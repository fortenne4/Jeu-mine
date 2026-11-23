--!strict
-- Coup de pioche · SCRIPT CLIENT : geste du corps entier (bras droit + main gauche sur le manche + taille).
-- Anticipation (pioche au-dessus/derrière l'épaule, torse cambré), frappe accélérée vers le minerai visé,
-- hit-stop + rebond à l'impact, retour en garde. Impact local à 0.20 s (le serveur frappe à 0.17 s + ping).
-- Deux gestes alternent (au-dessus de la tête / en diagonale, voir VARIANTES), mêmes temps pour les deux.
-- Joueur local : joué au clic (même cadence que le serveur) ; autres : relais serveur CoupPioche.
-- Attribut local « PiocheGeste » pendant le geste : PiocheDosAnimation n'écrit alors plus le bras.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local IK = require(script.Parent:WaitForChild("RigIK"))
local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
local remote = ReplicatedStorage:WaitForChild("CoupPioche") :: RemoteEvent
local joueur = Players.LocalPlayer

local lisse, sortie = IK.lisse, IK.sortie
-- Départ en douceur, arrivée franche : mélange des deux courbes (la sortie seule démarre d'un coup sec)
local function armer(u: number): number
	return 0.35 * sortie(u) + 0.65 * lisse(u)
end
local V = Vector3.new

local OCCUPE = 0.35 -- verrou serveur après un coup
local DUREE_MIN = 0.5
local T_HAUT, T_IMPACT, T_FIGE, T_REBOND = 0.13, 0.2, 0.25, 0.31
local SEP_MAINS = 0.85 -- main gauche plus bas sur le manche (studs)

-- Repère du torse (+X droite, +Y haut, -Z devant), main droite relative à l'épaule en longueurs de bras.
-- Manche : angle th depuis le haut vers l'arrière (0 = vertical, -pi/2 = devant, > 0 = derrière la tête).
local GARDE_P, GARDE_TH = V(-0.15, -0.5, -0.55), math.rad(-45)
local HAUT_P, HAUT_TH = V(0.1, 0.8, 0.3), math.rad(55)
local CTRL_MONTEE, CTRL_FRAPPE = V(0.25, 0.3, -0.5), V(0.02, 0.95, -0.45)
local REBOND_P, REBOND_TH = V(0.02, 0.14, 0.1), 0.3
local PITCH_HAUT, PITCH_IMPACT, PITCH_REBOND = 0.18, -0.32, -0.26
local YAW_HAUT = -0.28
local POLE_G, POLE_A, POLE_I = V(0.3, -0.6, 0.6), V(0.75, 0.55, 0.2), V(0.35, -0.85, 0.2)
local POLEG_G, POLEG_A, POLEG_I = V(-0.5, -0.7, 0.4), V(-0.3, -0.5, -0.8), V(-0.6, -0.75, 0.2)
local VISEE_DEFAUT, PORTEE_VISEE = 0.75, 7

-- Trois gestes qui alternent à chaque coup, avec exactement les mêmes temps (T_HAUT, T_IMPACT, T_FIGE, T_REBOND) :
--  1. coup au-dessus de la tête (pioche derrière l'épaule, torse cambré) ;
--  2. coup en diagonale depuis la droite : buste vrillé, pioche armée à hauteur de l'épaule droite ;
--  3. coup en diagonale depuis la gauche : la main droite croise devant le torse jusqu'à l'épaule gauche.
-- Seules les positions d'armé changent ; l'impact vise toujours le minerai (viser).
type Variante = {hautP: Vector3, hautTh: number, ctrlMontee: Vector3, ctrlFrappe: Vector3,
	pitchHaut: number, yawHaut: number, pole: Vector3, poleG: Vector3}
local VARIANTES: {Variante} = {
	{hautP = HAUT_P, hautTh = HAUT_TH, ctrlMontee = CTRL_MONTEE, ctrlFrappe = CTRL_FRAPPE,
		pitchHaut = PITCH_HAUT, yawHaut = YAW_HAUT, pole = POLE_A, poleG = POLEG_A},
	{hautP = V(0.62, 0.42, 0.32), hautTh = math.rad(38), ctrlMontee = V(0.55, -0.1, -0.25), ctrlFrappe = V(0.42, 0.62, -0.55),
		pitchHaut = 0.08, yawHaut = -0.72, pole = V(0.95, 0.2, 0.35), poleG = V(-0.1, -0.6, -0.8)},
	{hautP = V(-0.52, 0.4, 0.18), hautTh = math.rad(36), ctrlMontee = V(-0.3, -0.12, -0.4), ctrlFrappe = V(-0.32, 0.6, -0.55),
		pitchHaut = 0.08, yawHaut = 0.62, pole = V(0.25, -0.35, -0.9), poleG = V(-0.95, 0.15, 0.3)},
}

type Etat = {
	perso: Model, bras: IK.Bras?, gauche: IK.Bras?, outil: Instance?, actif: boolean, t: number, duree: number,
	poids: number, poidsDepart: number, p0: Vector3, th0: number, pitch: number, yaw: number, pitch0: number, yaw0: number,
	impP: Vector3, impTh: number, yawT: number, grip: CFrame, trail: Trail?, trailOn: boolean, variante: number,
}

local etats: {[Model]: Etat} = {}

local function etatDe(perso: Model): Etat
	local e = etats[perso]
	if not e then
		e = {
			perso = perso, bras = nil, gauche = nil, outil = nil, actif = false, t = 0, duree = DUREE_MIN,
			poids = 0, poidsDepart = 0, p0 = GARDE_P, th0 = GARDE_TH, pitch = 0, yaw = 0, pitch0 = 0, yaw0 = 0,
			impP = GARDE_P, impTh = GARDE_TH, yawT = 0, grip = CFrame.identity, trail = nil, trailOn = false,
			variante = #VARIANTES,
		}
		etats[perso] = e
		perso.Destroying:Once(function()
			etats[perso] = nil
		end)
	end
	return e :: Etat
end

local function cadence(outil: Instance): number
	local def = Pioches.get(outil:GetAttribute("PiocheId"))
	-- « Vitesse » : accélération de la série de coups (clic maintenu), réglée par le serveur
	local vitesse = math.max(outil:GetAttribute("Vitesse") or 1, 1)
	return math.max((if def then def.recharge else 0.6) / vitesse, OCCUPE)
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

local function finir(e: Etat)
	trainee(e, false)
	e.actif = false
	e.poids, e.pitch, e.yaw = 0, 0, 0
	e.perso:SetAttribute("PiocheGeste", nil)
	IK.relacherBras(e.bras)
	IK.relacherBras(e.gauche)
end

-- Minerai le plus proche devant : angle de frappe sous l'horizontale et rotation de la taille vers lui
local function viser(e: Etat, b: IK.Bras, S: Vector3)
	local a, y = VISEE_DEFAUT, 0
	local racine = e.perso:FindFirstChild("HumanoidRootPart")
	if racine and racine:IsA("BasePart") then
		local rc = racine.CFrame
		local Sw = b.torse.CFrame:PointToWorldSpace(S)
		local best = PORTEE_VISEE
		for _, m in CollectionService:GetTagged("Minerai") do
			if m:IsA("BasePart") then
				local rel = rc:VectorToObjectSpace(m.Position + V(0, m.Size.Y * 0.35, 0) - Sw)
				local h = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
				local cote = math.atan2(-rel.X, -rel.Z)
				if rel.Z < -0.3 and h < best and math.abs(cote) < 1 then
					best = h
					a = math.clamp(math.atan2(-rel.Y, h) - 0.2, 0.05, 1.05)
					y = math.clamp(cote, -0.5, 0.5)
				end
			end
		end
	end
	e.impP = V(-0.12, 0.05 - 0.75 * math.sin(a), -0.75 * math.cos(a))
	e.impTh = -math.pi / 2 - 0.6 * a
	e.yawT = y
end

local function demarrer(e: Etat, outil: Instance)
	if not IK.brasValide(e.bras) then
		e.bras = IK.preparerBras(e.perso, "Right")
	end
	if not IK.brasValide(e.gauche) then
		e.gauche = IK.preparerBras(e.perso, "Left")
	end
	local b = e.bras
	if not b or not outil:IsA("Tool") then
		return
	end
	trainee(e, false)
	if e.poids == 0 then
		IK.relacherBras(b)
		IK.relacherBras(e.gauche)
	end
	local tr = outil:FindFirstChild("TraineePioche", true)
	e.trail = if tr and tr:IsA("Trail") then tr else nil
	e.grip = (outil :: Tool).Grip.Rotation
	e.outil = outil
	local S, L = b.epaule.c0Origine.Position, b.l1 + b.l2
	local prise = b.main.CFrame * IK.priseMain(b.main, b.att)
	local d0 = b.torse.CFrame:VectorToObjectSpace((prise * e.grip:Inverse()).UpVector)
	e.p0 = (b.torse.CFrame:PointToObjectSpace(prise.Position) - S) / L
	e.th0 = math.clamp(math.atan2(d0.Z, d0.Y), -2.6, 1.6)
	viser(e, b, S)
	e.variante = e.variante % #VARIANTES + 1 -- geste suivant
	e.t = 0
	e.duree = math.max(cadence(outil), DUREE_MIN)
	e.poidsDepart, e.pitch0, e.yaw0 = e.poids, e.pitch, e.yaw
	e.actif = true
	e.perso:SetAttribute("PiocheGeste", true)
end

-- ================= Joueur local et relais =================

local dernierLocal = -math.huge

local function cliquer(outil: Tool)
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not h or h.Health <= 0 or outil.Parent ~= perso then
		return
	end
	local t = os.clock()
	if t - dernierLocal < cadence(outil) - 0.02 then
		return
	end
	dernierLocal = t
	demarrer(etatDe(perso), outil)
end

local branches: {[Tool]: boolean} = {}
local function brancher(o: Instance)
	if o:IsA("Tool") and o:GetAttribute("PiocheId") and not branches[o] then
		branches[o] = true
		o.Activated:Connect(function()
			cliquer(o)
		end)
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
joueur.CharacterAdded:Connect(suivreConteneur)
joueur.ChildAdded:Connect(function(o)
	if o:IsA("Backpack") then
		suivreConteneur(o)
	end
end)
suivreConteneur(joueur.Character)
suivreConteneur(joueur:FindFirstChildOfClass("Backpack"))

remote.OnClientEvent:Connect(function(perso: any)
	if typeof(perso) ~= "Instance" or not perso:IsA("Model") then
		return
	end
	local outil = perso:FindFirstChildOfClass("Tool")
	if not outil or not outil:GetAttribute("PiocheId") then
		return
	end
	if perso == joueur.Character then
		-- coup accepté par le serveur mais pas prédit ici (clic maintenu : les coups suivants arrivent
		-- par ce relais ; marge pour la gigue du réseau)
		local t = os.clock()
		if t - dernierLocal < cadence(outil) * 0.6 then
			return
		end
		dernierLocal = t
	end
	demarrer(etatDe(perso), outil)
end)

-- ================= Boucle =================

local function avancer(e: Etat, dt: number)
	e.t += dt
	local t, D, b = e.t, e.duree, e.bras
	if t >= D or not b or not IK.brasValide(b) or e.outil == nil or (e.outil :: Instance).Parent ~= e.perso then
		finir(e)
		return
	end
	trainee(e, t >= T_HAUT and t <= T_FIGE + 0.03)

	local w = e.poidsDepart + (1 - e.poidsDepart) * lisse(t / 0.06)
	local v = VARIANTES[e.variante] or VARIANTES[1]
	local p: Vector3, th: number, pitch: number, yaw: number, pole: Vector3, poleG: Vector3
	if t < T_HAUT then
		local u = armer(t / T_HAUT)
		local m = 1 - u
		p = m * m * e.p0 + 2 * m * u * v.ctrlMontee + u * u * v.hautP
		th = e.th0 + (v.hautTh - e.th0) * u
		pitch = e.pitch0 + (v.pitchHaut - e.pitch0) * u
		yaw = e.yaw0 + (v.yawHaut + e.yawT * 0.5 - e.yaw0) * u
		pole, poleG = POLE_G:Lerp(v.pole, u), POLEG_G:Lerp(v.poleG, u)
	elseif t < T_IMPACT then
		local u = (t - T_HAUT) / (T_IMPACT - T_HAUT)
		local s = u * u
		local m = 1 - s
		p = m * m * v.hautP + 2 * m * s * v.ctrlFrappe + s * s * e.impP
		th = v.hautTh + (e.impTh - v.hautTh) * s * u
		pitch = v.pitchHaut + (PITCH_IMPACT - v.pitchHaut) * s
		yaw = v.yawHaut + e.yawT * 0.5 + (e.yawT * 0.5 - v.yawHaut) * s
		pole, poleG = v.pole:Lerp(POLE_I, s), v.poleG:Lerp(POLEG_I, s)
	elseif t < T_FIGE then
		local u = (t - T_IMPACT) / (T_FIGE - T_IMPACT)
		p = e.impP + V(0, 0.02 * math.sin(u * 9.42) * (1 - u), 0)
		th, pitch, yaw = e.impTh, PITCH_IMPACT, e.yawT
		pole, poleG = POLE_I, POLEG_I
	elseif t < T_REBOND then
		local u = armer((t - T_FIGE) / (T_REBOND - T_FIGE))
		p = e.impP + REBOND_P * u
		th = e.impTh + REBOND_TH * u
		pitch = PITCH_IMPACT + (PITCH_REBOND - PITCH_IMPACT) * u
		yaw = e.yawT
		pole, poleG = POLE_I, POLEG_I
	else
		local u = lisse((t - T_REBOND) / (D - T_REBOND))
		p = (e.impP + REBOND_P):Lerp(GARDE_P, u)
		th = e.impTh + REBOND_TH + (GARDE_TH - e.impTh - REBOND_TH) * u
		pitch, yaw = PITCH_REBOND * (1 - u), e.yawT * (1 - u)
		pole, poleG = POLE_I:Lerp(POLE_G, u), POLEG_I:Lerp(POLEG_G, u)
		w *= 1 - u
	end
	e.poids, e.pitch, e.yaw = w, pitch, yaw

	if e.perso:GetAttribute("EpeeGeste") then
		return
	end
	local S, L = b.epaule.c0Origine.Position, b.l1 + b.l2
	local d = V(0, math.cos(th), math.sin(th))
	local n = V(0, -d.Z, d.Y)
	local main = S + p * L
	IK.poserBras(b, main, pole, d, n, e.grip, w)
	local g = e.gauche
	if g and IK.brasValide(g) then
		IK.poserBras(g, main - d * SEP_MAINS, poleG, d, n, e.grip, w)
	end
	IK.poserTaille(b, pitch * w, yaw * w)
end

local derniere = os.clock()
RunService.PreSimulation:Connect(function()
	local t = os.clock()
	local dt = math.min(t - derniere, 0.1)
	derniere = t
	for _, e in etats do
		if e.actif then
			avancer(e, dt)
		end
	end
end)
