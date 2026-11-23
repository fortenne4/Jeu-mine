-- Mécaniques signature des grottes profondes · SCRIPT CLIENT (serveur : MecaniquesGrotte.server.lua)
-- −100 m : la COURSE EN WAGONNET. Le tracé (points des rails) est lissé (Catmull-Rom) ; le wagonnet roule seul,
-- plus vite dans les descentes, la caméra suit derrière en s'inclinant dans les virages, le champ de vision
-- s'élargit avec la vitesse, les roues crachent des étincelles. Chaque joueur dont l'attribut « EnWagon » est
-- vrai reçoit un wagonnet sous les pieds (chez tout le monde). À l'arrivée : « WagonFin » au serveur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MecaniquesGrotte") :: RemoteEvent

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local FER = Color3.fromRGB(62, 60, 66)
local ROUILLE = Color3.fromRGB(110, 62, 38)
local BOIS = Color3.fromRGB(96, 66, 42)
local AMBRE = Color3.fromRGB(255, 176, 90)
local HAUTEUR = 3.1 -- racine du personnage au-dessus du rail

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
local function majWagons()
	for _, j in Players:GetPlayers() do
		local en = j:GetAttribute("EnWagon") == true
		if en and not wagons[j] then
			local m, morceaux = construireWagon()
			wagons[j] = {modele = m, morceaux = morceaux, vitesse = 26}
		elseif not en and wagons[j] then
			wagons[j].modele:Destroy()
			wagons[j] = nil
		end
	end
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
		local cible = math.clamp(28 + pente * 45, 18, 46)
		if L - s < 25 then
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
	for k = 1, 26 do
		local p = Instance.new("Part")
		p.Name = "EclatCoeur"
		p.Size = Vector3.new(0.6, 1.6, 0.6) * (0.6 + math.random() * 0.9)
		p.Material = Enum.Material.Neon
		p.Color = if k % 3 == 0 then Color3.fromRGB(230, 60, 220) else Color3.fromRGB(220, 30, 50)
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.CFrame = CFrame.new(centre) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5).Unit
		p.AssemblyLinearVelocity = dir * (30 + math.random() * 35)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		TweenService:Create(p, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		game:GetService("Debris"):AddItem(p, 3.6)
	end
end

local function cinematiqueCoeur(centre: Vector3)
	local cam = workspace.CurrentCamera
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local depuis = if r then r.Position else centre + Vector3.new(30, -10, 0)
	local horiz = Vector3.new(depuis.X - centre.X, 0, depuis.Z - centre.Z)
	local dir = if horiz.Magnitude > 1 then horiz.Unit else Vector3.xAxis
	local ancien = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	local debut = os.clock()
	local fini = false
	RunService:BindToRenderStep("CinematiqueCoeur", Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - debut
		local a = t * 0.35
		local d = 30 - math.min(t, 3) * 3
		local pos = centre + (CFrame.Angles(0, a, 0) * dir) * d + Vector3.new(0, -6 + t * 1.2, 0)
		cam.CFrame = CFrame.lookAt(pos, centre)
	end)
	secouer(1.2, 2.2)
	UI.jouer("metal", 0.25)
	task.delay(2.2, function()
		flash(Color3.fromRGB(255, 80, 120), 0.85, 1.4)
		secouer(3, 1.2)
		eclats(centre)
		UI.jouer("succes", 0.6)
		bandeau("LE CŒUR MAUDIT EST BRISÉ", Color3.fromRGB(255, 120, 200), 4)
	end)
	task.delay(5, function()
		if fini then
			return
		end
		fini = true
		RunService:UnbindFromRenderStep("CinematiqueCoeur")
		cam.CameraType = if ancien == Enum.CameraType.Scriptable then Enum.CameraType.Custom else ancien
	end)
end

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
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
		if typeof(d.centre) == "Vector3" then
			cinematiqueCoeur(d.centre)
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
			toast("Lingot royal coulé : +" .. tostring(d.pieces or 0) .. " pièces", true)
			UI.celebrer(gui, Color3.fromRGB(255, 160, 50), "LINGOT ROYAL !")
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
			toast("Coffre de l'Abîme : +" .. tostring(d.pieces or 0) .. " pièces et " .. tostring(d.gold or 0) .. " Or", true)
			UI.celebrer(gui, Color3.fromRGB(255, 200, 80), "TRÉSOR DE L'ABÎME")
		end
	end
end)
