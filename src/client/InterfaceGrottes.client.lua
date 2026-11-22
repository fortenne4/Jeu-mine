--!strict
-- Grottes profondes · INTERFACE (StarterPlayerScripts › Jeu)
-- 1. Choix de la profondeur (ouvert par le serveur quand le chef entre dans le cercle) : 5 paliers, une barre de
--    danger chacun (selon l'équipement du joueur), agrandissement au survol, bloc « Groupe » avec invitation.
-- 2. Carte d'invitation (Accepter / Refuser, 20 s) et petites notifications.
-- Le serveur (Grottes.server.lua) fait foi : ici on affiche et on demande, rien de plus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local T, creer, coin, trait, texte, jouer = UI.T, UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Grottes")
local function remote(nom: string): RemoteEvent
	return dossier:WaitForChild(nom) :: RemoteEvent
end
local evOuvrir, evFermer, evChoisir, evQuitter = remote("Ouvrir"), remote("Fermer"), remote("Choisir"), remote("Quitter")
local evInviter, evInvitation, evRepondre, evMessage = remote("Inviter"), remote("Invitation"), remote("Repondre"), remote("Message")

local LARGEUR, HAUTEUR = 760, 500 -- taille de conception (mise à l'échelle par UIScale)
local CRISTAL = Color3.fromRGB(120, 210, 255)
local BOUTON_BLEU = Color3.fromRGB(56, 140, 205)
local DUREE_INVITATION = 20
local TACTILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local BLANC = Color3.new(1, 1, 1)
local ENCRE = Color3.fromRGB(24, 14, 8)

local SURVOL = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FAST, BOUNCY = UI.FAST, UI.BOUNCY

-- ================= État =================
local ouverte = false
local estChef = false
local chefId = 0
local membres: {{userId: number, nom: string}} = {}
local invitesServeur: {[number]: boolean} = {}
local invitesLocales: {[number]: number} = {} -- invitation envoyée, pas encore confirmée par le serveur
local attente = false -- le chef a choisi, on attend le départ
local choisiId: number? = nil
local selectionTactile: number? = nil
local boucles: {Tween} = {}

-- ================= Petits outils =================
local function arrondi(px: number): UICorner
	return creer("UICorner", {CornerRadius = UDim.new(0, px)})
end

local function echapper(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function estMembre(userId: number): boolean
	for _, m in membres do
		if m.userId == userId then
			return true
		end
	end
	return false
end

local function estInvite(userId: number): boolean
	if invitesServeur[userId] then
		return true
	end
	local t = invitesLocales[userId]
	return t ~= nil and os.clock() - t < DUREE_INVITATION
end

local function stats(): {pioche: number, epee: number, defense: number}
	local function n(nom: string): number
		local v = joueur:GetAttribute(nom)
		return if type(v) == "number" then v else 0
	end
	return {pioche = n("StatPioche"), epee = n("StatEpee"), defense = n("StatDefense")}
end

-- Avatars (mis en cache)
local cacheAvatar: {[number]: string} = {}
local function avatar(userId: number, image: ImageLabel)
	image:SetAttribute("UserId", userId)
	local c = cacheAvatar[userId]
	if c then
		image.Image = c
		return
	end
	image.Image = ""
	task.spawn(function()
		local ok, contenu = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and type(contenu) == "string" then
			cacheAvatar[userId] = contenu
			if image:GetAttribute("UserId") == userId then
				image.Image = contenu
			end
		end
	end)
end

-- Amis (mis en cache, demandés une seule fois)
local rafraichirListe: () -> () = function() end
local cacheAmis: {[number]: boolean} = {}
local demandesAmis: {[number]: boolean} = {}
local function estAmi(userId: number): boolean
	local c = cacheAmis[userId]
	if c ~= nil then
		return c
	end
	if not demandesAmis[userId] then
		demandesAmis[userId] = true
		task.spawn(function()
			local ok, ami = pcall(function()
				return joueur:IsFriendsWith(userId)
			end)
			cacheAmis[userId] = ok and ami == true
			task.defer(rafraichirListe)
		end)
	end
	return false
end

-- Avatar rond (cercle + image)
local function medaillon(parent: Instance, props: {[string]: any}, couleur: Color3, z: number): (Frame, ImageLabel, UIStroke)
	props.BackgroundColor3 = T.Fond3D
	props.ZIndex = z
	props.Parent = parent
	local bord = trait(couleur, 2.5)
	local cercle = creer("Frame", props, {coin(0.5), bord, UI.degrade(Color3.fromRGB(120, 110, 130), Color3.fromRGB(40, 34, 44))})
	local image = creer("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z + 1, Parent = cercle}, {coin(0.5)})
	return cercle, image, bord
end

-- Bouton simple (Accepter / Refuser…)
local function boutonSimple(props: {[string]: any}, libelle: string, couleur: Color3, tailleMax: number?): (TextButton, TextLabel)
	props.Text, props.AutoButtonColor, props.BackgroundColor3 = "", false, couleur
	local b = creer("TextButton", props, {arrondi(12), trait(ENCRE, 2.5),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, BLANC),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 225, 225)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140))})})})
	creer("Frame", {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.92, 0.36), BackgroundColor3 = BLANC,
		BackgroundTransparency = 0.84, BorderSizePixel = 0, ZIndex = (props.ZIndex or 1) + 1, Parent = b}, {coin(0.5)})
	local l = texte({Text = libelle, Font = Enum.Font.GothamBlack, TextColor3 = BLANC, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.52), ZIndex = (props.ZIndex or 1) + 2, Parent = b}, tailleMax or 22)
	creer("UIStroke", {Thickness = 2, Color = ENCRE, Transparency = 0.2, Parent = l})
	UI.reactif(b, 1.06)
	return b, l
end

-- Bouton fermer rond (✕)
local function boutonFermer(props: {[string]: any}): TextButton
	props.Text, props.Font, props.TextScaled, props.TextColor3 = "X", Enum.Font.GothamBlack, true, T.Parchemin
	props.BackgroundColor3, props.AutoButtonColor = Color3.fromRGB(140, 46, 34), false
	local b = creer("TextButton", props, {coin(0.5), trait(T.Fer, 3), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150)),
		creer("UIPadding", {PaddingTop = UDim.new(0.24, 0), PaddingBottom = UDim.new(0.24, 0)})})
	UI.reactif(b, 1.1)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, FAST, {Rotation = 90}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, FAST, {Rotation = 0}):Play()
	end)
	return b
end

-- Grappe de cristaux (décor)
local function cristaux(parent: Instance, pos: UDim2, echelle: number, couleur: Color3, z: number, graine: number)
	local rng = Random.new(graine)
	local grappe = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = pos, Size = UDim2.fromOffset(60 * echelle, 60 * echelle),
		BackgroundTransparency = 1, ZIndex = z, Parent = parent})
	local lueur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromScale(1.6, 0.9),
		BackgroundColor3 = couleur, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = z, Parent = grappe}, {coin(0.5),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1)})})})
	UI.boucle(lueur, TweenInfo.new(1.8 + rng:NextNumber() * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundTransparency = 0.92}, boucles)
	for k = 1, 5 do
		local h = rng:NextNumber(0.45, 1) * (if k == 3 then 1 else 0.75)
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.2 + (k - 1) * 0.15, 1),
			Size = UDim2.fromScale(0.16 + rng:NextNumber() * 0.06, h), Rotation = (k - 3) * 14 + rng:NextNumber(-6, 6),
			BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = z + 1, Parent = grappe}, {coin(0.35), trait(couleur:Lerp(Color3.new(0, 0, 0), 0.5), 1.2, 0.2),
			creer("UIGradient", {Rotation = 0, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(235, 235, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 170)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 80, 120))})})})
	end
	return grappe
end

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "GrottesProfondes", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})
local voile = creer("TextButton", {Name = "Voile", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = T.Voile, BackgroundTransparency = 1, Parent = gui},
	{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 0.1)})})})

-- ================= Fond d'écran : galerie de mine (derrière la fenêtre) =================
-- Paroi rocheuse et veines de minerai, coffrage en bois ferré, lanternes suspendues, rails qui s'enfoncent,
-- wagonnet chargé, pioche contre un poteau, cristaux. Tout en Frames (aucune image à importer).
local decorMine = creer("CanvasGroup", {Name = "DecorMine", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(104, 86, 76),
	GroupTransparency = 1, BorderSizePixel = 0, Parent = voile},
	{creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 226)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(205, 186, 176)), ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 108, 116))})})})
do
	local BOIS, BOIS_SOMBRE, FER = Color3.fromRGB(112, 74, 44), Color3.fromRGB(58, 36, 22), Color3.fromRGB(92, 94, 104)
	local rng = Random.new(31)
	local function bloc(props: {[string]: any}, enfants: {Instance}?): Frame
		props.BorderSizePixel = 0
		props.Parent = props.Parent or decorMine
		return creer("Frame", props, enfants)
	end
	-- Paroi : blocs de roche irréguliers et strates
	for _ = 1, 70 do
		local s = rng:NextNumber(0.05, 0.16)
		local teinte = Color3.fromRGB(70, 58, 54):Lerp(Color3.fromRGB(120, 104, 96), rng:NextNumber())
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber(0, 0.78)),
			Size = UDim2.fromScale(s * rng:NextNumber(1, 1.8), s), SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = rng:NextNumber(-25, 25),
			BackgroundColor3 = teinte, BackgroundTransparency = rng:NextNumber(0.55, 0.8), ZIndex = 1}, {coin(rng:NextNumber(0.15, 0.4))})
	end
	for k = 1, 6 do
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.1 + k * 0.11), Size = UDim2.new(1.3, 0, 0, 3),
			Rotation = rng:NextNumber(-6, 6), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.82, ZIndex = 2})
	end
	-- Veines de minerai (charbon, cuivre, or, cristal) qui brillent un peu
	local veines = {Color3.fromRGB(28, 28, 32), Color3.fromRGB(205, 120, 60), Color3.fromRGB(255, 205, 70), CRISTAL}
	for _ = 1, 34 do
		local c = veines[rng:NextInteger(1, #veines)]
		local x = if rng:NextNumber() < 0.5 then rng:NextNumber(0.02, 0.26) else rng:NextNumber(0.74, 0.98)
		local p = bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, rng:NextNumber(0.12, 0.7)),
			Size = UDim2.fromScale(rng:NextNumber(0.012, 0.024), rng:NextNumber(0.012, 0.024)), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Rotation = 45, BackgroundColor3 = c, ZIndex = 3}, {coin(0.25), trait(Color3.new(0, 0, 0), 1, 0.4), UI.degrade(BLANC, Color3.fromRGB(140, 140, 140), 45)})
		if c ~= veines[1] then
			UI.boucle(p, TweenInfo.new(rng:NextNumber(1.2, 2.4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 1)),
				{BackgroundTransparency = 0.45}, boucles)
		end
	end
	-- Sol de terre battue
	bloc({AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.24), BackgroundColor3 = Color3.fromRGB(58, 42, 34), ZIndex = 4},
		{creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(160, 130, 110), Color3.fromRGB(70, 56, 50))})})
	-- Rails qui fuient vers le centre (point de fuite derrière la fenêtre)
	local fuite = Vector2.new(0.5, 0.74)
	for _, bas in {0.3, 0.7} do
		local dx, dy = bas - fuite.X, 1.02 - fuite.Y
		local longueur = math.sqrt(dx * dx * 2.2 + dy * dy) -- écran ≈ 16/9 : x compte plus
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((bas + fuite.X) / 2, (1.02 + fuite.Y) / 2), Size = UDim2.new(0, 7, longueur, 0),
			Rotation = math.deg(math.atan2(-dx * 1.6, dy)), BackgroundColor3 = Color3.fromRGB(150, 150, 160), ZIndex = 6},
			{trait(Color3.fromRGB(30, 26, 26), 1.5), UI.degrade(BLANC, Color3.fromRGB(90, 90, 100), 0)})
	end
	for k = 0, 7 do
		local t = (k / 8) ^ 1.6
		local y = 1 - t * (1 - fuite.Y)
		local demi = (0.7 - 0.5) * (1 - t) + 0.02
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.new(demi * 2.6, 0, 0, math.max(4, 16 * (1 - t))),
			BackgroundColor3 = BOIS_SOMBRE, ZIndex = 5}, {trait(Color3.new(0, 0, 0), 1, 0.4)})
	end
	-- Coffrage : deux poteaux, une poutre, des jambes de force, ferrures rivetées
	for _, x in {0.035, 0.965} do
		bloc({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0), Size = UDim2.new(0.055, 0, 1, 0), BackgroundColor3 = BOIS, ZIndex = 7},
			{trait(BOIS_SOMBRE, 3), creer("UIGradient", {Rotation = 0, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 140, 130)),
				ColorSequenceKeypoint.new(0.35, BLANC), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 110, 100))})})})
		for _, y in {0.3, 0.62} do
			local f = bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.new(0.062, 0, 0, 22), BackgroundColor3 = FER, ZIndex = 8},
				{trait(Color3.fromRGB(30, 30, 34), 2), UI.degrade(BLANC, Color3.fromRGB(110, 110, 120), 90)})
			UI.rivet(f, UDim2.fromScale(0.2, 0.5), 0.5)
			UI.rivet(f, UDim2.fromScale(0.8, 0.5), 0.5)
		end
	end
	bloc({Position = UDim2.fromScale(0, 0.02), Size = UDim2.new(1, 0, 0.075, 0), BackgroundColor3 = BOIS, ZIndex = 9},
		{trait(BOIS_SOMBRE, 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(BLANC, Color3.fromRGB(120, 105, 95))})})
	for _, s in {-1, 1} do
		local x = if s < 0 then 0.1 else 0.9
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.15), Size = UDim2.new(0.03, 0, 0.26, 0), Rotation = s * 45,
			BackgroundColor3 = BOIS, ZIndex = 8}, {trait(BOIS_SOMBRE, 2.5), UI.degrade(BLANC, Color3.fromRGB(130, 115, 100), 0)})
	end
	-- Lanternes suspendues à la poutre (lueur qui vacille)
	for i, x in {0.12, 0.31, 0.69, 0.88} do
		local h = if i % 2 == 0 then 0.1 else 0.06
		bloc({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0.09), Size = UDim2.new(0, 3, h, 0), BackgroundColor3 = Color3.fromRGB(40, 40, 46), ZIndex = 9})
		local lueur = bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.11 + h), Size = UDim2.fromScale(0.26, 0.26),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(255, 180, 80), BackgroundTransparency = 0.72, ZIndex = 3}, {coin(0.5)})
		UI.boucle(lueur, TweenInfo.new(0.9 + i * 0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{BackgroundTransparency = 0.8, Size = UDim2.fromScale(0.23, 0.23)}, boucles)
		local cage = bloc({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0.09 + h), Size = UDim2.fromScale(0.03, 0.045),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(255, 200, 90), ZIndex = 10},
			{arrondi(4), trait(Color3.fromRGB(30, 26, 24), 3), UI.degrade(Color3.fromRGB(255, 240, 190), Color3.fromRGB(255, 140, 40), 90)})
		bloc({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1.3, 0.22), BackgroundColor3 = Color3.fromRGB(40, 40, 46),
			ZIndex = 11, Parent = cage}, {arrondi(3)})
	end
	-- Wagonnet chargé sur les rails (bas gauche)
	local wagon = bloc({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.17, 0.93), Size = UDim2.fromScale(0.2, 0.12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(96, 70, 52), ZIndex = 12},
		{arrondi(6), trait(Color3.fromRGB(26, 20, 18), 3), UI.degrade(BLANC, Color3.fromRGB(110, 100, 95), 90)})
	for _, y in {0.25, 0.7} do
		bloc({Position = UDim2.fromScale(-0.03, y), Size = UDim2.new(1.06, 0, 0, 5), BackgroundColor3 = FER, ZIndex = 13, Parent = wagon})
	end
	for _, x in {0.22, 0.78} do
		bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1), Size = UDim2.fromScale(0.26, 0.4), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundColor3 = Color3.fromRGB(46, 46, 52), ZIndex = 13, Parent = wagon}, {coin(0.5), trait(Color3.fromRGB(20, 20, 22), 2)})
	end
	for k = 1, 7 do
		local c = if k % 3 == 0 then Color3.fromRGB(255, 205, 70) else Color3.fromRGB(34, 34, 38)
		bloc({AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.08 + k * 0.12, 0.08), Size = UDim2.fromScale(0.2, 0.2),
			SizeConstraint = Enum.SizeConstraint.RelativeXX, Rotation = k * 23, BackgroundColor3 = c, ZIndex = 11, Parent = wagon},
			{coin(0.3), trait(Color3.new(0, 0, 0), 1.5, 0.3)})
	end
	-- Pioche appuyée contre le poteau droit
	local manche = bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.91, 0.8), Size = UDim2.fromScale(0.014, 0.3), Rotation = -14,
		BackgroundColor3 = BOIS, ZIndex = 12}, {arrondi(3), trait(BOIS_SOMBRE, 2)})
	bloc({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.new(9, 0, 0.05, 0), Rotation = 8,
		BackgroundColor3 = FER, ZIndex = 13, Parent = manche}, {coin(0.5), trait(Color3.fromRGB(26, 26, 30), 2), UI.degrade(BLANC, Color3.fromRGB(100, 100, 110), 90)})
	-- Cristaux dans les coins
	cristaux(decorMine, UDim2.fromScale(0.8, 0.98), 1.3, Color3.fromRGB(190, 120, 255), 14, 5)
	cristaux(decorMine, UDim2.fromScale(0.27, 0.99), 0.9, CRISTAL, 14, 11)
	-- Vignettage : bords plus sombres pour faire ressortir la fenêtre
	bloc({Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 20},
		{creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.22, 0.95),
			NumberSequenceKeypoint.new(0.78, 0.95), NumberSequenceKeypoint.new(1, 0.55)})})})
end

local racine = creer("Frame", {Name = "Fenetre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(LARGEUR, HAUTEUR), BackgroundTransparency = 1, Active = true, Parent = gui})
local echelleEcran = creer("UIScale", {Name = "Ecran", Parent = racine})
local corps = creer("Frame", {Name = "Corps", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = racine})
local echelleAnim = creer("UIScale", {Name = "Anim", Parent = corps})

-- Ombre portée + cadre en planches de bois
creer("Frame", {Name = "Ombre", Position = UDim2.fromOffset(8, 12), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.5, ZIndex = 0, Parent = corps}, {arrondi(18)})
local grain = {}
for i = 0, 10 do
	local v = if i % 2 == 0 then 255 - (i * 7) % 30 else 196 + (i * 13) % 26
	table.insert(grain, ColorSequenceKeypoint.new(i / 10, Color3.fromRGB(v, v * 0.97, v * 0.94)))
end
creer("Frame", {Name = "Cadre", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bois, ZIndex = 1, Parent = corps},
	{arrondi(16), trait(Color3.fromRGB(18, 10, 6), 4), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(grain)})})
for _, c in {Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1)} do
	local eq = creer("Frame", {AnchorPoint = c, Position = UDim2.fromScale(c.X, c.Y), Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = T.Fer, ZIndex = 8, Parent = corps},
		{arrondi(8), trait(T.FerSombre, 2), creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(220, 220, 228), Color3.fromRGB(80, 80, 88))})})
	UI.rivet(eq, UDim2.fromScale(0.5 + (0.5 - c.X) * 0.4, 0.5 + (0.5 - c.Y) * 0.4), 0.28)
end
for i = 1, 11 do
	UI.rivet(corps, UDim2.new((i + 0.5) / 13, 0, 0, 6), 0.012)
	UI.rivet(corps, UDim2.new((i + 0.5) / 13, 0, 1, -6), 0.012)
end

-- Intérieur : pierre froide en haut, de plus en plus sombre vers le fond
local interieur = creer("Frame", {Name = "Interieur", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(LARGEUR - 24, HAUTEUR - 24),
	BackgroundColor3 = T.Pierre, ClipsDescendants = true, ZIndex = 2, Parent = corps},
	{arrondi(10), trait(T.FerSombre, 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(215, 220, 230)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(170, 160, 175)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 80, 105))})})})
do
	local rng = Random.new(17)
	for _ = 1, 26 do
		local s = rng:NextNumber(30, 80)
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0, 1), rng:NextNumber(0, 1)),
			Size = UDim2.fromOffset(s * rng:NextNumber(1, 1.6), s), Rotation = rng:NextNumber(-20, 20),
			BackgroundColor3 = if rng:NextNumber() < 0.5 then Color3.new(0, 0, 0) else Color3.fromRGB(120, 100, 86),
			BackgroundTransparency = rng:NextNumber(0.86, 0.94), BorderSizePixel = 0, ZIndex = 1, Parent = interieur}, {coin(rng:NextNumber(0.2, 0.45))})
	end
end
-- Lueur chaude de lanterne en haut, lueur de cristal au fond
local lanterne = creer("Frame", {Size = UDim2.new(1, 0, 0, 140), BackgroundColor3 = T.Braise, BorderSizePixel = 0, ZIndex = 1, Parent = interieur})
local gLanterne = creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.72),
	NumberSequenceKeypoint.new(1, 1)}), Parent = lanterne})
UI.boucle(gLanterne, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, -0.15)}, boucles)
local fond = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 200),
	BackgroundColor3 = Color3.fromRGB(150, 90, 255), BorderSizePixel = 0, ZIndex = 1, Parent = interieur})
local gFond = creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.7)}), Parent = fond})
UI.boucle(gFond, TweenInfo.new(3.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.2)}, boucles)
cristaux(interieur, UDim2.new(0, 470, 1, 10), 0.9, Color3.fromRGB(190, 120, 255), 2, 3)
cristaux(interieur, UDim2.new(0, 14, 1, 8), 0.7, CRISTAL, 2, 9)

-- En-tête : emblème de cristal + titre
cristaux(interieur, UDim2.fromOffset(46, 64), 0.85, CRISTAL, 5, 21)
local titre = texte({Text = "GROTTES PROFONDES", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(86, 12), Size = UDim2.fromOffset(470, 50), ZIndex = 5, Parent = interieur}, 44)
UI.dore(titre, 2.5)
UI.bandeFer(interieur, UDim2.fromOffset(0, 74), UDim2.new(1, 0, 0, 10), 18)

local fermer = boutonFermer({Name = "Fermer", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.fromOffset(64, 64), ZIndex = 12, Parent = corps})

-- ================= Paliers (colonne de gauche) =================
local Y0, H_LIGNE, ECART, X_CARTE, L_CARTE = 98, 64, 8, 64, 444

-- Puits : corde verticale + nœuds lumineux
creer("Frame", {Name = "Puits", Position = UDim2.fromOffset(31, Y0 + 8), Size = UDim2.fromOffset(6, 5 * (H_LIGNE + ECART) - ECART - 16),
	BackgroundColor3 = Color3.fromRGB(120, 86, 52), BorderSizePixel = 0, ZIndex = 3, Parent = interieur},
	{coin(0.5), trait(ENCRE, 1.5), creer("UIGradient", {Rotation = 0, Color = ColorSequence.new(Color3.fromRGB(255, 230, 190), Color3.fromRGB(110, 80, 60))})})

type Ligne = {
	niveau: any,
	conteneur: Frame,
	echelle: UIScale,
	carte: TextButton,
	ombre: Frame,
	halo: UIStroke,
	lueur: Frame,
	plein: Frame,
	info: TextLabel,
	noeud: Frame,
	assombri: Frame,
	survol: boolean,
}
local lignes: {Ligne} = {}

local function creerLigne(niveau: any, i: number): Ligne
	local y = Y0 + (i - 1) * (H_LIGNE + ECART)
	local accent: Color3 = niveau.ambiance.lumiere
	local conteneur = creer("Frame", {Name = "Niveau" .. i, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(X_CARTE + L_CARTE / 2, y + H_LIGNE / 2), Size = UDim2.fromOffset(L_CARTE, H_LIGNE),
		BackgroundTransparency = 1, ZIndex = 4, Parent = interieur})
	local echelle = creer("UIScale", {Parent = conteneur})
	local lueur = creer("Frame", {Name = "Lueur", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 34, 1, 30), BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = conteneur},
		{coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.3),
			NumberSequenceKeypoint.new(0.75, 0.3), NumberSequenceKeypoint.new(1, 1)})})})
	local ombre = creer("Frame", {Name = "Ombre", Position = UDim2.fromOffset(3, 5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 2, Parent = conteneur}, {arrondi(12)})
	local haloCadre = creer("Frame", {Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 8, 1, 8), BackgroundTransparency = 1, ZIndex = 3, Parent = conteneur}, {arrondi(15)})
	local halo = trait(accent, 3, 1)
	halo.Parent = haloCadre

	local teinte = T.Carte:Lerp(Color3.fromRGB(22, 16, 26), (i - 1) * 0.14)
	local carte = creer("TextButton", {Name = "Carte", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = teinte, ZIndex = 4, Parent = conteneur}, {arrondi(12), trait(T.FerSombre, 2, 0.05),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 248, 240), Color3.fromRGB(150, 136, 128))})})
	-- Liseré de couleur du palier + reflet
	creer("Frame", {Size = UDim2.new(0, 7, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = accent, BorderSizePixel = 0,
		ZIndex = 5, Parent = carte}, {coin(0.5), UI.degrade(BLANC, Color3.fromRGB(130, 130, 140))})
	creer("Frame", {Position = UDim2.fromOffset(16, 3), Size = UDim2.new(1, -24, 0, 18), BackgroundColor3 = BLANC, BackgroundTransparency = 0.93,
		BorderSizePixel = 0, ZIndex = 5, Parent = carte}, {coin(0.5)})

	local etiquetteNiveau = texte({Text = "NIVEAU " .. niveau.id, Font = Enum.Font.GothamBlack, TextColor3 = accent:Lerp(BLANC, 0.3),
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(24, 5), Size = UDim2.fromOffset(124, 32), ZIndex = 6, Parent = carte}, 26)
	creer("UIStroke", {Thickness = 2, Color = ENCRE, Transparency = 0.1, Parent = etiquetteNiveau})
	local profondeur = texte({Text = string.format("−%d m", niveau.profondeur), Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(25, 37), Size = UDim2.fromOffset(118, 20), ZIndex = 6, Parent = carte}, 17)
	creer("UIStroke", {Thickness = 1.5, Color = ENCRE, Transparency = 0.1, Parent = profondeur})

	-- Barre de danger (remplissage + couleur selon l'équipement) avec crans
	local barreFond = creer("Frame", {Name = "Barre", Position = UDim2.fromOffset(150, 17), Size = UDim2.fromOffset(200, 15),
		BackgroundColor3 = Color3.fromRGB(20, 14, 12), ZIndex = 6, Parent = carte}, {coin(0.5), trait(ENCRE, 1.5)})
	local plein = creer("Frame", {Name = "Plein", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Grottes.couleurDanger(0), BorderSizePixel = 0,
		ZIndex = 7, Parent = barreFond}, {coin(0.5), UI.degrade(BLANC, Color3.fromRGB(165, 165, 165))})
	creer("Frame", {Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.34), BackgroundColor3 = BLANC, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 8, Parent = plein}, {coin(0.5)})
	for k = 1, 4 do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(k / 5, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 9, Parent = barreFond})
	end
	-- Crans de difficulté de base (1 à 5)
	for k = 1, 5 do
		local allume = k <= niveau.difficulte
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(372 + (k - 1) * 15, 24), Size = UDim2.fromOffset(9, 9),
			Rotation = 45, BackgroundColor3 = if allume then T.Or else T.Inactif, BackgroundTransparency = if allume then 0 else 0.35,
			ZIndex = 6, Parent = carte}, {arrondi(2), trait(ENCRE, 1.2), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150), 45)})
	end
	-- Ligne d'info (nom du palier + danger), visible au survol seulement
	local info = texte({Font = Enum.Font.GothamBold, RichText = true, TextColor3 = T.Parchemin, TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(150, 38), Size = UDim2.fromOffset(284, 18), ZIndex = 6, Parent = carte}, 15)
	-- Voile (paliers non choisis pendant le départ)
	local assombri = creer("Frame", {Name = "Assombri", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		ZIndex = 12, Parent = carte}, {arrondi(12)})

	-- Nœud lumineux sur le puits
	local noeud = creer("Frame", {Name = "Noeud" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(34, y + H_LIGNE / 2),
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = accent, ZIndex = 4, Parent = interieur}, {coin(0.5), trait(ENCRE, 2),
		UI.degrade(BLANC, Color3.fromRGB(140, 140, 150), 45)})
	local aura = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.6, 1.6),
		BackgroundTransparency = 1, ZIndex = 3, Parent = noeud}, {coin(0.5), trait(accent, 2, 0.3)})
	UI.boucle(aura, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, i * 0.15),
		{Size = UDim2.fromScale(2.3, 2.3)}, boucles)

	return {niveau = niveau, conteneur = conteneur, echelle = echelle, carte = carte, ombre = ombre, halo = halo, lueur = lueur,
		plein = plein, info = info, noeud = noeud, assombri = assombri, survol = false}
end

for i, niveau in Grottes.NIVEAUX do
	table.insert(lignes, creerLigne(niveau, i))
end

local function survoler(l: Ligne, actif: boolean)
	if l.survol == actif then
		return
	end
	l.survol = actif
	l.conteneur.ZIndex = if actif then 7 else 4
	TweenService:Create(l.echelle, SURVOL, {Scale = if actif then 1.1 else 1}):Play()
	TweenService:Create(l.ombre, SURVOL, {BackgroundTransparency = if actif then 0.4 else 0.72,
		Position = if actif then UDim2.fromOffset(6, 11) else UDim2.fromOffset(3, 5)}):Play()
	TweenService:Create(l.halo, SURVOL, {Transparency = if actif then 0.05 else 1}):Play()
	TweenService:Create(l.lueur, SURVOL, {BackgroundTransparency = if actif then 0.78 else 1}):Play()
	TweenService:Create(l.info, SURVOL, {TextTransparency = if actif then 0 else 1}):Play()
	TweenService:Create(l.noeud, SURVOL, {Size = if actif then UDim2.fromOffset(24, 24) else UDim2.fromOffset(16, 16)}):Play()
	if actif then
		jouer("survol", 1.55 - l.niveau.id * 0.1) -- plus c'est profond, plus c'est grave
	end
end

local LIBELLES_NIVEAU = {"Facile", "Modéré", "Difficile", "Extrême", "Impossible"}

-- Barres de difficulté : niveau N = N/5 de la jauge, du vert (1) au rouge (5) ; la ligne d'info du survol
-- garde le danger selon l'équipement (recalculée quand l'équipement change)
local function majBarres(depuisZero: boolean)
	local s = stats()
	local total = #Grottes.NIVEAUX
	for i, l in lignes do
		local d = Grottes.danger(l.niveau, s)
		if depuisZero then
			l.plein.Size = UDim2.fromScale(0, 1)
		end
		local part = l.niveau.difficulte / 5
		TweenService:Create(l.plein, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false,
			if depuisZero then 0.2 + i * 0.07 else 0), {Size = UDim2.fromScale(part, 1),
			BackgroundColor3 = Grottes.couleurDanger((l.niveau.difficulte - 1) / math.max(total - 1, 1))}):Play()
		-- libellé fixe par niveau (Facile → Impossible), même couleur que la jauge
		local libelle = LIBELLES_NIVEAU[l.niveau.difficulte] or Grottes.libelleDanger(d)
		local couleurLibelle = Grottes.couleurDanger((l.niveau.difficulte - 1) / math.max(total - 1, 1))
		l.info.Text = string.format('%s  ·  <font color="#%s">%s</font>', echapper(l.niveau.nom), couleurLibelle:ToHex(), libelle)
	end
end

local function majVerrous()
	for _, l in lignes do
		local sombre = attente and choisiId ~= l.niveau.id
		TweenService:Create(l.assombri, FAST, {BackgroundTransparency = if sombre then 0.45 else 1}):Play()
	end
end

-- ================= Bloc « Groupe » (colonne de droite) =================
local groupe = UI.panneau({Name = "Groupe", Position = UDim2.fromOffset(528, Y0), Size = UDim2.fromOffset(192, 5 * (H_LIGNE + ECART) - ECART),
	BackgroundColor3 = T.BoisSombre, ZIndex = 5, Parent = interieur}, 0.06)
texte({Text = "GROUPE", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(100, 22), ZIndex = 6, Parent = groupe}, 18)
local compteur = texte({Text = "1/" .. Grottes.MAX_JOUEURS, Font = Enum.Font.GothamBlack, TextColor3 = T.Or,
	TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(100, 6), Size = UDim2.fromOffset(78, 32), ZIndex = 6, Parent = groupe}, 28)
creer("Frame", {Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 0, 2), BackgroundColor3 = T.OrFonce, BackgroundTransparency = 0.4,
	BorderSizePixel = 0, ZIndex = 6, Parent = groupe})

type Place = {bouton: TextButton, cercle: Frame, image: ImageLabel, bord: UIStroke, plus: TextLabel, nom: TextLabel, sous: TextLabel, userId: number?}
local places: {Place} = {}
local basculerListe: () -> () = function() end
for k = 1, Grottes.MAX_JOUEURS do
	local b = creer("TextButton", {Name = "Place" .. k, Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(8, 54 + (k - 1) * 84),
		Size = UDim2.fromOffset(176, 76), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.75, ZIndex = 6, Parent = groupe},
		{arrondi(12)})
	local cercle, image, bord = medaillon(b, {Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(60, 60)}, T.Gris, 7)
	local plus = texte({Text = "+", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, Size = UDim2.fromScale(1, 1), ZIndex = 9, Parent = cercle}, 34)
	local nom = texte({Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(76, 14),
		Size = UDim2.fromOffset(94, 24), ZIndex = 7, Parent = b}, 18)
	local sous = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(76, 40), Size = UDim2.fromOffset(94, 16), ZIndex = 7, Parent = b}, 13)
	b.Activated:Connect(function()
		if estChef and #membres < Grottes.MAX_JOUEURS and k > #membres then
			jouer("clic")
			basculerListe()
		end
	end)
	table.insert(places, {bouton = b, cercle = cercle, image = image, bord = bord, plus = plus, nom = nom, sous = sous, userId = nil})
end

local inviter = UI.boutonPrincipal({Name = "Inviter", Position = UDim2.fromOffset(14, 262), Size = UDim2.fromOffset(164, 64),
	BackgroundColor3 = BOUTON_BLEU, ZIndex = 6, Parent = groupe}, boucles)
inviter.definir("INVITER", BOUTON_BLEU, true)

local attenteChef = texte({Text = "Le chef choisit la profondeur", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
	Position = UDim2.fromOffset(14, 256), Size = UDim2.fromOffset(164, 56), Visible = false, ZIndex = 6, Parent = groupe}, 17)
UI.boucle(attenteChef, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.5}, boucles)

local function premierInvite(): number?
	for userId in invitesServeur do
		return userId
	end
	for userId in invitesLocales do
		if estInvite(userId) then
			return userId
		end
	end
	return nil
end

local function majGroupe()
	compteur.Text = #membres .. "/" .. Grottes.MAX_JOUEURS
	local enAttente = premierInvite()
	for k, p in places do
		local m = membres[k]
		if m then
			p.image.Visible, p.plus.Visible = true, false
			p.image.ImageTransparency = 0
			avatar(m.userId, p.image)
			p.nom.Text, p.nom.TextColor3 = m.nom, T.Parchemin
			p.sous.Text, p.sous.TextColor3 = if m.userId == chefId then "CHEF" else "", T.Or
			p.bord.Color, p.bord.Transparency = if m.userId == chefId then T.Or else CRISTAL, 0
			if p.userId ~= m.userId then
				p.userId = m.userId
				UI.pop(p.cercle, 0.6)
			end
		elseif enAttente and k == #membres + 1 then
			local cible = Players:GetPlayerByUserId(enAttente)
			p.image.Visible, p.plus.Visible = true, false
			p.image.ImageTransparency = 0.55
			avatar(enAttente, p.image)
			p.nom.Text, p.nom.TextColor3 = if cible then cible.DisplayName else "…", T.Gris
			p.sous.Text, p.sous.TextColor3 = "Invité…", T.Gris
			p.bord.Color, p.bord.Transparency = T.Gris, 0.3
			p.userId = nil
		else
			p.image.Visible, p.plus.Visible = false, true
			p.plus.TextColor3 = if estChef then T.Parchemin else T.Gris
			p.nom.Text, p.sous.Text = "", ""
			p.bord.Color, p.bord.Transparency = T.Gris, 0.5
			p.userId = nil
		end
	end
end

-- ================= Liste d'invitation =================
local liste = UI.panneau({Name = "ListeInvitation", Position = UDim2.fromOffset(288, 90), Size = UDim2.fromOffset(436, 366),
	BackgroundColor3 = T.BoisSombre, Visible = false, ZIndex = 20, Parent = interieur}, 0.04)
local echelleListe = creer("UIScale", {Parent = liste})
local titreListe = texte({Text = "INVITER", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(300, 40), ZIndex = 21, Parent = liste}, 34)
UI.dore(titreListe, 2)
local fermerListe = boutonFermer({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(58, 58),
	ZIndex = 22, Parent = liste})
local defilement = creer("ScrollingFrame", {Position = UDim2.fromOffset(10, 70), Size = UDim2.new(1, -20, 1, -80), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 21, Parent = liste},
	{creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		creer("UIPadding", {PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2)})})
local vide = texte({Text = "Personne d'autre ici", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromOffset(20, 150),
	Size = UDim2.new(1, -40, 0, 30), Visible = false, ZIndex = 22, Parent = liste}, 20)

type Rangee = {bouton: TextButton, sous: TextLabel, bord: UIStroke, pastille: Frame, etiquette: TextLabel}
local rangees: {[number]: Rangee} = {}

local function majRangee(userId: number, r: Rangee, joueurCible: Player)
	local ami = estAmi(userId)
	local invite = estInvite(userId)
	r.sous.Text = if ami then "AMI" else "@" .. joueurCible.Name
	r.sous.TextColor3 = if ami then T.Or else T.Gris
	r.sous.Font = if ami then Enum.Font.GothamBlack else Enum.Font.Gotham
	r.bord.Color = if ami then T.OrFonce else T.FerSombre
	r.etiquette.Text = if invite then "Invité…" else "Inviter"
	r.pastille.BackgroundColor3 = if invite then T.Inactif else BOUTON_BLEU
	r.bouton.Active = not invite
end

local function creerRangee(p: Player): Rangee
	local userId = p.UserId
	local b = creer("TextButton", {Name = tostring(userId), Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 66),
		BackgroundColor3 = T.Carte, ZIndex = 22, Parent = defilement}, {arrondi(12),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 245, 235), Color3.fromRGB(165, 148, 135))})})
	local bord = trait(T.FerSombre, 2)
	bord.Parent = b
	local _, image = medaillon(b, {Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(50, 50)}, CRISTAL, 23)
	avatar(userId, image)
	texte({Text = p.DisplayName, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(68, 9),
		Size = UDim2.new(1, -192, 0, 26), ZIndex = 23, Parent = b}, 20)
	local sous = texte({Font = Enum.Font.Gotham, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(68, 37),
		Size = UDim2.new(1, -192, 0, 18), ZIndex = 23, Parent = b}, 14)
	local pastille = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(106, 44),
		BackgroundColor3 = BOUTON_BLEU, ZIndex = 23, Parent = b}, {coin(0.5), trait(ENCRE, 2), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150))})
	local etiquette = texte({Font = Enum.Font.GothamBlack, TextColor3 = BLANC, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.5), ZIndex = 24, Parent = pastille}, 18)
	UI.reactif(b, 1.03)
	local r: Rangee = {bouton = b, sous = sous, bord = bord, pastille = pastille, etiquette = etiquette}
	b.Activated:Connect(function()
		if not estChef or #membres >= Grottes.MAX_JOUEURS then
			return
		end
		if estInvite(userId) then
			UI.secouer(pastille, 4)
			return
		end
		invitesLocales[userId] = os.clock()
		evInviter:FireServer(userId)
		jouer("metal")
		UI.pop(pastille, 0.7)
		majRangee(userId, r, p)
		majGroupe()
		-- l'invitation expire : on rafraîchit l'affichage
		task.delay(DUREE_INVITATION + 0.2, function()
			if invitesLocales[userId] then
				invitesLocales[userId] = nil
			end
			rafraichirListe()
			if ouverte then
				majGroupe()
			end
		end)
	end)
	return r
end

rafraichirListe = function()
	if not liste.Visible then
		return
	end
	local candidats: {Player} = {}
	local presents: {[number]: boolean} = {}
	for _, p in Players:GetPlayers() do
		if p ~= joueur and not estMembre(p.UserId) then
			table.insert(candidats, p)
			presents[p.UserId] = true
		end
	end
	for userId, r in rangees do
		if not presents[userId] then
			r.bouton:Destroy()
			rangees[userId] = nil
		end
	end
	local amis: {[Player]: boolean} = {}
	for _, p in candidats do
		amis[p] = estAmi(p.UserId) -- figé avant le tri (ordre cohérent)
	end
	table.sort(candidats, function(a, b)
		local amiA, amiB = amis[a], amis[b]
		if amiA ~= amiB then
			return amiA
		end
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	for ordre, p in candidats do
		local r = rangees[p.UserId]
		if not r then
			r = creerRangee(p)
			rangees[p.UserId] = r
		end
		r.bouton.LayoutOrder = ordre
		majRangee(p.UserId, r, p)
	end
	vide.Visible = #candidats == 0
end

local function cacherListe()
	if not liste.Visible then
		return
	end
	TweenService:Create(echelleListe, FAST, {Scale = 0.9}):Play()
	task.delay(0.12, function()
		if echelleListe.Scale < 0.95 then
			liste.Visible = false
		end
	end)
end

basculerListe = function()
	if liste.Visible and echelleListe.Scale >= 0.95 then
		cacherListe()
		return
	end
	if not estChef or #membres >= Grottes.MAX_JOUEURS then
		return
	end
	liste.Visible = true
	echelleListe.Scale = 0.85
	TweenService:Create(echelleListe, BOUNCY, {Scale = 1}):Play()
	jouer("ouvrir", 1.4)
	rafraichirListe()
end

inviter.bouton.Activated:Connect(function()
	if inviter.bouton.Active then
		jouer("clic")
		basculerListe()
	end
end)
fermerListe.Activated:Connect(function()
	jouer("clic", 0.9)
	cacherListe()
end)
Players.PlayerAdded:Connect(function()
	rafraichirListe()
end)
Players.PlayerRemoving:Connect(function(p)
	cacheAmis[p.UserId], demandesAmis[p.UserId] = nil, nil
	task.defer(rafraichirListe)
end)

local function majRoles()
	local plein = #membres >= Grottes.MAX_JOUEURS
	inviter.bouton.Visible = estChef and not plein
	attenteChef.Visible = not estChef
	if not estChef or plein then
		cacherListe()
	end
end

-- ================= Choix d'un palier =================
local function choisir(l: Ligne)
	if not ouverte or attente then
		return
	end
	if not estChef then
		if TACTILE then
			for _, autre in lignes do
				survoler(autre, autre == l)
			end
		end
		UI.secouer(l.conteneur, 5)
		UI.pop(attenteChef, 0.8)
		return
	end
	if TACTILE and selectionTactile ~= l.niveau.id then
		-- 1er toucher : aperçu (agrandi + infos), 2e toucher : départ
		selectionTactile = l.niveau.id
		for _, autre in lignes do
			survoler(autre, autre == l)
		end
		return
	end
	attente, choisiId = true, l.niveau.id
	cacherListe()
	jouer("metal")
	jouer("succes", 0.8)
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 0.25, ZIndex = 13,
		Parent = l.carte}, {arrondi(12)})
	TweenService:Create(flash, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flash, 0.6)
	UI.gerbe(l.carte, l.niveau.ambiance.lumiere, 16, Vector2.new(0.16, 0.5))
	l.echelle.Scale = 1.02
	TweenService:Create(l.echelle, BOUNCY, {Scale = 1.1}):Play()
	majVerrous()
	evChoisir:FireServer(l.niveau.id)
	-- le serveur peut refuser (cercle quitté…) : on redonne la main après un moment
	local moi = choisiId
	task.delay(4, function()
		if attente and choisiId == moi and ouverte then
			attente, choisiId = false, nil
			majVerrous()
		end
	end)
end

for _, l in lignes do
	if not TACTILE then
		l.carte.MouseEnter:Connect(function()
			survoler(l, true)
		end)
		l.carte.MouseLeave:Connect(function()
			survoler(l, false)
		end)
	end
	l.carte.MouseButton1Down:Connect(function()
		if estChef and not attente then
			TweenService:Create(l.echelle, TweenInfo.new(0.08), {Scale = if l.survol then 1.04 else 0.96}):Play()
		end
	end)
	l.carte.MouseButton1Up:Connect(function()
		TweenService:Create(l.echelle, BOUNCY, {Scale = if l.survol then 1.1 else 1}):Play()
	end)
	l.carte.Activated:Connect(function()
		choisir(l)
	end)
end

-- ================= Ouverture / fermeture =================
local function particule()
	local cristal = math.random() < 0.35
	local t = math.random(3, 6)
	local x = math.random()
	local p = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 6), Size = UDim2.fromOffset(t, t), BorderSizePixel = 0,
		ZIndex = 3, BackgroundColor3 = if cristal then CRISTAL:Lerp(BLANC, math.random() * 0.3)
			else Color3.fromRGB(255, 140 + math.random(0, 100), 40 + math.random(0, 60)), BackgroundTransparency = 0.1, Parent = interieur}, {coin(0.5)})
	local duree = 2.5 + math.random() * 2.5
	TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.1, 0.3 + math.random() * 0.5),
		BackgroundTransparency = 1, Size = UDim2.fromOffset(t * 0.4, t * 0.4)}):Play()
	Debris:AddItem(p, duree)
end

local tweenVoile: Tween? = nil
local function ouvrirFenetre()
	if ouverte then
		return
	end
	ouverte = true
	gui.Enabled = true
	for _, t in boucles do
		t:Play()
	end
	if tweenVoile then
		tweenVoile:Cancel()
	end
	echelleAnim.Scale = 0.8
	corps.Position = UDim2.fromOffset(0, 50)
	TweenService:Create(echelleAnim, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(corps, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
	local tv = TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.3})
	tweenVoile = tv
	tv:Play()
	TweenService:Create(decorMine, UI.DOUX, {GroupTransparency = 0}):Play()
	jouer("ouvrir", 0.85)
	-- les paliers descendent en cascade
	for i, l in lignes do
		l.survol = false
		l.conteneur.ZIndex = 4
		l.halo.Transparency, l.lueur.BackgroundTransparency, l.info.TextTransparency = 1, 1, 1
		l.ombre.BackgroundTransparency, l.ombre.Position = 0.72, UDim2.fromOffset(3, 5)
		l.noeud.Size = UDim2.fromOffset(16, 16)
		l.echelle.Scale = 0.5
		TweenService:Create(l.echelle, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.12 + i * 0.06), {Scale = 1}):Play()
	end
	majBarres(true)
	task.spawn(function()
		while ouverte do
			particule()
			task.wait(0.08 + math.random() * 0.12)
		end
	end)
end

local function fermerFenetre(prevenirServeur: boolean)
	if not ouverte then
		return
	end
	ouverte = false
	attente, choisiId, selectionTactile = false, nil, nil
	if prevenirServeur then
		evQuitter:FireServer()
	end
	for _, t in boucles do
		t:Pause()
	end
	if tweenVoile then
		tweenVoile:Cancel()
	end
	liste.Visible = false
	jouer("ouvrir", 1.3)
	TweenService:Create(echelleAnim, FAST, {Scale = 0.88}):Play()
	TweenService:Create(corps, FAST, {Position = UDim2.fromOffset(0, 30)}):Play()
	local tv = TweenService:Create(voile, FAST, {BackgroundTransparency = 1})
	tweenVoile = tv
	tv:Play()
	TweenService:Create(decorMine, FAST, {GroupTransparency = 1}):Play()
	task.delay(0.16, function()
		if not ouverte then
			gui.Enabled = false
			majVerrous()
		end
	end)
end

fermer.Activated:Connect(function()
	jouer("clic", 0.9)
	fermerFenetre(true)
end)

-- ================= Invitations + notifications =================
local notifs = creer("ScreenGui", {Name = "GrottesNotifs", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})
local zoneCartes = creer("Frame", {Name = "Invitations", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(390, 400), BackgroundTransparency = 1, Parent = notifs})
local echelleCartes = creer("UIScale", {Parent = zoneCartes})
local zoneMessage = creer("Frame", {Name = "Message", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96),
	Size = UDim2.fromOffset(470, 54), BackgroundTransparency = 1, Parent = notifs})
local echelleMessage = creer("UIScale", {Parent = zoneMessage})

local plaque = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.BoisSombre, Visible = false, ZIndex = 2, Parent = zoneMessage},
	{arrondi(16), trait(CRISTAL, 2.5), UI.degrade(Color3.fromRGB(255, 240, 225), Color3.fromRGB(150, 130, 120))})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(28, 27), Size = UDim2.fromOffset(16, 16), Rotation = 45,
	BackgroundColor3 = CRISTAL, ZIndex = 3, Parent = plaque}, {arrondi(3), trait(ENCRE, 1.5), UI.degrade(BLANC, Color3.fromRGB(120, 140, 170), 45)})
local texteMessage = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(48, 12), Size = UDim2.new(1, -62, 0, 30), ZIndex = 3,
	Parent = plaque}, 22)
local idMessage = 0
local function notifier(txt: string)
	idMessage += 1
	local moi = idMessage
	texteMessage.Text = txt
	plaque.Visible = true
	plaque.Position = UDim2.fromOffset(0, 50)
	TweenService:Create(plaque, BOUNCY, {Position = UDim2.fromOffset(0, 0)}):Play()
	UI.pop(plaque, 0.75)
	jouer("succes", 1.2)
	task.delay(2.8, function()
		if moi == idMessage then
			TweenService:Create(plaque, FAST, {Position = UDim2.fromOffset(0, 120)}):Play()
			task.delay(0.16, function()
				if moi == idMessage then
					plaque.Visible = false
				end
			end)
		end
	end)
end

type CarteInvitation = {cadre: Frame, id: number}
local cartes: {[number]: CarteInvitation} = {}
local ordreCartes: {number} = {}
local idCarte = 0

local function placerCartes()
	for k, chef in ordreCartes do
		local c = cartes[chef]
		if c then
			TweenService:Create(c.cadre, SURVOL, {Position = UDim2.fromOffset(0, (k - 1) * 134)}):Play()
		end
	end
end

local function retirerCarte(chef: number, reponse: boolean?)
	local c = cartes[chef]
	if not c then
		return
	end
	cartes[chef] = nil
	local idx = table.find(ordreCartes, chef)
	if idx then
		table.remove(ordreCartes, idx)
	end
	if reponse ~= nil then
		evRepondre:FireServer(chef, reponse)
	end
	local e = c.cadre:FindFirstChildOfClass("UIScale")
	if e then
		TweenService:Create(e, FAST, {Scale = 0.8}):Play()
	end
	TweenService:Create(c.cadre, FAST, {Position = c.cadre.Position - UDim2.fromOffset(0, 30)}):Play()
	Debris:AddItem(c.cadre, 0.18)
	placerCartes()
end

local function afficherInvitation(chef: number, nomChef: string)
	if cartes[chef] then
		local ancien = cartes[chef]
		cartes[chef] = nil
		ancien.cadre:Destroy()
		local idx = table.find(ordreCartes, chef)
		if idx then
			table.remove(ordreCartes, idx)
		end
	end
	idCarte += 1
	local moi = idCarte
	local cadre = creer("Frame", {Name = "Invitation", Position = UDim2.fromOffset(0, #ordreCartes * 134 - 40), Size = UDim2.fromOffset(390, 124),
		BackgroundColor3 = T.BoisSombre, ZIndex = 2, Parent = zoneCartes}, {arrondi(14), trait(T.Or, 2.5),
		UI.degrade(Color3.fromRGB(255, 240, 225), Color3.fromRGB(140, 120, 110))})
	creer("Frame", {Position = UDim2.fromOffset(6, 10), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55, ZIndex = 1, Parent = cadre}, {arrondi(14)})
	for _, c in {Vector2.new(0.025, 0.07), Vector2.new(0.975, 0.07), Vector2.new(0.025, 0.93), Vector2.new(0.975, 0.93)} do
		UI.rivet(cadre, UDim2.fromScale(c.X, c.Y), 0.07)
	end
	local cercle, image = medaillon(cadre, {Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(78, 78)}, CRISTAL, 3)
	avatar(chef, image)
	local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.1, 1.1),
		BackgroundTransparency = 1, ZIndex = 3, Parent = cercle}, {coin(0.5), trait(CRISTAL, 2, 0.2)})
	TweenService:Create(anneau, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.fromScale(1.3, 1.3)}):Play()
	texte({Text = "<b>" .. echapper(nomChef) .. "</b> t'invite dans la grotte", RichText = true, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(106, 12), Size = UDim2.fromOffset(270, 44), ZIndex = 3, Parent = cadre}, 20)
	local accepter = boutonSimple({Position = UDim2.fromOffset(106, 60), Size = UDim2.fromOffset(150, 50), ZIndex = 3, Parent = cadre}, "ACCEPTER", T.Vert)
	local refuser = boutonSimple({Position = UDim2.fromOffset(264, 60), Size = UDim2.fromOffset(112, 50), ZIndex = 3, Parent = cadre}, "REFUSER", T.Rouge, 18)
	local minuterie = creer("Frame", {Position = UDim2.fromOffset(14, 116), Size = UDim2.fromOffset(362, 4), BackgroundColor3 = T.Or, BorderSizePixel = 0,
		ZIndex = 3, Parent = cadre}, {coin(0.5)})
	TweenService:Create(minuterie, TweenInfo.new(DUREE_INVITATION, Enum.EasingStyle.Linear), {Size = UDim2.fromOffset(0, 4),
		BackgroundColor3 = T.Rouge}):Play()

	cartes[chef] = {cadre = cadre, id = moi}
	table.insert(ordreCartes, chef)
	UI.pop(cadre, 0.7)
	placerCartes()
	jouer("ouvrir", 1.1)
	jouer("succes")

	accepter.Activated:Connect(function()
		jouer("metal")
		retirerCarte(chef, true)
	end)
	refuser.Activated:Connect(function()
		jouer("clic", 0.9)
		retirerCarte(chef, false)
	end)
	task.delay(DUREE_INVITATION, function()
		local c = cartes[chef]
		if c and c.id == moi then
			retirerCarte(chef, false) -- pas de réponse = refus
		end
	end)
end

-- ================= Écran (UIScale selon la taille) =================
local connexionCamera: RBXScriptConnection? = nil
local function ajusterEchelle()
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	echelleEcran.Scale = math.clamp(math.min(vp.X / (LARGEUR + 40), vp.Y / (HAUTEUR + 30)), 0.5, 1.35)
	local petit = math.clamp(math.min(vp.X / 900, vp.Y / 620), 0.85, 1.2)
	echelleCartes.Scale, echelleMessage.Scale = petit, petit
end
local function suivreCamera()
	if connexionCamera then
		connexionCamera:Disconnect()
	end
	local cam = workspace.CurrentCamera
	if cam then
		connexionCamera = cam:GetPropertyChangedSignal("ViewportSize"):Connect(ajusterEchelle)
	end
	ajusterEchelle()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(suivreCamera)
suivreCamera()

-- ================= Réseau =================
local function appliquerEtat(e: any)
	if type(e) ~= "table" then
		return
	end
	estChef = e.estChef == true
	chefId = if type(e.chef) == "number" then e.chef else 0
	membres = {}
	if type(e.membres) == "table" then
		for _, m in e.membres do
			if type(m) == "table" and type(m.userId) == "number" then
				table.insert(membres, {userId = m.userId, nom = if type(m.nom) == "string" then m.nom else "?"})
			end
		end
	end
	invitesServeur = {}
	if type(e.invites) == "table" then
		for _, userId in e.invites do
			if type(userId) == "number" then
				invitesServeur[userId] = true
			end
		end
	end
	for userId in invitesLocales do
		if invitesServeur[userId] or estMembre(userId) then
			invitesLocales[userId] = nil
		end
	end
	if attente then
		attente, choisiId = false, nil
		majVerrous()
	end
	majGroupe()
	majRoles()
	rafraichirListe()
end

evOuvrir.OnClientEvent:Connect(function(e)
	appliquerEtat(e)
	ouvrirFenetre()
end)
evFermer.OnClientEvent:Connect(function()
	fermerFenetre(false)
end)
evInvitation.OnClientEvent:Connect(function(chef, nomChef)
	if type(chef) == "number" then
		afficherInvitation(chef, if type(nomChef) == "string" then nomChef else "Un mineur")
	end
end)
evMessage.OnClientEvent:Connect(function(txt)
	if type(txt) == "string" then
		notifier(txt)
	end
end)

-- Équipement modifié → barres recalculées
for _, nom in {"StatPioche", "StatEpee", "StatDefense"} do
	joueur:GetAttributeChangedSignal(nom):Connect(function()
		if ouverte then
			majBarres(false)
		end
	end)
end

-- Mort du personnage → on ferme (et on quitte le groupe)
local function surPersonnage(perso: Model)
	local hum = perso:WaitForChild("Humanoid", 10) :: Humanoid?
	if hum then
		hum.Died:Connect(function()
			fermerFenetre(true)
		end)
	end
end
joueur.CharacterAdded:Connect(surPersonnage)
joueur.CharacterRemoving:Connect(function()
	fermerFenetre(true)
end)
if joueur.Character then
	task.spawn(surPersonnage, joueur.Character)
end
