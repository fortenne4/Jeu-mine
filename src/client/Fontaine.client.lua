-- Effets locaux de la fontaine : eau animée et bruit à chaque entrée du joueur.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local joueur = Players.LocalPlayer
local fontaines = {}

local function piece(parent, nom, taille, couleur)
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.Color = couleur
	p.Material = Enum.Material.Glass
	p.Transparency = 0.22
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function ajouter(modele)
	if not modele:IsA("Model") or fontaines[modele] then return end
	-- Le tag peut arriver avant les enfants quand la carte est diffusée au client.
	local eau = modele:WaitForChild("Eau", 10)
	if not eau or not eau:IsA("BasePart") or not modele.Parent or fontaines[modele] then return end
	local dossier = Instance.new("Folder")
	dossier.Name = "EffetsEauLocaux"
	dossier.Parent = modele
	local son = Instance.new("Sound")
	son.Name = "Plouf"
	son.SoundId = "rbxasset://sounds/impact_water.mp3"
	son.Volume = 0.575
	son.RollOffMaxDistance = 55
	son.Parent = eau
	local info = {dossier = dossier, son = son, eau = eau, gouttes = {}, rides = {}, dedans = false}
	local rng = Random.new(451)
	for _, chute in modele:GetChildren() do
		if chute:IsA("BasePart") and (chute.Name == "ChuteGrandeVasque" or chute.Name == "ChutePetiteVasque") then
			for i = 1, 5 do
				local goutte = piece(dossier, "Goutte", Vector3.new(0.14, 0.14, 0.14), Color3.fromRGB(185, 228, 232))
				goutte.Shape = Enum.PartType.Ball
				table.insert(info.gouttes, {part = goutte, chute = chute, phase = (i - 1) / 5, vitesse = rng:NextNumber(0.55, 0.8), decalage = rng:NextNumber(-0.11, 0.11)})
			end
			local base = piece(dossier, "Eclaboussure", Vector3.new(0.1, 0.1, 0.1), Color3.new(1, 1, 1))
			base.Transparency = 1
			base.Position = chute.Position - Vector3.new(0, chute.Size.Y / 2, 0)
			local particules = Instance.new("ParticleEmitter")
			particules.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particules.Color = ColorSequence.new(Color3.fromRGB(198, 231, 232))
			particules.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0)})
			particules.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
			particules.Lifetime = NumberRange.new(0.3, 0.55)
			particules.Rate = 3
			particules.Speed = NumberRange.new(0.5, 1.4)
			particules.SpreadAngle = Vector2.new(45, 45)
			particules.Parent = base
		end
	end
	for n = 1, 3 do
		local cercle = {}
		for _ = 1, 20 do
			table.insert(cercle, piece(dossier, "Ride", Vector3.new(0.065, 0.025, 0.5), Color3.fromRGB(185, 224, 226)))
		end
		table.insert(info.rides, cercle)
	end
	fontaines[modele] = info
end

local function retirer(modele)
	local info = fontaines[modele]
	if not info then return end
	info.dossier:Destroy()
	info.son:Destroy()
	fontaines[modele] = nil
end

CollectionService:GetInstanceAddedSignal("FontaineAnimee"):Connect(ajouter)
CollectionService:GetInstanceRemovedSignal("FontaineAnimee"):Connect(retirer)
for _, modele in CollectionService:GetTagged("FontaineAnimee") do ajouter(modele) end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local racine = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
	for modele, info in fontaines do
		if not modele.Parent or not info.eau.Parent then retirer(modele); continue end
		for _, g in info.gouttes do
			local phase = (t * g.vitesse + g.phase) % 1
			g.part.Position = g.chute.Position + Vector3.new(g.decalage, (0.5 - phase * phase) * g.chute.Size.Y, g.decalage)
		end
		for n, cercle in info.rides do
			local phase = (t / 3 + (n - 1) / 3) % 1
			local rayon = 1 + phase * 3.6
			for i, p in cercle do
				local angle = (i - 1) * math.pi * 2 / #cercle
				local centre = info.eau.Position
				p.Size = Vector3.new(0.065, 0.025, math.max(0.15, 2 * math.pi * rayon / #cercle * 0.72))
				p.CFrame = CFrame.new(centre.X + math.cos(angle) * rayon, centre.Y + 0.15, centre.Z + math.sin(angle) * rayon) * CFrame.Angles(0, -angle, 0)
				p.Transparency = 0.55 + 0.43 * phase
			end
		end
		local dedans = false
		if racine then
			local d = racine.Position - info.eau.Position
			dedans = Vector2.new(d.X, d.Z).Magnitude < 9.45 and d.Y > -2 and d.Y < 2.85
		end
		if dedans and not info.dedans and (not info.dernier or t - info.dernier > 0.2) then
			info.dernier = t
			info.son:Stop()
			info.son:Play()
		end
		info.dedans = dedans
	end
end)
