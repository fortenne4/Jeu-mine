-- Généré par blender/armes/armures_minerais.py (111 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron d'émeraude : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronEmeraude.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["roche"] = {"Slate", 74, 68, 74, 0},
	["roche2"] = {"Slate", 58, 54, 60, 0},
	["roche3"] = {"Slate", 92, 86, 90, 0},
	["cadre"] = {"Metal", 94, 88, 92, 0.05},
	["emeraude"] = {"SmoothPlastic", 40, 190, 70, 0.15},
	["emeraude2"] = {"SmoothPlastic", 30, 150, 56, 0.15},
	["gemme"] = {"Neon", 60, 230, 100, 0},
	["cuir"] = {"Fabric", 66, 66, 44, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "roche2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.975, -0.0077, -0.2222, 0.0136, 0.9996, 0.0249, 0.222, -0.0273, 0.9747)},
	{"Liseré", "cadre", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "roche2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9848, 0.0497, 0.1663, -0.0494, 0.9988, -0.0063, -0.1664, -0.002, 0.9861)},
	{"Liseré", "cadre", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "cadre", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "roche2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9869, -0.0094, -0.1614, -0.0186, 0.9852, -0.1707, 0.1606, 0.1714, 0.972)},
	{"Lames", "roche3", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9887, 0.0088, 0.1495, 0.0084, 0.9934, -0.1145, -0.1495, 0.1145, 0.9821)},
	{"Lames", "roche", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9941, -0.0525, -0.0944, 0.0392, 0.9898, -0.1368, 0.1006, 0.1322, 0.9861)},
	{"Lames", "roche2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9868, 0.0554, 0.1523, -0.0387, 0.9931, -0.1103, -0.1574, 0.1029, 0.9822)},
	{"Lames", "roche3", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.995, -0.0453, -0.0894, 0.0323, 0.9894, -0.1414, 0.0949, 0.1378, 0.9859)},
	{"Lames", "roche3", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9943, 0.0161, 0.1051, -0.0024, 0.9916, -0.129, -0.1063, 0.128, 0.9861)},
	{"Flanc", "roche2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, -0.0091, 0.0244, 0.9997, 0.0287, 0.9993, -0.0241, -0.9995, 0.0285, -0.0098)},
	{"Flanc", "roche2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0316, -0.0073, -0.9995, 0.0064, 1, -0.0071, 0.9995, -0.0062, 0.0317)},
	{"Dossiere", "roche", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.9982, -0.0482, -0.0347, -0.0484, 0.9988, 0.0047, 0.0345, 0.0063, -0.9994)},
	{"Dossiere", "cadre", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "roche2", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9983, -0.0469, 0.0335, 0.0402, 0.9832, 0.1779, -0.0413, -0.1762, 0.9835)},
	{"Dossiere", "roche3", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9992, -0.0282, -0.0286, 0.0323, 0.9877, 0.1529, 0.024, -0.1537, 0.9878)},
	{"Dossiere", "roche3", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9999, -0.0151, -0.002, 0.0153, 0.9921, 0.1243, 0.0001, -0.1243, 0.9922)},
	{"Col", "cadre", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "cadre", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "cadre", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "cadre", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "roche3", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9869, 0.161, -0.0107, -0.1611, 0.9868, -0.0131, 0.0084, 0.0147, 0.9999)},
	{"Epauliere", "roche3", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8613, 0.5073, -0.0292, -0.508, 0.8609, -0.0283, 0.0108, 0.0392, 0.9992)},
	{"Epauliere", "cadre", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "roche3", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9852, 0.1715, 0.0005, -0.1714, 0.9848, 0.0271, 0.0041, -0.0268, 0.9996)},
	{"Epauliere", "roche3", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9863, -0.1628, 0.027, 0.1625, 0.9866, 0.0139, -0.0289, -0.0093, 0.9995)},
	{"Epauliere", "roche3", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8917, -0.4506, 0.0431, 0.4511, 0.8925, -0.0002, -0.0384, 0.0196, 0.9991)},
	{"Epauliere", "cadre", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "roche", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9855, -0.1695, 0.0012, 0.1695, 0.9853, -0.0212, 0.0024, 0.0211, 0.9998)},
	{"Ceinture", "cadre", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "emeraude", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "roche3", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 0.9988, -0.0387, -0.0287, 0.0367, 0.9971, -0.066, 0.0311, 0.0649, 0.9974)},
	{"Tassette", "cadre", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "roche2", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9999, -0.0025, 0.0171, 0.0047, 0.9909, -0.1346, -0.0166, 0.1347, 0.9907)},
	{"Tassette", "cadre", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Gemme", "cadre", "Coin", Vector3.new(0.07, 0.2513, 0.1941), CFrame.new(0.07, 0.5625, -0.825, 0, 0.8976, -0.4409, 0, -0.4409, -0.8976, -1, 0, 0)},
	{"Gemme", "cadre", "Coin", Vector3.new(0.07, 0.2513, 0.1235), CFrame.new(0, 0.42, -0.825, 0, 0.8976, 0.4409, 0, -0.4409, 0.8976, 1, 0, 0)},
	{"Gemme", "cadre", "Coin", Vector3.new(0.07, 0.2513, 0.1941), CFrame.new(0.07, 0.2775, -0.825, 0, 0.8976, -0.4409, 0, 0.4409, 0.8976, 1, 0, 0)},
	{"Gemme", "cadre", "Coin", Vector3.new(0.07, 0.2513, 0.1235), CFrame.new(0, 0.42, -0.825, 0, 0.8976, 0.4409, 0, 0.4409, -0.8976, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.2036), CFrame.new(0.0076, 0.5269, -0.8844, -0.5035, 0.7766, -0.3786, 0.206, -0.3177, -0.9255, -0.8391, -0.544, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.0341), CFrame.new(-0.0374, 0.4169, -0.8844, 0.5035, 0.7766, 0.3786, -0.206, -0.3177, 0.9255, 0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.0341), CFrame.new(-0.0374, 0.4231, -0.8844, -0.5035, 0.7766, 0.3786, -0.206, 0.3177, -0.9255, -0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.2036), CFrame.new(0.0076, 0.3131, -0.8844, 0.5035, 0.7766, -0.3786, 0.206, 0.3177, 0.9255, 0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.2036), CFrame.new(-0.0076, 0.3131, -0.8844, 0.5035, -0.7766, 0.3786, -0.206, 0.3177, 0.9255, -0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.0341), CFrame.new(0.0374, 0.4231, -0.8844, -0.5035, -0.7766, -0.3786, 0.206, 0.3177, -0.9255, 0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.0341), CFrame.new(0.0374, 0.4169, -0.8844, 0.5035, -0.7766, -0.3786, 0.206, -0.3177, 0.9255, -0.8391, -0.544, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0993, 0.2036), CFrame.new(-0.0076, 0.5269, -0.8844, -0.5035, -0.7766, 0.3786, -0.206, -0.3177, -0.9255, 0.8391, -0.544, 0)},
	{"Incrustation", "emeraude", "Bloc", Vector3.new(0.48, 0.56, 0.06), CFrame.new(0.5683, 0.36, -0.6664, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Incrustation", "cadre", "Bloc", Vector3.new(0.06, 0.62, 0.08), CFrame.new(0.8324, 0.36, -0.6102, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Incrustation", "emeraude2", "Bloc", Vector3.new(0.5, 0.14, 0.06), CFrame.new(0.5555, -0.4444, -0.6694, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.24, 0.356, 0.24), CFrame.new(1.0958, 1.1517, -0.0672, 0.6694, 0.2414, 0.7026, -0.2377, 0.9656, -0.1053, -0.7038, -0.0966, 0.7038)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(1.1597, 1.4408, -0.1731, -0.7093, -0.6273, 0.3215, -0.1831, -0.2765, -0.9434, 0.6807, -0.7281, 0.0812)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(1.2102, 1.2927, -0.1603, 0.7093, -0.6273, -0.3215, 0.1831, -0.2765, 0.9434, -0.6807, -0.7281, -0.0812)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(1.0612, 1.33, -0.1603, 0.5397, 0.4234, 0.7277, -0.4954, -0.5391, 0.6811, 0.6807, -0.7281, -0.0812)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(1.1753, 1.4369, -0.1731, -0.5397, 0.4234, -0.7277, 0.4954, -0.5391, -0.6811, -0.6807, -0.7281, 0.0812)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(1.0648, 1.3444, -0.0074, 0.5095, -0.8391, 0.1904, -0.616, -0.2012, 0.7616, -0.6008, -0.5054, -0.6194)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(1.0946, 1.4639, -0.1046, -0.5095, -0.8391, -0.1904, 0.616, -0.2012, -0.7616, 0.6008, -0.5054, 0.6194)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(1.2138, 1.3071, -0.0074, -0.7395, -0.5914, -0.3215, -0.3037, -0.1331, 0.9434, -0.6008, 0.7953, -0.0812)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(1.1633, 1.4552, -0.0202, 0.7395, -0.5914, 0.3215, 0.3037, -0.1331, -0.9434, 0.6008, 0.7953, 0.0812)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.242, 0.18), CFrame.new(1.2602, 1.0571, -0.4393, 0.4883, 0.4867, 0.7244, -0.5605, 0.8111, -0.1671, -0.6689, -0.3244, 0.6689)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.3561, 1.1067, -0.5307, -0.6459, 0.5772, 0.4996, 0.1746, -0.5254, 0.8327, 0.7432, 0.6251, 0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.4149, 1.2047, -0.5026, 0.6459, 0.5772, -0.4996, -0.1746, -0.5254, -0.8327, -0.7432, 0.6251, -0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3177, 1.263, -0.5026, 0.4581, -0.7352, -0.4996, -0.4877, 0.262, -0.8327, 0.7432, 0.6251, -0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2588, 1.165, -0.5307, -0.4581, -0.7352, 0.4996, 0.4877, 0.262, 0.8327, -0.7432, 0.6251, 0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3805, 1.2441, -0.4556, 0.2432, 0.4227, -0.8731, -0.8459, -0.348, -0.4041, -0.4746, 0.8368, 0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2778, 1.1965, -0.4234, -0.2432, 0.4227, 0.8731, 0.8459, -0.348, 0.4041, 0.4746, 0.8368, -0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.375, 1.1382, -0.4234, -0.8608, -0.506, -0.0543, -0.1835, 0.2092, 0.9605, -0.4746, 0.8368, -0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3686, 1.2512, -0.4556, 0.8608, -0.506, 0.0543, 0.1835, 0.2092, -0.9605, 0.4746, 0.8368, 0.2729)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.242, 0.18), CFrame.new(1.2602, 1.0571, 0.3893, 0.7244, 0.4867, 0.4883, -0.1671, 0.8111, -0.5605, -0.6689, 0.3244, 0.6689)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3686, 1.2512, 0.4056, -0.8608, -0.506, 0.0543, -0.1835, 0.2092, -0.9605, 0.4746, -0.8368, -0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.375, 1.1382, 0.3734, 0.8608, -0.506, -0.0543, 0.1835, 0.2092, 0.9605, -0.4746, -0.8368, 0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2778, 1.1965, 0.3734, 0.2432, 0.4227, 0.8731, -0.8459, -0.348, 0.4041, 0.4746, -0.8368, 0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3805, 1.2441, 0.4056, -0.2432, 0.4227, -0.8731, 0.8459, -0.348, -0.4041, -0.4746, -0.8368, -0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2588, 1.165, 0.4807, 0.4581, -0.7352, 0.4996, -0.4877, 0.262, 0.8327, -0.7432, -0.6251, -0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3177, 1.263, 0.4526, -0.4581, -0.7352, -0.4996, 0.4877, 0.262, -0.8327, 0.7432, -0.6251, 0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.4149, 1.2047, 0.4526, -0.6459, 0.5772, -0.4996, 0.1746, -0.5254, -0.8327, -0.7432, -0.6251, 0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.3561, 1.1067, 0.4807, 0.6459, 0.5772, 0.4996, -0.1746, -0.5254, 0.8327, 0.7432, -0.6251, -0.2386)},
	{"Incrustation", "emeraude", "Bloc", Vector3.new(0.48, 0.56, 0.06), CFrame.new(-0.5683, 0.36, -0.6664, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Incrustation", "cadre", "Bloc", Vector3.new(0.06, 0.62, 0.08), CFrame.new(-0.8324, 0.36, -0.6102, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Incrustation", "emeraude2", "Bloc", Vector3.new(0.5, 0.14, 0.06), CFrame.new(-0.5555, -0.4444, -0.6694, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.24, 0.356, 0.24), CFrame.new(-1.0958, 1.1517, -0.0672, 0.7026, -0.2414, 0.6694, 0.1053, 0.9656, 0.2377, -0.7038, -0.0966, 0.7038)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(-1.0612, 1.33, -0.1603, -0.5397, 0.8138, -0.2157, -0.4954, -0.0998, 0.8629, 0.6807, 0.5726, 0.457)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(-1.095, 1.4654, -0.0886, 0.5397, 0.8138, 0.2157, 0.4954, -0.0998, -0.8629, -0.6807, 0.5726, -0.457)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(-1.2102, 1.2927, -0.1603, 0.7093, 0.6273, 0.3215, -0.1831, -0.2765, 0.9434, 0.6807, -0.7281, -0.0812)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(-1.1597, 1.4408, -0.1731, -0.7093, 0.6273, -0.3215, 0.1831, -0.2765, -0.9434, -0.6807, -0.7281, 0.0812)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(-1.1633, 1.4552, -0.0202, 0.7395, 0.5914, -0.3215, -0.3037, -0.1331, -0.9434, -0.6008, 0.7953, 0.0812)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(-1.2138, 1.3071, -0.0074, -0.7395, 0.5914, 0.3215, 0.3037, -0.1331, 0.9434, 0.6008, 0.7953, -0.0812)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.2221), CFrame.new(-1.0946, 1.4639, -0.1046, -0.5095, 0.8391, 0.1904, -0.616, -0.2012, -0.7616, -0.6008, -0.5054, 0.6194)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.025, 0.2218, 0.0918), CFrame.new(-1.0648, 1.3444, -0.0074, 0.5095, 0.8391, -0.1904, 0.616, -0.2012, 0.7616, 0.6008, -0.5054, -0.6194)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.242, 0.18), CFrame.new(-1.2602, 1.0571, -0.4393, 0.7244, -0.4867, 0.4883, 0.1671, 0.8111, 0.5605, -0.6689, -0.3244, 0.6689)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2588, 1.165, -0.5307, -0.4581, 0.7352, -0.4996, -0.4877, 0.262, 0.8327, 0.7432, 0.6251, 0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3177, 1.263, -0.5026, 0.4581, 0.7352, 0.4996, 0.4877, 0.262, -0.8327, -0.7432, 0.6251, -0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.4149, 1.2047, -0.5026, 0.6459, -0.5772, 0.4996, 0.1746, -0.5254, -0.8327, 0.7432, 0.6251, -0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.3561, 1.1067, -0.5307, -0.6459, -0.5772, -0.4996, -0.1746, -0.5254, 0.8327, -0.7432, 0.6251, 0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3686, 1.2512, -0.4556, 0.8608, 0.506, -0.0543, -0.1835, 0.2092, -0.9605, -0.4746, 0.8368, 0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.375, 1.1382, -0.4234, -0.8608, 0.506, 0.0543, 0.1835, 0.2092, 0.9605, 0.4746, 0.8368, -0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2778, 1.1965, -0.4234, -0.2432, -0.4227, -0.8731, -0.8459, -0.348, 0.4041, -0.4746, 0.8368, -0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3805, 1.2441, -0.4556, 0.2432, -0.4227, 0.8731, 0.8459, -0.348, -0.4041, 0.4746, 0.8368, 0.2729)},
	{"Cristaux", "emeraude", "Bloc", Vector3.new(0.18, 0.242, 0.18), CFrame.new(-1.2602, 1.0571, 0.3893, 0.4883, -0.4867, 0.7244, 0.5605, 0.8111, 0.1671, -0.6689, 0.3244, 0.6689)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3805, 1.2441, 0.4056, -0.2432, -0.4227, 0.8731, -0.8459, -0.348, -0.4041, 0.4746, -0.8368, -0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2778, 1.1965, 0.3734, 0.2432, -0.4227, -0.8731, 0.8459, -0.348, 0.4041, -0.4746, -0.8368, 0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.375, 1.1382, 0.3734, 0.8608, 0.506, 0.0543, -0.1835, 0.2092, 0.9605, 0.4746, -0.8368, 0.2729)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3686, 1.2512, 0.4056, -0.8608, 0.506, -0.0543, 0.1835, 0.2092, -0.9605, -0.4746, -0.8368, -0.2729)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.3561, 1.1067, 0.4807, 0.6459, -0.5772, -0.4996, 0.1746, -0.5254, 0.8327, -0.7432, -0.6251, -0.2386)},
	{"Cristaux", "emeraude", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.4149, 1.2047, 0.4526, -0.6459, -0.5772, 0.4996, -0.1746, -0.5254, -0.8327, 0.7432, -0.6251, 0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3177, 1.263, 0.4526, -0.4581, 0.7352, 0.4996, -0.4877, 0.262, -0.8327, -0.7432, -0.6251, 0.2386)},
	{"Cristaux", "emeraude2", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2588, 1.165, 0.4807, 0.4581, 0.7352, -0.4996, 0.4877, 0.262, 0.8327, 0.7432, -0.6251, -0.2386)},
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
	modele.Name = "PlastronEmeraude"
	modele:SetAttribute("NomAffiche", "Plastron d'émeraude")

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
			l.Color = Color3.fromRGB(60, 230, 110)
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
	Nom = "Plastron d'émeraude",
	Format = "Code",
	Taille = Vector3.new(4.3137, 2.8146, 1.6923),
	Centre = Vector3.new(0, 0.1712, -0.0778), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
