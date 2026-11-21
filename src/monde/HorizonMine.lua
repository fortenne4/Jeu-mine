-- Décor de silhouette autour de la mine : aucune collision ni modification du terrain.
-- À construire après le terrain et la mine, sous le dossier Carte.
local O = require(script.Parent.Outils)
local Terrain = require(script.Parent.Terrain)
local M = O.M

local HorizonMine = {}
local PIERRE = Color3.fromRGB(92, 86, 101)
local PIERRE_CLAIRE = Color3.fromRGB(119, 111, 124)
local ARDOISE = Color3.fromRGB(58, 52, 73)
local BOIS = Color3.fromRGB(74, 48, 43)
local OR = Color3.fromRGB(243, 168, 75)

local function bloc(parent, nom, taille, cf, couleur, materiau)
	local piece = O.decor(O.bloc(parent, taille, cf, couleur, materiau, nom))
	piece.CanQuery = false
	piece.CanTouch = false
	return piece
end

-- On interroge exclusivement le terrain pour ne pas poser la silhouette sur un arbre.
local function sol(x, z)
	local parametres = RaycastParams.new()
	parametres.FilterType = Enum.RaycastFilterType.Include
	parametres.FilterDescendantsInstances = {workspace.Terrain}
	local resultat = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -650, 0), parametres)
	return if resultat then resultat.Position.Y else Terrain.hauteur(x, z)
end

local function tour(parent, x, z, base, hauteur)
	bloc(parent, "Tour", Vector3.new(13, hauteur, 13), CFrame.new(x, base + hauteur / 2, z), PIERRE, M.Pierre)
	bloc(parent, "CornicheTour", Vector3.new(15, 2, 15), CFrame.new(x, base + hauteur, z), PIERRE_CLAIRE, M.Pierre)
	for _, dx in {-5.4, 0, 5.4} do
		for _, dz in {-5.4, 5.4} do
			bloc(parent, "Creneau", Vector3.new(2.5, 3, 2.5), CFrame.new(x + dx, base + hauteur + 2.3, z + dz), PIERRE, M.Pierre)
		end
	end
	for _, dx in {-5.4, 5.4} do
		bloc(parent, "Creneau", Vector3.new(2.5, 3, 2.5), CFrame.new(x + dx, base + hauteur + 2.3, z), PIERRE, M.Pierre)
	end
	-- Les petites fenêtres éclairées restent de simples pièces, sans lumières coûteuses.
	for _, dy in {hauteur * 0.42, hauteur * 0.72} do
		bloc(parent, "FenetreDoree", Vector3.new(1.4, 3, 0.18), CFrame.new(x, base + dy, z + 6.6), OR, M.Neon)
	end
end

function HorizonMine.construire(carte)
	local precedent = carte:FindFirstChild("HorizonMine")
	if precedent then precedent:Destroy() end
	local decor = O.modele(carte, "HorizonMine")

	-- Haut de la façade, au-dessus et sur les côtés de l'entrée praticable.
	local falaise = O.modele(decor, "CouronnementFalaise")
	for _, cote in {-1, 1} do
		for i = 1, 5 do
			local x = cote * (31 + i * 8)
			local hauteur = 8 + (i % 3) * 4
			local piece = O.coin(falaise, Vector3.new(10, hauteur, 5), CFrame.new(x, 49 + hauteur / 2, -179) * CFrame.Angles(0, if cote < 0 then math.pi else 0, 0), if i % 2 == 0 then PIERRE else ARDOISE, M.Roche, "StrateRocheuse")
			O.decor(piece)
			piece.CanQuery = false
			piece.CanTouch = false
		end
	end

	-- Petit château de lecture lointaine posé sur le relief nord-ouest.
	-- Sa base suit le sol réel de la place, avec une fondation assez profonde.
	local x, z = -145, -202
	local base = sol(x, z) - 6
	local chateau = O.modele(decor, "ChateauLointain")
	bloc(chateau, "Fondation", Vector3.new(68, 16, 30), CFrame.new(x, base - 4, z), PIERRE, M.Roche)
	bloc(chateau, "Corps", Vector3.new(38, 25, 17), CFrame.new(x, base + 12.5, z), PIERRE, M.Pierre)
	bloc(chateau, "Corniche", Vector3.new(40, 2, 19), CFrame.new(x, base + 25.5, z), PIERRE_CLAIRE, M.Pierre)
	for _, dx in {-15, -10, -5, 0, 5, 10, 15} do
		bloc(chateau, "Creneau", Vector3.new(3, 3, 2), CFrame.new(x + dx, base + 28, z + 8), PIERRE, M.Pierre)
	end
	tour(chateau, x - 25, z, base, 35)
	tour(chateau, x + 25, z, base, 41)
	tour(chateau, x, z - 4, base + 20, 35)
	for _, dx in {-10, 0, 10} do
		bloc(chateau, "FenetreDoree", Vector3.new(2, 4, 0.2), CFrame.new(x + dx, base + 15, z + 8.6), OR, M.Neon)
	end
	bloc(chateau, "Porte", Vector3.new(6, 10, 0.25), CFrame.new(x, base + 5, z + 8.7), BOIS, M.Planches)
	bloc(chateau, "BanniereBordeaux", Vector3.new(3, 7, 0.2), CFrame.new(x + 6, base + 18, z + 8.8), Color3.fromRGB(111, 45, 59), M.Tissu)
	return decor
end

return HorizonMine
