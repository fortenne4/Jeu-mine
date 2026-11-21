-- Le serveur notifie tous les clients du lancer du conducteur vers le levier.
-- La pierre est déplacée par le serveur ; chaque client anime localement le bras R15.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local IK = require(script.Parent:WaitForChild("RigIK"))
local CameraWagon = require(script.Parent:WaitForChild("CameraWagon"))
local evenement = ReplicatedStorage:WaitForChild("WagonLancerPierre") :: RemoteEvent

local lancers = {}

local function finir(personnage, etat)
	if lancers[personnage] ~= etat then return end
	lancers[personnage] = nil
	if etat.connexion then etat.connexion:Disconnect() end
	for _, bras in etat.bras do IK.relacherBras(bras) end
	if personnage.Parent then personnage:SetAttribute("WagonLancerGeste", nil) end
end

evenement.OnClientEvent:Connect(function(personnage, cible, duree)
	if typeof(personnage) ~= "Instance" or not personnage:IsA("Model") or typeof(cible) ~= "Vector3" or typeof(duree) ~= "number" then return end
	if Players.LocalPlayer.Character == personnage then CameraWagon.demarrer() end
	local precedent = lancers[personnage]
	if precedent then finir(personnage, precedent) end
	local brasDroit = IK.preparerBras(personnage, "Right")
	local brasGauche = IK.preparerBras(personnage, "Left")
	local tete = personnage:FindFirstChild("Head")
	if not brasDroit or not brasGauche or not IK.brasValide(brasDroit) or not IK.brasValide(brasGauche) or not tete or not tete:IsA("BasePart") then return end
	brasDroit.taille = nil -- Ne pas modifier l'animation du torse du conducteur.
	duree = math.clamp(duree, 0.25, 3)
	local etat = {bras = {brasDroit, brasGauche}, connexion = nil}
	lancers[personnage] = etat
	personnage:SetAttribute("WagonLancerGeste", true)
	local debut = os.clock()
	-- Les AnimationConstraint sont résolues pendant la simulation : écrire les poses
	-- avant celle-ci, sinon les attachments changent mais les bras ne suivent pas.
	etat.connexion = RunService.PreSimulation:Connect(function()
		local u = (os.clock() - debut) / duree
		if u >= 1 or not personnage.Parent or not tete.Parent or not IK.brasValide(brasDroit) or not IK.brasValide(brasGauche) then
			finir(personnage, etat)
			return
		end
		local direction = brasDroit.torse.CFrame:VectorToObjectSpace(cible - brasDroit.torse.Position)
		if direction.Magnitude < 0.01 then direction = Vector3.new(0, 0, -1) end
		direction = direction.Unit
		-- Les mains rejoignent la pierre au-dessus de la tête, puis la lancent.
		local avance = IK.lisse((u - 0.50) / 0.16)
		local poids = math.min(IK.lisse(u / 0.16), 1 - IK.lisse((u - 0.76) / 0.24))
		for i, bras in etat.bras do
			local cote = if i == 1 then 1 else -1
			local origine = bras.epaule.c0Origine.Position
			local longueur = bras.l1 + bras.l2
			local positionMain = tete.Position + tete.CFrame.UpVector * 1.0 + tete.CFrame.RightVector * (cote * 0.3)
			local preparation = bras.torse.CFrame:PointToObjectSpace(positionMain)
			local extension = origine + direction * (longueur * 0.9)
			IK.poserBras(bras, preparation:Lerp(extension, avance), Vector3.new(cote, -0.2, 0.35), direction, Vector3.new(0, 1, 0), CFrame.identity, poids)
		end
	end)
	-- Le rendu peut être suspendu si la fenêtre est minimisée : relâcher les bras.
	task.delay(duree + 0.1, function() finir(personnage, etat) end)
end)

Players.LocalPlayer.CharacterRemoving:Connect(function(personnage)
	local etat = lancers[personnage]
	if etat then finir(personnage, etat) end
end)
