--!strict
--[[ Armes 3D (épées...) en Parts Roblox (ReplicatedStorage › Partage › ArmesVoxels).
	Les données (EpeeFer.lua...) sont générées par les scripts Blender de blender/armes/ :
	aucun import dans Studio n'est nécessaire.

	Contrat du modèle construit :
		Model (PrimaryPart = "Poignee")
		├─ Poignee : son CFrame = centre de la prise en main ; la lame pointe vers +Y local
		├─ Lame    : contient les Attachments "TrailA" (base de la lame) et "TrailB" (pointe)
		└─ autres pièces (Garde, Pommeau, Cristal...) soudées à Poignee par WeldConstraint
		Toutes les pièces : Anchored = false, CanCollide = false, Massless = true.
		Le cristal du pommeau est en Neon et porte une PointLight.

	Usage :
		local ArmesVoxels = require(ReplicatedStorage.Partage.ArmesVoxels)
		local epee = ArmesVoxels.construire("EpeeFer")
		epee:PivotTo(main.CFrame * decalage) ; puis souder Poignee à la main
]]

local ArmesVoxels = {}

local MATERIAUX: { [string]: Enum.Material } = {
	Metal = Enum.Material.Metal,
	Fabric = Enum.Material.Fabric,
	Wood = Enum.Material.Wood,
	Neon = Enum.Material.Neon,
	SmoothPlastic = Enum.Material.SmoothPlastic,
}

type Donnees = {
	Nom: string,
	Couleurs: { [string]: { any } },
	Pieces: { { any } },
	TrailA: Vector3,
	TrailB: Vector3,
	Lueur: { Couleur: Color3, Portee: number, Luminosite: number }?,
}

function ArmesVoxels.existe(id: string): boolean
	local m = script:FindFirstChild(id)
	return m ~= nil and m:IsA("ModuleScript")
end

function ArmesVoxels.liste(): { string }
	local t = {}
	for _, m in script:GetChildren() do
		if m:IsA("ModuleScript") then
			table.insert(t, m.Name)
		end
	end
	table.sort(t)
	return t
end

function ArmesVoxels.donnees(id: string): Donnees
	local module = script:FindFirstChild(id)
	assert(module and module:IsA("ModuleScript"), "ArmesVoxels : arme inconnue " .. id)
	return require(module) :: any
end

-- Construit l'arme au repère d'origine (Poignee.CFrame = CFrame.identity) ; déplacer avec Model:PivotTo.
function ArmesVoxels.construire(id: string): Model
	local d = ArmesVoxels.donnees(id)
	local modele = Instance.new("Model")
	modele.Name = id
	modele:SetAttribute("NomAffiche", d.Nom)

	local poignee: BasePart? = nil
	local lame: BasePart? = nil
	local pieces: { BasePart } = {}
	for _, pc in d.Pieces do
		local nom: string, cle: string, taille: Vector3, pos: Vector3, rotY: number = pc[1], pc[2], pc[3], pc[4], pc[5]
		local c = d.Couleurs[cle]
		local p = Instance.new("Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)
		p.Color = Color3.fromRGB(c[2], c[3], c[4])
		p.Material = MATERIAUX[c[1]] or Enum.Material.SmoothPlastic
		p.Reflectance = c[5] or 0
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.CastShadow = c[1] ~= "Neon"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = modele
		if nom == "Poignee" and not poignee then
			poignee = p
		elseif nom == "Lame" and not lame then
			lame = p
		end
		if nom == "Cristal" and d.Lueur and not p:FindFirstChildOfClass("PointLight") and taille.Y >= 0.2 then
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = d.Lueur.Couleur, d.Lueur.Portee, d.Lueur.Luminosite, false
			l.Parent = p
		end
		table.insert(pieces, p)
	end
	assert(poignee and lame, "ArmesVoxels : " .. id .. " sans Poignee ou Lame")
	modele.PrimaryPart = poignee

	for _, p in pieces do
		if p ~= poignee then
			local w = Instance.new("WeldConstraint")
			w.Part0 = poignee
			w.Part1 = p
			w.Parent = p
		end
	end

	local a = Instance.new("Attachment")
	a.Name = "TrailA"
	a.CFrame = lame.CFrame:Inverse() * CFrame.new(d.TrailA)
	a.Parent = lame
	local b = Instance.new("Attachment")
	b.Name = "TrailB"
	b.CFrame = lame.CFrame:Inverse() * CFrame.new(d.TrailB)
	b.Parent = lame
	return modele
end

return ArmesVoxels
