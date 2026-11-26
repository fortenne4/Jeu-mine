-- Généré par blender/armes/armures_minerais.py (73 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de rubis : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresRubis.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["grenat"] = {"SmoothPlastic", 96, 40, 52, 0.08},
	["grenat2"] = {"SmoothPlastic", 78, 32, 44, 0.08},
	["bronze"] = {"Metal", 130, 96, 84, 0.08},
	["rubis"] = {"SmoothPlastic", 210, 34, 76, 0.15},
	["rubis2"] = {"SmoothPlastic", 172, 24, 60, 0.15},
	["gemme"] = {"Neon", 255, 50, 100, 0},
	["cuir"] = {"Fabric", 92, 56, 38, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "grenat", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9996, -0.0091, 0.0252, 0.0105, 0.9982, -0.0582, -0.0247, 0.0585, 0.998), "JambeD"},
	{"Cuissard", "bronze", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "grenat2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0.0073, -0.0349, 0.9994, 0.0076, 0.9994, 0.0349, -0.9999, 0.0074, 0.0076), "JambeD"},
	{"Genouillere", "bronze", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "grenat", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9989, -0.0342, -0.0328, 0.035, 0.9991, 0.0258, 0.0319, -0.0269, 0.9991), "JambeD"},
	{"Greve", "grenat2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9997, -0.024, -0.0056, 0.0244, 0.9961, 0.0847, 0.0035, -0.0848, 0.9964), "JambeD"},
	{"Greve", "bronze", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "grenat2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0305, -0.0212, 0.9993, 0.0275, 0.9994, 0.0204, -0.9992, 0.0268, 0.0311), "JambeD"},
	{"Mollet", "grenat", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9994, 0.0344, 0.0031, -0.0342, 0.9983, -0.0468, -0.0047, 0.0467, 0.9989), "JambeD"},
	{"Cheville", "bronze", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(0.28, 0.66, -0.64, 0.9989, 0.0354, -0.0295, -0.0407, 0.9777, -0.2062, 0.0215, 0.2071, 0.9781), "JambeD"},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(0.72, 0.66, -0.64, 0.9988, 0.0425, 0.0246, -0.037, 0.9802, -0.1945, -0.0323, 0.1934, 0.9806), "JambeD"},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(0.5, 0.42, -0.64, 0.9998, 0.0123, 0.0174, -0.0094, 0.9876, -0.1566, -0.0191, 0.1564, 0.9875), "JambeD"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(0.435, 0.1275, -0.705, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(0.565, 0.1275, -0.705, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(0.435, -0.0875, -0.705, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeD"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(0.565, -0.0875, -0.705, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(0.5074, 0.091, -0.7616, -0.4962, 0.7296, -0.4706, 0.2646, -0.3891, -0.8824, -0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(0.4674, 0.016, -0.7616, 0.4962, 0.7296, 0.4706, -0.2646, -0.3891, 0.8824, 0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(0.4674, 0.024, -0.7616, -0.4962, 0.7296, 0.4706, -0.2646, 0.3891, -0.8824, -0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(0.5074, -0.051, -0.7616, 0.4962, 0.7296, -0.4706, 0.2646, 0.3891, 0.8824, 0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(0.4926, -0.051, -0.7616, 0.4962, -0.7296, 0.4706, -0.2646, 0.3891, 0.8824, -0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(0.5326, 0.024, -0.7616, -0.4962, -0.7296, -0.4706, 0.2646, 0.3891, -0.8824, 0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(0.5326, 0.016, -0.7616, 0.4962, -0.7296, -0.4706, 0.2646, -0.3891, 0.8824, -0.8269, -0.5623, 0), "JambeD"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(0.4926, 0.091, -0.7616, -0.4962, -0.7296, 0.4706, -0.2646, -0.3891, -0.8824, 0.8269, -0.5623, 0), "JambeD"},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.18, 0.209, 0.18), CFrame.new(1.1479, 0.1623, -0.1688, 0.6063, 0.7454, 0.2771, -0.4205, 0.5963, -0.6839, -0.6749, 0.2981, 0.6749), "JambeD"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(1.2948, 0.2885, -0.168, -0.8837, -0.4104, -0.2249, 0.0944, 0.3145, -0.9446, 0.4584, -0.856, -0.2392), "JambeD"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(1.2708, 0.1878, -0.1935, 0.8837, -0.4104, 0.2249, -0.0944, 0.3145, 0.9446, -0.4584, -0.856, 0.2392), "JambeD"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(1.2487, 0.3158, -0.1072, -0.1019, -0.8826, -0.4589, -0.8829, 0.2928, -0.3671, 0.4584, 0.3677, -0.8091), "JambeD"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(1.1997, 0.2766, -0.1935, 0.1019, -0.8826, 0.4589, 0.8829, 0.2928, 0.3671, -0.4584, 0.3677, 0.8091), "JambeD"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(1.1733, 0.2554, -0.0849, 0.1894, -0.6489, 0.7369, -0.6498, 0.4798, 0.5895, -0.7361, -0.5905, -0.3308), "JambeD"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(1.2518, 0.3183, -0.1201, -0.1894, -0.6489, -0.7369, 0.6498, 0.4798, -0.5895, 0.7361, -0.5905, 0.3308), "JambeD"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(1.2443, 0.1666, -0.0849, -0.5924, -0.7736, 0.2249, 0.3274, 0.0239, 0.9446, -0.7361, 0.6332, 0.2392), "JambeD"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(1.2683, 0.2673, -0.0594, 0.5924, -0.7736, -0.2249, -0.3274, 0.0239, -0.9446, 0.7361, 0.6332, -0.2392), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "grenat", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9996, 0.0091, -0.0252, -0.0105, 0.9982, -0.0582, 0.0247, 0.0585, 0.998), "JambeG"},
	{"Cuissard", "bronze", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "grenat2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0.0073, 0.0349, -0.9994, -0.0076, 0.9994, 0.0349, 0.9999, 0.0074, 0.0076), "JambeG"},
	{"Genouillere", "bronze", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "grenat", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9989, 0.0342, 0.0328, -0.035, 0.9991, 0.0258, -0.0319, -0.0269, 0.9991), "JambeG"},
	{"Greve", "grenat2", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9997, 0.024, 0.0056, -0.0244, 0.9961, 0.0847, -0.0035, -0.0848, 0.9964), "JambeG"},
	{"Greve", "bronze", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "grenat2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0305, 0.0212, -0.9993, -0.0275, 0.9994, 0.0204, 0.9992, 0.0268, 0.0311), "JambeG"},
	{"Mollet", "grenat", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9994, -0.0344, -0.0031, 0.0342, 0.9983, -0.0468, 0.0047, 0.0467, 0.9989), "JambeG"},
	{"Cheville", "bronze", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(-0.28, 0.66, -0.64, 0.9989, -0.0354, 0.0295, 0.0407, 0.9777, -0.2062, -0.0215, 0.2071, 0.9781), "JambeG"},
	{"Ecailles", "rubis", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(-0.72, 0.66, -0.64, 0.9988, -0.0425, -0.0246, 0.037, 0.9802, -0.1945, 0.0323, 0.1934, 0.9806), "JambeG"},
	{"Ecailles", "rubis2", "Bloc", Vector3.new(0.38, 0.28, 0.06), CFrame.new(-0.5, 0.42, -0.64, 0.9998, -0.0123, -0.0174, 0.0094, 0.9876, -0.1566, 0.0191, 0.1564, 0.9875), "JambeG"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(-0.435, 0.1275, -0.705, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(-0.565, 0.1275, -0.705, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(-0.435, -0.0875, -0.705, 0, 0, -1, 0, -1, 0, -1, 0, 0), "JambeG"},
	{"Genouillere", "bronze", "Coin", Vector3.new(0.07, 0.215, 0.13), CFrame.new(-0.565, -0.0875, -0.705, 0, 0, 1, 0, -1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(-0.5074, 0.091, -0.7616, -0.4962, -0.7296, 0.4706, -0.2646, -0.3891, -0.8824, 0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(-0.4674, 0.016, -0.7616, 0.4962, -0.7296, -0.4706, 0.2646, -0.3891, 0.8824, -0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(-0.4674, 0.024, -0.7616, -0.4962, -0.7296, -0.4706, 0.2646, 0.3891, -0.8824, 0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(-0.5074, -0.051, -0.7616, 0.4962, -0.7296, 0.4706, -0.2646, 0.3891, 0.8824, -0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(-0.4926, -0.051, -0.7616, 0.4962, 0.7296, -0.4706, 0.2646, 0.3891, 0.8824, 0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(-0.5326, 0.024, -0.7616, -0.4962, 0.7296, 0.4706, -0.2646, 0.3891, -0.8824, -0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.0376), CFrame.new(-0.5326, 0.016, -0.7616, 0.4962, 0.7296, 0.4706, -0.2646, -0.3891, 0.8824, 0.8269, -0.5623, 0), "JambeG"},
	{"Genouillere", "gemme", "Coin", Vector3.new(0.03, 0.0854, 0.1324), CFrame.new(-0.4926, 0.091, -0.7616, -0.4962, 0.7296, -0.4706, 0.2646, -0.3891, -0.8824, -0.8269, -0.5623, 0), "JambeG"},
	{"Cristaux", "rubis", "Bloc", Vector3.new(0.18, 0.209, 0.18), CFrame.new(-1.1479, 0.1623, -0.1688, 0.6063, -0.7454, -0.2771, 0.4205, 0.5963, -0.6839, 0.6749, 0.2981, 0.6749), "JambeG"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(-1.2948, 0.2885, -0.168, -0.8837, 0.4104, 0.2249, -0.0944, 0.3145, -0.9446, -0.4584, -0.856, -0.2392), "JambeG"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(-1.2708, 0.1878, -0.1935, 0.8837, 0.4104, -0.2249, 0.0944, 0.3145, 0.9446, 0.4584, -0.856, 0.2392), "JambeG"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(-1.2487, 0.3158, -0.1072, -0.1019, 0.8826, 0.4589, 0.8829, 0.2928, -0.3671, -0.4584, 0.3677, -0.8091), "JambeG"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(-1.1997, 0.2766, -0.1935, 0.1019, 0.8826, -0.4589, -0.8829, 0.2928, 0.3671, 0.4584, 0.3677, 0.8091), "JambeG"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(-1.1733, 0.2554, -0.0849, 0.1894, 0.6489, -0.7369, 0.6498, 0.4798, 0.5895, 0.7361, -0.5905, -0.3308), "JambeG"},
	{"Cristaux", "rubis", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(-1.2518, 0.3183, -0.1201, -0.1894, 0.6489, 0.7369, -0.6498, 0.4798, -0.5895, -0.7361, -0.5905, 0.3308), "JambeG"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.076), CFrame.new(-1.2443, 0.1666, -0.0849, -0.5924, 0.7736, -0.2249, -0.3274, 0.0239, 0.9446, 0.7361, 0.6332, 0.2392), "JambeG"},
	{"Cristaux", "rubis2", "Coin", Vector3.new(0.0216, 0.1632, 0.1372), CFrame.new(-1.2683, 0.2673, -0.0594, 0.5924, 0.7736, 0.2249, 0.3274, 0.0239, -0.9446, -0.7361, 0.6332, -0.2392), "JambeG"},
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
	modele.Name = "JambieresRubis"
	modele:SetAttribute("NomAffiche", "Jambières de rubis")

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
		p.Parent = groupes[groupe]
		souder(centres[groupe], p)
	end
	return modele
end

return {
	Nom = "Jambières de rubis",
	Format = "Code",
	Taille = Vector3.new(2.7147, 1.99, 1.4574),
	Centre = Vector3.new(0, 0.005, -0.0693), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
