--!strict
-- Couches de minage de la mine privée (ReplicatedStorage › Partage › CouchesMine).
-- Source unique : MinePrivee (couleur de la roche, minerais enfouis, pioche requise pour creuser),
-- RemonterMine.server (attribut joueur « CoucheMine ») et CoucheMine.client (bandeau à l'écran).
-- Profondeur en mètres sous le sol de la galerie : 1 bloc de 2 studs = 1 m (fond du massif ≈ 338 m).
-- minerais : {id, chance} ; chance = probabilité qu'un paquet de 3 × 3 × 3 cases abrite ce minerai
-- (somme < 1 par couche). puissance = puissance de pioche minimale (Partage › Pioches) pour creuser la roche :
-- 1 = toutes les pioches (pas encore choisi). Ex. : 1.4 Silex, 1.6 Cuivre, 1.8 Fer, 2 Givre, 3 Volcan, 4 Céleste, 6 Démon.

local rgb = Color3.fromRGB
local M = Enum.Material

export type Couche = {
	nom: string,
	debut: number,
	fin: number,
	couleur: Color3,
	couleur2: Color3,
	materiau: Enum.Material,
	puissance: number,
	minerais: {{any}},
}

local CouchesMine = {}

CouchesMine.LISTE = {
	{nom = "Terre battue", debut = -10, fin = 40, couleur = rgb(122, 94, 68), couleur2 = rgb(96, 72, 52), materiau = M.Ground,
		puissance = 1, minerais = {{"Quartz", 0.04}, {"Soufre", 0.09}, {"Charbon", 0.2}}},
	{nom = "Grès", debut = 40, fin = 85, couleur = rgb(186, 150, 98), couleur2 = rgb(150, 116, 74), materiau = M.Sandstone,
		puissance = 1, minerais = {{"Argent", 0.04}, {"Quartz", 0.07}, {"Soufre", 0.08}, {"Charbon", 0.12}}},
	{nom = "Roche grise", debut = 85, fin = 130, couleur = rgb(124, 122, 120), couleur2 = rgb(92, 90, 90), materiau = M.Slate,
		puissance = 1, minerais = {{"Obsidienne", 0.03}, {"Argent", 0.08}, {"Quartz", 0.08}}},
	{nom = "Basalte", debut = 130, fin = 170, couleur = rgb(62, 60, 66), couleur2 = rgb(44, 42, 48), materiau = M.Basalt,
		puissance = 1, minerais = {{"Givrite", 0.06}, {"Obsidienne", 0.07}, {"Argent", 0.05}}},
	{nom = "Glacier", debut = 170, fin = 215, couleur = rgb(150, 192, 218), couleur2 = rgb(104, 150, 186), materiau = M.Glacier,
		puissance = 1, minerais = {{"Rubis", 0.035}, {"Emeraude", 0.035}, {"Givrite", 0.08}}},
	{nom = "Cristaux", debut = 215, fin = 255, couleur = rgb(96, 72, 128), couleur2 = rgb(64, 48, 92), materiau = M.Slate,
		puissance = 1, minerais = {{"Lunarite", 0.02}, {"Rubis", 0.05}, {"Emeraude", 0.05}}},
	{nom = "Magma", debut = 255, fin = 300, couleur = rgb(78, 38, 28), couleur2 = rgb(48, 26, 22), materiau = M.CrackedLava,
		puissance = 1, minerais = {{"Diamant", 0.008}, {"Lunarite", 0.02}, {"Magmaite", 0.04}}},
	{nom = "Néant", debut = 300, fin = 400, couleur = rgb(30, 20, 42), couleur2 = rgb(16, 10, 26), materiau = M.Basalt,
		puissance = 1, minerais = {{"Neantite", 0.008}, {"Orichalque", 0.012}, {"Diamant", 0.015}}},
} :: {Couche}

-- PV des nœuds de minerai dans la mine privée (même échelle que la mine publique : Charbon 2 … Or 8)
CouchesMine.PV = {
	Charbon = 2, Soufre = 2, Quartz = 3, Argent = 4, Obsidienne = 6, Givrite = 6, Emeraude = 8, Rubis = 8,
	Lunarite = 11, Magmaite = 11, Diamant = 15, Orichalque = 15, Neantite = 18,
} :: {[string]: number}

CouchesMine.PROFONDEUR_MAX = 338 -- fond du massif (m)

-- Index de la couche à cette profondeur (m), toujours entre 1 et #LISTE
function CouchesMine.index(profondeur: number): number
	for i, c in CouchesMine.LISTE do
		if profondeur < c.fin then
			return i
		end
	end
	return #CouchesMine.LISTE
end

function CouchesMine.get(profondeur: number): Couche
	return CouchesMine.LISTE[CouchesMine.index(profondeur)]
end

return CouchesMine
