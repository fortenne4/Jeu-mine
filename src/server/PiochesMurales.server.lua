-- Deux pioches décoratives au-dessus des épées extérieures de la forge.
local PICKAXE_LENGTH_RATIO = 1.0
local ESPACE_AU_DESSUS_EPEE = 0.5
local INCLINAISON = 0 -- degrés dans le plan du mur
local MARGE_HAUT_MUR = 1.0 -- espace au-dessus des pioches, en studs
local MARGE_BORD_MUR = 0.03
local RETRAIT_PIGNON = 0.11 -- découpe contre le pignon, sans le traverser

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

-- Prolonger uniquement le mur derrière le râtelier. Le pignon existant
-- occupe déjà l'arrière du bord supérieur : le retrait évite de le traverser.
local mur, distance = nil, math.huge
for _, candidat in forge:GetChildren() do
	if candidat:IsA("BasePart") and candidat.Name == "MurCote" and candidat.Material == Enum.Material.Plaster then
		local d = (candidat.Position - groupe:GetPivot().Position).Magnitude
		if d < distance then mur, distance = candidat, d end
	end
end
if mur then
	local zMin, zMax, yMax = math.huge, -math.huge, -math.huge
	for _, part in groupe:GetDescendants() do
		if part:IsA("BasePart") then
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local coin = part.CFrame:PointToWorldSpace(Vector3.new(x * part.Size.X / 2, y * part.Size.Y / 2, z * part.Size.Z / 2))
				local localCoin = mur.CFrame:PointToObjectSpace(coin)
				zMin, zMax = math.min(zMin, localCoin.Z), math.max(zMax, localCoin.Z)
				yMax = math.max(yMax, coin.Y)
			end end end
		end
	end
	if zMin < math.huge then
		zMin, zMax = zMin - MARGE_BORD_MUR, zMax + MARGE_BORD_MUR
		local hautMur = mur.Position.Y + mur.Size.Y / 2
		local surelevation = math.max(0, yMax + MARGE_HAUT_MUR - hautMur)
		local function extension(nom, taille, centre, reference)
			reference = reference or mur
			local morceau = Instance.new("Part")
			morceau.Name = nom
			morceau.Size, morceau.CFrame = taille, mur.CFrame * CFrame.new(centre)
			morceau.Material, morceau.Color = reference.Material, reference.Color
			morceau.Reflectance, morceau.Transparency = reference.Reflectance, reference.Transparency
			morceau.Anchored, morceau.CanCollide, morceau.CanTouch, morceau.CanQuery = true, false, false, false
			morceau.Parent = groupe
		end
		if surelevation > 0 then
			extension("MurExtensionHaut", Vector3.new(mur.Size.X - RETRAIT_PIGNON, surelevation, zMax - zMin),
				Vector3.new(-RETRAIT_PIGNON / 2, mur.Size.Y / 2 + surelevation / 2, (zMin + zMax) / 2))
		end
		local bord = -mur.Size.Z / 2
		if zMin < bord then
			extension("MurExtensionCote", Vector3.new(mur.Size.X - RETRAIT_PIGNON, mur.Size.Y, bord - zMin),
				Vector3.new(-RETRAIT_PIGNON / 2, 0, (zMin + bord) / 2))
			-- Prolonger la pierre sous la partie blanche déjà ajoutée pour les
			-- pioches, sans bouger le mur porteur ni ses armes. Le même retrait
			-- évite de traverser le colombage sur la face extérieure.
			for _, pierre in forge:GetChildren() do
				if pierre:IsA("BasePart") and pierre.Name == "MurCote" and pierre.Material == Enum.Material.Cobblestone then
					local positionLocale = mur.CFrame:PointToObjectSpace(pierre.Position)
					if math.abs(positionLocale.X) < 0.05 and math.abs(positionLocale.Z) < 0.05 then
						extension("MurExtensionPierre", Vector3.new(mur.Size.X - RETRAIT_PIGNON, pierre.Size.Y, bord - zMin),
							Vector3.new(-RETRAIT_PIGNON / 2, positionLocale.Y, (zMin + bord) / 2), pierre)
						break
					end
				end
			end
		end
	end
end
