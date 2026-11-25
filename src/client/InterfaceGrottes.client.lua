--!strict
-- Grottes profondes · INTERFACE (StarterPlayerScripts › Jeu)
-- 1. Choix de la profondeur (ouvert par le serveur quand le chef entre dans le cercle) : 8 paliers, une barre de
--    danger chacun (selon l'équipement du joueur), les minerais du palier en pastilles 3D qui se chevauchent
--    (générées depuis Grottes.NIVEAUX, du plus fréquent au plus rare ; silhouette noire « ??? » tant que le
--    joueur n'a jamais miné ce minerai), agrandissement au survol, bloc « Groupe » avec invitation.
-- 2. Carte d'invitation (Accepter / Refuser, 20 s) et petites notifications.
-- Le serveur (Grottes.server.lua) fait foi : ici on affiche et on demande, rien de plus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))
local MineraisModeles = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MineraisModeles"))
local PiochesVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("PiochesVoxels"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local T, creer, coin, trait, texte, jouer = UI.T, UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Grottes")
local function remote(nom: string): RemoteEvent
	return dossier:WaitForChild(nom) :: RemoteEvent
end
local evOuvrir, evFermer, evChoisir, evQuitter = remote("Ouvrir"), remote("Fermer"), remote("Choisir"), remote("Quitter")
local evInviter, evInvitation, evRepondre, evMessage = remote("Inviter"), remote("Invitation"), remote("Repondre"), remote("Message")

local LARGEUR = 640 -- taille de conception (mise à l'échelle par UIScale) ; le panneau « Groupe » est collé à droite
-- hauteur : 500 pour 5 paliers, + 72 par palier en plus (une carte de 64 + 8 d'écart)
local HAUTEUR = 500 + (#Grottes.NIVEAUX - 5) * 72
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

-- Bouton fermer rond : croix « X » dessinée avec deux barres (pas de glyphe de police), toujours droite ;
-- au survol elle grossit seulement (UIScale), aucune rotation
local function boutonFermer(props: {[string]: any}): TextButton
	props.Text, props.Rotation = "", 0
	props.BackgroundColor3, props.AutoButtonColor = Color3.fromRGB(150, 44, 32), false
	local z = (props.ZIndex or 1) + 1
	local b = creer("TextButton", props, {coin(0.5), trait(Color3.fromRGB(60, 16, 10), 3), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150))})
	for _, angle in {45, -45} do
		creer("Frame", {Name = "Croix", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.12),
			Rotation = angle, BackgroundColor3 = T.Parchemin, BorderSizePixel = 0, ZIndex = z, Parent = b},
			{coin(0.5), trait(Color3.fromRGB(60, 16, 10), 1.5, 0.3)})
	end
	UI.reactif(b, 1.12)
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

-- ================= Fond d'écran : galerie de mine en 3D (derrière la fenêtre) =================
-- Une seule ViewportFrame plein écran, construite une fois : galerie qui s'enfonce (paroi de roche Slate/Rock/Basalt,
-- cadres de soutènement en bois avec chapeau, jambes de force et ferrures, voie ferrée sur traverses, wagonnet),
-- les VRAIS minerais du jeu (MineraisModeles) incrustés dans la paroi, les VRAIES pioches (ReplicatedStorage ›
-- ModelesPioches, sinon Partage › PiochesVoxels, comme IconesObjets) appuyées aux poteaux, lanternes.
-- Brouillard simulé (couleurs assombries avec la profondeur, pas de lumière dans un viewport), caméra qui oscille
-- très lentement (parallaxe) : la boucle est dans « boucles », donc arrêtée quand le menu est fermé.
local decorMine = creer("Frame", {Name = "DecorMine", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = voile})
type Fondu = {objet: Instance, prop: string, base: number}
local fondus: {Fondu} = {}
local function fondu(objet: Instance, prop: string, base: number)
	table.insert(fondus, {objet = objet, prop = prop, base = base})
	;(objet :: any)[prop] = 1
end
local function fondreDecor(visible: boolean, info: TweenInfo)
	for _, f in fondus do
		TweenService:Create(f.objet, info, {[f.prop] = if visible then f.base else 1}):Play()
	end
end

local vueMine = creer("ViewportFrame", {Name = "Galerie", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 9, 8),
	Ambient = Color3.fromRGB(96, 80, 68), LightColor = Color3.fromRGB(255, 200, 150), LightDirection = Vector3.new(0.35, -1, -0.45),
	BorderSizePixel = 0, ZIndex = 1, Parent = decorMine})
fondu(vueMine, "ImageTransparency", 0)
fondu(vueMine, "BackgroundTransparency", 0)
do
	local scene = Instance.new("Model")
	scene.Name = "Galerie"
	local rng = Random.new(31)
	local SOMBRE = Color3.fromRGB(10, 8, 7)
	local BOIS, BOIS_SOMBRE = Color3.fromRGB(118, 84, 54), Color3.fromRGB(70, 48, 30)
	local FER, ROUILLE = Color3.fromRGB(78, 78, 82), Color3.fromRGB(104, 70, 50)
	local ROCHES = {Color3.fromRGB(98, 86, 76), Color3.fromRGB(84, 74, 68), Color3.fromRGB(112, 98, 86), Color3.fromRGB(72, 64, 60)}
	local MATS_ROCHE = {Enum.Material.Slate, Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt}
	local FOND_Z = -72

	-- « brouillard » : plus c'est loin, plus c'est sombre
	local function brume(c: Color3, z: number): Color3
		return c:Lerp(SOMBRE, math.clamp((-z - 1) / 58, 0, 0.9))
	end
	local function piece(taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, forme: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Size, p.CFrame, p.Material = taille, cf, mat
		p.Color = brume(couleur, cf.Position.Z)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if forme then
			p.Shape = forme
		end
		p.Parent = scene
		return p
	end
	local function varie(c: Color3, f: number): Color3
		return c:Lerp(if rng:NextNumber() < 0.5 then SOMBRE else Color3.fromRGB(190, 170, 150), rng:NextNumber(0, f))
	end
	local function rot(a: number): CFrame
		return CFrame.Angles(rng:NextNumber(-a, a), rng:NextNumber(-a, a), rng:NextNumber(-a, a))
	end
	-- modèle cloné (minerai, pioche) : nettoyé, ancré, assombri selon la profondeur, néons adoucis (pas de fluo)
	local function preparer(m: Model)
		for _, d in m:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("BillboardGui") or d:IsA("LuaSourceContainer") or d:IsA("Beam") or d:IsA("Trail") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored, d.CastShadow = true, false
				if d.Material == Enum.Material.Neon then
					d.Material, d.Reflectance = Enum.Material.SmoothPlastic, 0.15
					d.Color = d.Color:Lerp(SOMBRE, 0.25)
				end
				d.Color = brume(d.Color, d.Position.Z)
			end
		end
		m.Parent = scene
	end

	-- Sol de terre battue + ballast de la voie (par tronçons, pour le dégradé de profondeur)
	for z = 6, FOND_Z, -4 do
		piece(Vector3.new(15, 1, 4.05), CFrame.new(0, -0.5, z - 2), Color3.fromRGB(80, 64, 50), Enum.Material.Ground)
		piece(Vector3.new(4.2, 0.2, 4.05), CFrame.new(0, 0.02, z - 2), Color3.fromRGB(92, 86, 80), Enum.Material.Pebble)
	end
	-- Parois et voûte : blocs de roche irréguliers devant un mur continu
	for z = 7, FOND_Z, -2.5 do
		for _, cote in {-1, 1} do
			piece(Vector3.new(1.5, 12, 2.6), CFrame.new(cote * 8.6, 5, z), Color3.fromRGB(58, 50, 46), Enum.Material.Slate)
			for k = 1, 3 do
				local i = rng:NextInteger(1, #ROCHES)
				local t = Vector3.new(rng:NextNumber(1.6, 3), rng:NextNumber(2.2, 3.8), rng:NextNumber(2.2, 3.4))
				piece(t, CFrame.new(cote * (7.6 + rng:NextNumber(-0.4, 0.5)), (k - 1) * 3.1 + rng:NextNumber(0.4, 1.6), z + rng:NextNumber(-0.9, 0.9)) * rot(0.35),
					varie(ROCHES[i], 0.25), MATS_ROCHE[i])
			end
		end
		piece(Vector3.new(18, 1.5, 2.6), CFrame.new(0, 11.2, z), Color3.fromRGB(52, 46, 42), Enum.Material.Slate)
		for _ = 1, 3 do
			local i = rng:NextInteger(1, #ROCHES)
			piece(Vector3.new(rng:NextNumber(2.5, 4.5), rng:NextNumber(1, 1.8), rng:NextNumber(2, 3)),
				CFrame.new(rng:NextNumber(-6, 6), 10.4 + rng:NextNumber(-0.2, 0.3), z + rng:NextNumber(-0.8, 0.8)) * rot(0.25), varie(ROCHES[i], 0.25), MATS_ROCHE[i])
		end
	end
	piece(Vector3.new(18, 13, 1), CFrame.new(0, 5.5, FOND_Z - 2), SOMBRE, Enum.Material.Slate)

	-- Voie : traverses en bois, rails en acier (champignon + patin rouillé)
	for z = 6.5, FOND_Z, -1.45 do
		piece(Vector3.new(4.3, 0.28, 0.72), CFrame.new(rng:NextNumber(-0.12, 0.12), 0.26, z) * CFrame.Angles(0, rng:NextNumber(-0.05, 0.05), 0),
			varie(Color3.fromRGB(86, 62, 42), 0.3), Enum.Material.WoodPlanks)
	end
	for z = 6, FOND_Z, -6 do
		for _, s in {-1, 1} do
			piece(Vector3.new(0.5, 0.09, 6.02), CFrame.new(s * 1.25, 0.45, z - 3), ROUILLE, Enum.Material.CorrodedMetal)
			piece(Vector3.new(0.12, 0.2, 6.02), CFrame.new(s * 1.25, 0.6, z - 3), Color3.fromRGB(70, 66, 64), Enum.Material.Metal)
			local tete = piece(Vector3.new(0.26, 0.14, 6.02), CFrame.new(s * 1.25, 0.76, z - 3), Color3.fromRGB(150, 146, 142), Enum.Material.Metal)
			tete.Reflectance = 0.12
		end
	end

	-- Cadres de soutènement : poteaux sur semelle, chapeau, jambes de force, ferrures, garnissage du plafond
	local function cadre(z: number)
		local h, demi = 8.4, 6.3
		for _, s in {-1, 1} do
			local x = s * demi
			piece(Vector3.new(1.15, h, 1.15), CFrame.new(x, h / 2, z) * CFrame.Angles(0, rng:NextNumber(-0.06, 0.06), s * rng:NextNumber(0.01, 0.04)),
				varie(BOIS, 0.2), Enum.Material.Wood)
			piece(Vector3.new(1.7, 0.35, 1.7), CFrame.new(x, 0.17, z), varie(BOIS_SOMBRE, 0.2), Enum.Material.WoodPlanks)
			local a, b = Vector3.new(s * (demi - 0.35), h - 2.5, z), Vector3.new(s * (demi - 2.5), h - 0.2, z)
			piece(Vector3.new(0.6, 0.6, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), varie(BOIS, 0.25), Enum.Material.Wood)
			for _, y in {h - 0.8, 1.4} do
				piece(Vector3.new(1.28, 0.22, 1.28), CFrame.new(x, y, z), FER, Enum.Material.CorrodedMetal)
			end
		end
		piece(Vector3.new(demi * 2 + 1.8, 1.2, 1.35), CFrame.new(0, h + 0.6, z) * CFrame.Angles(0, 0, rng:NextNumber(-0.012, 0.012)),
			varie(BOIS, 0.2), Enum.Material.Wood)
		for k = -2, 2 do
			piece(Vector3.new(2.2, 0.28, 3.2), CFrame.new(k * 2.6, h + 1.35, z - 1.3) * CFrame.Angles(0, 0, rng:NextNumber(-0.04, 0.04)),
				varie(BOIS_SOMBRE, 0.3), Enum.Material.WoodPlanks)
		end
	end
	for z = 1, FOND_Z + 8, -10 do
		cadre(z)
	end

	-- Lanternes accrochées au chapeau des deux premiers cadres (verre ambré, cage de fer)
	for _, l in {{-3.6, 1}, {3.6, 1}, {-3.2, -9}, {3.2, -9}} do
		local x, z = l[1], l[2]
		piece(Vector3.new(0.08, 0.9, 0.08), CFrame.new(x, 8.05, z), FER, Enum.Material.Metal)
		piece(Vector3.new(0.7, 0.16, 0.7), CFrame.new(x, 7.55, z), FER, Enum.Material.Metal)
		piece(Vector3.new(0.75, 0.12, 0.75), CFrame.new(x, 6.75, z), FER, Enum.Material.Metal)
		piece(Vector3.new(0.46, 0.62, 0.46), CFrame.new(x, 7.15, z), Color3.fromRGB(236, 160, 82), Enum.Material.Neon)
		for _, c in {Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1)} do
			piece(Vector3.new(0.07, 0.75, 0.07), CFrame.new(x + c.X * 0.29, 7.15, z + c.Y * 0.29), FER, Enum.Material.Metal)
		end
	end

	-- Wagonnet en fer rouillé sur la voie, chargé de charbon (vrai modèle de minerai par-dessus)
	do
		local z0, y0 = -4, 1.25
		piece(Vector3.new(2.9, 0.22, 3.6), CFrame.new(0, y0, z0), ROUILLE, Enum.Material.CorrodedMetal)
		for _, s in {-1, 1} do
			piece(Vector3.new(0.16, 1.6, 3.6), CFrame.new(s * 1.45, y0 + 0.8, z0) * CFrame.Angles(0, 0, s * -0.1), ROUILLE, Enum.Material.CorrodedMetal)
			piece(Vector3.new(2.9, 1.6, 0.16), CFrame.new(0, y0 + 0.8, z0 + s * 1.8) * CFrame.Angles(s * 0.1, 0, 0), ROUILLE, Enum.Material.CorrodedMetal)
			piece(Vector3.new(3.3, 0.16, 0.2), CFrame.new(0, y0 + 1.62, z0 + s * 1.88), FER, Enum.Material.Metal)
			piece(Vector3.new(0.2, 0.16, 3.9), CFrame.new(s * 1.55, y0 + 1.62, z0), FER, Enum.Material.Metal)
			for _, w in {-1, 1} do
				piece(Vector3.new(0.3, 0.95, 0.95), CFrame.new(s * 1.25, 0.95, z0 + w * 1.1), Color3.fromRGB(46, 44, 44), Enum.Material.Metal, Enum.PartType.Cylinder)
			end
		end
		for _ = 1, 14 do
			local t = rng:NextNumber(0.4, 0.75)
			piece(Vector3.new(t, t * 0.8, t), CFrame.new(rng:NextNumber(-1, 1), y0 + 1.45 + rng:NextNumber(0, 0.35), z0 + rng:NextNumber(-1.3, 1.3)) * rot(1.5),
				Color3.fromRGB(34, 34, 38), Enum.Material.Slate)
		end
		local charge = MineraisModeles.construire("Charbon", CFrame.new(0.2, y0 + 1.2, z0 - 0.3), Random.new(5), true)
		charge:ScaleTo(0.55)
		preparer(charge)
	end

	-- Vrais minerais du jeu incrustés dans la paroi (l'axe « haut » du rocher pointe vers le centre de la galerie)
	for i, o in {{"Charbon", -1, 1.2, 3.2}, {"Bronze", 1, 1.6, 2.4}, {"Gold", -1, 6.4, -1.8}, {"Fer", 1, 5.8, -3.5},
		{"Charbon", 1, 0.9, -7}, {"Fer", -1, 3.6, -6.5}, {"Bronze", -1, 1.2, -13}, {"Gold", 1, 4.5, -15}} do
		local id, cote, y, z = o[1] :: string, o[2] :: number, o[3] :: number, o[4] :: number
		if MineraisModeles.VISUEL[id] then
			local sol = CFrame.new(cote * 7.3, y, z) * CFrame.Angles(0, 0, cote * math.pi / 2) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
			local m = MineraisModeles.construire(id, sol, Random.new(i * 17 + 3), true)
			m:ScaleTo(0.72)
			preparer(m)
		end
	end

	-- Vraies pioches du jeu appuyées contre les poteaux du premier cadre
	local function pioche(id: string, cote: number)
		local dossier = ReplicatedStorage:FindFirstChild("ModelesPioches")
		local importe = dossier and dossier:FindFirstChild(id)
		local m: Model? = if importe and importe:IsA("Model") then importe:Clone() else PiochesVoxels.construire(id)
		if not m then
			return
		end
		m.WorldPivot = CFrame.identity
		local cf, taille = m:GetBoundingBox()
		m.WorldPivot = CFrame.new(cf.Position)
		m:ScaleTo(4.6 / math.max(taille.X, taille.Y, taille.Z))
		-- manche le long de Y, pic vers -Z (repère PiochesVoxels) : pic tourné vers le centre, manche penché contre le poteau
		m:PivotTo(CFrame.new(cote * 5.4, 2.25, 2.1) * CFrame.Angles(0, 0, -cote * 0.26) * CFrame.Angles(0, cote * math.pi / 2, 0))
		preparer(m)
	end
	pioche("Fer", -1)
	pioche("Cuivre", 1)

	scene.Parent = vueMine
	local camera = Instance.new("Camera")
	camera.FieldOfView = 62
	camera.Parent = vueMine
	vueMine.CurrentCamera = camera
	local BASE_CAMERA = CFrame.lookAt(Vector3.new(0, 4.2, 9.5), Vector3.new(0, 3.6, -30))
	camera.CFrame = BASE_CAMERA
	-- parallaxe : très lente oscillation de la caméra (jouée seulement menu ouvert)
	local oscillation = Instance.new("CFrameValue")
	oscillation.Changed:Connect(function(v: CFrame)
		camera.CFrame = BASE_CAMERA * v
	end)
	UI.boucle(oscillation, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Value = CFrame.new(0.45, 0.15, 0) * CFrame.Angles(0, math.rad(-1), 0)}, boucles)
end

-- Ambiance par-dessus la scène : lueur chaude en haut (lanternes), voile sombre léger (lisibilité des niveaux),
-- vignettage sur les bords
local lueurHaut = creer("Frame", {Size = UDim2.fromScale(1, 0.45), BackgroundColor3 = Color3.fromRGB(255, 170, 90), BorderSizePixel = 0,
	ZIndex = 2, Parent = decorMine}, {creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.82),
		NumberSequenceKeypoint.new(1, 1)})})})
fondu(lueurHaut, "BackgroundTransparency", 0)
local voileDecor = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 6, 5), BorderSizePixel = 0, ZIndex = 3,
	Parent = decorMine})
fondu(voileDecor, "BackgroundTransparency", 0.72)
local vignette = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 4, Parent = decorMine},
	{creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.2, 0.95),
		NumberSequenceKeypoint.new(0.8, 0.95), NumberSequenceKeypoint.new(1, 0.4)})})})
fondu(vignette, "BackgroundTransparency", 0)

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
-- (bordure simple : ni équerres de coin ni rivets, comme les fenêtres PNJ)

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
	Position = UDim2.fromOffset(86, 12), Size = UDim2.fromOffset(450, 50), ZIndex = 5, Parent = interieur}, 44)
UI.dore(titre, 2.5)
-- Séparateur de l'en-tête : bande unie (sans rivets) + liseré doré
creer("Frame", {Name = "Separateur", Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Color3.fromRGB(26, 17, 11),
	BorderSizePixel = 0, ZIndex = 5, Parent = interieur})
creer("Frame", {Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.OrFonce, BackgroundTransparency = 0.55,
	BorderSizePixel = 0, ZIndex = 5, Parent = interieur})

local fermer = boutonFermer({Name = "Fermer", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.fromOffset(64, 64), ZIndex = 12, Parent = corps})

-- ================= Paliers (colonne de gauche) =================
local Y0, H_LIGNE, ECART, X_CARTE, L_CARTE = 98, 64, 8, 64, 538

-- Puits : corde verticale + nœuds lumineux
creer("Frame", {Name = "Puits", Position = UDim2.fromOffset(31, Y0 + 8), Size = UDim2.fromOffset(6, #Grottes.NIVEAUX * (H_LIGNE + ECART) - ECART - 16),
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
	pastilles: {Pastille},
	bulle: TextLabel,
	survol: boolean,
}
local lignes: {Ligne} = {}

-- ================= Minerais du palier (pastilles 3D qui se chevauchent) =================
-- Ordre : du plus fréquent au plus rare (Grottes.partsMinerais, estimation qui suit le générateur), le plus
-- fréquent à gauche et au-dessus de la pile. Jamais miné → silhouette noire + « ??? » (comme un Pokédex).
type Pastille = {id: string, part: number, cadre: Frame, echelle: UIScale, vp: ViewportFrame, bord: UIStroke,
	lueur: Frame, badge: Frame, k: number, n: number, decouvert: boolean?, survol: boolean}

local D_PASTILLE, PAS_SERRE, PAS_ECARTE, L_PILE = 42, 25, 29, 104
local ANNEAU = {Charbon = Color3.fromRGB(150, 150, 168), Bronze = Color3.fromRGB(255, 146, 66), Fer = Color3.fromRGB(176, 214, 255),
	Gold = Color3.fromRGB(255, 212, 92)} :: {[string]: Color3}
local PIERRE_CLAIRE, PIERRE_FROIDE = Color3.fromRGB(150, 134, 124), Color3.fromRGB(150, 146, 158)

local decouverts: {[string]: boolean} = {}
local function lireDecouverts(): {[string]: boolean}
	local res = {}
	local v = joueur:GetAttribute(Grottes.ATTRIBUT_DECOUVERTS)
	if type(v) == "string" then
		for id in v:gmatch("[^,]+") do
			res[id] = true
		end
	end
	return res
end

local function anneau(id: string): Color3
	local v = MineraisModeles.VISUEL[id]
	return ANNEAU[id] or (if v then v.couleur else T.Gris)
end

local function placePastille(p: Pastille, pas: number): UDim2
	return UDim2.new(1, -D_PASTILLE / 2 - (p.n - p.k) * pas, 0.5, 0)
end

-- Apparence selon « découvert » ; renvoie vrai si l'état a changé après la création (animation de découverte)
local function peindrePastille(p: Pastille, decouvert: boolean): boolean
	if p.decouvert == decouvert then
		return false
	end
	local avant = p.decouvert
	p.decouvert = decouvert
	local vue = Icones.vue(p.vp)
	Icones.definir(p.vp, "minerai", p.id, {vitesse = if vue then vue.vitesse else 0, silhouette = not decouvert, marge = 0.78,
		hauteur = 0.35, angle = if vue then vue.angle else 0.5 + p.k * 1.3})
	local c = anneau(p.id)
	p.bord.Color = if decouvert then c:Lerp(ENCRE, 0.15) else ENCRE
	p.bord.Thickness = if decouvert then 2.5 else 2
	p.cadre.BackgroundColor3 = if decouvert then PIERRE_CLAIRE:Lerp(c, 0.18) else PIERRE_FROIDE
	p.lueur.BackgroundColor3 = c
	p.lueur.Visible = decouvert
	p.badge.Visible = not decouvert
	return avant ~= nil
end

local function creerPastilles(carte: TextButton, niveau: any): ({Pastille}, TextLabel)
	local pile = creer("Frame", {Name = "Minerais", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(L_PILE, D_PASTILLE + 4), BackgroundTransparency = 1, ZIndex = 6, Parent = carte})
	local parts = Grottes.partsMinerais(niveau)
	local liste: {Pastille} = {}
	for k, e in parts do
		local cadre = creer("Frame", {Name = e.id, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(D_PASTILLE, D_PASTILLE),
			BackgroundColor3 = PIERRE_FROIDE, ZIndex = 20 - k, Parent = pile}, {coin(0.5),
			creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 240)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(190, 180, 172)), ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 86, 84))})})})
		local bord = trait(ENCRE, 2)
		bord.Parent = cadre
		local echelle = creer("UIScale", {Parent = cadre})
		-- halo de la couleur du minerai derrière le rocher (découvert seulement)
		local lueur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.82, 0.82),
			BackgroundColor3 = T.Gris, BackgroundTransparency = 0.55, BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = cadre}, {coin(0.5),
			creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1)})})})
		-- reflet en haut de la pastille
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromScale(0.62, 0.26),
			BackgroundColor3 = BLANC, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 4, Parent = cadre}, {coin(0.5)})
		local vp = Icones.creer(cadre)
		vp.AnchorPoint, vp.Position, vp.Size, vp.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.96, 0.96), 2
		-- petit « ? » gravé (non découvert)
		local badge = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.84, 0.84), Size = UDim2.fromScale(0.36, 0.36),
			BackgroundColor3 = T.BoisSombre, ZIndex = 5, Parent = cadre}, {coin(0.5), trait(T.Gris, 1.2, 0.2)})
		texte({Text = "?", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = badge}, 12)
		local p: Pastille = {id = e.id, part = e.part, cadre = cadre, echelle = echelle, vp = vp, bord = bord, lueur = lueur,
			badge = badge, k = k, n = #parts, decouvert = nil, survol = false}
		cadre.Position = placePastille(p, PAS_SERRE)
		peindrePastille(p, decouverts[e.id] == true)
		table.insert(liste, p)
	end
	-- Infobulle (nom ou « ??? ») au-dessus de la pastille survolée
	local bulle = texte({Name = "Bulle", Text = "", RichText = true, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin,
		AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(118, 24), Visible = false, ZIndex = 40, Parent = pile}, 15)
	bulle.BackgroundTransparency, bulle.BackgroundColor3 = 0.04, T.BoisSombre
	creer("UICorner", {CornerRadius = UDim.new(0, 8), Parent = bulle})
	creer("UIStroke", {Color = T.OrFonce, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bulle})
	creer("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 3), Parent = bulle})
	creer("UIScale", {Parent = bulle})
	return liste, bulle
end

local function texteBulle(p: Pastille): string
	if not p.decouvert then
		return '<font color="#9c9084">???</font>'
	end
	local nom = Grottes.NOMS_MINERAIS[p.id] or p.id
	local frequence = if p.part >= 0.45 then "abondant" elseif p.part < 0.15 then "rare" else "courant"
	return string.format('%s <font color="#9c9084">· %s</font>', echapper(nom), frequence)
end

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
	local barreFond = creer("Frame", {Name = "Barre", Position = UDim2.fromOffset(150, 17), Size = UDim2.fromOffset(236, 15),
		BackgroundColor3 = Color3.fromRGB(20, 14, 12), ZIndex = 6, Parent = carte}, {coin(0.5), trait(ENCRE, 1.5)})
	local plein = creer("Frame", {Name = "Plein", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Grottes.couleurDanger(0), BorderSizePixel = 0,
		ZIndex = 7, Parent = barreFond}, {coin(0.5), UI.degrade(BLANC, Color3.fromRGB(165, 165, 165))})
	creer("Frame", {Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.34), BackgroundColor3 = BLANC, BackgroundTransparency = 0.7,
		BorderSizePixel = 0, ZIndex = 8, Parent = plein}, {coin(0.5)})
	for k = 1, 4 do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(k / 5, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 9, Parent = barreFond})
	end
	-- Minerais du palier (à droite, à la place des anciens crans de difficulté)
	local pastilles, bulle = creerPastilles(carte, niveau)
	-- Ligne d'info (nom du palier + danger), visible au survol seulement
	local info = texte({Font = Enum.Font.GothamBold, RichText = true, TextColor3 = T.Parchemin, TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(150, 38), Size = UDim2.fromOffset(240, 18), ZIndex = 6, Parent = carte}, 15)
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
		plein = plein, info = info, noeud = noeud, assombri = assombri, pastilles = pastilles, bulle = bulle, survol = false}
end

decouverts = lireDecouverts()
for i, niveau in Grottes.NIVEAUX do
	table.insert(lignes, creerLigne(niveau, i))
end

-- Survol d'une pastille : elle grossit, passe devant la pile et affiche son nom (ou « ??? »)
local function survolPastille(l: Ligne, p: Pastille, actif: boolean)
	if p.survol == actif then
		return
	end
	p.survol = actif
	p.cadre.ZIndex = if actif then 30 else 20 - p.k
	TweenService:Create(p.echelle, if actif then BOUNCY else FAST, {Scale = if actif then 1.2 else 1}):Play()
	local b = l.bulle
	local e = b:FindFirstChildOfClass("UIScale") :: UIScale
	if actif then
		b.Text = texteBulle(p)
		b.Position = UDim2.new(p.cadre.Position.X.Scale, p.cadre.Position.X.Offset, 0, -2)
		b.Visible = true
		e.Scale = 0.7
		TweenService:Create(e, BOUNCY, {Scale = 1}):Play()
		jouer("survol", 1.8)
	else
		task.delay(0.05, function()
			for _, autre in l.pastilles do
				if autre.survol then
					return
				end
			end
			b.Visible = false
		end)
	end
end

for _, l in lignes do
	for _, p in l.pastilles do
		p.cadre.MouseEnter:Connect(function()
			survolPastille(l, p, true)
		end)
		p.cadre.MouseLeave:Connect(function()
			survolPastille(l, p, false)
		end)
		p.cadre.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				survolPastille(l, p, true)
				task.delay(1.6, function()
					survolPastille(l, p, false)
				end)
			end
		end)
	end
end

-- Pile de minerais : s'écarte et les rochers tournent quand le palier est survolé
local function animerPile(l: Ligne, actif: boolean)
	for _, p in l.pastilles do
		TweenService:Create(p.cadre, SURVOL, {Position = placePastille(p, if actif then PAS_ECARTE else PAS_SERRE)}):Play()
		local vue = Icones.vue(p.vp)
		if vue then
			vue.vitesse = if actif then 1.3 else 0
		end
		if not actif then
			survolPastille(l, p, false)
		end
	end
end

-- Minerai découvert (attribut posé par le serveur) : la silhouette se colore, petit éclat si le menu est ouvert
local function majDecouvertes()
	decouverts = lireDecouverts()
	local nouveau = false
	for _, l in lignes do
		for _, p in l.pastilles do
			if peindrePastille(p, decouverts[p.id] == true) and p.decouvert and ouverte then
				nouveau = true
				p.echelle.Scale = 0.6
				TweenService:Create(p.echelle, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
				local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 0.1, ZIndex = 7,
					Parent = p.cadre}, {coin(0.5)})
				TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
				Debris:AddItem(flash, 0.65)
			end
		end
	end
	if nouveau then
		jouer("succes", 1.3)
	end
end
joueur:GetAttributeChangedSignal(Grottes.ATTRIBUT_DECOUVERTS):Connect(majDecouvertes)

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
	animerPile(l, actif)
	if actif then
		jouer("survol", 1.55 - l.niveau.id * 0.1) -- plus c'est profond, plus c'est grave
	end
end

local LIBELLES_NIVEAU = {"Facile", "Modéré", "Difficile", "Extrême", "Impossible", "Infernal", "Abyssal", "Cauchemar"}

-- Barres de difficulté : niveau N = N / (nombre de paliers) de la jauge, du vert (1) au rouge (5) ; la ligne d'info du survol
-- garde le danger selon l'équipement (recalculée quand l'équipement change)
local function majBarres(depuisZero: boolean)
	local s = stats()
	local total = #Grottes.NIVEAUX
	for i, l in lignes do
		local d = Grottes.danger(l.niveau, s)
		if depuisZero then
			l.plein.Size = UDim2.fromScale(0, 1)
		end
		local part = l.niveau.difficulte / total
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

-- ================= Panneau « Groupe » (collé à droite de la fenêtre, hors du cadre) =================
-- Deux ronds empilés : 1 = le chef (couronne), 2 = le partenaire. Chez le chef, le rond 2 vide est un gros « + »
-- qui pulse (clic = liste d'invitation) ; invité en attente = avatar voilé + arc qui tourne ; partenaire = son avatar.
-- Enfant de « corps » : il suit l'animation d'ouverture/fermeture et l'échelle de la fenêtre.
local L_PANNEAU, H_PANNEAU, ECART_PANNEAU, D_ROND = 108, 244, 14, 76
local Y_ROND1, Y_ROND2 = 22, 138
creer("Frame", {Name = "OmbreGroupe", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, ECART_PANNEAU + 6, 0.5, 10),
	Size = UDim2.fromOffset(L_PANNEAU, H_PANNEAU), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, ZIndex = 0, Parent = corps},
	{arrondi(16)})
local panneauGroupe = creer("Frame", {Name = "Groupe", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, ECART_PANNEAU, 0.5, 0),
	Size = UDim2.fromOffset(L_PANNEAU, H_PANNEAU), BackgroundColor3 = T.Bois, ZIndex = 1, Parent = corps},
	{arrondi(16), trait(Color3.fromRGB(18, 10, 6), 4), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(grain)})})
creer("Frame", {Name = "Interieur", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), BackgroundColor3 = T.BoisSombre,
	ZIndex = 2, Parent = panneauGroupe}, {arrondi(10), trait(T.FerSombre, 2),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(190, 180, 200), Color3.fromRGB(110, 90, 120))})})


type Rond = {bouton: TextButton, lueur: Frame, cercle: Frame, image: ImageLabel, bord: UIStroke, plus: TextLabel, appel: Frame,
	attente: Frame, couronne: Frame, nom: TextLabel, userId: number?}

local function creerRond(y: number): Rond
	local b = creer("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, y),
		Size = UDim2.fromOffset(D_ROND, D_ROND), BackgroundTransparency = 1, Active = false, ZIndex = 3, Parent = panneauGroupe})
	-- lueur de survol
	local lueur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3),
		BackgroundColor3 = CRISTAL, BackgroundTransparency = 1, ZIndex = 3, Parent = b}, {coin(0.5)})
	local cercle, image, bord = medaillon(b, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1)},
		T.Gris, 4)
	bord.Thickness = 3
	local plus = texte({Text = "+", Font = Enum.Font.GothamBlack, TextColor3 = CRISTAL, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = cercle}, 54)
	creer("UIStroke", {Thickness = 2, Color = ENCRE, Transparency = 0.3, Parent = plus})
	-- « + » immobile (demande du joueur) : il grossit seulement au survol du rond
	-- onde qui s'élargit autour du rond libre (appel à inviter)
	local appel = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Visible = false, ZIndex = 4, Parent = cercle}, {coin(0.5)})
	local traitAppel = trait(CRISTAL, 2.5, 0.1)
	traitAppel.Parent = appel
	traitAppel.Transparency = 0.55 -- anneau fixe, sans onde animée
	-- arc lumineux qui tourne autour de l'invité en attente
	local attente = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.16, 1.16),
		BackgroundTransparency = 1, Visible = false, ZIndex = 6, Parent = cercle}, {coin(0.5)})
	local traitAttente = trait(CRISTAL, 3)
	traitAttente.Parent = attente
	local gAttente = creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 0.15),
		NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = traitAttente})
	UI.boucle(gAttente, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
	-- badge couronne « CHEF » à cheval sur le haut du rond
	local couronne = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromOffset(46, 18),
		BackgroundColor3 = T.Or, Visible = false, ZIndex = 8, Parent = b}, {coin(0.5), trait(ENCRE, 2),
		UI.degrade(Color3.fromRGB(255, 244, 200), Color3.fromRGB(196, 120, 36))})
	for _, x in {0.25, 0.5, 0.75} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, if x == 0.5 then -0.12 else 0.02),
			Size = UDim2.fromOffset(8, 8), Rotation = 45, BackgroundColor3 = T.Or, ZIndex = 7, Parent = couronne}, {trait(ENCRE, 1.5)})
	end
	texte({Text = "CHEF", Font = Enum.Font.GothamBlack, TextColor3 = ENCRE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.8, 0.7), ZIndex = 9, Parent = couronne}, 12)
	-- pseudo (tronqué) sous le rond
	local nom = texte({Font = Enum.Font.GothamBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, y + D_ROND + 5),
		Size = UDim2.fromOffset(L_PANNEAU - 18, 16), ZIndex = 4, Parent = panneauGroupe}, 13)
	creer("UIStroke", {Thickness = 1.5, Color = ENCRE, Transparency = 0.3, Parent = nom})
	UI.reactif(b, 1.1)
	b.MouseEnter:Connect(function()
		if b.Active then
			TweenService:Create(lueur, SURVOL, {BackgroundTransparency = 0.72}):Play()
		end
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(lueur, SURVOL, {BackgroundTransparency = 1}):Play()
	end)
	return {bouton = b, lueur = lueur, cercle = cercle, image = image, bord = bord, plus = plus, appel = appel, attente = attente,
		couronne = couronne, nom = nom, userId = nil}
end

local rondChef, rondPartenaire = creerRond(Y_ROND1), creerRond(Y_ROND2)
local basculerListe: () -> () = function() end
rondPartenaire.bouton.Activated:Connect(function()
	if estChef and #membres < Grottes.MAX_JOUEURS then
		jouer("clic")
		basculerListe()
	end
end)

local function tronquer(s: string, n: number): string
	local longueur = utf8.len(s)
	if longueur and longueur > n then
		local o = utf8.offset(s, n)
		if o then
			return s:sub(1, o - 1) .. "…"
		end
	end
	return s
end

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

local function afficherMembre(r: Rond, userId: number, nom: string, estLeChef: boolean)
	r.image.Visible, r.plus.Visible, r.appel.Visible, r.attente.Visible = true, false, false, false
	r.image.ImageTransparency = 0
	avatar(userId, r.image)
	r.couronne.Visible = estLeChef
	r.bord.Color, r.bord.Transparency = if estLeChef then T.Or else CRISTAL, 0
	r.nom.Text, r.nom.TextColor3 = tronquer(nom, 9), T.Parchemin
end

local function majGroupe()
	-- rond 1 = le chef, rond 2 = l'autre membre (chez un non-chef : soi-même)
	local chef: {userId: number, nom: string}? = nil
	local autre: {userId: number, nom: string}? = nil
	for _, m in membres do
		if m.userId == chefId and not chef then
			chef = m
		elseif not autre then
			autre = m
		end
	end
	if not chef then
		chef = autre or {userId = joueur.UserId, nom = joueur.DisplayName}
		autre = if autre and membres[2] then membres[2] else nil
	end
	local c = chef :: {userId: number, nom: string}
	afficherMembre(rondChef, c.userId, c.nom, true)
	if rondChef.userId ~= c.userId then
		rondChef.userId = c.userId
		UI.pop(rondChef.cercle, 0.6)
	end

	local r = rondPartenaire
	local enAttente = if estChef then premierInvite() else nil
	if autre then
		afficherMembre(r, autre.userId, autre.nom, false)
		if r.userId ~= autre.userId then
			r.userId = autre.userId
			UI.pop(r.cercle, 0.6)
			if ouverte and estChef then
				-- le partenaire vient de rejoindre
				UI.gerbe(panneauGroupe, CRISTAL, 14, Vector2.new(0.5, (Y_ROND2 + D_ROND / 2) / H_PANNEAU))
				jouer("succes", 1.15)
			end
		end
	elseif enAttente then
		local cible = Players:GetPlayerByUserId(enAttente)
		r.image.Visible, r.plus.Visible, r.appel.Visible, r.attente.Visible, r.couronne.Visible = true, false, false, true, false
		r.image.ImageTransparency = 0.5
		avatar(enAttente, r.image)
		r.bord.Color, r.bord.Transparency = CRISTAL, 0.4
		r.nom.Text, r.nom.TextColor3 = tronquer(if cible then cible.DisplayName else "…", 9), T.Gris
		r.userId = nil
	else
		r.image.Visible, r.attente.Visible, r.couronne.Visible = false, false, false
		r.plus.Visible, r.appel.Visible = estChef, estChef
		r.bord.Color, r.bord.Transparency = if estChef then CRISTAL else T.Gris, if estChef then 0.2 else 0.5
		r.nom.Text = ""
		r.userId = nil
	end
	r.bouton.Active = estChef and #membres < Grottes.MAX_JOUEURS
	if not r.bouton.Active then
		TweenService:Create(r.lueur, FAST, {BackgroundTransparency = 1}):Play()
	end
end

-- ================= Liste d'invitation =================
-- (dans « corps », calée contre le bord droit de la fenêtre : elle s'ouvre juste à côté du panneau Groupe)
local liste = UI.panneau({Name = "ListeInvitation", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(436, 366), BackgroundColor3 = T.BoisSombre, Visible = false, ZIndex = 20, Parent = corps}, 0.04)
local echelleListe = creer("UIScale", {Parent = liste})
local titreListe = texte({Text = "INVITER UN MINEUR", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(18, 8), Size = UDim2.fromOffset(330, 36), ZIndex = 21, Parent = liste}, 32)
UI.dore(titreListe, 2)
texte({Text = "Choisis ton partenaire pour la descente", Font = Enum.Font.GothamBold, TextColor3 = CRISTAL, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(20, 44), Size = UDim2.fromOffset(330, 18), ZIndex = 21, Parent = liste}, 15)
local fermerListe = boutonFermer({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(58, 58),
	ZIndex = 22, Parent = liste})
local defilement = creer("ScrollingFrame", {Position = UDim2.fromOffset(10, 70), Size = UDim2.new(1, -20, 1, -80), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 21, Parent = liste},
	{creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		creer("UIPadding", {PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2)})})
local vide = texte({Text = "Personne d'autre dans la mine pour l'instant", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromOffset(20, 150),
	Size = UDim2.new(1, -40, 0, 30), Visible = false, ZIndex = 22, Parent = liste}, 20)

type Rangee = {bouton: TextButton, sous: TextLabel, bord: UIStroke, pastille: Frame, etiquette: TextLabel, attente: Frame, survol: boolean}
local rangees: {[number]: Rangee} = {}

local function majRangee(userId: number, r: Rangee, joueurCible: Player)
	local ami = estAmi(userId)
	local invite = estInvite(userId)
	r.sous.Text = if ami then "AMI" else "@" .. joueurCible.Name
	r.sous.TextColor3 = if ami then T.Or else T.Gris
	r.sous.Font = if ami then Enum.Font.GothamBlack else Enum.Font.Gotham
	r.bord.Color = if r.survol and not invite then CRISTAL elseif ami then T.OrFonce else T.FerSombre
	r.etiquette.Text = if invite then "ENVOYÉE…" else "INVITER"
	r.pastille.BackgroundColor3 = if invite then T.Inactif else BOUTON_BLEU
	r.attente.Visible = invite
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
		Size = UDim2.fromScale(0.82, 0.5), ZIndex = 25, Parent = pastille}, 18)
	creer("UIStroke", {Thickness = 1.5, Color = ENCRE, Transparency = 0.3, Parent = etiquette})
	-- reflet haut de la pastille
	creer("Frame", {Position = UDim2.fromScale(0.06, 0.1), Size = UDim2.fromScale(0.88, 0.38), BackgroundColor3 = BLANC, BackgroundTransparency = 0.82,
		BorderSizePixel = 0, ZIndex = 24, Parent = pastille}, {coin(0.5)})
	-- halo de survol autour de la pastille
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 10, 1, 10),
		BackgroundTransparency = 1, ZIndex = 23, Parent = pastille}, {coin(0.5)})
	local traitHalo = trait(CRISTAL, 2.5, 1)
	traitHalo.Parent = halo
	-- invitation envoyée : arc lumineux qui tourne autour de la pastille
	local attenteP = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 8, 1, 8),
		BackgroundTransparency = 1, Visible = false, ZIndex = 24, Parent = pastille}, {coin(0.5)})
	local traitAttenteP = trait(CRISTAL, 2.5)
	traitAttenteP.Parent = attenteP
	local gAttenteP = creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = traitAttenteP})
	TweenService:Create(gAttenteP, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}):Play()
	UI.reactif(b, 1.03)
	local r: Rangee = {bouton = b, sous = sous, bord = bord, pastille = pastille, etiquette = etiquette, attente = attenteP, survol = false}
	b.MouseEnter:Connect(function()
		r.survol = true
		if b.Active then
			TweenService:Create(traitHalo, SURVOL, {Transparency = 0.1}):Play()
			TweenService:Create(bord, SURVOL, {Color = CRISTAL, Thickness = 3}):Play()
			TweenService:Create(UI.echelle(pastille), SURVOL, {Scale = 1.08}):Play()
		end
	end)
	b.MouseLeave:Connect(function()
		r.survol = false
		local ami = cacheAmis[userId] == true
		TweenService:Create(traitHalo, SURVOL, {Transparency = 1}):Play()
		TweenService:Create(bord, SURVOL, {Color = if ami then T.OrFonce else T.FerSombre, Thickness = 2}):Play()
		TweenService:Create(UI.echelle(pastille), SURVOL, {Scale = 1}):Play()
	end)
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
		TweenService:Create(traitHalo, FAST, {Transparency = 1}):Play()
		local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 0.2, ZIndex = 26,
			Parent = pastille}, {coin(0.5)})
		TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		Debris:AddItem(flash, 0.5)
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
		UI.pop(rondChef.cercle, 0.75) -- c'est le chef (couronne) qui choisit
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
local jetonOuverture = 0
local function ouvrirFenetre()
	if ouverte then
		return
	end
	ouverte = true
	Curseur.liberer("Grottes", true)
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
	fondreDecor(true, UI.DOUX)
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
		-- les minerais tombent dans leur pile l'un après l'autre
		for _, p in l.pastilles do
			p.survol = false
			p.cadre.ZIndex = 20 - p.k
			p.cadre.Position = placePastille(p, PAS_SERRE)
			local vue = Icones.vue(p.vp)
			if vue then
				vue.vitesse = 0
			end
			p.echelle.Scale = 0
			TweenService:Create(p.echelle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.3 + i * 0.06 + p.k * 0.07),
				{Scale = 1}):Play()
		end
		l.bulle.Visible = false
	end
	majDecouvertes() -- après la cascade : l'éclat d'un minerai découvert n'est pas écrasé par le tween d'ouverture
	majBarres(true)
	jetonOuverture += 1
	local jeton = jetonOuverture
	task.spawn(function()
		while ouverte and jeton == jetonOuverture do -- fermer / rouvrir vite : l'ancienne boucle s'arrête
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
	Curseur.liberer("Grottes", false)
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
	fondreDecor(false, FAST)
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
	-- largeur totale = fenêtre + panneau Groupe collé à droite : l'ensemble est centré et rétréci s'il manque de place
	local largeurTotale = LARGEUR + ECART_PANNEAU + L_PANNEAU
	local e = math.clamp(math.min(vp.X / (largeurTotale + 40), vp.Y / (HAUTEUR + 30)), 0.35, 1.35)
	echelleEcran.Scale = e
	racine.Position = UDim2.new(0.5, -(ECART_PANNEAU + L_PANNEAU) / 2 * e, 0.5, 0)
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
