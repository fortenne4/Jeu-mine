-- Généré par blender/armes/armures_minerais.py (59 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de lunarite : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresLunarite.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["lune"] = {"SmoothPlastic", 176, 158, 228, 0.12},
	["lune2"] = {"SmoothPlastic", 150, 132, 210, 0.12},
	["lune3"] = {"SmoothPlastic", 204, 188, 240, 0.15},
	["argent"] = {"Metal", 214, 206, 214, 0.15},
	["cuir"] = {"Fabric", 128, 128, 144, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "lune2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9997, 0.0198, -0.0159, -0.0207, 0.9982, -0.056, 0.0148, 0.0563, 0.9983), "JambeD"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "lune", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0.0042, -0.0074, 1, -0.0206, 0.9998, 0.0074, -0.9998, -0.0206, 0.0041), "JambeD"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "lune", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9997, 0.0253, 0.0038, -0.0253, 0.9997, 0.0062, -0.0036, -0.0063, 1), "JambeD"},
	{"Greve", "lune2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9999, 0.0129, 0.0074, -0.0133, 0.9984, 0.0556, -0.0066, -0.0557, 0.9984), "JambeD"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "lune", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0252, 0.0113, 0.9996, 0.0099, 0.9999, -0.0116, -0.9996, 0.0102, 0.0251), "JambeD"},
	{"Mollet", "lune", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9998, -0.022, -0.002, 0.0218, 0.9977, -0.0644, 0.0034, 0.0644, 0.9979), "JambeD"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0595, 0.1669, 0.06), CFrame.new(0.5098, 0.1991, -0.76, 0.0545, 0.9985, 0, 0.9985, -0.0545, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0956, 0.1669, 0.06), CFrame.new(0.6023, 0.1447, -0.76, 0.6344, 0.773, 0, 0.773, -0.6344, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1231, 0.1669, 0.06), CFrame.new(0.6429, 0.0566, -0.76, 0.9687, 0.2483, 0, 0.2483, -0.9687, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1381, 0.1669, 0.06), CFrame.new(0.63, -0.0322, -0.76, 0.928, -0.3726, 0, -0.3726, -0.928, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1381, 0.1669, 0.06), CFrame.new(0.574, -0.0989, -0.76, 0.5281, -0.8492, 0, -0.8492, -0.5281, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1231, 0.1669, 0.06), CFrame.new(0.4887, -0.1271, -0.76, -0.0763, -0.9971, 0, -0.9971, 0.0763, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0956, 0.1669, 0.06), CFrame.new(0.395, -0.1024, -0.76, -0.6511, -0.759, 0, -0.759, 0.6511, 0, 0, 0, -1), "JambeD"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0595, 0.1669, 0.06), CFrame.new(0.3254, -0.0207, -0.76, -0.9739, -0.2271, 0, -0.2271, 0.9739, 0, 0, 0, -1), "JambeD"},
	{"Cristaux", "lune3", "Bloc", Vector3.new(0.16, 0.209, 0.16), CFrame.new(1.1475, 0.6897, 0.0077, 0.512, 0.7412, 0.4341, -0.4905, 0.6671, -0.5607, -0.7052, 0.0741, 0.7052), "JambeD"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(1.2839, 0.8208, -0.0288, -0.7779, -0.577, -0.2491, 0.1616, 0.1993, -0.9665, 0.6073, -0.7921, -0.0618), "JambeD"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(1.2584, 0.7217, -0.0351, 0.7779, -0.577, 0.2491, -0.1616, 0.1993, 0.9665, -0.6073, -0.7921, 0.0618), "JambeD"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(1.191, 0.7967, -0.0351, 0.0791, 0.1377, 0.9873, -0.7905, -0.5947, 0.1462, 0.6073, -0.7921, 0.0618), "JambeD"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(1.2922, 0.8117, -0.0288, -0.0791, 0.1377, -0.9873, 0.7905, -0.5947, -0.1462, -0.6073, -0.7921, -0.0618), "JambeD"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(1.2866, 0.8067, 0.0718, 0.1496, 0.0531, -0.9873, -0.727, -0.6709, -0.1462, -0.6701, 0.7397, -0.0618), "JambeD"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(1.1854, 0.7917, 0.0655, -0.1496, 0.0531, 0.9873, 0.727, -0.6709, 0.1462, 0.6701, 0.7397, 0.0618), "JambeD"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(1.2529, 0.7167, 0.0655, -0.7073, -0.6616, 0.2491, 0.2251, 0.1232, 0.9665, -0.6701, 0.7397, 0.0618), "JambeD"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(1.2784, 0.8158, 0.0718, 0.7073, -0.6616, -0.2491, -0.2251, 0.1232, -0.9665, 0.6701, 0.7397, -0.0618), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "lune2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9997, -0.0198, 0.0159, 0.0207, 0.9982, -0.056, -0.0148, 0.0563, 0.9983), "JambeG"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "lune", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0.0042, 0.0074, -1, 0.0206, 0.9998, 0.0074, 0.9998, -0.0206, 0.0041), "JambeG"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "lune", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9997, -0.0253, -0.0038, 0.0253, 0.9997, 0.0062, 0.0036, -0.0063, 1), "JambeG"},
	{"Greve", "lune2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9999, -0.0129, -0.0074, 0.0133, 0.9984, 0.0556, 0.0066, -0.0557, 0.9984), "JambeG"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "lune", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0252, -0.0113, -0.9996, -0.0099, 0.9999, -0.0116, 0.9996, 0.0102, 0.0251), "JambeG"},
	{"Mollet", "lune", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9998, 0.022, 0.002, -0.0218, 0.9977, -0.0644, -0.0034, 0.0644, 0.9979), "JambeG"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0595, 0.1669, 0.06), CFrame.new(-0.5098, 0.1991, -0.76, 0.0545, -0.9985, 0, -0.9985, -0.0545, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0956, 0.1669, 0.06), CFrame.new(-0.6023, 0.1447, -0.76, 0.6344, -0.773, 0, -0.773, -0.6344, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1231, 0.1669, 0.06), CFrame.new(-0.6429, 0.0566, -0.76, 0.9687, -0.2483, 0, -0.2483, -0.9687, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1381, 0.1669, 0.06), CFrame.new(-0.63, -0.0322, -0.76, 0.928, 0.3726, 0, 0.3726, -0.928, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1381, 0.1669, 0.06), CFrame.new(-0.574, -0.0989, -0.76, 0.5281, 0.8492, 0, 0.8492, -0.5281, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1231, 0.1669, 0.06), CFrame.new(-0.4887, -0.1271, -0.76, -0.0763, 0.9971, 0, 0.9971, 0.0763, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0956, 0.1669, 0.06), CFrame.new(-0.395, -0.1024, -0.76, -0.6511, 0.759, 0, 0.759, 0.6511, 0, 0, 0, -1), "JambeG"},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0595, 0.1669, 0.06), CFrame.new(-0.3254, -0.0207, -0.76, -0.9739, 0.2271, 0, 0.2271, 0.9739, 0, 0, 0, -1), "JambeG"},
	{"Cristaux", "lune3", "Bloc", Vector3.new(0.16, 0.209, 0.16), CFrame.new(-1.1475, 0.6897, 0.0077, 0.512, -0.7412, -0.4341, 0.4905, 0.6671, -0.5607, 0.7052, 0.0741, 0.7052), "JambeG"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(-1.2839, 0.8208, -0.0288, -0.7779, 0.577, 0.2491, -0.1616, 0.1993, -0.9665, -0.6073, -0.7921, -0.0618), "JambeG"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(-1.2584, 0.7217, -0.0351, 0.7779, 0.577, -0.2491, 0.1616, 0.1993, 0.9665, 0.6073, -0.7921, 0.0618), "JambeG"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(-1.191, 0.7967, -0.0351, 0.0791, -0.1377, -0.9873, 0.7905, -0.5947, 0.1462, -0.6073, -0.7921, 0.0618), "JambeG"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(-1.2922, 0.8117, -0.0288, -0.0791, -0.1377, 0.9873, -0.7905, -0.5947, -0.1462, 0.6073, -0.7921, -0.0618), "JambeG"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(-1.2866, 0.8067, 0.0718, 0.1496, -0.0531, 0.9873, 0.727, -0.6709, -0.1462, 0.6701, 0.7397, -0.0618), "JambeG"},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(-1.1854, 0.7917, 0.0655, -0.1496, -0.0531, -0.9873, -0.727, -0.6709, 0.1462, -0.6701, 0.7397, 0.0618), "JambeG"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.0624), CFrame.new(-1.2529, 0.7167, 0.0655, -0.7073, 0.6616, -0.2491, -0.2251, 0.1232, 0.9665, 0.6701, 0.7397, 0.0618), "JambeG"},
	{"Cristaux", "lune", "Coin", Vector3.new(0.0192, 0.1473, 0.1426), CFrame.new(-1.2784, 0.8158, 0.0718, 0.7073, 0.6616, 0.2491, 0.2251, 0.1232, -0.9665, -0.6701, 0.7397, -0.0618), "JambeG"},
}

local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function invisible(nom: string, pos: Vector3): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(pos)
	p.Transparency = 1
	p.CastShadow = false
	p.Anchored = false
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	return p
end

local function souder(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local GROUPES = {
	JambeG = Vector3.new(-0.5, 0, 0),
	JambeD = Vector3.new(0.5, 0, 0),
}

local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "JambieresLunarite"
	modele:SetAttribute("NomAffiche", "Jambières de lunarite")

	local racine = invisible("Racine", Vector3.zero)
	racine.Parent = modele
	modele.PrimaryPart = racine

	-- sous-groupes JambeG / JambeD : Model + PrimaryPart "Centre" (centre de la jambe) soudé à Racine
	local groupes: { [string]: Model } = {}
	local centres: { [string]: BasePart } = {}
	for nomG, pos in GROUPES do
		local g = Instance.new("Model")
		g.Name = nomG
		local c = invisible("Centre", pos)
		c.Parent = g
		g.PrimaryPart = c
		g.Parent = modele
		souder(racine, c)
		groupes[nomG] = g
		centres[nomG] = c
	end

	local lumieres: { [string]: boolean } = {}
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, groupe, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6], pc[7]
		local cleLumiere = groupe
		local c = COULEURS[cle]
		local p: BasePart = if forme == "Coin" then Instance.new("WedgePart") else Instance.new("Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = cf
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material = materiau(c[1])
		p.Color = Color3.fromRGB(c[2], c[3], c[4])
		p.Reflectance = c[5]
		p.CastShadow = c[1] ~= "Neon"
		p.Parent = groupes[groupe]
		souder(centres[groupe], p)
	end
	return modele
end

return {
	Nom = "Jambières de lunarite",
	Format = "Code",
	Taille = Vector3.new(2.7091, 1.99, 1.4553),
	Centre = Vector3.new(0, 0.005, -0.0624), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
