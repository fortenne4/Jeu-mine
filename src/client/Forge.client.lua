--!strict
-- Forge de Brom · SCRIPT CLIENT (l'UI)
-- S'ouvre quand le serveur le demande (le joueur a parlé à Brom). Aperçu en direct via Partage.Forge,
-- mais c'est le serveur qui recalcule, vérifie le sac et crée l'objet : le client ne fait qu'afficher et demander.
-- Thème et effets : InterfaceMine ; minerais / épée / lingots 3D : IconesObjets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Forge = require(Partage:WaitForChild("Forge"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local ArmesVoxels = require(Partage:WaitForChild("ArmesVoxels"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local DecorForge = require(script.Parent:WaitForChild("DecorForge"))
local evOuvrir = ReplicatedStorage:WaitForChild("ForgeOuvrir") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("ForgeAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Objet = {id: string, type: string, modele: string?, rang: number?, nom: string, couleur: string, stat: string, valeur: number, composition: {{any}}}
type Etat = {minerais: {[string]: number}, objets: {Objet}}
type Slot = {id: string?, q: number}

local T = UI.T
local creer, coin, trait, texte, jouer, pop = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop
local FAST, BOUNCY = UI.FAST, UI.BOUNCY
local DISTANCE_FERMETURE = 16
local EPEE_3D = "EpeeFer"
local NOIR = Color3.new(0, 0, 0)

local function couleurMinerai(id: string): Color3
	return Pioches.RARETES[MineraisModeles.VISUEL[id] and MineraisModeles.VISUEL[id].rarete or "Commun"] or T.Gris
end

local function arrondir(c: Color3): Color3
	local function q(x: number)
		return math.floor(x * 255 / 12 + 0.5) * 12
	end
	return Color3.fromRGB(math.min(255, q(c.R)), math.min(255, q(c.G)), math.min(255, q(c.B)))
end

-- Vrai modèle 3D d'un objet forgé : épée dédiée (ses couleurs), sinon l'épée de fer teintée, sinon un lingot
local function definirObjet(vp: ViewportFrame, typeId: string, couleur: Color3, vitesse: number, modele: string?)
	if typeId == "Epee" and modele and ArmesVoxels.existe(modele) then
		Icones.definir(vp, "epee", modele, {vitesse = vitesse, hauteur = 0.1, marge = 0.85})
	elseif typeId == "Epee" and ArmesVoxels.existe(EPEE_3D) then
		Icones.definir(vp, "epee", EPEE_3D, {teinte = arrondir(couleur), vitesse = vitesse, hauteur = 0.1, marge = 0.85})
	elseif typeId == "Casque" or typeId == "Plastron" or typeId == "Jambieres" then
		Icones.definir(vp, "armure", modele or typeId, {teinte = arrondir(couleur), vitesse = vitesse, hauteur = 0.2, marge = 0.85, angle = 0.45})
	else
		Icones.definir(vp, "lingot", arrondir(couleur):ToHex(), {vitesse = vitesse, hauteur = 0.45, marge = 0.85})
	end
end

local function bouton(props: {[string]: any}, tailleMax: number?): TextButton
	props.AutoButtonColor = false
	props.TextScaled = true
	props.Font = props.Font or Enum.Font.GothamBlack
	props.TextColor3 = props.TextColor3 or T.Parchemin
	props.BackgroundColor3 = props.BackgroundColor3 or T.CarteClaire
	local b = creer("TextButton", props, {coin(0.25), trait(T.FerSombre, 2), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
	creer("UITextSizeConstraint", {MaxTextSize = tailleMax or 26, MinTextSize = 8, Parent = b})
	UI.reactif(b, 1.08)
	return b
end

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "ForgeBrom", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 10, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})

local F = UI.fenetre(gui, {nom = "Brom", role = "FORGERON · LA FORGE", service = "Forge", couleur = T.Braise,
	repliques = {"Le feu est chaud, apporte ton minerai !", "Fer et charbon... ça fait de l'acier, gamin.",
		"Frappe tant que c'est chaud !", "L'or seul, c'est mou. Mélange-le."}})
local boucles = F.boucles
-- Décor d'arrière-plan (enclume, marteau, braises) : derrière le contenu, s'arrête fenêtre fermée
local decor = DecorForge.creer(F.contenu.Parent :: Frame, boucles)
local majBourse = UI.bourse(F.droite)
local message = UI.toast(gui)
local gauche = creer("Frame", {Name = "Gauche", Size = UDim2.fromScale(0.6, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = F.contenu})

-- ================= Onglets : type d'objet =================
local barreOnglets = creer("Frame", {Name = "Onglets", Size = UDim2.fromScale(1, 0.13), BackgroundTransparency = 1, ZIndex = 3, Parent = gauche}, {
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.016, 0), SortOrder = Enum.SortOrder.LayoutOrder}),
})
type Onglet = {bouton: TextButton, trait: UIStroke, souligne: Frame}
local onglets: {[string]: Onglet} = {}
for i, id in Forge.ORDRE_TYPES do
	local t = Forge.TYPES[id]
	local b = creer("TextButton", {Name = id, LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.238, 1),
		BackgroundColor3 = T.Carte, ZIndex = 3, Parent = barreOnglets}, {coin(0.25), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 135))})
	local tr = trait(T.FerSombre, 2)
	tr.Parent = b
	-- vrai modèle 3D du type (acier neutre), qui tourne au survol
	local caseIcone = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.03, 0.5), Size = UDim2.fromScale(0.86, 0.86),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.4, ZIndex = 4, Parent = b}, {coin(0.5)})
	local vpOnglet = Icones.creer(caseIcone)
	vpOnglet.ZIndex = 5
	definirObjet(vpOnglet, id, Color3.fromRGB(168, 174, 186), 0)
	b.MouseEnter:Connect(function()
		local v = Icones.vue(vpOnglet)
		if v then
			v.vitesse = 2
		end
	end)
	b.MouseLeave:Connect(function()
		local v = Icones.vue(vpOnglet)
		if v then
			v.vitesse = 0
		end
	end)
	texte({Text = t.nom, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.36, 0.22), Size = UDim2.fromScale(0.6, 0.56), ZIndex = 4, Parent = b}, 18)
	local souligne = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0, 0.08),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, ZIndex = 5, Parent = b}, {coin(0.5)})
	UI.reactif(b, 1.05)
	onglets[id] = {bouton = b, trait = tr, souligne = souligne}
end

-- ================= Emplacements de minerai (vrais minerais 3D) =================
local creuset = creer("Frame", {Name = "Creuset", Position = UDim2.fromScale(0, 0.16), Size = UDim2.fromScale(1, 0.5),
	BackgroundTransparency = 1, ZIndex = 3, Parent = gauche})
local plusMilieu = texte({Text = "+", Font = Enum.Font.GothamBlack, TextColor3 = T.Or, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromScale(0.1, 0.25), ZIndex = 4, Parent = creuset}, 60)
UI.dore(plusMilieu, 3)
UI.boucle(UI.echelle(plusMilieu), TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.2}, boucles)

type SlotUI = {carte: Frame, choix: TextButton, fond: Frame, vp: ViewportFrame, vide: TextLabel, appel: UIStroke, nom: TextLabel, possede: TextLabel,
	rangee: Frame, moins: TextButton, plus: TextButton, boite: TextBox, retirer: TextButton?}
local slotsUI: {SlotUI} = {}
for i = 1, 2 do
	local carte = UI.panneau({Name = "Emplacement" .. i, Position = UDim2.fromScale(if i == 1 then 0 else 0.56, 0), Size = UDim2.fromScale(0.44, 1),
		ZIndex = 3, Parent = creuset}, 0.07)
	local bordure = carte:FindFirstChildOfClass("UIStroke")
	if bordure then
		bordure:Destroy() -- remplacé par le liseré de rareté
	end
	texte({Text = if i == 1 then "MINERAI 1" else "MINERAI 2 · optionnel", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.06, 0.03), Size = UDim2.fromScale(0.7, 0.09), ZIndex = 4, Parent = carte}, 14)
	local retirer = if i == 2 then bouton({Text = "✕", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.96, 0.03),
		Size = UDim2.fromScale(0.13, 0.11), BackgroundColor3 = Color3.fromRGB(150, 50, 38), ZIndex = 4, Parent = carte}, 16) else nil
	local choix = creer("TextButton", {Name = "Choix", Text = "", AutoButtonColor = false, Position = UDim2.fromScale(0.06, 0.14),
		Size = UDim2.fromScale(0.88, 0.5), BackgroundTransparency = 1, ZIndex = 4, Parent = carte})
	local fond = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = choix},
		{coin(0.5), UI.degrade(Color3.fromRGB(255, 220, 190), Color3.fromRGB(60, 50, 45))})
	local vp = Icones.creer(fond)
	vp.ZIndex = 5
	local vide = texte({Text = "+", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = fond}, 50)
	-- Emplacement vide : anneau doré qui pulse (« pose un minerai ici »)
	local appel = trait(T.Or, 2.5, 0.2)
	appel.Name, appel.Parent = "Appel", fond
	UI.boucle(appel, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.85}, boucles)
	local nom = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.5, 0.36), ZIndex = 5, Parent = choix}, 26)
	local possede = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.5, 0.24), ZIndex = 5, Parent = choix}, 15)
	local rangee = creer("Frame", {Name = "Quantite", Position = UDim2.fromScale(0.06, 0.7), Size = UDim2.fromScale(0.88, 0.2),
		BackgroundTransparency = 1, ZIndex = 4, Parent = carte})
	local moins = bouton({Text = "−", Size = UDim2.fromScale(0.24, 1), ZIndex = 4, Parent = rangee}, 28)
	local plus = bouton({Text = "+", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.24, 1),
		ZIndex = 4, Parent = rangee}, 28)
	local boite = creer("TextBox", {Text = "1", ClearTextOnFocus = false, TextScaled = true, Font = Enum.Font.GothamBlack,
		TextColor3 = T.Or, BackgroundColor3 = T.Fond3D, Position = UDim2.fromScale(0.28, 0), Size = UDim2.fromScale(0.44, 1), ZIndex = 4,
		Parent = rangee}, {coin(0.25), trait(T.OrFonce, 1.5), creer("UITextSizeConstraint", {MaxTextSize = 26})})
	UI.reactif(choix, 1.04, carte)
	choix.MouseEnter:Connect(function()
		local v = Icones.vue(vp)
		if v then
			v.vitesse = 2.2
		end
	end)
	choix.MouseLeave:Connect(function()
		local v = Icones.vue(vp)
		if v then
			v.vitesse = 0.5
		end
	end)
	slotsUI[i] = {carte = carte, choix = choix, fond = fond, vp = vp, vide = vide, appel = appel, nom = nom, possede = possede, rangee = rangee,
		moins = moins, plus = plus, boite = boite, retirer = retirer}
end

-- Barre de proportions entre les deux minerais + badge d'alliage
local zoneProp = creer("Frame", {Name = "Proportions", Position = UDim2.fromScale(0, 0.69), Size = UDim2.fromScale(1, 0.09),
	BackgroundTransparency = 1, ZIndex = 3, Parent = gauche})
local railProp = creer("Frame", {Position = UDim2.fromScale(0, 0.45), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = T.Fond3D,
	ClipsDescendants = true, ZIndex = 4, Parent = zoneProp}, {coin(0.5), trait(T.FerSombre, 2)})
local propA = creer("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 4, Parent = railProp},
	{UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(130, 130, 130))})
local propB = creer("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0, 1), BorderSizePixel = 0,
	ZIndex = 4, Parent = railProp}, {UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(130, 130, 130))})
local texteA = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.02, 0.1),
	Size = UDim2.fromScale(0.4, 0.8), ZIndex = 6, Parent = railProp}, 15)
local texteB = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.58, 0.1),
	Size = UDim2.fromScale(0.4, 0.8), ZIndex = 6, Parent = railProp}, 15)
creer("UIStroke", {Thickness = 1.5, Parent = texteA})
creer("UIStroke", {Thickness = 1.5, Parent = texteB})
local badgeAlliage = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.42, 0.55),
	BackgroundColor3 = T.Or, Visible = false, ZIndex = 7, Parent = zoneProp}, {coin(0.5),
	UI.degrade(Color3.fromRGB(255, 250, 220), Color3.fromRGB(200, 130, 40))})
local texteAlliage = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(50, 24, 8), Position = UDim2.fromScale(0.05, 0.12),
	Size = UDim2.fromScale(0.9, 0.76), ZIndex = 8, Parent = badgeAlliage}, 16)
UI.rarete(badgeAlliage, T.Or, 4, boucles)

-- ================= Objets forgés =================
local titreInventaire = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.012, 0.8), Size = UDim2.fromScale(0.98, 0.05), ZIndex = 3, Parent = gauche}, 14)
local inventaire = creer("ScrollingFrame", {Name = "Inventaire", Position = UDim2.fromScale(0, 0.855), Size = UDim2.fromScale(1, 0.145),
	BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.35, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 3, Parent = gauche}, {coin(0.15), trait(T.FerSombre, 2),
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center}),
	creer("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}),
})
-- État vide : posé par-dessus la bande (dans la liste défilante, il ne s'affichait pas)
local vide = texte({Text = "Rien de forgé pour l'instant : choisis tes minerais et frappe !", Font = Enum.Font.Merriweather,
	TextColor3 = T.Parchemin, TextTransparency = 0.25, Position = UDim2.fromScale(0.03, 0.875), Size = UDim2.fromScale(0.94, 0.105),
	ZIndex = 5, Parent = gauche}, 15)

-- ================= Aperçu du résultat =================
local fiche = UI.panneau({Name = "Apercu", Position = UDim2.fromScale(0.62, 0), Size = UDim2.fromScale(0.38, 1),
	BackgroundColor3 = Color3.fromRGB(44, 34, 28), ZIndex = 3, Parent = F.contenu}, 0.05)
creer("UIPadding", {PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0), PaddingTop = UDim.new(0.035, 0),
	PaddingBottom = UDim.new(0.035, 0), Parent = fiche})

local scene = creer("CanvasGroup", {Name = "Scene", Size = UDim2.fromScale(1, 0.47), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4,
	Parent = fiche}, {coin(0.08), trait(T.OrFonce, 2), creer("UIGradient", {Name = "Fond", Rotation = 90})})
local degradeScene = scene:FindFirstChild("Fond") :: UIGradient
local rayons = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(2, 2),
	SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Parent = scene}, {coin(0.5),
	creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.2),
		NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(0.35, 0.3), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(0.65, 0.2),
		NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(0.9, 0.3), NumberSequenceKeypoint.new(1, 1)})})})
UI.boucle(rayons, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
-- Lueur de magma qui respire au pied de l'objet (identité de la forge)
local magma = creer("Frame", {Name = "Magma", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 110, 30), BorderSizePixel = 0, Parent = scene})
local gMagma = creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.6, 0.7), NumberSequenceKeypoint.new(1, 0.3)}), Parent = magma})
UI.boucle(gMagma, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.15)}, boucles)
UI.ombre(scene, 0.86, 0.6)
local vpResultat = Icones.creer(scene)
vpResultat.ZIndex = 2
local echelleResultat = UI.echelle(vpResultat)
-- pastille du type en bas à droite : silhouette 3D du modèle
local pastilleType = creer("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.97, 0.97), Size = UDim2.fromScale(0.2, 0.2),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.35, ZIndex = 3, Parent = scene},
	{coin(0.5), trait(T.OrFonce, 1.5, 0.3)})
local iconeType = Icones.creer(pastilleType)
iconeType.ZIndex = 4
local bandeauAlliage = texte({Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04),
	Size = UDim2.fromScale(0.9, 0.13), ZIndex = 3, Parent = scene}, 20)
UI.dore(bandeauAlliage, 2)

local nomRes = texte({Font = Enum.Font.Fantasy, Position = UDim2.fromScale(0, 0.49), Size = UDim2.fromScale(1, 0.09), ZIndex = 4, Parent = fiche}, 30)
UI.dore(nomRes)
local statRes = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0, 0.585),
	Size = UDim2.fromScale(1, 0.085), ZIndex = 4, Parent = fiche}, 30)
local statEnCours = {stat = "Dégâts", icone = "⚔", vide = true}
local majStat = UI.compteur(statRes, function(n)
	return if statEnCours.vide then statEnCours.icone .. " " .. statEnCours.stat .. " : —"
		else string.format("%s %s : %d", statEnCours.icone, statEnCours.stat, math.floor(n + 0.5))
end)
local compoRes = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromScale(0, 0.675),
	Size = UDim2.fromScale(1, 0.05), ZIndex = 4, Parent = fiche}, 15)
local coutRes = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0, 0.73), Size = UDim2.fromScale(1, 0.055), ZIndex = 4, Parent = fiche}, 17)
local coutActuel = {total = 0, prix = 0}
local majPrix = UI.compteur(coutRes, function(n)
	return if coutActuel.total == 0 then "" else string.format("◆ %d minerais   ◉ %d pièces", coutActuel.total, math.floor(n + 0.5))
end)
local avis = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Rouge, Position = UDim2.fromScale(0, 0.79),
	Size = UDim2.fromScale(1, 0.05), ZIndex = 4, Parent = fiche}, 15)

local principal = UI.boutonPrincipal({Name = "Forger", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0.14), BackgroundColor3 = T.Braise, ZIndex = 4, Parent = fiche}, boucles)
local boutonForger = principal.bouton

-- ================= Choix d'un minerai (par-dessus la colonne de gauche) =================
local panneauChoix = UI.panneau({Name = "ChoixMinerai", Size = UDim2.fromScale(0.6, 1), BackgroundColor3 = Color3.fromRGB(50, 38, 30),
	Active = true, Visible = false, ZIndex = 10, Parent = F.contenu}, 0.04)
creer("UIPadding", {PaddingLeft = UDim.new(0.03, 0), PaddingRight = UDim.new(0.03, 0), PaddingTop = UDim.new(0.03, 0),
	PaddingBottom = UDim.new(0.03, 0), Parent = panneauChoix})
local titreChoix = texte({Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.7, 0.11), ZIndex = 11,
	Parent = panneauChoix}, 32)
UI.dore(titreChoix)
local annulerChoix = bouton({Text = "Annuler", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromScale(0.25, 0.11), ZIndex = 11, Parent = panneauChoix}, 18)
local listeChoix = creer("ScrollingFrame", {Position = UDim2.fromScale(0, 0.14), Size = UDim2.fromScale(1, 0.86),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = T.OrFonce,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 11, Parent = panneauChoix}, {
	creer("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
	creer("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}),
})

-- ================= État =================
local etat: Etat = {minerais = {}, objets = {}}
local typeChoisi = Forge.ORDRE_TYPES[1]
local slots: {Slot} = {{id = nil, q = 1}, {id = nil, q = 1}}
local pointForge: BasePart? = nil
local promptForge: ProximityPrompt? = nil
local enAttente = false
local cartesObjets: {[string]: Frame} = {}
local dernierAlliage: string? = nil

local function possede(id: string): number
	return etat.minerais[id] or 0
end

local function borne(id: string, q: number): number
	return math.clamp(math.floor(q), 1, math.max(1, possede(id)))
end

local function pieces(): number
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Pièces")
	return if v and v:IsA("IntValue") then v.Value else 0
end

local function composition(): {{any}}
	local c = {}
	for _, s in slots do
		if s.id then
			table.insert(c, {s.id, s.q})
		end
	end
	return c
end

-- ================= Rendu =================
local function rafraichirOnglets()
	for id, o in onglets do
		local choisi = id == typeChoisi
		o.bouton.BackgroundColor3 = if choisi then T.CarteClaire else T.Carte
		o.trait.Color = if choisi then T.Or else T.FerSombre
		o.trait.Thickness = if choisi then 3 else 2
		TweenService:Create(o.souligne, BOUNCY, {Size = UDim2.fromScale(if choisi then 0.7 else 0, 0.08)}):Play()
	end
end

local function rafraichirSlots()
	local total = 0
	for _, s in slots do
		total += if s.id then s.q else 0
	end
	for i, ui in slotsUI do
		local s = slots[i]
		local id = s.id
		local rarete = UI.rarete(ui.carte, if id then couleurMinerai(id) else T.FerSombre,
			if id then UI.NIVEAUX[MineraisModeles.VISUEL[id].rarete] or 1 else 1, boucles)
		rarete.Transparency = if id then 0 else 0.3
		ui.vp.Visible = id ~= nil
		ui.vide.Visible = id == nil
		ui.appel.Enabled = id == nil
		if id then
			local m = Forge.MINERAIS[id]
			Icones.definir(ui.vp, "minerai", id, {vitesse = 0.5, hauteur = 0.35})
			ui.fond.BackgroundColor3 = couleurMinerai(id):Lerp(T.Fond3D, 0.55)
			ui.nom.Text = m.nom
			ui.nom.TextColor3 = T.Parchemin
			ui.possede.Text = "Possédé : " .. possede(id)
			ui.possede.TextColor3 = if s.q > possede(id) then T.Rouge else T.Gris
			ui.boite.Text = tostring(s.q)
		else
			ui.fond.BackgroundColor3 = T.Fond3D
			ui.nom.Text = "Choisir…"
			ui.nom.TextColor3 = T.Gris
			ui.possede.Text = if i == 1 then "Touche pour choisir" else "Ajoute un 2e minerai"
			ui.possede.TextColor3 = T.Gris
		end
		ui.rangee.Visible = id ~= nil
		if ui.retirer then
			ui.retirer.Visible = id ~= nil
		end
	end
	-- proportions
	local a, b = slots[1], slots[2]
	local pa = if total > 0 and a.id then a.q / total else 0
	local pb = if total > 0 and b.id then b.q / total else 0
	propA.BackgroundColor3 = if a.id then Forge.MINERAIS[a.id].couleur else T.Inactif
	propB.BackgroundColor3 = if b.id then Forge.MINERAIS[b.id].couleur else T.Inactif
	TweenService:Create(propA, BOUNCY, {Size = UDim2.fromScale(pa, 1)}):Play()
	TweenService:Create(propB, BOUNCY, {Size = UDim2.fromScale(pb, 1)}):Play()
	texteA.Text = if a.id then string.format("%s %d %%", Forge.MINERAIS[a.id].nom, math.floor(pa * 100 + 0.5)) else ""
	texteB.Text = if b.id then string.format("%d %% %s", math.floor(pb * 100 + 0.5), Forge.MINERAIS[b.id].nom) else ""
end

local function rafraichirApercu()
	local t = Forge.TYPES[typeChoisi]
	local comp = composition()
	local res, erreur = Forge.calculer(typeChoisi, comp)
	local manque: string? = nil
	for _, e in comp do
		if possede(e[1]) < e[2] then
			manque = "Pas assez de " .. Forge.MINERAIS[e[1]].mat
		end
	end
	definirObjet(iconeType, typeChoisi, Color3.fromRGB(168, 174, 186), 0)
	statEnCours.stat = t.stat
	statEnCours.icone = if t.stat == "Dégâts" then "⚔" else "🛡"
	statEnCours.vide = res == nil
	if res then
		definirObjet(vpResultat, typeChoisi, res.couleur, 0.9, res.modele)
		vpResultat.Visible = true
		-- Fond de braise chaud quelle que soit la couleur de l'objet : une épée de charbon ne se perd plus dans le noir
		degradeScene.Color = ColorSequence.new(res.couleur:Lerp(Color3.fromRGB(255, 176, 96), 0.55), Color3.fromRGB(64, 22, 10))
		rayons.BackgroundColor3 = res.couleur:Lerp(Color3.new(1, 1, 1), 0.5)
		nomRes.Text = res.nom
		majStat(res.valeur)
		local parts = {}
		for _, e in res.composition do
			table.insert(parts, string.format("%d%% %s", math.floor(e[2] / res.total * 100 + 0.5), Forge.MINERAIS[e[1]].mat))
		end
		local echelle = Forge.ECHELLES[typeChoisi]
		compoRes.Text = (if res.rang and echelle then string.format("Rang %d/%d · ", res.rang, #echelle) else "")
			.. table.concat(parts, " · ")
		coutActuel.total = res.total
		majPrix(res.prix)
		coutRes.TextColor3 = if pieces() >= res.prix then T.Parchemin else T.Rouge
		if not manque and pieces() < res.prix then
			manque = "Pas assez de pièces"
		end
	else
		vpResultat.Visible = false
		degradeScene.Color = ColorSequence.new(Color3.fromRGB(90, 52, 34), Color3.fromRGB(40, 18, 10))
		rayons.BackgroundColor3 = T.Gris
		nomRes.Text = t.nom .. " ?"
		majStat(0, true)
		compoRes.Text = string.format("De %d à %d minerais", t.min, t.max)
		coutActuel.total = 0
		majPrix(0, true)
	end
	-- badge d'alliage : apparaît (pop + son) quand une recette connue est détectée
	local alliage = res and res.alliage
	badgeAlliage.Visible = alliage ~= nil
	bandeauAlliage.Text = if alliage then "★ ALLIAGE : " .. string.upper(alliage) .. " ★" else ""
	if alliage and alliage ~= dernierAlliage then
		texteAlliage.Text = "★ " .. string.upper(alliage) .. " ★"
		pop(badgeAlliage, 0.4)
		pop(bandeauAlliage, 0.4)
		if gui.Enabled then
			jouer("succes", 1.6)
			UI.gerbe(zoneProp, T.Or, 10, Vector2.new(0.5, 0.2))
		end
	end
	dernierAlliage = alliage
	avis.Text = erreur or manque or ""
	local actif = res ~= nil and manque == nil and not enAttente
	principal.definir(if enAttente then "🔨 …" else "🔨 FORGER", T.Braise, actif)
end

-- Taille des cartes d'objets en pixels, d'après la hauteur visible de la bande : en échelle (RelativeYY),
-- la hauteur suivait celle du canevas automatique, qui grandissait avec elles → cartes géantes, hors de la bande
local function tailleObjet(): UDim2
	local h = math.max(24, inventaire.AbsoluteWindowSize.Y - 10)
	return UDim2.fromOffset(math.floor(h * 3.2), math.floor(h))
end
inventaire:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
	for _, c in cartesObjets do
		c.Size = tailleObjet()
	end
end)

local function rafraichirInventaire()
	for _, c in cartesObjets do
		c:Destroy()
	end
	table.clear(cartesObjets)
	titreInventaire.Text = string.format("TES OBJETS FORGÉS (%d)", #etat.objets)
	vide.Visible = #etat.objets == 0
	local n = #etat.objets
	for i, o in etat.objets do
		local t = Forge.TYPES[o.type]
		local ok, couleur = pcall(Color3.fromHex, o.couleur)
		local c = if ok then couleur else T.Gris
		local carte = creer("Frame", {Name = "Objet", LayoutOrder = -i, Size = tailleObjet(),
			BackgroundColor3 = T.Carte, ZIndex = 4, Parent = inventaire},
			{coin(0.18), trait(c, 2, 0.1), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(160, 150, 140))})
		local case = creer("Frame", {Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.84, 0.84),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = c:Lerp(T.Fond3D, 0.6), ZIndex = 5, Parent = carte}, {coin(0.3)})
		if n - i < 8 then -- 3D pour les 8 plus récents seulement
			local vp = Icones.creer(case)
			vp.ZIndex = 6
			definirObjet(vp, o.type, c, 0, o.modele)
		else
			texte({Text = if t then (t.nom:match(utf8.charpattern) or "?") else "?", Font = Enum.Font.Fantasy, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = case}, 30)
		end
		texte({Text = o.nom, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.33, 0.1), Size = UDim2.fromScale(0.64, 0.46), ZIndex = 5, Parent = carte}, 15)
		texte({Text = o.stat .. " " .. o.valeur, Font = Enum.Font.GothamBold, TextColor3 = T.Or,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.33, 0.58), Size = UDim2.fromScale(0.64, 0.3),
			ZIndex = 5, Parent = carte}, 14)
		cartesObjets[o.id] = carte
	end
end

local function rafraichir()
	rafraichirOnglets()
	rafraichirSlots()
	rafraichirApercu()
end

-- ================= Choix d'un minerai =================
local function fermerChoix()
	panneauChoix.Visible = false
end

local function ouvrirChoix(i: number)
	for _, d in listeChoix:GetChildren() do
		if d:IsA("GuiButton") then
			d:Destroy()
		end
	end
	titreChoix.Text = "Minerai " .. i
	local autre = slots[3 - i].id
	local function ligne(ordre: number, id: string?)
		local m = id and Forge.MINERAIS[id]
		local n = if id then possede(id) else 0
		local dispo = id == nil or (n > 0 and autre ~= id)
		local b = creer("TextButton", {LayoutOrder = ordre, Text = "", AutoButtonColor = false, Size = UDim2.new(1, -6, 0, 50),
			BackgroundColor3 = if dispo then T.Carte else T.Fond3D, ZIndex = 11, Parent = listeChoix},
			{coin(0.2), creer("UIAspectRatioConstraint", {AspectRatio = 6.5, DominantAxis = Enum.DominantAxis.Width}),
			UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(160, 150, 140))})
		UI.rarete(b, if slots[i].id == id then T.Or elseif id then couleurMinerai(id) else T.FerSombre,
			if id then UI.NIVEAUX[MineraisModeles.VISUEL[id].rarete] or 1 else 1)
		local fond = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.5), Size = UDim2.fromScale(0.86, 0.86),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = if id then couleurMinerai(id):Lerp(T.Fond3D, 0.55) else T.Fond3D,
			ZIndex = 12, Parent = b}, {coin(0.5)})
		if id then
			local vp = Icones.minerai(id, fond, {vitesse = if dispo then 0.7 else 0, hauteur = 0.35})
			vp.ZIndex = 13
			if not dispo then
				vp.ImageTransparency = 0.5
			end
		else
			texte({Text = "∅", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = fond}, 30)
		end
		texte({Text = if m then m.nom else "Aucun", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if dispo then T.Parchemin else T.Gris, Position = UDim2.fromScale(0.17, 0.12), Size = UDim2.fromScale(0.5, 0.48),
			ZIndex = 12, Parent = b}, 22)
		if id then
			texte({Text = MineraisModeles.VISUEL[id].rarete, Font = Enum.Font.GothamBold, TextColor3 = couleurMinerai(id),
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.17, 0.6), Size = UDim2.fromScale(0.5, 0.28),
				ZIndex = 12, Parent = b}, 14)
			texte({Text = if autre == id then "déjà utilisé" else "× " .. n, Font = Enum.Font.GothamBlack,
				TextColor3 = if dispo then T.Or else T.Gris, TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.fromScale(0.68, 0.25), Size = UDim2.fromScale(0.29, 0.5), ZIndex = 12, Parent = b}, 22)
		end
		UI.reactif(b, if dispo then 1.03 else 1)
		b.Activated:Connect(function()
			if not dispo then
				jouer("clic", 0.6)
				UI.secouer(b, 5)
				return
			end
			jouer("clic", 1.2)
			if id and slots[i].id ~= id then
				slots[i].q = borne(id, if i == 1 then Forge.TYPES[typeChoisi].min else 1)
			end
			slots[i].id = id
			fermerChoix()
			rafraichir()
			pop(slotsUI[i].carte, 0.8)
			if id then
				UI.gerbe(slotsUI[i].fond, couleurMinerai(id), 10)
			end
		end)
	end
	if i == 2 then
		ligne(0, nil)
	end
	for ordre, id in Forge.ORDRE_FORGE do
		ligne(ordre, id)
	end
	panneauChoix.Visible = true
	pop(panneauChoix, 0.85)
end

-- ================= Interactions =================
for id, o in onglets do
	o.bouton.Activated:Connect(function()
		if typeChoisi ~= id then
			typeChoisi = id
			jouer("clic", 1.1)
			rafraichir()
			pop(scene, 0.92)
			echelleResultat.Scale = 0.4
			TweenService:Create(echelleResultat, BOUNCY, {Scale = 1}):Play()
		end
	end)
end

for i, ui in slotsUI do
	ui.choix.Activated:Connect(function()
		jouer("clic")
		ouvrirChoix(i)
	end)
	local function changer(d: number)
		local id = slots[i].id
		if id then
			local avant = slots[i].q
			slots[i].q = borne(id, slots[i].q + d)
			if slots[i].q == avant then
				UI.secouer(ui.boite, 4)
				jouer("clic", 0.6)
				return
			end
			jouer("clic", if d > 0 then 1.15 else 0.9)
			rafraichir()
			pop(ui.boite, 0.85)
		end
	end
	ui.moins.Activated:Connect(function()
		changer(-1)
	end)
	ui.plus.Activated:Connect(function()
		changer(1)
	end)
	ui.boite.FocusLost:Connect(function()
		local id = slots[i].id
		local n = tonumber(ui.boite.Text)
		if id and n and n == n then
			slots[i].q = borne(id, n)
		end
		rafraichir()
	end)
	if ui.retirer then
		ui.retirer.Activated:Connect(function()
			slots[i].id = nil
			jouer("clic", 0.9)
			rafraichir()
		end)
	end
end
annulerChoix.Activated:Connect(fermerChoix)

local function celebrer(objet: any)
	local ok, couleur = pcall(Color3.fromHex, if type(objet) == "table" then objet.couleur else "")
	local c = if ok then couleur else T.Or
	UI.celebrer(scene, c, "FORGÉ !")
	echelleResultat.Scale = 0
	TweenService:Create(echelleResultat, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local v = Icones.vue(vpResultat)
	if v then
		v.angle -= 6.28
	end
	pop(F.racine, 0.97)
	jouer("succes")
	task.delay(0.15, jouer, "succes", 1.5)
	local carte = type(objet) == "table" and cartesObjets[objet.id]
	if carte then
		inventaire.CanvasPosition = Vector2.zero
		pop(carte, 0.5)
		UI.gerbe(carte, c, 8)
	end
end

-- Cinématique de forge (ForgeCinematique.client pose l'attribut ForgeCinematique) : fenêtre masquée pendant,
-- rendue après ; si elle ne démarre pas dans la seconde, ou dure plus de 10 s, on reprend la main
local function attendreCinematique()
	local debut = os.clock()
	gui.Enabled = false
	while not joueur:GetAttribute("ForgeCinematique") and os.clock() - debut < 1 do
		task.wait()
	end
	while joueur:GetAttribute("ForgeCinematique") and os.clock() - debut < 10 do
		task.wait(0.1)
	end
	gui.Enabled = F.estOuverte()
end

boutonForger.Activated:Connect(function()
	if enAttente or not boutonForger.Active then
		return
	end
	local comp = composition()
	enAttente = true
	rafraichirApercu()
	-- coups de marteau pendant que le serveur forge (anticipation)
	task.spawn(function()
		for k = 1, 2 do
			jouer("metal", 0.6 + k * 0.1)
			UI.secouer(scene, 4 + k * 2)
			UI.gerbe(scene, T.Braise, 6, Vector2.new(0.5, 0.75))
			task.wait(0.18)
		end
	end)
	local ok, rep = pcall(function()
		return fnAction:InvokeServer({action = "forger", type = typeChoisi, composition = comp})
	end)
	task.wait(0.3)
	local reussi = ok and type(rep) == "table" and rep.ok == true
	if reussi then
		attendreCinematique()
	end
	enAttente = false
	if ok and type(rep) == "table" then
		if type(rep.etat) == "table" then
			etat = rep.etat
		end
		message(tostring(rep.message), reussi)
	else
		message("Brom n'a pas répondu, réessaie", false)
	end
	for _, s in slots do
		if s.id then
			if possede(s.id) == 0 then
				s.id = nil
			else
				s.q = borne(s.id, s.q)
			end
		end
	end
	rafraichirInventaire()
	rafraichir()
	if reussi then
		celebrer(rep.objet)
	else
		jouer("clic", 0.6)
		UI.secouer(boutonForger, 10)
		local rouge = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Rouge, BackgroundTransparency = 0.3, ZIndex = 10,
			Parent = boutonForger}, {coin(0.22)})
		TweenService:Create(rouge, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.delay(0.5, rouge.Destroy, rouge)
	end
end)

-- ================= Ouverture / fermeture =================
F.surFermeture.Event:Connect(function()
	decor.arreter()
	fermerChoix()
	-- réactivée un peu après (comme les autres invites coupées par InterfaceMine) : le E qui ferme ne rouvre pas
	task.delay(0.25, function()
		if promptForge and not F.estOuverte() then
			promptForge.Enabled = true
		end
	end)
end)

local function ouvrirForge(nouvelEtat: Etat, part: BasePart)
	etat = nouvelEtat
	pointForge = part
	promptForge = part:FindFirstChildOfClass("ProximityPrompt")
	if promptForge then
		promptForge.Enabled = false -- cache l'invite chez ce joueur tant que la forge est ouverte
	end
	for _, s in slots do
		if s.id and possede(s.id) == 0 then
			s.id = nil
		elseif s.id then
			s.q = borne(s.id, s.q)
		end
	end
	if not slots[1].id then
		local meilleur, n = nil, 0
		for _, id in Forge.ORDRE_FORGE do
			if possede(id) > n and slots[2].id ~= id then
				meilleur, n = id, possede(id)
			end
		end
		if meilleur then
			slots[1].id, slots[1].q = meilleur, borne(meilleur, Forge.TYPES[typeChoisi].min)
		end
	end
	dernierAlliage = nil
	rafraichirInventaire()
	rafraichir()
	F.ouvrir()
	decor.demarrer()
end

evOuvrir.OnClientEvent:Connect(function(nouvelEtat: any, part: any)
	if type(nouvelEtat) == "table" and type(nouvelEtat.minerais) == "table" and type(nouvelEtat.objets) == "table"
		and typeof(part) == "Instance" and part:IsA("BasePart") then
		ouvrirForge(nouvelEtat, part)
	end
end)

-- Fermeture au clavier / manette : touche d'interaction (E / X), gérée par InterfaceMine.fenetre

-- Les pièces changent (minage, autre achat) : bourse et bouton Forger se mettent à jour
task.spawn(function()
	local stats = joueur:WaitForChild("leaderstats", 30)
	local v = stats and stats:WaitForChild("Pièces", 30)
	if v and v:IsA("IntValue") then
		majBourse(v.Value, true)
		v.Changed:Connect(function(n)
			majBourse(n)
			if F.estOuverte() then
				rafraichirApercu()
			end
		end)
	end
end)

-- On s'éloigne de Brom ou on meurt : la forge se ferme
task.spawn(function()
	while true do
		task.wait(0.3)
		if F.estOuverte() then
			local perso = joueur.Character
			local racine = perso and perso:FindFirstChild("HumanoidRootPart")
			local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
			if not (racine and racine:IsA("BasePart") and humanoid and humanoid.Health > 0 and pointForge and pointForge.Parent)
				or (racine.Position - pointForge.Position).Magnitude > DISTANCE_FERMETURE then
				F.fermerFenetre()
			end
		end
	end
end)
