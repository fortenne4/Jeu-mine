--!strict
-- Auras "ki" des mobs (ReplicatedStorage › Partage › AurasMobs).
-- AurasMobs.appliquer(mob, "Violet" | "Rouge") ; AurasMobs.retirer(mob). Marche client ou serveur.

local TweenService = game:GetService("TweenService")

local TEX_POINTE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_LANGUE = "rbxasset://textures/particles/fire_main.dds"
local TEX_LUEUR = "rbxasset://textures/particles/smoke_main.dds"
local NOM = "AuraMob"

type Palette = {bord: Color3, coeur: Color3}

local PALETTES: {[string]: Palette} = {
	Violet = {bord = Color3.fromRGB(110, 20, 200), coeur = Color3.fromRGB(170, 110, 230)},
	Rouge = {bord = Color3.fromRGB(170, 10, 20), coeur = Color3.fromRGB(230, 90, 80)},
}

local AurasMobs = {}

local function ns(...: number): NumberSequence
	local p, kp = {...}, {}
	for i = 1, #p, 2 do
		table.insert(kp, NumberSequenceKeypoint.new(p[i], p[i + 1]))
	end
	return NumberSequence.new(kp)
end

local function emetteur(parent: Instance, props: {[string]: any})
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	e.EmissionDirection = Enum.NormalId.Top
	e.LockedToPart = false
	e.VelocityInheritance = 0.8
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
end

function AurasMobs.retirer(model: Model)
	local p = model:FindFirstChild(NOM)
	if p then p:Destroy() end
end

function AurasMobs.appliquer(model: Model, nom: string)
	local pal = PALETTES[nom]
	if not pal then
		warn("AurasMobs : aura inconnue " .. tostring(nom))
		return
	end
	AurasMobs.retirer(model)
	local root = model.PrimaryPart
	if not root then return end

	local cadre, taille = model:GetBoundingBox()
	local h = math.max(taille.Y, 1)
	local k = math.clamp(h / 5, 0.6, 2.4) -- zombie ~5 studs, brute ~10
	local r = math.max(taille.X, taille.Z) * 0.55 + 0.4 * k
	local H = h * 1.1
	local densite = math.clamp((r * H) / 8, 0.6, 2.2)

	-- Cône invisible (Cylinder + ShapePartial) : base large aux pieds, se resserre au-dessus de la tête
	local p = Instance.new("Part")
	p.Name = NOM
	p.Size = Vector3.new(r * 2, H, r * 2)
	p.CFrame = CFrame.new(cadre.Position.X, cadre.Position.Y - h / 2 + H / 2, cadre.Position.Z) * cadre.Rotation
	p.Transparency = 1
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = false
	p.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = model

	local CYL, SURFACE = Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Surface
	local VEL = Enum.ParticleOrientation.VelocityParallel
	local monte = Vector3.new(0, 16 * k, 0)
	local bordClair = pal.bord:Lerp(pal.coeur, 0.35)

	-- Pointes : aiguilles effilées (étoile écrasée) qui partent dehors puis filent vers le haut
	emetteur(p, {
		Name = "Pointes", Texture = TEX_POINTE, Shape = CYL, ShapeStyle = SURFACE, ShapePartial = 0.3,
		Orientation = VEL, Squash = ns(0, 1.6, 1, 2.6),
		Color = ColorSequence.new({ColorSequenceKeypoint.new(0, bordClair), ColorSequenceKeypoint.new(0.4, pal.bord), ColorSequenceKeypoint.new(1, pal.bord)}),
		LightEmission = 0.8, Brightness = 2, Size = ns(0, 0.5 * k, 0.3, 1.1 * k, 1, 0.3 * k), Transparency = ns(0, 1, 0.1, 0, 0.7, 0.15, 1, 1),
		Lifetime = NumberRange.new(0.3, 0.5), Rate = 55 * densite, Speed = NumberRange.new(1 * k, 2.2 * k),
		Acceleration = monte, Drag = 1.5, ZOffset = 0.3,
	})
	-- Langues : flammes fines et opaques qui forment le contour saturé
	emetteur(p, {
		Name = "Langues", Texture = TEX_LANGUE, Shape = CYL, ShapeStyle = SURFACE, ShapePartial = 0.3,
		Orientation = VEL, Squash = ns(0, 1, 1, 2), Rotation = NumberRange.new(-8, 8),
		Color = ColorSequence.new(pal.bord, pal.bord:Lerp(Color3.new(), 0.25)),
		LightEmission = 0.5, Brightness = 1.6, Size = ns(0, 0.9 * k, 0.4, 1.5 * k, 1, 0.4 * k), Transparency = ns(0, 1, 0.15, 0.1, 0.7, 0.35, 1, 1),
		Lifetime = NumberRange.new(0.35, 0.6), Rate = 30 * densite, Speed = NumberRange.new(0.6 * k, 1.4 * k),
		Acceleration = monte, Drag = 1.5, ZOffset = 0.2,
	})
	-- Lueur : remplissage doux et clair, derrière le corps
	emetteur(p, {
		Name = "Lueur", Texture = TEX_LUEUR, Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = ColorSequence.new(pal.coeur, pal.coeur:Lerp(pal.bord, 0.5)), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
		LightEmission = 0.9, Size = ns(0, 1.6 * k, 1, 2.6 * k), Transparency = ns(0, 1, 0.3, 0.8, 1, 1),
		Lifetime = NumberRange.new(0.8, 1.2), Rate = 9 * densite, Speed = NumberRange.new(0.8 * k, 1.6 * k),
		Acceleration = Vector3.new(0, 2 * k, 0), Drag = 1, ZOffset = -1.5,
	})
	-- Crête : grandes pointes au-dessus de la tête (pointe de la goutte)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, H / 2 - 0.3 * k, 0)
	a.Parent = p
	emetteur(a, {
		Name = "Crete", Texture = TEX_POINTE, Orientation = VEL, Squash = ns(0, 2, 1, 3),
		Color = ColorSequence.new(bordClair, pal.bord), SpreadAngle = Vector2.new(28, 28),
		LightEmission = 0.8, Brightness = 2, Size = ns(0, 0.8 * k, 0.4, 1.5 * k, 1, 0.3 * k), Transparency = ns(0, 1, 0.1, 0.05, 0.7, 0.2, 1, 1),
		Lifetime = NumberRange.new(0.3, 0.45), Rate = 14 * densite, Speed = NumberRange.new(4 * k, 6 * k),
		Acceleration = monte * 0.5, Drag = 2,
	})

	local lumiere = Instance.new("PointLight")
	lumiere.Color = pal.coeur
	lumiere.Range = 7 * k
	lumiere.Brightness = 1
	lumiere.Shadows = false
	lumiere.Parent = p
	TweenService:Create(lumiere, TweenInfo.new(0.25 + math.random() * 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Brightness = 1.8}):Play()
end

return AurasMobs
