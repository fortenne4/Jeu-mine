local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
Players.CharacterAutoLoads = false

local monde = ServerStorage:WaitForChild("Monde")
local TenueMineur = require(monde:WaitForChild("TenueMineur"))
local EquipementVisuel = require(script.Parent:WaitForChild("EquipementVisuel"))

local peau = Color3.fromRGB(201, 145, 103)
local description = Instance.new("HumanoidDescription")
description.UseAvatarSettings = false
description.HeightScale = 1
description.WidthScale = 1
description.DepthScale = 1
description.HeadScale = 1
description.BodyTypeScale = 0
description.ProportionScale = 0
description.HeadColor = peau
description.TorsoColor = peau
description.LeftArmColor = peau
description.RightArmColor = peau
description.LeftLegColor = peau
description.RightLegColor = peau

local etats = {}

local function habiller(joueur: Player, personnage: Model)
	if joueur.Character ~= personnage or joueur.Parent ~= Players then
		return
	end
	local ok, erreur = pcall(TenueMineur.appliquer, personnage)
	if not ok then
		warn("[ApparitionMineur] Tenue interrompue : " .. tostring(erreur))
	end
	if joueur.Character == personnage then
		task.defer(EquipementVisuel.appliquer, joueur)
	end
end

local function charger(joueur: Player, etat)
	if joueur.Parent ~= Players or etat.chargement then
		return
	end
	etat.chargement = true
	local ok, erreur = pcall(joueur.LoadCharacterWithHumanoidDescriptionAsync, joueur, description)
	if not ok and joueur.Parent == Players then
		warn("[ApparitionMineur] Description indisponible : " .. tostring(erreur))
		joueur.CanLoadCharacterAppearance = false
		ok, erreur = pcall(joueur.LoadCharacterAsync, joueur)
	end

	if (not ok or not joueur.Character) and joueur.Parent == Players then
		warn("[ApparitionMineur] Apparition interrompue : " .. tostring(erreur))
		task.delay(2, charger, joueur, etat)
	elseif joueur.Character and joueur.Parent == Players then
		-- Le moteur a fini de charger l'apparence. La tenue s'ajoute au rig et aux équipements déjà présents.
		habiller(joueur, joueur.Character)
	end
	etat.chargement = false
end

local function planifierReapparition(joueur: Player, personnage: Model, etat)
	if etat.reapparition == personnage then
		return
	end
	etat.reapparition = personnage
	local function lancer()
		if not etat.autorise or joueur.Parent ~= Players or etat.personnage ~= personnage then
			return
		end
		if joueur.Character and joueur.Character ~= personnage then
			return
		end
		if etat.chargement then
			task.delay(0.25, lancer)
			return
		end
		charger(joueur, etat)
	end
	task.delay(Players.RespawnTime, lancer)
end

local function suivrePersonnage(joueur: Player, personnage: Model, etat)
	etat.personnage = personnage
	etat.reapparition = nil
	local humain = personnage:WaitForChild("Humanoid", 10)
	if not humain or not humain:IsA("Humanoid") or joueur.Character ~= personnage then
		return
	end

	humain.Died:Once(function()
		planifierReapparition(joueur, personnage, etat)
	end)
	if humain.Health <= 0 then
		planifierReapparition(joueur, personnage, etat)
	end
end

local function autoriserApparition(joueur: Player, etat)
	if etat.autorise or not workspace:GetAttribute("ApparitionAutorisee") then
		return
	end
	etat.autorise = true
	local personnage = joueur.Character
	local humain = personnage and personnage:FindFirstChildOfClass("Humanoid")
	if personnage and (not humain or humain.Health > 0) then
		task.spawn(habiller, joueur, personnage)
	else
		task.spawn(charger, joueur, etat)
	end
end

local function inscrire(joueur: Player)
	if etats[joueur] then
		return
	end
	local etat = {}
	etats[joueur] = etat
	joueur.CharacterAdded:Connect(function(personnage)
		suivrePersonnage(joueur, personnage, etat)
	end)
	joueur.CharacterRemoving:Connect(function(personnage)
		if etat.autorise and not etat.chargement and etat.personnage == personnage then
			planifierReapparition(joueur, personnage, etat)
		end
	end)
	if joueur.Character then
		task.spawn(suivrePersonnage, joueur, joueur.Character, etat)
	end
	autoriserApparition(joueur, etat)
end

workspace:GetAttributeChangedSignal("ApparitionAutorisee"):Connect(function()
	for joueur, etat in etats do
		autoriserApparition(joueur, etat)
	end
end)
Players.PlayerAdded:Connect(inscrire)
Players.PlayerRemoving:Connect(function(joueur)
	etats[joueur] = nil
end)
for _, joueur in Players:GetPlayers() do
	inscrire(joueur)
end
