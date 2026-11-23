-- Généré par blender/armes/casque_magma.py (149 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Casque du Cœur Magmatique : casque unique de quête (grotte de lave −200 m, voir Partage.CasqueMagma).
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Version mesh exportable : assets/casques/CasqueMagma.fbx / .obj.
-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	basalte = {"Basalt", 38, 35, 38, 0},
	obsidienne = {"SmoothPlastic", 21, 19, 25, 0.12},
	roche = {"Slate", 70, 64, 64, 0},
	visiere = {"SmoothPlastic", 46, 42, 50, 0.1},
	fente = {"SmoothPlastic", 0, 0, 0, 0},
	yeux = {"Neon", 150, 16, 8, 0},
	magma = {"Neon", 255, 88, 18, 0},
	cristal = {"Neon", 255, 124, 26, 0},
	coeur = {"Neon", 255, 222, 96, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame, marque ("lumiere" | "braises")}
local PIECES = {
	{"Coque", "basalte", "Bloc", Vector3.new(1, 1, 0.08), CFrame.new(0, 0.72, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0), "braises"},
	{"Coque", "basalte", "Bloc", Vector3.new(1, 1.22, 0.08), CFrame.new(0.68, -0.07, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Coque", "basalte", "Bloc", Vector3.new(1, 1.22, 0.08), CFrame.new(-0.68, -0.07, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Coque", "basalte", "Bloc", Vector3.new(1, 1.22, 0.08), CFrame.new(0, -0.07, 0.68, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Visiere", "visiere", "Bloc", Vector3.new(1, 1.22, 0.08), CFrame.new(0, -0.07, -0.68, -1, 0, 0, 0, 1, 0, 0, 0, -1)},
	{"Coque", "basalte", "Bloc", Vector3.new(1.03, 0.3411, 0.08), CFrame.new(0.5817, 0.6217, 0, 0, -0.7071, 0.7071, 0, 0.7071, 0.7071, -1, 0, 0)},
	{"Coque", "basalte", "Bloc", Vector3.new(1.03, 0.3411, 0.08), CFrame.new(-0.5817, 0.6217, 0, 0, 0.7071, -0.7071, 0, 0.7071, 0.7071, 1, 0, 0)},
	{"Coque", "basalte", "Bloc", Vector3.new(1.03, 0.3411, 0.08), CFrame.new(0, 0.6217, 0.5817, 1, 0, 0, 0, 0.7071, 0.7071, 0, -0.7071, 0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(1.03, 0.3411, 0.08), CFrame.new(0, 0.6217, -0.5817, -1, 0, 0, 0, 0.7071, 0.7071, 0, 0.7071, -0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.3411, 1.25, 0.08), CFrame.new(0.5817, -0.07, 0.5817, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.27, 0.27, 0.08), CFrame.new(0.5502, 0.5902, 0.5502, 0.7071, -0.4082, 0.5774, 0, 0.8165, 0.5774, -0.7071, -0.4082, 0.5774)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.3411, 1.25, 0.08), CFrame.new(0.5817, -0.07, -0.5817, -0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, -0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.27, 0.27, 0.08), CFrame.new(0.5502, 0.5902, -0.5502, -0.7071, -0.4082, 0.5774, 0, 0.8165, 0.5774, -0.7071, 0.4082, -0.5774)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.3411, 1.25, 0.08), CFrame.new(-0.5817, -0.07, 0.5817, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.27, 0.27, 0.08), CFrame.new(-0.5502, 0.5902, 0.5502, 0.7071, 0.4082, -0.5774, 0, 0.8165, 0.5774, 0.7071, -0.4082, 0.5774)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.3411, 1.25, 0.08), CFrame.new(-0.5817, -0.07, -0.5817, -0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, -0.7071)},
	{"Coque", "basalte", "Bloc", Vector3.new(0.27, 0.27, 0.08), CFrame.new(-0.5502, 0.5902, -0.5502, -0.7071, 0.4082, -0.5774, 0, 0.8165, 0.5774, 0.7071, 0.4082, -0.5774)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.99, 0.045), CFrame.new(0, 0.782, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 1.21, 0.045), CFrame.new(0.742, -0.07, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 1.21, 0.045), CFrame.new(-0.742, -0.07, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 1.21, 0.045), CFrame.new(0, -0.07, 0.742, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.3011, 0.045), CFrame.new(0.6256, 0.6656, 0, 0, -0.7071, 0.7071, 0, 0.7071, 0.7071, -1, 0, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.3011, 0.045), CFrame.new(-0.6256, 0.6656, 0, 0, 0.7071, -0.7071, 0, 0.7071, 0.7071, 1, 0, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.3011, 0.045), CFrame.new(0, 0.6656, 0.6256, 1, 0, 0, 0, 0.7071, 0.7071, 0, -0.7071, 0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.3011, 0.045), CFrame.new(0, 0.6656, -0.6256, -1, 0, 0, 0, 0.7071, 0.7071, 0, 0.7071, -0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.3011, 1.21, 0.045), CFrame.new(0.6256, -0.07, 0.6256, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.3011, 1.21, 0.045), CFrame.new(-0.6256, -0.07, 0.6256, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.3011, 1.21, 0.045), CFrame.new(0.6256, -0.07, -0.6256, -0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, -0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.3011, 1.21, 0.045), CFrame.new(-0.6256, -0.07, -0.6256, -0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, -0.7071)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.99, 0.32, 0.045), CFrame.new(0, 0.38, -0.742, -1, 0, 0, 0, 1, 0, 0, 0, -1)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4733, 0.4433, 0.0833), CFrame.new(0.2433, 0.8136, -0.2584, 0.997, -0.0016, -0.0769, 0.077, 0.0214, 0.9968, 0, -0.9998, 0.0214)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4733, 0.4767, 0.0915), CFrame.new(0.2433, 0.8177, 0.2416, 0.9967, -0.061, -0.054, 0.0478, -0.099, 0.9939, -0.066, -0.9932, -0.0958)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.4467, 0.5788, 0.1005), CFrame.new(-0.2567, 0.8222, 0.1906, 0.9928, -0.0402, 0.113, -0.1168, -0.1117, 0.9869, -0.0271, -0.9929, -0.1156)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4467, 0.3412, 0.0927), CFrame.new(-0.2567, 0.8183, -0.3094, 0.9925, -0.0241, -0.1202, 0.1178, -0.0836, 0.9895, -0.0339, -0.9962, -0.0801)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5041, 0.2074, 0.0787), CFrame.new(0.7714, 0.045, 0.228, -0.0464, 0.0758, 0.996, -0.0437, 0.996, -0.0778, -0.998, -0.0472, -0.0429)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5041, 0.3313, 0.0879), CFrame.new(0.776, 0.3544, 0.228, 0.0146, -0.0866, 0.9961, 0.035, 0.9957, 0.086, -0.9993, 0.0337, 0.0176)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4134, 0.5613, 0.1053), CFrame.new(0.7846, -0.3793, -0.2733, 0.1034, 0.0778, 0.9916, -0.0998, 0.9927, -0.0675, -0.9896, -0.092, 0.1105)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4159, 0.5787, 0.0768), CFrame.new(0.7704, 0.2307, -0.272, 0.1169, 0.0836, 0.9896, -0.0296, 0.9963, -0.0806, -0.9927, -0.0199, 0.119)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.5066, 0.1783, 0.1058), CFrame.new(0.7849, -0.5708, 0.2267, -0.1182, -0.0998, 0.988, -0.01, 0.995, 0.0993, -0.9929, 0.0019, -0.1186)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5066, 0.343, 0.0656), CFrame.new(0.7648, -0.2702, 0.2267, 0.0456, -0.0891, 0.995, -0.012, 0.9959, 0.0897, -0.9989, -0.016, 0.0444)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5119, 0.2384, 0.0715), CFrame.new(-0.7678, 0.4008, -0.2241, 0.057, 0.0671, -0.9961, -0.0775, 0.995, 0.0626, 0.9954, 0.0737, 0.0619)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.5119, 0.3739, 0.0866), CFrame.new(-0.7753, 0.0546, -0.2241, -0.0167, 0.0502, -0.9986, -0.059, 0.9969, 0.0511, 0.9981, 0.0598, -0.0137)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.4085, 0.4877, 0.0904), CFrame.new(-0.7772, -0.4162, 0.2758, -0.0861, 0.0547, -0.9948, -0.0964, 0.9933, 0.063, 0.9916, 0.1014, -0.0802)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.5115, 0.4877, 0.1005), CFrame.new(-0.7822, -0.4162, -0.2242, 0.0596, -0.0797, -0.995, 0.0687, 0.9948, -0.0755, 0.9959, -0.0639, 0.0647)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.4081, 0.2452, 0.0997), CFrame.new(-0.7818, -0.0097, 0.2759, -0.0032, -0.0854, -0.9963, -0.0512, 0.9951, -0.0851, 0.9987, 0.0507, -0.0076)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4081, 0.3671, 0.0882), CFrame.new(-0.7761, 0.3365, 0.2759, -0.0171, 0.0332, -0.9993, -0.0142, 0.9993, 0.0334, 0.9998, 0.0147, -0.0167)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5167, 0.2404, 0.0728), CFrame.new(-0.2216, 0.3998, 0.7684, 0.9977, -0.049, -0.0462, 0.0471, 0.9981, -0.041, 0.0481, 0.0387, 0.9981)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.4174, 0.4357, 0.0798), CFrame.new(0.2713, -0.4422, 0.7719, 0.9957, -0.0578, -0.0728, 0.0642, 0.994, 0.0888, 0.0673, -0.0931, 0.9934)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5026, 0.4357, 0.0779), CFrame.new(-0.2287, -0.4422, 0.771, 0.9983, 0.05, 0.0284, -0.0477, 0.996, -0.0758, -0.0321, 0.0743, 0.9967)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5167, 0.4239, 0.0876), CFrame.new(-0.2216, 0.0277, 0.7758, 0.9988, -0.0342, 0.0342, 0.0313, 0.9961, 0.0829, -0.0369, -0.0818, 0.996)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4033, 0.2845, 0.0769), CFrame.new(0.2784, -0.0421, 0.7704, 0.9887, 0.087, 0.1223, -0.095, 0.9936, 0.0612, -0.1162, -0.0722, 0.9906)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.4033, 0.3799, 0.1095), CFrame.new(0.2784, 0.3301, 0.7868, 0.9958, 0.0128, 0.0906, -0.0104, 0.9996, -0.0273, -0.0909, 0.0263, 0.9955)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5736, 0.2711, 0.0943), CFrame.new(0.6518, 0.6918, 0.1932, 0.006, -0.6328, 0.7743, 0.0766, 0.7724, 0.6306, -0.997, 0.0555, 0.0531)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.3464, 0.2711, 0.1052), CFrame.new(0.6557, 0.6957, -0.3068, 0.0032, -0.6922, 0.7217, 0.1109, 0.7175, 0.6877, -0.9938, 0.0778, 0.0791)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.3662, 0.2711, 0.0945), CFrame.new(-0.6519, 0.6919, -0.2969, -0.0288, 0.7104, -0.7032, 0.0692, 0.7032, 0.7076, 0.9972, -0.0283, -0.0695)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5538, 0.2711, 0.1004), CFrame.new(-0.654, 0.694, 0.2031, -0.0438, 0.7062, -0.7066, 0.0474, 0.708, 0.7046, 0.9979, -0.0026, -0.0644)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.5883, 0.2711, 0.067), CFrame.new(-0.1859, 0.6822, 0.6422, 0.9911, 0.0989, -0.0888, -0.0227, 0.7843, 0.6199, 0.1309, -0.6124, 0.7796)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.3317, 0.2711, 0.0926), CFrame.new(0.3141, 0.6912, 0.6512, 0.9971, 0.0322, -0.0685, 0.0189, 0.7707, 0.6369, 0.0733, -0.6363, 0.7679)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.579, 0.2711, 0.1074), CFrame.new(0.1905, 0.6965, -0.6565, -0.9966, 0.0817, -0.0141, 0.0406, 0.6292, 0.7761, 0.0722, 0.7729, -0.6304)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.341, 0.2711, 0.0865), CFrame.new(-0.3095, 0.6891, -0.6491, -0.997, -0.0771, 0.0077, -0.0444, 0.6498, 0.7588, -0.0635, 0.7562, -0.6513)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.2711, 0.5834, 0.0745), CFrame.new(0.6448, -0.3683, 0.6448, 0.7518, 0.096, 0.6524, -0.1007, 0.9945, -0.0303, -0.6517, -0.0429, 0.7573)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.2711, 0.5566, 0.0799), CFrame.new(0.6467, 0.2417, 0.6467, 0.7134, 0.0634, 0.6979, 0.0285, 0.9924, -0.1194, -0.7002, 0.1051, 0.7062)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.2711, 0.4034, 0.0656), CFrame.new(-0.6417, -0.4583, 0.6417, 0.6418, -0.0159, -0.7667, -0.0263, 0.9987, -0.0427, 0.7664, 0.0476, 0.6406)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.2711, 0.7366, 0.0716), CFrame.new(-0.6438, 0.1517, 0.6438, 0.7465, 0.0229, -0.665, 0.0488, 0.9948, 0.0889, 0.6636, -0.0988, 0.7415)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.2711, 0.4256, 0.0707), CFrame.new(0.6435, -0.4472, -0.6435, -0.7059, 0.04, 0.7072, -0.0413, 0.9944, -0.0975, -0.7071, -0.098, -0.7002)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.2711, 0.7144, 0.065), CFrame.new(0.6415, 0.1628, -0.6415, -0.711, 0.0605, 0.7006, 0.0023, 0.9965, -0.0837, -0.7032, -0.0579, -0.7087)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.2711, 0.594, 0.0916), CFrame.new(-0.6509, -0.363, -0.6509, -0.679, 0.0853, -0.7292, 0.0643, 0.9963, 0.0567, 0.7314, -0.0084, -0.6819)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.2711, 0.546, 0.1054), CFrame.new(-0.6558, 0.247, -0.6558, -0.6851, -0.0726, -0.7248, -0.0645, 0.9972, -0.0388, 0.7256, 0.0202, -0.6879)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.27, 0.27, 0.0829), CFrame.new(0.6042, 0.6442, 0.6042, 0.6993, -0.5257, 0.4843, 0.0999, 0.7427, 0.6621, -0.7078, -0.4147, 0.5719)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.27, 0.27, 0.0791), CFrame.new(-0.6031, 0.6431, 0.6031, 0.7339, 0.493, -0.4673, -0.1106, 0.7654, 0.634, 0.6702, -0.4136, 0.6163)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.27, 0.27, 0.092), CFrame.new(0.6068, 0.6468, -0.6068, -0.6244, -0.5075, 0.5939, -0.0389, 0.7795, 0.6252, -0.7802, 0.3672, -0.5065)},
	{"Plaques", "roche", "Bloc", Vector3.new(0.27, 0.27, 0.0619), CFrame.new(-0.5981, 0.6381, -0.5981, -0.6946, 0.4855, -0.5309, 0.0395, 0.7626, 0.6457, 0.7183, 0.4276, -0.5488)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.58, 0.28, 0.2), CFrame.new(-0.28, 0.37, -0.82, 0.9703, 0.2366, -0.0503, -0.2419, 0.9491, -0.2017, 0, 0.2079, 0.9781)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.58, 0.28, 0.2), CFrame.new(0.28, 0.37, -0.82, 0.9703, -0.2366, 0.0503, 0.2419, 0.9491, -0.2017, 0, 0.2079, 0.9781)},
	{"Visiere", "visiere", "Bloc", Vector3.new(0.66, 0.9, 0.07), CFrame.new(-0.2929, -0.23, -0.7839, 0.9272, 0, 0.3746, 0, 1, 0, -0.3746, 0, 0.9272)},
	{"Visiere", "fente", "Bloc", Vector3.new(0.44, 0.1, 0.03), CFrame.new(-0.2708, 0.08, -0.836, 0.9069, 0.1928, 0.3746, -0.2079, 0.9781, 0, -0.3664, -0.0779, 0.9272)},
	{"Visiere", "yeux", "Bloc", Vector3.new(0.12, 0.05, 0.02), CFrame.new(-0.2189, 0.067, -0.8677, 0.9069, 0.1928, 0.3746, -0.2079, 0.9781, 0, -0.3664, -0.0779, 0.9272)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.035, 0.24, 0.02), CFrame.new(-0.1892, -0.11, -0.8744, 0.9249, -0.0647, 0.3746, 0.0698, 0.9976, 0, -0.3737, 0.0261, 0.9272)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.065, 0.065, 0.025), CFrame.new(-0.1799, -0.24, -0.8781, 0.6556, -0.6556, 0.3746, 0.7071, 0.7071, 0, -0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(-0.4983, -0.68, -0.7052, 0.6556, -0.6556, 0.3746, 0.7071, 0.7071, 0, -0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(-0.2944, -0.68, -0.7876, 0.6556, -0.6556, 0.3746, 0.7071, 0.7071, 0, -0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(-0.0904, -0.68, -0.8701, 0.6556, -0.6556, 0.3746, 0.7071, 0.7071, 0, -0.2649, 0.2649, 0.9272)},
	{"Visiere", "visiere", "Bloc", Vector3.new(0.66, 0.9, 0.07), CFrame.new(0.2929, -0.23, -0.7839, 0.9272, 0, -0.3746, 0, 1, 0, 0.3746, 0, 0.9272)},
	{"Visiere", "fente", "Bloc", Vector3.new(0.44, 0.1, 0.03), CFrame.new(0.2708, 0.08, -0.836, 0.9069, -0.1928, -0.3746, 0.2079, 0.9781, 0, 0.3664, -0.0779, 0.9272)},
	{"Visiere", "yeux", "Bloc", Vector3.new(0.12, 0.05, 0.02), CFrame.new(0.2189, 0.067, -0.8677, 0.9069, -0.1928, -0.3746, 0.2079, 0.9781, 0, 0.3664, -0.0779, 0.9272)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.035, 0.24, 0.02), CFrame.new(0.1892, -0.11, -0.8744, 0.9249, 0.0647, -0.3746, -0.0698, 0.9976, 0, 0.3737, 0.0261, 0.9272)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.065, 0.065, 0.025), CFrame.new(0.1799, -0.24, -0.8781, 0.6556, 0.6556, -0.3746, -0.7071, 0.7071, 0, 0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(0.4983, -0.68, -0.7052, 0.6556, 0.6556, -0.3746, -0.7071, 0.7071, 0, 0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(0.2944, -0.68, -0.7876, 0.6556, 0.6556, -0.3746, -0.7071, 0.7071, 0, 0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.12, 0.12, 0.06), CFrame.new(0.0904, -0.68, -0.8701, 0.6556, 0.6556, -0.3746, -0.7071, 0.7071, 0, 0.2649, 0.2649, 0.9272)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.08, 0.3, 0.1), CFrame.new(-0.05, -0.7437, -0.9731, 0, 0, 1, -0.2873, -0.9578, 0, 0.9578, -0.2873, 0)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.08, 0.3, 0.1), CFrame.new(0.05, -0.7437, -0.9731, 0, 0, -1, 0.2873, -0.9578, 0, -0.9578, -0.2873, 0)},
	{"Plaques", "obsidienne", "Bloc", Vector3.new(0.31, 0.31, 0.07), CFrame.new(0, 0.41, -0.92, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Cristal", "cristal", "Bloc", Vector3.new(0.22, 0.22, 0.1), CFrame.new(0, 0.41, -0.97, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1), "lumiere"},
	{"Cristal", "coeur", "Bloc", Vector3.new(0.115, 0.115, 0.06), CFrame.new(0, 0.41, -1.01, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Cristal", "cristal", "Bloc", Vector3.new(0.07, 0.07, 0.06), CFrame.new(0, 0.59, -0.95, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Cristal", "cristal", "Bloc", Vector3.new(0.06, 0.06, 0.06), CFrame.new(0, 0.24, -0.95, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"CorneG", "roche", "Bloc", Vector3.new(0.4105, 0.5485, 0.4105), CFrame.new(-0.7612, 0.3598, 0.0669, 0.1573, -0.9197, 0.3597, 0.6979, 0.3612, 0.6184, -0.6987, 0.1538, 0.6987)},
	{"CorneG", "roche", "Bloc", Vector3.new(0.3554, 0.5033, 0.3554), CFrame.new(-0.9416, 0.4721, 0.105, 0.3771, -0.7235, 0.5783, 0.6135, 0.6629, 0.4292, -0.6938, 0.193, 0.6938)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.4648, 0.06, 0.4648), CFrame.new(-0.8624, 0.3995, 0.0838, 0.2679, -0.8357, 0.4795, 0.6662, 0.5202, 0.5344, -0.696, 0.1762, 0.696)},
	{"CorneG", "roche", "Bloc", Vector3.new(0.3056, 0.4775, 0.3056), CFrame.new(-1.0755, 0.6442, 0.1519, 0.5443, -0.4694, 0.6953, 0.4779, 0.8547, 0.2029, -0.6895, 0.2218, 0.6895)},
	{"CorneG", "roche", "Bloc", Vector3.new(0.258, 0.462, 0.258), CFrame.new(-1.158, 0.8646, 0.2089, 0.6507, -0.2171, 0.7277, 0.3259, 0.9453, -0.0093, -0.6859, 0.2433, 0.6859)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.3433, 0.06, 0.3433), CFrame.new(-1.1302, 0.7438, 0.1778, 0.604, -0.3405, 0.7205, 0.4035, 0.9103, 0.092, -0.6873, 0.2352, 0.6873)},
	{"CorneG", "roche", "Bloc", Vector3.new(0.2117, 0.4518, 0.2117), CFrame.new(-1.1841, 1.1217, 0.2768, 0.7093, 0.0116, 0.7048, 0.1761, 0.9653, -0.193, -0.6826, 0.2611, 0.6826)},
	{"CorneG", "obsidienne", "Bloc", Vector3.new(0.1664, 0.445, 0.1664), CFrame.new(-1.149, 1.4041, 0.3569, 0.733, 0.2147, 0.6455, 0.0328, 0.9366, -0.3488, -0.6795, 0.2769, 0.6795)},
	{"CorneG", "obsidienne", "Bloc", Vector3.new(0.122, 0.4416, 0.122), CFrame.new(-1.0478, 1.7, 0.45, 0.729, 0.394, 0.5598, -0.1039, 0.872, -0.4784, -0.6766, 0.2907, 0.6766)},
	{"CorneG", "obsidienne", "Coin", Vector3.new(0.095, 0.34, 0.0475), CFrame.new(-0.9421, 1.9747, 0.5217, 0.729, 0.394, 0.5598, -0.1039, 0.872, -0.4784, -0.6766, 0.2907, 0.6766)},
	{"CorneG", "obsidienne", "Coin", Vector3.new(0.095, 0.34, 0.0475), CFrame.new(-0.9155, 1.952, 0.5539, -0.729, 0.394, -0.5598, 0.1039, 0.872, 0.4784, 0.6766, 0.2907, -0.6766)},
	{"CorneD", "roche", "Bloc", Vector3.new(0.3748, 0.4703, 0.3748), CFrame.new(0.7409, 0.3468, 0.0516, 0.235, 0.9491, 0.2096, -0.667, 0.3143, -0.6755, -0.707, 0.019, 0.707)},
	{"CorneD", "roche", "Bloc", Vector3.new(0.3279, 0.4256, 0.3279), CFrame.new(0.8849, 0.4252, 0.0584, 0.4828, 0.7722, 0.4131, -0.5186, 0.6322, -0.5757, -0.7057, 0.0637, 0.7057)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.4266, 0.06, 0.4266), CFrame.new(0.8218, 0.3736, 0.0532, 0.3641, 0.8774, 0.3124, -0.6069, 0.478, -0.635, -0.7065, 0.0416, 0.7065)},
	{"CorneD", "roche", "Bloc", Vector3.new(0.2854, 0.3998, 0.2854), CFrame.new(0.9937, 0.5488, 0.073, 0.6379, 0.5335, 0.5554, -0.3147, 0.8388, -0.4443, -0.7029, 0.1086, 0.7029)},
	{"CorneD", "roche", "Bloc", Vector3.new(0.2447, 0.3825, 0.2447), CFrame.new(1.0684, 0.7084, 0.0962, 0.7046, 0.3101, 0.6383, -0.1214, 0.9389, -0.322, -0.6992, 0.1494, 0.6992)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.323, 0.06, 0.323), CFrame.new(1.0394, 0.6207, 0.0823, 0.6797, 0.4203, 0.6012, -0.2159, 0.8979, -0.3836, -0.701, 0.1309, 0.701)},
	{"CorneD", "roche", "Bloc", Vector3.new(0.2053, 0.3672, 0.2053), CFrame.new(1.11, 0.8949, 0.1293, 0.7183, 0.125, 0.6844, 0.0421, 0.9741, -0.222, -0.6945, 0.1883, 0.6945)},
	{"CorneD", "obsidienne", "Bloc", Vector3.new(0.1667, 0.3502, 0.1667), CFrame.new(1.1196, 1.0993, 0.1732, 0.7021, -0.0282, 0.7115, 0.1821, 0.9731, -0.1411, -0.6884, 0.2287, 0.6884)},
	{"CorneD", "obsidienne", "Bloc", Vector3.new(0.1288, 0.33, 0.1288), CFrame.new(1.0983, 1.3124, 0.229, 0.6648, -0.1611, 0.7295, 0.3089, 0.9484, -0.0721, -0.6802, 0.2733, 0.6802)},
	{"CorneD", "obsidienne", "Coin", Vector3.new(0.1045, 0.34, 0.0523), CFrame.new(1.04, 1.5452, 0.2778, 0.6648, -0.1611, 0.7295, 0.3089, 0.9484, -0.0721, -0.6802, 0.2733, 0.6802)},
	{"CorneD", "obsidienne", "Coin", Vector3.new(0.1045, 0.34, 0.0523), CFrame.new(1.0781, 1.5414, 0.3133, -0.6648, -0.1611, -0.7295, -0.3089, 0.9484, 0.0721, 0.6802, 0.2733, -0.6802)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.32, 0.15), CFrame.new(0, 0.9666, -0.3155, 1, 0, 0, 0, 0.8944, -0.4472, 0, 0.4472, 0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.32, 0.15), CFrame.new(0, 0.8996, -0.1814, -1, 0, 0, 0, 0.8944, 0.4472, 0, 0.4472, -0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.46, 0.18), CFrame.new(0, 1.036, -0.0376, 1, 0, 0, 0, 0.8944, -0.4472, 0, 0.4472, 0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.46, 0.18), CFrame.new(0, 0.9555, 0.1234, -1, 0, 0, 0, 0.8944, 0.4472, 0, 0.4472, -0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.56, 0.2), CFrame.new(0, 1.0852, 0.2358, 1, 0, 0, 0, 0.8944, -0.4472, 0, 0.4472, 0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.56, 0.2), CFrame.new(0, 0.9957, 0.4147, -1, 0, 0, 0, 0.8944, 0.4472, 0, 0.4472, -0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.46, 0.17), CFrame.new(0, 1.0337, 0.4668, 1, 0, 0, 0, 0.8944, -0.4472, 0, 0.4472, 0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.12, 0.46, 0.17), CFrame.new(0, 0.9577, 0.6189, -1, 0, 0, 0, 0.8944, 0.4472, 0, 0.4472, -0.8944)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.11, 0.46, 0.17), CFrame.new(0, 0.0618, 0.9825, -1, 0, 0, 0, -0.2425, 0.9701, 0, 0.9701, 0.2425)},
	{"Pointes", "obsidienne", "Coin", Vector3.new(0.11, 0.46, 0.17), CFrame.new(0, 0.2267, 1.0237, 1, 0, 0, 0, -0.2425, -0.9701, 0, 0.9701, -0.2425)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(-0.3, -0.69, 0.78, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(0, -0.69, 0.79, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(0.3, -0.69, 0.78, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(-0.78, -0.69, 0.25, 0, 0, -1, 0.7071, 0.7071, 0, 0.7071, -0.7071, 0)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(-0.78, -0.69, -0.15, 0, 0, -1, 0.7071, 0.7071, 0, 0.7071, -0.7071, 0)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(0.78, -0.69, 0.25, 0, 0, 1, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0)},
	{"Pointes", "obsidienne", "Bloc", Vector3.new(0.17, 0.17, 0.07), CFrame.new(0.78, -0.69, -0.15, 0, 0, 1, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.4, 0.02), CFrame.new(-0.835, -0.29, 0.14, 0, 0, -1, 0.1219, 0.9925, 0, 0.9925, -0.1219, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.07, 0.07, 0.025), CFrame.new(-0.835, -0.49, 0.1644, 0, 0, -1, 0.7071, 0.7071, 0, 0.7071, -0.7071, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.34, 0.02), CFrame.new(0.835, -0.37, 0.2, 0, 0, 1, -0.1045, 0.9945, 0, -0.9945, -0.1045, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.07, 0.07, 0.025), CFrame.new(0.835, -0.54, 0.2178, 0, 0, 1, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.04, 0.36, 0.02), CFrame.new(0.26, -0.37, 0.835, 0.9962, -0.0872, 0, 0.0872, 0.9962, 0, 0, 0, 1)},
	{"Fissures", "magma", "Bloc", Vector3.new(0.07, 0.07, 0.025), CFrame.new(0.2757, -0.55, 0.835, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1)},
	{"Eclats", "roche", "Bloc", Vector3.new(0.15, 0.1704, 0.1291), CFrame.new(-1.12, 0.12, 0.28, 0.5067, -0.8296, 0.2347, 0.8049, 0.3577, -0.4734, 0.3088, 0.4288, 0.849)},
	{"Eclats", "obsidienne", "Bloc", Vector3.new(0.1, 0.1119, 0.083), CFrame.new(-1, -0.42, -0.18, 0.6959, -0.7124, 0.091, 0.6351, 0.5513, -0.5411, 0.3353, 0.4343, 0.836)},
	{"Eclats", "obsidienne", "Bloc", Vector3.new(0.13, 0.1967, 0.0958), CFrame.new(1.08, 0, 0.36, 0.7778, -0.6122, 0.142, 0.627, 0.7714, -0.1084, -0.0432, 0.1734, 0.9839)},
	{"Eclats", "magma", "Bloc", Vector3.new(0.09, 0.125, 0.0737), CFrame.new(1.3, 0.62, -0.1, 0.0453, -0.5505, 0.8336, 0.9595, -0.2083, -0.1898, 0.2781, 0.8084, 0.5188)},
	{"Eclats", "roche", "Bloc", Vector3.new(0.1, 0.1245, 0.0743), CFrame.new(0.42, 1.08, 0.66, 0.2199, -0.9728, 0.0731, 0.0525, -0.063, -0.9966, 0.9741, 0.223, 0.0372)},
	{"Eclats", "magma", "Bloc", Vector3.new(0.08, 0.0952, 0.07), CFrame.new(-0.5, 1, -0.62, 0.252, -0.8482, 0.4658, 0.9666, 0.1978, -0.1628, 0.0459, 0.4913, 0.8698)},
}

local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function braises(parent: BasePart)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Braises"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 176, 64), Color3.fromRGB(210, 40, 10))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 6
	e.Lifetime = NumberRange.new(1.2, 2.2)
	e.Speed = NumberRange.new(0.25, 0.6)
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0, 0.5, 0)
	e.Drag = 0.6
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.4, 0.09),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Parent = parent
end

local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "CasqueMagma"
	modele:SetAttribute("NomAffiche", "Casque du Cœur Magmatique")
	modele:SetAttribute("Rarete", "Unique")

	local racine = Instance.new("Part")
	racine.Name = "Racine"
	racine.Size = Vector3.new(0.2, 0.2, 0.2)
	racine.CFrame = CFrame.identity
	racine.Transparency = 1
	racine.CastShadow = false
	racine.Anchored = false
	racine.CanCollide, racine.CanQuery, racine.CanTouch = false, false, false
	racine.Massless = true
	racine.Parent = modele
	modele.PrimaryPart = racine

	local lumiereFaite, braisesFaites = false, false
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6]
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
		if marque == "lumiere" and not lumiereFaite then
			lumiereFaite = true
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 130, 40)
			l.Range = 8
			l.Brightness = 1.5
			l.Shadows = false
			l.Parent = p
		elseif marque == "braises" and not braisesFaites then
			braisesFaites = true
			braises(p)
		end
		p.Parent = modele
		local w = Instance.new("WeldConstraint")
		w.Part0 = racine
		w.Part1 = p
		w.Parent = p
	end
	return modele
end

return {
	Nom = "Casque du Cœur Magmatique",
	Format = "Code",
	Taille = Vector3.new(2.7531, 3.0154, 2.2808),
	Centre = Vector3.new(-0.0094, 0.6088, 0.0859), -- centre de la boîte englobante dans le repère de la tête
	construire = construire,
}
