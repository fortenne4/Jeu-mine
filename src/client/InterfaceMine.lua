--!strict
-- Thème « mine premium » partagé par les interfaces des PNJ (StarterPlayerScripts › Jeu › InterfaceMine) :
-- cadre bois sombre + fer riveté, fond de pierre chaud, braises animées, portrait 3D du PNJ,
-- boutons à effets, compteurs animés, sons, célébrations. Utilisé par Boutique.client et Forge.client.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local UI = {}

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
local SONS = {
	clic = {"rbxasset://sounds/clickfast.wav", 0.5},
	survol = {"rbxasset://sounds/clickfast.wav", 0.15},
	ouvrir = {"rbxasset://sounds/swoosh.wav", 0.45},
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
		TweenService:Create(e, BOUNCY, {Scale = s}):Play()
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
		local t = texte({Text = texteTampon, Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.22),
			Size = UDim2.fromScale(0.9, 0.2), Rotation = -6, ZIndex = 21, Parent = scene}, 60)
		UI.dore(t, 3)
		local e = echelleDe(t)
		e.Scale = 2.4
		t.TextTransparency = 1
		TweenService:Create(e, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(t, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
		task.delay(1.4, function()
			TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1, Position = UDim2.fromScale(0.5, 0.1)}):Play()
			Debris:AddItem(t, 0.5)
		end)
	end
end

-- ================= Message (plaque en bas de l'écran) =================
function UI.toast(gui: ScreenGui): (string, boolean) -> ()
	local plaque = creer("Frame", {Name = "Message", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.94),
		Size = UDim2.fromScale(0.46, 0.055), BackgroundColor3 = T.BoisSombre, Visible = false, ZIndex = 50, Parent = gui},
		{coin(0.35), creer("UISizeConstraint", {MaxSize = Vector2.new(620, 52)})})
	local bord = trait(T.Vert, 2.5)
	bord.Parent = plaque
	local l = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.04, 0.18), Size = UDim2.fromScale(0.92, 0.64),
		ZIndex = 51, Parent = plaque}, 24)
	local id = 0
	return function(txt: string, ok: boolean)
		id += 1
		local moi = id
		l.Text = (if ok then "✔  " else "✖  ") .. txt
		l.TextColor3 = if ok then T.Vert else T.Rouge
		bord.Color = l.TextColor3
		plaque.Visible = true
		plaque.Position = UDim2.fromScale(0.5, 0.99)
		TweenService:Create(plaque, BOUNCY, {Position = UDim2.fromScale(0.5, 0.94)}):Play()
		pop(plaque, 0.7)
		task.delay(2.4, function()
			if moi == id then
				TweenService:Create(plaque, FAST, {Position = UDim2.fromScale(0.5, 1.06)}):Play()
				task.delay(0.16, function()
					if moi == id then
						plaque.Visible = false
					end
				end)
			end
		end)
	end
end

-- ================= Portrait 3D du PNJ =================
local function trouverPNJ(service: string): Instance?
	for _, d in workspace:GetDescendants() do
		if d:GetAttribute("Service") == service then
			return d
		end
	end
	return nil
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
	copie.Name = "Objet"
	local cfBoite, taille = copie:GetBoundingBox()
	local tete = copie:FindFirstChild("Head", true) or copie:FindFirstChild("Tete", true)
	local centre: Vector3
	if tete and tete:IsA("BasePart") then
		centre = tete.Position
	elseif tete and tete:IsA("Model") then
		centre = (tete:GetBoundingBox()).Position
	else
		centre = cfBoite.Position + Vector3.yAxis * taille.Y * 0.36
	end
	local racine = copie:FindFirstChild("HumanoidRootPart")
	local avant = (if racine and racine:IsA("BasePart") then racine.CFrame else copie:GetPivot()).LookVector
	avant = Vector3.new(avant.X, 0, avant.Z)
	avant = if avant.Magnitude > 0.01 then avant.Unit else Vector3.zAxis
	local h = math.clamp(taille.Y, 3, 9)
	local cible = centre - Vector3.yAxis * h * 0.07
	local cam = vp.CurrentCamera or creer("Camera", {FieldOfView = 30, Parent = vp})
	vp.CurrentCamera = cam
	local droite = avant:Cross(Vector3.yAxis)
	cam.CFrame = CFrame.lookAt(cible + avant * (h * 0.22 / math.tan(math.rad(15))) + droite * h * 0.08 + Vector3.yAxis * h * 0.03, cible)
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

	-- Cadre en planches de bois sombre (grain horizontal)
	local grain = {}
	for i = 0, 10 do
		local v = if i % 2 == 0 then 255 - (i * 7) % 30 else 196 + (i * 13) % 26
		table.insert(grain, ColorSequenceKeypoint.new(i / 10, Color3.fromRGB(v, v * 0.97, v * 0.94)))
	end
	creer("Frame", {Name = "Cadre", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bois, Parent = racine},
		{coin(0.03), trait(Color3.fromRGB(18, 10, 6), 4), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(grain)})})
	-- Équerres de fer aux coins
	for _, c in {Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1)} do
		local eq = creer("Frame", {AnchorPoint = c, Position = UDim2.fromScale(c.X, c.Y), Size = UDim2.fromScale(0.085, 0.085),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Fer, ZIndex = 4, Parent = racine},
			{coin(0.18), trait(T.FerSombre, 2), creer("UIGradient", {Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(220, 220, 228), Color3.fromRGB(80, 80, 88))})})
		UI.rivet(eq, UDim2.fromScale(0.5 + (0.5 - c.X) * 0.4, 0.5 + (0.5 - c.Y) * 0.4), 0.28)
	end
	for i = 1, 9 do
		UI.rivet(racine, UDim2.fromScale(0.08 + i * 0.084, 0.012), 0.014)
		UI.rivet(racine, UDim2.fromScale(0.08 + i * 0.084, 0.988), 0.014)
	end

	-- Intérieur : pierre chaude, lueur de forge en bas
	local interieur = creer("Frame", {Name = "Interieur", Position = UDim2.fromScale(0.016, 0.026), Size = UDim2.fromScale(0.968, 0.948),
		BackgroundColor3 = T.Pierre, ClipsDescendants = true, ZIndex = 1, Parent = racine},
		{coin(0.02), trait(T.FerSombre, 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 205)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 240, 225)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 190, 140))})})})
	local rng = Random.new(42)
	for _ = 1, 22 do
		local s = rng:NextNumber(0.06, 0.16)
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0, 1), rng:NextNumber(0, 1)),
			Size = UDim2.fromScale(s * rng:NextNumber(1, 1.6), s), SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = rng:NextNumber(-20, 20),
			BackgroundColor3 = if rng:NextNumber() < 0.5 then Color3.new(0, 0, 0) else Color3.fromRGB(120, 100, 86),
			BackgroundTransparency = rng:NextNumber(0.86, 0.94), BorderSizePixel = 0, Parent = interieur}, {coin(rng:NextNumber(0.2, 0.45))})
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
	local fermer = creer("TextButton", {Name = "Fermer", Text = "✕", Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = T.Parchemin,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.99, 0.16), Size = UDim2.fromScale(0.6, 0.6),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = Color3.fromRGB(140, 46, 34), AutoButtonColor = false, ZIndex = 4,
		Parent = entete}, {coin(0.5), trait(T.Fer, 3), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)),
		creer("UIPadding", {PaddingTop = UDim.new(0.22, 0), PaddingBottom = UDim.new(0.22, 0)})})
	UI.reactif(fermer, 1.1)
	fermer.MouseEnter:Connect(function()
		TweenService:Create(fermer, FAST, {Rotation = 90}):Play()
	end)
	fermer.MouseLeave:Connect(function()
		TweenService:Create(fermer, FAST, {Rotation = 0}):Play()
	end)

	UI.bandeFer(interieur, UDim2.fromScale(0, 0.205), UDim2.fromScale(1, 0.018), 14)
	local contenu = creer("Frame", {Name = "Contenu", Position = UDim2.fromScale(0.018, 0.25), Size = UDim2.fromScale(0.964, 0.725),
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
		for _, t in boucles do
			t:Pause()
		end
		if tweenVoile then
			tweenVoile:Cancel()
		end
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

	local function ouvrir()
		UI.portrait(o.service, vpPortrait)
		initiale.Visible = vpPortrait:FindFirstChild("Objet") == nil
		if ouverte then
			return
		end
		ouverte = true
		gui.Enabled = true
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
			while ouverte do
				braise()
				task.wait(0.07 + math.random() * 0.1)
			end
		end)
	end

	voile.Activated:Connect(fermerFenetre)
	fermer.Activated:Connect(function()
		jouer("clic", 0.9)
		fermerFenetre()
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
