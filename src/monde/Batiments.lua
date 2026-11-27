-- Bâtiments et accessoires : maisons à colombages, échoppes, forge, wagonnets, arbres, cristaux, PNJ...
-- Convention : chaque fonction reçoit un CFrame posé au sol ; -Z (LookVector) = la façade / l'avant.
local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local Lampadaires = require(script.Parent.Lampadaires)
local M, C = O.M, O.C

local B = {}
local HE = 10 -- hauteur d'un étage
local FORGE_DEBORD_TOIT = 1.2
local FORGE_PENTE_TOIT = 7 / 9.8
local FORGE_TOLERANCE_MUR = 0.05

-- ================= Lumières =================

local function cage(parent, cf, couleur, portee)
	return Lampadaires.lanterne(parent, cf, couleur, portee)
end

-- Les modèles utilisent les proportions de l'aperçu validé.
function B.lanterne(parent, cf, hauteur)
	local origine = cf.Position
	local filtre = RaycastParams.new()
	filtre.RespectCanCollide = true
	local sol = workspace:Raycast(origine + Vector3.yAxis * 8, -Vector3.yAxis * 30, filtre)
	local position = if sol then Vector3.new(origine.X, sol.Position.Y, origine.Z) else origine
	return Lampadaires.lampadaire(parent, CFrame.new(position) * cf.Rotation)
end

function B.suspension(parent, haut, longueur, couleur, portee)
	local m = O.modele(parent, "Suspension")
	O.decor(O.bloc(m, Vector3.new(0.15, longueur, 0.15), CFrame.new(haut - Vector3.new(0, longueur / 2, 0)), C.Fer, M.Metal, "Chaine"))
	cage(m, CFrame.new(haut - Vector3.new(0, longueur + 0.95, 0)), couleur, portee)
	return m
end

function B.applique(parent, cf)
	O.decor(O.bloc(parent, Vector3.new(0.3, 0.3, 1.2), cf * CFrame.new(0, 0.9, -0.6), C.Fer, M.Metal, "Support"))
	return cage(parent, cf * CFrame.new(0, 0.2, -1.2), C.Lumiere, 16)
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
	-- Ferrures plaquées : elles ne gênent ni l'accès ni les interactions.
	for _, y in {1.4, 5.6} do
		O.decor(O.bloc(parent, Vector3.new(1.15, 0.18, 0.08), cf * CFrame.new(-0.95, y, -0.34), C.Fer, M.Metal, "FerrurePorte"))
	end
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
			for _, y in {-1.05, 1.05} do
				O.decor(O.bloc(parent, Vector3.new(1, 0.12, 0.08), cf * CFrame.new(x, y, -0.36), C.Fer, M.Metal, "FerrureVolet"))
			end
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

-- Auberge modélisée dans Blender (blender/auberge.py, assets/Auberge.fbx), copie de previews/auberge/reference.png.
-- Couleurs de référence ; le plâtre, les tuiles et les volets prennent un peu de la teinte de chaque maison.
local REF_AUBERGE = {
	Pierre = {Color3.fromRGB(112, 108, 100), M.Pierre}, PierreSombre = {Color3.fromRGB(80, 78, 74), M.Pierre},
	PierreClaire = {Color3.fromRGB(146, 138, 124), M.Pierre}, Mortier = {Color3.fromRGB(70, 66, 60), M.Pierre},
	Cheminee = {Color3.fromRGB(172, 166, 158), M.Pierre},
	Platre = {Color3.fromRGB(234, 224, 202), M.Platre},
	Colombage = {Color3.fromRGB(72, 48, 32), M.Bois}, Planches = {Color3.fromRGB(98, 68, 44), M.Planches},
	Tuiles = {Color3.fromRGB(172, 104, 56), M.Tuiles}, TuilesClaires = {Color3.fromRGB(198, 128, 70), M.Tuiles},
	TuilesSombres = {Color3.fromRGB(132, 78, 44), M.Tuiles},
	Vitre = {Color3.fromRGB(54, 84, 150), M.Verre}, Plomb = {Color3.fromRGB(196, 200, 210), M.Metal},
	VitreAllumee = {C.Fenetre, M.Neon},
	Volets = {Color3.fromRGB(110, 68, 38), M.Planches}, Porte = {Color3.fromRGB(102, 62, 36), M.Planches},
	Fer = {C.Fer, M.Metal}, Tonneau = {Color3.fromRGB(142, 98, 58), M.Bois}, Pot = {Color3.fromRGB(178, 94, 58), M.Lisse},
	Feuillage = {Color3.fromRGB(58, 94, 42), M.Lisse}, Lierre = {Color3.fromRGB(64, 104, 44), M.Lisse},
	LierreClair = {Color3.fromRGB(108, 140, 58), M.Lisse},
	Fleurs = {Color3.fromRGB(198, 40, 42), M.Lisse}, FleursClaires = {Color3.fromRGB(236, 206, 214), M.Lisse},
}
-- Groupes sans collision (décor, végétation, menuiseries) : on circule librement devant la maison
local GROUPES_DECOR = {Decor = true, Fleurs = true, Lierre = true, Auvent = true, Fenetres = true, Porte = true}

-- Renvoie le modèle, le CFrame du bas de la porte (sur la façade) et celui de l'enseigne, ou nil sans import.
local function auberge3D(parent, cf, o)
	local pieces = M3.pieces("Auberge")
	if not pieces then
		return nil
	end
	local battant
	for _, p in pieces do
		if M3.groupe(p) == "Porte" and M3.teinte(p) == "Porte" then
			battant = p
		end
	end
	if not battant then
		local noms = {}
		for i = 1, math.min(6, #pieces) do
			table.insert(noms, pieces[i].Name)
		end
		warn("[Auberge] pièce Auberge_Porte_Porte introuvable : maisons en blocs. Exemples : " .. table.concat(noms, ", "))
		return nil
	end
	local mn, mx = M3.boite(pieces)
	local centre = (mn + mx) / 2
	-- l'avant : l'axe horizontal le plus fin du battant de porte, tourné vers l'extérieur
	local avant = battant.CFrame.LookVector
	local fin = battant.Size.Z
	if battant.Size.X < fin and math.abs(battant.CFrame.RightVector.Y) < 0.5 then
		avant, fin = battant.CFrame.RightVector, battant.Size.X
	end
	avant = Vector3.new(avant.X, 0, avant.Z).Unit
	if (battant.Position - centre):Dot(avant) < 0 then
		avant = -avant
	end
	local droite = Vector3.yAxis:Cross(-avant)
	local S = CFrame.fromMatrix(Vector3.new(centre.X, mn.Y, centre.Z), droite, Vector3.yAxis, -avant)
	-- même largeur de rue que les maisons en blocs, sans rendre la porte ridicule
	local k = o.echelle or math.clamp((o.largeur or 18) / 28, 0.65, 0.9) -- o.echelle : bâtiments des vendeurs, plus grands

	local rng = o.rng or Random.new()
	local mur = (o.mur or C.Platre)
	local toit = o.toit or C.Toit
	local volet = o.volet or C.Volet
	local m = O.modele(parent, o.nom or "Maison")
	local clones = M3.poser(pieces, S, cf, k, m, function(c, teinte)
		local t = REF_AUBERGE[teinte]
		if t then
			local couleur = t[1]
			if teinte == "Platre" then
				couleur = couleur:Lerp(mur, 0.35)
			elseif string.sub(teinte, 1, 6) == "Tuiles" then
				couleur = couleur:Lerp(toit, 0.2)
			elseif teinte == "Volets" then
				couleur = couleur:Lerp(volet, 0.45)
			end
			c.Color = couleur
			c.Material = t[2]
		end
		if teinte == "Vitre" then
			c.Transparency = 0.15
		end
		if GROUPES_DECOR[M3.groupe(c) or ""] then
			O.decor(c)
		end
	end)

	local porteCF = cf
	for _, c in clones do
		local groupe, teinte = M3.groupe(c), M3.teinte(c)
		if groupe == "Porte" and teinte == "Porte" then
			local p = c.Position
			porteCF = CFrame.new(p.X, cf.Position.Y + 1.6, p.Z) * cf.Rotation * CFrame.new(0, 0, -0.4 * k)
		elseif teinte == "VitreAllumee" and rng:NextNumber() < 0.7 then
			O.lumiere(c, C.Fenetre, 0.8, 14)
		elseif teinte == "Cheminee" and o.cheminee ~= false then
			local sommet = O.bloc(m, Vector3.new(1, 0.2, 1), CFrame.new(c.Position + Vector3.new(0, c.Size.Y / 2 + 0.2, 0)),
				C.PierreFoncee, M.Pierre, "SortieFumee")
			sommet.Transparency = 1
			O.decor(sommet)
			O.fumee(sommet, 1.5)
		end
	end
	local enseigneCF = porteCF * CFrame.new(0, 7.0 * k + 0.5, -0.5)
	if o.enseigne then
		B.fronton(m, enseigneCF, o.enseigne, 9)
	end
	return m, porteCF, enseigneCF, 9
end

--[[ Maisons en blocs Roblox, dans le style de l'auberge (previews/auberge/reference.png) :
	rez-de-chaussée en pierre, colombages sur plâtre clair, toits de tuiles orangées, porte en arc, lierre, fleurs.
	4 modèles (o.modele) :
		1 l'auberge : petit pignon à gauche, toit central avec lucarne, grand pignon en avancée à droite, auvent ;
		2 grand pignon central en avancée, toits latéraux avec lucarnes, pignons d'extrémité ;
		3 étage entier à colombages en encorbellement, rangée de fenêtres, lucarnes ;
		4 pignon sur rue (un seul grand pignon) et appentis à bois sur le côté.
	o.prestige (maisons des PNJ) : porche couvert, lanternes, bannières (o.couleur), potence, rez-de-chaussée plus haut.
	« gauche / droite » = vu de face par quelqu'un qui regarde la façade (la droite de l'observateur est -X local). ]]
local COUL_AUBERGE = {
	Pierre = Color3.fromRGB(112, 108, 100), PierreSombre = Color3.fromRGB(84, 80, 76), PierreClaire = Color3.fromRGB(150, 142, 128),
	Bois = Color3.fromRGB(72, 48, 32), Planches = Color3.fromRGB(98, 68, 44), Porte = Color3.fromRGB(102, 62, 36),
	Volets = Color3.fromRGB(110, 68, 38), Vitre = Color3.fromRGB(54, 84, 150), Plomb = Color3.fromRGB(196, 200, 210),
	Feuillage = Color3.fromRGB(58, 94, 42), Fleur = Color3.fromRGB(198, 40, 42), FleurClaire = Color3.fromRGB(236, 206, 214),
	FleurJaune = Color3.fromRGB(240, 196, 60),
}
local TUILES_REF = Color3.fromRGB(184, 112, 58)
local PLATRE_REF = Color3.fromRGB(234, 224, 202)

-- Segment 2D coupé à un rectangle (croisillons en losange)
local function couper(x0, y0, x1, y1, xmin, xmax, ymin, ymax)
	local dx, dy = x1 - x0, y1 - y0
	local t0, t1 = 0, 1
	for _, pq in {{-dx, x0 - xmin}, {dx, xmax - x0}, {-dy, y0 - ymin}, {dy, ymax - y0}} do
		local p, q = pq[1], pq[2]
		if p == 0 then
			if q < 0 then
				return nil
			end
		else
			local r = q / p
			if p < 0 then
				t0 = math.max(t0, r)
			else
				t1 = math.min(t1, r)
			end
			if t0 > t1 then
				return nil
			end
		end
	end
	return x0 + dx * t0, y0 + dy * t0, x0 + dx * t1, y0 + dy * t1
end

--[[ Boîte à outils d'une maison : toutes les positions sont dans le repère de cf,
	avec V(xv, y, z) où xv = abscisse vue de face (vers la droite de l'observateur). ]]
local function kitMaison(m, cf, o)
	local K = {}
	local rng = o.rng or Random.new()
	local UP = Vector3.yAxis
	K.rng, K.UP = rng, UP
	K.X, K.Z = Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	K.prestige = o.prestige == true
	K.platre = PLATRE_REF:Lerp(o.mur or C.Platre, 0.3)
	K.tuiles = TUILES_REF:Lerp(o.toit or C.Toit, if K.prestige then 0.08 else 0.18)
	K.tuilesSombres = K.tuiles:Lerp(Color3.new(0, 0, 0), 0.25)
	K.volets = COUL_AUBERGE.Volets:Lerp(o.volet or C.Volet, 0.45)
	K.couleur = o.couleur or Color3.fromRGB(150, 40, 40)

	local function V(xv, y, z)
		return Vector3.new(-xv, y, z)
	end
	K.V = V
	function K.poser(taille, centre, vx, vy, couleur, mat, nom)
		return O.bloc(m, taille, cf * CFrame.fromMatrix(centre, vx, vy), couleur, mat, nom)
	end
	function K.poutre(a, b, larg, ep, normale, couleur, mat, nom)
		local d = b - a
		local lg = math.max(d.Magnitude, 0.05)
		local uz = if d.Magnitude > 1e-4 then d.Unit else Vector3.yAxis
		local uy = (normale - uz * normale:Dot(uz)).Unit
		local ux = uy:Cross(uz)
		return O.bloc(m, Vector3.new(larg, ep, lg), cf * CFrame.fromMatrix((a + b) / 2, ux, uy, uz),
			couleur or COUL_AUBERGE.Bois, mat or M.Bois, nom or "Colombage")
	end
	function K.bloc(taille, centre, couleur, mat, nom)
		return O.bloc(m, taille, cf * CFrame.new(centre), couleur, mat, nom)
	end
	local bloc, poutre, poser = K.bloc, K.poutre, K.poser

	-- Mur de pierre plein (collisions) ; centre en coordonnées vues de face
	function K.murs(taille, centre)
		return bloc(taille, centre, COUL_AUBERGE.Pierre, M.Pierre, "Murs")
	end
	-- Zones réservées sur les façades (portes, fenêtres, portillons) : ni pierres en relief ni lierre dessus
	K.trous = {}
	function K.trou(x0, x1, y0, y1, z)
		table.insert(K.trous, {x0, x1, y0, y1, z})
	end
	local function libre(x0, x1, y0, y1, z)
		for _, t in K.trous do
			if math.abs(t[5] - z) < 1.6 and x1 > t[1] and x0 < t[2] and y1 > t[3] and y0 < t[4] then
				return false
			end
		end
		return true
	end
	-- Pierres en relief sur une façade tournée vers -Z (z = plan de la façade).
	-- Posées à la fin (K.poserPierres), une fois toutes les ouvertures connues.
	local demandesPierres = {}
	function K.pierres(x0, x1, z, y0, y1, nb)
		table.insert(demandesPierres, {x0, x1, z, y0, y1, nb})
	end
	function K.poserPierres()
		for _, d in demandesPierres do
			local x0, x1, z, y0, y1, nb = table.unpack(d)
			for _ = 1, nb do
				local w, h = rng:NextNumber(0.9, 1.8), rng:NextNumber(0.6, 1)
				local x, y = x0 + (x1 - x0) * rng:NextNumber(0.05, 0.95), rng:NextNumber(y0 + 0.4, y1 - 0.5)
				local c = rng:NextNumber(0, 1)
				if x - w / 2 > x0 and x + w / 2 < x1 and libre(x - w / 2, x + w / 2, y - h / 2, y + h / 2, z) then
					O.decor(bloc(Vector3.new(w, h, 0.3), V(x, y, z - 0.1),
						if c < 0.4 then COUL_AUBERGE.PierreSombre elseif c < 0.7 then COUL_AUBERGE.PierreClaire else COUL_AUBERGE.Pierre,
						M.Pierre, "Pierre"))
				end
			end
		end
		table.clear(demandesPierres)
	end

	-- Massif de feuillage et de fleurs le long de x0..x1 (hauteur y, plan z)
	function K.fleurs(x0, x1, y, z, densite)
		for _ = 1, math.floor((x1 - x0) * (densite or 2.4)) do
			local x = rng:NextNumber(x0 + 0.3, x1 - 0.3)
			local s = rng:NextNumber(0.6, 1.0)
			O.decor(O.ellipsoide(m, Vector3.new(s, s * 0.8, s), cf * CFrame.new(V(x, y, z + rng:NextNumber(-0.25, 0.25))),
				COUL_AUBERGE.Feuillage, M.Herbe, "Feuillage"))
			local t = rng:NextNumber()
			O.decor(O.ellipsoide(m, Vector3.new(0.35, 0.35, 0.35), cf * CFrame.new(V(x + rng:NextNumber(-0.3, 0.3), y + 0.35, z - 0.35)),
				if t < 0.65 then COUL_AUBERGE.Fleur elseif t < 0.85 then COUL_AUBERGE.FleurClaire else COUL_AUBERGE.FleurJaune, M.Lisse, "Fleur"))
		end
	end
	function K.jardiniere(x0, x1, y, z)
		O.decor(bloc(Vector3.new(x1 - x0, 0.7, 0.9), V((x0 + x1) / 2, y, z - 0.45), COUL_AUBERGE.Bois, M.Bois, "Jardiniere"))
		K.fleurs(x0, x1, y + 0.6, z - 0.5)
	end
	function K.muretFleuri(x0, x1, z)
		if x1 - x0 < 2 then
			return
		end
		bloc(Vector3.new(x1 - x0, 2.4, 1.3), V((x0 + x1) / 2, 1.2, z - 0.65), COUL_AUBERGE.PierreSombre, M.Pierre, "Muret")
		K.fleurs(x0, x1, 2.75, z - 0.65, 3)
	end

	-- Fenêtre sur une façade tournée vers -Z (losange : vitraux en losanges ; voletsCote : {-1, 1})
	function K.fenetre(xv, yc, z, w, h, losange, voletsCote, allumee, jardiniere)
		local demi = w / 2 + 0.5 + (if voletsCote and #voletsCote > 0 then w / 2 + 0.7 else 0)
		K.trou(xv - demi, xv + demi, yc - h / 2 - 1.6, yc + h / 2 + 0.5, z)
		local c = V(xv, yc, z)
		local n = Vector3.new(0, 0, -1)
		local vitre = bloc(Vector3.new(w, h, 0.2), c + n * 0.05, if allumee then C.Fenetre else COUL_AUBERGE.Vitre,
			if allumee then M.Neon else M.Verre, "Vitre")
		if allumee then
			vitre.Transparency = 0.2
			if rng:NextNumber() < 0.6 then
				O.lumiere(vitre, C.Fenetre, 0.8, 12)
			end
		end
		local plomb = if allumee then COUL_AUBERGE.Bois else COUL_AUBERGE.Plomb
		if losange then
			for k = -3, 3 do
				for _, s in {1, -1} do
					local x0, y0, x1, y1 = couper(-w, -w * s + k * 0.7, w, w * s + k * 0.7, -w / 2 + 0.05, w / 2 - 0.05, -h / 2 + 0.05, h / 2 - 0.05)
					if x0 then
						O.decor(poutre(c + V(x0, y0, -0.17), c + V(x1, y1, -0.17), 0.07, 0.05, n, plomb, M.Metal, "Plomb"))
					end
				end
			end
		else
			O.decor(bloc(Vector3.new(0.1, h, 0.06), c + n * 0.17, plomb, M.Metal, "Plomb"))
			for _, y in {-h / 6, h / 6} do
				O.decor(bloc(Vector3.new(w, 0.1, 0.06), c + n * 0.17 + UP * y, plomb, M.Metal, "Plomb"))
			end
		end
		for _, s in {-1, 1} do
			bloc(Vector3.new(0.35, h + 0.35, 0.4), c + V(s * (w / 2 + 0.17), 0, -0.1), COUL_AUBERGE.Bois, M.Bois, "Cadre")
		end
		bloc(Vector3.new(w + 0.7, 0.35, 0.4), c + UP * (h / 2 + 0.17) + n * 0.1, COUL_AUBERGE.Bois, M.Bois, "Cadre")
		bloc(Vector3.new(w + 0.9, 0.3, 0.7), c - UP * (h / 2 + 0.17) + n * 0.25, COUL_AUBERGE.Bois, M.Bois, "Appui")
		for _, s in voletsCote or {} do
			local ws = w / 2 + 0.2
			local cv = c + V(s * (w / 2 + 0.38 + ws / 2), 0, -0.12)
			O.decor(bloc(Vector3.new(ws, h + 0.2, 0.16), cv, K.volets, M.Planches, "Volet"))
			for _, y in {-h * 0.3, h * 0.3} do
				O.decor(bloc(Vector3.new(ws - 0.05, 0.22, 0.08), cv + UP * y + n * 0.1, COUL_AUBERGE.Bois, M.Bois, "Traverse"))
			end
		end
		if jardiniere or (K.prestige and yc < 8) then
			K.jardiniere(xv - w / 2 - 0.2, xv + w / 2 + 0.2, yc - h / 2 - 0.75, z)
		end
	end

	--[[ Pignon à colombages : base = milieu du bas (face extérieure du plâtre), u = horizontale dans le plan,
		n = normale extérieure. fen : 0, 1 ou 2 fenêtres dans la bande du milieu ; fenHaut : petite fenêtre en haut. ]]
	function K.pignon(base, u, n, hw, H, fen, fenHaut, sansEncorbellement)
		local function P2(x, y, off)
			return base + u * x + UP * y + n * (off or 0)
		end
		for _, s in {-1, 1} do
			local vz = -u * s -- la pente du coin descend vers l'extérieur
			O.coin(m, Vector3.new(0.4, H, hw), cf * CFrame.fromMatrix(P2(s * hw / 2, H / 2, -0.2), UP:Cross(vz), UP, vz), K.platre, M.Platre, "Pignon")
		end
		local function top(x)
			return H * (1 - math.abs(x) / hw)
		end
		poutre(P2(-hw - 0.4, -0.3, 0.1), P2(hw + 0.4, -0.3, 0.1), 0.6, 0.55, n)
		for _, f in {0.28, 0.58, 0.8} do
			local e = hw * (1 - f) - 0.1
			poutre(P2(-e, H * f, 0.15), P2(e, H * f, 0.15), 0.38, 0.3, n)
		end
		local function poteau(x, ya, yb)
			yb = math.min(yb, top(x) - 0.15)
			if yb - ya > 0.3 then
				poutre(P2(x, ya, 0.15), P2(x, yb, 0.15), 0.36, 0.3, n)
			end
		end
		for _, f in {-0.85, -0.55, -0.25, 0.25, 0.55, 0.85} do
			poteau(hw * f, 0, H * 0.28)
		end
		-- bande du milieu : fenêtres
		local fenetres = {}
		local wf = if fen == 2 then math.min(1.8, hw * 0.4) else math.min(2.2, hw * 0.6)
		if fen == 2 then
			fenetres = {-hw * 0.33, hw * 0.33}
			for _, f in {0, -0.72, 0.72} do
				poteau(hw * f, H * 0.28, H * 0.58)
			end
		else
			if fen == 1 then
				fenetres = {0}
			else
				poteau(0, H * 0.28, H * 0.58)
			end
			for _, f in {-0.7, -0.38, 0.38, 0.7} do
				poteau(hw * f, H * 0.28, H * 0.58)
			end
		end
		local hautes = {}
		if fenHaut and hw * 0.5 > 1.0 then
			hautes = {0}
			for _, f in {-0.3, 0.3} do
				poteau(hw * f, H * 0.58, H * 0.8)
			end
		else
			for _, f in {-0.22, 0, 0.22} do
				poteau(hw * f, H * 0.58, H * 0.8)
			end
		end
		poteau(0, H * 0.8, H)
		for _, s in {-1, 1} do
			poutre(P2(s * hw * 0.55, 0, 0.15), P2(s * hw * 0.85, H * 0.27, 0.15), 0.3, 0.28, n)
		end
		for _, s in {-1, 1} do
			poutre(P2(s * hw, 0, 0.15), P2(0, H, 0.15), 0.45, 0.32, n)
		end
		if not sansEncorbellement then
			local k = -hw + 0.5
			while k < hw - 0.3 do
				O.decor(poutre(P2(k, -0.8, -0.7), P2(k, -0.8, 0.2), 0.3, 0.4, UP))
				k += 1.1
			end
			for _, s in {-1, 1} do
				O.decor(poutre(P2(s * (hw - 0.5), -2.2, -0.75), P2(s * (hw - 0.2), -0.6, 0), 0.3, 0.3, n))
			end
		end
		local function vitre(x, y0, y1, w)
			local c = P2(x, (y0 + y1) / 2, 0.1)
			local hf = (y1 - y0) - 0.5
			if hf < 0.6 then
				return
			end
			O.decor(O.bloc(m, Vector3.new(w, hf, 0.2), cf * CFrame.fromMatrix(c, u, UP), COUL_AUBERGE.Vitre, M.Verre, "Vitre"))
			poutre(c + UP * (-hf / 2) + n * 0.12, c + UP * (hf / 2) + n * 0.12, 0.1, 0.06, n, COUL_AUBERGE.Plomb, M.Metal, "Plomb")
			for _, y in {-hf / 6, hf / 6} do
				poutre(c + UP * y - u * (w / 2) + n * 0.12, c + UP * y + u * (w / 2) + n * 0.12, 0.1, 0.06, n, COUL_AUBERGE.Plomb, M.Metal, "Plomb")
			end
			for _, s in {-1, 1} do
				poutre(c + u * (s * (w / 2 + 0.15)) - UP * (hf / 2 + 0.2) + n * 0.1, c + u * (s * (w / 2 + 0.15)) + UP * (hf / 2 + 0.2) + n * 0.1, 0.3, 0.32, n)
			end
		end
		for _, x in fenetres do
			vitre(x, H * 0.28, H * 0.58, wf)
		end
		for _, x in hautes do
			vitre(x, H * 0.58, H * 0.8, math.min(1.4, hw * 0.35))
		end
	end

	-- Pan de toit : bas = milieu du bord bas (sur le mur), haut = milieu du faîtage ; axe = sens du faîtage
	function K.pan(bas, haut, axe, longueur, debord)
		local d = (haut - bas).Unit
		local nrm = axe:Cross(d)
		if nrm.Y < 0 then
			nrm = -nrm
		end
		local debut = bas - d * debord
		local lg = (haut - debut).Magnitude
		local centre = (debut + haut) / 2 + nrm * 0.4
		poser(Vector3.new(longueur, 0.6, lg), centre, axe, nrm, K.tuiles, M.Tuiles, "Toit")
		local s = 0.9
		while s < lg - 0.4 do
			O.decor(poser(Vector3.new(longueur, 0.18, 0.35), debut + d * s + nrm * 0.75, axe, nrm, K.tuilesSombres, M.Tuiles, "RangTuiles"))
			s += 1.15
		end
		for _, sg in {-1, 1} do
			O.decor(poser(Vector3.new(0.35, 0.35, lg), centre + axe * (sg * (longueur / 2 - 0.1)) + nrm * 0.3, axe, nrm, COUL_AUBERGE.Bois, M.Bois, "RiveToit"))
		end
	end
	function K.faitage(a, b)
		local d = b - a
		return O.bloc(m, Vector3.new(0.9, 0.9, d.Magnitude), cf * CFrame.lookAt((a + b) / 2 + UP * 0.45, b + UP * 0.45) * CFrame.Angles(0, 0, math.pi / 4),
			K.tuilesSombres, M.Tuiles, "Faitage")
	end
	-- Toit à deux pans, faîtage parallèle à la façade (x de xa à xb, mur avant zAv, mur arrière zAr)
	function K.toitX(xa, xb, zAv, zAr, yBas, yHaut, debord)
		local xm, lg = (xa + xb) / 2, math.abs(xb - xa)
		local zm = (zAv + zAr) / 2
		K.pan(V(xm, yBas, zAv), V(xm, yHaut, zm), K.X, lg, debord)
		K.pan(V(xm, yBas, zAr), V(xm, yHaut, zm), K.X, lg, debord)
		K.faitage(V(xa, yHaut, zm), V(xb, yHaut, zm))
	end
	-- Toit à deux pans, faîtage perpendiculaire à la façade (axe xc, demi-largeur hw, de z0 à z1)
	function K.toitZ(xc, hw, z0, z1, yBas, yHaut, debord)
		local zm, lg = (z0 + z1) / 2, math.abs(z1 - z0)
		K.pan(V(xc - hw, yBas, zm), V(xc, yHaut, zm), K.Z, lg, debord)
		K.pan(V(xc + hw, yBas, zm), V(xc, yHaut, zm), K.Z, lg, debord)
		K.faitage(V(xc, yHaut, z0), V(xc, yHaut, z1))
	end

	-- Lucarne sur un pan avant (toit à faîtage parallèle à la façade : mur avant zF à yBas, faîtage z = zR à yR)
	function K.lucarne(xc, w, zF, yBas, zR, yR, nbFen)
		local pente = (yR - yBas) / (zR - zF)
		local zd = zF + 0.35 * (zR - zF)
		local yb = yBas + 0.35 * (yR - yBas) - 0.4
		local ye = yb + 3.0
		local ya = math.min(ye + 2.0, yR - 0.4)
		if ya - ye < 0.8 then
			return
		end
		local prof = zR - zd
		bloc(Vector3.new(w, ye - yb, prof), V(xc, (yb + ye) / 2, zd + prof / 2), COUL_AUBERGE.Bois, M.Planches, "Lucarne")
		for _, s in {-1, 1} do
			local vz = Vector3.new(-s, 0, 0)
			O.coin(m, Vector3.new(0.3, ya - ye, w / 2), cf * CFrame.fromMatrix(V(xc, (ye + ya) / 2, zd - 0.05) + Vector3.new(s * w / 4, 0, 0),
				UP:Cross(vz), UP, vz), COUL_AUBERGE.Bois, M.Planches, "Lucarne")
		end
		if nbFen == 2 then
			for _, s in {-1, 1} do
				K.fenetre(xc + s * w * 0.22, (yb + ye) / 2 + 0.1, zd, math.min(1.6, w * 0.26), 2.0, false, {s})
			end
		else
			K.fenetre(xc, (yb + ye) / 2 + 0.1, zd, math.min(1.6, w * 0.4), 2.0, false, if w >= 4 then {-1, 1} else nil)
		end
		local zm = zd + prof / 2 - 0.5
		K.pan(V(xc - w / 2, ye, zm), V(xc, ya, zm), K.Z, prof + 1.2, 0.8)
		K.pan(V(xc + w / 2, ye, zm), V(xc, ya, zm), K.Z, prof + 1.2, 0.8)
		K.faitage(V(xc, ya, zd - 0.9), V(xc, ya, zR))
		return pente
	end

	function K.cheminee(xv, z, yBase, yTop)
		local h = yTop - yBase
		bloc(Vector3.new(2, h, 2), V(xv, yBase + h / 2, z), COUL_AUBERGE.PierreClaire, M.Pierre, "Cheminee")
		local chapeau = bloc(Vector3.new(2.5, 0.45, 2.5), V(xv, yTop + 0.22, z), COUL_AUBERGE.PierreSombre, M.Pierre, "Chapeau")
		O.fumee(chapeau, 1.5)
	end

	-- Porte en arc sur une façade tournée vers -Z, avec perron ; renvoie le CFrame du bas de la porte
	function K.porte(xP, z, wP)
		wP = wP or 3
		local yArc = 6.4
		K.trou(xP - wP / 2 - 1.6, xP + wP / 2 + 1.6, 0, yArc + wP / 2 + 1.0, z)
		bloc(Vector3.new(wP, yArc - 1.2, 0.3), V(xP, (1.2 + yArc) / 2, z - 0.05), COUL_AUBERGE.Porte, M.Planches, "Porte")
		O.disque(m, 0.3, wP, cf * CFrame.new(V(xP, yArc, z - 0.05)) * CFrame.Angles(0, math.pi / 2, 0), COUL_AUBERGE.Porte, M.Planches, "Porte")
		O.disque(m, 0.2, wP + 1.1, cf * CFrame.new(V(xP, yArc, z + 0.02)) * CFrame.Angles(0, math.pi / 2, 0), COUL_AUBERGE.PierreSombre, M.Pierre, "Arc")
		for _, s in {-1, 1} do
			bloc(Vector3.new(0.5, yArc - 1.2, 0.45), V(xP + s * (wP / 2 + 0.25), (1.2 + yArc) / 2, z - 0.1), COUL_AUBERGE.PierreSombre, M.Pierre, "Piedroit")
		end
		for _, y in {2.6, 5.2} do
			O.decor(bloc(Vector3.new(wP - 1, 0.2, 0.1), V(xP - 0.3, y, z - 0.25), C.Fer, M.Metal, "Penture"))
		end
		O.decor(bloc(Vector3.new(0.25, 0.25, 0.15), V(xP + wP / 2 - 0.55, 4, z - 0.25), C.Fer, M.Metal, "Poignee"))
		for i = 1, 3 do
			local h = 1.2 - (i - 1) * 0.4
			bloc(Vector3.new(wP + 1.2 + i * 0.5, h, 1.0), V(xP, h / 2, z - (i - 0.5) * 1.0), COUL_AUBERGE.PierreClaire, M.Pierre, "Marche")
		end
		if K.prestige then
			K.porche(xP, z, wP)
		end
		-- hauteur 1.6 comme les anciennes maisons : le village pose tonneaux et caisses par rapport à la porte
		return cf * CFrame.new(V(xP, 1.6, z))
	end

	-- Porche couvert à deux poteaux et lanternes (maisons des PNJ)
	function K.porche(xP, z, wP)
		local d = wP / 2 + 1.0
		local zp = z - 3.0
		for _, s in {-1, 1} do
			bloc(Vector3.new(0.5, 7.6, 0.5), V(xP + s * d, 3.8, zp), COUL_AUBERGE.Bois, M.Bois, "Poteau")
			O.decor(poutre(V(xP + s * d, 6.6, zp), V(xP + s * d, 7.7, zp + 1.1), 0.25, 0.25, K.X))
			poutre(V(xP + s * d, 7.75, zp - 0.3), V(xP + s * d, 7.75, z), 0.4, 0.4, UP)
			B.applique(m, cf * CFrame.new(V(xP + s * (wP / 2 + 0.9), 4.2, z)))
		end
		poutre(V(xP - d - 0.3, 7.75, zp), V(xP + d + 0.3, 7.75, zp), 0.45, 0.45, UP)
		-- petit pignon de plâtre et toit à deux pans
		local hw, H = d + 0.2, 1.9
		K.pignon(V(xP, 8.0, zp - 0.2), -K.X, Vector3.new(0, 0, -1), hw, H, 0, false, true)
		K.toitZ(xP, hw + 0.3, zp - 1.0, z, 7.9, 8.0 + H + 0.2, 0.6)
	end

	-- Bannières de tissu suspendues sous l'avant-toit (maisons des PNJ)
	function K.bannieres(xs, z, yHaut)
		for _, xv in xs do
			O.decor(bloc(Vector3.new(2.2, 0.2, 0.2), V(xv, yHaut, z - 0.4), C.Or, M.Metal, "Tringle"))
			local tissu = O.decor(bloc(Vector3.new(1.5, 4.2, 0.12), V(xv, yHaut - 2.2, z - 0.4), K.couleur, M.Tissu, "Banniere"))
			tissu.CanTouch = false
			O.decor(bloc(Vector3.new(1.5, 0.25, 0.16), V(xv, yHaut - 4.35, z - 0.4), C.Or, M.Tissu, "Frange"))
			O.decor(bloc(Vector3.new(0.9, 0.9, 0.14), V(xv, yHaut - 1.6, z - 0.48), C.Or, M.Metal, "Embleme"))
		end
	end

	-- Potence avec panneau suspendu et lanterne (maisons des PNJ)
	function K.potence(xv, y, z)
		poutre(V(xv, y, z), V(xv, y, z - 2.6), 0.3, 0.3, UP, C.Fer, M.Metal, "Potence")
		O.decor(poutre(V(xv, y - 1.2, z), V(xv, y - 0.1, z - 1.6), 0.15, 0.15, K.X, C.Fer, M.Metal, "Potence"))
		for _, dz in {-0.8, -2.0} do
			O.decor(bloc(Vector3.new(0.06, 0.5, 0.06), V(xv, y - 0.3, z + dz), C.Fer, M.Metal, "Chaine"))
		end
		local panneau = bloc(Vector3.new(0.2, 1.4, 1.8), V(xv, y - 1.25, z - 1.4), K.couleur, M.Planches, "Panneau")
		O.decor(panneau)
		O.decor(bloc(Vector3.new(0.26, 0.6, 0.6), V(xv, y - 1.25, z - 1.4), C.Or, M.Metal, "Embleme"))
	end

	-- Lierre au pied d'une façade tournée vers -Z (centre xv, largeur W), seulement là où il ne cache rien
	function K.lierre(xv, z, W, h)
		if o.lierre ~= false and libre(xv - W / 2, xv + W / 2, 0, h, z) then
			K.trou(xv - W / 2, xv + W / 2, 0, h, z)
			B.lierre(m, cf * CFrame.new(V(xv, 0, z)), W, h, rng, nil)
		end
	end
	return K
end

-- ---------- Modèle 1 : l'auberge ----------
local function maisonAuberge(m, cf, o, K, L, P, G)
	local V, bloc = K.V, K.bloc
	local wl, wr = 0.27 * L, 0.36 * L
	local wc = L - wl - wr
	local xl, xr = -L / 2 + wl / 2, L / 2 - wr / 2
	local AV = 1.2
	local zF = -P / 2
	local Yr = G + (P / 2) * 1.43
	local Yl = math.max(G + (wl / 2) * 2.44, Yr + 1.2)
	local Yd = math.max(G + (wr / 2) * 3.14, Yl + 3)
	local zD = zF - AV

	K.murs(Vector3.new(L - wr, G, P), V(-L / 2 + (L - wr) / 2, G / 2, 0))
	K.murs(Vector3.new(wr, G, P + AV), V(xr, G / 2, -AV / 2))
	K.pierres(-L / 2, L / 2 - wr, zF, 0, G, math.floor((L - wr) * 1.6))
	K.pierres(L / 2 - wr, L / 2, zD, 0, G, math.floor(wr * 1.6))

	-- toits
	K.toitX(xl, xr, zF, -zF, G, Yr, 1.3)
	local zl0, zl1 = zF - 0.6, -zF + 0.6
	K.toitZ(xl, wl / 2, zl0 - 1.1, zl1 + 1.1, G, Yl, 1.2)
	local zr0, zr1 = zD - 0.6, -zF + 0.6
	K.toitZ(xr, wr / 2, zr0 - 1.2, zr1 + 1.2, G, Yd, 1.4)
	-- pignons
	local hwl = wl / 2 - 0.5 / ((Yl - G) / (wl / 2))
	K.pignon(V(xl, G + 0.5, zl0), -K.X, Vector3.new(0, 0, -1), hwl, Yl - G - 0.5, 1)
	K.pignon(V(xl, G + 0.5, zl1), K.X, Vector3.new(0, 0, 1), hwl, Yl - G - 0.5, 0)
	local hwr = wr / 2 - 0.5 / ((Yd - G) / (wr / 2))
	K.pignon(V(xr, G + 0.5, zr0), -K.X, Vector3.new(0, 0, -1), hwr, Yd - G - 0.5, 1, true)
	K.pignon(V(xr, G + 0.5, zr1), K.X, Vector3.new(0, 0, 1), hwr, Yd - G - 0.5, 0)
	-- lucarne et cheminée
	local xLuc = -L / 2 + wl + wc * 0.55
	local wLuc = math.min(wc * 0.7, 6.4)
	if wLuc >= 4 then
		K.lucarne(xLuc, wLuc, zF, G, 0, Yr, 2)
	end
	if o.cheminee ~= false then
		local xc = math.min(xLuc + wLuc / 2 + 1.2, L / 2 - wr - 1.2)
		local pente = (Yr - G) / (P / 2)
		K.cheminee(xc, 1.2, G + (P / 2 - 1.2) * pente - 1, Yr + 2.6)
	end

	-- rez-de-chaussée
	local nbG = if wl >= 6 then 2 else 1
	for i = 1, nbG do
		K.fenetre(-L / 2 + wl * (i - 0.5) / nbG, 5, zF, 1.8, 2.6, false, nil)
	end
	if not K.prestige then
		K.jardiniere(-L / 2 + 0.4, -L / 2 + wl - 0.4, 3.15, zF)
	end
	local xP = -L / 2 + wl + 1.9
	local porteCF = K.porte(xP, zF, 3)
	local a, b = xP + 1.5 + 0.8, L / 2 - wr - 2.2 -- laisse la place au lierre du coin
	if K.prestige then
		a += 1.2
	end
	local place = b - a
	if place >= 9 then
		for _, x in {a + 1.35, a + 5.75} do
			K.fenetre(x, 5, zF, 2.0, 3.0, true, {1})
		end
	elseif place >= 4.6 then
		K.fenetre(a + 1.35, 5, zF, 2.0, 3.0, true, {1})
	elseif place >= 2.6 then
		K.fenetre((a + b) / 2, 5, zF, 1.8, 3.0, true, nil)
	end
	if not K.prestige then
		K.muretFleuri(a - 0.4, b, zF)
	end
	-- aile droite : portillon, fenêtre éclairée
	local xG = L / 2 - wr + 2.0
	K.trou(xG - 1.9, xG + 1.9, 0, 7.2, zD)
	for _, s in {-1, 1} do
		bloc(Vector3.new(0.4, 6.6, 0.5), V(xG + s * 1.4, 3.3, zD - 0.2), COUL_AUBERGE.Bois, M.Bois, "Montant")
	end
	bloc(Vector3.new(3.2, 0.4, 0.5), V(xG, 6.8, zD - 0.2), COUL_AUBERGE.Bois, M.Bois, "Linteau")
	bloc(Vector3.new(2.4, 5.6, 0.25), V(xG, 3.0, zD - 0.05), COUL_AUBERGE.Planches, M.Planches, "Portillon")
	for _, y in {1.2, 4.8} do
		O.decor(bloc(Vector3.new(2.4, 0.3, 0.1), V(xG, y, zD - 0.22), COUL_AUBERGE.Bois, M.Bois, "Traverse"))
	end
	if wr >= 7 then
		K.fenetre(L / 2 - 2.3, 5.2, zD, 2.6, 3.0, false, nil, true)
	end
	B.suspension(m, (cf * CFrame.new(V(xr + wr * 0.22, G + 5, zr0 - 1.0))).Position, 0.8, C.Lumiere, 14)
	K.lierre(L / 2 - wr - 1.1, zF, 1.8, G + 0.5)
	B.tonneau(m, cf * CFrame.new(V(-L / 2 + 1.2, 0, zF - 2.6)))
	-- auvent en planches devant l'aile droite
	if o.auvent ~= false and wr >= 7 then
		local za = zD - 4.5
		local x0, x1 = L / 2 - wr * 0.55, L / 2 + 1.5
		for _, x in {x0 + 0.4, x1 - 0.4} do
			bloc(Vector3.new(0.45, 7.6, 0.45), V(x, 3.8, za), COUL_AUBERGE.Bois, M.Bois, "Poteau")
			O.decor(bloc(Vector3.new(2, 0.3, 0.35), V(x, 7.4, za), COUL_AUBERGE.Bois, M.Bois, "Traverse"))
		end
		local haut, bas = V((x0 + x1) / 2, G - 0.3, zD - 0.1), V((x0 + x1) / 2, 7.9, za - 0.6)
		local d = (bas - haut).Unit
		local nrm = K.X:Cross(d)
		if nrm.Y < 0 then
			nrm = -nrm
		end
		K.poser(Vector3.new(x1 - x0, 0.3, (bas - haut).Magnitude), (haut + bas) / 2, K.X, nrm, COUL_AUBERGE.Planches, M.Planches, "Auvent")
	end
	if K.prestige then
		K.bannieres({xr}, zD, G - 0.3)
		K.potence(L / 2 - wr - 0.6, G - 1.2, zF)
	end
	return porteCF, cf * CFrame.new(V(xr, G + 2.0, zr0 - 0.2)), math.min(9, wr - 0.6)
end

-- ---------- Modèle 2 : grand pignon central en avancée ----------
local function maisonPignonCentral(m, cf, o, K, L, P, G)
	local V = K.V
	local wg = math.max(0.44 * L, 7.5)
	local ws = (L - wg) / 2 -- largeur de chaque côté
	local AV = 1.4
	local zF = -P / 2
	local zG = zF - AV
	local Yr = G + (P / 2) * 1.2
	local Yg = math.max(G + (wg / 2) * 2.6, Yr + 2.5)

	K.murs(Vector3.new(L, G, P), V(0, G / 2, 0))
	K.murs(Vector3.new(wg, G, AV), V(0, G / 2, zF - AV / 2))
	K.pierres(-L / 2, -wg / 2, zF, 0, G, math.floor(ws * 1.6))
	K.pierres(wg / 2, L / 2, zF, 0, G, math.floor(ws * 1.6))
	K.pierres(-wg / 2, wg / 2, zG, 0, G, math.floor(wg * 1.6))

	-- toit principal (faîtage parallèle à la façade) et pignons d'extrémité
	K.toitX(-L / 2 - 1.2, L / 2 + 1.2, zF, -zF, G, Yr, 1.3)
	local hwE = P / 2 - 0.5 / ((Yr - G) / (P / 2))
	for _, s in {-1, 1} do
		K.pignon(V(s * (L / 2 + 0.5), G + 0.5, 0), Vector3.new(0, 0, s), Vector3.new(-s, 0, 0), hwE, Yr - G - 0.5, 1)
	end
	-- grand pignon central (faîtage perpendiculaire, jusqu'au faîtage principal)
	local zg0 = zG - 0.6
	-- le grand pignon traverse toute la maison (pignon arrière plus simple)
	K.toitZ(0, wg / 2, zg0 - 1.2, -zF + 0.6 + 1.2, G, Yg, 1.3)
	local hwg = wg / 2 - 0.5 / ((Yg - G) / (wg / 2))
	K.pignon(V(0, G + 0.5, zg0), -K.X, Vector3.new(0, 0, -1), hwg, Yg - G - 0.5, 2, true)
	K.pignon(V(0, G + 0.5, -zF + 0.6), K.X, Vector3.new(0, 0, 1), hwg, Yg - G - 0.5, 1)
	-- lucarnes sur les toits latéraux, cheminées aux extrémités
	if ws >= 5 then
		for _, s in {-1, 1} do
			K.lucarne(s * (wg / 2 + ws / 2), math.min(ws * 0.6, 4.2), zF, G, 0, Yr, 1)
		end
	end
	if o.cheminee ~= false then
		local pente = (Yr - G) / (P / 2)
		K.cheminee(-(L / 2 - 1.6), 1.4, G + (P / 2 - 1.4) * pente - 1, Yr + 2.4)
		if L >= 20 then
			K.cheminee(L / 2 - 1.6, 1.4, G + (P / 2 - 1.4) * pente - 1, Yr + 1.8)
		end
	end

	-- rez-de-chaussée : porte au centre du pignon, fenêtres de chaque côté
	local porteCF = K.porte(0, zG, if K.prestige then 3.4 else 3)
	if wg >= 11 and not K.prestige then
		for _, s in {-1, 1} do
			K.fenetre(s * (wg / 2 - 1.6), 5, zG, 1.6, 2.6, false, nil, false, true)
		end
	end
	for _, s in {-1, 1} do
		local xc = s * (wg / 2 + ws / 2)
		if ws >= 7.5 then
			for _, d in {-1, 1} do
				K.fenetre(xc + d * ws * 0.25, 5, zF, 1.9, 3.0, true, nil)
			end
		elseif ws >= 3.4 then
			K.fenetre(xc, 5, zF, 1.9, 3.0, true, if ws >= 5.5 then {-1, 1} else nil)
		end
		if not K.prestige then
			K.jardiniere(xc - ws / 2 + 0.6, xc + ws / 2 - 0.6, 3.0, zF)
		end
	end
	K.lierre(-L / 2 + 1.0, zF, 1.6, G + 0.5)
	B.tonneau(m, cf * CFrame.new(V(L / 2 - 1.4, 0, zF - 2.2)))
	if K.prestige then
		K.bannieres({-wg / 2 + 0.9, wg / 2 - 0.9}, zG, G - 0.3)
		K.potence(-L / 2 + 1.0, G - 1.2, zF)
	end
	return porteCF, cf * CFrame.new(V(0, G + 2.0, zg0 - 0.2)), math.min(9, wg - 0.8)
end

-- ---------- Modèle 3 : étage entier à colombages en encorbellement ----------
local function maisonEtage(m, cf, o, K, L, P, G)
	local V, bloc, poutre = K.V, K.bloc, K.poutre
	local UP = K.UP
	local HE2 = 6
	local zF = -P / 2
	local zE = zF - 0.8 -- façade de l'étage
	local Y0 = G + HE2
	local Yr = Y0 + (P / 2 + 0.4) * 1.1

	K.murs(Vector3.new(L, G, P), V(0, G / 2, 0))
	K.pierres(-L / 2, L / 2, zF, 0, G, math.floor(L * 1.6))
	-- étage en plâtre, en avancée sur la façade
	bloc(Vector3.new(L + 0.4, HE2, P + 0.8), V(0, G + HE2 / 2, -0.4), K.platre, M.Platre, "Etage")
	local n = Vector3.new(0, 0, -1)
	poutre(V(-L / 2 - 0.4, G + 0.3, zE - 0.15), V(L / 2 + 0.4, G + 0.3, zE - 0.15), 0.6, 0.5, n)
	poutre(V(-L / 2 - 0.4, Y0 - 0.25, zE - 0.15), V(L / 2 + 0.4, Y0 - 0.25, zE - 0.15), 0.5, 0.45, n)
	-- solives de l'encorbellement
	local k = -L / 2 + 0.4
	while k < L / 2 do
		O.decor(poutre(V(k, G - 0.3, zF), V(k, G - 0.3, zE - 0.2), 0.32, 0.4, UP))
		k += 1.2
	end
	-- fenêtres de l'étage, poteaux et croix de Saint-André
	local nbF = math.max(2, math.floor(L / 5.2))
	local pas = L / nbF
	for i = 0, nbF do
		local x = -L / 2 + i * pas
		poutre(V(x, G + 0.5, zE - 0.15), V(x, Y0 - 0.5, zE - 0.15), 0.42, 0.32, n)
	end
	for i = 1, nbF do
		local x = -L / 2 + (i - 0.5) * pas
		K.fenetre(x, G + HE2 * 0.6, zE, math.min(2.0, pas * 0.4), 2.4, false, if pas >= 4.6 then {-1, 1} else nil, false, K.prestige or i % 2 == 1)
		-- allège : croix de Saint-André sous la fenêtre
		local w = pas * 0.36
		O.decor(poutre(V(x - w, G + 0.6, zE - 0.12), V(x + w, G + 2.0, zE - 0.12), 0.26, 0.26, n))
		O.decor(poutre(V(x + w, G + 0.6, zE - 0.12), V(x - w, G + 2.0, zE - 0.12), 0.26, 0.26, n))
	end
	-- côtés de l'étage : poteaux d'angle et milieu
	for _, s in {-1, 1} do
		local ns = Vector3.new(-s, 0, 0)
		for _, z in {zE, 0, P / 2} do
			poutre(V(s * (L / 2 + 0.25), G + 0.3, z), V(s * (L / 2 + 0.25), Y0, z), 0.4, 0.3, ns)
		end
		poutre(V(s * (L / 2 + 0.25), G + HE2 * 0.5, zE), V(s * (L / 2 + 0.25), G + HE2 * 0.5, P / 2), 0.35, 0.3, ns)
	end
	-- toit et pignons d'extrémité
	K.toitX(-L / 2 - 1.2, L / 2 + 1.2, zE, P / 2, Y0, Yr, 1.2)
	local hwE = (P / 2 + 0.4) - 0.5 / ((Yr - Y0) / (P / 2 + 0.4))
	for _, s in {-1, 1} do
		K.pignon(V(s * (L / 2 + 0.3), Y0 + 0.5, -0.4), Vector3.new(0, 0, s), Vector3.new(-s, 0, 0), hwE, Yr - Y0 - 0.5, 1, false, true)
	end
	-- lucarnes
	local nbL = if L >= 18 then 2 else 1
	for i = 1, nbL do
		local x = if nbL == 1 then 0 else (i - 1.5) * L * 0.42
		K.lucarne(x, 3.6, zE, Y0, -0.4, Yr, 1)
	end
	if o.cheminee ~= false then
		local pente = (Yr - Y0) / (P / 2 + 0.4)
		K.cheminee(L / 2 - 2.2, 1.6, Y0 + (P / 2 - 1.6) * pente - 1, Yr + 2.4)
	end

	-- rez-de-chaussée : porte au tiers gauche, fenêtres
	local xP = -L / 2 + L * 0.3
	local porteCF = K.porte(xP, zF, 3)
	local libres = {}
	local x = -L / 2 + 2.6
	while x < L / 2 - 3.2 do
		if math.abs(x - xP) > (if K.prestige then 4.6 else 3.6) then
			table.insert(libres, x)
		end
		x += 3.8
	end
	for _, xf in libres do
		K.fenetre(xf, 4.8, zF, 1.9, 2.8, true, nil, false, not K.prestige)
	end
	K.lierre(L / 2 - 1.0, zF, 1.6, G)
	B.tonneau(m, cf * CFrame.new(V(xP + 3.2, 0, zF - 2.4)))
	if K.prestige then
		K.bannieres({-L / 2 + 0.9, L / 2 - 0.9}, zF, G - 0.3)
		K.potence(xP - 3.4, G - 1.2, zF)
	end
	local largeur = math.min(9, L * 0.4)
	local xE = math.clamp(L * 0.12, -L / 2 + largeur / 2, L / 2 - largeur / 2)
	return porteCF, cf * CFrame.new(V(xE, G - 1.3, zF - 0.6)), largeur
end

-- ---------- Modèle 4 : pignon sur rue et appentis ----------
local function maisonPignonSurRue(m, cf, o, K, L, P, G)
	local V, bloc, poutre = K.V, K.bloc, K.poutre
	local wm = 0.72 * L
	local wa = L - wm
	local xm = -L / 2 + wm / 2
	local zF = -P / 2
	local Ya = G + (wm / 2) * 2.4

	K.murs(Vector3.new(wm, G, P), V(xm, G / 2, 0))
	K.pierres(-L / 2, -L / 2 + wm, zF, 0, G, math.floor(wm * 1.6))
	local z0, z1 = zF - 0.6, -zF + 0.6
	K.toitZ(xm, wm / 2, z0 - 1.2, z1 + 1.2, G, Ya, 1.4)
	local hw = wm / 2 - 0.5 / ((Ya - G) / (wm / 2))
	K.pignon(V(xm, G + 0.5, z0), -K.X, Vector3.new(0, 0, -1), hw, Ya - G - 0.5, 2, true)
	K.pignon(V(xm, G + 0.5, z1), K.X, Vector3.new(0, 0, 1), hw, Ya - G - 0.5, 1)
	if o.cheminee ~= false then
		K.cheminee(xm - wm * 0.18, P / 4, Ya - wm * 0.18 * 2.4 - 1.5, Ya + 1.5)
	end
	-- rez-de-chaussée : porte au centre, fenêtres de part et d'autre
	local porteCF = K.porte(xm, zF, 3)
	local cote = wm / 2 - (if K.prestige then 3.4 else 2.4)
	if cote >= 3 then
		for _, s in {-1, 1} do
			K.fenetre(xm + s * (wm / 2 - cote / 2 - 0.2), 5, zF, math.min(2.0, cote * 0.55), 2.8, true, if cote >= 4.4 then {s} else nil, false, true)
		end
	end
	-- appentis à bois (côté droit) : toit en planches à un pan, poteaux, bûches et tonneaux
	if wa >= 3 then
		local xa = L / 2 - wa / 2
		local yHaut, yBas = G - 0.4, 6.4
		bloc(Vector3.new(wa, yBas, 0.4), V(xa, yBas / 2, P / 2 - 0.2), COUL_AUBERGE.Planches, M.Planches, "Planches")
		bloc(Vector3.new(0.4, yBas, P), V(L / 2 - 0.2, yBas / 2, 0), COUL_AUBERGE.Planches, M.Planches, "Planches")
		for _, z in {zF - 0.4, 0} do
			bloc(Vector3.new(0.45, yBas, 0.45), V(L / 2 - 0.3, yBas / 2, z), COUL_AUBERGE.Bois, M.Bois, "Poteau")
		end
		local haut, bas = V(-L / 2 + wm, yHaut, 0), V(L / 2 + 0.8, yBas, 0)
		local d = (bas - haut).Unit
		local nrm = K.Z:Cross(d)
		if nrm.Y < 0 then
			nrm = -nrm
		end
		K.poser(Vector3.new((bas - haut).Magnitude, 0.3, P + 1.6), (haut + bas) / 2 + nrm * 0.2, d, nrm, COUL_AUBERGE.Planches, M.Planches, "Auvent")
		-- tas de bûches
		for r = 0, 2 do
			for i = 0, math.max(1, math.floor(wa / 0.9)) - 1 - r do
				O.decor(O.disque(m, P * 0.5, 0.8, cf * CFrame.new(V(xa - wa / 2 + 0.8 + i * 0.85 + r * 0.42, 0.4 + r * 0.72, P / 6))
					* CFrame.Angles(0, math.pi / 2, 0), COUL_AUBERGE.Planches:Lerp(COUL_AUBERGE.Porte, K.rng:NextNumber()), M.Bois, "Buche"))
			end
		end
		B.tonneau(m, cf * CFrame.new(V(xa, 0, zF - 0.6)))
	end
	K.lierre(-L / 2 + 1.0, zF, 1.6, G)
	if K.prestige then
		K.bannieres({xm - wm / 2 + 0.9, xm + wm / 2 - 0.9}, zF, G - 0.3)
		K.potence(xm + 3.6, G - 1.2, zF)
	end
	return porteCF, cf * CFrame.new(V(xm, G + 2.0, z0 - 0.2)), math.min(9, wm - 1)
end

local MODELES_MAISON = {maisonAuberge, maisonPignonCentral, maisonEtage, maisonPignonSurRue}

local function maisonBlocs(parent, cf, o)
	local L = o.largeur or 18
	local E = o.etages or 1
	local P = math.clamp(0.5 * L, 10, math.max(10, o.profondeur or 16))
	local G = (if E > 1 then 10 else 9) + (if o.prestige then 1 else 0)
	local m = O.modele(parent, o.nom or "Maison")
	local K = kitMaison(m, cf, o)
	local construire = MODELES_MAISON[o.modele or 1] or maisonAuberge
	local porteCF, enseigneCF, largeurEnseigne = construire(m, cf, o, K, L, P, G)
	K.poserPierres()
	if o.enseigne then
		B.fronton(m, enseigneCF, o.enseigne, largeurEnseigne)
	end
	return m, porteCF, enseigneCF, largeurEnseigne
end

--[[ Maison à colombages, dans le style de l'auberge (previews/auberge/reference.png)
	o = {largeur, profondeur, etages, mur, toit, volet, nom, enseigne, cheminee, lierre, auvent, modele (1 à 4), prestige, couleur, rng}
	Renvoie le modèle, le CFrame du bas de la porte (sur la façade), celui de l'enseigne et sa largeur.
	Modèle Blender (Auberge.fbx dans ServerStorage.Modeles3D) s'il est importé, sinon la version en blocs. ]]
function B.maison(parent, cf, o)
	o = o or {}
	local m3, porte3, enseigne3, largeur3 = auberge3D(parent, cf, o)
	if m3 then
		return m3, porte3, enseigne3, largeur3
	end
	return maisonBlocs(parent, cf, o)
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

-- Fourneau du forgeron. cf = centre du foyer au sol, -Z = la gueule (vers l'atelier). Encombrement ≈ 9 × 6 au sol ;
-- la cheminée monte à (0, 16.5, 1) comme l'ancien foyer (elle traverse le toit au même endroit).
-- Modèle « Fourneau » (attribut VersionFourneau) : Village.preparerAteliers le pose aussi sur les cartes figées.
B.VERSION_FOURNEAU = 2
function B.fourneau(parent, cf)
	local m = O.modele(parent, "Fourneau")
	m:SetAttribute("VersionFourneau", B.VERSION_FOURNEAU)
	m:SetAttribute("Base", cf)
	local rng = Random.new(905)
	local BRIQUE = Color3.fromRGB(122, 64, 46)
	local BRIQUE_SOMBRE = Color3.fromRGB(78, 42, 34)
	local FEU = Color3.fromRGB(255, 120, 30)
	local BRAISE = Color3.fromRGB(255, 70, 16)
	local FER = Color3.fromRGB(52, 50, 54)
	local function brique() return BRIQUE:Lerp(BRIQUE_SOMBRE, rng:NextNumber(0, 0.6)) end

	-- Socle de pierre à deux degrés
	O.bloc(m, Vector3.new(9.2, 0.5, 6.4), cf * CFrame.new(0, 0.25, 0), COUL_AUBERGE.PierreSombre, M.Pierre, "Socle")
	O.bloc(m, Vector3.new(8.6, 0.5, 5.8), cf * CFrame.new(0, 0.75, 0.1), COUL_AUBERGE.Pierre, M.Pierre, "Socle")
	-- Corps en briques : côtés, fond, et façade autour de la gueule (assises décalées)
	local Y0, H = 1, 5
	for _, s in {-1, 1} do
		for k = 0, 4 do
			O.bloc(m, Vector3.new(1.8, 1, 5.2), cf * CFrame.new(s * 3.3 + (k % 2) * 0.06 * s, Y0 + 0.5 + k, 0.2), brique(), M.Brique, "Foyer")
		end
	end
	O.bloc(m, Vector3.new(5, H, 1.2), cf * CFrame.new(0, Y0 + H / 2, 2.2), BRIQUE_SOMBRE, M.Brique, "Foyer")
	-- Linteau de la gueule : arche de pierres claires (7 voussoirs + clé)
	local centreArche = cf * CFrame.new(0, Y0 + 2.4, -2.45)
	for k = 0, 6 do
		local a = (k + 0.5) / 7 * math.pi
		local p = Vector3.new(math.cos(a) * 2.05, math.sin(a) * 2.05, 0)
		O.bloc(m, Vector3.new(0.9, 0.95, 1.1), centreArche * CFrame.new(p) * CFrame.Angles(0, 0, a), COUL_AUBERGE.PierreClaire:Lerp(COUL_AUBERGE.Pierre, rng:NextNumber(0, 0.5)), M.Pierre, "Voussoir")
	end
	O.bloc(m, Vector3.new(1.1, 1.2, 1.3), centreArche * CFrame.new(0, 2.3, -0.05), COUL_AUBERGE.PierreClaire, M.Pierre, "Cle")
	for _, s in {-1, 1} do -- jambages de la gueule et écoinçons au-dessus de l'arche
		O.bloc(m, Vector3.new(0.9, 2.4, 1.1), cf * CFrame.new(s * 2.05, Y0 + 1.2, -2.45), COUL_AUBERGE.PierreClaire, M.Pierre, "Jambage")
		O.bloc(m, Vector3.new(1.6, 2.2, 1.1), cf * CFrame.new(s * 3.3, Y0 + 3.9, -2.45), brique(), M.Brique, "Foyer")
	end
	O.bloc(m, Vector3.new(3, 0.6, 1.1), cf * CFrame.new(0, Y0 + 4.7, -2.45), brique(), M.Brique, "Foyer")
	-- Dessus en pierre et cerclage de fer riveté
	O.bloc(m, Vector3.new(8.4, 0.7, 6), cf * CFrame.new(0, Y0 + H + 0.35, 0.1), COUL_AUBERGE.Pierre, M.Pierre, "Plateau")
	for _, y in {Y0 + 0.9, Y0 + 4.2} do
		for _, s in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(1.8, 0.28, 0.15), cf * CFrame.new(s * 3.35, y, -2.98), FER, M.Metal, "Cerclage"))
			for _, x in {2.8, 3.9} do
				O.decor(O.ellipsoide(m, Vector3.new(0.24, 0.24, 0.14), cf * CFrame.new(s * x, y, -3.06), Color3.fromRGB(120, 116, 112), M.Metal, "Rivet"))
			end
		end
	end

	-- Intérieur incandescent : fond de braises, lit de charbons rougeoyants, flammes
	local interieur = O.decor(O.bloc(m, Vector3.new(3.6, 3.6, 3.4), cf * CFrame.new(0, Y0 + 1.9, 0), FEU, M.Neon, "Braises"))
	interieur.Transparency = 0.15
	O.lumiere(interieur, Color3.fromRGB(255, 130, 50), 4, 34, true)
	for _ = 1, 14 do
		local chaud = rng:NextNumber() < 0.55
		local s = rng:NextNumber(0.5, 0.9)
		O.decor(O.ellipsoide(m, Vector3.new(s, s * 0.7, s), cf * CFrame.new(rng:NextNumber(-1.4, 1.4), Y0 + 0.35 + rng:NextNumber(0, 0.3), rng:NextNumber(-2, 1.2)),
			if chaud then BRAISE else Color3.fromRGB(34, 26, 24), if chaud then M.Neon else M.Ardoise, "Charbon"))
	end
	local flammes = O.decor(O.bloc(m, Vector3.new(2.6, 0.4, 2.4), cf * CFrame.new(0, Y0 + 0.8, -0.8), FEU, M.Neon, "Flammes"))
	flammes.Transparency = 1
	O.feu(flammes, 4.5)
	O.etincelles(flammes, Color3.fromRGB(255, 190, 90), 10)
	-- Fissures de chaleur dans les briques de façade
	for _ = 1, 6 do
		local s = if rng:NextNumber() < 0.5 then -1 else 1
		O.decor(O.bloc(m, Vector3.new(rng:NextNumber(0.5, 1.1), 0.08, 0.06), cf * CFrame.new(s * rng:NextNumber(2.7, 3.8), Y0 + rng:NextNumber(0.6, 4.5), -2.53)
			* CFrame.Angles(0, 0, rng:NextNumber(-0.6, 0.6)), FEU, M.Neon, "Fissure"))
	end

	-- Hotte en gradins de pierre, cerclée de fer, puis la cheminée
	local hY = Y0 + H + 0.7
	for k, t in {{7.6, 1.3, 5.2}, {6.2, 1.3, 4.4}, {4.8, 1.3, 3.8}} do
		local y = hY + (k - 1) * 1.3 + 0.65
		O.bloc(m, Vector3.new(t[1], t[2], t[3]), cf * CFrame.new(0, y, 0.3 + (k - 1) * 0.25), COUL_AUBERGE.Pierre:Lerp(COUL_AUBERGE.PierreClaire, (k - 1) * 0.25), M.Pierre, "Hotte")
		O.decor(O.bloc(m, Vector3.new(t[1] + 0.12, 0.22, t[3] + 0.12), cf * CFrame.new(0, y - 0.5, 0.3 + (k - 1) * 0.25), FER, M.Metal, "Bande"))
	end
	O.bloc(m, Vector3.new(3, 12, 3), cf * CFrame.new(0, 16.5, 1), COUL_AUBERGE.PierreClaire, M.Pierre, "Cheminee")
	for _, y in {12, 15.5, 19} do
		O.decor(O.bloc(m, Vector3.new(3.15, 0.25, 3.15), cf * CFrame.new(0, y, 1), FER, M.Metal, "Bande"))
	end
	local chapeau = O.bloc(m, Vector3.new(3.8, 0.6, 3.8), cf * CFrame.new(0, 22.8, 1), COUL_AUBERGE.PierreSombre, M.Pierre, "Chapeau")
	O.fumee(chapeau, 4, Color3.fromRGB(110, 102, 98))
	-- Écusson à l'enclume sur la hotte (fer forgé + braise)
	O.decor(O.bloc(m, Vector3.new(1.8, 1.2, 0.2), cf * CFrame.new(0, hY + 1.2, -2.4), FER, M.Metal, "Ecusson"))
	O.decor(O.bloc(m, Vector3.new(1.2, 0.35, 0.1), cf * CFrame.new(0, hY + 1.35, -2.52), BRAISE, M.Neon, "EcussonBraise"))

	-- Soufflet de cuir sur le côté droit, avec sa buse dans le foyer
	local s = cf * CFrame.new(5.6, 2.4, 0) * CFrame.Angles(0, 0, math.rad(-12))
	O.bloc(m, Vector3.new(2.6, 0.2, 2), s * CFrame.new(0, 0.55, 0), C.Bois, M.Planches, "Soufflet")
	O.bloc(m, Vector3.new(2.6, 0.2, 2), s * CFrame.new(0, -0.55, 0), C.Bois, M.Planches, "Soufflet")
	O.ellipsoide(m, Vector3.new(2.3, 0.95, 1.8), s, Color3.fromRGB(96, 60, 38), M.Cuir, "Soufflet")
	O.decor(O.bloc(m, Vector3.new(1.6, 0.25, 0.25), s * CFrame.new(2, 0.6, 0), C.BoisFonce, M.Bois, "Poignee"))
	O.decor(O.cylindre(m, 1.4, 0.35, s * CFrame.new(-1.7, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), FER, M.Metal, "Buse"))
	O.bloc(m, Vector3.new(0.5, 1.8, 0.5), cf * CFrame.new(5.6, 0.9, 0), C.BoisFonce, M.Bois, "Pied")

	-- Tisonnier et pince contre le jambage gauche, seau et tas de charbon
	for k, t in {{-4.5, 0.2}, {-4.85, -0.18}} do
		O.decor(O.bloc(m, Vector3.new(0.14, 3.6, 0.14), cf * CFrame.new(t[1], 1.9, -3.4) * CFrame.Angles(0, 0, t[2]), FER, M.Metal, if k == 1 then "Tisonnier" else "Pince"))
	end
	O.cylindre(m, 1.1, 1.3, cf * CFrame.new(-3.4, 0.55, -4.1), Color3.fromRGB(70, 66, 64), M.Metal, "Seau")
	for _ = 1, 4 do
		O.decor(O.ellipsoide(m, Vector3.new(0.5, 0.4, 0.5), cf * CFrame.new(-3.4 + rng:NextNumber(-0.3, 0.3), 1.15, -4.1 + rng:NextNumber(-0.3, 0.3)), Color3.fromRGB(30, 28, 30), M.Ardoise, "Charbon"))
	end
	for _ = 1, 9 do
		local t = rng:NextNumber(0.5, 1)
		O.decor(O.ellipsoide(m, Vector3.new(t, t * 0.7, t), cf * CFrame.new(rng:NextNumber(2.8, 4.6), t * 0.25, rng:NextNumber(-4.4, -3.2)),
			Color3.fromRGB(32, 30, 34), M.Ardoise, "TasCharbon"))
	end
	return m
end

-- Toit à deux pentes ; un passage est ménagé autour du conduit du fourneau.
-- La fonction sert aussi à remplacer les anciennes toitures des cartes figées.
function B.preparerToitForge(forge)
	if forge:GetAttribute("VersionToitForge") == 1 then return end
	local murPierre
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and p.Name == "MurFond" and p.Material == M.Pierre then murPierre = p break end
	end
	if not murPierre then warn("[Forge] Mur de référence absent : toit conservé") return end
	local cf = murPierre.CFrame * CFrame.new(0, -5.5, -9)
	local toiture = Instance.new("Model")
	toiture.Name = "Forge_Toit"
	local K = kitMaison(toiture, cf, {prestige = true, couleur = Color3.fromRGB(196, 92, 34), rng = Random.new(77), lierre = false})
	local V = K.V
	local zCentre, zAvant, zArriere, bas = 0.1, -9.7, 9.9, 14
	local haut = bas + (zArriere - zCentre) * FORGE_PENTE_TOIT
	-- Pan avant, continu et centré.
	K.pan(V(0, bas, zAvant), V(0, haut, zCentre), K.X, 26.8, FORGE_DEBORD_TOIT)
	-- Pan arrière, découpé autour de la cheminée (x local = -5, z = 7).
	-- Les quatre morceaux restent dans le même plan et gardent la même pente.
	local function panArriere(x0, x1, zBas, zHaut, debord)
		local milieu = (x0 + x1) / 2
		local function hauteur(z) return haut - (z - zCentre) * FORGE_PENTE_TOIT end
		K.pan(V(milieu, hauteur(zBas), zBas), V(milieu, hauteur(zHaut), zHaut), K.X, x1 - x0, debord)
	end
	-- La tuile a une épaisseur et son centre est décalé selon la normale :
	-- prévoir ce débord, sinon le pan amont mord encore dans la cheminée.
	local ouvertureGauche, ouvertureDroite = 3.2, 6.8 -- coordonnées vues de face
	local ouvertureHaut, ouvertureBas = 4.8, 9.2
	panArriere(-13.4, ouvertureGauche, zArriere, zCentre, FORGE_DEBORD_TOIT)
	panArriere(ouvertureDroite, 13.4, zArriere, zCentre, FORGE_DEBORD_TOIT)
	panArriere(ouvertureGauche, ouvertureDroite, ouvertureHaut, zCentre, 0)
	panArriere(ouvertureGauche, ouvertureDroite, zArriere, ouvertureBas, FORGE_DEBORD_TOIT)
	K.faitage(V(-13.4, haut, zCentre), V(13.4, haut, zCentre))
	-- Les petits rives générés sur les découpes seraient au milieu du toit.
	for _, p in toiture:GetChildren() do
		if p.Name == "RiveToit" then p:Destroy() end
	end
	for _, x in {-13.25, 13.25} do
		for _, z in {zAvant, zArriere} do
			K.poutre(V(x, bas - 0.05, z), V(x, haut - 0.05, zCentre), 0.35, 0.35, Vector3.yAxis, COUL_AUBERGE.Bois, M.Bois, "RiveToit")
		end
	end
	-- Chevrons sous les pans, placés hors de l'ouverture du conduit.
	for _, x in {-11, 0, 11} do
		for _, z in {zAvant, zArriere} do
			K.poutre(V(x, bas - 0.45, z), V(x, haut - 0.45, zCentre), 0.28, 0.28, Vector3.yAxis, COUL_AUBERGE.Bois, M.Bois, "Chevron")
		end
	end
	-- Deux montants rattachent l'enseigne conservée à l'avant-toit.
	for _, x in {-4, 4} do
		K.poutre(V(x, 13.9, -10.35), V(x, 15.6, -10.35), 0.3, 0.3, Vector3.new(0, 0, -1), COUL_AUBERGE.Bois, M.Bois, "SupportEnseigne")
	end
	for _, p in toiture:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored, p.CanTouch, p.CanQuery = true, false, false end
	end
	-- Aligner la face arrière en plâtre avec la pierre sans déplacer cette dernière.
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and p.Name == "MurFond" and p.Material == M.Platre and math.abs(p.Size.Z - murPierre.Size.Z) > FORGE_TOLERANCE_MUR then
			p.Size = Vector3.new(p.Size.X, p.Size.Y, murPierre.Size.Z)
		end
	end
	-- Retirer les anciens pans et le pignon sans fenêtre de l'ancien toit
	-- transversal. Ses colombages sont précisément centrés dans le plan
	-- de façade ; le fronton et les pignons latéraux restent intacts.
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") then
			local q = cf:PointToObjectSpace(p.Position)
			local ancienPan = p.Name == "Toit" or p.Name == "RangTuiles" or p.Name == "RiveToit" or p.Name == "Faitage"
			local pignonFacade = p.Name == "Pignon" and math.abs(q.Z + 9.7) < 0.02 and q.Y > 14.5 and math.abs(q.X) < 6.3
			local boisFacade = p.Name == "Colombage" and math.abs(q.X) < 6.3 and
				((math.abs(q.Z + 10.05) < 0.02 and q.Y > 14.5) or (math.abs(q.Z + 10) < 0.02 and math.abs(q.Y - 14.2) < 0.02))
			if ancienPan or pignonFacade or boisFacade then p:Destroy() end
		end
	end
	toiture.Parent = forge
	forge:SetAttribute("VersionToitForge", 1)
end

-- Les parements des colombages sont décalés aux intersections, avec leur dos dans le plâtre.
function B.preparerColombagesForge(forge)
	local murPlatre
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and p.Name == "MurFond" and p.Material == M.Platre then
			murPlatre = p
			break
		end
	end
	if not murPlatre then return end
	local faceInterieure = -murPlatre.Size.Z / 2
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Colombage" or p.Name == "CroixColombage") then
			local centre = murPlatre.CFrame:PointToObjectSpace(p.Position)
			local axe = murPlatre.CFrame:VectorToObjectSpace(p.CFrame.LookVector)
			local normale = murPlatre.CFrame:VectorToObjectSpace(p.CFrame.UpVector)
			if normale.Z < -0.99 and math.abs(centre.Z - faceInterieure) < 0.5
				and math.abs(centre.X) <= murPlatre.Size.X / 2 + 0.01
				and math.abs(centre.Y) < murPlatre.Size.Y / 2 then
				local diagonale = math.abs(axe.X) > 0.25 and math.abs(axe.Y) > 0.25
				local saillie = if math.abs(axe.X) > 0.99 then 0.04 else 0.025
				if diagonale then
					saillie = if axe.X * axe.Y > 0 then 0.08 else 0.05
					p.Name = "CroixColombage"
				end
				local z = faceInterieure + p.Size.Y / 2 - saillie
				p.CFrame += murPlatre.CFrame.ZVector * (z - centre.Z)
				p.Material = M.Bois
				p.Color = COUL_AUBERGE.Bois
			end
		end
	end
end

function B.preparerAmenagementForge(forge)
	local sol = forge:FindFirstChild("Sol")
	if not (sol and sol:IsA("BasePart")) then return end
	local dessus = sol.Position.Y + sol.Size.Y / 2
	if not forge:GetAttribute("SolForgeCorrige") then
		-- Le terrain de la place arrive deux studs au-dessus du repère de la forge.
		local repere = sol.CFrame
		dessus += 1.1
		for _, p in forge:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Sol" or p.Name == "Seuil") then
				local hausse = dessus - (p.Position.Y + p.Size.Y / 2)
				p.Size += Vector3.new(0, hausse, 0)
				p.CFrame += Vector3.yAxis * (hausse / 2)
			elseif p:IsA("BasePart") and p.Name == "Billot" then
				-- Le billot est un cylindre vertical dont l'épaisseur suit son axe X.
				local haut = p.Position.Y + p.Size.X / 2
				if haut > dessus then
					p.Size = Vector3.new(haut - dessus, p.Size.Y, p.Size.Z)
					p.CFrame += Vector3.yAxis * ((haut + dessus) / 2 - p.Position.Y)
				end
			elseif p:IsA("BasePart") and p.Name == "Barre" then
				p.CFrame += Vector3.yAxis * 0.55
			elseif p:IsA("Model") and p.Name == "Epee" then
				p:PivotTo(p:GetPivot() + Vector3.yAxis * 0.55)
			end
		end
		-- Sur les cartes figées, relever la caisse basse qui borde la forge.
		for _, objet in forge.Parent:GetChildren() do
			local corps = objet.Name == "Caisse" and objet:FindFirstChild("Corps")
			if objet:IsA("Model") and corps and corps:IsA("BasePart") then
				local p = repere:PointToObjectSpace(corps.Position)
				local hausse = dessus - 0.1 - (corps.Position.Y - corps.Size.Y / 2)
				if math.abs(p.X - 13.6) < 0.25 and math.abs(p.Z + 4) < 0.25 and hausse > 0.05 then
					objet:PivotTo(objet:GetPivot() + Vector3.yAxis * hausse)
				end
			end
		end
		forge:SetAttribute("SolForgeCorrige", true)
	end

	local fourneau = forge:FindFirstChild("Fourneau")
	local base = fourneau and fourneau:GetAttribute("Base")
	if fourneau and fourneau:IsA("Model") and typeof(base) == "CFrame" then
		local decalage = Vector3.yAxis * (dessus - base.Y)
		fourneau:PivotTo(fourneau:GetPivot() + decalage)
		fourneau:SetAttribute("Base", base + decalage)
	end
end

-- Balustrades en bois sur les deux côtés ouverts de l'atelier, entre le poteau de façade (z = -9)
-- et le début du mur latéral (z = -1). Même style que celles du quai de la mine.
-- Modèle « BalustradesForge » : Village.preparerAteliers le pose aussi sur les cartes figées.
function B.preparerBalustradesForge(forge)
	if forge:FindFirstChild("BalustradesForge") then return end
	local murPierre, sol = nil, forge:FindFirstChild("Sol")
	for _, p in forge:GetChildren() do
		if p:IsA("BasePart") and p.Name == "MurFond" and p.Material == M.Pierre then murPierre = p break end
	end
	if not (murPierre and sol and sol:IsA("BasePart")) then warn("[Forge] Mur ou sol absent : balustrades non posées") return end
	local cf = murPierre.CFrame * CFrame.new(0, -5.5, -9) -- repère de la forge
	local dessus = sol.Position.Y + sol.Size.Y / 2
	local m = Instance.new("Model")
	m.Name = "BalustradesForge"
	local function point(x, z)
		local p = cf * Vector3.new(x, 0, z)
		return Vector3.new(p.X, dessus, p.Z)
	end
	local function balustrade(a, b)
		local longueur = (b - a).Magnitude
		local repere = CFrame.lookAt(a, b) -- axe -Z local le long de la balustrade
		local poteaux = math.max(1, math.ceil(longueur / 3.4))
		for i = 0, poteaux do
			local d = longueur * i / poteaux
			O.bloc(m, Vector3.new(0.5, 3.1, 0.5), repere * CFrame.new(0, 1.55, -d), C.BoisFonce, M.Bois, "PoteauBalustrade")
			O.decor(O.bloc(m, Vector3.new(0.65, 0.25, 0.65), repere * CFrame.new(0, 3.2, -d), C.BoisFonce, M.Bois, "ChapeauBalustrade"))
			if i < poteaux then
				for k = 1, 3 do
					O.decor(O.bloc(m, Vector3.new(0.22, 2.3, 0.22), repere * CFrame.new(0, 1.35, -(d + longueur / poteaux * k / 4)), C.Bois, M.Bois, "Barreau"))
				end
			end
		end
		O.bloc(m, Vector3.new(0.45, 0.35, longueur + 0.5), repere * CFrame.new(0, 2.9, -longueur / 2), C.Bois, M.Planches, "MainCourante")
		O.decor(O.bloc(m, Vector3.new(0.3, 0.25, longueur), repere * CFrame.new(0, 0.35, -longueur / 2), C.Bois, M.Bois, "Lisse"))
	end
	for _, s in {-1, 1} do
		balustrade(point(s * 11, -8.3), point(s * 11, -1))
	end
	m.Parent = forge
end

-- Affine les panneaux en conservant la position de leur face extérieure.
function B.affinerMursForge(forge)
	local toiture = forge:FindFirstChild("Forge_Toit")
	local pan = toiture and toiture:FindFirstChild("Toit")
	local sol = forge:FindFirstChild("Sol")
	if not (pan and pan:IsA("BasePart") and sol and sol:IsA("BasePart")) then return end

	local epaisseur = pan.Size.Y
	local axe = sol.CFrame.XVector
	local enfants = forge:GetChildren()
	local anciensMurs = {}
	for _, p in enfants do
		if p:IsA("BasePart") and p.Name == "MurCote" then
			local x = axe:Dot(p.Position - sol.Position)
			local cote = math.sign(x)
			local retrait = p.Size.X - epaisseur
			if retrait > 0.001 then
				if p.Material == M.Pierre then
					anciensMurs[cote] = {faceInterieure = math.abs(x) - p.Size.X / 2, retrait = retrait}
				end
				p.Size = Vector3.new(epaisseur, p.Size.Y, p.Size.Z)
				p.CFrame += axe * (cote * retrait / 2)
			end
		end
	end

	-- Le râtelier et ses objets restent à la même distance de la face intérieure.
	-- Les fenêtres des pignons et les lanternes des poteaux gardent leurs supports.
	for _, objet in enfants do
		local barre = objet:IsA("BasePart") and objet.Name == "Barre"
		local modele = objet:IsA("Model") and (objet.Name == "Epee" or objet.Name == "Forge_PiochesMurales")
		if barre or modele then
			local pivot = if barre then objet.CFrame else objet:GetPivot()
			local x = axe:Dot(pivot.Position - sol.Position)
			local cote = math.sign(x)
			local mur = anciensMurs[cote]
			if mur and math.abs(math.abs(x) - mur.faceInterieure) < 0.8 then
				local position = pivot + axe * (cote * mur.retrait)
				if barre then objet.CFrame = position else objet:PivotTo(position) end
			end
		end
	end
end

-- La forge du forgeron : atelier ouvert (même structure qu'avant), dans le style des maisons du village :
-- murs de pierre et colombages, toit de tuiles à deux pans, pignon de façade avec l'enseigne, bannières et lanternes.
function B.forge(parent, cf)
	local m = O.modele(parent, "Forge")
	local K = kitMaison(m, cf, {prestige = true, couleur = Color3.fromRGB(196, 92, 34), rng = Random.new(77), lierre = false})
	local V, bloc, poutre = K.V, K.bloc, K.poutre
	O.bloc(m, Vector3.new(24, 1, 20), cf * CFrame.new(0, 0.5, 0), C.PierreFoncee, M.Pierre, "Sol")
	bloc(Vector3.new(24.6, 0.5, 1.4), V(0, 0.25, -10.6), COUL_AUBERGE.PierreClaire, M.Pierre, "Seuil")

	-- mur du fond : pierre jusqu'à 10, colombages au-dessus (côté atelier)
	bloc(Vector3.new(24, 9, 2), V(0, 5.5, 9), COUL_AUBERGE.Pierre, M.Pierre, "MurFond")
	bloc(Vector3.new(24, 4.2, 2), V(0, 12.1, 9), K.platre, M.Platre, "MurFond")
	local nFond = Vector3.new(0, 0, -1)
	for _, y in {10.2, 13.9} do
		poutre(V(-12, y, 8.15), V(12, y, 8.15), 0.4, 0.3, nFond)
	end
	for i = 0, 8 do
		local x = -12 + i * 3
		poutre(V(x, 10.2, 8.15), V(x, 13.9, 8.15), 0.38, 0.3, nFond)
		if i < 8 and i % 2 == 0 then
			O.decor(poutre(V(x, 10.3, 8.1), V(x + 3, 13.8, 8.1), 0.26, 0.26, nFond))
			O.decor(poutre(V(x + 3, 10.3, 8.1), V(x, 13.8, 8.1), 0.26, 0.26, nFond))
		end
	end
	K.pierres(-12, 12, 8, 1, 10, 30)
	K.poserPierres()

	-- murs latéraux : pierre en bas, plâtre et colombages en haut (faces extérieures)
	for _, s in {-1, 1} do
		bloc(Vector3.new(2, 9, 10), V(s * 11, 5.5, 4), COUL_AUBERGE.Pierre, M.Pierre, "MurCote")
		bloc(Vector3.new(2, 4, 10), V(s * 11, 12, 4), K.platre, M.Platre, "MurCote")
		local ns = Vector3.new(-s, 0, 0) -- normale extérieure (x local = -xv)
		local xf = s * 12.1
		for _, z in {-1, 4, 9} do
			poutre(V(xf, 10, z), V(xf, 14, z), 0.4, 0.3, ns)
		end
		for _, y in {10.1, 13.9} do
			poutre(V(xf, y, -1), V(xf, y, 9), 0.4, 0.3, ns)
		end
		O.decor(poutre(V(xf, 10.2, -1), V(xf, 13.8, 4), 0.28, 0.26, ns))
		O.decor(poutre(V(xf, 10.2, 9), V(xf, 13.8, 4), 0.28, 0.26, ns))
		-- poteaux de façade et aisseliers
		bloc(Vector3.new(1.4, 13, 1.4), V(s * 11, 7.5, -9), COUL_AUBERGE.Bois, M.Bois, "Poteau")
		poutre(V(s * 11, 10.6, -9), V(s * 9, 13.0, -9), 0.5, 0.5, Vector3.new(0, 0, -1))
		B.applique(m, cf * CFrame.new(V(s * 11, 6, -9.7)))
	end
	bloc(Vector3.new(24.4, 1.4, 1.4), V(0, 13.3, -9), COUL_AUBERGE.Bois, M.Bois, "Sabliere")

	-- toit à deux pans (faîtage parallèle à la façade) et pignons latéraux
	local zAv, zAr, yBas, yHaut = -9.7, 9.9, 14, 21
	local hw = (zAr - zAv) / 2 - 0.5 / ((yHaut - yBas) / ((zAr - zAv) / 2))
	for _, s in {-1, 1} do
		K.pignon(V(s * 12.3, yBas + 0.5, (zAv + zAr) / 2), Vector3.new(0, 0, s), Vector3.new(-s, 0, 0), hw, yHaut - yBas - 0.5, 1, false, true)
	end
	-- pignon de façade au-dessus de l'atelier, avec l'enseigne
	B.fronton(m, cf * CFrame.new(0, 15.9, -10.0), "FORGERON", 9)
	K.bannieres({-9.4, 9.4}, -9.4, 12.6)

	-- Fourneau (foyer voûté, hotte, cheminée, soufflet)
	B.fourneau(m, cf * CFrame.new(-5, 1, 6))

	-- Enclume sur billot
	local enclume = cf * CFrame.new(2, 1, -1)
	O.cylindre(m, 2.4, 2.4, enclume * CFrame.new(0, 1.2, 0), C.Bois, M.Bois, "Billot")
	O.bloc(m, Vector3.new(1.2, 1, 0.9), enclume * CFrame.new(0, 2.9, 0), C.Fer, M.Metal, "Pied")
	O.bloc(m, Vector3.new(2.8, 0.8, 1.2), enclume * CFrame.new(0, 3.8, 0), C.Fer, M.Metal, "Table")
	O.coin(m, Vector3.new(1.2, 0.8, 1.4), enclume * CFrame.new(-2.1, 3.8, 0) * CFrame.Angles(0, math.pi / 2, 0), C.Fer, M.Metal, "Bigorne")
	-- Baquet de trempe
	O.cylindre(m, 2, 3, cf * CFrame.new(6.5, 2, 5.5), C.Bois, M.Bois, "Baquet")
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
	B.preparerAmenagementForge(m)
	B.preparerToitForge(m)
	B.preparerColombagesForge(m)
	B.preparerBalustradesForge(m)
	B.affinerMursForge(m)
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

-- Tonneau : corps en bois (la matière « planches » se déforme en rayures sur un cylindre), couvercle, 3 cercles de fer
-- diametre (facultatif, 2.4 par défaut) : élargi pour recouvrir un ancien tonneau plus gros
function B.tonneau(parent, cf, diametre)
	local d = diametre or 2.4
	local m = O.modele(parent, "Tonneau")
	O.cylindre(m, 3.2, d, cf * CFrame.new(0, 1.6, 0), C.Bois, M.Bois, "Corps")
	O.decor(O.cylindre(m, 0.08, d - 0.3, cf * CFrame.new(0, 3.22, 0), C.BoisFonce, M.Bois, "Couvercle"))
	for _, y in {0.45, 1.6, 2.75} do
		O.decor(O.cylindre(m, 0.22, d + 0.12, cf * CFrame.new(0, y, 0), C.Fer, M.Metal, "Cercle"))
	end
	return m
end

-- Tonneaux qui traversent une autre pièce (mur, poteau, plancher…) : les surfaces se croisent et scintillent.
-- On décale chacun vers la place libre la plus proche (8 directions, jusqu'à 4 studs), toujours posée sur un sol.
function B.degagerTonneaux(racine)
	local corrige = 0
	-- Tonneaux 3D des maisons importées (un seul mesh par façade) : presque entièrement enterrés sous le terrain,
	-- on ne voyait que leur couvercle (mesh « Colombage ») et leurs cercles (mesh « Fer ») au ras de l'herbe, en
	-- scintillant. On repère chaque tonneau du mesh (rayons verticaux), on retire le mesh et on pose à sa place
	-- un vrai tonneau sur l'herbe (il recouvre le couvercle et les cercles restants).
	-- Un tonneau posé à la place d'un tonneau du mesh porte l'attribut « CouvreReste » : il doit rester pile
	-- au-dessus des restes (couvercle, cercles), sinon un bout de l'ancien tonneau dépasse à côté.
	local nosTonneaux = {} -- {modele, position}
	for _, t in racine:GetDescendants() do
		local corps = t:IsA("Model") and t.Name == "Tonneau" and t:FindFirstChild("Corps")
		if corps and corps:IsA("BasePart") then table.insert(nosTonneaux, {t, corps.Position}) end
	end
	for _, mesh in racine:GetDescendants() do
		if mesh:IsA("BasePart") and mesh.Name == "Auberge_Decor_Tonneau" and mesh.Parent then
			mesh.CanQuery = true
			local seul = RaycastParams.new()
			seul.FilterType = Enum.RaycastFilterType.Include
			seul.FilterDescendantsInstances = {mesh}
			local groupes = {} -- {somme, nombre, points}
			local demi = mesh.Size / 2
			for x = -demi.X, demi.X, 0.6 do
				for z = -demi.Z, demi.Z, 0.6 do
					local p = (mesh.CFrame * CFrame.new(x, 0, z)).Position
					local touche = workspace:Raycast(p + Vector3.new(0, demi.Y + 2, 0), Vector3.new(0, -(mesh.Size.Y + 4), 0), seul)
					if touche then
						local q = touche.Position * Vector3.new(1, 0, 1)
						local g = nil
						for _, e in groupes do
							if (e[1] / e[2] - q).Magnitude < 1.8 then g = e; break end
						end
						if g then g[1] += q; g[2] += 1; table.insert(g[3], q) else table.insert(groupes, {q, 1, {q}}) end
					end
				end
			end
			local parent = mesh.Parent
			local yBasMesh = mesh.Position.Y - demi.Y
			mesh:Destroy()
			corrige += 1
			for _, g in groupes do
				local c = g[1] / g[2]
				if g[2] >= 3 then
					-- largeur de l'ancien tonneau vu d'en haut (+ ses cercles de fer et le pas de la grille)
					local rayon = 0
					for _, q in g[3] do rayon = math.max(rayon, (q - c).Magnitude) end
					local diametre = math.clamp(2 * (rayon + 0.45), 2.4, 3.6)
					local proche = nil
					for i, e in nosTonneaux do
						if (e[2] * Vector3.new(1, 0, 1) - c).Magnitude < 2.6 then proche = i; break end
					end
					local y, parentTonneau = yBasMesh, parent
					if proche then
						-- un de nos tonneaux est déjà à côté : on le remplace par un tonneau pile sur l'ancien
						local ancien = nosTonneaux[proche][1]
						parentTonneau = ancien.Parent
						y = nosTonneaux[proche][2].Y - 1.6
						ancien:Destroy()
						table.remove(nosTonneaux, proche)
					end
					local t = B.tonneau(parentTonneau, CFrame.new(c.X, y, c.Z), diametre) -- remonté sur l'herbe juste après
					t:SetAttribute("CouvreReste", true)
					table.insert(nosTonneaux, {t, Vector3.new(c.X, y + 1.6, c.Z)})
				end
			end
		end
	end
	-- Tonneaux enfoncés dans le terrain (sol plus haut que prévu) : on les remonte sur l'herbe
	local terrain = RaycastParams.new()
	terrain.FilterType = Enum.RaycastFilterType.Include
	terrain.FilterDescendantsInstances = {workspace.Terrain}
	for _, tonneau in racine:GetDescendants() do
		local corps = tonneau.Parent and tonneau:IsA("Model") and tonneau.Name == "Tonneau" and tonneau:FindFirstChild("Corps")
		if corps and corps:IsA("BasePart") then
			local bas = corps.Position.Y - corps.Size.X / 2
			local sol = workspace:Raycast(Vector3.new(corps.Position.X, bas + 3, corps.Position.Z), Vector3.new(0, -6, 0), terrain)
			if sol and sol.Position.Y > bas + 0.05 then
				local monte = sol.Position.Y - bas
				local haut = bas + corps.Size.X
				-- les tonneaux empilés dessus montent avec lui
				for _, autre in racine:GetDescendants() do
					local c2 = autre ~= tonneau and autre:IsA("Model") and autre.Name == "Tonneau" and autre:FindFirstChild("Corps")
					if c2 and c2:IsA("BasePart") then
						local deja = autre:GetAttribute("Monte") or 0 -- posé sur deux tonneaux : on suit le plus haut, sans cumuler
						local bas2 = c2.Position.Y - c2.Size.X / 2 - deja
						if math.abs(bas2 - haut) < 0.4 and ((c2.Position - corps.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 and monte > deja then
							autre:TranslateBy(Vector3.new(0, monte - deja, 0))
							autre:SetAttribute("Monte", monte)
						end
					end
				end
				tonneau:TranslateBy(Vector3.new(0, monte, 0))
				corrige += 1
			end
		end
	end
	for _, tonneau in racine:GetDescendants() do
		local corps = tonneau.Parent and tonneau:IsA("Model") and tonneau.Name == "Tonneau" and tonneau:FindFirstChild("Corps")
		if corps and corps:IsA("BasePart") and not tonneau:GetAttribute("CouvreReste") then
			local filtre = OverlapParams.new()
			filtre.FilterType = Enum.RaycastFilterType.Exclude
			filtre.FilterDescendantsInstances = {tonneau}
			-- vrai si le corps, décalé de « decal », ne traverse aucune pièce visible
			local function libre(decal)
				local origine = corps.CFrame
				corps.CFrame = origine + decal
				local touche = false
				for _, p in workspace:GetPartsInPart(corps, filtre) do
					if p.Transparency < 1 then touche = true; break end
				end
				corps.CFrame = origine
				return not touche
			end
			if not libre(Vector3.zero) then
				local rayons = RaycastParams.new()
				rayons.FilterType = Enum.RaycastFilterType.Exclude
				rayons.FilterDescendantsInstances = {tonneau}
				local trouve = nil
				for d = 0.5, 4, 0.5 do
					for k = 0, 7 do
						local a = k * math.pi / 4
						local decal = Vector3.new(math.cos(a), 0, math.sin(a)) * d
						local bas = corps.Position + decal - Vector3.new(0, corps.Size.X / 2 - 0.3, 0)
						local sol = workspace:Raycast(bas + Vector3.new(0, 0.5, 0), Vector3.new(0, -1.5, 0), rayons)
						if sol and libre(decal) then trouve = decal; break end
					end
					if trouve then break end
				end
				if trouve then
					tonneau:TranslateBy(trouve)
					corrige += 1
				end
			end
		end
	end
	return corrige
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

-- Banc de la place : planche épaisse entre deux bacs en pierre fleuris.
-- cf est posé au sol, l'assise tournée vers -Z.
local FLEURS_BANC = {
	Color3.fromRGB(212, 83, 126), Color3.fromRGB(239, 159, 39),
	Color3.fromRGB(127, 119, 221), Color3.fromRGB(240, 226, 190),
}
function B.bancJardinieres(parent, cf, numero)
	local m = O.modele(parent, "Banc")
	m:SetAttribute("VersionBanc", 2)
	local rng = Random.new(numero or 1)
	local feuillage = Color3.fromRGB(78, 120, 42)
	local feuillageFonce = Color3.fromRGB(52, 92, 30)
	-- Assise : trois lattes posées sur une traverse sombre
	for i, z in {-0.6, 0, 0.6} do
		local latte = O.bloc(m, Vector3.new(4.9, 0.4, 0.56), cf * CFrame.new(0, 1.8, z), C.BoisClair, M.Planches, "Assise")
		if i == 2 then m.PrimaryPart = latte end
	end
	O.decor(O.bloc(m, Vector3.new(4.7, 0.3, 0.4), cf * CFrame.new(0, 1.45, 0), C.BoisFonce, M.Bois, "Traverse"))
	-- Deux places assises invisibles, tournées vers l'avant du banc (-Z)
	for _, x in {-1.2, 1.2} do
		local siege = Instance.new("Seat")
		siege.Name = "SiegeBanc"
		siege.Size = Vector3.new(2, 0.2, 1.6)
		siege.CFrame = cf * CFrame.new(x, 2.05, 0)
		siege.Anchored = true
		siege.CanCollide = false
		siege.CanTouch = false -- on s'assied avec E, pas en marchant dessus
		siege.Transparency = 1
		siege.Parent = m
		local invite = Instance.new("ProximityPrompt")
		invite.Name = "AsseoirBanc"
		invite.ActionText = "S'asseoir"
		invite.ObjectText = "Banc"
		invite.KeyboardKeyCode = Enum.KeyCode.E
		invite.GamepadKeyCode = Enum.KeyCode.ButtonX
		invite.MaxActivationDistance = 7
		invite.RequiresLineOfSight = false
		invite.Parent = siege
		siege:GetPropertyChangedSignal("Occupant"):Connect(function()
			invite.Enabled = siege.Occupant == nil
		end)
	end
	for _, cote in {-1, 1} do
		local x = cote * 3.35
		-- Bac en pierre
		O.bloc(m, Vector3.new(2, 2.2, 2), cf * CFrame.new(x, 1.1, 0), C.Pierre, M.Pierre, "Bac")
		for _, p in {{-0.45, 0.6}, {0.4, 1.45}} do
			O.decor(O.bloc(m, Vector3.new(0.8, 0.5, 0.08), cf * CFrame.new(x + p[1], p[2], -1.03), C.PierreClaire, M.Pierre, "Moellon"))
		end
		-- Rebord et terre
		for _, r in {{0, -0.95, 2.3, 0.4}, {0, 0.95, 2.3, 0.4}, {-0.95, 0, 0.4, 1.5}, {0.95, 0, 0.4, 1.5}} do
			O.decor(O.bloc(m, Vector3.new(r[3], 0.3, r[4]), cf * CFrame.new(x + r[1], 2.35, r[2]), C.PierreFoncee, M.Pierre, "Rebord"))
		end
		O.decor(O.bloc(m, Vector3.new(1.5, 0.2, 1.5), cf * CFrame.new(x, 2.25, 0), C.Terre, M.Terre, "TerreBac"))
		-- Feuillage en blocs et quelques fleurs
		O.decor(O.bloc(m, Vector3.new(1.2, 0.8, 1.2), cf * CFrame.new(x, 2.7, 0), feuillage, M.Herbe, "Feuillage"))
		O.decor(O.bloc(m, Vector3.new(0.6, 0.7, 0.6), cf * CFrame.new(x + 0.2, 3.3, 0.15), feuillageFonce, M.Herbe, "Feuillage"))
		for _ = 1, 3 do
			local fx, fz = rng:NextNumber(-0.55, 0.55), rng:NextNumber(-0.55, 0.55)
			local couleur = FLEURS_BANC[rng:NextInteger(1, #FLEURS_BANC)]
			O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(x + fx, rng:NextNumber(3.1, 3.6), fz), couleur, M.Lisse, "Fleur"))
		end
	end
	return m
end

-- Moulin à eau en blocs : rez-de-chaussée en pierre, étage à colombages, toit à deux pans, potence à sacs.
-- cf est posé au sol, la façade (porte) vers +Z, le mur arrière (côté rivière) à z local -6.
-- axeRoue : CFrame du moyeu de la roue (axe X local = axe de rotation, -X vers le moulin).
-- Le mécanisme relie la roue au moulin : arbre + rouet (tournent avec la roue), lanterne + arbre
-- vertical (tournent plus vite) qui monte jusqu'au coffre des meules sur le mur arrière.
function B.moulin(parent, cf, axeRoue)
	local m = O.modele(parent, "MoulinSud")
	m:SetAttribute("VersionMoulin", 2)
	local function b(taille, pos, couleur, mat, nom, angles)
		local c = cf * CFrame.new(pos)
		if angles then c = c * angles end
		return O.bloc(m, taille, c, couleur, mat, nom)
	end
	local V = Vector3.new
	local platre = C.Platre
	local poutre = C.BoisFonce

	-- Rez-de-chaussée en pierre
	b(V(14.8, 0.8, 12.8), V(0, 0.4, 0), C.PierreFoncee, M.Pierre, "Socle")
	b(V(14, 8, 12), V(0, 4, 0), C.Pierre, M.Pierre, "MurPierre")
	for _, sx in {-1, 1} do
		for _, sz in {-1, 1} do
			O.decor(b(V(1.4, 8.2, 1.4), V(sx * 6.6, 4.1, sz * 5.6), C.PierreFoncee, M.Pierre, "Chaine"))
		end
	end
	-- Étage à colombages
	b(V(14.4, 6, 12.4), V(0, 11, 0), platre, M.Platre, "MurColombage")
	for _, y in {8.25, 13.75} do
		for _, sz in {-1, 1} do
			O.decor(b(V(14.6, 0.5, 0.4), V(0, y, sz * 6.25), poutre, M.Bois, "Sabliere"))
		end
		for _, sx in {-1, 1} do
			O.decor(b(V(0.4, 0.5, 12.6), V(sx * 7.25, y, 0), poutre, M.Bois, "Sabliere"))
		end
	end
	for _, sz in {-1, 1} do
		for _, x in {-7, -3.5, 3.5, 7} do
			O.decor(b(V(0.45, 6, 0.4), V(x, 11, sz * 6.25), poutre, M.Bois, "Poteau"))
		end
		for _, sx in {-1, 1} do
			O.decor(b(V(0.35, 6.5, 0.35), V(sx * 5.25, 11, sz * 6.27), poutre, M.Bois, "Croix",
				CFrame.Angles(0, 0, sx * math.rad(32))))
		end
	end
	for _, sx in {-1, 1} do
		for _, z in {-6, -2, 2, 6} do
			O.decor(b(V(0.4, 6, 0.45), V(sx * 7.25, 11, z), poutre, M.Bois, "Poteau"))
		end
	end
	-- Pignons en gradins et toit à deux pans (faîtage est-ouest)
	for i = 0, 3 do
		b(V(14.4, 1.09, 12.4 * (1 - (i + 0.5) / 4)), V(0, 14 + (i + 0.5) * 1.085, 0), platre, M.Platre, "Pignon")
	end
	for _, sz in {-1, 1} do
		b(V(16, 0.6, 8.6), V(0, 16.2, sz * 3.5), C.ToitRouge, M.Tuiles, "Toit", CFrame.Angles(sz * math.rad(35), 0, 0))
	end
	O.decor(b(V(16.2, 0.7, 0.9), V(0, 18.7, 0), poutre, M.Bois, "Faitage"))
	-- Porte, marches, enseigne
	b(V(3.4, 4.8, 0.3), V(0, 3.2, 6.1), C.Bois, M.Planches, "Porte")
	O.decor(b(V(4.4, 0.7, 0.5), V(0, 5.9, 6.15), poutre, M.Bois, "Linteau"))
	for _, sx in {-1, 1} do
		O.decor(b(V(0.5, 5.2, 0.5), V(sx * 1.95, 3.1, 6.15), poutre, M.Bois, "Montant"))
	end
	b(V(4.6, 0.5, 1.4), V(0, 0.25, 6.9), C.PierreFoncee, M.Pierre, "Marche")
	local enseigne = O.decor(b(V(5, 1.3, 0.25), V(0, 7.1, 6.2), C.BoisClair, M.Planches, "Enseigne"))
	O.texte(enseigne, Enum.NormalId.Back, "MOULIN")
	-- Fenêtres (étage partout, petites fenêtres en pierre sur les côtés)
	local function fenetre(pos, taille, allumee)
		local vitre = b(taille, pos, allumee and C.Fenetre or C.Vitre, allumee and M.Neon or M.Verre, "Fenetre")
		O.decor(vitre)
		if allumee then O.lumiere(vitre, C.Lumiere, 0.6, 10) end
	end
	for _, sz in {-1, 1} do
		for _, x in {-5.25, 5.25} do
			fenetre(V(x, 11.3, sz * 6.32), V(1.8, 2, 0.2), x > 0)
		end
	end
	for _, sx in {-1, 1} do
		fenetre(V(sx * 7.32, 11.3, 0), V(0.2, 2, 1.8), sx < 0)
		fenetre(V(sx * 7.05, 4.6, 2.6), V(0.2, 1.6, 1.4), false)
	end
	-- Potence à sacs sur la façade
	O.decor(b(V(0.5, 0.5, 3), V(0, 16.6, 7.6), poutre, M.Bois, "Potence"))
	O.decor(b(V(0.4, 1.8, 0.4), V(0, 15.9, 6.4), poutre, M.Bois, "Potence"))
	O.decor(b(V(0.12, 3.2, 0.12), V(0, 14.9, 8.8), C.Toile, M.Tissu, "Corde"))
	O.decor(b(V(1.1, 1.3, 1), V(0, 12.7, 8.8), C.Toile, M.Tissu, "Sac"))
	for i, x in {-3.3, -4.4, 3.4} do
		b(V(1.2, 1.4, 1), V(x, 1.5, 7.4 + (i % 2) * 0.3), C.Toile, M.Tissu, "Sac")
	end
	b(V(1.8, 1.6, 1.8), V(4.8, 1.6, 7.5), C.Bois, M.Planches, "Caisse")

	-- ===== Mécanisme roue → moulin =====
	-- Arbre horizontal + rouet denté : tournent avec la roue (même pivot, même vitesse)
	local arbre = O.modele(m, "ArbreRoue")
	local noyau = O.disque(arbre, 0.4, 1.2, axeRoue, C.BoisFonce, M.Bois, "Noyau")
	O.disque(arbre, 10.6, 1.1, axeRoue * CFrame.new(-5.1, 0, 0), C.BoisFonce, M.Bois, "Arbre")
	for _, x in {-2.6, -5.6, -9.4} do
		O.disque(arbre, 0.25, 1.3, axeRoue * CFrame.new(x, 0, 0), C.Fer, M.Metal, "Frette")
	end
	local rouet = axeRoue * CFrame.new(-7.5, 0, 0)
	O.disque(arbre, 0.6, 4.6, rouet, C.Bois, M.Planches, "Rouet")
	for i = 0, 13 do
		O.bloc(arbre, Vector3.new(0.6, 0.7, 0.6), rouet * CFrame.Angles(i * math.pi / 7, 0, 0) * CFrame.new(0, 2.55, 0), C.BoisFonce, M.Bois, "Dent")
	end
	O.decorModele(arbre)
	arbre.PrimaryPart = noyau
	arbre:SetAttribute("Vitesse", 0.5)
	O.atomique(arbre)
	O.tag(arbre, "Rotatif")

	-- Lanterne + arbre vertical : engrène sur le haut du rouet, tourne plus vite
	local haut = rouet.Position + Vector3.new(0, 2.9, 0)
	local versMoulin = (cf.Position - axeRoue.Position) * Vector3.new(1, 0, 1)
	versMoulin = if versMoulin.Magnitude > 0 then versMoulin.Unit else Vector3.new(0, 0, 1)
	local centreLanterne = haut + versMoulin * 1.0 + Vector3.new(0, 0.55, 0)
	local pivotLanterne = CFrame.new(centreLanterne) * CFrame.Angles(0, 0, math.pi / 2) -- axe X local = vertical
	local lanterne = O.modele(m, "Lanterne")
	local noyauL = O.disque(lanterne, 0.3, 0.7, pivotLanterne, C.Fer, M.Metal, "Noyau")
	for _, dy in {-0.4, 0.45} do
		O.disque(lanterne, 0.25, 2.4, pivotLanterne * CFrame.new(dy, 0, 0), C.Bois, M.Planches, "Plateau")
	end
	for i = 0, 7 do
		local a = i * math.pi / 4
		O.bloc(lanterne, Vector3.new(0.25, 1.15, 0.25), CFrame.new(centreLanterne + Vector3.new(math.cos(a), -0.05, math.sin(a))),
			C.BoisFonce, M.Bois, "Fuseau")
	end
	local hautArbre = cf.Position.Y + 11.9
	local longueur = hautArbre - centreLanterne.Y
	O.disque(lanterne, longueur, 0.6, pivotLanterne * CFrame.new(longueur / 2, 0, 0), C.BoisFonce, M.Bois, "ArbreVertical")
	O.decorModele(lanterne)
	lanterne.PrimaryPart = noyauL
	lanterne:SetAttribute("Vitesse", 1.25)
	O.atomique(lanterne)
	O.tag(lanterne, "Rotatif")

	-- Pièces fixes : pile-palier dans la rivière, plaque du mur, fosse du rouet, potences et coffre des meules
	local function f(taille, pos, couleur, mat, nom)
		return O.bloc(m, taille, CFrame.new(pos), couleur, mat, nom)
	end
	local y = axeRoue.Position.Y
	local palier = axeRoue.Position + versMoulin * 3
	f(V(2.6, 8, 1.6), V(palier.X, y - 5.4, palier.Z), C.Pierre, M.Pierre, "Pile")
	f(V(2.2, 0.7, 1.6), V(palier.X, y - 0.9, palier.Z), C.BoisFonce, M.Bois, "Palier")
	O.decor(f(V(2.4, 0.35, 1.7), V(palier.X, y + 0.75, palier.Z), C.Fer, M.Metal, "Cerclage"))
	for _, dx in {-1.05, 1.05} do
		O.decor(f(V(0.3, 1.7, 1.7), V(palier.X + dx, y, palier.Z), C.Fer, M.Metal, "Cerclage"))
	end
	local mur = cf * CFrame.new(0, 0, -6)
	O.decor(f(V(2.6, 2.6, 0.25), V(mur.X, y, mur.Z - 0.15), C.Fer, M.Metal, "PlaqueArbre"))
	-- Fosse du rouet, creusée dans la berge et bordée de pierre
	local fosse = rouet.Position
	workspace.Terrain:FillBlock(CFrame.new(fosse.X, cf.Position.Y - 0.4, fosse.Z), V(7, 4.8, 3.6), Enum.Material.Air)
	f(V(7.6, 0.6, 3.8), V(fosse.X, fosse.Y - 3.4, fosse.Z), C.PierreFoncee, M.Pierre, "FondFosse")
	for _, dx in {-3.5, 3.5} do
		f(V(0.6, 3.2, 3.8), V(fosse.X + dx, fosse.Y - 1.6, fosse.Z), C.Pierre, M.Pierre, "BordFosse")
	end
	f(V(7.6, 3.2, 0.6), V(fosse.X, fosse.Y - 1.6, fosse.Z - versMoulin.Z * 2.1), C.Pierre, M.Pierre, "BordFosse")
	local mx, mz = centreLanterne.X, (centreLanterne.Z + mur.Z) / 2
	for _, dy in {3.2, 6.6} do
		O.decor(f(V(0.8, 0.5, math.abs(mur.Z - centreLanterne.Z) + 0.4), V(mx, centreLanterne.Y + dy, mz), C.BoisFonce, M.Bois, "Potence"))
		O.decor(f(V(1.1, 0.3, 1.1), V(mx, centreLanterne.Y + dy, centreLanterne.Z), C.Fer, M.Metal, "Collier"))
	end
	f(V(2.8, 2.4, math.abs(mur.Z - centreLanterne.Z) + 0.9), V(mx, hautArbre + 0.9, mz), C.BoisFonce, M.Planches, "CoffreMeules")
	O.decor(f(V(3.2, 0.3, math.abs(mur.Z - centreLanterne.Z) + 1.3), V(mx, hautArbre + 2.2, mz), C.ToitRouge, M.Tuiles, "CoffreToit"))
	return m
end

-- Jardinières de la gare. cf posé au sol ; la longueur suit l'axe Z local.
local FLEURS_JARDINIERE = {
	Color3.fromRGB(212, 83, 126), Color3.fromRGB(239, 159, 39),
	Color3.fromRGB(127, 119, 221), Color3.fromRGB(240, 226, 190),
}
local function fleurir(m, cf, largeur, longueur, y, rng)
	O.decor(O.bloc(m, Vector3.new(largeur, 0.55, longueur), cf * CFrame.new(0, y + 0.27, 0), Color3.fromRGB(78, 120, 42), M.Herbe, "Feuillage"))
	O.decor(O.bloc(m, Vector3.new(largeur * 0.55, 0.5, longueur * 0.45), cf * CFrame.new(largeur * 0.12, y + 0.75, -longueur * 0.18), Color3.fromRGB(58, 96, 34), M.Herbe, "Feuillage"))
	for _ = 1, math.max(3, math.floor(longueur * 2)) do
		local p = Vector3.new(rng:NextNumber(-largeur * 0.4, largeur * 0.4), y + rng:NextNumber(0.6, 1.05), rng:NextNumber(-longueur * 0.42, longueur * 0.42))
		O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(p), FLEURS_JARDINIERE[rng:NextInteger(1, #FLEURS_JARDINIERE)], M.Lisse, "Fleur"))
	end
end

-- Petit wagonnet de mine rouillé transformé en jardinière
function B.wagonnetFleuri(parent, cf, numero)
	local m = O.modele(parent, "WagonnetFleuri")
	local rouille = Color3.fromRGB(112, 64, 42)
	O.bloc(m, Vector3.new(2.2, 1.4, 3.2), cf * CFrame.new(0, 1.25, 0), rouille, M.Rouille, "Caisse")
	for _, z in {-1.1, 0, 1.1} do
		O.decor(O.bloc(m, Vector3.new(2.3, 1.2, 0.15), cf * CFrame.new(0, 1.25, z), C.Fer, M.Metal, "Renfort"))
	end
	for _, x in {-1, 1} do
		O.decor(O.bloc(m, Vector3.new(0.2, 0.2, 3.4), cf * CFrame.new(x * 1.12, 1.98, 0), C.Fer, M.Metal, "Rebord"))
		for _, z in {-0.95, 0.95} do
			O.decor(O.disque(m, 0.3, 1.05, cf * CFrame.new(x * 1.18, 0.52, z), C.Fer, M.Metal, "Roue"))
		end
	end
	O.decor(O.bloc(m, Vector3.new(1.95, 0.2, 2.95), cf * CFrame.new(0, 1.92, 0), C.Terre, M.Terre, "Terre"))
	fleurir(m, cf, 1.8, 2.8, 2, Random.new(numero or 1))
	return m
end

-- Caisse en planches fleurie, avec une petite lanterne plantée au milieu
function B.caisseLanterne(parent, cf, numero)
	local m = O.modele(parent, "CaisseLanterne")
	O.bloc(m, Vector3.new(1.9, 1.5, 1.9), cf * CFrame.new(0, 0.75, 0), Color3.fromRGB(150, 104, 62), M.Bois, "Caisse")
	for _, y in {0.18, 1.32} do
		O.decor(O.bloc(m, Vector3.new(1.98, 0.22, 1.98), cf * CFrame.new(0, y, 0), C.BoisFonce, M.Bois, "Latte"))
	end
	for _, x in {-0.88, 0.88} do
		for _, z in {-0.88, 0.88} do
			O.decor(O.bloc(m, Vector3.new(0.26, 1.55, 0.26), cf * CFrame.new(x, 0.77, z), C.BoisFonce, M.Bois, "Coin"))
		end
	end
	fleurir(m, cf, 1.7, 1.7, 1.5, Random.new(numero or 1))
	O.decor(O.bloc(m, Vector3.new(0.2, 1.1, 0.2), cf * CFrame.new(0, 2.5, 0), C.Fer, M.Metal, "Poteau"))
	cage(m, cf * CFrame.new(0, 3.6, 0), C.Lumiere, 14)
	return m
end

--[[ Ponton de pêche : passerelle sur pilotis, plateforme avec la cabane du pêcheur (colombages, toit
	rouge, cheminée qui fume), filets qui sèchent et coin de pêche.
	cf : départ de la passerelle sur la berge, au niveau du plancher ; -Z part au-dessus de l'eau.
	eau : distance du plancher jusqu'à la surface de l'eau (1.6 par défaut) ; longueur : passerelle (16). ]]
function B.pontonPeche(parent, cf, eau, longueur)
	eau = eau or 1.6
	local m = O.modele(parent, "PontonPeche")
	local rng = Random.new(7)
	local function a(x, y, z) return cf * CFrame.new(x, y, z) end
	local BOIS_MOUILLE = Color3.fromRGB(64, 50, 40)
	local PLANCHE = {Color3.fromRGB(134, 98, 64), Color3.fromRGB(120, 88, 58), Color3.fromRGB(146, 108, 72), Color3.fromRGB(112, 82, 56)}

	-- Passerelle : planches posées en travers, un peu irrégulières, sur deux longerons
	local LONG, LARGE = longueur or 16, 4
	for i = 0, LONG - 1 do
		local planche = O.bloc(m, Vector3.new(LARGE + rng:NextNumber(-0.15, 0.15), 0.3, 0.92),
			a(rng:NextNumber(-0.06, 0.06), -0.15, -0.5 - i) * CFrame.Angles(0, math.rad(rng:NextNumber(-1.2, 1.2)), 0),
			PLANCHE[rng:NextInteger(1, #PLANCHE)], M.Planches, "Planche")
		planche.TopSurface = Enum.SurfaceType.Smooth
	end
	for _, x in {-1.5, 1.5} do
		O.decor(O.bloc(m, Vector3.new(0.5, 0.5, LONG), a(x, -0.55, -LONG / 2), BOIS_MOUILLE, M.Bois, "Longeron"))
	end
	-- Plateforme du bout (cabane à droite, coin de pêche à gauche)
	local PD, PX = 7.5, 5.5
	local PZ0, PZ1 = -LONG, -LONG - PD
	for i = 0, math.ceil(PD) - 1 do
		O.bloc(m, Vector3.new(PX * 2 + rng:NextNumber(-0.1, 0.1), 0.3, 0.92), a(0, -0.15, PZ0 - 0.5 - i),
			PLANCHE[rng:NextInteger(1, #PLANCHE)], M.Planches, "Planche")
	end
	for _, x in {-PX + 0.4, 0, PX - 0.4} do
		O.decor(O.bloc(m, Vector3.new(0.5, 0.5, PD), a(x, -0.55, PZ0 - PD / 2), BOIS_MOUILLE, M.Bois, "Longeron"))
	end
	O.decor(O.bloc(m, Vector3.new(PX * 2 + 0.4, 0.45, 0.4), a(0, -0.1, PZ1 - 0.1), BOIS_MOUILLE, M.Bois, "Bordure"))

	-- Pilotis : troncs sombres qui plongent dans l'eau, cerclés de fer, un peu de mousse au ras de l'eau
	local pieux = {}
	for z = -3, -LONG, -4.5 do
		table.insert(pieux, Vector2.new(-2.15, z)); table.insert(pieux, Vector2.new(2.15, z))
	end
	for _, x in {-PX + 0.3, 0, PX - 0.3} do
		table.insert(pieux, Vector2.new(x, PZ0 - 0.4)); table.insert(pieux, Vector2.new(x, PZ1 + 0.3))
	end
	for _, p in pieux do
		local depasse = rng:NextNumber(0.2, 0.7)
		O.cylindre(m, 9 + depasse, 0.75, a(p.X, -4.5 + depasse / 2, p.Y), BOIS_MOUILLE, M.Bois, "Pieu")
		O.decor(O.cylindre(m, 0.2, 0.85, a(p.X, -0.9, p.Y), C.Fer, M.Metal, "Cercle"))
		O.decor(O.cylindre(m, 0.35, 0.82, a(p.X, -eau + 0.05, p.Y), Color3.fromRGB(62, 92, 48), M.Herbe, "Mousse"))
	end

	-- Cabane du pêcheur (porte vers la passerelle)
	local CX, CZ, CW, CD, CH = 2.6, PZ0 - 3.9, 5.4, 6, 4.6
	local function cabane(x, y, z) return a(CX + x, y, CZ + z) end
	O.bloc(m, Vector3.new(CW, 0.5, CD), cabane(0, 0.25, 0), C.PierreFoncee, M.Ardoise, "Soubassement")
	O.bloc(m, Vector3.new(CW - 0.6, CH, CD - 0.6), cabane(0, 0.5 + CH / 2, 0), C.Platre, M.Platre, "Murs")
	-- colombages : poteaux d'angle, sablière, traverses et croix de Saint-André
	for _, sx in {-1, 1} do
		for _, sz in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.5, CH, 0.5), cabane(sx * (CW / 2 - 0.3), 0.5 + CH / 2, sz * (CD / 2 - 0.3)), C.BoisFonce, M.Bois, "Poteau"))
		end
	end
	for _, y in {0.75, 0.5 + CH / 2, 0.5 + CH - 0.2} do
		O.decor(O.bloc(m, Vector3.new(CW + 0.05, 0.35, CD + 0.05), cabane(0, y, 0), C.BoisFonce, M.Bois, "Traverse"))
	end
	for _, sz in {-1, 1} do
		for _, s in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.3, 2.6, 0.3), cabane(sz * (CW / 2 + 0.01), 0.5 + CH * 0.75, s * 1.6) * CFrame.Angles(math.rad(s * 38), 0, 0),
				C.BoisFonce, M.Bois, "Croix"))
		end
	end
	-- porte (face -X, côté passerelle), fenêtre éclairée côté eau et côté berge
	O.bloc(m, Vector3.new(0.25, 3.4, 1.8), cabane(-CW / 2 + 0.2, 0.5 + 1.7, 1), C.Bois, M.Planches, "Porte")
	O.decor(O.bloc(m, Vector3.new(0.3, 0.2, 2.1), cabane(-CW / 2 + 0.2, 0.5 + 3.5, 1), C.BoisFonce, M.Bois, "Linteau"))
	O.decor(O.bloc(m, Vector3.new(0.3, 0.25, 0.25), cabane(-CW / 2 + 0.05, 0.5 + 1.7, 0.4), C.Fer, M.Metal, "Poignee"))
	for _, f in {{cabane(0, 0.5 + 3, -CD / 2 + 0.25), Vector3.new(1.8, 1.4, 0.2)}, {cabane(-CW / 2 + 0.25, 0.5 + 3, -1.8), Vector3.new(0.2, 1.4, 1.6)}} do
		local vitre = O.decor(O.bloc(m, f[2], f[1], C.Fenetre, M.Neon, "Fenetre"))
		vitre.Transparency = 0.15
		O.decor(O.bloc(m, Vector3.new(f[2].X > 1 and f[2].X + 0.4 or 0.6, 0.2, f[2].Z > 1 and f[2].Z + 0.4 or 0.6), f[1] * CFrame.new(0, -0.8, 0), C.Bois, M.Bois, "Appui"))
	end
	O.lumiere(O.decor(O.bloc(m, Vector3.new(0.4, 0.4, 0.4), cabane(0, 3, 0), C.Fenetre, M.Neon, "Lueur")), C.Lumiere, 1.2, 12)
	-- toit à deux pans en tuiles rouges, faîtage dans la longueur, pignons en planches
	local pente = math.rad(34)
	local demi = CW / 2 + 0.7
	local yToit = 0.5 + CH
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(demi / math.cos(pente) + 0.1, 0.4, CD + 1.4),
			cabane(s * demi / 2, yToit + math.tan(pente) * demi / 2, 0) * CFrame.Angles(0, 0, -s * pente), C.ToitRouge, M.Tuiles, "Toit")
	end
	O.decor(O.bloc(m, Vector3.new(0.5, 0.5, CD + 1.6), cabane(0, yToit + math.tan(pente) * demi + 0.1, 0), C.BoisFonce, M.Bois, "Faitage"))
	local hauteurPignon = math.tan(pente) * (CW / 2)
	for _, sz in {-1, 1} do
		for i = 0, 3 do
			local h = hauteurPignon * (i + 0.5) / 4
			local w = (CW - 0.4) * (1 - (i + 0.5) / 4)
			O.decor(O.bloc(m, Vector3.new(w, hauteurPignon / 4, 0.3), cabane(0, yToit + h, sz * (CD / 2 - 0.2)), C.BoisClair, M.Planches, "Pignon"))
		end
	end
	-- cheminée de tôle qui fume
	local tuyau = O.cylindre(m, 3, 0.6, cabane(CW / 4, yToit + 2.3, -CD / 4), C.Fer, M.Metal, "Cheminee")
	O.decor(O.cylindre(m, 0.25, 0.9, cabane(CW / 4, yToit + 3.8, -CD / 4), C.Fer, M.Metal, "Chapeau"))
	O.fumee(tuyau, 1.2)
	-- bouée rouge et blanche accrochée à la façade côté passerelle
	for i = 0, 7 do
		local ang = i * math.pi / 4
		O.decor(O.bloc(m, Vector3.new(0.35, 0.45, 0.6), cabane(-CW / 2 - 0.15, 0.5 + 3.3 + math.sin(ang) * 0.75, -1.8 + math.cos(ang) * 0.75) * CFrame.Angles(ang, 0, 0),
			if i % 2 == 0 then Color3.fromRGB(200, 52, 42) else Color3.fromRGB(236, 232, 224), M.Lisse, "Bouee"))
	end
	-- lanterne au coin de la cabane
	O.decor(O.bloc(m, Vector3.new(0.25, 0.25, 1), cabane(-CW / 2 - 0.1, 0.5 + 4.6, CD / 2 - 0.9), C.Fer, M.Metal, "Potence"))
	cage(m, cabane(-CW / 2 - 0.1, 0.5 + 3.8, CD / 2 - 1.4), C.Lumiere, 16)

	-- Filets qui sèchent sur une perche, côté pêche
	local fx, fz = -PX + 0.5, PZ0 - 2.2
	for _, dz in {-1.6, 1.6} do
		O.decor(O.bloc(m, Vector3.new(0.3, 3.6, 0.3), a(fx, 1.8, fz + dz), C.Bois, M.Bois, "Perche"))
	end
	O.decor(O.bloc(m, Vector3.new(0.25, 0.25, 3.8), a(fx, 3.55, fz), C.Bois, M.Bois, "Perche"))
	local filet = O.decor(O.bloc(m, Vector3.new(0.08, 2.4, 3), a(fx, 2.25, fz) * CFrame.Angles(0, 0, math.rad(4)), Color3.fromRGB(196, 186, 156), M.Tissu, "Filet"))
	filet.Transparency = 0.45
	for i = 0, 5 do
		O.decor(O.bloc(m, Vector3.new(0.1, 2.5, 0.06), a(fx + 0.02, 2.25, fz - 1.4 + i * 0.56), Color3.fromRGB(150, 140, 112), M.Tissu, "Maille"))
	end
	for i = 0, 3 do
		O.decor(O.bloc(m, Vector3.new(0.1, 0.06, 3), a(fx + 0.02, 1.3 + i * 0.6, fz), Color3.fromRGB(150, 140, 112), M.Tissu, "Maille"))
	end
	for _, dz in {-1, 0.2, 1.2} do
		O.decor(O.disque(m, 0.2, 0.32, a(fx + 0.1, 1.05, fz + dz), Color3.fromRGB(228, 150, 52), M.Lisse, "Flotteur"))
	end

	-- Coin de pêche : tabouret, canne sur son support, seau, caisse de poissons, tonneau
	local tx, tz = -PX + 2.3, PZ1 + 1.2
	O.bloc(m, Vector3.new(1.2, 0.25, 1.2), a(tx, 1, tz), C.BoisClair, M.Bois, "Tabouret")
	for _, d in {Vector2.new(-0.4, -0.4), Vector2.new(0.4, -0.4), Vector2.new(-0.4, 0.4), Vector2.new(0.4, 0.4)} do
		O.decor(O.bloc(m, Vector3.new(0.2, 0.9, 0.2), a(tx + d.X, 0.45, tz + d.Y), C.Bois, M.Bois, "Pied"))
	end
	O.decor(O.bloc(m, Vector3.new(0.25, 1.2, 0.25), a(-PX + 0.35, 0.6, tz - 0.3), C.BoisFonce, M.Bois, "Support"))
	local canne = a(-PX + 0.35, 1.1, tz - 0.3) * CFrame.Angles(math.rad(-20), 0, math.rad(55)) * CFrame.new(0, 3.2, 0)
	O.decor(O.bloc(m, Vector3.new(0.14, 6.4, 0.14), canne, Color3.fromRGB(92, 66, 40), M.Bois, "Canne"))
	local bout = (canne * CFrame.new(0, 3.2, 0)).Position
	local surface = (a(0, -eau, 0)).Position.Y
	local fil = O.decor(O.bloc(m, Vector3.new(0.04, bout.Y - surface, 0.04), CFrame.new(bout.X, (bout.Y + surface) / 2, bout.Z), Color3.fromRGB(230, 226, 214), M.Lisse, "Fil"))
	fil.Transparency = 0.2
	O.decor(O.ellipsoide(m, Vector3.new(0.35, 0.45, 0.35), CFrame.new(bout.X, surface + 0.1, bout.Z), Color3.fromRGB(214, 50, 40), M.Lisse, "Bouchon"))
	O.cylindre(m, 0.9, 0.9, a(tx - 1.0, 0.45, tz + 1.1), Color3.fromRGB(120, 122, 126), M.Metal, "Seau")
	O.decor(O.cylindre(m, 0.06, 0.75, a(tx - 1.0, 0.85, tz + 1.1), C.Eau, M.Verre, "EauSeau"))
	local caisse = B.caisse(m, a(-1.4, 0, PZ1 + 1), 1.5)
	caisse.Name = "CaissePoissons"
	for i = 0, 3 do
		O.decor(O.ellipsoide(m, Vector3.new(0.4, 0.28, 1.1), a(-1.4 + (i % 2) * 0.55 - 0.27, 1.55, PZ1 + 1 + (i < 2 and -0.3 or 0.35)) * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), 0),
			Color3.fromRGB(150, 168, 176), M.Lisse, "Poisson"))
	end
	B.tonneau(m, a(-PX + 1.2, 0, PZ0 - 4.6), 1.8)

	-- poteau de lanterne au départ de la passerelle
	O.bloc(m, Vector3.new(0.45, 4.2, 0.45), a(2.25, 1.7, -0.6), C.BoisFonce, M.Bois, "PoteauLanterne")
	O.decor(O.bloc(m, Vector3.new(0.25, 0.25, 1.2), a(2.25, 3.6, -1.1), C.BoisFonce, M.Bois, "Bras"))
	cage(m, a(2.25, 2.75, -1.6), C.Lumiere, 18)

	return m
end

local POISSONS = {Color3.fromRGB(104, 110, 112), Color3.fromRGB(150, 108, 56), Color3.fromRGB(116, 78, 46), Color3.fromRGB(134, 118, 86)}

-- Poisson suspendu par la queue à une barre (fil + corps + nageoire)
local function poissonPendu(m, haut, rng, couleur)
	local taille = rng:NextNumber(0.85, 1.25)
	O.decor(O.bloc(m, Vector3.new(0.04, 0.35, 0.04), haut * CFrame.new(0, -0.17, 0), Color3.fromRGB(176, 150, 104), M.Tissu, "Ficelle"))
	local corps = haut * CFrame.new(0, -0.33 - 0.45 * taille, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	O.decor(O.ellipsoide(m, Vector3.new(0.16, 0.9 * taille, 0.34 * taille), corps, couleur, M.Metal, "Poisson"))
	O.decor(O.coin(m, Vector3.new(0.08, 0.3, 0.35 * taille), corps * CFrame.new(0, 0.5 * taille, 0) * CFrame.Angles(math.pi / 2, 0, 0), couleur, M.Metal, "Queue"))
end

-- Petit fumoir à poissons : soubassement de pierre, planches noircies, toit à deux pans, cheminée qui fume,
-- lueur du feu par la trappe et poissons qui sèchent sous l'avant-toit. cf : au sol, façade vers -Z.
function B.fumoir(parent, cf)
	local m = O.modele(parent, "Fumoir")
	local rng = Random.new(11)
	local function a(x, y, z) return cf * CFrame.new(x, y, z) end
	local NOIRCI, SUIE = Color3.fromRGB(70, 52, 40), Color3.fromRGB(44, 36, 32)
	local W, D, H = 3.8, 3.6, 3.4
	O.bloc(m, Vector3.new(W + 0.4, 0.8, D + 0.4), a(0, 0.4, 0), C.PierreFoncee, M.Pierre, "Soubassement")
	O.bloc(m, Vector3.new(W, H, D), a(0, 0.8 + H / 2, 0), NOIRCI, M.Planches, "Murs")
	for _, sx in {-1, 1} do
		for _, sz in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.35, H + 0.1, 0.35), a(sx * (W / 2 - 0.1), 0.8 + H / 2, sz * (D / 2 - 0.1)), SUIE, M.Bois, "Poteau"))
		end
	end
	-- porte en planches et trappe du foyer, rougeoyante
	O.bloc(m, Vector3.new(1.4, 2.4, 0.2), a(-0.6, 0.8 + 1.2, -D / 2 - 0.05), C.Bois, M.Planches, "Porte")
	for _, y in {0.5, 1.9} do
		O.decor(O.bloc(m, Vector3.new(1.5, 0.15, 0.25), a(-0.6, 0.8 + y, -D / 2 - 0.12), C.Fer, M.Metal, "Penture"))
	end
	O.decor(O.bloc(m, Vector3.new(0.9, 0.6, 0.15), a(0.95, 1.25, -D / 2 - 0.05), Color3.fromRGB(255, 120, 40), M.Neon, "Braises"))
	O.decor(O.bloc(m, Vector3.new(1.1, 0.12, 0.25), a(0.95, 1.6, -D / 2 - 0.1), C.Fer, M.Metal, "Trappe"))
	O.lumiere(O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 0.3), a(0.95, 1.25, -D / 2 - 0.4), Color3.fromRGB(255, 120, 40), M.Neon, "Lueur")), Color3.fromRGB(255, 130, 60), 1, 10)
	-- fente sous le toit d'où s'échappe la fumée
	local fente = O.decor(O.bloc(m, Vector3.new(W - 0.6, 0.2, 0.1), a(0, 0.8 + H - 0.3, -D / 2 - 0.02), SUIE, M.Bois, "Fente"))
	O.fumee(fente, 0.8)
	-- toit à deux pans (faîtage de gauche à droite)
	local pente = math.rad(36)
	local demi = D / 2 + 0.6
	local yToit = 0.8 + H
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(W + 1, 0.3, demi / math.cos(pente) + 0.1),
			a(0, yToit + math.tan(pente) * demi / 2, s * demi / 2) * CFrame.Angles(s * pente, 0, 0), C.Toit, M.Tuiles, "Toit")
	end
	O.decor(O.bloc(m, Vector3.new(W + 1.1, 0.35, 0.35), a(0, yToit + math.tan(pente) * demi + 0.05, 0), SUIE, M.Bois, "Faitage"))
	for _, sx in {-1, 1} do
		for i = 0, 2 do
			local h = math.tan(pente) * (D / 2) * (i + 0.5) / 3
			O.decor(O.bloc(m, Vector3.new(0.25, math.tan(pente) * (D / 2) / 3, D * (1 - (i + 0.5) / 3)), a(sx * (W / 2 - 0.1), yToit + h, 0), NOIRCI, M.Planches, "Pignon"))
		end
	end
	-- cheminée de pierre à l'arrière
	local chem = O.bloc(m, Vector3.new(1, H + 2.6, 1), a(W / 2 - 0.6, 0.8 + (H + 2.6) / 2, D / 2 + 0.3), C.Pierre, M.Pierre, "Cheminee")
	O.decor(O.bloc(m, Vector3.new(1.2, 0.25, 1.2), a(W / 2 - 0.6, 0.8 + H + 2.7, D / 2 + 0.3), C.PierreFoncee, M.Pierre, "Couronne"))
	local bouche = O.decor(O.bloc(m, Vector3.new(0.6, 0.2, 0.6), a(W / 2 - 0.6, 0.8 + H + 2.9, D / 2 + 0.3), SUIE, M.Lisse, "Bouche"))
	bouche.Transparency = 1
	O.fumee(bouche, 2)
	-- poissons fumés suspendus sous l'avant-toit, côté gauche
	O.decor(O.bloc(m, Vector3.new(0.2, 0.2, D + 0.4), a(-W / 2 - 0.55, yToit - 0.1, 0), SUIE, M.Bois, "Barre"))
	for i = 0, 3 do
		poissonPendu(m, a(-W / 2 - 0.55, yToit - 0.2, -1.3 + i * 0.86), rng, POISSONS[3])
	end
	-- tas de bûches contre le mur droit
	for r = 0, 2 do
		for i = 0, 3 - r do
			O.decor(O.disque(m, 1.6, 0.5, a(W / 2 + 1.1, 0.25 + r * 0.45, -1.1 + i * 0.52 + r * 0.26),
				Color3.fromRGB(110 + rng:NextInteger(-12, 12), 78, 50), M.Bois, "Buche"))
		end
	end
	return m
end

-- Petit séchoir à poissons : deux montants, trois barres garnies de poissons, petit auvent de planches.
-- cf : au sol, barres parallèles à l'axe X.
function B.sechoirPoissons(parent, cf, numero)
	local m = O.modele(parent, "SechoirPoissons")
	local rng = Random.new(numero or 1)
	local function a(x, y, z) return cf * CFrame.new(x, y, z) end
	local L = 3.6
	for _, x in {-L / 2, L / 2} do
		O.bloc(m, Vector3.new(0.35, 3.4, 0.35), a(x, 1.7, 0), C.Bois, M.Bois, "Montant")
		for _, s in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.25, 1.4, 0.25), a(x, 0.55, s * 0.45) * CFrame.Angles(s * math.rad(-28), 0, 0), C.BoisFonce, M.Bois, "Jambe"))
		end
	end
	for _, y in {3.1, 1.75} do
		O.decor(O.bloc(m, Vector3.new(L + 0.5, 0.18, 0.18), a(0, y, 0), C.BoisFonce, M.Bois, "Barre"))
		for i = 0, 5 do
			poissonPendu(m, a(-L / 2 + 0.35 + i * (L - 0.7) / 5, y - 0.1, 0), rng, POISSONS[rng:NextInteger(1, #POISSONS)])
		end
	end
	-- petit auvent de planches
	O.decor(O.bloc(m, Vector3.new(L + 0.9, 0.2, 1.4), a(0, 3.55, 0) * CFrame.Angles(math.rad(12), 0, 0), C.BoisClair, M.Planches, "Auvent"))
	-- panier au pied
	O.cylindre(m, 0.7, 1, a(L / 2 + 0.6, 0.35, 0.4), Color3.fromRGB(176, 140, 86), M.Tissu, "Panier")
	return m
end

--[[ Nain mineur en blocs qui pioche (enseigne de la Grande Mine). cf : aux pieds, regard vers -Z ; s : échelle.
	Le bras droit et la pioche forment le modèle « BrasPioche » (pivot à l'épaule, pose de frappe) ; le client
	(PiocheurEnseigne.client) le fait lever puis frapper, et fait jaillir les étincelles de la pièce « Impact ». ]]
function B.nainPiocheur(parent, cf, s)
	s = s or 1
	local m = O.modele(parent, "NainPiocheur")
	local function a(x, y, z) return cf * CFrame.new(x * s, y * s, z * s) end
	local function bloc(g, taille, c, couleur, mat, nom) return O.decor(O.bloc(g, taille * s, c, couleur, mat, nom)) end
	local PEAU, BARBE, TUNIQUE = Color3.fromRGB(226, 172, 138), Color3.fromRGB(196, 98, 42), Color3.fromRGB(58, 88, 96)
	local CUIR, BOTTE, PANTALON = Color3.fromRGB(96, 62, 38), Color3.fromRGB(56, 38, 28), Color3.fromRGB(74, 60, 50)
	for _, x in {-0.32, 0.32} do
		bloc(m, Vector3.new(0.55, 0.5, 0.8), a(x, 0.25, -0.08), BOTTE, M.Cuir, "Botte")
		bloc(m, Vector3.new(0.5, 0.85, 0.55), a(x, 0.92, 0), PANTALON, M.Tissu, "Jambe")
	end
	bloc(m, Vector3.new(1.55, 1.25, 1.05), a(0, 2, 0), TUNIQUE, M.Tissu, "Tunique")
	bloc(m, Vector3.new(1.6, 0.28, 1.1), a(0, 1.48, 0), CUIR, M.Cuir, "Ceinture")
	bloc(m, Vector3.new(0.35, 0.3, 0.1), a(0, 1.48, -0.56), C.Or, M.Metal, "Boucle")
	bloc(m, Vector3.new(1, 0.95, 0.95), a(0, 3.08, 0), PEAU, M.Lisse, "Tete")
	bloc(m, Vector3.new(0.3, 0.32, 0.25), a(0, 3.02, -0.58), PEAU:Lerp(Color3.fromRGB(200, 90, 70), 0.25), M.Lisse, "Nez")
	for _, x in {-0.24, 0.24} do
		bloc(m, Vector3.new(0.14, 0.14, 0.06), a(x, 3.24, -0.49), Color3.fromRGB(30, 24, 22), M.Lisse, "Oeil")
	end
	bloc(m, Vector3.new(1.12, 1.05, 0.38), a(0, 2.42, -0.55), BARBE, M.Tissu, "Barbe")
	bloc(m, Vector3.new(0.62, 0.55, 0.3), a(0, 1.7, -0.6), BARBE, M.Tissu, "BarbePointe")
	bloc(m, Vector3.new(0.95, 0.2, 0.22), a(0, 2.86, -0.54), BARBE:Lerp(Color3.new(), 0.15), M.Tissu, "Moustache")
	bloc(m, Vector3.new(1.18, 0.5, 1.12), a(0, 3.7, 0), Color3.fromRGB(176, 140, 60), M.Metal, "Casque")
	bloc(m, Vector3.new(1.34, 0.12, 1.28), a(0, 3.47, 0), Color3.fromRGB(150, 118, 50), M.Metal, "Bord")
	local frontale = bloc(m, Vector3.new(0.36, 0.3, 0.16), a(0, 3.66, -0.6), Color3.fromRGB(255, 230, 160), M.Neon, "Frontale")
	O.lumiere(frontale, Color3.fromRGB(255, 220, 150), 1, 12)
	bloc(m, Vector3.new(0.42, 1.1, 0.46), a(-0.98, 2.05, -0.15) * CFrame.Angles(math.rad(20), 0, math.rad(-8)), TUNIQUE, M.Tissu, "BrasG")
	bloc(m, Vector3.new(0.38, 0.36, 0.38), a(-1.02, 1.45, -0.35), PEAU, M.Lisse, "MainG")

	-- bras droit + pioche, en pose de frappe (horizontal vers l'avant) ; pivot à l'épaule
	local bras = O.modele(m, "BrasPioche")
	local epaule = a(0.98, 2.45, 0)
	local function b(x, y, z) return epaule * CFrame.new(x * s, y * s, z * s) end
	bloc(bras, Vector3.new(0.44, 0.44, 1.2), b(0, 0, -0.5), TUNIQUE, M.Tissu, "Bras")
	bloc(bras, Vector3.new(0.4, 0.4, 0.4), b(0, 0, -1.2), PEAU, M.Lisse, "MainD")
	bloc(bras, Vector3.new(0.17, 0.17, 2.4), b(0, 0, -2.3), Color3.fromRGB(120, 84, 52), M.Bois, "Manche")
	bloc(bras, Vector3.new(0.24, 1.9, 0.3), b(0, -0.2, -3.45) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(120, 124, 132), M.Metal, "FerPioche")
	bloc(bras, Vector3.new(0.3, 0.3, 0.36), b(0, 0, -3.45), C.Fer, M.Metal, "Douille")
	bras.WorldPivot = epaule
	-- point d'impact (pointe basse de la pioche, pose de frappe) : étincelles et éclats de cristal
	local impact = bloc(m, Vector3.new(0.2, 0.2, 0.2), epaule * CFrame.Angles(math.rad(-22), 0, 0) * CFrame.new(0, -1.15 * s, -3.3 * s), Color3.new(), M.Lisse, "Impact")
	impact.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Name = "Etincelles"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140), Color3.fromRGB(200, 140, 255))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.5 * s, 0)
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Rate = 0
	e.Parent = impact
	m:SetAttribute("Echelle", s)
	O.tag(m, "Piocheur")
	return m
end

function B.tableTaverne(parent, cf)
	local m = O.modele(parent, "Table")
	m:SetAttribute("VersionTableTaverne", 2)
	-- Les décors du village sont calculés à Y=0, alors que la surface du terrain
	-- voxel est à Y=2 : les pieds doivent reposer sur le sol visible.
	cf = cf * CFrame.new(0, 2, 0)
	local bois = Color3.fromRGB(109, 71, 42)
	local planche = Color3.fromRGB(139, 93, 53)
	local fer = Color3.fromRGB(64, 58, 50)
	local plateau = O.bloc(m, Vector3.new(5.5, 0.35, 3.8), cf * CFrame.new(0, 3, 0), bois, M.Planches, "Plateau")
	m.PrimaryPart = plateau
	for _, z in {-1.25, 0, 1.25} do
		O.decor(O.bloc(m, Vector3.new(5.35, 0.08, 1.18), cf * CFrame.new(0, 3.215, z), planche, M.Planches, "PlanchePlateau"))
	end
	for _, x in {-2.2, 2.2} do
		for _, z in {-1.35, 1.35} do
			O.bloc(m, Vector3.new(0.42, 2.85, 0.42), cf * CFrame.new(x, 1.425, z), C.BoisFonce, M.Bois, "Pied")
		end
		O.decor(O.bloc(m, Vector3.new(0.3, 0.35, 2.8), cf * CFrame.new(x, 1.1, 0), bois, M.Bois, "Renfort"))
	end
	for _, x in {-3.7, 3.7} do
		local tabouret = O.modele(m, "Tabouret")
		O.bloc(tabouret, Vector3.new(1.6, 0.28, 1.6), cf * CFrame.new(x, 1.65, 0), planche, M.Planches, "Assise")
		for _, dx in {-0.55, 0.55} do
			for _, z in {-0.55, 0.55} do
				O.bloc(tabouret, Vector3.new(0.22, 1.5, 0.22), cf * CFrame.new(x + dx, 0.75, z), bois, M.Bois, "Pied")
			end
		end
	end
	for _, o in {{-1.25, 0.35}, {1.15, -0.45}} do
		local tasse = O.modele(m, "Chope")
		local t = cf * CFrame.new(o[1], 3.26, o[2])
		O.decor(O.cylindre(tasse, 1.1, 0.95, t * CFrame.new(0, 0.55, 0), Color3.fromRGB(137, 82, 39), M.Bois, "Corps"))
		for _, y in {0.12, 0.92} do
			O.decor(O.cylindre(tasse, 0.12, 1.0, t * CFrame.new(0, y, 0), fer, M.Metal, "Cercle"))
		end
		O.decor(O.cylindre(tasse, 0.17, 0.96, t * CFrame.new(0, 1.15, 0), Color3.fromRGB(246, 225, 173), M.Lisse, "Mousse"))
		-- Anse carrée en bois sombre, lisible depuis le côté.
		for _, y in {0.30, 0.85} do
			O.decor(O.bloc(tasse, Vector3.new(0.36, 0.13, 0.18), t * CFrame.new(0.57, y, 0), C.BoisFonce, M.Bois, "Anse"))
		end
		O.decor(O.bloc(tasse, Vector3.new(0.14, 0.68, 0.18), t * CFrame.new(0.75, 0.575, 0), C.BoisFonce, M.Bois, "Anse"))
	end
	return m
end

-- Seau de bois cerclé de fer (cf = fond du seau) ; plein = disque d'eau sur le dessus
local function seau(m, cf, plein)
	O.cylindre(m, 1.1, 1.2, cf * CFrame.new(0, 0.55, 0), C.Bois, M.Bois, "Seau")
	for _, y in {0.2, 0.9} do
		O.decor(O.cylindre(m, 0.12, 1.28, cf * CFrame.new(0, y, 0), Color3.fromRGB(70, 68, 72), M.Metal, "Cercle"))
	end
	O.decor(O.bloc(m, Vector3.new(1.3, 0.08, 0.08), cf * CFrame.new(0, 1.5, 0), Color3.fromRGB(70, 68, 72), M.Metal, "Anse"))
	for _, x in {-0.62, 0.62} do
		O.decor(O.bloc(m, Vector3.new(0.08, 0.5, 0.08), cf * CFrame.new(x, 1.27, 0), Color3.fromRGB(70, 68, 72), M.Metal, "Anse"))
	end
	if plein then
		local eau = O.decor(O.cylindre(m, 0.06, 1.05, cf * CFrame.new(0, 1.02, 0), Color3.fromRGB(60, 140, 180), M.Verre, "EauSeau"))
		eau.Transparency = 0.2
	end
end

-- Puits du village : dallage, double margelle de pierres taillées (mousse), eau qui scintille au fond,
-- toit de bardeaux sur poteaux contreventés, treuil à manivelle, seau suspendu, seau plein, lanterne.
-- Modèle « Puits » (attribut VersionPuits) : Village.preparerAteliers le remplace aussi sur les cartes figées.
B.VERSION_PUITS = 1
function B.puits(parent, cf)
	local m = O.modele(parent, "Puits")
	m:SetAttribute("VersionPuits", B.VERSION_PUITS)
	m:SetAttribute("Base", cf)
	local rng = Random.new(2718)
	-- Posé sur le vrai sol (terrain), puis le terrain est creusé à l'intérieur de la margelle : l'eau se voit au fond
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	local sol = workspace:Raycast(cf.Position + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), params)
	if sol then
		cf = CFrame.new(sol.Position) * cf.Rotation
	end
	workspace.Terrain:FillCylinder(cf * CFrame.new(0, 0.6, 0), 4, 2.3, Enum.Material.Air)
	local PIERRE = COUL_AUBERGE.Pierre
	-- Dallage circulaire
	O.cylindre(m, 0.3, 9.4, cf * CFrame.new(0, 0.15, 0), COUL_AUBERGE.PierreSombre, M.Pierre, "Dallage")
	for i = 0, 11 do
		local a = i * math.pi / 6
		O.decor(O.bloc(m, Vector3.new(1.6, 0.08, 1.3), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.33, -4.1), PIERRE:Lerp(COUL_AUBERGE.PierreClaire, rng:NextNumber(0, 0.5)), M.Pierre, "Dalle"))
	end
	-- Margelle : assise basse + chaperon débordant, pierres légèrement inégales
	for i = 0, 7 do
		local tour = cf * CFrame.Angles(0, i * math.pi / 4, 0)
		O.bloc(m, Vector3.new(2.45, 2.3, 1.1), tour * CFrame.new(0, 1.45, -2.75), PIERRE:Lerp(COUL_AUBERGE.PierreSombre, rng:NextNumber(0, 0.6)), M.Pierre, "Margelle")
		O.bloc(m, Vector3.new(2.7, 0.5, 1.5), tour * CFrame.new(0, 2.85, -2.8), COUL_AUBERGE.PierreClaire:Lerp(PIERRE, rng:NextNumber(0, 0.4)), M.Pierre, "Chaperon")
		if rng:NextNumber() < 0.5 then
			O.decor(O.ellipsoide(m, Vector3.new(rng:NextNumber(0.8, 1.4), 0.3, 0.5), tour * CFrame.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0.6, 1.4), -3.32),
				Color3.fromRGB(70, 104, 52), M.Herbe, "Mousse"))
		end
	end
	-- Le fond : puits sombre, eau bleue qui reflète, lueur et reflets
	O.decor(O.cylindre(m, 0.2, 4.7, cf * CFrame.new(0, 0.45, 0), Color3.fromRGB(10, 14, 18), M.Lisse, "Fond"))
	local lueur = O.decor(O.cylindre(m, 0.1, 4.7, cf * CFrame.new(0, 1.15, 0), Color3.fromRGB(60, 170, 210), M.Neon, "LueurEau"))
	lueur.Transparency = 0.55
	local eau = O.decor(O.cylindre(m, 0.2, 4.75, cf * CFrame.new(0, 1.3, 0), Color3.fromRGB(46, 120, 160), M.Verre, "Eau"))
	eau.Transparency = 0.2
	eau.Reflectance = 0.25
	O.lumiere(eau, Color3.fromRGB(110, 200, 255), 0.8, 9)
	local reflets = O.decor(O.bloc(m, Vector3.new(3.4, 0.2, 3.4), cf * CFrame.new(0, 1.5, 0), Color3.new(1, 1, 1), M.Lisse, "Reflets"))
	reflets.Transparency = 1
	O.lucioles(reflets, Color3.fromRGB(170, 230, 255), 1.5)

	-- Poteaux, contreventements, sablière
	for _, x in {-3.5, 3.5} do
		O.bloc(m, Vector3.new(0.8, 7.6, 0.8), cf * CFrame.new(x, 3.8, 0), COUL_AUBERGE.Bois, M.Bois, "Poteau")
		O.bloc(m, Vector3.new(1.2, 0.6, 1.2), cf * CFrame.new(x, 0.6, 0), COUL_AUBERGE.PierreSombre, M.Pierre, "Pied")
		for _, z in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(0.35, 2.2, 0.35), cf * CFrame.new(x, 6.5, z * 0.7) * CFrame.Angles(z * math.rad(40), 0, 0), COUL_AUBERGE.Bois, M.Bois, "Contrevent"))
		end
	end
	O.bloc(m, Vector3.new(8.2, 0.6, 0.7), cf * CFrame.new(0, 7.75, 0), COUL_AUBERGE.Bois, M.Bois, "Faitiere")
	-- Toit : 3 rangées de bardeaux par pan, faîtage
	for _, cote in {-1, 1} do
		for r = 0, 2 do
			local d = 0.6 + r * 1.05
			local teinte = C.Toit:Lerp(C.ToitRouge, if r % 2 == 0 then 0.25 else 0.05)
			O.bloc(m, Vector3.new(8.8, 0.28, 1.35), cf * CFrame.new(0, 8.35 - d * 0.62, cote * d) * CFrame.Angles(cote * math.rad(32), 0, 0), teinte, M.Tuiles, "Bardeaux")
		end
	end
	O.bloc(m, Vector3.new(9, 0.45, 0.6), cf * CFrame.new(0, 8.55, 0), C.Toit, M.Tuiles, "Faitage")
	for _, x in {-4.45, 4.45} do
		O.decor(O.bloc(m, Vector3.new(0.3, 0.9, 0.3), cf * CFrame.new(x, 8.7, 0), COUL_AUBERGE.Bois, M.Bois, "Epi"))
	end

	-- Treuil avec corde enroulée et manivelle
	O.decor(O.cylindre(m, 6.6, 0.6, cf * CFrame.new(0, 5.7, 0) * CFrame.Angles(0, 0, math.pi / 2), C.Bois, M.Bois, "Treuil"))
	O.decor(O.cylindre(m, 2, 1, cf * CFrame.new(0, 5.7, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(160, 136, 100), M.Tissu, "CordeEnroulee"))
	O.decor(O.bloc(m, Vector3.new(0.25, 1.6, 0.25), cf * CFrame.new(4.15, 5.1, 0), Color3.fromRGB(70, 68, 72), M.Metal, "Manivelle"))
	O.decor(O.bloc(m, Vector3.new(0.9, 0.25, 0.25), cf * CFrame.new(4.5, 4.35, 0), C.BoisFonce, M.Bois, "Poignee"))
	-- Corde et seau suspendu au-dessus de l'eau, seau plein posé sur le chaperon
	O.decor(O.bloc(m, Vector3.new(0.1, 0.9, 0.1), cf * CFrame.new(0, 4.95, 0.45), Color3.fromRGB(160, 136, 100), M.Tissu, "Corde"))
	seau(m, cf * CFrame.new(0, 3.35, 0.45), false)
	seau(m, cf * CFrame.new(2.1, 3.1, -1.9) * CFrame.Angles(0, 0.4, 0), true)
	-- Lanterne sous le toit
	B.suspension(m, (cf * CFrame.new(-1.9, 7.4, 0)).Position, 0.9, C.Fenetre, 14)
	-- Touffes de fleurs au pied
	for _, p in {{-4.6, 1.8}, {4.4, -2.2}, {-1.8, 4.6}} do
		O.decor(O.ellipsoide(m, Vector3.new(1.6, 0.9, 1.4), cf * CFrame.new(p[1], 0.45, p[2]), COUL_AUBERGE.Feuillage, M.Herbe, "Touffe"))
		for k = 1, 4 do
			O.decor(O.ellipsoide(m, Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(p[1] + rng:NextNumber(-0.6, 0.6), 0.9, p[2] + rng:NextNumber(-0.5, 0.5)),
				if k % 2 == 0 then COUL_AUBERGE.Fleur else COUL_AUBERGE.FleurJaune, M.Tissu, "Fleur"))
		end
	end
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
		O.bloc(m, Vector3.new(0.6, 2.7, 0.6), cf * CFrame.new(x, 1.75, 0), Color3.fromRGB(91, 67, 50), M.Rouille, "Poteau")
	end
	for i = 0, 7 do
		local couleur = if i % 2 == 0 then Color3.fromRGB(157, 65, 49) else Color3.fromRGB(195, 185, 164)
		O.bloc(m, Vector3.new(0.875, 0.8, 0.55), cf * CFrame.new(-3.0625 + i * 0.875, 3.05, 0), couleur, M.Metal, "Traverse")
	end
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

-- Arbres modélisés dans Blender (blender/arbres.py, assets/Arbres.fbx) : pins sylvestres et saules pleureurs
local TEINTES_ARBRES = {
	Ecorce = {Color3.fromRGB(96, 80, 66), M.Bois}, Tronc = {Color3.fromRGB(92, 70, 52), M.Bois},
	Branches = {Color3.fromRGB(84, 64, 48), M.Bois},
	Aiguilles = {Color3.fromRGB(46, 80, 42), M.Lisse}, AiguillesClaires = {Color3.fromRGB(84, 122, 54), M.Lisse},
	Feuillage = {Color3.fromRGB(62, 88, 42), M.Lisse}, Rameaux = {Color3.fromRGB(96, 128, 58), M.Lisse},
	RameauxClairs = {Color3.fromRGB(138, 160, 78), M.Lisse}, RameauxSombres = {Color3.fromRGB(70, 98, 46), M.Lisse},
	Feuilles = {Color3.fromRGB(110, 140, 62), M.Lisse}, FeuillesClaires = {Color3.fromRGB(160, 176, 92), M.Lisse},
	Pommes = {Color3.fromRGB(118, 84, 52), M.Bois}, AiguillesSombres = {Color3.fromRGB(38, 64, 36), M.Lisse},
	-- sapins (blender/sapins.py) : vert plus sombre et bleuté que les pins
	AiguillesSapin = {Color3.fromRGB(34, 66, 46), M.Lisse}, AiguillesSapinClaires = {Color3.fromRGB(70, 112, 64), M.Lisse},
}
local TRONC_PIN = Color3.fromRGB(176, 98, 54) -- haut du fût orangé (la pièce s'appelle aussi « Tronc »)
local SOLIDES_ARBRES = {Ecorce = true, Tronc = true}

-- Pose une variante au hasard (motif "^Pin%d+$" ou "^Saule%d+$") : pied du tronc sur base, hauteur h
local function arbre3D(parent, motif, nomModele, base, h, rng)
	local variantes = M3.variantes(motif)
	if #variantes == 0 then
		return nil
	end
	local pieces = M3.pieces(variantes[rng:NextInteger(1, #variantes)]) :: {MeshPart}
	local mn, mx = M3.boite(pieces)
	local pied = M3.centre(pieces, {Ecorce = true}) or M3.centre(pieces, {Tronc = true}) or (mn + mx) / 2
	local S = CFrame.new(pied.X, mn.Y, pied.Z)
	local k = h / (mx.Y - mn.Y)
	local estPin = string.match(motif, "Pin") ~= nil
	local nuance = rng:NextNumber(-0.1, 0.1)
	local m = O.modele(parent, nomModele)
	M3.poser(pieces, S, CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0), k, m, function(c, teinte)
		local t = TEINTES_ARBRES[teinte]
		if t then
			local couleur = if estPin and teinte == "Tronc" then TRONC_PIN else t[1]
			c.Color = if nuance > 0 then couleur:Lerp(Color3.fromRGB(150, 150, 70), nuance) else couleur:Lerp(Color3.new(0, 0, 0), -nuance)
			c.Material = t[2]
		end
		c.CastShadow = true
		if not SOLIDES_ARBRES[teinte] then
			O.decor(c)
		end
	end)
	return m
end

-- Saule pleureur (au bord de l'eau) ; feuillu d'automne si les modèles 3D ne sont pas importés
function B.saule(parent, base, h, rng)
	return arbre3D(parent, "^Saule%d+$", "Saule", base, h, rng) or B.feuillu(parent, base, h * 0.8, rng)
end

-- Sapin (épicéa) modélisé ; un pin s'il n'est pas importé
function B.sapin(parent, base, h, rng)
	return arbre3D(parent, "^Sapin%d+$", "Sapin", base, h, rng) or B.pin(parent, base, h, rng)
end

function B.pin(parent, base, h, rng)
	local pin3D = arbre3D(parent, "^Pin%d+$", "Pin", base, h, rng)
	if pin3D then
		return pin3D
	end
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
	-- roches de tons variés (brun chaud, ocre, grès rosé, gris violacé) plutôt qu'un gris unique
	local TONS = {Color3.fromRGB(128, 110, 96), Color3.fromRGB(156, 132, 104), Color3.fromRGB(150, 104, 84), Color3.fromRGB(98, 90, 106)}
	local teinte = TONS[rng:NextInteger(1, #TONS)]:Lerp(C.PierreFoncee, rng:NextNumber(0, 0.35))
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
	local coeur = O.bloc(parent, Vector3.new(r * 0.5, h * 0.92, r * 0.5), axe * CFrame.new(0, h * 0.46, 0), couleur:Lerp(Color3.new(), 0.4), M.Neon, "Coeur") -- néon assombri : lueur douce
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
	O.lumiere(coeur, couleur, 1.3, portee or math.clamp(h * 2.2, 14, 60))
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
		O.decor(O.cylindre(g, 0.85, 0.7, main * CFrame.new(0, 0.3, -0.35), C.Bois, M.Bois, "Chope"))
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
	local k = 4.7 / -plusBas -- nain : centre de la tête à ~4.7 studs du sol ; un joueur R15 l'a à ~5.4 : un peu plus petit, bien plus large

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
		-- pièces des nains « épiques » (blender/nains.py)
		Fourrure = {tenue.fourrure or Color3.fromRGB(110, 88, 66), M.Tissu},
		Casque = {Color3.fromRGB(132, 134, 140), M.Metal},
		Corne = {Color3.fromRGB(226, 212, 182), M.Lisse},
		Or = {Color3.fromRGB(232, 178, 58), M.Metal},
		Peinture = {Color3.fromRGB(52, 104, 168), M.Lisse},
		Lampe = {Color3.fromRGB(255, 230, 150), M.Neon},
		Lueur = {tenue.lueur or Color3.fromRGB(255, 200, 120), M.Neon},
	}
	local function regler(c, nomTeinte)
		local t = teintes[nomTeinte]
		if t then
			c.Color = t[1]
			c.Material = t[2]
		end
		if nomTeinte == "Verre" then
			c.Transparency = 0.35
		elseif nomTeinte == "Pivot" then
			c.Transparency = 1 -- repère d'articulation (épaule, coude, poignet, cou, hanches) : invisible
			c.CastShadow = false
		end
		O.decor(c)
	end

	local m = O.modele(parent, nom)
	-- Un sous-modèle par groupe : Corps, Buste, Tete, et pour les nains articulés BrasD/AvBrasD/MainD (et G)
	local groupes = {Corps = O.modele(m, "Corps"), Buste = O.modele(m, "Buste"), Tete = O.modele(m, "Tete")}
	for _, p in pieces do
		local g = M3.groupe(p) or "Buste"
		if not groupes[g] then
			groupes[g] = O.modele(m, g)
		end
		M3.poser({p}, S, cf, k, groupes[g], regler)
	end
	-- Squelette complet (repères d'articulation présents) : animé par AnimationsNains.client.lua
	local articule = groupes.BrasD ~= nil and groupes.Tete:FindFirstChild(nom .. "_Tete_Pivot") ~= nil
	m:SetAttribute("Squelette", articule)
	local teteClone = groupes.Tete:FindFirstChild(nom .. "_Tete_Peau") :: BasePart
	local busteClone = groupes.Buste:FindFirstChild(nom .. "_Buste_Haut") :: BasePart
	groupes.Tete.PrimaryPart = teteClone
	groupes.Buste.PrimaryPart = busteClone
	-- Pivots droits (axe Y vertical, tournés comme le PNJ) : après l'import, le repère propre des maillages
	-- est couché, et tourner la tête autour de lui la faisait basculer au lieu de pivoter.
	for _, piece in {teteClone, busteClone} do
		if piece then
			piece.PivotOffset = piece.CFrame:ToObjectSpace(CFrame.new(piece.Position) * cf.Rotation)
		end
	end
	m:SetAttribute("RotationTeteMax", 0.45) -- barbes et tresses longues : petit mouvement de tête
	print(string.format("[Monde] PNJ 3D %s : %d pièces, échelle %.3f, tête à %s (sol %s)", nom, #pieces, k,
		tostring(teteClone and teteClone.Position), tostring(cf.Position)))

	-- boîte invisible pour qu'on ne traverse pas le PNJ
	local boite = O.bloc(m, Vector3.new(3, 4.6, 2.4), cf * CFrame.new(0, 2.3, 0), Color3.new(0, 0, 0), M.Lisse, "Collision")
	boite.Transparency = 1
	boite.CastShadow = false

	-- Nom au-dessus de la tête, mais sous l'auvent ou le toit s'il y en a un juste au-dessus
	-- (sinon le texte se fondait dans la toile des échoppes).
	local hauteurNom = 2.2
	local plafond = workspace:Raycast(teteClone.Position, Vector3.new(0, 8, 0))
	if plafond then
		hauteurNom = math.clamp(plafond.Position.Y - teteClone.Position.Y - 1.6, 1.0, 2.2)
	end
	local etiquette = O.etiquette(teteClone, nom, role, hauteurNom)
	etiquette.AlwaysOnTop = true -- jamais caché par un bord de toit
	etiquette.MaxDistance = 45
	m.PrimaryPart = boite
	m.WorldPivot = cf
	O.tag(m, "PNJ")
	m:SetAttribute("Role", role)
	O.atomique(m)
	return m
end

-- Pose le PNJ sur le vrai sol (terrain, estrade, plancher) : sans ça, ses pieds s'enfonçaient
-- là où le terrain est plus haut que la position prévue. On ne fait que remonter, jamais descendre.
local function auSol(cf: CFrame): CFrame
	local haut = 4
	local r = workspace:Raycast(cf.Position + Vector3.new(0, haut, 0), Vector3.new(0, -(haut + 2), 0))
	if r and r.Position.Y > cf.Position.Y then
		return cf + Vector3.new(0, r.Position.Y - cf.Position.Y, 0)
	end
	return cf
end

function B.pnj(parent, cf, nom, role, tenue)
	cf = auSol(cf)
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
