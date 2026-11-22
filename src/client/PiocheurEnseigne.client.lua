-- Nain de l'enseigne « LA GRANDE MINE » : lève sa pioche puis frappe le dernier E, étincelles à chaque coup.
-- Le modèle (tag « Piocheur ») vient de Batiments.nainPiocheur : bras « BrasPioche » pivotant à l'épaule.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DISTANCE = 260 -- au-delà, on ne calcule rien
local LEVE, FRAPPE = math.rad(105), math.rad(-22)
local joueur = Players.LocalPlayer

local nains = {}

local function suivre(m: Instance)
	if not m:IsA("Model") or nains[m] then return end
	local bras = m:WaitForChild("BrasPioche", 10)
	local impact = m:WaitForChild("Impact", 10)
	if not (bras and bras:IsA("Model")) then return end
	nains[m] = {
		bras = bras,
		base = bras:GetPivot(),
		etincelles = impact and impact:FindFirstChildOfClass("ParticleEmitter"),
		decalage = math.random() * 2,
		dernierCoup = -1,
	}
end

for _, m in CollectionService:GetTagged("Piocheur") do task.spawn(suivre, m) end
CollectionService:GetInstanceAddedSignal("Piocheur"):Connect(function(m) task.spawn(suivre, m) end)
CollectionService:GetInstanceRemovedSignal("Piocheur"):Connect(function(m) nains[m] = nil end)

local function douce(t) return t * t * (3 - 2 * t) end

RunService.Heartbeat:Connect(function()
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	local temps = os.clock()
	for m, n in nains do
		if not m.Parent then nains[m] = nil continue end
		if racine and (racine.Position - n.base.Position).Magnitude > DISTANCE then continue end
		-- cycle d'un coup : lever (lent), frapper (vif), rester au contact, revenir légèrement
		local duree = 1.35
		local cycle = (temps + n.decalage) / duree
		local p = cycle % 1
		local angle
		if p < 0.5 then
			angle = FRAPPE + (LEVE - FRAPPE) * douce(p / 0.5)
		elseif p < 0.62 then
			angle = LEVE + (FRAPPE - LEVE) * ((p - 0.5) / 0.12) ^ 2
		elseif p < 0.8 then
			angle = FRAPPE
		else
			angle = FRAPPE + math.rad(12) * douce((p - 0.8) / 0.2)
		end
		n.bras:PivotTo(n.base * CFrame.Angles(angle, 0, 0))
		local coup = math.floor(cycle)
		if p >= 0.62 and coup ~= n.dernierCoup then
			n.dernierCoup = coup
			if n.etincelles then n.etincelles:Emit(14) end
		end
	end
end)
