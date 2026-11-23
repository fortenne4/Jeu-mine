-- Boss du village · CLIENT, avant le combat (module de BossVillage.client) :
-- 1. Puce en haut d'écran : « <Boss> dans 0:42 · Arène des boss » pendant la dernière minute (compte à rebours
--    calculé ici depuis l'attribut DebutBoss = horloge serveur, rien n'est envoyé chaque seconde), « combat en cours »
--    pendant un combat, « Prochain boss dans 6:12 » quelques secondes après le retour au village.
-- 2. Guide vers le cercle : trois chevrons lumineux au sol devant le joueur, pendant la dernière minute, seulement
--    à la surface près du village (masqué dans la mine, les grottes, l'arène, et dans le cercle).
-- 3. Panneau « PRÊT AU COMBAT » quand on est dans le cercle (attribut File) : boss, rang, départ, participants
--    (avatars ronds, 20 max), son + éclat à chaque arrivée, conseil du boss.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local Attente = {}

function Attente.init(ctx)
	local gui: ScreenGui = ctx.gui
	local dossier: Instance = ctx.dossier
	local Config = ctx.Config
	local joueur: Player = ctx.joueur

	local function bossProchain()
		local i = dossier:GetAttribute("Prochain")
		return Config.BOSS[if type(i) == "number" then i else 1] or Config.BOSS[1]
	end
	local function reste(): number
		local debut = dossier:GetAttribute("DebutBoss")
		return if type(debut) == "number" then debut - workspace:GetServerTimeNow() else math.huge
	end
	local function dansArene(): boolean
		return joueur:GetAttribute("DansArene") == true
	end
	local function hex(c: Color3): string
		return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
	end

	-- ================= 1. Puce =================
	local puce = creer("Frame", {Name = "PuceBoss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -60),
		Size = UDim2.fromScale(0.34, 0.05), BackgroundColor3 = T.BoisSombre, BackgroundTransparency = 0.08, Visible = false, Parent = gui},
		{coin(0.5), creer("UISizeConstraint", {MinSize = Vector2.new(250, 34), MaxSize = Vector2.new(480, 44)}),
			UI.degrade(Color3.fromRGB(255, 240, 225), Color3.fromRGB(150, 128, 112))})
	local bordPuce = trait(T.Or, 2, 0.15)
	bordPuce.Parent = puce
	local badge = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 1, -8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, Parent = puce}, {coin(0.5), trait(Color3.fromRGB(30, 16, 8), 1.5)})
	Outils.epees(badge, T.Parchemin, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7), ZIndex = 2})
	local puceTexte = texte({Font = Enum.Font.GothamBlack, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 0.18, 0), Size = UDim2.new(1, -14, 0.64, 0), Parent = puce}, 20)
	-- le texte commence après le badge (largeur = hauteur de la puce)
	local function placerTexte()
		local h = puce.AbsoluteSize.Y
		puceTexte.Position = UDim2.new(0, h + 6, 0.18, 0)
		puceTexte.Size = UDim2.new(1, -(h + 14), 0.64, 0)
	end
	puce:GetPropertyChangedSignal("AbsoluteSize"):Connect(placerTexte)
	placerTexte()

	local modePuce: string? = nil
	local finRetour = 0 -- os.clock() jusqu'où afficher « Prochain boss dans … » après le retour
	local poulsPuce: Tween? = nil
	local dernierPing = -1

	local function montrerPuce(voir: boolean)
		if voir == puce.Visible then return end
		if voir then
			puce.Visible = true
			puce.Position = UDim2.new(0.5, 0, 0, -60)
			TweenService:Create(puce, UI.BOUNCY, {Position = UDim2.new(0.5, 0, 0, 8)}):Play()
			UI.pop(puce, 0.8)
			Outils.jouer("souffle", 1.2, 0.3)
		else
			local t = TweenService:Create(puce, UI.FAST, {Position = UDim2.new(0.5, 0, 0, -60)})
			t.Completed:Once(function()
				if not modePuce then puce.Visible = false end
			end)
			t:Play()
		end
	end

	local function pouls(actif: boolean)
		if actif and not poulsPuce then
			bordPuce.Color = T.Rouge
			poulsPuce = TweenService:Create(bordPuce, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.8, Thickness = 3})
			poulsPuce:Play()
		elseif not actif and poulsPuce then
			poulsPuce:Cancel()
			poulsPuce = nil
			bordPuce.Color, bordPuce.Transparency, bordPuce.Thickness = T.Or, 0.15, 2
		end
	end

	local function majPuce()
		local etat = dossier:GetAttribute("Etat")
		local r = reste()
		local mode: string? = nil
		if ctx.etat.cinematique or dansArene() then
			mode = nil
		elseif etat == "Attente" and r <= Config.ANNONCE then
			mode = "annonce"
		elseif etat == "Combat" then
			mode = "combat"
		elseif etat == "Attente" and os.clock() < finRetour then
			mode = "retour"
		end
		modePuce = mode
		if mode == "annonce" then
			local def = bossProchain()
			puceTexte.Text = string.format('<font color="%s">%s</font> dans %s <font color="#9C9084">· Arène des boss</font>',
				hex(def.couleur:Lerp(Color3.new(1, 1, 1), 0.3)), def.nom, Config.minutes(r))
			badge.BackgroundColor3 = def.couleur
			pouls(r <= 10)
			local s = math.ceil(r)
			if r <= 5 and s ~= dernierPing and s > 0 then
				dernierPing = s
				UI.pop(puce, 0.92)
			end
		elseif mode == "combat" then
			local nom = dossier:GetAttribute("Nom") or "Le boss"
			local couleur = dossier:GetAttribute("Couleur") or T.Rouge
			puceTexte.Text = string.format('<font color="%s">%s</font> : combat en cours <font color="#9C9084">· entre dans le cercle</font>',
				hex(couleur:Lerp(Color3.new(1, 1, 1), 0.3)), nom)
			badge.BackgroundColor3 = couleur
			pouls(false)
		elseif mode == "retour" then
			local def = bossProchain()
			puceTexte.Text = string.format('Prochain boss dans %s <font color="#9C9084">· %s</font>', Config.minutes(r), def.nom)
			badge.BackgroundColor3 = T.Or
			pouls(false)
		else
			pouls(false)
		end
		montrerPuce(mode ~= nil)
	end

	-- ================= 2. Guide au sol =================
	local guide = Instance.new("Folder")
	guide.Name = "GuideBoss"
	local chevrons: {{BasePart}} = {}
	for k = 1, 3 do
		local bras = {}
		for _ = 1, 2 do
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.Neon
			p.Size = Vector3.new(0.32, 0.1, 2.3)
			p.Transparency = 1
			p.Parent = guide
			table.insert(bras, p)
		end
		chevrons[k] = bras
	end
	local guideVisible = false
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false

	local function cacherGuide()
		if not guideVisible then return end
		guideVisible = false
		guide.Parent = nil
	end

	local function dansMine(p: Vector3): boolean
		local a, b = dossier:GetAttribute("MineMin"), dossier:GetAttribute("MineMax")
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return false end
		return p.X > a.X and p.X < b.X and p.Y > a.Y and p.Y < b.Y and p.Z > a.Z and p.Z < b.Z
	end

	local function majGuide()
		local cercle = dossier:GetAttribute("Cercle")
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
		local debutBoss = dossier:GetAttribute("DebutBoss")
		local reste = if type(debutBoss) == "number" then debutBoss - workspace:GetServerTimeNow() else math.huge
		if modePuce ~= "annonce" or reste > (Config.GUIDE or 40) or typeof(cercle) ~= "Vector3" or not racine then
			cacherGuide()
			return
		end
		local pos = racine.Position
		local v = Vector3.new(cercle.X - pos.X, 0, cercle.Z - pos.Z)
		local d = v.Magnitude
		-- seulement à la surface près du village : pas sous terre (mine, grottes), pas trop loin, pas dans le cercle
		if d < (dossier:GetAttribute("RayonCercle") or 14) + 3 or d > 700 or pos.Y < cercle.Y - 20 or pos.Y > cercle.Y + 140 or dansMine(pos) then
			cacherGuide()
			return
		end
		if not guideVisible then
			guideVisible = true
			guide.Parent = workspace.CurrentCamera
		end
		local dir = v.Unit
		local couleur = bossProchain().couleur:Lerp(Color3.new(1, 1, 1), 0.35)
		params.FilterDescendantsInstances = {perso, guide}
		local t = os.clock()
		for k, bras in chevrons do
			local p = pos + dir * (4.5 + k * 3.2)
			local hit = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
			local sol = if hit then hit.Position else Vector3.new(p.X, pos.Y - 2.8, p.Z)
			local base = CFrame.lookAt(sol + Vector3.new(0, 0.18, 0), sol + Vector3.new(0, 0.18, 0) + dir)
			local onde = (t * 1.4 - k * 0.3) % 1 -- vague qui file vers le cercle
			local alpha = 0.2 + 0.65 * (1 - math.sin(onde * math.pi))
			for s, part in bras do
				local signe = if s == 1 then 1 else -1
				part.CFrame = base * CFrame.Angles(0, signe * math.rad(38), 0) * CFrame.new(0, 0, 1.1)
				part.Color = couleur
				part.Transparency = alpha
			end
		end
	end

	-- ================= 3. Panneau « PRÊT AU COMBAT » =================
	local HORS = UDim2.new(1, 360, 0.52, 0)
	local DEDANS = UDim2.new(1, -14, 0.52, 0)
	local panneau = creer("Frame", {Name = "FileBoss", AnchorPoint = Vector2.new(1, 0.5), Position = HORS, Size = UDim2.fromScale(0.41, 0.62),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(56, 34, 21), Visible = false, Parent = gui},
		{coin(0.05), trait(Color3.fromRGB(18, 10, 6), 3), creer("UISizeConstraint", {MinSize = Vector2.new(200, 300), MaxSize = Vector2.new(320, 485)})})
	local bordPanneau = trait(T.Or, 1.5, 0.5)
	local interieur = creer("Frame", {Name = "Interieur", Position = UDim2.fromScale(0.03, 0.02), Size = UDim2.fromScale(0.94, 0.96),
		BackgroundColor3 = T.Pierre, ClipsDescendants = true, Parent = panneau}, {coin(0.04), bordPanneau,
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 166, 166)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(226, 210, 196)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 196, 150))})})})
	-- lueur de braise en bas (respire)
	local lueur = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.35),
		BackgroundColor3 = T.Braise, BorderSizePixel = 0, Parent = interieur}, {creer("UIGradient", {Rotation = 90,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.72)})})})
	local respire = TweenService:Create(lueur, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.45})

	local entete = creer("Frame", {Size = UDim2.fromScale(1, 0.12), BackgroundColor3 = Color3.fromRGB(26, 17, 11), BorderSizePixel = 0, Parent = interieur},
		{creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.OrFonce,
			BorderSizePixel = 0})})
	local titreFile = texte({Text = "PRÊT AU COMBAT", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.66, 0.66), Parent = entete}, 30)
	UI.dore(titreFile, 2)
	Outils.epees(entete, T.Or, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.08, 0.5), Size = UDim2.fromScale(0.55, 0.55)})
	Outils.epees(entete, T.Or, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.92, 0.5), Size = UDim2.fromScale(0.55, 0.55)})

	local nomFile = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.05, 0.135), Size = UDim2.fromScale(0.9, 0.085), Parent = interieur}, 28)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 10, 6), Parent = nomFile})
	local rangFile = texte({Font = Enum.Font.Antique, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.05, 0.22), Size = UDim2.fromScale(0.9, 0.05),
		Parent = interieur}, 18)
	creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 10, 6), Parent = rangFile})

	local plaqueCompte = creer("Frame", {Position = UDim2.fromScale(0.12, 0.29), Size = UDim2.fromScale(0.76, 0.17), BackgroundColor3 = Color3.fromRGB(22, 15, 11),
		BackgroundTransparency = 0.15, Parent = interieur}, {coin(0.18), trait(T.OrFonce, 2, 0.2)})
	texte({Text = "DÉPART DANS", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromScale(0.1, 0.06), Size = UDim2.fromScale(0.8, 0.24),
		Parent = plaqueCompte}, 14)
	local compteFile = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.1, 0.3), Size = UDim2.fromScale(0.8, 0.64),
		Parent = plaqueCompte}, 52)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 10, 6), Parent = compteFile})

	local nombreFile = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.06, 0.48), Size = UDim2.fromScale(0.88, 0.05), Parent = interieur}, 18)
	creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 10, 6), Parent = nombreFile})
	local jaugeFile = creer("Frame", {Position = UDim2.fromScale(0.06, 0.54), Size = UDim2.fromScale(0.88, 0.016), BackgroundColor3 = Color3.fromRGB(20, 14, 10),
		BorderSizePixel = 0, Parent = interieur}, {coin(0.5)})
	local pleinFile = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = jaugeFile}, {coin(0.5),
		UI.degrade(Color3.fromRGB(255, 240, 180), T.OrFonce)})

	local grille = creer("Frame", {Position = UDim2.fromScale(0.05, 0.58), Size = UDim2.fromScale(0.9, 0.27), BackgroundTransparency = 1, Parent = interieur},
		{creer("UIGridLayout", {CellSize = UDim2.fromScale(0.125, 0.3), CellPadding = UDim2.fromScale(0.02, 0.04), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center})})
	local conseil = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.06, 0.865), Size = UDim2.fromScale(0.88, 0.115),
		TextWrapped = true, Parent = interieur}, 15)
	creer("UIStroke", {Thickness = 1.2, Color = Color3.fromRGB(20, 10, 6), Parent = conseil})

	local avatars: {[string]: Frame} = {}
	local fileVisible = false
	local dernierSeconde = -1

	local function montrerFile(voir: boolean)
		if voir == fileVisible then return end
		fileVisible = voir
		if voir then
			local def = bossProchain()
			nomFile.Text = string.upper(def.nom)
			nomFile.TextColor3 = def.couleur:Lerp(Color3.new(1, 1, 1), 0.35)
			rangFile.Text = "Rang : " .. def.titre
			conseil.Text = "Conseil : " .. (def.conseil or "reste mobile et sors des zones rouges.")
			bordPanneau.Color = def.couleur
			panneau.Visible = true
			panneau.Position = HORS
			TweenService:Create(panneau, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = DEDANS}):Play()
			respire:Play()
			Outils.jouer("souffle", 0.9)
			Outils.jouer("metal", 0.8)
		else
			respire:Pause()
			local t = TweenService:Create(panneau, UI.FAST, {Position = HORS})
			t.Completed:Once(function()
				if not fileVisible then panneau.Visible = false end
			end)
			t:Play()
		end
	end

	local function eclat()
		local f = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, BorderSizePixel = 0,
			ZIndex = 8, Parent = interieur}, {coin(0.04)})
		TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		task.delay(0.4, function() f:Destroy() end)
	end

	-- File = UserId séparés par des virgules (ordre d'arrivée) ; on ne reconstruit que ce qui change
	local function majFile()
		local texteFile = dossier:GetAttribute("File")
		local ids = if type(texteFile) == "string" and texteFile ~= "" then string.split(texteFile, ",") else {}
		local monId = tostring(joueur.UserId)
		local maPlace = table.find(ids, monId)
		local voir = maPlace ~= nil and dossier:GetAttribute("Etat") == "Attente" and not ctx.etat.cinematique and not dansArene()
		montrerFile(voir)
		if not voir then return end
		local max = Config.MAX_JOUEURS
		local garde: {[string]: boolean} = {}
		local nouveaux = 0
		for i = 1, math.min(#ids, max) do
			local id = ids[i]
			garde[id] = true
			local a = avatars[id]
			if not a then
				local n = tonumber(id) or 0
				local j = Players:GetPlayerByUserId(n)
				a = Outils.medaillon(grille, n, if j then j.DisplayName else "?", if id == monId then T.Or else T.FerSombre, {LayoutOrder = i})
				creer("UIAspectRatioConstraint", {AspectRatio = 1, Parent = a})
				avatars[id] = a
				UI.pop(a, 0.3)
				if id ~= monId then nouveaux += 1 end
			end
			a.LayoutOrder = i
		end
		for id, a in avatars do
			if not garde[id] then
				a:Destroy()
				avatars[id] = nil
			end
		end
		if nouveaux > 0 then
			Outils.jouer("metal", 1.1)
			eclat()
		end
		local n = math.min(#ids, max)
		TweenService:Create(pleinFile, UI.DOUX, {Size = UDim2.fromScale(n / max, 1)}):Play()
		if (maPlace :: number) > max then
			nombreFile.Text = string.format("%d/%d · arène pleine : tu es en réserve", n, max)
			nombreFile.TextColor3 = T.Rouge
		else
			nombreFile.Text = string.format("%d/%d mineur%s prêt%s", n, max, if n > 1 then "s" else "", if n > 1 then "s" else "")
			nombreFile.TextColor3 = T.Or
		end
	end

	local function majCompte()
		if not fileVisible then return end
		local r = reste()
		compteFile.Text = Config.minutes(r)
		local s = math.ceil(r)
		if r <= 5 and r > 0 and s ~= dernierSeconde then
			dernierSeconde = s
			compteFile.TextColor3 = T.Rouge
			UI.pop(compteFile, 1.5)
			Outils.jouer("ping", 0.8 + (5 - s) * 0.08, 0.35)
		elseif r > 5 then
			compteFile.TextColor3 = T.Parchemin
		end
	end

	dossier:GetAttributeChangedSignal("File"):Connect(majFile)
	dossier:GetAttributeChangedSignal("Etat"):Connect(function()
		majFile()
		majPuce()
	end)
	joueur:GetAttributeChangedSignal("DansArene"):Connect(function()
		majFile()
		majPuce()
	end)
	majFile()

	-- Une seule boucle légère : textes à 10 Hz, chevrons à 20 Hz
	local cumulTexte, cumulGuide = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		cumulTexte += dt
		cumulGuide += dt
		if cumulTexte >= 0.1 then
			cumulTexte = 0
			majPuce()
			majCompte()
		end
		if cumulGuide >= 0.05 then
			cumulGuide = 0
			if modePuce == "annonce" or guideVisible then majGuide() end
		end
	end)

	local api = {}
	function api.maj()
		majFile()
		majPuce()
	end
	-- Après le retour au village : « Prochain boss dans 6:12 » pendant 8 s
	function api.puceRetour()
		finRetour = os.clock() + 8
		majPuce()
	end
	function api.masquerFile()
		montrerFile(false)
	end
	return api
end

return Attente
