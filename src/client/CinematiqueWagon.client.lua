-- Voyage en wagon (aller vers la mine, retour vers la gare) : cinématique locale en plans de film,
-- jouée avec des clones du wagon et du passager. Le serveur a validé le départ et téléporte le vrai personnage.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local joueur = Players.LocalPlayer
local evenement = ReplicatedStorage:WaitForChild("VoyageWagon") :: RemoteEvent
local pret = ReplicatedStorage:WaitForChild("VoyageWagonPret") :: RemoteEvent

local LIAISON = "CinematiqueWagon"
local BANDES = 0.11 -- hauteur de chaque bande noire (part de l'écran)
local NOIR = 0.35 -- temps minimal au noir entre le dernier plan et le retour au joueur
local OUVERTURE = 0.8
local ATTENTE_ARRIVEE = 3
local MASQUE_PERSO = 2 -- le vrai personnage reste caché jusqu'à sa téléportation
local BASCULE = 4 -- longueur (studs) de la bascule du wagon entre deux pentes
local INTERFACES = {Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.EmotesMenu, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health}
local A_RETIRER = {"JointInstance", "Constraint", "WeldConstraint", "NoCollisionConstraint", "LuaSourceContainer", "Sound", "ProximityPrompt", "Animator", "ForceField", "BillboardGui", "Seat"}

-- Plans par sens, joués dans l'ordre avec une coupe franche entre chacun.
-- s0 → s1 : portion de voie parcourue (studs depuis le départ) ; avance(u) : progression 0..1 du wagon.
-- camera(c, u, voie) : CFrame de la caméra ; c = contexte (repères c.gare, c.haut, c.bas, c.quai, temps c.t),
-- voie = CFrame du wagon sans cahots. Options : etincelles (sous les roues arrière), fondu (secondes de fondu au noir en fin de plan).
-- Voie : gare → haut 107 studs, haut → bas 134, bas → quai 44.
local PLANS = {
	aller = {
		{
			nom = "DepartGare", duree = 4.8, fov = 50, s0 = 0, s1 = 78,
			avance = function(u) return u * u * (0.6 + 0.4 * u) end,
			-- 3/4 arrière, en hauteur, léger travelling : le wagon s'éloigne dans le tunnel.
			camera = function(c, u, voie)
				return CFrame.lookAt(c.gare + Vector3.new(8, 4 + 0.6 * u, 9 - 6 * u), voie.Position + Vector3.new(0, 1.2, 0))
			end,
		},
		{
			nom = "Descente", duree = 3.8, fov = 72, s0 = 72, s1 = 190, etincelles = true, fondu = 0.6,
			avance = function(u) return u * (0.8 + 0.2 * u) end,
			-- Caméra basse au bord de la descente : le wagon arrive, la frôle puis plonge.
			camera = function(c, u, voie)
				local position = c.haut + Vector3.new(4.6, -1.7, 4)
				local secousse = math.clamp(1 - (voie.Position - position).Magnitude / 14, 0, 1) * 0.12
				return CFrame.lookAt(position, voie.Position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(secousse * math.sin(c.t * 41), secousse * math.sin(c.t * 33), 0)
			end,
		},
	},
	retour = {
		{
			nom = "DepartQuai", duree = 4.4, fov = 55, s0 = 0, s1 = 70,
			avance = function(u) return u * u * (0.6 + 0.4 * u) end,
			-- 3/4 arrière depuis le quai souterrain : le wagon démarre et attaque la pente.
			camera = function(c, u, voie)
				return CFrame.lookAt(c.quai + Vector3.new(-7, 4 + 0.5 * u, -9 + 5 * u), voie.Position + Vector3.new(0, 1.2, 0))
			end,
		},
		{
			nom = "ArriveeGare", duree = 4.2, fov = 60, s0 = 230, s1 = 285, etincelles = true, fondu = 0.7,
			-- Freinage jusqu'à l'arrêt devant la gare, puis court temps immobile.
			avance = function(u)
				local v = 1 - math.min(u / 0.85, 1)
				return 1 - v * v
			end,
			-- Caméra fixe côté gare : le wagon sort du tunnel vers la lumière et freine.
			camera = function(c, u, voie)
				return CFrame.lookAt(c.gare + Vector3.new(6, 5, 14), voie.Position + Vector3.new(0, 1.2, 0))
			end,
		},
	},
}
local DUREES = {}
for sens, plans in PLANS do
	DUREES[sens] = 0
	for _, plan in plans do DUREES[sens] += plan.duree end
end

local ecran = Instance.new("ScreenGui")
ecran.Name = "CinematiqueWagon"
ecran.IgnoreGuiInset = true
ecran.ResetOnSpawn = false
ecran.DisplayOrder = 100
ecran.Parent = joueur:WaitForChild("PlayerGui")
local function cadreNoir(nom: string): Frame
	local f = Instance.new("Frame")
	f.Name = nom
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Parent = ecran
	return f
end
local voile = cadreNoir("Voile")
voile.Size = UDim2.fromScale(1, 1)
voile.BackgroundTransparency = 1
voile.ZIndex = 2
local bandeHaut = cadreNoir("BandeHaut")
bandeHaut.Size = UDim2.fromScale(1, 0)
local bandeBas = cadreNoir("BandeBas")
bandeBas.AnchorPoint = Vector2.new(0, 1)
bandeBas.Position = UDim2.fromScale(0, 1)
bandeBas.Size = UDim2.fromScale(1, 0)

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

local controles = nil
do
	local scripts = joueur:WaitForChild("PlayerScripts", 10)
	local module = scripts and scripts:WaitForChild("PlayerModule", 10)
	if module then
		local ok, resultat = pcall(function() return (require(module :: any) :: any):GetControls() end)
		if ok then controles = resultat end
	end
end

local guisMasques = {}
local interfacesAvant = {}
local invitesAvant = true
local masque = false
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
		interfacesAvant[i] = ok and active
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, type, false)
	end
	invitesAvant = ProximityPromptService.Enabled
	pcall(function() ProximityPromptService.Enabled = false end)
	if controles then controles:Disable() end
end
local function afficherInterface()
	if not masque then return end
	masque = false
	for _, gui in guisMasques do
		if gui.Parent then gui.Enabled = true end
	end
	table.clear(guisMasques)
	for i, type in INTERFACES do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, type, interfacesAvant[i] == true)
	end
	pcall(function() ProximityPromptService.Enabled = invitesAvant end)
	if controles then controles:Enable() end
end

-- Position sur la voie (polyligne de repères), avec une bascule douce aux changements de pente.
local function surVoie(c, s: number): CFrame
	local segments = c.segments
	local n = #segments
	local i = 1
	while i < n and s > segments[i].fin do i += 1 end
	local seg = segments[i]
	local l = math.clamp(s - seg.debut, 0, seg.longueur)
	local rotation = seg.rotation
	if i > 1 and l < BASCULE then
		rotation = segments[i - 1].rotation:Lerp(rotation, 0.5 + 0.5 * l / BASCULE)
	elseif i < n and seg.longueur - l < BASCULE then
		rotation = rotation:Lerp(segments[i + 1].rotation, 0.5 - 0.5 * (seg.longueur - l) / BASCULE)
	end
	return CFrame.new(seg.a + seg.direction * l) * rotation
end

local function preparerClone(modele: Model, pieces: {BasePart})
	for _, objet in modele:GetDescendants() do
		for _, classe in A_RETIRER do
			if objet:IsA(classe) then objet:Destroy(); break end
		end
	end
	for _, objet in modele:GetDescendants() do
		if objet:IsA("BasePart") then
			objet.Anchored = true
			objet.CanCollide = false
			objet.CanTouch = false
			objet.CanQuery = false
			objet.Massless = true
			table.insert(pieces, objet)
		end
	end
end

local function etincelles(fond: BasePart, x: number): ParticleEmitter
	local point = Instance.new("Attachment")
	point.Position = Vector3.new(x, -2.05, 2.1)
	point.Parent = fond
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 130), Color3.fromRGB(255, 120, 40))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.2, 0)
	e.Lifetime = NumberRange.new(0.15, 0.35)
	e.Rate = 90
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(35, 35)
	e.Acceleration = Vector3.new(0, -40, 0)
	e.EmissionDirection = Enum.NormalId.Back
	e.Enabled = false
	e.Parent = point
	return e
end

local actif = nil

local function terminer(etat)
	if actif ~= etat then return end
	actif = nil
	RunService:UnbindFromRenderStep(LIAISON)
	for _, connexion in etat.connexions do connexion:Disconnect() end
	etat.dossier:Destroy()
	for _, piece in etat.caches do
		if piece.Parent then piece.LocalTransparencyModifier = 0 end
	end
	local camera = etat.camera
	if camera.Parent then
		camera.FieldOfView = etat.fov
		camera.CameraType = Enum.CameraType.Custom
		local humain = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
		if humain then camera.CameraSubject = humain end
	end
	afficherInterface()
	animerEcran(1, 0, OUVERTURE)
end

-- Écran noir : attendre l'arrivée du vrai personnage, placer la caméra derrière lui, puis ouvrir.
local function finir(etat)
	voile.BackgroundTransparency = 0
	etat.dossier:Destroy()
	task.wait(NOIR)
	local limite = os.clock() + ATTENTE_ARRIVEE
	local racine
	while actif == etat do
		local perso = joueur.Character
		racine = perso and perso:FindFirstChild("HumanoidRootPart")
		if (racine and (racine.Position - etat.arrivee.Position).Magnitude < 12) or os.clock() > limite then break end
		task.wait(0.1)
	end
	if actif ~= etat then return end
	if racine and racine:IsA("BasePart") and etat.camera.Parent then
		local cf = racine.CFrame
		etat.camera.CFrame = CFrame.lookAt(cf.Position - cf.LookVector * 10 + Vector3.new(0, 4, 0), cf.Position + Vector3.new(0, 1.5, 0))
	end
	terminer(etat)
end

local function etape(etat)
	local camera = etat.camera
	if workspace.CurrentCamera ~= camera or not etat.fond.Parent then terminer(etat); return end
	local t = os.clock() - etat.debut
	local plan = etat.plans[etat.indice]
	while t >= etat.finPlan do
		etat.indice += 1
		plan = etat.plans[etat.indice]
		if not plan then
			RunService:UnbindFromRenderStep(LIAISON)
			task.spawn(finir, etat)
			return
		end
		etat.debutPlan = etat.finPlan
		etat.finPlan += plan.duree
		etat.sPrecedent = plan.s0
		camera.FieldOfView = plan.fov
		for _, e in etat.etincelles do e.Enabled = plan.etincelles == true end
	end
	if t < MASQUE_PERSO then
		for _, piece in etat.perso do piece.LocalTransparencyModifier = 1 end
	end
	local u = math.clamp((t - etat.debutPlan) / plan.duree, 0, 1)
	local s = plan.s0 + (plan.s1 - plan.s0) * plan.avance(u)
	local dt = t - etat.t
	if dt > 0 then etat.vitesse = (s - etat.sPrecedent) / dt end
	etat.sPrecedent, etat.t = s, t
	local voie = surVoie(etat, s)
	local k = math.clamp(etat.vitesse / 30, 0, 1)
	etat.fond.CFrame = voie * CFrame.new(0, k * (0.05 * math.sin(t * 23) + 0.035 * math.sin(t * 37.3)), 0)
		* CFrame.Angles(k * 0.012 * math.sin(t * 13.1), 0, k * 0.02 * math.sin(t * 17.9))
	camera.CFrame = plan.camera(etat, u, voie)
	if plan.fondu then voile.BackgroundTransparency = math.clamp((etat.finPlan - t) / plan.fondu, 0, 1) end
end

local function lancer(sens: string, wagon: Model, points: {Vector3}, arrivee: CFrame, autre: Model?): boolean
	if actif then terminer(actif) end
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if not (perso and humain and humain.Health > 0 and camera and wagon.PrimaryPart) then return false end

	local cloneWagon = wagon:Clone()
	local archivable = perso.Archivable
	perso.Archivable = true
	local passager = perso:Clone()
	perso.Archivable = archivable
	local fond = cloneWagon.PrimaryPart
	if not fond then cloneWagon:Destroy(); if passager then passager:Destroy() end; return false end

	local dossier = Instance.new("Folder")
	dossier.Name = "CinematiqueWagon"
	local pieces = {}
	preparerClone(cloneWagon, pieces)
	cloneWagon.Parent = dossier
	if passager then
		preparerClone(passager, pieces)
		local clone = passager:FindFirstChildOfClass("Humanoid")
		if clone then
			clone.RequiresNeck = false
			clone.BreakJointsOnDeath = false
			clone.EvaluateStateMachine = false
			clone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			clone.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
		passager.Name = "PassagerCinematique"
		passager.Parent = dossier
	end
	dossier.Parent = workspace
	-- Tout est soudé au fond ancré : un seul CFrame déplacé par image.
	for _, piece in pieces do
		if piece ~= fond then
			local soudure = Instance.new("WeldConstraint")
			soudure.Part0 = fond
			soudure.Part1 = piece
			soudure.Parent = piece
			piece.Anchored = false
		end
	end

	local segments = {}
	local cumul = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local longueur = (b - a).Magnitude
		if longueur > 0.01 then
			table.insert(segments, {a = a, direction = (b - a) / longueur, longueur = longueur, debut = cumul, fin = cumul + longueur, rotation = CFrame.lookAt(a, b).Rotation})
			cumul += longueur
		end
	end
	if #segments == 0 then dossier:Destroy(); return false end

	local etat = {
		camera = camera, fov = camera.FieldOfView, dossier = dossier, fond = fond, arrivee = arrivee,
		plans = PLANS[sens], segments = segments,
		gare = points[if sens == "aller" then 1 else 4], haut = points[if sens == "aller" then 2 else 3],
		bas = points[if sens == "aller" then 3 else 2], quai = points[if sens == "aller" then 4 else 1],
		etincelles = {etincelles(fond, -2.5), etincelles(fond, 2.5)},
		caches = {}, perso = {}, connexions = {},
		debut = os.clock(), indice = 0, debutPlan = 0, finPlan = 0, sPrecedent = 0, t = 0, vitesse = 0,
	}
	-- Les vrais wagons restent en place : on les cache localement, comme le vrai passager avant sa téléportation.
	for _, modele in {wagon, autre} do
		for _, objet in modele:GetDescendants() do
			if objet:IsA("BasePart") then
				objet.LocalTransparencyModifier = 1
				table.insert(etat.caches, objet)
			end
		end
	end
	-- Avec StreamingEnabled, le wagon d'arrivée peut apparaître pendant la cinématique : le cacher aussi.
	local terminus = points[#points]
	table.insert(etat.connexions, workspace.DescendantAdded:Connect(function(objet)
		if objet:IsA("BasePart") and (objet.Position - terminus).Magnitude < 8 then
			local modele = objet:FindFirstAncestorWhichIsA("Model")
			if modele and modele.Name == "Wagonnet" and not modele:IsDescendantOf(dossier) then
				objet.LocalTransparencyModifier = 1
				table.insert(etat.caches, objet)
			end
		end
	end))
	for _, objet in perso:GetDescendants() do
		if objet:IsA("BasePart") then
			table.insert(etat.perso, objet)
			table.insert(etat.caches, objet)
		end
	end
	actif = etat
	table.insert(etat.connexions, humain.Died:Connect(function() terminer(etat) end))
	task.delay(DUREES[sens] + NOIR + ATTENTE_ARRIVEE + 3, function() terminer(etat) end)
	camera.CameraType = Enum.CameraType.Scriptable
	voile.BackgroundTransparency = 1
	animerEcran(1, BANDES, 0.45)
	RunService:BindToRenderStep(LIAISON, Enum.RenderPriority.Camera.Value + 1, function() etape(etat) end)
	masquerInterface()
	return true
end

local numeroFondu = 0
local function fondu(duree: number)
	numeroFondu += 1
	local numero = numeroFondu
	animerEcran(0, 0, 0.35)
	task.delay(math.clamp(duree, 0.4, 3), function()
		if numero == numeroFondu and not actif then animerEcran(1, 0, 0.5) end
	end)
end

local function depart(sens, wagon, points, arrivee, autre): boolean
	if not PLANS[sens] or typeof(wagon) ~= "Instance" or not wagon:IsA("Model") or typeof(points) ~= "table" or #points ~= 4 or typeof(arrivee) ~= "CFrame" then return false end
	for _, point in points do
		if typeof(point) ~= "Vector3" then return false end
	end
	if not (typeof(autre) == "Instance" and autre:IsA("Model")) then autre = nil end
	local ok, lance = pcall(lancer, sens, wagon, points, arrivee, autre)
	if not ok and actif then terminer(actif) end
	return ok and lance
end

evenement.OnClientEvent:Connect(function(action, sens, wagon, points, arrivee, autre)
	if action ~= "depart" then return end
	-- L'accusé déclenche la téléportation ; sans cinématique, simple fondu pendant la téléportation.
	if depart(sens, wagon, points, arrivee, autre) then pret:FireServer() else fondu(2) end
end)

joueur.CharacterRemoving:Connect(function()
	if actif then terminer(actif) end
end)
