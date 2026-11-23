--!strict
-- Thème « mine premium » partagé par les interfaces des PNJ (StarterPlayerScripts › Jeu › InterfaceMine) :
-- cadre bois sombre + fer riveté, fond de pierre chaud, braises animées, portrait 3D du PNJ,
-- boutons à effets, compteurs animés, sons, célébrations. Utilisé par Boutique.client et Forge.client.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Curseur = require(script.Parent:WaitForChild("Curseur"))

local UI = {}

-- Touche d'interaction des PNJ (celle qui ouvre les fenêtres) : sert aussi à les fermer
local TOUCHES_INTERACTION = {[Enum.KeyCode.E] = true, [Enum.KeyCode.ButtonX] = true}
-- Invites (ProximityPrompt) actuellement affichées chez ce joueur, pour pouvoir les couper sans parcourir le workspace
local invitesVisibles: {[ProximityPrompt]: boolean} = {}
-- Pendant qu'une fenêtre de PNJ est ouverte, les invites E proches sont coupées chez ce joueur (E sert alors
-- à fermer, sans rouvrir la fenêtre derrière). État partagé par toutes les fenêtres du module.
local invitesCoupees: {[ProximityPrompt]: boolean} = {}
local fenetresOuvertes = 0
local function couperInvite(p: ProximityPrompt)
	if p.Enabled and TOUCHES_INTERACTION[p.KeyboardKeyCode] then
		p.Enabled = false
		invitesCoupees[p] = true
	end
end
ProximityPromptService.PromptShown:Connect(function(p)
	invitesVisibles[p] = true
	if fenetresOuvertes > 0 then
		couperInvite(p) -- invite apparue pendant qu'une fenêtre est ouverte
	end
end)
ProximityPromptService.PromptHidden:Connect(function(p)
	invitesVisibles[p] = nil
end)
local function couperInvites()
	fenetresOuvertes += 1
	for p in invitesVisibles do
		couperInvite(p)
	end
end
local function reactiverInvites()
	fenetresOuvertes = math.max(0, fenetresOuvertes - 1)
	task.delay(0.25, function()
		if fenetresOuvertes > 0 then
			return -- une fenêtre est (re)ouverte : on les rendra à la dernière fermeture
		end
		for p in invitesCoupees do
			if p.Parent then
				p.Enabled = true
			end
		end
		table.clear(invitesCoupees)
	end)
end

UI.T = {
	Voile = Color3.fromRGB(6, 4, 3),
	Bois = Color3.fromRGB(64, 40, 25),
	BoisSombre = Color3.fromRGB(34, 22, 15),
	Pierre = Color3.fromRGB(40, 34, 31),
	Carte = Color3.fromRGB(52, 40, 32),
	CarteClaire = Color3.fromRGB(74, 56, 42),
	Fer = Color3.fromRGB(78, 80, 88),
	FerSombre = Color3.fromRGB(30, 30, 34),
	Rivet = Color3.fromRGB(170, 170, 178),
	Or = Color3.fromRGB(255, 204, 92),
	OrFonce = Color3.fromRGB(168, 112, 40),
	Parchemin = Color3.fromRGB(240, 226, 200),
	Gris = Color3.fromRGB(156, 144, 132),
	Vert = Color3.fromRGB(92, 204, 100),
	Rouge = Color3.fromRGB(236, 84, 66),
	Braise = Color3.fromRGB(255, 120, 36),
	Fond3D = Color3.fromRGB(16, 12, 10),
	Inactif = Color3.fromRGB(78, 70, 64),
}
local T = UI.T

UI.FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
UI.BOUNCY = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
UI.DOUX = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FAST, BOUNCY = UI.FAST, UI.BOUNCY

UI.NIVEAUX = {Commun = 1, ["Peu commun"] = 2, Rare = 3, ["Légendaire"] = 4, Mythique = 5, Divin = 6}

-- ================= Outils =================
function UI.creer(classe: string, props: {[string]: any}, enfants: {Instance}?): any
	local i: any = Instance.new(classe)
	for k, v in props do
		if k ~= "Parent" then
			i[k] = v
		end
	end
	for _, e in enfants or {} do
		e.Parent = i
	end
	if props.Parent then
		i.Parent = props.Parent
	end
	return i
end
local creer = UI.creer

function UI.coin(r: number): UICorner
	return creer("UICorner", {CornerRadius = UDim.new(r, 0)})
end
local coin = UI.coin

function UI.trait(couleur: Color3, epaisseur: number, transp: number?): UIStroke
	return creer("UIStroke", {Color = couleur, Thickness = epaisseur, Transparency = transp or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local trait = UI.trait

function UI.degrade(a: Color3, b: Color3, rotation: number?): UIGradient
	return creer("UIGradient", {Rotation = rotation or 90, Color = ColorSequence.new(a, b)})
end

function UI.texte(props: {[string]: any}, tailleMax: number?): TextLabel
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or T.Parchemin
	local l = creer("TextLabel", props)
	creer("UITextSizeConstraint", {MaxTextSize = tailleMax or 40, MinTextSize = 7, Parent = l})
	return l
end
local texte = UI.texte

-- Texte doré en relief (titres)
function UI.dore(l: TextLabel, epaisseur: number?)
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 200)),
		ColorSequenceKeypoint.new(0.5, T.Or), ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 120, 36))}), Parent = l})
	creer("UIStroke", {Thickness = epaisseur or 2, Color = Color3.fromRGB(36, 18, 8), Parent = l})
end

function UI.milliers(n: number): string
	local s = tostring(math.floor(n))
	local res = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (res:gsub("^ ", ""))
end

-- ================= Sons =================
-- swoosh.wav n'est plus livré avec Studio (« Asset is not approved ») : l'ouverture utilise un glissement de lame aigu
local SONS = {
	clic = {"rbxasset://sounds/clickfast.wav", 0.5},
	survol = {"rbxasset://sounds/clickfast.wav", 0.15},
	ouvrir = {"rbxasset://sounds/unsheath.wav", 0.22},
	succes = {"rbxasset://sounds/electronicpingshort.wav", 0.6},
	metal = {"rbxasset://sounds/button.wav", 0.55},
}
local sons: {[string]: Sound} = {}
for nom, s in SONS do
	sons[nom] = creer("Sound", {Name = "UI_" .. nom, SoundId = s[1], Volume = s[2], Parent = SoundService})
end
function UI.jouer(nom: string, vitesse: number?)
	local s = sons[nom]
	if s then
		s.PlaybackSpeed = (vitesse or 1) * (0.95 + math.random() * 0.1)
		SoundService:PlayLocalSound(s)
	end
end
local jouer = UI.jouer

-- ================= Petits effets =================
local function echelleDe(o: GuiObject): UIScale
	return o:FindFirstChildOfClass("UIScale") or creer("UIScale", {Parent = o})
end
UI.echelle = echelleDe

function UI.pop(o: GuiObject, depart: number?)
	local e = echelleDe(o)
	e.Scale = depart or 0.88
	TweenService:Create(e, BOUNCY, {Scale = 1}):Play()
end
local pop = UI.pop

function UI.secouer(o: GuiObject, force: number?)
	if o:GetAttribute("Secoue") then
		return
	end
	o:SetAttribute("Secoue", true)
	local base = o.Position
	local f = force or 8
	task.spawn(function()
		for i = 1, 6 do
			local d = f * (1 - i / 7) * (if i % 2 == 0 then 1 else -1)
			o.Position = base + UDim2.fromOffset(d, if i % 3 == 0 then d * 0.3 else 0)
			task.wait(0.035)
		end
		o.Position = base
		o:SetAttribute("Secoue", nil)
	end)
end

-- Survol + appui pour n'importe quel bouton (échelle, son discret)
function UI.reactif(b: GuiButton, survol: number?, cible: GuiObject?)
	local e = echelleDe(cible or b)
	local s = survol or 1.04
	b.MouseEnter:Connect(function()
		if b.Active then
			TweenService:Create(e, FAST, {Scale = s}):Play()
			jouer("survol", 1.6)
		end
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(e, FAST, {Scale = 1}):Play()
	end)
	b.MouseButton1Down:Connect(function()
		if b.Active then
			TweenService:Create(e, TweenInfo.new(0.08), {Scale = 0.93}):Play()
		end
	end)
	b.MouseButton1Up:Connect(function()
		-- bouton devenu inactif pendant l'appui (achat en cours, quête acceptée) : il ne reste pas grossi
		TweenService:Create(e, BOUNCY, {Scale = if b.Active then s else 1}):Play()
	end)
end

-- Boucle infinie (dégradés qui défilent, halos qui tournent) : jouée seulement quand la fenêtre est ouverte
function UI.boucle(objet: Instance, info: TweenInfo, props: {[string]: any}, liste: {Tween})
	table.insert(liste, TweenService:Create(objet, info, props))
end

-- Compteur animé : renvoie une fonction (valeur, instantane?)
function UI.compteur(l: TextLabel, format: (number) -> string): (number, boolean?) -> ()
	local v = Instance.new("NumberValue")
	local cible = 0
	v.Changed:Connect(function(n)
		l.Text = format(n)
	end)
	l.Text = format(0)
	return function(n: number, instantane: boolean?)
		if n == cible and not instantane then
			return
		end
		cible = n
		if instantane then
			v.Value = n
			l.Text = format(n)
		else
			TweenService:Create(v, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Value = n}):Play()
		end
	end
end

-- Liseré de rareté : couleur du tier, reflet tournant dès « Rare »
-- (boucles = nil pour un élément éphémère : le reflet tourne sans être gardé dans la liste)
function UI.rarete(o: GuiObject, couleur: Color3, niveau: number, boucles: {Tween}?): UIStroke
	local s = (o:FindFirstChild("Rarete") :: UIStroke?) or creer("UIStroke", {Name = "Rarete", ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o})
	s.Color = couleur
	s.Thickness = 1 + math.min(niveau, 4) * 0.5
	local g = s:FindFirstChild("Reflet") :: UIGradient?
	if niveau >= 3 and not g then
		local ng = creer("UIGradient", {Name = "Reflet", Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.45, 0.4), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.55, 0.4),
			NumberSequenceKeypoint.new(1, 0.6)}), Parent = s})
		local t = TweenService:Create(ng, TweenInfo.new(4 - math.min(niveau, 6) * 0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
		if boucles then
			table.insert(boucles, t)
		end
		t:Play()
		g = ng
	end
	if g then
		g.Enabled = niveau >= 3
		g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, couleur), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, couleur)})
	end
	return s
end

-- Ombre douce au sol sous un objet 3D (fondue sur les bords : ne fait plus « barre grise »)
function UI.ombre(parent: Instance, y: number, largeur: number): Frame
	return creer("Frame", {Name = "Ombre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y),
		Size = UDim2.fromScale(largeur, 0.06), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0,
		Parent = parent}, {coin(0.5), creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)})})})
end

-- Petit rivet de fer (cercle bombé)
function UI.rivet(parent: Instance, pos: UDim2, taille: number?): Frame
	return creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromScale(taille or 0.022, taille or 0.022),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Rivet, ZIndex = 6, Parent = parent},
		{coin(0.5), trait(T.FerSombre, 1.5), creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(90, 90, 96))})})
end

-- Bande de fer horizontale rivetée
function UI.bandeFer(parent: Instance, pos: UDim2, taille: UDim2, nbRivets: number): Frame
	local b = creer("Frame", {Position = pos, Size = taille, BackgroundColor3 = T.Fer, BorderSizePixel = 0, ZIndex = 5, Parent = parent},
		{trait(T.FerSombre, 1.5), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 208)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(130, 130, 138)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 66))})})})
	for i = 1, nbRivets do
		UI.rivet(b, UDim2.fromScale((i - 0.5) / nbRivets, 0.5), 0.55)
	end
	return b
end

-- Panneau intérieur (pierre sombre, bord de fer)
function UI.panneau(props: {[string]: any}, arrondi: number?): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or T.Carte
	return creer("Frame", props, {coin(arrondi or 0.05), trait(T.FerSombre, 2, 0.1),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 245, 235), Color3.fromRGB(170, 150, 135))})})
end

-- ================= Bouton principal (ACHETER / FORGER) =================
export type BoutonPrincipal = {bouton: TextButton, texte: TextLabel, definir: (string, Color3, boolean) -> ()}
function UI.boutonPrincipal(props: {[string]: any}, boucles: {Tween}): BoutonPrincipal
	props.Text, props.AutoButtonColor = "", false
	props.BackgroundColor3 = props.BackgroundColor3 or T.Vert
	local b = creer("TextButton", props, {coin(0.22), trait(Color3.fromRGB(24, 14, 8), 3),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 225, 225)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140))})})})
	creer("Frame", {Name = "Reflet", Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.94, 0.38), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = b}, {coin(0.5)})
	local halo = creer("Frame", {Name = "Halo", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = b},
		{coin(0.22), trait(T.Or, 5, 0.4)})
	local haloTrait = halo:FindFirstChildOfClass("UIStroke") :: UIStroke
	UI.boucle(haloTrait, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.9, Thickness = 2}, boucles)
	local brillance = creer("CanvasGroup", {Name = "Brillance", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = b}, {coin(0.22)})
	local trace = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.2, 0.5), Size = UDim2.fromScale(0.12, 3),
		Rotation = 20, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = brillance},
		{creer("UIGradient", {Rotation = 0, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})})
	UI.boucle(trace, TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, -1, false, 0.6), {Position = UDim2.fromScale(1.2, 0.5)}, boucles)
	local l = texte({Name = "Texte", Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.56), ZIndex = 3, Parent = b}, 34)
	creer("UIStroke", {Thickness = 2.5, Color = Color3.fromRGB(24, 14, 8), Transparency = 0.15, Parent = l})
	UI.reactif(b, 1.035)
	local function definir(txt: string, couleur: Color3, actif: boolean)
		l.Text = txt
		b.Active = actif
		TweenService:Create(b, FAST, {BackgroundColor3 = if actif then couleur else couleur:Lerp(T.Inactif, 0.75)}):Play()
		halo.Visible, brillance.Visible = actif, actif
		l.TextTransparency = if actif then 0 else 0.25
	end
	return {bouton = b, texte = l, definir = definir}
end

-- ================= Célébration / éclats =================
function UI.gerbe(scene: GuiObject, couleur: Color3, nombre: number?, centre: Vector2?)
	local c = centre or Vector2.new(0.5, 0.5)
	local n = nombre or 20
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + math.random() * 0.4
		local t = 0.025 + math.random() * 0.035
		local e = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c.X, c.Y), Size = UDim2.fromScale(t, t * 2.2),
			SizeConstraint = Enum.SizeConstraint.RelativeXX, Rotation = math.deg(a) + 90, BorderSizePixel = 0,
			BackgroundColor3 = if i % 3 == 0 then Color3.new(1, 1, 1) else couleur:Lerp(Color3.new(1, 1, 1), math.random() * 0.4),
			ZIndex = 20, Parent = scene}, {coin(0.4)})
		local d = 0.35 + math.random() * 0.3
		TweenService:Create(e, TweenInfo.new(0.7 + math.random() * 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(c.X + math.cos(a) * d, c.Y + math.sin(a) * d + 0.08),
			BackgroundTransparency = 1, Rotation = math.deg(a) + 300, Size = UDim2.fromScale(t * 0.4, t * 0.4),
		}):Play()
		Debris:AddItem(e, 1.2)
	end
end

function UI.celebrer(scene: GuiObject, couleur: Color3, texteTampon: string?)
	local flash = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 19, Parent = scene})
	TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(flash, 0.7)
	for k = 0, 1 do
		local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 20, Parent = scene},
			{coin(0.5), trait(if k == 0 then couleur else Color3.new(1, 1, 1), 6 - k * 3)})
		local s = anneau:FindFirstChildOfClass("UIStroke") :: UIStroke
		local info = TweenInfo.new(0.7 + k * 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, k * 0.08)
		TweenService:Create(anneau, info, {Size = UDim2.fromScale(1.6, 1.6)}):Play()
		TweenService:Create(s, info, {Transparency = 1, Thickness = 0}):Play()
		Debris:AddItem(anneau, 1.1)
	end
	UI.gerbe(scene, couleur, 24)
	if texteTampon then
		UI.tampon(scene, texteTampon)
	end
end

-- Tampon doré qui s'écrase puis s'envole (« ACHETÉE ! », « VENDU ! ») ; peut être posé sur un cadre plus grand que la scène
function UI.tampon(parent: GuiObject, txt: string, y: number?, hauteur: number?)
	local y0 = y or 0.22
	local t = texte({Text = txt, Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y0),
		Size = UDim2.fromScale(0.9, hauteur or 0.2), Rotation = -6, ZIndex = 21, Parent = parent}, 60)
	UI.dore(t, 3)
	local e = echelleDe(t)
	e.Scale = 2.4
	t.TextTransparency = 1
	TweenService:Create(e, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(t, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	task.delay(1.4, function()
		TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1, Position = UDim2.fromScale(0.5, y0 - 0.12)}):Play()
		Debris:AddItem(t, 0.5)
	end)
end

-- ================= Messages : cartes de notification empilées (bas de l'écran) =================
-- Une seule pile partagée par toutes les interfaces (ScreenGui « NotificationsMine ») : les messages de scripts
-- différents s'empilent au lieu de s'écraser. Icônes dessinées en Frames (aucune image ni emoji).
local NOTIF_RATIO = 7.2 -- largeur / hauteur d'une carte
local NOTIF_MAX = 3 -- cartes visibles en même temps
local NOTIF_ECART = 6 -- pixels entre deux cartes
local NOTIF_MEDAILLON_X = 0.42 / NOTIF_RATIO + 0.014 -- centre du médaillon (échelle X de la carte)
local BLANC = Color3.new(1, 1, 1)
local NOIR = Color3.new(0, 0, 0)
local BRUN = Color3.fromRGB(40, 22, 10)

type TonNotif = {accent: Color3, clair: Color3, fond: Color3, fondHaut: Color3, chiffre: string, titre: string?}
local TONS_NOTIF: {[string]: TonNotif} = {
	succes = {accent = Color3.fromRGB(255, 186, 64), clair = Color3.fromRGB(255, 236, 168), fond = Color3.fromRGB(28, 18, 11),
		fondHaut = Color3.fromRGB(80, 52, 26), chiffre = "#FFD45C"},
	erreur = {accent = Color3.fromRGB(240, 84, 54), clair = Color3.fromRGB(255, 188, 150), fond = Color3.fromRGB(30, 13, 10),
		fondHaut = Color3.fromRGB(88, 30, 20), chiffre = "#FFC27A", titre = "ATTENTION"},
	info = {accent = Color3.fromRGB(150, 186, 214), clair = Color3.fromRGB(226, 238, 248), fond = Color3.fromRGB(20, 22, 26),
		fondHaut = Color3.fromRGB(54, 60, 68), chiffre = "#FFD45C", titre = "INFO"},
}
local TITRES_NOTIF: {[string]: string} = {piece = "BUTIN", pepite = "MINERAI", coffre = "TRÉSOR", flamme = "FOURNAISE",
	wagon = "WAGONNET", quete = "QUÊTE", gemme = "RELIQUE", etoile = "ÉVÉNEMENT", ok = "RÉUSSITE"}
-- Mots-clés (texte en minuscules) → icône ; la première ligne qui correspond gagne
local MOTS_NOTIF: {{string}} = {
	{"piece", "pièce", "piece"},
	{"coffre", "coffre", "trésor"},
	{"quete", "quête", "quete", "guilde"},
	{"gemme", "relique", "cristal", "gemme", "rune", "diamant", "rubis", "émeraude", "saphir"},
	{"flamme", "lave", "%f[%w]feux?%f[%W]", "fonderie", "braise", "flamme", "magma", "creuset", "fournaise"},
	{"wagon", "wagon", "en voiture", "terminus", "%f[%w]rails?%f[%W]"},
	{"pepite", "minerai", "%f[%w]fer%f[%W]", "%f[%w]or%f[%W]", "bronze", "cuivre", "veine", "lingot", "pépite", "charbon"},
}
local function iconeDuTexteNotif(txt: string): string?
	local bas = string.lower(txt)
	for _, ligne in MOTS_NOTIF do
		for k = 2, #ligne do
			if string.find(bas, ligne[k]) then
				return ligne[1]
			end
		end
	end
	return nil
end

-- Nombres du message en gras doré (RichText ; le texte brut est échappé d'abord)
local function texteRicheNotif(txt: string, couleur: string): string
	local s = string.gsub(txt, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, "[%+%-]?%d+", '<font color="' .. couleur .. '"><b>%0</b></font>')
	return s
end

-- ---- Dessin des icônes (boîte carrée, coordonnées en échelle 0..1) ----
local function formeNotif(parent: Instance, x: number, y: number, l: number, h: number, couleur: Color3, enfants: {Instance}?, rotation: number?): Frame
	return creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(l, h),
		Rotation = rotation or 0, BackgroundColor3 = couleur, BorderSizePixel = 0, Parent = parent}, enfants)
end
local function bombeNotif(rotation: number?): UIGradient -- relief « métal bombé » (multiplie la couleur)
	return creer("UIGradient", {Rotation = rotation or 60, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, BLANC),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 135, 135))})})
end
local function barreNotif(b: Instance, x: number, y: number, l: number, couleur: Color3, rotation: number)
	formeNotif(b, x, y, l, 0.16, couleur, {coin(0.5), trait(BRUN, 1.5)}, rotation)
end
local function refletNotif(b: Instance, x: number, y: number, l: number, h: number, rotation: number?)
	formeNotif(b, x, y, l, h, BLANC, {coin(0.5)}, rotation).BackgroundTransparency = 0.35
end

local OR_CLAIR = Color3.fromRGB(255, 224, 124)
local DESSINS_NOTIF: {[string]: (Frame, Color3) -> ()} = {
	ok = function(b, encre)
		barreNotif(b, 0.32, 0.6, 0.32, encre, 45)
		barreNotif(b, 0.6, 0.48, 0.62, encre, -48)
	end,
	croix = function(b, encre)
		barreNotif(b, 0.5, 0.5, 0.82, encre, 45)
		barreNotif(b, 0.5, 0.5, 0.82, encre, -45)
	end,
	info = function(b, encre)
		formeNotif(b, 0.5, 0.2, 0.2, 0.2, encre, {coin(0.5), trait(BRUN, 1.5)})
		formeNotif(b, 0.5, 0.64, 0.18, 0.5, encre, {coin(0.5), trait(BRUN, 1.5)})
	end,
	piece = function(b)
		formeNotif(b, 0.5, 0.5, 0.9, 0.9, T.Or, {coin(0.5), trait(T.OrFonce, 1.5), bombeNotif()})
		formeNotif(b, 0.5, 0.5, 0.62, 0.62, T.Or, {coin(0.5), trait(Color3.fromRGB(196, 128, 40), 1.5, 0.15)}).BackgroundTransparency = 1
		formeNotif(b, 0.5, 0.5, 0.13, 0.36, T.OrFonce, {coin(0.5)})
		refletNotif(b, 0.33, 0.28, 0.22, 0.12, -35)
	end,
	pepite = function(b)
		formeNotif(b, 0.42, 0.58, 0.58, 0.5, T.Or, {coin(0.35), trait(T.OrFonce, 1.5), bombeNotif()}, -12)
		formeNotif(b, 0.63, 0.42, 0.42, 0.4, OR_CLAIR, {coin(0.4), trait(T.OrFonce, 1.5), bombeNotif()}, 20)
		refletNotif(b, 0.6, 0.36, 0.12, 0.12, 45)
		formeNotif(b, 0.84, 0.16, 0.05, 0.26, BLANC, {coin(0.5)})
		formeNotif(b, 0.84, 0.16, 0.26, 0.05, BLANC, {coin(0.5)})
	end,
	coffre = function(b)
		local bois = Color3.fromRGB(128, 78, 40)
		formeNotif(b, 0.5, 0.66, 0.88, 0.46, bois, {coin(0.12), trait(BRUN, 1.5), bombeNotif(90)})
		formeNotif(b, 0.5, 0.34, 0.88, 0.32, bois:Lerp(BLANC, 0.1), {coin(0.45), trait(BRUN, 1.5), bombeNotif(90)})
		formeNotif(b, 0.5, 0.47, 0.94, 0.08, T.Fer, {trait(T.FerSombre, 1), bombeNotif(90)})
		formeNotif(b, 0.24, 0.56, 0.08, 0.7, T.Fer, {bombeNotif(0)})
		formeNotif(b, 0.76, 0.56, 0.08, 0.7, T.Fer, {bombeNotif(0)})
		formeNotif(b, 0.5, 0.55, 0.18, 0.22, T.Or, {coin(0.25), trait(T.OrFonce, 1), bombeNotif()})
	end,
	flamme = function(b)
		local function goutte(cx: number, cy: number, r: number, haut: Color3, basC: Color3)
			formeNotif(b, cx, cy, r, r, BLANC, {coin(0.5), UI.degrade(haut, basC, 90)})
			formeNotif(b, cx, cy - r * 0.3, r * 0.72, r * 0.72, BLANC, {coin(0.12), UI.degrade(haut, basC, 45)}, 45)
		end
		goutte(0.5, 0.62, 0.68, Color3.fromRGB(255, 196, 60), Color3.fromRGB(226, 64, 20))
		goutte(0.5, 0.72, 0.36, Color3.fromRGB(255, 248, 200), Color3.fromRGB(255, 190, 70))
	end,
	wagon = function(b)
		local c1 = formeNotif(b, 0.36, 0.26, 0.24, 0.22, T.Or, {coin(0.45), bombeNotif()})
		local c2 = formeNotif(b, 0.6, 0.23, 0.28, 0.26, OR_CLAIR, {coin(0.45), bombeNotif()})
		c1.ZIndex, c2.ZIndex = 1, 1
		formeNotif(b, 0.5, 0.5, 0.82, 0.4, T.Fer, {coin(0.12), trait(T.FerSombre, 1.5), bombeNotif(90)}).ZIndex = 2
		formeNotif(b, 0.5, 0.32, 0.96, 0.1, Color3.fromRGB(120, 122, 130), {coin(0.3), trait(T.FerSombre, 1)}).ZIndex = 3
		for _, x in {0.28, 0.72} do
			formeNotif(b, x, 0.78, 0.26, 0.26, Color3.fromRGB(28, 28, 32), {coin(0.5), trait(T.Rivet, 1.5)}).ZIndex = 4
			formeNotif(b, x, 0.78, 0.09, 0.09, T.Rivet, {coin(0.5)}).ZIndex = 5
		end
	end,
	quete = function(b)
		local brun = Color3.fromRGB(120, 78, 40)
		formeNotif(b, 0.5, 0.52, 0.64, 0.64, T.Parchemin, {coin(0.08), trait(brun, 1.2), bombeNotif(90)})
		formeNotif(b, 0.5, 0.18, 0.82, 0.15, Color3.fromRGB(214, 184, 132), {coin(0.5), trait(brun, 1.2)})
		formeNotif(b, 0.5, 0.86, 0.82, 0.15, Color3.fromRGB(214, 184, 132), {coin(0.5), trait(brun, 1.2)})
		for k, y in {0.38, 0.5, 0.62} do
			formeNotif(b, 0.46, y, if k == 3 then 0.28 else 0.4, 0.05, brun, {coin(0.5)})
		end
		formeNotif(b, 0.68, 0.68, 0.2, 0.2, Color3.fromRGB(190, 40, 36), {coin(0.5), trait(Color3.fromRGB(90, 16, 14), 1), bombeNotif()})
	end,
	gemme = function(b)
		formeNotif(b, 0.5, 0.5, 0.62, 0.62, BLANC, {coin(0.12), trait(Color3.fromRGB(220, 250, 255), 1.5),
			UI.degrade(Color3.fromRGB(150, 236, 255), Color3.fromRGB(70, 90, 230), 0)}, 45)
		formeNotif(b, 0.42, 0.4, 0.24, 0.24, BLANC, {coin(0.1)}, 45).BackgroundTransparency = 0.4
		formeNotif(b, 0.82, 0.18, 0.05, 0.24, BLANC, {coin(0.5)})
		formeNotif(b, 0.82, 0.18, 0.24, 0.05, BLANC, {coin(0.5)})
	end,
	etoile = function(b)
		formeNotif(b, 0.5, 0.5, 0.64, 0.64, T.Or, {coin(0.1), trait(T.OrFonce, 1.5), bombeNotif()})
		formeNotif(b, 0.5, 0.5, 0.64, 0.64, T.Or, {coin(0.1), trait(T.OrFonce, 1.5), bombeNotif()}, 45)
		formeNotif(b, 0.5, 0.5, 0.32, 0.32, Color3.fromRGB(255, 244, 200), {coin(0.5)})
	end,
}

-- ---- Pile de cartes ----
type CarteNotif = {cle: string, groupe: CanvasGroup, echelle: UIScale, contour: UIStroke, reflet: UIGradient, remplissage: Frame,
	badge: Frame, badgeTexte: TextLabel, bouton: TextButton, compte: number, duree: number, minuteur: Tween?, boucles: {Tween},
	ferme: boolean, survol: boolean}
local notifCadre: Frame? = nil
local notifCartes: {CarteNotif} = {}
local notifSons: {[string]: Sound} = {}
local SONS_NOTIF: {[string]: {any}} = {
	succes = {"rbxasset://sounds/electronicpingshort.wav", 0.28, 1.3},
	erreur = {"rbxasset://sounds/button.wav", 0.4, 0.75},
	info = {"rbxasset://sounds/clickfast.wav", 0.3, 1.1},
}
local function jouerNotif(nom: string, vitesse: number?)
	local d = SONS_NOTIF[nom]
	if not d then
		return
	end
	local s = notifSons[nom]
	if not s then
		s = creer("Sound", {Name = "UI_notif_" .. nom, SoundId = d[1], Volume = d[2], Parent = SoundService})
		notifSons[nom] = s
	end
	s.PlaybackSpeed = (vitesse or d[3]) * (0.96 + math.random() * 0.08)
	SoundService:PlayLocalSound(s)
end

local function hauteurNotif(largeur: number): number
	local cadre = notifCadre
	return (if cadre and cadre.AbsoluteSize.X > 1 then cadre.AbsoluteSize.X else 400) * largeur / NOTIF_RATIO
end

-- Range les cartes de bas en haut (la plus récente en bas ; les anciennes, plus petites et plus pâles, remontent)
local function placerNotifs(instantane: boolean?)
	local y = 0
	for i, c in notifCartes do
		local largeur = 1 - (i - 1) * 0.045
		local pos = UDim2.new(0.5, 0, 1, -y)
		local taille = UDim2.fromScale(largeur, 1)
		local transp = if i == 1 then 0 elseif i == 2 then 0.12 else 0.3
		y += hauteurNotif(largeur) + NOTIF_ECART
		if instantane then
			c.groupe.Position, c.groupe.Size, c.groupe.GroupTransparency = pos, taille, transp
		else
			TweenService:Create(c.groupe, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = pos, Size = taille}):Play()
			TweenService:Create(c.groupe, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {GroupTransparency = transp}):Play()
		end
	end
end

local function cadreNotif(): Frame
	local existant = notifCadre
	if existant and existant.Parent and existant.Parent.Parent then
		return existant
	end
	local sg = creer("ScreenGui", {Name = "NotificationsMine", ResetOnSpawn = false, DisplayOrder = 32,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui")})
	local cadre = creer("Frame", {Name = "Pile", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.968),
		Size = UDim2.fromScale(0.5, 0.45), BackgroundTransparency = 1, Active = false, Parent = sg},
		{creer("UISizeConstraint", {MinSize = Vector2.new(280, 0), MaxSize = Vector2.new(540, 400)})})
	notifCadre = cadre
	table.clear(notifCartes)
	cadre:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		placerNotifs()
	end)
	return cadre
end

local function balayerNotif(c: CarteNotif)
	c.reflet.Offset = Vector2.new(-1, 0)
	TweenService:Create(c.reflet, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(1, 0)}):Play()
end

local function fermerNotif(c: CarteNotif)
	if c.ferme then
		return
	end
	c.ferme = true
	local i = table.find(notifCartes, c)
	if i then
		table.remove(notifCartes, i)
	end
	if c.minuteur then
		c.minuteur:Cancel()
	end
	for _, t in c.boucles do
		t:Cancel()
	end
	c.bouton.Visible = false -- ne bloque plus les clics pendant le fondu
	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(c.groupe, info, {GroupTransparency = 1, Position = c.groupe.Position - UDim2.fromOffset(0, 14)}):Play()
	TweenService:Create(c.echelle, info, {Scale = 0.9}):Play()
	Debris:AddItem(c.groupe, 0.35)
	placerNotifs()
end

-- Barre de temps : se vide, la carte part quand elle est vide (en pause pendant le survol à la souris)
local function lancerMinuteurNotif(c: CarteNotif)
	if c.minuteur then
		c.minuteur:Cancel()
	end
	c.remplissage.Size = UDim2.fromScale(1, 1)
	local t = TweenService:Create(c.remplissage, TweenInfo.new(c.duree, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
	c.minuteur = t
	t.Completed:Connect(function(etat)
		if etat == Enum.PlaybackState.Completed and c.minuteur == t then
			fermerNotif(c)
		end
	end)
	t:Play()
	if c.survol then
		t:Pause()
	end
end

-- Étincelles + onde autour du médaillon de la carte du bas (dans la pile, hors CanvasGroup : pas rognées)
local function etincellesNotif(cadre: Frame, ton: TonNotif)
	local w = cadre.AbsoluteSize.X
	local h = w / NOTIF_RATIO
	local centre = UDim2.new(0, w * NOTIF_MEDAILLON_X, 1, -h / 2)
	local anneau = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = centre, Size = UDim2.fromOffset(h * 0.6, h * 0.6),
		BackgroundTransparency = 1, ZIndex = 20, Parent = cadre}, {coin(0.5), trait(ton.clair, 3)})
	local s = anneau:FindFirstChildOfClass("UIStroke") :: UIStroke
	local info = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(anneau, info, {Size = UDim2.fromOffset(h * 1.9, h * 1.9)}):Play()
	TweenService:Create(s, info, {Transparency = 1, Thickness = 0}):Play()
	Debris:AddItem(anneau, 0.6)
	for k = 1, 9 do
		local a = (k / 9) * math.pi * 2 + math.random() * 0.5
		local t = h * (0.08 + math.random() * 0.07)
		local e = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = centre, Size = UDim2.fromOffset(t, t), Rotation = 45,
			BorderSizePixel = 0, BackgroundColor3 = if k % 3 == 0 then BLANC else ton.accent:Lerp(ton.clair, math.random()),
			ZIndex = 21, Parent = cadre})
		local d = h * (0.55 + math.random() * 0.5)
		TweenService:Create(e, TweenInfo.new(0.5 + math.random() * 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = centre + UDim2.fromOffset(math.cos(a) * d, math.sin(a) * d * 0.8 - h * 0.15),
			Size = UDim2.fromOffset(t * 0.3, t * 0.3), Rotation = 225, BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(e, 0.9)
	end
end

local function creerCarteNotif(cadre: Frame, txt: string, nomTon: string, ton: TonNotif, icone: string, cle: string): CarteNotif
	local groupe = creer("CanvasGroup", {Name = "Notification", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, hauteurNotif(1) * 0.9), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		GroupTransparency = 1, Active = false, Parent = cadre},
		{creer("UIAspectRatioConstraint", {AspectRatio = NOTIF_RATIO, DominantAxis = Enum.DominantAxis.Width})})
	local echelle = creer("UIScale", {Scale = 0.86, Parent = groupe})
	-- ombre portée
	creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.992, 0.565), Size = UDim2.fromScale(0.93, 0.8),
		BackgroundColor3 = NOIR, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 1, Parent = groupe}, {coin(0.3)})
	-- carte bois sombre teintée
	local carte = creer("Frame", {Name = "Carte", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.5),
		Size = UDim2.fromScale(0.93, 0.8), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 2, Parent = groupe},
		{coin(0.3), UI.degrade(ton.fondHaut, ton.fond, 90)})
	local contour = creer("UIStroke", {Color = BLANC, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = carte})
	local sombre = ton.accent:Lerp(NOIR, 0.4)
	local lisere = creer("UIGradient", {Offset = Vector2.new(-1, 0), Color = ColorSequence.new({ColorSequenceKeypoint.new(0, sombre),
		ColorSequenceKeypoint.new(0.42, ton.accent), ColorSequenceKeypoint.new(0.5, ton.clair), ColorSequenceKeypoint.new(0.58, ton.accent),
		ColorSequenceKeypoint.new(1, sombre)}), Parent = contour})
	-- lueur chaude derrière le médaillon, veines du bois, filet clair en haut, rivets
	creer("Frame", {Size = UDim2.fromScale(0.55, 1), BackgroundColor3 = ton.accent, BorderSizePixel = 0, Parent = carte}, {coin(0.3),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)})})})
	for _, y in {0.36, 0.68} do
		creer("Frame", {Position = UDim2.fromScale(0.03, y), Size = UDim2.new(0.94, 0, 0, 1), BackgroundColor3 = NOIR,
			BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = carte})
	end
	creer("Frame", {Position = UDim2.fromScale(0.04, 0.07), Size = UDim2.new(0.92, 0, 0, 1), BackgroundColor3 = ton.clair,
		BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = carte}, {creer("UIGradient", {Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1)})})})
	UI.rivet(carte, UDim2.fromScale(0.978, 0.24), 0.13)
	UI.rivet(carte, UDim2.fromScale(0.978, 0.76), 0.13)
	-- reflet qui balaie la carte (dégradé : suit les coins arrondis)
	local voileReflet = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, ZIndex = 8, Parent = carte}, {coin(0.3)})
	local reflet = creer("UIGradient", {Rotation = 15, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.65),
		NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = voileReflet})

	-- médaillon : halo pulsant, disque de fer bordé, icône dessinée
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(NOTIF_MEDAILLON_X, 0.5),
		Size = UDim2.fromScale(0.86, 0.86), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = ton.accent,
		BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 3, Parent = groupe}, {coin(0.5)})
	local medaillon = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(NOTIF_MEDAILLON_X, 0.5),
		Size = UDim2.fromScale(0.84, 0.84), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = BLANC,
		BorderSizePixel = 0, ZIndex = 4, Parent = groupe},
		{coin(0.5), trait(ton.accent, 2.5), UI.degrade(ton.fondHaut:Lerp(ton.accent, 0.3), ton.fond, 90)})
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8),
		BackgroundTransparency = 1, Parent = medaillon}, {coin(0.5), trait(ton.clair, 1, 0.55)})
	local boite = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6),
		BackgroundTransparency = 1, Rotation = -30, Parent = medaillon})
	local echelleIcone = creer("UIScale", {Scale = 0, Parent = boite})
	local dessin = DESSINS_NOTIF[icone] or DESSINS_NOTIF.etoile
	dessin(boite, ton.clair)
	if nomTon == "succes" and icone ~= "ok" then -- pastille ✔ dessinée sur le médaillon
		local pastille = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.84), Size = UDim2.fromScale(0.36, 0.36),
			BackgroundColor3 = ton.accent, BorderSizePixel = 0, Parent = medaillon}, {coin(0.5), trait(BRUN, 1.5), bombeNotif()})
		DESSINS_NOTIF.ok(creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.7, 0.7), BackgroundTransparency = 1, Parent = pastille}), BRUN)
	end

	-- textes : petit titre de catégorie + message (nombres en or)
	UI.texte({Text = ton.titre or TITRES_NOTIF[icone] or "ÉVÉNEMENT", Font = Enum.Font.GothamBlack, TextColor3 = ton.accent,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.155, 0.17), Size = UDim2.fromScale(0.6, 0.2),
		ZIndex = 5, Parent = groupe}, 13)
	local message = UI.texte({Text = texteRicheNotif(txt, ton.chiffre), RichText = true, Font = Enum.Font.GothamMedium,
		TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.155, 0.38),
		Size = UDim2.fromScale(0.79, 0.38), ZIndex = 5, Parent = groupe}, 20)
	creer("UIStroke", {Thickness = 1.2, Color = Color3.fromRGB(14, 8, 4), Transparency = 0.35, Parent = message})

	-- barre de temps
	local rail = creer("Frame", {Position = UDim2.fromScale(0.155, 0.8), Size = UDim2.new(0.8, 0, 0.035, 1), BackgroundColor3 = NOIR,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5, Parent = groupe}, {coin(0.5)})
	local remplissage = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, BorderSizePixel = 0, Parent = rail},
		{coin(0.5), UI.degrade(ton.accent, ton.clair, 0)})

	-- badge « x2 » (message répété)
	local badge = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.95, 0.2), Size = UDim2.fromScale(0.62, 0.36),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, BorderSizePixel = 0, Visible = false, ZIndex = 7,
		Parent = groupe}, {coin(0.5), trait(BRUN, 1.5), bombeNotif(90)})
	local badgeTexte = UI.texte({Text = "x2", Font = Enum.Font.GothamBlack, TextColor3 = BRUN, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.84, 0.78), Parent = badge}, 16)

	-- zone cliquable (seul élément actif : le reste de la pile laisse passer les clics)
	local bouton = creer("TextButton", {Name = "Fermer", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Selectable = false,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.985, 0.5), Size = UDim2.fromScale(0.975, 0.84), ZIndex = 10, Parent = groupe})

	local n = utf8.len(txt) or #txt
	local c: CarteNotif = {cle = cle, groupe = groupe, echelle = echelle, contour = contour, reflet = reflet, remplissage = remplissage,
		badge = badge, badgeTexte = badgeTexte, bouton = bouton, compte = 1, duree = 3 + math.clamp((n - 38) * 0.05, 0, 3),
		minuteur = nil, boucles = {}, ferme = false, survol = false}

	-- boucles de vie : lisere lumineux qui balaie le contour, halo qui respire
	local b1 = TweenService:Create(lisere, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.4), {Offset = Vector2.new(1, 0)})
	local b2 = TweenService:Create(halo, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundTransparency = 0.9, Size = UDim2.fromScale(0.98, 0.98)})
	c.boucles = {b1, b2}
	b1:Play()
	b2:Play()

	-- entrée : la carte glisse et rebondit, l'icône éclate avec une rotation
	TweenService:Create(echelle, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local infoIcone = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.12)
	TweenService:Create(echelleIcone, infoIcone, {Scale = 1}):Play()
	TweenService:Create(boite, infoIcone, {Rotation = 0}):Play()
	if nomTon == "erreur" then
		task.delay(0.4, function()
			if medaillon.Parent then
				UI.secouer(medaillon, 4)
			end
		end)
	end

	-- survol : mise en avant + pause du minuteur (souris) ; clic / tap : ferme
	bouton.MouseEnter:Connect(function()
		if c.ferme or not UserInputService.MouseEnabled then
			return
		end
		c.survol = true
		TweenService:Create(echelle, FAST, {Scale = 1.03}):Play()
		TweenService:Create(contour, FAST, {Thickness = 3}):Play()
		if c.minuteur then
			c.minuteur:Pause()
		end
		balayerNotif(c)
		jouer("survol", 1.6)
	end)
	bouton.MouseLeave:Connect(function()
		c.survol = false
		if c.ferme then
			return
		end
		TweenService:Create(echelle, FAST, {Scale = 1}):Play()
		TweenService:Create(contour, FAST, {Thickness = 2}):Play()
		local m = c.minuteur
		if m and m.PlaybackState == Enum.PlaybackState.Paused then
			m:Play()
		end
	end)
	bouton.Activated:Connect(function()
		jouer("clic", 1.3)
		fermerNotif(c)
	end)
	return c
end

-- local toast = UI.toast(gui) ; toast(texte, ok, genre?)
--   genre (optionnel) : "info" (ton neutre) ou un nom d'icône pour la forcer
--   (piece, pepite, coffre, flamme, wagon, quete, gemme, etoile, ok, croix) ; sinon l'icône est déduite du texte.
-- `gui` est gardé pour la compatibilité : la pile de messages est commune à toutes les interfaces.
function UI.toast(gui: ScreenGui): (string, boolean, string?) -> ()
	local _ = gui
	return function(txt: string, ok: boolean, genre: string?)
		txt = tostring(txt)
		local cadre = cadreNotif()
		local nomTon = if genre == "info" then "info" elseif ok then "succes" else "erreur"
		local ton = TONS_NOTIF[nomTon]
		local icone: string
		if genre and genre ~= "info" and DESSINS_NOTIF[genre] then
			icone = genre
		elseif nomTon == "erreur" then
			icone = "croix"
		else
			icone = iconeDuTexteNotif(txt) or (if nomTon == "info" then "info" else "etoile")
		end
		local cle = nomTon .. "|" .. icone .. "|" .. txt
		-- message identique encore affiché : badge x2, x3… au lieu d'un doublon
		for i, c in notifCartes do
			if c.cle == cle and not c.ferme then
				c.compte += 1
				c.badgeTexte.Text = "x" .. c.compte
				c.badge.Visible = true
				pop(c.badge, 0.3)
				c.echelle.Scale = 1.07
				TweenService:Create(c.echelle, BOUNCY, {Scale = if c.survol then 1.03 else 1}):Play()
				balayerNotif(c)
				lancerMinuteurNotif(c)
				if i ~= 1 then
					table.remove(notifCartes, i)
					table.insert(notifCartes, 1, c)
					placerNotifs()
				end
				jouerNotif(nomTon, 1.2 + math.min(c.compte, 6) * 0.05)
				return
			end
		end
		local c = creerCarteNotif(cadre, txt, nomTon, ton, icone, cle)
		table.insert(notifCartes, 1, c)
		while #notifCartes > NOTIF_MAX do
			fermerNotif(notifCartes[#notifCartes])
		end
		placerNotifs()
		lancerMinuteurNotif(c)
		jouerNotif(nomTon)
		task.delay(0.14, function()
			if not c.ferme then
				etincellesNotif(cadre, ton)
				balayerNotif(c)
			end
		end)
	end
end


-- ================= Portrait 3D du PNJ =================
local pnjConnus: {[string]: Instance} = {} -- mémoire : on ne parcourt le workspace qu'une fois par PNJ
local function trouverPNJ(service: string): Instance?
	local connu = pnjConnus[service]
	if connu and connu:IsDescendantOf(workspace) then
		return connu
	end
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == service then
			pnjConnus[service] = d
			return d
		end
	end
	return nil
end

-- Étendue (min, max) d'un ensemble de pièces le long d'un axe du monde (pièces orientées incluses)
local function etendue(pieces: {BasePart}, axe: Vector3): (number, number)
	local mn, mx = math.huge, -math.huge
	for _, p in pieces do
		local cf, s = p.CFrame, p.Size / 2
		local c = cf.Position:Dot(axe)
		local r = math.abs(cf.RightVector:Dot(axe)) * s.X + math.abs(cf.UpVector:Dot(axe)) * s.Y + math.abs(cf.LookVector:Dot(axe)) * s.Z
		mn, mx = math.min(mn, c - r), math.max(mx, c + r)
	end
	return mn, mx
end

-- Cadrage « photo de profil » : visage entier + haut des épaules, calculé depuis la tête du modèle.
-- Marche pour les nains Blender (« <Nom>_Tete_Peau » dans le sous-modèle « Tete ») et les avatars R15 (« Head »).
local function cadragePortrait(copie: Model, fov: number): (CFrame, Vector3, Vector3, boolean)
	local tete: BasePart? = nil
	local nez: BasePart? = nil
	for _, d in copie:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Head" or string.match(d.Name, "_Tete_Peau$") then
				tete = tete or d
			elseif string.match(d.Name, "_Nez$") then
				nez = nez or d
			end
		end
	end
	-- Direction du regard : vers le nez si on l'a, sinon le HumanoidRootPart, sinon la tête R15, sinon le pivot
	local racine = copie:FindFirstChild("HumanoidRootPart")
	local avant: Vector3
	if tete and nez then
		avant = nez.Position - tete.Position
	elseif racine and racine:IsA("BasePart") then
		avant = racine.CFrame.LookVector
	elseif tete and tete.Name == "Head" then
		avant = tete.CFrame.LookVector
	else
		avant = copie:GetPivot().LookVector
	end
	avant = Vector3.new(avant.X, 0, avant.Z)
	avant = if avant.Magnitude > 0.01 then avant.Unit else Vector3.zAxis
	local droite = avant:Cross(Vector3.yAxis)
	local haut = Vector3.yAxis

	local bas0, haut0 = 0, 0
	if tete then
		bas0, haut0 = etendue({tete}, haut)
	end
	local hTete = haut0 - bas0
	if not tete or hTete < 0.2 or hTete > 8 then
		-- Pas de tête reconnue : ancien cadrage approximatif sur le haut de la boîte
		local cf, taille = copie:GetBoundingBox()
		local h = math.clamp(taille.Y, 3, 9)
		local cible = cf.Position + haut * h * 0.3
		return CFrame.lookAt(cible + avant * (h * 0.22 / math.tan(math.rad(fov / 2))), cible), avant, droite, false
	end
	local t = tete :: BasePart
	-- Coiffe : chapeau, cheveux, casque, cornes (sous-modèle « Tete » ou accessoires collés à la tête)
	local coiffe: {BasePart} = {t}
	local groupe = t.Parent
	if groupe and groupe:IsA("Model") and groupe ~= copie then
		for _, d in groupe:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.95 then
				table.insert(coiffe, d)
			end
		end
	end
	for _, acc in copie:GetDescendants() do
		if acc:IsA("Accessory") then
			local poignee = acc:FindFirstChild("Handle")
			if poignee and poignee:IsA("BasePart") and (poignee.Position - t.Position).Magnitude < t.Size.Magnitude * 1.2 then
				table.insert(coiffe, poignee)
			end
		end
	end
	local _, hautCoiffe = etendue(coiffe, haut)
	local gL, gR = etendue(coiffe, droite)
	local sommet = math.min(math.max(haut0, hautCoiffe), haut0 + hTete * 0.9) + hTete * 0.06
	local pied = bas0 - hTete * 0.42 -- coupé au niveau des épaules
	local largeur = math.min(gR - gL, hTete * 2.2)
	local demi = math.max((sommet - pied) / 2, largeur / 2) * 1.1 -- marge : le médaillon est rond
	local cible = t.Position + haut * ((sommet + pied) / 2 - t.Position:Dot(haut))
	local dir = (avant * math.cos(math.rad(18)) + droite * math.sin(math.rad(18)) + haut * 0.1).Unit
	return CFrame.lookAt(cible + dir * (demi / math.tan(math.rad(fov / 2))), cible), avant, droite, true
end

function UI.portrait(service: string, vp: ViewportFrame): boolean
	if vp:FindFirstChild("Objet") then
		return true
	end
	local pnj = trouverPNJ(service)
	if not (pnj and pnj:IsA("Model")) then
		return false
	end
	local ok, copie = pcall(function()
		pnj.Archivable = true
		return pnj:Clone()
	end)
	if not ok or not copie then
		return false
	end
	for _, d in copie:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("ProximityPrompt")
			or d:IsA("Light") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	local cam = vp.CurrentCamera or creer("Camera", {FieldOfView = 30, Parent = vp})
	vp.CurrentCamera = cam
	local cfCam, avant, droite, teteTrouvee = cadragePortrait(copie, cam.FieldOfView)
	cam.CFrame = cfCam
	-- Gardé en cache (« Objet ») seulement si la tête a été trouvée ; sinon portrait provisoire, retenté à la prochaine ouverture
	local ancien = vp:FindFirstChild("ObjetProvisoire")
	if ancien then
		ancien:Destroy()
	end
	copie.Name = if teteTrouvee then "Objet" else "ObjetProvisoire"
	vp.Ambient, vp.LightColor = Color3.fromRGB(150, 128, 110), Color3.fromRGB(255, 214, 170)
	vp.LightDirection = (-avant + droite * 0.6 - Vector3.yAxis).Unit
	copie.Parent = vp
	return true
end

-- ================= Fenêtre de PNJ =================
export type Fenetre = {
	gui: ScreenGui,
	racine: Frame,
	contenu: Frame,
	droite: Frame,
	fermer: TextButton,
	boucles: {Tween},
	ouvrir: () -> (),
	fermerFenetre: () -> (),
	estOuverte: () -> boolean,
	surFermeture: BindableEvent,
}

type Opts = {nom: string, role: string, service: string, repliques: {string}, couleur: Color3?, initiale: string?}

function UI.fenetre(gui: ScreenGui, o: Opts): Fenetre
	local boucles: {Tween} = {}
	local voile = creer("TextButton", {Name = "Voile", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Voile, BackgroundTransparency = 1, Parent = gui},
		{creer("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0.1)})})})

	local racine = creer("Frame", {Name = "Fenetre", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.88), BackgroundTransparency = 1, Active = true, Parent = gui},
		{creer("UIAspectRatioConstraint", {AspectRatio = 1.62}), creer("UISizeConstraint", {MaxSize = Vector2.new(1000, 617)})})
	local echelle = echelleDe(racine)

	-- Cadre : bois sombre de couleur unie (ni vis ni équerres), liseré chaud discret à l'intérieur
	creer("Frame", {Name = "Cadre", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(56, 34, 21), Parent = racine},
		{coin(0.03), trait(Color3.fromRGB(18, 10, 6), 4)})

	-- Intérieur : pierre chaude (dégradé brun → ambre), appareil de pierres très léger, vignettage, lueur de forge en bas
	local interieur = creer("Frame", {Name = "Interieur", Position = UDim2.fromScale(0.016, 0.026), Size = UDim2.fromScale(0.968, 0.948),
		BackgroundColor3 = T.Pierre, ClipsDescendants = true, ZIndex = 1, Parent = racine},
		{coin(0.02), trait(Color3.fromRGB(20, 13, 9), 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 166, 166)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(236, 220, 206)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 196, 150))})})})
	-- Appareil de pierres taillées (statique, construit une seule fois) : rangées décalées, teintes à peine différentes
	local rng = Random.new(42)
	local RANGEES = 7
	for r = 0, RANGEES - 1 do
		local x = if r % 2 == 0 then 0 else -0.06
		while x < 1 do
			local l = rng:NextNumber(0.1, 0.17)
			creer("Frame", {Position = UDim2.new(x, 2, r / RANGEES, 2), Size = UDim2.new(l, -4, 1 / RANGEES, -4),
				BackgroundColor3 = if rng:NextNumber() < 0.5 then Color3.fromRGB(150, 120, 96) else Color3.new(0, 0, 0),
				BackgroundTransparency = rng:NextNumber(0.9, 0.95), BorderSizePixel = 0, Parent = interieur}, {coin(0.12)})
			x += l
		end
	end
	-- Lumière chaude au centre (comme une lanterne) et vignettage sombre sur les bords
	creer("Frame", {Name = "Lanterne", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(1.1, 1.3),
		BackgroundColor3 = Color3.fromRGB(255, 178, 96), BorderSizePixel = 0, Parent = interieur}, {coin(0.5),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.9),
			NumberSequenceKeypoint.new(1, 1)})})})
	-- {rotation du dégradé (côté opaque d'abord), ancre, taille} : haut, bas, gauche, droite
	for _, v in {{90, Vector2.new(0, 0), UDim2.fromScale(1, 0.22)}, {-90, Vector2.new(0, 1), UDim2.fromScale(1, 0.22)},
		{0, Vector2.new(0, 0), UDim2.fromScale(0.14, 1)}, {180, Vector2.new(1, 0), UDim2.fromScale(0.14, 1)}} do
		local rot, ancre, taille = v[1] :: number, v[2] :: Vector2, v[3] :: UDim2
		creer("Frame", {Name = "Vignette", AnchorPoint = ancre, Position = UDim2.fromScale(ancre.X, ancre.Y), Size = taille,
			BackgroundColor3 = Color3.fromRGB(8, 5, 3), BorderSizePixel = 0, Parent = interieur},
			{creer("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(1, 1)})})})
	end
	local lueur = creer("Frame", {Name = "LueurForge", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.42),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = interieur})
	local gLueur = creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.Braise),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 20))}), Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.7, 0.86), NumberSequenceKeypoint.new(1, 0.66)}), Parent = lueur})
	UI.boucle(gLueur, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0, 0.12)}, boucles)
	local flamme = creer("Frame", {Name = "Defile", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.05),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = interieur})
	local gFlamme = creer("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 20)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 80)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 20)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 170, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 20))}),
		Offset = Vector2.new(-0.5, 0), Parent = flamme})
	UI.boucle(gFlamme, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Offset = Vector2.new(0.5, 0)}, boucles)

	-- En-tête : portrait 3D, nom, rôle, réplique tapée
	local entete = creer("Frame", {Name = "Entete", Size = UDim2.fromScale(1, 0.2), BackgroundTransparency = 1, ZIndex = 3, Parent = interieur})
	local medaillon = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.55), Size = UDim2.fromScale(0.86, 0.86),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, ZIndex = 3, Parent = entete})
	local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3),
		BackgroundColor3 = o.couleur or T.Or, ZIndex = 3, Parent = medaillon}, {coin(0.5),
		creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.3, 1),
			NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 0.1)})})})
	local cadrePortrait = creer("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(60, 40, 28), ZIndex = 4, Parent = medaillon},
		{coin(0.5), trait(T.Or, 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 200, 150), Color3.fromRGB(90, 60, 50))})})
	UI.boucle(halo, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}, boucles)
	local vpPortrait = creer("ViewportFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = cadrePortrait}, {coin(0.5)})
	local initiale = texte({Text = o.initiale or o.nom:sub(1, 1), Font = Enum.Font.Fantasy, Size = UDim2.fromScale(1, 1), ZIndex = 5,
		Parent = cadrePortrait}, 60)
	UI.dore(initiale)

	local nom = texte({Text = string.upper(o.nom), Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.125, 0.06), Size = UDim2.fromScale(0.46, 0.46), ZIndex = 4, Parent = entete}, 52)
	UI.dore(nom, 2.5)
	texte({Text = o.role, Font = Enum.Font.GothamBlack, TextColor3 = o.couleur or T.Or, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.127, 0.5), Size = UDim2.fromScale(0.4, 0.17), ZIndex = 4, Parent = entete}, 18)
	local bulle = texte({Font = Enum.Font.Merriweather, TextColor3 = T.Parchemin, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.127, 0.7), Size = UDim2.fromScale(0.47, 0.2), ZIndex = 4, Parent = entete}, 17)

	local droite = creer("Frame", {Name = "Droite", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.905, 0.18),
		Size = UDim2.fromScale(0.3, 0.6), BackgroundTransparency = 1, ZIndex = 4, Parent = entete})
	-- Bouton fermer : croix dessinée avec deux barres (aucun glyphe de police → jamais de rectangle vide)
	local fermer = creer("TextButton", {Name = "Fermer", Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.99, 0.16),
		Size = UDim2.fromScale(0.6, 0.6), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(150, 44, 32),
		AutoButtonColor = false, ZIndex = 4, Parent = entete}, {coin(0.5), trait(Color3.fromRGB(60, 16, 10), 3),
		UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))})
	local barres: {Frame} = {}
	for _, angle in {45, -45} do
		table.insert(barres, creer("Frame", {Name = "Croix", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.56, 0.13), Rotation = angle, BackgroundColor3 = T.Parchemin, BorderSizePixel = 0, ZIndex = 5,
			Parent = fermer}, {coin(0.5), trait(Color3.fromRGB(60, 16, 10), 1.5, 0.3)}))
	end
	UI.reactif(fermer, 1.1)
	fermer.MouseEnter:Connect(function()
		TweenService:Create(barres[1], FAST, {Rotation = 135}):Play()
		TweenService:Create(barres[2], FAST, {Rotation = 45}):Play()
	end)
	fermer.MouseLeave:Connect(function()
		TweenService:Create(barres[1], FAST, {Rotation = 45}):Play()
		TweenService:Create(barres[2], FAST, {Rotation = -45}):Play()
	end)

	-- Séparateur de l'en-tête : bande unie (plus de rivets)
	creer("Frame", {Name = "Separateur", Position = UDim2.fromScale(0, 0.205), Size = UDim2.fromScale(1, 0.012),
		BackgroundColor3 = Color3.fromRGB(26, 17, 11), BorderSizePixel = 0, ZIndex = 5, Parent = interieur})
	creer("Frame", {Position = UDim2.new(0, 0, 0.217, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.OrFonce,
		BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 5, Parent = interieur})
	local contenu = creer("Frame", {Name = "Contenu", Position = UDim2.fromScale(0.018, 0.25), Size = UDim2.fromScale(0.964, 0.715),
		BackgroundTransparency = 1, ZIndex = 3, Parent = interieur})

	local rideau = creer("Frame", {Name = "Rideau", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Voile, Visible = false, ZIndex = 60,
		Parent = racine}, {coin(0.03)})

	-- Braises qui montent du bas de la fenêtre
	local ouverte = false
	local function braise()
		local t = 0.004 + math.random() * 0.007
		local x = math.random()
		local b = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.02), Size = UDim2.fromScale(t, t),
			SizeConstraint = Enum.SizeConstraint.RelativeXX, BorderSizePixel = 0, ZIndex = 2,
			BackgroundColor3 = Color3.fromRGB(255, 140 + math.random(0, 100), 40 + math.random(0, 60)), Parent = interieur}, {coin(0.5)})
		local duree = 2 + math.random() * 2
		TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.12, 0.35 + math.random() * 0.4),
			BackgroundTransparency = 1, Size = UDim2.fromScale(t * 0.3, t * 0.3)}):Play()
		Debris:AddItem(b, duree)
	end

	local surFermeture = Instance.new("BindableEvent")
	local tweenVoile: Tween? = nil
	local function fermerFenetre()
		if not ouverte then
			return
		end
		ouverte = false
		Curseur.liberer(gui.Name, false)
		for _, t in boucles do
			t:Pause()
		end
		if tweenVoile then
			tweenVoile:Cancel()
		end
		reactiverInvites()
		jouer("ouvrir", 1.3)
		TweenService:Create(echelle, FAST, {Scale = 0.88}):Play()
		TweenService:Create(racine, FAST, {Position = UDim2.fromScale(0.5, 0.56)}):Play()
		rideau.Visible, rideau.BackgroundTransparency = true, 1
		TweenService:Create(rideau, FAST, {BackgroundTransparency = 0}):Play()
		local tv = TweenService:Create(voile, FAST, {BackgroundTransparency = 1})
		tweenVoile = tv
		tv:Play()
		surFermeture:Fire()
		task.delay(0.16, function()
			if not ouverte then
				gui.Enabled = false
			end
		end)
	end

	local session = 0 -- jeton : une seule boucle de braises vivante, même après fermer/rouvrir rapide
	local function ouvrir()
		initiale.Visible = not UI.portrait(o.service, vpPortrait)
		if ouverte then
			return
		end
		ouverte = true
		Curseur.liberer(gui.Name, true)
		session += 1
		local maSession = session
		gui.Enabled = true
		couperInvites()
		for _, t in boucles do
			t:Play()
		end
		if tweenVoile then
			tweenVoile:Cancel()
		end
		echelle.Scale = 0.82
		racine.Position = UDim2.fromScale(0.5, 0.6)
		TweenService:Create(echelle, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(racine, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		rideau.Visible, rideau.BackgroundTransparency = true, 0
		local fondu = TweenService:Create(rideau, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
		fondu.Completed:Connect(function()
			if ouverte then
				rideau.Visible = false
			end
		end)
		fondu:Play()
		local tv = TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.25})
		tweenVoile = tv
		tv:Play()
		jouer("ouvrir")
		local replique = "« " .. o.repliques[math.random(#o.repliques)] .. " »"
		local n = utf8.len(replique) or 40
		bulle.Text = replique
		bulle.MaxVisibleGraphemes = 0
		TweenService:Create(bulle, TweenInfo.new(n * 0.025, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = n}):Play()
		pop(cadrePortrait, 0.6)
		task.spawn(function()
			while ouverte and session == maSession do
				braise()
				task.wait(0.07 + math.random() * 0.1)
			end
		end)
	end

	-- Fermeture : uniquement le bouton rouge ou la touche d'interaction (E / X manette), plus les fermetures
	-- automatiques des scripts (on s'éloigne, on meurt). Cliquer à côté de la fenêtre ne la ferme plus.
	fermer.Activated:Connect(function()
		jouer("clic", 0.9)
		fermerFenetre()
	end)
	UserInputService.InputBegan:Connect(function(input, procese)
		if procese or not ouverte or not TOUCHES_INTERACTION[input.KeyCode] then
			return -- E tapé dans le chat ou une zone de texte : on ignore
		end
		if UserInputService:GetFocusedTextBox() or Players.LocalPlayer:GetAttribute("ForgeCinematique") then
			return -- cinématique de forge en cours : la fenêtre est seulement masquée, on ne la ferme pas
		end
		-- petit délai : l'appui est entièrement traité avant qu'une invite redevienne active (sinon elle rouvrirait)
		task.delay(0.05, fermerFenetre)
	end)

	return {gui = gui, racine = racine, contenu = contenu, droite = droite, fermer = fermer, boucles = boucles,
		ouvrir = ouvrir, fermerFenetre = fermerFenetre, estOuverte = function()
			return ouverte
		end, surFermeture = surFermeture}
end

-- Bourse : pièce dorée + montant animé
function UI.bourse(parent: Instance): (number, boolean?) -> ()
	local b = creer("Frame", {Name = "Bourse", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(1, 0.85),
		BackgroundColor3 = T.Fond3D, ZIndex = 4, Parent = parent}, {coin(0.5), trait(T.OrFonce, 2.5),
		UI.degrade(Color3.fromRGB(255, 230, 200), Color3.fromRGB(120, 100, 90))})
	local piece = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5), Size = UDim2.fromScale(0.78, 0.78),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, ZIndex = 5, Parent = b}, {coin(0.5), trait(T.OrFonce, 2),
		UI.degrade(Color3.fromRGB(255, 250, 210), Color3.fromRGB(200, 130, 30), 45)})
	texte({Text = "◉", TextColor3 = T.OrFonce, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = piece}, 30)
	local montant = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.3, 0.16), Size = UDim2.fromScale(0.62, 0.68), ZIndex = 5, Parent = b}, 30)
	local maj = UI.compteur(montant, UI.milliers)
	return function(n: number, instantane: boolean?)
		if not instantane then
			pop(piece, 0.7)
		end
		maj(n, instantane)
	end
end

return UI
