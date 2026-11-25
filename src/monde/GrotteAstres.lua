--[[ Grotte −1200 m « L'Observatoire des astres » (palier 8, Néant étoilé, boss : le Gardien des astres).
	Au plus profond, la roche s'ouvre sur un ciel. Des étoiles brillent sous la terre ; un peuple oublié les
	observait d'ici, et son gardien veille encore sur la carte du ciel.
	- Le Seuil à l'arrivée : deux pierres levées et leur linteau gravé d'une constellation, campement d'astronome
	  (lunette sur trépied, table de cartes du ciel, lanterne dorée)
	- Voûte étoilée : des étoiles scintillent sous le plafond de chaque salle (particules, très léger)
	- LE PUITS DES ÉTOILES : la plus grande salle s'ouvre sur un vide où brille une nébuleuse ; dalles dorées
	  suspendues jusqu'au pilier du PLANÉTAIRE (soleil d'or, anneaux d'orbite, planètes), étoiles tombées qui flottent
	- LE MÉTÉORE : une météorite fendue, encore brûlante, entourée d'éclats de néant
	- Constellations tracées sur les parois (étoiles reliées par des fils de lumière), cristaux du néant
	  (verre noir, cœur d'or ou de cyan), poussière d'étoiles
	- Salle du fond : L'AUTEL DES CONSTELLATIONS — grand anneau-portail empli de nébuleuse, douze obélisques
	  gravés des signes du ciel, estrade à trois marches, cercle d'or au sol
	Zones : Camp, Puits, Meteore, Autel. Attributs : Theme = "NeantEtoile", Planetaire, ArenaAstres. ]]

local GT = require(script.Parent.GrotteTheme)

local GrotteAstres = {}

local rgb = Color3.fromRGB

local P = {
	or_ = rgb(255, 210, 120),
	orPale = rgb(255, 238, 190),
	laiton = rgb(196, 150, 70),
	nuit = rgb(14, 14, 36),
	indigo = rgb(56, 60, 150),
	bleu = rgb(90, 130, 255),
	cyan = rgb(120, 210, 255),
	nebuleuse = rgb(110, 90, 230),
	etoile = rgb(245, 245, 255),
	pierre = rgb(60, 62, 92),
	pierreClaire = rgb(96, 98, 132),
	noir = rgb(10, 10, 20),
	braise = rgb(255, 140, 60),
	parchemin = rgb(222, 200, 150),
	bois = rgb(70, 52, 40),
}

local COUL_GENERIQUE = {
	Roche = {rgb(40, 42, 70), Enum.Material.Asphalt},
	Goutte = {P.orPale, Enum.Material.Neon, 0.4},
	Lueur = {P.or_, Enum.Material.Neon},
}

function GrotteAstres.decorer(ctx, infos, outils)
	local T = GT.nouveau(ctx, infos, outils)
	local rng, decor, M = T.rng, T.decor, T.M
	local depart, boss = T.depart, T.boss
	local salles = T.salles
	local plat, unite = T.plat, T.unite

	local candidates = {}
	for _, s in salles do
		if not s.depart and not s.boss and s.r >= 15 then
			table.insert(candidates, s)
		end
	end
	table.sort(candidates, function(a, b)
		return a.r > b.r
	end)
	local puits = T.salleFosse(candidates)
	local roles = {}

	local function sansOmbre(p: BasePart, t: number?): BasePart
		p.CastShadow = false
		if t then p.Transparency = t end
		return p
	end
	-- cristal du néant : prisme de verre noir réfléchissant, cœur d'or ou de cyan
	local function cristal(parent, base: CFrame, h: number, couleur: Color3)
		local l = h * rng:NextNumber(0.2, 0.28)
		for k = 0, 1 do
			local b = sansOmbre(T.bloc(parent, Vector3.new(l, h * 0.8, l), base * CFrame.new(0, h * 0.4, 0) * CFrame.Angles(0, k * math.pi / 4, 0), P.noir, Enum.Material.Glass, "Cristal"), 0.15)
			b.Reflectance = 0.3
		end
		for k = 0, 3 do
			sansOmbre(T.coin(parent, Vector3.new(l, h * 0.2, l * 0.5), base * CFrame.new(0, h * 0.9, 0) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 8, 0) * CFrame.new(0, 0, l * 0.25),
				P.noir, Enum.Material.Glass, "Pointe"), 0.15)
		end
		local c = sansOmbre(T.bloc(parent, Vector3.new(l * 0.22, h * 0.65, l * 0.22), base * CFrame.new(0, h * 0.42, 0), couleur, M.Neon, "Coeur"))
		if rng:NextNumber() < 0.4 then T.tag(c, "GrottePulse") end
	end
	local function grappe(base: CFrame, taille: number)
		local m = T.modele("CristauxNeant")
		for k = 1, rng:NextInteger(3, 5) do
			cristal(m, base * CFrame.new(rng:NextNumber(-1, 1) * taille * 0.3, -0.3, rng:NextNumber(-1, 1) * taille * 0.3)
				* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6), rng:NextNumber(-0.5, 0.5)), taille * rng:NextNumber(0.5, 1), if k % 2 == 0 then P.or_ else P.cyan)
		end
		return m
	end
	-- constellation sur une paroi : 4 à 6 étoiles reliées par des fils de lumière
	local function constellation(hit, taille: number)
		local n = hit.Normal
		local haut = unite(Vector3.yAxis - n * n.Y, Vector3.yAxis)
		local cote = n:Cross(haut).Unit
		local m = T.modele("Constellation")
		local prec = nil
		for k = 1, rng:NextInteger(4, 6) do
			local local2 = haut * rng:NextNumber(-1, 1) * taille + cote * ((k - 3.5) / 3) * taille * 1.4
			local recolle = T.trace(hit.Position + local2 + n * 3, -n * 6)
			if recolle then
				local q = recolle.Position + recolle.Normal * 0.15
				local d = if k == 1 then 0.75 else rng:NextNumber(0.35, 0.6)
				local e = sansOmbre(T.boule(m, Vector3.one * d, CFrame.new(q), if k == 1 then P.or_ else P.etoile, M.Neon, "Etoile"))
				if k == 1 then T.tag(e, "GrottePulse") end
				if prec then
					sansOmbre(T.bloc(m, Vector3.new(0.08, 0.08, (q - prec).Magnitude), CFrame.lookAt((q + prec) / 2, q), P.orPale, M.Neon, "Fil"), 0.4)
				end
				prec = q
			end
		end
		return m
	end
	-- étoile tombée : orbe doré qui flotte (VieGrotte, tag GrotteMeduse)
	local nEtoiles = 0
	local function etoileTombee(pos: Vector3, s: number, couleur: Color3)
		nEtoiles += 1
		local m = T.modele("EtoileTombee")
		local o = sansOmbre(T.boule(m, Vector3.one * s, CFrame.new(pos), couleur, M.Neon, "Orbe"))
		for k = 0, 3 do
			sansOmbre(T.bloc(m, Vector3.new(0.12, s * 2.2, 0.12), CFrame.new(pos) * CFrame.Angles(0, 0, k * math.pi / 4), couleur:Lerp(Color3.new(1, 1, 1), 0.4), M.Neon, "Rayon"), 0.3)
		end
		T.emetteur(o, {
			Name = "Poussiere", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(couleur, P.etoile),
			Size = NumberSequence.new({T.kp(0, 0.3), T.kp(1, 0)}), Lifetime = NumberRange.new(1, 2), Rate = 6, Speed = NumberRange.new(0.3, 0.8),
			SpreadAngle = Vector2.new(180, 180),
		})
		if nEtoiles % 3 == 1 then T.remplir(o, couleur, 0.7, 18) end
		m.PrimaryPart = o
		m:SetAttribute("Origine", pos)
		T.tag(m, "GrotteMeduse")
		return m
	end
	-- voûte étoilée : des étoiles qui scintillent juste sous le plafond (particules immobiles)
	local function voute(s)
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local haut = T.plafondEn(Vector3.new(s.p.X, y0 + 2, s.p.Z), 90)
		local y = if haut then haut.Position.Y - 2.5 else y0 + 20
		local v = T.volume(decor, Vector3.new(s.r * 1.5, 2, s.r * 1.5), CFrame.new(s.p.X, y, s.p.Z), "VouteEtoilee")
		T.emetteur(v, {
			Name = "Etoiles", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.etoile, P.orPale),
			Size = NumberSequence.new({T.kp(0, 0), T.kp(0.2, 0.35), T.kp(0.5, 0.15), T.kp(0.8, 0.35), T.kp(1, 0)}),
			Lifetime = NumberRange.new(4, 8), Rate = math.floor(s.r * 0.5), Speed = NumberRange.new(0), Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, Rotation = NumberRange.new(0, 360),
		})
	end

	-- ===== 1. Le Seuil (arrivée) =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local m = T.modele("SeuilAstres")
		-- pierres levées et linteau à constellation, en travers du passage (on passe dessous)
		local q1, q2 = T.solEn(depart.p + avant * 15 - droite * 7), T.solEn(depart.p + avant * 15 + droite * 7)
		if q1 and q2 then
			local y = math.min(q1.Position.Y, q2.Position.Y)
			for _, q in {q1, q2} do
				T.bloc(m, Vector3.new(2.4, 11, 2), CFrame.lookAt(q.Position + Vector3.new(0, 5, 0), q.Position + Vector3.new(0, 5, 0) + avant), P.pierre, Enum.Material.Slate, "PierreLevee")
			end
			local mil = (q1.Position + q2.Position) / 2
			local lin = CFrame.lookAt(Vector3.new(mil.X, y + 11, mil.Z), Vector3.new(mil.X, y + 11, mil.Z) - avant)
			T.bloc(m, Vector3.new(17, 2, 2.4), lin, P.pierreClaire, Enum.Material.Slate, "Linteau")
			local pts = {{-5, 0.3}, {-2.5, -0.4}, {0, 0.5}, {2, -0.2}, {4.5, 0.4}}
			local prec = nil
			for i, p in pts do
				local q = (lin * CFrame.new(p[1], p[2], -1.25)).Position
				sansOmbre(T.boule(m, Vector3.one * (if i == 3 then 0.7 else 0.45), CFrame.new(q), if i == 3 then P.or_ else P.etoile, M.Neon, "Etoile"))
				if prec then
					sansOmbre(T.bloc(m, Vector3.new(0.08, 0.08, (q - prec).Magnitude), CFrame.lookAt((q + prec) / 2, q), P.orPale, M.Neon, "Fil"), 0.3)
				end
				prec = q
			end
		end
		-- lunette sur trépied
		local qL = T.solEn(depart.p - droite * 11 + avant * 3)
		if qL then
			local c = qL.Position
			for k = 0, 2 do
				local a = k / 3 * 2 * math.pi
				local pied = c + Vector3.new(math.cos(a) * 1.3, 0, math.sin(a) * 1.3)
				local tete = c + Vector3.new(0, 3.4, 0)
				T.bloc(m, Vector3.new(0.2, 0.2, (tete - pied).Magnitude), CFrame.lookAt((pied + tete) / 2, tete), P.bois, M.Bois, "Pied")
			end
			local tube = CFrame.new(c + Vector3.new(0, 3.7, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0) * CFrame.Angles(math.rad(35), 0, 0)
			T.disque(m, 4, 0.7, tube * CFrame.Angles(0, math.pi / 2, 0), P.laiton, M.Metal, "Tube")
			T.disque(m, 0.4, 0.95, tube * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi / 2, 0), P.laiton:Lerp(P.or_, 0.4), M.Metal, "Bague")
			sansOmbre(T.disque(m, 0.1, 0.6, tube * CFrame.new(0, 0, -2.2) * CFrame.Angles(0, math.pi / 2, 0), P.cyan, M.Neon, "Lentille"))
		end
		-- table des cartes du ciel et lanterne dorée
		local qT = T.solEn(depart.p + droite * 11 + avant * 2)
		if qT then
			local cf = CFrame.lookAt(qT.Position, qT.Position + avant)
			T.bloc(m, Vector3.new(4, 0.3, 2.4), cf * CFrame.new(0, 2.6, 0), P.bois, M.Planches, "Plateau")
			for _, x in {-1.7, 1.7} do
				for _, z in {-1, 1} do
					T.bloc(m, Vector3.new(0.3, 2.5, 0.3), cf * CFrame.new(x, 1.25, z), P.bois, M.Bois, "Pied")
				end
			end
			for k = 0, 1 do
				local carte = T.bloc(m, Vector3.new(1.6, 0.05, 1.2), cf * CFrame.new(-0.9 + k * 1.7, 2.78, 0) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), P.parchemin, M.Lisse, "Carte")
				for _ = 1, 3 do
					sansOmbre(T.bloc(m, Vector3.new(0.12, 0.03, 0.12), carte.CFrame * CFrame.new(rng:NextNumber(-0.6, 0.6), 0.04, rng:NextNumber(-0.45, 0.45)), P.indigo, M.Lisse, "Point"))
				end
			end
			local lant = sansOmbre(T.boule(m, Vector3.one * 0.8, cf * CFrame.new(1.4, 3.3, 0.7), P.or_, M.Neon, "Lanterne"))
			T.lumiere(lant, P.or_, 1.4, 22)
		end
		T.zone(depart.p, 34, P.orPale:Lerp(P.bleu, 0.3), "Camp")
	end

	-- ===== 2. LE PUITS DES ÉTOILES et le planétaire =====
	if puits then
		local fosse = T.fosse(puits, {
			profondeur = 60, pilier = 6.5, couleurDalle = P.pierreClaire, materiauDalle = Enum.Material.Slate, couleurBord = P.laiton, couleurPoteau = P.laiton,
			pont = function(u, d0, d1, yA, yB)
				-- dalles de pierre bordées d'or, suspendues au-dessus du vide
				local c = puits.p
				local pente = math.atan2(yB - yA, d1 - d0)
				local m = T.modele("DallesEtoiles")
				local d, k = d0, 0
				while d <= d1 do
					k += 1
					local t = (d - d0) / (d1 - d0)
					local q = Vector3.new(c.X, yA + (yB - yA) * t - 0.4, c.Z) + u * d
					local cf = CFrame.lookAt(q, q + u) * CFrame.Angles(pente, rng:NextNumber(-0.05, 0.05), 0)
					T.solide(m, Vector3.new(4.6, 0.8, 2.4), cf, if k % 2 == 0 then P.pierre else P.pierreClaire, Enum.Material.Slate, "Dalle")
					sansOmbre(T.bloc(m, Vector3.new(4.7, 0.1, 0.15), cf * CFrame.new(0, 0.42, -1.15), P.or_, M.Neon, "Liseré"))
					d += 2.6
				end
			end,
		})
		if fosse then
			roles[puits] = "puits"
			local c = fosse.c
			-- nébuleuse au fond du vide
			local fond = T.volume(decor, Vector3.new(fosse.f * 1.7, 4, fosse.f * 1.7), CFrame.new(c.X, fosse.fond + 6, c.Z), "Nebuleuse")
			T.lumiere(fond, P.nebuleuse:Lerp(P.bleu, 0.5), 2.5, 60)
			T.emetteur(fond, {
				Name = "Nebuleuse", Texture = GT.TEX_FUMEE, LightEmission = 0.8, LightInfluence = 0, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, P.nebuleuse),
					ColorSequenceKeypoint.new(0.5, P.bleu), ColorSequenceKeypoint.new(1, P.or_)}),
				Size = NumberSequence.new(8, 16), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.4, 0.7), T.kp(1, 1)}), Lifetime = NumberRange.new(8, 12),
				Speed = NumberRange.new(0.5, 1.5), Rate = 4, Shape = Enum.ParticleEmitterShape.Box, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-8, 8),
			})
			T.emetteur(fond, {
				Name = "Etoiles", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.etoile, P.or_),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.5, 0.5), T.kp(1, 0)}), Lifetime = NumberRange.new(4, 7), Rate = 20,
				Speed = NumberRange.new(0), Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			-- le planétaire sur le pilier : socle, soleil d'or, anneaux d'orbite inclinés, planètes
			local pl = T.modele("Planetaire")
			T.cylindre(pl, 1.4, 4, CFrame.new(c + Vector3.new(0, 0.7, 0)), P.laiton, M.Metal, "Socle")
			T.cylindre(pl, 5, 0.6, CFrame.new(c + Vector3.new(0, 3.5, 0)), P.laiton, M.Metal, "Axe")
			local centre = c + Vector3.new(0, 7.5, 0)
			local soleil = sansOmbre(T.boule(pl, Vector3.one * 3, CFrame.new(centre), P.or_, M.Neon, "Soleil"))
			T.tag(soleil, "GrottePulse")
			T.lumiere(soleil, P.or_, 2.5, 50)
			T.emetteur(soleil, {
				Name = "Couronne", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.orPale, P.or_),
				Size = NumberSequence.new({T.kp(0, 3), T.kp(1, 6)}), Transparency = NumberSequence.new({T.kp(0, 0.6), T.kp(1, 1)}),
				Lifetime = NumberRange.new(1.5, 1.5), Rate = 2, Speed = NumberRange.new(0), LockedToPart = true,
			})
			local planetes = {P.cyan, P.braise, P.nebuleuse, P.etoile}
			for k = 1, 4 do
				local r = 2.6 + k * 1.6
				local incl = CFrame.new(centre) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 6), rng:NextNumber(-0.35, 0.35))
				local nSeg = 18
				for i = 0, nSeg - 1 do
					local a0, a1 = i / nSeg * 2 * math.pi, (i + 1) / nSeg * 2 * math.pi
					local p0 = (incl * CFrame.new(math.cos(a0) * r, 0, math.sin(a0) * r)).Position
					local p1 = (incl * CFrame.new(math.cos(a1) * r, 0, math.sin(a1) * r)).Position
					sansOmbre(T.bloc(pl, Vector3.new(0.14, 0.14, (p1 - p0).Magnitude + 0.05), CFrame.lookAt((p0 + p1) / 2, p1), P.laiton:Lerp(P.or_, 0.3), M.Metal, "Orbite"))
				end
				local a = rng:NextNumber(0, 2 * math.pi)
				local q = (incl * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)).Position
				sansOmbre(T.boule(pl, Vector3.one * (0.6 + k * 0.15), CFrame.new(q), planetes[k], M.Neon, "Planete"))
			end
			ctx.modele:SetAttribute("Planetaire", centre)
			-- étoiles tombées qui flottent au-dessus du vide
			for _ = 1, 6 do
				local a = rng:NextNumber(0, 2 * math.pi)
				local r = rng:NextNumber(fosse.pilier + 5, math.max(fosse.pilier + 6, fosse.f - 3))
				etoileTombee(c + Vector3.new(math.cos(a) * r, rng:NextNumber(-8, 8), math.sin(a) * r), rng:NextNumber(0.8, 1.4), if rng:NextNumber() < 0.6 then P.or_ else P.cyan)
			end
			T.zone(c, fosse.f + 12, P.nebuleuse:Lerp(P.or_, 0.3), "Puits")
		end
	end

	-- ===== 3. LE MÉTÉORE =====
	local meteore = nil
	for _, s in candidates do
		if not roles[s] then meteore = s break end
	end
	if meteore then
		local q0 = T.coinSalle(meteore, meteore.r * 0.45)
		local hit = T.solEn(q0, 8)
		if hit and T.solLibre(hit.Position, 5, 8) then
			roles[meteore] = "meteore"
			local q = hit.Position
			local m = T.modele("Meteorite")
			local cf = CFrame.new(q + Vector3.new(0, 2.4, 0)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0)
			T.boule(m, Vector3.new(8, 6.5, 7), cf, P.noir:Lerp(P.pierre, 0.4), Enum.Material.Basalt, "Roc")
			T.boule(m, Vector3.new(5, 4, 4.5), cf * CFrame.new(2.6, 1.2, -1), P.noir:Lerp(P.pierre, 0.3), Enum.Material.Basalt, "Bosse")
			for k = 1, 6 do
				sansOmbre(T.bloc(m, Vector3.new(0.3, rng:NextNumber(2.5, 4.5), 0.3), cf * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0) * CFrame.new(0, 0, -3.1),
					if k % 2 == 0 then P.braise else P.or_, M.Neon, "Fente"))
			end
			local coeur = T.volume(m, Vector3.new(6, 2, 6), CFrame.new(q + Vector3.new(0, 5, 0)), "Chaleur")
			T.lumiere(coeur, P.braise, 1.8, 30)
			T.emetteur(coeur, {
				Name = "Vapeur", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.pierreClaire, P.nuit), LightInfluence = 0.5,
				Size = NumberSequence.new(2, 6), Transparency = NumberSequence.new({T.kp(0, 0.6), T.kp(1, 1)}), Lifetime = NumberRange.new(4, 6),
				Rate = 4, Speed = NumberRange.new(1.5, 3), EmissionDirection = Enum.NormalId.Top, Shape = Enum.ParticleEmitterShape.Box,
			})
			for _ = 1, 6 do
				local a, d = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(5.5, 9)
				local qc = T.solEn(q + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d), 6)
				if qc and T.solLibre(qc.Position, 1, 3) then
					grappe(CFrame.new(qc.Position) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)), rng:NextNumber(1.2, 2.2))
				end
			end
			T.interdire(q, 7)
			ctx.modele:SetAttribute("Meteore", q)
			T.zone(meteore.p, meteore.r + 6, P.braise:Lerp(P.or_, 0.5), "Meteore")
		end
	end

	-- ===== 4. Constellations aux parois, cristaux du néant, étoiles tombées, voûtes étoilées =====
	local nConst = 0
	for _ = 1, 40 do
		if nConst >= 14 then break end
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(4, 9), pt.r + 8)
		if hit and math.abs(hit.Normal.Y) < 0.5 and (hit.Position - depart.p).Magnitude > 18 then
			nConst += 1
			constellation(hit, rng:NextNumber(2.5, 4))
		end
	end
	for _ = 1, 18 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 6), pt.r + 6)
		if hit and (hit.Position - depart.p).Magnitude > 20 then
			grappe(outils.axeVers(hit.Position - hit.Normal * 0.4, hit.Normal), rng:NextNumber(1.2, 2.6))
		end
	end
	for _, s in salles do
		voute(s)
		if not s.depart and not s.boss and roles[s] ~= "puits" and nEtoiles < 12 then
			local a = rng:NextNumber(0, 2 * math.pi)
			local sol = T.solEn(s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.2, 0.6), 8)
			if sol then
				etoileTombee(sol.Position + Vector3.new(0, rng:NextNumber(6, 10), 0), rng:NextNumber(0.6, 1), if rng:NextNumber() < 0.5 then P.or_ else P.cyan)
			end
		end
		if not s.depart then
			T.particulesSalle(s, {
				Name = "PoussiereEtoiles", Texture = GT.TEX_ETINCELLE, LightEmission = 1, Color = ColorSequence.new(P.orPale, P.cyan),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.15), T.kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 8,
				Speed = NumberRange.new(0.2, 0.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.1, 0),
			})
		end
	end

	-- ===== 5. L'AUTEL DES CONSTELLATIONS (salle du boss) =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local haut = T.plafondEn(c + Vector3.new(0, 2, 0), 90)
		local yH = if haut then haut.Position.Y else y0 + 40
		local m = T.modele("AutelConstellations")
		-- grand anneau-portail dressé contre la paroi du fond, empli de nébuleuse
		local q0, dir = T.coinSalle(s, T.rb * 0.78)
		local qP = T.solEn(q0, 10)
		if qP then
			local R = math.min(9, (yH - qP.Position.Y) / 2 - 1.5)
			local centre = qP.Position + Vector3.new(0, R + 0.6, 0)
			local face = CFrame.lookAt(centre, centre - dir)
			local nSeg = 28
			for i = 0, nSeg - 1 do
				local a0, a1 = i / nSeg * 2 * math.pi, (i + 1) / nSeg * 2 * math.pi
				local p0 = (face * CFrame.new(math.cos(a0) * R, math.sin(a0) * R, 0)).Position
				local p1 = (face * CFrame.new(math.cos(a1) * R, math.sin(a1) * R, 0)).Position
				T.bloc(m, Vector3.new(1.4, 1.2, (p1 - p0).Magnitude + 0.1), CFrame.lookAt((p0 + p1) / 2, p1, face.LookVector), P.pierreClaire, Enum.Material.Slate, "Anneau")
				if i % 4 == 0 then
					local g = sansOmbre(T.bloc(m, Vector3.new(0.5, 0.5, 0.2), face * CFrame.new(math.cos(a0) * R, math.sin(a0) * R, -0.7) * CFrame.Angles(0, 0, math.rad(45)), P.or_, M.Neon, "Glyphe"))
					T.tag(g, "GrottePulse")
				end
			end
			local voile = sansOmbre(T.disque(m, 0.3, R * 2 - 0.6, face * CFrame.Angles(0, math.pi / 2, 0), P.nebuleuse, M.Neon, "Nebuleuse"), 0.55)
			T.lumiere(voile, P.nebuleuse:Lerp(P.cyan, 0.4), 2, 50)
			T.emetteur(voile, {
				Name = "Tourbillon", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.cyan, P.or_),
				Size = NumberSequence.new({T.kp(0, 0.6), T.kp(1, 0)}), Lifetime = NumberRange.new(1.5, 2.5), Rate = 20, Speed = NumberRange.new(-4, -3),
				Shape = Enum.ParticleEmitterShape.Disc, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
			})
			T.interdire(qP.Position, R)
		end
		-- estrade à trois marches au centre
		for k = 0, 2 do
			T.cylindre(m, 0.5, 12 - k * 3.4, CFrame.new(c + Vector3.new(0, 0.25 + k * 0.5, 0)), if k == 1 then P.pierreClaire else P.pierre, Enum.Material.Slate, "Marche")
		end
		sansOmbre(T.cylindre(m, 0.08, 5.4, CFrame.new(c + Vector3.new(0, 1.55, 0)), P.or_, M.Neon, "Sceau"), 0.2)
		-- douze obélisques gravés des signes du ciel
		for k = 0, 11 do
			local a = k / 12 * 2 * math.pi
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.8)
			if q and T.libre(q.Position, 1) then
				local ob = T.modele("Obelisque", m)
				local face = CFrame.lookAt(q.Position, Vector3.new(c.X, q.Position.Y, c.Z))
				T.bloc(ob, Vector3.new(2, 8, 2), face * CFrame.new(0, 4, 0), P.pierre, Enum.Material.Slate, "Fut")
				T.coin(ob, Vector3.new(2, 1.6, 1), face * CFrame.new(0, 8.8, -0.5), P.laiton, M.Metal, "Pointe")
				T.coin(ob, Vector3.new(2, 1.6, 1), face * CFrame.new(0, 8.8, 0.5) * CFrame.Angles(0, math.pi, 0), P.laiton, M.Metal, "Pointe")
				-- signe : une petite constellation propre à l'obélisque
				local r2 = Random.new(k * 31 + 7)
				local prec = nil
				for i = 1, 3 + k % 3 do
					local q2 = (face * CFrame.new(r2:NextNumber(-0.7, 0.7), 2.5 + i * 1.3 + r2:NextNumber(-0.4, 0.4), -1.05)).Position
					sansOmbre(T.bloc(ob, Vector3.new(0.3, 0.3, 0.1), CFrame.new(q2) * face.Rotation, if i == 1 then P.or_ else P.etoile, M.Neon, "Etoile"))
					if prec then
						sansOmbre(T.bloc(ob, Vector3.new(0.06, 0.06, (q2 - prec).Magnitude), CFrame.lookAt((q2 + prec) / 2, q2), P.orPale, M.Neon, "Fil"), 0.3)
					end
					prec = q2
				end
				if k % 3 == 0 then T.lumiere(ob:FindFirstChild("Etoile") :: BasePart, P.or_, 1, 20) end
			end
		end
		-- cercle d'or au sol
		for k = 0, 39 do
			local a = k / 40 * 2 * math.pi
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.6)
			if q then
				sansOmbre(T.bloc(m, Vector3.new(0.25, 0.08, 2.4), CFrame.lookAt(q.Position + Vector3.new(0, 0.06, 0), q.Position + Vector3.new(0, 0.06, 0) + Vector3.new(-math.sin(a), 0, math.cos(a))),
					P.or_, M.Neon, "CercleOr"), 0.2)
			end
		end
		local brume = T.volume(m, Vector3.new(T.rb * 1.6, 3, T.rb * 1.6), CFrame.new(c + Vector3.new(0, 1.5, 0)), "BrumeEtoilee")
		T.emetteur(brume, {
			Name = "Brume", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.indigo:Lerp(P.nebuleuse, 0.4)), LightInfluence = 0.3, LightEmission = 0.2,
			Size = NumberSequence.new(5, 10), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.78), T.kp(1, 1)}),
			Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.3, 0.8), Rate = 6, Shape = Enum.ParticleEmitterShape.Box,
		})
		ctx.modele:SetAttribute("ArenaAstres", c)
		T.zone(c, T.rb + 8, P.or_:Lerp(P.nebuleuse, 0.5), "Autel")
	end

	-- ===== 6. Décor générique, veines d'or et de cyan, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, champignons = false, humide = false,
		mine = false, racines = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.or_, P.cyan, P.or_, P.bleu}, 4, P.orPale)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.orPale:Lerp(P.bleu, 0.3) end
			if roles[s] == "puits" then return P.nebuleuse:Lerp(P.cyan, 0.4) end
			if roles[s] == "meteore" then return P.braise:Lerp(P.or_, 0.5) end
			if s.boss then return P.or_:Lerp(P.nebuleuse, 0.4) end
			return P.bleu:Lerp(P.orPale, 0.35)
		end,
		galerie = P.bleu:Lerp(P.orPale, 0.45),
		lum = 0.55,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "NeantEtoile")
end

return GrotteAstres
