-- Outils de construction partagés : blocs, cylindres, lumières, textes, particules.
local CollectionService = game:GetService("CollectionService")

local Outils = {}

-- Certains matériaux récents peuvent manquer selon la version : on prend un remplaçant.
local function materiau(nom, defaut)
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	if ok and m then
		return m
	end
	return defaut
end
Outils.materiau = materiau

Outils.M = {
	Bois = Enum.Material.Wood,
	Planches = Enum.Material.WoodPlanks,
	Pierre = Enum.Material.Cobblestone,
	Ardoise = Enum.Material.Slate,
	Granite = Enum.Material.Granite,
	Brique = Enum.Material.Brick,
	Metal = Enum.Material.Metal,
	Rouille = Enum.Material.CorrodedMetal,
	Tissu = Enum.Material.Fabric,
	Neon = Enum.Material.Neon,
	Verre = Enum.Material.Glass,
	Lisse = Enum.Material.SmoothPlastic,
	Gravier = Enum.Material.Pebble,
	Herbe = Enum.Material.Grass,
	Roche = materiau("Rock", Enum.Material.Slate),
	Platre = materiau("Plaster", Enum.Material.Concrete),
	Tuiles = materiau("ClayRoofTiles", Enum.Material.Slate),
	Terre = materiau("Ground", Enum.Material.Sand),
	Paves = materiau("Pavement", Enum.Material.Cobblestone),
	Calcaire = materiau("Limestone", Enum.Material.Concrete),
	Cuir = materiau("Leather", Enum.Material.Fabric),
}

Outils.C = {
	BoisFonce = Color3.fromRGB(58, 40, 29),
	Bois = Color3.fromRGB(102, 72, 48),
	BoisClair = Color3.fromRGB(146, 108, 74),
	Tronc = Color3.fromRGB(74, 56, 44),
	Pierre = Color3.fromRGB(128, 120, 110),
	PierreClaire = Color3.fromRGB(170, 160, 146),
	PierreFoncee = Color3.fromRGB(82, 78, 74),
	Roche = Color3.fromRGB(96, 90, 86),
	Brique = Color3.fromRGB(122, 72, 56),
	Platre = Color3.fromRGB(216, 198, 166),
	Ocre = Color3.fromRGB(200, 162, 112),
	PlatreGris = Color3.fromRGB(184, 176, 164),
	Toit = Color3.fromRGB(74, 64, 70),
	ToitRouge = Color3.fromRGB(132, 66, 50),
	Volet = Color3.fromRGB(56, 82, 74),
	Fer = Color3.fromRGB(64, 64, 70),
	Rail = Color3.fromRGB(96, 92, 92),
	Or = Color3.fromRGB(242, 198, 96),
	Lumiere = Color3.fromRGB(255, 172, 86),
	Fenetre = Color3.fromRGB(255, 164, 78),
	Vitre = Color3.fromRGB(70, 84, 96),
	Cristal = Color3.fromRGB(110, 205, 255),
	CristalViolet = Color3.fromRGB(178, 118, 255),
	Eau = Color3.fromRGB(52, 104, 112),
	Paves = Color3.fromRGB(124, 116, 106),
	Terre = Color3.fromRGB(112, 88, 64),
	Toile = Color3.fromRGB(228, 214, 186),
}

local M, C = Outils.M, Outils.C

function Outils.modele(parent, nom)
	local m = Instance.new("Model")
	m.Name = nom
	m.Parent = parent
	return m
end

local function regler(p, taille, cf, couleur, mat, nom)
	p.Name = nom
	p.Anchored = true
	p.Size = taille
	p.CFrame = cf
	p.Color = couleur
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function Outils.bloc(parent, taille, cf, couleur, mat, nom)
	local p = regler(Instance.new("Part"), taille, cf, couleur, mat, nom or "Bloc")
	p.Parent = parent
	return p
end

-- Coin (WedgePart) : face haute à l'arrière (+Z), pente qui descend vers l'avant (-Z)
function Outils.coin(parent, taille, cf, couleur, mat, nom)
	local p = regler(Instance.new("WedgePart"), taille, cf, couleur, mat, nom or "Coin")
	p.Parent = parent
	return p
end

-- Disque / roue : l'axe suit l'axe X du CFrame
function Outils.disque(parent, epaisseur, diametre, cf, couleur, mat, nom)
	local p = regler(Instance.new("Part"), Vector3.new(epaisseur, diametre, diametre), cf, couleur, mat, nom or "Disque")
	p.Shape = Enum.PartType.Cylinder
	p.Parent = parent
	return p
end

-- Cylindre debout : l'axe suit l'axe Y du CFrame
function Outils.cylindre(parent, hauteur, diametre, cf, couleur, mat, nom)
	return Outils.disque(parent, hauteur, diametre, cf * CFrame.Angles(0, 0, math.pi / 2), couleur, mat, nom or "Cylindre")
end

function Outils.ellipsoide(parent, taille, cf, couleur, mat, nom)
	local p = Outils.bloc(parent, taille, cf, couleur, mat, nom or "Ellipsoide")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Pièce purement décorative : on passe à travers, la pioche l'ignore
function Outils.decor(p)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return p
end

function Outils.decorModele(m)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			Outils.decor(d)
		end
	end
	return m
end

function Outils.lumiere(parent, couleur, luminosite, portee, ombres)
	local l = Instance.new("PointLight")
	l.Color = couleur
	l.Brightness = luminosite
	l.Range = math.min(portee, 60)
	l.Shadows = ombres == true
	l.Parent = parent
	return l
end

function Outils.tag(instance, tag)
	CollectionService:AddTag(instance, tag)
	return instance
end

-- Modèle animé côté client : il arrive en entier chez le joueur
function Outils.atomique(m)
	pcall(function()
		local modele: any = m
		modele.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	return m
end

-- Texte gravé sur une face d'une pièce
function Outils.texte(part, face, texte, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui")
	g.Name = "Texte" .. face.Name
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = opts.ppp or 40
	g.LightInfluence = opts.lumiere or 0.3
	g.Parent = part
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.92, 0.8)
	t.Position = UDim2.fromScale(0.04, 0.1)
	t.Font = opts.police or Enum.Font.Antique
	t.Text = texte
	t.TextScaled = true
	t.TextColor3 = opts.couleur or C.Or
	t.TextStrokeColor3 = Color3.fromRGB(24, 14, 8)
	t.TextStrokeTransparency = 0.25
	t.Parent = g
	return g
end

-- Étiquette flottante (nom + rôle) au-dessus d'un PNJ ou d'un lieu
function Outils.etiquette(part, titre, sousTitre, hauteur)
	local b = Instance.new("BillboardGui")
	b.Name = "Etiquette"
	b.Size = UDim2.new(10, 0, 2.4, 0)
	b.StudsOffset = Vector3.new(0, hauteur or 2.4, 0)
	b.MaxDistance = 70
	b.LightInfluence = 0
	b.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.55)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Text = titre
	t.Parent = b
	if sousTitre then
		local s = t:Clone()
		s.Position = UDim2.fromScale(0, 0.58)
		s.Size = UDim2.fromScale(1, 0.4)
		s.Font = Enum.Font.Fantasy
		s.TextColor3 = C.Or
		s.Text = sousTitre
		s.Parent = b
	end
	return b
end

-- ===== Particules =====
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"

local function emetteur(parent, props)
	local e: any = Instance.new("ParticleEmitter")
	for cle, valeur in props do
		e[cle] = valeur
	end
	e.Parent = parent
	return e
end

function Outils.fumee(parent, taux, couleur)
	return emetteur(parent, {
		Name = "Fumee",
		Texture = TEX_FUMEE,
		Color = ColorSequence.new(couleur or Color3.fromRGB(150, 140, 136)),
		Size = NumberSequence.new(2, 10),
		Transparency = NumberSequence.new(0.55, 1),
		Lifetime = NumberRange.new(5, 8),
		Rate = taux or 2,
		Speed = NumberRange.new(3, 5),
		SpreadAngle = Vector2.new(12, 12),
		Acceleration = Vector3.new(1.5, 0.5, 0.4),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-15, 15),
	})
end

function Outils.feu(parent, taille)
	local f = Instance.new("Fire")
	f.Size = taille or 5
	f.Heat = 8
	f.Color = Color3.fromRGB(255, 140, 50)
	f.SecondaryColor = Color3.fromRGB(255, 70, 20)
	f.Parent = parent
	return f
end

-- Petites lueurs qui flottent (la part sert de volume d'émission)
function Outils.lucioles(parent, couleur, taux)
	return emetteur(parent, {
		Name = "Lucioles",
		Texture = TEX_ETINCELLE,
		LightEmission = 1,
		Color = ColorSequence.new(couleur),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Lifetime = NumberRange.new(3, 6),
		Rate = taux or 4,
		Speed = NumberRange.new(0.3, 1.2),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.3, 0),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

-- Brume basse (la part sert de volume d'émission)
function Outils.brume(parent, couleur, taux)
	return emetteur(parent, {
		Name = "Brume",
		Texture = TEX_FUMEE,
		Color = ColorSequence.new(couleur),
		Size = NumberSequence.new(8, 16),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0.86),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(8, 12),
		Rate = taux or 3,
		Speed = NumberRange.new(0.3, 0.8),
		SpreadAngle = Vector2.new(180, 10),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-6, 6),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

function Outils.etincelles(parent, couleur, taux)
	return emetteur(parent, {
		Name = "Etincelles",
		Texture = TEX_ETINCELLE,
		LightEmission = 1,
		Color = ColorSequence.new(couleur),
		Size = NumberSequence.new(0.25, 0),
		Lifetime = NumberRange.new(1, 2),
		Rate = taux or 6,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(50, 50),
		Acceleration = Vector3.new(0, 1.5, 0),
	})
end

return Outils
