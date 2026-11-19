-- Généré par blender/armes/casques_lisses.py (CasqueFer : 18 parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Casque lisse construit par ArmuresVoxels (CSG GeometryService, cache + Clone ; Secours si le CSG échoue).
-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.
return {
	Nom = "Casque de fer",
	Format = "Lisse",
	Rang = 4, -- échelle de puissance des casques (1 = plus faible, 10 = plus prestigieux)
	-- clé -> {matériau, r, g, b, reflectance}
	Couleurs = {
		["acier"] = {"Metal", 170, 178, 188, 0.12},
		["acierF"] = {"Metal", 104, 110, 120, 0.06},
		["maille"] = {"Metal", 76, 80, 90, 0.02},
		["acierC"] = {"Metal", 204, 210, 218, 0.15},
		["laiton"] = {"Metal", 208, 166, 82, 0.1},
		["lampe"] = {"Neon", 255, 228, 156, 0},
	},
	Pieces = {
		{Nom = "Coque", Cle = "acier", Forme = "CSG",
			Base = {Forme = "Boule", Taille = Vector3.new(1.62, 1.62, 1.62), CF = CFrame.new(0, 0.08, 0)},
			Plus = {
				{Forme = "Cylindre", Taille = Vector3.new(0.76, 1.6184, 1.6184), CF = CFrame.new(0, -0.3, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
			},
			Moins = {
				{Forme = "Boule", Taille = Vector3.new(1.38, 1.38, 1.38), CF = CFrame.new(0, 0.08, 0)},
				{Forme = "Cylindre", Taille = Vector3.new(2.58, 1.38, 1.38), CF = CFrame.new(0, -1.21, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
				{Forme = "Bloc", Taille = Vector3.new(0.6, 1.77, 1.05), CF = CFrame.new(0, -0.615, -0.775)},
				{Forme = "Bloc", Taille = Vector3.new(0.8, 1.67, 1.05), CF = CFrame.new(0, -0.665, -0.775)},
				{Forme = "Cylindre", Taille = Vector3.new(1.05, 0.2, 0.2), CF = CFrame.new(0.3, 0.17, -0.775, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
				{Forme = "Cylindre", Taille = Vector3.new(1.05, 0.2, 0.2), CF = CFrame.new(-0.3, 0.17, -0.775, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
			},
			Secours = {
				{Nom = "Coque", Cle = "acier", Forme = "Ellipsoide", Taille = Vector3.new(1.66, 1.3, 1.72), CF = CFrame.new(0, 0.52, 0.15)},
				{Nom = "Coque", Cle = "acier", Forme = "Ellipsoide", Taille = Vector3.new(1.62, 1.5, 1.2), CF = CFrame.new(0, 0.07, 0.38)},
				{Nom = "Coque", Cle = "acier", Forme = "Ellipsoide", Taille = Vector3.new(0.32, 1.1, 1.25), CF = CFrame.new(0.66, -0.06, -0.12)},
				{Nom = "Coque", Cle = "acier", Forme = "Ellipsoide", Taille = Vector3.new(0.32, 1.1, 1.25), CF = CFrame.new(-0.66, -0.06, -0.12)},
			},
		},
		{Nom = "Arete", Cle = "acierF", Forme = "CSG",
			Base = {Forme = "Cylindre", Taille = Vector3.new(0.075, 1.72, 1.72), CF = CFrame.new(0, 0.08, 0)},
			Moins = {
				{Forme = "Cylindre", Taille = Vector3.new(0.3, 1.4, 1.4), CF = CFrame.new(0, 0.08, 0)},
				{Forme = "Bloc", Taille = Vector3.new(1, 2, 1.5), CF = CFrame.new(0, -0.7, -1.05)},
				{Forme = "Bloc", Taille = Vector3.new(1, 1, 3), CF = CFrame.new(0, -1.12, 0)},
			},
		},
		{Nom = "Visiere", Cle = "acier", Forme = "CSG",
			Base = {Forme = "Cylindre", Taille = Vector3.new(0.06, 1.96, 1.96), CF = CFrame.new(0, 0.285, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
			Moins = {
				{Forme = "Cylindre", Taille = Vector3.new(0.3, 1.4, 1.4), CF = CFrame.new(0, 0.285, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
				{Forme = "Bloc", Taille = Vector3.new(3, 1, 3), CF = CFrame.new(0, 0.285, 1.05)},
			},
		},
		{Nom = "Camail", Cle = "maille", Forme = "CSG",
			Base = {Forme = "Cylindre", Taille = Vector3.new(0.22, 1.8, 1.8), CF = CFrame.new(0, -0.56, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
			Moins = {
				{Forme = "Cylindre", Taille = Vector3.new(0.6, 1.48, 1.48), CF = CFrame.new(0, -0.56, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
				{Forme = "Bloc", Taille = Vector3.new(3, 1, 3), CF = CFrame.new(0, -0.56, -1.22)},
			},
		},
		{Nom = "Camail", Cle = "maille", Forme = "CSG",
			Base = {Forme = "Cylindre", Taille = Vector3.new(0.18, 1.92, 1.92), CF = CFrame.new(0, -0.74, 0.02, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
			Moins = {
				{Forme = "Cylindre", Taille = Vector3.new(0.6, 1.58, 1.58), CF = CFrame.new(0, -0.74, 0.02, 0, -1, 0, 1, 0, 0, 0, 0, 1)},
				{Forme = "Bloc", Taille = Vector3.new(3, 1, 3), CF = CFrame.new(0, -0.74, -1.16)},
			},
		},
		{Nom = "Nasal", Cle = "acierF", Forme = "Bloc", Taille = Vector3.new(0.12, 0.44, 0.07), CF = CFrame.new(0, 0.07, -0.79)},
		{Nom = "Nasal", Cle = "acierF", Forme = "Boule", Taille = Vector3.new(0.15, 0.15, 0.15), CF = CFrame.new(0, -0.15, -0.79)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(0.56, -0.28, -0.5852)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(0.5, -0.52, -0.6373)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(0.62, 0.02, -0.5212)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(-0.56, -0.28, -0.5852)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(-0.5, -0.52, -0.6373)},
		{Nom = "Rivet", Cle = "acierC", Forme = "Boule", Taille = Vector3.new(0.085, 0.085, 0.085), CF = CFrame.new(-0.62, 0.02, -0.5212)},
		{Nom = "Support", Cle = "laiton", Forme = "Bloc", Taille = Vector3.new(0.1, 0.16, 0.16), CF = CFrame.new(-0.2799, 0.5441, -0.6286, 0.8564, -0.3372, -0.3911, 0.5164, 0.5592, 0.6486, 0, -0.7574, 0.653)},
		{Nom = "Lampe", Cle = "laiton", Forme = "Cylindre", Taille = Vector3.new(0.2, 0.25, 0.25), CF = CFrame.new(-0.2832, 0.5426, -0.6958, 0, 0, 1, -0.1191, 0.9929, 0, -0.9929, -0.1191, 0)},
		{Nom = "Lampe", Cle = "acierF", Forme = "Cylindre", Taille = Vector3.new(0.05, 0.3, 0.3), CF = CFrame.new(-0.2832, 0.5295, -0.805, 0, 0, 1, -0.1191, 0.9929, 0, -0.9929, -0.1191, 0)},
		{Nom = "Lentille", Cle = "lampe", Forme = "Cylindre", Taille = Vector3.new(0.03, 0.2, 0.2), CF = CFrame.new(-0.2832, 0.5265, -0.8298, 0, 0, 1, -0.1191, 0.9929, 0, -0.9929, -0.1191, 0)},
	},
	Lumieres = {
		{Piece = "Lentille", Type = "Point", Couleur = Color3.fromRGB(255, 220, 150), Portee = 8, Luminosite = 1.2},
		{Piece = "Lentille", Type = "Spot", Couleur = Color3.fromRGB(255, 226, 170), Portee = 18, Luminosite = 2, Angle = 55, Face = "Right"},
	},
}
