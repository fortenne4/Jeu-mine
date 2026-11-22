--!strict
-- Décor d'arrière-plan du comptoir de Gaspard (StarterPlayerScripts › Jeu › DecorMarchand).
-- Ambiance trésor : rayons dorés, tas de minerais du jeu (vrais modèles) à gauche, pyramide de lingots d'or à droite,
-- monceau de pépites et de pièces au centre, cristaux lumineux, gros minerai d'or qui tourne lentement,
-- poussière d'or qui monte et reflets en étoile qui scintillent sur le trésor.
-- Construit une seule fois (socle DecorCommun) ; tout s'arrête fenêtre fermée.
--   local decor = require(script.Parent.DecorMarchand).creer(interieur, boucles)
--   decor.demarrer() -- à l'ouverture ; decor.arreter() -- à la fermeture

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MineraisModeles = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MineraisModeles"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local D = require(script.Parent:WaitForChild("DecorCommun"))

local creer = UI.creer
local bloc, cylindre, halo, rayon = D.bloc, D.cylindre, D.halo, D.rayon
local BLANC = D.BLANC

local DecorMarchand = {}

local OR = Color3.fromRGB(255, 196, 48)
local OR_FONCE = Color3.fromRGB(214, 140, 28)
local CYAN = Color3.fromRGB(120, 210, 255)
local VIOLET = Color3.fromRGB(180, 110, 255)

-- Tas de minerais : copies des vrais rochers du jeu, posés en pyramide
local function tasMinerais(noms: {string}): Model?
	local m = Instance.new("Model")
	local places = {Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0.1), Vector3.new(0, 0, -0.9), Vector3.new(0, 0.75, -0.2)}
	local n = 0
	for i, nom in noms do
		local copie = D.copie(Icones.minerai(nom, nil, {vitesse = 0}))
		if copie then
			local t = copie:GetExtentsSize()
			local s = math.max(t.X, t.Z) * 0.62
			local p = places[i] or Vector3.zero
			copie:PivotTo(CFrame.new(p.X * s, p.Y * t.Y, p.Z * s) * CFrame.Angles(0, i * 1.3, 0))
			copie.Parent = m
			n += 1
		end
	end
	return if n > 0 then m else nil
end

-- Pyramide de lingots d'or (vrai lingot du jeu) : 3 / 2 / 1, rangées croisées
local function pyramideLingots(): Model?
	local base = D.copie(Icones.lingot(OR, nil, {vitesse = 0}))
	if not base then
		return nil
	end
	local h = base:GetExtentsSize().Y
	local m = Instance.new("Model")
	local places = {CFrame.new(0, 0, -1.4), CFrame.new(0, 0, 0), CFrame.new(0, 0, 1.4),
		CFrame.new(-0.7, h, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(0.7, h, 0) * CFrame.Angles(0, math.pi / 2, 0),
		CFrame.new(0, h * 2, 0) * CFrame.Angles(0, 0.06, 0)}
	for i, cf in places do
		local l = if i == #places then base else base:Clone()
		l:PivotTo(cf)
		l.Parent = m
	end
	return m
end

-- Monceau de pépites d'or, de pièces et de quelques gemmes (construit une fois, graine fixe)
local function monceau(): Model
	local m = Instance.new("Model")
	local rng = Random.new(77)
	for _ = 1, 34 do
		local r = math.sqrt(rng:NextNumber()) * 2.8
		local a = rng:NextNumber() * math.pi * 2
		local y = (1 - r / 3) * 1.5 + rng:NextNumber() * 0.25
		local s = rng:NextNumber(0.35, 0.7)
		bloc(m, Vector3.new(s, s * rng:NextNumber(0.6, 0.9), s * rng:NextNumber(0.7, 1)),
			CFrame.new(math.cos(a) * r, y, math.sin(a) * r * 0.7) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
			OR:Lerp(OR_FONCE, rng:NextNumber()), if rng:NextNumber() < 0.5 then Enum.Material.Foil else Enum.Material.Metal)
	end
	for _ = 1, 12 do -- pièces : disques posés de travers sur le tas
		local r = math.sqrt(rng:NextNumber()) * 2.6
		local a = rng:NextNumber() * math.pi * 2
		local y = (1 - r / 3) * 1.5 + 0.35
		local cf = CFrame.new(math.cos(a) * r, y, math.sin(a) * r * 0.7) * CFrame.Angles(0, rng:NextNumber(0, 6), math.pi / 2 + rng:NextNumber(-0.5, 0.5))
		cylindre(m, 0.14, 0.85, cf, OR, Enum.Material.Metal).Reflectance = 0.3
		cylindre(m, 0.16, 0.5, cf, OR_FONCE, Enum.Material.Metal)
	end
	for i, c in {CYAN, VIOLET, Color3.fromRGB(110, 255, 160)} do -- gemmes
		local a = i * 2.1
		bloc(m, Vector3.new(0.4, 0.62, 0.4), CFrame.new(math.cos(a) * 1.2, 1.35, math.sin(a) * 0.8) * CFrame.Angles(0.3, a, 0.4), c, Enum.Material.Neon)
	end
	return m
end

function DecorMarchand.creer(interieur: Frame, boucles: {Tween}): D.Decor
	local function construire(c: D.Contexte)
		-- Lointain : rayons dorés venant d'en haut, grand halo doré au centre, lueurs froides des cristaux sur les côtés
		for i, r in {{0.18, 0.08, 18}, {0.36, 0.05, 14}, {0.54, 0.1, 10}, {0.72, 0.05, 16}, {0.88, 0.08, 12}} do
			local ray = rayon(c.loin, r[1], r[2], r[3], Color3.fromRGB(255, 220, 130))
			c.onde(ray, 5.2 + i * 1.2, {Rotation = r[3] - 7})
		end
		c.respire(halo(c.loin, UDim2.fromScale(0.5, 0.95), 1.1, OR, 0.07), 3.6, 0.94, 1.06)
		c.respire(halo(c.loin, UDim2.fromScale(0.1, 0.78), 0.85, Color3.fromRGB(255, 150, 60), 0.065), 3.9, 0.94, 1.07)
		c.respire(halo(c.loin, UDim2.fromScale(0.9, 0.74), 0.85, OR, 0.065), 4.3, 0.95, 1.06)

		-- Milieu : tas de minerais (gauche), pyramide de lingots (droite), monceau d'or (centre bas)
		local tas = tasMinerais({"Charbon", "Bronze", "Fer", "Bronze"})
		if tas then
			D.vue3D(c.milieu, UDim2.fromScale(0.1, 0.8), 0.5, tas, {angle = 0.4, hauteur = 0.3, marge = 0.82,
				ambiant = Color3.fromRGB(120, 108, 100), lumiere = Color3.fromRGB(255, 226, 190), transparence = 0.12})
		end
		local lingots = pyramideLingots()
		if lingots then
			D.vue3D(c.milieu, UDim2.fromScale(0.9, 0.79), 0.46, lingots, {angle = -0.55, hauteur = 0.32, marge = 0.82,
				ambiant = Color3.fromRGB(130, 110, 90), lumiere = Color3.fromRGB(255, 232, 190), transparence = 0.1})
		end
		local tresor = D.vue3D(c.milieu, UDim2.fromScale(0.5, 0.93), 0.5, monceau(), {angle = 0.3, hauteur = 0.38, marge = 0.78,
			ambiant = Color3.fromRGB(130, 108, 84), lumiere = Color3.fromRGB(255, 236, 196), transparence = 0.12})
		c.chaqueImage(function(dt: number) -- le monceau tourne très lentement : les reflets glissent sur l'or
			tresor.angle += dt * 0.12
			D.placerOrbite(tresor)
		end)

		-- Proche : cristaux du jeu en haut des côtés, gros minerai d'or qui tourne (devant les lingots)
		c.respire(halo(c.proche, UDim2.fromScale(0.035, 0.36), 0.6, CYAN, 0.085), 2.9, 0.88, 1.1)
		c.respire(halo(c.proche, UDim2.fromScale(0.975, 0.32), 0.56, VIOLET, 0.085), 3.3, 0.9, 1.08)
		D.vpCristal(c.proche, UDim2.fromScale(0.035, 0.36), 0.32, CYAN, 21, 0.9)
		D.vpCristal(c.proche, UDim2.fromScale(0.975, 0.32), 0.3, VIOLET, 5, 2.4)
		local lueur = MineraisModeles.VISUEL.Gold
		if lueur then
			c.respire(halo(c.proche, UDim2.fromScale(0.955, 0.93), 0.5, lueur.cristal, 0.09), 2.6, 0.9, 1.08)
		end
		local vpOr = Icones.minerai("Gold", creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.955, 0.93),
			Size = UDim2.fromScale(0.26, 0.26), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
			Parent = c.proche}), {vitesse = 0.25, marge = 0.85, hauteur = 0.35, angle = 1.2})
		vpOr.ImageTransparency = 0.12
		vpOr.ImageColor3 = Color3.fromRGB(230, 220, 205)
	end

	-- Zones du trésor (pour les reflets) : tas, lingots, monceau
	local zones = {{0.04, 0.16, 0.7, 0.9}, {0.84, 0.97, 0.68, 0.9}, {0.4, 0.6, 0.84, 0.98}}
	return D.monter(interieur, boucles, {
		nom = "DecorMarchand",
		construire = construire,
		grains = {
			-- poussière d'or : monte doucement de partout
			{nombre = 14, taille = {0.0025, 0.005}, duree = {5, 9}, opacite = {0.1, 0.4},
				couleur = function()
					return Color3.fromRGB(255, math.random(200, 235), math.random(90, 150))
				end,
				depart = function()
					return math.random(), 0.3 + math.random() * 0.7
				end,
				arrivee = function(x, y)
					return x + (math.random() - 0.5) * 0.1, y - 0.12 - math.random() * 0.2
				end, pause = 3},
			-- reflets en étoile sur le trésor
			{nombre = 7, forme = "etoile", taille = {0.018, 0.03}, duree = {0.9, 1.5}, opacite = {0.6, 1},
				couleur = function()
					return Color3.fromRGB(255, 240, 190)
				end,
				depart = function()
					local z = zones[math.random(#zones)]
					return z[1] + math.random() * (z[2] - z[1]), z[3] + math.random() * (z[4] - z[3])
				end,
				arrivee = function(x, y)
					return x, y - 0.01
				end, pause = 4},
			-- quelques éclats bleutés (cristaux)
			{nombre = 3, forme = "etoile", taille = {0.014, 0.022}, duree = {1, 1.6}, opacite = {0.5, 0.9},
				couleur = function()
					return CYAN:Lerp(BLANC, 0.3)
				end,
				depart = function()
					if math.random() < 0.5 then
						return 0.02 + math.random() * 0.05, 0.25 + math.random() * 0.15
					end
					return 0.95 + math.random() * 0.04, 0.22 + math.random() * 0.15
				end,
				arrivee = function(x, y)
					return x, y
				end, pause = 5},
		},
	})
end

return DecorMarchand
