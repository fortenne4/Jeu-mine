--!strict
-- Épée · SCRIPT CLIENT : dégainage à l'équipement (coup 0) et combo de 3 coups (droite→gauche, gauche→droite, vertical).
-- Attribut local « EpeeGeste » sur le personnage pendant un geste : PiocheDosAnimation n'écrit alors plus le bras.
-- Chaque client anime tous les personnages (C0 décalé de pose * Transform⁻¹, comme PiocheDosAnimation) :
-- le coup du joueur local est joué tout de suite puis relayé par le serveur (RemoteEvent CoupEpee).
-- IK 2 segments (épaule + coude), poignet orienté pour diriger la lame, taille tournée.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("CoupEpee") :: RemoteEvent
local joueur = Players.LocalPlayer
local IK = require(script.Parent:WaitForChild("RigIK"))

local RESET = 1

type Coup = {
	duree: number, t: {number}, e: {(number) -> number}, frappe: Vector2, enchainer: number, cache: number,
	son: string, p: {Vector3}, d: {Vector3}, c: {Vector3}, yaw: {number}, pitch: {number}, n: {Vector3},
}

type Bras = IK.Bras
local lisse, sortie, entree = IK.lisse, IK.sortie, IK.entree
local T_COUP, E_COUP, F_COUP = {0, 0.2, 0.47, 0.68, 1}, {sortie, entree, sortie, lisse}, Vector2.new(0.2, 0.72)

local V = Vector3.new
local GARDE_P, GARDE_D, GARDE_C = V(-0.1, -0.45, -0.6), V(-0.1, 0.55, -0.85), V(0.3, -0.6, 0.6)
local HAUT, DROITE = V(0, 1, 0), V(1, 0, 0)

-- Repère du torse (+X droite, +Y haut, -Z devant) ; positions relatives à l'épaule en longueurs de bras.
-- Coups 1-3, clés : départ (pose actuelle), anticipation, frappe, suivi, garde.
-- Coup 0 = dégainage : hanche gauche, sortie du fourreau, brandi, pause, garde.
local COUPS: {[number]: Coup} = {
	[0] = {
		duree = 0.85, t = {0, 0.3, 0.48, 0.62, 0.8, 1}, e = {sortie, entree, sortie, lisse, lisse},
		frappe = Vector2.new(0.32, 0.8), enchainer = 0.8, cache = 0.3, son = "SonDegainer",
		p = {Vector3.zero, V(-0.6, -0.65, -0.3), V(-0.25, 0.1, -0.75), V(-0.1, 0.85, -0.45), V(-0.1, 0.9, -0.45), GARDE_P},
		d = {Vector3.zero, V(-0.1, -0.45, 0.9), V(-0.6, 0.1, -0.8), V(0, 0.95, -0.3), V(0, 0.95, -0.3), GARDE_D},
		c = {GARDE_C, V(0.8, -0.2, 0.5), V(0.6, -0.6, 0.3), V(0.8, 0.3, 0.3), V(0.8, 0.3, 0.3), GARDE_C},
		yaw = {0, 0.35, 0.15, -0.05, -0.05, 0},
		pitch = {0, -0.1, 0, 0.08, 0.08, 0},
		n = {Vector3.zero, DROITE, DROITE, DROITE, DROITE, DROITE},
	},
	{
		duree = 0.38, t = T_COUP, e = E_COUP, frappe = F_COUP, enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(0.45, 0.05, 0.05), V(-0.25, -0.05, -0.85), V(-0.85, -0.1, -0.35), GARDE_P},
		d = {Vector3.zero, V(0.8, 0.25, 0.55), V(0.1, 0.05, -1), V(-0.9, -0.05, -0.2), GARDE_D},
		c = {GARDE_C, V(0.8, -0.3, 0.4), V(0.2, -0.9, 0.1), V(0, -0.7, 0.6), GARDE_C},
		yaw = {0, -0.45, 0.05, 0.5, 0},
		pitch = {0, 0, -0.05, -0.08, 0},
		n = {Vector3.zero, HAUT, HAUT, HAUT, DROITE},
	},
	{
		duree = 0.38, t = T_COUP, e = E_COUP, frappe = F_COUP, enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(-0.85, 0.1, -0.3), V(-0.1, -0.05, -0.85), V(0.55, -0.05, -0.15), GARDE_P},
		d = {Vector3.zero, V(-0.85, 0.3, 0.4), V(0.05, 0.05, -1), V(0.9, 0, 0.3), GARDE_D},
		c = {GARDE_C, V(0.2, -0.9, 0.3), V(0.3, -0.9, 0.2), V(0.8, -0.5, 0.2), GARDE_C},
		yaw = {0, 0.5, 0, -0.45, 0},
		pitch = {0, 0, -0.05, -0.05, 0},
		n = {Vector3.zero, HAUT, HAUT, HAUT, DROITE},
	},
	{
		duree = 0.45, t = T_COUP, e = E_COUP, frappe = F_COUP, enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(-0.2, 0.85, 0.1), V(-0.35, 0.2, -0.85), V(-0.35, -0.6, -0.55), GARDE_P},
		d = {Vector3.zero, V(0, 0.3, 0.95), V(0, 0.1, -1), V(0, -0.8, -0.6), GARDE_D},
		c = {GARDE_C, V(0.7, 0.7, 0), V(0.9, -0.2, 0.2), V(0.5, -0.8, 0.2), GARDE_C},
		yaw = {0, -0.15, 0.1, 0.2, 0},
		pitch = {0, 0.18, -0.1, -0.3, 0},
		n = {Vector3.zero, DROITE, DROITE, DROITE, DROITE},
	},
}

-- ================= État des personnages =================

type Etat = {
	perso: Model, bras: Bras?, coup: Coup?, t: number,
	poids: number, poidsDepart: number, yaw: number, pitch: number, yaw0: number, pitch0: number,
	p0: Vector3, d0: Vector3, n0: Vector3, trail: Trail?, trailOn: boolean, grip: CFrame,
	pieces: {BasePart}, cache: boolean, son: Sound?,
}

local etats: {[Model]: Etat} = {}

local function etatDe(perso: Model): Etat
	local e = etats[perso]
	if not e then
		e = {
			perso = perso, bras = nil, coup = nil, t = 0, poids = 0, poidsDepart = 0,
			yaw = 0, pitch = 0, yaw0 = 0, pitch0 = 0, p0 = Vector3.zero, d0 = Vector3.zero, n0 = DROITE,
			trail = nil, trailOn = false, grip = CFrame.identity, pieces = {}, cache = false, son = nil,
		}
		etats[perso] = e
		perso.Destroying:Once(function()
			etats[perso] = nil
		end)
	end
	return e :: Etat
end

local function trainee(e: Etat, on: boolean)
	if e.trailOn ~= on then
		e.trailOn = on
		local tr = e.trail
		if tr and tr.Parent then
			tr.Enabled = on
		end
	end
end

-- Épée cachée tant que la main ne l'a pas saisie au fourreau (dégainage)
local function cacher(e: Etat, on: boolean)
	if e.cache ~= on then
		e.cache = on
		local ltm = if on then 1 else 0
		for _, p in e.pieces do
			p.LocalTransparencyModifier = ltm
		end
	end
end

local function finir(e: Etat)
	trainee(e, false)
	cacher(e, false)
	e.coup = nil
	e.poids, e.yaw, e.pitch = 0, 0, 0
	e.perso:SetAttribute("EpeeGeste", nil)
	IK.relacherBras(e.bras)
end

local function demarrer(e: Etat, i: number)
	if not IK.brasValide(e.bras) then
		e.bras = IK.preparerBras(e.perso, "Right")
	end
	local outil = e.perso:FindFirstChildOfClass("Tool")
	local c = COUPS[i]
	if not outil or not outil:GetAttribute("Epee") or not c then
		return
	end
	trainee(e, false)
	cacher(e, false)
	local tr = outil:FindFirstChild("TraineeEpee", true)
	e.trail = if tr and tr:IsA("Trail") then tr else nil
	e.grip = (outil :: Tool).Grip.Rotation
	local b = e.bras
	if b then
		if e.poids == 0 then
			IK.relacherBras(b)
		end
		local prise = b.main.CFrame * IK.priseMain(b.main, b.att)
		e.p0 = b.torse.CFrame:PointToObjectSpace(prise.Position)
		local handle = prise * e.grip:Inverse()
		e.d0 = b.torse.CFrame:VectorToObjectSpace(handle.UpVector)
		e.n0 = b.torse.CFrame:VectorToObjectSpace(handle.ZVector)
	end
	table.clear(e.pieces)
	if c.cache > 0 then
		for _, p in outil:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(e.pieces, p)
			end
		end
		cacher(e, true)
	end
	e.coup = c
	e.t = 0
	e.poidsDepart, e.yaw0, e.pitch0 = e.poids, e.yaw, e.pitch
	e.perso:SetAttribute("EpeeGeste", true)
	local son = outil:FindFirstChild(c.son, true)
	e.son = if son and son:IsA("Sound") then son else nil
	if c.cache == 0 and e.son then
		e.son.PlaybackSpeed = 0.9 + math.random() * 0.25
		e.son:Play()
	end
end

-- ================= Combo du joueur local =================

local combo, finPrevue, tampon = 0, -math.huge, false

local function lancerLocal(e: Etat)
	tampon = false
	local t = os.clock()
	combo = if t - finPrevue > RESET then 1 else combo % 3 + 1
	demarrer(e, combo)
	if e.coup then
		finPrevue = t + (e.coup :: Coup).duree
		remote:FireServer(combo)
	end
end

local function degainer()
	local perso = joueur.Character
	if perso then
		local e = etatDe(perso)
		tampon = false
		finPrevue = -math.huge
		demarrer(e, 0)
		if e.coup then
			remote:FireServer(0)
		end
	end
end

local function cliquer()
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not h or h.Health <= 0 then
		return
	end
	local e = etatDe(perso)
	local c = e.coup
	if c and e.t / c.duree < c.enchainer then
		tampon = true
		return
	end
	lancerLocal(e)
end

local branches: {[Tool]: boolean} = {}
local function brancher(o: Instance)
	if o:IsA("Tool") and o:GetAttribute("Epee") and not branches[o] then
		branches[o] = true
		o.Activated:Connect(cliquer)
		o.Equipped:Connect(degainer)
		o.Destroying:Once(function()
			branches[o] = nil
		end)
	end
end
local function suivreConteneur(c: Instance?)
	if c then
		c.ChildAdded:Connect(brancher)
		for _, o in c:GetChildren() do
			brancher(o)
		end
	end
end
joueur.CharacterAdded:Connect(function(perso)
	tampon = false
	suivreConteneur(perso)
end)
joueur.ChildAdded:Connect(function(o)
	if o:IsA("Backpack") then
		suivreConteneur(o)
	end
end)
suivreConteneur(joueur.Character)
suivreConteneur(joueur:FindFirstChildOfClass("Backpack"))

remote.OnClientEvent:Connect(function(perso: any, i: any)
	if typeof(perso) == "Instance" and perso:IsA("Model") and perso ~= joueur.Character and COUPS[i] then
		demarrer(etatDe(perso), i)
	end
end)

-- ================= Boucle =================

local function cle(liste: {Vector3}, depart: Vector3, i: number): Vector3
	return if i <= 1 then depart else liste[math.min(i, #liste)]
end

local function avancer(e: Etat, dt: number)
	local c = e.coup :: Coup
	local b = e.bras
	e.t += dt
	local u = e.t / c.duree
	if u >= 1 or not b or not IK.brasValide(b) then
		finir(e)
		return
	end
	if tampon and u >= c.enchainer and e.perso == joueur.Character then
		lancerLocal(e)
		return
	end
	if e.cache and u >= c.cache then
		cacher(e, false)
		if e.son then
			e.son:Play()
		end
	end
	trainee(e, u >= c.frappe.X and u <= c.frappe.Y)

	local T = c.t
	local n = #T - 1
	local k = n
	for s = 1, n do
		if u <= T[s + 1] then
			k = s
			break
		end
	end
	local v = c.e[k]((u - T[k]) / (T[k + 1] - T[k]))

	local w = e.poidsDepart + (1 - e.poidsDepart) * lisse(u / 0.12)
	if u > T[n] then
		w *= 1 - lisse((u - T[n]) / (1 - T[n]))
	end
	e.poids = w

	local S, L = b.epaule.c0Origine.Position, b.l1 + b.l2
	local p0 = (e.p0 - S) / L
	local q0, q1, q2, q3 = cle(c.p, p0, k - 1), cle(c.p, p0, k), cle(c.p, p0, k + 1), cle(c.p, p0, k + 2)
	local p = 0.5 * ((2 * q1) + (q2 - q0) * v + (2 * q0 - 5 * q1 + 4 * q2 - q3) * (v * v) + (3 * q1 - q0 - 3 * q2 + q3) * (v * v * v))
	q0, q1, q2, q3 = cle(c.d, e.d0, k - 1), cle(c.d, e.d0, k), cle(c.d, e.d0, k + 1), cle(c.d, e.d0, k + 2)
	local d = 0.5 * ((2 * q1) + (q2 - q0) * v + (2 * q0 - 5 * q1 + 4 * q2 - q3) * (v * v) + (3 * q1 - q0 - 3 * q2 + q3) * (v * v * v))
	if d.Magnitude < 1e-3 then
		d = q2
	end
	local pole = c.c[k]:Lerp(c.c[k + 1], v)
	local na, nb = cle(c.n, e.n0, k), c.n[k + 1]
	if na:Dot(nb) < 0 then
		na = -na
	end

	IK.poserBras(b, S + p * L, pole, d.Unit, na:Lerp(nb, v), e.grip, w)

	local ya = if k == 1 then e.yaw0 else c.yaw[k]
	local pa = if k == 1 then e.pitch0 else c.pitch[k]
	e.yaw = ya + (c.yaw[k + 1] - ya) * v
	e.pitch = pa + (c.pitch[k + 1] - pa) * v
	IK.poserTaille(b, e.pitch * w, e.yaw * w)
end

local derniere = os.clock()
RunService.PreSimulation:Connect(function()
	local t = os.clock()
	local dt = math.min(t - derniere, 0.1)
	derniere = t
	for _, e in etats do
		if e.coup then
			avancer(e, dt)
		end
	end
end)
