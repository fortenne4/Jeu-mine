--!strict
-- Combo de minage · SCRIPT CLIENT : médaillon de forge qui s'embrase pendant une série de coups (clic maintenu).
--  • médaillon de fer au-dessus de la barre d'objets : compteur de coups qui « cogne » à chaque coup,
--    anneau de braises qui tourne de plus en plus vite, 18 crans qui chauffent (braise → or → blanc) ;
--  • « SURCHAUFFE ! » à la cadence maximale (+30 %), étincelles à chaque coup ;
--  • « Solidité » du minerai frappé (barre de cristal à encoches) ;
--  • bannière « ÉCLAT PARFAIT +1 » quand un minerai est cassé d'une seule série (bonus donné par le serveur).
-- Tout est décidé par le serveur (PiocheBraise.server, RemoteEvent ComboMinage) : ici, on ne fait qu'afficher.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local joueur = Players.LocalPlayer
local combo = ReplicatedStorage:WaitForChild("ComboMinage") :: RemoteEvent

local ACCEL_MAX = 0.3 -- même plafond que le serveur (PiocheBraise.server, CONFIG.ACCEL_MAX)
local DUREE_AFFICHAGE = 1.6 -- secondes sans coup avant que le médaillon s'éteigne
local TAILLE = 0.65 -- échelle de tout l'affichage (1 = taille d'origine)
local N_CRANS = 18
local LARGEUR, HAUTEUR = 280, 190
local CENTRE = Vector2.new(LARGEUR / 2, 78)
local RAYON_CRANS = 49

local BRAISE_FONCEE = Color3.fromRGB(150, 38, 14)
local BLANC_CHAUD = Color3.fromRGB(255, 248, 225)
local CRISTAL = Color3.fromRGB(140, 214, 255)
local OMBRE = Color3.fromRGB(24, 14, 8)

-- Couleur du métal chauffé : 0 = braise sombre, 0,5 = braise, 0,8 = or, 1 = blanc chaud
local function chaleurCouleur(c: number): Color3
	if c < 0.5 then
		return BRAISE_FONCEE:Lerp(T.Braise, c / 0.5)
	elseif c < 0.8 then
		return T.Braise:Lerp(T.Or, (c - 0.5) / 0.3)
	end
	return T.Or:Lerp(BLANC_CHAUD, (c - 0.8) / 0.2)
end

local function rond(props: {[string]: any}, enfants: {Instance}?): Frame
	props.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	local f = creer("Frame", props, enfants)
	coin(1).Parent = f
	return f
end

local gui = creer("ScreenGui", {Name = "ComboMinage", ResetOnSpawn = false, DisplayOrder = 6,
	IgnoreGuiInset = true, Parent = joueur:WaitForChild("PlayerGui")})

-- Le groupe s'efface d'un bloc ; les étincelles vivent sur un calque à part (pas rognées par le groupe)
local groupe = creer("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -104),
	Size = UDim2.fromOffset(LARGEUR, HAUTEUR), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = gui})
local echelle = creer("UIScale", {Scale = TAILLE, Parent = groupe})
local calque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -104),
	Size = UDim2.fromOffset(LARGEUR, HAUTEUR), BackgroundTransparency = 1, ZIndex = 20, Parent = gui})
creer("UIScale", {Scale = TAILLE, Parent = calque})

local function auCentre(dx: number?, dy: number?): UDim2
	return UDim2.fromOffset(CENTRE.X + (dx or 0), CENTRE.Y + (dy or 0))
end

-- ===== Halo de chaleur (trois disques superposés, de plus en plus pâles) =====
local halos: {Frame} = {}
for i, d in {170, 146, 126} do
	halos[i] = rond({Position = auCentre(), Size = UDim2.fromOffset(d, d), BackgroundColor3 = T.Braise,
		BackgroundTransparency = 1, ZIndex = 1, Parent = groupe})
end

-- ===== Anneau de braises qui tourne =====
local anneauFeu = rond({Position = auCentre(), Size = UDim2.fromOffset(122, 122), BackgroundTransparency = 1, ZIndex = 2, Parent = groupe})
local traitFeu = trait(T.Braise, 4)
traitFeu.Parent = anneauFeu
local degradeFeu = creer("UIGradient", {Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, BRAISE_FONCEE), ColorSequenceKeypoint.new(0.35, T.Braise),
	ColorSequenceKeypoint.new(0.6, T.Or), ColorSequenceKeypoint.new(1, BRAISE_FONCEE)}),
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.45, 0),
		NumberSequenceKeypoint.new(0.55, 0), NumberSequenceKeypoint.new(1, 0.9)}), Parent = traitFeu})

-- ===== Médaillon de fer riveté =====
local medaillon = rond({Position = auCentre(), Size = UDim2.fromOffset(112, 112), BackgroundColor3 = T.FerSombre, ZIndex = 3,
	Parent = groupe}, {trait(OMBRE, 3), UI.degrade(T.Fer, T.FerSombre, 120)})
for k = 0, 7 do
	local a = k * math.pi / 4 + math.pi / 8
	rond({Position = UDim2.new(0.5, math.sin(a) * 50, 0.5, -math.cos(a) * 50), Size = UDim2.fromOffset(5, 5),
		BackgroundColor3 = T.Rivet, ZIndex = 4, Parent = medaillon}, {trait(OMBRE, 1)})
end

-- ===== Crans qui chauffent (arc de 270° autour du compteur) =====
local crans: {Frame} = {}
for i = 1, N_CRANS do
	local a = math.rad(-135 + (i - 1) * 270 / (N_CRANS - 1))
	crans[i] = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5),
		Position = auCentre(math.sin(a) * RAYON_CRANS, -math.cos(a) * RAYON_CRANS), Size = UDim2.fromOffset(4, 10),
		Rotation = math.deg(a), BackgroundColor3 = T.Inactif, BorderSizePixel = 0, ZIndex = 5, Parent = groupe}, {coin(0.5)})
end

-- ===== Cœur : compteur de coups =====
local coeur = rond({Position = auCentre(), Size = UDim2.fromOffset(78, 78), BackgroundColor3 = T.BoisSombre, ZIndex = 6,
	Parent = groupe}, {trait(T.OrFonce, 2), UI.degrade(T.Carte, T.BoisSombre, 90)})
local compteur = texte({Text = "x1", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromOffset(70, 40), ZIndex = 7, Parent = coeur}, 36)
UI.dore(compteur, 2.5)
local echelleCompteur = creer("UIScale", {Scale = 1, Parent = compteur})
texte({Text = "COUPS", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.76), Size = UDim2.fromOffset(50, 11), ZIndex = 7, Parent = coeur}, 11)

-- ===== « SURCHAUFFE ! » au-dessus du médaillon =====
local surchauffe = texte({Text = "SURCHAUFFE !", Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5), Position = auCentre(0, -76), Size = UDim2.fromOffset(200, 24), ZIndex = 8,
	TextTransparency = 1, Parent = groupe}, 24)
local traitSurchauffe = creer("UIStroke", {Color = OMBRE, Thickness = 2.5, Transparency = 1, Parent = surchauffe})
local degradeSurchauffe = creer("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.Braise),
	ColorSequenceKeypoint.new(0.5, BLANC_CHAUD), ColorSequenceKeypoint.new(1, T.Braise)}), Parent = surchauffe})

-- ===== Cadence en clair, sous le médaillon =====
local cadence = texte({Text = "CADENCE +0 %", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = auCentre(0, 72), Size = UDim2.fromOffset(200, 18), ZIndex = 8,
	Parent = groupe}, 16)
creer("UIStroke", {Color = OMBRE, Thickness = 2, Parent = cadence})

-- ===== Solidité du minerai : barre de cristal à encoches =====
local plaqueSolidite = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = auCentre(0, 96),
	Size = UDim2.fromOffset(190, 16), BackgroundColor3 = T.Pierre, ZIndex = 8, Visible = false, Parent = groupe},
	{coin(0.5), trait(OMBRE, 2)})
local fondSolidite = creer("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
	BackgroundColor3 = T.FerSombre, ZIndex = 9, ClipsDescendants = true, Parent = plaqueSolidite}, {coin(0.5)})
local barreSolidite = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 10,
	Parent = fondSolidite}, {coin(0.5)})
local degradeSolidite = creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(220, 245, 255), CRISTAL),
	Parent = barreSolidite})
local reflet = creer("Frame", {Size = UDim2.new(0, 18, 1, 0), Position = UDim2.fromScale(-0.2, 0), BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.55, Rotation = 20, ZIndex = 11, Parent = fondSolidite})
local encoches: {Frame} = {}
local function poserEncoches(pvMax: number)
	for _, e in encoches do e:Destroy() end
	table.clear(encoches)
	local n = math.clamp(math.floor(pvMax + 0.5), 1, 12)
	for i = 1, n - 1 do
		table.insert(encoches, creer("Frame", {Position = UDim2.fromScale(i / n, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = T.Pierre, BorderSizePixel = 0, ZIndex = 12, Parent = fondSolidite}))
	end
end

-- ===== Étincelles (calque à part) =====
local function etincelles(n: number, couleur: Color3, force: number)
	for _ = 1, n do
		local a = math.random() * math.pi * 2
		local d = (55 + math.random() * 55) * force
		local taille = math.random(3, 6)
		local s = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = auCentre(math.cos(a) * 40, math.sin(a) * 40),
			Size = UDim2.fromOffset(taille, taille), Rotation = math.random(0, 90), BackgroundColor3 = couleur,
			BorderSizePixel = 0, ZIndex = 21, Parent = calque})
		local duree = 0.35 + math.random() * 0.35
		TweenService:Create(s, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = auCentre(math.cos(a) * (40 + d), math.sin(a) * (40 + d) + 25), Rotation = s.Rotation + 180,
			BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1)}):Play()
		task.delay(duree + 0.05, function() s:Destroy() end)
	end
end

-- ===== Bannière « ÉCLAT PARFAIT » =====
local function eclatParfait()
	local banniere = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34),
		Size = UDim2.fromOffset(234, 48), BackgroundColor3 = T.BoisSombre, BackgroundTransparency = 0.1, ZIndex = 30,
		ClipsDescendants = true, Parent = gui}, {coin(0.2), trait(T.Or, 1.5), UI.degrade(T.Bois, T.BoisSombre, 90)})
	local titreEclat = texte({Text = "ÉCLAT PARFAIT", Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.43, 0.5), Size = UDim2.fromOffset(162, 26), ZIndex = 31, Parent = banniere}, 25)
	UI.dore(titreEclat, 1.5)
	local plus = texte({Text = "+1", Font = Enum.Font.GothamBlack, TextColor3 = CRISTAL, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.5), Size = UDim2.fromOffset(39, 29), ZIndex = 31, Parent = banniere}, 29)
	creer("UIStroke", {Color = OMBRE, Thickness = 1.5, Parent = plus})
	-- reflet qui balaie la bannière
	local balayage = creer("Frame", {Size = UDim2.new(0, 20, 1.6, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(-0.1, 0.5), Rotation = 18, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6,
		ZIndex = 32, Parent = banniere})
	UI.pop(banniere, 0.55)
	UI.pop(plus, 0.3)
	TweenService:Create(balayage, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(1.1, 0.5)}):Play()
	-- pluie d'or autour de la bannière
	for _ = 1, 16 do
		local a = math.random() * math.pi * 2
		local s = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34),
			Size = UDim2.fromOffset(3, 3), Rotation = 45, BackgroundColor3 = if math.random() < 0.7 then T.Or else CRISTAL,
			BorderSizePixel = 0, ZIndex = 29, Parent = gui})
		TweenService:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(a) * 150, 0.34, math.sin(a) * 58), BackgroundTransparency = 1, Rotation = 225}):Play()
		task.delay(0.75, function() s:Destroy() end)
	end
	task.delay(1.3, function()
		TweenService:Create(banniere, UI.DOUX, {Position = UDim2.fromScale(0.5, 0.3), BackgroundTransparency = 1}):Play()
		for _, o in banniere:GetDescendants() do
			if o:IsA("TextLabel") then
				TweenService:Create(o, UI.DOUX, {TextTransparency = 1}):Play()
			elseif o:IsA("UIStroke") then
				TweenService:Create(o, UI.DOUX, {Transparency = 1}):Play()
			elseif o:IsA("Frame") then
				TweenService:Create(o, UI.DOUX, {BackgroundTransparency = 1}):Play()
			end
		end
		task.delay(0.5, function() banniere:Destroy() end)
	end)
end

-- ===== État animé (chaque image) =====
local chaleur, chaleurCible = 0, 0 -- 0 = froid, 1 = cadence maximale
local enSurchauffe = false
local dernierEvenement = 0
local visible = false
local angleFeu = 0

local function allumer()
	dernierEvenement = os.clock()
	if visible then return end
	visible = true
	groupe.Visible = true
	echelle.Scale = 0.7 * TAILLE
	TweenService:Create(groupe, UI.DOUX, {GroupTransparency = 0}):Play()
	TweenService:Create(echelle, UI.BOUNCY, {Scale = TAILLE}):Play()
end

local function eteindre()
	visible = false
	chaleurCible = 0
	enSurchauffe = false
	local t = TweenService:Create(groupe, UI.DOUX, {GroupTransparency = 1})
	TweenService:Create(echelle, UI.DOUX, {Scale = 0.85 * TAILLE}):Play()
	t:Play()
	t.Completed:Once(function()
		if not visible then
			groupe.Visible = false
			plaqueSolidite.Visible = false
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	if not groupe.Visible then return end
	if visible and os.clock() - dernierEvenement > DUREE_AFFICHAGE then
		eteindre()
	end
	chaleur += (chaleurCible - chaleur) * math.min(1, dt * 8)
	-- anneau de braises : tourne plus vite quand ça chauffe
	angleFeu = (angleFeu + dt * (70 + 420 * chaleur)) % 360
	degradeFeu.Rotation = angleFeu
	traitFeu.Thickness = 3 + 3 * chaleur
	-- halo qui respire
	local souffle = 0.5 + 0.5 * math.sin(os.clock() * (4 + 8 * chaleur))
	for i, h in halos do
		h.BackgroundColor3 = chaleurCouleur(chaleur * 0.9)
		h.BackgroundTransparency = 1 - (0.08 + 0.05 * i) * chaleur * (0.75 + 0.25 * souffle)
	end
	-- crans : allumés jusqu'au niveau de chaleur, le dernier clignote
	local allumes = math.floor(chaleur * N_CRANS + 0.5)
	for i, c in crans do
		if i <= allumes then
			c.BackgroundColor3 = chaleurCouleur(i / N_CRANS)
		else
			c.BackgroundColor3 = T.Inactif
		end
	end
	if allumes > 0 and allumes < N_CRANS then
		crans[allumes].BackgroundColor3 = chaleurCouleur(allumes / N_CRANS):Lerp(BLANC_CHAUD, souffle * 0.6)
	end
	-- surchauffe : texte qui flamboie et tremble
	local cibleTexte = if enSurchauffe then 0 else 1
	surchauffe.TextTransparency += (cibleTexte - surchauffe.TextTransparency) * math.min(1, dt * 10)
	traitSurchauffe.Transparency = surchauffe.TextTransparency
	if enSurchauffe then
		degradeSurchauffe.Offset = Vector2.new(math.sin(os.clock() * 5) * 0.5, 0)
		surchauffe.Rotation = math.sin(os.clock() * 31) * 2.5
		medaillon.Rotation = math.sin(os.clock() * 40) * 1.2
	else
		surchauffe.Rotation, medaillon.Rotation = 0, 0
	end
	-- reflet qui glisse sur la barre de cristal
	reflet.Position = UDim2.fromScale(((os.clock() * 0.6) % 1.6) - 0.3, 0)
end)

-- ===== Son de ramassage : le minerai cassé arrive dans le sac =====
local BLOOP = "rbxassetid://9112751536" -- Bubble Bloop High Pitched Cute 1 (Pro Sound Effects)
local RETARD_BLOOP = 0.9 -- à la fin : après toute la succession de sons de l'éclat (roche, clochettes, ding, pièce)
local bloop = creer("Sound", {Name = "BloopRamassage", SoundId = BLOOP, Volume = 0.2,
	Parent = game:GetService("SoundService")})
local function ramasser()
	task.delay(RETARD_BLOOP, function()
		bloop.PlaybackSpeed = 0.97 + math.random() * 0.06
		game:GetService("SoundService"):PlayLocalSound(bloop)
	end)
end

-- ===== Évènements du serveur =====
combo.OnClientEvent:Connect(function(genre: string, a: any, b: any, c: any, _d: any)
	if genre == "ramasse" then
		ramasser()
	elseif genre == "serie" and typeof(a) == "number" and typeof(b) == "number" then
		allumer()
		local part = math.clamp((b - 1) / ACCEL_MAX, 0, 1)
		chaleurCible = math.max(part, 0.12)
		compteur.Text = "x" .. a
		cadence.Text = if part >= 1 then "CADENCE MAX +30 %" else string.format("CADENCE +%d %%", math.floor((b - 1) * 100 + 0.5))
		cadence.TextColor3 = T.Parchemin:Lerp(T.Or, part)
		-- le compteur « cogne » à chaque coup
		echelleCompteur.Scale = 1.45
		TweenService:Create(echelleCompteur, UI.BOUNCY, {Scale = 1}):Play()
		compteur.TextColor3 = BLANC_CHAUD
		TweenService:Create(compteur, UI.FAST, {TextColor3 = T.Or}):Play()
		if a > 1 then
			etincelles(4 + math.floor(part * 10), chaleurCouleur(math.max(part, 0.4)), 0.8 + part * 0.6)
		end
		if part >= 1 and not enSurchauffe then
			enSurchauffe = true
			UI.pop(surchauffe, 0.4)
			etincelles(18, BLANC_CHAUD, 1.5)
		elseif part < 1 then
			enSurchauffe = false
		end
	elseif genre == "minerai" and typeof(a) == "number" and typeof(b) == "number" and b > 0 then
		allumer()
		if not plaqueSolidite.Visible or #encoches ~= math.clamp(math.floor(b + 0.5), 1, 12) - 1 then
			poserEncoches(b)
		end
		plaqueSolidite.Visible = true
		local reste = math.clamp(a / b, 0, 1)
		degradeSolidite.Color = if reste > 0.35 then ColorSequence.new(Color3.fromRGB(220, 245, 255), CRISTAL)
			else ColorSequence.new(Color3.fromRGB(255, 200, 170), T.Rouge)
		TweenService:Create(barreSolidite, UI.FAST, {Size = UDim2.fromScale(reste, 1)}):Play()
		UI.secouer(plaqueSolidite, 3)
		if c == true then
			eclatParfait()
		end
	end
end)
