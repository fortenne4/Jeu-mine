-- Ambiance de la caverne de cristal · SCRIPT CLIENT
--  • Eau : sous terre (zone de la mine), l'eau du Terrain prend les réglages du Lac des Lueurs (turquoise, claire,
--    reflets doux) pour qu'on voie la profondeur du bassin ; valeurs d'origine remises en remontant. Laisse la main
--    à AmbianceGrotte.client.lua dans les grottes profondes (attribut Lighting « GrotteActive »).
--  • Textes flottants (tag « TexteFlottant », ex. « TUNNELS PRIVÉS » de CaverneDecor) : léger flottement local.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local joueur = Players.LocalPlayer
local terrain: any = workspace.Terrain

-- Zone de la mine souterraine (= Disposition.ZONE_MINE, sous le niveau de la vallée)
local ZONE_MIN, ZONE_MAX = Vector3.new(-112, -116, -516), Vector3.new(112, -20, -200)
local EAU = {WaterColor = Color3.fromRGB(24, 160, 176), WaterTransparency = 0.5, WaterReflectance = 0.12,
	WaterWaveSize = 0.12, WaterWaveSpeed = 9}
local origine = nil -- réglages de la vallée pendant qu'on est sous terre

local function dansMine(p: Vector3): boolean
	return p.X > ZONE_MIN.X and p.X < ZONE_MAX.X and p.Y > ZONE_MIN.Y and p.Y < ZONE_MAX.Y and p.Z > ZONE_MIN.Z and p.Z < ZONE_MAX.Z
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if Lighting:GetAttribute("GrotteActive") then continue end
		local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
		local dedans = racine ~= nil and dansMine(racine.Position)
		if dedans and not origine then
			origine = {}
			for p, v in EAU do
				origine[p] = terrain[p]
				terrain[p] = v
			end
		elseif not dedans and origine then
			for p, v in origine do
				terrain[p] = v
			end
			origine = nil
		end
	end
end)

-- ================= Textes flottants =================
local FLOTTE = TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local tweens = {}

local function flotter(p: Instance)
	if not p:IsA("BasePart") or tweens[p] then return end
	local t = TweenService:Create(p, FLOTTE, {CFrame = p.CFrame + Vector3.new(0, 0.6, 0)})
	tweens[p] = t
	t:Play()
end

local function arreter(p: Instance)
	local t = tweens[p]
	if t then
		t:Cancel()
		tweens[p] = nil
	end
end

CollectionService:GetInstanceAddedSignal("TexteFlottant"):Connect(flotter)
CollectionService:GetInstanceRemovedSignal("TexteFlottant"):Connect(arreter)
for _, p in CollectionService:GetTagged("TexteFlottant") do flotter(p) end
