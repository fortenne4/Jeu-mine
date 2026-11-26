-- Généré par blender/armes/armures_minerais.py (128 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de magmaïte : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronMagmaite.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["basalte"] = {"Basalt", 66, 58, 60, 0},
	["basalte2"] = {"Basalt", 84, 74, 76, 0},
	["basalte3"] = {"Basalt", 50, 44, 48, 0},
	["magma"] = {"Neon", 255, 100, 24, 0},
	["coeur"] = {"Neon", 255, 150, 40, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "magma", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "basalte3", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(0.2536, 0.145, -0.6832, 0.98, -0.068, -0.1868, 0.0698, 0.9976, 0.0028, 0.1861, -0.0158, 0.9824)},
	{"Poitrine", "basalte3", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(0.2571, 0.575, -0.6995, 0.9535, -0.0166, -0.3008, 0.0239, 0.9995, 0.0208, 0.3003, -0.027, 0.9535)},
	{"Poitrine", "basalte3", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(0.7417, 0.145, -0.5745, 0.9771, -0.0076, -0.2124, -0.0073, 0.9976, -0.069, 0.2125, 0.069, 0.9747)},
	{"Poitrine", "basalte", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(0.7459, 0.575, -0.5945, 0.9785, 0.0799, -0.19, -0.0795, 0.9968, 0.0097, 0.1901, 0.0056, 0.9817)},
	{"Liseré", "basalte2", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "basalte3", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(-0.744, 0.145, -0.5853, 0.9698, -0.0636, 0.2356, 0.0767, 0.996, -0.0468, -0.2317, 0.0635, 0.9707)},
	{"Poitrine", "basalte", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(-0.742, 0.575, -0.5763, 0.9821, -0.093, 0.164, 0.0871, 0.9953, 0.0433, -0.1673, -0.0282, 0.9855)},
	{"Poitrine", "basalte", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(-0.2538, 0.145, -0.6842, 0.9869, 0.0584, 0.1505, -0.0683, 0.9958, 0.0609, -0.1463, -0.0704, 0.9867)},
	{"Poitrine", "basalte3", "Bloc", Vector3.new(0.45, 0.387, 0.12), CFrame.new(-0.2548, 0.575, -0.6889, 0.9576, -0.1201, 0.2619, 0.0981, 0.9906, 0.0956, -0.2709, -0.0659, 0.9604)},
	{"Liseré", "basalte2", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "basalte2", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.441, 0.252, 0.12), CFrame.new(0.2379, -0.2095, -0.6577, 0.9981, 0.0019, -0.0618, -0.0104, 0.9904, -0.1377, 0.0609, 0.1381, 0.9885)},
	{"Lames", "basalte", "Bloc", Vector3.new(0.441, 0.252, 0.12), CFrame.new(0.7224, -0.2102, -0.5845, 0.9976, 0.0194, -0.0658, -0.032, 0.9798, -0.1974, 0.0606, 0.199, 0.9781)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.441, 0.252, 0.12), CFrame.new(-0.7234, -0.2092, -0.5917, 0.9887, -0.0018, 0.1498, 0.0342, 0.9762, -0.2141, -0.1458, 0.2168, 0.9653)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.441, 0.252, 0.12), CFrame.new(-0.2369, -0.2105, -0.6506, 0.9925, 0.0802, 0.0919, -0.0676, 0.9888, -0.1329, -0.1015, 0.1257, 0.9869)},
	{"Lames", "basalte", "Bloc", Vector3.new(0.45, 0.252, 0.12), CFrame.new(0.2308, -0.4516, -0.6634, 0.9879, 0.0306, -0.152, -0.0501, 0.9908, -0.126, 0.1467, 0.1321, 0.9803)},
	{"Lames", "basalte", "Bloc", Vector3.new(0.45, 0.252, 0.12), CFrame.new(0.7295, -0.4481, -0.6186, 0.9931, 0.0551, -0.1036, -0.0619, 0.996, -0.0639, 0.0997, 0.0699, 0.9926)},
	{"Lames", "basalte2", "Bloc", Vector3.new(0.45, 0.252, 0.12), CFrame.new(-0.7296, -0.448, -0.6193, 0.9895, -0.072, 0.1254, 0.089, 0.9868, -0.1352, -0.114, 0.145, 0.9829)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.45, 0.252, 0.12), CFrame.new(-0.2332, -0.4493, -0.6801, 0.985, 0.0776, 0.1544, -0.0574, 0.9897, -0.1311, -0.163, 0.1202, 0.9793)},
	{"Lames", "basalte2", "Bloc", Vector3.new(0.459, 0.252, 0.12), CFrame.new(0.2267, -0.6908, -0.6898, 0.978, 0.0384, -0.2051, -0.0624, 0.9917, -0.112, 0.1991, 0.1223, 0.9723)},
	{"Lames", "basalte", "Bloc", Vector3.new(0.459, 0.252, 0.12), CFrame.new(0.7318, -0.6907, -0.6194, 0.9953, -0.0535, -0.0807, 0.0395, 0.9854, -0.1659, 0.0884, 0.1619, 0.9828)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.459, 0.252, 0.12), CFrame.new(-0.7316, -0.6909, -0.6183, 0.9832, 0.0051, 0.1824, 0.0121, 0.9955, -0.0935, -0.1821, 0.0942, 0.9788)},
	{"Lames", "basalte3", "Bloc", Vector3.new(0.459, 0.252, 0.12), CFrame.new(-0.2279, -0.6896, -0.6984, 0.9922, 0.0769, 0.0978, -0.0596, 0.9838, -0.1688, -0.1092, 0.1617, 0.9808)},
	{"Flanc", "basalte", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, 0.0544, 0.037, 0.9978, -0.0246, 0.9991, -0.0357, -0.9982, -0.0226, 0.0553)},
	{"Flanc", "basalte3", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, -0.0006, 0.0917, -0.9958, -0.0817, 0.9925, 0.0914, 0.9967, 0.0814, 0.0069)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(0.6533, 0.085, 0.6084, -0.9992, 0.025, 0.032, 0.0219, 0.9954, -0.093, -0.0342, -0.0923, -0.9951)},
	{"Dossiere", "basalte", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(0.6533, 0.555, 0.621, -0.9966, 0.042, -0.0705, 0.0465, 0.9969, -0.0634, 0.0676, -0.0665, -0.9955)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(0, 0.085, 0.6324, -0.9938, -0.0996, -0.0502, -0.1033, 0.9916, 0.0779, 0.042, 0.0826, -0.9957)},
	{"Dossiere", "basalte2", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(0, 0.555, 0.6099, -0.9983, -0.0573, 0.0053, -0.0573, 0.9984, -0.0033, -0.0051, -0.0036, -1)},
	{"Dossiere", "basalte", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(-0.6533, 0.085, 0.606, -0.9984, 0.0299, -0.0485, 0.0315, 0.9989, -0.0334, 0.0474, -0.0349, -0.9983)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.588, 0.423, 0.12), CFrame.new(-0.6533, 0.555, 0.626, -0.9977, -0.0299, -0.0609, -0.0334, 0.9978, 0.0575, 0.059, 0.0594, -0.9965)},
	{"Dossiere", "basalte2", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "basalte", "Bloc", Vector3.new(0.594, 0.252, 0.12), CFrame.new(-0.66, -0.209, 0.6269, 0.9943, -0.1043, -0.0225, 0.1066, 0.9816, 0.1581, 0.0056, -0.1596, 0.9872)},
	{"Dossiere", "basalte2", "Bloc", Vector3.new(0.594, 0.252, 0.12), CFrame.new(0, -0.2104, 0.6173, 0.9968, -0.0768, -0.0215, 0.0787, 0.9905, 0.1127, 0.0126, -0.1141, 0.9934)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.594, 0.252, 0.12), CFrame.new(0.66, -0.2107, 0.6147, 0.9969, -0.0246, 0.0742, 0.0117, 0.9854, 0.1699, -0.0773, -0.1685, 0.9827)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.6, 0.252, 0.12), CFrame.new(-0.6667, -0.4483, 0.6523, 0.9928, -0.1004, 0.0659, 0.0921, 0.9886, 0.119, -0.0771, -0.1121, 0.9907)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.6, 0.252, 0.12), CFrame.new(0, -0.45, 0.6403, 0.9993, 0.0139, 0.0351, -0.0152, 0.9991, 0.0383, -0.0345, -0.0388, 0.9986)},
	{"Dossiere", "basalte2", "Bloc", Vector3.new(0.6, 0.252, 0.12), CFrame.new(0.6667, -0.4502, 0.6386, 0.9989, 0.0456, -0.0122, -0.0423, 0.9801, 0.1939, 0.0208, -0.1931, 0.981)},
	{"Dossiere", "basalte", "Bloc", Vector3.new(0.606, 0.252, 0.12), CFrame.new(-0.6733, -0.69, 0.6601, 0.9932, -0.0554, 0.1027, 0.049, 0.9967, 0.0641, -0.1059, -0.0586, 0.9926)},
	{"Dossiere", "basalte3", "Bloc", Vector3.new(0.606, 0.252, 0.12), CFrame.new(0, -0.688, 0.6739, 0.9968, 0.0778, 0.0154, -0.0793, 0.9743, 0.2106, 0.0014, -0.2112, 0.9774)},
	{"Dossiere", "basalte", "Bloc", Vector3.new(0.606, 0.252, 0.12), CFrame.new(0.6733, -0.6887, 0.6696, 0.9998, 0.0215, 0.0056, -0.0222, 0.9737, 0.2268, -0.0006, -0.2269, 0.9739)},
	{"Col", "basalte2", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "basalte2", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "basalte2", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "basalte2", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "basalte2", "Bloc", Vector3.new(0.45, 0.18, 1.26), CFrame.new(0.8024, 0.9948, 0.0014, 0.9983, 0.0469, 0.035, -0.0458, 0.9985, -0.0293, -0.0363, 0.0276, 0.999)},
	{"Epauliere", "basalte3", "Bloc", Vector3.new(0.45, 0.18, 1.26), CFrame.new(1.2976, 0.9252, 0.0085, 0.9852, 0.1635, -0.052, -0.1659, 0.9851, -0.0446, 0.044, 0.0526, 0.9976)},
	{"Epauliere", "basalte3", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.9016, 0.4279, 0.0625, -0.4292, 0.9032, 0.0078, -0.0531, -0.0338, 0.998)},
	{"Epauliere", "basalte2", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "basalte2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9933, 0.1156, -0.0082, -0.1159, 0.989, -0.0923, -0.0025, 0.0926, 0.9957)},
	{"Epauliere", "basalte3", "Bloc", Vector3.new(0.45, 0.18, 1.26), CFrame.new(-1.2976, 0.9252, 0.0091, 0.9882, -0.1355, 0.0717, 0.1327, 0.9903, 0.0422, -0.0767, -0.0322, 0.9965)},
	{"Epauliere", "basalte3", "Bloc", Vector3.new(0.45, 0.18, 1.26), CFrame.new(-0.8024, 0.9948, 0.0025, 0.9927, -0.0979, 0.0704, 0.102, 0.9931, -0.0576, -0.0643, 0.0644, 0.9958)},
	{"Epauliere", "basalte", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8673, -0.497, -0.0267, 0.4921, 0.8643, -0.1039, 0.0747, 0.077, 0.9942)},
	{"Epauliere", "basalte2", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "basalte", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9866, -0.1188, -0.1121, 0.1286, 0.9881, 0.0844, 0.1007, -0.0976, 0.9901)},
	{"Ceinture", "basalte3", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "basalte2", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "magma", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "basalte3", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 0.995, -0.1001, 0.0024, 0.1, 0.9923, -0.0727, 0.0049, 0.0726, 0.9974)},
	{"Tassette", "basalte2", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "basalte3", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9981, 0.0037, 0.0611, 0.004, 0.992, -0.1258, -0.061, 0.1258, 0.9902)},
	{"Tassette", "basalte2", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Coeur", "basalte3", "Bloc", Vector3.new(0.36, 0.36, 0.08), CFrame.new(0, 0.42, -0.84, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1)},
	{"Coeur", "coeur", "Bloc", Vector3.new(0.22, 0.22, 0.06), CFrame.new(0, 0.42, -0.89, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "lumiere"},
	{"Pointes", "basalte2", "Bloc", Vector3.new(0.24, 0.264, 0.24), CFrame.new(1.0873, 1.0842, -0.3248, 0.8179, 0.2822, 0.5013, -0.3384, 0.9407, 0.0226, -0.4652, -0.1881, 0.865)},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(1.212, 1.1657, -0.3993, -0.8521, 0.5167, 0.0836, -0.161, -0.4107, 0.8974, 0.4981, 0.7512, 0.4332)},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(1.2235, 1.289, -0.3398, 0.8521, 0.5167, -0.0836, 0.161, -0.4107, -0.8974, -0.4981, 0.7512, -0.4332)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(1.0681, 1.2002, -0.4429, 0.3012, 0.5216, 0.7982, -0.4371, -0.6685, 0.6017, 0.8475, -0.5302, 0.0267)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(1.1777, 1.2828, -0.4392, -0.3012, 0.5216, -0.7982, 0.4371, -0.6685, -0.6017, -0.8475, -0.5302, -0.0267)},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(1.1432, 1.3222, -0.2941, 0.5779, 0.1697, -0.7982, -0.7527, -0.2671, -0.6017, -0.3153, 0.9486, -0.0267)},
	{"Pointes", "basalte2", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(1.0336, 1.2396, -0.2978, -0.5779, 0.1697, 0.7982, 0.7527, -0.2671, 0.6017, 0.3153, 0.9486, 0.0267)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(1.2269, 1.285, -0.3543, -0.5753, 0.7343, -0.3602, -0.4766, -0.6589, -0.582, -0.6647, -0.1631, 0.729)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(1.1775, 1.2051, -0.2542, 0.5753, 0.7343, 0.3602, 0.4766, -0.6589, 0.582, 0.6647, -0.1631, -0.729)},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.26, 0.308, 0.26), CFrame.new(1.2168, 1.0817, 0.1771, 0.5647, 0.4402, 0.6981, -0.119, 0.8805, -0.459, -0.8166, 0.1761, 0.5496)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(1.3492, 1.1981, 0.1061, -0.7037, 0.5794, 0.4112, -0.2979, -0.766, 0.5696, 0.645, 0.2784, 0.7116)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(1.4134, 1.2869, 0.2171, 0.7037, 0.5794, -0.4112, 0.2979, -0.766, -0.5696, -0.645, 0.2784, -0.7116)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(1.2632, 1.3556, 0.2489, 0.4185, -0.8098, -0.4112, -0.8115, -0.1302, -0.5696, 0.4077, 0.5721, -0.7116)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(1.1991, 1.2668, 0.1379, -0.4185, -0.8098, 0.4112, 0.8115, -0.1302, 0.5696, -0.4077, 0.5721, 0.7116)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(1.3525, 1.2997, 0.3051, 0.3001, 0.3636, -0.8819, -0.5094, -0.7205, -0.4704, -0.8065, 0.5904, -0.031)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(1.215, 1.2264, 0.3003, -0.3001, 0.3636, 0.8819, 0.5094, -0.7205, 0.4704, 0.8065, 0.5904, 0.031)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(1.3651, 1.1577, 0.2686, -0.8222, -0.543, -0.1706, 0.0042, -0.3056, 0.9522, -0.5692, 0.7821, 0.2535)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(1.3385, 1.3062, 0.3081, 0.8222, -0.543, 0.1706, -0.0042, -0.3056, -0.9522, 0.5692, 0.7821, -0.2535)},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.2, 0.209, 0.2), CFrame.new(1.4755, 0.9639, 0.4938, 0.6408, 0.7553, -0.1379, -0.7019, 0.5035, -0.5038, -0.3111, 0.4196, 0.8527)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(1.6467, 1.0539, 0.5161, -0.9344, -0.025, -0.3554, 0.3517, 0.0942, -0.9314, 0.0567, -0.9952, -0.0792)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(1.6073, 0.9506, 0.5073, 0.9344, -0.025, 0.3554, -0.3517, 0.0942, 0.9314, -0.0567, -0.9952, 0.0792)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(1.5879, 1.1116, 0.5528, -0.5003, -0.8344, -0.2311, -0.6891, 0.5453, -0.4773, 0.5243, -0.0795, -0.8478)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(1.5622, 1.0586, 0.4587, 0.5003, -0.8344, 0.2311, 0.6891, 0.5453, 0.4773, -0.5243, -0.0795, 0.8478)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(1.4924, 1.0764, 0.563, 0.1719, -0.3165, 0.9329, -0.8601, 0.4136, 0.2987, -0.4803, -0.8537, -0.2011)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(1.5959, 1.1095, 0.5407, -0.1719, -0.3165, -0.9329, 0.8601, 0.4136, -0.2987, 0.4803, -0.8537, 0.2011)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(1.5375, 0.9683, 0.6116, -0.2622, -0.8972, 0.3554, 0.1807, 0.3161, 0.9314, -0.9479, 0.3085, 0.0792)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(1.5769, 1.0716, 0.6204, 0.2622, -0.8972, -0.3554, -0.1807, 0.3161, -0.9314, 0.9479, 0.3085, -0.0792)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(0.7135, 0.55, -0.6611, -0.4891, 0.8471, 0.2079, 0.866, 0.5, 0, -0.104, 0.1801, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(0.7809, 0.6706, -0.6467, 0.1699, 0.9633, 0.2079, 0.9848, -0.1736, 0, 0.0361, 0.2048, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.26, 0.03), CFrame.new(0.2635, 0.65, -0.7567, -0.8471, -0.4891, 0.2079, -0.5, 0.866, 0, -0.1801, -0.104, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.143, 0.03), CFrame.new(0.1534, 0.7051, -0.7801, -0.9633, 0.1699, 0.2079, 0.1736, 0.9848, 0, -0.2048, 0.0361, -0.9781)},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.24, 0.264, 0.24), CFrame.new(-1.0873, 1.0842, -0.3248, 0.893, -0.2822, 0.3505, 0.1859, 0.9407, 0.2837, -0.4098, -0.1881, 0.8926)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(-1.1305, 1.2963, -0.4425, -0.6436, -0.0181, 0.7652, -0.6194, -0.575, -0.5346, 0.4496, -0.818, 0.3588)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(-1.0254, 1.2229, -0.3932, 0.6436, -0.0181, -0.7652, 0.6194, -0.575, 0.5346, -0.4496, -0.818, -0.3588)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(-1.161, 1.1717, -0.4459, 0.4435, 0.8367, 0.3213, -0.2089, -0.2522, 0.9449, 0.8716, -0.4862, 0.0629)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(-1.1169, 1.3015, -0.4372, -0.4435, 0.8367, -0.3213, 0.2089, -0.2522, -0.9449, -0.8716, -0.4862, -0.0629)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(-1.2202, 1.1824, -0.3038, 0.9177, -0.397, 0.0151, -0.2943, -0.6539, 0.697, -0.2669, -0.6441, -0.7169)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(-1.2181, 1.2781, -0.4023, -0.9177, -0.397, -0.0151, 0.2943, -0.6539, -0.697, 0.2669, -0.6441, 0.7169)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1698), CFrame.new(-1.0825, 1.3293, -0.3496, -0.1694, 0.9854, -0.0151, -0.7048, -0.1318, -0.697, -0.6889, -0.1074, 0.7169)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2159, 0.1048), CFrame.new(-1.0846, 1.2336, -0.2512, 0.1694, 0.9854, 0.0151, 0.7048, -0.1318, 0.697, 0.6889, -0.1074, -0.7169)},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.26, 0.308, 0.26), CFrame.new(-1.2168, 1.0817, 0.1771, 0.58, -0.4402, 0.6854, 0.4286, 0.8805, 0.2029, -0.6928, 0.1761, 0.6993)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(-1.2131, 1.2632, 0.1209, -0.3136, 0.8969, -0.3117, -0.7845, -0.0598, 0.6172, 0.535, 0.4381, 0.7224)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(-1.2618, 1.3594, 0.2335, 0.3136, 0.8969, 0.3117, 0.7845, -0.0598, -0.6172, -0.535, 0.4381, -0.7224)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(-1.3636, 1.1881, 0.1201, 0.811, 0.5593, 0.1717, -0.2234, 0.0247, 0.9744, 0.5408, -0.8286, 0.145)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(-1.3368, 1.3401, 0.1427, -0.811, 0.5593, -0.1717, 0.2234, 0.0247, -0.9744, -0.5408, -0.8286, -0.145)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(-1.351, 1.1613, 0.2856, 0.7173, -0.5708, -0.3996, -0.0228, -0.5924, 0.8053, -0.6964, -0.5685, -0.4379)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(-1.4134, 1.2869, 0.2173, -0.7173, -0.5708, 0.3996, 0.0228, -0.5924, -0.8053, 0.6964, -0.5685, 0.4379)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.2036), CFrame.new(-1.2629, 1.3619, 0.2181, -0.4073, 0.8212, 0.3996, -0.5839, 0.1022, -0.8053, -0.7022, -0.5614, 0.4379)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.025, 0.2363, 0.1084), CFrame.new(-1.2006, 1.2363, 0.2864, 0.4073, 0.8212, -0.3996, 0.5839, 0.1022, 0.8053, 0.7022, -0.5614, -0.4379)},
	{"Pointes", "basalte", "Bloc", Vector3.new(0.2, 0.209, 0.2), CFrame.new(-1.4755, 0.9639, 0.4938, 0.2774, -0.7553, 0.5938, 0.8256, 0.5035, 0.2547, -0.4914, 0.4196, 0.7632)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(-1.6331, 1.0765, 0.5134, 0.1418, -0.1732, 0.9746, -0.9668, -0.2355, 0.0988, 0.2124, -0.9563, -0.2008)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(-1.525, 1.0875, 0.4911, -0.1418, -0.1732, -0.9746, 0.9668, -0.2355, -0.0988, -0.2124, -0.9563, 0.2008)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(-1.6519, 1.0051, 0.5653, 0.8939, -0.0889, 0.4394, -0.0343, -0.9908, -0.1307, 0.447, 0.1018, -0.8887)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(-1.6031, 0.9906, 0.4667, -0.8939, -0.0889, -0.4394, 0.0343, -0.9908, 0.1308, -0.447, 0.1018, 0.8887)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(-1.5957, 1.0365, 0.6287, 0.6207, 0.7608, 0.1894, 0.4585, -0.1563, -0.8748, -0.636, 0.6299, -0.4458)},
	{"Pointes", "basalte", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(-1.5747, 0.9395, 0.5792, -0.6207, 0.7608, -0.1894, -0.4585, -0.1563, 0.8748, 0.636, 0.6299, 0.4458)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.0901), CFrame.new(-1.4966, 1.0363, 0.6036, -0.1313, 0.1813, -0.9746, -0.4741, -0.8749, -0.0988, -0.8706, 0.4491, 0.2008)},
	{"Pointes", "basalte3", "Coin", Vector3.new(0.024, 0.1785, 0.1318), CFrame.new(-1.6048, 1.0253, 0.6259, 0.1313, 0.1813, 0.9746, 0.4741, -0.8749, 0.0988, 0.8706, 0.4491, -0.2008)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.3, 0.03), CFrame.new(-0.7135, 0.55, -0.6611, -0.4891, -0.8471, -0.2079, -0.866, 0.5, 0, 0.104, 0.1801, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.165, 0.03), CFrame.new(-0.8494, 0.5494, -0.6322, -0.9192, -0.3345, -0.2079, -0.342, 0.9397, 0, 0.1954, 0.0711, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.045, 0.26, 0.03), CFrame.new(-0.2635, 0.65, -0.7567, -0.8471, 0.4891, -0.2079, 0.5, 0.866, 0, 0.1801, -0.104, -0.9781)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.143, 0.03), CFrame.new(-0.2719, 0.7751, -0.7549, -0.3345, 0.9192, -0.2079, 0.9397, 0.342, 0, 0.0711, -0.1954, -0.9781)},
}

local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function particules(parent: BasePart)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Scintillement"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 176, 64), Color3.fromRGB(210, 40, 10))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 5
	e.Lifetime = NumberRange.new(1.2, 2.2)
	e.Speed = NumberRange.new(0.25, 0.6)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 0.5, 0)
	e.Drag = 0.6
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.09),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Parent = parent
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
	modele.Name = "PlastronMagmaite"
	modele:SetAttribute("NomAffiche", "Plastron de magmaïte")

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
			l.Color = Color3.fromRGB(255, 110, 30)
			l.Range = 6
			l.Brightness = 1.2
			l.Shadows = false
			l.Parent = p
			particules(p)
		end
		p.Parent = modele
		souder(racine, p)
	end
	return modele
end

return {
	Nom = "Plastron de magmaïte",
	Format = "Code",
	Taille = Vector3.new(4.3585, 2.6837, 1.6883),
	Centre = Vector3.new(-0.0297, 0.0974, -0.0758), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
