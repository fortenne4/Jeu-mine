--[[ Grotte −500 m « Le Cœur maudit » (palier 5, boss : l'Exécuteur maudit) : habillage complet.
	Le fond du monde. Ce que les nains de Brumefer ont réveillé en creusant trop profond bat encore ici.
	- Dernier camp d'une expédition à l'arrivée : tentes déchirées, barricade, lanternes maudites, ossements
	- LE VIDE SUSPENDU : la plus grande salle s'effondre dans un gouffre sans fond ; des dalles de pierre
	  mènent à un pilier central ; des rochers flottent dans le vide (animés), lueur violette d'en bas
	- Failles du vide : anneaux sombres dressés qui aspirent la poussière lumineuse
	- Cristaux corrompus (verre noir, cœur magenta) en grappes, runes maudites gravées aux parois
	- Esprits errants (feux follets violets qui flottent), chaînes qui pendent, ossements
	- Salle du boss : L'ARÈNE DU CŒUR — un cœur de cristal géant, enchaîné à la voûte, bat au-dessus du
	  combat ; huit piliers d'obsidienne aux flammes violettes, cercle de runes, brume maudite
	Zones : Camp, Vide, Coeur. ]]

local GT = require(script.Parent.GrotteTheme)
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local GrotteCoeur = {}

local P = {
	magenta = Color3.fromRGB(230, 60, 220),
	violet = Color3.fromRGB(150, 60, 255),
	violetSombre = Color3.fromRGB(40, 14, 60),
	noir = Color3.fromRGB(18, 12, 24),
	obsidienne = Color3.fromRGB(26, 18, 34),
	os = Color3.fromRGB(214, 204, 186),
	toile = Color3.fromRGB(110, 96, 80),
	esprit = Color3.fromRGB(190, 150, 255),
	pierre = Color3.fromRGB(58, 50, 66),
	rouge = Color3.fromRGB(200, 30, 60),
}

local COUL_GENERIQUE = {
	Roche = {Color3.fromRGB(44, 34, 54), Enum.Material.Basalt},
	Goutte = {P.esprit, Enum.Material.Neon, 0.4},
	Lueur = {P.magenta, Enum.Material.Neon},
}

function GrotteCoeur.decorer(ctx, infos, outils)
	local T = GT.nouveau(ctx, infos, outils)
	local rng, decor, M = T.rng, T.decor, T.M
	local depart, boss = T.depart, T.boss
	local salles, galeries = T.salles, T.galeries
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
	local vide = T.salleFosse(candidates)
	local roles = {}

	-- cristal corrompu : prisme de verre noir, cœur magenta
	local function cristal(parent, base: CFrame, h: number, couleur: Color3)
		local l = h * rng:NextNumber(0.2, 0.28)
		for k = 0, 1 do
			local b = T.bloc(parent, Vector3.new(l, h * 0.8, l), base * CFrame.new(0, h * 0.4, 0) * CFrame.Angles(0, k * math.pi / 4, 0), P.noir, Enum.Material.SmoothPlastic, "Cristal")
			b.Transparency, b.Reflectance, b.CastShadow = 0, 0.35, false
		end
		for k = 0, 3 do
			T.coin(parent, Vector3.new(l, h * 0.2, l * 0.5), base * CFrame.new(0, h * 0.9, 0) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 8, 0) * CFrame.new(0, 0, l * 0.25),
				P.noir, Enum.Material.SmoothPlastic, "Pointe").CastShadow = false
		end
		local c = T.bloc(parent, Vector3.new(l * 0.25, h * 0.7, l * 0.25), base * CFrame.new(0, h * 0.42, 0), couleur, M.Neon, "Coeur")
		c.CastShadow = false
		T.tag(c, "GrottePulse")
	end
	local function grappe(base: CFrame, taille: number)
		local m = T.modele("CristauxCorrompus")
		for k = 1, rng:NextInteger(3, 6) do
			cristal(m, base * CFrame.new(rng:NextNumber(-1, 1) * taille * 0.3, -0.3, rng:NextNumber(-1, 1) * taille * 0.3)
				* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6), rng:NextNumber(-0.5, 0.5)), taille * rng:NextNumber(0.5, 1), if k % 2 == 0 then P.magenta else P.violet)
		end
		return m
	end
	local function crane(pos: Vector3, s: number)
		local m = T.modele("Crane")
		T.boule(m, Vector3.new(1, 0.9, 1.1) * s, CFrame.new(pos + Vector3.new(0, 0.4 * s, 0)), P.os, M.Lisse, "Crane")
		for _, x in {-0.22, 0.22} do
			T.boule(m, Vector3.new(0.25, 0.25, 0.1) * s, CFrame.new(pos + Vector3.new(x * s, 0.45 * s, -0.52 * s)), P.noir, M.Lisse, "Orbite")
		end
		return m
	end
	-- esprit errant : orbe violet qui flotte (animé par VieGrotte)
	local nEsprits = 0
	local function esprit(pos: Vector3)
		nEsprits += 1
		local m = T.modele("EspritErrant")
		local o = T.boule(m, Vector3.one * 0.9, CFrame.new(pos), P.esprit, M.Neon, "Orbe")
		o.Transparency = 0.2
		T.emetteur(o, {
			Name = "Trainee", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.esprit, P.violet),
			Size = NumberSequence.new({T.kp(0, 0.8), T.kp(1, 0)}), Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(1, 2),
			Rate = 10, Speed = NumberRange.new(0.2, 0.6), Acceleration = Vector3.new(0, 1.2, 0),
		})
		if nEsprits % 3 == 0 then
			T.remplir(o, P.violet, 0.6, 14)
		end
		m.PrimaryPart = o
		m:SetAttribute("Origine", pos)
		T.tag(m, "GrotteMeduse")
	end

	-- ===== 1. Dernier camp d'une expédition =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local m = T.modele("DernierCamp")
		-- barricade de planches en travers (sur les côtés, le passage reste libre)
		for _, sx in {-1, 1} do
			local q = T.solEn(depart.p + avant * 14 + droite * sx * 7)
			if q then
				local cf = CFrame.lookAt(q.Position, q.Position + avant)
				for k = 0, 4 do
					T.bloc(m, Vector3.new(6, 0.5, 0.4), cf * CFrame.new(0, 0.8 + k * 0.9, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.2, 0.2)), Color3.fromRGB(70, 50, 36), M.Bois, "Planche")
				end
				for _, x in {-2.6, 2.6} do
					T.bloc(m, Vector3.new(0.5, 5.2, 0.5), cf * CFrame.new(x, 2.6, 0.3), Color3.fromRGB(60, 42, 30), M.Bois, "Piquet")
				end
			end
		end
		-- tente déchirée
		local qT = T.solEn(depart.p - droite * 13 - avant * 2)
		if qT then
			local cf = CFrame.lookAt(qT.Position, qT.Position + droite)
			T.coin(m, Vector3.new(5, 4, 3), cf * CFrame.new(0, 2, -1.5), P.toile, Enum.Material.Fabric, "Toile")
			T.coin(m, Vector3.new(5, 4, 3), cf * CFrame.new(0, 2, 1.5) * CFrame.Angles(0, math.pi, 0), P.toile, Enum.Material.Fabric, "Toile").Transparency = 0.3
		end
		-- lanternes maudites et ossements
		for k = 1, 3 do
			local q = T.solEn(depart.p + avant * rng:NextNumber(4, 10) + droite * rng:NextNumber(-12, 12))
			if q and (q.Position - depart.p).Magnitude > 8 then
				crane(q.Position, rng:NextNumber(0.8, 1.2))
			end
		end
		T.zone(depart.p, 34, P.esprit:Lerp(P.os, 0.4), "Camp")
	end

	-- ===== 2. LE VIDE SUSPENDU =====
	if vide then
		local fosse = T.fosse(vide, {
			profondeur = 60, pilier = 6,
			pont = function(u, d0, d1, yA, yB)
				-- dalles de pierre espacées qui flottent au-dessus du vide
				local c = vide.p
				local pente = math.atan2(yB - yA, d1 - d0)
				local m = T.modele("DallesVide")
				local d = d0
				local k = 0
				while d <= d1 do
					k += 1
					local t = (d - d0) / (d1 - d0)
					local q = Vector3.new(c.X, yA + (yB - yA) * t - 0.4, c.Z) + u * d
					T.solide(m, Vector3.new(4.6, 0.8, 2.4), CFrame.lookAt(q, q + u) * CFrame.Angles(pente, rng:NextNumber(-0.06, 0.06), rng:NextNumber(-0.04, 0.04)),
						if k % 2 == 0 then P.pierre else P.pierre:Lerp(P.violetSombre, 0.4), Enum.Material.Slate, "Dalle")
					local rune = T.bloc(m, Vector3.new(0.9, 0.1, 0.9), CFrame.lookAt(q + Vector3.new(0, 0.42, 0), q + Vector3.new(0, 0.42, 0) + u) * CFrame.Angles(0, math.rad(45), 0), P.violet, M.Neon, "Rune")
					rune.CastShadow = false
					d += 2.6
				end
			end,
		})
		if fosse then
			roles[vide] = "vide"
			local c = fosse.c
			-- lueur violette qui monte du fond
			local fond = T.volume(decor, Vector3.new(fosse.f * 1.8, 2, fosse.f * 1.8), CFrame.new(c.X, fosse.fond + 6, c.Z), "LueurAbysse")
			T.lumiere(fond, P.violet, 3, 60)
			T.emetteur(fond, {
				Name = "Ames", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.esprit, P.magenta),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.6), T.kp(1, 0)}), Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(4, 8),
				SpreadAngle = Vector2.new(10, 10), Rate = 18, EmissionDirection = Enum.NormalId.Top, Shape = Enum.ParticleEmitterShape.Box,
			})
			local brume = T.cylindre(decor, 1, fosse.f * 2, CFrame.new(c.X, fosse.fond + 10, c.Z), P.violetSombre, M.Neon, "BrumeAbysse")
			brume.Transparency = 0.86
			brume.CastShadow = false
			-- rochers qui flottent dans le vide
			for k = 1, 7 do
				local a = rng:NextNumber(0, 2 * math.pi)
				local r = rng:NextNumber(fosse.pilier + 4, fosse.f - 3)
				local pos = c + Vector3.new(math.cos(a) * r, rng:NextNumber(-12, 6), math.sin(a) * r)
				local m = T.modele("RocherFlottant")
				local s = rng:NextNumber(2.5, 5.5)
				local roc = T.boule(m, Vector3.new(s * 1.4, s, s * 1.2), CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0), P.pierre, Enum.Material.Slate, "Roc")
				T.coin(m, Vector3.new(s, s * 1.4, s * 0.8), CFrame.new(pos - Vector3.new(0, s * 0.8, 0)) * CFrame.Angles(math.pi, rng:NextNumber(0, 6), 0), P.pierre, Enum.Material.Slate, "Racine")
				local dessous = T.boule(m, Vector3.new(s * 0.8, 0.3, s * 0.7), CFrame.new(pos - Vector3.new(0, s * 0.45, 0)), P.violet, M.Neon, "Lueur")
				dessous.Transparency = 0.3
				if k % 2 == 0 then
					grappe(CFrame.new(pos + Vector3.new(0, s * 0.4, 0)), 2).Parent = m
				end
				m.PrimaryPart = roc
				m:SetAttribute("Origine", pos)
				T.tag(m, "GrotteMeduse")
			end
			-- obélisque maudit sur le pilier
			local ob = T.modele("ObeliskeMaudit")
			for k = 0, 1 do
				T.bloc(ob, Vector3.new(2, 11, 2), CFrame.new(c + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, k * math.pi / 4, 0), P.obsidienne, Enum.Material.SmoothPlastic, "Obelisque").Reflectance = 0.25
			end
			for k = 1, 4 do
				T.bloc(ob, Vector3.new(0.15, 1.4, 2.1), CFrame.new(c + Vector3.new(0, k * 2.2, 0)) * CFrame.Angles(0, k * 0.8, 0), P.magenta, M.Neon, "Glyphe").CastShadow = false
			end
			T.zone(c, fosse.f + 12, P.violet, "Vide")
		end
	end

	-- ===== 3. Failles du vide, cristaux corrompus, runes, esprits =====
	local nFailles = 0
	for _, s in salles do
		if not s.depart and not s.boss and roles[s] ~= "vide" and nFailles < 3 and s.r >= 12 then
			local q0, dir = T.coinSalle(s, s.r * 0.6)
			local sol = T.solEn(q0)
			if sol and T.solLibre(sol.Position, 3, 6) then
				nFailles += 1
				local cf = CFrame.lookAt(sol.Position + Vector3.new(0, 5.5, 0), sol.Position + Vector3.new(0, 5.5, 0) - dir)
				local m = T.modele("FailleDuVide")
				local anneau = T.disque(m, 0.5, 9, cf * CFrame.Angles(0, math.pi / 2, 0), P.magenta, M.Neon, "Bord")
				anneau.CastShadow = false
				local coeur = T.disque(m, 0.6, 8, cf * CFrame.Angles(0, math.pi / 2, 0), P.noir, M.Neon, "Vide")
				coeur.CastShadow = false
				T.tag(anneau, "GrottePulse")
				-- poussière aspirée : émise autour, vitesse négative vers le centre
				local aspi = T.volume(m, Vector3.new(14, 14, 1), cf, "Aspiration")
				T.emetteur(aspi, {
					Name = "Aspiration", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.esprit, P.magenta),
					Size = NumberSequence.new({T.kp(0, 0.3), T.kp(1, 0)}), Lifetime = NumberRange.new(1.2, 1.6), Speed = NumberRange.new(-5, -4),
					Rate = 30, Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
					ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
				})
				T.lumiere(anneau, P.magenta, 1.5, 24)
				for _ = 1, 4 do
					local qc = T.solEn(sol.Position + Vector3.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-6, 6)))
					if qc and T.solLibre(qc.Position, 1, 4) then
						grappe(CFrame.new(qc.Position), rng:NextNumber(1.5, 3))
					end
				end
				T.interdire(sol.Position, 6)
			end
		end
	end
	for _ = 1, 22 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 7), pt.r + 6)
		if hit and (hit.Position - depart.p).Magnitude > 20 then
			if rng:NextNumber() < 0.6 then
				grappe(outils.axeVers(hit.Position - hit.Normal * 0.4, hit.Normal), rng:NextNumber(1.2, 2.6))
			else
				-- rune maudite gravée : trois traits néon dans la paroi
				local cf = CFrame.lookAt(hit.Position + hit.Normal * 0.1, hit.Position + hit.Normal)
				local m = T.modele("RuneMaudite")
				for k = -1, 1 do
					T.bloc(m, Vector3.new(0.2, 2.2, 0.1), cf * CFrame.new(k * 0.7, 0, 0) * CFrame.Angles(0, 0, k * 0.5), P.magenta, M.Neon, "Trait").CastShadow = false
				end
				T.bloc(m, Vector3.new(2, 0.2, 0.1), cf * CFrame.new(0, 0.6, 0), P.magenta, M.Neon, "Trait").CastShadow = false
			end
		end
	end
	for _, s in salles do
		if not s.depart and nEsprits < 12 then
			for _ = 1, (if s.r >= 18 then 2 else 1) do
				local a = rng:NextNumber(0, 2 * math.pi)
				local sol = T.solEn(s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.2, 0.6), 8)
				if sol then
					esprit(sol.Position + Vector3.new(0, rng:NextNumber(5, 9), 0))
				end
			end
			T.particulesSalle(s, {
				Name = "Spores", Texture = GT.TEX_LUEUR, LightEmission = 1, Color = ColorSequence.new(P.esprit, P.magenta),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.18), T.kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 10,
				Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Top,
			})
		end
	end
	-- ossements le long des galeries
	for _ = 1, 16 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.7, 0.9))
		if q and T.solLibre(q.Position, 1, 3) then
			crane(q.Position, rng:NextNumber(0.7, 1.1))
			for _ = 1, 3 do
				T.bloc(decor, Vector3.new(0.25, 0.25, rng:NextNumber(1.2, 2.2)), CFrame.new(q.Position + Vector3.new(rng:NextNumber(-1.4, 1.4), 0.15, rng:NextNumber(-1.4, 1.4)))
					* CFrame.Angles(0, rng:NextNumber(0, 6), 0), P.os, M.Lisse, "Os")
			end
		end
	end

	-- ===== 4. L'ARÈNE DU CŒUR (salle du boss) =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local haut = T.plafondEn(c + Vector3.new(0, 2, 0), 90)
		local yH = if haut then haut.Position.Y else y0 + 40
		local yCoeur = math.min(y0 + 26, yH - 9)
		local m = T.modele("ArèneDuCoeur")
		-- le cœur de cristal
		local coeur = T.modele("CoeurMaudit", m)
		local pc = Vector3.new(c.X, yCoeur, c.Z)
		local noyau = T.boule(coeur, Vector3.new(6, 7.5, 6), CFrame.new(pc), P.rouge, M.Neon, "Noyau")
		noyau.CastShadow = false
		T.tag(noyau, "GrottePulse")
		local coque = T.boule(coeur, Vector3.new(8, 10, 8), CFrame.new(pc), P.violetSombre, Enum.Material.SmoothPlastic, "Coque")
		coque.Transparency, coque.CastShadow = 0.35, false
		for k = 1, 8 do
			cristal(coeur, CFrame.new(pc) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)) * CFrame.new(0, 3.5, 0), rng:NextNumber(3, 5), P.magenta)
		end
		T.lumiere(noyau, P.rouge, 3, 60)
		T.emetteur(noyau, {
			Name = "Pulsation", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.rouge, P.magenta),
			Size = NumberSequence.new({T.kp(0, 4), T.kp(1, 12)}), Transparency = NumberSequence.new({T.kp(0, 0.6), T.kp(1, 1)}),
			Lifetime = NumberRange.new(1, 1), Rate = 1.2, Speed = NumberRange.new(0), LockedToPart = true,
		})
		-- six chaînes qui le retiennent à la voûte (une casse à chaque phase du boss : MecaniquesGrotte)
		for k = 0, 5 do
			local a = k / 6 * 2 * math.pi
			local ancre = Vector3.new(c.X + math.cos(a) * 14, yH, c.Z + math.sin(a) * 14)
			local depuis = pc + Vector3.new(math.cos(a) * 3, 3, math.sin(a) * 3)
			local L = (ancre - depuis).Magnitude
			local n = math.floor(L / 1.6)
			local dir = (ancre - depuis).Unit
			local chaine = T.modele("ChaineCoeur", m)
			chaine:SetAttribute("Numero", k + 1)
			for i = 0, n do
				local q = depuis + dir * (i * 1.6)
				T.bloc(chaine, Vector3.new(0.4, 0.9, 1.9), CFrame.lookAt(q, q + dir) * CFrame.Angles(0, 0, (i % 2) * math.pi / 2), P.obsidienne, M.Metal, "Maillon").CastShadow = false
			end
		end
		coeur:SetAttribute("Centre", pc)
		ctx.modele:SetAttribute("ArenaCoeur", c)
		-- runes brûlantes : failles violettes dans l'arène, endormies jusqu'à la 2e phase du boss
		for k = 0, 5 do
			local a = k / 6 * 2 * math.pi + math.pi / 6
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * rng:NextNumber(0.32, 0.5))
			if q then
				local rune = T.cylindre(m, 0.15, 3.6, CFrame.new(q.Position + Vector3.new(0, 0.05, 0)), P.violetSombre, M.Neon, "RuneBrulante")
				rune.CastShadow = false
				rune:SetAttribute("Inactif", true)
				rune:SetAttribute("Periode", 6)
				rune:SetAttribute("Duree", 1.5)
				rune:SetAttribute("Decalage", k * 1.1)
				rune:SetAttribute("Couleur", P.magenta)
				T.tag(rune, "Geyser")
			end
		end
		-- huit piliers d'obsidienne aux flammes violettes
		for k = 0, 7 do
			local a = k / 8 * 2 * math.pi + math.pi / 8
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.78)
			if q and T.libre(q.Position, 1) then
				local col = T.modele("PilierMaudit", m)
				for j = 0, 1 do
					T.bloc(col, Vector3.new(2.4, 12, 2.4), CFrame.new(q.Position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, j * math.pi / 4 + a, 0), P.obsidienne, Enum.Material.SmoothPlastic, "Pilier").Reflectance = 0.25
				end
				local flamme = T.bloc(col, Vector3.new(1.2, 0.6, 1.2), CFrame.new(q.Position + Vector3.new(0, 12.4, 0)), P.violet, M.Neon, "Braise")
				T.emetteur(flamme, {
					Name = "FlammeViolette", Texture = GT.TEX_FEU, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.esprit, P.violet),
					Size = NumberSequence.new({T.kp(0, 1.8), T.kp(1, 0.3)}), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(3, 5),
					Rate = 26, EmissionDirection = Enum.NormalId.Top,
				})
				if k % 2 == 0 then
					T.lumiere(flamme, P.violet, 1.3, 26)
				end
			end
		end
		-- cercle de runes au sol
		for k = 0, 31 do
			local a = k / 32 * 2 * math.pi
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.55)
			if q then
				local r = T.bloc(m, Vector3.new(0.25, 0.08, 2.4), CFrame.lookAt(q.Position + Vector3.new(0, 0.06, 0), q.Position + Vector3.new(0, 0.06, 0) + Vector3.new(-math.sin(a), 0, math.cos(a))),
					P.magenta, M.Neon, "CercleRunes")
				r.Transparency, r.CastShadow = 0.2, false
			end
		end
		local brume = T.volume(m, Vector3.new(T.rb * 1.6, 3, T.rb * 1.6), CFrame.new(c + Vector3.new(0, 1.5, 0)), "BrumeMaudite")
		T.emetteur(brume, {
			Name = "Brume", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.violetSombre:Lerp(P.violet, 0.3)), LightInfluence = 0.3, LightEmission = 0.2,
			Size = NumberSequence.new(5, 10), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.75), T.kp(1, 1)}),
			Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.3, 0.8), Rate = 6, Shape = Enum.ParticleEmitterShape.Box,
		})
		T.zone(c, T.rb + 8, P.rouge:Lerp(P.violet, 0.5), "Coeur")
	end

	-- ===== 5. Décor générique, veines maudites, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, champignons = false, humide = false,
		mine = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.magenta, P.violet, P.magenta, P.rouge}, 4, P.violet)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.esprit:Lerp(P.os, 0.5) end
			if roles[s] == "vide" then return P.violet:Lerp(P.esprit, 0.4) end
			if s.boss then return P.rouge:Lerp(P.violet, 0.5) end
			return P.violet:Lerp(P.esprit, 0.5)
		end,
		galerie = P.esprit:Lerp(P.os, 0.3),
		lum = 0.5,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "CoeurMaudit")
end

return GrotteCoeur
