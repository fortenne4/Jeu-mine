--[[ Bordures de la carte : château fort des montagnes, sommets lointains, cascades, forêts d'altitude, brumes.
	Tout est du décor (aucune collision, aucune incidence sur le jeu). Construit après le village et la mine.

	Modèles 3D (Blender → assets/*.fbx → ServerStorage › Modeles3D) :
		Chateau.fbx  (blender/chateau.py) : « Chateau_<Groupe>_<Teinte> »
		Cimes.fbx    (blender/cimes.py)   : « Cime1..3_<Teinte> »
	Sans import, le petit château en blocs de HorizonMine reste en place et il n'y a pas de sommets lointains :
	rien ne casse. Réglages en tête de fichier. ]]
local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local Terrain = require(script.Parent.Terrain)
local D = require(script.Parent.Disposition)
local M = O.M

local Bordures = {}

local CONFIG = {
	-- Château : zone de recherche du site (crête de la montagne de la mine, au nord-ouest de la place)
	CHATEAU_ZONE = {xMin = -230, xMax = -95, zMin = -320, zMax = -222},
	CHATEAU_ECHELLE = 1.2,
	CHATEAU_RAYON = 78, -- rayon (studs, après échelle) du plateau aplani sous le château
	-- Sommets lointains : ellipse autour du centre de la carte
	CIMES_CENTRE = Vector3.new(0, 0, -160),
	CIMES_RAYONS = Vector2.new(560, 600),
	CIMES_NOMBRE = 18,
	-- Forêt d'altitude (en plus des arbres de la vallée)
	PINS_ALTITUDE = 300,
	TROUPEAUX = 12, -- troupeaux de chèvres (2 à 4 bêtes) sur les corniches herbeuses
	PAROIS = 48, -- pans de falaise stratifiés (Parois.fbx) posés sur les pentes raides
	-- Cascades : point de départ (haut) et direction de la chute (vers la vallée)
	CASCADES = {
		{depart = Vector2.new(-212, -214), vers = Vector2.new(0.25, 1), largeur = 20},
		{depart = Vector2.new(300, 82), vers = Vector2.new(-1, 0), largeur = 18},
		{depart = Vector2.new(-300, 76), vers = Vector2.new(1, 0.05), largeur = 16},
	},
}

local NEIGE = O.materiau("Snow", Enum.Material.Sand)
local TEINTES_CHATEAU = {
	Pierre = {Color3.fromRGB(132, 124, 138), M.Pierre},
	PierreSombre = {Color3.fromRGB(90, 84, 98), M.Pierre},
	PierreClaire = {Color3.fromRGB(170, 160, 168), M.Calcaire},
	Roche = {Color3.fromRGB(98, 92, 100), M.Roche},
	Ardoise = {Color3.fromRGB(64, 58, 92), M.Ardoise},
	ArdoiseClaire = {Color3.fromRGB(86, 78, 118), M.Ardoise},
	Bois = {Color3.fromRGB(86, 58, 40), M.Planches},
	Fer = {Color3.fromRGB(44, 44, 50), M.Metal},
	Or = {Color3.fromRGB(240, 186, 84), M.Metal},
	Lumiere = {Color3.fromRGB(255, 176, 86), M.Neon},
	Banniere = {Color3.fromRGB(128, 34, 54), M.Tissu},
	Lierre = {Color3.fromRGB(62, 98, 48), Enum.Material.Grass},
}
local TEINTES_CIMES = {
	Roche = {Color3.fromRGB(104, 92, 112), M.Roche},
	Neige = {Color3.fromRGB(246, 230, 236), NEIGE},
	Ombre = {Color3.fromRGB(46, 54, 48), Enum.Material.Grass},
}

-- Hauteur réelle du terrain (après creusements), sinon la formule
local function sol(x, z)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	p.FilterDescendantsInstances = {workspace.Terrain}
	local r = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -800, 0), p)
	return if r then r.Position.Y else Terrain.hauteur(x, z)
end

local function decorer(c: BasePart)
	O.decor(c)
	c.CastShadow = false
end

-- Retire le décor du village (arbres, rochers, falaises) posé là où va le château
local function degager(carte, centre: Vector3, rayon: number)
	local village = carte:FindFirstChild("Village")
	if not village then
		return
	end
	for _, nom in {"Nature", "Falaises"} do
		local dossier = village:FindFirstChild(nom)
		for _, e in (if dossier then dossier:GetChildren() else {}) do
			local ok, pivot = pcall(function()
				return (e :: any):GetPivot().Position
			end)
			if ok and Vector2.new(pivot.X - centre.X, pivot.Z - centre.Z).Magnitude < rayon then
				e:Destroy()
			end
		end
	end
end

-- ================= Château =================
local function siteChateau(): (Vector3, number)
	local Z = CONFIG.CHATEAU_ZONE
	local meilleur, score = nil, math.huge
	for x = Z.xMin, Z.xMax, 15 do
		for z = Z.zMin, Z.zMax, 15 do
			local hs = {}
			for k = 0, 8 do
				local a = k / 9 * math.pi * 2
				local r = if k == 0 then 0 else 55
				table.insert(hs, Terrain.hauteur(x + math.cos(a) * r, z + math.sin(a) * r))
			end
			local mn, mx, somme = math.huge, -math.huge, 0
			for _, h in hs do
				mn, mx, somme = math.min(mn, h), math.max(mx, h), somme + h
			end
			local moyenne = somme / #hs
			-- terrain assez plat, en hauteur, et proche du bord de la falaise (bien visible depuis la place)
			local s = (mx - mn) + math.abs(moyenne - 215) * 0.4 + math.abs(z - Z.zMax) * 0.35
			if moyenne > 150 and s < score then
				meilleur, score = Vector3.new(x, moyenne, z), s
			end
		end
	end
	local site = meilleur or Vector3.new(-160, 220, -260)
	-- le sol du château : un peu sous la moyenne, le socle rocheux rattrape le reste
	local hs = {}
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		table.insert(hs, Terrain.hauteur(site.X + math.cos(a) * 40, site.Z + math.sin(a) * 40))
	end
	table.sort(hs)
	return site, hs[math.floor(#hs * 0.4) + 1]
end

local function chateau(carte, decor): Vector3?
	local pieces = M3.pieces("Chateau")
	if not pieces then
		return nil
	end
	local site, base = siteChateau()
	local k = CONFIG.CHATEAU_ECHELLE
	local R = CONFIG.CHATEAU_RAYON
	local centre = Vector3.new(site.X, base, site.Z)

	-- Plateau : on creuse le relief au-dessus du sol du château, on comble dessous
	local terrain = workspace.Terrain
	terrain:FillCylinder(CFrame.new(centre + Vector3.new(0, 90, 0)), 180, R * 1.05, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(centre - Vector3.new(0, 22, 0)), 44, R * 1.1, Enum.Material.Rock)
	degager(carte, centre, R * 1.15)

	-- Repère source : sol du château (haut du socle), au centre de l'enceinte
	local socle = {}
	for _, p in pieces do
		if M3.groupe(p) == "Socle" then
			table.insert(socle, p)
		end
	end
	local mn, mx = M3.boite(pieces)
	local sMn, sMx = M3.boite(if #socle > 0 then socle else pieces)
	local S = CFrame.new((mn.X + mx.X) / 2, sMx.Y + 0.5, (mn.Z + mx.Z) / 2)
	-- la façade (-Z du modèle) regarde la place
	local cible = CFrame.lookAt(centre, Vector3.new(0, centre.Y, 0))
	local m = O.modele(decor, "ChateauFort")
	local lumieres = 0
	M3.poser(pieces, S, cible, k, m, function(c, teinte)
		local t = TEINTES_CHATEAU[teinte]
		if t then
			c.Color, c.Material = t[1], t[2]
		end
		decorer(c)
		c.CastShadow = teinte ~= "Lumiere" and teinte ~= "Banniere"
		if teinte == "Lumiere" and lumieres < 6 then
			lumieres += 1
			O.lumiere(c, Color3.fromRGB(255, 170, 90), 1.6, 40)
		end
	end)
	local _ = sMn
	-- Torches du pont-levis et fumée de la cheminée de la grande salle
	local avant = cible.LookVector
	for _, cote in {-1, 1} do
		local p = O.decor(O.bloc(m, Vector3.new(1, 1, 1), cible * CFrame.new(cote * 9 * k, 12 * k, -70 * k), Color3.new(), M.Lisse, "Torche"))
		p.Transparency = 1
		O.feu(p, 4)
		O.lumiere(p, Color3.fromRGB(255, 150, 60), 2.2, 45)
	end
	local fumee = O.decor(O.bloc(m, Vector3.one, cible * CFrame.new(34 * k, 53 * k, 30 * k), Color3.new(), M.Lisse, "Cheminee"))
	fumee.Transparency = 1
	O.fumee(fumee, 3, Color3.fromRGB(120, 112, 120))
	-- Corbeaux qui tournent autour du donjon (petites particules sombres)
	local _ = avant
	print(string.format("[Bordures] Château fort posé en (%d, %d, %d), %d pièces", centre.X, centre.Y, centre.Z, #pieces))
	return centre
end

-- ================= Sommets lointains =================
local function cimes(decor, rng)
	local variantes = M3.variantes("^Cime%d+$")
	if #variantes == 0 then
		return 0
	end
	local f = O.modele(decor, "SommetsLointains")
	local C, R = CONFIG.CIMES_CENTRE, CONFIG.CIMES_RAYONS
	for i = 1, CONFIG.CIMES_NOMBRE do
		local a = (i - 1) / CONFIG.CIMES_NOMBRE * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local r = 1 + rng:NextNumber(-0.06, 0.14)
		local pos = C + Vector3.new(math.cos(a) * R.X * r, 0, math.sin(a) * R.Y * r)
		local pieces = M3.pieces(variantes[(i - 1) % #variantes + 1]) :: {MeshPart}
		local mn, mx = M3.boite(pieces)
		local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
		local k = rng:NextNumber(0.95, 1.45)
		-- largeur tournée vers le centre de la carte, base enfoncée sous l'horizon
		local cf = CFrame.lookAt(pos, Vector3.new(C.X, 0, C.Z)) * CFrame.Angles(0, rng:NextNumber(-0.35, 0.35), 0)
			- Vector3.new(0, 40 + rng:NextNumber(0, 30), 0)
		local m = O.modele(f, "Cime")
		M3.poser(pieces, S, cf, k, m, function(c, teinte)
			local t = TEINTES_CIMES[teinte]
			if t then
				c.Color, c.Material = t[1], t[2]
			end
			decorer(c)
		end)
	end
	return CONFIG.CIMES_NOMBRE
end

-- ================= Cascades =================
local TEX_EAU = "rbxasset://textures/particles/smoke_main.dds"
local TEX_ECUME = "rbxasset://textures/particles/sparkles_main.dds"

local function emetteurEau(parent: Instance, props: {[string]: any}): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function pointEmission(m, cf: CFrame, taille: Vector3, nom: string): BasePart
	local p = O.decor(O.bloc(m, taille, cf, Color3.new(), M.Lisse, nom))
	p.Transparency = 1
	p.CastShadow = false
	return p
end

local GRAVITE = 70

--[[ Cascade en particules (plus d'aplats ni de faisceaux) :
	- chute : filets d'eau allongés, alignés sur leur vitesse, qui tombent avec la gravité depuis chaque rebord ;
	- gouttelettes scintillantes et voile de vapeur le long de la chute ;
	- ruissellement : eau du terrain (vagues animées) dans les passages en pente douce ;
	- pied : nuage d'embruns, éclaboussures et bassin. ]]
local function cascade(parent, def)
	local m = O.modele(parent, "Cascade")
	local dir = Vector3.new(def.vers.X, 0, def.vers.Y).Unit
	local p0 = Vector3.new(def.depart.X, 0, def.depart.Y)
	local points = {}
	for d = 0, 220, 3 do
		local q = p0 + dir * d
		local y = sol(q.X, q.Z)
		table.insert(points, Vector3.new(q.X, y, q.Z))
		if y < 2 and d > 20 then
			break
		end
	end
	if #points < 3 then
		return
	end
	local largeur = def.largeur
	local cote = dir:Cross(Vector3.yAxis).Unit
	local terrain = workspace.Terrain

	-- découpe en tronçons : « chute » (raide) ou « ruisseau » (doux)
	local i = 1
	while i < #points do
		local a = points[i]
		local j = i
		local raide = (points[i].Y - points[i + 1].Y) / 3 > 1.1
		while j < #points and (((points[j].Y - points[j + 1].Y) / 3 > 1.1) == raide) do
			j += 1
		end
		local b = points[j]
		local hauteur = a.Y - b.Y
		if raide and hauteur > 4 then
			-- rebord : les filets partent vers l'avant puis tombent
			local cf = CFrame.fromMatrix(a + dir * 1.2 + Vector3.yAxis * 0.6, cote, Vector3.yAxis, -dir)
			local lip = pointEmission(m, cf, Vector3.new(largeur, 0.4, 0.6), "Rebord")
			local duree = math.sqrt(2 * (hauteur + 6) / GRAVITE) + 0.25
			local avant = math.max(2, (b - a).Magnitude * 0.0 + (Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude) / duree)
			emetteurEau(lip, {
				Name = "Filets", Texture = TEX_EAU, Orientation = Enum.ParticleOrientation.VelocityParallel,
				EmissionDirection = Enum.NormalId.Front, Shape = Enum.ParticleEmitterShape.Box,
				Speed = NumberRange.new(avant * 0.9, avant * 1.2), SpreadAngle = Vector2.new(4, 4),
				Acceleration = Vector3.new(0, -GRAVITE, 0), Drag = 0.15,
				Lifetime = NumberRange.new(duree * 0.95, duree * 1.1), Rate = largeur * 22,
				Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 2.8)}),
				Squash = NumberSequence.new(-1.6),
				Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.8, 0.45),
					NumberSequenceKeypoint.new(1, 1)}),
				Color = ColorSequence.new(Color3.fromRGB(236, 246, 255), Color3.fromRGB(196, 222, 238)),
				LightEmission = 0.3, LightInfluence = 0.7,
			})
			emetteurEau(lip, {
				Name = "Gouttes", Texture = TEX_ECUME, Orientation = Enum.ParticleOrientation.VelocityParallel,
				EmissionDirection = Enum.NormalId.Front, Shape = Enum.ParticleEmitterShape.Box,
				Speed = NumberRange.new(avant * 0.6, avant * 1.6), SpreadAngle = Vector2.new(18, 18),
				Acceleration = Vector3.new(0, -GRAVITE, 0), Lifetime = NumberRange.new(duree * 0.8, duree * 1.05),
				Rate = largeur * 8, Size = NumberSequence.new(0.35, 0.15), Squash = NumberSequence.new(-1),
				Transparency = NumberSequence.new(0.2, 0.8), Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				LightEmission = 0.8,
			})
			-- voile de vapeur qui accompagne la chute
			local milieu = (a + b) / 2 + dir * 3
			local voile = pointEmission(m, CFrame.fromMatrix(milieu, cote, Vector3.yAxis, -dir), Vector3.new(largeur, hauteur * 0.8, 2), "Voile")
			local v = O.brume(voile, Color3.fromRGB(232, 240, 248), 2 + hauteur / 25)
			v.Size = NumberSequence.new(5, 12)
			v.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(1, 1)})
			v.Lifetime = NumberRange.new(4, 7)
			v.Acceleration = Vector3.new(0, -1.5, 0)
		elseif not raide then
			-- ruisseau : eau du terrain dans un petit lit creusé le long de la pente
			for k = i, j - 1 do
				local p, q = points[k], points[k + 1]
				local milieu = (p + q) / 2
				local long = (q - p).Magnitude + 1
				local cf = CFrame.lookAt(milieu, q) * CFrame.new(0, -0.6, 0)
				terrain:FillBlock(cf, Vector3.new(largeur * 0.55, 2.4, long), Enum.Material.Water)
			end
			-- écume qui file sur le ruisseau
			local c = CFrame.lookAt((a + b) / 2 + Vector3.yAxis * 0.8, b + Vector3.yAxis * 0.8)
			local ecume = pointEmission(m, c, Vector3.new(largeur * 0.5, 0.2, math.max(2, (b - a).Magnitude)), "Ecume")
			emetteurEau(ecume, {
				Name = "Ecume", Texture = TEX_ECUME, Shape = Enum.ParticleEmitterShape.Box,
				Speed = NumberRange.new(4, 7), EmissionDirection = Enum.NormalId.Front, SpreadAngle = Vector2.new(10, 10),
				Lifetime = NumberRange.new(0.8, 1.6), Rate = 12, Size = NumberSequence.new(0.5, 0.1),
				Transparency = NumberSequence.new(0.3, 1), LightEmission = 0.5,
			})
		end
		i = j
	end

	-- pied : embruns, éclaboussures, bassin
	local bas = points[#points]
	local pied = pointEmission(m, CFrame.new(bas + Vector3.yAxis), Vector3.new(largeur, 1, largeur * 0.6), "Embruns")
	emetteurEau(pied, {
		Name = "Nuage", Texture = TEX_EAU, Color = ColorSequence.new(Color3.fromRGB(238, 244, 250)),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 20)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(2.5, 4.5), Rate = 10 + largeur, Speed = NumberRange.new(5, 10), SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, 2.5, 0), Drag = 1.2, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-25, 25),
		Shape = Enum.ParticleEmitterShape.Box,
	})
	emetteurEau(pied, {
		Name = "Eclaboussures", Texture = TEX_ECUME, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)), Size = NumberSequence.new(0.6, 0.2), Squash = NumberSequence.new(-1),
		Transparency = NumberSequence.new(0.15, 0.9), Lifetime = NumberRange.new(0.6, 1.2), Rate = 50,
		Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(55, 55), Acceleration = Vector3.new(0, -GRAVITE * 0.8, 0),
		LightEmission = 0.7, Shape = Enum.ParticleEmitterShape.Box,
	})
	if math.abs(bas.Z - D.RIVIERE_Z) > 14 then
		terrain:FillCylinder(CFrame.new(bas - Vector3.new(0, 2, 0)), 4, largeur * 0.9, Enum.Material.Water)
	end
	-- roche mouillée et mousse autour de la chute
	for k = 1, #points, 3 do
		local p = points[k]
		local region = Region3.new(p - Vector3.new(largeur, 6, largeur), p + Vector3.new(largeur, 6, largeur)):ExpandToGrid(4)
		for _, matiere in {Enum.Material.Rock, Enum.Material.Limestone, Enum.Material.Sandstone, Enum.Material.Slate} do
			terrain:ReplaceMaterial(region, 4, matiere, if k % 2 == 0 then Enum.Material.Basalt else Enum.Material.LeafyGrass)
		end
	end
end
-- ================= Forêt d'altitude =================
local function foret(parent, rng, B)
	local f = O.modele(parent, "ForetAltitude")
	local n = 0
	for _ = 1, CONFIG.PINS_ALTITUDE * 12 do
		if n >= CONFIG.PINS_ALTITUDE then
			break
		end
		local x, z = rng:NextNumber(-310, 310), rng:NextNumber(-540, 230)
		local r = math.sqrt(x * x + z * z)
		if r < 160 or (math.abs(x) < 80 and z < -100 and z > -320) or math.abs(z - D.RIVIERE_Z) < 18 then
			continue
		end
		local h = Terrain.hauteur(x, z)
		local gx = Terrain.hauteur(x + 4, z) - Terrain.hauteur(x - 4, z)
		local gz = Terrain.hauteur(x, z + 4) - Terrain.hauteur(x, z - 4)
		local pente = math.sqrt(gx * gx + gz * gz) / 8
		-- les arbres se raréfient en montant, aucun au-dessus de la limite des neiges
		if h > 25 and h < 190 and pente < 1.35 and rng:NextNumber() > (h - 25) / 260 then
			local planter = if rng:NextNumber() < 0.2 + h / 400 then B.sapin else B.pin -- les sapins dominent en altitude
			local m = planter(f, Vector3.new(x, sol(x, z) - 0.8, z), rng:NextNumber(22, 36) * (1 - (h - 30) / 400), rng)
			if m then
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						O.decor(d)
						d.CastShadow = false
					end
				end
				n += 1
			end
		end
	end
	return n
end

-- ================= Brumes de vallée =================
local function brumes(parent)
	local f = O.modele(parent, "Brumes")
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local x, z = math.cos(a) * 250, math.sin(a) * 230 - 80
		local y = Terrain.hauteur(x, z) + 6
		local p = O.decor(O.bloc(f, Vector3.new(90, 8, 90), CFrame.new(x, y, z), Color3.new(), M.Lisse, "Brume"))
		p.Transparency = 1
		local e = O.brume(p, Color3.fromRGB(226, 196, 210), 2)
		e.Size = NumberSequence.new(30, 55)
		e.Lifetime = NumberRange.new(14, 20)
	end
end

-- ================= Parois rocheuses stratifiées (Parois.fbx) =================
local TEINTES_PAROIS = {
	RocheChaude = {Color3.fromRGB(130, 112, 98), M.Roche},
	RocheOcre = {Color3.fromRGB(176, 150, 114), O.materiau("Sandstone", M.Roche)},
	RocheRose = {Color3.fromRGB(162, 110, 86), O.materiau("Sandstone", M.Roche)},
	RocheViolette = {Color3.fromRGB(96, 88, 108), M.Ardoise},
	Joint = {Color3.fromRGB(46, 40, 46), O.materiau("Basalt", M.Roche)},
	Mousse = {Color3.fromRGB(74, 104, 50), Enum.Material.Grass},
	Herbe = {Color3.fromRGB(110, 132, 60), Enum.Material.Grass},
	Lierre = {Color3.fromRGB(56, 90, 42), Enum.Material.Grass},
	Buisson = {Color3.fromRGB(64, 94, 50), Enum.Material.Grass},
	Fleurs = {Color3.fromRGB(232, 150, 196), M.Tissu},
}
local COULEURS_FLEURS = {Color3.fromRGB(232, 150, 196), Color3.fromRGB(248, 214, 110), Color3.fromRGB(176, 140, 236), Color3.fromRGB(250, 246, 236)}

local function parois(decor, rng, centreChateau: Vector3?)
	local variantes = M3.variantes("^Paroi%d+$")
	if #variantes == 0 then
		return 0
	end
	local f = O.modele(decor, "Parois")
	local poses = {}
	local n = 0
	for _ = 1, 6000 do
		if n >= CONFIG.PAROIS then
			break
		end
		local x, z = rng:NextNumber(-312, 312), rng:NextNumber(-540, 232)
		if math.abs(x) < 70 and z < -100 and z > -300 then
			continue -- entrée de la mine dégagée
		end
		if centreChateau and Vector2.new(x - centreChateau.X, z - centreChateau.Z).Magnitude < CONFIG.CHATEAU_RAYON * 1.3 then
			continue
		end
		local h = Terrain.hauteur(x, z)
		local gx = Terrain.hauteur(x + 4, z) - Terrain.hauteur(x - 4, z)
		local gz = Terrain.hauteur(x, z + 4) - Terrain.hauteur(x, z - 4)
		local pente = math.sqrt(gx * gx + gz * gz) / 8
		if h < 12 or h > 170 or pente < 1.0 then -- pas sur les crêtes : le dos de la paroi serait visible
			continue
		end
		-- vraie falaise (raide tout autour), pas une simple bosse : sinon la paroi dépasserait du relief
		local falaise = true
		for k = 0, 3 do
			local a = k * math.pi / 2
			local px, pz = x + math.cos(a) * 11, z + math.sin(a) * 11
			local ax = Terrain.hauteur(px + 4, pz) - Terrain.hauteur(px - 4, pz)
			local az = Terrain.hauteur(px, pz + 4) - Terrain.hauteur(px, pz - 4)
			if math.sqrt(ax * ax + az * az) / 8 < 0.75 then
				falaise = false
				break
			end
		end
		if not falaise then
			continue
		end
		local hauteur = rng:NextNumber(26, 44)
		local libre = true
		for _, p in poses do
			if (p.X - x) ^ 2 + (p.Z - z) ^ 2 < (hauteur * 1.05) ^ 2 then
				libre = false
				break
			end
		end
		if not libre then
			continue
		end
		-- face tournée vers le bas de la pente (vers la vallée), base enfoncée dans la montagne
		local versBas = Vector3.new(-gx, 0, -gz).Unit
		local base = Vector3.new(x, sol(x, z) - hauteur * 0.25, z) - versBas * 5 -- enfoncée dans le relief
		local recul = math.clamp(math.pi / 2 - math.atan(pente) - 0.25, 0, 0.6) -- se couche comme la pente
		local cible = CFrame.lookAt(base, base + versBas) * CFrame.Angles(recul + rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.05, 0.05))
		local pieces = M3.pieces(variantes[rng:NextInteger(1, #variantes)]) :: {MeshPart}
		local mn, mx = M3.boite(pieces)
		local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
		local k = hauteur / (mx.Y - mn.Y)
		local m = O.modele(f, "Paroi")
		local fleur = COULEURS_FLEURS[rng:NextInteger(1, #COULEURS_FLEURS)]
		local nuance = rng:NextNumber(-0.08, 0.1)
		M3.poser(pieces, S, cible, k, m, function(c, teinte)
			local t = TEINTES_PAROIS[teinte]
			if t then
				local couleur = if teinte == "Fleurs" then fleur else t[1]
				c.Color = if nuance > 0 then couleur:Lerp(Color3.fromRGB(200, 170, 140), nuance) else couleur:Lerp(Color3.new(0, 0, 0), -nuance)
				c.Material = t[2]
			end
			O.decor(c)
			c.CastShadow = teinte:sub(1, 5) == "Roche"
		end)
		table.insert(poses, base)
		n += 1
	end
	return n
end

-- ================= Lucioles et petites lueurs =================
local function lucioles(decor, rng)
	local f = O.modele(decor, "Lucioles")
	for i = 1, 14 do
		local x = rng:NextNumber(-240, 240)
		local z = if i <= 8 then D.RIVIERE_Z + rng:NextNumber(-22, 22) else rng:NextNumber(-150, 200)
		if math.sqrt(x * x + z * z) < 60 then
			continue
		end
		local p = O.decor(O.bloc(f, Vector3.new(26, 7, 26), CFrame.new(x, sol(x, z) + 4, z), Color3.new(), M.Lisse, "Essaim"))
		p.Transparency = 1
		local e = O.lucioles(p, if i % 3 == 0 then Color3.fromRGB(170, 255, 190) else Color3.fromRGB(255, 220, 120), 3)
		e.Brightness = 3
	end
end

-- ================= Chèvres des montagnes (Chevre.fbx) =================
-- Posées par petits troupeaux sur les corniches herbeuses ; la tête est animée chez chaque joueur
-- (Oiseaux.client.lua › chèvres) autour de l'attribut « Nuque » du modèle (tag « ChevreDecor »).
local TEINTES_CHEVRE = {
	Pelage = {Color3.fromRGB(232, 224, 210), Enum.Material.Fabric},
	PelageBrun = {Color3.fromRGB(122, 86, 58), Enum.Material.Fabric},
	Sombre = {Color3.fromRGB(70, 58, 50), Enum.Material.Fabric},
	Cornes = {Color3.fromRGB(150, 132, 108), M.Lisse},
	Sabots = {Color3.fromRGB(44, 38, 36), M.Lisse},
	Yeux = {Color3.fromRGB(20, 16, 14), M.Lisse},
	Nez = {Color3.fromRGB(180, 140, 130), M.Lisse},
}

local function chevres(decor, rng, centreChateau: Vector3?)
	local variantes = M3.variantes("^Chevre%d+$")
	if #variantes == 0 then
		return 0
	end
	local f = O.modele(decor, "Chevres")
	local total, troupeaux = 0, 0
	for _ = 1, 4000 do
		if troupeaux >= CONFIG.TROUPEAUX then
			break
		end
		local x, z = rng:NextNumber(-300, 300), rng:NextNumber(-520, 225)
		if math.sqrt(x * x + z * z) < 165 or (math.abs(x) < 80 and z < -100 and z > -320) then
			continue
		end
		if centreChateau and Vector2.new(x - centreChateau.X, z - centreChateau.Z).Magnitude < CONFIG.CHATEAU_RAYON * 1.2 then
			continue
		end
		local h = Terrain.hauteur(x, z)
		local gx = Terrain.hauteur(x + 3, z) - Terrain.hauteur(x - 3, z)
		local gz = Terrain.hauteur(x, z + 3) - Terrain.hauteur(x, z - 3)
		if h < 35 or h > 180 or math.sqrt(gx * gx + gz * gz) / 6 > 0.55 then
			continue
		end
		troupeaux += 1
		for _ = 1, rng:NextInteger(2, 4) do
			local cx, cz = x + rng:NextNumber(-9, 9), z + rng:NextNumber(-9, 9)
			local pieces = M3.pieces(variantes[rng:NextInteger(1, #variantes)]) :: {MeshPart}
			local mn, mx = M3.boite(pieces)
			local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
			local k = rng:NextNumber(3.1, 3.8) / (mx.Y - mn.Y)
			local cible = CFrame.new(cx, sol(cx, cz) - 0.1, cz) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			local m = O.modele(f, "Chevre")
			local tete, corps = {}, {}
			M3.poser(pieces, S, cible, k, m, function(c, teinte)
				local t = TEINTES_CHEVRE[teinte]
				if t then
					c.Color, c.Material = t[1], t[2]
				end
				O.decor(c)
				if M3.groupe(c) == "Tete" then
					table.insert(tete, c)
				else
					table.insert(corps, c)
				end
			end)
			-- nuque : entre la tête et le corps, un peu sous le centre de la tête
			if #tete > 0 then
				local tMn, tMx = M3.boite(tete)
				local cMn, cMx = M3.boite(corps)
				local ct, cc = (tMn + tMx) / 2, (cMn + cMx) / 2
				local nuque = ct:Lerp(cc, 0.32) - Vector3.new(0, (tMx.Y - tMn.Y) * 0.15, 0)
				m:SetAttribute("Nuque", CFrame.lookAt(nuque, nuque + (ct - cc) * Vector3.new(1, 0, 1)))
				O.tag(m, "ChevreDecor")
			end
			total += 1
		end
	end
	return total
end

-- ================= Feuilles et pétales portés par le vent =================
local function feuilles(decor, rng)
	local f = O.modele(decor, "Vent")
	local couleurs = {
		ColorSequence.new(Color3.fromRGB(214, 150, 60), Color3.fromRGB(120, 140, 50)),
		ColorSequence.new(Color3.fromRGB(240, 180, 206), Color3.fromRGB(255, 240, 240)),
	}
	for i = 1, 14 do
		local x, z = rng:NextNumber(-260, 260), rng:NextNumber(-180, 210)
		if math.sqrt(x * x + z * z) < 70 then
			continue
		end
		local p = O.decor(O.bloc(f, Vector3.new(60, 26, 60), CFrame.new(x, sol(x, z) + 16, z), Color3.new(), M.Lisse, "Rafale"))
		p.Transparency = 1
		local e = Instance.new("ParticleEmitter")
		e.Name = "Feuilles"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = couleurs[if i % 4 == 0 then 2 else 1]
		e.Size = NumberSequence.new(0.45, 0.3)
		e.Squash = NumberSequence.new(0.5)
		e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1),
			NumberSequenceKeypoint.new(0.85, 0.1), NumberSequenceKeypoint.new(1, 1)})
		e.Lifetime = NumberRange.new(6, 10)
		e.Rate = 5
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(2.2, -0.8, 1.1) -- vent d'ouest léger, chute lente
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-160, 160)
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = p
	end
end

function Bordures.construire(carte)
	local B = require(script.Parent.Batiments)
	local precedent = carte:FindFirstChild("Bordures")
	if precedent then
		precedent:Destroy()
	end
	local decor = O.modele(carte, "Bordures")
	local rng = Random.new(2718)

	local centreChateau = chateau(carte, decor)
	if centreChateau then
		-- le grand château remplace la silhouette en blocs
		local horizon = carte:FindFirstChild("HorizonMine")
		local ancien = horizon and horizon:FindFirstChild("ChateauLointain")
		if ancien then
			ancien:Destroy()
		end
	end
	local nCimes = cimes(decor, rng)
	local eaux = O.modele(decor, "Cascades")
	for _, def in CONFIG.CASCADES do
		local ok, err = pcall(cascade, eaux, def)
		if not ok then
			warn("[Bordures] Cascade non posée : " .. tostring(err))
		end
	end
	local nParois = parois(decor, rng, centreChateau)
	local nPins = foret(decor, rng, B)
	brumes(decor)
	lucioles(decor, rng)
	feuilles(decor, rng)
	local nChevres = chevres(decor, rng, centreChateau)
	print(string.format("[Bordures] %d sommets lointains, %d cascades, %d parois stratifiées, %d pins d'altitude, %d chèvres",
		nCimes, #CONFIG.CASCADES, nParois, nPins, nChevres))
	return decor
end

return Bordures
