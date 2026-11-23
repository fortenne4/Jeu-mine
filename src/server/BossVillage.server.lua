-- Boss du village · SCRIPT SERVEUR (événement de groupe)
-- Grand cercle au bout de la rue du sud (place posée par Monde › Village.preparerCercleBoss) avec un panneau :
-- prochain boss, compte à rebours, « n/20 joueurs ». Toutes les CYCLE s (Partage › BossVillage), les joueurs
-- vivants dans le cercle (20 max, ordre d'arrivée) partent ensemble dans l'arène (Monde › AreneBoss) face au boss
-- de la rotation (Titan de cristal → Reine araignée → Seigneur de braise). Personne : le compte à rebours repart.
-- Déroulé : annonce à T−ANNONCE (puce + guide côté client) → « Depart » (fondu + chargement, joueurs gelés) →
-- téléportation → « Intro » quand tous sont posés (boss invulnérable et immobile pendant DUREE_INTRO) → combat
-- en 3 phases (66 % / 33 % : enrage) → « Fin » (bannière) → « Resultats » (classement) → « Retour » (fondu) au village.
-- Le boss réutilise MobsGrotte (IA, PV, coups d'épée, effets client) + des attaques de zone télégraphiées ici
-- (cercle / anneau / cône rouge qui se remplit avant l'impact). Victoire : pièces au prorata des dégâts + bonus.
-- Mort : écran K.O., réapparition au village, retour possible par le cercle. Tous morts / temps écoulé : échec.
-- Serveur autoritaire : PV, dégâts, récompenses, téléportations et gel des joueurs sont ici ; le client affiche.
-- Contrat des événements : voir le bas de Partage › BossVillage.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Config = require(Partage:WaitForChild("BossVillage"))
local Grottes = require(Partage:WaitForChild("Grottes"))
local Forge = require(Partage:WaitForChild("Forge"))
local MobsVoxels = require(Partage:WaitForChild("MobsVoxels"))
local MobsGrotte = require(script.Parent:WaitForChild("MobsGrotte"))
local AurasMobs = require(Partage:WaitForChild("AurasMobs"))

local monde = ServerStorage:WaitForChild("Monde")
local D = require(monde:WaitForChild("Disposition"))
local O = require(monde:WaitForChild("Outils"))
local Cercle = require(monde:WaitForChild("CercleLumineux"))
local AreneBoss = require(monde:WaitForChild("AreneBoss"))
local M = O.M

local PAS = 0.1
local CYCLE = Config.cycle(RunService:IsStudio())
local RAYON = D.CERCLE_BOSS_RAYON
local FLUX_LIMITE = 4
local ROUGE = Color3.fromRGB(255, 64, 44)
local OR = Color3.fromRGB(255, 204, 92)
local rng = Random.new()

-- ================= Dossier partagé (client) =================
local dossier = Instance.new("Folder")
dossier.Name = Config.DOSSIER
local evenement = Instance.new("RemoteEvent")
evenement.Name = "Evenement"
evenement.Parent = dossier
local action = Instance.new("RemoteEvent") -- client → serveur : retour anticipé au village (validé)
action.Name = "Action"
action.Parent = dossier
dossier:SetAttribute("Etat", "Attente")
dossier:SetAttribute("MineMin", D.ZONE_MINE_MIN)
dossier:SetAttribute("MineMax", D.ZONE_MINE_MAX)
dossier.Parent = ReplicatedStorage

-- ================= Outils =================
local function vivant(joueur: Player)
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if humain and humain.Health > 0 and racine and racine:IsA("BasePart") then return perso, racine, humain end
	return nil
end

local function plat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function poser(joueur: Player, cible: CFrame): boolean
	pcall(joueur.RequestStreamAroundAsync, joueur, cible.Position, FLUX_LIMITE)
	local perso, racine, humain = vivant(joueur)
	if not perso then return false end
	if humain.Sit then humain.Sit = false end
	local hauteur = if humain.RigType == Enum.HumanoidRigType.R6 then 3 else humain.HipHeight + racine.Size.Y / 2
	perso:PivotTo(cible + Vector3.new(0, hauteur + 0.1, 0))
	racine.AssemblyLinearVelocity = Vector3.zero
	return true
end

-- Gel côté serveur (départ, intro) : vitesse et saut à 0, valeurs d'origine restaurées ensuite
local geles = {} -- [Player] = {humain, ws, jh, jp}
local function geler(joueur: Player)
	local _, _, humain = vivant(joueur)
	if not humain or geles[joueur] then return end
	geles[joueur] = {humain = humain, ws = humain.WalkSpeed, jh = humain.JumpHeight, jp = humain.JumpPower}
	humain.WalkSpeed, humain.JumpHeight, humain.JumpPower = 0, 0, 0
end

local function degeler(joueur: Player)
	local g = geles[joueur]
	if not g then return end
	geles[joueur] = nil
	if g.humain.Parent then
		g.humain.WalkSpeed, g.humain.JumpHeight, g.humain.JumpPower = g.ws, g.jh, g.jp
	end
end

local function crediter(joueur: Player, n: number)
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Pièces")
	if v and v:IsA("IntValue") and n > 0 then
		v.Value += math.floor(n)
	end
end

-- ================= Cercle + panneau au village =================
local cercle, centreCercle
local panneau = {} -- labels du panneau

local function label(parent, nom, pos, taille, police, couleur)
	local t = Instance.new("TextLabel")
	t.Name = nom
	t.BackgroundTransparency = 1
	t.Position, t.Size = pos, taille
	t.Font = police
	t.TextScaled = true
	t.TextColor3 = couleur
	t.TextStrokeColor3 = Color3.fromRGB(16, 8, 4)
	t.TextStrokeTransparency = 0.15
	t.Text = ""
	t.Parent = parent
	return t
end

local function construireCercle()
	local carte = workspace:FindFirstChild("Carte")
	local village = carte and carte:FindFirstChild("Village")
	local place = village and village:FindFirstChild("PlaceBoss")
	local centre = place and place:GetAttribute("Centre")
	if typeof(centre) ~= "Vector3" then -- carte sans place : sol réel sous D.CERCLE_BOSS
		local hit = workspace:Raycast(D.CERCLE_BOSS + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0))
		centre = if hit then hit.Position else D.CERCLE_BOSS
	end
	local parent = place or workspace
	local ancien = parent:FindFirstChild("CercleBoss")
	if ancien then ancien:Destroy() end
	cercle = Cercle.construire(parent, CFrame.new(centre), "CercleBoss", {rayon = RAYON, texte = "0/" .. Config.MAX_JOUEURS, segments = 72})
	centreCercle = cercle:GetAttribute("Centre")
	dossier:SetAttribute("Cercle", centreCercle) -- guide client vers le cercle
	dossier:SetAttribute("RayonCercle", RAYON)
	-- anneau discret la nuit (pas d'aplat blanc éblouissant) : segments fins et translucides, lampe douce
	for _, p in cercle:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Anneau" then
			p.Size = Vector3.new(0.3, p.Size.Y, p.Size.Z)
			p.Transparency = 0.55
		end
	end
	local lueur = cercle:FindFirstChild("Lueur")
	local lampe = lueur and lueur:FindFirstChildOfClass("PointLight")
	if lampe then lampe.Brightness = 0.9 end
	local zone = cercle:FindFirstChild("Zone")
	local compteur = zone and zone:FindFirstChild("Compteur")
	if compteur then compteur.Enabled = false end -- remplacé par le grand panneau

	-- faisceau doux + étincelles au-dessus du cercle pendant les 30 dernières secondes (majPanneau)
	local faisceau = O.decor(O.cylindre(cercle, 46, 3.5, CFrame.new(centreCercle + Vector3.new(0, 23, 0)), OR, M.Neon, "Faisceau"))
	faisceau.Transparency, faisceau.CastShadow = 1, false
	local e = Instance.new("ParticleEmitter")
	e.Name = "Appel"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.LightEmission = 1
	e.Rate = 0
	e.Lifetime = NumberRange.new(2.5, 3.5)
	e.Speed = NumberRange.new(7, 11)
	e.SpreadAngle = Vector2.new(8, 8)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	e.Shape = Enum.ParticleEmitterShape.Box
	e.EmissionDirection = Enum.NormalId.Right -- axe du cylindre (Outils.cylindre couche l'axe X à la verticale)
	e.Parent = faisceau
	panneau.faisceau, panneau.appel, panneau.actif = faisceau, e, false
	-- haut (26 studs) : lisible depuis le pont, au-dessus des gardiens, sans écraser la vue de près
	local ancre = O.decor(O.bloc(cercle, Vector3.one, CFrame.new(centreCercle + Vector3.new(0, 26, 0)), Color3.new(1, 1, 1), M.Lisse, "Panneau"))
	ancre.Transparency = 1
	local b = Instance.new("BillboardGui")
	b.Name = "PanneauBoss"
	b.Size = UDim2.fromScale(14, 5.25)
	b.MaxDistance = 170
	b.LightInfluence = 0
	b.Parent = ancre
	local fond = Instance.new("Frame")
	fond.Size = UDim2.fromScale(1, 1)
	fond.BackgroundColor3 = Color3.fromRGB(26, 18, 14)
	fond.BackgroundTransparency = 0.2
	fond.Parent = b
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0.12, 0)
	coin.Parent = fond
	local bord = Instance.new("UIStroke")
	bord.Color = OR
	bord.Thickness = 3
	bord.Transparency = 0.15
	bord.Parent = fond
	local degrade = Instance.new("UIGradient")
	degrade.Rotation = 90
	degrade.Color = ColorSequence.new(Color3.fromRGB(255, 240, 225), Color3.fromRGB(140, 120, 110))
	degrade.Parent = fond
	panneau.etiquette = label(fond, "Etiquette", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.16), Enum.Font.Antique, OR)
	panneau.nom = label(fond, "Nom", UDim2.fromScale(0.04, 0.2), UDim2.fromScale(0.92, 0.32), Enum.Font.GothamBlack, Color3.new(1, 1, 1))
	panneau.compte = label(fond, "Compte", UDim2.fromScale(0.06, 0.55), UDim2.fromScale(0.88, 0.22), Enum.Font.GothamBold, Color3.fromRGB(240, 226, 200))
	panneau.joueurs = label(fond, "Joueurs", UDim2.fromScale(0.2, 0.78), UDim2.fromScale(0.6, 0.18), Enum.Font.GothamBold, OR)
end

local function majPanneau(etiquette: string, nom: string, couleur: Color3, compte: string, joueurs: string, reste: number?)
	if not panneau.nom or not panneau.nom.Parent then return end
	local actif = reste ~= nil and reste <= 30
	if panneau.faisceau and actif ~= panneau.actif then -- un boss approche : colonne de lumière qui attire les joueurs
		panneau.actif = actif
		panneau.faisceau.Color = couleur:Lerp(Color3.new(1, 1, 1), 0.35)
		panneau.appel.Color = ColorSequence.new(couleur:Lerp(Color3.new(1, 1, 1), 0.5))
		panneau.appel.Rate = if actif then 18 else 0
		TweenService:Create(panneau.faisceau, TweenInfo.new(1.5), {Transparency = if actif then 0.86 else 1}):Play()
	end
	panneau.etiquette.Text = etiquette
	panneau.nom.Text = nom
	panneau.nom.TextColor3 = couleur
	panneau.compte.Text = compte
	panneau.joueurs.Text = joueurs
end

-- ================= État =================
local arene: Model? = nil -- arène du combat en cours : une par boss (Monde › AreneBoss.obtenir(id), construite au besoin)
local index = 1 -- boss suivant dans Config.BOSS
local finAttente = os.clock() + CYCLE
local annonceFaite = false -- bandeau « arrive dans 1 min » déjà envoyé pour ce cycle
local combat = nil
local depart = false -- entre « Depart » et la création du combat (rien d'autre ne tourne)
local fileOrdre: {Player} = {} -- joueurs dans le cercle, par ordre d'arrivée

-- Prochain départ dans `delai` s : horloge serveur posée en attribut, le client calcule le compte à rebours
local function programmer(delai: number)
	finAttente = os.clock() + delai
	annonceFaite = false
	dossier:SetAttribute("Prochain", index)
	dossier:SetAttribute("DebutBoss", workspace:GetServerTimeNow() + delai)
end

local function retirer(c, joueur: Player)
	if not c.joueurs[joueur] then return end
	c.joueurs[joueur] = nil
	degeler(joueur)
	pcall(MobsGrotte.retirerJoueur, c.h, joueur)
	if joueur.Parent then joueur:SetAttribute("DansArene", nil) end
end

local function cibles(c)
	local liste = {}
	for j in c.joueurs do
		local _, racine = vivant(j)
		if racine and c.arrives[j] then table.insert(liste, racine) end
	end
	return liste
end

-- ================= Télégraphes et effets (dossier c.effets, détruit en fin de combat) =================
local function piece(c, classe: string, taille: Vector3, cf: CFrame, couleur: Color3, transp: number, mat: Enum.Material?)
	local p = Instance.new(classe) :: BasePart
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = mat or M.Neon
	p.Color = couleur
	p.Transparency = transp
	p.Size = taille
	p.CFrame = cf
	p.Parent = c.effets
	return p
end

local function disque(c, pos: Vector3, rayon: number, couleur: Color3, transp: number, y: number, mat: Enum.Material?)
	local p = piece(c, "Part", Vector3.new(0.12, rayon * 2, rayon * 2), CFrame.new(pos.X, c.centre.Y + y, pos.Z) * CFrame.Angles(0, 0, math.pi / 2),
		couleur, transp, mat) :: Part
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function remplir(p: BasePart, duree: number, taille: Vector3, cf: CFrame?)
	local but: {[string]: any} = {Size = taille}
	if cf then but.CFrame = cf end
	TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Linear), but):Play()
end

local function effacer(parties: {BasePart})
	for _, p in parties do
		if p.Parent then
			p.Color = Color3.fromRGB(255, 230, 200)
			TweenService:Create(p, TweenInfo.new(0.35), {Transparency = 1}):Play()
			Debris:AddItem(p, 0.4)
		end
	end
end

-- Cercle rouge qui se remplit en `duree` s ; rMin > 0 : anneau (zone sûre sombre au centre)
local function teleDisque(c, pos: Vector3, rayon: number, duree: number, rMin: number?, couleur: Color3?): {BasePart}
	local coul = couleur or ROUGE
	local contour = disque(c, pos, rayon, coul, 0.72, 0.08)
	local plein = disque(c, pos, 0.2, coul, 0.42, 0.1)
	remplir(plein, duree, Vector3.new(0.12, rayon * 2, rayon * 2))
	local parties = {contour, plein}
	if rMin and rMin > 0 then
		table.insert(parties, disque(c, pos, rMin, Color3.fromRGB(34, 26, 30), 0.25, 0.14, M.Lisse))
	end
	return parties
end

-- Cône (triangle) depuis origine vers dir (unitaire, plat) : deux coins (WedgePart) par couche
local function triangle(c, origine: Vector3, dir: Vector3, longueur: number, demi: number, couleur: Color3, transp: number, y: number, t: number)
	local res = {}
	for _, s in {1, -1} do
		local vX = Vector3.yAxis * s
		local vY = dir:Cross(vX)
		local function cfDe(k: number)
			local p = Vector3.new(origine.X, c.centre.Y + y, origine.Z) + dir * (longueur * k / 2) + vY * (demi * k / 2)
			return CFrame.fromMatrix(p, vX, vY, dir)
		end
		local w = piece(c, "WedgePart", Vector3.new(0.12, demi * t, longueur * t), cfDe(t), couleur, transp)
		table.insert(res, {w, cfDe(1)})
	end
	return res
end

local function teleCone(c, origine: Vector3, dir: Vector3, longueur: number, demi: number, duree: number): {BasePart}
	local parties = {}
	for _, e in triangle(c, origine, dir, longueur, demi, ROUGE, 0.72, 0.08, 1) do table.insert(parties, e[1]) end
	for _, e in triangle(c, origine, dir, longueur, demi, ROUGE, 0.42, 0.1, 0.02) do
		remplir(e[1], duree, Vector3.new(0.12, demi, longueur), e[2])
		table.insert(parties, e[1])
	end
	return parties
end

local function dansDisque(centre: Vector3, rayon: number, rMin: number?)
	return function(p: Vector3)
		local d = plat(p - centre).Magnitude
		return d <= rayon + 1 and d >= (rMin or 0)
	end
end

local function dansCone(origine: Vector3, dir: Vector3, longueur: number, demi: number)
	return function(p: Vector3)
		local v = plat(p - origine)
		local proj = v:Dot(dir)
		if proj < -2 or proj > longueur + 1 then return false end
		return (v - dir * proj).Magnitude <= demi * math.max(proj, 0) / longueur + 1.5
	end
end

-- Dégâts de zone (réduits par la défense, comme les mobs) ; hauteurMax : au-dessus, le saut esquive
-- Chaque coup du boss retire ~53 % des 150 PV d'un débutant sans armure : il meurt au 2e coup, jamais au 1er
local COUP = Config.COUP_BOSS

local function blesserZone(c, test: (Vector3) -> boolean, degats: number, hauteurMax: number?)
	if c.fini then return end
	for j in c.joueurs do
		local _, racine, humain = vivant(j)
		if racine and c.arrives[j] then
			local dy = racine.Position.Y - c.centre.Y
			if dy < (hauteurMax or 12) and dy > -4 and test(racine.Position) then
				local defense = j:GetAttribute("StatDefense")
				-- Seigneur de braise : coups de feu, réduits par la résistance au feu (casque magmatique)
				local feu = if c.def.id == "SeigneurBraise" then j:GetAttribute("ResistanceFeu") else nil
				local resFeu = if type(feu) == "number" then math.clamp(feu, 0, 0.9) else 0
				humain:TakeDamage(degats * Grottes.reductionDefense(if type(defense) == "number" then defense else 0) * (1 - resFeu))
			end
		end
	end
end

-- Secousse caméra chez les combattants proches (le client dose selon sa distance)
local function impact(c, pos: Vector3, rayon: number)
	for j in c.joueurs do
		if c.arrives[j] and j.Parent then evenement:FireClient(j, "Impact", pos, rayon) end
	end
end

local function explosion(c, pos: Vector3, rayon: number)
	impact(c, pos, rayon)
	local e = Instance.new("Explosion")
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.BlastRadius = math.min(rayon, 14)
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Position = Vector3.new(pos.X, c.centre.Y + 1, pos.Z)
	e.Parent = c.effets
end

local function onde(c, pos: Vector3, rayon: number, couleur: Color3)
	local p = disque(c, pos, 1, couleur, 0.2, 0.3)
	TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.12, rayon * 2, rayon * 2), Transparency = 1}):Play()
	Debris:AddItem(p, 0.5)
end

local function apres(c, delai: number, fn: () -> ())
	task.delay(delai, function()
		if not c.fini then
			local ok, err = pcall(fn)
			if not ok then warn("[BossVillage] " .. tostring(err)) end
		end
	end)
end

-- ================= Attaques des boss =================
local function face(m, pos: Vector3)
	local v = plat(pos - m.pos)
	if v.Magnitude > 0.01 then
		m.yaw = math.atan2(-v.X, -v.Z)
		m.yawCible = m.yaw
	end
end

local function etatBoss(m, e: string)
	m.etat = e
	m.modele:SetAttribute("Etat", e)
end

local function frappe(m)
	m.coup += 1
	m.modele:SetAttribute("Coup", m.coup)
end

-- Lance l'animation Attack pour que son image d'impact (def.impact) tombe à `delai` s d'ici
local function armer(c, m, delai: number)
	task.delay(math.max(0, delai - c.def.impact), function()
		if not c.fini and not m.mort then frappe(m) end
	end)
end

local function auHasard(liste)
	return liste[rng:NextInteger(1, #liste)]
end

local function dansArene(c, p: Vector3, marge: number): Vector3
	local v = plat(p - c.centre)
	local max = D.ARENE_RAYON - marge
	if v.Magnitude > max then v = v.Unit * max end
	return Vector3.new(c.centre.X + v.X, c.centre.Y, c.centre.Z + v.Z)
end

local ATTAQUES = {}

-- Puissance de la phase en cours : taille des zones (×) et dégâts (×) ; le nombre de vagues / projectiles
-- grandit aussi avec c.phase (1, 2, 3)
local function puissance(c)
	return Config.PUISSANCE[c.phase] or Config.PUISSANCE[1]
end

-- Racine de la cible actuelle du boss, sinon un joueur au hasard
local function racineCible(c, m, liste)
	local r = c.joueurs[m.cible] and m.cible.Character and m.cible.Character:FindFirstChild("HumanoidRootPart")
	return r or auHasard(liste)
end

-- Liste mélangée (copie) : pour viser plusieurs joueurs différents
local function melange(liste)
	local res = table.clone(liste)
	for i = #res, 2, -1 do
		local k = rng:NextInteger(1, i)
		res[i], res[k] = res[k], res[i]
	end
	return res
end

local function pointAuHasard(c, marge: number): Vector3
	local a, r = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(8, D.ARENE_RAYON - marge)
	return c.centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

-- Zone ronde télégraphiée : apparaît à `debut` s, frappe `duree` s plus tard.
-- pos peut être une fonction (position lue au moment où le télégraphe apparaît).
local function frappeDisque(c, pos: any, rayon: number, debut: number, duree: number, degats: number, opts: {[string]: any}?)
	local o = opts or {}
	local function lancer()
		local p: Vector3 = if type(pos) == "function" then pos() else pos
		if not p then return end
		local parties = teleDisque(c, p, rayon, duree, o.rMin, o.couleur)
		if o.avant then o.avant(p, duree) end
		apres(c, duree, function()
			effacer(parties)
			if o.effet then o.effet(p, rayon) end
			blesserZone(c, dansDisque(p, rayon, o.rMin), degats, o.hauteur)
		end)
	end
	if debut <= 0 then lancer() else apres(c, debut, lancer) end
end

-- Cône télégraphié depuis le boss vers `vers` (fonction → Vector3), apparaît à `debut` s
local function frappeCone(c, m, vers: () -> Vector3?, longueur: number, demi: number, debut: number, duree: number, degats: number,
	effet: ((Vector3, Vector3) -> ())?)
	local function lancer()
		local cible = vers()
		if not cible then return end
		face(m, cible)
		local dir = CFrame.Angles(0, m.yaw, 0).LookVector
		local origine = m.pos
		local parties = teleCone(c, origine, dir, longueur, demi, duree)
		apres(c, duree, function()
			effacer(parties)
			if effet then effet(origine, dir) end
			impact(c, origine + dir * longueur / 2, longueur / 2)
			blesserZone(c, dansCone(origine, dir, longueur, demi), degats)
		end)
	end
	if debut <= 0 then lancer() else apres(c, debut, lancer) end
end

-- Pics de cristal qui jaillissent du sol (visuel)
local function pics(c, pos: Vector3, rayon: number, n: number, echelle: number)
	for _ = 1, n do
		local h = rng:NextNumber(6, 10) * echelle
		local ecart = rayon * 0.5
		local cf = CFrame.new(pos + Vector3.new(rng:NextNumber(-ecart, ecart), h / 2 - 1, rng:NextNumber(-ecart, ecart)))
			* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4))
		local p = piece(c, "Part", Vector3.new(1.8 * echelle, h, 1.8 * echelle), cf - Vector3.new(0, h, 0), Color3.fromRGB(110, 205, 255), 0.15)
		TweenService:Create(p, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = cf}):Play()
		TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1), {Transparency = 1}):Play()
		Debris:AddItem(p, 1.6)
	end
end

-- Projectile qui tombe du ciel sur pos en `chute` s (météore, cristal, goutte d'acide)
local function chute(c, pos: Vector3, taille: number, couleur: Color3, mat: Enum.Material, chuteDuree: number, feu: boolean?)
	local boule = piece(c, "Part", Vector3.new(taille, taille, taille), CFrame.new(pos + Vector3.new(8, 70, 0)), couleur, 0, mat)
	boule.Shape = Enum.PartType.Ball
	if feu then O.feu(boule, 6) end
	TweenService:Create(boule, TweenInfo.new(chuteDuree, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = Vector3.new(pos.X, c.centre.Y + 1, pos.Z)}):Play()
	Debris:AddItem(boule, chuteDuree + 0.05)
end

-- Flaque qui reste au sol et brûle / ronge (dégâts par demi-seconde)
local function flaque(c, pos: Vector3, rayon: number, couleur: Color3, mat: Enum.Material, ticks: number, degatsTick: number)
	local f = disque(c, pos, rayon, couleur, 0.15, 0.12, mat)
	O.lumiere(f, couleur, 2, rayon + 12)
	for k = 1, ticks do
		apres(c, k * 0.5, function() blesserZone(c, dansDisque(pos, rayon), degatsTick, 6) end)
	end
	TweenService:Create(f, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, ticks * 0.5 - 0.6), {Transparency = 1}):Play()
	Debris:AddItem(f, ticks * 0.5 + 0.3)
end

-- ===== Titan de cristal =====

-- Onde de choc en anneau (sauter ou se coller au titan) ; phase 2 : 2 anneaux, phase 3 : 3, de plus en plus larges
function ATTAQUES.Onde(c, m, _, T)
	local K = puissance(c)
	local pos = m.pos
	local debut, premier = 0, T * 1.25
	for i = 1, c.phase do
		local rayon = math.min(32 * K.taille * (1 + (i - 1) * 0.15), D.ARENE_RAYON - 2)
		local duree = if i == 1 then premier else 0.85
		frappeDisque(c, pos, rayon, debut, duree, COUP * K.degats, {rMin = 8.5, hauteur = 5.5, effet = function(p, r)
			onde(c, p, r, Color3.fromRGB(150, 220, 255))
			explosion(c, p, 8)
		end})
		debut += duree
	end
	armer(c, m, premier)
	return debut + 0.8
end

-- Frappe des deux poings devant lui ; phase 2+ : un poing de cristal s'abat aussi sur 1 (puis 2) autres joueurs
function ATTAQUES.Poings(c, m, liste, T)
	local K = puissance(c)
	local cible = racineCible(c, m, liste)
	face(m, cible.Position)
	local dir = CFrame.Angles(0, m.yaw, 0).LookVector
	local rayon = 12 * K.taille
	local pos = dansArene(c, m.pos + dir * rayon, 4)
	local degats = COUP * K.degats
	local fracas = function(p, r)
		explosion(c, p, r)
		onde(c, p, r + 2, Color3.fromRGB(200, 190, 180))
	end
	frappeDisque(c, pos, rayon, 0, T, degats, {effet = fracas})
	armer(c, m, T)
	local autres = melange(liste)
	local n = 0
	for _, r in autres do
		if n >= c.phase - 1 then break end
		if r ~= cible then
			n += 1
			frappeDisque(c, dansArene(c, r.Position, 3), 9 * K.taille, n * 0.35, T, degats, {effet = function(p, rr)
				pics(c, p, rr, 5, K.taille)
				fracas(p, rr)
			end})
		end
	end
	return T + n * 0.35 + 0.6
end

-- Éclats de cristal sous les pieds des joueurs : 4 / 6 / 8 joueurs, zones et cristaux plus gros ;
-- phase 3 : une 2e vague suit les joueurs là où ils ont fui
function ATTAQUES.Eclats(c, m, liste, T)
	local K = puissance(c)
	local nb = ({4, 6, 8})[c.phase] or 4
	local rayon = 6.5 * K.taille
	local degats = COUP * K.degats
	local vise = melange(liste)
	local function eclat(p, r)
		pics(c, p, r, 4 + c.phase, K.taille)
		impact(c, p, r)
	end
	for i = 1, math.min(nb, #vise) do
		frappeDisque(c, dansArene(c, vise[i].Position, 3), rayon, 0, T * 1.2, degats, {effet = eclat})
		if c.phase >= 3 then
			local racine = vise[i]
			frappeDisque(c, function() return if racine.Parent then dansArene(c, racine.Position, 3) else nil end,
				rayon, T * 1.2 + 0.2, 0.9, degats, {effet = eclat})
		end
	end
	armer(c, m, T * 1.2)
	return T * 1.2 + (if c.phase >= 3 then 1.4 else 0.3)
end

-- Phase 2+ : pluie de cristaux sur toute l'arène (sur chaque joueur + au hasard), 8 puis 14 cristaux
function ATTAQUES.Cristaux(c, m, liste, T)
	local K = puissance(c)
	local points = {}
	for _, r in liste do table.insert(points, r.Position) end
	for _ = 1, (if c.phase >= 3 then 14 else 8) do table.insert(points, pointAuHasard(c, 6)) end
	etatBoss(m, "Roar")
	local rayon = 6 * K.taille
	local duree = T * 1.3
	for i, p in points do
		local pos = dansArene(c, p, 3)
		local delai = (i - 1) * 0.09
		frappeDisque(c, pos, rayon, delai, duree, COUP * K.degats, {
			avant = function(pp, d)
				apres(c, math.max(0, d - 0.5), function()
					chute(c, pp, 3.5 * K.taille, Color3.fromRGB(140, 220, 255), Enum.Material.Glass, 0.5)
				end)
			end,
			effet = function(pp, r)
				pics(c, pp, r, 3, K.taille)
				impact(c, pp, r)
			end,
		})
	end
	return duree + #points * 0.09 + 0.4
end

-- ===== Reine araignée =====

-- Crachat de toile en cône ; phase 2+ : un 2e (puis 3e) crachat vers d'autres joueurs, cônes plus larges
function ATTAQUES.Toile(c, m, liste, T)
	local K = puissance(c)
	local longueur, demi = math.min(34 * K.taille, 55), 15 * K.taille
	local degats = COUP * K.degats
	local vise = melange(liste)
	local premiere = racineCible(c, m, liste)
	local function fils(origine: Vector3, dir: Vector3)
		for k = -2, 2 do -- fils de toile au sol, quelques secondes
			local d = CFrame.Angles(0, k * 0.16, 0):VectorToWorldSpace(dir)
			local fil = piece(c, "Part", Vector3.new(0.25, 0.1, longueur - 2), CFrame.lookAt(origine + d * longueur / 2, origine + d * longueur) + Vector3.new(0, 0.25, 0),
				Color3.fromRGB(235, 235, 245), 0.2, M.Lisse)
			fil.Position = Vector3.new(fil.Position.X, c.centre.Y + 0.2, fil.Position.Z)
			TweenService:Create(fil, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2), {Transparency = 1}):Play()
			Debris:AddItem(fil, 2.7)
		end
	end
	local cibles_ = {premiere}
	for _, r in vise do
		if #cibles_ >= c.phase then break end
		if r ~= premiere then table.insert(cibles_, r) end
	end
	local ecart = T + 0.25
	for i, r in cibles_ do
		local debut = (i - 1) * ecart
		frappeCone(c, m, function() return if r.Parent then r.Position else nil end, longueur, demi, debut, T, degats, fils)
		if i == 1 then armer(c, m, T) else apres(c, debut, function() armer(c, m, T) end) end
	end
	return (#cibles_ - 1) * ecart + T + 0.5
end

-- Invocation de petites araignées (mobs existants) : 3 / 4 / 5, jamais plus de SBIRES_MAX en vie
function ATTAQUES.Invocation(c, m, liste, T)
	local vivants = 0
	for _, mob in c.h.mobs do
		if not mob.mort and not mob.boss then vivants += 1 end
	end
	local n = math.min(2 + c.phase, Config.SBIRES_MAX - vivants)
	if n <= 0 then return ATTAQUES.Toile(c, m, liste, T) end
	etatBoss(m, "Roar")
	for _ = 1, n do
		local a = rng:NextNumber(0, 2 * math.pi)
		local pos = dansArene(c, m.pos + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(7, 11), 4)
		local parties = teleDisque(c, pos, 3, T * 1.2, nil, Color3.fromRGB(190, 110, 255))
		apres(c, T * 1.2, function()
			effacer(parties)
			MobsGrotte.groupe(c.h, pos, 1, nil)
		end)
	end
	return T * 1.2 + 0.4
end

-- Bond sur un joueur ; phase 2 : 2 bonds d'affilée, phase 3 : 3 bonds, zone d'atterrissage plus grande
function ATTAQUES.Bond(c, m, liste, T)
	local K = puissance(c)
	local rayon = 10 * K.taille
	local duree = T * 1.2
	local ecart = duree + 0.35
	local deja = {}
	for i = 1, c.phase do
		apres(c, (i - 1) * ecart, function()
			local candidats = {}
			for _, r in cibles(c) do
				if not deja[r] then table.insert(candidats, r) end
			end
			if #candidats == 0 then candidats = cibles(c) end
			if #candidats == 0 then return end
			local cible = auHasard(candidats)
			deja[cible] = true
			local fin = dansArene(c, cible.Position, 8)
			face(m, fin)
			local depart = m.pos
			for k = 1, 5 do -- arc de saut (m.pos est relu par MobsGrotte à 10 Hz)
				apres(c, duree - 0.5 + k * 0.1, function()
					local t = k / 5
					m.pos = depart:Lerp(fin, t) + Vector3.new(0, math.sin(t * math.pi) * 12, 0)
				end)
			end
			armer(c, m, duree)
			frappeDisque(c, fin, rayon, 0, duree, COUP * K.degats, {effet = function(p, r)
				m.pos = fin
				explosion(c, p, r)
				onde(c, p, r + 2, Color3.fromRGB(190, 110, 255))
			end})
		end)
	end
	return (c.phase - 1) * ecart + duree + 0.6
end

-- Phase 2+ : pluie d'acide (sur chaque joueur + au hasard) qui laisse des flaques corrosives
function ATTAQUES.Acide(c, m, liste, T)
	local K = puissance(c)
	local VERT = Color3.fromRGB(150, 255, 90)
	local points = {}
	for _, r in liste do table.insert(points, r.Position) end
	for _ = 1, 3 * c.phase do table.insert(points, pointAuHasard(c, 6)) end
	etatBoss(m, "Roar")
	local rayon = 6 * K.taille
	local duree = T * 1.3
	for i, p in points do
		local pos = dansArene(c, p, 3)
		frappeDisque(c, pos, rayon, (i - 1) * 0.1, duree, COUP * 0.7 * K.degats, {
			couleur = VERT,
			avant = function(pp, d)
				apres(c, math.max(0, d - 0.5), function()
					chute(c, pp, 2.5, VERT, M.Neon, 0.5)
				end)
			end,
			effet = function(pp, r)
				impact(c, pp, r)
				flaque(c, pp, r * 0.8, VERT, M.Neon, 4 + 2 * c.phase, 5)
			end,
		})
	end
	return duree + #points * 0.1 + 0.4
end

-- ===== Seigneur de braise =====

-- Pluie de météores : sur les joueurs + 3 / 6 / 9 au hasard, plus gros ; phase 3 : 2e salve sur les joueurs
function ATTAQUES.Meteores(c, m, liste, T)
	local K = puissance(c)
	local rayon = 7 * K.taille
	local function salve(debut: number, aleatoires: number)
		local points = {}
		for _, r in cibles(c) do table.insert(points, r.Position) end
		for _ = 1, aleatoires do table.insert(points, pointAuHasard(c, 8)) end
		local duree = T * 1.4
		for i, p in points do
			local pos = dansArene(c, p, 3)
			frappeDisque(c, pos, rayon, debut, duree + (i - 1) * 0.15, COUP * K.degats, {
				avant = function(pp, d)
					apres(c, math.max(0, d - 0.55), function()
						chute(c, pp, 4 * K.taille, Color3.fromRGB(255, 120, 40), M.Neon, 0.55, true)
					end)
				end,
				effet = function(pp, r) explosion(c, pp, r) end,
			})
		end
		return debut + duree + #points * 0.15
	end
	etatBoss(m, "Roar")
	local fin = salve(0, 3 * c.phase)
	if c.phase >= 3 then
		apres(c, fin - 0.6, function() salve(0, 4) end)
		fin += T * 1.4 + 0.4
	end
	return fin + 0.5
end

-- Cercle de lave autour de lui, de plus en plus large, qui brûle plus longtemps
function ATTAQUES.Lave(c, m, _, T)
	local K = puissance(c)
	local pos = m.pos
	local rayon = 18 * K.taille
	armer(c, m, T * 1.2)
	frappeDisque(c, pos, rayon, 0, T * 1.2, COUP * K.degats, {effet = function(p, r)
		explosion(c, p, 10)
		flaque(c, p, r, Color3.fromRGB(255, 96, 30), Enum.Material.CrackedLava, 4 + 4 * c.phase, 6 * K.degats)
	end})
	return T * 1.2 + 0.5
end

-- Souffle de feu en cône ; phase 2 : il balaie vers un 2e joueur ; phase 3 : éventail de 3 cônes d'un coup, puis balayage
function ATTAQUES.Souffle(c, m, liste, T)
	local K = puissance(c)
	local longueur, demi = math.min(30 * K.taille, 50), 13 * K.taille
	local degats = COUP * K.degats
	local function flammes(origine: Vector3, dir: Vector3)
		for k = 1, 3 do
			local p = piece(c, "Part", Vector3.new(4, 4, 4), CFrame.new(origine + dir * (k * longueur / 3.3) + Vector3.new(0, 2.5, 0)), Color3.fromRGB(255, 120, 40), 1, M.Lisse)
			O.feu(p, 9).Heat = 15
			Debris:AddItem(p, 1)
		end
	end
	local premiere = racineCible(c, m, liste)
	local cibleFn = function() return if premiere.Parent then premiere.Position else nil end
	frappeCone(c, m, cibleFn, longueur, demi, 0, T, degats, flammes)
	if c.phase >= 3 then -- éventail : deux cônes de plus, de part et d'autre
		for _, angle in {-0.95, 0.95} do
			frappeCone(c, m, function()
				local v = plat(premiere.Position - m.pos)
				if v.Magnitude < 0.01 then return nil end
				return m.pos + CFrame.Angles(0, angle, 0):VectorToWorldSpace(v)
			end, longueur, demi * 0.8, 0, T, degats, flammes)
		end
		face(m, premiere.Position)
	end
	armer(c, m, T)
	local fin = T
	if c.phase >= 2 then
		local autre = premiere
		for _, r in melange(liste) do
			if r ~= premiere then autre = r break end
		end
		frappeCone(c, m, function() return if autre.Parent then autre.Position else nil end, longueur, demi, T + 0.2, T * 0.8, degats, flammes)
		apres(c, T + 0.2, function() armer(c, m, T * 0.8) end)
		fin = T + 0.2 + T * 0.8
	end
	return fin + 0.6
end

-- Phase 2+ : rayons de feu en étoile autour du seigneur (4 puis 6), phase 3 : 2e étoile décalée
function ATTAQUES.Colonnes(c, m, _, T)
	local K = puissance(c)
	local n = if c.phase >= 3 then 6 else 4
	local longueur = math.min(45 * K.taille, D.ARENE_RAYON)
	local degats = COUP * K.degats
	etatBoss(m, "Roar")
	local function etoile(debut: number, decalage: number)
		local base = rng:NextNumber(0, 2 * math.pi)
		for i = 1, n do
			local a = base + decalage + (i - 1) * 2 * math.pi / n
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local function lancer()
				local origine = m.pos
				local parties = teleCone(c, origine, dir, longueur, 5, T * 1.1)
				apres(c, T * 1.1, function()
					effacer(parties)
					for k = 1, 4 do
						local p = piece(c, "Part", Vector3.new(3, 3, 3), CFrame.new(origine + dir * (k * longueur / 4.5) + Vector3.new(0, 2, 0)),
							Color3.fromRGB(255, 120, 40), 1, M.Lisse)
						O.feu(p, 7).Heat = 18
						Debris:AddItem(p, 0.9)
					end
					blesserZone(c, dansCone(origine, dir, longueur, 5), degats)
				end)
			end
			if debut <= 0 then lancer() else apres(c, debut, lancer) end
		end
		impact(c, m.pos, 20)
	end
	etoile(0, 0)
	armer(c, m, T * 1.1)
	local fin = T * 1.1
	if c.phase >= 3 then
		etoile(T * 1.1 + 0.15, math.pi / n)
		fin += T * 1.1 + 0.15
	end
	return fin + 0.5
end

local function speciale(c, maintenant: number)
	local m = c.boss
	if c.intro or not m or m.mort or m.prep or maintenant < m.finAction or maintenant < c.prochaine then return end
	local liste = cibles(c)
	if #liste == 0 then return end
	local cadence = Config.CADENCE[c.phase] or Config.CADENCE[1]
	-- phase 2+ : de nouvelles attaques s'ajoutent au répertoire
	local noms = table.clone(c.def.attaques)
	if c.phase >= 2 and c.def.attaquesEnrage then
		for _, n in c.def.attaquesEnrage do table.insert(noms, n) end
	end
	local nom = auHasard(noms)
	if nom == c.derniere and #noms > 1 then nom = auHasard(noms) end
	c.derniere = nom
	etatBoss(m, "Roar")
	local T = cadence.T
	local duree = ATTAQUES[nom](c, m, liste, T)
	m.finAction = maintenant + duree
	c.prochaine = maintenant + duree + cadence.pause
end

-- Ciblage : le boss change régulièrement de victime, au hasard parmi les mineurs proches de lui ;
-- si sa cible s'éloigne, il passe à un mineur proche (ou au plus proche s'il n'y en a aucun).
local function majCible(c, maintenant: number)
	local m = c.boss
	if c.intro or not m or m.mort or m.prep then return end
	local proches, plusProche, dMin = {}, nil, math.huge
	for j in c.joueurs do
		local _, racine = vivant(j)
		if racine and c.arrives[j] then
			local d = plat(racine.Position - m.pos).Magnitude
			if d <= Config.CIBLE_PROCHE then table.insert(proches, j) end
			if d < dMin then plusProche, dMin = j, d end
		end
	end
	if not plusProche then return end
	local actuelProche = m.cible ~= nil and table.find(proches, m.cible) ~= nil
	if actuelProche and maintenant < (c.changeCible or 0) then return end
	local choix = plusProche
	if #proches > 0 then
		choix = proches[rng:NextInteger(1, #proches)]
		if choix == m.cible and #proches > 1 then choix = proches[rng:NextInteger(1, #proches)] end
	end
	if choix ~= m.cible then
		m.cible, m.vuA, m.errance = choix, maintenant, nil
	end
	c.changeCible = maintenant + rng:NextNumber(Config.CIBLE_CHANGE[1], Config.CIBLE_CHANGE[2])
end

-- ================= Combat =================
local function retourVillage(i: number): CFrame
	local p = centreCercle + Vector3.new(((i - 1) % 5 - 2) * 1.8, 0, -(RAYON + 5 + ((i - 1) // 5) * 2.5))
	return CFrame.lookAt(p, Vector3.new(centreCercle.X, p.Y, centreCercle.Z))
end

-- À tous les combattants posés dans l'arène
local function envoyer(c, type_: string, donnees)
	for j in c.joueurs do
		if c.arrives[j] and j.Parent then evenement:FireClient(j, type_, donnees) end
	end
end

-- Fondu noir chez le joueur, puis téléportation au village FONDU s plus tard (l'ambiance d'arène se coupe sous le noir)
local function renvoyer(j: Player, i: number)
	degeler(j)
	evenement:FireClient(j, "Retour", {})
	task.delay(Config.FONDU, function()
		if not j.Parent then return end
		poser(j, retourVillage(i))
		j:SetAttribute("DansArene", nil)
	end)
end

local function fermer(c)
	if c.ferme then return end
	c.ferme = true
	c.fini = true
	local i = 0
	for j in c.joueurs do
		if j.Parent then
			i += 1
			renvoyer(j, i)
		end
	end
	table.clear(c.joueurs)
	-- le boss et les effets disparaissent sous le fondu noir
	task.delay(Config.FONDU + 0.3, function()
		pcall(MobsGrotte.nettoyer, c.h)
		if c.effets then c.effets:Destroy() end
	end)
	combat = nil
	index = index % #Config.BOSS + 1
	dossier:SetAttribute("Etat", "Attente")
	dossier:SetAttribute("Intro", nil)
	dossier:SetAttribute("Debout", nil)
	programmer(CYCLE)
	-- prépare l'arène du boss suivant pendant l'attente (pas de saccade au lancement)
	local suivant = Config.BOSS[index].id
	task.delay(2, function()
		local ok, err = pcall(AreneBoss.obtenir, suivant)
		if not ok then warn("[BossVillage] Arène " .. suivant .. " non construite : " .. tostring(err)) end
	end)
end

-- Classement de tous les inscrits encore là (dégâts décroissants) ; pièces : BONUS_MIN + part du pot si victoire
local function classement(c, victoire: boolean)
	local nParticipants, total = 0, 0
	for j, d in c.degats do
		if j.Parent and d > 0 then
			nParticipants += 1
			total += d
		end
	end
	local pot = Config.POT_PAR_JOUEUR * nParticipants * c.def.recompense
	local lignes = {}
	for j in c.inscrits do
		if j.Parent then
			local d = c.degats[j] or 0
			local pieces = if victoire and d > 0 then Config.BONUS_MIN + math.floor(pot * d / math.max(total, 1)) else 0
			table.insert(lignes, {joueur = j, id = j.UserId, nom = j.DisplayName, degats = math.floor(d), pieces = pieces})
		end
	end
	table.sort(lignes, function(a, b)
		if a.degats ~= b.degats then return a.degats > b.degats end
		return a.nom < b.nom
	end)
	for rang, l in lignes do l.rang = rang end
	return lignes, nParticipants
end

local function terminer(c, victoire: boolean, raison: string?)
	if c.fini then return end
	c.fini = true
	local def = c.def
	for j in c.joueurs do
		degeler(j)
		pcall(MobsGrotte.retirerJoueur, c.h, j) -- plus personne n'est ciblé
	end
	if not victoire then pcall(MobsGrotte.nettoyer, c.h) end -- échec : le boss disparaît
	local lignes, nParticipants = classement(c, victoire)
	if victoire then
		for _, l in lignes do
			if l.pieces > 0 then crediter(l.joueur, l.pieces) end
		end
		dossier:SetAttribute("PV", 0)
	end
	local duree = if c.debut then os.clock() - c.debut else 0
	local mvp = if lignes[1] and lignes[1].degats > 0 then lignes[1].id else nil
	local top = {}
	for i = 1, math.min(#lignes, Config.MAX_JOUEURS) do
		local l = lignes[i]
		top[i] = {id = l.id, nom = l.nom, degats = l.degats, pieces = l.pieces, rang = l.rang}
	end
	local concernes = {}
	local fin = {victoire = victoire, nom = def.nom, couleur = def.couleur, raison = raison}
	for _, l in lignes do
		concernes[l.joueur] = true
		evenement:FireClient(l.joueur, "Fin", fin)
	end
	local texte = if victoire
		then def.nom .. " est vaincu par " .. nParticipants .. " mineur" .. (if nParticipants > 1 then "s" else "") .. " !"
		else def.nom .. " repart invaincu… " .. (raison or "")
	for _, j in Players:GetPlayers() do
		if not concernes[j] then evenement:FireClient(j, "Annonce", texte, def.couleur) end
	end
	task.delay(Config.BANNIERE_FIN, function()
		for _, l in lignes do
			if l.joueur.Parent then
				evenement:FireClient(l.joueur, "Resultats", {victoire = victoire, nom = def.nom, titre = def.titre, couleur = def.couleur,
					duree = duree, mvp = mvp, retour = Config.RESULTATS, raison = raison, lignes = top,
					moi = if l.rang > #top then {id = l.id, nom = l.nom, degats = l.degats, pieces = l.pieces, rang = l.rang} else nil})
			end
		end
	end)
	task.delay(if victoire then Config.RETOUR_VICTOIRE else Config.RETOUR_ECHEC, fermer, c)
end

local function creerBoss(c, partants, modeleId: string, pv: number)
	local def = c.def
	-- vrai modèle à sa taille ; modèle de secours agrandi à hauteurSecours
	local hauteur = MobsVoxels.donnees(modeleId).Hauteur or 8
	local echelle = if modeleId == def.id then 1 else def.hauteurSecours / math.max(hauteur, 1)
	local mobDef = {id = modeleId, poids = 1, pv = pv, degats = def.degats, vitesse = def.vitesse, portee = def.portee,
		recharge = def.recharge, echelle = echelle, vue = 150, abandon = 170, rayon = def.rayon,
		preparation = if modeleId == def.id then def.impact else nil}
	local grotte = {modele = c.arene, pointsMobs = {}, apparitions = {}, salleBoss = c.centre, sansGroupes = true}
	local niveau = {nombreMobs = {0, 0}, renfortSecondes = 1e9, mobs = Config.SBIRES, boss = mobDef}
	local h = MobsGrotte.peupler(grotte, niveau, partants)
	if not h.boss then
		MobsGrotte.nettoyer(h)
		return nil
	end
	return h
end

-- Transformation de phase (Config.TRANSFORMATIONS) : le boss grandit, change de couleur, s'illumine
local function transformer(c, phase: number)
	local m = c.boss
	local tr = Config.TRANSFORMATIONS[c.def.id]
	local etape = tr and tr[phase]
	if not m or m.mort or not etape then return end
	local modele: Model = m.modele
	local DUREE = 1.2
	MobsGrotte.grandir(m, etape.taille or 1, DUREE)
	local pieces = {}
	for _, p in modele:GetChildren() do
		local hex = p:IsA("BasePart") and etape.couleurs[p.Name]
		if hex then
			table.insert(pieces, {p, p.Color, Color3.fromHex(hex), etape.neon ~= nil and etape.neon[p.Name] == true})
		end
	end
	task.spawn(function()
		local etapes = 12
		for i = 1, etapes do
			if m.mort or not modele.Parent then return end
			local t = i / etapes
			for _, e in pieces do e[1].Color = e[2]:Lerp(e[3], t) end
			task.wait(DUREE / etapes)
		end
		for _, e in pieces do
			if e[4] then e[1].Material = Enum.Material.Neon end
		end
		if etape.aura and not m.mort and modele.Parent then
			pcall(AurasMobs.appliquer, modele, etape.aura)
		end
	end)
	local lum = m.root:FindFirstChild("LueurPhase") :: PointLight?
	if not lum then
		lum = Instance.new("PointLight")
		lum.Name = "LueurPhase"
		lum.Shadows = false
		lum.Brightness = 0
		lum.Parent = m.root
	end
	local l = lum :: PointLight
	l.Color = Color3.fromHex(etape.lumiere)
	l.Range = math.min(16 + 8 * phase, 60)
	TweenService:Create(l, TweenInfo.new(DUREE), {Brightness = 1 + phase}):Play()
	-- éclat de transformation : colonne de lumière à la couleur de la nouvelle phase
	local col = piece(c, "Part", Vector3.new(m.hauteur * 2.4, m.hauteur * 2.4, m.hauteur * 2.4), CFrame.new(m.pos + Vector3.new(0, m.hauteur * 0.5, 0)),
		Color3.fromHex(etape.lumiere), 0.6, M.Neon)
	col.Shape = Enum.PartType.Ball
	TweenService:Create(col, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = col.Size * 1.6, Transparency = 1}):Play()
	Debris:AddItem(col, 1)
	onde(c, m.pos, 30, Color3.fromHex(etape.lumiere))
end

-- Phases : sous 66 % puis 33 % de PV → 2 s invulnérable, rugissement, transformation, onde, cadence accélérée
local function majPhase(c)
	local m = c.boss
	if c.fini or c.intro or not m or m.mort or m.pv <= 0 then return end
	local r = m.pv / math.max(m.pvMax, 1)
	local cible = 1
	for i, seuil in Config.PHASES do
		if r <= seuil then cible = i + 1 end
	end
	if cible <= c.phase then return end
	c.phase = cible
	local maintenant = os.clock()
	local cadence = Config.CADENCE[cible] or Config.CADENCE[#Config.CADENCE]
	m.def.recharge = c.def.recharge * cadence.recharge
	local K = Config.PUISSANCE[cible] or Config.PUISSANCE[#Config.PUISSANCE]
	m.def.degats = c.def.degats * K.degats -- corps à corps plus fort aussi
	m.invulnerable = true
	m.modele:SetAttribute("Invulnerable", true)
	m.prep = nil
	m.finAction = math.max(m.finAction, maintenant + Config.PHASE_INVULNERABLE)
	c.prochaine = math.max(c.prochaine, maintenant + Config.PHASE_INVULNERABLE + 1)
	etatBoss(m, "Roar")
	onde(c, m.pos, 45, c.def.couleur)
	explosion(c, m.pos, 10)
	transformer(c, cible)
	dossier:SetAttribute("Phase", cible)
	envoyer(c, "Phase", {phase = cible, nom = c.def.nom, couleur = c.def.couleur})
	apres(c, Config.PHASE_INVULNERABLE, function()
		m.invulnerable = false
		m.modele:SetAttribute("Invulnerable", nil)
	end)
end

-- Fin de l'intro : le boss s'éveille, les joueurs sont dégelés, le chrono démarre
local function commencer(c)
	if c.fini or not c.intro then return end
	local maintenant = os.clock()
	c.intro = false
	c.debut = maintenant
	c.fin = maintenant + Config.DUREE_MAX
	c.prochaine = maintenant + 4.5 -- répit : première attaque de zone 4,5 s après l'intro
	local m = c.boss
	m.invulnerable = false
	m.modele:SetAttribute("Invulnerable", nil)
	m.finAction = maintenant + 1.5 -- le boss reste sur place 1,5 s (les joueurs reprennent leurs repères)
	etatBoss(m, "Idle")
	for j in c.joueurs do degeler(j) end
	dossier:SetAttribute("Intro", false)
	dossier:SetAttribute("FinCombat", workspace:GetServerTimeNow() + Config.DUREE_MAX)
end

-- Attend que tous les partants soient posés (ATTENTE_ARRIVEE s au plus), puis lance l'intro chez eux
local function introduire(c)
	local debut = os.clock()
	while not c.fini and os.clock() - debut < Config.ATTENTE_ARRIVEE do
		local tous = true
		for j in c.joueurs do
			if not c.arrives[j] then
				tous = false
				break
			end
		end
		if tous then break end
		task.wait(0.1)
	end
	if c.fini then return end
	c.introEnvoyee = true
	local m = c.boss
	envoyer(c, "Intro", {centre = c.centre, boss = m.modele, duree = Config.DUREE_INTRO, roar = Config.ROAR_INTRO})
	apres(c, Config.ROAR_INTRO, function()
		if c.intro then etatBoss(m, "Roar") end
	end)
	apres(c, Config.DUREE_INTRO, function() commencer(c) end)
end

local function lancer(partants: {Player})
	local def = Config.BOSS[index]
	local lieu = AreneBoss.obtenir(def.id) -- l'arène de CE boss (construite à sa première venue)
	arene = lieu
	local centre = lieu:GetAttribute("Centre")
	local c = {def = def, arene = lieu, centre = centre, joueurs = {}, inscrits = {}, arrives = {}, degats = {}, fini = false,
		fin = math.huge, prochaine = math.huge, derniere = nil, phase = 1, intro = true, introEnvoyee = false, debout = -1}
	c.effets = Instance.new("Folder")
	c.effets.Name = "EffetsBoss"
	c.effets.Parent = lieu

	-- PV : à l'échelle du groupe et de ses épées (StatEpee, posée par Grottes.server)
	local somme = 0
	for _, j in partants do
		local e = j:GetAttribute("StatEpee")
		somme += math.clamp(if type(e) == "number" then e else Forge.EPEE_BASE.valeur, Config.EPEE_MIN, Config.EPEE_MAX)
	end
	local pv = math.max(Config.PV_MIN, math.floor(somme * Config.PV_PAR_DEGAT * def.pvMult / 100 + 0.5) * 100)
	local h = nil
	if MobsVoxels.existe(def.id) then h = creerBoss(c, partants, def.id, pv) end
	if not h then h = creerBoss(c, partants, def.secours, pv) end -- modèle absent ou cassé : modèle de secours agrandi
	if not h then
		c.effets:Destroy()
		error("boss " .. def.id .. " impossible à créer")
	end
	c.h, c.boss = h, h.boss
	local m = h.boss
	m.modele:SetAttribute("Nom", def.nom)
	-- intro : invulnérable et immobile jusqu'à commencer()
	m.invulnerable = true
	m.modele:SetAttribute("Invulnerable", true)
	m.finAction = math.huge
	etatBoss(m, "Idle")
	h.surMort = function(_, estBoss)
		if estBoss and combat == c then terminer(c, true) end
	end
	h.surBlessure = function(mob, degats, joueur)
		if mob.boss and combat == c then
			c.degats[joueur] = (c.degats[joueur] or 0) + degats
			dossier:SetAttribute("PV", mob.pv)
			majPhase(c)
		end
	end

	dossier:SetAttribute("Index", index)
	dossier:SetAttribute("Nom", def.nom)
	dossier:SetAttribute("Titre", def.titre)
	dossier:SetAttribute("Couleur", def.couleur)
	dossier:SetAttribute("PVMax", pv)
	dossier:SetAttribute("PV", pv)
	dossier:SetAttribute("Phase", 1)
	dossier:SetAttribute("Intro", true)
	dossier:SetAttribute("Debout", #partants)
	dossier:SetAttribute("FinCombat", workspace:GetServerTimeNow() + Config.ATTENTE_ARRIVEE + Config.DUREE_INTRO + Config.DUREE_MAX)
	dossier:SetAttribute("Etat", "Combat")
	combat = c

	for i, j in partants do
		c.joueurs[j] = true
		c.inscrits[j] = true
		task.spawn(function()
			local a = (i - 1) / #partants * 2 * math.pi + rng:NextNumber(-0.1, 0.1)
			local pos = centre + Vector3.new(math.sin(a) * 40, 0, -math.cos(a) * 40)
			if poser(j, CFrame.lookAt(pos, Vector3.new(centre.X, pos.Y, centre.Z))) and c.joueurs[j] and combat == c and not c.fini then
				c.arrives[j] = true
				j:SetAttribute("DansArene", true)
				if c.introEnvoyee then -- arrivé après le début de l'intro : pas de cinématique
					degeler(j)
					evenement:FireClient(j, "Arrivee", {})
				end
			else
				retirer(c, j)
				degeler(j)
				if j.Parent then evenement:FireClient(j, "Annule", {}) end
			end
		end)
	end
	-- annonce pour ceux restés au village (les partants sont dans le chargement / l'intro)
	local partis = {}
	for _, j in partants do partis[j] = true end
	local texteSurgit = def.nom .. " surgit ! " .. #partants .. " mineur" .. (if #partants > 1 then "s" else "")
		.. " entre" .. (if #partants > 1 then "nt" else "") .. " dans l'arène."
	for _, j in Players:GetPlayers() do
		if not partis[j] then evenement:FireClient(j, "Annonce", texteSurgit, def.couleur) end
	end
	task.spawn(introduire, c)
end

local function majCombat(c, maintenant: number)
	if c.fini then return end
	local debout = 0
	for j in c.joueurs do
		if not j.Parent then
			retirer(c, j)
			continue
		end
		local perso, racine = vivant(j)
		if not perso then
			local arrive = c.arrives[j]
			retirer(c, j) -- mort : il réapparaît au village, exclu du combat (il peut revenir par le cercle)
			evenement:FireClient(j, if arrive then "KO" else "Annule", {nom = c.def.nom})
		elseif c.arrives[j] then
			debout += 1
			local p = racine.Position
			if p.Y < c.centre.Y - 25 then
				perso:PivotTo(CFrame.new(c.centre + Vector3.new(0, 4, -40))) -- filet de sécurité
			elseif plat(p - c.centre).Magnitude > D.ARENE_RAYON + 60 or p.Y > c.centre.Y + 150 then
				retirer(c, j) -- emmené ailleurs par un autre système
			end
		end
	end
	if debout ~= c.debout then
		c.debout = debout
		dossier:SetAttribute("Debout", debout)
	end
	if next(c.joueurs) == nil then
		terminer(c, false, "Plus aucun mineur debout.")
	elseif maintenant > c.fin then
		terminer(c, false, "Le temps est écoulé.")
	elseif c.boss and not c.boss.mort then
		majCible(c, maintenant)
		speciale(c, maintenant)
	end
end

-- ================= Joueurs =================
local derniereAction = {} -- [Player] = os.clock() du dernier appel à « Action » (1 par seconde)

Players.PlayerRemoving:Connect(function(joueur)
	geles[joueur] = nil
	derniereAction[joueur] = nil
	local k = table.find(fileOrdre, joueur)
	if k then table.remove(fileOrdre, k) end
	local c = combat
	if c then
		retirer(c, joueur)
		c.inscrits[joueur] = nil
		c.arrives[joueur] = nil
		c.degats[joueur] = nil
	end
end)

-- « Rejoindre le portail » (annonce en haut d'écran, BossAnnonce.client) : téléporte le joueur dans le grand
-- cercle pendant l'annonce. Seulement depuis la carte principale (village, mine publique), jamais depuis une mine
-- privée, une grotte ou une arène ; vivant, pas pendant un départ ou un combat.
local function rejoindre(joueur: Player)
	if depart or combat or dossier:GetAttribute("Etat") ~= "Attente" then return end
	local reste = finAttente - os.clock()
	if reste <= 1 or reste > Config.ANNONCE + 1 then return end
	if joueur:GetAttribute("DansArene") then return end
	local _, racine, humain = vivant(joueur)
	if not racine or not humain or typeof(centreCercle) ~= "Vector3" then return end
	local p = racine.Position
	if math.abs(p.X) > 700 or math.abs(p.Z) > 700 or p.Y < -200 then return end
	if plat(p - centreCercle).Magnitude < RAYON and math.abs(p.Y - centreCercle.Y) < 10 then return end -- déjà dedans
	humain.Sit = false
	local a = rng:NextNumber(0, 2 * math.pi)
	local r = rng:NextNumber(0, RAYON * 0.55)
	local cible = centreCercle + Vector3.new(math.cos(a) * r, 3.5, math.sin(a) * r)
	local perso = racine.Parent :: Model
	perso:PivotTo(CFrame.lookAt(cible, Vector3.new(centreCercle.X, cible.Y, centreCercle.Z)))
end

-- Retour anticipé au village depuis l'écran de résultats (combat fini, joueur encore dans l'arène)
action.OnServerEvent:Connect(function(joueur, type_)
	if type_ ~= "Retour" and type_ ~= "Rejoindre" then return end
	local t = os.clock()
	if t - (derniereAction[joueur] or 0) < 1 then return end
	derniereAction[joueur] = t
	if type_ == "Rejoindre" then
		rejoindre(joueur)
		return
	end
	local c = combat
	if not c or not c.fini or c.ferme or not c.joueurs[joueur] then return end
	c.joueurs[joueur] = nil
	pcall(MobsGrotte.retirerJoueur, c.h, joueur)
	renvoyer(joueur, rng:NextInteger(1, 10))
end)

-- ================= Démarrage =================
local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
-- Seule l'arène du premier boss est construite au démarrage ; les autres le sont à l'avance pendant l'attente
-- du boss suivant (voir fermer), jamais toutes en même temps.
local okArene, errArene = pcall(function() arene = AreneBoss.obtenir(Config.BOSS[index].id) end)
if not okArene then warn("[BossVillage] Arène non construite : " .. tostring(errArene)) end
local okCercle, errCercle = pcall(construireCercle)
if not okCercle then
	warn("[BossVillage] Cercle non construit : " .. tostring(errCercle))
	return
end
programmer(CYCLE)

local function dedans(p: Vector3): boolean
	local d = p - centreCercle
	return d.Y > -1 and d.Y < 10 and d.X * d.X + d.Z * d.Z < RAYON * RAYON
end

-- File d'attente : joueurs vivants dans le cercle, par ordre d'arrivée (attribut « File » pour le panneau client)
local function majFile(): {Player}
	local dans, proches = {}, {}
	for _, j in Players:GetPlayers() do
		local _, racine = vivant(j)
		if racine and dedans(racine.Position) then
			dans[j] = true
			table.insert(proches, {j, plat(racine.Position - centreCercle).Magnitude})
		end
	end
	for i = #fileOrdre, 1, -1 do
		if not dans[fileOrdre[i]] then table.remove(fileOrdre, i) end
	end
	table.sort(proches, function(a, b) return a[2] < b[2] end)
	for _, e in proches do
		if not table.find(fileOrdre, e[1]) then table.insert(fileOrdre, e[1]) end
	end
	local ids = table.create(#fileOrdre)
	for i, j in fileOrdre do ids[i] = tostring(j.UserId) end
	local texte = table.concat(ids, ",")
	if dossier:GetAttribute("File") ~= texte then dossier:SetAttribute("File", texte) end
	return fileOrdre
end

-- Départ : fondu + chargement chez les partants (gelés), téléportation DELAI_DEPART s plus tard
local function demarrer(partants: {Player})
	local def = Config.BOSS[index]
	dossier:SetAttribute("Etat", "Depart")
	dossier:SetAttribute("File", "")
	table.clear(fileOrdre)
	for _, j in partants do
		geler(j)
		evenement:FireClient(j, "Depart", {nom = def.nom, titre = def.titre, couleur = def.couleur, index = index, court = false})
	end
	task.wait(Config.DELAI_DEPART)
	local restants = {}
	for _, j in partants do
		if j.Parent and vivant(j) then
			table.insert(restants, j)
		else
			degeler(j)
			if j.Parent then evenement:FireClient(j, "Annule", {}) end
		end
	end
	local ok, err = true, nil
	if #restants > 0 then ok, err = pcall(lancer, restants) end
	if #restants == 0 or not ok then
		if not ok then warn("[BossVillage] Lancement impossible : " .. tostring(err)) end
		for _, j in restants do
			degeler(j)
			j:SetAttribute("DansArene", nil)
			if j.Parent then evenement:FireClient(j, "Annule", {}) end
		end
		combat = nil
		dossier:SetAttribute("Etat", "Attente")
		programmer(CYCLE)
	end
	depart = false
end

local function majAttente(maintenant: number)
	local def = Config.BOSS[index]
	local file = majFile()
	local n = math.min(#file, Config.MAX_JOUEURS)
	local reste = finAttente - maintenant
	majPanneau("PROCHAIN BOSS", def.nom, def.couleur, "Prochain boss dans " .. Config.minutes(reste), n .. "/" .. Config.MAX_JOUEURS .. " joueurs", reste)
	if cercle:GetAttribute("Texte") ~= n .. "/" .. Config.MAX_JOUEURS or (n > 0) ~= (cercle:GetAttribute("Occupe") == true) then
		cercle:SetAttribute("Texte", n .. "/" .. Config.MAX_JOUEURS)
		cercle:SetAttribute("Occupe", n > 0)
		Cercle.etat(cercle, n > 0)
	end
	if not annonceFaite and reste <= math.min(Config.ANNONCE, CYCLE - 5) then
		annonceFaite = true
		local quand = if reste >= 55 then "1 minute" else math.floor(reste + 0.5) .. " s"
		evenement:FireAllClients("Annonce", def.nom .. " arrive dans " .. quand .. " ! Rejoins le grand cercle au bout de la rue du sud.", def.couleur)
	end
	if reste > 0 then return end
	if n == 0 then -- personne : on relance le cycle
		programmer(CYCLE)
		return
	end
	local partants = table.move(file, 1, n, 1, {})
	Cercle.activer(cercle)
	depart = true
	task.spawn(demarrer, partants)
end

-- Pendant le combat, entrer dans le cercle fait rejoindre l'arène (chargement court, pas d'intro ; 20 joueurs max)
local function rejoindre(c, j: Player)
	c.joueurs[j] = true
	c.inscrits[j] = true
	geler(j)
	local def = c.def
	evenement:FireClient(j, "Depart", {nom = def.nom, titre = def.titre, couleur = def.couleur, index = index, court = true})
	task.spawn(function()
		task.wait(Config.FONDU)
		local a = rng:NextNumber(0, 2 * math.pi)
		local pos = c.centre + Vector3.new(math.sin(a) * 40, 0, -math.cos(a) * 40)
		if c.joueurs[j] and combat == c and not c.fini and poser(j, CFrame.lookAt(pos, Vector3.new(c.centre.X, pos.Y, c.centre.Z)))
			and c.joueurs[j] and combat == c and not c.fini then
			c.arrives[j] = true
			j:SetAttribute("DansArene", true)
			pcall(MobsGrotte.ajouterJoueur, c.h, j)
			degeler(j)
			evenement:FireClient(j, "Arrivee", {})
		else
			retirer(c, j)
			degeler(j)
			if j.Parent then evenement:FireClient(j, "Annule", {}) end
		end
	end)
end

local function majPanneauCombat(c, maintenant: number)
	local n = 0
	for _ in c.joueurs do n += 1 end
	if not c.fini and n < Config.MAX_JOUEURS then
		for _, j in Players:GetPlayers() do
			if n >= Config.MAX_JOUEURS then break end
			local _, racine = vivant(j)
			if racine and not c.joueurs[j] and dedans(racine.Position) then
				rejoindre(c, j)
				n += 1
			end
		end
	end
	local temps = if c.fini then "Fin du combat…" elseif c.intro then "Le boss s'éveille…" else "Temps restant " .. Config.minutes(c.fin - maintenant)
	majPanneau("COMBAT EN COURS", c.def.nom, c.def.couleur, temps,
		n .. "/" .. Config.MAX_JOUEURS .. (if c.fini then " mineurs" elseif n >= Config.MAX_JOUEURS then " · arène pleine" else " · entre pour rejoindre"))
	if cercle:GetAttribute("Texte") ~= "Combat" then
		cercle:SetAttribute("Texte", "Combat")
		cercle:SetAttribute("Occupe", true)
		Cercle.etat(cercle, true)
	end
end

while true do
	local maintenant = os.clock()
	if not cercle.Parent then pcall(construireCercle) end
	local c = combat
	local ok, err = true, nil
	if c then
		ok, err = pcall(majCombat, c, maintenant)
		if ok and combat == c then ok, err = pcall(majPanneauCombat, c, maintenant) end
	elseif not depart then
		ok, err = pcall(majAttente, maintenant)
	end
	if not ok then warn("[BossVillage] " .. tostring(err)) end
	task.wait(PAS)
end
