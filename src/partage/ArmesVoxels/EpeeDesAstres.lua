-- Épée des astres (butin unique du Gardien des astres, grotte −1200 m « Néant étoilé »).
-- MODÈLE PROVISOIRE écrit à la main (pas d'export Blender) : lame bleu nuit semée d'étoiles en néon, fil bleu
-- lumineux, garde dorée en croissant de lune, cristal violet au pommeau.
-- Pour brancher le vrai modèle : soit remplacer ce fichier (même format que EpeeFer.lua, généré par blender/armes/),
-- soit importer un mesh ReplicatedStorage.EpeesMesh.EpeeDesAstres (+ entrée dans Partage.EpeesMeshMateriaux) :
-- ArmesVoxels.construire le prend alors en priorité. Garder les noms « Poignee » et « Lame » (contrat ArmesVoxels).
-- Repère = Poignee : origine au centre de la prise, lame vers +Y, unités = studs.
return {
	Nom = "Épée des astres",
	Couleurs = {
		["nuit"] = {"Metal", 22, 26, 70, 0.25},
		["nuitF"] = {"Metal", 12, 14, 40, 0.1},
		["fil"] = {"Neon", 110, 170, 255, 0},
		["etoile"] = {"Neon", 255, 244, 200, 0},
		["etoileB"] = {"Neon", 170, 210, 255, 0},
		["or"] = {"Metal", 236, 190, 84, 0.3},
		["orF"] = {"Metal", 168, 120, 46, 0.1},
		["cuir"] = {"Fabric", 30, 24, 58, 0},
		["lien"] = {"Fabric", 210, 170, 80, 0},
		["cristal"] = {"Neon", 190, 110, 255, 0},
	},
	-- nom, couleur, taille, position (dans le repère de Poignee), rotation Y (degrés)
	Pieces = {
		{"Poignee", "cuir", Vector3.new(0.3, 0.95, 0.3), Vector3.new(0, 0, 0), 0},
		{"Lien", "lien", Vector3.new(0.34, 0.08, 0.34), Vector3.new(0, -0.3, 0), 0},
		{"Lien", "lien", Vector3.new(0.34, 0.08, 0.34), Vector3.new(0, 0, 0), 0},
		{"Lien", "lien", Vector3.new(0.34, 0.08, 0.34), Vector3.new(0, 0.3, 0), 0},
		-- garde : croissant de lune doré
		{"Garde", "or", Vector3.new(1.1, 0.22, 0.36), Vector3.new(0, 0.58, 0), 0},
		{"Garde", "orF", Vector3.new(0.5, 0.36, 0.44), Vector3.new(0, 0.6, 0), 0},
		{"Garde", "or", Vector3.new(0.22, 0.5, 0.3), Vector3.new(-0.62, 0.78, 0), 0},
		{"Garde", "or", Vector3.new(0.22, 0.5, 0.3), Vector3.new(0.62, 0.78, 0), 0},
		{"Garde", "or", Vector3.new(0.16, 0.22, 0.24), Vector3.new(-0.62, 1.1, 0), 0},
		{"Garde", "or", Vector3.new(0.16, 0.22, 0.24), Vector3.new(0.62, 1.1, 0), 0},
		{"Gemme", "etoileB", Vector3.new(0.2, 0.2, 0.46), Vector3.new(0, 0.62, 0), 45},
		-- lame bleu nuit, fil lumineux, gorge sombre
		{"Lame", "nuit", Vector3.new(0.56, 3.2, 0.14), Vector3.new(0, 2.35, 0), 0},
		{"Gorge", "nuitF", Vector3.new(0.14, 2.8, 0.16), Vector3.new(0, 2.3, 0), 0},
		{"Fil", "fil", Vector3.new(0.07, 3.1, 0.1), Vector3.new(-0.31, 2.35, 0), 0},
		{"Fil", "fil", Vector3.new(0.07, 3.1, 0.1), Vector3.new(0.31, 2.35, 0), 0},
		{"Pointe", "nuit", Vector3.new(0.4, 0.3, 0.12), Vector3.new(0, 4.08, 0), 0},
		{"Pointe", "fil", Vector3.new(0.24, 0.22, 0.1), Vector3.new(0, 4.32, 0), 0},
		{"Pointe", "etoile", Vector3.new(0.1, 0.12, 0.08), Vector3.new(0, 4.48, 0), 0},
		-- étoiles semées sur les deux faces de la lame (constellation)
		{"Etoile", "etoile", Vector3.new(0.12, 0.12, 0.18), Vector3.new(-0.12, 1.3, 0), 45},
		{"Etoile", "etoileB", Vector3.new(0.08, 0.08, 0.18), Vector3.new(0.14, 1.75, 0), 45},
		{"Etoile", "etoile", Vector3.new(0.16, 0.16, 0.18), Vector3.new(-0.08, 2.25, 0), 45},
		{"Etoile", "etoileB", Vector3.new(0.08, 0.08, 0.18), Vector3.new(0.16, 2.7, 0), 45},
		{"Etoile", "etoile", Vector3.new(0.12, 0.12, 0.18), Vector3.new(-0.14, 3.15, 0), 45},
		{"Etoile", "etoileB", Vector3.new(0.08, 0.08, 0.18), Vector3.new(0.1, 3.55, 0), 45},
		-- pommeau : griffes dorées autour d'un cristal violet
		{"Pommeau", "orF", Vector3.new(0.42, 0.14, 0.42), Vector3.new(0, -0.54, 0), 0},
		{"Griffe", "or", Vector3.new(0.07, 0.22, 0.07), Vector3.new(-0.17, -0.7, 0), 0},
		{"Griffe", "or", Vector3.new(0.07, 0.22, 0.07), Vector3.new(0.17, -0.7, 0), 0},
		{"Cristal", "cristal", Vector3.new(0.24, 0.26, 0.24), Vector3.new(0, -0.78, 0), 45},
		{"Cristal", "cristal", Vector3.new(0.12, 0.1, 0.12), Vector3.new(0, -0.95, 0), 45},
	},
	TrailA = Vector3.new(0, 0.85, 0),
	TrailB = Vector3.new(0, 4.4, 0),
	Lueur = {Couleur = Color3.fromRGB(150, 120, 255), Portee = 7, Luminosite = 1.6},
}
