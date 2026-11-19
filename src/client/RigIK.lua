--!strict
-- Pose procédurale des bras R15 (AnimationConstraint ou Motor6D) : C0 = C0origine * pose * Transform⁻¹.
-- IK 2 segments (épaule + coude), poignet orienté selon l'outil, taille. Partagé par EpeeAnimation et PiocheAnimation.

local V = Vector3.new

export type Joint = {moteur: Instance, cadre: Instance, c0Origine: CFrame, rotC0Inv: CFrame, c1Rot: CFrame}
export type Bras = {
	epaule: Joint, coude: Joint, poignet: Joint?, taille: Joint?,
	torse: BasePart, main: BasePart, att: string, l1: number, l2: number,
	qHautInv: CFrame, qBasInv: CFrame, priseInv: CFrame,
}

local M = {}

function M.lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end
function M.sortie(u: number): number
	u = 1 - u
	return 1 - u * u * u
end
function M.entree(u: number): number
	return u * u * u
end

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

function M.trouverJoint(perso: Model, nom: string): Joint?
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
		local cadre = if d:IsA("Motor6D") then d else (d :: any).Attachment0
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

function M.jointValide(j: Joint?): boolean
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
	if j and M.jointValide(j) then
		ecrire(j, (j.moteur :: any).Transform:Lerp(pose, w))
	end
end

local function relacher(j: Joint?)
	if j and M.jointValide(j) then
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

function M.priseMain(main: BasePart, nom: string): CFrame
	local att = main:FindFirstChild(nom)
	return if att and att:IsA("Attachment") then att.CFrame else CFrame.identity
end

-- cote = "Right" ou "Left" ; la taille (Waist) n'est rattachée qu'au bras droit
function M.preparerBras(perso: Model, cote: string): Bras?
	local epaule = M.trouverJoint(perso, cote .. "Shoulder")
	local coude = M.trouverJoint(perso, cote .. "Elbow")
	local poignet = M.trouverJoint(perso, cote .. "Wrist")
	local main = perso:FindFirstChild(cote .. "Hand")
	local torse = perso:FindFirstChild("UpperTorso")
	if not (epaule and coude and main and main:IsA("BasePart") and torse and torse:IsA("BasePart")) then
		return nil
	end
	local nom = cote .. "GripAttachment"
	local prise = M.priseMain(main, nom)
	local u = coude.c0Origine.Position - lireC1(epaule.moteur).Position
	local mainAvantBras = if poignet then poignet.c0Origine * lireC1(poignet.moteur):Inverse() * prise else CFrame.new(0, -1, 0)
	local v = mainAvantBras.Position - lireC1(coude.moteur).Position
	return {
		epaule = epaule, coude = coude, poignet = poignet,
		taille = if cote == "Right" then M.trouverJoint(perso, "Waist") else nil,
		torse = torse, main = main, att = nom, l1 = u.Magnitude, l2 = v.Magnitude,
		qHautInv = rotationDepuisBas(u):Inverse(), qBasInv = rotationDepuisBas(v):Inverse(),
		priseInv = prise.Rotation:Inverse(),
	}
end

function M.brasValide(b: Bras?): boolean
	return b ~= nil and M.jointValide(b.epaule) and M.jointValide(b.coude)
		and (b.poignet == nil or M.jointValide(b.poignet)) and b.torse.Parent ~= nil and b.main.Parent ~= nil
end

function M.relacherBras(b: Bras?)
	if b then
		relacher(b.epaule)
		relacher(b.coude)
		relacher(b.poignet)
		relacher(b.taille)
	end
end

-- Taille : flexion (pitch, + = cambré) et rotation (yaw, + = épaule droite vers l'avant), repère du torse
function M.poserTaille(b: Bras, pitch: number, yaw: number)
	local ta = b.taille
	if ta and M.jointValide(ta) then
		ecrire(ta, (ta.moteur :: any).Transform * (ta.rotC0Inv * CFrame.Angles(pitch, yaw, 0) * ta.c0Origine.Rotation))
	end
end

-- Prise de la main sur `cible`, coude vers `pole`, outil (+Y du Handle) selon `dir`, Z du Handle normal à `n`
function M.poserBras(b: Bras, cible: Vector3, pole: Vector3, dir: Vector3, n: Vector3, grip: CFrame, w: number)
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

return M
