-- Boss du village · outils CLIENT partagés par BossVillage.client et ses modules (BossAttente, BossCinematique,
-- BossCombat, BossResultats) : sons intégrés de Roblox (aucun asset externe), secousse de caméra, blocage des
-- contrôles, avatars des joueurs (miniatures en cache), écrans communs.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer = UI.creer

local Outils = {}

-- ================= Sons (seulement des sons déjà utilisés dans le jeu : rbxasset://sounds/…) =================
local SONS = {
	grondement = {"rbxasset://sounds/electronicpingshort.wav", 0.4, 0.35}, -- grave : rugissement, phase, chargement
	impact = {"rbxasset://sounds/swordslash.wav", 0.45, 0.55},             -- coup sourd : secousse, bannière
	lame = {"rbxasset://sounds/unsheath.wav", 0.55, 0.85},                 -- carte de nom, MVP
	metal = {"rbxasset://sounds/button.wav", 0.5, 1},                      -- arrivée d'un joueur dans la file
	souffle = {"rbxasset://sounds/unsheath.wav", 0.3, 1},                   -- fondus, panneaux
	ping = {"rbxasset://sounds/electronicpingshort.wav", 0.45, 1},         -- compte à rebours, victoire
	clic = {"rbxasset://sounds/clickfast.wav", 0.5, 1},
}
local sons: {[string]: {Sound | number}} = {}
for nom, s in SONS do
	sons[nom] = {creer("Sound", {Name = "Boss_" .. nom, SoundId = s[1], Volume = s[2], Parent = SoundService}), s[3]}
end

function Outils.jouer(nom: string, vitesse: number?, volume: number?)
	local e = sons[nom]
	if not e then return end
	local s = e[1] :: Sound
	s.PlaybackSpeed = (e[2] :: number) * (vitesse or 1) * (0.96 + math.random() * 0.08)
	if volume then s.Volume = volume else s.Volume = SONS[nom][2] end
	SoundService:PlayLocalSound(s)
end

-- ================= Secousse de caméra (modèle « trauma » : force cumulée qui retombe) =================
-- L'offset est retiré avant le module caméra et réappliqué après : aucune dérive, marche en Custom et en Scriptable.
local trauma = 0
local dernier: CFrame? = nil
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	dernier = nil
end)

RunService:BindToRenderStep("BossSecousseAvant", Enum.RenderPriority.Camera.Value - 1, function()
	if dernier and camera then
		camera.CFrame *= dernier:Inverse()
		dernier = nil
	end
end)
RunService:BindToRenderStep("BossSecousseApres", Enum.RenderPriority.Camera.Value + 2, function(dt)
	if trauma <= 0 or not camera then return end
	trauma = math.max(0, trauma - dt * 1.5)
	local s = trauma * trauma
	local t = os.clock() * 24
	local off = CFrame.Angles(math.noise(t, 1.3) * 0.07 * s, math.noise(t, 7.1) * 0.07 * s, math.noise(t, 13.7) * 0.05 * s)
	camera.CFrame *= off
	dernier = off
end)

-- force 0..1 (0.25 léger, 0.5 fort, 0.9 énorme)
function Outils.secouer(force: number)
	trauma = math.min(1, trauma + force)
end

-- ================= Contrôles (module de contrôles par défaut, sans jamais l'attendre) =================
local controlesCoupes = 0
local function modules()
	local joueur = Players.LocalPlayer
	local scripts = joueur:FindFirstChild("PlayerScripts")
	local pm = scripts and scripts:FindFirstChild("PlayerModule")
	local ok, module = pcall(function()
		return if pm and pm:IsA("ModuleScript") then require(pm) else nil
	end)
	return if ok and module and module.GetControls then module:GetControls() else nil
end

-- Compteur : plusieurs écrans peuvent couper les contrôles ; ils reviennent quand tous les ont rendus
function Outils.controles(actifs: boolean)
	controlesCoupes = math.max(0, controlesCoupes + (if actifs then -1 else 1))
	local c = modules()
	if c then
		if controlesCoupes > 0 then c:Disable() else c:Enable() end
	end
end

function Outils.libererControles()
	controlesCoupes = 0
	local c = modules()
	if c then c:Enable() end
end

-- ================= Avatars =================
local miniatures: {[number]: string} = {}
local enCours: {[number]: {ImageLabel}} = {}

-- Pose la miniature (tête) du joueur sur l'image, en cache ; l'initiale du nom reste en dessous si ça échoue
function Outils.avatar(id: number, image: ImageLabel)
	local url = miniatures[id]
	if url then
		image.Image = url
		return
	end
	local attente = enCours[id]
	if attente then
		table.insert(attente, image)
		return
	end
	enCours[id] = {image}
	task.spawn(function()
		local ok, res = false, nil
		if id > 0 then
			ok, res = pcall(Players.GetUserThumbnailAsync, Players, id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end
		local liste = enCours[id]
		enCours[id] = nil
		if ok and type(res) == "string" then
			miniatures[id] = res
			for _, i in liste or {} do
				if i.Parent then i.Image = res end
			end
		end
	end)
end

-- Médaillon rond : fond, initiale, miniature par-dessus, liseré
function Outils.medaillon(parent: Instance, id: number, nom: string, couleur: Color3, props: {[string]: any}?): Frame
	local p = props or {}
	p.BackgroundColor3 = p.BackgroundColor3 or UI.T.FerSombre
	p.Parent = parent
	local m = creer("Frame", p, {UI.coin(0.5), UI.trait(couleur, 2)})
	UI.texte({Text = string.upper(string.sub(nom, 1, 1)), Font = Enum.Font.GothamBlack, TextColor3 = UI.T.Gris,
		Size = UDim2.fromScale(1, 1), ZIndex = (p.ZIndex or 1), Parent = m}, 30)
	local img = creer("ImageLabel", {Name = "Avatar", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = (p.ZIndex or 1) + 1,
		Parent = m}, {UI.coin(0.5)})
	Outils.avatar(id, img)
	return m
end

-- Icône d'épées croisées dessinée (aucun glyphe de police : jamais de rectangle vide)
function Outils.epees(parent: Instance, couleur: Color3, props: {[string]: any}?): Frame
	local p = props or {}
	p.BackgroundTransparency = 1
	p.SizeConstraint = p.SizeConstraint or Enum.SizeConstraint.RelativeYY
	p.Parent = parent
	local f = creer("Frame", p)
	for _, angle in {45, -45} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.95),
			Rotation = angle, BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = p.ZIndex, Parent = f},
			{UI.coin(0.5), UI.trait(Color3.fromRGB(30, 16, 8), 1.2, 0.2)})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + 0.28 * math.sin(math.rad(angle)), 0.5 + 0.28 * math.cos(math.rad(angle))),
			Size = UDim2.fromScale(0.42, 0.12), Rotation = angle, BackgroundColor3 = couleur:Lerp(Color3.new(0, 0, 0), 0.25), BorderSizePixel = 0,
			ZIndex = p.ZIndex, Parent = f}, {UI.coin(0.5)})
	end
	return f
end

-- Couronne dessinée (MVP) : bandeau + trois pointes
function Outils.couronne(parent: Instance, props: {[string]: any}?): Frame
	local p = props or {}
	p.BackgroundTransparency = 1
	p.Parent = parent
	local f = creer("Frame", p, {creer("UIAspectRatioConstraint", {AspectRatio = 1.4})})
	local or_ = UI.T.Or
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.9, 0.34),
		BackgroundColor3 = or_, BorderSizePixel = 0, ZIndex = p.ZIndex, Parent = f}, {UI.coin(0.2), UI.trait(UI.T.OrFonce, 1.5),
		UI.degrade(Color3.fromRGB(255, 245, 200), Color3.fromRGB(210, 140, 40))})
	for i, x in {0.18, 0.5, 0.82} do
		local h = if i == 2 then 0.62 else 0.5
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1 - 0.34 - h * 0.25), Size = UDim2.fromScale(h * 0.42, h * 0.42),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = or_, BorderSizePixel = 0, ZIndex = p.ZIndex, Parent = f},
			{UI.trait(UI.T.OrFonce, 1.5), UI.degrade(Color3.fromRGB(255, 245, 200), Color3.fromRGB(210, 140, 40), 45)})
	end
	return f
end

return Outils
