-- Remonter en haut de sa mine privée · SCRIPT SERVEUR.
-- Dès qu'un joueur est descendu sous le sol de la galerie dans SA mine privée, l'attribut joueur « ProfondeurMine »
-- (mètres sous la galerie) fait apparaître le bouton « Remonter » (RemonterMine.client). Le bouton demande la
-- remontée ; le serveur vérifie (sa mine, bien sous la galerie, vivant, 2 s entre deux demandes) puis le replace au
-- point d'apparition de la mine, en haut, face au massif.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MinePrivee = require(ServerStorage:WaitForChild("Monde"):WaitForChild("MinePrivee"))

-- Repères de la mine (repère local de mine.base, voir MinePrivee.lua : galerie au sol y = 0, massif de z = -20
-- à -220, fond à y = -160, largeur 20)
local SEUIL = 3 -- studs sous le sol de la galerie à partir desquels on a « commencé à descendre »
local DEMI_LARGEUR = 14
local Z_MIN, Z_MAX = -230, 10
local Y_MIN = -175
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

-- Profondeur (studs sous la galerie) du joueur dans sa propre mine, ou nil s'il n'y est pas descendu
local function profondeur(joueur: Player): number?
	local mine = MinePrivee.trouver(joueur)
	if not mine or not mine.modele or not mine.modele.Parent then return nil end
	local _, racine = vivant(joueur)
	if not racine then return nil end
	local rel = mine.base:PointToObjectSpace(racine.Position)
	if math.abs(rel.X) > DEMI_LARGEUR or rel.Z < Z_MIN or rel.Z > Z_MAX or rel.Y < Y_MIN then return nil end
	local bas = -(rel.Y - 3) -- le centre du corps est ~3 studs au-dessus des pieds
	return if bas > SEUIL then bas else nil
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

-- Attribut « ProfondeurMine » (en mètres entiers, 1 m = 1 stud) tenu à jour pour le bouton
while true do
	for _, joueur in Players:GetPlayers() do
		local p = profondeur(joueur)
		local valeur = if p then math.floor(p + 0.5) else nil
		if joueur:GetAttribute("ProfondeurMine") ~= valeur then
			joueur:SetAttribute("ProfondeurMine", valeur)
		end
	end
	task.wait(0.3)
end
