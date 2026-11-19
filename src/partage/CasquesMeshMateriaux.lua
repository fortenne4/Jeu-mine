-- Généré par blender/armes/casques_fideles.py. Ne pas modifier à la main.
-- Casques mesh (ReplicatedStorage.CasquesMesh.<Id>, importés depuis assets/casques/<Id>.fbx) :
-- sous-mesh (nom de MeshPart) -> apparence Roblox ; Taille = encombrement attendu (studs, sans Racine).
return {
	CasqueCharbon = {
		Taille = Vector3.new(2.205, 2.322, 2.072),
		Centre = Vector3.new(-0.011, 0.176, -0.004), -- centre de la boîte dans le repère de la tête
		Parties = {
			Roche = {Material = Enum.Material.Slate, Color = Color3.fromRGB(44, 41, 45), Transparency = 0},
			Fissures = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 96, 24), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 120, 40), Portee = 6, Luminosite = 1.2}},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueBronze = {
		Taille = Vector3.new(1.863, 2.283, 1.963),
		Centre = Vector3.new(0.000, 0.163, -0.026), -- centre de la boîte dans le repère de la tête
		Parties = {
			BronzeClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(212, 134, 72), Transparency = 0},
			Bronze = {Material = Enum.Material.Metal, Color = Color3.fromRGB(176, 98, 52), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueCharbonBronze = {
		Taille = Vector3.new(1.953, 2.402, 2.179),
		Centre = Vector3.new(-0.023, 0.216, -0.002), -- centre de la boîte dans le repère de la tête
		Parties = {
			BronzeClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(212, 134, 72), Transparency = 0},
			Fissures = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 96, 24), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 120, 40), Portee = 6, Luminosite = 1.2}},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Roche = {Material = Enum.Material.Slate, Color = Color3.fromRGB(44, 41, 45), Transparency = 0},
			Bronze = {Material = Enum.Material.Metal, Color = Color3.fromRGB(176, 98, 52), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueFer = {
		Taille = Vector3.new(1.863, 1.999, 1.963),
		Centre = Vector3.new(0.000, 0.021, -0.026), -- centre de la boîte dans le repère de la tête
		Parties = {
			FerClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(160, 164, 172), Transparency = 0},
			Fer = {Material = Enum.Material.Metal, Color = Color3.fromRGB(108, 112, 120), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueCharbonFer = {
		Taille = Vector3.new(2.278, 2.687, 2.178),
		Centre = Vector3.new(0.056, 0.359, -0.014), -- centre de la boîte dans le repère de la tête
		Parties = {
			Fer = {Material = Enum.Material.Metal, Color = Color3.fromRGB(108, 112, 120), Transparency = 0},
			Fissures = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 96, 24), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 120, 40), Portee = 6, Luminosite = 1.2}},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Roche = {Material = Enum.Material.Slate, Color = Color3.fromRGB(44, 41, 45), Transparency = 0},
			FerClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(160, 164, 172), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueBronzeFer = {
		Taille = Vector3.new(1.912, 2.273, 2.022),
		Centre = Vector3.new(0.000, 0.158, 0.003), -- centre de la boîte dans le repère de la tête
		Parties = {
			BronzeClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(212, 134, 72), Transparency = 0},
			FerSombre = {Material = Enum.Material.Metal, Color = Color3.fromRGB(58, 57, 62), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Bronze = {Material = Enum.Material.Metal, Color = Color3.fromRGB(176, 98, 52), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueOr = {
		Taille = Vector3.new(1.952, 2.439, 2.078),
		Centre = Vector3.new(0.000, 0.241, -0.084), -- centre de la boîte dans le repère de la tête
		Parties = {
			Gemme = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 80), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 210, 110), Portee = 7, Luminosite = 1.4}},
			Or = {Material = Enum.Material.Metal, Color = Color3.fromRGB(222, 160, 40), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			OrClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(248, 200, 84), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueCharbonOr = {
		Taille = Vector3.new(2.180, 2.647, 2.163),
		Centre = Vector3.new(0.032, 0.339, -0.015), -- centre de la boîte dans le repère de la tête
		Parties = {
			FerClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(160, 164, 172), Transparency = 0},
			Fissures = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 96, 24), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 120, 40), Portee = 6, Luminosite = 1.2}},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Roche = {Material = Enum.Material.Slate, Color = Color3.fromRGB(44, 41, 45), Transparency = 0},
			Or = {Material = Enum.Material.Metal, Color = Color3.fromRGB(222, 160, 40), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueBronzeOr = {
		Taille = Vector3.new(1.952, 2.531, 2.130),
		Centre = Vector3.new(0.000, 0.287, -0.063), -- centre de la boîte dans le repère de la tête
		Parties = {
			Gemme = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 80), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 210, 110), Portee = 7, Luminosite = 1.4}},
			BronzeRouge = {Material = Enum.Material.Metal, Color = Color3.fromRGB(122, 58, 40), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Or = {Material = Enum.Material.Metal, Color = Color3.fromRGB(222, 160, 40), Transparency = 0},
			OrClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(248, 200, 84), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
	CasqueFerOr = {
		Taille = Vector3.new(2.759, 2.581, 2.100),
		Centre = Vector3.new(0.000, 0.312, -0.095), -- centre de la boîte dans le repère de la tête
		Parties = {
			Gemme = {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 80), Transparency = 0, Lumiere = {Couleur = Color3.fromRGB(255, 210, 110), Portee = 7, Luminosite = 1.4}},
			Fer = {Material = Enum.Material.Metal, Color = Color3.fromRGB(108, 112, 120), Transparency = 0},
			Doublure = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(16, 13, 12), Transparency = 0},
			Or = {Material = Enum.Material.Metal, Color = Color3.fromRGB(222, 160, 40), Transparency = 0},
			FerClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(160, 164, 172), Transparency = 0},
			OrClair = {Material = Enum.Material.Metal, Color = Color3.fromRGB(248, 200, 84), Transparency = 0},
			Racine = {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255), Transparency = 1},
		},
	},
}
