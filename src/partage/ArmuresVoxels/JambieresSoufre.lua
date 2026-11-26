-- Généré par blender/armes/armures_minerais.py (41 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières de soufre : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresSoufre.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["soufre"] = {"Slate", 214, 168, 52, 0},
	["soufre2"] = {"Slate", 190, 146, 40, 0},
	["soufre3"] = {"Slate", 230, 190, 80, 0},
	["fer"] = {"Metal", 98, 84, 92, 0.05},
	["fer2"] = {"Metal", 78, 66, 74, 0.05},
	["rivet"] = {"Metal", 150, 132, 140, 0.1},
	["cuir"] = {"Fabric", 70, 46, 30, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "soufre2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 0.9999, 0.0107, 0.0129, -0.0097, 0.997, -0.077, -0.0137, 0.0768, 0.9969), "JambeD"},
	{"Cuissard", "fer", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "soufre2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, -0.0103, 0.0082, 0.9999, -0.0141, 0.9999, -0.0084, -0.9998, -0.0141, -0.0102), "JambeD"},
	{"Genouillere", "fer", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "soufre2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 0.9998, 0.0118, 0.0141, -0.0116, 0.9998, -0.0172, -0.0143, 0.017, 0.9998), "JambeD"},
	{"Greve", "soufre3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 0.9999, -0.0061, 0.0126, 0.0053, 0.9977, 0.0679, -0.013, -0.0678, 0.9976), "JambeD"},
	{"Greve", "fer", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "soufre", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0.0065, -0.0146, 0.9999, -0.0063, 0.9999, 0.0146, -1, -0.0064, 0.0064), "JambeD"},
	{"Mollet", "soufre2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 0.9998, -0.0161, -0.0105, 0.0156, 0.999, -0.0423, 0.0111, 0.0421, 0.9991), "JambeD"},
	{"Cheville", "fer", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.98, 0.12, 0.08), CFrame.new(0.5, 0.66, -0.66, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.14, 0.66, -0.6695, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.86, 0.66, -0.6695, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.98, 0.12, 0.08), CFrame.new(0.5, -0.66, -0.66, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.14, -0.66, -0.6695, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.86, -0.66, -0.6695, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Genouillere", "fer2", "Bloc", Vector3.new(0.24, 0.24, 0.1), CFrame.new(0.5, 0.02, -0.75, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0, 1), "JambeD"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(1.118, 0.02, -0.3, 0, 0, 1, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "soufre2", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 0.9999, -0.0107, -0.0129, 0.0097, 0.997, -0.077, 0.0137, 0.0768, 0.9969), "JambeG"},
	{"Cuissard", "fer", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "soufre2", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, -0.0103, -0.0082, -0.9999, 0.0141, 0.9999, -0.0084, 0.9998, -0.0141, -0.0102), "JambeG"},
	{"Genouillere", "fer", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "soufre2", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 0.9998, -0.0118, -0.0141, 0.0116, 0.9998, -0.0172, 0.0143, 0.017, 0.9998), "JambeG"},
	{"Greve", "soufre3", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 0.9999, 0.0061, -0.0126, -0.0053, 0.9977, 0.0679, 0.013, -0.0678, 0.9976), "JambeG"},
	{"Greve", "fer", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "soufre", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0.0065, 0.0146, -0.9999, 0.0063, 0.9999, 0.0146, 1, -0.0064, 0.0064), "JambeG"},
	{"Mollet", "soufre2", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 0.9998, 0.0161, 0.0105, -0.0156, 0.999, -0.0423, -0.0111, 0.0421, 0.9991), "JambeG"},
	{"Cheville", "fer", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.98, 0.12, 0.08), CFrame.new(-0.5, 0.66, -0.66, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.14, 0.66, -0.6695, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.86, 0.66, -0.6695, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Sangles", "fer2", "Bloc", Vector3.new(0.98, 0.12, 0.08), CFrame.new(-0.5, -0.66, -0.66, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.14, -0.66, -0.6695, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.86, -0.66, -0.6695, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Genouillere", "fer2", "Bloc", Vector3.new(0.24, 0.24, 0.1), CFrame.new(-0.5, 0.02, -0.75, 0.7071, 0.7071, 0, -0.7071, 0.7071, 0, 0, 0, 1), "JambeG"},
	{"Rivets", "rivet", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(-1.118, 0.02, -0.3, 0, 0, -1, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0), "JambeG"},
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
	modele.Name = "JambieresSoufre"
	modele:SetAttribute("NomAffiche", "Jambières de soufre")

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
	Nom = "Jambières de soufre",
	Format = "Code",
	Taille = Vector3.new(2.276, 1.99, 1.4606),
	Centre = Vector3.new(0, 0.005, -0.0697), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
