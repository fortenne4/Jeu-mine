-- Musique et cris des boss du village · SCRIPT CLIENT
-- Dans l'arène (attribut joueur « DansArene ») : une musique d'action propre à chaque boss (fondu à l'entrée et à la
-- sortie), un peu plus rapide et plus forte à chaque phase. Quand le boss perd des PV (attribut PV du dossier
-- ReplicatedStorage › BossVillage), il pousse un cri de douleur propre à son espèce (pas plus d'un toutes les 0,3 s).
-- Sons : bibliothèque sous licence de Roblox (APM pour les musiques, Pro Sound Effects pour les cris).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("BossVillage"))

local joueur = Players.LocalPlayer

local MUSIQUES = {
	TitanCristal = {id = "rbxassetid://9048541013", volume = 0.45}, -- « Battleground » (orchestre + percussions)
	ReineAraignee = {id = "rbxassetid://9045719040", volume = 0.5}, -- « Impending Doom » (tension sombre)
	SeigneurBraise = {id = "rbxassetid://9045721164", volume = 0.45}, -- « Belly Of The Beast » (percussions de guerre)
}

-- Cris de douleur : {id, volume, vitesse de lecture}
local CRIS = {
	TitanCristal = { -- grognements de géant, très graves, avec un craquement de roche
		{"rbxassetid://9114629203", 0.9, 0.7},
		{"rbxassetid://9114628357", 0.9, 0.7},
		{"rbxassetid://9114628321", 0.9, 0.65},
		{"rbxassetid://9119037874", 0.7, 0.8},
	},
	ReineAraignee = { -- crissements d'araignée
		{"rbxassetid://9125477768", 0.75, 1},
		{"rbxassetid://9125477600", 0.75, 1.05},
		{"rbxassetid://9125478014", 0.7, 0.95},
	},
	SeigneurBraise = { -- rugissements de bête, graves et rauques
		{"rbxassetid://9116311708", 0.85, 0.75},
		{"rbxassetid://9116311525", 0.85, 0.7},
		{"rbxassetid://9113980480", 0.8, 0.85},
	},
}

local VITESSE_PHASE = {1, 1.04, 1.08}
local VOLUME_PHASE = {1, 1.12, 1.25}
local ECART_CRIS = 0.3
local FONDU = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function son(nom: string, id: string, boucle: boolean): Sound
	local s = Instance.new("Sound")
	s.Name = nom
	s.SoundId = id
	s.Looped = boucle
	s.Volume = 0
	s.Parent = SoundService
	return s
end

local musiques: {[string]: Sound} = {}
for id, def in MUSIQUES do
	musiques[id] = son("MusiqueBoss_" .. id, def.id, true)
end

local cris: {[string]: {{any}}} = {}
for id, liste in CRIS do
	cris[id] = {}
	for i, def in liste do
		table.insert(cris[id], {son("CriBoss_" .. id .. i, def[1], false), def[2], def[3]})
	end
end

local dossier = ReplicatedStorage:WaitForChild(Config.DOSSIER)

local function bossEnCours(): string?
	local i = dossier:GetAttribute("Index")
	local def = type(i) == "number" and Config.BOSS[i] or nil
	return def and def.id or nil
end

local function phase(): number
	local p = dossier:GetAttribute("Phase")
	return if type(p) == "number" then math.clamp(p, 1, 3) else 1
end

local enCours: string? = nil

local function regler(s: Sound, id: string, duree: TweenInfo?)
	local p = phase()
	s.PlaybackSpeed = VITESSE_PHASE[p]
	TweenService:Create(s, duree or FONDU, {Volume = MUSIQUES[id].volume * VOLUME_PHASE[p]}):Play()
end

local function couper(id: string)
	local s = musiques[id]
	local t = TweenService:Create(s, FONDU, {Volume = 0})
	t:Play()
	t.Completed:Once(function()
		if enCours ~= id then s:Stop() end
	end)
end

local function miseAJour()
	local dedans = joueur:GetAttribute("DansArene") == true
	local id = if dedans then bossEnCours() else nil
	if id == enCours then return end
	if enCours then couper(enCours) end
	enCours = id
	if id and musiques[id] then
		local s = musiques[id]
		s.TimePosition = 0
		s:Play()
		regler(s, id)
	end
end

joueur:GetAttributeChangedSignal("DansArene"):Connect(miseAJour)
dossier:GetAttributeChangedSignal("Index"):Connect(miseAJour)
dossier:GetAttributeChangedSignal("Phase"):Connect(function()
	if enCours and musiques[enCours] then
		regler(musiques[enCours], enCours, TweenInfo.new(0.8))
	end
end)
miseAJour()

-- Cris de douleur quand le boss perd des PV
local dernierPV: number? = nil
local dernierCri = 0
local dernierIndex = 0

local function crier(id: string, force: number)
	local liste = cris[id]
	if not liste or #liste == 0 then return end
	local k = math.random(1, #liste)
	if k == dernierIndex and #liste > 1 then k = k % #liste + 1 end
	dernierIndex = k
	local e = liste[k]
	local s: Sound = e[1]
	s.Volume = e[2] * force
	s.PlaybackSpeed = e[3] * (0.92 + math.random() * 0.16)
	s.TimePosition = 0
	s:Play()
end

dossier:GetAttributeChangedSignal("PV"):Connect(function()
	local pv = dossier:GetAttribute("PV")
	if type(pv) ~= "number" then
		dernierPV = nil
		return
	end
	local avant = dernierPV
	dernierPV = pv
	if not avant or pv >= avant or not enCours then return end
	local maintenant = os.clock()
	if maintenant - dernierCri < ECART_CRIS then return end
	dernierCri = maintenant
	-- gros coup (≥ 2 % des PV) : cri plus fort
	local pvMax = dossier:GetAttribute("PVMax")
	local part = if type(pvMax) == "number" and pvMax > 0 then (avant - pv) / pvMax else 0
	crier(enCours, if part >= 0.02 then 1.2 else 1)
end)
