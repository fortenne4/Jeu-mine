-- Pioches · SCRIPT SERVEUR (l'outil que tient le joueur)
-- Où : ServerScriptService > Jeu
-- Va avec le SCRIPT CLIENT PiocheBraise.client (secousse de caméra et petit flash à l'impact).
--
-- Ce qu'il fait :
--  • donne au joueur la pioche choisie dans la boutique de Liesel (attribut « Pioche » du joueur) :
--    modèle 3D de l'Atelier (PiochesModeles) et l'aura réglée dans l'Atelier (AuraPioche) ;
--  • la frappe : relais CoupPioche (geste du corps animé par PiocheAnimation.client), onde de choc et
--    étincelles aux couleurs de la pioche ;
--  • minerais (tag "Minerai", attribut "PV") : ils se fissurent à chaque coup puis éclatent.
--    Le BindableEvent ServerStorage.MineraiCasse prévient Minerais.server.lua (récompenses).
--  • clic maintenu = minage continu ; une série sans pause accélère les coups (jusqu'à +30 %) ;
--    un minerai cassé d'une seule série donne un éclat parfait (+1 minerai). Affichage : ComboMinage.client.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Catalogue des pioches (boutique de Liesel) : puissance, recharge et couleurs de chaque pioche
local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
-- Aura de l'Atelier 3D (style, couleurs, intensité réglés pour chaque pioche dans Partage › AurasPioches)
local AurasPioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("AurasPioches"))
local AuraPioche = require(script.Parent:WaitForChild("AuraPioche"))
-- Modèles 3D Blender des pioches
local PiochesModeles = require(script.Parent:WaitForChild("PiochesModeles"))
-- Mines privées : creusage des blocs (tag "BlocMine") dans la mine du joueur uniquement
local MinePrivee = require(ServerStorage:WaitForChild("Monde"):WaitForChild("MinePrivee"))
-- Sac du joueur : les minerais extraits de la mine privée y vont (vendus ensuite au marchand)
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local CONFIG = {
	DEGATS_COUP = 12, -- dégâts directs du coup (PNJ hostiles)
	PORTEE = 5, -- studs devant le joueur
	PVP = false, -- true = la pioche touche aussi les autres joueurs
	DEGATS_MINERAI = 1, -- PV retirés à un minerai par coup (multiplié par la puissance de la pioche)
	TAG_MINERAI = "Minerai",
	-- Clic maintenu = minage continu. Série de coups sans pause : la cadence accélère à chaque coup.
	ACCEL_PAR_COUP = 0.035, -- +3,5 % de vitesse par coup enchaîné…
	ACCEL_MAX = 0.3, -- …jusqu'à +30 % (la cadence reste bornée par le verrou de 0,35 s du geste)
	PAUSE_SERIE = 0.3, -- secondes de pause tolérées (au-delà de la recharge) avant que la série retombe
	-- Éclat parfait : minerai cassé d'une seule série (commencée sur le minerai intact, sans viser ailleurs)
	BONUS_ECLAT = 1, -- minerai(s) en plus dans le sac
	COUPS_MIN_ECLAT = 3, -- le minerai doit demander au moins 3 coups (pas de bonus sur ceux cassés d'un coup)
}

-- Sons intégrés à Roblox. Remplace-les par tes propres ID (rbxassetid://...) si tu veux.
local SONS = {
	EQUIPER = "rbxassetid://9119742466", -- Sword Draw Clang Unsheathing 1 : on dégaine la pioche
	-- Sons de la bibliothèque Pro Sound Effects (offerte par Roblox : marchent chez tous les collaborateurs)
	ELAN = "rbxassetid://9120972444", -- Wood Whoosh Quick Swings 1 : la pioche fend l'air
	PIERRE = "rbxassetid://9117841516", -- Pop Airy 2 : pierre, charbon, roche de la mine privée
	METAL = "rbxassetid://9116652350", -- Metal Hits 14 : minerais métalliques
	ECLAT = "rbxassetid://9118587701", -- Rock Drop On Concrete Breaks 4 : le minerai éclate
}
-- Minerais qui sonnent comme du métal à l'impact (les autres sonnent comme de la pierre)
local MINERAIS_METAL = {Bronze = true, Fer = true, Gold = true}
-- Éclat de tout minerai cassé : « Cloche d'or » + « Pièce légère » (banc d'écoute V7).
-- {id, volume, hauteur, délai en secondes}
local ECLAT_MINERAI = {
	{"rbxassetid://9118587698", 0.44, 1, 0}, -- Rock Drop On Concrete Breaks 3 : la roche cède
	{"rbxassetid://9119448154", 0.3, 1.1, 0.06}, -- Sparkle Bell Tree Wind Chimes 2 : clochettes
	{"rbxassetid://9126073026", 0.35, 1, 0.1}, -- Synth Sparkle Bell Tone Ding : ding
	{"rbxassetid://1169755927", 0.3, 1.2, 0.14}, -- Coin Collect (Everyedit, libre d'utilisation) : pièce
}

-- Endroit du manche tenu par la main (0 = milieu du manche, -2.2 = bout du manche).
-- -1.0 : la main tient le manche assez haut. Si la pioche est mal orientée, ajuste ici.
local GRIP = CFrame.new(0, -1.0, 0)

local BLANC = Color3.new(1, 1, 1)
local POUSSIERE = Color3.fromRGB(120, 108, 96)
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"

-- Le serveur prévient les clients (secousse, flash). Les clients n'envoient jamais rien.
local fxEvent = Instance.new("RemoteEvent")
fxEvent.Name = "PiocheFX"
fxEvent.Parent = ReplicatedStorage

-- Coup accepté : chaque client anime le corps du mineur (PiocheAnimation.client)
local coupEvent = Instance.new("RemoteEvent")
coupEvent.Name = "CoupPioche"
coupEvent.Parent = ReplicatedStorage

-- Combo de minage (ComboMinage.client) : vitesse de la série, solidité du minerai frappé, éclat parfait
local comboEvent = Instance.new("RemoteEvent")
comboEvent.Name = "ComboMinage"
comboEvent.Parent = ReplicatedStorage

-- Point visé par le viseur du client (ViseurPioche.client) : seule exception au « clients muets ».
-- Un Vector3 par coup, limité en cadence, validé ici (type, distance) puis utilisé pour creuser.
local viseEvent = Instance.new("RemoteEvent")
viseEvent.Name = "VisePioche"
viseEvent.Parent = ReplicatedStorage
local VISEE_PORTEE = 8 -- studs max entre la tête et le point visé
local visees: {[Player]: {point: Vector3, t: number}} = {}
viseEvent.OnServerEvent:Connect(function(joueur, point)
	if typeof(point) ~= "Vector3" or point ~= point then return end
	local precedente = visees[joueur]
	if precedente and os.clock() - precedente.t < 0.08 then return end
	visees[joueur] = {point = point, t = os.clock()}
end)
Players.PlayerRemoving:Connect(function(joueur) visees[joueur] = nil end)

-- Pour ton propre code (récompenses, inventaire…) : MineraiCasse.Event:Connect(function(joueur, bloc) ... end)
local mineraiCasse = Instance.new("BindableEvent")
mineraiCasse.Name = "MineraiCasse"
mineraiCasse.Parent = ServerStorage

-- ================= Fabriques d'effets =================

local function emetteur(props: {[string]: any}): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	for cle, valeur in props do
		(e :: any)[cle] = valeur
	end
	return e
end

local function etincelles(couleur: Color3): ParticleEmitter
	return emetteur({
		Name = "Etincelles",
		Texture = TEX_ETINCELLE,
		Color = ColorSequence.new(BLANC, couleur),
		Size = NumberSequence.new(0.16, 0),
		Lifetime = NumberRange.new(0.4, 0.9),
		Rate = 0,
		Speed = NumberRange.new(8, 18),
		SpreadAngle = Vector2.new(75, 75),
		Acceleration = Vector3.new(0, -25, 0),
	})
end

local function poussiere(couleur: Color3): ParticleEmitter
	return emetteur({
		Name = "Poussiere",
		Texture = TEX_FUMEE,
		LightEmission = 0,
		Color = ColorSequence.new(couleur),
		Size = NumberSequence.new(0.6, 2.2),
		Transparency = NumberSequence.new(0.45, 1),
		Lifetime = NumberRange.new(0.6, 1.1),
		Rate = 0,
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(80, 80),
		Acceleration = Vector3.new(0, 1, 0),
		RotSpeed = NumberRange.new(-40, 40),
	})
end

local function son(parent: Instance, id: string, volume: number, vitesse: number?)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = vitesse or 1
	s.RollOffMaxDistance = 90
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 4)
end

-- Pièce d'effet ancrée, sans collision, invisible aux détections
local function effetPart(props: {[string]: any}): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for cle, valeur in props do
		(p :: any)[cle] = valeur
	end
	p.Parent = workspace
	return p
end

-- Point invisible où accrocher des particules
local function ancre(position: Vector3, duree: number): Part
	local p = effetPart({Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), Position = position})
	Debris:AddItem(p, duree)
	return p
end

-- Son joué à un endroit du monde (survit au minerai qui disparaît), hauteur un peu variée à chaque coup
local function sonIci(position: Vector3, id: string, volume: number)
	son(ancre(position, 4), id, volume, 0.92 + math.random() * 0.16)
end

-- Plusieurs sons superposés au même endroit, chacun avec son volume, sa hauteur et son délai
local function melangeIci(position: Vector3, couches: {{any}})
	local a = ancre(position, 5)
	for _, c in couches do
		task.delay(c[4], function()
			if a.Parent then son(a, c[1], c[2], c[3]) end
		end)
	end
end

local function sol(position: Vector3): Vector3?
	local exclus = {}
	for _, j in Players:GetPlayers() do
		if j.Character then
			table.insert(exclus, j.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclus
	local r = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -15, 0), params)
	return r and r.Position or nil
end

local function onde(position: Vector3, rayon: number, couleur: Color3, duree: number)
	local cf = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	local p = effetPart({Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1, 1), CFrame = cf, Color = couleur, Transparency = 0.2})
	TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.12, rayon * 2, rayon * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, duree + 0.1)
end

-- Impact : onde de choc, étincelles et poussière aux couleurs de la pioche
local function impact(position: Vector3, force: number, couleur: Color3)
	onde(position, 2.5 + 1.5 * force, couleur, 0.3 + 0.1 * force)
	local a = ancre(position, 2)
	local att = Instance.new("Attachment")
	att.Parent = a
	local e = etincelles(couleur)
	e.Parent = att
	e:Emit(math.floor(18 * force))
	local d = poussiere(POUSSIERE)
	d.Parent = att
	d:Emit(math.floor(4 * force))
	local l = Instance.new("PointLight")
	l.Color = couleur
	l.Brightness = 3 * force
	l.Range = 8 + 4 * force
	l.Parent = a
	TweenService:Create(l, TweenInfo.new(0.3), {Brightness = 0}):Play()
	fxEvent:FireAllClients("impact", position, force, couleur)
end

-- Le minerai éclate en morceaux qui retombent
local function eclats(bloc: BasePart, couleur: Color3)
	local taille = math.max(bloc.Size.X, bloc.Size.Y, bloc.Size.Z)
	for _ = 1, 10 do
		local t = (0.2 + math.random() * 0.3) * math.min(taille, 4)
		local e = Instance.new("Part")
		e.Size = Vector3.new(t, t, t)
		e.CFrame = bloc.CFrame
			* CFrame.new((math.random() - 0.5) * bloc.Size.X, (math.random() - 0.5) * bloc.Size.Y, (math.random() - 0.5) * bloc.Size.Z)
			* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		e.Color = bloc.Color
		e.Material = bloc.Material
		e.CanQuery = false
		e.CanTouch = false
		e.TopSurface = Enum.SurfaceType.Smooth
		e.BottomSurface = Enum.SurfaceType.Smooth
		e.Parent = workspace
		e.AssemblyLinearVelocity = Vector3.new(math.random(-16, 16), math.random(16, 30), math.random(-16, 16))
		e.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
		task.delay(1.2, function()
			if e.Parent then
				TweenService:Create(e, TweenInfo.new(0.5), {Transparency = 1, Size = e.Size * 0.3}):Play()
			end
		end)
		Debris:AddItem(e, 1.8)
	end
	impact(bloc.Position, 1.5, couleur)
end

local function frapperMinerai(bloc: BasePart, joueur: Player?, degats: number, couleur: Color3)
	if not bloc.Parent or not CollectionService:HasTag(bloc, CONFIG.TAG_MINERAI) then return end
	local pvMax = bloc:GetAttribute("PVMax") or bloc:GetAttribute("PV") or 3
	bloc:SetAttribute("PVMax", pvMax)
	local pv = (bloc:GetAttribute("PV") or pvMax) - degats
	bloc:SetAttribute("PV", pv)

	-- Le bloc s'illumine un peu plus à chaque coup (il se fissure)
	local lueur = bloc:FindFirstChild("Fissure")
	if not lueur then
		lueur = Instance.new("Highlight")
		lueur.Name = "Fissure"
		lueur.FillColor = couleur
		lueur.OutlineColor = BLANC
		lueur.DepthMode = Enum.HighlightDepthMode.Occluded
		lueur.Parent = bloc
	end
	local usure = math.clamp(1 - pv / pvMax, 0, 1)
	lueur.FillTransparency = 1 - 0.5 * usure
	lueur.OutlineTransparency = 1 - 0.8 * usure

	if pv <= 0 then
		bloc:SetAttribute("Casse", true) -- lu par MinePrivee (case creusée pour de bon)
		CollectionService:RemoveTag(bloc, CONFIG.TAG_MINERAI)
		eclats(bloc, couleur)
		mineraiCasse:Fire(joueur, bloc)
		bloc.Transparency = 1
		bloc.CanCollide = false
		bloc.CanQuery = false
		lueur:Destroy()
		Debris:AddItem(bloc, 1)
		return true
	end
	return false
end

local function toucherCible(cible: Humanoid, modele: Model, degats: number): boolean
	if cible.Health <= 0 then return false end
	if not CONFIG.PVP and Players:GetPlayerFromCharacter(modele) then return false end
	cible:TakeDamage(degats)
	return true
end

-- ================= L'outil =================

local function creerPioche(def: Pioches.Pioche): Tool
	local tool = Instance.new("Tool")
	tool.Name = def.nom
	tool.ToolTip = def.description
	tool.CanBeDropped = false
	tool.Grip = GRIP
	tool:SetAttribute("PiocheId", def.id)
	tool:SetAttribute("Lueur", def.lueur)
	local COULEUR = def.lueur
	local CLAIR = def.lueur:Lerp(BLANC, 0.6)

	-- Poignée invisible (repère du manche : manche le long de Y, pic vers -Z) qui porte les pièces 3D
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 4.4, 0.35)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.identity
	handle.Parent = tool

	local posPointe, posTalon = Vector3.new(0, 1.7, -2.3), Vector3.new(0, 2.4, -0.4)
	local gabarit = PiochesModeles.gabarit(def.id)
	if gabarit then
		for _, src in gabarit:GetChildren() do
			if src:IsA("BasePart") then
				local c = src:Clone()
				c.CFrame = handle.CFrame * src.CFrame
				c.Anchored = false
				c.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = c
				weld.Parent = c
				c.Parent = tool
			end
		end
		posPointe = gabarit:GetAttribute("Pointe") or posPointe
		posTalon = gabarit:GetAttribute("Talon") or posTalon
	else
		-- pas de modèle : simple manche visible
		handle.Transparency = 0
		handle.Color = def.manche
		handle.Material = Enum.Material.Wood
	end

	-- Traînée pendant la frappe, aux couleurs de la pioche
	local t0 = Instance.new("Attachment")
	t0.Name = "Pointe"
	t0.CFrame = CFrame.new(posPointe)
	t0.Parent = handle
	local t1 = Instance.new("Attachment")
	t1.CFrame = CFrame.new(posTalon)
	t1.Parent = handle
	local trainee = Instance.new("Trail")
	trainee.Name = "TraineePioche"
	trainee.Attachment0 = t0
	trainee.Attachment1 = t1
	trainee.Lifetime = 0.2
	trainee.LightEmission = 1
	trainee.Color = ColorSequence.new(CLAIR, COULEUR)
	trainee.Transparency = NumberSequence.new(0.35, 1)
	trainee.WidthScale = NumberSequence.new(1, 0.3)
	trainee.Enabled = false
	trainee.Parent = handle

	-- Aura réglée dans l'Atelier 3D (Partage › AurasPioches)
	AuraPioche.ajouter(tool, handle, AurasPioches[def.id])

	-- ===== Frappe =====
	local dernierCoup = 0
	local occupe = false
	local serie = 0 -- coups enchaînés sans pause
	local mineraiSerie: BasePart? = nil -- minerai frappé par la série en cours
	local serieIntacte = false -- la série a commencé sur ce minerai encore intact
	tool:SetAttribute("Vitesse", 1) -- lu par PiocheAnimation.client (cadence du geste)

	-- Recharge réelle : celle de la pioche, raccourcie par l'accélération de la série
	local function recharge(): number
		return def.recharge / (tool:GetAttribute("Vitesse") or 1)
	end

	local function coup()
		local perso = tool.Parent
		if not perso or not perso:IsA("Model") then return end
		local humanoid = perso:FindFirstChildOfClass("Humanoid")
		local racine = perso:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not racine then return end
		local maintenant = os.clock()
		if occupe or maintenant - dernierCoup < recharge() then return end
		if maintenant - dernierCoup > recharge() + CONFIG.PAUSE_SERIE then
			serie, mineraiSerie = 0, nil -- pause : la série retombe
		end
		serie += 1
		local vitesse = 1 + math.min(CONFIG.ACCEL_MAX, (serie - 1) * CONFIG.ACCEL_PAR_COUP)
		tool:SetAttribute("Vitesse", vitesse)
		dernierCoup = maintenant
		occupe = true
		local joueurSerie = Players:GetPlayerFromCharacter(perso)
		if joueurSerie then comboEvent:FireClient(joueurSerie, "serie", serie, vitesse) end

		-- Geste animé par les clients (PiocheAnimation) ; traînée allumée par eux pendant la frappe
		coupEvent:FireAllClients(perso)
		son(handle, SONS.ELAN, 0.5, 0.9 + math.random() * 0.2)
		task.delay(0.35, function()
			occupe = false
		end)

		task.wait(0.17)
		if tool.Parent ~= perso then return end

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {perso}
		local zone = racine.CFrame * CFrame.new(0, -0.5, -CONFIG.PORTEE / 2)
		local touches = workspace:GetPartBoundsInBox(zone, Vector3.new(4, 6, CONFIG.PORTEE), params)

		local joueur = Players:GetPlayerFromCharacter(perso)
		-- Visée du client : consommée à chaque coup, valable 0,35 s et à portée de la tête
		local visee = joueur and visees[joueur]
		if joueur then visees[joueur] = nil end
		local tete = perso:FindFirstChild("Head")
		local cible, origine = nil, nil
		if visee and tete and tete:IsA("BasePart") and os.clock() - visee.t < 0.35
			and (visee.point - tete.Position).Magnitude <= VISEE_PORTEE then
			cible, origine = visee.point, tete.Position
		end
		local cibles = {}
		local minerai, distMin = nil, math.huge
		for _, partie in touches do
			local modele = partie:FindFirstAncestorOfClass("Model")
			local cible = modele and modele:FindFirstChildOfClass("Humanoid")
			if cible then
				cibles[cible] = modele
			elseif CollectionService:HasTag(partie, CONFIG.TAG_MINERAI) then
				local d = (partie.Position - racine.Position).Magnitude
				if d < distMin then
					minerai, distMin = partie, d
				end
			end
		end

		-- Mine privée : un nœud ne se frappe que s'il est touché par le rayon serveur tête → point visé
		-- (≤ VISEE_PORTEE, comme le creusage) ; roche visée = on creuse. Mine publique : inchangée.
		local noeudVise = nil
		if cible and origine then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = {perso}
			local trajet = cible - origine
			local hit = if trajet.Magnitude > 0.1 then workspace:Raycast(origine, trajet.Unit * (trajet.Magnitude + 0.6), rp) else nil
			local touche = hit and hit.Instance
			if touche and not CollectionService:HasTag(touche, CONFIG.TAG_MINERAI) then
				-- pièce d'un rocher (facette…) : on remonte à son cœur
				local m = touche.Parent
				local coeur = m and m:IsA("Model") and m.PrimaryPart
				if coeur and CollectionService:HasTag(coeur, CONFIG.TAG_MINERAI) then touche = coeur end
			end
			if touche and CollectionService:HasTag(touche, CONFIG.TAG_MINERAI) and touche:GetAttribute("Proprietaire") then
				noeudVise = touche
			end
		end
		if minerai and minerai:GetAttribute("Proprietaire") then minerai = nil end -- nœud privé : jamais via la zone
		if noeudVise and joueur and (noeudVise:GetAttribute("Proprietaire") == joueur.UserId or noeudVise:GetAttribute("Invite") == joueur.UserId) then
			minerai = noeudVise -- seul le propriétaire de la mine (ou son invité dans une grotte) peut le casser
		end

		local aTouche = minerai ~= nil
		local point = minerai and (minerai.Position + Vector3.new(0, minerai.Size.Y / 2, 0)) or nil
		for cible, modele in cibles do
			if toucherCible(cible, modele, CONFIG.DEGATS_COUP) then
				aTouche = true
				if not point then
					local r = modele:FindFirstChild("HumanoidRootPart")
					point = r and r.Position or nil
				end
			end
		end

		if not minerai then
			mineraiSerie = nil -- on vise ailleurs : l'éclat parfait de ce minerai est perdu
		end

		if not aTouche and joueur and Donnees.profil(joueur) then
			-- Dans sa mine privée : la zone de coup retire quelques blocs de roche exposés (0 gain ; les
			-- nœuds de minerai restent et se cassent comme dans la mine publique)
			local bloc = MinePrivee.creuser(joueur, racine, cible, origine)
			if bloc then
				sonIci(bloc.Position, SONS.PIERRE, 0.62)
				eclats(bloc, COULEUR)
				bloc:Destroy()
				return
			end
		end

		if not aTouche then
			-- Coup dans le vide : quelques étincelles au sol
			local p = sol(racine.Position + racine.CFrame.LookVector * 3)
			if p then
				local a = ancre(p, 1.5)
				local att = Instance.new("Attachment")
				att.Parent = a
				local e = etincelles(COULEUR)
				e.Speed = NumberRange.new(3, 7)
				e.Parent = att
				e:Emit(10)
			end
			return
		end

		impact(point or (racine.Position + racine.CFrame.LookVector * 3), 1, COULEUR)
		if minerai then
			local degats = CONFIG.DEGATS_MINERAI * def.puissance
			local pvMax = minerai:GetAttribute("PVMax") or minerai:GetAttribute("PV") or 3
			local pvAvant = minerai:GetAttribute("PV") or pvMax
			if minerai ~= mineraiSerie then
				mineraiSerie = minerai
				serieIntacte = pvAvant >= pvMax -- la série doit commencer sur le minerai intact
			end
			-- Éclat parfait : cassé d'une seule série, et assez solide pour demander plusieurs coups
			local eclatParfait = serieIntacte and pvAvant - degats <= 0 and pvMax > degats * (CONFIG.COUPS_MIN_ECLAT - 1)
			if eclatParfait then
				minerai:SetAttribute("BonusSerie", CONFIG.BONUS_ECLAT) -- lu par Minerais.server (récompense)
			end
			local position = minerai.Position
			sonIci(position, if MINERAIS_METAL[minerai:GetAttribute("Type")] then SONS.METAL else SONS.PIERRE, 0.75)
			-- Récompense : MineraiCasse → Minerais.server → Donnees.ajouterMinerai (sac)
			local casse = frapperMinerai(minerai, joueur, degats, COULEUR)
			if casse then
				-- tout minerai cassé : roche + clochettes + ding + pièce (banc d'écoute V7)
				melangeIci(position, ECLAT_MINERAI)
				-- le minerai part dans le sac : petit « bloop » joué chez le mineur seulement (ComboMinage.client)
				if joueur then comboEvent:FireClient(joueur, "ramasse") end
			end
			if casse then mineraiSerie = nil end
			if joueur then
				comboEvent:FireClient(joueur, "minerai", math.max(0, pvAvant - degats), pvMax, casse and eclatParfait, position)
			end
		end
	end

	-- Clic maintenu : le serveur enchaîne les coups tant que le bouton reste enfoncé (même validation
	-- qu'un clic : recharge, distance, visée). Relâcher arrête après le coup en cours.
	local tenu = false
	local boucleActive = false
	tool.Activated:Connect(function()
		tenu = true
		if boucleActive then return end
		boucleActive = true
		task.spawn(function()
			while tenu and tool.Parent and tool.Parent:IsA("Model") do
				coup()
				task.wait(0.03)
			end
			boucleActive = false
		end)
	end)
	tool.Deactivated:Connect(function()
		tenu = false
	end)
	tool.Unequipped:Connect(function()
		tenu = false
	end)
	tool.Equipped:Connect(function()
		son(handle, SONS.EQUIPER, 0.5)
	end)
	return tool
end

-- ================= Distribution =================

-- La pioche donnée est celle de l'attribut « Pioche » du joueur (réglé par la boutique de Liesel).
-- Quand il change, l'ancienne pioche est retirée (sac ou main) et la nouvelle prend sa place.
local function piochesDe(joueur: Player): {Tool}
	local res = {}
	for _, conteneur in {joueur:FindFirstChildOfClass("Backpack"), joueur.Character} do
		if conteneur then
			for _, t in conteneur:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("PiocheId") then
					table.insert(res, t)
				end
			end
		end
	end
	return res
end

local function donnerPioche(joueur: Player)
	local sac = joueur:WaitForChild("Backpack")
	local def = Pioches.get(joueur:GetAttribute("Pioche")) or Pioches.get(Pioches.DEPART)
	if not def then return end
	local enMain = false
	for _, t in piochesDe(joueur) do
		if t:GetAttribute("PiocheId") == def.id then
			return -- déjà la bonne
		end
		enMain = enMain or t.Parent == joueur.Character
		t:Destroy()
	end
	local tool = creerPioche(def)
	tool.Parent = sac
	local humanoid = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
	if enMain and humanoid then
		humanoid:EquipTool(tool) -- on l'avait en main : la nouvelle arrive directement en main
	end
end

local function surJoueur(joueur: Player)
	joueur.CharacterAdded:Connect(function()
		donnerPioche(joueur)
	end)
	joueur:GetAttributeChangedSignal("Pioche"):Connect(function()
		if joueur.Character then
			donnerPioche(joueur)
		end
	end)
	if joueur.Character then
		donnerPioche(joueur)
	end
end

Players.PlayerAdded:Connect(surJoueur)
for _, joueur in Players:GetPlayers() do
	surJoueur(joueur)
end
