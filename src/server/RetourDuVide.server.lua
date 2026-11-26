local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local monde = ServerStorage:WaitForChild("Monde")
local Disposition = require(monde:WaitForChild("Disposition"))
local MursInvisibles = require(monde:WaitForChild("MursInvisibles"))
local limitesMine = require(monde:WaitForChild("MinePrivee")).LIMITES

local dernierePosition = {}
local PERIODE_MEMOIRE = 0.15

local function dansBoite(p: Vector3, bas: Vector3, haut: Vector3): boolean
	return p.X >= bas.X and p.X <= haut.X and p.Y >= bas.Y and p.Y <= haut.Y and p.Z >= bas.Z and p.Z <= haut.Z
end

local function zoneJouable(joueur: Player, p: Vector3, carte: Instance): Instance?
	if dansBoite(p, MursInvisibles.MIN, MursInvisibles.MAX) then
		return carte
	end

	local grottes = workspace:FindFirstChild("Grottes")
	if grottes then
		for _, grotte in grottes:GetChildren() do
			local proprietaire = grotte:GetAttribute("Proprietaire")
			local invite = grotte:GetAttribute("Invite")
			local centre, demi = grotte:GetAttribute("Centre"), grotte:GetAttribute("DemiTaille")
			if
				(proprietaire == joueur.UserId or invite == joueur.UserId)
				and typeof(centre) == "Vector3"
				and typeof(demi) == "Vector3"
			then
				if dansBoite(p, centre - demi - Vector3.new(8, 8, 8), centre + demi + Vector3.new(8, 80, 8)) then
					return grotte
				end
			end
		end
	end

	local mines = workspace:FindFirstChild("MinesPrivees")
	local mine = mines and mines:FindFirstChild("MinePrivee_" .. joueur.UserId)
	local base = mine and mine:GetAttribute("Base")
	if typeof(base) == "CFrame" then
		local largeur = limitesMine.demiLargeur + 8
		local bas = Vector3.new(-largeur, limitesMine.yMin, limitesMine.zMin - 8)
		local haut = Vector3.new(largeur, 130, limitesMine.zMax + 8)
		if dansBoite(base:PointToObjectSpace(p), bas, haut) then
			return mine
		end
	end

	for id, centre in Disposition.ARENES_BOSS do
		local ecart = p - centre
		if ecart.X * ecart.X + ecart.Z * ecart.Z <= 135 ^ 2 and ecart.Y >= -30 and ecart.Y <= 180 then
			return workspace:FindFirstChild("AreneBoss_" .. id)
		end
	end

	local plaine = workspace:FindFirstChild("PlaineMobs")
	local sol = plaine and plaine:FindFirstChild("Sol")
	if sol and sol:IsA("BasePart") then
		local demi = sol.Size / 2
		local ecart = sol.CFrame:PointToObjectSpace(p)
		if dansBoite(ecart, Vector3.new(-demi.X - 4, -16, -demi.Z - 4), Vector3.new(demi.X + 4, 160, demi.Z + 4)) then
			return plaine
		end
	end
	return nil
end

local function appuiSol(carte: Instance, personnage: Model, position: Vector3, portee: number): boolean
	local exclusions = { personnage }
	local protection = carte:FindFirstChild("InvisibleWalls")
	if protection then
		table.insert(exclusions, protection)
	end
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Exclude
	filtre.FilterDescendantsInstances = exclusions
	filtre.RespectCanCollide = true
	filtre.IgnoreWater = true
	return workspace:Raycast(position, -Vector3.yAxis * portee, filtre) ~= nil
end

local function apparition(carte: Instance): CFrame
	local village = carte:FindFirstChild("Village")
	local dossier = village and village:FindFirstChild("Apparitions")
	local spawn = dossier and dossier:FindFirstChildWhichIsA("SpawnLocation")
	return if spawn then spawn.CFrame + Vector3.yAxis * 5 else CFrame.new(0, 8, 0)
end

Players.PlayerRemoving:Connect(function(joueur)
	dernierePosition[joueur] = nil
end)

RunService.Heartbeat:Connect(function()
	local carte = workspace:FindFirstChild("Carte")
	if not carte or not workspace:GetAttribute("MondeConstruit") then
		return
	end

	local maintenant = os.clock()
	for _, joueur in Players:GetPlayers() do
		local personnage = joueur.Character
		local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
		local humain = personnage and personnage:FindFirstChildOfClass("Humanoid")
		if not racine or not racine:IsA("BasePart") or not humain or humain.Health <= 0 then
			continue
		end

		local position = racine.Position
		local zone = zoneJouable(joueur, position, carte)
		local memoire = dernierePosition[joueur]
		if not memoire or memoire.personnage ~= personnage or (zone and memoire.zone ~= zone) then
			memoire = { personnage = personnage, zone = zone, instant = -math.huge }
			dernierePosition[joueur] = memoire
		end

		local portee = math.max(6, humain.HipHeight + racine.Size.Y / 2 + 3)
		if not zone then
			local destination = apparition(carte)
			if
				memoire.position
				and zoneJouable(joueur, memoire.position, carte) == memoire.zone
				and appuiSol(carte, personnage, memoire.position, portee)
			then
				destination = memoire.pivot
			end
			humain.Sit = false
			personnage:PivotTo(destination)
			racine.AssemblyLinearVelocity = Vector3.zero
			racine.AssemblyAngularVelocity = Vector3.zero
		elseif maintenant - memoire.instant >= PERIODE_MEMOIRE and humain.FloorMaterial ~= Enum.Material.Air then
			memoire.instant = maintenant
			if appuiSol(carte, personnage, position, portee) then
				memoire.position = position
				memoire.pivot = personnage:GetPivot()
			end
		end
	end
end)
