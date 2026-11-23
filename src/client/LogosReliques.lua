-- Logos des reliques du Casque du Cœur Magmatique · MODULE CLIENT (StarterPlayerScripts › Jeu › LogosReliques)
-- Dessine un médaillon (anneau de magma riveté + fond sombre + symbole) en GUI pur : Frames, UICorner, UIGradient,
-- UIStroke, rotations. Pas d'image ni d'emoji. Le logo remplit son parent (carré, centré) ; les traits suivent la taille.
--   LogosReliques.creer(id, parent, boucles?) -> Frame
--     id      : "Magma1" (éclat d'obsidienne), "Magma2" (corne de basalte), "Magma3" (cœur de magma)
--     boucles : liste de Tweens (optionnelle) ; si donnée, le cœur de magma y ajoute sa palpitation (à jouer/pauser)
-- Utilisé par EnclumeMagma.client.lua et ReliquesMagma.client.lua.

local TweenService = game:GetService("TweenService")

local LogosReliques = {}

local BLANC = Color3.new(1, 1, 1)
local NOIR = Color3.fromRGB(18, 9, 7)
local MAGMA = Color3.fromRGB(255, 110, 30)
local MAGMA_VIF = Color3.fromRGB(255, 196, 90)

local COULEURS = {
	Magma1 = Color3.fromRGB(120, 70, 160),
	Magma2 = Color3.fromRGB(150, 120, 110),
	Magma3 = Color3.fromRGB(255, 110, 30),
}

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

-- ColorSequence à partir de paires {t, couleur}
local function suite(points: {{any}}): ColorSequence
	local k = {}
	for _, p in points do
		table.insert(k, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(k)
end

local function degrade(rotation: number, points: {{any}}): UIGradient
	return creer("UIGradient", {Rotation = rotation, Color = suite(points)})
end

function LogosReliques.creer(id: string, parent: Instance, boucles: {Tween}?): Frame
	local couleur = COULEURS[id] or MAGMA
	local z0 = (if parent:IsA("GuiObject") then parent.ZIndex else 1) + 1

	local racine = creer("Frame", {Name = "Logo" .. id, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z0},
		{creer("UIAspectRatioConstraint", {AspectRatio = 1})})

	-- Traits en pixels : épaisseur = ratio × taille du logo (mise à jour quand la taille change)
	local traits: {{any}} = {}
	local function trait(o: GuiObject, c: Color3, ratio: number, transp: number?)
		local s = creer("UIStroke", {Color = c, Thickness = 1, Transparency = transp or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Round, Parent = o})
		table.insert(traits, {s, ratio})
	end
	local function disque(par: Instance, taille: number, x: number, y: number, c: Color3, z: number): Frame
		return creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(taille, taille),
			BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = z, Parent = par}, {coin(0.5)})
	end

	-- ===== Médaillon =====
	-- anneau de magma (dégradé braise → orange vif → braise)
	local anneau = disque(racine, 1, 0.5, 0.5, BLANC, z0)
	degrade(135, {{0, Color3.fromRGB(80, 18, 6)}, {0.28, MAGMA_VIF}, {0.55, MAGMA}, {0.8, Color3.fromRGB(150, 36, 8)},
		{1, Color3.fromRGB(60, 12, 4)}}).Parent = anneau
	trait(anneau, NOIR, 0.035)
	-- rivets de fer
	for k = 0, 7 do
		local a = (k / 8 + 1 / 16) * math.pi * 2
		local r = disque(racine, 0.075, 0.5 + math.cos(a) * 0.445, 0.5 + math.sin(a) * 0.445, BLANC, z0 + 1)
		degrade(90, {{0, Color3.fromRGB(200, 190, 185)}, {1, Color3.fromRGB(55, 48, 46)}}).Parent = r
		trait(r, NOIR, 0.012)
	end
	-- fond intérieur : la couleur de la relique qui plonge dans l'obsidienne
	local fond = disque(racine, 0.78, 0.5, 0.5, BLANC, z0 + 1)
	degrade(90, {{0, couleur:Lerp(Color3.new(), 0.35)}, {0.6, couleur:Lerp(Color3.new(), 0.78)}, {1, Color3.fromRGB(10, 6, 8)}}).Parent = fond
	trait(fond, NOIR, 0.03)
	-- liseré intérieur
	local lisere = disque(racine, 0.69, 0.5, 0.5, BLANC, z0 + 2)
	lisere.BackgroundTransparency = 1
	trait(lisere, couleur:Lerp(BLANC, 0.35), 0.014, 0.25)

	-- ===== Symbole =====
	local zs = z0 + 3
	local zone = creer("Frame", {Name = "Symbole", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.64, 0.64), BackgroundTransparency = 1, ZIndex = zs, Parent = racine})

	local function piece(x: number, y: number, l: number, h: number, rot: number, c: Color3, z: number, arrondi: number?): Frame
		return creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(l, h),
			Rotation = rot, BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = z, Parent = zone}, if arrondi then {coin(arrondi)} else nil)
	end
	-- étincelle à 4 branches
	local function eclat(x: number, y: number, t: number, z: number)
		for _, rot in {0, 90} do
			local b = piece(x, y, t, t * 0.2, rot, BLANC, z, 0.5)
			creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1)}), Parent = b})
		end
	end

	if id == "Magma1" then
		-- Éclat d'obsidienne : losange facetté violet-noir (facettes par dégradés à arête franche)
		local corps = piece(0.5, 0.5, 0.64, 0.64, 45, BLANC, zs, 0.05)
		degrade(-45, {{0, Color3.fromRGB(165, 115, 215)}, {0.499, Color3.fromRGB(96, 56, 138)}, {0.5, Color3.fromRGB(42, 20, 64)},
			{1, Color3.fromRGB(12, 6, 20)}}).Parent = corps
		trait(corps, NOIR, 0.028)
		-- facettes : haut clair / bas sombre, puis table centrale
		local haut = piece(0.5, 0.5, 0.64, 0.64, 45, BLANC, zs + 1, 0.05)
		haut.BackgroundTransparency = 0.55
		creer("UIGradient", {Rotation = 45, Color = suite({{0, Color3.fromRGB(230, 205, 255)}, {1, Color3.fromRGB(40, 20, 60)}}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.499, 0.35),
				NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = haut})
		local table_ = piece(0.5, 0.5, 0.3, 0.3, 45, BLANC, zs + 2, 0.06)
		degrade(45, {{0, Color3.fromRGB(235, 215, 255)}, {0.499, Color3.fromRGB(175, 125, 225)}, {0.5, Color3.fromRGB(78, 42, 112)},
			{1, Color3.fromRGB(30, 14, 46)}}).Parent = table_
		trait(table_, Color3.fromRGB(25, 10, 38), 0.012, 0.2)
		-- arête vive + reflets
		piece(0.5, 0.5, 0.012, 0.86, 0, Color3.fromRGB(210, 180, 250), zs + 1).BackgroundTransparency = 0.6
		eclat(0.33, 0.3, 0.2, zs + 3)
		eclat(0.66, 0.68, 0.12, zs + 3)
	elseif id == "Magma2" then
		-- Corne de basalte : segments annelés le long d'un arc qui s'affine, pointe chauffée au rouge
		local N = 9
		local cx, cy = 0.5, 0.58
		for k = 0, N - 1 do
			local t = k / (N - 1)
			local a = math.rad(215 - 190 * t)
			local r = 0.32 - 0.09 * t
			local x, y = cx + math.cos(a) * r, cy - math.sin(a) * r
			local s = 0.25 * (1 - t) + 0.07
			local base = Color3.fromRGB(196, 176, 164):Lerp(Color3.fromRGB(120, 100, 92), (k % 2) * 0.5)
			local chaud = math.clamp((t - 0.6) / 0.4, 0, 1)
			local seg = piece(x, y, s * 1.15, s, -math.deg(a) + 90, BLANC, zs + (N - k), 0.38)
			degrade(90, {{0, base:Lerp(MAGMA_VIF, chaud)}, {1, Color3.fromRGB(58, 46, 42):Lerp(Color3.fromRGB(190, 50, 10), chaud)}}).Parent = seg
			trait(seg, NOIR, 0.016)
		end
		-- braises qui s'échappent de la pointe
		local tipA = math.rad(25)
		local tx, ty = cx + math.cos(tipA) * 0.23, cy - math.sin(tipA) * 0.23
		piece(tx + 0.1, ty - 0.12, 0.06, 0.06, 0, MAGMA_VIF, zs + N + 1, 0.5)
		piece(tx + 0.02, ty - 0.2, 0.04, 0.04, 0, MAGMA, zs + N + 1, 0.5)
		eclat(0.3, 0.3, 0.14, zs + N + 2)
	else
		-- Cœur de magma : cœur incandescent (carré tourné + deux lobes), fissures lumineuses, noyau blanc qui palpite
		local function coeur(s: number, c: Color3, z: number): {Frame}
			local cx, cy = 0.5, 0.53 - 0.0735 * 0.5 + 0.0735 * s
			local d = 0.354 * s
			return {
				piece(cx, cy, s, s, 45, c, z, 0.06),
				piece(cx - d, cy - d, s, s, 0, c, z, 0.5),
				piece(cx + d, cy - d, s, s, 0, c, z, 0.5),
			}
		end
		coeur(0.56, NOIR, zs) -- contour
		coeur(0.5, Color3.fromRGB(205, 58, 14), zs + 1) -- croûte rouge
		local chair = coeur(0.4, Color3.fromRGB(255, 120, 30), zs + 2) -- chair orange
		for _, p in chair do
			p.BackgroundTransparency = 0.15
		end
		-- fissures qui partent du noyau
		local c = Vector2.new(0.5, 0.5)
		for _, f in {{-140, 0.3}, {-40, 0.3}, {92, 0.26}, {165, 0.2}, {15, 0.2}} do
			local a, l = math.rad(f[1]), f[2]
			local m = c + Vector2.new(math.cos(a), math.sin(a)) * l * 0.5
			local fis = piece(m.X, m.Y, l, 0.032, f[1], Color3.fromRGB(255, 236, 150), zs + 3, 0.5)
			creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.25),
				NumberSequenceKeypoint.new(1, 1)}), Parent = fis})
		end
		-- noyau
		local halo = piece(0.5, 0.5, 0.3, 0.3, 0, MAGMA_VIF, zs + 4, 0.5)
		halo.BackgroundTransparency = 0.35
		local noyau = piece(0.5, 0.5, 0.15, 0.15, 0, Color3.fromRGB(255, 250, 215), zs + 5, 0.5)
		-- reflet sur le lobe gauche
		piece(0.31, 0.3, 0.12, 0.07, -35, BLANC, zs + 5, 0.5).BackgroundTransparency = 0.45
		if boucles then
			local info = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			table.insert(boucles, TweenService:Create(halo, info, {Size = UDim2.fromScale(0.4, 0.4), BackgroundTransparency = 0.55}))
			table.insert(boucles, TweenService:Create(noyau, info, {Size = UDim2.fromScale(0.2, 0.2)}))
		end
	end

	-- reflet bombé sur le haut du médaillon
	creer("Frame", {Name = "Reflet", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.5, 0.16),
		BackgroundColor3 = BLANC, BackgroundTransparency = 0.84, BorderSizePixel = 0, ZIndex = zs + 20, Parent = racine}, {coin(0.5)})

	local function majTraits()
		local t = racine.AbsoluteSize.X
		for _, e in traits do
			e[1].Thickness = math.max(1, t * e[2])
		end
	end
	racine:GetPropertyChangedSignal("AbsoluteSize"):Connect(majTraits)
	racine.Parent = parent
	majTraits()
	return racine
end

return LogosReliques
