-- Bâtiments et accessoires : maisons à colombages, échoppes, forge, wagonnets, arbres, cristaux, PNJ...
-- Convention : chaque fonction reçoit un CFrame posé au sol ; -Z (LookVector) = la façade / l'avant.
local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local M, C = O.M, O.C

local B = {}
local HE = 10 -- hauteur d'un étage

-- ================= Lumières =================

local function cage(parent, cf, couleur, portee)
	O.decor(O.bloc(parent, Vector3.new(1.6, 0.3, 1.6), cf * CFrame.new(0, 0.95, 0), C.Fer, M.Metal, "Toit"))
	O.decor(O.bloc(parent, Vector3.new(1.3, 0.25, 1.3), cf * CFrame.new(0, -0.95, 0), C.Fer, M.Metal, "Fond"))
	for _, o in {{-0.55, -0.55}, {0.55, -0.55}, {-0.55, 0.55}, {0.55, 0.55}} do
		O.decor(O.bloc(parent, Vector3.new(0.15, 1.8, 0.15), cf * CFrame.new(o[1], 0, o[2]), C.Fer, M.Metal, "Montant"))
	end
	local flamme = O.decor(O.bloc(parent, Vector3.new(0.9, 1.4, 0.9), cf, couleur or C.Lumiere, M.Neon, "Flamme"))
	O.lumiere(flamme, couleur or C.Lumiere, 1.5, portee or 22)
	return flamme
end

-- Lanterne sur poteau ; le bras pointe vers -Z
function B.lanterne(parent, cf, hauteur)
	local h = hauteur or 11
	local m = O.modele(parent, "Lanterne")
	O.bloc(m, Vector3.new(1.6, 0.8, 1.6), cf * CFrame.new(0, 0.4, 0), C.PierreFoncee, M.Pierre, "Socle")
	O.cylindre(m, h, 0.7, cf * CFrame.new(0, h / 2, 0), C.BoisFonce, M.Bois, "Poteau")
	O.decor(O.bloc(m, Vector3.new(0.35, 0.35, 3), cf * CFrame.new(0, h - 0.5, -1.3), C.Fer, M.Metal, "Bras"))
	local c = cf * CFrame.new(0, h - 2.1, -2.6)
	O.decor(O.bloc(m, Vector3.new(0.15, 0.6, 0.15), c * CFrame.new(0, 1.3, 0), C.Fer, M.Metal, "Crochet"))
	cage(m, c)
	return m
end

-- Lanterne suspendue à une chaîne (haut = point d'accroche)
function B.suspension(parent, haut, longueur, couleur, portee)
	local m = O.modele(parent, "Suspension")
	O.decor(O.bloc(m, Vector3.new(0.15, longueur, 0.15), CFrame.new(haut - Vector3.new(0, longueur / 2, 0)), C.Fer, M.Metal, "Chaine"))
	cage(m, CFrame.new(haut - Vector3.new(0, longueur + 0.95, 0)), couleur, portee)
	return m
end

-- Applique murale (cf collé au mur, -Z vers l'extérieur)
function B.applique(parent, cf)
	O.decor(O.bloc(parent, Vector3.new(0.3, 0.3, 1.2), cf * CFrame.new(0, 0.9, -0.6), C.Fer, M.Metal, "Support"))
	O.decor(O.bloc(parent, Vector3.new(1, 0.25, 1), cf * CFrame.new(0, 0.85, -1.2), C.Fer, M.Metal, "Chapeau"))
	local flamme = O.decor(O.bloc(parent, Vector3.new(0.7, 1, 0.7), cf * CFrame.new(0, 0.2, -1.2), C.Lumiere, M.Neon, "Flamme"))
	O.lumiere(flamme, C.Lumiere, 1.2, 16)
	return flamme
end

-- Brasero de pierre avec un vrai feu
function B.brasero(parent, cf, taille)
	local s = taille or 1
	local m = O.modele(parent, "Brasero")
	O.bloc(m, Vector3.new(3, 4, 3) * s, cf * CFrame.new(0, 2 * s, 0), C.PierreFoncee, M.Pierre, "Socle")
	O.cylindre(m, 1, 4.4 * s, cf * CFrame.new(0, 4.5 * s, 0), C.Fer, M.Rouille, "Coupe")
	local braises = O.decor(O.bloc(m, Vector3.new(3.4, 0.4, 3.4) * s, cf * CFrame.new(0, 5.1 * s, 0), Color3.fromRGB(255, 92, 24), M.Neon, "Braises"))
	O.feu(braises, 6 * s)
	O.lumiere(braises, Color3.fromRGB(255, 140, 60), 3, 40 * s, true)
	O.etincelles(braises, Color3.fromRGB(255, 170, 70), 5)
	return m
end

-- ================= Maisons =================

function B.porte(parent, cf)
	O.bloc(parent, Vector3.new(3.8, 7, 0.4), cf * CFrame.new(0, 3.5, -0.1), C.Bois, M.Planches, "Porte")
	O.bloc(parent, Vector3.new(4.8, 0.7, 0.7), cf * CFrame.new(0, 7.3, -0.3), C.BoisFonce, M.Bois, "Linteau")
	for _, x in {-2.2, 2.2} do
		O.bloc(parent, Vector3.new(0.6, 7.3, 0.6), cf * CFrame.new(x, 3.65, -0.3), C.BoisFonce, M.Bois, "Montant")
	end
	O.decor(O.bloc(parent, Vector3.new(0.25, 0.7, 0.3), cf * CFrame.new(1.3, 3.5, -0.4), C.Fer, M.Metal, "Poignee"))
	B.applique(parent, cf * CFrame.new(3.4, 5.2, 0))
end

function B.fenetre(parent, cf, allumee, volet, rng)
	local vitre = O.bloc(parent, Vector3.new(2.6, 3.2, 0.3), cf * CFrame.new(0, 0, -0.05),
		allumee and C.Fenetre or C.Vitre, allumee and M.Neon or M.Verre, "Vitre")
	vitre.Transparency = allumee and 0.35 or 0.2
	for _, y in {1.8, -1.8} do
		O.bloc(parent, Vector3.new(3.4, 0.45, 0.5), cf * CFrame.new(0, y, -0.25), C.BoisFonce, M.Bois, "Cadre")
	end
	for _, x in {-1.5, 1.5} do
		O.bloc(parent, Vector3.new(0.45, 3.6, 0.5), cf * CFrame.new(x, 0, -0.25), C.BoisFonce, M.Bois, "Cadre")
	end
	O.decor(O.bloc(parent, Vector3.new(0.18, 3.2, 0.36), cf * CFrame.new(0, 0, -0.2), C.BoisFonce, M.Bois, "Croisillon"))
	O.decor(O.bloc(parent, Vector3.new(2.6, 0.18, 0.36), cf * CFrame.new(0, 0.2, -0.2), C.BoisFonce, M.Bois, "Croisillon"))
	O.bloc(parent, Vector3.new(3.8, 0.35, 1), cf * CFrame.new(0, -2.05, -0.45), C.PierreClaire, M.Pierre, "Rebord")
	if rng:NextNumber() < 0.6 then
		for _, x in {-2.35, 2.35} do
			O.bloc(parent, Vector3.new(1.3, 3.5, 0.25), cf * CFrame.new(x, 0, -0.2), volet, M.Planches, "Volet")
		end
	end
	if allumee and rng:NextNumber() < 0.3 then
		O.lumiere(vitre, C.Fenetre, 0.8, 12)
	end
end

-- Panneau de bois accroché à plat sur une façade (texte vers -Z)
function B.fronton(parent, cf, texte, largeur)
	local p = O.bloc(parent, Vector3.new(largeur, 2.4, 0.4), cf * CFrame.new(0, 0, -0.35), C.BoisFonce, M.Planches, "Fronton")
	O.texte(p, Enum.NormalId.Front, texte)
	return p
end

local VERTS_LIERRE = {
	Color3.fromRGB(48, 74, 38),
	Color3.fromRGB(62, 90, 44),
	Color3.fromRGB(40, 62, 34),
	Color3.fromRGB(78, 98, 48),
	Color3.fromRGB(120, 92, 44), -- quelques feuilles qui roussissent
}

local TEINTES_LIERRE = {
	Tiges = {C.Tronc, M.Bois},
	Feuilles = {Color3.fromRGB(46, 72, 36), M.Lisse},
	FeuillesClaires = {Color3.fromRGB(76, 102, 46), M.Lisse},
	FeuillesRousses = {Color3.fromRGB(130, 84, 40), M.Lisse},
}

-- Lierre modélisé dans Blender (variantes LierreN qui grimpent, LierreHautN qui retombent du toit)
local function lierre3D(parent, fcf, W, hauteurMax, rng, porteX)
	local grimpants = M3.variantes("^Lierre%d+$")
	if #grimpants == 0 then
		return nil
	end
	local tombants = M3.variantes("^LierreHaut%d+$")
	local tombe = #tombants > 0 and rng:NextNumber() < 0.3
	local nom = if tombe then tombants[rng:NextInteger(1, #tombants)] else grimpants[rng:NextInteger(1, #grimpants)]
	local pieces = M3.pieces(nom) :: {MeshPart}
	local mn, mx = M3.boite(pieces)
	local taille = mx - mn
	local feuilles = M3.centre(pieces, {Feuilles = true, FeuillesClaires = true, FeuillesRousses = true}) or (mn + mx) / 2
	local tiges = M3.centre(pieces, {Tiges = true}) or (mn + mx) / 2
	-- l'axe le plus fin est la profondeur ; les feuilles sont devant les tiges
	local avant, largeur0
	if taille.X < taille.Z then
		avant = Vector3.new(if feuilles.X >= tiges.X then 1 else -1, 0, 0)
		largeur0 = taille.Z
	else
		avant = Vector3.new(0, 0, if feuilles.Z >= tiges.Z then 1 else -1)
		largeur0 = taille.X
	end
	local centre = (mn + mx) / 2
	local dos = centre - avant * (math.abs(taille:Dot(avant)) / 2)
	local origine = Vector3.new(dos.X, if tombe then mx.Y else mn.Y, dos.Z)
	local S = CFrame.lookAt(origine, origine + avant)

	-- k plafonné : au-delà les feuilles deviennent trop grosses pour les maisons
	local hauteurVoulue = if tombe then rng:NextNumber(4.5, 6.5) else math.min(12, hauteurMax * rng:NextNumber(0.55, 0.95))
	local k = hauteurVoulue / taille.Y
	k = math.min(k, (W - 1) / largeur0)
	if taille.Y * k < 3 then
		return nil
	end
	local demi = largeur0 * k / 2
	local bas = if tombe then hauteurMax - 0.2 - taille.Y * k else 0
	local x
	for _ = 1, 8 do
		local lim = W / 2 - demi - 0.3
		local essai = if lim > 0 then rng:NextNumber(-lim, lim) else 0
		if not porteX or bas > 10 or math.abs(essai - porteX) > demi + 2.8 then
			x = essai
			break
		end
	end
	if not x then
		return nil
	end
	local m = O.modele(parent, "Lierre")
	local teinte = rng:NextNumber(-0.12, 0.12)
	M3.poser(pieces, S, fcf * CFrame.new(x, if tombe then hauteurMax - 0.2 else 0, -0.5), k, m, function(c, nomTeinte)
		local t = TEINTES_LIERRE[nomTeinte]
		if t then
			c.Color = if teinte > 0 then t[1]:Lerp(Color3.fromRGB(110, 120, 50), teinte) else t[1]:Lerp(Color3.new(0, 0, 0), -teinte)
			c.Material = t[2]
		end
		O.decor(c)
	end)
	return m
end

-- Lierre qui grimpe sur un mur (fcf : bas-centre du mur, -Z vers l'extérieur ; W : largeur du mur)
function B.lierre(parent, fcf, W, hauteurMax, rng, porteX)
	local modele3D = lierre3D(parent, fcf, W, hauteurMax, rng, porteX)
	if modele3D then
		return modele3D
	end
	local m = O.modele(parent, "Lierre")
	local tiges = if rng:NextNumber() < 0.3 then 2 else 1
	for _ = 1, tiges do
		local x = rng:NextNumber(-W / 2 + 1, W / 2 - 1)
		local y = 0
		local limite = hauteurMax * rng:NextNumber(0.5, 0.97)
		local etalement = 0.7
		while y < limite do
			local pas = rng:NextNumber(0.8, 1.3)
			local nx = math.clamp(x + rng:NextNumber(-0.7, 0.7), -W / 2 + 0.6, W / 2 - 0.6)
			local a, b = Vector3.new(x, y, -0.62), Vector3.new(nx, y + pas, -0.62)
			O.decor(O.bloc(m, Vector3.new(0.12, 0.12, (b - a).Magnitude + 0.1), fcf * CFrame.lookAt((a + b) / 2, b), C.Tronc, M.Bois, "Tige"))
			for _ = 1, rng:NextInteger(2, 3) do
				local fx = math.clamp(nx + rng:NextNumber(-etalement, etalement), -W / 2 + 0.3, W / 2 - 0.3)
				local fy = y + rng:NextNumber(0, pas)
				local s = rng:NextNumber(0.7, 1.4)
				local surPorte = porteX and math.abs(fx - porteX) < 3 and fy < 9.5
				if not surPorte then O.decor(O.bloc(m, Vector3.new(s, s * rng:NextNumber(0.8, 1.1), 0.1),
					fcf * CFrame.new(fx, fy, -0.68 - rng:NextNumber(0, 0.18))
						* CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, math.pi)),
					VERTS_LIERRE[rng:NextInteger(1, #VERTS_LIERRE)], M.Herbe, "Feuille")) end
			end
			x, y = nx, y + pas
			etalement = math.min(etalement + 0.12, 2.6) -- le lierre s'élargit en montant
		end
	end
	return m
end

--[[ Maison à colombages
	o = {largeur, profondeur, etages, mur, toit, volet, nom, enseigne, cheminee, rng}
	Renvoie le modèle et le CFrame du bas de la porte (sur la façade). ]]
function B.maison(parent, cf, o)
	o = o or {}
	local rng = o.rng or Random.new()
	local L = o.largeur or 18
	local P = o.profondeur or 16
	local E = o.etages or 1
	local mur = o.mur or C.Platre
	local toit = o.toit or C.Toit
	local volet = o.volet or C.Volet
	local m = O.modele(parent, o.nom or "Maison")

	local socle = 1.6
	O.bloc(m, Vector3.new(L + 1.2, socle, P + 1.2), cf * CFrame.new(0, socle / 2, 0), C.PierreFoncee, M.Pierre, "Soubassement")
	for e = 1, E do
		local y0 = socle + (e - 1) * HE
		local pierre = E > 1 and e == 1
		O.bloc(m, Vector3.new(L, HE, P), cf * CFrame.new(0, y0 + HE / 2, 0),
			pierre and C.Pierre or mur, pierre and M.Pierre or M.Platre, "Murs")
	end
	local haut = socle + E * HE

	local faces = {
		{cf * CFrame.new(0, 0, -P / 2), L, true},
		{cf * CFrame.new(0, 0, P / 2) * CFrame.Angles(0, math.pi, 0), L, false},
		{cf * CFrame.new(-L / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), P, false},
		{cf * CFrame.new(L / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), P, false},
	}
	local porteCF = faces[1][1] * CFrame.new(0, socle, 0)
	for _, f in faces do
		local fcf, W, avant = f[1], f[2], f[3]
		local n = math.max(1, math.floor(W / 6.5))
		for e = 1, E do
			local y0 = socle + (e - 1) * HE
			local pierre = E > 1 and e == 1
			for i = 1, n do
				local x = -W / 2 + (i - 0.5) * W / n
				if avant and e == 1 and i == math.ceil(n / 2) then
					porteCF = fcf * CFrame.new(x, y0, 0)
					B.porte(m, porteCF)
					O.bloc(m, Vector3.new(5.2, socle, 2.2), fcf * CFrame.new(x, socle / 2, -1.1), C.PierreClaire, M.Pierre, "Marche")
				else
					B.fenetre(m, fcf * CFrame.new(x, y0 + HE * 0.55, 0), rng:NextNumber() < 0.75, volet, rng)
				end
			end
			if not pierre then
				-- colombages
				for _, y in {y0 + 0.35, y0 + HE - 0.35} do
					O.bloc(m, Vector3.new(W + 0.6, 0.7, 0.5), fcf * CFrame.new(0, y, -0.2), C.BoisFonce, M.Bois, "Poutre")
				end
				for i = 0, n do
					O.bloc(m, Vector3.new(0.7, HE, 0.5), fcf * CFrame.new(-W / 2 + i * W / n, y0 + HE / 2, -0.2), C.BoisFonce, M.Bois, "Poteau")
				end
			end
		end
	end

	-- Lierre sur certaines façades
	if o.lierre ~= false then
		for _, f in faces do
			if rng:NextNumber() < 0.35 then
				local porteX = if f[3] then f[1]:PointToObjectSpace(porteCF.Position).X else nil
				B.lierre(m, f[1], f[2], haut, rng, porteX)
			end
		end
	end

	-- Toit à deux pans (faîtage parallèle à la façade)
	local RH = P * 0.42
	O.coin(m, Vector3.new(L, RH, P / 2), cf * CFrame.new(0, haut + RH / 2, -P / 4), mur, M.Platre, "Pignon")
	O.coin(m, Vector3.new(L, RH, P / 2), cf * CFrame.new(0, haut + RH / 2, P / 4) * CFrame.Angles(0, math.pi, 0), mur, M.Platre, "Pignon")
	local demi = P / 2
	local theta = math.atan2(RH, demi)
	local pente = math.sqrt(demi * demi + RH * RH)
	local depasse = 1.4
	for _, s in {-1, 1} do
		local centre = cf * CFrame.new(0, haut + RH / 2, s * P / 4)
		O.bloc(m, Vector3.new(L + 2 * depasse, 0.7, pente + depasse),
			centre * CFrame.Angles(s * theta, 0, 0) * CFrame.new(0, 0.4, s * depasse / 2), toit, M.Tuiles, "Toit")
	end
	O.bloc(m, Vector3.new(L + 2 * depasse + 0.4, 0.9, 0.9), cf * CFrame.new(0, haut + RH + 0.35, 0), C.BoisFonce, M.Bois, "Faitage")

	-- Cheminée qui fume
	if o.cheminee ~= false and rng:NextNumber() < 0.8 then
		local cx = (rng:NextNumber() < 0.5 and -1 or 1) * L * 0.28
		local hC = RH + 4
		O.bloc(m, Vector3.new(2.4, hC, 2.4), cf * CFrame.new(cx, haut + hC / 2, P / 6), C.Brique, M.Brique, "Cheminee")
		local chapeau = O.bloc(m, Vector3.new(3, 0.6, 3), cf * CFrame.new(cx, haut + hC + 0.3, P / 6), C.PierreFoncee, M.Pierre, "Chapeau")
		O.fumee(chapeau, 1.5)
	end

	if o.enseigne then
		B.fronton(m, porteCF * CFrame.new(0, 8.6, 0), o.enseigne, math.min(L - 2, 16))
	end
	return m, porteCF
end

-- ================= Commerces =================

-- Échoppe avec comptoir et auvent rayé. Le marchand se tient derrière (côté +Z).
function B.echoppe(parent, cf, largeur, toile)
	local m = O.modele(parent, "Echoppe")
	local l = largeur
	O.bloc(m, Vector3.new(l, 3.2, 2.2), cf * CFrame.new(0, 1.6, 0), C.Bois, M.Planches, "Comptoir")
	O.bloc(m, Vector3.new(l + 0.6, 0.35, 2.8), cf * CFrame.new(0, 3.37, 0), C.BoisClair, M.Bois, "Plateau")
	for _, x in {-l / 2, l / 2} do
		O.bloc(m, Vector3.new(0.6, 8, 0.6), cf * CFrame.new(x, 4, -1.2), C.BoisFonce, M.Bois, "Poteau")
		O.bloc(m, Vector3.new(0.6, 10, 0.6), cf * CFrame.new(x, 5, 5), C.BoisFonce, M.Bois, "Poteau")
	end
	local larg = l + 1.6
	local bandes = math.max(3, math.floor(larg / 2.2))
	local lb = larg / bandes
	for i = 1, bandes do
		local x = -larg / 2 + (i - 0.5) * lb
		local bande = O.bloc(m, Vector3.new(lb, 0.2, 8.4), cf * CFrame.new(x, 9.1, 1.9) * CFrame.Angles(math.rad(-14), 0, 0),
			i % 2 == 0 and toile or C.Toile, M.Tissu, "Auvent")
		bande.CanTouch = false
	end
	return m
end

function B.epee(parent, cf, couleur, mat)
	local m = O.modele(parent, "Epee")
	O.bloc(m, Vector3.new(0.55, 3.8, 0.16), cf * CFrame.new(0, 2.4, 0), couleur, mat, "Lame")
	O.bloc(m, Vector3.new(1.8, 0.3, 0.4), cf * CFrame.new(0, 4.45, 0), C.Or, M.Metal, "Garde")
	O.bloc(m, Vector3.new(0.3, 1.2, 0.3), cf * CFrame.new(0, 5.2, 0), C.BoisFonce, M.Cuir, "Poignee")
	O.bloc(m, Vector3.new(0.45, 0.45, 0.45), cf * CFrame.new(0, 5.95, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), C.Or, M.Metal, "Pommeau")
	if mat == M.Neon then
		O.lumiere(m.Lame, couleur, 1, 8)
	end
	return O.decorModele(m)
end

-- Armure sur mannequin : casque, plastron, jambières
function B.armure(parent, cf, couleur, mat, lisere)
	local m = O.modele(parent, "Armure")
	O.bloc(m, Vector3.new(2.4, 0.4, 2.4), cf * CFrame.new(0, 0.2, 0), C.BoisFonce, M.Bois, "Socle")
	O.bloc(m, Vector3.new(0.4, 6.4, 0.4), cf * CFrame.new(0, 3.4, 0.2), C.Bois, M.Bois, "Mat")
	for _, x in {-0.55, 0.55} do
		O.bloc(m, Vector3.new(0.95, 2.4, 1), cf * CFrame.new(x, 2.3, 0), couleur, mat, "Jambiere")
	end
	O.bloc(m, Vector3.new(2.3, 2.3, 1.2), cf * CFrame.new(0, 4.65, 0), couleur, mat, "Plastron")
	O.bloc(m, Vector3.new(2.36, 0.3, 1.26), cf * CFrame.new(0, 3.55, 0), lisere or C.Or, M.Metal, "Ceinture")
	for _, x in {-1.45, 1.45} do
		O.ellipsoide(m, Vector3.new(1.2, 0.9, 1.4), cf * CFrame.new(x, 5.6, 0), couleur, mat, "Epauliere")
	end
	O.ellipsoide(m, Vector3.new(1.5, 1.6, 1.6), cf * CFrame.new(0, 6.65, 0), couleur, mat, "Casque")
	O.bloc(m, Vector3.new(1.1, 0.2, 0.2), cf * CFrame.new(0, 6.6, -0.75), Color3.fromRGB(14, 12, 12), M.Lisse, "Visiere")
	O.bloc(m, Vector3.new(0.2, 0.8, 1.4), cf * CFrame.new(0, 7.5, 0), lisere or C.Or, M.Metal, "Crete")
	return O.decorModele(m)
end

-- La forge du forgeron : atelier ouvert, foyer, enclume, épées et armures exposées
function B.forge(parent, cf)
	local m = O.modele(parent, "Forge")
	O.bloc(m, Vector3.new(24, 1, 20), cf * CFrame.new(0, 0.5, 0), C.PierreFoncee, M.Pierre, "Sol")
	O.bloc(m, Vector3.new(24, 17, 2), cf * CFrame.new(0, 9.5, 9), C.Pierre, M.Pierre, "MurFond")
	for _, x in {-11, 11} do
		O.bloc(m, Vector3.new(2, 13, 10), cf * CFrame.new(x, 7.5, 4), C.Pierre, M.Pierre, "MurCote")
		O.bloc(m, Vector3.new(1.4, 13, 1.4), cf * CFrame.new(x, 7.5, -9), C.BoisFonce, M.Bois, "Poteau")
	end
	O.bloc(m, Vector3.new(24.4, 1.4, 1.4), cf * CFrame.new(0, 13.3, -9), C.BoisFonce, M.Bois, "Sabliere")
	-- toit à un pan : y = 18 au fond (z = 10), y = 14 à l'avant (z = -10.5)
	local theta = math.atan2(4, 20.5)
	O.bloc(m, Vector3.new(26, 0.8, 22.4), cf * CFrame.new(0, 16, -0.25) * CFrame.Angles(-theta, 0, 0) * CFrame.new(0, 0.4, 0),
		C.Toit, M.Tuiles, "Toit")
	B.fronton(m, cf * CFrame.new(0, 11.9, -9.3), "FORGERON", 12)

	-- Foyer, hotte et cheminée
	local foyer = cf * CFrame.new(-5, 1, 6)
	O.bloc(m, Vector3.new(7, 4, 5), foyer * CFrame.new(0, 2, 0), C.PierreFoncee, M.Brique, "Foyer")
	local braises = O.bloc(m, Vector3.new(5.6, 0.5, 3.6), foyer * CFrame.new(0, 4.1, -0.2), Color3.fromRGB(255, 96, 24), M.Neon, "Braises")
	O.feu(braises, 5)
	O.lumiere(braises, Color3.fromRGB(255, 130, 50), 4, 34, true)
	O.etincelles(braises, Color3.fromRGB(255, 180, 80), 8)
	O.coin(m, Vector3.new(7.4, 4, 4.4), foyer * CFrame.new(0, 9.2, 0.3), C.Pierre, M.Brique, "Hotte")
	O.bloc(m, Vector3.new(3, 12, 3), foyer * CFrame.new(0, 16.5, 1), C.Brique, M.Brique, "Cheminee")
	local chapeau = O.bloc(m, Vector3.new(3.8, 0.6, 3.8), foyer * CFrame.new(0, 22.8, 1), C.PierreFoncee, M.Pierre, "Chapeau")
	O.fumee(chapeau, 4, Color3.fromRGB(110, 102, 98))
	-- Soufflet
	O.coin(m, Vector3.new(2.2, 1.6, 3), foyer * CFrame.new(4.6, 2.6, 0) * CFrame.Angles(0, -math.pi / 2, 0), C.BoisFonce, M.Cuir, "Soufflet")

	-- Enclume sur billot
	local enclume = cf * CFrame.new(2, 1, -1)
	O.cylindre(m, 2.4, 2.4, enclume * CFrame.new(0, 1.2, 0), C.Bois, M.Bois, "Billot")
	O.bloc(m, Vector3.new(1.2, 1, 0.9), enclume * CFrame.new(0, 2.9, 0), C.Fer, M.Metal, "Pied")
	O.bloc(m, Vector3.new(2.8, 0.8, 1.2), enclume * CFrame.new(0, 3.8, 0), C.Fer, M.Metal, "Table")
	O.coin(m, Vector3.new(1.2, 0.8, 1.4), enclume * CFrame.new(-2.1, 3.8, 0) * CFrame.Angles(0, math.pi / 2, 0), C.Fer, M.Metal, "Bigorne")
	O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 1.6), enclume * CFrame.new(0.5, 4.35, 0.2), C.BoisFonce, M.Bois, "Marteau"))
	O.decor(O.bloc(m, Vector3.new(0.6, 0.5, 0.5), enclume * CFrame.new(0.5, 4.35, -0.6), C.Fer, M.Metal, "TeteMarteau"))
	-- Baquet de trempe
	O.cylindre(m, 2, 3, cf * CFrame.new(6.5, 2, 5.5), C.Bois, M.Planches, "Baquet")
	O.decor(O.cylindre(m, 0.2, 2.6, cf * CFrame.new(6.5, 2.9, 5.5), C.Eau, M.Verre, "Eau"))

	-- Râtelier d'épées (mur de droite, tourné vers l'intérieur)
	local ratelier = cf * CFrame.new(9.6, 1, 3) * CFrame.Angles(0, math.pi / 2, 0)
	for _, y in {3, 6} do
		O.bloc(m, Vector3.new(7, 0.4, 0.4), ratelier * CFrame.new(0, y, 0.3), C.BoisFonce, M.Bois, "Barre")
	end
	B.epee(m, ratelier * CFrame.new(-2.4, 0.4, 0), Color3.fromRGB(176, 180, 188), M.Metal)
	B.epee(m, ratelier * CFrame.new(0, 0.4, 0), Color3.fromRGB(255, 200, 80), M.Metal)
	B.epee(m, ratelier * CFrame.new(2.4, 0.4, 0), C.Cristal, M.Neon)

	-- Armures exposées devant l'atelier
	B.armure(m, cf * CFrame.new(-8, 1, -6), Color3.fromRGB(150, 154, 162), M.Metal, C.BoisFonce)
	B.armure(m, cf * CFrame.new(8, 1, -6), Color3.fromRGB(226, 176, 70), M.Metal, C.CristalViolet)
	return m
end

-- Tableau des classements (texte vers -Z). Les lignes Rang1..Rang10 seront remplies plus tard.
function B.classement(parent, cf, titre, stat)
	local m = O.modele(parent, "Classement_" .. stat)
	O.bloc(m, Vector3.new(11, 1.2, 3), cf * CFrame.new(0, 0.6, 0), C.PierreFoncee, M.Pierre, "Socle")
	for _, x in {-5, 5} do
		O.bloc(m, Vector3.new(1, 15, 1), cf * CFrame.new(x, 8.7, 0), C.BoisFonce, M.Bois, "Poteau")
		B.applique(m, cf * CFrame.new(x, 13, -0.5))
	end
	O.bloc(m, Vector3.new(12.4, 0.7, 2.6), cf * CFrame.new(0, 16.5, 0), C.Toit, M.Tuiles, "Chapeau")
	local tableau = O.bloc(m, Vector3.new(9, 12, 0.5), cf * CFrame.new(0, 9.4, 0), C.BoisFonce, M.Planches, "Tableau")
	O.tag(tableau, "Classement")
	tableau:SetAttribute("Stat", stat)

	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 50
	g.LightInfluence = 0.2
	g.Parent = tableau
	local fond = Instance.new("Frame")
	fond.Size = UDim2.fromScale(1, 1)
	fond.BackgroundColor3 = Color3.fromRGB(30, 22, 16)
	fond.BackgroundTransparency = 0.05
	fond.Parent = g
	local bord = Instance.new("UIStroke")
	bord.Color = C.Or
	bord.Thickness = 6
	bord.Parent = fond
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0.05, 0.02)
	t.Size = UDim2.fromScale(0.9, 0.12)
	t.Font = Enum.Font.Fantasy
	t.TextScaled = true
	t.TextColor3 = C.Or
	t.Text = titre
	t.Parent = fond
	local liste = Instance.new("Frame")
	liste.Name = "Liste"
	liste.BackgroundTransparency = 1
	liste.Position = UDim2.fromScale(0.07, 0.17)
	liste.Size = UDim2.fromScale(0.86, 0.8)
	liste.Parent = fond
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.01, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = liste
	local medailles = {Color3.fromRGB(255, 210, 90), Color3.fromRGB(210, 214, 222), Color3.fromRGB(214, 140, 80)}
	for i = 1, 10 do
		local ligne = Instance.new("TextLabel")
		ligne.Name = "Rang" .. i
		ligne.LayoutOrder = i
		ligne.BackgroundTransparency = 1
		ligne.Size = UDim2.fromScale(1, 0.088)
		ligne.Font = Enum.Font.GothamMedium
		ligne.TextScaled = true
		ligne.TextXAlignment = Enum.TextXAlignment.Left
		ligne.TextColor3 = medailles[i] or Color3.fromRGB(236, 226, 210)
		ligne.Text = i .. ".  —"
		ligne.Parent = liste
	end
	return m
end

-- ================= Accessoires =================

function B.tonneau(parent, cf)
	local m = O.modele(parent, "Tonneau")
	O.cylindre(m, 3.2, 2.4, cf * CFrame.new(0, 1.6, 0), C.Bois, M.Planches, "Corps")
	for _, y in {0.5, 2.7} do
		O.decor(O.cylindre(m, 0.25, 2.55, cf * CFrame.new(0, y, 0), C.Fer, M.Metal, "Cercle"))
	end
	return m
end

function B.caisse(parent, cf, s)
	s = s or 2.6
	local m = O.modele(parent, "Caisse")
	O.bloc(m, Vector3.new(s, s, s), cf * CFrame.new(0, s / 2, 0), C.BoisClair, M.Planches, "Corps")
	for _, x in {-1, 1} do
		for _, z in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.35, s + 0.04, 0.35), cf * CFrame.new(x * (s / 2 - 0.12), s / 2, z * (s / 2 - 0.12)), C.Bois, M.Bois, "Arete"))
		end
	end
	return m
end

function B.banc(parent, cf)
	local m = O.modele(parent, "Banc")
	O.bloc(m, Vector3.new(6, 0.4, 1.6), cf * CFrame.new(0, 1.8, 0), C.BoisClair, M.Planches, "Assise")
	O.bloc(m, Vector3.new(6, 1.4, 0.3), cf * CFrame.new(0, 2.9, 0.75), C.BoisClair, M.Planches, "Dossier")
	for _, x in {-2.5, 2.5} do
		O.bloc(m, Vector3.new(0.4, 1.6, 1.4), cf * CFrame.new(x, 0.8, 0), C.Fer, M.Metal, "Pied")
	end
	return m
end

function B.tableTaverne(parent, cf)
	local m = O.modele(parent, "Table")
	O.cylindre(m, 0.4, 4.4, cf * CFrame.new(0, 3, 0), C.BoisClair, M.Planches, "Plateau")
	O.cylindre(m, 2.8, 0.7, cf * CFrame.new(0, 1.4, 0), C.BoisFonce, M.Bois, "Pied")
	for _, x in {-3.3, 3.3} do
		O.cylindre(m, 1.6, 1.6, cf * CFrame.new(x, 0.8, 0), C.Bois, M.Planches, "Tabouret")
	end
	for _, o in {{-0.9, 0.5}, {1, -0.6}} do
		O.decor(O.cylindre(m, 0.8, 0.6, cf * CFrame.new(o[1], 3.6, o[2]), C.Bois, M.Bois, "Chope"))
		O.decor(O.cylindre(m, 0.15, 0.62, cf * CFrame.new(o[1], 4.05, o[2]), Color3.fromRGB(246, 236, 210), M.Lisse, "Mousse"))
	end
	return m
end

function B.puits(parent, cf)
	local m = O.modele(parent, "Puits")
	for i = 0, 7 do
		O.bloc(m, Vector3.new(2.3, 2.8, 0.9), cf * CFrame.Angles(0, i * math.pi / 4, 0) * CFrame.new(0, 1.4, -2.6), C.Pierre, M.Pierre, "Margelle")
	end
	O.decor(O.cylindre(m, 0.2, 4.6, cf * CFrame.new(0, 1.2, 0), Color3.fromRGB(20, 34, 40), M.Verre, "Eau"))
	for _, x in {-2.9, 2.9} do
		O.bloc(m, Vector3.new(0.6, 6.4, 0.6), cf * CFrame.new(x, 3.2, 0), C.BoisFonce, M.Bois, "Poteau")
	end
	O.decor(O.cylindre(m, 6.4, 0.5, cf * CFrame.new(0, 5.4, 0) * CFrame.Angles(0, 0, math.pi / 2), C.Bois, M.Bois, "Treuil"))
	O.coin(m, Vector3.new(7, 1.6, 2.2), cf * CFrame.new(0, 7.2, -1.1), C.Toit, M.Tuiles, "Toit")
	O.coin(m, Vector3.new(7, 1.6, 2.2), cf * CFrame.new(0, 7.2, 1.1) * CFrame.Angles(0, math.pi, 0), C.Toit, M.Tuiles, "Toit")
	O.decor(O.bloc(m, Vector3.new(0.1, 2, 0.1), cf * CFrame.new(0.6, 4.2, 0), Color3.fromRGB(150, 130, 100), M.Tissu, "Corde"))
	O.decor(O.cylindre(m, 1, 1, cf * CFrame.new(0.6, 2.9, 0), C.Bois, M.Planches, "Seau"))
	return m
end

-- Pioche posée à plat (manche le long de X)
function B.pioche(parent, cf, couleurTete)
	local m = O.modele(parent, "Pioche")
	O.bloc(m, Vector3.new(3.4, 0.25, 0.25), cf * CFrame.new(0, 0.125, 0), C.Bois, M.Bois, "Manche")
	O.bloc(m, Vector3.new(0.35, 0.3, 2.6), cf * CFrame.new(1.6, 0.15, 0), couleurTete, M.Metal, "Tete")
	return O.decorModele(m)
end

-- Tas de minerai (ellipsoïdes)
function B.tas(parent, cf, couleur, taille, rng)
	local m = O.modele(parent, "Tas")
	for _ = 1, 6 do
		local s = taille * rng:NextNumber(0.4, 0.8)
		O.ellipsoide(m, Vector3.new(s, s * 0.6, s), cf * CFrame.new(rng:NextNumber(-1, 1) * taille * 0.35, s * 0.2, rng:NextNumber(-1, 1) * taille * 0.35),
			couleur, M.Roche, "Morceau")
	end
	return m
end

function B.butoir(parent, cf)
	local m = O.modele(parent, "Butoir")
	for _, x in {-2.5, 2.5} do
		O.bloc(m, Vector3.new(0.8, 3, 0.8), cf * CFrame.new(x, 1.5, 0), C.BoisFonce, M.Bois, "Poteau")
	end
	O.bloc(m, Vector3.new(7, 1.2, 1.2), cf * CFrame.new(0, 2.6, 0), C.Bois, M.Bois, "Traverse")
	local lampe = O.decor(O.bloc(m, Vector3.new(0.8, 0.8, 0.4), cf * CFrame.new(0, 3.6, -0.3), Color3.fromRGB(255, 60, 40), M.Neon, "Lampe"))
	O.lumiere(lampe, Color3.fromRGB(255, 70, 50), 1, 10)
	return m
end

-- Wagonnet posé sur les rails (cf au niveau du sol, entre les rails ; avant = -Z)
function B.wagonnet(parent, cf, minerai, rng)
	local m = O.modele(parent, "Wagonnet")
	local yRail = 0.975
	for _, x in {-2.5, 2.5} do
		for _, z in {-2.1, 2.1} do
			O.disque(m, 0.5, 1.8, cf * CFrame.new(x, yRail + 0.9, z), C.Fer, M.Metal, "Roue")
		end
	end
	O.bloc(m, Vector3.new(5.4, 0.6, 6.4), cf * CFrame.new(0, 2.6, 0), C.Fer, M.Metal, "Chassis")
	local fond = O.bloc(m, Vector3.new(6, 0.4, 7.2), cf * CFrame.new(0, 3.1, 0), C.Bois, M.Planches, "Fond")
	for _, x in {-2.8, 2.8} do
		O.bloc(m, Vector3.new(0.4, 3, 7.2), cf * CFrame.new(x, 4.6, 0), C.BoisClair, M.Planches, "Flanc")
		O.bloc(m, Vector3.new(0.55, 0.4, 7.6), cf * CFrame.new(x, 6.1, 0), C.Fer, M.Metal, "Bord")
	end
	for _, z in {-3.4, 3.4} do
		O.bloc(m, Vector3.new(6, 3, 0.4), cf * CFrame.new(0, 4.6, z), C.BoisClair, M.Planches, "Face")
		O.bloc(m, Vector3.new(6.4, 0.4, 0.55), cf * CFrame.new(0, 6.1, z), C.Fer, M.Metal, "Bord")
		O.bloc(m, Vector3.new(0.6, 0.6, 0.8), cf * CFrame.new(0, 2.6, z * 1.12), C.Fer, M.Metal, "Attelage")
	end
	if minerai then
		rng = rng or Random.new()
		for _ = 1, 5 do
			local s = rng:NextNumber(1.6, 2.6)
			O.decor(O.ellipsoide(m, Vector3.new(s, s * 0.7, s), cf * CFrame.new(rng:NextNumber(-1.4, 1.4), 5.6, rng:NextNumber(-2, 2)),
				minerai, M.Roche, "Minerai"))
		end
	end
	m.PrimaryPart = fond
	return m
end

-- ================= Nature =================

function B.pin(parent, base, h, rng)
	local m = O.modele(parent, "Pin")
	O.cylindre(m, h * 0.5, math.max(0.8, h * 0.06), CFrame.new(base + Vector3.new(0, h * 0.25, 0)), C.Tronc, M.Bois, "Tronc")
	local vert = Color3.fromRGB(38 + rng:NextInteger(-6, 8), 60 + rng:NextInteger(-8, 10), 40 + rng:NextInteger(-6, 6))
	local rot = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	for i = 0, 3 do
		local largeur = h * (0.52 - i * 0.11)
		local hauteur = h * 0.32
		O.decor(O.ellipsoide(m, Vector3.new(largeur, hauteur, largeur * 0.9),
			CFrame.new(base + Vector3.new(0, h * (0.3 + i * 0.16), 0)) * rot, vert, M.Lisse, "Branches"))
	end
	O.decor(O.ellipsoide(m, Vector3.new(h * 0.08, h * 0.2, h * 0.08), CFrame.new(base + Vector3.new(0, h * 0.94, 0)), vert, M.Lisse, "Cime"))
	return m
end

local AUTOMNE = {
	Color3.fromRGB(196, 112, 44),
	Color3.fromRGB(214, 160, 62),
	Color3.fromRGB(164, 66, 42),
	Color3.fromRGB(150, 124, 52),
}

function B.feuillu(parent, base, h, rng)
	local m = O.modele(parent, "Arbre")
	O.cylindre(m, h * 0.6, math.max(0.9, h * 0.08), CFrame.new(base + Vector3.new(0, h * 0.3, 0)), C.Tronc, M.Bois, "Tronc")
	local couleur = AUTOMNE[rng:NextInteger(1, #AUTOMNE)]
	for _ = 1, rng:NextInteger(4, 6) do
		local s = h * rng:NextNumber(0.35, 0.5)
		local offset = Vector3.new(rng:NextNumber(-1, 1) * h * 0.18, h * rng:NextNumber(0.58, 0.8), rng:NextNumber(-1, 1) * h * 0.18)
		local teinte = couleur:Lerp(AUTOMNE[rng:NextInteger(1, #AUTOMNE)], 0.3)
		O.decor(O.ellipsoide(m, Vector3.new(s, s * 0.8, s), CFrame.new(base + offset), teinte, M.Lisse, "Feuillage"))
	end
	return m
end

local NEIGE = O.materiau("Snow", Enum.Material.Sand)

--[[ Pose un rocher / une falaise modélisé(e) : base au sol, taille = plus grande dimension horizontale
	(ou hauteur si parHauteur). Le dessus est enneigé en altitude, moussu plus bas, sombre sous terre. ]]
local function roche3D(parent, nom, cible, taille, rng, parHauteur)
	local pieces = M3.pieces(nom) :: {MeshPart}
	local mn, mx = M3.boite(pieces)
	local t = mx - mn
	local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
	local k = taille / (if parHauteur then t.Y else math.max(t.X, t.Z))
	local m = O.modele(parent, nom)
	local altitude = cible.Position.Y + t.Y * k * 0.7
	local teinte = C.Roche:Lerp(C.PierreFoncee, rng:NextNumber(0, 0.6))
	M3.poser(pieces, S, cible, k, m, function(c, nomTeinte)
		if nomTeinte == "Dessus" then
			if altitude > 175 then
				c.Color = Color3.fromRGB(236, 240, 246)
				c.Material = NEIGE
			elseif altitude > 0 then
				c.Color = Color3.fromRGB(82, 96, 56):Lerp(Color3.fromRGB(120, 116, 96), math.clamp(altitude / 175, 0, 1))
				c.Material = M.Herbe
			else
				c.Color = teinte:Lerp(Color3.new(0, 0, 0), 0.2)
				c.Material = M.Roche
			end
		else
			c.Color = teinte
			c.Material = M.Roche
		end
		if taille < 4 then
			O.decor(c) -- les cailloux ne gênent pas la marche
		end
	end)
	return m
end

-- Falaise ou aiguille rocheuse plantée dans une pente (cf : base, X = sens de la largeur)
function B.falaise(parent, cf, hauteur, rng, aiguille)
	local vars = M3.variantes(if aiguille then "^Aiguille%d+$" else "^Falaise%d+$")
	if #vars == 0 then
		return nil
	end
	return roche3D(parent, vars[rng:NextInteger(1, #vars)], cf, hauteur, rng, true)
end

function B.rocher(parent, base, s, rng)
	local vars = M3.variantes("^Rocher%d+$")
	if #vars > 0 and s >= 2 then -- les petits cailloux restent en blocs (moins coûteux)
		local cf = CFrame.new(base) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.15, 0.15))
		return roche3D(parent, vars[rng:NextInteger(1, #vars)], cf, s * 1.5, rng, false)
	end
	local m = O.modele(parent, "Rocher")
	for i = 1, rng:NextInteger(1, 3) do
		local t = Vector3.new(rng:NextNumber(1, 1.8), rng:NextNumber(0.7, 1.2), rng:NextNumber(1, 1.6)) * s / i
		O.bloc(m, t, CFrame.new(base + Vector3.new(rng:NextNumber(-0.4, 0.4) * s, t.Y * 0.25, rng:NextNumber(-0.4, 0.4) * s))
			* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, math.pi), rng:NextNumber(-0.4, 0.4)),
			C.Roche:Lerp(C.PierreFoncee, rng:NextNumber()), M.Roche, "Pierre")
	end
	return m
end

-- ================= Fantasy =================

local function prisme(parent, cf, h, couleur)
	local r = h * 0.22
	local axe = cf * CFrame.Angles(0, math.rad(45), 0)
	local coeur = O.bloc(parent, Vector3.new(r * 0.5, h * 0.92, r * 0.5), axe * CFrame.new(0, h * 0.46, 0), couleur, M.Neon, "Coeur")
	local gaine = O.bloc(parent, Vector3.new(r, h, r), axe * CFrame.new(0, h / 2, 0), couleur, M.Verre, "Gaine")
	gaine.Transparency = 0.4
	gaine.Reflectance = 0.25
	local pointe = O.bloc(parent, Vector3.new(r * 0.72, r * 0.72, r * 0.72), axe * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
		couleur, M.Verre, "Pointe")
	pointe.Transparency = 0.3
	return coeur
end

-- Amas de cristaux lumineux (cf = base, l'axe Y = direction de pousse)
function B.cristal(parent, cf, h, couleur, rng, portee)
	rng = rng or Random.new()
	local m = O.modele(parent, "Cristal")
	local coeur = prisme(m, cf, h, couleur)
	for _ = 1, rng:NextInteger(2, 4) do
		local a = rng:NextNumber(0, math.pi * 2)
		local inclinaison = rng:NextNumber(0.35, 0.7)
		local scf = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -h * 0.12) * CFrame.Angles(-inclinaison, 0, 0)
		prisme(m, scf, h * rng:NextNumber(0.35, 0.6), couleur)
	end
	O.lumiere(coeur, couleur, 2.2, portee or math.clamp(h * 2.2, 14, 60))
	m.PrimaryPart = coeur
	return m, coeur
end

-- ================= PNJ =================

local function sombre(c, k)
	return c:Lerp(Color3.new(0, 0, 0), k)
end

-- Cheveux selon la coiffure (dans le modèle de la tête, centre de la tête = t)
local function coiffure(g, t, style, couleur)
	if style == "chauve" then
		O.decor(O.bloc(g, Vector3.new(1.26, 0.4, 0.4), t * CFrame.new(0, -0.15, 0.46), couleur, M.Tissu, "Couronne"))
		return
	end
	O.decor(O.ellipsoide(g, Vector3.new(1.36, 0.75, 1.36), t * CFrame.new(0, 0.5, 0.05), couleur, M.Tissu, "Calotte"))
	O.decor(O.bloc(g, Vector3.new(1.3, 0.95, 0.42), t * CFrame.new(0, 0.12, 0.46), couleur, M.Tissu, "Nuque"))
	for _, s in {-1, 1} do
		O.decor(O.bloc(g, Vector3.new(0.2, 0.62, 0.9), t * CFrame.new(s * 0.62, 0.3, 0.12), couleur, M.Tissu, "Tempe"))
	end
	O.decor(O.bloc(g, Vector3.new(1.1, 0.22, 0.3), t * CFrame.new(0, 0.58, -0.5) * CFrame.Angles(0.3, 0, 0), couleur, M.Tissu, "Frange"))
	if style == "long" then
		O.decor(O.bloc(g, Vector3.new(1.34, 2, 0.42), t * CFrame.new(0, -0.6, 0.5), couleur, M.Tissu, "Cheveux"))
		for _, s in {-1, 1} do
			O.decor(O.bloc(g, Vector3.new(0.24, 1.5, 0.45), t * CFrame.new(s * 0.66, -0.35, 0.12), couleur, M.Tissu, "Meche"))
		end
	elseif style == "chignon" then
		O.decor(O.ellipsoide(g, Vector3.new(0.8, 0.8, 0.8), t * CFrame.new(0, 0.62, 0.62), couleur, M.Tissu, "Chignon"))
	end
end

-- Objet tenu dans la main (main = CFrame de la main)
local function outil(g, main, genre)
	if genre == "marteau" then
		O.decor(O.bloc(g, Vector3.new(0.22, 1.9, 0.22), main * CFrame.new(0, -0.55, -0.1), C.Bois, M.Bois, "Manche"))
		O.decor(O.bloc(g, Vector3.new(0.55, 0.5, 1.1), main * CFrame.new(0, -1.45, -0.1), C.Fer, M.Metal, "TeteMarteau"))
	elseif genre == "pioche" then
		O.decor(O.bloc(g, Vector3.new(0.22, 3.4, 0.22), main * CFrame.new(0, 0.2, -0.15), C.Bois, M.Bois, "Manche"))
		O.decor(O.bloc(g, Vector3.new(0.3, 0.32, 2.8), main * CFrame.new(0, 1.85, -0.15), Color3.fromRGB(150, 154, 162), M.Metal, "TetePioche"))
	elseif genre == "chope" then
		O.decor(O.cylindre(g, 0.85, 0.7, main * CFrame.new(0, 0.3, -0.35), C.Bois, M.Planches, "Chope"))
		O.decor(O.cylindre(g, 0.16, 0.72, main * CFrame.new(0, 0.8, -0.35), Color3.fromRGB(246, 236, 210), M.Lisse, "Mousse"))
		O.decor(O.cylindre(g, 0.1, 0.74, main * CFrame.new(0, 0.05, -0.35), C.Fer, M.Metal, "Cercle"))
	elseif genre == "registre" then
		O.decor(O.bloc(g, Vector3.new(1.05, 1.35, 0.3), main * CFrame.new(0, 0.35, -0.4) * CFrame.Angles(0.35, 0, 0), Color3.fromRGB(120, 36, 32), M.Cuir, "Couverture"))
		O.decor(O.bloc(g, Vector3.new(0.95, 1.25, 0.32), main * CFrame.new(0.06, 0.35, -0.4) * CFrame.Angles(0.35, 0, 0), Color3.fromRGB(236, 224, 196), M.Lisse, "Pages"))
	end
end

--[[ PNJ détaillé, construit en trois groupes animés par le client :
	Corps (jambes, bottes), Buste (torse, bras, tablier, outil), Tete (visage, cheveux, chapeau).
	tenue = {
		haut, bas, peau?, bottes?, ceinture?,
		coiffure? = "court" | "long" | "chignon" | "chauve", cheveux? = Color3,
		barbe? = Color3, barbeLongue? = bool, chapeau? = Color3, tablier? = Color3,
		manchesCourtes? = bool, outil? = "marteau" | "pioche" | "chope" | "registre",
	} ]]
--[[ PNJ en vrai avatar Roblox (R15) : corps articulé, couleurs de la tenue, accessoires du catalogue
	(tenue.accessoires = {{idCatalogue, "Hair"}, {id, "Hat"}, {id, "Face"}, {id, "Jacket"}...}),
	animation de repos et outil soudé dans la main. Renvoie nil si Roblox refuse (ex. hors serveur). ]]
local Players = game:GetService("Players")
local ANIM_REPOS = "rbxassetid://507766666" -- repos R15 standard

local function pnjAvatar(parent, cf, nom, role, tenue)
	local peau = tenue.peau or Color3.fromRGB(226, 182, 150)
	local acc = tenue.accessoires or {}
	local function description(niveau) -- 2 = tout, 1 = sans vêtements 3D, 0 = rien
		local d = Instance.new("HumanoidDescription")
		d.HeadColor = peau
		d.TorsoColor = tenue.haut
		local bras = if tenue.manchesCourtes then peau else tenue.haut
		d.LeftArmColor = bras
		d.RightArmColor = bras
		d.LeftLegColor = tenue.bas
		d.RightLegColor = tenue.bas
		local corps = tenue.corps or {}
		d.HeightScale = corps.hauteur or 1
		d.WidthScale = corps.largeur or 1
		d.DepthScale = corps.largeur or 1
		d.HeadScale = corps.tete or 1
		d.BodyTypeScale = corps.silhouette or 0.3
		d.ProportionScale = corps.proportions or 0
		if niveau > 0 then
			-- acc = liste de {id, type} ; type = nom d'Enum.AccessoryType (Hair, Hat, Face, Jacket, Sweater, DressSkirt...)
			local liste = {}
			for i, a in acc do
				local okType, genre = pcall(function()
					return (Enum.AccessoryType :: any)[a[2]]
				end)
				local vetement = a[2] == "Jacket" or a[2] == "Sweater" or a[2] == "DressSkirt"
						or a[2] == "Shirt" or a[2] == "Pants" or a[2] == "Shorts" or a[2] == "TShirt"
				if okType and genre and (niveau == 2 or not vetement) then
					table.insert(liste, {AssetId = a[1], AccessoryType = genre, IsLayered = vetement, Order = if vetement then i else nil})
				end
			end
			d:SetAccessories(liste, true)
		end
		return d
	end

	local ok, rig
	for niveau = 2, 0, -1 do
		ok, rig = pcall(Players.CreateHumanoidModelFromDescription, Players, description(niveau), Enum.HumanoidRigType.R15)
		if ok then
			break
		end
		warn("[Monde] " .. nom .. " : habillage niveau " .. niveau .. " refusé (" .. tostring(rig) .. ")")
	end
	if not ok or not rig then
		warn("[Monde] Avatar impossible pour " .. nom .. " : " .. tostring(rig))
		return nil
	end

	local m: Model = rig
	m.Name = nom
	local humanoide = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	local racine = m:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoide.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoide.BreakJointsOnDeath = false
	racine.Anchored = true
	m:PivotTo(cf * CFrame.new(0, humanoide.HipHeight + racine.Size.Y / 2, 0))
	local plusBas = math.huge
	for _, nomPied in {"LeftFoot", "RightFoot"} do
		local pied = m:FindFirstChild(nomPied) :: BasePart?
		if pied then
			plusBas = math.min(plusBas, pied.Position.Y - pied.Size.Y / 2)
		end
	end
	if plusBas < math.huge then
		m:PivotTo(m:GetPivot() + Vector3.new(0, cf.Position.Y - plusBas, 0))
	end

	-- Outil dans la main (registre dans la main gauche)
	if tenue.outil then
		local mainNom = if tenue.outil == "registre" then "LeftHand" else "RightHand"
		local main = m:FindFirstChild(mainNom) :: BasePart?
		if main then
			local objet = O.modele(m, "Outil")
			outil(objet, main.CFrame * CFrame.new(0, -0.1, 0), tenue.outil)
			objet.WorldPivot = main.CFrame
			objet:ScaleTo(0.75)
			for _, p in objet:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored = false
					p.Massless = true
					local w = Instance.new("WeldConstraint")
					w.Part0 = main
					w.Part1 = p
					w.Parent = p
				end
			end
		end
	end

	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p ~= racine then
			p.CanCollide = false
		end
	end
	racine.CanCollide = true

	local tete = m:FindFirstChild("Head") :: BasePart
	O.etiquette(tete, nom, role, 2)
	m.Parent = parent

	-- Animation de repos (jouée côté serveur, visible par tous)
	local animateur = humanoide:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animateur.Parent = humanoide
	local anim = Instance.new("Animation")
	anim.AnimationId = ANIM_REPOS
	local okAnim, piste = pcall(function()
		return animateur:LoadAnimation(anim)
	end)
	if okAnim and piste then
		piste.Looped = true
		piste:Play(0, 1, 0.9 + math.random() * 0.2)
	end

	O.tag(m, "PNJ")
	m:SetAttribute("Role", role)
	O.atomique(m)
	print("[Monde] PNJ avatar " .. nom .. " prêt")
	return m
end

-- PNJ modélisé dans Blender (pièces « Nom_Groupe_Teinte »), recoloré selon la tenue
local function pnj3D(parent, cf, nom, role, tenue)
	local pieces = M3.pieces(nom)
	if not pieces then
		return nil
	end
	local tete, nez
	for _, p in pieces do
		local g, t = M3.groupe(p), M3.teinte(p)
		if g == "Tete" and t == "Peau" then
			tete = p
		elseif t == "Nez" then
			nez = p
		end
	end
	local pieds = M3.centre(pieces, {Bottes = true, Semelle = true})
	if not (tete and nez and pieds) then
		return nil
	end

	-- Repère du personnage dans l'espace d'import : haut = pieds -> tête, avant = vers le nez
	local haut = (tete.Position - pieds).Unit
	local avant = nez.Position - tete.Position
	avant = (avant - haut * avant:Dot(haut)).Unit
	local plusBas = 0
	for _, p in pieces do
		local d = p.Size / 2
		for _, sx in {-1, 1} do
			for _, sy in {-1, 1} do
				for _, sz in {-1, 1} do
					local c = p.CFrame:PointToWorldSpace(Vector3.new(d.X * sx, d.Y * sy, d.Z * sz))
					plusBas = math.min(plusBas, (c - tete.Position):Dot(haut))
				end
			end
		end
	end
	local base = tete.Position + haut * plusBas
	local S = CFrame.fromMatrix(base, haut:Cross(-avant), haut, -avant)
	local k = 3.9 / -plusBas -- nain : centre de la tête à ~3.9 studs du sol (un joueur en fait ~5)

	local peau = tenue.peau or Color3.fromRGB(226, 182, 150)
	local cheveux = tenue.cheveux or Color3.fromRGB(70, 48, 32)
	local bottes = tenue.bottes or Color3.fromRGB(56, 38, 28)
	local barbe = tenue.barbe or cheveux
	local chapeau = tenue.chapeau or Color3.fromRGB(70, 50, 36)
	local tablier = tenue.tablier or Color3.fromRGB(96, 66, 44)
	local tablierClair = tablier.R + tablier.G + tablier.B > 2
	local teintes = {
		Peau = {peau, M.Lisse}, Nez = {peau, M.Lisse},
		Haut = {tenue.haut, M.Tissu}, HautSombre = {sombre(tenue.haut, 0.3), M.Tissu},
		Bas = {tenue.bas, M.Tissu},
		Bottes = {bottes, M.Cuir}, Revers = {sombre(bottes, 0.25), M.Cuir}, Semelle = {Color3.fromRGB(30, 22, 18), M.Cuir},
		Ceinture = {tenue.ceinture or Color3.fromRGB(62, 42, 30), M.Cuir}, Boucle = {C.Or, M.Metal},
		Cheveux = {cheveux, M.Tissu}, Barbe = {barbe, M.Tissu}, Sourcils = {barbe, M.Tissu},
		Chapeau = {chapeau, M.Tissu}, Ruban = {sombre(chapeau, 0.35), M.Cuir},
		Tablier = {tablier, if tablierClair then M.Tissu else M.Cuir},
		TablierSombre = {sombre(tablier, 0.15), if tablierClair then M.Tissu else M.Cuir},
		Yeux = {Color3.fromRGB(244, 240, 232), M.Lisse}, Pupilles = {Color3.fromRGB(40, 30, 22), M.Lisse},
		Bouche = {Color3.fromRGB(126, 62, 56), M.Lisse},
		Bois = {C.Bois, M.Bois}, Metal = {Color3.fromRGB(150, 154, 162), M.Metal},
		Couverture = {Color3.fromRGB(120, 36, 32), M.Cuir}, Pages = {Color3.fromRGB(236, 224, 196), M.Lisse},
		Mousse = {Color3.fromRGB(246, 236, 210), M.Lisse},
		Joues = {peau:Lerp(Color3.fromRGB(210, 90, 80), 0.22), M.Lisse},
		Cuir = {Color3.fromRGB(92, 60, 38), M.Cuir},
		Acier = {Color3.fromRGB(120, 124, 132), M.Metal},
		Verre = {Color3.fromRGB(170, 210, 230), M.Verre},
		Foulard = {tenue.foulard or Color3.fromRGB(150, 60, 50), M.Tissu},
	}
	local function regler(c, nomTeinte)
		local t = teintes[nomTeinte]
		if t then
			c.Color = t[1]
			c.Material = t[2]
		end
		if nomTeinte == "Verre" then
			c.Transparency = 0.35
		end
		O.decor(c)
	end

	local m = O.modele(parent, nom)
	local groupes = {Corps = O.modele(m, "Corps"), Buste = O.modele(m, "Buste"), Tete = O.modele(m, "Tete")}
	for _, p in pieces do
		M3.poser({p}, S, cf, k, groupes[M3.groupe(p) or ""] or groupes.Buste, regler)
	end
	local teteClone = groupes.Tete:FindFirstChild(nom .. "_Tete_Peau") :: BasePart
	local busteClone = groupes.Buste:FindFirstChild(nom .. "_Buste_Haut") :: BasePart
	groupes.Tete.PrimaryPart = teteClone
	groupes.Buste.PrimaryPart = busteClone
	print(string.format("[Monde] PNJ 3D %s : %d pièces, échelle %.3f, tête à %s (sol %s)", nom, #pieces, k,
		tostring(teteClone and teteClone.Position), tostring(cf.Position)))

	-- boîte invisible pour qu'on ne traverse pas le PNJ
	local boite = O.bloc(m, Vector3.new(3, 4.6, 2.4), cf * CFrame.new(0, 2.3, 0), Color3.new(0, 0, 0), M.Lisse, "Collision")
	boite.Transparency = 1
	boite.CastShadow = false

	O.etiquette(teteClone, nom, role, 2.2)
	m.PrimaryPart = boite
	m.WorldPivot = cf
	O.tag(m, "PNJ")
	m:SetAttribute("Role", role)
	O.atomique(m)
	return m
end

function B.pnj(parent, cf, nom, role, tenue)
	local modele3D = pnj3D(parent, cf, nom, role, tenue)
	if modele3D then
		return modele3D
	end
	if tenue.avatar ~= false then
		local avatar = pnjAvatar(parent, cf, nom, role, tenue)
		if avatar then
			return avatar
		end
	end
	local m = O.modele(parent, nom)
	local corps = O.modele(m, "Corps")
	local buste = O.modele(m, "Buste")
	local tm = O.modele(m, "Tete")
	local peau = tenue.peau or Color3.fromRGB(226, 182, 150)
	local cheveux = tenue.cheveux or Color3.fromRGB(70, 48, 32)
	local bottes = tenue.bottes or Color3.fromRGB(56, 38, 28)
	local ceinture = tenue.ceinture or Color3.fromRGB(62, 42, 30)
	local haut = tenue.haut
	local bas = tenue.bas

	-- Jambes, bottes à revers
	for _, s in {-1, 1} do
		local x = s * 0.5
		O.bloc(corps, Vector3.new(1, 0.16, 1.34), cf * CFrame.new(x, 0.08, -0.12), Color3.fromRGB(30, 22, 18), M.Cuir, "Semelle")
		O.bloc(corps, Vector3.new(0.94, 0.85, 1.22), cf * CFrame.new(x, 0.58, -0.08), bottes, M.Cuir, "Botte")
		O.bloc(corps, Vector3.new(1.02, 0.24, 1.02), cf * CFrame.new(x, 1.06, 0), sombre(bottes, 0.25), M.Cuir, "Revers")
		O.bloc(corps, Vector3.new(0.84, 0.95, 0.84), cf * CFrame.new(x, 1.6, 0), bas, M.Tissu, "Mollet")
		O.bloc(corps, Vector3.new(0.94, 1.05, 0.94), cf * CFrame.new(x, 2.55, 0), sombre(bas, 0.05), M.Tissu, "Cuisse")
	end
	O.bloc(corps, Vector3.new(2, 0.38, 1.08), cf * CFrame.new(0, 3.1, 0), ceinture, M.Cuir, "Ceinture")
	O.decor(O.bloc(corps, Vector3.new(0.44, 0.32, 0.1), cf * CFrame.new(0, 3.1, -0.56), C.Or, M.Metal, "Boucle"))
	O.decor(O.bloc(corps, Vector3.new(0.5, 0.6, 0.35), cf * CFrame.new(0.82, 2.75, -0.35), ceinture, M.Cuir, "Bourse"))

	-- Buste : torse, col, bras
	O.bloc(buste, Vector3.new(1.9, 0.82, 0.98), cf * CFrame.new(0, 3.68, 0), haut, M.Tissu, "Ventre")
	local poitrine = O.bloc(buste, Vector3.new(2.1, 1.12, 1.06), cf * CFrame.new(0, 4.62, 0), haut, M.Tissu, "Poitrine")
	O.decor(O.bloc(buste, Vector3.new(1.1, 0.24, 0.98), cf * CFrame.new(0, 5.2, 0), sombre(haut, 0.3), M.Tissu, "Col"))
	O.decor(O.bloc(buste, Vector3.new(0.12, 1.3, 0.08), cf * CFrame.new(0, 4.4, -0.54), sombre(haut, 0.35), M.Tissu, "Couture"))
	O.decor(O.cylindre(buste, 0.45, 0.62, cf * CFrame.new(0, 5.4, 0), peau, M.Lisse, "Cou"))
	local mains = {}
	for _, s in {-1, 1} do
		O.ellipsoide(buste, Vector3.new(0.98, 0.88, 1.02), cf * CFrame.new(s * 1.3, 4.86, 0), haut, M.Tissu, "Epaule")
		local bras = cf * CFrame.new(s * 1.38, 4.25, 0) * CFrame.Angles(0, 0, s * 0.06)
		O.bloc(buste, Vector3.new(0.78, 1.05, 0.82), bras, haut, M.Tissu, "Bras")
		local avant = cf * CFrame.new(s * 1.45, 3.3, -0.06) * CFrame.Angles(0, 0, s * 0.04)
		O.bloc(buste, Vector3.new(0.72, 1.0, 0.76), avant, if tenue.manchesCourtes then peau else haut, if tenue.manchesCourtes then M.Lisse else M.Tissu, "AvantBras")
		if not tenue.manchesCourtes then
			O.decor(O.bloc(buste, Vector3.new(0.78, 0.2, 0.82), cf * CFrame.new(s * 1.46, 2.86, -0.06), sombre(haut, 0.3), M.Tissu, "Poignet"))
		end
		local main = cf * CFrame.new(s * 1.47, 2.5, -0.08)
		O.ellipsoide(buste, Vector3.new(0.62, 0.7, 0.66), main, peau, M.Lisse, "Main")
		mains[s] = main
	end
	if tenue.tablier then
		O.decor(O.bloc(buste, Vector3.new(1.86, 2.6, 0.12), cf * CFrame.new(0, 3.6, -0.58), tenue.tablier, M.Cuir, "Tablier"))
		O.decor(O.bloc(buste, Vector3.new(1.4, 0.7, 0.14), cf * CFrame.new(0, 3.3, -0.66), sombre(tenue.tablier, 0.15), M.Cuir, "Poche"))
		for _, s in {-1, 1} do
			O.decor(O.bloc(buste, Vector3.new(0.2, 0.75, 0.1), cf * CFrame.new(s * 0.55, 5.05, -0.56), tenue.tablier, M.Cuir, "Bretelle"))
		end
	end
	if tenue.outil == "registre" then
		outil(buste, mains[-1], tenue.outil)
	elseif tenue.outil then
		outil(buste, mains[1], tenue.outil)
	end

	-- Tête : visage, oreilles, cheveux, barbe, chapeau
	local t = cf * CFrame.new(0, 6.08, 0)
	local tete = O.bloc(tm, Vector3.new(1.22, 1.32, 1.2), t, peau, M.Lisse, "Tete")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Parent = tete
	for _, s in {-1, 1} do
		O.decor(O.ellipsoide(tm, Vector3.new(0.18, 0.38, 0.28), t * CFrame.new(s * 0.62, -0.05, 0.02), peau, M.Lisse, "Oreille"))
		O.decor(O.bloc(tm, Vector3.new(0.3, 0.2, 0.06), t * CFrame.new(s * 0.27, 0.1, -0.6), Color3.fromRGB(244, 240, 232), M.Lisse, "BlancOeil"))
		O.decor(O.bloc(tm, Vector3.new(0.14, 0.17, 0.07), t * CFrame.new(s * 0.27, 0.09, -0.62), Color3.fromRGB(46, 34, 24), M.Lisse, "Pupille"))
		O.decor(O.bloc(tm, Vector3.new(0.36, 0.09, 0.09), t * CFrame.new(s * 0.27, 0.29, -0.6) * CFrame.Angles(0, 0, -s * 0.12),
			tenue.barbe or cheveux, M.Tissu, "Sourcil"))
	end
	O.decor(O.bloc(tm, Vector3.new(0.22, 0.34, 0.26), t * CFrame.new(0, -0.08, -0.64), sombre(peau, 0.06), M.Lisse, "Nez"))
	O.decor(O.bloc(tm, Vector3.new(0.42, 0.07, 0.06), t * CFrame.new(0, -0.38, -0.6), Color3.fromRGB(126, 62, 56), M.Lisse, "Bouche"))
	coiffure(tm, t, if tenue.chapeau and tenue.coiffure ~= "long" then "court" else (tenue.coiffure or "court"), cheveux)
	if tenue.barbe then
		O.decor(O.bloc(tm, Vector3.new(1.12, 0.66, 0.5), t * CFrame.new(0, -0.55, -0.38), tenue.barbe, M.Tissu, "Barbe"))
		O.decor(O.bloc(tm, Vector3.new(0.74, 0.17, 0.16), t * CFrame.new(0, -0.27, -0.67), tenue.barbe, M.Tissu, "Moustache"))
		for _, s in {-1, 1} do
			O.decor(O.bloc(tm, Vector3.new(0.2, 0.6, 0.5), t * CFrame.new(s * 0.57, -0.2, -0.15), tenue.barbe, M.Tissu, "Favori"))
		end
		if tenue.barbeLongue then
			O.decor(O.bloc(tm, Vector3.new(0.9, 0.9, 0.42), t * CFrame.new(0, -1.15, -0.5) * CFrame.Angles(-0.12, 0, 0), tenue.barbe, M.Tissu, "BarbeLongue"))
			O.decor(O.bloc(tm, Vector3.new(0.5, 0.5, 0.36), t * CFrame.new(0, -1.75, -0.55) * CFrame.Angles(-0.15, 0, 0), tenue.barbe, M.Tissu, "Pointe"))
		end
	end
	if tenue.chapeau then
		O.decor(O.cylindre(tm, 0.14, 2.3, t * CFrame.new(0, 0.72, 0), tenue.chapeau, M.Tissu, "Bord"))
		O.decor(O.cylindre(tm, 0.85, 1.38, t * CFrame.new(0, 1.12, 0), tenue.chapeau, M.Tissu, "Calotte"))
		O.decor(O.cylindre(tm, 0.18, 1.42, t * CFrame.new(0, 0.86, 0), sombre(tenue.chapeau, 0.35), M.Cuir, "Ruban"))
	end
	O.etiquette(tete, nom, role, 2.2)

	-- Mise à l'échelle d'un personnage Roblox, les pieds restent au sol
	tm.PrimaryPart = tete
	buste.PrimaryPart = poitrine
	m.WorldPivot = cf
	m:ScaleTo(0.82)

	O.tag(m, "PNJ")
	m:SetAttribute("Role", role)
	O.atomique(m)
	return m
end

return B
