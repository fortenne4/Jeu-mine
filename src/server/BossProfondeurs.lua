-- Boss des grottes profondes · MODULE SERVEUR (ServerScriptService › Jeu › BossProfondeurs)
-- Paliers 7 et 8 : le boss de la salle du boss (posé par MobsGrotte.peupler d'après Grottes.NIVEAUX[].boss) reçoit
-- ses attaques spéciales et sa récompense ici.
--   * Léviathan des abysses (−900 m, Sanctuaire du Léviathan, MobsVoxels.LeviathanAbysses) :
--     « Raz-de-marée » (onde d'eau autour de lui : sauter ou s'éloigner) et « Tentacules » (cercles sous les joueurs,
--     des tentacules jaillissent du sol : sortir des cercles). Mort : chaque joueur présent reçoit 1 lunarite + 1
--     magmaïte (de quoi forger la Lame des marées ou le Heaume des marées chez Brom) + des pièces.
--   * Gardien des astres (−1200 m, Autel des constellations, MobsVoxels.GardienAstres) :
--     « Onde stellaire » et « Pluie d'étoiles » (mêmes mécanismes). Mort : l'Épée des astres (objet unique, une fois
--     par joueur : marque « EpeeAstres » dans profil.fragments, comme MagmaForge) ; déjà obtenue (ou coffre
--     d'équipement plein) → récompense de consolation (pièces + lunarite + magmaïte).
-- Serveur autoritaire : zones, dégâts, cadence et récompenses décidés ici ; une seule récompense par expédition, aux
-- joueurs de l'expédition dont le personnage est dans la grotte. Zones rouges = Parts « AlerteBoss » répliquées.
-- RemoteEvent « BossProfondeurs » (serveur → client, BossProfondeurs.client.lua) :
--   ("Butin", {boss, minerais = {{id, n}}, pieces})            butin du Léviathan / consolation du Gardien
--   ("EpeeAstres", {nom, degats})                              Épée des astres obtenue
--   BossProfondeurs.preparer(exp) -- appelé par Grottes.server.lua après TroneLave.preparer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))
local CarteNaine = require(script.Parent:WaitForChild("CarteNaine"))

local BossProfondeurs = {}

-- ===== Réglages : récompenses =====
local BUTIN_LEVIATHAN = {{"Lunarite", 1}, {"Magmaite", 1}} -- 2 minerais = le minimum d'une épée ou d'un casque (Forge)
local PIECES_LEVIATHAN = 1000
local MARQUE_EPEE = "EpeeAstres" -- profil.fragments : Épée des astres déjà obtenue
BossProfondeurs.EPEE_ASTRES = {
	nom = "Épée des astres",
	modele = "EpeeDesAstres", -- Partage › ArmesVoxels › EpeeDesAstres (modèle provisoire, voir ce fichier)
	couleur = Color3.fromRGB(70, 90, 220),
	degats = 900, -- bien au-dessus de toutes les épées forgées (max actuel : Lame des marées, 425)
}
local CONSOLATION_ASTRES = {{"Lunarite", 2}, {"Magmaite", 2}}
local PIECES_CONSOLATION = 5000

-- ===== Réglages : attaques spéciales (dégâts avant la défense du joueur) =====
local SPECIALE_PREMIERE = 6 -- s après que le boss a pris une cible
local SPECIALE_INTERVALLE = 9 -- s entre la fin d'une spéciale et la suivante
local SPECIALE_REPOS = 0.6 -- s sans coup de base juste après une spéciale
local PORTEE_SPECIALES = 60 -- studs autour du boss : seuls ces joueurs sont visés par les spéciales
local MARGE_GROTTE = 80 -- un joueur compte s'il est à moins de rayon de la grotte + ça de son centre

type Config = {
	onde: {clip: string, prepa: number, rayon: number, duree: number, epaisseur: number, degats: number, declenche: number, couleur: Color3},
	impacts: {clip: string, prepa: number, nombre: number, rayon: number, ecart: number, degats: number, genre: string, couleur: Color3},
}
local BOSS: {[string]: Config} = {
	LeviathanAbysses = {
		onde = {clip = "Vague", prepa = 1.2, rayon = 20, duree = 0.9, epaisseur = 2.6, degats = 260, declenche = 14,
			couleur = Color3.fromRGB(70, 220, 235)},
		impacts = {clip = "Tentacules", prepa = 1.4, nombre = 6, rayon = 4, ecart = 0.2, degats = 230, genre = "tentacule",
			couleur = Color3.fromRGB(150, 70, 200)},
	},
	GardienAstres = {
		onde = {clip = "Nova", prepa = 1.2, rayon = 22, duree = 0.8, epaisseur = 2.6, degats = 340, declenche = 15,
			couleur = Color3.fromRGB(255, 214, 120)},
		impacts = {clip = "Invocation", prepa = 1.6, nombre = 8, rayon = 4.5, ecart = 0.16, degats = 300, genre = "etoile",
			couleur = Color3.fromRGB(170, 140, 255)},
	},
}

local remote = ReplicatedStorage:FindFirstChild("BossProfondeurs")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "BossProfondeurs"
	remote.Parent = ReplicatedStorage
end

local ROUGE_ALERTE = Color3.fromRGB(190, 30, 20)
local paramsSol = RaycastParams.new()
paramsSol.FilterType = Enum.RaycastFilterType.Include
paramsSol.FilterDescendantsInstances = {workspace.Terrain}
paramsSol.IgnoreWater = true

local function plat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function vivant(j: Player): (BasePart?, Humanoid?)
	local perso = j.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil, nil
	end
	return perso:FindFirstChild("HumanoidRootPart") :: BasePart?, hum
end

local function solSous(e, p: Vector3, haut: number): Vector3?
	local r = workspace:Raycast(p + Vector3.new(0, haut, 0), Vector3.new(0, -(haut + 14), 0), e.params)
	return r and r.Position
end

-- combattants vivants encore dans la grotte (suivis par les mobs) et près du boss (pas les mineurs à l'autre bout)
local function cibles(e): {{j: Player, hrp: BasePart, hum: Humanoid}}
	local t = {}
	local h = e.exp.mobs
	for _, j in e.exp.joueurs do
		local hrp, hum = vivant(j)
		if hrp and hum and h and h.joueurs[j] and (hrp.Position - e.boss.pos).Magnitude < PORTEE_SPECIALES then
			table.insert(t, {j = j, hrp = hrp, hum = hum})
		end
	end
	return t
end

local function blesser(j: Player, hum: Humanoid, degats: number)
	local defense = j:GetAttribute("StatDefense")
	hum:TakeDamage(degats * Grottes.reductionDefense(if type(defense) == "number" then defense else 0))
end

-- le joueur saute-t-il ? (hauteur du HumanoidRootPart au-dessus du sol, comparée à sa hauteur debout)
local function enLAir(e, hrp: BasePart, hum: Humanoid): boolean
	local r = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), e.params)
	if not r then
		return true
	end
	local debout = if hum.RigType == Enum.HumanoidRigType.R6 then 3 else hum.HipHeight + hrp.Size.Y / 2
	return hrp.Position.Y - r.Position.Y > debout + 1.2
end

local function piece(e, nom: string, taille: Vector3, cf: CFrame, couleur: Color3, materiau: Enum.Material, transparence: number): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
	p.Size, p.CFrame, p.Color, p.Material, p.Transparency = taille, cf, couleur, materiau, transparence
	p.Parent = e.alertes
	return p
end

-- zone d'alerte rouge au sol (disque), qui se fonce pendant `duree`
local function alerte(e, centre: Vector3, rayon: number, duree: number): Part
	local p = piece(e, "AlerteBoss", Vector3.new(0.15, rayon * 2, rayon * 2), CFrame.new(centre + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		ROUGE_ALERTE, Enum.Material.SmoothPlastic, 0.7)
	p.Shape = Enum.PartType.Cylinder
	TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Linear), {Transparency = 0.3}):Play()
	return p
end

local function arret(e, m): boolean
	return m.mort or e.exp.fini or not m.modele.Parent
end

local function attendre(e, m, duree: number): boolean
	local fin = os.clock() + duree
	while os.clock() < fin do
		if arret(e, m) then
			return false
		end
		task.wait(0.05)
	end
	return not arret(e, m)
end

local function etatBoss(m, nom: string)
	m.etat = nom
	m.modele:SetAttribute("Etat", nom)
end

local function tourner(m, vers: Vector3)
	local v = plat(vers - m.pos)
	if v.Magnitude > 0.01 then
		m.yaw = math.atan2(-v.X, -v.Z)
		m.yawCible = m.yaw
	end
end

-- 1. Onde (raz-de-marée / onde stellaire) : disque rouge pendant prepa, puis un anneau qui s'élargit ; touché si on
-- est sur son front au sol (sauter l'esquive) ; une seule touche par joueur
local function onde(e, m, c)
	local centre = m.pos
	etatBoss(m, c.clip)
	local d = alerte(e, centre, c.rayon, c.prepa)
	local ok = attendre(e, m, c.prepa)
	d:Destroy()
	if not ok then
		return
	end
	-- anneau visible (répliqué) : cylindre creux simulé par un disque néon translucide qui s'élargit et s'efface
	local anneau = piece(e, "OndeBoss", Vector3.new(1.2, 2, 2), CFrame.new(centre + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		c.couleur, Enum.Material.Neon, 0.35)
	anneau.Shape = Enum.PartType.Cylinder
	TweenService:Create(anneau, TweenInfo.new(c.duree, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(1.2, c.rayon * 2, c.rayon * 2), Transparency = 0.85}):Play()
	Debris:AddItem(anneau, c.duree + 0.2)
	local touches = {}
	local t0 = os.clock()
	while true do
		local u = math.min(1, (os.clock() - t0) / c.duree)
		local r = c.rayon * u
		for _, cb in cibles(e) do
			if not touches[cb.j] then
				local v = cb.hrp.Position - centre
				if math.abs(plat(v).Magnitude - r) < c.epaisseur and math.abs(v.Y) < 8 and not enLAir(e, cb.hrp, cb.hum) then
					touches[cb.j] = true
					blesser(cb.j, cb.hum, c.degats)
				end
			end
		end
		if u >= 1 or arret(e, m) then
			return
		end
		task.wait(0.05)
	end
end

-- effet d'un impact (répliqué) : tentacule qui jaillit du sol, ou étoile qui tombe de la voûte
local function effetImpact(e, pos: Vector3, c)
	if c.genre == "tentacule" then
		local haut = 7
		local p = piece(e, "TentaculeBoss", Vector3.new(1.4, 0.2, 1.4), CFrame.new(pos), c.couleur, Enum.Material.SmoothPlastic, 0)
		local pointe = piece(e, "TentaculeBoss", Vector3.new(0.6, 0.6, 0.6), CFrame.new(pos), Color3.fromRGB(255, 122, 217), Enum.Material.Neon, 0)
		local monte = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(p, monte, {Size = Vector3.new(1.4, haut, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, haut / 2, 0)) * CFrame.Angles(0.15, 0, 0.1)}):Play()
		TweenService:Create(pointe, monte, {CFrame = CFrame.new(pos + Vector3.new(0.3, haut + 0.2, 0.4))}):Play()
		task.delay(0.9, function()
			local descend = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			if p.Parent then TweenService:Create(p, descend, {Size = Vector3.new(1.4, 0.2, 1.4), CFrame = CFrame.new(pos)}):Play() end
			if pointe.Parent then TweenService:Create(pointe, descend, {CFrame = CFrame.new(pos), Transparency = 1}):Play() end
		end)
		Debris:AddItem(p, 1.4)
		Debris:AddItem(pointe, 1.4)
	else
		local etoile = piece(e, "EtoileBoss", Vector3.new(1.3, 1.3, 1.3), CFrame.new(pos + Vector3.new(0, 26, 0)) * CFrame.Angles(0, 0, math.rad(45)),
			Color3.fromRGB(255, 240, 190), Enum.Material.Neon, 0)
		local l = Instance.new("PointLight")
		l.Color, l.Brightness, l.Range, l.Shadows = c.couleur, 2, 14, false
		l.Parent = etoile
		TweenService:Create(etoile, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0, 0.6, 0))}):Play()
		task.delay(0.25, function()
			if etoile.Parent then
				TweenService:Create(etoile, TweenInfo.new(0.4), {Size = Vector3.new(c.rayon * 2, 0.4, c.rayon * 2), Transparency = 1}):Play()
			end
		end)
		Debris:AddItem(etoile, 0.8)
	end
end

-- 2. Impacts (tentacules / pluie d'étoiles) : un cercle rouge sous chaque combattant + d'autres autour, impacts l'un
-- après l'autre ; touché si on est encore dans le cercle au moment de l'impact
local function impacts(e, m, c)
	local liste = cibles(e)
	if #liste == 0 then
		return
	end
	tourner(m, liste[1].hrp.Position)
	etatBoss(m, c.clip)
	local points = {}
	for _, cb in liste do
		table.insert(points, cb.hrp.Position)
	end
	for _ = 1, 30 do
		if #points >= c.nombre then
			break
		end
		local base = liste[e.rng:NextInteger(1, #liste)].hrp.Position
		local a, r = e.rng:NextNumber(0, 2 * math.pi), e.rng:NextNumber(4, 13)
		table.insert(points, base + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	local liste2 = {}
	for _, p in points do
		local sol = solSous(e, p, 6)
		if sol then
			local t = c.prepa + #liste2 * c.ecart
			table.insert(liste2, {pos = sol, t = t, alerte = alerte(e, sol, c.rayon, t)})
		end
	end
	local t0 = os.clock()
	for _, im in liste2 do
		local reste = t0 + im.t - os.clock()
		if reste > 0 and not attendre(e, m, reste) then
			break
		end
		im.alerte:Destroy()
		effetImpact(e, im.pos, c)
		for _, cb in cibles(e) do
			local v = cb.hrp.Position - im.pos
			if plat(v).Magnitude < c.rayon + 0.5 and v.Y > -3 and v.Y < 9 then
				blesser(cb.j, cb.hum, c.degats)
			end
		end
	end
	for _, im in liste2 do
		if im.alerte.Parent then
			im.alerte:Destroy()
		end
	end
end

-- Lance la prochaine spéciale (rotation onde → impacts ; l'onde seulement si la cible est proche).
-- Pendant la spéciale, l'IA de MobsGrotte est suspendue (m.gele) : le boss reste blessable.
local function speciale(e, m)
	local hrp = m.cible and vivant(m.cible)
	if not hrp then
		return
	end
	local proche = plat(hrp.Position - m.pos).Magnitude < e.cfg.onde.declenche
	local nom = if e.rang % 2 == 1 and proche then "onde" else "impacts"
	e.rang += 1
	m.gele, m.prep = true, nil
	tourner(m, hrp.Position)
	local ok, err = pcall(function()
		if nom == "onde" then
			onde(e, m, e.cfg.onde)
		else
			impacts(e, m, e.cfg.impacts)
		end
	end)
	if not ok then
		warn("[BossProfondeurs] " .. tostring(err))
	end
	if not m.mort and m.modele.Parent then
		m.gele = false
		m.prochaineAttaque = math.max(m.prochaineAttaque or 0, os.clock() + SPECIALE_REPOS)
		etatBoss(m, "Idle")
	end
end

-- ================= Récompenses =================
local function presents(e): {Player}
	local exp, grotte = e.exp, e.exp.grotte
	local t = {}
	for _, j in exp.joueurs do
		local perso = j.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart")
		if j.Parent == Players and racine and racine:IsA("BasePart") and grotte.centre
			and (racine.Position - grotte.centre).Magnitude <= (grotte.rayon or 195) + MARGE_GROTTE then
			table.insert(t, j)
		end
	end
	return t
end

local function donnerMinerais(j: Player, liste: {{any}}): {{any}}
	local donnes = {}
	for _, l in liste do
		if Donnees.ajouterMinerai(j, l[1], l[2]) then
			Donnees.decouvrirMinerai(j, l[1])
			table.insert(donnes, {l[1], l[2]})
		end
	end
	return donnes
end

-- Épée des astres : la marque d'abord (impossible d'en obtenir deux), puis l'objet ; sinon consolation
local function donnerEpee(j: Player): boolean
	local p = Donnees.profil(j)
	if not p or p.fragments[MARQUE_EPEE] or #p.objets >= Donnees.MAX_OBJETS then
		return false
	end
	if not Donnees.ajouterFragment(j, MARQUE_EPEE) then
		return false
	end
	local c = BossProfondeurs.EPEE_ASTRES
	local objet: Donnees.Objet = {id = tostring(p.prochainId), type = "Epee", modele = c.modele, rang = nil, nom = c.nom,
		couleur = c.couleur:ToHex(), stat = "Dégâts", valeur = c.degats, composition = {}}
	p.prochainId += 1
	table.insert(p.objets, objet)
	Donnees.notifier(j)
	print(string.format("[BossProfondeurs] %s obtient l'%s", j.Name, c.nom))
	return true
end

local function recompenser(e, id: string)
	for _, j in presents(e) do
		if id == "LeviathanAbysses" then
			local donnes = donnerMinerais(j, BUTIN_LEVIATHAN)
			CarteNaine.crediter(j, PIECES_LEVIATHAN)
			remote:FireClient(j, "Butin", {boss = id, minerais = donnes, pieces = PIECES_LEVIATHAN})
		elseif id == "GardienAstres" then
			local p = Donnees.profil(j)
			local plein = p ~= nil and not p.fragments[MARQUE_EPEE] and #p.objets >= Donnees.MAX_OBJETS
			if donnerEpee(j) then
				remote:FireClient(j, "EpeeAstres", {nom = BossProfondeurs.EPEE_ASTRES.nom, degats = BossProfondeurs.EPEE_ASTRES.degats})
			else
				local donnes = donnerMinerais(j, CONSOLATION_ASTRES)
				CarteNaine.crediter(j, PIECES_CONSOLATION)
				remote:FireClient(j, "Butin", {boss = id, minerais = donnes, pieces = PIECES_CONSOLATION, plein = plein})
			end
		end
	end
end

-- ================= Boucle d'un boss =================
local function suivre(e)
	local m = e.boss
	local prochaine: number? = nil
	while not arret(e, m) do
		if m.cible and not m.gele then
			prochaine = prochaine or os.clock() + SPECIALE_PREMIERE
			if os.clock() >= (prochaine :: number) and not m.prep then
				speciale(e, m)
				prochaine = os.clock() + SPECIALE_INTERVALLE
			end
		end
		task.wait(0.1)
	end
	if e.exp.fini or e.recompense or m.pv > 0 then
		return
	end
	e.recompense = true -- une seule fois par expédition
	recompenser(e, m.def.id)
end

function BossProfondeurs.preparer(exp)
	local h = exp.mobs
	local m = h and h.boss
	if not m then
		return
	end
	local cfg = BOSS[m.def.id]
	if not cfg then
		return
	end
	local alertes = Instance.new("Folder")
	alertes.Name = "AlertesBoss"
	alertes.Parent = exp.grotte.modele
	local e = {exp = exp, boss = m, cfg = cfg, alertes = alertes, rang = 1, recompense = false, rng = Random.new(), params = h.params}
	task.spawn(suivre, e)
end

return BossProfondeurs
