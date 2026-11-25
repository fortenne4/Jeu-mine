-- Grottes profondes · SCRIPT CLIENT, écran de chargement à l'entrée d'une grotte.
-- Le serveur (Grottes.server.lua) pose l'attribut joueur « GrotteDepart » = id du palier juste avant de téléporter
-- le joueur, et l'efface quand il quitte la grotte. L'écran apparaît aussitôt et reste tant que la grotte n'est pas
-- prête chez ce client : arrivée dans la boîte de la grotte, streaming et sol autour de l'arrivée, modèle de la
-- grotte stable, textures et particules préchargées (ContentProvider), ambiance souterraine appliquée
-- (attribut « GrotteActive » de Lighting, posé par AmbianceGrotte.client.lua). Entre 1,5 s et 20 s.
-- Visuel : un fond d'écran dessiné par palier (ChargementGrotteThemes.lua) et une veine de roche que la pioche
-- mine en rythme : la barre se creuse derrière elle à chaque coup (éclats, étincelles, son).
-- Pendant le chargement : contrôles coupés (BossOutils.controles) et personnage ancré localement.
-- Rien n'est reconstruit à chaque image : l'écran est construit une fois, chaque décor au premier passage.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local Themes = require(script.Parent:WaitForChild("ChargementGrotteThemes"))
local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))

local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T
local K = Themes.kit
local rgb = K.rgb

local joueur = Players.LocalPlayer
local ATTRIBUT = "GrotteDepart"
local DUREE_MIN, DUREE_MAX = 1.5, 20
local RATIO_BARRE = 16      -- largeur / hauteur de la barre
local INSET = 0.012         -- épaisseur du cadre de fer aux deux bouts, en largeurs de barre
local TAILLE_PIOCHE = 3.4   -- côté du dessin de la pioche, en hauteurs de barre
local ANGLE_REPOS, ANGLE_ARME, ANGLE_FRAPPE = 8, 34, -100
local POINTE = Vector2.new(0.045 - 0.5, 0.25 - 0.5) -- pointe du pic dans le dessin, depuis le pivot (centre)
local SON_COUP = "rbxassetid://9125361455" -- marteau des nains (AnimationsNains), déjà utilisé dans le jeu
local BLANC, NOIR = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local CENTRE = Vector2.new(0.5, 0.5)
local YY = Enum.SizeConstraint.RelativeYY

local function tourner(v: Vector2, deg: number): Vector2
	local a = math.rad(deg)
	local c, s = math.cos(a), math.sin(a)
	return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
end
-- pivot de la pioche par rapport au point d'impact (en hauteurs de barre), pour que la pointe frappe la veine
local DECALAGE = tourner(POINTE, ANGLE_FRAPPE) * TAILLE_PIOCHE

local function tween(o: Instance, duree: number, props: {[string]: any}, style: Enum.EasingStyle?, sens: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(duree, style or Enum.EasingStyle.Quad, sens or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- ================= Écran =================
local gui = creer("ScreenGui", {Name = "ChargementGrotte", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 95, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.None, Parent = joueur:WaitForChild("PlayerGui")})
local ecran = creer("Frame", {Name = "Ecran", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = gui})
local fondDecors = creer("Frame", {Name = "Decors", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = ecran})

-- vignettage (lisibilité du titre en haut, de la barre et de l'astuce en bas)
for _, v in {{0, 0, 1, 0.32, 90, {{0, 0.1}, {1, 1}}}, {0, 0.6, 1, 0.4, 90, {{0, 1}, {0.55, 0.35}, {1, 0.05}}},
	{0, 0, 0.2, 1, 0, {{0, 0.25}, {1, 1}}}, {0.8, 0, 0.2, 1, 0, {{0, 1}, {1, 0.25}}}} do
	creer("Frame", {Position = UDim2.fromScale(v[1], v[2]), Size = UDim2.fromScale(v[3], v[4]), BackgroundColor3 = NOIR, BorderSizePixel = 0, ZIndex = 10,
		Parent = ecran}, {creer("UIGradient", {Rotation = v[5], Transparency = K.transp(v[6])})})
end

-- titre
local legende = texte({Name = "Legende", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.085), Size = UDim2.fromScale(0.7, 0.032),
	Font = Enum.Font.GothamBlack, ZIndex = 20, Parent = ecran}, 22)
local titre = texte({Name = "Titre", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.86, 0.085),
	Font = Enum.Font.Fantasy, TextColor3 = BLANC, ZIndex = 20, Parent = ecran}, 72)
local titreDegrade = creer("UIGradient", {Rotation = 90, Parent = titre})
creer("UIStroke", {Thickness = 3, Color = rgb(14, 8, 6), Parent = titre})
local titreEchelle = creer("UIScale", {Parent = titre})
local ornement = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.208), Size = UDim2.fromScale(0.34, 0.012), BackgroundTransparency = 1,
	ZIndex = 20, Parent = ecran})
local ornementTraits = {}
for _, cote in {0, 1} do
	table.insert(ornementTraits, creer("Frame", {AnchorPoint = Vector2.new(cote, 0.5), Position = UDim2.fromScale(cote, 0.5), Size = UDim2.new(0.46, 0, 0, 2),
		BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 20, Parent = ornement},
		{creer("UIGradient", {Rotation = if cote == 0 then 0 else 180, Transparency = K.transp({{0, 1}, {1, 0}})})}))
end
local losange = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), SizeConstraint = YY,
	Rotation = 45, BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 21, Parent = ornement}, {trait(rgb(14, 8, 6), 1.5)})

-- astuce
local astuce = texte({Name = "Astuce", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.955), Size = UDim2.fromScale(0.74, 0.034),
	Font = Enum.Font.Merriweather, RichText = true, ZIndex = 20, Parent = ecran}, 22)

-- ================= Barre : la veine que la pioche mine =================
local barre = creer("Frame", {Name = "Barre", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.56, 0.1),
	BackgroundTransparency = 1, ZIndex = 30, Parent = ecran},
	{creer("UIAspectRatioConstraint", {AspectRatio = RATIO_BARRE, DominantAxis = Enum.DominantAxis.Width}),
		creer("UISizeConstraint", {MaxSize = Vector2.new(880, math.huge)})})
local barreBase = barre.Position
creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.new(0.5, 0, 0.5, 5), Size = UDim2.fromScale(1.01, 1.1), BackgroundColor3 = NOIR,
	BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 1, Parent = barre}, {coin(0.4)})
local cadre = creer("Frame", {Name = "Cadre", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC,
	BorderSizePixel = 0, ZIndex = 2, Parent = barre}, {coin(0.32), trait(T.FerSombre, 2),
	creer("UIGradient", {Rotation = 90, Color = K.seq({{0, rgb(196, 196, 204)}, {0.45, rgb(112, 112, 120)}, {1, rgb(50, 50, 56)}})})})
for i = 1, 9 do
	for _, y in {0.1, 0.9} do
		UI.rivet(cadre, UDim2.fromScale((i - 0.5) / 9, y), 0.13)
	end
end
local interieur = creer("Frame", {Name = "Veine", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1 - 2 * INSET, 0.62),
	BackgroundColor3 = BLANC, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = cadre}, {coin(0.3), trait(T.FerSombre, 1.5)})
K.ratio(interieur, RATIO_BARRE * (1 - 2 * INSET) / 0.62)
local rocheDegrade = creer("UIGradient", {Rotation = 90, Parent = interieur})
-- minerais incrustés et fissures (positions fixes, couleurs du thème)
local rngVeine = Random.new(42)
local mineraisVeine = {}
for i = 1, 26 do
	local d = rngVeine:NextNumber(0.12, 0.26)
	table.insert(mineraisVeine, K.bloc(interieur, (i - 0.5) / 26 + rngVeine:NextNumber(-0.01, 0.01), rngVeine:NextNumber(0.2, 0.8), d, d, BLANC,
		{SizeConstraint = YY, Rotation = rngVeine:NextInteger(0, 1) * 45, BackgroundTransparency = rngVeine:NextNumber(0.05, 0.35), ZIndex = 1}))
end
local fissures = {}
for i = 1, 10 do
	local x0 = (i - 0.5) / 10 + rngVeine:NextNumber(-0.03, 0.03)
	table.insert(fissures, K.seg(interieur, x0, rngVeine:NextNumber(0, 0.3), x0 + rngVeine:NextNumber(-0.02, 0.02), rngVeine:NextNumber(0.6, 1), 0.05, NOIR, 0.55, 1))
end
-- tunnel creusé derrière la pioche
local creuse = creer("Frame", {Name = "Creuse", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = BLANC, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = interieur})
local creuseDegrade = creer("UIGradient", {Rotation = 90, Parent = creuse})
creer("Frame", {Size = UDim2.fromScale(1, 0.22), BackgroundColor3 = NOIR, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 2, Parent = creuse})
local filon = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.62), Size = UDim2.fromScale(1, 0.09), BackgroundColor3 = BLANC,
	BorderSizePixel = 0, ZIndex = 2, Parent = creuse}, {creer("UIGradient", {Rotation = 0, Transparency = K.transp({{0, 0.9}, {0.8, 0.45}, {1, 0.1}})})})
local braise = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(3, 1), SizeConstraint = YY,
	BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 2, Parent = creuse}, {creer("UIGradient", {Rotation = 0, Transparency = K.transp({{0, 1}, {1, 0.35}})})})
-- front de taille : gravats au bord de la roche
local front = creer("Frame", {Name = "Front", AnchorPoint = CENTRE, Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 1), SizeConstraint = YY,
	BackgroundTransparency = 1, ZIndex = 4, Parent = interieur})
local frontEchelle = creer("UIScale", {Parent = front})
local gravats = {}
for i, g in {{0.55, 0.15, 0.34, 20}, {0.62, 0.45, 0.4, 50}, {0.52, 0.78, 0.32, 10}, {0.7, 0.25, 0.22, 35}, {0.68, 0.7, 0.26, 70}} do
	gravats[i] = K.bloc(front, g[1], g[2], g[3], g[3], BLANC, {SizeConstraint = YY, Rotation = g[4]}, {trait(NOIR, 1, 0.5)})
end
-- éclair d'impact (hors veine : non rogné)
local eclair = creer("Frame", {AnchorPoint = CENTRE, Size = UDim2.fromScale(1.6, 1.6), SizeConstraint = YY, BackgroundColor3 = BLANC, BackgroundTransparency = 1,
	BorderSizePixel = 0, ZIndex = 32, Parent = barre}, {coin(0.5)})
local eclairEchelle = creer("UIScale", {Parent = eclair})

-- pioche dessinée dans un CanvasGroup : le groupe entier pivote autour de son centre (= les mains)
local pioche = creer("CanvasGroup", {Name = "Pioche", AnchorPoint = CENTRE, Size = UDim2.fromScale(TAILLE_PIOCHE / RATIO_BARRE, TAILLE_PIOCHE),
	BackgroundTransparency = 1, Rotation = ANGLE_REPOS, ZIndex = 33, Parent = barre})
K.ratio(pioche, 1)
local piocheFer, piocheBois, piocheAccent = {}, {}, {}
do
	-- manche en bois : dégradé en travers, veinures, nœud, arête éclairée
	local m = K.seg(pioche, 0.5, 0.64, 0.5, 0.13, 0.07, BLANC)
	table.insert(piocheBois, m)
	trait(rgb(30, 18, 10), 1.5).Parent = m
	creer("UIGradient", {Rotation = 90, Color = K.seq({{0, rgb(255, 255, 255)}, {0.25, rgb(225, 225, 225)}, {0.65, rgb(170, 170, 170)}, {1, rgb(95, 95, 95)}}), Parent = m})
	for _, v in {{-0.018, 0.2, 0.45}, {0.004, 0.16, 0.58}, {0.02, 0.28, 0.5}, {-0.006, 0.36, 0.62}} do
		local ax, ay, bx, by = K.decaler(pioche, 0.5, v[2], 0.5, v[3], v[1])
		K.seg(pioche, ax, ay, bx, by, 0.006, rgb(40, 24, 14), 0.45)
	end
	local nx, ny, nx2, ny2 = K.decaler(pioche, 0.5, 0.3, 0.5, 0.34, 0.008)
	K.seg(pioche, nx, ny, nx2, ny2, 0.03, rgb(50, 30, 18), 0.2)
	K.disque(pioche, (nx + nx2) / 2, (ny + ny2) / 2, 0.014, rgb(28, 16, 10), 0.1)
	local ax, ay, bx, by = K.decaler(pioche, 0.5, 0.2, 0.5, 0.6, 0.022)
	K.seg(pioche, ax, ay, bx, by, 0.008, rgb(255, 235, 200), 0.6)
	-- poignée en cuir : bande sombre et lanières en biais
	K.seg(pioche, 0.5, 0.44, 0.5, 0.61, 0.082, rgb(54, 32, 20))
	for k = 0, 5 do
		local y = 0.45 + k * 0.027
		K.seg(pioche, 0.462, y, 0.538, y + 0.022, 0.012, rgb(110, 72, 44))
		K.seg(pioche, 0.462, y + 0.004, 0.538, y + 0.026, 0.004, rgb(26, 14, 8), 0.3)
	end
	-- pommeau de fer
	local pommeau = K.disque(pioche, 0.5, 0.645, 0.085, BLANC)
	trait(rgb(24, 24, 28), 1.5).Parent = pommeau
	table.insert(piocheFer, pommeau)
	-- tête métallique : bras effilés, pic et lame
	for _, s in {{0.5, 0.14, 0.27, 0.155, 0.085}, {0.27, 0.155, 0.1, 0.215, 0.06}, {0.1, 0.215, 0.045, 0.25, 0.032},
		{0.5, 0.14, 0.72, 0.15, 0.085}, {0.72, 0.15, 0.87, 0.19, 0.068}} do
		local f = K.seg(pioche, s[1], s[2], s[3], s[4], s[5], BLANC)
		trait(rgb(24, 24, 28), 1.5).Parent = f
		table.insert(piocheFer, f)
	end
	local lame = K.bloc(pioche, 0.885, 0.2, 0.035, 0.1, BLANC, {Rotation = 20}, {trait(rgb(24, 24, 28), 1.5)})
	table.insert(piocheFer, lame)
	-- reflets (arête haute) et ombres (arête basse) le long de la tête
	for _, s in {{0.5, 0.14, 0.27, 0.155, 0.085}, {0.27, 0.155, 0.1, 0.215, 0.06}, {0.5, 0.14, 0.72, 0.15, 0.085}, {0.72, 0.15, 0.87, 0.19, 0.068}} do
		local x1, y1, x2, y2 = K.decaler(pioche, s[1], s[2], s[3], s[4], -s[5] * 0.28)
		K.seg(pioche, x1, y1, x2, y2, s[5] * 0.14, BLANC, 0.45)
		local x3, y3, x4, y4 = K.decaler(pioche, s[1], s[2], s[3], s[4], s[5] * 0.3)
		K.seg(pioche, x3, y3, x4, y4, s[5] * 0.12, rgb(10, 10, 14), 0.55)
	end
	-- douille, ligature de corde, rivet
	local douille = K.bloc(pioche, 0.5, 0.15, 0.13, 0.12, BLANC, nil, {coin(0.2), trait(rgb(24, 24, 28), 1.5)})
	table.insert(piocheFer, douille)
	table.insert(piocheAccent, K.bloc(pioche, 0.5, 0.15, 0.135, 0.035, BLANC))
	for k = 0, 3 do
		local y = 0.215 + k * 0.016
		local c = K.seg(pioche, 0.458, y, 0.542, y + 0.006, 0.014, rgb(196, 168, 118))
		trait(rgb(70, 52, 30), 1).Parent = c
	end
	K.seg(pioche, 0.46, 0.212, 0.54, 0.268, 0.007, rgb(150, 124, 82))
	K.seg(pioche, 0.54, 0.212, 0.46, 0.268, 0.007, rgb(150, 124, 82))
	local rivet = K.disque(pioche, 0.5, 0.15, 0.03, rgb(225, 225, 232))
	trait(rgb(24, 24, 28), 1).Parent = rivet
	creer("UIGradient", {Rotation = 45, Color = K.seq({{0, rgb(255, 255, 255)}, {1, rgb(90, 90, 96)}}), Parent = rivet})
	for _, f in piocheFer do
		creer("UIGradient", {Rotation = 90, Color = K.seq({{0, rgb(255, 255, 255)}, {0.2, rgb(235, 235, 240)}, {0.45, rgb(185, 185, 190)},
			{0.55, rgb(120, 120, 126)}, {0.8, rgb(150, 150, 156)}, {1, rgb(80, 80, 86)}}), Parent = f})
	end
	-- éclat de lumière sur la pointe du pic
	K.disque(pioche, 0.058, 0.243, 0.022, BLANC, 0.15)
	K.seg(pioche, 0.035, 0.243, 0.081, 0.243, 0.004, BLANC, 0.3)
	K.seg(pioche, 0.058, 0.228, 0.058, 0.258, 0.004, BLANC, 0.3)
end

-- éclats et étincelles recyclés
local eclats, etincelles = {}, {}
for _ = 1, 18 do
	table.insert(eclats, creer("Frame", {AnchorPoint = CENTRE, Size = UDim2.fromScale(0.16, 0.16), SizeConstraint = YY, BackgroundColor3 = BLANC,
		BorderSizePixel = 0, Visible = false, ZIndex = 31, Parent = barre}, {trait(NOIR, 1, 0.4)}))
end
for _ = 1, 14 do
	table.insert(etincelles, creer("Frame", {AnchorPoint = CENTRE, Size = UDim2.fromScale(0.36, 0.06), SizeConstraint = YY, BackgroundColor3 = BLANC,
		BorderSizePixel = 0, Visible = false, ZIndex = 32, Parent = barre}, {coin(0.5)}))
end
local iEclat, iEtincelle = 0, 0

-- étape et pourcentage sous la barre
local etiquette = texte({Name = "Etape", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(INSET, 1.42), Size = UDim2.fromScale(0.66, 0.55),
	Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 30, Parent = barre}, 20)
local pourcent = texte({Name = "Pourcent", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1 - INSET, 1.42), Size = UDim2.fromScale(0.2, 0.6),
	Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 30, Parent = barre}, 24)
creer("UIStroke", {Thickness = 1.5, Color = NOIR, Transparency = 0.3, Parent = pourcent})

-- voile noir (fondus d'entrée et de sortie)
local voile = creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BackgroundTransparency = 1, BorderSizePixel = 0,
	ZIndex = 100, Parent = gui})

local sonCoup = creer("Sound", {Name = "ChargementGrotte_Coup", SoundId = SON_COUP, Volume = 0.22, Parent = SoundService})

-- ================= Décors (un par palier, construits au premier passage) =================
local decors = {}
local function decorDe(id: number)
	if decors[id] then return decors[id] end
	local th = Themes.get(id)
	local cl = th.couleurs
	local cadreDecor = creer("Frame", {Name = "Decor" .. id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 1, Parent = fondDecors})
	local fond = creer("Frame", {Name = "Fond", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 1, Parent = cadreDecor},
		{creer("UIGradient", {Rotation = 90, Color = K.seq({{0, cl.fondHaut}, {0.55, cl.fondMilieu}, {1, cl.fondBas}})})})
	local function couche(nom: string, z: number): Frame
		return creer("Frame", {Name = nom, AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.08, 1.08),
			BackgroundTransparency = 1, ZIndex = z, Parent = cadreDecor})
	end
	local c = {fond = fond, loin = couche("Loin", 2), milieu = couche("Milieu", 3), particules = couche("Particules", 4), proche = couche("Proche", 5)}
	local rng = Random.new(id * 1013)
	local ok, animer = pcall(th.construire, c, rng)
	if not ok then
		warn("[ChargementGrotte] décor " .. id .. " incomplet : " .. tostring(animer))
		animer = function() end
	end
	local parts = {}
	for _, def in th.particules do
		for _ = 1, def.nombre do
			local coul = def.couleurs[rng:NextInteger(1, #def.couleurs)]
			local f = K.disque(c.particules, 0, 0, rng:NextNumber(def.taille[1], def.taille[2]), coul, def.transp)
			table.insert(parts, {f = f, x = rng:NextNumber(0, 1), y = rng:NextNumber(0, 1), v = rng:NextNumber(def.vitesse[1], def.vitesse[2]),
				sens = def.sens, amp = def.amplitude, freq = rng:NextNumber(0.4, 1.2), ph = rng:NextNumber(0, 6.28), transp = def.transp})
		end
	end
	decors[id] = {cadre = cadreDecor, couches = {c.loin, c.milieu, c.proche}, animer = animer, particules = parts}
	return decors[id]
end

-- ================= État =================
local valeur = Instance.new("NumberValue") -- progression affichée (avance à chaque coup de pioche)
local etat = {
	actif = false, visible = false, jeton = 0, t0 = 0, cible = 0, fin = false, pc = -1,
	pas = {a = 0, b = 0, frac = 0, debut = 0}, decor = nil, theme = nil, sx = 0, sy = 0,
	ancrage = nil, controles = false, connexion = nil,
}
local PROFONDEURS = {0.25, 0.55, 1}

local function appliquerTheme(th, niveau)
	local cl = th.couleurs
	titre.Text = th.titre
	titreDegrade.Color = K.seq({{0, cl.accent:Lerp(BLANC, 0.75)}, {0.5, cl.accent:Lerp(BLANC, 0.25)}, {1, cl.accent:Lerp(NOIR, 0.25)}})
	legende.TextColor3 = cl.accent:Lerp(BLANC, 0.3)
	legende.Text = string.format("PALIER %d   ·   −%d M   ·   %s", niveau and niveau.id or 1, niveau and niveau.profondeur or 50, niveau and niveau.nom or "")
	for _, f in ornementTraits do f.BackgroundColor3 = cl.accent end
	losange.BackgroundColor3 = cl.accent
	rocheDegrade.Color = K.seq({{0, cl.roche:Lerp(BLANC, 0.18)}, {0.5, cl.roche}, {1, cl.roche:Lerp(NOIR, 0.45)}})
	for _, m in mineraisVeine do m.BackgroundColor3 = cl.minerai end
	creuseDegrade.Color = K.seq({{0, cl.creuse:Lerp(NOIR, 0.5)}, {0.5, cl.creuse}, {1, cl.creuse:Lerp(NOIR, 0.6)}})
	filon.BackgroundColor3 = cl.accent
	braise.BackgroundColor3 = cl.accent
	for _, g in gravats do g.BackgroundColor3 = cl.eclat:Lerp(BLANC, 0.12) end
	eclair.BackgroundColor3 = cl.etincelle
	for _, f in piocheFer do f.BackgroundColor3 = cl.fer end
	for _, f in piocheBois do f.BackgroundColor3 = cl.bois end
	for _, f in piocheAccent do f.BackgroundColor3 = cl.accent end
	for _, e in eclats do e.BackgroundColor3 = cl.eclat end
	for _, e in etincelles do e.BackgroundColor3 = cl.etincelle end
	etiquette.TextColor3 = T.Parchemin
	pourcent.TextColor3 = cl.accent:Lerp(BLANC, 0.4)
end

local function changerAstuce(th)
	local a = th.astuces[math.random(1, #th.astuces)]
	astuce.Text = string.format('<font color="#%s"><b>ASTUCE</b></font>   <i>%s</i>', th.couleurs.accent:ToHex(), a)
end

local function definirPas(a: number, b: number, libelle: string)
	etat.pas = {a = a, b = b, frac = 0, debut = os.clock()}
	etiquette.Text = libelle
end

-- ================= Coups de pioche =================
local function lancerEclat(f: Frame, x: number, y: number, vx: number, vy: number, duree: number, transp: number)
	f.Position = UDim2.fromScale(x, y)
	f.BackgroundTransparency = transp
	f.Rotation = math.random(0, 90)
	f.Visible = true
	tween(f, duree * 0.42, {Position = UDim2.fromScale(x + vx * 0.5 / RATIO_BARRE, y + vy), Rotation = f.Rotation + 120})
	task.delay(duree * 0.42, function()
		if not etat.visible then
			f.Visible = false
			return
		end
		tween(f, duree * 0.58, {Position = UDim2.fromScale(x + vx / RATIO_BARRE, y + 0.9), Rotation = f.Rotation + 160, BackgroundTransparency = 1},
			Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end

local function lancerEtincelle(f: Frame, x: number, y: number)
	local a = math.rad(math.random(-170, -10))
	local d = 0.8 + math.random() * 1.4
	f.Position = UDim2.fromScale(x, y)
	f.Rotation = math.deg(a)
	f.BackgroundTransparency = 0
	f.Visible = true
	tween(f, 0.3, {Position = UDim2.fromScale(x + math.cos(a) * d / RATIO_BARRE, y + math.sin(a) * d), BackgroundTransparency = 1})
end

local function impact(fort: boolean?)
	local a = valeur.Value
	local reste = etat.cible - a
	if reste > 0.001 then
		local pasMin = if etat.fin then 0.14 else 0.022
		local nv = math.min(etat.cible, a + math.max(pasMin, reste * (if etat.fin then 0.75 else 0.5)))
		tween(valeur, 0.16, {Value = nv})
	end
	local x = INSET + a * (1 - 2 * INSET)
	sonCoup.PlaybackSpeed = 1.25 + math.random() * 0.25
	sonCoup.Volume = if fort then 0.4 else 0.22
	SoundService:PlayLocalSound(sonCoup)
	for _ = 1, if fort then 9 else 4 do
		iEclat = iEclat % #eclats + 1
		lancerEclat(eclats[iEclat], x + 0.006, 0.5, -(0.6 + math.random() * 1.6), -(0.9 + math.random() * 1.1), 0.55 + math.random() * 0.2, 0)
	end
	for _ = 1, if fort then 8 else 3 do
		iEtincelle = iEtincelle % #etincelles + 1
		lancerEtincelle(etincelles[iEtincelle], x + 0.004, 0.45)
	end
	eclair.Position = UDim2.fromScale(x, 0.5)
	eclair.BackgroundTransparency = 0.15
	eclairEchelle.Scale = 0.5
	tween(eclair, if fort then 0.5 else 0.25, {BackgroundTransparency = 1})
	tween(eclairEchelle, if fort then 0.5 else 0.25, {Scale = if fort then 3 else 1.4})
	frontEchelle.Scale = 1.25
	tween(frontEchelle, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
	barre.Position = barreBase + UDim2.fromOffset(0, if fort then 4 else 2)
	tween(barre, 0.14, {Position = barreBase})
end

local function frappes(jeton: number)
	while etat.jeton == jeton and etat.visible do
		local r = if etat.fin then 0.6 else 1
		tween(pioche, 0.24 * r, {Rotation = ANGLE_ARME})
		task.wait(0.26 * r)
		if etat.jeton ~= jeton or not etat.visible then break end
		tween(pioche, 0.085, {Rotation = ANGLE_FRAPPE}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.085)
		if etat.jeton ~= jeton or not etat.visible then break end
		impact(false)
		tween(pioche, 0.07, {Rotation = ANGLE_FRAPPE + 12})
		task.wait(0.07)
		tween(pioche, 0.2 * r, {Rotation = ANGLE_REPOS}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(0.25 * r)
	end
end

-- ================= Animation (une seule connexion, seulement pendant l'affichage) =================
local function image(dt: number)
	local maintenant = os.clock()
	local t = maintenant - etat.t0
	-- progression réelle lissée : l'étape en cours avance avec son vrai avancement, et un peu avec le temps
	local pas = etat.pas
	local derive = 0.55 * (1 - math.exp(-(maintenant - pas.debut) / 2.2))
	local c = pas.a + (pas.b - pas.a) * math.clamp(math.max(pas.frac, derive), 0, 1)
	if c > etat.cible then etat.cible = c end
	-- barre et pioche
	local a = valeur.Value
	local x = INSET + a * (1 - 2 * INSET)
	creuse.Size = UDim2.fromScale(a, 1)
	front.Position = UDim2.fromScale(a, 0.5)
	pioche.Position = UDim2.fromScale(x - DECALAGE.X / RATIO_BARRE, 0.5 - DECALAGE.Y)
	local pc = math.floor(a * 100 + 0.5)
	if pc ~= etat.pc then
		etat.pc = pc
		pourcent.Text = pc .. " %"
	end
	-- parallaxe (souris sur PC, lente dérive partout)
	local d = etat.decor
	if not d then return end
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize
	local mx, my = 0, 0
	if vs and vs.X > 0 and not UserInputService.TouchEnabled then
		local m = UserInputService:GetMouseLocation()
		mx, my = math.clamp(m.X / vs.X - 0.5, -0.5, 0.5), math.clamp(m.Y / vs.Y - 0.5, -0.5, 0.5)
	end
	local k = math.min(1, dt * 3)
	etat.sx += (mx - etat.sx) * k
	etat.sy += (my - etat.sy) * k
	for i, couche in d.couches do
		local p = PROFONDEURS[i]
		couche.Position = UDim2.fromScale(0.5 - etat.sx * 0.03 * p + math.sin(t * 0.13) * 0.006 * p, 0.5 - etat.sy * 0.02 * p + math.sin(t * 0.17) * 0.004 * p)
	end
	for _, q in d.particules do
		local y = ((q.y + q.sens * q.v * t) % 1.1) - 0.05
		q.f.Position = UDim2.fromScale(q.x + math.sin(t * q.freq + q.ph) * q.amp, y)
		q.f.BackgroundTransparency = math.min(0.95, q.transp + 0.3 * (0.5 + 0.5 * math.sin(t * q.freq * 3 + q.ph)))
	end
	d.animer(t)
end

-- ================= Personnage : contrôles coupés et ancrage local =================
local function personnage(): (Model?, BasePart?, Humanoid?)
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if racine and racine:IsA("BasePart") and hum and hum.Health > 0 then
		return perso, racine, hum
	end
	return nil, nil, nil
end

local function ancrer(racine: BasePart)
	if etat.ancrage then return end
	local a = {racine = racine, libre = not racine.Anchored}
	racine.Anchored = true
	-- le serveur libère le personnage au bout de 1,2 s : on le garde ancré chez soi jusqu'à la fin du chargement
	a.connexion = racine:GetPropertyChangedSignal("Anchored"):Connect(function()
		if not racine.Anchored and etat.visible then
			a.libre = true
			racine.Anchored = true
		end
	end)
	etat.ancrage = a
end

local function liberer()
	local a = etat.ancrage
	etat.ancrage = nil
	if a then
		a.connexion:Disconnect()
		if a.libre and a.racine.Parent then
			a.racine.Anchored = false
			a.racine.AssemblyLinearVelocity = Vector3.zero
		end
	end
	if etat.controles then
		etat.controles = false
		Outils.controles(true)
	end
end

-- ================= Afficher / cacher =================
local function montrer(id: number)
	local th = Themes.get(id)
	local niveau = Grottes.niveau(id)
	etat.jeton += 1
	local jeton = etat.jeton
	etat.theme = th
	etat.cible, etat.fin, etat.pc = 0, false, -1
	valeur.Value = 0
	pioche.Rotation = ANGLE_REPOS
	if not etat.controles then
		etat.controles = true
		Outils.controles(false)
	end
	gui.Enabled = true
	voile.BackgroundTransparency = 1
	tween(voile, 0.2, {BackgroundTransparency = 0})
	task.wait(0.2)
	if etat.jeton ~= jeton then return end
	local d = decorDe(id)
	for _, autre in decors do autre.cadre.Visible = autre == d end
	etat.decor = d
	appliquerTheme(th, niveau)
	changerAstuce(th)
	ecran.Visible = true
	etat.visible = true
	etat.t0 = os.clock()
	if etat.connexion then etat.connexion:Disconnect() end
	etat.connexion = RunService.Heartbeat:Connect(image)
	image(0)
	tween(voile, 0.45, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
	-- titre qui se pose
	titre.TextTransparency = 1
	titreEchelle.Scale = 0.9
	tween(titre, 0.7, {TextTransparency = 0}, Enum.EasingStyle.Sine)
	tween(titreEchelle, 0.7, {Scale = 1}, Enum.EasingStyle.Back)
	Outils.jouer("grondement", 0.8, 0.25)
	task.spawn(frappes, jeton)
	task.spawn(function()
		while etat.jeton == jeton and etat.visible do
			task.wait(7)
			if etat.jeton ~= jeton or not etat.visible then break end
			tween(astuce, 0.3, {TextTransparency = 1})
			task.wait(0.3)
			changerAstuce(th)
			tween(astuce, 0.4, {TextTransparency = 0})
		end
	end)
end

local function cacher(rapide: boolean?)
	if not etat.visible and not gui.Enabled then
		liberer()
		return
	end
	etat.jeton += 1
	local jeton = etat.jeton
	tween(voile, if rapide then 0.12 else 0.28, {BackgroundTransparency = 0})
	task.wait(if rapide then 0.12 else 0.28)
	etat.visible = false
	ecran.Visible = false
	if etat.connexion then
		etat.connexion:Disconnect()
		etat.connexion = nil
	end
	for _, f in eclats do f.Visible = false end
	for _, f in etincelles do f.Visible = false end
	liberer()
	tween(voile, if rapide then 0.3 else 0.75, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
	task.wait(if rapide then 0.3 else 0.75)
	if etat.jeton == jeton then gui.Enabled = false end
end

-- ================= Détection du vrai chargement =================
local function grotteAutour(pos: Vector3): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then return nil end
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

-- sol sous l'arrivée et autour (5 rayons vers le bas) : nombre de points qui ont déjà du sol
local DIRECTIONS_SOL = {Vector3.zero, Vector3.new(12, 0, 0), Vector3.new(-12, 0, 0), Vector3.new(0, 0, 12), Vector3.new(0, 0, -12)}
local function solCharge(pos: Vector3, perso: Model): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {perso}
	local n = 0
	for _, dpos in DIRECTIONS_SOL do
		if workspace:Raycast(pos + dpos + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), params) then
			n += 1
		end
	end
	return n
end

-- ressources à précharger : une instance par texture / maillage différent (200 au plus)
local CLES = {
	ParticleEmitter = {"Texture"}, Beam = {"Texture"}, Trail = {"Texture"}, Decal = {"Texture"}, Texture = {"Texture"},
	MeshPart = {"MeshId", "TextureID"}, SpecialMesh = {"MeshId", "TextureId"}, SurfaceAppearance = {"ColorMap"},
}
local function ressources(liste: {Instance}): {Instance}
	local vues, res = {}, {}
	for _, d in liste do
		local champs = CLES[d.ClassName]
		if champs then
			local cle = d.ClassName
			for _, ch in champs do
				local ok, v = pcall(function() return (d :: any)[ch] end)
				cle ..= "|" .. (if ok then tostring(v) else "")
			end
			if not vues[cle] then
				vues[cle] = true
				table.insert(res, d)
				if #res >= 200 then break end
			end
		end
	end
	return res
end

local function charger(id: number)
	if etat.actif then return end
	etat.actif = true
	local debut = os.clock()
	local niveau = Grottes.niveau(id)
	local th = Themes.get(id)
	local abandon = false
	local perso0 = joueur.Character
	local function stop(): boolean
		if abandon then return true end
		if joueur.Character ~= perso0 or not personnage() or joueur:GetAttribute(ATTRIBUT) == nil then
			abandon = true
		end
		return abandon
	end
	local function tard(): boolean
		return os.clock() - debut > DUREE_MAX
	end

	definirPas(0, 0.18, string.format("Descente vers −%d m…", niveau and niveau.profondeur or 50))
	montrer(id)

	-- 1. arrivée : le personnage est dans la boîte d'une grotte (le modèle, atomique, est arrivé avec lui)
	local modele, racine, perso
	while not stop() and not tard() and os.clock() - debut < 14 do
		local p, r = personnage()
		modele = r and grotteAutour(r.Position)
		if modele then
			perso, racine = p, r
			break
		end
		task.wait(0.1)
	end
	if modele and racine and not stop() then
		ancrer(racine)

		-- 2. streaming autour de l'arrivée + sol chargé
		definirPas(0.18, 0.45, "Les galeries se dévoilent…")
		local pos = racine.Position
		local fluxFini = false
		task.spawn(function()
			pcall(joueur.RequestStreamAroundAsync, joueur, pos, 4)
			fluxFini = true
		end)
		local debutPas = os.clock()
		while not stop() and not tard() and os.clock() - debutPas < 6 do
			local n = solCharge(pos, perso)
			etat.pas.frac = n / #DIRECTIONS_SOL * 0.6 + (if fluxFini then 0.4 else 0)
			if fluxFini and n >= 4 then break end
			task.wait(0.15)
		end

		-- 3. modèle de la grotte stable (plus de descendants qui arrivent)
		definirPas(0.45, 0.66, "Le décor se met en place…")
		local descendants = modele:GetDescendants()
		local nombre, stable = #descendants, 0
		debutPas = os.clock()
		while not stop() and not tard() and os.clock() - debutPas < 5 and modele.Parent do
			task.wait(0.25)
			descendants = modele:GetDescendants()
			if #descendants == nombre then stable += 1 else stable, nombre = 0, #descendants end
			etat.pas.frac = stable / 3
			if stable >= 3 then break end
		end

		-- 4. textures, maillages et particules préchargés
		definirPas(0.66, 0.88, "Préparation des textures…")
		local liste = ressources(descendants)
		local total, faits, prechargeFini = math.max(1, #liste), 0, false
		task.spawn(function()
			pcall(ContentProvider.PreloadAsync, ContentProvider, liste, function()
				faits += 1
			end)
			prechargeFini = true
		end)
		debutPas = os.clock()
		while not stop() and not tard() and not prechargeFini and os.clock() - debutPas < 6 do
			etat.pas.frac = faits / total
			task.wait(0.1)
		end

		-- 5. lumières et ambiance de la grotte appliquées (fondu de 1,6 s d'AmbianceGrotte)
		definirPas(0.88, 1, th.lumieres)
		debutPas = os.clock()
		while not stop() and not tard() and not Lighting:GetAttribute("GrotteActive") and os.clock() - debutPas < 4 do
			task.wait(0.1)
		end
		local debutFondu = os.clock()
		while not stop() and not tard() and os.clock() - debutFondu < 1.2 do
			etat.pas.frac = 0.4 + 0.6 * (os.clock() - debutFondu) / 1.2
			task.wait(0.05)
		end
	end

	if stop() then
		cacher(true)
		etat.actif = false
		return
	end
	-- fin : durée minimale, la pioche rattrape la barre, dernier coup qui perce la veine
	while os.clock() - debut < DUREE_MIN do task.wait(0.05) end
	etat.fin = true
	etat.cible = 1
	etiquette.Text = if modele then "Prêt !" else "La grotte t'attend…"
	local attente = os.clock()
	while valeur.Value < 0.995 and os.clock() - attente < 3 and not stop() do task.wait(0.05) end
	if not stop() then
		valeur.Value = 1
		impact(true)
		task.wait(0.35)
	end
	cacher(stop())
	etat.actif = false
end

joueur:GetAttributeChangedSignal(ATTRIBUT):Connect(function()
	local id = joueur:GetAttribute(ATTRIBUT)
	if type(id) == "number" then
		task.spawn(charger, id)
	end
end)
joueur.CharacterRemoving:Connect(function()
	if etat.visible then
		task.spawn(cacher, true)
	end
end)
