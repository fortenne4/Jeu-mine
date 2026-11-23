--[[ Grotte −200 m « La Fonderie de l'Abîme » (palier 3, Abîme de fer) : habillage complet.
	L'ancienne fonderie royale de Brumefer, où l'on coulait le fer des rois. Les fours brûlent encore.
	- Porte de la fonderie à l'arrivée : cadre de pierre, deux battants de fer ouverts, braseros, bannières
	- L'ABÎME : la plus grande salle est un gouffre au fond duquel bouillonne le fer en fusion ; des ponts de
	  planches à garde-corps de chaînes mènent à un pilier central (enclume, brasero) ; chaînes qui plongent
	- LA FONDERIE : creuset géant suspendu qui déverse une coulée de fer, rigoles incandescentes, moules et
	  lingots, haut-fourneau contre la paroi (gueule ardente, cheminée), enclumes et marteaux
	- LA SALLE DES ROUAGES : engrenages géants qui tournent contre les parois, arbres de transmission
	- Galeries : conduites de fer le long des parois, braseros sur pied, chaînes qui pendent
	- Salle du fond : LA GRANDE FORGE DES ROIS (statue d'un nain forgeron qui lève son marteau, enclume géante,
	  bassin de métal fondu, braseros)
	- Braises qui volent partout, veines de fer chauffé au rouge, galets de braise, lumière chaude
	Zones : Camp, Abime, Fonderie, Rouages, Forge. Le gouffre ramène au bord qui tombe (DangersGrotte). ]]

local GT = require(script.Parent.GrotteTheme)
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local GrotteFonderie = {}

local P = {
	fonte = Color3.fromRGB(46, 44, 50),
	fer = Color3.fromRGB(78, 78, 86),
	rouille = Color3.fromRGB(128, 72, 44),
	cuivre = Color3.fromRGB(184, 104, 56),
	bronze = Color3.fromRGB(176, 120, 60),
	fondu = Color3.fromRGB(255, 128, 30),
	braise = Color3.fromRGB(255, 84, 24),
	blancChaud = Color3.fromRGB(255, 225, 150),
	pierre = Color3.fromRGB(84, 78, 78),
	pierreSombre = Color3.fromRGB(52, 48, 50),
	rouge = Color3.fromRGB(150, 30, 26),
	or_ = Color3.fromRGB(255, 196, 80),
	bois = Color3.fromRGB(86, 58, 38),
}

local COUL_GENERIQUE = {
	Roche = {Color3.fromRGB(70, 64, 66), Enum.Material.Basalt},
	Goutte = {Color3.fromRGB(255, 200, 150), Enum.Material.Glass, 0.4},
	Lueur = {P.fondu, Enum.Material.Neon},
}

function GrotteFonderie.decorer(ctx, infos, outils)
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
	-- le gouffre va dans la salle qui laisse la plus grande fosse ; puis la fonderie et les rouages dans les plus grandes
	local abime = T.salleFosse(candidates)
	local reste = {}
	for _, s in candidates do
		if s ~= abime then
			table.insert(reste, s)
		end
	end
	local fonderie, rouages = reste[1], reste[2]
	local roles = {}

	local function feu(part: BasePart, taille: number, eclaire: boolean)
		T.emetteur(part, {
			Name = "Feu", Texture = GT.TEX_FEU, LightEmission = 1, LightInfluence = 0,
			Color = ColorSequence.new({ColorSequenceKeypoint.new(0, P.blancChaud), ColorSequenceKeypoint.new(0.5, P.fondu), ColorSequenceKeypoint.new(1, P.braise)}),
			Size = NumberSequence.new({T.kp(0, taille), T.kp(1, taille * 0.2)}), Transparency = NumberSequence.new({T.kp(0, 0.2), T.kp(1, 1)}),
			Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(15, 15), Rate = 30,
			EmissionDirection = Enum.NormalId.Top,
		})
		T.emetteur(part, {
			Name = "Braises", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.fondu),
			Size = NumberSequence.new({T.kp(0, 0.15), T.kp(1, 0)}), Lifetime = NumberRange.new(1, 2.5), Speed = NumberRange.new(3, 7),
			SpreadAngle = Vector2.new(30, 30), Rate = 6, EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, 2, 0),
		})
		if eclaire then
			T.lumiere(part, P.fondu, 1.6, 20)
		end
	end

	-- brasero de fer sur pied
	local nBraseros = 0
	local function brasero(pos: Vector3, h: number?)
		local hh = h or 3
		local m = T.modele("BraseroFer")
		T.bloc(m, Vector3.new(0.4, hh, 0.4), CFrame.new(pos + Vector3.new(0, hh / 2, 0)), P.fonte, M.Metal, "Pied")
		T.bloc(m, Vector3.new(1.6, 0.3, 1.6), CFrame.new(pos + Vector3.new(0, 0.15, 0)), P.fonte, M.Metal, "Base")
		local coupe = T.cylindre(m, 0.8, 2.2, CFrame.new(pos + Vector3.new(0, hh + 0.3, 0)), P.fer, M.Metal, "Coupe")
		local charbons = T.cylindre(m, 0.3, 1.9, CFrame.new(pos + Vector3.new(0, hh + 0.7, 0)), P.braise, M.Neon, "Charbons")
		charbons.CastShadow = false
		T.tag(charbons, "GrottePulse")
		nBraseros += 1
		feu(charbons, 1.4, nBraseros % 2 == 1)
		if nBraseros % 2 == 0 then
			T.remplir(charbons, P.fondu, 0.7, 18)
		end
		return m
	end

	-- ===== 1. Porte de la fonderie =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local base = T.solEn(depart.p + avant * 12)
		if base then
			local cf = CFrame.lookAt(base.Position, base.Position + avant)
			local m = T.modele("PorteFonderie")
			for _, x in {-7, 7} do
				T.bloc(m, Vector3.new(2.4, 15, 2.4), cf * CFrame.new(x, 7.5, 0), P.pierre, Enum.Material.Cobblestone, "Pilier")
				T.bloc(m, Vector3.new(3, 1, 3), cf * CFrame.new(x, 15.3, 0), P.pierreSombre, Enum.Material.Slate, "Chapiteau")
			end
			T.bloc(m, Vector3.new(17, 2.2, 2.6), cf * CFrame.new(0, 16.4, 0), P.pierreSombre, Enum.Material.Slate, "Linteau")
			local enseigne = O.bloc(m, Vector3.new(10, 1.6, 0.3), cf * CFrame.new(0, 16.4, -1.45), P.fonte, Enum.Material.Metal, "Inscription")
			O.decor(enseigne)
			O.texte(enseigne, Enum.NormalId.Front, "FONDERIE ROYALE")
			-- battants ouverts, renforcés de bandes rivetées
			for _, sx in {-1, 1} do
				local charniere = cf * CFrame.new(sx * 5.6, 0, 0)
				local ouvert = charniere * CFrame.Angles(0, sx * math.rad(70), 0)
				local b = T.bloc(m, Vector3.new(5.4, 13, 0.6), ouvert * CFrame.new(-sx * 2.7, 6.5, 0), P.fer, M.Metal, "Battant")
				for k = 1, 4 do
					T.bloc(m, Vector3.new(5.5, 0.4, 0.7), ouvert * CFrame.new(-sx * 2.7, k * 2.8, 0), P.fonte, M.Metal, "Bande")
				end
			end
			-- bannières rouges et or
			for _, x in {-7, 7} do
				local ban = T.bloc(m, Vector3.new(2, 6, 0.15), cf * CFrame.new(x, 10.5, -1.35), P.rouge, Enum.Material.Fabric, "Banniere")
				T.bloc(m, Vector3.new(2.1, 0.3, 0.2), cf * CFrame.new(x, 7.5, -1.4), P.or_, M.Metal, "Frange")
				T.bloc(m, Vector3.new(0.8, 0.8, 0.2), cf * CFrame.new(x, 11, -1.45) * CFrame.Angles(0, 0, math.rad(45)), P.or_, M.Neon, "Embleme")
			end
			brasero(base.Position + (cf.RightVector * -9) - avant * 2)
			brasero(base.Position + (cf.RightVector * 9) - avant * 2)
			T.interdire(base.Position, 9)
		end
		T.zone(depart.p, 34, P.fondu:Lerp(P.blancChaud, 0.4), "Camp")
	end

	-- ===== 2. L'ABÎME =====
	if abime then
		local fosse = T.fosse(abime, {
			profondeur = 36, pilier = 6,
			pont = function(u, d0, d1, yA, yB)
				T.pontPlanches(Vector3.new(abime.p.X, 0, abime.p.Z), u, d0, d1, yA, yB,
					{planche = P.bois, planche2 = Color3.fromRGB(104, 72, 46), poteau = P.fonte, materiauPoteau = M.Metal, chaine = P.fer})
			end,
		})
		if fosse then
			roles[abime] = "abime"
			local c = fosse.c
			-- le fer en fusion au fond
			local fond = T.cylindre(decor, 1, fosse.f * 2 - 1, CFrame.new(c.X, fosse.fond + 1, c.Z), P.fondu, M.Neon, "FerFondu")
			fond.CastShadow = false
			T.tag(fond, "GrottePulse")
			local croute = T.cylindre(decor, 1.1, fosse.f * 1.2, CFrame.new(c.X + fosse.f * 0.3, fosse.fond + 1.05, c.Z), P.braise:Lerp(P.fonte, 0.6), M.Neon, "Croute")
			croute.CastShadow = false
			local chaleur = T.volume(decor, Vector3.new(fosse.f * 1.8, 2, fosse.f * 1.8), CFrame.new(c.X, fosse.fond + 3, c.Z), "Chaleur")
			T.emetteur(chaleur, {
				Name = "Braises", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.blancChaud, P.braise),
				Size = NumberSequence.new({T.kp(0, 0.3), T.kp(1, 0)}), Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(4, 9),
				SpreadAngle = Vector2.new(15, 15), Rate = 40, EmissionDirection = Enum.NormalId.Top, Shape = Enum.ParticleEmitterShape.Box,
			})
			T.emetteur(chaleur, {
				Name = "Fumee", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(Color3.fromRGB(110, 60, 40)), LightInfluence = 0.5,
				Size = NumberSequence.new(6, 14), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.75), T.kp(1, 1)}),
				Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(3, 6), Rate = 3, EmissionDirection = Enum.NormalId.Top,
				Shape = Enum.ParticleEmitterShape.Box,
			})
			T.lumiere(chaleur, P.fondu, 3, 60)
			-- le pilier : enclume des maîtres et brasero
			local enclume = T.modele("EnclumePilier")
			T.bloc(enclume, Vector3.new(2.4, 1.6, 1.4), CFrame.new(c + Vector3.new(1.5, 0.8, 0)), P.pierreSombre, Enum.Material.Slate, "Socle")
			T.bloc(enclume, Vector3.new(3.4, 0.9, 1.3), CFrame.new(c + Vector3.new(1.5, 2.05, 0)), P.fonte, M.Metal, "Table")
			T.coin(enclume, Vector3.new(1.3, 0.9, 1.6), CFrame.new(c + Vector3.new(3.9, 2.05, 0)) * CFrame.Angles(0, -math.pi / 2, 0), P.fonte, M.Metal, "Bigorne")
			brasero(c + Vector3.new(-2.5, 0, 1.5), 2.5)
			-- chaînes géantes qui plongent du plafond dans le gouffre
			for k = 1, 5 do
				local a = rng:NextNumber(0, 2 * math.pi)
				local q = c + Vector3.new(math.cos(a), 0, math.sin(a)) * fosse.f * rng:NextNumber(0.4, 0.8)
				local haut = T.plafondEn(q + Vector3.new(0, 4, 0), 80)
				if haut then
					local bas = fosse.fond + rng:NextNumber(8, 20)
					local L = haut.Position.Y - bas
					local ch = T.modele("ChaineGeante")
					local n = math.floor(L / 1.6)
					for i = 0, n do
						local y = haut.Position.Y - i * 1.6
						T.bloc(ch, Vector3.new(0.35, 1.9, 0.9), CFrame.new(q.X, y, q.Z) * CFrame.Angles(0, (i % 2) * math.pi / 2, 0), P.fonte, M.Metal, "Maillon").CastShadow = false
					end
					T.bloc(ch, Vector3.new(0.6, 2.4, 0.6), CFrame.new(q.X, bas - 1, q.Z), P.fer, M.Metal, "Crochet")
				end
			end
			-- le coffre de l'Abîme : sur un plateau de fer, tout au fond du gouffre ; quand les trois rouages tournent,
			-- il remonte le long du pilier (MecaniquesGrotte : « Rouages »)
			local u = Vector3.new(1, 0, 0)
			do
				local meilleur, score = u, -math.huge
				for k = 0, 15 do
					local v = Vector3.new(math.cos(k * math.pi / 8), 0, math.sin(k * math.pi / 8))
					local mm = 2
					for _, d in fosse.dirs do
						mm = math.min(mm, 1 - v:Dot(d))
					end
					if mm > score then
						meilleur, score = v, mm
					end
				end
				u = meilleur
			end
			local cfHaut = CFrame.lookAt(c + u * (fosse.pilier + 2.4), c + u * (fosse.pilier + 2.4) - u)
			local cfBas = cfHaut - Vector3.new(0, fosse.prof - 5, 0)
			local co = T.modele("CoffreAbime")
			T.solide(co, Vector3.new(4.6, 0.4, 4.6), cfBas * CFrame.new(0, -0.2, 0), P.fonte, M.Metal, "Plateau")
			local caisse = T.bloc(co, Vector3.new(3.4, 1.8, 2.2), cfBas * CFrame.new(0, 0.9, 0), Color3.fromRGB(70, 46, 30), M.Bois, "Caisse")
			for _, x in {-1.2, 1.2} do
				T.bloc(co, Vector3.new(0.3, 1.9, 2.3), cfBas * CFrame.new(x, 0.9, 0), P.fer, M.Metal, "Bande")
			end
			T.bloc(co, Vector3.new(3.5, 0.6, 2.3), cfBas * CFrame.new(0, 2.1, 0), Color3.fromRGB(60, 40, 26), M.Bois, "Couvercle")
			T.bloc(co, Vector3.new(0.6, 0.6, 0.2), cfBas * CFrame.new(0, 1.5, -1.15), P.or_, M.Neon, "Serrure")
			for _, x in {-2.1, 2.1} do
				for _, z in {-2.1, 2.1} do
					T.bloc(co, Vector3.new(0.25, 26, 0.25), cfBas * CFrame.new(x, 13, z), P.fer, M.Metal, "Chaine").CastShadow = false
				end
			end
			local lueur = T.volume(co, Vector3.one, cfBas * CFrame.new(0, 3, 0), "LueurCoffre")
			T.lumiere(lueur, P.or_, 1.2, 16)
			local invite = Instance.new("ProximityPrompt")
			invite.ActionText, invite.ObjectText = "Ouvrir", "Coffre de l'Abîme"
			invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 0.8, 9, false
			invite.Enabled = false
			invite:SetAttribute("CoffreAbime", true)
			invite.Parent = caisse
			co.WorldPivot = cfBas
			co:SetAttribute("Cible", cfHaut)
			T.zone(c, fosse.f + 10, P.fondu, "Abime")
		end
	end

	-- ===== 3. LA FONDERIE =====
	if fonderie then
		roles[fonderie] = "fonderie"
		local s = fonderie
		local coinP, dir = T.coinSalle(s, s.r * 0.5)
		local sol = T.solEn(coinP)
		if sol then
			local base = sol.Position
			local cf = CFrame.lookAt(base, base - dir)
			local m = T.modele("Fonderie")
			-- creuset suspendu, droit et froid ; la manivelle le fait basculer (MecaniquesGrotte : « Fonderie royale »)
			local haut = T.plafondEn(base + Vector3.new(0, 4, 0), 60)
			local BASCULE = math.rad(28)
			local cfAxe = cf * CFrame.new(0, 11.5, 2) -- axe des tourillons
			local cfC = cfAxe * CFrame.new(0, -0.5, 0)
			local creuset = T.modele("Creuset", m)
			T.cylindre(creuset, 4.5, 6, cfC, P.fonte, M.Metal, "Cuve")
			T.cylindre(creuset, 0.4, 6.6, cfC * CFrame.new(0, 2.2, 0), P.fer, M.Metal, "Levre")
			local bain = T.cylindre(creuset, 0.3, 5.2, cfC * CFrame.new(0, 2.05, 0), P.fondu, M.Neon, "Bain")
			bain.CastShadow = false
			T.tag(bain, "GrottePulse")
			T.coin(creuset, Vector3.new(1.4, 0.6, 1.2), cfC * CFrame.new(0, 2.1, -3.3) * CFrame.Angles(0, math.pi, 0), P.fer, M.Metal, "Bec")
			for _, x in {-3.4, 3.4} do
				T.cylindre(creuset, 0.9, 1.4, cfAxe * CFrame.new(x, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), P.fer, M.Metal, "Tourillon")
			end
			creuset.WorldPivot = cfAxe
			creuset:SetAttribute("Bascule", BASCULE)
			if haut then
				for _, x in {-3.6, 3.6} do
					local q = (cfAxe * CFrame.new(x, 0, 0)).Position
					T.bloc(m, Vector3.new(0.3, haut.Position.Y - q.Y, 0.3), CFrame.new(q.X, (haut.Position.Y + q.Y) / 2, q.Z), P.fer, M.Metal, "ChaineCreuset").CastShadow = false
				end
			end
			-- la coulée (cachée tant que le creuset n'est pas basculé)
			local bec = (cfAxe * CFrame.Angles(BASCULE, 0, 0) * CFrame.new(0, 1.8, -3.6)).Position
			local L = bec.Y - base.Y
			local coulee = T.cylindre(m, L, 0.9, CFrame.new(bec.X, base.Y + L / 2, bec.Z), P.fondu, M.Neon, "Coulee")
			coulee.CastShadow = false
			coulee.Transparency = 1
			local pied = T.volume(m, Vector3.new(2, 0.4, 2), CFrame.new(bec.X, base.Y + 0.3, bec.Z), "PiedCoulee")
			T.emetteur(pied, {
				Name = "Gerbe", Texture = GT.TEX_ETINCELLE, LightEmission = 0.7, LightInfluence = 0, Color = ColorSequence.new(P.fondu, P.braise),
				Size = NumberSequence.new({T.kp(0, 0.16), T.kp(1, 0)}), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(8, 16),
				SpreadAngle = Vector2.new(70, 70), Rate = 32, EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -40, 0),
				Enabled = false,
			})
			local lp = T.lumiere(pied, P.fondu, 0, 32)
			if lp then
				lp.Name = "LueurCoulee"
			end
			-- rigole vers les lingotières : froide (fonte) tant qu'on n'a pas coulé
			local q0 = Vector3.new(bec.X, base.Y, bec.Z)
			local ordre = 0
			for k = 0, 5 do
				local q = q0 + dir * (k * 1.8)
				local s2 = T.solEn(q)
				if s2 then
					T.bloc(m, Vector3.new(1.8, 0.2, 1.9), CFrame.lookAt(s2.Position + Vector3.new(0, 0.05, 0), s2.Position + dir), P.pierreSombre, Enum.Material.Slate, "Rigole")
					local met = T.bloc(m, Vector3.new(0.8, 0.22, 1.9), CFrame.lookAt(s2.Position + Vector3.new(0, 0.1, 0), s2.Position + dir), P.fonte, M.Metal, "Metal")
					met.CastShadow = false
					ordre += 1
					met:SetAttribute("Ordre", ordre)
				end
			end
			for k = -2, 2 do
				local q = T.solEn(q0 + dir * 11 + cf.RightVector * k * 1.6)
				if q then
					T.bloc(m, Vector3.new(1.3, 0.6, 2.4), CFrame.lookAt(q.Position + Vector3.new(0, 0.3, 0), q.Position + Vector3.new(0, 0.3, 0) + dir), P.pierreSombre, Enum.Material.Slate, "Moule")
					local lg = T.bloc(m, Vector3.new(0.8, 0.3, 1.9), CFrame.lookAt(q.Position + Vector3.new(0, 0.55, 0), q.Position + Vector3.new(0, 0.55, 0) + dir), P.fonte, M.Metal, "Lingot")
					lg:SetAttribute("Ordre", ordre + 1 + (k + 2))
				end
			end
			-- la manivelle du creuset, sur un socle à côté
			local qM = T.solEn((cf * CFrame.new(6, 0, -1)).Position)
			if qM then
				local cfM = CFrame.lookAt(qM.Position, qM.Position + (base - qM.Position) * Vector3.new(1, 0, 1))
				local man = T.modele("Manivelle", m)
				T.bloc(man, Vector3.new(2, 2.6, 2), cfM * CFrame.new(0, 1.3, 0), P.pierreSombre, Enum.Material.Slate, "Socle")
				T.disque(man, 0.5, 2.6, cfM * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, math.pi / 2, 0), P.fer, M.Metal, "Volant")
				local poignee = T.bloc(man, Vector3.new(0.3, 1.6, 0.3), cfM * CFrame.new(0, 3.4, -1.3), P.bois, M.Bois, "Poignee")
				local invite = Instance.new("ProximityPrompt")
				invite.ActionText, invite.ObjectText = "Verser 3 Fer", "Creuset de la Fonderie royale"
				invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 0.8, 9, false
				invite:SetAttribute("FonderieRoyale", true)
				invite.Parent = poignee
			end
			-- haut-fourneau contre la paroi
			local hit = outils.paroi(base, dir, 3, s.r * 1.8)
			if hit then
				local n = unite(plat(hit.Normal), -dir)
				local pf = T.solEn(hit.Position + n * 4)
				if pf then
					local cff = CFrame.lookAt(pf.Position, pf.Position + n)
					local four = T.modele("HautFourneau", m)
					T.bloc(four, Vector3.new(9, 9, 6), cff * CFrame.new(0, 4.5, 1), P.pierre, Enum.Material.Brick, "Corps")
					T.bloc(four, Vector3.new(7, 2, 5), cff * CFrame.new(0, 10, 1), P.pierreSombre, Enum.Material.Brick, "Epaule")
					T.cylindre(four, 20, 3.4, cff * CFrame.new(0, 20, 1.5), P.pierreSombre, Enum.Material.Brick, "Cheminee")
					local gueule = T.bloc(four, Vector3.new(4, 3.4, 0.4), cff * CFrame.new(0, 2.6, -2.05), P.blancChaud, M.Neon, "Gueule")
					gueule.CastShadow = false
					T.tag(gueule, "GrottePulse")
					T.bloc(four, Vector3.new(5, 0.6, 0.8), cff * CFrame.new(0, 4.6, -2.2), P.fonte, M.Metal, "Arc")
					feu(gueule, 2.2, true)
					-- soufflet
					T.coin(four, Vector3.new(2.4, 1.4, 3.4), cff * CFrame.new(5.8, 1, -1) * CFrame.Angles(0, math.pi / 2, 0), P.bois, Enum.Material.Leather, "Soufflet")
				end
			end
			-- enclumes et marteaux
			for k = 1, 3 do
				local q = T.solEn(base + cf.RightVector * (k * 4 - 8) - dir * 6)
				if q and T.solLibre(q.Position, 1, 4) then
					local e = T.modele("Enclume", m)
					T.bloc(e, Vector3.new(1.2, 1.4, 1), CFrame.new(q.Position + Vector3.new(0, 0.7, 0)), P.bois, M.Bois, "Billot")
					T.bloc(e, Vector3.new(2.2, 0.7, 0.9), CFrame.new(q.Position + Vector3.new(0, 1.75, 0)), P.fonte, M.Metal, "Table")
					T.bloc(e, Vector3.new(0.3, 1.6, 0.3), CFrame.new(q.Position + Vector3.new(0.6, 2.6, 0.2)) * CFrame.Angles(0, 0, 0.5), P.bois, M.Bois, "Manche")
					T.bloc(e, Vector3.new(0.9, 0.5, 0.5), CFrame.new(q.Position + Vector3.new(1.05, 3.25, 0.2)) * CFrame.Angles(0, 0, 0.5), P.fer, M.Metal, "Masse")
				end
			end
			T.interdire(base, 12)
		end
		T.particulesSalle(s, {
			Name = "Braises", Texture = GT.TEX_ETINCELLE, LightEmission = 1, Color = ColorSequence.new(P.fondu, P.braise),
			Size = NumberSequence.new({T.kp(0, 0.18), T.kp(1, 0)}), Lifetime = NumberRange.new(3, 6), Rate = 14,
			Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.8, 0),
		})
		T.zone(Vector3.new(s.p.X, s.p.Y, s.p.Z), s.r + 6, P.fondu:Lerp(P.blancChaud, 0.2), "Fonderie")
	end

	-- ===== 4. LA SALLE DES ROUAGES =====
	local function rouage(cf: CFrame, diametre: number, vitesse: number, couleur: Color3, parent: Instance?)
		local m = T.modele("Rouage", parent)
		T.disque(m, 0.8, diametre, cf, couleur, M.Metal, "Disque")
		T.disque(m, 1, diametre * 0.25, cf, P.fonte, M.Metal, "Moyeu")
		local nDents = math.max(10, math.floor(diametre * 2.2))
		for k = 0, nDents - 1 do
			local a = k / nDents * 2 * math.pi
			T.bloc(m, Vector3.new(0.8, 0.9, 1), cf * CFrame.new(0, math.cos(a) * diametre / 2, math.sin(a) * diametre / 2) * CFrame.Angles(a, 0, 0), couleur, M.Metal, "Dent")
		end
		for k = 0, 2 do
			T.bloc(m, Vector3.new(0.85, diametre * 0.85, 0.7), cf * CFrame.Angles(k * math.pi / 3, 0, 0), P.fonte, M.Metal, "Rayon")
		end
		m.WorldPivot = cf
		-- à l'arrêt tant que sa manivelle n'a pas été tournée (MecaniquesGrotte : « Rouages »)
		m:SetAttribute("Vitesse", 0)
		m:SetAttribute("VitesseCible", vitesse)
		m:SetAttribute("Axe", "X")
		T.tag(m, "Rouage")
		return m
	end
	if rouages then
		roles[rouages] = "rouages"
		local s = rouages
		local nGroupes = 0
		for k = 1, 4 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local hit = outils.paroi(s.p, dir, rng:NextNumber(5, 10), s.r * 1.8)
			if hit and nGroupes < 3 then
				local n = unite(plat(hit.Normal), -dir)
				local d = rng:NextNumber(7, 13)
				local centre = hit.Position + n * 1.2
				-- l'axe de la roue est perpendiculaire à la paroi : son axe X pointe vers la salle
				local cf = CFrame.fromMatrix(centre, n, Vector3.yAxis)
				nGroupes += 1
				local grande = rouage(cf, d, (if k % 2 == 0 then 1 else -1) * rng:NextNumber(0.15, 0.3), if k % 2 == 0 then P.cuivre else P.rouille)
				grande:SetAttribute("Groupe", nGroupes)
				-- une petite roue qui s'engrène à côté
				local petite = cf * CFrame.new(0, d * 0.35, -(d / 2 + 2.2))
				rouage(petite, 4.2, (if k % 2 == 0 then -1 else 1) * 0.6, P.bronze):SetAttribute("Groupe", nGroupes)
				-- arbre de transmission qui file dans la roche
				T.cylindre(decor, 6, 0.9, cf * CFrame.new(-3, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), P.fonte, M.Metal, "Arbre")
				-- la manivelle au pied de la roue
				local qM = T.solEn(hit.Position + n * 4)
				if qM then
					local cfM = CFrame.lookAt(qM.Position, qM.Position + n)
					local man = T.modele("ManivelleRouage")
					T.bloc(man, Vector3.new(1.6, 2.4, 1.6), cfM * CFrame.new(0, 1.2, 0), P.fonte, M.Metal, "Socle")
					T.disque(man, 0.4, 2.2, cfM * CFrame.new(0, 2.7, 0) * CFrame.Angles(0, math.pi / 2, 0), P.cuivre, M.Metal, "Volant")
					local poignee = T.bloc(man, Vector3.new(0.3, 1.4, 0.3), cfM * CFrame.new(0, 3.1, -1.1), P.bois, M.Bois, "Poignee")
					local invite = Instance.new("ProximityPrompt")
					invite.ActionText, invite.ObjectText = "Tourner", "Manivelle des rouages " .. nGroupes .. " / 3"
					invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 1.2, 9, false
					invite:SetAttribute("ManivelleRouage", nGroupes)
					invite.Parent = poignee
				end
			end
		end
		ctx.modele:SetAttribute("RouagesTotal", nGroupes)
		T.particulesSalle(s, {
			Name = "Poussiere", Texture = GT.TEX_LUEUR, LightEmission = 0.5, Color = ColorSequence.new(P.blancChaud),
			Size = NumberSequence.new({T.kp(0, 0), T.kp(0.4, 0.14), T.kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 8,
			Speed = NumberRange.new(0.2, 0.5), SpreadAngle = Vector2.new(180, 180),
		})
		T.zone(s.p, s.r + 6, P.cuivre:Lerp(P.blancChaud, 0.3), "Rouages")
	end

	-- ===== 5. Galeries : conduites de fer, braseros, chaînes =====
	for _, g in galeries do
		local pts = g.pts
		local cote = if rng:NextNumber() < 0.5 then 1 else -1
		local prec = nil
		for i, pt in pts do
			if (pt.p - depart.p).Magnitude > 22 then
				local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * cote
				local hit = T.trace(pt.p + Vector3.new(0, 6, 0), lat * (pt.r + 10))
				local q = if hit then hit.Position - lat * 0.9 else nil
				if q and prec and (q - prec).Magnitude < 7 then
					for _, dy in {0, 1.1} do
						local a, b = prec + Vector3.new(0, dy, 0), q + Vector3.new(0, dy, 0)
						T.cylindre(decor, (b - a).Magnitude + 0.2, 0.7, CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0), if dy == 0 then P.cuivre else P.fer, M.Metal, "Conduite").CastShadow = false
					end
					if i % 6 == 0 then
						T.bloc(decor, Vector3.new(1.2, 2.6, 1.2), CFrame.lookAt(q + Vector3.new(0, 0.55, 0), q + Vector3.new(0, 0.55, 0) + pt.t), P.fonte, M.Metal, "Collier")
					end
				end
				prec = q
				if i % 9 == 0 and g.principal then
					local sol = T.solEn(pt.p + lat * pt.r * 0.75)
					if sol and T.solLibre(sol.Position, 1, 3) then
						brasero(sol.Position)
					end
				end
				if i % 7 == 3 then
					local haut = T.plafondEn(pt.p + Vector3.new(0, 2, 0), 40)
					if haut and haut.Position.Y - pt.p.Y > 12 then
						local L = rng:NextNumber(3, 7)
						for k = 0, math.floor(L / 1.2) do
							T.bloc(decor, Vector3.new(0.2, 1.3, 0.5), CFrame.new(haut.Position - Vector3.new(0, k * 1.2 + 0.6, 0)) * CFrame.Angles(0, (k % 2) * math.pi / 2, 0), P.fonte, M.Metal, "Chainette").CastShadow = false
						end
					end
				end
			else
				prec = nil
			end
		end
	end

	-- ===== 6. LA GRANDE FORGE DES ROIS =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local fond, dirFond = T.coinSalle(s, T.rb * 0.55)
		local q = T.solEn(fond)
		if q then
			local cf = CFrame.lookAt(q.Position, q.Position - dirFond)
			local m = T.modele("GrandeForge")
			-- statue du nain forgeron (blocs de bronze) qui lève son marteau
			local st = T.modele("StatueForgeron", m)
			local k = 1.6
			T.bloc(st, Vector3.new(6, 2, 5) * k / 1.6, cf * CFrame.new(0, 1, 2), P.pierreSombre, Enum.Material.Slate, "Socle")
			T.bloc(st, Vector3.new(2.2, 3, 2), cf * CFrame.new(-1.3, 2 + 1.5 * k, 2), P.bronze, M.Metal, "Jambe")
			T.bloc(st, Vector3.new(2.2, 3, 2), cf * CFrame.new(1.3, 2 + 1.5 * k, 2), P.bronze, M.Metal, "Jambe")
			T.bloc(st, Vector3.new(5.6, 5.2, 3.6), cf * CFrame.new(0, 2 + 3 * k + 2.6, 2), P.bronze, M.Metal, "Torse")
			T.bloc(st, Vector3.new(5.8, 1, 3.8), cf * CFrame.new(0, 2 + 3 * k + 0.8, 2), P.fonte, M.Metal, "Ceinture")
			T.bloc(st, Vector3.new(3, 3, 3), cf * CFrame.new(0, 2 + 3 * k + 6.8, 2), P.bronze, M.Metal, "Tete")
			T.coin(st, Vector3.new(3.2, 4, 1.6), cf * CFrame.new(0, 2 + 3 * k + 4.6, 0.2) * CFrame.Angles(0, math.pi, math.pi), P.bronze:Lerp(P.or_, 0.3), M.Metal, "Barbe")
			T.bloc(st, Vector3.new(3.4, 1.2, 3.4), cf * CFrame.new(0, 2 + 3 * k + 8.8, 2), P.fonte, M.Metal, "Casque")
			for _, x in {-0.6, 0.6} do
				T.bloc(st, Vector3.new(0.5, 0.4, 0.1), cf * CFrame.new(x, 2 + 3 * k + 7.2, 0.45), P.fondu, M.Neon, "Oeil")
			end
			-- bras levé + marteau
			T.bloc(st, Vector3.new(1.6, 5, 1.6), cf * CFrame.new(3.6, 2 + 3 * k + 7.2, 2) * CFrame.Angles(0, 0, math.rad(-20)), P.bronze, M.Metal, "Bras")
			T.bloc(st, Vector3.new(0.6, 6, 0.6), cf * CFrame.new(4.9, 2 + 3 * k + 11, 2) * CFrame.Angles(0, 0, math.rad(-20)), P.bois, M.Bois, "Manche")
			T.bloc(st, Vector3.new(4, 2.2, 2.2), cf * CFrame.new(5.9, 2 + 3 * k + 13.6, 2) * CFrame.Angles(0, 0, math.rad(-20)), P.fonte, M.Metal, "Marteau")
			T.bloc(st, Vector3.new(1.6, 5, 1.6), cf * CFrame.new(-3.4, 2 + 3 * k + 3.6, 2) * CFrame.Angles(0, 0, math.rad(12)), P.bronze, M.Metal, "Bras")
			-- enclume géante et bassin de métal fondu devant la statue
			T.bloc(m, Vector3.new(3, 2.5, 2.5), cf * CFrame.new(0, 1.25, -5), P.pierreSombre, Enum.Material.Slate, "Billot")
			T.bloc(m, Vector3.new(7, 1.6, 2.6), cf * CFrame.new(0, 3.3, -5), P.fonte, M.Metal, "Enclume")
			T.coin(m, Vector3.new(2.6, 1.6, 3), cf * CFrame.new(5, 3.3, -5) * CFrame.Angles(0, -math.pi / 2, 0), P.fonte, M.Metal, "Bigorne")
			local lingot = T.bloc(m, Vector3.new(2, 0.6, 0.9), cf * CFrame.new(0.5, 4.4, -5), P.blancChaud, M.Neon, "LingotChaud")
			T.tag(lingot, "GrottePulse")
			for _, x in {-9, 9} do
				local qb = T.solEn((cf * CFrame.new(x, 0, -3)).Position)
				if qb then
					brasero(qb.Position, 4)
				end
			end
			T.lumiere(T.volume(m, Vector3.one, cf * CFrame.new(0, 12, -10), "LueurForge"), P.fondu, 1.8, 50)
			T.interdire(q.Position, 10)
		end
		T.particulesSalle(s, {
			Name = "Braises", Texture = GT.TEX_ETINCELLE, LightEmission = 1, Color = ColorSequence.new(P.fondu, P.braise),
			Size = NumberSequence.new({T.kp(0, 0.2), T.kp(1, 0)}), Lifetime = NumberRange.new(3, 6), Rate = 16,
			Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.8, 0),
		})
		T.zone(Vector3.new(s.p.X, y0, s.p.Z), T.rb + 8, P.fondu:Lerp(P.or_, 0.4), "Forge")
	end

	-- ===== 7. Braises dans les autres salles =====
	for _, s in salles do
		if not s.depart and not s.boss and not roles[s] then
			T.particulesSalle(s, {
				Name = "Braises", Texture = GT.TEX_ETINCELLE, LightEmission = 1, Color = ColorSequence.new(P.fondu, P.braise),
				Size = NumberSequence.new({T.kp(0, 0.15), T.kp(1, 0)}), Lifetime = NumberRange.new(3, 6), Rate = 6,
				Speed = NumberRange.new(0.5, 1.2), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.6, 0),
			})
		end
	end

	-- ===== 8. Décor générique, veines de fer chauffé, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, champignons = false, mine = false, humide = false,
		racines = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.fondu, P.braise, P.fondu, P.or_}, 4, P.braise)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.fondu:Lerp(P.blancChaud, 0.5) end
			if roles[s] == "abime" then return P.fondu:Lerp(P.blancChaud, 0.2) end
			if roles[s] == "rouages" then return P.cuivre:Lerp(P.blancChaud, 0.45) end
			if s.boss then return P.or_:Lerp(P.fondu, 0.4) end
			return P.fondu:Lerp(P.blancChaud, 0.45)
		end,
		galerie = P.fondu:Lerp(P.blancChaud, 0.5),
		lum = 0.5,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "Fonderie")
end

return GrotteFonderie
