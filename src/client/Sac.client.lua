--!strict
-- Sac du mineur · SCRIPT CLIENT (bouton HUD + fenêtre d'inventaire)
-- Touche B (ou le bouton bourse) : ouvre / ferme. Gauche : ton personnage en 3D (glisse pour le tourner).
-- Droite : emplacements d'équipement, grille du sac (minerais + objets forgés NON équipés), détail de la case choisie.
-- L'état vient du serveur (SacEtat) ; équiper / retirer passe par SacAction : le client ne décide rien.
-- Thème / effets : InterfaceMine ; icônes 3D (minerais, pioches, épées, armures, bourse) : IconesObjets.
-- Perf : la grille est mise à jour par différence (cases créées / détruites / quantités), jamais reconstruite en entier.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Forge = require(Partage:WaitForChild("Forge"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local ArmesVoxels = require(Partage:WaitForChild("ArmesVoxels"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local evEtat = ReplicatedStorage:WaitForChild("SacEtat") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("SacAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Objet = {id: string, type: string, modele: string?, rang: number?, nom: string, couleur: string, stat: string, valeur: number, composition: {{any}}}
type Etat = {minerais: {[string]: number}, objets: {Objet}, equipement: {[string]: string}}

local T = UI.T
local creer, coin, trait, texte, jouer, pop = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop
local FAST, BOUNCY = UI.FAST, UI.BOUNCY
local TOUCHE = Enum.KeyCode.B
local COLONNES = 7
local EPEE_3D = "EpeeFer"
local ACIER = Color3.fromRGB(168, 174, 186)
local LANTERNE = Color3.fromRGB(255, 170, 70)
local BLANC = Color3.new(1, 1, 1)
local NOIR = Color3.new(0, 0, 0)
local ARMURES = {Casque = true, Plastron = true, Jambieres = true}
-- Emplacements d'équipement : id du type forgé, ou "Pioche" / "Libre"
local EMPLACEMENTS = {
	{id = "Pioche", nom = "Pioche"},
	{id = "Epee", nom = "Épée"},
	{id = "Libre", nom = "Bientôt"},
	{id = "Casque", nom = "Casque"},
	{id = "Plastron", nom = "Plastron"},
	{id = "Jambieres", nom = "Jambières"},
}

local PUISSANCE_MAX, FORCE_MAX = 1, 1
for _, p in Pioches.LISTE do
	PUISSANCE_MAX = math.max(PUISSANCE_MAX, p.puissance)
end
for _, m in Forge.MINERAIS do
	FORCE_MAX = math.max(FORCE_MAX, m.force)
end

-- ================= Petits outils =================
local function couleurHex(hex: any): Color3
	local ok, c = pcall(Color3.fromHex, hex)
	return if ok then c else T.Gris
end

-- Teinte arrondie (moins de variantes de modèles en cache)
local function arrondir(c: Color3): Color3
	local function q(x: number)
		return math.floor(x * 255 / 12 + 0.5) * 12
	end
	return Color3.fromRGB(math.min(255, q(c.R)), math.min(255, q(c.G)), math.min(255, q(c.B)))
end

local function rarete(nom: any): (string, Color3, number)
	local r = if type(nom) == "string" and UI.NIVEAUX[nom] then nom else "Commun"
	return r, Pioches.RARETES[r] or T.Gris, UI.NIVEAUX[r] or 1
end

local function rareteMinerai(id: string): (string, Color3, number)
	local v = MineraisModeles.VISUEL[id]
	return rarete(v and v.rarete)
end

-- Rareté d'un objet forgé = celle de son rang (échelle de la forge), sinon de son minerai le plus rare
local function rareteObjet(o: Objet): (string, Color3, number)
	local echelle = Forge.ECHELLES[o.type]
	local palier = echelle and o.rang and echelle[o.rang]
	if palier then
		return rarete(palier.rarete)
	end
	local meilleur, n = nil, 0
	for _, e in o.composition do
		local v = MineraisModeles.VISUEL[e[1]]
		local k = v and UI.NIVEAUX[v.rarete] or 0
		if k > n then
			meilleur, n = v.rarete, k
		end
	end
	return rarete(meilleur)
end

local function statMax(typeId: string): number
	local t, echelle = Forge.TYPES[typeId], Forge.ECHELLES[typeId]
	if echelle then
		return math.floor(echelle[#echelle].base * Forge.FACTEUR_MAX)
	end
	return if t then math.max(1, math.floor(FORCE_MAX * 1.6 * t.mult * math.sqrt(t.max / t.min) + 0.5)) else 1
end

-- Vrai modèle 3D d'un objet forgé : épée / pièce d'armure teintée à la couleur de l'alliage (lingot en dernier recours)
local function iconeObjet(vp: ViewportFrame, typeId: string, couleur: Color3, options: {[string]: any}?, modele: string?)
	local o: any = table.clone(options or {})
	o.teinte = if o.silhouette then nil else arrondir(couleur)
	o.marge = o.marge or 0.85
	if typeId == "Epee" and modele and ArmesVoxels.existe(modele) then
		o.teinte = nil -- épée dédiée : ses propres couleurs
		o.hauteur = o.hauteur or 0.1
		Icones.definir(vp, "epee", modele, o)
	elseif typeId == "Epee" and ArmesVoxels.existe(EPEE_3D) then
		o.hauteur = o.hauteur or 0.1
		Icones.definir(vp, "epee", EPEE_3D, o)
	elseif ARMURES[typeId] then
		o.hauteur = o.hauteur or 0.2
		o.angle = o.angle or 0.45
		Icones.definir(vp, "armure", modele or typeId, o)
	else
		o.hauteur = o.hauteur or 0.45
		Icones.definir(vp, "lingot", arrondir(couleur):ToHex(), o)
	end
end

local function tournerAuSurvol(b: GuiButton, vp: ViewportFrame, vite: number, repos: number)
	b.MouseEnter:Connect(function()
		local v = Icones.vue(vp)
		if v then
			v.vitesse = vite
		end
	end)
	b.MouseLeave:Connect(function()
		local v = Icones.vue(vp)
		if v then
			v.vitesse = repos
		end
	end)
end

-- Titre de section : ◆ TITRE ─────── compteur
local function section(parent: Instance, titre: string, y: number): TextLabel
	local l = texte({Text = "◆  " .. titre, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(0.5, 0.045), ZIndex = 3, Parent = parent}, 15)
	creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(30, 16, 8), Transparency = 0.2, Parent = l})
	creer("Frame", {Position = UDim2.new(0, 0, y + 0.05, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.OrFonce, BorderSizePixel = 0,
		ZIndex = 3, Parent = parent}, {creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1)})})})
	return texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, y + 0.005), Size = UDim2.fromScale(0.45, 0.04), ZIndex = 3, Parent = parent}, 14)
end

local playerGui = joueur:WaitForChild("PlayerGui")

-- ================= Bouton HUD : bourse 3D dans un médaillon de fer riveté =================
local hud = creer("ScreenGui", {Name = "SacHUD", ResetOnSpawn = false, DisplayOrder = 2, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui})
local socle = creer("Frame", {Name = "Sac", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.55, 0),
	Size = UDim2.fromScale(0.12, 0.12), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, Parent = hud},
	{creer("UIAspectRatioConstraint", {AspectRatio = 1}), creer("UISizeConstraint", {MinSize = Vector2.new(58, 58), MaxSize = Vector2.new(96, 96)})})
-- lueur chaude qui respire derrière le médaillon
for k, s in {1.45, 1.2} do
	local h = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s),
		BackgroundColor3 = T.Braise, BackgroundTransparency = if k == 1 then 0.88 else 0.8, Parent = socle}, {coin(0.5)})
	TweenService:Create(h, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, k * 0.3),
		{BackgroundTransparency = if k == 1 then 0.96 else 0.9}):Play()
end
local boutonSac = creer("TextButton", {Name = "Bouton", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = T.Fer, ZIndex = 2, Parent = socle}, {coin(0.5), trait(T.FerSombre, 2.5),
	creer("UIGradient", {Rotation = 50, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 236, 244)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 140, 150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(66, 66, 74))})})})
local disque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.76, 0.76),
	BackgroundColor3 = T.BoisSombre, Parent = boutonSac}, {coin(0.5), trait(Color3.fromRGB(14, 8, 4), 2),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 120, 100), Color3.fromRGB(255, 200, 150))})})
local foyer = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.97), Size = UDim2.fromScale(0.86, 0.5),
	BackgroundColor3 = LANTERNE, BackgroundTransparency = 0.7, Parent = disque}, {coin(0.5)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.84), Size = UDim2.fromScale(0.56, 0.12),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.55, Parent = disque}, {coin(0.5)}) -- ombre portée de la bourse
for i = 0, 7 do
	local a = i / 8 * math.pi * 2 + math.pi / 8
	UI.rivet(boutonSac, UDim2.fromScale(0.5 + math.cos(a) * 0.44, 0.5 + math.sin(a) * 0.44), 0.075)
end
-- Pivot en haut de la bourse (la rotation d'un GuiObject se fait autour de son centre : la bourse occupe la moitié basse)
local pivotBourse = creer("Frame", {Name = "Pivot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.1),
	Size = UDim2.fromScale(0.84, 1.6), BackgroundTransparency = 1, ZIndex = 3, Parent = boutonSac})
local vpBourse = Icones.bourse(pivotBourse, {vitesse = 0, angle = 0.4, hauteur = 0.32, marge = 0.7})
vpBourse.Position, vpBourse.Size, vpBourse.ZIndex = UDim2.fromScale(0, 0.5), UDim2.fromScale(1, 0.5), 3
vpBourse.Ambient = Color3.fromRGB(150, 122, 100)
local plaque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.74, 0.25),
	BackgroundColor3 = T.Bois, ZIndex = 7, Parent = socle}, {coin(0.35), trait(T.OrFonce, 1.5),
	UI.degrade(Color3.fromRGB(255, 235, 210), Color3.fromRGB(140, 110, 90))})
UI.dore(texte({Text = "SAC", Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.9, 0.84), ZIndex = 8,
	Parent = plaque}, 18), 1.5)
local toucheSac = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.12, 0.12), Size = UDim2.fromScale(0.3, 0.3),
	BackgroundColor3 = T.FerSombre, ZIndex = 8, Parent = socle}, {coin(0.5), trait(T.OrFonce, 1.5)})
texte({Text = TOUCHE.Name, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, Position = UDim2.fromScale(0.18, 0.18),
	Size = UDim2.fromScale(0.64, 0.64), ZIndex = 9, Parent = toucheSac}, 16)
toucheSac.Visible = not UserInputService.TouchEnabled
-- Pastille « nouveaux minerais » (discrète, apparaît quand le sac est fermé)
local badge = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.88, 0.13), Size = UDim2.fromScale(0.4, 0.28),
	BackgroundColor3 = T.Braise, Visible = false, ZIndex = 9, Parent = socle}, {coin(0.5), trait(Color3.fromRGB(60, 20, 8), 1.5),
	UI.degrade(Color3.fromRGB(255, 236, 190), Color3.fromRGB(210, 96, 40))})
local texteBadge = texte({Font = Enum.Font.GothamBlack, TextColor3 = BLANC, Position = UDim2.fromScale(0.08, 0.12), Size = UDim2.fromScale(0.84, 0.76),
	ZIndex = 10, Parent = badge}, 14)
creer("UIStroke", {Thickness = 1.2, Color = Color3.fromRGB(70, 24, 6), Parent = texteBadge})

local balancement: Tween? = nil
local function balancer(actif: boolean)
	if balancement then
		balancement:Cancel()
	end
	local t
	if actif then
		pivotBourse.Rotation = -8
		t = TweenService:Create(pivotBourse, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 8})
	else
		t = TweenService:Create(pivotBourse, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = 0})
	end
	balancement = t
	t:Play()
end
-- Tour complet de la bourse 3D (finit toujours de trois-quarts)
local ANGLE_BOURSE = 0.4
local angleBourse = creer("NumberValue", {Value = ANGLE_BOURSE}) :: NumberValue
angleBourse.Changed:Connect(function(a)
	local v = Icones.vue(vpBourse)
	if v then
		v.angle = a
		Icones.placer(vpBourse)
	end
end)
local tweenTour: Tween? = nil
local function tourBourse(duree: number)
	if tweenTour then
		tweenTour:Cancel()
	end
	angleBourse.Value = (angleBourse.Value - ANGLE_BOURSE) % (math.pi * 2) + ANGLE_BOURSE
	local t = TweenService:Create(angleBourse, TweenInfo.new(duree, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Value = ANGLE_BOURSE + math.pi * 2})
	tweenTour = t
	t:Play()
end
UI.reactif(boutonSac, 1.08, socle)
boutonSac.MouseEnter:Connect(function()
	balancer(true)
	tourBourse(1)
	TweenService:Create(foyer, FAST, {BackgroundTransparency = 0.45}):Play()
end)
boutonSac.MouseLeave:Connect(function()
	balancer(false)
	TweenService:Create(foyer, FAST, {BackgroundTransparency = 0.7}):Play()
end)

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "Sac", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local boucles: {Tween} = {}
local voile = creer("TextButton", {Name = "Voile", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = T.Voile, BackgroundTransparency = 1, Parent = gui},
	{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0.1)})})})
local fenetre = creer("Frame", {Name = "Fenetre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.95, 0.88), BackgroundTransparency = 1, Active = true, Parent = gui},
	{creer("UIAspectRatioConstraint", {AspectRatio = 1.62}), creer("UISizeConstraint", {MaxSize = Vector2.new(1000, 617)})})
local echelleFenetre = UI.echelle(fenetre)

-- Cadre : planches de bois sombre, équerres et rivets de fer
do
	local grain = {}
	for i = 0, 10 do
		local v = if i % 2 == 0 then 255 - (i * 7) % 30 else 196 + (i * 13) % 26
		table.insert(grain, ColorSequenceKeypoint.new(i / 10, Color3.fromRGB(v, v * 0.97, v * 0.94)))
	end
	creer("Frame", {Name = "Cadre", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bois, Parent = fenetre},
		{coin(0.03), trait(Color3.fromRGB(18, 10, 6), 4), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(grain)})})
	for _, c in {Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1)} do
		local eq = creer("Frame", {AnchorPoint = c, Position = UDim2.fromScale(c.X, c.Y), Size = UDim2.fromScale(0.08, 0.08),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fer, ZIndex = 4, Parent = fenetre},
			{coin(0.18), trait(T.FerSombre, 2), creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(220, 220, 228), Color3.fromRGB(80, 80, 88))})})
		UI.rivet(eq, UDim2.fromScale(0.5 + (0.5 - c.X) * 0.4, 0.5 + (0.5 - c.Y) * 0.4), 0.28)
	end
	for i = 1, 9 do
		UI.rivet(fenetre, UDim2.fromScale(0.08 + i * 0.084, 0.012), 0.014)
		UI.rivet(fenetre, UDim2.fromScale(0.08 + i * 0.084, 0.988), 0.014)
	end
end

-- Intérieur : pierre chaude, lueur de lanterne en bas, braises légères
local interieur = creer("Frame", {Name = "Interieur", Position = UDim2.fromScale(0.016, 0.026), Size = UDim2.fromScale(0.968, 0.948),
	BackgroundColor3 = T.Pierre, ClipsDescendants = true, ZIndex = 1, Parent = fenetre},
	{coin(0.02), trait(T.FerSombre, 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 205)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 240, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 196, 150))})})})
do
	local rng = Random.new(7)
	for _ = 1, 18 do
		local s = rng:NextNumber(0.06, 0.16)
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0, 1), rng:NextNumber(0, 1)),
			Size = UDim2.fromScale(s * rng:NextNumber(1, 1.6), s), SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = rng:NextNumber(-20, 20),
			BackgroundColor3 = if rng:NextNumber() < 0.5 then NOIR else Color3.fromRGB(120, 100, 86),
			BackgroundTransparency = rng:NextNumber(0.87, 0.94), BorderSizePixel = 0, Parent = interieur}, {coin(rng:NextNumber(0.2, 0.45))})
	end
	local lueur = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.35),
		BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = interieur})
	local g = creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(LANTERNE, T.Braise), Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.7, 0.9), NumberSequenceKeypoint.new(1, 0.74)}), Parent = lueur})
	UI.boucle(g, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.1)}, boucles)
end
local function braise()
	local t = 0.003 + math.random() * 0.005
	local x = math.random()
	local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.02), Size = UDim2.fromScale(t, t),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, ZIndex = 2,
		BackgroundColor3 = Color3.fromRGB(255, 150 + math.random(0, 90), 50 + math.random(0, 50)), Parent = interieur}, {coin(0.5)})
	local duree = 2.2 + math.random() * 2
	TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.1, 0.5 + math.random() * 0.35),
		BackgroundTransparency = 1, Size = UDim2.fromScale(t * 0.3, t * 0.3)}):Play()
	Debris:AddItem(b, duree)
end

-- En-tête : médaillon bourse, titre doré, sous-titre, bouton fermer
local medaillon = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.014, 0.085), Size = UDim2.fromScale(0.13, 0.13),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(60, 40, 28), ZIndex = 3, Parent = interieur},
	{coin(0.5), trait(T.Or, 2.5), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 200, 150), Color3.fromRGB(90, 60, 50))})})
local vpMedaillon = Icones.bourse(medaillon, {vitesse = 0.5, angle = 0.4, hauteur = 0.3, marge = 0.72})
vpMedaillon.ZIndex = 4
local titre = texte({Text = "SAC DU MINEUR", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.1, 0.022), Size = UDim2.fromScale(0.5, 0.085), ZIndex = 3, Parent = interieur}, 44)
UI.dore(titre, 2.5)
local sousTitre = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.101, 0.108), Size = UDim2.fromScale(0.5, 0.038), ZIndex = 3, Parent = interieur}, 17)
local fermer = creer("TextButton", {Name = "Fermer", Text = "✕", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = T.Parchemin,
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.08), Size = UDim2.fromScale(0.095, 0.095),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(140, 46, 34), AutoButtonColor = false, ZIndex = 4,
	Parent = interieur}, {coin(0.5), trait(T.Fer, 3), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150)),
	creer("UIPadding", {PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0)})})
UI.reactif(fermer, 1.1)
fermer.MouseEnter:Connect(function()
	TweenService:Create(fermer, FAST, {Rotation = 90}):Play()
end)
fermer.MouseLeave:Connect(function()
	TweenService:Create(fermer, FAST, {Rotation = 0}):Play()
end)
UI.bandeFer(interieur, UDim2.fromScale(0, 0.165), UDim2.fromScale(1, 0.016), 14)
local contenu = creer("Frame", {Name = "Contenu", Position = UDim2.fromScale(0.018, 0.2), Size = UDim2.fromScale(0.964, 0.78),
	BackgroundTransparency = 1, ZIndex = 3, Parent = interieur})

-- ================= Gauche : le personnage =================
local vitrine = creer("Frame", {Name = "Vitrine", Size = UDim2.fromScale(0.3, 1), BackgroundColor3 = T.Fond3D, ClipsDescendants = true,
	ZIndex = 3, Parent = contenu}, {coin(0.05), trait(T.FerSombre, 2.5),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(LANTERNE:Lerp(T.Pierre, 0.5), T.Fond3D)})})
for _, p in {UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.95, 0.03), UDim2.fromScale(0.05, 0.97), UDim2.fromScale(0.95, 0.97)} do
	UI.rivet(vitrine, p, 0.022)
end
local haloPerso = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.95, 0.95),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = LANTERNE, BackgroundTransparency = 0.84, ZIndex = 3, Parent = vitrine}, {coin(0.5)})
UI.boucle(haloPerso, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.9}, boucles)
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.6, 0.05),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.5, ZIndex = 3, Parent = vitrine}, {coin(0.5)}) -- ombre au sol
local vue = creer("ViewportFrame", {Name = "Perso", Size = UDim2.fromScale(1, 0.88), BackgroundTransparency = 1, Active = true, ZIndex = 4,
	Ambient = Color3.fromRGB(150, 130, 110), LightColor = Color3.fromRGB(255, 220, 170), LightDirection = Vector3.new(-0.6, -1, -0.8),
	Parent = vitrine})
local monde = creer("WorldModel", {Parent = vue})
local cameraVue = creer("Camera", {FieldOfView = 30, Parent = vue})
vue.CurrentCamera = cameraVue
local nomPerso = texte({Text = joueur.DisplayName, Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0.05, 0.885),
	Size = UDim2.fromScale(0.9, 0.08), ZIndex = 4, Parent = vitrine}, 26)
UI.dore(nomPerso, 1.5)
local astuce = texte({Text = "⟲ glisse pour tourner", TextColor3 = T.Parchemin, TextTransparency = 0.4,
	Position = UDim2.fromScale(0.1, 0.03), Size = UDim2.fromScale(0.8, 0.045), ZIndex = 4, Parent = vitrine}, 13)

-- ================= Droite =================
local droite = creer("Frame", {Name = "Droite", Position = UDim2.fromScale(0.318, 0), Size = UDim2.fromScale(0.682, 1),
	BackgroundTransparency = 1, ZIndex = 3, Parent = contenu})

-- ---- Équipement ----
local compteEquip = section(droite, "ÉQUIPEMENT", 0)
local rangeeEquip = creer("Frame", {Name = "Equipement", Position = UDim2.fromScale(0, 0.07), Size = UDim2.fromScale(1, 0.235),
	BackgroundTransparency = 1, ZIndex = 3, Parent = droite}, {
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
})
type SlotUI = {bouton: TextButton, fond: Frame, vp: ViewportFrame, halo: Frame, sel: Frame, nom: TextLabel}
local slotsUI: {[string]: SlotUI} = {}
for i, e in EMPLACEMENTS do
	local b = creer("TextButton", {Name = e.id, LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.148, 1),
		BackgroundTransparency = 1, ZIndex = 3, Parent = rangeeEquip})
	local fond = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.76),
		BackgroundColor3 = T.Pierre, ZIndex = 3, Parent = b}, {creer("UIAspectRatioConstraint", {AspectRatio = 1}), coin(0.2),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 140, 135), Color3.fromRGB(255, 232, 210))})})
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86),
		BackgroundColor3 = T.Gris, BackgroundTransparency = 1, ZIndex = 3, Parent = fond}, {coin(0.5)})
	UI.boucle(UI.echelle(halo), TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.12}, boucles)
	local vp = Icones.creer(fond)
	vp.ZIndex = 4
	local sel = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 6, Parent = fond},
		{coin(0.2), trait(T.Or, 3)})
	UI.rarete(fond, T.FerSombre, 1)
	if e.id == "Libre" then -- cadenas
		vp.Visible = false
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.3, 0.3),
			BackgroundTransparency = 1, ZIndex = 4, Parent = fond}, {coin(0.5), trait(T.Gris, 3, 0.4)})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.44, 0.32),
			BackgroundColor3 = T.Inactif, ZIndex = 5, Parent = fond}, {coin(0.2), trait(T.FerSombre, 1.5),
			UI.degrade(BLANC, Color3.fromRGB(120, 120, 120))})
	end
	local nom = texte({Text = e.nom, Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, Position = UDim2.fromScale(0, 0.8),
		Size = UDim2.fromScale(1, 0.19), ZIndex = 3, Parent = b}, 13)
	UI.reactif(b, 1.07, fond)
	tournerAuSurvol(b, vp, 1.8, 0)
	slotsUI[e.id] = {bouton = b, fond = fond, vp = vp, halo = halo, sel = sel, nom = nom}
end

-- ---- Grille du sac ----
local compteSac = section(droite, "SAC", 0.32)
local grille = creer("ScrollingFrame", {Name = "Grille", Position = UDim2.fromScale(0, 0.39), Size = UDim2.fromScale(1, 0.355),
	BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.35, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = droite}, {coin(0.05), trait(T.FerSombre, 2),
	creer("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7)})})
local disposition = creer("UIGridLayout", {CellPadding = UDim2.fromOffset(7, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grille})
local function ajusterGrille()
	local l = grille.AbsoluteSize.X - 19
	local c = math.max(26, math.floor((l - 7 * (COLONNES - 1)) / COLONNES))
	disposition.CellSize = UDim2.fromOffset(c, c)
end
grille:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajusterGrille)
local videGrille = texte({Text = "Ton sac est vide : va miner !", Font = Enum.Font.Merriweather, TextColor3 = T.Gris,
	Position = UDim2.fromScale(0.1, 0.5), Size = UDim2.fromScale(0.8, 0.1), ZIndex = 4, Parent = droite}, 18)

-- ---- Détail ----
local detail = UI.panneau({Name = "Detail", Position = UDim2.fromScale(0, 0.77), Size = UDim2.fromScale(1, 0.23),
	BackgroundColor3 = T.CarteClaire, ZIndex = 3, Parent = droite}, 0.12)
local caseDetail = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.012, 0.5), Size = UDim2.fromScale(0.86, 0.86),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = detail},
	{coin(0.2), UI.degrade(Color3.fromRGB(255, 220, 190), Color3.fromRGB(70, 60, 55))})
local haloDetail = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9),
	BackgroundColor3 = T.Gris, BackgroundTransparency = 0.8, ZIndex = 4, Parent = caseDetail}, {coin(0.5)})
local vpDetail = Icones.creer(caseDetail)
vpDetail.ZIndex = 5
UI.rarete(caseDetail, T.FerSombre, 1, boucles)
local X0 = 0.175
local nomDetail = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(X0, 0.06),
	Size = UDim2.fromScale(0.56, 0.28), ZIndex = 4, Parent = detail}, 26)
creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(30, 16, 8), Transparency = 0.3, Parent = nomDetail})
local infoDetail = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(X0, 0.35),
	Size = UDim2.fromScale(0.56, 0.16), ZIndex = 4, Parent = detail}, 14)
local statDetail = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(X0, 0.55), Size = UDim2.fromScale(0.2, 0.16), ZIndex = 4, Parent = detail}, 15)
local rail = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(X0 + 0.205, 0.63), Size = UDim2.fromScale(0.36, 0.11),
	BackgroundColor3 = T.Fond3D, ClipsDescendants = true, ZIndex = 4, Parent = detail}, {coin(0.5), trait(T.FerSombre, 1.5)})
local barre = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 5, Parent = rail},
	{coin(0.5), UI.degrade(BLANC, Color3.fromRGB(150, 150, 150))})
local compo = creer("Frame", {Name = "Composition", Position = UDim2.fromScale(X0, 0.76), Size = UDim2.fromScale(0.56, 0.2),
	BackgroundTransparency = 1, ZIndex = 4, Parent = detail}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center})})
local principal = UI.boutonPrincipal({Name = "Equiper", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.5),
	Size = UDim2.fromScale(0.23, 0.56), ZIndex = 4, Parent = detail}, boucles)
local boutonEquiper = principal.bouton

-- Bulle au survol et message
local bulle = texte({Font = Enum.Font.GothamBlack, BackgroundColor3 = T.BoisSombre, Visible = false,
	AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), ZIndex = 30, Parent = gui}, 16)
bulle.BackgroundTransparency = 0.08
bulle.TextScaled = false
bulle.TextSize = 16
creer("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = bulle})
coin(0.3).Parent = bulle
trait(T.OrFonce, 1.5).Parent = bulle
local message = UI.toast(gui)

local function montrerBulle(txt: string, couleur: Color3?)
	local p = UserInputService:GetMouseLocation()
	bulle.Text = txt
	bulle.TextColor3 = couleur or T.Parchemin
	bulle.Position = UDim2.fromOffset(p.X + 14, p.Y + 6)
	bulle.Visible = true
end

-- ================= État =================
local etat: Etat = {minerais = {}, objets = {}, equipement = {}}
local ouverte = false
local sale = true -- l'état a changé pendant que le sac était fermé
local selection: string? = nil -- "m:<minerai>", "o:<id objet>", "p" (pioche)
local enAttente = false
type Case = {bouton: TextButton, vp: ViewportFrame, sel: Frame, quantite: TextLabel?}
local cases: {[string]: Case} = {}
local vuTotal: number? = nil -- minerais au dernier coup d'œil (pastille du bouton)

local function objetParId(id: string?): Objet?
	for _, o in etat.objets do
		if o.id == id then
			return o
		end
	end
	return nil
end

local function estEquipe(o: Objet): boolean
	return etat.equipement[o.type] == o.id
end

local function totalMinerais(): number
	local n = 0
	for _, q in etat.minerais do
		n += if type(q) == "number" then q else 0
	end
	return n
end

local choisir: (string?) -> ()

local function nouvelleCase(cle: string, nom: string, couleurR: Color3, niveau: number, dessiner: (ViewportFrame) -> (), avecQuantite: boolean): Case
	local b = creer("TextButton", {Name = cle, Text = "", AutoButtonColor = false, BackgroundColor3 = T.Carte, ZIndex = 4, Parent = grille},
		{coin(0.16), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 225), Color3.fromRGB(150, 135, 125))})})
	UI.rarete(b, couleurR, niveau).Transparency = if niveau >= 2 then 0 else 0.4
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78),
		BackgroundColor3 = couleurR, BackgroundTransparency = 0.82, ZIndex = 4, Parent = b}, {coin(0.5)})
	local vp = Icones.creer(b)
	vp.ZIndex = 5
	dessiner(vp)
	local sel = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 7, Parent = b},
		{coin(0.16), trait(T.Or, 3)})
	local q: TextLabel? = nil
	if avecQuantite then
		local l = texte({Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.95, 0.98),
			Size = UDim2.fromScale(0.8, 0.32), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6, Parent = b}, 18)
		creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 10, 4), Parent = l})
		q = l
	end
	UI.reactif(b, 1.07)
	tournerAuSurvol(b, vp, 1.8, 0)
	b.MouseEnter:Connect(function()
		montrerBulle(nom, couleurR:Lerp(BLANC, 0.35))
	end)
	b.MouseLeave:Connect(function()
		bulle.Visible = false
	end)
	b.Activated:Connect(function()
		choisir(cle)
	end)
	local c: Case = {bouton = b, vp = vp, sel = sel, quantite = q}
	cases[cle] = c
	return c
end

-- Surlignage de la sélection (grille + emplacements), sans rien reconstruire
local function surligner()
	for cle, c in cases do
		c.sel.Visible = cle == selection
	end
	for id, s in slotsUI do
		local equipe = etat.equipement[id]
		s.sel.Visible = (id == "Pioche" and selection == "p") or (equipe ~= nil and selection == "o:" .. equipe)
	end
end

local function rafraichirGrille()
	local vus: {[string]: boolean} = {}
	local n = 0
	for i, id in Forge.ORDRE_MINERAIS do
		local q = etat.minerais[id] or 0
		if q > 0 then
			n += 1
			local cle = "m:" .. id
			vus[cle] = true
			local c = cases[cle]
			if not c then
				local m = Forge.MINERAIS[id]
				local _, couleurR, niveau = rareteMinerai(id)
				c = nouvelleCase(cle, m.nom, couleurR, niveau, function(vp)
					Icones.definir(vp, "minerai", id, {vitesse = 0, hauteur = 0.35, marge = 0.85})
				end, true)
			end
			c.bouton.LayoutOrder = i
			local l = c.quantite
			if l and l.Text ~= "×" .. q then
				local avant = l.Text
				l.Text = "×" .. q
				if avant ~= "" and ouverte then
					pop(l, 0.6)
				end
			end
		end
	end
	for i, o in etat.objets do
		if not estEquipe(o) then
			n += 1
			local cle = "o:" .. o.id
			vus[cle] = true
			local c = cases[cle]
			if not c then
				local _, couleurR, niveau = rareteObjet(o)
				local teinte = couleurHex(o.couleur)
				c = nouvelleCase(cle, o.nom, couleurR, niveau, function(vp)
					iconeObjet(vp, o.type, teinte, {vitesse = 0}, o.modele)
				end, false)
			end
			c.bouton.LayoutOrder = 1000 - i
		end
	end
	for cle, c in cases do
		if not vus[cle] then
			c.bouton:Destroy()
			cases[cle] = nil
		end
	end
	videGrille.Visible = n == 0
	compteSac.Text = string.format("%d case%s", n, if n > 1 then "s" else "")
	local total = totalMinerais()
	sousTitre.Text = string.format("%d minerai%s · %d objet%s forgé%s", total, if total > 1 then "s" else "",
		#etat.objets, if #etat.objets > 1 then "s" else "", if #etat.objets > 1 then "s" else "")
	local sel = selection
	if sel and sel:sub(1, 2) == "m:" and not cases[sel] then
		selection = nil
	elseif sel and sel:sub(1, 2) == "o:" and not objetParId(sel:sub(3)) then
		selection = nil
	end
end

local function rafraichirEquipement()
	local pioche = Pioches.get(joueur:GetAttribute("Pioche"))
	local nb = 0
	for _, e in EMPLACEMENTS do
		local s = slotsUI[e.id]
		if e.id == "Libre" then
			continue
		end
		local _nomR, couleurR, niveau, plein = "", T.FerSombre, 1, false
		if e.id == "Pioche" then
			Icones.definir(s.vp, "pioche", if pioche then pioche.id else Pioches.DEPART, {vitesse = 0, silhouette = pioche == nil, hauteur = 0.15, marge = 0.85})
			if pioche then
				_nomR, couleurR, niveau = rarete(pioche.rarete)
				plein = true
			end
		else
			local o = objetParId(etat.equipement[e.id])
			if o then
				iconeObjet(s.vp, o.type, couleurHex(o.couleur), {vitesse = 0}, o.modele)
				_nomR, couleurR, niveau = rareteObjet(o)
				plein = true
			else
				iconeObjet(s.vp, e.id, ACIER, {vitesse = 0, silhouette = true})
			end
		end
		nb += if plein then 1 else 0
		s.vp.ImageTransparency = if plein then 0 else 0.6
		UI.rarete(s.fond, if plein then couleurR else T.FerSombre, if plein then niveau else 1, boucles)
		s.halo.BackgroundColor3 = couleurR
		s.halo.BackgroundTransparency = if plein then 0.62 else 1
		s.fond.BackgroundColor3 = if plein then couleurR:Lerp(T.Pierre, 0.7) else T.Pierre
		s.nom.TextColor3 = if plein then couleurR:Lerp(BLANC, 0.3) else T.Gris
	end
	compteEquip.Text = string.format("%d / 5 équipé%s", nb, if nb > 1 then "s" else "")
end

-- ---- Panneau de détail ----
local signatureCompo = ""
local function definirCompo(liste: {{any}}?, astuceTexte: string?)
	local sig = "t:" .. (astuceTexte or "")
	if liste then
		local morceaux = {}
		for _, e in liste do
			table.insert(morceaux, tostring(e[1]) .. "=" .. tostring(e[2]))
		end
		sig = "c:" .. table.concat(morceaux, ",")
	end
	if sig == signatureCompo then
		return
	end
	signatureCompo = sig
	for _, d in compo:GetChildren() do
		if d:IsA("GuiObject") then
			d:Destroy()
		end
	end
	if not liste then
		texte({Text = astuceTexte or "", Font = Enum.Font.Merriweather, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = compo}, 14)
		return
	end
	for i, e in liste do
		local id, q = tostring(e[1]), tonumber(e[2]) or 0
		local m = Forge.MINERAIS[id]
		local _, couleurR = rareteMinerai(id)
		local puce = creer("Frame", {LayoutOrder = i, Size = UDim2.fromScale(2.4, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.25, ZIndex = 4, Parent = compo}, {coin(0.5), trait(couleurR, 1.5, 0.2)})
		local rond = creer("Frame", {Size = UDim2.fromScale(1, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = couleurR:Lerp(T.Fond3D, 0.6), ZIndex = 5, Parent = puce}, {coin(0.5)})
		if m then
			Icones.minerai(id, rond, {vitesse = 0, hauteur = 0.35, marge = 0.8}).ZIndex = 6
		end
		texte({Text = "×" .. q, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.46, 0.15), Size = UDim2.fromScale(0.5, 0.7), ZIndex = 5, Parent = puce}, 14)
	end
end

local tweenBarre: Tween? = nil
local function definirBarre(fraction: number, couleur: Color3)
	if tweenBarre then
		tweenBarre:Cancel()
	end
	barre.BackgroundColor3 = couleur
	local t = TweenService:Create(barre, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(math.clamp(fraction, 0.03, 1), 1)})
	tweenBarre = t
	t:Play()
end

local cleDetail: string? = nil
local function rafraichirDetail()
	local cle = selection
	surligner()
	detail.Visible = cle ~= nil
	if not cle then
		cleDetail = nil
		return
	end
	local nouveau = cle ~= cleDetail
	cleDetail = cle
	local couleurR, niveau, nomRarete = T.Gris, 1, "Commun"
	local action: string? = nil
	if cle == "p" then
		local def = Pioches.get(joueur:GetAttribute("Pioche"))
		Icones.definir(vpDetail, "pioche", if def then def.id else Pioches.DEPART, {vitesse = 0.7, hauteur = 0.15, marge = 0.85})
		if def then
			nomRarete, couleurR, niveau = rarete(def.rarete)
		end
		nomDetail.Text = if def then def.nom else "Aucune pioche"
		infoDetail.Text = "Pioche · " .. nomRarete
		statDetail.Text = string.format("Puissance ×%s", if def then tostring(def.puissance) else "—")
		definirBarre(if def then def.puissance / PUISSANCE_MAX else 0, couleurR)
		definirCompo(nil, "Change de pioche chez Liesel")
	elseif cle:sub(1, 2) == "m:" then
		local id = cle:sub(3)
		local m = Forge.MINERAIS[id]
		Icones.definir(vpDetail, "minerai", id, {vitesse = 0.7, hauteur = 0.35, marge = 0.85})
		nomRarete, couleurR, niveau = rareteMinerai(id)
		nomDetail.Text = m.nom
		infoDetail.Text = string.format("Minerai · %s · ×%d", nomRarete, etat.minerais[id] or 0)
		statDetail.Text = "Force " .. tostring(m.force)
		definirBarre(m.force / FORCE_MAX, couleurR)
		definirCompo(nil, "À mélanger chez Brom le forgeron")
	else
		local o = objetParId(cle:sub(3))
		if not o then
			detail.Visible = false
			return
		end
		local t = Forge.TYPES[o.type]
		iconeObjet(vpDetail, o.type, couleurHex(o.couleur), {vitesse = 0.7}, o.modele)
		nomRarete, couleurR, niveau = rareteObjet(o)
		nomDetail.Text = o.nom
		local echelle = Forge.ECHELLES[o.type]
		infoDetail.Text = string.format("%s · %s%s%s", if t then t.nom else o.type, nomRarete,
			if o.rang and echelle then string.format(" · Rang %d/%d", o.rang, #echelle) else "",
			if estEquipe(o) then " · ✔ Équipé" else "")
		statDetail.Text = string.format("%s %d", o.stat, o.valeur)
		definirBarre(o.valeur / statMax(o.type), couleurR)
		definirCompo(o.composition)
		action = if estEquipe(o) then "retirer" else "equiper"
	end
	nomDetail.TextColor3 = couleurR:Lerp(BLANC, 0.55)
	infoDetail.TextColor3 = couleurR:Lerp(BLANC, 0.2)
	haloDetail.BackgroundColor3 = couleurR
	caseDetail.BackgroundColor3 = couleurR:Lerp(T.Fond3D, 0.65)
	UI.rarete(caseDetail, couleurR, niveau, boucles)
	boutonEquiper.Visible = action ~= nil
	if action then
		principal.definir(if enAttente then "…" elseif action == "equiper" then "ÉQUIPER" else "RETIRER",
			if action == "equiper" then T.Vert else Color3.fromRGB(196, 104, 64), not enAttente)
	end
	if nouveau then
		pop(caseDetail, 0.8)
	end
end

choisir = function(cle: string?)
	if selection ~= cle then
		selection = cle
		jouer("clic", 1.15)
		local c = cle and cases[cle]
		if c then
			pop(c.bouton, 0.85)
		end
	end
	rafraichirDetail()
end

local function rafraichir()
	sale = false
	rafraichirGrille()
	rafraichirEquipement()
	rafraichirDetail()
end

-- Pastille du bouton : nouveaux minerais ramassés depuis le dernier coup d'œil
local function majBadge()
	local total = totalMinerais()
	if vuTotal == nil or ouverte then
		vuTotal = total
	end
	local nouveaux = total - (vuTotal :: number)
	if nouveaux > 0 then
		local txt = "+" .. (if nouveaux > 99 then "99" else tostring(nouveaux))
		if texteBadge.Text ~= txt or not badge.Visible then
			texteBadge.Text = txt
			badge.Visible = true
			pop(badge, 0.5)
			pop(pivotBourse, 0.85)
		end
	else
		badge.Visible = false
		if nouveaux < 0 then
			vuTotal = total
		end
	end
end

local function recevoir(nouvel: any)
	if type(nouvel) == "table" and type(nouvel.minerais) == "table" and type(nouvel.objets) == "table"
		and type(nouvel.equipement) == "table" then
		etat = nouvel
		if ouverte then
			rafraichir()
		else
			sale = true
		end
		majBadge()
	end
end
evEtat.OnClientEvent:Connect(recevoir)
joueur:GetAttributeChangedSignal("Pioche"):Connect(function()
	if ouverte then
		rafraichirEquipement()
		rafraichirDetail()
	end
end)

-- ================= Équiper / retirer : l'icône vole entre la case et l'emplacement =================
local function voler(p0: Vector2, s0: Vector2, cible: GuiObject, dessiner: (ViewportFrame) -> (), couleurR: Color3, cacher: ViewportFrame?)
	local p1, s1 = cible.AbsolutePosition, cible.AbsoluteSize
	local c0, c1 = p0 + s0 / 2, p1 + s1 / 2
	local cm = (c0 + c1) / 2 - Vector2.new(0, math.max(40, (c1 - c0).Magnitude * 0.25))
	local volant = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c0.X, c0.Y), Size = UDim2.fromOffset(s0.X, s0.Y),
		BackgroundTransparency = 1, ZIndex = 40, Parent = gui})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9),
		BackgroundColor3 = couleurR, BackgroundTransparency = 0.6, ZIndex = 40, Parent = volant}, {coin(0.5)})
	local vp = Icones.creer(volant)
	vp.ZIndex = 41
	dessiner(vp)
	if cacher then
		cacher.Visible = false
	end
	jouer("ouvrir", 1.8)
	local sm = (s0 + s1) / 2 * 1.3
	local t1 = TweenService:Create(volant, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.fromOffset(cm.X, cm.Y), Size = UDim2.fromOffset(sm.X, sm.Y), Rotation = -14})
	local t2 = TweenService:Create(volant, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.fromOffset(c1.X, c1.Y), Size = UDim2.fromOffset(s1.X, s1.Y), Rotation = 0})
	t1.Completed:Connect(function()
		t2:Play()
	end)
	t2.Completed:Connect(function()
		volant:Destroy()
		if cacher and cacher.Parent then
			cacher.Visible = true
		end
		if cible.Parent then
			pop(cible, 0.75)
			UI.gerbe(cible, couleurR, 10)
		end
		jouer("metal", 1.15)
	end)
	t1:Play()
end

local function equiperOuRetirer()
	local cle = selection
	if enAttente or not cle or cle:sub(1, 2) ~= "o:" or not boutonEquiper.Active then
		return
	end
	local o = objetParId(cle:sub(3))
	if not o then
		return
	end
	local action = if estEquipe(o) then "retirer" else "equiper"
	local slot = o.type
	local s = slotsUI[slot]
	local ancien = etat.equipement[slot]
	-- position de départ capturée avant que la grille ne change
	local depart: GuiObject? = if action == "equiper" then (cases[cle] and cases[cle].bouton) else (s and s.fond)
	local p0, s0 = if depart then depart.AbsolutePosition else Vector2.zero, if depart then depart.AbsoluteSize else Vector2.zero
	enAttente = true
	rafraichirDetail()
	local ok, rep = pcall(function()
		return fnAction:InvokeServer({action = action, slot = slot, id = o.id})
	end)
	enAttente = false
	if ok and type(rep) == "table" then
		recevoir(rep.etat)
		if rep.ok then
			local _, couleurR = rareteObjet(o)
			local teinte = couleurHex(o.couleur)
			local function dessiner(vp: ViewportFrame)
				iconeObjet(vp, o.type, teinte, {vitesse = 0}, o.modele)
			end
			if action == "equiper" and s then
				if depart then
					voler(p0, s0, s.fond, dessiner, couleurR, s.vp)
				else
					pop(s.fond)
					jouer("metal", 1.15)
				end
				local revenu = ancien and cases["o:" .. ancien]
				if revenu then
					pop(revenu.bouton, 0.5)
				end
			else
				task.wait() -- la grille place la nouvelle case
				local c = cases[cle]
				if c and depart then
					voler(p0, s0, c.bouton, dessiner, couleurR, c.vp)
				end
			end
		else
			message(tostring(rep.message), false)
			jouer("clic", 0.6)
			UI.secouer(boutonEquiper, 6)
		end
	else
		message("Le sac ne répond pas, réessaie", false)
	end
	rafraichirDetail()
end
boutonEquiper.Activated:Connect(function()
	task.spawn(equiperOuRetirer)
end)

for id, s in slotsUI do
	s.bouton.Activated:Connect(function()
		if id == "Libre" then
			jouer("clic", 0.6)
			UI.secouer(s.fond, 4)
		elseif id == "Pioche" then
			choisir("p")
		elseif etat.equipement[id] and objetParId(etat.equipement[id]) then
			choisir("o:" .. etat.equipement[id])
		else
			jouer("clic", 0.8)
			UI.secouer(s.fond, 4)
			message("Emplacement vide : forge un objet « " .. Forge.TYPES[id].nom .. " » chez Brom", false)
		end
	end)
end

-- ================= Personnage 3D =================
local clone: Model? = nil
local angle, vitesse = 0, 0
local glisse: Vector3? = nil
local derniereMain = 0
local BASE = CFrame.Angles(0, math.pi, 0) -- face à la caméra

local function recloner()
	monde:ClearAllChildren()
	clone = nil
	local perso = joueur.Character
	if not perso then
		return
	end
	local archivable = perso.Archivable
	perso.Archivable = true
	local ok, copie = pcall(perso.Clone, perso)
	perso.Archivable = archivable
	if not ok or not copie then
		return
	end
	local m = copie :: Model
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") or d:IsA("Sound") or d:IsA("ForceField") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.LocalTransparencyModifier = 0 -- 1re personne : la caméra masque tête et casque du vrai perso, pas de la vitrine
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 0
		end
	end
	local h = m:FindFirstChildOfClass("Humanoid")
	if h then
		h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	m:PivotTo(BASE)
	local cf, taille = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position) * BASE.Rotation
	m.Parent = monde
	local distance = (taille.Y * 0.66) / math.tan(math.rad(cameraVue.FieldOfView / 2))
	cameraVue.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, taille.Y * 0.05, distance), cf.Position)
	clone = m
end

-- Zone de glisser plein cadre au-dessus du perso : capte le clic (il ne traverse jamais vers le voile)
local zoneGlisser = creer("TextButton", {Name = "ZoneGlisser", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = vitrine})
zoneGlisser.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		glisse = input.Position
		vitesse = 0
		TweenService:Create(astuce, FAST, {TextTransparency = 1}):Play()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	local depart = glisse
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if depart then
			local dx = (input.Position - depart).X * 0.012
			angle += dx
			vitesse = vitesse * 0.5 + dx * 30 -- élan pour l'inertie
			glisse = input.Position
			derniereMain = os.clock()
		end
		if bulle.Visible then
			local p = UserInputService:GetMouseLocation()
			bulle.Position = UDim2.fromOffset(p.X + 14, p.Y + 6)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		glisse = nil
	end
end)

local rotation: RBXScriptConnection? = nil
local function tourner(dt: number)
	if not glisse then
		angle += vitesse * dt
		vitesse *= math.exp(-3 * dt)
		if math.abs(vitesse) < 0.2 and os.clock() - derniereMain > 2 then
			angle += dt * 0.5
		end
	end
	local m = clone
	if m and m.Parent then
		m:PivotTo(CFrame.new(m.WorldPivot.Position) * CFrame.Angles(0, angle, 0) * BASE)
	end
end

-- Le perso change (respawn, accessoire, outil en main) : nouvelle copie, regroupée
local copieDemandee = false
local function demanderCopie()
	if copieDemandee then
		return
	end
	copieDemandee = true
	task.delay(0.3, function()
		copieDemandee = false
		if ouverte then
			recloner()
		end
	end)
end
local function suivrePerso(perso: Model)
	demanderCopie()
	perso.ChildAdded:Connect(demanderCopie)
	perso.ChildRemoved:Connect(demanderCopie)
end
joueur.CharacterAdded:Connect(suivrePerso)
if joueur.Character then
	suivrePerso(joueur.Character)
end

-- ================= Ouverture / fermeture =================
local tweenVoile: Tween? = nil
local function basculer(ouvrir: boolean)
	if ouvrir == ouverte then
		return
	end
	ouverte = ouvrir
	if tweenVoile then
		tweenVoile:Cancel()
	end
	jouer("ouvrir", if ouvrir then 1 else 1.3)
	pop(pivotBourse, 0.7)
	if ouvrir then
		gui.Enabled = true
		badge.Visible = false
		vuTotal = totalMinerais()
		if sale then
			rafraichir()
		else
			rafraichirEquipement()
			rafraichirDetail()
		end
		ajusterGrille()
		recloner()
		for _, t in boucles do
			t:Play()
		end
		astuce.TextTransparency = 0.4
		echelleFenetre.Scale = 0.85
		fenetre.Position = UDim2.fromScale(0.5, 0.56)
		TweenService:Create(echelleFenetre, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(fenetre, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		tweenVoile = TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.3})
		rotation = RunService.RenderStepped:Connect(tourner)
		task.spawn(function()
			while ouverte do
				braise()
				task.wait(0.16 + math.random() * 0.2)
			end
		end)
	else
		bulle.Visible = false
		for _, t in boucles do
			t:Pause()
		end
		TweenService:Create(echelleFenetre, FAST, {Scale = 0.86}):Play()
		TweenService:Create(fenetre, FAST, {Position = UDim2.fromScale(0.5, 0.55)}):Play()
		tweenVoile = TweenService:Create(voile, FAST, {BackgroundTransparency = 1})
		if rotation then
			rotation:Disconnect()
			rotation = nil
		end
		task.delay(0.15, function()
			if not ouverte then
				gui.Enabled = false
				monde:ClearAllChildren()
				clone = nil
			end
		end)
	end
	(tweenVoile :: Tween):Play()
end

boutonSac.Activated:Connect(function()
	UI.gerbe(socle, T.Or, 8, Vector2.new(0.5, 0.4))
	basculer(not ouverte)
end)
fermer.Activated:Connect(function()
	jouer("clic", 0.9)
	basculer(false)
end)
-- Fermeture par le voile : seulement un clic simple commencé ET fini hors de la fenêtre (jamais la fin d'un glisser)
local appuiDehors: Vector3? = nil
local function horsFenetre(p: Vector3): boolean
	local a, t = fenetre.AbsolutePosition, fenetre.AbsoluteSize
	local inset = if gui.IgnoreGuiInset then GuiService:GetGuiInset() else Vector2.zero
	local x, y = p.X + inset.X, p.Y + inset.Y
	return x < a.X or y < a.Y or x > a.X + t.X or y > a.Y + t.Y
end
UserInputService.InputBegan:Connect(function(input)
	if ouverte and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		appuiDehors = if horsFenetre(input.Position) and not glisse then input.Position else nil
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local depart = appuiDehors
	if depart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		appuiDehors = nil
		if ouverte and not glisse and horsFenetre(input.Position) and (input.Position - depart).Magnitude < 12 then
			basculer(false)
		end
	end
end)
UserInputService.InputBegan:Connect(function(input, traite)
	if input.KeyCode == TOUCHE and not traite then
		basculer(not ouverte)
	elseif input.KeyCode == Enum.KeyCode.ButtonB and ouverte then
		basculer(false)
	end
end)

-- État initial (au cas où l'envoi du serveur est arrivé avant ce script)
task.spawn(function()
	for _ = 1, 30 do
		local ok, rep = pcall(function()
			return fnAction:InvokeServer({action = "etat"})
		end)
		if ok and type(rep) == "table" and rep.etat then
			recevoir(rep.etat)
			return
		end
		task.wait(2)
	end
end)
