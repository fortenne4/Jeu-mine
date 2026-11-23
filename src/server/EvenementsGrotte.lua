-- Événements aléatoires de la grotte −50 m · MODULE SERVEUR (ServerScriptService › Jeu › EvenementsGrotte)
-- Pendant une expédition au palier 1, de temps en temps (première après 1 min 30 à 2 min 30, puis toutes les
-- 2 min 30 à 4 min), un événement surgit près d'un joueur de l'expédition (jamais au camp de départ, jamais pendant
-- le combat du sanctuaire) :
--   * Pluie de cristaux : une douzaine d'éclats lumineux tombent du plafond ; on les ramasse en marchant dessus
--     (+1 pièce chacun, 25 s pour les prendre) ;
--   * Nuée de chauves-souris : un groupe de chauves-souris jaillit derrière le joueur ;
--   * Éboulement : grondement, poussière, la caméra tremble ; une veine rare apparaît dans les gravats (2 Bronze,
--     parfois de l'Or) ;
--   * Luciole dorée : elle fuit les joueurs ; qui l'attrape en 30 s gagne 25 pièces et peut-être un fragment de carte.
-- Les joueurs de l'expédition reçoivent l'annonce et les effets par le RemoteEvent « EvenementGrotte »
-- (EvenementsGrotte.client.lua).
--   EvenementsGrotte.lancer(exp) -- appelé par Grottes.server.lua après MobsGrotte.peupler (exp = expédition)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MobsGrotte = require(script.Parent.MobsGrotte)
local CarteNaine = require(script.Parent.CarteNaine)
local MineraisModeles = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MineraisModeles"))

local EvenementsGrotte = {}

local PREMIER = {90, 150}
local INTERVALLE = {150, 240}
local ZONE_CAMP = 40 -- pas d'événement à moins de ça du camp de départ
local PIECES_ECLAT, NB_ECLATS, DUREE_ECLATS = 1, 12, 25
local PIECES_LUCIOLE, CHANCE_FRAGMENT_LUCIOLE, DUREE_LUCIOLE = 25, 0.25, 30
local VITESSE_LUCIOLE = 12 -- un joueur court à 16
local CHAUVES_SOURIS = {{id = "ChauveSourisCave", poids = 1, pv = 18, degats = 5, vitesse = 13, portee = 4, recharge = 1.3, echelle = 1}}

local remote = ReplicatedStorage:FindFirstChild("EvenementGrotte")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "EvenementGrotte"
	remote.Parent = ReplicatedStorage
end
EvenementsGrotte.remote = remote

local rng = Random.new()

local function params(modele: Model): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	p.FilterDescendantsInstances = {workspace.Terrain}
	p.IgnoreWater = true
	return p
end

local function racine(j: Player): BasePart?
	local perso = j.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return perso:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function annoncer(exp, genre: string, donnees: {[string]: any})
	for _, j in exp.joueurs do
		if j.Parent then
			remote:FireClient(j, genre, donnees)
		end
	end
end

local function dossierDe(exp): Folder
	local m = exp.grotte.modele
	local f = m:FindFirstChild("Evenements")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Evenements"
		f.Parent = m
	end
	return f :: Folder
end

-- point au sol, en vue depuis « depuis », à une distance entre dmin et dmax
local function pointAutour(rp: RaycastParams, depuis: Vector3, dmin: number, dmax: number): Vector3?
	local tete = depuis + Vector3.new(0, 2, 0)
	for _ = 1, 16 do
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(dmin, dmax)
		local vise = tete + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if not workspace:Raycast(tete, vise - tete, rp) then
			local sol = workspace:Raycast(vise, Vector3.new(0, -14, 0), rp)
			if sol then
				return sol.Position
			end
		end
	end
	return nil
end

local function plafond(rp: RaycastParams, p: Vector3): number
	local hit = workspace:Raycast(p + Vector3.new(0, 1, 0), Vector3.new(0, 45, 0), rp)
	return if hit then hit.Position.Y - 0.8 else p.Y + 18
end

-- ================= Pluie de cristaux =================
local COULEURS_ECLAT = {Color3.fromRGB(80, 230, 255), Color3.fromRGB(70, 255, 210), Color3.fromRGB(165, 90, 255)}

local function pluie(exp, cible: Player, r: BasePart)
	local rp = params(exp.grotte.modele)
	local f = dossierDe(exp)
	local eclats = {}
	annoncer(exp, "Pluie", {pos = r.Position})
	for i = 1, NB_ECLATS do
		local sol = pointAutour(rp, r.Position, 4, 18)
		if sol then
			local c = COULEURS_ECLAT[(i - 1) % #COULEURS_ECLAT + 1]
			local p = Instance.new("Part")
			p.Name = "EclatCristal"
			p.Size = Vector3.new(0.6, 1.3, 0.6)
			p.Material = Enum.Material.Neon
			p.Color = c
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			local repos = CFrame.new(sol + Vector3.new(0, 0.6, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4))
			p.CFrame = repos + Vector3.new(0, plafond(rp, sol) - sol.Y, 0)
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = c, 8, 1.2, false
			l.Parent = p
			p.Parent = f
			task.delay(rng:NextNumber(0, 1.6), function()
				if p.Parent then
					TweenService:Create(p, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = repos}):Play()
				end
			end)
			table.insert(eclats, p)
		end
	end
	local fin = os.clock() + DUREE_ECLATS + 2
	task.spawn(function()
		while os.clock() < fin and not exp.fini and #eclats > 0 do
			for i = #eclats, 1, -1 do
				local p = eclats[i]
				for _, j in exp.joueurs do
					local rj = racine(j)
					if rj and p.Parent and (rj.Position - p.Position).Magnitude < 4 then
						CarteNaine.crediter(j, PIECES_ECLAT)
						remote:FireClient(j, "Eclat", {pos = p.Position, couleur = p.Color, pieces = PIECES_ECLAT})
						p:Destroy()
						table.remove(eclats, i)
						break
					end
				end
			end
			task.wait(0.15)
		end
		for _, p in eclats do
			if p.Parent then
				TweenService:Create(p, TweenInfo.new(1), {Transparency = 1, Size = p.Size * 0.3}):Play()
				Debris:AddItem(p, 1.1)
			end
		end
	end)
	return true
end

-- ================= Nuée de chauves-souris =================
local function nuee(exp, cible: Player, r: BasePart)
	local h = exp.mobs
	if not (h and h.actif) then
		return false
	end
	local rp = params(exp.grotte.modele)
	-- derrière le joueur de préférence
	local dos = -r.CFrame.LookVector
	local tete = r.Position + Vector3.new(0, 2, 0)
	local centre = nil
	for _, d in {12, 9, 6} do
		local vise = tete + Vector3.new(dos.X, 0, dos.Z).Unit * d
		if not workspace:Raycast(tete, vise - tete, rp) then
			local sol = workspace:Raycast(vise, Vector3.new(0, -14, 0), rp)
			if sol then
				centre = sol.Position
				break
			end
		end
	end
	centre = centre or pointAutour(rp, r.Position, 6, 14)
	if not centre then
		return false
	end
	annoncer(exp, "Nuee", {pos = centre})
	task.wait(1.2)
	if exp.fini or not h.actif then
		return true
	end
	local niveau = h.niveau
	h.niveau = setmetatable({mobs = CHAUVES_SOURIS, mobsZones = false}, {__index = niveau})
	pcall(MobsGrotte.groupe, h, centre, 3 + math.min(#exp.joueurs - 1, 1), nil)
	h.niveau = niveau
	return true
end

-- ================= Éboulement =================
local function eboulement(exp, cible: Player, r: BasePart)
	local rp = params(exp.grotte.modele)
	-- une paroi pas trop loin : là où tombent les gravats et apparaît la veine
	local tete = r.Position + Vector3.new(0, 2, 0)
	local mur = nil
	for _ = 1, 16 do
		local a = rng:NextNumber(0, 2 * math.pi)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local hit = workspace:Raycast(tete, dir * 22, rp)
		if hit and (hit.Position - tete).Magnitude > 7 then
			mur = {pos = hit.Position, normale = hit.Normal, dir = dir}
			break
		end
	end
	if not mur then
		return false
	end
	local pied = mur.pos - mur.dir * 3.5
	local sol = workspace:Raycast(pied + Vector3.new(0, 2, 0), Vector3.new(0, -16, 0), rp)
	if not sol then
		return false
	end
	annoncer(exp, "Eboulement", {pos = sol.Position})
	task.wait(2.2)
	if exp.fini then
		return true
	end
	local f = dossierDe(exp)
	-- gravats qui roulent
	for _ = 1, 7 do
		local p = Instance.new("Part")
		p.Name = "Gravat"
		local s = rng:NextNumber(0.8, 2)
		p.Size = Vector3.new(s, s * rng:NextNumber(0.6, 1), s * rng:NextNumber(0.7, 1.1))
		p.Material = Enum.Material.Slate
		p.Color = Color3.fromRGB(88, 84, 80)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, true, false, false
		local cible2 = sol.Position + Vector3.new(rng:NextNumber(-3, 3), s * 0.35, rng:NextNumber(-3, 3))
		local repos = CFrame.new(cible2) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6))
		p.CFrame = repos + Vector3.new(0, plafond(rp, sol.Position) - sol.Position.Y - 1, 0) + mur.dir * 1.5
		p.Parent = f
		TweenService:Create(p, TweenInfo.new(rng:NextNumber(0.5, 0.9), Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = repos}):Play()
	end
	-- la veine rare dévoilée
	local types = {"Bronze", "Bronze"}
	if rng:NextNumber() < 0.3 then
		types[2] = "Gold"
	end
	local grotte = exp.grotte
	for i, t in types do
		local cote = Vector3.new(-mur.dir.Z, 0, mur.dir.X) * (i == 1 and -1.8 or 1.8)
		local s = MineraisModeles.VISUEL[t].taille
		local p = sol.Position + cote
		local hit = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), rp)
		if hit then
			p = hit.Position
		end
		local ok, mm, coeur = pcall(MineraisModeles.construire, t, CFrame.new(p - Vector3.new(0, 1.25 * s - 0.1, 0)), Random.new(rng:NextInteger(1, 1e6)), true)
		if ok and mm and coeur then
			for _, d in mm:GetChildren() do
				if d:IsA("BasePart") then
					d.CanQuery = d == coeur
				end
			end
			coeur:SetAttribute("Type", t)
			coeur:SetAttribute("Taille", s)
			local pv = if t == "Gold" then 8 else 5
			coeur:SetAttribute("PV", pv)
			coeur:SetAttribute("PVMax", pv)
			coeur:SetAttribute("Proprietaire", grotte.modele:GetAttribute("Proprietaire"))
			local inv = grotte.modele:GetAttribute("Invite")
			if inv then
				coeur:SetAttribute("Invite", inv)
			end
			coeur:SetAttribute("Secret", true) -- le rocher s'efface une fois cassé (SecretsGrotte.server.lua)
			mm.Parent = f
			game:GetService("CollectionService"):AddTag(coeur, "Minerai")
		end
	end
	annoncer(exp, "Veine", {pos = sol.Position, or_ = types[2] == "Gold"})
	return true
end

-- ================= Luciole dorée =================
local function luciole(exp, cible: Player, r: BasePart)
	local rp = params(exp.grotte.modele)
	local depart = pointAutour(rp, r.Position, 10, 18)
	if not depart then
		return false
	end
	local f = dossierDe(exp)
	local p = Instance.new("Part")
	p.Name = "LucioleDoree"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * 0.9
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 215, 90)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	local pos = depart + Vector3.new(0, 3, 0)
	p.Position = pos
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = p.Color, 16, 2, false
	l.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(p.Color)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Rate = 30
	e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = p
	p.Parent = f
	annoncer(exp, "Luciole", {pos = pos, duree = DUREE_LUCIOLE})
	local fin = os.clock() + DUREE_LUCIOLE
	local dir = Vector3.new(1, 0, 0)
	task.spawn(function()
		local dt = 0.1
		while os.clock() < fin and not exp.fini and p.Parent do
			-- le joueur le plus proche
			local proche, dmin = nil, math.huge
			for _, j in exp.joueurs do
				local rj = racine(j)
				if rj then
					local d = (rj.Position - pos).Magnitude
					if d < dmin then
						proche, dmin = rj, d
					end
				end
			end
			if proche and dmin < 4.5 then
				local gagnant = nil
				for _, j in exp.joueurs do
					if racine(j) == proche then
						gagnant = j
					end
				end
				if gagnant then
					CarteNaine.crediter(gagnant, PIECES_LUCIOLE)
					annoncer(exp, "LucioleAttrapee", {pos = pos, nom = gagnant.DisplayName, pieces = PIECES_LUCIOLE})
					if rng:NextNumber() < CHANCE_FRAGMENT_LUCIOLE then
						task.delay(1, CarteNaine.donnerFragment, gagnant, "luciole")
					end
				end
				p:Destroy()
				return
			end
			-- fuit : parmi 12 directions, la plus éloignée du joueur qui ne heurte pas la roche
			if proche and dmin < 30 then
				local fuite = Vector3.new(pos.X - proche.Position.X, 0, pos.Z - proche.Position.Z)
				fuite = if fuite.Magnitude > 0.1 then fuite.Unit else dir
				local meilleur, score = nil, -math.huge
				for k = 0, 11 do
					local a = k / 12 * 2 * math.pi
					local d = Vector3.new(math.cos(a), 0, math.sin(a))
					if not workspace:Raycast(pos, d * 5, rp) then
						local s = d:Dot(fuite) * 2 + d:Dot(dir) + rng:NextNumber(0, 0.3)
						if s > score then
							meilleur, score = d, s
						end
					end
				end
				if meilleur then
					dir = meilleur
					local suivant = pos + dir * VITESSE_LUCIOLE * dt
					-- reste à ~3 studs du sol
					local s = workspace:Raycast(suivant + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), rp)
					if s then
						suivant = Vector3.new(suivant.X, pos.Y + (s.Position.Y + 3 - pos.Y) * 0.3, suivant.Z)
					end
					pos = suivant
				end
			end
			p.Position = pos + Vector3.new(0, math.sin(os.clock() * 5) * 0.3, 0)
			task.wait(dt)
		end
		if p.Parent then
			annoncer(exp, "LucioleEnfuie", {pos = pos})
			TweenService:Create(p, TweenInfo.new(0.8), {Transparency = 1, Size = Vector3.one * 0.1}):Play()
			Debris:AddItem(p, 0.9)
		end
	end)
	return true
end

local EVENEMENTS = {
	{fn = pluie, poids = 3},
	{fn = nuee, poids = 2},
	{fn = eboulement, poids = 2},
	{fn = luciole, poids = 2},
}
EvenementsGrotte.EVENEMENTS = {pluie = pluie, nuee = nuee, eboulement = eboulement, luciole = luciole} -- tests

local function tirer()
	local total = 0
	for _, e in EVENEMENTS do
		total += e.poids
	end
	local x = rng:NextNumber() * total
	for _, e in EVENEMENTS do
		x -= e.poids
		if x <= 0 then
			return e.fn
		end
	end
	return EVENEMENTS[1].fn
end

-- un joueur de l'expédition loin du camp (au hasard)
local function joueurCible(exp): (Player?, BasePart?)
	local depart = exp.grotte.apparitions and exp.grotte.apparitions[1]
	local campPos = depart and depart.Position
	local liste = {}
	for _, j in exp.joueurs do
		local r = racine(j)
		if r and (not campPos or (r.Position - campPos).Magnitude > ZONE_CAMP) then
			table.insert(liste, {j, r})
		end
	end
	if #liste == 0 then
		return nil, nil
	end
	local c = liste[rng:NextInteger(1, #liste)]
	return c[1], c[2]
end

function EvenementsGrotte.lancer(exp)
	local modele = exp and exp.grotte and exp.grotte.modele
	if not modele or modele:GetAttribute("Niveau") ~= 1 then
		return
	end
	task.spawn(function()
		local prochain = os.clock() + rng:NextNumber(PREMIER[1], PREMIER[2])
		while modele.Parent and not exp.fini do
			task.wait(2)
			if os.clock() >= prochain then
				local combat = modele:GetAttribute("SanctuaireEveil") and (modele:GetAttribute("GardiensRestants") or 1) > 0
					and not modele:GetAttribute("CoffreOuvert")
				combat = combat or modele:GetAttribute("AreneVague") ~= nil -- pas pendant l'arène du temple
				local j, r = joueurCible(exp)
				if j and r and not combat then
					local ok, fait = pcall(tirer(), exp, j, r)
					if not ok then
						warn("[EvenementsGrotte] " .. tostring(fait))
					end
					if ok and fait then
						prochain = os.clock() + rng:NextNumber(INTERVALLE[1], INTERVALLE[2])
					else
						prochain = os.clock() + 10 -- raté (pas de place) : on réessaie bientôt
					end
				else
					prochain = os.clock() + 8
				end
			end
		end
	end)
end

-- déclenche un événement tout de suite (tests depuis la barre de commande)
function EvenementsGrotte.forcer(exp, nom: string, joueur: Player)
	local r = racine(joueur)
	local fn = EvenementsGrotte.EVENEMENTS[nom]
	if r and fn then
		return fn(exp, joueur, r)
	end
	return false
end

return EvenementsGrotte
