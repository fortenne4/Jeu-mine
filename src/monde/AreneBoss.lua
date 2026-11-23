-- Arènes des boss du village (ServerStorage › Monde › AreneBoss) : une arène par boss, chacune à son centre
-- (Disposition.ARENES_BOSS), construite à la première utilisation puis gardée :
--	SeigneurBraise → « La Fosse des Rois Nains » (ce fichier) : volcan, disque suspendu au-dessus de la lave
--	TitanCristal   → « La Géode du Titan » (AreneCristal.lua)
--	ReineAraignee  → « Le Nid de la Reine » (AreneNid.lua)
-- Commun aux trois : sol plat et dégagé à centre.Y sur tout le rayon ARENE_RAYON (seules pièces solides), tout le
-- reste en bordure ou décoratif sans collision (ignoré des rayons des mobs), murs invisibles, peu de lumières.
-- L'ambiance (éclairage, brume, bannières / cocons qui se balancent, runes et cristaux qui pulsent) est réglée côté
-- client par AmbianceArene.client selon l'arène (attribut « Arene » du modèle = id du boss).
--	local arene = AreneBoss.obtenir("TitanCristal") -- Model « AreneBoss_TitanCristal » (attributs Centre, Rayon, Arene)
--
-- « La Fosse des Rois Nains » (volcan du Seigneur de braise) : un disque de dalles sombres (rosace dorée, cercle de
-- runes, fissures, éclats d'obsidienne) suspendu par huit chaînes géantes au-dessus d'un gouffre de lave, au cœur
-- d'une immense caverne volcanique. Autour, séparé par un ravin rougeoyant : un colisée nain en ruine (gradins,
-- colonnade, quatre portes fortifiées reliées par des ponts, quatre statues de rois nains, bannières déchirées,
-- aiguilles d'obsidienne). Au-dessus : voûte basse (+150) à lobes de roche et veines de magma sombres, stalactites ;
-- au loin : colonnes, coulées de lave figée et mer de lave, cendres et braises. ≈ 2 800 pièces ancrées, 12 lumières.
local O = require(script.Parent.Outils)
local D = require(script.Parent.Disposition)
local M = O.M

local AreneBoss = {}

local BASALTE = O.materiau("Basalt", M.Ardoise)

-- Palette : pierre sombre, or terni, runes bleues naines, obsidienne aux arêtes de braise, lave orangée (jamais fluo)
local JOINT = Color3.fromRGB(44, 40, 48)
local DALLE = Color3.fromRGB(76, 72, 80)
local DALLE_CLAIRE = Color3.fromRGB(106, 100, 106)
local DALLE_RUNE = Color3.fromRGB(44, 42, 54)
local COEUR = Color3.fromRGB(38, 36, 46)
local FISSURE = Color3.fromRGB(20, 18, 22)
local PIERRE = Color3.fromRGB(86, 80, 86)
local PIERRE_CLAIRE = Color3.fromRGB(134, 126, 122)
local ROCHE = Color3.fromRGB(50, 44, 48)
local ROCHE_SOMBRE = Color3.fromRGB(28, 24, 28)
local NOIR = Color3.fromRGB(14, 12, 16)
local OR = Color3.fromRGB(190, 146, 70)
local FER = Color3.fromRGB(50, 48, 54)
local OS = Color3.fromRGB(196, 184, 158)
local BRAISE = Color3.fromRGB(255, 140, 60)
local RUNE = Color3.fromRGB(86, 118, 222)
local CRISTAUX = {Color3.fromRGB(34, 28, 36), Color3.fromRGB(52, 36, 38)} -- obsidienne
local ARETE = Color3.fromRGB(92, 40, 24) -- arête de braise mate au bout des aiguilles d'obsidienne (jamais au sol)
local MAGMA = O.materiau("CrackedLava", M.Ardoise) -- roche de lave figée (mate, pas de néon)
local VEINE = Color3.fromRGB(104, 36, 14) -- veines de magma sombres (néon très atténué) sous la voûte et dans les coulées
local LAVE = Color3.fromRGB(214, 92, 30)
local LAVE_SOMBRE = Color3.fromRGB(122, 38, 14)
local BANNIERES = {Color3.fromRGB(112, 30, 30), Color3.fromRGB(38, 30, 30)}

-- Motifs de runes naines (barres : décalage x, décalage z, longueur, angle)
local MOTIFS = {
	{{0, 0, 2.8, 0}, {0.55, -0.6, 1.4, 0.75}, {-0.55, 0.55, 1.4, 0.75}},
	{{0, 0, 2.8, 0}, {0, -1.2, 1.8, math.pi / 2}, {0.4, 0.5, 1.2, math.pi / 2}},
	{{-0.6, 0, 2.6, 0}, {0.6, 0, 2.6, 0}, {0, 0, 2.4, 0.55}},
	{{0, 0.3, 2.2, 0}, {0.5, -1, 1.3, 0.8}, {-0.5, -1, 1.3, -0.8}},
}

local function construireFosse(m: Model, c: Vector3, R: number)
	local rng = Random.new(6061)
	local DEUX_PI = 2 * math.pi
	local HAUT_VOUTE = 150 -- dessous de la voûte, au-dessus du sol de l'arène (assez bas pour être vue depuis le sol)
	local BAS_LAVE = -150 -- surface de la mer de lave

	-- Repères : a = 0 au nord (-Z). tangent : X tangent, +Z vers le centre. face : -Z vers le centre.
	local function polaire(a, r, y)
		return CFrame.new(c.X + math.sin(a) * r, c.Y + (y or 0), c.Z - math.cos(a) * r)
	end
	local function tangent(a, r, y)
		return polaire(a, r, y) * CFrame.Angles(0, -a, 0)
	end
	local function face(a, r, y)
		return polaire(a, r, y) * CFrame.Angles(0, math.pi - a, 0)
	end
	local function petit(p)
		p.CastShadow = false
		return p
	end
	local function deco(taille, cf, couleur, mat, nom)
		return petit(O.decor(O.bloc(m, taille, cf, couleur, mat, nom)))
	end
	local function lueur(p, transparence)
		p.Transparency = transparence or 0.3
		O.tag(p, "RuneArene")
		return p
	end
	-- Incrustation dans le sol : cf au niveau du dessus du sol, dépasse de 0.04 (sous les télégraphes à +0.08)
	local function incruster(sx, sz, cf, couleur, mat, nom, epaisseur)
		local e = epaisseur or 0.1
		return deco(Vector3.new(sx, e, sz), cf * CFrame.new(0, 0.04 - e / 2, 0), couleur, mat, nom)
	end
	local function cercle(r, largeur, n, couleur, mat, nom, epaisseur)
		local longueur = DEUX_PI * r / n * 1.02
		local parts = {}
		for k = 0, n - 1 do
			table.insert(parts, incruster(longueur, largeur, tangent((k + 0.5) / n * DEUX_PI, r), couleur, mat, nom, epaisseur))
		end
		return parts
	end
	local function glyphe(cf, motif)
		for _, b in MOTIFS[motif] do
			lueur(incruster(0.42, b[3], cf * CFrame.new(b[1], 0, b[2]) * CFrame.Angles(0, b[4], 0), RUNE, M.Neon, "Rune"))
		end
	end
	-- Aiguilles d'obsidienne (verre noir) ; les plus grandes ont une arête de braise au sommet
	local function cristaux(cf, echelle, nombre)
		local couleur = CRISTAUX[rng:NextInteger(1, 2)]
		for i = 1, nombre do
			local h = rng:NextNumber(2, 4) * echelle * (if i == 1 then 1.4 else 1)
			local base = cf * CFrame.new(rng:NextNumber(-0.4, 0.4) * echelle, 0, rng:NextNumber(-0.4, 0.4) * echelle)
				* CFrame.Angles(0, rng:NextNumber(0, DEUX_PI), 0) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), 0, rng:NextNumber(-0.5, 0.5))
			local p = deco(Vector3.new(h * 0.3, h, h * 0.3), base * CFrame.new(0, h * 0.4, 0), couleur, M.Verre, "Obsidienne")
			p.Transparency = 0.08
			p.Reflectance = 0.15
			if i == 1 and echelle >= 1 then -- fine arête de braise mate (pas de néon : sinon on dirait un tube fluo)
				deco(Vector3.new(h * 0.08, h * 0.16, h * 0.08), base * CFrame.new(0, h * 0.86, 0) * CFrame.Angles(0, math.pi / 4, 0), ARETE, MAGMA, "Arete")
			end
		end
	end
	local function eboulis(cf, nombre, taille)
		for _ = 1, nombre do
			local t = rng:NextNumber(0.5, 1) * taille
			deco(Vector3.new(t, t * rng:NextNumber(0.6, 1), t), cf * CFrame.new(rng:NextNumber(-1, 1) * taille, t * 0.35, rng:NextNumber(-1, 1) * taille)
				* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), PIERRE:Lerp(PIERRE_CLAIRE, rng:NextNumber(0, 0.5)), M.Pierre, "Eboulis")
		end
	end
	local function invisible(taille, cf, nom)
		local p = deco(taille, cf, NOIR, M.Lisse, nom)
		p.Transparency = 1
		return p
	end
	local function brasier(cf, diametre, lumiere)
		O.decor(O.cylindre(m, 1.2, diametre, cf, FER, M.Metal, "Brasero"))
		local braises = petit(O.decor(O.cylindre(m, 0.3, diametre * 0.82, cf * CFrame.new(0, 0.6, 0), BRAISE, M.Neon, "Braises")))
		O.feu(braises, diametre + 1)
		O.etincelles(braises, BRAISE, 4)
		if lumiere then
			O.lumiere(braises, BRAISE, lumiere, 40)
		end
		return braises
	end
	local function chaine(p0: Vector3, p1: Vector3, maillon: number, epais: number)
		local u = (p1 - p0).Unit
		local haut = if math.abs(u.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
		for i = 0, math.floor((p1 - p0).Magnitude / maillon) - 1 do
			local centre = p0 + u * (maillon * (i + 0.5))
			local cf = CFrame.lookAt(centre, centre + u, haut) * CFrame.Angles(0, 0, if i % 2 == 0 then 0 else math.pi / 2)
			for _, s in {-1, 1} do
				deco(Vector3.new(epais, epais, maillon * 1.12), cf * CFrame.new(s * maillon * 0.2, 0, 0), FER, M.Metal, "Chaine")
			end
		end
	end
	-- Bannière déchirée (Model tagué « BanniereArene », pivot = hampe) ; cfHaut : +Z = face visible
	local function banniere(cfHaut, largeur, longueur, couleur)
		local b = Instance.new("Model")
		b.Name = "Banniere"
		local hampe = deco(Vector3.new(largeur + 0.8, 0.4, 0.4), cfHaut, FER, M.Metal, "Hampe")
		hampe.Parent = b
		local w = largeur / 3
		for i = 1, 3 do
			local l = longueur * rng:NextNumber(0.7, 1)
			deco(Vector3.new(w, l, 0.15), cfHaut * CFrame.new(-largeur / 2 + w * (i - 0.5), -l / 2 - 0.2, 0.25), couleur:Lerp(Color3.new(), rng:NextNumber(0, 0.2)),
				M.Tissu, "Toile").Parent = b
		end
		deco(Vector3.new(largeur, 0.6, 0.2), cfHaut * CFrame.new(0, -0.7, 0.3), OR, M.Metal, "Galon").Parent = b
		local e = largeur * 0.42
		deco(Vector3.new(e, e, 0.1), cfHaut * CFrame.new(0, -longueur * 0.32, 0.38) * CFrame.Angles(0, 0, math.pi / 4), OR, M.Metal, "Embleme").Parent = b
		deco(Vector3.new(e * 0.4, e * 1.3, 0.1), cfHaut * CFrame.new(0, -longueur * 0.32, 0.44), Color3.fromRGB(60, 40, 30), M.Tissu, "Marteau").Parent = b
		b.PrimaryPart = hampe
		b:SetAttribute("Phase", rng:NextNumber(0, DEUX_PI))
		O.tag(b, "BanniereArene")
		b.Parent = m
		return b
	end

	-- ===== 1. Le sol de combat (plat à Y, rayon R) =====
	O.cylindre(m, 8, (R + 4) * 2, CFrame.new(c) * CFrame.new(0, -4.12, 0), JOINT, M.Ardoise, "Sol")
	O.cylindre(m, 1, 38, CFrame.new(c) * CFrame.new(0, -0.5, 0), COEUR, BASALTE, "Coeur")
	-- Dalles en anneaux (seules pièces solides du dessus, avec le cœur) ; anneau 5 = bande des runes
	local rayons = {19, 23, 27.5, 32.5, 38, 44.5, 51, 57.5, 64, R}
	for b = 1, #rayons - 1 do
		local rIn, rOut = rayons[b], rayons[b + 1]
		local r = (rIn + rOut) / 2
		local n = math.floor(DEUX_PI * r / 6.5)
		local decal = rng:NextNumber()
		for k = 0, n - 1 do
			local couleur = if b == 6 then DALLE_RUNE:Lerp(DALLE, rng:NextNumber(0, 0.2)) else DALLE:Lerp(DALLE_CLAIRE, rng:NextNumber(0, 0.75))
			petit(O.bloc(m, Vector3.new(DEUX_PI * rIn / n - 0.35, 1, rOut - rIn - 0.35), tangent((k + decal) / n * DEUX_PI, r, -0.5), couleur, M.Ardoise, "Dalle"))
		end
	end
	-- Rosace du centre : soleil nain doré, rayons de runes, anneau bleu, glyphes
	cercle(18.4, 0.7, 48, OR, M.Metal, "Lisere")
	for _, p in cercle(16, 0.6, 40, RUNE, M.Neon, "Rune") do lueur(p) end
	for k = 0, 7 do
		local cf = CFrame.new(c) * CFrame.Angles(0, k * math.pi / 4, 0)
		incruster(0.8, 12, cf * CFrame.new(0, 0, -9), OR, M.Metal, "Rayon")
		local cfr = CFrame.new(c) * CFrame.Angles(0, k * math.pi / 4 + math.pi / 8, 0)
		lueur(incruster(0.5, 6, cfr * CFrame.new(0, 0, -8), RUNE, M.Neon, "Rune"))
		glyphe(cfr * CFrame.new(0, 0, -13.4), k % 4 + 1)
	end
	petit(O.decor(O.cylindre(m, 0.1, 5.4, CFrame.new(c) * CFrame.new(0, -0.01, 0), OR, M.Metal, "Moyeu")))
	lueur(petit(O.decor(O.cylindre(m, 0.1, 2.4, CFrame.new(c) * CFrame.new(0, 0.01, 0), RUNE, M.Neon, "Rune"))))
	-- Grand cercle de runes (bande 44.5 → 51) bordé d'or
	cercle(44.5, 0.5, 72, OR, M.Metal, "Lisere")
	cercle(51, 0.5, 80, OR, M.Metal, "Lisere")
	for k = 0, 23 do
		glyphe(tangent((k + 0.5) / 24 * DEUX_PI, 47.75), k % 4 + 1)
	end
	cercle(R + 0.3, 1, 96, OR, M.Metal, "Lisere", 0.3)
	-- Fissures (hors rosace et cercle de runes) et éclats de cristal pris dans la pierre
	local function horsRunes(d)
		return d > 20 and d < 69 and (d < 43.5 or d > 52)
	end
	for _ = 1, 18 do
		local a, r
		repeat
			a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(21, 68)
		until horsRunes(r)
		local p = Vector3.new(math.sin(a) * r, 0, -math.cos(a) * r)
		local dir = rng:NextNumber(0, DEUX_PI)
		for _ = 1, rng:NextInteger(3, 5) do
			local l = rng:NextNumber(1.5, 3.5)
			dir += rng:NextNumber(-0.9, 0.9)
			local q = p + Vector3.new(math.cos(dir), 0, math.sin(dir)) * l
			if not horsRunes(q.Magnitude) then break end
			incruster(0.3, l + 0.2, CFrame.lookAt(c + (p + q) / 2, c + q), FISSURE, M.Ardoise, "Fissure")
			p = q
		end
	end
	for _ = 1, 16 do
		local a, r
		repeat
			a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(21, 68)
		until horsRunes(r)
		local t = rng:NextNumber(0.6, 1.1)
		incruster(t, t, polaire(a, r) * CFrame.Angles(0, math.pi / 4 + rng:NextNumber(-0.3, 0.3), 0), CRISTAUX[rng:NextInteger(1, 2)], M.Verre, "Eclat").Reflectance = 0.2
	end
	-- Petits cristaux bas au bord du cercle (décor sans collision, ne gênent pas)
	for k = 0, 9 do
		cristaux(polaire((k + rng:NextNumber(0.2, 0.8)) / 10 * DEUX_PI, rng:NextNumber(66.5, 68.5)), 0.45, 3)
	end

	-- ===== 2. Bord du disque : margelle, braseros, attaches des chaînes =====
	for k = 0, 47 do
		local h = 1.4 + rng:NextNumber(-0.08, 0.08)
		deco(Vector3.new(DEUX_PI * 75.1 / 48 + 0.2, h, 3.6), tangent((k + 0.5) / 48 * DEUX_PI, 73.3, -0.12 + h / 2), PIERRE:Lerp(PIERRE_CLAIRE, rng:NextNumber(0.2, 0.6)),
			M.Pierre, "Margelle")
	end
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * DEUX_PI
		local pied = polaire(a, 73.3, 1.28)
		petit(O.decor(O.cylindre(m, 2.6, 3.2, pied * CFrame.new(0, 1.3, 0), PIERRE, M.Ardoise, "PiedBrasero")))
		deco(Vector3.new(3.8, 0.5, 3.8), pied * CFrame.new(0, 2.6, 0), OR, M.Metal, "Collier")
		brasier(pied * CFrame.new(0, 3.4, 0), 4.2, if k % 2 == 0 then 2.2 else nil) -- 4 lumières sur 8 braseros
		-- attache sous le rebord, d'où part une chaîne géante vers la voûte
		O.decor(O.bloc(m, Vector3.new(5, 6, 3), tangent(a, R + 5.4, -4), FER, M.Metal, "Attache"))
		chaine(polaire(a, R + 6, -3).Position, polaire(a, R + 110, HAUT_VOUTE).Position, 11, 1.4)
		O.decor(O.bloc(m, Vector3.new(9, 4, 9), polaire(a, R + 110, HAUT_VOUTE + 1), FER, M.Metal, "Anneau"))
	end

	-- ===== 3. Dessous du disque : éperon de roche suspendu, cristaux pendants =====
	local etages = {{66, 8.12, 8}, {56, 16.12, 9}, {44, 25.12, 10}, {32, 35.12, 12}, {20, 47.12, 14}, {10, 61.12, 16}, {4, 77.12, 12}}
	for i, e in etages do
		O.cylindre(m, e[3], e[1] * 2, CFrame.new(c.X, c.Y - e[2] - e[3] / 2, c.Z), ROCHE:Lerp(ROCHE_SOMBRE, i / #etages), BASALTE, "Eperon")
	end
	for _ = 1, 40 do
		local e = etages[rng:NextInteger(1, #etages)]
		local t = rng:NextNumber(5, 12)
		petit(O.decor(O.bloc(m, Vector3.new(t, t * 1.4, t), polaire(rng:NextNumber(0, DEUX_PI), e[1] - 1, -e[2] - rng:NextNumber(0, e[3]))
			* CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 3), rng:NextNumber(-0.6, 0.6)), ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.7)), BASALTE, "Roc")))
	end
	cristaux(polaire(0, 0, -89) * CFrame.Angles(math.pi, 0, 0), 2.6, 5)

	-- ===== 4. Le ravin de lave autour du disque (lueur, braises qui montent, fumée) =====
	for k = 0, 7 do
		local a = k / 8 * DEUX_PI + 0.2
		local p = invisible(Vector3.new(32, 2, 9), tangent(a, 80, -30), "Ravin")
		local e = O.etincelles(p, BRAISE, 7)
		e.Speed = NumberRange.new(5, 10)
		e.Lifetime = NumberRange.new(4, 7)
		e.SpreadAngle = Vector2.new(15, 15)
		e.Size = NumberSequence.new(0.35, 0)
		O.fumee(p, 1, Color3.fromRGB(96, 54, 44))
		if k % 3 == 0 then -- 3 lumières (total de l'arène ≤ 12)
			O.lumiere(p, Color3.fromRGB(255, 110, 40), 2.6, 64)
		end
	end

	-- ===== 5. Le colisée : falaise annulaire, gradins, portes, colonnade =====
	local PORTES = {0, math.pi / 2, math.pi, 3 * math.pi / 2}
	local function ecartPorte(a, r) -- distance tangentielle à l'axe de la porte la plus proche
		local mini = math.huge
		for _, g in PORTES do
			local d = math.abs((a - g + math.pi) % DEUX_PI - math.pi)
			mini = math.min(mini, math.sin(math.min(d, math.pi / 2)) * r)
		end
		return mini
	end
	local NA = 36
	for k = 0, NA - 1 do
		local a = (k + 0.5) / NA * DEUX_PI
		O.bloc(m, Vector3.new(DEUX_PI * 128 / NA + 1, 155 + rng:NextNumber(0, 0.3), 42), tangent(a, 107, -3 - 77.5), ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.6)),
			BASALTE, "Falaise")
	end
	for _ = 1, 40 do
		local t = rng:NextNumber(5, 12)
		petit(O.decor(O.bloc(m, Vector3.new(t, t * 1.6, t), polaire(rng:NextNumber(0, DEUX_PI), 86.5, -rng:NextNumber(6, 140))
			* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.7)), BASALTE, "Roc")))
	end
	-- Gradins (rangs de 5 studs, +2.5 de haut) ; le dernier rang sert de promenade sous la colonnade
	local rangs = {{86, 91, 2.5}, {91, 96, 5}, {96, 101, 7.5}, {101, 106, 10}, {106, 111, 12.5}, {111, 128, 15}}
	for i, rg in rangs do
		local rIn, rOut, haut = rg[1], rg[2], rg[3]
		local r = (rIn + rOut) / 2
		local n = 48
		local couleurRang = if i % 2 == 0 then 0.15 else 0.45
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * DEUX_PI
			if ecartPorte(a, r) > 25 then
				local h = haut + 3 + rng:NextNumber(0, 0.15)
				local tirage = rng:NextNumber()
				if tirage < 0.06 and i < #rangs then
					eboulis(polaire(a, r, -3), 3, 2.5)
				else
					if tirage < 0.18 then h -= rng:NextNumber(0.8, 2) end
					petit(O.bloc(m, Vector3.new(DEUX_PI * r / n + 0.3, h, rOut - rIn), tangent(a, r, -3 + h / 2),
						PIERRE:Lerp(PIERRE_CLAIRE, couleurRang + rng:NextNumber(-0.1, 0.15)), M.Pierre, "Gradin"))
				end
			end
		end
	end
	for _ = 1, 14 do
		local a = rng:NextNumber(0, DEUX_PI)
		if ecartPorte(a, 100) > 26 then
			local i = rng:NextInteger(1, #rangs)
			eboulis(polaire(a, (rangs[i][1] + rangs[i][2]) / 2, rangs[i][3]), rng:NextInteger(2, 4), 1.8)
		end
	end
	-- Cristaux géants poussés entre les gradins
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * DEUX_PI + rng:NextNumber(-0.15, 0.15)
		local i = rng:NextInteger(2, 5)
		cristaux(polaire(a, (rangs[i][1] + rangs[i][2]) / 2, rangs[i][3]), rng:NextNumber(1.6, 2.4), 4)
	end

	-- Portes fortifiées + ponts au-dessus du ravin
	for _, g in PORTES do
		local base = tangent(g, 107) -- +Z vers le centre ; avant des tours à z = +21 (r = 86)
		O.bloc(m, Vector3.new(18, 3, 42), base * CFrame.new(0, -1.5, 0), PIERRE, M.Ardoise, "Passage")
		for _, s in {-1, 1} do
			O.bloc(m, Vector3.new(15, 55, 42), base * CFrame.new(s * 16.5, 24.5, 0), PIERRE:Lerp(PIERRE_CLAIRE, rng:NextNumber(0.1, 0.4)), M.Ardoise, "Tour")
			for j = 0, 2 do
				if rng:NextNumber() > 0.2 then
					O.decor(O.bloc(m, Vector3.new(3.4, 3, 3.4), base * CFrame.new(s * (10.5 + j * 6), 53.5, 19.3), PIERRE_CLAIRE, M.Ardoise, "Merlon"))
				end
			end
			-- vasque de feu sur la façade
			deco(Vector3.new(2, 1, 3), base * CFrame.new(s * 16.5, 11.5, 22.4), FER, M.Metal, "Support")
			brasier(base * CFrame.new(s * 16.5, 12.4, 24), 4, nil)
			banniere(base * CFrame.new(s * 16.5, 46, 21.3), 7, 20, BANNIERES[1])
		end
		O.bloc(m, Vector3.new(18, 8, 10), base * CFrame.new(0, 26, 16), PIERRE_CLAIRE, M.Ardoise, "Linteau")
		for _, s in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(3, 3, 10), base * CFrame.new(s * 7.5, 20.5, 16), PIERRE_CLAIRE, M.Ardoise, "Arc"))
			O.decor(O.bloc(m, Vector3.new(2, 1.6, 10), base * CFrame.new(s * 5, 21.2, 16), PIERRE_CLAIRE, M.Ardoise, "Arc"))
		end
		O.decor(O.bloc(m, Vector3.new(18, 2, 32), base * CFrame.new(0, 23, -5), PIERRE, M.Ardoise, "Voute"))
		deco(Vector3.new(18, 22, 1), base * CFrame.new(0, 11, -20), NOIR, M.Lisse, "Ombre")
		-- herse à demi levée
		for i = -2, 2 do
			local x = i * 3.6
			deco(Vector3.new(0.8, 13, 0.8), base * CFrame.new(x, 15.5, 18), FER, M.Metal, "Herse")
			deco(Vector3.new(0.5, 1.2, 0.5), base * CFrame.new(x, 8.4, 18), FER, M.Metal, "Pointe")
		end
		for _, y in {12, 17} do
			deco(Vector3.new(18, 0.8, 0.8), base * CFrame.new(0, y, 18), FER, M.Metal, "Herse")
		end
		-- plaque dorée et runes au-dessus de l'arche
		deco(Vector3.new(10, 4, 0.4), base * CFrame.new(0, 26, 21.2), OR, M.Metal, "Plaque")
		for x = -2.5, 2.5, 2.5 do
			lueur(deco(Vector3.new(0.5, 2.8, 0.2), base * CFrame.new(x, 26, 21.45) * CFrame.Angles(0, 0, x * 0.12), RUNE, M.Neon, "Rune"))
		end
		local feu = invisible(Vector3.one, base * CFrame.new(0, 16, 25), "LumierePorte")
		O.lumiere(feu, Color3.fromRGB(255, 170, 100), 1.6, 50)
		-- pont (disque → porte), parapets à bornes dorées
		local pont = tangent(g, 80)
		O.bloc(m, Vector3.new(14, 2, 13), pont * CFrame.new(0, -1.1, 0), PIERRE, M.Ardoise, "Pont")
		O.decor(O.bloc(m, Vector3.new(9, 5, 13), pont * CFrame.new(0, -4.5, 0), ROCHE, BASALTE, "Pont"))
		O.decor(O.coin(m, Vector3.new(9, 10, 5), pont * CFrame.new(0, -12, 4), ROCHE, BASALTE, "Pont"))
		O.decor(O.coin(m, Vector3.new(9, 10, 5), pont * CFrame.new(0, -12, -4) * CFrame.Angles(0, math.pi, 0), ROCHE, BASALTE, "Pont"))
		for _, s in {-1, 1} do
			deco(Vector3.new(1.2, 2, 13), pont * CFrame.new(s * 6.4, 0.9, 0), PIERRE_CLAIRE, M.Pierre, "Parapet")
			for _, z in {-5.5, 5.5} do
				deco(Vector3.new(1.8, 2.8, 1.8), pont * CFrame.new(s * 6.4, 1.3, z), PIERRE_CLAIRE, M.Ardoise, "Borne")
				deco(Vector3.new(2, 0.4, 2), pont * CFrame.new(s * 6.4, 2.9, z), OR, M.Metal, "Borne")
			end
		end
	end

	-- Colonnade (32 travées) : piliers, linteaux, mur du fond à arcades sombres, bannières, torches
	local NB = 32
	local effondrees = {}
	for _ = 1, 5 do effondrees[rng:NextInteger(0, NB - 1)] = true end
	for k = 0, NB - 1 do
		local aP = k / NB * DEUX_PI
		if ecartPorte(aP, 120) > 26 then
			local casse = effondrees[k] or effondrees[(k - 1) % NB]
			local h = if casse then rng:NextNumber(6, 14) else 22
			local pied = polaire(aP, 120, 15)
			O.bloc(m, Vector3.new(5, 1.5, 5), pied * CFrame.new(0, 0.75, 0), PIERRE_CLAIRE, M.Ardoise, "BasePilier")
			O.cylindre(m, h, 3.6, pied * CFrame.new(0, 1.5 + h / 2, 0), PIERRE:Lerp(PIERRE_CLAIRE, 0.5), M.Pierre, "Pilier")
			if casse then
				eboulis(pied * CFrame.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)), 3, 2)
			else
				O.bloc(m, Vector3.new(5.2, 1.6, 5.2), pied * CFrame.new(0, 24.3, 0), PIERRE_CLAIRE, M.Ardoise, "Chapiteau")
				if k % 4 == 2 then -- torche sur la face intérieure
					local t = tangent(aP, 120, 15)
					deco(Vector3.new(0.6, 2.4, 0.6), t * CFrame.new(0, 12, 2.4) * CFrame.Angles(0.4, 0, 0), FER, M.Metal, "Torche")
					local flamme = deco(Vector3.new(0.8, 0.8, 0.8), t * CFrame.new(0, 13.4, 2.9), BRAISE, M.Neon, "Flamme")
					O.feu(flamme, 2.5)
				end
			end
		end
		local aT = (k + 0.5) / NB * DEUX_PI
		if ecartPorte(aT, 120) > 26 then
			local mur = tangent(aT, 125.5, 15)
			if effondrees[k] then
				local h = rng:NextNumber(8, 16)
				O.bloc(m, Vector3.new(DEUX_PI * 128 / NB + 0.5, h, 5), mur * CFrame.new(0, h / 2, 0), ROCHE:Lerp(PIERRE, 0.5), M.Ardoise, "Mur")
				eboulis(tangent(aT, 117, 15), 4, 2.4)
			else
				local h = 30 + rng:NextNumber(0, 0.2)
				O.bloc(m, Vector3.new(DEUX_PI * 128 / NB + 0.5, h, 5), mur * CFrame.new(0, h / 2, 0), ROCHE:Lerp(PIERRE, 0.5), M.Ardoise, "Mur")
				-- arcade sombre en escalier sur la face intérieure
				deco(Vector3.new(12, 16, 0.3), mur * CFrame.new(0, 8.5, 2.6), NOIR, M.Lisse, "Arcade")
				deco(Vector3.new(8, 2, 0.3), mur * CFrame.new(0, 17.5, 2.6), NOIR, M.Lisse, "Arcade")
				deco(Vector3.new(4, 1.5, 0.3), mur * CFrame.new(0, 19.2, 2.6), NOIR, M.Lisse, "Arcade")
				local linteau = tangent(aT, 120 * math.cos(math.pi / NB), 15)
				O.bloc(m, Vector3.new(2 * 120 * math.sin(math.pi / NB) + 4, 3, 4.6), linteau * CFrame.new(0, 26.6, 0), PIERRE_CLAIRE, M.Ardoise, "Linteau")
				if k % 2 == 0 then
					banniere(linteau * CFrame.new(0, 24.6, 2.6), 6, 14, BANNIERES[(k // 2) % 2 + 1])
				end
			end
		end
	end

	-- ===== 6. Quatre rois nains de pierre (diagonales), mains sur le manche de leur arme =====
	local S = 1.15
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		O.bloc(m, Vector3.new(16, 20, 16), face(a, 104, 7), PIERRE, M.Ardoise, "Socle")
		deco(Vector3.new(16.6, 1, 16.6), face(a, 104, 16.6), OR, M.Metal, "Socle")
		local base = face(a, 104, 17)
		local teinte = PIERRE_CLAIRE:Lerp(PIERRE, rng:NextNumber(0, 0.3))
		local function piece(sx, sy, sz, x, y, z, couleur, mat, nom, rot)
			local p = O.decor(O.bloc(m, Vector3.new(sx, sy, sz) * S, base * CFrame.new(x * S, y * S, z * S) * (rot or CFrame.identity), couleur or teinte, mat or M.Ardoise, nom or "Statue"))
			return p
		end
		local sombre = teinte:Lerp(ROCHE, 0.5)
		for _, s in {-1, 1} do
			piece(4.5, 3, 6.5, s * 3, 1.5, -0.6, sombre)
			piece(4, 6, 4.2, s * 3, 6, 0)
			piece(5, 3.5, 8, s * 7.6, 21, 0)
			piece(5.4, 0.6, 8.4, s * 7.6, 19.4, 0, OR, M.Metal)
			piece(3.6, 6, 3.6, s * 7.4, 16.5, 0)
			piece(3.6, 3.6, 6, s * 5.6, 13.6, -3.6)
			piece(3.8, 3.8, 3.8, s * 2.3, 13.6, -7.4)
			lueur(petit(piece(1.3, 0.7, 0.3, s * 1.6, 26.6, -3.85, RUNE, M.Neon, "Oeil")), 0.2)
			piece(2.4, 0.8, 0.8, s * 1.6, 27.6, -3.9, sombre)
			piece(5, 1.8, 1.8, s * 6, 30, -0.3, OS, M.Calcaire, "Corne")
			piece(1.6, 4, 1.6, s * 8.2, 32.4, -0.3, OS, M.Calcaire, "Corne")
		end
		piece(11, 4, 7.4, 0, 10.5, 0, sombre)
		piece(12, 1.6, 8, 0, 12.6, 0, sombre:Lerp(Color3.new(), 0.3))
		piece(3, 2.4, 0.5, 0, 12.6, -4.2, OR, M.Metal)
		piece(12, 9, 8, 0, 17.5, 0)
		piece(7, 7, 7, 0, 25.5, -0.3)
		piece(1.6, 2.2, 1.6, 0, 25, -4.4)
		piece(8.4, 9, 2.6, 0, 20.8, -4.6, teinte:Lerp(PIERRE_CLAIRE, 0.4))
		piece(6, 5, 2.4, 0, 14.6, -5, teinte:Lerp(PIERRE_CLAIRE, 0.4))
		piece(3, 3, 2, 0, 11, -5.2, teinte:Lerp(PIERRE_CLAIRE, 0.4))
		piece(3.2, 0.8, 2.9, 0, 15.5, -5, OR, M.Metal)
		piece(8, 3, 8, 0, 29.6, -0.3, sombre)
		piece(8.6, 0.8, 8.6, 0, 28.2, -0.3, OR, M.Metal)
		piece(1.6, 2.6, 7, 0, 32.4, -0.3, OR, M.Metal)
		piece(12, 20, 1, 0, 13, 4.5, sombre)
		-- arme posée tête en bas : marteau (rois 0 et 2) ou hache (rois 1 et 3)
		piece(1.6, 12, 1.6, 0, 8.5, -8, FER, M.Metal, "Arme")
		piece(2.2, 2.2, 2.2, 0, 15.8, -8, OR, M.Metal, "Arme")
		if k % 2 == 0 then
			piece(9, 5, 5.5, 0, 2.5, -8, FER:Lerp(PIERRE, 0.4), M.Metal, "Arme")
			for _, s in {-1, 1} do piece(0.6, 5.4, 5.9, s * 4.6, 2.5, -8, OR, M.Metal, "Arme") end
		else
			piece(2.4, 5, 2.4, 0, 3, -8, FER, M.Metal, "Arme")
			for _, s in {-1, 1} do
				piece(4, 6, 1, s * 3.2, 3, -8, FER:Lerp(PIERRE, 0.4), M.Metal, "Arme")
				piece(1, 7, 1.1, s * 5.4, 3, -8, OR, M.Metal, "Arme")
			end
		end
	end

	-- ===== 7. Lustre de fer au-dessus du centre (lumière principale du combat) =====
	local lustre = CFrame.new(c) * CFrame.new(0, 44, 0)
	for k = 0, 15 do
		local a = (k + 0.5) / 16 * DEUX_PI
		deco(Vector3.new(DEUX_PI * 11 / 16 + 0.3, 1, 1.2), lustre * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -11), FER, M.Metal, "Lustre")
		if k % 2 == 0 then
			local bougie = lustre * CFrame.Angles(0, -a, 0) * CFrame.new(0, 1.5, -11)
			petit(O.decor(O.cylindre(m, 2, 1.2, bougie, Color3.fromRGB(220, 206, 176), M.Lisse, "Bougie")))
			deco(Vector3.new(0.6, 1, 0.6), bougie * CFrame.new(0, 1.5, 0), BRAISE, M.Neon, "Flamme")
		end
	end
	for k = 0, 1 do
		deco(Vector3.new(22, 0.8, 0.8), lustre * CFrame.Angles(0, k * math.pi / 2, 0), FER, M.Metal, "Lustre")
	end
	local moyeu = deco(Vector3.new(3, 3, 3), lustre, FER, M.Metal, "Lustre")
	O.lumiere(moyeu, Color3.fromRGB(255, 214, 170), 1.6, 60)
	chaine((lustre * CFrame.new(0, 1.5, 0)).Position, c + Vector3.new(0, HAUT_VOUTE, 0), 5, 0.6)

	-- ===== 8. La grande caverne : mer de lave, voûte, parois, colonnes, stalactites, cascades, rocs flottants =====
	deco(Vector3.new(1400, 4, 1400), CFrame.new(c) * CFrame.new(0, BAS_LAVE - 2, 0), LAVE_SOMBRE, M.Neon, "MerDeLave")
	for _ = 1, 40 do
		local a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(135, 640)
		deco(Vector3.new(rng:NextNumber(20, 80), 1.5, rng:NextNumber(20, 80)), polaire(a, r, BAS_LAVE + 0.4) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			ROCHE_SOMBRE, O.materiau("CrackedLava", M.Ardoise), "Croute")
	end
	local voute = deco(Vector3.new(1400, 30, 1400), CFrame.new(c) * CFrame.new(0, HAUT_VOUTE + 15, 0), ROCHE, BASALTE, "Voute")
	voute.CastShadow = true -- la voûte cache le ciel : l'arène n'est éclairée que par ses feux et l'ambiance
	-- Relief de la voûte (visible depuis le sol) : gros lobes de roche pendants, veines de magma sombres qui la dessinent
	for k = 0, 17 do
		local a, r = (k + rng:NextNumber(0.1, 0.9)) / 18 * DEUX_PI, rng:NextNumber(130, 340)
		local l, h = rng:NextNumber(50, 110), rng:NextNumber(16, 34)
		local p = polaire(a, r, HAUT_VOUTE - h / 2 + 2) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), rng:NextNumber(0, 3), rng:NextNumber(-0.1, 0.1))
		local couleur = ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.5))
		deco(Vector3.new(l, h, l * rng:NextNumber(0.4, 0.7)), p, couleur, BASALTE, "Lobe")
		deco(Vector3.new(l * 0.55, h * 0.8, l * 0.35), p * CFrame.new(rng:NextNumber(-8, 8), -h * 0.55, 0) * CFrame.Angles(0, 0.4, 0), couleur, BASALTE, "Lobe")
	end
	for k = 0, 35 do
		local a, r = (k + rng:NextNumber(0, 1)) / 36 * DEUX_PI, rng:NextNumber(70, 420)
		local veine = deco(Vector3.new(rng:NextNumber(1.2, 2.6), 0.6, rng:NextNumber(24, 70)), polaire(a, r, HAUT_VOUTE - 0.2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			VEINE, M.Neon, "VeineVoute")
		veine.Transparency = 0.25
	end
	for k = 0, 23 do
		deco(Vector3.new(DEUX_PI * 640 / 24 + 10, 470, 60), tangent((k + 0.5) / 24 * DEUX_PI, 640, 80), ROCHE_SOMBRE:Lerp(ROCHE, rng:NextNumber(0, 0.4)), BASALTE, "Paroi")
	end
	for _ = 1, 7 do
		local a, r, d = rng:NextNumber(0, DEUX_PI), rng:NextNumber(260, 480), rng:NextNumber(40, 70)
		local p = polaire(a, r)
		local couleur = ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0.2, 0.7))
		O.decor(O.cylindre(m, HAUT_VOUTE - BAS_LAVE, d, p * CFrame.new(0, (HAUT_VOUTE + BAS_LAVE) / 2, 0), couleur, BASALTE, "Colonne"))
		petit(O.decor(O.cylindre(m, 30, d * 1.5, p * CFrame.new(0, BAS_LAVE + 12, 0), couleur, BASALTE, "Colonne")))
		petit(O.decor(O.cylindre(m, 40, d * 1.6, p * CFrame.new(0, HAUT_VOUTE - 18, 0), couleur, BASALTE, "Colonne")))
	end
	for _ = 1, 50 do
		local a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(60, 560)
		local l = rng:NextNumber(25, if r < 140 then 60 else 110)
		local w = l * 0.22
		local p = polaire(a, r, HAUT_VOUTE) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		local couleur = ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.6))
		deco(Vector3.new(w, l * 0.5, w), p * CFrame.new(0, -l * 0.25, 0), couleur, BASALTE, "Stalactite")
		deco(Vector3.new(w * 0.65, l * 0.35, w * 0.65), p * CFrame.new(0, -l * 0.675, 0) * CFrame.Angles(0, 0.4, 0), couleur, BASALTE, "Stalactite")
		local pointe = deco(Vector3.new(w * 0.35, l * 0.25, w * 0.35), p * CFrame.new(0, -l * 0.97, 0) * CFrame.Angles(0, 0.8, 0), couleur, BASALTE, "Stalactite")
		if rng:NextNumber() < 0.2 then
			pointe.Color, pointe.Material = ARETE, MAGMA -- pointe de magma figé (mate)
		end
	end
	for _ = 1, 15 do
		local a, r, l = rng:NextNumber(0, DEUX_PI), rng:NextNumber(150, 600), rng:NextNumber(40, 160)
		local w = l * 0.2
		local p = polaire(a, r, BAS_LAVE) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		deco(Vector3.new(w, l * 0.55, w), p * CFrame.new(0, l * 0.27, 0), ROCHE_SOMBRE, BASALTE, "Aiguille")
		deco(Vector3.new(w * 0.6, l * 0.5, w * 0.6), p * CFrame.new(0, l * 0.75, 0) * CFrame.Angles(0, 0.5, 0), ROCHE, BASALTE, "Aiguille")
	end
	for k = 0, 5 do
		local a, r = (k + rng:NextNumber(0.2, 0.8)) / 6 * DEUX_PI, rng:NextNumber(420, 560)
		local hauteur = HAUT_VOUTE - BAS_LAVE
		local cf = tangent(a, r, (HAUT_VOUTE + BAS_LAVE) / 2)
		-- coulée de lave figée (mate) parcourue de quelques filets de magma sombres décalés : plus de « tube fluo »
		deco(Vector3.new(28, hauteur, 4), cf, Color3.fromRGB(66, 30, 20), MAGMA, "Cascade")
		for _ = 1, 3 do
			local l = rng:NextNumber(0.25, 0.6) * hauteur
			local filet = deco(Vector3.new(rng:NextNumber(1.5, 3.5), l, 1), cf * CFrame.new(rng:NextNumber(-10, 10), rng:NextNumber(-0.5, 0.5) * (hauteur - l), 2.4),
				VEINE, M.Neon, "Cascade")
			filet.Transparency = 0.3
		end
		deco(Vector3.new(44, 14, 34), tangent(a, r, HAUT_VOUTE - 4), ROCHE_SOMBRE, BASALTE, "Source")
		petit(O.decor(O.cylindre(m, 1, 46, polaire(a, r, BAS_LAVE + 0.6), LAVE, M.Neon, "Bassin")))
		local vapeur = invisible(Vector3.new(30, 4, 30), polaire(a, r, BAS_LAVE + 4), "Vapeur")
		O.fumee(vapeur, 3, Color3.fromRGB(120, 72, 62))
	end
	for _ = 1, 14 do
		local a, r, t = rng:NextNumber(0, DEUX_PI), rng:NextNumber(150, 320), rng:NextNumber(8, 24)
		local p = polaire(a, r, rng:NextNumber(-60, 90)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2))
		deco(Vector3.new(t * 1.4, t * 0.7, t), p, ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.5)), BASALTE, "RocFlottant")
		deco(Vector3.new(t * 0.8, t * 0.8, t * 0.6), p * CFrame.new(0, -t * 0.6, 0) * CFrame.Angles(0, 0.5, 0), ROCHE_SOMBRE, BASALTE, "RocFlottant")
		if rng:NextNumber() < 0.45 then
			cristaux(p * CFrame.new(0, t * 0.35, 0), t * 0.25, 3)
		end
	end

	-- ===== 9. Atmosphère du volcan : braises qui montent, cendres qui tombent, brume au ras du sol =====
	local air = invisible(Vector3.new(130, 30, 130), CFrame.new(c) * CFrame.new(0, 16, 0), "Poussiere")
	local poussiere = O.lucioles(air, Color3.fromRGB(255, 170, 110), 6)
	poussiere.LightEmission = 0.5
	poussiere.Acceleration = Vector3.new(0, 0.8, 0)
	poussiere.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 0)})
	local ciel = invisible(Vector3.new(150, 2, 150), CFrame.new(c) * CFrame.new(0, 60, 0), "Cendres")
	local cendres = O.lucioles(ciel, Color3.fromRGB(120, 112, 110), 7)
	cendres.LightEmission = 0
	cendres.Speed = NumberRange.new(1, 2)
	cendres.Acceleration = Vector3.new(0.4, -2, 0.2)
	cendres.Lifetime = NumberRange.new(8, 12)
	cendres.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.08)})
	local nappe = invisible(Vector3.new(140, 1, 140), CFrame.new(c) * CFrame.new(0, 1, 0), "Brume")
	O.brume(nappe, Color3.fromRGB(150, 122, 128), 2)
end

-- Murs invisibles (on ne tombe pas, les mobs restent dedans : ils sont solides et touchés par leurs rayons).
-- Toutes les voûtes sont décoratives (ignorées des rayons) : LumiereSouterraine ne prend pas l'arène pour un souterrain.
local function mursInvisibles(m: Model, c: Vector3, R: number)
	local SEG = 36
	local longueurMurInv = 2 * math.pi * (R + 1.5) / SEG * 1.1
	for k = 0, SEG - 1 do
		local a = (k + 0.5) / SEG * 2 * math.pi
		local pos = CFrame.new(c.X + math.sin(a) * (R + 2.5), c.Y + 30, c.Z - math.cos(a) * (R + 2.5))
		local mur = O.bloc(m, Vector3.new(longueurMurInv, 60, 2), pos * CFrame.Angles(0, -a, 0), PIERRE, M.Lisse, "MurInvisible")
		mur.Transparency = 1
		mur.CastShadow = false
	end
end

-- Constructeurs par boss (les deux autres sont chargés seulement si on en a besoin)
local CONSTRUCTEURS = {
	SeigneurBraise = function() return construireFosse end,
	TitanCristal = function() return require(script.Parent.AreneCristal) end,
	ReineAraignee = function() return require(script.Parent.AreneNid) end,
}
AreneBoss.NOMS = {
	SeigneurBraise = "La Fosse des Rois Nains",
	TitanCristal = "La Géode du Titan",
	ReineAraignee = "Le Nid de la Reine",
}

function AreneBoss.nomModele(id: string): string
	return "AreneBoss_" .. id
end

function AreneBoss.centre(id: string): Vector3
	return D.ARENES_BOSS[id] or D.ARENE_BOSS
end

-- (Re)construit l'arène du boss id (inconnu → la Fosse). Model « AreneBoss_<id> » dans workspace.
function AreneBoss.construire(id: string?): Model
	local cle = if id and CONSTRUCTEURS[id] then id else "SeigneurBraise"
	local nom = AreneBoss.nomModele(cle)
	local ancienne = workspace:FindFirstChild(nom)
	if ancienne then
		ancienne:Destroy()
	end
	local c, R = AreneBoss.centre(cle), D.ARENE_RAYON
	local m = Instance.new("Model")
	m.Name = nom
	CONSTRUCTEURS[cle]()(m, c, R)
	mursInvisibles(m, c, R)
	m:SetAttribute("Centre", c)
	m:SetAttribute("Rayon", R)
	m:SetAttribute("Arene", cle)
	m:SetAttribute("NomArene", AreneBoss.NOMS[cle])
	m.Parent = workspace
	return m
end

-- Arène du boss id, construite à la première utilisation puis réutilisée
function AreneBoss.obtenir(id: string?): Model
	local cle = if id and CONSTRUCTEURS[id] then id else "SeigneurBraise"
	local m = workspace:FindFirstChild(AreneBoss.nomModele(cle))
	if m and m:IsA("Model") and m:GetAttribute("Centre") then
		return m
	end
	return AreneBoss.construire(cle)
end

return AreneBoss
