-- Généré par blender/armes/armures_minerais.py (85 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de diamant : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresDiamant.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["diamant"] = {"SmoothPlastic", 196, 204, 240, 0.2},
	["diamant2"] = {"SmoothPlastic", 168, 178, 230, 0.2},
	["diamant3"] = {"SmoothPlastic", 222, 228, 250, 0.25},
	["argent"] = {"Metal", 212, 206, 216, 0.15},
	["gemme"] = {"Neon", 170, 220, 255, 0},
	["cuir"] = {"Fabric", 96, 104, 130, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "diamant3", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9995, 0.0214, -0.0228, -0.0227, 0.9982, -0.0556, 0.0216, 0.0561, 0.9982), "JambeD"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "diamant2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0.0135, -0.0376, 0.9992, 0.0204, 0.9991, 0.0373, -0.9997, 0.0199, 0.0143), "JambeD"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "diamant2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9995, 0.0043, -0.0327, -0.0057, 0.999, -0.0448, 0.0324, 0.045, 0.9985), "JambeD"},
	{"Greve", "diamant2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9981, -0.0513, -0.0352, 0.0528, 0.9977, 0.0421, 0.033, -0.0439, 0.9985), "JambeD"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "diamant3", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, -0.0496, 0.0199, 0.9986, 0.0104, 0.9998, -0.0194, -0.9987, 0.0095, -0.0498), "JambeD"},
	{"Mollet", "diamant", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9985, 0.0321, 0.0445, -0.0316, 0.9994, -0.0106, -0.0448, 0.0091, 0.999), "JambeD"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(0.425, 0.1275, -0.705, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(0.575, 0.1275, -0.705, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(0.425, -0.0875, -0.705, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(0.575, -0.0875, -0.705, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(0.5073, 0.0901, -0.7678, -0.4867, 0.6749, -0.5547, 0.3244, -0.4499, -0.8321, -0.8111, -0.5849, 0), "JambeD", "lumiere"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(0.4573, 0.0151, -0.7678, 0.4867, 0.6749, 0.5547, -0.3244, -0.4499, 0.8321, 0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(0.4573, 0.0249, -0.7678, -0.4867, 0.6749, 0.5547, -0.3244, 0.4499, -0.8321, -0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(0.5073, -0.0501, -0.7678, 0.4867, 0.6749, -0.5547, 0.3244, 0.4499, 0.8321, 0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(0.4927, -0.0501, -0.7678, 0.4867, -0.6749, 0.5547, -0.3244, 0.4499, 0.8321, -0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(0.5427, 0.0249, -0.7678, -0.4867, -0.6749, -0.5547, 0.3244, 0.4499, -0.8321, 0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(0.5427, 0.0151, -0.7678, 0.4867, -0.6749, -0.5547, 0.3244, -0.4499, 0.8321, -0.8111, -0.5849, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(0.4927, 0.0901, -0.7678, -0.4867, -0.6749, 0.5547, -0.3244, -0.4499, -0.8321, 0.8111, -0.5849, 0), "JambeD"},
	{"Cristaux", "diamant", "Bloc", Vector3.new(0.18, 0.262, 0.18), CFrame.new(1.1517, 0.2117, -0.2683, 0.43, 0.7001, 0.57, -0.57, 0.7001, -0.43, -0.7001, -0.14, 0.7001), "JambeD"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.2991, 0.3689, -0.3561, -0.6812, -0.7024, -0.2066, 0.2292, 0.0634, -0.9713, 0.6953, -0.709, 0.1178), "JambeD"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2748, 0.2546, -0.3422, 0.6812, -0.7024, 0.2066, -0.2292, 0.0634, 0.9713, -0.6953, -0.709, -0.1178), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.1946, 0.3348, -0.3422, 0.2292, 0.0634, 0.9713, -0.6812, -0.7024, 0.2066, 0.6953, -0.709, -0.1178), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3089, 0.3591, -0.3561, -0.2292, 0.0634, -0.9713, 0.6812, -0.7024, -0.2066, -0.6953, -0.709, 0.1178), "JambeD"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.3202, 0.3703, -0.2438, 0.1017, 0.215, -0.9713, -0.8086, -0.5508, -0.2066, -0.5794, 0.8065, 0.1178), "JambeD"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.2058, 0.346, -0.2299, -0.1017, 0.215, 0.9713, 0.8086, -0.5508, 0.2066, 0.5794, 0.8065, -0.1178), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(1.349, 0.3288, -0.3068, -0.8086, 0.2438, -0.5354, 0.1017, -0.8384, -0.5354, -0.5794, -0.4874, 0.6532), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(1.286, 0.2658, -0.2299, 0.8086, 0.2438, 0.5354, -0.1017, -0.8384, 0.5354, 0.5794, -0.4874, -0.6532), "JambeD"},
	{"Cristaux", "diamant3", "Bloc", Vector3.new(0.18, 0.198, 0.18), CFrame.new(1.1422, -0.0307, 0.1747, 0.5149, 0.8305, 0.2127, -0.5157, 0.4983, -0.697, -0.6848, 0.2491, 0.6848), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(1.2961, 0.0694, 0.163, -0.8534, -0.3993, -0.3352, 0.2088, 0.3273, -0.9216, 0.4776, -0.8564, -0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(1.2616, -0.0255, 0.1429, 0.8534, -0.3993, 0.3352, -0.2088, 0.3273, 0.9216, -0.4776, -0.8564, 0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(1.2029, 0.0722, 0.1429, -0.2173, 0.1009, 0.9709, -0.8512, -0.5063, -0.138, 0.4776, -0.8564, 0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(1.3029, 0.058, 0.163, 0.2173, 0.1009, -0.9709, 0.8512, -0.5063, 0.138, -0.4776, -0.8564, -0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(1.2786, 0.0434, 0.2734, 0.0468, -0.235, -0.9709, -0.6928, -0.7078, 0.138, -0.7196, 0.6662, -0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(1.1786, 0.0576, 0.2532, -0.0468, -0.235, 0.9709, 0.6928, -0.7078, -0.138, 0.7196, 0.6662, 0.1959), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(1.3181, 0.0084, 0.2117, -0.5893, 0.1911, -0.785, 0.3673, -0.802, -0.471, -0.7196, -0.5659, 0.4024), "JambeD"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(1.2372, -0.0401, 0.2532, 0.5893, 0.1911, 0.785, -0.3673, -0.802, 0.471, 0.7196, -0.5659, -0.4024), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "diamant3", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9995, -0.0214, 0.0228, 0.0227, 0.9982, -0.0556, -0.0216, 0.0561, 0.9982), "JambeG"},
	{"Cuissard", "argent", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "diamant2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0.0135, 0.0376, -0.9992, -0.0204, 0.9991, 0.0373, 0.9997, 0.0199, 0.0143), "JambeG"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "diamant2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9995, -0.0043, 0.0327, 0.0057, 0.999, -0.0448, -0.0324, 0.045, 0.9985), "JambeG"},
	{"Greve", "diamant2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9981, 0.0513, 0.0352, -0.0528, 0.9977, 0.0421, -0.033, -0.0439, 0.9985), "JambeG"},
	{"Greve", "argent", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "diamant3", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, -0.0496, -0.0199, -0.9986, -0.0104, 0.9998, -0.0194, 0.9987, 0.0095, -0.0498), "JambeG"},
	{"Mollet", "diamant", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9985, -0.0321, -0.0445, 0.0316, 0.9994, -0.0106, 0.0448, 0.0091, 0.999), "JambeG"},
	{"Cheville", "argent", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(-0.425, 0.1275, -0.705, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(-0.575, 0.1275, -0.705, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(-0.425, -0.0875, -0.705, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "argent", "Coin", Vector3.new(0.07, 0.215, 0.15), CFrame.new(-0.575, -0.0875, -0.705, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(-0.5073, 0.0901, -0.7678, -0.4867, -0.6749, 0.5547, -0.3244, -0.4499, -0.8321, 0.8111, -0.5849, 0), "JambeG", "lumiere"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(-0.4573, 0.0151, -0.7678, 0.4867, -0.6749, -0.5547, 0.3244, -0.4499, 0.8321, -0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(-0.4573, 0.0249, -0.7678, -0.4867, -0.6749, -0.5547, 0.3244, 0.4499, -0.8321, 0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(-0.5073, -0.0501, -0.7678, 0.4867, -0.6749, 0.5547, -0.3244, 0.4499, 0.8321, -0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(-0.4927, -0.0501, -0.7678, 0.4867, 0.6749, -0.5547, 0.3244, 0.4499, 0.8321, 0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(-0.5427, 0.0249, -0.7678, -0.4867, 0.6749, 0.5547, -0.3244, 0.4499, -0.8321, -0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.0555), CFrame.new(-0.5427, 0.0151, -0.7678, 0.4867, 0.6749, 0.5547, -0.3244, -0.4499, 0.8321, 0.8111, -0.5849, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.1026, 0.1248), CFrame.new(-0.4927, 0.0901, -0.7678, -0.4867, 0.6749, -0.5547, 0.3244, -0.4499, -0.8321, -0.8111, -0.5849, 0), "JambeG"},
	{"Cristaux", "diamant", "Bloc", Vector3.new(0.18, 0.262, 0.18), CFrame.new(-1.1517, 0.2117, -0.2683, 0.43, -0.7001, -0.57, 0.57, 0.7001, -0.43, 0.7001, -0.14, 0.7001), "JambeG"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.2991, 0.3689, -0.3561, -0.6812, 0.7024, 0.2066, -0.2292, 0.0634, -0.9713, -0.6953, -0.709, 0.1178), "JambeG"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2748, 0.2546, -0.3422, 0.6812, 0.7024, -0.2066, 0.2292, 0.0634, 0.9713, 0.6953, -0.709, -0.1178), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.1946, 0.3348, -0.3422, 0.2292, -0.0634, -0.9713, 0.6812, -0.7024, 0.2066, -0.6953, -0.709, -0.1178), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3089, 0.3591, -0.3561, -0.2292, -0.0634, 0.9713, -0.6812, -0.7024, -0.2066, 0.6953, -0.709, 0.1178), "JambeG"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.3202, 0.3703, -0.2438, 0.1017, -0.215, 0.9713, 0.8086, -0.5508, -0.2066, 0.5794, 0.8065, 0.1178), "JambeG"},
	{"Cristaux", "diamant", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.2058, 0.346, -0.2299, -0.1017, -0.215, -0.9713, -0.8086, -0.5508, 0.2066, -0.5794, 0.8065, -0.1178), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.1666), CFrame.new(-1.349, 0.3288, -0.3068, -0.8086, -0.2438, 0.5354, -0.1017, -0.8384, -0.5354, 0.5794, -0.4874, 0.6532), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1663, 0.0688), CFrame.new(-1.286, 0.2658, -0.2299, 0.8086, -0.2438, -0.5354, 0.1017, -0.8384, 0.5354, -0.5794, -0.4874, -0.6532), "JambeG"},
	{"Cristaux", "diamant3", "Bloc", Vector3.new(0.18, 0.198, 0.18), CFrame.new(-1.1422, -0.0307, 0.1747, 0.5149, -0.8305, -0.2127, 0.5157, 0.4983, -0.697, 0.6848, 0.2491, 0.6848), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(-1.2961, 0.0694, 0.163, -0.8534, 0.3993, 0.3352, -0.2088, 0.3273, -0.9216, -0.4776, -0.8564, -0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(-1.2616, -0.0255, 0.1429, 0.8534, 0.3993, -0.3352, 0.2088, 0.3273, 0.9216, 0.4776, -0.8564, 0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(-1.2029, 0.0722, 0.1429, -0.2173, -0.1009, -0.9709, 0.8512, -0.5063, -0.138, -0.4776, -0.8564, 0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(-1.3029, 0.058, 0.163, 0.2173, -0.1009, 0.9709, -0.8512, -0.5063, 0.138, 0.4776, -0.8564, -0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(-1.2786, 0.0434, 0.2734, 0.0468, 0.235, 0.9709, 0.6928, -0.7078, 0.138, 0.7196, 0.6662, -0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(-1.1786, 0.0576, 0.2532, -0.0468, 0.235, -0.9709, -0.6928, -0.7078, -0.138, -0.7196, 0.6662, 0.1959), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.1274), CFrame.new(-1.3181, 0.0084, 0.2117, -0.5893, -0.1911, 0.785, -0.3673, -0.802, -0.471, 0.7196, -0.5659, 0.4024), "JambeG"},
	{"Cristaux", "diamant3", "Coin", Vector3.new(0.0216, 0.1619, 0.0786), CFrame.new(-1.2372, -0.0401, 0.2532, 0.5893, -0.1911, -0.785, 0.3673, -0.802, 0.471, -0.7196, -0.5659, -0.4024), "JambeG"},
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
	modele.Name = "JambieresDiamant"
	modele:SetAttribute("NomAffiche", "Jambières de diamant")

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
			l.Color = Color3.fromRGB(200, 230, 255)
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
	Nom = "Jambières de diamant",
	Format = "Code",
	Taille = Vector3.new(2.774, 1.99, 1.4739),
	Centre = Vector3.new(0, 0.005, -0.073), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
