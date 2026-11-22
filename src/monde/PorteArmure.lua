-- Support médiéval décoratif : le repère fourni est au centre du socle, au niveau du sol.
-- L'avant est dirigé vers -Z, comme pour les bâtiments du village.
local O = require(script.Parent.Outils)

local PorteArmure = {}
local BOIS = Color3.fromRGB(91, 58, 35)
local BOIS_CLAIR = Color3.fromRGB(125, 84, 50)
local FER = Color3.fromRGB(48, 44, 42)

-- À l'échelle 1 : hauteur 6,2 studs, socle 3,8 × 2,8 studs ;
-- épaules à Y=4,75 et tête centrée à Y=5,6 depuis le sol.
function PorteArmure.creer(parent: Instance, cf: CFrame, echelle: number?, couleurs: {[string]: Color3}?): Model
	local s = echelle or 1
	local palette = couleurs or {}
	local bois = palette.Bois or BOIS
	local clair = palette.BoisClair or BOIS_CLAIR
	local fer = palette.Fer or FER
	local modele = Instance.new("Model")
	modele.Name = "PorteArmure"
	local function piece(nom: string, taille: Vector3, localCF: CFrame, couleur: Color3, materiau: Enum.Material): BasePart
		local p = O.bloc(modele, taille * s, cf * CFrame.new(localCF.Position * s) * localCF.Rotation, couleur, materiau, nom)
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		return p
	end
	-- Pivot invisible exactement au centre du socle ; il sert à déplacer le mannequin entier.
	local ancrage = piece("Ancrage", Vector3.new(0.1, 0.1, 0.1), CFrame.identity, bois, Enum.Material.Wood)
	ancrage.Transparency = 1
	modele.PrimaryPart = ancrage
	piece("SocleLarge", Vector3.new(3.8, 0.32, 0.85), CFrame.new(0, 0.16, 0), bois, Enum.Material.WoodPlanks)
	piece("SocleTraverse", Vector3.new(0.85, 0.32, 2.8), CFrame.new(0, 0.16, 0), bois, Enum.Material.WoodPlanks)
	piece("SocleDessus", Vector3.new(1.15, 0.15, 1.15), CFrame.new(0, 0.395, 0), clair, Enum.Material.Wood)
	piece("PoteauCentral", Vector3.new(0.52, 4.95, 0.52), CFrame.new(0, 2.87, 0), bois, Enum.Material.Wood)
	piece("TraverseEpaules", Vector3.new(2.7, 0.4, 0.42), CFrame.new(0, 4.7, 0), clair, Enum.Material.Wood)
	-- Deux bras courtes inclinées, sans articulations ni humain caché.
	for _, cote in {-1, 1} do
		piece("BrasBois", Vector3.new(0.34, 1.45, 0.34), CFrame.new(cote * 1.42, 3.97, 0) * CFrame.Angles(0, 0, cote * math.rad(13)), bois, Enum.Material.Wood)
		piece("FerrureBras", Vector3.new(0.43, 0.18, 0.43), CFrame.new(cote * 1.28, 4.62, 0), fer, Enum.Material.Metal)
		piece("RivetSocle", Vector3.new(0.14, 0.07, 0.14), CFrame.new(cote * 1.5, 0.36, 0), fer, Enum.Material.Metal)
		piece("RenfortSocle", Vector3.new(0.18, 0.13, 0.85), CFrame.new(cote * 1.63, 0.385, 0), fer, Enum.Material.Metal)
	end
	piece("Cou", Vector3.new(0.45, 0.55, 0.45), CFrame.new(0, 5.05, 0), bois, Enum.Material.Wood)
	piece("TeteBois", Vector3.new(0.95, 1.15, 0.85), CFrame.new(0, 5.72, 0), clair, Enum.Material.Wood)
	piece("CollierFer", Vector3.new(0.63, 0.18, 0.63), CFrame.new(0, 4.38, 0), fer, Enum.Material.Metal)
	modele:SetAttribute("EchelleSupport", s)
	modele.Parent = parent
	return modele
end

return PorteArmure
