-- Boss du village · CLIENT, pendant le combat (module de BossVillage.client) :
-- « Phase »  : bandeau « PHASE 2 — <Boss> s'enrage ! », onde de choc à l'écran, éclat rouge, forte secousse.
-- « Impact » : secousse légère si une attaque de zone tombe près de moi (dosée selon la distance).
-- Touché     : éclat rouge sur les bords de l'écran (selon la part de PV perdue), seulement dans l'arène.
-- Indicateur discret sous la barre du boss : « 6 mineurs debout » (attribut Debout du dossier).
-- « KO »     : écran « K.O. — Retourne au cercle pour rejoindre le combat » jusqu'à la réapparition (+ quelques s).
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local Combat = {}

function Combat.init(ctx)
	local gui: ScreenGui = ctx.gui
	local cinema: ScreenGui = ctx.cinema
	local dossier: Instance = ctx.dossier
	local joueur: Player = ctx.joueur

	local function dansCombat(): boolean
		return joueur:GetAttribute("DansArene") == true and dossier:GetAttribute("Etat") == "Combat"
	end

	-- ================= Éclat rouge des bords (touché) =================
	local bords = creer("Frame", {Name = "Touche", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = cinema})
	local cotes: {Frame} = {}
	for _, v in {{90, Vector2.new(0, 0), UDim2.fromScale(1, 0.2)}, {-90, Vector2.new(0, 1), UDim2.fromScale(1, 0.2)},
		{0, Vector2.new(0, 0), UDim2.fromScale(0.16, 1)}, {180, Vector2.new(1, 0), UDim2.fromScale(0.16, 1)}} do
		local rot, ancre, taille = v[1] :: number, v[2] :: Vector2, v[3] :: UDim2
		table.insert(cotes, creer("Frame", {AnchorPoint = ancre, Position = UDim2.fromScale(ancre.X, ancre.Y), Size = taille,
			BackgroundColor3 = Color3.fromRGB(220, 20, 16), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = bords},
			{creer("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})})}))
	end
	local function eclatRouge(intensite: number)
		for _, f in cotes do
			f.BackgroundTransparency = 1 - 0.7 * math.clamp(intensite, 0, 1)
			TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		end
	end

	local connexionsPerso: {RBXScriptConnection} = {}
	local function lierPerso(perso: Model)
		for _, c in connexionsPerso do c:Disconnect() end
		table.clear(connexionsPerso)
		local humain = perso:WaitForChild("Humanoid", 10)
		if not humain or not humain:IsA("Humanoid") then return end
		local pv = humain.Health
		table.insert(connexionsPerso, humain.HealthChanged:Connect(function(n)
			local perte = pv - n
			pv = n
			if perte > 0.5 and dansCombat() then
				eclatRouge(0.35 + perte / math.max(humain.MaxHealth, 1) * 1.6)
				if perte / math.max(humain.MaxHealth, 1) > 0.25 then Outils.secouer(0.25) end
			end
		end))
	end
	joueur.CharacterAdded:Connect(lierPerso)
	if joueur.Character then task.spawn(lierPerso, joueur.Character) end

	-- ================= Mineurs debout =================
	local debout = creer("Frame", {Name = "Debout", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 86), Size = UDim2.fromScale(0.13, 0.03),
		BackgroundColor3 = Color3.fromRGB(18, 12, 9), BackgroundTransparency = 0.35, Visible = false, Parent = gui},
		{coin(0.5), trait(Color3.fromRGB(10, 6, 4), 1.5, 0.3), creer("UISizeConstraint", {MinSize = Vector2.new(150, 22), MaxSize = Vector2.new(210, 28)})})
	local point = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.07, 0.5), Size = UDim2.fromScale(0.4, 0.4),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Vert, BorderSizePixel = 0, Parent = debout}, {coin(0.5)})
	local deboutTexte = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.16, 0.14), Size = UDim2.fromScale(0.8, 0.72),
		Parent = debout}, 15)
	local dernierDebout = -1
	local function majDebout()
		local voir = dansCombat() and not ctx.etat.cinematique
		debout.Visible = voir
		local n = dossier:GetAttribute("Debout")
		if type(n) ~= "number" then return end
		deboutTexte.Text = n .. " mineur" .. (if n > 1 then "s" else "") .. " debout"
		point.BackgroundColor3 = if n <= 1 then T.Rouge elseif n <= 3 then T.Or else T.Vert
		if voir and dernierDebout >= 0 and n ~= dernierDebout then
			UI.pop(debout, if n < dernierDebout then 1.15 else 0.85)
			local s = debout:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = if n < dernierDebout then T.Rouge else T.Vert
				TweenService:Create(s, TweenInfo.new(0.8), {Color = Color3.fromRGB(10, 6, 4)}):Play()
			end
		end
		dernierDebout = n
	end
	dossier:GetAttributeChangedSignal("Debout"):Connect(majDebout)

	-- ================= Bandeau de phase =================
	local bandeau = creer("CanvasGroup", {Name = "Phase", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.7, 0.13),
		BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 10, Parent = cinema})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.8),
		BackgroundColor3 = Color3.fromRGB(40, 6, 4), BorderSizePixel = 0, Parent = bandeau}, {creer("UIGradient", {Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.25), NumberSequenceKeypoint.new(0.75, 0.25), NumberSequenceKeypoint.new(1, 1)})})})
	local phaseNumero = texte({Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromScale(0.9, 0.48),
		Parent = bandeau}, 64)
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 180)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 20))}), Parent = phaseNumero})
	creer("UIStroke", {Thickness = 3, Color = Color3.fromRGB(30, 4, 2), Parent = phaseNumero})
	local phaseTexte = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.6),
		Size = UDim2.fromScale(0.9, 0.3), Parent = bandeau}, 30)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(30, 4, 2), Parent = phaseTexte})
	local numeroPhase = 0

	local function onde(couleur: Color3)
		for k = 0, 1 do
			local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.08, 0.08),
				SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 9, Parent = cinema},
				{coin(0.5), trait(if k == 0 then couleur else Color3.new(1, 1, 1), 8 - k * 4)})
			local s = anneau:FindFirstChildOfClass("UIStroke") :: UIStroke
			local info = TweenInfo.new(0.8 + k * 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, k * 0.1)
			TweenService:Create(anneau, info, {Size = UDim2.fromScale(2.2, 2.2)}):Play()
			TweenService:Create(s, info, {Transparency = 1, Thickness = 0}):Play()
			task.delay(1.2, function() anneau:Destroy() end)
		end
	end

	local api = {}

	function api.phase(d)
		if type(d) ~= "table" then return end
		numeroPhase += 1
		local n = numeroPhase
		local couleur = if typeof(d.couleur) == "Color3" then d.couleur else T.Rouge
		phaseNumero.Text = "PHASE " .. tostring(tonumber(d.phase) or 2)
		phaseTexte.Text = tostring(d.nom or "Le boss") .. " s'enrage !"
		bandeau.Visible = true
		bandeau.GroupTransparency = 0
		local e = UI.echelle(bandeau)
		e.Scale = 1.7
		TweenService:Create(e, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		onde(couleur)
		eclatRouge(0.8)
		Outils.secouer(0.7)
		Outils.jouer("grondement", 0.45, 0.6)
		Outils.jouer("impact", 0.5, 0.5)
		task.delay(2.4, function()
			if numeroPhase ~= n then return end
			local t = TweenService:Create(bandeau, TweenInfo.new(0.5), {GroupTransparency = 1})
			t.Completed:Once(function()
				if numeroPhase == n then bandeau.Visible = false end
			end)
			t:Play()
		end)
	end

	function api.impact(pos: Vector3, rayon: number)
		if not dansCombat() then return end
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not racine then return end
		local d = Vector3.new(racine.Position.X - pos.X, 0, racine.Position.Z - pos.Z).Magnitude
		local marge = 18
		if d > rayon + marge then return end
		local k = 1 - math.clamp((d - rayon) / marge, 0, 1)
		Outils.secouer(0.12 + 0.3 * k)
	end

	-- ================= Écran K.O. =================
	local ko = creer("CanvasGroup", {Name = "KO", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 5,
		Parent = cinema})
	creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 2, 2), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = ko},
		{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.75),
			NumberSequenceKeypoint.new(1, 0.2)})})})
	local koTitre = texte({Text = "K.O.", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.5, 0.18), Parent = ko}, 140)
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 180)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 50, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 10, 8))}), Parent = koTitre})
	creer("UIStroke", {Thickness = 4, Color = Color3.fromRGB(20, 2, 2), Parent = koTitre})
	local koSous = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.7, 0.05), Parent = ko}, 32)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 2, 2), Parent = koSous})
	texte({Text = "Retourne au cercle de l'arène, au bout de la rue du sud, pour rejoindre le combat.", Font = Enum.Font.GothamBold,
		TextColor3 = T.Gris, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.59), Size = UDim2.fromScale(0.6, 0.032), Parent = ko}, 22)
	Outils.epees(ko, T.Rouge, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.27), Size = UDim2.fromScale(0.07, 0.07)})
	local numeroKO = 0

	local function cacherKO(n: number)
		if numeroKO ~= n or not ko.Visible then return end
		local t = TweenService:Create(ko, TweenInfo.new(0.6), {GroupTransparency = 1})
		t.Completed:Once(function()
			if numeroKO == n then ko.Visible = false end
		end)
		t:Play()
	end

	function api.ko(d)
		numeroKO += 1
		local n = numeroKO
		koSous.Text = "Retourne au cercle pour rejoindre le combat"
		if type(d) == "table" and d.nom then koSous.Text = tostring(d.nom) .. " t'a mis à terre · retourne au cercle pour rejoindre le combat" end
		ko.Visible = true
		ko.GroupTransparency = 1
		TweenService:Create(ko, TweenInfo.new(0.5), {GroupTransparency = 0}):Play()
		local e = UI.echelle(koTitre)
		e.Scale = 1.8
		TweenService:Create(e, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		Outils.jouer("grondement", 0.4, 0.5)
		-- jusqu'à la réapparition (+ 3,5 s pour lire), 12 s au plus
		local connexion
		connexion = joueur.CharacterAdded:Connect(function()
			connexion:Disconnect()
			task.delay(3.5, cacherKO, n)
		end)
		task.delay(12, function()
			if connexion.Connected then connexion:Disconnect() end
			cacherKO(n)
		end)
	end

	function api.maj()
		majDebout()
		if not dansCombat() and bandeau.Visible then
			bandeau.Visible = false
		end
	end

	dossier:GetAttributeChangedSignal("Etat"):Connect(api.maj)
	joueur:GetAttributeChangedSignal("DansArene"):Connect(api.maj)
	api.maj()
	return api
end

return Combat
