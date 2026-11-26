-- Généré par blender/armes/armures_minerais.py (51 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de quartz : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronQuartz.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

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

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "pierre", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9805, 0.012, -0.1962, -0.0116, 0.9999, 0.0033, 0.1963, -0.001, 0.9806)},
	{"Liseré", "cadre", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "pierre2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9839, -0.0168, 0.178, 0.0158, 0.9999, 0.0067, -0.1781, -0.0038, 0.984)},
	{"Liseré", "cadre", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "cadre", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "pierre2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9939, 0.0111, -0.1097, -0.0236, 0.9932, -0.1141, 0.1077, 0.116, 0.9874)},
	{"Lames", "pierre", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9927, -0.0027, 0.1209, 0.0185, 0.9915, -0.1291, -0.1195, 0.1303, 0.9842)},
	{"Lames", "pierre", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9863, 0.0115, -0.1646, -0.0298, 0.9936, -0.1093, 0.1623, 0.1127, 0.9803)},
	{"Lames", "pierre2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9884, 0.043, 0.1455, -0.0262, 0.9929, -0.1159, -0.1494, 0.1107, 0.9826)},
	{"Lames", "pierre", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9902, -0.0206, -0.1382, 0.0021, 0.9911, -0.1332, 0.1397, 0.1316, 0.9814)},
	{"Lames", "pierre2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9891, 0.0003, 0.1469, 0.0179, 0.9923, -0.1222, -0.1459, 0.1235, 0.9816)},
	{"Flanc", "pierre", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, 0.0098, -0.0334, 0.9994, -0.0256, 0.9991, 0.0337, -0.9996, -0.0259, 0.0089)},
	{"Flanc", "pierre", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0162, -0.0203, -0.9997, -0.0164, 0.9997, -0.0206, 0.9997, 0.0168, 0.0159)},
	{"Dossiere", "pierre2", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.9999, -0.0088, -0.0056, -0.0087, 0.9998, -0.019, 0.0057, -0.0189, -0.9998)},
	{"Dossiere", "cadre", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "pierre", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9995, -0.0211, -0.0245, 0.0244, 0.9889, 0.1462, 0.0212, -0.1468, 0.9889)},
	{"Dossiere", "pierre", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9995, -0.0084, -0.0319, 0.013, 0.9892, 0.146, 0.0304, -0.1463, 0.9888)},
	{"Dossiere", "pierre", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9996, -0.0148, 0.0223, 0.0112, 0.9881, 0.1533, -0.0243, -0.153, 0.9879)},
	{"Col", "cadre", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "cadre", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "cadre", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "cadre", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "pierre2", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.994, 0.1094, 0.001, -0.1094, 0.9939, -0.0148, -0.0026, 0.0146, 0.9999)},
	{"Epauliere", "pierre", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8787, 0.477, -0.0165, -0.4767, 0.8788, 0.0193, 0.0237, -0.0091, 0.9997)},
	{"Epauliere", "cadre", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "pierre", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9913, -0.1287, 0.0263, 0.1279, 0.9914, 0.0281, -0.0297, -0.0245, 0.9993)},
	{"Epauliere", "pierre2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8862, -0.4625, -0.0262, 0.462, 0.8866, -0.0227, 0.0337, 0.0081, 0.9994)},
	{"Epauliere", "cadre", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Ceinture", "pierre2", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "quartz3", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Cristal", "quartz", "Coin", Vector3.new(0.06, 0.4783, 0.456), CFrame.new(-0.2404, 0.4778, -0.844, 0.5292, -0.3236, -0.7844, -0.0723, 0.9039, -0.4217, 0.8454, 0.2799, 0.4549)},
	{"Cristal", "quartz", "Coin", Vector3.new(0.06, 0.4783, 0.3503), CFrame.new(-0.5566, 0.3078, -0.6606, -0.5292, -0.3236, 0.7844, 0.0723, 0.9039, 0.4217, -0.8454, 0.2799, -0.4549)},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.06, 0.4187, 0.2715), CFrame.new(0.0164, 0.5665, -0.8977, 0.3389, 0.5327, -0.7755, -0.4507, 0.8154, 0.3632, 0.8258, 0.2264, 0.5165)},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.06, 0.4187, 0.3893), CFrame.new(-0.2398, 0.6865, -0.7271, -0.3389, 0.5327, 0.7755, 0.4507, 0.8154, -0.3632, -0.8258, 0.2264, -0.5165)},
	{"Cristal", "quartz2", "Coin", Vector3.new(0.06, 0.4055, 0.37), CFrame.new(0.252, 0.687, -0.7269, -0.35, -0.5255, -0.7755, -0.4336, 0.8247, -0.3632, 0.8304, 0.2092, -0.5165)},
	{"Cristal", "quartz2", "Coin", Vector3.new(0.06, 0.4055, 0.2909), CFrame.new(-0.0043, 0.567, -0.8976, 0.35, -0.5255, 0.7755, 0.4336, 0.8247, 0.3632, -0.8304, 0.2092, 0.5165)},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.06, 0.4783, 0.3503), CFrame.new(0.5566, 0.3078, -0.6606, -0.5292, 0.3236, -0.7844, -0.0723, 0.9039, 0.4217, 0.8454, 0.2799, -0.4549)},
	{"Cristal", "quartz3", "Coin", Vector3.new(0.06, 0.4783, 0.456), CFrame.new(0.2404, 0.4778, -0.844, 0.5292, 0.3236, 0.7844, 0.0723, 0.9039, -0.4217, -0.8454, 0.2799, 0.4549)},
	{"Cristal", "quartz", "Coin", Vector3.new(0.06, 0.5002, 0.6325), CFrame.new(0.3162, 0.212, -0.8362, 0, 0, -1, 0.7334, 0.6798, 0, 0.6798, -0.7334, 0)},
	{"Cristal", "quartz", "Coin", Vector3.new(0.06, 0.5002, 0.6325), CFrame.new(-0.3162, 0.212, -0.8362, 0, 0, 1, -0.7334, 0.6798, 0, -0.6798, -0.7334, 0)},
	{"Cristal", "quartz2", "Coin", Vector3.new(0.06, 0.5002, 0.6325), CFrame.new(-0.3162, 0.212, -0.8362, 0, 0, 1, -0.7334, 0.6798, 0, -0.6798, -0.7334, 0)},
	{"Cristal", "quartz2", "Coin", Vector3.new(0.06, 0.5002, 0.6325), CFrame.new(0.3162, 0.212, -0.8362, 0, 0, -1, 0.7334, 0.6798, 0, 0.6798, -0.7334, 0)},
	{"Epauliere", "quartz", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(1.0441, 1.0618, -0.36, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "quartz3", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(1.0441, 1.0618, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "quartz2", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(1.0441, 1.0618, 0.36, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "quartz", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(-1.0441, 1.0618, -0.36, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "quartz3", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(-1.0441, 1.0618, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "quartz2", "Bloc", Vector3.new(0.86, 0.06, 0.26), CFrame.new(-1.0441, 1.0618, 0.36, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
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
	modele.Name = "PlastronQuartz"
	modele:SetAttribute("NomAffiche", "Plastron de quartz")

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
		p.Parent = modele
		souder(racine, p)
	end
	return modele
end

return {
	Nom = "Plastron de quartz",
	Format = "Code",
	Taille = Vector3.new(4.0796, 2.1237, 1.8083),
	Centre = Vector3.new(-0.0034, 0.0919, -0.1358), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
