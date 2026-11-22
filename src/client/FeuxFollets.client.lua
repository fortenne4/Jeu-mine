-- Feux follets de la grotte −50 m (« Le Lac des Lueurs ») · SCRIPT CLIENT
-- Dans une grotte qui a un dossier « Guide » (points du chemin principal posés par GrotteLueurs) :
--   * 3 feux follets guides flottent devant le joueur le long du chemin vers le boss, puis tournent autour
--     de la salle du boss ; ils éclairent ce qu'ils survolent ;
--   * des lucioles errantes dérivent autour du joueur (petites lumières colorées) ;
--   * chaque pas laisse une onde lumineuse sur la roche (bioluminescence) ;
--   * les méduses de spores reçoivent une vraie lueur.
-- Tout est local (rien n'est répliqué) et détruit en sortant de la grotte.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local joueur = Players.LocalPlayer
local terrain = workspace.Terrain

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local COULEURS = {
	Color3.fromRGB(80, 230, 255), -- cyan
	Color3.fromRGB(70, 255, 210), -- turquoise
	Color3.fromRGB(165, 90, 255), -- violet
	Color3.fromRGB(255, 95, 215), -- magenta
}
local GUIDE = Color3.fromRGB(150, 255, 235)
local NB_GUIDES, NB_LUCIOLES = 3, 7

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
params.IgnoreWater = true

local dossier: Folder? = nil
local grotte: Model? = nil
local chemin: {Vector3} = {}
local bossP: Vector3? = nil
local guides, lucioles = {}, {}
local lueursMeduses = {}
local nMeduses = 0

local function grotteAutour(pos: Vector3): Model?
	local g = workspace:FindFirstChild("Grottes")
	if not g then
		return nil
	end
	for _, m in g:GetChildren() do
		local c, d = m:GetAttribute("Centre"), m:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return m
			end
		end
	end
	return nil
end

local function feu(taille: number, couleur: Color3, lum: number, portee: number, trainee: boolean)
	local p = Instance.new("Part")
	p.Name = "FeuFollet"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * taille
	p.Material = Enum.Material.Neon
	p.Color = couleur
	p.Transparency = 0.05
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = couleur, lum, portee, false
	l.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Color = ColorSequence.new(couleur)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, taille * 0.5), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Rate = if trainee then 14 else 4
	e.Speed = NumberRange.new(0.2, 0.8)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = p
	if trainee then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, taille * 0.3, 0), Vector3.new(0, -taille * 0.3, 0)
		a0.Parent, a1.Parent = p, p
		local t = Instance.new("Trail")
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new(couleur)
		t.LightEmission, t.LightInfluence = 1, 0
		t.Transparency = NumberSequence.new(0.3, 1)
		t.Lifetime = 0.7
		t.FaceCamera = true
		t.WidthScale = NumberSequence.new(1, 0)
		t.Parent = p
	end
	p.Parent = dossier
	return p
end

-- garde un point dans l'air libre : on recule s'il est dans la roche vue depuis « depuis »
local function libre(depuis: Vector3, vers: Vector3): Vector3
	local d = vers - depuis
	local hit = workspace:Raycast(depuis, d, params)
	if hit then
		return hit.Position - d.Unit * 1.5
	end
	return vers
end

local function plusProche(pos: Vector3): number
	local meilleur, dmin = 1, math.huge
	for i, p in chemin do
		local d = (p - pos).Magnitude
		if d < dmin then
			meilleur, dmin = i, d
		end
	end
	return meilleur
end

local function lueurMeduse(m: Instance)
	if not dossier or lueursMeduses[m] or not m:IsA("Model") then
		return
	end
	local p = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if p then
		local l = Instance.new("PointLight")
		l.Name = "LueurMeduse"
		nMeduses += 1
		l.Color = if nMeduses % 2 == 0 then COULEURS[4] else COULEURS[1]
		l.Brightness, l.Range, l.Shadows = 1.1, 18, false
		l.Parent = p
		lueursMeduses[m] = l
	end
end

local function entrer(g: Model)
	local guide = g:FindFirstChild("Guide")
	if not guide then
		return
	end
	grotte = g
	chemin = {}
	for i = 1, guide:GetAttribute("N") or 0 do
		local p = guide:GetAttribute("P" .. i)
		if typeof(p) == "Vector3" then
			table.insert(chemin, p)
		end
	end
	bossP = guide:GetAttribute("Boss")
	local f = Instance.new("Folder")
	f.Name = "FeuxFolletsLocaux"
	f.Parent = workspace
	dossier = f
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origine = if racine then racine.Position else g:GetAttribute("Centre")
	for i = 1, NB_GUIDES do
		local p = feu(0.8, GUIDE, 0.6, 16, true)
		p.Position = origine + Vector3.new(i * 2, 5, 0)
		guides[i] = {part = p, pos = p.Position, phase = i * 2.1}
	end
	for i = 1, NB_LUCIOLES do
		local c = COULEURS[(i - 1) % #COULEURS + 1]
		local p = feu(0.35, c, 0.45, 12, false)
		p.Position = origine + Vector3.new(0, 4, 0)
		lucioles[i] = {part = p, pos = p.Position, ancre = p.Position, cible = p.Position, phase = i * 1.3, vitesse = 3 + i % 3}
	end
	for _, m in CollectionService:GetTagged("GrotteMeduse") do
		if m:IsDescendantOf(g) then
			lueurMeduse(m)
		end
	end
end

local function sortir()
	grotte = nil
	table.clear(guides)
	table.clear(lucioles)
	for _, l in lueursMeduses do
		l:Destroy()
	end
	table.clear(lueursMeduses)
	if dossier then
		dossier:Destroy()
		dossier = nil
	end
end

CollectionService:GetInstanceAddedSignal("GrotteMeduse"):Connect(function(m)
	if grotte and m:IsDescendantOf(grotte) then
		lueurMeduse(m)
	end
end)

-- onde lumineuse sous les pas
local dernierPas = 0
local function pas(racine: BasePart, hum: Humanoid)
	local hit = workspace:Raycast(racine.Position, Vector3.new(0, -(hum.HipHeight + racine.Size.Y / 2 + 2), 0), params)
	if not hit or not dossier then
		return
	end
	local onde = Instance.new("Part")
	onde.Name = "Onde"
	onde.Shape = Enum.PartType.Cylinder
	onde.Material = Enum.Material.Neon
	onde.Color = COULEURS[2]
	onde.Transparency = 0.35
	onde.Size = Vector3.new(0.06, 1.6, 1.6)
	onde.Anchored, onde.CanCollide, onde.CanQuery, onde.CanTouch, onde.CastShadow = true, false, false, false, false
	onde.CFrame = CFrame.new(hit.Position + hit.Normal * 0.05, hit.Position + hit.Normal) * CFrame.Angles(0, math.pi / 2, 0)
	onde.Parent = dossier
	local t = TweenService:Create(onde, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.06, 6, 6), Transparency = 1})
	t.Completed:Once(function()
		onde:Destroy()
	end)
	t:Play()
end

local verif = math.huge
RunService.RenderStepped:Connect(function(dt)
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	verif += dt
	if verif > 0.5 then
		verif = 0
		local g = racine and grotteAutour(racine.Position)
		if g ~= grotte then
			sortir()
			if g then
				entrer(g)
			end
		end
	end
	if not grotte or not racine or not hum or #chemin == 0 then
		return
	end
	local t = os.clock()
	local pos = racine.Position
	local tete = pos + Vector3.new(0, 2, 0)

	-- guides : quelques points devant sur le chemin, ou en ronde autour du boss
	local i0 = plusProche(pos)
	local auBoss = bossP and (pos - bossP).Magnitude < 34
	for k, g in guides do
		local cible
		if auBoss or i0 + k * 3 > #chemin then
			local b = bossP or chemin[#chemin]
			local a = t * 0.5 + k * 2.09
			cible = b + Vector3.new(math.cos(a) * 16, 9 + math.sin(t + k) * 2, math.sin(a) * 16)
		else
			cible = chemin[math.min(#chemin, i0 + k * 3)] + Vector3.new(0, 5 + math.sin(t * 1.7 + g.phase) * 0.9, 0)
		end
		-- les guides attendent le joueur : jamais plus de 38 studs devant
		local d = cible - tete
		if d.Magnitude > 38 then
			cible = tete + d.Unit * 38
		end
		g.pos = g.pos:Lerp(cible, math.min(1, dt * 1.6))
		local ondule = Vector3.new(math.sin(t * 2.3 + g.phase), math.sin(t * 3.1 + g.phase) * 0.6, math.cos(t * 1.9 + g.phase)) * 0.7
		g.part.Position = g.pos + ondule
		local l = g.part:FindFirstChildOfClass("PointLight")
		if l then
			l.Brightness = 0.55 + math.sin(t * 4 + g.phase) * 0.15
		end
	end

	-- lucioles : dérivent autour d'ancres proches du joueur, se replacent quand il s'éloigne
	for _, l in lucioles do
		if (l.ancre - pos).Magnitude > 34 or (l.cible - l.pos).Magnitude < 1 then
			local a = math.random() * math.pi * 2
			local r = 8 + math.random() * 20
			local vise = pos + Vector3.new(math.cos(a) * r, 2 + math.random() * 9, math.sin(a) * r)
			l.ancre = pos
			l.cible = libre(tete, vise)
		end
		local d = l.cible - l.pos
		if d.Magnitude > 0.01 then
			l.pos += d.Unit * math.min(d.Magnitude, l.vitesse * dt)
		end
		l.part.Position = l.pos + Vector3.new(math.sin(t * 2 + l.phase), math.sin(t * 2.6 + l.phase) * 0.5, math.cos(t * 1.7 + l.phase)) * 0.6
		l.part.Transparency = 0.1 + (math.sin(t * 3 + l.phase) * 0.5 + 0.5) * 0.4
	end

	-- pas lumineux
	if hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air and hum.FloorMaterial ~= Enum.Material.Water
		and t - dernierPas > 0.32 then
		dernierPas = t
		pas(racine, hum)
	end
end)
