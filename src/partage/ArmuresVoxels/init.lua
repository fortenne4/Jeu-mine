--!strict
--[[ Armures 3D voxel (Casque, Plastron, Jambieres) en Parts Roblox (ReplicatedStorage › Partage › ArmuresVoxels).
	Données générées par blender/armes/casque.py, plastron.py, jambieres.py (aperçu commun : armure.py).
	Casques par matériau (même contrat que Casque, couleurs propres, teinte ignorée) :
		CasqueCharbon, CasqueBronze, CasqueFer : casques LISSES (Format = "Lisse"), générés par
		blender/armes/casques_lisses.py (aperçu previews/armes/Casques2.png). Primitives Ball / Cylinder / Block /
		SpecialMesh Sphere + CSG runtime (GeometryService:UnionAsync / SubtractAsync) : coque creuse qui enveloppe
		toute la tête R15 (dessus, côtés, arrière), seul le visage reste ouvert. Construit une fois (yield court au
		1er appel), mis en cache puis :Clone(). Si le CSG échoue : pièces "Secours" (ellipsoïdes) à la place.
		10 casques lisses, attribut "Rang" (échelle 1..10) : 1 CasqueCharbon, 2 CasqueBronze, 3 CasqueCharbonBronze,
		4 CasqueFer, 5 CasqueCharbonFer, 6 CasqueBronzeFer, 7 CasqueOr, 8 CasqueCharbonOr, 9 CasqueBronzeOr, 10 CasqueFerOr.
		Lumieres (PointLight / SpotLight) et Particules (ParticleEmitter discret) déclarées dans chaque module.
		Lueur.Piece (optionnel, format voxel) = nom de la pièce qui porte la PointLight (défaut "Cristal").
		Casques des minerais (Format = "Code", Parts construites en jeu, aucun asset importé), générés par
		blender/armes/casques_minerais.py d'après previews/minerais/maquette-casques-epees.png (aperçus :
		previews/armes/casques_minerais/) : CasqueQuartz, CasqueSoufre, CasqueArgent, CasqueObsidienne,
		CasqueGivrite, CasqueEmeraude, CasqueRubis, CasqueLunarite, CasqueMagmaite, CasqueDiamant,
		CasqueOrichalque, CasqueNeantite.
		Plastrons et jambières des minerais (Format = "Code", même contrat que Plastron / Jambieres, couleurs fixes),
		assortis aux casques et épées du même minerai, générés par blender/armes/armures_minerais.py (aperçus :
		previews/armes/plastrons_minerais/, jambieres_minerais/, sets_minerais/) :
		PlastronSoufre, PlastronQuartz, PlastronArgent, PlastronObsidienne, PlastronGivrite, PlastronEmeraude,
		PlastronRubis, PlastronLunarite, PlastronMagmaite, PlastronDiamant, PlastronOrichalque, PlastronNeantite ;
		JambieresSoufre, JambieresQuartz, JambieresArgent, JambieresObsidienne, JambieresGivrite, JambieresEmeraude,
		JambieresRubis, JambieresLunarite, JambieresMagmaite, JambieresDiamant, JambieresOrichalque, JambieresNeantite
		(sous-Models JambeG / JambeD + Centre construits par le module lui-même).

	construire(id, teinte?, tailleTete?) : tailleTete = taille visuelle de la tête (Vector3) ; le modèle est mis à
		l'échelle (Model:ScaleTo) par rapport à la tête R15 de référence 1.2 stud. Omis = taille 1.2.
		ArmuresVoxels.prechauffer() construit les gabarits lisses en tâche de fond.

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
	Slate = Enum.Material.Slate,
}

type Donnees = {
	Nom: string,
	Taille: Vector3,
	Couleurs: { [string]: { any } },
	Groupes: { [string]: Vector3 }?,
	Pieces: { { any } },
	Lueur: { Couleur: Color3, Portee: number, Luminosite: number, Piece: string? }?,
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

-------------------------------------------------------------------- casques lisses (CSG)
local GeometryService = game:GetService("GeometryService")

local TETE_REF = 1.2 -- taille de tête pour laquelle les modèles sont dessinés

local FORMES: { [string]: Enum.PartType } = {
	Bloc = Enum.PartType.Block,
	Boule = Enum.PartType.Ball,
	Cylindre = Enum.PartType.Cylinder,
	Ellipsoide = Enum.PartType.Block,
}

local OPTIONS_CSG = {
	CollisionFidelity = Enum.CollisionFidelity.Box,
	RenderFidelity = Enum.RenderFidelity.Precise,
	SplitApart = false,
}

local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function primitive(spec: any, nom: string?): Part
	local p = Instance.new("Part")
	p.Name = nom or "Piece"
	p.Shape = FORMES[spec.Forme] or Enum.PartType.Block
	p.Size = spec.Taille
	p.CFrame = spec.CF
	p.Anchored = false
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if spec.Forme == "Ellipsoide" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	return p
end

local function habiller(p: BasePart, c: { any })
	p.Material = materiau(c[1])
	p.Color = Color3.fromRGB(c[2], c[3], c[4])
	p.Reflectance = c[5] or 0
	p.CastShadow = c[1] ~= "Neon"
	if p:IsA("PartOperation") then
		p.UsePartColor = true
	end
end

-- Base ∪ Plus − Moins (parent = nil, ou conteneur temporaire non répliqué si GeometryService l'exige).
local function essaiCSG(spec: any, parent: Instance?): (boolean, any)
	local temporaires: { Instance } = {}
	local function prim(s: any): Part
		local q = primitive(s)
		if parent then
			q.Transparency = 1
			q.Parent = parent
		end
		table.insert(temporaires, q)
		return q
	end
	local ok, res = pcall(function(): BasePart
		local cur: BasePart = prim(spec.Base)
		if spec.Plus and #spec.Plus > 0 then
			local autres = {}
			for _, s in spec.Plus do
				table.insert(autres, prim(s))
			end
			local r = GeometryService:UnionAsync(cur, autres, OPTIONS_CSG)
			cur = r[1] :: BasePart
			table.insert(temporaires, cur)
		end
		if spec.Moins and #spec.Moins > 0 then
			local autres = {}
			for _, s in spec.Moins do
				table.insert(autres, prim(s))
			end
			local r = GeometryService:SubtractAsync(cur, autres, OPTIONS_CSG)
			cur = r[1] :: BasePart
			table.insert(temporaires, cur)
		end
		assert(typeof(cur) == "Instance" and cur:IsA("BasePart"), "résultat CSG vide")
		return cur
	end)
	for _, t in temporaires do
		if t ~= res then
			t:Destroy()
		end
	end
	if ok then
		res.Parent = nil
		res.Transparency = 0
	end
	return ok, res
end

-- nil si GeometryService refuse (le Secours prend le relais).
local function operationCSG(spec: any): BasePart?
	local ok, res = essaiCSG(spec, nil)
	if not ok then
		local cam = workspace.CurrentCamera -- non répliqué : sert de conteneur temporaire
		if cam then
			ok, res = essaiCSG(spec, cam)
		end
	end
	if ok then
		return res
	end
	warn("[ArmuresVoxels] CSG impossible, pièces de secours :", res)
	return nil
end

-- Construit le gabarit lisse (à l'origine). Renvoie aussi true si tout le CSG a réussi.
local function construireLisse(id: string, d: any): (Model, boolean)
	local modele = Instance.new("Model")
	modele.Name = id
	modele:SetAttribute("NomAffiche", d.Nom)
	if d.Rang then
		modele:SetAttribute("Rang", d.Rang)
	end
	local racine = ancre("Racine", Vector3.zero)
	racine.Parent = modele
	modele.PrimaryPart = racine

	local complet = true
	local function poser(p: BasePart, nom: string, cle: string)
		p.Name = nom
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		habiller(p, d.Couleurs[cle])
		p.Parent = modele
		souder(racine, p)
	end
	for _, pc in d.Pieces do
		if pc.Forme == "CSG" then
			local r = operationCSG(pc)
			if r then
				poser(r, pc.Nom, pc.Cle)
			else
				complet = false
				for _, s in pc.Secours or {} do
					poser(primitive(s), s.Nom, s.Cle)
				end
			end
		else
			poser(primitive(pc), pc.Nom, pc.Cle)
		end
	end
	for _, l in d.Lumieres or {} do
		local p = modele:FindFirstChild(l.Piece)
		if p then
			local lum: Light
			if l.Type == "Spot" then
				local s = Instance.new("SpotLight")
				s.Angle = l.Angle or 60
				s.Face = (Enum.NormalId :: any)[l.Face or "Front"]
				lum = s
			else
				lum = Instance.new("PointLight")
			end
			lum.Color, lum.Brightness, lum.Shadows = l.Couleur, l.Luminosite, false
			;(lum :: any).Range = l.Portee
			lum.Parent = p
		end
	end
	-- scintillement / braises discrets (casques haut de gamme)
	for _, q in d.Particules or {} do
		local p = modele:FindFirstChild(q.Piece)
		if p then
			local e = Instance.new("ParticleEmitter")
			e.Color = ColorSequence.new(q.Couleur)
			e.LightEmission = 1
			e.LightInfluence = 0
			e.Rate = q.Taux
			e.Lifetime = NumberRange.new(q.Vie * 0.6, q.Vie)
			e.Speed = NumberRange.new(q.Vitesse * 0.5, q.Vitesse)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Acceleration = Vector3.new(0, 0.6, 0)
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.3, q.Taille),
				NumberSequenceKeypoint.new(1, 0),
			})
			e.Transparency = NumberSequence.new(0.15, 1)
			e.Parent = p
		end
	end
	return modele, complet
end

local gabarits: { [string]: Model } = {}
local enCours: { [string]: boolean } = {}

local function gabaritLisse(id: string, d: any): Model
	while enCours[id] do
		task.wait()
	end
	local g = gabarits[id]
	if g then
		return g
	end
	enCours[id] = true
	local ok, m, complet = pcall(construireLisse, id, d)
	enCours[id] = nil
	if not ok then
		error(m, 0)
	end
	if complet then
		gabarits[id] = m -- un échec CSG (passager ?) sera retenté au prochain appel
	end
	return m
end

-- Construit les gabarits lisses en tâche de fond (évite l'attente au premier équipement).
function ArmuresVoxels.prechauffer()
	for _, id in ArmuresVoxels.liste() do
		local ok, d = pcall(ArmuresVoxels.donnees, id)
		if ok and (d :: any).Format == "Lisse" then
			task.spawn(pcall, gabaritLisse, id, d)
		end
	end
end

local function echelle(modele: Model, tailleTete: Vector3?)
	if not tailleTete then
		return
	end
	local f = math.clamp(math.max(tailleTete.X, tailleTete.Y, tailleTete.Z) / TETE_REF, 0.6, 3)
	if math.abs(f - 1) > 0.02 then
		modele:ScaleTo(f)
	end
end

-------------------------------------------------------------------- casques mesh (fidèles à la référence)
-- Si ReplicatedStorage.CasquesMesh.<id> (Model de MeshParts importé depuis assets/casques/<id>.fbx) existe,
-- il remplace la version "Lisse". Apparence par sous-mesh : Partage.CasquesMeshMateriaux (généré par
-- blender/armes/casques_fideles.py). Voir assets/casques/IMPORT.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tableMesh: any = nil
local function materiauxMesh(): any
	if tableMesh == nil then
		tableMesh = false
		local m = script.Parent:FindFirstChild("CasquesMeshMateriaux")
		if m and m:IsA("ModuleScript") then
			local ok, res = pcall(require, m)
			if ok and type(res) == "table" then
				tableMesh = res
			end
		end
	end
	return tableMesh or nil
end

local function construireMesh(id: string, d: any): Model?
	local dossier = ReplicatedStorage:FindFirstChild("CasquesMesh")
	local source = dossier and dossier:FindFirstChild(id)
	if not (source and source:IsA("Model")) then
		return nil
	end
	local info = (materiauxMesh() or {})[id]
	local m = source:Clone()
	m.Name = id
	m:SetAttribute("NomAffiche", d.Nom)
	if d.Rang then
		m:SetAttribute("Rang", d.Rang)
	end
	m:SetAttribute("Mesh", true)

	local racine: BasePart? = nil
	local visibles: { BasePart } = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			p.Massless = true
			if p.Name == "Racine" and not racine then
				racine = p
			else
				table.insert(visibles, p)
			end
		elseif p:IsA("JointInstance") or p:IsA("WeldConstraint") then
			p:Destroy()
		end
	end
	if #visibles == 0 then
		m:Destroy()
		return nil
	end
	-- échelle d'import (unités FBX) : on ramène la hauteur à celle attendue
	if info and info.Taille then
		local _, taille = m:GetBoundingBox()
		local ratio = info.Taille.Y / math.max(taille.Y, 1e-3) * 0.9 -- casque un peu plus petit (demande joueur)
		if math.abs(ratio - 1) > 0.03 then
			m:ScaleTo(m:GetScale() * ratio)
		end
	end
	if not racine then -- pas de marqueur : centre de la tête = centre de la boîte - Centre attendu
		local cf = m:GetBoundingBox()
		local centre = if info and info.Centre then info.Centre else Vector3.zero
		racine = ancre("Racine", cf.Position - centre)
		racine.Parent = m
	end
	local r = racine :: BasePart
	r.Transparency = 1
	r.CastShadow = false
	r.CFrame = CFrame.new(r.Position) -- axes alignés (l'import garde devant = -Z)
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
		souder(r, p)
	end
	return m
end

-- Construit la pièce à l'origine (Racine.CFrame = CFrame.identity) ; déplacer avec Model:PivotTo.
-- tailleTete (casques) : taille visuelle de la tête porteuse, pour mettre le casque à l'échelle.
function ArmuresVoxels.construire(id: string, teinte: Color3?, tailleTete: Vector3?, forcerLisse: boolean?): Model
	local d = ArmuresVoxels.donnees(id)
	if not forcerLisse then
		local ok, mesh = pcall(construireMesh, id, d)
		if ok and mesh then
			echelle(mesh, tailleTete)
			return mesh
		elseif not ok then
			warn("[ArmuresVoxels] casque mesh illisible, version lisse :", id, mesh)
		end
	end
	if (d :: any).Format == "Code" then
		local m = (d :: any).construire()
		echelle(m, tailleTete)
		return m
	end
	if (d :: any).Format == "Lisse" then
		local g = gabaritLisse(id, d)
		local m = if gabarits[id] == g then g:Clone() else g
		echelle(m, tailleTete)
		return m
	end
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
		if d.Lueur and not lumiereFaite and nom == (d.Lueur.Piece or "Cristal") then
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
	echelle(modele, tailleTete)
	return modele
end

return ArmuresVoxels
