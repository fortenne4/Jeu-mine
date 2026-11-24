-- Brûlure · MODULE SERVEUR (ServerScriptService › Jeu › Brulure)
-- Effet « en feu » qui continue après le coup : flammes des failles (DangersGrotte), Roi déchu…
--   Brulure.appliquer(joueur, duree?) : le joueur brûle pendant `duree` secondes (prolonge, ne cumule pas).
-- Pendant la brûlure : DEGATS toutes les PERIODE s (réduits par « ResistanceFeu »), attribut joueur
-- « EnFeu » = true (lu par MachinesGrotte.client pour le voile orange et les braises).

local Players = game:GetService("Players")

local Brulure = {}

Brulure.DUREE = 4 -- secondes de brûlure par défaut
Brulure.DEGATS = 3 -- par tic
Brulure.PERIODE = 0.5

local fin: {[Player]: number} = {}

function Brulure.degatsFeu(joueur: Player, degats: number): number
	local r = joueur:GetAttribute("ResistanceFeu")
	return degats * (1 - (if type(r) == "number" then math.clamp(r, 0, 0.9) else 0))
end

function Brulure.appliquer(joueur: Player, duree: number?)
	local t = os.clock() + (duree or Brulure.DUREE)
	if not fin[joueur] or fin[joueur] < t then
		fin[joueur] = t
	end
	if joueur:GetAttribute("EnFeu") ~= true then
		joueur:SetAttribute("EnFeu", true)
	end
end

function Brulure.estEnFeu(joueur: Player): boolean
	return fin[joueur] ~= nil
end

task.spawn(function()
	while true do
		task.wait(Brulure.PERIODE)
		local maintenant = os.clock()
		for joueur, t in fin do
			local perso = joueur.Character
			local hum = perso and perso:FindFirstChildOfClass("Humanoid")
			if maintenant >= t or not hum or hum.Health <= 0 or not joueur.Parent then
				fin[joueur] = nil
				if joueur.Parent then
					joueur:SetAttribute("EnFeu", false)
				end
			else
				hum:TakeDamage(Brulure.degatsFeu(joueur, Brulure.DEGATS))
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(j)
	fin[j] = nil
end)

return Brulure
