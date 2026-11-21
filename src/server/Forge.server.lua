--!strict
-- Forge de Brom · SCRIPT SERVEUR
-- Le joueur parle à Brom (ProximityPrompt « Forger ») → le serveur ouvre la forge chez lui.
-- Le client propose une recette ; le serveur la recalcule (Partage.Forge), vérifie le sac, débite et crée l'objet.
--
-- Remotes (ReplicatedStorage) :
--   ForgeOuvrir (RemoteEvent, serveur → client) : (etat, pointInteraction)
--   ForgeAction (RemoteFunction, client → serveur) : {action = "forger", type = string, composition = {{id, qte}}} → reponse
-- Tests (Studio, partie non sauvegardée seulement) : 50 de chaque minerai à l'arrivée, et
--   game.ServerStorage.ForgeAPI:Invoke("minerais", game.Players.TonNom, 50)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Forge = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Forge"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CONFIG = {
	SERVICE = "Forge", -- attribut « Service » du PNJ Brom (Village.lua)
	MONNAIE = "Pièces",
	DISTANCE_PROMPT = 12,
	DISTANCE_ACTION = 22,
	CADENCE = 0.4, -- secondes minimum entre deux requêtes
	TEST_STUDIO = 50, -- minerais de chaque sorte donnés à l'arrivée en Studio (0 = désactivé)
}

local ACCORD = {Epee = "e", Jambieres = "es"}

type Etat ={minerais: {[string]: number}, objets: {Donnees.Objet}}
type Reponse = {ok: boolean, message: string, etat: Etat?, objet: Donnees.Objet?}

local ouvrir = Instance.new("RemoteEvent")
ouvrir.Name = "ForgeOuvrir"
ouvrir.Parent = ReplicatedStorage

local action = Instance.new("RemoteFunction")
action.Name = "ForgeAction"
action.Parent = ReplicatedStorage

local derniere: {[Player]: number} = {}
local pointForge: BasePart? = nil

local function etat(p: Donnees.Profil): Etat
	return {minerais = p.minerais, objets = p.objets}
end

local function reponse(p: Donnees.Profil?, ok: boolean, message: string, objet: Donnees.Objet?): Reponse
	return {ok = ok, message = message, etat = p and etat(p), objet = objet}
end

local function compteur(joueur: Player): IntValue?
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild(CONFIG.MONNAIE)
	return if v and v:IsA("IntValue") then v else nil
end

local function procheDeBrom(joueur: Player): boolean
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (racine and racine:IsA("BasePart") and pointForge) then
		return false
	end
	return (racine.Position - pointForge.Position).Magnitude <= CONFIG.DISTANCE_ACTION
end

-- anti-spam → forme → distance → recette recalculée → possession → débit → création
action.OnServerInvoke = function(joueur: Player, demande: any): Reponse
	local p = Donnees.profil(joueur)
	if not p then
		return reponse(nil, false, "Patiente un instant…")
	end
	local maintenant = os.clock()
	if maintenant - (derniere[joueur] or 0) < CONFIG.CADENCE then
		return reponse(p, false, "Doucement !")
	end
	derniere[joueur] = maintenant

	if type(demande) ~= "table" or demande.action ~= "forger" then
		return reponse(p, false, "Requête invalide")
	end
	if not procheDeBrom(joueur) then
		return reponse(p, false, "Approche-toi de l'enclume de Brom")
	end
	local res, erreur = Forge.calculer(demande.type, demande.composition)
	if not res then
		return reponse(p, false, erreur or "Recette invalide")
	end
	for _, e in res.composition do
		if (p.minerais[e[1]] or 0) < e[2] then
			return reponse(p, false, "Pas assez de " .. Forge.MINERAIS[e[1]].mat)
		end
	end
	if #p.objets >= Donnees.MAX_OBJETS then
		return reponse(p, false, "Ton coffre d'équipement est plein")
	end
	local pieces = compteur(joueur)
	if not pieces or pieces.Value < res.prix then
		return reponse(p, false, "Pas assez de pièces")
	end

	pieces.Value -= res.prix
	for _, e in res.composition do
		Donnees.ajouterMinerai(joueur, e[1], -e[2])
	end
	local objet: Donnees.Objet = {id = tostring(p.prochainId), type = res.type, modele = res.modele, rang = res.rang, nom = res.nom, couleur = res.couleur:ToHex(),
		stat = res.stat, valeur = res.valeur, composition = res.composition}
	p.prochainId += 1
	table.insert(p.objets, objet)
	Donnees.notifier(joueur)
	local quete = ServerStorage:FindFirstChild("QueteEvenement") -- Guilde des Mineurs (Quetes.server.lua)
	if quete and quete:IsA("BindableEvent") then
		quete:Fire("forger", joueur, res.type)
	end
	print(string.format("[Forge] %s forge %s (%s %d, %d %s)", joueur.Name, res.nom, res.stat, res.valeur, res.prix, CONFIG.MONNAIE))
	return reponse(p, true, res.nom .. " forgé" .. (ACCORD[res.type] or "") .. " !", objet)
end

-- ===== Joueurs =====
local function surJoueur(joueur: Player)
	local p = Donnees.attendre(joueur)
	if p and joueur.Parent and RunService:IsStudio() and CONFIG.TEST_STUDIO > 0 and not Donnees.estSauvegarde(joueur) then
		for _, id in Forge.ORDRE_MINERAIS do
			Donnees.ajouterMinerai(joueur, id, CONFIG.TEST_STUDIO)
		end
		print(string.format("[Forge] Test Studio : %d de chaque minerai pour %s", CONFIG.TEST_STUDIO, joueur.Name))
	end
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end
Players.PlayerRemoving:Connect(function(joueur)
	derniere[joueur] = nil
end)

-- ===== Brom : « Forger » =====
local function trouverBrom(): Instance?
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == CONFIG.SERVICE then
			return d
		end
	end
	return nil
end

-- Point d'interaction à hauteur de poitrine, indépendant de la façon dont le PNJ est construit
local function pointInteraction(brom: Instance): BasePart?
	local centre: Vector3, bas: number
	if brom:IsA("Model") then
		local cf, taille = brom:GetBoundingBox()
		centre, bas = cf.Position, cf.Position.Y - taille.Y / 2
	else
		local racine = brom:FindFirstChildWhichIsA("BasePart", true) or (if brom:IsA("BasePart") then brom else nil)
		if not racine then
			return nil
		end
		centre, bas = racine.Position, racine.Position.Y - racine.Size.Y / 2
	end
	local p = Instance.new("Part")
	p.Name = "InteractionForge"
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
	local brom = trouverBrom()
	local attente = os.clock()
	while not brom and os.clock() - attente < 30 do
		task.wait(1)
		brom = trouverBrom()
	end
	local part = brom and pointInteraction(brom)
	if not part then
		warn("[Forge] Brom introuvable (attribut Service = \"Forge\") : pas de forge.")
		return
	end
	pointForge = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptForge"
	prompt.ActionText = "Forger"
	prompt.ObjectText = "Brom · Forgeron"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.DISTANCE_PROMPT
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -115)
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("Theme", "Boutique") -- dessinée par Boutique.client.lua, comme celle de Liesel
	prompt.Parent = part
	prompt.Triggered:Connect(function(joueur)
		local p = Donnees.profil(joueur)
		if p then
			ouvrir:FireClient(joueur, etat(p), part)
		end
	end)
end)

-- ===== Outils de test (Studio uniquement) =====
if RunService:IsStudio() then
	local api = Instance.new("BindableFunction")
	api.Name = "ForgeAPI"
	api.OnInvoke = function(commande: string, joueur: Player, valeur: any)
		if commande == "minerais" and not Donnees.estSauvegarde(joueur) then
			for _, id in Forge.ORDRE_MINERAIS do
				Donnees.ajouterMinerai(joueur, id, tonumber(valeur) or 50)
			end
		end
		local p = Donnees.profil(joueur)
		return p and etat(p)
	end
	api.Parent = ServerStorage
end
