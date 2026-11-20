--!strict
-- Boutique de pioches de Liesel · SCRIPT CLIENT (le HUD)
-- S'ouvre quand le serveur le demande (le joueur a parlé à Liesel). Affiche le catalogue,
-- demande les achats au serveur et affiche sa réponse : aucun calcul d'argent ici.
-- Thème et effets : InterfaceMine ; pioches 3D : IconesObjets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Icones = require(script.Parent:WaitForChild("IconesObjets"))
local evOuvrir = ReplicatedStorage:WaitForChild("BoutiqueOuvrir") :: RemoteEvent
local fnAction = ReplicatedStorage:WaitForChild("BoutiqueAction") :: RemoteFunction

local joueur = Players.LocalPlayer

type Etat = {possedees: {[string]: boolean}, equipee: string}

local T = UI.T
local creer, coin, trait, texte, jouer, pop, milliers = UI.creer, UI.coin, UI.trait, UI.texte, UI.jouer, UI.pop, UI.milliers
local FAST, BOUNCY = UI.FAST, UI.BOUNCY
local DISTANCE_FERMETURE = 16
local PUISSANCE_MAX = Pioches.LISTE[#Pioches.LISTE].puissance
local VITESSE_MAX = 1 / Pioches.LISTE[#Pioches.LISTE].recharge
local NOIR = Color3.new(0, 0, 0)

-- ================= Fenêtre =================
local gui = creer("ScreenGui", {Name = "BoutiqueLiesel", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 10, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui")})

local F = UI.fenetre(gui, {nom = "Liesel", role = "FABRICANTE D'OUTILS · L'ATELIER", service = "Outils", couleur = Color3.fromRGB(120, 200, 255),
	repliques = {"Une bonne pioche, c'est la moitié du filon !", "Touche pas au tranchant, il est tout frais.",
		"Chaque pioche ici, je l'ai forgée de mes mains.", "Plus loin tu creuses, plus belle il te la faut."}})
local boucles = F.boucles
local majBourse = UI.bourse(F.droite)
local message = UI.toast(gui)

-- Liste des pioches (à gauche)
local liste = creer("ScrollingFrame", {Name = "Liste", Size = UDim2.fromScale(0.34, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = F.contenu}, {
	creer("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
	creer("UIPadding", {PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}),
})
-- AutomaticCanvasSize ne suit pas toujours les cartes : on règle la hauteur défilable à la main (molette).
do
	local disposition = liste:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	local function majCanevas()
		liste.CanvasSize = UDim2.fromOffset(0, disposition.AbsoluteContentSize.Y + 12)
	end
	liste.AutomaticCanvasSize = Enum.AutomaticSize.None
	disposition:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(majCanevas)
	majCanevas()
end

-- Fiche détaillée (à droite)
local fiche = UI.panneau({Name = "Fiche", Position = UDim2.fromScale(0.36, 0), Size = UDim2.fromScale(0.64, 1),
	BackgroundColor3 = Color3.fromRGB(44, 34, 28), ZIndex = 3, Parent = F.contenu}, 0.04)
creer("UIPadding", {PaddingLeft = UDim.new(0.025, 0), PaddingRight = UDim.new(0.025, 0), PaddingTop = UDim.new(0.035, 0),
	PaddingBottom = UDim.new(0.035, 0), Parent = fiche})

-- Scène de l'aperçu : rayons qui tournent, halo, socle, pioche 3D
local scene = creer("CanvasGroup", {Name = "Scene", Size = UDim2.fromScale(0.47, 0.79), BackgroundColor3 = T.Fond3D, ZIndex = 4,
	Parent = fiche}, {coin(0.07), trait(T.OrFonce, 2), creer("UIGradient", {Name = "Fond", Rotation = 90})})
local degradeScene = scene:FindFirstChild("Fond") :: UIGradient
local roue = creer("Frame", {Name = "Rayons", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromScale(2.4, 2.4), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1, Parent = scene})
local NB_RAYONS = 14
local rayons: {Frame} = {}
for i = 1, NB_RAYONS do
	table.insert(rayons, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(if i % 2 == 0 then 0.05 else 0.09, 1), Rotation = (i - 1) * 180 / NB_RAYONS,
		BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Parent = roue}, {
		creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1)})}),
	}))
end
local halos: {Frame} = {}
for i, t in {0.45, 0.68, 0.86} do
	table.insert(halos, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.25 + i * 0.2, 0.25 + i * 0.2), SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = t, Parent = scene}, {coin(0.5)}))
end
creer("Frame", {Name = "Ombre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.62, 0.07),
	BackgroundColor3 = NOIR, BackgroundTransparency = 0.45, Parent = scene}, {coin(0.5)})
local apercu = Icones.creer(scene)
apercu.Name, apercu.Active, apercu.ZIndex = "Apercu", true, 2
local echelleApercu = UI.echelle(apercu)
local eclat = creer("Frame", {Name = "Eclat", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1, ZIndex = 3, Parent = scene})
local bandeau = texte({Name = "Bandeau", Font = Enum.Font.Fantasy, TextColor3 = Color3.fromRGB(255, 214, 64), Text = "",
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.03), Size = UDim2.fromScale(0.96, 0.14), ZIndex = 4,
	Parent = scene}, 30)
creer("UIStroke", {Thickness = 2.5, Color = Color3.fromRGB(30, 50, 140), Parent = bandeau})
local astuce = texte({Name = "Astuce", Text = "⟲ glisse pour tourner", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
	TextTransparency = 0.35, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.97),
	Size = UDim2.fromScale(0.8, 0.065), ZIndex = 4, Parent = scene}, 13)
creer("UIStroke", {Thickness = 1.5, Transparency = 0.5, Parent = astuce})
UI.boucle(roue, TweenInfo.new(30, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
UI.boucle(halos[1], TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}, boucles)

-- Colonne d'infos
local col = creer("Frame", {Name = "Infos", Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.5, 0.79),
	BackgroundTransparency = 1, ZIndex = 4, Parent = fiche})
local nomPioche = texte({Name = "Nom", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.15), ZIndex = 4, Parent = col}, 36)
UI.dore(nomPioche)
local badge = creer("Frame", {Name = "Rarete", Position = UDim2.fromScale(0, 0.165), Size = UDim2.fromScale(0.62, 0.085),
	BackgroundColor3 = T.Gris, ZIndex = 4, Parent = col}, {coin(0.5), trait(NOIR, 1.5, 0.5),
	UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))})
local rarete = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(20, 14, 10), Position = UDim2.fromScale(0.06, 0.12),
	Size = UDim2.fromScale(0.88, 0.76), ZIndex = 5, Parent = badge}, 18)
local description = texte({Name = "Description", Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0, 0.28), Size = UDim2.fromScale(1, 0.24), ZIndex = 4, Parent = col}, 16)

-- Une stat : valeur animée, écart avec la pioche équipée (▲ vert / ▼ rouge), barre et repère « ta pioche »
type Stat = {barre: Frame, fantome: Frame, ecart: TextLabel, maj: (number, boolean?) -> (), cache: boolean}
local function ligneStat(y: number, libelle: string, format: (number) -> string): Stat
	texte({Text = libelle, Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(0.36, 0.065), ZIndex = 4, Parent = col}, 15)
	local ecart = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Vert, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0.36, y), Size = UDim2.fromScale(0.3, 0.065), ZIndex = 4, Parent = col}, 15)
	local valeur = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.66, y), Size = UDim2.fromScale(0.34, 0.065), ZIndex = 4, Parent = col}, 17)
	local rail = creer("Frame", {Position = UDim2.fromScale(0, y + 0.075), Size = UDim2.fromScale(1, 0.045),
		BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = col}, {coin(0.5), trait(T.FerSombre, 1.5)})
	local fantome = creer("Frame", {Name = "Equipee", Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Parchemin,
		BackgroundTransparency = 0.78, ZIndex = 4, Parent = rail}, {coin(0.5)})
	local barre = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Or, ZIndex = 5, Parent = rail}, {coin(0.5),
		UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(160, 160, 160))})
	local s: Stat = {barre = barre, fantome = fantome, ecart = ecart, maj = function() end, cache = false}
	s.maj = UI.compteur(valeur, function(n)
		return if s.cache then "???" else format(n)
	end)
	return s
end
local statPuissance = ligneStat(0.55, "PUISSANCE", function(n)
	return string.format("×%.1f", n)
end)
local statVitesse = ligneStat(0.72, "VITESSE", function(n)
	return string.format("%.1f coups/s", n)
end)

local comparaison = creer("Frame", {Name = "Comparaison", Position = UDim2.fromScale(0, 0.89), Size = UDim2.fromScale(1, 0.11),
	BackgroundColor3 = T.Fond3D, BackgroundTransparency = 0.3, ZIndex = 4, Parent = col}, {coin(0.3)})
local vignetteEquipee = Icones.creer(creer("Frame", {Position = UDim2.fromScale(0.02, 0.05), Size = UDim2.fromScale(0.9, 0.9),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 5, Parent = comparaison}))
vignetteEquipee.ZIndex = 5
local texteComparaison = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.2, 0.15), Size = UDim2.fromScale(0.78, 0.7), ZIndex = 5, Parent = comparaison}, 14)

local principal = UI.boutonPrincipal({Name = "Bouton", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0.17), ZIndex = 4, Parent = fiche}, boucles)
local bouton = principal.bouton

-- ================= Rotation de l'aperçu (glisser) =================
local glisse: Vector3? = nil
local derniereMain = 0
apercu.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		glisse = input.Position
		TweenService:Create(astuce, FAST, {TextTransparency = 1}):Play()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	local depart = glisse
	local v = Icones.vue(apercu)
	if depart and v and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - depart
		v.angle -= d.X * 0.012
		v.hauteur = math.clamp(v.hauteur + d.Y * 0.008, -0.9, 0.9)
		v.vitesse = 0
		glisse = input.Position
		derniereMain = os.clock()
		Icones.placer(apercu)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		glisse = nil
	end
end)

-- ================= État et rendu =================
local etat: Etat = {possedees = {[Pioches.DEPART] = true}, equipee = Pioches.DEPART}
local selection = Pioches.DEPART
local positionLiesel: Vector3? = nil
local enAttente = false
type Carte = {bouton: TextButton, statut: TextLabel, nom: TextLabel, rarete: TextLabel, bande: Frame, fond: Frame,
	vignette: ViewportFrame, trait: UIStroke}
local cartes: {[string]: Carte} = {}
local enDevoilement: {[string]: boolean} = {}

local function pieces(): number
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Pièces")
	return if v and v:IsA("IntValue") then v.Value else 0
end

local function rangSuivant(): number?
	for i, def in Pioches.LISTE do
		if not etat.possedees[def.id] then
			return i
		end
	end
	return nil
end

local function revelee(id: string): boolean
	if enDevoilement[id] then
		return false
	end
	if etat.possedees[id] then
		return true
	end
	local r = rangSuivant()
	return r ~= nil and Pioches.LISTE[r].id == id
end

type EtatBouton = {texte: string, couleur: Color3, actif: boolean, action: string?}
local function etatBouton(def: Pioches.Pioche): EtatBouton
	if etat.equipee == def.id then
		return {texte = "✔ ÉQUIPÉE", couleur = T.Gris, actif = false}
	elseif etat.possedees[def.id] then
		return {texte = "⚒ ÉQUIPER", couleur = Color3.fromRGB(70, 140, 220), actif = true, action = "equiper"}
	end
	local avant = Pioches.precedente(def.id)
	if not revelee(def.id) then
		return {texte = "🔒 PIOCHE INCONNUE", couleur = Color3.fromRGB(46, 40, 38), actif = false}
	elseif avant and not etat.possedees[avant.id] then
		return {texte = "🔒 D'ABORD : " .. string.upper(avant.nom), couleur = Color3.fromRGB(90, 80, 72), actif = false}
	elseif pieces() < def.prix then
		return {texte = "IL MANQUE " .. milliers(def.prix - pieces()) .. " ◉", couleur = Color3.fromRGB(150, 60, 50), actif = false}
	end
	return {texte = "ACHETER · " .. milliers(def.prix) .. " ◉", couleur = T.Vert, actif = true, action = "acheter"}
end

local function majStat(s: Stat, valeur: number, equipee: number, max: number, format: string, couleur: Color3, cachee: boolean)
	TweenService:Create(s.fantome, FAST, {Size = UDim2.fromScale(equipee / max, 1)}):Play()
	s.cache = cachee
	if cachee then
		s.maj(0, true)
		s.ecart.Text = ""
		TweenService:Create(s.barre, FAST, {Size = UDim2.fromScale(0, 1)}):Play()
		return
	end
	s.maj(valeur)
	local d = valeur - equipee
	local avant = s.ecart.Text
	if math.abs(d) < 1e-3 then
		s.ecart.Text = "="
		s.ecart.TextColor3 = T.Gris
	else
		s.ecart.Text = (if d > 0 then "▲ +" else "▼ ") .. string.format(format, d)
		s.ecart.TextColor3 = if d > 0 then T.Vert else T.Rouge
	end
	if s.ecart.Text ~= avant then
		pop(s.ecart, 0.6)
	end
	TweenService:Create(s.barre, BOUNCY, {Size = UDim2.fromScale(valeur / max, 1), BackgroundColor3 = couleur}):Play()
end

local function colorerScene(def: Pioches.Pioche, cachee: boolean)
	local fondA, fondB, rayon
	if cachee then
		fondA, fondB, rayon = Color3.fromRGB(70, 140, 235), Color3.fromRGB(235, 70, 45), Color3.fromRGB(225, 240, 255)
	else
		local c = Pioches.RARETES[def.rarete] or T.Or
		fondA, fondB, rayon = c:Lerp(T.Fond3D, 0.35), def.lueur:Lerp(T.Fond3D, 0.7), c:Lerp(Color3.new(1, 1, 1), 0.55)
	end
	degradeScene.Color = ColorSequence.new(fondA, fondB)
	for _, r in rayons do
		r.BackgroundColor3 = rayon
	end
	for _, h in halos do
		h.BackgroundColor3 = if cachee then Color3.new(1, 1, 1) else rayon
	end
end

local function afficherModele(def: Pioches.Pioche, cachee: boolean)
	Icones.definir(apercu, "pioche", def.id, {silhouette = cachee, vitesse = 0.8, marge = 1.0, hauteur = 0.15})
	colorerScene(def, cachee)
end

local function rafraichirFiche()
	local def = Pioches.get(selection) :: Pioches.Pioche
	local cachee = not revelee(def.id)
	local couleurRarete = Pioches.RARETES[def.rarete] or T.Gris
	local eq = Pioches.get(etat.equipee) or def
	if cachee then
		nomPioche.Text = "???"
		rarete.Text = "RARETÉ INCONNUE"
		badge.BackgroundColor3 = T.Inactif
		description.Text = "Personne ne l'a encore vue... Achète la pioche d'avant pour la découvrir."
		bandeau.Text = "QUELLE EST CETTE PIOCHE ?"
	else
		nomPioche.Text = def.nom
		rarete.Text = string.upper(def.rarete) .. "  " .. string.rep("★", UI.NIVEAUX[def.rarete] or 1)
		badge.BackgroundColor3 = couleurRarete
		description.Text = def.description
		if not enDevoilement[def.id] and bandeau:GetAttribute("Revelation") ~= def.id then
			bandeau.Text = ""
		end
	end
	majStat(statPuissance, def.puissance, eq.puissance, PUISSANCE_MAX, "%.1f", couleurRarete, cachee)
	majStat(statVitesse, 1 / def.recharge, 1 / eq.recharge, VITESSE_MAX, "%.2f", couleurRarete, cachee)
	Icones.definir(vignetteEquipee, "pioche", eq.id, {vitesse = 0, hauteur = 0.1})
	texteComparaison.Text = if eq.id == def.id then "C'est ta pioche actuelle" else "Comparée à ta " .. eq.nom
	local b = etatBouton(def)
	principal.definir(if enAttente then "…" else b.texte, b.couleur, b.actif and not enAttente)
end

local function rafraichirListe()
	for _, def in Pioches.LISTE do
		local c = cartes[def.id]
		if not c then
			continue
		end
		local choisie = def.id == selection
		local vue = revelee(def.id)
		local couleurRarete = Pioches.RARETES[def.rarete] or T.Gris
		UI.rarete(c.bouton, if vue then couleurRarete else Color3.fromRGB(110, 30, 26), if vue then UI.NIVEAUX[def.rarete] or 1 else 1, boucles)
		c.trait.Color = if choisie then T.Or elseif vue then couleurRarete else Color3.fromRGB(110, 30, 26)
		c.trait.Thickness = if choisie then 3.5 else c.trait.Thickness
		c.bouton.BackgroundColor3 = if not vue then (if choisie then Color3.fromRGB(30, 22, 22) else Color3.fromRGB(14, 11, 10))
			elseif choisie then T.CarteClaire else T.Carte
		c.nom.Text = if vue then def.nom else "???"
		c.nom.TextColor3 = if vue then T.Parchemin else T.Gris
		c.rarete.Text = if vue then def.rarete else "Inconnue"
		c.rarete.TextColor3 = if vue then couleurRarete else Color3.fromRGB(90, 84, 80)
		c.bande.BackgroundColor3 = if vue then couleurRarete else Color3.fromRGB(40, 36, 36)
		c.fond.BackgroundColor3 = if vue then couleurRarete:Lerp(T.Fond3D, 0.55) else Color3.fromRGB(150, 40, 30)
		Icones.definir(c.vignette, "pioche", def.id, {silhouette = not vue, vitesse = 0, hauteur = 0.1})
		local v = Icones.vue(c.vignette)
		if v then
			v.vitesse = if choisie then 0.9 else 0
		end
		if not vue then
			c.statut.Text = "🔒"
			c.statut.TextColor3 = T.Gris
		elseif etat.equipee == def.id then
			c.statut.Text = "ÉQUIPÉE"
			c.statut.TextColor3 = T.Vert
		elseif etat.possedees[def.id] then
			c.statut.Text = "POSSÉDÉE"
			c.statut.TextColor3 = T.Parchemin
		else
			c.statut.Text = milliers(def.prix) .. " ◉"
			c.statut.TextColor3 = if pieces() >= def.prix then T.Or else T.Gris
		end
	end
end

local function rafraichir()
	rafraichirListe()
	rafraichirFiche()
end

local function choisir(id: string)
	if selection == id then
		return
	end
	selection = id
	jouer("clic", 1.2)
	afficherModele(Pioches.get(id) :: Pioches.Pioche, not revelee(id))
	rafraichir()
	pop(scene, 0.92)
	echelleApercu.Scale = 0.5
	TweenService:Create(echelleApercu, BOUNCY, {Scale = 1}):Play()
end

-- Cartes de la liste (dans l'ordre de progression), numérotées comme un carnet de collection
for i, def in Pioches.LISTE do
	local carte = creer("TextButton", {Name = def.id, LayoutOrder = i, Text = "", AutoButtonColor = false,
		Size = UDim2.new(1, -6, 0, 60), BackgroundColor3 = T.Carte, ZIndex = 3, Parent = liste},
		{coin(0.2), creer("UIAspectRatioConstraint", {AspectRatio = 4, DominantAxis = Enum.DominantAxis.Width}),
		UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(175, 165, 160))})
	local tr = UI.rarete(carte, T.Gris, 1, boucles)
	local bande = creer("Frame", {Name = "Bande", Position = UDim2.fromScale(0.012, 0.15), Size = UDim2.fromScale(0.018, 0.7),
		BorderSizePixel = 0, ZIndex = 4, Parent = carte}, {coin(0.5)})
	local fond = creer("Frame", {Name = "Fond", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.045, 0.5),
		Size = UDim2.fromScale(0.82, 0.82), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 4, Parent = carte},
		{coin(0.3), trait(NOIR, 1.5, 0.4), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(60, 50, 50))})
	local vignette = Icones.creer(fond)
	vignette.ZIndex = 5
	texte({Text = string.format("N°%02d", i), Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.1), Size = UDim2.fromScale(0.2, 0.24), ZIndex = 4, Parent = carte}, 12)
	local nom = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.32), Size = UDim2.fromScale(0.47, 0.36), ZIndex = 4, Parent = carte}, 20)
	local rar = texte({Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.68), Size = UDim2.fromScale(0.47, 0.22), ZIndex = 4, Parent = carte}, 13)
	local statut = texte({Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.73, 0.3), Size = UDim2.fromScale(0.24, 0.4), ZIndex = 4, Parent = carte}, 16)
	cartes[def.id] = {bouton = carte, statut = statut, nom = nom, rarete = rar, bande = bande, fond = fond, vignette = vignette, trait = tr}
	UI.reactif(carte, 1.04)
	carte.MouseEnter:Connect(function()
		local v = Icones.vue(vignette)
		if v then
			v.vitesse = 2
		end
		TweenService:Create(tr, FAST, {Thickness = 4}):Play()
	end)
	carte.MouseLeave:Connect(function()
		local v = Icones.vue(vignette)
		if v then
			v.vitesse = if def.id == selection then 0.9 else 0
		end
		TweenService:Create(tr, FAST, {Thickness = if def.id == selection then 3.5 else 1 + math.min(UI.NIVEAUX[def.rarete] or 1, 4) * 0.5}):Play()
	end)
	carte.Activated:Connect(function()
		choisir(def.id)
	end)
end

-- ================= Révélation d'une nouvelle pioche =================
local function devoiler(def: Pioches.Pioche)
	local c = cartes[def.id]
	enDevoilement[def.id] = true
	selection = def.id
	afficherModele(def, true)
	rafraichir()
	bandeau:SetAttribute("Revelation", def.id)
	bandeau.Text = "QUELLE EST CETTE PIOCHE ?"
	pop(bandeau)
	if c then
		liste.CanvasPosition = Vector2.new(0, math.max(0, c.bouton.AbsolutePosition.Y - liste.AbsolutePosition.Y
			+ liste.CanvasPosition.Y - liste.AbsoluteSize.Y * 0.4))
		for _, r in {-4, 4, -3, 3, 0} do
			TweenService:Create(c.bouton, TweenInfo.new(0.06), {Rotation = r}):Play()
			task.wait(0.06)
		end
	end
	for k = 1, 3 do
		jouer("metal", 0.7 + k * 0.15)
		UI.secouer(scene, 3 + k * 2)
		task.wait(0.3)
	end
	enDevoilement[def.id] = nil
	if not gui.Enabled then
		return
	end
	afficherModele(def, false)
	rafraichir()
	UI.celebrer(scene, Pioches.RARETES[def.rarete] or T.Or)
	bandeau.Text = "★ " .. string.upper(def.nom) .. " ★"
	pop(bandeau, 0.5)
	echelleApercu.Scale = 0.2
	TweenService:Create(echelleApercu, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if c then
		pop(c.bouton, 0.8)
	end
	jouer("succes", 1.35)
	message("Nouvelle pioche découverte : " .. def.nom .. " !", true)
	task.delay(2.5, function()
		if bandeau:GetAttribute("Revelation") == def.id then
			bandeau:SetAttribute("Revelation", nil)
			if selection ~= def.id or revelee(def.id) then
				bandeau.Text = if revelee(selection) then "" else "QUELLE EST CETTE PIOCHE ?"
			end
		end
	end)
end

-- ================= Achat / équipement (le serveur décide) =================
bouton.Activated:Connect(function()
	if enAttente or not bouton.Active then
		return
	end
	local def = Pioches.get(selection) :: Pioches.Pioche
	local b = etatBouton(def)
	if not b.action then
		return
	end
	jouer("clic")
	enAttente = true
	rafraichirFiche()
	local ok, rep = pcall(function()
		return fnAction:InvokeServer({action = b.action, id = def.id})
	end)
	enAttente = false
	if ok and type(rep) == "table" and type(rep.etat) == "table" then
		etat = rep.etat
		message(tostring(rep.message), rep.ok == true)
		if rep.ok then
			jouer("succes", if b.action == "acheter" then 1 else 1.3)
			UI.celebrer(scene, def.lueur, if b.action == "acheter" then "ACHETÉE !" else "ÉQUIPÉE !")
			echelleApercu.Scale = 1.25
			TweenService:Create(echelleApercu, BOUNCY, {Scale = 1}):Play()
			pop(F.racine, 0.97)
			if b.action == "acheter" then
				local r = rangSuivant()
				local suivante = r and Pioches.LISTE[r]
				if suivante then
					enDevoilement[suivante.id] = true
					task.delay(1.6, devoiler, suivante)
				end
			end
		else
			jouer("clic", 0.6)
			UI.secouer(bouton)
		end
	else
		message("Liesel n'a pas répondu, réessaie", false)
		UI.secouer(bouton)
	end
	rafraichir()
end)

-- ================= Ouverture / fermeture =================
local rotation: RBXScriptConnection? = nil

F.surFermeture.Event:Connect(function()
	if rotation then
		rotation:Disconnect()
		rotation = nil
	end
end)

local function ouvrirBoutique(nouvelEtat: Etat, position: Vector3)
	etat = nouvelEtat
	positionLiesel = position
	selection = etat.equipee
	for _, def in Pioches.LISTE do
		if not etat.possedees[def.id] then
			selection = def.id
			break
		end
	end
	table.clear(enDevoilement)
	bandeau:SetAttribute("Revelation", nil)
	afficherModele(Pioches.get(selection) :: Pioches.Pioche, not revelee(selection))
	rafraichir()
	astuce.TextTransparency = 0.35
	if F.estOuverte() then
		return
	end
	F.ouvrir()
	rotation = RunService.RenderStepped:Connect(function(dt)
		local v = Icones.vue(apercu)
		if v and not glisse and os.clock() - derniereMain > 1.5 then
			v.vitesse = 0.8
			v.hauteur += (0.15 - v.hauteur) * math.min(1, dt * 2)
		end
	end)
end

evOuvrir.OnClientEvent:Connect(function(nouvelEtat: any, position: any)
	if type(nouvelEtat) == "table" and typeof(position) == "Vector3" then
		ouvrirBoutique(nouvelEtat, position)
	end
end)

UserInputService.InputBegan:Connect(function(input, traite)
	if F.estOuverte() and (input.KeyCode == Enum.KeyCode.ButtonB or (not traite and input.KeyCode == Enum.KeyCode.Q)) then
		F.fermerFenetre()
	end
end)

-- Pièces : compteur qui défile + boutons qui se mettent à jour
local function suivrePieces()
	local stats = joueur:WaitForChild("leaderstats", 30)
	local v = stats and stats:WaitForChild("Pièces", 30)
	if not (v and v:IsA("IntValue")) then
		return
	end
	majBourse(v.Value, true)
	v.Changed:Connect(function(n)
		majBourse(n)
		if F.estOuverte() then
			rafraichir()
		end
	end)
end
task.spawn(suivrePieces)

-- On s'éloigne de Liesel ou on meurt : la boutique se ferme
task.spawn(function()
	while true do
		task.wait(0.3)
		if F.estOuverte() then
			local perso = joueur.Character
			local racine = perso and perso:FindFirstChild("HumanoidRootPart")
			local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
			if not (racine and racine:IsA("BasePart") and humanoid and humanoid.Health > 0 and positionLiesel)
				or (racine.Position - positionLiesel).Magnitude > DISTANCE_FERMETURE then
				F.fermerFenetre()
			end
		end
	end
end)

-- ================= Invite « Voir les pioches » / « Forger » quand on s'approche d'un PNJ =================
-- Le serveur crée l'invite (ProximityPrompt, attribut Theme = "Boutique") ; on la dessine ici.
-- Clavier : E · manette : X · mobile : on touche la carte.
local invites: {[ProximityPrompt]: BillboardGui} = {}

local function toucheAffichee(prompt: ProximityPrompt, typeEntree: Enum.ProximityPromptInputType): string
	if typeEntree == Enum.ProximityPromptInputType.Gamepad then
		return (prompt.GamepadKeyCode.Name:gsub("^Button", ""))
	elseif typeEntree == Enum.ProximityPromptInputType.Touch then
		return "👆"
	end
	local s = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	return if s ~= "" then s else prompt.KeyboardKeyCode.Name
end

local function montrerInvite(prompt: ProximityPrompt, typeEntree: Enum.ProximityPromptInputType)
	if prompt:GetAttribute("Theme") ~= "Boutique" or invites[prompt] then
		return
	end
	local bb = creer("BillboardGui", {Name = "InviteBoutique", Adornee = prompt.Parent, AlwaysOnTop = true,
		Size = UDim2.fromOffset(300, 76), StudsOffset = Vector3.new(0, 1.5, 0), LightInfluence = 0,
		ResetOnSpawn = false, Enabled = not gui.Enabled, Parent = joueur:WaitForChild("PlayerGui")})
	local carte = creer("TextButton", {Name = "Carte", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bois, Parent = bb},
		{coin(0.22), trait(T.Fer, 3), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 130))})
	local echelle = creer("UIScale", {Scale = 0.6, Parent = carte})
	local touche = creer("Frame", {Name = "Touche", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5),
		Size = UDim2.fromScale(0.68, 0.68), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or,
		Parent = carte}, {coin(0.25), trait(T.OrFonce, 2), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(200, 170, 120))})
	texte({Text = toucheAffichee(prompt, typeEntree), Font = Enum.Font.GothamBlack, TextColor3 = T.BoisSombre,
		Position = UDim2.fromScale(0.15, 0.15), Size = UDim2.fromScale(0.7, 0.7), Parent = touche}, 30)
	texte({Text = prompt.ActionText, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.14), Size = UDim2.fromScale(0.68, 0.42), Parent = carte}, 24)
	texte({Text = prompt.ObjectText, Font = Enum.Font.GothamBold, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.58), Size = UDim2.fromScale(0.68, 0.28), Parent = carte}, 16)
	TweenService:Create(echelle, BOUNCY, {Scale = 1}):Play()
	carte.MouseEnter:Connect(function()
		TweenService:Create(echelle, FAST, {Scale = 1.06}):Play()
	end)
	carte.MouseLeave:Connect(function()
		TweenService:Create(echelle, FAST, {Scale = 1}):Play()
	end)
	carte.Activated:Connect(function()
		prompt:InputHoldBegin()
		prompt:InputHoldEnd()
	end)
	invites[prompt] = bb
end

local function cacherInvite(prompt: ProximityPrompt)
	local bb = invites[prompt]
	if not bb then
		return
	end
	invites[prompt] = nil
	local carte = bb:FindFirstChild("Carte")
	local echelle = carte and carte:FindFirstChildOfClass("UIScale")
	if echelle then
		TweenService:Create(echelle, FAST, {Scale = 0.5}):Play()
	end
	task.delay(0.15, function()
		bb:Destroy()
	end)
end

-- L'invite arrive du serveur en style Default (visible même si ce script plante) : on la passe en
-- Custom chez ce joueur seulement, maintenant que le dessin ci-dessus est prêt.
local function adopter(d: Instance)
	if d:IsA("ProximityPrompt") and d:GetAttribute("Theme") == "Boutique" then
		d.Style = Enum.ProximityPromptStyle.Custom
	end
end
for _, d in workspace:GetDescendants() do
	adopter(d)
end
workspace.DescendantAdded:Connect(adopter)

ProximityPromptService.PromptShown:Connect(montrerInvite)
ProximityPromptService.PromptHidden:Connect(cacherInvite)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local bb = invites[prompt]
	local carte = bb and bb:FindFirstChild("Carte")
	if carte and carte:IsA("GuiObject") then
		pop(carte)
	end
end)
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	for _, bb in invites do
		bb.Enabled = not gui.Enabled
	end
end)
