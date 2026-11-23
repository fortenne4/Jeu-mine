-- Cinématique du Casque du Cœur Magmatique · MODULE CLIENT (StarterPlayerScripts › Jeu › CinematiqueCasqueMagma)
-- Jouée en local par EnclumeMagma.client quand la forge réussit : les 3 reliques tournent en spirale et plongent dans
-- l'Enclume des Maîtres, la fente s'embrase, 3 coups de marteau, le casque s'élève dans une gerbe de braises, puis
-- titre + stats. Sautable (bouton Passer, Échap, B). Tout ce qui est créé est détruit à la fin ; caméra rendue même
-- si le joueur meurt.
--   CinematiqueCasqueMagma.jouer() -> boolean   false = impossible (pas de perso, déjà en cours)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local CasqueMagma = require(Partage:WaitForChild("CasqueMagma"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))
local LogosReliques = require(script.Parent:WaitForChild("LogosReliques"))
local creer, coin, trait, texte = UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local V = Vector3.new
local CASQUE = CasqueMagma.CASQUE

local CLE = "CinematiqueCasque"
local LIAISON = "CinematiqueCasqueMagma"
local MAGMA = Color3.fromRGB(255, 110, 30)
local MAGMA_VIF = Color3.fromRGB(255, 176, 70)
local BLANC_CHAUD = Color3.fromRGB(255, 236, 190)
local FONTE = Color3.fromRGB(46, 40, 44)
local ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local FEU = "rbxasset://textures/particles/fire_main.dds"
local INTERFACES = {Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.EmotesMenu, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health}

-- ================= Déroulé (secondes) =================
local T_PLONGEE = 2.3
local COUPS = {2.95, 3.5, 4.05}
local FENETRE = 0.55 -- levée + frappe du marteau
local LEVE = 1.35 -- angle max du marteau (rad)
local T_CASQUE, T_TITRE, T_EQUIPE, DUREE = 4.45, 5.0, 6.9, 8.2
local FONDU = 0.45
local BANDES = 0.11

local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end
local function rebond(u: number): number
	u = math.clamp(u, 0, 1) - 1
	return 1 + 2.2 * u * u * u + 1.2 * u * u
end

-- L'enclume activée par le joueur : retenue au déclenchement de l'invite
local derniereInvite: ProximityPrompt? = nil
ProximityPromptService.PromptTriggered:Connect(function(invite)
	if invite:GetAttribute("EnclumeMagma") then
		derniereInvite = invite
	end
end)

local function trouverEnclume(pos: Vector3): Model?
	local inv = derniereInvite
	local m = inv and inv.Parent and inv.Parent.Parent
	if m and m:IsA("Model") and m.Name == "EnclumePilier" and m:IsDescendantOf(workspace) then
		return m
	end
	local meilleur, dmin = nil, 60
	for _, d in workspace:GetDescendants() do
		if d.Name == "EnclumePilier" and d:IsA("Model") then
			local dist = (d:GetPivot().Position - pos).Magnitude
			if dist < dmin then
				meilleur, dmin = d, dist
			end
		end
	end
	return meilleur
end

local function piece(parent: Instance, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size, p.CFrame, p.Color, p.Material = taille, cf, couleur, mat
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function emetteur(parent: Instance, texture: string, props: {[string]: any}): ParticleEmitter
	props.Texture, props.Rate, props.LightEmission, props.Parent = texture, props.Rate or 0, props.LightEmission or 1, parent
	return creer("ParticleEmitter", props)
end

local function son(parent: Instance, id: string, volume: number): Sound
	return creer("Sound", {SoundId = id, Volume = volume, RollOffMaxDistance = 120, Parent = parent})
end

-- Silhouette de secours si le modèle 3D manque : dôme, visière, crête
local function silhouette(): Model
	local m = Instance.new("Model")
	m.Name = "CasqueSilhouette"
	local dome = piece(m, V(2.2, 2, 2.3), CFrame.identity, Color3.fromRGB(60, 30, 26), Enum.Material.Metal, "Racine")
	Instance.new("SpecialMesh", dome).MeshType = Enum.MeshType.Sphere
	piece(m, V(1.6, 0.28, 0.3), CFrame.new(0, -0.1, -1.05), MAGMA, Enum.Material.Neon, "Visiere")
	piece(m, V(0.3, 0.9, 1.9), CFrame.new(0, 0.85, 0), MAGMA, Enum.Material.Neon, "Crete")
	piece(m, V(2.4, 0.22, 2.5), CFrame.new(0, -0.75, 0), FONTE, Enum.Material.Metal, "Bord")
	m.PrimaryPart = dome
	return m
end

local function construireCasque(): Model
	local ok, res = pcall(function()
		local AV = require(Partage:WaitForChild("ArmuresVoxels")) :: any
		if AV.existe(CasqueMagma.MODELE) then
			return AV.construire(CasqueMagma.MODELE, nil, V(2.6, 2.6, 2.6))
		end
		return nil
	end)
	if ok and typeof(res) == "Instance" and res:IsA("Model") then
		return res
	end
	return silhouette()
end

-- ================= Interface du jeu (masquée pendant la cinématique) =================
local controles = nil
local function lireControles()
	if controles then
		return controles
	end
	local module = joueur:FindFirstChild("PlayerScripts") and joueur.PlayerScripts:FindFirstChild("PlayerModule")
	if module then
		local ok, res = pcall(function() return (require(module :: any) :: any):GetControls() end)
		if ok then
			controles = res
		end
	end
	return controles
end

local function masquerInterface(etat)
	for _, g in joueur.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g ~= etat.gui and g.Enabled then
			g.Enabled = false
			table.insert(etat.guis, g)
		end
	end
	for i, ty in INTERFACES do
		local ok, actif = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, ty)
		if ok then
			etat.coeur[i] = actif
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, ty, false)
		end
	end
	etat.invites = ProximityPromptService.Enabled
	pcall(function() ProximityPromptService.Enabled = false end)
	local c = lireControles()
	etat.controles = c ~= nil and pcall(function() c:Disable() end)
end

local function afficherInterface(etat)
	for _, g in etat.guis do
		if g.Parent then
			g.Enabled = true
		end
	end
	for i, ty in INTERFACES do
		if etat.coeur[i] ~= nil then
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, ty, etat.coeur[i])
		end
	end
	pcall(function() ProximityPromptService.Enabled = etat.invites end)
	if etat.controles and controles then
		pcall(function() controles:Enable() end)
	end
end

-- ================= Écran : bandes, flash, titre, Passer =================
local function construireEcran(etat)
	local gui = creer("ScreenGui", {Name = "CinematiqueCasque", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 101,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	etat.gui = gui
	local function noir(nom: string, ancre: number): Frame
		return creer("Frame", {Name = nom, AnchorPoint = Vector2.new(0, ancre), Position = UDim2.fromScale(0, ancre), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 5, Parent = gui})
	end
	etat.bandes = {noir("BandeHaut", 0), noir("BandeBas", 1)}
	etat.flash = creer("Frame", {Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = MAGMA_VIF, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 2, Parent = gui})
	etat.voile = creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 20, Parent = gui})

	-- Titre (caché jusqu'à T_TITRE)
	local bloc = creer("Frame", {Name = "Titre", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.9, 0.28),
		BackgroundTransparency = 1, Visible = false, ZIndex = 10, Parent = gui})
	etat.titre = bloc
	local nom = texte({Text = "CASQUE DU CŒUR MAGMATIQUE", Font = Enum.Font.Fantasy, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.32), TextTransparency = 1, ZIndex = 11, Parent = bloc}, 58)
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, BLANC_CHAUD),
		ColorSequenceKeypoint.new(0.5, MAGMA_VIF), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 60, 14))}), Parent = nom})
	local contour = creer("UIStroke", {Thickness = 2.5, Color = Color3.fromRGB(40, 10, 4), Transparency = 1, Parent = nom})
	local ligne = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = MAGMA, BorderSizePixel = 0, ZIndex = 11, Parent = bloc}, {creer("UIGradient", {Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})})
	local badge = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.13, 0.15),
		BackgroundColor3 = CASQUE.couleur, ZIndex = 11, Parent = bloc}, {coin(0.5), creer("UISizeConstraint", {MinSize = Vector2.new(90, 22)}),
		UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(170, 120, 110))})
	texte({Text = string.upper(CASQUE.rarete), Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.7), ZIndex = 12, Parent = badge}, 20)
	UI.rarete(badge, MAGMA_VIF, 4, etat.tweens)
	local stats = {
		{"Défense", "+" .. CASQUE.defense, Color3.fromRGB(150, 196, 255)},
		{"Vie maximale", "+" .. CASQUE.vie, Color3.fromRGB(120, 230, 120)},
		{"Résistance au feu", "+" .. math.floor(CASQUE.resistanceFeu * 100 + 0.5) .. " %", MAGMA_VIF},
	}
	local cases = {}
	for k, s in stats do
		local x = 0.5 + (k - 2) * 0.27
		local case = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0.6), Size = UDim2.fromScale(0.25, 0.2),
			BackgroundColor3 = Color3.fromRGB(20, 10, 8), BackgroundTransparency = 0.25, ZIndex = 11, Parent = bloc}, {coin(0.35), trait(s[3], 1.5, 0.3)})
		texte({Text = s[1], Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(240, 226, 206), TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.07, 0.15), Size = UDim2.fromScale(0.6, 0.7), ZIndex = 12, Parent = case}, 20)
		texte({Text = s[2], Font = Enum.Font.GothamBlack, TextColor3 = s[3], TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.62, 0.1), Size = UDim2.fromScale(0.32, 0.8), ZIndex = 12, Parent = case}, 24)
		case.Visible = false
		cases[k] = case
	end
	local equipe = texte({Text = "Équipe-le depuis ton sac", Font = Enum.Font.GothamBold, TextColor3 = MAGMA_VIF, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.6, 0.12), TextTransparency = 1, ZIndex = 11, Parent = bloc}, 22)
	etat.ui = {nom = nom, contour = contour, ligne = ligne, badge = badge, cases = cases, equipe = equipe}

	-- Bouton Passer
	local passer = creer("TextButton", {Name = "Passer", Text = "Passer  ›", Font = Enum.Font.GothamBold, TextScaled = true,
		TextColor3 = Color3.fromRGB(240, 226, 206), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.97, 0, 1, -12), Size = UDim2.fromScale(0.11, 0.05),
		BackgroundColor3 = Color3.fromRGB(30, 16, 12), BackgroundTransparency = 0.2, AutoButtonColor = true, ZIndex = 30, Parent = gui},
		{coin(0.3), trait(MAGMA, 1.5, 0.3), creer("UISizeConstraint", {MinSize = Vector2.new(96, 30), MaxSize = Vector2.new(170, 44)}),
			creer("UIPadding", {PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0)}), creer("UITextSizeConstraint", {MaxTextSize = 20})})
	etat.passer = passer
	gui.Parent = joueur:WaitForChild("PlayerGui")
end

local function montrerTitre(etat)
	local u = etat.ui
	etat.titre.Visible = true
	local echelle = UI.echelle(u.nom)
	echelle.Scale = 1.9
	TweenService:Create(echelle, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(u.nom, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
	TweenService:Create(u.contour, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
	TweenService:Create(u.ligne, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.2), {Size = UDim2.new(0.62, 0, 0, 2)}):Play()
	local eb = UI.echelle(u.badge)
	eb.Scale = 0
	TweenService:Create(eb, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.35), {Scale = 1}):Play()
	for k, c in u.cases do
		local cible = c.Position
		c.Position = cible + UDim2.fromScale(0, 0.25)
		c.BackgroundTransparency = 1
		c.Visible = true
		local info = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.6 + k * 0.15)
		TweenService:Create(c, info, {Position = cible, BackgroundTransparency = 0.25}):Play()
		task.delay(0.6 + k * 0.15, UI.jouer, "metal", 0.9 + k * 0.1)
	end
	for _, t in etat.tweens do
		t:Play()
	end
	UI.jouer("succes", 0.85)
end

-- ================= Scène 3D =================
local function construireScene(etat, perso: Model, racine: BasePart, humain: Humanoid)
	local dossier = Instance.new("Folder")
	dossier.Name = "CinematiqueCasqueMagma"
	etat.dossier = dossier

	local enclume = trouverEnclume(racine.Position)
	local tableP = enclume and enclume:FindFirstChild("Table")
	local F: CFrame
	local tailleTable: Vector3
	if tableP and tableP:IsA("BasePart") then
		tailleTable = tableP.Size
		F = tableP.CFrame * CFrame.new(0, tailleTable.Y / 2, 0)
		if (racine.Position - F.Position):Dot(F.ZVector) < 0 then
			F *= CFrame.Angles(0, math.pi, 0)
		end
		local fente = enclume:FindFirstChild("FenteMagma")
		if fente and fente:IsA("BasePart") then
			local l = F:PointToObjectSpace(fente.Position)
			F *= CFrame.new(l.X, 0, l.Z)
		end
	else
		-- repli : petite enclume locale devant le joueur
		local avant = racine.CFrame.LookVector * V(1, 0, 1)
		avant = if avant.Magnitude > 0.01 then avant.Unit else V(0, 0, -1)
		local sol = racine.Position.Y - humain.HipHeight - racine.Size.Y / 2
		tailleTable = V(3.4, 0.9, 1.3)
		local base = racine.Position * V(1, 0, 1) + V(0, sol, 0) + avant * 7
		F = CFrame.lookAt(base, base + avant) * CFrame.new(0, 2.5, 0)
		piece(dossier, V(2.4, 1.6, 1.4), F * CFrame.new(0, -1.7, 0), Color3.fromRGB(52, 46, 50), Enum.Material.Slate, "Socle")
		piece(dossier, tailleTable, F * CFrame.new(0, -0.45, 0), FONTE, Enum.Material.Metal, "Table")
		piece(dossier, V(2.2, 0.06, 0.5), F * CFrame.new(0, 0.02, 0), MAGMA, Enum.Material.Neon, "FenteMagma")
	end
	etat.F, etat.tailleTable = F, tailleTable

	-- Brasier sur la fente + coulées de lave sur la face avant
	local brasier = piece(dossier, V(2.2, 0.1, 0.5), F * CFrame.new(0, 0.05, 0), BLANC_CHAUD, Enum.Material.Neon, "Brasier")
	brasier.Transparency = 1
	etat.brasier = brasier
	etat.lumiere = creer("PointLight", {Color = MAGMA, Range = 16, Brightness = 0, Shadows = true, Parent = brasier})
	etat.flammes = emetteur(brasier, FEU, {Lifetime = NumberRange.new(0.35, 0.7), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Top, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.05)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 70, 10)),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})})
	etat.coulees = {}
	for i, x in {-0.55, 0.4} do
		local c = piece(dossier, V(0.3, 0.05, 0.08), F, MAGMA, Enum.Material.Neon, "Coulee" .. i)
		c.Transparency = 1
		etat.coulees[i] = {c, x}
	end

	local point = creer("Attachment", {Parent = brasier})
	etat.gerbe = emetteur(point, ETINCELLE, {Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(9, 20), SpreadAngle = Vector2.new(75, 75),
		Acceleration = V(0, -45, 0), Drag = 2, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 100, 24))})
	etat.braises = emetteur(point, ETINCELLE, {Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(3, 11), SpreadAngle = Vector2.new(180, 180),
		Acceleration = V(0, 5, 0), Drag = 1.5, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0)}),
		Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 70, 16))})
	etat.fumee = emetteur(point, "rbxasset://textures/particles/smoke_main.dds", {LightEmission = 0, Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(40, 40), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 3)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)}), Color = ColorSequence.new(Color3.fromRGB(90, 70, 66))})

	-- Reliques : gemme Neon + lumière + traînée + logo
	etat.reliques = {}
	for i, r in CasqueMagma.RELIQUES do
		local p = piece(dossier, V(0.05, 0.05, 0.05), F, r.couleur, Enum.Material.Neon, "Relique" .. i)
		local a0 = creer("Attachment", {Position = V(0, 0.18, 0), Parent = p})
		local a1 = creer("Attachment", {Position = V(0, -0.18, 0), Parent = p})
		creer("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = 0.35, LightEmission = 1, FaceCamera = true,
			Color = ColorSequence.new(r.couleur:Lerp(Color3.new(1, 1, 1), 0.3), MAGMA), Transparency = NumberSequence.new(0.1, 1), Parent = p})
		creer("PointLight", {Color = r.couleur, Range = 7, Brightness = 1.5, Parent = p})
		local bb = creer("BillboardGui", {Size = UDim2.fromScale(1.3, 1.3), StudsOffset = V(0, 1, 0), LightInfluence = 0, Enabled = false, Parent = p})
		LogosReliques.creer(r.id, bb)
		etat.reliques[i] = {part = p, bb = bb, phase = (i - 1) / 3 * math.pi * 2}
	end

	-- Marteau : pivot (main) en +X, tête qui tombe sur la fente
	local marteau = {}
	local function partieMarteau(taille: Vector3, decalage: CFrame, couleur: Color3, mat: Enum.Material, nom: string)
		local p = piece(dossier, taille, F, couleur, mat, nom)
		p.Transparency = 1
		table.insert(marteau, {p, decalage})
	end
	partieMarteau(V(2.1, 0.2, 0.2), CFrame.new(-1.05, 0, 0), Color3.fromRGB(96, 62, 38), Enum.Material.Wood, "Manche")
	partieMarteau(V(0.62, 0.95, 0.62), CFrame.new(-2.1, 0, 0), FONTE, Enum.Material.Metal, "Tete")
	partieMarteau(V(0.66, 0.14, 0.66), CFrame.new(-2.1, 0.12, 0), MAGMA, Enum.Material.Neon, "Rune")
	etat.marteau = marteau
	etat.pivotMarteau = F * CFrame.new(2.1, 0.5, 0)

	-- Onde de choc
	local onde = piece(dossier, V(0.12, 1, 1), F * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), MAGMA_VIF, Enum.Material.Neon, "Onde")
	onde.Shape = Enum.PartType.Cylinder
	onde.Transparency = 1
	etat.onde = onde

	-- Lueur qui suit le casque
	local lueur = piece(dossier, V(0.2, 0.2, 0.2), F, MAGMA, Enum.Material.Neon, "Lueur")
	lueur.Transparency = 1
	etat.lueurCasque = creer("PointLight", {Color = MAGMA, Range = 14, Brightness = 0, Parent = lueur})
	etat.braisesCasque = emetteur(lueur, ETINCELLE, {Lifetime = NumberRange.new(0.8, 1.5), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180),
		Acceleration = V(0, 2.5, 0), Size = NumberSequence.new(0.1, 0), Color = ColorSequence.new(MAGMA_VIF, MAGMA)})
	etat.lueur = lueur

	etat.sonMarteau = son(brasier, "rbxassetid://9125361455", 1)
	etat.sonLame = son(brasier, "rbxasset://sounds/unsheath.wav", 0.8)
	etat.sonVapeur = son(brasier, "rbxasset://sounds/impact_water.mp3", 0.6)

	for _, d in perso:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(etat.perso, d)
		end
	end
	dossier.Parent = workspace

	-- Casque : construit en parallèle (CSG possible), invisible jusqu'à T_CASQUE
	task.spawn(function()
		local objet = construireCasque()
		if not (etat.actif and dossier.Parent) then
			objet:Destroy()
			return
		end
		objet:PivotTo(CFrame.identity)
		local cf = objet:GetBoundingBox()
		local pieces = {}
		for _, p in objet:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
				table.insert(pieces, {p, p.Transparency})
				p.Transparency = 1
			end
		end
		local h = creer("Highlight", {FillColor = MAGMA, FillTransparency = 1, OutlineColor = MAGMA_VIF, OutlineTransparency = 1,
			DepthMode = Enum.HighlightDepthMode.Occluded, Parent = objet})
		etat.centreInv = CFrame.new(-cf.Position)
		etat.piecesCasque, etat.halo = pieces, h
		objet.Parent = dossier
		etat.casque = objet
	end)
end

-- ================= Boucle =================
local actif = nil

local function terminer(etat)
	if actif ~= etat then
		return
	end
	actif = nil
	etat.actif = false
	RunService:UnbindFromRenderStep(LIAISON)
	for _, c in etat.connexions do
		c:Disconnect()
	end
	for _, t in etat.tweens do
		t:Cancel()
	end
	pcall(function()
		etat.dossier:Destroy()
		for _, p in etat.perso do
			if p.Parent then
				p.LocalTransparencyModifier = 0
			end
		end
		local camera = etat.camera
		camera.FieldOfView = etat.fov
		camera.CameraType = Enum.CameraType.Custom
		local h = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
		if h then
			camera.CameraSubject = h
		end
	end)
	afficherInterface(etat)
	Curseur.liberer(CLE, false)
	local gui = etat.gui
	etat.titre.Visible = false
	etat.passer.Visible = false
	etat.flash.BackgroundTransparency = 1
	etat.voile.BackgroundTransparency = 0
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	TweenService:Create(etat.voile, info, {BackgroundTransparency = 1}):Play()
	for _, b in etat.bandes do
		TweenService:Create(b, info, {Size = UDim2.fromScale(1, 0)}):Play()
	end
	Debris:AddItem(gui, 0.6)
end

local function impact(etat, force: number)
	etat.eclat, etat.secousse = math.max(etat.eclat, force), math.max(etat.secousse, force)
end

local function etape(etat, dt: number)
	local camera = etat.camera
	if workspace.CurrentCamera ~= camera or not etat.dossier.Parent then
		terminer(etat)
		return
	end
	local t = os.clock() - etat.debut
	if t >= DUREE then
		terminer(etat)
		return
	end
	local F = etat.F
	etat.eclat *= math.exp(-dt * 7)
	etat.secousse *= math.exp(-dt * 9)

	-- 1. Reliques en spirale, puis plongée
	if not etat.plonge then
		local u = lisse((t - 0.4) / (T_PLONGEE - 0.4))
		local r = 3.2 * (1 - u) ^ 1.3
		local y = 0.25 + 2.6 * (1 - u) * (1 - u) + 0.6 * math.sin(u * math.pi)
		for i, o in etat.reliques do
			local s = rebond((t - 0.2 - i * 0.18) / 0.45)
			local a = o.phase + u * 7.5 + t * 0.6
			o.part.Size = V(0.55, 0.55, 0.55) * math.max(s, 0.02)
			o.part.CFrame = F * CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(t * 3 + i, t * 4, 0)
			if s > 0 and not o.vu then
				o.vu = true
				o.bb.Enabled = true
				UI.jouer("succes", 1 + i * 0.12)
			end
		end
		if t >= T_PLONGEE then
			etat.plonge = true
			for _, o in etat.reliques do
				o.part:Destroy()
			end
			impact(etat, 0.9)
			etat.gerbe:Emit(45)
			etat.fumee:Emit(10)
			etat.flammes.Rate = 40
			etat.braises.Rate = 12
			etat.sonVapeur.PlaybackSpeed = 0.8
			etat.sonVapeur:Play()
			etat.sonLame.PlaybackSpeed = 0.6
			etat.sonLame:Play()
		end
	end

	-- 2. Brasier et coulées
	local feu = lisse((t - T_PLONGEE) / 0.4) * (1 - lisse((t - DUREE + 1.6) / 1.2))
	local battement = 0.5 + 0.5 * math.sin(t * 11)
	local brasier = etat.brasier
	brasier.Transparency = 1 - feu
	brasier.Size = V(2.25, 0.1 + 0.18 * feu + 0.1 * etat.eclat, 0.55)
	brasier.Color = MAGMA:Lerp(BLANC_CHAUD, 0.35 + 0.4 * battement * feu + 0.3 * etat.eclat)
	etat.lumiere.Brightness = feu * (2.5 + battement) + etat.eclat * 6
	local tt = etat.tailleTable
	for _, c in etat.coulees do
		local L = tt.Y * lisse((t - T_PLONGEE - 0.15) / 1.6) + 0.02
		c[1].Size = V(0.3, L, 0.08)
		c[1].CFrame = F * CFrame.new(c[2], -L / 2 + 0.02, tt.Z / 2 + 0.03)
		c[1].Transparency = 1 - feu
	end

	-- 3. Marteau : 3 coups
	local apparition = lisse((t - 2.35) / 0.25) * (1 - lisse((t - COUPS[#COUPS] - 0.15) / 0.3))
	if apparition > 0 or etat.marteauVisible then
		etat.marteauVisible = apparition > 0
		local a = 0
		local dernier = COUPS[#COUPS]
		if t > dernier then
			a = LEVE * 0.6 * lisse((t - dernier) / 0.3)
		else
			for _, ti in COUPS do
				if t <= ti then
					local u = (t - (ti - FENETRE)) / FENETRE
					a = if u < 0.72 then LEVE * lisse(u / 0.72) else LEVE * (1 - ((u - 0.72) / 0.28) ^ 2)
					break
				end
			end
		end
		local M = etat.pivotMarteau * CFrame.Angles(0, 0, -math.max(a, 0))
		for _, m in etat.marteau do
			m[1].CFrame = M * m[2]
			m[1].Transparency = 1 - apparition
		end
	end
	while etat.coup < #COUPS and t >= COUPS[etat.coup + 1] do
		etat.coup += 1
		impact(etat, 0.75 + etat.coup * 0.1)
		etat.gerbe:Emit(28 + etat.coup * 8)
		etat.sonMarteau.PlaybackSpeed = 0.9 + etat.coup * 0.08
		etat.sonMarteau:Play()
		etat.sonLame.PlaybackSpeed = 1.6 + etat.coup * 0.1
		etat.sonLame:Play()
	end

	-- 4. Le casque s'élève
	if t >= T_CASQUE and not etat.revele then
		etat.revele = true
		impact(etat, 1.2)
		etat.braises:Emit(90)
		etat.gerbe:Emit(60)
		etat.flammes.Rate = 15
		etat.braisesCasque.Rate = 14
		etat.sonMarteau.PlaybackSpeed = 0.6
		etat.sonMarteau:Play()
		etat.sonVapeur.PlaybackSpeed = 1.3
		etat.sonVapeur:Play()
		local onde = etat.onde
		onde.Transparency = 0.1
		local info = TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(onde, info, {Size = V(0.04, 18, 18), Transparency = 1}):Play()
		if etat.halo then
			etat.halo.FillTransparency, etat.halo.OutlineTransparency = 0.05, 0
			TweenService:Create(etat.halo, TweenInfo.new(1.8, Enum.EasingStyle.Quad), {FillTransparency = 0.8, OutlineTransparency = 0.4}):Play()
		end
	end
	local yCasque = 0
	if etat.revele then
		local d = t - T_CASQUE
		local montee = rebond(d / 1.1)
		yCasque = 0.6 + 2.4 * montee + math.sin(t * 2) * 0.08 * lisse(d - 1)
		local cf = F * CFrame.new(0, yCasque, 0)
		etat.lueur.CFrame = cf
		etat.lueurCasque.Brightness = 2.5 + battement * 0.8 + etat.eclat * 4
		local objet = etat.casque
		if objet then
			objet:PivotTo(cf * CFrame.Angles(0, math.pi - 1.4 + d * 0.6, 0) * etat.centreInv)
			local f = lisse(d / 0.35)
			for _, pc in etat.piecesCasque do
				pc[1].Transparency = pc[2] + (1 - pc[2]) * (1 - f)
			end
		end
	end

	-- 5. Titre
	if t >= T_TITRE and not etat.titreVu then
		etat.titreVu = true
		montrerTitre(etat)
	end
	if t >= T_EQUIPE and not etat.equipeVu then
		etat.equipeVu = true
		TweenService:Create(etat.ui.equipe, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
	end

	-- Caméra (3 plans) + secousse
	local k = etat.secousse * 0.02
	local sec = CFrame.Angles(k * math.sin(t * 53), k * math.sin(t * 41), k * 0.5 * math.sin(t * 37))
	local cible: Vector3
	local pos: Vector3
	if t < T_PLONGEE then
		local u = lisse(t / T_PLONGEE)
		local a, d = -0.7 + 0.9 * u, 9.5 - 2.5 * u
		pos, cible = F * V(math.sin(a) * d, 4.2 - 1.2 * u, math.cos(a) * d), F * V(0, 1.1 - 0.5 * u, 0)
		camera.FieldOfView = 55
	elseif t < T_CASQUE then
		local u = lisse((t - T_PLONGEE) / (T_CASQUE - T_PLONGEE))
		pos, cible = F * V(-2.6 + 0.5 * u, 1.7 - 0.3 * u, 5 - 0.8 * u), F * V(0.3, 0.35, 0)
		camera.FieldOfView = 48
	else
		local u = lisse((t - T_CASQUE) / (DUREE - T_CASQUE))
		local a, d = 0.4 - 0.55 * u, 7.2 - 1.6 * u
		pos, cible = F * V(math.sin(a) * d, 1.2 + 0.5 * u, math.cos(a) * d), F * V(0, 0.4 + yCasque * 0.8, 0)
		camera.FieldOfView = 44
	end
	camera.CFrame = CFrame.lookAt(pos, cible) * sec
	etat.flash.BackgroundTransparency = 1 - math.min(etat.eclat, 1) * 0.55
	etat.voile.BackgroundTransparency = math.clamp((DUREE - t) / FONDU, 0, 1)
	for _, p in etat.perso do
		p.LocalTransparencyModifier = 1
	end
end

local CinematiqueCasqueMagma = {}

function CinematiqueCasqueMagma.enCours(): boolean
	return actif ~= nil
end

function CinematiqueCasqueMagma.jouer(): boolean
	if actif then
		return false
	end
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not (perso and humain and racine and racine:IsA("BasePart") and humain.Health > 0 and camera) then
		return false
	end
	local etat = {
		actif = true, camera = camera, fov = camera.FieldOfView, perso = {}, guis = {}, coeur = {}, connexions = {}, tweens = {},
		debut = os.clock(), coup = 0, eclat = 0, secousse = 0,
	}
	actif = etat
	local ok, err = pcall(function()
		construireEcran(etat)
		construireScene(etat, perso, racine :: BasePart, humain :: Humanoid)
	end)
	if not ok then
		warn("[CinematiqueCasqueMagma]", err)
		actif = nil
		if etat.dossier then
			etat.dossier:Destroy()
		end
		if etat.gui then
			etat.gui:Destroy()
		end
		return false
	end
	masquerInterface(etat)
	Curseur.liberer(CLE, true)
	camera.CameraType = Enum.CameraType.Scriptable
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, b in etat.bandes do
		TweenService:Create(b, info, {Size = UDim2.fromScale(1, BANDES)}):Play()
	end
	local function passer()
		if actif == etat then
			UI.jouer("clic", 0.9)
			terminer(etat)
		end
	end
	table.insert(etat.connexions, etat.passer.Activated:Connect(passer))
	table.insert(etat.connexions, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			passer()
		end
	end))
	table.insert(etat.connexions, humain.Died:Connect(function() terminer(etat) end))
	table.insert(etat.connexions, joueur.CharacterRemoving:Connect(function() terminer(etat) end))
	task.delay(DUREE + 3, terminer, etat)
	local dernier = os.clock()
	RunService:BindToRenderStep(LIAISON, Enum.RenderPriority.Camera.Value + 1, function()
		local maintenant = os.clock()
		local dt = math.min(maintenant - dernier, 0.1)
		dernier = maintenant
		local reussi, e = pcall(etape, etat, dt)
		if not reussi then
			warn("[CinematiqueCasqueMagma]", e)
			terminer(etat)
		end
	end)
	return true
end

return CinematiqueCasqueMagma
