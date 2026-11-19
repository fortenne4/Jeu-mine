--!strict
-- Vie des joueurs · SCRIPT SERVEUR : PV max fixés à chaque apparition du personnage.
-- Le HUD client (Hud.client) lit Humanoid.MaxHealth : il affichera automatiquement PV_MAX.

local Players = game:GetService("Players")

local PV_MAX = 150

local function appliquer(perso: Model)
	local h = perso:WaitForChild("Humanoid", 10)
	if h and h:IsA("Humanoid") and h.Parent == perso then
		h.MaxHealth = PV_MAX
		h.Health = PV_MAX
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
