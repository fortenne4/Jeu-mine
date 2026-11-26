-- Généré par blender/armes/armures_minerais.py (69 Parts en jeu, Racine comprise). Ne pas modifier à la main.
-- Plastron d'argent : assorti(es) au casque et à l'épée du même minerai.
-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,
-- donc visible par tous. Aperçu : previews/armes/plastrons_minerais/PlastronArgent.png
-- Repère : Racine = centre de l'UpperTorso R15. Devant = -Z, haut = +Y, droite = +X, unités = studs.

-- clé -> {matériau, r, g, b, reflectance}
local COULEURS = {
	["argent"] = {"Metal", 176, 172, 182, 0.15},
	["argent2"] = {"Metal", 146, 142, 152, 0.1},
	["argent3"] = {"Metal", 204, 200, 208, 0.2},
	["amethyste"] = {"SmoothPlastic", 168, 110, 230, 0.1},
	["amethyste2"] = {"SmoothPlastic", 196, 150, 246, 0.1},
	["gemme"] = {"Neon", 190, 130, 255, 0},
	["cuir"] = {"Fabric", 80, 88, 110, 0},
	["fente"] = {"SmoothPlastic", 14, 12, 16, 0},
}

-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}
local PIECES = {
	{"Dessous", "cuir", "Bloc", Vector3.new(2.02, 1.66, 1.02), CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Poitrine", "argent", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(0.5, 0.36, -0.64, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Liseré", "argent3", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(0.5, 0.8, -0.66, 0.9781, 0, -0.2079, 0, 1, 0, 0.2079, 0, 0.9781)},
	{"Poitrine", "argent", "Bloc", Vector3.new(1, 0.86, 0.12), CFrame.new(-0.5, 0.36, -0.64, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Liseré", "argent3", "Bloc", Vector3.new(1.04, 0.1, 0.16), CFrame.new(-0.5, 0.8, -0.66, 0.9781, 0, 0.2079, 0, 1, 0, -0.2079, 0, 0.9781)},
	{"Arete", "argent3", "Bloc", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0, 0.35, -0.72, 0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(0.48, -0.21, -0.62, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Lames", "argent2", "Bloc", Vector3.new(0.98, 0.28, 0.12), CFrame.new(-0.48, -0.21, -0.62, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Lames", "argent2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(0.48, -0.45, -0.64, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Lames", "argent2", "Bloc", Vector3.new(1, 0.28, 0.12), CFrame.new(-0.48, -0.45, -0.64, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Lames", "argent2", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(0.48, -0.69, -0.66, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Lames", "argent", "Bloc", Vector3.new(1.02, 0.28, 0.12), CFrame.new(-0.48, -0.69, -0.66, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Flanc", "argent", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(1.06, -0.14, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Flanc", "argent2", "Bloc", Vector3.new(1.02, 1.28, 0.12), CFrame.new(-1.06, -0.14, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Dossiere", "argent", "Bloc", Vector3.new(1.96, 0.94, 0.12), CFrame.new(0, 0.32, 0.62, -1, 0, 0, 0, 1, 0, 0, 0, -1)},
	{"Dossiere", "argent3", "Bloc", Vector3.new(0.14, 0.92, 0.1), CFrame.new(0, 0.32, 0.7, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Dossiere", "argent2", "Bloc", Vector3.new(1.98, 0.28, 0.12), CFrame.new(0, -0.21, 0.62, 1, 0, 0, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903)},
	{"Dossiere", "argent", "Bloc", Vector3.new(2, 0.28, 0.12), CFrame.new(0, -0.45, 0.64, 1, 0, 0, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903)},
	{"Dossiere", "argent", "Bloc", Vector3.new(2.02, 0.28, 0.12), CFrame.new(0, -0.69, 0.66, 1, 0, 0, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903)},
	{"Col", "argent3", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, -0.7, 1, 0, 0, 0, 0.9659, -0.2588, 0, 0.2588, 0.9659)},
	{"Col", "argent3", "Bloc", Vector3.new(1.4, 0.16, 0.14), CFrame.new(0, 0.88, 0.68, 1, 0, 0, 0, 0.9659, 0.2588, 0, -0.2588, 0.9659)},
	{"Col", "argent3", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(0.72, 0.88, -0.01, 0.9659, 0.2588, 0, -0.2588, 0.9659, 0, 0, 0, 1)},
	{"Col", "argent3", "Bloc", Vector3.new(0.14, 0.16, 1.4), CFrame.new(-0.72, 0.88, -0.01, 0.9659, -0.2588, 0, 0.2588, 0.9659, 0, 0, 0, 1)},
	{"Epauliere", "argent", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(1.05, 0.96, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "argent2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(1.72, 0.92, 0, 0.8829, 0.4695, 0, -0.4695, 0.8829, 0, 0, 0, 1)},
	{"Epauliere", "argent3", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(1.5, 0.98, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(2.04, 0.66, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "argent", "Bloc", Vector3.new(1, 0.2, 1.26), CFrame.new(-1.05, 0.96, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "argent2", "Bloc", Vector3.new(0.6, 0.18, 1.2), CFrame.new(-1.72, 0.92, 0, 0.8829, -0.4695, 0, 0.4695, 0.8829, 0, 0, 0, 1)},
	{"Epauliere", "argent3", "Bloc", Vector3.new(0.12, 0.26, 1.3), CFrame.new(-1.5, 0.98, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Epauliere", "argent", "Bloc", Vector3.new(0.16, 0.44, 1.14), CFrame.new(-2.04, 0.66, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Ceinture", "argent2", "Bloc", Vector3.new(2.14, 0.16, 1.18), CFrame.new(0, -0.84, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "argent3", "Bloc", Vector3.new(0.32, 0.26, 0.08), CFrame.new(0, -0.84, -0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Boucle", "cuir", "Bloc", Vector3.new(0.14, 0.1, 0.04), CFrame.new(0, -0.84, -0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(0.46, -1.06, -0.6, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "argent3", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "argent", "Bloc", Vector3.new(0.64, 0.3, 0.1), CFrame.new(-0.46, -1.06, -0.6, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Tassette", "argent3", "Bloc", Vector3.new(0.66, 0.06, 0.12), CFrame.new(-0.46, -1.2, -0.62, 1, 0, 0, 0, 0.9945, -0.1045, 0, 0.1045, 0.9945)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.07, 0.245, 0.16), CFrame.new(-0.08, 0.5625, -0.825, 0, 0, 1, 0, 1, 0, -1, 0, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.07, 0.245, 0.16), CFrame.new(0.08, 0.5625, -0.825, 0, 0, -1, 0, 1, 0, 1, 0, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.07, 0.245, 0.16), CFrame.new(-0.08, 0.3175, -0.825, 0, 0, 1, 0, -1, 0, 1, 0, 0)},
	{"Gemme", "argent3", "Coin", Vector3.new(0.07, 0.245, 0.16), CFrame.new(0.08, 0.3175, -0.825, 0, 0, -1, 0, -1, 0, -1, 0, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.1536), CFrame.new(0.0074, 0.5255, -0.8907, -0.4908, 0.698, -0.5214, 0.2999, -0.4266, -0.8533, -0.818, -0.5752, 0), "lumiere"},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.0574), CFrame.new(-0.0476, 0.4355, -0.8907, 0.4908, 0.698, 0.5215, -0.2999, -0.4266, 0.8533, 0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.0574), CFrame.new(-0.0476, 0.4445, -0.8907, -0.4908, 0.698, 0.5214, -0.2999, 0.4266, -0.8533, -0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.1536), CFrame.new(0.0074, 0.3545, -0.8907, 0.4908, 0.698, -0.5214, 0.2999, 0.4266, 0.8533, 0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.1536), CFrame.new(-0.0074, 0.3545, -0.8907, 0.4908, -0.698, 0.5214, -0.2999, 0.4266, 0.8533, -0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.0574), CFrame.new(0.0476, 0.4445, -0.8907, -0.4908, -0.698, -0.5215, 0.2999, 0.4266, -0.8533, 0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.0574), CFrame.new(0.0476, 0.4355, -0.8907, 0.4908, -0.698, -0.5214, 0.2999, -0.4266, 0.8533, -0.818, -0.5752, 0)},
	{"Gemme", "gemme", "Coin", Vector3.new(0.03, 0.1147, 0.1536), CFrame.new(-0.0074, 0.5255, -0.8907, -0.4908, -0.698, 0.5214, -0.2999, -0.4266, -0.8533, 0.818, -0.5752, 0)},
	{"Epauliere", "amethyste", "Bloc", Vector3.new(0.44, 0.06, 0.9), CFrame.new(1.7669, 1.0083, 0, 0.8829, 0.4695, 0, -0.4695, 0.8829, 0, 0, 0, 1)},
	{"Flanc", "amethyste2", "Bloc", Vector3.new(0.06, 0.7, 0.5), CFrame.new(1.13, -0.1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Gravure", "argent3", "Bloc", Vector3.new(0.06, 0.78, 0.05), CFrame.new(0.8725, 0.36, -0.6222, 0.9781, 0, 0.2079, 0, -1, 0, 0.2079, 0, -0.9781)},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(0.6362, 0.62, -0.6908, -0.6917, 0.6917, 0.2079, 0.7071, 0.7071, 0, -0.147, 0.147, -0.9781)},
	{"Tassette", "amethyste", "Bloc", Vector3.new(0.14, 0.14, 0.05), CFrame.new(0.46, -1.06, -0.66, -0.7071, 0.7071, 0, 0.7036, 0.7036, 0.0995, 0.0704, 0.0704, -0.995)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.1, 0.14, 1.1), CFrame.new(1.0214, 1.1155, 0, 0.9903, 0.1392, 0, -0.1392, 0.9903, 0, 0, 0, 1)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(0.3083, -0.4416, -0.7241, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(0.5083, -0.4416, -0.696, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(0.7083, -0.4416, -0.6679, 0.9903, -0.0194, -0.1378, 0, 0.9903, -0.1392, 0.1392, 0.1378, 0.9806)},
	{"Epauliere", "amethyste", "Bloc", Vector3.new(0.44, 0.06, 0.9), CFrame.new(-1.7669, 1.0083, 0, 0.8829, -0.4695, 0, 0.4695, 0.8829, 0, 0, 0, 1)},
	{"Flanc", "amethyste2", "Bloc", Vector3.new(0.06, 0.7, 0.5), CFrame.new(-1.13, -0.1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	{"Gravure", "argent3", "Bloc", Vector3.new(0.06, 0.78, 0.05), CFrame.new(-0.8725, 0.36, -0.6222, 0.9781, 0, -0.2079, 0, -1, 0, -0.2079, 0, -0.9781)},
	{"Rivets", "argent3", "Bloc", Vector3.new(0.08, 0.08, 0.04), CFrame.new(-0.6362, 0.62, -0.6908, -0.6917, 0.6917, -0.2079, 0.7071, 0.7071, 0, 0.147, -0.147, -0.9781)},
	{"Tassette", "amethyste", "Bloc", Vector3.new(0.14, 0.14, 0.05), CFrame.new(-0.46, -1.06, -0.66, -0.7071, 0.7071, 0, 0.7036, 0.7036, 0.0995, 0.0704, 0.0704, -0.995)},
	{"Crete", "argent3", "Bloc", Vector3.new(0.1, 0.14, 1.1), CFrame.new(-1.0214, 1.1155, 0, 0.9903, -0.1392, 0, 0.1392, 0.9903, 0, 0, 0, 1)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(-0.3083, -0.4416, -0.7241, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(-0.5083, -0.4416, -0.696, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
	{"Fentes", "fente", "Bloc", Vector3.new(0.05, 0.17, 0.03), CFrame.new(-0.7083, -0.4416, -0.6679, 0.9903, 0.0194, 0.1378, 0, 0.9903, -0.1392, -0.1392, 0.1378, 0.9806)},
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
	modele.Name = "PlastronArgent"
	modele:SetAttribute("NomAffiche", "Plastron d'argent")

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
			l.Color = Color3.fromRGB(200, 150, 255)
			l.Range = 5
			l.Brightness = 0.7
			l.Shadows = false
			l.Parent = p
		end
		p.Parent = modele
		souder(racine, p)
	end
	return modele
end

return {
	Nom = "Plastron d'argent",
	Format = "Code",
	Taille = Vector3.new(4.2997, 2.4279, 1.7043),
	Centre = Vector3.new(0, -0.0222, -0.0838), -- centre de la boîte englobante dans le repère de Racine
	construire = construire,
}
