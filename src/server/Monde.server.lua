-- Construit la carte au lancement du serveur (sauf si elle a déjà été figée dans la place).
-- Les joueurs n'apparaissent qu'une fois la carte prête.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Carte figée : on la garde, sauf si les modèles 3D importés ont changé depuis
local carte = workspace:FindFirstChild("Carte")
if carte then
	local Modeles3D = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Modeles3D"))
	if (carte:GetAttribute("Modeles3D") or 0) == Modeles3D.signature() then
		workspace:SetAttribute("MondeConstruit", true)
		return
	end
	print("[Monde] Les modèles 3D ont changé : reconstruction de la carte")
end

Players.CharacterAutoLoads = false

local Monde = require(ServerStorage:WaitForChild("Monde"))
local ok, erreur = pcall(Monde.construire)
if not ok then
	warn("[Monde] Erreur pendant la construction : " .. tostring(erreur))
end
workspace:SetAttribute("MondeConstruit", true)

Players.CharacterAutoLoads = true
for _, joueur in Players:GetPlayers() do
	if not joueur.Character then
		task.spawn(function()
			joueur:LoadCharacter()
		end)
	end
end
