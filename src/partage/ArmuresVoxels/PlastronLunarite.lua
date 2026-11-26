-- Généré par blender/armes/armures_minerais.py (83 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron de lunarite : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronLunarite.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["lune"] = {"SmoothPlastic", 176, 158, 228, 0.12},
	["lune2"] = {"SmoothPlastic", 150, 132, 210, 0.12},
	["lune3"] = {"SmoothPlastic", 204, 188, 240, 0.15},
	["argent"] = {"Metal", 214, 206, 214, 0.15},
	["gemme"] = {"Neon", 190, 150, 255, 0},
	["cuir"] = {"Fabric", 128, 128, 144, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "lune3", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9738, 0.025, -0.226, -0.0243, 0.9997, 0.0057, 0.226, 0, 0.9741)},
	{"Liseré", "argent", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "lune3", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9751, -0.031, 0.2195, 0.027, 0.9994, 0.0213, -0.2201, -0.0148, 0.9754)},
	{"Liseré", "argent", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "argent", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "lune2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9936, 0.0016, -0.1125, -0.0137, 0.9942, -0.1066, 0.1117, 0.1074, 0.9879)},
	{"Lames", "lune3", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9873, 0.0367, 0.1544, -0.0119, 0.9872, -0.1589, -0.1583, 0.155, 0.9751)},
	{"Lames", "lune", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.989, -0.0552, -0.137, 0.0343, 0.9881, -0.15, 0.1437, 0.1437, 0.9791)},
	{"Lames", "lune", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9861, 0.0524, 0.1578, -0.0249, 0.9849, -0.1715, -0.1644, 0.1652, 0.9725)},
	{"Lames", "lune2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9876, -0.0052, -0.1571, -0.0154, 0.9914, -0.1297, 0.1564, 0.1306, 0.979)},
	{"Lames", "lune2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9929, 0.0471, 0.1092, -0.0322, 0.9904, -0.1347, -0.1145, 0.1302, 0.9848)},
	{"Flanc", "lune3", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, -0.0036, -0.0332, 0.9994, -0.0176, 0.9993, 0.0331, -0.9998, -0.0175, -0.0042)},
	{"Flanc", "lune2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0.0005, 0.0192, -0.9998, 0.0123, 0.9997, 0.0192, 0.9999, -0.0123, 0.0002)},
	{"Dossiere", "lune3", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -1, -0.0008, -0.0002, -0.0008, 0.9995, -0.0311, 0.0002, -0.0311, -0.9995)},
	{"Dossiere", "argent", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "lune2", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 0.9998, -0.0201, 0.0023, 0.0197, 0.9916, 0.1277, -0.0048, -0.1276, 0.9918)},
	{"Dossiere", "lune", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 0.9996, 0.014, -0.0249, -0.0113, 0.9943, 0.1062, 0.0263, -0.1059, 0.994)},
	{"Dossiere", "lune", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 0.9994, 0.0315, -0.0135, -0.0288, 0.9856, 0.1665, 0.0186, -0.1661, 0.9859)},
	{"Col", "argent", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "argent", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "argent", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "argent", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "lune3", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9887, 0.1456, -0.0361, -0.1464, 0.989, -0.0196, 0.0329, 0.0246, 0.9992)},
	{"Epauliere", "lune2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.868, 0.4961, -0.0216, -0.496, 0.8682, 0.0102, 0.0238, 0.0018, 0.9997)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "lune", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9921, 0.1222, 0.0266, -0.1229, 0.9921, 0.0266, -0.0231, -0.0297, 0.9993)},
	{"Epauliere", "lune", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9857, -0.1661, 0.0298, 0.1663, 0.9861, -0.004, -0.0287, 0.0089, 0.9995)},
	{"Epauliere", "lune2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8891, -0.4569, -0.0286, 0.4572, 0.8894, 0.0038, 0.0237, -0.0164, 0.9996)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "lune2", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9888, -0.149, 0.0062, 0.149, 0.9888, 0.0001, -0.0062, 0.0008, 1)},
	{"Ceinture", "argent", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "lune3", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "lune2", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 0.9997, 0.0061, 0.0257, -0.0041, 0.997, -0.0771, -0.026, 0.077, 0.9967)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "lune", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 0.9996, 0.0206, -0.0189, -0.0228, 0.9923, -0.1221, 0.0162, 0.1225, 0.9923)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0782, 0.2403, 0.08), CFrame.new(0.0168, 0.7875, -0.9, -0.0087, 1, 0, 1, 0.0087, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1317, 0.2403, 0.08), CFrame.new(0.1826, 0.7195, -0.9, 0.4772, 0.8788, 0, 0.8788, -0.4772, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1773, 0.2403, 0.08), CFrame.new(0.2882, 0.5909, -0.9, 0.8434, 0.5373, 0, 0.5373, -0.8434, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.2104, 0.2403, 0.08), CFrame.new(0.3209, 0.4384, -0.9, 0.9981, 0.061, 0, 0.061, -0.9981, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.2278, 0.2403, 0.08), CFrame.new(0.2842, 0.294, -0.9, 0.9026, -0.4305, 0, -0.4305, -0.9026, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.2278, 0.2403, 0.08), CFrame.new(0.19, 0.1817, -0.9, 0.5807, -0.8141, 0, -0.8141, -0.5807, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.2104, 0.2403, 0.08), CFrame.new(0.0541, 0.1205, -0.9, 0.1132, -0.9936, 0, -0.9936, -0.1132, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1773, 0.2403, 0.08), CFrame.new(-0.1017, 0.1262, -0.9, -0.3827, -0.9239, 0, -0.9239, 0.3827, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.1317, 0.2403, 0.08), CFrame.new(-0.2467, 0.2079, -0.9, -0.7826, -0.6225, 0, -0.6225, 0.7826, 0, 0, 0, -1)},
	{"Croissant", "argent", "Bloc", Vector3.new(0.0782, 0.2403, 0.08), CFrame.new(-0.3425, 0.3593, -0.9, -0.9863, -0.165, 0, -0.165, 0.9863, 0, 0, 0, -1)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.149, 0.11), CFrame.new(0.065, 0.5945, -0.845, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.149, 0.11), CFrame.new(0.175, 0.5945, -0.845, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.149, 0.11), CFrame.new(0.065, 0.4455, -0.845, 0, 0, 1, 0, -1, 0, 1, 0, 0)},
	{"Gemme", "argent", "Coin", Vector3.new(0.07, 0.149, 0.11), CFrame.new(0.175, 0.4455, -0.845, 0, 0, -1, 0, -1, 0, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.089), CFrame.new(0.1272, 0.5697, -0.902, -0.4819, 0.6495, -0.5882, 0.3504, -0.4724, -0.8087, -0.8031, -0.5958, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.0471), CFrame.new(0.0872, 0.5147, -0.902, 0.4819, 0.6495, 0.5882, -0.3504, -0.4724, 0.8087, 0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.0471), CFrame.new(0.0872, 0.5253, -0.902, -0.4819, 0.6495, 0.5882, -0.3504, 0.4724, -0.8087, -0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.089), CFrame.new(0.1272, 0.4703, -0.902, 0.4819, 0.6495, -0.5882, 0.3504, 0.4724, 0.8087, 0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.089), CFrame.new(0.1128, 0.4703, -0.902, 0.4819, -0.6495, 0.5882, -0.3504, 0.4724, 0.8087, -0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.0471), CFrame.new(0.1528, 0.5253, -0.902, -0.4819, -0.6495, -0.5882, 0.3504, 0.4724, -0.8087, 0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.0471), CFrame.new(0.1528, 0.5147, -0.902, 0.4819, -0.6495, -0.5882, 0.3504, -0.4724, 0.8087, -0.8031, -0.5958, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.0806, 0.089), CFrame.new(0.1128, 0.5697, -0.902, -0.4819, -0.6495, 0.5882, -0.3504, -0.4724, -0.8087, 0.8031, -0.5958, 0)},
	{"Cristaux", "lune3", "Bloc", Vector3.new(0.2, 0.264, 0.2), CFrame.new(1.3487, 1.04, 0.0098, 0.512, 0.7412, 0.4341, -0.4905, 0.6671, -0.5607, -0.7052, 0.0741, 0.7052)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(1.4884, 1.081, -0.0436, -0.776, 0.223, 0.59, 0.1649, -0.8312, 0.531, 0.6088, 0.5093, 0.6083)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(1.5646, 1.1496, 0.0349, 0.776, 0.223, -0.59, -0.1649, -0.8312, -0.531, -0.6088, 0.5093, -0.6083)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(1.4041, 1.1747, -0.0436, 0.0825, 0.1408, 0.9866, -0.789, -0.5955, 0.151, 0.6088, -0.7909, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(1.5315, 1.1942, -0.0356, -0.0825, 0.1408, -0.9866, 0.789, -0.5955, -0.151, -0.6088, -0.7909, -0.062)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(1.5245, 1.1879, 0.09, 0.1532, 0.0563, -0.9866, -0.7254, -0.6716, -0.151, -0.6711, 0.7388, -0.062)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(1.3972, 1.1684, 0.082, -0.1532, 0.0563, 0.9866, 0.7254, -0.6716, 0.151, 0.6711, 0.7388, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(1.4815, 1.0748, 0.082, -0.7053, -0.6619, 0.2537, 0.2285, 0.1265, 0.9653, -0.6711, 0.7388, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(1.5142, 1.1994, 0.09, 0.7053, -0.6619, -0.2537, -0.2285, 0.1265, -0.9653, 0.6711, 0.7388, -0.062)},
	{"Etoiles", "argent", "Bloc", Vector3.new(0.12, 0.12, 0.04), CFrame.new(0.6283, -0.4416, -0.6792, -0.7139, 0.6865, 0.1378, 0.7002, 0.7002, 0.1392, -0.001, 0.1959, -0.9806)},
	{"Etoiles", "argent", "Bloc", Vector3.new(0.07, 0.07, 0.05), CFrame.new(0.6283, -0.4416, -0.6892, -0.0096, 0.9904, 0.1378, 0.9902, -0.0098, 0.1392, 0.1392, 0.1378, -0.9806)},
	{"Cristaux", "lune3", "Bloc", Vector3.new(0.2, 0.264, 0.2), CFrame.new(-1.3487, 1.04, 0.0098, 0.4341, -0.7412, 0.512, 0.5607, 0.6671, 0.4905, -0.7052, 0.0741, 0.7052)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(-1.5315, 1.1942, -0.0356, -0.0825, -0.1408, 0.9866, -0.789, -0.5955, -0.151, 0.6088, -0.7909, -0.062)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(-1.4041, 1.1747, -0.0436, 0.0825, -0.1408, -0.9866, 0.789, -0.5955, 0.151, -0.6088, -0.7909, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(-1.5646, 1.1496, 0.0349, 0.776, -0.223, 0.59, 0.1649, -0.8312, -0.531, 0.6088, 0.5093, -0.6083)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(-1.4884, 1.081, -0.0436, -0.776, -0.223, -0.59, -0.1649, -0.8312, 0.531, -0.6088, 0.5093, 0.6083)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(-1.5142, 1.1994, 0.09, 0.7053, 0.6619, 0.2537, 0.2285, 0.1265, -0.9653, -0.6711, 0.7388, -0.062)},
	{"Cristaux", "lune3", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(-1.4815, 1.0748, 0.082, -0.7053, 0.6619, -0.2537, -0.2285, 0.1265, 0.9653, 0.6711, 0.7388, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.0775), CFrame.new(-1.3972, 1.1684, 0.082, -0.1532, -0.0563, -0.9866, -0.7254, -0.6716, 0.151, -0.6711, 0.7388, 0.062)},
	{"Cristaux", "lune", "Coin", Vector3.new(0.024, 0.1844, 0.1807), CFrame.new(-1.5245, 1.1879, 0.09, 0.1532, -0.0563, 0.9866, 0.7254, -0.6716, -0.151, 0.6711, 0.7388, -0.062)},
	{"Etoiles", "argent", "Bloc", Vector3.new(0.12, 0.12, 0.04), CFrame.new(-0.6283, -0.4416, -0.6792, -0.6865, 0.7139, -0.1378, 0.7002, 0.7002, 0.1392, 0.1959, -0.001, -0.9806)},
	{"Etoiles", "argent", "Bloc", Vector3.new(0.07, 0.07, 0.05), CFrame.new(-0.6283, -0.4416, -0.6892, 0.0098, 0.9904, -0.1378, 0.9902, 0.0096, 0.1392, 0.1392, -0.1378, -0.9806)},
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
	modele.Name = "PlastronLunarite"
	modele:SetAttribute("NomAffiche", "Plastron de lunarite")

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
			l.Color = Color3.fromRGB(200, 170, 255)
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
	Nom = "Plastron de lunarite",
	Format = "Code",
	Taille = Vector3.new(4.3168, 2.5138, 1.7083),
	Centre = Vector3.new(0.003, 0.0208, -0.0858), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
