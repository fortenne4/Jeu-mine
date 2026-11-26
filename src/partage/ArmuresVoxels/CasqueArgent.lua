-- Généré par blender/armes/casques_minerais.py (121 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Casque d'Argent : casque de forge (maquette previews/minerais/maquette-casques-epees.png).
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/casques_minerais/CasqueArgent.png
-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["argent"] = {"Metal", 176, 172, 182, 0.15},
	["argent2"] = {"Metal", 146, 142, 152, 0.1},
	["argent3"] = {"Metal", 204, 200, 208, 0.2},
	["amethyste"] = {"SmoothPlastic", 168, 110, 230, 0.1},
	["amethyste2"] = {"SmoothPlastic", 196, 150, 246, 0.1},
	["gemme"] = {"Neon", 190, 130, 255, 0},
	["fente"] = {"SmoothPlastic", 14, 12, 16, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame, marque ("lumiere")}
local PIECES = {
	{"Coque", "argent3", "Bloc", Vector3.new(0.4054, 0.4252, 0.08), CFrame.new(0, 0.35, -0.6623, -0.9994, 0.0097, 0.032, 0.0172, 0.9691, 0.2461, -0.0286, 0.2465, -0.9687)},
	{"Coque", "argent", "Bloc", Vector3.new(0.4107, 0.4249, 0.08), CFrame.new(0.3223, 0.3501, -0.5713, -0.8423, -0.1397, 0.5206, 0.004, 0.9642, 0.2651, -0.539, 0.2254, -0.8116)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.4242, 0.08), CFrame.new(0.5591, 0.3503, -0.3218, -0.4965, -0.1753, 0.8501, 0.0114, 0.978, 0.2083, -0.8679, 0.1131, -0.4836)},
	{"Coque", "amethyste", "Bloc", Vector3.new(0.4261, 0.4239, 0.08), CFrame.new(0.6461, 0.3504, 0.02, 0.0075, -0.2401, 0.9707, -0.0205, 0.9705, 0.2402, -0.9998, -0.0218, 0.0024)},
	{"Coque", "amethyste", "Bloc", Vector3.new(0.421, 0.4242, 0.08), CFrame.new(0.5591, 0.3503, 0.3618, 0.491, -0.2142, 0.8444, -0.0369, 0.9633, 0.2658, -0.8704, -0.1616, 0.4651)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.4107, 0.4249, 0.08), CFrame.new(0.3223, 0.3501, 0.6113, 0.8579, -0.1548, 0.4899, 0.0236, 0.9644, 0.2634, -0.5133, -0.2144, 0.831)},
	{"Coque", "argent", "Bloc", Vector3.new(0.4054, 0.4252, 0.08), CFrame.new(0, 0.35, 0.7023, 0.9996, 0.0018, 0.0298, -0.009, 0.9697, 0.2443, -0.0285, -0.2444, 0.9692)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.4107, 0.4249, 0.08), CFrame.new(-0.3223, 0.3501, 0.6113, 0.8707, 0.1369, -0.4724, -0.0127, 0.9664, 0.2566, 0.4916, -0.2174, 0.8432)},
	{"Coque", "amethyste", "Bloc", Vector3.new(0.421, 0.4242, 0.08), CFrame.new(-0.5591, 0.3503, 0.3618, 0.5017, 0.2106, -0.839, -0.0289, 0.9735, 0.2271, 0.8646, -0.0896, 0.4945)},
	{"Coque", "amethyste", "Bloc", Vector3.new(0.4261, 0.4239, 0.08), CFrame.new(-0.6461, 0.3504, 0.02, -0.004, 0.2662, -0.9639, 0.0214, 0.9637, 0.2661, 0.9998, -0.0196, -0.0096)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.4242, 0.08), CFrame.new(-0.5591, 0.3503, -0.3218, -0.4599, 0.2037, -0.8643, -0.0126, 0.9717, 0.2357, 0.8879, 0.1193, -0.4443)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4107, 0.4249, 0.08), CFrame.new(-0.3223, 0.3501, -0.5713, -0.8636, 0.1366, -0.4852, 0, 0.9626, 0.271, 0.5041, 0.2341, -0.8313)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.3527, 0.3663, 0.08), CFrame.new(0, 0.6648, -0.5009, -1, -0.0078, 0.0051, -0.0025, 0.7503, 0.6611, -0.009, 0.661, -0.7503)},
	{"Coque", "argent", "Bloc", Vector3.new(0.3573, 0.3643, 0.08), CFrame.new(0.246, 0.665, -0.4313, -0.8627, -0.3517, 0.3634, -0.0178, 0.7393, 0.6731, -0.5054, 0.5742, -0.6441)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.3662, 0.3604, 0.08), CFrame.new(0.4265, 0.6654, -0.2408, -0.5117, -0.5679, 0.6447, 0.0405, 0.7336, 0.6783, -0.8582, 0.3732, -0.3524)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3706, 0.3584, 0.08), CFrame.new(0.4927, 0.6656, 0.02, 0.011, -0.664, 0.7476, -0.0002, 0.7477, 0.6641, -0.9999, -0.0075, 0.0081)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3662, 0.3604, 0.08), CFrame.new(0.4265, 0.6654, 0.2808, 0.5114, -0.5258, 0.6797, -0.0436, 0.774, 0.6316, -0.8582, -0.3527, 0.3729)},
	{"Coque", "argent", "Bloc", Vector3.new(0.3573, 0.3643, 0.08), CFrame.new(0.246, 0.665, 0.4713, 0.8597, -0.3485, 0.3734, 0.0099, 0.7423, 0.67, -0.5107, -0.5723, 0.6416)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3527, 0.3663, 0.08), CFrame.new(0, 0.6648, 0.5409, 0.9994, 0.0266, -0.0229, -0.0046, 0.7466, 0.6652, 0.0348, -0.6647, 0.7463)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.3573, 0.3643, 0.08), CFrame.new(-0.246, 0.665, 0.4713, 0.8609, 0.3068, -0.4058, 0.063, 0.7272, 0.6835, 0.5048, -0.614, 0.6068)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3662, 0.3604, 0.08), CFrame.new(-0.4265, 0.6654, 0.2808, 0.4989, 0.5303, -0.6855, 0.0643, 0.7662, 0.6394, 0.8643, -0.363, 0.3481)},
	{"Coque", "argent", "Bloc", Vector3.new(0.3706, 0.3584, 0.08), CFrame.new(-0.4927, 0.6656, 0.02, -0.0308, 0.6268, -0.7786, 0.004, 0.779, 0.627, 0.9995, 0.0162, -0.0265)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3662, 0.3604, 0.08), CFrame.new(-0.4265, 0.6654, -0.2408, -0.476, 0.5744, -0.666, -0.0428, 0.7412, 0.6699, 0.8784, 0.3474, -0.3282)},
	{"Coque", "argent", "Bloc", Vector3.new(0.3573, 0.3643, 0.08), CFrame.new(-0.246, 0.665, -0.4313, -0.8597, 0.3494, -0.3726, 0.0056, 0.7359, 0.6771, 0.5108, 0.58, -0.6346)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.232, 0.3085, 0.08), CFrame.new(0, 0.8463, -0.2603, -0.9994, -0.0316, 0.0133, -0.0003, 0.3966, 0.918, -0.0343, 0.9175, -0.3963)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2349, 0.3055, 0.08), CFrame.new(0.1323, 0.8463, -0.2228, -0.886, -0.4139, 0.209, 0.0109, 0.4319, 0.9018, -0.4636, 0.8013, -0.3782)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.2407, 0.2993, 0.08), CFrame.new(0.2293, 0.8465, -0.1202, -0.4924, -0.7695, 0.4066, 0.0423, 0.4454, 0.8943, -0.8693, 0.4576, -0.1868)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2436, 0.2961, 0.08), CFrame.new(0.2648, 0.8466, 0.02, -0.0067, -0.8964, 0.4433, 0.0031, 0.4433, 0.8964, -1, 0.0074, -0.0002)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2407, 0.2993, 0.08), CFrame.new(0.2293, 0.8465, 0.1602, 0.4922, -0.7861, 0.3737, -0.0391, 0.409, 0.9117, -0.8696, -0.4634, 0.1706)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.2349, 0.3055, 0.08), CFrame.new(0.1323, 0.8463, 0.2628, 0.8802, -0.4221, 0.2172, -0.0233, 0.4185, 0.9079, -0.4741, -0.8042, 0.3585)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.232, 0.3085, 0.08), CFrame.new(0, 0.8463, 0.3003, 0.9997, -0.0247, 0.0019, 0.0075, 0.3748, 0.9271, -0.0236, -0.9268, 0.3748)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2349, 0.3055, 0.08), CFrame.new(-0.1323, 0.8463, 0.2628, 0.8697, 0.4313, -0.24, 0.0359, 0.4296, 0.9023, 0.4923, -0.7933, 0.3581)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.2407, 0.2993, 0.08), CFrame.new(-0.2293, 0.8465, 0.1602, 0.4923, 0.7876, -0.3706, 0.0429, 0.4032, 0.9141, 0.8694, -0.4659, 0.1647)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.2436, 0.2961, 0.08), CFrame.new(-0.2648, 0.8466, 0.02, 0.019, 0.9124, -0.4089, -0.0045, 0.409, 0.9125, 0.9998, -0.0155, 0.0119)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2407, 0.2993, 0.08), CFrame.new(-0.2293, 0.8465, -0.1202, -0.489, 0.7885, -0.3731, 0.0018, 0.4286, 0.9035, 0.8723, 0.4411, -0.211)},
	{"Coque", "argent", "Bloc", Vector3.new(0.2349, 0.3055, 0.08), CFrame.new(-0.1323, 0.8463, -0.2228, -0.8792, 0.44, -0.183, -0.0028, 0.3792, 0.9253, 0.4765, 0.814, -0.3321)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3034, 0.112, 0.306), CFrame.new(0, 0.9105, 0.02, 0.9994, 0.01, -0.0335, -0.0101, 0.9999, -0.0027, 0.0335, 0.003, 0.9994)},
	{"Coque", "argent3", "Bloc", Vector3.new(0.3034, 0.112, 0.306), CFrame.new(0, 0.9105, 0.02, 0.7298, -0.0317, 0.683, 0.0132, 0.9994, 0.0324, -0.6836, -0.0146, 0.7297)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.282, 0.08), CFrame.new(0.6007, -0.015, -0.3471, -0.4809, 0, 0.8768, 0, 1, 0, -0.8768, 0, -0.4809)},
	{"Coque", "amethyste2", "Bloc", Vector3.new(0.4261, 0.282, 0.08), CFrame.new(0.6941, -0.015, 0.02, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.282, 0.08), CFrame.new(0.6007, -0.015, 0.3871, 0.4809, 0, 0.8768, 0, 1, 0, -0.8768, 0, 0.4809)},
	{"Coque", "argent", "Bloc", Vector3.new(0.4107, 0.282, 0.08), CFrame.new(0.3463, -0.015, 0.655, 0.8546, 0, 0.5193, 0, 1, 0, -0.5193, 0, 0.8546)},
	{"Coque", "argent", "Bloc", Vector3.new(0.4054, 0.282, 0.08), CFrame.new(0, -0.015, 0.7527, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4107, 0.282, 0.08), CFrame.new(-0.3463, -0.015, 0.655, 0.8546, 0, -0.5193, 0, 1, 0, 0.5193, 0, 0.8546)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.421, 0.282, 0.08), CFrame.new(-0.6007, -0.015, 0.3871, 0.4809, 0, -0.8768, 0, 1, 0, 0.8768, 0, 0.4809)},
	{"Coque", "amethyste2", "Bloc", Vector3.new(0.4261, 0.282, 0.08), CFrame.new(-0.6941, -0.015, 0.02, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.421, 0.282, 0.08), CFrame.new(-0.6007, -0.015, -0.3471, -0.4809, 0, -0.8768, 0, 1, 0, 0.8768, 0, -0.4809)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.262, 0.08), CFrame.new(0.6007, -0.275, -0.3471, -0.4809, 0, 0.8768, 0, 1, 0, -0.8768, 0, -0.4809)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4261, 0.262, 0.08), CFrame.new(0.6941, -0.275, 0.02, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.262, 0.08), CFrame.new(0.6007, -0.275, 0.3871, 0.4809, 0, 0.8768, 0, 1, 0, -0.8768, 0, 0.4809)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4107, 0.262, 0.08), CFrame.new(0.3463, -0.275, 0.655, 0.8546, 0, 0.5193, 0, 1, 0, -0.5193, 0, 0.8546)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4054, 0.262, 0.08), CFrame.new(0, -0.275, 0.7527, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Coque", "argent2", "Bloc", Vector3.new(0.4107, 0.262, 0.08), CFrame.new(-0.3463, -0.275, 0.655, 0.8546, 0, -0.5193, 0, 1, 0, 0.5193, 0, 0.8546)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.262, 0.08), CFrame.new(-0.6007, -0.275, 0.3871, 0.4809, 0, -0.8768, 0, 1, 0, 0.8768, 0, 0.4809)},
	{"Coque", "argent", "Bloc", Vector3.new(0.4261, 0.262, 0.08), CFrame.new(-0.6941, -0.275, 0.02, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Coque", "argent", "Bloc", Vector3.new(0.421, 0.262, 0.08), CFrame.new(-0.6007, -0.275, -0.3471, -0.4809, 0, -0.8768, 0, 1, 0, 0.8768, 0, -0.4809)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.09, 0.4351, 0.16), CFrame.new(0, 0.7819, -0.5019, 0, 0, 1, 0.766, 0.6428, 0, -0.6428, 0.766, 0)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.09, 0.421, 0.16), CFrame.new(0, 0.9398, -0.211, 0, 0, 1, 0.9588, 0.284, 0, -0.284, 0.9588, 0)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.09, 0.4493, 0.16), CFrame.new(0, 0.9634, 0.1258, 0, 0, 1, 0.9914, -0.1305, 0, 0.1305, 0.9914, 0)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.09, 0.5196, 0.16), CFrame.new(0, 0.8167, 0.4798, 0, 0, 1, 0.8192, -0.5736, 0, 0.5736, 0.8192, 0)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.09, 0.5196, 0.16), CFrame.new(0, 0.4988, 0.7466, 0, 0, 1, 0.4226, -0.9063, 0, 0.9063, 0.4226, 0)},
	{"Crete", "argent3", "Coin", Vector3.new(0.09, 0.22, 0.11), CFrame.new(-0.055, 0.868, -0.6312, 0, 0, 1, -0.8944, 0.4472, 0, -0.4472, -0.8944, 0)},
	{"Crete", "argent3", "Coin", Vector3.new(0.09, 0.22, 0.11), CFrame.new(0.055, 0.868, -0.6312, 0, 0, -1, 0.8944, 0.4472, 0, 0.4472, -0.8944, 0)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3254, 0.132, 0.08), CFrame.new(-0.7639, 0.32, 0.0834, 0.0748, 0, -0.9972, 0, 1, 0, 0.9972, 0, 0.0748)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3243, 0.132, 0.08), CFrame.new(-0.7346, 0.32, -0.2093, -0.2718, 0, -0.9624, 0, 1, 0, 0.9624, 0, -0.2718)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3201, 0.132, 0.08), CFrame.new(-0.6074, 0.32, -0.4711, -0.5905, 0, -0.8071, 0, 1, 0, 0.8071, 0, -0.5905)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3149, 0.132, 0.08), CFrame.new(-0.3996, 0.32, -0.6673, -0.8412, 0, -0.5407, 0, 1, 0, 0.5407, 0, -0.8412)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3114, 0.132, 0.08), CFrame.new(-0.1393, 0.32, -0.7722, -0.9816, 0, -0.1908, 0, 1, 0, 0.1908, 0, -0.9816)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3114, 0.132, 0.08), CFrame.new(0.1393, 0.32, -0.7722, -0.9816, 0, 0.1908, 0, 1, 0, -0.1908, 0, -0.9816)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3149, 0.132, 0.08), CFrame.new(0.3996, 0.32, -0.6673, -0.8412, 0, 0.5407, 0, 1, 0, -0.5407, 0, -0.8412)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3201, 0.132, 0.08), CFrame.new(0.6074, 0.32, -0.4711, -0.5905, 0, 0.8071, 0, 1, 0, -0.8071, 0, -0.5905)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3243, 0.132, 0.08), CFrame.new(0.7346, 0.32, -0.2093, -0.2718, 0, 0.9624, 0, 1, 0, -0.9624, 0, -0.2718)},
	{"Bandeau", "argent2", "Bloc", Vector3.new(0.3254, 0.132, 0.08), CFrame.new(0.7639, 0.32, 0.0834, 0.0748, 0, 0.9972, 0, 1, 0, -0.9972, 0, 0.0748)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.08, 0.187, 0.1697), CFrame.new(-0.0849, 0.8012, -0.5893, 0, 0, 1, 0.4819, 0.8762, 0, -0.8762, 0.4819, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.08, 0.187, 0.1697), CFrame.new(0.0849, 0.8012, -0.5893, 0, 0, -1, -0.4819, 0.8762, 0, 0.8762, 0.4819, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.08, 0.187, 0.1697), CFrame.new(-0.0849, 0.6373, -0.6795, 0, 0, 1, -0.4819, -0.8762, 0, 0.8762, -0.4819, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.08, 0.187, 0.1697), CFrame.new(0.0849, 0.6373, -0.6795, 0, 0, -1, 0.4819, -0.8762, 0, -0.8762, -0.4819, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(0.0069, 0.7971, -0.6739, -0.4575, 0.5392, -0.7071, 0.7683, -0.1606, -0.6196, -0.4476, -0.8267, -0.3408), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(-0.0491, 0.748, -0.7009, 0.4575, 0.5392, 0.7071, -0.7683, -0.1606, 0.6196, 0.4476, -0.8267, 0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(-0.0491, 0.76, -0.6943, -0.4575, 0.5392, 0.7071, -0.0334, 0.7842, -0.6196, -0.8886, -0.3071, -0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(0.0069, 0.711, -0.7213, 0.4575, 0.5392, -0.7071, 0.0334, 0.7842, 0.6196, 0.8886, -0.3071, 0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(-0.0069, 0.711, -0.7213, 0.4575, -0.5392, 0.7071, -0.0334, 0.7842, 0.6196, -0.8886, -0.3071, 0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(0.0491, 0.76, -0.6943, -0.4575, -0.5392, -0.7071, 0.0334, 0.7842, -0.6196, 0.8886, -0.3071, -0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(0.0491, 0.748, -0.7009, 0.4575, -0.5392, -0.7071, 0.7683, -0.1606, 0.6196, -0.4476, -0.8267, 0.3408)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1039, 0.0792), CFrame.new(-0.0069, 0.7971, -0.6739, -0.4575, -0.5392, 0.7071, -0.7683, -0.1606, -0.6196, 0.4476, -0.8267, -0.3408)},
	{"Visiere", "argent", "Bloc", Vector3.new(0.816, 0.92, 0.07), CFrame.new(0.2787, -0.15, -0.6422, -0.7936, 0, 0.6084, 0, 1, 0, -0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(0.1221, -0.12, -0.8127, -0.7936, 0, 0.6084, 0, 1, 0, -0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(0.2253, -0.12, -0.7336, -0.7936, 0, 0.6084, 0, 1, 0, -0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(0.3284, -0.12, -0.6545, -0.7936, 0, 0.6084, 0, 1, 0, -0.6084, 0, -0.7936)},
	{"Visiere", "argent", "Bloc", Vector3.new(0.816, 0.92, 0.07), CFrame.new(-0.2787, -0.15, -0.6422, -0.7936, 0, -0.6084, 0, 1, 0, 0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(-0.1221, -0.12, -0.8127, -0.7936, 0, -0.6084, 0, 1, 0, 0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(-0.2253, -0.12, -0.7336, -0.7936, 0, -0.6084, 0, 1, 0, 0.6084, 0, -0.7936)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.06, 0.36, 0.03), CFrame.new(-0.3284, -0.12, -0.6545, -0.7936, 0, -0.6084, 0, 1, 0, 0.6084, 0, -0.7936)},
	{"Visiere", "argent3", "Bloc", Vector3.new(0.06, 0.94, 0.08), CFrame.new(0, -0.14, -0.92, 1, 0, 0, 0, -1, 0, 0, 0, -1)},
	{"Visiere", "argent3", "Bloc", Vector3.new(0.06, 0.94, 0.08), CFrame.new(0, -0.14, -0.92, 1, 0, 0, 0, -1, 0, 0, 0, -1)},
	{"Visiere", "argent", "Coin", Vector3.new(0.12, 0.14, 0.06), CFrame.new(0, -0.6384, -0.8312, 1, 0, 0, 0, -0.9578, -0.2873, 0, 0.2873, -0.9578)},
	{"Visiere", "argent", "Coin", Vector3.new(0.12, 0.14, 0.06), CFrame.new(0, -0.6557, -0.8886, -1, 0, 0, 0, -0.9578, 0.2873, 0, 0.2873, 0.9578)},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.06, 0.06, 0.03), CFrame.new(-0.7217, 0.22, -0.4522, -0.3747, 0.3747, -0.848, 0.7071, 0.7071, 0, 0.5997, -0.5997, -0.5299)},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.06, 0.06, 0.03), CFrame.new(0.7217, 0.22, -0.4522, -0.3747, 0.3747, 0.848, 0.7071, 0.7071, 0, -0.5997, 0.5997, -0.5299)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(0.7016, -0.2324, -0.4051, -0.4961, -0.1037, 0.8621, -0.0404, 0.9945, 0.0964, -0.8673, 0.013, -0.4976)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(0.8101, -0.2324, 0.02, -0.0262, -0.1462, 0.9889, 0.0189, 0.989, 0.1467, -0.9995, 0.0226, -0.0231)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(0.7016, -0.2324, 0.4451, 0.521, -0.1004, 0.8476, 0.0155, 0.994, 0.1082, -0.8534, -0.0432, 0.5195)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(0.4051, -0.2324, 0.7562, 0.8483, -0.0873, 0.5223, -0.016, 0.9816, 0.1902, -0.5293, -0.1697, 0.8313)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(0, -0.2324, 0.8701, 0.9994, 0.0129, 0.0325, -0.0189, 0.9817, 0.1897, -0.0294, -0.1902, 0.9813)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(-0.4051, -0.2324, 0.7562, 0.8864, 0.0304, -0.4619, 0.0272, 0.9927, 0.1176, 0.4621, -0.1168, 0.8791)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(-0.7016, -0.2324, 0.4451, 0.4804, 0.1077, -0.8704, -0.0016, 0.9925, 0.1219, 0.877, -0.0572, 0.477)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(-0.8101, -0.2324, 0.02, 0.0307, 0.1121, -0.9932, 0.035, 0.993, 0.1131, 0.9989, -0.0382, 0.0266)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5029, 0.5, 0.07), CFrame.new(-0.7016, -0.2324, -0.4051, -0.5249, 0.129, -0.8413, -0.0188, 0.9865, 0.163, 0.851, 0.1014, -0.5153)},
	{"Lames", "amethyste", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(0.8563, -0.551, -0.2198, -0.2497, -0.2533, 0.9346, -0.0095, 0.9658, 0.2592, -0.9683, 0.0558, -0.2435)},
	{"Lames", "amethyste", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(0.8563, -0.551, 0.2598, 0.28, -0.1769, 0.9435, -0.0445, 0.9794, 0.1969, -0.959, -0.0971, 0.2664)},
	{"Lames", "argent", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(0.6269, -0.551, 0.6751, 0.7297, -0.1279, 0.6717, -0.027, 0.9762, 0.2153, -0.6832, -0.1753, 0.7089)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(0.2294, -0.551, 0.9149, 0.9727, -0.0167, 0.2313, -0.0418, 0.9684, 0.2458, -0.2281, -0.2488, 0.9413)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(-0.2294, -0.551, 0.9149, 0.9563, 0.0843, -0.2801, -0.0288, 0.98, 0.1967, 0.2911, -0.1801, 0.9396)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(-0.6269, -0.551, 0.6751, 0.6893, 0.2156, -0.6917, -0.0258, 0.9614, 0.2739, 0.724, -0.171, 0.6682)},
	{"Lames", "amethyste", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(-0.8563, -0.551, 0.2598, 0.2315, 0.2864, -0.9297, -0.0174, 0.9568, 0.2904, 0.9727, -0.051, 0.2265)},
	{"Lames", "amethyste", "Bloc", Vector3.new(0.5321, 0.5, 0.07), CFrame.new(-0.8563, -0.551, -0.2198, -0.246, 0.2177, -0.9445, 0.0377, 0.9759, 0.2151, 0.9685, 0.0173, -0.2483)},
	{"Lames", "argent3", "Bloc", Vector3.new(0.06, 0.597, 0.08), CFrame.new(0.933, -0.82, -0.24, 0, 0.2495, 0.9684, 1, 0, 0, 0, 0.9684, -0.2495)},
	{"Lames", "argent3", "Bloc", Vector3.new(0.06, 0.597, 0.08), CFrame.new(0.933, -0.82, 0.28, 0, -0.2495, 0.9684, 1, 0, 0, 0, 0.9684, 0.2495)},
	{"Lames", "argent3", "Bloc", Vector3.new(0.06, 0.597, 0.08), CFrame.new(-0.933, -0.82, -0.24, 0, -0.2495, -0.9684, -1, 0, 0, 0, 0.9684, -0.2495)},
	{"Lames", "argent3", "Bloc", Vector3.new(0.06, 0.597, 0.08), CFrame.new(-0.933, -0.82, 0.28, 0, 0.2495, -0.9684, -1, 0, 0, 0, 0.9684, 0.2495)},
}

local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "CasqueArgent"
	modele:SetAttribute("NomAffiche", "Casque d'Argent")

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

	local lumiereFaite = false
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
			l.Color = Color3.fromRGB(200, 150, 255)
			l.Range = 6
			l.Brightness = 0.9
			l.Shadows = false
			l.Parent = p
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
	Nom = "Casque d'Argent",
	Format = "Code",
	Taille = Vector3.new(2.0924, 1.8928, 2.0308),
	Centre = Vector3.new(0, 0.0964, 0.0554), -- centre de la boîte englobante dans le repère de la tête
	construire = construire,
}
