-- MobsGrotte (ServerScriptService › Jeu › MobsGrotte) : IA des mobs hostiles des grottes profondes.
-- Serveur autoritaire et léger : UNE boucle Heartbeat pour tous les mobs de toutes les grottes.
-- La logique (cible, vue, attaque, renforts) tourne à 10 Hz ; le déplacement est interpolé à chaque frame.
-- Mobs = modèles MobsVoxels ancrés (Root), déplacés par CFrame, sans Humanoid.
-- Pour le client (MobsGrotte.client) : tag « MobGrotte », attributs MobId, PV, PVMax, Etat
-- ("Idle"/"Walk"/"Attack"/"Hurt"/"Death"/"Roar"), Boss, Coup (compteur d'attaques), Allure, Hauteur,
-- et à chaque coup d'épée reçu : CoupDirection (Vector3 unitaire horizontal joueur → mob), DernierCoup
-- (os.clock()) et Auteur (UserId du joueur), posés avant PV ; le serveur applique aussi un léger recul (knockback, arrêté par les murs).
-- Mobs par groupes de 2-3 ; un groupe garde chaque gisement (grotte.gisements) : alerte à GARDE_ALERTE,
-- jamais plus loin que GARDE_LAISSE, retour au gisement après la poursuite.
--
--	local h = MobsGrotte.peupler(grotte, niveau, joueurs) -- grotte = {modele, pointsMobs, gisements?, salleBoss?, apparitions}
--	h.surMort = function(mobId, estBoss, tueur) end      -- optionnel (récompense, fin de grotte...)
--	h.surBlessure = function(m, degats, joueur) end      -- optionnel (dégâts réellement retirés, ex. boss du village)
--	h.boss = mob du boss (table interne) ; def.vue / def.abandon / def.rayon / def.preparation : détection, poursuite,
--	rayon de contact et délai avant l'impact propres au mob (défauts : VUE, ABANDON, taille du modèle, PREPARATION)
--	m.invulnerable = true : les coups d'épée l'ignorent (intro / changement de phase du boss du village)
--	m.gele = true : l'IA et le recul sont suspendus, le mob suit m.pos / m.yaw (cinématique : Roi déchu, TroneLave)
--	MobsGrotte.creer(h, def, point, boss?) : un mob précis (boss d'événement, ex. le Roi déchu du trône de magma)
--	def.tenace : ne lâche jamais sa cible (ni distance ni perte de vue) ; def.vitesseCible (ex. 0.9) : poursuite à
--	cette fraction de la vitesse de la cible (marche ou course mesurée), Etat « Run » quand elle court ;
--	def.toucher(joueur, humanoid, degats) : remplace hum:TakeDamage à l'impact (dégâts de feu + brûlure…)
--	MobsGrotte.retirerJoueur(h, joueur) / MobsGrotte.ajouterJoueur(h, joueur)
--	MobsGrotte.nettoyer(h)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Grottes = require(Partage:WaitForChild("Grottes"))
local MobsVoxels = require(Partage:WaitForChild("MobsVoxels"))

local MobsGrotte = {}

local PAS = 0.1 -- logique à 10 Hz
local VUE = 45 -- détection d'un joueur visible
local ABANDON = 60 -- la poursuite s'arrête au-delà
local PERTE_VUE = 3 -- s sans voir la cible avant d'abandonner
local PREPARATION = 0.35 -- délai avant l'impact (esquive possible)
local RECUP_ATTAQUE = 0.4
local DUREE_HURT = 0.35
local DUREE_ROAR = 1.2
local DUREE_MORT = 1.8 -- animation Death + fondu côté client, puis destruction
local DUREE_MORT_BOSS = 4.5 -- le boss meurt au ralenti (MobsGrotte.client)
local RECUL = 3.4 -- knockback d'un coup d'épée (studs), réduit pour les grands mobs, presque nul pour le boss
local RECUL_DUREE = 0.18
local RECUL_RECHARGE = 0.5
local POSTURE = 1.2 -- délai mini entre deux « Hurt » (le mob n'est plus étourdi en boucle)
local GARDE_ALERTE = 28 -- un garde ne prend pour cible qu'un joueur à moins de ça de son gisement
local GARDE_LAISSE = 40 -- … et ne s'en éloigne jamais plus ; il y revient après la poursuite
local VIRAGE = 10 -- rad/s
local VOL = 3 -- hauteur de vol de la chauve-souris
local ERRANCE = 8
-- Hitbox réelle : sphère de frappe devant le joueur (portée ~8) testée contre les boîtes des pièces visibles du mob
-- (pose de repos : les animations sont jouées par le client), à la CFrame actuelle ou au tick précédent (latence).
local EPEE_AVANCE = 3.4
local EPEE_RAYON = 3.6
local EPEE_TOLERANCE = 1.2
local HITBOX_DEBUG = RunService:IsStudio() and workspace:GetAttribute("HitboxDebug") == true
local BONUS_COUP3 = 1.5
local RENFORT_DISTANCE = 40
local LOIN_APPARITION = Grottes.ZONE_SURE * 0.7 -- zone sûre de l'arrivée (minimum, cf. GrotteGenerateur)
local ANGLES = {0, 45, -45, 90, -90}

local grottes = {} -- [handle] = true
local rng = Random.new()

local function aplatir(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function yawVers(dir: Vector3): number
	return math.atan2(-dir.X, -dir.Z) -- devant = -Z
end

local function rapprocherAngle(a: number, b: number, maxPas: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + math.clamp(d, -maxPas, maxPas)
end

local function hauteurVol(m): number
	return if m.vole and not m.mort then VOL * m.echelle else 0
end

local function racineJoueur(joueur: Player): (BasePart?, Humanoid?)
	local perso = joueur.Character
	if not perso or not perso.Parent then return nil, nil end
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local hrp = perso:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then return nil, nil end
	return hrp :: BasePart, hum
end

local function sol(h, x: number, yRef: number, z: number, montee: number, descente: number): number?
	local r = workspace:Raycast(Vector3.new(x, yRef + montee, z), Vector3.new(0, -(montee + descente), 0), h.params)
	return r and r.Position.Y
end

local function etat(m, e: string)
	if m.etat ~= e then
		m.etat = e
		m.modele:SetAttribute("Etat", e)
	end
end

local function marcher(m, allure: number)
	etat(m, "Walk")
	if math.abs((m.allure or 0) - allure) > 0.05 then
		m.allure = allure
		m.modele:SetAttribute("Allure", allure)
	end
end

-- Refuge de l'arrivée : un mob n'avance jamais vers une apparition s'il est (ou entre) dans le refuge
local function dansRefuge(h, de: Vector3, vers: Vector3): boolean
	for _, a in h.refuges do
		local dv = aplatir(vers - a).Magnitude
		if dv < Grottes.ZONE_REFUGE and dv < aplatir(de - a).Magnitude then return true end
	end
	return false
end

-- Avance de `dist` vers `dir` (plat, unitaire) sans traverser les murs ; contourne à ±45° / ±90°.
local function deplacer(h, m, dir: Vector3, dist: number, droit: boolean?): boolean
	if dist <= 0.01 then return false end
	local hRayon = if m.vole then VOL * m.echelle else math.max(2, m.hauteur * 0.4)
	for _, a in ANGLES do
		if a ~= 0 and droit then break end
		local d = if a == 0 then dir else CFrame.Angles(0, math.rad(a * m.cote), 0):VectorToWorldSpace(dir)
		local mur = workspace:Raycast(m.pos + Vector3.new(0, hRayon, 0), d * (dist + m.rayon), h.params)
		local cand = m.pos + d * dist
		if not mur and not dansRefuge(h, m.pos, cand) then
			local y = sol(h, cand.X, m.pos.Y, cand.Z, math.min(hRayon, 3), 6)
			if y then
				m.pos = Vector3.new(cand.X, y, cand.Z)
				if a < 0 then m.cote = -m.cote end -- garde le côté qui marche
				return true
			end
		end
	end
	return false
end

local function voit(h, m, cible: Vector3): boolean
	local oeil = m.pos + Vector3.new(0, hauteurVol(m) + math.min(m.hauteur * 0.6, 3.5), 0)
	return workspace:Raycast(oeil, cible - oeil, h.params) == nil
end

local function poser(m, maintenant: number): CFrame
	local y = m.pos.Y + hauteurVol(m)
	if m.vole and not m.mort then
		y += math.sin(maintenant * 2.5 + m.phase) * 0.5
	end
	return CFrame.new(m.pos.X, y, m.pos.Z) * CFrame.Angles(0, m.yaw, 0)
end

-- Boîtes {cf, demi-taille} des pièces visibles, dans le repère du Root ; rayon englobant pour le tri rapide
local function hitbox(modele: Model, root: BasePart, rayon: number, hauteur: number)
	local pieces, englobe = {}, 0
	local inv = root.CFrame:Inverse()
	for _, p in modele:GetChildren() do
		if p:IsA("BasePart") and p ~= root and p.Transparency < 0.9 and p.Size.Magnitude > 0.4 then
			local cf, demi = inv * p.CFrame, p.Size / 2
			table.insert(pieces, {cf, demi})
			englobe = math.max(englobe, cf.Position.Magnitude + demi.Magnitude)
		end
	end
	if #pieces == 0 then
		local demi = Vector3.new(rayon, hauteur / 2, rayon)
		table.insert(pieces, {CFrame.new(0, hauteur / 2, 0), demi})
		englobe = demi.Magnitude + hauteur / 2
	end
	if HITBOX_DEBUG then
		for _, pc in pieces do
			local a = Instance.new("BoxHandleAdornment")
			a.Name = "Hitbox"
			a.Adornee, a.CFrame, a.Size = root, pc[1], pc[2] * 2
			a.Color3, a.Transparency, a.ZIndex = Color3.new(1, 0.2, 0.2), 0.7, 1
			a.Parent = root
		end
	end
	return pieces, englobe
end

-- Point de la hitbox du mob (posé en cfMob) le plus proche de la sphère de frappe, ou nil si hors d'atteinte
local function toucheMob(m, centre: Vector3, cfMob: CFrame): Vector3?
	local cl = cfMob:PointToObjectSpace(centre)
	local meilleur, point = EPEE_RAYON + EPEE_TOLERANCE, nil
	for _, pc in m.hitbox do
		local cf, demi = pc[1], pc[2]
		local q = cf:PointToObjectSpace(cl)
		local c = Vector3.new(math.clamp(q.X, -demi.X, demi.X), math.clamp(q.Y, -demi.Y, demi.Y), math.clamp(q.Z, -demi.Z, demi.Z))
		local d = (q - c).Magnitude
		if d < meilleur then
			meilleur, point = d, cf * c
			if d == 0 then break end
		end
	end
	return point and cfMob * point
end

local function creerMob(h, def, point: Vector3, boss: boolean?, garde: Vector3?)
	local echelle = def.echelle or 1
	local y = sol(h, point.X, point.Y, point.Z, 4, 12) or point.Y
	local pos = Vector3.new(point.X, y, point.Z)
	local yaw = rng:NextNumber(-math.pi, math.pi)
	local ok, modele = pcall(MobsVoxels.construire, def.id, CFrame.new(pos) * CFrame.Angles(0, yaw, 0))
	if not ok then
		warn("MobsGrotte : impossible de construire " .. tostring(def.id) .. " : " .. tostring(modele))
		return nil
	end
	local hauteur = (modele:GetAttribute("Hauteur") or modele:GetExtentsSize().Y) * echelle
	if echelle ~= 1 then
		modele:ScaleTo(echelle)
	end
	-- variante recolorée (paliers 6 à 8) : pièces tirées vers def.teinte, néons passés en def.lueur ; nom affiché du boss
	if def.teinte or def.lueur then
		for _, p in modele:GetChildren() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				if p.Material == Enum.Material.Neon then
					if def.lueur then p.Color = def.lueur end
				elseif def.teinte then
					p.Color = p.Color:Lerp(def.teinte, def.teinteForce or 0.5)
				end
			end
		end
	end
	if def.nom then modele:SetAttribute("Nom", def.nom) end
	local taille = modele:GetExtentsSize()
	modele.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	modele:SetAttribute("MobId", def.id)
	modele:SetAttribute("PV", def.pv)
	modele:SetAttribute("PVMax", def.pv)
	modele:SetAttribute("Etat", "Idle")
	modele:SetAttribute("Boss", boss == true)
	modele:SetAttribute("Coup", 0)
	modele:SetAttribute("Allure", 1)
	modele:SetAttribute("Hauteur", hauteur)
	CollectionService:AddTag(modele, "MobGrotte")

	local m = {
		modele = modele, root = modele.PrimaryPart, def = def, boss = boss == true,
		vole = def.vole == true or def.id == "ChauveSourisCave", echelle = echelle, hauteur = hauteur,
		rayon = def.rayon or math.clamp(math.max(taille.X, taille.Z) * 0.3, 1, 4),
		pv = def.pv, pvMax = def.pv, etat = "Idle", allure = 1,
		origine = pos, pos = pos, yaw = yaw, yawCible = yaw, phase = rng:NextNumber(0, 2 * math.pi), cote = 1,
		cible = nil, vuA = 0, prochaineAttaque = 0, prep = nil, finAction = 0,
		errance = nil, finErrance = 0, prochaineErrance = os.clock() + rng:NextNumber(1, 4),
		rugi = false, mort = false, finMort = 0, coup = 0, tueur = nil,
		garde = garde, recul = nil, prochainRecul = 0, prochainHurt = 0,
	}
	m.hitbox, m.englobe = hitbox(modele, m.root, m.rayon, hauteur)
	m.cfDe = poser(m, os.clock())
	m.cfVers = m.cfDe
	m.t = PAS
	m.root.CFrame = m.cfDe
	modele.Parent = h.dossier
	table.insert(h.mobs, m)
	return m
end

local function frapper(h, m, maintenant: number)
	local joueur = m.prep.joueur
	if not h.joueurs[joueur] then return end
	local hrp, hum = racineJoueur(joueur)
	if not hrp or not hum then return end
	local vers = aplatir(hrp.Position - m.pos)
	local d = vers.Magnitude
	if d > m.def.portee + 1.5 then return end -- esquivé en reculant
	if math.abs(hrp.Position.Y - (m.pos.Y + hauteurVol(m))) > 6 + m.hauteur * 0.5 then return end
	local devant = CFrame.Angles(0, m.yaw, 0).LookVector
	if d > 1.5 and devant:Dot(vers.Unit) < 0.35 then return end -- esquivé sur le côté
	local defense = joueur:GetAttribute("StatDefense")
	if type(defense) ~= "number" then defense = 0 end
	local degats = m.def.degats * Grottes.reductionDefense(defense)
	if m.def.toucher then
		m.def.toucher(joueur, hum, degats)
	else
		hum:TakeDamage(degats)
	end
end

-- Poursuite calée sur la cible (def.vitesseCible) : vitesse horizontale mesurée du joueur, lissée ; au-dessus de
-- 1,2 × sa marche il « court » (course du Hud = marche × MULT_COURSE). Renvoie (vitesse du mob, court ?)
local MULT_COURSE = 1.85 -- Hud.client.lua
local function vitessePoursuite(m, hrp: BasePart, dt: number): (number, boolean)
	local perso = hrp.Parent
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local marche = if hum and hum.WalkSpeed > 0 then hum.WalkSpeed else 16
	local v = aplatir(hrp.AssemblyLinearVelocity).Magnitude
	local avant = m.vCible or marche
	m.vCible = avant + (v - avant) * math.min(1, dt * 4)
	local court = m.vCible > marche * 1.2
	return (if court then marche * MULT_COURSE else marche) * m.def.vitesseCible, court
end

local function chercherCible(h, m)
	local meilleur, dMin, hrpMin, humMin = nil, m.def.vue or VUE, nil, nil
	for joueur in h.joueurs do
		local hrp, hum = racineJoueur(joueur)
		if hrp then
			local d = (hrp.Position - m.pos).Magnitude
			if d < dMin and (not m.garde or aplatir(hrp.Position - m.garde).Magnitude < GARDE_ALERTE) and voit(h, m, hrp.Position) then
				meilleur, dMin, hrpMin, humMin = joueur, d, hrp, hum
			end
		end
	end
	return meilleur, hrpMin, humMin
end

local function majMob(h, m, dt: number, maintenant: number)
	-- attaque en cours (préparation puis impact)
	if m.prep then
		if not m.prep.faite and maintenant >= m.prep.frappe then
			m.prep.faite = true
			frapper(h, m, maintenant)
		end
		if maintenant < m.prep.fin then return end
		m.prep = nil
	end
	if maintenant < m.finAction then return end -- Hurt / Roar

	-- cible actuelle encore valable ?
	local hrp: BasePart? = nil
	if m.cible then
		if not h.joueurs[m.cible] then
			m.cible = nil
		else
			hrp = racineJoueur(m.cible)
			if not hrp or (not m.def.tenace and (hrp.Position - m.pos).Magnitude > (m.def.abandon or ABANDON))
				or (m.garde and aplatir(hrp.Position - m.garde).Magnitude > GARDE_LAISSE) then
				m.cible, hrp = nil, nil
			elseif voit(h, m, hrp.Position) then
				m.vuA = maintenant
			elseif not m.def.tenace and maintenant - m.vuA > PERTE_VUE then
				m.cible, hrp = nil, nil
			end
		end
		if not m.cible and m.garde then -- poursuite finie : le garde retourne à son gisement
			m.errance, m.finErrance = m.origine, maintenant + 20
		end
	end
	if not m.cible then
		local nouveau, r = chercherCible(h, m)
		if nouveau and r then
			m.cible, hrp, m.vuA, m.errance = nouveau, r, maintenant, nil
			if m.def.id == "BruteProfondeurs" and not m.rugi then
				m.rugi = true
				local v = aplatir(r.Position - m.pos)
				if v.Magnitude > 0.01 then m.yaw = yawVers(v.Unit) end
				m.yawCible = m.yaw
				m.finAction = maintenant + DUREE_ROAR
				etat(m, "Roar")
				return
			end
		end
	end

	if m.cible and hrp then
		local vers = aplatir(hrp.Position - m.pos)
		local d = vers.Magnitude
		local dir = if d > 0.01 then vers.Unit else CFrame.Angles(0, m.yaw, 0).LookVector
		m.yawCible = yawVers(dir)
		local dy = math.abs(hrp.Position.Y - (m.pos.Y + hauteurVol(m)))
		if d <= m.def.portee and dy < 6 + m.hauteur * 0.5 then
			if maintenant >= m.prochaineAttaque then
				m.yaw, m.yawCible = m.yawCible, m.yawCible -- face à la cible, puis figé pendant la préparation
				local prepa = m.def.preparation or PREPARATION -- grands boss : impact calé sur l'animation Attack
				m.prep = {joueur = m.cible, frappe = maintenant + prepa, fin = maintenant + prepa + RECUP_ATTAQUE, faite = false}
				m.prochaineAttaque = maintenant + math.max(m.def.recharge, prepa + RECUP_ATTAQUE)
				m.coup += 1
				m.modele:SetAttribute("Coup", m.coup)
				etat(m, "Attack")
				return
			end
			etat(m, "Idle")
		else
			local vitesse, court = m.def.vitesse, false
			if m.def.vitesseCible then vitesse, court = vitessePoursuite(m, hrp, dt) end
			local avance = math.min(vitesse * dt, math.max(0, d - m.def.portee * 0.7))
			if m.garde and aplatir(m.pos + dir * avance - m.garde).Magnitude > GARDE_LAISSE then
				-- au bout de la laisse : le garde abandonne et rentre (jamais figé à attendre)
				m.cible = nil
				m.errance, m.finErrance = m.origine, maintenant + 20
				etat(m, "Idle")
			elseif deplacer(h, m, dir, avance) then
				if court then etat(m, "Run") else marcher(m, 1) end
			else etat(m, "Idle") end
		end
	else
		-- repos : petite errance autour du point d'apparition
		if m.errance then
			local vers = aplatir(m.errance - m.pos)
			local d = vers.Magnitude
			if d < 1 or maintenant > m.finErrance then
				m.errance = nil
				m.prochaineErrance = maintenant + rng:NextNumber(3, 6)
				etat(m, "Idle")
			else
				local dir = vers.Unit
				local allure = if (m.origine - m.pos).Magnitude > ERRANCE * 1.5 then 0.6 else 0.35
				m.yawCible = yawVers(dir)
				if deplacer(h, m, dir, math.min(m.def.vitesse * allure * dt, d)) then
					marcher(m, allure)
				else
					m.errance = nil
					m.prochaineErrance = maintenant + rng:NextNumber(2, 4)
					etat(m, "Idle")
				end
			end
		elseif maintenant >= m.prochaineErrance then
			local a, r = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(2, ERRANCE)
			m.errance = m.origine + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			m.finErrance = maintenant + 15
		else
			etat(m, "Idle")
		end
	end
	m.yaw = rapprocherAngle(m.yaw, m.yawCible, VIRAGE * dt)
end

-- Évite que les mobs s'empilent
local function separer(h)
	local mobs = h.mobs
	for i = 1, #mobs do
		local a = mobs[i]
		if not a.mort then
			for j = i + 1, #mobs do
				local b = mobs[j]
				if not b.mort and a.vole == b.vole then
					local v = aplatir(b.pos - a.pos)
					local d = v.Magnitude
					local mini = (a.rayon + b.rayon) * 0.8
					if d < mini then
						local dir = if d > 0.01 then v.Unit else Vector3.xAxis
						local pousse = (mini - d) * 0.5
						if not b.boss then deplacer(h, b, dir, pousse, true) end
						if not a.boss then deplacer(h, a, -dir, pousse, true) end
					end
				end
			end
		end
	end
end

local function compterVivants(h): number
	local n = 0
	for _, m in h.mobs do
		if not m.mort and not m.boss then n += 1 end
	end
	return n
end

local function pointLoin(h): Vector3?
	local points = h.points
	if #points == 0 then return nil end
	local depart = rng:NextInteger(1, #points)
	for k = 0, #points - 1 do
		local p = points[(depart + k - 1) % #points + 1]
		local libre = true
		for joueur in h.joueurs do
			local hrp = racineJoueur(joueur)
			if hrp and (hrp.Position - p).Magnitude <= RENFORT_DISTANCE then
				libre = false
				break
			end
		end
		if libre then return p end
	end
	return nil
end

local function majGrotte(h, dt: number, maintenant: number)
	if not h.actif or not h.modele.Parent or not h.dossier.Parent then
		MobsGrotte.nettoyer(h)
		return
	end
	for joueur in h.joueurs do
		if not joueur.Parent then h.joueurs[joueur] = nil end
	end
	local mobs = h.mobs
	for i = #mobs, 1, -1 do
		local m = mobs[i]
		if not m.modele.Parent or not m.root.Parent then
			table.remove(mobs, i)
		elseif m.mort then
			if maintenant >= m.finMort then
				m.modele:Destroy()
				table.remove(mobs, i)
			end
		elseif m.gele then -- figé (cinématique) : suit m.pos / m.yaw posés par son script
			m.recul = nil
		else
			local r = m.recul
			if r then -- knockback : glisse dans le sens du coup, s'arrête au mur (deplacer fait le raycast)
				local pas = math.min(r.reste, r.vitesse * dt)
				r.reste -= pas
				if not deplacer(h, m, r.dir, pas, true) or r.reste <= 0.01 then m.recul = nil end
			end
			majMob(h, m, dt, maintenant)
		end
	end
	separer(h)
	for _, m in mobs do
		local cf = poser(m, maintenant)
		m.cfDe = m.root.CFrame
		m.cfVers = cf
		m.t = if cf == m.cfDe then PAS else 0
	end
	-- renforts (jamais au-delà du nombre de départ, loin des joueurs)
	if maintenant >= h.prochainRenfort then
		h.prochainRenfort = maintenant + h.niveau.renfortSecondes
		local manque = h.nombreDepart - compterVivants(h)
		if manque > 0 then
			local p = pointLoin(h)
			if p then MobsGrotte.groupe(h, p, math.min(manque, 2), nil) end
		end
	end
end

local function mourir(h, m, tueur: Player?)
	m.mort = true
	m.prep = nil
	m.cible = nil
	m.finMort = os.clock() + (if m.boss then DUREE_MORT_BOSS else DUREE_MORT)
	etat(m, "Death")
	if h.surMort then
		task.spawn(h.surMort, m.def.id, m.boss, tueur)
	end
end

-- dir = horizontale unitaire joueur → mob. Contrat client (EffetCoupMob) : CoupDirection puis DernierCoup,
-- posés AVANT PV (sinon le client jouerait l'ancien flash au premier coup).
local function blesser(h, m, degats: number, joueur: Player, dir: Vector3)
	local maintenant = os.clock()
	m.modele:SetAttribute("CoupDirection", dir)
	m.modele:SetAttribute("DernierCoup", maintenant)
	m.modele:SetAttribute("Auteur", joueur.UserId) -- chiffres de dégâts : les miens / ceux des autres
	local avant = m.pv
	m.pv = math.max(0, m.pv - degats)
	m.modele:SetAttribute("PV", m.pv)
	if h.surBlessure then
		task.spawn(h.surBlessure, m, avant - m.pv, joueur)
	end
	if m.pv <= 0 then
		mourir(h, m, joueur)
		return
	end
	if h.joueurs[joueur] and not m.cible then
		m.cible, m.vuA, m.errance = joueur, maintenant, nil
	end
	-- Posture : un recul au plus toutes les RECUL_RECHARGE s, un Hurt toutes les POSTURE s (pas de stun-lock)
	if not m.recul and maintenant >= m.prochainRecul then
		local dist = if m.boss then 0.8 else RECUL * math.clamp(6 / math.max(m.hauteur, 1), 0.35, 1)
		m.recul = {dir = dir, reste = dist, vitesse = dist / RECUL_DUREE}
		m.prochainRecul = maintenant + RECUL_RECHARGE
	end
	if m.boss then return end -- le boss encaisse sans broncher (à peine repoussé)
	local rugit = m.etat == "Roar" and maintenant < m.finAction
	if not m.prep and not rugit and maintenant >= m.prochainHurt then
		m.finAction = maintenant + DUREE_HURT
		m.prochainHurt = maintenant + POSTURE
		etat(m, "Hurt")
	end
end

local function surCoupEpee(joueur: Player, coup: number, outil: Instance)
	if typeof(joueur) ~= "Instance" or typeof(outil) ~= "Instance" then return end
	local degats = outil:GetAttribute("Degats")
	if type(degats) ~= "number" or degats <= 0 then return end
	local hrp = racineJoueur(joueur)
	if not hrp then return end
	local devant = aplatir(hrp.CFrame.LookVector)
	if devant.Magnitude < 0.01 then return end
	devant = devant.Unit
	if coup == 3 then degats *= BONUS_COUP3 end
	local origine = hrp.Position
	local centre = origine + devant * EPEE_AVANCE
	local portee = EPEE_RAYON + EPEE_TOLERANCE + 3
	for h in grottes do
		if h.actif and h.joueurs[joueur] then
			for _, m in h.mobs do
				if not m.mort and not m.invulnerable and (m.root.Position - centre).Magnitude <= m.englobe + portee then
					local point = toucheMob(m, centre, m.root.CFrame) or toucheMob(m, centre, m.cfDe)
					if point then
						local vers = point - origine
						local mur = workspace:Raycast(origine, vers, h.params)
						if not mur or mur.Distance >= vers.Magnitude - 1 then
							local plat = aplatir(m.pos - origine)
							blesser(h, m, degats, joueur, if plat.Magnitude > 0.01 then plat.Unit else devant)
						end
					end
				end
			end
		end
	end
end

-- ---------- API ----------

-- Liste de mobs pour un groupe posé en centre : celle de la zone du décor (niveau.mobsZones, parts « GrotteZone »
-- ZoneForet / ZoneLac / ZoneTemple de la grotte) si le centre est dedans, sinon niveau.mobs
local function mobsPour(h, centre: Vector3)
	local zones = h.niveau.mobsZones
	if type(zones) ~= "table" then return h.niveau.mobs end
	local meilleure, dmin = nil, math.huge
	for _, z in CollectionService:GetTagged("GrotteZone") do
		if z:IsA("BasePart") and z:IsDescendantOf(h.modele) then
			local liste = zones[(z.Name:gsub("^Zone", ""))]
			local r = z:GetAttribute("Rayon") or 20
			local d = (z.Position - centre).Magnitude
			if liste and d < r and d / r < dmin then
				meilleure, dmin = liste, d / r
			end
		end
	end
	return meilleure or h.niveau.mobs
end

-- Groupe de n mobs autour de centre (décalés de 3-5 studs s'il y a de l'air et du sol) ; garde = gisement défendu
function MobsGrotte.groupe(h, centre: Vector3, n: number, garde: Vector3?): number
	local haut = Vector3.new(0, 2, 0)
	local crees = 0
	local liste = mobsPour(h, centre)
	for i = 1, n do
		local p = centre
		if i > 1 then
			local a = i / n * 2 * math.pi + rng:NextNumber(-0.4, 0.4)
			local cand = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(3, 5)
			if not workspace:Raycast(centre + haut, cand - centre, h.params) and sol(h, cand.X, centre.Y, cand.Z, 2, 6) then p = cand end
		end
		if creerMob(h, Grottes.tirer(liste, rng), p, nil, garde) then crees += 1 end
	end
	return crees
end

function MobsGrotte.peupler(grotte, niveau, joueurs)
	if type(niveau) == "number" then niveau = Grottes.niveau(niveau) end
	assert(type(niveau) == "table", "MobsGrotte.peupler : niveau inconnu")
	assert(grotte and grotte.modele, "MobsGrotte.peupler : grotte.modele manquant")

	local dossier = Instance.new("Folder")
	dossier.Name = "Mobs"
	dossier.Parent = grotte.modele

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain, grotte.modele} -- les pièces des mobs ont CanQuery = false
	params.RespectCanCollide = true
	params.IgnoreWater = true

	local h = {
		actif = true, grotte = grotte, modele = grotte.modele, niveau = niveau, dossier = dossier,
		params = params, joueurs = {}, mobs = {}, points = grotte.pointsMobs or {},
		nombreDepart = 0, prochainRenfort = os.clock() + niveau.renfortSecondes, surMort = nil, refuges = {},
	}
	for _, a in grotte.apparitions or {} do table.insert(h.refuges, a.Position) end
	for k, v in joueurs or {} do
		local j = if typeof(k) == "Instance" then k else v
		if typeof(j) == "Instance" and j:IsA("Player") then h.joueurs[j] = true end
	end

	-- points de départ : hors de la zone sûre des apparitions des joueurs (jamais de mob à l'arrivée)
	local function horsZone(p: Vector3): boolean
		for _, a in grotte.apparitions or {} do
			if (a.Position - p).Magnitude < LOIN_APPARITION then return false end
		end
		return true
	end
	local loin = {}
	for _, p in h.points do
		if horsZone(p) then table.insert(loin, p) end
	end
	for i = #loin, 2, -1 do
		local j = rng:NextInteger(1, i)
		loin[i], loin[j] = loin[j], loin[i]
	end

	-- 1. Un groupe de 2-3 gardes par gisement ; 2. le reste par groupes de 2-3, loin des gisements
	-- grotte.sansGroupes : aucun groupe de départ (arène du boss du village : le boss seul, renforts à la main)
	local n = rng:NextInteger(niveau.nombreMobs[1], niveau.nombreMobs[2])
	local poses = 0
	local gisements = {}
	for _, g in grotte.gisements or {} do
		if horsZone(g.centre) then
			poses += MobsGrotte.groupe(h, g.centre, rng:NextInteger(2, 3), g.centre)
			table.insert(gisements, g.centre)
		end
	end
	local reste = if grotte.sansGroupes then 0 else math.max(n - poses, 2) -- toujours au moins un groupe errant en plus des gardes
	local centres = {}
	for _, p in loin do
		local ok = true
		for _, q in gisements do
			if (q - p).Magnitude < 25 then ok = false; break end
		end
		for _, q in centres do
			if (q - p).Magnitude < 20 then ok = false; break end
		end
		if ok then table.insert(centres, p) end
	end
	if #centres == 0 then centres = loin end
	-- les zones à thème du décor (mobsZones : forêt, lacs, temple) sont servies en premier
	if type(niveau.mobsZones) == "table" then
		local dedans, dehors = {}, {}
		for _, c in centres do
			table.insert(if mobsPour(h, c) ~= niveau.mobs then dedans else dehors, c)
		end
		centres = dedans
		for _, c in dehors do table.insert(centres, c) end
	end
	local k = 0
	while reste > 0 and #centres > 0 do
		local taille = if reste <= 3 then reste elseif reste == 4 then 2 else rng:NextInteger(2, 3)
		k += 1
		poses += MobsGrotte.groupe(h, centres[(k - 1) % #centres + 1], taille, nil)
		reste -= taille
	end
	h.nombreDepart = poses
	if poses == 0 and not grotte.sansGroupes then warn("MobsGrotte : aucun point d'apparition de mob dans la grotte") end
	if niveau.boss and grotte.salleBoss then
		h.boss = creerMob(h, niveau.boss, grotte.salleBoss, true)
	end

	grottes[h] = true
	return h
end

-- Un mob précis en `point` (boss d'événement : le Roi déchu du trône de magma, TroneLave)
function MobsGrotte.creer(h, def, point: Vector3, boss: boolean?)
	if not (h and h.actif) then return nil end
	return creerMob(h, def, point, boss)
end

-- Fait grandir un mob (transformation de phase d'un boss) : `facteur` × sa taille actuelle, en `duree` s.
-- Met à jour taille, rayon, portée et hitbox (recalculée à la fin, à partir des pièces au repos).
function MobsGrotte.grandir(m, facteur: number, duree: number?)
	if m.mort or facteur <= 0 then return end
	local modele: Model = m.modele
	local depart = modele:GetScale()
	local fin = depart * facteur
	local etapes = math.max(1, math.floor((duree or 1) / 0.05))
	m.echelle *= facteur
	m.hauteur *= facteur
	m.rayon *= facteur
	m.def.portee = (m.def.portee or 0) * facteur
	modele:SetAttribute("Hauteur", m.hauteur)
	task.spawn(function()
		for i = 1, etapes do
			if m.mort or not modele.Parent then return end
			local t = i / etapes
			modele:ScaleTo(depart + (fin - depart) * (1 - (1 - t) * (1 - t)))
			task.wait(0.05)
		end
		if m.mort or not modele.Parent then return end
		if HITBOX_DEBUG then
			for _, a in m.root:GetChildren() do
				if a.Name == "Hitbox" then a:Destroy() end
			end
		end
		m.hitbox, m.englobe = hitbox(modele, m.root, m.rayon, m.hauteur)
	end)
end

function MobsGrotte.ajouterJoueur(h, joueur: Player)
	if h and h.actif then h.joueurs[joueur] = true end
end

function MobsGrotte.retirerJoueur(h, joueur: Player)
	if not h then return end
	h.joueurs[joueur] = nil
	for _, m in h.mobs do
		if m.cible == joueur then m.cible = nil end
	end
end

function MobsGrotte.nettoyer(h)
	if not h then return end
	h.actif = false
	grottes[h] = nil
	for _, m in h.mobs do
		m.mort = true
	end
	table.clear(h.mobs)
	table.clear(h.joueurs)
	if h.dossier then h.dossier:Destroy() end
end

-- ---------- Boucle unique ----------

local cumul = 0
RunService.Heartbeat:Connect(function(dt)
	for h in grottes do
		for _, m in h.mobs do
			if m.t < PAS then
				m.t = math.min(m.t + dt, PAS)
				if m.root.Parent then
					m.root.CFrame = m.cfDe:Lerp(m.cfVers, m.t / PAS)
				end
			end
		end
	end
	cumul += dt
	if cumul < PAS then return end
	local pas = math.min(cumul, 0.5)
	cumul = 0
	local maintenant = os.clock()
	for h in grottes do
		local ok, err = pcall(majGrotte, h, pas, maintenant)
		if not ok then warn("MobsGrotte : " .. tostring(err)) end
	end
end)

task.spawn(function()
	local hook = ServerStorage:WaitForChild("CoupEpee")
	if hook:IsA("BindableEvent") then
		hook.Event:Connect(surCoupEpee)
	end
end)

return MobsGrotte
