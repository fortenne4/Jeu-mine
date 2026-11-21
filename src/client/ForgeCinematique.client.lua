-- Cinématique de forge (locale) : après une forge réussie, Brom martèle un lingot incandescent sur la grosse enclume ;
-- le lingot s'étire par paliers à chaque coup, refroidit et révèle l'objet forgé. Clone local de Brom (le vrai est figé
-- par AnimationsNains et caché), rien côté serveur. Attribut joueur « ForgeCinematique » = true pendant toute la durée.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local joueur = Players.LocalPlayer
local evenement = ReplicatedStorage:WaitForChild("ForgeCinematique") :: RemoteEvent
local Partage = ReplicatedStorage:WaitForChild("Partage")
local POSES = require(Partage:WaitForChild("PosesNains")).Brom

local ATTRIBUT = "ForgeCinematique"
local LIAISON = "CinematiqueForge"
local BANDES = 0.11
local OUVERTURE = 0.6
local V = Vector3.new
local INTERFACES = {Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.EmotesMenu, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health}
local A_RETIRER = {"LuaSourceContainer", "BillboardGui", "ProximityPrompt", "ClickDetector", "ParticleEmitter", "Light", "Sound"}
local ENCLUME_BROM = {Acier = true, Bois = true, Lueur = true, Or = true, Cuir = true} -- petite enclume du modèle de Brom
local COTES = {"D", "G"}
local GROUPES = {"Buste", "Tete", "BrasD", "AvBrasD", "MainD", "BrasG", "AvBrasG", "MainG"}

local LAVE = Color3.fromRGB(255, 84, 16)
local BLANC_CHAUD = Color3.fromRGB(255, 214, 140)
local FROID = Color3.fromRGB(96, 26, 10)
local S0 = V(1.1, 0.6, 0.7) -- lingot de départ (repère enclume : X = long de la table, Y = haut, Z = vers la caméra)
local ZC = -0.15 -- centre du lingot, légèrement côté Brom

-- ================= Déroulé (secondes) =================
local DEBUT_FRAPPE, PERIODE, COUPS = 1.45, 0.42, 6
local REVELE = DEBUT_FRAPPE + (COUPS - 1) * PERIODE + 0.4 -- juste après le dernier coup
local DUREE = 5.7
local IMPACTS = {}
local CLES = {{0, "repos"}, {0.55, "souleve", "douce"}, {1.05, "garde", "douce"}, {DEBUT_FRAPPE, "garde", "douce"}}
for i = 0, COUPS - 1 do
	local b = DEBUT_FRAPPE + i * PERIODE
	table.insert(CLES, {b + 0.2, "leve", "sortie"})
	table.insert(CLES, {b + 0.34, "frappe", "entree"})
	table.insert(CLES, {b + 0.42, "garde", "sortie"})
	IMPACTS[i + 1] = b + 0.34
end
table.insert(CLES, {REVELE + 0.7, "garde", "douce"})
table.insert(CLES, {REVELE + 1.3, "souleve", "douce"})
table.insert(CLES, {REVELE + 2.0, "repos", "douce"})

local COURBES = {
	douce = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end,
	sortie = function(t) return 1 - (1 - t) ^ 2.4 end,
	entree = function(t) return t ^ 2.2 end,
}
local function lisse(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- Plans : camera(etat, u) dans le repère F de l'enclume (-Z vers Brom, +Z côté caméra).
local PLANS = {
	{fin = 1.9, fov = 52, camera = function(e, u)
		return CFrame.lookAt(e.F * V(-3.6 + 0.8 * u, 3.4 - 0.3 * u, 9.5 - 1.8 * u), e.F * V(0, 1.6, -1.4))
	end},
	{fin = REVELE + 0.25, fov = 46, camera = function(e, u)
		local d = e.dist * (1.05 - 0.12 * u)
		return CFrame.lookAt(e.F * V(d * 0.42, d * 0.48, d), e.F * V(0, 0.35, ZC)) * e.secousseCF
	end},
	{fin = DUREE, fov = 42, fondu = 0.4, camera = function(e, u)
		local a, d = -0.5 + 0.75 * lisse(u), e.dist * 0.85
		return CFrame.lookAt(e.F * V(math.sin(a) * d, d * 0.42, math.cos(a) * d), e.F * V(0, e.hObjet * 0.45, ZC))
	end},
}

-- ================= Écran : voile + bandes =================
local ecran = Instance.new("ScreenGui")
ecran.Name = "CinematiqueForge"
ecran.IgnoreGuiInset = true
ecran.ResetOnSpawn = false
ecran.DisplayOrder = 100
ecran.Parent = joueur:WaitForChild("PlayerGui")
local function cadreNoir(nom: string): Frame
	local f = Instance.new("Frame")
	f.Name = nom
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 0)
	f.Parent = ecran
	return f
end
local voile = cadreNoir("Voile")
voile.Size = UDim2.fromScale(1, 1)
voile.BackgroundTransparency = 1
voile.ZIndex = 2
local bandeHaut = cadreNoir("BandeHaut")
local bandeBas = cadreNoir("BandeBas")
bandeBas.AnchorPoint = Vector2.new(0, 1)
bandeBas.Position = UDim2.fromScale(0, 1)

local fondus = {}
local function animerEcran(transparence: number, bandes: number, duree: number)
	for _, f in fondus do f:Cancel() end
	table.clear(fondus)
	local info = TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local taille = UDim2.fromScale(1, bandes)
	for _, f in {
		TweenService:Create(voile, info, {BackgroundTransparency = transparence}),
		TweenService:Create(bandeHaut, info, {Size = taille}),
		TweenService:Create(bandeBas, info, {Size = taille}),
	} do
		table.insert(fondus, f)
		f:Play()
	end
end

-- ================= Interface et contrôles =================
local controles = nil
local function lireControles()
	if controles then return controles end
	local scripts = joueur:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if module then
		local ok, resultat = pcall(function() return (require(module :: any) :: any):GetControls() end)
		if ok then controles = resultat end
	end
	return controles
end

local guisMasques, interfacesAvant = {}, {}
local invitesAvant, masque, controlesCoupes = true, false, false
local function masquerInterface()
	masque = true
	for _, gui in joueur.PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui ~= ecran and gui.Enabled then
			gui.Enabled = false
			table.insert(guisMasques, gui)
		end
	end
	for i, type in INTERFACES do
		local ok, active = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, type)
		interfacesAvant[i] = if ok then active else nil
		if ok then pcall(StarterGui.SetCoreGuiEnabled, StarterGui, type, false) end
	end
	invitesAvant = ProximityPromptService.Enabled
	pcall(function() ProximityPromptService.Enabled = false end)
	local c = lireControles()
	if c then controlesCoupes = pcall(function() c:Disable() end) end
end
local function afficherInterface()
	if not masque then return end
	masque = false
	for _, gui in guisMasques do
		if gui.Parent and not gui.Enabled then gui.Enabled = true end
	end
	table.clear(guisMasques)
	for i, type in INTERFACES do
		if interfacesAvant[i] ~= nil then pcall(StarterGui.SetCoreGuiEnabled, StarterGui, type, interfacesAvant[i]) end
	end
	table.clear(interfacesAvant)
	pcall(function() ProximityPromptService.Enabled = invitesAvant end)
	if controlesCoupes and controles then pcall(function() controles:Enable() end) end
	controlesCoupes = false
end

-- ================= Recherche de la scène =================
local function trouverBrom(): Model?
	for _, m in CollectionService:GetTagged("PNJ") do
		if m:IsA("Model") and m:GetAttribute("Service") == "Forge" and m:IsDescendantOf(workspace) then return m end
	end
	return nil
end

-- Grosse enclume = « Table » du modèle Forge (B.forge) ; la petite est dans le modèle de Brom.
local enclumeCache: BasePart? = nil
local function trouverEnclume(brom: Model?): BasePart?
	if enclumeCache and enclumeCache:IsDescendantOf(workspace) then return enclumeCache end
	enclumeCache = nil
	local forge = brom and brom.Parent and brom.Parent:FindFirstChild("Forge")
	local table_ = forge and forge:FindFirstChild("Table")
	if table_ and table_:IsA("BasePart") then enclumeCache = table_; return table_ end
	local meilleure, distance = nil, math.huge
	for _, d in workspace:GetDescendants() do
		if d.Name == "Table" and d:IsA("BasePart") and d.Parent and d.Parent.Name == "Forge" then
			local dist = if brom then (d.Position - brom:GetPivot().Position).Magnitude else 0
			if dist < distance then meilleure, distance = d, dist end
		end
	end
	enclumeCache = meilleure
	return meilleure
end

-- ================= Objet forgé =================
local function piece(parent: Instance, taille: Vector3, cf: CFrame, couleur: Color3, materiau: Enum.Material, nom: string): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.CFrame = cf
	p.Color = couleur
	p.Material = materiau
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function substitut(epee: boolean, couleur: Color3): Model
	local m = Instance.new("Model")
	m.Name = "ObjetForge"
	if epee then
		m.PrimaryPart = piece(m, V(0.3, 0.8, 0.3), CFrame.identity, Color3.fromRGB(92, 60, 38), Enum.Material.Fabric, "Poignee")
		piece(m, V(1.3, 0.2, 0.36), CFrame.new(0, 0.5, 0), Color3.fromRGB(200, 150, 70), Enum.Material.Metal, "Garde")
		piece(m, V(0.5, 2.3, 0.14), CFrame.new(0, 1.75, 0), couleur, Enum.Material.Metal, "Lame")
		piece(m, V(0.3, 0.3, 0.3), CFrame.new(0, -0.5, 0), Color3.fromRGB(200, 150, 70), Enum.Material.Metal, "Pommeau")
	else
		local dome = piece(m, V(1.6, 1.5, 1.7), CFrame.identity, couleur, Enum.Material.Metal, "Racine")
		Instance.new("SpecialMesh", dome).MeshType = Enum.MeshType.Sphere
		piece(m, V(1.8, 0.18, 1.9), CFrame.new(0, -0.55, 0), couleur:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Metal, "Bord")
		m.PrimaryPart = dome
	end
	return m
end

local function construireObjet(donnees): Model
	local epee = donnees.type == "Epee"
	local ok, couleur = pcall(Color3.fromHex, donnees.couleur)
	couleur = if ok then couleur else Color3.fromRGB(170, 176, 186)
	local id = donnees.modele
	local reussi, modele = pcall(function()
		local module = require(Partage:WaitForChild(if epee then "ArmesVoxels" else "ArmuresVoxels")) :: any
		if type(id) == "string" and module.existe(id) then
			return if epee then module.construire(id) else module.construire(id, couleur)
		end
		return nil
	end)
	return if reussi and modele then modele else substitut(epee, couleur)
end

-- Pose l'objet sur l'enclume et mesure sa boîte dans le repère F.
local function poserObjet(etat, objet: Model)
	local rot = if etat.epee then CFrame.fromMatrix(Vector3.zero, V(0, 0, 1), V(1, 0, 0), V(0, 1, 0)) else CFrame.Angles(0, math.pi, 0)
	objet:PivotTo(etat.F * rot)
	local mn, mx = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	local pieces, lame = {}, nil
	for _, p in objet:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			if p.Transparency < 1 then
				table.insert(pieces, {p, p.Transparency})
				local d = p.Size / 2
				for _, s in {V(1, 1, 1), V(1, 1, -1), V(1, -1, 1), V(1, -1, -1), V(-1, 1, 1), V(-1, 1, -1), V(-1, -1, 1), V(-1, -1, -1)} do
					local c = etat.F:PointToObjectSpace(p.CFrame:PointToWorldSpace(d * s))
					mn, mx = mn:Min(c), mx:Max(c)
				end
				if p.Name == "Lame" and not lame then lame = p end
			end
		elseif p:IsA("Light") or p:IsA("ParticleEmitter") then
			table.insert(etat.effetsObjet, {p, p.Enabled})
			p.Enabled = false
		end
	end
	if #pieces == 0 then return end
	local decalage = V(-(mn.X + mx.X) / 2, -mn.Y, ZC - (mn.Z + mx.Z) / 2)
	objet:PivotTo(etat.F * CFrame.new(decalage) * rot)
	local taille = mx - mn
	for _, pc in pieces do pc[1].Transparency = 1 end
	etat.piecesObjet = pieces
	etat.hObjet = taille.Y
	etat.dist = 2.4 + math.max(taille.X, taille.Z) * 0.75
	if etat.epee then
		etat.cible = V(taille.X, 0.22, if lame then math.min(lame.Size.X, taille.Z) else taille.Z * 0.4)
	else
		etat.cible = V(taille.X, 0.3, taille.Z)
		etat.cibleDome = taille * 0.95
	end
	local surbrillance = Instance.new("Highlight")
	surbrillance.FillColor = LAVE
	surbrillance.FillTransparency = 0.2
	surbrillance.OutlineTransparency = 1
	surbrillance.DepthMode = Enum.HighlightDepthMode.Occluded
	surbrillance.Enabled = false
	surbrillance.Parent = objet
	etat.surbrillance = surbrillance
	objet.Parent = etat.dossier
	etat.objet = objet
end

-- ================= Brom (clone local animé) =================
local function lirePose(nom: string)
	local p = POSES and POSES[nom] or {}
	local function bras(v)
		local r = table.create(7, 0)
		for i, a in v or {} do r[i] = a end
		return r
	end
	return {D = bras(p.D), G = bras(p.G), tete = {(p.tete or {})[1] or 0, (p.tete or {})[2] or 0}, buste = p.buste or 0}
end
local POSES_LUES = {}
for _, cle in CLES do POSES_LUES[cle[2]] = POSES_LUES[cle[2]] or lirePose(cle[2]) end
local pose = lirePose("repos")

local function melanger(a, b, w: number)
	pose.buste = a.buste + (b.buste - a.buste) * w
	pose.tete[1] = a.tete[1] + (b.tete[1] - a.tete[1]) * w
	pose.tete[2] = a.tete[2] + (b.tete[2] - a.tete[2]) * w
	for i = 1, 7 do
		pose.D[i] = a.D[i] + (b.D[i] - a.D[i]) * w
		pose.G[i] = a.G[i] + (b.G[i] - a.G[i]) * w
	end
end

local function poseA(t: number)
	local k = 1
	while k < #CLES and t >= CLES[k + 1][1] do k += 1 end
	local a, b = CLES[k], CLES[math.min(k + 1, #CLES)]
	if a == b then
		melanger(POSES_LUES[a[2]], POSES_LUES[a[2]], 0)
	else
		melanger(POSES_LUES[a[2]], POSES_LUES[b[2]], COURBES[b[3]]((t - a[1]) / (b[1] - a[1])))
	end
end

local function autour(b, P: Vector3, rot: CFrame): CFrame
	return CFrame.new(P) * b.R * rot * b.Rinv * CFrame.new(-P)
end

local function poserBrom(b, souffle: number)
	local pv, T = b.pivots, b.T
	local Tb = CFrame.new(0, souffle, 0) * autour(b, pv.Buste, CFrame.Angles(pose.buste, 0, 0))
	T.Buste = Tb
	T.Tete = Tb * autour(b, pv.Tete, CFrame.Angles(0, pose.tete[2], 0) * CFrame.Angles(pose.tete[1], 0, 0))
	for _, cote in COTES do
		local a = pose[cote]
		local Tbr = Tb * autour(b, pv["Bras" .. cote], CFrame.Angles(0, 0, a[3]) * CFrame.Angles(0, a[2], 0) * CFrame.Angles(a[1], 0, 0))
		local Tav = Tbr * autour(b, pv["AvBras" .. cote], CFrame.Angles(a[4], 0, 0) * CFrame.Angles(0, a[5], 0))
		T["Bras" .. cote] = Tbr
		T["AvBras" .. cote] = Tav
		T["Main" .. cote] = Tav * autour(b, pv["Main" .. cote], CFrame.Angles(a[6], 0, 0) * CFrame.Angles(0, 0, a[7]))
	end
	for g, pieces in b.groupes do
		local M = T[g]
		for _, pc in pieces do pc[1].CFrame = M * pc[2] end
	end
end

-- Clone de Brom déplacé pour que son marteau tombe sur le lingot ; estrade en bois s'il doit être surélevé.
local function preparerBrom(etat, brom: Model): boolean
	if not brom:GetAttribute("Squelette") or not POSES then return false end
	local clone = brom:Clone()
	if not clone then return false end
	CollectionService:RemoveTag(clone, "PNJ")
	for _, objet in clone:GetDescendants() do
		for _, classe in A_RETIRER do
			if objet:IsA(classe) then objet:Destroy(); break end
		end
	end
	local etincelles = clone:FindFirstChild("Etincelles")
	if etincelles then etincelles:Destroy() end
	local corps = clone:FindFirstChild("Corps")
	local lueur = corps and corps:FindFirstChild(brom.Name .. "_Corps_Lueur") :: BasePart?
	if not lueur then clone:Destroy(); return false end
	local impact = lueur.Position
	for _, p in corps:GetChildren() do
		if p:IsA("BasePart") and ENCLUME_BROM[string.match(p.Name, "_([^_]+)$") or ""] and (p.Position - impact).Magnitude < 2 then
			p.Transparency = 1
		end
	end
	local decalage = etat.F * V(0, 0.5, ZC - 0.05) - (impact + V(0, 0.04, 0))
	local pied = clone:GetPivot()
	local boite, tailleBoite = clone:GetBoundingBox()
	local sol = boite.Position.Y - tailleBoite.Y / 2
	clone:PivotTo(pied + decalage)
	local b = {R = pied.Rotation, Rinv = pied.Rotation:Inverse(), groupes = {}, pivots = {}, T = {}}
	for _, g in GROUPES do
		local groupe = clone:FindFirstChild(g)
		local repere = groupe and groupe:FindFirstChild(brom.Name .. "_" .. g .. "_Pivot")
		if not repere then clone:Destroy(); return false end
		b.pivots[g] = (repere :: BasePart).Position
		local pieces = {}
		for _, p in groupe:GetDescendants() do
			if p:IsA("BasePart") then table.insert(pieces, {p, p.CFrame}) end
		end
		b.groupes[g] = pieces
	end
	for _, p in clone:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
			p.LocalTransparencyModifier = 0
		end
	end
	if decalage.Y > 0.15 then
		local dos = (etat.F.Position - pied.Position) * V(1, 0, 1)
		dos = if dos.Magnitude > 0.01 then -dos.Unit else Vector3.zero
		local centre = (pied.Position + decalage + dos * 0.25) * V(1, 0, 1) + V(0, sol + decalage.Y / 2, 0)
		piece(etat.dossier, V(2.4, decalage.Y, 1.6), CFrame.new(centre) * pied.Rotation, Color3.fromRGB(110, 76, 48), Enum.Material.WoodPlanks, "Estrade")
	end
	clone.Name = brom.Name
	clone.Parent = etat.dossier
	etat.brom = b
	-- le vrai Brom (figé au repos par AnimationsNains) est caché localement
	for _, d in brom:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
			table.insert(etat.caches, d)
		elseif d:IsA("BillboardGui") and d.Enabled then
			d.Enabled = false
			table.insert(etat.etiquettes, d)
		end
	end
	return true
end

-- ================= Lingot, étincelles, sons =================
local function preparerLingot(etat)
	local lingot = piece(etat.dossier, S0, etat.F * CFrame.new(0, S0.Y / 2, ZC), LAVE, Enum.Material.Neon, "Lingot")
	lingot.CastShadow = false
	local dome = nil
	if not etat.epee then
		dome = piece(etat.dossier, V(0.05, 0.05, 0.05), lingot.CFrame, LAVE, Enum.Material.Neon, "Dome")
		dome.CastShadow = false
		Instance.new("SpecialMesh", dome).MeshType = Enum.MeshType.Sphere
	end
	local lumiere = Instance.new("PointLight")
	lumiere.Color = Color3.fromRGB(255, 120, 40)
	lumiere.Range = 12
	lumiere.Brightness = 2
	lumiere.Shadows = true
	lumiere.Parent = lingot
	local point = Instance.new("Attachment")
	point.Parent = lingot
	local function emetteur(texture: string): ParticleEmitter
		local e = Instance.new("ParticleEmitter")
		e.Texture = texture
		e.Rate = 0
		e.LightEmission = 1
		e.Parent = point
		return e
	end
	local gerbe = emetteur("rbxasset://textures/particles/sparkles_main.dds")
	gerbe.Lifetime = NumberRange.new(0.25, 0.6)
	gerbe.Speed = NumberRange.new(8, 18)
	gerbe.SpreadAngle = Vector2.new(80, 80)
	gerbe.Acceleration = V(0, -50, 0)
	gerbe.Drag = 2
	gerbe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0)})
	gerbe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 100, 24))
	local braises = emetteur("rbxasset://textures/particles/sparkles_main.dds")
	braises.Rate = 7
	braises.Lifetime = NumberRange.new(0.6, 1.2)
	braises.Speed = NumberRange.new(1, 3)
	braises.SpreadAngle = Vector2.new(30, 30)
	braises.Acceleration = V(0, 3, 0)
	braises.Size = NumberSequence.new(0.08, 0)
	braises.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50))
	local vapeur = emetteur("rbxasset://textures/particles/smoke_main.dds")
	vapeur.LightEmission = 0
	vapeur.Lifetime = NumberRange.new(0.8, 1.4)
	vapeur.Speed = NumberRange.new(2, 4)
	vapeur.SpreadAngle = Vector2.new(25, 25)
	vapeur.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2)})
	vapeur.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
	vapeur.Color = ColorSequence.new(Color3.fromRGB(230, 230, 230))
	local function son(id: string, volume: number): Sound
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.RollOffMaxDistance = 80
		s.Parent = lingot
		return s
	end
	etat.lingot, etat.dome, etat.lumiere, etat.point = lingot, dome, lumiere, point
	etat.gerbe, etat.braises, etat.vapeur = gerbe, braises, vapeur
	etat.sonMarteau = son("rbxasset://sounds/unsheath.wav", 0.9)
	etat.sonTrempe = son("rbxasset://sounds/impact_water.mp3", 0.7)
	etat.sonTrempe.PlaybackSpeed = 1.5
end

-- ================= Boucle =================
local actif = nil
local hasard = Random.new()

local function restaurer(etat)
	for _, c in etat.connexions do c:Disconnect() end
	etat.dossier:Destroy()
	for _, p in etat.caches do
		if p.Parent then p.LocalTransparencyModifier = 0 end
	end
	for _, p in etat.perso do
		if p.Parent then p.LocalTransparencyModifier = 0 end
	end
	for _, g in etat.etiquettes do
		if g.Parent then g.Enabled = true end
	end
	local camera = etat.camera
	if camera.Parent then
		camera.FieldOfView = etat.fov
		camera.CameraType = Enum.CameraType.Custom
		local humain = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
		if humain then camera.CameraSubject = humain end
	end
end

local function terminer(etat)
	if actif ~= etat then return end
	actif = nil
	joueur:SetAttribute(ATTRIBUT, false)
	RunService:UnbindFromRenderStep(LIAISON)
	local ok, erreur = pcall(restaurer, etat)
	if not ok then warn("[ForgeCinematique]", erreur) end
	afficherInterface()
	animerEcran(1, 0, OUVERTURE)
end

local function impact(etat, n: number)
	etat.pCible = n / COUPS
	etat.flash, etat.ecrase, etat.secousse = 1, 1, 1
	etat.gerbe:Emit(hasard:NextInteger(18, 26))
	etat.sonMarteau.PlaybackSpeed = hasard:NextNumber(1.55, 1.8)
	etat.sonMarteau:Play()
end

local function etape(etat, dt: number)
	local camera = etat.camera
	if workspace.CurrentCamera ~= camera or not etat.lingot.Parent then terminer(etat); return end
	local t = os.clock() - etat.debut
	if t >= DUREE then
		voile.BackgroundTransparency = 0
		terminer(etat)
		return
	end
	while etat.coup < COUPS and t >= IMPACTS[etat.coup + 1] do
		etat.coup += 1
		impact(etat, etat.coup)
	end
	local amorti = math.exp(-dt * 11)
	etat.flash *= amorti
	etat.ecrase *= amorti
	etat.secousse *= math.exp(-dt * 16)
	etat.p += (etat.pCible - etat.p) * (1 - math.exp(-dt * 14))
	local p = lisse(etat.p)

	-- refroidissement, puis l'objet apparaît dans le lingot qui s'efface
	local froid = lisse((t - REVELE) / 0.8)
	local apparition = lisse((t - REVELE) / 0.65)
	if t >= REVELE and not etat.revele then
		etat.revele = true
		etat.braises.Enabled = false
		etat.vapeur:Emit(14)
		etat.sonTrempe:Play()
		if etat.surbrillance then etat.surbrillance.Enabled = true end
		for _, e in etat.effetsObjet do e[1].Enabled = e[2] end
	end

	local s = etat.ecrase
	local taille = S0:Lerp(etat.cible, p) * V(1 + 0.16 * s, 1 - 0.32 * s, 1 + 0.16 * s)
	local lingot = etat.lingot
	lingot.Size = taille
	lingot.CFrame = etat.F * CFrame.new(0, taille.Y / 2, ZC)
	local couleur = LAVE:Lerp(BLANC_CHAUD, etat.flash * 0.8 + 0.06 * math.sin(t * 9)):Lerp(FROID, froid)
	lingot.Color = couleur
	lingot.Transparency = apparition
	etat.lumiere.Brightness = (2 + etat.flash * 6) * (1 - froid)
	etat.point.Position = V(0, taille.Y / 2, 0)
	if etat.dome and etat.cibleDome then
		local pd = lisse((etat.p - 0.15) / 0.85)
		local td = etat.cibleDome * math.max(pd, 0.02) * V(1 + 0.1 * s, 1 - 0.2 * s, 1 + 0.1 * s)
		etat.dome.Size = td
		etat.dome.CFrame = etat.F * CFrame.new(0, taille.Y + td.Y * 0.38, ZC)
		etat.dome.Color = couleur
		etat.dome.Transparency = apparition
	end
	if etat.piecesObjet then
		for _, pc in etat.piecesObjet do pc[1].Transparency = pc[2] + (1 - pc[2]) * (1 - apparition) end
		if etat.surbrillance then etat.surbrillance.FillTransparency = 0.2 + 0.8 * lisse((t - REVELE - 0.2) / 1.2) end
	end

	if etat.brom then
		poseA(t)
		poserBrom(etat.brom, math.sin(t * 1.6) * 0.03)
	end
	for _, piece in etat.perso do piece.LocalTransparencyModifier = 1 end

	local plan = PLANS[etat.plan]
	while t >= plan.fin and PLANS[etat.plan + 1] do
		etat.plan += 1
		plan = PLANS[etat.plan]
		camera.FieldOfView = plan.fov
	end
	local debut = if etat.plan > 1 then PLANS[etat.plan - 1].fin else 0
	local k = etat.secousse * 0.012
	etat.secousseCF = CFrame.Angles(k * math.sin(t * 47), k * math.sin(t * 39), 0)
	camera.CFrame = plan.camera(etat, (t - debut) / (plan.fin - debut))
	if plan.fondu then voile.BackgroundTransparency = math.clamp((plan.fin - t) / plan.fondu, 0, 1) end
end

local function lancer(donnees): boolean
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if not (perso and humain and humain.Health > 0 and camera) then return false end
	local brom = trouverBrom()
	local enclume = trouverEnclume(brom)
	if not enclume then return false end
	RunService.RenderStepped:Wait() -- AnimationsNains remet Brom au repos (attribut posé)
	RunService.RenderStepped:Wait()
	if not (enclume.Parent and perso.Parent and humain.Health > 0) then return false end

	local haut = enclume.CFrame * V(0, enclume.Size.Y / 2, 0)
	local versBrom = if brom then (brom:GetPivot().Position - haut) * V(1, 0, 1) else enclume.CFrame.ZVector
	if versBrom.Magnitude < 0.01 then versBrom = enclume.CFrame.ZVector end
	local dossier = Instance.new("Folder")
	dossier.Name = "CinematiqueForge"
	local etat = {
		camera = camera, fov = camera.FieldOfView, dossier = dossier, epee = donnees.type == "Epee",
		F = CFrame.lookAt(haut, haut + versBrom.Unit), cible = V(3.4, 0.22, 0.5), cibleDome = nil, hObjet = 1, dist = 5,
		caches = {}, perso = {}, etiquettes = {}, connexions = {}, effetsObjet = {},
		debut = 0, plan = 1, coup = 0, p = 0, pCible = 0, flash = 0, ecrase = 0, secousse = 0, secousseCF = CFrame.identity,
	}
	if not etat.epee then etat.cible, etat.cibleDome = V(1.8, 0.3, 1.9), V(1.6, 1.5, 1.7) end
	actif = etat
	local ok, erreur = pcall(function()
		-- le marteau posé sur la grosse enclume gênerait le lingot
		for _, nom in {"Marteau", "TeteMarteau"} do
			local d = enclume.Parent:FindFirstChild(nom)
			if d and d:IsA("BasePart") and (d.Position - haut).Magnitude < 3 then
				d.LocalTransparencyModifier = 1
				table.insert(etat.caches, d)
			end
		end
		preparerLingot(etat)
		if brom then preparerBrom(etat, brom) end
		for _, d in perso:GetDescendants() do
			if d:IsA("BasePart") then table.insert(etat.perso, d) end
		end
		dossier.Parent = workspace
	end)
	if not ok then
		warn("[ForgeCinematique]", erreur)
		actif = nil
		dossier:Destroy()
		for _, p in etat.caches do p.LocalTransparencyModifier = 0 end
		for _, g in etat.etiquettes do g.Enabled = true end
		return false
	end
	-- le casque peut prendre un court instant à se construire (CSG) : en parallèle
	task.spawn(function()
		local objet = construireObjet(donnees)
		if actif == etat and dossier.Parent then
			local reussi, e = pcall(poserObjet, etat, objet)
			if not reussi then warn("[ForgeCinematique]", e); objet:Destroy() end
		else
			objet:Destroy()
		end
	end)
	table.insert(etat.connexions, humain.Died:Connect(function() terminer(etat) end))
	task.delay(DUREE + 4, terminer, etat)
	etat.debut = os.clock()
	local pret, erreurDebut = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = PLANS[1].fov
		voile.BackgroundTransparency = 1
		animerEcran(1, BANDES, 0.45)
		masquerInterface()
	end)
	if not pret then
		warn("[ForgeCinematique]", erreurDebut)
		terminer(etat)
		return true
	end
	local dernier = os.clock()
	RunService:BindToRenderStep(LIAISON, Enum.RenderPriority.Camera.Value + 1, function()
		local maintenant = os.clock()
		local dt = math.min(maintenant - dernier, 0.1)
		dernier = maintenant
		local reussi, e = pcall(etape, etat, dt)
		if not reussi then warn("[ForgeCinematique]", e); terminer(etat) end
	end)
	return true
end

-- Repli (Brom ou enclume non chargés) : simple fondu au noir.
local function fondu()
	animerEcran(0, 0, 0.35)
	task.wait(0.9)
	animerEcran(1, 0, 0.5)
	task.wait(0.3)
	joueur:SetAttribute(ATTRIBUT, false)
end

local occupe = false
evenement.OnClientEvent:Connect(function(donnees)
	if occupe or actif then return end
	occupe = true
	if type(donnees) ~= "table" then donnees = {} end
	joueur:SetAttribute(ATTRIBUT, true)
	local ok, lance = pcall(lancer, donnees)
	if not ok then
		warn("[ForgeCinematique]", lance)
		if actif then terminer(actif) end
	end
	if not (ok and lance) then fondu() end
	occupe = false
end)

joueur.CharacterRemoving:Connect(function()
	if actif then terminer(actif) end
end)
