-- Ambiance des grottes profondes · SCRIPT CLIENT
-- Quand le personnage est dans la boîte d'une grotte (workspace.Grottes.*, attributs Centre / DemiTaille / Niveau),
-- l'éclairage passe en mode souterrain : plus de ciel, ambiance sombre teintée par le niveau (Partage.Grottes),
-- brouillard, étalonnage, bloom pour les lueurs, réverbération de grotte, lueur de lanterne autour du joueur.
-- Palier avec thème (THEMES) : couleurs de la roche et de l'eau changées localement (le village n'est pas visible
-- d'ici) et teinte qui suit les zones posées par le décor (parts taguées « GrotteZone » : Teinte, Rayon).
-- Tout est restauré en sortant.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))

local joueur = Players.LocalPlayer
local terrain = workspace.Terrain
local FONDU = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FONDU_ZONE = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local PROPRIETES_LIGHTING = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogColor", "FogStart", "FogEnd"}
local PROPRIETES_ATMO = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"}
local PROPRIETES_EAU = {"WaterColor", "WaterTransparency", "WaterReflectance", "WaterWaveSize", "WaterWaveSpeed"}

-- Thèmes par palier : couleurs locales de la roche et de l'eau
local THEMES = {
	[1] = { -- « Le Lac des Lueurs »
		materiaux = {
			[Enum.Material.Slate] = Color3.fromRGB(54, 60, 78),
			[Enum.Material.Basalt] = Color3.fromRGB(34, 38, 52),
			[Enum.Material.Mud] = Color3.fromRGB(40, 44, 46),
			[Enum.Material.LeafyGrass] = Color3.fromRGB(30, 104, 92),
			[Enum.Material.Cobblestone] = Color3.fromRGB(78, 82, 102),
			[Enum.Material.Ground] = Color3.fromRGB(46, 40, 60),
		},
		eau = {WaterColor = Color3.fromRGB(24, 160, 176), WaterTransparency = 0.5, WaterReflectance = 0.12, WaterWaveSize = 0.12,
			WaterWaveSpeed = 9},
		ambiance = Color3.fromRGB(60, 150, 190),
	},
}

local sauvegarde = nil -- valeurs d'origine pendant qu'on est sous terre
local actuelle = nil -- modèle de la grotte où l'on est
local cc, bloomCree = nil, nil
local effets = {} -- effets d'écran désactivés sous terre (rayons du soleil, profondeur de champ)
local teinteZone = nil

local function grotteAutour(pos: Vector3): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then
		return nil
	end
	for _, g in dossier:GetChildren() do
		local c, d = g:GetAttribute("Centre"), g:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return g
			end
		end
	end
	return nil
end

local function versCible(objet, cible, info: TweenInfo?)
	TweenService:Create(objet, info or FONDU, cible):Play()
end

local function infosNiveau(grotte: Model)
	local id = grotte:GetAttribute("Niveau") or 1
	local niveau = Grottes.niveau(id)
	local amb = niveau and niveau.ambiance or {lumiere = Color3.fromRGB(150, 200, 255), brouillard = Color3.fromRGB(30, 40, 52)}
	return amb.lumiere, amb.brouillard, THEMES[id]
end

local function entrer(grotte: Model)
	local lueur, brouillard, theme = infosNiveau(grotte)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not sauvegarde then
		sauvegarde = {lighting = {}, atmo = {}, eau = {}, materiaux = {}, reverb = SoundService.AmbientReverb}
		for _, p in PROPRIETES_LIGHTING do
			sauvegarde.lighting[p] = (Lighting :: any)[p]
		end
		if atmo then
			for _, p in PROPRIETES_ATMO do
				sauvegarde.atmo[p] = (atmo :: any)[p]
			end
		end
		if bloom then
			sauvegarde.bloom = {Intensity = bloom.Intensity, Size = bloom.Size, Threshold = bloom.Threshold}
		end
		for _, p in PROPRIETES_EAU do
			sauvegarde.eau[p] = (terrain :: any)[p]
		end
		for _, e in Lighting:GetChildren() do
			if (e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect")) and e.Enabled then
				e.Enabled = false
				table.insert(effets, e)
			end
		end
	end
	SoundService.AmbientReverb = Enum.ReverbType.Cave
	Lighting:SetAttribute("GrotteActive", true) -- LumiereSouterraine se met en retrait
	if theme then
		for mat, couleur in theme.materiaux do
			if sauvegarde.materiaux[mat] == nil then
				sauvegarde.materiaux[mat] = terrain:GetMaterialColor(mat)
			end
			terrain:SetMaterialColor(mat, couleur)
		end
		for p, v in theme.eau do
			(terrain :: any)[p] = v
		end
	end
	Lighting.ClockTime = 0 -- plus de soleil qui « traverse » la roche
	local ambiance = if theme then theme.ambiance else lueur
	versCible(Lighting, {
		Ambient = ambiance:Lerp(Color3.new(), 0.68), -- la lisibilité vient surtout des lumières de voûte du décor
		OutdoorAmbient = ambiance:Lerp(Color3.new(), 0.78),
		Brightness = 0.4,
		ExposureCompensation = 0.4,
		EnvironmentDiffuseScale = 0.15,
		EnvironmentSpecularScale = 0.7, -- la roche mouillée et l'eau gardent des reflets
		FogColor = brouillard,
		FogStart = 70,
		FogEnd = 430,
	})
	if atmo then
		versCible(atmo, {Density = 0.2, Offset = 0, Color = brouillard:Lerp(lueur, 0.2), Decay = brouillard, Glare = 0, Haze = 0.3})
	end
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "GrotteBloom"
		bloom.Intensity, bloom.Size, bloom.Threshold = 0, 28, 0.9
		bloom.Parent = Lighting
		bloomCree = bloom
	end
	versCible(bloom, {Intensity = 0.55, Size = 26, Threshold = 0.9})
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "GrotteCC"
		cc.Parent = Lighting
	end
	teinteZone = nil
	versCible(cc, {Contrast = 0.08, Saturation = 0.2, TintColor = Color3.new(1, 1, 1):Lerp(lueur, 0.12), Brightness = 0.02})
end

-- Teinte de la zone la plus proche (camp ambré, lacs cyan, forêt magenta, temple violet…)
local function suivreZones(grotte: Model, pos: Vector3)
	local lueur, brouillard = infosNiveau(grotte)
	local meilleure, dmin = nil, math.huge
	for _, z in CollectionService:GetTagged("GrotteZone") do
		if z:IsA("BasePart") and z:IsDescendantOf(grotte) then
			local r = z:GetAttribute("Rayon") or 20
			local d = (z.Position - pos).Magnitude
			if d < r and d / r < dmin then
				meilleure, dmin = z, d / r
			end
		end
	end
	local teinte = if meilleure then meilleure:GetAttribute("Teinte") else lueur
	if typeof(teinte) ~= "Color3" or teinte == teinteZone then
		return
	end
	teinteZone = teinte
	if cc then
		versCible(cc, {TintColor = Color3.new(1, 1, 1):Lerp(teinte, 0.07)}, FONDU_ZONE)
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		versCible(atmo, {Color = brouillard:Lerp(teinte, 0.18), Decay = brouillard:Lerp(teinte, 0.08)}, FONDU_ZONE)
	end
	versCible(Lighting, {Ambient = teinte:Lerp(Color3.new(), 0.78)}, FONDU_ZONE)
end

local function sortir()
	if not sauvegarde then
		return
	end
	local s = sauvegarde
	sauvegarde = nil
	teinteZone = nil
	Lighting:SetAttribute("GrotteActive", nil)
	Lighting.ClockTime = s.lighting.ClockTime
	local cible = table.clone(s.lighting)
	cible.ClockTime = nil
	versCible(Lighting, cible)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and next(s.atmo) then
		versCible(atmo, s.atmo)
	end
	SoundService.AmbientReverb = s.reverb
	for mat, couleur in s.materiaux do
		terrain:SetMaterialColor(mat, couleur)
	end
	for p, v in s.eau do
		(terrain :: any)[p] = v
	end
	if bloomCree then
		local b = bloomCree
		bloomCree = nil
		local t = TweenService:Create(b, FONDU, {Intensity = 0})
		t.Completed:Once(function()
			b:Destroy()
		end)
		t:Play()
	elseif s.bloom then
		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if b then
			versCible(b, s.bloom)
		end
	end
	for _, e in effets do
		e.Enabled = true
	end
	table.clear(effets)
	if cc then
		local c = cc
		cc = nil
		local t = TweenService:Create(c, FONDU, {Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1), Brightness = 0})
		t.Completed:Once(function()
			c:Destroy()
		end)
		t:Play()
	end
end

-- Lueur de lanterne autour du personnage (visible par lui seul) : on voit où l'on marche sans tuer l'obscurité
local function lanterne(racine: BasePart?, allumer: boolean)
	if not racine then
		return
	end
	local l = racine:FindFirstChild("LueurGrotte") :: PointLight?
	if allumer and not l then
		local n = Instance.new("PointLight")
		n.Name = "LueurGrotte"
		n.Color = Color3.fromRGB(255, 214, 160)
		n.Brightness = 0
		n.Range = 28
		n.Shadows = false
		n.Parent = racine
		versCible(n, {Brightness = 0.45})
	elseif not allumer and l then
		l:Destroy()
	end
end

while true do
	task.wait(0.5)
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local g = racine and grotteAutour(racine.Position)
	lanterne(racine, g ~= nil)
	if g ~= actuelle then
		actuelle = g
		if g then
			entrer(g)
		else
			sortir()
		end
	end
	if g and racine then
		suivreZones(g, racine.Position)
	end
end
