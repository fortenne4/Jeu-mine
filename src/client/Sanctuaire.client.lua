-- Sanctuaire de la grotte −50 m · SCRIPT CLIENT
-- Quand le serveur éveille le sanctuaire (attribut « SanctuaireEveil » du modèle de grotte, Sanctuaire.lua) :
-- cinématique de 4 s pour les joueurs proches (bandes noires, caméra qui glisse vers l'arche, runes qui s'allument
-- une à une, yeux des statues qui s'embrasent l'un après l'autre, titre), puis retour au jeu. Ensuite : compteur
-- des gardiens restants, annonce de l'ouverture du coffre, récompense du coffre. Un joueur arrivé plus tard voit
-- directement le sanctuaire éveillé. Tout est local (rien n'est répliqué).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Carte = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CarteNaine"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local PopupCoffre = require(script.Parent:WaitForChild("PopupCoffre"))
local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remote = ReplicatedStorage:WaitForChild(Carte.REMOTE) :: RemoteEvent

local CYAN = Color3.fromRGB(80, 230, 255)
local YEUX = Color3.fromRGB(150, 235, 255)
local VIOLET = Color3.fromRGB(165, 90, 255)
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local DISTANCE_CINEMATIQUE = 80

-- ================= Interface =================
local gui = creer("ScreenGui", {Name = "Sanctuaire", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 25, Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)
local bandes = {}
for i, y in {0, 1} do
	bandes[i] = creer("Frame", {AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 10, Parent = gui})
end
local titre = texte({Text = "LE SANCTUAIRE DE HALDUR", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78),
	Size = UDim2.fromScale(0.8, 0.08), TextTransparency = 1, Visible = false, ZIndex = 11, Parent = gui}, 56)
UI.dore(titre, 2) -- le contour (UIStroke) ne suit pas TextTransparency : le titre n'est visible que pendant la cinématique
local sousTitre = texte({Text = "Les gardiens s'éveillent…", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.85), Size = UDim2.fromScale(0.6, 0.04), TextTransparency = 1, Visible = false, ZIndex = 11, Parent = gui}, 26)
local plaque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.11), Size = UDim2.fromScale(0.26, 0.05),
	BackgroundColor3 = Color3.fromRGB(28, 18, 40), BackgroundTransparency = 0.15, Visible = false, ZIndex = 8, Parent = gui},
	{coin(0.35), trait(VIOLET, 2), creer("UISizeConstraint", {MinSize = Vector2.new(220, 34), MaxSize = Vector2.new(380, 48)})})
local plaqueTexte = texte({Text = "", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(220, 200, 255), Position = UDim2.fromScale(0.05, 0.15),
	Size = UDim2.fromScale(0.9, 0.7), ZIndex = 9, Parent = plaque}, 22)

local grondement = creer("Sound", {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, PlaybackSpeed = 0.35, Parent = SoundService})
local function son(vitesse: number, volume: number?)
	grondement.PlaybackSpeed = vitesse
	grondement.Volume = volume or 0.35
	SoundService:PlayLocalSound(grondement)
end

-- ================= Grotte courante =================
local function grotteAutour(pos: Vector3): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then
		return nil
	end
	for _, g in dossier:GetChildren() do
		local c, d = g:GetAttribute("Centre"), g:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return g
			end
		end
	end
	return nil
end

local function tagues(tag: string, g: Model): {BasePart}
	local t = {}
	for _, p in CollectionService:GetTagged(tag) do
		if p:IsA("BasePart") and p:IsDescendantOf(g) then
			table.insert(t, p)
		end
	end
	return t
end

-- ================= Éveil : runes et yeux =================
local function allumerRune(p: BasePart, instant: boolean)
	local info = if instant then TweenInfo.new(0) else TweenInfo.new(0.35, Enum.EasingStyle.Quad)
	if p.Name == "GlypheArche" then
		p.Color = Color3.new(1, 1, 1)
		TweenService:Create(p, info, {Transparency = 0.05}):Play()
		task.delay(if instant then 0 else 0.3, function()
			TweenService:Create(p, TweenInfo.new(0.6), {Color = CYAN}):Play()
		end)
	else
		TweenService:Create(p, if instant then info else TweenInfo.new(1.4), {Color = CYAN}):Play()
	end
end

local function allumerOeil(p: BasePart, instant: boolean)
	TweenService:Create(p, if instant then TweenInfo.new(0) else TweenInfo.new(0.5), {Color = YEUX}):Play()
	if not p:FindFirstChild("LueurOeil") then
		local l = Instance.new("PointLight")
		l.Name = "LueurOeil"
		l.Color, l.Range, l.Shadows = CYAN, 9, false
		l.Brightness = if instant then 2 else 0
		l.Parent = p
		if not instant then
			TweenService:Create(l, TweenInfo.new(0.5), {Brightness = 2}):Play()
		end
		local e = Instance.new("ParticleEmitter")
		e.Name = "FlammeOeil"
		e.Texture = TEX_ETINCELLE
		e.Color = ColorSequence.new(YEUX, VIOLET)
		e.LightEmission, e.LightInfluence = 1, 0
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
		e.Lifetime = NumberRange.new(0.4, 0.8)
		e.Rate = 18
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Acceleration = Vector3.new(0, 3, 0)
		e.Parent = p
	end
end

local function eveilInstantane(g: Model)
	for _, p in tagues("RuneArche", g) do
		allumerRune(p, true)
	end
	for _, p in tagues("YeuxGardien", g) do
		allumerOeil(p, true)
	end
end

-- ================= Cinématique =================
local enCinematique = false
local function controles(actifs: boolean)
	-- module de contrôles par défaut de Roblox, s'il existe (sans jamais l'attendre : ce jeu peut ne pas l'avoir)
	local scripts = joueur:FindFirstChild("PlayerScripts")
	local pm = scripts and scripts:FindFirstChild("PlayerModule")
	local ok, module = pcall(function()
		return if pm and pm:IsA("ModuleScript") then require(pm) else nil
	end)
	if ok and module and module.GetControls then
		local c = module:GetControls()
		if actifs then c:Enable() else c:Disable() end
	end
end

local function glisser(de: CFrame, vers: CFrame, duree: number, secousse: number?)
	local t0 = os.clock()
	while true do
		local a = math.clamp((os.clock() - t0) / duree, 0, 1)
		local e = a * a * (3 - 2 * a)
		local cf = de:Lerp(vers, e)
		if secousse and secousse > 0 then
			cf *= CFrame.new((math.random() - 0.5) * secousse, (math.random() - 0.5) * secousse, 0)
		end
		camera.CFrame = cf
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
end

local function derouler(g: Model)
	if enCinematique then
		return
	end
	enCinematique = true
	local arche = g:GetAttribute("ArcheSanctuaire")
	local axe = g:GetAttribute("ArcheAxe")
	if typeof(arche) ~= "Vector3" or typeof(axe) ~= "Vector3" then
		eveilInstantane(g)
		enCinematique = false
		return
	end
	local runes = tagues("RuneArche", g)
	table.sort(runes, function(a, b)
		return (a:GetAttribute("Ordre") or -1) < (b:GetAttribute("Ordre") or -1)
	end)
	local statues = {}
	for _, m in g:GetDescendants() do
		if m:IsA("Model") and m.Name == "StatueGardien" then
			table.insert(statues, m)
		end
	end
	local yeux = tagues("YeuxGardien", g)

	local typeAvant = camera.CameraType
	local cfAvant = camera.CFrame
	controles(false)
	camera.CameraType = Enum.CameraType.Scriptable
	for _, b in bandes do
		TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0.11)}):Play()
	end

	-- 1. vers l'arche, poussée lente pendant que les runes s'allument
	local cote = axe:Cross(Vector3.yAxis).Unit
	local haut = arche + Vector3.new(0, 9, 0)
	local planA = CFrame.lookAt(arche - axe * 20 + cote * 5 + Vector3.new(0, 5, 0), haut)
	local planA2 = CFrame.lookAt(arche - axe * 14 + cote * 2.5 + Vector3.new(0, 6, 0), haut)
	glisser(camera.CFrame, planA, 0.9)
	task.spawn(function()
		for i, r in runes do
			allumerRune(r, false)
			if r.Name == "GlypheArche" then
				son(0.3 + i * 0.03, 0.25)
			end
			task.wait(0.12)
		end
	end)
	glisser(planA, planA2, 1.5)

	-- 2. entre les statues : les yeux s'embrasent l'un après l'autre, la caméra tremble
	titre.Visible, sousTitre.Visible = true, true
	TweenService:Create(titre, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	TweenService:Create(sousTitre, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.3), {TextTransparency = 0}):Play()
	if #statues >= 1 then
		local centres = {}
		for _, s in statues do
			local cf, taille = s:GetBoundingBox()
			table.insert(centres, cf.Position + Vector3.new(0, taille.Y * 0.32, 0))
		end
		local milieu = Vector3.zero
		for _, c in centres do
			milieu += c
		end
		milieu /= #centres
		local depuis = milieu - axe * 10 + Vector3.new(0, -3, 0)
		local planB1 = CFrame.lookAt(depuis, centres[1])
		local planB2 = CFrame.lookAt(depuis, centres[#centres])
		glisser(planA2, planB1, 0.6)
		son(0.25, 0.5)
		for _, o in yeux do
			if (o.Position - centres[1]).Magnitude < 9 then
				allumerOeil(o, false)
			end
		end
		glisser(planB1, planB2, 0.9, 0.12)
		son(0.22, 0.5)
		for _, o in yeux do
			allumerOeil(o, false)
		end
		glisser(planB2, planB2 * CFrame.new(0, 0, -2), 0.5, 0.2)
	else
		for _, o in yeux do
			allumerOeil(o, false)
		end
		task.wait(1.5)
	end

	-- 3. retour au joueur
	TweenService:Create(titre, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
	TweenService:Create(sousTitre, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local retour = if racine then CFrame.lookAt(racine.Position - axe * 12 + Vector3.new(0, 6, 0), racine.Position + axe * 6) else cfAvant
	glisser(camera.CFrame, retour, 0.6)
	for _, b in bandes do
		TweenService:Create(b, TweenInfo.new(0.4), {Size = UDim2.fromScale(1, 0)}):Play()
	end
	titre.Visible, sousTitre.Visible = false, false
	camera.CameraType = if typeAvant == Enum.CameraType.Scriptable then Enum.CameraType.Custom else typeAvant
	controles(true)
	enCinematique = false
end

-- en cas d'erreur, la caméra et les contrôles reviennent toujours au joueur
local function cinematique(g: Model)
	local ok, err = pcall(derouler, g)
	if not ok then
		warn("[Sanctuaire] cinématique interrompue : " .. tostring(err))
		eveilInstantane(g)
		camera.CameraType = Enum.CameraType.Custom
		for _, b in bandes do
			b.Size = UDim2.fromScale(1, 0)
		end
		titre.Visible, sousTitre.Visible = false, false
		controles(true)
		enCinematique = false
	end
end

-- ================= Suivi de la grotte =================
local actuelle: Model? = nil
local connexions: {RBXScriptConnection} = {}

local function majPlaque(g: Model)
	local n = g:GetAttribute("GardiensRestants")
	if type(n) == "number" and n > 0 and not g:GetAttribute("CoffreOuvert") then
		plaque.Visible = true
		plaqueTexte.Text = "Gardiens du sanctuaire : " .. n
	else
		plaque.Visible = false
	end
end

local function quitter()
	for _, c in connexions do
		c:Disconnect()
	end
	table.clear(connexions)
	plaque.Visible = false
	actuelle = nil
end

local function entrer(g: Model)
	actuelle = g
	if g:GetAttribute("SanctuaireEveil") then
		eveilInstantane(g)
	end
	-- coffre déjà ouvert par ce joueur : plus d'invite chez lui
	local coffre = g:FindFirstChild("CoffreSanctuaire", true)
	if coffre then
		local function majCoffre()
			local ouverts = coffre:GetAttribute("OuvertPar")
			if type(ouverts) == "string" and ouverts:find("," .. joueur.UserId .. ",", 1, true) then
				for _, d in coffre:GetDescendants() do
					if d:IsA("ProximityPrompt") then
						d.Enabled = false
					end
				end
			end
		end
		majCoffre()
		table.insert(connexions, coffre:GetAttributeChangedSignal("OuvertPar"):Connect(majCoffre))
		-- l'invite est réactivée par le serveur à l'ouverture : on la recoupe si ce joueur a déjà ouvert
		table.insert(connexions, g:GetAttributeChangedSignal("CoffreOuvert"):Connect(function()
			task.defer(majCoffre)
		end))
	end
	majPlaque(g)
	table.insert(connexions, g:GetAttributeChangedSignal("SanctuaireEveil"):Connect(function()
		local arche = g:GetAttribute("ArcheSanctuaire")
		local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if racine and typeof(arche) == "Vector3" and (racine.Position - arche).Magnitude < DISTANCE_CINEMATIQUE then
			task.spawn(cinematique, g)
		else
			eveilInstantane(g)
			toast("Le sanctuaire s'est éveillé…", true)
		end
	end))
	table.insert(connexions, g:GetAttributeChangedSignal("GardiensRestants"):Connect(function()
		majPlaque(g)
	end))
	table.insert(connexions, g:GetAttributeChangedSignal("CoffreOuvert"):Connect(function()
		majPlaque(g)
		if g:GetAttribute("CoffreOuvert") then
			toast("Les gardiens sont vaincus : le coffre du sanctuaire s'ouvre !", true)
			UI.jouer("succes", 0.8)
		end
	end))
end

remote.OnClientEvent:Connect(function(genre, d)
	if genre == "Coffre" and type(d) == "table" then
		PopupCoffre.afficher({titre = "Coffre du sanctuaire", theme = "Sanctuaire", recompenses = {
			{genre = "pieces", n = tonumber(d.pieces) or 0}, {genre = "minerai", id = tostring(d.minerai), n = tonumber(d.nombre) or 0}}})
	end
end)

while true do
	task.wait(0.4)
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local g = racine and grotteAutour(racine.Position)
	if g ~= actuelle and not enCinematique then
		quitter()
		if g and g:GetAttribute("Niveau") == 1 then
			entrer(g)
		end
	end
end
