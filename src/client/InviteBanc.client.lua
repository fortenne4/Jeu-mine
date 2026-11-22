-- Petite bulle « E S'asseoir » pour les bancs de la place (l'invite Roblox par défaut est trop grande).
-- Le serveur crée l'invite « AsseoirBanc » ; on la dessine ici, en compact, au-dessus du siège.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local joueur = Players.LocalPlayer
local BOIS = Color3.fromRGB(58, 40, 29)
local OR = Color3.fromRGB(242, 198, 96)
local PARCHEMIN = Color3.fromRGB(240, 226, 190)
local RAPIDE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local bulles: {[ProximityPrompt]: BillboardGui} = {}

local function toucheAffichee(invite: ProximityPrompt, typeEntree: Enum.ProximityPromptInputType): string
	if typeEntree == Enum.ProximityPromptInputType.Gamepad then
		return (invite.GamepadKeyCode.Name:gsub("^Button", ""))
	elseif typeEntree == Enum.ProximityPromptInputType.Touch then
		return "👆"
	end
	local s = UserInputService:GetStringForKeyCode(invite.KeyboardKeyCode)
	return if s ~= "" then s else invite.KeyboardKeyCode.Name
end

local function montrer(invite: ProximityPrompt, typeEntree: Enum.ProximityPromptInputType)
	if invite.Name ~= "AsseoirBanc" or bulles[invite] then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "InviteBanc"
	bb.Adornee = invite.Parent
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(104, 28)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	bb.ResetOnSpawn = false

	local carte = Instance.new("TextButton")
	carte.Name = "Carte"
	carte.Text = ""
	carte.AutoButtonColor = false
	carte.AnchorPoint = Vector2.new(0.5, 0.5)
	carte.Position = UDim2.fromScale(0.5, 0.5)
	carte.Size = UDim2.fromScale(1, 1)
	carte.BackgroundColor3 = BOIS
	carte.BackgroundTransparency = 0.15
	carte.Parent = bb
	Instance.new("UICorner", carte).CornerRadius = UDim.new(0, 7)
	local trait = Instance.new("UIStroke", carte)
	trait.Color = OR
	trait.Thickness = 1.5
	trait.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local echelle = Instance.new("UIScale", carte)
	echelle.Scale = 0.6

	local touche = Instance.new("TextLabel")
	touche.Name = "Touche"
	touche.AnchorPoint = Vector2.new(0, 0.5)
	touche.Position = UDim2.new(0, 4, 0.5, 0)
	touche.Size = UDim2.fromOffset(20, 20)
	touche.BackgroundColor3 = OR
	touche.Font = Enum.Font.GothamBlack
	touche.TextColor3 = BOIS
	touche.TextSize = 13
	touche.Text = toucheAffichee(invite, typeEntree)
	touche.Parent = carte
	Instance.new("UICorner", touche).CornerRadius = UDim.new(0, 5)

	local action = Instance.new("TextLabel")
	action.BackgroundTransparency = 1
	action.Position = UDim2.new(0, 30, 0, 0)
	action.Size = UDim2.new(1, -34, 1, 0)
	action.Font = Enum.Font.GothamBold
	action.TextColor3 = PARCHEMIN
	action.TextSize = 13
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Text = invite.ActionText
	action.Parent = carte

	carte.Activated:Connect(function()
		invite:InputHoldBegin()
		invite:InputHoldEnd()
	end)
	bb.Parent = joueur:WaitForChild("PlayerGui")
	TweenService:Create(echelle, RAPIDE, {Scale = 1}):Play()
	bulles[invite] = bb
end

local function cacher(invite: ProximityPrompt)
	local bb = bulles[invite]
	if not bb then return end
	bulles[invite] = nil
	bb:Destroy()
end

-- L'invite arrive en style Default (visible même si ce script plante) : on la passe en Custom ici.
local function adopter(d: Instance)
	if d:IsA("ProximityPrompt") and d.Name == "AsseoirBanc" then
		d.Style = Enum.ProximityPromptStyle.Custom
	end
end
for _, d in workspace:GetDescendants() do
	adopter(d)
end
workspace.DescendantAdded:Connect(adopter)

ProximityPromptService.PromptShown:Connect(montrer)
ProximityPromptService.PromptHidden:Connect(cacher)
