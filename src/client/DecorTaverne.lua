--!strict
-- Décor d'arrière-plan de la taverne de Margot / Guilde des Mineurs (StarterPlayerScripts › Jeu › DecorTaverne).
-- Lumière tamisée : fenêtre en arc au clair de lune violet (rayons qui descendent), bannières de la Guilde (pioches
-- croisées) qui ondulent, lanterne suspendue qui se balance, pyramide de tonneaux 3D à gauche, tableau de la Guilde
-- avec ses parchemins de quêtes à droite, chopes moussues 3D, bougies dont la flamme vacille,
-- poussière dorée dans la lumière et quelques paillettes violettes (la Veine d'Étoile).
-- Construit une seule fois (socle DecorCommun) ; tout s'arrête fenêtre fermée.
--   local decor = require(script.Parent.DecorTaverne).creer(interieur, boucles)
--   decor.demarrer() -- à l'ouverture ; decor.arreter() -- à la fermeture

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local D = require(script.Parent:WaitForChild("DecorCommun"))

local creer, coin, trait = UI.creer, UI.coin, UI.trait
local bloc, cylindre, halo, rayon, kp = D.bloc, D.cylindre, D.halo, D.rayon, D.kp
local BLANC = D.BLANC

local DecorTaverne = {}

local VIOLET = Color3.fromRGB(196, 120, 255)
local BOIS = Color3.fromRGB(122, 80, 46)
local BOIS_FONCE = Color3.fromRGB(70, 44, 26)
local FER = Color3.fromRGB(58, 58, 64)
local ENCRE = Color3.fromRGB(58, 36, 20)
local CHAUD = Color3.fromRGB(255, 176, 90)
local MOUSSE = Color3.fromRGB(246, 238, 218)

-- ================= 3D =================
-- Tonneau couché, fond tourné vers la caméra (+Z)
local function tonneau(m: Model, cf: CFrame, robinet: boolean)
	local axe = cf * CFrame.Angles(0, math.pi / 2, 0) -- l'axe X du cylindre part vers -Z : le fond avant est en X négatif
	cylindre(m, 3.0, 2.25, axe, BOIS, Enum.Material.Wood)
	cylindre(m, 1.7, 2.42, axe, BOIS:Lerp(BLANC, 0.05), Enum.Material.Wood)
	for _, x in {-1.32, 1.32} do
		cylindre(m, 0.16, 2.33, axe * CFrame.new(x, 0, 0), FER, Enum.Material.Metal)
	end
	for _, x in {-0.5, 0.5} do
		cylindre(m, 0.16, 2.5, axe * CFrame.new(x, 0, 0), FER, Enum.Material.Metal)
	end
	cylindre(m, 0.06, 1.95, axe * CFrame.new(-1.5, 0, 0), BOIS_FONCE, Enum.Material.Wood) -- fond
	for _, y in {-0.5, 0, 0.5} do -- douelles du fond
		bloc(m, Vector3.new(0.02, 0.04, 1.7 - math.abs(y) * 0.9), axe * CFrame.new(-1.54, y, 0), Color3.fromRGB(40, 24, 14), Enum.Material.Wood)
	end
	if robinet then
		bloc(m, Vector3.new(0.5, 0.18, 0.18), axe * CFrame.new(-1.75, -0.45, 0), Color3.fromRGB(200, 150, 60), Enum.Material.Metal)
		bloc(m, Vector3.new(0.16, 0.3, 0.16), axe * CFrame.new(-1.95, -0.58, 0), Color3.fromRGB(200, 150, 60), Enum.Material.Metal)
	end
end

local function pyramideTonneaux(): Model
	local m = Instance.new("Model")
	bloc(m, Vector3.new(5.6, 0.35, 3.4), CFrame.new(0, -1.3, 0), BOIS_FONCE, Enum.Material.Wood) -- râtelier
	for _, x in {-2.2, 2.2} do
		bloc(m, Vector3.new(0.35, 0.7, 3.4), CFrame.new(x, -0.95, 0), BOIS_FONCE, Enum.Material.Wood) -- cales
	end
	tonneau(m, CFrame.new(-1.22, 0, 0), false)
	tonneau(m, CFrame.new(1.22, 0, 0), false)
	tonneau(m, CFrame.new(0, 2.05, 0.05), true)
	return m
end

-- Chope en bois cerclée, mousse qui déborde, anse à droite
local function chope(m: Model, cf: CFrame)
	local debout = CFrame.Angles(0, 0, math.pi / 2)
	cylindre(m, 1.7, 1.2, cf * CFrame.new(0, 0.85, 0) * debout, Color3.fromRGB(150, 100, 58), Enum.Material.Wood)
	cylindre(m, 0.14, 1.3, cf * CFrame.new(0, 0.08, 0) * debout, BOIS_FONCE, Enum.Material.Wood)
	for _, y in {0.4, 1.35} do
		cylindre(m, 0.14, 1.27, cf * CFrame.new(0, y, 0) * debout, FER, Enum.Material.Metal)
	end
	cylindre(m, 0.32, 1.24, cf * CFrame.new(0, 1.78, 0) * debout, MOUSSE, Enum.Material.SmoothPlastic)
	for i, p in {Vector3.new(0.3, 1.98, 0.1), Vector3.new(-0.25, 2.0, -0.15), Vector3.new(0.05, 2.08, 0.25), Vector3.new(-0.5, 1.9, 0.3)} do
		local s = 0.42 + (i % 2) * 0.12
		bloc(m, Vector3.one * s, cf * CFrame.new(p), MOUSSE, Enum.Material.SmoothPlastic, nil, Enum.PartType.Ball)
	end
	bloc(m, Vector3.new(0.4, 0.4, 0.4), cf * CFrame.new(-0.62, 1.55, 0), MOUSSE, Enum.Material.SmoothPlastic, nil, Enum.PartType.Ball) -- coulure
	for _, y in {0.45, 1.3} do
		bloc(m, Vector3.new(0.5, 0.18, 0.22), cf * CFrame.new(0.82, y, 0), BOIS_FONCE, Enum.Material.Wood)
	end
	bloc(m, Vector3.new(0.18, 1.03, 0.22), cf * CFrame.new(1.0, 0.875, 0), BOIS_FONCE, Enum.Material.Wood)
end

local function plateauChopes(): Model
	local m = Instance.new("Model")
	bloc(m, Vector3.new(4.4, 0.25, 2.2), CFrame.new(0, -0.12, 0), BOIS_FONCE, Enum.Material.Wood)
	chope(m, CFrame.new(-1.05, 0, 0.2) * CFrame.Angles(0, 0.4, 0))
	chope(m, CFrame.new(1.0, 0, -0.25) * CFrame.Angles(0, -0.5, 0))
	return m
end

-- ================= 2D =================
local function cadre(parent: Instance, props: {[string]: any}, enfants: {Instance}?): Frame
	props.BorderSizePixel = 0
	props.Parent = parent
	return creer("Frame", props, enfants)
end

-- Pioche dessinée (manche + fer), qu'on fait pivoter pour croiser l'emblème
local function piocheDessinee(parent: Instance, angle: number)
	local p = cadre(parent, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9),
		Rotation = angle, BackgroundTransparency = 1})
	cadre(p, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.1, 0.9),
		BackgroundColor3 = Color3.fromRGB(150, 104, 62)}, {coin(0.5)})
	cadre(p, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.85, 0.13),
		BackgroundColor3 = Color3.fromRGB(205, 210, 222)}, {coin(0.5), UI.degrade(BLANC, Color3.fromRGB(130, 130, 145), 90)})
end
local function embleme(parent: Instance, pos: UDim2, taille: number)
	local e = cadre(parent, {Name = "Embleme", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(taille, taille),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1})
	piocheDessinee(e, -38)
	piocheDessinee(e, 38)
	cadre(e, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.24, 0.24),
		Rotation = 45, BackgroundColor3 = VIOLET}, {coin(0.15), trait(Color3.fromRGB(255, 214, 120), 1.5)})
	return e
end

-- Bannière violette de la Guilde : tissu dégradé, liseré doré, emblème, franges ; ondule depuis sa tringle
local function banniere(c: D.Contexte, x: number, duree: number)
	-- pivot au centre du conteneur = haut de la bannière (la moitié haute du conteneur reste vide)
	local pivot = cadre(c.milieu, {Name = "Banniere", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.215),
		Size = UDim2.fromScale(0.16, 0.6), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1})
	cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.15, 0.025),
		BackgroundColor3 = BOIS_FONCE}, {coin(0.5)})
	local tissu = cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.505), Size = UDim2.fromScale(0.92, 0.4),
		BackgroundColor3 = BLANC}, {coin(0.06), trait(Color3.fromRGB(214, 160, 60), 2, 0.2),
		UI.degrade(Color3.fromRGB(150, 80, 210), Color3.fromRGB(64, 28, 96), 90)})
	embleme(tissu, UDim2.fromScale(0.5, 0.42), 0.7)
	for i = 0, 3 do -- franges
		cadre(tissu, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.14 + i * 0.24, 0.97), Size = UDim2.fromScale(0.16, 0.08),
			BackgroundColor3 = Color3.fromRGB(214, 160, 60)}, {coin(0.5)})
	end
	pivot.Rotation = -2
	c.onde(pivot, duree, {Rotation = 2})
end

-- Fenêtre en arc au clair de lune (le haut arrondi = cadre très arrondi dont on « recouvre » le bas)
local function fenetre(c: D.Contexte, pos: UDim2)
	local f = cadre(c.loin, {Name = "Fenetre", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(0.24, 0.36),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1})
	-- deux morceaux : le haut (0 → 0.75, coins ronds) et le bas (0.4 → 1, carré) ; dégradé continu de a (haut) à b (bas)
	local function arche(taille: UDim2, a: Color3, b: Color3)
		local haut = cadre(f, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, (1 - taille.Y.Scale) / 2), Size = taille,
			BackgroundTransparency = 1})
		cadre(haut, {Size = UDim2.fromScale(1, 0.75), BackgroundColor3 = BLANC}, {coin(0.5), UI.degrade(a, a:Lerp(b, 0.75), 90)})
		cadre(haut, {Position = UDim2.fromScale(0, 0.4), Size = UDim2.fromScale(1, 0.6), BackgroundColor3 = BLANC},
			{UI.degrade(a:Lerp(b, 0.4), b, 90)})
		return haut
	end
	arche(UDim2.fromScale(1, 1), BOIS_FONCE, BOIS_FONCE)
	local verre = arche(UDim2.fromScale(0.8, 0.9), Color3.fromRGB(70, 52, 130), Color3.fromRGB(150, 110, 210))
	-- lune et croisillons
	cadre(verre, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.68, 0.24), Size = UDim2.fromScale(0.26, 0.26),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.fromRGB(240, 230, 255), BackgroundTransparency = 0.15}, {coin(0.5)})
	cadre(verre, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.06, 1), BackgroundColor3 = BOIS_FONCE})
	for _, y in {0.42, 0.7} do
		cadre(verre, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(1, 0.035), BackgroundColor3 = BOIS_FONCE})
	end
	cadre(f, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.97), Size = UDim2.fromScale(1.15, 0.06),
		BackgroundColor3 = BOIS}, {coin(0.3)}) -- rebord
	return f
end

-- Lanterne suspendue : chaîne, chapeau, verre ambré qui vacille, halo ; se balance depuis son crochet
local function lanterne(c: D.Contexte, x: number)
	local pivot = cadre(c.milieu, {Name = "Lanterne", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.215),
		Size = UDim2.fromScale(0.1, 0.56), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1})
	cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.05, 0.16), BackgroundColor3 = FER})
	local h = halo(pivot, UDim2.fromScale(0.5, 0.79), 0.42, CHAUD, 0.1)
	c.respire(h, 0.9, 0.92, 1.06)
	cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.67), Size = UDim2.fromScale(0.34, 0.06),
		BackgroundTransparency = 1}, {trait(FER, 2), coin(0.5)}) -- anneau
	cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.69), Size = UDim2.fromScale(0.78, 0.05),
		BackgroundColor3 = FER}, {coin(0.4)}) -- chapeau
	local verre = cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.735), Size = UDim2.fromScale(0.6, 0.13),
		BackgroundColor3 = BLANC}, {coin(0.15), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 170)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 50))})})})
	c.onde(verre, 0.37, {BackgroundTransparency = 0.18})
	for _, bx in {0.1, 0.5, 0.9} do
		cadre(verre, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(bx, 0), Size = UDim2.fromScale(0.08, 1), BackgroundColor3 = FER})
	end
	cadre(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.72, 0.035),
		BackgroundColor3 = FER}, {coin(0.4)}) -- socle
	pivot.Rotation = -3.5
	c.onde(pivot, 3.2, {Rotation = 3.5})
end

-- Bougie : cire crème, coulure, mèche, flamme en goutte (cœur clair) qui vacille, halo chaud
local function bougie(c: D.Contexte, parent: Instance, pos: UDim2, hauteur: number, i: number)
	local b = cadre(parent, {Name = "Bougie", AnchorPoint = Vector2.new(0.5, 1), Position = pos, Size = UDim2.fromScale(hauteur * 0.32, hauteur),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1})
	local h = halo(b, UDim2.fromScale(0.5, 0.2), 1.3, CHAUD, 0.075) -- 1.3 × la hauteur de la bougie
	c.respire(h, 0.6 + i * 0.13, 0.9, 1.08)
	cadre(b, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.62, 0.62),
		BackgroundColor3 = BLANC}, {coin(0.2), UI.degrade(Color3.fromRGB(250, 238, 214), Color3.fromRGB(190, 170, 140), 0)})
	cadre(b, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.36, 0.38), Size = UDim2.fromScale(0.16, 0.22),
		BackgroundColor3 = Color3.fromRGB(252, 244, 226)}, {coin(0.5)}) -- coulure
	cadre(b, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.39), Size = UDim2.fromScale(0.06, 0.06),
		BackgroundColor3 = Color3.fromRGB(30, 20, 16)})
	local flamme = cadre(b, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.42, 0.3),
		BackgroundColor3 = BLANC}, {coin(0.5), creer("UIGradient", {Rotation = -90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 220)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 190, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 110, 30))}), Transparency = NumberSequence.new({kp(0, 0), kp(0.7, 0.1), kp(1, 0.8)})})})
	local e = UI.echelle(flamme)
	e.Scale = 0.9
	c.onde(e, 0.21 + i * 0.04, {Scale = 1.1})
	flamme.Rotation = -4
	c.onde(flamme, 0.5 + i * 0.07, {Rotation = 4})
end

-- Tableau de la Guilde : planches, plaque à l'emblème, parchemins de quêtes punaisés (deux se balancent un peu)
local function tableau(c: D.Contexte, pos: UDim2)
	local t = cadre(c.milieu, {Name = "Tableau", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(0.44, 0.5),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = BLANC}, {coin(0.05), trait(Color3.fromRGB(36, 22, 12), 3),
		UI.degrade(BOIS:Lerp(BLANC, 0.05), BOIS_FONCE, 90)})
	for _, y in {0.3, 0.55, 0.8} do
		cadre(t, {Position = UDim2.fromScale(0.02, y), Size = UDim2.fromScale(0.96, 0.012), BackgroundColor3 = Color3.fromRGB(40, 24, 14),
			BackgroundTransparency = 0.3})
	end
	local plaque = cadre(t, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.03), Size = UDim2.fromScale(0.42, 0.17),
		BackgroundColor3 = Color3.fromRGB(46, 28, 18)}, {coin(0.2), trait(Color3.fromRGB(214, 160, 60), 2)})
	embleme(plaque, UDim2.fromScale(0.5, 0.5), 0.36)
	local feuilles = {{0.24, 0.42, 0.3, 0.32, -5}, {0.62, 0.38, 0.28, 0.27, 4}, {0.36, 0.73, 0.3, 0.3, 3}, {0.76, 0.72, 0.26, 0.3, -6}}
	for k, p in feuilles do
		local f = cadre(t, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(p[1], p[2]), Size = UDim2.fromScale(p[3], p[4]),
			Rotation = p[5], BackgroundColor3 = BLANC}, {coin(0.06), UI.degrade(Color3.fromRGB(244, 230, 198), Color3.fromRGB(206, 182, 140), 90)})
		for l = 0, 3 do
			cadre(f, {Position = UDim2.fromScale(0.14, 0.3 + l * 0.15), Size = UDim2.fromScale(if l == 3 then 0.45 else 0.72, 0.035),
				BackgroundColor3 = ENCRE, BackgroundTransparency = 0.45}, {coin(0.5)})
		end
		local sceau = k % 2 == 1
		cadre(f, {AnchorPoint = Vector2.new(0.5, 0.5), Position = if sceau then UDim2.fromScale(0.78, 0.86) else UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(if sceau then 0.2 else 0.1, if sceau then 0.2 else 0.1), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundColor3 = if sceau then Color3.fromRGB(170, 36, 40) else Color3.fromRGB(150, 150, 160)}, {coin(0.5)})
		if k == 2 or k == 3 then
			c.onde(f, 2.6 + k * 0.5, {Rotation = p[5] + (if p[5] > 0 then -2.5 else 2.5)})
		end
	end
	return t
end

function DecorTaverne.creer(interieur: Frame, boucles: {Tween}): D.Decor
	local function construire(c: D.Contexte)
		-- Lointain : fenêtre au clair de lune, rayons violets qui descendent, chaleur de l'âtre en bas
		c.respire(halo(c.loin, UDim2.fromScale(0.5, 0.42), 0.75, VIOLET, 0.06), 4.2, 0.95, 1.05)
		for i, r in {{0.47, 0.07, 28}, {0.52, 0.05, 22}, {0.56, 0.08, 34}} do
			local ray = rayon(c.loin, r[1], r[2], r[3], Color3.fromRGB(200, 170, 255), 0.32, 1.1)
			c.onde(ray, 6 + i * 1.4, {Rotation = r[3] - 5})
		end
		fenetre(c, UDim2.fromScale(0.5, 0.4))
		c.respire(halo(c.loin, UDim2.fromScale(0.15, 0.9), 0.95, CHAUD, 0.065), 2.8, 0.94, 1.05)
		c.respire(halo(c.loin, UDim2.fromScale(0.85, 0.88), 0.95, CHAUD, 0.06), 3.4, 0.94, 1.05)

		-- Milieu : bannières de part et d'autre de la fenêtre, lanterne à gauche, tableau de la Guilde à droite
		banniere(c, 0.33, 3.8)
		banniere(c, 0.67, 4.4)
		lanterne(c, 0.2)
		tableau(c, UDim2.fromScale(0.86, 0.54))
		D.vue3D(c.milieu, UDim2.fromScale(0.09, 0.8), 0.52, pyramideTonneaux(), {angle = 0.32, hauteur = 0.16, marge = 0.8,
			ambiant = Color3.fromRGB(110, 86, 72), lumiere = Color3.fromRGB(255, 200, 140), transparence = 0.1})

		-- Proche : chopes moussues (bas droite) et bougies (sur les tonneaux, au pied du tableau)
		c.respire(halo(c.proche, UDim2.fromScale(0.93, 0.93), 0.4, CHAUD, 0.08), 2.4, 0.9, 1.08)
		D.vue3D(c.proche, UDim2.fromScale(0.93, 0.93), 0.28, plateauChopes(), {angle = -0.35, hauteur = 0.3, marge = 0.85,
			ambiant = Color3.fromRGB(120, 92, 76), lumiere = Color3.fromRGB(255, 206, 150), transparence = 0.1})
		bougie(c, c.proche, UDim2.fromScale(0.075, 0.61), 0.11, 1)
		bougie(c, c.proche, UDim2.fromScale(0.105, 0.61), 0.075, 2)
		bougie(c, c.proche, UDim2.fromScale(0.8, 1.0), 0.1, 3)
		bougie(c, c.proche, UDim2.fromScale(0.25, 1.0), 0.09, 4)
	end

	return D.monter(interieur, boucles, {
		nom = "DecorTaverne",
		construire = construire,
		-- Lumière tamisée : voile un peu plus dense et légèrement prune
		teinteVoile = Color3.fromRGB(18, 11, 16),
		voile = NumberSequence.new({kp(0, 0.66), kp(0.18, 0.6), kp(0.5, 0.52), kp(0.82, 0.6), kp(1, 0.66)}),
		grains = {
			-- poussière dorée dans la lumière : lente, dans tous les sens
			{nombre = 14, taille = {0.003, 0.006}, duree = {7, 12}, opacite = {0.45, 0.7},
				couleur = function()
					return Color3.fromRGB(236, 212, 172)
				end,
				depart = function()
					return math.random(), 0.1 + math.random() * 0.85
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.5) * 0.12, y + (math.random() - 0.6) * 0.14
				end, pause = 4},
			-- paillettes violettes (la Veine d'Étoile) qui montent sous la fenêtre
			{nombre = 6, forme = "etoile", taille = {0.012, 0.02}, duree = {2.2, 3.4}, opacite = {0.5, 0.85},
				couleur = function()
					return VIOLET
				end,
				depart = function()
					return 0.3 + math.random() * 0.4, 0.45 + math.random() * 0.45
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.5) * 0.05, y - 0.08 - math.random() * 0.1
				end, pause = 4},
		},
	})
end

return DecorTaverne
