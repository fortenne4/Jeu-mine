-- Le levier de la gare déclenche le trajet uniquement pour le passager assis.
-- Le déplacement et la vérification de la place restent sous contrôle du serveur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local D = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Disposition"))

local message = Instance.new("RemoteEvent")
message.Name = "InformationDepartWagon"
message.Parent = ReplicatedStorage
local transition = Instance.new("RemoteEvent")
transition.Name = "WagonTransition"
transition.Parent = ReplicatedStorage
local lancerPierre = Instance.new("RemoteEvent")
lancerPierre.Name = "WagonLancerPierre"
lancerPierre.Parent = ReplicatedStorage
local invites = {}
local positionsGare = {}
local VITESSE = 40 -- studs par seconde ; trajet environ deux fois plus rapide

local function positionInvite(invite: ProximityPrompt): Vector3?
	local parent = invite.Parent
	if parent and parent:IsA("BasePart") then return parent.Position end
	if parent and parent:IsA("Attachment") then return parent.WorldPosition end
	return nil
end

-- La cible visible est distincte du repère fixe de l'invite F.
local function poigneeLevier(invite: ProximityPrompt): BasePart?
	local levier = invite:FindFirstAncestorOfClass("Model")
	local poignee = levier and levier:FindFirstChild("Poignee")
	return if poignee and poignee:IsA("BasePart") then poignee else nil
end

-- Le levier ne bascule qu'une fois la pierre arrivée à sa poignée.
local function toucherLevier(invite: ProximityPrompt)
	local levier = invite:FindFirstAncestorOfClass("Model")
	local manche = levier and levier:FindFirstChild("Manche")
	local poignee = poigneeLevier(invite)
	if not (manche and manche:IsA("BasePart") and poignee and poignee:IsA("BasePart")) then return end
	local mancheInitial, poigneeInitial = manche.CFrame, poignee.CFrame
	local pivot = mancheInitial * CFrame.new(0, -manche.Size.Y / 2, 0)
	local rotation = CFrame.Angles(math.rad(60), 0, 0)
	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(manche, info, {CFrame = pivot * rotation * pivot:ToObjectSpace(mancheInitial)}):Play()
	TweenService:Create(poignee, info, {CFrame = pivot * rotation * pivot:ToObjectSpace(poigneeInitial)}):Play()
	task.delay(0.7, function()
		if manche.Parent then TweenService:Create(manche, info, {CFrame = mancheInitial}):Play() end
		if poignee.Parent then TweenService:Create(poignee, info, {CFrame = poigneeInitial}):Play() end
	end)
end

local function lancer(personnage: Model, humain: Humanoid, siege: Seat, invite: ProximityPrompt): boolean
	local poignee = poigneeLevier(invite)
	if not poignee then return false end
	local cible = poignee.Position
	local tete = personnage:FindFirstChild("Head")
	if not tete or not tete:IsA("BasePart") then return false end
	-- Les deux bras se lèvent et la pierre reste au-dessus de la tête avant le tir.
	lancerPierre:FireAllClients(personnage, cible, 1.25)
	local pierre = Instance.new("Part")
	pierre.Name = "PierreLanceeWagon"
	pierre.Shape = Enum.PartType.Ball
	pierre.Size = Vector3.new(0.45, 0.38, 0.4)
	pierre.Color = Color3.fromRGB(102, 93, 79)
	pierre.Material = Enum.Material.Rock
	pierre.Anchored = true
	pierre.CanCollide = false
	pierre.CanTouch = false
	pierre.CanQuery = false
	pierre.CFrame = tete.CFrame * CFrame.new(0, 1.2, -0.15)
	pierre.Parent = workspace
	Debris:AddItem(pierre, 3)
	local preparation = os.clock()
	while os.clock() - preparation < 0.65 do
		if not (personnage.Parent and tete.Parent and humain.Health > 0 and siege.Parent and siege.Occupant == humain and invite.Parent) then pierre:Destroy(); return false end
		pierre.CFrame = tete.CFrame * CFrame.new(0, 1.2, -0.15)
		RunService.Heartbeat:Wait()
	end
	local origine = pierre.Position
	local debut = os.clock()
	while os.clock() - debut < 0.6 do
		if not (personnage.Parent and humain.Health > 0 and siege.Parent and siege.Occupant == humain and invite.Parent) then pierre:Destroy(); return false end
		local u = math.clamp((os.clock() - debut) / 0.6, 0, 1)
		if not poignee.Parent then pierre:Destroy(); return false end
		local destination = poignee.Position
		local arc = Vector3.new(0, 3 * 4 * u * (1 - u), 0)
		pierre.CFrame = CFrame.new(origine:Lerp(destination, u) + arc) * CFrame.Angles(u * math.pi * 4, u * math.pi * 3, 0)
		RunService.Heartbeat:Wait()
	end
	pierre:Destroy()
	if not (siege.Parent and siege.Occupant == humain and invite.Parent) then return false end
	toucherLevier(invite)
	return true
end

local function parcourir(wagon: Model, siege: Seat, passager: Humanoid?, sens: string): boolean
	local depart = wagon:GetPivot()
	local gare = positionsGare[wagon]
	if not gare then return false end
	local fondY = gare.Position.Y
	local haut = Vector3.new(D.TUNNEL_FIN.X, fondY, D.TUNNEL_FIN.Z)
	local bas = Vector3.new(D.DESCENTE_FIN.X, fondY + D.DESCENTE_FIN.Y - D.TUNNEL_FIN.Y, D.DESCENTE_FIN.Z)
	-- Le wagon fait 7,2 studs de long ; son centre reste devant le butoir bas.
	local quai = Vector3.new(D.QUAI_BAS.X, fondY + D.QUAI_BAS.Y - D.TUNNEL_FIN.Y, D.QUAI_BAS.Z + 4)

	local function deplacer(points: {Vector3}, retour: boolean, vide: boolean): boolean
		local orientation = wagon:GetPivot().Rotation
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local longueur = (b - a).Magnitude
			if longueur > 0.01 then
				-- Au retour le wagon recule, sans tourner sur lui-même.
				local rotation = if retour then CFrame.lookAt(b, a).Rotation else CFrame.lookAt(a, b).Rotation
				local parcouru = 0
				while parcouru < longueur and wagon.Parent and siege.Parent do
					local dt = RunService.Heartbeat:Wait()
					if vide then
						-- Le retour automatique reste immobile si quelqu'un remonte dedans.
						if siege.Occupant or wagon:GetAttribute("MonteeEnCours") then continue end
					elseif siege.Occupant ~= passager then
						return false -- le passager est descendu avant le terminus
					end
					parcouru = math.min(longueur, parcouru + VITESSE * math.min(dt, 0.1))
					local u = parcouru / longueur
					local tournant = math.clamp(parcouru / 8, 0, 1)
					wagon:PivotTo(CFrame.new(a:Lerp(b, u)) * orientation:Lerp(rotation, tournant))
				end
				orientation = rotation
			end
			if not wagon.Parent or not siege.Parent then return false end
		end
		return true
	end

	if sens == "aller" then
		return deplacer({depart.Position, haut, bas, quai}, false, false)
	end
	local position = depart.Position
	local retour = {position}
	if position.Z < bas.Z - 0.01 then table.insert(retour, bas) end
	if position.Z < haut.Z - 0.01 then table.insert(retour, haut) end
	table.insert(retour, gare.Position)
	local termine = deplacer(retour, true, sens == "retourVide")
	if termine and wagon.Parent then wagon:PivotTo(gare) end
	return termine
end

local function retourSiAbandonne(wagon: Model, siege: Seat)
	task.spawn(function()
		while wagon.Parent and siege.Parent do
			if wagon:GetAttribute("EnTrajet") then return end
			if not siege.Occupant and not wagon:GetAttribute("MonteeEnCours") then
				-- Un court délai laisse le temps au joueur de remonter s'il vient de tomber.
				task.wait(2)
				if not (wagon.Parent and siege.Parent) then return end
				if not wagon:GetAttribute("EnTrajet") and not siege.Occupant and not wagon:GetAttribute("MonteeEnCours") then
					wagon:SetAttribute("EnTrajet", true)
					local ok, erreur = xpcall(function() parcourir(wagon, siege, nil, "retourVide") end, debug.traceback)
					if wagon.Parent then wagon:SetAttribute("EnTrajet", nil) end
					if not ok then warn("[Wagonnet] Retour vide interrompu : " .. tostring(erreur)) end
					return
				end
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

local function declencher(joueur: Player, invite: ProximityPrompt, gare: Instance, sens: string)
	local personnage = joueur.Character
	local humain = personnage and personnage:FindFirstChildOfClass("Humanoid")
	local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
	local position = positionInvite(invite)
	if not (humain and racine and racine:IsA("BasePart") and position and humain.Health > 0) then return end
	if (racine.Position - position).Magnitude > invite.MaxActivationDistance + 2 then return end
	local siege = humain.SeatPart
	local wagon = siege and siege.Parent
	if not (siege and siege:IsA("Seat") and siege.Name == "SiegeWagon" and siege.Occupant == humain
		and wagon and wagon:IsA("Model") and wagon.Name == "Wagonnet" and wagon:IsDescendantOf(gare)) then
		message:FireClient(joueur, "Il faut être dans le wagon")
		return
	end
	if wagon:GetAttribute("EnTrajet") then return end
	local positionWagon = wagon:GetPivot().Position
	if sens == "aller" then
		if positionWagon.Z < D.TUNNEL_FIN.Z + 5 then return end
		positionsGare[wagon] = wagon:GetPivot()
	else
		if not positionsGare[wagon] or math.abs(positionWagon.Z - (D.QUAI_BAS.Z + 4)) > 4 then return end
	end
	wagon:SetAttribute("EnTrajet", true)
	task.spawn(function()
		local termine = false
		local transitionCommencee = false
		local ok, erreur = xpcall(function()
			if not lancer(personnage, humain, siege, invite) then return end
			-- Le départ du wagon et sa transition ne commencent qu'après l'impact.
			transition:FireClient(joueur, "depart", sens)
			transitionCommencee = true
			termine = parcourir(wagon, siege, humain, sens)
		end, debug.traceback)
		if joueur.Parent then transition:FireClient(joueur, if transitionCommencee then "arrivee" else "annulation") end
		if wagon.Parent then wagon:SetAttribute("EnTrajet", nil) end
		if not ok then
			warn("[Wagonnet] Trajet interrompu : " .. tostring(erreur))
		elseif transitionCommencee and not termine then
			-- En cas d'abandon en cours de route seulement, ramener le wagon vide.
			-- Au terminus il attend le joueur, même lorsque celui-ci va miner.
			retourSiAbandonne(wagon, siege)
		end
	end)
end

local function raccorder(instance: Instance)
	if not instance:IsA("ProximityPrompt") or invites[instance] then return end
	local carte = workspace:FindFirstChild("Carte")
	local mine = carte and carte:FindFirstChild("Mine")
	local gare = mine and mine:FindFirstChild("Gare")
	local caverne = mine and mine:FindFirstChild("Caverne")
	local sens = if instance.Name == "ActionnerDepart" then "aller" elseif instance.Name == "ActionnerRetour" then "retour" else nil
	local levier = if sens == "aller" then gare and gare:FindFirstChild("LevierDepart") else caverne and caverne:FindFirstChild("LevierRetour")
	if not sens or not gare then return end
	if not levier or not instance:IsDescendantOf(levier) then return end
	invites[instance] = true
	instance.Triggered:Connect(function(joueur) declencher(joueur, instance, gare, sens) end)
	instance.Destroying:Once(function() invites[instance] = nil end)
end

workspace.DescendantAdded:Connect(function(instance) task.defer(raccorder, instance) end)
task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
	for _, instance in workspace:GetDescendants() do raccorder(instance) end
end)
