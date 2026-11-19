--!strict
--[[ Armures 3D voxel (Casque, Plastron, Jambieres) en Parts Roblox (ReplicatedStorage › Partage › ArmuresVoxels).
	Données générées par blender/armes/casque.py, plastron.py, jambieres.py (aperçu commun : armure.py).

	Contrat du modèle construit (à l'origine : Racine.CFrame = CFrame.identity) :
		Model "<id>" (PrimaryPart = "Racine", attribut NomAffiche)
		├─ Racine : Part invisible (0.2 stud, Transparency 1) au centre de la pièce
		│    Casque   : centre de la tête R15     Plastron : centre de l'UpperTorso
		│    Jambieres: entre les deux jambes, à hauteur du genou (hanches y = +1, chevilles y = -1)
		├─ pièces visibles soudées à Racine (WeldConstraint)
		└─ Jambieres seulement : sous-Models "JambeG" (x = -0.5, gauche du perso) et "JambeD" (x = +0.5),
		   chacun avec PrimaryPart "Centre" (invisible, centre de la jambe) ; les pièces d'une jambe sont
		   soudées à son Centre, et chaque Centre est soudé à Racine.
		   Pour porter : détruire la soudure Centre<->Racine puis souder Centre à la jambe.
		Devant = -Z (LookVector), haut = +Y, droite du perso = +X. Unités = studs.
		Toutes les Parts : Anchored = false, CanCollide/CanQuery/CanTouch = false, Massless = true.
		Métal teintable : attribut Teinte = true (+ TeinteFacteur : 1 = métal principal, 0.72 = métal sombre).
		Cuir, rivets, cristal : couleur fixe. Le cristal (Neon) du Casque / Plastron porte une PointLight.

	Usage :
		local ArmuresVoxels = require(ReplicatedStorage.Partage.ArmuresVoxels)
		local casque = ArmuresVoxels.construire("Casque", Color3.fromRGB(214, 168, 72))
		ArmuresVoxels.teinter(casque, autreCouleur)   -- re-teinter plus tard
]]

local ArmuresVoxels = {}

local MATERIAUX: { [string]: Enum.Material } = {
	Metal = Enum.Material.Metal,
	Fabric = Enum.Material.Fabric,
	Neon = Enum.Material.Neon,
	SmoothPlastic = Enum.Material.SmoothPlastic,
}

type Donnees = {
	Nom: string,
	Taille: Vector3,
	Couleurs: { [string]: { any } },
	Groupes: { [string]: Vector3 }?,
	Pieces: { { any } },
	Lueur: { Couleur: Color3, Portee: number, Luminosite: number }?,
}

function ArmuresVoxels.existe(id: string): boolean
	local m = script:FindFirstChild(id)
	return m ~= nil and m:IsA("ModuleScript")
end

function ArmuresVoxels.liste(): { string }
	local t = {}
	for _, m in script:GetChildren() do
		if m:IsA("ModuleScript") then
			table.insert(t, m.Name)
		end
	end
	table.sort(t)
	return t
end

function ArmuresVoxels.donnees(id: string): Donnees
	local module = script:FindFirstChild(id)
	assert(module and module:IsA("ModuleScript"), "ArmuresVoxels : pièce inconnue " .. id)
	return require(module) :: any
end

local function teinteDe(teinte: Color3, facteur: number): Color3
	return Color3.new(
		math.clamp(teinte.R * facteur, 0, 1),
		math.clamp(teinte.G * facteur, 0, 1),
		math.clamp(teinte.B * facteur, 0, 1)
	)
end

-- Applique la couleur d'alliage à toutes les Parts Teinte = true du modèle (métal sombre = teinte x facteur).
function ArmuresVoxels.teinter(modele: Instance, teinte: Color3)
	for _, p in modele:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Teinte") == true then
			local f = p:GetAttribute("TeinteFacteur")
			p.Color = teinteDe(teinte, if typeof(f) == "number" then f else 1)
		end
	end
end

local function nouvellePart(nom: string, taille: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.CFrame = cf
	p.Anchored = false
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

local function ancre(nom: string, pos: Vector3): Part
	local p = nouvellePart(nom, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos))
	p.Transparency = 1
	p.CastShadow = false
	return p
end

local function souder(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

-- Construit la pièce à l'origine (Racine.CFrame = CFrame.identity) ; déplacer avec Model:PivotTo.
function ArmuresVoxels.construire(id: string, teinte: Color3?): Model
	local d = ArmuresVoxels.donnees(id)
	local modele = Instance.new("Model")
	modele.Name = id
	modele:SetAttribute("NomAffiche", d.Nom)

	local racine = ancre("Racine", Vector3.zero)
	racine.Parent = modele
	modele.PrimaryPart = racine

	-- sous-groupes (JambeG / JambeD) : Model + PrimaryPart "Centre" soudé à Racine
	local centres: { [string]: Part } = {}
	local groupes: { [string]: Model } = {}
	if d.Groupes then
		for nom, pos in d.Groupes do
			local g = Instance.new("Model")
			g.Name = nom
			local c = ancre("Centre", pos)
			c.Parent = g
			g.PrimaryPart = c
			g.Parent = modele
			souder(racine, c)
			centres[nom] = c
			groupes[nom] = g
		end
	end

	local lumiereFaite = false
	for _, pc in d.Pieces do
		local nom: string, cle: string, taille: Vector3, pos: Vector3, rotY: number, grp: string? =
			pc[1], pc[2], pc[3], pc[4], pc[5], pc[6]
		local c = d.Couleurs[cle]
		local p = nouvellePart(nom, taille, CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0))
		p.Material = MATERIAUX[c[1]] or Enum.Material.SmoothPlastic
		p.Reflectance = c[5] or 0
		p.CastShadow = c[1] ~= "Neon"
		local facteur: number? = c[6]
		if facteur then
			p:SetAttribute("Teinte", true)
			p:SetAttribute("TeinteFacteur", facteur)
		end
		p.Color = if facteur and teinte then teinteDe(teinte, facteur) else Color3.fromRGB(c[2], c[3], c[4])
		if nom == "Cristal" and d.Lueur and not lumiereFaite then
			lumiereFaite = true
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = d.Lueur.Couleur, d.Lueur.Portee, d.Lueur.Luminosite, false
			l.Parent = p
		end
		if grp and groupes[grp] then
			p.Parent = groupes[grp]
			souder(centres[grp], p)
		else
			p.Parent = modele
			souder(racine, p)
		end
	end
	return modele
end

return ArmuresVoxels
