-- Verrouillage de la caméra sur le boss (« focus ») · SCRIPT CLIENT
-- Ctrl (PC), R3 (manette) ou un appui sur le logo en bas à gauche (téléphone) : la caméra se tourne vers le boss et
-- le suit, un « point vital » (réticule rouge) s'affiche sur lui, et le personnage lui fait face (CameraVisee met
-- le personnage dans l'axe de la caméra). Rappuyer libère la caméra. Sans boss à portée, vise le mob le plus proche.
-- Se libère tout seul si la cible meurt, s'éloigne trop, ou si on meurt. En pause quand une interface est ouverte.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Curseur = require(script.Parent:WaitForChild("Curseur"))

local joueur = Players.LocalPlayer

local PORTEE_BOSS = 160
local PORTEE_MOB = 60
local LACHER = 1.25 -- × portée : au-delà, le verrou saute
local DOUCEUR = 14 -- vitesse à laquelle la caméra rejoint la cible
local ROUGE = Color3.fromRGB(255, 70, 60)
local OR = Color3.fromRGB(255, 204, 92)
local BOIS = Color3.fromRGB(40, 25, 16)

local verrou = false
local cible: Model? = nil

-- ================= Logo en bas à gauche =================
local gui = Instance.new("ScreenGui")
gui.Name = "VerrouBoss"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = joueur:WaitForChild("PlayerGui")

local puce = Instance.new("TextButton")
puce.Name = "Logo"
puce.Text = ""
puce.AutoButtonColor = false
puce.AnchorPoint = Vector2.new(0, 1)
puce.Position = UDim2.new(0, 14, 1, -58)
puce.Size = UDim2.fromOffset(176, 40)
puce.BackgroundColor3 = BOIS
puce.BackgroundTransparency = 0.25
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
touche.Text = "Ctrl"
touche.Parent = puce
Instance.new("UICorner", touche).CornerRadius = UDim.new(0, 6)

-- Icône de cible : anneau + 4 crans + point
local icone = Instance.new("Frame")
icone.AnchorPoint = Vector2.new(0, 0.5)
icone.Position = UDim2.new(0, 52, 0.5, 0)
icone.Size = UDim2.fromOffset(24, 24)
icone.BackgroundTransparency = 1
icone.Parent = puce
Instance.new("UICorner", icone).CornerRadius = UDim.new(1, 0)
local anneauIcone = Instance.new("UIStroke")
anneauIcone.Color = OR
anneauIcone.Thickness = 2
anneauIcone.Parent = icone
local pointIcone = Instance.new("Frame")
pointIcone.AnchorPoint = Vector2.new(0.5, 0.5)
pointIcone.Position = UDim2.fromScale(0.5, 0.5)
pointIcone.Size = UDim2.fromOffset(6, 6)
pointIcone.BackgroundColor3 = OR
pointIcone.BorderSizePixel = 0
pointIcone.Parent = icone
Instance.new("UICorner", pointIcone).CornerRadius = UDim.new(1, 0)
for _, d in {Vector2.new(0.5, -0.12), Vector2.new(0.5, 1.12), Vector2.new(-0.12, 0.5), Vector2.new(1.12, 0.5)} do
	local cran = Instance.new("Frame")
	cran.AnchorPoint = Vector2.new(0.5, 0.5)
	cran.Position = UDim2.fromScale(d.X, d.Y)
	cran.Size = if d.X == 0.5 then UDim2.fromOffset(2, 7) else UDim2.fromOffset(7, 2)
	cran.BackgroundColor3 = OR
	cran.BorderSizePixel = 0
	cran.Parent = icone
end

local etiquette = Instance.new("TextLabel")
etiquette.BackgroundTransparency = 1
etiquette.Position = UDim2.new(0, 84, 0, 0)
etiquette.Size = UDim2.new(1, -90, 1, 0)
etiquette.Font = Enum.Font.GothamBold
etiquette.TextColor3 = Color3.fromRGB(245, 232, 210)
etiquette.TextSize = 14
etiquette.TextXAlignment = Enum.TextXAlignment.Left
etiquette.Text = "Viser le boss"
etiquette.Parent = puce

local function majTouche()
	local dernier = UserInputService:GetLastInputType()
	if dernier.Name:sub(1, 7) == "Gamepad" then
		touche.Text = "R3"
	elseif dernier == Enum.UserInputType.Touch then
		touche.Text = "Appui"
	else
		touche.Text = "Ctrl"
	end
end
UserInputService.LastInputTypeChanged:Connect(majTouche)
majTouche()

local function majLogo(disponible: boolean)
	local couleur = if verrou then ROUGE else OR
	anneauIcone.Color, pointIcone.BackgroundColor3, bord.Color = couleur, couleur, couleur
	for _, f in icone:GetChildren() do
		if f:IsA("Frame") then f.BackgroundColor3 = couleur end
	end
	if verrou then
		etiquette.Text = "Verrouillé"
		etiquette.TextColor3 = ROUGE:Lerp(Color3.new(1, 1, 1), 0.35)
	else
		etiquette.Text = if cible == nil and not disponible then "Viser (aucune cible)" else "Viser le boss"
		etiquette.TextColor3 = Color3.fromRGB(245, 232, 210)
	end
	puce.BackgroundTransparency = if verrou or disponible then 0.2 else 0.55
	etiquette.TextTransparency = if verrou or disponible then 0 else 0.4
	touche.BackgroundTransparency = if verrou or disponible then 0 else 0.45
end

-- ================= Point vital (réticule sur la cible) =================
local marque = Instance.new("BillboardGui")
marque.Name = "PointVital"
marque.AlwaysOnTop = true
marque.LightInfluence = 0
marque.Size = UDim2.fromOffset(54, 54)
marque.Enabled = false
marque.ResetOnSpawn = false
marque.Parent = gui

local anneau = Instance.new("Frame")
anneau.AnchorPoint = Vector2.new(0.5, 0.5)
anneau.Position = UDim2.fromScale(0.5, 0.5)
anneau.Size = UDim2.fromScale(0.8, 0.8)
anneau.BackgroundTransparency = 1
anneau.Parent = marque
Instance.new("UICorner", anneau).CornerRadius = UDim.new(1, 0)
local traitAnneau = Instance.new("UIStroke")
traitAnneau.Color = ROUGE
traitAnneau.Thickness = 2.5
traitAnneau.Parent = anneau
for i = 0, 3 do -- 4 crochets qui tournent
	local c = Instance.new("Frame")
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	local a = i * math.pi / 2
	c.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.62, 0.5 + math.sin(a) * 0.62)
	c.Size = if i % 2 == 0 then UDim2.fromOffset(9, 3) else UDim2.fromOffset(3, 9)
	c.BackgroundColor3 = ROUGE
	c.BorderSizePixel = 0
	c.Parent = anneau
end
local coeur = Instance.new("Frame")
coeur.AnchorPoint = Vector2.new(0.5, 0.5)
coeur.Position = UDim2.fromScale(0.5, 0.5)
coeur.Size = UDim2.fromScale(0.2, 0.2)
coeur.BackgroundColor3 = ROUGE
coeur.BorderSizePixel = 0
coeur.Parent = marque
Instance.new("UICorner", coeur).CornerRadius = UDim.new(1, 0)
local echelleMarque = Instance.new("UIScale")
echelleMarque.Parent = anneau

-- ================= Cible =================
local function cibleValide(m: Model?): boolean
	if not m or not m.Parent or not m.PrimaryPart then return false end
	local pv = m:GetAttribute("PV")
	return (type(pv) ~= "number" or pv > 0) and m:GetAttribute("Etat") ~= "Death"
end

local function racine(): BasePart?
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

local function portee(m: Model): number
	return if m:GetAttribute("Boss") == true then PORTEE_BOSS else PORTEE_MOB
end

local function chercherCible(): Model?
	local r = racine()
	if not r then return nil end
	local meilleur, score = nil, math.huge
	for _, m in CollectionService:GetTagged("MobGrotte") do
		if m:IsA("Model") and cibleValide(m) then
			local d = ((m.PrimaryPart :: BasePart).Position - r.Position).Magnitude
			if d <= portee(m) then
				local s = if m:GetAttribute("Boss") == true then d - 10000 else d -- les boss d'abord
				if s < score then meilleur, score = m, s end
			end
		end
	end
	return meilleur
end

-- Point vital : la tête (os « head »), sinon le haut du corps
local function vital(m: Model): (Vector3, BasePart)
	local tete = m:FindFirstChild("B_head")
	if tete and tete:IsA("BasePart") then
		local h = m:GetAttribute("Hauteur")
		return tete.Position + Vector3.new(0, (if type(h) == "number" then h else 6) * 0.06, 0), tete
	end
	local cf, taille = m:GetBoundingBox()
	return cf.Position + Vector3.new(0, taille.Y * 0.15, 0), m.PrimaryPart :: BasePart
end

local function desactiver()
	verrou = false
	cible = nil
	marque.Enabled = false
	marque.Adornee = nil
	majLogo(chercherCible() ~= nil)
end

local function activer(m: Model)
	verrou = true
	cible = m
	local _, adornee = vital(m)
	marque.Adornee = adornee
	marque.Enabled = true
	echelleMarque.Scale = 2.2
	TweenService:Create(echelleMarque, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	majLogo(true)
end

local function rebond()
	echellePuce.Scale = 0.9
	TweenService:Create(echellePuce, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local function basculer()
	rebond()
	if verrou then
		desactiver()
		return
	end
	local m = chercherCible()
	if m then
		activer(m)
	else
		-- rien à viser : petit refus
		etiquette.Text = "Aucune cible proche"
		local x = puce.Position
		for i, dx in {-6, 6, -4, 4, 0} do
			task.delay(i * 0.04, function() puce.Position = x + UDim2.fromOffset(dx, 0) end)
		end
		task.delay(1.2, function()
			if not verrou then majLogo(chercherCible() ~= nil) end
		end)
	end
end

ContextActionService:BindAction("VerrouBoss", function(_, etat)
	if etat == Enum.UserInputState.Begin then
		basculer()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.ButtonR3)
puce.Activated:Connect(basculer)

-- Disponibilité affichée sur le logo (4 fois par seconde)
task.spawn(function()
	while true do
		if not verrou then
			cible = nil
			majLogo(chercherCible() ~= nil)
		end
		task.wait(0.25)
	end
end)

-- ================= Caméra =================
local horloge = 0
local function suivre(dt: number)
	horloge += dt
	if not verrou then return end
	local m = cible
	local r = racine()
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	if not m or not cibleValide(m) or not r or not humain or humain.Health <= 0
		or ((m.PrimaryPart :: BasePart).Position - r.Position).Magnitude > portee(m) * LACHER then
		desactiver()
		return
	end
	-- réticule vivant
	anneau.Rotation = (horloge * 90) % 360
	coeur.Size = UDim2.fromScale(0.2 + 0.06 * math.sin(horloge * 8), 0.2 + 0.06 * math.sin(horloge * 8))

	local camera = workspace.CurrentCamera
	if not camera or camera.CameraType ~= Enum.CameraType.Custom or Curseur.estLibre() then return end
	local point = vital(m)
	local focus = camera.Focus.Position
	local zoom = (camera.CFrame.Position - focus).Magnitude
	local vers = point - focus
	local plat = Vector3.new(vers.X, 0, vers.Z)
	if plat.Magnitude < 1.5 then return end -- collé à la cible : on ne force rien
	local yaw = math.atan2(-plat.X, -plat.Z)
	local pitch = math.atan2(vers.Y, plat.Magnitude)
	if zoom >= 1 then
		pitch = math.clamp(pitch - 0.2, -1.1, 0.45) -- caméra un peu au-dessus de l'épaule
	else
		pitch = math.clamp(pitch, -1.3, 1.3)
	end
	local voulu = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	-- la caméra de Roblox repart de camera.CFrame à chaque image : pas de saut quand on relâche
	local rot = camera.CFrame.Rotation:Lerp(voulu, 1 - math.exp(-DOUCEUR * dt))
	camera.CFrame = CFrame.new(focus) * rot * CFrame.new(0, 0, zoom)
end

-- Après la caméra de Roblox et après CameraVisee
RunService:BindToRenderStep("VerrouBoss", Enum.RenderPriority.Camera.Value + 2, suivre)

joueur.CharacterAdded:Connect(function()
	if verrou then desactiver() end
end)
