-- Généré par blender/armes/armures_minerais.py (71 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron d'obsidienne : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronObsidienne.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["obs"] = {"SmoothPlastic", 34, 28, 40, 0.12},
	["obs2"] = {"SmoothPlastic", 52, 42, 60, 0.1},
	["obs3"] = {"SmoothPlastic", 72, 58, 82, 0.08},
	["veine"] = {"Neon", 182, 60, 255, 0},
	["gemme"] = {"Neon", 205, 110, 255, 0},
	["cuir"] = {"Fabric", 40, 28, 48, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "obs2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9734, -0.0274, -0.2275, 0.0348, 0.999, 0.0285, 0.2265, -0.0357, 0.9734)},
	{"Liseré", "obs3", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "obs2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9884, 0.0087, 0.1516, 0.0019, 0.9976, -0.0695, -0.1519, 0.069, 0.986)},
	{"Liseré", "obs3", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "obs3", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "obs2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.988, -0.0755, -0.1346, 0.0517, 0.9837, -0.1722, 0.1454, 0.1632, 0.9758)},
	{"Lames", "obs", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9757, 0.0853, 0.2018, -0.0451, 0.9795, -0.1961, -0.2144, 0.1823, 0.9596)},
	{"Lames", "obs", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9843, 0.0491, -0.1696, -0.071, 0.9895, -0.1257, 0.1616, 0.1358, 0.9775)},
	{"Lames", "obs3", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9895, -0.0122, 0.1442, 0.042, 0.9777, -0.2056, -0.1385, 0.2095, 0.9679)},
	{"Lames", "obs2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9906, -0.0542, -0.1258, 0.0336, 0.9866, -0.1599, 0.1328, 0.1542, 0.9791)},
	{"Lames", "obs2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9962, 0, 0.0874, 0.0147, 0.9857, -0.1679, -0.0862, 0.1686, 0.9819)},
	{"Flanc", "obs2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, 0.0204, -0.03, 0.9993, 0.0285, 0.9992, 0.0294, -0.9994, 0.0279, 0.0212)},
	{"Flanc", "obs", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0479, 0.0225, -0.9986, 0.0064, 0.9997, 0.0229, 0.9988, -0.0074, 0.0477)},
	{"Dossiere", "obs", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.999, -0.0038, -0.0448, -0.0055, 0.9993, 0.0376, 0.0446, 0.0378, -0.9983)},
	{"Dossiere", "obs3", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "obs2", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9981, 0.0329, -0.0516, -0.0224, 0.9813, 0.1909, 0.0569, -0.1894, 0.9802)},
	{"Dossiere", "obs", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9979, -0.0506, -0.0412, 0.0575, 0.9805, 0.1879, 0.0309, -0.1899, 0.9813)},
	{"Dossiere", "obs", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9981, 0.0143, -0.0595, -0.0066, 0.9919, 0.1268, 0.0608, -0.1261, 0.9901)},
	{"Col", "obs3", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "obs3", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "obs3", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "obs3", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "obs2", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9949, 0.0987, 0.0202, -0.0992, 0.9948, 0.0231, -0.0178, -0.025, 0.9995)},
	{"Epauliere", "obs", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.879, 0.4765, 0.0157, -0.4749, 0.878, -0.0605, -0.0426, 0.0457, 0.998)},
	{"Epauliere", "obs3", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "obs2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9852, 0.1579, -0.0665, -0.1582, 0.9874, 0.0003, 0.0657, 0.0102, 0.9978)},
	{"Epauliere", "obs", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9912, -0.1301, -0.0248, 0.1288, 0.9905, -0.0471, 0.0307, 0.0435, 0.9986)},
	{"Epauliere", "obs2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8698, -0.4935, 0.0036, 0.4929, 0.8683, -0.0567, 0.0249, 0.051, 0.9984)},
	{"Epauliere", "obs3", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "obs", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9775, -0.2011, -0.0634, 0.204, 0.978, 0.0427, 0.0534, -0.0547, 0.9971)},
	{"Ceinture", "obs2", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "obs3", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "obs2", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 0.9997, -0.021, -0.0084, 0.0202, 0.9956, -0.0917, 0.0103, 0.0915, 0.9958)},
	{"Tassette", "obs3", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "obs", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9999, 0.0042, 0.0119, -0.0033, 0.9974, -0.0715, -0.0122, 0.0715, 0.9974)},
	{"Tassette", "obs3", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Gemme", "obs3", "Coin", Vector3.new(0.07, 0.235, 0.15), CFrame.new(-0.075, 0.5575, -0.825, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Gemme", "obs3", "Coin", Vector3.new(0.07, 0.235, 0.15), CFrame.new(0.075, 0.5575, -0.825, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Gemme", "obs3", "Coin", Vector3.new(0.07, 0.235, 0.15), CFrame.new(-0.075, 0.3225, -0.825, 0, 0, 1, 0, -1, 0, 1, 0, 0)},
	{"Gemme", "obs3", "Coin", Vector3.new(0.07, 0.235, 0.15), CFrame.new(0.075, 0.3225, -0.825, 0, 0, -1, 0, -1, 0, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.1465), CFrame.new(0.0074, 0.5207, -0.8877, -0.4924, 0.7074, -0.507, 0.2897, -0.4161, -0.8619, -0.8207, -0.5713, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.0507), CFrame.new(-0.0426, 0.4357, -0.8877, 0.4924, 0.7074, 0.507, -0.2897, -0.4161, 0.8619, 0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.0507), CFrame.new(-0.0426, 0.4443, -0.8877, -0.4924, 0.7074, 0.507, -0.2897, 0.4161, -0.8619, -0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.1465), CFrame.new(0.0074, 0.3593, -0.8877, 0.4924, 0.7074, -0.507, 0.2897, 0.4161, 0.8619, 0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.1465), CFrame.new(-0.0074, 0.3593, -0.8877, 0.4924, -0.7074, 0.507, -0.2897, 0.4161, 0.8619, -0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.0507), CFrame.new(0.0426, 0.4443, -0.8877, -0.4924, -0.7074, -0.507, 0.2897, 0.4161, -0.8619, 0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.0507), CFrame.new(0.0426, 0.4357, -0.8877, 0.4924, -0.7074, -0.507, 0.2897, -0.4161, 0.8619, -0.8207, -0.5713, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.105, 0.1465), CFrame.new(-0.0074, 0.5207, -0.8877, -0.4924, -0.7074, 0.507, -0.2897, -0.4161, -0.8619, 0.8207, -0.5713, 0)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.36, 0.03), CFrame.new(0.6135, 0.5, -0.6823, -0.8471, 0.4891, 0.2079, 0.5, 0.866, 0, -0.1801, 0.104, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.198, 0.03), CFrame.new(0.6246, 0.6597, -0.68, -0.3345, 0.9192, 0.2079, 0.9397, 0.342, 0, -0.0711, 0.1954, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(0.3135, 0.12, -0.7461, -0.7493, -0.6287, 0.2079, -0.6428, 0.766, 0, -0.1593, -0.1336, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(0.1856, 0.1669, -0.7733, -0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.26, 0.03), CFrame.new(0.559, -0.441, -0.6939, -0.3569, 0.9239, 0.1378, 0.9305, 0.3387, 0.1392, 0.0819, 0.1779, -0.9806)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.143, 0.03), CFrame.new(0.6301, -0.3406, -0.6697, 0.3205, 0.9372, 0.1378, 0.9305, -0.3387, 0.1392, 0.1771, 0.0836, -0.9806)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(1.1636, 1.0501, 0.2, 0.9305, -0.3387, 0.1392, -0.1308, 0.0476, 0.9903, -0.342, -0.9397, 0)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(1.1881, 1.0466, 0.0633, 0.4951, -0.8576, 0.1392, -0.0696, 0.1205, 0.9903, -0.866, -0.5, 0)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.32, 0.03), CFrame.new(0.5, 0.4, 0.685, 0.8192, -0.5736, 0, 0.5736, 0.8192, 0, 0, 0, 1)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.176, 0.03), CFrame.new(0.4839, 0.545, 0.685, 0.2588, -0.9659, 0, 0.9659, 0.2588, 0, 0, 0, 1)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.36, 0.03), CFrame.new(-0.6135, 0.5, -0.6823, -0.8471, -0.4891, -0.2079, -0.5, 0.866, 0, 0.1801, 0.104, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.198, 0.03), CFrame.new(-0.7432, 0.5897, -0.6548, -0.9633, 0.1699, -0.2079, 0.1736, 0.9848, 0, 0.2048, -0.0361, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-0.3135, 0.12, -0.7461, -0.7493, 0.6287, -0.2079, 0.6428, 0.766, 0, 0.1593, -0.1336, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-0.2905, 0.2569, -0.751, -0.1699, 0.9633, -0.2079, 0.9848, 0.1736, 0, 0.0361, -0.2048, -0.9781)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.26, 0.03), CFrame.new(-0.559, -0.441, -0.6939, -0.3569, -0.9239, -0.1378, -0.9305, 0.3387, 0.1392, -0.0819, 0.1779, -0.9806)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.143, 0.03), CFrame.new(-0.68, -0.4709, -0.6811, -0.8673, -0.4784, -0.1378, -0.4951, 0.8576, 0.1392, 0.0516, 0.1889, -0.9806)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-1.1636, 1.0501, 0.2, 0.9305, 0.3387, -0.1392, 0.1308, 0.0476, 0.9903, 0.342, -0.9397, 0)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-1.0579, 1.0649, 0.1112, 0.9305, -0.3387, -0.1392, 0.1308, -0.0476, 0.9903, -0.342, -0.9397, 0)},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.32, 0.03), CFrame.new(-0.5, 0.4, 0.685, 0.8192, 0.5736, 0, -0.5736, 0.8192, 0, 0, 0, 1)},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.176, 0.03), CFrame.new(-0.3692, 0.4647, 0.685, 0.9962, -0.0872, 0, 0.0872, 0.9962, 0, 0, 0, 1)},
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

local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "PlastronObsidienne"
	modele:SetAttribute("NomAffiche", "Plastron d'obsidienne")

	local racine = invisible("Racine", Vector3.zero)
	racine.Parent = modele
	modele.PrimaryPart = racine

	local lumieres: { [string]: boolean } = {}
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6]
		local cleLumiere = ""
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
		if marque == "lumiere" and not lumieres[cleLumiere] then
			lumieres[cleLumiere] = true
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(190, 70, 255)
			l.Range = 5
			l.Brightness = 0.8
			l.Shadows = false
			l.Parent = p
		end
		p.Parent = modele
		souder(racine, p)
	end
	return modele
end

return {
	Nom = "Plastron d'obsidienne",
	Format = "Code",
	Taille = Vector3.new(4.39, 2.4161, 1.7285),
	Centre = Vector3.new(-0.0035, -0.0281, -0.0658), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
