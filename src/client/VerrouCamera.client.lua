-- Verrouiller / déverrouiller la caméra · SCRIPT CLIENT
-- Bouton en bas à gauche, juste en dessous du logo « Viser le boss » (VerrouBoss.client), même style.
-- C (PC), croix gauche (manette) ou un appui sur le bouton (téléphone) bascule :
--  • Caméra verrouillée (par défaut) : souris au centre, personnage dans l'axe de la caméra, décalage d'épaule.
--  • Caméra libre : caméra Roblox classique (souris libre, clic droit pour tourner).
-- L'état est partagé par l'attribut CameraVerrouillee du LocalPlayer, lu par CameraVisee.client à chaque image.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))

local joueur = Players.LocalPlayer

local OR = Color3.fromRGB(255, 204, 92)
local BLEU = Color3.fromRGB(150, 186, 214) -- caméra libre : gris bleuté
local BOIS = Color3.fromRGB(40, 25, 16)
local CREME = Color3.fromRGB(245, 232, 210)

local LARGEUR, HAUTEUR = 220, 40
local X_LOGO_BOSS, LARGEUR_LOGO_BOSS, Y_BAS = 14, 176, -58 -- logo de VerrouBoss.client
local ECART = 8
-- juste en dessous du logo du boss (demande du collaborateur), aligné à gauche
local POS_DESSOUS = UDim2.new(0, X_LOGO_BOSS, 1, Y_BAS + HAUTEUR + ECART)

if joueur:GetAttribute("CameraVerrouillee") == nil then
	joueur:SetAttribute("CameraVerrouillee", true)
end

-- ================= Bouton =================
local gui = Instance.new("ScreenGui")
gui.Name = "VerrouCamera"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = joueur:WaitForChild("PlayerGui")

local puce = Instance.new("TextButton")
puce.Name = "Bouton"
puce.Text = ""
puce.AutoButtonColor = false
puce.AnchorPoint = Vector2.new(0, 1)
puce.Position = POS_DESSOUS
puce.Size = UDim2.fromOffset(LARGEUR, HAUTEUR)
puce.BackgroundColor3 = BOIS
puce.BackgroundTransparency = 0.2
puce.Parent = gui
Instance.new("UICorner", puce).CornerRadius = UDim.new(0, 10)
local bord = Instance.new("UIStroke")
bord.Color = OR
bord.Thickness = 1.5
bord.Transparency = 0.3
bord.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bord.Parent = puce
local echellePuce = Instance.new("UIScale")
echellePuce.Parent = puce

local touche = Instance.new("TextLabel")
touche.AnchorPoint = Vector2.new(0, 0.5)
touche.Position = UDim2.new(0, 7, 0.5, 0)
touche.Size = UDim2.fromOffset(38, 26)
touche.BackgroundColor3 = OR
touche.Font = Enum.Font.GothamBlack
touche.TextColor3 = BOIS
touche.TextSize = 13
touche.Text = "C"
touche.Parent = puce
Instance.new("UICorner", touche).CornerRadius = UDim.new(0, 6)

-- Icône : cadenas (anse + corps + serrure), l'anse se soulève et pivote quand la caméra est libre
local icone = Instance.new("Frame")
icone.AnchorPoint = Vector2.new(0, 0.5)
icone.Position = UDim2.new(0, 52, 0.5, 0)
icone.Size = UDim2.fromOffset(24, 24)
icone.BackgroundTransparency = 1
icone.Parent = puce
local echelleIcone = Instance.new("UIScale")
echelleIcone.Parent = icone

local ANSE_FERMEE = UDim2.new(0.5, 0, 0, 1)
local ANSE_OUVERTE = UDim2.new(0.5, 5, 0, -3)
local anse = Instance.new("Frame")
anse.AnchorPoint = Vector2.new(0.5, 0)
anse.Position = ANSE_FERMEE
anse.Size = UDim2.fromOffset(12, 14)
anse.BackgroundTransparency = 1
anse.Parent = icone
Instance.new("UICorner", anse).CornerRadius = UDim.new(1, 0)
local traitAnse = Instance.new("UIStroke")
traitAnse.Color = OR
traitAnse.Thickness = 2.5
traitAnse.Parent = anse

local corps = Instance.new("Frame")
corps.AnchorPoint = Vector2.new(0.5, 1)
corps.Position = UDim2.new(0.5, 0, 1, 0)
corps.Size = UDim2.fromOffset(18, 13)
corps.BackgroundColor3 = OR
corps.BorderSizePixel = 0
corps.ZIndex = 2
corps.Parent = icone
Instance.new("UICorner", corps).CornerRadius = UDim.new(0, 3)
local reflet = Instance.new("Frame") -- liseré clair en haut du corps (métal)
reflet.Position = UDim2.fromOffset(2, 2)
reflet.Size = UDim2.new(1, -4, 0, 2)
reflet.BackgroundColor3 = Color3.new(1, 1, 1)
reflet.BackgroundTransparency = 0.55
reflet.BorderSizePixel = 0
reflet.ZIndex = 3
reflet.Parent = corps
local serrure = Instance.new("Frame")
serrure.AnchorPoint = Vector2.new(0.5, 0.5)
serrure.Position = UDim2.fromScale(0.5, 0.55)
serrure.Size = UDim2.fromOffset(4, 6)
serrure.BackgroundColor3 = BOIS
serrure.BorderSizePixel = 0
serrure.ZIndex = 3
serrure.Parent = corps
Instance.new("UICorner", serrure).CornerRadius = UDim.new(1, 0)

local etiquette = Instance.new("TextLabel")
etiquette.BackgroundTransparency = 1
etiquette.Position = UDim2.new(0, 84, 0, 0)
etiquette.Size = UDim2.new(1, -90, 1, 0)
etiquette.Font = Enum.Font.GothamBold
etiquette.TextColor3 = CREME
etiquette.TextScaled = true
etiquette.TextXAlignment = Enum.TextXAlignment.Left
etiquette.Text = "Caméra verrouillée"
etiquette.Parent = puce
local tailleTexte = Instance.new("UITextSizeConstraint")
tailleTexte.MaxTextSize = 14
tailleTexte.MinTextSize = 10
tailleTexte.Parent = etiquette

-- ================= Pastille de touche =================
local function majTouche()
	local dernier = UserInputService:GetLastInputType()
	if dernier.Name:sub(1, 7) == "Gamepad" then
		touche.Text = "◀"
	elseif dernier == Enum.UserInputType.Touch then
		touche.Text = "Appui"
	else
		touche.Text = "C"
	end
end
UserInputService.LastInputTypeChanged:Connect(majTouche)
majTouche()

-- ================= État =================
local INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function estVerrouillee(): boolean
	return joueur:GetAttribute("CameraVerrouillee") ~= false
end

local function majBouton(anime: boolean)
	local v = estVerrouillee()
	local couleur = if v then OR else BLEU
	local cibles = {
		{bord, {Color = couleur}},
		{touche, {BackgroundColor3 = couleur}},
		{traitAnse, {Color = couleur}},
		{corps, {BackgroundColor3 = couleur}},
		{anse, {Position = if v then ANSE_FERMEE else ANSE_OUVERTE, Rotation = if v then 0 else 18}},
		{etiquette, {TextColor3 = if v then CREME else BLEU:Lerp(Color3.new(1, 1, 1), 0.45)}},
	}
	for _, c in cibles do
		if anime then
			TweenService:Create(c[1], INFO, c[2]):Play()
		else
			for prop, val in c[2] do
				(c[1] :: any)[prop] = val
			end
		end
	end
	etiquette.Text = if v then "Caméra verrouillée" else "Caméra libre"
end

local function rebond()
	echellePuce.Scale = 0.9
	TweenService:Create(echellePuce, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	echelleIcone.Scale = 1.35
	TweenService:Create(echelleIcone, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local function basculer()
	joueur:SetAttribute("CameraVerrouillee", not estVerrouillee())
	rebond()
	UI.jouer("metal", if estVerrouillee() then 0.9 else 1.15)
end

joueur:GetAttributeChangedSignal("CameraVerrouillee"):Connect(function()
	majBouton(true)
end)
majBouton(false)

ContextActionService:BindAction("VerrouCamera", function(_, etat, input)
	-- manette : la croix sert aussi à naviguer dans les menus, on la laisse passer quand un bouton est sélectionné
	if input.KeyCode == Enum.KeyCode.DPadLeft and GuiService.SelectedObject ~= nil then
		return Enum.ContextActionResult.Pass
	end
	if etat == Enum.UserInputState.Begin then
		basculer()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.C, Enum.KeyCode.DPadLeft)
puce.Activated:Connect(basculer)

-- Survol : léger grossissement + lueur du bord
local survole = false
puce.MouseEnter:Connect(function()
	survole = true
	UI.jouer("survol")
	TweenService:Create(echellePuce, TweenInfo.new(0.15), {Scale = 1.05}):Play()
	TweenService:Create(bord, TweenInfo.new(0.15), {Transparency = 0}):Play()
end)
puce.MouseLeave:Connect(function()
	survole = false
	TweenService:Create(echellePuce, TweenInfo.new(0.15), {Scale = 1}):Play()
	TweenService:Create(bord, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
end)
puce.MouseButton1Down:Connect(function()
	TweenService:Create(echellePuce, TweenInfo.new(0.08), {Scale = 0.94}):Play()
end)
puce.MouseButton1Up:Connect(function()
	TweenService:Create(echellePuce, TweenInfo.new(0.12), {Scale = if survole then 1.05 else 1}):Play()
end)

