-- Vie des grottes · SCRIPT CLIENT
-- Anime localement le décor posé par le serveur dans workspace.Grottes (tags CollectionService) :
-- méduses de spores qui flottent, poissons qui tournent, néons qui pulsent, papillons de nuit autour
-- des lanternes, et gouttes d'eau sonores tant que le personnage est sous terre.
-- Une seule boucle par frame ; seuls les objets proches de la caméra (tri toutes les 0,5 s) sont animés.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local joueur = Players.LocalPlayer
local alea = Random.new()

local TAU = math.pi * 2
local PORTEE = 160
local INCLINAISON = math.rad(6)
local FRETILLEMENT = math.rad(10)
local BATTEMENT = math.rad(55)
local COULEUR_AILE = Color3.fromRGB(150, 255, 235)
local SON_GOUTTE = "rbxasset://sounds/impact_water.mp3"

local meduses = {} -- [Model] = données
local poissons = {} -- [Model] = données
local lanternes = {} -- [BasePart] = {papillons, actif}
local pulses = setmetatable({}, {__mode = "k"}) -- [BasePart] = {t0, tween, actif}

local dossierPapillons: Folder? = nil

local function phase(o: Instance): number
	local p = o:GetAttribute("Phase")
	return if typeof(p) == "number" then p else alea:NextNumber(0, TAU)
end

local function vecteur(o: Instance, nom: string, defaut: Vector3): Vector3
	local v = o:GetAttribute(nom)
	return if typeof(v) == "Vector3" then v else defaut
end

local function nombre(o: Instance, nom: string, defaut: number): number
	local v = o:GetAttribute(nom)
	return if typeof(v) == "number" and v == v then v else defaut
end

local function signe(): number
	return if alea:NextNumber() < 0.5 then -1 else 1
end

-- Méduses

local function ajouterMeduse(m: Instance)
	if not m:IsA("Model") or meduses[m] then
		return
	end
	local base = m:GetPivot()
	meduses[m] = {
		origine = vecteur(m, "Origine", base.Position),
		rotation = base.Rotation,
		phase = phase(m),
		flottement = TAU / alea:NextNumber(5, 7),
		derive = TAU / alea:NextNumber(22, 28),
		tour = alea:NextNumber(0.08, 0.2) * signe(),
		actif = false,
	}
end

local function animerMeduse(m: Model, d, t: number)
	local p = d.phase
	local a = t * d.derive + p
	local pos = d.origine + Vector3.new(math.cos(a) * 3, math.sin(t * d.flottement + p) * 1.2, math.sin(a) * 3)
	m:PivotTo(CFrame.new(pos) * d.rotation * CFrame.Angles(0, t * d.tour + p, 0)
		* CFrame.Angles(math.sin(t * 0.9 + p) * INCLINAISON, 0, math.cos(t * 0.7 + p) * INCLINAISON))
end

-- Poissons

local function ajouterPoisson(m: Instance)
	if not m:IsA("Model") or poissons[m] then
		return
	end
	local vitesse = nombre(m, "Vitesse", 0.4)
	poissons[m] = {
		centre = vecteur(m, "Centre", m:GetPivot().Position),
		rayon = nombre(m, "Rayon", 6),
		vitesse = if vitesse ~= 0 then vitesse else 0.4,
		phase = phase(m),
		actif = false,
	}
end

local function trajetPoisson(d, a: number): Vector3
	local r = d.rayon * (1 + 0.2 * math.sin(a * 0.5 + d.phase))
	return d.centre + Vector3.new(math.cos(a) * r, math.sin(a * 3 + d.phase) * 0.3, math.sin(a) * r * 0.75)
end

local function animerPoisson(m: Model, d, t: number)
	local a = t * d.vitesse + d.phase
	local pos = trajetPoisson(d, a)
	local dir = trajetPoisson(d, a + 0.05 * math.sign(d.vitesse)) - pos
	if dir.Magnitude < 1e-4 then
		return
	end
	m:PivotTo(CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.sin(t * 11 + d.phase) * FRETILLEMENT, 0))
end

-- Néons qui pulsent

local function ajouterPulse(p: Instance)
	if not p:IsA("BasePart") or pulses[p] then
		return
	end
	local etat = {t0 = p.Transparency, tween = nil :: Tween?, actif = false}
	pulses[p] = etat
	task.delay(alea:NextNumber(0, 3), function()
		if pulses[p] ~= etat or not p.Parent then
			return
		end
		local info = TweenInfo.new(alea:NextNumber(1.8, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tw = TweenService:Create(p, info, {Transparency = math.min(etat.t0 + 0.35, 0.9)})
		etat.tween = tw
		if etat.actif then
			tw:Play()
		end
	end)
end

local function retirerPulse(p: Instance)
	local etat = pulses[p]
	if not etat then
		return
	end
	pulses[p] = nil
	if etat.tween then
		etat.tween:Cancel()
	end
	if p.Parent then
		(p :: BasePart).Transparency = etat.t0
	end
end

-- Papillons de nuit autour des lanternes

local function aile(cf: CFrame): Part
	if not dossierPapillons or not dossierPapillons.Parent then
		local f = workspace:FindFirstChild("PapillonsGrotte")
		if not (f and f:IsA("Folder")) then
			f = Instance.new("Folder")
			f.Name = "PapillonsGrotte"
			f.Parent = workspace
		end
		dossierPapillons = f :: Folder
	end
	local p = Instance.new("Part")
	p.Name = "Aile"
	p.Size = Vector3.new(0.5, 0.05, 0.35)
	p.Material = Enum.Material.Neon
	p.Color = COULEUR_AILE
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cf
	p.Parent = dossierPapillons
	return p
end

local function ajouterLanterne(l: Instance)
	if not l:IsA("BasePart") or lanternes[l] then
		return
	end
	local liste = {}
	for _ = 1, alea:NextInteger(2, 3) do
		table.insert(liste, {
			gauche = aile(l.CFrame),
			droite = aile(l.CFrame),
			rayon = alea:NextNumber(1.5, 3.5),
			hauteur = alea:NextNumber(0.5, 1.05),
			vitesse = alea:NextNumber(1.2, 2.4) * signe(),
			irregulier = alea:NextNumber(1.3, 2.1),
			battement = alea:NextNumber(22, 32),
			phase = alea:NextNumber(0, TAU),
		})
	end
	lanternes[l] = {papillons = liste, actif = false}
end

local function retirerLanterne(l: Instance)
	local d = lanternes[l]
	if not d then
		return
	end
	lanternes[l] = nil
	for _, b in d.papillons do
		b.gauche:Destroy()
		b.droite:Destroy()
	end
end

local function trajetPapillon(c: Vector3, b, a: number): Vector3
	local r = b.rayon * (1 + 0.3 * math.sin(a * b.irregulier + b.phase))
	local y = math.sin(a * b.irregulier * 0.7 + b.phase) * b.hauteur + math.sin(a * 5) * 0.15
	return c + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
end

-- Tri par distance (toutes les 0,5 s)

local function grottesPresentes(): boolean
	local d = workspace:FindFirstChild("Grottes")
	return d ~= nil and #d:GetChildren() > 0
end

local function trier()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local c = camera.CFrame.Position
	for m, d in meduses do
		if not m.Parent then
			meduses[m] = nil
		else
			d.actif = (d.origine - c).Magnitude < PORTEE
		end
	end
	for m, d in poissons do
		if not m.Parent then
			poissons[m] = nil
		else
			d.actif = (d.centre - c).Magnitude < PORTEE
		end
	end
	for l, d in lanternes do
		if not l.Parent then
			retirerLanterne(l)
		else
			d.actif = (l.Position - c).Magnitude < PORTEE
		end
	end
	for p, etat in pulses do
		if not p.Parent then
			retirerPulse(p)
		else
			local proche = (p.Position - c).Magnitude < PORTEE
			if proche ~= etat.actif then
				etat.actif = proche
				if etat.tween then
					if proche then
						etat.tween:Play()
					else
						etat.tween:Pause()
					end
				end
			end
		end
	end
end

local function suivre(tag: string, ajouter: (Instance) -> (), retirer: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(ajouter)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(retirer)
	for _, o in CollectionService:GetTagged(tag) do
		ajouter(o)
	end
end

suivre("GrotteMeduse", ajouterMeduse, function(m)
	meduses[m] = nil
end)
suivre("GrottePoisson", ajouterPoisson, function(m)
	poissons[m] = nil
end)
suivre("GrottePulse", ajouterPulse, retirerPulse)
suivre("GrotteLanterne", ajouterLanterne, retirerLanterne)

-- Boucle d'animation unique

local cumul = math.huge
local grottesLa = false
local ailes: {BasePart} = {}
local reperes: {CFrame} = {}

RunService.RenderStepped:Connect(function(dt)
	cumul += dt
	if cumul >= 0.5 then
		cumul = 0
		grottesLa = grottesPresentes()
		if grottesLa then
			trier()
		end
	end
	if not grottesLa then
		return
	end
	local t = os.clock()
	for m, d in meduses do
		if d.actif and m.Parent then
			animerMeduse(m, d, t)
		end
	end
	for m, d in poissons do
		if d.actif and m.Parent then
			animerPoisson(m, d, t)
		end
	end
	table.clear(ailes)
	table.clear(reperes)
	for l, d in lanternes do
		if d.actif and l.Parent then
			local c = l.Position
			for _, b in d.papillons do
				local a = t * b.vitesse + b.phase
				local pos = trajetPapillon(c, b, a)
				local dir = trajetPapillon(c, b, a + 0.05 * math.sign(b.vitesse)) - pos
				if dir.Magnitude > 1e-4 then
					local corps = CFrame.lookAt(pos, pos + dir)
					local f = math.sin(t * b.battement + b.phase) * BATTEMENT
					table.insert(ailes, b.gauche)
					table.insert(reperes, corps * CFrame.Angles(0, 0, -f) * CFrame.new(-0.25, 0, 0))
					table.insert(ailes, b.droite)
					table.insert(reperes, corps * CFrame.Angles(0, 0, f) * CFrame.new(0.25, 0, 0))
				end
			end
		end
	end
	if #ailes > 0 then
		workspace:BulkMoveTo(ailes, reperes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

-- Gouttes d'eau sonores

local function dansUneGrotte(pos: Vector3): boolean
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then
		return false
	end
	for _, g in dossier:GetChildren() do
		local c, d = g:GetAttribute("Centre"), g:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return true
			end
		end
	end
	return false
end

local function goutte(autour: Vector3)
	local angle = alea:NextNumber(0, TAU)
	local distance = alea:NextNumber(8, 30)
	local p = Instance.new("Part")
	p.Name = "Goutte"
	p.Size = Vector3.one * 0.2
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = CFrame.new(autour + Vector3.new(math.cos(angle) * distance, alea:NextNumber(4, 12), math.sin(angle) * distance))
	local s = Instance.new("Sound")
	s.SoundId = SON_GOUTTE
	s.RollOffMinDistance = 5
	s.RollOffMaxDistance = 60
	if alea:NextInteger(1, 6) == 1 then
		s.Volume = 0.2
		s.PlaybackSpeed = alea:NextNumber(0.9, 1.2)
	else
		s.Volume = alea:NextNumber(0.12, 0.25)
		s.PlaybackSpeed = alea:NextNumber(1.6, 2.6)
	end
	s.Parent = p
	p.Parent = workspace
	s:Play()
	Debris:AddItem(p, 4)
end

while true do
	task.wait(alea:NextNumber(1.5, 5))
	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	if racine and dansUneGrotte(racine.Position) then
		goutte(racine.Position)
	end
end
