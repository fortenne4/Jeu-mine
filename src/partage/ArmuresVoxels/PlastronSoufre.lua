-- Généré par blender/armes/armures_minerais.py (49 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de soufre : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronSoufre.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["soufre"] = {"Slate", 214, 168, 52, 0},
	["soufre2"] = {"Slate", 190, 146, 40, 0},
	["soufre3"] = {"Slate", 230, 190, 80, 0},
	["fer"] = {"Metal", 98, 84, 92, 0.05},
	["fer2"] = {"Metal", 78, 66, 74, 0.05},
	["rivet"] = {"Metal", 150, 132, 140, 0.1},
	["cuir"] = {"Fabric", 70, 46, 30, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "soufre", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9788, 0.0138, -0.2045, -0.0163, 0.9998, -0.0104, 0.2043, 0.0135, 0.9788)},
	{"Liseré", "fer", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "soufre3", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9791, -0.0112, 0.2031, 0.013, 0.9999, -0.0073, -0.203, 0.0098, 0.9791)},
	{"Liseré", "fer", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "fer", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "soufre", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9897, -0.03, -0.1397, 0.0128, 0.9924, -0.1221, 0.1423, 0.1191, 0.9826)},
	{"Lames", "soufre2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9889, 0.0034, 0.1483, 0.0173, 0.9903, -0.1379, -0.1473, 0.1389, 0.9793)},
	{"Lames", "soufre3", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9921, -0.0322, -0.1214, 0.0136, 0.9885, -0.1507, 0.1249, 0.1478, 0.9811)},
	{"Lames", "soufre", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9884, 0.0014, 0.1517, 0.0174, 0.9922, -0.1231, -0.1507, 0.1243, 0.9807)},
	{"Lames", "soufre", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9917, -0.0101, -0.1283, -0.0082, 0.99, -0.1408, 0.1284, 0.1407, 0.9817)},
	{"Lames", "soufre3", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9899, 0.0311, 0.1381, -0.0132, 0.9916, -0.1288, -0.1409, 0.1257, 0.982)},
	{"Flanc", "soufre", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, -0.0127, 0.0003, 0.9999, 0.0082, 1, -0.0002, -0.9999, 0.0082, -0.0127)},
	{"Flanc", "soufre2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0047, 0.0069, -1, 0.0062, 1, 0.0069, 1, -0.0062, 0.0047)},
	{"Dossiere", "soufre2", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.9999, 0.0056, -0.0102, 0.0054, 0.9998, 0.0169, 0.0103, 0.0169, -0.9998)},
	{"Dossiere", "fer", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "soufre", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9999, 0.0125, 0.0039, -0.0129, 0.992, 0.126, -0.0023, -0.126, 0.992)},
	{"Dossiere", "soufre3", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9999, -0.0122, -0.0085, 0.0132, 0.9904, 0.1375, 0.0067, -0.1376, 0.9905)},
	{"Dossiere", "soufre2", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9998, -0.0157, -0.0098, 0.017, 0.9886, 0.1494, 0.0073, -0.1495, 0.9887)},
	{"Col", "fer", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "fer", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "fer", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "fer", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "soufre", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.99, 0.1411, -0.0093, -0.1409, 0.9899, 0.0184, 0.0118, -0.0169, 0.9998)},
	{"Epauliere", "soufre2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8837, 0.468, 0.0117, -0.468, 0.8837, 0.001, -0.0099, -0.0064, 0.9999)},
	{"Epauliere", "fer", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "soufre3", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9879, -0.1548, 0.0047, 0.1547, 0.9879, 0.0039, -0.0052, -0.0031, 1)},
	{"Epauliere", "soufre", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8776, -0.4793, 0.0034, 0.4793, 0.8776, -0.0059, -0.0001, 0.0068, 1)},
	{"Epauliere", "fer", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Ceinture", "fer2", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "rivet", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.17, 0.8, 0.07), CFrame.new(0.4525, 0.36, -0.7114, 0.9781, 0, 0.2079, 0, -1, 0, 0.2079, 0, -0.9781)},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.17, 0.7414, 0.07), CFrame.new(0.4483, -0.4416, -0.7045, 0.9904, 0.0068, 0.1382, -0.0074, -0.9947, 0.1022, 0.1381, -0.1023, -0.9851)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.4576, 0.62, -0.7354, -0.6917, 0.6917, 0.2079, 0.7071, 0.7071, 0, -0.147, 0.147, -0.9781)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.4576, 0.16, -0.7354, -0.6917, 0.6917, 0.2079, 0.7071, 0.7071, 0, -0.147, 0.147, -0.9781)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.4516, -0.1982, -0.7085, -0.7139, 0.6865, 0.1378, 0.7002, 0.7002, 0.1392, -0.001, 0.1959, -0.9806)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.4516, -0.6782, -0.7485, -0.7139, 0.6865, 0.1378, 0.7002, 0.7002, 0.1392, -0.001, 0.1959, -0.9806)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(1.0622, 1.0471, -0.45, -0.7002, -0.7002, 0.1392, 0.0984, 0.0984, 0.9903, -0.7071, 0.7071, 0)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(1.0622, 1.0471, 0.45, -0.7002, -0.7002, 0.1392, 0.0984, 0.0984, 0.9903, -0.7071, 0.7071, 0)},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.17, 0.8, 0.07), CFrame.new(-0.4525, 0.36, -0.7114, 0.9781, 0, -0.2079, 0, -1, 0, -0.2079, 0, -0.9781)},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.17, 0.7414, 0.07), CFrame.new(-0.4483, -0.4416, -0.7045, 0.9904, -0.0068, -0.1382, 0.0074, -0.9947, 0.1022, -0.1381, -0.1023, -0.9851)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.4576, 0.62, -0.7354, -0.6917, 0.6917, -0.2079, 0.7071, 0.7071, 0, 0.147, -0.147, -0.9781)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.4576, 0.16, -0.7354, -0.6917, 0.6917, -0.2079, 0.7071, 0.7071, 0, 0.147, -0.147, -0.9781)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.4516, -0.1982, -0.7085, -0.6865, 0.7139, -0.1378, 0.7002, 0.7002, 0.1392, 0.1959, -0.001, -0.9806)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.4516, -0.6782, -0.7485, -0.6865, 0.7139, -0.1378, 0.7002, 0.7002, 0.1392, 0.1959, -0.001, -0.9806)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(-1.0622, 1.0471, -0.45, 0.7002, 0.7002, -0.1392, 0.0984, 0.0984, 0.9903, 0.7071, -0.7071, 0)},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(-1.0622, 1.0471, 0.45, 0.7002, 0.7002, -0.1392, 0.0984, 0.0984, 0.9903, 0.7071, -0.7071, 0)},
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
	modele.Name = "PlastronSoufre"
	modele:SetAttribute("NomAffiche", "Plastron de soufre")

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
	Nom = "Plastron de soufre",
	Format = "Code",
	Taille = Vector3.new(4.0627, 2.1163, 1.6147),
	Centre = Vector3.new(0.0029, 0.0882, -0.039), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
