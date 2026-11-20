--!strict
-- Petit rebond sur les toits du village à la réception d'un saut.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local VITESSE_CHUTE_MIN = 31
local FACTEUR_HAUTEUR = math.sqrt(3)
local VITESSE_REBOND_MAX = 36 * FACTEUR_HAUTEUR
local DELAI_REBOND = 0.85
local AVANCES_AUVENT = {0, 2.5, 5, 7.5, 10}
local MARGE_SAUT_AUVENT = 5.5
local VITESSE_REBOND_AUVENT_MIN = 42

local joueur = Players.LocalPlayer
local persoSuivi: Model? = nil
local humanoide: Humanoid? = nil
local racine: BasePart? = nil
local reception: RBXScriptConnection? = nil
local vitesseChute = 0
local vitesseSaut = 0
local sautEnCours = false
local dernierRebond = -math.huge

local filtre = RaycastParams.new()
filtre.RespectCanCollide = true

local function sautVersAuvent(h: Humanoid, r: BasePart): number
	local vers = h.MoveDirection
	if vers.Magnitude < 0.1 then
		vers = r.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	if vers.Magnitude < 0.1 then
		return 0
	end
	vers = vers.Unit

	local pieds = r.Position.Y - h.HipHeight - r.Size.Y / 2
	local dessous = Vector3.yAxis * 12
	local origine = r.Position + dessous
	local hauteur = 0
	filtre.CollisionGroup = r.CollisionGroup
	for _, avance in AVANCES_AUVENT do
		local surface = workspace:Raycast(origine + vers * avance, -dessous, filtre)
		if surface and surface.Instance.Name == "Auvent" and surface.Instance:GetAttribute("ToitRebond") then
			-- Sous la toile, il faut d'abord ressortir pour pouvoir sauter par-dessus.
			if avance == 0 then
				return 0
			end
			hauteur = math.max(hauteur, surface.Position.Y - pieds)
		end
	end
	if hauteur < 4 then
		return 0
	end
	return math.sqrt(2 * workspace.Gravity * (hauteur + MARGE_SAUT_AUVENT))
end

local function suivre(perso: Model)
	persoSuivi = perso
	if reception then
		reception:Disconnect()
		reception = nil
	end
	humanoide = nil
	racine = nil
	vitesseChute = 0
	vitesseSaut = 0
	sautEnCours = false
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
		if h.Health <= 0 then
			return
		end
		if etat == Enum.HumanoidStateType.Jumping then
			sautEnCours = true
			vitesseSaut = sautVersAuvent(h, r)
			return
		end
		if etat ~= Enum.HumanoidStateType.Landed then
			return
		end
		local impact, apresSaut = vitesseChute, sautEnCours
		vitesseChute = 0
		sautEnCours = false
		local maintenant = os.clock()
		if (impact < VITESSE_CHUTE_MIN and not apresSaut) or maintenant - dernierRebond < DELAI_REBOND then
			return
		end

		local distance = h.HipHeight + r.Size.Y / 2 + 1.5
		filtre.CollisionGroup = r.CollisionGroup
		-- Les pieds peuvent toucher le bord alors que le centre du personnage dépasse du toit.
		local emprise = Vector3.new(r.Size.X, 0.1, r.Size.Z)
		local sol = workspace:Blockcast(r.CFrame, emprise, Vector3.new(0, -distance, 0), filtre)
		if not sol or sol.Normal.Y <= 0 or not sol.Instance:GetAttribute("ToitRebond") then
			return
		end

		-- La réception sur la toile rebondit aussi quand le saut arrive près de son sommet.
		local sautSurAuvent = apresSaut and sol.Instance.Name == "Auvent"
		if impact < VITESSE_CHUTE_MIN and not sautSurAuvent then
			return
		end

		dernierRebond = maintenant
		local vitesse = r.AssemblyLinearVelocity
		local minimum = if sautSurAuvent then VITESSE_REBOND_AUVENT_MIN else 0
		local rebond = math.clamp(impact * 0.72 * FACTEUR_HAUTEUR, minimum, VITESSE_REBOND_MAX)
		h:ChangeState(Enum.HumanoidStateType.Freefall)
		r.AssemblyLinearVelocity = Vector3.new(vitesse.X, rebond, vitesse.Z)
	end)
end

RunService.PreSimulation:Connect(function()
	local h, r = humanoide, racine
	vitesseChute = 0
	if not h or not r then
		return
	end

	local etat = h:GetState()
	local vitesse = r.AssemblyLinearVelocity
	if etat == Enum.HumanoidStateType.Jumping then
		if vitesseSaut > 0 and vitesse.Y > 0 then
			r.AssemblyLinearVelocity = Vector3.new(vitesse.X, math.max(vitesse.Y, vitesseSaut), vitesse.Z)
			vitesseSaut = 0
		end
	else
		vitesseSaut = 0
	end

	-- Après le contact, la physique a déjà freiné le personnage.
	if etat == Enum.HumanoidStateType.Freefall then
		vitesseChute = math.max(0, -vitesse.Y)
	end
end)

joueur.CharacterAdded:Connect(suivre)
if joueur.Character then
	suivre(joueur.Character)
end
