-- Pioches · SCRIPT CLIENT
-- Où : StarterPlayer > StarterPlayerScripts > LocalScript
-- Ce que seul ton écran voit quand une pioche frappe : secousse de caméra et petit flash.
-- (L'aura de chaque pioche est celle réglée dans l'Atelier 3D : AuraPioche côté serveur.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local fxEvent = ReplicatedStorage:WaitForChild("PiocheFX")

local BLANC = Color3.new(1, 1, 1)

-- ================= Secousse et flash =================

local secousse = 0

local flash = Instance.new("ColorCorrectionEffect")
flash.Name = "PiocheFlash"
flash.Parent = Lighting

local function eclair(force: number, couleur: Color3)
	flash.TintColor = BLANC:Lerp(couleur, math.clamp(force * 0.25, 0, 0.6))
	flash.Brightness = 0.05 * force
	flash.Contrast = 0.06 * force
	TweenService:Create(flash, TweenInfo.new(0.3 + 0.1 * force), {
		TintColor = BLANC,
		Brightness = 0,
		Contrast = 0,
	}):Play()
end

fxEvent.OnClientEvent:Connect(function(genre: string, position: Vector3, force: number, couleur: Color3?)
	local camera = workspace.CurrentCamera
	local distance = (position - camera.CFrame.Position).Magnitude
	local proche = math.clamp(1 - distance / 80, 0, 1)
	if proche <= 0 then return end
	secousse = math.max(secousse, force * proche)
	eclair(force * proche, couleur or Color3.fromRGB(255, 220, 160))
end)

RunService:BindToRenderStep("PiocheSecousse", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if secousse < 0.01 then
		secousse = 0
		return
	end
	local camera = workspace.CurrentCamera
	local t = os.clock() * 30
	local rx = math.noise(t, 0.31) * secousse * 0.04
	local ry = math.noise(0.73, t) * secousse * 0.04
	local rz = math.noise(t, t * 0.5) * secousse * 0.02
	camera.CFrame = camera.CFrame * CFrame.Angles(rx, ry, rz)
	secousse *= math.exp(-dt * 6)
end)
