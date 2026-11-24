--!strict
-- Géométrie des minerais (ReplicatedStorage › Partage › MineraisModeles).
-- Le serveur s'en sert pour faire pousser les minerais dans la mine (Minerais.server.lua),
-- le client pour les icônes 3D (IconesObjets) : même rocher, mêmes couleurs, mêmes matériaux.

export type Visuel = {
	rarete: string,
	taille: number,
	couleur: Color3,
	couleur2: Color3,
	materiau: Enum.Material,
	reflet: number,
	cristal: Color3,
	cristalMat: Enum.Material,
	cristaux: number,
	amas: number,
	veines: number,
	veine: Color3,
}

local MineraisModeles = {}

MineraisModeles.ORDRE = {"Charbon", "Bronze", "Fer", "Gold"}
MineraisModeles.VISUEL = {
	Charbon = {rarete = "Commun", taille = 1, couleur = Color3.fromRGB(30, 30, 34), couleur2 = Color3.fromRGB(48, 48, 54),
		materiau = Enum.Material.Slate, reflet = 0.15, cristal = Color3.fromRGB(14, 14, 20), cristalMat = Enum.Material.Glass,
		cristaux = 4, amas = 1, veines = 3, veine = Color3.fromRGB(140, 35, 12)},
	Bronze = {rarete = "Peu commun", taille = 1.05, couleur = Color3.fromRGB(180, 98, 44), couleur2 = Color3.fromRGB(140, 72, 32),
		materiau = Enum.Material.Metal, reflet = 0.1, cristal = Color3.fromRGB(255, 140, 50), cristalMat = Enum.Material.Neon,
		cristaux = 5, amas = 2, veines = 5, veine = Color3.fromRGB(255, 160, 70)},
	Fer = {rarete = "Rare", taille = 1.1, couleur = Color3.fromRGB(152, 158, 170), couleur2 = Color3.fromRGB(112, 118, 130),
		materiau = Enum.Material.Metal, reflet = 0.25, cristal = Color3.fromRGB(175, 215, 255), cristalMat = Enum.Material.Glass,
		cristaux = 6, amas = 2, veines = 5, veine = Color3.fromRGB(160, 215, 255)},
	Gold = {rarete = "Légendaire", taille = 1.2, couleur = Color3.fromRGB(255, 196, 48), couleur2 = Color3.fromRGB(232, 160, 30),
		materiau = Enum.Material.Foil, reflet = 0.2, cristal = Color3.fromRGB(255, 226, 120), cristalMat = Enum.Material.Neon,
		cristaux = 8, amas = 3, veines = 6, veine = Color3.fromRGB(255, 245, 190)},
} :: {[string]: Visuel}

local function piece(parent: Instance, nom: string, taille: Vector3, cf: CFrame, couleur: Color3, materiau: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.CFrame = cf
	p.Color = couleur
	p.Material = materiau
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
MineraisModeles.piece = piece

-- Rocher taillé : un cœur + des blocs inclinés (facettes) + des cristaux qui dépassent.
-- rng fixe = même rocher à chaque fois (icônes) ; sansCailloux = pas de cailloux au sol autour.
-- defForce : visuel hors catalogue (minerais en projet de MineraisPropositions, vitrine de la plaine).
function MineraisModeles.construire(nom: string, sol: CFrame, rng: Random?, sansCailloux: boolean?, defForce: Visuel?): (Model, Part)
	local def = defForce or MineraisModeles.VISUEL[nom]
	local r = rng or Random.new()
	local s = def.taille
	local modele = Instance.new("Model")
	modele.Name = "Minerai_" .. nom

	local centre = sol * CFrame.new(0, 1.25 * s, 0) * CFrame.Angles(0, r:NextNumber(0, math.pi * 2), 0)
	local coeur = piece(modele, "Coeur", Vector3.new(2.3, 2, 2.2) * s,
		centre * CFrame.Angles(r:NextNumber(-0.2, 0.2), 0, r:NextNumber(-0.2, 0.2)), def.couleur, def.materiau)
	coeur.Reflectance = def.reflet

	local function decor(p: Part)
		p.CanQuery = false
		p.CanCollide = false
		if p.Material == Enum.Material.Glass then
			p.Transparency = 0.15
			p.Reflectance = 0.35
		end
	end

	local function facettes(c: Vector3, rayon: number, nombre: number, echelle: number)
		for i = 1, nombre do
			local dir = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-0.5, 1), r:NextNumber(-1, 1)).Unit
			local t = Vector3.new(r:NextNumber(1, 1.6), r:NextNumber(0.8, 1.4), r:NextNumber(1, 1.6)) * s * echelle
			local cf = CFrame.new(c + dir * rayon) * CFrame.Angles(r:NextNumber(0, 6.28), r:NextNumber(0, 6.28), r:NextNumber(0, 6.28))
			local p = piece(modele, "Facette", t, cf, if i % 2 == 0 then def.couleur else def.couleur2, def.materiau)
			p.Reflectance = def.reflet
			p.CanQuery = false
		end
	end
	facettes(centre.Position, 0.8 * s, 14, 1)
	for _, decalage in {Vector3.new(1.3, -0.5, 0.6), Vector3.new(-1.2, -0.6, -0.5), Vector3.new(0.2, -0.8, -1.2)} do
		facettes((centre * CFrame.new(decalage * s)).Position, 0.35 * s, 5, 0.5)
	end

	for _ = 1, def.cristaux do
		local dir = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-0.1, 1), r:NextNumber(-1, 1)).Unit
		local pos = centre.Position + dir * 1.2 * s
		local h = r:NextNumber(0.5, 0.95) * s
		local cf = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, math.rad(45), 0)
		decor(piece(modele, "Cristal", Vector3.new(0.28 * s, h, 0.28 * s), cf, def.cristal, def.cristalMat))
	end

	for a = 1, def.amas do
		local angle = a * 2.4 + r:NextNumber(0, 1)
		local dir = Vector3.new(math.cos(angle), r:NextNumber(0.25, 0.9), math.sin(angle)).Unit
		local base = centre.Position + dir * 1.0 * s
		for _ = 1, 3 do
			local d2 = (dir + Vector3.new(r:NextNumber(-0.4, 0.4), r:NextNumber(-0.2, 0.2), r:NextNumber(-0.4, 0.4))).Unit
			local pos = base + Vector3.new(r:NextNumber(-0.2, 0.2), r:NextNumber(-0.2, 0.2), r:NextNumber(-0.2, 0.2)) * s
			local h = r:NextNumber(0.6, 1.2) * s
			local rc = r:NextNumber(0.22, 0.34) * s
			local axe = CFrame.lookAt(pos, pos + d2) * CFrame.Angles(-math.pi / 2, 0, 0)
			decor(piece(modele, "Cristal", Vector3.new(rc, h, rc), axe * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(45), 0), def.cristal, def.cristalMat))
			decor(piece(modele, "Pointe", Vector3.one * rc * 0.72, axe * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), def.cristal, def.cristalMat))
		end
	end

	for _ = 1, def.veines do
		local dir = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-0.6, 1), r:NextNumber(-1, 1)).Unit
		local pos = centre.Position + dir * 1.12 * s
		local tangente = dir:Cross(Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1))).Unit
		decor(piece(modele, "Veine", Vector3.new(0.09, 0.09, r:NextNumber(0.8, 1.6) * s), CFrame.lookAt(pos, pos + tangente), def.veine, Enum.Material.Neon))
	end

	if not sansCailloux then
		for _ = 1, 6 do
			local a = r:NextNumber(0, math.pi * 2)
			local rr = r:NextNumber(1.8, 2.8) * s
			local t = r:NextNumber(0.25, 0.55) * s
			local cf = sol * CFrame.new(math.cos(a) * rr, t * 0.3, math.sin(a) * rr) * CFrame.Angles(r:NextNumber(0, 6), r:NextNumber(0, 6), r:NextNumber(0, 6))
			local p = piece(modele, "Caillou", Vector3.new(t, t * 0.7, t * 1.2), cf, def.couleur2, def.materiau)
			p.Reflectance = def.reflet
			decor(p)
		end
	end

	modele.PrimaryPart = coeur
	return modele, coeur
end

return MineraisModeles
