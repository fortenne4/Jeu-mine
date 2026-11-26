--!strict
-- Sac du mineur · SCRIPT CLIENT (bouton HUD + fenêtre d'inventaire)
-- Touche B (ou le bouton bourse) : ouvre / ferme. Manette : B ferme, L1 / R1 changent d'onglet, Y change le tri.
-- Gauche : ton personnage en 3D (glisse pour le tourner) entouré de ses emplacements d'équipement + Vie / Défense / Dégâts / Puissance.
-- Centre : onglets (Tout / Minerais / Armes / Armures), tri (type, rareté, quantité), grille du sac (objets NON équipés).
-- Droite : détail de la case choisie (grand aperçu 3D, rareté, stats en barres, composition, bouton Équiper / Retirer).
-- L'état vient du serveur (SacEtat) ; équiper / retirer passe par SacAction : le client ne décide rien.
-- Icônes = vrais modèles 3D (IconesObjets). Perf : grille mise à jour par différence (jamais reconstruite),
-- filtre et tri = Visible / LayoutOrder ; seules les icônes survolées / sélectionnées tournent ; un seul battement
-- (RenderStepped, fenêtre ouverte seulement) anime les lueurs des raretés Épique et plus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Forge = require(Partage:WaitForChild("Forge"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local PrixMinerais = require(Partage:WaitForChild("PrixMinerais"))
local ArmesVoxels = require(Partage:WaitForChild("ArmesVoxels"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local evEtat = ReplicatedStorage:WaitForChild("SacEtat") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("SacAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Objet = {id: string, type: string, modele: string?, rang: number?, nom: string, couleur: string, stat: string, valeur: number, composition: {{any}}}
type Etat = {minerais: {[string]: number}, objets: {Objet}, equipement: {[string]: string}}

local T = UI.T
local creer, coin, trait, texte, jouer, pop = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop
local FAST = UI.FAST
local TOUCHE = Enum.KeyCode.B
local EPEE_3D = "EpeeFer"
local ACIER = Color3.fromRGB(168, 174, 186)
local BLANC = Color3.new(1, 1, 1)
local NOIR = Color3.new(0, 0, 0)
-- Palette « verre fumé » : sombre, chaud, lisible
local FOND = Color3.fromRGB(26, 21, 19)
local CARTE = Color3.fromRGB(40, 34, 31)
local CREUX = Color3.fromRGB(15, 12, 11)
local DISCRET = Color3.fromRGB(164, 152, 140)
local LISERE = Color3.fromRGB(255, 226, 180)
local DOUX = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SURVOL = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ARMURES = {Casque = true, Plastron = true, Jambieres = true}
local CATEGORIE_TYPE = {Epee = "arme", Casque = "armure", Plastron = "armure", Jambieres = "armure"}

-- Raretés : celles des pioches + « Épique » (nouveaux minerais de la mine privée)
-- + « Céleste » : au-dessus de tout, réservée à l'Épée des astres (butin du Gardien des astres, palier 8)
local NIVEAUX: {[string]: number} = {Commun = 1, ["Peu commun"] = 2, Rare = 3, ["Épique"] = 4, ["Légendaire"] = 5, Mythique = 6, Divin = 7, ["Céleste"] = 8}
local COULEURS_RARETE: {[string]: Color3} = table.clone(Pioches.RARETES)
COULEURS_RARETE["Épique"] = COULEURS_RARETE["Épique"] or Color3.fromRGB(236, 96, 200)
COULEURS_RARETE["Céleste"] = Color3.fromRGB(120, 170, 255)
local NIVEAU_LUEUR = 4 -- lueur animée à partir d'Épique

-- Emplacements autour du mannequin : cote 0 = gauche, 1 = droite ; rang = ligne
local EMPLACEMENTS = {
	{id = "Casque", nom = "Casque", cote = 0, rang = 0},
	{id = "Plastron", nom = "Plastron", cote = 0, rang = 1},
	{id = "Jambieres", nom = "Jambières", cote = 0, rang = 2},
	{id = "Epee", nom = "Épée", cote = 1, rang = 0},
	{id = "Pioche", nom = "Pioche", cote = 1, rang = 1},
	{id = "Libre", nom = "Bientôt", cote = 1, rang = 2},
}
local CATEGORIES = {
	{id = "tout", nom = "Tout"},
	{id = "minerai", nom = "Minerais"},
	{id = "arme", nom = "Armes"},
	{id = "armure", nom = "Armures"},
}
local TRIS = {"Type", "Rareté", "Quantité"}

local PUISSANCE_MAX, FORCE_MAX, PRIX_MAX = 1, 1, 1
for _, p in Pioches.LISTE do
	PUISSANCE_MAX = math.max(PUISSANCE_MAX, p.puissance)
end
for _, m in Forge.MINERAIS do
	FORCE_MAX = math.max(FORCE_MAX, m.force)
end
for _, id in Forge.ORDRE_SAC do
	PRIX_MAX = math.max(PRIX_MAX, PrixMinerais.get(id) or 0)
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
	local r = if type(nom) == "string" and NIVEAUX[nom] then nom else "Commun"
	return r, COULEURS_RARETE[r] or T.Gris, NIVEAUX[r] or 1
end

local function rareteMinerai(id: string): (string, Color3, number)
	local v = MineraisModeles.VISUEL[id]
	return rarete(v and v.rarete)
end

-- Rareté d'un objet forgé = celle de son rang (échelle de la forge), sinon de son minerai le plus rare
local function rareteObjet(o: Objet): (string, Color3, number)
	local echelle = Forge.ECHELLES[o.type]
	local palier = echelle and o.rang and echelle[o.rang]
	if o.modele == "CasqueMagma" then -- casque de quête unique (Partage.CasqueMagma)
		return rarete("Mythique")
	elseif o.modele == "EpeeDesAstres" then -- épée unique du Gardien des astres
		return rarete("Céleste")
	end
	if palier then
		return rarete(palier.rarete)
	end
	local meilleur, n = nil, 0
	for _, e in o.composition do
		local v = MineraisModeles.VISUEL[e[1]]
		local k = v and NIVEAUX[v.rarete] or 0
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

local function abrege(q: number): string
	if q >= 100000 then
		return string.format("%dk", math.floor(q / 1000))
	elseif q >= 10000 then
		return string.format("%.1fk", q / 1000)
	end
	return tostring(q)
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

local function vitesseIcone(vp: ViewportFrame, v: number)
	local vue = Icones.vue(vp)
	if vue then
		vue.vitesse = v
	end
end

-- Liseré fin et discret (verre)
local function filet(transp: number?, couleur: Color3?, epaisseur: number?): UIStroke
	return creer("UIStroke", {Color = couleur or LISERE, Transparency = transp or 0.88, Thickness = epaisseur or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

-- Relief vertical : haut plus clair que le bas (multiplie la couleur de fond)
local function relief(haut: number?, bas: number?): UIGradient
	local h, b = math.floor(math.min(haut or 1, 1) * 255), math.floor(math.min(bas or 0.62, 1) * 255)
	return creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(h, h, h), Color3.fromRGB(b, b, b))})
end

-- Fondu horizontal (lignes de séparation, ombres)
local function fonduBords(milieu: number?): UIGradient
	return creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, milieu or 0), NumberSequenceKeypoint.new(1, 1)})})
end

-- Reflet qui tourne sur un liseré (piloté par le battement, pas par un tween par case)
local function refletTournant(s: UIStroke): UIGradient
	return creer("UIGradient", {Name = "Reflet", Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.42, 0.45), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.58, 0.45),
		NumberSequenceKeypoint.new(1, 0.55)}), Parent = s})
end

local function titreSection(parent: Instance, txt: string, pos: UDim2, taille: UDim2): TextLabel
	local l = texte({Text = txt, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = pos, Size = taille, Parent = parent}, 14)
	l.TextTransparency = 0.1
	return l
end

local playerGui = joueur:WaitForChild("PlayerGui")

-- ================= Bouton HUD : bourse 3D dans un médaillon de verre fumé =================
local hud = creer("ScreenGui", {Name = "SacHUD", ResetOnSpawn = false, DisplayOrder = 2, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui})
local socle = creer("Frame", {Name = "Sac", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.55, 0),
	Size = UDim2.fromScale(0.11, 0.11), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, Parent = hud},
	{creer("UIAspectRatioConstraint", {AspectRatio = 1}), creer("UISizeConstraint", {MinSize = Vector2.new(56, 56), MaxSize = Vector2.new(92, 92)})})
-- lueur chaude qui respire derrière le médaillon
local haloHud = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3),
	BackgroundColor3 = T.Braise, BackgroundTransparency = 0.86, Parent = socle}, {coin(0.5)})
TweenService:Create(haloHud, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{BackgroundTransparency = 0.95, Size = UDim2.fromScale(1.45, 1.45)}):Play()
local boutonSac = creer("TextButton", {Name = "Bouton", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = FOND, BackgroundTransparency = 0.12, ZIndex = 2, Parent = socle},
	{coin(0.5), filet(0.35, T.Or, 2), relief(1.5, 0.7)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.84),
	BackgroundTransparency = 1, Parent = boutonSac}, {coin(0.5), filet(0.82)})
local foyer = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromScale(0.62, 0.62),
	BackgroundColor3 = T.Braise, BackgroundTransparency = 0.8, Parent = boutonSac}, {coin(0.5)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.46, 0.08),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.5, Parent = boutonSac}, {coin(0.5), fonduBords(0.2)}) -- ombre de la bourse
-- Pivot en haut de la bourse (la rotation d'un GuiObject se fait autour de son centre : la bourse occupe la moitié basse)
local pivotBourse = creer("Frame", {Name = "Pivot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.1),
	Size = UDim2.fromScale(0.84, 1.6), BackgroundTransparency = 1, ZIndex = 3, Parent = boutonSac})
local vpBourse = Icones.bourse(pivotBourse, {vitesse = 0, angle = 0.4, hauteur = 0.32, marge = 0.7})
vpBourse.Position, vpBourse.Size, vpBourse.ZIndex = UDim2.fromScale(0, 0.5), UDim2.fromScale(1, 0.5), 3
vpBourse.Ambient = Color3.fromRGB(150, 122, 100)
local etiquetteSac = texte({Text = "SAC", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 1.02), Size = UDim2.fromScale(1, 0.24), ZIndex = 4, Parent = socle}, 15)
creer("UIStroke", {Thickness = 1.5, Color = NOIR, Transparency = 0.35, Parent = etiquetteSac})
local toucheSac = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.1, 0.12), Size = UDim2.fromScale(0.3, 0.3),
	BackgroundColor3 = CREUX, BackgroundTransparency = 0.1, ZIndex = 8, Parent = socle}, {coin(0.3), filet(0.45, T.Or, 1.5)})
texte({Text = TOUCHE.Name, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, Position = UDim2.fromScale(0.18, 0.18),
	Size = UDim2.fromScale(0.64, 0.64), ZIndex = 9, Parent = toucheSac}, 16)
toucheSac.Visible = not UserInputService.TouchEnabled
-- Pastille « nouveaux minerais » (apparaît quand le sac est fermé)
local badge = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.9, 0.12), Size = UDim2.fromScale(0.42, 0.26),
	BackgroundColor3 = T.Braise, Visible = false, ZIndex = 9, Parent = socle}, {coin(0.5), filet(0.3, BLANC, 1.2),
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
	TweenService:Create(foyer, FAST, {BackgroundTransparency = 0.55}):Play()
end)
boutonSac.MouseLeave:Connect(function()
	balancer(false)
	TweenService:Create(foyer, FAST, {BackgroundTransparency = 0.8}):Play()
end)

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "Sac", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local boucles: {Tween} = {}
local flou = creer("BlurEffect", {Name = "FlouSac", Size = 0, Enabled = false, Parent = Lighting}) :: BlurEffect
local voile = creer("TextButton", {Name = "Voile", Text = "", AutoButtonColor = false, Selectable = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 4, 3), BackgroundTransparency = 1, Parent = gui},
	{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0.05)})})})
local fenetre = creer("Frame", {Name = "Fenetre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.96, 0.9), BackgroundTransparency = 1, Active = true, Parent = gui},
	{creer("UIAspectRatioConstraint", {AspectRatio = 1.78}), creer("UISizeConstraint", {MaxSize = Vector2.new(1180, 663)})})
local echelleFenetre = UI.echelle(fenetre)

-- Ombre portée douce + fond de verre fumé
creer("Frame", {Name = "Ombre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 24, 1, 24),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.6, Parent = fenetre}, {coin(0.05)})
local fond = creer("Frame", {Name = "Fond", Size = UDim2.fromScale(1, 1), BackgroundColor3 = FOND, BackgroundTransparency = 0.06,
	Parent = fenetre}, {coin(0.03), filet(0.78, LISERE, 1.5), relief(1.15, 0.6)})
do
	-- lueur chaude sous l'en-tête, braises en bas
	creer("Frame", {Size = UDim2.fromScale(1, 0.32), BackgroundColor3 = T.Braise, BackgroundTransparency = 0, BorderSizePixel = 0,
		Parent = fond}, {coin(0.095), creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1)})})})
	local bas = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.3),
		BackgroundColor3 = T.Braise, BorderSizePixel = 0, Parent = fond}, {coin(0.1)})
	local g = creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.9)}), Parent = bas})
	UI.boucle(g, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.12)}, boucles)
end
local particules = creer("Frame", {Name = "Braises", Position = UDim2.fromScale(0.03, 0.4), Size = UDim2.fromScale(0.94, 0.58),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = fond})
local function braise()
	local t = 0.003 + math.random() * 0.004
	local x = math.random()
	local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.02), Size = UDim2.fromScale(t, t),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(255, 150 + math.random(0, 90), 50 + math.random(0, 50)), Parent = particules}, {coin(0.5)})
	local duree = 2.4 + math.random() * 2
	TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.08, 0.3 + math.random() * 0.4),
		BackgroundTransparency = 1, Size = UDim2.fromScale(t * 0.3, t * 0.3)}):Play()
	Debris:AddItem(b, duree)
end

-- En-tête : accent doré, titre, sous-titre, bouton fermer
creer("Frame", {Position = UDim2.fromScale(0.022, 0.038), Size = UDim2.fromScale(0.0045, 0.07), BackgroundColor3 = T.Or,
	BorderSizePixel = 0, Parent = fenetre}, {coin(0.5), UI.degrade(Color3.fromRGB(255, 244, 200), Color3.fromRGB(200, 110, 30))})
local titre = texte({Text = "INVENTAIRE", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.035, 0.028), Size = UDim2.fromScale(0.4, 0.07), Parent = fenetre}, 40)
UI.dore(titre, 1.5)
local sousTitre = texte({Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.036, 0.096), Size = UDim2.fromScale(0.45, 0.03), Parent = fenetre}, 15)
local aideTouches = texte({Text = "[Échap] fermer", Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextTransparency = 0.35,
	TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.925, 0.075),
	Size = UDim2.fromScale(0.2, 0.03), Parent = fenetre}, 13)
aideTouches.Visible = not UserInputService.TouchEnabled
-- Bouton fermer : même croix que les autres interfaces (deux barres dessinées, aucun glyphe → jamais de rectangle vide)
local fermer = creer("TextButton", {Name = "Fermer", Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.978, 0.075),
	Size = UDim2.fromScale(0.07, 0.07), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(150, 44, 32),
	AutoButtonColor = false, Parent = fenetre}, {coin(0.5), trait(Color3.fromRGB(60, 16, 10), 3),
	UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))})
local barresCroix: {Frame} = {}
for _, angle in {45, -45} do
	table.insert(barresCroix, creer("Frame", {Name = "Croix", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.13), Rotation = angle, BackgroundColor3 = T.Parchemin, BorderSizePixel = 0,
		Parent = fermer}, {coin(0.5), trait(Color3.fromRGB(60, 16, 10), 1.5, 0.3)}))
end
UI.reactif(fermer, 1.1)
fermer.MouseEnter:Connect(function()
	TweenService:Create(barresCroix[1], FAST, {Rotation = 135}):Play()
	TweenService:Create(barresCroix[2], FAST, {Rotation = 45}):Play()
end)
fermer.MouseLeave:Connect(function()
	TweenService:Create(barresCroix[1], FAST, {Rotation = 45}):Play()
	TweenService:Create(barresCroix[2], FAST, {Rotation = -45}):Play()
end)
creer("Frame", {Position = UDim2.fromScale(0.02, 0.138), Size = UDim2.new(0.96, 0, 0, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0,
	Parent = fenetre}, {fonduBords(0.45)})

local function bloc(nom: string, pos: UDim2, taille: UDim2): Frame
	return creer("Frame", {Name = nom, Position = pos, Size = taille, BackgroundColor3 = CARTE, BackgroundTransparency = 0.35,
		Parent = fenetre}, {coin(0.04), filet(0.9), relief(1.1, 0.7)})
end

-- ================= Gauche : mannequin + emplacements =================
local gauche = bloc("Equipement", UDim2.fromScale(0.02, 0.162), UDim2.fromScale(0.27, 0.814))
titreSection(gauche, "ÉQUIPEMENT", UDim2.fromScale(0.06, 0.022), UDim2.fromScale(0.6, 0.038))
local compteEquip = texte({Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Right,
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.94, 0.024), Size = UDim2.fromScale(0.35, 0.034), Parent = gauche}, 13)
-- scène du personnage : halos, socle lumineux, vue 3D
local haloPerso = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.62, 0.62),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = T.Braise, BackgroundTransparency = 0.9, Parent = gauche}, {coin(0.5)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.4, 0.4),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.fromRGB(255, 190, 120), BackgroundTransparency = 0.9,
	Parent = gauche}, {coin(0.5)})
UI.boucle(haloPerso, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.95}, boucles)
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.715), Size = UDim2.fromScale(0.5, 0.05),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.35, Parent = gauche}, {coin(0.5), fonduBords(0)})
local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.715), Size = UDim2.fromScale(0.56, 0.06),
	BackgroundTransparency = 1, Parent = gauche}, {coin(0.5), filet(0.55, T.Or, 1.5)})
UI.boucle(anneau:FindFirstChildOfClass("UIStroke") :: UIStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{Transparency = 0.85}, boucles)
local vue = creer("ViewportFrame", {Name = "Perso", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.075),
	Size = UDim2.fromScale(0.58, 0.66), BackgroundTransparency = 1, Ambient = Color3.fromRGB(150, 130, 115),
	LightColor = Color3.fromRGB(255, 225, 185), LightDirection = Vector3.new(-0.6, -1, -0.8), Parent = gauche})
local monde = creer("WorldModel", {Parent = vue})
local cameraVue = creer("Camera", {FieldOfView = 30, Parent = vue})
vue.CurrentCamera = cameraVue
-- Zone de glisser au-dessus du perso : capte le clic (il ne traverse jamais vers le voile)
local zoneGlisser = creer("TextButton", {Name = "ZoneGlisser", Text = "", AutoButtonColor = false, Selectable = false, BackgroundTransparency = 1,
	AnchorPoint = vue.AnchorPoint, Position = vue.Position, Size = vue.Size, Parent = gauche})
local astuce = texte({Text = "glisse pour tourner", Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextTransparency = 0.4,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.068), Size = UDim2.fromScale(0.5, 0.028), Parent = gauche}, 12)
local nomPerso = texte({Text = joueur.DisplayName, Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.745), Size = UDim2.fromScale(0.8, 0.048), Parent = gauche}, 22)
UI.dore(nomPerso, 1.2)

-- Emplacements
type SlotUI = {bouton: TextButton, fond: Frame, bord: UIStroke, reflet: UIGradient, vp: ViewportFrame, halo: Frame, sel: Frame,
	flash: Frame, nom: TextLabel}
local slotsUI: {[string]: SlotUI} = {}
local TAILLE_SLOT = 0.2 -- en largeur du panneau
for i, e in EMPLACEMENTS do
	local y = 0.11 + e.rang * 0.21
	local b = creer("TextButton", {Name = e.id, LayoutOrder = i, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(e.cote, 0), Position = UDim2.fromScale(if e.cote == 0 then 0.035 else 0.965, y),
		Size = UDim2.fromScale(TAILLE_SLOT, TAILLE_SLOT), SizeConstraint = Enum.SizeConstraint.RelativeXX, Parent = gauche})
	-- trait fin qui relie l'emplacement au mannequin
	creer("Frame", {AnchorPoint = Vector2.new(e.cote, 0.5), Position = UDim2.fromScale(if e.cote == 0 then 1.05 else -0.05, 0.5),
		Size = UDim2.new(0.32, 0, 0, 1), BackgroundColor3 = LISERE, BorderSizePixel = 0, Parent = b},
		{creer("UIGradient", {Rotation = if e.cote == 0 then 0 else 180, Transparency = NumberSequence.new(0.7, 1)})})
	local fond = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = CREUX, BackgroundTransparency = 0.1, Parent = b},
		{coin(0.24), relief(1.4, 0.8)})
	local bord = filet(0.82, LISERE, 1.5)
	bord.Name = "Bord"
	bord.Parent = fond
	local reflet = refletTournant(bord)
	reflet.Enabled = false
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82),
		BackgroundColor3 = T.Gris, BackgroundTransparency = 1, Parent = fond}, {coin(0.5)})
	local vp = Icones.creer(fond)
	local sel = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = fond},
		{coin(0.24), trait(T.Or, 2.5)})
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 1, Parent = fond}, {coin(0.24)})
	if e.id == "Libre" then -- cadenas
		vp.Visible = false
		fond.BackgroundTransparency = 0.45
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.28, 0.28),
			BackgroundTransparency = 1, Parent = fond}, {coin(0.5), trait(DISCRET, 2.5, 0.5)})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.4, 0.3),
			BackgroundColor3 = DISCRET, BackgroundTransparency = 0.45, Parent = fond}, {coin(0.25)})
	end
	local nom = texte({Text = e.nom, Font = Enum.Font.GothamBold, TextColor3 = DISCRET, Position = UDim2.fromScale(-0.1, 1.04),
		Size = UDim2.fromScale(1.2, 0.2), Parent = b}, 12)
	UI.reactif(b, 1.08, fond)
	b.MouseEnter:Connect(function()
		vitesseIcone(vp, 1.8)
	end)
	b.MouseLeave:Connect(function()
		vitesseIcone(vp, 0)
	end)
	slotsUI[e.id] = {bouton = b, fond = fond, bord = bord, reflet = reflet, vp = vp, halo = halo, sel = sel, flash = flash, nom = nom}
end

-- Stats totales : 4 pastilles (2 × 2)
type Pastille = {regler: (number, boolean?) -> ()}
local function pastille(nom: string, couleur: Color3, col: number, ligne: number, format: (number) -> string): Pastille
	local p = creer("Frame", {Position = UDim2.fromScale(0.04 + col * 0.47, 0.81 + ligne * 0.088), Size = UDim2.fromScale(0.45, 0.074),
		BackgroundColor3 = CREUX, BackgroundTransparency = 0.15, Parent = gauche}, {coin(0.3), filet(0.9)})
	creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.03, 0.5),
		BackgroundColor3 = couleur, BorderSizePixel = 0, Parent = p}, {coin(0.5)})
	texte({Text = nom, Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.13, 0.27), Size = UDim2.fromScale(0.45, 0.46), Parent = p}, 11)
	local v = texte({Font = Enum.Font.GothamBlack, TextColor3 = couleur:Lerp(BLANC, 0.45), TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.44, 0.64), Parent = p}, 18)
	return {regler = UI.compteur(v, format)}
end
local function entier(n: number): string
	return tostring(math.floor(n + 0.5))
end
local statVie = pastille("VIE", Color3.fromRGB(236, 84, 96), 0, 0, entier)
local statDefense = pastille("DÉFENSE", Color3.fromRGB(110, 170, 255), 1, 0, entier)
local statDegats = pastille("DÉGÂTS", Color3.fromRGB(255, 140, 60), 0, 1, entier)
local statPuissance = pastille("PUISSANCE", T.Or, 1, 1, function(n)
	return "×" .. tostring(math.floor(n * 10 + 0.5) / 10)
end)

-- ================= Centre : onglets, tri, grille =================
local centre = creer("Frame", {Name = "SacGrille", Position = UDim2.fromScale(0.305, 0.162), Size = UDim2.fromScale(0.415, 0.814),
	BackgroundTransparency = 1, Parent = fenetre})
local rangeeOnglets = creer("Frame", {Size = UDim2.fromScale(0.76, 0.068), BackgroundTransparency = 1, Parent = centre},
	{creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.016, 0), SortOrder = Enum.SortOrder.LayoutOrder})})
type Onglet = {bouton: TextButton, texte: TextLabel, trait: Frame, bord: UIStroke}
local onglets: {[string]: Onglet} = {}
local categorie = "tout"
local tri = "Type"
for i, c in CATEGORIES do
	local b = creer("TextButton", {Name = c.id, LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.238, 1),
		BackgroundColor3 = CARTE, BackgroundTransparency = 0.3, Parent = rangeeOnglets}, {coin(0.3)})
	local bord = filet(0.88)
	bord.Parent = b
	local l = texte({Text = c.nom, RichText = true, Font = Enum.Font.GothamBold, TextColor3 = DISCRET, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.5), Parent = b}, 14)
	local souligne = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = b}, {coin(0.5)})
	UI.reactif(b, 1.05)
	onglets[c.id] = {bouton = b, texte = l, trait = souligne, bord = bord}
end
local boutonTri = creer("TextButton", {Name = "Tri", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.22, 0.068), BackgroundColor3 = CARTE, BackgroundTransparency = 0.3,
	Parent = centre}, {coin(0.3), filet(0.88)})
local texteTri = texte({RichText = true, Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.46), Parent = boutonTri}, 13)
UI.reactif(boutonTri, 1.05)

local grille = creer("ScrollingFrame", {Name = "Grille", Position = UDim2.fromScale(0, 0.088), Size = UDim2.fromScale(1, 0.912),
	BackgroundColor3 = CREUX, BackgroundTransparency = 0.3, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = T.Or, ScrollBarImageTransparency = 0.4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, Selectable = false, Parent = centre}, {coin(0.035), filet(0.9),
	creer("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})})
local ECART = 8
local disposition = creer("UIGridLayout", {CellPadding = UDim2.fromOffset(ECART, ECART), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grille})
local function ajusterGrille()
	local l = grille.AbsoluteSize.X - 24
	local colonnes = math.clamp(math.floor((l + ECART) / 84), 4, 7)
	local c = math.max(30, math.floor((l - ECART * (colonnes - 1)) / colonnes))
	disposition.CellSize = UDim2.fromOffset(c, c)
end
grille:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajusterGrille)
local videGrille = texte({Font = Enum.Font.GothamBold, TextColor3 = DISCRET, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.06), Parent = centre}, 17)

-- ================= Droite : détail =================
local droite = bloc("Detail", UDim2.fromScale(0.735, 0.162), UDim2.fromScale(0.245, 0.814))
local videDetail = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = droite})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.42, 0.42),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1, Parent = videDetail}, {coin(0.24), trait(DISCRET, 2, 0.6)})
texte({Text = "?", Font = Enum.Font.GothamBlack, TextColor3 = DISCRET, TextTransparency = 0.5, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.3, 0.1), Parent = videDetail}, 48)
texte({Text = "Choisis un objet", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.08, 0.56),
	Size = UDim2.fromScale(0.84, 0.045), Parent = videDetail}, 18)
texte({Text = "Touche une case du sac ou un emplacement pour voir ses détails.", Font = Enum.Font.GothamBold, TextColor3 = DISCRET,
	TextWrapped = true, Position = UDim2.fromScale(0.1, 0.615), Size = UDim2.fromScale(0.8, 0.08), Parent = videDetail}, 13)

local contenuDetail = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = droite})
local scene = creer("Frame", {Name = "Apercu", Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.9, 0.42),
	BackgroundColor3 = CREUX, BackgroundTransparency = 0.15, Parent = contenuDetail}, {coin(0.08), relief(1.6, 0.8)})
local bordScene = filet(0.6, T.Gris, 1.5)
bordScene.Parent = scene
local refletScene = refletTournant(bordScene)
local haloDetail = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.86, 0.86),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Gris, BackgroundTransparency = 0.84, Parent = scene}, {coin(0.5)})
local coeurDetail = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.5, 0.5),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Gris, BackgroundTransparency = 0.78, Parent = scene}, {coin(0.5)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.5, 0.06),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.4, Parent = scene}, {coin(0.5), fonduBords(0)})
local vpDetail = Icones.creer(scene)
vpDetail.Size = UDim2.fromScale(0.94, 0.94)
vpDetail.AnchorPoint = Vector2.new(0.5, 0.5)
vpDetail.Position = UDim2.fromScale(0.5, 0.5)
local tagRarete = creer("Frame", {Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.44, 0.1), BackgroundColor3 = T.Gris,
	BackgroundTransparency = 0.75, Parent = scene}, {coin(0.5)})
local bordTag = filet(0.3, T.Gris, 1)
bordTag.Parent = tagRarete
local texteRarete = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.08, 0.18), Size = UDim2.fromScale(0.84, 0.64),
	Parent = tagRarete}, 12)
local tagCoin = creer("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.95, 0.05), Size = UDim2.fromScale(0.3, 0.1),
	BackgroundColor3 = CREUX, BackgroundTransparency = 0.2, Parent = scene}, {coin(0.5), filet(0.75)})
local texteCoin = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.08, 0.18),
	Size = UDim2.fromScale(0.84, 0.64), Parent = tagCoin}, 13)

local nomDetail = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.06, 0.465),
	Size = UDim2.fromScale(0.88, 0.062), Parent = contenuDetail}, 26)
creer("UIStroke", {Thickness = 1.2, Color = NOIR, Transparency = 0.4, Parent = nomDetail})
local infoDetail = texte({Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.06, 0.53), Size = UDim2.fromScale(0.88, 0.032), Parent = contenuDetail}, 13)
creer("Frame", {Position = UDim2.fromScale(0.06, 0.58), Size = UDim2.new(0.88, 0, 0, 1), BackgroundColor3 = LISERE, BorderSizePixel = 0,
	Parent = contenuDetail}, {fonduBords(0.75)})

-- Barres de stats (3 lignes réutilisées)
type Barre = {cadre: Frame, nom: TextLabel, valeur: TextLabel, rempli: Frame, tween: Tween?}
local barres: {Barre} = {}
for i = 1, 3 do
	local cadre = creer("Frame", {Position = UDim2.fromScale(0.06, 0.598 + (i - 1) * 0.074), Size = UDim2.fromScale(0.88, 0.062),
		BackgroundTransparency = 1, Parent = contenuDetail})
	local nom = texte({Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.6, 0.46), Parent = cadre}, 12)
	local valeur = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.5, 0.5), Parent = cadre}, 14)
	local rail = creer("Frame", {Position = UDim2.fromScale(0, 0.62), Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = NOIR,
		BackgroundTransparency = 0.35, ClipsDescendants = true, Parent = cadre}, {coin(0.5)})
	local rempli = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = rail},
		{coin(0.5), creer("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(170, 170, 170), BLANC)})})
	table.insert(barres, {cadre = cadre, nom = nom, valeur = valeur, rempli = rempli, tween = nil})
end
local function regler(i: number, nom: string?, valeur: string?, fraction: number?, couleur: Color3?, depuisZero: boolean?)
	local b = barres[i]
	b.cadre.Visible = nom ~= nil
	if not nom then
		return
	end
	b.nom.Text = string.upper(nom)
	b.valeur.Text = valeur or ""
	b.rempli.BackgroundColor3 = couleur or T.Or
	if b.tween then
		(b.tween :: Tween):Cancel()
	end
	if depuisZero then
		b.rempli.Size = UDim2.fromScale(0, 1)
	end
	local t = TweenService:Create(b.rempli, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, (i - 1) * 0.06),
		{Size = UDim2.fromScale(math.clamp(fraction or 0, 0.03, 1), 1)})
	b.tween = t
	t:Play()
end

local compo = creer("Frame", {Name = "Composition", Position = UDim2.fromScale(0.06, 0.83), Size = UDim2.fromScale(0.88, 0.052),
	BackgroundTransparency = 1, Parent = contenuDetail}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center})})
local principal = UI.boutonPrincipal({Name = "Equiper", Position = UDim2.fromScale(0.06, 0.9), Size = UDim2.fromScale(0.88, 0.074),
	Parent = contenuDetail}, boucles)
local boutonEquiper = principal.bouton

-- Bulle au survol et message
local bulle = texte({RichText = true, Font = Enum.Font.GothamBold, BackgroundColor3 = CREUX, Visible = false,
	AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28), ZIndex = 30, Parent = gui}, 15)
bulle.BackgroundTransparency = 0.08
bulle.TextScaled = false
bulle.TextSize = 15
creer("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = bulle})
coin(0.3).Parent = bulle
local bordBulle = filet(0.5, T.Or, 1.2)
bordBulle.Parent = bulle
local message = UI.toast(gui)

local function montrerBulle(nom: string, nomR: string, couleur: Color3)
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return
	end
	local p = UserInputService:GetMouseLocation()
	bulle.Text = string.format('<b>%s</b>   <font color="#%s">%s</font>', nom, couleur:Lerp(BLANC, 0.2):ToHex(), nomR)
	bulle.TextColor3 = T.Parchemin
	bordBulle.Color = couleur
	bulle.Position = UDim2.fromOffset(p.X + 16, p.Y + 8)
	bulle.Visible = true
end

-- ================= État =================
local etat: Etat = {minerais = {}, objets = {}, equipement = {}}
local ouverte = false
local sale = true -- l'état a changé pendant que le sac était fermé
local selection: string? = nil -- "m:<minerai>", "o:<id objet>", "p" (pioche)
local survol: string? = nil
local enAttente = false
local sansSurgir = false -- réponse d'équiper / retirer : la case revenue vole, elle ne « surgit » pas
type Case = {bouton: TextButton, carte: Frame, echelle: UIScale, apparition: UIScale, vp: ViewportFrame, halo: Frame, bord: UIStroke,
	reflet: UIGradient?, sel: Frame, quantite: TextLabel?, categorie: string, niveau: number, ordre: number, q: number, phase: number,
	nom: string, nomR: string, couleur: Color3}
local cases: {[string]: Case} = {}
local brillants: {[string]: Case} = {} -- cases Épique+ (lueur animée)
local pulsants: {[GuiObject]: {base: number, amp: number}} = {}
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

-- Style d'une case selon survol / sélection : agrandie, liseré allumé, icône qui tourne
local function styleCase(cle: string)
	local c = cases[cle]
	if not c then
		return
	end
	local actif = survol == cle
	local fort = actif or selection == cle
	TweenService:Create(c.echelle, SURVOL, {Scale = if actif then 1.08 else 1}):Play()
	TweenService:Create(c.bord, SURVOL, {Thickness = if fort then 2.5 else 1.5, Transparency = if fort then 0 else (if c.niveau >= 2 then 0.35 else 0.6)}):Play()
	if not brillants[cle] then
		TweenService:Create(c.halo, SURVOL, {BackgroundTransparency = if fort then 0.62 else 0.84}):Play()
	end
	vitesseIcone(c.vp, if fort then 1.8 else 0)
end

-- Survol (souris) ou sélection manette
local function survolerCase(cle: string, actif: boolean)
	local c = cases[cle]
	if not c then
		return
	end
	if actif then
		survol = cle
		jouer("survol", 1.6)
		montrerBulle(c.nom, c.nomR, c.couleur)
	elseif survol == cle then
		survol = nil
		bulle.Visible = false
	end
	styleCase(cle)
end

local function nouvelleCase(cle: string, nom: string, nomR: string, couleurR: Color3, niveau: number, categorieCase: string,
	dessiner: (ViewportFrame) -> (), avecQuantite: boolean): Case
	local b = creer("TextButton", {Name = cle, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Parent = grille})
	local apparition = creer("UIScale", {Name = "Apparition", Parent = b})
	local carte = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = couleurR:Lerp(CARTE, 0.8), Parent = b},
		{coin(0.18), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), BLANC)})})
	local echelle = UI.echelle(carte)
	local bord = filet(if niveau >= 2 then 0.35 else 0.6, couleurR, 1.5)
	bord.Parent = carte
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.74, 0.74),
		BackgroundColor3 = couleurR, BackgroundTransparency = 0.84, Parent = carte}, {coin(0.5)})
	-- liseré de rareté en bas de la case
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.97), Size = UDim2.fromScale(0.6, 0.045),
		BackgroundColor3 = couleurR, BorderSizePixel = 0, Parent = carte}, {coin(0.5), fonduBords(0)})
	local vp = Icones.creer(carte)
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.47)
	vp.Size = UDim2.fromScale(0.9, 0.9)
	dessiner(vp)
	local sel = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = carte},
		{coin(0.18), trait(T.Or, 2.5)})
	local q: TextLabel? = nil
	if avecQuantite then
		local pastilleQ = creer("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.96, 0.04), Size = UDim2.fromScale(0.5, 0.25),
			BackgroundColor3 = CREUX, BackgroundTransparency = 0.12, Parent = carte}, {coin(0.5), filet(0.55, couleurR, 1)})
		q = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.1, 0.14), Size = UDim2.fromScale(0.8, 0.72),
			Parent = pastilleQ}, 14)
	end
	local reflet: UIGradient? = nil
	if niveau >= 3 then
		reflet = refletTournant(bord)
	end
	local c: Case = {bouton = b, carte = carte, echelle = echelle, apparition = apparition, vp = vp, halo = halo, bord = bord, reflet = reflet,
		sel = sel, quantite = q, categorie = categorieCase, niveau = niveau, ordre = 0, q = 1, phase = math.random() * 6.28,
		nom = nom, nomR = nomR, couleur = couleurR}
	cases[cle] = c
	if niveau >= NIVEAU_LUEUR then
		brillants[cle] = c
	end
	b.MouseEnter:Connect(function()
		survolerCase(cle, true)
	end)
	b.MouseLeave:Connect(function()
		survolerCase(cle, false)
	end)
	b.SelectionGained:Connect(function()
		survolerCase(cle, true)
	end)
	b.SelectionLost:Connect(function()
		survolerCase(cle, false)
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(echelle, TweenInfo.new(0.08), {Scale = 0.94}):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(echelle, UI.BOUNCY, {Scale = if survol == cle then 1.08 else 1}):Play()
	end)
	b.Activated:Connect(function()
		choisir(cle)
	end)
	return c
end

-- Surlignage de la sélection (grille + emplacements), sans rien reconstruire
local function surligner()
	for cle, c in cases do
		local choisi = cle == selection
		if c.sel.Visible ~= choisi then
			c.sel.Visible = choisi
			styleCase(cle)
		end
	end
	for id, s in slotsUI do
		local equipe = etat.equipement[id]
		s.sel.Visible = (id == "Pioche" and selection == "p") or (equipe ~= nil and selection == "o:" .. equipe)
	end
end

-- ---- Filtre (onglet) et tri : Visible + LayoutOrder, aucune case recréée ----
local function ordreTri(c: Case): number
	if tri == "Rareté" then
		return (10 - c.niveau) * 100000 + c.ordre
	elseif tri == "Quantité" then
		return (99999 - math.min(c.q, 99999)) * 5000 + c.ordre
	end
	return c.ordre
end

local function appliquerFiltre()
	local comptes = {tout = 0, minerai = 0, arme = 0, armure = 0}
	local visibles = 0
	for _, c in cases do
		comptes.tout += 1
		comptes[c.categorie] = (comptes[c.categorie] or 0) + 1
		local v = categorie == "tout" or c.categorie == categorie
		c.bouton.Visible = v
		c.bouton.LayoutOrder = ordreTri(c)
		visibles += if v then 1 else 0
	end
	for _, cat in CATEGORIES do
		local o = onglets[cat.id]
		local actif = cat.id == categorie
		o.texte.Text = string.format('%s <font color="#%s">%d</font>', cat.nom, (if actif then T.Parchemin else DISCRET):ToHex(),
			comptes[cat.id] or 0)
		o.texte.TextColor3 = if actif then T.Or else DISCRET
		TweenService:Create(o.bouton, SURVOL, {BackgroundTransparency = if actif then 0.05 else 0.3,
			BackgroundColor3 = if actif then Color3.fromRGB(64, 46, 28) else CARTE}):Play()
		TweenService:Create(o.trait, DOUX, {Size = if actif then UDim2.new(0.6, 0, 0, 2) else UDim2.new(0, 0, 0, 2)}):Play()
		o.bord.Color = if actif then T.Or else LISERE
		o.bord.Transparency = if actif then 0.45 else 0.88
	end
	texteTri.Text = string.format('<font color="#%s">Tri :</font> %s', DISCRET:ToHex(), tri)
	videGrille.Visible = visibles == 0
	videGrille.Text = if comptes.tout == 0 then "Ton sac est vide : va miner !" else "Rien dans cette catégorie"
end

-- Cascade : les cases visibles apparaissent l'une après l'autre (ordre d'affichage)
local function cascade()
	local liste = {}
	for _, c in cases do
		if c.bouton.Visible then
			table.insert(liste, c)
		end
	end
	table.sort(liste, function(a, b)
		return a.bouton.LayoutOrder < b.bouton.LayoutOrder
	end)
	for i, c in liste do
		c.apparition.Scale = 0
		TweenService:Create(c.apparition, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false,
			math.min(i - 1, 28) * 0.022), {Scale = 1}):Play()
	end
end

local function rafraichirGrille()
	local vus: {[string]: boolean} = {}
	local nouvelles: {Case} = {}
	for i, id in Forge.ORDRE_SAC do
		local q = etat.minerais[id] or 0
		if q > 0 then
			local cle = "m:" .. id
			vus[cle] = true
			local c = cases[cle]
			if not c then
				local m = Forge.MINERAIS[id]
				local nomR, couleurR, niveau = rareteMinerai(id)
				c = nouvelleCase(cle, m.nom, nomR, couleurR, niveau, "minerai", function(vp)
					Icones.definir(vp, "minerai", id, {vitesse = 0, hauteur = 0.35, marge = 0.85})
				end, true)
				table.insert(nouvelles, c)
			end
			c.ordre, c.q = i, q
			local l = c.quantite
			local txt = "×" .. abrege(q)
			if l and l.Text ~= txt then
				local avant = l.Text
				l.Text = txt
				if avant ~= "" and ouverte then
					pop(l, 0.6)
				end
			end
		end
	end
	local nbObjets = #etat.objets
	for i, o in etat.objets do
		if not estEquipe(o) then
			local cle = "o:" .. o.id
			vus[cle] = true
			local c = cases[cle]
			if not c then
				local nomR, couleurR, niveau = rareteObjet(o)
				local teinte = couleurHex(o.couleur)
				c = nouvelleCase(cle, o.nom, nomR, couleurR, niveau, CATEGORIE_TYPE[o.type] or "arme", function(vp)
					iconeObjet(vp, o.type, teinte, {vitesse = 0}, o.modele)
				end, false)
				table.insert(nouvelles, c)
			end
			c.ordre, c.q = 1000 + (nbObjets - i), 1
		end
	end
	for cle, c in cases do
		if not vus[cle] then
			c.bouton:Destroy()
			cases[cle] = nil
			brillants[cle] = nil
			if survol == cle then
				survol = nil
				bulle.Visible = false
			end
		end
	end
	appliquerFiltre()
	if ouverte and not sansSurgir then -- nouvelle case pendant que le sac est ouvert : elle surgit
		for _, c in nouvelles do
			c.apparition.Scale = 0
			TweenService:Create(c.apparition, UI.BOUNCY, {Scale = 1}):Play()
		end
	end
	local total = totalMinerais()
	sousTitre.Text = string.format("%d minerai%s  ·  %d objet%s forgé%s", total, if total > 1 then "s" else "",
		nbObjets, if nbObjets > 1 then "s" else "", if nbObjets > 1 then "s" else "")
	local sel = selection
	if sel and sel:sub(1, 2) == "m:" and not cases[sel] then
		selection = nil
	elseif sel and sel:sub(1, 2) == "o:" and not objetParId(sel:sub(3)) then
		selection = nil
	end
end

local function vieMax(): number
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	return if h then h.MaxHealth else 0
end

local function rafraichirEquipement(instantane: boolean?)
	local pioche = Pioches.get(joueur:GetAttribute("Pioche"))
	local nb, defense, degats = 0, 0, 0
	for _, e in EMPLACEMENTS do
		local s = slotsUI[e.id]
		if e.id == "Libre" then
			continue
		end
		local couleurR, niveau, plein, _nomR = T.Gris, 1, false, ""
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
				if o.type == "Epee" then
					degats += o.valeur
				else
					defense += o.valeur
				end
			else
				iconeObjet(s.vp, e.id, ACIER, {vitesse = 0, silhouette = true})
			end
		end
		nb += if plein then 1 else 0
		s.vp.ImageTransparency = if plein then 0 else 0.55
		s.bord.Color = if plein then couleurR else LISERE
		s.bord.Transparency = if plein then 0.1 else 0.82
		s.bord.Thickness = if plein then 2 else 1.5
		s.reflet.Enabled = plein and niveau >= 3
		s.halo.BackgroundColor3 = couleurR
		s.halo.BackgroundTransparency = if plein then 0.74 else 1
		pulsants[s.halo] = if plein and niveau >= NIVEAU_LUEUR then {base = 0.72, amp = 0.1} else nil
		s.fond.BackgroundColor3 = if plein then couleurR:Lerp(CREUX, 0.82) else CREUX
		s.nom.TextColor3 = if plein then couleurR:Lerp(BLANC, 0.35) else DISCRET
	end
	compteEquip.Text = string.format("%d / 5", nb)
	statVie.regler(vieMax(), instantane)
	statDefense.regler(defense, instantane)
	statDegats.regler(degats, instantane)
	statPuissance.regler(if pioche then pioche.puissance else 0, instantane)
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
		texte({Text = astuceTexte or "", Font = Enum.Font.GothamBold, TextColor3 = DISCRET, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0.8), Parent = compo}, 13)
		return
	end
	for i, e in liste do
		local id, q = tostring(e[1]), tonumber(e[2]) or 0
		local m = Forge.MINERAIS[id]
		local _, couleurR = rareteMinerai(id)
		local puce = creer("Frame", {LayoutOrder = i, Size = UDim2.fromScale(2.3, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = CREUX, BackgroundTransparency = 0.2, Parent = compo}, {coin(0.5), filet(0.4, couleurR, 1)})
		local rond = creer("Frame", {Size = UDim2.fromScale(1, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = couleurR, BackgroundTransparency = 0.7, Parent = puce}, {coin(0.5)})
		if m then
			Icones.minerai(id, rond, {vitesse = 0, hauteur = 0.35, marge = 0.8})
		end
		texte({Text = "×" .. q, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.47, 0.18), Size = UDim2.fromScale(0.48, 0.64), Parent = puce}, 13)
	end
end

local cleDetail: string? = nil
local function rafraichirDetail()
	local cle = selection
	surligner()
	contenuDetail.Visible = cle ~= nil
	videDetail.Visible = cle == nil
	if not cle then
		cleDetail = nil
		pulsants[haloDetail] = nil
		return
	end
	local nouveau = cle ~= cleDetail
	cleDetail = cle
	local couleurR, niveau, nomRarete = T.Gris, 1, "Commun"
	local action: string? = nil
	local coinTexte: string? = nil
	if cle == "p" then
		local def = Pioches.get(joueur:GetAttribute("Pioche"))
		Icones.definir(vpDetail, "pioche", if def then def.id else Pioches.DEPART, {vitesse = 0.8, hauteur = 0.15, marge = 0.85})
		if def then
			nomRarete, couleurR, niveau = rarete(def.rarete)
		end
		nomDetail.Text = if def then def.nom else "Aucune pioche"
		infoDetail.Text = "Pioche"
		coinTexte = "ÉQUIPÉE"
		regler(1, "Puissance", if def then "×" .. tostring(def.puissance) else "—", if def then def.puissance / PUISSANCE_MAX else 0, couleurR, nouveau)
		regler(2)
		regler(3)
		definirCompo(nil, "Change de pioche chez Liesel")
	elseif cle:sub(1, 2) == "m:" then
		local id = cle:sub(3)
		local m = Forge.MINERAIS[id]
		local q = etat.minerais[id] or 0
		local prix = PrixMinerais.get(id) or 0
		Icones.definir(vpDetail, "minerai", id, {vitesse = 0.8, hauteur = 0.35, marge = 0.85})
		nomRarete, couleurR, niveau = rareteMinerai(id)
		nomDetail.Text = m.nom
		infoDetail.Text = "Minerai"
		coinTexte = "×" .. abrege(q)
		if (m :: any).forgeable == false then -- nouveaux minerais de la mine privée : vente seulement pour l'instant
			regler(1, "Valeur", UI.milliers(prix) .. " pièces", prix / PRIX_MAX, couleurR, nouveau)
			regler(2, "Total du stock", UI.milliers(prix * q) .. " pièces", 1, T.Or, nouveau)
			regler(3)
			definirCompo(nil, "À vendre à Gaspard (pas encore forgeable)")
		else
			regler(1, "Force", tostring(m.force), m.force / FORCE_MAX, couleurR, nouveau)
			regler(2, "Valeur", UI.milliers(prix) .. " pièces", prix / PRIX_MAX, T.Or, nouveau)
			regler(3)
			definirCompo(nil, "À mélanger chez Brom le forgeron")
		end
	else
		local o = objetParId(cle:sub(3))
		if not o then
			contenuDetail.Visible = false
			videDetail.Visible = true
			return
		end
		local t = Forge.TYPES[o.type]
		iconeObjet(vpDetail, o.type, couleurHex(o.couleur), {vitesse = 0.8}, o.modele)
		nomRarete, couleurR, niveau = rareteObjet(o)
		nomDetail.Text = o.nom
		local echelle = Forge.ECHELLES[o.type]
		infoDetail.Text = if t then t.nom else o.type
		coinTexte = if estEquipe(o) then "ÉQUIPÉ" else nil
		regler(1, o.stat, "+" .. tostring(o.valeur), o.valeur / statMax(o.type), couleurR, nouveau)
		if o.rang and echelle then
			regler(2, "Rang", string.format("%d / %d", o.rang, #echelle), o.rang / #echelle, T.Or, nouveau)
		else
			regler(2)
		end
		regler(3)
		definirCompo(o.composition)
		action = if estEquipe(o) then "retirer" else "equiper"
	end
	nomDetail.TextColor3 = couleurR:Lerp(BLANC, 0.55)
	texteRarete.Text = string.upper(nomRarete)
	texteRarete.TextColor3 = couleurR:Lerp(BLANC, 0.3)
	tagRarete.BackgroundColor3 = couleurR
	bordTag.Color = couleurR
	tagCoin.Visible = coinTexte ~= nil
	texteCoin.Text = coinTexte or ""
	texteCoin.TextColor3 = if coinTexte and coinTexte:find("QUIP") then T.Vert else T.Parchemin
	haloDetail.BackgroundColor3 = couleurR
	coeurDetail.BackgroundColor3 = couleurR
	bordScene.Color = couleurR
	bordScene.Transparency = if niveau >= 2 then 0.25 else 0.6
	refletScene.Enabled = niveau >= 3
	pulsants[haloDetail] = if niveau >= NIVEAU_LUEUR then {base = 0.76, amp = 0.08} else nil
	if niveau < NIVEAU_LUEUR then
		haloDetail.BackgroundTransparency = 0.84
	end
	boutonEquiper.Visible = action ~= nil
	if action then
		principal.definir(if enAttente then "…" elseif action == "equiper" then "ÉQUIPER" else "RETIRER",
			if action == "equiper" then T.Vert else Color3.fromRGB(196, 104, 64), not enAttente)
	end
	if nouveau then
		pop(scene, 0.88)
		nomDetail.Position = UDim2.fromScale(0.1, 0.465)
		nomDetail.TextTransparency = 1
		TweenService:Create(nomDetail, DOUX, {Position = UDim2.fromScale(0.06, 0.465), TextTransparency = 0}):Play()
	end
end

choisir = function(cle: string?)
	if selection ~= cle then
		selection = cle
		jouer("clic", 1.15)
		local c = cle and cases[cle]
		if c then
			pop(c.carte, 0.88)
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
-- Éclair blanc + onde de choc sur l'emplacement, le mannequin s'illumine à la couleur de la rareté
local function eclair(s: SlotUI, couleurR: Color3)
	s.flash.BackgroundTransparency = 0.1
	TweenService:Create(s.flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	local onde = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Parent = s.fond}, {coin(0.24)})
	local t = trait(couleurR:Lerp(BLANC, 0.3), 3)
	t.Parent = onde
	TweenService:Create(onde, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1.7, 1.7)}):Play()
	TweenService:Create(t, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Thickness = 1}):Play()
	Debris:AddItem(onde, 0.6)
	haloPerso.BackgroundColor3 = couleurR
	haloPerso.BackgroundTransparency = 0.55
	TweenService:Create(haloPerso, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.9}):Play()
	task.delay(0.9, function()
		haloPerso.BackgroundColor3 = T.Braise
	end)
end

local function voler(p0: Vector2, s0: Vector2, cible: GuiObject, dessiner: (ViewportFrame) -> (), couleurR: Color3, cacher: ViewportFrame?,
	slot: SlotUI?)
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
			if slot then
				eclair(slot, couleurR)
			end
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
	local depart: GuiObject? = if action == "equiper" then (cases[cle] and cases[cle].carte) else (s and s.fond)
	local p0, s0 = if depart then depart.AbsolutePosition else Vector2.zero, if depart then depart.AbsoluteSize else Vector2.zero
	enAttente = true
	rafraichirDetail()
	local ok, rep = pcall(function()
		return fnAction:InvokeServer({action = action, slot = slot, id = o.id})
	end)
	enAttente = false
	if ok and type(rep) == "table" then
		sansSurgir = true
		recevoir(rep.etat)
		sansSurgir = false
		if rep.ok then
			local _, couleurR = rareteObjet(o)
			local teinte = couleurHex(o.couleur)
			local function dessiner(vp: ViewportFrame)
				iconeObjet(vp, o.type, teinte, {vitesse = 0}, o.modele)
			end
			if action == "equiper" and s then
				if depart then
					voler(p0, s0, s.fond, dessiner, couleurR, s.vp, s)
				else
					pop(s.fond)
					eclair(s, couleurR)
					jouer("metal", 1.15)
				end
				local revenu = ancien and cases["o:" .. ancien]
				if revenu then
					pop(revenu.carte, 0.5)
				end
			else
				task.wait() -- la grille place la nouvelle case
				local c = cases[cle]
				if c and depart and c.bouton.Visible then
					voler(p0, s0, c.carte, dessiner, couleurR, c.vp)
				else
					jouer("metal", 1)
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

-- Onglets et tri
local function choisirCategorie(id: string)
	if id == categorie then
		return
	end
	categorie = id
	jouer("clic", 1.25)
	appliquerFiltre()
	cascade()
	grille.CanvasPosition = Vector2.zero
end
for id, o in onglets do
	o.bouton.Activated:Connect(function()
		choisirCategorie(id)
	end)
end
local function trierSuivant()
	local i = table.find(TRIS, tri) or 1
	tri = TRIS[i % #TRIS + 1]
	jouer("clic", 1.35)
	pop(boutonTri, 0.9)
	appliquerFiltre()
	cascade()
end
boutonTri.Activated:Connect(trierSuivant)

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
	local distance = (taille.Y * 0.62) / math.tan(math.rad(cameraVue.FieldOfView / 2))
	cameraVue.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, taille.Y * 0.05, distance), cf.Position)
	clone = m
end

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
			bulle.Position = UDim2.fromOffset(p.X + 16, p.Y + 8)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		glisse = nil
	end
end)

-- Battement unique (fenêtre ouverte seulement) : perso qui tourne + lueurs des raretés Épique et plus
local battement: RBXScriptConnection? = nil
local temps = 0
local function battre(dt: number)
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
	temps += dt
	local rot = (temps * 120) % 360
	for cle, c in brillants do
		if c.bouton.Visible then
			local fort = cle == survol or cle == selection
			c.halo.BackgroundTransparency = (if fort then 0.5 else 0.7) + 0.1 * math.sin(temps * 2.6 + c.phase)
		end
	end
	for cle, c in cases do
		local r = c.reflet
		if r and c.bouton.Visible then
			r.Rotation = rot + c.phase * 57
		end
	end
	for o, p in pulsants do
		o.BackgroundTransparency = p.base + p.amp * math.sin(temps * 2.6)
	end
	for _, s in slotsUI do
		if s.reflet.Enabled then
			s.reflet.Rotation = rot
		end
	end
	if refletScene.Enabled then
		refletScene.Rotation = rot
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
	task.spawn(function()
		local h = perso:WaitForChild("Humanoid", 10)
		if h and h:IsA("Humanoid") then
			h:GetPropertyChangedSignal("MaxHealth"):Connect(function()
				if ouverte then
					statVie.regler(h.MaxHealth)
				end
			end)
		end
	end)
end
joueur.CharacterAdded:Connect(suivrePerso)
if joueur.Character then
	suivrePerso(joueur.Character)
end

-- ================= Ouverture / fermeture =================
local rideau = creer("Frame", {Name = "Rideau", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 16, 15),
	BackgroundTransparency = 1, Visible = false, ZIndex = 50, Parent = fenetre}, {coin(0.03)})
local tweens: {Tween} = {}
local function animer(objet: Instance, info: TweenInfo, props: {[string]: any})
	local t = TweenService:Create(objet, info, props)
	table.insert(tweens, t)
	t:Play()
end

local function manetteActive(): boolean
	local t = UserInputService:GetLastInputType()
	return t.Name:sub(1, 7) == "Gamepad"
end

local function basculer(ouvrir: boolean)
	if ouvrir == ouverte then
		return
	end
	ouverte = ouvrir
	Curseur.liberer("Sac", ouvrir)
	for _, t in tweens do
		t:Cancel()
	end
	table.clear(tweens)
	jouer("ouvrir", if ouvrir then 1 else 1.3)
	pop(pivotBourse, 0.7)
	if ouvrir then
		gui.Enabled = true
		badge.Visible = false
		vuTotal = totalMinerais()
		if sale then
			rafraichir()
		else
			rafraichirEquipement(true)
			rafraichirDetail()
		end
		statVie.regler(vieMax(), true)
		ajusterGrille()
		recloner()
		for _, t in boucles do
			t:Play()
		end
		astuce.TextTransparency = 0.4
		-- glisse depuis le bas + fondu (rideau couleur du fond qui s'efface)
		echelleFenetre.Scale = 0.96
		fenetre.Position = UDim2.fromScale(0.5, 0.56)
		rideau.Visible = true
		rideau.BackgroundTransparency = 0
		animer(echelleFenetre, DOUX, {Scale = 1})
		animer(fenetre, DOUX, {Position = UDim2.fromScale(0.5, 0.5)})
		animer(rideau, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		animer(voile, UI.DOUX, {BackgroundTransparency = 0.3})
		flou.Enabled = true
		animer(flou, UI.DOUX, {Size = 14})
		task.delay(0.36, function()
			if ouverte then
				rideau.Visible = false
			end
		end)
		cascade()
		battement = RunService.RenderStepped:Connect(battre)
		task.spawn(function()
			while ouverte do
				braise()
				task.wait(0.25 + math.random() * 0.3)
			end
		end)
		if manetteActive() then
			local premier: GuiObject = slotsUI.Pioche.bouton
			local mieux = math.huge
			for _, c in cases do
				if c.bouton.Visible and c.bouton.LayoutOrder < mieux then
					premier, mieux = c.bouton, c.bouton.LayoutOrder
				end
			end
			GuiService.SelectedObject = premier
		end
	else
		bulle.Visible = false
		survol = nil
		for _, t in boucles do
			t:Pause()
		end
		local sel = GuiService.SelectedObject
		if sel and sel:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
		rideau.Visible = true
		animer(rideau, FAST, {BackgroundTransparency = 0})
		animer(echelleFenetre, FAST, {Scale = 0.97})
		animer(fenetre, FAST, {Position = UDim2.fromScale(0.5, 0.54)})
		animer(voile, FAST, {BackgroundTransparency = 1})
		animer(flou, FAST, {Size = 0})
		if battement then
			battement:Disconnect()
			battement = nil
		end
		task.delay(0.16, function()
			if not ouverte then
				gui.Enabled = false
				flou.Enabled = false
				monde:ClearAllChildren()
				clone = nil
			end
		end)
	end
end

boutonSac.Activated:Connect(function()
	UI.gerbe(socle, T.Or, 8, Vector2.new(0.5, 0.4))
	basculer(true)
end)
-- Seuls la croix et la touche Échap ferment le sac : un clic dehors, B ou un équipement ne le ferment jamais.
-- Échap ouvre aussi le menu Roblox, qui peut capter la touche : MenuOpened sert de relais.
GuiService.MenuOpened:Connect(function()
	basculer(false)
end)
fermer.Activated:Connect(function()
	jouer("clic", 0.9)
	basculer(false)
end)
UserInputService.InputBegan:Connect(function(input, traite)
	if input.KeyCode == Enum.KeyCode.Escape then
		basculer(false)
	elseif input.KeyCode == TOUCHE and not traite then
		basculer(true)
	elseif not ouverte then
		return
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1 then
		local i = 1
		for k, c in CATEGORIES do
			if c.id == categorie then
				i = k
			end
		end
		i = (i - 1 + (if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1)) % #CATEGORIES + 1
		choisirCategorie(CATEGORIES[i].id)
	elseif input.KeyCode == Enum.KeyCode.ButtonY then
		trierSuivant()
	end
end)

appliquerFiltre()
rafraichirDetail()

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
