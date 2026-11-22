--!strict
-- Grottes profondes (ReplicatedStorage › Partage › Grottes) : expéditions à 1 ou 2 joueurs dans une grotte
-- générée au hasard. Le joueur choisit sa profondeur ; plus on descend, plus les minerais sont rares et
-- résistants et plus les mobs sont dangereux. Source unique des réglages : le serveur (Grottes.server,
-- GrotteGenerateur, MobsGrotte) fait foi, le client (InterfaceGrottes) ne s'en sert que pour l'affichage.
--
-- Cohérence avec l'équipement : chaque palier donne un équipement CONSEILLÉ (puissance de pioche,
-- dégâts d'épée, défense totale casque + plastron + jambières). Grottes.danger(niveau, stats) compare
-- l'équipement du joueur à ce conseil et renvoie 0 (facile) … 1 (mortel) pour la barre de difficulté.

local Grottes = {}

Grottes.MAX_JOUEURS = 2
Grottes.RAYON_CERCLE = 5.5 * 1.25 -- 1,25 × le cercle des tunnels privés (CercleLumineux.RAYON)

-- Réduction des dégâts reçus par la défense : defense / (defense + DEFENSE_MOITIE)
-- (DEFENSE_MOITIE de défense = dégâts divisés par 2)
Grottes.DEFENSE_MOITIE = 60

export type MineraiGrotte = {id: string, poids: number, pv: number}
export type MobGrotte = {id: string, poids: number, pv: number, degats: number, vitesse: number, portee: number, recharge: number, echelle: number?}
export type Niveau = {
	id: number,
	nom: string,
	profondeur: number,            -- affiché « −N m »
	difficulte: number,            -- 1 à 5 (étoiles / barre de base)
	conseil: {pioche: number, epee: number, defense: number},
	minerais: {MineraiGrotte},
	densiteMinerais: number,       -- nœuds par tranche de 10 studs de galerie
	mobs: {MobGrotte},
	nombreMobs: {number},          -- {min, max} au départ
	renfortSecondes: number,       -- un mob réapparaît toutes les N s (jusqu'au nombre de départ)
	boss: MobGrotte?,              -- un seul, dans la dernière salle
	ambiance: {roche: Color3, lumiere: Color3, brouillard: Color3, materiau: string},
}

Grottes.NIVEAUX = {
	{
		id = 1, nom = "Galeries humides", profondeur = 50, difficulte = 1,
		conseil = {pioche = 1, epee = 6, defense = 0},
		minerais = {
			{id = "Charbon", poids = 55, pv = 3},
			{id = "Bronze", poids = 35, pv = 5},
			{id = "Fer", poids = 10, pv = 9},
		},
		densiteMinerais = 1.4,
		mobs = {
			{id = "ChauveSourisCave", poids = 1, pv = 30, degats = 8, vitesse = 14, portee = 4, recharge = 1.2, echelle = 1},
		},
		nombreMobs = {3, 5}, renfortSecondes = 40,
		ambiance = {roche = Color3.fromRGB(96, 92, 88), lumiere = Color3.fromRGB(150, 200, 255), brouillard = Color3.fromRGB(30, 40, 52), materiau = "Slate"},
	},
	{
		id = 2, nom = "Cavernes oubliées", profondeur = 100, difficulte = 2,
		conseil = {pioche = 1.6, epee = 19, defense = 10},
		minerais = {
			{id = "Bronze", poids = 45, pv = 8},
			{id = "Fer", poids = 40, pv = 14},
			{id = "Gold", poids = 15, pv = 22},
		},
		densiteMinerais = 1.5,
		mobs = {
			{id = "ChauveSourisCave", poids = 2, pv = 45, degats = 12, vitesse = 15, portee = 4, recharge = 1.1, echelle = 1},
			{id = "MineurZombie", poids = 3, pv = 110, degats = 18, vitesse = 9, portee = 4.5, recharge = 1.4, echelle = 1},
			{id = "RampantGaleries", poids = 2, pv = 80, degats = 15, vitesse = 12, portee = 4.5, recharge = 1.2, echelle = 1},
		},
		nombreMobs = {5, 7}, renfortSecondes = 35,
		ambiance = {roche = Color3.fromRGB(84, 78, 92), lumiere = Color3.fromRGB(190, 150, 255), brouillard = Color3.fromRGB(34, 26, 48), materiau = "Basalt"},
	},
	{
		id = 3, nom = "Abîme de fer", profondeur = 200, difficulte = 3,
		conseil = {pioche = 2, epee = 49, defense = 25},
		minerais = {
			{id = "Fer", poids = 60, pv = 24},
			{id = "Gold", poids = 40, pv = 40},
		},
		densiteMinerais = 1.6,
		mobs = {
			{id = "ZombieLame", poids = 3, pv = 280, degats = 32, vitesse = 11, portee = 5, recharge = 1.2, echelle = 1},
			{id = "ZombieMutant", poids = 2, pv = 380, degats = 40, vitesse = 9, portee = 5.5, recharge = 1.5, echelle = 1.1},
			{id = "RampantGaleries", poids = 1, pv = 220, degats = 28, vitesse = 14, portee = 4.5, recharge = 1.1, echelle = 1.1},
		},
		nombreMobs = {6, 8}, renfortSecondes = 30,
		ambiance = {roche = Color3.fromRGB(70, 66, 70), lumiere = Color3.fromRGB(255, 150, 90), brouillard = Color3.fromRGB(44, 24, 18), materiau = "Basalt"},
	},
	{
		id = 4, nom = "Profondeurs ardentes", profondeur = 350, difficulte = 4,
		conseil = {pioche = 4, epee = 124, defense = 55},
		minerais = {
			{id = "Fer", poids = 35, pv = 45},
			{id = "Gold", poids = 65, pv = 50},
		},
		densiteMinerais = 1.8,
		mobs = {
			{id = "ZombieMutant", poids = 3, pv = 800, degats = 60, vitesse = 10, portee = 5.5, recharge = 1.4, echelle = 1.15},
			{id = "BruteProfondeurs", poids = 2, pv = 1400, degats = 85, vitesse = 8, portee = 7, recharge = 2, echelle = 1},
			{id = "ZombieLame", poids = 2, pv = 650, degats = 55, vitesse = 12, portee = 5, recharge = 1.1, echelle = 1.1},
		},
		nombreMobs = {6, 9}, renfortSecondes = 28,
		ambiance = {roche = Color3.fromRGB(64, 46, 40), lumiere = Color3.fromRGB(255, 110, 50), brouillard = Color3.fromRGB(60, 20, 10), materiau = "CrackedLava"},
	},
	{
		id = 5, nom = "Cœur maudit", profondeur = 500, difficulte = 5,
		conseil = {pioche = 8, epee = 230, defense = 100},
		minerais = {
			{id = "Gold", poids = 100, pv = 80},
		},
		densiteMinerais = 2.2,
		mobs = {
			{id = "BruteProfondeurs", poids = 2, pv = 2600, degats = 120, vitesse = 9, portee = 7, recharge = 1.8, echelle = 1.1},
			{id = "ZombieMutant", poids = 2, pv = 1600, degats = 95, vitesse = 11, portee = 5.5, recharge = 1.3, echelle = 1.2},
		},
		nombreMobs = {7, 9}, renfortSecondes = 25,
		boss = {id = "ExecuteurMaudit", poids = 1, pv = 9000, degats = 170, vitesse = 9, portee = 8, recharge = 2.2, echelle = 1.4},
		ambiance = {roche = Color3.fromRGB(40, 30, 46), lumiere = Color3.fromRGB(200, 60, 255), brouillard = Color3.fromRGB(24, 8, 34), materiau = "Basalt"},
	},
} :: {Niveau}

function Grottes.niveau(id: any): Niveau?
	if type(id) ~= "number" then return nil end
	return Grottes.NIVEAUX[id]
end

-- Part des dégâts reçus qui reste après la défense (1 = aucune protection)
function Grottes.reductionDefense(defense: number): number
	defense = math.max(0, defense)
	return 1 - defense / (defense + Grottes.DEFENSE_MOITIE)
end

export type Stats = {pioche: number, epee: number, defense: number}

-- Danger d'un palier pour cet équipement : 0 = largement équipé … 1 = mortel.
-- Chaque stat compte selon le rapport équipement / conseil (le maillon faible pèse le plus).
function Grottes.danger(niveau: Niveau, stats: Stats): number
	local c = niveau.conseil
	local function rapport(valeur: number, conseil: number): number
		if conseil <= 0 then return 1.5 end
		return math.clamp(valeur / conseil, 0, 1.5)
	end
	local rPioche = rapport(stats.pioche, c.pioche)
	local rEpee = rapport(stats.epee, c.epee)
	-- défense : conseil 0 → toujours bon ; sinon rapport avec un plancher (on survit un peu sans armure)
	local rDefense = if c.defense <= 0 then 1.5 else math.clamp(0.3 + stats.defense / c.defense, 0, 1.5)
	local faible = math.min(rPioche, rEpee, rDefense)
	local moyenne = (rPioche + rEpee * 1.4 + rDefense * 1.2) / 3.6
	local niveauEquipement = faible * 0.6 + moyenne * 0.4 -- 1 = équipement conseillé
	return math.clamp(1.25 - niveauEquipement, 0, 1)
end

-- Texte court du danger (infobulle)
function Grottes.libelleDanger(danger: number): string
	if danger < 0.2 then return "Facile"
	elseif danger < 0.45 then return "Équilibré"
	elseif danger < 0.7 then return "Risqué"
	elseif danger < 0.9 then return "Très risqué"
	end
	return "Mortel"
end

function Grottes.couleurDanger(danger: number): Color3
	local vert, jaune, rouge = Color3.fromRGB(96, 220, 120), Color3.fromRGB(255, 205, 70), Color3.fromRGB(240, 60, 60)
	if danger < 0.5 then return vert:Lerp(jaune, danger / 0.5) end
	return jaune:Lerp(rouge, (danger - 0.5) / 0.5)
end

-- Tirage pondéré dans une liste {poids = n}
function Grottes.tirer<T>(liste: {T}, rng: Random): T
	local total = 0
	for _, e in liste do total += (e :: any).poids end
	local x = rng:NextNumber() * total
	for _, e in liste do
		x -= (e :: any).poids
		if x <= 0 then return e end
	end
	return liste[#liste]
end

-- Noms des RemoteEvents (dossier ReplicatedStorage › Grottes, créé par Grottes.server)
Grottes.REMOTES = {
	"Ouvrir",       -- serveur → client : (etat) ouvre / met à jour le choix de profondeur
	"Fermer",       -- serveur → client : () ferme l'interface
	"Choisir",      -- client → serveur : (niveauId) le chef lance l'expédition
	"Quitter",      -- client → serveur : () annule / quitte le groupe
	"Inviter",      -- client → serveur : (userId) le chef invite un joueur
	"Invitation",   -- serveur → client : (chefUserId, chefNom) invitation reçue
	"Repondre",     -- client → serveur : (chefUserId, accepte: boolean)
	"Message",      -- serveur → client : (texte) petite notification
}
-- etat envoyé par « Ouvrir » : {chef = userId, membres = {{userId, nom}}, invites = {userId...}, estChef = bool}
-- Stats d'équipement du joueur pour la barre : attributs joueur « StatPioche », « StatEpee », « StatDefense »
-- (posés par Grottes.server, mis à jour à chaque changement d'équipement).

return Grottes
