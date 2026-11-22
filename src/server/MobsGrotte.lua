-- MobsGrotte (ServerScriptService › Jeu › MobsGrotte) : IA des mobs hostiles des grottes profondes.
-- Serveur autoritaire et léger : UNE boucle Heartbeat pour tous les mobs de toutes les grottes.
-- La logique (cible, vue, attaque, renforts) tourne à 10 Hz ; le déplacement est interpolé à chaque frame.
-- Mobs = modèles MobsVoxels ancrés (Root), déplacés par CFrame, sans Humanoid.
-- Pour le client (MobsGrotte.client) : tag « MobGrotte », attributs MobId, PV, PVMax, Etat
-- ("Idle"/"Walk"/"Attack"/"Hurt"/"Death"/"Roar"), Boss, Coup (compteur d'attaques), Allure, Hauteur.
--
--	local h = MobsGrotte.peupler(grotte, niveau, joueurs) -- grotte = {modele, pointsMobs, salleBoss?, apparitions}
--	h.surMort = function(mobId, estBoss, tueur) end      -- optionnel (récompense, fin de grotte...)
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
local RECUL = 1.4
local VIRAGE = 10 -- rad/s
local VOL = 3 -- hauteur de vol de la chauve-souris
local ERRANCE = 8
local EPEE_PORTEE = 7
local EPEE_COS = math.cos(math.rad(70))
local BONUS_COUP3 = 1.5
local RENFORT_DISTANCE = 40
local LOIN_APPARITION = 25
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

-- Avance de `dist` vers `dir` (plat, unitaire) sans traverser les murs ; contourne à ±45° / ±90°.
local function deplacer(h, m, dir: Vector3, dist: number, droit: boolean?): boolean
	if dist <= 0.01 then return false end
	local hRayon = if m.vole then VOL * m.echelle else math.max(2, m.hauteur * 0.4)
	for _, a in ANGLES do
		if a ~= 0 and droit then break end
		local d = if a == 0 then dir else CFrame.Angles(0, math.rad(a * m.cote), 0):VectorToWorldSpace(dir)
		local mur = workspace:Raycast(m.pos + Vector3.new(0, hRayon, 0), d * (dist + m.rayon), h.params)
		if not mur then
			local cand = m.pos + d * dist
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

local function creerMob(h, def, point: Vector3, boss: boolean?)
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
		vole = def.id == "ChauveSourisCave", echelle = echelle, hauteur = hauteur,
		rayon = math.clamp(math.max(taille.X, taille.Z) * 0.3, 1, 4),
		pv = def.pv, pvMax = def.pv, etat = "Idle", allure = 1,
		origine = pos, pos = pos, yaw = yaw, yawCible = yaw, phase = rng:NextNumber(0, 2 * math.pi), cote = 1,
		cible = nil, vuA = 0, prochaineAttaque = 0, prep = nil, finAction = 0,
		errance = nil, finErrance = 0, prochaineErrance = os.clock() + rng:NextNumber(1, 4),
		rugi = false, mort = false, finMort = 0, coup = 0, tueur = nil,
	}
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
	hum:TakeDamage(m.def.degats * Grottes.reductionDefense(defense))
end

local function chercherCible(h, m)
	local meilleur, dMin, hrpMin, humMin = nil, VUE, nil, nil
	for joueur in h.joueurs do
		local hrp, hum = racineJoueur(joueur)
		if hrp then
			local d = (hrp.Position - m.pos).Magnitude
			if d < dMin and voit(h, m, hrp.Position) then
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
			if not hrp or (hrp.Position - m.pos).Magnitude > ABANDON then
				m.cible, hrp = nil, nil
			elseif voit(h, m, hrp.Position) then
				m.vuA = maintenant
			elseif maintenant - m.vuA > PERTE_VUE then
				m.cible, hrp = nil, nil
			end
		end
	end
	if not m.cible then
		local nouveau, r = chercherCible(h, m)
		if nouveau and r then
			m.cible, hrp, m.vuA, m.errance = nouveau, r, maintenant, nil
			if m.def.id == "BruteProfondeurs" and not m.rugi then
				m.rugi = true
				m.yaw = yawVers(aplatir(r.Position - m.pos).Unit)
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
				m.prep = {joueur = m.cible, frappe = maintenant + PREPARATION, fin = maintenant + PREPARATION + RECUP_ATTAQUE, faite = false}
				m.prochaineAttaque = maintenant + math.max(m.def.recharge, PREPARATION + RECUP_ATTAQUE)
				m.coup += 1
				m.modele:SetAttribute("Coup", m.coup)
				etat(m, "Attack")
				return
			end
			etat(m, "Idle")
		else
			local avance = math.min(m.def.vitesse * dt, math.max(0, d - m.def.portee * 0.7))
			if deplacer(h, m, dir, avance) then marcher(m, 1) else etat(m, "Idle") end
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
		else
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
		if compterVivants(h) < h.nombreDepart then
			local p = pointLoin(h)
			if p then creerMob(h, Grottes.tirer(h.niveau.mobs, rng), p) end
		end
	end
end

local function mourir(h, m, tueur: Player?)
	m.mort = true
	m.prep = nil
	m.cible = nil
	m.finMort = os.clock() + DUREE_MORT
	etat(m, "Death")
	if h.surMort then
		task.spawn(h.surMort, m.def.id, m.boss, tueur)
	end
end

local function blesser(h, m, degats: number, joueur: Player, dir: Vector3)
	m.pv = math.max(0, m.pv - degats)
	m.modele:SetAttribute("PV", m.pv)
	if m.pv <= 0 then
		mourir(h, m, joueur)
		return
	end
	local maintenant = os.clock()
	if h.joueurs[joueur] and not m.cible then
		m.cible, m.vuA, m.errance = joueur, maintenant, nil
	end
	if m.boss then return end -- le boss encaisse sans broncher
	deplacer(h, m, dir, RECUL, true)
	if not m.prep then
		m.finAction = maintenant + DUREE_HURT
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
	for h in grottes do
		if h.actif and h.joueurs[joueur] then
			for _, m in h.mobs do
				if not m.mort then
					local centre = m.pos + Vector3.new(0, hauteurVol(m) + math.min(m.hauteur * 0.5, 3), 0)
					local vers = centre - hrp.Position
					local plat = aplatir(vers)
					local d = plat.Magnitude
					if d <= EPEE_PORTEE + m.rayon and math.abs(vers.Y) < m.hauteur + 4 then
						local dir = if d > 0.01 then plat.Unit else devant
						if (d < 1.5 + m.rayon * 0.5 or devant:Dot(dir) >= EPEE_COS)
							and workspace:Raycast(hrp.Position, vers, h.params) == nil then
							blesser(h, m, degats, joueur, dir)
						end
					end
				end
			end
		end
	end
end

-- ---------- API ----------

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
		nombreDepart = 0, prochainRenfort = os.clock() + niveau.renfortSecondes, surMort = nil,
	}
	for k, v in joueurs or {} do
		local j = if typeof(k) == "Instance" then k else v
		if typeof(j) == "Instance" and j:IsA("Player") then h.joueurs[j] = true end
	end

	-- points de départ : de préférence loin des apparitions des joueurs
	local loin = {}
	for _, p in h.points do
		local ok = true
		for _, a in grotte.apparitions or {} do
			if (a.Position - p).Magnitude < LOIN_APPARITION then
				ok = false
				break
			end
		end
		if ok then table.insert(loin, p) end
	end
	if #loin == 0 then loin = table.clone(h.points) end
	for i = #loin, 2, -1 do
		local j = rng:NextInteger(1, i)
		loin[i], loin[j] = loin[j], loin[i]
	end

	if #loin > 0 then
		local n = rng:NextInteger(niveau.nombreMobs[1], niveau.nombreMobs[2])
		h.nombreDepart = n
		for i = 1, n do
			local p = loin[(i - 1) % #loin + 1]
			if i > #loin then
				p += Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
			end
			creerMob(h, Grottes.tirer(niveau.mobs, rng), p)
		end
	else
		warn("MobsGrotte : aucun point d'apparition de mob dans la grotte")
	end
	if niveau.boss and grotte.salleBoss then
		creerMob(h, niveau.boss, grotte.salleBoss, true)
	end

	grottes[h] = true
	return h
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
