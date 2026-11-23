--[[ Grotte −350 m « Les Rivières de lave » (palier 4, Profondeurs ardentes) : habillage complet.
	Là où la roche fond. La chaleur monte du sol, la lave coule de la voûte, le feu jaillit des failles.
	- Avant-poste à l'arrivée : murets de basalte, bannières noircies, braseros, coffres de survie
	- LE LAC DE LAVE : la plus grande salle est une cuve de lave (qui brûle !) traversée par des ponts de
	  basalte jusqu'à un îlot central ; croûte noire qui flotte, bulles, fumées
	- Chutes de lave qui tombent de la voûte dans de petites mares de lave
	- LA FORÊT DE BASALTE : colonnes hexagonales de toutes tailles, orgues qui sortent des parois
	- Geysers de feu (failles rougeoyantes) qui jaillissent à intervalles (DangersGrotte) : on attend son tour
	- Pics et éclats d'obsidienne, cendres qui tombent, braises, veines de magma
	- Salle du fond : LE TRÔNE DE MAGMA (trône d'obsidienne au-dessus d'un bassin de lave, cornes, braseros)
	Zones : Camp, LacLave, Basalte, Trone. ]]

local GT = require(script.Parent.GrotteTheme)
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local GrotteLave = {}

local P = {
	lave = Color3.fromRGB(255, 96, 20),
	laveClaire = Color3.fromRGB(255, 190, 70),
	croute = Color3.fromRGB(40, 24, 20),
	basalte = Color3.fromRGB(48, 44, 46),
	basalteClair = Color3.fromRGB(74, 66, 66),
	obsidienne = Color3.fromRGB(24, 18, 30),
	obsidienneReflet = Color3.fromRGB(70, 40, 90),
	cendre = Color3.fromRGB(150, 140, 135),
	braise = Color3.fromRGB(255, 70, 20),
	fumee = Color3.fromRGB(60, 50, 48),
	rouge = Color3.fromRGB(120, 24, 20),
}

local COUL_GENERIQUE = {
	Roche = {Color3.fromRGB(58, 46, 44), Enum.Material.Basalt},
	Goutte = {P.laveClaire, Enum.Material.Neon, 0.2},
	Lueur = {P.lave, Enum.Material.Neon},
}

function GrotteLave.decorer(ctx, infos, outils)
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
	-- La roche du palier (« CrackedLava ») rougeoie partout : on ne voyait plus la vraie lave. Toute la grotte
	-- passe en basalte sombre ; la lave craquelée ne reste qu'en liserés autour des coulées (plus bas).
	local terrainG = workspace.Terrain
	do
		local cb, dm = ctx.modele:GetAttribute("Centre"), ctx.modele:GetAttribute("DemiTaille")
		if typeof(cb) == "Vector3" and typeof(dm) == "Vector3" then
			terrainG:ReplaceMaterial(Region3.new(cb - dm, cb + dm):ExpandToGrid(4), 4, Enum.Material.CrackedLava, Enum.Material.Basalt)
		end
	end
	local function lisere(centre: Vector3, rayon: number)
		terrainG:ReplaceMaterial(Region3.new(centre - Vector3.new(rayon, 3, rayon), centre + Vector3.new(rayon, 1, rayon)):ExpandToGrid(4), 4,
			Enum.Material.Basalt, Enum.Material.CrackedLava)
	end

	local lacSalle = T.salleFosse(candidates)
	local foret = nil
	for _, s in candidates do
		if s ~= lacSalle and not foret then
			foret = s
		end
	end
	local roles = {}

	-- surface de lave (Neon, qui brûle : tag « Lave ») + bulles et fumée
	local nLaves = 0
	local function nappe(cf: CFrame, taille: Vector3, nom: string)
		local p = T.bloc(decor, taille, cf, P.lave, M.Neon, nom)
		p.CastShadow = false
		T.tag(p, "Lave")
		T.tag(p, "GrottePulse")
		nLaves += 1
		if nLaves <= 10 then
			T.emetteur(p, {
				Name = "Bulles", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.laveClaire, P.lave),
				Size = NumberSequence.new({T.kp(0, 0.2), T.kp(0.5, 0.6), T.kp(1, 0)}), Lifetime = NumberRange.new(0.6, 1.2),
				Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(20, 20), Rate = 8, EmissionDirection = Enum.NormalId.Top,
			})
			T.emetteur(p, {
				Name = "Fumee", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.fumee), LightInfluence = 0.6,
				Size = NumberSequence.new(3, 8), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.8), T.kp(1, 1)}),
				Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(1, 3), Rate = 1.5, EmissionDirection = Enum.NormalId.Top,
			})
		end
		return p
	end

	local function prisme(parent, base: CFrame, h: number, r: number, couleur: Color3, mat: Enum.Material, nom: string)
		-- prisme hexagonal : trois blocs tournés de 60°
		for k = 0, 2 do
			T.bloc(parent, Vector3.new(r * 1.73, h, r), base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, k * math.pi / 3, 0), couleur, mat, nom)
		end
	end

	-- ===== 1. Avant-poste à l'arrivée =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local m = T.modele("AvantPoste")
		for _, sx in {-1, 1} do
			local q = T.solEn(depart.p + avant * 9 + droite * sx * 9)
			if q then
				local cf = CFrame.lookAt(q.Position, q.Position + avant)
				for k = 0, 2 do
					T.bloc(m, Vector3.new(4.5, 2.2 - k * 0.5, 2), cf * CFrame.new(sx * k * 3, 1.1 - k * 0.25, 0) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), P.basalte, Enum.Material.Basalt, "Muret")
				end
				local mat = T.bloc(m, Vector3.new(0.4, 8, 0.4), cf * CFrame.new(0, 4, 1.2), P.basalteClair, M.Metal, "Mat")
				T.bloc(m, Vector3.new(2.2, 4, 0.12), cf * CFrame.new(-1.2 * sx, 6, 1.2) * CFrame.Angles(0, 0, 0.05 * sx), P.rouge:Lerp(P.croute, 0.4), Enum.Material.Fabric, "Banniere")
				local br = B.brasero(decor, cf * CFrame.new(sx * 3, 0, -2.5), 0.7)
				if br then O.decorModele(br) end
				local c = B.caisse(decor, cf * CFrame.new(-sx * 3, 0, 2))
				if c then O.decorModele(c) end
			end
		end
		T.zone(depart.p, 34, P.laveClaire:Lerp(P.cendre, 0.4), "Camp")
	end

	-- ===== 2. LE LAC DE LAVE =====
	if lacSalle then
		local fosse = T.fosse(lacSalle, {
			profondeur = 6, pilier = 6.5, chuteProfondeur = 2.2, -- tombé dans la lave : ramené au bord (brûlé)
			pont = function(u, d0, d1, yA, yB)
				-- pont de basalte : grosses dalles posées sur des piles
				local c = lacSalle.p
				local cote = Vector3.new(-u.Z, 0, u.X)
				local pente = math.atan2(yB - yA, d1 - d0)
				local m = T.modele("PontBasalte")
				local d = d0
				local k = 0
				while d <= d1 do
					k += 1
					local t = (d - d0) / (d1 - d0)
					local q = Vector3.new(c.X, 0, c.Z) + u * d
					local y = yA + (yB - yA) * t
					T.solide(m, Vector3.new(5, 0.9, 2.1), CFrame.lookAt(Vector3.new(q.X, y - 0.2, q.Z), Vector3.new(q.X, y - 0.2, q.Z) + u) * CFrame.Angles(pente, 0, rng:NextNumber(-0.03, 0.03)),
						if k % 2 == 0 then P.basalte else P.basalteClair, Enum.Material.Basalt, "Dalle")
					if k % 3 == 1 then
						T.bloc(m, Vector3.new(2.4, 7, 2.4), CFrame.new(q.X, y - 4, q.Z), P.basalte, Enum.Material.Basalt, "Pile")
					end
					d += 2.05
				end
				-- bornes lumineuses aux deux bouts
				for _, dd in {d0 + 0.5, d1 - 0.5} do
					local t = (dd - d0) / (d1 - d0)
					local q = Vector3.new(c.X, yA + (yB - yA) * t, c.Z) + u * dd
					for _, sx in {-1, 1} do
						local b = T.bloc(m, Vector3.new(0.8, 2, 0.8), CFrame.new(q + cote * 2.8 * sx + Vector3.new(0, 1, 0)), P.obsidienne, Enum.Material.SmoothPlastic, "Borne")
						T.bloc(m, Vector3.new(0.5, 0.5, 0.5), CFrame.new(q + cote * 2.8 * sx + Vector3.new(0, 2.25, 0)), P.laveClaire, M.Neon, "Feu")
					end
				end
			end,
		})
		if fosse then
			roles[lacSalle] = "lac"
			local c = fosse.c
			-- la lave remplit la cuve jusqu'à 1,8 stud sous le bord
			local lac = nappe(CFrame.new(c.X, c.Y - 1.8, c.Z), Vector3.new(fosse.f * 2.05, 0.6, fosse.f * 2.05), "LacLave")
			-- berges de lave craquelée tout autour (la seule roche qui rougeoie)
			for k = 0, 11 do
				local a = k / 12 * 2 * math.pi
				lisere(c + Vector3.new(math.cos(a), 0, math.sin(a)) * (fosse.f + 1.5), 4)
			end
			-- la lave qui monte (MecaniquesGrotte) : jusqu'où elle déborde ; refuges de basalte sur la berge
			lac:SetAttribute("BaseCF", lac.CFrame)
			lac:SetAttribute("BaseTaille", lac.Size)
			lac:SetAttribute("Crue", Vector3.new((fosse.f + 8) * 2, 0.6, (fosse.f + 8) * 2))
			lac:SetAttribute("CrueY", c.Y + 0.2) -- au-dessus des berges (on y brûle), sous les dalles des ponts
			T.tag(lac, "LaveMontante")
			for k = 0, 4 do
				local a = k / 5 * 2 * math.pi + rng:NextNumber(-0.3, 0.3)
				local u = Vector3.new(math.cos(a), 0, math.sin(a))
				local proche = false
				for _, d in fosse.dirs do
					if u:Dot(d) > 0.85 then
						proche = true
					end
				end
				local q = T.solEn(c + u * (fosse.f + rng:NextNumber(3, 5.5)))
				if q and not proche then
					local m = T.modele("Refuge")
					for j = 0, 2 do
						T.solide(m, Vector3.new(3.8 * 1.73, 3.2, 3.8), CFrame.new(q.Position + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, j * math.pi / 3, 0),
							P.basalteClair, Enum.Material.Basalt, "Colonne")
					end
				end
			end
			-- croûte noire qui flotte (plaques sombres)
			for _ = 1, 14 do
				local a, r = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(fosse.pilier + 2, fosse.f - 1)
				local q = c + Vector3.new(math.cos(a) * r, -1.45, math.sin(a) * r)
				local s = rng:NextNumber(1.5, 3.5)
				T.bloc(decor, Vector3.new(s, 0.25, s * rng:NextNumber(0.6, 1.2)), CFrame.new(q) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), P.croute, Enum.Material.Basalt, "Croute")
			end
			-- îlot : obélisque d'obsidienne et brasero
			local ob = T.modele("Obelisque")
			prisme(ob, CFrame.new(c + Vector3.new(1.5, 0, 1.5)), 9, 1.3, P.obsidienne, Enum.Material.SmoothPlastic, "Obsidienne")
			local cristal = T.bloc(ob, Vector3.new(0.8, 1.6, 0.8), CFrame.new(c + Vector3.new(1.5, 9.8, 1.5)) * CFrame.Angles(0, math.rad(45), math.rad(45)), P.laveClaire, M.Neon, "CoeurDeFeu")
			T.tag(cristal, "GrottePulse")
			T.lumiere(cristal, P.lave, 1.5, 30)
			local l = T.volume(decor, Vector3.one, CFrame.new(c + Vector3.new(0, 3, 0)), "LueurLac")
			T.lumiere(l, P.lave, 2.6, 60)
			T.zone(c, fosse.f + 12, P.lave:Lerp(P.laveClaire, 0.3), "LacLave")
		end
	end

	-- ===== 3. Chutes de lave dans d'autres salles =====
	local nChutes = 0
	for _, s in salles do
		if not s.depart and not s.boss and roles[s] ~= "lac" and s.r >= 13 and nChutes < 3 then
			local q0, dir = T.coinSalle(s, s.r * 0.7)
			local sol = T.solEn(q0)
			local haut = sol and T.plafondEn(sol.Position + Vector3.new(0, 2, 0), 80)
			if sol and haut and haut.Position.Y - sol.Position.Y > 12 and T.solLibre(sol.Position, 3, 7) then
				nChutes += 1
				local y0, y1 = sol.Position.Y, haut.Position.Y
				local p = sol.Position
				-- petite mare creusée
				workspace.Terrain:FillCylinder(CFrame.new(p.X, y0 - 1, p.Z), 3, 5, Enum.Material.Air)
				nappe(CFrame.new(p.X, y0 - 1.6, p.Z), Vector3.new(9, 0.5, 9), "MareLave")
				local col = T.cylindre(decor, y1 - y0, 2.2, CFrame.new(p.X, (y0 + y1) / 2, p.Z), P.lave, M.Neon, "ChuteLave")
				col.CastShadow = false
				local coeur = T.cylindre(decor, y1 - y0, 1.2, CFrame.new(p.X, (y0 + y1) / 2, p.Z), P.laveClaire, M.Neon, "ChuteLaveCoeur")
				coeur.CastShadow = false
				local pied = T.volume(decor, Vector3.new(3, 0.5, 3), CFrame.new(p.X, y0 - 0.8, p.Z), "PiedChute")
				T.emetteur(pied, {
					Name = "Eclaboussures", Texture = GT.TEX_ETINCELLE, LightEmission = 0.7, LightInfluence = 0, Color = ColorSequence.new(P.lave, P.braise),
					Size = NumberSequence.new({T.kp(0, 0.25), T.kp(1, 0)}), Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(6, 12),
					SpreadAngle = Vector2.new(60, 60), Rate = 24, EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -40, 0),
				})
				T.emetteur(pied, {
					Name = "Fumee", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.fumee), LightInfluence = 0.5,
					Size = NumberSequence.new(4, 10), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.2, 0.7), T.kp(1, 1)}),
					Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(3, 6), Rate = 3, EmissionDirection = Enum.NormalId.Top,
				})
				T.lumiere(pied, P.lave, 2.4, 45)
				T.interdire(p, 7)
			end
		end
	end

	-- ===== 4. LA FORÊT DE BASALTE =====
	if foret then
		roles[foret] = "basalte"
		local s = foret
		local n = 0
		for _ = 1, 80 do
			if n >= 26 then
				break
			end
			local a, r = rng:NextNumber(0, 2 * math.pi), s.r * math.sqrt(rng:NextNumber(0.05, 0.9))
			local q = T.solEn(s.p + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
			if q and T.solLibre(q.Position, 2, 5) then
				n += 1
				local m = T.modele("OrgueBasalte")
				local base = CFrame.new(q.Position - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
				for k = 1, rng:NextInteger(3, 6) do
					local h = rng:NextNumber(3, 14)
					local off = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
					prisme(m, base * CFrame.new(off), h, rng:NextNumber(0.7, 1.1), if k % 2 == 0 then P.basalte else P.basalteClair, Enum.Material.Basalt, "Colonne")
					if rng:NextNumber() < 0.3 then
						local lueur = T.bloc(m, Vector3.new(0.12, h * 0.7, 0.12), base * CFrame.new(off + Vector3.new(0.9, h * 0.4, 0)), P.lave, M.Neon, "Fissure")
						lueur.CastShadow = false
					end
				end
			end
		end
		-- orgues qui sortent des parois
		for _ = 1, 6 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local hit = outils.paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(3, 10), s.r * 1.8)
			if hit then
				local m = T.modele("OrgueParoi")
				local base = outils.axeVers(hit.Position - hit.Normal * 1, hit.Normal)
				for k = 1, 5 do
					prisme(m, base * CFrame.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)), rng:NextNumber(2, 6), 0.8, P.basalteClair, Enum.Material.Basalt, "Colonne")
				end
			end
		end
		T.zone(s.p, s.r + 6, P.lave:Lerp(P.cendre, 0.5), "Basalte")
	end

	-- ===== 4b. Le geyser propulseur et la corniche secrète =====
	-- Une faille à flammes blanc-bleu, sans danger, qui projette à ~30 studs de haut (DangersGrotte : Propulsion) :
	-- en se laissant porter vers la paroi, on atterrit sur une corniche creusée dans la roche, où dort de l'or.
	do
		local fait = false
		for _, s in salles do
			if not fait and not s.depart and not s.boss and roles[s] ~= "lac" and s.r >= 12 then
				local _, dir = T.coinSalle(s, s.r * 0.5)
				local hit = outils.paroi(s.p, dir, 3, s.r * 1.9)
				if hit then
					local n = unite(plat(hit.Normal), -dir)
					local pied = T.solEn(hit.Position + n * 3.8)
					local haut = pied and T.plafondEn(pied.Position + Vector3.new(0, 2, 0), 90)
					if pied and haut and haut.Position.Y - pied.Position.Y > 30 and T.solLibre(pied.Position, 2, 3) then
						fait = true
						local yC = pied.Position.Y + 22
						local bord = Vector3.new(hit.Position.X, yC, hit.Position.Z)
						local m = T.modele("CornicheSecrete")
						-- l'alcôve, creusée dans la paroi
						local fondA = bord - n * 4.5
						workspace.Terrain:FillBlock(CFrame.lookAt(fondA + Vector3.new(0, 4, 0), fondA + Vector3.new(0, 4, 0) + n), Vector3.new(11, 8, 9), Enum.Material.Air)
						-- la corniche : une dalle de basalte qui dépasse un peu dans la salle
						local cfD = CFrame.lookAt(bord - n * 3.2 + Vector3.new(0, -0.6, 0), bord - n * 3.2 + Vector3.new(0, -0.6, 0) - n)
						T.solide(m, Vector3.new(10, 1.2, 9.4), cfD, P.basalteClair, Enum.Material.Basalt, "Dalle")
						-- trésor : de l'or et des éclats d'obsidienne
						local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))
						for i, t in {{"Gold", 9}, {"Gold", 9}} do
							local pos = (cfD * CFrame.new((i - 1.5) * 4, 0.6, -2.5)).Position
							local sz = MineraisModeles.VISUEL[t[1]].taille
							local mm, coeur = MineraisModeles.construire(t[1], CFrame.new(pos - Vector3.new(0, 1.25 * sz - 0.1, 0)), Random.new(rng:NextInteger(1, 1e6)), true)
							for _, p in mm:GetChildren() do
								if p:IsA("BasePart") then
									p.CanQuery = p == coeur
								end
							end
							coeur:SetAttribute("Type", t[1])
							coeur:SetAttribute("Taille", sz)
							coeur:SetAttribute("PV", t[2])
							coeur:SetAttribute("PVMax", t[2])
							coeur:SetAttribute("Proprietaire", ctx.proprietaire)
							if ctx.invite then
								coeur:SetAttribute("Invite", ctx.invite)
							end
							coeur:SetAttribute("Secret", true)
							T.tag(coeur, "Minerai")
							mm.Parent = m
						end
						for _ = 1, 4 do
							local h = rng:NextNumber(1.5, 3.5)
							T.coin(m, Vector3.new(h * 0.4, h, h * 0.4), cfD * CFrame.new(rng:NextNumber(-4, 4), 0.6 + h / 2, rng:NextNumber(-4, -1)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
								P.obsidienne, Enum.Material.SmoothPlastic, "Obsidienne").Reflectance = 0.3
						end
						local l = T.volume(m, Vector3.one, cfD * CFrame.new(0, 4, -2), "LueurCorniche")
						T.lumiere(l, P.laveClaire, 1.4, 20)
						-- la faille propulseuse au pied de la paroi
						local bleu = Color3.fromRGB(170, 225, 255)
						for k = 0, 5 do
							local a = k / 6 * 2 * math.pi
							T.bloc(m, Vector3.new(1.4, rng:NextNumber(0.6, 1.2), 1), CFrame.new(pied.Position + Vector3.new(math.cos(a) * 2, 0.2, math.sin(a) * 2)) * CFrame.Angles(0, a, 0.3),
								P.obsidienne, Enum.Material.SmoothPlastic, "Bord")
						end
						local faille = T.cylindre(m, 0.2, 2.8, CFrame.new(pied.Position + Vector3.new(0, 0.05, 0)), bleu, M.Neon, "FailleBleue")
						faille.CastShadow = false
						T.tag(faille, "GrottePulse")
						faille:SetAttribute("Propulsion", 112)
						faille:SetAttribute("Periode", 5)
						faille:SetAttribute("Duree", 1.3)
						faille:SetAttribute("Couleur", bleu)
						T.tag(faille, "Geyser")
						T.lumiere(faille, bleu, 1, 14)
						T.interdire(pied.Position, 4)
					end
				end
			end
		end
	end

	-- ===== 5. Geysers de feu (failles) le long du chemin, jamais en plein passage =====
	local nGeysers = 0
	for _, g in galeries do
		for i, pt in g.pts do
			if i % 7 == 4 and nGeysers < 10 and (pt.p - depart.p).Magnitude > 30 then
				local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then 1 else -1)
				local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.45, 0.65))
				if q and T.libre(q.Position, 2) and not T.surChemin(q.Position, 2.5) then
					nGeysers += 1
					local m = T.modele("Geyser")
					for k = 0, 5 do
						local a = k / 6 * 2 * math.pi
						T.bloc(m, Vector3.new(1.4, rng:NextNumber(0.6, 1.4), 1), CFrame.new(q.Position + Vector3.new(math.cos(a) * 1.8, 0.2, math.sin(a) * 1.8)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), a, 0.3),
							P.croute, Enum.Material.Basalt, "Bord")
					end
					local faille = T.cylindre(m, 0.2, 2.6, CFrame.new(q.Position + Vector3.new(0, 0.05, 0)), P.lave, M.Neon, "Faille")
					faille.CastShadow = false
					T.tag(faille, "GrottePulse")
					faille:SetAttribute("Periode", rng:NextNumber(6, 9))
					faille:SetAttribute("Duree", 1.6)
					faille:SetAttribute("Decalage", rng:NextNumber(0, 9))
					T.tag(faille, "Geyser")
				end
			end
		end
	end

	-- ===== 6. Pics d'obsidienne, cendres, braises =====
	for _ = 1, 30 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then 1 else -1)
		local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.7, 0.95))
		if q and T.solLibre(q.Position, 1, 4) and (q.Position - depart.p).Magnitude > 20 then
			local m = T.modele("PicsObsidienne")
			for k = 1, rng:NextInteger(2, 4) do
				local h = rng:NextNumber(1.5, 4.5)
				T.coin(m, Vector3.new(h * 0.4, h, h * 0.4), CFrame.new(q.Position + Vector3.new(rng:NextNumber(-1, 1), h / 2 - 0.2, rng:NextNumber(-1, 1)))
					* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), P.obsidienne, Enum.Material.SmoothPlastic, "Pic").Reflectance = 0.25
			end
		end
	end
	for _, s in salles do
		if not s.depart then
			T.particulesSalle(s, {
				Name = "Cendres", Texture = GT.TEX_LUEUR, LightEmission = 0.2, LightInfluence = 0.8, Color = ColorSequence.new(P.cendre),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.12), T.kp(1, 0)}), Lifetime = NumberRange.new(6, 10), Rate = 10,
				Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Bottom,
				Acceleration = Vector3.new(0.3, -0.4, 0),
			})
		end
	end

	-- ===== 7. LE TRÔNE DE MAGMA =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local fond, dirFond = T.coinSalle(s, T.rb * 0.55)
		local q = T.solEn(fond)
		if q then
			local cf = CFrame.lookAt(q.Position, q.Position - dirFond)
			local m = T.modele("TroneMagma")
			-- bassin de lave en demi-lune devant le trône
			local pb = (cf * CFrame.new(0, 0, -7)).Position
			workspace.Terrain:FillCylinder(CFrame.new(pb.X, q.Position.Y - 1, pb.Z), 3, 6, Enum.Material.Air)
			nappe(CFrame.new(pb.X, q.Position.Y - 1.6, pb.Z), Vector3.new(11, 0.5, 11), "BassinTrone")
			-- estrade et trône
			T.bloc(m, Vector3.new(12, 1.6, 8), cf * CFrame.new(0, 0.8, 2), P.basalte, Enum.Material.Basalt, "Estrade")
			T.bloc(m, Vector3.new(10, 1, 6), cf * CFrame.new(0, 2.1, 2.4), P.obsidienne, Enum.Material.SmoothPlastic, "Marche").Reflectance = 0.2
			T.bloc(m, Vector3.new(6, 2.4, 4), cf * CFrame.new(0, 3.8, 3), P.obsidienne, Enum.Material.SmoothPlastic, "Assise").Reflectance = 0.2
			T.bloc(m, Vector3.new(6.4, 12, 1.6), cf * CFrame.new(0, 9, 5), P.obsidienne, Enum.Material.SmoothPlastic, "Dossier").Reflectance = 0.2
			for _, sx in {-1, 1} do
				T.bloc(m, Vector3.new(1.4, 3, 4), cf * CFrame.new(sx * 3.6, 5.5, 3), P.obsidienne, Enum.Material.SmoothPlastic, "Accoudoir")
				-- cornes
				for k = 0, 3 do
					T.coin(m, Vector3.new(1.2 - k * 0.2, 2.4, 1.2 - k * 0.2), cf * CFrame.new(sx * (3.6 + k * 0.9), 15 + k * 1.6, 5) * CFrame.Angles(0, 0, -sx * (0.4 + k * 0.25)),
						P.croute, Enum.Material.Basalt, "Corne")
				end
				local col = T.modele("ColonneTrone", m)
				prisme(col, cf * CFrame.new(sx * 9, 0, 1), 16, 1.4, P.basalte, Enum.Material.Basalt, "Colonne")
				local feuC = T.bloc(col, Vector3.new(1.6, 1, 1.6), cf * CFrame.new(sx * 9, 16.5, 1), P.laveClaire, M.Neon, "Feu")
				T.emetteur(feuC, {
					Name = "Flammes", Texture = GT.TEX_FEU, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.laveClaire, P.lave),
					Size = NumberSequence.new({T.kp(0, 2), T.kp(1, 0.4)}), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(3, 5),
					Rate = 30, EmissionDirection = Enum.NormalId.Top,
				})
				T.lumiere(feuC, P.lave, 1.6, 30)
			end
			local gemme = T.bloc(m, Vector3.new(1.4, 1.4, 0.4), cf * CFrame.new(0, 13.5, 4.1) * CFrame.Angles(0, 0, math.rad(45)), P.laveClaire, M.Neon, "Gemme")
			T.tag(gemme, "GrottePulse")
			T.interdire(q.Position, 11)
		end
		T.zone(Vector3.new(s.p.X, y0, s.p.Z), T.rb + 8, P.lave, "Trone")
	end

	-- ===== 8. Décor générique, veines de magma, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, champignons = false, humide = false,
		racines = false, mine = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.lave, P.laveClaire, P.lave, P.braise}, 5, P.braise)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.cendre:Lerp(P.laveClaire, 0.3) end
			if roles[s] == "lac" then return P.laveClaire:Lerp(P.cendre, 0.4) end
			if roles[s] == "basalte" then return P.cendre:Lerp(P.laveClaire, 0.25) end
			if s.boss then return P.laveClaire:Lerp(P.lave, 0.4) end
			return P.cendre:Lerp(P.laveClaire, 0.35)
		end,
		galerie = P.cendre:Lerp(P.laveClaire, 0.3),
		lum = 0.5,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "Lave")
end

return GrotteLave
