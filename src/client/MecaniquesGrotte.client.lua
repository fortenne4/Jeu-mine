-- Mécaniques signature des grottes profondes · SCRIPT CLIENT (serveur : MecaniquesGrotte.server.lua)
-- −100 m : la COURSE EN WAGONNET. Le tracé (points des rails) est lissé (Catmull-Rom) ; le wagonnet roule seul,
-- plus vite dans les descentes, la caméra suit derrière en s'inclinant dans les virages, le champ de vision
-- s'élargit avec la vitesse, les roues crachent des étincelles. Chaque joueur dont l'attribut « EnWagon » est
-- vrai reçoit un wagonnet sous les pieds (chez tout le monde). À l'arrivée : « WagonFin » au serveur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local PopupCoffre = require(script.Parent:WaitForChild("PopupCoffre"))

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MecaniquesGrotte") :: RemoteEvent

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local FER = Color3.fromRGB(62, 60, 66)
local ROUILLE = Color3.fromRGB(110, 62, 38)
local BOIS = Color3.fromRGB(96, 66, 42)
local AMBRE = Color3.fromRGB(255, 176, 90)
local HAUTEUR = 3.1 -- racine du personnage au-dessus du rail
local ECHELLE_WAGON = 0.7 -- wagon de la gare réduit : il cache moins l'écran et le décor
local VITESSE = 1.25 -- multiplicateur de vitesse de la course

local gui = Instance.new("ScreenGui")
gui.Name = "MecaniquesGrotte"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 23
gui.Parent = joueur:WaitForChild("PlayerGui")
local toast = UI.toast(gui)

-- ================= Wagonnets sous les joueurs en course =================
local function piece(parent: Instance, taille: Vector3, couleur: Color3, mat: Enum.Material, nom: string): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.Color, p.Material = couleur, mat
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Le même wagon que celui de la gare (voyage vers la mine), préparé par le serveur (ReplicatedStorage ›
-- ModeleWagonCourse, base à l'origine) ; lampe et étincelles ajoutées ici. nil si le modèle n'existe pas.
local function wagonDeLaGare(): (Model?, {{part: BasePart, offset: CFrame}}?)
	local modele = ReplicatedStorage:FindFirstChild("ModeleWagonCourse")
	if not (modele and modele:IsA("Model")) then return nil, nil end
	local m = modele:Clone()
	m.Name = "WagonCourse"
	-- réduit autour de sa base (posée à l'origine par le serveur)
	m.WorldPivot = CFrame.new()
	m:ScaleTo(ECHELLE_WAGON)
	local morceaux = {}
	local plusGros: BasePart? = nil
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(morceaux, {part = d, offset = d.CFrame})
			if not plusGros or d.Size.Magnitude > plusGros.Size.Magnitude then plusGros = d end
		end
	end
	if not plusGros then
		m:Destroy()
		return nil, nil
	end
	-- la plus grosse pièce en tête : elle porte les étincelles
	for i, mo in morceaux do
		if mo.part == plusGros then
			table.remove(morceaux, i)
			table.insert(morceaux, 1, mo)
			break
		end
	end
	local longueur = (m:GetAttribute("Longueur") or 6) * ECHELLE_WAGON
	local hauteur = (m:GetAttribute("Hauteur") or 3) * ECHELLE_WAGON
	local fond = plusGros :: BasePart
	local origine = morceaux[1].offset
	-- phare à l'avant
	local lampe = piece(m, Vector3.new(0.45, 0.55, 0.45), AMBRE, Enum.Material.Neon, "Lampe")
	table.insert(morceaux, {part = lampe, offset = CFrame.new(0, hauteur + 0.3, -longueur / 2 - 0.1)})
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = AMBRE, 0.7, 14, false
	l.Parent = lampe
	local feu = Instance.new("SpotLight")
	feu.Color, feu.Brightness, feu.Range, feu.Angle, feu.Face = AMBRE, 2, 40, 55, Enum.NormalId.Front
	feu.Parent = lampe
	for _, x in {-1, 1} do
		local a = Instance.new("Attachment")
		a.Name = "Etincelles"
		a.Parent = fond
		a.CFrame = origine:ToObjectSpace(CFrame.new(x * 1.3, 0.1, longueur * 0.3))
		local e = Instance.new("ParticleEmitter")
		e.Texture = TEX_ETINCELLE
		e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 140), Color3.fromRGB(255, 120, 40))
		e.LightEmission, e.LightInfluence = 1, 0
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.14), NumberSequenceKeypoint.new(1, 0)})
		e.Lifetime = NumberRange.new(0.25, 0.5)
		e.Speed = NumberRange.new(6, 12)
		e.SpreadAngle = Vector2.new(30, 30)
		e.EmissionDirection = Enum.NormalId.Back
		e.Acceleration = Vector3.new(0, -30, 0)
		e.Rate = 0
		e.Parent = a
	end
	m.Parent = workspace
	return m, morceaux
end

local function construireWagon(): (Model, {{part: BasePart, offset: CFrame}})
	local m = Instance.new("Model")
	m.Name = "WagonCourse"
	local morceaux = {}
	local function ajoute(taille, couleur, mat, nom, offset)
		local p = piece(m, taille, couleur, mat, nom)
		table.insert(morceaux, {part = p, offset = offset})
		return p
	end
	ajoute(Vector3.new(3.4, 0.3, 4.6), FER, Enum.Material.Metal, "Fond", CFrame.new(0, 0.95, 0))
	for _, x in {-1.6, 1.6} do
		ajoute(Vector3.new(0.25, 1.9, 4.6), ROUILLE, Enum.Material.CorrodedMetal, "Flanc", CFrame.new(x, 1.95, 0))
	end
	for _, z in {-2.2, 2.2} do
		ajoute(Vector3.new(3.4, 1.9, 0.25), ROUILLE, Enum.Material.CorrodedMetal, "Bout", CFrame.new(0, 1.95, z))
	end
	for _, y in {1.3, 2.75} do
		for _, x in {-1.7, 1.7} do
			ajoute(Vector3.new(0.12, 0.25, 4.7), FER, Enum.Material.Metal, "Bande", CFrame.new(x, y, 0))
		end
	end
	for _, x in {-1.45, 1.45} do
		for _, z in {-1.5, 1.5} do
			local r = ajoute(Vector3.new(0.35, 1.2, 1.2), FER, Enum.Material.Metal, "Roue", CFrame.new(x, 0.6, z))
			r.Shape = Enum.PartType.Cylinder
		end
	end
	ajoute(Vector3.new(0.4, 0.4, 0.4), BOIS, Enum.Material.Wood, "Support", CFrame.new(0, 3.1, -2.3))
	local lampe = ajoute(Vector3.new(0.45, 0.55, 0.45), AMBRE, Enum.Material.Neon, "Lampe", CFrame.new(0, 3.5, -2.35))
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = AMBRE, 0.7, 14, false
	l.Parent = lampe
	local feu = Instance.new("SpotLight")
	feu.Color, feu.Brightness, feu.Range, feu.Angle, feu.Face = AMBRE, 2, 40, 55, Enum.NormalId.Front
	feu.Parent = lampe
	-- étincelles des roues
	for _, x in {-1.45, 1.45} do
		local a = Instance.new("Attachment")
		a.Name = "Etincelles"
		local fond = morceaux[1].part
		a.Parent = fond
		a.Position = Vector3.new(x, -0.9, 1.5)
		local e = Instance.new("ParticleEmitter")
		e.Texture = TEX_ETINCELLE
		e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 140), Color3.fromRGB(255, 120, 40))
		e.LightEmission, e.LightInfluence = 1, 0
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.14), NumberSequenceKeypoint.new(1, 0)})
		e.Lifetime = NumberRange.new(0.25, 0.5)
		e.Speed = NumberRange.new(6, 12)
		e.SpreadAngle = Vector2.new(30, 30)
		e.EmissionDirection = Enum.NormalId.Back
		e.Acceleration = Vector3.new(0, -30, 0)
		e.Rate = 0
		e.Parent = a
	end
	m.Parent = workspace
	return m, morceaux
end

local wagons: {[Player]: {modele: Model, morceaux: any, vitesse: number}} = {}
-- Le wagonnet décoratif de la gare (« WagonGare ») se cache chez soi tant qu'un wagon de course roule :
-- sinon les deux se superposent au départ
local function majWagonGare()
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then return end
	local cache = next(wagons) ~= nil
	for _, d in dossier:GetDescendants() do
		if d.Name == "WagonGare" and d:IsA("Model") then
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") then p.LocalTransparencyModifier = if cache then 1 else 0 end
			end
		end
	end
end

local function majWagons()
	for _, j in Players:GetPlayers() do
		local en = j:GetAttribute("EnWagon") == true
		if en and not wagons[j] then
			local m, morceaux = wagonDeLaGare()
			if not m or not morceaux then
				m, morceaux = construireWagon()
			end
			wagons[j] = {modele = m, morceaux = morceaux, vitesse = 26}
		elseif not en and wagons[j] then
			wagons[j].modele:Destroy()
			wagons[j] = nil
		end
	end
	majWagonGare()
end
local function suivreJoueur(j: Player)
	j:GetAttributeChangedSignal("EnWagon"):Connect(majWagons)
end
Players.PlayerAdded:Connect(suivreJoueur)
Players.PlayerRemoving:Connect(function(j)
	if wagons[j] then
		wagons[j].modele:Destroy()
		wagons[j] = nil
	end
	majWagonGare()
end)
for _, j in Players:GetPlayers() do
	suivreJoueur(j)
end
majWagons()

RunService.RenderStepped:Connect(function()
	for j, w in wagons do
		local r = j.Character and j.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r then
			local base = r.CFrame * CFrame.new(0, -HAUTEUR, 0)
			local parts, cfs = {}, {}
			for _, mo in w.morceaux do
				table.insert(parts, mo.part)
				table.insert(cfs, base * mo.offset)
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
			local v = r.AssemblyLinearVelocity.Magnitude
			for _, a in w.morceaux[1].part:GetChildren() do
				local e = a:FindFirstChildOfClass("ParticleEmitter")
				if e then
					e.Rate = if v > 30 then 60 elseif v > 18 then 15 else 0
				end
			end
		end
	end
end)

-- ================= La course (joueur local) =================
local function lisser(points: {Vector3}): ({Vector3}, {number})
	local dense = {}
	local n = #points
	for i = 1, n - 1 do
		local p0 = points[math.max(1, i - 1)]
		local p1, p2 = points[i], points[i + 1]
		local p3 = points[math.min(n, i + 2)]
		local pas = math.max(1, math.ceil((p2 - p1).Magnitude / 0.8))
		for k = 0, pas - 1 do
			local t = k / pas
			local t2, t3 = t * t, t * t * t
			table.insert(dense, 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
		end
	end
	table.insert(dense, points[n])
	local cumul = {0}
	for i = 2, #dense do
		cumul[i] = cumul[i - 1] + (dense[i] - dense[i - 1]).Magnitude
	end
	return dense, cumul
end

local function echantillon(dense, cumul, s: number, depuis: number): (Vector3, Vector3, number)
	local i = depuis
	while i < #dense - 1 and cumul[i + 1] < s do
		i += 1
	end
	local seg = math.max(cumul[i + 1] - cumul[i], 1e-4)
	local t = math.clamp((s - cumul[i]) / seg, 0, 1)
	local p = dense[i]:Lerp(dense[i + 1], t)
	local d = dense[i + 1] - dense[i]
	return p, if d.Magnitude > 1e-4 then d.Unit else Vector3.new(0, 0, -1), i
end

local enCourse = false
local function course(points: {Vector3})
	if enCourse or #points < 4 then
		return
	end
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not (r and hum) then
		remote:FireServer("WagonFin")
		return
	end
	enCourse = true
	local dense, cumul = lisser(points)
	local L = cumul[#cumul]
	hum.PlatformStand = true
	hum.AutoRotate = false
	local cam = workspace.CurrentCamera
	local fovAvant = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	UI.jouer("metal", 0.6)
	toast("En voiture ! Accroche-toi…", true)
	local s, v, idx = 0, 8, 1
	local camPos = r.Position + Vector3.new(0, 6, 8)
	local roulis = 0
	local tPrec = nil
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 0.05)
		if not r.Parent or hum.Health <= 0 then
			conn:Disconnect()
			enCourse = false
			hum.PlatformStand = false
			cam.CameraType = Enum.CameraType.Custom
			remote:FireServer("WagonFin")
			return
		end
		local p, t, i = echantillon(dense, cumul, s, idx)
		idx = i
		-- vitesse : départ en douceur, plus vite dans les descentes, freinage à l'arrivée
		local pente = -t.Y
		local cible = math.clamp(28 + pente * 45, 18, 46) * VITESSE
		if L - s < 25 * VITESSE then
			cible = math.max(6, (L - s) * 1.1)
		end
		v += (cible - v) * math.min(1, dt * 1.6)
		s = math.min(L, s + v * dt)
		-- virage : roulis de la caméra selon la courbure
		local courbure = 0
		if tPrec then
			courbure = tPrec:Cross(t).Y / math.max(dt, 1e-3)
		end
		tPrec = t
		roulis += (math.clamp(-courbure * 0.04, -0.35, 0.35) - roulis) * math.min(1, dt * 3)
		local plat = Vector3.new(t.X, 0, t.Z)
		local devant = if plat.Magnitude > 1e-3 then plat.Unit else Vector3.new(0, 0, -1)
		local cfR = CFrame.lookAt(p + Vector3.new(0, HAUTEUR, 0), p + Vector3.new(0, HAUTEUR, 0) + devant)
		r.CFrame = cfR
		r.AssemblyLinearVelocity = t * v
		-- caméra derrière, un peu au-dessus, qui regarde loin devant
		local ici = p + Vector3.new(0, HAUTEUR, 0)
		local voulue = ici - devant * 7 + Vector3.new(0, 2, 0) -- sous les chapeaux des cadres de mine
		camPos = camPos:Lerp(voulue, math.min(1, dt * 6))
		local regard, _, _ = echantillon(dense, cumul, math.min(L, s + 18), idx)
		cam.CFrame = CFrame.lookAt(camPos, regard + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, roulis)
			* CFrame.new(math.noise(os.clock() * 8) * v * 0.004, math.noise(os.clock() * 9, 1) * v * 0.004, 0)
		cam.FieldOfView = fovAvant + math.clamp((v - 20) * 0.9, 0, 22)
		if s >= L - 0.05 then
			conn:Disconnect()
			enCourse = false
			-- descente du wagonnet, à côté des rails
			local cote = Vector3.new(-devant.Z, 0, devant.X)
			hum.PlatformStand = false
			hum.AutoRotate = true
			r.AssemblyLinearVelocity = Vector3.zero
			perso:PivotTo(CFrame.lookAt(p + cote * 3.5 + Vector3.new(0, HAUTEUR, 0), p + cote * 3.5 + Vector3.new(0, HAUTEUR, 0) + devant))
			TweenService:Create(cam, TweenInfo.new(0.5), {FieldOfView = fovAvant}):Play()
			cam.CameraType = Enum.CameraType.Custom
			UI.jouer("succes")
			toast("Terminus ! Bienvenue au fond de la mine.", true)
			remote:FireServer("WagonFin")
		end
	end)
end

-- ================= Secousses, bandeau d'alerte, cinématique du Cœur =================
local secousse = {force = 0, fin = 0}
RunService:BindToRenderStep("SecousseGrotte", Enum.RenderPriority.Camera.Value + 2, function()
	local reste = secousse.fin - os.clock()
	if reste > 0 then
		local f = secousse.force * math.min(1, reste)
		local cam = workspace.CurrentCamera
		cam.CFrame *= CFrame.Angles(math.rad((math.random() - 0.5) * f), math.rad((math.random() - 0.5) * f), 0)
	end
end)
local function secouer(force: number, duree: number)
	secousse.force = math.max(force, if os.clock() < secousse.fin then secousse.force else 0)
	secousse.fin = math.max(secousse.fin, os.clock() + duree)
end

local function bandeau(texte: string, couleur: Color3, duree: number)
	local b = UI.texte({
		Name = "BandeauAlerte", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.fromScale(0.7, 0.07), BackgroundTransparency = 1, Text = texte, TextColor3 = couleur,
		Font = Enum.Font.FredokaOne, TextTransparency = 1, Parent = gui,
	}, 46)
	UI.creer("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 3, Transparency = 0.2, Parent = b})
	TweenService:Create(b, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	UI.pop(b, 1.4)
	task.delay(duree, function()
		local t = TweenService:Create(b, TweenInfo.new(0.6), {TextTransparency = 1})
		t:Play()
		t.Completed:Wait()
		b:Destroy()
	end)
end

local function flash(couleur: Color3, opacite: number, duree: number)
	local f = UI.creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = couleur, BackgroundTransparency = 1 - opacite,
		BorderSizePixel = 0, ZIndex = 50, Parent = gui})
	local t = TweenService:Create(f, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	t:Play()
	t.Completed:Connect(function()
		f:Destroy()
	end)
end

-- éclats du Cœur : pièces locales projetées tout autour, qui retombent puis disparaissent
local function eclats(centre: Vector3)
	for k = 1, 36 do
		local p = Instance.new("Part")
		p.Name = "EclatCoeur"
		p.Size = Vector3.new(0.6, 1.6, 0.6) * (0.6 + math.random() * 0.9)
		p.Material = if k % 4 == 0 then Enum.Material.Neon else Enum.Material.Glass -- peu de néon : lumière raisonnable
		p.Color = if k % 3 == 0 then Color3.fromRGB(230, 60, 220) else Color3.fromRGB(220, 30, 50)
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.CFrame = CFrame.new(centre) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5).Unit
		p.AssemblyLinearVelocity = dir * (30 + math.random() * 35)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		TweenService:Create(p, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		Debris:AddItem(p, 3.6)
	end
end

-- ================= Mort de l'Exécuteur maudit : pluie d'or et butin =================
local OR_PEPITE, OR_PIECE = Color3.fromRGB(246, 190, 64), Color3.fromRGB(236, 176, 56)

-- pluie de pépites et de pièces d'or (pièces locales, physiques) sur l'arène pendant `duree` s
local function pluieDOr(sol: Vector3, duree: number)
	local dossier = Instance.new("Folder")
	dossier.Name = "PluieDOr"
	dossier.Parent = workspace
	Debris:AddItem(dossier, duree + 8)
	-- lueur dorée douce au-dessus de l'arène
	local porteur = Instance.new("Part")
	porteur.Anchored, porteur.Transparency = true, 1
	porteur.CanCollide, porteur.CanQuery, porteur.CanTouch = false, false, false
	porteur.Size = Vector3.one
	porteur.CFrame = CFrame.new(sol + Vector3.new(0, 18, 0))
	porteur.Parent = dossier
	local lueur = Instance.new("PointLight")
	lueur.Color, lueur.Range, lueur.Brightness, lueur.Shadows = Color3.fromRGB(255, 200, 110), 50, 0, false
	lueur.Parent = porteur
	TweenService:Create(lueur, TweenInfo.new(0.8), {Brightness = 1.4}):Play()
	task.delay(duree + 1, function()
		TweenService:Create(lueur, TweenInfo.new(2), {Brightness = 0}):Play()
	end)
	task.spawn(function()
		local t0, n = os.clock(), 0
		while os.clock() - t0 < duree and dossier.Parent do
			for _ = 1, 2 do
				n += 1
				local a, r = math.random() * 2 * math.pi, math.sqrt(math.random()) * 34
				local p = Instance.new("Part")
				if n % 3 == 0 then
					p.Name = "PieceOr"
					p.Shape = Enum.PartType.Cylinder
					p.Size = Vector3.new(0.22, 1.2, 1.2)
					p.Color = OR_PIECE
				else
					p.Name = "PepiteOr"
					p.Size = Vector3.new(0.6 + math.random() * 0.6, 0.45 + math.random() * 0.45, 0.6 + math.random() * 0.6)
					p.Color = OR_PEPITE
				end
				p.Material = Enum.Material.Metal
				p.Reflectance = 0.15
				p.Massless = true
				p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false
				p.CFrame = CFrame.new(sol + Vector3.new(math.cos(a) * r, 22 + math.random() * 8, math.sin(a) * r))
					* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
				if n % 6 == 0 then
					local e = Instance.new("ParticleEmitter")
					e.Texture = TEX_ETINCELLE
					e.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140))
					e.LightEmission, e.LightInfluence = 0.4, 0
					e.Size = NumberSequence.new(0.35, 0)
					e.Lifetime = NumberRange.new(0.4, 0.7)
					e.Speed = NumberRange.new(0.5, 1.5)
					e.SpreadAngle = Vector2.new(180, 180)
					e.Rate = 8
					e.Parent = p
				end
				p.Parent = dossier
				p.AssemblyLinearVelocity = Vector3.new(math.random(-4, 4), -12 - math.random() * 10, math.random(-4, 4))
				p.AssemblyAngularVelocity = Vector3.new(math.random() * 8, math.random() * 8, math.random() * 8)
				task.delay(4.5, function()
					if p.Parent then
						TweenService:Create(p, TweenInfo.new(1.2), {Transparency = 1}):Play()
					end
				end)
				Debris:AddItem(p, 5.8)
			end
			task.wait(0.08)
		end
	end)
end

-- pépites (2D) qui jaillissent au centre de l'écran puis volent jusqu'au sac (bouton SacHUD › Sac), avec le total
local function pepitesVersSac(n: number)
	local cam = workspace.CurrentCamera
	local ecran = cam.ViewportSize
	local hud = joueur.PlayerGui:FindFirstChild("SacHUD")
	local socle = hud and hud:FindFirstChild("Sac")
	local cible = Vector2.new(60, ecran.Y * 0.55)
	if socle and socle:IsA("GuiObject") then
		local inset = GuiService:GetGuiInset() -- SacHUD respecte la barre du haut, ce ScreenGui non
		cible = socle.AbsolutePosition + socle.AbsoluteSize / 2 + inset
	end
	local centre = Vector2.new(ecran.X / 2, ecran.Y * 0.45)
	local total = UI.texte({
		Name = "TotalOr", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.5, 0.1),
		BackgroundTransparency = 1, Text = "+" .. n .. " OR", TextColor3 = Color3.fromRGB(255, 214, 90), Font = Enum.Font.FredokaOne,
		ZIndex = 60, Parent = gui,
	}, 64)
	UI.creer("UIStroke", {Color = Color3.fromRGB(60, 30, 4), Thickness = 3, Parent = total})
	UI.pop(total, 0.4)
	UI.jouer("succes", 0.9)
	local nombre = math.clamp(n, 8, 24)
	for k = 1, nombre do
		local s = 14 + math.random() * 12
		local f = UI.creer("Frame", {
			Name = "PepiteVol", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(s, s * 0.8), Position = UDim2.fromOffset(centre.X, centre.Y),
			Rotation = math.random(0, 360), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 61, Parent = gui,
		}, {UI.coin(0.35), UI.trait(Color3.fromRGB(90, 52, 10), 1.5), UI.degrade(Color3.fromRGB(255, 238, 160), Color3.fromRGB(214, 140, 30), 45)})
		local a, r = math.random() * 2 * math.pi, 50 + math.random() * 120
		local eclat = centre + Vector2.new(math.cos(a) * r, math.sin(a) * r * 0.7)
		TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(eclat.X, eclat.Y)}):Play()
		task.delay(0.4 + k * 0.04, function()
			local t = TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.fromOffset(cible.X, cible.Y), Size = UDim2.fromOffset(s * 0.5, s * 0.4), Rotation = f.Rotation + 180})
			t:Play()
			t.Completed:Connect(function()
				f:Destroy()
				if k % 3 == 0 then
					UI.jouer("clic", 1.2 + math.random() * 0.3)
				end
				if socle and socle:IsA("GuiObject") then
					UI.pop(socle, 1.12)
				end
			end)
		end)
	end
	task.delay(1.6, function()
		local t = TweenService:Create(total, TweenInfo.new(0.6), {TextTransparency = 1, Position = UDim2.fromScale(0.5, 0.3)})
		t:Play()
		t.Completed:Wait()
		total:Destroy()
	end)
end

-- butin de l'Exécuteur : pépites vers le sac puis pop-up de coffre (or + pièces)
local function butinExecuteur(gold: number, pieces: number)
	if gold <= 0 and pieces <= 0 then
		return
	end
	if gold > 0 then
		pepitesVersSac(gold)
	end
	task.delay(if gold > 0 then 1.3 else 0, function()
		PopupCoffre.afficher({titre = "Butin de l'Exécuteur", theme = "Maudit",
			sousTitre = if gold > 0 then "+" .. gold .. " Or dans ton sac !" else nil,
			recompenses = {{genre = "minerai", id = "Gold", n = gold}, {genre = "pieces", n = pieces}}})
	end)
end

-- Cinématique (≈ 10 s) : 1. l'Exécuteur s'effondre au ralenti (plan bas, de trois quarts) ; 2. la caméra lève les
-- yeux vers le Cœur qui se fissure ; 3. le Cœur éclate (t = 4,3 s, calé sur le serveur) et une pluie d'or tombe sur
-- l'arène, plan large qui tourne lentement ; 4. la caméra revient derrière le joueur puis rend la main.
local T_FISSURE, T_EXPLOSION, T_RETOUR, T_FIN = 3.3, 4.3, 9.2, 10
local enCinematique = false
local function cinematiqueCoeur(d)
	local centre: Vector3 = d.centre
	local sol: Vector3 = if typeof(d.sol) == "Vector3" then d.sol else centre - Vector3.new(0, 24, 0)
	local boss: Vector3 = if typeof(d.boss) == "Vector3" then d.boss else sol + Vector3.new(0, 5, 0)
	local hauteur = if type(d.hauteur) == "number" then math.clamp(d.hauteur, 4, 30) else 10
	local gold, pieces = tonumber(d.gold) or 0, tonumber(d.pieces) or 0
	if enCinematique then
		butinExecuteur(gold, pieces)
		return
	end
	enCinematique = true
	local cam = workspace.CurrentCamera
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local depuis = if r then r.Position else boss + Vector3.new(30, 0, 0)
	local horiz = Vector3.new(depuis.X - boss.X, 0, depuis.Z - boss.Z)
	local dir = if horiz.Magnitude > 1 then horiz.Unit else Vector3.xAxis
	local cote = dir:Cross(Vector3.yAxis)
	-- teinte légèrement désaturée pendant la chute, puis chaude avec l'or (aucun éclaircissement fort)
	local teinte = Instance.new("ColorCorrectionEffect")
	teinte.Name = "TeinteCoeur"
	teinte.Parent = cam
	TweenService:Create(teinte, TweenInfo.new(0.8), {Saturation = -0.3, Contrast = 0.08}):Play()

	cam.CameraType = Enum.CameraType.Scriptable
	local courant = cam.CFrame
	local debut = os.clock()
	RunService:BindToRenderStep("CinematiqueCoeur", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local t = os.clock() - debut
		local pos, vise
		if t < T_FISSURE then
			local u = t / T_FISSURE
			pos = boss + dir * (hauteur * 1.6 + 8 - u * 4) + cote * (hauteur * 0.6) + Vector3.new(0, 1.5 - hauteur * 0.2, 0)
			vise = boss + Vector3.new(0, hauteur * (0.15 - u * 0.35), 0)
		elseif t < T_EXPLOSION then
			pos = sol + dir * 30 + cote * 6 + Vector3.new(0, 6, 0)
			vise = centre
		elseif t < T_RETOUR then
			local a = (t - T_EXPLOSION) * 0.12
			pos = sol + CFrame.Angles(0, a, 0) * (dir * 34 + cote * 6) + Vector3.new(0, 16, 0)
			vise = sol + Vector3.new(0, 7, 0)
		else
			local p = joueur.Character
			local rr = p and p:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rr then
				vise = rr.Position + Vector3.new(0, 1.5, 0)
				pos = rr.Position - rr.CFrame.LookVector * 12 + Vector3.new(0, 4.5, 0)
			else
				pos, vise = courant.Position, courant.Position + courant.LookVector
			end
		end
		courant = courant:Lerp(CFrame.lookAt(pos, vise), 1 - math.exp(-dt * (if t < T_RETOUR then 3.5 else 6)))
		cam.CFrame = courant
	end)

	bandeau("L'EXÉCUTEUR MAUDIT EST TOMBÉ", Color3.fromRGB(255, 200, 90), 2.4)
	UI.jouer("metal", 0.25)
	task.delay(1.8, function()
		secouer(1.4, 0.8) -- il touche le sol
		UI.jouer("metal", 0.2)
	end)
	task.delay(T_FISSURE, function()
		secouer(0.7, T_EXPLOSION - T_FISSURE) -- le Cœur se fissure
		UI.jouer("metal", 0.3)
	end)
	task.delay(T_EXPLOSION, function()
		flash(Color3.fromRGB(255, 190, 210), 0.4, 1)
		secouer(2.2, 1)
		eclats(centre)
		UI.jouer("succes", 0.6)
		bandeau("LE CŒUR MAUDIT EST BRISÉ", Color3.fromRGB(255, 120, 200), 3.5)
		TweenService:Create(teinte, TweenInfo.new(1), {Saturation = 0.1, Contrast = 0.05, TintColor = Color3.fromRGB(255, 244, 225)}):Play()
	end)
	task.delay(T_EXPLOSION + 0.3, function()
		pluieDOr(sol, 3.8)
	end)
	task.delay(T_FIN, function()
		RunService:UnbindFromRenderStep("CinematiqueCoeur")
		local p = joueur.Character
		local hum = p and p:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
		cam.CameraType = Enum.CameraType.Custom
		local fin = TweenService:Create(teinte, TweenInfo.new(0.8), {Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1)})
		fin:Play()
		fin.Completed:Connect(function()
			teinte:Destroy()
		end)
		enCinematique = false
		butinExecuteur(gold, pieces)
	end)
end

-- ================= −700 m : leviers gelés et porte de glace de la salle scellée =================
local GLACE, GIVRE = Color3.fromRGB(165, 220, 255), Color3.fromRGB(110, 230, 255)

-- éclats de glace locaux projetés depuis centre (vers dir), qui retombent et s'effacent
local function eclatsGlace(centre: Vector3, dir: Vector3, n: number, force: number)
	for k = 1, n do
		local p = Instance.new("Part")
		p.Name = "EclatGlace"
		p.Size = Vector3.new(0.5, 1.2, 0.5) * (0.5 + math.random() * 1.1)
		p.Material = if k % 5 == 0 then Enum.Material.Neon else Enum.Material.Glass
		p.Color = if k % 5 == 0 then GIVRE else GLACE
		p.Transparency = 0.2
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.CFrame = CFrame.new(centre + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 3) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		p.Parent = workspace
		local v = (dir + Vector3.new(math.random() - 0.5, math.random() * 0.9, math.random() - 0.5)).Unit
		p.AssemblyLinearVelocity = v * force * (0.5 + math.random())
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		TweenService:Create(p, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		Debris:AddItem(p, 2.3)
	end
end

-- La porte se fissure (traits lumineux qui grandissent sur la glace) puis éclate (t = 2,6 s, calé sur le serveur).
-- Près de la porte : courte cinématique (la caméra se place face à la porte) ; ailleurs : bandeau seulement.
local function salleGlace(d)
	local porte: Vector3, normale: Vector3 = d.porte, d.normale
	bandeau("LES TROIS RUNES BRILLENT… LA GLACE CÈDE !", GIVRE, 3)
	secouer(0.6, 2.6)
	UI.jouer("metal", 0.3)
	local fissures = Instance.new("Folder")
	fissures.Name = "FissuresGlace"
	fissures.Parent = workspace
	Debris:AddItem(fissures, 3)
	local droite = normale:Cross(Vector3.yAxis)
	for k = 1, 10 do
		task.delay(k * 0.2, function()
			local a = math.random() * 2 * math.pi
			local L = 2 + math.random() * 5
			local p = Instance.new("Part")
			p.Name = "Fissure"
			p.Material, p.Color = Enum.Material.Neon, Color3.fromRGB(225, 250, 255)
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Size = Vector3.new(0.15, 0.1, 0.15)
			local base = CFrame.fromMatrix(porte + normale * 2.3, droite, Vector3.yAxis) * CFrame.Angles(0, 0, a)
			p.CFrame = base
			p.Parent = fissures
			TweenService:Create(p, TweenInfo.new(0.25), {Size = Vector3.new(L, 0.12, 0.15), CFrame = base * CFrame.new(L / 2, 0, 0)}):Play()
			UI.jouer("clic", 0.6 + math.random() * 0.3)
		end)
	end
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local proche = r ~= nil and (r.Position - porte).Magnitude < 90 and not enCinematique and not enCourse
	local cam = workspace.CurrentCamera
	if proche then
		enCinematique = true
		cam.CameraType = Enum.CameraType.Scriptable
		local courant = cam.CFrame
		local debut = os.clock()
		RunService:BindToRenderStep("CinematiqueGlace", Enum.RenderPriority.Camera.Value + 1, function(dt)
			local t = os.clock() - debut
			local pos = porte + normale * (17 - math.min(t, 2.6) * 1.5) + droite * 4 + Vector3.new(0, 2, 0)
			courant = courant:Lerp(CFrame.lookAt(pos, porte + Vector3.new(0, -1, 0)), 1 - math.exp(-dt * 4))
			cam.CFrame = courant
		end)
	end
	task.delay(2.6, function()
		flash(Color3.fromRGB(220, 245, 255), 0.45, 0.8)
		secouer(1.8, 0.9)
		eclatsGlace(porte, normale, 40, 26)
		UI.jouer("succes", 0.7)
		bandeau("LA SALLE SCELLÉE EST OUVERTE !", Color3.fromRGB(200, 245, 255), 3.5)
	end)
	task.delay(5, function()
		if proche then
			RunService:UnbindFromRenderStep("CinematiqueGlace")
			local p = joueur.Character
			local hum = p and p:FindFirstChildOfClass("Humanoid")
			if hum then
				cam.CameraSubject = hum
			end
			cam.CameraType = Enum.CameraType.Custom
			enCinematique = false
		end
		toast("Des minerais très rares t'attendent derrière la porte de glace !", true)
	end)
end

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	if genre == "LevierGlace" then
		if d.etape == "glace" and typeof(d.pos) == "Vector3" then
			eclatsGlace(d.pos + Vector3.new(0, 2.5, 0), Vector3.yAxis, 16, 14)
			UI.jouer("clic", 0.7)
			toast("La glace vole en éclats ! Abaisse le levier.", true)
		elseif d.etape == "abaisse" then
			local n, total = tonumber(d.n) or 1, tonumber(d.total) or 3
			UI.jouer("metal", 0.4 + n * 0.1)
			if n < total then
				bandeau(("Levier %d / %d abaissé : une rune s'allume sur la porte de glace"):format(n, total), GIVRE, 3)
			end
		end
		return
	elseif genre == "SalleGlace" then
		if typeof(d.porte) == "Vector3" and typeof(d.normale) == "Vector3" then
			salleGlace(d)
		end
		return
	end
	if genre == "LaveMonte" then
		bandeau("LA LAVE MONTE ! Grimpe sur un prisme de basalte", Color3.fromRGB(255, 140, 50), 5)
		secouer(0.9, (d.delai or 6) + 3)
		UI.jouer("metal", 0.3)
		return
	elseif genre == "LaveDescend" then
		toast("La lave redescend… le lac retrouve son lit.", true)
		return
	elseif genre == "PhaseCoeur" then
		local textes = {nil, "Une chaîne du Cœur cède ! Les runes s'embrasent…", "Une autre chaîne se brise ! Le Cœur vacille…",
			"Dernière chaîne ! Le Cœur ne tient plus qu'à un fil !"}
		bandeau(textes[d.phase or 2] or "Une chaîne du Cœur cède !", Color3.fromRGB(230, 90, 220), 3.5)
		secouer(1.6, 1)
		flash(Color3.fromRGB(150, 30, 160), 0.35, 0.6)
		UI.jouer("metal", 0.35)
		return
	elseif genre == "CoeurBrise" then
		if d.cinematique and typeof(d.centre) == "Vector3" then
			cinematiqueCoeur(d)
		else
			-- hors de l'arène : simple annonce, puis le butin
			bandeau("L'EXÉCUTEUR MAUDIT EST TOMBÉ ! Le Cœur se brise…", Color3.fromRGB(255, 200, 90), 3.5)
			secouer(1, 1.5)
			UI.jouer("succes", 0.6)
			task.delay(1.5, butinExecuteur, tonumber(d.gold) or 0, tonumber(d.pieces) or 0)
		end
		return
	end
	if genre == "WagonDepart" and type(d.points) == "table" then
		course(d.points)
	elseif genre == "Ascenseur" then
		toast(if d.monte then "Le treuil grince… la cage monte." else "La cage redescend.", true)
		UI.jouer("metal", 0.5)
	elseif genre == "Fonderie" then
		if not d.ok then
			toast(tostring(d.raison or "La fonderie reste froide."), false)
		elseif d.etape == "versement" then
			toast("Le fer tombe dans le creuset… la fonderie royale se rallume !", true)
			UI.jouer("metal", 0.4)
		elseif d.etape == "lingot" then
			PopupCoffre.afficher({titre = "Lingot royal", theme = "Fonderie", recompenses = {{genre = "pieces", n = tonumber(d.pieces) or 0}}})
		end
	elseif genre == "Rouages" then
		local fini = (d.n or 0) >= (d.total or 3)
		toast(if fini then "Toutes les roues tournent… quelque chose remonte de l'Abîme !"
			else "Rouage " .. tostring(d.n) .. " / " .. tostring(d.total) .. " en marche", true)
		UI.jouer("metal", 0.5 + (d.n or 1) * 0.1)
	elseif genre == "CoffreAbime" then
		if d.pret then
			toast("Le coffre de l'Abîme est remonté près du pilier !", true)
		else
			PopupCoffre.afficher({titre = "Coffre de l'Abîme", theme = "Abime", recompenses = {
				{genre = "pieces", n = tonumber(d.pieces) or 0}, {genre = "minerai", id = "Gold", n = tonumber(d.gold) or 0}}})
		end
	end
end)
