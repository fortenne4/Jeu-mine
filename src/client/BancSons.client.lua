--!strict
-- Banc d'écoute des sons de minage · SCRIPT CLIENT, STUDIO UNIQUEMENT (rien en vrai jeu).
-- Dans la plaine des mobs, à droite de l'arrivée : des dalles au sol. Marcher sur une dalle joue son son.
--  • rangée du fond : les 4 recettes « tycoon » (plusieurs sons superposés) ;
--  • rangées de devant : chaque son seul, avec son nom et son ID, pour comparer couche par couche.
-- Les dalles sont locales (chaque testeur a les siennes). Supprimer ce script quand les sons sont choisis.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

if not RunService:IsStudio() then
	return
end

local joueur = Players.LocalPlayer

-- {id, volume, hauteur (PlaybackSpeed), délai en secondes}
type Couche = {number}
type Dalle = {nom: string, couches: {Couche}, couleur: Color3}

local RECETTES: {Dalle} = {
	{nom = "1. Coup sur la roche", couleur = Color3.fromRGB(170, 160, 146),
		couches = {{9118598279, 0.6, 0.8}, {9117371986, 0.7, 1.1}, {9117841338, 0.5, 1.3}}},
	{nom = "2. Charbon cassé", couleur = Color3.fromRGB(70, 70, 76),
		couches = {{9118587698, 0.7, 1}, {9117841516, 0.6, 0.9}, {9117273906, 0.5, 1.1, 0.08}}},
	{nom = "3. Bronze / Fer cassé", couleur = Color3.fromRGB(255, 154, 60),
		couches = {{9119598174, 0.7, 1}, {1169755927, 0.6, 1.1, 0.05}, {9114595903, 0.4, 1.25, 0.1}}},
	{nom = "4. Or cassé", couleur = Color3.fromRGB(255, 204, 92),
		couches = {{9119598174, 0.7, 1}, {9113728042, 0.6, 1.05, 0.05}, {9119447936, 0.5, 1.1, 0.12}, {9114369623, 0.4, 1.2, 0.2}}},
}

local SEULS: {{number | string}} = {
	{9118598279, "Rock Hit Dirt 14"}, {9117371986, "Pile Rocks 7"}, {9117841338, "Pop Airy 1"},
	{9118587698, "Rock Breaks 3"}, {9117841516, "Pop Airy 2"}, {9117273906, "Pebbles On Wood 5"},
	{9119598174, "Statue Debris 3"}, {1169755927, "Coin Collect"}, {9114595903, "Glass Clinks 9"},
	{9113728042, "Cash Register 1"}, {9119447936, "Wind Chimes 1"}, {9114369623, "Fairy Dust 1"},
	{9118622391, "Rock Impacts 8 (actuel)"}, {9118587701, "Rock Breaks 4 (actuel)"}, {9116652350, "Metal Hits 14 (actuel)"},
}

-- Minerais de valeur (bronze, fer, or) : alternatives pour le moment où le minerai éclate
local VALEUR: {Dalle} = {
	{nom = "V1. Ding cristal", couleur = Color3.fromRGB(140, 214, 255),
		couches = {{9118609567, 0.6, 1}, {9126073001, 0.45, 1, 0.05}}},
	{nom = "V2. Grosse pièce", couleur = Color3.fromRGB(205, 140, 70),
		couches = {{9119598174, 0.6, 1}, {9125509503, 0.6, 1.1, 0.04}}},
	{nom = "V3. Pièces sur bois", couleur = Color3.fromRGB(190, 150, 90),
		couches = {{9118612665, 0.6, 1}, {9113849011, 0.6, 1.05, 0.05}}},
	{nom = "V4. Ka-ching doux", couleur = Color3.fromRGB(255, 204, 92),
		couches = {{9118609567, 0.6, 1}, {9113728049, 0.4, 1.1, 0.06}}},
	{nom = "V5. Scintillement", couleur = Color3.fromRGB(200, 170, 255),
		couches = {{9114604477, 0.5, 1}, {9114369623, 0.45, 1.15, 0.05}, {9126073318, 0.35, 1.2, 0.1}}},
	{nom = "V6. Cloche d'or", couleur = Color3.fromRGB(255, 230, 150),
		couches = {{9118587698, 0.6, 1}, {9119448154, 0.4, 1.1, 0.06}, {9126073026, 0.35, 1, 0.1}}},
	{nom = "V7. Cloche + pièce (en jeu)", couleur = Color3.fromRGB(255, 190, 80),
		couches = {{9118587698, 0.44, 1}, {9119448154, 0.3, 1.1, 0.06}, {9126073026, 0.35, 1, 0.1}, {1169755927, 0.5, 1.2, 0.14}, {9112751536, 0.2, 1, 0.9}}},
}

-- Ramassage : le minerai arrive dans le sac (discret, court, un peu satisfaisant)
local RAMASSAGE: {Dalle} = {
	{nom = "R1. Pop", couleur = Color3.fromRGB(120, 200, 140), couches = {{9117843593, 0.5, 1.3}}},
	{nom = "R2. Bloop", couleur = Color3.fromRGB(110, 190, 220), couches = {{9112751536, 0.4, 1}}},
	{nom = "R3. Petit ding", couleur = Color3.fromRGB(230, 220, 150), couches = {{9126072698, 0.3, 1.2}}},
	{nom = "R4. Pop + ding", couleur = Color3.fromRGB(150, 220, 170), couches = {{9117838079, 0.45, 1.2}, {9126073011, 0.2, 1.3, 0.04}}},
	{nom = "R5. Pièce légère", couleur = Color3.fromRGB(240, 200, 110), couches = {{1169755927, 0.35, 1.2}}},
	{nom = "R6. Petites bulles", couleur = Color3.fromRGB(120, 170, 230), couches = {{9112752570, 0.4, 1}}},
	-- même son de plus en plus aigu selon la rareté (charbon → bronze → fer → or), comme dans les tycoons
	{nom = "R7. Bloop selon rareté", couleur = Color3.fromRGB(180, 140, 255),
		couches = {{9112751536, 0.4, 1}, {9112751536, 0.4, 1.12, 0.35}, {9112751536, 0.4, 1.26, 0.7}, {9112751536, 0.45, 1.5, 1.05}}},
}

local ORIGINE = Vector3.new(5050, 0, 212) -- plaine des mobs (sol à y = 0), à droite de l'arrivée (5000, z 230)

local dossier = Instance.new("Folder")
dossier.Name = "BancSons"
dossier.Parent = workspace

local function jouer(couches: {Couche})
	for _, c in couches do
		task.delay(c[4] or 0, function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxassetid://" .. c[1]
			s.Volume = c[2]
			s.PlaybackSpeed = c[3]
			s.Parent = SoundService
			SoundService:PlayLocalSound(s)
			task.delay(5, function() s:Destroy() end)
		end)
	end
end

local function texteDessus(p: BasePart, titre: string, sous: string?)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Top
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.9, if sous then 0.5 else 0.8)
	t.Position = UDim2.fromScale(0.05, if sous then 0.12 else 0.1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Text = titre
	t.Parent = g
	if sous then
		local s = t:Clone()
		s.Font = Enum.Font.GothamBold
		s.Size = UDim2.fromScale(0.9, 0.26)
		s.Position = UDim2.fromScale(0.05, 0.64)
		s.TextColor3 = Color3.fromRGB(255, 226, 160)
		s.Text = sous
		s.Parent = g
	end
end

type Zone = {partie: BasePart, couches: {Couche}, couleur: Color3, dessus: boolean}
local zones: {Zone} = {}

local function dalle(centre: Vector3, taille: number, couleur: Color3, couches: {Couche}, titre: string, sous: string?)
	local cadre = Instance.new("Part")
	cadre.Anchored, cadre.CanCollide = true, true
	cadre.Size = Vector3.new(taille + 0.6, 0.3, taille + 0.6)
	cadre.CFrame = CFrame.new(centre + Vector3.new(0, 0.15, 0))
	cadre.Color = Color3.fromRGB(40, 34, 31)
	cadre.Material = Enum.Material.Slate
	cadre.Parent = dossier
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide = true, true
	p.Size = Vector3.new(taille, 0.4, taille)
	-- le haut de la dalle est tourné pour que le texte se lise en arrivant depuis l'arrivée (+Z)
	p.CFrame = CFrame.new(centre + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, math.pi, 0)
	p.Color = couleur:Lerp(Color3.new(0, 0, 0), 0.25)
	p.Material = Enum.Material.SmoothPlastic
	p.Name = titre
	p.Parent = dossier
	texteDessus(p, titre, sous)
	table.insert(zones, {partie = p, couches = couches, couleur = couleur, dessus = false})
end

-- Panneaux en bois, face tournée vers l'arrivée (+Z)
local function panneau(position: Vector3, largeur: number, texte: string)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(largeur, 6, 0.6)
	p.CFrame = CFrame.new(position)
	p.Color = Color3.fromRGB(64, 40, 25)
	p.Material = Enum.Material.Wood
	p.Parent = dossier
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	g.LightInfluence = 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.94, 0.8)
	t.Position = UDim2.fromScale(0.03, 0.1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 204, 92)
	t.Text = texte
	t.Parent = g
end
panneau(ORIGINE + Vector3.new(14, 4, -6), 30, "BANC D'ÉCOUTE DES SONS\nMarche sur une dalle pour l'écouter")
panneau(ORIGINE + Vector3.new(71, 4, -6), 52, "MINERAIS DE VALEUR (éclat)  ·  RAMASSAGE (au sac)")

-- Minerais de valeur : rangée du fond, à droite des recettes
for i, r in VALEUR do
	dalle(ORIGINE + Vector3.new(47 + (i - 1) * 9.5, 0, 0), 8, r.couleur, r.couches, r.nom, "minerai de valeur")
end
-- Ramassage : rangée de devant, sous les minerais de valeur
for i, r in RAMASSAGE do
	dalle(ORIGINE + Vector3.new(46 + (i - 1) * 8, 0, 12), 6.5, r.couleur, r.couches, r.nom, "ramassage")
end

-- Rangée du fond : les 4 recettes (grandes dalles)
for i, r in RECETTES do
	dalle(ORIGINE + Vector3.new((i - 1) * 9.5, 0, 0), 8, r.couleur, r.couches, r.nom, "recette")
end
-- Rangées de devant : chaque son seul (petites dalles, 5 par rangée)
for i, s in SEULS do
	local col, rang = (i - 1) % 5, math.floor((i - 1) / 5)
	local id = s[1] :: number
	dalle(ORIGINE + Vector3.new(col * 7, 0, 11 + rang * 7), 5.5, Color3.fromRGB(70, 110, 150),
		{{id, 0.7, 1}}, s[2] :: string, tostring(id))
end

-- Marcher sur une dalle : on joue son son une fois, puis il faut en sortir pour la rejouer
RunService.Heartbeat:Connect(function()
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not racine or not racine:IsA("BasePart") then return end
	local pos = racine.Position
	for _, z in zones do
		local local_ = z.partie.CFrame:PointToObjectSpace(pos)
		local demi = z.partie.Size / 2
		local dessus = math.abs(local_.X) <= demi.X and math.abs(local_.Z) <= demi.Z and local_.Y > 0 and local_.Y < 6
		if dessus and not z.dessus then
			jouer(z.couches)
			z.partie.Color = z.couleur:Lerp(Color3.new(1, 1, 1), 0.4)
			z.partie.Material = Enum.Material.Neon
			TweenService:Create(z.partie, TweenInfo.new(0.6), {Color = z.couleur:Lerp(Color3.new(0, 0, 0), 0.25)}):Play()
			task.delay(0.6, function() z.partie.Material = Enum.Material.SmoothPlastic end)
		end
		z.dessus = dessus
	end
end)
