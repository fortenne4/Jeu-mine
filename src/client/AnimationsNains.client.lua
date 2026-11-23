-- Animations des nains du village (Gaspard, Liesel, Brom, Margot), calculées chez chaque joueur.
--
-- Les nains sont des maillages découpés en segments (blender/nains.py) : Buste, Tete, BrasD/AvBrasD/MainD
-- (et G). Chaque segment tourne autour de son repère d'articulation invisible (« Nom_Groupe_Pivot » :
-- hanches, cou, épaule, coude, poignet). Les poses clés viennent de Partage › PosesNains (généré et vérifié
-- dans Blender : rien ne traverse le corps). Ici on enchaîne ces poses avec des courbes naturelles :
--   • au repos : respiration, léger balancement, la tête suit le joueur proche ;
--   • de temps en temps (intervalle irrégulier) : l'action du nain (boire, forger, lire, examiner).
-- Les formules de rotation sont exactement celles de transformes() dans blender/nains.py.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local POSES = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("PosesNains"))

local DISTANCE_ANIMATION = 110 -- au-delà, on ne calcule rien
local DISTANCE_REGARD = 26
local REGARD_MAX = 0.45 -- rad : barbes et tresses longues, petit mouvement de tête
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local STRIKE_INTERVAL = 1.2
local HAMMER_SOUND_ID = "rbxassetid://9125361455"
local SOUND_VOLUME = 0.35
local SOUND_MAX_DISTANCE = 60
local SOUND_PITCH_VARIATION = 0.05
-- Poses de la main qui garde le marteau attaché au même poignet. À l'impact,
-- une face de la tête vise le centre de la table plutôt que son centre de masse.
local BROM_POSES_ENCLUME = {
	frappe = {D = {1.80766, 0.67317, 0.40794, 0, -0.17834, 0.36196, 0.36427}, tete = {-0.2, 0}, buste = -0.1},
	garde = {D = {1.98, 0.67069, 0.24935, 0, -0.07806, 0.08, 0.35339}, tete = {-0.2, 0}, buste = -0.1},
	leve = {D = {2.5, 0.75052, -0.05569, 0.03253, 0.19932, -0.55, 0.30985}, tete = {-0.1, 0}, buste = -0.1},
}

local joueur = Players.LocalPlayer
local GROUPES_MOBILES = {"Buste", "Tete", "BrasD", "AvBrasD", "MainD", "BrasG", "AvBrasG", "MainG"}

-- ================= Courbes de mouvement =================
local COURBES = {
	douce = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end, -- départ et arrivée en douceur
	sortie = function(t) return 1 - (1 - t) ^ 2.4 end, -- part vite, ralentit (lever le marteau)
	entree = function(t) return t ^ 2.2 end, -- accélère jusqu'au bout (frappe)
}

-- ================= Actions =================
-- Étape : {pose, durée pour l'atteindre (s), courbe, pause après (s), événement à l'arrivée}
local function etape(pose, duree, courbe, pause, evenement)
	return {pose = pose, duree = duree, courbe = courbe or "douce", pause = pause or 0, evenement = evenement}
end

local ACTIONS = {
	Brom = { -- coups réguliers, puis une courte pause entre deux séries
		intervalle = {0.15, 0.3},
		suite = function(rng: Random)
			local s = {}
			local k = STRIKE_INTERVAL / 1.2
			for _ = 1, rng:NextInteger(4, 6) do
				table.insert(s, etape("leve", 0.46 * k, "sortie", 0.08 * k))
				table.insert(s, etape("frappe", 0.14 * k, "entree", 0.06 * k, "impact"))
				table.insert(s, etape("garde", 0.28 * k, "sortie", 0.18 * k))
			end
			table.insert(s, etape("garde", 0.1, "douce", 0.35 + rng:NextNumber(0, 0.2)))
			return s
		end,
	},
	Margot = { -- boit dans sa chope : une ou deux gorgées, la tête bascule, puis elle repose la chope
		intervalle = {7, 14},
		suite = function(rng: Random)
			local s = {etape("approche", 0.75), etape("boire", 0.6, "douce", 0.2),
				etape("gorgee", 0.55, "douce", 0.5 + rng:NextNumber(0, 0.6))}
			if rng:NextNumber() < 0.35 then
				table.insert(s, etape("boire", 0.35, "douce", 0.2))
				table.insert(s, etape("gorgee", 0.45, "douce", 0.4 + rng:NextNumber(0, 0.3)))
			end
			table.insert(s, etape("boire", 0.4, "douce", 0.15))
			table.insert(s, etape("approche", 0.6, "douce", 0.1))
			table.insert(s, etape("repos", 0.75))
			return s
		end,
	},
	Gaspard = { -- consulte son registre, parcourt la page des yeux, puis le range
		intervalle = {9, 16},
		suite = function(rng: Random)
			return {
				etape("leve_livre", 0.85), etape("lire", 0.6, "douce", 1.2 + rng:NextNumber(0, 0.8)),
				etape("lire2", 1.1, "douce", 0.8 + rng:NextNumber(0, 0.7)), etape("lire", 0.9, "douce", 0.6),
				etape("leve_livre", 0.7), etape("repos", 0.85),
			}
		end,
	},
	Liesel = { -- soulève sa pioche, examine le tranchant sous plusieurs angles, puis la repose au sol
		intervalle = {8, 15},
		suite = function(rng: Random)
			return {
				etape("leve_pioche", 0.75), etape("examiner", 0.6, "douce", 0.5 + rng:NextNumber(0, 0.3)),
				etape("examiner_g", 0.8, "douce", 0.4 + rng:NextNumber(0, 0.3)),
				etape("examiner_d", 1.0, "douce", 0.4 + rng:NextNumber(0, 0.3)),
				etape("examiner", 0.6, "douce", 0.3), etape("leve_pioche", 0.6), etape("repos", 0.7),
			}
		end,
	},
}

-- ================= Poses =================
type Pose = {D: {number}, G: {number}, tete: {number}, buste: number}

local function bras(v: {number}?): {number}
	local r = {0, 0, 0, 0, 0, 0, 0}
	for i, a in v or {} do
		r[i] = a
	end
	return r
end

local function lirePose(nom: string, nomPose: string): Pose
	local p = if nom == "Brom" and BROM_POSES_ENCLUME[nomPose]
		then BROM_POSES_ENCLUME[nomPose] else (POSES[nom] or {})[nomPose] or {}
	return {D = bras(p.D), G = bras(p.G), tete = {(p.tete or {})[1] or 0, (p.tete or {})[2] or 0}, buste = p.buste or 0}
end

local function melanger(a: Pose, b: Pose, t: number): Pose
	local res = {D = {}, G = {}, tete = {}, buste = a.buste + (b.buste - a.buste) * t}
	for i = 1, 7 do
		res.D[i] = a.D[i] + (b.D[i] - a.D[i]) * t
		res.G[i] = a.G[i] + (b.G[i] - a.G[i]) * t
	end
	res.tete[1] = a.tete[1] + (b.tete[1] - a.tete[1]) * t
	res.tete[2] = a.tete[2] + (b.tete[2] - a.tete[2]) * t
	return res
end

-- ================= Nains suivis =================
local nains = {}

local function pivotDe(modele: Model, groupe: string): Vector3?
	local g = modele:FindFirstChild(groupe)
	local p = g and g:FindFirstChild(modele.Name .. "_" .. groupe .. "_Pivot")
	return p and (p :: BasePart).Position
end

local function etincelles(modele: Model): ((Vector3) -> ())?
	local support = Instance.new("Part")
	support.Name = "Etincelles"
	support.Anchored, support.CanCollide, support.CanQuery, support.CanTouch = true, false, false, false
	support.Transparency = 1
	support.Size = Vector3.new(0.2, 0.2, 0.2)
	support.CFrame = modele:GetPivot()
	support.Parent = modele
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.25, 0.55)
	e.Speed = NumberRange.new(7, 15)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -45, 0)
	e.Drag = 2
	e.LightEmission = 1
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0)})
	e.Color = ColorSequence.new(Color3.fromRGB(255, 236, 160), Color3.fromRGB(255, 110, 30))
	e.Parent = support
	local lumiere = Instance.new("PointLight")
	lumiere.Color = Color3.fromRGB(255, 150, 60)
	lumiere.Range = 9
	lumiere.Brightness = 0
	lumiere.Parent = support
	return function(position: Vector3)
		support.CFrame = CFrame.new(position)
		e:Emit(math.random(14, 22))
		lumiere.Brightness = 4
		task.delay(0.07, function() lumiere.Brightness = 2 end)
		task.delay(0.16, function() lumiere.Brightness = 0 end)
	end
end

-- Épée et son sont locaux : chaque spectateur entend le coup au même moment
-- que l'animation qu'il voit, sans diffuser de sons à tout le serveur.
local function grandeEnclume(modele: Model): BasePart?
	local forge = modele.Parent and modele.Parent:FindFirstChild("Forge")
	local tableForge = forge and forge:FindFirstChild("Table")
	return if tableForge and tableForge:IsA("BasePart") then tableForge else nil
end

local function jouerImpact(info)
	local enclume = grandeEnclume(info.modele)
	if not enclume then return end
	local point = (enclume.CFrame * CFrame.new(0, enclume.Size.Y / 2 + 0.12, 0)).Position
	if info.etincelles then info.etincelles(point) end
	if HAMMER_SOUND_ID == "" then return end
	local son = enclume:FindFirstChild("Forge_ImpactMarteau")
	if not (son and son:IsA("Sound")) then
		son = Instance.new("Sound")
		son.Name = "Forge_ImpactMarteau"
		son.SoundId = HAMMER_SOUND_ID
		son.RollOffMode = Enum.RollOffMode.InverseTapered
		son.RollOffMaxDistance = SOUND_MAX_DISTANCE
		son.Parent = enclume
	end
	son.PlaybackSpeed = info.rng:NextNumber(1 - SOUND_PITCH_VARIATION, 1 + SOUND_PITCH_VARIATION)
	son.Volume = SOUND_VOLUME * info.rng:NextNumber(0.93, 1.07)
	son:Play()
end

local function suivre(modele: Model)
	if nains[modele] or not modele:IsA("Model") or not modele:GetAttribute("Squelette") then
		return
	end
	local action = ACTIONS[modele.Name]
	if not action or not POSES[modele.Name] then
		return
	end
	task.spawn(function()
		for _, g in {"Tete", "Buste", "BrasD", "AvBrasD", "MainD", "BrasG", "AvBrasG", "MainG"} do
			if not modele:WaitForChild(g, 15) then
				return
			end
		end
		task.wait(0.5) -- laisse arriver toutes les pièces
		local info = {
			modele = modele,
			R = modele:GetPivot().Rotation,
			groupes = {},
			pivots = {},
			rng = Random.new(),
			pose = lirePose(modele.Name, "repos"),
			suite = nil,
			indice = 0,
			depart = nil,
			t = 0,
			pause = 0,
			attente = 0,
			phase = math.random() * 10,
			regard = 0,
			etincelles = nil,
		}
		info.Rinv = info.R:Inverse()
		info.attente = info.rng:NextNumber(1.5, action.intervalle[2])
		for _, g in GROUPES_MOBILES do
			local pieces = {}
			for _, p in modele[g]:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(pieces, {p, p.CFrame})
				end
			end
			info.groupes[g] = pieces
		end
		info.pivots = {
			hanches = pivotDe(modele, "Buste"), cou = pivotDe(modele, "Tete"),
			epauleD = pivotDe(modele, "BrasD"), coudeD = pivotDe(modele, "AvBrasD"), poignetD = pivotDe(modele, "MainD"),
			epauleG = pivotDe(modele, "BrasG"), coudeG = pivotDe(modele, "AvBrasG"), poignetG = pivotDe(modele, "MainG"),
		}
		for _, v in info.pivots do
			if not v then
				warn("[AnimationsNains] Repères d'articulation incomplets pour " .. modele.Name)
				return
			end
		end
		if modele.Name == "Brom" then
			info.etincelles = etincelles(modele)
		end
		nains[modele] = info
	end)
end

CollectionService:GetInstanceAddedSignal("PNJ"):Connect(suivre)
CollectionService:GetInstanceRemovedSignal("PNJ"):Connect(function(m) nains[m] = nil end)
for _, m in CollectionService:GetTagged("PNJ") do
	suivre(m)
end

-- ================= Calcul des transformations =================
local function autour(info, P: Vector3, rot: CFrame): CFrame
	-- rotation « rot » exprimée dans le repère du nain (x droite, y haut, -z devant), centrée sur P
	return CFrame.new(P) * info.R * rot * info.Rinv * CFrame.new(-P)
end

local function poserSegments(info, pose: Pose, souffle: number, lacetRegard: number)
	local pv = info.pivots
	local Tb = CFrame.new(0, souffle, 0) * autour(info, pv.hanches, CFrame.Angles(pose.buste, 0, 0))
	local T = {
		Buste = Tb,
		Tete = Tb * autour(info, pv.cou, CFrame.Angles(0, pose.tete[2] + lacetRegard, 0) * CFrame.Angles(pose.tete[1], 0, 0)),
	}
	for _, cote in {"D", "G"} do
		local a = pose[cote]
		local Tbr = Tb * autour(info, pv["epaule" .. cote], CFrame.Angles(0, 0, a[3]) * CFrame.Angles(0, a[2], 0) * CFrame.Angles(a[1], 0, 0))
		local Tav = Tbr * autour(info, pv["coude" .. cote], CFrame.Angles(a[4], 0, 0) * CFrame.Angles(0, a[5], 0))
		T["Bras" .. cote] = Tbr
		T["AvBras" .. cote] = Tav
		T["Main" .. cote] = Tav * autour(info, pv["poignet" .. cote], CFrame.Angles(a[6], 0, 0) * CFrame.Angles(0, 0, a[7]))
	end
	for g, pieces in info.groupes do
		local M = T[g]
		for _, pc in pieces do
			pc[1].CFrame = M * pc[2]
		end
	end
end

-- ================= Boucle =================
local function avancerAction(info, dt: number)
	local action = ACTIONS[info.modele.Name]
	if not info.suite then
		info.attente -= dt
		if info.attente <= 0 then
			info.suite = action.suite(info.rng)
			info.indice = 1
			info.depart = info.pose
			info.t, info.pause = 0, 0
		end
		return
	end
	local e = info.suite[info.indice]
	if info.t < e.duree then
		info.t = math.min(info.t + dt, e.duree)
		local a = COURBES[e.courbe](info.t / e.duree)
		info.pose = melanger(info.depart, lirePose(info.modele.Name, e.pose), a)
		if info.t >= e.duree and e.evenement == "impact" then
			jouerImpact(info)
		end
		return
	end
	info.pause += dt
	if info.pause >= e.pause then
		info.indice += 1
		info.depart = info.pose
		info.t, info.pause = 0, 0
		if info.indice > #info.suite then
			info.suite = nil
			local iv = action.intervalle
			info.attente = info.rng:NextNumber(iv[1], iv[2])
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local horloge = os.clock()
	local cinematique = joueur:GetAttribute("ForgeCinematique") == true
	for modele, info in nains do
		if not modele.Parent then
			nains[modele] = nil
			continue
		end
		-- cinématique de forge : Brom figé au repos (ForgeCinematique.client le clone puis le cache)
		if cinematique and modele.Name == "Brom" then
			if not info.fige then
				info.fige = true
				info.suite, info.regard = nil, 0
				info.pose = lirePose("Brom", "repos")
				poserSegments(info, info.pose, 0, 0)
			end
			continue
		end
		info.fige = nil
		if camera and (camera.CFrame.Position - info.pivots.cou).Magnitude > DISTANCE_ANIMATION then
			continue
		end
		avancerAction(info, dt)
		-- respiration (~15 par minute) et regard vers le joueur proche, atténué pendant les actions
		local souffle = math.sin(horloge * 1.6 + info.phase) * 0.035
		local cible = 0
		if racine and not info.suite then
			local rel = (CFrame.new(info.pivots.cou) * info.R):PointToObjectSpace(racine.Position)
			if rel.Magnitude < DISTANCE_REGARD and rel.Z < 2 then
				cible = math.clamp(math.atan2(-rel.X, -rel.Z), -REGARD_MAX, REGARD_MAX)
			end
		end
		info.regard += (cible - info.regard) * math.min(1, dt * 3)
		local pose = info.pose
		if not info.suite then -- léger balancement au repos
			pose = table.clone(pose)
			pose.buste = pose.buste + math.sin(horloge * 0.8 + info.phase * 2) * 0.012
		end
		poserSegments(info, pose, souffle, info.regard)
	end
end)
