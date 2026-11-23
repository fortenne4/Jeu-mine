-- Caméra de visée (tous supports) :
--  • 3e personne : souris bloquée au centre (sur le viseur), le personnage se tourne vers où regarde la caméra,
--    caméra légèrement décalée sur l'épaule. On vise donc avec la souris / le stick / le doigt, et les coups
--    (épée, pioche) partent toujours vers le viseur.
--  • 1re personne : champ de vision élargi.
--  • Interface ouverte (Curseur.estLibre) : souris libre, en 1re comme en 3e personne.
--  • PC : maintenir Alt libère la souris le temps de cliquer un bouton du HUD.
--  • Rien n'est forcé pendant les cinématiques (caméra Scriptable), assis (wagon, banc) ou mort.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Curseur = require(script.Parent:WaitForChild("Curseur"))

local joueur = Players.LocalPlayer
local reglages = UserSettings():GetService("UserGameSettings")

local FOV_PREMIERE = 90 -- 1re personne : champ de vision large
local FOV_TROISIEME = 70 -- 3e personne : valeur Roblox par défaut
local DECALAGE_EPAULE = 1.75 -- comme le Shift Lock de Roblox
local SEUIL_PREMIERE = 1 -- distance caméra → cible sous laquelle on est en 1re personne

-- Le Shift Lock de Roblox ferait doublon (décalage ajouté deux fois) : on le coupe
pcall(function()
	joueur.DevEnableMouseLock = false
end)

local altTenu = false
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		altTenu = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		altTenu = false
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	altTenu = false
end)

local etaitPremiere: boolean? = nil
local typeAvant: Enum.CameraType? = nil
local decalageEcrit = false
local iconeCachee = false

local function miseAJour(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local libre = Curseur.estLibre()

	local custom = camera.CameraType == Enum.CameraType.Custom
	local zoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local premiere = zoom < SEUIL_PREMIERE

	-- FOV : seulement aux changements (1re ↔ 3e, ou retour d'une cinématique), pour laisser
	-- le Hud ajouter son bonus de course par-dessus
	if custom then
		if premiere ~= etaitPremiere or typeAvant ~= Enum.CameraType.Custom then
			camera.FieldOfView = if premiere then FOV_PREMIERE else FOV_TROISIEME
		end
		etaitPremiere = premiere
	end
	typeAvant = camera.CameraType

	local vivant = humain ~= nil and humain.Health > 0
	local assis = humain ~= nil and (humain.Sit or humain.SeatPart ~= nil)
	local viser = custom and vivant and not assis and not libre

	-- Souris : libre dans les interfaces (et avec Alt), bloquée au centre sinon
	local cacherIcone = false
	if libre or (altTenu and viser) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif viser then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		cacherIcone = true -- le viseur du centre de l'écran sert de curseur
		-- le personnage regarde dans la direction de la caméra (ce que fait le Shift Lock)
		pcall(function()
			reglages.RotationType = Enum.RotationType.CameraRelative
		end)
	end
	if cacherIcone ~= iconeCachee then
		iconeCachee = cacherIcone
		UserInputService.MouseIconEnabled = not cacherIcone
	end

	-- Décalage d'épaule en 3e personne, nul en 1re (il s'efface en zoomant)
	if humain then
		local cible = 0
		if viser and not premiere then
			cible = DECALAGE_EPAULE * math.clamp((zoom - SEUIL_PREMIERE) / 4, 0, 1)
		end
		local actuel = humain.CameraOffset
		if cible > 0 or decalageEcrit then
			local x = actuel.X + (cible - actuel.X) * (1 - math.exp(-12 * dt))
			if math.abs(x - cible) < 0.01 then
				x = cible
			end
			humain.CameraOffset = Vector3.new(x, actuel.Y, actuel.Z)
			decalageEcrit = x ~= 0
		end
	end
end

-- Juste après la caméra de Roblox (qui remet souris et rotation à chaque image)
RunService:BindToRenderStep("CameraVisee", Enum.RenderPriority.Camera.Value + 1, miseAJour)

joueur.CharacterAdded:Connect(function()
	decalageEcrit = false
end)
