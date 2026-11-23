-- Enclume des Maîtres · Casque du Cœur Magmatique · SCRIPT CLIENT
-- Grotte −200 m (la Fonderie) : interface de l'enclume (3 ronds de reliques, aperçu 3D du casque, fiche, bouton Forger)
-- et petite notification quand on ramasse une relique. Le serveur (CasqueMagma.server.lua) fait foi ; ici on affiche.
-- Contrat du RemoteEvent : voir ReplicatedStorage › Partage › CasqueMagma.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local CasqueMagma = require(Partage:WaitForChild("CasqueMagma"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))
local LogosReliques = require(script.Parent:WaitForChild("LogosReliques"))
local CinematiqueCasqueMagma = require(script.Parent:WaitForChild("CinematiqueCasqueMagma"))
local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild(CasqueMagma.REMOTE) :: RemoteEvent

-- Palette « forge volcanique »
local OBSIDIENNE = Color3.fromRGB(16, 11, 14)
local OBSIDIENNE_CLAIRE = Color3.fromRGB(38, 26, 32)
local MAGMA = Color3.fromRGB(255, 110, 30)
local MAGMA_VIF = Color3.fromRGB(255, 176, 70)
local CENDRE = Color3.fromRGB(118, 108, 112)
local CASQUE = CasqueMagma.CASQUE
local RELIQUES = CasqueMagma.RELIQUES

local boucles: {Tween} = {} -- animations en boucle : jouées seulement quand l'interface est ouverte

-- ================= ScreenGui =================
local gui = creer("ScreenGui", {Name = "EnclumeMagma", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 31,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})

local scene = creer("Frame", {Name = "Scene", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui})
local voile = creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 3, 2),
	BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Parent = scene},
	{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0.05)})})})

local racine = creer("Frame", {Name = "Enclume", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.94, 0.9), BackgroundColor3 = OBSIDIENNE, Active = true, ZIndex = 2, Parent = scene},
	{coin(0.035), creer("UIAspectRatioConstraint", {AspectRatio = 1.32}), creer("UISizeConstraint", {MaxSize = Vector2.new(860, 652)}),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 130, 150)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 120))})})})
local echelle = UI.echelle(racine)
-- Bordure magma : dégradé qui tourne autour du cadre
local bord = creer("UIStroke", {Thickness = 3.5, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = racine})
local gBord = creer("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 10)),
	ColorSequenceKeypoint.new(0.25, MAGMA_VIF), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 30, 10)),
	ColorSequenceKeypoint.new(0.75, MAGMA), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 10))}), Parent = bord})
UI.boucle(gBord, TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
-- Liseré intérieur sombre
creer("Frame", {Name = "Interieur", Position = UDim2.fromScale(0.012, 0.016), Size = UDim2.fromScale(0.976, 0.968), BackgroundTransparency = 1,
	ZIndex = 2, Parent = racine}, {coin(0.03), trait(Color3.fromRGB(60, 22, 12), 2, 0.2)})

-- Fond : fissures de lave + lueur de coulée en bas (clippé par un CanvasGroup arrondi)
local fond = creer("CanvasGroup", {Name = "Fond", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = racine}, {coin(0.035)})
local rng = Random.new(7)
for _ = 1, 9 do
	local x, y = rng:NextNumber(0, 1), rng:NextNumber(0.1, 1)
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(rng:NextNumber(0.12, 0.3), 0.004),
		Rotation = rng:NextNumber(-50, 50), BackgroundColor3 = MAGMA, BackgroundTransparency = rng:NextNumber(0.6, 0.82), BorderSizePixel = 0,
		Parent = fond}, {creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})})
end
local coulee = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.4),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = fond})
local gCoulee = creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(MAGMA, Color3.fromRGB(255, 50, 10)),
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 0.55)}),
	Parent = coulee})
UI.boucle(gCoulee, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.12)}, boucles)

-- ================= En-tête =================
local titre = texte({Text = "ENCLUME DES MAÎTRES", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.035), Size = UDim2.fromScale(0.7, 0.085), ZIndex = 5, Parent = racine}, 52)
UI.dore(titre, 2.5)
texte({Text = CASQUE.nom, Font = Enum.Font.GothamBlack, TextColor3 = MAGMA, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.6, 0.045), ZIndex = 5, Parent = racine}, 22)
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.175), Size = UDim2.new(0.6, 0, 0, 2),
	BackgroundColor3 = MAGMA, BorderSizePixel = 0, ZIndex = 5, Parent = racine}, {creer("UIGradient", {Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})})

-- Bouton fermer : croix en deux barres (aucun glyphe de police)
local fermer = creer("TextButton", {Name = "Fermer", Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.975, 0.03),
	Size = UDim2.fromScale(0.085, 0.085), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(150, 44, 24),
	AutoButtonColor = false, Selectable = true, ZIndex = 6, Parent = racine}, {coin(0.5), trait(Color3.fromRGB(60, 16, 8), 3),
	UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))})
local barres = {}
for _, angle in {45, -45} do
	table.insert(barres, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.56, 0.13),
		Rotation = angle, BackgroundColor3 = T.Parchemin, BorderSizePixel = 0, ZIndex = 7, Parent = fermer}, {coin(0.5)}))
end
UI.reactif(fermer, 1.1)
fermer.MouseEnter:Connect(function()
	TweenService:Create(barres[1], UI.FAST, {Rotation = 135}):Play()
	TweenService:Create(barres[2], UI.FAST, {Rotation = 45}):Play()
end)
fermer.MouseLeave:Connect(function()
	TweenService:Create(barres[1], UI.FAST, {Rotation = 45}):Play()
	TweenService:Create(barres[2], UI.FAST, {Rotation = -45}):Play()
end)

-- ================= Icônes des reliques (dessinées en Frames, pas d'emoji) =================
local NOIR = Color3.fromRGB(20, 10, 8)
local function iconeRelique(parent: GuiObject, id: string, _couleur: Color3)
	-- logo de la relique (médaillon dessiné par LogosReliques) ; la palpitation du cœur suit les boucles de l'interface
	local zone = LogosReliques.creer(id, parent, boucles)
	zone.Name = "Icone"
	zone.Size = UDim2.fromScale(0.9, 0.9)
	return zone
end

-- ================= 3 ronds de reliques =================
local X_RONDS = {0.24, 0.5, 0.76}
local Y_RONDS = 0.335
local TAILLE_ROND = 0.17 -- en largeur de racine (RelativeXX)

type Rond = {halo: Frame, rond: Frame, trait: UIStroke, points: Frame, inconnu: TextLabel, icone: Frame, nom: TextLabel, etat: string?}
local ronds: {Rond} = {}
for i, r in RELIQUES do
	local x = X_RONDS[i]
	local halo = creer("Frame", {Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, Y_RONDS),
		Size = UDim2.fromScale(TAILLE_ROND * 1.45, TAILLE_ROND * 1.45), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = r.couleur, Visible = false, ZIndex = 4, Parent = racine}, {coin(0.5),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1)})})})
	UI.boucle(halo, TweenInfo.new(1.1 + i * 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Size = UDim2.fromScale(TAILLE_ROND * 1.7, TAILLE_ROND * 1.7), BackgroundTransparency = 0.45}, boucles)
	local rond = creer("Frame", {Name = "Rond" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, Y_RONDS),
		Size = UDim2.fromScale(TAILLE_ROND, TAILLE_ROND), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = OBSIDIENNE_CLAIRE, ZIndex = 5, Parent = racine}, {coin(1)})
	creer("UIGradient", {Name = "Relief", Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(110, 100, 100)), Parent = rond})
	local tr = trait(CENDRE, 2, 0.5)
	tr.Parent = rond
	-- contour en pointillé (emplacement vide) : 20 petits points autour du cercle
	local points = creer("Frame", {Name = "Pointilles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Parent = rond})
	for k = 0, 19 do
		local a = k / 20 * math.pi * 2
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.43, 0.5 + math.sin(a) * 0.43),
			Size = UDim2.fromScale(0.055, 0.055), BackgroundColor3 = CENDRE, BackgroundTransparency = 0.25, BorderSizePixel = 0,
			ZIndex = 6, Parent = points}, {coin(1)})
	end
	local inconnu = texte({Text = "?", Font = Enum.Font.Fantasy, TextColor3 = CENDRE, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), ZIndex = 7, Parent = rond}, 60)
	local icone = iconeRelique(rond, r.id, r.couleur)
	-- reflet en haut du rond
	creer("Frame", {Name = "Reflet", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.08), Size = UDim2.fromScale(0.6, 0.22),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 9, Parent = rond}, {coin(1)})
	local nom = texte({Text = r.nom, Font = Enum.Font.GothamBlack, TextColor3 = CENDRE, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(x, Y_RONDS + TAILLE_ROND * 1.32 * 0.5 + 0.035), Size = UDim2.fromScale(0.23, 0.04), ZIndex = 5, Parent = racine}, 18)
	ronds[i] = {halo = halo, rond = rond, trait = tr, points = points, inconnu = inconnu, icone = icone, nom = nom}
end
-- Fils de magma qui relient les ronds (s'allument quand les deux voisins sont là)
local liens: {Frame} = {}
for i = 1, 2 do
	local x0, x1 = X_RONDS[i], X_RONDS[i + 1]
	liens[i] = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((x0 + x1) / 2, Y_RONDS),
		Size = UDim2.new(x1 - x0 - TAILLE_ROND, -6, 0, 4), BackgroundColor3 = CENDRE, BackgroundTransparency = 0.6, BorderSizePixel = 0,
		ZIndex = 4, Parent = racine}, {coin(1)})
end

-- ================= Aperçu du casque + fiche =================
local Y_BAS = 0.545
local cadreVP = creer("Frame", {Name = "Apercu", Position = UDim2.fromScale(0.05, Y_BAS), Size = UDim2.fromScale(0.4, 0.28),
	BackgroundColor3 = Color3.fromRGB(26, 14, 12), ZIndex = 4, Parent = racine}, {coin(0.08), trait(Color3.fromRGB(110, 44, 16), 2.5),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 100, 110), Color3.fromRGB(255, 160, 110))})})
local socle = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.6, 0.12),
	BackgroundColor3 = MAGMA, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 4, Parent = cadreVP}, {coin(1),
	creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1)})})})
UI.boucle(socle, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.65}, boucles)
local vp = creer("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(150, 110, 100),
	LightColor = Color3.fromRGB(255, 200, 150), LightDirection = Vector3.new(-0.5, -1, 0.6), ZIndex = 5, Parent = cadreVP}, {coin(0.08)})
local camVP = creer("Camera", {FieldOfView = 30, Parent = vp})
vp.CurrentCamera = camVP

-- Silhouette de secours (si le modèle 3D n'existe pas encore) : dôme + visière + crête
local silhouette = creer("Frame", {Name = "Silhouette", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47),
	Size = UDim2.fromScale(0.42, 0.42), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 6, Parent = cadreVP})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.9, 0.9),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6, Parent = silhouette}, {coin(1), trait(NOIR, 3),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, MAGMA_VIF),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 40, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 10))})})})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.62, 0.12),
	BackgroundColor3 = Color3.fromRGB(255, 140, 40), ZIndex = 7, Parent = silhouette}, {coin(0.5), trait(NOIR, 2)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.14, 0.3),
	BackgroundColor3 = MAGMA, ZIndex = 5, Parent = silhouette}, {coin(0.4), trait(NOIR, 2)})

local etiquetteVP = texte({Text = "APERÇU", Font = Enum.Font.GothamBlack, TextColor3 = CENDRE, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.5, 0.09), ZIndex = 8, Parent = cadreVP}, 14)

local modele: Model? = nil
local modeleTente = false
local function chargerModele()
	if modeleTente then
		return
	end
	modeleTente = true
	task.spawn(function()
		local ok, res = pcall(function()
			local AV = require(Partage:WaitForChild("ArmuresVoxels"))
			if not AV.existe(CasqueMagma.MODELE) then
				return nil
			end
			return AV.construire(CasqueMagma.MODELE)
		end)
		if not ok or typeof(res) ~= "Instance" or not res:IsA("Model") then
			return -- pas de modèle : la silhouette reste
		end
		local m = res :: Model
		m:PivotTo(CFrame.identity)
		local cf, taille = m:GetBoundingBox()
		local rayon = taille.Magnitude * 0.5
		local dist = rayon / math.tan(math.rad(camVP.FieldOfView * 0.5)) * 1.08
		local centre = cf.Position
		-- devant du casque = -Z : la caméra regarde depuis -Z, un peu au-dessus
		camVP.CFrame = CFrame.lookAt(centre + Vector3.new(0, rayon * 0.35, -dist), centre)
		m.Parent = vp
		modele = m
		silhouette.Visible = false
	end)
end

-- Fiche du casque
local fiche = creer("Frame", {Name = "Fiche", Position = UDim2.fromScale(0.5, Y_BAS), Size = UDim2.fromScale(0.45, 0.28),
	BackgroundColor3 = OBSIDIENNE_CLAIRE, ZIndex = 4, Parent = racine}, {coin(0.08), trait(Color3.fromRGB(110, 44, 16), 2.5),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 230, 220), Color3.fromRGB(140, 110, 110))})})
texte({Text = CASQUE.nom, Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.06, 0.06),
	Size = UDim2.fromScale(0.62, 0.17), ZIndex = 5, Parent = fiche}, 26)
local badge = creer("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.95, 0.07), Size = UDim2.fromScale(0.26, 0.15),
	BackgroundColor3 = CASQUE.couleur, ZIndex = 5, Parent = fiche}, {coin(0.5), trait(NOIR, 2),
	UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(170, 120, 110))})
texte({Text = string.upper(CASQUE.rarete), Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.66), ZIndex = 6, Parent = badge}, 16)
UI.rarete(badge, MAGMA_VIF, 4, boucles)
local STATS = {
	{"Défense", "+" .. CASQUE.defense, Color3.fromRGB(150, 196, 255)},
	{"Vie maximale", "+" .. CASQUE.vie, Color3.fromRGB(120, 230, 120)},
	{"Résistance au feu", "+" .. math.floor(CASQUE.resistanceFeu * 100 + 0.5) .. " %", MAGMA_VIF},
}
for k, s in STATS do
	local y = 0.3 + (k - 1) * 0.2
	creer("Frame", {Position = UDim2.fromScale(0.06, y), Size = UDim2.fromScale(0.88, 0.16), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 5, Parent = fiche}, {coin(0.3)})
	creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.085, y + 0.08), Size = UDim2.fromScale(0.07, 0.07),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = s[3], ZIndex = 6, Parent = fiche}, {trait(NOIR, 1.5)})
	texte({Text = s[1], Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.16, y + 0.025), Size = UDim2.fromScale(0.5, 0.11), ZIndex = 6, Parent = fiche}, 18)
	texte({Text = s[2], Font = Enum.Font.GothamBlack, TextColor3 = s[3], TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.62, y + 0.02), Size = UDim2.fromScale(0.29, 0.12), ZIndex = 6, Parent = fiche}, 20)
end

-- ================= Statut, message, bouton Forger =================
local statut = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.835), Size = UDim2.fromScale(0.86, 0.04), ZIndex = 5, Parent = racine}, 18)
local message = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Rouge, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.835), Size = UDim2.fromScale(0.86, 0.04), TextTransparency = 1, ZIndex = 6, Parent = racine}, 18)
local bouton = UI.boutonPrincipal({Name = "Forger", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.885),
	Size = UDim2.fromScale(0.36, 0.085), BackgroundColor3 = MAGMA, Selectable = true, ZIndex = 5, Parent = racine}, boucles)

-- ================= État =================
local ouverte = false
local forgeEnCours = false
local animationForge = false

local function lireEtat()
	return CasqueMagma.lire(joueur:GetAttribute("FragmentsCarte"))
end

local function majRond(i: number, present: boolean, forge: boolean)
	local r = RELIQUES[i]
	local o = ronds[i]
	local etat = if forge and present then "fondu" elseif present then "plein" else "vide"
	if o.etat == etat then
		return
	end
	local avant = o.etat
	o.etat = etat
	local plein = etat ~= "vide"
	o.points.Visible = not plein
	o.inconnu.Visible = not plein
	o.icone.Visible = plein
	o.halo.Visible = etat == "plein"
	o.rond.BackgroundColor3 = if plein then r.couleur else OBSIDIENNE_CLAIRE
	o.rond.BackgroundTransparency = if etat == "fondu" then 0.55 else 0
	o.trait.Color = if plein then r.couleur:Lerp(Color3.new(1, 1, 1), 0.45) else CENDRE
	o.trait.Thickness = if plein then 3.5 else 2
	o.trait.Transparency = if etat == "plein" then 0 elseif etat == "fondu" then 0.5 else 0.5
	o.nom.TextColor3 = if etat == "plein" then r.couleur:Lerp(Color3.new(1, 1, 1), 0.35) elseif etat == "fondu" then CENDRE else Color3.fromRGB(80, 72, 76)
	if avant == "vide" and etat == "plein" and ouverte then
		UI.pop(o.rond, 0.5)
		UI.jouer("succes", 1.15)
	end
end

local function majTout()
	local trouves, forge = lireEtat()
	local n = 0
	for i, r in RELIQUES do
		local p = trouves[r.id] == true
		if p then
			n += 1
		end
		majRond(i, p, forge)
	end
	for i, l in liens do
		local actif = trouves[RELIQUES[i].id] and trouves[RELIQUES[i + 1].id] and not forge
		l.BackgroundColor3 = if actif then MAGMA else CENDRE
		l.BackgroundTransparency = if actif then 0.1 else 0.6
	end
	if modele then
		vp.ImageTransparency = if forge then 0 else 0.25
	end
	etiquetteVP.Text = if forge then "FORGÉ" else "APERÇU"
	etiquetteVP.TextColor3 = if forge then MAGMA_VIF else CENDRE
	if animationForge then
		return
	end
	if forge then
		statut.Text = "Déjà forgé — un seul par aventurier"
		statut.TextColor3 = MAGMA_VIF
		bouton.definir("DÉJÀ FORGÉ", MAGMA, false)
	elseif forgeEnCours then
		statut.Text = "Les reliques fondent dans l'enclume…"
		statut.TextColor3 = MAGMA_VIF
		bouton.definir("FORGE EN COURS…", MAGMA, false)
	elseif n >= #RELIQUES then
		statut.Text = "Les 3 reliques sont réunies : l'enclume t'attend !"
		statut.TextColor3 = T.Vert
		bouton.definir("FORGER", MAGMA, true)
	else
		statut.Text = "Trouve les 3 reliques cachées dans la Fonderie (" .. n .. "/" .. #RELIQUES .. ")"
		statut.TextColor3 = T.Parchemin
		bouton.definir("FORGER", MAGMA, false)
	end
end
joueur:GetAttributeChangedSignal("FragmentsCarte"):Connect(majTout)

-- Message (rouge = erreur) qui s'efface tout seul
local idMessage = 0
local function afficherMessage(txt: string, ok: boolean)
	idMessage += 1
	local moi = idMessage
	message.Text = txt
	message.TextColor3 = if ok then T.Vert else T.Rouge
	message.TextTransparency = 0
	statut.TextTransparency = 1
	UI.pop(message, 0.7)
	task.delay(3.5, function()
		if moi == idMessage then
			TweenService:Create(message, UI.FAST, {TextTransparency = 1}):Play()
			TweenService:Create(statut, UI.FAST, {TextTransparency = 0}):Play()
		end
	end)
end

-- ================= Ouvrir / fermer =================
local connexionRotation: RBXScriptConnection? = nil
local session = 0

local function fermerInterface()
	if not ouverte then
		return
	end
	ouverte = false
	session += 1
	Curseur.liberer("EnclumeMagma", false)
	for _, t in boucles do
		t:Pause()
	end
	if connexionRotation then
		connexionRotation:Disconnect()
		connexionRotation = nil
	end
	local sel = GuiService.SelectedObject
	if sel and sel:IsDescendantOf(gui) then
		GuiService.SelectedObject = nil
	end
	UI.jouer("ouvrir", 1.3)
	TweenService:Create(echelle, UI.FAST, {Scale = 0.88}):Play()
	TweenService:Create(voile, UI.FAST, {BackgroundTransparency = 1}):Play()
	local maSession = session
	task.delay(0.16, function()
		if not ouverte and maSession == session then
			scene.Visible = false
		end
	end)
end

local function ouvrirInterface()
	chargerModele()
	majTout()
	if ouverte then
		return
	end
	ouverte = true
	session += 1
	local maSession = session
	Curseur.liberer("EnclumeMagma", true)
	scene.Visible = true
	for _, t in boucles do
		t:Play()
	end
	echelle.Scale = 0.8
	racine.Position = UDim2.fromScale(0.5, 0.56)
	voile.BackgroundTransparency = 1
	TweenService:Create(echelle, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(racine, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.2}):Play()
	UI.jouer("ouvrir")
	task.delay(0.12, UI.jouer, "metal", 0.8)
	-- ronds qui apparaissent l'un après l'autre
	for i, o in ronds do
		local e = UI.echelle(o.rond)
		e.Scale = 0.3
		TweenService:Create(e, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.08 * i), {Scale = 1}):Play()
	end
	-- rotation lente du casque (seulement pendant que l'interface est ouverte)
	local angle = 0
	connexionRotation = RunService.RenderStepped:Connect(function(dt)
		angle += dt * 0.7
		local m = modele
		if m then
			m:PivotTo(CFrame.Angles(0, angle, 0))
		else
			silhouette.Rotation = math.sin(angle * 1.5) * 5
		end
	end)
	-- braises qui montent
	task.spawn(function()
		while ouverte and session == maSession do
			local t = 0.005 + math.random() * 0.008
			local x = math.random()
			local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.02), Size = UDim2.fromScale(t, t),
				SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, ZIndex = 3,
				BackgroundColor3 = Color3.fromRGB(255, 120 + math.random(0, 110), 30 + math.random(0, 50)), Parent = fond}, {coin(1)})
			local duree = 2 + math.random() * 2
			TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.12, 0.3 + math.random() * 0.45),
				BackgroundTransparency = 1, Size = UDim2.fromScale(t * 0.3, t * 0.3)}):Play()
			Debris:AddItem(b, duree)
			task.wait(0.08 + math.random() * 0.1)
		end
	end)
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = if bouton.bouton.Active then bouton.bouton else fermer
	end
end

fermer.Activated:Connect(function()
	UI.jouer("clic", 0.9)
	fermerInterface()
end)
UserInputService.InputBegan:Connect(function(input)
	if not ouverte or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		fermerInterface()
	end
end)
-- Fermeture à la mort et au respawn
local function suivrePerso(perso: Model)
	fermerInterface()
	local hum = perso:WaitForChild("Humanoid", 10)
	if hum and hum:IsA("Humanoid") then
		hum.Died:Connect(fermerInterface)
	end
end
if joueur.Character then
	task.spawn(suivrePerso, joueur.Character)
end
joueur.CharacterAdded:Connect(suivrePerso)

-- ================= Forger =================
bouton.bouton.Activated:Connect(function()
	if not bouton.bouton.Active or forgeEnCours or animationForge then
		return
	end
	local trouves, forge = lireEtat()
	for _, r in RELIQUES do
		if not trouves[r.id] then
			return
		end
	end
	if forge then
		return
	end
	forgeEnCours = true
	UI.jouer("metal")
	UI.secouer(bouton.bouton, 4)
	majTout()
	remote:FireServer("Forger")
	task.delay(5, function() -- sécurité : pas de réponse du serveur
		if forgeEnCours then
			forgeEnCours = false
			majTout()
		end
	end)
end)

-- Les 3 ronds fusionnent vers le casque : flash orange, secousse, tampon
local function animerFusion()
	animationForge = true
	statut.Text = "Les reliques fusionnent…"
	statut.TextColor3 = MAGMA_VIF
	bouton.definir("FORGE…", MAGMA, false)
	local cible = UDim2.fromScale(0.05 + 0.4 * 0.5, Y_BAS + 0.28 * 0.5)
	local fusion = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	for i, r in RELIQUES do
		local o = ronds[i]
		local copie = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = o.rond.Position, Size = o.rond.Size,
			SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = r.couleur, ZIndex = 30, Parent = racine},
			{coin(1), trait(MAGMA_VIF, 4), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 90, 70))})
		TweenService:Create(copie, fusion, {Position = cible, Size = UDim2.fromScale(0.03, 0.03), BackgroundColor3 = MAGMA_VIF}):Play()
		Debris:AddItem(copie, 0.75)
		TweenService:Create(o.rond, UI.FAST, {BackgroundTransparency = 0.7}):Play()
	end
	UI.jouer("ouvrir", 0.7)
	task.wait(0.7)
	-- impact
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = MAGMA, BackgroundTransparency = 0.05, BorderSizePixel = 0,
		ZIndex = 40, Parent = racine}, {coin(0.035)})
	TweenService:Create(flash, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flash, 0.75)
	UI.secouer(racine, 7)
	UI.jouer("metal", 0.7)
	task.delay(0.08, UI.jouer, "succes")
	UI.pop(cadreVP, 0.6)
	UI.gerbe(racine, MAGMA, 26, Vector2.new(cible.X.Scale, cible.Y.Scale))
	UI.tampon(racine, "CASQUE FORGÉ !", 0.33, 0.14)
	task.wait(0.9)
	animationForge = false
	for _, o in ronds do
		o.etat = nil -- force le redessin
	end
	majTout()
end

-- ================= Notification de relique (sans ouvrir l'interface) =================
local notif = creer("Frame", {Name = "Relique", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.2),
	Size = UDim2.fromScale(0.42, 0.11), BackgroundColor3 = OBSIDIENNE, Visible = false, ZIndex = 50, Parent = gui},
	{coin(0.2), creer("UISizeConstraint", {MinSize = Vector2.new(300, 70), MaxSize = Vector2.new(560, 96)}),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(200, 180, 190), Color3.fromRGB(255, 170, 120))})})
local notifTrait = trait(MAGMA, 2.5)
notifTrait.Parent = notif
local notifRond = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.025, 0.5), Size = UDim2.fromScale(0.78, 0.78),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = MAGMA, ZIndex = 51, Parent = notif}, {coin(1), trait(NOIR, 2),
	UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(140, 110, 100))})
local notifIcones: {[string]: Frame} = {}
for _, r in RELIQUES do
	local ic = iconeRelique(notifRond, r.id, r.couleur)
	ic.Position = UDim2.fromScale(0.5, 0.5)
	ic.Size = UDim2.fromScale(0.96, 0.96)
	ic.ZIndex = 52
	for _, d in ic:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex += 45
		end
	end
	ic.Visible = false
	notifIcones[r.id] = ic
end
local notifTitre = texte({Font = Enum.Font.GothamBlack, TextColor3 = MAGMA_VIF, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.new(0.19, 0, 0.12, 0), Size = UDim2.fromScale(0.78, 0.36), ZIndex = 51, Parent = notif}, 22)
local notifTexte = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true, Position = UDim2.new(0.19, 0, 0.5, 0), Size = UDim2.fromScale(0.78, 0.4), ZIndex = 51, Parent = notif}, 15)
local idNotif = 0
local function notifierRelique(id: string)
	local r = CasqueMagma.PAR_ID[id]
	if not r then
		return
	end
	idNotif += 1
	local moi = idNotif
	local trouves = lireEtat()
	trouves[id] = true
	local n = 0
	for _, x in RELIQUES do
		if trouves[x.id] then
			n += 1
		end
	end
	for k, ic in notifIcones do
		ic.Visible = k == id
	end
	notifRond.BackgroundColor3 = r.couleur
	notifTrait.Color = r.couleur:Lerp(MAGMA, 0.5)
	notifTitre.Text = "Relique trouvée : " .. r.nom .. " (" .. n .. "/" .. #RELIQUES .. ")"
	notifTexte.Text = "« " .. r.texte .. " »"
	notif.Visible = true
	notif.Position = UDim2.fromScale(0.5, -0.15)
	TweenService:Create(notif, UI.BOUNCY, {Position = UDim2.fromScale(0.5, 0.06)}):Play()
	UI.pop(notifRond, 0.4)
	UI.jouer("succes")
	task.delay(0.15, UI.jouer, "metal", 1.2)
	if n >= #RELIQUES then
		task.delay(0.6, function()
			if moi == idNotif then
				notifTexte.Text = "Les 3 reliques sont réunies : rapporte-les à l'Enclume des Maîtres !"
				UI.pop(notif, 0.9)
			end
		end)
	end
	task.delay(if n >= #RELIQUES then 7 else 5, function()
		if moi == idNotif then
			TweenService:Create(notif, UI.FAST, {Position = UDim2.fromScale(0.5, -0.15)}):Play()
			task.delay(0.16, function()
				if moi == idNotif then
					notif.Visible = false
				end
			end)
		end
	end)
end

-- ================= Messages du serveur =================
remote.OnClientEvent:Connect(function(action, donnees)
	donnees = if type(donnees) == "table" then donnees else {}
	if action == "Ouvrir" then
		ouvrirInterface()
	elseif action == "Relique" then
		local id = donnees.id or donnees[1]
		if type(id) == "string" then
			notifierRelique(id)
		end
	elseif action == "Forge" then
		forgeEnCours = false
		local msg = if type(donnees.message) == "string" then donnees.message else ""
		if donnees.ok == true then
			if CinematiqueCasqueMagma.jouer() then
				fermerInterface()
				majTout()
			elseif ouverte then
				task.spawn(function()
					animerFusion()
					if msg ~= "" then
						afficherMessage(msg, true)
					end
				end)
			else
				majTout()
			end
		else
			majTout()
			if ouverte then
				afficherMessage(if msg ~= "" then msg else "La forge a échoué.", false)
				UI.secouer(bouton.bouton, 6)
			end
		end
	end
end)

majTout()
