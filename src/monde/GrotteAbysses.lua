--[[ Grotte −900 m « La Cité engloutie » (palier 7, Abysses engloutis, boss : le Léviathan des abysses, BossProfondeurs).
	Une mer souterraine s'est retirée d'ici il y a mille ans. Elle a laissé une cité de pierre blanche, ses
	récifs, ses méduses qui flottent encore dans l'air humide… et ce qui dormait au fond.
	- Cloche de plongée à l'arrivée : cloche de cuivre à hublots, scaphandre, ancre, cordages, caisses
	- LE GOUFFRE ABYSSAL : la plus grande salle s'ouvre sur un puits plein d'eau noire ; dalles de pierre
	  blanche sur des pieux de corail jusqu'à un pilier où se dresse la statue du dieu-poisson (trident, yeux
	  lumineux) ; méduses géantes au-dessus du vide, bulles qui remontent, lueur turquoise d'en bas
	- LA CITÉ ENGLOUTIE : colonnes brisées, arches, escaliers, dallages, amphores, couverts d'algues
	- LE RÉCIF : coraux branchus lumineux, anémones, grandes algues, bénitiers géants ; sources chaudes
	  (cheminées hydrothermales orange) qui crachent des bulles
	- Partout : méduses qui flottent, plancton lumineux, flaques d'eau et roche couverte d'algues
	- Salle du fond : LE SANCTUAIRE DU LÉVIATHAN — squelette géant (colonne vertébrale, côtes, crâne aux yeux
	  vivants) contre la paroi, perle géante dans un bénitier sur l'autel, colonnes brisées en cercle
	Zones : Camp, Gouffre, Cite, Recif, Leviathan. Attributs : Theme = "CiteEngloutie", ArenaLeviathan. ]]

local GT = require(script.Parent.GrotteTheme)

local GrotteAbysses = {}

local rgb = Color3.fromRGB
local CALCAIRE = Enum.Material.Limestone

local P = {
	turquoise = rgb(60, 230, 200),
	cyan = rgb(90, 220, 255),
	abysse = rgb(6, 40, 56),
	pierre = rgb(196, 200, 186),
	pierreSombre = rgb(120, 136, 132),
	algue = rgb(40, 140, 100),
	algueClaire = rgb(110, 220, 140),
	corailRose = rgb(255, 110, 160),
	corailOrange = rgb(255, 150, 70),
	corailViolet = rgb(170, 110, 255),
	cuivre = rgb(184, 110, 60),
	cuivreVert = rgb(80, 160, 130),
	perle = rgb(240, 236, 255),
	os = rgb(220, 214, 196),
	chaud = rgb(255, 130, 50),
	bois = rgb(80, 60, 44),
}

local COUL_GENERIQUE = {
	Roche = {rgb(120, 150, 150), CALCAIRE},
	Goutte = {P.turquoise, Enum.Material.Glass, 0.3},
	Lueur = {P.turquoise, Enum.Material.Neon},
	Chapeau = {P.corailViolet, Enum.Material.SmoothPlastic},
	Pied = {rgb(200, 220, 210), Enum.Material.SmoothPlastic},
}

function GrotteAbysses.decorer(ctx, infos, outils)
	local T = GT.nouveau(ctx, infos, outils)
	local rng, decor, M = T.rng, T.decor, T.M
	local depart, boss = T.depart, T.boss
	local salles = T.salles
	local plat, unite = T.plat, T.unite
	local terrain = workspace.Terrain

	local candidates = {}
	for _, s in salles do
		if not s.depart and not s.boss and s.r >= 15 then
			table.insert(candidates, s)
		end
	end
	table.sort(candidates, function(a, b)
		return a.r > b.r
	end)
	local gouffre = T.salleFosse(candidates)
	local roles = {}

	local function sansOmbre(p: BasePart, t: number?): BasePart
		p.CastShadow = false
		if t then p.Transparency = t end
		return p
	end
	-- corail branchu : tronc et branches qui se divisent, bouts lumineux
	local function corail(pos: Vector3, h: number, couleur: Color3)
		local m = T.modele("Corail")
		local function branche(base: CFrame, l: number, ep: number, n: number)
			T.bloc(m, Vector3.new(ep, l, ep), base * CFrame.new(0, l / 2, 0), couleur, M.Lisse, "Branche").CastShadow = false
			local bout = base * CFrame.new(0, l, 0)
			if n <= 0 then
				sansOmbre(T.boule(m, Vector3.one * ep * 1.6, bout, couleur:Lerp(Color3.new(1, 1, 1), 0.3), M.Neon, "Bout"))
				return
			end
			for k = 1, 2 do
				branche(bout * CFrame.Angles(rng:NextNumber(-0.7, 0.7), k * math.pi + rng:NextNumber(-0.5, 0.5), rng:NextNumber(0.3, 0.7) * (if k == 1 then 1 else -1)), l * 0.7, ep * 0.75, n - 1)
			end
		end
		branche(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), h * 0.4, h * 0.12, 2)
		return m
	end
	-- anémone : pied et couronne de tentacules lumineux
	local function anemone(pos: Vector3, s: number, couleur: Color3)
		local m = T.modele("Anemone")
		T.cylindre(m, 0.8 * s, 1 * s, CFrame.new(pos + Vector3.new(0, 0.4 * s, 0)), couleur:Lerp(Color3.new(), 0.4), M.Lisse, "Pied")
		for k = 0, 7 do
			local a = k / 8 * 2 * math.pi
			T.bloc(m, Vector3.new(0.15, 0.9, 0.15) * s, CFrame.new(pos + Vector3.new(math.cos(a) * 0.35 * s, 1.1 * s, math.sin(a) * 0.35 * s))
				* CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), couleur, M.Neon, "Tentacule").CastShadow = false
		end
	end
	-- grande algue : segments qui ondulent légèrement vers le haut
	local function algue(pos: Vector3, h: number)
		local m = T.modele("Algue")
		local cf = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
		local n = math.max(3, math.floor(h / 1.6))
		for k = 1, n do
			local seg = T.bloc(m, Vector3.new(0.7, 1.7, 0.1), cf * CFrame.new(0, 0.8, 0), if k % 2 == 0 then P.algue else P.algueClaire:Lerp(P.algue, 0.5), M.Lisse, "Feuille")
			seg.CastShadow = false
			cf = cf * CFrame.new(0, 1.6, 0) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.15, 0.15))
		end
	end
	-- bénitier géant (deux valves entrouvertes), perle optionnelle
	local function benitier(pos: Vector3, s: number, face: Vector3, perle: boolean?)
		local m = T.modele("Benitier")
		local cf = CFrame.lookAt(pos, pos + face)
		T.boule(m, Vector3.new(3, 1, 2.2) * s, cf * CFrame.new(0, 0.4 * s, 0), P.pierre:Lerp(P.corailViolet, 0.2), M.Lisse, "Valve")
		T.boule(m, Vector3.new(3, 1, 2.2) * s, cf * CFrame.new(0, 1.2 * s, 0.5 * s) * CFrame.Angles(-0.7, 0, 0), P.pierre:Lerp(P.corailViolet, 0.3), M.Lisse, "Valve")
		sansOmbre(T.boule(m, Vector3.new(2.4, 0.5, 1.6) * s, cf * CFrame.new(0, 0.7 * s, 0), P.corailViolet, M.Neon, "Chair"), 0.2)
		local pr = nil
		if perle then
			pr = sansOmbre(T.boule(m, Vector3.one * 1.1 * s, cf * CFrame.new(0, 1.2 * s, -0.1 * s), P.perle, M.Neon, "Perle"))
			T.tag(pr, "GrottePulse")
		end
		return m, pr
	end
	-- méduse : ombrelle translucide, cœur lumineux, tentacules (flotte : VieGrotte, tag GrotteMeduse)
	local nMeduses = 0
	local function meduse(pos: Vector3, s: number, couleur: Color3)
		nMeduses += 1
		local m = T.modele("Meduse")
		local ombrelle = sansOmbre(T.boule(m, Vector3.new(2.6, 1.6, 2.6) * s, CFrame.new(pos), couleur, M.Neon, "Ombrelle"), 0.45)
		sansOmbre(T.boule(m, Vector3.new(1.2, 0.8, 1.2) * s, CFrame.new(pos - Vector3.new(0, 0.1 * s, 0)), Color3.new(1, 1, 1), M.Neon, "Coeur"), 0.2)
		for k = 0, 5 do
			local a = k / 6 * 2 * math.pi
			local L = rng:NextNumber(2.5, 4.5) * s
			sansOmbre(T.bloc(m, Vector3.new(0.1, L, 0.1) * Vector3.new(s, 1, s), CFrame.new(pos + Vector3.new(math.cos(a) * 0.8 * s, -L / 2 - 0.4 * s, math.sin(a) * 0.8 * s)),
				couleur, M.Neon, "Tentacule"), 0.35)
		end
		if nMeduses % 3 == 1 then T.remplir(ombrelle, couleur, 0.6, 16) end
		m.PrimaryPart = ombrelle
		m:SetAttribute("Origine", pos)
		T.tag(m, "GrotteMeduse")
		return m
	end
	-- colonne de pierre blanche (brisée ou entière), chapiteau, algues
	local function colonne(pos: Vector3, h: number, cassee: boolean)
		local m = T.modele("Colonne")
		T.bloc(m, Vector3.new(3.2, 0.8, 3.2), CFrame.new(pos + Vector3.new(0, 0.4, 0)), P.pierreSombre, CALCAIRE, "Socle")
		local hf = if cassee then h * rng:NextNumber(0.35, 0.7) else h
		T.cylindre(m, hf, 2.4, CFrame.new(pos + Vector3.new(0, 0.8 + hf / 2, 0)), P.pierre, CALCAIRE, "Fut")
		for k = 0, 3 do
			T.bloc(m, Vector3.new(0.25, hf * 0.9, 0.25), CFrame.new(pos + Vector3.new(0, 0.8 + hf / 2, 0)) * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0, 1.15), P.pierreSombre, CALCAIRE, "Cannelure")
		end
		if cassee then
			T.coin(m, Vector3.new(2.4, 0.9, 2.4), CFrame.new(pos + Vector3.new(0, 0.8 + hf + 0.45, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), P.pierre, CALCAIRE, "Cassure")
		else
			T.bloc(m, Vector3.new(3.4, 1, 3.4), CFrame.new(pos + Vector3.new(0, 0.8 + hf + 0.5, 0)), P.pierreSombre, CALCAIRE, "Chapiteau")
		end
		sansOmbre(T.boule(m, Vector3.new(2.8, 0.6, 2.8), CFrame.new(pos + Vector3.new(0, 0.8 + hf * rng:NextNumber(0.3, 0.8), 0)), P.algue, M.Lisse, "Algues"), 0.1)
		return m
	end

	-- ===== 1. La cloche de plongée (arrivée) =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local m = T.modele("ClochePlongee")
		local qC = T.solEn(depart.p - droite * 12 + avant * 2)
		if qC then
			local c = qC.Position
			T.cylindre(m, 4.2, 5, CFrame.new(c + Vector3.new(0, 2.1, 0)), P.cuivre, M.Metal, "Cloche")
			T.boule(m, Vector3.new(5, 3.4, 5), CFrame.new(c + Vector3.new(0, 4.2, 0)), P.cuivre, M.Metal, "Dome")
			T.cylindre(m, 0.6, 5.4, CFrame.new(c + Vector3.new(0, 0.3, 0)), P.cuivreVert, M.Metal, "Cerclage")
			T.cylindre(m, 1.2, 0.8, CFrame.new(c + Vector3.new(0, 6.2, 0)), P.cuivreVert, M.Metal, "Anneau")
			for k = 0, 2 do
				local a = k / 3 * 2 * math.pi + math.pi / 6
				local u = Vector3.new(math.cos(a), 0, math.sin(a))
				local hub = sansOmbre(T.disque(m, 0.3, 1.5, CFrame.lookAt(c + u * 2.5 + Vector3.new(0, 2.6, 0), c + u * 4 + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, math.pi / 2, 0),
					P.turquoise, M.Neon, "Hublot"))
				if k == 0 then T.lumiere(hub, P.turquoise, 1, 20) end
			end
			-- cordages enroulés
			for k = 0, 2 do
				T.cylindre(m, 0.35, 2.4 - k * 0.3, CFrame.new(c + droite * 4 + Vector3.new(0, 0.2 + k * 0.35, 0)), rgb(170, 140, 90), M.Tissu, "Corde")
			end
		end
		-- scaphandre posé sur une caisse, ancre plantée
		local qS = T.solEn(depart.p + droite * 11 + avant * 4)
		if qS then
			local c = qS.Position
			T.bloc(m, Vector3.new(2, 1.6, 2), CFrame.new(c + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0.3, 0), P.bois, M.Planches, "Caisse")
			T.boule(m, Vector3.new(1.8, 1.8, 1.8), CFrame.new(c + Vector3.new(0, 2.5, 0)), P.cuivre, M.Metal, "Scaphandre")
			sansOmbre(T.disque(m, 0.2, 1, CFrame.new(c + Vector3.new(0, 2.5, -0.85)) * CFrame.Angles(0, math.pi / 2, 0), P.cyan, Enum.Material.Glass, "Visiere"), 0.3)
			local qA = c + droite * 3 - avant * 2
			T.bloc(m, Vector3.new(0.5, 5, 0.5), CFrame.new(qA + Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, 0.15), P.cuivreVert:Lerp(P.pierreSombre, 0.5), M.Rouille, "Verge")
			T.bloc(m, Vector3.new(3.4, 0.5, 0.5), CFrame.new(qA + Vector3.new(0.3, 4.4, 0)) * CFrame.Angles(0, 0, 0.15), P.cuivreVert:Lerp(P.pierreSombre, 0.5), M.Rouille, "Jas")
			for _, x in {-1, 1} do
				T.coin(m, Vector3.new(0.5, 1.4, 1.2), CFrame.new(qA + Vector3.new(x * 1.2, 0.5, 0)) * CFrame.Angles(0, math.pi / 2 * x, 0), P.cuivreVert:Lerp(P.pierreSombre, 0.5), M.Rouille, "Patte")
			end
		end
		T.zone(depart.p, 34, rgb(255, 210, 150):Lerp(P.turquoise, 0.3), "Camp")
	end

	-- ===== 2. LE GOUFFRE ABYSSAL =====
	if gouffre then
		local fosse = T.fosse(gouffre, {
			profondeur = 50, pilier = 6, couleurDalle = P.pierre, materiauDalle = CALCAIRE, couleurBord = P.pierreSombre, couleurPoteau = P.cuivreVert,
			pont = function(u, d0, d1, yA, yB)
				T.pontPlanches(gouffre.p, u, d0, d1, yA, yB, {planche = P.pierre, planche2 = P.pierreSombre, materiau = CALCAIRE,
					poteau = P.corailRose:Lerp(P.pierreSombre, 0.4), materiauPoteau = M.Lisse, chaine = P.algue})
			end,
		})
		if fosse then
			roles[gouffre] = "gouffre"
			local c = fosse.c
			-- eau noire au fond du puits (le pilier est refait par-dessus)
			terrain:FillCylinder(CFrame.new(c.X, fosse.fond + 5, c.Z), 10, fosse.f + 2, Enum.Material.Water)
			fosse.refaire()
			local fond = T.volume(decor, Vector3.new(fosse.f * 1.6, 2, fosse.f * 1.6), CFrame.new(c.X, fosse.fond + 11, c.Z), "LueurAbysse")
			T.lumiere(fond, P.turquoise, 2.5, 60)
			T.emetteur(fond, {
				Name = "Bulles", Texture = GT.TEX_LUEUR, LightEmission = 0.6, LightInfluence = 0, Color = ColorSequence.new(P.cyan, P.perle),
				Size = NumberSequence.new({T.kp(0, 0.15), T.kp(1, 0.5)}), Transparency = NumberSequence.new({T.kp(0, 0.3), T.kp(1, 1)}),
				Lifetime = NumberRange.new(5, 9), Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(8, 8), Rate = 16,
				EmissionDirection = Enum.NormalId.Top, Shape = Enum.ParticleEmitterShape.Box,
			})
			-- statue du dieu-poisson sur le pilier
			local st = T.modele("DieuPoisson")
			local base = CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			T.bloc(st, Vector3.new(2.6, 3, 1.8), base * CFrame.new(0, 1.5, 0), P.pierre, CALCAIRE, "Robe")
			T.bloc(st, Vector3.new(2.2, 2.6, 1.5), base * CFrame.new(0, 4.3, 0), P.pierre, CALCAIRE, "Torse")
			T.coin(st, Vector3.new(1.8, 2.6, 2.6), base * CFrame.new(0, 7, 0) * CFrame.Angles(-math.pi / 2, 0, 0), P.pierreSombre, CALCAIRE, "TetePoisson")
			for _, x in {-0.6, 0.6} do
				sansOmbre(T.boule(st, Vector3.new(0.5, 0.5, 0.5), base * CFrame.new(x, 6.9, -0.9), P.turquoise, M.Neon, "Oeil"))
				T.coin(st, Vector3.new(0.2, 1.6, 1.2), base * CFrame.new(x * 1.8, 7.2, 0.3) * CFrame.Angles(0, 0, x * 0.6), P.algue, M.Lisse, "Nageoire")
			end
			T.bloc(st, Vector3.new(0.3, 9, 0.3), base * CFrame.new(1.5, 4.5, -0.4), P.cuivreVert, M.Metal, "Hampe")
			for k = -1, 1 do
				T.bloc(st, Vector3.new(0.25, 1.6, 0.25), base * CFrame.new(1.5 + k * 0.5, 9.4 - math.abs(k) * 0.2, -0.4), P.cuivreVert, M.Metal, "Dent")
			end
			T.bloc(st, Vector3.new(1.4, 0.25, 0.25), base * CFrame.new(1.5, 8.7, -0.4), P.cuivreVert, M.Metal, "Garde")
			-- méduses géantes au-dessus du vide
			for _ = 1, 4 do
				local a = rng:NextNumber(0, 2 * math.pi)
				local r = rng:NextNumber(fosse.pilier + 5, math.max(fosse.pilier + 6, fosse.f - 3))
				meduse(c + Vector3.new(math.cos(a) * r, rng:NextNumber(6, 14), math.sin(a) * r), rng:NextNumber(1.6, 2.4), if rng:NextNumber() < 0.5 then P.turquoise else P.corailViolet)
			end
			T.zone(c, fosse.f + 12, P.turquoise:Lerp(P.abysse, 0.3), "Gouffre")
		end
	end

	-- ===== 3. LA CITÉ ENGLOUTIE et LE RÉCIF =====
	local reste = {}
	for _, s in candidates do
		if not roles[s] then table.insert(reste, s) end
	end
	local cite, recif = reste[1], reste[2]
	if cite then
		roles[cite] = "cite"
		local m = T.modele("CiteEngloutie")
		local poses = 0
		for _ = 1, 30 do
			if poses >= 9 then break end
			local a, d = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0.35, 0.9) * cite.r
			local hit = T.solEn(cite.p + Vector3.new(math.cos(a), 0, math.sin(a)) * d, 8)
			if hit and T.solLibre(hit.Position, 3, 7) then
				poses += 1
				local q = hit.Position
				local x = rng:NextNumber()
				if x < 0.45 then
					colonne(q, rng:NextNumber(9, 14), rng:NextNumber() < 0.6).Parent = m
				elseif x < 0.65 then
					-- colonne tombée
					local cf = CFrame.new(q + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
					T.disque(m, rng:NextNumber(5, 8), 2.2, cf, P.pierre, CALCAIRE, "Tronçon")
					T.disque(m, 2, 2.2, cf * CFrame.new(rng:NextNumber(4.5, 6), -0.1, 0.8) * CFrame.Angles(0, 0.4, 0), P.pierre, CALCAIRE, "Tronçon")
				elseif x < 0.8 then
					-- escalier qui ne mène nulle part
					local cf = CFrame.new(q) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
					for k = 0, 3 do
						T.bloc(m, Vector3.new(5, 0.8, 1.4), cf * CFrame.new(0, 0.4 + k * 0.8, -k * 1.2), if k % 2 == 0 then P.pierre else P.pierreSombre, CALCAIRE, "Marche")
					end
				else
					-- amphores
					for k = 1, rng:NextInteger(2, 3) do
						local p = q + Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
						local penche = if k == 1 then CFrame.Angles(0, 0, 1.3) * CFrame.new(0, 0.6, 0) else CFrame.identity
						T.boule(m, Vector3.new(1.4, 1.8, 1.4), CFrame.new(p + Vector3.new(0, 0.9, 0)) * penche, P.corailOrange:Lerp(P.pierreSombre, 0.45), M.Lisse, "Amphore")
						T.cylindre(m, 0.7, 0.6, CFrame.new(p + Vector3.new(0, 0.9, 0)) * penche * CFrame.new(0, 1.1, 0), P.corailOrange:Lerp(P.pierreSombre, 0.5), M.Lisse, "Col")
					end
				end
				T.interdire(q, 3)
			end
		end
		-- deux grandes arches contre la paroi
		for _ = 1, 2 do
			local q0, dir = T.coinSalle(cite, cite.r * 0.75)
			local hit = T.solEn(q0, 8)
			if hit and T.libre(hit.Position, 2) then
				local cf = CFrame.lookAt(hit.Position, hit.Position - dir)
				for _, x in {-3.5, 3.5} do
					T.bloc(m, Vector3.new(1.6, 10, 1.6), cf * CFrame.new(x, 5, 0), P.pierre, CALCAIRE, "Pied")
				end
				T.bloc(m, Vector3.new(9.2, 1.4, 2), cf * CFrame.new(0, 10.7, 0), P.pierreSombre, CALCAIRE, "Linteau")
				sansOmbre(T.bloc(m, Vector3.new(0.6, 0.6, 0.15), cf * CFrame.new(0, 10.7, -1.05) * CFrame.Angles(0, 0, math.rad(45)), P.turquoise, M.Neon, "Glyphe"))
				sansOmbre(T.bloc(m, Vector3.new(5.4, 8.4, 0.2), cf * CFrame.new(0, 5.2, 0.6), P.turquoise, M.Neon, "Voile"), 0.85)
				T.interdire(hit.Position, 5)
			end
		end
		T.zone(cite.p, cite.r + 6, P.pierre:Lerp(P.turquoise, 0.5), "Cite")
	end
	if recif then
		roles[recif] = "recif"
		T.zone(recif.p, recif.r + 6, P.corailRose:Lerp(P.turquoise, 0.5), "Recif")
	end

	-- coraux, anémones, algues, bénitiers : dans le récif, et un peu partout au pied des parois
	local couleursCorail = {P.corailRose, P.corailOrange, P.corailViolet, P.turquoise}
	local function semer(centre: Vector3, rayon: number, n: number)
		for _ = 1, n do
			local a, d = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0.3, 0.95) * rayon
			local hit = T.solEn(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * d, 8)
			if hit and T.solLibre(hit.Position, 1.5, 4) then
				local x = rng:NextNumber()
				if x < 0.4 then
					corail(hit.Position, rng:NextNumber(3, 6), couleursCorail[rng:NextInteger(1, #couleursCorail)])
				elseif x < 0.65 then
					anemone(hit.Position, rng:NextNumber(0.8, 1.5), couleursCorail[rng:NextInteger(1, #couleursCorail)])
				elseif x < 0.9 then
					algue(hit.Position, rng:NextNumber(5, 11))
				else
					benitier(hit.Position, rng:NextNumber(0.8, 1.3), Vector3.new(math.cos(a), 0, math.sin(a)))
				end
			end
		end
	end
	if recif then semer(recif.p, recif.r, 26) end
	for _, s in salles do
		if not s.depart and not s.boss and roles[s] ~= "recif" then semer(s.p, s.r, 6) end
	end
	for _ = 1, 24 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.75, 0.92))
		if q and T.solLibre(q.Position, 1, 3) then
			if rng:NextNumber() < 0.5 then
				algue(q.Position, rng:NextNumber(4, 8))
			else
				corail(q.Position, rng:NextNumber(2.5, 4.5), couleursCorail[rng:NextInteger(1, #couleursCorail)])
			end
		end
	end

	-- sources chaudes : cheminées hydrothermales (lueur orange, bulles)
	local nSources = 0
	for _, s in salles do
		if nSources >= 4 then break end
		if not s.depart and not s.boss and roles[s] ~= "gouffre" then
			local q0 = T.coinSalle(s, s.r * 0.55)
			local hit = T.solEn(q0, 8)
			if hit and T.solLibre(hit.Position, 3, 6) then
				nSources += 1
				local m = T.modele("SourceChaude")
				local q = hit.Position
				for k = 0, 2 do
					T.cylindre(m, 1.6, 3.4 - k * 0.9, CFrame.new(q + Vector3.new(0, 0.8 + k * 1.5, 0)) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, rng:NextNumber(-0.1, 0.1)),
						rgb(70, 60, 60):Lerp(P.pierreSombre, k * 0.2), Enum.Material.Basalt, "Cheminee")
				end
				local bouche = sansOmbre(T.cylindre(m, 0.3, 1.2, CFrame.new(q + Vector3.new(0, 4.8, 0)), P.chaud, M.Neon, "Bouche"))
				T.tag(bouche, "GrottePulse")
				T.lumiere(bouche, P.chaud, 1.2, 18)
				T.emetteur(bouche, {
					Name = "Bulles", Texture = GT.TEX_LUEUR, LightEmission = 0.5, LightInfluence = 0, Color = ColorSequence.new(P.perle, P.chaud),
					Size = NumberSequence.new({T.kp(0, 0.2), T.kp(1, 0.6)}), Transparency = NumberSequence.new({T.kp(0, 0.2), T.kp(1, 1)}),
					Lifetime = NumberRange.new(2, 3.5), Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(10, 10), Rate = 14,
					EmissionDirection = Enum.NormalId.Top,
				})
				T.interdire(q, 4)
			end
		end
	end

	-- méduses et plancton dans les salles
	for _, s in salles do
		if not s.depart and nMeduses < 14 then
			for _ = 1, (if s.r >= 18 then 2 else 1) do
				local a = rng:NextNumber(0, 2 * math.pi)
				local sol = T.solEn(s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.2, 0.6), 8)
				if sol then
					meduse(sol.Position + Vector3.new(0, rng:NextNumber(7, 11), 0), rng:NextNumber(0.6, 1), couleursCorail[rng:NextInteger(1, #couleursCorail)])
				end
			end
		end
		if not s.depart then
			T.particulesSalle(s, {
				Name = "Plancton", Texture = GT.TEX_LUEUR, LightEmission = 1, Color = ColorSequence.new(P.turquoise, P.cyan),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.16), T.kp(1, 0)}), Lifetime = NumberRange.new(6, 10), Rate = 12,
				Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.15, 0),
			})
		end
	end

	-- ===== 4. LE SANCTUAIRE DU LÉVIATHAN (salle du boss) =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local m = T.modele("SanctuaireLeviathan")
		-- squelette du léviathan couché contre la paroi la plus éloignée des entrées
		local q0, dir = T.coinSalle(s, T.rb * 0.72)
		local cote = Vector3.new(-dir.Z, 0, dir.X)
		local sq = T.modele("Leviathan", m)
		local n = 11
		for i = 0, n do
			local t = i / n - 0.5
			local q = T.solEn(q0 + cote * t * T.rb * 1.4, 10)
			if q then
				local h = 1.2 + math.cos(t * math.pi) * 5
				local p = q.Position + Vector3.new(0, h, 0)
				T.bloc(sq, Vector3.new(1.8, 1.6, 2.2), CFrame.lookAt(p, p + cote), P.os, M.Lisse, "Vertebre")
				if i > 1 and i < n - 1 then
					-- côtes : deux segments qui retombent de chaque côté
					for _, sx in {-1, 1} do
						local d = -dir * sx
						local a1 = p + d * 3.5 + Vector3.new(0, 1, 0)
						local a2 = a1 + d * 1.5 - Vector3.new(0, h + 0.5, 0)
						T.bloc(sq, Vector3.new(0.6, 0.6, (a1 - p).Magnitude), CFrame.lookAt((p + a1) / 2, a1), P.os, M.Lisse, "Cote")
						T.bloc(sq, Vector3.new(0.5, 0.5, (a2 - a1).Magnitude), CFrame.lookAt((a1 + a2) / 2, a2), P.os, M.Lisse, "Cote")
					end
				end
				if i == n then
					-- crâne aux orbites vivantes
					local cr = CFrame.lookAt(p + cote * 3, p + cote * 6)
					T.bloc(sq, Vector3.new(5, 4, 6), cr, P.os, M.Lisse, "Crane")
					T.coin(sq, Vector3.new(4.4, 1.6, 4), cr * CFrame.new(0, -2.6, -3.5) * CFrame.Angles(math.pi, 0, 0), P.os, M.Lisse, "Machoire")
					for _, x in {-1.4, 1.4} do
						local oeil = sansOmbre(T.boule(sq, Vector3.one * 1.1, cr * CFrame.new(x, 0.7, -3), P.turquoise, M.Neon, "Orbite"))
						T.tag(oeil, "GrottePulse")
					end
					T.lumiere(sq:FindFirstChild("Orbite") :: BasePart, P.turquoise, 1.5, 24)
				end
			end
		end
		T.interdire(q0, 8)
		-- autel : bénitier géant et perle
		local qA = T.solEn(c - dir * T.rb * 0.15, 8)
		if qA then
			T.cylindre(m, 1.2, 7, CFrame.new(qA.Position + Vector3.new(0, 0.6, 0)), P.pierreSombre, CALCAIRE, "Autel")
			T.cylindre(m, 0.15, 7.4, CFrame.new(qA.Position + Vector3.new(0, 1.25, 0)), P.turquoise, M.Neon, "Liseré").CastShadow = false
			local _, perle = benitier(qA.Position + Vector3.new(0, 1.2, 0), 1.8, -dir, true)
			if perle then
				T.lumiere(perle, P.perle:Lerp(P.turquoise, 0.4), 2, 40)
				T.emetteur(perle, {
					Name = "Eclat", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.perle, P.turquoise),
					Size = NumberSequence.new({T.kp(0, 0.4), T.kp(1, 0)}), Lifetime = NumberRange.new(1.5, 2.5), Rate = 10, Speed = NumberRange.new(1, 2),
					SpreadAngle = Vector2.new(180, 180),
				})
			end
		end
		-- colonnes brisées en cercle, algues et coraux entre elles
		for k = 0, 5 do
			local a = k / 6 * 2 * math.pi + math.pi / 6
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.8)
			if q and T.libre(q.Position, 1) then
				colonne(q.Position, rng:NextNumber(10, 15), k % 2 == 1).Parent = m
				local q2 = T.solEn(c + Vector3.new(math.cos(a + 0.5), 0, math.sin(a + 0.5)) * T.rb * 0.85)
				if q2 then algue(q2.Position, rng:NextNumber(6, 10)) end
			end
		end
		local brume = T.volume(m, Vector3.new(T.rb * 1.6, 3, T.rb * 1.6), CFrame.new(c + Vector3.new(0, 1.5, 0)), "BrumeAbysse")
		T.emetteur(brume, {
			Name = "Brume", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.abysse:Lerp(P.turquoise, 0.35)), LightInfluence = 0.3, LightEmission = 0.2,
			Size = NumberSequence.new(5, 10), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.78), T.kp(1, 1)}),
			Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.3, 0.8), Rate = 6, Shape = Enum.ParticleEmitterShape.Box,
		})
		ctx.modele:SetAttribute("ArenaLeviathan", c)
		T.zone(c, T.rb + 8, P.turquoise:Lerp(P.corailViolet, 0.35), "Leviathan")
	end

	-- ===== 5. Décor générique (flaques, algues aux parois), veines turquoise, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = true, torches = false, poussieres = false, boss = false, champignons = false, humide = true,
		mine = false, racines = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.turquoise, P.cyan, P.turquoise, P.corailViolet}, 4, P.turquoise)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return rgb(255, 210, 160):Lerp(P.turquoise, 0.4) end
			if roles[s] == "gouffre" then return P.turquoise:Lerp(P.cyan, 0.4) end
			if roles[s] == "cite" then return P.pierre:Lerp(P.turquoise, 0.6) end
			if roles[s] == "recif" then return P.corailRose:Lerp(P.turquoise, 0.6) end
			if s.boss then return P.turquoise:Lerp(P.corailViolet, 0.3) end
			return P.turquoise:Lerp(P.cyan, 0.5)
		end,
		galerie = P.turquoise:Lerp(P.pierre, 0.4),
		lum = 0.55,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "CiteEngloutie")
end

return GrotteAbysses
