--!strict
-- Décor d'arrière-plan de la boutique de pioches de Liesel (StarterPlayerScripts › Jeu › DecorPioches).
-- Second plan, derrière les cartes et la fiche : grandes pioches du jeu en contre-jour, minerais et cristaux
-- lumineux (vrais modèles en ViewportFrame, 7 au total), halos, rayons de lumière, poussière et étincelles,
-- léger parallaxe à la souris. Construit une seule fois (à la première ouverture) ; tout s'arrête fenêtre fermée.
--   local decor = require(script.Parent.DecorPioches).creer(interieur, boucles)
--   decor.demarrer() -- à l'ouverture ; decor.arreter() -- à la fermeture

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))

local creer, coin = UI.creer, UI.coin
local T = UI.T

export type Decor = {demarrer: () -> (), arreter: () -> ()}

local DecorPioches = {}

local BLANC = Color3.new(1, 1, 1)
local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- Halo doux : disques concentriques très transparents (faux dégradé radial, aucune image)
local function halo(parent: Instance, pos: UDim2, taille: number, couleur: Color3, force: number?): Frame
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

-- Rayon de lumière (god ray) : trois bandes superposées pour des bords adoucis, fondu sur la longueur
local function rayon(parent: Instance, x: number, largeur: number, angle: number, couleur: Color3): Frame
	local r = creer("Frame", {Name = "Rayon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(x, -0.3),
		Size = UDim2.fromScale(largeur, 1.6), Rotation = angle, BackgroundTransparency = 1, Parent = parent})
	for _, f in {1, 0.6, 0.28} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(f, 1),
			BackgroundColor3 = couleur, BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = r},
			{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 0.1), kp(0.4, 0.45), kp(0.75, 0.85), kp(1, 1)})})})
	end
	return r
end

-- Cristal façon grottes du jeu (cœur néon, gaine de verre, pointe en losange) — même dessin que Batiments.cristal
local function bloc(m: Model, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, transp: number?): Part
	local p = Instance.new("Part")
	p.Size, p.CFrame, p.Color, p.Material, p.Anchored = taille, cf, couleur, mat, true
	p.Transparency = transp or 0
	p.Reflectance = if mat == Enum.Material.Glass then 0.25 else 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local function prisme(m: Model, cf: CFrame, h: number, couleur: Color3)
	local r = h * 0.22
	local axe = cf * CFrame.Angles(0, math.rad(45), 0)
	bloc(m, Vector3.new(r * 0.5, h * 0.92, r * 0.5), axe * CFrame.new(0, h * 0.46, 0), couleur, Enum.Material.Neon)
	bloc(m, Vector3.new(r, h, r), axe * CFrame.new(0, h / 2, 0), couleur, Enum.Material.Glass, 0.4)
	bloc(m, Vector3.one * r * 0.72, axe * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), couleur, Enum.Material.Glass, 0.3)
end
local function amasCristaux(couleur: Color3, graine: number): Model
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

type Grain = {f: Frame, etincelle: boolean, vivant: boolean}
type Orbite = {vp: ViewportFrame, camera: Camera, centre: Vector3, distance: number, angle: number, hauteur: number}
local function placerOrbite(o: Orbite)
	local cf = CFrame.new(o.centre) * CFrame.Angles(0, o.angle, 0) * CFrame.Angles(-o.hauteur, 0, 0) * CFrame.new(0, 0, o.distance)
	o.camera.CFrame = cf
	o.vp.LightDirection = cf:VectorToWorldSpace(Vector3.new(0.5, -1, -0.7).Unit)
end

local function vpCristal(parent: Instance, pos: UDim2, taille: number, couleur: Color3, graine: number, angle: number): Orbite
	local vp = creer("ViewportFrame", {Name = "Cristal", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
		Size = UDim2.fromScale(taille, taille), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(110, 100, 116), LightColor = couleur:Lerp(BLANC, 0.5), ImageTransparency = 0.12, Parent = parent})
	local cam = creer("Camera", {FieldOfView = 30, Parent = vp})
	vp.CurrentCamera = cam
	local m = amasCristaux(couleur, graine)
	m.Parent = vp
	local cf, t = m:GetBoundingBox()
	local o: Orbite = {vp = vp, camera = cam, centre = cf.Position, distance = t.Magnitude / 2 / math.tan(math.rad(15)) * 0.95,
		angle = angle, hauteur = 0.28}
	placerOrbite(o)
	return o
end

-- Oriente la caméra d'une icône de pioche pour la voir de profil (axe le plus mince du modèle), puis l'incline
local function profil(vp: ViewportFrame, roulis: number)
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

function DecorPioches.creer(interieur: Frame, boucles: {Tween}): Decor
	-- ZIndex 2 : au-dessus de la pierre (1), sous l'en-tête et le contenu (3)
	local racine = creer("Frame", {Name = "DecorPioches", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
		Parent = interieur})
	local function couche(nom: string): Frame
		return creer("Frame", {Name = nom, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = racine})
	end
	-- Ordre de dessin = ordre de création : lointain, pioches, minerais/cristaux, voile, poussières
	local loin, milieu, proche = couche("Loin"), couche("Milieu"), couche("Proche")
	creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Fond3D, BorderSizePixel = 0,
		Parent = racine}, {creer("UIGradient", {Transparency = NumberSequence.new({kp(0, 0.72), kp(0.18, 0.66), kp(0.5, 0.56),
		kp(0.82, 0.66), kp(1, 0.72)})})})
	local poussiere = couche("Poussiere")
	-- Amplitude du parallaxe (px) : plus la couche est proche, plus elle bouge
	local couches: {{cadre: Frame, amp: number, x: number, y: number}} = {{cadre = loin, amp = 6, x = 0, y = 0},
		{cadre = milieu, amp = 12, x = 0, y = 0}, {cadre = proche, amp = 20, x = 0, y = 0}, {cadre = poussiere, amp = 26, x = 0, y = 0}}

	local construit = false
	local orbites: {Orbite} = {}
	local tournant: Orbite? = nil

	local function respire(o: GuiObject, duree: number, de: number, a: number)
		local e = UI.echelle(o)
		e.Scale = de
		UI.boucle(e, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = a}, boucles)
	end

	local function construire()
		-- Lointain : rayons de lumière chauds venant du haut, qui oscillent lentement
		for i, r in {{0.2, 0.09, 24}, {0.34, 0.05, 20}, {0.58, 0.11, 16}, {0.76, 0.06, 22}, {0.9, 0.08, 14}} do
			local ray = rayon(loin, r[1], r[2], r[3], Color3.fromRGB(255, 206, 140))
			UI.boucle(ray, TweenInfo.new(5 + i * 1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = r[3] - 7}, boucles)
		end
		-- Contre-jours derrière les grandes pioches : braise à gauche, givre à droite
		respire(halo(loin, UDim2.fromScale(0.12, 0.52), 1.0, Color3.fromRGB(255, 120, 40), 0.075), 3.4, 0.94, 1.06)
		respire(halo(loin, UDim2.fromScale(0.88, 0.46), 0.95, Color3.fromRGB(90, 170, 255), 0.07), 4.1, 0.95, 1.07)

		-- Milieu : deux grandes pioches du jeu en silhouette (ne dévoilent pas les pioches à découvrir)
		for _, p in {{"Legende", UDim2.fromScale(0.11, 0.6), 1.15, -22}, {"Demon", UDim2.fromScale(0.9, 0.56), 1.1, 24}} do
			local cadre = creer("Frame", {Name = "Pioche", AnchorPoint = Vector2.new(0.5, 0.5), Position = p[2] :: UDim2,
				Size = UDim2.fromScale(p[3] :: number, p[3] :: number), SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1, Parent = milieu})
			local vp = Icones.pioche(p[1] :: string, cadre, {silhouette = true, vitesse = 0, marge = 0.78, hauteur = 0.04})
			vp.ImageTransparency = 0.3
			profil(vp, p[4] :: number)
		end

		-- Proche : minerais du jeu (MineraisModeles) et cristaux, chacun avec son halo qui respire
		for i, m in {{"Gold", UDim2.fromScale(0.07, 0.9), 0.32, 0.25}, {"Fer", UDim2.fromScale(0.95, 0.9), 0.28, 0},
			{"Bronze", UDim2.fromScale(0.5, 1.0), 0.2, 0}} do
			local nom = m[1] :: string
			local pos, taille = m[2] :: UDim2, m[3] :: number
			local lueur = MineraisModeles.VISUEL[nom]
			if lueur then
				respire(halo(proche, pos, taille * 1.9, lueur.cristal, 0.08), 2.4 + i * 0.6, 0.9, 1.08)
			end
			local vp = Icones.minerai(nom, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
				Size = UDim2.fromScale(taille, taille), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
				Parent = proche}), {vitesse = m[4] :: number, marge = 0.85, hauteur = 0.35, angle = i * 1.7})
			vp.ImageTransparency = 0.15
			vp.ImageColor3 = Color3.fromRGB(225, 215, 205)
		end
		local violet, cyan = Color3.fromRGB(180, 110, 255), Color3.fromRGB(90, 220, 255)
		respire(halo(proche, UDim2.fromScale(0.035, 0.34), 0.62, violet, 0.085), 2.9, 0.88, 1.1)
		respire(halo(proche, UDim2.fromScale(0.975, 0.3), 0.58, cyan, 0.085), 3.3, 0.9, 1.08)
		table.insert(orbites, vpCristal(proche, UDim2.fromScale(0.035, 0.34), 0.34, violet, 7, 0.6))
		local c = vpCristal(proche, UDim2.fromScale(0.975, 0.3), 0.3, cyan, 13, 2.2)
		table.insert(orbites, c)
		tournant = c -- un seul cristal tourne (avec le minerai d'or) : le reste est fixe
	end

	-- Poussière (beige, lente, dans tous les sens) et étincelles (braises qui montent) : réserve fixe, recyclée
	local NB_POUSSIERE, NB_ETINCELLES = 12, 9
	local grains: {Grain} = {}
	for i = 1, NB_POUSSIERE + NB_ETINCELLES do
		local etincelle = i > NB_POUSSIERE
		local t = if etincelle then 0.0025 + math.random() * 0.002 else 0.003 + math.random() * 0.004
		local f = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(t, t), SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BorderSizePixel = 0, BackgroundTransparency = 1, Visible = false, Parent = poussiere,
			BackgroundColor3 = if etincelle then Color3.fromRGB(255, math.random(140, 210), math.random(40, 90)) else Color3.fromRGB(232, 214, 186)},
			{coin(0.5)})
		table.insert(grains, {f = f, etincelle = etincelle, vivant = false})
	end

	local actif = false
	local function cycle(g: Grain)
		if not actif then
			g.vivant = false
			g.f.Visible = false
			return
		end
		g.vivant = true
		local f = g.f
		local x = math.random()
		local y = if g.etincelle then 0.8 + math.random() * 0.25 else 0.05 + math.random() * 0.9
		local duree = if g.etincelle then 3 + math.random() * 2.5 else 6 + math.random() * 5
		local fin = if g.etincelle then UDim2.fromScale(x + (math.random() - 0.5) * 0.1, y - 0.3 - math.random() * 0.35)
			else UDim2.fromScale(x + (math.random() - 0.5) * 0.12, y + (math.random() - 0.6) * 0.14)
		f.Position = UDim2.fromScale(x, y)
		f.BackgroundTransparency = 1
		f.Visible = true
		local opacite = if g.etincelle then 0.05 + math.random() * 0.3 else 0.45 + math.random() * 0.3
		TweenService:Create(f, TweenInfo.new(duree * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = opacite}):Play()
		task.delay(duree * 0.55, function()
			TweenService:Create(f, TweenInfo.new(duree * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		end)
		local mvt = TweenService:Create(f, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = fin})
		mvt.Completed:Once(function()
			cycle(g)
		end)
		mvt:Play()
	end

	-- Parallaxe (souris) + rotation lente d'un cristal : une seule connexion, seulement fenêtre ouverte
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
		local o = tournant
		if o then
			o.angle += dt * 0.35
			placerOrbite(o)
		end
	end

	-- Construction protégée : en cas d'erreur, on nettoie et on réessaiera à la prochaine ouverture
	local function construireProtege()
		if construit then
			return
		end
		local avant = #boucles
		local ok, err = pcall(construire)
		if ok then
			construit = true
			if actif then -- fenêtre déjà ouverte : ses boucles tournent, on lance celles du décor
				for k = avant + 1, #boucles do
					boucles[k]:Play()
				end
			end
		else
			warn("[DecorPioches] décor non construit :", err)
			for k = #boucles, avant + 1, -1 do
				boucles[k]:Cancel()
				table.remove(boucles, k)
			end
			for _, c in {loin, milieu, proche} do
				c:ClearAllChildren()
			end
			table.clear(orbites)
			tournant = nil
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
		if not connexion then
			connexion = RunService.RenderStepped:Connect(image)
		end
		for _, g in grains do
			if not g.vivant then
				g.vivant = true
				task.delay(math.random() * (if g.etincelle then 2.5 else 4), cycle, g)
			end
		end
	end

	local function arreter()
		actif = false
		if connexion then
			connexion:Disconnect()
			connexion = nil
		end
	end

	return {demarrer = demarrer, arreter = arreter}
end

return DecorPioches
