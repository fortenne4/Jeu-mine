-- Machines et dangers des grottes profondes · SCRIPT CLIENT
-- * « Rouage » (Model, attributs Vitesse en rad/s et Axe : "X", "Y" ou "Z" du pivot) : engrenages, roues,
--   tambours qui tournent (seulement ceux proches de la caméra) ;
-- * « Geyser » (BasePart, attributs Actif / Avertit posés par DangersGrotte.server) : grondement et fumée
--   avant l'éruption, puis gerbe de feu et lumière pendant ;
-- * attribut joueur « Brule » : voile orange et braises autour du personnage quand il marche dans la lave.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local joueur = Players.LocalPlayer
local TEX_FEU = "rbxasset://textures/particles/fire_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local PORTEE = 180

-- ================= Rouages =================
local rouages = {} -- [Model] = {pivot, vitesse, axe, angle}
local function ajouterRouage(m: Instance)
	if not m:IsA("Model") or rouages[m] then
		return
	end
	local axe = m:GetAttribute("Axe")
	rouages[m] = {
		pivot = m:GetPivot(),
		vitesse = tonumber(m:GetAttribute("Vitesse")) or 0.3,
		axe = if axe == "Y" then Vector3.yAxis elseif axe == "Z" then Vector3.zAxis else Vector3.xAxis,
		angle = 0,
	}
end
CollectionService:GetInstanceAddedSignal("Rouage"):Connect(ajouterRouage)
CollectionService:GetInstanceRemovedSignal("Rouage"):Connect(function(m)
	rouages[m] = nil
end)
for _, m in CollectionService:GetTagged("Rouage") do
	ajouterRouage(m)
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local c = cam.CFrame.Position
	for m, d in rouages do
		if not m.Parent then
			rouages[m] = nil
		elseif (d.pivot.Position - c).Magnitude < PORTEE then
			-- la vitesse peut changer (rouages remis en marche) : montée en régime progressive
			local cible = tonumber(m:GetAttribute("Vitesse")) or 0
			d.vitesse += (cible - d.vitesse) * math.min(1, dt * 0.8)
			d.angle += d.vitesse * dt
			m:PivotTo(d.pivot * CFrame.fromAxisAngle(d.axe, d.angle))
		end
	end
end)

-- ================= Geysers =================
local function preparerGeyser(g: Instance)
	if not g:IsA("BasePart") or g:FindFirstChild("GerbeLocale") then
		return
	end
	local a = Instance.new("Attachment")
	a.Name = "GerbeLocale"
	a.Parent = g
	local feu = Instance.new("ParticleEmitter")
	feu.Name = "Feu"
	feu.Texture = TEX_FEU
	local teinte = g:GetAttribute("Couleur")
	feu.Color = if typeof(teinte) == "Color3" then ColorSequence.new(teinte:Lerp(Color3.new(1, 1, 1), 0.5), teinte)
		else ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 120, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 10))})
	feu.LightEmission, feu.LightInfluence = 1, 0
	feu.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})
	feu.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	feu.Lifetime = NumberRange.new(0.6, 1)
	feu.Speed = NumberRange.new(30, 42)
	feu.SpreadAngle = Vector2.new(8, 8)
	feu.EmissionDirection = Enum.NormalId.Top
	feu.Rate = 90
	feu.Enabled = false
	feu.Parent = a
	local fumee = Instance.new("ParticleEmitter")
	fumee.Name = "Fumee"
	fumee.Texture = TEX_FUMEE
	fumee.Color = ColorSequence.new(Color3.fromRGB(70, 60, 55))
	fumee.Size = NumberSequence.new(1.5, 4)
	fumee.Transparency = NumberSequence.new(0.5, 1)
	fumee.Lifetime = NumberRange.new(1, 2)
	fumee.Speed = NumberRange.new(3, 6)
	fumee.SpreadAngle = Vector2.new(15, 15)
	fumee.EmissionDirection = Enum.NormalId.Top
	fumee.Rate = 18
	fumee.Enabled = false
	fumee.Parent = a
	local l = Instance.new("PointLight")
	l.Name = "LueurGeyser"
	l.Color = if typeof(teinte) == "Color3" then teinte else Color3.fromRGB(255, 130, 40)
	l.Range, l.Brightness, l.Shadows = 22, 0, false
	l.Parent = a
	local function maj()
		local actif, avertit = g:GetAttribute("Actif") == true, g:GetAttribute("Avertit") == true
		feu.Enabled = actif
		fumee.Enabled = actif or avertit
		TweenService:Create(l, TweenInfo.new(0.3), {Brightness = if actif then 3 elseif avertit then 0.8 else 0}):Play()
	end
	g:GetAttributeChangedSignal("Actif"):Connect(maj)
	g:GetAttributeChangedSignal("Avertit"):Connect(maj)
	maj()
end
CollectionService:GetInstanceAddedSignal("Geyser"):Connect(preparerGeyser)
for _, g in CollectionService:GetTagged("Geyser") do
	preparerGeyser(g)
end

-- ================= Brûlure dans la lave =================
local braises: ParticleEmitter? = nil
local function majBrule()
	local b = joueur:GetAttribute("Brule") == true
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	if b and r and not (braises and braises.Parent == r) then
		local e = Instance.new("ParticleEmitter")
		e.Name = "BraisesBrulure"
		e.Texture = TEX_ETINCELLE
		e.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 60, 20))
		e.LightEmission = 1
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
		e.Lifetime = NumberRange.new(0.5, 1)
		e.Speed = NumberRange.new(3, 7)
		e.SpreadAngle = Vector2.new(40, 40)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = 60
		e.Parent = r
		braises = e
	elseif not b and braises then
		braises:Destroy()
		braises = nil
	end
end
joueur:GetAttributeChangedSignal("Brule"):Connect(majBrule)
