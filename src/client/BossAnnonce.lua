--!strict
-- Boss du village · CLIENT : l'annonce unique du prochain boss (module de BossVillage.client).
-- Remplace la puce « <Boss> dans 0:42 » et le bandeau central pendant la dernière minute avant le boss.
-- Deux formats, choisis selon le lieu du joueur (réévalué 2 fois par seconde, passage animé de l'un à l'autre) :
--  • « haut » (village, surface, mine publique) : grande carte tout en haut de l'écran, centrée, qui tombe du bord ;
--  • « cote » (grotte ou mine privée) : carte compacte sur le bord DROIT, qui glisse depuis le bord, placée dans un
--    créneau libre (évite le suivi de quêtes, le compteur de reliques et le bouton « Remonter »).
--    Grotte = joueur dans la boîte d'un modèle de workspace.Grottes (attributs Centre / DemiTaille) ;
--    mine privée = attribut joueur « ProfondeurMine » ou joueur dans la boîte d'un modèle de workspace.MinesPrivees.
-- Contenu : emblème du boss (tête 3D animée, rayons qui tournent, anneau qui respire), nom révélé lettre par lettre,
--   titre, plaque de compte à rebours bien visible, barre de temps, mineurs déjà prêts (avatars), attaques du boss,
--   halos et reflets à la couleur du boss, braises qui montent ;
--  • entrée : éclair sur les bords de l'écran, flash, onde de choc depuis l'emblème, gerbe d'étincelles ;
--  • « REJOINDRE LE PORTAIL » : le serveur téléporte le joueur dans le grand cercle (BossVillage.server, « Rejoindre ») ;
--  • « IGNORER » : la carte disparaît jusqu'au boss suivant ;
--  • 10 dernières secondes : bord et plaque rouges qui battent, chiffres rouges qui cognent.
-- La carte se cache dans le cercle (le panneau « PRÊT AU COMBAT » prend le relais), dans l'arène et pendant les cinématiques.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MobsVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MobsVoxels"))

-- Touches : R = rejoindre le portail, X = ignorer (manette : croix haut / croix bas). E sert déjà aux invites.
local TOUCHES_REJOINDRE = {Enum.KeyCode.R, Enum.KeyCode.DPadUp}
local TOUCHES_IGNORER = {Enum.KeyCode.X, Enum.KeyCode.DPadDown}

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

type Format = {largeur: number, hauteur: number}
-- tailles de dessin (en px avant l'UIScale de l'écran)
local FORMATS: {[string]: Format} = {
	haut = {largeur = 620, hauteur = 168},
	cote = {largeur = 300, hauteur = 258},
}
local OMBRE = Color3.fromRGB(16, 8, 4)
local BLANC = Color3.new(1, 1, 1)
local MARGE_COTE = 12 -- distance au bord droit (format côté)

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
	local function racineJoueur(): BasePart?
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart")
		return if racine and racine:IsA("BasePart") then racine else nil
	end
	-- même zone que le serveur : on ne peut rejoindre que depuis la carte principale (village, mine publique)
	local function peutRejoindre(): boolean
		local racine = racineJoueur()
		if not racine then return false end
		local p = racine.Position
		return math.abs(p.X) <= 700 and math.abs(p.Z) <= 700 and p.Y >= -200
	end

	-- ================= Lieu du joueur : grotte / mine privée → format « cote », sinon « haut » =================
	-- même test que AmbianceGrotte.client (grotteAutour)
	local function dansUneGrotte(p: Vector3): boolean
		local grottes = workspace:FindFirstChild("Grottes")
		if not grottes then return false end
		for _, g in grottes:GetChildren() do
			local c, d = g:GetAttribute("Centre"), g:GetAttribute("DemiTaille")
			if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
				local r = p - c
				if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then return true end
			end
		end
		return false
	end
	-- boîtes des mines privées, calculées une fois (la coque d'une mine ne bouge pas) puis rafraîchies toutes les 30 s
	local boitesMines: {[Instance]: {cf: CFrame, demi: Vector3, quand: number}} = setmetatable({}, {__mode = "k"}) :: any
	local function dansUneMinePrivee(p: Vector3): boolean
		if type(joueur:GetAttribute("ProfondeurMine")) == "number" then return true end -- sous la galerie de sa mine (RemonterMine.server)
		local mines = workspace:FindFirstChild("MinesPrivees")
		if not mines then return false end
		local maintenant = os.clock()
		for _, m in mines:GetChildren() do
			if m:IsA("Model") then
				local b = boitesMines[m]
				if not b or maintenant - b.quand > 30 then
					local cf, taille = m:GetBoundingBox()
					if taille.Magnitude < 10 then continue end -- pas encore chargée : on ne retient rien
					b = {cf = cf, demi = taille / 2 + Vector3.new(6, 12, 6), quand = maintenant}
					boitesMines[m] = b
				end
				if b then
					local r = b.cf:PointToObjectSpace(p)
					if math.abs(r.X) < b.demi.X and math.abs(r.Y) < b.demi.Y and math.abs(r.Z) < b.demi.Z then return true end
				end
			end
		end
		return false
	end
	local function lieu(): string
		local racine = racineJoueur()
		if not racine then return "haut" end
		local p = racine.Position
		return if dansUneGrotte(p) or dansUneMinePrivee(p) then "cote" else "haut"
	end

	-- ================= Carte =================
	local ancre = creer("Frame", {Name = "AnnonceBoss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -400),
		Size = UDim2.fromOffset(FORMATS.haut.largeur, FORMATS.haut.hauteur), BackgroundTransparency = 1, Visible = false, ZIndex = 40,
		Parent = gui})
	local echelle = creer("UIScale", {Scale = 1, Parent = ancre})

	-- lueur de la couleur du boss derrière la carte : 3 couches de plus en plus larges et diffuses
	local HALOS = {{ecart = 12, base = 0.6}, {ecart = 28, base = 0.8}, {ecart = 48, base = 0.9}}
	local halos: {Frame} = {}
	for i, h in HALOS do
		halos[i] = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, h.ecart, 1, h.ecart), BackgroundColor3 = T.Or, BackgroundTransparency = h.base, BorderSizePixel = 0,
			ZIndex = 40 - i, Parent = ancre}, {coin(0.22 + i * 0.04)})
	end

	local carte = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLANC, ClipsDescendants = true, ZIndex = 41, Parent = ancre}, {coin(0.16)})
	local echelleCarte = creer("UIScale", {Scale = 1, Parent = carte})
	local fond = creer("UIGradient", {Rotation = 0, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.BoisSombre),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 8))}), Parent = carte})
	local bord = trait(T.Or, 3)
	bord.Parent = carte
	-- bord : dégradé or / couleur du boss / blanc qui tourne tout autour de la carte
	local degradeBord = creer("UIGradient", {Rotation = 0, Parent = bord})

	-- rayures diagonales qui défilent lentement (couleur du boss, très discrètes)
	local rayures = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 41, Parent = carte})
	local listeRayures: {Frame} = {}
	for k = 0, 22 do
		listeRayures[k + 1] = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, k * 32 - 60, 0.5, 0),
			Size = UDim2.new(0, 10, 2.4, 0), Rotation = 32, BackgroundColor3 = T.Or, BackgroundTransparency = 0.94, BorderSizePixel = 0,
			ZIndex = 41, Parent = rayures})
	end

	-- voile de la couleur du boss, depuis l'emblème
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
	-- flash blanc de l'entrée (couvre toute la carte puis s'efface)
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 50, Parent = carte})

	-- ===== Emblème =====
	local emb = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(78, 82),
		Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 43, Parent = carte})
	local echelleEmb = creer("UIScale", {Scale = 1, Parent = emb})
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
	-- logo du boss : sa tête en 3D (même modèle voxel que l'écran de chargement), épées croisées en secours
	local epees = Outils.epees(disque, T.Parchemin, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.66), ZIndex = 46})
	local logo = creer("ViewportFrame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 170), LightColor = BLANC, LightDirection = Vector3.new(-0.4, -0.6, -1),
		ZIndex = 46, Parent = disque}, {coin(1)})
	local camLogo = creer("Camera", {FieldOfView = 30, Parent = logo})
	logo.CurrentCamera = camLogo
	local mondeLogo = creer("WorldModel", {Parent = logo})
	local modelesLogo: {[string]: Model | false} = {}
	-- cadrage courant de la tête (la caméra se balance doucement autour, voir l'animation)
	local cadrage: {haut: Vector3, avant: Vector3, distance: number, montee: number}? = nil
	local function poserLogo(def)
		for _, m in mondeLogo:GetChildren() do m.Parent = nil end
		local m = modelesLogo[def.id]
		if m == nil then
			m = false
			pcall(function()
				local nomModele = if MobsVoxels.existe(def.id) then def.id
					elseif def.secours and MobsVoxels.existe(def.secours) then def.secours else nil
				if nomModele then
					local construit = MobsVoxels.construire(nomModele, CFrame.new())
					for _, piece in construit:GetDescendants() do
						if piece:IsA("BasePart") then piece.CastShadow = false end
					end
					-- le boss respire (animation Idle, comme sur l'écran de chargement)
					construit.Parent = mondeLogo
					pcall(function()
						MobsVoxels.animateur(construit, nomModele):Jouer("Idle", true, 0)
					end)
					m = construit
				end
			end)
			modelesLogo[def.id] = m
		end
		if m then
			m.Parent = mondeLogo
			-- cadrage sur le haut du corps (la tête), de face
			local cf, taille = m:GetBoundingBox()
			local haut = cf.Position + Vector3.new(0, taille.Y * 0.28, 0)
			local d = math.max(taille.X, taille.Y * 0.5) * 0.5 / math.tan(math.rad(camLogo.FieldOfView / 2)) * 1.05
			cadrage = {haut = haut, avant = cf.LookVector, distance = d, montee = taille.Y * 0.05}
			camLogo.CFrame = CFrame.lookAt(haut + cf.LookVector * d + Vector3.new(0, taille.Y * 0.05, 0), haut)
			epees.Visible, logo.Visible = false, true
		else
			cadrage = nil
			epees.Visible, logo.Visible = true, false
		end
	end

	-- ===== Textes =====
	-- point rouge qui bat + « APPEL AUX ARMES »
	local pointAlerte = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = T.Rouge, ZIndex = 46, Parent = carte}, {coin(1)})
	local surtitre = texte({Text = "APPEL AUX ARMES  ·  BOSS DU VILLAGE", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 46, Parent = carte}, 13)
	local nom = texte({Text = "Titan de cristal", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 46, Parent = carte}, 38)
	local degradeNom = creer("UIGradient", {Rotation = 90, Parent = nom})
	local traitNom = creer("UIStroke", {Thickness = 2.5, Color = OMBRE, Parent = nom})
	local titre = texte({Text = "Colosse des profondeurs", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 46, Parent = carte}, 18)
	creer("UIStroke", {Thickness = 1.5, Color = OMBRE, Parent = titre})

	-- ===== Plaque du compte à rebours =====
	local plaque = creer("Frame", {AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.fromRGB(12, 8, 6), BackgroundTransparency = 0.1,
		ZIndex = 45, Parent = carte}, {coin(0.2)})
	local traitPlaque = trait(T.Or, 2)
	traitPlaque.Parent = plaque
	-- lueur de la couleur du boss qui monte du bas de la plaque
	local lueurPlaque = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Or, BackgroundTransparency = 0.5, BorderSizePixel = 0,
		ZIndex = 45, Parent = plaque}, {coin(0.2), creer("UIGradient", {Rotation = 270,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1)})})})
	local chrono = texte({Text = "1:00", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0), Size = UDim2.new(1, -12, 0.62, 0), ZIndex = 47, Parent = plaque}, 52)
	creer("UIStroke", {Thickness = 3, Color = OMBRE, Parent = chrono})
	local echelleChrono = creer("UIScale", {Scale = 1, Parent = chrono})
	local etiquetteChrono = texte({Text = "AVANT LE DÉPART", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.new(1, -12, 0, 12), ZIndex = 47, Parent = plaque}, 12)

	-- ===== Boutons =====
	local function bouton(texteBouton: string, primaire: boolean): (TextButton, TextLabel, UIGradient?)
		local b = creer("TextButton", {Text = "", AutoButtonColor = false,
			BackgroundColor3 = if primaire then BLANC else Color3.fromRGB(40, 32, 28), ZIndex = 47, ClipsDescendants = true, Parent = carte},
			{coin(0.3), trait(if primaire then T.Or else T.Inactif, if primaire then 2 else 1.5)})
		local g: UIGradient? = nil
		if primaire then
			g = creer("UIGradient", {Rotation = 90, Parent = b})
		end
		local l = texte({Text = texteBouton, Font = Enum.Font.GothamBlack, TextColor3 = if primaire then BLANC else T.Gris,
			Position = UDim2.fromScale(0.04, 0.18), Size = UDim2.fromScale(0.92, 0.64), ZIndex = 48, Parent = b}, 17)
		if primaire then creer("UIStroke", {Thickness = 2, Color = OMBRE, Parent = l}) end
		UI.reactif(b, 1.04)
		return b, l, g
	end
	local bRejoindre, lRejoindre, degradeRejoindre = bouton("[R]  REJOINDRE LE PORTAIL", true)
	local bIgnorer, lIgnorer = bouton("[X]  IGNORER", false)
	local refletBouton = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.3, 0.5), Size = UDim2.new(0, 26, 2, 0),
		Rotation = 20, BackgroundColor3 = BLANC, BackgroundTransparency = 0.6, ZIndex = 48, Parent = bRejoindre})
	local echelleRejoindre = UI.echelle(bRejoindre)

	-- indications de touches selon le dernier périphérique (clavier, manette, tactile)
	local PREFIXES = {
		clavier = {rejoindre = "[R]  ", ignorer = "[X]  "},
		manette = {rejoindre = "[CROIX HAUT]  ", ignorer = "[CROIX BAS]  "},
		tactile = {rejoindre = "", ignorer = ""},
	}
	local peripherique = "clavier"
	local function majPeripherique()
		local dernier = UserInputService:GetLastInputType()
		peripherique = if dernier.Name:sub(1, 7) == "Gamepad" then "manette"
			elseif dernier == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
				and not UserInputService.GamepadEnabled) then "tactile"
			else "clavier"
		lIgnorer.Text = PREFIXES[peripherique].ignorer .. "IGNORER"
	end
	UserInputService.LastInputTypeChanged:Connect(majPeripherique)
	majPeripherique()

	-- ===== Bande du bas : mineurs déjà prêts (avatars) + attaques du boss =====
	local xBande, yBande, largeurPrets = 158, 142, 300
	local avatars: {ImageLabel} = {}
	for i = 1, 5 do
		local a = creer("ImageLabel", {Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Color3.fromRGB(40, 32, 28), Image = "", ZIndex = 47 + i, Visible = false, Parent = carte},
			{coin(1), trait(OMBRE, 1.5)})
		avatars[i] = a
	end
	local prets = texte({Text = "Sois le premier dans le cercle !", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 47, RichText = true, Parent = carte}, 14)
	local attaques = texte({Text = "", Font = Enum.Font.GothamBold, TextColor3 = T.Gris, AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 47, RichText = true, Parent = carte}, 13)
	local NOMS_ATTAQUES = {Onde = "Onde", Poings = "Poings", Eclats = "Éclats", Toile = "Toile", Invocation = "Invocation",
		Bond = "Bond", Meteores = "Météores", Lave = "Lave", Souffle = "Souffle"}
	local nombrePrets = -1
	local function majPrets()
		local file = dossier:GetAttribute("File")
		local ids = if type(file) == "string" and file ~= "" then string.split(file, ",") else {}
		local n = #ids
		for i, a in avatars do
			local id = tonumber(ids[i])
			a.Visible = id ~= nil
			if id then Outils.avatar(id, a) end
		end
		local decalage = math.min(n, 5) * 15 + (if n > 0 then 10 else 0)
		prets.Position = UDim2.fromOffset(xBande + decalage, yBande + 3)
		prets.Size = UDim2.fromOffset(largeurPrets - decalage, 14)
		prets.Text = if n == 0 then "Sois le premier dans le cercle !"
			else string.format('<font color="#FFCC5C">%d/%d</font> mineurs prêts', n, Config.MAX_JOUEURS)
		if n > nombrePrets and nombrePrets >= 0 then UI.pop(prets, 0.8) end
		nombrePrets = n
	end
	dossier:GetAttributeChangedSignal("File"):Connect(majPrets)

	-- ===== Barre de temps (bas) =====
	local barreFond = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Color3.fromRGB(30, 22, 18), BorderSizePixel = 0, ZIndex = 46, Parent = carte})
	local barre = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 47, Parent = barreFond})
	local degradeBarre = creer("UIGradient", {Parent = barre})

	-- ===== Onde de choc de l'entrée (part de l'emblème, déborde de la carte) =====
	local onde = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 1,
		Visible = false, ZIndex = 42, Parent = ancre}, {coin(1)})
	local traitOnde = trait(T.Or, 6)
	traitOnde.Parent = onde

	-- ================= Disposition des deux formats =================
	local format = "haut"
	local F: Format = FORMATS.haut
	local embBase = Vector2.new(78, 82)
	local function placer(o: GuiObject, x: number, y: number, l: number, h: number)
		o.Position = UDim2.fromOffset(x, y)
		o.Size = UDim2.fromOffset(l, h)
	end
	local function disposer(nouveau: string)
		format = nouveau
		F = FORMATS[nouveau]
		local c = nouveau == "cote"
		ancre.Size = UDim2.fromOffset(F.largeur, F.hauteur)
		ancre.AnchorPoint = if c then Vector2.new(1, 0) else Vector2.new(0.5, 0)
		embBase = if c then Vector2.new(70, 92) else Vector2.new(78, 82)
		emb.Position = UDim2.fromOffset(embBase.X, embBase.Y)
		echelleEmb.Scale = if c then 0.78 else 1
		pointAlerte.Position = UDim2.fromOffset(if c then 16 else 160, if c then 19 else 21)
		placer(surtitre, if c then 30 else 174, if c then 12 else 14, if c then 256 else 300, 14)
		surtitre.Text = if c then "APPEL AUX ARMES  ·  BOSS" else "APPEL AUX ARMES  ·  BOSS DU VILLAGE"
		placer(nom, if c then 138 else 158, if c then 32 else 28, if c then 150 else 300, if c then 32 else 42)
		placer(titre, if c then 139 else 160, if c then 66 else 70, if c then 150 else 300, if c then 16 else 18)
		plaque.Position = UDim2.new(1, if c then -14 else -16, 0, if c then 88 else 14)
		plaque.Size = UDim2.fromOffset(if c then 148 else 132, if c then 64 else 78)
		placer(bRejoindre, if c then 14 else 158, if c then 162 else 98, if c then 272 else 312, if c then 38 else 36)
		placer(bIgnorer, if c then 186 else 482, if c then 208 else 98, if c then 100 else 122, if c then 30 else 36)
		xBande, yBande, largeurPrets = if c then 14 else 158, if c then 212 else 142, if c then 168 else 300
		for i, a in avatars do
			a.Position = UDim2.fromOffset(xBande + (i - 1) * 15, yBande)
		end
		attaques.Position = UDim2.new(1, if c then -14 else -16, 0, if c then 238 else 145)
		attaques.Size = UDim2.fromOffset(if c then 272 else 220, 14)
		nombrePrets = -1
		majPrets()
	end
	disposer("haut")

	-- ================= Thème du boss =================
	local couleur = T.Or
	local function appliquerBoss()
		local def = bossProchain()
		couleur = def.couleur
		local claire = couleur:Lerp(BLANC, 0.55)
		nom.Text = def.nom
		poserLogo(def)
		titre.Text = def.titre or ""
		titre.TextColor3 = couleur:Lerp(BLANC, 0.35)
		degradeNom.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 225)),
			ColorSequenceKeypoint.new(0.45, claire), ColorSequenceKeypoint.new(1, couleur)})
		traitNom.Color = couleur:Lerp(OMBRE, 0.8)
		for _, h in halos do h.BackgroundColor3 = couleur end
		voile.BackgroundColor3 = couleur
		traitInterieur.Color = couleur
		traitAnneau.Color = claire
		traitOnde.Color = claire
		lueurPlaque.BackgroundColor3 = couleur
		degradeDisque.Color = ColorSequence.new(claire, couleur:Lerp(OMBRE, 0.35))
		for _, r in listeRayons do r.BackgroundColor3 = couleur end
		if degradeRejoindre then
			degradeRejoindre.Color = ColorSequence.new(claire, couleur:Lerp(OMBRE, 0.3))
		end
		degradeBarre.Color = ColorSequence.new(claire, couleur)
		degradeBord.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.Or), ColorSequenceKeypoint.new(0.25, BLANC),
			ColorSequenceKeypoint.new(0.5, couleur), ColorSequenceKeypoint.new(0.75, claire), ColorSequenceKeypoint.new(1, T.Or)})
		for _, r in listeRayures do r.BackgroundColor3 = couleur end
		local liste = {}
		for _, a in def.attaques or {} do table.insert(liste, NOMS_ATTAQUES[a] or a) end
		attaques.Text = if #liste > 0 then '<font color="#9C9084">ATTAQUES </font>' .. table.concat(liste, " · ") else ""
		attaques.TextColor3 = couleur:Lerp(BLANC, 0.45)
		nombrePrets = -1
		majPrets()
		fond.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, couleur:Lerp(OMBRE, 0.78)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 8))})
	end

	-- ================= Taille et place à l'écran =================
	local function tactile(): boolean
		return peripherique == "tactile"
	end
	local function majEchelle()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local v = camera.ViewportSize
		if format == "cote" then
			-- compacte : ~30 % de la largeur, ~40 % de la hauteur au plus
			echelle.Scale = math.clamp(math.min(v.X * 0.3 / F.largeur, v.Y * 0.4 / F.hauteur), 0.5, 0.85)
		else
			echelle.Scale = math.clamp((v.X - 24) / F.largeur, 0.5, 1) * (if tactile() then 0.7 else 0.62)
		end
	end

	-- éléments du HUD déjà sur le bord droit : la carte « cote » se place dans un créneau libre entre eux
	local function obstaclesDroite(largeurCarte: number): {{number}}
		local liste: {{number}} = {}
		local pg = joueur:FindFirstChildOfClass("PlayerGui")
		if not pg then return liste end
		local ecran = gui.AbsoluteSize.X
		local function ajouter(o: Instance?)
			if not o or not o:IsA("GuiObject") or not o.Visible then return end
			local sg = o:FindFirstAncestorOfClass("ScreenGui")
			if not sg or not sg.Enabled then return end
			local pos, taille = o.AbsolutePosition, o.AbsoluteSize
			-- seulement ce qui est à l'écran et dans la colonne de droite occupée par la carte
			if taille.Y > 0 and pos.X < ecran and pos.X + taille.X > ecran - largeurCarte - MARGE_COTE - 10 then
				table.insert(liste, {pos.Y, pos.Y + taille.Y})
			end
		end
		local suivi = pg:FindFirstChild("SuiviQuetes")
		ajouter(suivi and suivi:FindFirstChild("Panneau"))
		local reliques = pg:FindFirstChild("ReliquesMagmaHUD")
		ajouter(reliques and reliques:FindFirstChild("Compteur"))
		local remonter = pg:FindFirstChild("RemonterMine")
		ajouter(remonter and remonter:FindFirstChildOfClass("TextButton"))
		return liste
	end
	local function hautCote(): number
		local s = echelle.Scale
		local h, l = F.hauteur * s, F.largeur * s
		local H = gui.AbsoluteSize.Y
		local mini = 8
		local maxi = math.max(mini, H - h - 120) -- le bas reste aux boutons mobiles (saut, courir)
		local voulu = math.clamp(H * 0.42 - h / 2, mini, maxi) -- centré, un peu au-dessus du milieu
		local obstacles = obstaclesDroite(l)
		local function libre(y: number): boolean
			if y < mini or y > maxi then return false end
			for _, o in obstacles do
				if y < o[2] + 8 and y + h > o[1] - 8 then return false end
			end
			return true
		end
		local candidats = {voulu}
		for _, o in obstacles do
			table.insert(candidats, o[2] + 8)
			table.insert(candidats, o[1] - 8 - h)
		end
		local meilleur: number? = nil
		for _, y in candidats do
			if libre(y) and (meilleur == nil or math.abs(y - voulu) < math.abs(meilleur - voulu)) then meilleur = y end
		end
		return meilleur or voulu
	end

	local yCote = 0
	local function posVisible(): UDim2
		return if format == "cote" then UDim2.new(1, -MARGE_COTE, 0, yCote) else UDim2.new(0.5, 0, 0, 4)
	end
	local function posCachee(): UDim2
		local s = echelle.Scale
		return if format == "cote" then UDim2.new(1, F.largeur * s + 70, 0, yCote)
			else UDim2.new(0.5, 0, 0, -F.hauteur * s - 80)
	end
	local tweenAncre: Tween? = nil
	local function glisser(cible: UDim2, info: TweenInfo, fin: (() -> ())?)
		if tweenAncre then tweenAncre:Cancel() end
		local tw = TweenService:Create(ancre, info, {Position = cible})
		tweenAncre = tw
		if fin then
			tw.Completed:Connect(function(etat)
				if etat == Enum.PlaybackState.Completed then fin() end
			end)
		end
		tw:Play()
	end
	local ENTREE_HAUT = TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local ENTREE_COTE = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local SORTIE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	-- ================= Apparition =================
	-- éclair de la couleur du boss sur les bords de l'écran à l'arrivée de l'annonce
	-- le trait est dessiné autour du cadre : cadre rentré de 40 px pour que l'éclair tombe sur les bords de l'écran
	local eclair = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -80, 1, -80),
		BackgroundTransparency = 1, ZIndex = 39, Visible = false, Parent = gui})
	local traitEclair = creer("UIStroke", {Thickness = 40, Color = T.Or, Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = eclair})
	local debutEntree = -math.huge -- pour l'éclat des halos et la révélation du nom
	local function effetsEntree(complet: boolean)
		debutEntree = os.clock()
		-- la carte claque : flash blanc, petit zoom, onde de choc depuis l'emblème, étincelles
		flash.BackgroundTransparency = 0.05
		TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		echelleCarte.Scale = 0.82
		TweenService:Create(echelleCarte, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		local s = echelleEmb.Scale
		onde.Position = UDim2.fromOffset(embBase.X, embBase.Y)
		onde.Size = UDim2.fromOffset(60 * s, 60 * s)
		onde.Visible = true
		traitOnde.Transparency, traitOnde.Thickness = 0, 6
		local tw = TweenService:Create(onde, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Size = UDim2.fromOffset(F.largeur * 1.1, F.largeur * 1.1)})
		TweenService:Create(traitOnde, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Transparency = 1, Thickness = 1}):Play()
		tw.Completed:Once(function() onde.Visible = false end)
		tw:Play()
		UI.gerbe(ancre, couleur, if complet then 20 else 12, Vector2.new(embBase.X / F.largeur, embBase.Y / F.hauteur))
		UI.pop(disque, 0.3)
		task.delay(0.18, function() UI.pop(plaque, 0.6) end)
		reflet.Position = UDim2.fromScale(-0.2, 0.5)
		TweenService:Create(reflet, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(1.2, 0.5)}):Play()
		if complet then
			-- éclair sur les bords de l'écran (plus discret en format côté, on est en pleine exploration)
			eclair.Visible = true
			traitEclair.Color = couleur
			traitEclair.Transparency = if format == "cote" then 0.55 else 0.25
			local fondu = TweenService:Create(traitEclair, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {Transparency = 1})
			fondu.Completed:Once(function() eclair.Visible = false end)
			fondu:Play()
			Outils.jouer("lame", 0.9, 0.5)
			Outils.jouer("grondement", 0.8, 0.45)
		else
			Outils.jouer("souffle", 1.1, 0.35)
		end
	end

	local visible = false
	local enBascule = false
	local ignoreDebut: number? = nil -- DebutBoss du cycle ignoré
	local enTeleportation = false
	local function montrer(oui: boolean)
		if oui == visible then return end
		visible = oui
		enBascule = false
		if oui then
			appliquerBoss()
			enTeleportation = false
			disposer(lieu())
			majEchelle()
			if format == "cote" then yCote = hautCote() end
			ancre.Visible = true
			ancre.Position = posCachee()
			glisser(posVisible(), if format == "cote" then ENTREE_COTE else ENTREE_HAUT)
			effetsEntree(true)
		else
			glisser(posCachee(), SORTIE, function()
				if not visible then ancre.Visible = false end
			end)
		end
	end
	-- le joueur change de lieu pendant l'annonce : la carte sort par son bord et revient dans l'autre format
	local function basculer(nouveau: string)
		enBascule = true
		glisser(posCachee(), SORTIE, function()
			enBascule = false
			if not visible then
				ancre.Visible = false
				return
			end
			disposer(nouveau)
			majEchelle()
			if format == "cote" then yCote = hautCote() end
			ancre.Position = posCachee()
			glisser(posVisible(), if format == "cote" then ENTREE_COTE else ENTREE_HAUT)
			effetsEntree(false)
		end)
	end

	local function rejoindre()
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
	end
	local function ignorer()
		local debut = dossier:GetAttribute("DebutBoss")
		ignoreDebut = if type(debut) == "number" then debut else -1
		Outils.jouer("clic", 0.9)
		montrer(false)
	end
	bRejoindre.Activated:Connect(rejoindre)
	bIgnorer.Activated:Connect(ignorer)
	-- raccourcis clavier / manette, seulement quand la carte est affichée (et pas en tapant dans le chat)
	UserInputService.InputBegan:Connect(function(input, traite)
		if traite or not visible then return end
		if table.find(TOUCHES_REJOINDRE, input.KeyCode) then
			UI.pop(bRejoindre, 0.9)
			rejoindre()
		elseif table.find(TOUCHES_IGNORER, input.KeyCode) then
			ignorer()
		end
	end)

	-- ================= Animation (chaque image, seulement carte affichée) =================
	local dernierSecondes = -1
	local prochaineBraise = 0
	local prochainReflet = os.clock() + 2.5
	local prochainLieu = 0
	RunService.RenderStepped:Connect(function()
		local r = reste()
		local debut = dossier:GetAttribute("DebutBoss")
		local doit = dossier:GetAttribute("Etat") == "Attente" and r > 0 and r <= Config.ANNONCE
			and not ctx.etat.cinematique and joueur:GetAttribute("DansArene") ~= true and not dansLeCercle()
			and not (ignoreDebut ~= nil and ignoreDebut == debut)
		montrer(doit)
		if not ancre.Visible then return end

		local t = os.clock()
		-- taille adaptée à l'écran (téléphone) ; lieu et créneau libre réévalués 2 fois par seconde
		majEchelle()
		if visible and not enBascule and t >= prochainLieu then
			prochainLieu = t + 0.5
			local voulu = lieu()
			if voulu ~= format then
				basculer(voulu)
			elseif format == "cote" then
				local y = hautCote()
				if math.abs(y - yCote) > 6 then
					yCote = y
					glisser(posVisible(), TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
				end
			end
		end

		local urgent = r <= 10
		local souffle = 0.5 + 0.5 * math.sin(t * 3)
		local eclat = math.max(0, 1 - (t - debutEntree) / 0.9) -- 1 à l'entrée, puis s'éteint

		-- ===== compte à rebours =====
		local txt = Config.minutes(math.max(0, r))
		if chrono.Text ~= txt then chrono.Text = txt end
		chrono.TextColor3 = if urgent then T.Rouge:Lerp(BLANC, 0.15) else T.Parchemin
		local s = math.ceil(r)
		if s ~= dernierSecondes then
			dernierSecondes = s
			-- chaque seconde, les chiffres tombent en place
			chrono.Position = UDim2.new(0.5, 0, 0.42, -8)
			chrono.TextTransparency = 0.5
			TweenService:Create(chrono, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0.42, 0), TextTransparency = 0}):Play()
			if urgent and s > 0 then
				echelleChrono.Scale = if s <= 3 then 1.5 else 1.3
				TweenService:Create(echelleChrono, UI.BOUNCY, {Scale = 1}):Play()
				UI.secouer(carte, if s <= 3 then 4 else 3)
			end
		end
		if urgent then
			traitPlaque.Color = T.Rouge:Lerp(BLANC, 0.3 * souffle)
			traitPlaque.Thickness = 2 + 1.5 * (0.5 + 0.5 * math.sin(t * 12))
			lueurPlaque.BackgroundColor3 = T.Rouge
			lueurPlaque.BackgroundTransparency = 0.25 + 0.25 * (0.5 + 0.5 * math.sin(t * 12))
			etiquetteChrono.TextColor3 = T.Rouge:Lerp(BLANC, 0.4)
		else
			traitPlaque.Color = couleur:Lerp(BLANC, 0.35 * souffle)
			traitPlaque.Thickness = 2
			lueurPlaque.BackgroundColor3 = couleur
			lueurPlaque.BackgroundTransparency = 0.45 + 0.2 * souffle
			etiquetteChrono.TextColor3 = T.Gris
		end
		barre.Size = UDim2.fromScale(math.clamp(r / Config.ANNONCE, 0, 1), 1)

		-- ===== nom révélé lettre par lettre à l'entrée =====
		local lettres = math.floor((t - debutEntree) * 32)
		local total = utf8.len(nom.Text) or 0
		local visibles = if lettres < total then math.max(0, lettres) else -1
		if nom.MaxVisibleGraphemes ~= visibles then nom.MaxVisibleGraphemes = visibles end

		-- ===== bord qui tourne, rayures qui défilent, point d'alerte qui bat =====
		degradeBord.Rotation = (t * 90) % 360
		local decalageRayures = (t * 18) % 32
		for k, ray in listeRayures do
			ray.Position = UDim2.new(0, (k - 1) * 32 - 60 + decalageRayures, 0.5, 0)
		end
		pointAlerte.BackgroundTransparency = 0.5 - 0.5 * math.sin(t * 6)
		-- la caméra du logo se balance doucement autour de la tête du boss
		if cadrage then
			local angle = math.sin(t * 0.7) * 0.35
			local avant = CFrame.Angles(0, angle, 0):VectorToWorldSpace(cadrage.avant)
			camLogo.CFrame = CFrame.lookAt(cadrage.haut + avant * cadrage.distance + Vector3.new(0, cadrage.montee, 0), cadrage.haut)
		end

		-- ===== emblème : flotte, rayons qui tournent, anneau qui respire =====
		emb.Position = UDim2.fromOffset(embBase.X, embBase.Y + math.sin(t * 1.6) * 2)
		rayons.Rotation = (t * 25) % 360
		anneau.Size = UDim2.fromOffset(92 + souffle * 4, 92 + souffle * 4)
		for i, ray in listeRayons do
			ray.BackgroundTransparency = 0.45 + 0.3 * (0.5 + 0.5 * math.sin(t * 2 + i)) - 0.3 * eclat
		end

		-- ===== lueur à la couleur du boss : respire, éclate à l'entrée, bat en rouge à la fin =====
		local battement = if urgent then 0.5 + 0.5 * math.sin(t * 12) else souffle
		for i, h in halos do
			local base = HALOS[i].base
			h.BackgroundColor3 = if urgent then couleur:Lerp(T.Rouge, 0.6 * battement) else couleur
			h.BackgroundTransparency = math.clamp(base + 0.08 * (1 - battement) - 0.45 * eclat, 0, 1)
		end

		-- ===== bord : blanc (dégradé), puis rouge qui bat pendant les 10 dernières secondes =====
		if urgent then
			bord.Color = T.Rouge:Lerp(BLANC, 0.25 * souffle)
			bord.Thickness = 3 + 1.5 * (0.5 + 0.5 * math.sin(t * 12))
		else
			bord.Color, bord.Thickness = BLANC, 3
		end

		-- ===== bouton Rejoindre : pulse doux + reflet ; grisé hors de la carte principale =====
		local possible = peutRejoindre()
		if not enTeleportation then
			local libelle = if possible then PREFIXES[peripherique].rejoindre .. "REJOINDRE LE PORTAIL" else "RETOURNE AU VILLAGE"
			if lRejoindre.Text ~= libelle then lRejoindre.Text = libelle end
		end
		bRejoindre.BackgroundTransparency = if possible then 0 else 0.55
		echelleRejoindre.Scale = if possible then 1 + 0.03 * math.sin(t * 4) else 1
		refletBouton.Position = UDim2.fromScale(((t * 0.8) % 1.8) - 0.4, 0.5)

		-- ===== reflet sur toute la carte de temps en temps, braises qui montent =====
		if t >= prochainReflet then
			prochainReflet = t + 3.2
			reflet.Position = UDim2.fromScale(-0.2, 0.5)
			TweenService:Create(reflet, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(1.2, 0.5)}):Play()
		end
		if t >= prochaineBraise then
			prochaineBraise = t + (if urgent then 0.06 else 0.14)
			local x = math.random()
			local taille = math.random(2, 4)
			local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 1, 4), Size = UDim2.fromOffset(taille, taille),
				Rotation = math.random(0, 90), BackgroundColor3 = if math.random() < 0.6 then couleur:Lerp(BLANC, 0.4) else T.Or,
				BorderSizePixel = 0, ZIndex = 42, Parent = carte})
			local duree = 1.4 + math.random() * 1.2
			TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(x + (math.random() - 0.5) * 0.08, 0, 0, -6), BackgroundTransparency = 1, Rotation = b.Rotation + 180}):Play()
			task.delay(duree + 0.05, function() b:Destroy() end)
		end
	end)

	return {}
end

return Annonce
