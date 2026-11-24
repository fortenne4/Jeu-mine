-- Remonter en haut de sa mine privée · SCRIPT SERVEUR.
-- Dès qu'un joueur est descendu sous le sol de la galerie dans SA mine privée, l'attribut joueur « ProfondeurMine »
-- (mètres sous la galerie) fait apparaître le bouton « Remonter » (RemonterMine.client). Le bouton demande la
-- remontée ; le serveur vérifie (sa mine, bien sous la galerie, vivant, 2 s entre deux demandes) puis le replace au
-- point d'apparition de la mine, en haut, face au massif.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MinePrivee = require(ServerStorage:WaitForChild("Monde"):WaitForChild("MinePrivee"))

-- Repères de la mine (repère local de mine.base, voir MinePrivee.LIMITES : galerie au sol y = 0, massif de 80 de
-- large, 800 de long, fond à y = -676). Profondeur affichée en mètres : 1 bloc de 2 studs = 1 m (Partage › CouchesMine).
local CouchesMine = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CouchesMine"))
local SEUIL = 3 -- studs sous le sol de la galerie à partir desquels on a « commencé à descendre »
local DEMI_LARGEUR = MinePrivee.LIMITES.demiLargeur
local Z_MIN, Z_MAX = MinePrivee.LIMITES.zMin, MinePrivee.LIMITES.zMax
local Y_MIN = MinePrivee.LIMITES.yMin
local BLOC = MinePrivee.TAILLE_BLOC
local ATTENTE = 2 -- secondes entre deux remontées

local evenement = Instance.new("RemoteEvent")
evenement.Name = "RemonterMine"
evenement.Parent = ReplicatedStorage

local function vivant(joueur: Player)
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if humain and humain.Health > 0 and racine and racine:IsA("BasePart") then return perso, racine, humain end
	return nil
end

-- Profondeur (studs sous la galerie) du joueur dans sa propre mine (négative en haut, dans la galerie), ou nil
-- s'il n'est pas dans sa mine
local function position(joueur: Player): number?
	local mine = MinePrivee.trouver(joueur)
	if not mine or not mine.modele or not mine.modele.Parent then return nil end
	local _, racine = vivant(joueur)
	if not racine then return nil end
	local rel = mine.base:PointToObjectSpace(racine.Position)
	if math.abs(rel.X) > DEMI_LARGEUR or rel.Z < Z_MIN or rel.Z > Z_MAX or rel.Y < Y_MIN then return nil end
	return -(rel.Y - 3) -- le centre du corps est ~3 studs au-dessus des pieds
end

-- Profondeur (studs) seulement si le joueur est descendu sous la galerie
local function profondeur(joueur: Player): number?
	local bas = position(joueur)
	return if bas and bas > SEUIL then bas else nil
end

local derniere: {[Player]: number} = {}
evenement.OnServerEvent:Connect(function(joueur)
	local t = os.clock()
	if t - (derniere[joueur] or 0) < ATTENTE then return end
	derniere[joueur] = t
	if not profondeur(joueur) then return end
	local mine = MinePrivee.trouver(joueur)
	local perso, racine, humain = vivant(joueur)
	if not mine or not perso or not racine or not humain then return end
	if humain.Sit then humain.Sit = false end
	local hauteur = if humain.RigType == Enum.HumanoidRigType.R6 then 3 else humain.HipHeight + racine.Size.Y / 2
	perso:PivotTo(mine.apparition + Vector3.new(0, hauteur + 0.1, 0))
	racine.AssemblyLinearVelocity = Vector3.zero
	joueur:SetAttribute("ProfondeurMine", nil)
end)

Players.PlayerRemoving:Connect(function(joueur)
	derniere[joueur] = nil
end)

-- Attributs tenus à jour : « ProfondeurMine » (mètres entiers, 1 m = 1 bloc, seulement sous la galerie) pour le
-- bouton, et « CoucheMine » (index dans CouchesMine.LISTE, dès qu'on est dans sa mine) pour le bandeau des couches
while true do
	for _, joueur in Players:GetPlayers() do
		local bas = position(joueur)
		local valeur = if bas and bas > SEUIL then math.floor(bas / BLOC + 0.5) else nil
		if joueur:GetAttribute("ProfondeurMine") ~= valeur then
			joueur:SetAttribute("ProfondeurMine", valeur)
		end
		local couche = if bas then CouchesMine.index(bas / BLOC) else nil
		if joueur:GetAttribute("CoucheMine") ~= couche then
			joueur:SetAttribute("CoucheMine", couche)
		end
	end
	task.wait(0.3)
end
