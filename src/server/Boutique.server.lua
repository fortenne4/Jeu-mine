--!strict
-- Boutique de pioches de Liesel · SCRIPT SERVEUR
-- Le joueur parle à Liesel (ProximityPrompt) → le serveur ouvre la boutique chez lui.
-- Toute la logique (prix, possession, argent) reste ici : le client ne fait qu'afficher et demander.
--
-- Remotes (ReplicatedStorage) :
--   BoutiqueOuvrir  (RemoteEvent, serveur → client) : (etat, positionLiesel)
--   BoutiqueAction  (RemoteFunction, client → serveur) : {action = "acheter"|"equiper", id = string} → reponse
-- Pioche équipée : attribut « Pioche » du Player (lu par PiocheBraise.server.lua).
-- Tests (Studio seulement) : ServerStorage.BoutiqueAPI (BindableFunction), commandes « pieces » et « reset ».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CONFIG = {
	MONNAIE = "Pièces",
	SERVICE = "Outils", -- attribut « Service » du PNJ Liesel (Village.lua)
	DISTANCE_PROMPT = 12, -- studs : à cette distance, l'invite « Voir les pioches » apparaît
	DISTANCE_ACHAT = 22, -- au-delà, le serveur refuse les achats (le client ferme la boutique avant)
	ANTI_SPAM = 0.25, -- secondes minimum entre deux requêtes d'un joueur
}

type Etat = {possedees: {[string]: boolean}, equipee: string}
type Reponse = {ok: boolean, message: string, etat: Etat}

-- ===== Remotes =====
local ouvrir = Instance.new("RemoteEvent")
ouvrir.Name = "BoutiqueOuvrir"
ouvrir.Parent = ReplicatedStorage

local action = Instance.new("RemoteFunction")
action.Name = "BoutiqueAction"
action.Parent = ReplicatedStorage

-- ===== État par joueur : la table des pioches est celle du profil sauvegardé (Donnees) =====
local possedees: {[Player]: {[string]: boolean}} = {}
local derniereRequete: {[Player]: number} = {}
local pointLiesel: BasePart? = nil

local function etat(joueur: Player): Etat
	local copie = {}
	for id in possedees[joueur] or {} do
		copie[id] = true
	end
	return {possedees = copie, equipee = joueur:GetAttribute("Pioche") or Pioches.DEPART}
end

local function compteur(joueur: Player): IntValue?
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild(CONFIG.MONNAIE)
	return if v and v:IsA("IntValue") then v else nil
end

local function procheDeLiesel(joueur: Player): boolean
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (racine and racine:IsA("BasePart") and pointLiesel) then
		return false
	end
	return (racine.Position - pointLiesel.Position).Magnitude <= CONFIG.DISTANCE_ACHAT
end

local function equiper(joueur: Player, id: string)
	joueur:SetAttribute("Pioche", id) -- PiocheBraise remplace l'outil dans le sac
end

local function reponse(joueur: Player, ok: boolean, message: string): Reponse
	return {ok = ok, message = message, etat = etat(joueur)}
end

-- ===== Requêtes du client : anti-spam → types → existence → règles → modification =====
action.OnServerInvoke = function(joueur: Player, demande: any): Reponse
	local maintenant = os.clock()
	if maintenant - (derniereRequete[joueur] or 0) < CONFIG.ANTI_SPAM then
		return reponse(joueur, false, "Doucement !")
	end
	derniereRequete[joueur] = maintenant

	if type(demande) ~= "table" or type(demande.action) ~= "string" then
		return reponse(joueur, false, "Requête invalide")
	end
	local def = Pioches.get(demande.id)
	if not def then
		return reponse(joueur, false, "Pioche inconnue")
	end
	local sac = possedees[joueur]
	if not sac then
		return reponse(joueur, false, "Patiente un instant…")
	end

	if demande.action == "equiper" then
		if not sac[def.id] then
			return reponse(joueur, false, "Tu ne possèdes pas cette pioche")
		end
		equiper(joueur, def.id)
		return reponse(joueur, true, def.nom .. " équipée !")
	elseif demande.action == "acheter" then
		if not procheDeLiesel(joueur) then
			return reponse(joueur, false, "Approche-toi de Liesel")
		end
		if sac[def.id] then
			return reponse(joueur, false, "Tu l'as déjà")
		end
		local avant = Pioches.precedente(def.id)
		if avant and not sac[avant.id] then
			return reponse(joueur, false, "Achète d'abord la " .. avant.nom)
		end
		local pieces = compteur(joueur)
		if not pieces or pieces.Value < def.prix then
			return reponse(joueur, false, "Pas assez de pièces")
		end
		pieces.Value -= def.prix
		sac[def.id] = true
		equiper(joueur, def.id)
		print(string.format("[Boutique] %s achète %s (%d %s)", joueur.Name, def.id, def.prix, CONFIG.MONNAIE))
		local quete = ServerStorage:FindFirstChild("QueteEvenement") -- Guilde des Mineurs (Quetes.server.lua)
		if quete and quete:IsA("BindableEvent") then
			quete:Fire("pioche", joueur, def.id)
		end
		return reponse(joueur, true, def.nom .. " achetée !")
	end
	return reponse(joueur, false, "Requête invalide")
end

-- ===== Joueurs =====
local function surJoueur(joueur: Player)
	-- Donnees remet aussi l'attribut « Pioche » sur la pioche équipée lors de la dernière partie
	local profil = Donnees.attendre(joueur)
	if profil and joueur.Parent then
		possedees[joueur] = profil.pioches
	end
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end
Players.PlayerRemoving:Connect(function(joueur)
	possedees[joueur] = nil
	derniereRequete[joueur] = nil
end)

-- ===== Liesel : « Parler » =====
local function racineDuPNJ(m: Instance): BasePart?
	if m:IsA("Model") then
		if m.PrimaryPart then
			return m.PrimaryPart
		end
		local r = m:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			return r
		end
	end
	return m:FindFirstChildWhichIsA("BasePart", true)
end

local function trouverLiesel(): Instance?
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == CONFIG.SERVICE then
			return d
		end
	end
	return nil
end

-- Point d'interaction dédié, à hauteur de poitrine devant Liesel : il ne dépend pas de la façon
-- dont le PNJ est construit (modèle 3D, avatar ou blocs), dont la « racine » peut être n'importe où.
local function pointInteraction(liesel: Instance): BasePart?
	local centre: Vector3, bas: number
	if liesel:IsA("Model") then
		local cf, taille = liesel:GetBoundingBox()
		centre, bas = cf.Position, cf.Position.Y - taille.Y / 2
	else
		local racine = racineDuPNJ(liesel)
		if not racine then
			return nil
		end
		centre, bas = racine.Position, racine.Position.Y - racine.Size.Y / 2
	end
	local p = Instance.new("Part")
	p.Name = "InteractionLiesel"
	p.Size = Vector3.new(1, 1, 1)
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
	-- le PNJ peut arriver un peu après la carte (avatar chargé depuis Roblox) : on le cherche 30 s
	local liesel = trouverLiesel()
	local attente = os.clock()
	while not liesel and os.clock() - attente < 30 do
		task.wait(1)
		liesel = trouverLiesel()
	end
	local part = liesel and pointInteraction(liesel)
	if not part then
		warn("[Boutique] Liesel introuvable (attribut Service = \"Outils\") : pas de boutique.")
		return
	end
	pointLiesel = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptBoutique"
	prompt.ActionText = "Voir les pioches"
	prompt.ObjectText = "Liesel · Fabricante d'outils"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.DISTANCE_PROMPT
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -115)
	-- Style par défaut : l'invite Roblox s'affiche toujours. Boutique.client.lua la passe en style
	-- Custom chez lui (thème de la boutique) seulement une fois prêt à la dessiner.
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("Theme", "Boutique")
	prompt.Parent = part
	prompt.Triggered:Connect(function(joueur)
		if possedees[joueur] then
			ouvrir:FireClient(joueur, etat(joueur), part.Position)
		end
	end)
	print(string.format("[Boutique] Liesel est prête à vendre ses pioches (interaction en %s)", tostring(part.Position)))
end)

-- ===== Outils de test (Studio uniquement) =====
-- Barre de commande : game.ServerStorage.BoutiqueAPI:Invoke("pieces", game.Players.TonNom, 5000)
if RunService:IsStudio() then
	local api = Instance.new("BindableFunction")
	api.Name = "BoutiqueAPI"
	api.OnInvoke = function(commande: string, joueur: Player, valeur: any)
		if commande == "pieces" then
			local v = compteur(joueur)
			if v then
				v.Value += tonumber(valeur) or 0
			end
		elseif commande == "reset" then
			local sac = possedees[joueur]
			if sac then
				table.clear(sac) -- même table que le profil : la remise à zéro sera sauvegardée
				sac[Pioches.DEPART] = true
			end
			equiper(joueur, Pioches.DEPART)
		end
		return etat(joueur)
	end
	api.Parent = ServerStorage
end
