-- Deux pioches décoratives au-dessus des épées extérieures de la forge.
local PICKAXE_LENGTH_RATIO = 1.0
local ESPACE_AU_DESSUS_EPEE = 0.5
local INCLINAISON = 0 -- degrés dans le plan du mur

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("PiochesVoxels"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local forge = carte and carte:FindFirstChild("Forge", true)
if not forge then warn("[PiochesMurales] Forge introuvable") return end
if forge:FindFirstChild("Forge_PiochesMurales") then return end

local groupe = Instance.new("Model")
groupe.Name = "Forge_PiochesMurales"
groupe.Parent = forge
for _, epee in forge:GetChildren() do
	if not (epee:IsA("Model") and epee.Name == "Epee") then continue end
	local lame, garde, poignee, pommeau = epee:FindFirstChild("Lame"), epee:FindFirstChild("Garde"), epee:FindFirstChild("Poignee"), epee:FindFirstChild("Pommeau")
	if not (lame and garde and poignee and pommeau and lame:IsA("BasePart") and garde:IsA("BasePart") and poignee:IsA("BasePart") and pommeau:IsA("BasePart")) then continue end
	-- Conserver les deux emplacements extérieurs : le modèle doré central
	-- ne laisserait pas assez de largeur pour des pioches grandeur nature.
	if lame.Material ~= Enum.Material.Neon and lame.Color.R > 0.9 then continue end
	local pioche = Pioches.construire("Fer")
	if not pioche then warn("[PiochesMurales] Modèle Fer indisponible") break end
	local nomLame = if lame.Material == Enum.Material.Neon then "Cyan" elseif lame.Color.R > 0.9 then "Doree" else "Grise"
	pioche.Name = "Pioche_Epee_" .. nomLame
	pioche:SetAttribute("CouleurEpee", lame.Color)
	-- Les blocs hauts de la pioche Fer composent la tête ; les pièces basses
	-- en métal sont ses ferrures et les autres blocs forment le manche.
	for _, p in pioche:GetDescendants() do
		if p:IsA("BasePart") then
			local source = if p.Material == Enum.Material.Metal and p.Position.Y > 1.1 then lame
				elseif p.Material == Enum.Material.Metal then garde else poignee
			p.Material, p.Color, p.Reflectance, p.Transparency = source.Material, source.Color, source.Reflectance, source.Transparency
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		elseif p:IsA("BaseScript") or p:IsA("Tool") or p:IsA("ProximityPrompt") or p:IsA("Humanoid") then
			p:Destroy()
		end
	end
	local _, tailleEpee = epee:GetBoundingBox()
	local _, taillePioche = pioche:GetBoundingBox()
	pioche:ScaleTo(PICKAXE_LENGTH_RATIO * tailleEpee.Y / taillePioche.Y)
	-- Le manche suit Y ; le profil du pic (axe Z du modèle) longe le mur.
	local rotation = CFrame.Angles(0, math.rad(90), 0)
	local centreEpee = epee:GetBoundingBox()
	local hauteurCentre = centreEpee.Position.Y + tailleEpee.Y / 2 + ESPACE_AU_DESSUS_EPEE + tailleEpee.Y * PICKAXE_LENGTH_RATIO / 2
	local cadre = CFrame.new(lame.Position.X, hauteurCentre, lame.Position.Z) * lame.CFrame.Rotation
	pioche:PivotTo(cadre * CFrame.Angles(0, 0, math.rad(INCLINAISON)) * rotation)
	-- Centrer la boîte après rotation, sans supposer que le pivot du modèle
	-- coïncide avec le milieu de ses blocs.
	local boite = pioche:GetBoundingBox()
	pioche:PivotTo(pioche:GetPivot() + (cadre.Position - boite.Position))
	pioche.Parent = groupe
	for _, signe in {-1, 1} do
		local crochet = Instance.new("Part")
		crochet.Name = "Crochet"
		crochet.Size = Vector3.new(0.15, 0.28, 0.2)
		crochet.CFrame = cadre * CFrame.new(signe * 0.22, tailleEpee.Y * PICKAXE_LENGTH_RATIO * 0.32, 0)
		crochet.Color, crochet.Material = garde.Color, garde.Material
		crochet.Anchored, crochet.CanCollide, crochet.CanTouch, crochet.CanQuery = true, false, false, false
		crochet.Parent = pioche
	end
end
