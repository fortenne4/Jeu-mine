-- Généré par blender/armes/armures_minerais.py (35 Parts en jeu, Racine et Centres comprises). Ne pas modifier à la main.
-- Jambières d'argent : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/jambieres_minerais/JambieresArgent.png
-- Repère : Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["argent"] = {"Metal", 176, 172, 182, 0.15},
	["argent2"] = {"Metal", 146, 142, 152, 0.1},
	["argent3"] = {"Metal", 204, 200, 208, 0.2},
	["amethyste"] = {"SmoothPlastic", 168, 110, 230, 0.1},
	["amethyste2"] = {"SmoothPlastic", 196, 150, 246, 0.1},
	["cuir"] = {"Fabric", 80, 88, 110, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "argent", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(0.5, 0.54, -0.58, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeD"},
	{"Cuissard", "argent3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "argent", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(1.05, 0.54, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Genouillere", "argent3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(1.06, 0.02, -0.28, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Greve", "argent", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(0.5, -0.5, -0.58, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeD"},
	{"Greve", "argent3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(0.5, -0.5, -0.645, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071), "JambeD"},
	{"Greve", "argent2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(1.05, -0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), "JambeD"},
	{"Mollet", "argent", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(0.5, -0.48, 0.58, 1, 0, 0, 0, 0.9986, -0.0523, 0, 0.0523, 0.9986), "JambeD"},
	{"Cheville", "argent3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Cuissard", "amethyste", "Bloc", Vector3.new(0.05, 0.5, 0.56), CFrame.new(1.12, 0.54, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Greve", "amethyste2", "Bloc", Vector3.new(0.05, 0.5, 0.56), CFrame.new(1.12, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeD"},
	{"Genouillere", "amethyste", "Bloc", Vector3.new(0.2, 0.2, 0.06), CFrame.new(0.5, 0.02, -0.74, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.16, 0.76, -0.6295, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(0.84, 0.76, -0.6295, -0.7071, 0.7071, 0, 0.7071, 0.7071, 0, 0, 0, -1), "JambeD"},
	{"Dessous", "cuir", "Bloc", Vector3.new(0.96, 1.86, 1), CFrame.new(-0.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "argent", "Bloc", Vector3.new(0.94, 0.78, 0.12), CFrame.new(-0.5, 0.54, -0.58, 1, 0, 0, 0, 0.9976, -0.0698, 0, 0.0698, 0.9976), "JambeG"},
	{"Cuissard", "argent3", "Bloc", Vector3.new(1, 0.12, 0.18), CFrame.new(-0.5, 0.94, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "argent", "Bloc", Vector3.new(0.92, 0.78, 0.12), CFrame.new(-1.05, 0.54, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Genouillere", "argent3", "Bloc", Vector3.new(0.66, 0.42, 0.16), CFrame.new(-0.5, 0.02, -0.64, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "argent", "Bloc", Vector3.new(0.14, 0.4, 0.56), CFrame.new(-1.06, 0.02, -0.28, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Greve", "argent", "Bloc", Vector3.new(0.92, 0.8, 0.12), CFrame.new(-0.5, -0.5, -0.58, 1, 0, 0, 0, 0.9986, 0.0523, 0, -0.0523, 0.9986), "JambeG"},
	{"Greve", "argent3", "Bloc", Vector3.new(0.14, 0.72, 0.14), CFrame.new(-0.5, -0.5, -0.645, 0.7071, 0, -0.7071, 0, 1, 0, 0.7071, 0, 0.7071), "JambeG"},
	{"Greve", "argent2", "Bloc", Vector3.new(0.94, 0.8, 0.12), CFrame.new(-1.05, -0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), "JambeG"},
	{"Mollet", "argent", "Bloc", Vector3.new(0.92, 0.74, 0.12), CFrame.new(-0.5, -0.48, 0.58, 1, 0, 0, 0, 0.9986, -0.0523, 0, 0.0523, 0.9986), "JambeG"},
	{"Cheville", "argent3", "Bloc", Vector3.new(1, 0.14, 1.14), CFrame.new(-0.52, -0.92, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Cuissard", "amethyste", "Bloc", Vector3.new(0.05, 0.5, 0.56), CFrame.new(-1.12, 0.54, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Greve", "amethyste2", "Bloc", Vector3.new(0.05, 0.5, 0.56), CFrame.new(-1.12, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), "JambeG"},
	{"Genouillere", "amethyste", "Bloc", Vector3.new(0.2, 0.2, 0.06), CFrame.new(-0.5, 0.02, -0.74, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.16, 0.76, -0.6295, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.07, 0.07, 0.035), CFrame.new(-0.84, 0.76, -0.6295, -0.7071, -0.7071, 0, -0.7071, 0.7071, 0, 0, 0, -1), "JambeG"},
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
	modele.Name = "JambieresArgent"
	modele:SetAttribute("NomAffiche", "Jambières d'argent")

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
	Nom = "Jambières d'argent",
	Format = "Code",
	Taille = Vector3.new(2.29, 1.99, 1.4293),
	Centre = Vector3.new(0, 0.005, -0.0554), -- centre de la boîte englobante dans le repère de Racine
	Groupes = GROUPES,
	construire = construire,
}
