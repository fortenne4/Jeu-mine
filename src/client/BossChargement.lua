-- Boss du village · CLIENT, écran de chargement des boss (module de BossCinematique) :
-- un décor propre à chaque boss (géode du Titan, nid de la Reine, coulée de lave du Seigneur), portrait 3D du vrai
-- modèle (MobsVoxels) dans un ViewportFrame en contre-jour (zoom d'apparition, rotation lente, rugissement), nom en
-- impact (secousse, flash, éclats), titre tapé lettre par lettre, menace, mineurs, attaques à éviter, conseil, jauge
-- thématique, astuces en fondu, vignettage, grain, parallaxe. Rien n'est créé à chaque image : l'écran est construit
-- une fois, chaque décor au premier affichage de son boss, puis tout est réutilisé (particules recyclées).
-- API : Chargement.creer(cinema, Config, dossier) → {racine, etat, progresser(v, duree, style?), montrer(d), cacher()}
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local BLANC, NOIR = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local CENTRE = Vector2.new(0.5, 0.5)
local YY = Enum.SizeConstraint.RelativeYY

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- police intégrée si elle existe dans cette version de Roblox, sinon celle de secours
local function police(nom: string, defaut: Enum.Font): Enum.Font
	local ok, f = pcall(function()
		return (Enum.Font :: any)[nom]
	end)
	return if ok and f then f else defaut
end

local function transparence(points: {{number}}): NumberSequence
	local k = {}
	for _, p in points do
		table.insert(k, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(k)
end

local function couleurs(points: {any}): ColorSequence
	local k = {}
	for _, p in points do
		table.insert(k, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(k)
end

local function echapper(s: string): string
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

-- ================= Dessin (aucune image, aucun glyphe) =================
-- Conteneur carré (échelle isotrope : on peut y tracer des segments en coordonnées 0..1)
local function carre(parent: Instance, props: {[string]: any}): Frame
	props.BackgroundTransparency = 1
	props.SizeConstraint = props.SizeConstraint or YY
	props.Parent = parent
	return creer("Frame", props)
end

-- Segment de a à b (coordonnées d'un parent carré), épaisseur en pixels
local function ligne(parent: Instance, a: Vector2, b: Vector2, ep: number, couleur: Color3, transp: number?, z: number?): Frame
	local d = b - a
	return creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.new(d.Magnitude, ep, 0, ep), Rotation = math.deg(math.atan2(d.Y, d.X)), BackgroundColor3 = couleur,
		BackgroundTransparency = transp or 0, BorderSizePixel = 0, ZIndex = z or 1, Parent = parent})
end

local function rond(parent: Instance, pos: UDim2, taille: number, couleur: Color3, transp: number?, z: number?): Frame
	return creer("Frame", {AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY,
		BackgroundColor3 = couleur, BackgroundTransparency = transp or 0, BorderSizePixel = 0, ZIndex = z or 1, Parent = parent}, {coin(0.5)})
end

-- Lueur douce : trois disques concentriques (faux dégradé radial) ; l'UIScale sert à la faire respirer
local function lueur(parent: Instance, pos: UDim2, taille: number, couleur: Color3, base: number, z: number?): (Frame, UIScale)
	local g = creer("Frame", {AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent})
	for k = 1, 3 do
		local s = 0.35 + k * 0.22
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = couleur,
			BackgroundTransparency = math.min(0.97, base + k * 0.04), BorderSizePixel = 0, ZIndex = z or 1, Parent = g}, {coin(0.5)})
	end
	return g, creer("UIScale", {Parent = g})
end

-- Étincelle à 4 branches (deux traits fondus en croix + petite croix en biais + cœur)
local function etoile(parent: Instance, pos: UDim2, taille: number, couleur: Color3, z: number): (Frame, UIScale)
	local s = creer("Frame", {AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z, Parent = parent})
	local fondu = transparence({{0, 1}, {0.5, 0}, {1, 1}})
	for _, r in {0, 90} do
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.1), Rotation = r,
			BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = z, Parent = s}, {coin(0.5), creer("UIGradient", {Transparency = fondu})})
	end
	for _, r in {45, 135} do
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.07), Rotation = r,
			BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = z, Parent = s}, {coin(0.5), creer("UIGradient", {Transparency = fondu})})
	end
	rond(s, UDim2.fromScale(0.5, 0.5), 0.2, BLANC, 0, z)
	return s, creer("UIScale", {Scale = 0, Parent = s})
end

-- Éclat de cristal à facettes : corps + pointe en losange, face gauche claire / face droite sombre
local function cristal(parent: Instance, x: number, y: number, l: number, h: number, rot: number, c1: Color3, c2: Color3, z: number): Frame
	local g = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(l, h), Rotation = rot,
		BackgroundTransparency = 1, ZIndex = z, Parent = parent})
	local facettes = couleurs({{0, c1:Lerp(BLANC, 0.45)}, {0.5, c1}, {0.501, c2}, {1, c2:Lerp(NOIR, 0.35)}})
	creer("Frame", {Position = UDim2.fromScale(0, 0.16), Size = UDim2.fromScale(1, 0.84), BackgroundColor3 = BLANC, BorderSizePixel = 0,
		ZIndex = z, Parent = g}, {creer("UIGradient", {Color = facettes}), trait(c1:Lerp(BLANC, 0.5), 1, 0.45)})
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromScale(0.707, 0.707),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, Rotation = 45, BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = z, Parent = g},
		{creer("UIGradient", {Rotation = -45, Color = facettes}), trait(c1:Lerp(BLANC, 0.5), 1, 0.45)})
	return g
end

-- Petite araignée vue de dessus (corps, tête, 8 pattes, yeux rouges), dans un carré
local function araignee(parent: Instance, props: {[string]: any}, couleur: Color3, yeux: Color3): Frame
	local z = props.ZIndex or 1
	local a = carre(parent, props)
	for _, cote in {-1, 1} do
		for k = 1, 4 do
			local ang = math.rad(-60 + (k - 1) * 38)
			local p1 = Vector2.new(0.5 + cote * 0.1, 0.45 + (k - 2.5) * 0.06)
			local p2 = Vector2.new(0.5 + cote * (0.1 + math.cos(ang) * 0.28), 0.45 + math.sin(ang) * 0.28)
			local p3 = Vector2.new(p2.X + cote * 0.12, p2.Y + 0.16)
			ligne(a, p1, p2, 2, couleur, 0, z)
			ligne(a, p2, p3, 2, couleur, 0, z)
		end
	end
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.34, 0.4), BackgroundColor3 = couleur,
		BorderSizePixel = 0, ZIndex = z, Parent = a}, {coin(0.5)})
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.33), Size = UDim2.fromScale(0.22, 0.2), BackgroundColor3 = couleur,
		BorderSizePixel = 0, ZIndex = z, Parent = a}, {coin(0.5)})
	for _, x in {0.45, 0.55} do
		rond(a, UDim2.fromScale(x, 0.3), 0.06, yeux, 0, z)
	end
	return a
end

-- Crâne (niveau de menace) : renvoie le cadre et ses pièces à colorer
local function crane(parent: Instance, ordre: number): (Frame, {Frame}, {Frame})
	local c = creer("Frame", {Name = "Crane" .. ordre, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), SizeConstraint = YY,
		LayoutOrder = ordre, Parent = parent})
	local os_ = {
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.8, 0.64),
			BorderSizePixel = 0, Parent = c}, {coin(0.45)}),
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.5, 0.32),
			BorderSizePixel = 0, Parent = c}, {coin(0.25)}),
	}
	local trous = {}
	for _, x in {0.33, 0.67} do
		table.insert(trous, creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, 0.37), Size = UDim2.fromScale(0.24, 0.24),
			BorderSizePixel = 0, ZIndex = 2, Parent = c}, {coin(0.5)}))
	end
	for _, x in {0.42, 0.58} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, 0.72), Size = UDim2.fromScale(0.06, 0.16),
			BackgroundColor3 = rgb(14, 10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = c})
	end
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.09, 0.09), Rotation = 45,
		BackgroundColor3 = rgb(14, 10, 10), BorderSizePixel = 0, ZIndex = 2, Parent = c})
	return c, os_, trous
end

-- ================= Thèmes =================
local THEMES = {
	TitanCristal = {
		fond = {rgb(10, 16, 44), rgb(26, 16, 58), rgb(4, 5, 16)}, vignette = rgb(2, 4, 16),
		accent = rgb(130, 215, 255), accent2 = rgb(185, 140, 255),
		nom = {rgb(240, 252, 255), rgb(150, 215, 255), rgb(130, 95, 235)},
		police = police("Sarpanch", Enum.Font.Fantasy),
		ambiance = rgb(70, 82, 135), lumiere = rgb(175, 225, 255), menace = 4,
		devise = "« Les cristaux chantent quand il s'éveille. »",
	},
	ReineAraignee = {
		fond = {rgb(8, 18, 11), rgb(16, 24, 16), rgb(12, 6, 16)}, vignette = rgb(2, 6, 3),
		accent = rgb(150, 255, 110), accent2 = rgb(235, 60, 55),
		nom = {rgb(236, 255, 226), rgb(160, 240, 120), rgb(110, 55, 160)},
		police = police("Creepster", Enum.Font.Fantasy),
		ambiance = rgb(60, 92, 62), lumiere = rgb(175, 255, 140), menace = 4,
		devise = "« Chaque galerie est un fil de sa toile. »",
	},
	SeigneurBraise = {
		fond = {rgb(14, 4, 3), rgb(42, 10, 5), rgb(96, 26, 6)}, vignette = rgb(10, 2, 0),
		accent = rgb(255, 150, 60), accent2 = rgb(255, 225, 110),
		nom = {rgb(255, 248, 210), rgb(255, 170, 60), rgb(200, 45, 20)},
		police = police("GrenzeGotisch", Enum.Font.Fantasy),
		ambiance = rgb(110, 60, 45), lumiere = rgb(255, 170, 90), menace = 5,
		devise = "« Le volcan respire à travers lui. »",
	},
}

-- noms lisibles des attaques (BossVillage.BOSS[i].attaques / attaquesEnrage)
local ATTAQUES = {
	Onde = "Onde de choc", Poings = "Poings sismiques", Eclats = "Éclats de cristal", Cristaux = "Pics de cristal",
	Toile = "Toile en cône", Invocation = "Nuée d'araignées", Bond = "Bond écrasant", Acide = "Pluie d'acide",
	Meteores = "Pluie de météores", Lave = "Cercle de lave", Souffle = "Souffle de feu", Colonnes = "Colonnes de feu",
}

local Chargement = {}

function Chargement.creer(cinema: ScreenGui, Config: any, dossier: Instance)
	local MobsVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MobsVoxels"))

	local generation = 0
	local actifs: {[Tween]: boolean} = {} -- tweens lancés par les cycles (annulés au masquage)

	-- Relance etape() à chaque fin de tween tant que l'écran est affiché pour cette génération (particules recyclées)
	local function cycle(gen: number, delai: number, etape: () -> Tween)
		local function suivant()
			if gen ~= generation then return end
			local t = etape()
			actifs[t] = true
			t.Completed:Once(function(etat)
				actifs[t] = nil
				if etat == Enum.PlaybackState.Completed then suivant() end
			end)
			t:Play()
		end
		task.delay(delai, suivant)
	end

	-- ================= Ossature =================
	local racine = creer("Frame", {Name = "Chargement", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false, ZIndex = 50, Parent = cinema})

	-- couche 1 : fond (dégradé du thème + décor lointain), légèrement plus grande pour la parallaxe
	local fondCouche = creer("Frame", {Name = "Fond", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.05, 1.05),
		BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 1, Parent = racine})
	local fondDegrade = creer("UIGradient", {Rotation = 90, Parent = fondCouche})

	-- couche 2 : scène du boss (rayons, halos, portrait 3D)
	local scene = creer("Frame", {Name = "Scene", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.7, 0.5), Size = UDim2.fromScale(1.05, 1.05),
		SizeConstraint = YY, BackgroundTransparency = 1, ZIndex = 2, Parent = racine})
	local rayons = creer("CanvasGroup", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(1.5, 1.5),
		BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 1, Parent = scene})
	for k = 1, 10 do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.05 + (k % 3) * 0.025, 0.5),
			Rotation = k * 36, BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = rayons},
			{creer("UIGradient", {Rotation = 90, Transparency = transparence({{0, 1}, {0.55, 0.78}, {1, 0.45}})})})
	end
	-- (la rotation d'un enfant de cadre ne pivote pas autour du centre : les rayons sont ancrés au centre et
	-- c'est le CanvasGroup entier qui tourne)
	local halos: {Frame} = {}
	for k = 1, 3 do
		table.insert(halos, creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.35 + k * 0.2, 0.35 + k * 0.2),
			BackgroundColor3 = BLANC, BackgroundTransparency = 0.8 + k * 0.05, BorderSizePixel = 0, ZIndex = 2, Parent = scene}, {coin(0.5)}))
	end
	local anneauHalo = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78),
		BackgroundTransparency = 1, ZIndex = 2, Parent = scene}, {coin(0.5), trait(BLANC, 2, 0.6)})
	local portrait = creer("ViewportFrame", {Name = "Portrait", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3,
		Ambient = rgb(80, 80, 100), LightColor = BLANC, LightDirection = Vector3.new(0, -1, 0), ImageColor3 = NOIR, Parent = scene})
	local camVue = creer("Camera", {FieldOfView = 38, Parent = portrait})
	portrait.CurrentCamera = camVue
	local monde = creer("WorldModel", {Parent = portrait})
	-- ombre au sol sous le boss
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.62, 0.07), BackgroundColor3 = NOIR,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2, Parent = scene},
		{coin(0.5), creer("UIGradient", {Transparency = transparence({{0, 1}, {0.5, 0.1}, {1, 1}})})})

	-- couche 3 : décor de premier plan (plus de parallaxe)
	local avantCouche = creer("Frame", {Name = "Avant", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.06, 1.06),
		BackgroundTransparency = 1, ZIndex = 3, Parent = racine})

	-- ombre de lecture à gauche, vignettage sur les 4 bords
	creer("Frame", {Size = UDim2.fromScale(0.66, 1), BackgroundColor3 = NOIR, BorderSizePixel = 0, ZIndex = 4, Parent = racine},
		{creer("UIGradient", {Transparency = transparence({{0, 0.2}, {0.55, 0.45}, {1, 1}})})})
	local vignettes: {Frame} = {}
	for _, v in {{Vector2.new(0, 0), UDim2.fromScale(1, 0.3), 90, false}, {Vector2.new(0, 1), UDim2.fromScale(1, 0.3), 90, true},
		{Vector2.new(0, 0), UDim2.fromScale(0.22, 1), 0, false}, {Vector2.new(1, 0), UDim2.fromScale(0.22, 1), 0, true}} do
		local f = creer("Frame", {AnchorPoint = v[1], Position = UDim2.fromScale(v[1].X, v[1].Y), Size = v[2], BackgroundColor3 = NOIR,
			BorderSizePixel = 0, ZIndex = 5, Parent = racine}, {creer("UIGradient", {Rotation = v[3],
			Transparency = if v[4] then transparence({{0, 1}, {1, 0.05}}) else transparence({{0, 0.05}, {1, 1}})})})
		table.insert(vignettes, f)
	end

	-- couche 4 : contenu (textes, jauge) : c'est elle qui tremble à l'impact du nom
	local contenu = creer("Frame", {Name = "Contenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Parent = racine})
	-- bandes cinéma
	creer("Frame", {Size = UDim2.fromScale(1, 0.07), BackgroundColor3 = NOIR, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = contenu})
	creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = NOIR,
		BorderSizePixel = 0, Parent = contenu}, {creer("UIGradient", {Rotation = 90, Transparency = transparence({{0, 1}, {0.35, 0.25}, {1, 0.05}})})})
	local filetHaut = creer("Frame", {Position = UDim2.fromScale(0, 0.07), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = BLANC, BorderSizePixel = 0,
		Parent = contenu}, {creer("UIGradient", {Transparency = transparence({{0, 1}, {0.3, 0.3}, {0.7, 0.3}, {1, 1}})})})

	-- en haut à droite : n° du boss, renforts, durée max
	local badge = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Right, RichText = true,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.965, 0.035), Size = UDim2.fromScale(0.4, 0.032), Parent = contenu}, 20)

	-- ----- panneau d'informations (gauche) -----
	local info = creer("Frame", {Name = "Infos", Position = UDim2.fromScale(0.045, 0.115), Size = UDim2.fromScale(0.47, 0.68),
		BackgroundTransparency = 1, Parent = contenu})
	local surtitre = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.8, 0.045), Parent = info}, 20)
	local surTrait = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.058), Size = UDim2.fromScale(0.12, 0.004),
		BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = info})

	local nomProps = {Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.18), Size = UDim2.fromScale(1, 0.22), ZIndex = 3, Parent = info}
	local nom = texte(table.clone(nomProps), 120)
	local nomDegrade = creer("UIGradient", {Rotation = 90, Parent = nom})
	creer("UIStroke", {Thickness = 3, Color = rgb(10, 6, 4), Parent = nom})
	local lueurProps = table.clone(nomProps)
	lueurProps.ZIndex = 2
	local nomLueur = texte(lueurProps, 120)
	local lueurTrait = creer("UIStroke", {Thickness = 9, Transparency = 0.8, Parent = nomLueur})
	local echoProps = table.clone(nomProps)
	echoProps.ZIndex = 4
	local nomEcho = texte(echoProps, 120)
	local echelleNom = UI.echelle(nom)
	local echelleEcho = UI.echelle(nomEcho)

	local titre = texte({Font = Enum.Font.Antique, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0, 0.295),
		Size = UDim2.fromScale(1, 0.065), Parent = info}, 40)
	creer("UIStroke", {Thickness = 2, Color = rgb(8, 5, 3), Parent = titre})
	local devise = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.365), Size = UDim2.fromScale(1, 0.042), Parent = info}, 22)
	local separateur = creer("Frame", {Position = UDim2.fromScale(0, 0.43), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = BLANC, BorderSizePixel = 0,
		Parent = info}, {creer("UIGradient", {Transparency = transparence({{0, 0}, {0.7, 0.3}, {1, 1}})})})

	-- menace + mineurs
	local stats = creer("CanvasGroup", {Position = UDim2.fromScale(0, 0.455), Size = UDim2.fromScale(1, 0.1), BackgroundTransparency = 1,
		GroupTransparency = 1, Parent = info})
	texte({Text = "MENACE", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.4, 0.34), Parent = stats}, 16)
	local rangCranes = creer("Frame", {Position = UDim2.fromScale(0, 0.4), Size = UDim2.fromScale(0.5, 0.6), BackgroundTransparency = 1, Parent = stats},
		{creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center})})
	local cranes = {}
	for i = 1, 5 do
		local c, os_, trous = crane(rangCranes, i)
		cranes[i] = {cadre = c, os = os_, trous = trous, echelle = creer("UIScale", {Parent = c})}
	end
	texte({Text = "MINEURS", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.58, 0), Size = UDim2.fromScale(0.4, 0.34), Parent = stats}, 16)
	local mineurs = texte({Font = Enum.Font.GothamBlack, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.58, 0.38), Size = UDim2.fromScale(0.42, 0.6), Parent = stats}, 30)

	-- attaques à éviter
	local titreAttaques = texte({Text = "ATTAQUES À ÉVITER", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris,
		TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Position = UDim2.fromScale(0, 0.585), Size = UDim2.fromScale(0.6, 0.034),
		Parent = info}, 16)
	local grille = creer("Frame", {Position = UDim2.fromScale(0, 0.63), Size = UDim2.fromScale(1, 0.19), BackgroundTransparency = 1, Parent = info},
		{creer("UIGridLayout", {CellSize = UDim2.fromScale(0.485, 0.42), CellPadding = UDim2.fromScale(0.03, 0.12), SortOrder = Enum.SortOrder.LayoutOrder})})
	local puces = {}
	for i = 1, 4 do
		local p = creer("Frame", {Name = "Attaque" .. i, BackgroundColor3 = rgb(14, 10, 9), BackgroundTransparency = 0.2, LayoutOrder = i,
			Visible = false, Parent = grille}, {coin(0.25)})
		local bord = trait(T.Gris, 1.5, 0.35)
		bord.Parent = p
		local losange = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.075, 0.5), Size = UDim2.fromScale(0.5, 0.5), SizeConstraint = YY,
			Rotation = 45, BackgroundColor3 = T.Rouge, BorderSizePixel = 0, Parent = p}, {coin(0.15)})
		texte({Text = "!", Font = Enum.Font.GothamBlack, TextColor3 = rgb(20, 8, 6), AnchorPoint = CENTRE, Position = UDim2.fromScale(0.075, 0.52),
			Size = UDim2.fromScale(0.1, 0.5), ZIndex = 2, Parent = p}, 20)
		local l = texte({Font = Enum.Font.GothamBold, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.16, 0.16),
			Size = UDim2.fromScale(0.8, 0.68), Parent = p}, 20)
		puces[i] = {cadre = p, bord = bord, losange = losange, texte = l, echelle = creer("UIScale", {Parent = p})}
	end

	-- conseil du boss
	local conseil = creer("CanvasGroup", {Position = UDim2.fromScale(0, 0.845), Size = UDim2.fromScale(1, 0.155), BackgroundColor3 = rgb(10, 8, 7),
		BackgroundTransparency = 0.25, GroupTransparency = 1, Parent = info}, {coin(0.12)})
	local conseilBarre = creer("Frame", {Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.012, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0,
		Parent = conseil})
	local conseilTag = texte({Text = "CONSEIL DU VÉTÉRAN", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.6, 0.26), Parent = conseil}, 16)
	local conseilTexte = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Position = UDim2.fromScale(0.04, 0.4), Size = UDim2.fromScale(0.93, 0.52), Parent = conseil}, 20)

	-- ----- jauge (bas) -----
	local etat = texte({Text = "Chargement de l'arène…", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.05, 0.835), Size = UDim2.fromScale(0.45, 0.03), Parent = contenu}, 18)
	local pourcent = texte({Text = "0 %", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.75, 0.83), Size = UDim2.fromScale(0.2, 0.038), Parent = contenu}, 30)
	creer("UIStroke", {Thickness = 2, Color = rgb(8, 5, 3), Parent = pourcent})
	local jaugeCadre = creer("Frame", {Name = "Jauge", Position = UDim2.fromScale(0.05, 0.875), Size = UDim2.fromScale(0.9, 0.024),
		BackgroundTransparency = 1, Parent = contenu}, {creer("UISizeConstraint", {MinSize = Vector2.new(200, 9)})})
	local eclatJauge = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 10, Parent = jaugeCadre}, {coin(0.5)})
	local astuce = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, RichText = true, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.925), Size = UDim2.fromScale(0.86, 0.036), Parent = contenu}, 22)

	-- grain de pellicule (points recyclés), flash, ouverture au noir
	local grain = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7, Parent = racine})
	local points: {Frame} = {}
	for i = 1, 40 do
		points[i] = creer("Frame", {Size = UDim2.fromOffset(2, 2), BackgroundColor3 = if i % 2 == 0 then BLANC else NOIR, BorderSizePixel = 0, Parent = grain})
	end
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8,
		Parent = racine})
	local ouverture = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BorderSizePixel = 0, ZIndex = 9, Parent = racine})

	local bouclesCommunes: {Tween} = {
		TweenService:Create(rayons, TweenInfo.new(40, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}),
		TweenService:Create(anneauHalo, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.fromScale(0.86, 0.86)}),
	}

	-- ================= Décors par boss (construits au premier affichage) =================
	type Decor = {fond: Frame, avant: Frame, jauge: Frame, remplir: (number) -> (), tete: GuiObject, boucles: {Tween}, demarrer: (number) -> ()}
	local decors: {[string]: Decor} = {}

	local function couches(id: string): (Frame, Frame, Frame)
		local f = creer("Frame", {Name = id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = fondCouche})
		local a = creer("Frame", {Name = id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = avantCouche})
		local j = creer("Frame", {Name = id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = jaugeCadre})
		return f, a, j
	end

	-- ---------- Titan de cristal : géode ----------
	local function decorTitan(th): Decor
		local f, a, j = couches("TitanCristal")
		local boucles: {Tween} = {}
		local rng = Random.new(7)
		local c1, c2 = rgb(150, 205, 255), rgb(95, 70, 200)
		-- lueurs froides au fond
		for _, l in {{0.86, 0.85, 0.9, c1}, {0.12, 0.92, 0.6, c2}, {0.95, 0.08, 0.55, c2}} do
			local _, e = lueur(f, UDim2.fromScale(l[1], l[2]), l[3], l[4], 0.84, 1)
			table.insert(boucles, TweenService:Create(e, TweenInfo.new(2 + rng:NextNumber(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.12}))
		end
		-- veines de la géode (anneaux à facettes derrière le boss)
		local geode = carre(f, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.7, 0.5), Size = UDim2.fromScale(1.2, 1.2), ZIndex = 1})
		for r = 1, 3 do
			local rayon, n = 0.22 + r * 0.08, 14 + r * 4
			for k = 0, n - 1 do
				local a1, a2 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
				local r1, r2 = rayon * (0.96 + ((k * 7) % 5) * 0.02), rayon * (0.96 + (((k + 1) * 7) % 5) * 0.02)
				ligne(geode, Vector2.new(0.5 + math.cos(a1) * r1, 0.5 + math.sin(a1) * r1), Vector2.new(0.5 + math.cos(a2) * r2, 0.5 + math.sin(a2) * r2),
					2, if r == 2 then c2 else c1, 0.72 + r * 0.06, 1)
			end
		end
		-- amas de cristaux : bas droite (grand), haut droite (suspendu), bas gauche, haut gauche (petits, sombres)
		local function amas(props, nb: number, suspendu: boolean, clair: Color3, sombre: Color3)
			local g = carre(a, props)
			for k = 1, nb do
				local x = 0.12 + (k - 1) / math.max(1, nb - 1) * 0.8 + rng:NextNumber(-0.05, 0.05)
				local h = rng:NextNumber(0.3, 0.85) * (1 - math.abs(x - 0.6) * 0.7)
				local l = h * rng:NextNumber(0.2, 0.3)
				if suspendu then
					cristal(g, x, h, l, h, 180 + rng:NextNumber(-18, 18), clair, sombre, 2)
				else
					cristal(g, x, 1.02, l, h, rng:NextNumber(-28, 28), clair, sombre, 2)
				end
			end
			return g
		end
		amas({AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1.02, 1.04), Size = UDim2.fromScale(0.5, 0.5), ZIndex = 2}, 7, false, c1, c2)
		amas({AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.98, -0.02), Size = UDim2.fromScale(0.34, 0.34), ZIndex = 2}, 6, true, c1, c2)
		amas({AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(-0.03, 1.04), Size = UDim2.fromScale(0.3, 0.3), ZIndex = 2}, 5, false,
			rgb(80, 110, 170), rgb(45, 35, 110))
		amas({AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromScale(0.3, -0.03), Size = UDim2.fromScale(0.2, 0.2), ZIndex = 2}, 4, true,
			rgb(80, 110, 170), rgb(45, 35, 110))
		-- étincelles qui scintillent (chacune a son retard : le tween se rejoue avec lui)
		for _ = 1, 16 do
			local x = if rng:NextNumber() < 0.6 then rng:NextNumber(0.55, 0.98) else rng:NextNumber(0.02, 0.5)
			local y = if x < 0.52 then (if rng:NextNumber() < 0.5 then rng:NextNumber(0.08, 0.11) else rng:NextNumber(0.82, 0.98)) else rng:NextNumber(0.09, 0.95)
			local _, e = etoile(a, UDim2.fromScale(x, y), rng:NextNumber(0.025, 0.055), if rng:NextNumber() < 0.5 then c1 else rgb(220, 190, 255), 3)
			table.insert(boucles, TweenService:Create(e, TweenInfo.new(rng:NextNumber(0.35, 0.6), Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true,
				rng:NextNumber(0.4, 2.6)), {Scale = 1}))
		end
		-- poussière de givre qui monte lentement (recyclée)
		local poussieres = {}
		for k = 1, 14 do
			poussieres[k] = rond(a, UDim2.fromScale(0.5, 1.1), rng:NextNumber(0.004, 0.009), if k % 2 == 0 then c1 else rgb(210, 200, 255), 0.2, 1)
		end

		-- jauge : cristal à facettes qui se remplit, gemme au bout
		local fondJ = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(12, 16, 38), BorderSizePixel = 0, Parent = j},
			{coin(0.3), trait(rgb(100, 125, 210), 1.5, 0.2)})
		local rempli = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
			Parent = fondJ}, {coin(0.3), creer("UIGradient", {Rotation = 90, Color = couleurs({{0, rgb(235, 250, 255)}, {0.45, rgb(140, 210, 255)},
			{0.55, rgb(110, 115, 240)}, {1, rgb(70, 45, 170)}})})})
		local reflet = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(-0.2, 0.5), Size = UDim2.fromScale(0.15, 3), Rotation = 25,
			BackgroundColor3 = BLANC, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Parent = rempli},
			{creer("UIGradient", {Transparency = transparence({{0, 1}, {0.5, 0}, {1, 1}})})})
		table.insert(boucles, TweenService:Create(reflet, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 0.3),
			{Position = UDim2.fromScale(1.2, 0.5)}))
		for k = 1, 9 do
			creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(k / 10, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = rgb(8, 10, 30),
				BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 4, Parent = fondJ})
		end
		local tete = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(2, 2), SizeConstraint = YY,
			BackgroundTransparency = 1, ZIndex = 5, Parent = fondJ})
		local _, eT = lueur(tete, UDim2.fromScale(0.5, 0.5), 2.4, c1, 0.7, 5)
		table.insert(boucles, TweenService:Create(eT, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.3}))
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.75, 0.75), Rotation = 45, BackgroundColor3 = BLANC,
			BorderSizePixel = 0, ZIndex = 6, Parent = tete}, {creer("UIGradient", {Rotation = -45, Color = couleurs({{0, rgb(245, 252, 255)}, {0.5, c1},
			{0.501, c2}, {1, rgb(50, 30, 120)}})}), trait(BLANC, 1.5, 0.1)})

		return {fond = f, avant = a, jauge = j, tete = tete, boucles = boucles,
			remplir = function(v)
				rempli.Size = UDim2.fromScale(v, 1)
				tete.Position = UDim2.fromScale(v, 0.5)
			end,
			demarrer = function(gen)
				for k, p in poussieres do
					cycle(gen, k * 0.25, function()
						local x = math.random() * 0.98
						p.Position = UDim2.fromScale(x, 1.05)
						p.BackgroundTransparency = 0.15
						return TweenService:Create(p, TweenInfo.new(4 + math.random() * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.1, 0.25 + math.random() * 0.3), BackgroundTransparency = 1})
					end)
				end
			end}
	end

	-- ---------- Reine araignée : nid ----------
	local function decorReine(th): Decor
		local f, a, j = couches("ReineAraignee")
		local boucles: {Tween} = {}
		local rng = Random.new(11)
		local soie = rgb(222, 232, 214)
		-- brume verte au ras du sol (fond) et devant les pattes (avant)
		for k = 1, 6 do
			local devant = k > 4
			local b = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(rng:NextNumber(0.1, 0.9), if devant then 0.92 else rng:NextNumber(0.55, 0.95)),
				Size = UDim2.fromScale(rng:NextNumber(0.45, 0.8), rng:NextNumber(0.18, 0.32)), BackgroundColor3 = rgb(90, 170, 90),
				BackgroundTransparency = if devant then 0.82 else 0.86, BorderSizePixel = 0, ZIndex = 1, Parent = if devant then a else f},
				{coin(0.5), creer("UIGradient", {Transparency = transparence({{0, 1}, {0.5, 0.2}, {1, 1}})})})
			table.insert(boucles, TweenService:Create(b, TweenInfo.new(rng:NextNumber(5, 9), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Position = b.Position + UDim2.fromScale(rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.03, 0.03))}))
		end
		local _, eL = lueur(f, UDim2.fromScale(0.7, 0.75), 1.1, rgb(80, 200, 90), 0.86, 1)
		table.insert(boucles, TweenService:Create(eL, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.1}))
		-- yeux rouges dans l'ombre (paires) qui clignent
		local yeux: {{Frame}} = {}
		local placesYeux = {{0.02, 0.14}, {0.12, 0.09}, {0.27, 0.095}, {0.44, 0.085}, {0.56, 0.16}, {0.97, 0.3}, {0.93, 0.52}, {0.985, 0.68},
			{0.012, 0.42}, {0.02, 0.62}, {0.52, 0.8}, {0.86, 0.12}}
		for _, p in placesYeux do
			local t = rng:NextNumber(0.7, 1.4)
			local paire = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(p[1], p[2]), Size = UDim2.fromScale(0.045 * t, 0.018 * t),
				SizeConstraint = YY, BackgroundTransparency = 1, ZIndex = 2, Parent = f})
			local duo = {}
			for _, x in {0.25, 0.75} do
				table.insert(duo, creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromScale(0.3, 0.8),
					BackgroundColor3 = th.accent2, BorderSizePixel = 0, ZIndex = 2, Parent = paire}, {coin(0.5), trait(rgb(255, 40, 30), 2, 0.55)}))
			end
			table.insert(yeux, duo)
		end
		-- toiles qui se tissent dans les coins : rayons puis spirale, segment par segment
		local tissages: {{any}} = {}
		local function toile(props, ox: number, oy: number, sx: number, sy: number)
			local g = carre(a, props)
			local segments: {Frame} = {}
			local n, angles = 6, {}
			for k = 0, n do
				angles[k] = (k / n) * math.pi / 2 + (if k > 0 and k < n then rng:NextNumber(-0.08, 0.08) else 0)
			end
			local function pt(ang: number, r: number): Vector2
				return Vector2.new(ox + sx * math.cos(ang) * r, oy + sy * math.sin(ang) * r)
			end
			for k = 0, n do
				table.insert(segments, ligne(g, pt(angles[k], 0), pt(angles[k], 0.98), 2, soie, 1, 2))
			end
			for _, r in {0.2, 0.36, 0.52, 0.68, 0.84} do
				for k = 0, n - 1 do
					local milieu = (angles[k] + angles[k + 1]) / 2
					local p1, p2, pm = pt(angles[k], r), pt(angles[k + 1], r), pt(milieu, r * 0.92)
					table.insert(segments, ligne(g, p1, pm, 1.5, soie, 1, 2))
					table.insert(segments, ligne(g, pm, p2, 1.5, soie, 1, 2))
				end
			end
			local v = Instance.new("NumberValue")
			local montres = 0
			v.Changed:Connect(function(x)
				local cible = math.floor(x)
				if cible < montres then
					for i = cible + 1, montres do segments[i].BackgroundTransparency = 1 end
				else
					for i = montres + 1, math.min(cible, #segments) do segments[i].BackgroundTransparency = 0.45 end
				end
				montres = math.min(cible, #segments)
			end)
			table.insert(tissages, {v, #segments})
		end
		toile({AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.3, 0.3), ZIndex = 2}, 0, 0, 1, 1)
		toile({AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.48, 0.48), ZIndex = 2}, 1, 0, -1, 1)
		toile({AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromScale(0.36, 0.36), ZIndex = 2}, 1, 1, -1, -1)
		-- œufs du nid (bas droite) : coque pâle, embryon sombre qui bouge, halo vert qui pulse
		local nid = carre(a, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.97, 1.02), Size = UDim2.fromScale(0.3, 0.3), ZIndex = 3})
		for k = 1, 7 do
			local l = rng:NextNumber(0.16, 0.24)
			local oeuf = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.08 + (k - 1) * 0.13 + rng:NextNumber(-0.03, 0.03),
				1 - (k % 2) * 0.12), Size = UDim2.fromScale(l, l * 1.3), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 3 + (k % 2), Parent = nid},
				{coin(0.5), creer("UIGradient", {Rotation = 70, Color = couleurs({{0, rgb(225, 238, 205)}, {1, rgb(110, 140, 90)}})})})
			local halo = trait(th.accent, 2.5, 0.5)
			halo.Parent = oeuf
			table.insert(boucles, TweenService:Create(halo, TweenInfo.new(rng:NextNumber(0.8, 1.4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.95, Thickness = 1}))
			local embryon = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.45, 0.38),
				BackgroundColor3 = rgb(40, 50, 30), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 3 + (k % 2), Parent = oeuf}, {coin(0.5)})
			table.insert(boucles, TweenService:Create(embryon, TweenInfo.new(rng:NextNumber(0.6, 1.1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true,
				rng:NextNumber(0, 1)), {Position = UDim2.fromScale(0.5 + rng:NextNumber(-0.12, 0.12), 0.48)}))
		end
		-- petites araignées qui descendent au bout d'un fil
		local descentes = {}
		for k, p in {{0.58, 0.2}, {0.82, 0.36}, {0.955, 0.14}} do
			local fil = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(p[1], 0), Size = UDim2.new(0, 1, 0, 0),
				BackgroundColor3 = soie, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 4, Parent = a})
			local bete = araignee(a, {AnchorPoint = Vector2.new(0.5, 0.25), Position = UDim2.fromScale(p[1], 0), Size = UDim2.fromScale(0.05, 0.05), ZIndex = 5},
				rgb(26, 20, 28), th.accent2)
			local d = 2.4 + k * 0.5
			table.insert(boucles, TweenService:Create(fil, TweenInfo.new(d, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(0, 1, p[2], 0)}))
			table.insert(boucles, TweenService:Create(bete, TweenInfo.new(d, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.fromScale(p[1], p[2])}))
			table.insert(boucles, TweenService:Create(bete, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 12}))
			table.insert(descentes, {fil, bete, p[1]})
		end

		-- jauge : fil de soie tendu, nœuds de toile, araignée qui avance au bout
		local filFond = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = soie, BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = j})
		local _ = filFond
		local rempli = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 0, 0, 4),
			BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 2, Parent = j},
			{coin(0.5), creer("UIGradient", {Color = couleurs({{0, rgb(120, 220, 90)}, {1, rgb(240, 255, 230)}})})})
		local noeuds: {Frame} = {}
		for k = 1, 9 do
			noeuds[k] = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(k / 10, 0.5), Size = UDim2.fromScale(0.7, 0.7), SizeConstraint = YY,
				Rotation = 45, BackgroundColor3 = soie, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 3, Parent = j})
		end
		local tete = araignee(j, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(2.6, 2.6), Rotation = 90, ZIndex = 4},
			rgb(30, 24, 34), th.accent2)
		table.insert(boucles, TweenService:Create(tete, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 98}))

		return {fond = f, avant = a, jauge = j, tete = tete, boucles = boucles,
			remplir = function(v)
				rempli.Size = UDim2.new(v, 0, 0, 4)
				tete.Position = UDim2.fromScale(v, 0.5)
				for k, n in noeuds do
					local passe = v >= k / 10
					n.BackgroundColor3 = if passe then th.accent else soie
					n.BackgroundTransparency = if passe then 0 else 0.7
				end
			end,
			demarrer = function(gen)
				for _, t in tissages do
					local v: NumberValue = t[1]
					v.Value = 0
					local tw = TweenService:Create(v, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = t[2]})
					actifs[tw] = true
					tw.Completed:Once(function() actifs[tw] = nil end)
					tw:Play()
				end
				for _, dsc in descentes do
					dsc[1].Size = UDim2.new(0, 1, 0, 0)
					dsc[2].Position = UDim2.fromScale(dsc[3], 0)
				end
				for _, duo in yeux do
					for _, o in duo do
						o.BackgroundTransparency = 1
						o.Size = UDim2.fromScale(0.3, 0.8)
						local tw = TweenService:Create(o, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2 + math.random() * 1.2),
							{BackgroundTransparency = 0})
						actifs[tw] = true
						tw.Completed:Once(function() actifs[tw] = nil end)
						tw:Play()
					end
				end
				-- clignements : une paire au hasard toutes les ~0,3 s
				task.spawn(function()
					task.wait(1.2)
					while gen == generation do
						local duo = yeux[math.random(#yeux)]
						for _, o in duo do
							TweenService:Create(o, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
								{Size = UDim2.fromScale(0.3, 0.05)}):Play()
						end
						task.wait(0.2 + math.random() * 0.3)
					end
				end)
			end}
	end

	-- ---------- Seigneur de braise : lave ----------
	local function decorSeigneur(th): Decor
		local f, a, j = couches("SeigneurBraise")
		local boucles: {Tween} = {}
		local rng = Random.new(23)
		-- chaleur au sol
		local chaleur = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.45),
			BackgroundColor3 = rgb(255, 90, 20), BorderSizePixel = 0, ZIndex = 1, Parent = f},
			{creer("UIGradient", {Rotation = 90, Transparency = transparence({{0, 1}, {0.6, 0.7}, {1, 0.35}})})})
		table.insert(boucles, TweenService:Create(chaleur, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.35}))
		local _, eL = lueur(f, UDim2.fromScale(0.7, 0.62), 1.2, rgb(255, 110, 30), 0.82, 1)
		table.insert(boucles, TweenService:Create(eL, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.08}))
		-- fissures de lave au sol (un seul CanvasGroup : la pulsation n'est qu'un tween de GroupColor3)
		local fissures = creer("CanvasGroup", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.42),
			BackgroundTransparency = 1, ZIndex = 2, Parent = f})
		for k, x in {0, 0.19, 0.4, 0.6, 0.8} do
			local g = carre(fissures, {Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(1, 1)})
			local function branche(p: Vector2, ang: number, n: number, ep: number)
				for _ = 1, n do
					local pas = rng:NextNumber(0.07, 0.13)
					ang += rng:NextNumber(-0.6, 0.6)
					local q = p + Vector2.new(math.cos(ang), math.sin(ang)) * pas
					ligne(g, p, q, ep * 3.5, rgb(255, 80, 15), 0.78, 1)
					ligne(g, p, q, ep, rgb(255, 205, 90), 0, 2)
					if rng:NextNumber() < 0.28 and n > 2 then
						branche(q, ang + rng:NextNumber(-1.2, 1.2), math.floor(n / 2), math.max(1, ep - 1))
					end
					p = q
				end
			end
			branche(Vector2.new(rng:NextNumber(0.2, 0.8), 1.02), -math.pi / 2 + rng:NextNumber(-0.7, 0.7), 6 + (k % 3), 3)
		end
		table.insert(boucles, TweenService:Create(fissures, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{GroupColor3 = rgb(150, 95, 80)}))
		-- fumée (fond) et braises (devant), recyclées
		local fumees, braises = {}, {}
		for k = 1, 7 do
			fumees[k] = rond(f, UDim2.fromScale(0.5, 1.3), rng:NextNumber(0.25, 0.45), rgb(32, 22, 20), 1, 1)
		end
		for k = 1, 30 do
			braises[k] = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 1.2), Size = UDim2.fromScale(0.01, 0.01), SizeConstraint = YY,
				Rotation = 45, BackgroundColor3 = rgb(255, 120, 30):Lerp(rgb(255, 235, 130), rng:NextNumber()), BorderSizePixel = 0, ZIndex = 4, Parent = a})
		end

		-- jauge : coulée de lave dans un lit de roche, boule incandescente au bout
		local fondJ = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(30, 18, 14), BorderSizePixel = 0, Parent = j},
			{coin(0.5), trait(rgb(90, 44, 22), 2, 0.1)})
		local rempli = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 2, Parent = fondJ}, {coin(0.5)})
		local flot = creer("UIGradient", {Offset = Vector2.new(-0.25, 0), Color = couleurs({{0, rgb(255, 110, 25)}, {0.25, rgb(255, 220, 100)},
			{0.5, rgb(255, 120, 30)}, {0.75, rgb(220, 60, 15)}, {1, rgb(255, 150, 40)}}), Parent = rempli})
		table.insert(boucles, TweenService:Create(flot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.25, 0)}))
		creer("Frame", {Size = UDim2.fromScale(1, 0.35), BackgroundColor3 = BLANC, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 3, Parent = rempli},
			{coin(0.5)})
		local tete = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1.6, 1.6), SizeConstraint = YY,
			BackgroundColor3 = rgb(255, 235, 140), BorderSizePixel = 0, ZIndex = 5, Parent = fondJ}, {coin(0.5), trait(rgb(255, 140, 40), 3, 0.3)})
		local _, eT = lueur(tete, UDim2.fromScale(0.5, 0.5), 3, rgb(255, 120, 30), 0.6, 4)
		table.insert(boucles, TweenService:Create(eT, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.35}))
		local bulles = {}
		for k = 1, 5 do
			bulles[k] = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0.5, 0.5), SizeConstraint = YY,
				Rotation = 45, BackgroundColor3 = rgb(255, 200, 80), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Parent = fondJ})
		end
		local niveau = 0

		return {fond = f, avant = a, jauge = j, tete = tete, boucles = boucles,
			remplir = function(v)
				niveau = v
				rempli.Size = UDim2.fromScale(v, 1)
				tete.Position = UDim2.fromScale(v, 0.5)
			end,
			demarrer = function(gen)
				for k, p in fumees do
					cycle(gen, (k - 1) * 0.6, function()
						local x = math.random() * 1.1 - 0.05
						p.Position = UDim2.fromScale(x, 1.05)
						p.BackgroundTransparency = 0.6
						return TweenService:Create(p, TweenInfo.new(6 + math.random() * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.2, 0.15), BackgroundTransparency = 1})
					end)
				end
				for k, b in braises do
					cycle(gen, (k - 1) * 0.08, function()
						local x = math.random() * 1.02
						local t = 0.006 + math.random() * 0.01
						b.Position = UDim2.fromScale(x, 1.03)
						b.Size = UDim2.fromScale(t, t)
						b.BackgroundTransparency = 0
						b.Rotation = 45
						return TweenService:Create(b, TweenInfo.new(1.6 + math.random() * 1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.16, 0.15 + math.random() * 0.5),
							BackgroundTransparency = 1, Rotation = 45 + (math.random() - 0.5) * 400, Size = UDim2.fromScale(t * 0.3, t * 0.3)})
					end)
				end
				for k, b in bulles do
					cycle(gen, k * 0.15, function()
						b.Position = UDim2.fromScale(niveau, 0.5)
						b.BackgroundTransparency = 0
						return TweenService:Create(b, TweenInfo.new(0.5 + math.random() * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Position = UDim2.new(niveau, (math.random() - 0.5) * 30, -1.5 - math.random() * 2, 0), BackgroundTransparency = 1})
					end)
				end
			end}
	end

	local CONSTRUCTEURS = {TitanCristal = decorTitan, ReineAraignee = decorReine, SeigneurBraise = decorSeigneur}

	local function decorDe(id: string): Decor
		local d = decors[id]
		if not d then
			d = CONSTRUCTEURS[id](THEMES[id])
			decors[id] = d
		end
		return d
	end

	-- ================= Portrait 3D (un modèle par boss, construit une fois) =================
	type Portrait = {modele: Model, anim: any, centre: Vector3, hauteur: number, distance: number}
	local portraits: {[string]: Portrait | false} = {}

	local function portraitDe(def): Portrait?
		local id = def.id
		local p = portraits[id]
		if p == nil then
			p = false
			local ok, res = pcall(function()
				local nomModele = if MobsVoxels.existe(id) then id elseif def.secours and MobsVoxels.existe(def.secours) then def.secours else nil
				if not nomModele then return nil end
				local m = MobsVoxels.construire(nomModele, CFrame.new())
				for _, piece in m:GetDescendants() do
					if piece:IsA("BasePart") then piece.CastShadow = false end
				end
				m.Parent = monde
				local cf, taille = m:GetBoundingBox()
				local anim = nil
				pcall(function()
					anim = MobsVoxels.animateur(m, nomModele)
					anim:Jouer("Idle", true, 0)
				end)
				m.Parent = nil
				local cadre = math.max(taille.Y, taille.X * 0.85)
				return {modele = m, anim = anim, centre = cf.Position, hauteur = taille.Y,
					distance = cadre * 0.5 / math.tan(math.rad(camVue.FieldOfView / 2)) * 1.12}
			end)
			if ok and res then p = res end
			portraits[id] = p
		end
		return if p then p else nil
	end

	-- ================= État de l'affichage =================
	local themeCourant = THEMES.TitanCristal
	local decorCourant: Decor? = nil
	local portraitCourant: Portrait? = nil
	local zoom = Instance.new("NumberValue")
	local trauma = 0
	local parallaxe = Vector2.zero
	local t0 = os.clock()
	local rendu: RBXScriptConnection? = nil
	local finJauge = false
	local dernierNombre = 1

	-- nombre de mineurs partis : la file du cercle est vidée juste avant le départ, on garde sa dernière valeur
	local function compterFile()
		local f = dossier:GetAttribute("File")
		if type(f) == "string" and f ~= "" then
			dernierNombre = #string.split(f, ",")
		end
	end
	dossier:GetAttributeChangedSignal("File"):Connect(compterFile)
	compterFile()

	local progression = Instance.new("NumberValue")
	progression.Changed:Connect(function(v)
		pourcent.Text = math.floor(v * 100 + 0.5) .. " %"
		if decorCourant then decorCourant.remplir(v) end
		if v >= 0.999 and not finJauge and racine.Visible then
			finJauge = true
			eclatJauge.BackgroundTransparency = 0.15
			TweenService:Create(eclatJauge, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
			if decorCourant then UI.pop(decorCourant.tete, 1.8) end
			UI.pop(pourcent, 1.3)
		end
	end)

	local tweenProgres: Tween? = nil
	local function progresser(v: number, duree: number, style: Enum.EasingStyle?)
		if tweenProgres then tweenProgres:Cancel() end
		local t = TweenService:Create(progression, TweenInfo.new(duree, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = v})
		tweenProgres = t
		t:Play()
	end

	local function pas(dt: number)
		local t = os.clock() - t0
		-- parallaxe : la souris sur ordinateur, une lente dérive sur mobile / manette
		local cible: Vector2
		local taille = racine.AbsoluteSize
		if UserInputService.MouseEnabled and not UserInputService.TouchEnabled and taille.X > 0 then
			local m = UserInputService:GetMouseLocation()
			cible = Vector2.new(math.clamp(m.X / taille.X * 2 - 1, -1, 1), math.clamp(m.Y / taille.Y * 2 - 1, -1, 1))
		else
			cible = Vector2.new(math.sin(t * 0.4) * 0.6, math.cos(t * 0.31) * 0.4)
		end
		parallaxe = parallaxe:Lerp(cible, math.min(1, dt * 3))
		-- secousse (retombe vite)
		trauma = math.max(0, trauma - dt * 1.8)
		local s = trauma * trauma * 18
		local ox, oy = math.noise(t * 25, 1.7) * s, math.noise(t * 25, 9.2) * s
		local px, py = parallaxe.X, parallaxe.Y
		fondCouche.Position = UDim2.new(0.5, -px * 12 + ox * 0.4, 0.5, -py * 8 + oy * 0.4)
		scene.Position = UDim2.new(0.7, px * 6 + ox * 0.7, 0.5, py * 4 + oy * 0.7)
		avantCouche.Position = UDim2.new(0.5, px * 20 + ox, 0.5, py * 13 + oy)
		contenu.Position = UDim2.fromOffset(ox, oy)
		-- portrait : orbite lente de trois quarts, contre-jour qui suit la caméra
		local p = portraitCourant
		if p then
			if p.anim then p.anim:Pas(dt) end
			local a = 0.55 * math.sin(t * 0.2 - 1.2)
			local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
			local z = zoom.Value
			local oeil = p.centre + dir * p.distance * z + Vector3.new(0, p.hauteur * (-0.04 + 0.1 * (z - 1)), 0)
			camVue.CFrame = CFrame.lookAt(oeil, p.centre + Vector3.new(0, p.hauteur * 0.04, 0))
			local cote = dir:Cross(Vector3.yAxis)
			portrait.LightDirection = (dir * 0.75 + cote * 0.55 + Vector3.new(0, -0.45, 0)).Unit
		end
	end

	-- ================= Montrer / cacher =================
	local function trouverDef(d)
		local i = tonumber(d.index)
		if i and Config.BOSS[i] then return Config.BOSS[i] end
		for _, def in Config.BOSS do
			if def.nom == d.nom then return def end
		end
		return Config.BOSS[1]
	end

	local function apres(gen: number, delai: number, f: () -> ())
		task.delay(delai, function()
			if gen == generation then f() end
		end)
	end

	local function montrer(d)
		generation += 1
		local gen = generation
		local def = trouverDef(d)
		local id = if THEMES[def.id] then def.id else "TitanCristal"
		local th = THEMES[id]
		themeCourant = th
		local couleur = if typeof(d.couleur) == "Color3" then d.couleur else def.couleur or th.accent

		-- décor du boss (les autres masqués)
		local decor = decorDe(id)
		for autre, dc in decors do
			local visible = autre == id
			dc.fond.Visible, dc.avant.Visible, dc.jauge.Visible = visible, visible, visible
		end
		decorCourant = decor
		fondDegrade.Color = couleurs({{0, th.fond[1]}, {0.55, th.fond[2]}, {1, th.fond[3]}})
		for _, v in vignettes do v.BackgroundColor3 = th.vignette end
		rayons.GroupColor3 = couleur
		for _, h in halos do h.BackgroundColor3 = couleur end
		local traitHalo = anneauHalo:FindFirstChildOfClass("UIStroke") :: UIStroke
		filetHaut.BackgroundColor3 = th.accent
		surTrait.BackgroundColor3 = th.accent
		separateur.BackgroundColor3 = th.accent
		conseilBarre.BackgroundColor3 = th.accent
		conseilTag.TextColor3 = th.accent
		pourcent.TextColor3 = th.accent

		-- portrait 3D
		if portraitCourant and portraitCourant.modele then portraitCourant.modele.Parent = nil end
		portraitCourant = portraitDe(def)
		if portraitCourant then
			portraitCourant.modele.Parent = monde
			if portraitCourant.anim then pcall(function() portraitCourant.anim:Jouer("Idle", true, 0) end) end
		end
		portrait.Ambient = th.ambiance
		portrait.LightColor = th.lumiere
		portrait.ImageColor3 = NOIR
		zoom.Value = 1.75
		TweenService:Create(zoom, TweenInfo.new(1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = 1}):Play()
		TweenService:Create(portrait, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0.35), {ImageColor3 = BLANC}):Play()
		rayons.GroupTransparency = 1
		TweenService:Create(rayons, TweenInfo.new(1, Enum.EasingStyle.Quad), {GroupTransparency = 0.35}):Play()

		-- textes
		local total = #Config.BOSS
		badge.Text = string.format('%s<font color="#%s">BOSS %d / %d</font>   ·   DURÉE MAX %s',
			if d.court then '<font color="#' .. T.Rouge:ToHex() .. '">RENFORTS</font>   ·   ' else "",
			th.accent:ToHex(), table.find(Config.BOSS, def) or 1, total, Config.minutes(Config.DUREE_MAX))
		surtitre.Text = if d.court then "RENFORTS · ARÈNE DES BOSS" else "ARÈNE DES BOSS"
		local nomTexte = string.upper(tostring(d.nom or def.nom or "Boss"))
		for _, l in {nom, nomLueur, nomEcho} do
			l.Text = nomTexte
			l.Font = th.police
			l.TextTransparency = 1
		end
		nom.TextColor3 = BLANC
		nomDegrade.Color = couleurs({{0, th.nom[1]}, {0.5, th.nom[2]}, {1, th.nom[3]}})
		nomLueur.TextColor3 = couleur
		lueurTrait.Color = couleur
		nomEcho.TextColor3 = th.accent
		titre.Text = tostring(d.titre or def.titre or "")
		titre.TextColor3 = couleur:Lerp(BLANC, 0.3)
		titre.MaxVisibleGraphemes = 0
		devise.Text = th.devise
		devise.TextTransparency = 1
		separateur.Size = UDim2.new(0, 0, 0, 2)
		stats.GroupTransparency = 1
		local nb = if d.court then math.max(1, tonumber(dossier:GetAttribute("Debout")) or 1) else dernierNombre
		mineurs.Text = string.format('%d <font color="#%s">/ %d</font>', nb, T.Gris:ToHex(), Config.MAX_JOUEURS)
		for i, c in cranes do
			local allume = i <= th.menace
			for _, o in c.os do
				o.BackgroundColor3 = if allume then rgb(238, 228, 208) else rgb(56, 50, 48)
				o.BackgroundTransparency = if allume then 0 else 0.35
			end
			for _, o in c.trous do
				o.BackgroundColor3 = if allume then th.accent2 else rgb(20, 16, 16)
			end
			c.echelle.Scale = 0
		end
		titreAttaques.TextTransparency = 1
		local liste = {}
		for _, nomA in def.attaques or {} do table.insert(liste, {nomA, false}) end
		for _, nomA in def.attaquesEnrage or {} do table.insert(liste, {nomA, true}) end
		for i, pc in puces do
			local e = liste[i]
			pc.cadre.Visible = e ~= nil
			pc.echelle.Scale = 0
			if e then
				local lisible = echapper(ATTAQUES[e[1]] or e[1])
				pc.texte.Text = if e[2] then lisible .. ' <font color="#' .. T.Rouge:ToHex() .. '">· enragé</font>' else lisible
				pc.bord.Color = if e[2] then T.Rouge else th.accent
				pc.losange.BackgroundColor3 = if e[2] then T.Rouge else th.accent
			end
		end
		conseilTexte.Text = tostring(def.conseil or "")
		conseil.GroupTransparency = 1
		etat.Text = "Chargement de l'arène…"
		finJauge = false
		progression.Value = 0
		decor.remplir(0)
		pourcent.Text = "0 %"

		-- démarrage
		racine.Visible = true
		ouverture.BackgroundTransparency = 0
		TweenService:Create(ouverture, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		trauma, t0 = 0, os.clock()
		for _, b in bouclesCommunes do b:Play() end
		for _, b in decor.boucles do b:Play() end
		decor.demarrer(gen)
		if rendu then rendu:Disconnect() end
		rendu = RunService.RenderStepped:Connect(pas)
		Outils.jouer("grondement", 0.8, 0.3)

		-- grain : points replacés au hasard 20 fois par seconde
		task.spawn(function()
			while gen == generation do
				for _, pt in points do
					pt.Position = UDim2.fromScale(math.random(), math.random())
					pt.BackgroundTransparency = 0.55 + math.random() * 0.4
				end
				task.wait(0.05)
			end
		end)

		-- astuces : une au hasard, puis la suivante toutes les 3 s en fondu
		local astuces = Config.ASTUCES
		local ia = math.random(#astuces)
		local function ecrireAstuce()
			astuce.Text = '<font color="#' .. th.accent:ToHex() .. '"><b>ASTUCE</b></font>   ' .. echapper(astuces[ia])
		end
		ecrireAstuce()
		astuce.TextTransparency = 0
		task.spawn(function()
			while true do
				task.wait(3)
				if gen ~= generation then return end
				TweenService:Create(astuce, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
				task.wait(0.27)
				if gen ~= generation then return end
				ia = ia % #astuces + 1
				ecrireAstuce()
				TweenService:Create(astuce, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			end
		end)

		-- surtitre
		surtitre.TextTransparency = 1
		surtitre.Position = UDim2.fromScale(0.05, 0)
		TweenService:Create(surtitre, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.fromScale(0, 0)}):Play()
		surTrait.Size = UDim2.fromScale(0, 0.004)
		TweenService:Create(surTrait, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.12, 0.004)}):Play()

		-- nom : il s'écrase (grand → taille normale), puis impact : secousse, flash, écho, éclats, rugissement
		echelleNom.Scale = 2.3
		apres(gen, 0.15, function()
			TweenService:Create(echelleNom, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1}):Play()
			TweenService:Create(nom, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
		end)
		apres(gen, 0.37, function()
			trauma = 1
			Outils.jouer("impact", 0.6, 0.6)
			Outils.jouer("grondement", 0.5, 0.5)
			flash.BackgroundTransparency = 0.55
			TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
			nomLueur.TextTransparency = 0.5
			local pulse = TweenService:Create(nomLueur, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.8})
			actifs[pulse] = true
			pulse:Play()
			echelleEcho.Scale = 1
			nomEcho.TextTransparency = 0.2
			TweenService:Create(echelleEcho, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.35}):Play()
			TweenService:Create(nomEcho, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
			UI.gerbe(info, th.accent, 16, Vector2.new(0.3, 0.18))
			UI.pop(scene, 1.06)
			local p = portraitCourant
			if p and p.anim and p.anim.Clips and p.anim.Clips.Roar then
				local duree = p.anim:Jouer("Roar", false, 0.15)
				apres(gen, math.max(0.3, duree * 0.92), function()
					if portraitCourant == p then p.anim:Jouer("Idle", true, 0.35) end
				end)
			end
		end)
		-- titre tapé lettre par lettre, devise
		apres(gen, 0.5, function()
			Outils.jouer("lame", 1.15, 0.35)
			task.spawn(function()
				local n = utf8.len(titre.Text) or #titre.Text
				for k = 1, n do
					if gen ~= generation then return end
					titre.MaxVisibleGraphemes = k
					task.wait(0.028)
				end
				titre.MaxVisibleGraphemes = -1
			end)
			TweenService:Create(separateur, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0, 2)}):Play()
		end)
		apres(gen, 0.75, function()
			TweenService:Create(devise, TweenInfo.new(0.5), {TextTransparency = 0.1}):Play()
			TweenService:Create(stats, TweenInfo.new(0.35), {GroupTransparency = 0}):Play()
			for i, c in cranes do
				apres(gen, (i - 1) * 0.07, function()
					TweenService:Create(c.echelle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
					if i <= th.menace then Outils.jouer("metal", 0.8 + i * 0.07, 0.18) end
				end)
			end
		end)
		apres(gen, 0.95, function()
			TweenService:Create(titreAttaques, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			for i, pc in puces do
				if pc.cadre.Visible then
					apres(gen, (i - 1) * 0.08, function()
						TweenService:Create(pc.echelle, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
					end)
				end
			end
		end)
		apres(gen, 1.2, function()
			TweenService:Create(conseil, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {GroupTransparency = 0}):Play()
		end)
	end

	local function cacher()
		generation += 1
		racine.Visible = false
		if rendu then
			rendu:Disconnect()
			rendu = nil
		end
		local liste = {}
		for t in actifs do table.insert(liste, t) end
		for _, t in liste do t:Cancel() end
		table.clear(actifs)
		for _, b in bouclesCommunes do b:Pause() end
		for _, dc in decors do
			for _, b in dc.boucles do b:Pause() end
		end
		if portraitCourant and portraitCourant.modele then portraitCourant.modele.Parent = nil end
		portraitCourant = nil
	end

	return {racine = racine, etat = etat, progresser = progresser, montrer = montrer, cacher = cacher}
end

return Chargement
