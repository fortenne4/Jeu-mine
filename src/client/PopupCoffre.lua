--!strict
-- Pop-up d'ouverture de coffre / trésor (StarterPlayerScripts › Jeu › PopupCoffre).
-- Un vrai coffre 3D (Parts en ViewportFrame : planches, ferrures, serrure à gemme, trésor) tremble, son couvercle bascule, un faisceau doré
-- jaillit, des rayons tournent derrière, des étincelles éclatent ; le titre s'écrase comme un tampon puis les
-- récompenses sortent du coffre une à une en cartes (pièce dessinée / vrai minerai 3D en ViewportFrame) avec un
-- compteur qui monte. Bouton « Récupérer » (souris, tactile, manette A, Entrée, B) + fermeture auto après 6 s.
-- Si un coffre arrive pendant qu'un autre est affiché : il est mis en file et s'affiche juste après.
--   local PopupCoffre = require(script.Parent:WaitForChild("PopupCoffre"))
--   PopupCoffre.afficher({titre = "Coffre de l'Abîme", theme = "Abime",
--       recompenses = {{genre = "pieces", n = 80}, {genre = "minerai", id = "Gold", n = 2}}})
-- Interface construite une seule fois (au premier coffre), puis réutilisée ; seules les cartes sont recréées.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))
local Partage = ReplicatedStorage:WaitForChild("Partage")
local Pioches = require(Partage:WaitForChild("Pioches"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))

local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

export type Recompense = {genre: string, n: number?, id: string?, nom: string?}
export type Options = {titre: string?, theme: string?, sousTitre: string?, recompenses: {Recompense}?}

local PopupCoffre = {}

local DUREE_AUTO = 6 -- secondes avant fermeture automatique (après la dernière carte)
local NOMS_MINERAIS = {Charbon = "Charbon", Bronze = "Bronze", Fer = "Fer", Gold = "Or"}

type Theme = {accent: Color3, lueur: Color3, fond: Color3, sous: string}
local THEMES: {[string]: Theme} = {
	Abime = {accent = Color3.fromRGB(150, 110, 255), lueur = Color3.fromRGB(255, 214, 120), fond = Color3.fromRGB(34, 18, 70),
		sous = "Remonté des profondeurs de l'Abîme"},
	Sanctuaire = {accent = Color3.fromRGB(80, 230, 255), lueur = Color3.fromRGB(200, 248, 255), fond = Color3.fromRGB(8, 46, 66),
		sous = "Les gardiens sont vaincus"},
	Fonderie = {accent = Color3.fromRGB(255, 130, 40), lueur = Color3.fromRGB(255, 196, 96), fond = Color3.fromRGB(78, 24, 6),
		sous = "Le creuset royal a parlé"},
	Defaut = {accent = T.Or, lueur = Color3.fromRGB(255, 220, 120), fond = Color3.fromRGB(56, 36, 10), sous = "Trésor découvert !"},
}

local OR_CLAIR, OR_MOY, OR_FONCE = Color3.fromRGB(255, 242, 176), Color3.fromRGB(240, 178, 58), Color3.fromRGB(146, 86, 22)
local CONTOUR = Color3.fromRGB(34, 16, 6)
local BLANC = Color3.new(1, 1, 1)

local function tw(o: Instance, info: TweenInfo, props: {[string]: any}): Tween
	local t = TweenService:Create(o, info, props)
	t:Play()
	return t
end
local function ti(d: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?, rep: number?, rev: boolean?, delai: number?): TweenInfo
	return TweenInfo.new(d, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false, delai or 0)
end

-- Dégradé à trois teintes (la couleur de fond reste blanche : le dégradé porte les couleurs)
local function teintes(o: GuiObject, c0: Color3, c1: Color3, c2: Color3, rot: number?): UIGradient
	local obj: any = o
	obj.BackgroundColor3 = BLANC
	return creer("UIGradient", {Rotation = rot or 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c0),
		ColorSequenceKeypoint.new(0.5, c1), ColorSequenceKeypoint.new(1, c2)}), Parent = o})
end
-- ================= Coffre 3D (Parts dans un ViewportFrame) =================
-- Construit une fois par thème (gabarit), puis cloné à chaque pop-up. Repère : base du coffre en (0,0,0), face avant vers +Z,
-- charnière du couvercle sur l'arête arrière du haut (axe X).
type Theme3D = {bois: Color3, boisMat: Enum.Material, fer: Color3, ferMat: Enum.Material, garn: Color3, garnMat: Enum.Material,
	gemme: Color3, lueur: Color3, piece: Color3, ambiant: Color3, lumiere: Color3}
local THEMES3D: {[string]: Theme3D} = {
	Abime = {bois = Color3.fromRGB(58, 40, 38), boisMat = Enum.Material.WoodPlanks, fer = Color3.fromRGB(42, 40, 48), ferMat = Enum.Material.Metal,
		garn = Color3.fromRGB(238, 180, 64), garnMat = Enum.Material.Foil, gemme = Color3.fromRGB(170, 110, 255), lueur = Color3.fromRGB(255, 150, 60),
		piece = Color3.fromRGB(246, 190, 70), ambiant = Color3.fromRGB(150, 110, 125), lumiere = Color3.fromRGB(255, 196, 150)},
	Sanctuaire = {bois = Color3.fromRGB(206, 188, 152), boisMat = Enum.Material.Wood, fer = Color3.fromRGB(168, 172, 170), ferMat = Enum.Material.Slate,
		garn = Color3.fromRGB(214, 226, 238), garnMat = Enum.Material.Metal, gemme = Color3.fromRGB(80, 230, 255), lueur = Color3.fromRGB(150, 245, 255),
		piece = Color3.fromRGB(240, 210, 120), ambiant = Color3.fromRGB(130, 150, 165), lumiere = Color3.fromRGB(232, 246, 255)},
	Fonderie = {bois = Color3.fromRGB(86, 50, 34), boisMat = Enum.Material.WoodPlanks, fer = Color3.fromRGB(56, 54, 56), ferMat = Enum.Material.CorrodedMetal,
		garn = Color3.fromRGB(206, 114, 62), garnMat = Enum.Material.Metal, gemme = Color3.fromRGB(255, 120, 40), lueur = Color3.fromRGB(255, 162, 60),
		piece = Color3.fromRGB(248, 186, 70), ambiant = Color3.fromRGB(165, 110, 90), lumiere = Color3.fromRGB(255, 208, 165)},
	Defaut = {bois = Color3.fromRGB(150, 96, 54), boisMat = Enum.Material.WoodPlanks, fer = Color3.fromRGB(70, 64, 60), ferMat = Enum.Material.Metal,
		garn = Color3.fromRGB(240, 182, 62), garnMat = Enum.Material.Foil, gemme = Color3.fromRGB(235, 55, 70), lueur = Color3.fromRGB(255, 214, 110),
		piece = Color3.fromRGB(246, 194, 72), ambiant = Color3.fromRGB(150, 120, 95), lumiere = Color3.fromRGB(255, 232, 195)},
}
local LARG, PROF, HAUT, RAYON, EP = 4, 2.6, 1.9, 1.3, 0.18
local CHARNIERE = CFrame.new(0, HAUT, -PROF / 2)
local NOIR = Color3.new(0, 0, 0)
local DIR_LUMIERE = Vector3.new(0.6, -1, -0.8).Unit -- repère caméra : vient d'en haut à gauche

local function bloc(parent: Instance, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, forme: Enum.PartType?, transp: number?): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if forme then
		p.Shape = forme
	end
	p.Size, p.CFrame, p.Color, p.Material, p.Transparency = taille, cf, couleur, mat, transp or 0
	p.Parent = parent
	return p
end
local function rivet(parent: Instance, pos: Vector3, th: Theme3D)
	bloc(parent, Vector3.new(0.12, 0.12, 0.12), CFrame.new(pos), th.garn:Lerp(BLANC, 0.15), th.garnMat, Enum.PartType.Ball)
end

local gabarits: {[string]: Model} = {}
local function gabarit(nomTheme: string): Model
	local deja = gabarits[nomTheme]
	if deja then
		return deja
	end
	local th = THEMES3D[nomTheme] or THEMES3D.Defaut
	local scene = Instance.new("Model")
	scene.Name = "Scene"
	local m = Instance.new("Model")
	m.Name = "Coffre"
	m.Parent = scene
	local W, D, H = LARG, PROF, HAUT
	local sombre = th.bois:Lerp(NOIR, 0.55)
	local fonce = Color3.fromRGB(14, 8, 4)
	-- ombre au sol
	bloc(scene, Vector3.new(0.04, 5.6, 5.6), CFrame.new(0, -0.24, 0) * CFrame.Angles(0, 0, math.rad(90)), NOIR, Enum.Material.SmoothPlastic,
		Enum.PartType.Cylinder, 0.55).Name = "Ombre"

	-- caisse : fond + 4 parois en planches (teintes alternées, joints sombres)
	bloc(m, Vector3.new(W, EP, D), CFrame.new(0, EP / 2, 0), sombre, th.boisMat)
	for i = 0, 2 do
		local hp, y = H / 3, (i + 0.5) * H / 3
		local c = if i == 1 then th.bois:Lerp(BLANC, 0.06) else th.bois:Lerp(NOIR, 0.05 + i * 0.03)
		for _, z in {D / 2 - EP / 2, -D / 2 + EP / 2} do
			bloc(m, Vector3.new(W, hp, EP), CFrame.new(0, y, z), c, th.boisMat)
		end
		for _, x in {W / 2 - EP / 2, -W / 2 + EP / 2} do
			bloc(m, Vector3.new(EP, hp, D - 2 * EP), CFrame.new(x, y, 0), c:Lerp(NOIR, 0.12), th.boisMat)
		end
		if i > 0 then
			bloc(m, Vector3.new(W + 0.01, 0.04, D + 0.01), CFrame.new(0, i * H / 3, 0), sombre:Lerp(NOIR, 0.4), Enum.Material.SmoothPlastic)
		end
	end
	-- trésor : lit d'or, monticule, pièces, gemmes, nappe de lumière
	local fondInt = W - 2 * EP - 0.04
	bloc(m, Vector3.new(fondInt, 1.1, D - 2 * EP - 0.04), CFrame.new(0, H - 0.75, 0), th.piece:Lerp(NOIR, 0.25), Enum.Material.Metal)
	bloc(m, Vector3.new(2.2, 0.5, 1.4), CFrame.new(0.2, H - 0.12, 0) * CFrame.Angles(0, 0.2, 0), th.piece:Lerp(NOIR, 0.1), Enum.Material.Metal)
	bloc(m, Vector3.new(1.2, 0.5, 0.9), CFrame.new(-0.4, H + 0.12, 0.1) * CFrame.Angles(0, -0.3, 0), th.piece, Enum.Material.Metal)
	local rnd = Random.new(42)
	for _ = 1, 26 do
		local x, z = rnd:NextNumber(-1.6, 1.6), rnd:NextNumber(-0.95, 0.95)
		local bosse = math.max(0, 1 - (x / 1.7) ^ 2 - (z / 1.05) ^ 2)
		bloc(m, Vector3.new(0.1, 0.5, 0.5), CFrame.new(x, H - 0.2 + bosse * 0.55, z)
			* CFrame.Angles(rnd:NextNumber(-0.5, 0.5), rnd:NextNumber(0, 6.28), math.rad(90) + rnd:NextNumber(-0.5, 0.5)),
			th.piece:Lerp(BLANC, rnd:NextNumber(0, 0.25)), Enum.Material.Foil, Enum.PartType.Cylinder)
	end
	local gemmes = {{-1.1, 0.25, th.gemme}, {0.9, -0.3, th.gemme:Lerp(BLANC, 0.3)}, {0.25, 0.45, Color3.fromRGB(70, 220, 120)},
		{-0.35, -0.5, Color3.fromRGB(80, 150, 255)}}
	for k, g in gemmes do
		bloc(m, Vector3.new(0.34, 0.34, 0.34), CFrame.new(g[1] :: number, H + 0.12, g[2] :: number) * CFrame.Angles(0.6, k, 0.78), g[3] :: Color3,
			if k % 2 == 1 then Enum.Material.Neon else Enum.Material.Glass)
	end
	bloc(m, Vector3.new(fondInt - 0.1, 0.04, D - 2 * EP - 0.14), CFrame.new(0, H + 0.02, 0), th.lueur, Enum.Material.Neon, nil, 0.6).Name = "Lueur"

	-- ferrures : bandes verticales, cerclages, coins, pieds, charnières, rivets
	for _, x in {-1.15, 1.15} do
		for _, z in {D / 2 + 0.03, -D / 2 - 0.03} do
			bloc(m, Vector3.new(0.32, H, 0.06), CFrame.new(x, H / 2, z), th.fer, th.ferMat)
			for _, y in {0.35, 0.95, 1.5} do
				rivet(m, Vector3.new(x, y, z + (if z > 0 then 0.04 else -0.04)), th)
			end
		end
		bloc(m, Vector3.new(0.5, 0.2, 0.2), CFrame.new(x, H, -D / 2 - 0.05), th.garn, th.garnMat, Enum.PartType.Cylinder)
	end
	bloc(m, Vector3.new(W + 0.06, 0.18, D + 0.06), CFrame.new(0, 0.14, 0), th.fer, th.ferMat)
	bloc(m, Vector3.new(W + 0.06, 0.18, D + 0.06), CFrame.new(0, H - 0.09, 0), th.garn, th.garnMat)
	for _, x in {-W / 2, W / 2} do
		for _, z in {-D / 2, D / 2} do
			bloc(m, Vector3.new(0.24, H + 0.02, 0.24), CFrame.new(x, H / 2, z), th.garn, th.garnMat)
			bloc(m, Vector3.new(0.38, 0.22, 0.38), CFrame.new(x * 0.95, -0.1, z * 0.92), th.garn:Lerp(NOIR, 0.3), th.garnMat)
			rivet(m, Vector3.new(x, H * 0.55, z + (if z > 0 then 0.13 else -0.13)), th)
		end
	end
	for k = 0, 7 do
		rivet(m, Vector3.new(-1.75 + k * 0.5, H - 0.09, D / 2 + 0.1), th)
	end
	-- serrure ornée : plaque, volutes, trou de serrure, gemme sertie
	local zs = D / 2 + 0.07
	bloc(m, Vector3.new(0.72, 0.82, 0.08), CFrame.new(0, H - 0.52, zs), th.garn, th.garnMat)
	for _, s in {-1, 1} do
		bloc(m, Vector3.new(0.3, 0.3, 0.06), CFrame.new(s * 0.42, H - 0.5, zs) * CFrame.Angles(0, 0, math.rad(45)), th.garn:Lerp(NOIR, 0.2), th.garnMat)
	end
	bloc(m, Vector3.new(0.5, 0.18, 0.05), CFrame.new(0, H - 0.98, zs), th.garn:Lerp(NOIR, 0.2), th.garnMat)
	bloc(m, Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, H - 0.66, zs + 0.03), fonce, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	bloc(m, Vector3.new(0.07, 0.2, 0.04), CFrame.new(0, H - 0.78, zs + 0.04), fonce, Enum.Material.SmoothPlastic)
	bloc(m, Vector3.new(0.3, 0.3, 0.06), CFrame.new(0, H - 0.34, zs + 0.02) * CFrame.Angles(0, 0, math.rad(45)), th.garn:Lerp(BLANC, 0.2), th.garnMat)
	bloc(m, Vector3.new(0.2, 0.2, 0.1), CFrame.new(0, H - 0.34, zs + 0.05) * CFrame.Angles(0, 0, math.rad(45)), th.gemme, Enum.Material.Neon)

	-- couvercle bombé (demi-cylindre de planches), pivot = charnière arrière
	local cv = Instance.new("Model")
	cv.Name = "Couvercle"
	cv.Parent = m
	local N = 7
	local seg = 2 * RAYON * math.sin(math.pi / (2 * N)) * 1.08
	local function surArc(x: number, theta: number, r: number): CFrame
		return CFrame.new(x, H, 0) * CFrame.Angles(math.rad(theta), 0, 0) * CFrame.new(0, r, 0)
	end
	for i = 1, N do
		local theta = -90 + (i - 0.5) * 180 / N
		local c = if i % 2 == 0 then th.bois:Lerp(BLANC, 0.08) else th.bois:Lerp(NOIR, 0.04)
		bloc(cv, Vector3.new(W - 0.04, EP, seg), surArc(0, theta, RAYON - EP / 2), c, th.boisMat)
		if i < N then
			bloc(cv, Vector3.new(W - 0.02, 0.03, 0.05), surArc(0, -90 + i * 180 / N, RAYON + 0.005), sombre:Lerp(NOIR, 0.4), Enum.Material.SmoothPlastic)
		end
		for _, x in {-W / 2 + 0.1, W / 2 - 0.1} do
			bloc(cv, Vector3.new(0.24, 0.07, seg), surArc(x, theta, RAYON + 0.03), th.garn, th.garnMat)
		end
		for _, x in {-1.15, 1.15} do
			bloc(cv, Vector3.new(0.32, 0.06, seg), surArc(x, theta, RAYON + 0.025), th.fer, th.ferMat)
		end
	end
	for _, x in {-W / 2 + EP / 2 + 0.02, W / 2 - EP / 2 - 0.02} do
		-- flanc en escalier (style voxel)
		for k = 0, 5 do
			local ym = (k + 0.5) * RAYON / 6
			local zh = math.sqrt(RAYON * RAYON - ym * ym)
			bloc(cv, Vector3.new(EP, RAYON / 6 + 0.01, 2 * zh), CFrame.new(x, H + ym, 0), th.bois:Lerp(NOIR, 0.12 + (k % 2) * 0.05), th.boisMat)
		end
	end
	for _, x in {-1.15, 1.15} do
		for _, theta in {-50, 0, 50} do
			rivet(cv, surArc(x, theta, RAYON + 0.08).Position, th)
		end
	end
	for _, z in {D / 2 + 0.02, -D / 2 - 0.02} do
		bloc(cv, Vector3.new(W + 0.06, 0.16, 0.08), CFrame.new(0, H + 0.08, z), th.garn, th.garnMat)
	end
	-- moraillon qui retombe sur la serrure
	bloc(cv, Vector3.new(0.3, 0.5, 0.07), CFrame.new(0, H - 0.02, D / 2 + 0.12), th.garn:Lerp(BLANC, 0.1), th.garnMat)
	bloc(cv, Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, H - 0.24, D / 2 + 0.17), th.gemme, Enum.Material.Neon, Enum.PartType.Ball)
	cv.WorldPivot = CHARNIERE
	m.WorldPivot = CFrame.new()
	gabarits[nomTheme] = scene
	return scene
end

-- Scène 3D active (une seule à la fois)
type Volant = {p: BasePart, v: Vector3, w: Vector3, age: number}
type Etat3D = {scene: Model?, coffre: Model?, couvercle: Model?, conn: RBXScriptConnection?, angle: NumberValue, tremble: NumberValue,
	volants: {Volant}, t: number}
local S: Etat3D = {scene = nil, coffre = nil, couvercle = nil, conn = nil, angle = Instance.new("NumberValue"),
	tremble = Instance.new("NumberValue"), volants = {}, t = 0}

local function projeter(cam: Camera, vp: GuiObject, p: Vector3): (number, number)
	local l = cam.CFrame:PointToObjectSpace(p)
	local th = math.tan(math.rad(cam.FieldOfView) / 2)
	local asp = vp.AbsoluteSize.X / math.max(vp.AbsoluteSize.Y, 1)
	local z = math.max(-l.Z, 0.01)
	return 0.5 + (l.X / z) / (th * asp) / 2, 0.5 - (l.Y / z) / th / 2
end

local function arreter3D()
	if S.conn then
		S.conn:Disconnect()
		S.conn = nil
	end
	for _, v in S.volants do
		v.p:Destroy()
	end
	table.clear(S.volants)
	if S.scene then
		S.scene:Destroy()
	end
	S.scene, S.coffre, S.couvercle = nil, nil, nil
	S.angle.Value, S.tremble.Value = 0, 0
end

local CIBLE = Vector3.new(0, 2.0, 0)
local function placerCamera(vp: ViewportFrame, cam: Camera, t: number)
	local a = math.rad(26) + math.sin(t * 0.55) * math.rad(8)
	local h = math.rad(19)
	local cf = CFrame.lookAt(CIBLE + Vector3.new(math.sin(a) * math.cos(h), math.sin(h), math.cos(a) * math.cos(h)) * 11.5, CIBLE)
	cam.CFrame = cf
	vp.LightDirection = cf:VectorToWorldSpace(DIR_LUMIERE)
end

-- Installe le coffre du thème dans le ViewportFrame et lance la boucle d'animation (caméra, flottement, tremblement, couvercle, pièces)
local function demarrer3D(vp: ViewportFrame, monde: WorldModel, cam: Camera, nomTheme: string)
	arreter3D()
	local th = THEMES3D[nomTheme] or THEMES3D.Defaut
	vp.Ambient, vp.LightColor = th.ambiant, th.lumiere
	local scene = gabarit(nomTheme):Clone()
	scene.Parent = monde
	local coffre = scene:FindFirstChild("Coffre") :: Model
	local couvercle = coffre:FindFirstChild("Couvercle") :: Model
	S.scene, S.coffre, S.couvercle, S.t = scene, coffre, couvercle, 0
	local hasard = Random.new()
	S.conn = RunService.RenderStepped:Connect(function(dt)
		S.t += dt
		local t = S.t
		placerCamera(vp, cam, t)
		local tr = S.tremble.Value
		local base = CFrame.new(0, 0.08 * math.sin(t * 2.2), 0)
		if tr > 0 then
			base = base * CFrame.new(hasard:NextNumber(-1, 1) * 0.07 * tr, math.abs(math.sin(t * 31)) * 0.1 * tr, 0)
				* CFrame.Angles(0, 0, math.sin(t * 47) * math.rad(4) * tr)
		end
		coffre:PivotTo(base)
		local ang = S.angle.Value - math.rad(9) * tr * math.abs(math.sin(t * 37))
		couvercle:PivotTo(base * CHARNIERE * CFrame.Angles(ang, 0, 0))
		for i = #S.volants, 1, -1 do
			local v = S.volants[i]
			v.age += dt
			if v.age > 1.5 then
				v.p:Destroy()
				table.remove(S.volants, i)
			else
				v.v += Vector3.new(0, -26 * dt, 0)
				v.p.CFrame = CFrame.new(v.p.Position + v.v * dt) * v.p.CFrame.Rotation * CFrame.Angles(v.w.X * dt, v.w.Y * dt, v.w.Z * dt)
				if v.age > 1.1 then
					v.p.Transparency = (v.age - 1.1) / 0.4
				end
			end
		end
	end)
end

-- Ouverture : pièces et gemmes qui jaillissent + colonne de lumière néon
local function jaillir(nomTheme: string)
	local th = THEMES3D[nomTheme] or THEMES3D.Defaut
	local scene = S.scene
	if not scene then
		return
	end
	local hasard = Random.new()
	for k = 1, 18 do
		local gemme = k % 6 == 0
		local p = if gemme
			then bloc(scene, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, HAUT + 0.3, 0), th.gemme:Lerp(BLANC, hasard:NextNumber(0, 0.3)), Enum.Material.Neon)
			else bloc(scene, Vector3.new(0.1, 0.5, 0.5), CFrame.new(hasard:NextNumber(-1.2, 1.2), HAUT + 0.3, hasard:NextNumber(-0.6, 0.6)),
				th.piece:Lerp(BLANC, hasard:NextNumber(0, 0.3)), Enum.Material.Foil, Enum.PartType.Cylinder)
		table.insert(S.volants, {p = p, v = Vector3.new(hasard:NextNumber(-3.2, 3.2), hasard:NextNumber(8, 12.5), hasard:NextNumber(-1, 3)),
			w = Vector3.new(hasard:NextNumber(-12, 12), hasard:NextNumber(-12, 12), hasard:NextNumber(-12, 12)), age = hasard:NextNumber(0, 0.15)})
	end
	local colonne = bloc(scene, Vector3.new(2, 2.4, 2.4), CFrame.new(0, HAUT + 1, 0) * CFrame.Angles(0, 0, math.rad(90)), th.lueur,
		Enum.Material.Neon, Enum.PartType.Cylinder, 0.2)
	tw(colonne, ti(0.9, Enum.EasingStyle.Quart), {Size = Vector3.new(7, 3.3, 3.3), CFrame = CFrame.new(0, HAUT + 3.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1})
	Debris:AddItem(colonne, 1)
	local lueur = (S.coffre :: Model):FindFirstChild("Lueur") :: BasePart
	tw(lueur, ti(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.25})
end

-- Son d'impact (déjà utilisé par BossOutils) pour le couvercle qui claque
local sonImpact = creer("Sound", {Name = "UI_PopupCoffreImpact", SoundId = "rbxasset://sounds/swordslash.wav", Volume = 0.4, Parent = SoundService})
local function impact(vitesse: number)
	sonImpact.PlaybackSpeed = vitesse * (0.95 + math.random() * 0.1)
	SoundService:PlayLocalSound(sonImpact)
end

-- ================= Construction (une seule fois) =================
type Elements = {
	gui: ScreenGui, voile: TextButton, lueurFond: Frame, racine: Frame, echelle: UIScale, halo: Frame, rayons: CanvasGroup,
	rayonsGrad: {UIGradient}, coffre: Frame, vp: ViewportFrame, camera: Camera, monde: WorldModel, faisceau: Frame, bouche: Frame,
	boucheLueur: Frame, eclats: Frame, titre: TextLabel, titreTrait: UIStroke, titreEchelle: UIScale, sous: TextLabel, plaque: Frame,
	rangee: Frame, bouton: UI.BoutonPrincipal, barre: Frame, barreFond: Frame, boucles: {Tween},
}
local E: Elements? = nil

local function construire(): Elements
	local joueur = Players.LocalPlayer
	local boucles: {Tween} = {}
	local gui = creer("ScreenGui", {Name = "PopupCoffre", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 70, Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})

	-- Voile sombre (bloque les clics vers le monde) + lueur colorée du thème au centre
	local voile = creer("TextButton", {Name = "Voile", Text = "", AutoButtonColor = false, Selectable = false, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Voile, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = gui},
		{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0.05)})})})
	local lueurFond = creer("Frame", {Name = "LueurFond", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(1.2, 1.2), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 2, Parent = gui}, {coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)})})})

	-- Racine carrée centrée (s'adapte du téléphone à l'écran large)
	local racine = creer("Frame", {Name = "Racine", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.94), BackgroundTransparency = 1, ZIndex = 3, Parent = gui},
		{creer("UIAspectRatioConstraint", {AspectRatio = 1}), creer("UISizeConstraint", {MaxSize = Vector2.new(620, 620)})})
	local echelle = UI.echelle(racine)

	-- Halo et rayons tournants derrière le coffre
	local halo = creer("Frame", {Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.62, 0.62), BackgroundColor3 = T.Or, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = racine},
		{coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 1)})})})
	local rayons = creer("CanvasGroup", {Name = "Rayons", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(1.05, 1.05), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 2, Parent = racine})
	local rayonsGrad: {UIGradient} = {}
	for i = 0, 8 do
		local large = i % 2 == 0
		local r = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(if large then 0.09 else 0.045, 1), Rotation = i * 20, BackgroundColor3 = BLANC, BorderSizePixel = 0,
			Parent = rayons})
		table.insert(rayonsGrad, creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, if large then 0.55 else 0.7), NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(0.7, if large then 0.55 else 0.7), NumberSequenceKeypoint.new(1, 1)}), Parent = r}))
	end
	UI.boucle(rayons, ti(16, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
	UI.boucle(halo, ti(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.fromScale(0.7, 0.7)}, boucles)

	-- ===== Le coffre 3D (ViewportFrame + WorldModel) =====
	local coffre = creer("Frame", {Name = "Coffre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.395),
		Size = UDim2.fromScale(0.72, 0.44), BackgroundTransparency = 1, ZIndex = 5, Parent = racine})
	-- faisceau de lumière qui jaillit (par-dessus le coffre 3D)
	local faisceau = creer("Frame", {Name = "Faisceau", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0), BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 3, Parent = coffre},
		{coin(0.4), creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.6, 0.55), NumberSequenceKeypoint.new(1, 0.1)})})})
	local vp = creer("ViewportFrame", {Name = "Coffre3D", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
		Ambient = Color3.fromRGB(150, 120, 95), LightColor = Color3.fromRGB(255, 232, 195), Parent = coffre}) :: ViewportFrame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent = vp
	vp.CurrentCamera = camera
	local monde = Instance.new("WorldModel")
	monde.Parent = vp
	-- ouverture (point d'où sortent les cartes) + halo « bloom » posé sur l'intérieur lumineux
	local bouche = creer("Frame", {Name = "Bouche", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.14), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = coffre})
	local boucheLueur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.7),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = bouche}, {coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1)})})})

	-- couche des étincelles / éclairs (au-dessus de tout)
	local eclats = creer("Frame", {Name = "Eclats", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = racine})

	-- Titre (tampon) + sous-titre
	local titre = texte({Name = "Titre", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.09),
		Size = UDim2.fromScale(0.94, 0.12), Visible = false, ZIndex = 7, Parent = racine}, 64)
	UI.dore(titre, 3)
	local titreTrait = titre:FindFirstChildOfClass("UIStroke") :: UIStroke
	local titreEchelle = UI.echelle(titre)
	local sous = texte({Name = "SousTitre", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.168), Size = UDim2.fromScale(0.8, 0.042), TextTransparency = 1, ZIndex = 7, Parent = racine}, 22)

	-- Plaque des récompenses : bois sombre, bandes de fer rivetées
	local plaque = creer("Frame", {Name = "Plaque", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.735),
		Size = UDim2.fromScale(0.96, 0.25), BorderSizePixel = 0, ZIndex = 8, Parent = racine}, {coin(0.08), trait(CONTOUR, 3)})
	teintes(plaque, Color3.fromRGB(78, 52, 34), Color3.fromRGB(52, 34, 22), Color3.fromRGB(30, 20, 13))
	UI.bandeFer(plaque, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.07), 9)
	UI.bandeFer(plaque, UDim2.fromScale(0, 0.93), UDim2.fromScale(1, 0.07), 9)
	local rangee = creer("Frame", {Name = "Rangee", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.8), BackgroundTransparency = 1, ZIndex = 2, Parent = plaque},
		{creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.025, 0), SortOrder = Enum.SortOrder.LayoutOrder})})

	-- Bouton Récupérer + barre de fermeture automatique
	local bouton = UI.boutonPrincipal({Name = "Recuperer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.91),
		Size = UDim2.fromScale(0.42, 0.085), BackgroundColor3 = T.Vert, Visible = false, Selectable = true, ZIndex = 9, Parent = racine}, boucles)
	bouton.definir("RÉCUPÉRER", T.Vert, true)
	local barreFond = creer("Frame", {Name = "Minuteur", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.972),
		Size = UDim2.fromScale(0.34, 0.009), BackgroundColor3 = Color3.fromRGB(20, 12, 8), BackgroundTransparency = 0.3, BorderSizePixel = 0,
		Visible = false, ZIndex = 9, Parent = racine}, {coin(0.5)})
	local barre = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = barreFond}, {coin(0.5)})

	return {gui = gui, voile = voile, lueurFond = lueurFond, racine = racine, echelle = echelle, halo = halo, rayons = rayons,
		rayonsGrad = rayonsGrad, coffre = coffre, vp = vp, camera = camera, monde = monde, faisceau = faisceau, bouche = bouche,
		boucheLueur = boucheLueur, eclats = eclats, titre = titre, titreTrait = titreTrait, titreEchelle = titreEchelle,
		sous = sous, plaque = plaque, rangee = rangee, bouton = bouton, barre = barre, barreFond = barreFond, boucles = boucles}
end

-- ================= Icône de pièces dessinée (pile de deux pièces) =================
local function iconePieces(parent: Instance)
	for k, v in {{0.62, 0.42, 0.62}, {0.4, 0.56, 0.72}} do
		local p = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(v[1], v[2]), Size = UDim2.fromScale(v[3], v[3]),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = k, Parent = parent},
			{coin(0.5), trait(OR_FONCE, 2), creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(OR_CLAIR, OR_MOY:Lerp(OR_FONCE, 0.3))})})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.68, 0.68),
			BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = p}, {coin(0.5), trait(OR_FONCE, 1, 0.3),
			creer("UIGradient", {Rotation = 225, Color = ColorSequence.new(OR_CLAIR, OR_MOY)})})
		-- losange gravé + reflet
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.26, 0.26),
			Rotation = 45, BackgroundColor3 = OR_FONCE, BorderSizePixel = 0, Parent = p}, {coin(0.15)})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.32, 0.28), Size = UDim2.fromScale(0.22, 0.12),
			Rotation = -35, BackgroundColor3 = BLANC, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = p}, {coin(0.5)})
	end
end

-- ================= État =================
local ouvert = false
local session = 0
local fermeture = false -- animation de fermeture en cours
local pret = false -- bouton visible : Entrée / B / clic ferment
local file: {Options} = {}
local cartes: {Instance} = {}
local ACTION = "PopupCoffreRecuperer"

local fermer: () -> ()

local function etincelles(e: Elements, maSession: number, couleur: Color3)
	task.spawn(function()
		while ouvert and session == maSession do
			local t = 0.006 + math.random() * 0.01
			local x = 0.5 + (math.random() - 0.5) * 0.34
			local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromScale(t, t),
				SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, ZIndex = 1,
				BackgroundColor3 = couleur:Lerp(BLANC, math.random() * 0.5), Parent = e.eclats}, {coin(0.5)})
			local d = 1.4 + math.random() * 1.4
			tw(b, ti(d, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.25, 0.05 + math.random() * 0.25),
				BackgroundTransparency = 1, Size = UDim2.fromScale(t * 0.3, t * 0.3)})
			Debris:AddItem(b, d)
			task.wait(0.06 + math.random() * 0.08)
		end
	end)
end

-- Carte d'une récompense (créée invisible dans la rangée ; révélée plus tard)
type Carte = {fente: Frame, carte: Frame, montant: TextLabel, valeur: NumberValue, n: number, couleur: Color3, niveau: number}
local function creerCarte(e: Elements, r: Recompense, ordre: number): Carte
	local genre = r.genre
	local n = math.max(0, math.floor(tonumber(r.n) or 0))
	local nom, rarete, couleur = "Pièces", "Trésor", T.Or
	local visuel = if genre == "minerai" and r.id then MineraisModeles.VISUEL[r.id] else nil
	if genre == "minerai" and r.id then
		nom = r.nom or NOMS_MINERAIS[r.id] or r.id
		rarete = if visuel then visuel.rarete else "Minerai"
		couleur = (Pioches.RARETES :: any)[rarete] or T.Or
	elseif r.nom then
		nom = r.nom
	end
	local niveau = UI.NIVEAUX[rarete] or 3

	local fente = creer("Frame", {Name = "Fente", LayoutOrder = ordre, Size = UDim2.fromScale(0.3, 1), BackgroundTransparency = 1,
		Parent = e.rangee}, {creer("UIAspectRatioConstraint", {AspectRatio = 0.8})})
	local carte = creer("Frame", {Name = "Carte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Visible = false, Parent = fente}, {coin(0.1)})
	teintes(carte, T.CarteClaire, T.Carte, Color3.fromRGB(28, 20, 15))
	UI.echelle(carte)
	-- médaillon de l'icône : fond sombre + lueur de rareté
	local medaillon = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.86, 0.56),
		BackgroundColor3 = T.Fond3D, BorderSizePixel = 0, ClipsDescendants = false, Parent = carte}, {coin(0.12), trait(CONTOUR, 1.5)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.95, 0.95),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = couleur, BorderSizePixel = 0, Parent = medaillon},
		{coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1)})})})
	local zone = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = medaillon})
	if genre == "minerai" and r.id and visuel then
		Icones.minerai(r.id, zone, {vitesse = 1.1, marge = 0.78})
	else
		iconePieces(zone)
	end
	texte({Text = nom, Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.05, 0.615), Size = UDim2.fromScale(0.9, 0.12),
		Parent = carte}, 22)
	texte({Text = string.upper(rarete), Font = Enum.Font.GothamBold, TextColor3 = couleur, Position = UDim2.fromScale(0.1, 0.735),
		Size = UDim2.fromScale(0.8, 0.07), Parent = carte}, 13)
	local montant = texte({Text = "+0", Font = Enum.Font.GothamBlack, TextColor3 = if genre == "pieces" then T.Or else couleur:Lerp(BLANC, 0.25),
		Position = UDim2.fromScale(0.05, 0.8), Size = UDim2.fromScale(0.9, 0.17), Parent = carte}, 34)
	creer("UIStroke", {Thickness = 2, Color = CONTOUR, Parent = montant})
	local valeur = Instance.new("NumberValue")
	valeur.Parent = carte
	valeur.Changed:Connect(function(v)
		montant.Text = "+" .. UI.milliers(v)
	end)
	table.insert(cartes, fente)
	return {fente = fente, carte = carte, montant = montant, valeur = valeur, n = n, couleur = couleur, niveau = niveau}
end

-- Fait sortir une carte du coffre (vol en arc depuis l'ouverture) puis lance son compteur
local function reveler(e: Elements, c: Carte, rang: number)
	local f = c.fente
	local bouche = e.bouche
	local dx = (bouche.AbsolutePosition.X + bouche.AbsoluteSize.X / 2 - (f.AbsolutePosition.X + f.AbsoluteSize.X / 2)) / math.max(f.AbsoluteSize.X, 1)
	local dy = (bouche.AbsolutePosition.Y + bouche.AbsoluteSize.Y / 2 - (f.AbsolutePosition.Y + f.AbsoluteSize.Y / 2)) / math.max(f.AbsoluteSize.Y, 1)
	local carte = c.carte
	local ech = UI.echelle(carte)
	carte.Position = UDim2.fromScale(0.5 + dx, 0.5 + dy)
	carte.Rotation = (math.random() - 0.5) * 50
	ech.Scale = 0.15
	carte.Visible = true
	local vol = ti(0.5, Enum.EasingStyle.Back)
	tw(carte, vol, {Position = UDim2.fromScale(0.5, 0.5), Rotation = 0})
	tw(ech, vol, {Scale = 1})
	UI.jouer("ouvrir", 1.5 + rang * 0.1)
	task.delay(0.42, function()
		if not carte.Parent then
			return
		end
		UI.rarete(carte, c.couleur, c.niveau, nil)
		UI.gerbe(f, c.couleur, 10)
		UI.jouer("metal", 0.9 + rang * 0.12)
		UI.pop(carte, 1.18)
		tw(c.valeur, ti(0.8, Enum.EasingStyle.Quad), {Value = c.n})
		task.delay(0.82, function()
			if carte.Parent then
				c.montant.Text = "+" .. UI.milliers(c.n)
				UI.pop(c.montant, 1.35)
				UI.jouer("clic", 1.3)
			end
		end)
	end)
end

local function remettre(e: Elements)
	arreter3D()
	e.faisceau.Size = UDim2.fromScale(0.5, 0)
	e.bouche.Visible = false
	e.boucheLueur.Size = UDim2.fromScale(0.86, 0.7)
	e.rayons.GroupTransparency, e.rayons.Size = 1, UDim2.fromScale(0.6, 0.6)
	e.halo.BackgroundTransparency = 1
	e.titre.Visible = false
	e.sous.TextTransparency = 1
	e.bouton.bouton.Visible = false
	e.barreFond.Visible = false
	e.barre.Size = UDim2.fromScale(1, 1)
	for _, c in cartes do
		c:Destroy()
	end
	table.clear(cartes)
end

local function deroule(e: Elements, o: Options, maSession: number)
	local nomTheme = if THEMES[o.theme or ""] then o.theme :: string else "Defaut"
	local theme = THEMES[nomTheme]
	local actif = function()
		return ouvert and session == maSession
	end
	remettre(e)
	e.titre.Text = string.upper(o.titre or "Trésor")
	e.sous.Text = o.sousTitre or theme.sous
	e.sous.TextColor3 = theme.accent:Lerp(BLANC, 0.35)
	e.halo.BackgroundColor3 = theme.accent
	e.lueurFond.BackgroundColor3 = theme.fond
	e.faisceau.BackgroundColor3 = theme.lueur
	e.boucheLueur.BackgroundColor3 = theme.lueur
	for _, g in e.rayonsGrad do
		g.Color = ColorSequence.new(theme.lueur)
	end
	local cs: {Carte} = {}
	for i, r in o.recompenses or {} do
		if type(r) == "table" and (tonumber(r.n) or 0) > 0 then
			table.insert(cs, creerCarte(e, r, i))
		end
	end

	-- entrée : voile, lueur, racine qui surgit
	e.gui.Enabled = true
	demarrer3D(e.vp, e.monde, e.camera, nomTheme)
	e.voile.BackgroundTransparency = 1
	tw(e.voile, UI.DOUX, {BackgroundTransparency = 0.2})
	e.lueurFond.BackgroundTransparency = 1
	tw(e.lueurFond, ti(0.8), {BackgroundTransparency = 0.2})
	e.echelle.Scale = 0.55
	tw(e.echelle, ti(0.5, Enum.EasingStyle.Back), {Scale = 1})
	for _, t in e.boucles do
		t:Play()
	end
	UI.jouer("ouvrir", 0.8)
	task.wait(0.45)

	-- anticipation : le coffre tremble de plus en plus
	for k = 1, 3 do
		if not actif() then return end
		UI.jouer("metal", 0.55 + k * 0.15)
		S.tremble.Value = 0.35 + k * 0.22
		tw(e.halo, ti(0.2), {BackgroundTransparency = 1 - k * 0.15})
		task.wait(0.26)
		S.tremble.Value = 0
		task.wait(0.16 - k * 0.03)
	end
	if not actif() then return end

	-- ouverture : couvercle qui bascule en arrière, faisceau, flash, gerbe, secousse
	-- position à l'écran de l'ouverture du coffre 3D (pour le halo, le faisceau et le départ des cartes)
	local bx, by = projeter(e.camera, e.vp, Vector3.new(0, HAUT + 0.15, 0))
	e.bouche.Position = UDim2.fromScale(bx, by)
	e.faisceau.Position = UDim2.fromScale(bx, by)
	e.boucheLueur.BackgroundColor3 = theme.lueur
	e.bouche.Visible = true
	tw(S.angle, ti(0.55, Enum.EasingStyle.Back), {Value = -math.rad(112)})
	jaillir(nomTheme)
	tw(e.faisceau, ti(0.5, Enum.EasingStyle.Quart), {Size = UDim2.fromScale(0.5, 1.1)})
	tw(e.rayons, ti(0.6, Enum.EasingStyle.Back), {Size = UDim2.fromScale(1.05, 1.05), GroupTransparency = 0})
	tw(e.halo, ti(0.3), {BackgroundTransparency = 0.25})
	UI.jouer("ouvrir", 0.6)
	impact(0.7)
	task.delay(0.1, function()
		UI.jouer("succes", 0.85)
	end)
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.lueur, BackgroundTransparency = 0.2, BorderSizePixel = 0,
		ZIndex = 30, Parent = e.gui})
	tw(flash, ti(0.55), {BackgroundTransparency = 1})
	Debris:AddItem(flash, 0.6)
	UI.gerbe(e.eclats, theme.lueur, 26, Vector2.new(0.5, 0.42))
	UI.gerbe(e.eclats, theme.accent, 14, Vector2.new(0.5, 0.42))
	for k = 0, 1 do
		local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.1, 0.1),
			BackgroundTransparency = 1, ZIndex = 5, Parent = e.eclats}, {coin(0.5), trait(if k == 0 then theme.lueur else BLANC, 6 - k * 3)})
		local s = anneau:FindFirstChildOfClass("UIStroke") :: UIStroke
		local inf = ti(0.7 + k * 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, k * 0.08)
		tw(anneau, inf, {Size = UDim2.fromScale(1.3, 1.3)})
		tw(s, inf, {Transparency = 1, Thickness = 0})
		Debris:AddItem(anneau, 1.1)
	end
	UI.secouer(e.racine, 10)
	etincelles(e, maSession, theme.lueur)
	-- lueur de l'intérieur qui palpite
	tw(e.boucheLueur, ti(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true), {Size = UDim2.fromScale(0.95, 0.95)})

	-- titre en tampon
	task.wait(0.15)
	if not actif() then return end
	e.titre.Visible = true
	e.titre.TextTransparency, e.titreTrait.Transparency = 1, 1
	e.titreEchelle.Scale = 2.6
	tw(e.titreEchelle, ti(0.35, Enum.EasingStyle.Back), {Scale = 1})
	tw(e.titre, ti(0.18), {TextTransparency = 0})
	tw(e.titreTrait, ti(0.18), {Transparency = 0})
	task.delay(0.3, function()
		if actif() then
			UI.jouer("metal", 0.7)
			UI.secouer(e.titre, 6)
			tw(e.sous, ti(0.4), {TextTransparency = 0})
		end
	end)
	task.wait(0.5)

	-- récompenses une à une
	for i, c in cs do
		if not actif() then return end
		reveler(e, c, i)
		task.wait(0.42)
	end
	task.wait(if #cs > 0 then 0.6 else 0.1)
	if not actif() then return end

	-- bouton + minuteur
	local b = e.bouton.bouton
	b.Visible = true
	UI.pop(b, 0.5)
	UI.jouer("clic", 1.1)
	pret = true
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = b
	end
	e.barreFond.Visible = true
	e.barre.Size = UDim2.fromScale(1, 1)
	tw(e.barre, ti(DUREE_AUTO, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
	task.wait(DUREE_AUTO)
	if actif() then
		fermer()
	end
end

local function lancer(o: Options)
	local e = E or construire()
	if not E then
		E = e
		e.bouton.bouton.Activated:Connect(function()
			if pret then
				UI.jouer("clic", 0.9)
				fermer()
			end
		end)
	end
	ouvert = true
	pret = false
	session += 1
	Curseur.liberer("PopupCoffre", true)
	ContextActionService:BindActionAtPriority(ACTION, function(_, etat)
		if etat == Enum.UserInputState.Begin and pret then
			fermer()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonB)
	task.spawn(deroule, e, o, session)
end

fermer = function()
	local e = E
	if not ouvert or not e then
		return
	end
	ouvert = false
	pret = false
	session += 1
	local maSession = session
	fermeture = true
	ContextActionService:UnbindAction(ACTION)
	Curseur.liberer("PopupCoffre", false)
	if GuiService.SelectedObject == e.bouton.bouton then
		GuiService.SelectedObject = nil
	end
	-- les cartes s'envolent vers le haut (vers la bourse), puis tout s'efface
	for i, f in cartes do
		local c = f:FindFirstChild("Carte")
		if c and c:IsA("Frame") then
			tw(c, ti(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, i * 0.04), {Position = UDim2.fromScale(0.5, -2.2)})
		end
	end
	UI.jouer("ouvrir", 1.3)
	tw(e.echelle, ti(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.12), {Scale = 0.8})
	tw(e.voile, ti(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.12), {BackgroundTransparency = 1})
	tw(e.lueurFond, ti(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.12), {BackgroundTransparency = 1})
	tw(e.rayons, ti(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {GroupTransparency = 1})
	task.delay(0.45, function()
		if ouvert or session ~= maSession then
			return
		end
		fermeture = false
		e.gui.Enabled = false
		for _, t in e.boucles do
			t:Pause()
		end
		remettre(e)
		local suivant = table.remove(file, 1)
		if suivant then
			lancer(suivant)
		end
	end)
end

-- Affiche le pop-up (ou le met en file si un coffre est déjà affiché)
function PopupCoffre.afficher(o: Options)
	if type(o) ~= "table" then
		return
	end
	if ouvert or fermeture or #file > 0 then
		table.insert(file, o)
		return
	end
	lancer(o)
end

function PopupCoffre.fermer()
	fermer()
end

return PopupCoffre
