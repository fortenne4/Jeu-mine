-- Vitrine locale des mobs dans la plaine : alignés devant ZoneMobs, face à l'arrivée, Idle en boucle.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MobsVoxels = require(Partage:WaitForChild("MobsVoxels"))
local AurasMobs = require(Partage:WaitForChild("AurasMobs"))

local NOMS = {
	MineurZombie = "Mineur zombie",
	BruteProfondeurs = "Brute des profondeurs",
	ChauveSourisCave = "Chauve-souris des caves",
	RampantGaleries = "Rampant des galeries",
	ZombieLame = "Zombie à bras-lame",
	ZombieMutant = "Zombie mutant",
	ExecuteurMaudit = "Exécuteur maudit",
	GolemChampignon = "Golem champignon",
	CrabeLueur = "Crabe des lueurs",
	SpectreNain = "Spectre nain",
	RoiDechu = "Le Roi déchu",
}
local ECART, PORTEE = 6, 300

local zone = workspace:WaitForChild("PlaineMobs"):WaitForChild("ZoneMobs", math.huge)
local centre = Vector3.new(zone.Position.X, zone.Position.Y - zone.Size.Y / 2, zone.Position.Z + 140)
local face = CFrame.Angles(0, math.pi, 0) -- devant -Z -> regarde +Z (vers l'arrivée)

local dossier = Instance.new("Folder")
dossier.Name = "VitrineMobs"

local mobs, total = {}, -ECART
local BOSS_VILLAGE = {TitanCristal = true, ReineAraignee = true, SeigneurBraise = true} -- boss de l'arène : pas en vitrine
for _, id in MobsVoxels.liste() do
	if BOSS_VILLAGE[id] then continue end
	local m = MobsVoxels.construire(id)
	local taille = m:GetExtentsSize()
	table.insert(mobs, {m = m, l = taille.X, h = m:GetAttribute("Hauteur") or taille.Y})
	total += taille.X + ECART
end

local animateurs = {}
local function exposer(m: Model, pos: Vector3, h: number, nom: string, aura: string?)
	m:PivotTo(CFrame.new(pos) * face)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(180, 30)
	b.StudsOffsetWorldSpace = Vector3.new(0, h + 1.5, 0)
	b.MaxDistance = 120
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = nom
	t.Parent = b
	b.Adornee = m.PrimaryPart
	b.Parent = m
	if aura then AurasMobs.appliquer(m, aura) end
	m.Parent = dossier
	local a = MobsVoxels.animateur(m)
	a:Jouer("Idle", true, 0)
	table.insert(animateurs, a)
end

local x = -total / 2
for _, e in mobs do
	local m = e.m
	local y = if m.Name:find("ChauveSouris") then 4 elseif m.Name == "SpectreNain" then 3 else 0
	exposer(m, centre + Vector3.new(x + e.l / 2, y, 0), e.h, NOMS[m.Name] or m.Name)
	x += e.l + ECART
end

-- 2e rangée (derrière) : démo des auras de mobs
local SUFFIXE = {Violet = " (aura ki violette)", Rouge = " (aura ki rouge)"}
for i, d in {{"ZombieLame", "Violet"}, {"BruteProfondeurs", "Rouge"}, {"BruteProfondeurs", "Violet"}} do
	local m = MobsVoxels.construire(d[1])
	exposer(m, centre + Vector3.new((i - 2) * 16, 0, -18), m:GetAttribute("Hauteur") or m:GetExtentsSize().Y, NOMS[d[1]] .. SUFFIXE[d[2]], d[2])
end
dossier.Parent = workspace

local joueur = Players.LocalPlayer
RunService.Heartbeat:Connect(function(dt)
	local perso = joueur.Character
	local racine = perso and perso.PrimaryPart
	if racine and (racine.Position - centre).Magnitude < PORTEE then
		for _, a in animateurs do
			a:Pas(dt)
		end
	end
end)
