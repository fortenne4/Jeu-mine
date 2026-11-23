-- Ambiance des arènes des boss · SCRIPT CLIENT
-- Quand le serveur pose l'attribut joueur « DansArene » (BossVillage.server), l'éclairage prend l'ambiance de
-- l'arène du boss en cours (ReplicatedStorage › BossVillage, attribut Index → Partage › BossVillage.BOSS[i].id) :
--	SeigneurBraise : caverne de lave (ombre chaude, brume rougeâtre, écho d'arène)
--	TitanCristal   : géode (lumière froide bleutée, brume indigo, écho de caverne)
--	ReineAraignee  : nid (pénombre verdâtre, brume vert-violacé plus proche, écho de galerie)
-- Toujours assez clair pour lire le boss et ses zones rouges ; bloom doux (pas d'éblouissement), plus de soleil.
-- Anime aussi le décor de l'arène où l'on est : bannières et cocons qui se balancent (tag « BanniereArene »), runes
-- et œufs qui respirent (tag « RuneArene »), veines et cœurs de cristal parcourus d'une onde de lumière qui part du
-- centre (tag « EchoArene »). Tout est restauré en sortant (mort, victoire, échec).
-- Phases du boss (attribut Phase du dossier, 1..3) : la teinte devient plus intense (contraste, saturation, couleur du boss).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("BossVillage"))

local joueur = Players.LocalPlayer
local FONDU = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local PROPRIETES_LIGHTING = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogColor", "FogStart", "FogEnd"}
local PROPRIETES_ATMO = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"}

local AMBIANCES = {
	SeigneurBraise = {
		lighting = {
			Ambient = Color3.fromRGB(116, 94, 100), -- lisible partout, même loin des braseros
			OutdoorAmbient = Color3.fromRGB(92, 70, 74),
			Brightness = 0.5,
			ExposureCompensation = 0.3,
			EnvironmentDiffuseScale = 0.2,
			EnvironmentSpecularScale = 0.6,
			FogColor = Color3.fromRGB(70, 34, 26),
			FogStart = 160,
			FogEnd = 900,
		},
		atmo = {Density = 0.33, Offset = 0, Color = Color3.fromRGB(122, 58, 40), Decay = Color3.fromRGB(58, 30, 34), Glare = 0, Haze = 1.2},
		bloom = {Intensity = 0.55, Size = 24, Threshold = 1.1},
		correction = {Contrast = 0.1, Saturation = 0.08, TintColor = Color3.fromRGB(255, 238, 226), Brightness = 0.03},
		reverb = Enum.ReverbType.Arena,
	},
	TitanCristal = {
		lighting = {
			Ambient = Color3.fromRGB(104, 110, 146), -- lumière froide mais claire : le rouge des zones ressort
			OutdoorAmbient = Color3.fromRGB(78, 84, 118),
			Brightness = 0.5,
			ExposureCompensation = 0.3,
			EnvironmentDiffuseScale = 0.25,
			EnvironmentSpecularScale = 0.8, -- reflets sur la pierre polie et les cristaux
			FogColor = Color3.fromRGB(26, 30, 62),
			FogStart = 170,
			FogEnd = 800,
		},
		atmo = {Density = 0.3, Offset = 0, Color = Color3.fromRGB(78, 96, 168), Decay = Color3.fromRGB(44, 40, 96), Glare = 0, Haze = 1},
		bloom = {Intensity = 0.5, Size = 26, Threshold = 1.15},
		correction = {Contrast = 0.1, Saturation = 0.05, TintColor = Color3.fromRGB(230, 238, 255), Brightness = 0.03},
		reverb = Enum.ReverbType.Cave,
	},
	ReineAraignee = {
		lighting = {
			Ambient = Color3.fromRGB(104, 106, 96), -- pénombre oppressante mais lisible
			OutdoorAmbient = Color3.fromRGB(74, 80, 72),
			Brightness = 0.4,
			ExposureCompensation = 0.3,
			EnvironmentDiffuseScale = 0.15,
			EnvironmentSpecularScale = 0.4,
			FogColor = Color3.fromRGB(36, 44, 38),
			FogStart = 100, -- au-delà du cercle de combat (rayon 70)
			FogEnd = 460,
		},
		atmo = {Density = 0.4, Offset = 0, Color = Color3.fromRGB(86, 104, 82), Decay = Color3.fromRGB(70, 50, 84), Glare = 0, Haze = 1.8},
		bloom = {Intensity = 0.4, Size = 22, Threshold = 1.2},
		correction = {Contrast = 0.12, Saturation = -0.12, TintColor = Color3.fromRGB(236, 250, 236), Brightness = 0.02},
		reverb = Enum.ReverbType.StoneCorridor,
	},
}

local sauvegarde = nil
local cc, bloomCree = nil, nil
local effets = {}
local animation: RBXScriptConnection? = nil
local areneId: string? = nil -- arène dont l'ambiance est appliquée

-- Id de l'arène du combat en cours (dossier du serveur), Fosse par défaut
local function idArene(): string
	local dossier = ReplicatedStorage:FindFirstChild(Config.DOSSIER)
	local i = dossier and dossier:GetAttribute("Index")
	local def = type(i) == "number" and Config.BOSS[i]
	return if def and AMBIANCES[def.id] then def.id else "SeigneurBraise"
end

-- Correction de couleur renforcée selon la phase du boss (0 en phase 1)
local function correctionPhase(id: string)
	local A = AMBIANCES[id]
	local dossier = ReplicatedStorage:FindFirstChild(Config.DOSSIER)
	local p = dossier and dossier:GetAttribute("Phase")
	local k = if type(p) == "number" then math.clamp(p - 1, 0, 2) else 0
	local couleur = Color3.new(1, 1, 1)
	for _, def in Config.BOSS do
		if def.id == id then couleur = def.couleur end
	end
	local c = table.clone(A.correction)
	c.Contrast += 0.06 * k
	c.Saturation += 0.08 * k
	c.TintColor = c.TintColor:Lerp(couleur:Lerp(Color3.new(1, 1, 1), 0.45), 0.25 * k)
	return c
end

local function appliquer(id: string)
	local A = AMBIANCES[id]
	areneId = id
	SoundService.AmbientReverb = A.reverb
	Lighting.ClockTime = 0 -- pas de soleil qui passerait sous la voûte
	TweenService:Create(Lighting, FONDU, A.lighting):Play()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		TweenService:Create(atmo, FONDU, A.atmo):Play()
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "AreneBloom"
		bloom.Intensity = 0
		bloom.Parent = Lighting
		bloomCree = bloom
	end
	TweenService:Create(bloom :: BloomEffect, FONDU, A.bloom):Play()
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AreneCC"
		cc.Parent = Lighting
	end
	TweenService:Create(cc :: ColorCorrectionEffect, FONDU, correctionPhase(id)):Play()
end

local function entrer(id: string)
	if sauvegarde then
		if areneId ~= id then appliquer(id) end -- changement d'arène sans sortir : on garde la sauvegarde d'origine
		return
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	sauvegarde = {lighting = {}, atmo = {}, reverb = SoundService.AmbientReverb}
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
	for _, e in Lighting:GetChildren() do
		if (e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect")) and e.Enabled then
			e.Enabled = false
			table.insert(effets, e)
		end
	end
	appliquer(id)
end

local function sortir()
	if not sauvegarde then
		return
	end
	local s = sauvegarde
	sauvegarde = nil
	areneId = nil
	Lighting.ClockTime = s.lighting.ClockTime
	local cible = table.clone(s.lighting)
	cible.ClockTime = nil
	TweenService:Create(Lighting, FONDU, cible):Play()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and next(s.atmo) then
		TweenService:Create(atmo, FONDU, s.atmo):Play()
	end
	SoundService.AmbientReverb = s.reverb
	if bloomCree then
		local b = bloomCree
		bloomCree = nil
		local t = TweenService:Create(b, FONDU, {Intensity = 0})
		t.Completed:Once(function() b:Destroy() end)
		t:Play()
	elseif s.bloom then
		local b = Lighting:FindFirstChildOfClass("BloomEffect")
		if b then TweenService:Create(b, FONDU, s.bloom):Play() end
	end
	for _, e in effets do
		e.Enabled = true
	end
	table.clear(effets)
	if cc then
		local c = cc
		cc = nil
		local t = TweenService:Create(c, FONDU, {Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1), Brightness = 0})
		t.Completed:Once(function() c:Destroy() end)
		t:Play()
	end
end

-- Décor vivant (local), seulement dans l'arène où l'on est
local poses = setmetatable({}, {__mode = "k"}) -- bannière / cocon → pivot d'origine
local bases = setmetatable({}, {__mode = "k"}) -- lueur d'écho → transparence d'origine
local appartenance = setmetatable({}, {__mode = "k"}) -- instance → modèle d'arène (ou false)
local function areneDe(inst: Instance): Instance?
	local a = appartenance[inst]
	if a == nil then
		a = false
		local parent = inst.Parent
		while parent and parent ~= workspace do
			if parent:GetAttribute("Arene") then
				a = parent
				break
			end
			parent = parent.Parent
		end
		appartenance[inst] = a
	end
	return a or nil
end
local function ici(inst: Instance): boolean
	local a = areneDe(inst)
	return a == nil or a:GetAttribute("Arene") == areneId
end

local cumul = 0
local function animer(dt: number)
	cumul += dt
	if cumul < 1 / 20 then
		return
	end
	cumul = 0
	local t = os.clock()
	for _, b in CollectionService:GetTagged("BanniereArene") do
		if b:IsA("Model") and b.PrimaryPart and ici(b) then
			local base = poses[b]
			if not base then
				base = b:GetPivot()
				poses[b] = base
			end
			local phase = b:GetAttribute("Phase") or 0
			local angle = 0.07 * math.sin(t * 1.3 + phase) + 0.03 * math.sin(t * 2.9 + phase * 2)
			b:PivotTo(base * CFrame.Angles(angle, 0, 0.02 * math.sin(t * 0.9 + phase)))
		end
	end
	for _, r in CollectionService:GetTagged("RuneArene") do
		if r:IsA("BasePart") and ici(r) then
			local p = r.Position
			r.Transparency = 0.32 + 0.16 * math.sin(t * 1.6 + (p.X + p.Z) * 0.05)
		end
	end
	-- onde de lumière froide qui part du centre de la géode et parcourt veines et cristaux
	for _, r in CollectionService:GetTagged("EchoArene") do
		if r:IsA("BasePart") and ici(r) then
			local base = bases[r]
			if not base then
				base = r.Transparency
				bases[r] = base
			end
			local a = areneDe(r)
			local centre = a and a:GetAttribute("Centre")
			local d = if typeof(centre) == "Vector3" then (r.Position - centre).Magnitude else 0
			local onde = math.max(0, math.sin(t * 1.8 - d * 0.06)) ^ 4
			r.Transparency = math.clamp(base + 0.18 - 0.4 * onde, 0, 0.95)
		end
	end
end

local function miseAJour()
	if joueur:GetAttribute("DansArene") == true then
		entrer(idArene())
		if not animation then
			animation = RunService.Heartbeat:Connect(animer)
		end
	else
		sortir()
		if animation then
			animation:Disconnect()
			animation = nil
		end
	end
end

joueur:GetAttributeChangedSignal("DansArene"):Connect(miseAJour)
miseAJour()

task.spawn(function()
	local dossier = ReplicatedStorage:WaitForChild(Config.DOSSIER)
	dossier:GetAttributeChangedSignal("Phase"):Connect(function()
		if sauvegarde and cc and areneId then
			TweenService:Create(cc, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), correctionPhase(areneId)):Play()
		end
	end)
end)
