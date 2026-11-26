-- Généré par blender/armes/armures_minerais.py (91 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières d'orichalque : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresOrichalque.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["or"] = {"Metal", 232, 172, 52, 0.2},
	["or2"] = {"Metal", 204, 142, 38, 0.15},
	["or3"] = {"Metal", 250, 206, 100, 0.25},
	["bronze"] = {"Metal", 104, 74, 54, 0.05},
	["gemme"] = {"Neon", 255, 214, 60, 0},
	["cuir"] = {"Fabric", 92, 60, 36, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "or", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeD"},
	{"Cuissard", "or3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "or2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "or3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "or2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Greve", "or2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Greve", "or3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "or2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Mollet", "or", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 1, 0, 0, 0, 0.9986, -0.0523, 0, 0.0523, 0.9986), "JambeD"},
	{"Cheville", "or3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Incrustation", "bronze", "Bloc", Vector3.new(0.5, 0.5, 0.06), CFrame.new(0.5, -0.5, -0.62, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Soleil", "bronze", "Bloc", Vector3.new(0.3, 0.3, 0.06), CFrame.new(0.5, 0.02, -0.74, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(0.435, 0.0995, -0.735, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(0.565, 0.0995, -0.735, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(0.435, -0.0595, -0.735, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(0.565, -0.0595, -0.735, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(0.5071, 0.0741, -0.7982, -0.4729, 0.6054, -0.6402, 0.3941, -0.5045, -0.7682, -0.7881, -0.6155, 0), "JambeD", "lumiere"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(0.4571, 0.0141, -0.7982, 0.4729, 0.6054, 0.6402, -0.3941, -0.5045, 0.7682, 0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(0.4571, 0.0259, -0.7982, -0.4729, 0.6054, 0.6402, -0.3941, 0.5045, -0.7682, -0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(0.5071, -0.0341, -0.7982, 0.4729, 0.6054, -0.6402, 0.3941, 0.5045, 0.7682, 0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(0.4929, -0.0341, -0.7982, 0.4729, -0.6054, 0.6402, -0.3941, 0.5045, 0.7682, -0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(0.5429, 0.0259, -0.7982, -0.4729, -0.6054, -0.6402, 0.3941, 0.5045, -0.7682, 0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(0.5429, 0.0141, -0.7982, 0.4729, -0.6054, -0.6402, 0.3941, -0.5045, 0.7682, -0.7881, -0.6155, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(0.4929, 0.0741, -0.7982, -0.4729, -0.6054, 0.6402, -0.3941, -0.5045, -0.7682, 0.7881, -0.6155, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.745, 0.1326, -0.7557, 0.1698, 0.8492, -0.5, 0.0981, 0.4903, 0.866, 0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.72, 0.1759, -0.7557, -0.1698, 0.8492, 0.5, -0.0981, 0.4903, -0.866, -0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.6559, 0.24, -0.7557, 0.0981, 0.4903, -0.866, 0.1698, 0.8492, 0.5, 0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.6126, 0.265, -0.7557, -0.0981, 0.4903, 0.866, -0.1698, 0.8492, -0.5, -0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.525, 0.2884, -0.7557, 0, 0, -1, 0.1961, 0.9806, 0, 0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.475, 0.2884, -0.7557, 0, 0, 1, -0.1961, 0.9806, 0, -0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.3874, 0.265, -0.7557, -0.0981, -0.4903, -0.866, 0.1698, 0.8492, -0.5, 0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.3441, 0.24, -0.7557, 0.0981, -0.4903, 0.866, -0.1698, 0.8492, 0.5, -0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.28, 0.1759, -0.7557, -0.1698, -0.8492, -0.5, 0.0981, 0.4903, -0.866, 0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0.255, 0.1326, -0.7557, 0.1698, -0.8492, 0.5, -0.0981, 0.4903, 0.866, -0.9806, -0.1961, 0), "JambeD"},
	{"Rayons", "or3", "Bloc", Vector3.new(0.14, 0.206, 0.14), CFrame.new(1.1466, 0.5689, 0, 0.473, 0.7433, 0.473, -0.5256, 0.669, -0.5256, -0.7071, 0, 0.7071), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(1.2742, 0.691, -0.0441, -0.7382, -0.621, -0.2635, 0.2017, 0.1696, -0.9647, 0.6437, -0.7653, 0), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(1.25, 0.6027, -0.0441, 0.7382, -0.621, 0.2635, -0.2017, 0.1696, 0.9647, -0.6437, -0.7653, 0), "JambeD"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(1.2483, 0.7198, 0.0054, 0.1231, -0.7707, -0.6253, -0.7553, 0.336, -0.5627, 0.6437, 0.5415, -0.5407), "JambeD"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(1.191, 0.6683, -0.0441, -0.1231, -0.7707, 0.6253, 0.7553, 0.336, 0.5627, -0.6437, 0.5415, 0.5407), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(1.191, 0.6683, 0.0441, 0.1231, -0.7707, 0.6253, -0.7553, 0.336, 0.5627, -0.6437, -0.5415, -0.5407), "JambeD"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(1.2483, 0.7198, -0.0054, -0.1231, -0.7707, -0.6253, 0.7553, 0.336, -0.5627, 0.6437, -0.5415, 0.5407), "JambeD"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(1.25, 0.6027, 0.0441, -0.7382, -0.621, 0.2635, 0.2017, 0.1696, 0.9647, -0.6437, 0.7653, 0), "JambeD"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(1.2742, 0.691, 0.0441, 0.7382, -0.621, -0.2635, -0.2017, 0.1696, -0.9647, 0.6437, 0.7653, 0), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "or", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeG"},
	{"Cuissard", "or3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "or2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "or3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "or2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Greve", "or2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Greve", "or3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "or2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Mollet", "or", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 1, 0, 0, 0, 0.9986, -0.0523, 0, 0.0523, 0.9986), "JambeG"},
	{"Cheville", "or3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Incrustation", "bronze", "Bloc", Vector3.new(0.5, 0.5, 0.06), CFrame.new(-0.5, -0.5, -0.62, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Soleil", "bronze", "Bloc", Vector3.new(0.3, 0.3, 0.06), CFrame.new(-0.5, 0.02, -0.74, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(-0.435, 0.0995, -0.735, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(-0.565, 0.0995, -0.735, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(-0.435, -0.0595, -0.735, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "or3", "Coin", Vector3.new(0.07, 0.159, 0.13), CFrame.new(-0.565, -0.0595, -0.735, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(-0.5071, 0.0741, -0.7982, -0.4729, -0.6054, 0.6402, -0.3941, -0.5045, -0.7682, 0.7881, -0.6155, 0), "JambeG", "lumiere"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(-0.4571, 0.0141, -0.7982, 0.4729, -0.6054, -0.6402, 0.3941, -0.5045, 0.7682, -0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(-0.4571, 0.0259, -0.7982, -0.4729, -0.6054, -0.6402, 0.3941, 0.5045, -0.7682, 0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(-0.5071, -0.0341, -0.7982, 0.4729, -0.6054, 0.6402, -0.3941, 0.5045, 0.7682, -0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(-0.4929, -0.0341, -0.7982, 0.4729, 0.6054, -0.6402, 0.3941, 0.5045, 0.7682, 0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(-0.5429, 0.0259, -0.7982, -0.4729, 0.6054, 0.6402, -0.3941, 0.5045, -0.7682, -0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.064), CFrame.new(-0.5429, 0.0141, -0.7982, 0.4729, 0.6054, 0.6402, -0.3941, -0.5045, 0.7682, 0.7881, -0.6155, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0975, 0.0922), CFrame.new(-0.4929, 0.0741, -0.7982, -0.4729, 0.6054, -0.6402, 0.3941, -0.5045, -0.7682, -0.7881, -0.6155, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.745, 0.1326, -0.7557, 0.1698, -0.8492, 0.5, -0.0981, 0.4903, 0.866, -0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.72, 0.1759, -0.7557, -0.1698, -0.8492, -0.5, 0.0981, 0.4903, -0.866, 0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.6559, 0.24, -0.7557, 0.0981, -0.4903, 0.866, -0.1698, 0.8492, 0.5, -0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.6126, 0.265, -0.7557, -0.0981, -0.4903, -0.866, 0.1698, 0.8492, -0.5, 0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.525, 0.2884, -0.7557, 0, 0, 1, -0.1961, 0.9806, 0, -0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.475, 0.2884, -0.7557, 0, 0, -1, 0.1961, 0.9806, 0, 0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.3874, 0.265, -0.7557, -0.0981, 0.4903, 0.866, -0.1698, 0.8492, -0.5, -0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.3441, 0.24, -0.7557, 0.0981, 0.4903, -0.866, 0.1698, 0.8492, 0.5, 0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.28, 0.1759, -0.7557, -0.1698, 0.8492, 0.5, -0.0981, 0.4903, -0.866, -0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.05, 0.16, 0.05), CFrame.new(-0.255, 0.1326, -0.7557, 0.1698, 0.8492, -0.5, 0.0981, 0.4903, 0.866, 0.9806, -0.1961, 0), "JambeG"},
	{"Rayons", "or3", "Bloc", Vector3.new(0.14, 0.206, 0.14), CFrame.new(-1.1466, 0.5689, 0, 0.473, -0.7433, -0.473, 0.5256, 0.669, -0.5256, 0.7071, 0, 0.7071), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(-1.2742, 0.691, -0.0441, -0.7382, 0.621, 0.2635, -0.2017, 0.1696, -0.9647, -0.6437, -0.7653, 0), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(-1.25, 0.6027, -0.0441, 0.7382, 0.621, -0.2635, 0.2017, 0.1696, 0.9647, 0.6437, -0.7653, 0), "JambeG"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(-1.2483, 0.7198, 0.0054, 0.1231, 0.7707, 0.6253, 0.7553, 0.336, -0.5627, -0.6437, 0.5415, -0.5407), "JambeG"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(-1.191, 0.6683, -0.0441, -0.1231, 0.7707, -0.6253, -0.7553, 0.336, 0.5627, 0.6437, 0.5415, 0.5407), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(-1.191, 0.6683, 0.0441, 0.1231, 0.7707, -0.6253, 0.7553, 0.336, 0.5627, 0.6437, -0.5415, -0.5407), "JambeG"},
	{"Rayons", "or3", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(-1.2483, 0.7198, -0.0054, -0.1231, 0.7707, 0.6253, -0.7553, 0.336, -0.5627, -0.6437, -0.5415, 0.5407), "JambeG"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.0535), CFrame.new(-1.25, 0.6027, 0.0441, -0.7382, 0.621, -0.2635, -0.2017, 0.1696, 0.9647, 0.6437, 0.7653, 0), "JambeG"},
	{"Rayons", "or", "Coin", Vector3.new(0.0168, 0.1294, 0.1295), CFrame.new(-1.2742, 0.691, 0.0441, 0.7382, 0.621, 0.2635, 0.2017, 0.1696, -0.9647, -0.6437, 0.7653, 0), "JambeG"},
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
	modele.Name = "JambieresOrichalque"
	modele:SetAttribute("NomAffiche", "Jambières d'orichalque")

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
			l.Color = Color3.fromRGB(255, 210, 80)
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
	Nom = "Jambières d'orichalque",
	Format = "Code",
	Taille = Vector3.new(2.6793, 1.99, 1.4993),
	Centre = Vector3.new(0, 0.005, -0.0904), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
