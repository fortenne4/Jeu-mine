--!strict
-- Guilde des Mineurs · INTERFACE (StarterPlayerScripts › Jeu)
-- 1. Le tableau de la Guilde chez Margot : rang, histoire « La Veine d'Étoile », contrats du jour, parchemin de quête.
-- 2. Le suivi des quêtes en cours à droite de l'écran (cliquer sur l'en-tête pour le replier).
-- 3. Les bannières (objectif rempli, quête terminée, nouveau rang) et le « ! » / « ? » au-dessus de Margot.
-- Le serveur (Quetes.server.lua) fait foi : ici on affiche et on demande, rien de plus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Q = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Quetes"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local DecorTaverne = require(script.Parent:WaitForChild("DecorTaverne"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local T, creer, coin, trait, texte = UI.T, UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local evOuvrir = ReplicatedStorage:WaitForChild("QuetesOuvrir") :: RemoteEvent
local evMaj = ReplicatedStorage:WaitForChild("QuetesMaj") :: RemoteEvent
local action = ReplicatedStorage:WaitForChild("QuetesAction") :: RemoteFunction

local DISTANCE_FERMETURE = 18
local VIOLET = Color3.fromRGB(196, 120, 255)
local ENCRE = Color3.fromRGB(58, 36, 20)
local ENCRE_CLAIRE = Color3.fromRGB(110, 78, 48)

local etat: {[string]: any}? = nil
local onglet = "histoire" -- ou "contrats"
local selection: {cible: string, i: number?} = {cible = "histoire"}

-- ================= Petits dessins =================
-- Icône d'objectif : gemme du minerai, ou symbole
local function iconeObjectif(o: Q.Objectif, parent: Instance, z: number): GuiObject
	local m = o.cible and Q.MINERAIS[o.cible]
	if m and (o.type == "miner" or o.type == "livrer") then
		local cadre = creer("Frame", {Size = UDim2.fromScale(1, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1,
			ZIndex = z, Parent = parent})
		-- Vrai minerai 3D du jeu (comme chez Gaspard et Brom) plutôt qu'un losange dessiné
		local vp = Icones.minerai(o.cible :: string, cadre, {vitesse = 0, hauteur = 0.35, marge = 0.8})
		vp.ZIndex = z
		return cadre
	end
	local symboles = {miner = "⛏", livrer = "▣", forger = "⚒", pioche = "⛏", wagon = "➜"}
	return texte({Text = symboles[o.type] or "•", Font = Enum.Font.GothamBlack, TextColor3 = ENCRE, Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = z, Parent = parent}, 22)
end

-- Barre de progression (fond d'encre, remplissage coloré) : renvoie la fonction de mise à jour
local function barre(parent: Instance, props: {[string]: any}, couleur: Color3): (number) -> ()
	props.BackgroundColor3 = Color3.fromRGB(40, 26, 16)
	props.BackgroundTransparency = 0.25
	local fond = creer("Frame", props, {coin(0.5), trait(Color3.fromRGB(20, 12, 6), 1.5, 0.3)}) -- liseré : la barre vide reste visible
	local plein = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = couleur, ZIndex = (props.ZIndex or 1) + 1, Parent = fond},
		{coin(0.5), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))})
	return function(f: number)
		TweenService:Create(plein, UI.DOUX, {Size = UDim2.fromScale(math.clamp(f, 0, 1), 1)}):Play()
	end
end

local function chiffreRomain(n: number): string
	return ({"I", "II", "III", "IV", "V", "VI", "VII"})[n] or tostring(n)
end

local function duree(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%dh %02dmin", s // 3600, (s % 3600) // 60)
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

-- Plaque de rang
local plaqueRang = UI.panneau({Name = "Rang", Size = UDim2.fromScale(1, 0.24), BackgroundColor3 = Color3.fromRGB(46, 34, 28), ZIndex = 3,
	Parent = gauche}, 0.12)
local embleme = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.62, 0.62),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = 45, BackgroundColor3 = T.Or, ZIndex = 4, Parent = plaqueRang},
	{coin(0.18), trait(Color3.fromRGB(24, 14, 8), 2.5), UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(150, 100, 40), 45)})
local halosRang = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.5),
	BackgroundTransparency = 1, ZIndex = 3, Parent = embleme}, {coin(0.2), trait(T.Or, 2, 0.5)})
UI.boucle(halosRang, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
local chiffreRang = texte({Text = "I", Font = Enum.Font.Fantasy, TextColor3 = ENCRE, Rotation = -45, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), ZIndex = 5, Parent = embleme}, 40)
local titreRang = texte({Text = "RANG DE GUILDE", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.3, 0.1), Size = UDim2.fromScale(0.66, 0.15), ZIndex = 4, Parent = plaqueRang}, 14)
local nomRang = texte({Text = "Apprenti", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.3, 0.24), Size = UDim2.fromScale(0.66, 0.3), ZIndex = 4, Parent = plaqueRang}, 30)
UI.dore(nomRang, 2)
local majBarreRang = barre(plaqueRang, {Position = UDim2.fromScale(0.3, 0.6), Size = UDim2.fromScale(0.65, 0.11), ZIndex = 4, Parent = plaqueRang}, VIOLET)
local texteRenommee = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.3, 0.74), Size = UDim2.fromScale(0.66, 0.15), ZIndex = 4, Parent = plaqueRang}, 15)
local _ = titreRang

-- Onglets
local barreOnglets = creer("Frame", {Position = UDim2.fromScale(0, 0.27), Size = UDim2.fromScale(1, 0.09), BackgroundTransparency = 1, ZIndex = 3,
	Parent = gauche})
local boutonsOnglets: {[string]: TextButton} = {}
local pastilles: {[string]: Frame} = {}
for k, def in {{"histoire", "HISTOIRE"}, {"contrats", "CONTRATS DU JOUR"}} do
	local b = creer("TextButton", {Name = def[1], Text = "", AutoButtonColor = false, Position = UDim2.fromScale((k - 1) * 0.505, 0),
		Size = UDim2.fromScale(0.495, 1), BackgroundColor3 = T.Carte, ZIndex = 3, Parent = barreOnglets},
		{coin(0.25), trait(T.FerSombre, 2), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
	texte({Text = def[2], Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.06, 0.2), Size = UDim2.fromScale(0.88, 0.6), ZIndex = 4,
		Parent = b}, 17)
	local pastille = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.97, 0.12), Size = UDim2.fromScale(0.55, 0.55),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Rouge, Visible = false, ZIndex = 6, Parent = b},
		{coin(0.5), trait(Color3.fromRGB(40, 10, 6), 1.5)})
	texte({Text = "!", Font = Enum.Font.GothamBlack, Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = pastille}, 16)
	UI.reactif(b, 1.04)
	boutonsOnglets[def[1]] = b
	pastilles[def[1]] = pastille
end

-- Liste des quêtes
local liste = creer("ScrollingFrame", {Name = "Liste", Position = UDim2.fromScale(0, 0.39), Size = UDim2.fromScale(1, 0.61),
	BackgroundColor3 = Color3.fromRGB(30, 22, 18), BackgroundTransparency = 0.35, BorderSizePixel = 0, ScrollBarThickness = 5,
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
-- Rouleaux en haut et en bas
for _, y in {0, 1} do
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(1.03, 0.045),
		BackgroundColor3 = Color3.fromRGB(150, 100, 56), ZIndex = 5, Parent = parchemin}, {coin(0.5), trait(Color3.fromRGB(70, 42, 20), 2),
		UI.degrade(Color3.fromRGB(255, 220, 170), Color3.fromRGB(120, 76, 40))})
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
-- Sceau de cire
local sceau = creer("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.95, 0.05), Size = UDim2.fromScale(0.15, 0.15),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(150, 30, 30), ZIndex = 4, Parent = parchemin},
	{coin(0.5), trait(Color3.fromRGB(80, 10, 10), 2), UI.degrade(Color3.fromRGB(255, 160, 160), Color3.fromRGB(110, 40, 40), 45)})
local texteSceau = texte({Text = "G", Font = Enum.Font.Fantasy, TextColor3 = Color3.fromRGB(255, 220, 200), Size = UDim2.fromScale(1, 1),
	ZIndex = 5, Parent = sceau}, 30)

local chapitre = texte({Font = Enum.Font.GothamBlack, TextColor3 = ENCRE_CLAIRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.25), Size = UDim2.fromScale(0.9, 0.045), ZIndex = 4, Parent = parchemin}, 14)
local titre = texte({Font = Enum.Font.Fantasy, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.295), Size = UDim2.fromScale(0.9, 0.085), ZIndex = 4, Parent = parchemin}, 34)
creer("Frame", {Position = UDim2.fromScale(0.05, 0.39), Size = UDim2.fromScale(0.9, 0.004), BackgroundColor3 = ENCRE_CLAIRE,
	BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 4, Parent = parchemin})
local recit = texte({Font = Enum.Font.Merriweather, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Position = UDim2.fromScale(0.05, 0.41), Size = UDim2.fromScale(0.9, 0.2),
	ZIndex = 4, Parent = parchemin}, 18)

local zoneObjectifs = creer("Frame", {Name = "Objectifs", Position = UDim2.fromScale(0.05, 0.63), Size = UDim2.fromScale(0.9, 0.22),
	BackgroundTransparency = 1, ZIndex = 4, Parent = parchemin}, {creer("UIListLayout", {Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder})})

-- Récompenses
local zoneRecompense = creer("Frame", {Position = UDim2.fromScale(0.05, 0.87), Size = UDim2.fromScale(0.9, 0.09), BackgroundTransparency = 1,
	ZIndex = 4, Parent = parchemin})
texte({Text = "RÉCOMPENSE", Font = Enum.Font.GothamBlack, TextColor3 = ENCRE_CLAIRE, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(0.25, 1), ZIndex = 4, Parent = zoneRecompense}, 14)
local function pastilleRecompense(x: number, couleur: Color3, symbole: string): TextLabel
	local p = creer("Frame", {Position = UDim2.fromScale(x, 0.05), Size = UDim2.fromScale(0.34, 0.9), BackgroundColor3 = Color3.fromRGB(70, 46, 28),
		ZIndex = 4, Parent = zoneRecompense}, {coin(0.5), trait(couleur, 2)})
	local icone = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5), Size = UDim2.fromScale(0.8, 0.8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = couleur, ZIndex = 5, Parent = p}, {coin(0.5),
		UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(150, 120, 80), 45)})
	texte({Text = symbole, Font = Enum.Font.GothamBlack, TextColor3 = ENCRE, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = icone}, 18)
	return texte({Font = Enum.Font.GothamBlack, TextColor3 = couleur, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.32, 0.15), Size = UDim2.fromScale(0.64, 0.7), ZIndex = 5, Parent = p}, 22)
end
local texteGainPieces = pastilleRecompense(0.26, T.Or, "◉")
local texteGainRenommee = pastilleRecompense(0.64, VIOLET, "★")

-- Boutons du bas
local principal = UI.boutonPrincipal({Name = "Principal", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(0.72, 0.13), ZIndex = 3, Parent = scene}, boucles)
local boutonAbandon = creer("TextButton", {Name = "Abandonner", Text = "ABANDONNER", Font = Enum.Font.GothamBlack, TextScaled = true,
	TextColor3 = T.Parchemin, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
	Size = UDim2.fromScale(0.26, 0.13), BackgroundColor3 = Color3.fromRGB(120, 44, 34), ZIndex = 3, Parent = scene},
	{coin(0.22), trait(Color3.fromRGB(24, 14, 8), 2.5), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135)),
		creer("UIPadding", {PaddingTop = UDim.new(0.3, 0), PaddingBottom = UDim.new(0.3, 0), PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0)})})
UI.reactif(boutonAbandon, 1.05)
-- Sans « Abandonner », le bouton principal prend toute la largeur (plus de trou à droite)
boutonAbandon:GetPropertyChangedSignal("Visible"):Connect(function()
	principal.bouton.Size = UDim2.fromScale(if boutonAbandon.Visible then 0.72 else 1, 0.13)
end)
principal.bouton.Size = UDim2.fromScale(if boutonAbandon.Visible then 0.72 else 1, 0.13)

-- ================= Remplissage =================
local function queteSelectionnee(): (Q.Quete?, {[string]: any}?)
	local e = etat
	if not e then
		return nil, nil
	end
	if selection.cible == "contrat" then
		local c = selection.i and e.contrats[selection.i]
		return c and c.def, c
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

local dernierRecit = ""
local function remplirParchemin()
	local e = etat
	if not e then
		return
	end
	local def, contrat = queteSelectionnee()
	for _, enfant in zoneObjectifs:GetChildren() do
		if enfant:IsA("GuiObject") then
			enfant:Destroy()
		end
	end
	boutonAbandon.Visible = false
	if not def then
		-- Histoire terminée
		portraitDonneur("Taverne")
		nomDonneur.Text, roleDonneur.Text = "Margot", "Aubergiste · Guilde"
		initialeDonneur.Text = "M"
		chapitre.Text = "LA VEINE D'ÉTOILE · ÉPILOGUE"
		titre.Text = "Légende de la Guilde"
		recit.Text = "Ton nom est gravé au-dessus du comptoir. Les contrats du jour t'attendent toujours au tableau !"
		recit.MaxVisibleGraphemes = -1
		texteGainPieces.Text, texteGainRenommee.Text = "—", "—"
		principal.definir("HISTOIRE TERMINÉE", T.Or, false)
		return
	end
	local pnj = Q.PNJ[def.pnj]
	portraitDonneur(def.pnj)
	initialeDonneur.Text = pnj.nom:sub(1, 1)
	nomDonneur.Text, roleDonneur.Text = pnj.nom, pnj.role
	sceau.BackgroundColor3 = pnj.couleur:Lerp(Color3.fromRGB(120, 20, 20), 0.55)
	texteSceau.Text = pnj.nom:sub(1, 1)
	if contrat then
		chapitre.Text = "CONTRAT DU JOUR · RENOUVELÉ DANS " .. string.upper(duree(e.reset))
	else
		chapitre.Text = string.format("CHAPITRE %s · %s  —  QUÊTE %d / %d", chiffreRomain(def.chapitre), string.upper(Q.CHAPITRES[def.chapitre] or ""),
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

	local etatQuete = if contrat then contrat.etat else e.hEtat
	local prog = if contrat then contrat.prog else e.hProg
	local fini = if contrat then contrat.fini else e.hFini
	local hauteur = 1 / math.max(3, #def.objectifs) - 0.04
	for i, o in def.objectifs do
		local v = math.min(o.n, tonumber(prog[i]) or 0)
		local ok = etatQuete ~= "dispo" and v >= o.n
		local ligne = creer("Frame", {LayoutOrder = i, Size = UDim2.fromScale(1, hauteur), BackgroundTransparency = 1, ZIndex = 4, Parent = zoneObjectifs})
		local case = creer("Frame", {Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0, 0.1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = if ok then Color3.fromRGB(70, 150, 60) else Color3.fromRGB(240, 226, 196), ZIndex = 4, Parent = ligne},
			{coin(0.2), trait(ENCRE, 2)})
		if ok then
			texte({Text = "✔", Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = case}, 20)
		end
		local zoneIcone = creer("Frame", {Position = UDim2.fromScale(0.06, 0), Size = UDim2.fromScale(1, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1, ZIndex = 4, Parent = ligne})
		iconeObjectif(o, zoneIcone, 5)
		local lib = texte({Text = Q.texteObjectif(o), Font = Enum.Font.GothamBold, TextColor3 = if ok then Color3.fromRGB(60, 120, 50) else ENCRE,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.13, 0), Size = UDim2.fromScale(0.52, 1), ZIndex = 4, Parent = ligne}, 18)
		if ok then
			creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(math.min(1, lib.TextBounds.X / math.max(lib.AbsoluteSize.X, 1)), 0, 0, 2),
				BackgroundColor3 = Color3.fromRGB(60, 120, 50), BorderSizePixel = 0, ZIndex = 5, Parent = lib})
		end
		if etatQuete ~= "dispo" then
			local maj = barre(ligne, {Position = UDim2.fromScale(0.67, 0.3), Size = UDim2.fromScale(0.2, 0.4), ZIndex = 4, Parent = ligne},
				if ok then T.Vert else T.Or)
			maj(v / o.n)
			texte({Text = string.format("%d/%d", v, o.n), Font = Enum.Font.GothamBlack, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.fromScale(0.88, 0.15), Size = UDim2.fromScale(0.12, 0.7), ZIndex = 4, Parent = ligne}, 16)
		end
	end
	texteGainPieces.Text = UI.milliers(def.recompense.pieces)
	texteGainRenommee.Text = "+" .. def.recompense.renommee

	if etatQuete == "dispo" then
		principal.definir("ACCEPTER LA QUÊTE", T.Or, true)
	elseif etatQuete == "rendue" then
		principal.definir("CONTRAT RENDU", T.Vert, false)
	elseif fini then
		principal.definir("RENDRE LA QUÊTE", T.Vert, true)
	else
		-- Quête en cours : le bouton montre où on en est (au lieu d'un simple « EN COURS… »)
		local fait, total = 0, 0
		for i, o in def.objectifs do
			fait += math.min(o.n, tonumber(prog[i]) or 0)
			total += o.n
		end
		principal.definir(if #def.objectifs == 1 then string.format("EN COURS · %d / %d", fait, total)
			else string.format("EN COURS · %d %%", math.floor(fait / math.max(total, 1) * 100)), T.Or, false)
	end
	boutonAbandon.Visible = contrat ~= nil and etatQuete == "active"
end

-- Carte d'une quête dans la liste
local function carte(ordre: number, def: Q.Quete?, statut: string, choisie: boolean, surClic: (() -> ())?)
	local verrouillee = statut == "verrou"
	local b = creer("TextButton", {Name = "Carte" .. ordre, LayoutOrder = ordre, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = if choisie then Color3.fromRGB(96, 70, 48) elseif verrouillee then Color3.fromRGB(34, 28, 26) else T.Carte, ZIndex = 4,
		Parent = liste}, {coin(0.16), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(160, 150, 140))})
	local couleur = if statut == "fini" then T.Vert elseif statut == "active" then T.Or elseif statut == "dispo" then VIOLET
		elseif statut == "rendue" then Color3.fromRGB(110, 150, 100) elseif statut == "faite" then Color3.fromRGB(120, 170, 110)
		else Color3.fromRGB(112, 100, 92) -- verrouillée : gris lisible (le fer sombre disparaissait sur la carte)
	UI.rarete(b, if choisie then T.Or else couleur, if choisie then 3 else 1)
	local pnj = def and Q.PNJ[def.pnj]
	local pastille = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.03, 0.5), Size = UDim2.fromScale(0.72, 0.72),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = if verrouillee or not pnj then Color3.fromRGB(20, 16, 14) else pnj.couleur,
		ZIndex = 5, Parent = b}, {coin(0.5), trait(ENCRE, 2), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(110, 100, 90), 45)})
	texte({Text = if verrouillee or not pnj then "?" elseif statut == "rendue" or statut == "faite" then "✔" else pnj.nom:sub(1, 1),
		Font = Enum.Font.Fantasy, TextColor3 = if verrouillee then T.Gris else ENCRE, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = pastille}, 24)
	texte({Text = if verrouillee or not def then "???" else def.titre, Font = Enum.Font.Fantasy, TextColor3 = if verrouillee then T.Gris else T.Parchemin,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.2, 0.12), Size = UDim2.fromScale(0.62, 0.44), ZIndex = 5, Parent = b}, 20)
	local etiquettes = {dispo = "NOUVELLE", active = "EN COURS", fini = "À RENDRE !", rendue = "RENDU", faite = "ACCOMPLIE", verrou = "VERROUILLÉE"}
	texte({Text = etiquettes[statut] or "", Font = Enum.Font.GothamBlack, TextColor3 = couleur, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.2, 0.58), Size = UDim2.fromScale(0.5, 0.28), ZIndex = 5, Parent = b}, 13)
	if def and not verrouillee then
		texte({Text = UI.milliers(def.recompense.pieces) .. " ◉", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.62, 0.58), Size = UDim2.fromScale(0.34, 0.28), ZIndex = 5, Parent = b}, 13)
	end
	if statut == "fini" or statut == "dispo" then
		local brille = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.3), Size = UDim2.fromScale(0.22, 0.22),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = couleur, ZIndex = 6, Parent = b}, {coin(0.5)})
		TweenService:Create(brille, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.8}):Play()
	end
	if surClic and not verrouillee then
		UI.reactif(b, 1.03)
		b.Activated:Connect(function()
			UI.jouer("clic")
			surClic()
		end)
	end
end

local function entete(ordre: number, txt: string)
	local l = texte({Name = "Entete" .. ordre, LayoutOrder = ordre, Text = txt, Font = Enum.Font.GothamBlack, TextColor3 = T.OrFonce,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20), ZIndex = 4, Parent = liste}, 14)
	return l
end

local function remplirListe()
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
			end else nil)
		end
		task.defer(function()
			-- Fait défiler jusqu'à la quête en cours
			local c = liste:FindFirstChild("Carte" .. tostring(e.h + math.min(4, (Q.HISTOIRE[e.h] or {chapitre = 4}).chapitre)))
			if c and c:IsA("GuiObject") then
				liste.CanvasPosition = Vector2.new(0, math.max(0, c.AbsolutePosition.Y - liste.AbsolutePosition.Y + liste.CanvasPosition.Y - 60))
			end
		end)
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
			end)
		end
		-- Coffre de la Guilde
		local coffre = creer("Frame", {Name = "Coffre", LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 78), BackgroundColor3 = Color3.fromRGB(70, 46, 26),
			ZIndex = 4, Parent = liste}, {coin(0.14), trait(if e.coffre then T.FerSombre else T.Or, 2),
			UI.degrade(Color3.fromRGB(255, 230, 190), Color3.fromRGB(130, 100, 80))})
		local boite = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5), Size = UDim2.fromScale(0.7, 0.62),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(120, 70, 34), ZIndex = 5, Parent = coffre},
			{coin(0.15), trait(ENCRE, 2)})
		creer("Frame", {Position = UDim2.fromScale(0, 0.38), Size = UDim2.fromScale(1, 0.14), BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 6, Parent = boite})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.22, 0.3),
			BackgroundColor3 = T.Or, ZIndex = 7, Parent = boite}, {coin(0.3), trait(ENCRE, 1.5)})
		texte({Text = "COFFRE DE LA GUILDE", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.26, 0.1), Size = UDim2.fromScale(0.7, 0.34), ZIndex = 5, Parent = coffre}, 20)
		local sous = texte({Text = if e.coffre then "Ouvert ! Reviens demain." else string.format("Rends les 3 contrats : %d / 3", rendus),
			Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.26, 0.46), Size = UDim2.fromScale(0.44, 0.26), ZIndex = 5, Parent = coffre}, 14)
		local _ = sous
		if not e.coffre then
			local pret = rendus >= Q.NB_CONTRATS
			local b = creer("TextButton", {Text = if pret then "OUVRIR" else "+50 %", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Color3.new(1, 1, 1),
				AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.96, 0.62), Size = UDim2.fromScale(0.26, 0.46),
				BackgroundColor3 = if pret then T.Vert else T.Inactif, ZIndex = 6, Parent = coffre}, {coin(0.25), trait(ENCRE, 2),
				UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)), creer("UIPadding", {PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0)})})
			if pret then
				UI.reactif(b, 1.06)
				TweenService:Create(boite, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 6}):Play()
				b.Activated:Connect(function()
					local r = action:InvokeServer({action = "coffre"})
					if type(r) == "table" then
						message(r.message, r.ok)
						if r.ok then
							UI.celebrer(scene, T.Or, "COFFRE OUVERT !")
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
		end
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
	for nom, b in boutonsOnglets do
		TweenService:Create(b, UI.FAST, {BackgroundColor3 = if nom == onglet then Color3.fromRGB(150, 104, 60) else T.Carte}):Play()
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
		texteRenommee.Text = string.format("★ %s / %s  ·  bonus vente +%d %%", UI.milliers(e.renommee), UI.milliers(suivant.renommee), r.bonus)
	else
		majBarreRang(1)
		texteRenommee.Text = string.format("★ %s  ·  RANG MAXIMAL  ·  +%d %%", UI.milliers(e.renommee), r.bonus)
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
		if nom == "histoire" then
			selection = {cible = "histoire"}
		elseif selection.cible ~= "contrat" then
			selection = {cible = "contrat", i = 1}
		end
		toutRemplir()
	end)
end

-- Grande annonce de nouveau rang dans la fenêtre
local function annonceRang(rangIndex: number)
	local r = Q.RANGS[rangIndex]
	if not r then
		return
	end
	local voile = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 30,
		Parent = F.racine}, {coin(0.03)})
	TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.35}):Play()
	local l1 = texte({Text = "NOUVEAU RANG DE GUILDE", Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.6, 0.06), ZIndex = 31, Parent = voile}, 26)
	local l2 = texte({Text = string.upper(r.nom), Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.9, 0.16), ZIndex = 31, Parent = voile}, 80)
	UI.dore(l2, 3)
	local l3 = texte({Text = string.format("Bonus de vente chez Gaspard : +%d %%", r.bonus), Font = Enum.Font.GothamBlack, TextColor3 = r.couleur,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.6, 0.06), ZIndex = 31, Parent = voile}, 26)
	UI.pop(l2, 2)
	UI.celebrer(F.racine, r.couleur)
	UI.jouer("succes", 0.8)
	task.delay(2.6, function()
		for _, o in {l1, l2, l3} do
			TweenService:Create(o, UI.FAST, {TextTransparency = 1}):Play()
		end
		TweenService:Create(voile, UI.FAST, {BackgroundTransparency = 1}):Play()
		Debris:AddItem(voile, 0.3)
	end)
end

-- Bouton principal : accepter / rendre
local occupe = false
local pauseAffichage = 0 -- pendant la célébration, les mises à jour du serveur n'effacent pas la réplique de fin
principal.bouton.Activated:Connect(function()
	if occupe or not principal.bouton.Active then
		UI.secouer(principal.bouton, 5)
		return
	end
	local def, contrat = queteSelectionnee()
	if not def then
		return
	end
	local e = etat :: {[string]: any}
	local etatQuete = if contrat then contrat.etat else e.hEtat
	local demande = {action = if etatQuete == "dispo" then "accepter" else "rendre", cible = selection.cible, i = selection.i}
	occupe = true
	UI.jouer("metal")
	local r = action:InvokeServer(demande)
	occupe = false
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
		UI.gerbe(scene, VIOLET, 14, Vector2.new(0.36, 0.95))
		UI.jouer("succes", 1.2)
		toutRemplir()
	else
		pauseAffichage = os.clock() + 2.4
		UI.celebrer(scene, T.Or, "QUÊTE ACCOMPLIE !")
		UI.jouer("succes")
		-- Réplique de fin du donneur sur le parchemin, puis la quête suivante
		dernierRecit = ""
		recit.Text = "« " .. tostring(r.fin or "Bien joué !") .. " »"
		recit.MaxVisibleGraphemes = -1
		principal.definir(string.format("+%s PIÈCES  ·  +%d ★", UI.milliers(r.pieces or 0), r.renommee or 0), T.Vert, false)
		remplirRang()
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

-- ================= Suivi à l'écran =================
local suivi = creer("ScreenGui", {Name = "SuiviQuetes", ResetOnSpawn = false, DisplayOrder = 4, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})
local panneauSuivi = creer("Frame", {Name = "Panneau", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0.28, 0), Size = UDim2.fromOffset(270, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(36, 26, 20), BackgroundTransparency = 0.12, Visible = false, Parent = suivi},
	{coin(0.06), trait(T.OrFonce, 2), UI.degrade(Color3.fromRGB(255, 240, 225), Color3.fromRGB(170, 150, 135)),
		creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
		creer("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
		creer("UIScale", {})})
local enteteSuivi = creer("TextButton", {Name = "Entete", LayoutOrder = 0, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1, Parent = panneauSuivi})
local titreSuivi = texte({Text = "GUILDE DES MINEURS", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(0.82, 1), Parent = enteteSuivi}, 20)
UI.dore(titreSuivi, 1.5)
local flecheSuivi = texte({Text = "▾", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromScale(0.15, 1), Parent = enteteSuivi}, 20)
local corpsSuivi = creer("Frame", {Name = "Corps", LayoutOrder = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Parent = panneauSuivi}, {creer("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})})
local replie = false
enteteSuivi.Activated:Connect(function()
	replie = not replie
	corpsSuivi.Visible = not replie
	flecheSuivi.Text = if replie then "▸" else "▾"
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

local function blocSuivi(ordre: number, def: Q.Quete, prog: {any}, fini: boolean, estHistoire: boolean)
	local bloc = creer("Frame", {Name = "Quete" .. ordre, LayoutOrder = ordre, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Parent = corpsSuivi}, {creer("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})})
	local t = texte({LayoutOrder = 0, Text = (if estHistoire then "◆ " else "◇ ") .. def.titre, Font = Enum.Font.GothamBlack,
		TextColor3 = if fini then T.Vert elseif estHistoire then T.Or else T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18), Parent = bloc}, 16)
	local _ = t
	if fini then
		local l = texte({LayoutOrder = 1, Text = "✔ Retourne voir Margot à la taverne", Font = Enum.Font.GothamBold, TextColor3 = T.Vert,
			TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 15), Parent = bloc}, 14)
		TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.45}):Play()
		return
	end
	for i, o in def.objectifs do
		local v = math.min(o.n, tonumber(prog[i]) or 0)
		local ok = v >= o.n
		local ligne = creer("Frame", {LayoutOrder = i, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = bloc})
		texte({Text = (if ok then "✔ " else "") .. Q.texteObjectif(o), Font = Enum.Font.GothamBold, TextColor3 = if ok then T.Vert else T.Parchemin,
			TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.62, 1), Parent = ligne}, 14)
		local maj = barre(ligne, {Position = UDim2.fromScale(0.64, 0.3), Size = UDim2.fromScale(0.22, 0.4), Parent = ligne}, if ok then T.Vert else T.Or)
		maj(v / o.n)
		texte({Text = string.format("%d/%d", v, o.n), Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.86, 0), Size = UDim2.fromScale(0.14, 1), Parent = ligne}, 13)
	end
end

local function remplirSuivi()
	local e = etat
	if not e then
		return
	end
	for _, enfant in corpsSuivi:GetChildren() do
		if enfant:IsA("GuiObject") then
			enfant:Destroy()
		end
	end
	local n = 0
	local h = Q.histoire(e.h)
	if h and e.hEtat == "active" then
		n += 1
		blocSuivi(n, h, e.hProg, e.hFini, true)
	end
	for _, c in e.contrats do
		if c.etat == "active" then
			n += 1
			blocSuivi(n, c.def, c.prog, c.fini, false)
		end
	end
	if n == 0 and h then
		-- Rien en cours : petite invitation vers Margot
		n += 1
		texte({LayoutOrder = 1, Text = "Une nouvelle quête t'attend chez Margot, à la taverne !", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Size = UDim2.new(1, 0, 0, 32), Parent = corpsSuivi}, 14)
	end
	local _, r = Q.rang(e.renommee)
	titreSuivi.Text = "GUILDE · " .. string.upper(r.nom)
	panneauSuivi.Visible = n > 0
end

-- ================= Bannières =================
local banniere = creer("Frame", {Name = "Banniere", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.2), Size = UDim2.fromScale(0.42, 0.085),
	BackgroundColor3 = Color3.fromRGB(40, 28, 20), Visible = false, ZIndex = 10, Parent = suivi},
	{coin(0.25), trait(T.Or, 3), UI.degrade(Color3.fromRGB(255, 235, 210), Color3.fromRGB(150, 120, 100)),
		creer("UISizeConstraint", {MinSize = Vector2.new(300, 56), MaxSize = Vector2.new(640, 90)})})
local banniereTitre = texte({Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.9, 0.5), ZIndex = 11,
	Parent = banniere}, 34)
UI.dore(banniereTitre, 2)
local banniereSous = texte({Font = Enum.Font.GothamBold, Position = UDim2.fromScale(0.05, 0.58), Size = UDim2.fromScale(0.9, 0.32), ZIndex = 11,
	Parent = banniere}, 18)
local fileBannieres: {{string}} = {}
local banniereActive = false
local function suivante()
	if banniereActive or #fileBannieres == 0 then
		return
	end
	banniereActive = true
	local b = table.remove(fileBannieres, 1) :: {string}
	banniereTitre.Text, banniereSous.Text = b[1], b[2]
	banniere.Visible = true
	banniere.Position = UDim2.fromScale(0.5, -0.2)
	TweenService:Create(banniere, UI.BOUNCY, {Position = UDim2.fromScale(0.5, 0.06)}):Play()
	UI.pop(banniere, 0.6)
	UI.jouer(if b[3] == "fini" then "succes" else "metal", if b[3] == "fini" then 1 else 1.3)
	if b[3] == "fini" then
		UI.gerbe(banniere, T.Or, 16)
	end
	task.delay(if b[3] == "fini" then 3.2 else 2.2, function()
		TweenService:Create(banniere, UI.FAST, {Position = UDim2.fromScale(0.5, -0.2)}):Play()
		task.delay(0.2, function()
			banniere.Visible = false
			banniereActive = false
			suivante()
		end)
	end)
end
local function annoncer(titreB: string, sous: string, genre: string)
	table.insert(fileBannieres, {titreB, sous, genre})
	suivante()
end

-- ================= « ! » / « ? » au-dessus de Margot =================
local marqueur: BillboardGui? = nil
local texteMarqueur: TextLabel? = nil
local function majMarqueur()
	local e = etat
	if not (e and marqueur and texteMarqueur) then
		return
	end
	local aRendre = (e.hEtat == "active" and e.hFini)
	local nouveau = Q.histoire(e.h) ~= nil and e.hEtat == "dispo"
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
end

task.spawn(function()
	local part = workspace:WaitForChild("InteractionGuilde", 120)
	if not (part and part:IsA("BasePart")) then
		return
	end
	local bb = creer("BillboardGui", {Name = "MarqueurGuilde", Adornee = part, AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 140,
		Size = UDim2.fromScale(3, 3.6), StudsOffsetWorldSpace = Vector3.new(0, 6.2, 0), Enabled = false, Parent = suivi})
	local l = texte({Text = "!", Font = Enum.Font.Fantasy, TextColor3 = T.Or, Size = UDim2.fromScale(1, 1), Parent = bb}, 200)
	creer("UIStroke", {Thickness = 4, Color = Color3.fromRGB(40, 20, 6), Parent = l})
	marqueur, texteMarqueur = bb, l
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
		local _, r = Q.rang(nouvelEtat.renommee)
		annoncer("NOUVEAU RANG : " .. string.upper(r.nom), string.format("Bonus de vente chez Gaspard : +%d %%", r.bonus), "fini")
	end
	for _, ev in (if type(evenements) == "table" then evenements else {}) do
		if type(ev) ~= "table" then
			continue
		end
		if ev.type == "objectif" then
			annoncer("Objectif rempli", tostring(ev.texte), "objectif")
		elseif ev.type == "fini" then
			annoncer("QUÊTE TERMINÉE !", "« " .. tostring(ev.titre) .. " » · Retourne voir Margot", "fini")
		elseif ev.type == "info" then
			annoncer("Guilde des Mineurs", tostring(ev.texte), "objectif")
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
	-- Ouvre sur ce qui demande de l'attention : quête d'histoire, sinon un contrat à rendre / nouveau
	local e = nouvelEtat
	if Q.histoire(e.h) and (e.hEtat == "dispo" or e.hFini or e.hEtat == "active") then
		onglet, selection = "histoire", {cible = "histoire"}
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
