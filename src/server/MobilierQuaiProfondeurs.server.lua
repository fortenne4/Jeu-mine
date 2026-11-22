-- Mobilier décoratif du quai souterrain, disposé contre le bord extérieur.
local X_BORD = -17.2
local Z_BANC = -384.5
local Z_BACS = {-391.5, -395.5}
local PORTEE_LUMIERE = 16
local INTENSITE_LUMIERE = 1.2
local LARGEUR_MINERAI = 1.5
local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local caverne = carte and carte:FindFirstChild("Caverne", true)
local quai = caverne and caverne:FindFirstChild("Quai")
if not (caverne and quai and quai:IsA("BasePart")) then
	warn("[MobilierQuaiProfondeurs] Quai introuvable")
	return
end
if caverne:FindFirstChild("MobilierQuaiProfondeurs") then return end

local ySol = quai.Position.Y + quai.Size.Y / 2
local mobilier = Instance.new("Model")
mobilier.Name = "MobilierQuaiProfondeurs"
mobilier.Parent = caverne
local bois, cerclage = Color3.fromRGB(111, 64, 37), Color3.fromRGB(61, 46, 36)

local function bloc(parent, nom, taille, position, couleur, materiau)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = nom, taille, CFrame.new(position)
	p.Color, p.Material = couleur, materiau
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local banc = Instance.new("Model")
banc.Name, banc.Parent = "Banc", mobilier
bloc(banc, "Assise", Vector3.new(1.5, 0.25, 4), Vector3.new(X_BORD, ySol + 1.15, Z_BANC), bois, Enum.Material.WoodPlanks)
bloc(banc, "Dossier", Vector3.new(0.2, 1.4, 4), Vector3.new(X_BORD - 0.66, ySol + 1.95, Z_BANC), bois, Enum.Material.WoodPlanks)
for _, dz in {-1.5, 1.5} do
	for _, dx in {-0.48, 0.48} do
		bloc(banc, "Pied", Vector3.new(0.24, 1.05, 0.24), Vector3.new(X_BORD + dx, ySol + 0.525, Z_BANC + dz), cerclage, Enum.Material.Wood)
	end
end

for index, z in Z_BACS do
	local nom = if index == 1 then "Charbon" else "Or"
	local bac = Instance.new("Model")
	bac.Name, bac.Parent = "Bac" .. nom, mobilier
	local centre = Vector3.new(X_BORD, ySol, z)
	bloc(bac, "Fond", Vector3.new(2, 0.16, 2), centre + Vector3.new(0, 0.08, 0), bois, Enum.Material.WoodPlanks)
	for _, signe in {-1, 1} do
		bloc(bac, "Paroi", Vector3.new(0.16, 1.15, 2), centre + Vector3.new(signe * 0.92, 0.66, 0), bois, Enum.Material.WoodPlanks)
		bloc(bac, "Paroi", Vector3.new(1.68, 1.15, 0.16), centre + Vector3.new(0, 0.66, signe * 0.92), bois, Enum.Material.WoodPlanks)
	end
	-- Reprendre la géométrie, les matériaux et les couleurs des minerais minables.
	-- Le modèle est réduit uniformément pour tenir dans le bac et reste décoratif.
	local idMinerai = if index == 1 then "Charbon" else "Gold"
	local minerai = MineraisModeles.construire(idMinerai, CFrame.new(), Random.new(910 + index), true)
	local taille = minerai:GetExtentsSize()
	minerai:ScaleTo(LARGEUR_MINERAI / math.max(taille.X, taille.Z))
	local boite, dimensions = minerai:GetBoundingBox()
	local cible = centre + Vector3.new(0, 0.6 + dimensions.Y / 2, 0)
	minerai:PivotTo(minerai:GetPivot() + (cible - boite.Position))
	for _, piece in minerai:GetDescendants() do
		if piece:IsA("BasePart") then
			piece.Anchored, piece.CanCollide, piece.CanTouch, piece.CanQuery = true, false, false, false
		end
	end
	minerai.Parent = bac
end

-- Halo chaud discret, limité au mobilier ; aucune collision ni lumière globale.
local supportLumiere = bloc(mobilier, "SupportLumiere", Vector3.new(0.1, 0.1, 0.1),
	Vector3.new(X_BORD, ySol + 4, (Z_BANC + Z_BACS[1]) / 2), bois, Enum.Material.SmoothPlastic)
supportLumiere.Transparency = 1
local lumiere = Instance.new("PointLight")
lumiere.Name = "LumiereMobilier"
lumiere.Color = Color3.fromRGB(255, 191, 112)
lumiere.Brightness, lumiere.Range, lumiere.Shadows = INTENSITE_LUMIERE, PORTEE_LUMIERE, false
lumiere.Parent = supportLumiere
