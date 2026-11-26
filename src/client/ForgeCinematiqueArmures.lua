-- Cinématiques de forge des plastrons et des jambières (utilisé par ForgeCinematique.client).
-- La pièce travaillée est le VRAI modèle forgé (ArmuresVoxels, res.modele) : chauffé au rouge, il se forme morceau par
-- morceau à chaque coup (un lingot brut fond à mesure), refroidit, se réchauffe au fourneau, puis la trempe rend à
-- chaque Part sa couleur et son matériau. Brom (clone local) tient la pièce aux tenailles (main gauche, IK 2 segments)
-- et frappe de la main droite (poses PosesNains + correction IK : la panne touche la surface réelle frappée).
-- Décor réel : fourneau (Fourneau, attribut Base), enclume (Table), Bigorne, seau Forge_SeauEau (sinon un seau posé
-- dès le début). Brom change de poste (foyer, enclume, bigorne, seau) aux changements de plan.
local Players = game:GetService("Players")

local V, C = Vector3.new, CFrame.new
local PI = math.pi
local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis
local FER = Color3.fromRGB(58, 58, 64)
local BOIS = Color3.fromRGB(95, 55, 32)
local EAU = Color3.fromRGB(60, 120, 170)
-- modèle couché face vers le haut : haut du modèle (+Y) vers les tenailles (-Z), dos (+Z) vers le bas
local COUCHE = CFrame.fromMatrix(Vector3.zero, V(-1, 0, 0), V(0, 0, -1), V(0, -1, 0))
local ATTACHES = {"JointInstance", "WeldConstraint", "NoCollisionConstraint"}

local COURBES = {
	douce = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end,
	sortie = function(t) return 1 - (1 - t) ^ 2.4 end,
	entree = function(t) return t ^ 2.2 end,
}
local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end
local function lerpCF(a: CFrame, b: CFrame, w: number): CFrame return a:Lerp(b, w) end
local function lerpN(a: number, b: number, w: number): number return a + (b - a) * w end
local function brut(v) return v end

-- Clés {t, valeur, courbe, coupe} : coupe = saut net à cet instant (changement de plan).
local function cleA(cles, t: number, resoudre, melanger)
	local k = 1
	while k < #cles and t >= cles[k + 1][1] do k += 1 end
	local a, b = cles[k], cles[k + 1]
	local va = resoudre(a[2])
	if not b or t <= a[1] or b[4] then return va, a end
	return melanger(va, resoudre(b[2]), COURBES[b[3] or "douce"](math.clamp((t - a[1]) / (b[1] - a[1]), 0, 1))), a
end

local function orth(v: Vector3, a: Vector3): Vector3?
	local o = v - a * v:Dot(a)
	return if o.Magnitude > 1e-4 then o.Unit else nil
end
local function repere(axe: Vector3, charniere: Vector3): CFrame
	return CFrame.fromMatrix(Vector3.zero, charniere, axe)
end
local function autour(P: Vector3, rot: CFrame): CFrame
	return C(P) * rot * C(-P)
end

-- IK 2 segments (épaule S → coude → poignet W) : transformations rigides du bras et de l'avant-bras (repère de Brom).
local function ik(sd, S: Vector3, W: Vector3, pole: Vector3, indice: Vector3)
	local d = W - S
	local dist = math.clamp(d.Magnitude, math.abs(sd.l1 - sd.l2) + 1e-3, sd.l1 + sd.l2 - 1e-3)
	local u = if d.Magnitude > 1e-4 then d.Unit else -Y
	local a = (sd.l1 ^ 2 - sd.l2 ^ 2 + dist ^ 2) / (2 * dist)
	local h = math.sqrt(math.max(sd.l1 ^ 2 - a ^ 2, 0))
	local perp = orth(pole - S, u) or orth(Z, u) or X
	local E = S + u * a + perp * h
	local Wr = S + u * dist
	local a1, a2 = (E - S).Unit, (Wr - E).Unit
	local n = a1:Cross(a2)
	n = if n.Magnitude > 0.03 then n.Unit else (orth(indice, a1) or X)
	local Q1 = repere(a1, orth(n, a1) or X) * sd.R1inv
	local Q2 = repere(a2, orth(n, a2) or X) * sd.R2inv
	return C(S) * Q1 * C(-sd.S0), C(E) * Q2 * C(-sd.E0), Wr
end

return function(o)
	local piece, ZC = o.piece, o.ZC
	local LAVE, BLANC_CHAUD, FROID = o.LAVE, o.BLANC_CHAUD, o.FROID
	local B = o.poses or {}

	-- ================= Poses du haut du corps (bras droit + buste) =================
	local function lire(nom: string, extra)
		local p = B[nom] or {}
		local d = table.create(7, 0)
		for i, v in p.D or {} do d[i] = v end
		local r = {D = d, tete = {(p.tete or {})[1] or 0, (p.tete or {})[2] or 0}, buste = p.buste or 0, torsion = 0, recul = 0}
		for cle, v in extra or {} do r[cle] = v end
		return r
	end
	local function mix(a, b, w: number)
		local d = table.create(7, 0)
		for i = 1, 7 do d[i] = a.D[i] + (b.D[i] - a.D[i]) * w end
		return {D = d, tete = {lerpN(a.tete[1], b.tete[1], w), lerpN(a.tete[2], b.tete[2], w)}, buste = lerpN(a.buste, b.buste, w),
			torsion = lerpN(a.torsion, b.torsion, w), recul = lerpN(a.recul, b.recul, w)}
	end
	local POSES = {repos = lire("repos"), garde = lire("garde"), souleve = lire("souleve")}
	POSES.leve = lire("leve", {torsion = -0.12, recul = 0.06}) -- poids en arrière, épaule droite qui recule
	POSES.frappe = lire("frappe", {torsion = 0.06, recul = -0.05}) -- buste qui plonge sur le coup
	POSES.rebond = mix(POSES.frappe, POSES.garde, 0.35)
	POSES.leveCourt = mix(POSES.garde, POSES.leve, 0.4)
	POSES.penche = lire("garde", {buste = -0.18, tete = {-0.35, 0}, recul = -0.04})
	POSES.fier = lire("garde", {buste = 0.05, tete = {0.05, 0}, torsion = 0.08})

	-- ================= Déroulés =================
	local function nouveau(duree: number)
		return {cles = {}, impacts = {}, duree = duree, revele = math.huge, apparition = 1, brom = true, objet = true, fk = {{0, "repos"}}}
	end
	local function fk(sc, t: number, nom: string, courbe: string?)
		table.insert(sc.fk, {t, nom, courbe or "douce"})
	end
	-- coup normal : levée lente 0,3 s, frappe 0,08 s, rebond, petit temps ; petit coup : 0,32 s en tout
	local function coup(sc, b: number, cible: string, petit: boolean?)
		if petit then
			fk(sc, b + 0.14, "leveCourt", "sortie"); fk(sc, b + 0.2, "frappe", "entree")
			fk(sc, b + 0.25, "rebond", "sortie"); fk(sc, b + 0.32, "garde")
			table.insert(sc.impacts, {b + 0.2, 0.45, cible})
		else
			fk(sc, b + 0.3, "leve"); fk(sc, b + 0.38, "frappe", "entree")
			fk(sc, b + 0.45, "rebond", "sortie"); fk(sc, b + 0.6, "garde")
			table.insert(sc.impacts, {b + 0.38, 1, cible})
		end
	end
	local function marque(liste)
		local r = {}
		for _, c in liste do table.insert(r, {c[1], c[2], "douce", c[3]}) end
		return r
	end

	-- Plastron : foyer → 5 coups en spirale (poitrine du centre vers les bords) → réchauffe → bigorne (flancs, dos)
	-- → trempe → épaulières rivetées à petits coups → présentation.
	local Plastron = nouveau(9.6)
	fk(Plastron, 0.3, "penche"); fk(Plastron, 0.8, "garde")
	for i, b in {1.5, 2.1, 2.7, 3.3, 3.9} do coup(Plastron, b, "c" .. i) end
	fk(Plastron, 4.75, "penche"); fk(Plastron, 5.3, "garde")
	coup(Plastron, 5.6, "b1"); coup(Plastron, 6.2, "b2")
	fk(Plastron, 7.0, "penche"); fk(Plastron, 7.45, "garde")
	coup(Plastron, 7.9, "e1", true); coup(Plastron, 8.22, "e2", true); coup(Plastron, 8.54, "e3", true)
	fk(Plastron, 9.25, "fier")
	Plastron.piece = marque({
		{0, "feu"}, {0.35, "feu"}, {0.75, "tenue"}, {1.15, "enclumeHaut", true}, {1.45, "enclume"},
		{4.6, "tenue", true}, {4.85, "tenue"}, {5.0, "feu"}, {5.15, "feu"}, {5.33, "tenue"},
		{5.35, "bigorneHaut", true}, {5.55, "bigorne"}, {6.8, "eauHaut", true}, {7.0, "eau"}, {7.3, "eau"}, {7.55, "eauHaut"},
		{7.6, "enclumeHaut", true}, {7.85, "enclume"}, {8.9, "enclume"}, {9.3, "presente"},
	})
	Plastron.racine = marque({
		{0, "foyer"}, {0.75, "foyer"}, {1.15, "foyerTourne"}, {1.15, "enclume", true}, {4.6, "foyerTourne", true}, {4.85, "foyer"},
		{5.35, "bigorne", true}, {6.8, "seau", true}, {7.6, "enclume", true},
	})
	Plastron.chaleur = {{0, 1}, {1.15, 0.95}, {4.6, 0.38}, {5.0, 0.38}, {5.2, 1}, {5.35, 1}, {6.8, 0.6}}
	Plastron.trempe, Plastron.poseEpaulieres = 6.98, 7.6
	Plastron.vues = {{1.15, "foyer"}, {4.6, "enclume"}, {5.35, "foyer"}, {6.8, "bigorne"}, {7.6, "seau"}, {8.9, "rivets"}, {9.6, "final"}}
	Plastron.bigorne = {"b1", "b2"}

	-- Jambières : une jambe puis l'autre (cuissard, genouillère, grève), réchauffe entre les deux, grèves arrondies
	-- sur la bigorne, trempe de la paire, présentation.
	local Jambieres = nouveau(9.6)
	fk(Jambieres, 0.25, "penche"); fk(Jambieres, 0.7, "garde")
	for i, b in {1.45, 2.05, 2.65} do coup(Jambieres, b, "j1" .. i) end
	fk(Jambieres, 3.35, "penche"); fk(Jambieres, 3.9, "garde")
	for i, b in {4.35, 4.95, 5.55} do coup(Jambieres, b, "j2" .. i) end
	coup(Jambieres, 6.4, "r1"); coup(Jambieres, 7.0, "r2")
	fk(Jambieres, 7.8, "penche"); fk(Jambieres, 8.2, "garde"); fk(Jambieres, 9.2, "fier")
	Jambieres.piece = marque({
		{0, "feu"}, {0.3, "feu"}, {0.7, "tenue"}, {1.1, "enclumeHaut", true}, {1.4, "enclume"},
		{3.25, "tenue", true}, {3.5, "tenue"}, {3.62, "feu"}, {3.78, "feu"}, {3.98, "tenue"},
		{4.0, "enclumeHaut", true}, {4.3, "enclume"}, {6.15, "bigorneHaut", true}, {6.35, "bigorne"},
		{7.6, "eauHaut", true}, {7.8, "eau"}, {8.1, "eau"}, {8.38, "eauHaut"},
		{8.4, "enclumeHaut", true}, {8.65, "enclume"}, {8.85, "enclume"}, {9.25, "presente"},
	})
	Jambieres.racine = marque({
		{0, "foyer"}, {0.7, "foyer"}, {1.1, "foyerTourne"}, {1.1, "enclume", true}, {3.25, "foyerTourne", true}, {3.5, "foyer"},
		{4.0, "enclume", true}, {6.15, "bigorne", true}, {7.6, "seau", true}, {8.4, "enclume", true},
	})
	Jambieres.chaleur = {{0, 1}, {1.1, 0.95}, {3.25, 0.4}, {3.55, 0.4}, {3.75, 1}, {4.0, 1}, {6.15, 0.45}, {7.6, 0.4}}
	Jambieres.trempe = 7.78
	Jambieres.vues = {{1.1, "foyer"}, {3.25, "enclume"}, {4.0, "foyer"}, {6.15, "enclume"}, {7.6, "bigorne"}, {8.4, "seau"}, {9.6, "final"}}
	Jambieres.bigorne = {"r1", "r2"}
	Jambieres.enLong = true

	-- ================= Pièce : le vrai modèle =================
	local function construireModele(etat): Model
		local d = etat.donnees or {}
		local ok, c = pcall(Color3.fromHex, d.couleur)
		c = if ok then c else Color3.fromRGB(170, 176, 186)
		local Armures = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("ArmuresVoxels")) :: any
		for _, id in {d.modele, d.type} do
			if type(id) == "string" and Armures.existe(id) then
				local reussi, m = pcall(Armures.construire, id, c)
				if reussi and m then return m end
			end
		end
		return o.construire(d)
	end

	-- classe chaque Part dans le groupe du coup qui la forme
	local function grouperPlastron(a)
		local mn, mx = a.mn, a.mx
		local hw, H = math.max(-mn.X, mx.X), mx.Y - mn.Y
		local ym = (mn.Y + mx.Y) / 2 + 0.08 * H
		local spirale = {}
		for i = 1, 5 do
			local r, ang = (i - 1) / 4 * 0.75 * hw, (i - 1) * 2.4
			spirale[i] = V(r * math.cos(ang), ym + 0.8 * r * math.sin(ang), 0)
		end
		for _, pc in a.pieces do
			local c = pc.c
			if c.Y > mn.Y + 0.72 * H and math.abs(c.X) > 0.45 * hw then
				pc.groupe, pc.epaule = if c.X >= 0 then "e1" else "e2", true
			elseif c.Z > 0.25 * mx.Z or math.abs(c.X) > 0.75 * hw then
				pc.groupe = if c.X >= 0 then "b1" else "b2"
			else
				local meilleur, dm = 1, math.huge
				for i, s in spirale do
					local dd = (V(c.X, c.Y, 0) - s).Magnitude
					if dd < dm then meilleur, dm = i, dd end
				end
				pc.groupe = "c" .. meilleur
			end
		end
		return {e3 = {"e1", "e2"}}
	end
	local function grouperJambieres(a)
		local mn, H = a.mn, a.mx.Y - a.mn.Y
		for _, pc in a.pieces do
			local c = pc.c
			local tiers = if c.Y > mn.Y + 2 * H / 3 then 1 elseif c.Y > mn.Y + H / 3 then 2 else 3
			pc.groupe = "j" .. (if c.X < 0 then 1 else 2) .. tiers
		end
		return {r1 = {"j13"}, r2 = {"j23"}}
	end

	local function preparerPiece(etat, a)
		local modele = construireModele(etat)
		local racine = modele.PrimaryPart or modele:FindFirstChild("Racine")
		local R0 = if racine and racine:IsA("BasePart") then racine.CFrame else modele:GetPivot()
		for _, d in modele:GetDescendants() do
			for _, classe in ATTACHES do
				if d:IsA(classe) then d:Destroy(); break end
			end
		end
		local pieces, effets, volume = {}, {}, 0
		local mn, mx = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
		local hasard = Random.new()
		for _, p in modele:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
				if p.Transparency < 1 then
					local Lm = R0:ToObjectSpace(p.CFrame)
					local h, x, y, z = p.Size / 2, Lm.XVector, Lm.YVector, Lm.ZVector
					local hx = V(math.abs(x.X) * h.X + math.abs(y.X) * h.Y + math.abs(z.X) * h.Z,
						math.abs(x.Y) * h.X + math.abs(y.Y) * h.Y + math.abs(z.Y) * h.Z,
						math.abs(x.Z) * h.X + math.abs(y.Z) * h.Y + math.abs(z.Z) * h.Z)
					table.insert(pieces, {p = p, Lm = Lm, taille = p.Size, couleur = p.Color, mat = p.Material, transp = p.Transparency,
						c = Lm.Position, hx = hx, vol = math.max(p.Size.X * p.Size.Y * p.Size.Z, 1e-3), delai = hasard:NextNumber(0, 0.35)})
					mn, mx = mn:Min(Lm.Position - hx), mx:Max(Lm.Position + hx)
					p.Transparency = 1
				end
			elseif p:IsA("Light") or p:IsA("ParticleEmitter") then
				table.insert(effets, {p, p.Enabled})
				p.Enabled = false
			end
		end
		if #pieces == 0 then error("pièce forgée vide") end
		a.pieces, a.effets, a.mn, a.mx = pieces, effets, mn, mx
		local unions = (if a.sc.enLong then grouperJambieres else grouperPlastron)(a)
		a.groupes = {}
		for _, pc in pieces do
			a.groupes[pc.groupe] = a.groupes[pc.groupe] or {}
			table.insert(a.groupes[pc.groupe], pc)
			if pc.epaule then pc.tf, pc.pop = a.sc.poseEpaulieres, -10 else volume += pc.vol end
		end
		for nom, liste in unions do
			local g = {}
			for _, n in liste do for _, pc in a.groupes[n] or {} do table.insert(g, pc) end end
			a.groupes[nom] = g
		end
		a.volume = math.max(volume, 1e-3)
		-- prise des tenailles : bord du haut (col du plastron, ceinture des jambières)
		local prise, haut = nil, -math.huge
		local hw = math.max(-mn.X, mx.X)
		for _, pc in pieces do
			local top = pc.c.Y + pc.hx.Y
			if (a.sc.enLong or math.abs(pc.c.X) < 0.3 * hw) and top > haut then prise, haut = pc, top end
		end
		prise = prise or pieces[1]
		a.g = V(prise.c.X, prise.c.Y + prise.hx.Y - 0.06, prise.c.Z)
		a.largeur = mx.X - mn.X
		modele.Parent = etat.dossier
	end

	-- ================= Brom : squelette local (repère du poste) =================
	local function preparerRig(etat, a)
		local b = etat.brom
		local P0 = b.pied
		local r = {piv = {}, T = {Corps = CFrame.identity}, parts = {}}
		for g, pos in b.pivots do r.piv[g] = P0:PointToObjectSpace(pos) end
		local dans = {}
		for g, liste in b.groupes do
			for _, pc in liste do
				dans[pc[1]] = true
				table.insert(r.parts, {pc[1], g, P0:ToObjectSpace(pc[2])})
			end
		end
		for _, p in b.clone:GetDescendants() do
			if p:IsA("BasePart") and not dans[p] then table.insert(r.parts, {p, "Corps", P0:ToObjectSpace(p.CFrame)}) end
		end
		local function cote(s: string)
			local S0, E0, W0 = r.piv["Bras" .. s], r.piv["AvBras" .. s], r.piv["Main" .. s]
			local a0, b0 = (E0 - S0).Unit, (W0 - E0).Unit
			return {S0 = S0, E0 = E0, W0 = W0, l1 = (E0 - S0).Magnitude, l2 = (W0 - E0).Magnitude,
				R1inv = repere(a0, orth(X, a0) or Z):Inverse(), R2inv = repere(b0, orth(X, b0) or Z):Inverse()}
		end
		r.D, r.G = cote("D"), cote("G")
		r.k = r.D.l1 / 0.889
		-- panne du marteau (main droite) et prise de la main gauche (miroir du manche)
		local tete, manche = nil, nil
		for _, pc in b.groupes.MainD do
			local n = pc[1].Name
			if string.find(n, "_Acier$") then tete = pc
			elseif not tete and string.find(n, "_Metal$") then tete = pc end
			if string.find(n, "_Bois$") then manche = pc end
		end
		local faces
		if tete then
			local s, cf = tete[1].Size, tete[2]
			local axe = if s.X >= s.Y and s.X >= s.Z then cf.XVector elseif s.Y >= s.Z then cf.YVector else cf.ZVector
			local c, ax = P0:PointToObjectSpace(cf.Position), P0:VectorToObjectSpace(axe)
			local demi = math.max(s.X, s.Y, s.Z) / 2
			faces = {c + ax * demi, c - ax * demi}
		else
			faces = {r.D.W0 - Y * r.k}
		end
		r.T.Buste = CFrame.identity
		local _, _, _, Tm = a.fkCorps(r, POSES.frappe, 0)
		r.face = faces[1]
		for _, f in faces do
			if (Tm * f).Y < (Tm * r.face).Y then r.face = f end
		end
		r.Pfrappe = Tm * r.face
		local cm = if manche then P0:PointToObjectSpace(manche[2].Position) else r.D.W0
		local G0 = V(-cm.X, r.piv.MainD.Y - 0.3 * r.k, cm.Z)
		r.Rt0inv = CFrame.fromMatrix(G0, X, -Z, Y):Inverse()
		a.rig = r
	end

	local function fkCorps(r, p, souffle: number)
		local pv, T = r.piv, r.T
		local Tb = C(0, souffle, p.recul) * autour(pv.Buste, CFrame.Angles(0, p.torsion, 0) * CFrame.Angles(p.buste, 0, 0))
		T.Buste = Tb
		T.Tete = Tb * autour(pv.Tete, CFrame.Angles(0, p.tete[2], 0) * CFrame.Angles(p.tete[1], 0, 0))
		local d = p.D
		local Tbr = Tb * autour(pv.BrasD, CFrame.Angles(0, 0, d[3]) * CFrame.Angles(0, d[2], 0) * CFrame.Angles(d[1], 0, 0))
		local Tav = Tbr * autour(pv.AvBrasD, CFrame.Angles(d[4], 0, 0) * CFrame.Angles(0, d[5], 0))
		return Tb, Tbr, Tav, Tav * autour(pv.MainD, CFrame.Angles(d[6], 0, 0) * CFrame.Angles(0, 0, d[7]))
	end

	-- ================= Décor : postes, poses de la pièce, seau, tenailles, caméras =================
	local function seauPose(etat, cote: number): BasePart
		local F = etat.F
		local xs, zs = 2.7 * cote, 0.7
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {etat.dossier, Players.LocalPlayer.Character :: Instance}
		local r = workspace:Raycast(F * V(xs, 0.3, zs), V(0, -8, 0), params)
		local sol = if r then math.clamp(F:PointToObjectSpace(r.Position).Y, -5, -1.6) else -4.2
		local haut = math.min(sol + 2, -0.9)
		local h = haut - sol
		local vertical = CFrame.Angles(0, 0, PI / 2)
		for _, pr in {{V(0.12, 1.9, 1.9), sol + 0.06, BOIS}, {V(0.14, 2, 2), sol + h * 0.2, FER}, {V(0.14, 2, 2), haut - 0.15, FER}} do
			piece(etat.dossier, pr[1], F * C(xs, pr[2], zs) * vertical, pr[3], Enum.Material.Metal, "Seau").Shape = Enum.PartType.Cylinder
		end
		for i = 0, 11 do -- douelles : seau creux, la pièce reste visible sous l'eau
			local ang = i / 12 * 2 * PI
			piece(etat.dossier, V(0.5, h, 0.1), F * C(xs + math.cos(ang) * 0.92, sol + h / 2, zs + math.sin(ang) * 0.92) * CFrame.Angles(0, -ang + PI / 2, 0),
				BOIS, Enum.Material.WoodPlanks, "Douelle")
		end
		local eau = piece(etat.dossier, V(0.05, 1.8, 1.8), F * C(xs, haut - 0.2, zs) * vertical, EAU, Enum.Material.Glass, "Eau")
		eau.Shape = Enum.PartType.Cylinder
		eau.Transparency = 0.4
		return eau
	end

	local function preparerDecor(etat, a)
		local F, b, r = etat.F, etat.brom, a.rig
		local k = r.k
		local forge = etat.enclume and etat.enclume.Parent
		local Pe = b.pied
		local function poste(pos: Vector3, regard: Vector3): CFrame
			regard = V(regard.X, 0, regard.Z)
			regard = if regard.Magnitude > 1e-3 then regard.Unit else -Pe.LookVector
			local p = V(pos.X, b.sol, pos.Z)
			return CFrame.lookAt(p, p + regard)
		end
		local postes = {enclume = Pe}
		local poses = {}
		local function aPlat(surf: CFrame): CFrame return surf * C(0, a.mx.Z, 0) * COUCHE end
		local function leve(cf: CFrame): CFrame return C(0, 0.55, 0) * cf * CFrame.Angles(0.15, 0, 0) end

		-- enclume
		local rotE = if a.sc.enLong then CFrame.Angles(0, -PI / 2, 0) else CFrame.identity
		poses.enclume = aPlat(F * C(0, 0, 0.1) * rotE)
		poses.enclumeHaut = leve(poses.enclume)

		-- bigorne réelle (sinon le bout de la table)
		local big = forge and forge:FindFirstChild("Bigorne")
		local bp = F * V(1.2, 0, ZC)
		if big and big:IsA("BasePart") then
			local cb = F:PointToObjectSpace(big.Position)
			local x = cb.X - math.sign(cb.X) * 0.25
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {big}
			local hit = workspace:Raycast(F * V(x, 3, cb.Z), F:VectorToWorldSpace(V(0, -6, 0)), params)
			bp = if hit then hit.Position else F * V(x, 0, cb.Z)
		end
		local cg, nb = Vector3.zero, 0
		for _, nom in a.sc.bigorne do
			for _, pc in a.groupes[nom] or {} do cg += pc.c; nb += 1 end
		end
		cg = if nb > 0 then cg / nb else Vector3.zero
		local b0 = aPlat(CFrame.new(bp) * F.Rotation)
		local ecart = bp - b0 * cg
		poses.bigorne = C(ecart.X, 0, ecart.Z) * b0
		poses.bigorneHaut = leve(poses.bigorne)
		local decal = (bp - F * V(0, 0, ZC)) * V(1, 0, 1)
		postes.bigorne = Pe + decal
		local estrade = etat.dossier:FindFirstChild("Estrade")
		if estrade and estrade:IsA("BasePart") then
			local l = estrade.CFrame:VectorToObjectSpace(decal)
			estrade.Size += V(math.abs(l.X), 0, math.abs(l.Z))
			estrade.CFrame *= C(l.X / 2, 0, l.Z / 2)
		end

		-- fourneau réel : la pièce dans les braises, grip à la gueule
		local fourneau = forge and forge:FindFirstChild("Fourneau")
		local base = fourneau and (fourneau:GetAttribute("Base") or fourneau:GetPivot())
		if typeof(base) == "CFrame" then
			postes.foyer = poste(base * V(-0.8, 0, -4.4), base.ZVector)
			local versE = (F.Position - postes.foyer.Position) * V(1, 0, 1)
			postes.foyerTourne = poste(postes.foyer.Position, base.ZVector:Lerp(if versE.Magnitude > 0.01 then versE.Unit else base.ZVector, 0.75))
			local f0 = aPlat(CFrame.new(base * V(0, 2.0, -1.0)) * base.Rotation)
			local zb = base:PointToObjectSpace(f0 * a.g).Z
			poses.feu = C(base.ZVector * (-2.3 - zb)) * f0
		else
			postes.foyer, postes.foyerTourne, poses.feu = Pe, Pe, poses.enclumeHaut
		end
		poses.tenue = {loc = aPlat(C(-0.45 * k, 1.9 * k, -1.5 * k) * CFrame.Angles(0, PI, 0) * CFrame.Angles(-0.25, 0, 0))}

		-- seau de trempe réel (sinon posé dès le début à côté de l'enclume)
		local seau = forge and forge:FindFirstChild("Forge_SeauEau")
		local eau = seau and seau:FindFirstChild("Eau")
		if not (eau and eau:IsA("BasePart")) then
			local cote = if big and big:IsA("BasePart") and F:PointToObjectSpace(big.Position).X > 0 then -1 else 1
			eau = seauPose(etat, cote)
		end
		local wp = (eau :: BasePart).Position
		local vers = (F.Position - wp) * V(1, 0, 1)
		vers = if vers.Magnitude > 0.01 then vers.Unit else X
		local droite = (-vers):Cross(Y)
		postes.seau = poste(wp + vers * 2.3 + droite * 0.7, -vers)
		local Rh = CFrame.lookAt(Vector3.zero, vers)
		local pend = a.g.Y - a.mn.Y
		poses.eau = C(V(wp.X, math.max(wp.Y - 0.08, wp.Y - 1.75 + pend), wp.Z)) * Rh * C(-a.g)
		poses.eauHaut = C(V(wp.X, wp.Y + 0.3 + pend, wp.Z)) * Rh * C(-a.g)
		a.eau = wp

		poses.presente = C(F * V(0.1, 2.2, ZC)) * F.Rotation * CFrame.Angles(0, PI, 0) * C(-a.g)
		a.postes, a.poses = postes, poses

		-- tenailles (repère : mors à l'origine, +Z vers la main)
		local Lt = 1.3 * k
		a.Lt = Lt
		a.tenailles = {}
		local function bout(nom: string, taille: Vector3, cf: CFrame, cyl: boolean?)
			local p = piece(etat.dossier, taille, CFrame.identity, FER, Enum.Material.Metal, nom)
			if cyl then p.Shape = Enum.PartType.Cylinder end
			table.insert(a.tenailles, {p, cf})
		end
		for _, s in {-1, 1} do
			bout("Mors", V(0.16, 0.06, 0.32), C(0, s * 0.07, 0.14))
			bout("Branche", V(0.08, 0.08, Lt - 0.3), C(0, s * 0.055, (Lt + 0.3) / 2))
		end
		bout("Axe", V(0.22, 0.13, 0.13), C(0, 0, 0.32), true)

		-- caméras
		local pf, ps = postes.foyer, postes.seau
		local qb = F:PointToObjectSpace(bp)
		local sq = if qb.X >= 0 then 1 else -1
		-- RECUL : la caméra est reculée sur la ligne œil → cible (1 = plans d'origine, plus grand = plus loin)
		local RECUL = 1.6
		local function vue(oeil: Vector3, cible: Vector3): CFrame
			return CFrame.lookAt(cible + (oeil - cible) * RECUL, cible)
		end
		local VUES = {
			foyer = function(e, u) return vue(pf * V(-4.6 + 0.4 * u, 3.7, -0.9), pf * V(-0.6, 2.3, -2)) end,
			enclume = function(e, u) return vue(F * V(1.9 - 0.3 * u, 2.4 - 0.2 * u, 3.8 - 0.3 * u), F * V(0, 0.25, ZC)) * e.secousseCF end,
			rivets = function(e, u) return vue(F * V(-1.7 + 0.2 * u, 2.0, 3.2), F * V(0, 0.3, ZC + 0.2)) * e.secousseCF end,
			bigorne = function(e, u) return vue(F * V(qb.X + 1.2 * sq, 2.0, 3.3 - 0.2 * u), F * V(qb.X, 0.15, ZC)) * e.secousseCF end,
			seau = function(e, u) return vue(ps * V(-3.6 + 0.3 * u, 3.4, -2.6), ps * V(-0.4, 2.0, -1.6)) end,
			final = function(e, u) return vue(F * V(-0.8 + 0.6 * u, 2.6, 6.2 - 0.5 * u), F * V(0, 1.4, -0.3)) end,
		}
		etat.plans = {}
		for i, v in a.sc.vues do
			table.insert(etat.plans, {fin = v[1], fov = if v[2] == "foyer" or v[2] == "seau" or v[2] == "final" then 50 else 46,
				camera = VUES[v[2]], fondu = if i == #a.sc.vues then 0.4 else nil})
		end
	end

	-- ================= Animation =================
	local function incandescent(h: number, eclat: number): Color3
		local c = FROID:Lerp(LAVE, math.clamp(h * 1.5, 0, 1))
		return c:Lerp(BLANC_CHAUD, math.clamp(math.clamp((h - 0.65) / 0.35, 0, 1) * 0.75 + eclat * 0.5, 0, 1))
	end

	-- point de la surface réellement frappée (dessus des Parts formées autour du groupe visé)
	local function contact(a, Pr: CFrame, nom: string): Vector3
		local g = a.groupes[nom] or {}
		local up = Pr:VectorToObjectSpace(Y)
		local cm = Vector3.zero
		for _, pc in g do cm += pc.c end
		cm = if #g > 0 then cm / #g else V(0, (a.mn.Y + a.mx.Y) / 2, 0)
		local haut = -math.huge
		local function tester(c: Vector3, hx: Vector3)
			local d = c - cm
			if (d - up * d:Dot(up)).Magnitude < 0.38 then
				haut = math.max(haut, c:Dot(up) + math.abs(hx.X * up.X) + math.abs(hx.Y * up.Y) + math.abs(hx.Z * up.Z))
			end
		end
		for _, pc in g do tester(pc.c, pc.hx) end
		for _, pc in a.pieces do
			if pc.vis then tester(pc.c, pc.hx) end
		end
		if haut == -math.huge then haut = cm:Dot(up) + 0.2 end
		return Pr * (cm - up * cm:Dot(up) + up * haut)
	end

	local function impact(etat, coupInfo)
		local a = etat.armure
		local t = os.clock() - etat.debut
		for _, pc in a.groupes[coupInfo[3]] or {} do
			if not (pc.tf and t >= pc.tf) then pc.tf = t end
			pc.pop = t
		end
		etat.gerbe:Emit(6)
	end

	local function maj(etat, t: number, dt: number)
		local a = etat.armure
		local sc, r, F = a.sc, a.rig, etat.F
		local k = r.k
		local P, cleP = cleA(sc.racine, t, function(n) return a.postes[n] end, lerpCF)
		local coupe = cleP ~= a.cleP and cleP[4]
		a.cleP = cleP
		local pose = cleA(sc.fk, t, function(n) return POSES[n] end, mix)
		local Pr = cleA(sc.piece, t, function(n)
			local v = a.poses[n]
			return if typeof(v) == "CFrame" then v else P * v.loc
		end, lerpCF)
		local h = cleA(sc.chaleur, t, brut, lerpN) + (if t < 0.4 then 0.05 * math.sin(t * 20) else 0)
		local tq = sc.trempe
		local flash = math.min(etat.flash, 1)

		-- Parts du modèle : formées (pop), incandescentes, puis couleurs d'origine après la trempe
		local reste, centre = 0, Vector3.zero
		for _, pc in a.pieces do
			local tf = pc.tf
			if tf and t >= tf then
				local p = pc.p
				if not pc.vis then pc.vis = true; p.Transparency = pc.transp end
				local u = (t - pc.pop) / 0.2
				p.Size = pc.taille * (if u < 1 then 0.6 + 0.4 * COURBES.sortie(u) + 0.14 * math.sin(PI * u) else 1)
				p.CFrame = Pr * pc.Lm
				local eclat = math.max(0, 1 - (t - pc.pop) / 0.35)
				local froid = if pc.epaule then 1 - 0.7 * eclat elseif t >= tq then lisse((t - tq - pc.delai) / 0.55) else 0
				p.Color = incandescent(h, math.max(flash * 0.4, eclat)):Lerp(pc.couleur, froid)
				p.Material = if froid > 0.6 then pc.mat else Enum.Material.Neon
			elseif not pc.epaule then
				reste += pc.vol
				centre += pc.c * pc.vol
			end
		end

		-- lingot brut : relie la prise aux Parts pas encore formées, fond à mesure
		local lingot = etat.lingot
		local f = reste / a.volume
		if f > 0.005 then
			centre /= reste
			local s = etat.ecrase
			local ep = (0.08 + 0.3 * math.sqrt(f)) * (1 - 0.3 * s)
			local la = (0.12 + 0.45 * a.largeur * math.sqrt(f)) * (1 + 0.12 * s)
			local z = a.mx.Z - ep / 2
			local g0, c0 = V(a.g.X, a.g.Y, z), V(centre.X, centre.Y, z)
			local milieu = (g0 + c0) / 2
			lingot.Size = V(la, ep, (c0 - g0).Magnitude + 0.3)
			lingot.CFrame = Pr * (if (c0 - g0).Magnitude > 0.05 then CFrame.lookAt(milieu, c0, Z) else C(milieu))
			lingot.Color = incandescent(h, flash)
			lingot.Transparency = 0
		else
			lingot.Transparency = 1
			lingot.CFrame = Pr
		end

		-- prochain coup : la panne doit tomber sur la surface réelle
		local prochain = sc.impacts[etat.coup + 1]
		local cible = if prochain and prochain[1] - t < 0.75 then contact(a, Pr, prochain[3]) else nil
		local dCible = if cible then P:PointToObjectSpace(cible) - r.Pfrappe else Vector3.zero
		if dCible.Magnitude > 1.5 then dCible = dCible.Unit * 1.5 end
		a.delta = if coupe or not a.delta then dCible else a.delta + (dCible - a.delta) * (1 - math.exp(-dt * 16))

		-- bras droit : poses + correction IK ; bras gauche : IK vers la poignée des tenailles
		local T = r.T
		local Tb, Tbr, _, Tm = fkCorps(r, pose, math.sin(t * 1.6) * 0.03)
		local D = r.D
		local Tmain = C(a.delta) * Tm
		local W = Tmain * D.W0
		local Tbras, Tav, Wr = ik(D, Tb * D.S0, W, Tbr * D.E0 + a.delta * 0.5, Tbr:VectorToWorldSpace(X))
		T.BrasD, T.AvBrasD, T.MainD = Tbras, Tav, C(Wr - W) * Tmain

		local G = r.G
		local SL = Tb * G.S0
		local J = P:PointToObjectSpace(Pr * a.g)
		local u = ((SL + V(-0.25, -0.9, 0.3) * k) - J).Unit
		local d0 = J - SL
		local ud, portee = u:Dot(d0), (G.l1 + G.l2) * 0.985
		local disc = ud * ud - d0:Dot(d0) + portee * portee
		local s = if disc >= 0 then math.clamp(a.Lt * 0.85, -ud - math.sqrt(disc), -ud + math.sqrt(disc)) else -ud
		s = math.clamp(s, a.Lt * 0.55, a.Lt * 1.05)
		local yv = orth(P:VectorToObjectSpace(Pr.ZVector), u) or orth(-Z, u) or Z
		local xv = yv:Cross(u)
		if xv.X < 0 then yv, xv = -yv, -xv end
		local Rt = CFrame.fromMatrix(Vector3.zero, xv, yv, u)
		local Tg = C(J + u * s) * Rt * r.Rt0inv
		local WL = Tg * G.W0
		local TbrasG, TavG, WrG = ik(G, SL, WL, SL + V(-0.7, -0.9, 0.6) * k, X)
		T.BrasG, T.AvBrasG, T.MainG = TbrasG, TavG, C(WrG - WL) * Tg
		local Tt = P * C(J) * Rt
		for _, tp in a.tenailles do tp[1].CFrame = Tt * tp[2] end
		for _, rp in r.parts do rp[1].CFrame = P * T[rp[2]] * rp[3] end

		-- étincelles au point frappé, vapeur à la surface de l'eau, lueur qui suit la chaleur
		local dansEau = t >= tq - 0.1 and t < tq + 0.6
		local monde = if dansEau then a.eau + V(0, 0.1, 0) elseif cible then cible else Pr.Position
		etat.point.CFrame = lingot.CFrame:ToObjectSpace(CFrame.new(monde))
		if t >= tq and not a.trempe then
			a.trempe = true
			etat.vapeur:Emit(30)
			etat.vapeur.Rate = 25
			etat.sonTrempe:Play()
			etat.braises.Enabled = false
		end
		if a.trempe and t > tq + 0.5 then etat.vapeur.Rate = 0 end
		if t > tq + 0.9 and not a.effetsRendus then
			a.effetsRendus = true
			for _, e in a.effets do e[1].Enabled = e[2] end
		end
		etat.lumiere.Brightness = (0.8 + 4 * h + 4 * flash) * (1 - (if t >= tq then lisse((t - tq) / 0.6) else 0))
	end

	for _, sc in {Plastron, Jambieres} do
		sc.impact = impact
		sc.maj = maj
		function sc.preparer(etat)
			local a = {sc = sc, fkCorps = fkCorps}
			etat.armure = a
			if etat.dome then etat.dome:Destroy(); etat.dome = nil end
			preparerPiece(etat, a)
			preparerRig(etat, a)
			preparerDecor(etat, a)
		end
		sc.plans = {{fin = sc.duree, fov = 46, camera = function(e) return e.camera.CFrame end}}
	end
	return {Plastron = Plastron, Jambieres = Jambieres}
end
