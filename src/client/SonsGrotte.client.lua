-- Musique et sons de la grotte −50 m (« Le Lac des Lueurs ») · SCRIPT CLIENT
-- Dans une grotte du palier 1 : une nappe d'ambiance de grotte en continu, et une musique qui change en fondu
-- selon la zone la plus proche (parts « GrotteZone » posées par GrotteLueurs : ZoneCamp, ZoneLac, ZoneForet,
-- ZoneTemple ; ailleurs, les galeries). Au camp, le feu crépite. Tout s'éteint en fondu en sortant.
-- Sons de la boutique de Studio (bibliothèque audio Roblox, utilisables librement dans le jeu).

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local joueur = Players.LocalPlayer

local AMBIANCE = {id = "rbxassetid://273398061", volume = 0.32} -- nappe de grotte (1 min 58)
local MUSIQUES = {
	Galeries = {id = "rbxassetid://140644891314737", volume = 0.22}, -- « Stone Cocoon »
	Foret = {id = "rbxassetid://72364895117540", volume = 0.3}, -- « Indoor Forest »
	Lac = {id = "rbxassetid://9039650243", volume = 0.3}, -- « Mercury Lake » (KPM)
	Temple = {id = "rbxassetid://1843880486", volume = 0.32}, -- « Rhythm Drone »
	Camp = {id = "rbxassetid://140644891314737", volume = 0.14}, -- la même nappe que les galeries, plus douce
}
local FEU = {id = "rbxassetid://2787093357", volume = 0.45} -- feu de camp (au camp seulement)
local FONDU = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local dossier = Instance.new("Folder")
dossier.Name = "SonsGrotte"
dossier.Parent = SoundService

local function son(nom: string, def): Sound
	local s = Instance.new("Sound")
	s.Name = nom
	s.SoundId = def.id
	s.Looped = true
	s.Volume = 0
	s:SetAttribute("VolumeMax", def.volume)
	s.Parent = dossier
	return s
end

local ambiance = son("Ambiance", AMBIANCE)
local feu = son("Feu", FEU)
local musiques: {[string]: Sound} = {}
for nom, def in MUSIQUES do
	musiques[nom] = son("Musique" .. nom, def)
end

local function volume(s: Sound, actif: boolean)
	local cible = if actif then s:GetAttribute("VolumeMax") or 0.3 else 0
	if actif and not s.IsPlaying then
		s:Play()
	end
	local t = TweenService:Create(s, FONDU, {Volume = cible})
	if not actif then
		t.Completed:Once(function()
			if s.Volume <= 0.001 then
				s:Pause()
			end
		end)
	end
	t:Play()
end

local function grotteAutour(pos: Vector3): Model?
	local g = workspace:FindFirstChild("Grottes")
	if not g then
		return nil
	end
	for _, m in g:GetChildren() do
		local c, d = m:GetAttribute("Centre"), m:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return m
			end
		end
	end
	return nil
end

-- zone la plus proche (au sens de son rayon) ; nil = galeries
local function zoneAutour(grotte: Model, pos: Vector3): string
	local meilleure, dmin = "Galeries", math.huge
	for _, z in CollectionService:GetTagged("GrotteZone") do
		if z:IsA("BasePart") and z:IsDescendantOf(grotte) then
			local r = z:GetAttribute("Rayon") or 20
			local d = (z.Position - pos).Magnitude
			if d < r and d / r < dmin then
				local nom = z.Name:gsub("^Zone", "")
				if musiques[nom] then
					meilleure, dmin = nom, d / r
				end
			end
		end
	end
	return meilleure
end

local zoneActuelle: string? = nil
local dansGrotte = false

while true do
	task.wait(0.6)
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local g = racine and grotteAutour(racine.Position)
	local actif = g ~= nil and g:GetAttribute("Niveau") == 1
	if actif and racine and g then
		if not dansGrotte then
			dansGrotte = true
			volume(ambiance, true)
		end
		local z = zoneAutour(g, racine.Position)
		if z ~= zoneActuelle then
			if zoneActuelle then
				volume(musiques[zoneActuelle], false)
			end
			zoneActuelle = z
			volume(musiques[z], true)
			volume(feu, z == "Camp")
		end
	elseif dansGrotte then
		dansGrotte = false
		volume(ambiance, false)
		volume(feu, false)
		if zoneActuelle then
			volume(musiques[zoneActuelle], false)
		end
		zoneActuelle = nil
	end
end
