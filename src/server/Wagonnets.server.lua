-- Entrée dans les wagonnets vides de la gare. Le serveur décide qui monte et où.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local animations = ReplicatedStorage:FindFirstChild("EntreeWagonAnimation")
if not animations then
	animations = Instance.new("RemoteEvent")
	animations.Name = "EntreeWagonAnimation"
	animations.Parent = ReplicatedStorage
end
local evenement = animations :: RemoteEvent
local prepares = {}
local DUREE = 1.3

local function entree(joueur: Player, wagon: Model, siege: Seat, invite: ProximityPrompt)
	local personnage = joueur.Character
	local humain = personnage and personnage:FindFirstChildOfClass("Humanoid")
	local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
	local fond = wagon:FindFirstChild("Fond")
	if not (personnage and humain and racine and racine:IsA("BasePart") and fond and fond:IsA("BasePart")) then return end
	if humain.Health <= 0 or humain.Sit or siege.Occupant or wagon:GetAttribute("MonteeEnCours") then return end
	if not wagon:IsDescendantOf(workspace) or (racine.Position - siege.Position).Magnitude > invite.MaxActivationDistance + 2 then return end

	wagon:SetAttribute("MonteeEnCours", true)
	invite.Enabled = false
	local ancienAncrage, ancienAuto, ancienPlatform = racine.Anchored, humain.AutoRotate, humain.PlatformStand
	local depart = racine.Position
	local relatif = fond.CFrame:PointToObjectSpace(depart)
	-- À droite du wagon, le joueur utilise la main gauche ; à gauche, la droite.
	local coteBras = if relatif.X >= 0 then "Left" else "Right"
	local sens = if relatif.X >= 0 then 1 else -1
	-- Le bord le plus proche sert de point d'appui.
	local surCote = math.abs(relatif.X) / 3 >= math.abs(relatif.Z) / 3.6
	local x, z = 0, 0
	if surCote then
		x, z = (if relatif.X >= 0 then 2.8 else -2.8), math.clamp(relatif.Z, -2.5, 2.5)
	else
		x, z = math.clamp(relatif.X, -2.0, 2.0), (if relatif.Z >= 0 then 3.4 else -3.4)
	end
	local bord = fond.CFrame:PointToWorldSpace(Vector3.new(x, 3.1, z))
	local interieur = siege.Position + Vector3.new(0, 2.8, 0)
	local direction = Vector3.new(interieur.X - depart.X, 0, interieur.Z - depart.Z)
	if direction.Magnitude < 0.1 then direction = fond.CFrame.LookVector end
	local orientation = CFrame.lookAt(Vector3.zero, direction.Unit).Rotation

	local ok, erreur = xpcall(function()
		humain.AutoRotate = false
		humain.PlatformStand = true
		racine.Anchored = true
		evenement:FireAllClients(personnage, bord, DUREE, coteBras, sens)
		local debut = os.clock()
		while os.clock() - debut < DUREE do
			if not (personnage.Parent and racine.Parent and humain.Health > 0 and siege.Parent and not siege.Occupant) then break end
			local u = math.clamp((os.clock() - debut) / DUREE, 0, 1)
			local avance = u * u * (3 - 2 * u)
			local position = depart:Lerp(interieur, avance) + Vector3.new(0, 3.5 * math.sin(math.pi * u), 0)
			-- Une légère rotation accompagne le passage latéral des jambes.
			local pivot = CFrame.Angles(0, sens * math.rad(25) * math.sin(math.pi * u), 0)
			racine.CFrame = CFrame.new(position) * orientation * pivot
			RunService.Heartbeat:Wait()
		end
		if humain.Health > 0 and siege.Parent and not siege.Occupant then
			racine.CFrame = CFrame.new(interieur) * orientation
		end
	end, debug.traceback)
	if racine.Parent then racine.Anchored = ancienAncrage end
	if humain.Parent then
		humain.PlatformStand = ancienPlatform
		humain.AutoRotate = ancienAuto
		if ok and humain.Health > 0 and siege.Parent and not siege.Occupant then siege:Sit(humain) end
	end
	if wagon.Parent then wagon:SetAttribute("MonteeEnCours", nil) end
	if invite.Parent then invite.Enabled = siege.Occupant == nil end
	if not ok then warn("[Wagonnet] Entrée interrompue : " .. tostring(erreur)) end
end

local function preparer(wagon: Model)
	if prepares[wagon] then return end
	local carte = workspace:FindFirstChild("Carte")
	local mine = carte and carte:FindFirstChild("Mine")
	local gare = mine and mine:FindFirstChild("Gare")
	if not gare or not wagon:IsDescendantOf(gare) then return end
	local fond = wagon:FindFirstChild("Fond")
	if not fond or not fond:IsA("BasePart") or wagon:FindFirstChild("Minerai") then return end
	prepares[wagon] = true
	local siege = Instance.new("Seat")
	siege.Name = "SiegeWagon"
	siege.Size = Vector3.new(2.2, 0.35, 2.2)
	siege.CFrame = fond.CFrame * CFrame.new(0, 0.45, 0)
	siege.Anchored = true
	siege.CanCollide = false
	siege.CanTouch = false -- seule l'interaction volontaire assied le joueur
	siege.Transparency = 1
	siege.Parent = wagon
	local invite = Instance.new("ProximityPrompt")
	invite.Name = "MonterWagon"
	invite.ActionText = "Monter"
	invite.ObjectText = "Wagonnet"
	invite.KeyboardKeyCode = Enum.KeyCode.E
	invite.GamepadKeyCode = Enum.KeyCode.ButtonX
	invite.MaxActivationDistance = 10
	invite.RequiresLineOfSight = false
	invite.UIOffset = Vector2.new(0, -60)
	invite.Parent = siege
	invite.Triggered:Connect(function(joueur) entree(joueur, wagon, siege, invite) end)
	siege:GetPropertyChangedSignal("Occupant"):Connect(function()
		if invite.Parent then invite.Enabled = siege.Occupant == nil and not wagon:GetAttribute("MonteeEnCours") end
	end)
	wagon.Destroying:Once(function() prepares[wagon] = nil end)
end

local function examiner(instance: Instance)
	if instance:IsA("Model") and instance.Name == "Wagonnet" then
		-- Laisser le constructeur terminer les pièces et le chargement éventuel.
		task.defer(function() if instance.Parent then preparer(instance) end end)
	end
end
workspace.DescendantAdded:Connect(examiner)
task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
	for _, instance in workspace:GetDescendants() do examiner(instance) end
end)
