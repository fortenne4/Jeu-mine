-- Généré par blender/armes/armures_minerais.py (65 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières d'émeraude : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresEmeraude.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["roche"] = {"Slate", 74, 68, 74, 0},
	["roche2"] = {"Slate", 58, 54, 60, 0},
	["roche3"] = {"Slate", 92, 86, 90, 0},
	["cadre"] = {"Metal", 94, 88, 92, 0.05},
	["emeraude"] = {"SmoothPlastic", 40, 190, 70, 0.15},
	["emeraude2"] = {"SmoothPlastic", 30, 150, 56, 0.15},
	["cuir"] = {"Fabric", 66, 66, 44, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "roche2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9986, -0.0497, -0.0204, 0.0484, 0.997, -0.0597, 0.0233, 0.0587, 0.998), "JambeD"},
	{"Cuissard", "cadre", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "roche", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, -0.0491, 0.0496, 0.9976, -0.0053, 0.9987, -0.0499, -0.9988, -0.0078, -0.0487), "JambeD"},
	{"Genouillere", "cadre", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "roche", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9998, -0.0029, 0.0213, 0.0035, 0.9995, -0.031, -0.0212, 0.0311, 0.9993), "JambeD"},
	{"Greve", "roche3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9996, 0.0191, -0.0213, -0.0182, 0.9988, 0.0449, 0.0221, -0.0445, 0.9988), "JambeD"},
	{"Greve", "cadre", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "roche2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.047, 0.0113, 0.9988, -0.0202, 0.9997, -0.0103, -0.9987, -0.0197, 0.0472), "JambeD"},
	{"Mollet", "roche", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9987, 0.0029, -0.0511, -0.007, 0.9969, -0.079, 0.0507, 0.0792, 0.9956), "JambeD"},
	{"Cheville", "cadre", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Incrustation", "emeraude", "Bloc", Vector3.new(0.44, 0.5, 0.06), CFrame.new(0.5, -0.5, -0.62, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Incrustation", "emeraude2", "Bloc", Vector3.new(0.44, 0.4, 0.06), CFrame.new(0.5, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeD"},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.22, 0.18), CFrame.new(0.6516, 0.1343, -0.7432, 0.5194, 0.2873, 0.8048, -0.6288, 0.7663, 0.1322, -0.5787, -0.5747, 0.5787), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(0.6898, 0.2557, -0.9019, -0.5931, -0.7447, 0.306, 0.2197, -0.5153, -0.8284, 0.7746, -0.4241, 0.4692), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(0.7236, 0.1644, -0.8501, 0.5931, -0.7447, -0.306, -0.2197, -0.5153, 0.8284, -0.7746, -0.4241, -0.4692), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(0.6559, 0.3075, -0.8498, 0.5913, -0.726, -0.3511, -0.2244, 0.2701, -0.9363, 0.7746, 0.6325, -0.0032), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(0.6172, 0.2043, -0.8501, -0.5913, -0.726, 0.3511, 0.2244, 0.2701, 0.9363, -0.7746, 0.6325, 0.0032), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(0.6401, 0.2654, -0.7572, 0.3361, -0.9344, 0.1181, -0.9051, -0.2857, 0.315, -0.2606, -0.2128, -0.9417), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(0.6531, 0.3001, -0.861, -0.3361, -0.9344, -0.1181, 0.9051, -0.2857, -0.315, 0.2606, -0.2128, 0.9417), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(0.7465, 0.2255, -0.7572, -0.8483, -0.4321, -0.306, -0.4609, 0.3183, 0.8284, -0.2606, 0.8438, -0.4692), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(0.7128, 0.3168, -0.8089, 0.8483, -0.4321, 0.306, 0.4609, 0.3183, -0.8284, 0.2606, 0.8438, 0.4692), "JambeD"},
	{"Cristaux", "emeraude2", "Bloc", Vector3.new(0.14, 0.165, 0.14), CFrame.new(0.3638, 0.0485, -0.7447, 0.8462, -0.1961, 0.4954, -0.3026, 0.5883, 0.7498, -0.4385, -0.7845, 0.4385), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(0.4013, 0.0759, -0.8338, -0.661, 0.6857, -0.3048, -0.0022, 0.4045, 0.9145, 0.7504, 0.6051, -0.2659), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(0.3758, 0.1524, -0.8561, 0.661, 0.6857, 0.3048, 0.0022, 0.4045, -0.9145, -0.7504, 0.6051, 0.2659), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(0.2919, 0.1245, -0.8561, 0.5301, -0.7913, 0.3048, 0.3948, -0.0878, -0.9145, 0.7504, 0.6051, 0.2659), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(0.3174, 0.0479, -0.8338, -0.5301, -0.7913, -0.3048, -0.3948, -0.0878, 0.9145, -0.7504, 0.6051, -0.2659), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(0.2955, 0.1137, -0.779, 0.8415, -0.5401, -0.0115, -0.5395, -0.8413, 0.0344, -0.0282, -0.0227, -0.9993), "JambeD"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(0.2945, 0.1166, -0.8626, -0.8415, -0.5401, 0.0115, 0.5395, -0.8413, -0.0344, 0.0282, -0.0227, 0.9993), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(0.3784, 0.1446, -0.8626, -0.3495, 0.9369, 0.0115, -0.9365, -0.349, -0.0344, -0.0282, -0.0227, 0.9993), "JambeD"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(0.3794, 0.1417, -0.779, 0.3495, 0.9369, -0.0115, 0.9365, -0.349, 0.0344, 0.0282, -0.0227, -0.9993), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "roche2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9986, 0.0497, 0.0204, -0.0484, 0.997, -0.0597, -0.0233, 0.0587, 0.998), "JambeG"},
	{"Cuissard", "cadre", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "roche", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, -0.0491, -0.0496, -0.9976, 0.0053, 0.9987, -0.0499, 0.9988, -0.0078, -0.0487), "JambeG"},
	{"Genouillere", "cadre", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "roche", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9998, 0.0029, -0.0213, -0.0035, 0.9995, -0.031, 0.0212, 0.0311, 0.9993), "JambeG"},
	{"Greve", "roche3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9996, -0.0191, 0.0213, 0.0182, 0.9988, 0.0449, -0.0221, -0.0445, 0.9988), "JambeG"},
	{"Greve", "cadre", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "roche2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.047, -0.0113, -0.9988, 0.0202, 0.9997, -0.0103, 0.9987, -0.0197, 0.0472), "JambeG"},
	{"Mollet", "roche", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9987, -0.0029, 0.0511, 0.007, 0.9969, -0.079, -0.0507, 0.0792, 0.9956), "JambeG"},
	{"Cheville", "cadre", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Incrustation", "emeraude", "Bloc", Vector3.new(0.44, 0.5, 0.06), CFrame.new(-0.5, -0.5, -0.62, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Incrustation", "emeraude2", "Bloc", Vector3.new(0.44, 0.4, 0.06), CFrame.new(-0.5, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeG"},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.22, 0.18), CFrame.new(-0.6516, 0.1343, -0.7432, 0.5194, -0.2873, -0.8048, 0.6288, 0.7663, 0.1322, 0.5787, -0.5747, 0.5787), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(-0.6898, 0.2557, -0.9019, -0.5931, 0.7447, -0.306, -0.2197, -0.5153, -0.8284, -0.7746, -0.4241, 0.4692), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(-0.7236, 0.1644, -0.8501, 0.5931, 0.7447, 0.306, 0.2197, -0.5153, 0.8284, 0.7746, -0.4241, -0.4692), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(-0.6559, 0.3075, -0.8498, 0.5913, 0.726, 0.3511, 0.2244, 0.2701, -0.9363, -0.7746, 0.6325, -0.0032), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(-0.6172, 0.2043, -0.8501, -0.5913, 0.726, -0.3511, -0.2244, 0.2701, 0.9363, 0.7746, 0.6325, 0.0032), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(-0.6401, 0.2654, -0.7572, 0.3361, 0.9344, -0.1181, 0.9051, -0.2857, 0.315, 0.2606, -0.2128, -0.9417), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(-0.6531, 0.3001, -0.861, -0.3361, 0.9344, 0.1181, -0.9051, -0.2857, -0.315, -0.2606, -0.2128, 0.9417), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.0735), CFrame.new(-0.7465, 0.2255, -0.7572, -0.8483, 0.4321, 0.306, 0.4609, 0.3183, 0.8284, 0.2606, 0.8438, -0.4692), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1643, 0.147), CFrame.new(-0.7128, 0.3168, -0.8089, 0.8483, 0.4321, -0.306, -0.4609, 0.3183, -0.8284, -0.2606, 0.8438, 0.4692), "JambeG"},
	{"Cristaux", "emeraude2", "Bloc", Vector3.new(0.14, 0.165, 0.14), CFrame.new(-0.3638, 0.0485, -0.7447, 0.8462, 0.1961, -0.4954, 0.3026, 0.5883, 0.7498, 0.4385, -0.7845, 0.4385), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(-0.4013, 0.0759, -0.8338, -0.661, -0.6857, 0.3048, 0.0022, 0.4045, 0.9145, -0.7504, 0.6051, -0.2659), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(-0.3758, 0.1524, -0.8561, 0.661, -0.6857, -0.3048, -0.0022, 0.4045, -0.9145, 0.7504, 0.6051, 0.2659), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(-0.2919, 0.1245, -0.8561, 0.5301, 0.7913, -0.3048, -0.3948, -0.0878, -0.9145, -0.7504, 0.6051, 0.2659), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(-0.3174, 0.0479, -0.8338, -0.5301, 0.7913, 0.3048, 0.3948, -0.0878, 0.9145, 0.7504, 0.6051, -0.2659), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(-0.2955, 0.1137, -0.779, 0.8415, 0.5401, 0.0115, 0.5395, -0.8413, 0.0344, 0.0282, -0.0227, -0.9993), "JambeG"},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(-0.2945, 0.1166, -0.8626, -0.8415, 0.5401, -0.0115, -0.5395, -0.8413, -0.0344, -0.0282, -0.0227, 0.9993), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.1089), CFrame.new(-0.3784, 0.1446, -0.8626, -0.3495, -0.9369, -0.0115, 0.9365, -0.349, -0.0344, 0.0282, -0.0227, 0.9993), "JambeG"},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0168, 0.1272, 0.0585), CFrame.new(-0.3794, 0.1417, -0.779, 0.3495, -0.9369, 0.0115, -0.9365, -0.349, 0.0344, -0.0282, -0.0227, -0.9993), "JambeG"},
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
	modele.Name = "JambieresEmeraude"
	modele:SetAttribute("NomAffiche", "Jambières d'émeraude")

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
	Nom = "Jambières d'émeraude",
	Format = "Code",
	Taille = Vector3.new(2.3035, 1.99, 1.6082),
	Centre = Vector3.new(0, 0.005, -0.1117), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
