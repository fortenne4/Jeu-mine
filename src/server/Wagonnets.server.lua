-- Entrée dans les wagonnets de voyage (gare et quai souterrain) par un saut d'obstacle :
-- le serveur déplace la racine, chaque client pose les membres (Wagonnets.client).
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
-- Saut d'obstacle (speed vault) : impulsion 0-0,22, appui et passage des jambes 0,22-0,6,
-- descente dans le wagon 0,6-0,9, tassement 0,9-1. Mêmes phases dans Wagonnets.client.
local DUREE = 1.1

local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function tangente(cles, k: number): Vector3
	if k <= 1 or k >= #cles then return Vector3.zero end
	return (cles[k + 1][2] - cles[k - 1][2]) / (cles[k + 1][1] - cles[k - 1][1])
end

-- Courbe d'Hermite passant par les clés {u, position} (tangentes de Catmull-Rom, nulles aux extrémités).
local function courbe(cles, u: number): Vector3
	local i = 1
	while i < #cles - 1 and u > cles[i + 1][1] do i += 1 end
	local u0, u1 = cles[i][1], cles[i + 1][1]
	local h = u1 - u0
	local x = math.clamp((u - u0) / h, 0, 1)
	local x2, x3 = x * x, x * x * x
	return cles[i][2] * (2 * x3 - 3 * x2 + 1) + tangente(cles, i) * (h * (x3 - 2 * x2 + x))
		+ cles[i + 1][2] * (3 * x2 - 2 * x3) + tangente(cles, i + 1) * (h * (x3 - x2))
end

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
	-- Le bord le plus proche du joueur sert d'appui.
	local surCote = math.abs(relatif.X) / 3 >= math.abs(relatif.Z) / 3.6
	local x, z = 0, 0
	if surCote then
		x, z = (if relatif.X >= 0 then 2.8 else -2.8), math.clamp(relatif.Z, -2.5, 2.5)
	else
		x, z = math.clamp(relatif.X, -2.0, 2.0), (if relatif.Z >= 0 then 3.4 else -3.4)
	end
	local bord = fond.CFrame:PointToWorldSpace(Vector3.new(x, 3.1, z))
	local interieur = siege.Position + Vector3.new(0, 2.8, 0)
	local auSol = Vector3.new(bord.X, depart.Y, bord.Z)
	local direction = auSol - depart
	if direction.Magnitude < 0.1 then direction = Vector3.new(interieur.X - bord.X, 0, interieur.Z - bord.Z) end
	if direction.Magnitude < 0.1 then direction = fond.CFrame.LookVector end
	direction = direction.Unit
	local orientation = CFrame.lookAt(Vector3.zero, direction).Rotation
	local finale = siege.CFrame.Rotation
	local _, lacet = orientation:ToObjectSpace(finale):ToEulerAnglesYXZ()
	-- Le corps tourne vers le siège : en tournant à gauche, appui main gauche et jambes balayées à droite.
	local coteJambes = if lacet >= 0 then 1 else -1
	local coteBras = if coteJambes > 0 then "Left" else "Right"
	local approche = if (auSol - depart).Magnitude > 1.6 then auSol - direction * 1.6 else depart
	local cles = {
		{0, depart},
		{0.22, approche - Vector3.new(0, 0.3, 0)}, -- impulsion
		{0.5, Vector3.new(bord.X, bord.Y + 1.4, bord.Z) + direction * 0.6}, -- bassin au-dessus du rebord
		{0.78, interieur + Vector3.new(0, 0.7, 0)},
		{0.9, interieur - Vector3.new(0, 0.3, 0)}, -- tassement
		{1, interieur},
	}

	local ok, erreur = xpcall(function()
		humain.AutoRotate = false
		humain.PlatformStand = true
		racine.Anchored = true
		evenement:FireAllClients(personnage, bord, DUREE, coteBras, coteJambes)
		local debut = os.clock()
		while os.clock() - debut < DUREE do
			if not (personnage.Parent and racine.Parent and humain.Health > 0 and siege.Parent and not siege.Occupant) then break end
			local u = math.clamp((os.clock() - debut) / DUREE, 0, 1)
			-- Corps incliné vers la main d'appui et légèrement en arrière pendant le passage.
			local cloche = lisse((u - 0.15) / 0.3) * (1 - lisse((u - 0.55) / 0.3))
			racine.CFrame = CFrame.new(courbe(cles, u)) * orientation * CFrame.Angles(0, lacet * lisse((u - 0.3) / 0.55), 0)
				* CFrame.Angles(0.3 * cloche, 0, coteJambes * 0.6 * cloche)
			RunService.Heartbeat:Wait()
		end
		if humain.Health > 0 and siege.Parent and not siege.Occupant then
			racine.CFrame = CFrame.new(interieur) * finale
		end
	end, debug.traceback)
	if racine.Parent then racine.Anchored = ancienAncrage end
	if humain.Parent then
		humain.PlatformStand = ancienPlatform
		humain.AutoRotate = ancienAuto
		if ok and humain.Health > 0 and siege.Parent and not siege.Occupant then
			siege:Sit(humain)
			-- Occupant peut n'être mis à jour qu'à l'image suivante : garder la montée verrouillée jusque-là.
			local limite = os.clock() + 0.5
			while siege.Parent and siege.Occupant ~= humain and os.clock() < limite do RunService.Heartbeat:Wait() end
		end
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
	local caverne = mine and mine:FindFirstChild("Caverne")
	local enGare = gare and wagon:IsDescendantOf(gare)
	local enBas = caverne and wagon:IsDescendantOf(caverne) and wagon:GetAttribute("WagonRetour")
	if not (enGare or enBas) then return end
	local fond = wagon:FindFirstChild("Fond")
	if not fond or not fond:IsA("BasePart") or wagon:FindFirstChild("Minerai") then return end
	prepares[wagon] = true
	-- Carte figée enregistrée en Play : l'ancien siège n'a plus de connexions, on le remplace.
	local ancien = wagon:FindFirstChild("SiegeWagon")
	if ancien then ancien:Destroy() end
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
