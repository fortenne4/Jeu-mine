--!strict
-- Sac du mineur · SCRIPT SERVEUR
-- Envoie l'état du sac (minerais, objets forgés, équipement) au client à chaque changement,
-- et valide l'équipement des objets forgés (données seulement : rien n'est encore porté sur le perso).
--
-- Remotes (ReplicatedStorage) :
--   SacEtat   (RemoteEvent, serveur → client) : etat, envoyé au chargement et après chaque changement
--   SacAction (RemoteFunction, client → serveur) : {action = "etat"} | {action = "equiper"|"retirer", slot = type, id = string}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forge = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Forge"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CADENCE = 0.15

type Etat = {minerais: {[string]: number}, objets: {Donnees.Objet}, equipement: {[string]: string}}
type Reponse = {ok: boolean, message: string, etat: Etat?}

local evEtat = Instance.new("RemoteEvent")
evEtat.Name = "SacEtat"
evEtat.Parent = ReplicatedStorage

local action = Instance.new("RemoteFunction")
action.Name = "SacAction"
action.Parent = ReplicatedStorage

local derniere: {[Player]: number} = {}

local function etat(p: Donnees.Profil): Etat
	return {minerais = p.minerais, objets = p.objets, equipement = p.equipement}
end

Donnees.surChangement(function(joueur: Player)
	local p = Donnees.profil(joueur)
	if p and joueur.Parent then
		evEtat:FireClient(joueur, etat(p))
	end
end)

action.OnServerInvoke = function(joueur: Player, demande: any): Reponse
	local p = Donnees.profil(joueur)
	if not p then
		return {ok = false, message = "Patiente un instant…"}
	end
	local maintenant = os.clock()
	if maintenant - (derniere[joueur] or 0) < CADENCE then
		return {ok = false, message = "Doucement !", etat = etat(p)}
	end
	derniere[joueur] = maintenant
	if type(demande) ~= "table" then
		return {ok = false, message = "Requête invalide", etat = etat(p)}
	elseif demande.action == "etat" then
		return {ok = true, message = "", etat = etat(p)}
	end
	local slot = demande.slot
	local t = if type(slot) == "string" then Forge.TYPES[slot] else nil
	if not t then
		return {ok = false, message = "Emplacement invalide", etat = etat(p)}
	end
	if demande.action == "equiper" then
		if not Donnees.objetDeType(p, demande.id, slot) then
			return {ok = false, message = "Cet objet ne va pas là", etat = etat(p)}
		end
		p.equipement[slot] = demande.id
	elseif demande.action == "retirer" then
		p.equipement[slot] = nil
	else
		return {ok = false, message = "Requête invalide", etat = etat(p)}
	end
	p.inconnus.equipement[slot] = nil
	return {ok = true, message = (if demande.action == "equiper" then "Équipé : " else "Retiré : ") .. t.nom, etat = etat(p)}
end

local function surJoueur(joueur: Player)
	local p = Donnees.attendre(joueur)
	if p and joueur.Parent then
		evEtat:FireClient(joueur, etat(p))
	end
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end
Players.PlayerRemoving:Connect(function(joueur)
	derniere[joueur] = nil
end)
