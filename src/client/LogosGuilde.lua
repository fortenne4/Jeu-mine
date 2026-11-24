--!strict
-- Logos de la Guilde des Mineurs · MODULE CLIENT (StarterPlayerScripts › Jeu › LogosGuilde)
-- Petites icônes dessinées en GUI pur (Frames, UICorner, UIGradient, UIStroke, rotations) : aucune image, aucun emoji,
-- aucun glyphe spécial de police (les ⛏ ⚒ ★ ✔ ◉ ▾ s'affichaient en carrés vides chez certains joueurs).
-- Le logo remplit son parent (carré centré) ; les liserés suivent la taille.
--   LogosGuilde.creer(nom, parent, couleur?) -> Frame
--     nom : pioche, enclume, wagon, poisson, sortie, caisse, pepite, casque, coche, piece, etoile, cadenas,
--           chevron, parchemin, livre, exclamation, coffre, sablier
--   LogosGuilde.sceau(parent, couleur, interieur?) -> Frame  -- sceau de cire (interieur = nom de logo ou lettre)
--   LogosGuilde.objectif(type, cible?) -> (nom, couleur?)    -- logo dessiné d'un type d'objectif de quête
-- Utilisé par Quetes.client.lua.

local LogosGuilde = {}

local BLANC = Color3.new(1, 1, 1)
local BRUN = Color3.fromRGB(40, 22, 10)
local BOIS = Color3.fromRGB(150, 96, 52)
local FER = Color3.fromRGB(150, 154, 166)
local FER_SOMBRE = Color3.fromRGB(34, 34, 40)
local OR = Color3.fromRGB(255, 204, 92)
local OR_FONCE = Color3.fromRGB(168, 112, 40)
local VERT = Color3.fromRGB(92, 204, 100)
local PARCHEMIN = Color3.fromRGB(240, 226, 200)

local function creer(classe: string, props: {[string]: any}, enfants: {Instance}?): any
	local i: any = Instance.new(classe)
	for k, v in props do
		if k ~= "Parent" then
			i[k] = v
		end
	end
	for _, e in enfants or {} do
		e.Parent = i
	end
	if props.Parent then
		i.Parent = props.Parent
	end
	return i
end

local function coin(r: number): UICorner
	return creer("UICorner", {CornerRadius = UDim.new(r, 0)})
end

-- Relief « métal bombé » : multiplie la couleur de la pièce
local function bombe(rotation: number?): UIGradient
	return creer("UIGradient", {Rotation = rotation or 60, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, BLANC),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 130, 130))})})
end

type Dessin = {
	boite: Frame,
	z: number,
	traits: {{any}},
}

-- Pièce rectangulaire (coordonnées 0..1 dans la boîte carrée)
local function forme(d: Dessin, x: number, y: number, l: number, h: number, couleur: Color3, arrondi: number?, rotation: number?): Frame
	d.z += 1
	return creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(l, h),
		Rotation = rotation or 0, BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = d.z, Parent = d.boite},
		if arrondi then {coin(arrondi)} else nil)
end

-- Segment de (x1, y1) à (x2, y2), d'épaisseur e
local function segment(d: Dessin, x1: number, y1: number, x2: number, y2: number, e: number, couleur: Color3): Frame
	local dx, dy = x2 - x1, y2 - y1
	local l = math.sqrt(dx * dx + dy * dy) + e * 0.6
	return forme(d, (x1 + x2) / 2, (y1 + y2) / 2, l, e, couleur, 0.5, math.deg(math.atan2(dy, dx)))
end

-- Liseré dont l'épaisseur suit la taille du logo (ratio × côté)
local function liser(d: Dessin, o: GuiObject, couleur: Color3, ratio: number, transp: number?)
	local s = creer("UIStroke", {Color = couleur, Thickness = 1, Transparency = transp or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round, Parent = o})
	table.insert(d.traits, {s, ratio})
end

local function refl(d: Dessin, x: number, y: number, l: number, h: number, rotation: number?)
	forme(d, x, y, l, h, BLANC, 0.5, rotation).BackgroundTransparency = 0.45
end

local function eclat(d: Dessin, x: number, y: number, t: number)
	for _, rot in {0, 90} do
		local b = forme(d, x, y, t, t * 0.2, BLANC, 0.5, rot)
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1)}), Parent = b})
	end
end

local DESSINS: {[string]: (Dessin, Color3?) -> ()} = {}

DESSINS.pioche = function(d, c)
	local tete = c or FER
	-- manche en bois (bas-gauche → haut-droite)
	local manche = segment(d, 0.16, 0.88, 0.64, 0.38, 0.12, BOIS)
	bombe(0).Parent = manche
	liser(d, manche, BRUN, 0.025)
	-- tête arquée perpendiculaire au manche
	for _, s in {{0.39, 0.12, 0.69, 0.32}, {0.69, 0.32, 0.9, 0.6}} do
		local p = segment(d, s[1], s[2], s[3], s[4], 0.13, tete)
		bombe(90).Parent = p
		liser(d, p, BRUN, 0.025)
	end
	local virole = forme(d, 0.66, 0.35, 0.15, 0.15, tete:Lerp(BRUN, 0.35), 0.3, 45)
	liser(d, virole, BRUN, 0.02)
	refl(d, 0.52, 0.2, 0.14, 0.04, 36)
end

DESSINS.enclume = function(d, c)
	local fer = c or FER
	local function bloc(x, y, l, h, arrondi)
		local p = forme(d, x, y, l, h, fer, arrondi, 0)
		bombe(90).Parent = p
		liser(d, p, BRUN, 0.025)
		return p
	end
	bloc(0.56, 0.76, 0.6, 0.12, 0.3) -- socle
	bloc(0.56, 0.6, 0.28, 0.22, 0.15) -- taille
	local corne = segment(d, 0.08, 0.38, 0.32, 0.4, 0.1, fer)
	bombe(90).Parent = corne
	liser(d, corne, BRUN, 0.025)
	bloc(0.58, 0.4, 0.62, 0.16, 0.25) -- table
	refl(d, 0.56, 0.36, 0.42, 0.035)
	-- marteau posé de biais + étincelle
	local manche = segment(d, 0.72, 0.28, 0.94, 0.06, 0.06, BOIS)
	liser(d, manche, BRUN, 0.02)
	local tete = forme(d, 0.66, 0.2, 0.2, 0.11, FER_SOMBRE:Lerp(fer, 0.5), 0.2, -45)
	liser(d, tete, BRUN, 0.02)
	eclat(d, 0.28, 0.16, 0.26)
end

DESSINS.wagon = function(d, c)
	local or_ = c or OR
	local c1 = forme(d, 0.36, 0.28, 0.24, 0.22, or_, 0.45)
	bombe().Parent = c1
	local c2 = forme(d, 0.6, 0.25, 0.28, 0.26, or_:Lerp(BLANC, 0.3), 0.45)
	bombe().Parent = c2
	local caisse = forme(d, 0.5, 0.52, 0.82, 0.4, FER, 0.12)
	bombe(90).Parent = caisse
	liser(d, caisse, FER_SOMBRE, 0.025)
	local rebord = forme(d, 0.5, 0.34, 0.96, 0.1, Color3.fromRGB(120, 122, 130), 0.3)
	liser(d, rebord, FER_SOMBRE, 0.02)
	for _, x in {0.28, 0.72} do
		local r = forme(d, x, 0.8, 0.26, 0.26, Color3.fromRGB(28, 28, 32), 0.5)
		liser(d, r, Color3.fromRGB(170, 170, 178), 0.025)
		forme(d, x, 0.8, 0.09, 0.09, Color3.fromRGB(170, 170, 178), 0.5)
	end
end

DESSINS.poisson = function(d, c)
	local peau = c or Color3.fromRGB(110, 190, 255)
	for _, s in {{0.72, 0.5, 0.94, 0.28}, {0.72, 0.5, 0.94, 0.72}} do
		local q = segment(d, s[1], s[2], s[3], s[4], 0.16, peau:Lerp(BRUN, 0.2))
		liser(d, q, BRUN, 0.02)
	end
	local corps = forme(d, 0.44, 0.5, 0.66, 0.4, peau, 0.5)
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(peau:Lerp(BLANC, 0.45), peau:Lerp(BRUN, 0.35))}).Parent = corps
	liser(d, corps, BRUN, 0.025)
	local nageoire = forme(d, 0.46, 0.32, 0.16, 0.16, peau:Lerp(BRUN, 0.25), 0.2, 45)
	nageoire.ZIndex = corps.ZIndex - 1
	forme(d, 0.26, 0.44, 0.1, 0.1, BLANC, 0.5)
	forme(d, 0.25, 0.44, 0.05, 0.05, BRUN, 0.5)
	refl(d, 0.46, 0.4, 0.3, 0.05)
end

DESSINS.sortie = function(d, c)
	local pierre = Color3.fromRGB(128, 116, 104)
	local arche = forme(d, 0.5, 0.5, 0.8, 0.84, pierre, 0.48)
	bombe(90).Parent = arche
	liser(d, arche, BRUN, 0.025)
	forme(d, 0.5, 0.78, 0.8, 0.28, pierre:Lerp(BRUN, 0.15), 0.1)
	local trou = forme(d, 0.5, 0.56, 0.52, 0.66, Color3.fromRGB(18, 12, 10), 0.48)
	forme(d, 0.5, 0.8, 0.52, 0.22, Color3.fromRGB(18, 12, 10), 0)
	local _ = trou
	local fleche = c or OR
	for _, s in {{0.5, 0.82, 0.5, 0.42}, {0.5, 0.36, 0.33, 0.53}, {0.5, 0.36, 0.67, 0.53}} do
		local p = segment(d, s[1], s[2], s[3], s[4], 0.11, fleche)
		liser(d, p, BRUN, 0.018)
	end
end

DESSINS.caisse = function(d, c)
	local bois = c or BOIS
	local boite = forme(d, 0.5, 0.54, 0.84, 0.74, bois, 0.1)
	bombe(90).Parent = boite
	liser(d, boite, BRUN, 0.03)
	for _, y in {0.3, 0.78} do
		local p = forme(d, 0.5, y, 0.84, 0.1, bois:Lerp(BRUN, 0.25), 0.2)
		liser(d, p, BRUN, 0.015)
	end
	segment(d, 0.18, 0.36, 0.82, 0.72, 0.08, bois:Lerp(BRUN, 0.3))
	segment(d, 0.18, 0.72, 0.82, 0.36, 0.08, bois:Lerp(BRUN, 0.3))
	for _, x in {0.14, 0.86} do
		for _, y in {0.3, 0.78} do
			forme(d, x, y, 0.07, 0.07, FER, 0.5)
		end
	end
end

-- Minerai brut : roche grise et cristaux de la couleur donnée
DESSINS.pepite = function(d, c)
	local gemme = c or OR
	local roche = forme(d, 0.46, 0.62, 0.76, 0.5, Color3.fromRGB(96, 90, 86), 0.35, -8)
	bombe(80).Parent = roche
	liser(d, roche, BRUN, 0.025)
	for _, g in {{0.36, 0.48, 0.3, -20}, {0.6, 0.38, 0.38, 15}, {0.74, 0.58, 0.22, 40}} do
		local p = forme(d, g[1], g[2], g[3], g[3], gemme, 0.18, g[4])
		creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(gemme:Lerp(BLANC, 0.55), gemme:Lerp(BRUN, 0.3))}).Parent = p
		liser(d, p, gemme:Lerp(BRUN, 0.6), 0.02)
	end
	eclat(d, 0.84, 0.18, 0.24)
end

DESSINS.casque = function(d, c)
	local fer = c or FER
	local clip = forme(d, 0.5, 0.36, 0.8, 0.44, BLANC, nil)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	d.z += 1
	local dome = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 1.8),
		BackgroundColor3 = fer, BorderSizePixel = 0, ZIndex = d.z, Parent = clip}, {coin(0.5), bombe(70)})
	local _ = dome
	local bord = forme(d, 0.5, 0.6, 0.94, 0.14, fer:Lerp(BRUN, 0.2), 0.4)
	bombe(90).Parent = bord
	liser(d, bord, BRUN, 0.025)
	forme(d, 0.5, 0.34, 0.08, 0.44, fer:Lerp(BLANC, 0.3), 0.5)
	for _, x in {0.22, 0.5, 0.78} do
		forme(d, x, 0.6, 0.06, 0.06, Color3.fromRGB(200, 200, 206), 0.5)
	end
	local lampe = forme(d, 0.5, 0.42, 0.16, 0.12, OR, 0.4)
	liser(d, lampe, BRUN, 0.018)
	refl(d, 0.36, 0.24, 0.12, 0.05, -30)
end

DESSINS.coche = function(d, c)
	local v = c or VERT
	for _, s in {{0.2, 0.52, 0.42, 0.74}, {0.42, 0.74, 0.82, 0.26}} do
		local p = segment(d, s[1], s[2], s[3], s[4], 0.17, v)
		liser(d, p, BRUN, 0.03)
	end
end

DESSINS.piece = function(d, c)
	local o = c or OR
	local p = forme(d, 0.5, 0.5, 0.9, 0.9, o, 0.5)
	bombe().Parent = p
	liser(d, p, OR_FONCE, 0.035)
	local anneau = forme(d, 0.5, 0.5, 0.62, 0.62, o, 0.5)
	anneau.BackgroundTransparency = 1
	liser(d, anneau, Color3.fromRGB(196, 128, 40), 0.03, 0.15)
	forme(d, 0.5, 0.5, 0.13, 0.36, OR_FONCE, 0.5)
	refl(d, 0.33, 0.28, 0.22, 0.1, -35)
end

-- Étoile de renommée (8 branches)
DESSINS.etoile = function(d, c)
	local o = c or Color3.fromRGB(196, 120, 255)
	for _, r in {0, 45} do
		local p = forme(d, 0.5, 0.5, 0.66, 0.66, o, 0.1, r)
		bombe().Parent = p
		liser(d, p, o:Lerp(BRUN, 0.6), 0.025)
	end
	forme(d, 0.5, 0.5, 0.34, 0.34, o:Lerp(BLANC, 0.6), 0.5)
	eclat(d, 0.5, 0.5, 0.5)
end

DESSINS.cadenas = function(d, c)
	local anse = Color3.fromRGB(140, 136, 132)
	for _, s in {{0.31, 0.56, 0.31, 0.32}, {0.69, 0.56, 0.69, 0.32}, {0.31, 0.32, 0.4, 0.16}, {0.4, 0.16, 0.6, 0.16}, {0.6, 0.16, 0.69, 0.32}} do
		segment(d, s[1], s[2], s[3], s[4], 0.1, anse)
	end
	local corps = forme(d, 0.5, 0.66, 0.66, 0.48, c or Color3.fromRGB(176, 140, 70), 0.18)
	bombe(90).Parent = corps
	liser(d, corps, BRUN, 0.03)
	forme(d, 0.5, 0.6, 0.13, 0.13, BRUN, 0.5)
	forme(d, 0.5, 0.71, 0.07, 0.16, BRUN, 0.3)
end

DESSINS.chevron = function(d, c)
	local o = c or OR
	for _, s in {{0.24, 0.36, 0.5, 0.64}, {0.5, 0.64, 0.76, 0.36}} do
		local p = segment(d, s[1], s[2], s[3], s[4], 0.15, o)
		liser(d, p, BRUN, 0.025)
	end
end

DESSINS.parchemin = function(d, c)
	local brun = Color3.fromRGB(120, 78, 40)
	local feuille = forme(d, 0.5, 0.52, 0.66, 0.66, PARCHEMIN, 0.08)
	bombe(90).Parent = feuille
	liser(d, feuille, brun, 0.025)
	for _, y in {0.18, 0.86} do
		local r = forme(d, 0.5, y, 0.84, 0.15, Color3.fromRGB(214, 184, 132), 0.5)
		liser(d, r, brun, 0.025)
	end
	for k, y in {0.38, 0.5, 0.62} do
		forme(d, 0.45, y, if k == 3 then 0.26 else 0.4, 0.05, brun, 0.5)
	end
	local cire = forme(d, 0.7, 0.68, 0.22, 0.22, c or Color3.fromRGB(190, 40, 36), 0.5)
	bombe().Parent = cire
	liser(d, cire, Color3.fromRGB(90, 16, 14), 0.02)
end

DESSINS.livre = function(d, c)
	local cuir = c or Color3.fromRGB(150, 40, 36)
	local couv = forme(d, 0.5, 0.54, 0.9, 0.7, cuir, 0.1)
	bombe(90).Parent = couv
	liser(d, couv, BRUN, 0.03)
	for _, x in {0.29, 0.71} do
		local page = forme(d, x, 0.5, 0.38, 0.6, PARCHEMIN, 0.06, if x < 0.5 then -4 else 4)
		liser(d, page, Color3.fromRGB(120, 78, 40), 0.015)
		for k = 1, 3 do
			forme(d, x, 0.32 + k * 0.1, 0.24, 0.035, Color3.fromRGB(150, 110, 70), 0.5, if x < 0.5 then -4 else 4)
		end
	end
	forme(d, 0.5, 0.54, 0.05, 0.66, cuir:Lerp(BRUN, 0.4), 0.5)
	local signet = forme(d, 0.62, 0.86, 0.07, 0.2, OR, 0.2)
	liser(d, signet, BRUN, 0.015)
end

DESSINS.exclamation = function(d, c)
	local o = c or OR
	local barre = forme(d, 0.5, 0.38, 0.2, 0.54, o, 0.5)
	bombe(0).Parent = barre
	liser(d, barre, BRUN, 0.04)
	local point = forme(d, 0.5, 0.84, 0.2, 0.2, o, 0.5)
	liser(d, point, BRUN, 0.04)
end

DESSINS.coffre = function(d, c)
	local bois = c or Color3.fromRGB(128, 78, 40)
	local bas = forme(d, 0.5, 0.66, 0.88, 0.46, bois, 0.12)
	bombe(90).Parent = bas
	liser(d, bas, BRUN, 0.025)
	local couvercle = forme(d, 0.5, 0.34, 0.88, 0.32, bois:Lerp(BLANC, 0.1), 0.45)
	bombe(90).Parent = couvercle
	liser(d, couvercle, BRUN, 0.025)
	forme(d, 0.5, 0.47, 0.94, 0.08, FER, nil)
	forme(d, 0.24, 0.56, 0.08, 0.7, FER, nil)
	forme(d, 0.76, 0.56, 0.08, 0.7, FER, nil)
	local serrure = forme(d, 0.5, 0.55, 0.18, 0.22, OR, 0.25)
	liser(d, serrure, OR_FONCE, 0.015)
end

DESSINS.sablier = function(d, c)
	local sable = c or OR
	for _, y in {0.12, 0.88} do
		local p = forme(d, 0.5, y, 0.7, 0.1, BOIS, 0.3)
		liser(d, p, BRUN, 0.02)
	end
	local verre = Color3.fromRGB(210, 230, 240)
	for _, s in {{0.24, 0.18, 0.5, 0.5}, {0.76, 0.18, 0.5, 0.5}, {0.5, 0.5, 0.24, 0.82}, {0.5, 0.5, 0.76, 0.82}} do
		local p = segment(d, s[1], s[2], s[3], s[4], 0.07, verre)
		p.BackgroundTransparency = 0.2
	end
	forme(d, 0.5, 0.3, 0.22, 0.12, sable, 0.4, 0)
	forme(d, 0.5, 0.74, 0.34, 0.14, sable, 0.4, 0)
	forme(d, 0.5, 0.55, 0.03, 0.2, sable, 0.5)
end

-- Boîte carrée centrée + mise à l'échelle des liserés
local function nouvelleBoite(parent: Instance, nom: string): Dessin
	local z0 = (if parent:IsA("GuiObject") then parent.ZIndex else 1) + 1
	local boite = creer("Frame", {Name = "Logo_" .. nom, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z0, Parent = parent},
		{creer("UIAspectRatioConstraint", {AspectRatio = 1})})
	return {boite = boite, z = z0, traits = {}}
end

local function brancherTraits(d: Dessin)
	if #d.traits == 0 then
		return
	end
	local function maj()
		local cote = math.max(d.boite.AbsoluteSize.X, 1)
		for _, t in d.traits do
			(t[1] :: UIStroke).Thickness = math.max(1, cote * (t[2] :: number))
		end
	end
	maj()
	d.boite:GetPropertyChangedSignal("AbsoluteSize"):Connect(maj)
end

function LogosGuilde.creer(nom: string, parent: Instance, couleur: Color3?): Frame
	local d = nouvelleBoite(parent, nom)
	local f = DESSINS[nom] or DESSINS.exclamation
	f(d, couleur)
	brancherTraits(d)
	return d.boite
end

-- Sceau de cire : galette aux bords irréguliers, anneau en relief, symbole (logo dessiné ou lettre) au centre
function LogosGuilde.sceau(parent: Instance, couleur: Color3, interieur: string?): Frame
	local d = nouvelleBoite(parent, "Sceau")
	local cire = couleur
	local sombre = cire:Lerp(Color3.new(0, 0, 0), 0.45)
	-- coulures de cire tout autour
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2 + 0.3
		local r = 0.36 + (k % 3) * 0.025
		local t = 0.3 + (k % 2) * 0.06
		local p = forme(d, 0.5 + math.cos(a) * r * 0.62, 0.5 + math.sin(a) * r * 0.62, t, t, cire:Lerp(sombre, 0.25), 0.5)
		liser(d, p, sombre, 0.018)
	end
	local galette = forme(d, 0.5, 0.5, 0.84, 0.84, cire, 0.5)
	creer("UIGradient", {Rotation = 45, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, cire:Lerp(BLANC, 0.45)),
		ColorSequenceKeypoint.new(0.5, cire), ColorSequenceKeypoint.new(1, sombre)})}).Parent = galette
	liser(d, galette, sombre, 0.025)
	local anneau = forme(d, 0.5, 0.5, 0.62, 0.62, cire:Lerp(sombre, 0.3), 0.5)
	creer("UIGradient", {Rotation = -135, Color = ColorSequence.new(cire:Lerp(BLANC, 0.3), sombre)}).Parent = anneau
	liser(d, anneau, cire:Lerp(BLANC, 0.35), 0.016, 0.3)
	refl(d, 0.34, 0.26, 0.2, 0.07, -40)
	brancherTraits(d)
	if interieur then
		d.z += 1
		local zone = creer("Frame", {Name = "Symbole", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.46, 0.46), BackgroundTransparency = 1, ZIndex = d.z, Parent = d.boite})
		if DESSINS[interieur] then
			LogosGuilde.creer(interieur, zone, cire:Lerp(BLANC, 0.7))
		else
			local l = creer("TextLabel", {Text = interieur, Font = Enum.Font.Fantasy, TextScaled = true, BackgroundTransparency = 1,
				TextColor3 = cire:Lerp(BLANC, 0.75), Size = UDim2.fromScale(1.2, 1.2), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.52), ZIndex = d.z + 1, Parent = zone})
			creer("UIStroke", {Thickness = 1.5, Color = sombre, Parent = l})
		end
	end
	return d.boite
end

-- Logo dessiné d'un objectif de quête (liste, suivi à l'écran, bannières)
local COULEURS_MINERAI: {[string]: Color3} = {
	Charbon = Color3.fromRGB(150, 150, 160),
	Bronze = Color3.fromRGB(230, 130, 60),
	Fer = Color3.fromRGB(150, 185, 255),
	Gold = Color3.fromRGB(255, 200, 60),
}
function LogosGuilde.objectif(typeObjectif: string, cible: string?): (string, Color3?)
	if typeObjectif == "miner" or typeObjectif == "livrer" then
		local c = cible and COULEURS_MINERAI[cible]
		if c then
			return "pepite", c
		end
		return if typeObjectif == "livrer" then "caisse" else "pioche", nil
	elseif typeObjectif == "forger" then
		return "enclume", nil
	elseif typeObjectif == "pioche" then
		return "pioche", OR
	elseif typeObjectif == "wagon" then
		return "wagon", nil
	elseif typeObjectif == "equiper" then
		return "casque", nil
	elseif typeObjectif == "pecher" then
		return "poisson", nil
	elseif typeObjectif == "sortie" then
		return "sortie", nil
	end
	return "parchemin", nil
end

return LogosGuilde
