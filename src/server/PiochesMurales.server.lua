-- Deux pioches décoratives au-dessus des épées extérieures de la forge.
local PICKAXE_LENGTH_RATIO = 0.7
local ESPACE_AU_DESSUS_EPEE = 0.45
local MARGE_HAUT_MUR = 0.4
local MARGE_BORD_MUR = 0.2
local VERSION_PRESENTOIR = 3

local PiochesModeles = require(script.Parent:WaitForChild("PiochesModeles"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local forge = carte and carte:FindFirstChild("Forge", true)
if not forge then warn("[PiochesMurales] Forge introuvable") return end
local ancien = forge:FindFirstChild("Forge_PiochesMurales")
if ancien and ancien:GetAttribute("Version") == VERSION_PRESENTOIR then return end

local groupe = Instance.new("Model")
groupe.Name = "Forge_PiochesMurales"
groupe:SetAttribute("Version", VERSION_PRESENTOIR)
for _, epee in forge:GetChildren() do
	if not (epee:IsA("Model") and epee.Name == "Epee") then continue end
	local lame, garde, poignee, pommeau = epee:FindFirstChild("Lame"), epee:FindFirstChild("Garde"), epee:FindFirstChild("Poignee"), epee:FindFirstChild("Pommeau")
	if not (lame and garde and poignee and pommeau and lame:IsA("BasePart") and garde:IsA("BasePart") and poignee:IsA("BasePart") and pommeau:IsA("BasePart")) then continue end
	-- Les pioches occupent les deux emplacements extérieurs du râtelier.
	if lame.Material ~= Enum.Material.Neon and lame.Color.R > 0.9 then continue end
	local mur, distance = nil, math.huge
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and p.Name == "MurCote" and p.Material == Enum.Material.Plaster then
			local d = (p.Position - lame.Position).Magnitude
			if d < distance then mur, distance = p, d end
		end
	end
	if not mur then continue end
	local centreEpee, tailleEpee = epee:GetBoundingBox()
	local basPioche = centreEpee.Position.Y + tailleEpee.Y / 2 + ESPACE_AU_DESSUS_EPEE
	local hautMur = mur.Position.Y + mur.Size.Y / 2 - MARGE_HAUT_MUR
	local hauteur = math.min(PICKAXE_LENGTH_RATIO * tailleEpee.Y, hautMur - basPioche)
	if hauteur < 1.5 then continue end
	local id = if lame.Material == Enum.Material.Neon then "Givre" else "Volcan"
	local modele = PiochesModeles.gabarit(id)
	if not modele then continue end
	local pioche = modele:Clone()
	pioche.Name = "Pioche_" .. id
	pioche:SetAttribute("ModelePioche", id)
	local _, taillePioche = pioche:GetBoundingBox()
	pioche:ScaleTo(pioche:GetScale() * hauteur / taillePioche.Y)
	-- Le manche suit Y ; le profil du pic (axe Z du modèle) longe le mur.
	local rotation = CFrame.Angles(0, math.rad(90), 0)
	local cadre = CFrame.new(lame.Position.X, basPioche + hauteur / 2, lame.Position.Z) * lame.CFrame.Rotation
	pioche:PivotTo(cadre * rotation)
	local boite, taille = pioche:GetBoundingBox()
	local axe = mur.CFrame.ZVector
	local demiLargeur = (math.abs(axe:Dot(boite.XVector)) * taille.X + math.abs(axe:Dot(boite.ZVector)) * taille.Z) / 2
	local limite = mur.Size.Z / 2 - demiLargeur - MARGE_BORD_MUR
	if limite < 0 then
		pioche:Destroy()
		continue
	end
	local z = mur.CFrame:PointToObjectSpace(cadre.Position).Z
	cadre += axe * (math.clamp(z, -limite, limite) - z)
	pioche:PivotTo(pioche:GetPivot() + (cadre.Position - boite.Position))
	pioche.Parent = groupe
	local crochet = Instance.new("Part")
	crochet.Name = "Crochet"
	crochet.Size = Vector3.new(0.3, 0.27, 0.73)
	crochet.CFrame = cadre * CFrame.new(0, -hauteur * 0.3, 0.29)
	crochet.Color, crochet.Material = garde.Color, garde.Material
	crochet.Anchored, crochet.CanCollide, crochet.CanTouch, crochet.CanQuery = true, false, false, false
	crochet.Parent = pioche
end
if #groupe:GetChildren() ~= 2 then
	groupe:Destroy()
	warn("[PiochesMurales] Impossible de monter les deux pioches de la forge")
	return
end
groupe.Parent = forge
if ancien then ancien:Destroy() end
