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
-- Zone sûre autour de l'arrivée dans la grotte (studs) : aucun minerai, aucun mob n'y apparaît
-- (≥ vue des mobs 45 + errance 8 ; 0,7 × si la grotte manque de place). Refuge : les mobs n'y entrent jamais.
Grottes.ZONE_SURE = 55
Grottes.ZONE_REFUGE = 25

-- Réduction des dégâts reçus par la défense : defense / (defense + DEFENSE_MOITIE)
-- (DEFENSE_MOITIE de défense = dégâts divisés par 2)
Grottes.DEFENSE_MOITIE = 60

-- dominant = false : ce minerai ne fait jamais le type dominant d'un gisement (il n'apparaît que dans les 30 %
-- de nœuds tirés au poids) → minerai « rare » du palier (ex. un peu de cuivre à −50 m).
export type MineraiGrotte = {id: string, poids: number, pv: number, dominant: boolean?}
-- Variantes recolorées (paliers 6 à 8) : teinte = couleur vers laquelle tirent les pièces (force 0 … 1, défaut 0,5),
-- lueur = couleur des pièces en néon ; nom = nom affiché sur la barre du boss ; rayon / preparation : voir MobsGrotte.
export type MobGrotte = {id: string, poids: number, pv: number, degats: number, vitesse: number, portee: number, recharge: number, echelle: number?, vole: boolean?,
	nom: string?, teinte: Color3?, teinteForce: number?, lueur: Color3?, rayon: number?, preparation: number?}
export type Niveau = {
	id: number,
	nom: string,
	profondeur: number,            -- affiché « −N m »
	difficulte: number,            -- 1 à 8 (barre de base)
	conseil: {pioche: number, epee: number, defense: number},
	minerais: {MineraiGrotte},
	nombreMinerais: {number},      -- {min, max} nœuds par grotte (1 nœud = 1 minerai), regroupés en gisements
	mobs: {MobGrotte},
	nombreMobs: {number},          -- {min, max} au départ (gardes des gisements compris), par groupes de 2-3
	renfortSecondes: number,       -- un mob réapparaît toutes les N s (jusqu'au nombre de départ)
	boss: MobGrotte?,              -- un seul, dans la dernière salle
	mobsZones: {[string]: {MobGrotte}}?, -- mobs propres à une zone du décor (Foret, Lac, Temple), palier 1
	ambiance: {roche: Color3, lumiere: Color3, brouillard: Color3, materiau: string},
}

Grottes.NIVEAUX = {
	{
		id = 1, nom = "Galeries humides", profondeur = 50, difficulte = 1,
		conseil = {pioche = 1, epee = 6, defense = 0},
		-- Charbon partout, un tout petit peu de cuivre (≈ 9 % des nœuds, ~1 par grotte), pas de fer
		minerais = {
			{id = "Charbon", poids = 70, pv = 3},
			{id = "Bronze", poids = 30, pv = 5, dominant = false},
		},
		nombreMinerais = {12, 14},
		-- Zombies faibles + chauves-souris (≈ 19 coups de zombie pour tuer un joueur sans armure)
		mobs = {
			{id = "MineurZombie", poids = 3, pv = 36, degats = 8, vitesse = 8, portee = 4.5, recharge = 1.6, echelle = 1},
			{id = "ChauveSourisCave", poids = 2, pv = 18, degats = 5, vitesse = 13, portee = 4, recharge = 1.3, echelle = 1},
		},
		nombreMobs = {9, 11}, renfortSecondes = 45,
		-- Mobs à thème (« Le Lac des Lueurs ») : un groupe qui apparaît dans une zone du décor (parts « GrotteZone »
		-- ZoneForet / ZoneLac / ZoneTemple) tire ses mobs dans cette liste plutôt que dans « mobs »
		mobsZones = {
			Foret = {
				{id = "GolemChampignon", poids = 3, pv = 60, degats = 10, vitesse = 6.5, portee = 5, recharge = 2, echelle = 1},
				{id = "ChauveSourisCave", poids = 1, pv = 18, degats = 5, vitesse = 13, portee = 4, recharge = 1.3, echelle = 1},
			},
			Lac = {
				{id = "CrabeLueur", poids = 3, pv = 28, degats = 6, vitesse = 10, portee = 4.5, recharge = 1.4, echelle = 1.15},
				{id = "MineurZombie", poids = 1, pv = 36, degats = 8, vitesse = 8, portee = 4.5, recharge = 1.6, echelle = 1},
			},
			Temple = {
				{id = "SpectreNain", poids = 3, pv = 32, degats = 9, vitesse = 10, portee = 5, recharge = 1.7, echelle = 1, vole = true},
				{id = "ChauveSourisCave", poids = 1, pv = 18, degats = 5, vitesse = 13, portee = 4, recharge = 1.3, echelle = 1},
			},
		},
		ambiance = {roche = Color3.fromRGB(96, 92, 88), lumiere = Color3.fromRGB(150, 200, 255), brouillard = Color3.fromRGB(30, 40, 52), materiau = "Slate"},
	},
	{
		id = 2, nom = "Cavernes oubliées", profondeur = 100, difficulte = 2,
		conseil = {pioche = 1.6, epee = 19, defense = 10},
		-- Charbon, cuivre et fer (≈ 35 / 34 / 31 %)
		minerais = {
			{id = "Charbon", poids = 40, pv = 5},
			{id = "Bronze", poids = 35, pv = 8},
			{id = "Fer", poids = 25, pv = 14},
		},
		nombreMinerais = {12, 13},
		-- Zombies plus solides, chauves-souris, premiers rampants
		mobs = {
			{id = "MineurZombie", poids = 4, pv = 90, degats = 14, vitesse = 9, portee = 4.5, recharge = 1.5, echelle = 1},
			{id = "ChauveSourisCave", poids = 2, pv = 35, degats = 9, vitesse = 14, portee = 4, recharge = 1.2, echelle = 1},
			{id = "RampantGaleries", poids = 1, pv = 70, degats = 12, vitesse = 12, portee = 4.5, recharge = 1.3, echelle = 1},
		},
		nombreMobs = {10, 12}, renfortSecondes = 38,
		ambiance = {roche = Color3.fromRGB(84, 78, 92), lumiere = Color3.fromRGB(190, 150, 255), brouillard = Color3.fromRGB(34, 26, 48), materiau = "Basalt"},
	},
	{
		id = 3, nom = "Abîme de fer", profondeur = 200, difficulte = 3,
		conseil = {pioche = 2, epee = 49, defense = 25},
		-- Cuivre, fer et premier or (≈ 29 / 37 / 34 %)
		minerais = {
			{id = "Bronze", poids = 20, pv = 16},
			{id = "Fer", poids = 45, pv = 24},
			{id = "Gold", poids = 35, pv = 40},
		},
		nombreMinerais = {11, 13},
		-- Zombies à lame (plus forts), zombies, rampants, chauves-souris
		mobs = {
			{id = "ZombieLame", poids = 3, pv = 240, degats = 26, vitesse = 11, portee = 5, recharge = 1.3, echelle = 1},
			{id = "MineurZombie", poids = 2, pv = 180, degats = 22, vitesse = 10, portee = 4.5, recharge = 1.4, echelle = 1.05},
			{id = "RampantGaleries", poids = 2, pv = 180, degats = 22, vitesse = 14, portee = 4.5, recharge = 1.1, echelle = 1.1},
			{id = "ChauveSourisCave", poids = 1, pv = 70, degats = 14, vitesse = 15, portee = 4, recharge = 1.1, echelle = 1},
		},
		nombreMobs = {11, 13}, renfortSecondes = 32,
		ambiance = {roche = Color3.fromRGB(70, 66, 70), lumiere = Color3.fromRGB(255, 150, 90), brouillard = Color3.fromRGB(44, 24, 18), materiau = "Basalt"},
	},
	{
		id = 4, nom = "Profondeurs ardentes", profondeur = 350, difficulte = 4,
		conseil = {pioche = 4, epee = 124, defense = 55},
		-- Fer et or (≈ 51 / 49 %)
		minerais = {
			{id = "Fer", poids = 55, pv = 45},
			{id = "Gold", poids = 45, pv = 50},
		},
		nombreMinerais = {11, 13},
		-- Zombies mutants, zombies à lame, premières brutes, chauves-souris
		mobs = {
			{id = "ZombieMutant", poids = 3, pv = 650, degats = 50, vitesse = 10, portee = 5.5, recharge = 1.4, echelle = 1.1},
			{id = "ZombieLame", poids = 3, pv = 520, degats = 44, vitesse = 12, portee = 5, recharge = 1.2, echelle = 1.1},
			{id = "BruteProfondeurs", poids = 1, pv = 1200, degats = 70, vitesse = 8, portee = 7, recharge = 2, echelle = 1},
			{id = "ChauveSourisCave", poids = 1, pv = 140, degats = 26, vitesse = 16, portee = 4, recharge = 1, echelle = 1.1},
		},
		nombreMobs = {11, 14}, renfortSecondes = 28,
		ambiance = {roche = Color3.fromRGB(44, 40, 42), lumiere = Color3.fromRGB(255, 130, 60), brouillard = Color3.fromRGB(40, 18, 12), materiau = "CrackedLava"},
	},
	{
		id = 5, nom = "Cœur maudit", profondeur = 500, difficulte = 5,
		conseil = {pioche = 8, epee = 230, defense = 100},
		-- Surtout de l'or, un peu de fer (≈ 44 / 56 %)
		minerais = {
			{id = "Fer", poids = 30, pv = 60},
			{id = "Gold", poids = 70, pv = 80},
		},
		nombreMinerais = {11, 13},
		-- Zombies mutants géants, brutes, zombies à lame + boss (Exécuteur maudit)
		mobs = {
			{id = "ZombieMutant", poids = 3, pv = 1400, degats = 80, vitesse = 11, portee = 5.5, recharge = 1.3, echelle = 1.2},
			{id = "BruteProfondeurs", poids = 2, pv = 2300, degats = 105, vitesse = 9, portee = 7, recharge = 1.8, echelle = 1.1},
			{id = "ZombieLame", poids = 2, pv = 1100, degats = 72, vitesse = 13, portee = 5, recharge = 1.1, echelle = 1.15},
		},
		nombreMobs = {12, 14}, renfortSecondes = 25,
		boss = {id = "ExecuteurMaudit", poids = 1, pv = 9000, degats = 170, vitesse = 9, portee = 8, recharge = 2.2, echelle = 1.4},
		ambiance = {roche = Color3.fromRGB(40, 30, 46), lumiere = Color3.fromRGB(200, 60, 255), brouillard = Color3.fromRGB(24, 8, 34), materiau = "Basalt"},
	},
	-- ===== Au-delà du Cœur maudit : minerais de la mine privée (Partage › CouchesMine), du moins rare au plus rare =====
	-- Équipement conseillé au-dessus de la forge actuelle (épée max ≈ 310) : ces paliers attendent les pièces
	-- forgées avec les nouveaux minerais. Mobs = modèles existants recolorés (teinte / lueur, MobsGrotte).
	{
		id = 6, nom = "Glacier éternel", profondeur = 700, difficulte = 6,
		conseil = {pioche = 10, epee = 310, defense = 140},
		-- Givrite, argent et obsidienne (≈ 34 / 30 / 30 %), un peu d'émeraude prise dans la glace (≈ 6 %)
		minerais = {
			{id = "Givrite", poids = 40, pv = 110},
			{id = "Argent", poids = 25, pv = 95},
			{id = "Obsidienne", poids = 25, pv = 120},
			{id = "Emeraude", poids = 20, pv = 140, dominant = false},
		},
		nombreMinerais = {11, 13},
		-- Mutants, lames et brutes gelés, chauves-souris de givre + boss (Titan de givre)
		mobs = {
			{id = "ZombieMutant", poids = 3, pv = 2400, degats = 120, vitesse = 11, portee = 5.5, recharge = 1.3, echelle = 1.2,
				teinte = Color3.fromRGB(170, 215, 245), teinteForce = 0.5, lueur = Color3.fromRGB(120, 230, 255)},
			{id = "ZombieLame", poids = 3, pv = 1900, degats = 105, vitesse = 13, portee = 5, recharge = 1.1, echelle = 1.15,
				teinte = Color3.fromRGB(150, 200, 240), teinteForce = 0.5, lueur = Color3.fromRGB(120, 230, 255)},
			{id = "BruteProfondeurs", poids = 2, pv = 3800, degats = 150, vitesse = 9, portee = 7, recharge = 1.8, echelle = 1.15,
				teinte = Color3.fromRGB(190, 225, 250), teinteForce = 0.55, lueur = Color3.fromRGB(150, 240, 255)},
			{id = "ChauveSourisCave", poids = 2, pv = 700, degats = 60, vitesse = 17, portee = 4, recharge = 1, echelle = 1.2,
				teinte = Color3.fromRGB(210, 235, 255), teinteForce = 0.6, lueur = Color3.fromRGB(120, 230, 255)},
		},
		nombreMobs = {12, 14}, renfortSecondes = 24,
		boss = {id = "TitanCristal", nom = "Titan de givre", poids = 1, pv = 15000, degats = 240, vitesse = 9, portee = 11, recharge = 2.4,
			echelle = 0.8, rayon = 5, preparation = 0.8, teinte = Color3.fromRGB(205, 235, 255), teinteForce = 0.55, lueur = Color3.fromRGB(120, 230, 255)},
		ambiance = {roche = Color3.fromRGB(150, 190, 215), lumiere = Color3.fromRGB(140, 220, 255), brouillard = Color3.fromRGB(18, 38, 58), materiau = "Glacier"},
	},
	{
		id = 7, nom = "Abysses engloutis", profondeur = 900, difficulte = 7,
		conseil = {pioche = 12, epee = 420, defense = 190},
		-- Émeraude, rubis et lunarite (≈ 32 / 32 / 31 %), magmaïte des sources chaudes (≈ 5 %)
		minerais = {
			{id = "Emeraude", poids = 35, pv = 150},
			{id = "Rubis", poids = 35, pv = 160},
			{id = "Lunarite", poids = 30, pv = 180},
			{id = "Magmaite", poids = 20, pv = 200, dominant = false},
		},
		nombreMinerais = {11, 13},
		-- Crabes géants, noyés (spectres), rampants des récifs, mutants noyés + boss (Léviathan des abysses, BossProfondeurs)
		mobs = {
			{id = "CrabeLueur", poids = 3, pv = 3200, degats = 150, vitesse = 11, portee = 5.5, recharge = 1.3, echelle = 1.7,
				teinte = Color3.fromRGB(40, 170, 170), teinteForce = 0.45, lueur = Color3.fromRGB(90, 255, 230)},
			{id = "SpectreNain", poids = 2, pv = 2600, degats = 140, vitesse = 12, portee = 5, recharge = 1.5, echelle = 1.2, vole = true,
				teinte = Color3.fromRGB(60, 200, 200), teinteForce = 0.55, lueur = Color3.fromRGB(110, 255, 220)},
			{id = "RampantGaleries", poids = 2, pv = 3000, degats = 145, vitesse = 15, portee = 4.5, recharge = 1.1, echelle = 1.25,
				teinte = Color3.fromRGB(30, 110, 120), teinteForce = 0.55, lueur = Color3.fromRGB(90, 255, 230)},
			{id = "ZombieMutant", poids = 2, pv = 4200, degats = 170, vitesse = 11, portee = 5.5, recharge = 1.3, echelle = 1.25,
				teinte = Color3.fromRGB(50, 130, 130), teinteForce = 0.5, lueur = Color3.fromRGB(90, 255, 230)},
		},
		nombreMobs = {12, 14}, renfortSecondes = 23,
		-- boss : modèle provisoire MobsVoxels.LeviathanAbysses ; attaques spéciales et butin dans BossProfondeurs.lua
		boss = {id = "LeviathanAbysses", nom = "Le Léviathan des abysses", poids = 1, pv = 24000, degats = 320, vitesse = 10, portee = 9,
			recharge = 2.3, echelle = 1.15, rayon = 5, preparation = 0.8},
		ambiance = {roche = Color3.fromRGB(56, 96, 104), lumiere = Color3.fromRGB(60, 230, 200), brouillard = Color3.fromRGB(4, 28, 38), materiau = "Limestone"},
	},
	{
		id = 8, nom = "Néant étoilé", profondeur = 1200, difficulte = 8,
		conseil = {pioche = 12, epee = 560, defense = 250},
		-- Diamant et orichalque (≈ 47 / 45 %), néantite très rare (≈ 8 %)
		minerais = {
			{id = "Diamant", poids = 40, pv = 230},
			{id = "Orichalque", poids = 35, pv = 250},
			{id = "Neantite", poids = 25, pv = 290, dominant = false},
		},
		nombreMinerais = {11, 13},
		-- Spectres astraux (volants), lames du néant, colosses stellaires, chauves-souris d'étoiles + boss (Gardien des astres, BossProfondeurs)
		mobs = {
			{id = "SpectreNain", poids = 2, pv = 4200, degats = 210, vitesse = 13, portee = 5, recharge = 1.4, echelle = 1.3, vole = true,
				teinte = Color3.fromRGB(255, 215, 130), teinteForce = 0.55, lueur = Color3.fromRGB(255, 240, 180)},
			{id = "ZombieLame", poids = 3, pv = 5200, degats = 230, vitesse = 14, portee = 5, recharge = 1.05, echelle = 1.2,
				teinte = Color3.fromRGB(40, 40, 90), teinteForce = 0.6, lueur = Color3.fromRGB(120, 200, 255)},
			{id = "BruteProfondeurs", poids = 2, pv = 8500, degats = 300, vitesse = 9, portee = 7, recharge = 1.7, echelle = 1.2,
				teinte = Color3.fromRGB(30, 32, 72), teinteForce = 0.6, lueur = Color3.fromRGB(255, 215, 120)},
			{id = "ChauveSourisCave", poids = 2, pv = 1600, degats = 130, vitesse = 18, portee = 4, recharge = 0.9, echelle = 1.25,
				teinte = Color3.fromRGB(40, 40, 84), teinteForce = 0.6, lueur = Color3.fromRGB(255, 215, 120)},
		},
		nombreMobs = {13, 15}, renfortSecondes = 22,
		-- boss : modèle provisoire MobsVoxels.GardienAstres ; attaques spéciales et Épée des astres dans BossProfondeurs.lua
		boss = {id = "GardienAstres", nom = "Le Gardien des astres", poids = 1, pv = 36000, degats = 420, vitesse = 10, portee = 9,
			recharge = 2.2, echelle = 1.1, rayon = 5, preparation = 0.8},
		ambiance = {roche = Color3.fromRGB(34, 34, 60), lumiere = Color3.fromRGB(255, 210, 120), brouillard = Color3.fromRGB(6, 6, 18), materiau = "Asphalt"},
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

-- Minerais pouvant être le type dominant d'un gisement (GrotteGenerateur) : ceux sans « dominant = false »
-- (tous si aucun ne l'est)
function Grottes.mineraisDominants(niveau: Niveau): {MineraiGrotte}
	local liste = {}
	for _, m in niveau.minerais do
		if m.dominant ~= false then
			table.insert(liste, m)
		end
	end
	return if #liste > 0 then liste else table.clone(niveau.minerais)
end

-- Part ESTIMÉE de chaque minerai dans une grotte de ce palier (0 … 1), triée du plus fréquent au plus rare.
-- Suit le générateur : 70 % des nœuds sont du type dominant du gisement (types dominants tournés à parts ≈ égales),
-- 30 % tirés au poids. Sert à l'interface (ordre des icônes, « abondant / rare »).
function Grottes.partsMinerais(niveau: Niveau): {{id: string, part: number}}
	local total = 0
	for _, m in niveau.minerais do total += m.poids end
	local dominants = Grottes.mineraisDominants(niveau)
	local res = {}
	for i, m in niveau.minerais do
		local part = 0.3 * (if total > 0 then m.poids / total else 0)
		if table.find(dominants, m) then
			part += 0.7 / #dominants
		end
		table.insert(res, {id = m.id, part = part, ordre = i})
	end
	table.sort(res, function(a, b)
		if math.abs(a.part - b.part) > 1e-6 then return a.part > b.part end
		return a.ordre < b.ordre
	end)
	return res :: any
end

-- Nom des minerais pour le joueur (l'id « Bronze » s'affiche « Cuivre », « Gold » → « Or »)
Grottes.NOMS_MINERAIS = {Charbon = "Charbon", Bronze = "Cuivre", Fer = "Fer", Gold = "Or",
	Soufre = "Soufre", Quartz = "Quartz", Argent = "Argent", Obsidienne = "Obsidienne", Givrite = "Givrite", Emeraude = "Émeraude",
	Rubis = "Rubis", Lunarite = "Lunarite", Magmaite = "Magmaïte", Diamant = "Diamant", Orichalque = "Orichalque", Neantite = "Néantite"} :: {[string]: string}

-- Minerais déjà minés au moins une fois (n'importe où) : attribut joueur posé par le serveur (Donnees),
-- ids séparés par des virgules, ex. "Charbon,Bronze". Le client n'en fait qu'un affichage (silhouettes).
Grottes.ATTRIBUT_DECOUVERTS = "MineraisDecouverts"

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
