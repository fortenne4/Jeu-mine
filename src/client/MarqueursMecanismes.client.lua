-- Marqueurs des mécanismes de grotte · SCRIPT CLIENT
-- Dans la grotte du joueur (workspace › Grottes, attribut Proprietaire / Invite), chaque mécanisme encore à faire
-- porte une pastille dorée qui flotte et pulse (icône + consigne), un contour lumineux de près et des étincelles.
-- Le marqueur disparaît quand l'invite est désactivée, quand le mécanisme est fait pour ce joueur, ou après un
-- premier usage (règles « uneFois »). Pour un nouveau mécanisme : ajouter une entrée à REGLES (clé = attribut
-- de l'invite) ; sans règle, l'ActionText de l'invite sert de consigne. Les reliques (tag ReliqueMagma) sont exclues.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local CasqueMagma = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CasqueMagma"))

local joueur = Players.LocalPlayer
local uid = joueur.UserId

local PORTEE = 20 -- visible seulement de près : il faut explorer pour trouver
local PORTEE_CONTOUR = 12
local PORTEE_ETINCELLES = 15
local OR, ORANGE, BRUN = Color3.fromRGB(255, 214, 90), Color3.fromRGB(255, 140, 30), Color3.fromRGB(58, 30, 10)
local ROUGE, ROUGE_SOMBRE = Color3.fromRGB(255, 90, 60), Color3.fromRGB(190, 30, 20)

local function contient(liste: any, id: number): boolean
	return type(liste) == "string" and liste:find("," .. id .. ",", 1, true) ~= nil
end

local function grandParent(i: Instance): Instance?
	return i.Parent and i.Parent.Parent
end

local function reliques(): (number, boolean)
	local t, forge = CasqueMagma.lire(joueur:GetAttribute("FragmentsCarte"))
	local n = 0
	for _ in t do
		n += 1
	end
	return n, forge
end

local function wagonGare(_, g: Instance): Instance?
	return g:FindFirstChild("WagonGare", true)
end

-- clé = attribut de l'invite. texte : chaîne ou fonction(invite, grotte). fait(invite, grotte) : déjà fait pour moi.
-- uneFois : masqué après un premier usage (groupe = clé commune). portee, couleur, hauteur, cible(invite, grotte).
local REGLES = {
	CourseWagon = {texte = "Monte dans le wagonnet", icone = "wagon", uneFois = true, cible = wagonGare},
	AscenseurLevier = {texte = "Actionne le levier de l'ascenseur", icone = "levier", uneFois = true, groupe = "Ascenseur"},
	FonderieRoyale = {texte = "Verse 3 Fer dans le creuset", icone = "creuset",
		fait = function(_, g)
			local marques = joueur:GetAttribute("FragmentsCarte") -- lingot déjà coulé un jour (sauvegardé)
			return contient(g:GetAttribute("Fondus"), uid) or (type(marques) == "string" and ("," .. marques .. ","):find(",LingotRoyal,", 1, true) ~= nil)
		end},
	ManivelleRouage = {icone = "manivelle", texte = function(i, g)
		return ("Tourne la manivelle (%d/%d)"):format(i:GetAttribute("ManivelleRouage") or 1, g:GetAttribute("RouagesTotal") or 3)
	end},
	CoffreAbime = {texte = "Ouvre le coffre de l'Abîme", icone = "coffre",
		fait = function(_, g) return contient(g:GetAttribute("CoffreAbimePris"), uid) end},
	EnclumeMagma = {icone = "enclume", texte = function()
		local n = reliques()
		return if n >= 3 then "Forge le Casque magmatique !" else ("Enclume des maîtres · reliques %d/3"):format(n)
	end, fait = function() return select(2, reliques()) end},
	CoffreSanctuaire = {texte = "Ouvre le coffre du sanctuaire", icone = "coffre",
		fait = function(i) local m = grandParent(i) return m ~= nil and contient(m:GetAttribute("OuvertPar"), uid) end},
	Arene = {texte = "Frappe le gong : l'arène t'attend", icone = "gong", uneFois = true},
	PierreRunique = {icone = "rune", texte = function(_, g)
		return ("Active les pierres dans le bon ordre (%d/%d)"):format(g:GetAttribute("RunesProgres") or 0, g:GetAttribute("PierresRunes") or 3)
	end, fait = function(_, g) return g:GetAttribute("PorteOuverte") == true end},
	FragmentCarte = {texte = "Ramasse le fragment de carte", icone = "carte", portee = 12,
		fait = function(i) local m = grandParent(i) return m ~= nil and contient(m:GetAttribute("PrisPar"), uid) end},
	Peche = {texte = "Coin de pêche", icone = "poisson", uneFois = true, groupe = "Peche", portee = 20},
}
local ORDRE = {"CourseWagon", "AscenseurLevier", "FonderieRoyale", "ManivelleRouage", "CoffreAbime", "EnclumeMagma",
	"CoffreSanctuaire", "Arene", "PierreRunique", "FragmentCarte", "Peche"}
local GENERIQUE = {icone = "exclam", texte = function(i) return i.ActionText end}

-- mécanismes sans invite : fonction(instance) → règle ou nil
local laveEnCrue = false
local SPECIAUX = {
	function(i)
		if i:IsA("BasePart") and i:GetAttribute("Propulsion") and CollectionService:HasTag(i, "Geyser") then
			return {texte = "Saute dans la faille bleue", icone = "fleche", uneFois = true, faitPres = 6, hauteur = 4}
		end
	end,
	function(i)
		if i:IsA("Model") and i.Name == "Refuge" then
			return {texte = "Réfugie-toi ici !", icone = "exclam", couleur = ROUGE, portee = 120, hauteur = 4.5,
				dispo = function() return laveEnCrue end}
		end
	end,
}

-- ================= Icônes dessinées en Frames (repère 52 × 52) =================
local function bloc(parent: Instance, x: number, y: number, w: number, h: number, rot: number?, coin: number?, c: Color3?)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position, f.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	f.Rotation, f.BorderSizePixel, f.BackgroundColor3 = rot or 0, 0, c or BRUN
	if coin then
		local u = Instance.new("UICorner")
		u.CornerRadius = if coin >= 1 then UDim.new(0.5, 0) else UDim.new(0, coin * 10)
		u.Parent = f
	end
	f.Parent = parent
	return f
end
local function rond(parent, x, y, d, c) return bloc(parent, x, y, d, d, 0, 1, c) end
local function anneau(parent, x, y, d, ep)
	local f = rond(parent, x, y, d)
	f.BackgroundTransparency = 1
	local s = Instance.new("UIStroke")
	s.Thickness, s.Color = ep, BRUN
	s.Parent = f
end

local ICONES = {
	exclam = function(p)
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		t.Text, t.Font, t.TextSize, t.TextColor3 = "!", Enum.Font.GothamBlack, 34, BRUN
		t.Parent = p
	end,
	levier = function(p)
		bloc(p, 26, 38, 24, 7, 0, 0.3)
		bloc(p, 30, 26, 4, 22, 28)
		rond(p, 35, 15, 10)
	end,
	manivelle = function(p)
		anneau(p, 22, 28, 20, 3)
		bloc(p, 22, 28, 18, 3, 45)
		bloc(p, 36, 20, 4, 12)
		rond(p, 36, 13, 8)
	end,
	coffre = function(p)
		bloc(p, 26, 31, 30, 16, 0, 0.2)
		bloc(p, 26, 19, 30, 9, 0, 0.4)
		bloc(p, 26, 24, 30, 2, 0, nil, OR)
		bloc(p, 26, 27, 6, 7, 0, 0.2, OR)
	end,
	enclume = function(p)
		bloc(p, 28, 19, 26, 7, 0, 0.2)
		bloc(p, 12, 20, 10, 4, -12)
		bloc(p, 28, 27, 10, 9)
		bloc(p, 28, 36, 24, 6, 0, 0.2)
	end,
	wagon = function(p)
		bloc(p, 26, 17, 36, 4, 0, 0.2)
		bloc(p, 26, 26, 30, 14, 0, 0.2)
		rond(p, 17, 36, 9)
		rond(p, 35, 36, 9)
	end,
	creuset = function(p)
		bloc(p, 23, 24, 22, 18, -22, 0.3)
		rond(p, 36, 35, 6)
		rond(p, 40, 43, 4)
	end,
	gong = function(p)
		bloc(p, 11, 28, 3, 26)
		bloc(p, 41, 28, 3, 26)
		bloc(p, 26, 15, 34, 3)
		rond(p, 26, 30, 20)
		rond(p, 26, 30, 7, OR)
	end,
	rune = function(p)
		bloc(p, 26, 26, 22, 22, 45, 0.2)
		bloc(p, 26, 26, 3, 14, 0, nil, OR)
		bloc(p, 26, 22, 10, 3, 0, nil, OR)
	end,
	carte = function(p)
		bloc(p, 26, 26, 28, 22, -8, 0.3)
		bloc(p, 25, 21, 18, 2, -8, nil, OR)
		bloc(p, 26, 27, 18, 2, -8, nil, OR)
		bloc(p, 27, 33, 12, 2, -8, nil, OR)
	end,
	poisson = function(p)
		bloc(p, 23, 26, 24, 14, 0, 1)
		bloc(p, 37, 26, 11, 11, 45)
		rond(p, 17, 24, 4, OR)
	end,
	fleche = function(p)
		bloc(p, 26, 30, 6, 22, 0, 0.3)
		bloc(p, 21, 19, 5, 17, 45, 0.3)
		bloc(p, 31, 19, 5, 17, -45, 0.3)
	end,
}

-- ================= Construction d'un marqueur =================
local dossierGui = Instance.new("Folder")
dossierGui.Name = "MarqueursMecanismes"
dossierGui.Parent = joueur:WaitForChild("PlayerGui")

local SINUS = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local function boucle(liste, objet, info, props)
	local t = TweenService:Create(objet, info, props)
	t:Play()
	table.insert(liste, t)
end

local function construireGui(m)
	local r = m.regle
	local clair, fonce = r.couleur or OR, if r.couleur then ROUGE_SOMBRE else ORANGE
	local h = r.hauteur or ((m.adornee.Size.Y / 2) + 3)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee, gui.Enabled = "Marqueur", m.adornee, false
	gui.Size, gui.StudsOffset = UDim2.fromOffset(240, 112), Vector3.new(0, h, 0)
	gui.AlwaysOnTop, gui.LightInfluence, gui.MaxDistance, gui.ResetOnSpawn = false, 0, r.portee or PORTEE, false
	local racine = Instance.new("Frame")
	racine.Size, racine.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	racine.Parent = gui
	local echelle = Instance.new("UIScale")
	echelle.Scale = 0.85
	echelle.Parent = racine

	local halo = rond(racine, 120, 30, 52, clair)
	halo.BackgroundTransparency = 0.6
	local trait = Instance.new("UIStroke")
	trait.Color, trait.Thickness = clair, 3
	trait.Parent = halo
	boucle(m.tweens, halo, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Size = UDim2.fromOffset(92, 92), BackgroundTransparency = 1})
	boucle(m.tweens, trait, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Transparency = 1})

	bloc(racine, 120, 55, 14, 14, 45, nil, fonce)
	local pastille = rond(racine, 120, 30, 52, Color3.new(1, 1, 1))
	local degrade = Instance.new("UIGradient")
	degrade.Color, degrade.Rotation = ColorSequence.new(clair, fonce), 90
	degrade.Parent = pastille
	local bord = Instance.new("UIStroke")
	bord.Color, bord.Thickness = BRUN, 3
	bord.Parent = pastille
	local reflet = bloc(pastille, 20, 14, 16, 8, -30, 1, Color3.new(1, 1, 1))
	reflet.BackgroundTransparency = 0.55
	ICONES[r.icone or "exclam"](pastille)
	boucle(m.tweens, pastille, SINUS, {Size = UDim2.fromOffset(57, 57)})

	local texte = Instance.new("TextLabel")
	texte.AnchorPoint, texte.Position = Vector2.new(0.5, 0), UDim2.fromOffset(120, 66)
	texte.Size, texte.AutomaticSize = UDim2.fromOffset(0, 26), Enum.AutomaticSize.X
	texte.BackgroundColor3, texte.BackgroundTransparency = Color3.fromRGB(26, 18, 12), 0.15
	texte.Font, texte.TextSize, texte.TextColor3 = Enum.Font.GothamBold, 15, Color3.fromRGB(255, 240, 210)
	texte.Text = ""
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0, 8)
	coin.Parent = texte
	local cadre = Instance.new("UIStroke")
	cadre.Color, cadre.Thickness, cadre.ApplyStrokeMode = clair, 1.5, Enum.ApplyStrokeMode.Border
	cadre.Parent = texte
	local marge = Instance.new("UIPadding")
	marge.PaddingLeft, marge.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	marge.Parent = texte
	texte.Parent = racine

	boucle(m.tweens, gui, SINUS, {StudsOffset = Vector3.new(0, h + 0.7, 0)})
	gui.Parent = dossierGui
	m.gui, m.echelle, m.label, m.scaleCible = gui, echelle, texte, 0.85
end

local function contour(m)
	if m.highlight or not m.cible then
		return m.highlight
	end
	local hl = Instance.new("Highlight")
	hl.FillColor, hl.OutlineColor = m.regle.couleur or ORANGE, m.regle.couleur or OR
	hl.FillTransparency, hl.OutlineTransparency = 0.8, 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Enabled = false
	hl.Parent = m.cible
	boucle(m.tweens, hl, SINUS, {FillTransparency = 0.95, OutlineTransparency = 0.6})
	m.highlight = hl
	return hl
end

local function etincelles(m)
	if m.emetteur then
		return m.emetteur
	end
	local a = Instance.new("Attachment")
	a.Name = "MarqueurEtincelles"
	a.Position = Vector3.new(0, -m.adornee.Size.Y / 2 + 0.3, 0)
	a.Parent = m.adornee
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(m.regle.couleur or OR, Color3.new(1, 1, 1))
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.1)
	e.Lifetime, e.Rate = NumberRange.new(1, 1.8), 6
	e.Speed, e.SpreadAngle = NumberRange.new(1, 2.5), Vector2.new(60, 60)
	e.EmissionDirection, e.Acceleration = Enum.NormalId.Top, Vector3.new(0, 0.8, 0)
	e.Enabled = false
	e.Parent = a
	m.attache, m.emetteur = a, e
	return e
end

-- ================= Suivi de la grotte courante =================
local grotte: Model? = nil
local marqueurs: {[Instance]: any} = {}
local faits: {[any]: boolean} = {}
local connexions: {RBXScriptConnection} = {}

local function retirer(inst: Instance)
	local m = marqueurs[inst]
	if not m then
		return
	end
	marqueurs[inst] = nil
	for _, t in m.tweens do
		t:Cancel()
	end
	m.gui:Destroy()
	if m.highlight then
		m.highlight:Destroy()
	end
	if m.attache then
		m.attache:Destroy()
	end
end

local function exclu(i: Instance, g: Instance): boolean
	if i:GetAttribute("ReliqueMagma") ~= nil or i.Name == "MonterWagon" then
		return true
	end
	local p = i.Parent
	while p and p ~= g do
		if CollectionService:HasTag(p, "ReliqueMagma") then
			return true
		end
		p = p.Parent
	end
	return false
end

local function ciblePar(i: Instance, g: Instance): Instance?
	local p = if i:IsA("ProximityPrompt") then i.Parent else i
	while p and p ~= g do
		if p:IsA("Model") then
			return p
		end
		p = p.Parent
	end
	return if i:IsA("ProximityPrompt") then i.Parent else i
end

local function adorneePour(i: Instance): BasePart?
	local p = if i:IsA("ProximityPrompt") then i.Parent else i
	if p and p:IsA("Attachment") then
		p = p.Parent
	end
	if p and p:IsA("Model") then
		return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
	end
	return if p and p:IsA("BasePart") then p else nil
end

local function ajouter(i: Instance)
	local g = grotte
	if not g or marqueurs[i] then
		return
	end
	local regle
	if i:IsA("ProximityPrompt") then
		if exclu(i, g) then
			return
		end
		for _, cle in ORDRE do
			if i:GetAttribute(cle) ~= nil then
				regle = REGLES[cle]
				break
			end
		end
		regle = regle or GENERIQUE
	else
		for _, f in SPECIAUX do
			regle = f(i)
			if regle then
				break
			end
		end
		if not regle then
			return
		end
	end
	local adornee = adorneePour(i)
	if not adornee then
		return
	end
	local m = {inst = i, regle = regle, adornee = adornee, tweens = {}, groupe = regle.groupe or i,
		invite = if i:IsA("ProximityPrompt") then i else nil,
		cible = if regle.cible then regle.cible(i, g) else ciblePar(i, g)}
	marqueurs[i] = m
	construireGui(m)
end

local function vider()
	for i in marqueurs do
		retirer(i)
	end
	for _, c in connexions do
		c:Disconnect()
	end
	table.clear(connexions)
	table.clear(faits)
	grotte = nil
end

local function entrer(g: Model)
	vider()
	grotte = g
	for _, d in g:GetDescendants() do
		ajouter(d)
	end
	table.insert(connexions, g.DescendantAdded:Connect(function(d)
		task.defer(ajouter, d)
	end))
	table.insert(connexions, g.DescendantRemoving:Connect(retirer))
end

local function trouverGrotte(): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then
		return nil
	end
	for _, g in dossier:GetChildren() do
		if g:IsA("Model") and (g:GetAttribute("Proprietaire") == uid or g:GetAttribute("Invite") == uid) then
			return g
		end
	end
	return nil
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt)
	local m = marqueurs[invite]
	if m and m.regle.uneFois then
		faits[m.groupe] = true
	end
end)

-- ================= Boucle de visibilité (8 Hz) =================
local function majMarqueur(m, g: Model, pos: Vector3?)
	local r = m.regle
	local ok = m.adornee.Parent ~= nil and pos ~= nil
	if ok and m.invite then
		ok = m.invite.Enabled and m.invite.Parent ~= nil
	elseif ok and r.dispo then
		ok = r.dispo(m.inst, g)
	end
	local dist = if pos then (m.adornee.Position - pos).Magnitude else math.huge
	if ok and r.faitPres and dist < r.faitPres then
		faits[m.groupe] = true
	end
	ok = ok and not (r.uneFois and faits[m.groupe]) and not (r.fait and r.fait(m.inst, g)) and dist <= (r.portee or PORTEE)

	m.gui.Enabled = ok
	if ok then
		local t = if type(r.texte) == "function" then r.texte(m.inst, g) else r.texte
		t = if t and t ~= "" then t else "Interagir"
		if m.label.Text ~= t then
			m.label.Text = t
		end
		local s = 0.85 + 0.4 * math.clamp(1 - (dist - 5) / 15, 0, 1)
		if math.abs(s - m.scaleCible) > 0.04 then
			m.scaleCible = s
			TweenService:Create(m.echelle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Scale = s}):Play()
		end
	end
	local proche = ok and dist < PORTEE_CONTOUR
	if proche or m.highlight then
		local hl = contour(m)
		if hl then
			hl.Enabled = proche
		end
	end
	local brille = ok and dist < PORTEE_ETINCELLES
	if brille or m.emetteur then
		etincelles(m).Enabled = brille
	end
end

local attente = 0
while true do
	task.wait(0.125)
	attente -= 0.125
	if attente <= 0 then
		attente = 1
		local g = trouverGrotte()
		if g ~= grotte then
			if g then
				entrer(g)
			else
				vider()
			end
		end
	end
	local g = grotte
	if g and g.Parent then
		laveEnCrue = false
		for _, lac in CollectionService:GetTagged("LaveMontante") do
			if lac:GetAttribute("EnCrue") and lac:IsDescendantOf(g) then
				laveEnCrue = true
				break
			end
		end
		local perso = joueur.Character
		local rp = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
		local pos = if rp and not joueur:GetAttribute("EnWagon") then rp.Position else nil
		for _, m in marqueurs do
			majMarqueur(m, g, pos)
		end
	elseif g then
		vider()
	end
end
