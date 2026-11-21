-- Petits accessoires décoratifs du village : sans collision ni logique de jeu.
local O = require(script.Parent.Outils)
local M = O.M
local DecorVillage = {}

local BOIS = Color3.fromRGB(83, 53, 40)
local TISSU = Color3.fromRGB(112, 43, 55)
local FER = Color3.fromRGB(185, 174, 161)
local OR = Color3.fromRGB(225, 166, 66)

local function piece(parent, nom, taille, cf, couleur, materiau)
	local p = O.decor(O.bloc(parent, taille, cf, couleur, materiau, nom))
	p.CanTouch = false
	p.CanQuery = false
	return p
end

-- Toutes les coordonnées sont hors des grands axes et des échoppes.
-- Les objets sont purement décoratifs, même si un chemin est déplacé plus tard.
local function banniere(parent, position)
	local face = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	local m = O.modele(parent, "BanniereDesMineurs")
	piece(m, "Poteau", Vector3.new(0.3, 9, 0.3), face * CFrame.new(0, 4.5, 0), BOIS, M.Bois)
	piece(m, "Traverse", Vector3.new(4.3, 0.25, 0.3), face * CFrame.new(0, 8.2, 0), BOIS, M.Bois)
	piece(m, "TissuBordeaux", Vector3.new(3.6, 4.8, 0.14), face * CFrame.new(0, 5.6, 0), TISSU, M.Tissu)
	for _, sens in {-1, 1} do
		local axe = face * CFrame.new(0, 5.65, -0.12) * CFrame.Angles(0, 0, sens * math.rad(43))
		piece(m, "ManchePioche", Vector3.new(0.16, 2.55, 0.12), axe, OR, M.Metal)
		piece(m, "TetePioche", Vector3.new(1.15, 0.17, 0.14), axe * CFrame.new(0, 1.13, 0), FER, M.Metal)
	end
end

local function caisseMinerai(parent, position, angle)
	local m = O.modele(parent, "CaisseDeMineraiDecorative")
	local cf = CFrame.new(position) * CFrame.Angles(0, angle, 0)
	piece(m, "Caisse", Vector3.new(2.4, 1.55, 2.2), cf * CFrame.new(0, 0.8, 0), BOIS, M.Planches)
	for _, x in {-0.8, 0.8} do
		piece(m, "Renfort", Vector3.new(0.18, 1.6, 0.12), cf * CFrame.new(x, 0.8, -1.12), Color3.fromRGB(54, 39, 34), M.Bois)
	end
	for _, pepite in {{-0.6, -0.3, 0.55}, {0.15, 0.3, 0.62}, {0.65, -0.2, 0.42}} do
		local p = O.decor(O.ellipsoide(m, Vector3.new(pepite[3], pepite[3] * 0.7, pepite[3]), cf * CFrame.new(pepite[1], 1.62, pepite[2]), OR, M.Metal, "Pepite"))
		p.CanTouch = false
		p.CanQuery = false
	end
end

function DecorVillage.construire(carte)
	local precedent = carte:FindFirstChild("DecorVillage")
	if precedent then precedent:Destroy() end
	local decor = O.modele(carte, "DecorVillage")
	for _, position in {Vector3.new(-76, 0, -67), Vector3.new(76, 0, -67)} do
		banniere(decor, position)
	end
	caisseMinerai(decor, Vector3.new(-78, 0, -82), 0.25)
	caisseMinerai(decor, Vector3.new(78, 0, -82), -0.25)
	return decor
end

return DecorVillage
