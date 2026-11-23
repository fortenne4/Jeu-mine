-- Arène du Titan de cristal (ServerStorage › Monde › AreneCristal) : « La Géode du Titan ».
-- Le sol de combat est une immense tranche d'agate polie (anneaux concentriques gris-lavande, veines de cristal qui
-- pulsent en onde depuis le centre, sceau hexagonal au milieu), posée sur un piton au-dessus d'une faille étroite où
-- brillent des cristaux. Comme le colisée de la Fosse, l'arène est FERMÉE : une terrasse de pierre (r 90 → 120)
-- porte des ruines naines adossées à la paroi (grande porte au nord, quatre rois nains de pierre sur les diagonales,
-- tête colossale à demi enfouie au sud, escalier et balcon à l'est, gardiens pris dans le cristal à l'ouest, arcades
-- sombres entre les deux), puis la paroi courbe de la géode (r ≈ 120 à la base) remonte en voûte jusqu'à +130.
-- Elle est tapissée de grands prismes inclinés et d'amas de pointes serrées ; des cristaux pendent de la voûte et un
-- lustre de cristal éclaire le centre. Plusieurs plans : sol → faille → terrasse et ruines → paroi → voûte.
-- Appelé par AreneBoss.construire("TitanCristal") (≈ 2 800 pièces ancrées, 11 lumières froides).
-- Gameplay : sol plat à c.Y sur tout le rayon R (une seule pièce solide), tout le reste est décor sans collision.
local O = require(script.Parent.Outils)
local Kit = require(script.Parent.AreneKit)
local M = O.M

local MARBRE = O.materiau("Marble", M.Lisse)
local BASALTE = O.materiau("Basalt", M.Ardoise)

-- Palette froide et mate : pierre polie gris-violet, cristaux violets / bleus (jamais rouges), or terni nain
local SOL = Color3.fromRGB(50, 48, 66)
local AGATES = {
	Color3.fromRGB(68, 64, 90), Color3.fromRGB(90, 86, 116), Color3.fromRGB(116, 112, 142),
	Color3.fromRGB(62, 72, 102), Color3.fromRGB(140, 136, 160), Color3.fromRGB(80, 70, 106),
}
local VIOLET = Color3.fromRGB(138, 96, 214)
local BLEU = Color3.fromRGB(90, 144, 228)
local INDIGO = Color3.fromRGB(110, 102, 224)
local GLACE = Color3.fromRGB(176, 206, 250)
local CRISTAUX = {VIOLET, BLEU, INDIGO}
local ROCHE = Color3.fromRGB(48, 46, 62)
local ROCHE_SOMBRE = Color3.fromRGB(24, 22, 34)
local PAROI = Color3.fromRGB(78, 74, 100) -- paroi de la géode (assez claire pour se lire à la lumière froide)
local PAROI_SOMBRE = Color3.fromRGB(40, 38, 56)
local QUARTZ = Color3.fromRGB(168, 162, 188) -- liseré de quartz laiteux des géodes
local PIERRE = Color3.fromRGB(106, 104, 118)
local PIERRE_CLAIRE = Color3.fromRGB(146, 142, 154)
local OR = Color3.fromRGB(164, 140, 88)
local FER = Color3.fromRGB(56, 56, 66)
local NOIR = Color3.fromRGB(10, 10, 16)
local RUNE = Color3.fromRGB(110, 150, 236)
local FROID = Color3.fromRGB(172, 200, 255)

return function(m: Model, c: Vector3, R: number)
	local rng = Random.new(7172)
	local k = Kit.nouveau(m, c, rng)
	local DEUX_PI = Kit.DEUX_PI
	local deco, incruster, polaire, tangent, face = k.deco, k.incruster, k.polaire, k.tangent, k.face
	local Y_T = -1 -- dessus de la terrasse des ruines (r 90 → 120)
	local RH, RV, Y0 = 122, 110, 20 -- paroi : demi-ellipsoïde (rayon à l'équateur, demi-hauteur, hauteur de l'équateur)

	-- Plaque incrustée à une hauteur donnée (dessus à +0.04 + dy, toujours sous les télégraphes à +0.08)
	local function plaque(sx, sz, cf, couleur, mat, nom, dy)
		return incruster(sx, sz, cf * CFrame.new(0, dy or 0, 0), couleur, mat, nom)
	end
	-- Hexagone plat (trois rectangles à 60°)
	local function hexagone(cf, taille, couleur, mat, nom, dy)
		local parts = {}
		for i = 0, 2 do
			table.insert(parts, plaque(taille * 0.577, taille, cf * CFrame.Angles(0, i * math.pi / 3, 0), couleur, mat, nom, dy))
		end
		return parts
	end
	-- Point de la paroi (latitude phi, azimut a) et normale sortante
	local function paroi(phi: number, a: number): (Vector3, Vector3)
		local r = RH * math.cos(phi)
		local nh, nv = math.cos(phi) / RH, math.sin(phi) / RV
		local l = math.sqrt(nh * nh + nv * nv)
		nh, nv = nh / l, nv / l
		local s, co = math.sin(a), math.cos(a)
		return Vector3.new(c.X + s * r, c.Y + Y0 + RV * math.sin(phi), c.Z - co * r), Vector3.new(s * nh, nv, -co * nh)
	end
	-- Ruines adossées au pied de la paroi (angle, demi-largeur) : pas de cristaux devant, en bas de la paroi
	local RUINES = {{0, 0.27}, {math.pi, 0.2}, {math.pi / 2, 0.3}, {3 * math.pi / 2, 0.3}}
	for j = 0, 3 do
		table.insert(RUINES, {math.pi / 4 + j * math.pi / 2, 0.1})
	end
	for j = 0, 7 do
		table.insert(RUINES, {math.pi / 8 + j * math.pi / 4, 0.07})
	end
	local function libre(a: number, phi: number): boolean
		if phi > math.rad(24) then
			return true
		end
		for _, z in RUINES do
			if math.abs((a - z[1] + math.pi) % DEUX_PI - math.pi) < z[2] then
				return false
			end
		end
		return true
	end

	-- ===== 1. Le sol de combat : tranche d'agate polie (seule pièce solide) =====
	O.cylindre(m, 8, (R + 8) * 2, CFrame.new(c) * CFrame.new(0, -4, 0), SOL, MARBRE, "Sol")
	local r, i = 8.5, 0
	while r < 67 do
		local largeur = rng:NextNumber(1.6, 4.4)
		i += 1
		if i % 2 == 0 or rng:NextNumber() < 0.25 then
			local rm = r + largeur / 2
			k.cercle(rm, largeur, math.floor(DEUX_PI * rm / 8) + 6, AGATES[rng:NextInteger(1, #AGATES)], MARBRE, "Agate", 0.1)
		end
		r += largeur + rng:NextNumber(0, 1.4)
	end
	k.cercle(R + 0.3, 1, 96, QUARTZ, MARBRE, "Lisere", 0.3)
	k.cercle(18.5, 0.6, 40, QUARTZ, MARBRE, "Lisere")
	-- Sceau du centre : hexagones emboîtés (quartz, ardoise, cristal) et six pétales
	hexagone(CFrame.new(c), 15, QUARTZ, MARBRE, "Sceau", -0.01)
	hexagone(CFrame.new(c) * CFrame.Angles(0, math.pi / 6, 0), 11, ROCHE, MARBRE, "Sceau", 0)
	for _, p in hexagone(CFrame.new(c), 5, VIOLET, M.Neon, "Sceau", 0.012) do k.lueur(p, 0.45, "EchoArene") end
	for j = 0, 5 do
		local cf = CFrame.new(c) * CFrame.Angles(0, j * math.pi / 3, 0)
		k.lueur(plaque(1.6, 1.6, cf * CFrame.new(0, 0, -11.5) * CFrame.Angles(0, math.pi / 4, 0), if j % 2 == 0 then BLEU else VIOLET, M.Neon, "Petale", 0.01), 0.4, "EchoArene")
		plaque(0.5, 6, cf * CFrame.Angles(0, math.pi / 6, 0) * CFrame.new(0, 0, -12), OR, M.Metal, "Rayon", 0.005)
	end
	-- Anneau de douze hexagones de cristal (r = 47) : runes naines englouties dans la pierre
	for j = 0, 11 do
		local cf = tangent((j + 0.5) / 12 * DEUX_PI, 47)
		hexagone(cf, 4.6, QUARTZ, MARBRE, "Hexa", 0.005)
		for _, p in hexagone(cf * CFrame.Angles(0, math.pi / 6, 0), 2.6, CRISTAUX[j % 3 + 1], M.Neon, "Hexa", 0.012) do k.lueur(p, 0.45, "EchoArene") end
	end
	-- Veines de cristal (lueur douce en onde depuis le centre) et éclats plats
	for j = 0, 23 do
		local a = (j + rng:NextNumber(0.1, 0.9)) / 24 * DEUX_PI
		for _, p in k.veine(a, rng:NextNumber(10, 58), rng:NextInteger(4, 7), rng:NextNumber(0.35, 0.6), CRISTAUX[rng:NextInteger(1, 3)], M.Neon, 9.5, 68.5) do
			p.CFrame += Vector3.new(0, 0.015, 0)
			k.lueur(p, 0.45, "EchoArene")
		end
	end
	for _ = 1, 18 do
		local t = rng:NextNumber(0.7, 1.3)
		local p = plaque(t, t * 1.6, polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(20, 66)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), GLACE, M.Neon, "Eclat", 0.016)
		p.Transparency = 0.35
	end
	-- Petites grappes basses au bord du cercle (décor sans collision)
	for j = 0, 9 do
		k.grappe(polaire((j + rng:NextNumber(0.2, 0.8)) / 10 * DEUX_PI, rng:NextNumber(66.5, 68.5)), 0.5, 3, CRISTAUX)
	end

	-- ===== 2. Margelle de pierre polie, pylônes de cristal =====
	for j = 0, 47 do
		local h = 1.4 + rng:NextNumber(-0.08, 0.08)
		deco(Vector3.new(DEUX_PI * 75.1 / 48 + 0.2, h, 3.6), tangent((j + 0.5) / 48 * DEUX_PI, 73.3, -0.12 + h / 2), PIERRE:Lerp(PIERRE_CLAIRE, rng:NextNumber(0.2, 0.7)),
			MARBRE, "Margelle")
	end
	for j = 0, 7 do
		local a = (j + 0.5) / 8 * DEUX_PI
		local pied = polaire(a, 74, 1.28)
		k.cyl(2.4, 4.4, pied * CFrame.new(0, 1.2, 0), PIERRE, MARBRE, "Socle")
		deco(Vector3.new(4.8, 0.5, 4.8), pied * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, math.pi / 4, 0), OR, M.Metal, "Collier")
		k.cristal(pied * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, a, 0), 13, 3.2, CRISTAUX[j % 2 + 1], {coeur = true})
		if j % 2 == 0 then
			k.lumiere(pied * CFrame.new(0, 8, 0), FROID, 1.2, 42)
		end
	end

	-- ===== 3. Piton sous le disque (vu depuis la faille) et grand cristal pendant =====
	local etages = {{R + 6, 8, 10}, {60, 18, 12}, {46, 30, 14}, {30, 44, 16}, {15, 60, 16}}
	for j, e in etages do
		k.cyl(e[3], e[1] * 2, CFrame.new(c.X, c.Y - e[2] - e[3] / 2, c.Z), ROCHE:Lerp(ROCHE_SOMBRE, j / #etages), BASALTE, "Piton")
	end
	for _ = 1, 16 do
		local e = etages[rng:NextInteger(1, #etages)]
		local t = rng:NextNumber(5, 11)
		deco(Vector3.new(t, t * 1.4, t), polaire(rng:NextNumber(0, DEUX_PI), e[1] - 1, -e[2] - rng:NextNumber(0, e[3]))
			* CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 3), rng:NextNumber(-0.6, 0.6)), ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.7)), BASALTE, "Roc")
	end
	k.cristal(CFrame.new(c) * CFrame.new(0, -74, 0) * CFrame.Angles(math.pi, 0, 0), 30, 8, VIOLET, {coeur = true})

	-- ===== 4. La faille (r 76 → 90) : lit de cristaux qui brillent au fond, poussière qui monte =====
	k.cyl(4, 2 * 96, CFrame.new(c) * CFrame.new(0, -70, 0), ROCHE_SOMBRE, BASALTE, "Fond")
	for j = 0, 17 do
		local a = (j + rng:NextNumber(0.1, 0.9)) / 18 * DEUX_PI
		local L = rng:NextNumber(12, 26)
		k.cristal(polaire(a, rng:NextNumber(79, 87), -69) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 3), rng:NextNumber(-0.35, 0.35)),
			L, L * 0.28, CRISTAUX[rng:NextInteger(1, 3)], {coeur = j % 3 == 0})
	end
	for j = 0, 7 do
		local p = k.invisible(Vector3.new(24, 2, 8), tangent(j / 8 * DEUX_PI + 0.2, 83, -40), "Faille")
		local e = O.lucioles(p, GLACE, 5)
		e.Speed = NumberRange.new(3, 6)
		e.Lifetime = NumberRange.new(6, 9)
		e.Acceleration = Vector3.new(0, 1, 0)
		if j % 4 == 0 then
			O.lumiere(p, BLEU, 2.2, 60)
		end
	end
	-- Quatre ponts de pierre polie au-dessus de la faille (diagonales), lanternes de cristal
	for j = 0, 3 do
		local a = math.pi / 4 + j * math.pi / 2
		local pont = tangent(a, 83)
		deco(Vector3.new(12, 2, 20), pont * CFrame.new(0, -1.1, 0), PIERRE, MARBRE, "Pont")
		deco(Vector3.new(8, 6, 20), pont * CFrame.new(0, -5, 0), ROCHE, BASALTE, "Pont")
		for _, s in {-1, 1} do
			deco(Vector3.new(1.2, 1.8, 20), pont * CFrame.new(s * 5.6, 0.8, 0), PIERRE_CLAIRE, MARBRE, "Parapet")
			k.cristal(pont * CFrame.new(s * 5.6, 1.6, rng:NextNumber(-5, 5)), 4, 1.3, CRISTAUX[rng:NextInteger(1, 3)], {coeur = true})
		end
	end

	-- ===== 5. La terrasse des ruines (r 90 → 121), dallée de pierre, bord de quartz laiteux =====
	for j = 0, 35 do
		local a = (j + 0.5) / 36 * DEUX_PI
		deco(Vector3.new(DEUX_PI * 121.5 / 36 + 1.5, 44, 32), tangent(a, 105.5, Y_T - 22), PIERRE:Lerp(PIERRE_CLAIRE, if j % 2 == 0 then 0.1 else 0.4):Lerp(ROCHE, rng:NextNumber(0, 0.3)),
			M.Ardoise, "Terrasse")
	end
	for j = 0, 47 do
		deco(Vector3.new(DEUX_PI * 90 / 48 + 0.6, 2.4, 3.4), tangent((j + 0.5) / 48 * DEUX_PI, 90.6, Y_T - 0.6), QUARTZ:Lerp(PIERRE_CLAIRE, rng:NextNumber(0, 0.5)), MARBRE, "Quartz")
	end
	for _ = 1, 14 do
		local t = rng:NextNumber(5, 10)
		deco(Vector3.new(t, t * 1.3, t), polaire(rng:NextNumber(0, DEUX_PI), 89.5, -rng:NextNumber(8, 42)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)),
			ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.6)), BASALTE, "Roc")
	end

	-- ===== 6. La paroi de la géode : demi-ellipsoïde de roche qui ferme l'arène (r ≈ 120 à la base, voûte à +130) =====
	local DPHI = math.rad(10)
	for b = 0, 9 do
		local phi = math.rad(-6 + 10 * b)
		local rb = RH * math.cos(phi)
		local n = math.max(8, math.floor(DEUX_PI * rb / 22))
		local rBord = RH * math.cos(math.max(0, math.abs(phi) - DPHI / 2))
		local largeur = DEUX_PI * rBord / n * 1.12
		local hauteur = math.sqrt((RH * math.sin(phi)) ^ 2 + (RV * math.cos(phi)) ^ 2) * DPHI * 1.25
		for j = 0, n - 1 do
			local a = (j + 0.5 + b * 0.37) / n * DEUX_PI
			local pos, nrm = paroi(phi, a)
			local E = 18
			local dedans = -nrm
			local tx = Vector3.new(math.cos(a), 0, math.sin(a))
			local cf = CFrame.fromMatrix(pos + nrm * (E / 2 + rng:NextNumber(0, 1.6)), tx, dedans:Cross(tx), dedans)
				* CFrame.Angles(rng:NextNumber(-0.05, 0.05), rng:NextNumber(-0.05, 0.05), rng:NextNumber(-0.05, 0.05))
			deco(Vector3.new(largeur, hauteur, E), cf, PAROI:Lerp(PAROI_SOMBRE, b / 12 + rng:NextNumber(0, 0.35)), M.Roche, "Geode")
		end
	end
	k.cyl(14, 66, CFrame.new(c) * CFrame.new(0, Y0 + RV + 5, 0), PAROI_SOMBRE, M.Roche, "Geode")
	-- bosses de roche en relief
	for _ = 1, 46 do
		local phi, a = math.rad(rng:NextNumber(-8, 70)), rng:NextNumber(0, DEUX_PI)
		if libre(a, phi) then
			local pos, nrm = paroi(phi, a)
			local t = rng:NextNumber(6, 14)
			deco(Vector3.new(t * 1.3, t, t), CFrame.new(pos - nrm * t * 0.12) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)),
				PAROI:Lerp(PAROI_SOMBRE, rng:NextNumber(0, 0.6)), M.Roche, "Roc")
		end
	end
	-- strates de quartz laiteux au pied de la paroi (le bord de la géode)
	for j = 0, 39 do
		local a = (j + 0.5) / 40 * DEUX_PI
		local pos, nrm = paroi(math.rad(-9), a)
		deco(Vector3.new(DEUX_PI * 120 / 40 + 1, 1.6, 3), CFrame.lookAt(pos - nrm * 0.6, pos - nrm * 2), QUARTZ:Lerp(PAROI, rng:NextNumber(0.2, 0.6)), MARBRE, "Strate")
	end

	-- ===== 7. Cristaux de la paroi : grands prismes inclinés, amas de pointes serrées, cristaux pendants =====
	local function prisme(phi, a, L, w, couleur, opts)
		local pos, nrm = paroi(phi, a)
		local d = -nrm + Vector3.yAxis * (if phi < math.rad(36) then rng:NextNumber(0.4, 1.1) else -rng:NextNumber(0.5, 1.2))
			+ Vector3.new(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3))
		k.cristal(k.dirige(pos + nrm * 2, d) * CFrame.new(0, -L * 0.08, 0), L, w, couleur, opts)
	end
	for j = 0, 39 do
		local a = (j + rng:NextNumber(0.15, 0.85)) / 40 * DEUX_PI
		local phi = math.rad(if j % 2 == 0 then rng:NextNumber(-6, 22) else rng:NextNumber(24, 64))
		if not libre(a, phi) then
			phi = math.rad(rng:NextNumber(26, 48))
		end
		local L = if phi < math.rad(36) then rng:NextNumber(18, 38) else rng:NextNumber(14, 28)
		prisme(phi, a, L, L * rng:NextNumber(0.2, 0.3), CRISTAUX[rng:NextInteger(1, 3)], {coeur = j % 3 == 0, transp = 0.15})
	end
	for j = 0, 57 do
		local a = (j + rng:NextNumber(0, 1)) / 58 * DEUX_PI
		local phi = math.rad(rng:NextNumber(-8, 76))
		if libre(a, phi) then
			local pos, nrm = paroi(phi, a)
			k.amas(pos + nrm, -nrm + Vector3.yAxis * (if phi < math.rad(36) then 0.5 else -0.7), rng:NextNumber(1.2, 2.6), rng:NextInteger(4, 6), CRISTAUX)
		end
	end
	for j = 0, 21 do
		local phi = math.rad(rng:NextNumber(48, 84))
		local a = (j + rng:NextNumber(0.1, 0.9)) / 22 * DEUX_PI
		local pos, nrm = paroi(phi, a)
		local L = rng:NextNumber(14, 32)
		k.cristal(k.dirige(pos + nrm * 2, Vector3.new(rng:NextNumber(-0.25, 0.25), -1, rng:NextNumber(-0.25, 0.25)) - nrm * 0.3), L, L * 0.26, CRISTAUX[rng:NextInteger(1, 3)],
			{coeur = j % 4 == 0, transp = 0.15})
	end
	-- amas posés sur la terrasse, entre les ruines
	for j = 0, 11 do
		local a = (j + rng:NextNumber(0.25, 0.75)) / 12 * DEUX_PI
		k.amas(polaire(a, rng:NextNumber(94, 114), Y_T).Position, Vector3.yAxis, rng:NextNumber(1, 1.8), 4, CRISTAUX, 1.6)
	end
	-- lumières froides dans trois grands amas de la paroi
	for j = 0, 2 do
		local pos, nrm = paroi(math.rad(14), j / 3 * DEUX_PI + math.pi / 3)
		k.lumiere(CFrame.new(pos - nrm * 14), if j == 1 then VIOLET else BLEU, 1.4, 56)
	end

	-- ===== 8. Ruines naines adossées à la paroi =====
	-- (a) Grande porte au nord, traversée de cristaux
	do
		local base = tangent(0, 112, Y_T) -- +Z vers le centre
		for _, s in {-1, 1} do
			deco(Vector3.new(14, 52, 16), base * CFrame.new(s * 15, 26, 0), PIERRE:Lerp(PIERRE_CLAIRE, rng:NextNumber(0.1, 0.4)), MARBRE, "Tour")
			for j = 0, 1 do
				deco(Vector3.new(3.6, 3.4, 3.6), base * CFrame.new(s * (10 + j * 8.5), 53.6, 6.4), PIERRE_CLAIRE, MARBRE, "Merlon")
			end
			deco(Vector3.new(15, 1.2, 17), base * CFrame.new(s * 15, 38, 0), OR, M.Metal, "Cordon")
			k.lueur(deco(Vector3.new(0.6, 9, 0.3), base * CFrame.new(s * 15, 26, 8.1), RUNE, M.Neon, "Rune"), 0.4)
		end
		deco(Vector3.new(18, 8, 14), base * CFrame.new(0, 34, 0), PIERRE_CLAIRE, MARBRE, "Linteau")
		deco(Vector3.new(16, 30, 1), base * CFrame.new(0, 15, -4), NOIR, M.Lisse, "Ombre")
		deco(Vector3.new(11, 4, 0.4), base * CFrame.new(0, 34, 7.2), OR, M.Metal, "Plaque")
		for x = -3, 3, 3 do
			k.lueur(deco(Vector3.new(0.6, 2.8, 0.2), base * CFrame.new(x, 34, 7.45) * CFrame.Angles(0, 0, x * 0.1), RUNE, M.Neon, "Rune"), 0.35)
		end
		for j = 0, 2 do
			local h = 0.8 + j * 0.8
			deco(Vector3.new(20 - j * 2, h, 3), base * CFrame.new(0, h / 2, 9.5 - j * 3), PIERRE_CLAIRE, MARBRE, "Marche")
		end
		k.cristal(base * CFrame.new(-11, 0, 6) * CFrame.Angles(0.25, 0, -0.5), 40, 10, VIOLET, {coeur = true, transp = 0.3})
		k.cristal(base * CFrame.new(12, 0, 4) * CFrame.Angles(0.25, 0, 0.4), 32, 8, BLEU, {transp = 0.3})
		k.amas((base * CFrame.new(0, 54, 2)).Position, Vector3.new(0, 1, 0) + (base.LookVector * -0.6), 2, 5, CRISTAUX)
		k.lumiere(base * CFrame.new(0, 12, 14), FROID, 1, 40)
	end

	-- (b) Quatre rois nains de pierre sur les diagonales (gabarit de ceux de la Fosse), pris par le cristal
	for j = 0, 3 do
		local a = math.pi / 4 + j * math.pi / 2
		deco(Vector3.new(14, 7, 14), face(a, 104, Y_T + 3.5), PIERRE, MARBRE, "Socle")
		deco(Vector3.new(14.6, 0.8, 14.6), face(a, 104, Y_T + 7), OR, M.Metal, "Socle")
		local base = face(a, 104, Y_T + 7.4)
		local teinte = PIERRE_CLAIRE:Lerp(PIERRE, rng:NextNumber(0, 0.3))
		local sombre = teinte:Lerp(ROCHE, 0.5)
		local barbe = teinte:Lerp(QUARTZ, 0.4)
		local function piece(sx, sy, sz, x, y, z, couleur, mat, nom)
			return deco(Vector3.new(sx, sy, sz), base * CFrame.new(x, y, z), couleur or teinte, mat or MARBRE, nom or "Statue")
		end
		for _, s in {-1, 1} do
			piece(4.5, 3, 6.5, s * 3, 1.5, -0.6, sombre)
			piece(4, 6, 4.2, s * 3, 6, 0)
			piece(5, 3.5, 8, s * 7.6, 21, 0)
			piece(5.4, 0.6, 8.4, s * 7.6, 19.4, 0, OR, M.Metal)
			piece(3.6, 6, 3.6, s * 7.4, 16.5, 0)
			piece(3.6, 3.6, 6, s * 5.6, 13.6, -3.6)
			piece(3.8, 3.8, 3.8, s * 2.3, 13.6, -7.4)
			k.lueur(piece(1.3, 0.7, 0.3, s * 1.6, 26.6, -3.85, RUNE, M.Neon, "Oeil"), 0.2)
			piece(2.4, 0.8, 0.8, s * 1.6, 27.6, -3.9, sombre)
			piece(5, 1.8, 1.8, s * 6, 30, -0.3, QUARTZ, M.Calcaire, "Corne")
			piece(1.6, 4, 1.6, s * 8.2, 32.4, -0.3, QUARTZ, M.Calcaire, "Corne")
		end
		piece(11, 4, 7.4, 0, 10.5, 0, sombre)
		piece(12, 1.6, 8, 0, 12.6, 0, sombre:Lerp(Color3.new(), 0.3))
		piece(3, 2.4, 0.5, 0, 12.6, -4.2, OR, M.Metal)
		piece(12, 9, 8, 0, 17.5, 0)
		piece(7, 7, 7, 0, 25.5, -0.3)
		piece(1.6, 2.2, 1.6, 0, 25, -4.4)
		piece(8.4, 9, 2.6, 0, 20.8, -4.6, barbe)
		piece(6, 5, 2.4, 0, 14.6, -5, barbe)
		piece(3, 3, 2, 0, 11, -5.2, barbe)
		piece(3.2, 0.8, 2.9, 0, 15.5, -5, OR, M.Metal)
		piece(8, 3, 8, 0, 29.6, -0.3, sombre)
		piece(8.6, 0.8, 8.6, 0, 28.2, -0.3, OR, M.Metal)
		piece(1.6, 2.6, 7, 0, 32.4, -0.3, OR, M.Metal)
		piece(12, 20, 1, 0, 13, 4.5, sombre)
		-- arme posée tête en bas : marteau ou hache
		piece(1.6, 12, 1.6, 0, 8.5, -8, FER, M.Metal, "Arme")
		piece(2.2, 2.2, 2.2, 0, 15.8, -8, OR, M.Metal, "Arme")
		if j % 2 == 0 then
			piece(9, 5, 5.5, 0, 2.5, -8, FER:Lerp(PIERRE, 0.4), M.Metal, "Arme")
		else
			for _, s in {-1, 1} do
				piece(4, 6, 1, s * 3.2, 3, -8, FER:Lerp(PIERRE, 0.4), M.Metal, "Arme")
			end
		end
		-- le cristal le gagne : un prisme lui traverse l'épaule, des pointes à ses pieds
		local cote = if j % 2 == 0 then -1 else 1
		k.cristal(base * CFrame.new(cote * 6, 12, 3) * CFrame.Angles(-0.25, 0, cote * 0.55), 24, 5.5, CRISTAUX[j % 3 + 1], {transp = 0.3})
		k.amas((base * CFrame.new(-cote * 6, -7, -6)).Position, Vector3.yAxis, 1.4, 4, CRISTAUX, 1.4)
	end

	-- (c) Tête colossale d'un roi nain à demi enfouie au sud, cristaux jaillissant de sa couronne
	do
		local base = face(math.pi, 108, Y_T) -- -Z vers le centre
		local teinte = PIERRE_CLAIRE
		local sombre = PIERRE:Lerp(ROCHE, 0.4)
		deco(Vector3.new(30, 26, 28), base * CFrame.new(0, 9, 0), teinte, MARBRE, "Tete")
		deco(Vector3.new(32, 5, 30), base * CFrame.new(0, 21, 0), sombre, MARBRE, "Casque")
		deco(Vector3.new(33, 1, 31), base * CFrame.new(0, 19, 0), OR, M.Metal, "Casque")
		deco(Vector3.new(4, 9, 4), base * CFrame.new(0, 11, -15), teinte, MARBRE, "Nez")
		deco(Vector3.new(22, 3, 3), base * CFrame.new(0, 17.5, -14.6), sombre, MARBRE, "Sourcils")
		for _, s in {-1, 1} do
			k.lueur(deco(Vector3.new(4, 2, 0.6), base * CFrame.new(s * 6.5, 14.5, -14.2), RUNE, M.Neon, "Oeil"), 0.3)
			deco(Vector3.new(10, 3.5, 3.5), base * CFrame.new(s * 19, 22, 0) * CFrame.Angles(0, 0, s * 0.4), QUARTZ, M.Calcaire, "Corne")
			deco(Vector3.new(3, 9, 3), base * CFrame.new(s * 24.5, 27, 0) * CFrame.Angles(0, 0, s * 0.2), QUARTZ, M.Calcaire, "Corne")
		end
		deco(Vector3.new(26, 12, 6), base * CFrame.new(0, 1, -15), teinte:Lerp(QUARTZ, 0.3), MARBRE, "Barbe")
		for x = -9, 9, 6 do
			deco(Vector3.new(4.5, 8, 4), base * CFrame.new(x, -1, -16.5), teinte:Lerp(QUARTZ, 0.3), MARBRE, "Barbe")
		end
		k.grappe(base * CFrame.new(0, 23, 2), 4, 4, CRISTAUX, {coeur = true})
		k.amas((base * CFrame.new(-16, 0, -10)).Position, Vector3.yAxis, 1.8, 5, CRISTAUX, 1.5)
		k.amas((base * CFrame.new(15, 0, -9)).Position, Vector3.yAxis, 1.4, 4, CRISTAUX, 1.5)
	end

	-- (d) À l'est : escalier taillé le long de la paroi, balcon et porte haute ; marteau de guerre tombé au pied
	do
		local NM = 14
		for j = 0, NM - 1 do
			local h = 2 + j * 2
			deco(Vector3.new(3.4, h, 8), tangent(math.pi / 2 - 0.2 + j * 0.026, 113, Y_T + h / 2), PIERRE:Lerp(PIERRE_CLAIRE, 0.25 + (j % 2) * 0.2), M.Ardoise, "Marche")
		end
		local balcon = tangent(math.pi / 2 + 0.225, 113, Y_T + 28) -- dessus du balcon
		deco(Vector3.new(16, 2, 12), balcon * CFrame.new(0, -1, 0), PIERRE_CLAIRE, MARBRE, "Balcon")
		deco(Vector3.new(16.4, 0.6, 12.4), balcon * CFrame.new(0, -2.2, 0), OR, M.Metal, "Balcon")
		for _, s in {-1, 1} do
			deco(Vector3.new(3, 26, 3), balcon * CFrame.new(s * 6, -15, 4), PIERRE, MARBRE, "Pilier")
			deco(Vector3.new(0.8, 2.6, 0.8), balcon * CFrame.new(s * 7.4, 1.3, 5.4), PIERRE_CLAIRE, MARBRE, "Balustre")
			k.cyl(15, 2.4, balcon * CFrame.new(s * 5, 7.5, -3.5), PIERRE:Lerp(PIERRE_CLAIRE, 0.4), M.Pierre, "Pilier")
			deco(Vector3.new(2.6, 2, 2.6), balcon * CFrame.new(s * 3.6, 15.6, -3.5), PIERRE_CLAIRE, MARBRE, "Arc")
		end
		deco(Vector3.new(16, 0.8, 0.8), balcon * CFrame.new(0, 2.6, 5.4), PIERRE_CLAIRE, MARBRE, "Rampe")
		deco(Vector3.new(13, 2.6, 3), balcon * CFrame.new(0, 17.4, -3.5), PIERRE_CLAIRE, MARBRE, "Linteau")
		deco(Vector3.new(8, 14, 0.4), balcon * CFrame.new(0, 7, -5.6), NOIR, M.Lisse, "Ombre")
		k.lueur(deco(Vector3.new(1.4, 1.4, 0.3), balcon * CFrame.new(0, 17.4, -1.9) * CFrame.Angles(0, 0, math.pi / 4), RUNE, M.Neon, "Rune"), 0.35)
		-- marteau de guerre couché sur la terrasse, tête prise dans le cristal
		local pied = tangent(math.pi / 2 + 0.05, 99, Y_T)
		local manche = pied * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.12)
		deco(Vector3.new(3, 40, 3), manche, FER, M.Metal, "Manche")
		deco(Vector3.new(3.8, 2.6, 3.8), manche * CFrame.new(0, -17, 0), OR, M.Metal, "Bague")
		local tete = manche * CFrame.new(0, 21, 0)
		deco(Vector3.new(9, 9, 16), tete, FER:Lerp(PIERRE, 0.3), M.Metal, "TeteMarteau")
		for _, s in {-1, 1} do
			deco(Vector3.new(9.6, 9.6, 0.8), tete * CFrame.new(0, 0, s * 8.2), OR, M.Metal, "TeteMarteau")
		end
		k.amas(tete.Position, Vector3.yAxis, 1.8, 5, CRISTAUX, 1.4)
	end

	-- (e) À l'ouest : porte secondaire entre deux gardiens nains agenouillés, pris dans des blocs de cristal
	do
		local base = tangent(3 * math.pi / 2, 115, Y_T)
		for _, s in {-1, 1} do
			deco(Vector3.new(5, 30, 6), base * CFrame.new(s * 8, 15, 0), PIERRE:Lerp(PIERRE_CLAIRE, 0.3), MARBRE, "Jambage")
			deco(Vector3.new(4, 3, 6), base * CFrame.new(s * 4.5, 27, 0), PIERRE_CLAIRE, MARBRE, "Arc")
		end
		deco(Vector3.new(22, 4, 7), base * CFrame.new(0, 31, 0), PIERRE_CLAIRE, MARBRE, "Linteau")
		deco(Vector3.new(11, 25, 0.4), base * CFrame.new(0, 12.5, -2.8), NOIR, M.Lisse, "Ombre")
		k.lueur(deco(Vector3.new(2, 2, 0.3), base * CFrame.new(0, 31, 3.6) * CFrame.Angles(0, 0, math.pi / 4), RUNE, M.Neon, "Rune"), 0.35)
	end
	for _, s in {-1, 1} do
		local base = face(3 * math.pi / 2 + s * 0.18, 104, Y_T)
		local teinte = PIERRE_CLAIRE:Lerp(PIERRE, 0.3)
		deco(Vector3.new(10, 3, 10), base * CFrame.new(0, 1.5, 0), PIERRE, MARBRE, "Socle")
		deco(Vector3.new(8, 4, 7), base * CFrame.new(0, 5, 0.5), teinte:Lerp(ROCHE, 0.4), MARBRE, "Gardien")
		deco(Vector3.new(8.4, 8, 6), base * CFrame.new(0, 11, 0), teinte, MARBRE, "Gardien")
		deco(Vector3.new(5.4, 5.4, 5.4), base * CFrame.new(0, 17.5, -0.4), teinte, MARBRE, "Gardien")
		deco(Vector3.new(6, 7, 2), base * CFrame.new(0, 12.5, -3.4), QUARTZ, MARBRE, "Barbe")
		deco(Vector3.new(6, 2.4, 6), base * CFrame.new(0, 21, -0.4), FER, M.Metal, "Casque")
		deco(Vector3.new(1.4, 16, 1.4), base * CFrame.new(3.8, 9, -4), FER, M.Metal, "Hache")
		deco(Vector3.new(1, 6, 4), base * CFrame.new(3.8, 15, -6), FER:Lerp(PIERRE, 0.3), M.Metal, "Hache")
		local bloc = deco(Vector3.new(15, 26, 14), base * CFrame.new(0, 12, 0) * CFrame.Angles(0, 0.3, s * 0.06), GLACE:Lerp(VIOLET, 0.35), M.Verre, "Gangue")
		bloc.Transparency = 0.6
		k.amas((base * CFrame.new(-6, 0, -5)).Position, Vector3.yAxis, 1.5, 4, CRISTAUX, 1.3)
	end

	-- (f) Arcades sombres creusées au pied de la paroi, entre les grandes ruines (certaines effondrées)
	for j = 0, 7 do
		local base = tangent(math.pi / 8 + j * math.pi / 4, 116, Y_T)
		local casse = j % 3 == 1
		for _, s in {-1, 1} do
			local h = if casse and s == 1 then rng:NextNumber(6, 10) else 17
			deco(Vector3.new(3.4, 1.4, 3.4), base * CFrame.new(s * 6, 0.7, 0), PIERRE_CLAIRE, MARBRE, "BasePilier")
			k.cyl(h, 2.6, base * CFrame.new(s * 6, 1.4 + h / 2, 0), PIERRE:Lerp(PIERRE_CLAIRE, 0.4), M.Pierre, "Pilier")
			if not (casse and s == 1) then
				deco(Vector3.new(3.6, 1.4, 3.6), base * CFrame.new(s * 6, 19, 0), PIERRE_CLAIRE, MARBRE, "Chapiteau")
				deco(Vector3.new(3, 2, 3), base * CFrame.new(s * 4, 20.6, 0), PIERRE_CLAIRE, MARBRE, "Arc")
			end
		end
		deco(Vector3.new(9, 18, 0.4), base * CFrame.new(0, 10, -2.6), NOIR, M.Lisse, "Ombre")
		if casse then
			k.eboulis(base * CFrame.new(4, 0, 4), 4, 2, PIERRE, PIERRE_CLAIRE, M.Pierre)
			k.cristal(base * CFrame.new(1, 0, 2) * CFrame.Angles(0.3, 0, -0.35), 26, 6.5, CRISTAUX[j % 3 + 1], {coeur = true, transp = 0.25})
		else
			deco(Vector3.new(16, 3, 3.6), base * CFrame.new(0, 23, 0), PIERRE_CLAIRE, MARBRE, "Linteau")
			k.lueur(deco(Vector3.new(1.4, 1.4, 0.3), base * CFrame.new(0, 23, 1.9) * CFrame.Angles(0, 0, math.pi / 4), RUNE, M.Neon, "Rune"), 0.35)
		end
	end

	-- ===== 9. Lustre de cristal pendu à la voûte au-dessus du centre (lumière principale du combat) =====
	local haut = Y0 + RV
	for j, e in {{haut - 6, 30, 16}, {haut - 18, 20, 14}, {haut - 29, 12, 12}} do
		deco(Vector3.new(e[2], e[3], e[2]), CFrame.new(c) * CFrame.new(0, e[1], 0) * CFrame.Angles(0, j * 0.5, 0), PAROI_SOMBRE, M.Roche, "Stalactite")
	end
	local attache = CFrame.new(c) * CFrame.new(0, haut - 34, 0) * CFrame.Angles(math.pi, 0, 0)
	k.cristal(attache, 36, 10, VIOLET, {coeur = true, transp = 0.15})
	for j = 0, 5 do
		local L = rng:NextNumber(14, 22)
		k.cristal(attache * CFrame.Angles(0, j * math.pi / 3, 0) * CFrame.new(0, 0, -5) * CFrame.Angles(-0.45, 0, 0), L, L * 0.26, CRISTAUX[j % 3 + 1], {coeur = j % 2 == 0})
	end
	k.lumiere(CFrame.new(c) * CFrame.new(0, 50, 0), FROID, 1.6, 60)

	-- ===== 10. Atmosphère : poussière de cristal en suspension, brume froide au ras du sol =====
	local air = k.invisible(Vector3.new(130, 30, 130), CFrame.new(c) * CFrame.new(0, 16, 0), "Poussiere")
	local poussiere = O.lucioles(air, GLACE, 6)
	poussiere.LightEmission = 0.5
	poussiere.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 0)})
	local nappe = k.invisible(Vector3.new(140, 1, 140), CFrame.new(c) * CFrame.new(0, 1, 0), "Brume")
	O.brume(nappe, Color3.fromRGB(120, 130, 172), 2)
end
