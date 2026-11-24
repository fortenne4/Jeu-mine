-- Boss du village · CLIENT, entrées en scène des boss (module de BossCinematique), jouées pendant l'intro.
-- Caméra FIXE (un plan cadré par étape, au plus un zoom lent) : c'est le boss qui joue devant l'objectif.
-- TitanCristal  : gros plan sur un cristal qui tremble au pied d'une statue de pierre (titan recoloré + coque de
--                 roche qui l'englobe), plan large : la statue se fissure (veines bleues), secousses croissantes,
--                 elle éclate en débris, le titan libéré grogne les bras levés, poings tremblants.
-- ReineAraignee : plan fixe très large ; elle descend du haut de l'écran au bout d'un fil en tournoyant, atterrit,
--                 plan plus proche : elle se cabre et crache une toile qui couvre l'écran puis se dissout.
-- SeigneurBraise: vue de haut sur le rituel (cercle runique tracé trait par trait, obélisques de feu, portail) ;
--                 plan bas : il jaillit du portail d'un bond ; plan rapproché : recroquevillé et rétréci, il tremble
--                 dans les braises, puis se redresse, grandit et fait éclater le sol (onde, mottes, l'herbe brûle).
-- Tout est local : le boss serveur reste gelé, on ne fait que le masquer / déplacer / recolorer chez ce joueur, et il
-- revient exactement à sa position serveur à la fin. Aucun objet créé à chaque image.
--	local e = Entrees.creer(id, boss, cinema, R) -- nil (avec warn) si l'entrée est impossible
--	e.pas(t) → CFrame? (caméra ; nil = plan commun du rugissement) ; e.fin() : nettoyage complet (idempotent)
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer = UI.creer

local HAUT = Vector3.yAxis
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_FEU = "rbxasset://textures/particles/fire_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"

-- sons déjà utilisés dans le jeu
local SON = {
	cailloux = "rbxassetid://9117371986", -- Pile Rocks 7
	rocheSol = "rbxassetid://9118598279", -- Rock Hit Dirt 14
	rocheCasse = "rbxassetid://9118587698", -- Rock Breaks 3
	rocheCasse2 = "rbxassetid://9118587701", -- Rock Breaks 4
	statue = "rbxassetid://9119598174", -- Statue Debris 3
	impactRoche = "rbxassetid://9118622391", -- Rock Impacts 8
	souffle = "rbxassetid://9120972444", -- Wood Whoosh Quick Swings 1
	feu = "rbxassetid://2787093357", -- feu de camp
	clochette = "rbxassetid://9119448154", -- Sparkle Bell Tree
	eau = "rbxasset://sounds/impact_water.mp3",
	criTitan = "rbxassetid://9114629203",
	criReine = "rbxassetid://9125477768",
	criReine2 = "rbxassetid://9125478014",
	criBraise = "rbxassetid://9116311708",
	criBraise2 = "rbxassetid://9116311525",
}

local PIERRE = Color3.fromRGB(132, 128, 122)
local PIERRE_SOMBRE = Color3.fromRGB(62, 60, 58)
local CRISTAL = Color3.fromRGB(130, 215, 255)
local SOIE = Color3.fromRGB(214, 222, 208)
local BRAISE = Color3.fromRGB(255, 110, 30)
local CENDRE = Color3.fromRGB(26, 22, 20)
local ROUGE = Color3.fromRGB(255, 60, 30)

local function k01(t: number, a: number, b: number): number
	return math.clamp((t - a) / (b - a), 0, 1)
end
local function lisse(k: number): number
	return k * k * (3 - 2 * k)
end

-- ================= Base commune =================
local function nouvelle(boss: Model)
	local pivot = boss:GetPivot()
	local lv = pivot.LookVector
	local avant = Vector3.new(lv.X, 0, lv.Z)
	avant = if avant.Magnitude > 0.01 then avant.Unit else Vector3.zAxis
	local _, taille = boss:GetBoundingBox()
	local e = {
		boss = boss, pivot = pivot, pos = pivot.Position, rot = pivot.Rotation, avant = avant, cote = avant:Cross(HAUT),
		h = boss:GetAttribute("Hauteur") or taille.Y, largeur = math.max(taille.X, taille.Z, 4),
		pieces = {}, joints = {}, evts = {}, i = 1, deplace = false, masque = false, fini = false,
		cam = workspace.CurrentCamera,
		dossier = creer("Folder", {Name = "EntreeBoss", Parent = workspace}),
		sons = creer("Folder", {Name = "EntreeBossSons", Parent = SoundService}),
	}
	for _, p in boss:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then table.insert(e.pieces, p) end
	end
	local j = boss:FindFirstChild("Joints")
	if j then
		for _, m in j:GetChildren() do
			if m:IsA("Motor6D") or m:IsA("AnimationConstraint") then e.joints[m.Name] = m end
		end
	end
	return e
end

local function masquer(e, oui: boolean)
	e.masque = e.masque or oui
	local v = if oui then 1 else 0
	for _, p in e.pieces do p.LocalTransparencyModifier = v end
end

-- la Root ancrée porte tout le rig : la déplacer suffit (moins cher qu'un PivotTo sur 200+ pièces)
local function poser(e, cf: CFrame)
	local r = e.boss.PrimaryPart
	if r then
		r.CFrame = cf * r.PivotOffset:Inverse()
		e.deplace = true
	end
end

local function quand(e, t: number, f: () -> ())
	table.insert(e.evts, {t, f})
end

local function declencher(e, t: number)
	local evts = e.evts
	while e.i <= #evts and evts[e.i][1] <= t do
		local f = evts[e.i][2]
		e.i += 1
		f()
	end
end

local function son(e, id: string, volume: number, vitesse: number?, boucle: boolean?): Sound
	return creer("Sound", {SoundId = id, Volume = volume, PlaybackSpeed = vitesse or 1, Looped = boucle == true, Parent = e.sons})
end

-- son (préchargé) joué à l'instant t, avec secousse éventuelle
local function bruit(e, t: number, id: string, volume: number, vitesse: number?, secousse: number?)
	local s = son(e, id, volume, vitesse)
	quand(e, t, function()
		s:Play()
		if secousse then Outils.secouer(secousse) end
	end)
end

local function piece(e, classe: string, props: {[string]: any}): BasePart
	if props.Anchored == nil then props.Anchored = true end
	props.CanCollide = props.CanCollide == true
	props.CanQuery, props.CanTouch = false, false
	props.CastShadow = props.CastShadow == true
	props.TopSurface, props.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	props.Parent = props.Parent or e.dossier
	return creer(classe, props)
end

local function emetteur(parent: Instance, texture: string, props: {[string]: any}): ParticleEmitter
	props.Texture = texture
	props.Rate = props.Rate or 0
	props.Parent = parent
	return creer("ParticleEmitter", props)
end

local function projeter(p: BasePart, centre: Vector3, rng: Random)
	local d = p.Position - centre
	d = Vector3.new(d.X, 0, d.Z)
	d = if d.Magnitude > 0.1 then d.Unit else Vector3.xAxis
	p.Anchored = false
	p.CanCollide = true
	p.AssemblyLinearVelocity = d * rng:NextNumber(14, 30) + HAUT * rng:NextNumber(18, 40)
	p.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8))
end

-- plan fixe : œil et cible figés, au plus un léger rapprochement (eye0 → eye1) et un zoom lent
local function plan(e, eye0: Vector3, eye1: Vector3, cible: Vector3, fov0: number, fov1: number, k: number): CFrame
	e.cam.FieldOfView = fov0 + (fov1 - fov0) * k
	return CFrame.lookAt(eye0:Lerp(eye1, k), cible)
end

local function finBase(e)
	if e.fini then return end
	e.fini = true
	if e.restaurer then e.restaurer() end
	if e.masque then
		for _, p in e.pieces do p.LocalTransparencyModifier = 0 end
	end
	if e.deplace and e.boss.Parent then e.boss:PivotTo(e.pivot) end
	if e.gui then e.gui:Destroy() end
	e.dossier:Destroy()
	e.sons:Destroy()
end

-- ================= Titan de cristal : la statue =================
local function titan(e, R: number)
	local P, av, cote, h, w, pivot = e.pos, e.avant, e.cote, e.h, e.largeur, e.pivot
	local rng = Random.new(31)
	local TA = 1.8 -- fin du gros plan sur le cristal
	local TB = R - 2.1 -- la statue éclate

	-- statue : titan recoloré en pierre et figé dans sa pose
	local couleurs, materiaux = table.create(#e.pieces), table.create(#e.pieces)
	for i, p in e.pieces do
		couleurs[i], materiaux[i] = p.Color, p.Material
		local _, _, v = p.Color:ToHSV()
		p.Color = PIERRE:Lerp(PIERRE_SOMBRE, 1 - v)
		p.Material = Enum.Material.Slate
	end
	local statue = true
	local function liberer()
		if not statue then return end
		statue = false
		for i, p in e.pieces do
			if p.Parent then p.Color, p.Material = couleurs[i], materiaux[i] end
		end
	end
	e.restaurer = liberer
	local gel = {}
	for _, m in e.joints do gel[m] = m.Transform end

	-- coque de roche qui englobe tout le corps : tranches horizontales, ellipse autour de la silhouette de chaque tranche
	local NB = math.max(4, math.floor(h / 3.3))
	local tranches = table.create(NB)
	for i = 1, NB do tranches[i] = {math.huge, -math.huge, math.huge, -math.huge} end
	for _, p in e.pieces do
		local l = pivot:PointToObjectSpace(p.Position)
		local r = p.Size.Magnitude * 0.3
		local b = tranches[math.clamp(math.floor(l.Y / h * NB) + 1, 1, NB)]
		b[1], b[2] = math.min(b[1], l.X - r), math.max(b[2], l.X + r)
		b[3], b[4] = math.min(b[3], l.Z - r), math.max(b[4], l.Z + r)
	end
	local coque = {piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, w * 1.15, w * 1.15), Color = PIERRE_SOMBRE,
		Material = Enum.Material.Slate, CFrame = CFrame.new(P + HAUT * 0.8) * CFrame.Angles(0, 0, math.pi / 2), CastShadow = true})}
	local faces = {} -- faces de roche tournées vers la caméra : support des fissures
	for i, b in tranches do
		if b[1] > b[2] then continue end
		local cy = (i - 0.5) / NB * h
		local cx, cz = (b[1] + b[2]) / 2, (b[3] + b[4]) / 2
		local ax, az = (b[2] - b[1]) / 2 + 0.7, (b[4] - b[3]) / 2 + 0.7
		local n = math.clamp(math.floor(2 * math.pi * math.sqrt((ax * ax + az * az) / 2) / 3), 6, 18)
		for k = 1, n do
			local a = k / n * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
			local pos = pivot:PointToWorldSpace(Vector3.new(cx + math.cos(a) * ax, cy + rng:NextNumber(-0.6, 0.6), cz + math.sin(a) * az))
			local dehors = pivot:VectorToWorldSpace(Vector3.new(math.cos(a) / ax, 0, math.sin(a) / az).Unit)
			local face = dehors:Dot(av)
			if (cy > h * 0.62 and face > 0.6) or rng:NextNumber() < 0.12 then continue end -- le visage reste lisible
			local sx, sy, sz = rng:NextNumber(2.6, 4.4), rng:NextNumber(2.8, 4.2), rng:NextNumber(1.2, 2.2)
			local cf = CFrame.lookAt(pos, pos + dehors) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.5, 0.5))
			table.insert(coque, piece(e, "Part", {Size = Vector3.new(sx, sy, sz), CFrame = cf,
				Color = PIERRE:Lerp(PIERRE_SOMBRE, rng:NextNumber(0.15, 0.7)), Material = Enum.Material.Slate, CastShadow = true}))
			if face > 0.3 then
				table.insert(faces, {cf * CFrame.new(rng:NextNumber(-sx, sx) * 0.25, -sy * 0.42, -(sz / 2 + 0.06)), sy * 0.95})
			end
		end
	end

	-- petit cristal et cailloux au pied de la statue : ils tremblent
	local C = P + av * (w * 0.5 + 3.5) + cote * 2.5
	local bijoux = {}
	local function bijou(props, caillou: boolean)
		table.insert(bijoux, {piece(e, "Part", props), props.CFrame, rng:NextNumber(0, 100), caillou})
	end
	bijou({Size = Vector3.new(0.9, 2.6, 0.9), CFrame = CFrame.new(C + HAUT * 1.2) * CFrame.Angles(0.12, 0.7, -0.18), Color = CRISTAL,
		Material = Enum.Material.Neon}, false)
	bijou({Size = Vector3.new(0.6, 1.5, 0.6), CFrame = CFrame.new(C + cote * 0.9 + HAUT * 0.6) * CFrame.Angles(0, 0.3, 0.45),
		Color = Color3.fromRGB(95, 130, 230), Material = Enum.Material.Neon}, false)
	bijou({Size = Vector3.new(0.5, 1.1, 0.5), CFrame = CFrame.new(C - cote * 0.8 + av * 0.3 + HAUT * 0.45) * CFrame.Angles(0.3, 1.1, -0.5),
		Color = CRISTAL, Material = Enum.Material.Neon}, false)
	for _ = 1, 7 do
		local s = rng:NextNumber(0.35, 0.8)
		local a = rng:NextNumber(0, 6.3)
		bijou({Size = Vector3.new(s, s * 0.7, s), CFrame = CFrame.new(C + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(1.2, 2.6)
			+ HAUT * (s * 0.35)) * CFrame.Angles(0, a, 0), Color = PIERRE:Lerp(PIERRE_SOMBRE, rng:NextNumber()), Material = Enum.Material.Slate}, true)
	end
	creer("PointLight", {Color = CRISTAL, Brightness = 1.5, Range = 9, Parent = bijoux[1][1]})

	-- fissures : veines bleues sur la coque (et le torse), de plus en plus nombreuses jusqu'à l'éclatement
	for _, p in e.pieces do
		if (p.Position - P):Dot(av) > 0 and p.Size.Magnitude > 2.5 and (p.Position - P).Y > h * 0.35 then
			local r = p.CFrame
			local ext = math.abs(av:Dot(r.RightVector)) * p.Size.X / 2 + math.abs(av:Dot(r.UpVector)) * p.Size.Y / 2
				+ math.abs(av:Dot(r.LookVector)) * p.Size.Z / 2
			local c = p.Position + av * (ext + 0.06)
			table.insert(faces, {CFrame.lookAt(c, c + av) * CFrame.Angles(0, 0, rng:NextNumber(0, math.pi * 2)), math.max(p.Size.X, p.Size.Y, p.Size.Z)})
		end
	end
	local fissures = {}
	local n = math.min(30, #faces)
	local d0, d1 = TA + 0.25, TB - 0.3
	for k = 1, n do
		local f = table.remove(faces, rng:NextInteger(1, #faces))
		local base = f[1] * CFrame.Angles(0, 0, rng:NextNumber(-0.7, 0.7))
		table.insert(fissures, {piece(e, "Part", {Size = Vector3.new(0.35, 0.05, 0.25), CFrame = base, Color = CRISTAL, Material = Enum.Material.Neon,
			Transparency = 1}), base, math.min(rng:NextNumber(2, 4.5), f[2]), d0 + ((k - 1) / n) ^ 0.7 * (d1 - d0), 0})
	end

	local coeur = piece(e, "Part", {Size = Vector3.one * 0.2, Transparency = 1, CFrame = CFrame.new(P + HAUT * h * 0.5 + av * (w * 0.4))})
	local lueur = creer("PointLight", {Color = CRISTAL, Brightness = 0, Range = 40, Parent = coeur})
	local poussiere = emetteur(coeur, TEX_FUMEE, {Color = ColorSequence.new(Color3.fromRGB(150, 145, 140)), Size = NumberSequence.new(3, 9),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(1.2, 2.2), Speed = NumberRange.new(10, 25),
		SpreadAngle = Vector2.new(180, 180), Drag = 3})
	local eclats = emetteur(coeur, TEX_ETINCELLE, {Color = ColorSequence.new(CRISTAL), LightEmission = 1, Size = NumberSequence.new(0.7, 0),
		Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(25, 45), SpreadAngle = Vector2.new(180, 180), Drag = 2})
	local gravats = emetteur(coeur, TEX_FUMEE, {Color = ColorSequence.new(Color3.fromRGB(120, 115, 110)), Size = NumberSequence.new(0.6, 1.4),
		Transparency = NumberSequence.new(0.2, 1), Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(2, 5), Acceleration = Vector3.new(0, -30, 0),
		SpreadAngle = Vector2.new(60, 60)})

	-- sons et secousses croissantes
	bruit(e, 0.3, SON.cailloux, 0.5, 1.2)
	bruit(e, 1.1, SON.cailloux, 0.6, 1)
	bruit(e, TA - 0.1, SON.rocheSol, 0.6, 0.9, 0.1)
	for k = 1, 5 do
		bruit(e, TA + 0.4 + (k - 1) / 4 * (TB - TA - 0.65), SON.rocheCasse, 0.45 + k * 0.1, 0.75 + k * 0.08, 0.1 + k * 0.08)
	end
	quand(e, TA + 0.3, function()
		Outils.jouer("grondement", 0.5, 0.5)
		gravats.Rate = 14
	end)
	bruit(e, TB, SON.statue, 1)
	bruit(e, TB, SON.rocheCasse2, 0.9, 0.8)
	bruit(e, TB + 0.35, SON.criTitan, 0.9, 0.6)
	quand(e, TB + 0.4, function() Outils.jouer("grondement", 0.6, 0.6) end)
	bruit(e, R, SON.criTitan, 1, 0.75)

	-- la statue éclate
	local volants = {}
	quand(e, TB, function()
		liberer()
		gravats.Rate = 0
		for _, f in fissures do f[1]:Destroy() end
		table.clear(fissures)
		local centre = P + HAUT * h * 0.4
		for _, p in coque do
			projeter(p, centre, rng)
			table.insert(volants, p)
		end
		for _ = 1, 26 do
			local s = rng:NextNumber(0.8, 2.6)
			local p = piece(e, "Part", {Size = Vector3.new(s, s * rng:NextNumber(0.6, 1.3), s * rng:NextNumber(0.6, 1.3)),
				CFrame = CFrame.new(P + HAUT * rng:NextNumber(1, h * 0.95) + cote * (rng:NextNumber(-0.4, 0.4) * w) + av * (rng:NextNumber(-0.3, 0.3) * w))
					* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
				Color = PIERRE:Lerp(PIERRE_SOMBRE, rng:NextNumber()), Material = Enum.Material.Slate, CastShadow = true})
			projeter(p, centre, rng)
			table.insert(volants, p)
		end
		lueur.Brightness = 10
		TweenService:Create(lueur, TweenInfo.new(0.9), {Brightness = 0}):Play()
		poussiere:Emit(45)
		eclats:Emit(60)
		local onde = piece(e, "Part", {Shape = Enum.PartType.Ball, Size = Vector3.one * 4, CFrame = CFrame.new(centre), Color = CRISTAL,
			Material = Enum.Material.Neon, Transparency = 0.2})
		TweenService:Create(onde, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.one * (w * 1.8), Transparency = 1}):Play()
		Outils.jouer("impact", 0.5, 0.6)
		Outils.secouer(0.8)
	end)
	quand(e, R + 1.6, function()
		for _, p in volants do
			if p.Parent then TweenService:Create(p, TweenInfo.new(0.8), {Transparency = 1}):Play() end
		end
	end)

	-- colère : bras levés au ciel (poses absolues depuis le repos ; os alignés sur le modèle, devant = -Z).
	-- Rz(θ) envoie le bras pendant (0, -1, 0) vers (sin θ, -cos θ) : θ = -2.5 → haut-gauche (arm.L est en -X),
	-- +2.5 → haut-droite. Avant-bras pliés vers l'intérieur (poings au-dessus de la tête), torse en arrière, tête levée.
	local bras = {}
	for _, d in {
		{"arm.L", CFrame.Angles(-0.3, 0, -2.5), 1}, {"arm.R", CFrame.Angles(-0.3, 0, 2.5), 1},
		{"fore.L", CFrame.Angles(0, 0, -0.9), 2}, {"fore.R", CFrame.Angles(0, 0, 0.9), 2},
		{"torso", CFrame.Angles(0.14, 0, 0), 0}, {"head", CFrame.Angles(0.3, 0, 0), 0}, {"jaw", CFrame.Angles(-0.4, 0, 0), 0},
	} do
		local m = e.joints[d[1]]
		if m then table.insert(bras, {m, d[2], d[3], CFrame.identity, CFrame.identity, rng:NextNumber(0, 50)}) end
	end
	local function colere(b, wb: number, t: number)
		local m = b[1]
		local cur = m.Transform
		if cur ~= b[5] then b[4] = cur end -- l'animateur a réécrit : nouvelle base
		local cible = b[2]
		if b[3] > 0 then -- poings qui tremblent
			local a = (if b[3] == 2 then 0.14 else 0.05) * wb
			cible *= CFrame.Angles(math.noise(t * 15, b[6]) * a, 0, math.noise(t * 17, b[6] + 9) * a)
		end
		local v = b[4]:Lerp(cible, wb)
		m.Transform = v
		b[5] = v
	end

	local camA0 = C + av * 7.5 + cote * 1.4 + HAUT * 1.6
	local camA1 = C + av * 6.5 + cote * 1.2 + HAUT * 1.5
	local cibleA = C + HAUT * 1.7
	local cibleB = P + HAUT * (h * 0.55)
	local camB0 = P + av * (h * 1.3 + 9) + cote * (h * 0.14) + HAUT * (h * 0.3)
	local camB1 = camB0 + (cibleB - camB0).Unit * 2.5

	return function(t: number): CFrame?
		declencher(e, t)
		if t < TB + 0.1 then
			local amp = 0.03 + 0.16 * k01(t, 0.2, TA) + 0.12 * k01(t, TA, TB)
			for _, b in bijoux do
				local g = b[3]
				if b[4] then
					b[1].CFrame = b[2] + HAUT * (math.max(0, math.noise(t * 9, g)) * amp * 2.2)
				else
					b[1].CFrame = b[2] * CFrame.new(math.noise(t * 31, g) * amp, 0, math.noise(t * 29, g + 7) * amp)
						* CFrame.Angles(0, 0, math.noise(t * 23, g + 3) * amp * 0.6)
				end
			end
		end
		if statue then
			for m, cf in gel do m.Transform = cf end
			lueur.Brightness = 4 * k01(t, TA, TB)
			for _, f in fissures do
				if f[5] < 1 then
					local g = k01(t, f[4], f[4] + 0.3)
					if g > 0 then
						f[5] = g
						local l = f[3] * g
						f[1].Transparency = 0
						f[1].Size = Vector3.new(0.35, l, 0.25)
						f[1].CFrame = f[2] * CFrame.new(0, l / 2, 0)
					end
				end
			end
		else
			local wb = lisse(k01(t, TB + 0.1, TB + 0.55)) * (1 - lisse(k01(t, R + 1.7, R + 2.4)))
			if wb > 0 then
				for _, b in bras do colere(b, wb, t) end
			end
		end
		if t >= R then return nil end
		if t < TA then return plan(e, camA0, camA1, cibleA, 44, 41, lisse(t / TA)) end
		return plan(e, camB0, camB1, cibleB, 50, 46, lisse(k01(t, TA, R)))
	end
end

-- ================= Reine araignée : descente au fil, toile crachée =================
local function ligne(parent: Instance, a: Vector2, b: Vector2, ep: number, transp: number)
	local d = b - a
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.new(d.Magnitude, ep, 0, ep), Rotation = math.deg(math.atan2(d.Y, d.X)), BackgroundColor3 = SOIE,
		BackgroundTransparency = transp, BorderSizePixel = 0, Parent = parent})
end

local function toileEcran(cinema: Instance): (CanvasGroup, UIScale)
	local toile = creer("CanvasGroup", {Name = "ToileBoss", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.5, 1.5), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1, Visible = false,
		ZIndex = 38, Parent = cinema})
	local echelle = creer("UIScale", {Scale = 0.1, Parent = toile})
	local rng = Random.new(9)
	local c = Vector2.new(0.5, 0.5)
	local nb = 14
	local angles = table.create(nb)
	for k = 1, nb do angles[k] = (k - 1) / nb * math.pi * 2 + rng:NextNumber(-0.12, 0.12) end
	local function pt(a: number, r: number): Vector2
		return c + Vector2.new(math.cos(a), math.sin(a)) * r
	end
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8),
		BackgroundColor3 = SOIE, BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = toile}, {UI.coin(0.5)})
	for k = 1, nb do ligne(toile, c, pt(angles[k], 0.72), 5, 0.05) end
	for _, r in {0.04, 0.075, 0.115, 0.16, 0.215, 0.28, 0.355, 0.44} do
		for k = 1, nb do
			local a1 = angles[k]
			local a2 = if k == nb then angles[1] + math.pi * 2 else angles[k + 1]
			local rr = r * rng:NextNumber(0.92, 1.08)
			local m = pt((a1 + a2) / 2, rr * 0.86)
			ligne(toile, pt(a1, rr), m, 3, 0.2)
			ligne(toile, m, pt(a2, rr), 3, 0.2)
		end
	end
	for _ = 1, 6 do -- glu au centre et coulures
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + rng:NextNumber(-0.03, 0.03), 0.5 + rng:NextNumber(-0.02, 0.05)),
			Size = UDim2.fromScale(rng:NextNumber(0.03, 0.07), rng:NextNumber(0.03, 0.09)), BackgroundColor3 = SOIE, BackgroundTransparency = 0.1,
			BorderSizePixel = 0, Parent = toile}, {UI.coin(0.5)})
	end
	return toile, echelle
end

local function reine(e, R: number, cinema: Instance)
	local P, av, cote, h, w = e.pos, e.avant, e.cote, e.h, e.largeur
	local TD0, TD1 = 0.5, R - 3 -- descente
	local TS = R - 2 -- crachat
	local TW = TS + 0.22 -- la toile touche l'écran
	local TF = R - 0.95 -- la toile se dissout
	local TC = TD1 + 0.35 -- second plan, plus proche, pour le crachat
	local FOV0, FOV1 = 55, 51

	-- 1er plan : très large et lointain ; cadre haut de V = 3,4 h (elle occupe ~30 % de la hauteur), sol en bas
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {e.boss, e.dossier}
	local hit = workspace:Raycast(P + HAUT * 2, HAUT * 150, params)
	local plafond = if hit then hit.Position.Y - P.Y else math.huge
	local V = h * 3.4
	local cibleL = P + HAUT * (V * 0.38)
	local dirL = (av + cote * 0.2).Unit
	local fovL = 50
	local distL = V / 2 / math.tan(math.rad(fovL / 2))
	local mur = workspace:Raycast(cibleL, dirL * distL, params)
	if mur and mur.Distance - 2 < distL then
		local d = math.max(mur.Distance - 2, h * 1.6)
		fovL = math.min(2 * math.deg(math.atan(V / 2 / d)), 80)
		distL = d
	end
	local eyeL0 = cibleL + dirL * distL - HAUT * (V * 0.1)
	local eyeL1 = eyeL0 + (cibleL - eyeL0).Unit * (distL * 0.04)
	local y0 = math.max(math.min(V * 0.88 - h * 0.25, plafond - h * 0.9), h + 4)
	-- 2e plan : face à l'arrivée, plus proche
	local eye0 = P + av * (h * 1.7 + 10) + cote * (h * 0.22) + HAUT * (h * 0.32)
	local cible = P + HAUT * (h * 0.42)
	local eye1 = eye0 + (cible - eye0).Unit * 2
	local sommet = if hit then hit.Position else P + HAUT * (y0 + h + 60)
	local fil = piece(e, "Part", {Size = Vector3.new(0.3, 1, 0.3), CFrame = CFrame.new(sommet), Color = SOIE, Material = Enum.Material.Neon,
		Transparency = 0.2})
	local crachat = piece(e, "Part", {Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, CFrame = CFrame.new(P), Color = SOIE,
		Material = Enum.Material.Neon, Transparency = 1})
	local sol = piece(e, "Part", {Size = Vector3.one * 0.2, Transparency = 1, CFrame = CFrame.new(P + HAUT * 0.5)})
	local poussiere = emetteur(sol, TEX_FUMEE, {Color = ColorSequence.new(Color3.fromRGB(120, 130, 110)), Size = NumberSequence.new(2, 7),
		Transparency = NumberSequence.new(0.4, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(12, 22),
		SpreadAngle = Vector2.new(80, 10), EmissionDirection = Enum.NormalId.Top, Drag = 4})
	local toile, echelle = toileEcran(cinema)
	e.gui = toile

	local function hauteur(t: number): (number, number)
		if t < TD1 then
			local s = 1 - (1 - k01(t, TD0, TD1)) ^ 1.7
			return y0 * (1 - s), s
		end
		local b = k01(t, TD1, TD1 + 0.4)
		return math.sin(b * math.pi) * 1.2 * (1 - b), 1
	end
	-- se cabre avant de cracher, puis claque vers l'avant
	local function tangage(t: number): number
		if t < TS then return 0.35 * lisse(k01(t, TS - 0.75, TS - 0.08)) end
		local k = k01(t, TS, TS + 0.12)
		if k < 1 then return 0.35 - 0.47 * k end
		return -0.12 * (1 - k01(t, TS + 0.12, TS + 0.6))
	end
	poser(e, CFrame.new(P + HAUT * y0) * e.rot)

	for k, t in {0.6, 1.4, 2.1} do bruit(e, t, SON.souffle, 0.5, 0.6 + k * 0.1) end
	bruit(e, 1.5, SON.criReine2, 0.35, 0.8)
	bruit(e, TD1, SON.rocheSol, 0.8, 0.8, 0.4)
	bruit(e, TS - 0.6, SON.criReine2, 0.6, 1.2)
	bruit(e, TS - 0.05, SON.criReine, 0.9, 1.1)
	bruit(e, TS, SON.souffle, 0.7, 1.2)
	bruit(e, TW, SON.eau, 0.9, 0.8, 0.3)
	bruit(e, R, SON.criReine2, 1, 0.9)
	quand(e, TD1, function()
		poussiere:Emit(30)
		Outils.jouer("impact", 0.4, 0.5)
	end)
	quand(e, TS, function() crachat.Transparency = 0 end)
	quand(e, TW, function()
		crachat.Transparency = 1
		toile.Visible = true
		echelle.Scale = 0.15
		TweenService:Create(echelle, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(toile, TweenInfo.new(2, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.5, 0.56)}):Play()
	end)
	quand(e, TF, function()
		TweenService:Create(toile, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
		TweenService:Create(echelle, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {Scale = 1.12}):Play()
	end)

	local bouche = P + av * (w * 0.4) + HAUT * (h * 0.45)
	local vise = eye1 + (bouche - eye1).Unit * 2.5
	local pose, attache = false, sommet

	return function(t: number): CFrame?
		declencher(e, t)
		if t < TD1 + 0.45 then
			-- descente tête en bas, à la verticale, pendue au fil par l'abdomen ; elle se retourne juste avant le sol
			local y, s = hauteur(t)
			local f = lisse(k01(t, TD1 - 0.75, TD1 - 0.05)) -- 0 = tête en bas, 1 = sur ses pattes
			local demi = h * 0.5
			local leve = math.max(w * 0.5 - demi, 0) * (1 - f) -- la tête ne touche pas le sol pendant le retournement
			local centre = P + HAUT * (y + demi + leve) + cote * (math.sin(t * 2.4) * 1.2 * (1 - s))
			local tour = (1 - s) ^ 1.5 * math.pi * 6
			poser(e, CFrame.new(centre) * CFrame.Angles(0, tour, 0) * e.rot * CFrame.Angles(-math.pi / 2 * (1 - f), 0, 0)
				* CFrame.new(0, -demi, 0))
			if t < TD1 + 0.15 then attache = centre + HAUT * (w * 0.5 * (1 - f) + h * 0.2 * f) end
		elseif t < TS + 0.65 then
			local a = tangage(t)
			poser(e, e.pivot * CFrame.new(0, math.abs(a) * w * 0.22, 0) * CFrame.Angles(a, 0, 0))
		elseif not pose then
			pose = true
			poser(e, e.pivot)
		end
		if fil.Parent then
			if t < TD1 + 0.9 then
				local bas = attache:Lerp(sommet, k01(t, TD1 + 0.15, TD1 + 0.9))
				fil.Size = Vector3.new(0.3, math.max((sommet - bas).Magnitude, 0.05), 0.3)
				fil.CFrame = CFrame.new((sommet + bas) / 2)
			else
				fil:Destroy()
			end
		end
		if t >= TS and t < TW then
			local k = k01(t, TS, TW)
			crachat.Size = Vector3.one * (1.4 + 2 * k)
			crachat.CFrame = CFrame.new(bouche:Lerp(vise, k))
		end
		if t >= R then return nil end
		if t < TC then return plan(e, eyeL0, eyeL1, cibleL, fovL, fovL, lisse(t / TC)) end
		return plan(e, eye0, eye1, cible, FOV0, FOV1, lisse(k01(t, TC, R)))
	end
end

-- ================= Seigneur de braise : rituel, portail, bond, éclosion =================
-- os (Data.Bones) : root › hips › torso › head › jaw, torso › arm.* › fore.*, root › leg.* (jambe d'un seul os)
local OS_BRAISE = {"root", "hips", "torso", "head", "jaw", "arm.L", "fore.L", "arm.R", "fore.R", "leg.L", "leg.R"}

local function poseBraise(d: {[string]: CFrame}, sol: boolean)
	local p = table.create(#OS_BRAISE, CFrame.identity)
	for i, nom in OS_BRAISE do p[i] = d[nom] or CFrame.identity end
	-- abaissement de la racine (en longueurs de jambe) pour garder les pieds au sol
	local v = (d["leg.L"] or CFrame.identity):VectorToWorldSpace(-HAUT)
	p.chute = if sol then 1 + v.Y else 0
	return p
end

local function A(x: number, z: number?): CFrame
	return CFrame.Angles(x, 0, z or 0)
end

local function braise(e, R: number)
	local P, av, cote, h, w = e.pos, e.avant, e.cote, e.h, e.largeur
	local rng = Random.new(17)
	local TA = R - 4.7 -- fin du plan rituel vu de haut
	local TP = TA - 0.9 -- le portail s'ouvre
	local TS = TA + 0.6 -- saut hors du portail
	local TI = TS + 1.1 -- atterrissage recroquevillé
	local TC = TI + 0.35 -- plan rapproché
	local TG = R - 1.3 -- se redresse et grandit
	local TX = TG + 0.22 -- éclate le sol
	local rr = math.max(9, h * 0.5)
	local rr2 = rr * 0.72
	local Q = P - av * math.max(22, rr * 1.9) -- cercle runique et portail, derrière la place du boss
	local Pc = Q + HAUT * (h * 0.62)
	local Dp = h * 1.15
	masquer(e, true)

	-- duvet d'herbe autour du point d'impact
	local rG = math.max(w * 0.55, 9)
	local touffes = {}
	for _ = 1, 46 do
		local a, r = rng:NextNumber(0, math.pi * 2), rG * math.sqrt(rng:NextNumber())
		local pied = P + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		for _ = 1, 2 do
			local ht = rng:NextNumber(0.9, 2)
			local col = Color3.fromRGB(70, 150, 50):Lerp(Color3.fromRGB(125, 195, 70), rng:NextNumber())
			local cf = CFrame.new(pied + HAUT * (ht / 2)) * CFrame.Angles(0, rng:NextNumber(0, 6.3), 0) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, 0)
			table.insert(touffes, {piece(e, "WedgePart", {Size = Vector3.new(0.25, ht, 0.7), CFrame = cf, Color = col, Material = Enum.Material.SmoothPlastic}),
				col, r / rG * 0.3, cf, ht, 0})
		end
	end
	local zoneFeu = piece(e, "Part", {Size = Vector3.new(rG * 2, 1, rG * 2), Transparency = 1, CFrame = CFrame.new(P + HAUT * 0.6)})
	local flammes = emetteur(zoneFeu, TEX_FEU, {Color = ColorSequence.new(Color3.fromRGB(255, 190, 80), Color3.fromRGB(220, 50, 15)),
		LightEmission = 1, Size = NumberSequence.new(1.6, 0), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(3, 7),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(15, 15)})
	local fumee = emetteur(zoneFeu, TEX_FUMEE, {Color = ColorSequence.new(Color3.fromRGB(55, 50, 48)), Size = NumberSequence.new(2, 6),
		Transparency = NumberSequence.new(0.35, 1), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(3, 5),
		EmissionDirection = Enum.NormalId.Top, Drag = 1})
	local braisesAir = emetteur(zoneFeu, TEX_ETINCELLE, {Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), ROUGE), LightEmission = 1,
		Size = NumberSequence.new(0.45, 0), Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(0.5, 2.5),
		Acceleration = Vector3.new(0, 4, 0), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(70, 70)})
	local souffleSol = emetteur(zoneFeu, TEX_FUMEE, {Color = ColorSequence.new(Color3.fromRGB(110, 85, 60)), Size = NumberSequence.new(3, 10),
		Transparency = NumberSequence.new(0.3, 1), Lifetime = NumberRange.new(0.9, 1.8), Speed = NumberRange.new(18, 34),
		SpreadAngle = Vector2.new(85, 10), EmissionDirection = Enum.NormalId.Top, Drag = 4})
	local gerbe = emetteur(zoneFeu, TEX_ETINCELLE, {Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), BRAISE), LightEmission = 1,
		Size = NumberSequence.new(0.8, 0), Lifetime = NumberRange.new(0.6, 1.3), Speed = NumberRange.new(25, 50),
		Acceleration = Vector3.new(0, -25, 0), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Drag = 1})
	local lueurSol = creer("PointLight", {Color = BRAISE, Brightness = 0, Range = rG * 2.5, Parent = zoneFeu})
	local rougeur = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, rG * 1.7, rG * 1.7), Color = ROUGE,
		Material = Enum.Material.Neon, Transparency = 1, CFrame = CFrame.new(P + HAUT * 0.07) * CFrame.Angles(0, 0, math.pi / 2)})
	local marque = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.08, rG * 2.1, rG * 2.1),
		CFrame = CFrame.new(P + HAUT * 0.05) * CFrame.Angles(0, 0, math.pi / 2), Color = CENDRE, Material = Enum.Material.Slate, Transparency = 1})
	local braisesSol = {}
	for k = 1, 10 do
		local a = k / 10 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local l = rG * rng:NextNumber(0.5, 0.95)
		table.insert(braisesSol, piece(e, "Part", {Size = Vector3.new(0.35, 0.1, l), Color = BRAISE, Material = Enum.Material.Neon, Transparency = 1,
			CFrame = CFrame.new(P + HAUT * 0.12) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -l / 2)}))
	end
	-- mottes de sol projetées par l'éclatement (cachées jusque-là)
	local mottes = {}
	for _ = 1, 24 do
		local s = rng:NextNumber(0.9, 2.4)
		local a, r = rng:NextNumber(0, math.pi * 2), rG * rng:NextNumber(0.25, 0.85)
		table.insert(mottes, piece(e, "Part", {Size = Vector3.new(s, s * rng:NextNumber(0.5, 0.9), s * rng:NextNumber(0.7, 1.2)),
			CFrame = CFrame.new(P + Vector3.new(math.cos(a) * r, s * 0.3, math.sin(a) * r)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
			Color = Color3.fromRGB(92, 70, 52):Lerp(Color3.fromRGB(70, 110, 45), rng:NextNumber() * 0.5), Material = Enum.Material.Slate,
			Transparency = 1, CastShadow = true}))
	end

	-- cercle runique (anneaux qui tournent en sens contraires, runes, hexagramme), tracé trait par trait
	local runes = {}
	local function rune(props, offset: CFrame, sens: number, app: number)
		props.Color, props.Material, props.Transparency = ROUGE, Enum.Material.Neon, 1
		props.CFrame = CFrame.new(Q) * offset
		table.insert(runes, {piece(e, "Part", props), offset, sens, app, props.Size, 0})
	end
	for k = 0, 15 do
		rune({Size = Vector3.new(2 * math.pi * rr / 16 * 1.05, 0.12, 0.45)}, CFrame.Angles(0, k / 16 * math.pi * 2, 0) * CFrame.new(0, 0.06, -rr), 1, 0.25 + k * 0.06)
	end
	for k = 0, 11 do
		rune({Size = Vector3.new(2 * math.pi * rr2 / 12 * 1.05, 0.12, 0.38)}, CFrame.Angles(0, k / 12 * math.pi * 2, 0) * CFrame.new(0, 0.06, -rr2), -1, 0.9 + k * 0.06)
	end
	for k = 0, 7 do
		rune({Size = Vector3.new(1.3, 0.14, 2)}, CFrame.Angles(0, (k + 0.5) / 8 * math.pi * 2, 0) * CFrame.new(0, 0.07, -(rr + rr2) / 2), 1, 1.3 + k * 0.07)
	end
	for k = 0, 5 do
		rune({Size = Vector3.new(rr2 * 1.732, 0.12, 0.3)}, CFrame.Angles(0, k / 6 * math.pi * 2, 0) * CFrame.new(0, 0.06, -rr2 * 0.5), -1, 1.6 + k * 0.07)
	end
	local disque = piece(e, "Part", {Size = Vector3.new(rr * 2, 0.2, rr * 2), Transparency = 1, CFrame = CFrame.new(Q + HAUT * 0.3)})
	local montee = emetteur(disque, TEX_ETINCELLE, {Color = ColorSequence.new(Color3.fromRGB(255, 160, 60), ROUGE), LightEmission = 1,
		Size = NumberSequence.new(0.6, 0), Lifetime = NumberRange.new(1.2, 2.2), Speed = NumberRange.new(6, 14),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(8, 8)})
	local lumiereCercle = creer("PointLight", {Color = ROUGE, Brightness = 0, Range = rr * 3, Parent = disque})
	-- obélisques de feu autour du cercle, allumés un par un
	for k = 0, 5 do
		local a = (k + 0.5) / 6 * math.pi * 2
		local ho = 4 + h * 0.15
		local base = CFrame.new(Q) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -rr * 1.28)
		piece(e, "Part", {Size = Vector3.new(1.8, ho, 1.8), CFrame = base * CFrame.new(0, ho / 2, 0), Color = PIERRE_SOMBRE, Material = Enum.Material.Slate,
			CastShadow = true})
		local tete = piece(e, "Part", {Size = Vector3.new(1.2, 0.8, 1.2), CFrame = base * CFrame.new(0, ho + 0.4, 0), Color = CENDRE,
			Material = Enum.Material.Slate})
		local f = emetteur(tete, TEX_FEU, {Color = ColorSequence.new(Color3.fromRGB(255, 190, 80), Color3.fromRGB(220, 50, 15)), LightEmission = 1,
			Size = NumberSequence.new(1.8, 0), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(4, 7),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(10, 10)})
		quand(e, 0.5 + k * 0.22, function()
			tete.Color, tete.Material = BRAISE, Enum.Material.Neon
			f.Rate = 30
			f:Emit(8)
		end)
	end

	-- portail de feu (disques dont la normale est l'avant du boss)
	local cfP = CFrame.fromMatrix(Pc, av, HAUT)
	local bord = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.1, 0.1), CFrame = cfP, Color = Color3.fromRGB(255, 130, 35),
		Material = Enum.Material.Neon, Transparency = 1})
	local fond = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.1, 0.1), CFrame = cfP, Color = Color3.fromRGB(120, 15, 8),
		Material = Enum.Material.Neon, Transparency = 1})
	local centre = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 0.1, 0.1), CFrame = cfP, Color = Color3.fromRGB(255, 205, 90),
		Material = Enum.Material.Neon, Transparency = 1})
	local spirale = {}
	for _ = 1, 6 do
		table.insert(spirale, piece(e, "Part", {Size = Vector3.new(0.8, 0.1, 0.1), CFrame = cfP, Color = Color3.fromRGB(210, 60, 15),
			Material = Enum.Material.Neon, Transparency = 1}))
	end
	local feuPortail = emetteur(bord, TEX_FEU, {Color = ColorSequence.new(Color3.fromRGB(255, 180, 70), Color3.fromRGB(200, 40, 10)), LightEmission = 1,
		Size = NumberSequence.new(2.5, 0), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(180, 180)})
	local lumierePortail = creer("PointLight", {Color = BRAISE, Brightness = 0, Range = 40, Parent = centre})
	local portailVisible = false

	local function ouverture(t: number): number
		local k = k01(t, TP, TP + 0.8)
		local o = 1 + 2.70158 * (k - 1) ^ 3 + 1.70158 * (k - 1) ^ 2
		return o * (1 - lisse(k01(t, TI + 0.2, TI + 0.9)))
	end

	-- rig : poses clés (rotations en axes du modèle, devant = -Z ; Rx > 0 : membre pendant vers l'avant, torse/tête en arrière)
	local PREP = poseBraise({hips = A(-0.15), torso = A(-0.35), head = A(0.2), ["arm.L"] = A(-0.9, -0.15), ["arm.R"] = A(-0.9, 0.15),
		["fore.L"] = A(0.3), ["fore.R"] = A(0.3), ["leg.L"] = A(0.6, -0.1), ["leg.R"] = A(0.6, 0.1)}, true)
	local LANCER = poseBraise({hips = A(-0.1), torso = A(-0.2), head = A(0.25), ["arm.L"] = A(1.9, -0.2), ["arm.R"] = A(1.9, 0.2),
		["fore.L"] = A(0.3), ["fore.R"] = A(0.3), ["leg.L"] = A(-0.45), ["leg.R"] = A(-0.25)}, false)
	local VOL = poseBraise({hips = A(-0.2), torso = A(-0.3), head = A(0.15), ["arm.L"] = A(0.9, -0.5), ["arm.R"] = A(0.9, 0.5),
		["fore.L"] = A(0.9), ["fore.R"] = A(0.9), ["leg.L"] = A(1, -0.15), ["leg.R"] = A(0.85, 0.15)}, false)
	local RECROQ = poseBraise({hips = A(-0.45), torso = A(-0.5), head = A(-0.35), ["arm.L"] = A(0.55, 0.35), ["arm.R"] = A(0.55, -0.35),
		["fore.L"] = A(1.6, 0.3), ["fore.R"] = A(1.6, -0.3), ["leg.L"] = A(0.85, -0.35), ["leg.R"] = A(0.85, 0.35)}, true)
	RECROQ.chute += 0.05
	local EXT = poseBraise({hips = A(0.1), torso = A(0.25), head = A(0.4), jaw = A(-0.5), ["arm.L"] = A(-0.25, -2.1), ["arm.R"] = A(-0.25, 2.1),
		["fore.L"] = A(0, -0.5), ["fore.R"] = A(0, 0.5), ["leg.L"] = A(0, -0.2), ["leg.R"] = A(0, 0.2)}, true)
	local CLES = {{TS, PREP}, {TS + 0.25, LANCER}, {TS + 0.6, VOL}, {TI - 0.12, VOL}, {TI + 0.1, RECROQ}, {TG, RECROQ}, {TG + 0.25, EXT}}
	local rig = {} -- {Motor6D, indice, base, dernier, graine}
	for i, nom in OS_BRAISE do
		local m = e.joints[nom]
		if m and m:IsA("Motor6D") then table.insert(rig, {m, i, CFrame.identity, CFrame.identity, rng:NextNumber(0, 50)}) end
	end
	local jambe = e.joints["leg.L"]
	local s0 = e.boss:GetScale()
	local ech = s0
	local function echelle(s: number)
		if math.abs(s - ech) > 1e-4 and e.boss.Parent then
			ech = s
			pcall(e.boss.ScaleTo, e.boss, s)
		end
	end
	e.restaurer = function() echelle(s0) end

	local function animer(t: number)
		local ia = 1
		while ia < #CLES - 1 and CLES[ia + 1][1] <= t do ia += 1 end
		local ca, cb = CLES[ia], CLES[ia + 1]
		local k = lisse(k01(t, ca[1], cb[1]))
		local pa, pb = ca[2], cb[2]
		local L = if jambe and jambe:IsA("Motor6D") then jambe.C0.Y else h * 0.35
		local chute = pa.chute + (pb.chute - pa.chute) * k
		local tremble = 0.07 * k01(t, TI + 0.3, TG) * (1 - k01(t, TG, TG + 0.05))
		local wb = 1 - lisse(k01(t, R, R + 0.5))
		for _, b in rig do
			local m, i = b[1], b[2]
			local cf = if i == 1 then CFrame.new(0, -chute * L, 0) else pa[i]:Lerp(pb[i], k)
			if tremble > 0 and i > 1 and i < 10 then
				cf *= CFrame.Angles(math.noise(t * 19, b[5]) * tremble, 0, math.noise(t * 23, b[5] + 5) * tremble)
			end
			if wb < 1 then
				local cur = m.Transform
				if cur ~= b[4] then b[3] = cur end -- l'animateur a réécrit : nouvelle base
				cf = b[3]:Lerp(cf, wb)
			end
			m.Transform = cf
			b[4] = cf
		end
	end

	-- sons
	local feu = son(e, SON.feu, 0, 1, true)
	quand(e, 0.2, function() feu:Play() end)
	quand(e, 0.3, function() Outils.jouer("grondement", 0.45, 0.5) end)
	bruit(e, 0.6, SON.clochette, 0.4, 0.8)
	bruit(e, 1.3, SON.clochette, 0.5, 0.65)
	bruit(e, TP, SON.souffle, 0.8, 0.5, 0.25)
	quand(e, TP, function() Outils.jouer("grondement", 0.35, 0.6) end)
	bruit(e, TS, SON.souffle, 0.8, 0.8)
	bruit(e, TS, SON.criBraise, 0.9, 0.85)
	bruit(e, TI, SON.impactRoche, 0.9, 0.9, 0.5)
	bruit(e, TI, SON.rocheSol, 0.7, 0.7)
	quand(e, TI + 0.4, function() Outils.jouer("grondement", 0.4, 0.55) end)
	bruit(e, TG, SON.souffle, 0.9, 0.55)
	bruit(e, TX, SON.impactRoche, 1, 0.6)
	bruit(e, TX, SON.rocheCasse2, 1, 0.7)
	bruit(e, TX, SON.statue, 0.8, 0.8)
	bruit(e, R, SON.criBraise2, 1, 0.75)

	quand(e, 0.3, function() montee.Rate = 50 end)
	quand(e, TP + 0.3, function() feuPortail.Rate = 80 end)
	quand(e, TS, function()
		echelle(s0 * 0.85)
		masquer(e, false)
	end)
	quand(e, TI, function()
		montee.Rate = 0
		souffleSol:Emit(20)
		braisesAir.Rate = 15
		flammes.Rate = 12
	end)
	for k, b in braisesSol do
		quand(e, TI + 0.25 + (k - 1) * 0.13, function()
			TweenService:Create(b, TweenInfo.new(0.3), {Transparency = 0.15}):Play()
		end)
	end
	quand(e, TI + 0.3, function() feuPortail.Rate = 0 end)
	quand(e, TX, function()
		echelle(s0)
		braisesAir.Rate = 0
		flammes.Rate = 200
		fumee.Rate = 45
		souffleSol:Emit(60)
		gerbe:Emit(90)
		Outils.secouer(1)
		Outils.jouer("impact", 0.3, 0.8)
		lueurSol.Brightness = 14
		TweenService:Create(lueurSol, TweenInfo.new(1.4), {Brightness = 2}):Play()
		TweenService:Create(rougeur, TweenInfo.new(0.9), {Transparency = 1}):Play()
		TweenService:Create(marque, TweenInfo.new(0.3), {Transparency = 0.05}):Play()
		for _, b in braisesSol do
			TweenService:Create(b, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 0.75}):Play()
		end
		local c = P - HAUT * 2
		for _, p in mottes do
			p.Transparency = 0
			projeter(p, c, rng)
		end
		local onde = piece(e, "Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2), Color = BRAISE, Material = Enum.Material.Neon,
			Transparency = 0.1, CFrame = CFrame.new(P + HAUT * 0.2) * CFrame.Angles(0, 0, math.pi / 2)})
		TweenService:Create(onde, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.3, rG * 4.5, rG * 4.5), Transparency = 1}):Play()
		local flash = piece(e, "Part", {Shape = Enum.PartType.Ball, Size = Vector3.one * 4, CFrame = CFrame.new(P + HAUT * (h * 0.3)), Color = Color3.fromRGB(255, 210, 120),
			Material = Enum.Material.Neon, Transparency = 0.05})
		TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.one * (h * 1.6), Transparency = 1}):Play()
	end)
	quand(e, TX + 1.2, function() flammes.Rate = 40 end)
	quand(e, TX + 2.2, function() flammes.Rate = 0 end)
	quand(e, TX + 3, function() fumee.Rate = 0 end)
	quand(e, R + 1.6, function()
		for _, p in mottes do
			if p.Parent then TweenService:Create(p, TweenInfo.new(0.8), {Transparency = 1}):Play() end
		end
	end)

	local depart = Q - av * 2 + HAUT * (h * 0.08)
	local herbeFinie, runesFinies, pose = false, false, false
	-- A : plongée presque verticale sur le rituel
	local HA = rr * 2.6 + h * 0.5
	local cibleA = Q + HAUT * (h * 0.25)
	local camA0 = Q + av * (HA * 0.32) + cote * (HA * 0.08) + HAUT * HA
	local camA1 = camA0 + (cibleA - camA0).Unit * (HA * 0.15)
	-- B : plan bas fixe sur le portail et la trajectoire
	local cibleB = Q:Lerp(P, 0.4) + HAUT * (h * 0.6)
	local camB0 = P + av * (h + 10) + cote * (h * 0.55) + HAUT * (h * 0.22)
	local camB1 = camB0 + (cibleB - camB0).Unit * 2
	-- C : plan rapproché sur le boss recroquevillé puis l'éclatement
	local cibleC = P + HAUT * (h * 0.42)
	local camC0 = P + av * (h * 0.9 + 9) + cote * (h * 0.25) + HAUT * (h * 0.12)
	local camC1 = camC0 + (cibleC - camC0).Unit * 3

	return function(t: number): CFrame?
		declencher(e, t)
		-- cercle runique
		if not runesFinies then
			local fin = k01(t, TI, TI + 0.8)
			for _, r in runes do
				local p = r[1]
				if r[6] < 1 then
					local g = k01(t, r[4], r[4] + 0.2)
					if g > 0 then
						r[6] = g
						p.Size = Vector3.new(r[5].X * g, r[5].Y, r[5].Z)
					end
				end
				p.CFrame = CFrame.new(Q) * CFrame.Angles(0, t * 0.5 * r[3], 0) * r[2]
				p.Transparency = math.max(1 - r[6], fin)
			end
			lumiereCercle.Brightness = 4 * k01(t, 0.2, 2) * (1 - fin)
			runesFinies = fin >= 1
		end
		-- portail
		local s = ouverture(t)
		if s > 0.01 then
			local d = Dp * s * (1 + 0.03 * math.sin(t * 9))
			bord.Size = Vector3.new(0.5, d, d)
			fond.Size = Vector3.new(0.6, d * 0.86, d * 0.86)
			centre.Size = Vector3.new(0.7, d * 0.45, d * 0.45)
			for k, p in spirale do
				p.Size = Vector3.new(0.8, d * 0.4, 0.45 * s)
				p.CFrame = cfP * CFrame.Angles(t * 3 + k * math.pi / 3, 0, 0) * CFrame.new(0, d * 0.2, 0)
			end
			lumierePortail.Brightness = 6 * s
			if not portailVisible then
				portailVisible = true
				bord.Transparency, fond.Transparency, centre.Transparency = 0, 0, 0.3
				for _, p in spirale do p.Transparency = 0 end
			end
		elseif portailVisible then
			portailVisible = false
			bord.Transparency, fond.Transparency, centre.Transparency = 1, 1, 1
			for _, p in spirale do p.Transparency = 1 end
			lumierePortail.Brightness = 0
		end
		-- bond hors du portail, en arc vers la caméra
		if t >= TS then
			if t < TI then
				local kj = k01(t, TS, TI)
				local pos = depart:Lerp(P, kj) + HAUT * (4 * kj * (1 - kj) * h * 0.55)
				poser(e, CFrame.new(pos) * e.rot * CFrame.Angles(-0.3 * math.sin(kj * math.pi), 0, 0))
			elseif t < TG then
				local a = 0.15 * k01(t, TI + 0.3, TG)
				poser(e, e.pivot * CFrame.new(math.noise(t * 21, 3) * a, 0, math.noise(t * 19, 11) * a))
			elseif not pose then
				pose = true
				poser(e, e.pivot)
			end
			if t >= TG and t < TX then echelle(s0 * (0.85 + 0.15 * lisse(k01(t, TG, TX)))) end
			if t < R + 0.5 then animer(t) end
		end
		-- recroquevillé : braises qui s'accumulent, le sol rougit
		if t >= TI and t < TX then
			local g = k01(t, TI, TG)
			braisesAir.Rate = 15 + 110 * g
			rougeur.Transparency = 1 - 0.6 * g
			lueurSol.Brightness = 5 * g
		end
		-- l'herbe brûle : orange, noircit, se recroqueville, disparaît
		if t >= TX and not herbeFinie then
			local reste = false
			for _, b in touffes do
				if b[6] < 1 then
					local g = k01(t, TX + b[3], TX + b[3] + 0.9)
					b[6] = g
					local p = b[1]
					if g >= 1 then
						p.Transparency = 1
					else
						reste = true
						p.Material = if g > 0 and g < 0.35 then Enum.Material.Neon else Enum.Material.SmoothPlastic
						p.Color = if g < 0.3 then b[2]:Lerp(BRAISE, g / 0.3) else BRAISE:Lerp(CENDRE, math.min(1, (g - 0.3) / 0.3))
						if g > 0.55 then
							local ht = b[5] * math.max(1 - (g - 0.55) / 0.45, 0.05)
							p.Size = Vector3.new(0.25, ht, 0.7)
							p.CFrame = b[4] * CFrame.new(0, (ht - b[5]) / 2, 0)
						end
					end
				end
			end
			herbeFinie = not reste
		end
		feu.Volume = (0.35 * k01(t, 0.2, 2) + 0.45 * k01(t, TX, TX + 0.2)) * (1 - k01(t, R + 0.8, R + 2.2))
		if t >= R then return nil end
		if t < TA then return plan(e, camA0, camA1, cibleA, 60, 56, lisse(t / TA)) end
		if t < TC then return plan(e, camB0, camB1, cibleB, 62, 60, lisse(k01(t, TA, TC))) end
		return plan(e, camC0, camC1, cibleC, 62, 58, lisse(k01(t, TC, R)))
	end
end

-- ================= API =================
local ENTREES = {TitanCristal = titan, ReineAraignee = reine, SeigneurBraise = braise}

local Entrees = {}

function Entrees.creer(id: string?, boss: Model?, cinema: Instance, R: number)
	local f = id and ENTREES[id]
	if not f then
		warn("[BossEntrees] pas d'entrée pour le boss « " .. tostring(id) .. " » : plan fixe de secours")
		return nil
	end
	if not boss or not boss.Parent then
		warn("[BossEntrees] modèle du boss absent chez ce client (" .. tostring(id) .. ") : plan fixe de secours")
		return nil
	end
	if not boss.PrimaryPart then
		warn("[BossEntrees] le modèle " .. boss:GetFullName() .. " n'a pas de PrimaryPart (Root) : plan fixe de secours")
		return nil
	end
	local e = nouvelle(boss)
	local ok, pas = pcall(f, e, R, cinema)
	if not ok then
		warn("[BossEntrees] erreur à la préparation de " .. tostring(id) .. " : " .. tostring(pas))
		finBase(e)
		return nil
	end
	table.sort(e.evts, function(a, b) return a[1] < b[1] end)
	return {pas = pas, fin = function() finBase(e) end}
end

return Entrees
