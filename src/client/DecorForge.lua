--!strict
-- Décor d'arrière-plan de la forge de Brom (StarterPlayerScripts › Jeu › DecorForge).
-- Second plan, derrière les onglets et l'aperçu : grande enclume 3D sur son billot (pièce chauffée au rouge dessus),
-- marteau qui se lève et frappe de temps en temps (gerbe d'étincelles + éclair de chaleur à l'impact), foyer rougeoyant,
-- lingots chauffés (vrai modèle du jeu), épée en contre-jour, rayons de feu, braises et éclats de magma qui s'envolent.
-- Construit une seule fois (socle DecorCommun) ; tout s'arrête fenêtre fermée.
--   local decor = require(script.Parent.DecorForge).creer(interieur, boucles)
--   decor.demarrer() -- à l'ouverture ; decor.arreter() -- à la fermeture

local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local D = require(script.Parent:WaitForChild("DecorCommun"))

local creer, coin = UI.creer, UI.coin
local bloc, cylindre, halo, rayon = D.bloc, D.cylindre, D.halo, D.rayon
local BLANC = D.BLANC

local DecorForge = {}

local FER = Color3.fromRGB(62, 64, 72)
local ACIER = Color3.fromRGB(128, 132, 144)
local BOIS = Color3.fromRGB(96, 62, 38)
local MET, BOIS_MAT = Enum.Material.Metal, Enum.Material.Wood
local FEU = Color3.fromRGB(255, 132, 44)

-- Enclume sur billot cerclé de fer, bigorne à gauche (cylindres qui s'affinent), pièce chauffée au rouge sur la table
local function enclume(): Model
	local m = Instance.new("Model")
	cylindre(m, 2.2, 3.3, CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2), BOIS, BOIS_MAT)
	cylindre(m, 0.12, 3.18, CFrame.new(0, 2.24, 0) * CFrame.Angles(0, 0, math.pi / 2), BOIS:Lerp(BLANC, 0.18), BOIS_MAT)
	for _, y in {0.35, 1.75} do
		cylindre(m, 0.22, 3.42, CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), FER, MET)
	end
	bloc(m, Vector3.new(2.7, 0.45, 1.9), CFrame.new(0, 2.5, 0), FER, MET) -- pattes
	bloc(m, Vector3.new(1.9, 0.5, 1.5), CFrame.new(0, 2.95, 0), FER:Lerp(BLANC, 0.04), MET)
	bloc(m, Vector3.new(1.2, 0.6, 1.1), CFrame.new(0, 3.5, 0), FER, MET) -- taille
	bloc(m, Vector3.new(3.9, 0.9, 1.55), CFrame.new(0, 4.25, 0), FER:Lerp(BLANC, 0.06), MET) -- table
	bloc(m, Vector3.new(3.7, 0.08, 1.4), CFrame.new(0, 4.73, 0), ACIER, MET) -- face polie
	bloc(m, Vector3.new(0.9, 0.7, 1.2), CFrame.new(2.35, 4.35, 0), FER, MET) -- talon
	bloc(m, Vector3.new(0.22, 0.04, 0.22), CFrame.new(1.4, 4.78, 0.2), Color3.fromRGB(16, 14, 14), MET) -- trou carré
	for i, d in {0.86, 0.66, 0.46, 0.26} do -- bigorne
		cylindre(m, 0.62, d, CFrame.new(-2.2 - (i - 1) * 0.55, 4.7 - d / 2, 0), FER:Lerp(BLANC, 0.03 * i), MET)
	end
	-- pièce chauffée : barre orange, bout presque blanc
	bloc(m, Vector3.new(1.9, 0.2, 0.36), CFrame.new(0.15, 4.88, 0.1) * CFrame.Angles(0, 0.18, 0), Color3.fromRGB(255, 118, 34), Enum.Material.Neon)
	bloc(m, Vector3.new(0.5, 0.22, 0.38), CFrame.new(-0.75, 4.88, 0.27) * CFrame.Angles(0, 0.18, 0), Color3.fromRGB(255, 214, 140), Enum.Material.Neon)
	-- tenailles posées contre le billot
	bloc(m, Vector3.new(0.14, 2.6, 0.14), CFrame.new(1.75, 1.3, 1.3) * CFrame.Angles(0, 0, -0.22), FER, MET)
	bloc(m, Vector3.new(0.14, 2.6, 0.14), CFrame.new(1.9, 1.3, 1.25) * CFrame.Angles(0, 0, -0.32), FER, MET)
	return m
end

-- Marteau : la main (bout du manche) est à l'origine, la tête en haut (+Y) ; face de frappe côté -X
local function marteau(): Model
	local m = Instance.new("Model")
	bloc(m, Vector3.new(0.26, 2.9, 0.26), CFrame.new(0, 1.55, 0), Color3.fromRGB(110, 72, 42), BOIS_MAT)
	bloc(m, Vector3.new(0.32, 0.9, 0.32), CFrame.new(0, 0.5, 0), Color3.fromRGB(62, 38, 24), Enum.Material.Fabric) -- poignée
	bloc(m, Vector3.new(1.3, 0.68, 0.68), CFrame.new(0, 3.1, 0), FER, MET)
	bloc(m, Vector3.new(0.16, 0.74, 0.74), CFrame.new(-0.72, 3.1, 0), ACIER, MET) -- face de frappe
	bloc(m, Vector3.new(0.5, 0.36, 0.56), CFrame.new(0.85, 3.1, 0), FER:Lerp(BLANC, 0.05), MET) -- panne
	bloc(m, Vector3.new(0.3, 0.12, 0.72), CFrame.new(0, 3.48, 0), ACIER, MET) -- coin de fixation
	return m
end

-- Lingots chauffés : vrai lingot du jeu (IconesObjets), recoloré « sorti du feu », empilés par trois
local function lingotsChauds(): Model?
	local base = D.copie(Icones.lingot(Color3.fromRGB(230, 96, 34), nil, {vitesse = 0}))
	if not base then
		return nil
	end
	for _, p in base:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Material == Enum.Material.Foil then
				p.Color, p.Material = Color3.fromRGB(255, 214, 130), Enum.Material.Neon
			else
				p.Color = p.Color:Lerp(Color3.fromRGB(255, 90, 20), 0.4)
			end
		end
	end
	local m = Instance.new("Model")
	for i, cf in {CFrame.new(-1.35, 0, 0), CFrame.new(1.35, 0, 0.1) * CFrame.Angles(0, 0.08, 0), CFrame.new(0, 0.95, 0) * CFrame.Angles(0, -0.1, 0)} do
		local l = if i == 3 then base else base:Clone()
		l:PivotTo(cf)
		l.Parent = m
	end
	return m
end

function DecorForge.creer(interieur: Frame, boucles: {Tween}): D.Decor
	local function construire(c: D.Contexte)
		-- Lointain : rayons de feu venant d'en haut à gauche, foyer rouge à gauche, chaleur derrière l'enclume
		for i, r in {{0.12, 0.1, -26}, {0.26, 0.06, -20}, {0.44, 0.08, -14}, {0.7, 0.05, -18}, {0.86, 0.09, -24}} do
			local ray = rayon(c.loin, r[1], r[2], r[3], Color3.fromRGB(255, 170, 90))
			c.onde(ray, 4.6 + i * 1.1, {Rotation = r[3] + 6})
		end
		c.respire(halo(c.loin, UDim2.fromScale(0.08, 0.86), 1.15, Color3.fromRGB(255, 70, 20), 0.08), 2.2, 0.9, 1.08)
		c.respire(halo(c.loin, UDim2.fromScale(0.5, 0.74), 1.05, FEU, 0.06), 3.1, 0.94, 1.05)

		-- Milieu : épée du jeu en contre-jour à droite (ne gâche rien : silhouette noire)
		local cadreEpee = creer("Frame", {Name = "Epee", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.93, 0.5),
			Size = UDim2.fromScale(1.0, 1.0), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, Parent = c.milieu})
		local vpEpee = Icones.epee("EpeeFer", cadreEpee, {silhouette = true, vitesse = 0, marge = 0.8, hauteur = 0.04})
		vpEpee.ImageTransparency = 0.3
		D.profil(vpEpee, 28)

		-- Grande enclume (centre bas) et pièce chauffée qui rougeoie
		local ENCLUME_X, ENCLUME_Y, ENCLUME_T = 0.47, 0.8, 0.62
		local vEnclume = D.vue3D(c.milieu, UDim2.fromScale(ENCLUME_X, ENCLUME_Y), ENCLUME_T, enclume(), {angle = 0.22, hauteur = 0.2, marge = 0.8,
			ambiant = Color3.fromRGB(96, 74, 62), lumiere = Color3.fromRGB(255, 190, 130), transparence = 0.08})
		-- Point d'impact (face de l'enclume), en échelle de l'intérieur
		local IMPACT = Vector2.new(0.51, 0.6)
		local chaleur = halo(c.milieu, UDim2.fromScale(IMPACT.X, IMPACT.Y), 0.22, FEU, 0.1)
		c.respire(chaleur, 1.4, 0.85, 1.12)

		-- Marteau : la main est au centre de sa vue ; le roulis de la caméra fait pivoter le marteau autour de la main
		local REPOS, LEVE, FRAPPE = -88, 16, -106 -- roulis (degrés) : posé, levé, à l'impact
		local main = Vector2.new(0.725, 0.5)
		local vMarteau = D.vue3D(c.milieu, UDim2.fromScale(main.X, main.Y), 0.85, marteau(), {centre = Vector3.zero, rayon = 3.5, marge = 1,
			hauteur = 0, angle = 0, ambiant = Color3.fromRGB(90, 72, 64), lumiere = Color3.fromRGB(255, 196, 140), transparence = 0.1})
		vMarteau.roulis = REPOS
		D.placerOrbite(vMarteau)
		local roulis = Instance.new("NumberValue")
		roulis.Value = REPOS
		roulis.Parent = vMarteau.vp
		roulis.Changed:Connect(function(v: number)
			vMarteau.roulis = v
			D.placerOrbite(vMarteau)
		end)

		-- Gauche : lingots chauffés près du foyer
		local lingots = lingotsChauds()
		if lingots then
			c.respire(halo(c.proche, UDim2.fromScale(0.075, 0.9), 0.5, Color3.fromRGB(255, 110, 30), 0.09), 1.9, 0.88, 1.1)
			D.vue3D(c.proche, UDim2.fromScale(0.075, 0.9), 0.3, lingots, {angle = 0.5, hauteur = 0.35, marge = 0.85,
				ambiant = Color3.fromRGB(120, 80, 60), lumiere = Color3.fromRGB(255, 200, 150), transparence = 0.1})
		end

		-- Devant (au-dessus du voile) : éclair de chaleur et gerbe d'étincelles à chaque coup
		local eclair = creer("CanvasGroup", {Name = "Eclair", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(IMPACT.X, IMPACT.Y),
			Size = UDim2.fromScale(0.36, 0.36), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
			GroupTransparency = 1, Parent = c.devant})
		local h = halo(eclair, UDim2.fromScale(0.5, 0.5), 1, Color3.fromRGB(255, 190, 90), 0.2)
		h.Size = UDim2.fromScale(1, 1)
		local echelleEclair = UI.echelle(eclair)

		local etincelles: {{f: Frame}} = {}
		for _ = 1, 16 do
			local f = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.012, 0.0028),
				SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, BackgroundColor3 = BLANC, Visible = false,
				Parent = c.devant}, {coin(0.5), creer("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255, 120, 30),
				Color3.fromRGB(255, 244, 200)), Transparency = NumberSequence.new({D.kp(0, 1), D.kp(0.5, 0.3), D.kp(1, 0)})})})
			table.insert(etincelles, {f = f})
		end

		local function impact()
			local taille = interieur.AbsoluteSize
			local ratio = if taille.Y > 1 then taille.X / taille.Y else 1.65
			echelleEclair.Scale = 0.6
			eclair.GroupTransparency = 0.05
			TweenService:Create(echelleEclair, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.25}):Play()
			TweenService:Create(eclair, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1}):Play()
			for _, e in etincelles do
				local f = e.f
				local a = math.rad(math.random(-172, -8)) -- vers le haut, en éventail
				local d = 0.05 + math.random() * 0.13 -- distance en hauteur d'intérieur
				local dx, dy = math.cos(a) * d / ratio, math.sin(a) * d
				local duree = 0.35 + math.random() * 0.45
				f.Position = UDim2.fromScale(IMPACT.X, IMPACT.Y)
				f.Rotation = math.deg(a) -- la traînée suit sa direction
				f.BackgroundTransparency = 0
				f.Size = UDim2.fromScale(0.008 + math.random() * 0.01, 0.0026)
				f.Visible = true
				TweenService:Create(f, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Position = UDim2.fromScale(IMPACT.X + dx, IMPACT.Y + dy + d * 0.25), Size = UDim2.fromScale(0.003, 0.002)}):Play()
				TweenService:Create(f, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
			end
			-- l'enclume encaisse : petit tassement
			local e = UI.echelle(vEnclume.vp)
			e.Scale = 0.985
			TweenService:Create(e, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end

		-- Le coup : on lève (anticipation), on abat vite, rebond, puis on repose le marteau
		c.cadence(function()
			local function vers(v: number, duree: number, style: Enum.EasingStyle, sens: Enum.EasingDirection)
				TweenService:Create(roulis, TweenInfo.new(duree, style, sens), {Value = v}):Play()
				task.wait(duree)
			end
			vers(LEVE, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.12)
			vers(FRAPPE, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			impact()
			vers(FRAPPE + 16, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			vers(REPOS, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end, 1.6, 3.2)
	end

	local function couleurBraise(): Color3
		return Color3.fromRGB(255, math.random(120, 210), math.random(30, 80))
	end
	return D.monter(interieur, boucles, {
		nom = "DecorForge",
		construire = construire,
		grains = {
			-- braises : petites, montent du bas en ondulant
			{nombre = 16, taille = {0.0025, 0.0045}, duree = {2.6, 4.6}, opacite = {0, 0.25}, couleur = couleurBraise,
				depart = function()
					return math.random(), 0.85 + math.random() * 0.2
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.5) * 0.12, y - 0.35 - math.random() * 0.4
				end, pause = 2.5},
			-- éclats de magma : plus gros, jaillissent du foyer (bas gauche) et de l'enclume, en tournant
			{nombre = 7, forme = "magma", taille = {0.006, 0.011}, duree = {1.8, 3.2}, opacite = {0, 0.1}, tourne = 300,
				couleur = function()
					return Color3.fromRGB(255, math.random(90, 150), 20)
				end,
				depart = function()
					if math.random() < 0.5 then
						return 0.04 + math.random() * 0.14, 0.95
					end
					return 0.44 + math.random() * 0.14, 0.68
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.3) * 0.18, y - 0.25 - math.random() * 0.3
				end, pause = 3, style = Enum.EasingStyle.Quad, sens = Enum.EasingDirection.Out},
			-- cendres : grises, lentes, dans tous les sens
			{nombre = 8, taille = {0.003, 0.006}, duree = {6, 10}, opacite = {0.55, 0.75},
				couleur = function()
					return Color3.fromRGB(150, 136, 124)
				end,
				depart = function()
					return math.random(), 0.1 + math.random() * 0.8
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.5) * 0.12, y - 0.05 - math.random() * 0.1
				end, pause = 4},
		},
	})
end

return DecorForge
