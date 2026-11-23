--!strict
-- Boss du village (ReplicatedStorage › Partage › BossVillage) : réglages partagés de l'événement de groupe.
-- Le serveur (BossVillage.server) fait foi ; le client (BossVillage.client) ne s'en sert que pour l'affichage.
-- Toutes les CYCLE secondes, les joueurs debout dans le grand cercle du bout de la rue du sud (max MAX_JOUEURS)
-- sont téléportés dans l'arène face au boss suivant de la rotation.

local BossVillage = {}

BossVillage.CYCLE = 7 * 60          -- s entre deux boss (fin du combat → prochain boss)
BossVillage.CYCLE_STUDIO = 45       -- cycle court dans Studio (si DEBUT_RAPIDE_STUDIO)
BossVillage.DEBUT_RAPIDE_STUDIO = true -- Studio : boss toutes les CYCLE_STUDIO s pour tester vite ; false = vrai cycle
BossVillage.MAX_JOUEURS = 20
BossVillage.DUREE_MAX = 5 * 60      -- au-delà : échec, le boss disparaît
BossVillage.GUIDE = 40              -- s avant le boss : flèches au sol vers le cercle
BossVillage.ANNONCE = 60            -- s avant le boss : bandeau + puce en haut d'écran + guide vers le cercle

-- Déroulé (s). Départ : fondu au noir + écran de chargement, téléportation après DELAI_DEPART, intro quand tous
-- sont posés (au plus ATTENTE_ARRIVEE s). Intro : boss invulnérable et immobile, joueurs gelés.
BossVillage.FONDU = 0.6
BossVillage.DELAI_DEPART = 0.8
BossVillage.ATTENTE_ARRIVEE = 3
BossVillage.DUREE_INTRO = 6.5
BossVillage.ROAR_INTRO = 2.6        -- instant du rugissement dans l'intro (plan bas sur le boss)
-- Phases : sous 66 % puis 33 % de PV, le boss s'enrage (2 s invulnérable, rugissement, attaques plus rapides)
BossVillage.PHASES = {0.66, 0.33}
BossVillage.PHASE_INVULNERABLE = 2
BossVillage.CADENCE = { -- par phase : T = durée des télégraphes (× 1), pause entre deux attaques spéciales, recharge du corps à corps (×)
	{T = 1, pause = 4.2, recharge = 1},
	{T = 0.9, pause = 3.4, recharge = 0.9},
	{T = 0.8, pause = 2.6, recharge = 0.8},
}
-- Fin : bannière VICTOIRE / ÉCHEC, puis écran de résultats, puis retour au village (fondu)
BossVillage.BANNIERE_FIN = 2.2
BossVillage.RESULTATS = 10
BossVillage.RETOUR_VICTOIRE = BossVillage.BANNIERE_FIN + BossVillage.RESULTATS -- s dans l'arène après la fin
BossVillage.RETOUR_ECHEC = BossVillage.BANNIERE_FIN + BossVillage.RESULTATS

-- Astuces de l'écran de chargement
BossVillage.ASTUCES = {
	"Les zones rouges au sol annoncent les attaques : sors-en !",
	"Le 3e coup d'un enchaînement d'épée frappe 1,5 fois plus fort.",
	"Une bonne armure réduit les dégâts de chaque coup du boss.",
	"À 66 % puis 33 % de PV, le boss s'enrage : ses attaques s'accélèrent.",
	"K.O. ? Retourne dans le cercle du village pour rejoindre le combat.",
	"Le meilleur combattant est sacré MVP et touche la plus grosse part du pot.",
	"Le cercle de l'arène accueille jusqu'à 20 mineurs.",
}

-- PV du boss = mult × Σ (dégâts d'épée de chaque joueur, bornés) × PV_PAR_DEGAT, au moins PV_MIN.
-- PV_PAR_DEGAT ≈ 2 coups/s × 1,17 (combo) × 45 % du temps à frapper × ~180 s : ~3 min quel que soit le groupe.
-- Épée max du jeu ≈ 310 dégâts (Fer et or, Forge.lua) : ~59 000 PV par joueur très équipé.
BossVillage.PV_PAR_DEGAT = 190
BossVillage.EPEE_MIN = 15           -- un joueur à l'épée de base compte comme une épée de 15
BossVillage.EPEE_MAX = 310
BossVillage.PV_MIN = 4000

-- Récompenses (pièces) : BONUS_MIN à tout joueur ayant touché le boss + sa part du pot (au prorata des dégâts),
-- pot = POT_PAR_JOUEUR × nombre de participants × mult du boss.
-- Dégâts d'un coup du boss (corps à corps et zones), avant la défense de l'armure :
-- 80 sur 150 PV de départ = un débutant tient 1 coup et meurt au 2e. Cercle de lave : + 6 par demi-seconde.
BossVillage.COUP_BOSS = 80

BossVillage.BONUS_MIN = 150
BossVillage.POT_PAR_JOUEUR = 450

export type Boss = {
	id: string, nom: string, titre: string, couleur: Color3,
	secours: string, hauteurSecours: number, pvMult: number, recompense: number,
	degats: number, vitesse: number, portee: number, recharge: number, rayon: number, impact: number,
	attaques: {string}, conseil: string,
}

-- Rotation des 3 boss. Modèles : Partage › MobsVoxels › <id> ; tant qu'il manque, « secours » est utilisé.
-- Le vrai modèle est gardé à sa taille (~19 à 27 studs) ; le secours est agrandi à hauteurSecours studs.
-- degats = coup au corps à corps, impact = image d'impact de l'animation Attack (s), calée sur les dégâts.
-- rayon = rayon de contact (portée des coups d'épée autour du boss : épée 7 + rayon).
BossVillage.BOSS = {
	{id = "TitanCristal", nom = "Titan de cristal", titre = "Colosse des profondeurs", couleur = Color3.fromRGB(110, 205, 255),
		secours = "BruteProfondeurs", hauteurSecours = 19, pvMult = 1.1, recompense = 1,
		degats = BossVillage.COUP_BOSS, vitesse = 9, portee = 13, recharge = 2.6, rayon = 6.5, impact = 26 / 30, attaques = {"Onde", "Poings", "Eclats"},
		conseil = "Son onde de choc frappe en anneau : saute-la, ou colle-toi à lui."},
	{id = "ReineAraignee", nom = "Reine araignée", titre = "Mère des galeries", couleur = Color3.fromRGB(190, 110, 255),
		secours = "RampantGaleries", hauteurSecours = 12, pvMult = 0.9, recompense = 1,
		degats = BossVillage.COUP_BOSS, vitesse = 12, portee = 13, recharge = 2.1, rayon = 8, impact = 22 / 30, attaques = {"Toile", "Invocation", "Bond"},
		conseil = "Ne reste pas devant elle : sa toile part en cône. Tue vite ses petites araignées."},
	{id = "SeigneurBraise", nom = "Seigneur de braise", titre = "Cœur du volcan", couleur = Color3.fromRGB(255, 120, 50),
		secours = "ExecuteurMaudit", hauteurSecours = 17, pvMult = 1, recompense = 1.1,
		degats = BossVillage.COUP_BOSS, vitesse = 9, portee = 13, recharge = 2.4, rayon = 6.5, impact = 18 / 30, attaques = {"Meteores", "Lave", "Souffle"},
		conseil = "Bouge sans arrêt sous la pluie de météores, et sors vite du cercle de lave."},
} :: {Boss}

-- Sbires invoqués par la Reine (mobs existants des grottes)
BossVillage.SBIRES = {
	{id = "RampantGaleries", poids = 1, pv = 450, degats = 40, vitesse = 14, portee = 4.5, recharge = 1.2, echelle = 1.1},
}
BossVillage.SBIRES_MAX = 6

-- Dossier ReplicatedStorage › BossVillage (créé par le serveur) :
--   RemoteEvent « Evenement » : serveur → client (type, données)
--     "Annonce" (texte, couleur?)                       tous les joueurs (bandeau)
--     "Depart" {nom, titre, couleur, index, court}       partant : fondu noir + écran de chargement (court = rejoindre)
--     "Intro" {centre, boss (Model?), duree, roar}       posé dans l'arène : cinématique d'entrée du boss
--     "Arrivee" {}                                       posé (rejoindre / arrivé en retard) : fin du chargement
--     "Annule" {}                                        départ annulé (mort, erreur) : fin du chargement
--     "Phase" {phase, nom, couleur}                      changement de phase (bannière, secousse)
--     "Impact" (position, rayon)                         attaque de zone tombée (secousse si proche)
--     "KO" {nom}                                         mort dans l'arène (écran K.O.)
--     "Fin" {victoire, nom, couleur}                     bannière VICTOIRE / ÉCHEC
--     "Resultats" {victoire, nom, titre, couleur, duree, mvp, retour, lignes = {{id, nom, degats, pieces, rang}}, moi?}
--     "Retour" {}                                        fondu noir : le serveur téléporte au village FONDU s après
--   RemoteEvent « Action » : client → serveur ("Retour") : retour anticipé au village après la fin (validé, 1/s)
--   attributs : Etat ("Attente"/"Depart"/"Combat"), Index, Nom, Titre, Couleur, PV, PVMax, FinCombat (temps serveur),
--     Prochain (index du boss suivant), DebutBoss (temps serveur du prochain départ), File (UserId du cercle, ordre
--     d'arrivée, séparés par des virgules), Phase (1..3), Debout (mineurs debout dans l'arène), Intro (bool),
--     Cercle / RayonCercle (cercle du village), MineMin / MineMax (zone de la mine : guide masqué dedans)
-- Attribut joueur « DansArene » = true pendant le combat (barre de PV, ambiance d'arène).
BossVillage.DOSSIER = "BossVillage"

function BossVillage.cycle(studio: boolean): number
	return if studio and BossVillage.DEBUT_RAPIDE_STUDIO then BossVillage.CYCLE_STUDIO else BossVillage.CYCLE
end

function BossVillage.minutes(s: number): string
	s = math.max(0, math.floor(s + 0.5))
	return string.format("%d:%02d", s // 60, s % 60)
end

return BossVillage
