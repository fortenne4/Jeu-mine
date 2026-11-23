-- Événements aléatoires de la grotte −50 m · SCRIPT CLIENT
-- Affiche ce qu'envoie EvenementsGrotte.lua (RemoteEvent « EvenementGrotte ») : grand bandeau d'annonce,
-- messages, et effets locaux (éclats ramassés, nuée, poussière et tremblement de l'éboulement, luciole attrapée).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, texte = UI.creer, UI.texte

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("EvenementGrotte") :: RemoteEvent
local terrain = workspace.Terrain

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"

-- ================= Bandeau =================
local gui = creer("ScreenGui", {Name = "EvenementsGrotte", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 25,
	Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)
local bandeau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.2), Size = UDim2.fromScale(0.6, 0.13),
	BackgroundTransparency = 1, Visible = false, Parent = gui}, {creer("UISizeConstraint", {MaxSize = Vector2.new(820, 120)})})
local fond = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 8, 16), BackgroundTransparency = 0.25,
	Parent = bandeau}, {UI.coin(0.25), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.18, 0), NumberSequenceKeypoint.new(0.82, 0), NumberSequenceKeypoint.new(1, 1)})})})
local titre = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.9, 0.52),
	ZIndex = 2, Parent = bandeau}, 48)
local sousTitre = texte({Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(235, 228, 210), Position = UDim2.fromScale(0.1, 0.6),
	Size = UDim2.fromScale(0.8, 0.3), ZIndex = 2, Parent = bandeau}, 24)
local contour = creer("UIStroke", {Thickness = 2.5, Color = Color3.new(0, 0, 0), Transparency = 0.2, Parent = titre})

local idBandeau = 0
local function annonce(t: string, st: string, couleur: Color3)
	idBandeau += 1
	local moi = idBandeau
	titre.Text, sousTitre.Text = t, st
	titre.TextColor3 = couleur
	contour.Color = couleur:Lerp(Color3.new(0, 0, 0), 0.8)
	bandeau.Visible = true
	bandeau.Position = UDim2.fromScale(0.5, -0.2)
	TweenService:Create(bandeau, UI.BOUNCY, {Position = UDim2.fromScale(0.5, 0.1)}):Play()
	UI.jouer("ouvrir", 0.8)
	task.delay(3.6, function()
		if moi ~= idBandeau then
			return
		end
		TweenService:Create(bandeau, UI.FAST, {Position = UDim2.fromScale(0.5, -0.2)}):Play()
		task.delay(0.2, function()
			if moi == idBandeau then
				bandeau.Visible = false
			end
		end)
	end)
end

-- ================= Effets =================
local function emettre(pos: Vector3, props: {[string]: any}, n: number, duree: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = a
	e:Emit(n)
	Debris:AddItem(a, duree)
	return e
end

local function eclat(pos: Vector3, couleur: Color3, n: number)
	emettre(pos, {Texture = TEX_ETINCELLE, Color = ColorSequence.new(couleur, Color3.new(1, 1, 1)), LightEmission = 1, LightInfluence = 0,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}),
		Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Drag = 4}, n, 1.5)
end

-- tremblement de caméra (force décroissante)
local secousse = 0
RunService:BindToRenderStep("SecousseGrotte", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if secousse <= 0 then
		return
	end
	secousse = math.max(0, secousse - dt * 0.35)
	local cam = workspace.CurrentCamera
	if cam then
		local f = secousse * 0.04
		cam.CFrame *= CFrame.Angles((math.random() - 0.5) * f, (math.random() - 0.5) * f, (math.random() - 0.5) * f * 0.5)
	end
end)

local function distance(pos: Vector3): number
	local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if r then (r.Position - pos).Magnitude else math.huge
end

local function poussiere(pos: Vector3, duree: number)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {terrain}
	local haut = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), params)
	local y = if haut then haut.Position.Y - 1 else pos.Y + 14
	local a = Instance.new("Attachment")
	a.WorldPosition = Vector3.new(pos.X, y, pos.Z)
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_FUMEE
	e.Color = ColorSequence.new(Color3.fromRGB(125, 116, 104))
	e.LightInfluence = 0.7
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(1.5, 2.5)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(50, 50)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Acceleration = Vector3.new(0, -8, 0)
	e.Rate = 30
	e.Parent = a
	local g = e:Clone()
	g.Texture = TEX_ETINCELLE
	g.Color = ColorSequence.new(Color3.fromRGB(80, 74, 66))
	g.Size = NumberSequence.new(0.18)
	g.Transparency = NumberSequence.new(0)
	g.Acceleration = Vector3.new(0, -50, 0)
	g.Rate = 40
	g.Parent = a
	task.delay(duree, function()
		e.Enabled, g.Enabled = false, false
	end)
	Debris:AddItem(a, duree + 3)
end

local function nueeEffet(pos: Vector3)
	-- nuage d'ailes sombres qui jaillit
	emettre(pos + Vector3.new(0, 4, 0), {Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.fromRGB(40, 30, 45)), LightEmission = 0,
		LightInfluence = 1, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2)}),
		Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(180, 60), Drag = 1.5,
		RotSpeed = NumberRange.new(-300, 300), Rotation = NumberRange.new(0, 360)}, 60, 2.5)
	emettre(pos + Vector3.new(0, 4, 0), {Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.fromRGB(255, 70, 60)), LightEmission = 1,
		LightInfluence = 0, Size = NumberSequence.new(0.15), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 60), Drag = 1.5}, 20, 2)
	if distance(pos) < 40 then
		secousse = math.max(secousse, 0.4)
	end
end

-- ================= Messages du serveur =================
local OR = Color3.fromRGB(255, 210, 90)
local CYAN = Color3.fromRGB(120, 235, 255)
local ROUGE = Color3.fromRGB(255, 110, 90)
local AMBRE = Color3.fromRGB(255, 170, 80)

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	local pos = if typeof(d.pos) == "Vector3" then d.pos else nil
	if genre == "Pluie" then
		annonce("PLUIE DE CRISTAUX", "Ramasse les éclats avant qu'ils ne s'éteignent !", CYAN)
	elseif genre == "Eclat" and pos then
		eclat(pos, if typeof(d.couleur) == "Color3" then d.couleur else CYAN, 18)
		UI.jouer("metal", 1.5 + math.random() * 0.3)
	elseif genre == "Nuee" and pos then
		annonce("UNE NUÉE DE CHAUVES-SOURIS !", "Elles surgissent derrière toi…", ROUGE)
		task.delay(1.1, nueeEffet, pos)
	elseif genre == "Eboulement" and pos then
		annonce("ÉBOULEMENT !", "Le plafond s'effondre… recule !", AMBRE)
		local d0 = distance(pos)
		secousse = math.max(secousse, math.clamp(1.4 - d0 / 60, 0.3, 1.2))
		poussiere(pos, 3)
		UI.jouer("metal", 0.35)
	elseif genre == "Veine" then
		toast(if d.or_ then "Les gravats ont dévoilé une veine… de l'or brille !" else "Les gravats ont dévoilé une veine de bronze !", true)
		if pos then
			eclat(pos + Vector3.new(0, 1.5, 0), if d.or_ then OR else AMBRE, 30)
		end
	elseif genre == "Luciole" then
		annonce("UNE LUCIOLE DORÉE !", "Attrape-la avant qu'elle ne s'échappe (" .. tostring(d.duree or 30) .. " s)", OR)
	elseif genre == "LucioleAttrapee" then
		if pos then
			eclat(pos, OR, 50)
		end
		local moi = d.nom == joueur.DisplayName
		toast((if moi then "Luciole attrapée" else tostring(d.nom) .. " a attrapé la luciole") .. " : +" .. tostring(d.pieces or 0) .. " pièces", true)
		if moi then
			UI.celebrer(gui, OR, "LUCIOLE !")
		end
	elseif genre == "LucioleEnfuie" then
		toast("La luciole dorée s'est enfuie…", false)
	end
end)
