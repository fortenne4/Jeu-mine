local DiagnosticVide = require(script.Parent.DiagnosticVide)

local MursInvisibles = {}

-- Les repères proviennent du terrain réel. La dalle s'étend aussi sous le décor de bordure.
MursInvisibles.MIN = Vector3.new(-322, -133, -562)
MursInvisibles.MAX = Vector3.new(322, 600, 242)

local EPAISSEUR = 12
local BAS, HAUT = -150, 700
local TAILLE_SOL = Vector3.new(1800, 30, 1900)
local POSITION_SOL = Vector3.new(0, -165, -160)
local nordOuest = Vector3.new(-320, 0, -560)
local nordEst = Vector3.new(320, 0, -560)
local sudEst = Vector3.new(320, 0, 240)
local sudOuest = Vector3.new(-320, 0, 240)
local cotes = {
	{ nom = "Nord", debut = nordOuest, fin = nordEst, segments = 8 },
	{ nom = "Est", debut = nordEst, fin = sudEst, segments = 10 },
	{ nom = "Sud", debut = sudEst, fin = sudOuest, segments = 8 },
	{ nom = "Ouest", debut = sudOuest, fin = nordOuest, segments = 10 },
}

local function bloc(parent: Instance, nom: string, taille: Vector3, cf: CFrame): Part
	local existant = parent:FindFirstChild(nom)
	local part = if existant and existant:IsA("Part") then existant else Instance.new("Part")
	part.Name = nom
	part.Size = taille
	part.CFrame = cf
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

local function retirerAncienMur(dossier: Instance, nom: string)
	local ancien = dossier:FindFirstChild(nom)
	if ancien and ancien:IsA("Part") then
		ancien:Destroy()
	end
end

function MursInvisibles.construire(carte: Instance)
	local dossier = carte:FindFirstChild("InvisibleWalls")
	if not dossier then
		dossier = Instance.new("Folder")
		dossier.Name = "InvisibleWalls"
		dossier.Parent = carte
	end

	-- Le client doit garder tous les colliders, y compris en mode Streaming.
	local existant = dossier:FindFirstChild("ProtectionSurface")
	local protection = if existant and existant:IsA("Model") then existant else Instance.new("Model")
	protection.Name = "ProtectionSurface"
	protection.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local sol = bloc(protection, "SolSecours", TAILLE_SOL, CFrame.new(POSITION_SOL))
	local total = 0
	for _, cote in cotes do
		for i = 1, cote.segments do
			local debut = cote.debut:Lerp(cote.fin, (i - 1) / cote.segments)
			local fin = cote.debut:Lerp(cote.fin, i / cote.segments)
			local centre = (debut + fin) / 2 + Vector3.yAxis * ((BAS + HAUT) / 2)
			local nom = string.format("Perimetre%s%02d", cote.nom, i)
			-- Six studs de recouvrement à chaque extrémité, y compris aux angles.
			local taille = Vector3.new(EPAISSEUR, HAUT - BAS, (fin - debut).Magnitude + EPAISSEUR)
			bloc(protection, nom, taille, CFrame.lookAt(centre, centre + fin - debut))
			retirerAncienMur(dossier, nom)
			total += 1
		end
		retirerAncienMur(dossier, cote.nom)
	end
	protection.Parent = dossier

	local demi = TAILLE_SOL / 2
	local resultats = DiagnosticVide.relever({
		minX = POSITION_SOL.X - demi.X,
		maxX = POSITION_SOL.X + demi.X,
		minZ = POSITION_SOL.Z - demi.Z,
		maxZ = POSITION_SOL.Z + demi.Z,
		haut = 768,
		bas = -190,
		pas = 20,
	}, { workspace.Terrain }, { sol })
	local message = string.format(
		"Murs : %d positions validées. Vide : %d points avant, %d après (%d rayons verticaux).",
		total,
		#resultats.avant,
		#resultats.apres,
		resultats.total
	)
	if #resultats.apres == 0 then
		print(message)
	else
		warn(message, "Premier point sans sol :", resultats.apres[1])
	end
	return resultats
end

return MursInvisibles
