-- Généré par blender/armes/armures_minerais.py (81 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de néantite : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresNeantite.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["neant"] = {"SmoothPlastic", 52, 38, 60, 0.1},
	["neant2"] = {"SmoothPlastic", 40, 30, 48, 0.1},
	["neant3"] = {"SmoothPlastic", 74, 58, 84, 0.1},
	["neantite"] = {"SmoothPlastic", 220, 60, 240, 0.15},
	["neantite2"] = {"SmoothPlastic", 180, 40, 210, 0.15},
	["veine"] = {"Neon", 210, 50, 240, 0},
	["cuir"] = {"Fabric", 34, 24, 40, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9997, -0.0058, 0.0247, 0.0066, 0.9995, -0.0303, -0.0246, 0.0304, 0.9992), "JambeD"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, -0.0336, 0.0501, 0.9982, 0.0201, 0.9986, -0.0494, -0.9992, 0.0185, -0.0346), "JambeD"},
	{"Genouillere", "neant3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "neant2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9983, 0.0383, 0.0436, -0.0402, 0.9982, 0.0436, -0.0419, -0.0452, 0.9981), "JambeD"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9989, -0.0331, 0.0338, 0.0305, 0.9969, 0.0732, -0.0361, -0.0721, 0.9967), "JambeD"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0262, -0.0471, 0.9985, -0.045, 0.9978, 0.0482, -0.9986, -0.0462, 0.024), "JambeD"},
	{"Mollet", "neant", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9976, 0.0482, 0.0503, -0.0439, 0.9955, -0.0838, -0.0541, 0.0814, 0.9952), "JambeD"},
	{"Cheville", "neant3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cristaux", "neantite", "Bloc", Vector3.new(0.2, 0.242, 0.2), CFrame.new(0.5, 0.1911, -0.7797, 0.7071, 0, 0.7071, -0.4656, 0.7526, 0.4656, -0.5322, -0.6585, 0.5322), "JambeD", "lumiere"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(0.5631, 0.2365, -0.9033, -0.6312, 0.7756, 0, 0.0764, 0.0621, 0.9951, 0.7719, 0.6281, -0.0984), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(0.5631, 0.3575, -0.9153, 0.6312, 0.7756, 0, -0.0764, 0.0621, -0.9951, -0.7719, 0.6281, 0.0984), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(0.4369, 0.2365, -0.9033, 0.6312, 0.5136, 0.5812, 0.0764, -0.7868, 0.6124, 0.7719, -0.3422, -0.5359), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(0.5076, 0.311, -0.9685, -0.6312, 0.5136, -0.5812, -0.0764, -0.7868, -0.6124, -0.7719, -0.3422, 0.5359), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(0.4369, 0.3196, -0.8083, 0.6312, -0.7756, 0, -0.7549, -0.6143, 0.2297, -0.1781, -0.145, -0.9733), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(0.4369, 0.3476, -0.9267, -0.6312, -0.7756, 0, 0.7549, -0.6143, -0.2297, 0.1781, -0.145, 0.9733), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(0.5631, 0.3476, -0.9267, -0.6312, 0.7756, 0, -0.7549, -0.6143, -0.2297, -0.1781, -0.145, 0.9733), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(0.5631, 0.3196, -0.8083, 0.6312, 0.7756, 0, 0.7549, -0.6143, 0.2297, 0.1781, -0.145, -0.9733), "JambeD"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(1.2293, 0.3557, -0.05, 0.3714, 0.9285, 0, -0.9285, 0.3714, 0, 0, 0, 1), "JambeD"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(1.2293, 0.3557, 0.05, -0.3714, 0.9285, 0, 0.9285, 0.3714, 0, 0, 0, -1), "JambeD"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(1.2293, -0.1943, -0.05, 0.3714, 0.9285, 0, -0.9285, 0.3714, 0, 0, 0, 1), "JambeD"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(1.2293, -0.1943, 0.05, -0.3714, 0.9285, 0, 0.9285, 0.3714, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.34, 0.03), CFrame.new(0.35, 0.55, -0.645, -0.9063, -0.4226, 0, -0.4226, 0.9063, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.187, 0.03), CFrame.new(0.2291, 0.6437, -0.645, -0.9659, 0.2588, 0, 0.2588, 0.9659, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(0.7, -0.45, -0.645, -0.866, 0.5, 0, 0.5, 0.866, 0, 0, 0, -1), "JambeD"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(0.6994, -0.3111, -0.645, -0.342, 0.9397, 0, 0.9397, 0.342, 0, 0, 0, -1), "JambeD"},
	{"Cristaux", "neantite2", "Bloc", Vector3.new(0.16, 0.198, 0.16), CFrame.new(1.1393, 0.6693, 0.1639, 0.57, 0.7001, 0.43, -0.43, 0.7001, -0.57, -0.7001, 0.14, 0.7001), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(1.2463, 0.705, 0.1271, -0.8211, 0.2412, 0.5173, 0.0755, -0.8525, 0.5173, 0.5658, 0.4638, 0.6817), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(1.2975, 0.7561, 0.1945, 0.8211, 0.2412, -0.5173, -0.0755, -0.8525, -0.5173, -0.5658, 0.4638, -0.6817), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(1.175, 0.7763, 0.1271, 0.0755, 0.19, 0.9789, -0.8211, -0.5451, 0.1691, 0.5658, -0.8165, 0.1148), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(1.2717, 0.7931, 0.1385, -0.0755, 0.19, -0.9789, 0.8211, -0.5451, -0.1691, -0.5658, -0.8165, -0.1148), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(1.2617, 0.7831, 0.2385, 0.2011, 0.0368, -0.9789, -0.6955, -0.6983, -0.1691, -0.6898, 0.7149, -0.1148), "JambeD"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(1.165, 0.7663, 0.2271, -0.2011, 0.0368, 0.9789, 0.6955, -0.6983, 0.1691, 0.6898, 0.7149, 0.1148), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(1.2987, 0.7573, 0.1824, -0.6955, 0.3441, -0.6307, 0.2011, -0.7495, -0.6307, -0.6898, -0.5655, 0.4521), "JambeD"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(1.2363, 0.695, 0.2271, 0.6955, 0.3441, 0.6307, -0.2011, -0.7495, 0.6307, 0.6898, -0.5655, -0.4521), "JambeD"},
	{"Liseré", "veine", "Bloc", Vector3.new(0.9, 0.04, 0.04), CFrame.new(0.5, 0.86, -0.655, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Liseré", "veine", "Bloc", Vector3.new(0.98, 0.04, 0.04), CFrame.new(0.52, -0.84, -0.58, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9997, 0.0058, -0.0247, -0.0066, 0.9995, -0.0303, 0.0246, 0.0304, 0.9992), "JambeG"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "neant3", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, -0.0336, -0.0501, -0.9982, -0.0201, 0.9986, -0.0494, 0.9992, 0.0185, -0.0346), "JambeG"},
	{"Genouillere", "neant3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "neant2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9983, -0.0383, -0.0436, 0.0402, 0.9982, 0.0436, 0.0419, -0.0452, 0.9981), "JambeG"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9989, 0.0331, -0.0338, -0.0305, 0.9969, 0.0732, 0.0361, -0.0721, 0.9967), "JambeG"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "neant3", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0262, 0.0471, -0.9985, 0.045, 0.9978, 0.0482, 0.9986, -0.0462, 0.024), "JambeG"},
	{"Mollet", "neant", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9976, -0.0482, -0.0503, 0.0439, 0.9955, -0.0838, 0.0541, 0.0814, 0.9952), "JambeG"},
	{"Cheville", "neant3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cristaux", "neantite", "Bloc", Vector3.new(0.2, 0.242, 0.2), CFrame.new(-0.5, 0.1911, -0.7797, 0.7071, 0, -0.7071, 0.4656, 0.7526, 0.4656, 0.5322, -0.6585, 0.5322), "JambeG", "lumiere"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(-0.5631, 0.2365, -0.9033, -0.6312, -0.7756, 0, -0.0764, 0.0621, 0.9951, -0.7719, 0.6281, -0.0984), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(-0.5631, 0.3575, -0.9153, 0.6312, -0.7756, 0, 0.0764, 0.0621, -0.9951, 0.7719, 0.6281, 0.0984), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(-0.4369, 0.2365, -0.9033, 0.6312, -0.5136, -0.5812, -0.0764, -0.7868, 0.6124, -0.7719, -0.3422, -0.5359), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(-0.5076, 0.311, -0.9685, -0.6312, -0.5136, 0.5812, 0.0764, -0.7868, -0.6124, 0.7719, -0.3422, 0.5359), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(-0.4369, 0.3196, -0.8083, 0.6312, 0.7756, 0, 0.7549, -0.6143, 0.2297, 0.1781, -0.145, -0.9733), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(-0.4369, 0.3476, -0.9267, -0.6312, 0.7756, 0, -0.7549, -0.6143, -0.2297, -0.1781, -0.145, 0.9733), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.1611), CFrame.new(-0.5631, 0.3476, -0.9267, -0.6312, -0.7756, 0, 0.7549, -0.6143, -0.2297, 0.1781, -0.145, 0.9733), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.024, 0.1823, 0.0822), CFrame.new(-0.5631, 0.3196, -0.8083, 0.6312, -0.7756, 0, -0.7549, -0.6143, 0.2297, -0.1781, -0.145, -0.9733), "JambeG"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(-1.2293, 0.3557, -0.05, 0.3714, -0.9285, 0, 0.9285, 0.3714, 0, 0, 0, 1), "JambeG"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(-1.2293, 0.3557, 0.05, -0.3714, -0.9285, 0, -0.9285, 0.3714, 0, 0, 0, -1), "JambeG"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(-1.2293, -0.1943, -0.05, 0.3714, -0.9285, 0, 0.9285, 0.3714, 0, 0, 0, 1), "JambeG"},
	{"Pointes", "neant3", "Coin", Vector3.new(0.06, 0.3, 0.1), CFrame.new(-1.2293, -0.1943, 0.05, -0.3714, -0.9285, 0, -0.9285, 0.3714, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.34, 0.03), CFrame.new(-0.35, 0.55, -0.645, -0.9063, 0.4226, 0, 0.4226, 0.9063, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.187, 0.03), CFrame.new(-0.2291, 0.6437, -0.645, -0.9659, -0.2588, 0, -0.2588, 0.9659, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-0.7, -0.45, -0.645, -0.866, -0.5, 0, -0.5, 0.866, 0, 0, 0, -1), "JambeG"},
	{"Veines", "veine", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-0.6994, -0.3111, -0.645, -0.342, -0.9397, 0, -0.9397, 0.342, 0, 0, 0, -1), "JambeG"},
	{"Cristaux", "neantite2", "Bloc", Vector3.new(0.16, 0.198, 0.16), CFrame.new(-1.1393, 0.6693, 0.1639, 0.57, -0.7001, -0.43, 0.43, 0.7001, -0.57, 0.7001, 0.14, 0.7001), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(-1.2463, 0.705, 0.1271, -0.8211, -0.2412, -0.5173, -0.0755, -0.8525, 0.5173, -0.5658, 0.4638, 0.6817), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(-1.2975, 0.7561, 0.1945, 0.8211, -0.2412, 0.5173, 0.0755, -0.8525, -0.5173, 0.5658, 0.4638, -0.6817), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(-1.175, 0.7763, 0.1271, 0.0755, -0.19, -0.9789, 0.8211, -0.5451, 0.1691, -0.5658, -0.8165, 0.1148), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(-1.2717, 0.7931, 0.1385, -0.0755, -0.19, 0.9789, -0.8211, -0.5451, -0.1691, 0.5658, -0.8165, -0.1148), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(-1.2617, 0.7831, 0.2385, 0.2011, -0.0368, 0.9789, 0.6955, -0.6983, -0.1691, 0.6898, 0.7149, -0.1148), "JambeG"},
	{"Cristaux", "neantite2", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(-1.165, 0.7663, 0.2271, -0.2011, -0.0368, -0.9789, -0.6955, -0.6983, 0.1691, -0.6898, 0.7149, 0.1148), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.1328), CFrame.new(-1.2987, 0.7573, 0.1824, -0.6955, -0.3441, 0.6307, -0.2011, -0.7495, -0.6307, 0.6898, -0.5655, 0.4521), "JambeG"},
	{"Cristaux", "neantite", "Coin", Vector3.new(0.0192, 0.1463, 0.0648), CFrame.new(-1.2363, 0.695, 0.2271, 0.6955, -0.3441, -0.6307, 0.2011, -0.7495, 0.6307, -0.6898, -0.5655, -0.4521), "JambeG"},
	{"Liseré", "veine", "Bloc", Vector3.new(0.9, 0.04, 0.04), CFrame.new(-0.5, 0.86, -0.655, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Liseré", "veine", "Bloc", Vector3.new(0.98, 0.04, 0.04), CFrame.new(-0.52, -0.84, -0.58, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
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
	modele.Name = "JambieresNeantite"
	modele:SetAttribute("NomAffiche", "Jambières de néantite")

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
		if marque == "lumiere" and not lumieres[cleLumiere] then
			lumieres[cleLumiere] = true
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(230, 60, 255)
			l.Range = 3
			l.Brightness = 0.5
			l.Shadows = false
			l.Parent = p
		end
		p.Parent = groupes[groupe]
		souder(centres[groupe], p)
	end
	return modele
end

return {
	Nom = "Jambières de néantite",
	Format = "Code",
	Taille = Vector3.new(2.7594, 1.99, 1.6888),
	Centre = Vector3.new(0, 0.005, -0.1496), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
