--!strict
-- Guilde des Mineurs · SCRIPT SERVEUR
-- Margot (taverne) tient le tableau de la Guilde : l'histoire « La Veine d'Étoile » et les contrats du jour.
-- Toute la logique (progression, livraisons, récompenses, rangs) est ici ; le client ne fait qu'afficher et demander.
--
-- Remotes (ReplicatedStorage) :
--   QuetesOuvrir (RemoteEvent, serveur → client) : (etat, pointInteraction)
--   QuetesMaj    (RemoteEvent, serveur → client) : (etat, evenement?) — suivi à l'écran et notifications
--   QuetesAction (RemoteFunction, client → serveur) : {action = "accepter"|"rendre"|"abandonner"|"coffre", cible = "histoire"|"contrat", i = number?}
-- Progression : ServerStorage.MineraiCasse (pioche) et ServerStorage.QueteEvenement (forge, boutique, wagonnet).
-- Bonus de rang : attribut « BonusGuilde » du joueur (pourcentage), lu par Marchand.server.lua (vente).
-- Tests (Studio, partie non sauvegardée) : game.ServerStorage.QuetesAPI:Invoke("renommee", game.Players.TonNom, 500)
--   autres commandes : "histoire" (index), "finir" (complète les objectifs en cours), "reset"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Q = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Quetes"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CONFIG = {
	MONNAIE = "Pièces",
	SERVICE = "Taverne", -- attribut « Service » de Margot (Village.lua)
	DISTANCE_PROMPT = 12,
	DISTANCE_ACTION = 24,
	ANTI_SPAM = 0.25,
}

type Etat = {[string]: any}

-- ===== Remotes =====
local ouvrir = Instance.new("RemoteEvent")
ouvrir.Name = "QuetesOuvrir"
ouvrir.Parent = ReplicatedStorage
local maj = Instance.new("RemoteEvent")
maj.Name = "QuetesMaj"
maj.Parent = ReplicatedStorage
local action = Instance.new("RemoteFunction")
action.Name = "QuetesAction"
action.Parent = ReplicatedStorage
local evenementQuete = Instance.new("BindableEvent")
evenementQuete.Name = "QueteEvenement"
evenementQuete.Parent = ServerStorage

local pointMargot: BasePart? = nil
local derniereRequete: {[Player]: number} = {}
local dejaFinies: {[Player]: {[string]: boolean}} = {}

-- ===== Validation des données sauvegardées =====
local TYPES_OBJECTIF = {miner = true, livrer = true, forger = true, pioche = true, wagon = true}

local function entier(x: any, max: number): number
	local n = tonumber(x)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return 0
	end
	return math.clamp(math.floor(n), 0, max)
end

local function queteValide(d: any): boolean
	if type(d) ~= "table" or type(d.id) ~= "string" or type(d.titre) ~= "string" or type(d.objectifs) ~= "table"
		or type(d.recompense) ~= "table" or not Q.PNJ[d.pnj] then
		return false
	end
	for _, o in d.objectifs do
		if type(o) ~= "table" or not TYPES_OBJECTIF[o.type] or entier(o.n, 1e6) < 1 then
			return false
		end
	end
	return true
end

-- Remet d'aplomb la partie « quetes » du profil (types, jour, contrats)
local function preparer(joueur: Player, p: Donnees.Profil): {[string]: any}
	local q = p.quetes
	q.renommee = entier(q.renommee, 1e9)
	q.h = math.clamp(entier(q.h, 1e4), 1, #Q.HISTOIRE + 1)
	q.hEtat = if q.hEtat == "active" then "active" else "dispo"
	q.hProg = if type(q.hProg) == "table" then q.hProg else {}
	q.rendues = entier(q.rendues, 1e9)
	local jour = Q.jour()
	local contratsOk = entier(q.jour, 1e9) == jour and type(q.contrats) == "table" and #q.contrats == Q.NB_CONTRATS
	if contratsOk then
		for _, c in q.contrats do
			if type(c) ~= "table" or not queteValide(c.def) then
				contratsOk = false
			end
		end
	end
	if not contratsOk then
		local rang = Q.rang(q.renommee)
		q.jour = jour
		q.coffre = false
		q.contrats = {}
		for _, def in Q.genererContrats(jour, joueur.UserId, rang) do
			table.insert(q.contrats, {def = def, etat = "dispo", prog = {}})
		end
	end
	for _, c in q.contrats do
		c.etat = if c.etat == "active" or c.etat == "rendue" then c.etat else "dispo"
		c.prog = if type(c.prog) == "table" then c.prog else {}
	end
	q.coffre = q.coffre == true
	return q
end

local function quetes(joueur: Player): {[string]: any}?
	local p = Donnees.profil(joueur)
	if not p then
		return nil
	end
	local q = p.quetes
	if q.jour ~= Q.jour() or type(q.contrats) ~= "table" then
		return preparer(joueur, p)
	end
	return q
end

local function compteur(joueur: Player): IntValue?
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild(CONFIG.MONNAIE)
	return if v and v:IsA("IntValue") then v else nil
end

-- ===== Progression =====
-- Valeur actuelle d'un objectif : compteur pour miner/forger/wagon, état réel pour livrer/pioche
local function valeur(joueur: Player, o: Q.Objectif, prog: {any}, i: number): number
	local p = Donnees.profil(joueur)
	if o.type == "livrer" then
		return math.min(o.n, if p and o.cible then (p.minerais[o.cible] or 0) else 0)
	elseif o.type == "pioche" then
		return if p and o.cible and p.pioches[o.cible] then 1 else 0
	end
	return math.min(o.n, entier(prog[i], 1e6))
end

local function progression(joueur: Player, def: Q.Quete, prog: {any}): ({number}, boolean)
	local valeurs, fini = {}, true
	for i, o in def.objectifs do
		valeurs[i] = valeur(joueur, o, prog, i)
		if valeurs[i] < o.n then
			fini = false
		end
	end
	return valeurs, fini
end

-- Liste des quêtes en cours : {def, prog, cle}
local function enCours(q: {[string]: any}): {{def: Q.Quete, prog: {any}, cle: string}}
	local liste = {}
	local h = Q.histoire(q.h)
	if h and q.hEtat == "active" then
		table.insert(liste, {def = h, prog = q.hProg, cle = h.id})
	end
	for _, c in q.contrats do
		if c.etat == "active" then
			table.insert(liste, {def = c.def, prog = c.prog, cle = c.def.id})
		end
	end
	return liste
end

local function etat(joueur: Player): Etat?
	local q = quetes(joueur)
	if not q then
		return nil
	end
	local h = Q.histoire(q.h)
	local hProg, hFini = {}, false
	if h then
		hProg, hFini = progression(joueur, h, q.hProg)
	end
	local contrats = {}
	for _, c in q.contrats do
		local valeurs, fini = progression(joueur, c.def, c.prog)
		table.insert(contrats, {def = c.def, etat = c.etat, prog = valeurs, fini = fini})
	end
	local reset = (Q.jour() + 1) * 86400 - os.time()
	return {renommee = q.renommee, h = q.h, hEtat = q.hEtat, hProg = hProg, hFini = hFini, contrats = contrats,
		coffre = q.coffre, reset = reset, rendues = q.rendues}
end

local function appliquerRang(joueur: Player)
	local q = quetes(joueur)
	if q then
		local i, r = Q.rang(q.renommee)
		joueur:SetAttribute("BonusGuilde", r.bonus)
		joueur:SetAttribute("RangGuilde", i)
	end
end

-- Envoi groupé (une fois par image au plus) + détection des quêtes qui viennent d'être terminées
local envoiPrevu: {[Player]: boolean} = {}
local evenementsEnAttente: {[Player]: {any}} = {}
local function envoyer(joueur: Player, evenement: any?)
	if evenement then
		evenementsEnAttente[joueur] = evenementsEnAttente[joueur] or {}
		table.insert(evenementsEnAttente[joueur], evenement)
	end
	if envoiPrevu[joueur] then
		return
	end
	envoiPrevu[joueur] = true
	task.defer(function()
		envoiPrevu[joueur] = nil
		if not joueur.Parent then
			return
		end
		local q = quetes(joueur)
		local e = etat(joueur)
		if not (q and e) then
			return
		end
		local evts = evenementsEnAttente[joueur] or {}
		evenementsEnAttente[joueur] = nil
		local finies = dejaFinies[joueur] or {}
		dejaFinies[joueur] = finies
		for _, c in enCours(q) do
			local _, fini = progression(joueur, c.def, c.prog)
			if fini and not finies[c.cle] then
				table.insert(evts, {type = "fini", titre = c.def.titre})
			end
			finies[c.cle] = fini
		end
		maj:FireClient(joueur, e, evts)
	end)
end

-- Ajoute n à tous les objectifs « genre » (et cible) des quêtes en cours
local function avancer(joueur: Player, genre: string, cible: string?, n: number)
	if not joueur:GetAttribute("DonneesChargees") then
		return
	end
	local q = quetes(joueur)
	if not q then
		return
	end
	local change = false
	for _, c in enCours(q) do
		for i, o in c.def.objectifs do
			if o.type == genre and (o.cible == nil or o.cible == cible) then
				local avant = entier(c.prog[i], 1e6)
				if avant < o.n then
					c.prog[i] = math.min(o.n, avant + n)
					change = true
					if c.prog[i] >= o.n then
						envoyer(joueur, {type = "objectif", texte = Q.texteObjectif(o)})
					end
				end
			end
		end
	end
	if change then
		envoyer(joueur)
	end
end

-- ===== Actions du client =====
local function procheDeMargot(joueur: Player): boolean
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (racine and racine:IsA("BasePart") and pointMargot) then
		return false
	end
	return (racine.Position - pointMargot.Position).Magnitude <= CONFIG.DISTANCE_ACTION
end

local function reponse(joueur: Player, ok: boolean, message: string, extra: {[string]: any}?): {[string]: any}
	local r: {[string]: any} = {ok = ok, message = message, etat = etat(joueur)}
	for k, v in extra or {} do
		r[k] = v
	end
	return r
end

local function recompenser(joueur: Player, q: {[string]: any}, pieces: number, renommee: number): (boolean, number)
	local rangAvant = Q.rang(q.renommee)
	local v = compteur(joueur)
	if v then
		v.Value += pieces
	end
	q.renommee = math.min(1e9, q.renommee + renommee)
	q.rendues += 1
	appliquerRang(joueur)
	local rangApres = Q.rang(q.renommee)
	return rangApres > rangAvant, rangApres
end

action.OnServerInvoke = function(joueur: Player, demande: any)
	local maintenant = os.clock()
	if maintenant - (derniereRequete[joueur] or 0) < CONFIG.ANTI_SPAM then
		return reponse(joueur, false, "Doucement !")
	end
	derniereRequete[joueur] = maintenant
	if type(demande) ~= "table" or type(demande.action) ~= "string" then
		return reponse(joueur, false, "Requête invalide")
	end
	local q = quetes(joueur)
	if not q then
		return reponse(joueur, false, "Patiente un instant…")
	end
	if not procheDeMargot(joueur) then
		return reponse(joueur, false, "Approche-toi du tableau de Margot")
	end

	-- Coffre des contrats du jour
	if demande.action == "coffre" then
		if q.coffre then
			return reponse(joueur, false, "Coffre déjà ouvert aujourd'hui")
		end
		local total = 0
		for _, c in q.contrats do
			if c.etat ~= "rendue" then
				return reponse(joueur, false, "Rends d'abord les 3 contrats du jour")
			end
			total += c.def.recompense.pieces
		end
		q.coffre = true
		local pieces = math.floor(total * Q.BONUS_COFFRE)
		local monte, rang = recompenser(joueur, q, pieces, 25)
		envoyer(joueur)
		return reponse(joueur, true, string.format("Coffre de la Guilde : +%d pièces !", pieces),
			{pieces = pieces, renommee = 25, rangMonte = monte, rang = rang})
	end

	-- Cible : l'histoire ou un contrat
	local def: Q.Quete?, porteur: {[string]: any}? = nil, nil
	if demande.cible == "histoire" then
		def = Q.histoire(q.h)
	elseif demande.cible == "contrat" and type(demande.i) == "number" then
		porteur = q.contrats[demande.i]
		def = porteur and porteur.def
	end
	if not def then
		return reponse(joueur, false, "Quête introuvable")
	end
	local etatQuete = if porteur then porteur.etat else q.hEtat
	local prog = if porteur then porteur.prog else q.hProg

	if demande.action == "accepter" then
		if etatQuete ~= "dispo" then
			return reponse(joueur, false, "Quête déjà en cours")
		end
		if porteur then
			porteur.etat, porteur.prog = "active", {}
		else
			q.hEtat, q.hProg = "active", {}
		end
		envoyer(joueur)
		return reponse(joueur, true, "Quête acceptée : " .. def.titre)
	elseif demande.action == "abandonner" then
		if not porteur or etatQuete ~= "active" then
			return reponse(joueur, false, "Impossible d'abandonner cette quête")
		end
		porteur.etat, porteur.prog = "dispo", {}
		if dejaFinies[joueur] then
			dejaFinies[joueur][def.id] = nil
		end
		envoyer(joueur)
		return reponse(joueur, true, "Contrat abandonné")
	elseif demande.action == "rendre" then
		if etatQuete ~= "active" then
			return reponse(joueur, false, "Accepte d'abord cette quête")
		end
		local _, fini = progression(joueur, def, prog)
		if not fini then
			return reponse(joueur, false, "Objectifs pas encore remplis")
		end
		-- Livraisons : on retire les minerais du sac (vérifiés juste au-dessus)
		for _, o in def.objectifs do
			if o.type == "livrer" and o.cible then
				Donnees.ajouterMinerai(joueur, o.cible, -o.n)
			end
		end
		if porteur then
			porteur.etat = "rendue"
		else
			q.h += 1
			q.hEtat, q.hProg = "dispo", {}
		end
		if dejaFinies[joueur] then
			dejaFinies[joueur][def.id] = nil
		end
		local monte, rang = recompenser(joueur, q, def.recompense.pieces, def.recompense.renommee)
		print(string.format("[Quetes] %s rend « %s » (+%d %s, +%d renommée)", joueur.Name, def.titre,
			def.recompense.pieces, CONFIG.MONNAIE, def.recompense.renommee))
		envoyer(joueur)
		return reponse(joueur, true, def.titre .. " : accomplie !", {pieces = def.recompense.pieces, renommee = def.recompense.renommee,
			rangMonte = monte, rang = rang, fin = def.fin, pnj = def.pnj, histoireFinie = (not porteur) and q.h > #Q.HISTOIRE})
	end
	return reponse(joueur, false, "Requête invalide")
end

-- ===== Événements de jeu =====
task.spawn(function()
	local casse = ServerStorage:WaitForChild("MineraiCasse", 60)
	if casse and casse:IsA("BindableEvent") then
		casse.Event:Connect(function(joueur, bloc)
			if typeof(joueur) == "Instance" and joueur:IsA("Player") and typeof(bloc) == "Instance" then
				avancer(joueur, "miner", bloc:GetAttribute("Type") :: string?, 1)
			end
		end)
	else
		warn("[Quetes] MineraiCasse introuvable : les objectifs de minage n'avanceront pas.")
	end
end)

evenementQuete.Event:Connect(function(genre: string, joueur: Player, cible: any)
	if typeof(joueur) ~= "Instance" or not joueur:IsA("Player") then
		return
	end
	if genre == "forger" or genre == "wagon" then
		avancer(joueur, genre, if type(cible) == "string" then cible else nil, 1)
	elseif genre == "pioche" then
		envoyer(joueur) -- l'objectif « pioche » se lit sur le profil
	end
end)

-- Le sac change (minage, forge, livraison) : les objectifs « livrer » bougent
Donnees.surChangement(function(joueur)
	local q = quetes(joueur)
	if not q then
		return
	end
	for _, c in enCours(q) do
		for _, o in c.def.objectifs do
			if o.type == "livrer" then
				envoyer(joueur)
				return
			end
		end
	end
end)

-- ===== Joueurs =====
local function surJoueur(joueur: Player)
	local p = Donnees.attendre(joueur)
	if not (p and joueur.Parent) then
		return
	end
	preparer(joueur, p)
	appliquerRang(joueur)
	dejaFinies[joueur] = {}
	local q = quetes(joueur)
	if q then
		for _, c in enCours(q) do
			local _, fini = progression(joueur, c.def, c.prog)
			dejaFinies[joueur][c.cle] = fini
		end
	end
	envoyer(joueur)
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end
Players.PlayerRemoving:Connect(function(joueur)
	derniereRequete[joueur] = nil
	dejaFinies[joueur] = nil
	envoiPrevu[joueur] = nil
	evenementsEnAttente[joueur] = nil
end)

-- Changement de jour pendant la partie : nouveaux contrats
task.spawn(function()
	local jour = Q.jour()
	while true do
		task.wait(30)
		if Q.jour() ~= jour then
			jour = Q.jour()
			for _, j in Players:GetPlayers() do
				local p = Donnees.profil(j)
				if p then
					preparer(j, p)
					envoyer(j, {type = "info", texte = "Nouveaux contrats au tableau de la Guilde !"})
				end
			end
		end
	end
end)

-- ===== Margot : « Tableau de la Guilde » =====
local function trouverMargot(): Instance?
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == CONFIG.SERVICE then
			return d
		end
	end
	return nil
end

local function pointInteraction(pnj: Instance): BasePart?
	local centre: Vector3, bas: number
	if pnj:IsA("Model") then
		local cf, taille = pnj:GetBoundingBox()
		centre, bas = cf.Position, cf.Position.Y - taille.Y / 2
	else
		local racine = pnj:FindFirstChildWhichIsA("BasePart", true) or (if pnj:IsA("BasePart") then pnj else nil)
		if not racine then
			return nil
		end
		centre, bas = racine.Position, racine.Position.Y - racine.Size.Y / 2
	end
	local part = Instance.new("Part")
	part.Name = "InteractionGuilde"
	part.Size = Vector3.one
	part.CFrame = CFrame.new(centre.X, bas + 3, centre.Z)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = workspace
	return part
end

task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do
		task.wait(0.25)
	end
	local margot = trouverMargot()
	local attente = os.clock()
	while not margot and os.clock() - attente < 30 do
		task.wait(1)
		margot = trouverMargot()
	end
	local part = margot and pointInteraction(margot)
	if not part then
		warn("[Quetes] Margot introuvable (attribut Service = \"Taverne\") : pas de tableau de la Guilde.")
		return
	end
	pointMargot = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptGuilde"
	prompt.ActionText = "Tableau de la Guilde"
	prompt.ObjectText = "Margot · Guilde des Mineurs"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.DISTANCE_PROMPT
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -115)
	prompt:SetAttribute("Theme", "Boutique") -- dessinée par Boutique.client.lua, comme celles de Liesel et Brom
	prompt.Parent = part
	prompt.Triggered:Connect(function(joueur)
		local e = etat(joueur)
		if e then
			ouvrir:FireClient(joueur, e, part)
		end
	end)
end)

-- ===== Outils de test (Studio uniquement, jamais sur une partie sauvegardée) =====
if RunService:IsStudio() then
	local api = Instance.new("BindableFunction")
	api.Name = "QuetesAPI"
	api.OnInvoke = function(commande: string, joueur: Player, val: any)
		local p = Donnees.profil(joueur)
		if not p or Donnees.estSauvegarde(joueur) then
			return "partie sauvegardée : outils de test désactivés"
		end
		local q = preparer(joueur, p)
		if commande == "renommee" then
			q.renommee = entier(val, 1e9)
		elseif commande == "histoire" then
			q.h, q.hEtat, q.hProg = math.clamp(entier(val, 1e4), 1, #Q.HISTOIRE + 1), "dispo", {}
		elseif commande == "finir" then
			for _, c in enCours(q) do
				for i, o in c.def.objectifs do
					c.prog[i] = o.n
				end
			end
		elseif commande == "reset" then
			p.quetes = {}
			preparer(joueur, p)
		end
		appliquerRang(joueur)
		envoyer(joueur)
		return etat(joueur)
	end
	api.Parent = ServerStorage
end
