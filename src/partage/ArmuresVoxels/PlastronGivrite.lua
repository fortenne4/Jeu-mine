-- Généré par blender/armes/armures_minerais.py (107 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de givrite : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronGivrite.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["glace"] = {"SmoothPlastic", 150, 190, 236, 0.15},
	["glace2"] = {"SmoothPlastic", 120, 166, 222, 0.15},
	["glace3"] = {"SmoothPlastic", 190, 218, 248, 0.2},
	["argent"] = {"Metal", 206, 208, 220, 0.15},
	["gemme"] = {"Neon", 150, 210, 255, 0},
	["gemme2"] = {"Neon", 220, 240, 255, 0},
	["cuir"] = {"Fabric", 88, 102, 134, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "glace3", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9782, -0.013, -0.2072, 0.0154, 0.9998, 0.0099, 0.207, -0.0128, 0.9782)},
	{"Liseré", "argent", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "glace3", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9743, 0.0291, 0.2233, -0.0313, 0.9995, 0.0067, -0.223, -0.0135, 0.9747)},
	{"Liseré", "argent", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "argent", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "glace3", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9909, 0.0156, -0.1339, -0.0301, 0.9938, -0.1072, 0.1314, 0.1103, 0.9852)},
	{"Lames", "glace3", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9876, 0.0257, 0.1547, -0.0079, 0.9934, -0.114, -0.1566, 0.1114, 0.9814)},
	{"Lames", "glace", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.987, -0.0024, -0.1605, -0.0172, 0.9925, -0.121, 0.1596, 0.1222, 0.9796)},
	{"Lames", "glace", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9914, 0.0064, 0.1311, 0.0136, 0.9884, -0.1514, -0.1305, 0.1518, 0.9797)},
	{"Lames", "glace3", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9863, -0.0056, -0.1646, -0.023, 0.985, -0.1713, 0.1631, 0.1727, 0.9714)},
	{"Lames", "glace", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9924, 0.0396, 0.1164, -0.0248, 0.9917, -0.1263, -0.1204, 0.1225, 0.9851)},
	{"Flanc", "glace", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, -0.0325, 0.0333, 0.9989, -0.0294, 0.999, -0.0342, -0.999, -0.0305, -0.0314)},
	{"Flanc", "glace", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0025, 0.0139, -0.9999, 0.0021, 0.9999, 0.0139, 1, -0.0022, 0.0025)},
	{"Dossiere", "glace2", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.9997, 0.0202, -0.012, 0.02, 0.9997, 0.0114, 0.0122, 0.0112, -0.9999)},
	{"Dossiere", "argent", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "glace3", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9999, 0.0051, -0.0135, -0.0032, 0.9905, 0.1374, 0.0141, -0.1374, 0.9904)},
	{"Dossiere", "glace2", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9999, -0.0061, -0.0103, 0.0075, 0.9892, 0.1461, 0.0093, -0.1461, 0.9892)},
	{"Dossiere", "glace", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9998, -0.0134, 0.015, 0.0116, 0.9932, 0.1158, -0.0164, -0.1156, 0.9932)},
	{"Col", "argent", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "argent", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "argent", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "argent", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "glace2", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9893, 0.1434, -0.0266, -0.1428, 0.9895, 0.0217, 0.0294, -0.0177, 0.9994)},
	{"Epauliere", "glace3", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8857, 0.4642, 0.0082, -0.464, 0.8856, -0.0207, -0.0169, 0.0146, 0.9998)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "glace3", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9936, 0.1126, -0.0001, -0.1126, 0.9936, -0.0081, -0.0008, 0.0081, 1)},
	{"Epauliere", "glace3", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9877, -0.154, -0.0274, 0.1548, 0.9876, 0.0277, 0.0228, -0.0316, 0.9992)},
	{"Epauliere", "glace3", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8982, -0.4394, -0.0094, 0.4395, 0.8981, 0.0138, 0.0024, -0.0165, 0.9999)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "glace2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9931, -0.1176, 0.0009, 0.1176, 0.993, 0.0107, -0.0022, -0.0106, 0.9999)},
	{"Ceinture", "argent", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "glace3", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "glace", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 1, 0.0071, -0.0047, -0.0074, 0.9975, -0.0708, 0.0042, 0.0708, 0.9975)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "glace3", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9991, -0.0258, -0.0343, 0.0229, 0.9965, -0.0806, 0.0363, 0.0797, 0.9962)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.2709, 0.2199), CFrame.new(0.075, 0.5775, -0.825, 0, 0.9029, -0.4299, 0, -0.4299, -0.9029, -1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.2709, 0.129), CFrame.new(0, 0.42, -0.825, 0, 0.9029, 0.4299, 0, -0.4299, 0.9029, 1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.2709, 0.2199), CFrame.new(0.075, 0.2625, -0.825, 0, 0.9029, -0.4299, 0, 0.4299, 0.9029, 1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.2709, 0.129), CFrame.new(0, 0.42, -0.825, 0, 0.9029, 0.4299, 0, 0.4299, -0.9029, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1105, 0.2321), CFrame.new(0.0076, 0.542, -0.8874, -0.5039, 0.7798, -0.3714, 0.2016, -0.3119, -0.9285, -0.8399, -0.5428, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1105, 0.0371), CFrame.new(-0.0424, 0.417, -0.8874, 0.5039, 0.7798, 0.3714, -0.2016, -0.3119, 0.9285, 0.8399, -0.5428, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.1105, 0.0371), CFrame.new(-0.0424, 0.423, -0.8874, -0.5039, 0.7798, 0.3714, -0.2016, 0.3119, -0.9285, -0.8399, -0.5428, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.1105, 0.2321), CFrame.new(0.0076, 0.298, -0.8874, 0.5039, 0.7798, -0.3714, 0.2016, 0.3119, 0.9285, 0.8399, -0.5428, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1105, 0.2321), CFrame.new(-0.0076, 0.298, -0.8874, 0.5039, -0.7798, 0.3714, -0.2016, 0.3119, 0.9285, -0.8399, -0.5428, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1105, 0.0371), CFrame.new(0.0424, 0.423, -0.8874, -0.5039, -0.7798, -0.3714, 0.2016, 0.3119, -0.9285, 0.8399, -0.5428, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.1105, 0.0371), CFrame.new(0.0424, 0.417, -0.8874, 0.5039, -0.7798, -0.3714, 0.2016, -0.3119, 0.9285, -0.8399, -0.5428, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.1105, 0.2321), CFrame.new(-0.0076, 0.542, -0.8874, -0.5039, -0.7798, 0.3714, -0.2016, -0.3119, -0.9285, 0.8399, -0.5428, 0)},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.2, 0.28, 0.2), CFrame.new(0.9441, 1.1334, -0.2801, 0.7062, 0.2844, 0.6484, -0.1069, 0.9481, -0.2995, -0.6999, 0.1422, 0.6999)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(1.0089, 1.3765, -0.3076, -0.7606, -0.5864, 0.2787, -0.295, -0.0702, -0.9529, 0.5783, -0.807, -0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(1.0454, 1.2519, -0.3232, 0.7606, -0.5864, -0.2787, 0.295, -0.0702, 0.9529, -0.5783, -0.807, 0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(0.9531, 1.3828, -0.2376, 0.4726, -0.8541, -0.2172, -0.665, -0.1839, -0.7239, 0.5783, 0.4865, -0.6549)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(0.9247, 1.2881, -0.3232, -0.4726, -0.8541, 0.2172, 0.665, -0.1839, 0.7239, -0.5783, 0.4865, 0.6549)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(0.9196, 1.271, -0.1985, 0.5252, -0.8099, 0.2614, -0.4896, -0.0364, 0.8712, -0.696, -0.5855, -0.4156)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(0.9537, 1.3849, -0.2529, -0.5252, -0.8099, -0.2614, 0.4896, -0.0364, -0.8712, 0.696, -0.5855, 0.4156)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(1.0402, 1.2348, -0.1985, -0.708, -0.6489, -0.2787, -0.1197, -0.2787, 0.9529, -0.696, 0.708, 0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(1.0038, 1.3594, -0.1829, 0.708, -0.6489, 0.2787, 0.1197, -0.2787, -0.9529, 0.696, 0.708, -0.1196)},
	{"Cristaux", "glace", "Bloc", Vector3.new(0.22, 0.358, 0.22), CFrame.new(1.2905, 1.1076, 0.1446, 0.697, 0.4983, 0.5157, -0.2127, 0.8305, -0.5149, -0.6848, 0.2491, 0.6848)},
	{"Cristaux", "glace", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(1.4395, 1.3715, 0.1505, -0.8407, -0.5397, 0.0445, -0.15, 0.153, -0.9768, 0.5203, -0.8278, -0.2096)},
	{"Cristaux", "glace", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(1.4459, 1.231, 0.1204, 0.8407, -0.5397, -0.0445, 0.15, 0.153, 0.9768, -0.5203, -0.8278, 0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(1.3263, 1.3027, 0.1204, 0.2633, 0.389, 0.8828, -0.8124, -0.4042, 0.4204, 0.5203, -0.8278, 0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(1.4533, 1.3632, 0.1505, -0.2633, 0.389, -0.8828, 0.8124, -0.4042, -0.4204, -0.5203, -0.8278, -0.2096)},
	{"Cristaux", "glace", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(1.3084, 1.2729, 0.2554, 0.4283, -0.7602, 0.4885, -0.5373, 0.2203, 0.8141, -0.7265, -0.6111, -0.3141)},
	{"Cristaux", "glace", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(1.3787, 1.39, 0.2103, -0.4283, -0.7602, -0.4885, 0.5373, 0.2203, -0.8141, 0.7265, -0.6111, 0.3141)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(1.4982, 1.3183, 0.2103, -0.6757, 0.5522, -0.4885, 0.1251, -0.5671, -0.8141, -0.7265, -0.6111, 0.3141)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(1.428, 1.2012, 0.2554, 0.6757, 0.5522, 0.4885, -0.1251, -0.5671, 0.8141, 0.7265, -0.6111, -0.3141)},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.18, 0.231, 0.18), CFrame.new(1.4161, 1.0138, 0.4768, 0.761, 0.5735, 0.3033, -0.2041, 0.6554, -0.7272, -0.6158, 0.4915, 0.6158)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(1.547, 1.1739, 0.5283, -0.9337, -0.3539, -0.0553, -0.0975, 0.3997, -0.9114, 0.3446, -0.8456, -0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(1.5407, 1.07, 0.4818, 0.9337, -0.3539, 0.0553, 0.0975, 0.3997, 0.9114, -0.3446, -0.8456, 0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(1.4553, 1.1448, 0.4818, 0.0273, 0.4431, 0.896, -0.9383, -0.2977, 0.1758, 0.3446, -0.8456, 0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(1.5574, 1.1648, 0.5283, -0.0273, 0.4431, -0.896, 0.9383, -0.2977, -0.1758, -0.3446, -0.8456, -0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(1.4186, 1.1028, 0.5807, 0.4406, -0.6124, 0.6565, -0.466, 0.469, 0.7502, -0.7673, -0.6364, -0.0787)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(1.4934, 1.1883, 0.5717, -0.4406, -0.6124, -0.6565, 0.466, 0.469, -0.7502, 0.7673, -0.6364, 0.0787)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(1.504, 1.028, 0.5807, -0.5204, -0.8522, 0.0553, 0.3748, -0.1697, 0.9114, -0.7673, 0.495, 0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(1.5103, 1.1319, 0.6271, 0.5204, -0.8522, -0.0553, -0.3748, -0.1697, -0.9114, 0.7673, 0.495, -0.4077)},
	{"Liseré", "argent", "Bloc", Vector3.new(0.06, 0.9991, 0.05), CFrame.new(0.4958, -0.8104, -0.7361, -0.0194, 0.9903, 0.1378, 0.9903, 0, 0.1392, 0.1378, 0.1392, -0.9806)},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.2, 0.28, 0.2), CFrame.new(-0.9441, 1.1334, -0.2801, 0.6484, -0.2844, 0.7062, 0.2995, 0.9481, 0.1069, -0.6999, 0.1422, 0.6999)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(-0.9247, 1.2881, -0.3232, -0.4726, 0.8541, -0.2172, -0.665, -0.1839, 0.7239, 0.5783, 0.4865, 0.6549)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(-0.9531, 1.3828, -0.2376, 0.4726, 0.8541, 0.2172, 0.665, -0.1839, -0.7239, -0.5783, 0.4865, -0.6549)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(-1.0454, 1.2519, -0.3232, 0.7606, 0.5864, 0.2787, -0.295, -0.0702, 0.9529, 0.5783, -0.807, 0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(-1.0089, 1.3765, -0.3076, -0.7606, 0.5864, -0.2787, 0.295, -0.0702, -0.9529, -0.5783, -0.807, -0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(-1.0038, 1.3594, -0.1829, 0.708, 0.6489, -0.2787, -0.1197, -0.2787, -0.9529, -0.696, 0.708, -0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(-1.0402, 1.2348, -0.1985, -0.708, 0.6489, 0.2787, 0.1197, -0.2787, 0.9529, 0.696, 0.708, 0.1196)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.1851), CFrame.new(-0.9537, 1.3849, -0.2529, -0.5252, 0.8099, 0.2614, -0.4896, -0.0364, -0.8712, -0.696, -0.5855, 0.4156)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.024, 0.1848, 0.0765), CFrame.new(-0.9196, 1.271, -0.1985, 0.5252, 0.8099, -0.2614, 0.4896, -0.0364, 0.8712, 0.696, -0.5855, -0.4156)},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.22, 0.358, 0.22), CFrame.new(-1.2905, 1.1076, 0.1446, 0.5157, -0.4983, 0.697, 0.5149, 0.8305, 0.2127, -0.6848, 0.2491, 0.6848)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(-1.4533, 1.3632, 0.1505, -0.2633, -0.389, 0.8828, -0.8124, -0.4042, -0.4204, 0.5203, -0.8278, -0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(-1.3263, 1.3027, 0.1204, 0.2633, -0.389, -0.8828, 0.8124, -0.4042, 0.4204, -0.5203, -0.8278, 0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(-1.4459, 1.231, 0.1204, 0.8407, 0.5397, 0.0445, -0.15, 0.153, 0.9768, 0.5203, -0.8278, 0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(-1.4395, 1.3715, 0.1505, -0.8407, 0.5397, -0.0445, 0.15, 0.153, -0.9768, -0.5203, -0.8278, -0.2096)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(-1.428, 1.2012, 0.2554, 0.6757, -0.5522, -0.4885, 0.1251, -0.5671, 0.8141, -0.7265, -0.6111, -0.3141)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(-1.4982, 1.3183, 0.2103, -0.6757, -0.5522, 0.4885, -0.1251, -0.5671, -0.8141, 0.7265, -0.6111, 0.3141)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.2036), CFrame.new(-1.3787, 1.39, 0.2103, -0.4283, 0.7602, 0.4885, -0.5373, 0.2203, -0.8141, -0.7265, -0.6111, 0.3141)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.025, 0.2033, 0.0841), CFrame.new(-1.3084, 1.2729, 0.2554, 0.4283, 0.7602, -0.4885, 0.5373, 0.2203, 0.8141, 0.7265, -0.6111, -0.3141)},
	{"Cristaux", "glace3", "Bloc", Vector3.new(0.18, 0.231, 0.18), CFrame.new(-1.4161, 1.0138, 0.4768, 0.3033, -0.5735, 0.761, 0.7272, 0.6554, 0.2041, -0.6158, 0.4915, 0.6158)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-1.5574, 1.1648, 0.5283, -0.0273, -0.4431, 0.896, -0.9383, -0.2977, -0.1758, 0.3446, -0.8456, -0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-1.4553, 1.1448, 0.4818, 0.0273, -0.4431, -0.896, 0.9383, -0.2977, 0.1758, -0.3446, -0.8456, 0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-1.5407, 1.07, 0.4818, 0.9337, 0.3539, -0.0553, -0.0975, 0.3997, 0.9114, 0.3446, -0.8456, 0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-1.547, 1.1739, 0.5283, -0.9337, 0.3539, 0.0553, 0.0975, 0.3997, -0.9114, -0.3446, -0.8456, -0.4077)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-1.504, 1.028, 0.5807, 0.5204, -0.5461, -0.6565, 0.3748, -0.5447, 0.7502, -0.7673, -0.6364, -0.0787)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-1.5788, 1.1135, 0.5717, -0.5204, -0.5461, 0.6565, -0.3748, -0.5447, -0.7502, 0.7673, -0.6364, 0.0787)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.1568), CFrame.new(-1.4934, 1.1883, 0.5717, -0.4406, 0.6124, 0.6565, -0.466, 0.469, -0.7502, -0.7673, -0.6364, 0.0787)},
	{"Cristaux", "glace3", "Coin", Vector3.new(0.0216, 0.1654, 0.0711), CFrame.new(-1.4186, 1.1028, 0.5807, 0.4406, 0.6124, -0.6565, 0.466, 0.469, 0.7502, 0.7673, -0.6364, -0.0787)},
	{"Liseré", "argent", "Bloc", Vector3.new(0.06, 0.9991, 0.05), CFrame.new(-0.4958, -0.8104, -0.7361, -0.0194, -0.9903, -0.1378, -0.9903, 0, 0.1392, -0.1378, 0.1392, -0.9806)},
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
	modele.Name = "PlastronGivrite"
	modele:SetAttribute("NomAffiche", "Plastron de givrite")

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
			l.Color = Color3.fromRGB(150, 210, 255)
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
	Nom = "Plastron de givrite",
	Format = "Code",
	Taille = Vector3.new(4.2902, 2.7108, 1.6983),
	Centre = Vector3.new(-0.0008, 0.1193, -0.0808), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
