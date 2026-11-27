--!strict
-- Forge de Brom · SCRIPT CLIENT (l'UI)
-- S'ouvre quand le serveur le demande (le joueur a parlé à Brom). Aperçu en direct via Partage.Forge,
-- mais c'est le serveur qui recalcule, vérifie le sac et crée l'objet : le client ne fait qu'afficher et demander.
-- Thème et effets : InterfaceMine ; minerais / épée / lingots 3D : IconesObjets.
-- Disposition : objet à forger en haut (avec le nombre de minerais requis), sac à gauche, enclume au centre,
-- aperçu à droite, bouton FORGER centré en bas (gris tant que la forge est impossible).
-- Règles (Partage.Forge) : chaque minerai posé compte Forge.TYPES[type].requis unités ; minerais optionnels
-- dans la même quantité ; tous de la même rareté (les autres raretés sont cadenassées dans le sac).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Forge = require(Partage:WaitForChild("Forge"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local ArmesVoxels = require(Partage:WaitForChild("ArmesVoxels"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local DecorForge = require(script.Parent:WaitForChild("DecorForge"))
local evOuvrir = ReplicatedStorage:WaitForChild("ForgeOuvrir") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("ForgeAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Objet = {id: string, type: string, modele: string?, rang: number?, nom: string, couleur: string, stat: string, valeur: number, composition: {{any}}}
type Etat = {minerais: {[string]: number}, objets: {Objet}}

local T = UI.T
local creer, coin, trait, texte, jouer, pop = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop
local BOUNCY = UI.BOUNCY
local DISTANCE_FERMETURE = 16
local EPEE_3D = "EpeeFer"

local function couleurMinerai(id: string): Color3
	return Pioches.RARETES[MineraisModeles.VISUEL[id] and MineraisModeles.VISUEL[id].rarete or "Commun"] or T.Gris
end

local function couleurRarete(rarete: string): Color3
	return Pioches.RARETES[rarete] or T.Gris
end

local function arrondir(c: Color3): Color3
	local function q(x: number)
		return math.floor(x * 255 / 12 + 0.5) * 12
	end
	return Color3.fromRGB(math.min(255, q(c.R)), math.min(255, q(c.G)), math.min(255, q(c.B)))
end

-- Vrai modèle 3D d'un objet forgé : épée dédiée (ses couleurs), sinon l'épée de fer teintée, sinon un lingot
local function definirObjet(vp: ViewportFrame, typeId: string, couleur: Color3, vitesse: number, modele: string?)
	if typeId == "Epee" and modele and ArmesVoxels.existe(modele) then
		Icones.definir(vp, "epee", modele, {vitesse = vitesse, hauteur = 0.1, marge = 0.85})
	elseif typeId == "Epee" and ArmesVoxels.existe(EPEE_3D) then
		Icones.definir(vp, "epee", EPEE_3D, {teinte = arrondir(couleur), vitesse = vitesse, hauteur = 0.1, marge = 0.85})
	elseif typeId == "Casque" or typeId == "Plastron" or typeId == "Jambieres" then
		Icones.definir(vp, "armure", modele or typeId, {teinte = arrondir(couleur), vitesse = vitesse, hauteur = 0.2, marge = 0.85, angle = 0.45})
	else
		Icones.definir(vp, "lingot", arrondir(couleur):ToHex(), {vitesse = vitesse, hauteur = 0.45, marge = 0.85})
	end
end

local function bouton(props: {[string]: any}, tailleMax: number?): TextButton
	props.AutoButtonColor = false
	props.TextScaled = true
	props.Font = props.Font or Enum.Font.GothamBlack
	props.TextColor3 = props.TextColor3 or T.Parchemin
	props.BackgroundColor3 = props.BackgroundColor3 or T.CarteClaire
	local b = creer("TextButton", props, {coin(0.25), trait(T.FerSombre, 2), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
	creer("UITextSizeConstraint", {MaxTextSize = tailleMax or 26, MinTextSize = 8, Parent = b})
	UI.reactif(b, 1.08)
	return b
end

-- Titre de colonne (« Sac », « Aperçu ») : même police dorée que les noms d'objets
local function titreColonne(parent: Instance, txt: string, hauteur: number): TextLabel
	local l = texte({Text = txt, Font = Enum.Font.Fantasy, Size = UDim2.fromScale(1, hauteur), ZIndex = 4, Parent = parent}, 28)
	UI.dore(l)
	return l
end

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "ForgeBrom", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 10, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})

local F = UI.fenetre(gui, {nom = "Brom", role = "FORGERON · LA FORGE", service = "Forge", couleur = T.Braise,
	repliques = {"Le feu est chaud, apporte ton minerai !", "Même rareté sur l'enclume, sinon ça casse, gamin.",
		"Frappe tant que c'est chaud !", "Six rubis pour un plastron, pas un de moins."}})
local boucles = F.boucles
-- Forge plus grande que les autres fenêtres (minerais plus lisibles), même proportions
F.racine.Size = UDim2.fromScale(0.97, 0.93)
local limiteTaille = F.racine:FindFirstChildOfClass("UISizeConstraint")
if limiteTaille then
	limiteTaille.MaxSize = Vector2.new(1300, 802)
end
-- Décor d'arrière-plan (enclume, marteau, braises) : derrière le contenu, s'arrête fenêtre fermée
local decor = DecorForge.creer(F.contenu.Parent :: Frame, boucles)
local majBourse = UI.bourse(F.droite)
local message = UI.toast(gui)

local HAUT_COLONNES, H_COLONNES = 0.145, 0.71

-- ================= Onglets : objet à forger + minerais requis =================
local barreOnglets = creer("Frame", {Name = "Onglets", Size = UDim2.fromScale(1, 0.12), BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu}, {
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center}),
})
type Onglet = {bouton: TextButton, trait: UIStroke, souligne: Frame}
local onglets: {[string]: Onglet} = {}
for i, id in Forge.ORDRE_TYPES do
	local t = Forge.TYPES[id]
	local b = creer("TextButton", {Name = id, LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.241, 1),
		BackgroundColor3 = T.Carte, ZIndex = 3, Parent = barreOnglets}, {coin(0.25), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
	local tr = trait(T.FerSombre, 2)
	tr.Parent = b
	-- vrai modèle 3D du type (acier neutre), qui tourne au survol
	local caseIcone = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.03, 0.5), Size = UDim2.fromScale(0.86, 0.86),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.4, ZIndex = 4, Parent = b}, {coin(0.5)})
	local vpOnglet = Icones.creer(caseIcone)
	vpOnglet.ZIndex = 5
	definirObjet(vpOnglet, id, Color3.fromRGB(168, 174, 186), 0)
	b.MouseEnter:Connect(function()
		local v = Icones.vue(vpOnglet)
		if v then
			v.vitesse = 2
		end
	end)
	b.MouseLeave:Connect(function()
		local v = Icones.vue(vpOnglet)
		if v then
			v.vitesse = 0
		end
	end)
	texte({Text = t.nom .. " · " .. t.requis, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.34, 0.22), Size = UDim2.fromScale(0.63, 0.56), ZIndex = 4, Parent = b}, 18)
	local souligne = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0, 0.08),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 5, Parent = b}, {coin(0.5)})
	UI.reactif(b, 1.05)
	onglets[id] = {bouton = b, trait = tr, souligne = souligne}
end

-- ================= Sac (gauche) : minerais forgeables possédés =================
local colonneSac = UI.panneau({Name = "Sac", Position = UDim2.fromScale(0, HAUT_COLONNES), Size = UDim2.fromScale(0.27, H_COLONNES),
	BackgroundColor3 = Color3.fromRGB(44, 34, 28), ZIndex = 3, Parent = F.contenu}, 0.05)
creer("UIPadding", {PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0), PaddingTop = UDim.new(0.03, 0),
	PaddingBottom = UDim.new(0.03, 0), Parent = colonneSac})
local titreSac = titreColonne(colonneSac, "Sac", 0.09)
local traitSac = trait(T.Or, 2.5, 1)
traitSac.Parent = colonneSac
-- Grille de cases carrées, sans défilement : la taille des cases s'adapte au nombre de minerais possédés
local grilleSac = creer("Frame", {Name = "Grille", Position = UDim2.fromScale(0, 0.11), Size = UDim2.fromScale(1, 0.89),
	BackgroundTransparency = 1, ZIndex = 4, Parent = colonneSac})
local dispositionSac = creer("UIGridLayout", {CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = grilleSac}) :: UIGridLayout
local nbCases = 0
local function ajusterGrille()
	local l, h = grilleSac.AbsoluteSize.X, grilleSac.AbsoluteSize.Y
	local n, ecart = math.max(nbCases, 1), 6
	local meilleur = 0
	for colonnes = 1, n do
		local rangees = math.ceil(n / colonnes)
		local c = math.min((l - ecart * (colonnes - 1)) / colonnes, (h - ecart * (rangees - 1)) / rangees)
		meilleur = math.max(meilleur, c)
	end
	local c = math.floor(math.min(meilleur, l * 0.48))
	dispositionSac.CellSize = UDim2.fromOffset(math.max(c, 20), math.max(c, 20))
end
grilleSac:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajusterGrille)
local sacVide = texte({Text = "Aucun minerai à forger dans ton sac : va miner !", Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin,
	TextTransparency = 0.25, Position = UDim2.fromScale(0, 0.2), Size = UDim2.fromScale(1, 0.2), Visible = false, ZIndex = 5,
	Parent = colonneSac}, 15)

-- ================= Centre : condition, rareté, enclume, minerai optionnel =================
local centre = creer("Frame", {Name = "Centre", Position = UDim2.fromScale(0.285, HAUT_COLONNES), Size = UDim2.fromScale(0.4, H_COLONNES),
	BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu})
local titreRequis = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Size = UDim2.fromScale(1, 0.08), ZIndex = 4, Parent = centre}, 22)
-- compteur et rareté côte à côte sur une seule ligne, pour laisser toute la place à l'enclume
local caseCompteur = UI.panneau({Name = "Compteur", Position = UDim2.fromScale(0.02, 0.09),
	Size = UDim2.fromScale(0.27, 0.095), BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = centre}, 0.25)
local texteCompteur = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = caseCompteur}, 30)
local badgeRarete = creer("Frame", {Name = "Rarete", Position = UDim2.fromScale(0.31, 0.09),
	Size = UDim2.fromScale(0.67, 0.095), BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = centre}, {coin(0.3)})
local traitBadge = trait(T.FerSombre, 2)
traitBadge.Parent = badgeRarete
local texteRarete = texte({RichText = true, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.04, 0.1),
	Size = UDim2.fromScale(0.92, 0.8), ZIndex = 5, Parent = badgeRarete}, 18)

-- ================= Pièces 3D (enclume, marteau du bouton) =================
local ACIER_POLI, FONTE, FONTE_SOMBRE = Color3.fromRGB(150, 156, 170), Color3.fromRGB(70, 72, 82), Color3.fromRGB(44, 44, 52)
local BOIS_BILLOT, BOIS_MANCHE, CUIR = Color3.fromRGB(104, 68, 42), Color3.fromRGB(150, 102, 62), Color3.fromRGB(70, 42, 28)
local METAL, BOIS = Enum.Material.Metal, Enum.Material.Wood

local function piece3D(parent: Instance, forme: Enum.PartType?, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material?,
	nom: string?): Part
	local p = Instance.new("Part")
	p.Name = nom or "Piece"
	p.Shape = forme or Enum.PartType.Block
	p.Size, p.CFrame, p.Color = taille, cf, couleur
	p.Material = mat or METAL
	p.Anchored, p.CanCollide = true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function coin3D(parent: Instance, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	w.Size, w.CFrame, w.Color = taille, cf, couleur
	w.Material = mat or METAL
	w.Anchored, w.CanCollide = true, false
	w.Parent = parent
	return w
end

local VERTICAL = CFrame.Angles(0, 0, math.pi / 2) -- un cylindre Roblox est couché sur X : debout sur Y

-- Enclume de forgeron (repère : dessus de la table à y = 0, bigorne côté -X, talon côté +X), sur billot cerclé de fer.
-- Les alvéoles des minerais sont creusées dans la table (zone x ∈ [-2.3, 1.5]).
local function modeleEnclume(): Model
	local m = Instance.new("Model")
	m.Name = "Enclume"
	-- table et face polie (biseau clair sur l'arête avant)
	piece3D(m, nil, Vector3.new(5.6, 0.9, 1.9), CFrame.new(0, -0.45, 0), FONTE, METAL, "Table")
	piece3D(m, nil, Vector3.new(5.5, 0.08, 1.78), CFrame.new(0, 0.02, 0), ACIER_POLI, METAL, "Face")
	piece3D(m, nil, Vector3.new(5.5, 0.1, 0.06), CFrame.new(0, -0.05, 0.92), ACIER_POLI:Lerp(Color3.new(1, 1, 1), 0.2), METAL, "Arete")
	-- talon (+X) : trou carré (tranchet) et trou rond (pritchel)
	piece3D(m, nil, Vector3.new(0.9, 0.8, 1.6), CFrame.new(3.2, -0.5, 0), FONTE, METAL, "Talon")
	piece3D(m, nil, Vector3.new(0.86, 0.06, 1.5), CFrame.new(3.2, -0.08, 0), ACIER_POLI:Lerp(FONTE, 0.3), METAL)
	piece3D(m, nil, Vector3.new(0.34, 0.03, 0.34), CFrame.new(2.35, 0.06, 0), Color3.fromRGB(10, 9, 12), Enum.Material.SmoothPlastic, "Tranchet")
	piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.03, 0.24, 0.24), CFrame.new(2.85, 0.06, 0) * VERTICAL, Color3.fromRGB(10, 9, 12),
		Enum.Material.SmoothPlastic, "Pritchel")
	-- marche (petite table plus basse) puis bigorne conique qui s'affine vers la pointe
	piece3D(m, nil, Vector3.new(0.7, 0.75, 1.5), CFrame.new(-3.15, -0.48, 0), FONTE, METAL, "Marche")
	for i = 1, 8 do
		local d = 0.86 * (1 - (i - 1) / 8.6)
		piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.34, d, d), CFrame.new(-3.5 - 0.3 * (i - 0.5), -0.1 - d / 2, 0),
			FONTE:Lerp(ACIER_POLI, 0.15 * (1 - i / 8)), METAL, "Bigorne")
	end
	piece3D(m, Enum.PartType.Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(-6.0, -0.2, 0), FONTE, METAL, "Pointe")
	-- évasement sous la table, taille (col), évasement du pied
	coin3D(m, Vector3.new(1.7, 0.55, 0.9), CFrame.new(0, -1.18, 0.38) * CFrame.Angles(math.pi, 0, 0), FONTE_SOMBRE)
	coin3D(m, Vector3.new(1.7, 0.55, 0.9), CFrame.new(0, -1.18, -0.38) * CFrame.Angles(math.pi, math.pi, 0), FONTE_SOMBRE)
	piece3D(m, nil, Vector3.new(2.6, 0.25, 1.5), CFrame.new(0, -1.0, 0), FONTE_SOMBRE, METAL)
	piece3D(m, nil, Vector3.new(1.7, 1.1, 1.0), CFrame.new(0, -1.6, 0), FONTE_SOMBRE, METAL, "Col")
	coin3D(m, Vector3.new(1.9, 0.5, 0.7), CFrame.new(0, -2.15, 0.62), FONTE)
	coin3D(m, Vector3.new(1.9, 0.5, 0.7), CFrame.new(0, -2.15, -0.62) * CFrame.Angles(0, math.pi, 0), FONTE)
	piece3D(m, nil, Vector3.new(3.4, 0.45, 2.0), CFrame.new(0, -2.55, 0), FONTE, METAL, "Pied")
	for _, x in {-1.45, 1.45} do
		for _, z in {-0.75, 0.75} do
			piece3D(m, nil, Vector3.new(0.8, 0.3, 0.7), CFrame.new(x, -2.88, z), FONTE_SOMBRE, METAL, "Patte")
		end
	end
	-- billot de chêne cerclé de deux bandes de fer rivetées
	piece3D(m, Enum.PartType.Cylinder, Vector3.new(1.9, 4.2, 4.2), CFrame.new(0, -3.98, 0) * VERTICAL, BOIS_BILLOT, BOIS, "Billot")
	piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.06, 4.0, 4.0), CFrame.new(0, -3.02, 0) * VERTICAL, BOIS_BILLOT:Lerp(Color3.new(1, 1, 1), 0.2),
		BOIS, "Cerne")
	for _, y in {-3.45, -4.6} do
		piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.2, 4.32, 4.32), CFrame.new(0, y, 0) * VERTICAL, FONTE_SOMBRE, METAL, "Cerclage")
		for k = 0, 5 do
			local a = k * math.pi / 3 + 0.3
			piece3D(m, Enum.PartType.Ball, Vector3.new(0.14, 0.14, 0.14), CFrame.new(math.cos(a) * 2.16, y, math.sin(a) * 2.16), ACIER_POLI, METAL, "Rivet")
		end
	end
	return m
end

local enclume = creer("Frame", {Name = "Enclume", Position = UDim2.fromScale(-0.04, 0.2), Size = UDim2.fromScale(1.08, 0.51),
	BackgroundTransparency = 1, ZIndex = 3, Parent = centre})
-- lueur de forge derrière le billot
creer("Frame", {Name = "Braises", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1.02), Size = UDim2.fromScale(0.75, 0.32),
	BackgroundColor3 = Color3.fromRGB(255, 110, 30), BorderSizePixel = 0, ZIndex = 3, Parent = enclume}, {coin(0.5),
	creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1)})})})
local vueEnclume = creer("ViewportFrame", {Name = "Vue", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4,
	Ambient = Color3.fromRGB(120, 112, 108), LightColor = Color3.fromRGB(255, 214, 170), LightDirection = Vector3.new(-0.6, -1, -0.8),
	Parent = enclume}) :: ViewportFrame
local cameraEnclume = Instance.new("Camera")
cameraEnclume.FieldOfView = 26
cameraEnclume.Parent = vueEnclume
vueEnclume.CurrentCamera = cameraEnclume
modeleEnclume().Parent = vueEnclume
local alveoles = Instance.new("Model")
alveoles.Name = "Alveoles"
alveoles.Parent = vueEnclume
-- caméra plongeante de trois-quarts face : la table et ses alvéoles bien visibles, la bigorne entière
do
	local cible = Vector3.new(-0.9, -2.0, 0)
	local function cadrer()
		local s = vueEnclume.AbsoluteSize
		local aspect = if s.Y > 0 then s.X / s.Y else 2
		-- distance pour tenir la largeur (≈ 10 studs) et la hauteur (≈ 6,5 studs) de l'ensemble
		local demiV = math.rad(cameraEnclume.FieldOfView / 2)
		local d = math.max(2.9 / math.tan(demiV), 4.6 / (math.tan(demiV) * aspect)) + 0.4
		local dir = Vector3.new(0.12, 0.62, 1).Unit
		cameraEnclume.CFrame = CFrame.lookAt(cible + dir * d, cible)
	end
	vueEnclume:GetPropertyChangedSignal("AbsoluteSize"):Connect(cadrer)
	cadrer()
end

-- Minerais posés : étiquettes sous l'enclume (recliquer sur le minerai du sac pour le retirer) ; texte d'aide tant que rien n'est posé
local rangeePoses = creer("Frame", {Name = "Poses", Position = UDim2.fromScale(0, 0.712), Size = UDim2.fromScale(1, 0.062),
	BackgroundTransparency = 1, ZIndex = 4, Parent = centre}, {
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.015, 0), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center}),
})
local enclumeVide = texte({Text = "Clique sur un minerai du sac pour le poser sur l'enclume", Font = Enum.Font.GothamBold,
	TextColor3 = T.Parchemin, TextTransparency = 0.2, Position = UDim2.fromScale(0, 0.712), Size = UDim2.fromScale(1, 0.062),
	ZIndex = 5, Parent = centre}, 15)

local boutonAjouter = bouton({Name = "Ajouter", Text = "+ Ajouter un minerai (optionnel)", AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.785), Size = UDim2.fromScale(0.82, 0.09), ZIndex = 4, Parent = centre}, 20)
local traitAjouter = boutonAjouter:FindFirstChildOfClass("UIStroke") :: UIStroke
texte({Text = "Chaque minerai ajouté doit être en même quantité que le principal", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
	TextTransparency = 0.15, Position = UDim2.fromScale(0.04, 0.89), Size = UDim2.fromScale(0.92, 0.1), ZIndex = 4, Parent = centre}, 15)

-- ================= Aperçu du résultat (droite) =================
local fiche = UI.panneau({Name = "Apercu", Position = UDim2.fromScale(0.7, HAUT_COLONNES), Size = UDim2.fromScale(0.3, H_COLONNES),
	BackgroundColor3 = Color3.fromRGB(44, 34, 28), ZIndex = 3, Parent = F.contenu}, 0.05)
creer("UIPadding", {PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0), PaddingTop = UDim.new(0.03, 0),
	PaddingBottom = UDim.new(0.03, 0), Parent = fiche})
titreColonne(fiche, "Aperçu", 0.09)

local scene = creer("CanvasGroup", {Name = "Scene", Position = UDim2.fromScale(0, 0.11), Size = UDim2.fromScale(1, 0.47),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, Parent = fiche}, {coin(0.08), trait(T.OrFonce, 2), creer("UIGradient", {Name = "Fond", Rotation = 90})})
local degradeScene = scene:FindFirstChild("Fond") :: UIGradient
local rayons = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(2, 2),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Parent = scene}, {coin(0.5),
	creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.2),
		NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(0.35, 0.3), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(0.65, 0.2),
		NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(0.9, 0.3), NumberSequenceKeypoint.new(1, 1)})})})
UI.boucle(rayons, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
-- Lueur de magma qui respire au pied de l'objet (identité de la forge)
local magma = creer("Frame", {Name = "Magma", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 110, 30), BorderSizePixel = 0, Parent = scene})
local gMagma = creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.6, 0.7), NumberSequenceKeypoint.new(1, 0.3)}), Parent = magma})
UI.boucle(gMagma, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.15)}, boucles)
UI.ombre(scene, 0.86, 0.6)
local vpResultat = Icones.creer(scene)
vpResultat.ZIndex = 2
local echelleResultat = UI.echelle(vpResultat)
-- pastille du type en bas à droite : silhouette 3D du modèle
local pastilleType = creer("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.97, 0.97), Size = UDim2.fromScale(0.2, 0.2),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.35, ZIndex = 3, Parent = scene},
	{coin(0.5), trait(T.OrFonce, 1.5, 0.3)})
local iconeType = Icones.creer(pastilleType)
iconeType.ZIndex = 4
local bandeauAlliage = texte({Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04),
	Size = UDim2.fromScale(0.9, 0.13), ZIndex = 3, Parent = scene}, 20)
UI.dore(bandeauAlliage, 2)

local nomRes = texte({Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.09), ZIndex = 4, Parent = fiche}, 28)
UI.dore(nomRes)
local statRes = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0, 0.7),
	Size = UDim2.fromScale(1, 0.085), ZIndex = 4, Parent = fiche}, 28)
local statEnCours = {stat = "Dégâts", icone = "⚔", vide = true}
local majStat = UI.compteur(statRes, function(n)
	return if statEnCours.vide then statEnCours.icone .. " " .. statEnCours.stat .. " : —"
		else string.format("%s %s : %d", statEnCours.icone, statEnCours.stat, math.floor(n + 0.5))
end)
local compoRes = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromScale(0, 0.8),
	Size = UDim2.fromScale(1, 0.05), ZIndex = 4, Parent = fiche}, 15)
local coutRes = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0, 0.86), Size = UDim2.fromScale(1, 0.055), ZIndex = 4, Parent = fiche}, 17)
local coutActuel = {total = 0, prix = 0}
local majPrix = UI.compteur(coutRes, function(n)
	return if coutActuel.total == 0 then "" else string.format("◆ %d minerais   ◉ %d pièces", coutActuel.total, math.floor(n + 0.5))
end)
local avis = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Rouge, Position = UDim2.fromScale(0, 0.93),
	Size = UDim2.fromScale(1, 0.06), ZIndex = 4, Parent = fiche}, 15)

-- ================= FORGER (centré en bas) : gris si impossible, couleur braise sinon =================
local principal = UI.boutonPrincipal({Name = "Forger", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromScale(0.34, 0.115), BackgroundColor3 = T.Braise, ZIndex = 4, Parent = F.contenu}, boucles)
local boutonForger = principal.bouton
local GRIS_FORGER = Color3.fromRGB(112, 112, 116)
-- Marteau de forgeron en 3D (à la place de l'emoji) : manche de frêne à poignée de cuir, tête d'acier forgé
-- (table de frappe d'un côté, panne de l'autre), coin de serrage et viroles. Repère : main en bas, tête en haut.
local function modeleMarteau(): Model
	local m = Instance.new("Model")
	m.Name = "Marteau"
	piece3D(m, nil, Vector3.new(0.34, 4.4, 0.26), CFrame.new(0, 0.2, 0), BOIS_MANCHE, BOIS, "Manche")
	piece3D(m, nil, Vector3.new(0.4, 0.22, 0.32), CFrame.new(0, -1.95, 0), BOIS_MANCHE:Lerp(Color3.new(0, 0, 0), 0.25), BOIS, "Talon")
	-- poignée : lanières de cuir enroulées
	for k = 0, 6 do
		piece3D(m, nil, Vector3.new(0.4, 0.14, 0.32), CFrame.new(0, -1.7 + k * 0.17, 0) * CFrame.Angles(0, 0, math.rad(if k % 2 == 0 then 8 else -8)),
			CUIR:Lerp(Color3.new(1, 1, 1), if k % 2 == 0 then 0 else 0.08), Enum.Material.Fabric, "Cuir")
	end
	-- viroles d'acier sous la tête
	piece3D(m, nil, Vector3.new(0.42, 0.12, 0.34), CFrame.new(0, 1.85, 0), FONTE_SOMBRE, METAL, "Virole")
	-- tête : corps, bombé, table de frappe (-X) et panne qui s'affine (+X)
	piece3D(m, nil, Vector3.new(1.3, 0.78, 0.66), CFrame.new(-0.1, 2.45, 0), FONTE, METAL, "Tete")
	piece3D(m, nil, Vector3.new(1.32, 0.12, 0.6), CFrame.new(-0.1, 2.88, 0), ACIER_POLI:Lerp(FONTE, 0.35), METAL)
	piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.34, 0.86, 0.86), CFrame.new(-0.9, 2.45, 0), FONTE, METAL, "Bout")
	piece3D(m, Enum.PartType.Cylinder, Vector3.new(0.08, 0.8, 0.8), CFrame.new(-1.1, 2.45, 0), ACIER_POLI, METAL, "Frappe")
	piece3D(m, nil, Vector3.new(0.4, 0.6, 0.64), CFrame.new(0.72, 2.45, 0), FONTE, METAL)
	piece3D(m, nil, Vector3.new(0.34, 0.4, 0.62), CFrame.new(1.06, 2.45, 0), FONTE, METAL)
	piece3D(m, nil, Vector3.new(0.2, 0.18, 0.6), CFrame.new(1.32, 2.45, 0), ACIER_POLI, METAL, "Panne")
	-- œil : bout du manche et coin de serrage visibles sur le dessus
	piece3D(m, nil, Vector3.new(0.32, 0.04, 0.24), CFrame.new(0, 2.95, 0), BOIS_MANCHE, BOIS)
	piece3D(m, nil, Vector3.new(0.06, 0.05, 0.24), CFrame.new(0, 2.97, 0), FONTE_SOMBRE, METAL, "Coin")
	return m
end
local vueMarteau = creer("ViewportFrame", {Name = "Marteau", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5),
	Size = UDim2.fromScale(0.95, 0.95), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 8,
	Ambient = Color3.fromRGB(130, 120, 112), LightColor = Color3.fromRGB(255, 220, 180), LightDirection = Vector3.new(-0.5, -1, -0.7),
	Parent = boutonForger}) :: ViewportFrame
do
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vueMarteau
	vueMarteau.CurrentCamera = cam
	local mod = modeleMarteau()
	-- incliné comme brandi, tête en haut à droite
	mod:PivotTo(CFrame.Angles(0, math.rad(-20), math.rad(-38)))
	mod.Parent = vueMarteau
	local cf, taille = mod:GetBoundingBox()
	local d = (taille.Magnitude / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.02
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0.4, d), cf.Position)
end
local function etatForger(txt: string, actif: boolean)
	principal.definir(txt, if actif then T.Braise else GRIS_FORGER, actif)
	if not actif then
		-- vrai gris (definir mélange vers une teinte brune)
		TweenService:Create(boutonForger, TweenInfo.new(0.2), {BackgroundColor3 = GRIS_FORGER}):Play()
	end
	principal.texte.TextColor3 = if actif then Color3.new(1, 1, 1) else Color3.fromRGB(205, 205, 208)
	vueMarteau.ImageTransparency = if actif then 0 else 0.35
	vueMarteau.ImageColor3 = if actif then Color3.new(1, 1, 1) else Color3.fromRGB(150, 150, 154)
end

-- ================= État =================
local etat: Etat = {minerais = {}, objets = {}}
local typeChoisi = Forge.ORDRE_TYPES[1]
local poses: {string} = {} -- minerais sur l'enclume ; [1] = principal, les suivants sont optionnels
local modeAjout = false
local pointForge: BasePart? = nil
local promptForge: ProximityPrompt? = nil
local enAttente = false

local function possede(id: string): number
	return etat.minerais[id] or 0
end

local function requis(): number
	return Forge.TYPES[typeChoisi].requis
end

local function rareteVerrou(): string?
	return if poses[1] then Forge.rarete(poses[1]) else nil
end

local function pieces(): number
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Pièces")
	return if v and v:IsA("IntValue") then v.Value else 0
end

local function composition(): {{any}}
	local c = {}
	for _, id in poses do
		table.insert(c, {id, requis()})
	end
	return c
end

local function indexPose(id: string): number?
	return table.find(poses, id)
end

-- ================= Lignes du sac =================
type LigneSac = {bouton: TextButton, vp: ViewportFrame, nom: TextLabel, nombre: TextLabel, cadenas: TextLabel, voile: Frame}
local lignes: {[string]: LigneSac} = {}
local choisirMinerai: (string) -> () -- défini plus bas (interactions)

local function construireSac()
	for _, l in lignes do
		l.bouton:Destroy()
	end
	table.clear(lignes)
	local n = 0
	for ordre, id in Forge.ORDRE_FORGE do
		if possede(id) <= 0 then
			continue
		end
		n += 1
		local m = Forge.MINERAIS[id]
		-- case carrée d'inventaire : minerai 3D, nom en haut, quantité en bas à droite, cadenas si autre rareté
		local b = creer("TextButton", {Name = id, LayoutOrder = ordre, Text = "", AutoButtonColor = false,
			BackgroundColor3 = couleurMinerai(id):Lerp(T.Fond3D, 0.62), ZIndex = 5, Parent = grilleSac},
			{coin(0.16), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(120, 110, 104))})
		local vp = Icones.creer(b)
		vp.Position, vp.Size = UDim2.fromScale(0.12, 0.14), UDim2.fromScale(0.76, 0.7)
		vp.ZIndex = 6
		Icones.definir(vp, "minerai", id, {vitesse = 0.6, hauteur = 0.35})
		local nom = texte({Text = m.nom, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.05, 0.03),
			Size = UDim2.fromScale(0.9, 0.2), ZIndex = 7, Parent = b}, 19)
		creer("UIStroke", {Thickness = 1.2, Parent = nom})
		local nombre = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.3, 0.75), Size = UDim2.fromScale(0.65, 0.22), ZIndex = 7, Parent = b}, 22)
		creer("UIStroke", {Thickness = 1.5, Parent = nombre})
		local voile = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.35,
			Visible = false, ZIndex = 8, Parent = b}, {coin(0.16)})
		local cadenas = texte({Text = "🔒", Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.4), Visible = false, ZIndex = 9, Parent = b}, 30)
		UI.reactif(b, 1.06)
		b.Activated:Connect(function()
			choisirMinerai(id)
		end)
		lignes[id] = {bouton = b, vp = vp, nom = nom, nombre = nombre, cadenas = cadenas, voile = voile}
	end
	nbCases = n
	ajusterGrille()
	sacVide.Visible = n == 0
end

local function majSac()
	local verrou = rareteVerrou()
	for id, l in lignes do
		local bloque = verrou ~= nil and Forge.rarete(id) ~= verrou
		local pose = indexPose(id) ~= nil
		l.cadenas.Visible = bloque
		l.voile.Visible = bloque
		l.vp.ImageTransparency = if bloque then 0.6 else 0
		l.nom.TextColor3 = if bloque then T.Gris elseif pose then T.Or else T.Parchemin
		l.nombre.Text = "× " .. possede(id)
		l.nombre.TextColor3 = if bloque then T.Gris elseif possede(id) < requis() then T.Rouge else T.Or
		UI.rarete(l.bouton, if pose then T.Or elseif bloque then T.FerSombre else couleurMinerai(id),
			if bloque then 1 else UI.NIVEAUX[Forge.rarete(id)] or 1)
	end
	traitSac.Transparency = if modeAjout then 0 else 1
	titreSac.Text = if modeAjout then "Choisis le minerai" else "Sac"
end

-- ================= Encoches de l'enclume + étiquettes des minerais posés =================
type Encoche = {carte: Frame, quantite: TextLabel}
local encoches: {[string]: Encoche} = {} -- étiquettes sous l'enclume, par minerai posé
local signatureEnclume = ""
local retirerMinerai: (string) -> () -- défini plus bas

-- Alvéoles creusées dans la face de l'enclume (3D) : zone utile x ∈ [ZONE_X0, ZONE_X1], z ∈ [-ZONE_Z/2, ZONE_Z/2]
local ZONE_X0, ZONE_X1, ZONE_Z = -2.65, 2.0, 1.5
local function disposerAlveoles(n: number): (number, number)
	-- colonnes qui donnent la plus grande alvéole carrée
	local l, meilleurC, meilleuresCol = ZONE_X1 - ZONE_X0, 0, 1
	for colonnes = 1, n do
		local rangees = math.ceil(n / colonnes)
		local c = math.min(l / colonnes, ZONE_Z / rangees)
		if c > meilleurC then
			meilleurC, meilleuresCol = c, colonnes
		end
	end
	return math.min(meilleurC, 0.75), meilleuresCol
end

-- Une alvéole : rebord d'acier, creux noir ; si pleine, une gemme taillée (octaèdre) à la couleur du minerai
local function alveole(cf: CFrame, c: number, couleurRebord: Color3, couleurGemme: Color3?)
	piece3D(alveoles, nil, Vector3.new(c * 0.86, 0.05, c * 0.86), cf * CFrame.new(0, 0.03, 0), couleurRebord, METAL, "Rebord")
	piece3D(alveoles, nil, Vector3.new(c * 0.68, 0.05, c * 0.68), cf * CFrame.new(0, 0.045, 0), Color3.fromRGB(8, 7, 10),
		Enum.Material.SmoothPlastic, "Creux")
	if couleurGemme then
		local t = c * 0.42
		local g = piece3D(alveoles, nil, Vector3.new(t, t, t), cf * CFrame.new(0, 0.05 + t * 0.62, 0)
			* CFrame.Angles(math.rad(45), 0, math.rad(35.26)), couleurGemme, Enum.Material.Glass, "Gemme")
		g.Reflectance = 0.15
		-- éclat lumineux sous la gemme
		piece3D(alveoles, Enum.PartType.Cylinder, Vector3.new(0.02, c * 0.62, c * 0.62), cf * CFrame.new(0, 0.075, 0) * VERTICAL,
			couleurGemme:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.Neon, "Lueur").Transparency = 0.35
	end
end

local function majEnclume()
	local r = requis()
	-- signature : objet choisi + minerais posés + quantités possédées (une encoche pleine par unité disponible)
	local morceaux = {typeChoisi}
	for _, id in poses do
		table.insert(morceaux, id .. "=" .. math.min(possede(id), r))
	end
	local signature = table.concat(morceaux, "|")
	if signature ~= signatureEnclume then
		signatureEnclume = signature
		alveoles:ClearAllChildren()
		for _, e in encoches do
			e.carte:Destroy()
		end
		table.clear(encoches)
		local nbMinerais = math.max(1, #poses)
		local total = r * nbMinerais
		local c, colonnes = disposerAlveoles(total)
		local rangees = math.ceil(total / colonnes)
		local x0 = (ZONE_X0 + ZONE_X1) / 2 - colonnes * c / 2
		local ordre = 0
		for k = 1, nbMinerais do
			local id = poses[k]
			local pleins = if id then math.min(possede(id), r) else 0
			for u = 1, r do
				local col, rang = ordre % colonnes, ordre // colonnes
				ordre += 1
				local cf = CFrame.new(x0 + (col + 0.5) * c, 0, (rang + 0.5) * c - rangees * c / 2)
				local plein = id ~= nil and u <= pleins
				local rebord = if id then couleurMinerai(id):Lerp(ACIER_POLI, if plein then 0.35 else 0.7) else ACIER_POLI:Lerp(FONTE, 0.4)
				alveole(cf, c, rebord, if plein and id then Forge.MINERAIS[id].couleur:Lerp(couleurMinerai(id), 0.35) else nil)
			end
		end
		for i, id in poses do
			local carte = creer("Frame", {Name = id, LayoutOrder = i, Size = UDim2.fromScale(0.235, 1), BackgroundColor3 = T.Carte, ZIndex = 5,
				Parent = rangeePoses}, {coin(0.3), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
			UI.rarete(carte, couleurMinerai(id), 1)
			-- pas de bouton de retrait : on reclique sur le minerai dans le sac pour l'enlever
			local quantite = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.05, 0.1),
				Size = UDim2.fromScale(0.9, 0.8), ZIndex = 6, Parent = carte}, 14)
			encoches[id] = {carte = carte, quantite = quantite}
		end
	end
	for id, e in encoches do
		local q = possede(id)
		e.quantite.Text = Forge.MINERAIS[id].nom .. (if q >= r then " ×" .. r else string.format(" %d/%d", q, r))
		e.quantite.TextColor3 = if q >= r then T.Parchemin else T.Rouge
	end
	enclumeVide.Visible = #poses == 0
end

-- ================= Rendu =================
local function rafraichirOnglets()
	for id, o in onglets do
		local choisi = id == typeChoisi
		o.bouton.BackgroundColor3 = if choisi then T.CarteClaire else T.Carte
		o.trait.Color = if choisi then T.Or else T.FerSombre
		o.trait.Thickness = if choisi then 3 else 2
		TweenService:Create(o.souligne, BOUNCY, {Size = UDim2.fromScale(if choisi then 0.7 else 0, 0.08)}):Play()
	end
end

local function rafraichirCentre()
	local t = Forge.TYPES[typeChoisi]
	local r = requis()
	titreRequis.Text = string.format("%s : %d minerais requis", t.nom, r)
	local besoin = r * math.max(1, #poses)
	local presents = 0
	for _, id in poses do
		presents += math.min(possede(id), r)
	end
	texteCompteur.Text = string.format("%d / %d", presents, besoin)
	texteCompteur.TextColor3 = if #poses == 0 then T.Gris elseif presents >= besoin then T.Or else T.Rouge
	local verrou = rareteVerrou()
	if verrou then
		local c = couleurRarete(verrou)
		texteRarete.Text = string.format('Rareté verrouillée : <font color="#%s">%s</font>', c:ToHex(), verrou)
		traitBadge.Color, traitBadge.Thickness = c, 2.5
	else
		texteRarete.Text = "Choisis un minerai dans le sac"
		traitBadge.Color, traitBadge.Thickness = T.FerSombre, 2
	end
	local peutAjouter = #poses >= 1 and #poses < Forge.MAX_MINERAIS
	boutonAjouter.Text = if modeAjout then "Choisis-le dans le sac…  (annuler)" else "+ Ajouter un minerai (optionnel)"
	boutonAjouter.TextColor3 = if peutAjouter then T.Parchemin else T.Gris
	boutonAjouter.BackgroundColor3 = if modeAjout then T.OrFonce elseif peutAjouter then T.CarteClaire else T.Fond3D
	traitAjouter.Color = if modeAjout then T.Or else T.FerSombre
end

local function rafraichirApercu()
	local t = Forge.TYPES[typeChoisi]
	local comp = composition()
	local res, erreur = nil, nil
	if #comp > 0 then
		res, erreur = Forge.calculer(typeChoisi, comp)
	end
	local manque: string? = nil
	for _, e in comp do
		local q = possede(e[1])
		if q < e[2] then
			manque = string.format("Il manque %d %s", e[2] - q, Forge.MINERAIS[e[1]].mat)
		end
	end
	definirObjet(iconeType, typeChoisi, Color3.fromRGB(168, 174, 186), 0)
	statEnCours.stat = t.stat
	statEnCours.icone = if t.stat == "Dégâts" then "⚔" else "🛡"
	statEnCours.vide = res == nil
	if res then
		definirObjet(vpResultat, typeChoisi, res.couleur, 0.9, res.modele)
		vpResultat.Visible = true
		-- Fond de braise chaud quelle que soit la couleur de l'objet : une épée de charbon ne se perd plus dans le noir
		-- fond ardoise sombre, à peine teinté par le minerai : l'objet ressort au lieu de se fondre dans le fond
		degradeScene.Color = ColorSequence.new(Color3.fromRGB(78, 84, 100):Lerp(res.couleur, 0.12), Color3.fromRGB(16, 17, 22))
		rayons.BackgroundColor3 = res.couleur:Lerp(Color3.new(1, 1, 1), 0.5)
		nomRes.Text = res.nom
		majStat(res.valeur)
		local parts = {}
		for _, e in res.composition do
			table.insert(parts, string.format("%d %s", e[2], Forge.MINERAIS[e[1]].mat))
		end
		local echelle = Forge.ECHELLES[typeChoisi]
		compoRes.Text = (if res.rang and echelle then string.format("Rang %d/%d · ", res.rang, #echelle) else "")
			.. table.concat(parts, " · ")
		coutActuel.total = res.total
		majPrix(res.prix)
		coutRes.TextColor3 = if pieces() >= res.prix then T.Parchemin else T.Rouge
		if not manque and pieces() < res.prix then
			manque = "Pas assez de pièces"
		end
	else
		vpResultat.Visible = false
		degradeScene.Color = ColorSequence.new(Color3.fromRGB(66, 70, 82), Color3.fromRGB(16, 17, 22))
		rayons.BackgroundColor3 = T.Gris
		nomRes.Text = t.nom .. " ?"
		majStat(0, true)
		compoRes.Text = string.format("%d minerais de même rareté", t.requis)
		coutActuel.total = 0
		majPrix(0, true)
	end
	local alliage = res and res.alliage
	bandeauAlliage.Text = if alliage then "★ ALLIAGE : " .. string.upper(alliage) .. " ★" else ""
	avis.Text = if #comp == 0 then "" else (erreur or manque or "")
	local actif = res ~= nil and manque == nil and not enAttente
	etatForger(if enAttente then "FORGE…" else "FORGER", actif)
end

local function rafraichir()
	rafraichirOnglets()
	majSac()
	majEnclume()
	rafraichirCentre()
	rafraichirApercu()
end

-- ================= Interactions =================
choisirMinerai = function(id: string)
	local verrou = rareteVerrou()
	local ligne = lignes[id]
	if verrou and Forge.rarete(id) ~= verrou then
		jouer("clic", 0.6)
		if ligne then
			UI.secouer(ligne.bouton, 5)
		end
		message(string.format("Rareté différente : il faut un minerai %s", verrou), false)
		return
	end
	if indexPose(id) then
		-- recliquer sur un minerai déjà posé le retire de l'enclume
		retirerMinerai(id)
		return
	end
	if #poses == 0 then
		poses[1] = id
	elseif modeAjout then
		if #poses >= Forge.MAX_MINERAIS then
			message(string.format("%d minerais différents au maximum", Forge.MAX_MINERAIS), false)
			return
		end
		table.insert(poses, id)
	else
		poses[1] = id -- même rareté : remplace le principal
	end
	modeAjout = false
	jouer("clic", 1.2)
	rafraichir()
	local e = encoches[id]
	if e then
		pop(e.carte, 0.8)
	end
	UI.gerbe(enclume, couleurMinerai(id), 10)
end

retirerMinerai = function(id: string)
	local i = indexPose(id)
	if i then
		table.remove(poses, i)
		if #poses == 0 then
			modeAjout = false
		end
		jouer("clic", 0.9)
		rafraichir()
	end
end

boutonAjouter.Activated:Connect(function()
	if #poses == 0 then
		jouer("clic", 0.6)
		UI.secouer(boutonAjouter, 4)
		message("Pose d'abord le minerai principal", false)
		return
	elseif #poses >= Forge.MAX_MINERAIS and not modeAjout then
		jouer("clic", 0.6)
		UI.secouer(boutonAjouter, 4)
		message(string.format("%d minerais différents au maximum", Forge.MAX_MINERAIS), false)
		return
	end
	modeAjout = not modeAjout
	jouer("clic", if modeAjout then 1.15 else 0.9)
	rafraichir()
	if modeAjout then
		pop(colonneSac, 0.97)
	end
end)

for id, o in onglets do
	o.bouton.Activated:Connect(function()
		if typeChoisi ~= id then
			typeChoisi = id
			jouer("clic", 1.1)
			rafraichir()
			pop(scene, 0.92)
			echelleResultat.Scale = 0.4
			TweenService:Create(echelleResultat, BOUNCY, {Scale = 1}):Play()
		end
	end)
end

local function celebrer(objet: any)
	local ok, couleur = pcall(Color3.fromHex, if type(objet) == "table" then objet.couleur else "")
	local c = if ok then couleur else T.Or
	UI.celebrer(scene, c, "FORGÉ !")
	echelleResultat.Scale = 0
	TweenService:Create(echelleResultat, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local v = Icones.vue(vpResultat)
	if v then
		v.angle -= 6.28
	end
	pop(F.racine, 0.97)
	jouer("succes")
	task.delay(0.15, jouer, "succes", 1.5)
end

-- Cinématique de forge (ForgeCinematique.client pose l'attribut ForgeCinematique) : fenêtre masquée pendant,
-- rendue après ; si elle ne démarre pas dans la seconde, ou dure plus de 10 s, on reprend la main
local function attendreCinematique()
	local debut = os.clock()
	gui.Enabled = false
	while not joueur:GetAttribute("ForgeCinematique") and os.clock() - debut < 1 do
		task.wait()
	end
	while joueur:GetAttribute("ForgeCinematique") and os.clock() - debut < 10 do
		task.wait(0.1)
	end
	gui.Enabled = F.estOuverte()
end

-- Minerais épuisés : retirés de l'enclume ; le sac est reconstruit sur le nouvel état
local function apresChangementSac()
	for i = #poses, 1, -1 do
		if possede(poses[i]) <= 0 then
			table.remove(poses, i)
		end
	end
	construireSac()
	rafraichir()
end

boutonForger.Activated:Connect(function()
	if enAttente or not boutonForger.Active then
		return
	end
	local comp = composition()
	enAttente = true
	rafraichirApercu()
	-- coups de marteau pendant que le serveur forge (anticipation)
	task.spawn(function()
		for k = 1, 2 do
			jouer("metal", 0.6 + k * 0.1)
			UI.secouer(scene, 4 + k * 2)
			UI.gerbe(scene, T.Braise, 6, Vector2.new(0.5, 0.75))
			task.wait(0.18)
		end
	end)
	local ok, rep = pcall(function()
		return fnAction:InvokeServer({action = "forger", type = typeChoisi, composition = comp})
	end)
	task.wait(0.3)
	local reussi = ok and type(rep) == "table" and rep.ok == true
	if reussi then
		attendreCinematique()
	end
	enAttente = false
	if ok and type(rep) == "table" then
		if type(rep.etat) == "table" then
			etat = rep.etat
		end
		message(tostring(rep.message), reussi)
	else
		message("Brom n'a pas répondu, réessaie", false)
	end
	apresChangementSac()
	if reussi then
		celebrer(rep.objet)
	else
		jouer("clic", 0.6)
		UI.secouer(boutonForger, 10)
		local rouge = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Rouge, BackgroundTransparency = 0.3, ZIndex = 10,
			Parent = boutonForger}, {coin(0.22)})
		TweenService:Create(rouge, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.delay(0.5, rouge.Destroy, rouge)
	end
end)

-- ================= Ouverture / fermeture =================
F.surFermeture.Event:Connect(function()
	decor.arreter()
	modeAjout = false
	-- réactivée un peu après (comme les autres invites coupées par InterfaceMine) : le E qui ferme ne rouvre pas
	task.delay(0.25, function()
		if promptForge and not F.estOuverte() then
			promptForge.Enabled = true
		end
	end)
end)

local function ouvrirForge(nouvelEtat: Etat, part: BasePart)
	etat = nouvelEtat
	pointForge = part
	promptForge = part:FindFirstChildOfClass("ProximityPrompt")
	if promptForge then
		promptForge.Enabled = false -- cache l'invite chez ce joueur tant que la forge est ouverte
	end
	-- aucun minerai proposé d'office : l'enclume garde seulement ce que le joueur avait posé et possède encore
	modeAjout = false
	apresChangementSac()
	F.ouvrir()
	decor.demarrer()
end

evOuvrir.OnClientEvent:Connect(function(nouvelEtat: any, part: any)
	if type(nouvelEtat) == "table" and type(nouvelEtat.minerais) == "table" and type(nouvelEtat.objets) == "table"
		and typeof(part) == "Instance" and part:IsA("BasePart") then
		ouvrirForge(nouvelEtat, part)
	end
end)

-- Fermeture au clavier / manette : touche d'interaction (E / X), gérée par InterfaceMine.fenetre

-- Les pièces changent (minage, autre achat) : bourse et bouton Forger se mettent à jour
task.spawn(function()
	local stats = joueur:WaitForChild("leaderstats", 30)
	local v = stats and stats:WaitForChild("Pièces", 30)
	if v and v:IsA("IntValue") then
		majBourse(v.Value, true)
		v.Changed:Connect(function(n)
			majBourse(n)
			if F.estOuverte() then
				rafraichirApercu()
			end
		end)
	end
end)

-- On s'éloigne de Brom ou on meurt : la forge se ferme
task.spawn(function()
	while true do
		task.wait(0.3)
		if F.estOuverte() then
			local perso = joueur.Character
			local racine = perso and perso:FindFirstChild("HumanoidRootPart")
			local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
			if not (racine and racine:IsA("BasePart") and humanoid and humanoid.Health > 0 and pointForge and pointForge.Parent)
				or (racine.Position - pointForge.Position).Magnitude > DISTANCE_FERMETURE then
				F.fermerFenetre()
			end
		end
	end
end)
