-- Généré par blender/armes/armures_minerais.py (99 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de rubis : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronRubis.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["grenat"] = {"SmoothPlastic", 96, 40, 52, 0.08},
	["grenat2"] = {"SmoothPlastic", 78, 32, 44, 0.08},
	["bronze"] = {"Metal", 130, 96, 84, 0.08},
	["rubis"] = {"SmoothPlastic", 210, 34, 76, 0.15},
	["rubis2"] = {"SmoothPlastic", 172, 24, 60, 0.15},
	["gemme"] = {"Neon", 255, 50, 100, 0},
	["gemme2"] = {"Neon", 255, 140, 170, 0},
	["cuir"] = {"Fabric", 92, 56, 38, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "grenat", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.974, 0.0236, -0.2253, -0.0194, 0.9996, 0.0208, 0.2257, -0.0158, 0.9741)},
	{"Liseré", "bronze", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "grenat2", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9811, 0.0297, 0.1913, -0.0244, 0.9993, -0.03, -0.1921, 0.0247, 0.9811)},
	{"Liseré", "bronze", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "bronze", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "grenat2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9921, -0.0221, -0.1234, 0.0071, 0.9926, -0.1211, 0.1251, 0.1192, 0.985)},
	{"Lames", "grenat", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9895, 0.0476, 0.1362, -0.0297, 0.991, -0.1303, -0.1411, 0.1249, 0.9821)},
	{"Lames", "grenat2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9863, -0.0407, -0.1599, 0.017, 0.989, -0.1468, 0.1641, 0.142, 0.9762)},
	{"Lames", "grenat2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9925, 0.0139, 0.1217, 0.0057, 0.9873, -0.1588, -0.1224, 0.1583, 0.9798)},
	{"Lames", "grenat", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9921, -0.0388, -0.1194, 0.0243, 0.9924, -0.1203, 0.1232, 0.1164, 0.9855)},
	{"Lames", "grenat2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9898, -0.0103, 0.1422, 0.0331, 0.9868, -0.1588, -0.1387, 0.1619, 0.977)},
	{"Flanc", "grenat2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, 0.0102, 0.0288, 0.9995, 0.0003, 0.9996, -0.0288, -0.9999, 0.0006, 0.0101)},
	{"Flanc", "grenat2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.013, -0.0279, -0.9995, -0.0261, 0.9993, -0.0282, 0.9996, 0.0265, 0.0122)},
	{"Dossiere", "grenat", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -0.9995, 0.0109, -0.03, 0.0104, 0.9998, 0.0161, 0.0301, 0.0158, -0.9994)},
	{"Dossiere", "bronze", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "grenat2", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 1, 0.0034, 0.0042, -0.004, 0.9873, 0.1587, -0.0036, -0.1587, 0.9873)},
	{"Dossiere", "grenat", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9993, -0.0328, -0.0173, 0.0346, 0.9926, 0.1167, 0.0133, -0.1172, 0.993)},
	{"Dossiere", "grenat2", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9997, 0.0233, -0.0109, -0.0218, 0.9927, 0.1188, 0.0135, -0.1186, 0.9929)},
	{"Col", "bronze", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "bronze", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "bronze", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "bronze", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "grenat", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9891, 0.1468, 0.0127, -0.1466, 0.9891, -0.01, -0.014, 0.008, 0.9999)},
	{"Epauliere", "grenat2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8744, 0.4851, -0.0083, -0.4848, 0.8743, 0.0237, 0.0188, -0.0167, 0.9997)},
	{"Epauliere", "bronze", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "grenat2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9842, 0.173, 0.0368, -0.174, 0.9844, 0.0247, -0.032, -0.0307, 0.999)},
	{"Epauliere", "grenat2", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9849, -0.1728, -0.0097, 0.1727, 0.9848, -0.0174, 0.0126, 0.0155, 0.9998)},
	{"Epauliere", "grenat2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8777, -0.4792, -0.0003, 0.4789, 0.8771, -0.0376, 0.0183, 0.0329, 0.9993)},
	{"Epauliere", "bronze", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "grenat2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9927, -0.1206, 0.0033, 0.1206, 0.9923, -0.0286, 0.0002, 0.0288, 0.9996)},
	{"Ceinture", "bronze", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "rubis", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "grenat2", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 0.9998, -0.0204, -0.003, 0.0199, 0.9924, -0.1212, 0.0054, 0.1211, 0.9926)},
	{"Tassette", "bronze", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "grenat2", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9992, -0.0267, 0.0287, 0.0296, 0.9941, -0.1048, -0.0257, 0.1056, 0.9941)},
	{"Tassette", "bronze", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Gemme", "bronze", "Coin", Vector3.new(0.07, 0.3245, 0.2602), CFrame.new(0.09, 0.5875, -0.825, 0, 0.9015, -0.4327, 0, -0.4327, -0.9015, -1, 0, 0)},
	{"Gemme", "bronze", "Coin", Vector3.new(0.07, 0.3245, 0.1558), CFrame.new(0, 0.4, -0.825, 0, 0.9015, 0.4327, 0, -0.4327, 0.9015, 1, 0, 0)},
	{"Gemme", "bronze", "Coin", Vector3.new(0.07, 0.3245, 0.2602), CFrame.new(0.09, 0.2125, -0.825, 0, 0.9015, -0.4327, 0, 0.4327, 0.9015, 1, 0, 0)},
	{"Gemme", "bronze", "Coin", Vector3.new(0.07, 0.3245, 0.1558), CFrame.new(0, 0.4, -0.825, 0, 0.9015, 0.4327, 0, 0.4327, -0.9015, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.143, 0.2859), CFrame.new(0.0075, 0.5518, -0.8964, -0.5029, 0.773, -0.3867, 0.2109, -0.3242, -0.9222, -0.8382, -0.5454, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.143, 0.0503), CFrame.new(-0.0575, 0.3968, -0.8964, 0.5029, 0.773, 0.3867, -0.2109, -0.3242, 0.9222, 0.8382, -0.5454, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.143, 0.0503), CFrame.new(-0.0575, 0.4032, -0.8964, -0.5029, 0.773, 0.3867, -0.2109, 0.3242, -0.9222, -0.8382, -0.5454, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.143, 0.2859), CFrame.new(0.0075, 0.2482, -0.8964, 0.5029, 0.773, -0.3867, 0.2109, 0.3242, 0.9222, 0.8382, -0.5454, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.143, 0.2859), CFrame.new(-0.0075, 0.2482, -0.8964, 0.5029, -0.773, 0.3867, -0.2109, 0.3242, 0.9222, -0.8382, -0.5454, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.143, 0.0503), CFrame.new(0.0575, 0.4032, -0.8964, -0.5029, -0.773, -0.3867, 0.2109, 0.3242, -0.9222, 0.8382, -0.5454, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.143, 0.0503), CFrame.new(0.0575, 0.3968, -0.8964, 0.5029, -0.773, -0.3867, 0.2109, -0.3242, 0.9222, -0.8382, -0.5454, 0)},
	{"Gemme", "gemme2", "Coin", Vector3.new(0.03, 0.143, 0.2859), CFrame.new(-0.0075, 0.5518, -0.8964, -0.5029, -0.773, 0.3867, -0.2109, -0.3242, -0.9222, 0.8382, -0.5454, 0)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.3079, -0.1818, -0.7014, 0.9911, -0.0324, -0.1294, -0.0058, 0.9585, -0.285, 0.1333, 0.2832, 0.9498)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.7279, -0.1818, -0.6424, 0.9867, -0.0492, -0.1547, 0.0004, 0.9536, -0.3012, 0.1623, 0.2971, 0.9409)},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.5079, -0.4218, -0.6933, 0.9952, -0.0227, -0.095, -0.0034, 0.964, -0.2661, 0.0976, 0.2651, 0.9593)},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.9079, -0.4218, -0.6371, 0.9925, -0.0571, -0.1077, 0.0262, 0.9629, -0.2685, 0.119, 0.2636, 0.9572)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.3079, -0.6618, -0.7414, 0.9955, -0.0152, -0.0931, -0.0102, 0.9638, -0.2666, 0.0938, 0.2663, 0.9593)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(0.7279, -0.6618, -0.6824, 0.9957, -0.0337, -0.0863, 0.0086, 0.9612, -0.2758, 0.0922, 0.2739, 0.9573)},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.24, 0.308, 0.24), CFrame.new(1.1541, 1.0923, -0.2219, 0.612, 0.6577, 0.4392, -0.377, 0.7308, -0.5691, -0.6952, 0.1827, 0.6952)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(1.3184, 1.16, -0.2703, -0.8353, 0.2728, 0.4773, 0.0262, -0.8474, 0.5303, 0.5491, 0.4555, 0.7007)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(1.3909, 1.2405, -0.1638, 0.8353, 0.2728, -0.4773, -0.0262, -0.8474, -0.5303, -0.5491, 0.4555, -0.7007)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(1.2766, 1.3434, -0.1638, 0.1137, -0.8714, -0.4773, -0.828, 0.1824, -0.5303, 0.5491, 0.4555, -0.7007)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(1.2041, 1.2628, -0.2703, -0.1137, -0.8714, 0.4773, 0.828, 0.1824, 0.5303, -0.5491, 0.4555, 0.7007)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(1.1853, 1.2419, -0.1191, 0.2698, -0.7419, 0.6138, -0.6546, 0.3262, 0.682, -0.7062, -0.5858, -0.3976)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(1.2785, 1.3455, -0.1795, -0.2698, -0.7419, -0.6138, 0.6546, 0.3262, -0.682, 0.7062, -0.5858, 0.3976)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(1.2996, 1.1391, -0.1191, -0.6793, -0.7222, 0.1303, 0.1996, -0.0109, 0.9798, -0.7062, 0.6916, 0.1515)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(1.3194, 1.2879, -0.0961, 0.6793, -0.7222, -0.1303, -0.1996, -0.0109, -0.9798, 0.7062, 0.6916, -0.1515)},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.24, 0.253, 0.24), CFrame.new(1.334, 1.0444, 0.2231, 0.612, 0.6577, 0.4392, -0.377, 0.7308, -0.5691, -0.6952, 0.1827, 0.6952)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(1.4799, 1.0911, 0.1692, -0.8593, 0.2751, 0.4311, -0.0403, -0.8769, 0.479, 0.5098, 0.3943, 0.7646)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(1.5376, 1.1552, 0.2715, 0.8593, 0.2751, -0.4311, 0.0403, -0.8769, -0.479, -0.5098, 0.3943, -0.7646)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(1.4229, 1.2585, 0.2715, 0.0501, -0.9009, -0.4311, -0.8588, 0.1815, -0.479, 0.5098, 0.3943, -0.7646)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(1.3652, 1.1944, 0.1692, -0.0501, -0.9009, 0.4311, 0.8588, 0.1815, 0.479, -0.5098, 0.3943, 0.7646)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(1.4774, 1.1923, 0.3399, 0.1996, -0.0001, -0.9799, -0.6927, -0.7073, -0.141, -0.6931, 0.7069, -0.1413)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(1.3463, 1.1734, 0.321, -0.1996, -0.0001, 0.9799, 0.6927, -0.7073, 0.141, 0.6931, 0.7069, 0.1413)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(1.5395, 1.1573, 0.2565, -0.7098, 0.3907, -0.5861, 0.1258, -0.7484, -0.6512, -0.6931, -0.536, 0.482)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(1.4611, 1.0701, 0.321, 0.7098, 0.3907, 0.5861, -0.1258, -0.7484, 0.6512, 0.6931, -0.536, -0.482)},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.3079, -0.1818, -0.7014, 0.9946, 0.0319, 0.0988, 0.0005, 0.9501, -0.3118, -0.1038, 0.3102, 0.945)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.7279, -0.1818, -0.6424, 0.9908, 0.0947, 0.0961, -0.0578, 0.9415, -0.332, -0.122, 0.3234, 0.9384)},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.5079, -0.4218, -0.6933, 0.9947, 0.0465, 0.0917, -0.0154, 0.9491, -0.3147, -0.1017, 0.3116, 0.9448)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.9079, -0.4218, -0.6371, 0.9956, 0.0408, 0.0842, -0.0103, 0.9421, -0.3351, -0.093, 0.3328, 0.9384)},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.3079, -0.6618, -0.7414, 0.9807, 0.0734, 0.1815, -0.0164, 0.9545, -0.2977, -0.1951, 0.2889, 0.9373)},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.36, 0.26, 0.06), CFrame.new(-0.7279, -0.6618, -0.6824, 0.9923, 0.0594, 0.109, -0.0212, 0.9461, -0.3232, -0.1223, 0.3184, 0.94)},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.24, 0.308, 0.24), CFrame.new(-1.1541, 1.0923, -0.2219, 0.4392, -0.6577, 0.612, 0.5691, 0.7308, 0.377, -0.6952, 0.1827, 0.6952)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(-1.2041, 1.2628, -0.2703, -0.1137, 0.8714, -0.4773, -0.828, 0.1824, 0.5303, 0.5491, 0.4555, 0.7007)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(-1.2766, 1.3434, -0.1638, 0.1137, 0.8714, 0.4773, 0.828, 0.1824, -0.5303, -0.5491, 0.4555, -0.7007)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(-1.3909, 1.2405, -0.1638, 0.8353, -0.2728, 0.4773, 0.0262, -0.8474, -0.5303, 0.5491, 0.4555, -0.7007)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(-1.3184, 1.16, -0.2703, -0.8353, -0.2728, -0.4773, -0.0262, -0.8474, 0.5303, -0.5491, 0.4555, 0.7007)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(-1.3194, 1.2879, -0.0961, 0.6793, 0.7222, 0.1303, 0.1996, -0.0109, -0.9798, -0.7062, 0.6916, -0.1515)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(-1.2996, 1.1391, -0.1191, -0.6793, 0.7222, -0.1303, -0.1996, -0.0109, 0.9798, 0.7062, 0.6916, 0.1515)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.0948), CFrame.new(-1.1853, 1.2419, -0.1191, -0.2698, -0.065, -0.9607, -0.6546, -0.7194, 0.2325, -0.7062, 0.6916, 0.1515)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2205, 0.209), CFrame.new(-1.3312, 1.2773, -0.0961, 0.2698, -0.065, 0.9607, 0.6546, -0.7194, -0.2325, 0.7062, 0.6916, -0.1515)},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.24, 0.253, 0.24), CFrame.new(-1.334, 1.0444, 0.2231, 0.4392, -0.6577, 0.612, 0.5691, 0.7308, 0.377, -0.6952, 0.1827, 0.6952)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(-1.4963, 1.2133, 0.1881, -0.0501, -0.1932, 0.9799, -0.8588, -0.4925, -0.141, 0.5098, -0.8486, -0.1413)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(-1.3652, 1.1944, 0.1692, 0.0501, -0.1932, -0.9799, 0.8588, -0.4925, 0.141, -0.5098, -0.8486, 0.1413)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(-1.5376, 1.1552, 0.2715, 0.8593, -0.2751, 0.4311, -0.0403, -0.8769, -0.479, 0.5098, 0.3943, -0.7646)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(-1.4799, 1.0911, 0.1692, -0.8593, -0.2751, -0.4311, 0.0403, -0.8769, 0.479, -0.5098, 0.3943, 0.7646)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(-1.4611, 1.0701, 0.321, 0.7098, -0.3907, -0.5861, 0.1258, -0.7484, 0.6512, -0.6931, -0.536, -0.482)},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(-1.5395, 1.1573, 0.2565, -0.7098, -0.3907, 0.5861, -0.1258, -0.7484, -0.6512, 0.6931, -0.536, 0.482)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1076), CFrame.new(-1.3463, 1.1734, 0.321, -0.1996, 0.0001, -0.9799, -0.6927, -0.7073, 0.141, -0.6931, 0.7069, 0.1413)},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.025, 0.2145, 0.1601), CFrame.new(-1.4774, 1.1923, 0.3399, 0.1996, 0.0001, 0.9799, 0.6927, -0.7073, -0.141, 0.6931, 0.7069, -0.1413)},
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
	modele.Name = "PlastronRubis"
	modele:SetAttribute("NomAffiche", "Plastron de rubis")

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
			l.Color = Color3.fromRGB(255, 50, 90)
			l.Range = 5
			l.Brightness = 0.9
			l.Shadows = false
			l.Parent = p
		end
		p.Parent = modele
		souder(racine, p)
	end
	return modele
end

return {
	Nom = "Plastron de rubis",
	Format = "Code",
	Taille = Vector3.new(4.3256, 2.6301, 1.7163),
	Centre = Vector3.new(0.015, 0.079, -0.0898), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
