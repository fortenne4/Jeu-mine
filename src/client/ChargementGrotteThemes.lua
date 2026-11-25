-- Grottes profondes · CLIENT, thèmes de l'écran de chargement (module de ChargementGrotte.client.lua).
-- Un « fond d'écran » par palier, entièrement dessiné en UI (Frames, dégradés, contours ; aucune image importée) :
-- couches de parallaxe (loin / milieu / proche), particules, palette du thème, titre, astuces et couleurs de la
-- veine que la pioche mine. Chaque objet est dessiné par une fonction du kit (poutre veinée, cristal à facettes,
-- flamme à langues, bain de métal en fusion, fissure ramifiée…) pour rester lisible et réutilisable.
-- Chaque décor est construit une seule fois (au premier passage) puis réutilisé ; l'animation ne touche qu'aux
-- éléments qui bougent (une fonction animer(t) par décor, appelée par le script principal).
-- API : Themes.get(niveauId) → thème ; Themes.kit → outils de dessin (partagés avec la barre et la pioche).
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait = UI.creer, UI.coin, UI.trait

local BLANC, NOIR = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local CENTRE = Vector2.new(0.5, 0.5)
local BAS = Vector2.new(0.5, 1)
local HAUT = Vector2.new(0.5, 0)
local YY = Enum.SizeConstraint.RelativeYY

-- ================= Kit de dessin =================
local K = {}
local ratios = setmetatable({}, {__mode = "k"}) -- largeur / hauteur de chaque groupe (pour les formes en biais)

function K.rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local rgb = K.rgb

function K.seq(points: {any}): ColorSequence
	local k = {}
	for _, p in points do
		table.insert(k, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(k)
end

function K.transp(points: {{number}}): NumberSequence
	local k = {}
	for _, p in points do
		table.insert(k, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(k)
end

function K.degrade(parent: Instance?, couleurs: ColorSequence?, rotation: number?, transparence: NumberSequence?): UIGradient
	local p: {[string]: any} = {Rotation = rotation or 90, Parent = parent}
	if couleurs then p.Color = couleurs end
	if transparence then p.Transparency = transparence end
	return creer("UIGradient", p)
end

-- Relief (clair d'un côté, sombre de l'autre) pour la roche, le bois, les cristaux
function K.relief(c: Color3): ColorSequence
	return K.seq({{0, c:Lerp(BLANC, 0.2)}, {0.2, c:Lerp(BLANC, 0.07)}, {0.6, c}, {1, c:Lerp(NOIR, 0.45)}})
end

-- Métal poli : bande de reflet franche, puis ombre
function K.metal(c: Color3): ColorSequence
	return K.seq({{0, c:Lerp(BLANC, 0.5)}, {0.22, c:Lerp(BLANC, 0.2)}, {0.45, c}, {0.52, c:Lerp(NOIR, 0.28)}, {0.8, c:Lerp(NOIR, 0.12)}, {1, c:Lerp(NOIR, 0.5)}})
end

-- Groupe aux proportions fixes : w × h en hauteurs du parent ; ses enfants se placent en 0..1
function K.groupe(parent: Instance, x: number, y: number, w: number, h: number, ancre: Vector2?, z: number?): Frame
	local g = creer("Frame", {AnchorPoint = ancre or BAS, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
		SizeConstraint = YY, BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent})
	ratios[g] = w / h
	return g
end

function K.ratio(g: Instance, r: number)
	ratios[g] = r
end

-- Rectangle (ancré au centre par défaut) ; props et enfants optionnels
function K.bloc(g: Instance, x: number, y: number, w: number, h: number, couleur: Color3, props: {[string]: any}?, enfants: {Instance}?): Frame
	local p: {[string]: any} = {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
		BackgroundColor3 = couleur, BorderSizePixel = 0, Parent = g}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	return creer("Frame", p, enfants)
end

-- Ellipse (tailles dans les unités du groupe)
function K.ellipse(g: Instance, x: number, y: number, w: number, h: number, couleur: Color3, transp: number?, enfants: {Instance}?): Frame
	local e = K.bloc(g, x, y, w, h, couleur, {BackgroundTransparency = transp or 0}, enfants)
	coin(0.5).Parent = e
	return e
end

-- Forme allongée tournée (feuille, pétale, éclat) : longueur l et épaisseur e en hauteurs du groupe
function K.feuille(g: Instance, x: number, y: number, l: number, e: number, rot: number, couleur: Color3, transp: number?, enfants: {Instance}?, carre: boolean?): Frame
	local ar = ratios[g] or 1
	local f = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(l / ar, e), Rotation = rot,
		BackgroundColor3 = couleur, BackgroundTransparency = transp or 0, BorderSizePixel = 0, Parent = g}, enfants)
	if not carre then coin(0.5).Parent = f end
	return f
end

-- Segment de a à b (coordonnées du groupe), épaisseur en hauteurs du groupe
function K.seg(g: Instance, ax: number, ay: number, bx: number, by: number, ep: number, couleur: Color3, transp: number?, z: number?): Frame
	local ar = ratios[g] or 1
	local dx, dy = (bx - ax) * ar, by - ay
	local l = math.sqrt(dx * dx + dy * dy)
	return creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale((ax + bx) / 2, (ay + by) / 2), Size = UDim2.fromScale(l / ar, ep),
		Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = couleur, BackgroundTransparency = transp or 0, BorderSizePixel = 0,
		ZIndex = z or 1, Parent = g})
end

-- Décale un segment perpendiculairement (off en hauteurs du groupe)
function K.decaler(g: Instance, ax: number, ay: number, bx: number, by: number, off: number): (number, number, number, number)
	local ar = ratios[g] or 1
	local dx, dy = (bx - ax) * ar, by - ay
	local l = math.sqrt(dx * dx + dy * dy)
	if l == 0 then return ax, ay, bx, by end
	local nx, ny = -dy / l, dx / l
	return ax + nx * off / ar, ay + ny * off, bx + nx * off / ar, by + ny * off
end

function K.disque(g: Instance, x: number, y: number, d: number, couleur: Color3, transp: number?, z: number?): Frame
	return creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d, d), SizeConstraint = YY,
		BackgroundColor3 = couleur, BackgroundTransparency = transp or 0, BorderSizePixel = 0, ZIndex = z or 1, Parent = g}, {coin(0.5)})
end

-- Rivet bombé (tête claire, reflet)
function K.rivet(g: Instance, x: number, y: number, d: number, couleur: Color3?)
	local c = couleur or rgb(170, 168, 176)
	local r = K.disque(g, x, y, d, c, 0)
	K.degrade(r, K.seq({{0, c:Lerp(BLANC, 0.6)}, {0.5, c}, {1, c:Lerp(NOIR, 0.6)}}), 45)
	trait(c:Lerp(NOIR, 0.75), 1).Parent = r
end

-- Lueur douce : disques concentriques (faux dégradé radial) ; l'UIScale sert à la faire respirer
function K.lueur(g: Instance, x: number, y: number, d: number, couleur: Color3, base: number, z: number?, anneaux: number?): (Frame, UIScale)
	local l = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d, d), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z or 1, Parent = g})
	local n = anneaux or 3
	for k = 1, n do
		local s = 0.3 + 0.7 * k / n
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = couleur,
			BackgroundTransparency = math.min(0.975, base + k / n * 0.1), BorderSizePixel = 0, ZIndex = z or 1, Parent = l}, {coin(0.5)})
	end
	return l, creer("UIScale", {Parent = l})
end

-- Ombre portée douce au sol
function K.ombre(g: Instance, x: number, y: number, w: number, h: number, transp: number?)
	K.ellipse(g, x, y, w, h, NOIR, transp or 0.4, {K.degrade(nil, nil, 0, K.transp({{0, 1}, {0.25, 0.1}, {0.75, 0.1}, {1, 1}}))})
end

-- Pic en marches (style voxel) : stalactite (versBas) ou stalagmite ; goutte lumineuse optionnelle au bout
function K.pic(parent: Instance, x: number, y: number, w: number, h: number, couleur: Color3, versBas: boolean, marches: number?, z: number?, goutte: Color3?): Frame
	local n = marches or 5
	local g = K.groupe(parent, x, y, w, h, if versBas then HAUT else BAS, z)
	local relief = K.relief(couleur)
	for i = 0, n - 1 do
		local f = 1 - i / n
		local yy = if versBas then i / n else 1 - (i + 1) / n
		creer("Frame", {Position = UDim2.fromScale((1 - f) / 2, yy - 0.004), Size = UDim2.fromScale(f, 1 / n + 0.008), BackgroundColor3 = BLANC,
			BorderSizePixel = 0, ZIndex = z or 1, Parent = g}, {creer("UIGradient", {Rotation = 0, Color = relief})})
		-- arête éclairée sur la marche
		creer("Frame", {Position = UDim2.fromScale((1 - f) / 2, if versBas then yy + 1 / n - 0.012 else yy), Size = UDim2.fromScale(f, 0.012),
			BackgroundColor3 = couleur:Lerp(BLANC, 0.35), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = z or 1, Parent = g})
	end
	if goutte then
		K.disque(g, 0.5, if versBas then 1.01 else -0.01, 0.035, goutte, 0.1, z)
	end
	return g
end

-- Rangée de pics le long du plafond (versBas) ou du sol
function K.rangee(parent: Instance, rng: Random, n: number, couleur: Color3, hMin: number, hMax: number, wMin: number, wMax: number, versBas: boolean, y: number, z: number?, goutte: Color3?)
	for i = 1, n do
		local x = (i - 0.5) / n + rng:NextNumber(-0.3, 0.3) / n
		K.pic(parent, x, y, rng:NextNumber(wMin, wMax), rng:NextNumber(hMin, hMax), couleur, versBas, rng:NextInteger(4, 6), z,
			if goutte and rng:NextNumber() < 0.5 then goutte else nil)
	end
end

-- Sol en blocs (silhouette) du bas de l'écran à partir de y, arête supérieure éclairée
function K.sol(parent: Instance, rng: Random, couleur: Color3, y: number, z: number?, arete: Color3?)
	local x = -0.02
	while x < 1.02 do
		local w = rng:NextNumber(0.05, 0.11)
		local h = (1 - y) + rng:NextNumber(-0.02, 0.04)
		local b = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(x, 1.01), Size = UDim2.fromScale(w + 0.004, h),
			BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = z or 1, Parent = parent},
			{creer("UIGradient", {Rotation = 90, Color = K.seq({{0, couleur:Lerp(BLANC, 0.14)}, {0.12, couleur}, {1, couleur:Lerp(NOIR, 0.55)}})})})
		creer("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = arete or couleur:Lerp(BLANC, 0.3), BackgroundTransparency = 0.35,
			BorderSizePixel = 0, ZIndex = z or 1, Parent = b})
		x += w
	end
end

-- Rocher en strates (trois couches en relief, arêtes, fissures, mousse optionnelle)
function K.rocher(parent: Instance, x: number, yBas: number, w: number, h: number, couleur: Color3, rng: Random, mousse: Color3?, z: number?): Frame
	local g = K.groupe(parent, x, yBas, w, h, BAS, z)
	local dessin = {{0.5, 1, 1, 0.55}, {0.5 + rng:NextNumber(-0.1, 0.1), 0.48, 0.78, 0.34}, {0.5 + rng:NextNumber(-0.14, 0.14), 0.17, 0.5, 0.24}}
	for i, s in dessin do
		local c = couleur:Lerp(BLANC, (i - 1) * 0.05)
		K.bloc(g, s[1], s[2], s[3], s[4], BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(c), 0), trait(couleur:Lerp(NOIR, 0.6), 1.5)})
		K.bloc(g, s[1], s[2] - s[4], s[3], 0.05, c:Lerp(BLANC, 0.3), {AnchorPoint = HAUT, BackgroundTransparency = 0.35})
	end
	for _ = 1, 2 do
		local cx = rng:NextNumber(0.25, 0.75)
		K.seg(g, cx, 0.5, cx + rng:NextNumber(-0.1, 0.1), 0.85, 0.025, couleur:Lerp(NOIR, 0.65), 0.2)
	end
	if mousse then
		local top = dessin[3]
		for k = 1, 4 do
			K.ellipse(g, top[1] + (k - 2.5) * top[3] * 0.25, top[2] - top[4] + 0.01, top[3] * 0.32, 0.09, mousse:Lerp(NOIR, (k % 2) * 0.25), 0,
				{K.degrade(nil, K.seq({{0, mousse:Lerp(BLANC, 0.25)}, {1, mousse:Lerp(NOIR, 0.4)}}), 90)})
		end
	end
	return g
end

-- Poutre en bois dans le rectangle (gx, gy, w, h) d'un groupe (coin haut-gauche) ; detail 1 à 3 :
-- 1 = relief seul ; 2 = veinures, nœuds, arête ; 3 = + ferrures rivetées, chevilles, échardes
function K.poutre(g: Instance, gx: number, gy: number, w: number, h: number, couleur: Color3, rng: Random, detail: number, z: number?)
	local ar = ratios[g] or 1
	local vertical = h > w * ar
	local ep = if vertical then w * ar else h -- épaisseur en hauteurs du groupe
	local long = if vertical then h else w * ar -- longueur en hauteurs du groupe
	local travers = ep / long
	local rotTravers = if vertical then 0 else 90
	local rotFil = if vertical then 90 else 0
	local function rect(u: number, v: number, su: number, sv: number, c: Color3, props: {[string]: any}?, enfants: {Instance}?): Frame
		local x, y, sx, sy
		if vertical then
			x, y, sx, sy = gx + v * w, gy + u * h, sv * w, su * h
		else
			x, y, sx, sy = gx + u * w, gy + v * h, su * w, sv * h
		end
		local p: {[string]: any} = {ZIndex = z or 1}
		if props then
			for k, val in props do p[k] = val end
		end
		return K.bloc(g, x, y, sx, sy, c, p, enfants)
	end
	rect(0.5, 0.5, 1, 1, BLANC, nil, {K.degrade(nil, K.seq({{0, couleur:Lerp(BLANC, 0.24)}, {0.14, couleur:Lerp(BLANC, 0.08)}, {0.62, couleur},
		{1, couleur:Lerp(NOIR, 0.52)}}), rotTravers), trait(couleur:Lerp(NOIR, 0.7), 1.5)})
	if detail <= 1 then return end
	-- veinures (fil du bois)
	for _ = 1, 2 + detail do
		local l = rng:NextNumber(0.35, 0.85)
		rect(rng:NextNumber(l / 2, 1 - l / 2), rng:NextNumber(0.18, 0.86), l, 0.04, couleur:Lerp(NOIR, 0.55), {BackgroundTransparency = 0.4},
			{K.degrade(nil, nil, rotFil, K.transp({{0, 1}, {0.2, 0.25}, {0.8, 0.25}, {1, 1}}))})
	end
	-- arête éclairée
	rect(0.5, 0.07, 1, 0.06, couleur:Lerp(BLANC, 0.45), {BackgroundTransparency = 0.5})
	-- nœuds (aplatis dans le sens du fil, auréole plus sombre)
	for _ = 1, detail - 1 do
		local u, v = rng:NextNumber(0.25, 0.75), rng:NextNumber(0.35, 0.65)
		rect(u, v, 0.6 * travers * 1.9, 0.5, couleur:Lerp(NOIR, 0.3), {BackgroundTransparency = 0.45}, {coin(0.5)})
		rect(u, v, 0.3 * travers * 1.9, 0.25, couleur:Lerp(NOIR, 0.68), nil, {coin(0.5), trait(couleur:Lerp(BLANC, 0.1), 1, 0.5)})
	end
	if detail < 3 then return end
	-- ferrures aux deux bouts, rivetées
	local fer = rgb(92, 90, 98)
	for _, u in {0.06, 0.94} do
		rect(u, 0.5, 0.045 / travers * travers * 0.9, 1.14, BLANC, nil, {K.degrade(nil, K.metal(fer), rotFil), trait(rgb(24, 22, 26), 1.5)})
		for _, v in {0.28, 0.72} do
			rect(u, v, 0.17 * travers, 0.17, rgb(186, 184, 192), nil, {coin(0.5), trait(rgb(30, 28, 32), 1),
				K.degrade(nil, K.seq({{0, rgb(240, 240, 246)}, {1, rgb(90, 88, 96)}}), 45)})
		end
	end
	-- chevilles de bois
	for _, u in {0.2, 0.8} do
		rect(u, 0.5, 0.26 * travers, 0.26, couleur:Lerp(NOIR, 0.35), nil, {coin(0.5), trait(couleur:Lerp(NOIR, 0.75), 1),
			K.degrade(nil, K.seq({{0, couleur:Lerp(BLANC, 0.2)}, {1, couleur:Lerp(NOIR, 0.55)}}), 45)})
	end
	-- échardes qui dépassent de l'arête
	for _ = 1, 3 do
		local u = rng:NextNumber(0.15, 0.85)
		local ax, ay, bx, by
		if vertical then
			ax, ay = gx + w * 0.97, gy + u * h
			bx, by = ax + ep * 0.4 / ar, ay - ep * 1.2
		else
			ax, ay = gx + u * w, gy + h * 0.97
			bx, by = ax + ep * 1.2 / ar, ay + ep * 0.35
		end
		K.seg(g, ax, ay, bx, by, ep * 0.09, couleur:Lerp(BLANC, 0.3), 0, z)
	end
end

-- Jambe de force en biais : bois en relief, veinure, arête, boulons aux bouts
function K.jambe(g: Instance, ax: number, ay: number, bx: number, by: number, ep: number, couleur: Color3, z: number?)
	local f = K.seg(g, ax, ay, bx, by, ep, BLANC, 0, z)
	K.degrade(f, K.seq({{0, couleur:Lerp(BLANC, 0.22)}, {0.6, couleur}, {1, couleur:Lerp(NOIR, 0.5)}}), 90)
	trait(couleur:Lerp(NOIR, 0.7), 1.5).Parent = f
	local a1, b1, a2, b2 = K.decaler(g, ax, ay, bx, by, -ep * 0.32)
	K.seg(g, a1, b1, a2, b2, ep * 0.1, couleur:Lerp(BLANC, 0.4), 0.45, z)
	local c1, d1, c2, d2 = K.decaler(g, ax, ay, bx, by, ep * 0.12)
	K.seg(g, c1 + (c2 - c1) * 0.15, d1 + (d2 - d1) * 0.15, c1 + (c2 - c1) * 0.8, d1 + (d2 - d1) * 0.8, ep * 0.07, couleur:Lerp(NOIR, 0.5), 0.4, z)
	K.rivet(g, ax + (bx - ax) * 0.1, ay + (by - ay) * 0.1, ep * 0.45)
	K.rivet(g, ax + (bx - ax) * 0.9, ay + (by - ay) * 0.9, ep * 0.45)
end

-- Cadre de mine : deux poteaux, chapeau, jambes de force, équerres de fer
function K.cadreMine(parent: Instance, x: number, yBas: number, w: number, h: number, couleur: Color3, rng: Random, detail: number, z: number?): Frame
	local g = K.groupe(parent, x, yBas, w, h, BAS, z)
	local ep = 0.11
	K.poutre(g, 0, 0.08, ep, 0.92, couleur, rng, detail, z)
	K.poutre(g, 1 - ep, 0.08, ep, 0.92, couleur, rng, detail, z)
	K.poutre(g, -0.05, 0, 1.1, 0.105, couleur, rng, detail, z)
	if detail >= 2 then
		K.jambe(g, 0.1, 0.38, 0.32, 0.1, 0.045, couleur:Lerp(NOIR, 0.08), z)
		K.jambe(g, 0.9, 0.38, 0.68, 0.1, 0.045, couleur:Lerp(NOIR, 0.08), z)
		for _, px in {ep / 2, 1 - ep / 2} do -- équerres
			K.bloc(g, px, 0.13, ep * 1.25, 0.05, rgb(70, 68, 74), {ZIndex = z or 1}, {K.degrade(nil, K.metal(rgb(80, 78, 86)), 90), trait(rgb(20, 20, 24), 1)})
			K.rivet(g, px, 0.13, 0.025)
		end
	else
		K.seg(g, 0.1, 0.36, 0.3, 0.1, 0.04, couleur:Lerp(NOIR, 0.2), 0, z)
		K.seg(g, 0.9, 0.36, 0.7, 0.1, 0.04, couleur:Lerp(NOIR, 0.2), 0, z)
	end
	return g
end

-- Colonne naine : base, fût cannelé, chapiteau (ou sommet brisé), mousse au pied
function K.colonne(parent: Instance, x: number, yBas: number, w: number, h: number, couleur: Color3, cassee: boolean, mousse: Color3?, z: number?): Frame
	local g = K.groupe(parent, x, yBas, w, h, BAS, z)
	local relief = K.relief(couleur)
	local function morceau(cx, cy, cw, ch, anc)
		K.bloc(g, cx, cy, cw, ch, BLANC, {AnchorPoint = anc or CENTRE}, {K.degrade(nil, relief, 0), trait(couleur:Lerp(NOIR, 0.55), 1)})
	end
	morceau(0.5, 1, 1, 0.06, BAS)
	morceau(0.5, 0.94, 0.86, 0.04, BAS)
	local haut = if cassee then 0.32 else 0.12
	morceau(0.5, 0.9, 0.7, 0.9 - haut, BAS)
	for k = 1, 3 do -- cannelures
		K.bloc(g, 0.15 + k * 0.175, (0.9 + haut) / 2, 0.035, 0.9 - haut - 0.04, couleur:Lerp(NOIR, 0.4), {BackgroundTransparency = 0.45})
	end
	if cassee then
		morceau(0.36, haut + 0.02, 0.34, 0.06)
		morceau(0.62, haut - 0.01, 0.16, 0.05)
		K.seg(g, 0.4, haut + 0.02, 0.55, 0.55, 0.012, couleur:Lerp(NOIR, 0.65), 0.2)
	else
		morceau(0.5, 0.1, 0.86, 0.04)
		morceau(0.5, 0.055, 1, 0.055)
	end
	if mousse then
		K.ellipse(g, 0.5, 0.95, 1.1, 0.06, mousse, 0.1, {K.degrade(nil, K.seq({{0, mousse:Lerp(BLANC, 0.25)}, {1, mousse:Lerp(NOIR, 0.35)}}), 90)})
		K.ellipse(g, 0.3, 0.6, 0.35, 0.04, mousse, 0.35)
	end
	return g
end

-- Cristal à facettes : corps, pointe, arête centrale, liseré, reflet, lueur interne (pas de rotation)
function K.cristal(g: Instance, x: number, yBas: number, w: number, h: number, c1: Color3, c2: Color3, z: number?): Frame
	local cr = creer("Frame", {AnchorPoint = BAS, Position = UDim2.fromScale(x, yBas), Size = UDim2.fromScale(w, h), BackgroundTransparency = 1,
		ZIndex = z or 1, Parent = g})
	local facettes = K.seq({{0, c1:Lerp(BLANC, 0.5)}, {0.35, c1}, {0.5, c1:Lerp(c2, 0.4)}, {0.501, c2}, {1, c2:Lerp(NOIR, 0.45)}})
	local bord = c2:Lerp(NOIR, 0.55)
	creer("Frame", {Position = UDim2.fromScale(0, 0.18), Size = UDim2.fromScale(1, 0.82), BackgroundColor3 = BLANC, BorderSizePixel = 0,
		ZIndex = z or 1, Parent = cr}, {creer("UIGradient", {Rotation = 0, Color = facettes}), trait(bord, 1, 0.2)})
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.707, 0.707),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, Rotation = 45, BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = z or 1, Parent = cr},
		{creer("UIGradient", {Rotation = -45, Color = facettes}), trait(bord, 1, 0.2)})
	creer("Frame", {AnchorPoint = HAUT, Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.06, 0.78), BackgroundColor3 = c1:Lerp(BLANC, 0.65),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = z or 1, Parent = cr})
	creer("Frame", {AnchorPoint = HAUT, Position = UDim2.fromScale(0.2, 0.28), Size = UDim2.fromScale(0.09, 0.45), BackgroundColor3 = BLANC,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = z or 1, Parent = cr}, {coin(0.5)})
	creer("Frame", {AnchorPoint = BAS, Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.4), BackgroundColor3 = c1,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = z or 1, Parent = cr}, {creer("UIGradient", {Rotation = 90, Transparency = K.transp({{0, 1}, {1, 0.2}})})})
	return cr
end

-- Amas de cristaux sur un socle de roche + lueur ; renvoie l'UIScale de la lueur
function K.amas(parent: Instance, x: number, yBas: number, h: number, c1: Color3, c2: Color3, rng: Random, roche: Color3?, z: number?): UIScale
	local g = K.groupe(parent, x, yBas, h * 1.3, h, BAS, z)
	local _, s = K.lueur(g, 0.5, 0.65, 1.5, c1, 0.82, z, 5)
	local ordre = {2, 4, 1, 5, 3}
	for _, i in ordre do
		local hh = if i == 3 then 1 else rng:NextNumber(0.35, 0.8)
		K.cristal(g, 0.12 + (i - 1) * 0.19 + rng:NextNumber(-0.03, 0.03), 0.97, if i == 3 then 0.2 else rng:NextNumber(0.11, 0.16), hh * 0.92, c1, c2, z)
	end
	local r = roche or rgb(40, 34, 40)
	K.ellipse(g, 0.5, 0.97, 1.05, 0.12, r, 0, {K.degrade(nil, K.relief(r), 90), trait(r:Lerp(NOIR, 0.6), 1)})
	for k = 1, 5 do
		K.disque(g, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.3, 0.9), 0.025, c1:Lerp(BLANC, 0.6), 0.2)
		local _ = k
	end
	return s
end

-- Flamme : corps rouge sombre, langues de feu animées, orange, jaune, cœur blanc-jaune, braises qui montent.
-- pal = {coeur, jaune, orange, rouge} ; renvoie la fonction d'animation
function K.feu(parent: Instance, x: number, yBas: number, h: number, pal, rng: Random, z: number?): (number) -> ()
	local g = K.groupe(parent, x, yBas, h * 0.62, h, BAS, z)
	local _, halo = K.lueur(g, 0.5, 0.66, 1.25, pal.orange, 0.83, z, 5)
	local fondu = K.transp({{0, 1}, {0.4, 0.25}, {1, 0}})
	K.bloc(g, 0.5, 1, 0.95, 0.7, pal.rouge, {AnchorPoint = BAS, BackgroundTransparency = 0.05}, {coin(0.5), K.degrade(nil, nil, 90, fondu)})
	local langues = {}
	for i = 1, 5 do
		local lx = 0.18 + (i - 1) * 0.16 + rng:NextNumber(-0.03, 0.03)
		local lh = rng:NextNumber(0.62, 1) * (1 - math.abs(lx - 0.5) * 1.1)
		local f = K.bloc(g, lx, 0.9, 0.2, lh, BLANC, {AnchorPoint = BAS}, {coin(0.5),
			K.degrade(nil, K.seq({{0, pal.rouge}, {0.45, pal.orange}, {1, pal.jaune}}), 90, K.transp({{0, 1}, {0.3, 0.2}, {1, 0}}))})
		table.insert(langues, {f, lx, lh, rng:NextNumber(0, 6.28), rng:NextNumber(7, 12)})
	end
	local orange = K.bloc(g, 0.5, 0.98, 0.72, 0.6, BLANC, {AnchorPoint = BAS}, {coin(0.5),
		K.degrade(nil, K.seq({{0, pal.orange:Lerp(pal.rouge, 0.5)}, {0.6, pal.orange}, {1, pal.orange:Lerp(pal.jaune, 0.3)}}), 90, fondu)})
	local jaune = K.bloc(g, 0.5, 0.98, 0.46, 0.42, BLANC, {AnchorPoint = BAS}, {coin(0.5),
		K.degrade(nil, K.seq({{0, pal.jaune:Lerp(pal.orange, 0.4)}, {1, pal.jaune}}), 90, fondu)})
	K.bloc(g, 0.5, 0.97, 0.26, 0.25, pal.coeur, {AnchorPoint = BAS}, {coin(0.5), K.degrade(nil, nil, 90, K.transp({{0, 0.7}, {0.45, 0.05}, {1, 0}}))})
	local braises = {}
	for _ = 1, 6 do
		local b = K.disque(g, 0.5, 0.5, rng:NextNumber(0.02, 0.04), pal.jaune:Lerp(pal.coeur, 0.3), 0)
		table.insert(braises, {b, rng:NextNumber(0.25, 0.75), rng:NextNumber(0, 1), rng:NextNumber(0.35, 0.75)})
	end
	return function(t: number)
		for _, l in langues do
			local s = 1 + 0.2 * math.sin(t * l[5] + l[4]) + 0.08 * math.sin(t * l[5] * 1.9 + l[4])
			l[1].Size = UDim2.fromScale(0.2 * (1.1 - 0.15 * s), l[3] * s)
			l[1].Position = UDim2.fromScale(l[2] + 0.035 * math.sin(t * 3.1 + l[4]), 0.9)
		end
		local p = 1 + 0.06 * math.sin(t * 13) + 0.035 * math.sin(t * 7.3)
		orange.Size = UDim2.fromScale(0.72, 0.6 * p)
		jaune.Size = UDim2.fromScale(0.46, 0.42 * (2 - p))
		halo.Scale = 0.94 + 0.12 * (p - 0.9)
		for _, b in braises do
			local ph = (b[3] + t * b[4]) % 1
			b[1].Position = UDim2.fromScale(b[2] + math.sin(ph * 8 + b[3] * 6) * 0.1, 0.5 - ph * 0.62)
			b[1].BackgroundTransparency = ph
		end
	end
end

-- Coulée (eau, lave, métal) : aura, corps avec cœur brillant, traînées qui descendent, gerbe au pied
function K.coulee(parent: Instance, x: number, y0: number, w: number, h: number, bord: Color3, milieu: Color3, coeur: Color3, rng: Random, z: number?): (number) -> ()
	creer("Frame", {AnchorPoint = HAUT, Position = UDim2.fromScale(x, y0), Size = UDim2.fromScale(w * 2.4, h), SizeConstraint = YY,
		BackgroundColor3 = milieu, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = z or 1, Parent = parent},
		{coin(0.5), K.degrade(nil, nil, 0, K.transp({{0, 1}, {0.5, 0.2}, {1, 1}}))})
	local c = creer("Frame", {AnchorPoint = HAUT, Position = UDim2.fromScale(x, y0), Size = UDim2.fromScale(w, h), SizeConstraint = YY,
		BackgroundColor3 = BLANC, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = z or 1, Parent = parent},
		{K.degrade(nil, K.seq({{0, bord}, {0.22, milieu}, {0.5, coeur}, {0.78, milieu}, {1, bord}}), 0)})
	local traits = {}
	for _ = 1, 7 do
		local f = creer("Frame", {AnchorPoint = HAUT, Position = UDim2.fromScale(rng:NextNumber(0.2, 0.8), 0), Size = UDim2.fromScale(rng:NextNumber(0.08, 0.2), rng:NextNumber(0.08, 0.18)),
			BackgroundColor3 = coeur:Lerp(BLANC, 0.5), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = z or 1, Parent = c},
			{coin(0.5), K.degrade(nil, nil, 90, K.transp({{0, 1}, {0.5, 0.1}, {1, 1}}))})
		table.insert(traits, {f, rng:NextNumber(0, 1.4), rng:NextNumber(0.55, 1)})
	end
	local gerbe = {}
	for i = 1, 4 do
		local d = K.disque(parent, x, y0 + h, w * (0.8 + i * 0.25), coeur:Lerp(BLANC, 0.3), 0.4, z)
		table.insert(gerbe, {d, i})
	end
	return function(t: number)
		for _, s in traits do
			s[1].Position = UDim2.new(s[1].Position.X.Scale, 0, ((s[2] + t * s[3]) % 1.4) - 0.2, 0)
		end
		for _, b in gerbe do
			local ph = (t * 1.6 + b[2] * 0.25) % 1
			b[1].Size = UDim2.fromScale(w * (0.8 + ph * 2.2), w * (0.5 + ph * 1.2))
			b[1].BackgroundTransparency = 0.3 + ph * 0.7
		end
	end
end

-- Bain de métal en fusion : rebord, faux dégradé radial (rouge → orange → jaune → blanc), croûtes rougeoyantes,
-- bulles qui éclatent ; renvoie la fonction d'animation
function K.bain(parent: Instance, x: number, y: number, w: number, h: number, rng: Random, rebord: Color3?, z: number?): (number) -> ()
	local g = K.groupe(parent, x, y, w, h, CENTRE, z)
	local _, halo = K.lueur(g, 0.5, 0.4, w / h * 0.9, rgb(255, 140, 40), 0.82, z, 5)
	local r = rebord or rgb(40, 34, 34)
	K.ellipse(g, 0.5, 0.55, 1.06, 1.15, r, 0, {K.degrade(nil, K.relief(r), 90), trait(r:Lerp(NOIR, 0.6), 1.5)})
	K.ellipse(g, 0.5, 0.5, 1, 1, rgb(190, 40, 12))
	K.ellipse(g, 0.5, 0.5, 0.84, 0.78, rgb(250, 110, 24))
	K.ellipse(g, 0.5, 0.48, 0.62, 0.52, rgb(255, 180, 50))
	local coeur = K.ellipse(g, 0.5, 0.46, 0.34, 0.26, rgb(255, 245, 190))
	local croutes = {}
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local cx, cy = 0.5 + math.cos(a) * 0.33, 0.5 + math.sin(a) * 0.3
		local f = K.ellipse(g, cx, cy, rng:NextNumber(0.1, 0.18), rng:NextNumber(0.12, 0.2), rgb(52, 26, 18), 0,
			{trait(rgb(255, 150, 40), 1.5, 0.15), K.degrade(nil, K.seq({{0, rgb(80, 40, 28)}, {1, rgb(30, 14, 10)}}), 90)})
		table.insert(croutes, {f, cx, cy, rng:NextNumber(0, 6.28)})
	end
	local bulles = {}
	for _ = 1, 6 do
		local b = K.ellipse(g, 0.5, 0.5, 0.06, 0.06, rgb(255, 230, 150), 0, {trait(rgb(255, 250, 220), 1, 0.2)})
		table.insert(bulles, {b, rng:NextNumber(0.25, 0.75), rng:NextNumber(0.3, 0.7), rng:NextNumber(0, 1), rng:NextNumber(0.5, 0.9)})
	end
	return function(t: number)
		halo.Scale = 1 + 0.05 * math.sin(t * 2.3)
		coeur.BackgroundColor3 = rgb(255, 220, 120):Lerp(rgb(255, 250, 220), 0.5 + 0.5 * math.sin(t * 3.1))
		for _, c in croutes do
			c[1].Position = UDim2.fromScale(c[2] + math.sin(t * 0.4 + c[4]) * 0.02, c[3] + math.cos(t * 0.35 + c[4]) * 0.02)
		end
		for _, b in bulles do
			local ph = (b[4] + t * b[5]) % 1
			if ph < 0.05 then
				b[2], b[3] = 0.3 + math.random() * 0.4, 0.3 + math.random() * 0.4
			end
			local d = 0.03 + ph * 0.09
			b[1].Position = UDim2.fromScale(b[2], b[3])
			b[1].Size = UDim2.fromScale(d, d * w / h * 0.8)
			b[1].BackgroundTransparency = if ph > 0.85 then (ph - 0.85) / 0.15 else 0.1
		end
	end
end

-- Chaîne : maillons de face (contour, trou, reflet) et de profil (barre claire)
function K.chaine(g: Instance, ax: number, ay: number, bx: number, by: number, n: number, ep: number, couleur: Color3, z: number?)
	local sombre = couleur:Lerp(NOIR, 0.65)
	for i = 0, n - 1 do
		local t0, t1 = (i - 0.08) / n, (i + 1.08) / n
		local x0, y0 = ax + (bx - ax) * t0, ay + (by - ay) * t0
		local x1, y1 = ax + (bx - ax) * t1, ay + (by - ay) * t1
		if i % 2 == 0 then
			local m = K.seg(g, x0, y0, x1, y1, ep, BLANC, 0, z)
			coin(0.5).Parent = m
			K.degrade(m, K.metal(couleur), 90)
			trait(sombre, 1.2).Parent = m
			local tm, tn = (i + 0.3) / n, (i + 0.7) / n
			local trou = K.seg(g, ax + (bx - ax) * tm, ay + (by - ay) * tm, ax + (bx - ax) * tn, ay + (by - ay) * tn, ep * 0.38, sombre:Lerp(NOIR, 0.4), 0, z)
			coin(0.5).Parent = trou
		else
			local m = K.seg(g, x0, y0, x1, y1, ep * 0.36, BLANC, 0, z)
			coin(0.5).Parent = m
			K.degrade(m, K.metal(couleur:Lerp(BLANC, 0.1)), 90)
			trait(sombre, 1).Parent = m
		end
	end
end

-- Engrenage : couronne, dents trapézoïdales régulières, voile ajouré, rayons, moyeu claveté, rivets.
-- Le dessin tourne dans un CanvasGroup ; le reflet métallique est posé par-dessus et ne tourne pas.
function K.engrenage(parent: Instance, x: number, y: number, d: number, couleur: Color3, dents: number, detail: number, z: number?): CanvasGroup
	local cg = creer("CanvasGroup", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d, d), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent})
	K.ratio(cg, 1)
	local sombre = couleur:Lerp(NOIR, 0.55)
	local clair = couleur:Lerp(BLANC, 0.18)
	for i = 1, dents do
		local a = i / dents * math.pi * 2
		local ca, sa = math.cos(a), math.sin(a)
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + ca * 0.415, 0.5 + sa * 0.415), Size = UDim2.fromScale(0.1, 0.62 / dents * 2.4),
			Rotation = math.deg(a), BackgroundColor3 = couleur, BorderSizePixel = 0, Parent = cg}, {trait(sombre, 1)})
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + ca * 0.465, 0.5 + sa * 0.465), Size = UDim2.fromScale(0.06, 0.62 / dents * 1.5),
			Rotation = math.deg(a), BackgroundColor3 = clair, BorderSizePixel = 0, Parent = cg}, {trait(sombre, 1)})
	end
	trait(sombre, 1.5).Parent = K.disque(cg, 0.5, 0.5, 0.84, couleur)
	K.disque(cg, 0.5, 0.5, 0.72, sombre)
	K.disque(cg, 0.5, 0.5, 0.66, couleur:Lerp(NOIR, 0.25))
	for k = 0, 5 do -- jours du voile, entre les rayons
		local a = (k + 0.5) / 6 * math.pi * 2
		K.disque(cg, 0.5 + math.cos(a) * 0.2, 0.5 + math.sin(a) * 0.2, 0.15, sombre:Lerp(NOIR, 0.5))
	end
	for k = 0, 2 do
		K.bloc(cg, 0.5, 0.5, 0.66, 0.075, couleur, {Rotation = k * 60}, {trait(sombre, 1)})
	end
	trait(sombre, 1.5).Parent = K.disque(cg, 0.5, 0.5, 0.26, clair)
	K.disque(cg, 0.5, 0.5, 0.17, couleur:Lerp(NOIR, 0.3))
	K.disque(cg, 0.5, 0.5, 0.09, sombre:Lerp(NOIR, 0.5))
	K.bloc(cg, 0.5, 0.455, 0.035, 0.04, sombre:Lerp(NOIR, 0.5)) -- clavette
	if detail >= 2 then
		for k = 1, 12 do
			local a = k / 12 * math.pi * 2
			K.disque(cg, 0.5 + math.cos(a) * 0.385, 0.5 + math.sin(a) * 0.385, 0.03, clair:Lerp(BLANC, 0.2))
		end
		for k = 1, 6 do
			local a = k / 6 * math.pi * 2
			K.disque(cg, 0.5 + math.cos(a) * 0.105, 0.5 + math.sin(a) * 0.105, 0.025, clair:Lerp(BLANC, 0.25))
		end
	end
	-- reflet fixe (lumière venant d'en haut à gauche) et ombre en bas à droite
	creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(d * 0.86, d * 0.86), SizeConstraint = YY,
		BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = z or 1, Parent = parent},
		{coin(0.5), K.degrade(nil, K.seq({{0, rgb(255, 230, 200)}, {0.5, rgb(128, 128, 128)}, {1, NOIR}}), 45, K.transp({{0, 0.72}, {0.45, 1}, {0.6, 1}, {1, 0.55}}))})
	return cg
end

-- Tuyau en cuivre le long de points (coudes ronds, brides rivetées, reflet)
function K.tuyau(g: Instance, pts: {{number}}, ep: number, couleur: Color3, z: number?)
	local sombre = couleur:Lerp(NOIR, 0.6)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local f = K.seg(g, a[1], a[2], b[1], b[2], ep, BLANC, 0, z)
		K.degrade(f, K.metal(couleur), 90)
		trait(sombre, 1.2).Parent = f
		local x1, y1, x2, y2 = K.decaler(g, a[1], a[2], b[1], b[2], -ep * 0.22)
		K.seg(g, x1, y1, x2, y2, ep * 0.12, couleur:Lerp(BLANC, 0.6), 0.45, z)
	end
	for i, p in pts do
		local f = K.disque(g, p[1], p[2], ep * (if i == 1 or i == #pts then 1.5 else 1.25), couleur:Lerp(NOIR, 0.15), 0, z)
		K.degrade(f, K.metal(couleur:Lerp(NOIR, 0.1)), 45)
		trait(sombre, 1.2).Parent = f
	end
end

-- Fissure ramifiée : lueur, bords lumineux, fond noir profond, branches de plus en plus fines
local function failleSeg(g: Instance, ax: number, ay: number, bx: number, by: number, e: number, c: Color3, z: number?)
	K.seg(g, ax, ay, bx, by, e * 3.4, c, 0.84, z)
	K.seg(g, ax, ay, bx, by, e * 1.7, c:Lerp(BLANC, 0.35), 0.12, z)
	local f = K.seg(g, ax, ay, bx, by, e, BLANC, 0, z)
	K.degrade(f, K.seq({{0, c:Lerp(NOIR, 0.55)}, {0.3, rgb(6, 0, 10)}, {0.7, rgb(6, 0, 10)}, {1, c:Lerp(NOIR, 0.55)}}), 90)
	K.disque(g, bx, by, e * 1.7, c:Lerp(BLANC, 0.35), 0.12, z)
	K.disque(g, bx, by, e, rgb(6, 0, 10), 0, z)
end
function K.fissure(g: Instance, x: number, y: number, ang: number, L: number, ep: number, prof: number, rng: Random, c: Color3, z: number?)
	local ar = ratios[g] or 1
	local px, py = x, y
	local n = 4
	for k = 1, n do
		local a = ang + rng:NextNumber(-0.5, 0.5)
		local l = L / n
		local qx, qy = px + math.cos(a) * l / ar, py + math.sin(a) * l
		local e = ep * (1 - (k - 1) / n * 0.55)
		failleSeg(g, px, py, qx, qy, e, c, z)
		if prof > 0 and rng:NextNumber() < 0.6 then
			K.fissure(g, qx, qy, a + (rng:NextInteger(0, 1) * 2 - 1) * rng:NextNumber(0.5, 1.1), L * 0.5, e * 0.55, prof - 1, rng, c, z)
		end
		px, py = qx, qy
	end
end

-- Lanterne de mine : crochet, chaîne, chapeau, cage de fer rivetée, verre ambré, flamme, halo ; renvoie l'animation
function K.lanterne(parent: Instance, x: number, yHaut: number, h: number, rng: Random, z: number?): (number) -> ()
	local g = K.groupe(parent, x, yHaut, h * 0.5, h, HAUT, z) -- ar 0.5
	local fer = rgb(62, 60, 66)
	local sombre = rgb(18, 16, 20)
	-- crochet
	K.seg(g, 0.5, 0, 0.5, 0.05, 0.018, fer, 0, z)
	K.seg(g, 0.5, 0.05, 0.62, 0.075, 0.016, fer, 0, z)
	K.seg(g, 0.62, 0.075, 0.6, 0.035, 0.014, fer, 0, z)
	K.chaine(g, 0.5, 0.06, 0.5, 0.27, 6, 0.026, rgb(110, 106, 112), z)
	K.bloc(g, 0.5, 0.29, 0.14, 0.03, BLANC, {BackgroundTransparency = 1, ZIndex = z or 1}, {coin(0.5), trait(fer:Lerp(BLANC, 0.2), 2)})
	-- halo
	local _, halo = K.lueur(g, 0.5, 0.6, 1.5, rgb(255, 176, 80), 0.8, z, 6)
	-- chapeau
	K.bloc(g, 0.5, 0.325, 0.44, 0.04, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer), 90), trait(sombre, 1.2)})
	K.bloc(g, 0.5, 0.36, 0.72, 0.045, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer), 90), trait(sombre, 1.2), coin(0.2)})
	-- verre ambré et flamme
	K.bloc(g, 0.5, 0.57, 0.62, 0.36, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.seq({{0, rgb(220, 120, 40)}, {0.5, rgb(255, 214, 130)}, {1, rgb(190, 96, 30)}}), 0)})
	local _, flHalo = K.lueur(g, 0.5, 0.6, 0.38, rgb(255, 240, 180), 0.55, z, 3)
	local flamme = K.bloc(g, 0.5, 0.67, 0.16, 0.16, rgb(255, 150, 40), {AnchorPoint = BAS, ZIndex = z or 1}, {coin(0.5),
		K.degrade(nil, K.seq({{0, rgb(255, 120, 30)}, {1, rgb(255, 210, 90)}}), 90, K.transp({{0, 1}, {0.35, 0.1}, {1, 0}}))})
	K.bloc(g, 0.5, 0.67, 0.08, 0.08, rgb(255, 250, 220), {AnchorPoint = BAS, ZIndex = z or 1}, {coin(0.5)})
	K.bloc(g, 0.5, 0.69, 0.05, 0.03, rgb(60, 40, 30), {ZIndex = z or 1}) -- mèche
	-- reflet sur le verre
	K.bloc(g, 0.3, 0.55, 0.06, 0.26, BLANC, {BackgroundTransparency = 0.55, ZIndex = z or 1}, {coin(0.5)})
	-- cage : montants, cercles, rivets
	for _, bx in {0.2, 0.5, 0.8} do
		K.bloc(g, bx, 0.57, if bx == 0.5 then 0.035 else 0.05, 0.38, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer), 0), trait(sombre, 1)})
	end
	for _, by in {0.4, 0.74} do
		K.bloc(g, 0.5, by, 0.72, 0.03, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer), 90), trait(sombre, 1)})
		for _, bx in {0.2, 0.8} do
			K.rivet(g, bx, by, 0.022)
		end
	end
	-- socle
	K.bloc(g, 0.5, 0.775, 0.8, 0.04, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer), 90), trait(sombre, 1.2), coin(0.2)})
	K.bloc(g, 0.5, 0.81, 0.52, 0.035, BLANC, {ZIndex = z or 1}, {K.degrade(nil, K.metal(fer:Lerp(NOIR, 0.2)), 90), trait(sombre, 1.2)})
	local ph = rng:NextNumber(0, 6.28)
	return function(t: number)
		local f = 1 + 0.06 * math.sin(t * 11 + ph) + 0.04 * math.sin(t * 6.7 + ph * 2)
		halo.Scale = f
		flHalo.Scale = f
		flamme.Size = UDim2.fromScale(0.16 * (2 - f), 0.16 * f)
	end
end

-- ================= Palier 1 : Le Lac des Lueurs =================
local CYAN, MAGENTA_L = rgb(80, 232, 220), rgb(222, 104, 255)

-- Champignon lumineux : chapeau en dôme, lamelles, tachetures, reflet, pied fibreux à anneau et volve, halo
local function champignon(parent: Instance, x: number, yBas: number, h: number, cc: Color3, rng: Random, detail: number)
	local g = K.groupe(parent, x, yBas, h * 0.95, h, BAS)
	local pied = rgb(196, 206, 222)
	local fonce = cc:Lerp(NOIR, 0.55)
	K.ombre(g, 0.5, 0.985, 0.9, 0.05, 0.3)
	local _, halo = K.lueur(g, 0.5, 0.28, 1.6, cc, 0.85, nil, 5)
	-- pied
	K.bloc(g, 0.5, 0.96, 0.17, 0.64, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, pied:Lerp(BLANC, 0.45)}, {0.3, pied}, {1, pied:Lerp(NOIR, 0.5)}}), 0),
		trait(pied:Lerp(NOIR, 0.6), 1.5)})
	if detail >= 2 then
		for i = 1, 4 do -- fibres
			K.bloc(g, 0.435 + i * 0.026, 0.68, 0.008, rng:NextNumber(0.25, 0.5), pied:Lerp(NOIR, 0.4), {BackgroundTransparency = 0.5},
				{K.degrade(nil, nil, 90, K.transp({{0, 1}, {0.3, 0}, {0.7, 0}, {1, 1}}))})
		end
		for _ = 1, 6 do -- grain
			K.ellipse(g, rng:NextNumber(0.44, 0.56), rng:NextNumber(0.45, 0.9), 0.014, 0.01, pied:Lerp(NOIR, 0.5), 0.35)
		end
		K.ellipse(g, 0.5, 0.52, 0.21, 0.018, pied:Lerp(NOIR, 0.45), 0.3) -- ombre sous l'anneau
		K.ellipse(g, 0.5, 0.5, 0.25, 0.035, pied:Lerp(BLANC, 0.25), 0, {trait(pied:Lerp(NOIR, 0.5), 1), K.degrade(nil, K.relief(pied), 0)})
	end
	K.ellipse(g, 0.5, 0.945, 0.3, 0.07, BLANC, 0, {K.degrade(nil, K.relief(pied:Lerp(NOIR, 0.15)), 0), trait(pied:Lerp(NOIR, 0.6), 1)}) -- volve
	-- lumière du chapeau qui coule sur le pied
	K.bloc(g, 0.5, 0.33, 0.17, 0.22, cc, {AnchorPoint = HAUT, BackgroundTransparency = 0.25}, {K.degrade(nil, nil, 90, K.transp({{0, 0.15}, {1, 1}}))})
	-- dessous du chapeau : lamelles
	K.ellipse(g, 0.5, 0.33, 0.88, 0.1, fonce, 0)
	for i = 0, (if detail >= 2 then 14 else 7) do
		local n = if detail >= 2 then 14 else 7
		local rx = 0.08 + i / n * 0.84
		K.seg(g, 0.5, 0.37, rx, 0.315, 0.006, if i % 2 == 0 then cc:Lerp(BLANC, 0.25) else cc:Lerp(NOIR, 0.25), 0.3)
	end
	K.ellipse(g, 0.5, 0.305, 0.95, 0.022, cc:Lerp(BLANC, 0.55), 0.05) -- liseré lumineux
	-- chapeau (dôme en deux couches)
	local degrade = K.seq({{0, cc:Lerp(BLANC, 0.5)}, {0.4, cc}, {1, cc:Lerp(NOIR, 0.5)}})
	K.ellipse(g, 0.5, 0.21, 1, 0.22, BLANC, 0, {K.degrade(nil, degrade, 90), trait(fonce, 2)})
	K.ellipse(g, 0.5, 0.15, 0.74, 0.2, BLANC, 0, {K.degrade(nil, degrade, 90)})
	-- tachetures
	local taches = {}
	for _ = 1, (if detail >= 2 then 9 else 4) do
		local a = rng:NextNumber(0.14, 0.86)
		local yy = 0.09 + rng:NextNumber(0, 0.12) + math.abs(a - 0.5) * 0.16
		local d = rng:NextNumber(0.025, 0.065)
		local tache = K.disque(g, a, yy, d, cc:Lerp(BLANC, 0.72), rng:NextNumber(0.05, 0.25))
		trait(cc:Lerp(BLANC, 0.3), 1, 0.4).Parent = tache
		if d > 0.045 then
			K.disque(g, a - d * 0.12, yy - d * 0.12, d * 0.4, BLANC, 0.15)
		end
		table.insert(taches, {tache, rng:NextNumber(0, 6.28)})
	end
	-- reflet
	K.ellipse(g, 0.35, 0.1, 0.26, 0.04, BLANC, 0.55)
	K.ellipse(g, 0.29, 0.1, 0.08, 0.022, BLANC, 0.15)
	return halo, taches
end

-- Fougère : frondes courbées, folioles par paires (dégradé base → pointe lumineuse)
local function fougere(parent: Instance, x: number, yBas: number, h: number, c1: Color3, c2: Color3, rng: Random, frondes: number): {Frame}
	local g = K.groupe(parent, x, yBas, h, h, BAS)
	local bouts = {}
	for f = 1, frondes do
		local a = math.rad(-72 + (f - 0.5) / frondes * 144 + rng:NextNumber(-8, 8))
		local L = rng:NextNumber(0.62, 0.92) * (1 - math.abs(a) * 0.2)
		local sens = if a < 0 then -1 else 1
		local function point(s: number): (number, number)
			return 0.5 + math.sin(a) * L * s + sens * 0.2 * L * s * s, 1 - math.cos(a) * L * s + 0.34 * L * s * s
		end
		local px, py = point(0)
		for k = 1, 4 do
			local qx, qy = point(k / 4)
			K.seg(g, px, py, qx, qy, 0.016 * (1 - k * 0.17), c1:Lerp(NOIR, 0.4))
			px, py = qx, qy
		end
		for k = 1, 8 do
			local s = 0.1 + (k - 1) / 8 * 0.84
			local ax, ay = point(s)
			local bx, by = point(s + 0.02)
			local ang = math.atan2(by - ay, bx - ax)
			local l = 0.14 * L * (1 - s * 0.62)
			local teinte = c1:Lerp(c2, s)
			for _, cote in {-1, 1} do
				local b = ang + cote * math.rad(60)
				K.feuille(g, ax + math.cos(b) * l * 0.5, ay + math.sin(b) * l * 0.5, l, l * 0.34, math.deg(b), BLANC, 0,
					{K.degrade(nil, K.seq({{0, teinte:Lerp(NOIR, 0.35)}, {0.55, teinte}, {1, teinte:Lerp(BLANC, 0.35)}}), 0)})
			end
		end
		local tx, ty = point(1)
		table.insert(bouts, K.disque(g, tx, ty, 0.03, c2:Lerp(BLANC, 0.55), 0.1))
	end
	return bouts
end

-- Touffe d'herbes : brins en deux segments qui se courbent, pointe qui s'estompe
local function touffe(parent: Instance, x: number, yBas: number, h: number, c1: Color3, c2: Color3, rng: Random, n: number)
	local g = K.groupe(parent, x, yBas, h, h, BAS)
	for _ = 1, n do
		local bx = 0.5 + rng:NextNumber(-0.16, 0.16)
		local a = math.rad(rng:NextNumber(-38, 38))
		local L = rng:NextNumber(0.5, 1)
		local mx, my = bx + math.sin(a) * L * 0.5, 1 - math.cos(a) * L * 0.5
		local a2 = a + (if a < 0 then -1 else 1) * math.rad(rng:NextNumber(10, 32))
		local tx, ty = mx + math.sin(a2) * L * 0.5, my - math.cos(a2) * L * 0.5
		local c = c1:Lerp(c2, rng:NextNumber(0, 1))
		K.seg(g, bx, 1, mx, my, 0.032, c:Lerp(NOIR, 0.3))
		local p = K.seg(g, mx, my, tx, ty, 0.02, c)
		K.degrade(p, K.seq({{0, c}, {1, c:Lerp(BLANC, 0.4)}}), 0, K.transp({{0, 0}, {1, 0.55}}))
	end
end

-- Liane qui pend du plafond : tige ondulée, feuilles alternées, bulbes lumineux ; renvoie les bulbes
local function liane(parent: Instance, x: number, longueur: number, c1: Color3, cl: Color3, rng: Random): {UIScale}
	local g = K.groupe(parent, x, 0, 0.14, longueur, HAUT)
	local ph = rng:NextNumber(0, 6.28)
	local px, py = 0.5, 0
	local bulbes = {}
	local n = 13
	for k = 1, n do
		local yy = k / n
		local xx = 0.5 + math.sin(yy * 7 + ph) * 0.22
		K.seg(g, px, py, xx, yy, 0.0065 / longueur, c1:Lerp(NOIR, 0.35))
		if k % 2 == 0 then
			local cote = if k % 4 == 0 then 1 else -1
			K.feuille(g, xx + cote * 0.13, yy, 0.038 / longueur, 0.015 / longueur, cote * 32, BLANC, 0,
				{K.degrade(nil, if cote > 0 then K.seq({{0, c1:Lerp(NOIR, 0.3)}, {1, c1:Lerp(BLANC, 0.3)}}) else K.seq({{0, c1:Lerp(BLANC, 0.3)}, {1, c1:Lerp(NOIR, 0.3)}}), 0)})
		end
		if k % 4 == 3 then
			local _, s = K.lueur(g, xx, yy + 0.02, 0.07 / longueur, cl, 0.8, nil, 4)
			K.disque(g, xx, yy + 0.02, 0.014 / longueur, cl:Lerp(BLANC, 0.5), 0)
			table.insert(bulbes, s)
		end
		px, py = xx, yy
	end
	return bulbes
end

-- Fleur lumineuse : tige, deux feuilles, cinq pétales en dégradé, cœur, halo
local function fleur(parent: Instance, x: number, yBas: number, h: number, cp: Color3, rng: Random): UIScale
	local g = K.groupe(parent, x, yBas, h, h, BAS)
	local tige = rgb(40, 120, 90)
	local cx, cy = 0.5 + rng:NextNumber(-0.1, 0.1), 0.3
	K.seg(g, 0.5, 1, 0.5 + (cx - 0.5) * 0.4, 0.62, 0.025, tige:Lerp(NOIR, 0.2))
	K.seg(g, 0.5 + (cx - 0.5) * 0.4, 0.62, cx, cy + 0.04, 0.02, tige)
	for _, cote in {-1, 1} do
		K.feuille(g, 0.5 + cote * 0.12, 0.78, 0.24, 0.08, cote * -30, BLANC, 0, {K.degrade(nil, K.seq({{0, tige:Lerp(NOIR, 0.3)}, {1, tige:Lerp(BLANC, 0.3)}}), if cote > 0 then 0 else 180)})
	end
	local _, halo = K.lueur(g, cx, cy, 0.75, cp, 0.84, nil, 5)
	local a0 = rng:NextNumber(0, 72)
	for k = 0, 4 do
		local a = math.rad(a0 + k * 72)
		K.feuille(g, cx + math.cos(a) * 0.09, cy + math.sin(a) * 0.09, 0.19, 0.1, math.deg(a), BLANC, 0,
			{K.degrade(nil, K.seq({{0, cp:Lerp(BLANC, 0.7)}, {0.5, cp}, {1, cp:Lerp(NOIR, 0.2)}}), 0), trait(cp:Lerp(NOIR, 0.4), 1, 0.4)})
	end
	trait(rgb(200, 150, 60), 1).Parent = K.disque(g, cx, cy, 0.075, rgb(255, 240, 170))
	for k = 0, 4 do
		local a = math.rad(a0 + 36 + k * 72)
		K.disque(g, cx + math.cos(a) * 0.05, cy + math.sin(a) * 0.05, 0.018, rgb(255, 255, 220), 0)
	end
	return halo
end

-- Coussin de mousse : bosses qui se chevauchent + points lumineux
local function mousse(parent: Instance, x: number, yBas: number, w: number, c1: Color3, c2: Color3, rng: Random)
	local g = K.groupe(parent, x, yBas, w, w * 0.22, BAS)
	for i = 1, 10 do
		local cx = (i - 0.5) / 10 + rng:NextNumber(-0.03, 0.03)
		local d = rng:NextNumber(0.5, 1)
		local c = c1:Lerp(c2, rng:NextNumber())
		K.ellipse(g, cx, 1 - d * 0.35, 0.15 + d * 0.06, d * 0.9, BLANC, 0, {K.degrade(nil, K.seq({{0, c:Lerp(BLANC, 0.25)}, {1, c:Lerp(NOIR, 0.45)}}), 90)})
	end
	for _ = 1, 6 do
		K.disque(g, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.25, 0.7), 0.12, rgb(190, 255, 220), 0.15)
	end
end

local function decorLueurs(c, rng: Random): (number) -> ()
	local loin, milieu, proche = c.loin, c.milieu, c.proche
	-- voûte : stalactites aux gouttes lumineuses, vers luisants, fils perlés
	K.rangee(loin, rng, 14, rgb(18, 40, 56), 0.08, 0.22, 0.04, 0.09, true, 0, nil, rgb(140, 255, 240))
	local vers = {}
	for _ = 1, 30 do
		local d = K.disque(loin, rng:NextNumber(0.02, 0.98), rng:NextNumber(0.03, 0.3), rng:NextNumber(0.004, 0.009), rgb(150, 255, 235), 0.3)
		table.insert(vers, {d, rng:NextNumber(0, 6.28), rng:NextNumber(0.8, 2.4)})
	end
	local perles = {}
	for _ = 1, 9 do
		local fx = rng:NextNumber(0.04, 0.96)
		local l = rng:NextNumber(0.08, 0.24)
		K.bloc(loin, fx, 0, 0.0016, l, rgb(150, 230, 230), {AnchorPoint = HAUT, BackgroundTransparency = 0.55})
		for k = 1, 3 do
			local p = K.disque(loin, fx, l * k / 3, 0.006, rgb(190, 255, 245), 0.15)
			table.insert(perles, {p, rng:NextNumber(0, 6.28)})
		end
	end
	-- fond rocheux et ruines naines
	for _, r in {{0.08, 0.68, 0.2, 0.12}, {0.44, 0.66, 0.16, 0.08}, {0.96, 0.68, 0.22, 0.14}} do
		K.rocher(loin, r[1], r[2], r[3], r[4], rgb(22, 42, 56), rng, rgb(30, 90, 80))
	end
	for _, r in {{0.14, 0.67, 0.07, 0.3, true}, {0.25, 0.67, 0.06, 0.2, false}, {0.79, 0.67, 0.07, 0.34, false}, {0.9, 0.67, 0.06, 0.22, true}} do
		K.colonne(loin, r[1], r[2], r[3], r[4], rgb(30, 56, 70), r[5], rgb(40, 120, 100))
	end
	local _, geodeS = K.lueur(loin, 0.4, 0.5, 0.26, rgb(200, 120, 255), 0.86, nil, 5)
	-- cascade dans le grand lac
	local cascade = K.coulee(milieu, 0.66, 0, 0.045, 0.66, rgb(40, 170, 200), rgb(110, 225, 240), rgb(225, 255, 255), rng)
	local _, brumeS = K.lueur(milieu, 0.66, 0.66, 0.34, rgb(160, 245, 255), 0.76, nil, 5)
	-- lac lumineux, reflets, reflets des champignons, nénuphars fleuris
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.645), Size = UDim2.fromScale(1.04, 0.25), BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = milieu},
		{K.degrade(nil, K.seq({{0, rgb(130, 255, 240)}, {0.2, rgb(30, 175, 195)}, {1, rgb(6, 48, 70)}}), 90, K.transp({{0, 0.05}, {0.3, 0.38}, {1, 0.72}}))})
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.643), Size = UDim2.new(1.04, 0, 0, 2), BackgroundColor3 = rgb(220, 255, 250), BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Parent = milieu})
	for _, rx in {0.09, 0.21, 0.92} do
		K.bloc(milieu, rx, 0.65, 0.05, 0.16, rgb(150, 255, 240), {AnchorPoint = HAUT, SizeConstraint = YY, BackgroundTransparency = 0.6}, {coin(0.5),
			K.degrade(nil, nil, 90, K.transp({{0, 0.2}, {1, 1}}))})
	end
	local reflets = {}
	for _ = 1, 9 do
		local x, y = rng:NextNumber(0.05, 0.95), rng:NextNumber(0.66, 0.84)
		local l = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(rng:NextNumber(0.04, 0.12), 0.005),
			BackgroundColor3 = rgb(210, 255, 250), BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = milieu}, {coin(0.5)})
		table.insert(reflets, {l, x, y, rng:NextNumber(0, 6.28)})
	end
	local fleursLac = {}
	for _, n in {{0.33, 0.7}, {0.52, 0.76}, {0.76, 0.72}, {0.43, 0.82}} do
		local g = K.groupe(milieu, n[1], n[2], 0.06, 0.03, CENTRE)
		K.ellipse(g, 0.5, 0.5, 1, 1, rgb(30, 130, 90), 0, {K.degrade(nil, K.seq({{0, rgb(80, 200, 140)}, {1, rgb(20, 80, 60)}}), 90), trait(rgb(10, 50, 40), 1)})
		K.seg(g, 0.5, 0.5, 0.9, 0.2, 0.15, rgb(20, 90, 70))
		local _, s = K.lueur(g, 0.45, 0.2, 1.4, MAGENTA_L, 0.84, nil, 4)
		for k = 0, 3 do
			K.feuille(g, 0.45 + math.cos(k * 1.57) * 0.08, 0.15 + math.sin(k * 1.57) * 0.12, 0.42, 0.2, k * 90, rgb(240, 170, 255), 0, {trait(rgb(160, 60, 200), 1, 0.4)})
		end
		K.disque(g, 0.45, 0.15, 0.3, rgb(255, 245, 200))
		table.insert(fleursLac, s)
	end
	for _, r in {{0.3, 0.9, 0.16, 0.07}, {0.58, 0.9, 0.12, 0.05}} do
		K.rocher(milieu, r[1], r[2], r[3], r[4], rgb(26, 44, 56), rng, rgb(40, 140, 110))
	end
	-- premier plan : sol moussu, champignons, fougères, herbes, fleurs, lianes
	K.sol(proche, rng, rgb(10, 22, 30), 0.935, nil, rgb(60, 160, 140))
	local halos, taches = {}, {}
	for _, ch in {{0.08, 0.66, CYAN, 2}, {0.21, 0.38, MAGENTA_L, 2}, {0.93, 0.58, MAGENTA_L, 2}, {0.8, 0.22, CYAN, 1}, {0.845, 0.16, CYAN, 1}, {0.29, 0.14, CYAN, 1}} do
		local halo, t = champignon(proche, ch[1], 1.0, ch[2], ch[3], rng, ch[4])
		table.insert(halos, {halo, rng:NextNumber(0, 6.28)})
		for _, v in t do table.insert(taches, v) end
	end
	local bouts = {}
	for _, f in {{0.15, 0.32, 5}, {0.74, 0.28, 4}, {0.99, 0.3, 4}} do
		for _, b in fougere(proche, f[1], 1.0, f[2], rgb(30, 110, 90), rgb(110, 255, 210), rng, f[3]) do table.insert(bouts, b) end
	end
	for _, t in {{0.03, 0.14}, {0.34, 0.12}, {0.68, 0.12}, {0.88, 0.13}} do
		touffe(proche, t[1], 1.0, t[2], rgb(30, 100, 80), rgb(90, 220, 170), rng, 9)
	end
	local fleurs = {}
	for _, f in {{0.12, 0.18, MAGENTA_L}, {0.26, 0.15, CYAN}, {0.7, 0.16, MAGENTA_L}, {0.87, 0.2, rgb(255, 200, 120)}, {0.38, 0.12, rgb(255, 200, 120)}} do
		table.insert(fleurs, fleur(proche, f[1], 1.0, f[2], f[3], rng))
	end
	for _, m in {{0.12, 0.98, 0.14}, {0.5, 0.995, 0.2}, {0.86, 0.98, 0.16}} do
		mousse(proche, m[1], m[2], m[3], rgb(30, 110, 80), rgb(70, 190, 140), rng)
	end
	local bulbes = {}
	for _, l in {{0.03, 0.42}, {0.13, 0.3}, {0.31, 0.2}, {0.69, 0.22}, {0.88, 0.34}, {0.97, 0.46}} do
		for _, b in liane(proche, l[1], l[2], rgb(40, 130, 100), CYAN, rng) do table.insert(bulbes, b) end
	end
	K.rangee(proche, rng, 7, rgb(8, 18, 26), 0.06, 0.14, 0.05, 0.1, true, 0)

	return function(t: number)
		for _, v in vers do
			v[1].BackgroundTransparency = 0.2 + 0.65 * (0.5 + 0.5 * math.sin(t * v[3] + v[2]))
		end
		for _, p in perles do
			p[1].BackgroundTransparency = 0.1 + 0.5 * (0.5 + 0.5 * math.sin(t * 1.7 + p[2]))
		end
		for _, r in reflets do
			r[1].Position = UDim2.fromScale(r[2] + math.sin(t * 0.7 + r[4]) * 0.02, r[3])
			r[1].BackgroundTransparency = 0.3 + 0.5 * (0.5 + 0.5 * math.sin(t * 1.3 + r[4]))
		end
		for _, hl in halos do
			hl[1].Scale = 1 + 0.07 * math.sin(t * 1.5 + hl[2])
		end
		for i, tc in taches do
			if i % 2 == 0 then tc[1].BackgroundTransparency = 0.05 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 + tc[2])) end
		end
		for i, b in bouts do
			b.BackgroundTransparency = 0.1 + 0.6 * (0.5 + 0.5 * math.sin(t * 2.2 + i))
		end
		for i, b in bulbes do
			b.Scale = 1 + 0.15 * math.sin(t * 1.8 + i * 1.3)
		end
		for i, f in fleurs do
			f.Scale = 1 + 0.1 * math.sin(t * 1.4 + i)
		end
		for i, f in fleursLac do
			f.Scale = 1 + 0.12 * math.sin(t * 1.6 + i * 2)
		end
		geodeS.Scale = 1 + 0.06 * math.sin(t * 0.9)
		brumeS.Scale = 1 + 0.05 * math.sin(t * 2.1)
		cascade(t)
	end
end

-- ================= Palier 2 : La Mine oubliée de Brumefer =================
-- Voie ferrée en vraie perspective : y = 1/z, demi-écartement ∝ 1/z ; traverses veinées, selles, tirefonds,
-- rails en deux couches (âme sombre, champignon d'acier) avec reflet de lanterne
local function voie(parent: Instance, rng: Random)
	local g = K.groupe(parent, 0.5, 1.02, 1.8, 0.54, BAS)
	local ar = 1.8 / 0.54
	local G = 0.4
	local BOIS = rgb(96, 64, 40)
	local BRUME = rgb(18, 12, 9)
	local zs = {0.9, 1.1, 1.36, 1.7, 2.12, 2.66, 3.4, 4.35, 5.6, 7.3, 9.6, 12.8, 17.5}
	local function X(s: number, z: number): number
		return 0.5 + s * G / z / ar
	end
	-- ballast (gravier)
	for _ = 1, 46 do
		local z = rng:NextNumber(0.95, 5)
		local d = 0.022 / z
		K.ellipse(g, 0.5 + rng:NextNumber(-2.1, 2.1) * G / z / ar, 1 / z + rng:NextNumber(-0.02, 0.02) / z, d * 1.6 / ar, d,
			rgb(70, 60, 54):Lerp(BRUME, math.clamp(1 - 1.2 / z, 0, 0.85)):Lerp(BLANC, rng:NextNumber(0, 0.12)), 0)
	end
	-- traverses, de la plus lointaine à la plus proche
	for i = #zs, 1, -1 do
		local z = zs[i]
		local y = 1 / z
		local brume = math.clamp(1 - 1.15 / z, 0, 0.9)
		local cb = BOIS:Lerp(BRUME, brume)
		local L = 3.1 * G / z / ar
		local ep = 0.055 / z
		K.bloc(g, 0.5, y + ep * 0.55, L * 1.04, ep * 0.5, NOIR, {BackgroundTransparency = 0.5}) -- ombre portée
		K.bloc(g, 0.5, y, L, ep * 0.6, BLANC, {AnchorPoint = HAUT}, {K.degrade(nil, K.seq({{0, cb}, {1, cb:Lerp(NOIR, 0.55)}}), 90), trait(cb:Lerp(NOIR, 0.7), 1, brume)})
		K.bloc(g, 0.5, y, L * 0.97, ep * 0.55, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, cb:Lerp(BLANC, 0.18)}, {1, cb}}), 90), trait(cb:Lerp(NOIR, 0.7), 1, brume)})
		if z < 3.5 then
			for k = 1, 3 do -- veinures
				local l = rng:NextNumber(0.3, 0.7)
				K.bloc(g, 0.5 + rng:NextNumber(-0.25, 0.25) * L, y - ep * (0.12 + k * 0.12), L * l, math.max(0.001, ep * 0.05), cb:Lerp(NOIR, 0.55),
					{BackgroundTransparency = 0.35}, {K.degrade(nil, nil, 0, K.transp({{0, 1}, {0.2, 0.2}, {0.8, 0.2}, {1, 1}}))})
			end
			for _, s in {-1, 1} do -- bout de la traverse plus sombre (bois de bout)
				K.bloc(g, 0.5 + s * L * 0.49, y - ep * 0.25, L * 0.02, ep * 0.5, cb:Lerp(NOIR, 0.4))
			end
			for _, s in {-1, 1} do -- selle et tirefonds
				local rx = X(s, z)
				K.bloc(g, rx, y - ep * 0.42, G * 0.75 / z / ar, ep * 0.2, rgb(70, 66, 70):Lerp(BRUME, brume), {}, {trait(rgb(20, 18, 20), 1)})
				for _, o in {-1, 1} do
					local tx = rx + o * G * 0.28 / z / ar
					K.disque(g, tx, y - ep * 0.42, ep * 0.32, rgb(110, 104, 106):Lerp(BRUME, brume))
					K.disque(g, tx - ep * 0.04 / ar, y - ep * 0.46, ep * 0.12, rgb(210, 200, 190):Lerp(BRUME, brume), 0.2)
				end
			end
		end
	end
	-- rails : tronçons d'épaisseur décroissante (la ligne reste droite : x est linéaire en y)
	for _, s in {-1, 1} do
		for i = 1, #zs - 1 do
			local za, zb = zs[i], zs[i + 1]
			local ax, ay, bx, by = X(s, za), 1 / za, X(s, zb), 1 / zb
			local e = 0.028 / ((za + zb) / 2)
			local brume = math.clamp(1 - 1.15 / za, 0, 0.9)
			K.seg(g, ax, ay + e * 0.55, bx, by + e * 0.55, e * 0.95, rgb(34, 30, 32):Lerp(BRUME, brume))
			local tete = K.seg(g, ax, ay, bx, by, e * 0.75, BLANC)
			K.degrade(tete, K.metal(rgb(140, 136, 140):Lerp(BRUME, brume * 0.8)), 90)
			local x1, y1, x2, y2 = K.decaler(g, ax, ay, bx, by, -e * 0.2)
			K.seg(g, x1, y1, x2, y2, e * 0.16, rgb(255, 222, 170), 0.2 + brume * 0.7)
		end
		local zf = zs[#zs]
		K.seg(g, X(s, zf), 1 / zf, 0.5, 0, 0.002, rgb(60, 56, 56):Lerp(BRUME, 0.85))
	end
end

-- Wagonnet : planches veinées, coins de fer rivetés, chargement d'améthyste, roues à rayons
local function wagonnet(parent: Instance, x: number, yBas: number, h: number, rng: Random)
	local g = K.groupe(parent, x, yBas, h * 1.6, h, BAS)
	local bois = rgb(104, 68, 42)
	K.ombre(g, 0.5, 0.98, 1.0, 0.08, 0.3)
	local _, _ = K.lueur(g, 0.5, 0.25, 1.1, rgb(190, 120, 255), 0.84, nil, 5)
	for i = 1, 5 do
		K.cristal(g, 0.18 + i * 0.12 + rng:NextNumber(-0.02, 0.02), 0.32, rng:NextNumber(0.07, 0.11), rng:NextNumber(0.22, 0.4), rgb(210, 140, 255), rgb(110, 50, 170))
	end
	for k = 1, 4 do -- planches
		local y = 0.32 + (k - 1) * 0.13
		K.poutre(g, 0.07, y, 0.86, 0.13, bois:Lerp(NOIR, (k % 2) * 0.08), rng, 2)
	end
	K.bloc(g, 0.5, 0.31, 0.92, 0.05, BLANC, {}, {K.degrade(nil, K.metal(rgb(110, 108, 116)), 90), trait(rgb(20, 20, 24), 1.2)})
	for _, cx in {0.08, 0.92} do
		K.bloc(g, cx, 0.56, 0.07, 0.5, BLANC, {}, {K.degrade(nil, K.metal(rgb(96, 94, 102)), 0), trait(rgb(20, 20, 24), 1.2)})
		for k = 1, 3 do
			K.rivet(g, cx, 0.38 + k * 0.11, 0.035)
		end
	end
	K.bloc(g, 0.5, 0.86, 0.8, 0.05, rgb(40, 38, 42)) -- essieux
	for _, rx in {0.26, 0.74} do
		local r = K.groupe(g, rx, 0.88, 0.3, 0.3, CENTRE)
		trait(rgb(130, 126, 134), 2).Parent = K.disque(r, 0.5, 0.5, 1, rgb(46, 44, 48))
		K.disque(r, 0.5, 0.5, 0.72, rgb(30, 28, 32))
		for k = 0, 5 do
			local a = k / 6 * math.pi
			K.seg(r, 0.5 - math.cos(a) * 0.36, 0.5 - math.sin(a) * 0.36, 0.5 + math.cos(a) * 0.36, 0.5 + math.sin(a) * 0.36, 0.06, rgb(90, 86, 94))
		end
		K.rivet(r, 0.5, 0.5, 0.28, rgb(140, 136, 144))
	end
end

-- Caisse en planches avec écharpe et coins de fer
local function caisse(parent: Instance, x: number, yBas: number, h: number, rng: Random)
	local g = K.groupe(parent, x, yBas, h, h, BAS)
	local bois = rgb(110, 76, 46)
	K.ombre(g, 0.5, 0.99, 1.15, 0.08, 0.3)
	for k = 1, 4 do
		K.poutre(g, 0.04, (k - 1) * 0.24 + 0.02, 0.92, 0.24, bois:Lerp(NOIR, (k % 2) * 0.1), rng, 2)
	end
	K.jambe(g, 0.12, 0.88, 0.88, 0.14, 0.09, bois:Lerp(BLANC, 0.08))
	for _, cx in {0.07, 0.93} do
		for _, cy in {0.08, 0.92} do
			K.bloc(g, cx, cy, 0.14, 0.14, BLANC, {}, {K.degrade(nil, K.metal(rgb(90, 88, 96)), 45), trait(rgb(20, 20, 24), 1)})
			K.rivet(g, cx, cy, 0.05)
		end
	end
end

local function decorMine(c, rng: Random): (number) -> ()
	local loin, milieu, proche = c.loin, c.milieu, c.proche
	local BOIS = rgb(104, 68, 42)
	-- parois de roche en strates, veines d'améthyste
	for _, cote in {0, 1} do
		local g = K.groupe(loin, cote, 1, 0.95, 1, Vector2.new(cote, 1))
		K.bloc(g, cote, 0.5, 1, 1, rgb(26, 17, 13), {AnchorPoint = Vector2.new(cote, 0.5)}, {K.degrade(nil, nil, if cote == 0 then 0 else 180, K.transp({{0, 0}, {0.7, 0.4}, {1, 1}}))})
		for k = 1, 7 do
			local y = k / 8 + rng:NextNumber(-0.03, 0.03)
			local x0 = if cote == 0 then 0 else 1
			local x1 = if cote == 0 then rng:NextNumber(0.3, 0.6) else 1 - rng:NextNumber(0.3, 0.6)
			K.seg(g, x0, y, x1, y + rng:NextNumber(-0.04, 0.04), 0.004, rgb(60, 44, 34), 0.4)
		end
		for _ = 1, 2 do
			local vx = if cote == 0 then rng:NextNumber(0.1, 0.4) else 1 - rng:NextNumber(0.1, 0.4)
			local vy = rng:NextNumber(0.25, 0.7)
			K.fissure(g, vx, vy, rng:NextNumber(0, 6.28), 0.18, 0.006, 1, rng, rgb(170, 90, 255))
		end
	end
	-- lumière au bout du tunnel + cadres en perspective
	local _, finS = K.lueur(loin, 0.5, 0.46, 0.36, rgb(255, 190, 110), 0.78, nil, 6)
	for k, h in {0.12, 0.2, 0.33, 0.55} do
		local f = (k - 1) / 3
		K.cadreMine(loin, 0.5, 0.47 + 0.46 * h, h * 0.95, h, BOIS:Lerp(rgb(14, 9, 7), 0.8 - f * 0.66), rng, if k >= 3 then 2 else 1)
	end
	voie(loin, rng)
	-- wagonnet, caisses, améthyste
	wagonnet(milieu, 0.18, 0.95, 0.15, rng)
	caisse(milieu, 0.85, 0.97, 0.12, rng)
	caisse(milieu, 0.79, 0.99, 0.08, rng)
	local amasA = K.amas(milieu, 0.95, 0.99, 0.24, rgb(205, 135, 255), rgb(100, 40, 160), rng, rgb(44, 32, 30))
	local amasB = K.amas(milieu, 0.36, 0.99, 0.1, rgb(205, 135, 255), rgb(100, 40, 160), rng, rgb(44, 32, 30))
	-- grand cadre au premier plan : poteaux, chapeau, jambes de force, lanternes
	for _, cote in {0, 1} do
		local g = K.groupe(proche, if cote == 0 then 0.035 else 0.965, 1.02, 0.11, 1.06, BAS)
		K.poutre(g, 0, 0, 1, 1, BOIS, rng, 3)
	end
	local chapeau = K.groupe(proche, 0.5, 0, 2.6, 0.085, HAUT)
	K.poutre(chapeau, 0, 0, 1, 1, BOIS:Lerp(NOIR, 0.05), rng, 2)
	for _, cote in {0, 1} do
		local g = K.groupe(proche, cote, 0.08, 0.3, 0.3, Vector2.new(cote, 0))
		if cote == 0 then
			K.jambe(g, 0.2, 0.95, 0.95, 0.04, 0.075, BOIS:Lerp(NOIR, 0.08))
		else
			K.jambe(g, 0.8, 0.95, 0.05, 0.04, 0.075, BOIS:Lerp(NOIR, 0.08))
		end
	end
	local lanternes = {
		K.lanterne(proche, 0.27, 0.075, 0.24, rng),
		K.lanterne(proche, 0.73, 0.075, 0.24, rng),
	}
	K.sol(proche, rng, rgb(22, 15, 11), 0.95, nil, rgb(120, 90, 60))
	return function(t: number)
		finS.Scale = 1 + 0.05 * math.sin(t * 0.8)
		for _, l in lanternes do l(t) end
		amasA.Scale = 1 + 0.07 * math.sin(t * 1.2)
		amasB.Scale = 1 + 0.07 * math.sin(t * 1.5 + 2)
	end
end

-- ================= Palier 3 : La Fonderie de l'Abîme =================
-- Cheminée de briques : rangs décalés, joints de mortier, gueule de four, fumée ; renvoie l'animation
local function cheminee(parent: Instance, x: number, yBas: number, w: number, h: number, rng: Random): (number) -> ()
	local g = K.groupe(parent, x, yBas, w, h, BAS)
	K.bloc(g, 0.5, 1, 1, 0.94, rgb(34, 20, 16), {AnchorPoint = BAS}, {trait(rgb(16, 10, 8), 1.5)})
	local rangs = 16
	for r = 0, rangs - 1 do
		local y = 0.07 + r * (0.93 / rangs)
		local decal = if r % 2 == 0 then 0 else 1 / 6
		local chaleur = math.clamp((y - 0.55) / 0.45, 0, 1)
		for b = 0, 3 do
			local bx = decal + b / 3 - 1 / 6
			local x0, x1 = math.max(0.02, bx - 1 / 6 + 0.012), math.min(0.98, bx + 1 / 6 - 0.012)
			if x1 > x0 + 0.02 then
				local cb = rgb(120, 56, 38):Lerp(rgb(86, 40, 30), rng:NextNumber()):Lerp(rgb(220, 110, 50), chaleur * 0.5)
				K.bloc(g, (x0 + x1) / 2, y + 0.93 / rangs / 2, x1 - x0, 0.93 / rangs - 0.008, BLANC, {},
					{K.degrade(nil, K.seq({{0, cb:Lerp(BLANC, 0.15)}, {1, cb:Lerp(NOIR, 0.3)}}), 90)})
			end
		end
	end
	K.bloc(g, 0.5, 0.07, 1.14, 0.04, BLANC, {}, {K.degrade(nil, K.relief(rgb(60, 40, 34)), 90), trait(rgb(16, 10, 8), 1)})
	K.bloc(g, 0.5, 0.035, 1.08, 0.03, BLANC, {}, {K.degrade(nil, K.relief(rgb(70, 46, 38)), 90), trait(rgb(16, 10, 8), 1)})
	-- gueule du four
	local _, gueuleHalo = K.lueur(g, 0.5, 0.92, 1.0, rgb(255, 140, 40), 0.8, nil, 5)
	K.bloc(g, 0.5, 1, 0.6, 0.16, BLANC, {AnchorPoint = BAS}, {coin(0.45), K.degrade(nil, K.seq({{0, rgb(255, 230, 140)}, {0.5, rgb(255, 130, 30)}, {1, rgb(140, 30, 10)}}), 90),
		trait(rgb(30, 18, 14), 2)})
	local feu = K.feu(g, 0.5, 1, 0.13, {coeur = rgb(255, 250, 220), jaune = rgb(255, 220, 90), orange = rgb(255, 130, 30), rouge = rgb(170, 30, 10)}, rng)
	-- fumée
	local fumees = {}
	for i = 1, 6 do
		local f = K.disque(g, 0.5, 0, 0.1, rgb(70, 64, 66), 0.5)
		table.insert(fumees, {f, i / 6})
	end
	return function(t: number)
		feu(t)
		gueuleHalo.Scale = 1 + 0.06 * math.sin(t * 5)
		for _, f in fumees do
			local ph = (f[2] + t * 0.12) % 1
			f[1].Position = UDim2.fromScale(0.5 + math.sin(ph * 5 + f[2] * 6) * 0.4 + ph * 0.6, -ph * 0.55)
			f[1].Size = UDim2.fromScale(0.08 + ph * 0.3, 0.08 + ph * 0.3)
			f[1].BackgroundTransparency = 0.45 + ph * 0.55
		end
	end
end

-- Cuve de métal : corps riveté, cerclages, bec et volant de vanne, métal en fusion qui bouillonne
local function cuve(parent: Instance, x: number, yBas: number, w: number, h: number, rng: Random): (number) -> ()
	local g = K.groupe(parent, x, yBas, w, h, BAS)
	local fer = rgb(70, 64, 66)
	K.ombre(g, 0.5, 0.99, 1.1, 0.05, 0.35)
	local _, halo = K.lueur(g, 0.5, 0.12, 1.0, rgb(255, 140, 40), 0.82, nil, 5)
	for _, lx in {0.2, 0.8} do
		K.bloc(g, lx, 1, 0.1, 0.12, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.metal(fer:Lerp(NOIR, 0.2)), 0), trait(rgb(16, 14, 16), 1)})
	end
	K.bloc(g, 0.5, 0.9, 0.9, 0.74, BLANC, {AnchorPoint = BAS}, {coin(0.08), K.degrade(nil, K.metal(fer), 0), trait(rgb(16, 14, 16), 1.5)})
	for _, sx in {0.35, 0.65} do
		K.bloc(g, sx, 0.53, 0.008, 0.72, rgb(20, 18, 20), {BackgroundTransparency = 0.3})
	end
	for _, by in {0.3, 0.55, 0.8} do
		K.bloc(g, 0.5, by, 0.94, 0.045, BLANC, {}, {K.degrade(nil, K.metal(fer:Lerp(BLANC, 0.1)), 90), trait(rgb(16, 14, 16), 1)})
		for k = 1, 5 do
			K.rivet(g, 0.05 + k * 0.15, by, 0.03)
		end
	end
	K.bloc(g, 0.5, 0.17, 1, 0.05, BLANC, {}, {coin(0.3), K.degrade(nil, K.metal(fer:Lerp(BLANC, 0.15)), 90), trait(rgb(16, 14, 16), 1.2)})
	local surface = K.ellipse(g, 0.5, 0.165, 0.86, 0.04, rgb(255, 170, 50), 0, {K.degrade(nil, K.seq({{0, rgb(200, 60, 14)}, {0.5, rgb(255, 230, 140)}, {1, rgb(200, 60, 14)}}), 0)})
	local _ = surface
	-- bec, vanne
	K.tuyau(g, {{0.96, 0.62}, {1.12, 0.62}, {1.12, 0.74}}, 0.05, rgb(186, 110, 64))
	local vanne = K.groupe(g, 1.12, 0.56, 0.1, 0.1, CENTRE)
	K.bloc(vanne, 0.5, 0.5, 1, 1, BLANC, {BackgroundTransparency = 1}, {coin(0.5), trait(rgb(200, 40, 30), 2.5)})
	K.seg(vanne, 0.1, 0.5, 0.9, 0.5, 0.12, rgb(170, 30, 24))
	K.seg(vanne, 0.5, 0.1, 0.5, 0.9, 0.12, rgb(170, 30, 24))
	local bulles = {}
	for _ = 1, 3 do
		table.insert(bulles, {K.ellipse(g, 0.5, 0.16, 0.05, 0.03, rgb(255, 240, 180), 0), rng:NextNumber(0, 1), rng:NextNumber(0.25, 0.75)})
	end
	return function(t: number)
		halo.Scale = 1 + 0.06 * math.sin(t * 2.5)
		for _, b in bulles do
			local ph = (b[2] + t * 0.8) % 1
			b[1].Position = UDim2.fromScale(b[3], 0.16 - ph * 0.02)
			b[1].Size = UDim2.fromScale(0.03 + ph * 0.06, 0.02 + ph * 0.025)
			b[1].BackgroundTransparency = ph
		end
	end
end

-- Enclume : corne effilée, table, taille, pieds, liseré de chaleur ; marteau posé contre
local function enclume(parent: Instance, x: number, yBas: number, h: number)
	local g = K.groupe(parent, x, yBas, h * 1.9, h, BAS)
	local fer = rgb(52, 50, 56)
	K.ombre(g, 0.5, 0.98, 1.05, 0.08, 0.35)
	K.bloc(g, 0.5, 1, 0.62, 0.2, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.metal(fer:Lerp(NOIR, 0.2)), 90), trait(rgb(14, 14, 16), 1.5)})
	K.bloc(g, 0.5, 0.82, 0.3, 0.32, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.metal(fer), 0), trait(rgb(14, 14, 16), 1.5)})
	K.bloc(g, 0.55, 0.5, 0.66, 0.22, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, rgb(255, 160, 80)}, {0.08, rgb(150, 150, 160)}, {0.2, fer}, {1, fer:Lerp(NOIR, 0.5)}}), 90),
		trait(rgb(14, 14, 16), 1.5)})
	K.seg(g, 0.23, 0.33, 0.04, 0.37, 0.12, fer, 0) -- corne
	K.seg(g, 0.08, 0.36, -0.06, 0.39, 0.06, fer:Lerp(BLANC, 0.1), 0)
	K.bloc(g, 0.75, 0.34, 0.035, 0.04, rgb(14, 14, 16)) -- trou carré
	-- marteau
	K.seg(g, 0.92, 1, 1.02, 0.45, 0.06, rgb(110, 74, 46))
	K.bloc(g, 1.03, 0.43, 0.2, 0.1, BLANC, {Rotation = 12}, {K.degrade(nil, K.metal(rgb(90, 88, 96)), 90), trait(rgb(14, 14, 16), 1.2)})
end

local function decorFonderie(c, rng: Random): (number) -> ()
	local loin, milieu, proche = c.loin, c.milieu, c.proche
	local FER = rgb(56, 50, 52)
	local CUIVRE = rgb(186, 110, 64)
	-- cheminée et tuyauterie au fond
	local fumee = cheminee(loin, 0.3, 0.72, 0.13, 0.62, rng)
	local tuyaux = K.groupe(loin, 0.5, 0.72, 2.4, 0.72, BAS)
	K.tuyau(tuyaux, {{0.0, 0.6}, {0.28, 0.6}, {0.28, 0.25}, {0.4, 0.25}}, 0.028, CUIVRE)
	K.tuyau(tuyaux, {{1.0, 0.45}, {0.7, 0.45}, {0.7, 0.8}, {0.62, 0.8}}, 0.032, CUIVRE:Lerp(NOIR, 0.15))
	-- engrenages géants
	local engrenages = {
		{K.engrenage(loin, 0.12, 0.2, 0.5, rgb(64, 58, 60), 18, 2), 9},
		{K.engrenage(loin, 0.29, 0.06, 0.26, rgb(58, 52, 54), 12, 1), -16},
		{K.engrenage(loin, 0.88, 0.27, 0.56, rgb(68, 60, 60), 20, 2), -7},
		{K.engrenage(loin, 0.71, 0.08, 0.24, rgb(54, 48, 50), 11, 1), 17},
	}
	-- poutrelles rivetées et treillis
	for _, y in {0.47, 0.56} do
		local b = creer("Frame", {Position = UDim2.fromScale(-0.02, y), Size = UDim2.fromScale(1.04, 0.024), BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = loin},
			{K.degrade(nil, K.metal(FER), 90), trait(rgb(14, 12, 14), 1)})
		local _ = b
	end
	local treillis = K.groupe(loin, 0.5, 0.565, 2.6, 0.09, BAS)
	for i = 0, 25 do
		local x0, x1 = i / 26, (i + 1) / 26
		local f = K.seg(treillis, x0, if i % 2 == 0 then 0 else 1, x1, if i % 2 == 0 then 1 else 0, 0.1, BLANC)
		K.degrade(f, K.metal(FER:Lerp(NOIR, 0.15)), 90)
		K.rivet(treillis, x0, if i % 2 == 0 then 0.08 else 0.92, 0.12)
	end
	-- lueur de l'Abîme
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.7), Size = UDim2.fromScale(1.04, 0.32), BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = milieu},
		{K.degrade(nil, K.seq({{0, rgb(255, 110, 30)}, {1, rgb(255, 200, 90)}}), 90, K.transp({{0, 1}, {0.6, 0.55}, {1, 0.15}}))})
	-- cuves
	local cuves = {cuve(milieu, 0.15, 0.9, 0.16, 0.22, rng), cuve(milieu, 0.86, 0.92, 0.18, 0.26, rng)}
	-- creuset suspendu
	local potence = K.groupe(milieu, 0.5, 0, 0.5, 0.06, HAUT)
	K.poutre(potence, 0, 0, 1, 0.55, FER, rng, 1)
	K.rivet(potence, 0.25, 0.27, 0.3)
	K.rivet(potence, 0.75, 0.27, 0.3)
	local chaines = K.groupe(milieu, 0.5, 0.03, 0.3, 0.2, HAUT)
	K.chaine(chaines, 0.22, 0, 0.34, 1, 9, 0.06, rgb(100, 96, 100))
	K.chaine(chaines, 0.78, 0, 0.66, 1, 9, 0.06, rgb(100, 96, 100))
	local creuset = K.groupe(milieu, 0.5, 0.215, 0.24, 0.14, HAUT)
	local coulee = K.coulee(creuset, 0.95, 0.3, 0.075, 3.72, rgb(220, 60, 14), rgb(255, 150, 36), rgb(255, 245, 190), rng)
	local _, creusetHalo = K.lueur(creuset, 0.5, 0.15, 1.6, rgb(255, 150, 40), 0.8, nil, 5)
	K.bloc(creuset, 0.5, 0.58, 0.82, 0.8, BLANC, {}, {coin(0.35), K.degrade(nil, K.metal(CUIVRE), 0), trait(rgb(40, 22, 14), 2)})
	for _, by in {0.42, 0.72} do
		K.bloc(creuset, 0.5, by, 0.84, 0.07, BLANC, {}, {K.degrade(nil, K.metal(rgb(70, 64, 66)), 90), trait(rgb(20, 18, 20), 1)})
		for k = 1, 5 do
			K.rivet(creuset, 0.1 + k * 0.133, by, 0.05)
		end
	end
	for _, tx in {0.06, 0.94} do -- tourillons
		K.disque(creuset, tx, 0.4, 0.16, rgb(70, 64, 66))
		K.rivet(creuset, tx, 0.4, 0.08)
	end
	K.bloc(creuset, 0.5, 0.15, 0.96, 0.13, BLANC, {}, {coin(0.3), K.degrade(nil, K.metal(CUIVRE:Lerp(BLANC, 0.1)), 90), trait(rgb(40, 22, 14), 1.5)})
	local surface = K.ellipse(creuset, 0.5, 0.17, 0.78, 0.09, BLANC, 0, {K.degrade(nil, K.seq({{0, rgb(220, 70, 14)}, {0.3, rgb(255, 170, 50)}, {0.5, rgb(255, 245, 190)},
		{0.7, rgb(255, 170, 50)}, {1, rgb(220, 70, 14)}}), 0)})
	K.bloc(creuset, 0.95, 0.27, 0.16, 0.1, BLANC, {}, {K.degrade(nil, K.metal(CUIVRE), 90), trait(rgb(40, 22, 14), 1.2)}) -- bec
	local bain = K.bain(creuset, 0.95, 4.08, 2.3, 0.55, rng, rgb(50, 40, 40))
	for i = -1, 1, 2 do -- lingotières qui se remplissent
		local m = K.groupe(creuset, 0.95 + i * 1.6, 4.1, 0.55, 0.2, CENTRE)
		K.bloc(m, 0.5, 0.5, 1, 1, BLANC, {}, {K.degrade(nil, K.metal(rgb(60, 56, 58)), 90), trait(rgb(14, 12, 14), 1.5)})
		K.bloc(m, 0.5, 0.45, 0.8, 0.5, BLANC, {}, {K.degrade(nil, K.seq({{0, rgb(255, 230, 140)}, {1, rgb(230, 90, 20)}}), 90)})
	end
	-- braises au pied du creuset
	local braises = {}
	local tas = K.groupe(milieu, 0.38, 0.99, 0.22, 0.06, BAS)
	K.ellipse(tas, 0.5, 0.7, 1, 0.7, rgb(30, 20, 18), 0, {K.degrade(nil, K.seq({{0, rgb(70, 40, 30)}, {1, rgb(16, 10, 10)}}), 90)})
	for _ = 1, 12 do
		local b = K.disque(tas, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.45, 0.9), rng:NextNumber(0.15, 0.3), rgb(255, 120, 30), 0)
		table.insert(braises, {b, rng:NextNumber(0, 6.28)})
	end
	-- premier plan : chaînes, enclume, brasero, sol de plaques rivetées
	local g1 = K.groupe(proche, 0.05, 0, 0.06, 0.55, HAUT)
	K.chaine(g1, 0.5, 0, 0.5, 1, 11, 0.06, rgb(80, 76, 80))
	local g2 = K.groupe(proche, 0.95, 0, 0.06, 0.42, HAUT)
	K.chaine(g2, 0.5, 0, 0.5, 1, 8, 0.075, rgb(80, 76, 80))
	enclume(proche, 0.16, 0.97, 0.16)
	local brasero = K.groupe(proche, 0.86, 0.97, 0.2, 0.28, BAS)
	K.seg(brasero, 0.3, 1, 0.42, 0.56, 0.05, rgb(46, 44, 48))
	K.seg(brasero, 0.7, 1, 0.58, 0.56, 0.05, rgb(46, 44, 48))
	local feu = K.feu(brasero, 0.5, 0.52, 0.55, {coeur = rgb(255, 250, 220), jaune = rgb(255, 220, 90), orange = rgb(255, 130, 30), rouge = rgb(170, 30, 10)}, rng)
	K.bloc(brasero, 0.5, 0.56, 0.82, 0.14, BLANC, {}, {coin(0.35), K.degrade(nil, K.metal(rgb(70, 64, 66)), 90), trait(rgb(14, 12, 14), 1.5)})
	for k = 1, 4 do
		K.rivet(brasero, 0.12 + k * 0.15, 0.56, 0.03)
	end
	local sol = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(-0.02, 1.01), Size = UDim2.fromScale(1.04, 0.06), BackgroundTransparency = 1, Parent = proche})
	for k = 0, 7 do
		local p = K.bloc(sol, (k + 0.5) / 8, 0.5, 1 / 8 - 0.004, 1, BLANC, {}, {K.degrade(nil, K.metal(rgb(44, 40, 42)), 90), trait(rgb(10, 8, 10), 1)})
		local _ = p
		for _, rx in {0.1, 0.9} do
			K.disque(sol, (k + rx) / 8, 0.3, 0.18, rgb(120, 116, 120))
		end
	end
	return function(t: number)
		for _, e in engrenages do
			e[1].Rotation = (t * e[2]) % 360
		end
		fumee(t)
		for _, cv in cuves do cv(t) end
		coulee(t)
		bain(t)
		feu(t)
		creusetHalo.Scale = 1 + 0.05 * math.sin(t * 2.4)
		surface.BackgroundColor3 = BLANC:Lerp(rgb(255, 220, 160), 0.5 + 0.5 * math.sin(t * 3))
		for _, b in braises do
			b[1].BackgroundColor3 = rgb(200, 50, 10):Lerp(rgb(255, 200, 80), 0.5 + 0.5 * math.sin(t * 2.5 + b[2]))
		end
	end
end

-- ================= Palier 4 : Les Rivières de lave =================
local FEU = {coeur = rgb(255, 250, 225), jaune = rgb(255, 214, 80), orange = rgb(255, 120, 26), rouge = rgb(150, 24, 8)}

-- Orgue de basalte : colonnes hexagonales (trois facettes, dessus clair, fractures, fissures de lave)
local function orgue(parent: Instance, x: number, n: number, w: number, hMax: number, rng: Random)
	local g = K.groupe(parent, x, 1.0, w, hMax, BAS)
	local B = rgb(40, 32, 34)
	for i = 1, n do
		local h = rng:NextNumber(0.35, 1)
		local cx = (i - 0.5) / n
		local cw = 0.94 / n
		K.bloc(g, cx - cw * 0.33, 1, cw * 0.34, h, B:Lerp(BLANC, 0.12), {AnchorPoint = BAS}, {trait(B:Lerp(NOIR, 0.6), 1)})
		K.bloc(g, cx, 1, cw * 0.34, h, B, {AnchorPoint = BAS}, {trait(B:Lerp(NOIR, 0.6), 1)})
		K.bloc(g, cx + cw * 0.33, 1, cw * 0.34, h, B:Lerp(NOIR, 0.35), {AnchorPoint = BAS}, {trait(B:Lerp(NOIR, 0.6), 1)})
		K.bloc(g, cx, 1 - h, cw, 0.03, B:Lerp(BLANC, 0.25), {}, {coin(0.4), K.degrade(nil, K.seq({{0, rgb(255, 130, 50)}, {0.3, B:Lerp(BLANC, 0.3)}, {1, B}}), 90)})
		for _ = 1, 2 do
			K.bloc(g, cx, 1 - h * rng:NextNumber(0.2, 0.8), cw * 1.02, 0.006, B:Lerp(NOIR, 0.6), {BackgroundTransparency = 0.2})
		end
		if rng:NextNumber() < 0.55 then
			local fx = cx + rng:NextNumber(-0.25, 0.25) * cw
			K.bloc(g, fx, 1, cw * 0.18, h * 0.65, rgb(255, 110, 30), {AnchorPoint = BAS, BackgroundTransparency = 0.75})
			K.bloc(g, fx, 1, cw * 0.06, h * 0.6, rgb(255, 190, 80), {AnchorPoint = BAS, BackgroundTransparency = 0.15},
				{K.degrade(nil, nil, 90, K.transp({{0, 1}, {0.3, 0.2}, {1, 0}}))})
		end
	end
end

-- Corne torsadée le long d'une courbe : bandes alternées, sillons de torsion, reflet
local function corne(g: Instance, pts: {{number}}, ep0: number)
	local n = #pts - 1
	for i = 1, n do
		local a, b = pts[i], pts[i + 1]
		local e = ep0 * (1 - (i - 1) / n * 0.8)
		local cc = if i % 2 == 0 then rgb(72, 50, 40) else rgb(48, 32, 26)
		local f = K.seg(g, a[1], a[2], b[1], b[2], e, BLANC)
		K.degrade(f, K.seq({{0, cc:Lerp(rgb(230, 210, 180), 0.45)}, {0.4, cc}, {1, cc:Lerp(NOIR, 0.5)}}), 90)
		coin(0.3).Parent = f
		K.disque(g, b[1], b[2], e * 0.9, cc)
		-- sillon de torsion en biais
		local mx, my = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
		local x1, y1 = K.decaler(g, mx - (b[1] - a[1]) * 0.25, my - (b[2] - a[2]) * 0.25, mx + (b[1] - a[1]) * 0.25, my + (b[2] - a[2]) * 0.25, e * 0.45)
		local _, _, x4, y4 = K.decaler(g, mx - (b[1] - a[1]) * 0.25, my - (b[2] - a[2]) * 0.25, mx + (b[1] - a[1]) * 0.25, my + (b[2] - a[2]) * 0.25, -e * 0.45)
		K.seg(g, x1, y1, x4, y4, e * 0.12, rgb(20, 12, 10), 0.3)
		local r1, s1, r2, s2 = K.decaler(g, a[1], a[2], b[1], b[2], -e * 0.25)
		K.seg(g, r1, s1, r2, s2, e * 0.12, rgb(240, 220, 190), 0.55)
	end
	local fin = pts[#pts]
	K.disque(g, fin[1], fin[2], ep0 * 0.18, rgb(255, 170, 70), 0.1)
end

-- Petit crâne (calotte, orbites rougeoyantes, nez, mâchoire à dents)
local function crane(g: Instance, x: number, y: number, d: number): {Frame}
	local os_ = rgb(222, 206, 178)
	local cal = K.disque(g, x, y, d, BLANC)
	K.degrade(cal, K.seq({{0, os_:Lerp(BLANC, 0.4)}, {0.5, os_}, {1, os_:Lerp(NOIR, 0.5)}}), 45)
	trait(rgb(40, 26, 20), 1.5).Parent = cal
	K.bloc(g, x, y + d * 0.48, d * 0.58, d * 0.3, BLANC, {}, {coin(0.25), K.degrade(nil, K.seq({{0, os_}, {1, os_:Lerp(NOIR, 0.45)}}), 90), trait(rgb(40, 26, 20), 1.2)})
	for k = -2, 2 do
		K.bloc(g, x + k * d * 0.1, y + d * 0.5, d * 0.07, d * 0.13, os_:Lerp(BLANC, 0.3), {}, {trait(rgb(40, 26, 20), 1)})
	end
	local yeux = {}
	for _, s in {-1, 1} do
		K.disque(g, x + s * d * 0.2, y + d * 0.06, d * 0.26, rgb(20, 8, 6))
		table.insert(yeux, K.disque(g, x + s * d * 0.2, y + d * 0.08, d * 0.1, rgb(255, 60, 30)))
	end
	K.bloc(g, x, y + d * 0.28, d * 0.08, d * 0.08, rgb(20, 8, 6), {Rotation = 45, SizeConstraint = YY})
	K.seg(g, x + d * 0.1, y - d * 0.45, x + d * 0.22, y - d * 0.15, d * 0.03, rgb(60, 40, 30), 0.2)
	return yeux
end

-- Trône du Roi déchu : estrade à marches veinées de lave, socle sculpté, coussin, dossier à nervures et à pointes,
-- crâne aux cornes torsadées, gemme de feu à facettes, accoudoirs à crânes, coulées de lave ; renvoie l'animation
local function trone(parent: Instance, rng: Random): (number) -> ()
	local g = K.groupe(parent, 0.5, 0.68, 0.48, 0.48, BAS)
	local OBS = rgb(22, 14, 20)
	local BAS_ = rgb(40, 30, 32)
	local _, halo = K.lueur(g, 0.5, 0.42, 1.25, rgb(255, 70, 30), 0.84, nil, 6)
	-- estrade
	local fissures = {}
	for k = 0, 3 do
		local yb = 1 - k * 0.075
		local w = 1 - k * 0.14
		K.bloc(g, 0.5, yb, w, 0.06, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, BAS_:Lerp(BLANC, 0.1)}, {1, BAS_:Lerp(NOIR, 0.5)}}), 90), trait(rgb(10, 6, 6), 1.2)})
		K.bloc(g, 0.5, yb - 0.06, w, 0.015, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, BAS_:Lerp(BLANC, 0.3)}, {1, BAS_:Lerp(BLANC, 0.1)}}), 90)})
		K.bloc(g, 0.5, yb - 0.075, w, 0.004, rgb(255, 120, 40), {AnchorPoint = HAUT, BackgroundTransparency = 0.3})
		for _ = 1, 2 do
			local fx = 0.5 + rng:NextNumber(-0.45, 0.45) * w
			local f1 = K.seg(g, fx, yb - 0.055, fx + rng:NextNumber(-0.03, 0.03), yb - 0.03, 0.008, rgb(255, 140, 40))
			local f2 = K.seg(g, f1.Position.X.Scale + 0.01, yb - 0.03, fx + rng:NextNumber(-0.04, 0.04), yb - 0.004, 0.006, rgb(255, 110, 30))
			K.seg(g, fx, yb - 0.05, fx, yb - 0.005, 0.03, rgb(255, 90, 20), 0.8)
			table.insert(fissures, f1)
			table.insert(fissures, f2)
		end
	end
	-- coulées de lave qui descendent l'estrade
	for _, s in {-1, 1} do
		local cx = 0.5 + s * 0.24
		K.bloc(g, cx, 1, 0.026, 0.3, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.seq({{0, rgb(255, 200, 80)}, {1, rgb(200, 50, 10)}}), 90)})
		K.bloc(g, cx, 1, 0.07, 0.3, rgb(255, 100, 20), {AnchorPoint = BAS, BackgroundTransparency = 0.8})
	end
	-- socle sculpté
	K.bloc(g, 0.5, 0.7, 0.42, 0.11, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(OBS), 0), trait(rgb(6, 2, 6), 1.5)})
	K.bloc(g, 0.5, 0.645, 0.34, 0.06, BLANC, {BackgroundTransparency = 1}, {trait(rgb(160, 50, 20), 1.5, 0.2)})
	K.seg(g, 0.36, 0.645, 0.64, 0.645, 0.006, rgb(255, 120, 40), 0.1)
	-- accoudoirs et leurs crânes
	local yeux = {}
	for _, s in {-1, 1} do
		local ax = 0.5 + s * 0.22
		K.bloc(g, ax, 0.7, 0.06, 0.12, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(OBS), 0), trait(rgb(6, 2, 6), 1.2)})
		K.bloc(g, ax - s * 0.02, 0.575, 0.12, 0.03, BLANC, {}, {K.degrade(nil, K.metal(OBS:Lerp(BLANC, 0.1)), 90), trait(rgb(6, 2, 6), 1.2)})
		for _, o in crane(g, ax + s * 0.035, 0.555, 0.045) do table.insert(yeux, o) end
	end
	-- dossier : dalle, bordure sculptée, nervures, inscription de lave
	K.bloc(g, 0.5, 0.6, 0.34, 0.46, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(OBS), 0), trait(rgb(6, 2, 6), 1.5)})
	K.bloc(g, 0.5, 0.38, 0.27, 0.38, BLANC, {BackgroundTransparency = 1}, {trait(rgb(120, 40, 20), 1.5, 0.15)})
	for _, nx in {0.4, 0.6} do
		K.bloc(g, nx, 0.4, 0.018, 0.36, OBS:Lerp(BLANC, 0.12), {}, {trait(rgb(6, 2, 6), 1)})
	end
	local inscription = {}
	for k = 0, 3 do
		local y = 0.3 + k * 0.06
		table.insert(inscription, K.seg(g, 0.47, y, 0.5, y + 0.025, 0.006, rgb(255, 120, 40)))
		table.insert(inscription, K.seg(g, 0.53, y, 0.5, y + 0.025, 0.006, rgb(255, 120, 40)))
	end
	-- pointes de la couronne du dossier
	for _, p in {{0.35, 0.08, 0.05}, {0.42, 0.13, 0.055}, {0.5, 0.18, 0.06}, {0.58, 0.13, 0.055}, {0.65, 0.08, 0.05}} do
		K.pic(g, p[1], 0.15, p[3], p[2], OBS:Lerp(BLANC, 0.06), false, 5, nil, rgb(255, 140, 50))
	end
	-- coussin
	K.bloc(g, 0.5, 0.6, 0.34, 0.05, BLANC, {AnchorPoint = BAS}, {coin(0.4), K.degrade(nil, K.seq({{0, rgb(170, 40, 40)}, {1, rgb(70, 10, 14)}}), 90), trait(rgb(30, 4, 6), 1.2)})
	K.bloc(g, 0.5, 0.56, 0.28, 0.008, rgb(255, 180, 160), {BackgroundTransparency = 0.6})
	-- gemme de feu sertie
	local _, gemmeHalo = K.lueur(g, 0.5, 0.29, 0.22, rgb(255, 60, 30), 0.72, nil, 5)
	K.bloc(g, 0.5, 0.29, 0.07, 0.07, BLANC, {SizeConstraint = YY, Rotation = 45, BackgroundTransparency = 1}, {trait(rgb(200, 150, 60), 2.5)})
	local gemme = K.bloc(g, 0.5, 0.29, 0.055, 0.055, BLANC, {SizeConstraint = YY, Rotation = 45},
		{K.degrade(nil, K.seq({{0, rgb(255, 170, 120)}, {0.5, rgb(230, 30, 20)}, {0.501, rgb(160, 10, 10)}, {1, rgb(60, 0, 0)}}), -45)})
	K.bloc(g, 0.5, 0.29, 0.025, 0.025, rgb(255, 120, 80), {SizeConstraint = YY, Rotation = 45, BackgroundTransparency = 0.2})
	K.disque(g, 0.49, 0.278, 0.012, BLANC, 0.1)
	-- crâne et cornes torsadées au sommet
	for _, o in crane(g, 0.5, 0.175, 0.075) do table.insert(yeux, o) end
	corne(g, {{0.47, 0.17}, {0.42, 0.16}, {0.37, 0.12}, {0.34, 0.07}, {0.345, 0.025}, {0.37, 0.0}}, 0.03)
	corne(g, {{0.53, 0.17}, {0.58, 0.16}, {0.63, 0.12}, {0.66, 0.07}, {0.655, 0.025}, {0.63, 0.0}}, 0.03)
	return function(t: number)
		halo.Scale = 1 + 0.05 * math.sin(t * 1.6)
		local p = 0.5 + 0.5 * math.sin(t * 2.2)
		gemmeHalo.Scale = 1 + 0.18 * p
		gemme.BackgroundTransparency = 0.15 * (1 - p)
		for _, o in yeux do
			o.BackgroundColor3 = rgb(200, 30, 10):Lerp(rgb(255, 170, 60), p)
		end
		local q = 0.5 + 0.5 * math.sin(t * 1.3)
		for i, f in fissures do
			f.BackgroundColor3 = rgb(255, 90, 20):Lerp(rgb(255, 210, 100), (q + i * 0.13) % 1)
		end
		for _, f in inscription do
			f.BackgroundTransparency = 0.4 * (1 - q)
		end
	end
end

local function decorLave(c, rng: Random): (number) -> ()
	local loin, milieu, proche = c.loin, c.milieu, c.proche
	K.rangee(loin, rng, 12, rgb(36, 14, 12), 0.06, 0.18, 0.05, 0.1, true, 0, nil, rgb(255, 120, 40))
	local chutes = {
		K.coulee(loin, 0.1, 0, 0.042, 0.64, rgb(180, 40, 10), rgb(255, 120, 26), rgb(255, 235, 150), rng),
		K.coulee(loin, 0.9, 0, 0.055, 0.64, rgb(180, 40, 10), rgb(255, 120, 26), rgb(255, 235, 150), rng),
	}
	-- crête lointaine éclairée par-dessous
	local x = -0.02
	while x < 1.02 do
		local w = rng:NextNumber(0.04, 0.09)
		local h = rng:NextNumber(0.03, 0.09)
		creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(x, 0.66), Size = UDim2.fromScale(w + 0.003, h),
			BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = loin}, {K.degrade(nil, K.seq({{0, rgb(34, 14, 12)}, {1, rgb(90, 30, 14)}}), 90)})
		x += w
	end
	-- colonnes de feu sur leurs braseros, de part et d'autre du trône
	local feux = {}
	for _, fx in {0.31, 0.69} do
		local b = K.groupe(loin, fx, 0.66, 0.07, 0.1, BAS)
		K.bloc(b, 0.5, 1, 0.5, 0.7, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(rgb(40, 30, 32)), 0), trait(rgb(10, 6, 6), 1.2)})
		K.bloc(b, 0.5, 0.32, 1, 0.22, BLANC, {}, {coin(0.3), K.degrade(nil, K.relief(rgb(52, 38, 40)), 90), trait(rgb(10, 6, 6), 1.2)})
		table.insert(feux, K.feu(loin, fx, 0.6, 0.26, FEU, rng))
	end
	local anim = trone(loin, rng)
	-- orgues de basalte
	orgue(milieu, 0.13, 6, 0.5, 0.52, rng)
	orgue(milieu, 0.88, 7, 0.56, 0.6, rng)
	-- rivière de lave au premier plan : chaleur, dégradé, courants lumineux, croûtes, bulles
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.66), Size = UDim2.fromScale(1.04, 0.2), BackgroundColor3 = rgb(255, 110, 30), BorderSizePixel = 0, Parent = proche},
		{K.degrade(nil, nil, 90, K.transp({{0, 1}, {1, 0.5}}))})
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.85), Size = UDim2.fromScale(1.04, 0.16), BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = proche},
		{K.degrade(nil, K.seq({{0, rgb(255, 240, 160)}, {0.25, rgb(255, 170, 40)}, {0.6, rgb(240, 90, 16)}, {1, rgb(150, 24, 8)}}), 90)})
	creer("Frame", {Position = UDim2.fromScale(-0.02, 0.849), Size = UDim2.new(1.04, 0, 0, 3), BackgroundColor3 = rgb(255, 250, 220), BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Parent = proche})
	local courants = {}
	for _ = 1, 9 do
		local f = K.bloc(proche, 0, rng:NextNumber(0.87, 0.98), rng:NextNumber(0.08, 0.2), 0.006, rgb(255, 245, 190), {SizeConstraint = YY, BackgroundTransparency = 0.25},
			{coin(0.5), K.degrade(nil, nil, 0, K.transp({{0, 1}, {0.5, 0}, {1, 1}}))})
		table.insert(courants, {f, rng:NextNumber(0, 1.3), rng:NextNumber(0.02, 0.05)})
	end
	local croutes = {}
	for _ = 1, 9 do
		local w = rng:NextNumber(0.06, 0.14)
		local f = K.bloc(proche, 0, rng:NextNumber(0.88, 0.97), w, w * 0.22, BLANC, {SizeConstraint = YY}, {coin(0.5), trait(rgb(255, 160, 50), 1.5, 0.1),
			K.degrade(nil, K.seq({{0, rgb(80, 40, 28)}, {1, rgb(28, 12, 10)}}), 90)})
		table.insert(croutes, {f, rng:NextNumber(0, 1.2), rng:NextNumber(0.008, 0.02)})
	end
	local bulles = {}
	for _ = 1, 6 do
		local f = K.disque(proche, 0.5, 0.9, 0.02, rgb(255, 230, 150), 0)
		trait(rgb(255, 250, 220), 1, 0.2).Parent = f
		table.insert(bulles, {f, rng:NextNumber(0, 1), rng:NextNumber(0.6, 1)})
	end
	-- pics d'obsidienne
	for _, p in {{0.02, 0.4}, {0.09, 0.26}, {0.93, 0.3}, {0.99, 0.44}} do
		K.pic(proche, p[1], 1.01, 0.09, p[2], rgb(18, 10, 16), false, 6, nil, rgb(255, 120, 50))
	end
	return function(t: number)
		for _, ch in chutes do ch(t) end
		for _, f in feux do f(t) end
		anim(t)
		for _, cr in courants do
			cr[1].Position = UDim2.fromScale(((cr[2] + t * cr[3]) % 1.3) - 0.15, cr[1].Position.Y.Scale)
		end
		for _, cr in croutes do
			cr[1].Position = UDim2.fromScale(((cr[2] + t * cr[3]) % 1.24) - 0.12, cr[1].Position.Y.Scale)
		end
		for _, b in bulles do
			local ph = (b[2] + t * b[3]) % 1
			if ph < 0.03 then
				b[1].Position = UDim2.fromScale(math.random() * 0.9 + 0.05, 0.88 + math.random() * 0.1)
			end
			b[1].Size = UDim2.fromScale(0.008 + ph * 0.025, 0.008 + ph * 0.025)
			b[1].BackgroundTransparency = if ph > 0.8 then (ph - 0.8) / 0.2 else 0.05
		end
	end
end

-- ================= Palier 5 : Le Cœur maudit =================
local MAGENTA, VIOLET = rgb(255, 60, 220), rgb(150, 80, 255)

-- Rocher flottant : dessus moussu violet, strates, fissure lumineuse, cristaux, débris, lueur dessous
local function rocherFlottant(parent: Instance, x: number, y: number, h: number, rng: Random): Frame
	local g = K.groupe(parent, x, y, h * 1.6, h, CENTRE)
	local R = rgb(54, 40, 66)
	K.lueur(g, 0.5, 0.95, 0.9, MAGENTA, 0.86, nil, 4)
	K.bloc(g, 0.5, 0.88, 0.3, 0.2, BLANC, {}, {K.degrade(nil, K.relief(R:Lerp(NOIR, 0.3)), 0), trait(R:Lerp(NOIR, 0.6), 1)})
	K.bloc(g, 0.48, 0.68, 0.62, 0.28, BLANC, {}, {K.degrade(nil, K.relief(R:Lerp(NOIR, 0.15)), 0), trait(R:Lerp(NOIR, 0.6), 1)})
	K.bloc(g, 0.5, 0.42, 0.92, 0.32, BLANC, {}, {K.degrade(nil, K.relief(R), 0), trait(R:Lerp(NOIR, 0.6), 1.2)})
	K.ellipse(g, 0.5, 0.26, 0.96, 0.14, rgb(110, 70, 140), 0, {K.degrade(nil, K.seq({{0, rgb(160, 110, 190)}, {1, rgb(70, 40, 90)}}), 90)})
	K.seg(g, 0.3, 0.35, 0.45, 0.55, 0.035, MAGENTA, 0.1)
	K.seg(g, 0.45, 0.55, 0.42, 0.75, 0.025, MAGENTA, 0.2)
	K.seg(g, 0.3, 0.35, 0.45, 0.55, 0.12, MAGENTA, 0.8)
	for k = 1, 2 do
		K.cristal(g, 0.3 + k * 0.22, 0.27, 0.07, rng:NextNumber(0.25, 0.4), rgb(255, 120, 240), rgb(120, 30, 160))
	end
	K.bloc(g, 0.38, 1.05, 0.06, 0.08, R:Lerp(NOIR, 0.2), {Rotation = 20})
	K.bloc(g, 0.62, 1.12, 0.04, 0.06, R:Lerp(NOIR, 0.2), {Rotation = -15})
	return g
end

-- Cœur de cristal : contour sombre, lobes et pointe à facettes, cœur interne qui pulse, fissures, reflets, anneaux
local function coeurCristal(parent: Instance, rng: Random): (Frame, UIScale, UIScale, Frame)
	local g = K.groupe(parent, 0.5, 0.46, 0.32, 0.32, CENTRE)
	local battement = creer("UIScale", {Parent = g})
	local function forme(echelle: number, c1: Color3, c2: Color3, transp: number)
		local s = 0.42 * echelle
		local hd = s / math.sqrt(2)
		local cy = 0.6
		K.bloc(g, 0.5, cy, s, s, BLANC, {SizeConstraint = YY, Rotation = 45, BackgroundTransparency = transp},
			{K.degrade(nil, K.seq({{0, c1}, {0.5, c1:Lerp(c2, 0.5)}, {0.501, c2}, {1, c2:Lerp(NOIR, 0.4)}}), -45)})
		K.disque(g, 0.5 - hd / 2, cy - hd / 2, s, c1, transp)
		K.disque(g, 0.5 + hd / 2, cy - hd / 2, s, c2, transp)
	end
	forme(1.1, rgb(70, 0, 60), rgb(40, 0, 40), 0)
	forme(1, rgb(255, 110, 240), rgb(170, 20, 150), 0)
	-- facettes
	for _, s in {{0.5, 0.36, 0.5, 0.9}, {0.35, 0.45, 0.5, 0.9}, {0.65, 0.45, 0.5, 0.9}, {0.35, 0.45, 0.5, 0.36}, {0.65, 0.45, 0.5, 0.36}, {0.2, 0.42, 0.35, 0.45}, {0.8, 0.42, 0.65, 0.45}} do
		K.seg(g, s[1], s[2], s[3], s[4], 0.008, rgb(255, 210, 250), 0.45)
	end
	-- cœur interne
	local _, interne = K.lueur(g, 0.5, 0.55, 0.55, rgb(255, 220, 255), 0.55, nil, 5)
	-- fissures maudites
	K.fissure(g, 0.42, 0.5, math.rad(110), 0.22, 0.01, 1, rng, rgb(255, 160, 255))
	K.fissure(g, 0.6, 0.42, math.rad(40), 0.16, 0.008, 1, rng, rgb(255, 160, 255))
	-- reflets
	K.ellipse(g, 0.32, 0.36, 0.1, 0.05, BLANC, 0.35)
	K.disque(g, 0.29, 0.35, 0.025, BLANC, 0)
	-- anneaux de fer qui le retiennent
	local anneaux = {}
	for _, p in {{0.24, 0.32}, {0.76, 0.32}, {0.38, 0.22}, {0.62, 0.22}} do
		local a = K.disque(g, p[1], p[2], 0.07, BLANC, 1)
		trait(rgb(120, 110, 130), 3).Parent = a
		table.insert(anneaux, a)
	end
	return g, battement, interne, anneaux[1]
end

local function decorCoeur(c, rng: Random): (number) -> ()
	local loin, milieu, proche = c.loin, c.milieu, c.proche
	-- failles du vide : fissures ramifiées à bords lumineux, éclats aspirés
	local eclats = {}
	for _, f in {{0.17, 0.08, 1.2}, {0.35, 0.2, 1.4}, {0.83, 0.1, 1.5}} do
		local g = K.groupe(loin, f[1], 0.75, 0.6, 0.7, BAS)
		K.lueur(g, 0.5, 0.5, 0.8, VIOLET, 0.86, nil, 5)
		K.fissure(g, 0.5, 0.02, f[3], 0.95, 0.03, 2, rng, VIOLET)
		for _ = 1, 5 do
			local e = K.feuille(g, rng:NextNumber(0.3, 0.7), rng:NextNumber(0.2, 0.8), rng:NextNumber(0.03, 0.06), rng:NextNumber(0.012, 0.02), rng:NextNumber(0, 180),
				rgb(20, 8, 30), 0, {trait(VIOLET:Lerp(BLANC, 0.3), 1, 0.2)}, true)
			table.insert(eclats, {e, e.Position.X.Scale, e.Position.Y.Scale, rng:NextNumber(0, 6.28)})
		end
	end
	-- cercle de runes (deux couronnes, graduations, glyphes lumineux), qui tourne
	local runes = creer("CanvasGroup", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.7, 0.7), SizeConstraint = YY,
		BackgroundTransparency = 1, GroupTransparency = 0.2, Parent = loin})
	K.ratio(runes, 1)
	for _, d in {{0.98, 3}, {0.9, 1.5}, {0.76, 2}} do
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(d[1], d[1]), BackgroundTransparency = 1, Parent = runes},
			{coin(0.5), trait(VIOLET, d[2], 0.25)})
	end
	for i = 1, 36 do
		local a = i / 36 * math.pi * 2
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + math.cos(a) * 0.47, 0.5 + math.sin(a) * 0.47), Size = UDim2.fromScale(0.025, if i % 3 == 0 then 0.006 else 0.003),
			Rotation = math.deg(a), BackgroundColor3 = MAGENTA, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = runes})
	end
	local glyphes = {
		{{0.5, 0, 0.5, 1}, {0.5, 0.3, 0.9, 0}},
		{{0.2, 0, 0.2, 1}, {0.2, 0.5, 0.8, 0}, {0.2, 0.5, 0.8, 1}},
		{{0.1, 1, 0.5, 0}, {0.5, 0, 0.9, 1}, {0.3, 0.6, 0.7, 0.6}},
		{{0.5, 0, 0.5, 1}, {0.1, 0.2, 0.9, 0.6}},
		{{0.2, 0.1, 0.8, 0.1}, {0.5, 0.1, 0.5, 1}, {0.2, 1, 0.8, 0.7}},
	}
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local g = creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + math.cos(a) * 0.415, 0.5 + math.sin(a) * 0.415),
			Size = UDim2.fromScale(0.055, 0.055), Rotation = math.deg(a) + 90, BackgroundTransparency = 1, Parent = runes})
		K.ratio(g, 1)
		for _, s in glyphes[(i % #glyphes) + 1] do
			K.seg(g, s[1], s[2], s[3], s[4], 0.32, MAGENTA, 0.75)
			K.seg(g, s[1], s[2], s[3], s[4], 0.11, rgb(255, 200, 250), 0)
		end
	end
	for k = 0, 3 do
		local a = k * math.pi / 2
		creer("Frame", {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + math.cos(a) * 0.49, 0.5 + math.sin(a) * 0.49), Size = UDim2.fromScale(0.04, 0.04),
			Rotation = 45, BackgroundColor3 = rgb(255, 200, 250), BorderSizePixel = 0, Parent = runes}, {trait(VIOLET, 1.5)})
	end
	-- rochers qui flottent
	local rochers = {}
	for _ = 1, 6 do
		local gx, gy = rng:NextNumber(0.05, 0.95), rng:NextNumber(0.16, 0.6)
		if math.abs(gx - 0.5) < 0.2 then gx += if gx < 0.5 then -0.22 else 0.22 end
		local r = rocherFlottant(loin, gx, gy, rng:NextNumber(0.05, 0.1), rng)
		table.insert(rochers, {r, gx, gy, rng:NextNumber(0, 6.28), rng:NextNumber(0.006, 0.014)})
	end
	-- chaînes vers le cœur
	local chaines = K.groupe(milieu, 0.5, 0, 2.0, 0.5, HAUT)
	K.chaine(chaines, 0.04, 0, 0.385, 0.6, 20, 0.03, rgb(90, 80, 100))
	K.chaine(chaines, 0.96, 0, 0.615, 0.6, 20, 0.03, rgb(90, 80, 100))
	K.chaine(chaines, 0.3, 0, 0.462, 0.75, 13, 0.026, rgb(76, 68, 86))
	K.chaine(chaines, 0.7, 0, 0.538, 0.75, 13, 0.026, rgb(76, 68, 86))
	-- cœur de cristal géant + énergie qui orbite
	local _, halo = K.lueur(milieu, 0.5, 0.46, 0.85, MAGENTA, 0.76, nil, 6)
	local _, battement, interne = coeurCristal(milieu, rng)
	local orbes = {}
	for i = 1, 7 do
		local o = K.disque(milieu, 0.5, 0.46, rng:NextNumber(0.006, 0.012), rgb(255, 190, 250), 0.1)
		table.insert(orbes, {o, i / 7 * math.pi * 2, rng:NextNumber(0.5, 1), rng:NextNumber(0.18, 0.24)})
	end
	-- piliers d'obsidienne gravés, flammes violettes
	local feux = {}
	for _, px in {0.06, 0.94} do
		local g = K.groupe(proche, px, 1.01, 0.13, 0.72, BAS)
		K.bloc(g, 0.5, 1, 0.72, 0.84, BLANC, {AnchorPoint = BAS}, {K.degrade(nil, K.relief(rgb(30, 18, 40)), 0), trait(rgb(6, 2, 10), 1.5)})
		K.bloc(g, 0.5, 0.58, 0.48, 0.5, BLANC, {BackgroundTransparency = 1}, {trait(VIOLET, 1.5, 0.3)})
		for k = 0, 2 do
			local y = 0.42 + k * 0.12
			K.seg(g, 0.4, y, 0.6, y + 0.06, 0.012, MAGENTA, 0.1)
			K.seg(g, 0.6, y, 0.4, y + 0.06, 0.012, MAGENTA, 0.1)
			K.seg(g, 0.4, y, 0.6, y + 0.06, 0.04, MAGENTA, 0.8)
		end
		K.bloc(g, 0.5, 0.17, 1, 0.05, BLANC, {}, {K.degrade(nil, K.relief(rgb(44, 30, 56)), 90), trait(rgb(6, 2, 10), 1.2)})
		K.bloc(g, 0.5, 0.21, 0.86, 0.04, BLANC, {}, {K.degrade(nil, K.relief(rgb(38, 24, 50)), 90), trait(rgb(6, 2, 10), 1.2)})
		K.bloc(g, 0.5, 0.98, 0.9, 0.05, BLANC, {}, {K.degrade(nil, K.relief(rgb(38, 24, 50)), 90), trait(rgb(6, 2, 10), 1.2)})
		table.insert(feux, K.feu(g, 0.5, 0.15, 0.24, {coeur = rgb(255, 235, 255), jaune = rgb(255, 150, 250), orange = rgb(200, 80, 255), rouge = rgb(70, 10, 110)}, rng))
	end
	local cr1 = K.amas(proche, 0.24, 1.01, 0.2, rgb(190, 70, 230), rgb(60, 10, 90), rng, rgb(30, 18, 40))
	local cr2 = K.amas(proche, 0.77, 1.01, 0.16, rgb(190, 70, 230), rgb(60, 10, 90), rng, rgb(30, 18, 40))
	K.sol(proche, rng, rgb(12, 5, 18), 0.95, nil, rgb(140, 60, 200))
	local solFissures = K.groupe(proche, 0.5, 1.0, 1.6, 0.3, BAS)
	K.fissure(solFissures, 0.08, 0.82, -0.12, 2, 0.025, 1, rng, VIOLET)
	K.fissure(solFissures, 0.62, 0.86, 0.1, 1.8, 0.022, 1, rng, VIOLET)
	return function(t: number)
		runes.Rotation = (t * 6) % 360
		for _, r in rochers do
			r[1].Position = UDim2.fromScale(r[2], r[3] + math.sin(t * 0.8 + r[4]) * r[5])
		end
		for _, e in eclats do
			local ph = (t * 0.15 + e[4]) % 1
			e[1].Position = UDim2.fromScale(e[2] + (0.5 - e[2]) * ph * 0.6, e[3] + math.sin(t + e[4]) * 0.01)
			e[1].Rotation = (t * 40 + e[4] * 50) % 360
			e[1].BackgroundTransparency = ph
		end
		-- battement double (boum-boum)
		local ph = (t * 0.9) % 1
		local b = (if ph < 0.18 then math.sin(ph * math.pi / 0.18) else 0) + (if ph > 0.24 and ph < 0.42 then 0.7 * math.sin((ph - 0.24) * math.pi / 0.18) else 0)
		battement.Scale = 1 + 0.06 * b
		halo.Scale = 1 + 0.12 * b
		interne.Scale = 0.85 + 0.35 * b
		for _, o in orbes do
			local a = o[2] + t * o[3]
			o[1].Position = UDim2.fromScale(0.5 + math.cos(a) * o[4] * 0.62, 0.46 + math.sin(a) * o[4] * 0.45)
		end
		for _, f in feux do f(t) end
		cr1.Scale = 1 + 0.08 * math.sin(t * 1.4)
		cr2.Scale = 1 + 0.08 * math.sin(t * 1.7 + 1)
	end
end

-- ================= Thèmes =================
-- couleurs : fond (haut / milieu / bas), roche de la veine, tunnel creusé, lueur du tunnel, minerais de la veine,
-- éclats de roche, étincelles, fer et bois de la pioche.
local THEMES = {
	[1] = {
		titre = "Le Lac des Lueurs",
		couleurs = {fondHaut = rgb(4, 12, 22), fondMilieu = rgb(10, 38, 54), fondBas = rgb(3, 10, 16), roche = rgb(58, 66, 86),
			creuse = rgb(10, 16, 24), accent = rgb(90, 235, 230), minerai = rgb(220, 120, 255), eclat = rgb(84, 94, 116),
			etincelle = rgb(150, 255, 240), fer = rgb(150, 160, 176), bois = rgb(120, 84, 56)},
		particules = {{nombre = 22, couleurs = {rgb(120, 255, 235), rgb(230, 140, 255)}, taille = {0.005, 0.011}, vitesse = {0.015, 0.04}, sens = -1, transp = 0.25, amplitude = 0.025}},
		lumieres = "Les lueurs s'éveillent…",
		astuces = {
			"Le camp de l'arrivée est un refuge : les mobs n'y entrent jamais.",
			"Cinq rouleaux de la carte naine sont cachés dans chaque grotte du Lac.",
			"Touche F (Y à la manette) : la boussole des feux follets guide vers la cachette la plus proche.",
			"Sur les pontons, ferre quand le curseur passe dans la zone verte.",
			"Active les trois pierres runiques dans l'ordre de la porte pour ouvrir la salle secrète.",
		},
		construire = decorLueurs,
	},
	[2] = {
		titre = "La Mine oubliée de Brumefer",
		couleurs = {fondHaut = rgb(16, 10, 8), fondMilieu = rgb(46, 30, 22), fondBas = rgb(10, 6, 6), roche = rgb(84, 66, 56),
			creuse = rgb(18, 12, 10), accent = rgb(255, 180, 90), minerai = rgb(190, 120, 255), eclat = rgb(110, 88, 72),
			etincelle = rgb(255, 210, 130), fer = rgb(140, 140, 150), bois = rgb(130, 88, 52)},
		particules = {{nombre = 24, couleurs = {rgb(255, 200, 130), rgb(200, 150, 255)}, taille = {0.003, 0.007}, vitesse = {0.008, 0.02}, sens = 1, transp = 0.35, amplitude = 0.03}},
		lumieres = "Les lanternes s'allument…",
		astuces = {
			"À la gare, monte dans le wagonnet : il file plus vite dans les descentes.",
			"L'ascenseur du Grand Puits mène à la Réserve du contremaître et à ses 3 minerais.",
			"Le cercle « Sortie » ramène devant l'entrée des grottes profondes.",
			"Le camp de l'arrivée est un refuge : les mobs n'y entrent jamais.",
		},
		construire = decorMine,
	},
	[3] = {
		titre = "La Fonderie de l'Abîme",
		couleurs = {fondHaut = rgb(14, 10, 10), fondMilieu = rgb(48, 22, 12), fondBas = rgb(30, 10, 6), roche = rgb(76, 70, 72),
			creuse = rgb(16, 12, 12), accent = rgb(255, 140, 40), minerai = rgb(210, 130, 80), eclat = rgb(96, 90, 92),
			etincelle = rgb(255, 200, 90), fer = rgb(120, 116, 120), bois = rgb(110, 72, 46)},
		particules = {{nombre = 26, couleurs = {rgb(255, 170, 60), rgb(255, 230, 140)}, taille = {0.003, 0.007}, vitesse = {0.06, 0.14}, sens = -1, transp = 0.1, amplitude = 0.012}},
		lumieres = "Les forges se rallument…",
		astuces = {
			"Verse 3 Fer dans le creuset de la Fonderie royale : +120 pièces, une seule fois.",
			"Relance les 3 manivelles : le coffre de l'Abîme remonte du gouffre.",
			"Tomber dans le gouffre coûte 15 PV : reste sur les ponts.",
			"Trois reliques volcaniques permettent de forger le Casque du Cœur Magmatique.",
		},
		construire = decorFonderie,
	},
	[4] = {
		titre = "Les Rivières de lave",
		couleurs = {fondHaut = rgb(16, 6, 6), fondMilieu = rgb(56, 16, 8), fondBas = rgb(140, 36, 8), roche = rgb(52, 42, 44),
			creuse = rgb(14, 8, 8), accent = rgb(255, 110, 30), minerai = rgb(255, 170, 60), eclat = rgb(70, 58, 60),
			etincelle = rgb(255, 210, 90), fer = rgb(90, 84, 92), bois = rgb(80, 50, 36)},
		particules = {
			{nombre = 22, couleurs = {rgb(255, 140, 40), rgb(255, 220, 110)}, taille = {0.004, 0.009}, vitesse = {0.04, 0.1}, sens = -1, transp = 0.1, amplitude = 0.02},
			{nombre = 14, couleurs = {rgb(120, 110, 110), rgb(80, 74, 74)}, taille = {0.003, 0.006}, vitesse = {0.01, 0.025}, sens = 1, transp = 0.4, amplitude = 0.04},
		},
		lumieres = "La lave s'embrase…",
		astuces = {
			"La lave monte toutes les 2 à 3 minutes : réfugie-toi sur les prismes de basalte.",
			"Les geysers fument avant de jaillir : écarte-toi.",
			"Le geyser bleu ne brûle pas : il propulse vers une corniche secrète.",
			"Assieds-toi sur le trône de magma… si tu oses affronter le Roi déchu.",
			"Onde de feu du Roi déchu : saute au passage ou reste hors du disque rouge.",
		},
		construire = decorLave,
	},
	[5] = {
		titre = "Le Cœur maudit",
		couleurs = {fondHaut = rgb(6, 2, 12), fondMilieu = rgb(30, 6, 40), fondBas = rgb(4, 0, 8), roche = rgb(50, 38, 62),
			creuse = rgb(10, 4, 14), accent = rgb(255, 60, 220), minerai = rgb(150, 80, 255), eclat = rgb(70, 54, 86),
			etincelle = rgb(255, 150, 250), fer = rgb(110, 100, 126), bois = rgb(70, 44, 60)},
		particules = {{nombre = 18, couleurs = {rgb(255, 90, 230), rgb(160, 100, 255)}, taille = {0.008, 0.02}, vitesse = {0.02, 0.05}, sens = -1, transp = 0.45, amplitude = 0.04}},
		lumieres = "Le Cœur s'éveille…",
		astuces = {
			"À 75, 50 et 25 % des PV du boss, une chaîne du Cœur cède.",
			"Dès la 2e phase, les runes brûlantes de l'arène s'éveillent : surveille le sol.",
			"Le Vide suspendu n'a pas de fond : reste sur les dalles runiques.",
			"Le dernier camp de l'expédition est un refuge : les mobs n'y entrent jamais.",
		},
		construire = decorCoeur,
	},
}

local Themes = {}
Themes.kit = K

function Themes.get(id: number?)
	return THEMES[id or 1] or THEMES[1]
end

return Themes
