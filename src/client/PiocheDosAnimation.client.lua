--!strict
-- Pioche dans le dos · SCRIPT CLIENT (geste de dégainage / rangement)
-- Va avec le SCRIPT SERVEUR PiocheDos (qui soude le modèle « PiocheDos » dans le dos).
--
-- Chaque client anime TOUS les personnages (le sien et ceux des autres) : aucune animation
-- importée, aucun RemoteEvent. On le voit dès qu'un outil-pioche entre ou sort d'un personnage
-- (ce qui est répliqué), puis on joue le geste localement :
--  • Dégainer : la main monte devant l'épaule, passe par-dessus et va saisir le manche derrière
--    l'épaule ; la pioche du dos devient l'outil en main ; la main l'arrache vers le haut puis la
--    ramène devant. Le torse pivote un peu pour accompagner le geste.
--  • Ranger : la main lève la pioche par-dessus l'épaule et la pose dans le dos, puis redescend.
--    (L'outil quitte la main tout de suite côté Roblox : une copie de la pioche du dos est soudée
--    à la main le temps du geste.)
--
-- La main suit une trajectoire courbe (spline) et le bras est placé par IK à deux segments
-- (épaule + coude) : la main arrive exactement sur le manche, quelle que soit la taille de l'avatar.
-- Le bras est posé en décalant le « C0 » des articulations (l'Animator réécrit Transform à chaque
-- frame, jamais C0) et on mélange avec l'animation en cours (marche, « tenir un outil »…) au début
-- et à la fin du geste : aucun à-coup. On peut marcher pendant le geste.
-- Ces écritures sont locales (non répliquées) : c'est pour ça que chaque client anime tout le monde.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ================= Réglages du geste =================

local DUREE_ALLER = 0.5 -- la main va chercher le manche (ou porte la pioche jusqu'au dos)
local DUREE_TENIR = 0.07 -- la main reste un instant sur le manche
local DUREE_RETOUR = 0.55 -- la main ramène la pioche devant (ou redescend)
local DUREE_ANNULER = 0.3 -- geste interrompu : la main revient

local ROTATION_TORSE = math.rad(14) -- le torse pivote (épaule droite vers l'arrière) pendant le geste

-- Points de passage de la main, relatifs à l'épaule, en longueurs de bras (repère du torse :
-- +X = droite, +Y = haut, -Z = devant, +Z = dos).
local POINTS = {
	devantEpaule = Vector3.new(0.2, 0.05, -0.55), -- main qui monte devant l'épaule
	auDessus = Vector3.new(0.05, 0.6, -0.1), -- main au-dessus de l'épaule
	arrache = Vector3.new(0.12, 0.72, 0.12), -- la pioche est tirée vers le haut, hors du dos
	pret = Vector3.new(0.1, -0.25, -0.6), -- pioche tenue devant
	repos = Vector3.new(0.12, -0.9, 0), -- bras le long du corps
}
-- Direction vers laquelle pointe le coude (repère du torse)
local COUDES = {
	bas = Vector3.new(0.3, -0.5, 0.8),
	dehors = Vector3.new(0.9, -0.3, 0.3),
	haut = Vector3.new(0.7, 0.7, 0),
	hautAvant = Vector3.new(0.35, 0.85, -0.4),
}
-- Point du manche saisi si on ne trouve pas le modèle du dos (repère du torse)
local SAISIE_DEFAUT = Vector3.new(0.5, 0.85, 0.8)

-- Rig R6 (pas de coude) : simple rotation de l'épaule
local R = math.rad
local POSES_R6 = {
	mi = CFrame.Angles(R(100), 0, 0),
	haut = CFrame.Angles(R(195), 0, R(-10)),
}

-- Prise de la main droite en R6 (soudure « RightGrip » par défaut)
local PRISE_R6 = CFrame.new(0, -1, 0) * CFrame.Angles(R(-90), 0, 0)
local GRIP_DEFAUT = CFrame.new(0, -1.0, 0)

type Joint = {
	moteur: Instance, -- Motor6D ou AnimationConstraint
	cadre: Instance, -- ce qui porte le « C0 » : le Motor6D lui-même, ou l'Attachment0 de la contrainte
	c0Origine: CFrame, -- C0 d'origine du joint (remis en place à la fin du geste)
	rotC0: CFrame, -- rotation de C0 : pour exprimer la pose dans le repère de Part0
}

type Bras = {
	epaule: Joint,
	coude: Joint?, -- nil en R6
	poignet: Joint?,
	taille: Joint?, -- rotation du torse (Waist, R15)
	torse: BasePart,
	main: BasePart,
	l1: number, -- épaule → coude
	l2: number, -- coude → prise de la main
	qHaut: CFrame, -- -Y → direction réelle épaule→coude dans le haut du bras
	qBas: CFrame, -- -Y → direction réelle coude→prise dans l'avant-bras
}

type EtatPerso = {
	perso: Model,
	connexions: {RBXScriptConnection},
	afficheEnMain: boolean, -- ce qui est montré : true = pioche en main, false = dans le dos
	cibleEnMain: boolean, -- ce qui est vrai côté jeu (outil dans le Character ou non)
	grip: CFrame, -- tool.Grip au moment où l'outil est entré
	enAttente: boolean,
	-- Geste en cours
	phase: string?, -- "aller", "tenir", "retour", "annuler" ou nil (au repos)
	t: number, -- temps écoulé dans la phase
	poids: number, -- 0 = animation normale, 1 = geste
	poidsDepart: number,
	points: {Vector3},
	coudes: {Vector3},
	bras: Bras?,
}

local etats: {[Model]: EtatPerso} = {}
local NOM_SOUDURE_MAIN = "SoudureMainLocale"

local function deconnecter(liste: {RBXScriptConnection})
	for _, c in liste do
		c:Disconnect()
	end
	table.clear(liste)
end

local function estPioche(instance: Instance): boolean
	return instance:IsA("Tool") and instance:GetAttribute("PiocheId") ~= nil
end

local function piocheEnMain(perso: Model): Tool?
	for _, t in perso:GetChildren() do
		if estPioche(t) then
			return t :: Tool
		end
	end
	return nil
end

local function mainDroite(perso: Model): BasePart?
	local main = perso:FindFirstChild("RightHand") or perso:FindFirstChild("Right Arm")
	if main and main:IsA("BasePart") then
		return main
	end
	return nil
end

local function priseMain(main: BasePart): CFrame
	local att = main:FindFirstChild("RightGripAttachment")
	if att and att:IsA("Attachment") then
		return att.CFrame
	end
	return PRISE_R6
end

-- ================= Affichage : dos ou main =================

local function soudureDos(modele: Instance?): Weld?
	local racine = modele and modele:FindFirstChild("RacineDos")
	local soudure = racine and racine:FindFirstChild("SoudureDos")
	if soudure and soudure:IsA("Weld") then
		return soudure
	end
	return nil
end

local function appliquer(e: EtatPerso)
	local perso = e.perso
	local outil = piocheEnMain(perso)
	local modele = perso:FindFirstChild("PiocheDos")

	-- L'outil en main reste caché tant que la main n'a pas attrapé le manche
	if outil then
		local ltm = if e.afficheEnMain then 0 else 1
		for _, d in outil:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = ltm
			end
		end
	end

	if modele and modele:IsA("Model") then
		-- Montré dans le dos si la pioche est rangée ; montré dans la main pendant le rangement
		-- (l'outil a déjà quitté la main mais le bras n'a pas encore atteint le dos).
		local visible = not e.afficheEnMain or outil == nil
		local dansLaMain = e.afficheEnMain and outil == nil
		for _, d in modele:GetDescendants() do
			if d:IsA("BasePart") then
				local origine = d:GetAttribute("TransparenceOrigine")
				if typeof(origine) == "number" then
					d.Transparency = if visible then origine else 1
				end
			end
		end
		-- On ne modifie JAMAIS la soudure du dos (créée par le serveur) : pour tenir la copie en main,
		-- on la désactive et on ajoute une soudure locale main → racine, détruite ensuite.
		local soudure = soudureDos(modele)
		local racine = modele:FindFirstChild("RacineDos")
		if soudure and racine and racine:IsA("BasePart") then
			local locale = racine:FindFirstChild(NOM_SOUDURE_MAIN)
			local main = mainDroite(perso)
			if dansLaMain and main then
				if not (locale and locale:IsA("Weld")) then
					local w = Instance.new("Weld")
					w.Name = NOM_SOUDURE_MAIN
					w.Part1 = racine
					w.Parent = racine
					locale = w
				end
				local w = locale :: Weld
				w.Part0 = main
				w.C0 = priseMain(main) * e.grip:Inverse()
				soudure.Enabled = false
			else
				if locale then
					locale:Destroy()
				end
				soudure.Enabled = true
			end
		end
	end
end

-- Regroupe les ajouts de la même frame (modèle reconstruit, pièces qui arrivent…)
local function planifier(e: EtatPerso)
	if e.enAttente then
		return
	end
	e.enAttente = true
	task.defer(function()
		e.enAttente = false
		if etats[e.perso] == e then
			appliquer(e)
		end
	end)
end

-- ================= Articulations =================

-- L'Animator réécrit Transform à chaque frame : on ne s'y fie pas. On décale le « C0 » du joint,
-- que l'Animator ne touche jamais : rendu = Part0 * C0 * Transform * C1⁻¹. En posant
-- C0 = C0origine * T' * Transform⁻¹, on obtient exactement la pose T' voulue.
-- Deux sortes de rigs :
--  • Motor6D : le « C0 » est Motor6D.C0, le « C1 » Motor6D.C1 ;
--  • AnimationConstraint (rigs récents) : Attachment0.CFrame et Attachment1.CFrame.
local function cadreDe(d: Instance): Instance?
	if d:IsA("Motor6D") then
		return d
	elseif d:IsA("AnimationConstraint") then
		return d.Attachment0
	end
	return nil
end

local function lireC0(j: Joint): CFrame
	local cadre = j.cadre
	return if cadre:IsA("Motor6D") then cadre.C0 else (cadre :: Attachment).CFrame
end

local function ecrireC0(j: Joint, cf: CFrame)
	local cadre = j.cadre
	if cadre:IsA("Motor6D") then
		cadre.C0 = cf
	else
		(cadre :: Attachment).CFrame = cf
	end
end

local function lireC1(j: Joint): CFrame
	local m = j.moteur
	if m:IsA("Motor6D") then
		return m.C1
	end
	local att = (m :: AnimationConstraint).Attachment1
	return if att then att.CFrame else CFrame.identity
end

local function trouverJoint(perso: Model, noms: {string}): Joint?
	for _, d in perso:GetDescendants() do
		if table.find(noms, d.Name) then
			local cadre = cadreDe(d)
			if cadre then
				local j: Joint = {moteur = d, cadre = cadre, c0Origine = CFrame.identity, rotC0 = CFrame.identity}
				-- C0 d'origine gardé en attribut local : survit même si on retrouve le joint en plein geste
				local origine = cadre:GetAttribute("C0Origine")
				if typeof(origine) ~= "CFrame" then
					origine = lireC0(j)
					cadre:SetAttribute("C0Origine", origine)
				end
				j.c0Origine = origine :: CFrame
				j.rotC0 = j.c0Origine.Rotation
				return j
			end
		end
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

-- Pose de l'animation en cours sur ce joint
local function lireBase(j: Joint): CFrame
	return (j.moteur :: any).Transform
end

-- Force la pose finale du joint à `cf` (repère du joint), quelle que soit l'animation
local function ecrire(j: Joint, cf: CFrame)
	ecrireC0(j, j.c0Origine * cf * lireBase(j):Inverse())
end

local function relacher(j: Joint?)
	if j and jointValide(j) then
		ecrireC0(j, j.c0Origine)
	end
end

-- Rotation qui amène l'axe -Y sur la direction de `v` (os pas exactement vertical dans sa pièce)
local function rotationDepuisBas(v: Vector3): CFrame
	local bas = Vector3.new(0, -1, 0)
	local d = v.Unit
	local axe = bas:Cross(d)
	if axe.Magnitude < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axe.Unit, math.acos(math.clamp(bas:Dot(d), -1, 1)))
end

local function preparerBras(perso: Model): Bras?
	local epaule = trouverJoint(perso, {"RightShoulder", "Right Shoulder"})
	local main = mainDroite(perso)
	local torse = perso:FindFirstChild("UpperTorso") or perso:FindFirstChild("Torso")
	if not (epaule and main and torse and torse:IsA("BasePart")) then
		return nil
	end
	local coude = trouverJoint(perso, {"RightElbow"})
	local poignet = trouverJoint(perso, {"RightWrist"})
	local bras: Bras = {
		epaule = epaule,
		coude = coude,
		poignet = poignet,
		taille = trouverJoint(perso, {"Waist"}),
		torse = torse,
		main = main,
		l1 = 1,
		l2 = 1,
		qHaut = CFrame.identity,
		qBas = CFrame.identity,
	}
	if coude and poignet then
		-- Longueurs mesurées sur le rig : épaule → coude, puis coude → point de prise de la main,
		-- poignet droit (pendant le geste on garde le poignet droit, voir poserIK)
		local u = coude.c0Origine.Position - lireC1(epaule).Position
		local mainDansAvantBras = poignet.c0Origine * lireC1(poignet):Inverse() * priseMain(main)
		local v = mainDansAvantBras.Position - lireC1(coude).Position
		bras.l1 = u.Magnitude
		bras.l2 = v.Magnitude
		bras.qHaut = rotationDepuisBas(u)
		bras.qBas = rotationDepuisBas(v)
	end
	return bras
end

local function brasValide(b: Bras?): boolean
	return b ~= nil
		and jointValide(b.epaule)
		and (b.coude == nil or jointValide(b.coude))
		and (b.poignet == nil or jointValide(b.poignet))
		and b.torse.Parent ~= nil
		and b.main.Parent ~= nil
end

local function relacherBras(e: EtatPerso)
	local b = e.bras
	if b and not e.perso:GetAttribute("EpeeGeste") then
		relacher(b.epaule)
		relacher(b.coude)
		relacher(b.poignet)
		relacher(b.taille)
	end
end

-- ================= Trajectoire et IK =================

local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * u * (u * (u * 6 - 15) + 10)
end

-- Courbe passant par tous les points (Catmull-Rom), u de 0 à 1
local function spline(pts: {Vector3}, u: number): Vector3
	local n = #pts
	if n == 1 then
		return pts[1]
	end
	local s = math.clamp(u, 0, 1) * (n - 1)
	local i = math.min(math.floor(s), n - 2) + 1
	local t = s - (i - 1)
	local p0, p1 = pts[math.max(i - 1, 1)], pts[i]
	local p2, p3 = pts[i + 1], pts[math.min(i + 2, n)]
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * (t * t)
		+ (3 * p1 - p0 - 3 * p2 + p3) * (t * t * t))
end

-- Position actuelle de la prise de la main, dans le repère du torse
local function mainDansTorse(b: Bras): Vector3
	return b.torse.CFrame:PointToObjectSpace((b.main.CFrame * priseMain(b.main)).Position)
end

local function pivotEpaule(b: Bras): Vector3
	return b.epaule.c0Origine.Position
end

-- Point du manche que la main saisit quand la pioche est dans le dos (repère du torse)
local function pointSaisie(e: EtatPerso, b: Bras): Vector3
	local soudure = soudureDos(e.perso:FindFirstChild("PiocheDos"))
	if soudure and soudure.Part0 == b.torse then
		-- Position de repos de la racine (= Handle) dans le dos, puis le point tenu par la main
		return (soudure.C0 * e.grip).Position
	end
	return SAISIE_DEFAUT * (b.l1 + b.l2) / 2
end

local function versPoint(b: Bras, relatif: Vector3): Vector3
	return pivotEpaule(b) + relatif * (b.l1 + b.l2)
end

-- IK à deux segments : place la prise de la main sur `cible`, coude tourné vers `pole`
local function poserIK(b: Bras, cible: Vector3, pole: Vector3, w: number)
	local coude = b.coude :: Joint
	local S = pivotEpaule(b)
	local l1, l2 = b.l1, b.l2
	local d = cible - S
	local dist = math.clamp(d.Magnitude, math.abs(l1 - l2) + 0.02, (l1 + l2) * 0.999)
	local dir = if d.Magnitude > 1e-4 then d.Unit else Vector3.new(0, -1, 0)
	local a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
	local h = math.sqrt(math.max(0, l1 * l1 - a * a))
	local perp = pole - dir * pole:Dot(dir)
	if perp.Magnitude < 1e-3 then
		perp = Vector3.new(0, 0, 1) - dir * dir.Z
	end
	perp = perp.Unit
	local E = S + dir * a + perp * h
	local H = S + dir * dist

	-- Haut du bras : +Y de l'os va du coude vers l'épaule ; l'avant-bras se replie vers son -Z
	local yH = (S - E).Unit
	local f = (H - E).Unit
	local zf = f - yH * f:Dot(yH)
	local zH = if zf.Magnitude > 1e-3 then -zf.Unit else -perp
	local xH = yH:Cross(zH)
	local rotHaut = CFrame.fromMatrix(Vector3.zero, xH, yH, zH)
	-- Avant-bras : même axe de pli (X), +Y du poignet vers le coude
	local yB = (E - H).Unit
	local zB = xH:Cross(yB)
	local rotBas = CFrame.fromMatrix(Vector3.zero, xH, yB, zB)
	-- Corrige pour les os qui ne sont pas exactement selon -Y dans leur pièce
	rotHaut = rotHaut * b.qHaut:Inverse()
	rotBas = rotBas * b.qBas:Inverse()

	local poseEpaule = b.epaule.rotC0:Inverse() * rotHaut * lireC1(b.epaule).Rotation
	local poseCoude = coude.rotC0:Inverse() * (rotHaut:Inverse() * rotBas) * lireC1(coude).Rotation
	ecrire(b.epaule, lireBase(b.epaule):Lerp(poseEpaule, w))
	ecrire(coude, lireBase(coude):Lerp(poseCoude, w))
	-- Poignet droit : la prise de la main reste dans l'axe de l'avant-bras (l'animation « tenir un
	-- outil » plie le poignet, ce qui décalerait la main du manche)
	local poignet = b.poignet
	if poignet and jointValide(poignet) then
		ecrire(poignet, lireBase(poignet):Lerp(CFrame.identity, w))
	end
end

-- R6 : pas de coude, on lève simplement le bras (repère du joint)
local function poserR6(b: Bras, avance: number, w: number)
	local j = b.epaule
	local mi = j.rotC0:Inverse() * POSES_R6.mi * j.rotC0
	local haut = j.rotC0:Inverse() * POSES_R6.haut * j.rotC0
	local cible = if avance < 0.5 then mi else mi:Lerp(haut, avance * 2 - 1)
	ecrire(j, lireBase(j):Lerp(cible, w * math.min(1, avance * 2)))
end

local function tournerTorse(b: Bras, w: number)
	local taille = b.taille
	if taille and jointValide(taille) then
		local rot = taille.rotC0:Inverse() * CFrame.Angles(0, -ROTATION_TORSE * w, 0) * taille.rotC0
		ecrire(taille, lireBase(taille) * rot)
	end
end

-- ================= Geste =================

local function demarrer(e: EtatPerso, phase: string, points: {Vector3}, coudes: {Vector3})
	e.phase = phase
	e.t = 0
	e.poidsDepart = e.poids
	e.points = points
	e.coudes = coudes
end

-- La main part de là où elle est et va saisir le manche (dégainer) ou porter la pioche au dos
local function lancerAller(e: EtatPerso, b: Bras)
	local depart = mainDansTorse(b)
	local saisie = pointSaisie(e, b)
	if e.cibleEnMain then
		demarrer(e, "aller",
			{depart, versPoint(b, POINTS.devantEpaule), versPoint(b, POINTS.auDessus), saisie},
			{COUDES.bas, COUDES.dehors, COUDES.haut, COUDES.hautAvant})
	else
		demarrer(e, "aller",
			{depart, versPoint(b, POINTS.arrache), saisie},
			{COUDES.bas, COUDES.haut, COUDES.hautAvant})
	end
end

-- Après l'échange dos ↔ main : la main ramène la pioche devant, ou redescend
local function lancerRetour(e: EtatPerso, b: Bras)
	local saisie = pointSaisie(e, b)
	if e.afficheEnMain then
		demarrer(e, "retour",
			{saisie, versPoint(b, POINTS.arrache), versPoint(b, POINTS.pret)},
			{COUDES.hautAvant, COUDES.haut, COUDES.bas})
	else
		demarrer(e, "retour",
			{saisie, versPoint(b, POINTS.auDessus), versPoint(b, POINTS.devantEpaule), versPoint(b, POINTS.repos)},
			{COUDES.hautAvant, COUDES.haut, COUDES.dehors, COUDES.bas})
	end
end

-- Geste interrompu avant l'échange : la main revient sans rien échanger
local function lancerAnnuler(e: EtatPerso, b: Bras)
	local fin = if e.afficheEnMain then POINTS.pret else POINTS.repos
	demarrer(e, "annuler", {mainDansTorse(b), versPoint(b, fin)}, {COUDES.haut, COUDES.bas})
end

local function finir(e: EtatPerso)
	e.phase = nil
	e.poids = 0
	relacherBras(e)
end

-- Appelé quand la pioche entre ou sort du personnage
local function changer(e: EtatPerso, enMain: boolean)
	e.cibleEnMain = enMain
	local humanoid = e.perso:FindFirstChildOfClass("Humanoid")
	local vivant = humanoid ~= nil and humanoid.Health > 0
	if not brasValide(e.bras) then
		e.bras = preparerBras(e.perso)
	end
	local b = e.bras
	if not vivant or not b then
		-- Pas de geste (mort, rig incomplet) : on affiche directement le bon état
		e.afficheEnMain = enMain
		if e.phase then
			finir(e)
		end
	elseif e.afficheEnMain == enMain then
		-- Retour à l'état déjà affiché (spam) : la main revient sans rien échanger
		if e.phase == "aller" then
			lancerAnnuler(e, b)
		end
	elseif e.phase == "tenir" or e.phase == "retour" then
		-- Échange déjà fait dans l'autre sens : on enchaîne directement le nouveau geste
		lancerAller(e, b)
	else
		lancerAller(e, b)
	end
	appliquer(e)
end

local function avancer(e: EtatPerso, dt: number)
	local b = e.bras
	if not b or not brasValide(b) then
		e.afficheEnMain = e.cibleEnMain
		e.phase = nil
		appliquer(e)
		return
	end
	e.t += dt
	local u = 0
	if e.phase == "aller" then
		u = e.t / DUREE_ALLER
		e.poids = e.poidsDepart + (1 - e.poidsDepart) * lisse(u / 0.35)
		if u >= 1 then
			-- La main tient le manche : on échange dos ↔ main
			e.afficheEnMain = e.cibleEnMain
			e.phase = "tenir"
			e.t = 0
			e.poids = 1
			appliquer(e)
		end
	elseif e.phase == "tenir" then
		u = 1
		e.poids = 1
		if e.t >= DUREE_TENIR then
			lancerRetour(e, b)
			u = 0
		end
	elseif e.phase == "retour" then
		u = e.t / DUREE_RETOUR
		e.poids = 1 - lisse((u - 0.45) / 0.55)
	else -- annuler
		u = e.t / DUREE_ANNULER
		e.poids = e.poidsDepart * (1 - lisse(u))
	end

	if (e.phase == "retour" or e.phase == "annuler") and u >= 1 then
		finir(e)
		return
	end

	local avance = lisse(u)
	if e.perso:GetAttribute("EpeeGeste") then
		return -- l'épée (EpeeAnimation) a la priorité sur le bras
	elseif b.coude then
		local cible = spline(e.points, avance)
		local pole = spline(e.coudes, avance)
		poserIK(b, cible, pole, e.poids)
		tournerTorse(b, e.poids)
	else
		-- R6 : on approxime la hauteur de la main par la progression vers le manche
		local haut = if e.phase == "aller" then avance elseif e.phase == "tenir" then 1 else 1 - avance
		poserR6(b, haut, e.poids)
	end
end

-- Temps mesuré nous-mêmes (le dt de PreSimulation n'est pas fiable pour ça)
local derniereFrame = os.clock()
RunService.PreSimulation:Connect(function()
	local maintenant = os.clock()
	local dt = math.min(maintenant - derniereFrame, 0.1)
	derniereFrame = maintenant
	for _, e in etats do
		if e.phase then
			avancer(e, dt)
		end
	end
end)

-- ================= Suivi des personnages =================

local function oublierPerso(perso: Model)
	local e = etats[perso]
	if not e then
		return
	end
	deconnecter(e.connexions)
	if e.phase then
		relacherBras(e)
	end
	etats[perso] = nil
end

local function suivrePerso(perso: Model)
	if etats[perso] then
		return
	end
	local outil = piocheEnMain(perso)
	local e: EtatPerso = {
		perso = perso,
		connexions = {},
		afficheEnMain = outil ~= nil, -- état initial sans geste
		cibleEnMain = outil ~= nil,
		grip = if outil then outil.Grip else GRIP_DEFAUT,
		enAttente = false,
		phase = nil,
		t = 0,
		poids = 0,
		poidsDepart = 0,
		points = {},
		coudes = {},
		bras = nil,
	}
	etats[perso] = e

	table.insert(e.connexions, perso.ChildAdded:Connect(function(enfant)
		if estPioche(enfant) then
			e.grip = (enfant :: Tool).Grip
			changer(e, true)
		elseif enfant.Name == "PiocheDos" then
			planifier(e)
		end
	end))
	table.insert(e.connexions, perso.ChildRemoved:Connect(function(enfant)
		if estPioche(enfant) then
			-- Différé : si une nouvelle pioche remplace l'ancienne dans la même frame, pas de rangement
			task.defer(function()
				if etats[perso] == e and e.cibleEnMain and piocheEnMain(perso) == nil then
					changer(e, false)
				end
			end)
		end
	end))
	-- Pièces qui arrivent après coup (réplication) : on leur applique l'état actuel
	table.insert(e.connexions, perso.DescendantAdded:Connect(function(d)
		local parent = d.Parent
		if d:IsA("BasePart") and parent and (parent.Name == "PiocheDos" or estPioche(parent)) then
			planifier(e)
		end
	end))
	-- (Pas d'AncestryChanged : avec le streaming, un personnage peut sortir puis revenir.)
	table.insert(e.connexions, perso.Destroying:Connect(function()
		oublierPerso(perso)
	end))

	appliquer(e)
end

local connexionsJoueurs: {[Player]: {RBXScriptConnection}} = {}
local persoSuivi: {[Player]: Model} = {}

-- Un seul personnage suivi par joueur : l'ancien est oublié même si CharacterRemoving/Destroying
-- n'ont pas été vus (sécurité contre les fuites)
local function suivre(joueur: Player, perso: Model)
	local ancien = persoSuivi[joueur]
	if ancien and ancien ~= perso then
		oublierPerso(ancien)
	end
	persoSuivi[joueur] = perso
	suivrePerso(perso)
end

local function surJoueur(joueur: Player)
	if connexionsJoueurs[joueur] then
		return
	end
	local liste = {}
	connexionsJoueurs[joueur] = liste
	table.insert(liste, joueur.CharacterAdded:Connect(function(perso)
		suivre(joueur, perso)
	end))
	table.insert(liste, joueur.CharacterRemoving:Connect(oublierPerso))
	if joueur.Character then
		suivre(joueur, joueur.Character)
	end
end

Players.PlayerAdded:Connect(surJoueur)
Players.PlayerRemoving:Connect(function(joueur)
	local liste = connexionsJoueurs[joueur]
	if liste then
		deconnecter(liste)
		connexionsJoueurs[joueur] = nil
	end
	local perso = persoSuivi[joueur]
	if perso then
		oublierPerso(perso)
	end
	persoSuivi[joueur] = nil
end)
for _, joueur in Players:GetPlayers() do
	surJoueur(joueur)
end
