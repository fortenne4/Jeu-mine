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

local RESET = 1

type Coup = {
	duree: number, t: {number}, e: {(number) -> number}, frappe: Vector2, enchainer: number, cache: number,
	son: string, p: {Vector3}, d: {Vector3}, c: {Vector3}, yaw: {number}, pitch: {number}, n: {Vector3},
}

local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end
local function sortie(u: number): number
	u = 1 - u
	return 1 - u * u * u
end
local function entree(u: number): number
	return u * u * u
end
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

-- ================= Articulations (même méthode que PiocheDosAnimation) =================

type Joint = {moteur: Instance, cadre: Instance, c0Origine: CFrame, rotC0Inv: CFrame, c1Rot: CFrame}
type Bras = {
	epaule: Joint, coude: Joint, poignet: Joint?, taille: Joint?,
	torse: BasePart, main: BasePart, l1: number, l2: number,
	qHautInv: CFrame, qBasInv: CFrame, priseInv: CFrame,
}

local function lireC0(cadre: Instance): CFrame
	return if cadre:IsA("Motor6D") then cadre.C0 else (cadre :: Attachment).CFrame
end

local function ecrireC0(cadre: Instance, cf: CFrame)
	if cadre:IsA("Motor6D") then
		cadre.C0 = cf
	else
		(cadre :: Attachment).CFrame = cf
	end
end

local function lireC1(m: Instance): CFrame
	if m:IsA("Motor6D") then
		return m.C1
	end
	local att = (m :: AnimationConstraint).Attachment1
	return if att then att.CFrame else CFrame.identity
end

local function trouverJoint(perso: Model, nom: string): Joint?
	local choix: Instance? = nil
	for _, d in perso:GetDescendants() do
		if d.Name == nom and (d:IsA("Motor6D") or d:IsA("AnimationConstraint")) then
			local m = d :: any
			local ok = m.Enabled and (if d:IsA("Motor6D") then m.Part0 and m.Part1 else m.Attachment0 and m.Attachment1)
			if ok and (choix == nil or (m.Active and not (choix :: any).Active)) then
				choix = d
			end
		end
	end
	local d = choix
	if d then
		local m = d :: any
		local cadre = if d:IsA("Motor6D") then d else m.Attachment0
		local origine = cadre:GetAttribute("C0Origine")
		if typeof(origine) ~= "CFrame" then
			origine = lireC0(cadre)
			cadre:SetAttribute("C0Origine", origine)
		end
		local o = origine :: CFrame
		return {moteur = d, cadre = cadre, c0Origine = o, rotC0Inv = o.Rotation:Inverse(), c1Rot = lireC1(d).Rotation}
	end
	return nil
end

local function jointValide(j: Joint?): boolean
	if j == nil or j.moteur.Parent == nil or j.cadre.Parent == nil then
		return false
	end
	local m = j.moteur :: any
	if j.moteur:IsA("Motor6D") then
		return m.Part0 ~= nil and m.Part1 ~= nil
	end
	return m.Attachment0 == j.cadre and m.Attachment1 ~= nil
end

local function ecrire(j: Joint, cf: CFrame)
	ecrireC0(j.cadre, j.c0Origine * cf * (j.moteur :: any).Transform:Inverse())
end

local function poser(j: Joint?, pose: CFrame, w: number)
	if j and jointValide(j) then
		ecrire(j, (j.moteur :: any).Transform:Lerp(pose, w))
	end
end

local function relacher(j: Joint?)
	if j and jointValide(j) then
		ecrireC0(j.cadre, j.c0Origine)
	end
end

local function rotationDepuisBas(v: Vector3): CFrame
	local d = v.Unit
	local axe = V(0, -1, 0):Cross(d)
	if axe.Magnitude < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axe.Unit, math.acos(math.clamp(-d.Y, -1, 1)))
end

local function priseMain(main: BasePart): CFrame
	local att = main:FindFirstChild("RightGripAttachment")
	return if att and att:IsA("Attachment") then att.CFrame else CFrame.identity
end

local function preparerBras(perso: Model): Bras?
	local epaule = trouverJoint(perso, "RightShoulder")
	local coude = trouverJoint(perso, "RightElbow")
	local poignet = trouverJoint(perso, "RightWrist")
	local main = perso:FindFirstChild("RightHand")
	local torse = perso:FindFirstChild("UpperTorso")
	if not (epaule and coude and main and main:IsA("BasePart") and torse and torse:IsA("BasePart")) then
		return nil
	end
	local prise = priseMain(main)
	local u = coude.c0Origine.Position - lireC1(epaule.moteur).Position
	local mainAvantBras = if poignet then poignet.c0Origine * lireC1(poignet.moteur):Inverse() * prise else CFrame.new(0, -1, 0)
	local v = mainAvantBras.Position - lireC1(coude.moteur).Position
	return {
		epaule = epaule, coude = coude, poignet = poignet, taille = trouverJoint(perso, "Waist"),
		torse = torse, main = main, l1 = u.Magnitude, l2 = v.Magnitude,
		qHautInv = rotationDepuisBas(u):Inverse(), qBasInv = rotationDepuisBas(v):Inverse(),
		priseInv = prise.Rotation:Inverse(),
	}
end

local function brasValide(b: Bras?): boolean
	return b ~= nil and jointValide(b.epaule) and jointValide(b.coude)
		and (b.poignet == nil or jointValide(b.poignet)) and b.torse.Parent ~= nil and b.main.Parent ~= nil
end

-- Main sur `cible`, coude vers `pole`, lame (+Y du Handle) selon `dir`, plat (Z du Handle) normal à `n` :
-- le tranchant (X) reste dans le plan de balayage
local function poserBras(b: Bras, cible: Vector3, pole: Vector3, dir: Vector3, n: Vector3, grip: CFrame, w: number)
	local S = b.epaule.c0Origine.Position
	local l1, l2 = b.l1, b.l2
	local d = cible - S
	local mag = d.Magnitude
	local dist = math.clamp(mag, math.abs(l1 - l2) + 0.02, (l1 + l2) * 0.999)
	local axe = if mag > 1e-4 then d / mag else V(0, -1, 0)
	local a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
	local h = math.sqrt(math.max(0, l1 * l1 - a * a))
	local perp = pole - axe * pole:Dot(axe)
	if perp.Magnitude < 1e-3 then
		perp = V(0, 0, 1) - axe * axe.Z
	end
	perp = perp.Unit
	local E = S + axe * a + perp * h
	local H = S + axe * dist

	local yH = (S - E).Unit
	local f = (H - E).Unit
	local zf = f - yH * f:Dot(yH)
	local zH = if zf.Magnitude > 1e-3 then -zf.Unit else -perp
	local xH = yH:Cross(zH)
	local rotHaut = CFrame.fromMatrix(Vector3.zero, xH, yH, zH) * b.qHautInv
	local yB = (E - H).Unit
	local rotBas = CFrame.fromMatrix(Vector3.zero, xH, yB, xH:Cross(yB)) * b.qBasInv

	local ep, co = b.epaule, b.coude
	poser(ep, ep.rotC0Inv * rotHaut * ep.c1Rot, w)
	poser(co, co.rotC0Inv * rotHaut:Inverse() * rotBas * co.c1Rot, w)

	local po = b.poignet
	if po then
		local z = n - dir * n:Dot(dir)
		if z.Magnitude < 1e-3 then
			z = dir:Cross(V(1, 0, 0))
		end
		z = z.Unit
		local rotMain = CFrame.fromMatrix(Vector3.zero, dir:Cross(z), dir, z) * grip * b.priseInv
		poser(po, po.rotC0Inv * rotBas:Inverse() * rotMain * po.c1Rot, w)
	end
end

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
	local b = e.bras
	if b then
		relacher(b.epaule)
		relacher(b.coude)
		relacher(b.poignet)
		relacher(b.taille)
	end
end

local function demarrer(e: Etat, i: number)
	if not brasValide(e.bras) then
		e.bras = preparerBras(e.perso)
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
			relacher(b.epaule)
			relacher(b.coude)
			relacher(b.poignet)
			relacher(b.taille)
		end
		local prise = b.main.CFrame * priseMain(b.main)
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
	if u >= 1 or not b or not brasValide(b) then
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

	poserBras(b, S + p * L, pole, d.Unit, na:Lerp(nb, v), e.grip, w)

	local ya = if k == 1 then e.yaw0 else c.yaw[k]
	local pa = if k == 1 then e.pitch0 else c.pitch[k]
	e.yaw = ya + (c.yaw[k + 1] - ya) * v
	e.pitch = pa + (c.pitch[k + 1] - pa) * v
	local ta = b.taille
	if ta and jointValide(ta) then
		ecrire(ta, (ta.moteur :: any).Transform * (ta.rotC0Inv * CFrame.Angles(e.pitch * w, e.yaw * w, 0) * ta.c0Origine.Rotation))
	end
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
