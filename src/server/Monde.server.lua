-- Construit la carte au lancement du serveur (sauf si elle a déjà été figée dans la place).
-- Les joueurs n'apparaissent qu'une fois la carte prête.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Carte figée : on la garde, sauf si les modèles 3D importés ont changé depuis
local carte = workspace:FindFirstChild("Carte")
if carte then
	local monde = ServerStorage:WaitForChild("Monde")
	local Modeles3D = require(monde:WaitForChild("Modeles3D"))
	if (carte:GetAttribute("Modeles3D") or 0) == Modeles3D.signature() then
		local village = carte:FindFirstChild("Village")
		if village then
			local Village = require(monde:WaitForChild("Village"))
			Village.preparerFontaine(village)
			Village.preparerToits(village)
			Village.preparerSentiers(village)
		end
		local mine = carte:FindFirstChild("Mine")
		if mine then require(monde:WaitForChild("Mine")).preparerVoie(mine) end
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
