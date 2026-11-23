--!strict
-- Vie des joueurs · SCRIPT SERVEUR : PV max fixés à chaque apparition du personnage.
-- Le HUD client (Hud.client) lit Humanoid.MaxHealth : il affichera automatiquement PV_MAX.
-- Régénération (remplace le script « Health » par défaut de Roblox) : REGEN_COMBAT par seconde pendant le combat,
-- REGEN_REPOS par seconde après DELAI_REPOS s sans perdre de PV.

local Players = game:GetService("Players")

local PV_MAX = 150
local REGEN_COMBAT = 0.01 -- 1 % des PV max / s (comme Roblox par défaut)
local REGEN_REPOS = 0.05 -- 5 % / s hors combat : ~20 s pour remonter de 0 au max
local DELAI_REPOS = 5 -- s sans dégât avant la régénération rapide
local PAS = 0.25

local suivis: {[Humanoid]: number} = {} -- humanoïde → os.clock() du dernier dégât

local function appliquer(perso: Model)
	local h = perso:WaitForChild("Humanoid", 10)
	if h and h:IsA("Humanoid") and h.Parent == perso then
		h.MaxHealth = PV_MAX
		h.Health = PV_MAX
		local defaut = perso:FindFirstChild("Health") -- régénération Roblox par défaut : remplacée ci-dessous
		if defaut and defaut:IsA("Script") then defaut:Destroy() end
		local avant = h.Health
		suivis[h] = 0
		h.HealthChanged:Connect(function(pv)
			if pv < avant then suivis[h] = os.clock() end
			avant = pv
		end)
		h.AncestryChanged:Connect(function()
			if not h:IsDescendantOf(workspace) then suivis[h] = nil end
		end)
	end
end

local function lier(joueur: Player)
	joueur.CharacterAdded:Connect(appliquer)
	if joueur.Character then
		task.spawn(appliquer, joueur.Character)
	end
end

Players.PlayerAdded:Connect(lier)
for _, j in Players:GetPlayers() do
	task.spawn(lier, j)
end

task.spawn(function()
	while true do
		local maintenant = os.clock()
		for h, dernier in suivis do
			if h.Parent and h.Health > 0 and h.Health < h.MaxHealth then
				local taux = if maintenant - dernier >= DELAI_REPOS then REGEN_REPOS else REGEN_COMBAT
				h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * taux * PAS)
			end
		end
		task.wait(PAS)
	end
end)
