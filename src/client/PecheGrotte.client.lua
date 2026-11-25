-- Pêche dans les lacs de la grotte −50 m · SCRIPT CLIENT
-- Quand le serveur lance une partie (PecheGrotte.server.lua, RemoteEvent « PecheGrotte ») : le personnage se tourne
-- vers l'eau, arme la canne au-dessus de l'épaule et lance ; la ligne part en arc, le bouchon fait « plouf »
-- (gouttes, ronds dans l'eau) puis flotte… « ÇA MORD ! » : le bouchon plonge par saccades, un « ! » apparaît, une
-- barre s'ouvre et un curseur va et vient : il faut ferrer (clic, Espace, A à la manette, bouton à l'écran) quand il
-- passe dans la zone verte, autant de fois que le poisson l'exige (2 ratés = la ligne casse). La canne plie, la
-- ligne vibre, le poisson se débat. À la prise : le poisson (voxel aux couleurs de l'espèce) jaillit de l'eau,
-- frétille jusqu'au joueur et une carte le présente (rareté, pièces, nouveau au carnet de pêche).
-- Tout est local : canne, bouchon, ligne, particules et ronds sont créés une fois et réutilisés ; les bras sont
-- posés par RigIK (AnimationConstraint) et relâchés à la fin.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")

local Peche = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Peche"))
local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local IK = require(script.Parent:WaitForChild("RigIK"))
local creer, coin, trait, texte = UI.creer, UI.coin, UI.trait, UI.texte
local lisse, sortie, entree = IK.lisse, IK.sortie, IK.entree

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild(Peche.REMOTE) :: RemoteEvent
local terrain = workspace.Terrain

local V = Vector3.new
local HAUT = V(0, 1, 0)
local ACTION = "FerrerPeche"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"

-- ================= Interface =================
local gui = creer("ScreenGui", {Name = "PecheGrotte", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 22,
	Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)

local jeu = creer("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.36, 0.15),
	BackgroundColor3 = Color3.fromRGB(14, 20, 30), BackgroundTransparency = 0.2, Visible = false, Parent = gui},
	{coin(0.15), trait(Color3.fromRGB(90, 200, 255), 2, 0.3), creer("UISizeConstraint", {MinSize = Vector2.new(300, 110), MaxSize = Vector2.new(560, 150)})})
local consigne = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(150, 235, 255), Position = UDim2.fromScale(0.05, 0.06),
	Size = UDim2.fromScale(0.9, 0.26), Parent = jeu}, 26)
local barre = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.88, 0.22),
	BackgroundColor3 = Color3.fromRGB(30, 40, 55), Parent = jeu}, {coin(0.4)})
local zoneVerte = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = Color3.fromRGB(80, 220, 120),
	Parent = barre}, {coin(0.4)})
local curseur = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 6, 1.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = barre}, {coin(1)})
local points = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.6, 0.18),
	BackgroundTransparency = 1, Parent = jeu}, {creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center})})

-- carte de la prise
local carte = creer("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1.4, 0.45), Size = UDim2.fromScale(0.26, 0.3),
	BackgroundColor3 = Color3.fromRGB(14, 18, 28), BackgroundTransparency = 0.1, Visible = false, Parent = gui},
	{coin(0.08), creer("UISizeConstraint", {MinSize = Vector2.new(260, 200), MaxSize = Vector2.new(380, 280)})})
local bordCarte = trait(Color3.new(1, 1, 1), 3)
bordCarte.Parent = carte
local carteNouveau = texte({Text = "NOUVEAU AU CARNET !", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 215, 90),
	Position = UDim2.fromScale(0.06, 0.05), Size = UDim2.fromScale(0.88, 0.1), Parent = carte}, 18)
local carteNom = texte({Font = Enum.Font.GothamBlack, Position = UDim2.fromScale(0.06, 0.17), Size = UDim2.fromScale(0.88, 0.17), Parent = carte}, 30)
local carteRarete = texte({Font = Enum.Font.GothamBold, Position = UDim2.fromScale(0.06, 0.35), Size = UDim2.fromScale(0.88, 0.1), Parent = carte}, 18)
local carteTexte = texte({Font = Enum.Font.Garamond, TextColor3 = Color3.fromRGB(220, 215, 200), TextWrapped = true,
	Position = UDim2.fromScale(0.08, 0.48), Size = UDim2.fromScale(0.84, 0.2), Parent = carte}, 22)
local cartePieces = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 205, 70), Position = UDim2.fromScale(0.06, 0.7),
	Size = UDim2.fromScale(0.88, 0.13), Parent = carte}, 26)
local carteCarnet = texte({Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(170, 190, 210), Position = UDim2.fromScale(0.06, 0.85),
	Size = UDim2.fromScale(0.88, 0.09), Parent = carte}, 16)

-- « ! » au-dessus du bouchon quand ça mord
local alerte = creer("BillboardGui", {Name = "PecheAlerte", Size = UDim2.fromOffset(64, 64), StudsOffset = V(0, 1.6, 0), AlwaysOnTop = true,
	LightInfluence = 0, ResetOnSpawn = false, Enabled = false, Parent = joueur:WaitForChild("PlayerGui")})
local alerteTexte = texte({Text = "!", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 225, 70), Size = UDim2.fromScale(1, 1),
	Parent = alerte}, 60)
creer("UIStroke", {Color = Color3.fromRGB(70, 35, 0), Thickness = 3, Parent = alerteTexte})
local alerteEchelle = creer("UIScale", {Parent = alerteTexte})

-- ================= Objets 3D locaux (créés une fois, réutilisés) =================
local dossier = creer("Folder", {Name = "PecheLocale", Parent = workspace})

local function piece(taille: Vector3, couleur: Color3, matiere: Enum.Material?, forme: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Shape = forme or Enum.PartType.Block
	p.Size = taille
	p.Color = couleur
	p.Material = matiere or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	return p
end

-- canne : poignée en liège puis brins de plus en plus fins ; la flexion croît vers le scion
local CANNE_LONG = {0.85, 0.95, 0.9, 0.85, 0.8, 0.7}
local CANNE_EP = {0.2, 0.12, 0.1, 0.085, 0.07, 0.055}
local CANNE_RECUL = 0.55
local canne = creer("Model", {Name = "Canne"})
local segments, fracFlex = {}, {}
do
	local total, cumul = 0, 0
	for _, l in CANNE_LONG do
		total += l
	end
	for i, l in CANNE_LONG do
		cumul += l
		fracFlex[i] = (cumul / total) ^ 2
		local s = piece(V(CANNE_EP[i], CANNE_EP[i], l), if i == 1 then Color3.fromRGB(165, 120, 70) else Color3.fromRGB(70, 50, 38),
			if i == 1 then Enum.Material.Wood else nil)
		s.Parent = canne
		segments[i] = s
	end
end
local moulinet = piece(V(0.1, 0.3, 0.3), Color3.fromRGB(175, 178, 190), Enum.Material.Metal)
moulinet.Parent = canne
local scion = piece(V(0.09, 0.09, 0.09), Color3.fromRGB(255, 90, 60), Enum.Material.Neon)
scion.Parent = canne
local OFF_MOULINET = CFrame.new(0, -0.2, -0.2)

local bouchon = creer("Model", {Name = "Bouchon"})
local bBas = piece(V(0.5, 0.5, 0.5), Color3.fromRGB(230, 60, 50), nil, Enum.PartType.Ball)
local bHaut = piece(V(0.34, 0.34, 0.34), Color3.new(1, 1, 1), nil, Enum.PartType.Ball)
local bTige = piece(V(0.06, 0.4, 0.06), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
bBas.Parent, bHaut.Parent, bTige.Parent = bouchon, bouchon, bouchon
local OFF_HAUT, OFF_TIGE = CFrame.new(0, 0.2, 0), CFrame.new(0, 0.5, 0)

local a0 = creer("Attachment", {Name = "PecheLigne0", Parent = terrain})
local a1 = creer("Attachment", {Name = "PecheLigne1", Parent = terrain})
local ligne = creer("Beam", {Attachment0 = a0, Attachment1 = a1, Width0 = 0.04, Width1 = 0.04, Segments = 24, FaceCamera = true,
	Color = ColorSequence.new(Color3.fromRGB(235, 235, 225)), LightEmission = 0.3, LightInfluence = 0.6, Enabled = false, Parent = terrain})

local pointEau = creer("Attachment", {Name = "PecheEau", Parent = terrain})
local gouttes = creer("ParticleEmitter", {Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.fromRGB(205, 245, 255)),
	LightEmission = 0.5, LightInfluence = 0.5, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)}),
	Lifetime = NumberRange.new(0.45, 0.9), Speed = NumberRange.new(5, 11), SpreadAngle = Vector2.new(35, 35),
	EmissionDirection = Enum.NormalId.Top, Acceleration = V(0, -40, 0), Rate = 0, Parent = pointEau})
local ecume = creer("ParticleEmitter", {Texture = TEX_FUMEE, Color = ColorSequence.new(Color3.fromRGB(230, 250, 255)),
	LightEmission = 0.2, Transparency = NumberSequence.new(0.35, 1), Size = NumberSequence.new(0.6, 1.8),
	Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(80, 80),
	EmissionDirection = Enum.NormalId.Top, Rate = 0, Parent = pointEau})
local pointVol = creer("Attachment", {Name = "PecheVol", Parent = terrain})
local traine = creer("ParticleEmitter", {Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.fromRGB(205, 245, 255)),
	LightEmission = 0.5, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0)}),
	Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180),
	Acceleration = V(0, -30, 0), Rate = 55, Enabled = false, Parent = pointVol})
local eclats = creer("ParticleEmitter", {Texture = TEX_ETINCELLE, LightEmission = 1,
	Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}),
	Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(180, 180), Rate = 0, Parent = pointVol})

local function eclabousser(pos: Vector3, n: number)
	pointEau.WorldPosition = pos
	gouttes:Emit(n)
	ecume:Emit(math.ceil(n / 4))
end

-- ronds dans l'eau : anneaux plats qui s'agrandissent (réserve tournante)
local NB_RONDS = 10
local ROT_PLAT = CFrame.Angles(math.pi / 2, 0, 0)
local ronds, rondT0, rondDuree, rondR = {}, table.create(NB_RONDS, 0), table.create(NB_RONDS, 1), table.create(NB_RONDS, 1)
for i = 1, NB_RONDS do
	ronds[i] = creer("CylinderHandleAdornment", {Adornee = terrain, Height = 0.03, Radius = 0.3, InnerRadius = 0.2, ZIndex = 0,
		Color3 = Color3.fromRGB(215, 245, 255), Transparency = 1, Visible = false, Parent = dossier})
end
local rondSuivant = 0

local function rond(pos: Vector3, r: number, duree: number)
	rondSuivant = rondSuivant % NB_RONDS + 1
	local a = ronds[rondSuivant]
	a.CFrame = CFrame.new(pos) * ROT_PLAT
	rondT0[rondSuivant], rondDuree[rondSuivant], rondR[rondSuivant] = os.clock(), duree, r
	a.Visible = true
end

local function majRonds(now: number)
	for i = 1, NB_RONDS do
		local a = ronds[i]
		if a.Visible then
			local u = (now - rondT0[i]) / rondDuree[i]
			if u >= 1 then
				a.Visible = false
			else
				local r = 0.15 + (rondR[i] - 0.15) * sortie(u)
				a.Radius = r
				a.InnerRadius = math.max(0, r - 0.04 - 0.12 * (1 - u))
				a.Transparency = 0.3 + 0.7 * u
			end
		end
	end
end

local function son(nom: string, id: string, volume: number): Sound
	return creer("Sound", {Name = "Peche_" .. nom, SoundId = id, Volume = volume, Parent = SoundService})
end
local sonSiffle = son("Siffle", "rbxasset://sounds/swordslash.wav", 0.22)
local sonPlouf = son("Plouf", "rbxasset://sounds/impact_water.mp3", 0.45)
local sonClapot = son("Clapot", "rbxasset://sounds/impact_water.mp3", 0.16)
local function jouerSon(s: Sound, vitesse: number)
	s.PlaybackSpeed = vitesse * (0.92 + math.random() * 0.16)
	SoundService:PlayLocalSound(s)
end

-- poisson voxel : {taille, décalage, teinte (>0 vers le blanc, <0 vers le noir)} ; la queue bat à part
local POISSON = {
	{V(0.5, 0.7, 1.1), V(0, 0, 0), 0},
	{V(0.42, 0.24, 0.85), V(0, -0.3, -0.05), 0.55},
	{V(0.44, 0.56, 0.3), V(0, 0.02, -0.68), -0.12},
	{V(0.08, 0.3, 0.55), V(0, 0.48, 0.05), -0.3},
	{V(0.3, 0.06, 0.2), V(0, -0.2, -0.2), -0.2},
	{V(0.06, 0.14, 0.14), V(-0.24, 0.12, -0.62), -1},
	{V(0.06, 0.14, 0.14), V(0.24, 0.12, -0.62), -1},
}
local QUEUE_TAILLE, QUEUE_PIVOT, QUEUE_OFF, BOUCHE = V(0.08, 0.72, 0.42), 0.55, 0.21, V(0, 0, -0.85)
local BLANC, NOIR = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

-- ================= Poses (repère du haut du torse : -Z devant, +X à droite) =================
local function u3(x: number, y: number, z: number): Vector3
	return V(x, y, z).Unit
end
local P_REPOS, D_REPOS = V(0.55, -0.5, -1.1), u3(0, 0.55, -1)
local P_ARME, D_ARME = V(0.8, 0.85, -0.2), u3(0.1, 0.5, 1)
local P_LANCE, D_LANCE = V(0.45, -0.3, -1.4), u3(0, 0.08, -1)
local P_COMBAT, D_COMBAT = V(0.6, -0.25, -1), u3(0, 0.85, -1)
local P_TIRE, D_TIRE = V(0.65, 0.35, -0.7), u3(0.05, 1, -0.25)
local P_ECHEC, D_ECHEC = V(0.5, -0.6, -1.15), u3(0, 0.2, -1)
local POLE_D, POLE_G, N_CANNE = V(1, -0.8, 0.4), V(-1, -0.8, 0.4), V(1, 0, 0)
local PRISE_G = 0.5
local T_ARME, T_LACHE, T_LANCE, T_POSE, VOL = 0.38, 0.5, 0.58, 1.05, 0.6
local VOL_POISSON, TENUE = 0.85, 0.6

-- ================= Partie =================
local partie = nil -- état de la partie en cours
local prochainBouton = 0

local function main(): BasePart?
	local perso = joueur.Character
	if not perso then
		return nil
	end
	return (perso:FindFirstChild("RightHand") or perso:FindFirstChild("Right Arm") or perso:FindFirstChild("HumanoidRootPart")) :: BasePart?
end

local function surface(p, pos: Vector3): Vector3
	return V(pos.X, p.surf, pos.Z)
end

local function changerPhase(p, phase: string)
	p.phase, p.tPhase = phase, os.clock()
end

local function nettoyer()
	local p = partie
	partie = nil
	jeu.Visible = false
	alerte.Enabled = false
	ContextActionService:UnbindAction(ACTION)
	if p then
		if bouchon.Parent then
			rond(surface(p, p.bob), 0.7, 0.8)
		end
		for _, o in p.pastilles do
			o:Destroy()
		end
		if p.poisson then
			p.poisson.modele:Destroy()
		end
		IK.relacherBras(p.bras)
		IK.relacherBras(p.gauche)
	end
	canne.Parent, bouchon.Parent = nil, nil
	ligne.Enabled = false
	traine.Enabled = false
end

local function echouer(p, casse: boolean)
	if p.phase == "echec" then
		return
	end
	changerPhase(p, "echec")
	p.casse = casse
	p.fin = p.tPhase + 0.55
	p.centreEau = surface(p, p.bob) + V(0, 0.15, 0)
	alerte.Enabled = false
	eclabousser(p.bob, 10)
	rond(surface(p, p.bob), 1.4, 1)
	if casse then
		UI.jouer("metal", 1.9)
	end
end

local function finir(ok: boolean, casse: boolean?)
	local p = partie
	if not p or p.fini then
		return
	end
	p.fini = true
	remote:FireServer("Fin", {ok = ok})
	jeu.Visible = false
	alerte.Enabled = false
	ContextActionService:UnbindAction(ACTION)
	if ok then
		changerPhase(p, "remonte")
	else
		echouer(p, casse == true)
	end
end

local function placerZone()
	if not partie then
		return
	end
	local w = partie.zone
	partie.centre = w / 2 + math.random() * (1 - w)
	zoneVerte.Size = UDim2.fromScale(w, 1)
	zoneVerte.Position = UDim2.fromScale(partie.centre, 0)
end

local function majPoints()
	if not partie then
		return
	end
	for i, p in partie.pastilles do
		p.BackgroundColor3 = if i <= partie.reussis then Color3.fromRGB(90, 230, 130) else Color3.fromRGB(50, 60, 75)
	end
end

local function ferrer(_, etat)
	if etat ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	local p = partie
	if not p or p.phase ~= "touche" or p.fini or os.clock() < prochainBouton then
		return Enum.ContextActionResult.Sink
	end
	prochainBouton = os.clock() + 0.18
	if math.abs(p.x - p.centre) <= p.zone / 2 + 0.01 then
		p.reussis += 1
		majPoints()
		UI.jouer("metal", 1.1 + p.reussis * 0.12)
		p.tirage, p.tremble = 1, 0.14
		p.impulsion += 0.5
		eclabousser(p.bob, 10)
		rond(surface(p, p.bob), 1.3, 1)
		jouerSon(sonClapot, 1.1)
		if p.reussis >= p.touches then
			consigne.Text = "PRIS !"
			finir(true)
		else
			p.zone = math.max(0.08, p.zone * 0.92)
			placerZone()
		end
	else
		p.rates += 1
		p.mou = 1
		p.impulsion -= 0.4
		UI.secouer(barre, 6)
		UI.jouer("metal", 0.5)
		if p.rates >= 2 then
			consigne.Text = "La ligne casse…"
			finir(false, true)
		else
			consigne.Text = "Raté ! Encore une chance…"
		end
	end
	return Enum.ContextActionResult.Sink
end

local function commencer(d)
	nettoyer()
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local m = main()
	if not (perso and r and hum and m) or typeof(d.eau) ~= "Vector3" then
		remote:FireServer("Fin", {ok = false})
		return
	end
	hum:UnequipTools()
	local bras = IK.preparerBras(perso, "Right")
	local gauche = IK.preparerBras(perso, "Left")
	if gauche then
		gauche.taille = nil
	end
	local eau = d.eau + V(0, 0.2, 0)
	local plat = V(eau.X - r.Position.X, 0, eau.Z - r.Position.Z)
	local dist = plat.Magnitude
	if dist > 0.5 then
		r.CFrame = CFrame.lookAt(r.Position, r.Position + plat)
	end
	local avant = if dist > 0.5 then -plat.Unit else V(0, 0, 1)
	local now = os.clock()
	local p = {phase = "attente", debut = now, tPhase = now, attente = tonumber(d.attente) or 3,
		touches = math.clamp(tonumber(d.touches) or 2, 1, 8), zone = math.clamp(tonumber(d.zone) or 0.25, 0.08, 0.5),
		vitesse = math.clamp(tonumber(d.vitesse) or 0.7, 0.2, 2), reussis = 0, rates = 0, x = 0, centre = 0.5, pastilles = {},
		depart = r.Position, fini = false, racine = r, hum = hum, bras = bras, gauche = gauche,
		torse = if bras then bras.torse else r, main = if bras then bras.main else m,
		prise = if bras then IK.priseMain(bras.main, bras.att) else CFrame.identity,
		P = P_REPOS, D = D_REPOS, pitch = 0, yaw = 0, w = 0, flex = 0, impulsion = 0, tirage = 0, mou = 0, tremble = 0,
		eau = eau, surf = d.eau.Y + 0.04, rive = eau + avant * math.min(dist * 0.35, 4), avant = avant, lateral = avant:Cross(HAUT),
		centreEau = eau, bob = m.Position - HAUT * 0.7, lance = eau, hauteur = 2.5 + dist * 0.12,
		siffle = false, lache = false, plouf = false, prochainRond = now + 2, saccade = -1, prochainRemous = 0,
		fin = nil, casse = false, poisson = nil, arrive = false, debutTouche = 0}
	partie = p
	canne.Parent, bouchon.Parent = dossier, dossier
end

local function debutTouche(p, now: number)
	changerPhase(p, "touche")
	p.debutTouche = now
	p.tremble = 0.1
	eclabousser(p.bob, 14)
	rond(surface(p, p.bob), 1.2, 0.9)
	jouerSon(sonClapot, 0.9)
	UI.jouer("ouvrir", 1.4)
	consigne.Text = "ÇA MORD ! Ferre dans la zone verte"
	for i = 1, p.touches do
		p.pastilles[i] = creer("Frame", {Size = UDim2.fromScale(0.85, 0.85), SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = Color3.fromRGB(50, 60, 75), LayoutOrder = i, Parent = points}, {coin(1)})
	end
	placerZone()
	jeu.Visible = true
	UI.pop(jeu, 0.7)
	alerte.Adornee = bHaut
	alerte.Enabled = true
	ContextActionService:BindActionAtPriority(ACTION, ferrer, true, Enum.ContextActionPriority.High.Value + 50,
		Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.UserInputType.MouseButton1)
	ContextActionService:SetTitle(ACTION, "Ferrer")
	ContextActionService:SetPosition(ACTION, UDim2.new(1, -150, 1, -150))
end

local function lancerSortie(p, poisson)
	changerPhase(p, "sortie")
	local k = poisson.taille
	local modele = Instance.new("Model")
	modele.Name = "PoissonPris"
	local parts, offs = {}, {}
	local brille = poisson.id == "Lanterne" or poisson.rarete == "Épique" or poisson.rarete == "Légendaire"
	for i, d in POISSON do
		local t = d[3]
		local c = if t >= 0 then poisson.couleur:Lerp(BLANC, t) else poisson.couleur:Lerp(NOIR, -t)
		local pc = piece(d[1] * k, c, if i == 1 and brille then Enum.Material.Neon else nil)
		pc.Parent = modele
		parts[i], offs[i] = pc, CFrame.new(d[2] * k)
	end
	local queue = piece(QUEUE_TAILLE * k, poisson.couleur:Lerp(NOIR, 0.25))
	queue.Parent = modele
	modele.Parent = dossier
	p.poisson = {modele = modele, parts = parts, offs = offs, queue = queue, pivot = CFrame.new(0, 0, QUEUE_PIVOT * k),
		offQueue = CFrame.new(0, 0, QUEUE_OFF * k), bouche = BOUCHE * k}
	p.lance = p.bob
	bouchon.Parent = nil
	alerte.Enabled = false
	eclabousser(p.bob, 30)
	rond(surface(p, p.bob), 1.8, 1.2)
	rond(surface(p, p.bob), 3, 1.8)
	jouerSon(sonPlouf, 1.3)
	eclats.Color = ColorSequence.new(Peche.COULEUR_RARETE[poisson.rarete] or BLANC)
	pointVol.WorldPosition = p.bob
	traine.Enabled = true
	p.tremble = 0.15
end

local function majCanne(base: Vector3, D: Vector3, flex: number, tire: Vector3): Vector3
	local perp = tire - D * tire:Dot(D)
	if perp.Magnitude < 1e-3 then
		perp = V(0, -1, 0) + D * D.Y
		if perp.Magnitude < 1e-3 then
			perp = Vector3.xAxis
		end
	end
	perp = perp.Unit
	local pos = base - D * CANNE_RECUL
	for i, s in segments do
		local a = flex * fracFlex[i]
		local fin = pos + (D * math.cos(a) + perp * math.sin(a)) * CANNE_LONG[i]
		s.CFrame = CFrame.lookAt((pos + fin) * 0.5, fin)
		pos = fin
	end
	moulinet.CFrame = segments[1].CFrame * OFF_MOULINET
	scion.Position = pos
	return pos
end

local function cadreAxe(pos: Vector3, ax: Vector3): CFrame
	local z = ax:Cross(HAUT)
	if z.Magnitude < 1e-3 then
		z = ax:Cross(Vector3.xAxis)
	end
	z = z.Unit
	return CFrame.fromMatrix(pos, ax, z:Cross(ax), z)
end

local function majLigne(debut: Vector3, fin: Vector3, mou: number, vib: number, now: number)
	local d = fin - debut
	local L = d.Magnitude
	if L < 0.05 then
		ligne.Enabled = false
		return
	end
	local u = d / L
	local bas = V(0, -mou, 0)
	local lat = if vib > 0 then u:Cross(HAUT) * (math.sin(now * 55) * vib) else Vector3.zero
	a0.WorldCFrame = cadreAxe(debut, (u + bas + lat).Unit)
	a1.WorldCFrame = cadreAxe(fin, (u - bas - lat).Unit)
	ligne.CurveSize0, ligne.CurveSize1 = L * 0.35, L * 0.35
	ligne.Enabled = true
end

local function remous(p, now: number, pos: Vector3, ecart: number)
	if now >= p.prochainRemous then
		p.prochainRemous = now + 0.22 + math.random() * 0.3
		local q = pos + V((math.random() - 0.5) * ecart, 0, (math.random() - 0.5) * ecart)
		eclabousser(q, 4 + math.random(4))
		rond(surface(p, q), 0.9, 0.8)
		if math.random() < 0.35 then
			jouerSon(sonClapot, 1.2)
		end
	end
end

-- ================= Pose des bras (avant la simulation, sinon les AnimationConstraint ne suivent pas) =================
local function poseCible(p, now: number): (Vector3, Vector3, number, number, number)
	local ph = p.phase
	if ph == "attente" then
		local tl = now - p.debut
		if tl < T_ARME then
			local u = sortie(tl / T_ARME)
			return P_REPOS:Lerp(P_ARME, u), D_REPOS:Lerp(D_ARME, u), 0.15 * u, -0.35 * u, 40
		elseif tl < T_LANCE then
			local u = entree((tl - T_ARME) / (T_LANCE - T_ARME))
			return P_ARME:Lerp(P_LANCE, u), D_ARME:Lerp(D_LANCE, u), 0.15 - 0.35 * u, -0.35 + 0.6 * u, 40
		elseif tl < T_POSE then
			local u = lisse((tl - T_LANCE) / (T_POSE - T_LANCE))
			return P_LANCE:Lerp(P_REPOS, u), D_LANCE:Lerp(D_REPOS, u), -0.2 * (1 - u), 0.25 * (1 - u), 20
		end
		return P_REPOS + V(0, math.sin(now * 1.7) * 0.03, 0), D_REPOS, 0, 0, 6
	elseif ph == "touche" then
		local a, s = p.tirage, math.sin(now * 7.5)
		return P_COMBAT:Lerp(P_TIRE, a) + V(0, s * 0.05, s * 0.04), D_COMBAT:Lerp(D_TIRE, a), -0.05 + 0.2 * a, 0.05 * s, 14
	elseif ph == "remonte" or ph == "sortie" then
		return P_TIRE + V(0, math.sin(now * 9) * 0.03, 0), D_TIRE, 0.2, 0, 10
	end
	return P_ECHEC, D_ECHEC, -0.05, 0, 8
end

RunService.PreSimulation:Connect(function(dt)
	local p = partie
	if not p then
		return
	end
	local now = os.clock()
	local P, D, pitch, yaw, k = poseCible(p, now)
	local a = 1 - math.exp(-k * dt)
	p.P = p.P:Lerp(P, a)
	local d = p.D:Lerp(D, a)
	if d.Magnitude > 1e-3 then
		p.D = d.Unit
	end
	p.pitch += (pitch - p.pitch) * a
	p.yaw += (yaw - p.yaw) * a
	local w = lisse((now - p.debut) / 0.18)
	if p.fin and now > p.fin then
		w *= 1 - lisse((now - p.fin) / 0.35)
	end
	p.w = w
	local b = p.bras
	if b and IK.brasValide(b) then
		IK.poserBras(b, p.P, POLE_D, p.D, N_CANNE, CFrame.identity, w)
		IK.poserTaille(b, p.pitch * w, p.yaw * w)
		local g = p.gauche
		if g and IK.brasValide(g) then
			IK.poserBras(g, p.P - p.D * PRISE_G, POLE_G, p.D, N_CANNE, CFrame.identity, w)
		end
	end
end)

-- ================= Canne, ligne, bouchon, poisson (après la simulation) =================
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	majRonds(now)
	local p = partie
	if not p then
		return
	end
	local r = p.racine
	if not r.Parent or not p.hum.Parent or p.hum.Health <= 0 then
		finir(false)
		nettoyer()
		return
	end
	p.tirage *= math.exp(-dt * 3.5)
	p.mou *= math.exp(-dt * 3)
	p.tremble *= math.exp(-dt * 6)
	p.impulsion *= math.exp(-dt * 5)

	local tl, tp, ph = now - p.debut, now - p.tPhase, p.phase
	local base = if p.main.Parent then (p.main.CFrame * p.prise).Position else r.Position
	local D = p.torse.CFrame:VectorToWorldSpace(p.D)
	local flexCible, mou, vib = 0.1 + math.sin(now * 1.3) * 0.04, 0.55 + math.sin(now * 1.1) * 0.25, 0
	local inclX, inclZ = math.sin(now * 1.9) * 0.12, math.cos(now * 1.5) * 0.12
	local bob = p.bob
	local ligneVisible = true

	if ph == "attente" then
		if tl < T_LACHE then
			flexCible, mou = if tl < T_ARME then 0.2 else -0.6, 0
		elseif tl < T_LACHE + VOL then
			flexCible, mou = -0.2, 0.15
		end
	elseif ph == "touche" then
		flexCible, mou, vib = 0.55 + math.sin(now * 6) * 0.2 + p.tirage * 0.6, 0.04 + p.mou * 0.5, 0.05 + p.tirage * 0.1
		inclX, inclZ = math.sin(now * 11) * 0.3, math.cos(now * 9) * 0.3
	elseif ph == "remonte" then
		flexCible, mou, vib = 1 + math.sin(now * 9) * 0.15, 0, 0.12
	elseif ph == "sortie" then
		flexCible, mou, vib = if p.arrive then 0.15 else 0.9, if p.arrive then 0.45 else 0.05, 0
	else
		flexCible, mou = 0, if p.casse then 0 else 1.1
		vib = if p.casse and tp < 0.15 then 0.25 else 0
	end
	p.flex += (flexCible - p.flex) * (1 - math.exp(-dt * 14))
	local flex = p.flex + p.impulsion
	if ph == "echec" then
		flex += -0.35 * math.exp(-5 * tp) * math.cos(tp * 18)
	end
	local bout = majCanne(base, D, flex, bob - base)

	if ph == "attente" then
		if tl < T_LACHE then
			bob = bob:Lerp(bout - HAUT * 0.7, 1 - math.exp(-dt * 12))
			if tl >= T_ARME and not p.siffle then
				p.siffle = true
				jouerSon(sonSiffle, 1.35)
			end
		elseif tl < T_LACHE + VOL then
			if not p.lache then
				p.lache, p.lance = true, bob
			end
			local u = (tl - T_LACHE) / VOL
			bob = p.lance:Lerp(p.eau, u) + HAUT * (math.sin(u * math.pi) * p.hauteur)
		else
			local ts = tl - T_LACHE - VOL
			if not p.plouf then
				p.plouf = true
				eclabousser(p.eau, 22)
				rond(surface(p, p.eau), 1.6, 1.3)
				rond(surface(p, p.eau), 2.6, 1.9)
				jouerSon(sonPlouf, 1)
			end
			local dunk = 0.35 * math.exp(-4 * ts) * math.cos(ts * 9)
			bob = p.eau + V(math.sin(now * 0.7) * 0.08, math.sin(now * 2.2) * 0.06 - dunk, math.cos(now * 0.5) * 0.08)
			if now >= p.prochainRond then
				p.prochainRond = now + 1.4 + math.random() * 1.2
				rond(surface(p, bob), 0.9, 1.5)
			end
			if tl >= p.attente then
				debutTouche(p, now)
			end
		end
	elseif ph == "touche" then
		local f = tp * 2.4
		local n = math.floor(f)
		f -= n
		if n ~= p.saccade then
			p.saccade = n
			p.impulsion += 0.35
			p.tremble = math.max(p.tremble, 0.05)
			eclabousser(bob, 6)
			rond(surface(p, bob), 0.8, 0.9)
			jouerSon(sonClapot, 1.3)
		end
		local plonge = if f < 0.12 then f / 0.12 * 0.5 else 0.5 * (1 - (f - 0.12) / 0.88) ^ 2
		p.centreEau = p.centreEau:Lerp(p.eau:Lerp(p.rive, 0.45 * p.reussis / p.touches), 1 - math.exp(-dt * 3))
		local ampl = math.min(1, tp / 1.2)
		bob = p.centreEau + p.lateral * (math.sin(tp * 2.7) * 0.7 * ampl) + p.avant * (math.sin(tp * 1.9) * 0.3 * ampl)
			- HAUT * (0.15 + plonge)
		if tp > 0.6 then
			remous(p, now, bob, 1.4)
		end
		local s = if tp < 0.15 then tp / 0.15 * 1.35 elseif tp < 0.3 then 1.35 - (tp - 0.15) / 0.15 * 0.35 else 1 + math.sin(now * 14) * 0.1
		alerteEchelle.Scale = s
		if tp > 1.6 then
			alerte.Enabled = false
		end
		if not p.fini then
			local u = ((now - p.debutTouche) * p.vitesse) % 2
			p.x = if u < 1 then u else 2 - u
			curseur.Position = UDim2.fromScale(p.x, 0.5)
			if now - p.debutTouche > Peche.DUREE_MAX - p.attente - 1 then
				consigne.Text = "Trop tard, il s'est décroché…"
				finir(false)
			end
		end
	elseif ph == "remonte" then
		p.centreEau = p.centreEau:Lerp(p.rive, 1 - math.exp(-dt * 1.5))
		bob = p.centreEau + p.lateral * (math.sin(now * 5) * 0.25) + V(0, -0.3 + math.sin(now * 12) * 0.05, 0)
		remous(p, now, bob, 1)
		if tp > 4 then
			nettoyer()
			return
		end
	elseif ph == "sortie" then
		local f = p.poisson
		local arrivee = r.Position + r.CFrame.LookVector * 1.8 + V(0, 1.3, 0)
		local cf
		if tp < VOL_POISSON then
			local u = tp / VOL_POISSON
			local h = p.hauteur + 1.5
			local pos = p.lance:Lerp(arrivee, u) + HAUT * (math.sin(u * math.pi) * h)
			local vit = arrivee - p.lance + HAUT * (math.cos(u * math.pi) * math.pi * h)
			cf = CFrame.lookAt(pos, pos + vit) * CFrame.Angles(0, math.sin(now * 32) * 0.4, math.sin(now * 11) * 0.25)
			pointVol.WorldPosition = pos
		else
			if not p.arrive then
				p.arrive = true
				traine.Enabled = false
				pointVol.WorldPosition = arrivee
				eclats:Emit(18)
				eclabousser(arrivee, 12)
				p.tremble = 0.08
			end
			local amorti = 1 - (tp - VOL_POISSON) / (TENUE + 0.4)
			cf = CFrame.lookAt(arrivee, arrivee + r.CFrame.RightVector) * CFrame.Angles(0, math.sin(now * 26) * 0.35 * amorti, 0)
		end
		if f then
			for i, pc in f.parts do
				pc.CFrame = cf * f.offs[i]
			end
			f.queue.CFrame = cf * f.pivot * CFrame.Angles(0, math.sin(now * 32 + 1.3) * 0.7, 0) * f.offQueue
			bob = cf:PointToWorldSpace(f.bouche)
			if tp >= VOL_POISSON + TENUE then
				pointVol.WorldPosition = cf.Position
				eclats:Emit(14)
				f.modele:Destroy()
				p.poisson = nil
				p.fin = now
			end
		end
		ligneVisible = p.poisson ~= nil
		if tp >= VOL_POISSON + TENUE + 0.4 then
			nettoyer()
			return
		end
	else
		ligneVisible = not p.casse or tp < 0.15
		local montee = -0.3 * math.exp(-6 * tp) + 0.12 * math.exp(-3 * tp) * math.sin(tp * 10)
		bob = p.centreEau + p.avant * (-0.6 * tp) + V(0, montee + math.sin(now * 2.2) * 0.05, 0)
		inclX, inclZ = inclX * 2, inclZ * 2
		if tp >= 1.1 then
			nettoyer()
			return
		end
	end

	p.bob = bob
	if bouchon.Parent then
		local cf = CFrame.new(bob) * CFrame.Angles(inclX, 0, inclZ)
		bBas.CFrame = cf
		bHaut.CFrame = cf * OFF_HAUT
		bTige.CFrame = cf * OFF_TIGE
	end
	if ligneVisible then
		majLigne(bout, if bouchon.Parent then bHaut.Position else bob, mou, vib, now)
	else
		ligne.Enabled = false
	end

	if not p.fini and (r.Position - p.depart).Magnitude > 10 then
		finir(false)
	end
end)

-- petite secousse de caméra (ça mord, ferrage, sortie) ; la caméra de Roblox la recalcule à chaque image
RunService:BindToRenderStep("PecheSecousse", Enum.RenderPriority.Camera.Value + 2, function()
	local p = partie
	local cam = workspace.CurrentCamera
	if p and p.tremble > 0.003 and cam and cam.CameraType == Enum.CameraType.Custom then
		local t = os.clock()
		cam.CFrame *= CFrame.new(math.sin(t * 61) * p.tremble, math.sin(t * 47 + 1) * p.tremble, 0)
	end
end)

joueur.CharacterRemoving:Connect(function()
	if partie then
		finir(false)
		nettoyer()
	end
end)

-- ================= Prise =================
local idCarte = 0
local function montrerCarte(poisson, d)
	idCarte += 1
	local moi = idCarte
	local c = Peche.COULEUR_RARETE[poisson.rarete] or Color3.new(1, 1, 1)
	local carnet = Peche.lire(joueur:GetAttribute("CarnetPeche"))
	carteNouveau.Visible = d.nouveau == true
	carteNom.Text = poisson.nom
	carteNom.TextColor3 = poisson.couleur:Lerp(Color3.new(1, 1, 1), 0.35)
	carteRarete.Text = string.upper(poisson.rarete)
	carteRarete.TextColor3 = c
	carteTexte.Text = "« " .. poisson.texte .. " »"
	cartePieces.Text = "+" .. tostring(d.pieces or poisson.pieces) .. " pièces"
	carteCarnet.Text = "Carnet de pêche : " .. Peche.especes(carnet) .. " / " .. #Peche.POISSONS .. " espèces · prise n° " .. tostring(d.n or 1)
	bordCarte.Color = c
	carte.Visible = true
	carte.Position = UDim2.fromScale(1.4, 0.45)
	TweenService:Create(carte, UI.BOUNCY, {Position = UDim2.fromScale(0.97, 0.45)}):Play()
	UI.jouer("succes")
	if poisson.rarete == "Épique" or poisson.rarete == "Légendaire" then
		UI.celebrer(gui, c, string.upper(poisson.rarete) .. " !")
	end
	task.delay(5.5, function()
		if moi == idCarte then
			TweenService:Create(carte, UI.FAST, {Position = UDim2.fromScale(1.4, 0.45)}):Play()
		end
	end)
end

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	if genre == "Debut" then
		commencer(d)
	elseif genre == "Prise" then
		local poisson = Peche.PAR_ID[d.id]
		if poisson then
			if partie and partie.phase ~= "sortie" and partie.phase ~= "echec" then
				lancerSortie(partie, poisson)
			end
			task.delay(0.8, montrerCarte, poisson, d)
		end
	elseif genre == "Rate" then
		toast("Le poisson s'est échappé…", false)
		if partie then
			echouer(partie, false)
		end
	end
end)
