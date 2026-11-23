--!strict
-- Boss du village · CLIENT : l'annonce unique du prochain boss, en haut de l'écran (module de BossVillage.client).
-- Remplace la puce « <Boss> dans 0:42 » et le bandeau central pendant la dernière minute avant le boss.
--  • emblème du boss (rayons qui tournent, anneau qui pulse), nom doré teinté de la couleur du boss, titre,
--    grand compte à rebours, barre de temps, reflet qui balaie la carte, braises qui montent ;
--  • « REJOINDRE LE PORTAIL » : le serveur téléporte le joueur dans le grand cercle (BossVillage.server, « Rejoindre ») ;
--  • « IGNORER » : la carte disparaît jusqu'au boss suivant ;
--  • 10 dernières secondes : bord rouge qui bat, chiffres rouges qui cognent.
-- La carte se cache dans le cercle (le panneau « PRÊT AU COMBAT » prend le relais), dans l'arène et pendant les cinématiques.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local LARGEUR, HAUTEUR = 600, 132
local TAILLE = 0.72 -- échelle de la carte (1 = taille d'origine)
local OMBRE = Color3.fromRGB(16, 8, 4)
local BLANC = Color3.new(1, 1, 1)

local Annonce = {}

function Annonce.init(ctx)
	local gui: ScreenGui = ctx.gui
	local dossier: Instance = ctx.dossier
	local Config = ctx.Config
	local joueur: Player = ctx.joueur
	local action: RemoteEvent = ctx.action

	local function bossProchain()
		local i = dossier:GetAttribute("Prochain")
		return Config.BOSS[if type(i) == "number" then i else 1] or Config.BOSS[1]
	end
	local function reste(): number
		local debut = dossier:GetAttribute("DebutBoss")
		return if type(debut) == "number" then debut - workspace:GetServerTimeNow() else math.huge
	end
	local function dansLeCercle(): boolean
		local file = dossier:GetAttribute("File")
		if type(file) ~= "string" or file == "" then return false end
		return table.find(string.split(file, ","), tostring(joueur.UserId)) ~= nil
	end
	-- même zone que le serveur : on ne peut rejoindre que depuis la carte principale (village, mine publique)
	local function peutRejoindre(): boolean
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart")
		if not racine or not racine:IsA("BasePart") then return false end
		local p = racine.Position
		return math.abs(p.X) <= 700 and math.abs(p.Z) <= 700 and p.Y >= -200
	end

	-- ================= Carte =================
	local ancre = creer("Frame", {Name = "AnnonceBoss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -HAUTEUR - 40),
		Size = UDim2.fromOffset(LARGEUR, HAUTEUR), BackgroundTransparency = 1, Visible = false, ZIndex = 40, Parent = gui})
	local echelle = creer("UIScale", {Scale = 1, Parent = ancre})

	-- halo de couleur derrière la carte
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 34, 1, 34), BackgroundColor3 = T.Or, BackgroundTransparency = 0.75, ZIndex = 40, Parent = ancre}, {coin(0.28)})

	local carte = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, ClipsDescendants = true, ZIndex = 41,
		Parent = ancre}, {coin(0.16)})
	local fond = creer("UIGradient", {Rotation = 0, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.BoisSombre),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 8))}), Parent = carte})
	local bord = trait(T.Or, 3)
	bord.Parent = carte
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 190)),
		ColorSequenceKeypoint.new(0.5, T.Or), ColorSequenceKeypoint.new(1, T.OrFonce)}), Parent = bord})

	-- voile de la couleur du boss, de la gauche vers la droite
	local voile = creer("Frame", {Size = UDim2.fromScale(0.75, 1), BackgroundColor3 = T.Or, BackgroundTransparency = 0, ZIndex = 41,
		Parent = carte})
	creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)}),
		Parent = voile})

	-- liseret intérieur fin, couleur du boss
	local liseret = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1, ZIndex = 42, Parent = carte}, {coin(0.14)})
	local traitInterieur = trait(T.Or, 1, 0.55)
	traitInterieur.Parent = liseret

	-- reflet qui balaie la carte
	local reflet = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.2, 0.5), Size = UDim2.new(0, 60, 2, 0),
		Rotation = 20, BackgroundColor3 = BLANC, BackgroundTransparency = 0.82, ZIndex = 49, Parent = carte})

	-- ===== Emblème (gauche) =====
	local emb = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(74, HAUTEUR / 2),
		Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 43, Parent = carte})
	local rayons = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ZIndex = 43, Parent = emb})
	local listeRayons: {Frame} = {}
	for k = 0, 7 do
		local r = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 10, 1, 0),
			Rotation = k * 22.5, BackgroundColor3 = T.Or, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 43, Parent = rayons})
		creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)}), Parent = r})
		listeRayons[k + 1] = r
	end
	local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(92, 92),
		BackgroundColor3 = Color3.fromRGB(20, 14, 10), ZIndex = 44, Parent = emb}, {coin(1)})
	local traitAnneau = trait(T.Or, 3)
	traitAnneau.Parent = anneau
	local disque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(74, 74),
		BackgroundColor3 = T.Or, ZIndex = 45, Parent = anneau}, {coin(1), trait(OMBRE, 2)})
	local degradeDisque = creer("UIGradient", {Rotation = 120, Parent = disque})
	Outils.epees(disque, T.Parchemin, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.66), ZIndex = 46})

	-- ===== Textes (milieu) =====
	local X0 = 150
	local surtitre = texte({Text = "BOSS DU VILLAGE  ·  ARÈNE DES BOSS", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(X0, 12), Size = UDim2.fromOffset(300, 14), ZIndex = 46,
		Parent = carte}, 13)
	local nom = texte({Text = "Titan de cristal", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(X0, 26), Size = UDim2.fromOffset(310, 40), ZIndex = 46, Parent = carte}, 36)
	local degradeNom = creer("UIGradient", {Rotation = 90, Parent = nom})
	local traitNom = creer("UIStroke", {Thickness = 2.5, Color = OMBRE, Parent = nom})
	local titre = texte({Text = "Colosse des profondeurs", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(X0 + 2, 64), Size = UDim2.fromOffset(300, 18), ZIndex = 46, Parent = carte}, 18)
	creer("UIStroke", {Thickness = 1.5, Color = OMBRE, Parent = titre})

	-- ===== Compte à rebours (droite) =====
	local chrono = texte({Text = "0:60", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 14), Size = UDim2.fromOffset(120, 44), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 46,
		Parent = carte}, 44)
	creer("UIStroke", {Thickness = 3, Color = OMBRE, Parent = chrono})
	local echelleChrono = creer("UIScale", {Scale = 1, Parent = chrono})
	texte({Text = "AVANT LE DÉPART", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 56), Size = UDim2.fromOffset(130, 12), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 46,
		Parent = carte}, 12)

	-- ===== Boutons =====
	local function bouton(texteBouton: string, x: number, largeur: number, primaire: boolean): (TextButton, TextLabel, UIGradient?)
		local b = creer("TextButton", {Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(x, 90), Size = UDim2.fromOffset(largeur, 32),
			BackgroundColor3 = if primaire then BLANC else Color3.fromRGB(40, 32, 28), ZIndex = 47, ClipsDescendants = true, Parent = carte},
			{coin(0.3), trait(if primaire then T.Or else T.Inactif, if primaire then 2 else 1.5)})
		local g: UIGradient? = nil
		if primaire then
			g = creer("UIGradient", {Rotation = 90, Parent = b})
		end
		local l = texte({Text = texteBouton, Font = Enum.Font.GothamBlack, TextColor3 = if primaire then BLANC else T.Gris,
			Position = UDim2.fromScale(0.04, 0.16), Size = UDim2.fromScale(0.92, 0.68), ZIndex = 48, Parent = b}, 16)
		if primaire then creer("UIStroke", {Thickness = 2, Color = OMBRE, Parent = l}) end
		UI.reactif(b, 1.04)
		return b, l, g
	end
	local bRejoindre, lRejoindre, degradeRejoindre = bouton("REJOINDRE LE PORTAIL", X0, 250, true)
	local bIgnorer = bouton("IGNORER", X0 + 262, 110, false)
	local refletBouton = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.3, 0.5), Size = UDim2.new(0, 26, 2, 0),
		Rotation = 20, BackgroundColor3 = BLANC, BackgroundTransparency = 0.6, ZIndex = 48, Parent = bRejoindre})
	local echelleRejoindre = UI.echelle(bRejoindre)

	-- ===== Barre de temps (bas) =====
	local barreFond = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Color3.fromRGB(30, 22, 18), BorderSizePixel = 0, ZIndex = 46, Parent = carte})
	local barre = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 47, Parent = barreFond})
	local degradeBarre = creer("UIGradient", {Parent = barre})

	-- ===== Braises qui montent (calque de la carte) =====
	local function braise(couleur: Color3)
		local x = math.random()
		local taille = math.random(2, 4)
		local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 4), Size = UDim2.fromOffset(taille, taille),
			Rotation = math.random(0, 90), BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = 42, Parent = carte})
		local duree = 1.4 + math.random() * 1.2
		TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Position = UDim2.new(x + (math.random() - 0.5) * 0.08, 0, 0, -6), BackgroundTransparency = 1, Rotation = b.Rotation + 180}):Play()
		task.delay(duree + 0.05, function() b:Destroy() end)
	end

	-- ================= Thème du boss =================
	local couleur = T.Or
	local function appliquerBoss()
		local def = bossProchain()
		couleur = def.couleur
		local claire = couleur:Lerp(BLANC, 0.55)
		nom.Text = def.nom
		titre.Text = def.titre or ""
		titre.TextColor3 = couleur:Lerp(BLANC, 0.35)
		degradeNom.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 225)),
			ColorSequenceKeypoint.new(0.45, claire), ColorSequenceKeypoint.new(1, couleur)})
		traitNom.Color = couleur:Lerp(OMBRE, 0.8)
		halo.BackgroundColor3 = couleur
		voile.BackgroundColor3 = couleur
		traitInterieur.Color = couleur
		traitAnneau.Color = claire
		degradeDisque.Color = ColorSequence.new(claire, couleur:Lerp(OMBRE, 0.35))
		for _, r in listeRayons do r.BackgroundColor3 = couleur end
		if degradeRejoindre then
			degradeRejoindre.Color = ColorSequence.new(claire, couleur:Lerp(OMBRE, 0.3))
		end
		degradeBarre.Color = ColorSequence.new(claire, couleur)
		fond.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, couleur:Lerp(OMBRE, 0.78)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 8))})
	end

	-- ================= Apparition =================
	local visible = false
	local ignoreDebut: number? = nil -- DebutBoss du cycle ignoré
	local enTeleportation = false
	local function montrer(oui: boolean)
		if oui == visible then return end
		visible = oui
		if oui then
			appliquerBoss()
			enTeleportation = false
			ancre.Visible = true
			ancre.Position = UDim2.new(0.5, 0, 0, -HAUTEUR - 40)
			TweenService:Create(ancre, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0, 10)}):Play()
			halo.BackgroundTransparency = 0.2
			TweenService:Create(halo, TweenInfo.new(0.9), {BackgroundTransparency = 0.75}):Play()
			reflet.Position = UDim2.fromScale(-0.2, 0.5)
			TweenService:Create(reflet, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(1.2, 0.5)}):Play()
			Outils.jouer("lame", 0.9, 0.5)
			Outils.jouer("grondement", 0.8, 0.45)
		else
			local t = TweenService:Create(ancre, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, 0, -HAUTEUR - 40)})
			t.Completed:Once(function()
				if not visible then ancre.Visible = false end
			end)
			t:Play()
		end
	end

	bRejoindre.Activated:Connect(function()
		if enTeleportation then return end
		if not peutRejoindre() then
			UI.secouer(bRejoindre, 6)
			return
		end
		enTeleportation = true
		lRejoindre.Text = "TÉLÉPORTATION…"
		Outils.jouer("lame", 1.3, 0.5)
		action:FireServer("Rejoindre")
		task.delay(2.5, function() enTeleportation = false end)
	end)
	bIgnorer.Activated:Connect(function()
		local debut = dossier:GetAttribute("DebutBoss")
		ignoreDebut = if type(debut) == "number" then debut else -1
		Outils.jouer("clic", 0.9)
		montrer(false)
	end)

	-- ================= Animation (chaque image) =================
	local dernierSecondes = -1
	local prochaineBraise = 0
	local prochainReflet = os.clock() + 2.5
	RunService.RenderStepped:Connect(function()
		local r = reste()
		local debut = dossier:GetAttribute("DebutBoss")
		local doit = dossier:GetAttribute("Etat") == "Attente" and r > 0 and r <= Config.ANNONCE
			and not ctx.etat.cinematique and joueur:GetAttribute("DansArene") ~= true and not dansLeCercle()
			and not (ignoreDebut ~= nil and ignoreDebut == debut)
		montrer(doit)
		if not ancre.Visible then return end

		-- taille adaptée à l'écran (téléphone)
		local camera = workspace.CurrentCamera
		if camera then
			echelle.Scale = math.clamp((camera.ViewportSize.X - 24) / LARGEUR, 0.5, 1) * TAILLE
		end

		local t = os.clock()
		local urgent = r <= 10
		chrono.Text = Config.minutes(math.max(0, r))
		chrono.TextColor3 = if urgent then T.Rouge:Lerp(BLANC, 0.15) else T.Parchemin
		local s = math.ceil(r)
		if s ~= dernierSecondes then
			dernierSecondes = s
			if urgent and s > 0 then
				echelleChrono.Scale = 1.3
				TweenService:Create(echelleChrono, UI.BOUNCY, {Scale = 1}):Play()
				Outils.jouer("ping", 0.8 + (10 - s) * 0.05, 0.3)
			end
		end
		barre.Size = UDim2.fromScale(math.clamp(r / Config.ANNONCE, 0, 1), 1)

		-- emblème : rayons qui tournent, anneau qui respire
		rayons.Rotation = (t * 25) % 360
		local souffle = 0.5 + 0.5 * math.sin(t * 3)
		anneau.Size = UDim2.fromOffset(92 + souffle * 4, 92 + souffle * 4)
		for i, ray in listeRayons do
			ray.BackgroundTransparency = 0.45 + 0.3 * (0.5 + 0.5 * math.sin(t * 2 + i))
		end
		halo.BackgroundTransparency = 0.7 + 0.12 * souffle

		-- bord : or, puis rouge qui bat pendant les 10 dernières secondes
		if urgent then
			bord.Color = T.Rouge:Lerp(BLANC, 0.25 * souffle)
			bord.Thickness = 3 + 1.5 * (0.5 + 0.5 * math.sin(t * 12))
		else
			bord.Color, bord.Thickness = BLANC, 3
		end

		-- bouton Rejoindre : pulse doux + reflet ; grisé hors de la carte principale
		local possible = peutRejoindre()
		if not enTeleportation then
			lRejoindre.Text = if possible then "REJOINDRE LE PORTAIL" else "RETOURNE AU VILLAGE"
		end
		bRejoindre.BackgroundTransparency = if possible then 0 else 0.55
		echelleRejoindre.Scale = if possible then 1 + 0.03 * math.sin(t * 4) else 1
		refletBouton.Position = UDim2.fromScale(((t * 0.8) % 1.8) - 0.4, 0.5)

		-- reflet sur toute la carte de temps en temps, braises qui montent
		if t >= prochainReflet then
			prochainReflet = t + 3.2
			reflet.Position = UDim2.fromScale(-0.2, 0.5)
			TweenService:Create(reflet, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(1.2, 0.5)}):Play()
		end
		if t >= prochaineBraise then
			prochaineBraise = t + (if urgent then 0.06 else 0.14)
			braise(if math.random() < 0.6 then couleur:Lerp(BLANC, 0.4) else T.Or)
		end
	end)

	return {}
end

return Annonce
