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

-- ===== Réglages : récompense de l'Exécuteur maudit (boss −500 m) =====
-- Donnée à sa mort, une seule fois par expédition et par joueur, à chaque membre vivant présent dans la grotte.
local OR_EXECUTEUR_MIN, OR_EXECUTEUR_MAX = 25, 40 -- minerai d'Or (« Gold ») ajouté au sac (tirage par joueur)
local PIECES_EXECUTEUR = 500 -- pièces en plus (le Roi déchu de −350 m en donne 250)
local RAYON_ARENE_COEUR = 90 -- studs autour du centre de l'arène : dedans, cinématique complète ; ailleurs, bandeau

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
-- « Inactif ») s'éveillent. À sa mort, le Cœur se brise : cinématique côté client (« CoeurBrise »), plus aucune
-- chaîne, et grosse récompense en Or + pièces (réglages OR_EXECUTEUR_* / PIECES_EXECUTEUR en tête de fichier).
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

-- le joueur est-il dans la case de cette grotte ? (grottes posées sur une grille, GROTTES_ECART studs entre deux)
local Disposition = require(game:GetService("ServerStorage"):WaitForChild("Monde"):WaitForChild("Disposition"))
local function dansLaGrotte(grotte: Model, pos: Vector3): boolean
	local index = grotte:GetAttribute("Emplacement")
	if type(index) ~= "number" then
		return false
	end
	local col = (index - 1) % Disposition.GROTTES_COLONNES
	local rang = (index - 1) // Disposition.GROTTES_COLONNES
	local base = Disposition.GROTTES_ORIGINE + Vector3.new(-col * Disposition.GROTTES_ECART, 0, rang * Disposition.GROTTES_ECART)
	local v = pos - base
	local demi = Disposition.GROTTES_ECART / 2
	return math.abs(v.X) < demi and math.abs(v.Z) < demi and math.abs(v.Y) < 150
end

-- Mort de l'Exécuteur : chaque membre vivant de l'expédition présent dans la grotte reçoit l'or (une seule fois par
-- expédition : marque « OrExecuteur » sur la grotte) ; ceux de l'arène voient la cinématique, les autres un bandeau.
local function briserCoeur(grotte: Model, arene: Instance, mob: Model)
	local coeur = arene:FindFirstChild("CoeurMaudit")
	local centre = coeur and coeur:GetAttribute("Centre")
	local sol = grotte:GetAttribute("ArenaCoeur")
	local corps = mob.PrimaryPart
	local posBoss = if corps then corps.Position else nil
	for _, j in Players:GetPlayers() do
		local r = racine(j)
		if r and membre(grotte, j) and dansLaGrotte(grotte, r.Position) then
			local gold, pieces = 0, 0
			if not dejaFait(grotte, "OrExecuteur", j) then
				marquer(grotte, "OrExecuteur", j)
				gold = math.random(OR_EXECUTEUR_MIN, OR_EXECUTEUR_MAX)
				if not Donnees.ajouterMinerai(j, "Gold", gold) then
					gold = 0
				end
				pieces = PIECES_EXECUTEUR
				CarteNaine.crediter(j, pieces)
			end
			local dansArene = false
			if typeof(sol) == "Vector3" then
				local v = r.Position - sol
				dansArene = Vector3.new(v.X, 0, v.Z).Magnitude < RAYON_ARENE_COEUR and math.abs(v.Y) < 60
			end
			remote:FireClient(j, "CoeurBrise", {centre = centre, sol = sol, boss = posBoss, hauteur = mob:GetAttribute("Hauteur"),
				cinematique = dansArene, gold = gold, pieces = pieces})
		end
	end
	runes(arene, false)
	-- le Cœur éclate (et ses dernières chaînes tombent) au moment de l'explosion de la cinématique (MecaniquesGrotte.client)
	task.delay(4.3, function()
		for _ = 1, 6 do
			lacherChaine(arene)
		end
		if not (coeur and coeur.Parent) then
			return
		end
		for _, p in coeur:GetDescendants() do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(0.3), {Transparency = 1}):Play()
			elseif p:IsA("Light") then
				TweenService:Create(p, TweenInfo.new(0.3), {Brightness = 0}):Play()
			elseif p:IsA("ParticleEmitter") then
				p.Enabled = false
			end
		end
		Debris:AddItem(coeur, 0.6)
	end)
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
			briserCoeur(grotte, arene, mob)
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

-- ================= −700 m : la salle scellée et ses 3 leviers gelés =================
-- Invite « LevierGlace » : "Gele" → (maintien) la gangue éclate → "Libre" → « Abaisser » → "Abaisse" (une rune de la
-- PorteGlace s'allume). Au 3e levier (compteur « LeviersGlace » de la grotte), le serveur ouvre la porte UNE fois
-- (« SalleGlaceOuverte ») : la glace se fissure (client) puis ses éclats tombent, la salle est ouverte à l'expédition.
local SON_GLACE, SON_LEVIER = "rbxassetid://9118587701", "rbxassetid://9116652350"
local CYAN = Color3.fromRGB(110, 230, 255)

local function sonEn(part: BasePart, id: string, volume: number, hauteur: number)
	local s = Instance.new("Sound")
	s.SoundId, s.Volume, s.PlaybackSpeed, s.RollOffMaxDistance = id, volume, hauteur, 90
	s.Parent = part
	s:Play()
	Debris:AddItem(s, 4)
end

local function eteindre(p: BasePart, duree: number)
	p.CanCollide, p.CanQuery = false, false
	TweenService:Create(p, TweenInfo.new(duree), {Transparency = 1}):Play()
	Debris:AddItem(p, duree + 0.1)
end

local function ouvrirSalleGlace(grotte: Model)
	local porte = grotte:FindFirstChild("PorteGlace")
	if not porte then
		return
	end
	local centre, normale = porte:GetAttribute("Centre"), porte:GetAttribute("Normale")
	prevenirMembres(grotte, "SalleGlace", {porte = centre, normale = normale})
	task.delay(2.6, function()
		if not porte.Parent then
			return
		end
		local n = if typeof(normale) == "Vector3" then normale else Vector3.zero
		local sol = (if typeof(centre) == "Vector3" then centre.Y else 0) - 6
		for i, p in porte:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "Eclat" then
					-- chaque bloc bascule vers la salle et s'écrase au sol (anime en douceur, sans physique)
					if i % 4 == 0 then
						sonEn(p, SON_GLACE, 0.5, 0.7 + math.random() * 0.4)
					end
					p.CanCollide, p.CanQuery = false, false
					local cible = p.Position + n * (3 + math.random() * 7) + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
					TweenService:Create(p, TweenInfo.new(0.7 + math.random() * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						CFrame = CFrame.new(cible.X, sol, cible.Z) * CFrame.Angles(math.random() * 2, math.random() * 6, math.random() * 2),
						Size = p.Size * 0.7,
					}):Play()
					task.delay(1.4, eteindre, p, 1)
				elseif p.Name == "GemmeGelee" or p.Name == "CercleRunes" or p.Name:sub(1, 4) == "Rune" then
					eteindre(p, 0.4)
				end
			end
		end
	end)
end

local function levierGlace(invite: ProximityPrompt, joueur: Player)
	local grotte = grotteDe(invite)
	local r = racine(joueur)
	local socle = invite.Parent
	local levier = socle and socle.Parent
	if not (grotte and r and membre(grotte, joueur) and socle and socle:IsA("BasePart") and levier) then
		return
	end
	if (r.Position - socle.Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	local etat = invite:GetAttribute("LevierGlace")
	if etat == "Gele" then
		-- la gangue éclate (le maintien de l'invite = on la brise / la fait fondre)
		invite:SetAttribute("LevierGlace", "Libre")
		invite:SetAttribute("Libere", os.clock())
		invite.ActionText, invite.HoldDuration = "Abaisser", 0.3
		local gangue = levier:FindFirstChild("GangueGlace")
		if gangue then
			for _, p in gangue:GetChildren() do
				if p:IsA("BasePart") then
					eteindre(p, 0.35)
				end
			end
		end
		sonEn(socle, SON_GLACE, 0.6, 1)
		remote:FireClient(joueur, "LevierGlace", {etape = "glace", pos = socle.Position})
	elseif etat == "Libre" and os.clock() - (invite:GetAttribute("Libere") or 0) > 0.4 then
		invite:SetAttribute("LevierGlace", "Abaisse")
		invite.Enabled = false
		local n = (grotte:GetAttribute("LeviersGlace") or 0) + 1
		local total = grotte:GetAttribute("LeviersGlaceTotal") or 3
		grotte:SetAttribute("LeviersGlace", n)
		local manche = levier:FindFirstChild("Manche") :: Model?
		local charniere = manche and manche:GetAttribute("Charniere")
		if manche and typeof(charniere) == "CFrame" then
			task.spawn(basculer, manche, charniere, 0.5, -1.1, 0.5)
		end
		local voyant = levier:FindFirstChild("Voyant") :: BasePart?
		if voyant then
			voyant.Material, voyant.Color = Enum.Material.Neon, CYAN
		end
		sonEn(socle, SON_LEVIER, 0.7, 0.8)
		-- une rune de la porte s'allume
		local porte = grotte:FindFirstChild("PorteGlace")
		if porte then
			for _, p in porte:GetChildren() do
				if p:IsA("BasePart") and p.Name == "RuneGlace" and p:GetAttribute("Index") == n then
					p.Material = Enum.Material.Neon
					TweenService:Create(p, TweenInfo.new(0.8), {Color = CYAN}):Play()
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness, l.Shadows = CYAN, 14, 1.2, false
					l.Parent = p
				end
			end
		end
		prevenirMembres(grotte, "LevierGlace", {etape = "abaisse", n = n, total = total, pos = socle.Position})
		if n >= total and not grotte:GetAttribute("SalleGlaceOuverte") then
			grotte:SetAttribute("SalleGlaceOuverte", true)
			task.delay(1.2, ouvrirSalleGlace, grotte)
		end
	end
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
	elseif invite:GetAttribute("LevierGlace") then
		levierGlace(invite, joueur)
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
