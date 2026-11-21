--!strict
-- Comptoir des minerais de Gaspard · SCRIPT SERVEUR
-- Le joueur parle à Gaspard (ProximityPrompt « Vendre mes minerais ») → le serveur ouvre le comptoir chez lui.
-- Le client propose une vente ; le serveur vérifie tout (stock, distance, cadence), retire les minerais
-- du sac PUIS crédite les Pièces, sans attente entre les deux : pas de duplication possible.
--
-- Remotes (ReplicatedStorage) :
--   MarchandOuvrir (RemoteEvent, serveur → client) : (etat, pointInteraction)
--   MarchandAction (RemoteFunction, client → serveur) :
--     {action = "vendre", id = string, quantite = entier} | {action = "toutVendre"} → {ok, message, etat, gain}
-- Prix : Partage › PrixMinerais (source unique).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local PrixMinerais = require(Partage:WaitForChild("PrixMinerais"))
local Forge = require(Partage:WaitForChild("Forge"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CONFIG = {
	SERVICE = "Vente", -- attribut « Service » du PNJ Gaspard (Village.lua)
	MONNAIE = "Pièces",
	DISTANCE_PROMPT = 12,
	DISTANCE_VENTE = 22, -- au-delà, le serveur refuse (le client ferme le comptoir avant, à 16)
	ANTI_SPAM = 0.25, -- secondes minimum entre deux requêtes d'un joueur
}

type Etat = {minerais: {[string]: number}, prix: {[string]: number}}
type Reponse = {ok: boolean, message: string, etat: Etat?, gain: number?}

local ouvrir = Instance.new("RemoteEvent")
ouvrir.Name = "MarchandOuvrir"
ouvrir.Parent = ReplicatedStorage

local action = Instance.new("RemoteFunction")
action.Name = "MarchandAction"
action.Parent = ReplicatedStorage

local derniere: {[Player]: number} = {}
local pointGaspard: BasePart? = nil

-- Copie : seulement les minerais qui ont un prix
local function etat(p: Donnees.Profil): Etat
	local m = {}
	for id in PrixMinerais.PRIX do
		local q = p.minerais[id]
		if q and q > 0 then
			m[id] = q
		end
	end
	return {minerais = m, prix = PrixMinerais.PRIX}
end

local function reponse(p: Donnees.Profil?, ok: boolean, message: string, gain: number?): Reponse
	return {ok = ok, message = message, etat = p and etat(p), gain = gain}
end

local function compteur(joueur: Player): IntValue?
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild(CONFIG.MONNAIE)
	return if v and v:IsA("IntValue") then v else nil
end

local function procheDeGaspard(joueur: Player): boolean
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (racine and racine:IsA("BasePart") and pointGaspard) then
		return false
	end
	return (racine.Position - pointGaspard.Position).Magnitude <= CONFIG.DISTANCE_VENTE
end

local function nomMinerai(id: string): string
	local def = Forge.MINERAIS[id]
	return if def then def.nom else id
end

-- Retire n minerais puis crédite (aucune attente entre les deux). Renvoie le gain, ou nil si refusé.
local function encaisser(joueur: Player, p: Donnees.Profil, pieces: IntValue, id: string, n: number): number?
	local prix = PrixMinerais.get(id)
	if not prix or n < 1 or (p.minerais[id] or 0) < n then
		return nil
	end
	if not Donnees.ajouterMinerai(joueur, id, -n) then
		return nil
	end
	-- Bonus de rang de la Guilde des Mineurs (attribut posé par Quetes.server.lua, en %), arrondi à l'inférieur
	local bonus = math.clamp(tonumber(joueur:GetAttribute("BonusGuilde")) or 0, 0, 100)
	local gain = math.floor(prix * n * (1 + bonus / 100))
	pieces.Value += gain
	return gain
end

-- anti-spam → profil → forme → distance → stock → retrait → crédit
action.OnServerInvoke = function(joueur: Player, demande: any): Reponse
	local p = Donnees.profil(joueur)
	if not p or not joueur:GetAttribute("DonneesChargees") then
		return reponse(nil, false, "Patiente un instant…")
	end
	local maintenant = os.clock()
	if maintenant - (derniere[joueur] or 0) < CONFIG.ANTI_SPAM then
		return reponse(p, false, "Doucement !")
	end
	derniere[joueur] = maintenant

	if type(demande) ~= "table" or type(demande.action) ~= "string" then
		return reponse(p, false, "Requête invalide")
	end
	if not procheDeGaspard(joueur) then
		return reponse(p, false, "Approche-toi du comptoir de Gaspard")
	end
	local pieces = compteur(joueur)
	if not pieces then
		return reponse(p, false, "Patiente un instant…")
	end

	if demande.action == "vendre" then
		local id, q = demande.id, demande.quantite
		if type(id) ~= "string" or not PrixMinerais.get(id) then
			return reponse(p, false, "Minerai inconnu")
		end
		if type(q) ~= "number" or q ~= q or q ~= math.floor(q) or q < 1 or q > 1e9 then
			return reponse(p, false, "Quantité invalide")
		end
		local stock = p.minerais[id] or 0
		if stock < 1 then
			return reponse(p, false, "Tu n'as plus de " .. nomMinerai(id))
		end
		if q > stock then
			return reponse(p, false, "Tu n'en as que " .. stock)
		end
		local gain = encaisser(joueur, p, pieces, id, q)
		if not gain then
			return reponse(p, false, "Vente impossible")
		end
		print(string.format("[Marchand] %s vend %d %s (+%d %s)", joueur.Name, q, id, gain, CONFIG.MONNAIE))
		return reponse(p, true, string.format("%d %s vendu%s : +%d pièces", q, nomMinerai(id), if q > 1 then "s" else "", gain), gain)
	elseif demande.action == "toutVendre" then
		local total, nombre = 0, 0
		for _, id in Forge.ORDRE_MINERAIS do
			local q = p.minerais[id] or 0
			if q > 0 then
				local gain = encaisser(joueur, p, pieces, id, q)
				if gain then
					total += gain
					nombre += q
				end
			end
		end
		if nombre == 0 then
			return reponse(p, false, "Rien à vendre, va miner !")
		end
		print(string.format("[Marchand] %s vend tout : %d minerais (+%d %s)", joueur.Name, nombre, total, CONFIG.MONNAIE))
		return reponse(p, true, string.format("%d minerais vendus : +%d pièces", nombre, total), total)
	end
	return reponse(p, false, "Requête invalide")
end

Players.PlayerRemoving:Connect(function(joueur)
	derniere[joueur] = nil
end)

-- ===== Gaspard : « Vendre mes minerais » =====
local function trouverGaspard(): Instance?
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == CONFIG.SERVICE then
			return d
		end
	end
	return nil
end

-- Point d'interaction à hauteur de poitrine, indépendant de la façon dont le PNJ est construit
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
	local p = Instance.new("Part")
	p.Name = "InteractionMarchand"
	p.Size = Vector3.one
	p.CFrame = CFrame.new(centre.X, bas + 3, centre.Z)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Parent = workspace
	return p
end

task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do
		task.wait(0.25)
	end
	-- le PNJ peut arriver un peu après la carte : on le cherche 30 s
	local gaspard = trouverGaspard()
	local attente = os.clock()
	while not gaspard and os.clock() - attente < 30 do
		task.wait(1)
		gaspard = trouverGaspard()
	end
	local part = gaspard and pointInteraction(gaspard)
	if not part then
		warn("[Marchand] Gaspard introuvable (attribut Service = \"Vente\") : pas de comptoir.")
		return
	end
	pointGaspard = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptMarchand"
	prompt.ActionText = "Vendre mes minerais"
	prompt.ObjectText = "Gaspard · Marchand de minerais"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.DISTANCE_PROMPT
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -115)
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("Theme", "Boutique") -- dessinée par Boutique.client.lua, comme celles de Liesel et Brom
	prompt.Parent = part
	prompt.Triggered:Connect(function(joueur)
		local p = Donnees.profil(joueur)
		if p and joueur:GetAttribute("DonneesChargees") then
			ouvrir:FireClient(joueur, etat(p), part.Position)
		end
	end)
	print(string.format("[Marchand] Gaspard achète les minerais (interaction en %s)", tostring(part.Position)))
end)
