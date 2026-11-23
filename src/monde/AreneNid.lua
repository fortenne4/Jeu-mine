-- Arène de la Reine araignée (ServerStorage › Monde › AreneNid) : « Le Nid de la Reine ».
-- Une ancienne salle de mine circulaire envahie par la reine. Sol de terre battue texturé (gravier, boue, roche,
-- fissures, débris, planches cassées, ossements, squelettes de mineurs), rails rouillés qui se croisent sur une plaque
-- tournante. Autour, comme le colisée de la Fosse, une GALERIE DE MINE CIRCULAIRE massive : deux anneaux d'étais
-- épais (r 84 et 104), chapeaux, jambes de force, solives et plafond de planches, voie ferrée circulaire, wagonnets ;
-- derrière, la paroi de roche (r 110) percée de quatre galeries, et la voûte en dôme qui monte vers l'antre.
-- Les toiles sont de VRAIS fils 3D (AreneKit.toile3D / nappe / filCourbe) : toiles tendues entre les étais, le sol et
-- les poutres (moyeu décalé vers le centre), nappes en hamac dans la galerie, entonnoirs qui s'enfoncent dans les
-- galeries nord et sud, grande toile en entonnoir (rayons + spirale) sous la voûte, fils tendus vers le dôme.
-- Couvées d'œufs en grappes, cocons de tailles variées (certains en forme de mineur, tête en bas, casque et bottes),
-- sac d'œufs luminescent au-dessus du centre, brume basse verdâtre.
-- Appelé par AreneBoss.construire("ReineAraignee") (≈ 2 700 pièces ancrées, 10 lumières).
-- Gameplay : sol plat à c.Y sur tout le rayon R (une seule pièce solide), tout le reste est décor sans collision ;
-- au-dessus du cercle de combat, les cocons restent hauts (bas des cocons ≥ 30 studs) pour ne pas gêner la caméra.
local O = require(script.Parent.Outils)
local Kit = require(script.Parent.AreneKit)
local M = O.M

-- Palette terreuse et froide ; toiles gris pâle ; lueurs vert pâle (jamais rouges au sol)
local TERRE = Color3.fromRGB(72, 62, 54)
local TERRE_SOMBRE = Color3.fromRGB(48, 42, 38)
local BOUE = Color3.fromRGB(38, 34, 30)
local FISSURE = Color3.fromRGB(24, 20, 18)
local ROCHE = Color3.fromRGB(66, 62, 64)
local ROCHE_SOMBRE = Color3.fromRGB(34, 32, 36)
local BOIS = Color3.fromRGB(100, 74, 50)
local BOIS_SOMBRE = Color3.fromRGB(60, 44, 32)
local TOILE = Color3.fromRGB(206, 210, 200)
local TOILE_VIEILLE = Color3.fromRGB(168, 172, 160)
local OS = Color3.fromRGB(198, 188, 164)
local OEUF = Color3.fromRGB(172, 188, 148)
local LUEUR = Color3.fromRGB(150, 226, 120)
local VIOLET = Color3.fromRGB(150, 110, 200)
local FER = Color3.fromRGB(66, 64, 68)
local ROUILLE = Color3.fromRGB(112, 72, 50)
local NOIR = Color3.fromRGB(8, 8, 10)
local LANTERNE = Color3.fromRGB(255, 184, 110)
local CASQUE = Color3.fromRGB(122, 100, 58) -- casque de mineur terni
local LAMPE = Color3.fromRGB(196, 182, 128)
local CUIR = Color3.fromRGB(62, 46, 36)

return function(m: Model, c: Vector3, R: number)
	local rng = Random.new(8283)
	local k = Kit.nouveau(m, c, rng)
	local DEUX_PI = Kit.DEUX_PI
	local deco, incruster, polaire, tangent = k.deco, k.incruster, k.polaire, k.tangent
	local RI, RO, RW = 84, 104, 110 -- étais intérieurs, étais extérieurs (galerie circulaire), paroi de roche
	local HG = 33 -- dessous des chapeaux de la galerie
	local H = 66 -- voûte au-dessus de l'antre
	local NE = 16 -- étais par anneau
	local RR = 94 -- voie ferrée circulaire
	local GALERIES = {0, math.pi / 2, math.pi, 3 * math.pi / 2}
	local function ecartGalerie(a: number): number
		local mini = math.huge
		for _, g in GALERIES do
			mini = math.min(mini, math.abs((a - g + math.pi) % DEUX_PI - math.pi))
		end
		return mini
	end
	local function v(a: number, r: number, y: number): Vector3
		return polaire(a, r, y).Position
	end
	local function angleEtai(j: number): number
		return (j + 0.5) / NE * DEUX_PI
	end
	local function ranger(liste: {BasePart}, parent: Instance)
		for _, p in liste do p.Parent = parent end
	end
	-- Grande toile en entonnoir sous la voûte : hauteur au rayon r (bord sur les chapeaux, fond vers l'antre)
	local function yToile(r: number): number
		return HG + 1 + (H - 3 - HG - 1) * math.clamp((RI - r) / (RI - 12), 0, 1) ^ 1.6
	end
	-- Dessous du dôme de roche (de la paroi à +38 jusqu'à l'antre)
	local R0, YV0, R1, YV1 = RW + 6, 38, 62, H + 2
	local function yVoute(r: number): number
		return math.min(H, YV0 + (R0 - r) * (YV1 - YV0) / (R0 - R1))
	end

	-- ===== 1. Sol de terre battue (seule pièce solide) : plaques, boue, gravier, fissures, soie, débris =====
	O.cylindre(m, 8, (RW + 16) * 2, CFrame.new(c) * CFrame.new(0, -4, 0), TERRE, M.Terre, "Sol")
	for _ = 1, 66 do
		local a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(8, RW - 2)
		local tirage = rng:NextNumber()
		local couleur, mat
		if tirage < 0.28 then
			couleur, mat = ROCHE:Lerp(TERRE, rng:NextNumber(0, 0.4)), M.Gravier
		elseif tirage < 0.46 then
			couleur, mat = BOUE, M.Terre
		elseif tirage < 0.6 then
			couleur, mat = ROCHE_SOMBRE:Lerp(ROCHE, rng:NextNumber()), M.Roche
		else
			couleur, mat = TERRE_SOMBRE:Lerp(TERRE, rng:NextNumber(0, 0.6)), M.Terre
		end
		incruster(rng:NextNumber(5, 15), rng:NextNumber(4, 11), polaire(a, r, -rng:NextNumber(0.005, 0.03)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), couleur, mat, "Plaque", 0.06)
	end
	for j = 0, 13 do
		k.veine((j + rng:NextNumber(0.1, 0.9)) / 14 * DEUX_PI, rng:NextNumber(12, 90), rng:NextInteger(4, 8), rng:NextNumber(0.3, 0.55), FISSURE, M.Terre, 8, RW - 4)
	end
	for _ = 1, 9 do -- voiles de soie collés au sol
		local cf = polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(20, 66), 0.006) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		for i = 1, 2 do
			incruster(rng:NextNumber(4, 8), rng:NextNumber(3, 6), cf * CFrame.Angles(0, i * 0.9, 0) * CFrame.new(0, i * 0.002, 0), TOILE_VIEILLE, M.Lisse, "Soie", 0.02).Transparency = 0.7
		end
	end
	for _ = 1, 12 do
		k.eboulis(polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(72, RW - 4)), rng:NextInteger(2, 4), rng:NextNumber(0.8, 1.8), ROCHE, ROCHE_SOMBRE, M.Roche)
	end
	for _ = 1, 10 do -- planches cassées
		deco(Vector3.new(1.4, 0.3, rng:NextNumber(3, 7)), polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(60, RW - 6), 0.15)
			* CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(0, 3), rng:NextNumber(-0.06, 0.06)), BOIS_SOMBRE:Lerp(BOIS, rng:NextNumber()), M.Planches, "Planche")
	end

	-- ===== 2. Rails rouillés N-S et E-O (jusque dans les galeries), plaque tournante au centre =====
	k.cyl(0.1, 11, CFrame.new(c) * CFrame.new(0, -0.03, 0), BOIS_SOMBRE, M.Planches, "PlaqueTournante")
	k.cercle(5.6, 0.5, 20, FER, M.Rouille, "Cerclage")
	for _, g in {0, math.pi / 2} do
		local axe = CFrame.new(c) * CFrame.Angles(0, -g, 0) -- -Z = direction de la voie
		for z = -RW - 44, RW + 44, 4 do
			if math.abs(z) > 6.5 and rng:NextNumber() > 0.15 then
				incruster(5.4, 1.1, axe * CFrame.new(0, 0, z) * CFrame.Angles(0, rng:NextNumber(-0.08, 0.08), 0), BOIS_SOMBRE:Lerp(BOIS, rng:NextNumber(0, 0.5)), M.Planches, "Traverse", 0.08)
			end
		end
		for _, x in {-1.8, 1.8} do
			for z = -RW - 44, RW + 44 - 15, 15 do
				if rng:NextNumber() > 0.08 and math.abs(z + 7.5) > 12 then
					local p = incruster(0.4, 15, axe * CFrame.new(x, 0, z + 7.5), ROUILLE:Lerp(FER, rng:NextNumber(0, 0.5)), M.Rouille, "Rail", 0.1)
					p.CFrame *= CFrame.new(0, 0.015, 0)
				end
			end
		end
	end
	-- voie ferrée circulaire dans la galerie
	for j = 0, 89 do
		local a = (j + 0.5) / 90 * DEUX_PI
		if rng:NextNumber() > 0.12 and ecartGalerie(a) > 0.05 then
			incruster(1.1, 5.4, tangent(a, RR) * CFrame.Angles(0, rng:NextNumber(-0.08, 0.08), 0), BOIS_SOMBRE:Lerp(BOIS, rng:NextNumber(0, 0.5)), M.Planches, "Traverse", 0.08)
		end
	end
	for _, dr in {-1.8, 1.8} do
		for j = 0, 43 do
			if rng:NextNumber() > 0.08 then
				local p = incruster(DEUX_PI * (RR + dr) / 44 * 1.02, 0.4, tangent((j + 0.5) / 44 * DEUX_PI, RR + dr), ROUILLE:Lerp(FER, rng:NextNumber(0, 0.5)), M.Rouille, "Rail", 0.1)
				p.CFrame *= CFrame.new(0, 0.015, 0)
			end
		end
	end

	-- ===== 3. La galerie circulaire : deux anneaux d'étais épais, chapeaux, jambes de force, solives, plafond =====
	for j = 0, NE - 1 do
		local a = angleEtai(j)
		for _, rr in {RI, RO} do
			local pied = tangent(a, rr) -- +Z vers le centre
			local penche = CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.04, 0.04))
			deco(Vector3.new(4.8, 1.4, 4.8), pied * CFrame.new(0, 0.7, 0), ROCHE, M.Pierre, "Cale")
			deco(Vector3.new(3.6, HG, 3.6), pied * penche * CFrame.new(0, HG / 2, 0), BOIS:Lerp(BOIS_SOMBRE, rng:NextNumber(0, 0.6)), M.Bois, "Etai")
			deco(Vector3.new(5, 1.6, 5), pied * CFrame.new(0, HG - 0.6, 0), BOIS_SOMBRE, M.Bois, "Sabot")
			if rr == RI then
				for _, s in {-1, 1} do -- jambes de force vers les chapeaux
					deco(Vector3.new(1.8, 11, 1.8), pied * CFrame.new(s * 3.6, HG - 4.5, 0) * CFrame.Angles(0, 0, -s * 0.75), BOIS_SOMBRE, M.Bois, "Jambe")
				end
			end
		end
		deco(Vector3.new(2.8, 3, RO - RI + 6), tangent(a, (RI + RO) / 2, HG + 3.4), BOIS:Lerp(BOIS_SOMBRE, rng:NextNumber(0.2, 0.6)), M.Bois, "Solive")
		-- chapeaux entre cet étai et le suivant
		local am = (j + 1) / NE * DEUX_PI
		for _, rr in {RI, RO} do
			local corde = 2 * rr * math.sin(math.pi / NE)
			local milieu = tangent(am, rr * math.cos(math.pi / NE))
			if rr == RI and j == 9 then -- chapeau cassé, qui pend d'un côté
				deco(Vector3.new(corde * 0.7, 2.8, 3), milieu * CFrame.new(-corde * 0.2, HG - 5, 0) * CFrame.Angles(0, 0, 0.45), BOIS_SOMBRE, M.Bois, "Chapeau")
			else
				deco(Vector3.new(corde + 3, 3, 3.2), milieu * CFrame.new(0, HG + 1.5, 0), BOIS:Lerp(BOIS_SOMBRE, rng:NextNumber(0.1, 0.6)), M.Bois, "Chapeau")
			end
		end
		if rng:NextNumber() > 0.18 then
			deco(Vector3.new(2 * (RI + RO) / 2 * math.sin(math.pi / NE) + 3, 1.2, RO - RI + 4), tangent(am, (RI + RO) / 2, HG + 5.4), BOIS_SOMBRE:Lerp(BOIS, rng:NextNumber(0, 0.3)), M.Planches, "Plafond")
		end
		if j % 4 == 1 then -- lanterne de mineur sur la face intérieure de l'étai
			local l = tangent(a, RI) * CFrame.new(0, 15, 2.6)
			deco(Vector3.new(0.3, 1.6, 0.3), l * CFrame.new(0, 1.4, 0), FER, M.Metal, "Crochet")
			deco(Vector3.new(1.4, 1.8, 1.4), l, FER, M.Metal, "Lanterne").Transparency = 0.5
			deco(Vector3.new(0.6, 0.9, 0.6), l, LANTERNE, M.Neon, "Flamme")
			k.lumiere(l * CFrame.new(0, 0, 1), LANTERNE, 1.2, 40)
		end
	end

	-- ===== 4. Paroi de roche (r 110), dôme qui monte vers l'antre, stalactites =====
	for j = 0, 39 do
		local a = (j + 0.5) / 40 * DEUX_PI
		if ecartGalerie(a) > 0.09 then
			deco(Vector3.new(DEUX_PI * (RW + 9) / 40 + 2, 46, 18), tangent(a, RW + 9, 21), ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.6)), M.Roche, "Paroi")
		end
	end
	for _ = 1, 30 do
		local a = rng:NextNumber(0, DEUX_PI)
		if ecartGalerie(a) > 0.12 then
			local t = rng:NextNumber(5, 12)
			deco(Vector3.new(t * 1.3, t, t), polaire(a, RW - 1, rng:NextNumber(-1, 34)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)),
				ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.7)), M.Roche, "Roc")
		end
	end
	local pente = math.atan2(YV1 - YV0, R0 - R1)
	local longueur = math.sqrt((R0 - R1) ^ 2 + (YV1 - YV0) ^ 2) + 6
	for j = 0, 23 do
		local a = (j + 0.5) / 24 * DEUX_PI
		deco(Vector3.new(DEUX_PI * R0 / 24 * 1.08, 10, longueur), tangent(a, (R0 + R1) / 2, (YV0 + YV1) / 2) * CFrame.Angles(-pente, 0, 0) * CFrame.new(0, 5, 0),
			ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0.2, 0.7)), M.Roche, "Voute")
	end
	k.cyl(16, 2 * 72, CFrame.new(c) * CFrame.new(0, H + 8, 0), ROCHE_SOMBRE, M.Roche, "Voute")
	for _ = 1, 26 do
		local a, r = rng:NextNumber(0, DEUX_PI), rng:NextNumber(24, 104)
		local y = yVoute(r)
		local l = rng:NextNumber(8, if r < 75 then 14 else 22)
		local w = l * 0.3
		local p = polaire(a, r, y) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		local couleur = ROCHE:Lerp(ROCHE_SOMBRE, rng:NextNumber(0, 0.6))
		deco(Vector3.new(w, l * 0.6, w), p * CFrame.new(0, -l * 0.25, 0), couleur, M.Roche, "Stalactite")
		deco(Vector3.new(w * 0.5, l * 0.45, w * 0.5), p * CFrame.new(0, -l * 0.75, 0) * CFrame.Angles(0, 0.5, 0), couleur, M.Roche, "Stalactite")
	end
	k.cyl(0.4, 30, CFrame.new(c) * CFrame.new(0, H - 0.3, 0), NOIR, M.Lisse, "Antre")
	for j = 0, 9 do
		deco(Vector3.new(9, 5, 6), tangent(j / 10 * DEUX_PI, 16, H - 1.5) * CFrame.Angles(0.3, 0, 0), ROCHE_SOMBRE, M.Roche, "Bord")
	end

	-- ===== 5. Quatre galeries dans la paroi : nord et sud murées par des entonnoirs de toile, est et ouest éclairées
	-- par une chambre à œufs au fond =====
	local function couvee(cf: CFrame, n: number, echelle: number, lumiere: boolean)
		k.cyl(0.1, 5 * echelle, cf * CFrame.new(0, -0.01, 0), TOILE_VIEILLE, M.Lisse, "Couvee").Transparency = 0.45
		for j = 1, n do
			local a = j / n * DEUX_PI + rng:NextNumber(-0.3, 0.3)
			local dessus = j > math.ceil(n * 0.7) -- dernière rangée posée sur les autres
			local d = if dessus then rng:NextNumber(0, 0.7) * echelle elseif j == 1 then 0 else rng:NextNumber(0.9, 1.8) * echelle
			local t = echelle * rng:NextNumber(0.8, 1.2)
			local pos = cf * CFrame.new(math.cos(a) * d, (if dessus then 3 else 1.15) * t, math.sin(a) * d) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3))
			k.boule(Vector3.new(1.8, 2.5, 1.8) * t, pos, OEUF:Lerp(TOILE_VIEILLE, rng:NextNumber(0, 0.3)), M.Lisse, "Oeuf").Transparency = 0.25
			if j % 2 == 1 then
				k.lueur(k.boule(Vector3.new(0.9, 1.4, 0.9) * t, pos, LUEUR, M.Neon, "Lueur"), 0.45)
			end
		end
		for _ = 1, 3 do -- fils de soie qui retiennent la couvée
			local a = rng:NextNumber(0, DEUX_PI)
			k.fil((cf * CFrame.new(math.cos(a) * 2.4 * echelle, 0.1, math.sin(a) * 2.4 * echelle)).Position,
				(cf * CFrame.new(-math.cos(a) * 0.5, 3.6 * echelle, -math.sin(a) * 0.5)).Position, 0.15, TOILE, M.Lisse, "Toile")
		end
		if lumiere then
			k.lumiere(cf * CFrame.new(0, 3 * echelle, 0), LUEUR, 1.1, 40)
		end
	end
	for gi, g in GALERIES do
		local base = tangent(g, RW + 2) -- +Z vers le centre, la galerie part vers -Z
		for _, s in {-1, 1} do
			deco(Vector3.new(10, 46, 20), base * CFrame.new(s * 15, 21, -8), ROCHE:Lerp(ROCHE_SOMBRE, 0.3), M.Roche, "Paroi")
			deco(Vector3.new(2, 18, 50), base * CFrame.new(s * 9, 9, -30), ROCHE_SOMBRE, M.Roche, "Galerie")
		end
		deco(Vector3.new(20, 2, 50), base * CFrame.new(0, 19, -30), ROCHE_SOMBRE, M.Roche, "Galerie")
		deco(Vector3.new(20, 2, 50), base * CFrame.new(0, -1.05, -30), TERRE_SOMBRE, M.Terre, "Galerie")
		deco(Vector3.new(20, 26, 20), base * CFrame.new(0, 31, -8), ROCHE:Lerp(ROCHE_SOMBRE, 0.4), M.Roche, "Paroi")
		deco(Vector3.new(18, 18, 1), base * CFrame.new(0, 9, -54), NOIR, M.Lisse, "Fond")
		for z = 0, 2 do
			local cadre = base * CFrame.new(0, 0, -z * 16)
			for _, s in {-1, 1} do
				deco(Vector3.new(2.2, 16, 2.2), cadre * CFrame.new(s * 7, 8, 0), BOIS:Lerp(BOIS_SOMBRE, z * 0.3), M.Bois, "Cadre")
			end
			deco(Vector3.new(16.5, 2.2, 2.4), cadre * CFrame.new(0, 16.4, 0) * CFrame.Angles(0, 0, if z == 1 then 0.08 else 0), BOIS:Lerp(BOIS_SOMBRE, z * 0.3), M.Bois, "Cadre")
		end
		if gi % 2 == 1 then -- nord et sud : entonnoir de toile qui s'enfonce dans la galerie
			local bouche = {}
			for i = 0, 9 do
				local t = i / 10 * DEUX_PI
				table.insert(bouche, (base * CFrame.new(math.cos(t) * 5.8, 8 + math.sin(t) * 7.4, 1)).Position)
			end
			k.toile3D((base * CFrame.new(0, 8, -32)).Position, bouche, 5, TOILE, 0, 0.2)
		else -- est et ouest : chambre à œufs au fond, lueur verte
			couvee(base * CFrame.new(0, 0, -40), 7, 1.3, false)
			k.lumiere(base * CFrame.new(0, 7, -34), LUEUR, 1.2, 34)
		end
	end

	-- ===== 6. Les toiles : vrais fils 3D tendus entre étais, poutres, sol et voûte =====
	local function surEtai(j: number, y: number, r: number?): Vector3
		return v(angleEtai(j), (r or RI) - 1.9, y)
	end
	local function surChapeau(j: number, t: number): Vector3
		return v(angleEtai(j), RI, HG):Lerp(v(angleEtai(j + 1), RI, HG), t)
	end
	-- (a) toiles des travées : moyeu avancé vers le centre, ancrées au sol, aux deux étais, au chapeau et au fond de la galerie
	for j = 0, NE - 1 do
		local am = (j + 1) / NE * DEUX_PI
		if j % 4 == 0 or j % 4 == 2 then
			local centre = v(am + rng:NextNumber(-0.03, 0.03), RI - rng:NextNumber(4, 10), rng:NextNumber(12, 19))
			k.toile3D(centre, {
				v(angleEtai(j) + 0.03, RI - rng:NextNumber(6, 12), 0.1),
				surEtai(j, rng:NextNumber(4, 9)),
				surEtai(j, rng:NextNumber(17, 26)),
				surChapeau(j, rng:NextNumber(0.25, 0.4)),
				surChapeau(j, rng:NextNumber(0.6, 0.75)),
				surEtai(j + 1, rng:NextNumber(20, 28)),
				surEtai(j + 1, rng:NextNumber(10, 15), RO), -- au fond de la galerie : la toile traverse en biais
				surEtai(j + 1, rng:NextNumber(4, 8)),
				v(angleEtai(j + 1) - 0.03, RI - rng:NextNumber(6, 12), 0.1),
			}, if j % 4 == 0 then 5 else 4, TOILE, 0, 0.2)
		elseif j % 4 == 1 then -- toile déchirée : moitié de toile, fils qui pendent
			local centre = v(am, RI - rng:NextNumber(2, 5), rng:NextNumber(18, 24))
			k.toile3D(centre, {surEtai(j, rng:NextNumber(8, 14)), surEtai(j, 28), surChapeau(j, 0.5), surEtai(j + 1, 26)}, 4, TOILE_VIEILLE, 0, 0.18, true)
			for s = -1, 1 do
				local haut = surChapeau(j, 0.5 + s * 0.2)
				k.fil(haut, haut + Vector3.new(rng:NextNumber(-1.5, 1.5), -rng:NextNumber(8, 20), rng:NextNumber(-1.5, 1.5)), 0.2, TOILE_VIEILLE, M.Lisse, "Toile")
			end
		end
	end
	-- (b) nappes en hamac dans la galerie (entre étais intérieurs et extérieurs), visibles à travers les toiles
	for _, j in {0, 2, 5, 8, 10, 13} do
		k.nappe(surEtai(j, rng:NextNumber(9, 12), RI + 3.8), surEtai(j + 1, rng:NextNumber(9, 12), RI + 3.8),
			surEtai(j, rng:NextNumber(13, 17), RO), surEtai(j + 1, rng:NextNumber(13, 17), RO), 4, rng:NextNumber(1.5, 3), TOILE_VIEILLE, 0, 0.15)
	end
	-- (c) grande toile en entonnoir sous la voûte : rayons qui suivent la pente + spirale continue
	local NR = 16
	local anglesToile = {}
	for j = 1, NR do
		anglesToile[j] = (j - 1 + rng:NextNumber(-0.2, 0.2)) / NR * DEUX_PI
	end
	local function pointToile(j: number, r: number): Vector3
		local a = anglesToile[(j - 1) % NR + 1]
		return c + Vector3.new(math.sin(a) * r, yToile(r), -math.cos(a) * r)
	end
	local PALIERS = {12, 24, 38, 54, 70, RI * math.cos(math.pi / NE) - 0.5}
	for j = 1, NR do
		for i = 1, #PALIERS - 1 do
			k.fil(pointToile(j, PALIERS[i]), pointToile(j, PALIERS[i + 1]), 0.32, TOILE, M.Lisse, "Toile")
		end
	end
	do
		local r, s = 15, 0
		while r < 80 do
			local r2 = r + 9 / NR * rng:NextNumber(0.85, 1.15)
			if rng:NextNumber() > 0.06 then
				k.fil(pointToile(s % NR + 1, r), pointToile(s % NR + 2, r2), 0.22, TOILE, M.Lisse, "Toile")
			end
			r, s = r2, s + 1
		end
	end
	-- (d) fils tendus : du haut des étais vers le dôme, en diagonale d'un étai à l'autre, du plafond de la galerie au sol
	for j = 0, NE - 1 do
		local a = angleEtai(j)
		local r = rng:NextNumber(66, 82)
		k.filCourbe(surEtai(j, HG - rng:NextNumber(1, 6)), v(a + rng:NextNumber(-0.25, 0.25), r, yVoute(r)), rng:NextNumber(0.4, 1.4), 2, 0.2, TOILE, 0)
		if j % 4 == 0 or j % 4 == 1 then
			k.filCourbe(surEtai(j, rng:NextNumber(4, 8)), surEtai(j + 2, rng:NextNumber(22, 29)), rng:NextNumber(0.3, 1), 2, 0.18, TOILE_VIEILLE, 0)
		end
		if j % 2 == 0 then
			local ag = a + rng:NextNumber(0.06, 0.3)
			local rg = rng:NextNumber(88, 100)
			k.fil(v(ag, rg, HG + 4.8), v(ag + rng:NextNumber(-0.02, 0.02), rg + rng:NextNumber(-3, 3), 0.1), 0.16, TOILE_VIEILLE, M.Lisse, "Toile")
		end
	end

	-- ===== 7. Couvées d'œufs en grappes : au bord du cercle, devant les toiles, entassées dans la galerie =====
	for j = 0, 5 do
		couvee(polaire((j + rng:NextNumber(0.25, 0.75)) / 6 * DEUX_PI, rng:NextNumber(62, 67)), 5, 0.8, false)
	end
	for _, j in {0, 2, 4, 6, 8, 10, 12, 14} do -- au pied des toiles des travées
		couvee(polaire((j + 1) / NE * DEUX_PI + rng:NextNumber(-0.08, 0.08), rng:NextNumber(73, 78)), 6, 1, false)
	end
	for j = 0, 7 do
		couvee(polaire((j + 0.5) / 8 * DEUX_PI, rng:NextNumber(99, 101)), 9, 1.5, j % 3 == 0)
	end

	-- ===== 8. Ossements, squelettes de mineurs, outils, wagonnets, caisses, étais renversés =====
	local function os_(cf: CFrame, l: number)
		deco(Vector3.new(0.45, 0.45, l), cf * CFrame.new(0, 0.22, 0), OS, M.Calcaire, "Os")
		for _, s in {-1, 1} do
			deco(Vector3.new(0.8, 0.6, 0.6), cf * CFrame.new(0, 0.28, s * l / 2), OS, M.Calcaire, "Os")
		end
	end
	local function crane(cf: CFrame, casque: boolean)
		deco(Vector3.new(1.5, 1.3, 1.6), cf * CFrame.new(0, 0.65, 0), OS, M.Calcaire, "Crane")
		deco(Vector3.new(1.1, 0.4, 0.6), cf * CFrame.new(0, 0.2, -0.75), OS:Lerp(TERRE, 0.2), M.Calcaire, "Crane")
		if casque then
			deco(Vector3.new(1.9, 0.7, 1.9), cf * CFrame.new(1.6, 0.35, 0.8) * CFrame.Angles(0.4, 0.6, 0.2), CASQUE, M.Rouille, "Casque")
		end
	end
	for _ = 1, 24 do
		os_(polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(48, 106)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng:NextNumber(1.6, 2.6))
	end
	for _ = 1, 8 do
		crane(polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(50, 106)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), rng:NextNumber() < 0.6)
	end
	for j = 0, 3 do -- squelettes de mineurs couchés
		local cf = polaire((j + rng:NextNumber(0.2, 0.8)) / 4 * DEUX_PI, rng:NextNumber(76, 104)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		crane(cf * CFrame.new(0, 0, -3.4), true)
		deco(Vector3.new(0.4, 0.4, 5), cf * CFrame.new(0, 0.25, 0), OS, M.Calcaire, "Colonne")
		for z = -1, 1 do
			for _, s in {-1, 1} do
				deco(Vector3.new(1.6, 0.3, 0.3), cf * CFrame.new(s * 0.7, 0.5, z * 0.8 - 0.8) * CFrame.Angles(0, 0, s * 0.5), OS, M.Calcaire, "Cote")
			end
		end
		deco(Vector3.new(1.8, 0.6, 1), cf * CFrame.new(0, 0.3, 2.6), OS, M.Calcaire, "Bassin")
		os_(cf * CFrame.new(0.6, 0, 4.6) * CFrame.Angles(0, 0.2, 0), 2.6)
		os_(cf * CFrame.new(-0.7, 0, 4.4) * CFrame.Angles(0, -0.3, 0), 2.4)
		k.fil((cf * CFrame.new(0, 0.5, 0)).Position, (cf * CFrame.new(rng:NextNumber(-6, 6), 0.1, rng:NextNumber(-8, 8))).Position, 0.15, TOILE_VIEILLE, M.Lisse, "Toile")
	end
	for _ = 1, 5 do -- pioches abandonnées
		local cf = polaire(rng:NextNumber(0, DEUX_PI), rng:NextNumber(74, 106), 0.2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		deco(Vector3.new(0.35, 0.35, 4), cf, BOIS, M.Bois, "Manche")
		deco(Vector3.new(3, 0.45, 0.5), cf * CFrame.new(0, 0, -2), FER, M.Metal, "Pioche")
	end
	local function wagonnet(cf: CFrame)
		deco(Vector3.new(5, 3.4, 7.4), cf * CFrame.new(0, 2.6, 0), ROUILLE, M.Rouille, "Wagonnet")
		deco(Vector3.new(4.2, 0.6, 6.6), cf * CFrame.new(0, 4.1, 0), ROCHE, M.Gravier, "Minerai")
		for _, s in {-1, 1} do
			deco(Vector3.new(5.3, 0.6, 0.5), cf * CFrame.new(0, 4.3, s * 3.6), FER, M.Metal, "Rebord")
			for _, z in {-2.4, 2.4} do
				O.decor(O.disque(m, 0.6, 2, cf * CFrame.new(s * 2.4, 1, z), FER, M.Metal, "Roue")).CastShadow = false
			end
		end
		local centre = (cf * CFrame.new(0, 3, 0)).Position
		for j = 1, 6 do
			local a = j / 6 * DEUX_PI
			local p0 = centre + Vector3.new(math.cos(a) * 4, rng:NextNumber(-2, 3), math.sin(a) * 5)
			k.fil(p0, p0 + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(5, 14), rng:NextNumber(-6, 6)), 0.2, TOILE, M.Lisse, "Toile")
		end
	end
	wagonnet(tangent(math.pi / 2, 118) * CFrame.Angles(0, 0, 0.06)) -- sort de la galerie est
	wagonnet(tangent(math.pi / 2 + 0.45, RR) * CFrame.Angles(0, math.pi / 2, 0))
	wagonnet(tangent(3 * math.pi / 2 - 0.5, RR + 1) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, 1.25)) -- renversé
	for j = 1, 6 do
		local a = math.pi / 4 + rng:NextNumber(-0.25, 0.25) + (j % 2) * math.pi
		local cf = polaire(a, rng:NextNumber(97, 106)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		if j <= 3 then
			deco(Vector3.new(3.4, 3.4, 3.4), cf * CFrame.new(0, 1.7, 0), BOIS, M.Planches, "Caisse")
		else
			k.cyl(4, 3, cf * CFrame.new(0, 2, 0), BOIS_SOMBRE, M.Planches, "Tonneau")
			k.cyl(0.4, 3.2, cf * CFrame.new(0, 3.2, 0), FER, M.Metal, "Cercle")
		end
		k.fil((cf * CFrame.new(0, 3, 0)).Position, (cf * CFrame.new(rng:NextNumber(-6, 6), 14, rng:NextNumber(-6, 6))).Position, 0.18, TOILE, M.Lisse, "Toile")
	end
	for _ = 1, 4 do -- étais renversés
		local a = rng:NextNumber(0, DEUX_PI)
		if ecartGalerie(a) > 0.2 then
			deco(Vector3.new(2.4, rng:NextNumber(14, 22), 2.4), polaire(a, rng:NextNumber(90, 106), 3) * CFrame.Angles(rng:NextNumber(1.1, 1.4), rng:NextNumber(0, 3), 0), BOIS_SOMBRE, M.Bois, "EtaiTombe")
		end
	end

	-- ===== 9. Cocons : simples ou en forme de mineur (casque, lampe, bottes), de tailles variées =====
	-- corps debout dans le repère cf (pieds vers -Y) ; renvoie les pièces et la hauteur du sommet
	local function corpsCocon(cf: CFrame, t: number, mineur: boolean): ({BasePart}, number)
		local parts = {}
		local function ajoute(p)
			if p then table.insert(parts, p) end
			return p
		end
		if mineur then
			ajoute(k.boule(Vector3.new(3, 7.6, 2.8) * t, cf * CFrame.new(0, -0.6 * t, 0), TOILE_VIEILLE, M.Lisse, "Cocon"))
			ajoute(k.boule(Vector3.new(2.6, 2.6, 2.6) * t, cf * CFrame.new(0, 3.5 * t, 0), TOILE_VIEILLE:Lerp(TOILE, 0.4), M.Lisse, "Tete"))
			ajoute(k.cyl(0.3 * t, 3.6 * t, cf * CFrame.new(0, 4.1 * t, 0) * CFrame.Angles(0.15, 0, 0), CASQUE, M.Metal, "Casque"))
			ajoute(k.boule(Vector3.new(2.7, 1.7, 2.7) * t, cf * CFrame.new(0, 4.5 * t, 0) * CFrame.Angles(0.15, 0, 0), CASQUE, M.Metal, "Casque"))
			ajoute(deco(Vector3.new(0.8, 0.8, 0.5) * t, cf * CFrame.new(0, 4.5 * t, -1.35 * t), LAMPE, M.Verre, "Lampe"))
			for _, s in {-1, 1} do
				ajoute(deco(Vector3.new(0.9, 1.2, 1.5) * t, cf * CFrame.new(s * 0.55 * t, -4.6 * t, -0.25 * t), CUIR, M.Cuir, "Botte"))
			end
			for _, y in {-2.2, 0.8} do
				ajoute(k.cyl(0.45 * t, 3.3 * t, cf * CFrame.new(0, y * t, 0) * CFrame.Angles(0.12 * y, 0, 0), TOILE, M.Lisse, "Bande"))
			end
			if rng:NextNumber() < 0.5 then -- la pioche est restée prise dans la soie
				local manche = cf * CFrame.new(1.4 * t, -0.8 * t, -0.8 * t) * CFrame.Angles(0, 0, 0.35)
				ajoute(deco(Vector3.new(0.35, 4.4, 0.35) * t, manche, BOIS, M.Bois, "Manche"))
				ajoute(deco(Vector3.new(3, 0.5, 0.5) * t, manche * CFrame.new(0, 2.2 * t, 0), FER, M.Metal, "Pioche"))
			end
			return parts, 5.4 * t
		end
		ajoute(k.boule(Vector3.new(3.4, 7, 3.4) * t, cf, TOILE_VIEILLE, M.Lisse, "Cocon"))
		for _, y in {-1.2, 1.4} do
			ajoute(k.cyl(0.5 * t, 3.6 * t, cf * CFrame.new(0, y * t, 0) * CFrame.Angles(0.15 * y, 0, 0), TOILE, M.Lisse, "Bande"))
		end
		return parts, 3.5 * t
	end
	-- Cocon suspendu (Model tagué « BanniereArene » : il se balance côté client). Les mineurs pendent tête en bas.
	local function cocon(attachePos: Vector3, yCentre: number, t: number, mineur: boolean)
		local modele = Instance.new("Model")
		modele.Name = "Cocon"
		local attache = k.invisible(Vector3.new(0.4, 0.4, 0.4), CFrame.new(attachePos), "Attache")
		local cf = CFrame.new(attachePos.X + rng:NextNumber(-0.6, 0.6), c.Y + yCentre, attachePos.Z + rng:NextNumber(-0.6, 0.6))
			* CFrame.Angles(if mineur then math.pi else 0, rng:NextNumber(0, DEUX_PI), rng:NextNumber(-0.1, 0.1))
		local parts, sommet = corpsCocon(cf, t, mineur)
		local haut = if mineur then cf * CFrame.new(0, -5.2 * t, 0) else cf * CFrame.new(0, sommet, 0) -- tête en bas : le fil tient les bottes
		local fil = k.fil(attachePos, haut.Position, 0.2, TOILE, M.Lisse, "Fil")
		if fil then table.insert(parts, fil) end
		table.insert(parts, attache)
		ranger(parts, modele)
		modele.PrimaryPart = attache
		modele:SetAttribute("Phase", rng:NextNumber(0, DEUX_PI))
		O.tag(modele, "BanniereArene")
		modele.Parent = m
	end
	for j = 0, 7 do -- sous la grande toile, au-dessus du combat : bas des cocons ≥ 30
		local a = (j + rng:NextNumber(0.15, 0.85)) / 8 * DEUX_PI
		local r = rng:NextNumber(18, 44)
		local t = rng:NextNumber(0.75, 1.05)
		local yHaut = yToile(r)
		local yCentre = math.max(30 + 5.6 * t, yHaut - 5.6 * t - rng:NextNumber(1, 8))
		cocon(v(a, r, yHaut), yCentre, t, j % 2 == 0)
	end
	for j = 0, 5 do -- au bord de la toile, devant la galerie
		local a = (j + rng:NextNumber(0.2, 0.8)) / 6 * DEUX_PI
		local r = rng:NextNumber(73, 79)
		local t = rng:NextNumber(0.9, 1.5)
		cocon(v(a, r, yToile(r)), rng:NextNumber(16, 24), t, j % 2 == 1)
	end
	for j = 0, 5 do -- sous le plafond de la galerie
		local a = angleEtai(j * 2 + 1) + rng:NextNumber(0.08, 0.3)
		local t = rng:NextNumber(0.8, 1.6)
		cocon(v(a, rng:NextNumber(88, 100), HG + 4.8), rng:NextNumber(14, 21), t, j % 2 == 0)
	end
	for j = 0, 7 do -- prisonniers emmaillotés debout contre les étais extérieurs (immobiles)
		if j % 4 ~= 3 then
			local a = angleEtai(j * 2)
			local t = rng:NextNumber(0.85, 1.25)
			-- dos à l'étai, visage (lampe) vers le centre, penché contre le bois
			local cf = tangent(a, RO - 3.6, 5.6 * t) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0.12, 0, rng:NextNumber(-0.1, 0.1))
			corpsCocon(cf, t, true)
			for _, y in {-3, 2} do
				k.fil((cf * CFrame.new(-1.6 * t, y * t, 0)).Position, (cf * CFrame.new(1.6 * t, y * t + 1, 2.4)).Position, 0.2, TOILE, M.Lisse, "Toile")
			end
		end
	end

	-- ===== 10. Sac d'œufs luminescent au-dessus du centre (lumière principale), fils vers l'antre =====
	local sac = CFrame.new(c) * CFrame.new(0, 52, 0)
	k.boule(Vector3.new(9, 13, 9), sac, OEUF:Lerp(TOILE, 0.3), M.Lisse, "Sac").Transparency = 0.35
	k.lueur(k.boule(Vector3.new(5.5, 9, 5.5), sac, LUEUR:Lerp(VIOLET, 0.35), M.Neon, "Lueur"), 0.35)
	for j = 1, NR, 2 do
		local a = (j - 1) / NR * DEUX_PI
		k.fil((sac * CFrame.new(math.sin(a) * 2.5, 5.5, -math.cos(a) * 2.5)).Position, pointToile(j, 12), 0.28, TOILE, M.Lisse, "Toile")
	end
	k.fil((sac * CFrame.new(0, -6.5, 0)).Position, (sac * CFrame.new(0.6, -12, 0.3)).Position, 0.2, TOILE, M.Lisse, "Toile")
	k.lumiere(sac * CFrame.new(0, -7, 0), Color3.fromRGB(200, 226, 190), 1.5, 60)

	-- ===== 11. Atmosphère : nappes de brume basses, voile violacé, spores =====
	local nappe = k.invisible(Vector3.new(140, 1, 140), CFrame.new(c) * CFrame.new(0, 1, 0), "Brume")
	O.brume(nappe, Color3.fromRGB(126, 150, 116), 3)
	local nappe2 = k.invisible(Vector3.new(220, 1, 220), CFrame.new(c) * CFrame.new(0, 2, 0), "Brume")
	O.brume(nappe2, Color3.fromRGB(116, 100, 136), 2)
	for j = 0, 3 do
		local p = k.invisible(Vector3.new(34, 1, 18), tangent(math.pi / 4 + j * math.pi / 2, 95, 1), "Brume")
		O.brume(p, Color3.fromRGB(120, 140, 112), 2)
	end
	local air = k.invisible(Vector3.new(130, 40, 130), CFrame.new(c) * CFrame.new(0, 22, 0), "Spores")
	local spores = O.lucioles(air, Color3.fromRGB(190, 230, 160), 5)
	spores.LightEmission = 0.4
	spores.Acceleration = Vector3.new(0, -0.15, 0)
	spores.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.16), NumberSequenceKeypoint.new(1, 0)})
end
