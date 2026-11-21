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

	Épées forgées (EpeeCharbon, EpeeBronzeOr...) : modèle mesh ReplicatedStorage.EpeesMesh.<id> s'il est
	importé (assets/epees/IMPORT.md, apparence dans Partage.EpeesMeshMateriaux), même contrat ci-dessus
	(Poignee = petite Part invisible au centre de la prise) ; sinon EpeeFer teintée à la couleur du minerai.

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

-------------------------------------------------------------------- épées mesh (fidèles à la référence)
-- Si ReplicatedStorage.EpeesMesh.<id> (Model de MeshParts importé depuis assets/epees/<id>.fbx) existe,
-- il est utilisé. Apparence par sous-mesh : Partage.EpeesMeshMateriaux (généré par
-- blender/armes/epees_fideles.py). Sinon, version de secours : EpeeFer teintée à la couleur du minerai.
-- Voir assets/epees/IMPORT.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tableMesh: any = nil
local function materiauxMesh(): { [string]: any }
	if tableMesh == nil then
		tableMesh = false
		local m = script.Parent:FindFirstChild("EpeesMeshMateriaux")
		if m and m:IsA("ModuleScript") then
			local ok, res = pcall(require, m)
			if ok and type(res) == "table" then
				tableMesh = res
			end
		end
	end
	return tableMesh or {}
end

local function sourceMesh(id: string): Model?
	local dossier = ReplicatedStorage:FindFirstChild("EpeesMesh")
	local source = dossier and dossier:FindFirstChild(id)
	if source and source:IsA("Model") then
		return source
	end
	return nil
end

function ArmesVoxels.existe(id: string): boolean
	local m = script:FindFirstChild(id)
	if m ~= nil and m:IsA("ModuleScript") then
		return true
	end
	return materiauxMesh()[id] ~= nil or sourceMesh(id) ~= nil
end

function ArmesVoxels.liste(): { string }
	local t = {}
	for _, m in script:GetChildren() do
		if m:IsA("ModuleScript") then
			table.insert(t, m.Name)
		end
	end
	for id in materiauxMesh() do
		if not table.find(t, id) then
			table.insert(t, id)
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

local function attache(lame: BasePart, nom: string, pos: Vector3)
	local a = Instance.new("Attachment")
	a.Name = nom
	a.CFrame = lame.CFrame:Inverse() * CFrame.new(pos)
	a.Parent = lame
end

-- Épée mesh importée : même contrat que la version en Parts (PrimaryPart "Poignee", "Lame" + TrailA/TrailB).
local function construireMesh(id: string): Model?
	local source = sourceMesh(id)
	if not source then
		return nil
	end
	local info = materiauxMesh()[id]
	local m = source:Clone()
	m.Name = id
	m:SetAttribute("NomAffiche", if info and info.Nom then info.Nom else id)
	m:SetAttribute("Mesh", true)

	local poignee: BasePart? = nil
	local lame: BasePart? = nil
	local visibles: { BasePart } = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			p.Massless = true
			if p.Name == "Poignee" and not poignee then
				poignee = p
			else
				if p.Name == "Lame" and not lame then
					lame = p
				end
				table.insert(visibles, p)
			end
		elseif p:IsA("JointInstance") or p:IsA("WeldConstraint") then
			p:Destroy()
		end
	end
	if #visibles == 0 or not lame then
		m:Destroy()
		return nil
	end
	-- échelle d'import (unités FBX) : hauteur ramenée à celle attendue (sans Poignee ni Aura)
	if info and info.Taille then
		local bas, haut = math.huge, -math.huge
		for _, p in visibles do
			if p.Name ~= "Aura" then
				local taille = p.Size
				bas = math.min(bas, p.Position.Y - taille.Y / 2)
				haut = math.max(haut, p.Position.Y + taille.Y / 2)
			end
		end
		local ratio = info.Taille.Y / math.max(haut - bas, 1e-3)
		if math.abs(ratio - 1) > 0.03 then
			m:ScaleTo(m:GetScale() * ratio)
		end
	end
	if not poignee then -- pas de marqueur : centre de la prise = centre de la boîte - Centre attendu
		local cf = m:GetBoundingBox()
		local centre = if info and info.Centre then info.Centre else Vector3.zero
		local p = Instance.new("Part")
		p.Name = "Poignee"
		p.Size = Vector3.new(0.1, 0.1, 0.1)
		p.Position = cf.Position - centre
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.Parent = m
		poignee = p
	end
	local r = poignee :: BasePart
	r.Transparency = 1
	r.CastShadow = false
	r.CFrame = CFrame.new(r.Position) -- axes alignés : lame vers +Y, plat face à -Z
	m.PrimaryPart = r
	m:PivotTo(CFrame.identity)

	local lumieres: { [string]: boolean } = {}
	for _, p in visibles do
		local e = info and info.Parties and info.Parties[p.Name]
		if e then
			p.Material = e.Material
			p.Color = e.Color
			p.Transparency = e.Transparency or 0
			p.CastShadow = e.Material ~= Enum.Material.Neon
			if p:IsA("MeshPart") then
				p.TextureID = ""
			end
			if e.Lumiere and not lumieres[p.Name] then
				lumieres[p.Name] = true
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = e.Lumiere.Couleur, e.Lumiere.Portee, e.Lumiere.Luminosite, false
				l.Parent = p
			end
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = r
		w.Part1 = p
		w.Parent = p
	end
	local l = lame :: BasePart
	attache(l, "TrailA", if info and info.TrailA then info.TrailA else Vector3.new(0, 1, 0))
	attache(l, "TrailB", if info and info.TrailB then info.TrailB else Vector3.new(0, 3, 0))
	return m
end

-- Construit l'arme au repère d'origine (Poignee.CFrame = CFrame.identity) ; déplacer avec Model:PivotTo.
function ArmesVoxels.construire(id: string): Model
	local okMesh, mesh = pcall(construireMesh, id)
	if okMesh and mesh then
		return mesh
	elseif not okMesh then
		warn("[ArmesVoxels] mesh " .. id .. " : " .. tostring(mesh))
	end
	local module = script:FindFirstChild(id)
	if not (module and module:IsA("ModuleScript")) then
		-- épée forgée pas encore importée : EpeeFer teintée à la couleur du minerai
		-- (aussi si EpeesMesh.<id> existe mais est inutilisable : pas de Lame, pas d'entrée de matériaux)
		local info = materiauxMesh()[id]
		assert(info or sourceMesh(id), "ArmesVoxels : arme inconnue " .. id)
		local m = ArmesVoxels.construire("EpeeFer")
		m.Name = id
		m:SetAttribute("NomAffiche", if info and info.Nom then info.Nom else id)
		local teinte: Color3? = info and info.Teinte
		for _, p in m:GetDescendants() do
			if teinte and p:IsA("BasePart") and p.Material == Enum.Material.Metal then
				local _, _, v = p.Color:ToHSV()
				local th, ts, tv = teinte:ToHSV()
				p.Color = Color3.fromHSV(th, ts, math.clamp(tv * (0.55 + v * 0.6), 0, 1))
			end
		end
		return m
	end
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
