--!strict
-- Petit rebond sur les toits du village à la réception d'un saut.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local VITESSE_CHUTE_MIN = 31
local FACTEUR_HAUTEUR = math.sqrt(3)
local VITESSE_REBOND_MAX = 36 * FACTEUR_HAUTEUR
local DELAI_REBOND = 0.85

local joueur = Players.LocalPlayer
local persoSuivi: Model? = nil
local humanoide: Humanoid? = nil
local racine: BasePart? = nil
local reception: RBXScriptConnection? = nil
local vitesseChute = 0
local dernierRebond = -math.huge

local filtre = RaycastParams.new()
filtre.RespectCanCollide = true

local function suivre(perso: Model)
	persoSuivi = perso
	if reception then
		reception:Disconnect()
		reception = nil
	end
	humanoide = nil
	racine = nil
	vitesseChute = 0
	dernierRebond = -math.huge

	local h = perso:WaitForChild("Humanoid", 10)
	local r = perso:WaitForChild("HumanoidRootPart", 10)
	if persoSuivi ~= perso or joueur.Character ~= perso
		or not h or not h:IsA("Humanoid") or not r or not r:IsA("BasePart") then
		return
	end
	humanoide, racine = h, r
	filtre.FilterDescendantsInstances = {perso}

	reception = h.StateChanged:Connect(function(_, etat)
		if etat ~= Enum.HumanoidStateType.Landed or h.Health <= 0 then
			return
		end
		local impact = vitesseChute
		vitesseChute = 0
		local maintenant = os.clock()
		if impact < VITESSE_CHUTE_MIN or maintenant - dernierRebond < DELAI_REBOND then
			return
		end

		local distance = h.HipHeight + r.Size.Y / 2 + 1.5
		filtre.CollisionGroup = r.CollisionGroup
		local sol = workspace:Raycast(r.Position, Vector3.new(0, -distance, 0), filtre)
		if not sol or not sol.Instance:GetAttribute("ToitRebond") then
			return
		end

		dernierRebond = maintenant
		local vitesse = r.AssemblyLinearVelocity
		local rebond = math.min(impact * 0.72 * FACTEUR_HAUTEUR, VITESSE_REBOND_MAX)
		h:ChangeState(Enum.HumanoidStateType.Freefall)
		r.AssemblyLinearVelocity = Vector3.new(vitesse.X, rebond, vitesse.Z)
	end)
end

-- Après le contact, la physique a déjà freiné le personnage.
RunService.PreSimulation:Connect(function()
	local h, r = humanoide, racine
	if h and r and h:GetState() == Enum.HumanoidStateType.Freefall then
		vitesseChute = math.max(0, -r.AssemblyLinearVelocity.Y)
	else
		vitesseChute = 0
	end
end)

joueur.CharacterAdded:Connect(suivre)
if joueur.Character then
	suivre(joueur.Character)
end
