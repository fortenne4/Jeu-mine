--!strict
-- Bandeau des couches de minage de la mine privée · SCRIPT CLIENT.
-- En haut de l'écran, dès que le joueur est dans sa mine privée (attribut joueur « CoucheMine », tenu par
-- RemonterMine.server) : « COUCHE 4 · BASALTE · −142 m », une barre de profondeur découpée en couches (repère
-- du joueur) et les minerais de la couche (silhouette « ? » tant qu'il n'en a jamais miné : attribut
-- « MineraisDecouverts »). Grande annonce « Nouvelle couche ! » quand il descend dans une couche plus profonde.
-- « Pioche trop faible » quand le serveur refuse de creuser une couche (RemoteEvent « AvisMine »).
-- Couches, couleurs et pioche requise : Partage › CouchesMine.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local CouchesMine = require(Partage:WaitForChild("CouchesMine"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local Forge = require(Partage:WaitForChild("Forge"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local joueur = Players.LocalPlayer
local OMBRE = Color3.fromRGB(16, 8, 4)
local LISTE = CouchesMine.LISTE
local MAX = CouchesMine.PROFONDEUR_MAX
local HORS_ECRAN = UDim2.new(0.5, 0, 0, -140)
local EN_PLACE = UDim2.new(0.5, 0, 0, 8)

local gui = creer("ScreenGui", {Name = "CoucheMine", ResetOnSpawn = false, DisplayOrder = 6,
	Parent = joueur:WaitForChild("PlayerGui")})

-- ===== Bandeau =====
local bandeau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = HORS_ECRAN, Size = UDim2.fromOffset(440, 96),
	BackgroundColor3 = T.Bois, Visible = false, Parent = gui},
	{coin(0.16), trait(OMBRE, 3), UI.degrade(T.CarteClaire, T.BoisSombre, 90)})
local lisere = bandeau:FindFirstChildOfClass("UIStroke") :: UIStroke -- contour, teinté selon la couche

-- pastille « COUCHE n » à la couleur de la roche
local pastille = creer("Frame", {Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(92, 40), BackgroundColor3 = LISTE[1].couleur,
	Parent = bandeau}, {coin(0.3), trait(OMBRE, 2)})
local pastilleHaut = texte({Text = "COUCHE", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0, 0.06),
	Size = UDim2.fromScale(1, 0.36), Parent = pastille}, 12)
creer("UIStroke", {Thickness = 1.5, Color = OMBRE, Parent = pastilleHaut})
local numero = texte({Text = "1", Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0, 0.36), Size = UDim2.fromScale(1, 0.62),
	Parent = pastille}, 24)
UI.dore(numero, 2)

local nom = texte({Text = "TERRE BATTUE", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(112, 6), Size = UDim2.fromOffset(210, 28), Parent = bandeau}, 26)
UI.dore(nom, 2)
local sousTitre = texte({Text = "", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(113, 33), Size = UDim2.fromOffset(210, 16), Parent = bandeau}, 13)
creer("UIStroke", {Thickness = 1.2, Color = OMBRE, Parent = sousTitre})
local profondeurTexte = texte({Text = "0 m", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin,
	TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(322, 8), Size = UDim2.fromOffset(108, 30), Parent = bandeau}, 24)
creer("UIStroke", {Thickness = 2, Color = OMBRE, Parent = profondeurTexte})

-- barre de profondeur : un segment par couche, repère du joueur
local barre = creer("Frame", {Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 10), BackgroundColor3 = T.Fond3D,
	Parent = bandeau}, {coin(0.5), trait(OMBRE, 1.5)})
local DEBUT = LISTE[1].debut
local function fraction(m: number): number
	return math.clamp((m - DEBUT) / (MAX - DEBUT), 0, 1)
end
local segments: {Frame} = {}
for i, c in LISTE do
	local a, b = fraction(math.max(c.debut, DEBUT)), fraction(math.min(c.fin, MAX))
	segments[i] = creer("Frame", {Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1), BackgroundColor3 = c.couleur,
		BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = barre})
end
local repere = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(6, 18),
	BackgroundColor3 = T.Or, ZIndex = 3, Parent = barre}, {coin(0.5), trait(OMBRE, 1.5)})

-- minerais de la couche
local rangee = creer("Frame", {Position = UDim2.fromOffset(10, 70), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1,
	Parent = bandeau}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})

-- ===== Annonce « Nouvelle couche ! » =====
local annonce = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(560, 110),
	BackgroundTransparency = 1, Visible = false, Parent = gui})
local annonceHaut = texte({Text = "NOUVELLE COUCHE !", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Size = UDim2.fromScale(1, 0.32),
	Parent = annonce}, 26)
creer("UIStroke", {Thickness = 2.5, Color = OMBRE, Parent = annonceHaut})
local annonceNom = texte({Text = "", Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0, 0.3), Size = UDim2.fromScale(1, 0.7),
	Parent = annonce}, 64)
UI.dore(annonceNom, 3)
local echelleAnnonce = creer("UIScale", {Scale = 1, Parent = annonce})

-- ===== Avertissement « Pioche trop faible » =====
local avis = texte({Text = "", Font = Enum.Font.GothamBlack, TextColor3 = T.Rouge, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 110), Size = UDim2.fromOffset(520, 26), Visible = false, Parent = gui}, 20)
creer("UIStroke", {Thickness = 2, Color = OMBRE, Parent = avis})

-- ================= Logique =================
local function decouverts(): {[string]: boolean}
	local s = joueur:GetAttribute("MineraisDecouverts")
	local vus = {}
	if type(s) == "string" then
		for id in s:gmatch("[^,]+") do
			vus[id] = true
		end
	end
	return vus
end

local function nomMinerai(id: string): string
	local m = Forge.MINERAIS[id]
	return if m then m.nom else id
end

-- Pioche la moins chère assez puissante pour cette couche (nil si toutes conviennent)
local function piocheRequise(c: number): any
	local besoin = LISTE[c].puissance
	if besoin <= 1 then
		return nil
	end
	for _, p in Pioches.LISTE do
		if p.puissance >= besoin then
			return p
		end
	end
	return nil
end

local coucheAffichee = 0
local function remplirMinerais(c: number)
	for _, o in rangee:GetChildren() do
		if o:IsA("GuiObject") then
			o:Destroy()
		end
	end
	local vus = decouverts()
	-- du plus fréquent au plus rare
	local liste = table.clone(LISTE[c].minerais)
	table.sort(liste, function(a, b)
		return a[2] > b[2]
	end)
	for i, e in liste do
		local id = e[1] :: string
		local connu = vus[id] == true
		local case = creer("Frame", {LayoutOrder = i, Size = UDim2.fromOffset(if connu then 96 else 44, 22), BackgroundColor3 = T.Fond3D,
			BackgroundTransparency = 0.25, Parent = rangee}, {coin(0.5), trait(OMBRE, 1)})
		local rond = creer("Frame", {Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Parent = case})
		Icones.minerai(id, rond, {silhouette = not connu, vitesse = 0.4, hauteur = 0.35, marge = 0.85})
		texte({Text = if connu then nomMinerai(id) else "?", Font = Enum.Font.GothamBold, TextColor3 = if connu then T.Parchemin else T.Gris,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(25, 2), Size = UDim2.new(1, -28, 1, -4), Parent = case}, 13)
	end
end

local function remplirCouche(c: number)
	local couche = LISTE[c]
	coucheAffichee = c
	numero.Text = tostring(c)
	nom.Text = string.upper(couche.nom)
	pastille.BackgroundColor3 = couche.couleur
	lisere.Color = couche.couleur:Lerp(T.Or, 0.5)
	local p = piocheRequise(c)
	sousTitre.Text = string.format("%d – %d m", math.max(0, couche.debut), math.min(couche.fin, MAX))
		.. (if p then " · pioche : " .. p.nom else "")
	for i, s in segments do
		s.BackgroundTransparency = if i == c then 0 else 0.45
	end
	remplirMinerais(c)
end

local visible = false
local function montrer(oui: boolean)
	if oui == visible then
		return
	end
	visible = oui
	if oui then
		bandeau.Visible = true
		bandeau.Position = HORS_ECRAN
		TweenService:Create(bandeau, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = EN_PLACE}):Play()
	else
		local t = TweenService:Create(bandeau, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = HORS_ECRAN})
		t.Completed:Once(function()
			if not visible then
				bandeau.Visible = false
			end
		end)
		t:Play()
	end
end

local jetonAnnonce = 0
local function annoncer(c: number)
	jetonAnnonce += 1
	local jeton = jetonAnnonce
	local couche = LISTE[c]
	annonceNom.Text = string.upper(couche.nom)
	annonceHaut.Text = string.format("NOUVELLE COUCHE ! · %d", c)
	annonceHaut.TextColor3 = couche.couleur:Lerp(Color3.new(1, 1, 1), 0.55)
	annonce.Visible = true
	echelleAnnonce.Scale = 0.6
	TweenService:Create(echelleAnnonce, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	UI.jouer("succes")
	task.delay(2.6, function()
		if jeton == jetonAnnonce then
			annonce.Visible = false
		end
	end)
end

local plusProfonde = 0 -- couche la plus profonde atteinte pendant cette visite
local function maj()
	local c = joueur:GetAttribute("CoucheMine")
	if type(c) ~= "number" or not LISTE[c] then
		montrer(false)
		plusProfonde = 0
		return
	end
	if c ~= coucheAffichee then
		remplirCouche(c)
	end
	if plusProfonde > 0 and c > plusProfonde then
		annoncer(c)
	end
	plusProfonde = math.max(plusProfonde, c)
	local m = joueur:GetAttribute("ProfondeurMine")
	local metres = if type(m) == "number" then m else 0
	profondeurTexte.Text = string.format("−%d m", metres)
	TweenService:Create(repere, TweenInfo.new(0.3), {Position = UDim2.fromScale(fraction(metres), 0.5)}):Play()
	montrer(true)
end
joueur:GetAttributeChangedSignal("CoucheMine"):Connect(maj)
joueur:GetAttributeChangedSignal("ProfondeurMine"):Connect(maj)
joueur:GetAttributeChangedSignal("MineraisDecouverts"):Connect(function()
	if coucheAffichee > 0 then
		remplirMinerais(coucheAffichee)
	end
end)
maj()

-- Avertissement du serveur : la roche de cette couche est trop dure pour la pioche
local jetonAvis = 0
local avisMine = ReplicatedStorage:WaitForChild("AvisMine") :: RemoteEvent
avisMine.OnClientEvent:Connect(function(genre: any, c: any)
	if genre ~= "pioche" or type(c) ~= "number" or not LISTE[c] then
		return
	end
	local p = piocheRequise(c)
	avis.Text = string.format("Pioche trop faible pour la couche %s", LISTE[c].nom)
		.. (if p then " : il faut la " .. p.nom else "")
	avis.Visible = true
	UI.secouer(avis, 6)
	jetonAvis += 1
	local jeton = jetonAvis
	task.delay(2.2, function()
		if jeton == jetonAvis then
			avis.Visible = false
		end
	end)
end)
