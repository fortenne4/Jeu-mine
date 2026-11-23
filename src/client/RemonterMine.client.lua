--!strict
-- Bouton « REMONTER » de la mine privée · SCRIPT CLIENT.
-- Apparaît à droite de l'écran dès que le joueur est descendu sous le sol de la galerie dans sa mine privée
-- (attribut joueur « ProfondeurMine », tenu par RemonterMine.server) et affiche la profondeur.
-- Un clic demande au serveur de remonter tout en haut de la mine (point d'apparition).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local joueur = Players.LocalPlayer
local evenement = ReplicatedStorage:WaitForChild("RemonterMine") :: RemoteEvent

local OMBRE = Color3.fromRGB(16, 8, 4)
local HORS_ECRAN = UDim2.new(1, 220, 0.6, 0)
local EN_PLACE = UDim2.new(1, -16, 0.6, 0)

local gui = creer("ScreenGui", {Name = "RemonterMine", ResetOnSpawn = false, DisplayOrder = 7,
	Parent = joueur:WaitForChild("PlayerGui")})

local bouton = creer("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = HORS_ECRAN,
	Size = UDim2.fromOffset(190, 62), BackgroundColor3 = T.Bois, Visible = false, Parent = gui},
	{coin(0.2), trait(OMBRE, 3), UI.degrade(T.CarteClaire, T.BoisSombre, 90)})
creer("UIStroke", {Thickness = 1.5, Color = T.OrFonce, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bouton})
UI.reactif(bouton, 1.05)

-- pastille ronde avec une flèche vers le haut (dessinée en blocs)
local pastille = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = T.Or, Parent = bouton}, {coin(1), trait(OMBRE, 2), UI.degrade(Color3.fromRGB(255, 236, 170), T.OrFonce, 90)})
local fleche = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1, Parent = pastille})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(7, 18),
	BackgroundColor3 = OMBRE, BorderSizePixel = 0, Parent = fleche}, {coin(0.4)})
for _, sens in {-1, 1} do
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, sens * 6, 0.36, 3), Size = UDim2.fromOffset(7, 17),
		Rotation = sens * 45, BackgroundColor3 = OMBRE, BorderSizePixel = 0, Parent = fleche}, {coin(0.4)})
end

local titre = texte({Text = "[H] REMONTER", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(62, 9), Size = UDim2.fromOffset(122, 24), Parent = bouton}, 22)
UI.dore(titre, 2)
local sousTitre = texte({Text = "Profondeur 0 m", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
	TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(63, 36), Size = UDim2.fromOffset(120, 16), Parent = bouton}, 15)
creer("UIStroke", {Thickness = 1.5, Color = OMBRE, Parent = sousTitre})

-- ===== Apparition / disparition =====
local visible = false
local function montrer(oui: boolean)
	if oui == visible then return end
	visible = oui
	if oui then
		bouton.Visible = true
		bouton.Position = HORS_ECRAN
		TweenService:Create(bouton, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = EN_PLACE}):Play()
		UI.jouer("ouvrir", 1.2)
	else
		local t = TweenService:Create(bouton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = HORS_ECRAN})
		t.Completed:Once(function()
			if not visible then bouton.Visible = false end
		end)
		t:Play()
	end
end

local function maj()
	local p = joueur:GetAttribute("ProfondeurMine")
	if type(p) == "number" then
		sousTitre.Text = string.format("Profondeur %d m", p)
		montrer(true)
	else
		montrer(false)
	end
end
joueur:GetAttributeChangedSignal("ProfondeurMine"):Connect(maj)
maj()

-- la flèche monte et descend doucement pour attirer l'œil
task.spawn(function()
	while true do
		if visible then
			TweenService:Create(fleche, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = UDim2.fromScale(0.5, 0.42)}):Play()
			task.wait(0.5)
			TweenService:Create(fleche, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = UDim2.fromScale(0.5, 0.5)}):Play()
			task.wait(0.5)
		else
			task.wait(0.3)
		end
	end
end)

local occupe = false
local function remonter()
	if occupe or not visible then return end
	occupe = true
	UI.jouer("clic", 1.1)
	UI.pop(bouton, 0.9)
	evenement:FireServer()
	task.delay(2, function() occupe = false end)
end
bouton.Activated:Connect(remonter)
-- touche H : en 1re personne la souris est bloquée au centre (Alt la libère), la touche évite d'avoir à cliquer
game:GetService("UserInputService").InputBegan:Connect(function(input, traite)
	if not traite and input.KeyCode == Enum.KeyCode.H then remonter() end
end)
