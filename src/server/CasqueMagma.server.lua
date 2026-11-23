-- Quête du Casque du Cœur Magmatique · SCRIPT SERVEUR
-- Grotte −200 m (Fonderie) : 3 reliques (modèles « ReliqueMagma » posés par GrotteFonderie, invite « Ramasser »,
-- attribut ReliqueMagma = "Magma1".."Magma3") et l'enclume du pilier (invite avec l'attribut EnclumeMagma).
--   • Ramasser une relique : sauvegardée dans profil.fragments (Donnees.ajouterFragment), une fois pour toujours.
--   • Enclume : ouvre l'interface chez le joueur (EnclumeMagma.client) ; « Forger » crée le casque si les 3 reliques
--     sont là et qu'il n'a jamais été forgé (marque MagmaForge). Un seul casque par joueur.
--   • Casque porté : Défense = valeur de l'objet (comptée par Grottes.server), attributs joueur
--     « BonusVie » (+25 PV max, lu par Vie.server) et « ResistanceFeu » (0.08, lu par DangersGrotte).
-- Le serveur fait tout : distance à l'invite vérifiée, état lu dans le profil, jamais dans le client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Donnees = require(script.Parent:WaitForChild("Donnees"))
local Config = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CasqueMagma"))

local remote = ReplicatedStorage:FindFirstChild(Config.REMOTE) :: RemoteEvent?
if not remote then
	local r = Instance.new("RemoteEvent")
	r.Name = Config.REMOTE
	r.Parent = ReplicatedStorage
	remote = r
end
local evenement = remote :: RemoteEvent

local function racine(joueur: Player): BasePart?
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not (r and r:IsA("BasePart")) then
		return nil
	end
	return r
end

local function aPortee(joueur: Player, invite: ProximityPrompt): boolean
	local part = invite.Parent
	local r = racine(joueur)
	return r ~= nil and part ~= nil and part:IsA("BasePart") and (r.Position - part.Position).Magnitude <= invite.MaxActivationDistance + 4
end

-- dernière enclume utilisée par chaque joueur (la forge doit se faire près d'elle)
local enclumes: {[Player]: ProximityPrompt} = {}
local derniereDemande: {[Player]: number} = {}

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	local relique = invite:GetAttribute("ReliqueMagma")
	if type(relique) == "string" then
		if not Config.PAR_ID[relique] or not aPortee(joueur, invite) then
			return
		end
		if Donnees.ajouterFragment(joueur, relique) then
			evenement:FireClient(joueur, "Relique", {id = relique})
			print(string.format("[CasqueMagma] %s ramasse %s", joueur.Name, relique))
		end
	elseif invite:GetAttribute("EnclumeMagma") then
		if aPortee(joueur, invite) then
			enclumes[joueur] = invite
			evenement:FireClient(joueur, "Ouvrir", {})
		end
	end
end)

local function forger(joueur: Player): (boolean, string)
	local p = Donnees.profil(joueur)
	if not p then
		return false, "Ta sauvegarde n'est pas encore chargée"
	end
	local invite = enclumes[joueur]
	if not (invite and invite.Parent and aPortee(joueur, invite)) then
		return false, "Approche-toi de l'enclume"
	end
	if p.fragments[Config.ID_FORGE] then
		return false, "Tu as déjà forgé ce casque"
	end
	for _, r in Config.RELIQUES do
		if not p.fragments[r.id] then
			return false, "Il manque des reliques"
		end
	end
	if #p.objets >= Donnees.MAX_OBJETS then
		return false, "Ton coffre d'équipement est plein"
	end
	-- la marque d'abord : impossible d'obtenir deux casques même en cliquant très vite
	if not Donnees.ajouterFragment(joueur, Config.ID_FORGE) then
		return false, "Tu as déjà forgé ce casque"
	end
	local c = Config.CASQUE
	local objet: Donnees.Objet = {id = tostring(p.prochainId), type = "Casque", modele = Config.MODELE, rang = nil, nom = c.nom,
		couleur = c.couleur:ToHex(), stat = "Défense", valeur = c.defense, composition = {}}
	p.prochainId += 1
	table.insert(p.objets, objet)
	Donnees.notifier(joueur)
	print(string.format("[CasqueMagma] %s forge le %s", joueur.Name, c.nom))
	return true, c.nom .. " forgé ! Équipe-le depuis ton sac."
end

evenement.OnServerEvent:Connect(function(joueur: Player, action: any)
	if action ~= "Forger" then
		return
	end
	local maintenant = os.clock()
	if maintenant - (derniereDemande[joueur] or 0) < 1 then
		return
	end
	derniereDemande[joueur] = maintenant
	local ok, message = forger(joueur)
	evenement:FireClient(joueur, "Forge", {ok = ok, message = message})
end)

-- Bonus du casque porté : PV max et résistance au feu
local function majBonus(joueur: Player)
	if not joueur.Parent then
		return
	end
	local p = Donnees.profil(joueur)
	local porte = false
	if p then
		local id = p.equipement.Casque
		for _, o in p.objets do
			if o.id == id and o.modele == Config.MODELE then
				porte = true
				break
			end
		end
	end
	joueur:SetAttribute("BonusVie", if porte then Config.CASQUE.vie else 0)
	joueur:SetAttribute("ResistanceFeu", if porte then Config.CASQUE.resistanceFeu else 0)
end

Donnees.surChangement(function(joueur)
	task.spawn(majBonus, joueur)
end)

local function surJoueur(joueur: Player)
	Donnees.attendre(joueur)
	majBonus(joueur)
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end

Players.PlayerRemoving:Connect(function(joueur)
	enclumes[joueur] = nil
	derniereDemande[joueur] = nil
end)
