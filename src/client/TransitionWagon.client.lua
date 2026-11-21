-- Trajet en wagon : caméra fixe au départ, puis écran de chargement jusqu'à l'arrivée.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CameraWagon = require(script.Parent:WaitForChild("CameraWagon"))

local joueur = Players.LocalPlayer
local evenement = ReplicatedStorage:WaitForChild("WagonTransition")
local gui = Instance.new("ScreenGui")
gui.Name = "TransitionWagon"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Enabled = false
gui.Parent = joueur:WaitForChild("PlayerGui")

local fond = Instance.new("Frame")
fond.Name = "Fond"
fond.Size = UDim2.fromScale(1, 1)
fond.BackgroundColor3 = Color3.new(1, 1, 1)
fond.BackgroundTransparency = 1
fond.BorderSizePixel = 0
fond.Parent = gui
local degrade = Instance.new("UIGradient")
degrade.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 39)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(50, 32, 26)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 23, 19)),
})
degrade.Rotation = 35
degrade.Parent = fond

local contenu = Instance.new("Frame")
contenu.Name = "Contenu"
contenu.BackgroundTransparency = 1
contenu.Size = UDim2.fromScale(1, 1)
contenu.Parent = fond
local panneau = Instance.new("Frame")
panneau.Name = "PanneauMine"
panneau.AnchorPoint = Vector2.new(0.5, 0.5)
panneau.Position = UDim2.fromScale(0.5, 0.5)
panneau.Size = UDim2.fromScale(0.8, 0.42)
panneau.BackgroundColor3 = Color3.fromRGB(62, 41, 30)
panneau.BorderSizePixel = 0
panneau.Parent = contenu
local limites = Instance.new("UISizeConstraint")
limites.MaxSize = Vector2.new(620, 280)
limites.Parent = panneau
local coins = Instance.new("UICorner")
coins.CornerRadius = UDim.new(0, 16)
coins.Parent = panneau
local contour = Instance.new("UIStroke")
contour.Thickness = 3
contour.Color = Color3.fromRGB(199, 147, 67)
contour.Parent = panneau

local minerai = Instance.new("Frame")
minerai.Name = "Cristal"
minerai.AnchorPoint = Vector2.new(0.5, 0.5)
minerai.Position = UDim2.fromScale(0.5, 0.22)
minerai.Size = UDim2.fromOffset(26, 26)
minerai.Rotation = 45
minerai.BackgroundColor3 = Color3.fromRGB(83, 207, 224)
minerai.BorderSizePixel = 0
minerai.Parent = panneau
local contourCristal = Instance.new("UIStroke")
contourCristal.Color = Color3.fromRGB(179, 245, 245)
contourCristal.Thickness = 2
contourCristal.Parent = minerai

local texte = Instance.new("TextLabel")
texte.Name = "Chargement"
texte.AnchorPoint = Vector2.new(0.5, 0.5)
texte.Position = UDim2.fromScale(0.5, 0.48)
texte.Size = UDim2.new(0.9, 0, 0.22, 0)
texte.BackgroundTransparency = 1
texte.Text = "Direction la mine !"
texte.TextColor3 = Color3.fromRGB(237, 210, 155)
texte.Font = Enum.Font.GothamBold
texte.TextScaled = true
texte.Parent = panneau
local limiteTexte = Instance.new("UITextSizeConstraint")
limiteTexte.MaxTextSize = 30
limiteTexte.Parent = texte
local sousTitre = Instance.new("TextLabel")
sousTitre.Name = "SousTitre"
sousTitre.AnchorPoint = Vector2.new(0.5, 0.5)
sousTitre.Position = UDim2.fromScale(0.5, 0.66)
sousTitre.Size = UDim2.new(0.85, 0, 0.12, 0)
sousTitre.BackgroundTransparency = 1
sousTitre.Text = "Le wagon est en route..."
sousTitre.TextColor3 = Color3.fromRGB(199, 183, 158)
sousTitre.Font = Enum.Font.GothamMedium
sousTitre.TextScaled = true
sousTitre.Parent = panneau
local limiteSousTitre = Instance.new("UITextSizeConstraint")
limiteSousTitre.MaxTextSize = 17
limiteSousTitre.Parent = sousTitre
local ligne = Instance.new("Frame")
ligne.Name = "RailChargement"
ligne.AnchorPoint = Vector2.new(0.5, 0.5)
ligne.Position = UDim2.fromScale(0.5, 0.82)
ligne.Size = UDim2.new(0.55, 0, 0, 5)
ligne.BackgroundColor3 = Color3.fromRGB(30, 24, 23)
ligne.BorderSizePixel = 0
ligne.ClipsDescendants = true
ligne.Parent = panneau
local chariot = Instance.new("Frame")
chariot.Name = "Wagon"
chariot.Size = UDim2.fromScale(0.25, 1)
chariot.BackgroundColor3 = Color3.fromRGB(245, 182, 78)
chariot.BorderSizePixel = 0
chariot.Parent = ligne
local animationChargement: Tween? = nil
local fondus = {}
local numeroTrajet = 0
local DUREE_APPARITION = 1.5
local DUREE_DISPARITION = 0.45
-- Les éléments et contours sont fondus individuellement.
local elements = {}
for _, objet in contenu:GetDescendants() do
    if objet:IsA("GuiObject") then
        table.insert(elements, {objet = objet, propriete = "BackgroundTransparency", visible = objet.BackgroundTransparency})
    elseif objet:IsA("UIStroke") then
        table.insert(elements, {objet = objet, propriete = "Transparency", visible = objet.Transparency})
    end
    if objet:IsA("TextLabel") or objet:IsA("TextButton") then
        table.insert(elements, {objet = objet, propriete = "TextTransparency", visible = objet.TextTransparency})
    end
end
local function annulerFondus()
    for _, fondu in fondus do fondu:Cancel() end
    table.clear(fondus)
end
local function animer(transparence)
    annulerFondus()
    local duree = if transparence == 0 then DUREE_APPARITION else DUREE_DISPARITION
    local info = TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local function lancer(objet, propriete, valeur)
        local fondu = TweenService:Create(objet, info, {[propriete] = valeur})
        table.insert(fondus, fondu)
        fondu:Play()
    end
    lancer(fond, "BackgroundTransparency", transparence)
    for _, element in elements do
        lancer(element.objet, element.propriete, if transparence == 0 then element.visible else 1)
    end
end
local function masquerImmediatement()
    fond.BackgroundTransparency = 1
    for _, element in elements do element.objet[element.propriete] = 1 end
end
evenement.OnClientEvent:Connect(function(action, sens)
	if action == "depart" then
		numeroTrajet += 1
		local trajet = numeroTrajet
		CameraWagon.demarrer()
		annulerFondus()
		if animationChargement then animationChargement:Cancel() end
		gui.Enabled = true
		masquerImmediatement()
		texte.Text = if sens == "aller" then "Direction la mine !" elseif sens == "retour" then "Direction la gare !" else "Voyage en cours..."
		chariot.Position = UDim2.fromScale(0, 0)
		animationChargement = TweenService:Create(chariot, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.fromScale(0.75, 0)})
		task.delay(2, function()
			if trajet ~= numeroTrajet then return end
			animer(0)
			animationChargement:Play()
			task.delay(DUREE_APPARITION, function()
				if trajet == numeroTrajet then CameraWagon.restaurer() end
			end)
		end)
	elseif action == "arrivee" or action == "annulation" then
		numeroTrajet += 1
		local trajet = numeroTrajet
		CameraWagon.restaurer()
		animer(1)
		task.delay(DUREE_DISPARITION, function()
			if trajet == numeroTrajet then
				gui.Enabled = false
				if animationChargement then animationChargement:Cancel() end
			end
		end)
	end
end)

joueur.CharacterRemoving:Connect(function()
	numeroTrajet += 1
	CameraWagon.restaurer()
	annulerFondus()
	if animationChargement then animationChargement:Cancel() end
	gui.Enabled = false
end)
