-- Voyage en wagon : départ automatique dès que le joueur est assis dans le wagon de la gare (aller)
-- ou dans celui du quai souterrain (retour). Les wagons ne bougent pas : le serveur valide et téléporte,
-- le client joue la cinématique avec des clones.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local D = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Disposition"))

local voyage = Instance.new("RemoteEvent")
voyage.Name = "VoyageWagon"
voyage.Parent = ReplicatedStorage
local pret = Instance.new("RemoteEvent")
pret.Name = "VoyageWagonPret"
pret.Parent = ReplicatedStorage

local ASSISE = 0.35 -- la pose assise se stabilise avant le clonage côté client
local ATTENTE_ACCUSE = 1.5 -- sans accusé du client : téléportation sans blocage
local FIN_BLOCAGE = 9 -- depuis l'envoi de la cinématique : à allonger si les PLANS client s'allongent
local RECHARGE = 8
local SOL_MINE = Vector3.new(D.QUAI_BAS.X - 12, D.CAVERNE_SOL + 2, D.QUAI_BAS.Z + 12) -- quai souterrain, hors de la voie
local SOL_GARE = Vector3.new(-9.5, 2.2, D.RAIL_DEBUT.Z - 28) -- quai de la gare, face au wagon
local REGARD_GARE = Vector3.new(D.RAIL_DEBUT.X, 0, SOL_GARE.Z)

local enCours = {}
local accuses = {} -- joueur → voyage en attente de l'accusé du client
local derniers = {}
local raccordes = {}
local wagons = {} -- sens → wagon de départ de ce sens

local function cadreArrivee(humain: Humanoid, racine: BasePart, sol: Vector3, regard: Vector3): CFrame
	local position = sol + Vector3.new(0, humain.HipHeight + racine.Size.Y / 2, 0)
	return CFrame.lookAt(position, Vector3.new(regard.X, position.Y, regard.Z))
end

local function vivant(personnage: Model, humain: Humanoid, racine: BasePart): boolean
	return personnage.Parent ~= nil and racine.Parent ~= nil and humain.Health > 0
end

local function ejecter(humain: Humanoid)
	local siege = humain.SeatPart
	local soudure = siege and siege:FindFirstChild("SeatWeld")
	if soudure then soudure:Destroy() end
	humain.Sit = false
end

-- Repères du pivot du wagon le long de la voie, dans le sens du trajet.
local function pointsVoie(sens: string, depart: Vector3): {Vector3}
	local y = depart.Y - (if sens == "aller" then D.RAIL_DEBUT.Y else D.QUAI_BAS.Y)
	local gare = Vector3.new(D.RAIL_DEBUT.X, y + D.RAIL_DEBUT.Y, D.RAIL_DEBUT.Z - 25)
	local haut = Vector3.new(D.TUNNEL_FIN.X, y + D.TUNNEL_FIN.Y, D.TUNNEL_FIN.Z)
	local bas = Vector3.new(D.DESCENTE_FIN.X, y + D.DESCENTE_FIN.Y, D.DESCENTE_FIN.Z)
	-- Le wagon fait 7,2 studs : il s'arrête devant le butoir bas.
	local quai = Vector3.new(D.QUAI_BAS.X, y + D.QUAI_BAS.Y, D.QUAI_BAS.Z + 4)
	if sens == "aller" then return {depart, haut, bas, quai} end
	return {depart, bas, haut, gare}
end

local function partir(siege: Seat, humain: Humanoid, sens: string)
	local personnage = humain.Parent
	local joueur = personnage and Players:GetPlayerFromCharacter(personnage)
	local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
	local wagon = siege.Parent
	if not (joueur and personnage and racine and racine:IsA("BasePart") and wagon and wagon:IsA("Model")) then return end
	if enCours[joueur] or humain.Health <= 0 then return end
	if os.clock() - (derniers[joueur] or -math.huge) < RECHARGE then ejecter(humain); return end
	enCours[joueur] = true
	local ancre = false
	local ok, erreur = xpcall(function()
		task.wait(ASSISE)
		if not (joueur.Parent and vivant(personnage, humain, racine) and siege.Occupant == humain) then return end
		local arrivee = if sens == "aller"
			then cadreArrivee(humain, racine, SOL_MINE, D.CAVERNE_CENTRE)
			else cadreArrivee(humain, racine, SOL_GARE, REGARD_GARE)
		local autre = wagons[if sens == "aller" then "retour" else "aller"]
		local attente = {recu = false}
		derniers[joueur] = os.clock()
		accuses[joueur] = attente
		local envoi = os.clock()
		voyage:FireClient(joueur, "depart", sens, wagon, pointsVoie(sens, wagon:GetPivot().Position), arrivee, if autre and autre.Parent then autre else nil)
		while not attente.recu and os.clock() - envoi < ATTENTE_ACCUSE and joueur.Parent do task.wait(0.05) end
		accuses[joueur] = nil
		if not vivant(personnage, humain, racine) then return end
		ejecter(humain)
		personnage:PivotTo(arrivee)
		local quete = ServerStorage:FindFirstChild("QueteEvenement") -- Guilde des Mineurs (Quetes.server.lua)
		if quete and quete:IsA("BindableEvent") then
			quete:Fire("wagon", joueur, sens)
		end
		if not attente.recu then return end
		racine.Anchored = true
		ancre = true
		while os.clock() - envoi < FIN_BLOCAGE and vivant(personnage, humain, racine) do task.wait(0.2) end
	end, debug.traceback)
	if ancre and racine.Parent then racine.Anchored = false end
	accuses[joueur] = nil
	enCours[joueur] = nil
	if not ok then warn("[Wagonnet] Voyage interrompu : " .. tostring(erreur)) end
end

local function raccorder(instance: Instance)
	if raccordes[instance] or not (instance:IsA("Seat") and instance.Name == "SiegeWagon") then return end
	local carte = workspace:FindFirstChild("Carte")
	local mine = carte and carte:FindFirstChild("Mine")
	local gare = mine and mine:FindFirstChild("Gare")
	local caverne = mine and mine:FindFirstChild("Caverne")
	local wagon = instance.Parent
	local sens = if gare and instance:IsDescendantOf(gare) then "aller"
		elseif caverne and wagon and instance:IsDescendantOf(caverne) and wagon:GetAttribute("WagonRetour") then "retour"
		else nil
	if not sens then return end
	local siege = instance
	raccordes[siege] = true
	wagons[sens] = wagon
	siege:GetPropertyChangedSignal("Occupant"):Connect(function()
		local humain = siege.Occupant
		if humain then task.spawn(partir, siege, humain, sens) end
	end)
	siege.Destroying:Once(function() raccordes[siege] = nil end)
end

pret.OnServerEvent:Connect(function(joueur)
	local attente = accuses[joueur]
	if not attente then return end
	accuses[joueur] = nil -- un seul accusé par voyage
	attente.recu = true
end)
Players.PlayerRemoving:Connect(function(joueur) derniers[joueur] = nil end)
workspace.DescendantAdded:Connect(function(instance) task.defer(raccorder, instance) end)
task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
	for _, instance in workspace:GetDescendants() do raccorder(instance) end
end)
