--!strict
-- Pêche dans les lacs de la grotte −50 m · MODULE PARTAGÉ (ReplicatedStorage › Partage › Peche)
-- Liste des poissons (carnet de pêche), réglages du mini-jeu. Le serveur (PecheGrotte.server.lua) tire le poisson
-- et fait foi ; le client (PecheGrotte.client.lua) n'affiche que le mini-jeu et le carnet.

local Peche = {}

Peche.REMOTE = "PecheGrotte"

export type Poisson = {id: string, nom: string, rarete: string, poids: number, pieces: number, couleur: Color3,
	taille: number, touches: number, zone: number, vitesse: number, texte: string}

-- touches : appuis réussis à enchaîner ; zone : largeur de la zone verte (0-1) ; vitesse : allers-retours/s du curseur
Peche.POISSONS = {
	{id = "Gardon", nom = "Gardon pâle", rarete = "Commun", poids = 40, pieces = 3, couleur = Color3.fromRGB(190, 205, 215),
		taille = 0.8, touches = 2, zone = 0.3, vitesse = 0.55, texte = "Il n'a jamais vu le soleil."},
	{id = "Truite", nom = "Truite des grottes", rarete = "Commun", poids = 30, pieces = 4, couleur = Color3.fromRGB(150, 175, 160),
		taille = 1, touches = 2, zone = 0.27, vitesse = 0.65, texte = "Aveugle, mais elle sent tout."},
	{id = "Lanterne", nom = "Poisson-lanterne", rarete = "Peu commun", poids = 15, pieces = 8, couleur = Color3.fromRGB(80, 230, 255),
		taille = 0.9, touches = 3, zone = 0.22, vitesse = 0.75, texte = "Sa lueur attire les plus gros."},
	{id = "Anguille", nom = "Anguille de cristal", rarete = "Rare", poids = 8, pieces = 15, couleur = Color3.fromRGB(150, 255, 235),
		taille = 1.5, touches = 3, zone = 0.18, vitesse = 0.9, texte = "Transparente comme le verre."},
	{id = "Carpe", nom = "Carpe de Brumefer", rarete = "Rare", poids = 5, pieces = 18, couleur = Color3.fromRGB(205, 140, 70),
		taille = 1.4, touches = 4, zone = 0.18, vitesse = 0.85, texte = "Les nains l'élevaient dans les bassins du roi."},
	{id = "Lune", nom = "Poisson-lune spectral", rarete = "Épique", poids = 1.6, pieces = 35, couleur = Color3.fromRGB(175, 120, 255),
		taille = 1.2, touches = 4, zone = 0.14, vitesse = 1.05, texte = "On dit qu'il nage entre deux mondes."},
	{id = "Roi", nom = "Roi-poisson doré", rarete = "Légendaire", poids = 0.4, pieces = 80, couleur = Color3.fromRGB(255, 205, 70),
		taille = 1.7, touches = 5, zone = 0.12, vitesse = 1.2, texte = "La couronne de Haldur dort dans son ventre…"},
}

Peche.PAR_ID = {} :: {[string]: Poisson}
for _, p in Peche.POISSONS do
	Peche.PAR_ID[p.id] = p :: any
end

Peche.COULEUR_RARETE = {
	Commun = Color3.fromRGB(200, 200, 200),
	["Peu commun"] = Color3.fromRGB(110, 230, 120),
	Rare = Color3.fromRGB(90, 170, 255),
	["Épique"] = Color3.fromRGB(190, 110, 255),
	["Légendaire"] = Color3.fromRGB(255, 200, 60),
}

-- sur l'îlot du grand lac, les poissons rares mordent bien plus souvent
Peche.BONUS_ILOT = {Rare = 2.5, ["Épique"] = 3, ["Légendaire"] = 3}

Peche.ATTENTE = {1.5, 4.5} -- s avant que ça morde
Peche.DUREE_MAX = 30 -- s pour finir le mini-jeu

-- lit l'attribut « CarnetPeche » (« id:n,id:n »)
function Peche.lire(attribut: any): {[string]: number}
	local t = {}
	if type(attribut) == "string" then
		for id, n in attribut:gmatch("([^,:]+):(%d+)") do
			t[id] = tonumber(n) :: number
		end
	end
	return t
end

function Peche.especes(carnet: {[string]: number}): number
	local n = 0
	for id in carnet do
		if Peche.PAR_ID[id] then
			n += 1
		end
	end
	return n
end

return Peche
