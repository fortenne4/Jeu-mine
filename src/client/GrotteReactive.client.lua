-- Grotte réactive (−50 m, « Le Lac des Lueurs ») · SCRIPT CLIENT
-- Toutes les grottes réagissent au joueur, en local (rien n'est répliqué) :
--   * les veines de cristal et les galets lumineux s'illuminent quand on passe près d'eux, puis s'apaisent ;
--   * les champignons lâchent une bouffée de spores lumineuses quand on les frôle ;
--   * chaque coup de pioche sur un minerai envoie une onde de lumière dans les veines autour (de la plus proche
--     à la plus lointaine), et fait parfois tomber un peu de poussière du plafond.
-- L'écho des coups vient de la réverbération « Cave » posée par AmbianceGrotte.client.lua.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local joueur = Players.LocalPlayer
local terrain = workspace.Terrain

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local CASE = 16 -- taille d'une case de la grille spatiale
local RAYON_VEINE = 11 -- les veines s'allument à moins de 11 studs
local RAYON_CHAMPI = 6
local RECHARGE_CHAMPI = 6
local RAYON_ONDE = 32 -- portée de l'onde d'un coup de pioche
local BLANC = Color3.new(1, 1, 1)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
params.IgnoreWater = true

local grotte: Model? = nil
local grille: {[Vector3]: {any}} = {} -- case -> liste de veines {part, couleur, allumee}
local champis: {{part: BasePart, pos: Vector3, dernier: number}} = {}
local allumees: {[any]: boolean} = {} -- veines allumées par la proximité
local connexions: {RBXScriptConnection} = {}
local effets: Folder? = nil

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

local function cle(p: Vector3): Vector3
	return Vector3.new(math.floor(p.X / CASE), math.floor(p.Y / CASE), math.floor(p.Z / CASE))
end

-- veines dans un rayon autour d'un point
local function veinesAutour(pos: Vector3, rayon: number, rappel: (any, number) -> ())
	local a, b = cle(pos - Vector3.one * rayon), cle(pos + Vector3.one * rayon)
	for x = a.X, b.X do
		for y = a.Y, b.Y do
			for z = a.Z, b.Z do
				local l = grille[Vector3.new(x, y, z)]
				if l then
					for _, v in l do
						if v.part.Parent then
							local d = (v.part.Position - pos).Magnitude
							if d < rayon then
								rappel(v, d)
							end
						end
					end
				end
			end
		end
	end
end

local function teinter(v, intensite: number, duree: number)
	local cible = if intensite > 0 then v.couleur:Lerp(BLANC, intensite) else v.couleur
	TweenService:Create(v.part, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Color = cible}):Play()
end

local function ajouterVeine(p: Instance)
	if not p:IsA("BasePart") or (p.Name ~= "Veine" and p.Name ~= "GaletLueur") then
		return
	end
	local k = cle(p.Position)
	grille[k] = grille[k] or {}
	table.insert(grille[k], {part = p, couleur = p.Color})
end

local function ajouterChampi(m: Instance)
	if not m:IsA("Model") or (m.Name ~= "Champignon" and m.Name ~= "ChampiGeant") then
		return
	end
	-- la tête du champignon : la pièce la plus haute
	local haut, yMax = nil, -math.huge
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Position.Y > yMax then
			haut, yMax = p, p.Position.Y
		end
	end
	if haut then
		table.insert(champis, {part = haut, pos = haut.Position, dernier = 0})
	end
end

local function bouffee(c)
	if not effets then
		return
	end
	local couleur = c.part.Color
	local a = Instance.new("Attachment")
	a.WorldPosition = c.pos + Vector3.new(0, 0.4, 0)
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Color = ColorSequence.new(couleur:Lerp(BLANC, 0.3), couleur)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(1.6, 2.8)
	e.Speed = NumberRange.new(1.5, 4)
	e.SpreadAngle = Vector2.new(60, 60)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -0.6, 0)
	e.Drag = 1.5
	e.Rate = 0
	e.Parent = a
	e:Emit(22)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = couleur, 12, 0, false
	l.Parent = a
	TweenService:Create(l, TweenInfo.new(0.25), {Brightness = 2.2}):Play()
	task.delay(0.3, function()
		TweenService:Create(l, TweenInfo.new(1.4), {Brightness = 0}):Play()
	end)
	Debris:AddItem(a, 3.5)
end

local function poussiere(pos: Vector3)
	local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), params)
	if not hit then
		return
	end
	local a = Instance.new("Attachment")
	a.WorldPosition = hit.Position - Vector3.new(0, 0.5, 0)
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_FUMEE
	e.Color = ColorSequence.new(Color3.fromRGB(120, 112, 100))
	e.LightInfluence = 0.6
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.6)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Acceleration = Vector3.new(0, -10, 0)
	e.Rate = 0
	e.Parent = a
	e:Emit(10)
	-- quelques gravillons
	local g = e:Clone()
	g.Texture = TEX_ETINCELLE
	g.Color = ColorSequence.new(Color3.fromRGB(90, 84, 76))
	g.LightEmission = 0
	g.Size = NumberSequence.new(0.12)
	g.Transparency = NumberSequence.new(0)
	g.Acceleration = Vector3.new(0, -40, 0)
	g.Parent = a
	g:Emit(6)
	Debris:AddItem(a, 3)
end

-- un coup de pioche : onde de lumière dans les veines, de la plus proche à la plus lointaine
local function coup(pos: Vector3)
	veinesAutour(pos, RAYON_ONDE, function(v, d)
		task.delay(d / 26, function()
			if not v.part.Parent then
				return
			end
			teinter(v, 0.7, 0.12)
			task.delay(0.22, function()
				if v.part.Parent then
					teinter(v, if allumees[v] then 0.5 else 0, 0.9)
				end
			end)
		end)
	end)
	if math.random() < 0.35 then
		poussiere(pos)
	end
end

local function suivreMinerai(p: Instance)
	if not grotte or not p:IsA("BasePart") or not p:IsDescendantOf(grotte) then
		return
	end
	local pv = p:GetAttribute("PV")
	table.insert(connexions, p:GetAttributeChangedSignal("PV"):Connect(function()
		local n = p:GetAttribute("PV")
		if type(n) == "number" and type(pv) == "number" and n < pv then
			local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if racine and (racine.Position - p.Position).Magnitude < 60 then
				coup(p.Position)
			end
		end
		pv = n
	end))
end

local function sortir()
	for v in allumees do
		if v.part.Parent then
			v.part.Color = v.couleur
		end
	end
	table.clear(allumees)
	for _, c in connexions do
		c:Disconnect()
	end
	table.clear(connexions)
	table.clear(grille)
	table.clear(champis)
	if effets then
		effets:Destroy()
		effets = nil
	end
	grotte = nil
end

local function entrer(g: Model)
	grotte = g
	local f = Instance.new("Folder")
	f.Name = "GrotteReactiveLocale"
	f.Parent = workspace
	effets = f
	for _, d in g:GetDescendants() do
		ajouterVeine(d)
		ajouterChampi(d)
	end
	-- avec le streaming, le décor peut arriver après coup
	table.insert(connexions, g.DescendantAdded:Connect(function(d)
		ajouterVeine(d)
		ajouterChampi(d)
	end))
	for _, p in CollectionService:GetTagged("Minerai") do
		suivreMinerai(p)
	end
	table.insert(connexions, CollectionService:GetInstanceAddedSignal("Minerai"):Connect(suivreMinerai))
end

local verif, tic = math.huge, 0
RunService.Heartbeat:Connect(function(dt)
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
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
	tic += dt
	if not grotte or not racine or tic < 0.15 then
		return
	end
	tic = 0
	local pos = racine.Position
	local t = os.clock()

	-- veines proches : s'allument ; celles qu'on a quittées s'apaisent
	local proches = {}
	veinesAutour(pos, RAYON_VEINE, function(v, d)
		proches[v] = true
		if not allumees[v] then
			allumees[v] = true
			teinter(v, 0.5 * (1 - d / RAYON_VEINE) + 0.15, 0.35)
		end
	end)
	for v in allumees do
		if not proches[v] then
			allumees[v] = nil
			if v.part.Parent then
				teinter(v, 0, 1.6)
			end
		end
	end

	-- champignons frôlés
	for _, c in champis do
		local ecart = c.pos - pos
		if t - c.dernier > RECHARGE_CHAMPI and c.part.Parent and Vector2.new(ecart.X, ecart.Z).Magnitude < RAYON_CHAMPI
			and ecart.Y > -4 and ecart.Y < 14 then
			c.dernier = t
			bouffee(c)
		end
	end
end)
