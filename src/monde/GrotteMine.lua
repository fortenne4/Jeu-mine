--[[ Grotte −100 m « La Mine oubliée de Brumefer » (palier 2, Cavernes oubliées) : habillage complet.
	Le puits n°3 des nains de Brumefer, abandonné depuis la Grande Crue : une vraie mine, profonde et hantée.
	- Portail du puits à l'arrivée (cadre en rondins, enseigne « PUITS N°3 », wagonnet, outils, lanternes)
	- Galeries boisées : cadres de mine (poteaux + chapeau) tout le long, lanternes suspendues aux chapeaux
	- Rails sur tout le chemin principal (traverses, deux rails), wagonnets chargés d'améthyste, butoirs
	- LE GRAND PUITS : la plus grande salle s'ouvre vers le haut ; cage d'ascenseur suspendue, grande roue de
	  treuil, câbles, colonne de lumière qui tombe du jour lointain
	- LA CATHÉDRALE D'AMÉTHYSTE : cristaux géants violets au sol et aux parois, cristal-roi central, éclats
	- L'éboulement : galerie effondrée, rochers, poutres brisées, panneau « DANGER »
	- Échafaudages contre les parois (plateformes, échelles, caisses), lanternes fantômes qui flottent
	- Salle du fond : LE TREUIL GÉANT (tambour, engrenages, chaînes vers la voûte) et le filon d'améthyste
	- Veines violettes et lilas, galets lumineux, éclairage doux de chaque salle et galerie
	Tout le décor est traversable (sauf l'échelle de la cage, pour l'ambiance), rien sur les gisements ni au
	milieu du passage. Zones d'ambiance : Camp, Puits, Geode, Eboulement, Treuil. ]]

local GT = require(script.Parent.GrotteTheme)
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local GrotteMine = {}

local P = {
	amethyste = Color3.fromRGB(150, 85, 235),
	lilas = Color3.fromRGB(215, 160, 255),
	violetSombre = Color3.fromRGB(70, 34, 110),
	ambre = Color3.fromRGB(255, 176, 90),
	fantome = Color3.fromRGB(150, 220, 255),
	jour = Color3.fromRGB(235, 225, 200),
	bois = Color3.fromRGB(96, 66, 42),
	boisClair = Color3.fromRGB(128, 92, 58),
	boisSombre = Color3.fromRGB(62, 42, 28),
	fer = Color3.fromRGB(70, 70, 78),
	rouille = Color3.fromRGB(120, 66, 40),
	roche = Color3.fromRGB(70, 64, 80),
}

local COUL_GENERIQUE = {
	Roche = {Color3.fromRGB(76, 70, 88), Enum.Material.Basalt},
	Goutte = {Color3.fromRGB(220, 200, 255), Enum.Material.Glass, 0.3},
	Chapeau = {Color3.fromRGB(110, 60, 160), Enum.Material.SmoothPlastic},
	Pied = {Color3.fromRGB(190, 180, 200), Enum.Material.SmoothPlastic},
	Lueur = {P.lilas, Enum.Material.Neon},
}

function GrotteMine.decorer(ctx, infos, outils)
	local T = GT.nouveau(ctx, infos, outils)
	local rng, decor, M = T.rng, T.decor, T.M
	local depart, boss = T.depart, T.boss
	local salles, galeries = T.salles, T.galeries
	local plat, unite = T.plat, T.unite

	-- ===== Répartition des salles : la plus grande = le Grand Puits, puis la Cathédrale, puis l'éboulement =====
	local candidates = {}
	for _, s in salles do
		if not s.depart and not s.boss and s.r >= 15 then
			table.insert(candidates, s)
		end
	end
	table.sort(candidates, function(a, b)
		return a.r > b.r
	end)
	local puits, cathedrale, effondree = candidates[1], candidates[2], candidates[3]
	local roles = {}
	if puits then roles[puits] = "puits" end
	if cathedrale then roles[cathedrale] = "geode" end
	if effondree then roles[effondree] = "eboulement" end

	-- lanterne de mine : cage de fer, flamme ambrée (ou violette pour les lanternes fantômes)
	local nLanternes = 0
	local function lanterne(cf: CFrame, couleur: Color3, eclaire: boolean)
		local m = T.modele("LanterneMine")
		T.bloc(m, Vector3.new(0.7, 0.12, 0.7), cf * CFrame.new(0, 0.5, 0), P.fer, M.Metal, "Toit")
		T.bloc(m, Vector3.new(0.6, 0.1, 0.6), cf * CFrame.new(0, -0.5, 0), P.fer, M.Metal, "Socle")
		for _, x in {-0.28, 0.28} do
			for _, z in {-0.28, 0.28} do
				T.bloc(m, Vector3.new(0.08, 1, 0.08), cf * CFrame.new(x, 0, z), P.fer, M.Metal, "Barreau")
			end
		end
		local flamme = T.bloc(m, Vector3.new(0.3, 0.5, 0.3), cf * CFrame.new(0, -0.05, 0), couleur, M.Neon, "Flamme")
		flamme.CastShadow = false
		T.tag(flamme, "GrottePulse")
		if eclaire then
			nLanternes += 1
			if nLanternes % 2 == 0 then
				T.lumiere(flamme, couleur, 0.9, 14)
			else
				T.remplir(flamme, couleur, 0.6, 16)
			end
		end
		return m
	end

	-- ===== 1. Portail du puits n°3 à l'arrivée =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local base = T.solEn(depart.p + avant * 12)
		if base then
			local cf = CFrame.lookAt(base.Position, base.Position + avant)
			local m = T.modele("PortailPuits")
			for _, x in {-6, 6} do
				T.cylindre(m, 12, 1.3, cf * CFrame.new(x, 6, 0), P.bois, M.Bois, "Rondin")
				T.bloc(m, Vector3.new(1.6, 0.6, 1.6), cf * CFrame.new(x, 0.3, 0), P.roche, Enum.Material.Cobblestone, "Pied")
			end
			T.bloc(m, Vector3.new(14.5, 1.3, 1.5), cf * CFrame.new(0, 12.4, 0), P.boisSombre, M.Bois, "Chapeau")
			for _, x in {-4, 4} do
				T.coin(m, Vector3.new(0.8, 3, 3), cf * CFrame.new(x, 10.3, 0) * CFrame.Angles(0, math.pi / 2, 0), P.bois, M.Bois, "Jambe")
			end
			local enseigne = O.bloc(m, Vector3.new(9, 2.2, 0.35), cf * CFrame.new(0, 14.2, -0.5), P.boisClair, Enum.Material.WoodPlanks, "Enseigne")
			O.decor(enseigne)
			O.texte(enseigne, Enum.NormalId.Front, "PUITS N°3 — BRUMEFER")
			for _, x in {-6, 6} do
				lanterne(cf * CFrame.new(x, 9, -1.4), P.ambre, true)
			end
			-- wagonnet abandonné, caisses, tonneau, pioches
			local w = B.wagonnet(decor, cf * CFrame.new(-9, 0, -4) * CFrame.Angles(0, 0.4, 0), nil, rng)
			if w then O.decorModele(w) end
			for k = 1, 3 do
				local c = B.caisse(decor, cf * CFrame.new(9 + k * 0.4, 0, -2 - k * 2.3) * CFrame.Angles(0, rng:NextNumber(0, 3), 0))
				if c then O.decorModele(c) end
			end
			local t = B.tonneau(decor, cf * CFrame.new(10, 0, 3))
			if t then O.decorModele(t) end
			B.pioche(decor, cf * CFrame.new(8, 0.3, 1) * CFrame.Angles(0, 0.6, math.rad(75)), P.fer)
			T.interdire(base.Position, 8)
		end
		T.zone(depart.p, 34, P.ambre, "Camp")
	end

	-- ===== 2. Galeries boisées : cadres de mine et lanternes suspendues =====
	local nCadres = 0
	for _, g in galeries do
		local dernier = nil
		local pas = if g.principal then 30 else 46 -- espacés : quelques cadres seulement, pas un tunnel continu
		for i, pt in g.pts do
			if i > 1 and i < #g.pts and (not dernier or (pt.p - dernier).Magnitude > pas) then
				local loinSalles = true
				for _, s in salles do
					if plat(pt.p - s.p).Magnitude < s.r * 0.9 then
						loinSalles = false
					end
				end
				if loinSalles and (pt.p - depart.p).Magnitude > 24 then
					dernier = pt.p
					local lat = Vector3.new(-pt.t.Z, 0, pt.t.X)
					local sol = T.solEn(pt.p)
					local haut = T.plafondEn(pt.p + Vector3.new(0, 2, 0), 30)
					if sol and haut and haut.Position.Y - sol.Position.Y > 8.2 then
						local y0 = sol.Position.Y
						local h = math.clamp(haut.Position.Y - y0 - 0.6, 7.6, 10) -- même hauteur partout : une charpente régulière
						-- largeur : jusqu'aux parois de chaque côté (bornée)
						local function bord(sens: number): number
							local hit = T.trace(Vector3.new(pt.p.X, y0 + 3, pt.p.Z), lat * sens * 20)
							return if hit then math.clamp(hit.Distance - 0.8, 3.5, 11) else 8
						end
						local g1, g2 = bord(-1), bord(1)
						local cfBase = CFrame.lookAt(Vector3.new(pt.p.X, y0, pt.p.Z), Vector3.new(pt.p.X, y0, pt.p.Z) + pt.t)
						-- chaque poteau sur SON sol (pente, marche) : sinon le cadre flotte d'un côté
						local piedG = T.solEn((cfBase * CFrame.new(-g1, 0, 0)).Position, 4)
						local piedD = T.solEn((cfBase * CFrame.new(g2, 0, 0)).Position, 4)
						if not (piedG and piedD) or math.abs(piedG.Position.Y - piedD.Position.Y) > 2.5
							or math.abs(piedG.Position.Y - y0) > 3 or math.abs(piedD.Position.Y - y0) > 3 then
							continue -- sol trop irrégulier ou vide sous un poteau : pas de cadre ici
						end
						local m = T.modele("CadreMine")
						local inclin = rng:NextNumber(-0.04, 0.04)
						local enfonce = 1.2 -- les poteaux s'enfoncent un peu dans le sol
						for _, cote in {{-g1, piedG.Position.Y, -0.06}, {g2, piedD.Position.Y, 0.06}} do
							local hp = y0 + h - cote[2] + enfonce
							T.bloc(m, Vector3.new(0.9, hp, 0.9), cfBase * CFrame.new(cote[1], (cote[2] - y0) - enfonce + hp / 2, 0)
								* CFrame.Angles(0, 0, cote[3] + inclin), P.bois, M.Bois, "Poteau")
						end
						T.bloc(m, Vector3.new(g1 + g2 + 1.6, 0.9, 1.1), cfBase * CFrame.new((g2 - g1) / 2, h, 0), P.boisSombre, M.Bois, "Chapeau")
						-- planches de garnissage au plafond, une fois sur deux
						if nCadres % 2 == 0 then
							for k = -1, 1 do
								T.bloc(m, Vector3.new(0.5 + rng:NextNumber(0, 0.3), 0.2, 4), cfBase * CFrame.new((g2 - g1) / 2 + k * 1.6, h + 0.55, 0), P.boisClair, M.Bois, "Garnissage")
							end
						end
						nCadres += 1
						if nCadres % 3 == 0 then
							local chaine = T.bloc(m, Vector3.new(0.1, 1.2, 0.1), cfBase * CFrame.new((g2 - g1) / 2, h - 1, 0), P.fer, M.Metal, "Chaine")
							chaine.CastShadow = false
							lanterne(cfBase * CFrame.new((g2 - g1) / 2, h - 2.2, 0), P.ambre, true)
						end
					end
				end
			end
		end
	end

	-- ===== 3. Rails sur le chemin principal, wagonnets d'améthyste =====
	local railPoints = {}
	for _, g in galeries do
		if g.principal then
			for _, pt in g.pts do
				local sol = T.solEn(pt.p)
				if sol and (pt.p - depart.p).Magnitude > 16 then
					table.insert(railPoints, {p = sol.Position + Vector3.new(0, 0.12, 0), t = pt.t, g = g})
				else
					table.insert(railPoints, false)
				end
			end
			table.insert(railPoints, false)
		end
	end
	local nWagons = 0
	for i = 1, #railPoints - 1 do
		local a, b = railPoints[i], railPoints[i + 1]
		if a and b and (b.p - a.p).Magnitude < 7 and math.abs(b.p.Y - a.p.Y) < 2.5 then
			local m = T.modele("Rails")
			local dir = (b.p - a.p)
			local lat = unite(Vector3.new(-dir.Z, 0, dir.X), Vector3.xAxis)
			local L = dir.Magnitude
			for _, s in {-1, 1} do
				local off = lat * 1.25 * s
				local r = T.bloc(m, Vector3.new(0.22, 0.25, L + 0.1), CFrame.lookAt((a.p + b.p) / 2 + off + Vector3.new(0, 0.3, 0), b.p + off + Vector3.new(0, 0.3, 0)), Color3.fromRGB(58, 56, 62), M.Metal, "Rail")
				r.CastShadow = false
			end
			local n = math.max(1, math.floor(L / 1.6))
			for k = 0, n - 1 do
				local q = a.p:Lerp(b.p, (k + 0.5) / n)
				local tr = T.bloc(m, Vector3.new(3.4, 0.22, 0.55), CFrame.lookAt(q, q + dir) * CFrame.Angles(0, rng:NextNumber(-0.06, 0.06), 0), P.boisSombre, M.Bois, "Traverse")
				tr.CastShadow = false
			end
			-- un wagonnet de temps en temps, posé sur les rails, plein d'améthyste
			if i % 22 == 11 and nWagons < 5 and T.libre(a.p, 2) then
				nWagons += 1
				local cf = CFrame.lookAt(a.p, a.p + dir) * CFrame.Angles(0, math.pi / 2, 0)
				local w = B.wagonnet(decor, cf * CFrame.new(0, -0.6, 0), nil, rng)
				if w then
					O.decorModele(w)
					for k = 1, 4 do
						local c = T.coin(decor, Vector3.new(0.7, rng:NextNumber(1, 1.8), 0.9),
							cf * CFrame.new(rng:NextNumber(-1.8, 1.8), 2.4, rng:NextNumber(-1, 1)) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6), rng:NextNumber(-0.6, 0.6)),
							if k % 2 == 0 then P.amethyste else P.lilas, M.Neon, "EclatAmethyste")
						c.CastShadow = false
						T.tag(c, "GrottePulse")
					end
					local eclat = T.volume(decor, Vector3.new(2, 1, 2), cf * CFrame.new(0, 2.6, 0), "LueurWagon")
					T.remplir(eclat, P.amethyste, 0.7, 12)
				end
			end
		end
	end

	-- course en wagonnet : les points des rails dans l'ordre (dossier « CourseWagon », lu par CourseWagon.client)
	-- et la gare au départ (wagonnet + invite « Monter » : CourseWagon.server)
	do
		local course = {}
		for _, rp in railPoints do
			if rp then
				table.insert(course, rp.p)
			end
		end
		if #course > 12 then
			local f = Instance.new("Folder")
			f.Name = "CourseWagon"
			for i, p in course do
				f:SetAttribute("P" .. i, p)
			end
			f:SetAttribute("N", #course)
			f.Parent = ctx.modele
			local p1, p2 = course[1], course[math.min(4, #course)]
			local dir = unite(plat(p2 - p1), Vector3.new(0, 0, -1))
			local cf = CFrame.lookAt(p1, p1 + dir) * CFrame.Angles(0, math.pi / 2, 0)
			local gare = B.wagonnet(decor, cf * CFrame.new(0, -0.6, 0), nil, rng)
			if gare then
				O.decorModele(gare)
				gare.Name = "WagonGare"
			end
			local borne = T.volume(decor, Vector3.new(1, 1, 1), CFrame.new(p1 + Vector3.new(0, 2.5, 0)), "BorneWagon")
			local invite = Instance.new("ProximityPrompt")
			invite.ActionText, invite.ObjectText = "Monter", "Wagonnet du puits n°3"
			invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 0.3, 9, false
			invite:SetAttribute("CourseWagon", true)
			invite.Parent = borne
			-- panneau « EN VOITURE ! »
			local cote = Vector3.new(-dir.Z, 0, dir.X)
			local qP = T.solEn(p1 + cote * 4.5)
			if qP then
				local cfp = CFrame.lookAt(qP.Position, qP.Position - cote)
				T.bloc(decor, Vector3.new(0.4, 4, 0.4), cfp * CFrame.new(0, 2, 0), P.bois, M.Bois, "Piquet")
				local pan = O.bloc(decor, Vector3.new(4, 1.4, 0.25), cfp * CFrame.new(0, 3.8, -0.3), P.boisClair, Enum.Material.WoodPlanks, "Panneau")
				O.decor(pan)
				O.texte(pan, Enum.NormalId.Front, "EN VOITURE !")
				lanterne(cfp * CFrame.new(1.6, 4.9, -0.4), P.ambre, true)
			end
		end
	end

	-- ===== 4. LE GRAND PUITS =====
	if puits then
		local s = puits
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local haut = T.plafondEn(Vector3.new(s.p.X, y0 + 2, s.p.Z), 90)
		local yPlafond = if haut then haut.Position.Y else y0 + 24
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local R = 7.5
		-- la cheminée du puits : on creuse vers le haut, sans percer le bloc de roche de la grotte
		local centreBoite, demi = ctx.modele:GetAttribute("Centre"), ctx.modele:GetAttribute("DemiTaille")
		local yMax = if typeof(centreBoite) == "Vector3" and typeof(demi) == "Vector3" then centreBoite.Y + demi.Y - 6 else yPlafond + 50
		local yHaut = math.max(yPlafond + 12, math.min(yPlafond + 56, yMax))
		workspace.Terrain:FillCylinder(CFrame.new(c.X, (yPlafond - 2 + yHaut) / 2, c.Z), yHaut - yPlafond + 2, R, Enum.Material.Air)
		local m = T.modele("GrandPuits")
		-- couronne de boisage à l'ouverture
		for k = 0, 7 do
			local a = k / 8 * 2 * math.pi
			local u = Vector3.new(math.cos(a), 0, math.sin(a))
			local q = c + Vector3.new(0, yPlafond - y0 + 0.5, 0) + u * (R + 0.4)
			T.bloc(m, Vector3.new(1, 1, R * 0.85), CFrame.lookAt(q, q + Vector3.new(-u.Z, 0, u.X)), P.boisSombre, M.Bois, "Couronne")
		end
		-- grande roue du treuil, tout en haut du puits
		local yRoue = yHaut - 6
		local roue = T.modele("RouePuits", m)
		T.disque(roue, 0.6, 9, CFrame.new(c.X, yRoue, c.Z), P.bois, M.Bois, "Jante")
		T.disque(roue, 0.8, 1.6, CFrame.new(c.X, yRoue, c.Z), P.fer, M.Metal, "Moyeu")
		for k = 0, 5 do
			T.bloc(roue, Vector3.new(0.5, 8.6, 0.5), CFrame.new(c.X, yRoue, c.Z) * CFrame.Angles(k * math.pi / 6, 0, 0), P.boisSombre, M.Bois, "Rayon")
		end
		roue.WorldPivot = CFrame.new(c.X, yRoue, c.Z)
		roue:SetAttribute("Vitesse", 0.35)
		roue:SetAttribute("Axe", "X")
		T.tag(roue, "Rouage")
		T.bloc(m, Vector3.new(16, 1, 1), CFrame.new(c.X, yRoue, c.Z), P.fer, M.Metal, "Axe")
		-- ASCENSEUR : plateforme physique guidée (PrismaticConstraint en servo) qui monte de la salle jusqu'à la
		-- galerie secrète creusée en haut du puits ; un levier en bas, un en haut (AscenseurPuits.server.lua)
		local hMax = math.max(14, math.min(yHaut - y0 - 9, 42))
		local ascenseur = T.modele("Ascenseur", m)
		local ancre = T.volume(ascenseur, Vector3.one, CFrame.new(c.X, y0 + 0.1, c.Z), "Ancre")
		local plateforme = Instance.new("Part")
		plateforme.Name = "Plateforme"
		plateforme.Size = Vector3.new(6, 0.6, 6)
		plateforme.CFrame = CFrame.new(c.X, y0 + 0.4, c.Z)
		plateforme.Color, plateforme.Material = P.boisSombre, Enum.Material.WoodPlanks
		plateforme.Anchored, plateforme.CanQuery = false, false
		plateforme.TopSurface, plateforme.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		plateforme.Parent = ascenseur
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "Rail", "Chariot"
		a0.Axis, a0.SecondaryAxis = Vector3.yAxis, Vector3.xAxis
		a1.Axis, a1.SecondaryAxis = Vector3.yAxis, Vector3.xAxis
		a0.Parent, a1.Parent = ancre, plateforme
		local glissiere = Instance.new("PrismaticConstraint")
		glissiere.Name = "Glissiere"
		glissiere.Attachment0, glissiere.Attachment1 = a0, a1
		glissiere.ActuatorType = Enum.ActuatorType.Servo
		glissiere.ServoMaxForce = 5e7
		glissiere.Speed = 7
		glissiere.LimitsEnabled = true
		glissiere.LowerLimit, glissiere.UpperLimit = 0, hMax
		glissiere.TargetPosition = 0
		glissiere.Parent = plateforme
		-- la cage, soudée à la plateforme (sans masse, traversable)
		local function soude(p: BasePart)
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = plateforme, p
			w.Parent = p
			return p
		end
		local cfCage = CFrame.new(c.X, y0 + 0.4, c.Z)
		soude(T.bloc(ascenseur, Vector3.new(6, 0.4, 6), cfCage * CFrame.new(0, 5.6, 0), P.fer, M.Metal, "Toit"))
		for _, x in {-2.85, 2.85} do
			for _, z in {-2.85, 2.85} do
				soude(T.bloc(ascenseur, Vector3.new(0.3, 5.4, 0.3), cfCage * CFrame.new(x, 2.9, z), P.fer, M.Metal, "Montant"))
			end
		end
		for _, z in {-2.85, 2.85} do
			for k = -2, 2 do
				soude(T.bloc(ascenseur, Vector3.new(0.1, 5, 0.1), cfCage * CFrame.new(k * 1.1, 2.9, z), P.fer, M.Metal, "Grille"))
			end
			soude(T.bloc(ascenseur, Vector3.new(6, 0.25, 0.25), cfCage * CFrame.new(0, 1.1, z), P.fer, M.Metal, "Lisse"))
		end
		local lampe = soude(T.bloc(ascenseur, Vector3.new(0.5, 0.6, 0.5), cfCage * CFrame.new(0, 5, 0), P.ambre, M.Neon, "Lampe"))
		T.lumiere(lampe, P.ambre, 1.2, 18)
		-- le câble : un faisceau tendu entre la roue et le toit de la cage (il suit la cage)
		local hautCable = T.volume(m, Vector3.one, CFrame.new(c.X, yRoue - 4.5, c.Z), "PoulieCable")
		local ah, ab = Instance.new("Attachment"), Instance.new("Attachment")
		ah.Parent = hautCable
		ab.Position = Vector3.new(0, 5.8, 0)
		ab.Parent = plateforme
		local cableBeam = Instance.new("Beam")
		cableBeam.Attachment0, cableBeam.Attachment1 = ah, ab
		cableBeam.Width0, cableBeam.Width1 = 0.3, 0.3
		cableBeam.Color = ColorSequence.new(P.fer)
		cableBeam.LightInfluence, cableBeam.FaceCamera, cableBeam.Segments = 1, true, 1
		cableBeam.Parent = plateforme
		ascenseur:SetAttribute("HMax", hMax)
		T.tag(plateforme, "Ascenseur")
		-- leviers : en bas au bord du puits, en haut dans la galerie secrète
		local function levier(pos: Vector3, vers: Vector3, ou: string)
			local cf = CFrame.lookAt(pos, pos + vers)
			local lv = T.modele("Levier", ascenseur)
			T.bloc(lv, Vector3.new(1.4, 1.2, 1), cf * CFrame.new(0, 0.6, 0), P.fer, M.Metal, "Boitier")
			local manche = T.bloc(lv, Vector3.new(0.25, 2, 0.25), cf * CFrame.new(0, 1.8, 0) * CFrame.Angles(0.5, 0, 0), P.bois, M.Bois, "Manche")
			T.bloc(lv, Vector3.new(0.5, 0.5, 0.5), cf * CFrame.new(0, 2.7, -0.5), Color3.fromRGB(190, 40, 30), M.Lisse, "Pommeau")
			local invite = Instance.new("ProximityPrompt")
			invite.ActionText, invite.ObjectText = "Actionner", "Levier de l'ascenseur"
			invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 0.4, 8, false
			invite:SetAttribute("AscenseurLevier", ou)
			invite.Parent = manche
		end
		-- la galerie secrète en haut : une salle creusée sur le flanc du puits, plancher de planches
		local u = Vector3.new(1, 0, 0)
		do
			local meilleur, roc = u, -1
			for k = 0, 7 do
				local d = Vector3.new(math.cos(k * math.pi / 4), 0, math.sin(k * math.pi / 4))
				local hit = T.trace(c + Vector3.new(0, hMax + 3, 0), d * (R + 16))
				local dist = if hit then hit.Distance else 0
				if dist > roc then
					meilleur, roc = d, dist
				end
			end
			u = meilleur
		end
		local yHautSol = y0 + hMax + 0.7
		local centreGal = c + u * (R + 6.5)
		workspace.Terrain:FillBlock(CFrame.lookAt(Vector3.new(centreGal.X, yHautSol + 4.6, centreGal.Z), Vector3.new(centreGal.X, yHautSol + 4.6, centreGal.Z) + u),
			Vector3.new(11, 9, 13), Enum.Material.Air)
		local galerie = T.modele("GalerieSecrete", m)
		local cfG = CFrame.lookAt(Vector3.new(c.X, yHautSol, c.Z) + u * (R - 0.2), Vector3.new(c.X, yHautSol, c.Z) + u * (R + 10))
		for k = 0, 12 do
			T.solide(galerie, Vector3.new(10.5, 0.4, 1), cfG * CFrame.new(0, -0.2, -k * 1.02 - 0.5), if k % 2 == 0 then P.boisClair else P.bois, M.Bois, "Planche")
		end
		for _, x in {-5, 5} do
			T.bloc(galerie, Vector3.new(0.9, 8.5, 0.9), cfG * CFrame.new(x, 4, -1), P.bois, M.Bois, "Poteau")
		end
		T.bloc(galerie, Vector3.new(11, 0.9, 1), cfG * CFrame.new(0, 8.4, -1), P.boisSombre, M.Bois, "Chapeau")
		local enseigne = O.bloc(galerie, Vector3.new(7, 1.4, 0.3), cfG * CFrame.new(0, 7.2, -1.4), P.boisClair, Enum.Material.WoodPlanks, "Enseigne")
		O.decor(enseigne)
		O.texte(enseigne, Enum.NormalId.Front, "RÉSERVE DU CONTREMAÎTRE")
		lanterne(cfG * CFrame.new(-3.5, 5, -6), P.ambre, true)
		local cf2 = B.caisse(decor, cfG * CFrame.new(3.5, 0, -10))
		if cf2 then O.decorModele(cf2) end
		-- le trésor : de l'or et du fer, à miner (rocher effacé une fois cassé : SecretsGrotte)
		local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))
		for i, t in {{"Gold", 9}, {"Gold", 9}, {"Fer", 7}} do
			local pos = (cfG * CFrame.new((i - 2) * 3.2, 0, -8)).Position
			local s = MineraisModeles.VISUEL[t[1]].taille
			local mm, coeur = MineraisModeles.construire(t[1], CFrame.new(pos - Vector3.new(0, 1.25 * s - 0.1, 0)), Random.new(rng:NextInteger(1, 1e6)), true)
			for _, p in mm:GetChildren() do
				if p:IsA("BasePart") then
					p.CanQuery = p == coeur
				end
			end
			coeur:SetAttribute("Type", t[1])
			coeur:SetAttribute("Taille", s)
			coeur:SetAttribute("PV", t[2])
			coeur:SetAttribute("PVMax", t[2])
			coeur:SetAttribute("Proprietaire", ctx.proprietaire)
			if ctx.invite then
				coeur:SetAttribute("Invite", ctx.invite)
			end
			coeur:SetAttribute("Secret", true)
			T.tag(coeur, "Minerai")
			mm.Parent = galerie
		end
		levier(Vector3.new(c.X, yHautSol, c.Z) + u * (R + 1.5) + Vector3.new(-u.Z, 0, u.X) * 3.5, -u, "haut")
		local qL = T.solEn(c + Vector3.new(-u.Z, 0, u.X) * (R + 2.5))
		if qL then
			levier(qL.Position, -Vector3.new(-u.Z, 0, u.X), "bas")
		end
		for _, x in {-3.2, 3.2} do
			local cb = T.bloc(m, Vector3.new(0.18, yRoue - y0, 0.18), CFrame.new(c.X + x, (yRoue + y0) / 2, c.Z + 1.5), P.fer, M.Metal, "CableGuide")
			cb.CastShadow = false
		end
		-- colonne de jour qui tombe du haut du puits
		local source = T.volume(m, Vector3.new(R * 1.6, 1, R * 1.6), CFrame.new(c.X, yHaut - 1, c.Z), "LumiereJour")
		local spot = T.lumiere(source, P.jour, 3, 60, "SpotLight")
		if spot then
			(spot :: any).Face = Enum.NormalId.Bottom;
			(spot :: any).Angle = 30;
			(spot :: any).Shadows = true
		end
		local poussiere = T.volume(m, Vector3.new(R * 1.4, yPlafond - y0, R * 1.4), CFrame.new(c.X, (yPlafond + y0) / 2, c.Z), "PoussierePuits")
		T.emetteur(poussiere, {
			Name = "Poussiere", Texture = GT.TEX_LUEUR, LightEmission = 0.8, LightInfluence = 0, Color = ColorSequence.new(P.jour),
			Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.16), T.kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 10,
			Speed = NumberRange.new(0.1, 0.4), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.1, 0),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
		-- tas de minerai et seaux au pied du puits, échelle collée à la paroi
		for k = 1, 3 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 3))
			if q and T.solLibre(q.Position, 1, 4) then
				local t = B.tonneau(decor, CFrame.new(q.Position) * CFrame.Angles(0, a, 0))
				if t then O.decorModele(t) end
			end
		end
		local hitE = outils.paroi(c + Vector3.new(0, 2, 0), Vector3.new(1, 0, 0), 2, s.r * 1.6)
		if hitE then
			local n = hitE.Normal
			local bas = hitE.Position + n * 0.6
			local hE = math.min(yPlafond - y0 + 4, 26)
			local ech = T.modele("Echelle", m)
			for _, d in {-0.7, 0.7} do
				T.bloc(ech, Vector3.new(0.3, hE, 0.3), CFrame.lookAt(bas + Vector3.new(0, hE / 2 - 1.5, 0), bas + Vector3.new(0, hE / 2 - 1.5, 0) - n) * CFrame.new(d, 0, 0), P.bois, M.Bois, "Montant")
			end
			for k = 0, math.floor(hE / 1.2) do
				T.bloc(ech, Vector3.new(1.6, 0.2, 0.2), CFrame.lookAt(bas + Vector3.new(0, k * 1.2 - 1.2, 0), bas + Vector3.new(0, k * 1.2 - 1.2, 0) - n), P.boisClair, M.Bois, "Barreau")
			end
		end
		T.zone(c, s.r + 6, P.jour:Lerp(P.amethyste, 0.3), "Puits")
		T.interdire(c, R + 1)
	end

	-- ===== 5. LA CATHÉDRALE D'AMÉTHYSTE =====
	local function cristal(parent, base: CFrame, h: number, couleur: Color3, nom: string)
		-- prisme à 8 faces (deux blocs tournés de 45°) en verre teinté, pointe en pyramide, fin cœur lumineux
		local largeur = h * rng:NextNumber(0.2, 0.28)
		local hc = h * 0.76
		local sombre = couleur:Lerp(Color3.new(0, 0, 0), 0.5):Lerp(P.violetSombre, 0.3)
		local corps = nil
		for k = 0, 1 do
			local b = T.bloc(parent, Vector3.new(largeur, hc, largeur), base * CFrame.new(0, hc / 2, 0) * CFrame.Angles(0, k * math.pi / 4, 0), sombre, Enum.Material.SmoothPlastic, nom)
			b.Transparency = 0.06
			b.Reflectance = 0.12
			b.CastShadow = false
			corps = corps or b
		end
		local hp = h - hc
		for k = 0, 3 do
			local w = T.coin(parent, Vector3.new(largeur, hp, largeur * 0.5),
				base * CFrame.new(0, hc + hp / 2, 0) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 8, 0) * CFrame.new(0, 0, largeur * 0.25),
				sombre, Enum.Material.SmoothPlastic, nom .. "Pointe")
			w.Transparency = 0.06
			w.CastShadow = false
		end
		local coeur = T.bloc(parent, Vector3.new(largeur * 0.22, hc * 0.9, largeur * 0.22), base * CFrame.new(0, hc * 0.5, 0), couleur, M.Neon, nom .. "Coeur")
		coeur.Transparency = 0.15
		coeur.CastShadow = false
		T.tag(coeur, "GrottePulse")
		return corps
	end
	local function grappe(base: CFrame, taille: number, couleur: Color3)
		local m = T.modele("GrappeAmethyste")
		for k = 1, rng:NextInteger(4, 7) do
			local inc = CFrame.Angles(rng:NextNumber(-0.55, 0.55), rng:NextNumber(0, 6), rng:NextNumber(-0.55, 0.55))
			cristal(m, base * CFrame.new(rng:NextNumber(-1, 1) * taille * 0.3, -0.3, rng:NextNumber(-1, 1) * taille * 0.3) * inc,
				taille * rng:NextNumber(0.45, 1), if k % 3 == 0 then P.lilas else couleur, "Cristal")
		end
		return m
	end
	if cathedrale then
		local s = cathedrale
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		-- le cristal-roi au centre (hors passage : décalé si besoin)
		local centre = Vector3.new(s.p.X, y0, s.p.Z)
		local roi, dirRoi = T.coinSalle(s, s.r * 0.45)
		local solRoi = T.solEn(roi)
		if solRoi then
			local m = T.modele("CristalRoi")
			local base = CFrame.new(solRoi.Position - Vector3.new(0, 0.5, 0))
			cristal(m, base * CFrame.Angles(0.08, 0, 0.05), 18, P.amethyste, "CristalRoi")
			for k = 1, 6 do
				local a = k / 6 * 2 * math.pi
				cristal(m, base * CFrame.new(math.cos(a) * 2.6, 0, math.sin(a) * 2.6) * CFrame.Angles(math.cos(a) * 0.45, a, math.sin(a) * 0.45),
					rng:NextNumber(5, 9), if k % 2 == 0 then P.lilas else P.amethyste, "CristalSatellite")
			end
			local l = T.volume(m, Vector3.one, base * CFrame.new(0, 10, 0) + dirRoi * -7, "LueurRoi")
			T.remplir(l, P.amethyste, 0.4, 30)
			T.emetteur(l, {
				Name = "Eclats", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.lilas, P.amethyste),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.4, 0.35), T.kp(1, 0)}), Lifetime = NumberRange.new(2, 4), Rate = 12,
				Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.6, 0),
			})
			T.interdire(solRoi.Position, 6)
		end
		-- grappes au pied des parois, et d'autres qui sortent des murs
		for k = 1, 12 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local p = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.65, 0.95)
			local q = T.solEn(p)
			if q and T.solLibre(q.Position, 2, 5) then
				grappe(CFrame.new(q.Position), rng:NextNumber(3, 6), P.amethyste)
			end
		end
		for k = 1, 8 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local hit = outils.paroi(centre, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(3, 14), s.r * 1.8)
			if hit then
				grappe(outils.axeVers(hit.Position - hit.Normal * 0.5, hit.Normal), rng:NextNumber(2.5, 5), if k % 2 == 0 then P.lilas else P.amethyste)
			end
		end
		T.particulesSalle(s, {
			Name = "PoussiereAmethyste", Texture = GT.TEX_LUEUR, LightEmission = 1, Color = ColorSequence.new(P.lilas),
			Size = NumberSequence.new({T.kp(0, 0), T.kp(0.3, 0.2), T.kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 12,
			Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 180),
		})
		T.zone(centre, s.r + 8, P.amethyste, "Geode")
	end
	-- petites grappes d'améthyste le long des galeries
	for i = 1, 18 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 6), pt.r + 6)
		if hit and (hit.Position - depart.p).Magnitude > 22 then
			grappe(outils.axeVers(hit.Position - hit.Normal * 0.4, hit.Normal), rng:NextNumber(1.2, 2.4), if i % 3 == 0 then P.lilas else P.amethyste)
		end
	end

	-- ===== 6. L'éboulement =====
	if effondree then
		local s = effondree
		local coinP, dir = T.coinSalle(s, s.r * 0.6)
		local m = T.modele("Eboulement")
		for k = 1, 16 do
			local q = T.solEn(coinP + Vector3.new(rng:NextNumber(-7, 7), 0, rng:NextNumber(-7, 7)))
			if q and not T.surChemin(q.Position, 5) then
				local t = rng:NextNumber(1.5, 4.5)
				local r = T.bloc(m, Vector3.new(t, t * rng:NextNumber(0.6, 1), t * rng:NextNumber(0.7, 1.2)),
					CFrame.new(q.Position + Vector3.new(0, t * 0.3, 0)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
					P.roche:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.3)), Enum.Material.Basalt, "Rocher")
			end
		end
		for k = 1, 4 do
			local q = T.solEn(coinP + Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5)))
			if q and not T.surChemin(q.Position, 5) then
				T.bloc(m, Vector3.new(0.9, 0.9, rng:NextNumber(6, 10)), CFrame.new(q.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)),
					P.bois, M.Bois, "PoutreBrisee")
			end
		end
		local qPanneau = T.solEn(coinP - dir * 8)
		if qPanneau and not T.surChemin(qPanneau.Position, 3) then
			local cf = CFrame.lookAt(qPanneau.Position, qPanneau.Position - dir)
			T.bloc(m, Vector3.new(0.4, 3.6, 0.4), cf * CFrame.new(0, 1.8, 0), P.bois, M.Bois, "Piquet")
			local p = O.bloc(m, Vector3.new(4, 1.6, 0.25), cf * CFrame.new(0, 3.4, -0.3) * CFrame.Angles(0, 0, 0.08), Color3.fromRGB(200, 150, 40), Enum.Material.WoodPlanks, "Panneau")
			O.decor(p)
			O.texte(p, Enum.NormalId.Front, "DANGER")
		end
		local poussiere = T.volume(m, Vector3.new(12, 6, 12), CFrame.new(coinP + Vector3.new(0, 4, 0)), "PoussiereEboulement")
		T.emetteur(poussiere, {
			Name = "Poussiere", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(Color3.fromRGB(110, 100, 115)), LightInfluence = 0.8,
			Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.8), T.kp(1, 1)}), Size = NumberSequence.new(4, 8),
			Lifetime = NumberRange.new(6, 10), Rate = 2, Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 180),
			Shape = Enum.ParticleEmitterShape.Box,
		})
		T.zone(coinP, s.r, P.ambre:Lerp(P.roche, 0.4), "Eboulement")
		T.interdire(coinP, 9)
	end

	-- ===== 7. Échafaudages contre les parois des autres salles =====
	for _, s in salles do
		if not s.depart and not s.boss and roles[s] ~= "eboulement" and s.r >= 13 and rng:NextNumber() < 0.75 then
			local a = rng:NextNumber(0, 2 * math.pi)
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local hit = outils.paroi(s.p, dir, 3, s.r * 1.6)
			if hit then
				local n = T.unite(plat(hit.Normal), -dir)
				local pied = T.solEn(hit.Position + n * 2.6)
				if pied and T.solLibre(pied.Position, 2, 4) then
					local cf = CFrame.lookAt(pied.Position, pied.Position + n)
					local m = T.modele("Echafaudage")
					local H = rng:NextNumber(6, 9)
					for _, x in {-3, 3} do
						for _, z in {-1.6, 1.6} do
							T.bloc(m, Vector3.new(0.5, H + 1, 0.5), cf * CFrame.new(x, (H + 1) / 2, z), P.bois, M.Bois, "Poteau")
						end
					end
					for k = 0, 3 do
						T.bloc(m, Vector3.new(1.1, 0.25, 4), cf * CFrame.new(-2.4 + k * 1.6, H, 0), if k % 2 == 0 then P.boisClair else P.bois, M.Bois, "Planche")
					end
					T.bloc(m, Vector3.new(6.8, 0.3, 0.3), cf * CFrame.new(0, H + 1.1, -1.6), P.boisSombre, M.Bois, "Garde")
					T.bloc(m, Vector3.new(0.4, H, 0.25), cf * CFrame.new(3.6, H / 2, -1.2) * CFrame.Angles(0.15, 0, 0), P.bois, M.Bois, "Echelle")
					local c = B.caisse(decor, cf * CFrame.new(-1.5, H + 0.1, 0.5))
					if c then O.decorModele(c) end
					lanterne(cf * CFrame.new(1.8, H + 1.5, 0), P.ambre, true)
				end
			end
		end
	end

	-- ===== 8. Lanternes fantômes qui flottent (animées par VieGrotte comme les méduses) =====
	local nFantomes = 0
	for _, s in salles do
		if not s.depart and nFantomes < 10 then
			for _ = 1, (if s.r >= 18 then 2 else 1) do
				local a = rng:NextNumber(0, 2 * math.pi)
				local p = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.2, 0.6)
				local sol = T.solEn(p, 8)
				if sol then
					nFantomes += 1
					local pos = sol.Position + Vector3.new(0, rng:NextNumber(6, 10), 0)
					local m = lanterne(CFrame.new(pos), P.fantome, nFantomes % 3 == 0)
					m.Name = "LanterneFantome"
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") and d.Name ~= "Flamme" then
							d.Transparency = 0.55
							d.Color = P.fantome:Lerp(Color3.new(0, 0, 0), 0.5)
						end
					end
					local flamme = m:FindFirstChild("Flamme")
					if flamme then
						T.emetteur(flamme, {
							Name = "Volutes", Texture = GT.TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.fantome),
							Size = NumberSequence.new({T.kp(0, 0.4), T.kp(1, 0)}), Transparency = NumberSequence.new(0.3, 1),
							Lifetime = NumberRange.new(1, 2), Rate = 6, Speed = NumberRange.new(0.3, 0.8), Acceleration = Vector3.new(0, 1, 0),
						})
					end
					m.PrimaryPart = flamme :: BasePart?
					m:SetAttribute("Origine", pos)
					T.tag(m, "GrotteMeduse")
				end
			end
		end
	end

	-- ===== 9. Salle du fond : LE TREUIL GÉANT et le filon d'améthyste =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local fond, dirFond = T.coinSalle(s, T.rb * 0.55)
		local qT = T.solEn(fond)
		if qT then
			local cf = CFrame.lookAt(qT.Position, qT.Position - dirFond)
			local m = T.modele("TreuilGeant")
			for _, x in {-6, 6} do
				T.bloc(m, Vector3.new(1.6, 10, 3), cf * CFrame.new(x, 5, 0), P.boisSombre, M.Bois, "Chevalet")
				T.bloc(m, Vector3.new(1.8, 1.2, 4), cf * CFrame.new(x, 0.6, 0), P.roche, Enum.Material.Cobblestone, "Socle")
			end
			T.disque(m, 10, 5, cf * CFrame.new(0, 8, 0), P.bois, M.Bois, "Tambour")
			for k = -2, 2 do
				T.disque(m, 0.4, 5.3, cf * CFrame.new(k * 2, 8, 0), P.fer, M.Metal, "Cerclage")
			end
			for _, x in {-7.5, 7.5} do
				local eng = T.modele("Engrenage", m)
				T.disque(eng, 0.7, 7, cf * CFrame.new(x, 8, 0), P.rouille, M.Metal, "Disque")
				for k = 0, 11 do
					local a = k / 12 * 2 * math.pi
					T.bloc(eng, Vector3.new(0.7, 0.9, 0.9), cf * CFrame.new(x, 8 + math.cos(a) * 3.6, math.sin(a) * 3.6) * CFrame.Angles(a, 0, 0), P.rouille, M.Metal, "Dent")
				end
				for k = 0, 3 do
					T.bloc(eng, Vector3.new(0.75, 6, 0.6), cf * CFrame.new(x, 8, 0) * CFrame.Angles(k * math.pi / 4, 0, 0), P.fer, M.Metal, "Rayon")
				end
				eng.WorldPivot = cf * CFrame.new(x, 8, 0)
				eng:SetAttribute("Vitesse", if x < 0 then 0.5 else -0.5)
				eng:SetAttribute("Axe", "X")
				T.tag(eng, "Rouage")
			end
			-- chaînes qui montent vers la voûte
			local haut = T.plafondEn(qT.Position + Vector3.new(0, 10, 0), 60)
			local yH = if haut then haut.Position.Y else qT.Position.Y + 30
			for _, x in {-2.5, 2.5} do
				local q = (cf * CFrame.new(x, 10.5, -1)).Position
				T.bloc(m, Vector3.new(0.35, yH - q.Y, 0.35), CFrame.new(q.X, (yH + q.Y) / 2, q.Z), P.fer, M.Metal, "ChaineVoute").CastShadow = false
			end
			lanterne(cf * CFrame.new(-6, 11, -2), P.ambre, true)
			lanterne(cf * CFrame.new(6, 11, -2), P.ambre, true)
			T.interdire(qT.Position, 9)
		end
		-- le filon : une veine d'améthyste géante dans la paroi du fond
		local hit = outils.paroi(Vector3.new(s.p.X, y0, s.p.Z), dirFond, 6, T.rb * 2.2)
		if hit then
			for k = 1, 3 do
				T.veine(hit, rng:NextInteger(10, 16), if k % 2 == 0 then P.lilas else P.amethyste, rng:NextNumber(0.35, 0.5), 2)
			end
			grappe(outils.axeVers(hit.Position - hit.Normal * 0.6, hit.Normal), 7, P.amethyste)
			local l = T.volume(decor, Vector3.one, CFrame.new(hit.Position + hit.Normal * 4), "LueurFilon")
			T.lumiere(l, P.amethyste, 2, 40)
		end
		T.zone(Vector3.new(s.p.X, y0, s.p.Z), T.rb + 8, P.amethyste:Lerp(P.ambre, 0.35), "Treuil")
	end

	-- ===== 10. Décor générique (stalactites, colonnes, racines, restes de mine) en palette violette =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, mine = false, couleurs = COUL_GENERIQUE})

	-- ===== 11. Veines, galets, éclairage de lisibilité, guide =====
	T.veinesEtGalets({P.amethyste, P.amethyste, Color3.fromRGB(110, 60, 200)}, 4, P.amethyste)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.ambre:Lerp(P.jour, 0.3) end
			if roles[s] == "puits" then return P.jour:Lerp(P.amethyste, 0.25) end
			if roles[s] == "geode" then return P.amethyste:Lerp(P.jour, 0.3) end
			if roles[s] == "eboulement" then return P.ambre:Lerp(P.jour, 0.4) end
			if s.boss then return P.amethyste:Lerp(P.ambre, 0.4) end
			return P.lilas:Lerp(P.jour, 0.45)
		end,
		galerie = P.ambre:Lerp(P.jour, 0.45),
		lum = 0.55,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "MineOubliee")
end

return GrotteMine
