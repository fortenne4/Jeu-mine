-- Boss du village · SCRIPT CLIENT : affichage seulement (le serveur BossVillage.server fait foi).
-- 1. Barre de PV du boss : grand trait rouge centré en haut de l'écran, nom du boss en plus petit dessous, visible seulement dans l'arène (attribut joueur « DansArene ») : nom, titre, PV chiffrés, temps
--    restant ; la partie perdue s'efface en traînée, secousse sur les gros coups, lisere qui bat sous 35 %,
--    petits crans aux seuils de phase (66 % / 33 %). Masquée pendant le chargement et l'intro.
-- 2. Bandeau d'annonce pour tous (boss qui arrive, victoire, échec).
-- 3. Aiguillage des événements serveur vers les modules :
--    BossAttente (puce, guide, file d'attente) · BossCinematique (fondu, chargement, intro, retour) ·
--    BossCombat (phases, secousses, touché, mineurs debout, K.O.) · BossResultats (bannière de fin, classement).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Config = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("BossVillage"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local joueur = Players.LocalPlayer
local playerGui = joueur:WaitForChild("PlayerGui")
local dossier = ReplicatedStorage:WaitForChild(Config.DOSSIER)
local evenement = dossier:WaitForChild("Evenement")
local action = dossier:WaitForChild("Action")

local gui = creer("ScreenGui", {Name = "BossVillage", ResetOnSpawn = false, DisplayOrder = 4,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
-- écran plein (fondus, chargement, intro, K.O., résultats) au-dessus du reste de l'interface
local cinema = creer("ScreenGui", {Name = "BossVillageCinema", ResetOnSpawn = false, DisplayOrder = 30, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local etat = {cinematique = false} -- partagé avec les modules

-- ================= Barre de PV du boss =================
-- Un grand trait rouge centré en haut de l'écran, le nom du boss en plus petit dessous.
local ROUGE = Color3.fromRGB(205, 28, 32)
local barre = creer("Frame", {Name = "BarreBoss", AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Visible = false,
	Size = UDim2.fromOffset(900, 70), Parent = gui})
local jauge = creer("Frame", {Name = "Jauge", Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Color3.fromRGB(18, 8, 8),
	BackgroundTransparency = 0.15, ClipsDescendants = true, BorderSizePixel = 0, Parent = barre}, {coin(0.5)})
local lisere = creer("UIStroke", {Color = Color3.fromRGB(10, 4, 4), Thickness = 2, Transparency = 0.2, Parent = jauge})
local trainee = creer("Frame", {Name = "Trainee", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 225, 200),
	BorderSizePixel = 0, Parent = jauge}, {coin(0.5)})
local plein = creer("Frame", {Name = "Plein", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	ZIndex = 2, Parent = jauge}, {coin(0.5)})
creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, ROUGE:Lerp(Color3.new(1, 1, 1), 0.3)),
	ColorSequenceKeypoint.new(0.5, ROUGE), ColorSequenceKeypoint.new(1, ROUGE:Lerp(Color3.new(0, 0, 0), 0.45))}), Parent = plein})
-- crans des phases : fines marques sombres sur le trait (le look de la barre ne change pas)
for _, seuil in Config.PHASES do
	creer("Frame", {Name = "Cran", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(seuil, 0), Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = Color3.fromRGB(20, 6, 6), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 3, Parent = jauge})
end
local nomBoss = texte({Name = "Nom", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 24), Parent = barre}, 22)
creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 8, 6), Parent = nomBoss})
local titreBoss = texte({Name = "Titre", Font = Enum.Font.Antique, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.Or,
	Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(1, 0, 0, 16), Parent = barre}, 15)
local pvTexte = texte({Name = "PV", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.new(0.6, 0, 0, 24), Size = UDim2.new(0.4, 0, 0, 20), Parent = barre}, 15)
creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 8, 6), Parent = pvTexte})
local tempsTexte = texte({Name = "Temps", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.Gris,
	Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(0.4, 0, 0, 20), Parent = barre}, 15)
creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 8, 6), Parent = tempsTexte})

local function placer()
	local ecran = gui.AbsoluteSize
	local largeur = math.clamp(ecran.X * 0.6, 300, 1100)
	barre.Size = UDim2.fromOffset(largeur, 66)
	barre.Position = UDim2.new(0.5, 0, 0, 14)
	barre:SetAttribute("Base", barre.Position)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placer)

local pvAffiche = 0
local pouls: Tween? = nil
local function majPV(instantane: boolean?)
	local pvMax = math.max(dossier:GetAttribute("PVMax") or 1, 1)
	local pv = math.clamp(dossier:GetAttribute("PV") or pvMax, 0, pvMax)
	local r = pv / pvMax
	pvTexte.Text = UI.milliers(pv) .. " / " .. UI.milliers(pvMax)
	local taille = UDim2.fromScale(r, 1)
	if instantane then
		plein.Size, trainee.Size = taille, taille
	else
		TweenService:Create(plein, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = taille}):Play()
		TweenService:Create(trainee, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0.35), {Size = taille}):Play()
		if pvAffiche - pv > pvMax * 0.03 and barre.Visible then
			UI.secouer(barre, 6)
		end
	end
	pvAffiche = pv
	local critique = r < 0.35 and r > 0
	if critique and not pouls then
		lisere.Color = Color3.fromRGB(255, 70, 60)
		pouls = TweenService:Create(lisere, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.9, Thickness = 3})
		pouls:Play()
	elseif not critique and pouls then
		pouls:Cancel()
		pouls = nil
		lisere.Color, lisere.Transparency, lisere.Thickness = Color3.fromRGB(10, 4, 4), 0.2, 2
	end
end

local function majIdentite()
	local couleur = dossier:GetAttribute("Couleur") or T.Rouge
	nomBoss.Text = string.upper(dossier:GetAttribute("Nom") or "Boss")
	titreBoss.Text = dossier:GetAttribute("Titre") or ""
	nomBoss.TextColor3 = couleur:Lerp(Color3.new(1, 1, 1), 0.45)
end

local function visibilite()
	local voir = joueur:GetAttribute("DansArene") == true and dossier:GetAttribute("Etat") == "Combat" and not etat.cinematique
	if voir == barre.Visible then return end
	if voir then
		majIdentite()
		placer()
		majPV(true)
		barre.Visible = true
		local base = barre.Position
		barre.Position = base - UDim2.fromOffset(0, 140)
		TweenService:Create(barre, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = base}):Play()
		UI.pop(barre, 0.8)
	else
		barre.Visible = false
	end
end

dossier:GetAttributeChangedSignal("PV"):Connect(function() majPV() end)
dossier:GetAttributeChangedSignal("PVMax"):Connect(function() majPV(true) end)
dossier:GetAttributeChangedSignal("Nom"):Connect(majIdentite)
dossier:GetAttributeChangedSignal("Etat"):Connect(visibilite)
joueur:GetAttributeChangedSignal("DansArene"):Connect(visibilite)
visibilite()

task.spawn(function()
	while true do
		if barre.Visible then
			local reste = (dossier:GetAttribute("FinCombat") or 0) - workspace:GetServerTimeNow()
			tempsTexte.Text = "Temps restant " .. Config.minutes(reste)
			tempsTexte.TextColor3 = if reste < 30 then T.Rouge else T.Gris
		end
		task.wait(0.25)
	end
end)

-- ================= Bandeau d'annonce =================
local bandeau = creer("Frame", {Name = "Annonce", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromScale(0.5, 0.07), BackgroundColor3 = T.BoisSombre, BackgroundTransparency = 0.1, Visible = false, Parent = gui},
	{coin(0.3), trait(T.Or, 2.5, 0.2), creer("UISizeConstraint", {MinSize = Vector2.new(300, 44), MaxSize = Vector2.new(900, 80)})})
local bandeauTexte = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.04, 0.12), Size = UDim2.fromScale(0.92, 0.76),
	Parent = bandeau}, 30)
creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 10, 6), Parent = bandeauTexte})
local numeroAnnonce = 0

local function annoncer(txt: string, couleur: Color3?)
	numeroAnnonce += 1
	local n = numeroAnnonce
	bandeauTexte.Text = txt
	bandeauTexte.TextColor3 = (couleur or T.Parchemin):Lerp(Color3.new(1, 1, 1), 0.3)
	bandeau.Visible = true
	bandeau.BackgroundTransparency, bandeauTexte.TextTransparency = 0.1, 0
	UI.pop(bandeau, 0.7)
	UI.jouer("ouvrir")
	task.delay(5, function()
		if numeroAnnonce ~= n then return end
		TweenService:Create(bandeau, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TweenService:Create(bandeauTexte, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.delay(0.55, function()
			if numeroAnnonce == n then bandeau.Visible = false end
		end)
	end)
end

-- ================= Modules =================
local Attente = require(script.Parent:WaitForChild("BossAttente"))
local Cinematique = require(script.Parent:WaitForChild("BossCinematique"))
local Combat = require(script.Parent:WaitForChild("BossCombat"))
local Resultats = require(script.Parent:WaitForChild("BossResultats"))

local ctx = {gui = gui, cinema = cinema, dossier = dossier, evenement = evenement, action = action, Config = Config, joueur = joueur, etat = etat}
local attente, combat, resultats
ctx.majVisibilite = function()
	visibilite()
	if attente then attente.maj() end
	if combat then combat.maj() end
end
attente = Attente.init(ctx)
combat = Combat.init(ctx)
resultats = Resultats.init(ctx)
ctx.puceRetour = attente.puceRetour
ctx.fermerResultats = resultats.fermer
local cinematique = Cinematique.init(ctx)
-- Annonce unique du prochain boss en haut d'écran, avec « Rejoindre le portail » / « Ignorer »
require(script.Parent:WaitForChild("BossAnnonce")).init(ctx)

evenement.OnClientEvent:Connect(function(type_, donnees, extra)
	if type_ == "Annonce" and type(donnees) == "string" then
		-- l'annonce du boss est la carte en haut d'écran (BossAnnonce) : plus de bandeau central en doublon
		local _ = extra
	elseif type(donnees) == "table" and type_ == "Depart" then
		attente.masquerFile()
		cinematique.depart(donnees)
	elseif type(donnees) == "table" and type_ == "Intro" then
		cinematique.intro(donnees)
	elseif type_ == "Arrivee" then
		cinematique.arrivee()
	elseif type_ == "Annule" then
		cinematique.annule()
	elseif type_ == "Phase" then
		combat.phase(donnees)
	elseif type_ == "Impact" and typeof(donnees) == "Vector3" then
		combat.impact(donnees, tonumber(extra) or 8)
	elseif type_ == "KO" then
		combat.ko(donnees)
	elseif type_ == "Fin" then
		resultats.fin(donnees)
	elseif type_ == "Resultats" then
		resultats.afficher(donnees)
	elseif type_ == "Retour" then
		cinematique.retour()
	end
end)
