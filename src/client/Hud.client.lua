--!strict
-- HUD du mineur · SCRIPT CLIENT : plaque PV + stamina (haut à gauche) et course.
-- Course : maintenir Maj (Shift gauche/droite) en se déplaçant · manette : L3 (bascule) · mobile : bouton « Courir » (bascule).
-- La vitesse de marche normale est LUE sur l'Humanoid (jamais écrite en dur) : si un autre script la change,
-- elle devient la nouvelle base et la course la multiplie. La stamina vit dans le module partagé Stamina.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Stamina = require(script.Parent:WaitForChild("Stamina"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local joueur = Players.LocalPlayer
local playerGui = joueur:WaitForChild("PlayerGui")

-- ================= Réglages =================
local MULT_COURSE = 1.6
local FOV_BONUS = 8
local VITESSE_REELLE = 2 -- studs/s horizontaux minimum pour compter comme « bouge vraiment »
local RETARD_DELAI = 0.45 -- la barre claire attend avant de rattraper
local SEUIL_CRITIQUE = 0.25
local ARRET_BASCULE = 0.5 -- s immobile avant d'annuler la course en mode bascule (L3 / mobile)

local FAST, BOUNCY = UI.FAST, UI.BOUNCY
local PULSE = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local CLIGNE = TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- PV : vert vif -> vert forêt · Stamina : bleu glacier -> bleu profond (dégradés verticaux)
local COUL_PV = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 196, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 96, 40))})
local COUL_STA = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 225, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 140, 240)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 52, 150))})
local GRIS_EPUISE = Color3.fromRGB(120, 116, 112)
local RETARD_PV = Color3.fromRGB(236, 255, 170) -- vert très pâle / jaune paille
local VERT_CRISTAL = Color3.fromRGB(56, 214, 96)
local FOND_COEUR = Color3.fromRGB(14, 52, 26)
local HALO_COEUR = Color3.fromRGB(90, 255, 130)
local ROUGE_ALERTE = Color3.fromRGB(255, 60, 50)

-- La barre de vie Roblox par défaut fait doublon
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- ================= Plaque =================
local gui = creer("ScreenGui", {Name = "HudVie", ResetOnSpawn = false, DisplayOrder = 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})

local POS_PLAQUE = UDim2.fromOffset(16, 10)
local grain = {}
for i = 0, 10 do
	local v = if i % 2 == 0 then 255 - (i * 7) % 30 else 196 + (i * 13) % 26
	table.insert(grain, ColorSequenceKeypoint.new(i / 10, Color3.fromRGB(v, v * 0.97, v * 0.94)))
end
-- Plaque large et haute : la hauteur (≈ largeur / 4) reste bien au-dessus du bouton Sac (centré à 55 % de l'écran)
local plaque = creer("Frame", {Name = "Plaque", Position = POS_PLAQUE, Size = UDim2.fromScale(0.36, 0), BackgroundColor3 = T.Bois,
	Parent = gui}, {coin(0.2), trait(Color3.fromRGB(18, 10, 6), 3),
	creer("UIAspectRatioConstraint", {AspectRatio = 4, DominantAxis = Enum.DominantAxis.Width}),
	creer("UISizeConstraint", {MinSize = Vector2.new(320, 80), MaxSize = Vector2.new(780, 195)}),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(grain)})})
-- liseré intérieur clair (bois patiné)
creer("Frame", {Position = UDim2.fromScale(0.012, 0.07), Size = UDim2.fromScale(0.976, 0.86), BackgroundTransparency = 1, Parent = plaque},
	{coin(0.18), trait(Color3.fromRGB(150, 104, 60), 1.5, 0.55)})
-- rivets côté droit + le long des bords
for _, p in {Vector2.new(0.985, 0.17), Vector2.new(0.985, 0.83)} do
	UI.rivet(plaque, UDim2.fromScale(p.X, p.Y), 0.09)
end
for i = 1, 4 do
	UI.rivet(plaque, UDim2.fromScale(0.3 + i * 0.13, 0.055), 0.06)
	UI.rivet(plaque, UDim2.fromScale(0.3 + i * 0.13, 0.945), 0.06)
end

-- ================= Médaillon : cœur de cristal (PV) =================
local medaillon = creer("Frame", {Name = "Medaillon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(-0.028, 0.5),
	Size = UDim2.fromScale(1.12, 1.12), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fer, ZIndex = 3,
	Parent = plaque}, {coin(0.5), trait(T.FerSombre, 3),
	creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(225, 225, 232), Color3.fromRGB(70, 70, 78))})})
for i = 0, 5 do
	local a = math.rad(i * 60 + 30)
	UI.rivet(medaillon, UDim2.fromScale(0.5 + math.cos(a) * 0.445, 0.5 + math.sin(a) * 0.445), 0.08)
end
local fondCoeur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.76, 0.76),
	BackgroundColor3 = FOND_COEUR, ZIndex = 4, Parent = medaillon}, {coin(0.5), trait(Color3.fromRGB(6, 20, 10), 2),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(170, 255, 190), Color3.fromRGB(30, 60, 40))})})
local haloCoeur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.95, 0.95),
	BackgroundColor3 = HALO_COEUR, BackgroundTransparency = 0.72, ZIndex = 4, Parent = fondCoeur}, {coin(0.5)})
local coeur = creer("Frame", {Name = "Coeur", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.66, 0.66), BackgroundTransparency = 1, ZIndex = 5, Parent = fondCoeur})
do
	-- cœur de cristal vert (émeraude) : carré à 45° + deux lobes sur ses arêtes hautes
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.5, 0.5),
		Rotation = 45, BackgroundColor3 = VERT_CRISTAL, BorderSizePixel = 0, ZIndex = 5, Parent = coeur}, {coin(0.08)})
	for _, x in {0.323, 0.677} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.403), Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = VERT_CRISTAL, BorderSizePixel = 0, ZIndex = 5, Parent = coeur}, {coin(0.5)})
	end
	-- facettes de cristal : ombre en bas à droite, éclats clairs en haut à gauche
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.66), Size = UDim2.fromScale(0.3, 0.3),
		Rotation = 45, BackgroundColor3 = Color3.fromRGB(8, 90, 36), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 6,
		Parent = coeur}, {coin(0.1)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.3, 0.36), Size = UDim2.fromScale(0.2, 0.13),
		Rotation = -35, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 6,
		Parent = coeur}, {coin(0.5)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.44, 0.5), Size = UDim2.fromScale(0.07, 0.07),
		Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 6, Parent = coeur})
end

-- ================= Lanterne (stamina) =================
type Lanterne = {pivot: Frame, corps: Frame, halo: Frame}
local function lanterne(parent: Instance, z: number): Lanterne
	local pivot = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z, Parent = parent})
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.57), Size = UDim2.fromScale(1.05, 1.05),
		BackgroundColor3 = Color3.fromRGB(255, 176, 70), BackgroundTransparency = 0.85, ZIndex = z, Parent = pivot}, {coin(0.5)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.38, 0.3),
		BackgroundTransparency = 1, ZIndex = z, Parent = pivot}, {coin(0.5), trait(T.FerSombre, 2)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.64, 0.13),
		BackgroundColor3 = T.Fer, ZIndex = z + 1, Parent = pivot}, {coin(0.35), trait(T.FerSombre, 1.5)})
	local corps = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromScale(0.5, 0.48),
		BackgroundColor3 = Color3.fromRGB(255, 196, 90), ZIndex = z + 1, Parent = pivot}, {coin(0.25), trait(T.FerSombre, 2),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 110, 30))})})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.36, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, ZIndex = z + 2, Parent = corps}, {coin(0.5)}) -- flamme
	for _, x in {0.3, 0.7} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = T.FerSombre, BorderSizePixel = 0, ZIndex = z + 3, Parent = corps})
	end
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.7, 0.13),
		BackgroundColor3 = T.Fer, ZIndex = z + 1, Parent = pivot}, {coin(0.35), trait(T.FerSombre, 1.5)})
	return {pivot = pivot, corps = corps, halo = halo}
end

local iconeSta = creer("Frame", {Name = "IconeStamina", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.272, 0.74),
	Size = UDim2.fromScale(0.4, 0.4), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 3, Parent = plaque})
local lanterneSta = lanterne(iconeSta, 3)
lanterneSta.halo.BackgroundColor3 = Color3.fromRGB(120, 200, 255) -- lueur bleutée, assortie à la barre

-- ================= Barres =================
type Barre = {cadre: Frame, rempli: Frame, retard: Frame, flash: Frame, valeur: TextLabel, nom: TextLabel, lueur: UIStroke,
	degrade: UIGradient}

-- Texte lisible : TextScaled borné (min confortable), contour épais + ombre portée décalée
local CONTOUR = Color3.fromRGB(16, 8, 4)
local function texteBarre(parent: Instance, props: {[string]: any}, tailleMax: number, tailleMin: number): TextLabel
	props.Parent = parent
	props.ZIndex = 8
	local l = texte(props, tailleMax)
	local c = l:FindFirstChildOfClass("UITextSizeConstraint")
	if c then
		c.MinTextSize = tailleMin
	end
	creer("UIStroke", {Thickness = 2.5, Color = CONTOUR, LineJoinMode = Enum.LineJoinMode.Round, Parent = l})
	-- ombre : copie sombre légèrement décalée sous le texte
	local ombre = texte({Text = l.Text, Font = l.Font, TextXAlignment = l.TextXAlignment, TextColor3 = Color3.new(0, 0, 0),
		TextTransparency = 0.45, AnchorPoint = l.AnchorPoint, Position = l.Position + UDim2.fromOffset(2, 3), Size = l.Size, ZIndex = 7,
		Parent = parent}, tailleMax)
	local co = ombre:FindFirstChildOfClass("UITextSizeConstraint")
	if co then
		co.MinTextSize = tailleMin
	end
	l:GetPropertyChangedSignal("Text"):Connect(function()
		ombre.Text = l.Text
	end)
	return l
end

local function creerBarre(nomBarre: string, libelle: string, pos: UDim2, taille: UDim2, couleurs: ColorSequence, couleurRetard: Color3,
	tailleTexte: number, tailleMin: number): Barre
	-- halo extérieur (alerte), derrière le cadre
	local halo = creer("Frame", {Name = nomBarre .. "Lueur", Position = pos, Size = taille, BackgroundTransparency = 1, ZIndex = 2, Parent = plaque},
		{coin(0.45)})
	local lueur = trait(Color3.fromRGB(255, 50, 40), 6, 1)
	lueur.Parent = halo
	local cadre = creer("Frame", {Name = nomBarre, Position = pos, Size = taille, BackgroundColor3 = T.Fer, ZIndex = 3, Parent = plaque},
		{coin(0.45), trait(T.FerSombre, 2),
			creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(215, 215, 222)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 130, 138)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 66))})}),
			creer("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3)})})
	-- CanvasGroup : les remplissages sont rognés à la forme arrondie
	local clip = creer("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 19, 16), ZIndex = 3, Parent = cadre},
		{coin(0.4), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(90, 90, 90), Color3.new(1, 1, 1))})})
	local retard = creer("Frame", {Name = "Retard", Size = UDim2.fromScale(1, 1), BackgroundColor3 = couleurRetard, BorderSizePixel = 0,
		ZIndex = 3, Parent = clip})
	local degrade = creer("UIGradient", {Rotation = 90, Color = couleurs})
	local rempli = creer("Frame", {Name = "Rempli", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		ZIndex = 4, Parent = clip}, {degrade})
	-- reflet bombé + ombre basse (lisibles sur la couleur, communs aux deux barres)
	creer("Frame", {Position = UDim2.fromScale(0, 0.06), Size = UDim2.fromScale(1, 0.36), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 5, Parent = clip})
	creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.22), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 5, Parent = clip})
	for i = 1, 9 do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(i / 10, 0.18), Size = UDim2.new(0, 2, 0.64, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 5, Parent = clip})
	end
	local flash = creer("Frame", {Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 6, Parent = clip})
	-- textes hors du CanvasGroup (restent nets)
	local nom = texteBarre(cadre, {Text = libelle, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.36, 0.84)}, math.floor(tailleTexte * 0.8), tailleMin)
	local valeur = texteBarre(cadre, {Text = "", Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.36, 0.06), Size = UDim2.fromScale(0.61, 0.88)}, tailleTexte, tailleMin)
	return {cadre = cadre, rempli = rempli, retard = retard, flash = flash, valeur = valeur, nom = nom, lueur = lueur, degrade = degrade}
end

local barrePV = creerBarre("PV", "PV", UDim2.fromScale(0.272, 0.09), UDim2.fromScale(0.69, 0.46), COUL_PV, RETARD_PV, 44, 16)
local barreSta = creerBarre("Stamina", "STAMINA", UDim2.fromScale(0.38, 0.58), UDim2.fromScale(0.582, 0.33), COUL_STA,
	Color3.fromRGB(30, 40, 70), 32, 13)
barreSta.retard.Visible = false

-- Touche de course (bureau : Maj · manette : L3), en coin de la barre stamina
local touche = creer("TextLabel", {Name = "Touche", Text = "Maj", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = T.BoisSombre,
	BackgroundColor3 = T.Or, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.933, 0.745), Size = UDim2.fromScale(0.058, 0.27),
	ZIndex = 8, Parent = plaque}, {coin(0.35), trait(T.OrFonce, 1.5), creer("UIPadding", {PaddingTop = UDim.new(0.14, 0),
	PaddingBottom = UDim.new(0.14, 0), PaddingLeft = UDim.new(0.08, 0), PaddingRight = UDim.new(0.08, 0)})})
local echelleTouche = UI.echelle(touche)

-- ================= Bouton mobile « Courir » =================
local boutonCourir = creer("TextButton", {Name = "Courir", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
	BackgroundColor3 = T.Bois, Visible = false, ZIndex = 2, Parent = gui}, {coin(0.5),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 130, 115))})})
local traitCourir = trait(T.OrFonce, 3)
traitCourir.Parent = boutonCourir
local iconeCourir = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, ZIndex = 3, Parent = boutonCourir})
local lanterneCourir = lanterne(iconeCourir, 3)
local texteCourir = texte({Text = "COURIR", Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.1, 0.6), Size = UDim2.fromScale(0.8, 0.24),
	ZIndex = 4, Parent = boutonCourir}, 16)
creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(28, 12, 6), Parent = texteCourir})
UI.reactif(boutonCourir, 1.06)

-- ================= Mise en page responsive =================
local camConnexion: RBXScriptConnection? = nil
local function ajusterTaille()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local vp = cam.ViewportSize
	-- petits écrans : la plaque prend plus de place relative pour rester lisible
	plaque.Size = UDim2.fromScale(if vp.X < 900 then 0.46 else 0.36, 0)
	-- bouton Courir à gauche du bouton Saut tactile de Roblox (mêmes formules que TouchJump)
	local saut = if math.min(vp.X, vp.Y) <= 500 then 70 else 120
	local taille = math.floor(saut * 0.78)
	boutonCourir.Size = UDim2.fromOffset(taille, taille)
	boutonCourir.Position = UDim2.new(1, -(saut * 1.5 - 10) - 14, 1, -saut / 2 - 20)
end
local function suivreCamera()
	if camConnexion then
		camConnexion:Disconnect()
		camConnexion = nil
	end
	local cam = workspace.CurrentCamera
	if cam then
		camConnexion = cam:GetPropertyChangedSignal("ViewportSize"):Connect(ajusterTaille)
	end
	ajusterTaille()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(suivreCamera)
suivreCamera()

-- Affichage selon le dernier périphérique utilisé
local function majPeripherique()
	local dernier = UserInputService:GetLastInputType()
	local tactile = dernier == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		and not UserInputService.GamepadEnabled)
	local manette = dernier.Name:sub(1, 7) == "Gamepad"
	boutonCourir.Visible = tactile
	touche.Visible = not tactile
	-- la barre stamina laisse la place à la touche affichée (bureau / manette)
	local largeur = UDim2.fromScale(if tactile then 0.582 else 0.517, 0.33)
	barreSta.cadre.Size = largeur
	local lueurSta = plaque:FindFirstChild("StaminaLueur") :: Frame?
	if lueurSta then
		lueurSta.Size = largeur
	end
	touche.Text = if manette then "L3" else "Maj"
end
UserInputService.LastInputTypeChanged:Connect(majPeripherique)
majPeripherique()

-- Shift Lock de Roblox utilise aussi Maj : on le déplace sur Ctrl (côté client uniquement) pour éviter le conflit
task.spawn(function()
	local scripts = joueur:WaitForChild("PlayerScripts", 10)
	local module = scripts and scripts:WaitForChild("PlayerModule", 10)
	local camera = module and module:WaitForChild("CameraModule", 10)
	local verrou = camera and camera:WaitForChild("MouseLockController", 10)
	local touches = verrou and verrou:WaitForChild("BoundKeys", 10)
	if touches and touches:IsA("StringValue") and touches.Value == "LeftShift,RightShift" then
		touches.Value = "LeftControl,RightControl"
	end
end)

-- ================= État PV =================
local humanoid: Humanoid? = nil
local racine: BasePart? = nil
local connexionsPerso: {RBXScriptConnection} = {}
local pvActuel, pvMax = 100, 100
local pvCible, pvAff, pvRetard = 1, 1, 1 -- fractions
local horloge = 0
local tempsDegat = -math.huge
local secousse = 0
local critique = false

local tPulseLueur = TweenService:Create(barrePV.lueur, PULSE, {Transparency = 0.1})
local tPulseHalo = TweenService:Create(haloCoeur, PULSE, {BackgroundTransparency = 0.2, Size = UDim2.fromScale(1.3, 1.3)})

local function definirCritique(c: boolean)
	if c == critique then
		return
	end
	critique = c
	if c then
		-- alerte : le halo du cœur vire au rouge pendant la pulsation
		haloCoeur.BackgroundColor3 = ROUGE_ALERTE
		tPulseLueur:Play()
		tPulseHalo:Play()
	else
		tPulseLueur:Cancel()
		tPulseHalo:Cancel()
		TweenService:Create(barrePV.lueur, FAST, {Transparency = 1}):Play()
		TweenService:Create(haloCoeur, FAST, {BackgroundTransparency = 0.72, Size = UDim2.fromScale(0.95, 0.95),
			BackgroundColor3 = HALO_COEUR}):Play()
	end
end

local function majTextePV()
	local h = humanoid
	if h and h.Health <= 0 then
		barrePV.valeur.Text = "K.O."
	else
		barrePV.valeur.Text = string.format("%d / %d", math.ceil(pvActuel), math.floor(pvMax + 0.5))
	end
end

local function degats(n: number)
	tempsDegat = horloge
	local ratio = n / math.max(pvMax, 1)
	secousse = math.min(12, 3 + ratio * 45)
	barrePV.flash.BackgroundTransparency = 0.1
	TweenService:Create(barrePV.flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	fondCoeur.BackgroundColor3 = Color3.fromRGB(255, 90, 80)
	TweenService:Create(fondCoeur, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundColor3 = FOND_COEUR}):Play()
	UI.pop(coeur, 1.25)
	if ratio >= 0.04 then
		UI.jouer("metal", 0.55)
	end
end

local function lireSante(instantane: boolean)
	local h = humanoid
	if not h then
		return
	end
	local avant = pvActuel
	pvActuel, pvMax = h.Health, h.MaxHealth
	pvCible = if pvMax > 0 then math.clamp(pvActuel / pvMax, 0, 1) else 0
	if instantane then
		pvAff, pvRetard = pvCible, pvCible
	elseif pvActuel < avant - 0.01 then
		degats(avant - pvActuel)
	end
	definirCritique(pvActuel > 0 and pvCible < SEUIL_CRITIQUE)
	majTextePV()
end

-- ================= Course =================
local bascule = false -- mode L3 / mobile
local immobile = 0
local enCourse = false
local facteur = 1
local baseVitesse = 16
local derniereVitesse: number? = nil -- dernière WalkSpeed écrite par ce script (nil = on n'écrit pas)
local baseFov = 70
local dernierFov: number? = nil
local camCourse: Camera? = nil
local etaitEpuise = false

local function definirBascule(b: boolean)
	if b == bascule then
		return
	end
	bascule = b
	traitCourir.Color = if b then T.Or else T.OrFonce
	traitCourir.Thickness = if b then 4 else 3
	TweenService:Create(boutonCourir, FAST, {BackgroundColor3 = if b then T.CarteClaire else T.Bois}):Play()
	TweenService:Create(lanterneCourir.halo, FAST, {BackgroundTransparency = if b then 0.35 else 0.85}):Play()
end

local function libre(h: Humanoid): boolean
	if h.Health <= 0 or h.Sit or h.PlatformStand then
		return false
	end
	local etat = h:GetState()
	return etat ~= Enum.HumanoidStateType.Dead and etat ~= Enum.HumanoidStateType.Seated and etat ~= Enum.HumanoidStateType.Physics
		and etat ~= Enum.HumanoidStateType.Ragdoll
end

local function definirCourse(c: boolean)
	if c == enCourse then
		return
	end
	enCourse = c
	joueur:SetAttribute("Court", c)
	TweenService:Create(lanterneSta.halo, FAST, {BackgroundTransparency = if c then 0.35 else 0.85}):Play()
	TweenService:Create(echelleTouche, FAST, {Scale = if c then 1.15 else 1}):Play()
	touche.BackgroundColor3 = if c then Color3.fromRGB(255, 240, 180) else T.Or
end

local function majEpuise(e: boolean)
	etaitEpuise = e
	local nom, valeur = barreSta.nom, barreSta.valeur
	if e then
		definirBascule(false)
		barreSta.degrade.Enabled = false -- gris franc, sans teinte bleue
		barreSta.rempli.BackgroundColor3 = GRIS_EPUISE
		TweenService:Create(barreSta.rempli, CLIGNE, {BackgroundTransparency = 0.6}):Play()
		nom.Text, nom.TextColor3 = "ÉPUISÉ", T.Rouge
		UI.secouer(iconeSta, 4)
		UI.jouer("ouvrir", 0.55)
	else
		barreSta.degrade.Enabled = true
		TweenService:Create(barreSta.rempli, FAST, {BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
		nom.Text, nom.TextColor3 = "STAMINA", T.Or
		UI.pop(iconeSta, 1.3)
	end
	valeur.TextColor3 = if e then T.Gris else Color3.new(1, 1, 1)
end

boutonCourir.Activated:Connect(function()
	if not bascule and not Stamina.peutCourir() then
		UI.secouer(boutonCourir, 5)
		UI.jouer("clic", 0.6)
		return
	end
	UI.jouer("clic", if bascule then 0.85 else 1.1)
	immobile = 0
	definirBascule(not bascule)
end)

UserInputService.InputBegan:Connect(function(input, traite)
	if input.KeyCode == Enum.KeyCode.ButtonL3 and not traite then
		immobile = 0
		definirBascule(not bascule and Stamina.peutCourir())
	end
end)

-- ================= Personnage =================
local function lierPerso(perso: Model)
	for _, c in connexionsPerso do
		c:Disconnect()
	end
	table.clear(connexionsPerso)
	humanoid, racine = nil, nil
	derniereVitesse, facteur = nil, 1
	definirBascule(false)
	definirCourse(false)
	local trouve = perso:WaitForChild("Humanoid", 10)
	local r = perso:WaitForChild("HumanoidRootPart", 10)
	if not (trouve and trouve:IsA("Humanoid")) or joueur.Character ~= perso then
		return -- perso remplacé entre-temps : le nouvel appel s'en charge
	end
	local h = trouve :: Humanoid
	humanoid = h
	racine = if r and r:IsA("BasePart") then r :: BasePart else nil
	baseVitesse = h.WalkSpeed
	Stamina.remplir()
	pvActuel = h.Health
	lireSante(true)
	table.insert(connexionsPerso, h.HealthChanged:Connect(function()
		lireSante(false)
	end))
	table.insert(connexionsPerso, h:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		lireSante(false)
	end))
	table.insert(connexionsPerso, h.Died:Connect(function()
		definirBascule(false)
		definirCritique(false)
		majTextePV()
	end))
end
joueur.CharacterAdded:Connect(lierPerso)
if joueur.Character then
	task.spawn(lierPerso, joueur.Character)
end

-- ================= Boucle par image (aucune allocation hors changements) =================
local largeurPV, largeurRetard, largeurSta = -1, -1, -1
local staAff = 1
local staTexte = -1
local plaqueDecalee = false

RunService.RenderStepped:Connect(function(dt)
	horloge += dt

	-- --- Course ---
	local h = humanoid
	local r = racine
	local veut = false
	if h and r and h.Parent then
		local intention = h.MoveDirection.Magnitude > 0.1
		if bascule then
			immobile = if intention then 0 else immobile + dt
			if immobile > ARRET_BASCULE then
				definirBascule(false)
			end
		end
		local maj = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
			and UserInputService:GetFocusedTextBox() == nil
		if (maj or bascule) and intention and libre(h) and Stamina.peutCourir() then
			local v = r.AssemblyLinearVelocity
			-- au démarrage on accélère déjà ; la stamina ne baisse que si on avance réellement
			veut = true
			if v.X * v.X + v.Z * v.Z > VITESSE_REELLE * VITESSE_REELLE then
				Stamina.drainer(Stamina.DRAIN_COURSE * dt)
				if not Stamina.peutCourir() then
					veut = false
				end
			end
		end

		local cibleF = if veut then MULT_COURSE else 1
		facteur += (cibleF - facteur) * (1 - math.exp(-8 * dt))
		if math.abs(cibleF - facteur) < 0.002 then
			facteur = cibleF
		end

		-- WalkSpeed : la base suit toute valeur posée par quelqu'un d'autre
		local ws = h.WalkSpeed
		local ecrit = derniereVitesse
		if ecrit == nil or math.abs(ws - ecrit) > 0.01 then
			baseVitesse = ws
		end
		if facteur ~= 1 then
			local n = baseVitesse * facteur
			if math.abs(n - ws) > 0.001 then
				h.WalkSpeed = n
			end
			derniereVitesse = n
		elseif ecrit ~= nil then
			h.WalkSpeed = baseVitesse
			derniereVitesse = nil
		end
	end
	definirCourse(veut)

	-- FOV : même principe que la vitesse
	local cam = workspace.CurrentCamera
	if cam then
		if cam ~= camCourse then
			camCourse, dernierFov = cam, nil
		end
		local f = cam.FieldOfView
		local ecritF = dernierFov
		if ecritF == nil or math.abs(f - ecritF) > 0.01 then
			baseFov = f
		end
		local bonus = (facteur - 1) / (MULT_COURSE - 1) * FOV_BONUS
		if bonus > 0.01 then
			local n = baseFov + bonus
			if math.abs(n - f) > 0.001 then
				cam.FieldOfView = n
			end
			dernierFov = n
		elseif ecritF ~= nil then
			cam.FieldOfView = baseFov
			dernierFov = nil
		end
	end

	-- --- Barre PV (+ barre de dégâts retardée) ---
	pvAff += (pvCible - pvAff) * (1 - math.exp(-14 * dt))
	if pvRetard <= pvAff then
		pvRetard = pvAff
	elseif horloge - tempsDegat > RETARD_DELAI then
		pvRetard += (pvAff - pvRetard) * (1 - math.exp(-5 * dt))
	end
	if math.abs(pvAff - largeurPV) > 0.0008 then
		largeurPV = pvAff
		barrePV.rempli.Size = UDim2.fromScale(pvAff, 1)
	end
	if math.abs(pvRetard - largeurRetard) > 0.0008 then
		largeurRetard = pvRetard
		barrePV.retard.Size = UDim2.fromScale(pvRetard, 1)
	end

	-- --- Barre stamina ---
	local sCible = Stamina.fraction()
	staAff += (sCible - staAff) * (1 - math.exp(-12 * dt))
	if math.abs(staAff - largeurSta) > 0.0008 then
		largeurSta = staAff
		barreSta.rempli.Size = UDim2.fromScale(staAff, 1)
	end
	local sTexte = math.floor(Stamina.get() + 0.5)
	if sTexte ~= staTexte then
		staTexte = sTexte
		barreSta.valeur.Text = string.format("%d / %d", sTexte, Stamina.MAX)
	end
	local ep = Stamina.estEpuise()
	if ep ~= etaitEpuise then
		majEpuise(ep)
	end

	-- --- Secousse de la plaque ---
	if secousse > 0.3 then
		secousse *= math.exp(-9 * dt)
		plaque.Position = UDim2.fromOffset(POS_PLAQUE.X.Offset + math.sin(horloge * 71) * secousse,
			POS_PLAQUE.Y.Offset + math.cos(horloge * 53) * secousse * 0.45)
		plaqueDecalee = true
	elseif plaqueDecalee then
		secousse = 0
		plaque.Position = POS_PLAQUE
		plaqueDecalee = false
	end
end)
