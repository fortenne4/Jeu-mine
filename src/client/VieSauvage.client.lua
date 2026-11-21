--!strict
-- Faune du décor (StarterPlayerScripts › Jeu), purement visuelle et locale à chaque joueur :
--   · chèvres (tag « ChevreDecor », posées par Bordures.lua) : broutent, relèvent la tête, regardent autour ;
--   · papillons qui volettent autour du village et des prés ;
--   · poissons qui sautent dans la rivière, avec éclaboussures.
-- Réglages en tête de fichier.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local NB_PAPILLONS = 26
local RIVIERE_Z = 82 -- Disposition.RIVIERE_Z
local RIVIERE_X = 220
local SAUT_INTERVALLE = {2.5, 6} -- secondes entre deux sauts de poisson
local DISTANCE_ANIMATION = 320 -- au-delà, les chèvres ne sont plus animées (économie)

local function attendreMonde()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 120 do
		task.wait(0.5)
	end
end
attendreMonde()

local dossier = workspace:FindFirstChild("VieSauvageDecor") or Instance.new("Folder")
dossier:ClearAllChildren()
dossier.Name = "VieSauvageDecor"
dossier.Parent = workspace

local function piece(taille: Vector3, couleur: Color3, mat: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Size = taille
	p.Color = couleur
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = dossier
	return p
end

local rayTerrain = RaycastParams.new()
rayTerrain.FilterType = Enum.RaycastFilterType.Include
rayTerrain.FilterDescendantsInstances = {workspace.Terrain}
local function sol(x: number, z: number): number
	local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -500, 0), rayTerrain)
	return if r then r.Position.Y else 0
end

local rng = Random.new()

-- ================= Chèvres =================
type Chevre = {modele: Model, nuque: CFrame, tete: {BasePart}, bases: {CFrame}, etat: string, fin: number,
	tangage: number, lacet: number, cibleT: number, cibleL: number}
local chevres: {Chevre} = {}

local function ajouterChevre(m: Instance)
	if not m:IsA("Model") then
		return
	end
	local nuque = m:GetAttribute("Nuque")
	if typeof(nuque) ~= "CFrame" then
		return
	end
	local tete, bases = {}, {}
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and string.find(p.Name, "_Tete_", 1, true) then
			table.insert(tete, p)
			table.insert(bases, p.CFrame)
		end
	end
	if #tete > 0 then
		table.insert(chevres, {modele = m, nuque = nuque, tete = tete, bases = bases, etat = "broute",
			fin = os.clock() + rng:NextNumber(1, 6), tangage = 0, lacet = 0, cibleT = 0.9, cibleL = 0})
	end
end
for _, m in CollectionService:GetTagged("ChevreDecor") do
	ajouterChevre(m)
end
CollectionService:GetInstanceAddedSignal("ChevreDecor"):Connect(ajouterChevre)

-- ================= Papillons =================
local COULEURS = {Color3.fromRGB(255, 196, 70), Color3.fromRGB(240, 120, 190), Color3.fromRGB(150, 200, 255),
	Color3.fromRGB(255, 255, 240), Color3.fromRGB(190, 140, 255), Color3.fromRGB(255, 140, 70)}
type Papillon = {ailes: {BasePart}, centre: Vector3, phase: number, rayon: number, vitesse: number}
local papillons: {Papillon} = {}
for _ = 1, NB_PAPILLONS do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(40, 150)
	local x, z = math.cos(a) * r, math.sin(a) * r
	if math.abs(z - RIVIERE_Z) < 12 then
		z += 20
	end
	local c = COULEURS[rng:NextInteger(1, #COULEURS)]
	local ailes = {piece(Vector3.new(0.5, 0.05, 0.4), c, Enum.Material.Neon), piece(Vector3.new(0.5, 0.05, 0.4), c, Enum.Material.Neon)}
	for _, aile in ailes do
		aile.Transparency = 0.15
	end
	table.insert(papillons, {ailes = ailes, centre = Vector3.new(x, sol(x, z) + rng:NextNumber(1.5, 4), z),
		phase = rng:NextNumber(0, 100), rayon = rng:NextNumber(3, 9), vitesse = rng:NextNumber(0.3, 0.7)})
end

-- ================= Poissons =================
local poisson = piece(Vector3.new(0.5, 0.7, 1.8), Color3.fromRGB(196, 206, 214), Enum.Material.Metal)
poisson.Transparency = 1
local nageoire = piece(Vector3.new(0.1, 0.6, 0.5), Color3.fromRGB(230, 140, 80))
nageoire.Transparency = 1
local gerbe = piece(Vector3.new(1, 1, 1), Color3.new())
gerbe.Transparency = 1
local eclats = Instance.new("ParticleEmitter")
eclats.Texture = "rbxasset://textures/particles/sparkles_main.dds"
eclats.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
eclats.Size = NumberSequence.new(0.5, 0.15)
eclats.Lifetime = NumberRange.new(0.5, 0.9)
eclats.Speed = NumberRange.new(6, 12)
eclats.SpreadAngle = Vector2.new(35, 35)
eclats.Acceleration = Vector3.new(0, -40, 0)
eclats.EmissionDirection = Enum.NormalId.Top
eclats.LightEmission = 0.6
eclats.Rate = 0
eclats.Parent = gerbe
local saut: {debut: number, depart: Vector3, arrivee: Vector3, hauteur: number, duree: number}? = nil
local prochainSaut = os.clock() + 2

local function nouveauSaut()
	local x = rng:NextNumber(-RIVIERE_X, RIVIERE_X)
	local z = RIVIERE_Z + rng:NextNumber(-5, 5)
	local dir = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-0.3, 0.3)).Unit
	local y = -2.2 -- surface de l'eau (Terrain.lua : eau de Y -12 à -4… lit de rivière)
	local r = workspace:Raycast(Vector3.new(x, 20, z), Vector3.new(0, -40, 0))
	if r then
		y = r.Position.Y
	end
	local depart = Vector3.new(x, y - 0.5, z)
	saut = {debut = os.clock(), depart = depart, arrivee = depart + dir * rng:NextNumber(4, 7), hauteur = rng:NextNumber(2.5, 4.5),
		duree = rng:NextNumber(0.7, 1)}
	gerbe.CFrame = CFrame.new(depart + Vector3.yAxis * 0.4)
	eclats:Emit(14)
end

-- ================= Boucle =================
local parts: {BasePart} = {}
local cfs: {CFrame} = {}
RunService.Heartbeat:Connect(function(dt)
	local maintenant = os.clock()
	local cam = workspace.CurrentCamera
	local oeil = if cam then cam.CFrame.Position else Vector3.zero
	local n = 0

	-- chèvres : broute (tête basse) ↔ regarde (tête haute, tourne) ; transitions douces
	for _, c in chevres do
		if not c.modele.Parent then
			continue
		end
		if maintenant > c.fin then
			if c.etat == "broute" then
				c.etat, c.cibleT, c.cibleL = "regarde", rng:NextNumber(-0.15, 0.1), rng:NextNumber(-0.7, 0.7)
				c.fin = maintenant + rng:NextNumber(2, 5)
			else
				c.etat, c.cibleT, c.cibleL = "broute", rng:NextNumber(0.75, 1.05), rng:NextNumber(-0.2, 0.2)
				c.fin = maintenant + rng:NextNumber(3, 8)
			end
		end
		if (c.nuque.Position - oeil).Magnitude > DISTANCE_ANIMATION then
			continue
		end
		local k = math.min(1, dt * 2.2)
		c.tangage += (c.cibleT - c.tangage) * k
		c.lacet += (c.cibleL - c.lacet) * k
		local mastication = if c.etat == "broute" then math.sin(maintenant * 9) * 0.04 else 0
		local rot = c.nuque * CFrame.Angles(0, c.lacet, 0) * CFrame.Angles(-(c.tangage + mastication), 0, 0) * c.nuque:Inverse()
		for i, p in c.tete do
			n += 1
			parts[n] = p
			cfs[n] = rot * c.bases[i]
		end
	end

	-- papillons : vol en huit irrégulier, battements rapides
	for _, p in papillons do
		local t = maintenant * p.vitesse + p.phase
		local pos = p.centre + Vector3.new(math.sin(t) * p.rayon, math.sin(t * 2.3) * 1.2 + math.sin(t * 7.1) * 0.3,
			math.sin(t * 2) * p.rayon * 0.6)
		local suivant = p.centre + Vector3.new(math.sin(t + 0.05) * p.rayon, 0, math.sin((t + 0.05) * 2) * p.rayon * 0.6)
		local base = CFrame.lookAt(pos, Vector3.new(suivant.X, pos.Y, suivant.Z))
		local bat = math.abs(math.sin(maintenant * 22 + p.phase)) * 1.2
		n += 1
		parts[n] = p.ailes[1]
		cfs[n] = base * CFrame.Angles(0, 0, bat) * CFrame.new(-0.25, 0, 0)
		n += 1
		parts[n] = p.ailes[2]
		cfs[n] = base * CFrame.Angles(0, 0, -bat) * CFrame.new(0.25, 0, 0)
	end

	-- poisson : arc au-dessus de l'eau, éclaboussures au départ et à l'arrivée
	if not saut and maintenant > prochainSaut then
		nouveauSaut()
	end
	local s = saut
	if s then
		local u = (maintenant - s.debut) / s.duree
		if u >= 1 then
			poisson.Transparency, nageoire.Transparency = 1, 1
			gerbe.CFrame = CFrame.new(s.arrivee + Vector3.yAxis * 0.4)
			eclats:Emit(18)
			saut = nil
			prochainSaut = maintenant + rng:NextNumber(SAUT_INTERVALLE[1], SAUT_INTERVALLE[2])
		else
			poisson.Transparency, nageoire.Transparency = 0, 0
			local pos = s.depart:Lerp(s.arrivee, u) + Vector3.yAxis * (4 * s.hauteur * u * (1 - u))
			local vitesse = (s.arrivee - s.depart) / s.duree + Vector3.yAxis * (4 * s.hauteur * (1 - 2 * u) / s.duree)
			local cf = CFrame.lookAt(pos, pos + vitesse) * CFrame.Angles(0, 0, math.sin(maintenant * 30) * 0.2)
			n += 1
			parts[n] = poisson
			cfs[n] = cf
			n += 1
			parts[n] = nageoire
			cfs[n] = cf * CFrame.new(0, 0.1, 1) * CFrame.Angles(0, math.sin(maintenant * 30) * 0.5, 0)
		end
	end

	for i = n + 1, #parts do
		parts[i] = nil
		cfs[i] = nil
	end
	if n > 0 then
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
