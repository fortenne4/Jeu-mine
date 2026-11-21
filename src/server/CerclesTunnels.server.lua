-- Cercles lumineux devant les tunnels privés : un joueur à la fois (« 0/1 » → « 1/1 »), puis
-- téléportation dans SA mine privée. Le cercle « Sortie » de la mine le ramène devant son tunnel.
-- Détection serveur par boucle légère (distance horizontale), anti-spam, morts ignorés.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local monde = ServerStorage:WaitForChild("Monde")
local D = require(monde:WaitForChild("Disposition"))
local Cercle = require(monde:WaitForChild("CercleLumineux"))
local MinePrivee = require(monde:WaitForChild("MinePrivee"))

local PAS = 0.1          -- période de la boucle de détection
local ACTIVATION = 0.35  -- effet visible avant la téléportation
local FLUX_LIMITE = 3    -- attente max du streaming ; au-delà, le voyage est annulé (pas de téléportation dans le vide)
local RECHARGE = 2.5     -- délai entre deux téléportations d'un même joueur
local RAYON2 = Cercle.RAYON * Cercle.RAYON

local cercles = {}  -- [modèle] = {centre, numero, occupant}
local enCours = {}  -- [joueur] = true pendant une téléportation
local derniers = {} -- [joueur] = os.clock() de la dernière téléportation
local tunnelDe = {} -- [joueur] = numéro du tunnel emprunté (pour le retour)

local function vivant(joueur)
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if humain and humain.Health > 0 and racine and racine:IsA("BasePart") then return perso, racine, humain end
	return nil
end

local function dedans(centre: Vector3, p: Vector3)
	local d = p - centre
	return d.Y > -1 and d.Y < 8 and d.X * d.X + d.Z * d.Z < RAYON2
end

-- Point de retour : devant le cercle du tunnel, face au centre de la caverne
local function arriveeCaverne(numero)
	local pos = D.PORTES[numero] or D.PORTES[1]
	local centre = Vector3.new(D.CAVERNE_CENTRE.X, pos.Y, D.CAVERNE_CENTRE.Z)
	return CFrame.lookAt(pos, centre) * CFrame.new(0, 0, -D.RETOUR_AVANCE)
end

-- Active un cercle, charge la zone d'arrivée, puis téléporte si le joueur est resté dedans.
local function voyager(joueur, modele, centre, cible: CFrame)
	Cercle.etat(modele, true)
	Cercle.activer(modele)
	local debut = os.clock()
	local fluxFini, fluxPret = false, false
	task.spawn(function()
		fluxPret = pcall(joueur.RequestStreamAroundAsync, joueur, cible.Position, FLUX_LIMITE)
		fluxFini = true
	end)
	task.wait(ACTIVATION)
	local perso, racine, humain = vivant(joueur)
	if not perso or not dedans(centre, racine.Position) then return false end
	while not fluxFini and os.clock() - debut < FLUX_LIMITE and joueur.Parent do task.wait(0.05) end
	if not fluxPret then return false end
	perso, racine, humain = vivant(joueur)
	if not perso then return false end
	if humain.Sit then humain.Sit = false end
	local hauteur = if humain.RigType == Enum.HumanoidRigType.R6 then 3 else humain.HipHeight + racine.Size.Y / 2
	perso:PivotTo(cible + Vector3.new(0, hauteur + 0.1, 0))
	racine.AssemblyLinearVelocity = Vector3.zero
	return true
end

local function entrerTunnel(joueur, modele, c)
	enCours[joueur] = true
	c.occupant = joueur
	local ok, erreur = pcall(function()
		local mine = MinePrivee.obtenir(joueur)
		if voyager(joueur, modele, c.centre, mine.apparition) and joueur.Parent then tunnelDe[joueur] = c.numero end
	end)
	if not ok then warn("[Cercles] Entrée interrompue : " .. tostring(erreur)) end
	if joueur.Parent then derniers[joueur] = os.clock() end
	task.wait(0.4)
	enCours[joueur] = nil
	c.occupant = nil
	if modele.Parent then Cercle.etat(modele, false) end
end

local function sortirMine(joueur, mine)
	enCours[joueur] = true
	local ok, resultat = pcall(voyager, joueur, mine.retour, mine.centreRetour, arriveeCaverne(tunnelDe[joueur] or 1))
	if not ok then warn("[Cercles] Sortie interrompue : " .. tostring(resultat)) end
	-- Sortie réussie : la mine est détruite (moins de pièces répliquées), reconstruite au prochain passage
	if ok and resultat == true then MinePrivee.liberer(joueur) end
	if joueur.Parent then derniers[joueur] = os.clock() end
	task.wait(0.4)
	enCours[joueur] = nil
	if mine.retour.Parent then Cercle.etat(mine.retour, false) end
end

local function ajouter(modele)
	local centre = modele:GetAttribute("Centre")
	if not modele:IsA("Model") or typeof(centre) ~= "Vector3" then return end
	cercles[modele] = {centre = centre, numero = modele:GetAttribute("Numero") or 1}
	modele.Destroying:Once(function() cercles[modele] = nil end)
end

Players.PlayerRemoving:Connect(function(joueur)
	enCours[joueur], derniers[joueur], tunnelDe[joueur] = nil, nil, nil
	for _, c in cercles do
		if c.occupant == joueur then c.occupant = nil end
	end
	MinePrivee.liberer(joueur)
end)

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
CollectionService:GetInstanceAddedSignal("CercleTunnel"):Connect(ajouter)
CollectionService:GetInstanceRemovedSignal("CercleTunnel"):Connect(function(modele) cercles[modele] = nil end)
for _, modele in CollectionService:GetTagged("CercleTunnel") do ajouter(modele) end

local PRES_CAVERNE = D.CAVERNE_RAYON + 20
local function examiner(joueur, maintenant)
	if enCours[joueur] or maintenant - (derniers[joueur] or -math.huge) < RECHARGE then return end
	local _, racine = vivant(joueur)
	if not racine then return end
	local p = racine.Position
	local mine = MinePrivee.trouver(joueur)
	if mine and mine.retour.Parent and dedans(mine.centreRetour, p) then
		task.spawn(sortirMine, joueur, mine)
	elseif (p - D.CAVERNE_CENTRE).Magnitude < PRES_CAVERNE then
		for modele, c in cercles do
			if not c.occupant and dedans(c.centre, p) then
				task.spawn(entrerTunnel, joueur, modele, c)
				return
			end
		end
	end
end

while true do
	local maintenant = os.clock()
	for _, joueur in Players:GetPlayers() do
		local ok, erreur = pcall(examiner, joueur, maintenant)
		if not ok then warn("[Cercles] Détection interrompue pour " .. joueur.Name .. " : " .. tostring(erreur)) end
	end
	task.wait(PAS)
end
