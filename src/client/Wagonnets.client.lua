-- Montée dans le wagon en saut d'obstacle (speed vault) : main d'appui collée au rebord, bras libre
-- en balancier, jambes groupées qui balaient au-dessus du rebord, puis réception assise.
-- Chaque client pose les membres (R15, AnimationConstraint) ; le serveur déplace la racine aux mêmes phases.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local IK = require(script.Parent:WaitForChild("RigIK"))
local evenement = ReplicatedStorage:WaitForChild("EntreeWagonAnimation") :: RemoteEvent

-- Inverser ces signes si les cuisses ou les genoux plient dans le mauvais sens sur le rig.
local SENS_HANCHE = 1
local SENS_GENOU = -1
-- Clés des jambes : {u, flexion hanche, flexion genou, balayage latéral} (radians).
local JAMBES = {
	{0, 0, 0, 0},
	{0.18, 0.4, 0.7, 0}, -- impulsion
	{0.32, 1.3, 1.9, 0.35}, -- jambes groupées
	{0.5, 1.5, 2.0, 0.7}, -- passage au-dessus du rebord
	{0.68, 1.4, 1.6, 0.25},
	{0.85, 1.45, 1.45, 0}, -- réception assise
	{1, 1.45, 1.45, 0},
}
local POLE_APPUI = {Left = Vector3.new(-1, -0.5, 0), Right = Vector3.new(1, -0.5, 0)}
local BAS, AVANT = Vector3.new(0, -1, 0), Vector3.new(0, 0, 1)
local sauts = {}

local function jambes(u: number): (number, number, number)
	local i = 1
	while i < #JAMBES - 1 and u > JAMBES[i + 1][1] do i += 1 end
	local a, b = JAMBES[i], JAMBES[i + 1]
	local x = IK.lisse((u - a[1]) / (b[1] - a[1]))
	return a[2] + (b[2] - a[2]) * x, a[3] + (b[3] - a[3]) * x, a[4] + (b[4] - a[4]) * x
end

local function ecrire(joint, pose: CFrame)
	local cf = joint.c0Origine * pose * (joint.moteur :: any).Transform:Inverse()
	if joint.cadre:IsA("Motor6D") then joint.cadre.C0 = cf else (joint.cadre :: Attachment).CFrame = cf end
end

local function finir(personnage: Model, etat)
	if sauts[personnage] ~= etat then return end
	sauts[personnage] = nil
	etat.connexion:Disconnect()
	IK.relacherBras(etat.appui)
	IK.relacherBras(etat.libre)
	for _, joint in etat.jambes do
		if IK.jointValide(joint) then ecrire(joint, (joint.moteur :: any).Transform) end
	end
end

evenement.OnClientEvent:Connect(function(personnage: Model, bord: Vector3, duree: number, cote: string, coteJambes: number)
	if typeof(personnage) ~= "Instance" or not personnage:IsA("Model") or typeof(bord) ~= "Vector3" or typeof(duree) ~= "number" then return end
	local precedent = sauts[personnage]
	if precedent then finir(personnage, precedent) end
	local coteBras = if cote == "Right" then "Right" else "Left"
	local coteLibre = if coteBras == "Left" then "Right" else "Left"
	local balayage = if coteJambes == -1 then -1 else 1
	local signeLibre = if coteLibre == "Right" then 1 else -1
	local appui = IK.preparerBras(personnage, coteBras)
	local libre = IK.preparerBras(personnage, coteLibre)
	if appui then appui.taille = nil end
	if libre then libre.taille = nil end
	local etat = {appui = appui, libre = libre, jambes = {}, connexion = nil :: RBXScriptConnection?}
	for _, nom in {"LeftHip", "RightHip", "LeftKnee", "RightKnee"} do
		local joint = IK.trouverJoint(personnage, nom)
		if joint then
			joint.genou = string.find(nom, "Knee") ~= nil
			table.insert(etat.jambes, joint)
		end
	end
	local cibleLibre = Vector3.new(signeLibre * 2.3, 0.9, -0.3) -- bras libre écarté en balancier
	local poleLibre = Vector3.new(signeLibre, -0.3, 0.5)
	local mainLibre = Vector3.new(signeLibre, 0.3, 0).Unit
	duree = math.clamp(duree, 0.3, 3)
	sauts[personnage] = etat
	local debut = os.clock()
	-- Poses écrites avant la simulation, sinon les AnimationConstraint ne suivent pas.
	etat.connexion = RunService.PreSimulation:Connect(function()
		local u = (os.clock() - debut) / duree
		if u >= 1 or not personnage.Parent then finir(personnage, etat); return end
		-- Main d'appui posée puis collée au rebord jusqu'au transfert du poids.
		if appui and IK.brasValide(appui) then
			local poids = IK.lisse(u / 0.15) * (1 - IK.lisse((u - 0.6) / 0.15))
			IK.poserBras(appui, appui.torse.CFrame:PointToObjectSpace(bord), POLE_APPUI[coteBras], BAS, AVANT, CFrame.identity, poids)
		end
		if libre and IK.brasValide(libre) then
			local poids = IK.lisse((u - 0.1) / 0.2) * (1 - IK.lisse((u - 0.7) / 0.2))
			IK.poserBras(libre, cibleLibre, poleLibre, mainLibre, AVANT, CFrame.identity, poids)
		end
		local hanche, genou, lateral = jambes(u)
		for _, joint in etat.jambes do
			if IK.jointValide(joint) then
				if joint.genou then
					ecrire(joint, CFrame.Angles(SENS_GENOU * genou, 0, 0))
				else
					ecrire(joint, CFrame.Angles(0, -balayage * lateral, 0) * CFrame.Angles(0, 0, balayage * lateral * 0.6) * CFrame.Angles(SENS_HANCHE * hanche, 0, 0))
				end
			end
		end
	end)
	-- Le rendu peut être suspendu si la fenêtre est minimisée : relâcher quand même.
	task.delay(duree + 0.1, function() finir(personnage, etat) end)
end)

Players.LocalPlayer.CharacterRemoving:Connect(function(personnage)
	local etat = sauts[personnage]
	if etat then finir(personnage, etat) end
end)
