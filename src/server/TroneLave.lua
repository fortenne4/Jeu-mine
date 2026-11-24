-- Trône de magma (grotte −350 m « Les Rivières de lave ») · MODULE SERVEUR (ServerScriptService › Jeu › TroneLave)
-- Le trône (GrotteLave, section 7 : modèle « TroneMagma », Seat « SiegeRoi », invite « S'asseoir ») réveille le
-- Roi déchu quand un joueur de l'expédition s'y assoit :
--   1. cinématique (TroneRoi.client) : le trône tremble, le bassin bouillonne, les flammes montent, le roi surgit
--      de la lave (montée jouée ici, vue par tous), rugit, titre « LE ROI DÉCHU » ;
--   2. combat : le joueur assis + au plus un allié présent dans la salle (PV selon le nombre). IA de MobsGrotte
--      (boss, épées des joueurs) ; ses coups brûlent (Brulure) ; il ne lâche jamais sa cible et la suit à 90 % de sa
--      vitesse (marche ou course : MobsGrotte def.vitesseCible) ;
--   3. victoire : pièces + or pour chaque joueur de l'expédition (pop-up de coffre) ; le trône reste calme.
--      Défaite (personne de vivant dans la grotte, ou 20 s sans cible) : le roi replonge dans la lave, le trône
--      redevient utilisable après RECHARGE_TRONE s. Un seul combat à la fois par grotte.
-- RemoteEvent « TroneRoi » (serveur → client) : ("Intro", {cf, bassin, duree}), ("Eveil"), ("Combat"),
-- ("Retour", {pos}), ("Victoire", {pieces, gold}), ("Defaite"), ("Onde", {pos, rayon, duree}),
-- ("Meteores", {impacts = {{pos, t}}, rayon}).
-- Attaques spéciales (en rotation avec le coup d'épée de base) : onde de feu au sol (sauter / s'éloigner), charge en
-- ligne droite (s'écarter du couloir rouge), pluie de météores (sortir des cercles rouges). Zones rouges = Parts
-- « AlerteRoi » répliquées (dossier « AlertesRoi » de la grotte) ; dégâts et zones validés ici.
--   TroneLave.preparer(exp) -- appelé par Grottes.server.lua après ArenaTemple.preparer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))

local MobsGrotte = require(script.Parent.MobsGrotte)
local Brulure = require(script.Parent.Brulure)
local Donnees = require(script.Parent.Donnees)
local CarteNaine = require(script.Parent.CarteNaine)

local TroneLave = {}

-- ===== Réglages =====
local PV_BASE = 5000 -- seul (épée conseillée du palier : 124) ; à deux : × (1 + BONUS_PV_JOUEUR)
local BONUS_PV_JOUEUR = 0.7
local DEGATS = 60 -- par coup, avant la défense, puis réduit par la résistance au feu (casque magmatique)
local BRULURE = 3 -- s de brûlure par coup (Brulure.DEGATS = 3 PV toutes les 0,5 s)
local PORTEE = 7
local RECHARGE_COUP = 1.8
local PREPARATION = 0.55 -- délai avant l'impact, calé sur le clip Attack
local VITESSE_CIBLE = 0.9 -- poursuite : 90 % de la vitesse de la cible (marche 16 → 14,4 ; course 29,6 → 26,6)
local ECHELLE = 1.3 -- ≈ 10 studs de haut
local RECHARGE_TRONE = 45 -- s avant de pouvoir le réveiller de nouveau après une défaite
local SANS_CIBLE_MAX = 20
local MARGE_SALLE = 12 -- un allié compte s'il est dans la salle du trône (rayon de la salle + ça)
local PIECES = 250
local OR_VICTOIRE = 3
-- cinématique (s, depuis le moment où le joueur s'assoit) ; TroneRoi.client suit la même chronologie
local DUREE_INTRO = 9
local DEBUT_MONTEE, DUREE_MONTEE = 2.8, 2.6
local RUGISSEMENT, FIN_RUGISSEMENT = 5.6, 7.2

-- Attaques spéciales : une toutes les SPECIALE_INTERVALLE s, en rotation (Onde → Charge → Météores), entre les coups
-- d'épée de base. Chacune est annoncée (animation + zone rouge au sol) puis validée ici : zone, dégâts, cadence.
-- Dégâts avant la défense, puis réduits par la résistance au feu (Brulure.degatsFeu) ; chaque touche brûle.
local SPECIALE_PREMIERE = 5 -- s après le début du combat
local SPECIALE_INTERVALLE = 7 -- s entre la fin d'une spéciale et la suivante
local SPECIALE_BRULURE = 3 -- s de brûlure par touche
local SPECIALE_REPOS = 0.6 -- s sans coup de base juste après une spéciale
-- 1. Onde de feu : il plante l'épée, un anneau de feu part de lui → sauter au passage ou être hors de portée
local ONDE_PREPA = 1 -- s d'annonce (disque rouge, clip « Frappe »)
local ONDE_RAYON = 16
local ONDE_DUREE = 0.7 -- s pour que l'anneau atteigne ONDE_RAYON
local ONDE_EPAISSEUR = 2.2 -- demi-largeur du front de l'onde
local ONDE_DEGATS = 45
local ONDE_DECLENCHE = 12 -- seulement si sa cible est à moins de ça
-- 2. Charge : il fonce en ligne droite, épée en avant → s'écarter du couloir rouge
local CHARGE_PREPA = 0.8 -- s d'annonce (couloir rouge, clip « Elan »)
local CHARGE_DISTANCE = 18
local CHARGE_VITESSE = 42 -- studs/s
local CHARGE_LARGEUR = 5
local CHARGE_DEGATS = 70
local CHARGE_MIN, CHARGE_MAX = 7, 32 -- distance de sa cible pour charger
-- 3. Pluie de météores : un cercle rouge sous chaque combattant + autour, impacts l'un après l'autre
local METEORE_PREPA = 1.6 -- s avant le premier impact (clip « Incantation »)
local METEORE_NOMBRE = 6
local METEORE_RAYON = 4
local METEORE_ECART = 0.18 -- s entre deux impacts
local METEORE_DEGATS = 40

local remote = ReplicatedStorage:FindFirstChild("TroneRoi")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "TroneRoi"
	remote.Parent = ReplicatedStorage
end

local parInvite = {} -- [ProximityPrompt] = e

local function vivant(j: Player): (BasePart?, Humanoid?)
	local perso = j.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil, nil
	end
	return perso:FindFirstChild("HumanoidRootPart") :: BasePart?, hum
end

local function annoncer(joueurs: {Player}, genre: string, d: {[string]: any}?)
	for _, j in joueurs do
		if j.Parent then
			remote:FireClient(j, genre, d or {})
		end
	end
end

local function definition(n: number)
	return {
		id = "RoiDechu", poids = 1, pv = math.floor(PV_BASE * (1 + BONUS_PV_JOUEUR * (n - 1))), degats = DEGATS,
		vitesse = 14, portee = PORTEE, recharge = RECHARGE_COUP, echelle = ECHELLE, preparation = PREPARATION,
		vue = 400, tenace = true, vitesseCible = VITESSE_CIBLE,
		toucher = function(joueur: Player, hum: Humanoid, degats: number)
			hum:TakeDamage(Brulure.degatsFeu(joueur, degats))
			Brulure.appliquer(joueur, BRULURE)
		end,
	}
end

-- aura de braises, flammes de la couronne et de l'épée, lueur rouge (répliquées : vues par tous)
local TEX_FEU = "rbxasset://textures/particles/fire_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local function emetteur(parent: Instance, props: {[string]: any})
	local e: any = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	e.LightEmission = 0.3 -- sobre : le roi doit rester lisible
	for k, v in props do
		e[k] = v
	end
	e.Parent = parent
end
local function aura(modele: Model)
	local torse: BasePart? = nil
	for _, p in modele:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "AN" and (not torse or p.Size.Magnitude > torse.Size.Magnitude) then
				torse = p
			elseif p.Name == "FL" then
				emetteur(p, {Name = "FlammeCouronne", Texture = TEX_FEU, Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 70, 20)),
					Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.3, 0.6),
					Speed = NumberRange.new(1.5, 3), Rate = 18, EmissionDirection = Enum.NormalId.Top})
			elseif p.Name == "LB" and p.Size.Y > 0.1 then -- tranchant de l'épée
				emetteur(p, {Name = "FlammeEpee", Texture = TEX_FEU, Color = ColorSequence.new(Color3.fromRGB(255, 180, 60), Color3.fromRGB(255, 50, 10)),
					Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.25, 0.5),
					Speed = NumberRange.new(1, 2.5), Rate = 40, EmissionDirection = Enum.NormalId.Top})
			end
		end
	end
	if torse then
		emetteur(torse, {Name = "AuraBraises", Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.fromRGB(255, 190, 70), Color3.fromRGB(255, 60, 10)),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(1.2, 2.2),
			Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Rate = 26, Acceleration = Vector3.new(0, 4, 0)})
		emetteur(torse, {Name = "AuraFumee", Texture = "rbxasset://textures/particles/smoke_main.dds", LightEmission = 0.3, LightInfluence = 0.5,
			Color = ColorSequence.new(Color3.fromRGB(60, 30, 26)), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1)}),
			Size = NumberSequence.new(2, 5), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(1, 2), Rate = 5, EmissionDirection = Enum.NormalId.Top})
		local l = Instance.new("PointLight")
		l.Name = "LueurRoi"
		l.Color, l.Brightness, l.Range, l.Shadows = Color3.fromRGB(255, 70, 25), 0.8, 14, false
		l.Parent = torse
	end
end

local function ejecter(siege: Seat)
	local w = siege:FindFirstChild("SeatWeld")
	if w then
		w:Destroy()
	end
	local hum = siege.Occupant
	if hum then
		hum.Sit = false
	end
end

local function invite(e, actif: boolean, texte: string?)
	e.invite.Enabled = actif
	e.invite.ObjectText = texte or "Trône du Roi déchu"
end

local function poserRoi(m, pos: Vector3)
	m.pos = pos
	local cfR = CFrame.new(pos) * CFrame.Angles(0, m.yaw, 0)
	m.cfDe, m.cfVers, m.t = cfR, cfR, 0.1
	if m.root.Parent then
		m.root.CFrame = cfR
	end
end

local function glisserRoi(e, m, de: Vector3, vers: Vector3, duree: number)
	local t0 = os.clock()
	while true do
		if e.exp.fini or not m.modele.Parent then
			return
		end
		local u = math.min(1, (os.clock() - t0) / duree)
		m.pos = de:Lerp(vers, 1 - (1 - u) ^ 3)
		if u >= 1 then
			return
		end
		task.wait(0.05)
	end
end

local function etatRoi(m, nom: string)
	m.etat = nom
	m.modele:SetAttribute("Etat", nom)
end

-- défaite : le roi replonge dans la lave, le trône se repose puis redevient utilisable
local function retour(e)
	local exp, m = e.exp, e.roi
	e.phase = "retour"
	invite(e, false, "Trône du Roi déchu (le roi sommeille…)")
	if m and not m.mort and m.modele.Parent then
		m.gele, m.invulnerable, m.cible, m.prep = true, true, nil, nil
		etatRoi(m, "Idle")
		annoncer(exp.joueurs, "Retour", {pos = m.pos})
		glisserRoi(e, m, m.pos, m.pos - Vector3.new(0, m.hauteur + 1.5, 0), 2.5)
		if m.modele.Parent then
			m.modele:Destroy()
		end
	end
	e.roi = nil
	if exp.fini then
		return
	end
	annoncer(exp.joueurs, "Defaite")
	e.phase = "recharge"
	task.wait(RECHARGE_TRONE)
	if exp.fini or not e.siege.Parent then
		return
	end
	e.siege.Disabled = false
	invite(e, true)
	e.phase = "pret"
end

local function victoire(e)
	local exp = e.exp
	e.phase = "vaincu"
	for _, j in exp.joueurs do
		if j.Parent then
			CarteNaine.crediter(j, PIECES)
			Donnees.ajouterMinerai(j, "Gold", OR_VICTOIRE)
			remote:FireClient(j, "Victoire", {pieces = PIECES, gold = OR_VICTOIRE})
		end
	end
	task.delay(6, function()
		if not exp.fini and e.siege.Parent then
			e.siege.Disabled = false
			invite(e, true, "Trône du Roi déchu (vaincu)")
		end
	end)
end

-- ================= Attaques spéciales =================
local paramsSol = RaycastParams.new()
paramsSol.FilterType = Enum.RaycastFilterType.Include
paramsSol.FilterDescendantsInstances = {workspace.Terrain}
paramsSol.IgnoreWater = true

local ROUGE_ALERTE = Color3.fromRGB(190, 30, 20)

local function plat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function solSous(p: Vector3, haut: number): Vector3?
	local r = workspace:Raycast(p + Vector3.new(0, haut, 0), Vector3.new(0, -(haut + 14), 0), paramsSol)
	return r and r.Position
end

-- dégâts de feu d'une spéciale : défense, puis résistance au feu, puis brûlure
local function brulerJoueur(j: Player, degats: number)
	local _, hum = vivant(j)
	if not hum then
		return
	end
	local defense = j:GetAttribute("StatDefense")
	hum:TakeDamage(Brulure.degatsFeu(j, degats * Grottes.reductionDefense(if type(defense) == "number" then defense else 0)))
	Brulure.appliquer(j, SPECIALE_BRULURE)
end

-- le joueur saute-t-il ? (hauteur du HumanoidRootPart au-dessus du sol, comparée à sa hauteur debout)
local function enLAir(hrp: BasePart, hum: Humanoid): boolean
	local r = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), paramsSol)
	if not r then
		return true
	end
	local debout = if hum.RigType == Enum.HumanoidRigType.R6 then 3 else hum.HipHeight + hrp.Size.Y / 2
	return hrp.Position.Y - r.Position.Y > debout + 1.2
end

-- combattants vivants encore dans le combat
local function cibles(e): {{j: Player, hrp: BasePart, hum: Humanoid}}
	local t = {}
	local h = e.exp.mobs
	for _, j in e.exp.joueurs do
		local hrp, hum = vivant(j)
		if hrp and hum and h and h.joueurs[j] then
			table.insert(t, {j = j, hrp = hrp, hum = hum})
		end
	end
	return t
end

-- zone d'alerte rouge au sol (disque ou rectangle), répliquée : tous les joueurs la voient
local function alerte(e, cf: CFrame, taille: Vector3, disque: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = "AlerteRoi"
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = ROUGE_ALERTE
	p.Transparency = 0.7
	if disque then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.15, taille.X, taille.X)
		p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	else
		p.Size = taille
		p.CFrame = cf
	end
	p.Parent = e.alertes
	return p
end

local function annoncerAlerte(p: BasePart, duree: number)
	TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Linear), {Transparency = 0.3}):Play()
end

local function arret(e, m): boolean
	return m.mort or e.exp.fini or not m.modele.Parent
end

local function attendreSpecial(e, m, duree: number): boolean
	local fin = os.clock() + duree
	while os.clock() < fin do
		if arret(e, m) then
			return false
		end
		task.wait(0.05)
	end
	return not arret(e, m)
end

local function tourner(m, vers: Vector3)
	local v = plat(vers - m.pos)
	if v.Magnitude > 0.01 then
		m.yaw = math.atan2(-v.X, -v.Z)
		m.yawCible = m.yaw
	end
end

-- 1. Onde de feu : disque rouge pendant ONDE_PREPA, puis un anneau qui s'élargit ; touché si on est sur son front
-- au sol (sauter l'esquive) ; une seule touche par joueur
local function onde(e, m)
	local centre = m.pos
	etatRoi(m, "Frappe")
	local d = alerte(e, CFrame.new(centre + Vector3.new(0, 0.12, 0)), Vector3.new(ONDE_RAYON * 2, 0, 0), true)
	annoncerAlerte(d, ONDE_PREPA)
	local ok = attendreSpecial(e, m, ONDE_PREPA)
	d:Destroy()
	if not ok then
		return
	end
	annoncer(e.exp.joueurs, "Onde", {pos = centre, rayon = ONDE_RAYON, duree = ONDE_DUREE})
	local touches = {}
	local t0 = os.clock()
	while true do
		local u = math.min(1, (os.clock() - t0) / ONDE_DUREE)
		local r = ONDE_RAYON * u
		for _, c in cibles(e) do
			if not touches[c.j] then
				local v = c.hrp.Position - centre
				if math.abs(plat(v).Magnitude - r) < ONDE_EPAISSEUR and math.abs(v.Y) < 8 and not enLAir(c.hrp, c.hum) then
					touches[c.j] = true
					brulerJoueur(c.j, ONDE_DEGATS)
				end
			end
		end
		if u >= 1 or arret(e, m) then
			return
		end
		task.wait(0.05)
	end
end

-- 2. Charge : couloir rouge vers la cible pendant CHARGE_PREPA, puis il fonce (arrêté par les murs et le vide)
local function charge(e, m, cible)
	local dir = plat(cible.hrp.Position - m.pos)
	if dir.Magnitude < 0.01 then
		return
	end
	dir = dir.Unit
	tourner(m, cible.hrp.Position)
	etatRoi(m, "Elan")
	local depart = m.pos
	local long = CHARGE_DISTANCE
	local mur = workspace:Raycast(depart + Vector3.new(0, 2.5, 0), dir * (CHARGE_DISTANCE + 2), paramsSol)
	if mur then
		long = math.max(0, mur.Distance - 2)
	end
	local couloir = alerte(e, CFrame.lookAt(depart, depart + dir) * CFrame.new(0, 0.2, -long / 2), Vector3.new(CHARGE_LARGEUR, 0.2, math.max(long, 1)))
	annoncerAlerte(couloir, CHARGE_PREPA)
	local ok = attendreSpecial(e, m, CHARGE_PREPA)
	couloir:Destroy()
	if not ok or long < 1 then
		return
	end
	etatRoi(m, "Charge")
	local touches = {}
	local parcouru = 0
	while parcouru < long do
		local pas = math.min(CHARGE_VITESSE * 0.05, long - parcouru)
		local cand = m.pos + dir * pas
		local sol = solSous(cand, 4)
		if not sol then
			break
		end
		m.pos = Vector3.new(cand.X, sol.Y, cand.Z)
		parcouru += pas
		for _, c in cibles(e) do
			if not touches[c.j] then
				local v = c.hrp.Position - m.pos
				if plat(v).Magnitude < CHARGE_LARGEUR / 2 + 1.5 and math.abs(v.Y) < 7 then
					touches[c.j] = true
					brulerJoueur(c.j, CHARGE_DEGATS)
				end
			end
		end
		if arret(e, m) then
			return
		end
		task.wait(0.05)
	end
end

-- 3. Pluie de météores : un cercle rouge sous chaque combattant + d'autres autour, impacts l'un après l'autre
local function meteores(e, m)
	local liste = cibles(e)
	if #liste == 0 then
		return
	end
	tourner(m, liste[1].hrp.Position)
	etatRoi(m, "Incantation")
	local rng = Random.new()
	local points = {}
	for _, c in liste do
		table.insert(points, c.hrp.Position)
	end
	for _ = 1, 30 do
		if #points >= METEORE_NOMBRE then
			break
		end
		local base = liste[rng:NextInteger(1, #liste)].hrp.Position
		local a, r = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(4, 13)
		table.insert(points, base + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	local impacts, envoi = {}, {}
	for _, p in points do
		local sol = solSous(p, 6)
		if sol then
			local t = METEORE_PREPA + #impacts * METEORE_ECART
			local d = alerte(e, CFrame.new(sol + Vector3.new(0, 0.12, 0)), Vector3.new(METEORE_RAYON * 2, 0, 0), true)
			annoncerAlerte(d, t)
			table.insert(impacts, {pos = sol, t = t, alerte = d})
			table.insert(envoi, {pos = sol, t = t})
		end
	end
	annoncer(e.exp.joueurs, "Meteores", {impacts = envoi, rayon = METEORE_RAYON})
	local t0 = os.clock()
	for _, im in impacts do
		local reste = t0 + im.t - os.clock()
		if reste > 0 and not attendreSpecial(e, m, reste) then
			break
		end
		im.alerte:Destroy()
		for _, c in cibles(e) do
			local v = c.hrp.Position - im.pos
			if plat(v).Magnitude < METEORE_RAYON + 0.5 and v.Y > -3 and v.Y < 9 then
				brulerJoueur(c.j, METEORE_DEGATS)
			end
		end
	end
	for _, im in impacts do
		if im.alerte.Parent then
			im.alerte:Destroy()
		end
	end
end

-- Lance la prochaine spéciale possible dans la rotation ; renvoie son rang (nil : aucune possible maintenant).
-- Pendant la spéciale, l'IA de MobsGrotte est suspendue (m.gele) : seul ce script le déplace ; il reste blessable.
local ORDRE_SPECIALES = {"Onde", "Charge", "Meteores"}
local function speciale(e, m, rang: number): number?
	local hrp, hum = nil, nil
	if m.cible then
		hrp, hum = vivant(m.cible)
	end
	if not hrp or not hum then
		return nil
	end
	local d = plat(hrp.Position - m.pos).Magnitude
	for k = 1, #ORDRE_SPECIALES do
		local i = (rang + k - 1) % #ORDRE_SPECIALES + 1
		local nom = ORDRE_SPECIALES[i]
		local possible = (nom == "Onde" and d < ONDE_DECLENCHE) or (nom == "Charge" and d > CHARGE_MIN and d < CHARGE_MAX)
			or nom == "Meteores"
		if possible then
			m.gele, m.prep = true, nil
			local cible = {j = m.cible, hrp = hrp, hum = hum}
			local ok, err = pcall(function()
				if nom == "Onde" then
					onde(e, m)
				elseif nom == "Charge" then
					charge(e, m, cible)
				else
					meteores(e, m)
				end
			end)
			if not ok then
				warn("TroneLave : " .. tostring(err))
			end
			if e.alertes then
				e.alertes:ClearAllChildren()
			end
			if not m.mort and m.modele.Parent then
				m.gele = false
				etatRoi(m, "Idle")
				m.prochaineAttaque = os.clock() + SPECIALE_REPOS
			end
			return i
		end
	end
	return nil
end

local function combat(e, assis: Player)
	local exp, h = e.exp, e.exp.mobs
	local trone = e.modele
	local bassin = trone:GetAttribute("Bassin")
	local cfT = trone:GetAttribute("TroneCF")
	local centre = trone:GetAttribute("CentreSalle")
	local rayon = trone:GetAttribute("RayonSalle") or 30
	if typeof(bassin) ~= "Vector3" or typeof(cfT) ~= "CFrame" then
		return
	end
	e.phase = "intro"
	invite(e, false, "Trône du Roi déchu")

	-- combattants : le joueur assis + au plus un allié présent dans la salle
	local combattants = {assis}
	for _, j in exp.joueurs do
		local hrp = vivant(j)
		if j ~= assis and hrp and #combattants < 2 and typeof(centre) == "Vector3" then
			local v = hrp.Position - centre
			if Vector3.new(v.X, 0, v.Z).Magnitude < rayon + MARGE_SALLE and math.abs(v.Y) < 30 then
				table.insert(combattants, j)
			end
		end
	end

	local m = MobsGrotte.creer(h, definition(#combattants), bassin, true)
	if not m then
		e.phase = "pret"
		invite(e, true)
		return
	end
	e.roi = m
	m.gele, m.invulnerable = true, true
	local fond = m.pos
	local vers = Vector3.new(cfT.Position.X - fond.X, 0, cfT.Position.Z - fond.Z)
	if vers.Magnitude > 0.01 then
		m.yaw = math.atan2(-vers.X, -vers.Z)
		m.yawCible = m.yaw
	end
	local bas = fond - Vector3.new(0, m.hauteur + 1, 0)
	poserRoi(m, bas) -- caché sous la lave
	aura(m.modele)

	-- pendant la cinématique, les mobs laissent les combattants tranquilles
	for _, j in combattants do
		MobsGrotte.retirerJoueur(h, j)
	end
	local autres = {}
	for _, j in exp.joueurs do
		if not table.find(combattants, j) then
			table.insert(autres, j)
		end
	end
	annoncer(combattants, "Intro", {cf = cfT, bassin = bassin, duree = DUREE_INTRO})
	annoncer(autres, "Eveil")

	local t0 = os.clock()
	local function attendre(t: number)
		local reste = t0 + t - os.clock()
		if reste > 0 then
			task.wait(reste)
		end
	end
	attendre(DEBUT_MONTEE)
	glisserRoi(e, m, bas, fond, DUREE_MONTEE)
	attendre(RUGISSEMENT)
	if m.modele.Parent then etatRoi(m, "Roar") end
	attendre(FIN_RUGISSEMENT)
	if m.modele.Parent then etatRoi(m, "Idle") end
	attendre(DUREE_INTRO)

	-- le combat commence : le joueur se lève, le trône se verrouille
	ejecter(e.siege)
	e.siege.Disabled = true
	for _, j in combattants do
		if table.find(exp.joueurs, j) and j.Parent then
			MobsGrotte.ajouterJoueur(h, j)
		end
	end
	if exp.fini or not m.modele.Parent then
		return
	end
	m.gele, m.invulnerable = false, false
	if vivant(assis) and h.joueurs[assis] then
		m.cible, m.vuA = assis, os.clock()
	end
	e.phase = "combat"
	annoncer(exp.joueurs, "Combat")

	local alertes = Instance.new("Folder")
	alertes.Name = "AlertesRoi"
	alertes.Parent = exp.grotte.modele
	e.alertes = alertes
	local sansCible = 0
	local avant = os.clock()
	local prochaineSpeciale = os.clock() + SPECIALE_PREMIERE
	local rang = 0
	while true do
		task.wait(0.1)
		if exp.fini or not h.actif then
			alertes:Destroy()
			e.alertes = nil
			return
		end
		if m.mort then
			alertes:Destroy()
			e.alertes = nil
			victoire(e)
			return
		end
		if not m.modele.Parent then
			break
		end
		local vivants = 0
		for _, j in exp.joueurs do
			if vivant(j) then
				vivants += 1
			end
		end
		if vivants == 0 then
			break
		end
		local maintenant = os.clock()
		sansCible = if m.cible then 0 else sansCible + (maintenant - avant)
		avant = maintenant
		if sansCible >= SANS_CIBLE_MAX then
			break
		end
		-- attaque spéciale (jamais pendant un coup d'épée de base)
		if maintenant >= prochaineSpeciale and m.cible and not m.prep and not m.mort then
			local fait = speciale(e, m, rang)
			if fait then
				rang = fait
				prochaineSpeciale = os.clock() + SPECIALE_INTERVALLE
			else
				prochaineSpeciale = os.clock() + 0.5
			end
		end
	end
	alertes:Destroy()
	e.alertes = nil
	retour(e)
end

ProximityPromptService.PromptTriggered:Connect(function(p: ProximityPrompt, joueur: Player)
	if not p:GetAttribute("TroneRoi") then
		return
	end
	local e = parInvite[p]
	if not e or not table.find(e.exp.joueurs, joueur) then
		return
	end
	local hrp, hum = vivant(joueur)
	local siege = e.siege
	if not hrp or not hum or siege.Disabled or siege.Occupant then
		return
	end
	if (hrp.Position - siege.Position).Magnitude > p.MaxActivationDistance + 5 then
		return
	end
	siege:Sit(hum)
end)

function TroneLave.preparer(exp)
	local grotte = exp and exp.grotte and exp.grotte.modele
	local trone = grotte and grotte:FindFirstChild("TroneMagma", true)
	local siege = trone and trone:FindFirstChild("SiegeRoi")
	local p = siege and siege:FindFirstChild("InviteTrone")
	if not (siege and siege:IsA("Seat") and p and p:IsA("ProximityPrompt")) or not exp.mobs then
		return
	end
	local e = {exp = exp, modele = trone, siege = siege, invite = p, phase = "pret", roi = nil}
	parInvite[p] = e
	grotte.AncestryChanged:Connect(function()
		if not grotte.Parent then
			parInvite[p] = nil
		end
	end)
	siege:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = siege.Occupant
		if not hum then
			return
		end
		local j = Players:GetPlayerFromCharacter(hum.Parent)
		if not j or not table.find(exp.joueurs, j) then
			ejecter(siege)
			return
		end
		if e.phase == "pret" and not exp.fini and exp.mobs.actif then
			task.spawn(combat, e, j)
		end
	end)
end

return TroneLave
