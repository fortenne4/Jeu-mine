-- Fragments de la carte naine · SCRIPT CLIENT
-- Parchemin qui s'ouvre quand on ramasse un fragment (titre, morceau d'histoire, carte en 8 cases, pièces gagnées),
-- célébration quand la carte est complète. Les cachettes déjà ramassées par ce joueur sont cachées chez lui
-- (attribut « PrisPar » de la cachette). Le serveur (CarteNaine.lua) fait foi ; ici on ne fait qu'afficher.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Carte = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CarteNaine"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild(Carte.REMOTE) :: RemoteEvent

-- ================= Cachettes déjà ramassées : invisibles chez ce joueur =================
local function majCachette(m: Instance)
	local pris = m:GetAttribute("PrisPar")
	local moi = type(pris) == "string" and pris:find("," .. joueur.UserId .. ",", 1, true) ~= nil
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if moi then 1 else 0
		elseif d:IsA("ParticleEmitter") or d:IsA("ProximityPrompt") then
			d.Enabled = not moi
		end
	end
end
local function suivre(m: Instance)
	majCachette(m)
	m:GetAttributeChangedSignal("PrisPar"):Connect(function()
		majCachette(m)
	end)
end
for _, m in CollectionService:GetTagged("FragmentCarte") do
	suivre(m)
end
CollectionService:GetInstanceAddedSignal("FragmentCarte"):Connect(suivre)

-- ================= Parchemin =================
local gui = creer("ScreenGui", {Name = "CarteNaine", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 30,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)

local PAPIER = Color3.fromRGB(232, 214, 172)
local ENCRE = Color3.fromRGB(62, 40, 22)

local scene = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui})
local parchemin = creer("Frame", {Name = "Parchemin", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromScale(0.36, 0.5), BackgroundColor3 = PAPIER, Parent = scene},
	{coin(0.04), trait(Color3.fromRGB(120, 84, 44), 3), creer("UISizeConstraint", {MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(560, 470)}),
		UI.degrade(Color3.fromRGB(244, 230, 196), Color3.fromRGB(214, 190, 142), 90)})
-- rouleaux en haut et en bas
for _, y in {0, 1} do
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.new(1.06, 0, 0, 16),
		BackgroundColor3 = Color3.fromRGB(150, 104, 58), ZIndex = 3, Parent = parchemin}, {coin(1), trait(Color3.fromRGB(80, 50, 24), 2)})
end
local entete = texte({Text = "FRAGMENT DE CARTE", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(140, 90, 40),
	Position = UDim2.fromScale(0.08, 0.07), Size = UDim2.fromScale(0.84, 0.07), ZIndex = 2, Parent = parchemin}, 20)
local titre = texte({Text = "", Font = Enum.Font.Fantasy, TextColor3 = ENCRE, Position = UDim2.fromScale(0.06, 0.15),
	Size = UDim2.fromScale(0.88, 0.13), ZIndex = 2, Parent = parchemin}, 40)
local corps = texte({Text = "", Font = Enum.Font.Garamond, TextColor3 = ENCRE, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.09, 0.31), Size = UDim2.fromScale(0.82, 0.33), ZIndex = 2, Parent = parchemin}, 26)
local cases = creer("Frame", {Position = UDim2.fromScale(0.1, 0.68), Size = UDim2.fromScale(0.8, 0.11), BackgroundTransparency = 1,
	ZIndex = 2, Parent = parchemin}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center})})
local listeCases = {}
for i = 1, #Carte.FRAGMENTS do
	listeCases[i] = creer("Frame", {Size = UDim2.fromScale(0.1, 0.1), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.fromRGB(196, 170, 120),
		Rotation = if i % 2 == 0 then 3 else -3, ZIndex = 3, LayoutOrder = i, Parent = cases}, {coin(0.15), trait(Color3.fromRGB(120, 84, 44), 1.5)})
	texte({Text = tostring(i), Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(150, 120, 80), Size = UDim2.fromScale(1, 1), ZIndex = 4,
		Parent = listeCases[i]}, 18)
end
local compte = texte({Text = "", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(110, 74, 38), Position = UDim2.fromScale(0.1, 0.8),
	Size = UDim2.fromScale(0.8, 0.06), ZIndex = 2, Parent = parchemin}, 18)
local gain = texte({Text = "", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(176, 120, 20), Position = UDim2.fromScale(0.1, 0.87),
	Size = UDim2.fromScale(0.8, 0.07), ZIndex = 2, Parent = parchemin}, 24)
local fermer = creer("TextButton", {Text = "X", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = ENCRE, BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.04), Size = UDim2.fromScale(0.08, 0.08), SizeConstraint = Enum.SizeConstraint.RelativeYY,
	ZIndex = 5, Parent = parchemin})

local ouvertId = 0
local function cacher()
	ouvertId += 1
	TweenService:Create(parchemin, UI.FAST, {Position = UDim2.fromScale(0.5, 0.52)}):Play()
	task.delay(0.15, function()
		scene.Visible = false
	end)
end
fermer.Activated:Connect(cacher)

local function montrer(id: string, pieces: number, complete: boolean, origine: string?)
	local f = Carte.PAR_ID[id]
	if not f then
		return
	end
	local trouves = Carte.lire(joueur:GetAttribute("FragmentsCarte"))
	trouves[id] = true
	local n = Carte.compter(trouves)
	entete.Text = if origine == "coffre" then "FRAGMENT TROUVÉ DANS LE COFFRE" else "FRAGMENT DE CARTE N° " .. f.numero
	titre.Text = f.titre
	corps.Text = "« " .. f.texte .. " »"
	compte.Text = "Carte du royaume : " .. n .. " / " .. #Carte.FRAGMENTS .. " fragments"
	gain.Text = if complete then "CARTE COMPLÈTE !  +" .. pieces .. " pièces" else "+" .. pieces .. " pièces"
	for i, c in listeCases do
		local fi = Carte.FRAGMENTS[i]
		local a = trouves[fi.id] == true
		c.BackgroundColor3 = if a then Color3.fromRGB(214, 160, 70) else Color3.fromRGB(196, 170, 120)
		local l = c:FindFirstChildOfClass("TextLabel")
		if l then
			l.TextColor3 = if a then ENCRE else Color3.fromRGB(150, 120, 80)
		end
		if fi.id == id then
			UI.pop(c, 2)
			c.BackgroundColor3 = T.Or
		end
	end
	scene.Visible = true
	parchemin.Position = UDim2.fromScale(0.5, 0.56)
	TweenService:Create(parchemin, UI.BOUNCY, {Position = UDim2.fromScale(0.5, 0.46)}):Play()
	UI.pop(parchemin, 0.6)
	UI.jouer("ouvrir")
	task.delay(0.25, UI.jouer, "succes")
	if complete then
		task.delay(0.4, UI.celebrer, scene, T.Or, "CARTE COMPLÈTE !")
	end
	ouvertId += 1
	local moi = ouvertId
	task.delay(if complete then 14 else 10, function()
		if moi == ouvertId then
			cacher()
		end
	end)
end

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	if genre == "Fragment" then
		montrer(d.id, d.pieces or 0, d.complete == true, d.origine)
	elseif genre == "Doublon" then
		toast("Carte déjà complète : +" .. tostring(d.pieces or 0) .. " pièces", true)
	end
end)
