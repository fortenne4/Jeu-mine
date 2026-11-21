--!strict
-- Oiseaux du décor (StarterPlayerScripts › Jeu) : volées qui tournent autour du château fort et au-dessus de la vallée,
-- et deux grands rapaces qui planent. Purement visuel, créé chez chaque joueur (aucun échange avec le serveur).
-- Réglages : VOLEES en tête de fichier.

local RunService = game:GetService("RunService")

local DOSSIER_NOM = "OiseauxDecor"
local CHATEAU_DEFAUT = Vector3.new(-140, 243, -260)

type Volee = {centre: Vector3?, autourChateau: boolean, rayon: number, altitude: number, nombre: number, vitesse: number,
	taille: number, couleur: Color3, battement: number, plane: number}
local VOLEES: {Volee} = {
	{autourChateau = true, rayon = 70, altitude = 70, nombre = 9, vitesse = 0.16, taille = 1.6, couleur = Color3.fromRGB(30, 26, 32), battement = 9, plane = 0.35},
	{autourChateau = true, rayon = 115, altitude = 105, nombre = 6, vitesse = -0.11, taille = 1.8, couleur = Color3.fromRGB(36, 30, 36), battement = 8, plane = 0.4},
	{centre = Vector3.new(60, 0, 40), autourChateau = false, rayon = 160, altitude = 120, nombre = 8, vitesse = 0.08, taille = 1.5, couleur = Color3.fromRGB(44, 38, 44), battement = 10, plane = 0.3},
	{centre = Vector3.new(-40, 0, -60), autourChateau = false, rayon = 230, altitude = 210, nombre = 2, vitesse = 0.035, taille = 5, couleur = Color3.fromRGB(70, 52, 40), battement = 3, plane = 0.85},
}

local function piece(dossier: Instance, taille: Vector3, couleur: Color3, forme: string?): BasePart
	local p: BasePart = if forme == "coin" then Instance.new("WedgePart") else Instance.new("Part")
	p.Size = taille
	p.Color = couleur
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = dossier
	return p
end

type Oiseau = {corps: BasePart, ailes: {BasePart}, decalage: Vector3, phase: number, rayonPerso: number, taille: number}

local function attendreMonde()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 120 do
		task.wait(0.5)
	end
end

attendreMonde()
local ancien = workspace:FindFirstChild(DOSSIER_NOM)
if ancien then
	ancien:Destroy()
end
local dossier = Instance.new("Folder")
dossier.Name = DOSSIER_NOM
dossier.Parent = workspace

local chateau = CHATEAU_DEFAUT
local carte = workspace:FindFirstChild("Carte")
local fort = carte and carte:FindFirstChild("ChateauFort", true)
if fort and fort:IsA("Model") then
	chateau = fort:GetPivot().Position
end

local rng = Random.new()
local groupes: {{def: Volee, oiseaux: {Oiseau}, centre: Vector3}} = {}
for _, def in VOLEES do
	local centre = if def.autourChateau then chateau else (def.centre :: Vector3) + Vector3.new(0, 0, 0)
	local oiseaux = {}
	for _ = 1, def.nombre do
		local s = def.taille * rng:NextNumber(0.85, 1.15)
		local corps = piece(dossier, Vector3.new(0.35, 0.3, 1.1) * s, def.couleur)
		local ailes = {
			piece(dossier, Vector3.new(0.08, 0.45, 1.4) * s, def.couleur, "coin"),
			piece(dossier, Vector3.new(0.08, 0.45, 1.4) * s, def.couleur, "coin"),
		}
		table.insert(oiseaux, {corps = corps, ailes = ailes, phase = rng:NextNumber(0, math.pi * 2),
			decalage = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-1, 1)) * (6 + def.rayon * 0.08),
			rayonPerso = def.rayon * rng:NextNumber(0.85, 1.15), taille = s})
	end
	table.insert(groupes, {def = def, oiseaux = oiseaux, centre = centre})
end

local parts: {BasePart} = {}
local cframes: {CFrame} = {}
for _, g in groupes do
	for _, o in g.oiseaux do
		table.insert(parts, o.corps)
		table.insert(parts, o.ailes[1])
		table.insert(parts, o.ailes[2])
	end
end

local t0 = os.clock()
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local t = os.clock() - t0
	local n = 0
	for _, g in groupes do
		local d = g.def
		for k, o in g.oiseaux do
			-- trajectoire : grand cercle + ondulations, chaque oiseau légèrement décalé dans la volée
			local a = t * d.vitesse + (k / #g.oiseaux) * 0.6 + o.phase * 0.05
			local r = o.rayonPerso + math.sin(t * 0.4 + o.phase) * d.rayon * 0.12
			local y = g.centre.Y + d.altitude + math.sin(t * 0.7 + o.phase) * 6 + o.decalage.Y * 2
			local pos = Vector3.new(g.centre.X + math.cos(a) * r, y, g.centre.Z + math.sin(a) * r) + o.decalage
			local tangente = Vector3.new(-math.sin(a), 0, math.cos(a)) * math.sign(d.vitesse)
			local inclinaison = -0.35 * math.sign(d.vitesse)
			local base = CFrame.lookAt(pos, pos + tangente) * CFrame.Angles(0, 0, inclinaison)
			-- battement d'ailes, entrecoupé de vol plané
			local cycle = (math.sin(t * 0.5 + o.phase) + 1) / 2
			local bat = if cycle < d.plane then 0.08 else math.sin(t * d.battement + o.phase) * 0.75
			local s = o.taille
			n += 1
			cframes[n] = base
			n += 1
			cframes[n] = base * CFrame.new(-0.18 * s, 0, 0) * CFrame.Angles(0, 0, bat) * CFrame.new(-0.7 * s, 0, 0)
				* CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(0, math.pi, 0)
			n += 1
			cframes[n] = base * CFrame.new(0.18 * s, 0, 0) * CFrame.Angles(0, 0, -bat) * CFrame.new(0.7 * s, 0, 0)
				* CFrame.Angles(0, 0, -math.pi / 2)
		end
	end
	local _ = cam
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end)
