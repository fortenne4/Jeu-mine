-- Cercle lumineux au sol (portes des tunnels privés, sortie des mines privées).
-- Anneau de lumière blanche creux (segments néon) posé sur le sol réel, compteur « 0/1 » ;
-- activation : éclat + colonne de lumière.
local TweenService = game:GetService("TweenService")
local O = require(script.Parent.Outils)
local M, C = O.M, O.C

local Cercle = {}
Cercle.RAYON = 5.5 -- rayon de détection (studs) = rayon de l'anneau

local LIBRE = Color3.fromRGB(255, 255, 255)
local OCCUPE = Color3.fromRGB(255, 232, 176)
local SEGMENTS = 36
local ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local FONDU = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COLORES = {Anneau = true, Lueur = true, Colonne = true}

local function emetteur(parent, nom, props)
	local e: any = Instance.new("ParticleEmitter")
	e.Name = nom
	e.Texture = ETINCELLE
	e.LightEmission = 1
	e.Color = ColorSequence.new(LIBRE)
	e.EmissionDirection = Enum.NormalId.Top
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	for cle, valeur in props do
		e[cle] = valeur
	end
	e.Parent = parent
	return e
end

-- Pose le cercle sur le sol réel (terrain bosselé ou Parts) pour qu'il ne soit jamais enfoui
local function auSol(cf, ignorer)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclus = {ignorer}
	for _, joueur in game:GetService("Players"):GetPlayers() do
		if joueur.Character then table.insert(exclus, joueur.Character) end
	end
	params.FilterDescendantsInstances = exclus
	local haut = -math.huge
	for _, d in {Vector3.zero, Vector3.new(2.5, 0, 0), Vector3.new(-2.5, 0, 0), Vector3.new(0, 0, 2.5), Vector3.new(0, 0, -2.5)} do
		local hit = workspace:Raycast(cf.Position + d + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
		if hit then haut = math.max(haut, hit.Position.Y) end
	end
	if haut == -math.huge then return cf end
	return cf + Vector3.new(0, haut - cf.Position.Y, 0)
end

-- cf : centre du cercle, au sol. opts.texte remplace le compteur (ex. « Sortie »), opts.rayon le rayon (défaut RAYON).
function Cercle.construire(parent, cf, nom, opts)
	opts = opts or {}
	local R = opts.rayon or Cercle.RAYON
	local m = O.modele(parent, nom or "Cercle")
	cf = auSol(cf, m) + Vector3.new(0, 0.1, 0)
	-- Anneau blanc, creux au centre
	local longueur = 2 * math.pi * R / SEGMENTS * 1.1
	for k = 1, SEGMENTS do
		local a = k * 2 * math.pi / SEGMENTS
		O.decor(O.bloc(m, Vector3.new(0.45, 0.18, longueur), cf * CFrame.Angles(0, a, 0) * CFrame.new(R, 0.05, 0), LIBRE, M.Neon, "Anneau"))
	end
	local lueur = O.decor(O.bloc(m, Vector3.new(0.2, 0.2, 0.2), cf * CFrame.new(0, 0.6, 0), LIBRE, M.Lisse, "Lueur"))
	lueur.Transparency = 1
	local colonne = O.decor(O.cylindre(m, 9, R * 2, cf * CFrame.new(0, 4.6, 0), LIBRE, M.Neon, "Colonne"))
	colonne.Transparency = 1
	colonne.CastShadow = false
	O.lumiere(lueur, LIBRE, 1.4, 18)

	local zone = O.decor(O.bloc(m, Vector3.new(R * 1.4, 0.2, R * 1.4), cf * CFrame.new(0, 0.8, 0), Color3.new(1, 1, 1), M.Lisse, "Zone"))
	zone.Transparency = 1
	emetteur(zone, "Lueurs", {
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.3), NumberSequenceKeypoint.new(1, 0)}),
		Lifetime = NumberRange.new(1.5, 2.6),
		Rate = 6,
		Speed = NumberRange.new(1.2, 2.6),
		SpreadAngle = Vector2.new(6, 6),
	})
	emetteur(zone, "Eclat", {
		Size = NumberSequence.new(0.45, 0),
		Lifetime = NumberRange.new(0.5, 0.9),
		Rate = 0,
		Speed = NumberRange.new(8, 15),
		SpreadAngle = Vector2.new(25, 25),
	})

	local b = Instance.new("BillboardGui")
	b.Name = "Compteur"
	b.Size = UDim2.new(4, 0, 1.6, 0)
	b.StudsOffset = Vector3.new(0, 5.6, 0)
	b.MaxDistance = 70
	b.LightInfluence = 0
	b.Parent = zone
	local t = Instance.new("TextLabel")
	t.Name = "Texte"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = LIBRE
	t.TextStrokeColor3 = Color3.fromRGB(10, 14, 24)
	t.TextStrokeTransparency = 0.2
	t.Text = opts.texte or "0/1"
	t.Parent = b

	m:SetAttribute("Centre", cf.Position)
	if opts.texte then m:SetAttribute("Texte", opts.texte) end
	return m
end

-- Couleurs et compteur : libre (0/1, bleu) ou occupé (1/1, or)
function Cercle.etat(m, occupe)
	local couleur = if occupe then OCCUPE else LIBRE
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and COLORES[p.Name] then p.Color = couleur end
	end
	local lueur = m:FindFirstChild("Lueur")
	local lumiere = lueur and lueur:FindFirstChildOfClass("PointLight")
	if lumiere then lumiere.Color = couleur end
	local zone = m:FindFirstChild("Zone")
	if not zone then return end
	for _, e in zone:GetChildren() do
		if e:IsA("ParticleEmitter") then e.Color = ColorSequence.new(couleur) end
	end
	local compteur = zone:FindFirstChild("Compteur")
	local t = compteur and compteur:FindFirstChild("Texte")
	if t then
		t.Text = m:GetAttribute("Texte") or (if occupe then "1/1" else "0/1")
		t.TextColor3 = couleur
	end
end

-- Effet d'activation : gerbe d'étincelles, colonne de lumière, flash de la lampe
function Cercle.activer(m)
	local zone = m:FindFirstChild("Zone")
	local eclat = zone and zone:FindFirstChild("Eclat")
	if eclat then eclat:Emit(40) end
	local colonne = m:FindFirstChild("Colonne")
	if colonne then
		colonne.Transparency = 0.5
		TweenService:Create(colonne, FONDU, {Transparency = 1}):Play()
	end
	local lueur = m:FindFirstChild("Lueur")
	local lumiere = lueur and lueur:FindFirstChildOfClass("PointLight")
	if lumiere then
		lumiere.Brightness = 6
		TweenService:Create(lumiere, FONDU, {Brightness = 1.4}):Play()
	end
end

return Cercle
