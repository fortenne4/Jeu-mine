-- Nouveaux minerais (ReplicatedStorage › Partage › MineraisPropositions).
-- Minables dans la mine privée seulement (couches de Partage › CouchesMine), vendables chez Gaspard (PrixMinerais),
-- pas encore forgeables (Forge.MINERAIS : forgeable = false). Exposés aussi dans la vitrine de la plaine des mobs.
-- Même format que MineraisModeles.VISUEL (qui les reprend) + « speciaux » (effets en plus, à partir de la rareté Épique).
-- Aperçu de travail : previews/minerais/atelier-minerais.html (mêmes valeurs).

local rgb = Color3.fromRGB
local M = Enum.Material

local Propositions = {}

Propositions.ORDRE = {
	"Soufre", "Quartz", "Argent", "Obsidienne", "Givrite", "Emeraude", "Rubis",
	"Lunarite", "Magmaite", "Diamant", "Orichalque", "Neantite",
}

-- Noms affichés (y compris les 4 minerais de départ, pour la vitrine)
Propositions.NOMS = {
	Charbon = "Charbon", Bronze = "Cuivre", Fer = "Fer", Gold = "Or",
	Soufre = "Soufre", Quartz = "Quartz", Argent = "Argent", Obsidienne = "Obsidienne",
	Givrite = "Givrite", Emeraude = "Émeraude", Rubis = "Rubis",
	Lunarite = "Lunarite", Magmaite = "Magmaïte", Diamant = "Diamant", Orichalque = "Orichalque", Neantite = "Néantite",
}

Propositions.COULEURS_RARETE = {
	["Commun"] = rgb(185, 178, 168),
	["Peu commun"] = rgb(111, 209, 111),
	["Rare"] = rgb(90, 168, 255),
	["Épique"] = rgb(183, 124, 255),
	["Légendaire"] = rgb(242, 193, 78),
	["Mythique"] = rgb(255, 90, 106),
}

-- speciaux : geant = cristaux géants au sommet ; eclats = éclats en lévitation ; anneau = runes en orbite ;
-- lune = petite lune flottante ; lueur = PointLight (luminosité) ; pulse = néons qui respirent ;
-- etincelles = {n, mode = "scintille" | "monte" | "braises" | "aspire"}
Propositions.VISUEL = {
	Soufre = {rarete = "Commun", taille = 1, couleur = rgb(214, 190, 70), couleur2 = rgb(176, 150, 52),
		materiau = M.Sandstone, reflet = 0.05, cristal = rgb(255, 236, 90), cristalMat = M.Glass,
		cristaux = 5, amas = 1, veines = 2, veine = rgb(255, 250, 170)},
	Quartz = {rarete = "Commun", taille = 1, couleur = rgb(205, 200, 195), couleur2 = rgb(170, 165, 162),
		materiau = M.Granite, reflet = 0.05, cristal = rgb(245, 240, 255), cristalMat = M.Glass,
		cristaux = 7, amas = 2, veines = 2, veine = rgb(255, 220, 235)},
	Argent = {rarete = "Peu commun", taille = 1.05, couleur = rgb(190, 196, 206), couleur2 = rgb(150, 156, 168),
		materiau = M.Metal, reflet = 0.4, cristal = rgb(235, 245, 255), cristalMat = M.Glass,
		cristaux = 5, amas = 2, veines = 6, veine = rgb(230, 240, 255)},
	Obsidienne = {rarete = "Rare", taille = 1.1, couleur = rgb(24, 20, 32), couleur2 = rgb(40, 30, 52),
		materiau = M.Glass, reflet = 0.45, cristal = rgb(120, 60, 200), cristalMat = M.Glass,
		cristaux = 6, amas = 2, veines = 4, veine = rgb(170, 90, 255)},
	Givrite = {rarete = "Rare", taille = 1.1, couleur = rgb(120, 190, 230), couleur2 = rgb(90, 155, 205),
		materiau = M.Ice, reflet = 0.3, cristal = rgb(150, 235, 255), cristalMat = M.Neon,
		cristaux = 7, amas = 2, veines = 4, veine = rgb(220, 250, 255)},
	Emeraude = {rarete = "Épique", taille = 1.15, couleur = rgb(40, 58, 48), couleur2 = rgb(30, 44, 38),
		materiau = M.Slate, reflet = 0.1, cristal = rgb(40, 220, 110), cristalMat = M.Glass,
		cristaux = 7, amas = 3, veines = 3, veine = rgb(120, 255, 170),
		speciaux = {geant = 1, etincelles = {n = 16, mode = "scintille"}}},
	Rubis = {rarete = "Épique", taille = 1.15, couleur = rgb(70, 40, 40), couleur2 = rgb(52, 30, 32),
		materiau = M.Basalt, reflet = 0.1, cristal = rgb(235, 30, 60), cristalMat = M.Glass,
		cristaux = 7, amas = 3, veines = 3, veine = rgb(255, 90, 110),
		speciaux = {geant = 1, etincelles = {n = 16, mode = "scintille"}}},
	Lunarite = {rarete = "Légendaire", taille = 1.2, couleur = rgb(225, 225, 235), couleur2 = rgb(195, 195, 212),
		materiau = M.Marble, reflet = 0.2, cristal = rgb(190, 205, 255), cristalMat = M.Neon,
		cristaux = 6, amas = 3, veines = 6, veine = rgb(235, 240, 255),
		speciaux = {geant = 1, eclats = 4, lueur = 1.6, lune = true, etincelles = {n = 18, mode = "scintille"}}},
	Magmaite = {rarete = "Légendaire", taille = 1.2, couleur = rgb(40, 30, 28), couleur2 = rgb(60, 36, 28),
		materiau = M.CrackedLava, reflet = 0.05, cristal = rgb(255, 110, 20), cristalMat = M.Neon,
		cristaux = 7, amas = 3, veines = 10, veine = rgb(255, 170, 40),
		speciaux = {geant = 1, lueur = 2, pulse = true, etincelles = {n = 45, mode = "braises"}}},
	Diamant = {rarete = "Mythique", taille = 1.25, couleur = rgb(110, 112, 120), couleur2 = rgb(88, 90, 98),
		materiau = M.Granite, reflet = 0.1, cristal = rgb(235, 250, 255), cristalMat = M.Glass,
		cristaux = 12, amas = 4, veines = 4, veine = rgb(255, 255, 255),
		speciaux = {geant = 3, eclats = 6, anneau = 10, lueur = 1.6, etincelles = {n = 34, mode = "scintille"}}},
	Orichalque = {rarete = "Mythique", taille = 1.25, couleur = rgb(210, 110, 50), couleur2 = rgb(170, 70, 40),
		materiau = M.Foil, reflet = 0.25, cristal = rgb(255, 170, 80), cristalMat = M.Neon,
		cristaux = 9, amas = 3, veines = 8, veine = rgb(255, 220, 150),
		speciaux = {geant = 2, eclats = 4, anneau = 14, lueur = 1.8, pulse = true, etincelles = {n = 26, mode = "monte"}}},
	Neantite = {rarete = "Mythique", taille = 1.3, couleur = rgb(16, 10, 24), couleur2 = rgb(30, 16, 44),
		materiau = M.Basalt, reflet = 0.05, cristal = rgb(190, 60, 255), cristalMat = M.Neon,
		cristaux = 10, amas = 4, veines = 9, veine = rgb(230, 140, 255),
		speciaux = {geant = 2, eclats = 7, anneau = 12, lueur = 2, pulse = true, etincelles = {n = 44, mode = "aspire"}}},
}

return Propositions
