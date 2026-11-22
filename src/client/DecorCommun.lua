--!strict
-- Socle commun des décors d'arrière-plan des commerçants (StarterPlayerScripts › Jeu › DecorCommun).
-- Même recette que DecorPioches (Liesel), qui reste autonome : racine ZIndex 2 (au-dessus de la pierre, sous
-- l'en-tête et le contenu), couches lointain / milieu / proche, voile sombre qui garde les cartes lisibles,
-- couche « devant » (éclats vifs au-dessus du voile), poussières recyclées, léger parallaxe à la souris.
-- Construction une seule fois (préchargée fenêtre fermée, protégée par pcall) ; tout s'arrête fenêtre fermée.
--   local decor = DecorCommun.monter(interieur, boucles, {nom = "DecorForge", construire = function(c) ... end, grains = {...}})
--   decor.demarrer() -- à l'ouverture ; decor.arreter() -- à la fermeture
-- Outils de dessin partagés : halo, rayon, etoile (2D) ; bloc, cylindre, vue3D, copie, profil, vpCristal (3D en ViewportFrame).

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))

local creer, coin = UI.creer, UI.coin
local T = UI.T

export type Decor = {demarrer: () -> (), arreter: () -> ()}
export type Orbite = {vp: ViewportFrame, camera: Camera, centre: Vector3, distance: number, angle: number, hauteur: number, roulis: number}
export type TypeGrain = {
	nombre: number,
	forme: string?, -- "rond" (défaut) | "magma" (éclat brûlant qui tourne) | "etoile" (reflet scintillant)
	taille: {number}, -- {min, max}, en fraction de la largeur
	duree: {number}, -- {min, max} secondes de vie
	opacite: {number}, -- transparence au plus visible {min, max} ; étoile : échelle maximale {min, max}
	couleur: () -> Color3,
	depart: () -> (number, number), -- position de départ (échelle)
	arrivee: (number, number) -> (number, number), -- position d'arrivée selon le départ
	pause: number?, -- attente maximale entre deux vies
	tourne: number?, -- degrés parcourus pendant une vie
	style: Enum.EasingStyle?,
	sens: Enum.EasingDirection?,
}
export type Contexte = {
	interieur: Frame,
	loin: Frame,
	milieu: Frame,
	proche: Frame,
	devant: Frame, -- au-dessus du voile, même parallaxe que « milieu »
	boucles: {Tween},
	respire: (o: GuiObject, duree: number, de: number, a: number) -> (),
	onde: (o: Instance, duree: number, props: {[string]: any}) -> (), -- aller-retour sinusoïdal infini
	chaqueImage: (fn: (dt: number) -> ()) -> (), -- appelée à chaque image, fenêtre ouverte seulement
	cadence: (fn: () -> (), min: number, max: number) -> (), -- appelée de temps en temps (peut attendre)
}
export type Config = {
	nom: string,
	construire: (Contexte) -> (),
	grains: {TypeGrain},
	teinteVoile: Color3?,
	voile: NumberSequence?,
}

local DecorCommun = {}

local BLANC = Color3.new(1, 1, 1)
DecorCommun.BLANC = BLANC
local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end
DecorCommun.kp = kp
local function entre(t: {number}): number
	return t[1] + math.random() * (t[2] - t[1])
end
DecorCommun.entre = entre

-- ================= Dessin 2D =================
-- Halo doux : disques concentriques très transparents (faux dégradé radial, aucune image)
function DecorCommun.halo(parent: Instance, pos: UDim2, taille: number, couleur: Color3, force: number?): Frame
	local h = creer("Frame", {Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(taille, taille),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, Parent = parent})
	local n = 6
	for k = 0, n - 1 do
		local s = 1 - k / n * 0.85
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s),
			BackgroundColor3 = couleur:Lerp(BLANC, k / n * 0.45), BackgroundTransparency = 1 - (force or 0.07),
			BorderSizePixel = 0, Parent = h}, {coin(0.5)})
	end
	return h
end

-- Rayon de lumière : trois bandes superposées (bords adoucis), fondu sur la longueur. y = départ (défaut : au-dessus du cadre)
function DecorCommun.rayon(parent: Instance, x: number, largeur: number, angle: number, couleur: Color3, y: number?, longueur: number?): Frame
	local r = creer("Frame", {Name = "Rayon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, y or -0.3),
		Size = UDim2.fromScale(largeur, longueur or 1.6), Rotation = angle, BackgroundTransparency = 1, Parent = parent})
	for _, f in {1, 0.6, 0.28} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(f, 1),
			BackgroundColor3 = couleur, BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = r},
			{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 0.1), kp(0.4, 0.45), kp(0.75, 0.85), kp(1, 1)})})})
	end
	return r
end

-- Reflet en étoile (4 branches fondues + 2 petites diagonales + cœur blanc) ; taille en fraction de la largeur
function DecorCommun.etoile(parent: Instance, taille: number, couleur: Color3): Frame
	local e = creer("Frame", {Name = "Etoile", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(taille, taille),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1, Parent = parent})
	local fondu = NumberSequence.new({kp(0, 1), kp(0.5, 0), kp(1, 1)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
		BackgroundColor3 = couleur, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = e}, {coin(0.5)})
	for _, b in {{1, 0.1, 0, 0}, {0.1, 1, 0, 90}, {0.5, 0.06, 45, 0}, {0.5, 0.06, -45, 0}} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(b[1], b[2]),
			Rotation = b[3], BackgroundColor3 = couleur:Lerp(BLANC, 0.35), BorderSizePixel = 0, Parent = e},
			{coin(0.5), creer("UIGradient", {Rotation = b[4], Transparency = fondu})})
	end
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.16),
		BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = e}, {coin(0.5)})
	return e
end

-- ================= 3D en ViewportFrame =================
function DecorCommun.bloc(m: Model, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, transp: number?, forme: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size, p.CFrame, p.Color, p.Material, p.Anchored = taille, cf, couleur, mat, true
	p.Transparency = transp or 0
	p.Reflectance = if mat == Enum.Material.Glass then 0.25 elseif mat == Enum.Material.Metal then 0.08 else 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if forme then
		p.Shape = forme
	end
	p.Parent = m
	return p
end
local bloc = DecorCommun.bloc

-- Cylindre le long de l'axe X du CFrame (« longueur » sur X, « diametre » sur Y/Z)
function DecorCommun.cylindre(m: Model, longueur: number, diametre: number, cf: CFrame, couleur: Color3, mat: Enum.Material): Part
	return bloc(m, Vector3.new(longueur, diametre, diametre), cf, couleur, mat, nil, Enum.PartType.Cylinder)
end

-- Cristal façon grottes du jeu (cœur néon, gaine de verre, pointe en losange) — même dessin que DecorPioches
local function prisme(m: Model, cf: CFrame, h: number, couleur: Color3)
	local r = h * 0.22
	local axe = cf * CFrame.Angles(0, math.rad(45), 0)
	bloc(m, Vector3.new(r * 0.5, h * 0.92, r * 0.5), axe * CFrame.new(0, h * 0.46, 0), couleur, Enum.Material.Neon)
	bloc(m, Vector3.new(r, h, r), axe * CFrame.new(0, h / 2, 0), couleur, Enum.Material.Glass, 0.4)
	bloc(m, Vector3.one * r * 0.72, axe * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), couleur, Enum.Material.Glass, 0.3)
end
function DecorCommun.amasCristaux(couleur: Color3, graine: number): Model
	local m = Instance.new("Model")
	local rng = Random.new(graine)
	bloc(m, Vector3.new(2.6, 0.7, 2.2), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0.4, 0.08), Color3.fromRGB(46, 40, 38), Enum.Material.Slate)
	bloc(m, Vector3.new(1.6, 0.6, 1.5), CFrame.new(0.7, 0.35, 0.3) * CFrame.Angles(0.1, 1.1, -0.1), Color3.fromRGB(58, 50, 46), Enum.Material.Slate)
	prisme(m, CFrame.new(0, 0.4, 0), 3.2, couleur)
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local cf = CFrame.new(0, 0.4, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.45) * CFrame.Angles(-rng:NextNumber(0.4, 0.75), 0, 0)
		prisme(m, cf, 3.2 * rng:NextNumber(0.35, 0.6), couleur:Lerp(BLANC, rng:NextNumber(0, 0.2)))
	end
	return m
end

-- Caméra en orbite autour du centre (angle autour de Y, plongée, roulis autour de l'axe de visée)
function DecorCommun.placerOrbite(o: Orbite)
	local cf = CFrame.new(o.centre) * CFrame.Angles(0, o.angle, 0) * CFrame.Angles(-o.hauteur, 0, 0) * CFrame.new(0, 0, o.distance)
		* CFrame.Angles(0, 0, math.rad(o.roulis))
	o.camera.CFrame = cf
	o.vp.LightDirection = cf:VectorToWorldSpace(Vector3.new(0.5, -1, -0.7).Unit)
end
local placerOrbite = DecorCommun.placerOrbite

type OptsVue = {angle: number?, hauteur: number?, marge: number?, ambiant: Color3?, lumiere: Color3?, transparence: number?,
	teinte: Color3?, centre: Vector3?, rayon: number?}
-- Modèle construit en code dans un ViewportFrame carré (taille relative à la hauteur), cadré par sa boîte englobante
function DecorCommun.vue3D(parent: Instance, pos: UDim2, taille: number, modele: Model, opts: OptsVue?): Orbite
	local o = opts or {}
	local vp = creer("ViewportFrame", {Name = "Vue3D", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
		Size = UDim2.fromScale(taille, taille), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
		Ambient = o.ambiant or Color3.fromRGB(110, 96, 88), LightColor = o.lumiere or Color3.fromRGB(255, 220, 180),
		ImageTransparency = o.transparence or 0.12, ImageColor3 = o.teinte or BLANC, Parent = parent})
	local cam = creer("Camera", {FieldOfView = 30, Parent = vp})
	vp.CurrentCamera = cam
	modele.Parent = vp
	local cf, t = modele:GetBoundingBox()
	local rayon = o.rayon or t.Magnitude / 2
	local orb: Orbite = {vp = vp, camera = cam, centre = o.centre or cf.Position, distance = rayon / math.tan(math.rad(15)) * (o.marge or 0.95),
		angle = o.angle or 0, hauteur = o.hauteur or 0.25, roulis = 0}
	placerOrbite(orb)
	return orb
end

function DecorCommun.vpCristal(parent: Instance, pos: UDim2, taille: number, couleur: Color3, graine: number, angle: number): Orbite
	local o = DecorCommun.vue3D(parent, pos, taille, DecorCommun.amasCristaux(couleur, graine),
		{angle = angle, hauteur = 0.28, ambiant = Color3.fromRGB(110, 100, 116), lumiere = couleur:Lerp(BLANC, 0.5)})
	return o
end

-- Copie du vrai modèle d'une icône (IconesObjets), pour composer des tas / piles dans une seule vue
function DecorCommun.copie(vp: ViewportFrame): Model?
	local obj = vp:FindFirstChild("Objet")
	local m = if obj and obj:IsA("Model") then obj:Clone() else nil
	vp:Destroy()
	return m
end

-- Oriente la caméra d'une icône pour voir l'objet de profil (axe le plus mince), puis l'incline (comme DecorPioches)
function DecorCommun.profil(vp: ViewportFrame, roulis: number)
	local v = Icones.vue(vp)
	local obj = vp:FindFirstChild("Objet")
	if not (v and obj and obj:IsA("Model")) then
		return
	end
	local cf, t = obj:GetBoundingBox()
	local dir = if t.X <= t.Y and t.X <= t.Z then cf.RightVector elseif t.Y <= t.Z then cf.UpVector else cf.LookVector
	if Vector2.new(dir.X, dir.Z).Magnitude > 0.2 then
		v.angle = math.atan2(dir.X, dir.Z)
	end
	v.vitesse = 0
	Icones.placer(vp)
	v.camera.CFrame *= CFrame.Angles(0, 0, math.rad(roulis))
end

-- ================= Montage d'un décor =================
type Grain = {f: Frame, e: UIScale?, type: TypeGrain, vivant: boolean}

function DecorCommun.monter(interieur: Frame, boucles: {Tween}, config: Config): Decor
	-- ZIndex 2 : au-dessus de la pierre (1), sous l'en-tête et le contenu (3)
	local racine = creer("Frame", {Name = config.nom, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
		Parent = interieur})
	local function couche(nom: string): Frame
		return creer("Frame", {Name = nom, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = racine})
	end
	-- Ordre de dessin = ordre de création : lointain, milieu, proche, voile, devant (éclats vifs), poussières
	local loin, milieu, proche = couche("Loin"), couche("Milieu"), couche("Proche")
	creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = config.teinteVoile or T.Fond3D, BorderSizePixel = 0,
		Parent = racine}, {creer("UIGradient", {Transparency = config.voile or NumberSequence.new({kp(0, 0.72), kp(0.18, 0.66),
		kp(0.5, 0.56), kp(0.82, 0.66), kp(1, 0.72)})})})
	local devant = couche("Devant")
	local poussiere = couche("Poussiere")
	-- Amplitude du parallaxe (px) : plus la couche est proche, plus elle bouge
	local couches: {{cadre: Frame, amp: number, x: number, y: number}} = {{cadre = loin, amp = 6, x = 0, y = 0},
		{cadre = milieu, amp = 12, x = 0, y = 0}, {cadre = proche, amp = 20, x = 0, y = 0}, {cadre = devant, amp = 12, x = 0, y = 0},
		{cadre = poussiere, amp = 26, x = 0, y = 0}}

	local construit = false
	local actif = false
	local session = 0
	local images: {(number) -> ()} = {}
	local cadences: {{fn: () -> (), min: number, max: number}} = {}

	local function lancerCadence(c: {fn: () -> (), min: number, max: number})
		local maSession = session
		task.spawn(function()
			task.wait(c.min * math.random())
			while actif and session == maSession do
				local ok, err = pcall(c.fn)
				if not ok then
					warn("[" .. config.nom .. "] animation :", err)
					return
				end
				task.wait(c.min + math.random() * (c.max - c.min))
			end
		end)
	end

	local ctx: Contexte = {
		interieur = interieur, loin = loin, milieu = milieu, proche = proche, devant = devant, boucles = boucles,
		respire = function(o: GuiObject, duree: number, de: number, a: number)
			local e = UI.echelle(o)
			e.Scale = de
			UI.boucle(e, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = a}, boucles)
		end,
		onde = function(o: Instance, duree: number, props: {[string]: any})
			UI.boucle(o, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), props, boucles)
		end,
		chaqueImage = function(fn: (number) -> ())
			table.insert(images, fn)
		end,
		cadence = function(fn: () -> (), min: number, max: number)
			table.insert(cadences, {fn = fn, min = min, max = max})
		end,
	}

	-- Poussières / braises / reflets : réserve fixe par type, recyclée
	local grains: {Grain} = {}
	for _, tg in config.grains do
		for _ = 1, tg.nombre do
			local t = entre(tg.taille)
			local forme = tg.forme or "rond"
			local g: Grain
			if forme == "etoile" then
				local f = DecorCommun.etoile(poussiere, t, tg.couleur())
				f.Visible = false
				local e = UI.echelle(f)
				e.Scale = 0
				g = {f = f, e = e, type = tg, vivant = false}
			else
				local f = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(t, if forme == "magma" then t * 0.78 else t),
					SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, BackgroundTransparency = 1, Visible = false,
					BackgroundColor3 = if forme == "magma" then BLANC else tg.couleur(), Parent = poussiere},
					{coin(if forme == "magma" then 0.3 else 0.5)})
				if forme == "magma" then
					local c = tg.couleur()
					creer("UIGradient", {Rotation = 45, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c:Lerp(BLANC, 0.7)),
						ColorSequenceKeypoint.new(0.45, c), ColorSequenceKeypoint.new(1, c:Lerp(Color3.fromRGB(90, 10, 0), 0.6))}), Parent = f})
				end
				g = {f = f, type = tg, vivant = false}
			end
			table.insert(grains, g)
		end
	end

	local function cycle(g: Grain)
		if not actif then
			g.vivant = false
			g.f.Visible = false
			return
		end
		g.vivant = true
		local tg, f = g.type, g.f
		local x, y = tg.depart()
		local x2, y2 = tg.arrivee(x, y)
		local duree = entre(tg.duree)
		f.Position = UDim2.fromScale(x, y)
		f.Visible = true
		local e = g.e
		if e then -- étoile : apparaît en grandissant, tourne, disparaît
			e.Scale = 0
			f.Rotation = math.random(0, 45)
			TweenService:Create(e, TweenInfo.new(duree * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = entre(tg.opacite)}):Play()
			task.delay(duree * 0.5, function()
				TweenService:Create(e, TweenInfo.new(duree * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0}):Play()
			end)
		else
			f.BackgroundTransparency = 1
			TweenService:Create(f, TweenInfo.new(duree * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{BackgroundTransparency = entre(tg.opacite)}):Play()
			task.delay(duree * 0.55, function()
				TweenService:Create(f, TweenInfo.new(duree * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
			end)
			if tg.tourne then
				f.Rotation = math.random(0, 90)
			end
		end
		local props: {[string]: any} = {Position = UDim2.fromScale(x2, y2)}
		if tg.tourne then
			props.Rotation = f.Rotation + tg.tourne * (if math.random() < 0.5 then -1 else 1)
		end
		local mvt = TweenService:Create(f, TweenInfo.new(duree, tg.style or Enum.EasingStyle.Sine, tg.sens or Enum.EasingDirection.InOut), props)
		mvt.Completed:Once(function()
			if tg.pause then
				f.Visible = false
				task.delay(math.random() * tg.pause, cycle, g)
			else
				cycle(g)
			end
		end)
		mvt:Play()
	end

	-- Parallaxe (souris) + animations image par image du décor : une seule connexion, seulement fenêtre ouverte
	local connexion: RBXScriptConnection? = nil
	local decalage = Vector2.zero
	local function image(dt: number)
		local centre = interieur.AbsolutePosition + interieur.AbsoluteSize / 2
		local demi = interieur.AbsoluteSize / 2
		local souris = UserInputService:GetMouseLocation()
		local cible = Vector2.zero
		if demi.X > 1 and demi.Y > 1 then
			local rel = (souris - centre) / demi
			cible = Vector2.new(math.clamp(rel.X, -1, 1), math.clamp(rel.Y, -1, 1))
		end
		decalage += (cible - decalage) * math.min(1, dt * 4)
		for _, c in couches do
			local x, y = math.round(-decalage.X * c.amp), math.round(-decalage.Y * c.amp)
			if x ~= c.x or y ~= c.y then
				c.x, c.y = x, y
				c.cadre.Position = UDim2.new(0.5, x, 0.5, y)
			end
		end
		for _, fn in images do
			fn(dt)
		end
	end

	-- Construction protégée : en cas d'erreur, on nettoie et on réessaiera à la prochaine ouverture
	local function construireProtege()
		if construit then
			return
		end
		local avant = #boucles
		local ok, err = pcall(config.construire, ctx)
		if ok then
			construit = true
			if actif then -- fenêtre déjà ouverte : ses boucles tournent, on lance celles du décor
				for k = avant + 1, #boucles do
					boucles[k]:Play()
				end
				for _, c in cadences do
					lancerCadence(c)
				end
			end
		else
			warn("[" .. config.nom .. "] décor non construit :", err)
			for k = #boucles, avant + 1, -1 do
				boucles[k]:Cancel()
				table.remove(boucles, k)
			end
			for _, c in {loin, milieu, proche, devant} do
				c:ClearAllChildren()
			end
			table.clear(images)
			table.clear(cadences)
		end
	end
	-- Préchargé fenêtre fermée (pas pendant l'animation d'ouverture)
	task.delay(3, construireProtege)

	local function demarrer()
		if not construit then
			task.defer(construireProtege) -- secours si on ouvre avant le préchargement
		end
		if actif then
			return
		end
		actif = true
		session += 1
		if not connexion then
			connexion = RunService.RenderStepped:Connect(image)
		end
		for _, c in cadences do
			lancerCadence(c)
		end
		for _, g in grains do
			if not g.vivant then
				g.vivant = true
				task.delay(math.random() * (g.type.pause or 3), cycle, g)
			end
		end
	end

	local function arreter()
		actif = false
		session += 1
		if connexion then
			connexion:Disconnect()
			connexion = nil
		end
	end

	return {demarrer = demarrer, arreter = arreter}
end

return DecorCommun
