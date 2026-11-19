-- Affiche le décompte de téléportation (attribut "DecompteTP" posé par le serveur).
local TweenService = game:GetService("TweenService")
local joueur = game:GetService("Players").LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "DecompteTP"
gui.ResetOnSpawn = false
gui.Enabled = false
local t = Instance.new("TextLabel")
t.AnchorPoint = Vector2.new(0.5, 0.5)
t.Position = UDim2.fromScale(0.5, 0.35)
t.Size = UDim2.fromScale(0.2, 0.2)
t.BackgroundTransparency = 1
t.Font = Enum.Font.GothamBlack
t.TextScaled = true
t.TextColor3 = Color3.new(1, 1, 1)
t.TextStrokeTransparency = 0.2
t.Parent = gui
local echelle = Instance.new("UIScale")
echelle.Parent = t
gui.Parent = joueur:WaitForChild("PlayerGui")

local function maj()
	local n = joueur:GetAttribute("DecompteTP")
	gui.Enabled = n ~= nil
	if n then
		t.Text = tostring(n)
		echelle.Scale = 1.4
		TweenService:Create(echelle, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end
end
joueur:GetAttributeChangedSignal("DecompteTP"):Connect(maj)
maj()
