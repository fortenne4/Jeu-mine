-- Généré par blender/armes/armures_minerais.py (51 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de quartz : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresQuartz.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["pierre"] = {"Slate", 128, 112, 120, 0},
	["pierre2"] = {"Slate", 104, 92, 100, 0},
	["cadre"] = {"Slate", 150, 134, 140, 0},
	["quartz"] = {"SmoothPlastic", 232, 186, 218, 0.1},
	["quartz2"] = {"SmoothPlastic", 210, 156, 196, 0.1},
	["quartz3"] = {"SmoothPlastic", 246, 214, 236, 0.15},
	["cuir"] = {"Fabric", 82, 52, 40, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "pierre", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9995, 0.0314, -0.0075, -0.0319, 0.9957, -0.0874, 0.0047, 0.0876, 0.9961), "JambeD"},
	{"Cuissard", "cadre", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "pierre2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, -0.0056, 0.0246, 0.9997, 0.0269, 0.9993, -0.0244, -0.9996, 0.0268, -0.0062), "JambeD"},
	{"Genouillere", "cadre", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "pierre2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9996, -0.0244, 0.0156, 0.0244, 0.9997, 0.0054, -0.0158, -0.005, 0.9999), "JambeD"},
	{"Greve", "pierre2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9999, -0.0127, -0.0007, 0.0127, 0.9966, 0.0816, -0.0003, -0.0816, 0.9967), "JambeD"},
	{"Greve", "cadre", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "pierre", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, -0.0342, -0.026, 0.9991, 0.015, 0.9995, 0.0265, -0.9993, 0.0159, -0.0338), "JambeD"},
	{"Mollet", "pierre2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9999, 0.0059, 0.0099, -0.0053, 0.9985, -0.0541, -0.0102, 0.0541, 0.9985), "JambeD"},
	{"Cheville", "cadre", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Bandes", "quartz", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(0.23, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Bandes", "quartz3", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(0.5, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Bandes", "quartz2", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(0.77, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Bandes", "quartz2", "Bloc", Vector3.new(0.3, 0.5, 0.06), CFrame.new(0.3, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeD"},
	{"Bandes", "quartz", "Bloc", Vector3.new(0.3, 0.5, 0.06), CFrame.new(0.7, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeD"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.4894, 0.1094, -0.7868, -0.5298, -0.4683, 0.7071, -0.5298, -0.4683, -0.7071, 0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.5894, 0.0094, -0.7868, 0.5298, -0.4683, -0.7071, 0.5298, -0.4683, 0.7071, -0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.5894, 0.0306, -0.7868, -0.5298, -0.4683, -0.7071, 0.5298, 0.4683, -0.7071, 0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.4894, -0.0694, -0.7868, 0.5298, -0.4683, 0.7071, -0.5298, 0.4683, 0.7071, -0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.5106, -0.0694, -0.7868, 0.5298, 0.4683, -0.7071, 0.5298, 0.4683, 0.7071, 0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.4106, 0.0306, -0.7868, -0.5298, 0.4683, 0.7071, -0.5298, 0.4683, -0.7071, -0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.4106, 0.0094, -0.7868, 0.5298, 0.4683, 0.7071, -0.5298, -0.4683, 0.7071, 0.6623, -0.7493, 0), "JambeD"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(0.5106, 0.1094, -0.7868, -0.5298, 0.4683, -0.7071, 0.5298, -0.4683, -0.7071, -0.6623, -0.7493, 0), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "pierre", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9995, -0.0314, 0.0075, 0.0319, 0.9957, -0.0874, -0.0047, 0.0876, 0.9961), "JambeG"},
	{"Cuissard", "cadre", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "pierre2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, -0.0056, -0.0246, -0.9997, -0.0269, 0.9993, -0.0244, 0.9996, 0.0268, -0.0062), "JambeG"},
	{"Genouillere", "cadre", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "pierre2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9996, 0.0244, -0.0156, -0.0244, 0.9997, 0.0054, 0.0158, -0.005, 0.9999), "JambeG"},
	{"Greve", "pierre2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9999, 0.0127, 0.0007, -0.0127, 0.9966, 0.0816, 0.0003, -0.0816, 0.9967), "JambeG"},
	{"Greve", "cadre", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "pierre", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, -0.0342, 0.026, -0.9991, -0.015, 0.9995, 0.0265, 0.9993, 0.0159, -0.0338), "JambeG"},
	{"Mollet", "pierre2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9999, -0.0059, -0.0099, 0.0053, 0.9985, -0.0541, 0.0102, 0.0541, 0.9985), "JambeG"},
	{"Cheville", "cadre", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Bandes", "quartz", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(-0.23, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Bandes", "quartz3", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(-0.5, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Bandes", "quartz2", "Bloc", Vector3.new(0.22, 0.62, 0.06), CFrame.new(-0.77, -0.52, -0.64, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Bandes", "quartz2", "Bloc", Vector3.new(0.3, 0.5, 0.06), CFrame.new(-0.3, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeG"},
	{"Bandes", "quartz", "Bloc", Vector3.new(0.3, 0.5, 0.06), CFrame.new(-0.7, 0.52, -0.62, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeG"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.4894, 0.1094, -0.7868, -0.5298, 0.4683, -0.7071, 0.5298, -0.4683, -0.7071, -0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.5894, 0.0094, -0.7868, 0.5298, 0.4683, 0.7071, -0.5298, -0.4683, 0.7071, 0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.5894, 0.0306, -0.7868, -0.5298, 0.4683, 0.7071, -0.5298, 0.4683, -0.7071, -0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.4894, -0.0694, -0.7868, 0.5298, 0.4683, -0.7071, 0.5298, 0.4683, 0.7071, 0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.5106, -0.0694, -0.7868, 0.5298, -0.4683, 0.7071, -0.5298, 0.4683, 0.7071, -0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.4106, 0.0306, -0.7868, -0.5298, -0.4683, -0.7071, 0.5298, 0.4683, -0.7071, 0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.4106, 0.0094, -0.7868, 0.5298, -0.4683, -0.7071, 0.5298, -0.4683, 0.7071, -0.6623, -0.7493, 0), "JambeG"},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.04, 0.2135, 0.1414), CFrame.new(-0.5106, 0.1094, -0.7868, -0.5298, -0.4683, 0.7071, -0.5298, -0.4683, -0.7071, 0.6623, -0.7493, 0), "JambeG"},
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
	modele.Name = "JambieresQuartz"
	modele:SetAttribute("NomAffiche", "Jambières de quartz")

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
	Nom = "Jambières de quartz",
	Format = "Code",
	Taille = Vector3.new(2.2785, 1.99, 1.5446),
	Centre = Vector3.new(0, 0.005, -0.1077), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
