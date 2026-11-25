--!strict
-- Halo animé des 2 grands cercles des grottes profondes (tag « CercleGrotte », posés par Grottes.server.lua).
-- Purement visuel et local : le serveur compte toujours les joueurs. Couronne lumineuse qui respire, ondes qui
-- s'élargissent, orbes qui tournent, étincelles qui montent du pourtour ; doré dès qu'un joueur attend (« 1/2 »).
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TAG = "CercleGrotte"
local LIBRE = Color3.fromRGB(228, 212, 255)
local OCCUPE = Color3.fromRGB(255, 214, 140)
local ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local ORBES = 6
local PROCHE = 140 -- studs : au-delà, les orbes ne tournent plus (aucun calcul)
local RESPIRE = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local ONDE = TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1)

type Halo = {
	support: Part,
	centre: Vector3,
	rayon: number,
	orbes: {BasePart},
	couleurs: {Instance},
	tweens: {Tween},
	connexions: {RBXScriptConnection},
}
local halos: {[Instance]: Halo} = {}
local enAttente: {[Instance]: RBXScriptConnection} = {}

local function anneau(support: Part, rayon: number, epaisseur: number, transparence: number): CylinderHandleAdornment
	local a = Instance.new("CylinderHandleAdornment")
	a.Adornee = support
	a.CFrame = CFrame.Angles(math.pi / 2, 0, 0) -- couché à plat
	a.Height = 0.04
	a.Radius = rayon
	a.InnerRadius = math.max(0, rayon - epaisseur)
	a.Color3 = LIBRE
	a.Transparency = transparence
	a.ZIndex = 0
	a.Parent = support
	return a
end

local function teinter(h: Halo, texte: any)
	local occupe = type(texte) == "string" and string.sub(texte, 1, 2) ~= "0/"
	local c = if occupe then OCCUPE else LIBRE
	for _, objet in h.couleurs do
		if objet:IsA("HandleAdornment") then
			objet.Color3 = c
		elseif objet:IsA("BasePart") then
			objet.Color = c
		elseif objet:IsA("ParticleEmitter") then
			objet.Color = ColorSequence.new(c)
		elseif objet:IsA("PointLight") then
			objet.Color = c
		end
	end
end

local function creer(modele: Model, centre: Vector3, rayon: number)
	local support = Instance.new("Part")
	support.Name = "HaloGrotte"
	support.Size = Vector3.new(rayon * 2, 0.2, rayon * 2)
	support.CFrame = CFrame.new(centre + Vector3.new(0, 0.12, 0))
	support.Transparency = 1
	support.Anchored, support.CanCollide, support.CanTouch, support.CanQuery = true, false, false, false
	support.CastShadow = false
	local h: Halo = {support = support, centre = centre, rayon = rayon, orbes = {}, couleurs = {}, tweens = {}, connexions = {}}

	-- Couronne épaisse qui respire, juste à l'extérieur de l'anneau néon
	local couronne = anneau(support, rayon + 0.9, 1.2, 0.5)
	table.insert(h.tweens, TweenService:Create(couronne, RESPIRE, {Transparency = 0.82}))
	-- Deux ondes qui partent du centre vers l'anneau, décalées d'une demi-période
	for i = 0, 1 do
		local onde = anneau(support, rayon * 0.25, 0.35, 0.25)
		local t = TweenService:Create(onde, ONDE, {Radius = rayon + 0.4, InnerRadius = rayon + 0.05, Transparency = 1})
		table.insert(h.tweens, t)
		table.insert(h.couleurs, onde)
		if i == 1 then
			onde.Transparency = 1
			task.delay(1.3, function()
				if support.Parent then onde.Transparency = 0.25; t:Play() end
			end)
		end
	end
	table.insert(h.couleurs, couronne)

	-- Étincelles qui montent du pourtour (émetteur cylindrique, surface seulement)
	local e = Instance.new("ParticleEmitter")
	e.Texture = ETINCELLE
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Shape = Enum.ParticleEmitterShape.Cylinder
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.EmissionDirection = Enum.NormalId.Top
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 0.32), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(1.4, 2.4)
	e.Rate = 14
	e.Speed = NumberRange.new(1.5, 3.5)
	e.Acceleration = Vector3.new(0, 1, 0)
	e.Color = ColorSequence.new(LIBRE)
	e.Parent = support
	table.insert(h.couleurs, e)

	-- Lumière douce qui pulse
	local l = Instance.new("PointLight")
	l.Brightness = 0.4
	l.Range = rayon * 2.4
	l.Shadows = false
	l.Color = LIBRE
	l.Parent = support
	table.insert(h.tweens, TweenService:Create(l, RESPIRE, {Brightness = 1.1}))
	table.insert(h.couleurs, l)

	-- Orbes qui tournent au ras de l'anneau
	for _ = 1, ORBES do
		local o = Instance.new("Part")
		o.Name = "Orbe"
		o.Shape = Enum.PartType.Ball
		o.Size = Vector3.one * 0.45
		o.Material = Enum.Material.Neon
		o.Color = LIBRE
		o.Anchored, o.CanCollide, o.CanTouch, o.CanQuery = true, false, false, false
		o.CastShadow = false
		o.CFrame = support.CFrame
		o.Parent = support
		table.insert(h.orbes, o)
		table.insert(h.couleurs, o)
	end

	support.Parent = modele
	for i, t in h.tweens do
		if i ~= 3 then t:Play() end -- la 2e onde démarre avec son décalage
	end
	teinter(h, modele:GetAttribute("Texte"))
	table.insert(h.connexions, modele:GetAttributeChangedSignal("Texte"):Connect(function()
		teinter(h, modele:GetAttribute("Texte"))
	end))
	halos[modele] = h
end

local function retirer(modele: Instance)
	local c = enAttente[modele]
	if c then c:Disconnect(); enAttente[modele] = nil end
	local h = halos[modele]
	if not h then return end
	halos[modele] = nil
	for _, connexion in h.connexions do connexion:Disconnect() end
	for _, t in h.tweens do t:Cancel(); t:Destroy() end
	h.support:Destroy()
end

local function suivre(modele: Instance)
	if not modele:IsA("Model") or halos[modele] or enAttente[modele] then return end
	local function essayer(): boolean
		local centre, rayon = modele:GetAttribute("Centre"), modele:GetAttribute("Rayon")
		if typeof(centre) ~= "Vector3" or type(rayon) ~= "number" then return false end
		creer(modele, centre, rayon)
		return true
	end
	if essayer() then return end
	-- Avec le streaming, les attributs peuvent arriver après le modèle
	enAttente[modele] = modele.AttributeChanged:Connect(function()
		if halos[modele] or not essayer() then return end
		local c = enAttente[modele]
		enAttente[modele] = nil
		if c then c:Disconnect() end
	end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(suivre)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(retirer)
for _, modele in CollectionService:GetTagged(TAG) do suivre(modele) end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera or next(halos) == nil then return end
	local t = os.clock()
	local oeil = camera.CFrame.Position
	for _, h in halos do
		if (oeil - h.centre).Magnitude > PROCHE then continue end
		local r = h.rayon - 0.1
		for i, o in h.orbes do
			local a = t * 0.6 + (i - 1) * 2 * math.pi / ORBES
			o.CFrame = CFrame.new(h.centre + Vector3.new(math.cos(a) * r, 0.7 + math.sin(t * 2 + i) * 0.25, math.sin(a) * r))
		end
	end
end)
