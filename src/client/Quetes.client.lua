--!strict
-- Guilde des Mineurs · INTERFACE (StarterPlayerScripts › Jeu)
-- 1. Le tableau de la Guilde chez Margot : histoire, quêtes du Pic Doré et contrats du jour.
-- 2. Le suivi des quêtes en cours à droite de l'écran (cliquer sur l'en-tête pour le replier).
-- 3. Les annonces (nouvelle quête, objectif rempli, quête terminée, nouveau rang) et le « ! » / « ? » au-dessus de Margot.
-- Le serveur (Quetes.server.lua) fait foi : ici on affiche et on demande, rien de plus.
-- Icônes : vrais modèles 3D (IconesObjets) ou logos dessinés en Frames (LogosGuilde) ; aucun emoji ni glyphe spécial.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Q = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Quetes"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local DecorTaverne = require(script.Parent:WaitForChild("DecorTaverne"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local Logos = require(script.Parent:WaitForChild("LogosGuilde"))
local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local evOuvrir = ReplicatedStorage:WaitForChild("QuetesOuvrir") :: RemoteEvent
local evMaj = ReplicatedStorage:WaitForChild("QuetesMaj") :: RemoteEvent
local action = ReplicatedStorage:WaitForChild("QuetesAction") :: RemoteFunction

local DISTANCE_FERMETURE = 18
local VIOLET = Color3.fromRGB(196, 120, 255)
local ENCRE = Color3.fromRGB(58, 36, 20)
local ENCRE_CLAIRE = Color3.fromRGB(110, 78, 48)
local CIRE = Color3.fromRGB(170, 34, 30)
local VERT_ENCRE = Color3.fromRGB(46, 126, 52)
local OR_PIC = Color3.fromRGB(255, 176, 60)
local BLANC = Color3.new(1, 1, 1)
local NOIR = Color3.new(0, 0, 0)

local COULEURS_STATUT: {[string]: Color3} = {
	dispo = VIOLET,
	active = T.Or,
	fini = T.Vert,
	rendue = Color3.fromRGB(120, 170, 110),
	faite = Color3.fromRGB(120, 170, 110),
	verrou = Color3.fromRGB(112, 100, 92),
}
local ETIQUETTES: {[string]: string} = {dispo = "NOUVELLE", active = "EN COURS", fini = "À RENDRE", rendue = "RENDU", faite = "ACCOMPLIE",
	verrou = "VERROUILLÉE"}
local ARMURES = {Casque = true, Plastron = true, Jambieres = true}

local etat: {[string]: any}? = nil
local onglet = "histoire"
local selection: {cible: string, i: number?} = {cible = "histoire"}

-- ================= Petits outils =================
local function boite(props: {[string]: any}): Frame
	props.BackgroundTransparency = 1
	props.SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeYY
	return creer("Frame", props)
end

local function chiffreRomain(n: number): string
	return ({"I", "II", "III", "IV", "V", "VI", "VII"})[n] or tostring(n)
end

local function duree(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%dh %02dmin", s // 3600, (s % 3600) // 60)
end

-- Avancement global d'une quête (0..1)
local function fraction(def: Q.Quete, prog: {any}?): number
	local fait, total = 0, 0
	for i, o in def.objectifs do
		fait += math.min(o.n, tonumber(prog and prog[i]) or 0)
		total += o.n
	end
	return fait / math.max(total, 1)
end

-- Logo dessiné du 1er objectif d'une quête
local function logoQuete(def: Q.Quete, parent: Instance): Frame
	local o = def.objectifs[1]
	local nom, couleur = Logos.objectif(if o then o.type else "", o and o.cible)
	return Logos.creer(nom, parent, couleur)
end

-- Barre de progression (fond d'encre, remplissage bombé, tête lumineuse quand elle avance)
-- renvoie maj(fraction, instantane?, couleur?)
local function barre(parent: Instance, props: {[string]: any}, couleur: Color3): (number, boolean?, Color3?) -> ()
	props.BackgroundColor3 = Color3.fromRGB(34, 22, 14)
	props.BackgroundTransparency = 0.12
	local fond = creer("Frame", props, {coin(0.5), trait(Color3.fromRGB(16, 10, 5), 1.5, 0.2)}) -- liseré : la barre vide reste visible
	local z = (props.ZIndex or 1) + 1
	local plein = creer("Frame", {Name = "Plein", Size = UDim2.fromScale(0, 1), BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = z,
		Parent = fond}, {coin(0.5), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, BLANC),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(232, 232, 232)), ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 135, 135))})})})
	creer("Frame", {Name = "Reflet", Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.3), BackgroundColor3 = BLANC,
		BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = z + 1, Parent = plein}, {coin(0.5)})
	local tete = creer("Frame", {Name = "Tete", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(2.2, 2.2),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = couleur:Lerp(BLANC, 0.65), BackgroundTransparency = 1,
		ZIndex = z + 2, Parent = plein}, {coin(0.5)})
	local actuel = -1
	return function(f: number, instantane: boolean?, nouvelle: Color3?)
		f = math.clamp(f, 0, 1)
		if nouvelle then
			TweenService:Create(plein, UI.FAST, {BackgroundColor3 = nouvelle}):Play()
		end
		if instantane or actuel < 0 then
			plein.Size = UDim2.fromScale(f, 1)
			if not instantane and f > 0 then
				-- premier affichage : se remplit depuis zéro
				plein.Size = UDim2.fromScale(0, 1)
				TweenService:Create(plein, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromScale(f, 1)}):Play()
			end
			actuel = f
			return
		end
		if f > actuel + 1e-3 then
			tete.BackgroundTransparency = 0.05
			TweenService:Create(tete, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
		end
		actuel = f
		TweenService:Create(plein, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromScale(f, 1)}):Play()
	end
end

-- Rayons de lumière qui tournent (derrière un sceau, un emblème)
local function rayons(parent: Instance, props: {[string]: any}, couleur: Color3): Frame
	props.BackgroundTransparency = 1
	local r = creer("Frame", props)
	for _, a in {0, 45, 90, 135} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.09), Rotation = a,
			BackgroundColor3 = couleur, BorderSizePixel = 0, ZIndex = r.ZIndex, Parent = r}, {coin(0.5),
			creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.25),
				NumberSequenceKeypoint.new(1, 1)})})})
	end
	return r
end

-- Anneau qui s'élargit (impact d'un sceau)
local function onde(parent: Instance, pos: UDim2, couleur: Color3, taille: number, z: number)
	local a = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(taille * 0.4, taille * 0.4),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = z, Parent = parent}, {coin(0.5), trait(couleur, 4)})
	local s = a:FindFirstChildOfClass("UIStroke") :: UIStroke
	local info = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(a, info, {Size = UDim2.fromScale(taille * 1.6, taille * 1.6)}):Play()
	TweenService:Create(s, info, {Transparency = 1, Thickness = 0.5}):Play()
	Debris:AddItem(a, 0.6)
end

-- ================= Fenêtre de la Guilde =================
local gui = creer("ScreenGui", {Name = "GuildeMargot", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = joueur:WaitForChild("PlayerGui")})

local F = UI.fenetre(gui, {nom = "Margot", role = "AUBERGISTE · GUILDE DES MINEURS", service = "Taverne", couleur = VIOLET,
	repliques = {"La Guilde paie bien ceux qui creusent profond.", "Une chope, une quête, et au travail !",
		"On raconte que la Veine d'Étoile brille dans le noir...", "Ton nom finira peut-être au-dessus du comptoir."}})
local boucles = F.boucles
-- Décor d'arrière-plan (taverne de la Guilde) : derrière le contenu, s'arrête fenêtre fermée
local decor = DecorTaverne.creer(F.contenu.Parent :: Frame, boucles)
local majBourse = UI.bourse(F.droite)
local message = UI.toast(gui)

-- ----- Colonne de gauche -----
local gauche = creer("Frame", {Name = "Gauche", Size = UDim2.fromScale(0.39, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu})

-- Plaque de rang : bois sombre riveté, emblème en losange, barre de renommée
local plaqueRang = UI.panneau({Name = "Rang", Size = UDim2.fromScale(1, 0.24), BackgroundColor3 = Color3.fromRGB(54, 36, 24), ZIndex = 3,
	Parent = gauche}, 0.12)
for _, p in {UDim2.fromScale(0.025, 0.15), UDim2.fromScale(0.975, 0.15), UDim2.fromScale(0.025, 0.85), UDim2.fromScale(0.975, 0.85)} do
	UI.rivet(plaqueRang, p, 0.07)
end
local socleRang = boite({AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.84, 0.84), ZIndex = 4,
	Parent = plaqueRang})
local rayonsRang = rayons(socleRang, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.5),
	ZIndex = 4, Parent = socleRang}, T.Or)
UI.boucle(rayonsRang, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
local embleme = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7),
	Rotation = 45, BackgroundColor3 = T.Or, ZIndex = 5, Parent = socleRang},
	{coin(0.18), trait(Color3.fromRGB(24, 14, 8), 2.5), UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(150, 100, 40), 45)})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), BackgroundTransparency = 1,
	ZIndex = 6, Parent = embleme}, {coin(0.18), trait(ENCRE, 1.5, 0.45)})
local halosRang = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.4, 1.4),
	BackgroundTransparency = 1, ZIndex = 4, Parent = embleme}, {coin(0.2), trait(T.Or, 2, 0.5)})
UI.boucle(halosRang, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
local chiffreRang = texte({Text = "I", Font = Enum.Font.Fantasy, TextColor3 = ENCRE, Rotation = -45, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), ZIndex = 7, Parent = embleme}, 40)
texte({Text = "RANG DE GUILDE", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.31, 0.1), Size = UDim2.fromScale(0.64, 0.14), ZIndex = 4, Parent = plaqueRang}, 14)
local nomRang = texte({Text = "Apprenti", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.31, 0.23), Size = UDim2.fromScale(0.64, 0.32), ZIndex = 4, Parent = plaqueRang}, 32)
UI.dore(nomRang, 2)
local majBarreRang = barre(plaqueRang, {Position = UDim2.fromScale(0.35, 0.61), Size = UDim2.fromScale(0.6, 0.11), ZIndex = 4, Parent = plaqueRang}, VIOLET)
local etoileRang = boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.34, 0.665), Size = UDim2.fromScale(0.3, 0.3), ZIndex = 6,
	Parent = plaqueRang})
Logos.creer("etoile", etoileRang, VIOLET)
local texteRenommee = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.31, 0.76), Size = UDim2.fromScale(0.65, 0.15), ZIndex = 4, Parent = plaqueRang}, 15)

-- Onglets (logo dessiné + libellé, soulignement doré sur l'onglet actif)
local barreOnglets = creer("Frame", {Position = UDim2.fromScale(0, 0.27), Size = UDim2.fromScale(1, 0.09), BackgroundTransparency = 1, ZIndex = 3,
	Parent = gauche})
local boutonsOnglets: {[string]: TextButton} = {}
local soulignes: {[string]: Frame} = {}
local pastilles: {[string]: Frame} = {}
for k, def in {{"histoire", "HISTOIRE", "livre"}, {"contrats", "CONTRATS", "parchemin"}, {"margot", "PIC DORÉ", "pioche"}} do
	local b = creer("TextButton", {Name = def[1], Text = "", AutoButtonColor = false, Position = UDim2.fromScale((k - 1) * 0.337, 0),
		Size = UDim2.fromScale(0.326, 1), BackgroundColor3 = T.Carte, ZIndex = 3, Parent = barreOnglets},
		{coin(0.25), trait(T.FerSombre, 2), UI.degrade(BLANC, Color3.fromRGB(150, 140, 135))})
	local ic = boite({AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.68, 0.68), ZIndex = 4, Parent = b})
	Logos.creer(def[3], ic, if def[1] == "margot" then OR_PIC else nil)
	texte({Text = def[2], Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.27, 0.22), Size = UDim2.fromScale(0.69, 0.56), ZIndex = 4,
		Parent = b}, 16)
	soulignes[def[1]] = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0, 0.09),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 5, Parent = b}, {coin(0.5)})
	local pastille = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.97, 0.12), Size = UDim2.fromScale(0.58, 0.58),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Rouge, Visible = false, ZIndex = 6, Parent = b},
		{coin(0.5), trait(Color3.fromRGB(40, 10, 6), 1.5), UI.degrade(BLANC, Color3.fromRGB(170, 150, 150))})
	Logos.creer("exclamation", boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7),
		ZIndex = 7, Parent = pastille}), BLANC)
	UI.boucle(UI.echelle(pastille), TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.18}, boucles)
	UI.reactif(b, 1.04)
	boutonsOnglets[def[1]] = b
	pastilles[def[1]] = pastille
end

-- Liste des quêtes
local liste = creer("ScrollingFrame", {Name = "Liste", Position = UDim2.fromScale(0, 0.39), Size = UDim2.fromScale(1, 0.61),
	BackgroundColor3 = Color3.fromRGB(28, 20, 16), BackgroundTransparency = 0.3, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = T.OrFonce, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 3, Parent = gauche}, {coin(0.04), trait(T.FerSombre, 2),
	creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
	creer("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12)})})

-- ----- Parchemin (droite) -----
local scene = creer("Frame", {Name = "Scene", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.59, 1),
	BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu})
local parchemin = creer("Frame", {Name = "Parchemin", Size = UDim2.fromScale(1, 0.84), BackgroundColor3 = T.Parchemin, ZIndex = 3, Parent = scene},
	{coin(0.035), trait(Color3.fromRGB(96, 64, 36), 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 230)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(246, 230, 196)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(214, 186, 140))})})})
-- Rouleaux en haut et en bas (avec embouts dorés)
for _, y in {0, 1} do
	local rouleau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(1.03, 0.045),
		BackgroundColor3 = Color3.fromRGB(150, 100, 56), ZIndex = 5, Parent = parchemin}, {coin(0.5), trait(Color3.fromRGB(70, 42, 20), 2),
		UI.degrade(Color3.fromRGB(255, 220, 170), Color3.fromRGB(120, 76, 40))})
	for _, x in {0, 1} do
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromScale(1.5, 1.5),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, ZIndex = 6, Parent = rouleau},
			{coin(0.5), trait(Color3.fromRGB(70, 42, 20), 2), UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(160, 100, 30), 45)})
	end
end
-- Taches d'usure du parchemin
local rngP = Random.new(7)
for _ = 1, 9 do
	local s = rngP:NextNumber(0.08, 0.2)
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rngP:NextNumber(0.05, 0.95), rngP:NextNumber(0.1, 0.9)),
		Size = UDim2.fromScale(s, s), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(160, 120, 70),
		BackgroundTransparency = rngP:NextNumber(0.88, 0.94), BorderSizePixel = 0, ZIndex = 3, Parent = parchemin}, {coin(0.5)})
end

-- Donneur de quête : portrait + nom
local medaillon = creer("Frame", {Position = UDim2.fromScale(0.04, 0.06), Size = UDim2.fromScale(0.17, 0.17), SizeConstraint = Enum.SizeConstraint.RelativeYY,
	BackgroundColor3 = Color3.fromRGB(60, 40, 28), ZIndex = 4, Parent = parchemin}, {coin(0.5), trait(T.Or, 2.5),
	UI.degrade(Color3.fromRGB(255, 200, 150), Color3.fromRGB(90, 60, 50))})
local vpDonneurs: {[string]: ViewportFrame} = {}
local initialeDonneur = texte({Font = Enum.Font.Fantasy, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = medaillon}, 40)
UI.dore(initialeDonneur)
local nomDonneur = texte({Font = Enum.Font.Fantasy, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.2, 0.075), Size = UDim2.fromScale(0.55, 0.075), ZIndex = 4, Parent = parchemin}, 24)
local roleDonneur = texte({Font = Enum.Font.GothamBold, TextColor3 = ENCRE_CLAIRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.2, 0.15), Size = UDim2.fromScale(0.5, 0.05), ZIndex = 4, Parent = parchemin}, 15)
-- Sceau de cire du donneur (dessiné, refait seulement quand le donneur change)
local sceau = boite({AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.96, 0.035), Size = UDim2.fromScale(0.19, 0.19), ZIndex = 4,
	Parent = parchemin})
local cleSceau = ""
local function poserSceau(couleur: Color3, interieur: string)
	local cle = couleur:ToHex() .. interieur
	if cle == cleSceau then
		return
	end
	cleSceau = cle
	sceau:ClearAllChildren()
	Logos.sceau(sceau, couleur, interieur)
	UI.pop(sceau, 1.5)
end

local chapitre = texte({Font = Enum.Font.GothamBlack, TextColor3 = ENCRE_CLAIRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.25), Size = UDim2.fromScale(0.75, 0.045), ZIndex = 4, Parent = parchemin}, 14)
local titre = texte({Font = Enum.Font.Fantasy, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.295), Size = UDim2.fromScale(0.9, 0.085), ZIndex = 4, Parent = parchemin}, 34)
-- Filet décoratif : deux traits d'encre et un losange
for _, x in {0.05, 0.53} do
	creer("Frame", {Position = UDim2.fromScale(x, 0.389), Size = UDim2.fromScale(0.42, 0.005), BackgroundColor3 = ENCRE_CLAIRE,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 4, Parent = parchemin}, {creer("UIGradient", {
		Transparency = NumberSequence.new(if x < 0.5 then 0.9 else 0, if x < 0.5 then 0 else 0.9)})})
end
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.391), Size = UDim2.fromScale(0.025, 0.025),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = CIRE, BorderSizePixel = 0, ZIndex = 5, Parent = parchemin},
	{trait(ENCRE, 1.2)})
local recit = texte({Font = Enum.Font.Merriweather, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Position = UDim2.fromScale(0.05, 0.41), Size = UDim2.fromScale(0.9, 0.2),
	ZIndex = 4, Parent = parchemin}, 18)

local zoneObjectifs = creer("Frame", {Name = "Objectifs", Position = UDim2.fromScale(0.05, 0.63), Size = UDim2.fromScale(0.9, 0.22),
	BackgroundTransparency = 1, ZIndex = 4, Parent = parchemin}, {creer("UIListLayout", {Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder})})

-- Récompenses : cartouches pièce dorée + étoile de renommée
local zoneRecompense = creer("Frame", {Position = UDim2.fromScale(0.05, 0.87), Size = UDim2.fromScale(0.9, 0.09), BackgroundTransparency = 1,
	ZIndex = 4, Parent = parchemin})
texte({Text = "RÉCOMPENSE", Font = Enum.Font.GothamBlack, TextColor3 = ENCRE_CLAIRE, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(0.19, 1), ZIndex = 4, Parent = zoneRecompense}, 14)
local function cartouche(x: number, couleur: Color3, logo: string): (Frame, TextLabel)
	local p = creer("Frame", {Position = UDim2.fromScale(x, 0.02), Size = UDim2.fromScale(0.27, 0.96), BackgroundColor3 = Color3.fromRGB(66, 42, 26),
		ZIndex = 4, Parent = zoneRecompense}, {coin(0.5), trait(couleur, 2), UI.degrade(Color3.fromRGB(255, 230, 200), Color3.fromRGB(140, 110, 90))})
	local ic = boite({AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(1.05, 1.05), ZIndex = 5, Parent = p})
	Logos.creer(logo, ic, couleur)
	local l = texte({Font = Enum.Font.GothamBlack, TextColor3 = couleur, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.3, 0.14), Size = UDim2.fromScale(0.66, 0.72), ZIndex = 5, Parent = p}, 22)
	creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(30, 16, 8), Transparency = 0.2, Parent = l})
	return p, l
end
local cartouchePieces, texteGainPieces = cartouche(0.2, T.Or, "piece")
local cartoucheRenommee, texteGainRenommee = cartouche(0.49, VIOLET, "etoile")

-- Tampon d'état (encre) : NOUVELLE / EN COURS / À RENDRE / RENDU
local tamponEtat = creer("Frame", {Name = "TamponEtat", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.885, 0.48),
	Size = UDim2.fromScale(0.23, 1.15), Rotation = -9, BackgroundColor3 = BLANC, BackgroundTransparency = 0.82, ZIndex = 6, Parent = zoneRecompense},
	{coin(0.2), trait(T.Vert, 2.5)})
local texteTampon = texte({Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.88, 0.62), ZIndex = 7, Parent = tamponEtat}, 20)
local etatTampon = ""
local function majTampon(txt: string, couleur: Color3)
	(tamponEtat:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = couleur
	texteTampon.TextColor3 = couleur
	texteTampon.Text = txt
	if txt ~= etatTampon then
		etatTampon = txt
		-- le tampon s'écrase sur le parchemin
		local e = UI.echelle(tamponEtat)
		e.Scale = 1.9
		tamponEtat.Rotation = -22
		TweenService:Create(e, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1}):Play()
		TweenService:Create(tamponEtat, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Rotation = -9}):Play()
	end
end

-- Boutons du bas
local principal = UI.boutonPrincipal({Name = "Principal", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(0.72, 0.13), ZIndex = 3, Parent = scene}, boucles)
local boutonAbandon = creer("TextButton", {Name = "Abandonner", Text = "ABANDONNER", Font = Enum.Font.GothamBlack, TextScaled = true,
	TextColor3 = T.Parchemin, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
	Size = UDim2.fromScale(0.26, 0.13), BackgroundColor3 = Color3.fromRGB(120, 44, 34), ZIndex = 3, Parent = scene},
	{coin(0.22), trait(Color3.fromRGB(24, 14, 8), 2.5), UI.degrade(BLANC, Color3.fromRGB(150, 140, 135)),
		creer("UIPadding", {PaddingTop = UDim.new(0.3, 0), PaddingBottom = UDim.new(0.3, 0), PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0)})})
UI.reactif(boutonAbandon, 1.05)
-- Sans « Abandonner », le bouton principal prend toute la largeur (plus de trou à droite)
boutonAbandon:GetPropertyChangedSignal("Visible"):Connect(function()
	principal.bouton.Size = UDim2.fromScale(if boutonAbandon.Visible then 0.72 else 1, 0.13)
end)
principal.bouton.Size = UDim2.fromScale(if boutonAbandon.Visible then 0.72 else 1, 0.13)

-- ================= Effets de la fenêtre =================
-- Grand sceau de cire qui s'abat sur le parchemin (accepter / rendre)
local function frapperSceau(couleur: Color3, interieur: string)
	local groupe = creer("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.72, 0.5), Size = UDim2.fromScale(0.36, 0.36),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, GroupTransparency = 1, Rotation = -30, ZIndex = 18, Parent = parchemin})
	Logos.sceau(groupe, couleur, interieur)
	local e = UI.echelle(groupe)
	e.Scale = 2.8
	local chute = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(e, chute, {Scale = 1}):Play()
	TweenService:Create(groupe, chute, {GroupTransparency = 0, Rotation = -8}):Play()
	task.delay(0.2, function()
		UI.jouer("metal", 0.75)
		UI.secouer(parchemin, 5)
		onde(parchemin, UDim2.fromScale(0.72, 0.5), couleur:Lerp(BLANC, 0.4), 0.5, 17)
		UI.gerbe(parchemin, couleur:Lerp(BLANC, 0.3), 12, Vector2.new(0.72, 0.5))
		e.Scale = 1.08
		TweenService:Create(e, UI.BOUNCY, {Scale = 1}):Play()
	end)
	task.delay(1.4, function()
		TweenService:Create(groupe, TweenInfo.new(0.45), {GroupTransparency = 1}):Play()
		Debris:AddItem(groupe, 0.5)
	end)
end

-- Pièces / étoiles qui s'envolent d'un élément vers un autre (récompense → bourse, → emblème de rang)
local function envolee(depuis: GuiObject, vers: GuiObject?, nom: string, couleur: Color3, n: number)
	if not vers then
		return
	end
	local origine = F.racine.AbsolutePosition
	local a = depuis.AbsolutePosition + depuis.AbsoluteSize / 2 - origine
	local b = vers.AbsolutePosition + vers.AbsoluteSize / 2 - origine
	local t = math.clamp(depuis.AbsoluteSize.Y * 0.75, 14, 34)
	for i = 1, n do
		local f = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(a.X, a.Y), Size = UDim2.fromOffset(t, t),
			BackgroundTransparency = 1, ZIndex = 50, Parent = F.racine})
		Logos.creer(nom, f, couleur)
		local ang = math.random() * math.pi * 2
		local r = t * (1 + math.random() * 1.6)
		TweenService:Create(f, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = UDim2.fromOffset(a.X + math.cos(ang) * r, a.Y + math.sin(ang) * r - t)}):Play()
		task.delay(0.3 + i * 0.06, function()
			local vol = TweenService:Create(f, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.fromOffset(b.X, b.Y), Size = UDim2.fromOffset(t * 0.55, t * 0.55)})
			vol.Completed:Connect(function()
				f:Destroy()
				UI.jouer("clic", 1.5 + i * 0.05)
				local e = UI.echelle(vers)
				e.Scale = 1.12
				TweenService:Create(e, UI.BOUNCY, {Scale = 1}):Play()
			end)
			vol:Play()
		end)
	end
end

-- ================= Remplissage =================
local function queteSelectionnee(): (Q.Quete?, {[string]: any}?)
	local e = etat
	if not e then
		return nil, nil
	end
	if selection.cible == "contrat" then
		local c = selection.i and e.contrats[selection.i]
		return c and c.def, c
	elseif selection.cible == "margot" then
		local m = e.margot
		return m and Q.MARGOT[m.index], m
	end
	return Q.histoire(e.h), nil
end

local function portraitDonneur(service: string)
	for s, vp in vpDonneurs do
		vp.Visible = s == service
	end
	if not vpDonneurs[service] then
		local vp = creer("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = medaillon}, {coin(0.5)})
		vpDonneurs[service] = vp
		UI.portrait(service, vp)
	end
	initialeDonneur.Visible = vpDonneurs[service]:FindFirstChild("Objet") == nil
end

-- Icône d'objectif sur le parchemin : vrai modèle 3D du jeu (minerai, pioche, armure), sinon logo dessiné
local function iconeObjectif(o: Q.Objectif, parent: Instance)
	local vp: ViewportFrame? = nil
	local cible = o.cible
	local ok = pcall(function()
		if cible and Q.MINERAIS[cible] and (o.type == "miner" or o.type == "livrer") then
			vp = Icones.minerai(cible, parent, {vitesse = 0.5, hauteur = 0.35, marge = 0.8})
		elseif cible and o.type == "pioche" then
			vp = Icones.pioche(cible, parent, {vitesse = 0.5, marge = 0.85})
		elseif cible and ARMURES[cible] and (o.type == "forger" or o.type == "equiper") then
			vp = Icones.armure(cible, parent, nil, {vitesse = 0.5, marge = 0.85})
		end
	end)
	local v = vp
	if ok and v and v:FindFirstChild("Objet") then
		v.ZIndex = 6
		return
	end
	if v then
		v:Destroy()
	end
	local nom, couleur = Logos.objectif(o.type, cible)
	Logos.creer(nom, boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), ZIndex = 6,
		Parent = parent}), couleur)
end

local dernierRecit = ""
local function remplirParchemin()
	local e = etat
	if not e then
		return
	end
	local def, suiviQuete = queteSelectionnee()
	local estPicDore = selection.cible == "margot"
	for _, enfant in zoneObjectifs:GetChildren() do
		if enfant:IsA("GuiObject") then
			enfant:Destroy()
		end
	end
	boutonAbandon.Visible = false
	if not def then
		-- Épilogue de la chaîne sélectionnée.
		dernierRecit = ""
		portraitDonneur("Taverne")
		nomDonneur.Text, roleDonneur.Text = "Margot", "Aubergiste · Guilde"
		initialeDonneur.Text = "M"
		poserSceau(Color3.fromRGB(200, 150, 40), "etoile")
		chapitre.Text = if estPicDore then "LE PIC DORÉ · ÉPILOGUE" else "LA VEINE D'ÉTOILE · ÉPILOGUE"
		titre.Text = if estPicDore then "À la table de Margot" else "Légende de la Guilde"
		recit.Text = if estPicDore then "Tu auras toujours une place à ma table. Passe te réchauffer quand tu remontes de la mine !"
			else "Ton nom est gravé au-dessus du comptoir. Les contrats du jour t'attendent toujours au tableau !"
		recit.MaxVisibleGraphemes = -1
		texteGainPieces.Text, texteGainRenommee.Text = "-", "-"
		majTampon("TERMINÉE", T.OrFonce)
		principal.definir(if estPicDore then "CHAÎNE TERMINÉE" else "HISTOIRE TERMINÉE", T.Or, false)
		return
	end
	local pnj = Q.PNJ[def.pnj]
	portraitDonneur(def.pnj)
	initialeDonneur.Text = pnj.nom:sub(1, 1)
	nomDonneur.Text, roleDonneur.Text = pnj.nom, pnj.role
	poserSceau(pnj.couleur:Lerp(Color3.fromRGB(120, 20, 20), 0.55), pnj.nom:sub(1, 1))
	if estPicDore then
		chapitre.Text = string.format("LE PIC DORÉ  -  QUÊTE %d / %d", e.margot.index, #Q.MARGOT)
	elseif suiviQuete then
		chapitre.Text = "CONTRAT DU JOUR · RENOUVELÉ DANS " .. string.upper(duree(e.reset))
	else
		chapitre.Text = string.format("CHAPITRE %s · %s  -  QUÊTE %d / %d", chiffreRomain(def.chapitre), string.upper(Q.CHAPITRES[def.chapitre] or ""),
			e.h, #Q.HISTOIRE)
	end
	titre.Text = def.titre
	if def.recit ~= dernierRecit then
		dernierRecit = def.recit
		recit.Text = "« " .. def.recit .. " »"
		local n = utf8.len(recit.Text) or 100
		recit.MaxVisibleGraphemes = 0
		TweenService:Create(recit, TweenInfo.new(math.min(n * 0.012, 2.2), Enum.EasingStyle.Linear), {MaxVisibleGraphemes = n}):Play()
	end

	local etatQuete = if suiviQuete then suiviQuete.etat else e.hEtat
	local prog = if suiviQuete then suiviQuete.prog else e.hProg
	local fini = if suiviQuete then suiviQuete.fini else e.hFini
	local hauteur = 1 / math.max(3, #def.objectifs) - 0.04
	for i, o in def.objectifs do
		local v = math.min(o.n, tonumber(prog[i]) or 0)
		local ok = etatQuete ~= "dispo" and v >= o.n
		local ligne = creer("Frame", {LayoutOrder = i, Size = UDim2.fromScale(1, hauteur), BackgroundTransparency = 1, ZIndex = 4, Parent = zoneObjectifs})
		-- Case à cocher (coche dessinée)
		local case = creer("Frame", {Size = UDim2.fromScale(0.72, 0.72), Position = UDim2.fromScale(0, 0.14), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = if ok then VERT_ENCRE else Color3.fromRGB(246, 234, 206), ZIndex = 4, Parent = ligne},
			{coin(0.22), trait(ENCRE, 2)})
		if ok then
			Logos.creer("coche", case, Color3.fromRGB(150, 240, 140))
		end
		-- Icône : disque d'encre + modèle 3D
		local zoneIcone = creer("Frame", {Position = UDim2.fromScale(0.065, -0.05), Size = UDim2.fromScale(1.1, 1.1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = ENCRE, BackgroundTransparency = 0.86, ZIndex = 5, Parent = ligne}, {coin(0.5), trait(ENCRE_CLAIRE, 1.2, 0.5)})
		iconeObjectif(o, zoneIcone)
		local lib = texte({Text = Q.texteObjectif(o), Font = Enum.Font.GothamBold, TextColor3 = if ok then VERT_ENCRE else ENCRE,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.15, 0), Size = UDim2.fromScale(0.5, 1), ZIndex = 4, Parent = ligne}, 18)
		if ok then
			creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(math.min(1, lib.TextBounds.X / math.max(lib.AbsoluteSize.X, 1)), 0, 0, 2),
				BackgroundColor3 = VERT_ENCRE, BorderSizePixel = 0, ZIndex = 5, Parent = lib})
		end
		if etatQuete ~= "dispo" then
			local maj = barre(ligne, {Position = UDim2.fromScale(0.67, 0.3), Size = UDim2.fromScale(0.2, 0.4), ZIndex = 4, Parent = ligne},
				if ok then T.Vert else T.Or)
			maj(v / o.n)
			texte({Text = string.format("%d/%d", v, o.n), Font = Enum.Font.GothamBlack, TextColor3 = if ok then VERT_ENCRE else ENCRE,
				TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.88, 0.15), Size = UDim2.fromScale(0.12, 0.7), ZIndex = 4, Parent = ligne}, 16)
		end
	end
	texteGainPieces.Text = UI.milliers(def.recompense.pieces)
	texteGainRenommee.Text = "+" .. def.recompense.renommee

	if etatQuete == "dispo" then
		majTampon("NOUVELLE", Color3.fromRGB(140, 70, 200))
		principal.definir("ACCEPTER LA QUÊTE", T.Or, true)
	elseif etatQuete == "rendue" then
		majTampon("RENDU", VERT_ENCRE)
		principal.definir("CONTRAT RENDU", T.Vert, false)
	elseif fini then
		majTampon("À RENDRE", VERT_ENCRE)
		principal.definir("RENDRE LA QUÊTE", T.Vert, true)
	else
		majTampon("EN COURS", T.OrFonce)
		-- Quête en cours : le bouton montre où on en est (au lieu d'un simple « EN COURS… »)
		local fait, total = 0, 0
		for i, o in def.objectifs do
			fait += math.min(o.n, tonumber(prog[i]) or 0)
			total += o.n
		end
		principal.definir(if #def.objectifs == 1 then string.format("EN COURS · %d / %d", fait, total)
			else string.format("EN COURS · %d %%", math.floor(fait / math.max(total, 1) * 100)), T.Or, false)
	end
	boutonAbandon.Visible = selection.cible == "contrat" and etatQuete == "active"
end

-- Carte d'une quête dans la liste : liseré du statut, médaillon avec l'icône du type, étiquette, progression, récompense
local function carte(ordre: number, def: Q.Quete?, statut: string, choisie: boolean, surClic: (() -> ())?, prog: {any}?)
	local verrouillee = statut == "verrou"
	local couleur = COULEURS_STATUT[statut] or COULEURS_STATUT.verrou
	local b = creer("TextButton", {Name = "Carte" .. ordre, LayoutOrder = ordre, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = if choisie then Color3.fromRGB(104, 76, 50) elseif verrouillee then Color3.fromRGB(32, 27, 25) else T.Carte,
		Selectable = surClic ~= nil and not verrouillee, ZIndex = 4, Parent = liste},
		{creer("UIAspectRatioConstraint", {AspectRatio = 5, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width}), coin(0.18), UI.degrade(BLANC, Color3.fromRGB(160, 150, 140))})
	UI.rarete(b, if choisie then T.Or else couleur, if choisie or statut == "fini" then 3 else 1)
	-- liseré de statut à gauche
	creer("Frame", {Position = UDim2.fromScale(0.012, 0.16), Size = UDim2.fromScale(0.012, 0.68), BackgroundColor3 = couleur, BorderSizePixel = 0,
		ZIndex = 5, Parent = b}, {coin(0.5)})
	-- médaillon
	local med = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5), Size = UDim2.fromScale(0.78, 0.78),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(26, 18, 13), ZIndex = 5, Parent = b},
		{coin(0.5), trait(couleur, 2), UI.degrade(Color3.fromRGB(255, 230, 200), Color3.fromRGB(110, 100, 90), 45)})
	local zoneLogo = boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.66, 0.66), ZIndex = 6,
		Parent = med})
	if verrouillee or not def then
		Logos.creer("cadenas", zoneLogo, Color3.fromRGB(120, 108, 96))
	elseif statut == "rendue" or statut == "faite" then
		Logos.creer("coche", zoneLogo)
	else
		logoQuete(def, zoneLogo)
	end
	texte({Text = if not def then "Quête verrouillée" else def.titre, Font = Enum.Font.Fantasy,
		TextColor3 = if verrouillee then T.Gris else T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.21, 0.1), Size = UDim2.fromScale(0.54, 0.46), ZIndex = 5, Parent = b}, 20)
	-- étiquette de statut
	local etiquette = creer("Frame", {Position = UDim2.fromScale(0.21, 0.6), Size = UDim2.fromScale(0.24, 0.28), BackgroundColor3 = couleur:Lerp(NOIR, 0.5),
		ZIndex = 5, Parent = b}, {coin(0.5), trait(couleur, 1.2)})
	texte({Text = ETIQUETTES[statut] or "", Font = Enum.Font.GothamBlack, TextColor3 = couleur:Lerp(BLANC, 0.35), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.72), ZIndex = 6, Parent = etiquette}, 12)
	-- progression (quête en cours / à rendre)
	if def and (statut == "active" or statut == "fini") then
		local maj = barre(b, {Position = UDim2.fromScale(0.47, 0.67), Size = UDim2.fromScale(0.27, 0.14), ZIndex = 5, Parent = b},
			if statut == "fini" then T.Vert else T.Or)
		maj(fraction(def, prog), true)
	end
	-- récompense
	if def then
		local zp = boite({AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.975, 0.32), Size = UDim2.fromScale(0.3, 0.3), ZIndex = 5, Parent = b})
		Logos.creer("piece", zp)
		texte({Text = UI.milliers(def.recompense.pieces), Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.75, 0.17), Size = UDim2.fromScale(0.155, 0.32), ZIndex = 5, Parent = b}, 15)
		local ze = boite({AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.975, 0.72), Size = UDim2.fromScale(0.28, 0.28), ZIndex = 5, Parent = b})
		Logos.creer("etoile", ze, VIOLET)
		texte({Text = "+" .. def.recompense.renommee, Font = Enum.Font.GothamBlack, TextColor3 = VIOLET, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.75, 0.59), Size = UDim2.fromScale(0.155, 0.27), ZIndex = 5, Parent = b}, 13)
	end
	-- quête à rendre / nouvelle : le médaillon palpite
	if statut == "fini" or statut == "dispo" then
		local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ZIndex = 5, Parent = med}, {coin(0.5), trait(couleur, 3, 0.1)})
		local s = halo:FindFirstChildOfClass("UIStroke") :: UIStroke
		TweenService:Create(halo, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Size = UDim2.fromScale(1.5, 1.5)}):Play()
		TweenService:Create(s, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Transparency = 1}):Play()
	end
	-- quête pas encore débloquée : visible mais assombrie, non cliquable
	if verrouillee then
		creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 6, 5), BackgroundTransparency = 0.42,
			ZIndex = 20, Parent = b}, {coin(0.18)})
	end
	if surClic and not verrouillee then
		UI.reactif(b, 1.03)
		b.MouseEnter:Connect(function()
			if not choisie then
				TweenService:Create(b, UI.FAST, {BackgroundColor3 = T.CarteClaire}):Play()
			end
		end)
		b.MouseLeave:Connect(function()
			if not choisie then
				TweenService:Create(b, UI.FAST, {BackgroundColor3 = T.Carte}):Play()
			end
		end)
		b.Activated:Connect(function()
			UI.jouer("clic")
			surClic()
		end)
	end
end

-- En-tête de section : texte centré entre deux filets dorés
local function entete(ordre: number, txt: string)
	local f = creer("Frame", {Name = "Entete" .. ordre, LayoutOrder = ordre, Size = UDim2.fromScale(1, 0), BackgroundTransparency = 1, ZIndex = 4,
		Parent = liste}, {creer("UIAspectRatioConstraint", {AspectRatio = 15, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width})})
	for _, x in {0, 1} do
		creer("Frame", {AnchorPoint = Vector2.new(x, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.new(0.1, 0, 0, 2), BackgroundColor3 = T.OrFonce,
			BorderSizePixel = 0, ZIndex = 4, Parent = f}, {creer("UIGradient", {Transparency = NumberSequence.new(if x == 0 then 1 else 0, if x == 0 then 0 else 1)})})
	end
	texte({Text = txt, Font = Enum.Font.GothamBlack, TextColor3 = T.Or, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.8), ZIndex = 4, Parent = f}, 14)
	return f
end

local remplirListe: () -> ()

-- Coffre de la Guilde (onglet Contrats)
local function carteCoffre(e: {[string]: any}, rendus: number)
	local pret = rendus >= Q.NB_CONTRATS
	local coffre = creer("Frame", {Name = "Coffre", LayoutOrder = 10, Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.fromRGB(70, 46, 26),
		ZIndex = 4, Parent = liste}, {creer("UIAspectRatioConstraint", {AspectRatio = 4.3, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width}), coin(0.16),
		UI.degrade(Color3.fromRGB(255, 230, 190), Color3.fromRGB(130, 100, 80))})
	if pret and not e.coffre then
		UI.rarete(coffre, T.Or, 4) -- un seul UIStroke par cadre : le liseré animé remplace le trait
	else
		trait(if e.coffre then T.FerSombre else T.Or, 2).Parent = coffre
	end
	local zc = boite({AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.03, 0.5), Size = UDim2.fromScale(0.74, 0.74), ZIndex = 5, Parent = coffre})
	Logos.creer("coffre", zc)
	texte({Text = "COFFRE DE LA GUILDE", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.24, 0.1), Size = UDim2.fromScale(0.72, 0.32), ZIndex = 5, Parent = coffre}, 20)
	texte({Text = if e.coffre then "Ouvert ! Reviens demain." else string.format("Rends les 3 contrats : %d / 3", rendus),
		Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.24, 0.44), Size = UDim2.fromScale(0.46, 0.22), ZIndex = 5, Parent = coffre}, 14)
	-- trois jetons : un par contrat rendu
	for k = 1, Q.NB_CONTRATS do
		local fait = k <= rendus or e.coffre
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.27 + (k - 1) * 0.07, 0.8), Size = UDim2.fromScale(0.15, 0.15),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = if fait then T.Or else Color3.fromRGB(40, 28, 20),
			ZIndex = 5, Parent = coffre}, {coin(0.15), trait(ENCRE, 1.2)})
	end
	if e.coffre then
		return
	end
	local b = creer("TextButton", {Text = if pret then "OUVRIR" else "+50 %", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = BLANC,
		AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.96, 0.64), Size = UDim2.fromScale(0.26, 0.44),
		BackgroundColor3 = if pret then T.Vert else T.Inactif, Selectable = pret, ZIndex = 6, Parent = coffre}, {coin(0.25), trait(ENCRE, 2),
		UI.degrade(BLANC, Color3.fromRGB(150, 150, 150)), creer("UIPadding", {PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0)})})
	if not pret then
		return
	end
	UI.reactif(b, 1.06)
	TweenService:Create(zc, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 6}):Play()
	b.Activated:Connect(function()
		local r = action:InvokeServer({action = "coffre"})
		if type(r) == "table" then
			message(r.message, r.ok)
			if r.ok then
				UI.celebrer(scene, T.Or, "COFFRE OUVERT !")
				envolee(zc, F.droite:FindFirstChild("Bourse") :: GuiObject?, "piece", T.Or, 10)
				if r.rangMonte then
					task.delay(1.2, function()
						local _, rang = Q.rang((r.etat or {}).renommee or 0)
						UI.celebrer(scene, rang.couleur, "NOUVEAU RANG !")
					end)
				end
			end
			if r.etat then
				etat = r.etat
				remplirListe()
			end
		end
	end)
end

remplirListe = function()
	local e = etat
	if not e then
		return
	end
	for _, enfant in liste:GetChildren() do
		if enfant:IsA("GuiObject") then
			enfant:Destroy()
		end
	end
	if onglet == "histoire" then
		local ordre = 0
		local chap = 0
		for i, def in Q.HISTOIRE do
			if def.chapitre ~= chap then
				chap = def.chapitre
				ordre += 1
				entete(ordre, string.format("CHAPITRE %s · %s", chiffreRomain(chap), string.upper(Q.CHAPITRES[chap])))
			end
			ordre += 1
			local statut = if i < e.h then "faite" elseif i > e.h then "verrou"
				elseif e.hEtat == "dispo" then "dispo" elseif e.hFini then "fini" else "active"
			carte(ordre, def, statut, i == e.h and selection.cible == "histoire", if i == e.h then function()
				selection = {cible = "histoire"}
				remplirListe()
				remplirParchemin()
			end else nil, if i == e.h then e.hProg else nil)
		end
		task.defer(function()
			-- Fait défiler jusqu'à la quête en cours
			local c = liste:FindFirstChild("Carte" .. tostring(e.h + math.min(4, (Q.HISTOIRE[e.h] or {chapitre = 4}).chapitre)))
			if c and c:IsA("GuiObject") then
				liste.CanvasPosition = Vector2.new(0, math.max(0, c.AbsolutePosition.Y - liste.AbsolutePosition.Y + liste.CanvasPosition.Y - 60))
			end
		end)
	elseif onglet == "margot" then
		local m = e.margot
		if m then
			entete(0, "LE PIC DORÉ · QUÊTES DE MARGOT")
			for i, def in Q.MARGOT do
				local statut = if i < m.index then "faite" elseif i > m.index then "verrou"
					elseif m.etat == "dispo" then "dispo" elseif m.fini then "fini" else "active"
				carte(i, def, statut, i == m.index, nil, if i == m.index then m.prog else nil)
			end
			local courante = liste:FindFirstChild("Carte" .. m.index)
			if courante and courante:IsA("GuiObject") then
				task.defer(function()
					if courante.Parent == liste then
						local haut = courante.AbsolutePosition.Y - liste.AbsolutePosition.Y
						liste.CanvasPosition = Vector2.new(0, math.max(0, haut + liste.CanvasPosition.Y - 60))
					end
				end)
			end
		end
	else
		entete(0, "RENOUVELÉS DANS " .. string.upper(duree(e.reset)))
		local rendus = 0
		for i, c in e.contrats do
			local statut = if c.etat == "dispo" then "dispo" elseif c.etat == "rendue" then "rendue" elseif c.fini then "fini" else "active"
			if c.etat == "rendue" then
				rendus += 1
			end
			carte(i, c.def, statut, selection.cible == "contrat" and selection.i == i, function()
				selection = {cible = "contrat", i = i}
				remplirListe()
				remplirParchemin()
			end, c.prog)
		end
		carteCoffre(e, rendus)
	end
	-- Pastilles « ! » sur les onglets
	pastilles.histoire.Visible = Q.histoire(e.h) ~= nil and (e.hEtat == "dispo" or e.hFini)
	local aFaire = false
	for _, c in e.contrats do
		if c.etat == "dispo" or (c.etat == "active" and c.fini) then
			aFaire = true
		end
	end
	pastilles.contrats.Visible = aFaire
	local m = e.margot
	pastilles.margot.Visible = m ~= nil and m.index <= #Q.MARGOT and (m.etat == "dispo" or m.fini)
	for nom, b in boutonsOnglets do
		local actif = nom == onglet
		TweenService:Create(b, UI.FAST, {BackgroundColor3 = if actif then Color3.fromRGB(150, 104, 60) else T.Carte}):Play()
		TweenService:Create(soulignes[nom], UI.BOUNCY, {Size = UDim2.fromScale(if actif then 0.8 else 0, 0.09)}):Play()
		local bord = b:FindFirstChildOfClass("UIStroke")
		if bord then
			bord.Color = if actif then T.Or else T.FerSombre
		end
	end
end

local function remplirRang()
	local e = etat
	if not e then
		return
	end
	local i, r, suivant = Q.rang(e.renommee)
	chiffreRang.Text = chiffreRomain(i)
	nomRang.Text = r.nom
	embleme.BackgroundColor3 = r.couleur
	if suivant then
		majBarreRang((e.renommee - r.renommee) / (suivant.renommee - r.renommee))
		texteRenommee.Text = string.format("%s / %s renommée  ·  vente +%d %%", UI.milliers(e.renommee), UI.milliers(suivant.renommee), r.bonus)
	else
		majBarreRang(1)
		texteRenommee.Text = string.format("%s renommée  ·  RANG MAXIMAL  ·  +%d %%", UI.milliers(e.renommee), r.bonus)
	end
end

local function toutRemplir()
	remplirRang()
	remplirListe()
	remplirParchemin()
end

for nom, b in boutonsOnglets do
	b.Activated:Connect(function()
		UI.jouer("clic")
		onglet = nom
		liste.CanvasPosition = Vector2.zero
		if nom == "histoire" then
			selection = {cible = "histoire"}
		elseif nom == "margot" then
			selection = {cible = "margot"}
		elseif selection.cible ~= "contrat" then
			selection = {cible = "contrat", i = 1}
		end
		toutRemplir()
	end)
end

-- Grande annonce de nouveau rang dans la fenêtre : emblème qui s'abat, rayons, nom doré
local function annonceRang(rangIndex: number)
	local r = Q.RANGS[rangIndex]
	if not r then
		return
	end
	local voile = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BackgroundTransparency = 1, ZIndex = 30,
		Parent = F.racine}, {coin(0.03)})
	TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.3}):Play()
	local socle = boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.33), Size = UDim2.fromScale(0.26, 0.26), ZIndex = 31,
		Parent = voile})
	local ray = rayons(socle, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(2.6, 2.6), ZIndex = 31,
		Parent = socle}, r.couleur)
	TweenService:Create(ray, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = 90}):Play()
	local losange = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72),
		Rotation = 45, BackgroundColor3 = r.couleur, ZIndex = 32, Parent = socle},
		{coin(0.18), trait(Color3.fromRGB(24, 14, 8), 3), UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(150, 100, 40), 45)})
	texte({Text = chiffreRomain(rangIndex), Font = Enum.Font.Fantasy, TextColor3 = ENCRE, Rotation = -45, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), ZIndex = 33, Parent = losange}, 80)
	local e = UI.echelle(socle)
	e.Scale = 3
	TweenService:Create(e, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1}):Play()
	task.delay(0.28, function()
		UI.jouer("metal", 0.7)
		UI.secouer(F.racine, 6)
		onde(voile, UDim2.fromScale(0.5, 0.33), r.couleur:Lerp(BLANC, 0.4), 0.5, 31)
	end)
	local l1 = texte({Text = "NOUVEAU RANG DE GUILDE", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.6, 0.06), ZIndex = 31, Parent = voile}, 26)
	local l2 = texte({Text = string.upper(r.nom), Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.67),
		Size = UDim2.fromScale(0.9, 0.15), ZIndex = 31, Parent = voile}, 80)
	UI.dore(l2, 3)
	local l3 = texte({Text = string.format("Bonus de vente chez Gaspard : +%d %%", r.bonus), Font = Enum.Font.GothamBlack, TextColor3 = r.couleur,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.6, 0.06), ZIndex = 31, Parent = voile}, 26)
	UI.pop(l2, 2)
	UI.celebrer(F.racine, r.couleur)
	UI.jouer("succes", 0.8)
	task.delay(2.8, function()
		for _, o in {l1, l2, l3} do
			TweenService:Create(o, UI.FAST, {TextTransparency = 1}):Play()
		end
		socle.Visible = false
		TweenService:Create(voile, UI.FAST, {BackgroundTransparency = 1}):Play()
		Debris:AddItem(voile, 0.3)
	end)
end

-- ================= Annonces à l'écran (bandeau + sceau qui se pose) =================
local annonces = creer("ScreenGui", {Name = "AnnoncesGuilde", ResetOnSpawn = false, DisplayOrder = 12, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})
local CACHE = UDim2.fromScale(0.5, -0.32)
local banniere = creer("Frame", {Name = "Banniere", AnchorPoint = Vector2.new(0.5, 0), Position = CACHE, Size = UDim2.fromScale(0.5, 0.13),
	BackgroundTransparency = 1, Visible = false, Active = false, Parent = annonces},
	{creer("UIAspectRatioConstraint", {AspectRatio = 5.2}), creer("UISizeConstraint", {MinSize = Vector2.new(320, 62), MaxSize = Vector2.new(620, 120)})})
local echBanniere = UI.echelle(banniere)
-- rayons derrière le sceau (quête terminée, rang)
local rayonsB = rayons(banniere, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.085, 0.5), Size = UDim2.fromScale(2.6, 2.6),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 1, Parent = banniere}, T.Or)
-- queues du ruban (pointes de chaque côté)
local queues: {Frame} = {}
for _, cote in {-1, 1} do
	local q = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + cote * 0.43, 0.6), Size = UDim2.fromScale(0.13, 0.56),
		BackgroundColor3 = CIRE, BorderSizePixel = 0, ZIndex = 2, Parent = banniere}, {trait(Color3.fromRGB(24, 12, 6), 2),
		UI.degrade(BLANC, Color3.fromRGB(150, 150, 150))})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(if cote < 0 then 0 else 1, 0.5), Size = UDim2.fromScale(0.71, 0.71),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 2, Parent = q},
		{UI.degrade(BLANC, Color3.fromRGB(150, 150, 150), -45)})
	table.insert(queues, q)
end
local plaqueB = creer("Frame", {Name = "Plaque", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.82),
	BackgroundColor3 = Color3.fromRGB(46, 30, 20), ZIndex = 3, Parent = banniere}, {coin(0.2), trait(T.Or, 2.5),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 210)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 180, 160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 100, 90))})})})
creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.975, 0.84), BackgroundTransparency = 1,
	ZIndex = 4, Parent = plaqueB}, {coin(0.2), trait(T.Or, 1, 0.55)})
for _, x in {0.985, 0.015} do
	UI.rivet(plaqueB, UDim2.fromScale(x, 0.5), 0.1)
end
-- reflet qui balaie la plaque (découpé aux coins arrondis)
local brillanceB = creer("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = plaqueB}, {coin(0.2)})
local traceB = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.2, 0.5), Size = UDim2.fromScale(0.1, 3), Rotation = 20,
	BackgroundColor3 = BLANC, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 5, Parent = brillanceB},
	{creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)})})})
local titreB = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.17, 0.08),
	Size = UDim2.fromScale(0.8, 0.45), ZIndex = 6, Parent = plaqueB}, 38)
UI.dore(titreB, 2)
local sousB = texte({Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.17, 0.53),
	Size = UDim2.fromScale(0.8, 0.24), ZIndex = 6, Parent = plaqueB}, 18)
local cadreBarreB = creer("Frame", {Position = UDim2.fromScale(0.17, 0.78), Size = UDim2.fromScale(0.8, 0.14), BackgroundTransparency = 1, ZIndex = 6,
	Parent = plaqueB})
local majBarreB = barre(cadreBarreB, {Size = UDim2.fromScale(0.8, 0.7), Position = UDim2.fromScale(0, 0.15), ZIndex = 6, Parent = cadreBarreB}, T.Or)
local compteB = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.82, -0.2),
	Size = UDim2.fromScale(0.18, 1.4), ZIndex = 6, Parent = cadreBarreB}, 16)
local sceauB = boite({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.085, 0.5), Size = UDim2.fromScale(1.14, 1.14), ZIndex = 8,
	Parent = banniere})
local echSceauB = UI.echelle(sceauB)
local tweenRayons: Tween? = nil

type Annonce = {titre: string, sous: string, genre: string, interieur: string, barre: {de: number, a: number, texte: string}?}
local GENRES: {[string]: {cire: Color3, rayons: boolean, duree: number}} = {
	objectif = {cire = Color3.fromRGB(176, 118, 36), rayons = false, duree = 2.4},
	fini = {cire = CIRE, rayons = true, duree = 3.4},
	nouvelle = {cire = Color3.fromRGB(120, 60, 170), rayons = false, duree = 3},
	info = {cire = Color3.fromRGB(60, 100, 150), rayons = false, duree = 2.6},
	rang = {cire = Color3.fromRGB(200, 146, 36), rayons = true, duree = 3.6},
}
local fileAnnonces: {Annonce} = {}
local annonceActive = false

local function suivante()
	if annonceActive or #fileAnnonces == 0 then
		return
	end
	annonceActive = true
	local a = table.remove(fileAnnonces, 1) :: Annonce
	local g = GENRES[a.genre] or GENRES.info
	titreB.Text, sousB.Text = a.titre, a.sous
	sousB.TextColor3 = T.Parchemin
	for _, q in queues do
		q.BackgroundColor3 = g.cire:Lerp(NOIR, 0.2)
		local pointe = q:FindFirstChildOfClass("Frame")
		if pointe then
			pointe.BackgroundColor3 = g.cire:Lerp(NOIR, 0.2)
		end
	end
	sceauB:ClearAllChildren()
	Logos.sceau(sceauB, g.cire, a.interieur)
	sceauB.Visible = false
	rayonsB.Visible = g.rayons
	cadreBarreB.Visible = a.barre ~= nil
	local barreA = a.barre
	if barreA then
		majBarreB(barreA.de, true, if barreA.a >= 1 then T.Vert else T.Or)
		compteB.Text = ""
	end
	-- le bandeau tombe du haut de l'écran
	titreB.TextTransparency, sousB.TextTransparency = 1, 1
	banniere.Visible = true
	banniere.Position = CACHE
	echBanniere.Scale = 0.9
	TweenService:Create(banniere, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.035)}):Play()
	TweenService:Create(echBanniere, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if g.rayons then
		rayonsB.Rotation = 0
		if tweenRayons then
			tweenRayons:Cancel()
		end
		tweenRayons = TweenService:Create(rayonsB, TweenInfo.new(g.duree + 0.5, Enum.EasingStyle.Linear), {Rotation = 120})
		tweenRayons:Play()
	end
	task.delay(0.15, function()
		TweenService:Create(titreB, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		TweenService:Create(sousB, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	end)
	-- le sceau de cire s'abat sur le bandeau
	task.delay(0.28, function()
		sceauB.Visible = true
		sceauB.Rotation = -35
		echSceauB.Scale = 2.8
		local chute = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(echSceauB, chute, {Scale = 1}):Play()
		TweenService:Create(sceauB, chute, {Rotation = -8}):Play()
	end)
	task.delay(0.48, function()
		UI.jouer("metal", 0.8)
		if a.genre == "fini" or a.genre == "rang" then
			UI.jouer("succes", if a.genre == "rang" then 0.8 else 1)
		end
		UI.secouer(plaqueB, 5)
		onde(banniere, UDim2.fromScale(0.085, 0.5), g.cire:Lerp(BLANC, 0.45), 1.1, 9)
		UI.gerbe(banniere, g.cire:Lerp(BLANC, 0.35), if g.rayons then 14 else 8, Vector2.new(0.085, 0.5))
		echSceauB.Scale = 1.1
		TweenService:Create(echSceauB, UI.BOUNCY, {Scale = 1}):Play()
		traceB.Position = UDim2.fromScale(-0.2, 0.5)
		TweenService:Create(traceB, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(1.2, 0.5)}):Play()
		if barreA then
			majBarreB(barreA.a, false, if barreA.a >= 1 then T.Vert else nil)
			compteB.Text = barreA.texte
			UI.pop(compteB, 1.6)
		end
	end)
	task.delay(g.duree, function()
		TweenService:Create(banniere, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = CACHE}):Play()
		task.delay(0.32, function()
			banniere.Visible = false
			annonceActive = false
			suivante()
		end)
	end)
end
local function annoncer(a: Annonce)
	-- deux « objectif rempli » identiques à la suite : un seul bandeau
	local dernier = fileAnnonces[#fileAnnonces]
	if dernier and dernier.genre == a.genre and dernier.titre == a.titre and dernier.sous == a.sous then
		return
	end
	table.insert(fileAnnonces, a)
	suivante()
end

-- Retrouve la quête active qui contient un objectif (par son texte)
local function trouverObjectif(e: {[string]: any}, texteO: string): (Q.Quete?, Q.Objectif?)
	local candidats: {{any}} = {}
	local h = Q.histoire(e.h)
	if h and e.hEtat == "active" then
		table.insert(candidats, {h})
	end
	local m = e.margot
	if m and m.etat == "active" and Q.MARGOT[m.index] then
		table.insert(candidats, {Q.MARGOT[m.index]})
	end
	for _, c in e.contrats do
		if c.etat == "active" then
			table.insert(candidats, {c.def})
		end
	end
	for _, cand in candidats do
		local def = cand[1] :: Q.Quete
		for _, o in def.objectifs do
			if Q.texteObjectif(o) == texteO then
				return def, o
			end
		end
	end
	return nil, nil
end

-- Avancement d'une quête par son titre dans un état (pour la barre de « quête terminée »)
local function fractionParTitre(e: {[string]: any}?, titreQ: string): number?
	if not e then
		return nil
	end
	local h = Q.histoire(e.h)
	if h and h.titre == titreQ then
		return fraction(h, e.hProg)
	end
	local m = e.margot
	local qm = m and Q.MARGOT[m.index]
	if qm and qm.titre == titreQ then
		return fraction(qm, m.prog)
	end
	for _, c in e.contrats do
		if c.def and c.def.titre == titreQ then
			return fraction(c.def, c.prog)
		end
	end
	return nil
end

-- Quête acceptée dans la fenêtre : annoncée quand on referme le tableau
local nouvelleEnAttente: Annonce? = nil

-- Bouton principal : accepter / rendre
local occupe = false
local pauseAffichage = 0 -- pendant la célébration, les mises à jour du serveur n'effacent pas la réplique de fin
principal.bouton.Activated:Connect(function()
	if occupe or not principal.bouton.Active then
		UI.secouer(principal.bouton, 5)
		return
	end
	local def, suiviQuete = queteSelectionnee()
	if not def then
		return
	end
	local e = etat :: {[string]: any}
	local etatQuete = if suiviQuete then suiviQuete.etat else e.hEtat
	local index = if selection.cible == "margot" then e.margot.index else selection.i
	local demande = {action = if etatQuete == "dispo" then "accepter" else "rendre", cible = selection.cible, i = index}
	occupe = true
	UI.jouer("metal")
	local ok, r = pcall(function()
		return action:InvokeServer(demande)
	end)
	occupe = false
	if not ok then
		message("Impossible de joindre la Guilde. Réessaie dans un instant.", false)
		return
	end
	if type(r) ~= "table" then
		return
	end
	message(r.message, r.ok)
	if r.etat then
		etat = r.etat
	end
	if not r.ok then
		UI.secouer(principal.bouton, 6)
		toutRemplir()
		return
	end
	if demande.action == "accepter" then
		local pnj = Q.PNJ[def.pnj]
		frapperSceau(if pnj then pnj.couleur:Lerp(Color3.fromRGB(120, 20, 20), 0.55) else CIRE, if pnj then pnj.nom:sub(1, 1) else "G")
		UI.gerbe(scene, VIOLET, 14, Vector2.new(0.36, 0.95))
		UI.jouer("succes", 1.2)
		local o = def.objectifs[1]
		nouvelleEnAttente = {titre = "NOUVELLE QUÊTE", sous = "« " .. def.titre .. " »" .. (if o then "  ·  " .. Q.texteObjectif(o) else ""),
			genre = "nouvelle", interieur = (Logos.objectif(if o then o.type else "", o and o.cible)),
			barre = {de = 0, a = 0, texte = "0 %"}}
		toutRemplir()
	else
		pauseAffichage = os.clock() + 2.4
		frapperSceau(CIRE, "coche")
		UI.celebrer(scene, T.Or, "QUÊTE ACCOMPLIE !")
		UI.jouer("succes")
		envolee(cartouchePieces, F.droite:FindFirstChild("Bourse") :: GuiObject?, "piece", T.Or, 8)
		task.delay(0.25, function()
			envolee(cartoucheRenommee, embleme, "etoile", VIOLET, 5)
		end)
		-- Réplique de fin du donneur sur le parchemin, puis la quête suivante
		dernierRecit = ""
		recit.Text = "« " .. tostring(r.fin or "Bien joué !") .. " »"
		recit.MaxVisibleGraphemes = -1
		majTampon("RENDU", VERT_ENCRE)
		principal.definir(string.format("+%s PIÈCES  ·  +%d RENOMMÉE", UI.milliers(r.pieces or 0), r.renommee or 0), T.Vert, false)
		task.delay(1, remplirRang)
		task.delay(2.4, function()
			if r.rangMonte then
				annonceRang(r.rang)
			end
			if F.estOuverte() then
				toutRemplir()
			end
		end)
	end
end)

boutonAbandon.Activated:Connect(function()
	if selection.cible ~= "contrat" then
		return
	end
	local r = action:InvokeServer({action = "abandonner", cible = "contrat", i = selection.i})
	if type(r) == "table" then
		message(r.message, r.ok)
		if r.etat then
			etat = r.etat
			toutRemplir()
		end
	end
end)

-- ================= Suivi à l'écran (coin droit) =================
-- Blocs gardés d'une mise à jour à l'autre : seule la progression bouge (pas de reconstruction complète).
local suivi = creer("ScreenGui", {Name = "SuiviQuetes", ResetOnSpawn = false, DisplayOrder = 4, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})
local panneauSuivi = creer("Frame", {Name = "Panneau", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0.28, 0), Size = UDim2.fromOffset(280, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(34, 24, 18), BackgroundTransparency = 0.1, Visible = false, Parent = suivi},
	{creer("UICorner", {CornerRadius = UDim.new(0, 10)}), trait(T.OrFonce, 2), UI.degrade(Color3.fromRGB(255, 240, 225), Color3.fromRGB(160, 140, 125)),
		creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		creer("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)}),
		creer("UIScale", {})})
local enteteSuivi = creer("TextButton", {Name = "Entete", LayoutOrder = 0, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1, Parent = panneauSuivi})
local sceauSuivi = creer("Frame", {Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Parent = enteteSuivi})
Logos.sceau(sceauSuivi, CIRE, "G")
local titreSuivi = texte({Text = "GUILDE DES MINEURS", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.new(0, 34, 0, 2), Size = UDim2.new(1, -86, 1, -4), Parent = enteteSuivi}, 20)
UI.dore(titreSuivi, 1.5)
local compteSuivi = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.fromOffset(22, 18),
	BackgroundColor3 = Color3.fromRGB(70, 46, 26), Parent = enteteSuivi}, {coin(0.5), trait(T.OrFonce, 1.5)})
local texteCompteSuivi = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.1),
	Parent = compteSuivi}, 13)
local flecheSuivi = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1, Parent = enteteSuivi})
Logos.creer("chevron", flecheSuivi, T.Or)
-- filet doré sous l'en-tête
creer("Frame", {Name = "Filet", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = panneauSuivi},
	{creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1)})})})
local corpsSuivi = creer("Frame", {Name = "Corps", LayoutOrder = 2, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Parent = panneauSuivi}, {creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
-- Invitation quand rien n'est en cours
local invite = creer("Frame", {Name = "Invite", LayoutOrder = 999, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Visible = false,
	Parent = corpsSuivi})
local logoInvite = creer("Frame", {Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Parent = invite})
Logos.creer("exclamation", logoInvite, T.Or)
texte({Text = "Une nouvelle quête t'attend chez Margot, à la taverne !", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
	TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -30, 1, 0), Parent = invite}, 14)
TweenService:Create(UI.echelle(logoInvite), TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.2}):Play()

local replie = false
enteteSuivi.Activated:Connect(function()
	replie = not replie
	corpsSuivi.Visible = not replie
	TweenService:Create(flecheSuivi, UI.BOUNCY, {Rotation = if replie then -90 else 0}):Play()
	UI.jouer("clic", 1.2)
end)

-- Échelle selon la taille de l'écran (téléphone)
local function ajusterSuivi()
	local cam = workspace.CurrentCamera
	local h = if cam then cam.ViewportSize.Y else 800
	(panneauSuivi:FindFirstChildOfClass("UIScale") :: UIScale).Scale = math.clamp(h / 900, 0.65, 1.1)
end
ajusterSuivi()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajusterSuivi)
end

type BlocSuivi = {cadre: Frame, maj: ({any}) -> ()}
local blocsSuivi: {[string]: BlocSuivi} = {}

local function creerBlocSuivi(def: Q.Quete, genre: string, fini: boolean): BlocSuivi
	local couleur = if fini then T.Vert elseif genre == "histoire" then T.Or elseif genre == "margot" then OR_PIC else T.Parchemin
	local cadre = creer("Frame", {Name = "Quete", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(16, 10, 7), BackgroundTransparency = 0.35, Parent = corpsSuivi},
		{creer("UICorner", {CornerRadius = UDim.new(0, 8)})})
	if not fini then
		trait(couleur, 1.5, 0.45).Parent = cadre
	end
	creer("Frame", {Name = "Accent", Position = UDim2.new(0, 4, 0, 7), Size = UDim2.new(0, 3, 1, -14), BackgroundColor3 = couleur, BorderSizePixel = 0,
		Parent = cadre}, {coin(0.5)})
	local interieur = creer("Frame", {Position = UDim2.fromOffset(13, 0), Size = UDim2.new(1, -19, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Parent = cadre}, {creer("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}),
		creer("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 6)})})
	-- titre + logo de la catégorie (livre = histoire, pioche dorée = Pic Doré, parchemin = contrat)
	local ligneTitre = creer("Frame", {LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = interieur})
	local lt = creer("Frame", {Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = ligneTitre})
	Logos.creer(if genre == "histoire" then "livre" elseif genre == "margot" then "pioche" else "parchemin", lt, if genre == "margot" then OR_PIC else nil)
	texte({Text = def.titre, Font = Enum.Font.GothamBlack, TextColor3 = couleur, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(21, 0), Size = UDim2.new(1, -21, 1, 0), Parent = ligneTitre}, 15)
	if fini then
		local l = creer("Frame", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = interieur})
		local c = creer("Frame", {Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = l})
		Logos.creer("coche", c)
		local t = texte({Text = "Retourne voir Margot à la taverne", Font = Enum.Font.GothamBold, TextColor3 = T.Vert,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(21, 1), Size = UDim2.new(1, -21, 1, -2), Parent = l}, 14)
		TweenService:Create(t, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.45}):Play()
		UI.rarete(cadre, T.Vert, 3)
		return {cadre = cadre, maj = function(_prog: {any}) end}
	end
	type Ligne = {o: Q.Objectif, ligne: Frame, case: Frame, coche: Frame, lib: TextLabel, cpt: TextLabel, flash: Frame,
		maj: (number, boolean?, Color3?) -> (), prec: number}
	local lignes: {Ligne} = {}
	for i, o in def.objectifs do
		local ligne = creer("Frame", {LayoutOrder = i, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Parent = interieur})
		local flash = creer("Frame", {Position = UDim2.fromOffset(-4, -1), Size = UDim2.new(1, 8, 1, 2), BackgroundColor3 = T.Or, BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = ligne}, {coin(0.3)})
		local case = creer("Frame", {Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(44, 30, 20),
			Parent = ligne}, {coin(0.25), trait(Color3.fromRGB(14, 8, 4), 1.2)})
		local coche = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = case})
		Logos.creer("coche", coche, Color3.fromRGB(150, 240, 140))
		local ic = creer("Frame", {Position = UDim2.fromOffset(18, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = ligne})
		local nomL, couleurL = Logos.objectif(o.type, o.cible)
		Logos.creer(nomL, ic, couleurL)
		local lib = texte({Text = Q.texteObjectif(o), Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -82, 0, 16), Parent = ligne}, 14)
		local cpt = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(44, 16), Parent = ligne}, 13)
		local maj = barre(ligne, {Position = UDim2.fromOffset(38, 19), Size = UDim2.new(1, -38, 0, 5), Parent = ligne}, T.Or)
		table.insert(lignes, {o = o, ligne = ligne, case = case, coche = coche, lib = lib, cpt = cpt, flash = flash, maj = maj, prec = -1})
	end
	local function majBloc(prog: {any})
		for i, L in lignes do
			local v = math.min(L.o.n, tonumber(prog[i]) or 0)
			if v == L.prec then
				continue
			end
			local ok = v >= L.o.n
			local premier = L.prec < 0
			if not premier and v > L.prec then
				-- la ligne s'illumine et un « +N » s'envole
				L.flash.BackgroundTransparency = 0.6
				TweenService:Create(L.flash, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
				local plus = texte({Text = "+" .. (v - L.prec), Font = Enum.Font.GothamBlack, TextColor3 = if ok then T.Vert else T.Or,
					TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 0),
					Size = UDim2.fromOffset(40, 16), Parent = L.ligne}, 15)
				creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 10, 4), Parent = plus})
				TweenService:Create(plus, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Position = UDim2.new(1, -46, 0, -14), TextTransparency = 1}):Play()
				Debris:AddItem(plus, 1)
				UI.pop(L.cpt, 1.4)
				if ok then
					UI.pop(L.case, 1.8)
				end
			end
			L.maj(v / L.o.n, premier, if ok then T.Vert else nil)
			L.cpt.Text = string.format("%d/%d", v, L.o.n)
			L.cpt.TextColor3 = if ok then T.Vert else T.Or
			L.coche.Visible = ok
			L.case.BackgroundColor3 = if ok then VERT_ENCRE else Color3.fromRGB(44, 30, 20)
			L.lib.TextColor3 = if ok then T.Vert else T.Parchemin
			L.prec = v
		end
	end
	return {cadre = cadre, maj = majBloc}
end

local function remplirSuivi()
	local e = etat
	if not e then
		return
	end
	local voulu: {{any}} = {}
	local h = Q.histoire(e.h)
	if h and e.hEtat == "active" then
		table.insert(voulu, {"h:" .. h.id .. (if e.hFini then ":f" else ""), h, e.hProg, e.hFini, "histoire"})
	end
	local m = e.margot
	local queteMargot = m and Q.MARGOT[m.index]
	if queteMargot and m.etat == "active" then
		table.insert(voulu, {"m:" .. queteMargot.id .. (if m.fini then ":f" else ""), queteMargot, m.prog, m.fini, "margot"})
	end
	for _, c in e.contrats do
		if c.etat == "active" then
			table.insert(voulu, {"c:" .. tostring(c.def.id) .. (if c.fini then ":f" else ""), c.def, c.prog, c.fini, "contrat"})
		end
	end
	local presents: {[string]: boolean} = {}
	for ordre, v in voulu do
		local cle = v[1] :: string
		presents[cle] = true
		local b = blocsSuivi[cle]
		if not b then
			b = creerBlocSuivi(v[2], v[5], v[4])
			blocsSuivi[cle] = b
			UI.pop(b.cadre, 0.7)
		end
		b.cadre.LayoutOrder = ordre
		b.maj(v[3] or {})
	end
	for cle, b in blocsSuivi do
		if not presents[cle] then
			b.cadre:Destroy()
			blocsSuivi[cle] = nil
		end
	end
	invite.Visible = #voulu == 0 and (h ~= nil or queteMargot ~= nil)
	local _, r = Q.rang(e.renommee)
	titreSuivi.Text = "GUILDE · " .. string.upper(r.nom)
	texteCompteSuivi.Text = tostring(#voulu)
	compteSuivi.Visible = #voulu > 0
	panneauSuivi.Visible = #voulu > 0 or invite.Visible
end

-- ================= « ! » / « ? » au-dessus de Margot =================
local marqueur: BillboardGui? = nil
local texteMarqueur: TextLabel? = nil
local halosMarqueur: Frame? = nil
local function majMarqueur()
	local e = etat
	if not (e and marqueur and texteMarqueur) then
		return
	end
	local aRendre = (e.hEtat == "active" and e.hFini)
	local nouveau = Q.histoire(e.h) ~= nil and e.hEtat == "dispo"
	local m = e.margot
	if m and m.index <= #Q.MARGOT then
		aRendre = aRendre or (m.etat == "active" and m.fini)
		nouveau = nouveau or m.etat == "dispo"
	end
	for _, c in e.contrats do
		if c.etat == "active" and c.fini then
			aRendre = true
		elseif c.etat == "dispo" then
			nouveau = true
		end
	end
	marqueur.Enabled = (aRendre or nouveau) and not F.estOuverte()
	texteMarqueur.Text = if aRendre then "?" else "!"
	texteMarqueur.TextColor3 = if aRendre then Color3.fromRGB(120, 255, 120) else T.Or
	if halosMarqueur then
		halosMarqueur.BackgroundColor3 = if aRendre then T.Vert else T.Or
	end
end

task.spawn(function()
	local part = workspace:WaitForChild("InteractionGuilde", 120)
	if not (part and part:IsA("BasePart")) then
		return
	end
	local bb = creer("BillboardGui", {Name = "MarqueurGuilde", Adornee = part, AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 140,
		Size = UDim2.fromScale(3, 3.6), StudsOffsetWorldSpace = Vector3.new(0, 6.2, 0), Enabled = false, Parent = suivi})
	-- halo lumineux derrière le signe
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8),
		SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = T.Or, BackgroundTransparency = 0.55, Parent = bb}, {coin(0.5),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1)})})})
	TweenService:Create(halo, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.85}):Play()
	local l = texte({Text = "!", Font = Enum.Font.Fantasy, TextColor3 = T.Or, Size = UDim2.fromScale(1, 1), Parent = bb}, 200)
	creer("UIStroke", {Thickness = 4, Color = Color3.fromRGB(40, 20, 6), Parent = l})
	marqueur, texteMarqueur, halosMarqueur = bb, l, halo
	TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{StudsOffsetWorldSpace = Vector3.new(0, 7, 0)}):Play()
	majMarqueur()
end)

-- ================= Réseau =================
local pointGuilde: BasePart? = nil
local promptGuilde: ProximityPrompt? = nil

evMaj.OnClientEvent:Connect(function(nouvelEtat: any, evenements: any)
	if type(nouvelEtat) ~= "table" or type(nouvelEtat.contrats) ~= "table" then
		return
	end
	local ancien = etat
	etat = nouvelEtat
	if ancien and Q.rang(nouvelEtat.renommee) > Q.rang(ancien.renommee) and not F.estOuverte() then
		local i, r = Q.rang(nouvelEtat.renommee)
		annoncer({titre = "NOUVEAU RANG : " .. string.upper(r.nom), sous = string.format("Bonus de vente chez Gaspard : +%d %%", r.bonus),
			genre = "rang", interieur = chiffreRomain(i)})
	end
	for _, ev in (if type(evenements) == "table" then evenements else {}) do
		if type(ev) ~= "table" then
			continue
		end
		if ev.type == "objectif" then
			local txt = tostring(ev.texte)
			local def, o = trouverObjectif(nouvelEtat, txt)
			annoncer({titre = "OBJECTIF ACCOMPLI", sous = if def then "« " .. def.titre .. " »  ·  " .. txt else txt, genre = "objectif",
				interieur = if o then (Logos.objectif(o.type, o.cible)) else "coche",
				barre = if o then {de = math.max(0, (o.n - 1) / o.n), a = 1, texte = string.format("%d/%d", o.n, o.n)} else nil})
		elseif ev.type == "fini" then
			local t = tostring(ev.titre)
			annoncer({titre = "QUÊTE TERMINÉE !", sous = "« " .. t .. " »  ·  Retourne voir Margot", genre = "fini", interieur = "coche",
				barre = {de = math.min(fractionParTitre(ancien, t) or 0.8, 0.95), a = 1, texte = "100 %"}})
		elseif ev.type == "info" then
			annoncer({titre = "GUILDE DES MINEURS", sous = tostring(ev.texte), genre = "info", interieur = "parchemin"})
		end
	end
	remplirSuivi()
	majMarqueur()
	if F.estOuverte() and not occupe and os.clock() >= pauseAffichage then
		remplirRang()
		remplirListe()
		remplirParchemin()
	end
end)

evOuvrir.OnClientEvent:Connect(function(nouvelEtat: any, part: any)
	if type(nouvelEtat) ~= "table" or type(nouvelEtat.contrats) ~= "table" or typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	etat = nouvelEtat
	pointGuilde = part
	promptGuilde = part:FindFirstChildOfClass("ProximityPrompt")
	if promptGuilde then
		promptGuilde.Enabled = false -- cache l'invite chez ce joueur tant que le tableau est ouvert
	end
	-- Rouvre le Pic Doré si le joueur y était ou si une de ses quêtes attend Margot.
	local e = nouvelEtat
	local m = e.margot
	local picDoreEnCours = m and m.index <= #Q.MARGOT and m.etat == "active"
	if m and (onglet == "margot" or (picDoreEnCours and m.fini)) then
		onglet, selection = "margot", {cible = "margot"}
	elseif Q.histoire(e.h) and (e.hEtat == "dispo" or e.hFini or e.hEtat == "active") then
		onglet, selection = "histoire", {cible = "histoire"}
	elseif m and m.index <= #Q.MARGOT then
		onglet, selection = "margot", {cible = "margot"}
	else
		onglet, selection = "contrats", {cible = "contrat", i = 1}
		for i, c in e.contrats do
			if c.etat ~= "rendue" then
				selection.i = i
				break
			end
		end
	end
	dernierRecit = ""
	etatTampon = ""
	toutRemplir()
	F.ouvrir()
	decor.demarrer()
	majMarqueur()
end)

F.surFermeture.Event:Connect(function()
	decor.arreter()
	-- réactivée un peu après (comme les autres invites coupées par InterfaceMine) : le E qui ferme ne rouvre pas
	task.delay(0.25, function()
		if promptGuilde and not F.estOuverte() then
			promptGuilde.Enabled = true
		end
	end)
	task.delay(0.2, majMarqueur)
	-- quête acceptée : grande annonce une fois le tableau refermé
	local a = nouvelleEnAttente
	if a then
		nouvelleEnAttente = nil
		task.delay(0.35, function()
			annoncer(a)
		end)
	end
end)

-- Fermeture au clavier / manette : touche d'interaction (E / X), gérée par InterfaceMine.fenetre

-- Pièces : bourse de la fenêtre
task.spawn(function()
	local stats = joueur:WaitForChild("leaderstats", 30)
	local v = stats and stats:WaitForChild("Pièces", 30)
	if v and v:IsA("IntValue") then
		majBourse(v.Value, true)
		v.Changed:Connect(function(n)
			majBourse(n)
		end)
	end
end)

-- On s'éloigne de Margot ou on meurt : le tableau se ferme ; le compte à rebours des contrats avance
task.spawn(function()
	local t = 0
	while true do
		task.wait(0.3)
		t += 0.3
		if F.estOuverte() then
			local perso = joueur.Character
			local racine = perso and perso:FindFirstChild("HumanoidRootPart")
			local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
			if not (racine and racine:IsA("BasePart") and humanoid and humanoid.Health > 0 and pointGuilde and pointGuilde.Parent)
				or (racine.Position - pointGuilde.Position).Magnitude > DISTANCE_FERMETURE then
				F.fermerFenetre()
			end
		end
		if t >= 60 and etat then
			t = 0
			etat.reset = math.max(0, (etat.reset or 0) - 60)
		end
	end
end)
