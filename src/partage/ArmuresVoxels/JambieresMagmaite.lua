-- Généré par blender/armes/armures_minerais.py (81 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de magmaïte : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresMagmaite.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["basalte"] = {"Basalt", 66, 58, 60, 0},
	["basalte2"] = {"Basalt", 84, 74, 76, 0},
	["basalte3"] = {"Basalt", 50, 44, 48, 0},
	["magma"] = {"Neon", 255, 100, 24, 0},
	["coeur"] = {"Neon", 255, 150, 40, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "magma", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "basalte3", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(0.265, 0.3457, -0.5967, 0.9977, 0.0295, 0.0611, -0.0313, 0.9991, 0.0288, -0.0602, -0.0306, 0.9977), "JambeD"},
	{"Cuissard", "basalte3", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(0.265, 0.7344, -0.5643, 0.9958, -0.0813, 0.0418, 0.082, 0.9965, -0.0134, -0.0406, 0.0168, 0.999), "JambeD"},
	{"Cuissard", "basalte", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(0.735, 0.3446, -0.5809, 0.9993, -0.0311, 0.0229, 0.0307, 0.9994, 0.0141, -0.0233, -0.0134, 0.9996), "JambeD"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(0.735, 0.7354, -0.5782, 0.9953, 0.0021, -0.0965, -0.001, 0.9999, 0.0112, 0.0965, -0.0111, 0.9953), "JambeD"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, -0.0116, -0.0443, 0.999, 0.0041, 0.999, 0.0443, -0.9999, 0.0046, -0.0114), "JambeD"},
	{"Genouillere", "basalte2", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "basalte", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9976, 0.0617, -0.0319, -0.0583, 0.9935, 0.0982, 0.0377, -0.0961, 0.9947), "JambeD"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(0.27, -0.7, -0.5745, 0.992, 0.0978, 0.0794, -0.0998, 0.9948, 0.0212, -0.077, -0.0289, 0.9966), "JambeD"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(0.27, -0.3008, -0.6012, 0.9988, 0.0473, -0.01, -0.0463, 0.9951, 0.0879, 0.0141, -0.0873, 0.9961), "JambeD"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(0.73, -0.6994, -0.5635, 0.9994, 0.028, 0.0187, -0.0285, 0.9993, 0.0235, -0.0181, -0.024, 0.9995), "JambeD"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(0.73, -0.3007, -0.5992, 0.9955, -0.0913, -0.0246, 0.0901, 0.9949, -0.0463, 0.0287, 0.0439, 0.9986), "JambeD"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0307, -0.0707, 0.997, 0.0444, 0.9966, 0.0693, -0.9985, 0.0422, 0.0337), "JambeD"},
	{"Mollet", "basalte", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9975, 0.0697, -0.0132, -0.0704, 0.9959, -0.0568, 0.0092, 0.0575, 0.9983), "JambeD"},
	{"Cheville", "basalte2", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "basalte3", "Bloc", Vector3.new(0.3, 0.3, 0.08), CFrame.new(0.5, 0.02, -0.74, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Genouillere", "coeur", "Bloc", Vector3.new(0.16, 0.16, 0.05), CFrame.new(0.5, 0.02, -0.79, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD", "lumiere"},
	{"Pointes", "basalte2", "Bloc", Vector3.new(0.22, 0.231, 0.22), CFrame.new(1.1498, 0.0999, -0.1701, 0.4993, 0.8639, 0.0666, -0.6662, 0.4319, -0.608, -0.554, 0.2592, 0.7912), "JambeD"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(1.3442, 0.1919, -0.1853, -0.8661, -0.2822, -0.4127, 0.3585, 0.2248, -0.9061, 0.3484, -0.9327, -0.0935), "JambeD"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(1.2936, 0.081, -0.1967, 0.8661, -0.2822, 0.4127, -0.3585, 0.2248, 0.9061, -0.3484, -0.9327, 0.0935), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(1.2954, 0.2514, -0.1218, -0.377, -0.7966, -0.4726, -0.7427, 0.5648, -0.3597, 0.5534, 0.2154, -0.8046), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(1.2375, 0.2074, -0.2202, 0.377, -0.7966, 0.4726, 0.7427, 0.5648, 0.3597, -0.5534, 0.2154, 0.8046), "JambeD"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(1.1946, 0.2131, -0.0868, -0.003, -0.5079, 0.8614, -0.793, 0.526, 0.3073, -0.6092, -0.6822, -0.4044), "JambeD"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(1.3, 0.2508, -0.1363, 0.003, -0.5079, -0.8614, 0.793, 0.526, -0.3073, 0.6092, -0.6822, 0.4044), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(1.2507, 0.0868, -0.0633, -0.4921, -0.7665, 0.4127, 0.3082, 0.29, 0.9061, -0.8141, 0.5731, 0.0935), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(1.3012, 0.1976, -0.0518, 0.4921, -0.7665, -0.4127, -0.3082, 0.29, -0.9061, 0.8141, 0.5731, -0.0935), "JambeD"},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.2, 0.187, 0.2), CFrame.new(0.5, 0.2336, -0.7766, 0.866, 0, 0.5, -0.4096, 0.5735, 0.7095, -0.2867, -0.8192, 0.4966), "JambeD"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(0.5779, 0.2466, -0.8736, -0.7249, 0.6661, -0.1757, 0.0291, 0.2845, 0.9582, 0.6882, 0.6895, -0.2256), "JambeD"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(0.5596, 0.3464, -0.8971, 0.7249, 0.6661, 0.1757, -0.0291, 0.2845, -0.9582, -0.6882, 0.6895, 0.2256), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(0.4367, 0.3195, -0.916, 0.4185, -0.891, 0.1757, 0.2801, -0.0573, -0.9582, 0.8639, 0.4503, 0.2256), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(0.455, 0.2197, -0.8925, -0.4185, -0.891, -0.1757, -0.2801, -0.0573, 0.9582, -0.8639, 0.4503, -0.2256), "JambeD"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(0.4904, 0.3792, -0.8742, 0.7249, 0.2112, -0.6556, -0.6566, 0.4996, -0.565, 0.2082, 0.8401, 0.5009), "JambeD"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(0.4221, 0.3203, -0.822, -0.7249, 0.2112, 0.6556, 0.6566, 0.4996, 0.565, -0.2082, 0.8401, -0.5009), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(0.545, 0.3473, -0.8031, -0.4185, -0.6285, -0.6556, -0.9076, 0.3153, 0.2772, 0.0325, 0.7111, -0.7023), "JambeD"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(0.4767, 0.3762, -0.8763, 0.4185, -0.6285, 0.6556, 0.9076, 0.3153, -0.2772, -0.0325, 0.7111, 0.7023), "JambeD"},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(1.115, -0.5, 0.15, 0, 0, 1, 0.5, 0.866, 0, -0.866, 0.5, 0), "JambeD"},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(1.115, -0.3611, 0.1494, 0, 0, 1, 0.9397, 0.342, 0, -0.342, 0.9397, 0), "JambeD"},
	{"Dessous", "magma", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "basalte3", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(-0.265, 0.3457, -0.5967, 0.9977, -0.0295, -0.0611, 0.0313, 0.9991, 0.0288, 0.0602, -0.0306, 0.9977), "JambeG"},
	{"Cuissard", "basalte3", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(-0.265, 0.7344, -0.5643, 0.9958, 0.0813, -0.0418, -0.082, 0.9965, -0.0134, 0.0406, 0.0168, 0.999), "JambeG"},
	{"Cuissard", "basalte", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(-0.735, 0.3446, -0.5809, 0.9993, 0.0311, -0.0229, -0.0307, 0.9994, 0.0141, 0.0233, -0.0134, 0.9996), "JambeG"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(0.423, 0.351, 0.12), CFrame.new(-0.735, 0.7354, -0.5782, 0.9953, -0.0021, 0.0965, 0.001, 0.9999, 0.0112, -0.0965, -0.0111, 0.9953), "JambeG"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "basalte2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, -0.0116, 0.0443, -0.999, -0.0041, 0.999, 0.0443, 0.9999, 0.0046, -0.0114), "JambeG"},
	{"Genouillere", "basalte2", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "basalte", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9976, -0.0617, 0.0319, 0.0583, 0.9935, 0.0982, -0.0377, -0.0961, 0.9947), "JambeG"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(-0.27, -0.7, -0.5745, 0.992, -0.0978, -0.0794, 0.0998, 0.9948, 0.0212, 0.077, -0.0289, 0.9966), "JambeG"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(-0.27, -0.3008, -0.6012, 0.9988, -0.0473, 0.01, 0.0463, 0.9951, 0.0879, -0.0141, -0.0873, 0.9961), "JambeG"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(-0.73, -0.6994, -0.5635, 0.9994, -0.028, -0.0187, 0.0285, 0.9993, 0.0235, 0.0181, -0.024, 0.9995), "JambeG"},
	{"Greve", "basalte", "Bloc", Vector3.new(0.414, 0.36, 0.12), CFrame.new(-0.73, -0.3007, -0.5992, 0.9955, 0.0913, 0.0246, -0.0901, 0.9949, -0.0463, -0.0287, 0.0439, 0.9986), "JambeG"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "basalte2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0307, 0.0707, -0.997, -0.0444, 0.9966, 0.0693, 0.9985, 0.0422, 0.0337), "JambeG"},
	{"Mollet", "basalte", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9975, -0.0697, 0.0132, 0.0704, 0.9959, -0.0568, -0.0092, 0.0575, 0.9983), "JambeG"},
	{"Cheville", "basalte2", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "basalte3", "Bloc", Vector3.new(0.3, 0.3, 0.08), CFrame.new(-0.5, 0.02, -0.74, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Genouillere", "coeur", "Bloc", Vector3.new(0.16, 0.16, 0.05), CFrame.new(-0.5, 0.02, -0.79, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG", "lumiere"},
	{"Pointes", "basalte2", "Bloc", Vector3.new(0.22, 0.231, 0.22), CFrame.new(-1.1498, 0.0999, -0.1701, 0.4993, -0.8639, -0.0666, 0.6662, 0.4319, -0.608, 0.554, 0.2592, 0.7912), "JambeG"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(-1.3442, 0.1919, -0.1853, -0.8661, 0.2822, 0.4127, -0.3585, 0.2248, -0.9061, -0.3484, -0.9327, -0.0935), "JambeG"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(-1.2936, 0.081, -0.1967, 0.8661, 0.2822, -0.4127, 0.3585, 0.2248, 0.9061, 0.3484, -0.9327, 0.0935), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(-1.2954, 0.2514, -0.1218, -0.377, 0.7966, 0.4726, 0.7427, 0.5648, -0.3597, -0.5534, 0.2154, -0.8046), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(-1.2375, 0.2074, -0.2202, 0.377, 0.7966, -0.4726, -0.7427, 0.5648, 0.3597, 0.5534, 0.2154, 0.8046), "JambeG"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(-1.1946, 0.2131, -0.0868, -0.003, 0.5079, -0.8614, 0.793, 0.526, 0.3073, 0.6092, -0.6822, -0.4044), "JambeG"},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(-1.3, 0.2508, -0.1363, 0.003, 0.5079, 0.8614, -0.793, 0.526, -0.3073, -0.6092, -0.6822, 0.4044), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.0989), CFrame.new(-1.2507, 0.0868, -0.0633, -0.4921, 0.7665, -0.4127, -0.3082, 0.29, 0.9061, 0.8141, 0.5731, 0.0935), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.1965, 0.1459), CFrame.new(-1.3012, 0.1976, -0.0518, 0.4921, 0.7665, 0.4127, 0.3082, 0.29, -0.9061, -0.8141, 0.5731, -0.0935), "JambeG"},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.2, 0.187, 0.2), CFrame.new(-0.5, 0.2336, -0.7766, 0.866, 0, -0.5, 0.4096, 0.5735, 0.7095, 0.2867, -0.8192, 0.4966), "JambeG"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(-0.5779, 0.2466, -0.8736, -0.7249, -0.6661, 0.1757, -0.0291, 0.2845, 0.9582, -0.6882, 0.6895, -0.2256), "JambeG"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(-0.5596, 0.3464, -0.8971, 0.7249, -0.6661, -0.1757, 0.0291, 0.2845, -0.9582, 0.6882, 0.6895, 0.2256), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(-0.4367, 0.3195, -0.916, 0.4185, 0.891, -0.1757, -0.2801, -0.0573, -0.9582, -0.8639, 0.4503, 0.2256), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(-0.455, 0.2197, -0.8925, -0.4185, 0.891, 0.1757, 0.2801, -0.0573, 0.9582, 0.8639, 0.4503, -0.2256), "JambeG"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(-0.4904, 0.3792, -0.8742, 0.7249, -0.2112, 0.6556, 0.6566, 0.4996, -0.565, -0.2082, 0.8401, 0.5009), "JambeG"},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(-0.4221, 0.3203, -0.822, -0.7249, -0.2112, -0.6556, -0.6566, 0.4996, 0.565, 0.2082, 0.8401, -0.5009), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.096), CFrame.new(-0.545, 0.3473, -0.8031, -0.4185, 0.6285, 0.6556, 0.9076, 0.3153, 0.2772, -0.0325, 0.7111, -0.7023), "JambeG"},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1755, 0.1124), CFrame.new(-0.4767, 0.3762, -0.8763, 0.4185, 0.6285, -0.6556, -0.9076, 0.3153, -0.2772, 0.0325, 0.7111, 0.7023), "JambeG"},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-1.115, -0.5, 0.15, 0, 0, -1, -0.5, 0.866, 0, 0.866, 0.5, 0), "JambeG"},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-1.115, -0.3611, 0.1494, 0, 0, -1, -0.9397, 0.342, 0, 0.342, 0.9397, 0), "JambeG"},
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
	modele.Name = "JambieresMagmaite"
	modele:SetAttribute("NomAffiche", "Jambières de magmaïte")

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
			l.Color = Color3.fromRGB(255, 110, 30)
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
	Nom = "Jambières de magmaïte",
	Format = "Code",
	Taille = Vector3.new(2.8256, 1.99, 1.644),
	Centre = Vector3.new(0, 0.005, -0.1566), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
