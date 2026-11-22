-- Effet de coup sur les mobs · CLIENT : à chaque changement de l'attribut « DernierCoup » (posé par le serveur),
-- le mob devient orange vif une fraction de seconde (couleur de chaque pièce, sans Highlight) et quelques éclats tombent du
-- point d'impact (côté joueur, d'après « CoupDirection »). Générique : tout Model portant un des TAGS.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TAGS = {"MobGrotte", "Mob"}
local DISTANCE_MAX = 150
local MAX_ECLATS = 60
local ORANGE = Color3.fromRGB(255, 120, 20)
local ORANGE_COUP = Color3.fromRGB(225, 115, 45) -- teinte du mob touché : orange franc mais mat
local FLASH_TENU = 0.12 -- le mob reste entièrement orange ce temps-là
local FLASH_FONDU = 0.2

local rng = Random.new()
local suivis = {} -- [modele] = {connexion, vraies, tweens, couleurs}

local dossier = Instance.new("Folder")
dossier.Name = "EffetsCoupsMobs"
dossier.Parent = workspace

local socle = Instance.new("Part")
socle.Anchored, socle.CanCollide, socle.CanQuery, socle.CanTouch = true, false, false, false
socle.Transparency = 1
socle.Size = Vector3.one * 0.1
socle.Parent = dossier
local point = Instance.new("Attachment")
point.Parent = socle
local etincelles = Instance.new("ParticleEmitter")
etincelles.Enabled = false
etincelles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
etincelles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), ORANGE)
etincelles.LightEmission = 1
etincelles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
etincelles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6)})
etincelles.Lifetime = NumberRange.new(0.2, 0.38)
etincelles.Speed = NumberRange.new(10, 18)
etincelles.SpreadAngle = Vector2.new(45, 45)
etincelles.Acceleration = Vector3.new(0, -60, 0)
etincelles.Drag = 4
etincelles.EmissionDirection = Enum.NormalId.Front
etincelles.Parent = point

local libres, actifs = {}, 0
local enVol = {} -- [eclat] = Y d'atterrissage
local rayon = RaycastParams.new()
rayon.FilterType = Enum.RaycastFilterType.Exclude
rayon.IgnoreWater = true

RunService.Heartbeat:Connect(function()
	for p, y in enVol do
		if p.Position.Y <= y and p.AssemblyLinearVelocity.Y < 0 then
			p.Anchored = true
			p.Position = Vector3.new(p.Position.X, y, p.Position.Z)
			enVol[p] = nil
		end
	end
end)
local function prendreEclat(): BasePart?
	local p = table.remove(libres)
	if p then return p end
	if actifs >= MAX_ECLATS then return nil end
	p = Instance.new("Part")
	p.Material = Enum.Material.SmoothPlastic
	p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

local function rendreEclat(p: BasePart)
	enVol[p] = nil
	p.Anchored = true
	p.Parent = nil
	table.insert(libres, p)
	actifs -= 1
end

local function eclats(e, impact: Vector3, dir: Vector3, modele: Model)
	rayon.FilterDescendantsInstances = {dossier, modele}
	local r = workspace:Raycast(impact, Vector3.new(0, -30, 0), rayon)
	local sol = if r then r.Position.Y else impact.Y - 30
	local n = rng:NextInteger(7, 10)
	for _ = 1, n do
		local p = prendreEclat()
		if not p then return end
		actifs += 1
		local taille = rng:NextNumber(0.3, 0.55)
		p.Size = Vector3.one * taille
		local braise = rng:NextNumber() < 0.45
		p.Color = if braise then ORANGE else e.couleurs[rng:NextInteger(1, #e.couleurs)]
		p.Material = if braise then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.Transparency = 0
		p.CanCollide = false
		p.Anchored = false
		p.CFrame = CFrame.new(impact + Vector3.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.3, 0.3)))
			* CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0)
		p.Parent = dossier
		local cote = dir:Cross(Vector3.yAxis)
		p.AssemblyLinearVelocity = -dir * rng:NextNumber(4, 9) + cote * rng:NextNumber(-5, 5) + Vector3.yAxis * rng:NextNumber(7, 13)
		p.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-15, 15), rng:NextNumber(-15, 15), rng:NextNumber(-15, 15))
		local duree = rng:NextNumber(0.7, 1)
		TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, duree),
			{Transparency = 1, Size = Vector3.one * taille * 0.3}):Play()
		enVol[p] = sol + taille * 0.5
		task.delay(duree + 0.27, rendreEclat, p)
	end
end

-- Flash : chaque pièce visible du mob passe orange vif (Neon) puis reprend sa couleur. On ne passe PAS par un
-- Highlight : Roblox n'en affiche qu'environ 31 à la fois (auras de pioches, etc.) et les suivants restent invisibles.
local function restaurer(e)
	if not e.allume then return end
	e.allume = false
	for p, o in e.vraies do
		if p.Parent then
			p.Material = o.materiau
			local tw = TweenService:Create(p, TweenInfo.new(FLASH_FONDU, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = o.couleur})
			e.tweens[p] = tw
			tw:Play()
		end
	end
end

local function flash(e, modele: Model)
	if not e.vraies then -- vraies couleurs relevées une seule fois (jamais en plein flash)
		e.vraies, e.tweens = {}, {}
		for _, p in modele:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 0.95 then
				e.vraies[p] = {couleur = p.Color, materiau = p.Material}
			end
		end
	end
	for p, o in e.vraies do
		local tw = e.tweens[p]
		if tw then tw:Cancel(); e.tweens[p] = nil end
		p.Material = if o.materiau == Enum.Material.Neon then Enum.Material.SmoothPlastic else o.materiau -- pas de fluo
		p.Color = ORANGE_COUP
	end
	e.allume = true
	e.jeton = (e.jeton or 0) + 1
	local jeton = e.jeton
	task.delay(FLASH_TENU, function()
		if e.jeton == jeton then restaurer(e) end
	end)
end

local function couleursDe(modele: Model): {Color3}
	local t = {}
	for _, p in modele:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.5 then
			table.insert(t, p.Color)
			if #t >= 8 then break end
		end
	end
	if #t == 0 then t[1] = ORANGE end
	return t
end

local function coup(e, modele: Model)
	if not modele.Parent then return end
	local bb, taille = modele:GetBoundingBox()
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - bb.Position).Magnitude > DISTANCE_MAX then return end
	e.couleurs = e.couleurs or couleursDe(modele)
	flash(e, modele)
	local d = modele:GetAttribute("CoupDirection")
	local h = if typeof(d) == "Vector3" then d * Vector3.new(1, 0, 1)
		elseif camera then camera.CFrame.LookVector * Vector3.new(1, 0, 1) else Vector3.zAxis
	local dir = if h.Magnitude > 0.01 then h.Unit else Vector3.zAxis
	local impact = bb.Position - dir * math.min(taille.X, taille.Z) * 0.4 + Vector3.yAxis * taille.Y * 0.1
	point.WorldCFrame = CFrame.lookAt(impact, impact - dir + Vector3.yAxis * 0.5)
	etincelles:Emit(14)
	eclats(e, impact, dir, modele)
end

local function suivre(modele: Instance)
	if suivis[modele] or not modele:IsA("Model") then return end
	local e = {}
	suivis[modele] = e
	e.connexion = modele:GetAttributeChangedSignal("DernierCoup"):Connect(function()
		coup(e, modele)
	end)
end

local function oublier(modele: Instance)
	local e = suivis[modele]
	if not e then return end
	if modele:IsDescendantOf(workspace) then
		for _, tag in TAGS do
			if CollectionService:HasTag(modele, tag) then return end
		end
	end
	suivis[modele] = nil
	e.connexion:Disconnect()
	restaurer(e)
end

for _, tag in TAGS do
	CollectionService:GetInstanceAddedSignal(tag):Connect(suivre)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(oublier)
	for _, m in CollectionService:GetTagged(tag) do suivre(m) end
end
