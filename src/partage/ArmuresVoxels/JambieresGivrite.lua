-- Généré par blender/armes/armures_minerais.py (63 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de givrite : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresGivrite.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["glace"] = {"SmoothPlastic", 150, 190, 236, 0.15},
	["glace2"] = {"SmoothPlastic", 120, 166, 222, 0.15},
	["glace3"] = {"SmoothPlastic", 190, 218, 248, 0.2},
	["argent"] = {"Metal", 206, 208, 220, 0.15},
	["gemme"] = {"Neon", 150, 210, 255, 0},
	["cuir"] = {"Fabric", 88, 102, 134, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "glace2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.999, 0.0308, -0.0329, -0.0334, 0.9962, -0.0803, 0.0303, 0.0814, 0.9962), "JambeD"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "glace", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0.0167, -0.0207, 0.9996, -0.0232, 0.9995, 0.021, -0.9996, -0.0236, 0.0162), "JambeD"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "glace", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9995, 0.0244, 0.0174, -0.0249, 0.9993, 0.0287, -0.0167, -0.0291, 0.9994), "JambeD"},
	{"Greve", "glace3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9996, -0.0246, 0.0154, 0.0239, 0.9989, 0.04, -0.0164, -0.0396, 0.9991), "JambeD"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "glace", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, -0.034, 0.0013, 0.9994, -0.0291, 0.9996, -0.0023, -0.999, -0.0292, -0.034), "JambeD"},
	{"Mollet", "glace", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9998, 0.0205, -0.0032, -0.0207, 0.997, -0.0747, 0.0017, 0.0748, 0.9972), "JambeD"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.18, 0.231, 0.18), CFrame.new(0.5, 0.1761, -0.7641, 0.7071, 0, 0.7071, -0.3922, 0.8321, 0.3922, -0.5883, -0.5547, 0.5883), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(0.4931, 0.3155, -0.9252, -0.6384, -0.5295, 0.5586, -0.0036, -0.7237, -0.6901, 0.7697, -0.4426, 0.4601), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(0.5567, 0.2369, -0.8728, 0.6384, -0.5295, -0.5586, 0.0036, -0.7237, 0.6901, -0.7697, -0.4426, -0.4601), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(0.4433, 0.2369, -0.8728, 0.6384, 0.5295, 0.5586, -0.0036, -0.7237, 0.6901, 0.7697, -0.4426, -0.4601), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(0.5069, 0.3155, -0.9252, -0.6384, 0.5295, -0.5586, 0.0036, -0.7237, -0.6901, -0.7697, -0.4426, 0.4601), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(0.5069, 0.3784, -0.8308, 0.6384, 0.5295, -0.5586, -0.7119, 0.1302, -0.6901, -0.2927, 0.8382, 0.4601), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(0.4433, 0.2998, -0.7783, -0.6384, 0.5295, 0.5586, 0.7119, 0.1302, 0.6901, 0.2927, 0.8382, -0.4601), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(0.5567, 0.2998, -0.7783, -0.6384, -0.5295, -0.5586, -0.7119, 0.1302, 0.6901, -0.2927, 0.8382, -0.4601), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(0.4931, 0.3784, -0.8308, 0.6384, -0.5295, 0.5586, 0.7119, 0.1302, -0.6901, 0.2927, 0.8382, 0.4601), "JambeD"},
	{"Cristaux", "glace", "Bloc", Vector3.new(0.17, 0.22, 0.17), CFrame.new(1.1509, 0.6728, 0.0662, 0.5503, 0.7352, 0.3957, -0.456, 0.6617, -0.5951, -0.6994, 0.147, 0.6994), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(1.2962, 0.8124, 0.0419, -0.8116, -0.5327, -0.2399, 0.1298, 0.2359, -0.9631, 0.5697, -0.8127, -0.1223), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(1.2702, 0.7081, 0.0287, 0.8116, -0.5327, 0.2399, -0.1298, 0.2359, 0.9631, -0.5697, -0.8127, 0.1223), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(1.1986, 0.7878, 0.0287, 0.0439, 0.1787, 0.9829, -0.8207, -0.5546, 0.1375, 0.5697, -0.8127, 0.1223), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(1.3049, 0.8027, 0.0419, -0.0439, 0.1787, -0.9829, 0.8207, -0.5546, -0.1375, -0.5697, -0.8127, -0.1223), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(1.1868, 0.7772, 0.1347, 0.1837, -0.7173, 0.6721, -0.6949, 0.3888, 0.6049, -0.6952, -0.5782, -0.427), "JambeD"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(1.2596, 0.8427, 0.0885, -0.1837, -0.7173, -0.6721, 0.6949, 0.3888, -0.6049, 0.6952, -0.5782, 0.427), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(1.3313, 0.7631, 0.0885, -0.6718, 0.3114, -0.6721, 0.2556, -0.7542, -0.6049, -0.6952, -0.5782, 0.427), "JambeD"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(1.2585, 0.6976, 0.1347, 0.6718, 0.3114, 0.6721, -0.2556, -0.7542, 0.6049, 0.6952, -0.5782, -0.427), "JambeD"},
	{"Genouillere", "gemme", "Bloc", Vector3.new(0.12, 0.12, 0.05), CFrame.new(0.5, -0.1, -0.74, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "glace2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.999, -0.0308, 0.0329, 0.0334, 0.9962, -0.0803, -0.0303, 0.0814, 0.9962), "JambeG"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "glace", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0.0167, 0.0207, -0.9996, 0.0232, 0.9995, 0.021, 0.9996, -0.0236, 0.0162), "JambeG"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "glace", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9995, -0.0244, -0.0174, 0.0249, 0.9993, 0.0287, 0.0167, -0.0291, 0.9994), "JambeG"},
	{"Greve", "glace3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9996, 0.0246, -0.0154, -0.0239, 0.9989, 0.04, 0.0164, -0.0396, 0.9991), "JambeG"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "glace", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, -0.034, -0.0013, -0.9994, 0.0291, 0.9996, -0.0023, 0.999, -0.0292, -0.034), "JambeG"},
	{"Mollet", "glace", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9998, -0.0205, 0.0032, 0.0207, 0.997, -0.0747, -0.0017, 0.0748, 0.9972), "JambeG"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.18, 0.231, 0.18), CFrame.new(-0.5, 0.1761, -0.7641, 0.7071, 0, -0.7071, 0.3922, 0.8321, 0.3922, 0.5883, -0.5547, 0.5883), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-0.4931, 0.3155, -0.9252, -0.6384, 0.5295, -0.5586, 0.0036, -0.7237, -0.6901, -0.7697, -0.4426, 0.4601), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-0.5567, 0.2369, -0.8728, 0.6384, 0.5295, 0.5586, -0.0036, -0.7237, 0.6901, 0.7697, -0.4426, -0.4601), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-0.4433, 0.2369, -0.8728, 0.6384, -0.5295, -0.5586, 0.0036, -0.7237, 0.6901, -0.7697, -0.4426, -0.4601), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-0.5069, 0.3155, -0.9252, -0.6384, -0.5295, 0.5586, -0.0036, -0.7237, -0.6901, 0.7697, -0.4426, 0.4601), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-0.5069, 0.3784, -0.8308, 0.6384, -0.5295, 0.5586, 0.7119, 0.1302, -0.6901, 0.2927, 0.8382, 0.4601), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-0.4433, 0.2998, -0.7783, -0.6384, -0.5295, -0.5586, -0.7119, 0.1302, 0.6901, -0.2927, 0.8382, -0.4601), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-0.5567, 0.2998, -0.7783, -0.6384, 0.5295, 0.5586, 0.7119, 0.1302, 0.6901, 0.2927, 0.8382, -0.4601), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-0.4931, 0.3784, -0.8308, 0.6384, 0.5295, -0.5586, -0.7119, 0.1302, -0.6901, -0.2927, 0.8382, 0.4601), "JambeG"},
	{"Cristaux", "glace", "Bloc", Vector3.new(0.17, 0.22, 0.17), CFrame.new(-1.1509, 0.6728, 0.0662, 0.5503, -0.7352, -0.3957, 0.456, 0.6617, -0.5951, 0.6994, 0.147, 0.6994), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(-1.2962, 0.8124, 0.0419, -0.8116, 0.5327, 0.2399, -0.1298, 0.2359, -0.9631, -0.5697, -0.8127, -0.1223), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(-1.2702, 0.7081, 0.0287, 0.8116, 0.5327, -0.2399, 0.1298, 0.2359, 0.9631, 0.5697, -0.8127, 0.1223), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(-1.1986, 0.7878, 0.0287, 0.0439, -0.1787, -0.9829, 0.8207, -0.5546, 0.1375, -0.5697, -0.8127, 0.1223), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(-1.3049, 0.8027, 0.0419, -0.0439, -0.1787, 0.9829, -0.8207, -0.5546, -0.1375, 0.5697, -0.8127, -0.1223), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(-1.1868, 0.7772, 0.1347, 0.1837, 0.7173, -0.6721, 0.6949, 0.3888, 0.6049, 0.6952, -0.5782, -0.427), "JambeG"},
	{"Cristaux", "glace", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(-1.2596, 0.8427, 0.0885, -0.1837, 0.7173, 0.6721, -0.6949, 0.3888, -0.6049, -0.6952, -0.5782, 0.427), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.1497), CFrame.new(-1.3313, 0.7631, 0.0885, -0.6718, -0.3114, 0.6721, -0.2556, -0.7542, -0.6049, 0.6952, -0.5782, 0.427), "JambeG"},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0204, 0.1563, 0.0668), CFrame.new(-1.2585, 0.6976, 0.1347, 0.6718, -0.3114, -0.6721, 0.2556, -0.7542, 0.6049, -0.6952, -0.5782, -0.427), "JambeG"},
	{"Genouillere", "gemme", "Bloc", Vector3.new(0.12, 0.12, 0.05), CFrame.new(-0.5, -0.1, -0.74, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
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
	modele.Name = "JambieresGivrite"
	modele:SetAttribute("NomAffiche", "Jambières de givrite")

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
	Nom = "Jambières de givrite",
	Format = "Code",
	Taille = Vector3.new(2.7357, 1.99, 1.6076),
	Centre = Vector3.new(0, 0.005, -0.1355), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
