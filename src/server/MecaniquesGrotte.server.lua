-- Mécaniques signature des grottes profondes · SCRIPT SERVEUR
-- RemoteEvent « MecaniquesGrotte » (client : MecaniquesGrotte.client.lua).
-- −100 m (GrotteMine) :
--   * Course en wagonnet : invite « Monter » (attribut CourseWagon) à la gare ; le serveur vérifie, protège le
--     joueur (ForceField invisible, attribut « EnWagon ») et envoie le tracé (dossier « CourseWagon » de la
--     grotte) ; le client fait rouler le wagonnet et renvoie « WagonFin ». Sécurité : fin forcée après 120 s.
--   * Ascenseur du Grand Puits : plateforme physique (tag « Ascenseur », PrismaticConstraint « Glissiere ») ;
--     les leviers (attribut AscenseurLevier) l'envoient en haut ou en bas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local remote = ReplicatedStorage:FindFirstChild("MecaniquesGrotte")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "MecaniquesGrotte"
	remote.Parent = ReplicatedStorage
end

-- Modèle du wagonnet de la course : copie du wagon de la gare (celui qui descend à la mine), sans siège, scripts
-- ni invites, ancré, recentré pour que sa base (bas, milieu, avant = −Z) soit à l'origine. Le client le clone
-- (ReplicatedStorage › ModeleWagonCourse) ; sans wagon de gare, il garde son wagonnet construit en code.
local A_RETIRER = {"JointInstance", "Constraint", "WeldConstraint", "NoCollisionConstraint", "LuaSourceContainer", "Sound",
	"ProximityPrompt", "Animator", "ForceField", "BillboardGui", "Seat", "ClickDetector"}
local function preparerModeleWagon()
	local depart = os.clock()
	local wagon: Model? = nil
	while not wagon and os.clock() - depart < 90 do
		local carte = workspace:FindFirstChild("Carte")
		local mine = carte and carte:FindFirstChild("Mine")
		local gare = mine and mine:FindFirstChild("Gare")
		if gare then
			for _, d in gare:GetDescendants() do
				if d:IsA("Seat") and d.Name == "SiegeWagon" and d.Parent and d.Parent:IsA("Model") then
					wagon = d.Parent :: Model
					break
				end
			end
		end
		if not wagon then task.wait(2) end
	end
	if not wagon then
		warn("[MecaniquesGrotte] wagon de la gare introuvable : la course garde son wagonnet construit en code")
		return
	end
	local copie = wagon:Clone()
	for _, d in copie:GetDescendants() do
		for _, classe in A_RETIRER do
			if d:IsA(classe) then
				d:Destroy()
				break
			end
		end
	end
	for _, d in copie:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
			d.Massless = true
		end
	end
	-- repère de base : milieu du bas de la boîte englobante, longueur du wagon selon Z
	local cf, taille = copie:GetBoundingBox()
	local base = cf * CFrame.new(0, -taille.Y / 2, 0)
	if taille.X > taille.Z then
		base *= CFrame.Angles(0, math.pi / 2, 0)
	end
	for _, d in copie:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = base:ToObjectSpace(d.CFrame)
		end
	end
	copie.Name = "ModeleWagonCourse"
	copie:SetAttribute("Longueur", math.max(taille.X, taille.Z))
	copie:SetAttribute("Hauteur", taille.Y)
	copie.Parent = ReplicatedStorage
end
task.spawn(preparerModeleWagon)

local function grotteDe(objet: Instance): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	local m = objet
	while m and m.Parent ~= dossier do
		m = m.Parent :: Instance
	end
	return if m and m:IsA("Model") then m else nil
end

local function membre(grotte: Model, joueur: Player): boolean
	return joueur.UserId == grotte:GetAttribute("Proprietaire") or joueur.UserId == grotte:GetAttribute("Invite")
end

local function racine(joueur: Player): BasePart?
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return perso:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ================= Course en wagonnet =================
local courses: {[Player]: {debut: number, bouclier: ForceField?}} = {}

local function finCourse(joueur: Player)
	local c = courses[joueur]
	if not c then
		return
	end
	courses[joueur] = nil
	joueur:SetAttribute("EnWagon", nil)
	if c.bouclier and c.bouclier.Parent then
		c.bouclier:Destroy()
	end
end

local function departCourse(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	if not (grotte and r and membre(grotte, joueur)) or courses[joueur] then
		return
	end
	if (r.Position - (invite.Parent :: BasePart).Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	local f = grotte:FindFirstChild("CourseWagon")
	local n = f and f:GetAttribute("N")
	if not (f and type(n) == "number" and n > 4) then
		return
	end
	local points = {}
	for i = 1, n do
		local p = f:GetAttribute("P" .. i)
		if typeof(p) == "Vector3" then
			table.insert(points, p)
		end
	end
	local bouclier = Instance.new("ForceField")
	bouclier.Visible = false
	bouclier.Parent = joueur.Character
	courses[joueur] = {debut = os.clock(), bouclier = bouclier}
	joueur:SetAttribute("EnWagon", true)
	remote:FireClient(joueur, "WagonDepart", {points = points})
	task.delay(120, function()
		local c = courses[joueur]
		if c and c.bouclier == bouclier then
			finCourse(joueur)
		end
	end)
end

-- ================= Ascenseur du Grand Puits =================
local function preparerAscenseur(p: Instance)
	if p:IsA("BasePart") and p:IsDescendantOf(workspace) then
		pcall(function()
			p:SetNetworkOwner(nil)
		end)
	end
end
CollectionService:GetInstanceAddedSignal("Ascenseur"):Connect(function(p)
	task.defer(preparerAscenseur, p)
end)
for _, p in CollectionService:GetTagged("Ascenseur") do
	preparerAscenseur(p)
end

local dernierLevier: {[Instance]: number} = {}
local function actionnerLevier(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	if not (grotte and r and membre(grotte, joueur)) then
		return
	end
	local asc = invite:FindFirstAncestor("Ascenseur")
	local plateforme = asc and asc:FindFirstChild("Plateforme")
	local glissiere = plateforme and plateforme:FindFirstChild("Glissiere") :: PrismaticConstraint?
	if not glissiere then
		return
	end
	if os.clock() - (dernierLevier[asc] or 0) < 1.5 then
		return
	end
	dernierLevier[asc] = os.clock()
	local hMax = asc:GetAttribute("HMax") or glissiere.UpperLimit
	local enHaut = glissiere.TargetPosition > hMax / 2
	glissiere.TargetPosition = if enHaut then 0 else hMax
	asc:SetAttribute("Monte", not enHaut)
	remote:FireClient(joueur, "Ascenseur", {monte = not enHaut})
end

-- ================= −200 m : Fonderie royale et rouages =================
local TweenService = game:GetService("TweenService")
local Donnees = require(script.Parent:WaitForChild("Donnees"))
local CarteNaine = require(script.Parent:WaitForChild("CarteNaine"))

local FER_REQUIS = 3
local PIECES_LINGOT = 120
local PIECES_COFFRE = 80
local OR_COFFRE = 2
local FONDU = Color3.fromRGB(255, 128, 30)
local FONTE = Color3.fromRGB(46, 44, 50)

local function dejaFait(m: Instance, attribut: string, joueur: Player): boolean
	local liste = m:GetAttribute(attribut)
	return type(liste) == "string" and liste:find("," .. joueur.UserId .. ",", 1, true) ~= nil
end
local function marquer(m: Instance, attribut: string, joueur: Player)
	local liste = m:GetAttribute(attribut)
	m:SetAttribute(attribut, (if type(liste) == "string" then liste else ",") .. joueur.UserId .. ",")
end

-- fait pivoter un modèle autour de son pivot d'origine (angle en radians autour de l'axe X), en douceur
local function basculer(modele: Model, depart: CFrame, de: number, a: number, duree: number)
	local t0 = os.clock()
	while true do
		local u = math.min(1, (os.clock() - t0) / duree)
		local e = u * u * (3 - 2 * u)
		modele:PivotTo(depart * CFrame.Angles(de + (a - de) * e, 0, 0))
		if u >= 1 then
			break
		end
		task.wait()
	end
end

local fonderiesOccupees: {[Instance]: boolean} = {}
local LINGOT_ROYAL = "LingotRoyal"
local function fonderieRoyale(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	local fonderie = invite:FindFirstAncestor("Fonderie")
	local creuset = fonderie and fonderie:FindFirstChild("Creuset") :: Model?
	if not (grotte and r and membre(grotte, joueur) and creuset) or fonderiesOccupees[fonderie] then
		return
	end
	local p = Donnees.profil(joueur)
	-- une seule fois par joueur, pour toujours (marque « LingotRoyal » sauvegardée dans profil.fragments)
	if dejaFait(grotte, "Fondus", joueur) or (p and p.fragments[LINGOT_ROYAL]) then
		remote:FireClient(joueur, "Fonderie", {ok = false, raison = "Tu as déjà coulé ton lingot royal : la fonderie ne s'allume qu'une fois."})
		return
	end
	if not p or (p.minerais.Fer or 0) < FER_REQUIS then
		remote:FireClient(joueur, "Fonderie", {ok = false, raison = "Il faut " .. FER_REQUIS .. " Fer dans ton sac pour rallumer la fonderie."})
		return
	end
	if not Donnees.ajouterFragment(joueur, LINGOT_ROYAL) then
		return
	end
	Donnees.ajouterMinerai(joueur, "Fer", -FER_REQUIS)
	marquer(grotte, "Fondus", joueur)
	fonderiesOccupees[fonderie] = true
	invite.Enabled = false
	remote:FireClient(joueur, "Fonderie", {ok = true, etape = "versement"})
	task.spawn(function()
		local pivot = creuset:GetPivot()
		local angle = creuset:GetAttribute("Bascule") or math.rad(28)
		basculer(creuset, pivot, 0, angle, 2.2)
		local coulee = fonderie:FindFirstChild("Coulee") :: BasePart?
		local pied = fonderie:FindFirstChild("PiedCoulee")
		if coulee then
			coulee.Transparency = 0
		end
		local gerbe = pied and pied:FindFirstChild("Gerbe") :: ParticleEmitter?
		local lueur = pied and pied:FindFirstChild("LueurCoulee") :: PointLight?
		if gerbe then
			gerbe.Enabled = true
		end
		if lueur then
			TweenService:Create(lueur, TweenInfo.new(0.6), {Brightness = 2.4}):Play()
		end
		-- le métal file dans la rigole puis remplit les moules, un par un
		local morceaux = {}
		for _, d in fonderie:GetChildren() do
			if d:IsA("BasePart") and (d.Name == "Metal" or d.Name == "Lingot") then
				table.insert(morceaux, d)
			end
		end
		table.sort(morceaux, function(a, b)
			return (a:GetAttribute("Ordre") or 0) < (b:GetAttribute("Ordre") or 0)
		end)
		for _, d in morceaux do
			d.Material = Enum.Material.Neon
			TweenService:Create(d, TweenInfo.new(0.4), {Color = FONDU}):Play()
			task.wait(0.35)
		end
		if joueur.Parent then
			CarteNaine.crediter(joueur, PIECES_LINGOT)
			remote:FireClient(joueur, "Fonderie", {ok = true, etape = "lingot", pieces = PIECES_LINGOT})
		end
		task.wait(6)
		-- la coulée s'arrête, le creuset se redresse, le métal refroidit
		if coulee then
			coulee.Transparency = 1
		end
		if gerbe then
			gerbe.Enabled = false
		end
		if lueur then
			TweenService:Create(lueur, TweenInfo.new(1.5), {Brightness = 0}):Play()
		end
		basculer(creuset, pivot, angle, 0, 2.5)
		for _, d in morceaux do
			TweenService:Create(d, TweenInfo.new(4), {Color = FONTE}):Play()
		end
		task.wait(4)
		for _, d in morceaux do
			d.Material = Enum.Material.Metal
		end
		fonderiesOccupees[fonderie] = nil
		invite.Enabled = true
	end)
end

local function manivelleRouage(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	local groupe = invite:GetAttribute("ManivelleRouage")
	if not (grotte and r and membre(grotte, joueur)) or type(groupe) ~= "number" then
		return
	end
	invite.Enabled = false
	for _, m in CollectionService:GetTagged("Rouage") do
		if m:IsDescendantOf(grotte) and m:GetAttribute("Groupe") == groupe then
			m:SetAttribute("Vitesse", m:GetAttribute("VitesseCible") or 0.3)
		end
	end
	local enMarche = (grotte:GetAttribute("RouagesEnMarche") or 0) + 1
	grotte:SetAttribute("RouagesEnMarche", enMarche)
	local total = grotte:GetAttribute("RouagesTotal") or 3
	for _, j in Players:GetPlayers() do
		if membre(grotte, j) then
			remote:FireClient(j, "Rouages", {n = enMarche, total = total})
		end
	end
	if enMarche >= total then
		-- le coffre de l'Abîme remonte
		local coffre = grotte:FindFirstChild("CoffreAbime", true) :: Model?
		local cible = coffre and coffre:GetAttribute("Cible")
		if coffre and typeof(cible) == "CFrame" then
			task.spawn(function()
				task.wait(1.5)
				local depart = coffre:GetPivot()
				local t0, duree = os.clock(), 7
				while true do
					local u = math.min(1, (os.clock() - t0) / duree)
					local e = u * u * (3 - 2 * u)
					coffre:PivotTo(depart:Lerp(cible, e))
					if u >= 1 then
						break
					end
					task.wait()
				end
				for _, d in coffre:GetDescendants() do
					if d:IsA("ProximityPrompt") then
						d.Enabled = true
					end
				end
				for _, j in Players:GetPlayers() do
					if membre(grotte, j) then
						remote:FireClient(j, "CoffreAbime", {pret = true})
					end
				end
			end)
		end
	end
end

local function coffreAbime(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	if not (grotte and r and membre(grotte, joueur)) or dejaFait(grotte, "CoffreAbimePris", joueur) then
		return
	end
	marquer(grotte, "CoffreAbimePris", joueur)
	CarteNaine.crediter(joueur, PIECES_COFFRE)
	Donnees.ajouterMinerai(joueur, "Gold", OR_COFFRE)
	remote:FireClient(joueur, "CoffreAbime", {pieces = PIECES_COFFRE, gold = OR_COFFRE})
end

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local function prevenirMembres(grotte: Model, genre: string, infos)
	for _, j in Players:GetPlayers() do
		if membre(grotte, j) then
			remote:FireClient(j, genre, infos)
		end
	end
end

-- ================= −350 m : la lave monte =================
-- Le lac (tag « LaveMontante ») déborde périodiquement : alerte 6 s, crue en 3 s jusqu'à CrueY (les berges
-- brûlent), 16 s de crue — on se réfugie sur les prismes de basalte « Refuge » —, puis décrue en 4 s.
local function crue(lac: BasePart)
	local grotte = grotteDe(lac)
	local baseCF, baseTaille = lac:GetAttribute("BaseCF"), lac:GetAttribute("BaseTaille")
	local taille, y = lac:GetAttribute("Crue"), lac:GetAttribute("CrueY")
	if not (grotte and typeof(baseCF) == "CFrame" and typeof(baseTaille) == "Vector3" and typeof(taille) == "Vector3" and type(y) == "number") then
		return
	end
	lac:SetAttribute("EnCrue", true)
	prevenirMembres(grotte, "LaveMonte", {centre = baseCF.Position, delai = 6})
	task.wait(6)
	if not lac.Parent then
		return
	end
	local haute = CFrame.new(baseCF.X, y - taille.Y / 2, baseCF.Z)
	TweenService:Create(lac, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = haute, Size = taille}):Play()
	task.wait(3 + 16)
	if not lac.Parent then
		return
	end
	prevenirMembres(grotte, "LaveDescend", {})
	TweenService:Create(lac, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = baseCF, Size = baseTaille}):Play()
	task.wait(4)
	lac:SetAttribute("EnCrue", nil)
end

local function surveillerLac(lac: Instance)
	if not lac:IsA("BasePart") then
		return
	end
	task.spawn(function()
		local prochaine = os.clock() + math.random(100, 160)
		while lac.Parent do
			task.wait(1)
			if os.clock() >= prochaine or lac:GetAttribute("ForcerCrue") then -- ForcerCrue : test depuis Studio
				lac:SetAttribute("ForcerCrue", nil)
				crue(lac)
				prochaine = os.clock() + math.random(130, 190)
			end
		end
	end)
end
CollectionService:GetInstanceAddedSignal("LaveMontante"):Connect(surveillerLac)
for _, l in CollectionService:GetTagged("LaveMontante") do
	surveillerLac(l)
end

-- ================= −500 m : le Cœur maudit =================
-- Le gardien de l'arène (MobGrotte, Boss = true) est relié au Cœur : à 75 %, 50 % et 25 % de ses PV, une des
-- six chaînes du Cœur cède (chute physique) ; dès la 2e phase, les runes brûlantes de l'arène (geysers
-- « Inactif ») s'éveillent. À sa mort, le Cœur se brise : cinématique côté client, plus aucune chaîne.
local SEUILS_COEUR = {0.75, 0.5, 0.25}
local coeursSuivis: {[Model]: boolean} = {}

local function lacherChaine(arene: Instance)
	for _, ch in arene:GetChildren() do
		if ch:IsA("Model") and ch.Name == "ChaineCoeur" and not ch:GetAttribute("Tombee") then
			ch:SetAttribute("Tombee", true)
			for _, p in ch:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored = false
					p.CanCollide = false
					p.AssemblyLinearVelocity = Vector3.new(math.random(-6, 6), -4, math.random(-6, 6))
				end
			end
			Debris:AddItem(ch, 5)
			return ch
		end
	end
	return nil
end

local function runes(arene: Instance, eveillees: boolean)
	for _, p in arene:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "RuneBrulante" then
			p:SetAttribute("Inactif", if eveillees then nil else true)
		end
	end
end

local function briserCoeur(grotte: Model, arene: Instance)
	local coeur = arene:FindFirstChild("CoeurMaudit")
	local centre = coeur and coeur:GetAttribute("Centre")
	prevenirMembres(grotte, "CoeurBrise", {centre = centre})
	runes(arene, false)
	for _ = 1, 6 do
		lacherChaine(arene)
	end
	if coeur then
		task.delay(2.4, function()
			for _, p in coeur:GetDescendants() do
				if p:IsA("BasePart") then
					TweenService:Create(p, TweenInfo.new(1.2), {Transparency = 1}):Play()
				elseif p:IsA("Light") then
					TweenService:Create(p, TweenInfo.new(1.2), {Brightness = 0}):Play()
				elseif p:IsA("ParticleEmitter") then
					p.Enabled = false
				end
			end
			Debris:AddItem(coeur, 1.5)
		end)
	end
end

local function suivreBoss(mob: Instance)
	if not mob:IsA("Model") or not mob:GetAttribute("Boss") then
		return
	end
	local grotte = grotteDe(mob)
	local arene = grotte and grotte:FindFirstChild("ArèneDuCoeur", true)
	if not (grotte and arene) or coeursSuivis[arene] then
		return
	end
	coeursSuivis[arene] = true
	local phase = 1
	local fini = false
	local function maj()
		if fini then
			return
		end
		local pv, pvMax = mob:GetAttribute("PV") or 0, mob:GetAttribute("PVMax") or 1
		if pv <= 0 then
			fini = true
			coeursSuivis[arene] = nil
			briserCoeur(grotte, arene)
			return
		end
		while phase <= #SEUILS_COEUR and pv / pvMax <= SEUILS_COEUR[phase] do
			phase += 1
			arene:SetAttribute("PhaseCoeur", phase)
			lacherChaine(arene)
			if phase >= 2 then
				runes(arene, true)
			end
			prevenirMembres(grotte, "PhaseCoeur", {phase = phase})
		end
	end
	mob:GetAttributeChangedSignal("PV"):Connect(maj)
	mob.AncestryChanged:Connect(function()
		if not mob:IsDescendantOf(workspace) and not fini then
			fini = true
			coeursSuivis[arene] = nil
		end
	end)
end
CollectionService:GetInstanceAddedSignal("MobGrotte"):Connect(suivreBoss)
for _, m in CollectionService:GetTagged("MobGrotte") do
	suivreBoss(m)
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	if invite:GetAttribute("CourseWagon") then
		departCourse(invite, joueur)
	elseif invite:GetAttribute("AscenseurLevier") then
		actionnerLevier(invite, joueur)
	elseif invite:GetAttribute("FonderieRoyale") then
		fonderieRoyale(invite, joueur)
	elseif invite:GetAttribute("ManivelleRouage") then
		manivelleRouage(invite, joueur)
	elseif invite:GetAttribute("CoffreAbime") then
		coffreAbime(invite, joueur)
	end
end)

remote.OnServerEvent:Connect(function(joueur: Player, genre)
	if genre == "WagonFin" then
		finCourse(joueur)
	end
end)

Players.PlayerRemoving:Connect(function(joueur)
	courses[joueur] = nil
end)
