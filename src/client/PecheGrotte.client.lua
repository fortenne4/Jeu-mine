-- Pêche dans les lacs de la grotte −50 m · SCRIPT CLIENT
-- Quand le serveur lance une partie (PecheGrotte.server.lua, RemoteEvent « PecheGrotte ») : la ligne part vers
-- l'eau, le bouchon flotte… puis « ÇA MORD ! » : une barre apparaît, un curseur va et vient, il faut ferrer
-- (clic, Espace, A à la manette, bouton à l'écran) quand il passe dans la zone verte, autant de fois que le
-- poisson l'exige (2 ratés = il s'échappe). À la prise : le poisson saute hors de l'eau et une carte le présente
-- (rareté, pièces, nouveau au carnet de pêche).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local Peche = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Peche"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait, texte = UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild(Peche.REMOTE) :: RemoteEvent
local terrain = workspace.Terrain

local ACTION = "FerrerPeche"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"

-- ================= Interface =================
local gui = creer("ScreenGui", {Name = "PecheGrotte", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 22,
	Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)

local jeu = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.36, 0.15),
	BackgroundColor3 = Color3.fromRGB(14, 20, 30), BackgroundTransparency = 0.2, Visible = false, Parent = gui},
	{coin(0.15), trait(Color3.fromRGB(90, 200, 255), 2, 0.3), creer("UISizeConstraint", {MinSize = Vector2.new(300, 110), MaxSize = Vector2.new(560, 150)})})
local consigne = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(150, 235, 255), Position = UDim2.fromScale(0.05, 0.06),
	Size = UDim2.fromScale(0.9, 0.26), Parent = jeu}, 26)
local barre = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.88, 0.22),
	BackgroundColor3 = Color3.fromRGB(30, 40, 55), Parent = jeu}, {coin(0.4)})
local zoneVerte = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = Color3.fromRGB(80, 220, 120),
	Parent = barre}, {coin(0.4)})
local curseur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 6, 1.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = barre}, {coin(1)})
local points = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.6, 0.18),
	BackgroundTransparency = 1, Parent = jeu}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center})})

-- carte de la prise
local carte = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1.4, 0.45), Size = UDim2.fromScale(0.26, 0.3),
	BackgroundColor3 = Color3.fromRGB(14, 18, 28), BackgroundTransparency = 0.1, Visible = false, Parent = gui},
	{coin(0.08), creer("UISizeConstraint", {MinSize = Vector2.new(260, 200), MaxSize = Vector2.new(380, 280)})})
local bordCarte = trait(Color3.new(1, 1, 1), 3)
bordCarte.Parent = carte
local carteNouveau = texte({Text = "NOUVEAU AU CARNET !", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 215, 90),
	Position = UDim2.fromScale(0.06, 0.05), Size = UDim2.fromScale(0.88, 0.1), Parent = carte}, 18)
local carteNom = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.06, 0.17), Size = UDim2.fromScale(0.88, 0.17), Parent = carte}, 30)
local carteRarete = texte({Font = Enum.Font.GothamBold, Position = UDim2.fromScale(0.06, 0.35), Size = UDim2.fromScale(0.88, 0.1), Parent = carte}, 18)
local carteTexte = texte({Font = Enum.Font.Garamond, TextColor3 = Color3.fromRGB(220, 215, 200), TextWrapped = true,
	Position = UDim2.fromScale(0.08, 0.48), Size = UDim2.fromScale(0.84, 0.2), Parent = carte}, 22)
local cartePieces = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 205, 70), Position = UDim2.fromScale(0.06, 0.7),
	Size = UDim2.fromScale(0.88, 0.13), Parent = carte}, 26)
local carteCarnet = texte({Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(170, 190, 210), Position = UDim2.fromScale(0.06, 0.85),
	Size = UDim2.fromScale(0.88, 0.09), Parent = carte}, 16)

-- ================= Ligne et bouchon =================
local partie = nil -- état de la partie en cours
local prochainBouton = 0

local function main(): BasePart?
	local perso = joueur.Character
	if not perso then
		return nil
	end
	return (perso:FindFirstChild("RightHand") or perso:FindFirstChild("Right Arm") or perso:FindFirstChild("HumanoidRootPart")) :: BasePart?
end

local function eclabousser(pos: Vector3, n: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Color = ColorSequence.new(Color3.fromRGB(200, 245, 255))
	e.LightEmission, e.LightInfluence = 0.6, 0.4
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -35, 0)
	e.Rate = 0
	e.Parent = a
	e:Emit(n)
	Debris:AddItem(a, 1.5)
end

local function nettoyer()
	if partie then
		for _, o in partie.objets do
			o:Destroy()
		end
		if partie.boucle then
			partie.boucle:Disconnect()
		end
	end
	partie = nil
	jeu.Visible = false
	ContextActionService:UnbindAction(ACTION)
end

local function finir(ok: boolean)
	if not partie or partie.fini then
		return
	end
	partie.fini = true
	remote:FireServer("Fin", {ok = ok})
	jeu.Visible = false
	ContextActionService:UnbindAction(ACTION)
	if not ok and partie.bouchon then
		eclabousser(partie.bouchon.Position, 10)
	end
	task.delay(if ok then 1.2 else 0.3, function()
		if partie and partie.fini then
			nettoyer()
		end
	end)
end

local function placerZone()
	if not partie then
		return
	end
	local w = partie.zone
	partie.centre = w / 2 + math.random() * (1 - w)
	zoneVerte.Size = UDim2.fromScale(w, 1)
	zoneVerte.Position = UDim2.fromScale(partie.centre, 0)
end

local function majPoints()
	if not partie then
		return
	end
	for i, p in partie.pastilles do
		p.BackgroundColor3 = if i <= partie.reussis then Color3.fromRGB(90, 230, 130) else Color3.fromRGB(50, 60, 75)
	end
end

local function ferrer(_, etat)
	if etat ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	if not partie or partie.phase ~= "touche" or partie.fini or os.clock() < prochainBouton then
		return Enum.ContextActionResult.Sink
	end
	prochainBouton = os.clock() + 0.18
	local x = partie.x
	if math.abs(x - partie.centre) <= partie.zone / 2 + 0.01 then
		partie.reussis += 1
		majPoints()
		UI.jouer("metal", 1.1 + partie.reussis * 0.12)
		if partie.bouchon then
			eclabousser(partie.bouchon.Position, 6)
		end
		if partie.reussis >= partie.touches then
			consigne.Text = "PRIS !"
			finir(true)
		else
			partie.zone = math.max(0.08, partie.zone * 0.92)
			placerZone()
		end
	else
		partie.rates += 1
		UI.secouer(barre, 6)
		UI.jouer("metal", 0.5)
		if partie.rates >= 2 then
			consigne.Text = "Il s'échappe…"
			finir(false)
		else
			consigne.Text = "Raté ! Encore une chance…"
		end
	end
	return Enum.ContextActionResult.Sink
end

local function commencer(d)
	nettoyer()
	local m = main()
	local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (m and r) or typeof(d.eau) ~= "Vector3" then
		remote:FireServer("Fin", {ok = false})
		return
	end
	local eau = d.eau + Vector3.new(0, 0.2, 0)
	local p = {phase = "attente", debut = os.clock(), attente = tonumber(d.attente) or 3, touches = math.clamp(tonumber(d.touches) or 2, 1, 8),
		zone = math.clamp(tonumber(d.zone) or 0.25, 0.08, 0.5), vitesse = math.clamp(tonumber(d.vitesse) or 0.7, 0.2, 2),
		reussis = 0, rates = 0, x = 0, centre = 0.5, objets = {}, pastilles = {}, depart = r.Position, fini = false}
	partie = p
	-- bouchon
	local b = Instance.new("Part")
	b.Name = "Bouchon"
	b.Shape = Enum.PartType.Ball
	b.Size = Vector3.one * 0.55
	b.Material = Enum.Material.SmoothPlastic
	b.Color = Color3.fromRGB(230, 60, 50)
	b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch = true, false, false, false
	b.Position = m.Position
	local haut = Instance.new("Part")
	haut.Shape = Enum.PartType.Ball
	haut.Size = Vector3.one * 0.35
	haut.Material = Enum.Material.Neon
	haut.Color = Color3.new(1, 1, 1)
	haut.Anchored, haut.CanCollide, haut.CanQuery, haut.CanTouch = true, false, false, false
	haut.Parent = b
	b.Parent = workspace
	p.bouchon = b
	table.insert(p.objets, b)
	-- ligne
	local a0 = Instance.new("Attachment")
	a0.Parent = m
	local a1 = Instance.new("Attachment")
	a1.Parent = b
	local ligne = Instance.new("Beam")
	ligne.Attachment0, ligne.Attachment1 = a0, a1
	ligne.Width0, ligne.Width1 = 0.05, 0.05
	ligne.Color = ColorSequence.new(Color3.fromRGB(230, 230, 220))
	ligne.LightEmission, ligne.LightInfluence = 0.3, 0.6
	ligne.FaceCamera = true
	ligne.CurveSize0 = 1.5
	ligne.Segments = 12
	ligne.Parent = b
	table.insert(p.objets, a0)
	-- lancer : arc vers l'eau
	local origine = m.Position
	local tLancer = 0.55
	p.boucle = RunService.RenderStepped:Connect(function(dt)
		if partie ~= p then
			return
		end
		local t = os.clock() - p.debut
		local pos
		if t < tLancer then
			local u = t / tLancer
			pos = origine:Lerp(eau, u) + Vector3.new(0, math.sin(u * math.pi) * 4, 0)
		else
			local dip = if p.phase == "touche" then 0.25 + math.abs(math.sin(t * 9)) * 0.25 else 0
			pos = eau + Vector3.new(0, math.sin(t * 2.2) * 0.07 - dip, 0)
			if not p.ploufFait then
				p.ploufFait = true
				eclabousser(eau, 8)
			end
		end
		b.Position = pos
		haut.Position = pos + Vector3.new(0, 0.22, 0)
		-- ça mord
		if p.phase == "attente" and t >= p.attente then
			p.phase = "touche"
			p.debutTouche = os.clock()
			eclabousser(eau, 14)
			UI.jouer("ouvrir", 1.4)
			consigne.Text = "ÇA MORD ! Ferre dans la zone verte"
			for i = 1, p.touches do
				p.pastilles[i] = creer("Frame", {Size = UDim2.fromScale(0.85, 0.85), SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundColor3 = Color3.fromRGB(50, 60, 75), LayoutOrder = i, Parent = points}, {coin(1)})
				table.insert(p.objets, p.pastilles[i])
			end
			placerZone()
			jeu.Visible = true
			UI.pop(jeu, 0.7)
			ContextActionService:BindActionAtPriority(ACTION, ferrer, true, Enum.ContextActionPriority.High.Value + 50,
				Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)
			ContextActionService:SetTitle(ACTION, "Ferrer")
			ContextActionService:SetPosition(ACTION, UDim2.new(1, -150, 1, -150))
		end
		-- curseur qui va et vient
		if p.phase == "touche" and not p.fini then
			local u = ((os.clock() - p.debutTouche) * p.vitesse) % 2
			p.x = if u < 1 then u else 2 - u
			curseur.Position = UDim2.fromScale(p.x, 0.5)
			if os.clock() - p.debutTouche > Peche.DUREE_MAX - p.attente - 1 then
				consigne.Text = "Trop tard, il s'est décroché…"
				finir(false)
			end
		end
		-- abandon : trop loin du ponton, ou mort
		local rr = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
		if not p.fini and (not rr or not hum or hum.Health <= 0 or (rr.Position - p.depart).Magnitude > 10) then
			finir(false)
		end
	end)
end

-- ================= Prise =================
local idCarte = 0
local function montrerCarte(poisson, d)
	idCarte += 1
	local moi = idCarte
	local c = Peche.COULEUR_RARETE[poisson.rarete] or Color3.new(1, 1, 1)
	local carnet = Peche.lire(joueur:GetAttribute("CarnetPeche"))
	carteNouveau.Visible = d.nouveau == true
	carteNom.Text = poisson.nom
	carteNom.TextColor3 = poisson.couleur:Lerp(Color3.new(1, 1, 1), 0.35)
	carteRarete.Text = string.upper(poisson.rarete)
	carteRarete.TextColor3 = c
	carteTexte.Text = "« " .. poisson.texte .. " »"
	cartePieces.Text = "+" .. tostring(d.pieces or poisson.pieces) .. " pièces"
	carteCarnet.Text = "Carnet de pêche : " .. Peche.especes(carnet) .. " / " .. #Peche.POISSONS .. " espèces · prise n° " .. tostring(d.n or 1)
	bordCarte.Color = c
	carte.Visible = true
	carte.Position = UDim2.fromScale(1.4, 0.45)
	TweenService:Create(carte, UI.BOUNCY, {Position = UDim2.fromScale(0.97, 0.45)}):Play()
	UI.jouer("succes")
	if poisson.rarete == "Épique" or poisson.rarete == "Légendaire" then
		UI.celebrer(gui, c, string.upper(poisson.rarete) .. " !")
	end
	task.delay(5.5, function()
		if moi == idCarte then
			TweenService:Create(carte, UI.FAST, {Position = UDim2.fromScale(1.4, 0.45)}):Play()
		end
	end)
end

local function sautPoisson(poisson, depuis: Vector3)
	local m = main()
	if not m then
		return
	end
	local k = poisson.taille
	local corps = Instance.new("Part")
	corps.Name = "PoissonPris"
	corps.Size = Vector3.new(0.5, 0.7, 1.4) * k
	corps.Material = Enum.Material.Neon
	corps.Color = poisson.couleur
	corps.Anchored, corps.CanCollide, corps.CanQuery, corps.CanTouch = true, false, false, false
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.Sphere
	sm.Parent = corps
	local queue = Instance.new("WedgePart")
	queue.Size = Vector3.new(0.15, 0.7, 0.6) * k
	queue.Material = Enum.Material.Neon
	queue.Color = poisson.couleur:Lerp(Color3.new(0, 0, 0), 0.25)
	queue.Anchored, queue.CanCollide, queue.CanQuery, queue.CanTouch = true, false, false, false
	queue.Parent = corps
	corps.Parent = workspace
	eclabousser(depuis, 20)
	local t0 = os.clock()
	local c
	c = RunService.RenderStepped:Connect(function()
		local u = math.min(1, (os.clock() - t0) / 0.8)
		local vers = m.Position + Vector3.new(0, 1, 0)
		local pos = depuis:Lerp(vers, u) + Vector3.new(0, math.sin(u * math.pi) * 5, 0)
		local cf = CFrame.lookAt(pos, vers + Vector3.new(0, 0.01, 0)) * CFrame.Angles(0, 0, math.sin(os.clock() * 25) * 0.4)
		corps.CFrame = cf
		queue.CFrame = cf * CFrame.new(0, 0, 0.9 * k) * CFrame.Angles(0, math.pi, 0)
		if u >= 1 then
			c:Disconnect()
			corps:Destroy()
		end
	end)
end

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	if genre == "Debut" then
		commencer(d)
	elseif genre == "Prise" then
		local poisson = Peche.PAR_ID[d.id]
		if poisson then
			local depuis = if partie and partie.bouchon then partie.bouchon.Position else (main() or {Position = Vector3.zero}).Position
			sautPoisson(poisson, depuis)
			task.delay(0.6, montrerCarte, poisson, d)
		end
		nettoyer()
	elseif genre == "Rate" then
		toast("Le poisson s'est échappé…", false)
		nettoyer()
	end
end)
