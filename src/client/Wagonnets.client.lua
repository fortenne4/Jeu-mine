-- Saut de franchissement : appui du bras côté wagon et jambes sur le côté.
-- Chaque client calcule la pose avec le module IK du jeu (R15 et AnimationConstraint).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IK = require(script.Parent:WaitForChild("RigIK"))
local evenement = ReplicatedStorage:WaitForChild("EntreeWagonAnimation") :: RemoteEvent

evenement.OnClientEvent:Connect(function(personnage: Model, bord: Vector3, duree: number, cote: string, sens: number)
	if not personnage or not personnage:IsA("Model") or typeof(bord) ~= "Vector3" then return end
	local coteBras = if cote == "Right" then "Right" else "Left"
	local direction = if sens == -1 then -1 else 1
	local bras = IK.preparerBras(personnage, coteBras)
	local articulations = {
		{joint = IK.trouverJoint(personnage, "LeftHip"), pied = -1},
		{joint = IK.trouverJoint(personnage, "RightHip"), pied = 1},
		{joint = IK.trouverJoint(personnage, "LeftKnee"), genou = true},
		{joint = IK.trouverJoint(personnage, "RightKnee"), genou = true},
	}
	local debut = os.clock()
	local connexion
	connexion = RunService.RenderStepped:Connect(function()
		local u = (os.clock() - debut) / duree
		if u >= 1 or not personnage.Parent then
			connexion:Disconnect()
			IK.relacherBras(bras)
			for _, element in articulations do
				local joint = element.joint
				if joint and IK.jointValide(joint) then
					if joint.cadre:IsA("Motor6D") then joint.cadre.C0 = joint.c0Origine else (joint.cadre :: Attachment).CFrame = joint.c0Origine end
				end
			end
			return
		end
		-- Lever la main vers le bord, puis la relâcher pendant le passage au-dessus.
		if bras and IK.brasValide(bras) then
			local poids = math.min(math.clamp(u / 0.18, 0, 1), math.clamp((0.84 - u) / 0.25, 0, 1))
			local cible = bras.torse.CFrame:PointToObjectSpace(bord)
			local pole = if coteBras == "Left" then -1 else 1
			IK.poserBras(bras, cible, Vector3.new(pole, -0.5, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), CFrame.identity, poids)
		end
		-- Les genoux se replient et les deux jambes se balancent latéralement.
		local envol = math.sin(math.pi * math.clamp(u, 0, 1))
		for _, element in articulations do
			local joint = element.joint
			if joint and IK.jointValide(joint) then
				local pose = if element.genou then CFrame.Angles(1.05 * envol, 0, 0) else CFrame.Angles(-0.75 * envol, 0.12 * direction * envol, 0.5 * direction * envol)
				local moteur = joint.moteur :: any
				local cf = joint.c0Origine * pose * moteur.Transform:Inverse()
				if joint.cadre:IsA("Motor6D") then joint.cadre.C0 = cf else (joint.cadre :: Attachment).CFrame = cf end
			end
		end
	end)
end)
