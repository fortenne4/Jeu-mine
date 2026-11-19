--!strict
-- Sauvegarde des joueurs (ModuleScript, ServerScriptService › Jeu › Donnees)
-- Une seule clé par joueur dans le DataStore « JeuMine », verrouillée par le serveur qui l'utilise :
-- si le joueur rejoint un autre serveur avant la fin de la sauvegarde, rien n'est dupliqué ni perdu.
--
-- Ce qui est sauvegardé : les Pièces (leaderstats), les pioches achetées, la pioche équipée,
-- le sac de minerais, les objets forgés chez Brom et l'équipement porté (schéma v3).
-- Les autres scripts ne touchent jamais au DataStore : ils lisent/modifient le profil en mémoire.
--   local Donnees = require(script.Parent.Donnees)
--   local profil = Donnees.attendre(joueur)   -- nil si le joueur est parti avant le chargement
--   profil.pioches.Givre = true
-- Le joueur reçoit l'attribut « DonneesChargees » quand son profil est prêt.
--
-- Studio : active « Enable Studio Access to API Services » (Paramètres du jeu › Sécurité) pour tester
-- la vraie sauvegarde. Sinon le jeu marche quand même, mais rien n'est sauvegardé (message dans la sortie).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
local Forge = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Forge"))

local CONFIG = {
	STORE = "JeuMine",
	AUTOSAVE = 60, -- secondes entre deux sauvegardes automatiques
	VERROU_PERIME = 150, -- un verrou plus vieux que ça vient d'un serveur planté : on le reprend
	ESSAIS_VERROU = 6, -- tentatives si un autre serveur garde encore le profil (5 s d'écart)
	ESSAIS = 4, -- tentatives en cas d'erreur du DataStore (attente 1, 2, 4 s)
	MONNAIE = "Pièces",
	-- Test dans Studio : pièces données d'office à chaque Play (0 = désactivé).
	-- Cette partie de test n'est alors pas sauvegardée, pour ne pas gonfler la vraie sauvegarde.
	ARGENT_TEST_STUDIO = 5_000_000,
}
local VERSION = 3
local MAX_OBJETS = 200

-- Objet forgé chez Brom (Forge.server.lua) ; couleur en hexadécimal, composition {{idMinerai, quantite}}
export type Objet = {id: string, type: string, nom: string, couleur: string, stat: string, valeur: number, composition: {{any}}}

export type Profil = {
	version: number,
	pieces: number,
	pioches: {[string]: boolean},
	equipee: string,
	minerais: {[string]: number},
	objets: {Objet},
	prochainId: number,
	equipement: {[string]: string}, -- emplacement (type d'objet forgé) → id de l'objet porté
	inconnus: {minerais: {[any]: any}, objets: {any}, equipement: {[any]: any}},
}

type Session = {profil: Profil, sauvegarde: boolean, libere: boolean}

local Donnees = {}

local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(CONFIG.STORE)
end)

local sessions: {[Player]: Session} = {}
local ecrituresEnCours = 0 -- la fermeture du serveur attend aussi les sauvegardes de départ déjà lancées
local enAttente: {[Player]: {thread}} = {}

local function profilVide(): Profil
	return {version = VERSION, pieces = 0, pioches = {[Pioches.DEPART] = true}, equipee = Pioches.DEPART,
		minerais = {}, objets = {}, prochainId = 1, equipement = {}, inconnus = {minerais = {}, objets = {}, equipement = {}}}
end

-- MIGRATIONS[v] transforme une sauvegarde de la version v en v + 1
local MIGRATIONS: {[number]: (any) -> any} = {
	[1] = function(b)
		b.minerais, b.objets, b.prochainId = b.minerais or {}, b.objets or {}, b.prochainId or 1
		return b
	end,
	[2] = function(b)
		b.equipement = b.equipement or {}
		return b
	end,
}

-- Entier écrêté dans [0, max] ; nil si ce n'est pas un nombre fini
local function entier(x: any, max: number): number?
	local n = tonumber(x)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return nil
	end
	return math.clamp(math.floor(n), 0, max)
end

local function lireObjet(o: any): Objet?
	if type(o) ~= "table" or type(o.id) ~= "string" or type(o.nom) ~= "string" or type(o.stat) ~= "string"
		or type(o.couleur) ~= "string" or not Forge.TYPES[o.type] or not entier(o.valeur, 1e6) or type(o.composition) ~= "table" then
		return nil
	end
	local compo = {}
	for _, e in o.composition do
		local q = type(e) == "table" and Forge.MINERAIS[e[1]] and entier(e[2], Forge.QTE_MAX)
		if q then
			table.insert(compo, {e[1], q})
		end
	end
	return {id = o.id, type = o.type, nom = o.nom, couleur = o.couleur, stat = o.stat,
		valeur = entier(o.valeur, 1e6) :: number, composition = compo}
end

-- Nettoie une sauvegarde lue (types, pioches inconnues) : jamais de confiance aveugle
local function lire(brut: any): Profil
	local p = profilVide()
	if type(brut) ~= "table" then
		return p
	end
	local v = tonumber(brut.version) or VERSION
	if v > VERSION then
		error("sauvegarde plus récente (v" .. v .. ") que ce serveur (v" .. VERSION .. ")")
	end
	v = if v == v then math.clamp(math.floor(v), 1, VERSION) else 1
	while v < VERSION do
		local etape = MIGRATIONS[v]
		if not etape then
			error("migration manquante depuis la version " .. v)
		end
		brut = etape(brut)
		v += 1
	end
	p.pieces = math.max(0, math.floor(tonumber(brut.pieces) or 0))
	if type(brut.pioches) == "table" then
		for id, possede in brut.pioches do
			if possede == true and Pioches.get(id) then
				p.pioches[id] = true
			end
		end
	end
	if Pioches.get(brut.equipee) and p.pioches[brut.equipee] then
		p.equipee = brut.equipee
	end
	-- Minerais / objets inconnus de ce serveur : gardés tels quels dans « inconnus » et réécrits (jamais supprimés)
	local inconnus = type(brut.inconnus) == "table" and brut.inconnus or {}
	for _, source in {inconnus.minerais, brut.minerais} do
		if type(source) ~= "table" then
			continue
		end
		for id, n in source do
			local q = entier(n, 1e9)
			if Forge.MINERAIS[id] and q then
				if q > 0 then
					p.minerais[id] = math.min((p.minerais[id] or 0) + q, 1e9)
				end
			else
				p.inconnus.minerais[id] = n
			end
		end
	end
	for _, source in {inconnus.objets, brut.objets} do
		if type(source) ~= "table" then
			continue
		end
		for _, o in source do
			local objet = lireObjet(o)
			if objet and #p.objets < MAX_OBJETS then
				table.insert(p.objets, objet)
			else
				table.insert(p.inconnus.objets, o)
			end
		end
	end
	p.prochainId = math.max(entier(brut.prochainId, 1e12) or 1, #p.objets + 1)
	-- Équipement : l'objet doit exister et être du bon type, sinon gardé dans « inconnus »
	for _, source in {brut.equipement, inconnus.equipement} do
		if type(source) ~= "table" then
			continue
		end
		for slot, id in source do
			if p.equipement[slot] ~= nil then
				continue
			elseif Donnees.objetDeType(p, id, slot) then
				p.equipement[slot] = id
			else
				p.inconnus.equipement[slot] = id
			end
		end
	end
	return p
end

-- Ce qui est écrit dans le DataStore
local function serialiser(p: Profil, verrou: any): any
	local pioches = {}
	for id in p.pioches do
		pioches[id] = true
	end
	return {version = VERSION, pieces = p.pieces, pioches = pioches, equipee = p.equipee,
		minerais = table.clone(p.minerais), objets = table.clone(p.objets), prochainId = p.prochainId,
		equipement = table.clone(p.equipement), verrou = verrou,
		inconnus = if next(p.inconnus.minerais) or #p.inconnus.objets > 0 or next(p.inconnus.equipement) then p.inconnus else nil}
end

-- arret() vrai : on cesse les relances (ex. session libérée entre-temps)
local function avecEssais<T>(fn: () -> T, arret: (() -> boolean)?): (boolean, any)
	local attente = 1
	local erreur: any = nil
	for essai = 1, CONFIG.ESSAIS do
		if essai > 1 and arret and arret() then
			return false, "abandon : session libérée"
		end
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		erreur = res
		warn(string.format("[Donnees] essai %d/%d échoué : %s", essai, CONFIG.ESSAIS, tostring(res)))
		if essai < CONFIG.ESSAIS then
			task.wait(attente)
			attente *= 2
		end
	end
	return false, erreur
end

local function cle(joueur: Player): string
	return "joueur_" .. joueur.UserId
end

local function compteur(joueur: Player): IntValue
	local stats = joueur:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = joueur
	end
	local v = (stats :: Instance):FindFirstChild(CONFIG.MONNAIE)
	if not (v and v:IsA("IntValue")) then
		v = Instance.new("IntValue")
		v.Name = CONFIG.MONNAIE
		v.Parent = stats
	end
	return v :: IntValue
end

-- Le profil en mémoire reprend l'état du jeu (pièces, pioche équipée) juste avant d'écrire
local function synchroniser(joueur: Player, s: Session)
	s.profil.pieces = math.max(0, compteur(joueur).Value)
	local equipee = joueur:GetAttribute("Pioche")
	if type(equipee) == "string" and s.profil.pioches[equipee] then
		s.profil.equipee = equipee
	end
end

-- ===== Chargement : prend le verrou dans la même écriture atomique =====
local function charger(joueur: Player): (Profil?, string?)
	if not store then
		return nil, "DataStore indisponible"
	end
	local ds = store :: DataStore
	for _ = 1, CONFIG.ESSAIS_VERROU do
		local verrouAilleurs = false
		local profil: Profil? = nil
		local ok, err = avecEssais(function()
			return ds:UpdateAsync(cle(joueur), function(ancien: any)
				verrouAilleurs = false
				local verrou = type(ancien) == "table" and ancien.verrou
				if type(verrou) == "table" and verrou.serveur ~= game.JobId
					and os.time() - (tonumber(verrou.t) or 0) < CONFIG.VERROU_PERIME then
					verrouAilleurs = true
					return nil -- un autre serveur sauvegarde encore : on n'écrit rien
				end
				local p = lire(ancien)
				profil = p
				return serialiser(p, {serveur = game.JobId, t = os.time()})
			end)
		end)
		if not ok then
			return nil, tostring(err)
		end
		if not verrouAilleurs and profil then
			return profil, nil
		end
		if not joueur.Parent then
			return nil, "parti"
		end
		task.wait(5)
	end
	return nil, "verrou"
end

-- ===== Écriture (autosave, départ, fermeture) =====
local function sauvegarder(joueur: Player, liberer: boolean): boolean
	local s = sessions[joueur]
	if not s or not s.sauvegarde or s.libere or not store then
		return true
	end
	if liberer then
		s.libere = true -- une seule libération, même si départ et fermeture arrivent ensemble
	end
	synchroniser(joueur, s)
	local p = s.profil
	local ds = store :: DataStore
	ecrituresEnCours += 1
	local ok, err = avecEssais(function()
		return ds:UpdateAsync(cle(joueur), function(ancien: any)
			local verrou = type(ancien) == "table" and ancien.verrou
			if type(verrou) == "table" and verrou.serveur ~= game.JobId then
				return nil -- le profil a été repris ailleurs : ne pas l'écraser
			end
			if s.libere and not liberer then
				return nil -- autosave tardive après la libération : ne pas reposer le verrou
			end
			return serialiser(p, if liberer then nil else {serveur = game.JobId, t = os.time()})
		end)
	end, if liberer then nil else function()
		return s.libere
	end)
	ecrituresEnCours -= 1
	if not ok then
		warn("[Donnees] Sauvegarde ratée pour " .. joueur.Name .. " : " .. tostring(err))
	end
	return ok
end

-- ===== API =====
function Donnees.profil(joueur: Player): Profil?
	local s = sessions[joueur]
	return s and s.profil
end

Donnees.MAX_OBJETS = MAX_OBJETS

-- Vrai si le profil possède l'objet `id` et qu'il est du type `typeObjet`
function Donnees.objetDeType(p: Profil, id: any, typeObjet: any): boolean
	if type(id) ~= "string" or type(typeObjet) ~= "string" then
		return false
	end
	for _, o in p.objets do
		if o.id == id then
			return o.type == typeObjet
		end
	end
	return false
end

-- Changement du sac / des objets : les écouteurs (Sac.server) sont prévenus une fois par image au plus
local ecouteurs: {(Player) -> ()} = {}
local prevenus: {[Player]: boolean} = {}
function Donnees.surChangement(fn: (Player) -> ())
	table.insert(ecouteurs, fn)
end
function Donnees.notifier(joueur: Player)
	if prevenus[joueur] then
		return
	end
	prevenus[joueur] = true
	task.defer(function()
		prevenus[joueur] = nil
		if sessions[joueur] then
			for _, fn in ecouteurs do
				task.spawn(fn, joueur)
			end
		end
	end)
end

-- Ajoute (ou retire si n < 0) des minerais au sac du joueur ; renvoie false si le profil n'est pas prêt
function Donnees.ajouterMinerai(joueur: Player, id: string, n: number): boolean
	local p = Donnees.profil(joueur)
	if not p or not Forge.MINERAIS[id] then
		return false
	end
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return false
	end
	local q = math.clamp((p.minerais[id] or 0) + math.floor(n), 0, 1e9)
	p.minerais[id] = if q > 0 then q else nil
	Donnees.notifier(joueur)
	return true
end

-- Vrai si la session de ce joueur écrit dans le DataStore (faux en partie de test Studio)
function Donnees.estSauvegarde(joueur: Player): boolean
	local s = sessions[joueur]
	return s ~= nil and s.sauvegarde and not s.libere
end

-- Attend que le profil soit chargé (nil si le joueur part ou si le chargement échoue)
function Donnees.attendre(joueur: Player): Profil?
	if sessions[joueur] then
		return sessions[joueur].profil
	end
	if not joueur.Parent then
		return nil
	end
	enAttente[joueur] = enAttente[joueur] or {}
	table.insert(enAttente[joueur], coroutine.running())
	coroutine.yield()
	local s = sessions[joueur]
	return s and s.profil
end

local function reveiller(joueur: Player)
	local liste = enAttente[joueur]
	enAttente[joueur] = nil
	for _, th in liste or {} do
		task.spawn(th)
	end
end

-- ===== Cycle de vie =====
local function surJoueur(joueur: Player)
	local profil, erreur = charger(joueur)
	if not joueur.Parent then
		-- parti pendant le chargement : on rend le verrou tout de suite
		if profil then
			-- on remet d'abord le compteur à la valeur chargée, sinon la sauvegarde écrirait 0 pièce
			compteur(joueur).Value = profil.pieces
			joueur:SetAttribute("Pioche", profil.equipee)
			sessions[joueur] = {profil = profil, sauvegarde = true, libere = false}
			sauvegarder(joueur, true)
			sessions[joueur] = nil
		end
		reveiller(joueur)
		return
	end
	local sauvegarde = true
	if not profil then
		if erreur == "verrou" then
			joueur:Kick("Ta partie précédente est encore en train de se sauvegarder. Reviens dans une minute !")
			reveiller(joueur)
			return
		elseif RunService:IsStudio() then
			-- Studio sans accès aux API : on joue, mais sans rien écrire (pour ne jamais écraser une vraie sauvegarde)
			warn("[Donnees] Pas de sauvegarde en Studio (" .. tostring(erreur) .. "). Active l'accès aux API pour la tester.")
			profil = profilVide()
			sauvegarde = false
		else
			-- Ne JAMAIS jouer avec un profil vide : sa sauvegarde écraserait la vraie
			joueur:Kick("Impossible de charger ta sauvegarde. Reviens dans un instant !")
			reveiller(joueur)
			return
		end
	end
	local p = profil :: Profil
	sessions[joueur] = {profil = p, sauvegarde = sauvegarde, libere = false}
	compteur(joueur).Value = p.pieces
	joueur:SetAttribute("Pioche", p.equipee)

	if RunService:IsStudio() and CONFIG.ARGENT_TEST_STUDIO > 0 then
		-- On rend tout de suite la sauvegarde intacte (et son verrou), puis la partie de test ne sauvegarde plus rien
		local s = sessions[joueur]
		sauvegarder(joueur, true) -- écrit puis libère (s.libere passe à vrai avant toute attente)
		s.sauvegarde = false
		compteur(joueur).Value = CONFIG.ARGENT_TEST_STUDIO
		print(string.format("[Donnees] Test Studio : %d %s pour %s (partie non sauvegardée)",
			CONFIG.ARGENT_TEST_STUDIO, CONFIG.MONNAIE, joueur.Name))
	end

	joueur:SetAttribute("DonneesChargees", true)
	reveiller(joueur)

	-- Autosave décalée selon le joueur pour ne pas tout écrire au même moment
	task.spawn(function()
		task.wait(joueur.UserId % CONFIG.AUTOSAVE)
		while sessions[joueur] and not sessions[joueur].libere do
			sauvegarder(joueur, false)
			task.wait(CONFIG.AUTOSAVE)
		end
	end)
end

Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end

Players.PlayerRemoving:Connect(function(joueur)
	if sessions[joueur] then
		sauvegarder(joueur, true)
		sessions[joueur] = nil
	end
	reveiller(joueur)
end)

game:BindToClose(function()
	for joueur in sessions do
		task.spawn(sauvegarder, joueur, true)
	end
	local debut = os.clock()
	while ecrituresEnCours > 0 and os.clock() - debut < 25 do
		task.wait(0.1)
	end
end)

return Donnees
