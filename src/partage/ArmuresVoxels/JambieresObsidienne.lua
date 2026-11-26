-- Généré par blender/armes/armures_minerais.py (41 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières d'obsidienne : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresObsidienne.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["obs"] = {"SmoothPlastic", 34, 28, 40, 0.12},
	["obs2"] = {"SmoothPlastic", 52, 42, 60, 0.1},
	["obs3"] = {"SmoothPlastic", 72, 58, 82, 0.08},
	["veine"] = {"Neon", 182, 60, 255, 0},
	["gemme"] = {"Neon", 205, 110, 255, 0},
	["cuir"] = {"Fabric", 40, 28, 48, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "obs", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9987, -0.0395, -0.0319, 0.0368, 0.9961, -0.0805, 0.035, 0.0793, 0.9962), "JambeD"},
	{"Cuissard", "obs3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "obs3", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0.0498, -0.0023, 0.9988, 0.0405, 0.9992, 0.0003, -0.9979, 0.0404, 0.0499), "JambeD"},
	{"Genouillere", "obs3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "obs", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9988, 0.0247, 0.0433, -0.0269, 0.9983, 0.0515, -0.042, -0.0526, 0.9977), "JambeD"},
	{"Greve", "obs", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9988, -0.0403, 0.0289, 0.0381, 0.9965, 0.0747, -0.0318, -0.0735, 0.9968), "JambeD"},
	{"Greve", "obs3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "obs2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0069, -0.063, 0.998, 0.0639, 0.996, 0.0624, -0.9979, 0.0633, 0.0109), "JambeD"},
	{"Mollet", "obs2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9974, -0.0577, 0.0426, 0.062, 0.9923, -0.1077, -0.036, 0.11, 0.9933), "JambeD"},
	{"Cheville", "obs3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.34, 0.03), CFrame.new(0.65, 0.55, -0.645, -0.9063, 0.4226, 0, 0.4226, 0.9063, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.187, 0.03), CFrame.new(0.644, 0.7028, -0.645, -0.4226, 0.9063, 0, 0.9063, 0.4226, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(0.3, -0.45, -0.645, -0.866, -0.5, 0, -0.5, 0.866, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(0.1794, -0.3811, -0.645, -0.9848, 0.1736, 0, 0.1736, 0.9848, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(1.115, -0.5, 0.1, 0, 0, 1, 0.6428, 0.766, 0, -0.766, 0.6428, 0), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(1.115, -0.3631, 0.1235, 0, 0, 1, 0.9848, 0.1736, 0, -0.1736, 0.9848, 0), "JambeD"},
	{"Genouillere", "obs3", "Bloc", Vector3.new(0.26, 0.26, 0.06), CFrame.new(0.5, 0.02, -0.73, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Genouillere", "gemme", "Bloc", Vector3.new(0.15, 0.15, 0.05), CFrame.new(0.5, 0.02, -0.765, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "obs", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9987, 0.0395, 0.0319, -0.0368, 0.9961, -0.0805, -0.035, 0.0793, 0.9962), "JambeG"},
	{"Cuissard", "obs3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "obs3", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0.0498, 0.0023, -0.9988, -0.0405, 0.9992, 0.0003, 0.9979, 0.0404, 0.0499), "JambeG"},
	{"Genouillere", "obs3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "obs", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9988, -0.0247, -0.0433, 0.0269, 0.9983, 0.0515, 0.042, -0.0526, 0.9977), "JambeG"},
	{"Greve", "obs", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9988, 0.0403, -0.0289, -0.0381, 0.9965, 0.0747, 0.0318, -0.0735, 0.9968), "JambeG"},
	{"Greve", "obs3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "obs2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0069, 0.063, -0.998, -0.0639, 0.996, 0.0624, 0.9979, 0.0633, 0.0109), "JambeG"},
	{"Mollet", "obs2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9974, 0.0577, -0.0426, -0.062, 0.9923, -0.1077, 0.036, 0.11, 0.9933), "JambeG"},
	{"Cheville", "obs3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.34, 0.03), CFrame.new(-0.65, 0.55, -0.645, -0.9063, -0.4226, 0, -0.4226, 0.9063, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.187, 0.03), CFrame.new(-0.644, 0.7028, -0.645, -0.4226, -0.9063, 0, -0.9063, 0.4226, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-0.3, -0.45, -0.645, -0.866, 0.5, 0, 0.5, 0.866, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-0.1794, -0.3811, -0.645, -0.9848, -0.1736, 0, -0.1736, 0.9848, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-1.115, -0.5, 0.1, 0, 0, -1, -0.6428, 0.766, 0, 0.766, 0.6428, 0), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-1.115, -0.3631, 0.1235, 0, 0, -1, -0.9848, 0.1736, 0, 0.1736, 0.9848, 0), "JambeG"},
	{"Genouillere", "obs3", "Bloc", Vector3.new(0.26, 0.26, 0.06), CFrame.new(-0.5, 0.02, -0.73, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Genouillere", "gemme", "Bloc", Vector3.new(0.15, 0.15, 0.05), CFrame.new(-0.5, 0.02, -0.765, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
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
	modele.Name = "JambieresObsidienne"
	modele:SetAttribute("NomAffiche", "Jambières d'obsidienne")

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
	Nom = "Jambières d'obsidienne",
	Format = "Code",
	Taille = Vector3.new(2.294, 1.99, 1.4869),
	Centre = Vector3.new(0, 0.005, -0.0466), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
