-- Outils communs aux arènes des boss (ServerStorage › Monde › AreneKit), utilisés par AreneCristal et AreneNid.
-- Repères polaires autour du centre c : a = 0 au nord (-Z), sens horaire vu de dessus.
--	local k = Kit.nouveau(m, c, rng)
--	k.tangent(a, r, y) : X tangent, +Z vers le centre · k.face(a, r, y) : -Z vers le centre
-- Toutes les pièces « deco » sont sans collision et ignorées des rayons (O.decor) : seul le sol est solide.
local O = require(script.Parent.Outils)
local M = O.M

local Kit = {}
Kit.DEUX_PI = 2 * math.pi

function Kit.nouveau(m: Model, c: Vector3, rng: Random)
	local DEUX_PI = Kit.DEUX_PI
	local k = {}

	function k.polaire(a: number, r: number, y: number?): CFrame
		return CFrame.new(c.X + math.sin(a) * r, c.Y + (y or 0), c.Z - math.cos(a) * r)
	end
	function k.tangent(a: number, r: number, y: number?): CFrame
		return k.polaire(a, r, y) * CFrame.Angles(0, -a, 0)
	end
	function k.face(a: number, r: number, y: number?): CFrame
		return k.polaire(a, r, y) * CFrame.Angles(0, math.pi - a, 0)
	end

	-- Pièce solide (sol, gros volumes hors du cercle)
	function k.solide(taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string?): BasePart
		return O.bloc(m, taille, cf, couleur, mat, nom)
	end
	-- Pièce décorative : sans collision, ignorée des rayons, sans ombre
	function k.deco(taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string?): BasePart
		local p = O.decor(O.bloc(m, taille, cf, couleur, mat, nom))
		p.CastShadow = false
		return p
	end
	function k.cyl(h: number, d: number, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string?): BasePart
		local p = O.decor(O.cylindre(m, h, d, cf, couleur, mat, nom))
		p.CastShadow = false
		return p
	end
	function k.boule(taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string?): BasePart
		local p = O.decor(O.ellipsoide(m, taille, cf, couleur, mat, nom))
		p.CastShadow = false
		return p
	end
	function k.invisible(taille: Vector3, cf: CFrame, nom: string?): BasePart
		local p = k.deco(taille, cf, Color3.new(), M.Lisse, nom)
		p.Transparency = 1
		return p
	end
	-- Lueur animée côté client (AmbianceArene) : « RuneArene » respire, « EchoArene » = onde depuis le centre
	function k.lueur(p: BasePart, transparence: number?, tag: string?): BasePart
		p.Transparency = transparence or 0.3
		O.tag(p, tag or "RuneArene")
		return p
	end
	function k.lumiere(cf: CFrame, couleur: Color3, luminosite: number, portee: number): BasePart
		local p = k.invisible(Vector3.one, cf, "Lumiere")
		O.lumiere(p, couleur, luminosite, portee)
		return p
	end

	-- Incrustation dans le sol : dessus à +0.04 (sous les télégraphes du boss, posés à +0.08)
	function k.incruster(sx: number, sz: number, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string?, epaisseur: number?): BasePart
		local e = epaisseur or 0.1
		return k.deco(Vector3.new(sx, e, sz), cf * CFrame.new(0, 0.04 - e / 2, 0), couleur, mat, nom)
	end
	function k.cercle(r: number, largeur: number, n: number, couleur: Color3, mat: Enum.Material, nom: string?, epaisseur: number?): {BasePart}
		local longueur = DEUX_PI * r / n * 1.02
		local parts = {}
		for i = 0, n - 1 do
			table.insert(parts, k.incruster(longueur, largeur, k.tangent((i + 0.5) / n * DEUX_PI, r), couleur, mat, nom, epaisseur))
		end
		return parts
	end

	-- Brin droit entre deux points (fil de toile, veine, poutre fine, chaîne simple)
	function k.fil(p0: Vector3, p1: Vector3, epais: number, couleur: Color3, mat: Enum.Material, nom: string?): BasePart?
		local d = p1 - p0
		local l = d.Magnitude
		if l < 0.05 then
			return nil
		end
		local haut = if math.abs(d.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
		return k.deco(Vector3.new(epais, epais, l + epais * 0.5), CFrame.lookAt((p0 + p1) / 2, p1, haut), couleur, mat, nom)
	end
	function k.chaine(p0: Vector3, p1: Vector3, maillon: number, epais: number, couleur: Color3)
		local u = (p1 - p0).Unit
		local haut = if math.abs(u.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
		for i = 0, math.floor((p1 - p0).Magnitude / maillon) - 1 do
			local centre = p0 + u * (maillon * (i + 0.5))
			local cf = CFrame.lookAt(centre, centre + u, haut) * CFrame.Angles(0, 0, if i % 2 == 0 then 0 else math.pi / 2)
			for _, s in {-1, 1} do
				k.deco(Vector3.new(epais, epais, maillon * 1.12), cf * CFrame.new(s * maillon * 0.2, 0, 0), couleur, M.Metal, "Chaine")
			end
		end
	end

	-- Fil qui ploie (chaînette approchée en segments droits) : « fleche » = creux au milieu
	function k.filCourbe(p0: Vector3, p1: Vector3, fleche: number, segments: number, epais: number, couleur: Color3, transparence: number?, nom: string?): {BasePart}
		local parts = {}
		local prec = p0
		for i = 1, segments do
			local t = i / segments
			local q = p0:Lerp(p1, t) - Vector3.new(0, fleche * 4 * t * (1 - t), 0)
			local p = k.fil(prec, q, epais, couleur, M.Lisse, nom or "Toile")
			if p then
				p.Transparency = transparence or 0
				table.insert(parts, p)
			end
			prec = q
		end
		return parts
	end

	-- Toile en VRAIS fils 3D : rayons du moyeu vers des ancrages réels (étais, poutres, sol, voûte), pas forcément
	-- dans un même plan, puis une spirale continue qui saute d'un rayon au suivant. Les ancrages sont donnés dans
	-- l'ordre du tour ; si le moyeu est enfoncé derrière eux, on obtient un entonnoir. ouverte : pas de fil entre le
	-- dernier et le premier rayon (toile déchirée).
	function k.toile3D(centre: Vector3, ancres: {Vector3}, nTours: number, couleur: Color3, transparence: number, epais: number?, ouverte: boolean?): {BasePart}
		local e = epais or 0.18
		local parts = {}
		local n = #ancres
		for _, a in ancres do
			local p = k.fil(centre, a, e, couleur, M.Lisse, "Toile")
			if p then table.insert(parts, p) end
		end
		local pas = if ouverte then n - 1 else n
		local total = nTours * n
		local f0, f1 = 0.1, 0.9
		local function frac(s: number): number
			return f0 + (f1 - f0) * s / total
		end
		for s = 0, total - 1 do
			local i = s % n + 1
			if i <= pas and rng:NextNumber() > 0.06 then -- quelques fils cassés
				local j = i % n + 1
				local p = k.fil(centre:Lerp(ancres[i], frac(s)), centre:Lerp(ancres[j], frac(s + 1)), e * 0.8, couleur, M.Lisse, "Toile")
				if p then table.insert(parts, p) end
			end
		end
		for _, p in parts do
			p.Transparency = transparence
		end
		return parts
	end

	-- Nappe de soie (toile en hamac) entre quatre coins : grille de fils qui ploient
	function k.nappe(p00: Vector3, p10: Vector3, p01: Vector3, p11: Vector3, n: number, fleche: number, couleur: Color3, transparence: number, epais: number?)
		local e = epais or 0.16
		for i = 0, n do
			local t = math.clamp(i / n + rng:NextNumber(-0.05, 0.05), 0, 1)
			k.filCourbe(p00:Lerp(p10, t), p01:Lerp(p11, t), fleche, 2, e, couleur, transparence)
			k.filCourbe(p00:Lerp(p01, t), p10:Lerp(p11, t), fleche, 2, e, couleur, transparence)
		end
	end

	-- Repère dont +Y suit la direction d (pour faire pousser un cristal ou une pointe le long de d)
	function k.dirige(base: Vector3, d: Vector3): CFrame
		local u = d.Unit
		local haut = if math.abs(u.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
		return CFrame.lookAt(base, base + u, haut) * CFrame.Angles(-math.pi / 2, 0, 0)
	end

	-- Pointe de cristal légère (2 pièces) : pied à cf, pousse le long de +Y
	function k.pointe(cf: CFrame, L: number, w: number, couleur: Color3, transp: number?): {BasePart}
		local a = k.deco(Vector3.new(w, L * 0.72, w), cf * CFrame.new(0, L * 0.36, 0) * CFrame.Angles(0, math.pi / 4, 0), couleur, M.Verre, "Cristal")
		local b = k.deco(Vector3.new(w * 0.5, L * 0.34, w * 0.5), cf * CFrame.new(0, L * 0.84, 0), couleur, M.Verre, "Cristal")
		a.Transparency, b.Transparency = transp or 0.18, transp or 0.18
		return {a, b}
	end
	-- Amas de pointes serrées plantées autour de pos, qui poussent en moyenne selon d (paroi, voûte, sol)
	function k.amas(pos: Vector3, d: Vector3, echelle: number, nombre: number, couleurs: {Color3}, ecart: number?)
		local u = d.Unit
		local t1 = u:Cross(if math.abs(u.Y) > 0.9 then Vector3.xAxis else Vector3.yAxis).Unit
		local t2 = u:Cross(t1)
		for i = 1, nombre do
			local base = pos + (t1 * rng:NextNumber(-1, 1) + t2 * rng:NextNumber(-1, 1)) * echelle * (ecart or 1.2) - u * echelle * 0.4
			local dir = u + t1 * rng:NextNumber(-0.55, 0.55) + t2 * rng:NextNumber(-0.55, 0.55)
			local L = rng:NextNumber(2.2, 5) * echelle * (if i == 1 then 1.5 else 1)
			k.pointe(k.dirige(base, dir), L, L * rng:NextNumber(0.22, 0.32), couleurs[rng:NextInteger(1, #couleurs)])
		end
	end

	-- Toile d'araignée dans le plan XY local de cf (normale = Z) : rayons irréguliers + tours en spirale.
	-- Retourne les pièces (pour les teinter / taguer).
	function k.toile(cf: CFrame, rayon: number, nRayons: number, nTours: number, couleur: Color3, transparence: number, epais: number?): {BasePart}
		local e = epais or 0.22
		local parts = {}
		local angles, longueurs = {}, {}
		for i = 1, nRayons do
			angles[i] = (i - 1 + rng:NextNumber(-0.22, 0.22)) / nRayons * DEUX_PI
			longueurs[i] = rayon * rng:NextNumber(0.82, 1.08)
		end
		local function point(i: number, r: number): Vector3
			local a = angles[(i - 1) % nRayons + 1]
			return cf:PointToWorldSpace(Vector3.new(math.cos(a) * r, math.sin(a) * r, 0))
		end
		local centre = cf.Position
		for i = 1, nRayons do
			local p = k.fil(centre, point(i, longueurs[i]), e, couleur, M.Lisse, "Toile")
			if p then table.insert(parts, p) end
		end
		for t = 1, nTours do
			local f = (t - 0.25 + rng:NextNumber(-0.1, 0.1)) / (nTours + 0.2)
			for i = 1, nRayons do
				if rng:NextNumber() > 0.08 then -- quelques fils cassés
					local j = i % nRayons + 1
					local p = k.fil(point(i, longueurs[i] * f), point(j, longueurs[j] * f), e * 0.85, couleur, M.Lisse, "Toile")
					if p then table.insert(parts, p) end
				end
			end
		end
		for _, p in parts do
			p.Transparency = transparence
		end
		return parts
	end

	-- Cristal prismatique : pied à cf, pousse le long de +Y de cf (deux fûts croisés + pointe en escalier).
	-- opts : coeur (lueur intérieure), transp, mat, tag (tag de la lueur)
	function k.cristal(cf: CFrame, L: number, w: number, couleur: Color3, opts: {[string]: any}?): {BasePart}
		local o = opts or {}
		local mat = o.mat or M.Verre
		local transp = o.transp or 0.2
		local corps = L * 0.7
		local parts = {}
		for _, rot in {0, math.pi / 4} do
			local p = k.deco(Vector3.new(w, corps, w), cf * CFrame.new(0, corps / 2, 0) * CFrame.Angles(0, rot, 0), couleur, mat, "Cristal")
			p.Transparency = transp
			table.insert(parts, p)
		end
		local p1 = k.deco(Vector3.new(w * 0.66, L * 0.2, w * 0.66), cf * CFrame.new(0, corps + L * 0.08, 0) * CFrame.Angles(0, math.pi / 8, 0), couleur, mat, "Cristal")
		local p2 = k.deco(Vector3.new(w * 0.3, L * 0.16, w * 0.3), cf * CFrame.new(0, corps + L * 0.22, 0) * CFrame.Angles(0, math.pi / 3, 0), couleur, mat, "Cristal")
		p1.Transparency, p2.Transparency = transp, transp
		table.insert(parts, p1)
		table.insert(parts, p2)
		if o.coeur then
			local claire = couleur:Lerp(Color3.new(1, 1, 1), 0.25)
			local cc = k.deco(Vector3.new(w * 0.34, corps * 0.9, w * 0.34), cf * CFrame.new(0, corps * 0.5, 0), claire, M.Neon, "Coeur")
			k.lueur(cc, o.transpCoeur or 0.35, o.tag or "EchoArene")
			table.insert(parts, cc)
		end
		return parts
	end
	-- Grappe de cristaux autour de cf (pied), inclinés
	function k.grappe(cf: CFrame, echelle: number, nombre: number, couleurs: {Color3}, opts: {[string]: any}?)
		for i = 1, nombre do
			local L = rng:NextNumber(3, 6) * echelle * (if i == 1 then 1.5 else 1)
			local base = cf * CFrame.new(rng:NextNumber(-0.5, 0.5) * echelle, 0, rng:NextNumber(-0.5, 0.5) * echelle)
				* CFrame.Angles(0, rng:NextNumber(0, DEUX_PI), 0) * CFrame.Angles(rng:NextNumber(-0.55, 0.55), 0, rng:NextNumber(-0.55, 0.55))
			k.cristal(base * CFrame.new(0, -L * 0.1, 0), L, L * 0.26, couleurs[rng:NextInteger(1, #couleurs)], if i == 1 then opts else nil)
		end
	end

	function k.eboulis(cf: CFrame, nombre: number, taille: number, c1: Color3, c2: Color3, mat: Enum.Material)
		for _ = 1, nombre do
			local t = rng:NextNumber(0.5, 1) * taille
			k.deco(Vector3.new(t, t * rng:NextNumber(0.6, 1), t), cf * CFrame.new(rng:NextNumber(-1, 1) * taille, t * 0.3, rng:NextNumber(-1, 1) * taille)
				* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), c1:Lerp(c2, rng:NextNumber()), mat, "Eboulis")
		end
	end

	-- Fissure / veine en zigzag dans le sol, entre les rayons rMin et rMax (retourne les pièces)
	function k.veine(a: number, r: number, segments: number, largeur: number, couleur: Color3, mat: Enum.Material, rMin: number, rMax: number): {BasePart}
		local parts = {}
		local p = Vector3.new(math.sin(a) * r, 0, -math.cos(a) * r)
		local dir = math.atan2(p.Z, p.X) + rng:NextNumber(-0.6, 0.6)
		for _ = 1, segments do
			local l = rng:NextNumber(2, 4.5)
			dir += rng:NextNumber(-0.8, 0.8)
			local q = p + Vector3.new(math.cos(dir), 0, math.sin(dir)) * l
			local d = q.Magnitude
			if d < rMin or d > rMax then break end
			table.insert(parts, k.incruster(largeur, l + largeur * 0.6, CFrame.lookAt(c + (p + q) / 2, c + q), couleur, mat, "Veine"))
			p = q
		end
		return parts
	end

	return k
end

return Kit
