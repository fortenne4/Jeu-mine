--!strict
-- Comptoir des minerais de Gaspard · SCRIPT CLIENT (le HUD)
-- S'ouvre quand le serveur le demande (le joueur a parlé à Gaspard). Affiche les minerais du sac,
-- leur prix et le total ; demande les ventes au serveur et affiche sa réponse : aucun calcul d'argent ici
-- (le total affiché n'est qu'un aperçu, le serveur recalcule tout).
-- Thème et effets : InterfaceMine ; minerais 3D : IconesObjets. L'invite « Vendre mes minerais »
-- est dessinée par Boutique.client.lua (attribut Theme = "Boutique"), comme celles de Liesel et Brom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Pioches = require(Partage:WaitForChild("Pioches"))
local Forge = require(Partage:WaitForChild("Forge"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local PrixMinerais = require(Partage:WaitForChild("PrixMinerais"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local DecorMarchand = require(script.Parent:WaitForChild("DecorMarchand"))
local evOuvrir = ReplicatedStorage:WaitForChild("MarchandOuvrir") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("MarchandAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Etat = {minerais: {[string]: number}, prix: {[string]: number}}

local T = UI.T
local creer, coin, trait, texte, jouer, pop, milliers = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop, UI.milliers
local FAST, BOUNCY = UI.FAST, UI.BOUNCY
local DISTANCE_FERMETURE = 16
local NOIR, BLANC = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
local ORDRE = Forge.ORDRE_SAC -- les 4 de départ + les nouveaux minerais de la mine privée
local COULEUR_VENDRE = Color3.fromRGB(70, 170, 80)
local COULEUR_TOUT = Color3.fromRGB(214, 150, 40)

local function nomMinerai(id: string): string
	local d = Forge.MINERAIS[id]
	return if d then d.nom else id
end
local function rareteMinerai(id: string): (string, Color3, number)
	local v = MineraisModeles.VISUEL[id]
	local r = if v then v.rarete else "Commun"
	return r, Pioches.RARETES[r] or T.Gris, UI.NIVEAUX[r] or 1
end
local function couleurMinerai(id: string?): Color3
	if not id then
		return T.Or
	end
	local _, c = rareteMinerai(id)
	return c
end

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "MarchandGaspard", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 10, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})

local F = UI.fenetre(gui, {nom = "Gaspard", role = "MARCHAND DE MINERAIS · LE COMPTOIR", service = "Vente", couleur = Color3.fromRGB(120, 210, 255),
	repliques = {"Montre-moi ce que la montagne t'a donné.", "Le charbon, ça chauffe ; l'or, ça paie !",
		"Pesé, compté, payé. Rien ne se perd chez Gaspard.", "Liesel a de belles pioches... encore faut-il pouvoir les payer !",
		"Plus c'est rare, plus ça brille dans ma balance."}})
local boucles = F.boucles
-- Décor d'arrière-plan (trésor, minerais, lingots) : derrière le contenu, s'arrête fenêtre fermée
local decor = DecorMarchand.creer(F.contenu.Parent :: Frame, boucles)
F.surFermeture.Event:Connect(function()
	decor.arreter()
end)
local majBourse = UI.bourse(F.droite)
local message = UI.toast(gui)
local bourse = F.droite:FindFirstChild("Bourse") :: Frame?

-- ---------- Colonne de gauche : minerais du sac + « Tout vendre » ----------
local gauche = creer("Frame", {Name = "Gauche", Size = UDim2.fromScale(0.58, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu})
texte({Text = "TON SAC", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.02, 0), Size = UDim2.fromScale(0.5, 0.065), ZIndex = 3, Parent = gauche}, 18)
local resume = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.fromScale(0.45, 0), Size = UDim2.fromScale(0.53, 0.065), ZIndex = 3, Parent = gauche}, 15)

local liste = creer("ScrollingFrame", {Name = "Liste", Position = UDim2.fromScale(0, 0.075), Size = UDim2.fromScale(1, 0.735),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = gauche}, {
	creer("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
	creer("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}),
})
local disposition = liste:FindFirstChildOfClass("UIListLayout") :: UIListLayout

-- État vide : par-dessus la liste
local vide = UI.panneau({Name = "Vide", Position = UDim2.fromScale(0, 0.075), Size = UDim2.fromScale(0.985, 0.735),
	BackgroundColor3 = Color3.fromRGB(36, 28, 24), Visible = false, ZIndex = 6, Parent = gauche}, 0.06)
local videIcone = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.08), Size = UDim2.fromScale(0.5, 0.5),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 7, Parent = vide})
Icones.minerai("Charbon", videIcone, {silhouette = true, vitesse = 0.5, hauteur = 0.3}).ZIndex = 7
local videTitre = texte({Text = "Rien à vendre, va miner !", Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.9, 0.14), ZIndex = 7, Parent = vide}, 34)
UI.dore(videTitre)
texte({Text = "Casse des minerais dans la mine : ils arrivent dans ton sac.\nReviens me les vendre ici.", Font = Enum.Font.Merriweather,
	TextColor3 = T.Parchemin, TextWrapped = true, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.76),
	Size = UDim2.fromScale(0.86, 0.16), ZIndex = 7, Parent = vide}, 16)

local principalTout = UI.boutonPrincipal({Name = "ToutVendre", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(0.985, 0.16), BackgroundColor3 = COULEUR_TOUT, ZIndex = 4, Parent = gauche}, boucles)
local boutonTout = principalTout.bouton

-- ---------- Colonne de droite : fiche de vente ----------
local fiche = UI.panneau({Name = "Fiche", Position = UDim2.fromScale(0.6, 0), Size = UDim2.fromScale(0.4, 1),
	BackgroundColor3 = Color3.fromRGB(44, 34, 28), ZIndex = 3, Parent = F.contenu}, 0.05)
creer("UIPadding", {PaddingLeft = UDim.new(0.04, 0), PaddingRight = UDim.new(0.04, 0), PaddingTop = UDim.new(0.03, 0),
	PaddingBottom = UDim.new(0.03, 0), Parent = fiche})

-- Scène : minerai 3D qui tourne sur fond de rayons à la couleur de sa rareté
local scene = creer("CanvasGroup", {Name = "Scene", Size = UDim2.fromScale(0.44, 0.4), BackgroundColor3 = T.Fond3D, ZIndex = 4,
	Parent = fiche}, {coin(0.1), trait(T.OrFonce, 2), creer("UIGradient", {Name = "Fond", Rotation = 90})})
local degradeScene = scene:FindFirstChild("Fond") :: UIGradient
local roue = creer("Frame", {Name = "Rayons", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(2.2, 2.2), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1, Parent = scene})
local rayons: {Frame} = {}
for i = 1, 10 do
	table.insert(rayons, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(if i % 2 == 0 then 0.05 else 0.09, 1), Rotation = (i - 1) * 18, BorderSizePixel = 0,
		BackgroundColor3 = BLANC, Parent = roue}, {creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.7), NumberSequenceKeypoint.new(1, 1)})})}))
end
local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.7, 0.7),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = BLANC, BackgroundTransparency = 0.8, Parent = scene}, {coin(0.5)})
UI.ombre(scene, 0.88, 0.6)
local apercu = Icones.creer(scene)
apercu.Name, apercu.ZIndex = "Apercu", 2
local echelleApercu = UI.echelle(apercu)
UI.boucle(roue, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
UI.boucle(halo, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.6}, boucles)

-- Infos à droite de la scène
local infos = creer("Frame", {Name = "Infos", Position = UDim2.fromScale(0.48, 0), Size = UDim2.fromScale(0.52, 0.4),
	BackgroundTransparency = 1, ZIndex = 4, Parent = fiche})
local nomSel = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(1, 0.3), ZIndex = 4, Parent = infos}, 34)
UI.dore(nomSel)
local badge = creer("Frame", {Position = UDim2.fromScale(0, 0.33), Size = UDim2.fromScale(0.9, 0.17), BackgroundColor3 = T.Gris, ZIndex = 4,
	Parent = infos}, {coin(0.5), trait(NOIR, 1.5, 0.5), UI.degrade(BLANC, Color3.fromRGB(170, 170, 170))})
local rareteSel = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(20, 14, 10), Position = UDim2.fromScale(0.06, 0.12),
	Size = UDim2.fromScale(0.88, 0.76), ZIndex = 5, Parent = badge}, 16)
local prixSel = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.56), Size = UDim2.fromScale(1, 0.2), ZIndex = 4, Parent = infos}, 20)
local stockSel = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.8), Size = UDim2.fromScale(1, 0.16), ZIndex = 4, Parent = infos}, 16)

-- Sélecteur de quantité : [−] [ 12 ] [+]
texte({Text = "QUANTITÉ", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.43), Size = UDim2.fromScale(0.5, 0.05), ZIndex = 4, Parent = fiche}, 14)
local rangee = creer("Frame", {Name = "Quantite", Position = UDim2.fromScale(0, 0.49), Size = UDim2.fromScale(1, 0.12),
	BackgroundTransparency = 1, ZIndex = 4, Parent = fiche})

local function boutonFer(props: {[string]: any}, txt: string, taille: number): TextButton
	props.Text, props.AutoButtonColor = "", false
	props.BackgroundColor3 = props.BackgroundColor3 or T.Fer
	props.ZIndex = props.ZIndex or 5
	local b = creer("TextButton", props, {coin(0.25), trait(T.FerSombre, 2),
		UI.degrade(Color3.fromRGB(230, 230, 236), Color3.fromRGB(110, 110, 118))})
	local l = texte({Name = "Texte", Text = txt, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.62), ZIndex = (props.ZIndex :: number) + 1, Parent = b}, taille)
	creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 14, 10), Transparency = 0.2, Parent = l})
	UI.reactif(b, 1.08)
	return b
end

local moins = boutonFer({Name = "Moins", Size = UDim2.fromScale(1, 1), SizeConstraint = Enum.SizeConstraint.RelativeYY, Parent = rangee}, "−", 30)
local plus = boutonFer({Name = "Plus", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(1, 1),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, Parent = rangee}, "+", 30)
local champ = creer("TextBox", {Name = "Champ", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.52, 0.92), BackgroundColor3 = T.Fond3D, Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = T.Or,
	Text = "0", ClearTextOnFocus = false, PlaceholderText = "0", ZIndex = 5, Parent = rangee},
	{coin(0.25), trait(T.OrFonce, 2), creer("UITextSizeConstraint", {MaxTextSize = 30, MinTextSize = 8}),
	creer("UIPadding", {PaddingTop = UDim.new(0.16, 0), PaddingBottom = UDim.new(0.16, 0)})})

-- Raccourcis 1 / 10 / MAX
local raccourcis = creer("Frame", {Name = "Raccourcis", Position = UDim2.fromScale(0, 0.635), Size = UDim2.fromScale(1, 0.085),
	BackgroundTransparency = 1, ZIndex = 4, Parent = fiche}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0.03, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
local boutonsRapides: {[number]: TextButton} = {}
for i, n in {1, 10, math.huge} do
	boutonsRapides[n] = boutonFer({Name = "Rapide" .. i, LayoutOrder = i, Size = UDim2.fromScale(0.313, 1), BackgroundColor3 = T.CarteClaire,
		Parent = raccourcis}, if n == math.huge then "MAX" else "×" .. n, 20)
end

-- Total en direct
local plaqueTotal = creer("Frame", {Name = "Total", Position = UDim2.fromScale(0, 0.74), Size = UDim2.fromScale(1, 0.085),
	BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.25, ZIndex = 4, Parent = fiche}, {coin(0.3), trait(T.OrFonce, 1.5, 0.3)})
local libelleTotal = texte({Text = "TU REÇOIS", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.2), Size = UDim2.fromScale(0.45, 0.6), ZIndex = 5, Parent = plaqueTotal}, 15)
local totalTexte = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.fromScale(0.45, 0.12), Size = UDim2.fromScale(0.5, 0.76), ZIndex = 5, Parent = plaqueTotal}, 24)
local majTotal = UI.compteur(totalTexte, function(n)
	return milliers(n + 0.5) .. " ◉"
end)

local principal = UI.boutonPrincipal({Name = "Vendre", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0.15), BackgroundColor3 = COULEUR_VENDRE, ZIndex = 4, Parent = fiche}, boucles)
local bouton = principal.bouton

-- ================= État =================
local etat: Etat = {minerais = {}, prix = PrixMinerais.PRIX}
local selection: string? = nil
local quantite = 0
local positionGaspard: Vector3? = nil
local enAttente = false

type Carte = {bouton: TextButton, fond: Frame, vignette: ViewportFrame, nom: TextLabel, rarete: TextLabel, stock: TextLabel,
	prix: TextLabel, valeur: TextLabel, bande: Frame, trait: UIStroke, lueur: Frame}
local cartes: {[string]: Carte} = {}

local function prix(id: string): number
	local p = etat.prix[id]
	return if type(p) == "number" then p else (PrixMinerais.get(id) or 0)
end
-- Bonus de rang de la Guilde des Mineurs (attribut « BonusGuilde », en %) : même calcul que Marchand.server (arrondi à l'inférieur, par minerai)
local function bonusGuilde(): number
	return math.clamp(tonumber(joueur:GetAttribute("BonusGuilde")) or 0, 0, 100)
end
local function avecBonus(base: number): number
	return math.floor(base * (1 + bonusGuilde() / 100))
end
local function stock(id: string): number
	local q = etat.minerais[id]
	return if type(q) == "number" then q else 0
end
local function totalSac(): (number, number)
	local valeur, nombre = 0, 0
	for _, id in ORDRE do
		valeur += avecBonus(stock(id) * prix(id))
		nombre += stock(id)
	end
	return valeur, nombre
end

-- ================= Rendu (mise à jour des éléments existants, jamais de reconstruction) =================
local function colorerScene(id: string?)
	local c = if id then couleurMinerai(id) else T.Gris
	local v = id and MineraisModeles.VISUEL[id]
	local teinte = if v then v.couleur else T.Gris
	degradeScene.Color = ColorSequence.new(c:Lerp(T.Fond3D, 0.4), teinte:Lerp(T.Fond3D, 0.65))
	local rayon = c:Lerp(BLANC, 0.55)
	for _, r in rayons do
		r.BackgroundColor3 = rayon
	end
	halo.BackgroundColor3 = rayon
end

local function rafraichirFiche()
	local id = selection
	local q = if id then stock(id) else 0
	if id and q > 0 then
		local nomR, couleurR, niveau = rareteMinerai(id)
		nomSel.Text = nomMinerai(id)
		rareteSel.Text = string.upper(nomR) .. "  " .. string.rep("★", niveau)
		badge.BackgroundColor3 = couleurR
		prixSel.Text = milliers(prix(id)) .. " ◉ l'unité"
		stockSel.Text = "Dans ton sac : " .. milliers(q)
		champ.Text = tostring(quantite)
		champ.TextEditable = true
		majTotal(avecBonus(quantite * prix(id)))
		local actif = quantite >= 1 and not enAttente
		principal.definir(if enAttente then "…" else string.format("VENDRE ×%s", milliers(quantite)), COULEUR_VENDRE, actif)
	else
		nomSel.Text = "—"
		rareteSel.Text = "AUCUN MINERAI"
		badge.BackgroundColor3 = T.Inactif
		prixSel.Text = ""
		stockSel.Text = "Choisis un minerai à gauche"
		champ.Text = "0"
		champ.TextEditable = false
		majTotal(0)
		principal.definir("RIEN À VENDRE", T.Inactif, false)
	end
	local peut = id ~= nil and q > 0 and not enAttente
	for n, b in boutonsRapides do
		b.Active = peut
		b.BackgroundColor3 = if peut and (if n == math.huge then quantite == q else quantite == n) then T.OrFonce else T.CarteClaire
	end
	moins.Active = peut and quantite > 1
	plus.Active = peut and quantite < q
	moins.BackgroundTransparency = if moins.Active then 0 else 0.5
	plus.BackgroundTransparency = if plus.Active then 0 else 0.5
	local b = bonusGuilde()
	libelleTotal.Text = if b > 0 then string.format("TU REÇOIS · +%d %% GUILDE", b) else "TU REÇOIS"
	libelleTotal.TextColor3 = if b > 0 then Color3.fromRGB(196, 120, 255) else T.Gris
	local valeur, nombre = totalSac()
	resume.Text = if nombre > 0 then string.format("%s minerais · %s ◉", milliers(nombre), milliers(valeur)) else ""
	principalTout.definir(if enAttente then "…" elseif nombre > 0 then "TOUT VENDRE · " .. milliers(valeur) .. " ◉" else "TOUT VENDRE",
		COULEUR_TOUT, nombre > 0 and not enAttente)
	vide.Visible = nombre == 0
end

local function rafraichirListe()
	for i, id in ORDRE do
		local c = cartes[id]
		if not c then
			continue
		end
		local q = stock(id)
		local dispo = q > 0
		local choisie = id == selection
		local _, couleurR, niveau = rareteMinerai(id)
		c.bouton.LayoutOrder = if dispo then i else i + 100 -- les minerais épuisés descendent en bas
		c.bouton.Visible = dispo or i <= #Forge.ORDRE_MINERAIS -- nouveaux minerais : seulement quand on en a
		c.bouton.Active = dispo
		c.bouton.BackgroundColor3 = if choisie then T.CarteClaire elseif dispo then T.Carte else Color3.fromRGB(30, 24, 21)
		-- Carte choisie : liseré et reflet dorés (le reflet de rareté teintait l'or en brun : sélection illisible)
		UI.rarete(c.bouton, if choisie then T.Or elseif dispo then couleurR else T.Inactif, if choisie then 4 elseif dispo then niveau else 1, boucles)
		c.trait.Color = if choisie then T.Or elseif dispo then couleurR else T.Inactif
		c.trait.Thickness = if choisie then 3.5 else 1 + math.min(niveau, 4) * 0.5
		c.bande.BackgroundColor3 = if dispo then couleurR else T.Inactif
		c.lueur.Visible = choisie and dispo
		c.fond.BackgroundColor3 = if dispo then couleurR:Lerp(T.Fond3D, 0.55) else Color3.fromRGB(28, 24, 22)
		c.nom.TextColor3 = if dispo then T.Parchemin else T.Gris
		c.rarete.TextColor3 = if dispo then couleurR else T.Inactif
		c.stock.Text = "×" .. milliers(q)
		c.stock.TextColor3 = if dispo then T.Parchemin else T.Inactif
		c.prix.Text = milliers(prix(id)) .. " ◉ / u"
		c.valeur.Text = if dispo then "= " .. milliers(avecBonus(q * prix(id))) .. " ◉" else "épuisé"
		c.valeur.TextColor3 = if dispo then T.Or else T.Inactif
		local v = Icones.vue(c.vignette)
		if v then
			v.vitesse = if choisie then 0.9 else 0
		end
		c.vignette.ImageTransparency = if dispo then 0 else 0.55
	end
end

local function rafraichir()
	rafraichirListe()
	rafraichirFiche()
end

local function bornerQuantite()
	local q = if selection then stock(selection) else 0
	quantite = if q <= 0 then 0 else math.clamp(quantite, 1, q)
end

local function premierDispo(): string?
	-- le plus précieux d'abord : c'est souvent celui qu'on vient vendre
	for i = #ORDRE, 1, -1 do
		if stock(ORDRE[i]) > 0 then
			return ORDRE[i]
		end
	end
	return nil
end

local function choisir(id: string?, silencieux: boolean?)
	if id == selection and not silencieux then
		return
	end
	selection = id
	quantite = if id then stock(id) else 0 -- par défaut : tout le stock de ce minerai
	if id then
		Icones.definir(apercu, "minerai", id, {vitesse = 0.9, marge = 0.85, hauteur = 0.3})
	else
		local ancien = apercu:FindFirstChild("Objet")
		if ancien then
			ancien:Destroy()
		end
		apercu:SetAttribute("Cle", nil)
	end
	colorerScene(id)
	rafraichir()
	if not silencieux then
		jouer("clic", 1.2)
		pop(scene, 0.92)
		echelleApercu.Scale = 0.5
		TweenService:Create(echelleApercu, BOUNCY, {Scale = 1}):Play()
	end
end

local function definirQuantite(n: number)
	local avant = quantite
	quantite = math.floor(n)
	bornerQuantite()
	if quantite ~= avant then
		jouer("survol", 1.2 + math.min(quantite, 50) * 0.01)
		pop(champ, 0.9)
	end
	rafraichirFiche()
end

-- Cartes des minerais (créées une fois)
local function hauteurCarte()
	local n = math.max(1, math.min(#ORDRE, 4))
	local h = math.max(52, (liste.AbsoluteSize.Y - 8 - (n - 1) * 6) / n)
	for _, c in cartes do
		c.bouton.Size = UDim2.new(1, -4, 0, h)
	end
	liste.CanvasSize = UDim2.fromOffset(0, disposition.AbsoluteContentSize.Y + 8)
end

for i, id in ORDRE do
	local carte = creer("TextButton", {Name = id, LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 64),
		BackgroundColor3 = T.Carte, ZIndex = 3, Parent = liste}, {coin(0.18), UI.degrade(BLANC, Color3.fromRGB(175, 165, 160))})
	local tr = UI.rarete(carte, T.Gris, 1, boucles)
	-- Lueur dorée de la carte choisie (venue de la gauche) : la sélection se lit d'un coup d'œil
	local lueur = creer("Frame", {Name = "Lueur", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Or, BorderSizePixel = 0, Visible = false,
		ZIndex = 3, Parent = carte}, {coin(0.18), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.62),
		NumberSequenceKeypoint.new(0.55, 0.92), NumberSequenceKeypoint.new(1, 1)})})})
	local bande = creer("Frame", {Name = "Bande", Position = UDim2.fromScale(0.01, 0.15), Size = UDim2.fromScale(0.012, 0.7),
		BorderSizePixel = 0, ZIndex = 4, Parent = carte}, {coin(0.5)})
	local fond = creer("Frame", {Name = "Fond", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.035, 0.5),
		Size = UDim2.fromScale(0.84, 0.84), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 4, Parent = carte},
		{coin(0.3), trait(NOIR, 1.5, 0.4), UI.degrade(BLANC, Color3.fromRGB(60, 50, 50))})
	local vignette = Icones.minerai(id, fond, {vitesse = 0, hauteur = 0.35, marge = 0.8})
	vignette.ZIndex = 5
	local nomR = rareteMinerai(id)
	local nom = texte({Text = nomMinerai(id), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.2, 0.14), Size = UDim2.fromScale(0.34, 0.42), ZIndex = 4, Parent = carte}, 22)
	local rar = texte({Text = nomR, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.2, 0.58), Size = UDim2.fromScale(0.34, 0.28), ZIndex = 4, Parent = carte}, 14)
	local st = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0.53, 0.2), Size = UDim2.fromScale(0.16, 0.6), ZIndex = 4, Parent = carte}, 24)
	local px = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.7, 0.12), Size = UDim2.fromScale(0.27, 0.36), ZIndex = 4, Parent = carte}, 15)
	local val = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.7, 0.5), Size = UDim2.fromScale(0.27, 0.4), ZIndex = 4, Parent = carte}, 20)
	cartes[id] = {bouton = carte, fond = fond, vignette = vignette, nom = nom, rarete = rar, stock = st, prix = px, valeur = val,
		bande = bande, trait = tr, lueur = lueur}
	UI.reactif(carte, 1.025)
	carte.MouseEnter:Connect(function()
		local v = Icones.vue(vignette)
		if v and carte.Active then
			v.vitesse = 2
			TweenService:Create(tr, FAST, {Thickness = 4}):Play()
		end
	end)
	carte.MouseLeave:Connect(function()
		local v = Icones.vue(vignette)
		if v then
			v.vitesse = if id == selection then 0.9 else 0
		end
		rafraichirListe()
	end)
	carte.Activated:Connect(function()
		if carte.Active and not enAttente then
			choisir(id)
		end
	end)
end
liste:GetPropertyChangedSignal("AbsoluteSize"):Connect(hauteurCarte)
disposition:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	liste.CanvasSize = UDim2.fromOffset(0, disposition.AbsoluteContentSize.Y + 8)
end)
hauteurCarte()

-- ================= Quantité : −/+ (maintenir pour accélérer), champ, raccourcis =================
local maintien = 0
local function repeter(b: TextButton, pas: number)
	b.MouseButton1Down:Connect(function()
		if not b.Active then
			return
		end
		maintien += 1
		local moi = maintien
		definirQuantite(quantite + pas)
		task.delay(0.35, function()
			local k = 0
			while maintien == moi and b.Active do
				k += 1
				definirQuantite(quantite + pas * (if k > 20 then 10 elseif k > 8 then 3 else 1))
				task.wait(0.07)
			end
		end)
	end)
	local function lacher()
		maintien += 1
	end
	b.MouseButton1Up:Connect(lacher)
	b.MouseLeave:Connect(lacher)
end
repeter(moins, -1)
repeter(plus, 1)

champ.FocusLost:Connect(function()
	local n = tonumber((champ.Text:gsub("%D", "")))
	definirQuantite(n or quantite)
end)
champ:GetPropertyChangedSignal("Text"):Connect(function()
	local propre = champ.Text:gsub("%D", "")
	if propre ~= champ.Text then
		champ.Text = propre
	end
end)

for n, b in boutonsRapides do
	b.Activated:Connect(function()
		if b.Active and selection then
			jouer("clic", 1.1)
			definirQuantite(if n == math.huge then stock(selection) else n)
		end
	end)
end

-- ================= Effet : les pièces volent jusqu'à la bourse =================
local function centreDe(o: GuiObject): Vector2
	return o.AbsolutePosition + o.AbsoluteSize / 2
end

local function volerPieces(depuis: GuiObject, montant: number)
	local cible = if bourse then bourse.AbsolutePosition + Vector2.new(bourse.AbsoluteSize.Y * 0.45, bourse.AbsoluteSize.Y / 2) else Vector2.new(0, 0)
	local depart = centreDe(depuis)
	local taille = math.max(16, gui.AbsoluteSize.Y * 0.034)
	local n = math.clamp(math.floor(math.log(montant + 1) * 3), 5, 18)
	-- montant qui s'envole du bouton
	local gain = texte({Text = "+" .. milliers(montant) .. " ◉", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(depart.X, depart.Y - depuis.AbsoluteSize.Y * 0.6), Size = UDim2.fromOffset(taille * 7, taille * 1.6),
		ZIndex = 81, Parent = gui}, 44)
	UI.dore(gain, 2.5)
	pop(gain, 1.8)
	TweenService:Create(gain, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.fromOffset(depart.X, depart.Y - depuis.AbsoluteSize.Y * 0.6 - taille * 3)}):Play()
	task.delay(0.7, function()
		TweenService:Create(gain, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
	end)
	Debris:AddItem(gain, 1.2)
	for i = 1, n do
		local piece = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(depart.X, depart.Y),
			Size = UDim2.fromOffset(taille, taille), BackgroundColor3 = T.Or, ZIndex = 80, Parent = gui},
			{coin(0.5), trait(T.OrFonce, 2), UI.degrade(Color3.fromRGB(255, 250, 210), Color3.fromRGB(200, 130, 30), 45)})
		texte({Text = "◉", TextColor3 = T.OrFonce, Size = UDim2.fromScale(1, 1), ZIndex = 81, Parent = piece}, 30)
		local a = math.random() * math.pi * 2
		local r = taille * (1.5 + math.random() * 2.5)
		local eclate = depart + Vector2.new(math.cos(a) * r, math.sin(a) * r - taille)
		local t1 = TweenService:Create(piece, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = UDim2.fromOffset(eclate.X, eclate.Y), Rotation = math.random(-90, 90)})
		t1:Play()
		task.delay(0.22 + i * 0.045, function()
			local t2 = TweenService:Create(piece, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.fromOffset(cible.X, cible.Y), Size = UDim2.fromOffset(taille * 0.6, taille * 0.6), Rotation = 0})
			t2.Completed:Connect(function()
				piece:Destroy()
				if i % 3 == 1 or i == n then
					jouer("metal", 1.5 + i * 0.03)
				end
				if bourse then
					pop(bourse, 1.12)
				end
			end)
			t2:Play()
		end)
	end
end

-- ================= Vente (le serveur décide) =================
local function vendre(demande: {[string]: any}, depuis: GuiObject)
	if enAttente then
		return
	end
	jouer("clic")
	enAttente = true
	rafraichirFiche()
	local ok, rep = pcall(function()
		return fnAction:InvokeServer(demande)
	end)
	enAttente = false
	if ok and type(rep) == "table" then
		if type(rep.etat) == "table" and type(rep.etat.minerais) == "table" then
			etat = {minerais = rep.etat.minerais, prix = if type(rep.etat.prix) == "table" then rep.etat.prix else PrixMinerais.PRIX}
		end
		message(tostring(rep.message), rep.ok == true)
		if rep.ok then
			local gain = if type(rep.gain) == "number" then rep.gain else 0
			jouer("succes", if demande.action == "toutVendre" then 0.9 else 1.1)
			-- Éclats dans la scène, tampon sur toute la fiche (dans la petite scène il était coupé)
			UI.celebrer(scene, couleurMinerai(selection))
			UI.tampon(fiche, if demande.action == "toutVendre" then "TOUT VENDU !" else "VENDU !", 0.3, 0.16)
			volerPieces(depuis, gain)
			pop(F.racine, 0.98)
			local c = selection and cartes[selection]
			if c then
				pop(c.bouton, 0.85)
			end
		else
			jouer("clic", 0.6)
			UI.secouer(depuis)
		end
	else
		message("Gaspard n'a pas répondu, réessaie", false)
		UI.secouer(depuis)
	end
	-- le minerai choisi est épuisé : on passe au suivant
	if not selection or stock(selection) <= 0 then
		choisir(premierDispo(), true)
	else
		bornerQuantite()
		rafraichir()
	end
end

bouton.Activated:Connect(function()
	if bouton.Active and selection and quantite >= 1 then
		vendre({action = "vendre", id = selection, quantite = quantite}, bouton)
	end
end)
boutonTout.Activated:Connect(function()
	if boutonTout.Active then
		vendre({action = "toutVendre"}, boutonTout)
	end
end)

-- ================= Ouverture / fermeture =================
local function ouvrirComptoir(nouvelEtat: Etat, position: Vector3)
	etat = {minerais = if type(nouvelEtat.minerais) == "table" then nouvelEtat.minerais else {},
		prix = if type(nouvelEtat.prix) == "table" then nouvelEtat.prix else PrixMinerais.PRIX}
	positionGaspard = position
	choisir(premierDispo(), true)
	if F.estOuverte() then
		return
	end
	F.ouvrir()
	decor.demarrer()
	echelleApercu.Scale = 0.4
	TweenService:Create(echelleApercu, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

evOuvrir.OnClientEvent:Connect(function(nouvelEtat: any, position: any)
	if type(nouvelEtat) == "table" and typeof(position) == "Vector3" then
		ouvrirComptoir(nouvelEtat, position)
	end
end)

-- Le sac change pendant que le comptoir est ouvert (forge, minage) : on suit, sans reconstruire
task.spawn(function()
	local evSac = ReplicatedStorage:WaitForChild("SacEtat", 60)
	if not (evSac and evSac:IsA("RemoteEvent")) then
		return
	end
	evSac.OnClientEvent:Connect(function(s: any)
		if not (F.estOuverte() and not enAttente and type(s) == "table" and type(s.minerais) == "table") then
			return
		end
		local m = {}
		for id, q in s.minerais do
			if PrixMinerais.get(id) and type(q) == "number" and q > 0 then
				m[id] = q
			end
		end
		etat.minerais = m
		if not selection or stock(selection) <= 0 then
			choisir(premierDispo(), true)
		else
			bornerQuantite()
			rafraichir()
		end
	end)
end)

-- Fermeture au clavier / manette : touche d'interaction (E / X), gérée par InterfaceMine.fenetre

-- Pièces : compteur de la bourse qui défile
task.spawn(function()
	local stats = joueur:WaitForChild("leaderstats", 30)
	local v = stats and stats:WaitForChild("Pièces", 30)
	if not (v and v:IsA("IntValue")) then
		return
	end
	majBourse(v.Value, true)
	v.Changed:Connect(function(n)
		majBourse(n)
	end)
end)

-- On s'éloigne de Gaspard ou on meurt : le comptoir se ferme
task.spawn(function()
	while true do
		task.wait(0.3)
		if F.estOuverte() then
			local perso = joueur.Character
			local racine = perso and perso:FindFirstChild("HumanoidRootPart")
			local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
			if not (racine and racine:IsA("BasePart") and humanoid and humanoid.Health > 0 and positionGaspard)
				or (racine.Position - positionGaspard).Magnitude > DISTANCE_FERMETURE then
				F.fermerFenetre()
			end
		end
	end
end)

-- Le rang de la Guilde change (quête rendue) : prix et totaux affichés suivent le nouveau bonus
joueur:GetAttributeChangedSignal("BonusGuilde"):Connect(function()
	if F.estOuverte() then
		rafraichir()
	end
end)
