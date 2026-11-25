-- Pêche dans les lacs de la grotte −50 m · SCRIPT SERVEUR
-- Les pontons de pêche (invite « Pêcher », attribut « Peche » = "berge" ou "ilot", posés par GrotteLueurs) lancent
-- une partie de pêche : le serveur tire le poisson (plus de rares sur l'îlot), le client joue le mini-jeu
-- (PecheGrotte.client.lua : attendre que ça morde, puis ferrer au bon moment N fois) et renvoie le résultat.
-- Le serveur vérifie la durée (pas de prise trop rapide), paie le poisson et l'inscrit au carnet de pêche
-- (Donnees.ajouterPoisson, attribut joueur « CarnetPeche »). Parfois, un vieux coffret remonte avec un fragment
-- de la carte naine.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Peche = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Peche"))
local CarteNaine = require(script.Parent:WaitForChild("CarteNaine"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CHANCE_COFFRET = {berge = 0.03, ilot = 0.06} -- « caverne » (coin pêche public) : jamais de fragment
local RECHARGE = 2 -- s entre deux parties
local PIECES_LIBRE = 1 -- coin pêche public de la caverne : 1 pièce par prise (le carnet compte quand même)

local remote = ReplicatedStorage:FindFirstChild(Peche.REMOTE)
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = Peche.REMOTE
	remote.Parent = ReplicatedStorage
end

local rng = Random.new()
local parties: {[Player]: {poisson: any, debut: number, attente: number, genre: string, bout: BasePart, libre: boolean}} = {}
local derniere: {[Player]: number} = {}

local function grotteDe(objet: Instance): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	local m = objet
	while m and m.Parent ~= dossier do
		m = m.Parent :: Instance
	end
	return if m and m:IsA("Model") then m else nil
end

local function tirer(genre: string)
	local total = 0
	local poids = {}
	for i, p in Peche.POISSONS do
		local w = p.poids * (if genre == "ilot" then Peche.BONUS_ILOT[p.rarete] or 1 else 1)
		poids[i] = w
		total += w
	end
	local x = rng:NextNumber() * total
	for i, p in Peche.POISSONS do
		x -= poids[i]
		if x <= 0 then
			return p
		end
	end
	return Peche.POISSONS[1]
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	local genre = invite:GetAttribute("Peche")
	if type(genre) ~= "string" then
		return
	end
	local bout = invite.Parent
	local grotte = bout and grotteDe(bout)
	-- coin pêche public de la carte (caverne, CaverneDecor) : ouvert à tous, attribut posé par le serveur
	local carte = workspace:FindFirstChild("Carte")
	local libre = bout ~= nil and carte ~= nil and bout:GetAttribute("PecheLibre") == true and bout:IsDescendantOf(carte)
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (bout and bout:IsA("BasePart") and (grotte or libre) and r) then
		return
	end
	if grotte and joueur.UserId ~= grotte:GetAttribute("Proprietaire") and joueur.UserId ~= grotte:GetAttribute("Invite") then
		return
	end
	if (r.Position - bout.Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	local enCours = parties[joueur]
	if enCours and os.clock() - enCours.debut < enCours.attente + Peche.DUREE_MAX + 5 then
		return -- partie en cours (une partie abandonnée sans réponse expire d'elle-même)
	end
	if os.clock() - (derniere[joueur] or 0) < RECHARGE then
		return
	end
	local eau = bout:GetAttribute("Eau")
	if typeof(eau) ~= "Vector3" then
		return
	end
	local poisson = tirer(genre)
	local attente = rng:NextNumber(Peche.ATTENTE[1], Peche.ATTENTE[2])
	parties[joueur] = {poisson = poisson, debut = os.clock(), attente = attente, genre = genre, bout = bout, libre = grotte == nil}
	-- le client ne connaît que la difficulté (le poisson reste une surprise jusqu'à la prise)
	remote:FireClient(joueur, "Debut", {eau = eau, bout = bout.Position, attente = attente, touches = poisson.touches,
		zone = poisson.zone, vitesse = poisson.vitesse, rarete = poisson.rarete})
end)

remote.OnServerEvent:Connect(function(joueur: Player, genre, d)
	local partie = parties[joueur]
	if not partie then
		return
	end
	parties[joueur] = nil
	derniere[joueur] = os.clock()
	if genre ~= "Fin" or type(d) ~= "table" or d.ok ~= true then
		remote:FireClient(joueur, "Rate", {})
		return
	end
	local p = partie.poisson
	local duree = os.clock() - partie.debut
	-- trop vite (impossible de ferrer N fois en moins de ~0,3 s par touche) ou bien trop tard : rien
	if duree < partie.attente + p.touches * 0.3 or duree > partie.attente + Peche.DUREE_MAX + 2 then
		remote:FireClient(joueur, "Rate", {})
		return
	end
	local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r or not partie.bout.Parent or (r.Position - partie.bout.Position).Magnitude > 14 then
		remote:FireClient(joueur, "Rate", {})
		return
	end
	local pieces = if partie.libre then PIECES_LIBRE else p.pieces
	CarteNaine.crediter(joueur, pieces)
	local n = Donnees.ajouterPoisson(joueur, p.id)
	remote:FireClient(joueur, "Prise", {id = p.id, pieces = pieces, nouveau = n == 1, n = n})
	if rng:NextNumber() < (CHANCE_COFFRET[partie.genre] or 0) then
		task.delay(2.5, CarteNaine.donnerFragment, joueur, "peche")
	end
end)

Players.PlayerRemoving:Connect(function(joueur)
	parties[joueur] = nil
	derniere[joueur] = nil
end)
