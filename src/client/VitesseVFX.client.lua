local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local joueur = Players.LocalPlayer
local N, R_MIN, OPACITE, FONDU = 34, 0.48, 0.65, 0.2
local rand, sin, cos, pi, clamp = math.random, math.sin, math.cos, math.pi, math.clamp

local gui = Instance.new("ScreenGui")
gui.Name = "VitesseVFX"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = joueur:WaitForChild("PlayerGui")

local degrade = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local cadres, ang, r0, r, v, long, ep = {}, {}, {}, {}, {}, {}, {}

local function relance(i, debut)
	ang[i] = rand() * 2 * pi
	r0[i] = 1 + rand() * 0.2
	r[i] = if debut then R_MIN + rand() * (r0[i] - R_MIN) else r0[i]
	v[i] = 0.9 + rand() * 1.1
	long[i] = 0.1 + rand() * 0.2
	ep[i] = 1 + rand() * 1.5
	cadres[i].Rotation = math.deg(ang[i])
end

for i = 1, N do
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	f.Visible = false
	local g = Instance.new("UIGradient")
	g.Transparency = degrade
	g.Parent = f
	f.Parent = gui
	cadres[i] = f
	relance(i, true)
end

local racine: BasePart? = nil
local function surPerso(c)
	racine = c:WaitForChild("HumanoidRootPart", 10) :: BasePart?
end
if joueur.Character then task.spawn(surPerso, joueur.Character) end
joueur.CharacterAdded:Connect(surPerso)

local alpha, conn = 0, nil

local function etape(dt)
	local court = joueur:GetAttribute("Court") == true
	local k = 0
	if racine and racine.Parent then
		local vel = racine.AssemblyLinearVelocity
		k = clamp((math.sqrt(vel.X * vel.X + vel.Z * vel.Z) - 4) / 20, 0, 1)
	end
	local cible = if court then k else 0
	alpha += clamp(cible - alpha, -dt / FONDU, dt / FONDU)

	if alpha <= 0 and not court then
		for i = 1, N do cadres[i].Visible = false end
		conn:Disconnect()
		conn = nil
		return
	end

	local taille = workspace.CurrentCamera.ViewportSize
	local cx, cy = taille.X * 0.5, taille.Y * 0.5
	local D = taille.Magnitude * 0.5
	local actifs = math.ceil(N * alpha)
	local vit = dt * (0.6 + alpha)

	for i = 1, N do
		local f = cadres[i]
		if i > actifs then
			f.Visible = false
		else
			r[i] -= v[i] * vit
			if r[i] <= R_MIN then relance(i, false) end
			local ri = r[i]
			local u = (r0[i] - ri) / (r0[i] - R_MIN)
			local a = ang[i]
			f.Position = UDim2.fromOffset(cx + cos(a) * ri * D, cy + sin(a) * ri * D)
			f.Size = UDim2.fromOffset(long[i] * D * (0.5 + alpha * 0.5), ep[i])
			f.BackgroundTransparency = 1 - sin(pi * u) * OPACITE * alpha
			f.Visible = true
		end
	end
end

local function verifie()
	if joueur:GetAttribute("Court") == true and not conn then
		conn = RunService.RenderStepped:Connect(etape)
	end
end
joueur:GetAttributeChangedSignal("Court"):Connect(verifie)
verifie()
