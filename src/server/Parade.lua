--!strict
-- Parade à l'épée · MODULE SERVEUR (ServerScriptService › Jeu › Parade)
-- Le client (EpeeAnimation.client) envoie ParadeEpee:FireServer(true / false) au clic droit / L2 / bouton tactile.
-- Serveur autoritaire : épée réellement en main, vivant, recharge après chaque garde, durée max de garde.
-- Attribut répliqué « EpeeParade » sur le personnage pendant la garde (les autres clients voient la pose).
-- Points de dégâts (MobsGrotte.frapper, BossVillage.blesserZone parable) :
--	local reduction, parfaite = Parade.bloque(joueur, positionSource, typeCoup)
--	typeCoup = "melee" | "projectile" : parables ; tout autre type (feu, lave, zone, chute…) → 0.
--	reduction = 0 (pas paré) … 1 ; parfaite = garde levée moins de FENETRE_PARFAITE s avant l'impact.
-- Serveur → clients : ParadeEpee:FireAllClients(perso, parfaite) (étincelles, clang, recul).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Parade = {
	REDUCTION = 0.85, -- part des dégâts parés
	FENETRE_PARFAITE = 0.25, -- s : garde levée juste avant l'impact → 100 % + étourdissement du mob
	DUREE_MAX = 4, -- s de garde continue (le client relâche à 3,8 s)
	RECHARGE = 0.3, -- s après une garde avant d'en relever une (le client attend 0,45 s : marge réseau)
	COS_CONE = 0.5, -- cône frontal de 120°
}

local PARABLES = {melee = true, projectile = true}

local remote = Instance.new("RemoteEvent")
remote.Name = "ParadeEpee"
remote.Parent = ReplicatedStorage

type Garde = {debut: number, perso: Model, outil: Tool, cx: RBXScriptConnection?}
local gardes: {[Player]: Garde} = {}
local fins: {[Player]: number} = {}

local function epeeEnMain(perso: Model): Tool?
	local outil = perso:FindFirstChildOfClass("Tool")
	return if outil and outil:GetAttribute("Epee") then outil else nil
end

function Parade.finir(joueur: Player)
	local g = gardes[joueur]
	if g then
		gardes[joueur] = nil
		fins[joueur] = os.clock()
		if g.cx then
			g.cx:Disconnect()
		end
		if g.perso.Parent then
			g.perso:SetAttribute("EpeeParade", nil)
		end
	end
end

local function commencer(joueur: Player)
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not hum or hum.Health <= 0 or gardes[joueur] then
		return
	end
	local outil = epeeEnMain(perso)
	local t = os.clock()
	if not outil or t - (fins[joueur] or -math.huge) < Parade.RECHARGE then
		return
	end
	local g: Garde = {debut = t, perso = perso, outil = outil, cx = nil}
	gardes[joueur] = g
	g.cx = outil.Unequipped:Once(function()
		Parade.finir(joueur)
	end)
	perso:SetAttribute("EpeeParade", true)
	task.delay(Parade.DUREE_MAX, function()
		if gardes[joueur] == g then
			Parade.finir(joueur)
		end
	end)
end

remote.OnServerEvent:Connect(function(joueur: Player, actif: any)
	if actif == true then
		commencer(joueur)
	elseif actif == false then
		Parade.finir(joueur)
	end
end)

function Parade.enGarde(joueur: Player): boolean
	return gardes[joueur] ~= nil
end

function Parade.bloque(joueur: Player, source: Vector3, typeCoup: string): (number, boolean)
	local g = gardes[joueur]
	if not g or not PARABLES[typeCoup] then
		return 0, false
	end
	local t = os.clock()
	local perso = g.perso
	local hrp = perso:FindFirstChild("HumanoidRootPart")
	if joueur.Character ~= perso or t - g.debut > Parade.DUREE_MAX or g.outil.Parent ~= perso
		or not (hrp and hrp:IsA("BasePart")) then
		Parade.finir(joueur)
		return 0, false
	end
	local vers = source - hrp.Position
	vers = Vector3.new(vers.X, 0, vers.Z)
	if vers.Magnitude > 0.5 then
		local devant = hrp.CFrame.LookVector
		devant = Vector3.new(devant.X, 0, devant.Z)
		if devant.Magnitude < 0.01 or devant.Unit:Dot(vers.Unit) < Parade.COS_CONE then
			return 0, false
		end
	end
	local parfaite = t - g.debut <= Parade.FENETRE_PARFAITE
	remote:FireAllClients(perso, parfaite)
	return if parfaite then 1 else Parade.REDUCTION, parfaite
end

Players.PlayerRemoving:Connect(function(joueur)
	Parade.finir(joueur)
	fins[joueur] = nil
end)

return Parade
