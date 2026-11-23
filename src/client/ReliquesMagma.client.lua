-- Reliques du Casque du Cœur Magmatique · SCRIPT CLIENT
-- Chaque joueur ne voit plus les reliques qu'il a déjà ramassées (modèles tagués « ReliqueMagma », posés par
-- GrotteFonderie) : relique invisible, lueur et braises coupées, invite désactivée. Le serveur (CasqueMagma.server)
-- refuse de toute façon un 2e ramassage ; ceci n'est que de l'affichage.
-- Repérage (local, seulement pour les reliques pas encore ramassées) : logo flottant au-dessus (BillboardGui, distance en
-- mètres), colonne de lumière jusqu'au plafond, contour (Highlight) quand on est proche, relique qui tourne et flotte.
-- Compteur « Reliques x/3 » en haut à droite quand on est dans la Fonderie (−200 m) et que le casque n'est pas forgé.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CasqueMagma"))
local Logos = require(script.Parent:WaitForChild("LogosReliques"))

local joueur = Players.LocalPlayer
local playerGui = joueur:WaitForChild("PlayerGui")

local DIST_LOGO = 15 -- seulement de près : les reliques restent à chercher -- logo flottant visible jusqu'à cette distance
local DIST_CONTOUR = 10 -- contour coloré en dessous de cette distance
local DIST_ANIM = 60 -- la relique tourne/flotte en dessous de cette distance
local DIST_COLONNE = 15 -- colonne de lumière affichée en dessous de cette distance
local HAUTEUR_MAX = 160 -- hauteur max de la colonne (si pas de plafond trouvé : 70)

local function trouvees(): ({[string]: boolean}, boolean)
	return Config.lire(joueur:GetAttribute("FragmentsCarte"))
end

-- ================= Repérage des reliques =================
type Suivi = {
	part: BasePart, cf0: CFrame, rot0: CFrame, phase: number,
	bb: BillboardGui, porteur: Frame, echelle: UIScale, distance: TextLabel, dernier: number,
	a0: Attachment, a1: Attachment, faisceaux: {Beam}, colonne: boolean,
	contour: Highlight, proche: boolean,
}
local suivis: {[Instance]: Suivi} = {} -- clé : modèle de la relique
local nbSuivis = 0
local boucle: RBXScriptConnection? = nil

local function hauteurPlafond(origine: Vector3, exclure: {Instance}): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclure
	params.IgnoreWater = true
	local res = workspace:Raycast(origine, Vector3.new(0, HAUTEUR_MAX, 0), params)
	return if res then math.max(12, res.Distance) else 70
end

local function etape()
	local cam = workspace.CurrentCamera
	local perso = joueur.Character
	local hrp = perso and perso:FindFirstChild("HumanoidRootPart")
	local ref = if hrp and hrp:IsA("BasePart") then hrp.Position elseif cam then cam.CFrame.Position else Vector3.zero
	local t = os.clock()
	for m, s in suivis do
		if not s.part.Parent then
			continue -- relique sortie du streaming : nettoyée par AncestryChanged
		end
		local p0 = s.cf0.Position
		local d = (p0 - ref).Magnitude
		local ph = t + s.phase
		if d < DIST_ANIM then
			s.part.CFrame = CFrame.new(p0 + Vector3.new(0, math.sin(ph * 1.7) * 0.28, 0)) * CFrame.Angles(0, ph * 0.9, 0) * s.rot0
		end
		if d < DIST_LOGO then
			s.porteur.Position = UDim2.fromScale(0.5, 0.38 + math.sin(ph * 2) * 0.03)
			s.echelle.Scale = 1 + math.sin(ph * 3.2) * 0.05
			local n = math.floor(d + 0.5)
			if n ~= s.dernier then
				s.dernier = n
				s.distance.Text = n .. " m"
			end
		end
		local proche = d < DIST_CONTOUR
		if proche ~= s.proche then
			s.proche = proche
			s.contour.Enabled = proche
		end
		local colonne = d < DIST_COLONNE
		if colonne ~= s.colonne then
			s.colonne = colonne
			for _, f in s.faisceaux do
				f.Enabled = colonne
			end
		end
		-- la colonne respire un peu
		local f = s.faisceaux[2]
		if colonne and f then
			local w = 0.5 + math.sin(ph * 2.4) * 0.12
			f.Width0, f.Width1 = w, w * 0.5
		end
	end
end

local function majBoucle()
	if nbSuivis > 0 and not boucle then
		boucle = RunService.RenderStepped:Connect(etape)
	elseif nbSuivis == 0 and boucle then
		boucle:Disconnect()
		boucle = nil
	end
end

local function retirer(m: Instance)
	local s = suivis[m]
	if not s then
		return
	end
	suivis[m] = nil
	nbSuivis -= 1
	if s.part.Parent then
		s.part.CFrame = s.cf0
	end
	s.bb:Destroy()
	s.a0:Destroy()
	s.a1:Destroy()
	for _, f in s.faisceaux do
		f:Destroy()
	end
	s.contour:Destroy()
	majBoucle()
end

local function suivre(m: Instance, part: BasePart, id: string)
	local r = Config.PAR_ID[id]
	if not r or suivis[m] then
		return
	end
	local couleur: Color3 = r.couleur
	local vif = couleur:Lerp(Color3.new(1, 1, 1), 0.4)
	local cf0 = part.CFrame

	-- Logo flottant (taille fixe à l'écran : lisible de loin, discret de près)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Relique_" .. id
	bb.Adornee = part
	bb.AlwaysOnTop = false
	bb.MaxDistance = DIST_LOGO
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(64, 86)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	bb.ResetOnSpawn = false
	bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local porteur = Instance.new("Frame")
	porteur.AnchorPoint = Vector2.new(0.5, 0.5)
	porteur.Position = UDim2.fromScale(0.5, 0.38)
	porteur.Size = UDim2.fromScale(1, 0.74)
	porteur.BackgroundTransparency = 1
	porteur.Parent = bb
	local echelle = Instance.new("UIScale")
	echelle.Parent = porteur
	local halo = Instance.new("Frame")
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.5)
	halo.Size = UDim2.fromScale(1.2, 1.2)
	halo.SizeConstraint = Enum.SizeConstraint.RelativeXX
	halo.BackgroundColor3 = couleur
	halo.BackgroundTransparency = 0.55
	halo.BorderSizePixel = 0
	halo.Parent = porteur
	local coinHalo = Instance.new("UICorner")
	coinHalo.CornerRadius = UDim.new(0.5, 0)
	coinHalo.Parent = halo
	local gHalo = Instance.new("UIGradient")
	gHalo.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)})
	gHalo.Parent = halo
	Logos.creer(id, porteur)
	local distance = Instance.new("TextLabel")
	distance.AnchorPoint = Vector2.new(0.5, 1)
	distance.Position = UDim2.fromScale(0.5, 1)
	distance.Size = UDim2.fromScale(1.4, 0.24)
	distance.BackgroundTransparency = 1
	distance.Font = Enum.Font.GothamBlack
	distance.TextScaled = true
	distance.TextColor3 = vif
	distance.TextStrokeColor3 = Color3.fromRGB(20, 8, 4)
	distance.TextStrokeTransparency = 0.15
	distance.Text = ""
	distance.Parent = bb
	bb.Parent = playerGui

	-- Colonne de lumière jusqu'au plafond (2 faisceaux : halo large + cœur vif, qui s'effacent vers le haut)
	local h = hauteurPlafond(cf0.Position + Vector3.new(0, 1, 0), {m, joueur.Character :: Instance})
	local terrain = workspace.Terrain
	local a0 = Instance.new("Attachment")
	a0.Name = "ReliqueBas_" .. id
	a0.Parent = terrain
	a0.WorldPosition = cf0.Position - Vector3.new(0, 1.8, 0)
	local a1 = Instance.new("Attachment")
	a1.Name = "ReliqueHaut_" .. id
	a1.Parent = terrain
	a1.WorldPosition = cf0.Position + Vector3.new(0, h, 0)
	local faisceaux = {}
	for k, regl in {
		{largeur = 3.2, fin = 1.6, couleur = couleur, transp = {0.55, 0.8}},
		{largeur = 0.5, fin = 0.25, couleur = vif, transp = {0.1, 0.55}},
	} do
		local b = Instance.new("Beam")
		b.Name = "Colonne" .. k
		b.Attachment0, b.Attachment1 = a0, a1
		b.FaceCamera = true
		b.Segments = 1
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = 2
		b.Color = ColorSequence.new(regl.couleur)
		b.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, regl.transp[1]),
			NumberSequenceKeypoint.new(0.6, regl.transp[2]), NumberSequenceKeypoint.new(1, 1)})
		b.Width0, b.Width1 = regl.largeur, regl.fin
		b.Parent = terrain
		faisceaux[k] = b
	end

	-- Contour coloré (activé de près par la boucle)
	local contour = Instance.new("Highlight")
	contour.Name = "ContourRelique"
	contour.Adornee = m
	contour.FillColor = couleur
	contour.FillTransparency = 0.8
	contour.OutlineColor = vif
	contour.OutlineTransparency = 0
	contour.DepthMode = Enum.HighlightDepthMode.Occluded
	contour.Enabled = false
	contour.Parent = m

	suivis[m] = {
		part = part, cf0 = cf0, rot0 = cf0.Rotation, phase = (#id * 1.37 + (r.numero or 0) * 2.1),
		bb = bb, porteur = porteur, echelle = echelle, distance = distance, dernier = -1,
		a0 = a0, a1 = a1, faisceaux = faisceaux, colonne = true, contour = contour, proche = false,
	}
	nbSuivis += 1
	part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(workspace) then
			retirer(m)
		end
	end)
	majBoucle()
end

local function majModele(m: Instance, t: {[string]: boolean})
	local id = m:GetAttribute("Relique")
	if type(id) ~= "string" then
		return
	end
	local prise = t[id] == true
	local partRelique: BasePart? = nil
	for _, d in m:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d.Enabled = not prise
		elseif d.Name == "Relique" and d:IsA("BasePart") then
			partRelique = d
			d.LocalTransparencyModifier = if prise then 1 else 0
			for _, e in d:GetChildren() do
				if e:IsA("ParticleEmitter") or e:IsA("Light") then
					e.Enabled = not prise
				end
			end
		end
	end
	if prise then
		retirer(m)
	elseif partRelique and m:IsDescendantOf(workspace) then
		suivre(m, partRelique, id)
	end
end

-- ================= Compteur « Reliques x/3 » (haut droite) =================
local POS_VISIBLE = UDim2.fromScale(0.988, 0.17)
local POS_CACHE = UDim2.fromScale(1.35, 0.17)
local hud = Instance.new("ScreenGui")
hud.Name = "ReliquesMagmaHUD"
hud.ResetOnSpawn = false
hud.DisplayOrder = 4
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local panneau = Instance.new("Frame")
panneau.Name = "Compteur"
panneau.AnchorPoint = Vector2.new(1, 0)
panneau.Position = POS_CACHE
panneau.Size = UDim2.fromScale(0.18, 0.065)
panneau.BackgroundColor3 = Color3.new(1, 1, 1)
panneau.Visible = false
panneau.Parent = hud
do
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 4.2
	ar.Parent = panneau
	local sc = Instance.new("UISizeConstraint")
	sc.MinSize, sc.MaxSize = Vector2.new(170, 40), Vector2.new(290, 69)
	sc.Parent = panneau
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = panneau
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromRGB(74, 50, 36), Color3.fromRGB(22, 14, 12)) -- bois sombre
	g.Parent = panneau
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(200, 80, 24)
	s.Thickness = 2
	s.Transparency = 0.1
	s.Parent = panneau
end
local function etiquette(txt: string, police: Enum.Font, couleur: Color3, y: number, h: number, max: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromScale(0.06, y)
	l.Size = UDim2.fromScale(0.36, h)
	l.Font = police
	l.Text = txt
	l.TextColor3 = couleur
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextStrokeTransparency = 0.5
	l.Parent = panneau
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = max
	c.Parent = l
	return l
end
etiquette("RELIQUES", Enum.Font.GothamBlack, Color3.fromRGB(255, 176, 90), 0.1, 0.34, 16)
local compte = etiquette("0/3", Enum.Font.Fantasy, Color3.fromRGB(255, 236, 210), 0.42, 0.5, 30)

type Case = {groupe: CanvasGroup, echelle: UIScale, trouvee: boolean?}
local cases: {[string]: Case} = {}
for i, r in Config.RELIQUES do
	local cg = Instance.new("CanvasGroup")
	cg.Name = r.id
	cg.AnchorPoint = Vector2.new(0, 0.5)
	cg.Position = UDim2.fromScale(0.45 + (i - 1) * 0.18, 0.5)
	cg.Size = UDim2.fromScale(0.72, 0.72)
	cg.SizeConstraint = Enum.SizeConstraint.RelativeYY
	cg.BackgroundTransparency = 1
	cg.Parent = panneau
	local e = Instance.new("UIScale")
	e.Parent = cg
	Logos.creer(r.id, cg)
	cases[r.id] = {groupe = cg, echelle = e}
end
hud.Parent = playerGui

local INFO_CASE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function majCompteur()
	local t = trouvees()
	local n = 0
	for _, r in Config.RELIQUES do
		local ok = t[r.id] == true
		if ok then
			n += 1
		end
		local c = cases[r.id]
		if c.trouvee ~= ok then
			local avant = c.trouvee
			c.trouvee = ok
			TweenService:Create(c.groupe, INFO_CASE, {GroupTransparency = if ok then 0 else 0.55,
				GroupColor3 = if ok then Color3.new(1, 1, 1) else Color3.fromRGB(110, 104, 104)}):Play()
			if ok and avant == false then -- vient d'être ramassée : petit « pop »
				c.echelle.Scale = 1.4
				TweenService:Create(c.echelle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			end
		end
	end
	compte.Text = n .. "/" .. #Config.RELIQUES
end

-- Le joueur est-il dans la grotte de la Fonderie ? (grottes : workspace.Grottes, attributs Centre / DemiTaille / Niveau)
local function dansFonderie(): boolean
	local perso = joueur.Character
	local hrp = perso and perso:FindFirstChild("HumanoidRootPart")
	local dossier = workspace:FindFirstChild("Grottes")
	if not (hrp and hrp:IsA("BasePart") and dossier) then
		return false
	end
	local pos = hrp.Position
	for _, g in dossier:GetChildren() do
		if g:GetAttribute("Niveau") == Config.NIVEAU then
			local c, d = g:GetAttribute("Centre"), g:GetAttribute("DemiTaille")
			if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
				local r = pos - c
				if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
					return true
				end
			end
		end
	end
	return false
end

local hudVisible = false
local function majVisibiliteHud()
	local _, forge = trouvees()
	local voir = not forge and dansFonderie()
	if voir == hudVisible then
		return
	end
	hudVisible = voir
	if voir then
		panneau.Visible = true
		TweenService:Create(panneau, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = POS_VISIBLE}):Play()
	else
		TweenService:Create(panneau, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = POS_CACHE}):Play()
		task.delay(0.26, function()
			if not hudVisible then
				panneau.Visible = false
			end
		end)
	end
end
task.spawn(function()
	while true do
		majVisibiliteHud()
		task.wait(0.5)
	end
end)

-- ================= Branchements =================
local function toutMettreAJour()
	local t = trouvees()
	for _, m in CollectionService:GetTagged("ReliqueMagma") do
		majModele(m, t)
	end
	majCompteur()
	majVisibiliteHud()
end

local function brancher(m: Instance)
	-- les enfants peuvent arriver juste après le modèle (streaming)
	task.defer(function()
		majModele(m, (trouvees()))
	end)
	m.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") or d:IsA("ProximityPrompt") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			majModele(m, (trouvees()))
		end
	end)
end
CollectionService:GetInstanceAddedSignal("ReliqueMagma"):Connect(brancher)
CollectionService:GetInstanceRemovedSignal("ReliqueMagma"):Connect(retirer)
for _, m in CollectionService:GetTagged("ReliqueMagma") do
	brancher(m)
end
joueur:GetAttributeChangedSignal("FragmentsCarte"):Connect(toutMettreAJour)
toutMettreAJour()
