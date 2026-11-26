--!strict
-- Épée · SCRIPT CLIENT : dégainage à l'équipement (coup 0) et combo de 4 coups (droite→gauche, gauche→droite, fendoir à deux mains, coup montant).
-- Attribut local « EpeeGeste » sur le personnage pendant un geste : PiocheDosAnimation n'écrit alors plus le bras.
-- Chaque client anime tous les personnages (C0 décalé de pose * Transform⁻¹, comme PiocheDosAnimation) :
-- le coup du joueur local est joué tout de suite puis relayé par le serveur (RemoteEvent CoupEpee).
-- IK 2 segments (épaule + coude), poignet orienté pour diriger la lame, taille tournée.
-- Parade : clic droit / L2 / bouton tactile maintenu = garde (lame en travers, main gauche sur la lame).
-- Le serveur (Parade.lua, RemoteEvent ParadeEpee) valide et pose « EpeeParade » sur le personnage (vu par tous) ;
-- attribut local « EpeeGarde » sur le LocalPlayer (Hud.client : marche ralentie). Coût : stamina (Stamina.lua).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local remote = ReplicatedStorage:WaitForChild("CoupEpee") :: RemoteEvent
local remoteParade = ReplicatedStorage:WaitForChild("ParadeEpee") :: RemoteEvent
local joueur = Players.LocalPlayer
local IK = require(script.Parent:WaitForChild("RigIK"))
local Stamina = require(script.Parent:WaitForChild("Stamina"))
local Curseur = require(script.Parent:WaitForChild("Curseur"))

local RESET = 1

type Coup = {
	duree: number, t: {number}, e: {(number) -> number}, frappe: Vector2, enchainer: number, cache: number,
	son: string, p: {Vector3}, d: {Vector3}, c: {Vector3}, yaw: {number}, pitch: {number}, n: {Vector3},
	nom: string?, deuxMains: number?, -- coups à valider (CoupsEpeeAValider, aperçu Studio)
}

type Bras = IK.Bras
local lisse, sortie, entree = IK.lisse, IK.sortie, IK.entree
local T_COUP, E_COUP, F_COUP = {0, 0.2, 0.47, 0.68, 1}, {sortie, entree, sortie, lisse}, Vector2.new(0.2, 0.72)

local V = Vector3.new
local GARDE_P, GARDE_D, GARDE_C = V(-0.1, -0.45, -0.6), V(-0.1, 0.55, -0.85), V(0.3, -0.6, 0.6)
local HAUT, DROITE = V(0, 1, 0), V(1, 0, 0)

-- Parade : main droite devant la poitrine, lame horizontale vers la gauche, plat face à l'ennemi
local PARADE_P, PARADE_D, PARADE_C = V(-0.55, 0.08, -0.65), V(-1, 0.2, -0.05).Unit, V(0.75, -0.45, 0.35)
local PARADE_N, PARADE_YAW, PARADE_PITCH = V(0, 0.25, -1).Unit, 0.2, 0.04
local GAUCHE_C, DEMI_LAME = V(-0.75, -0.5, 0.35), 1.2 -- coude gauche, main gauche à 1,2 stud sur la lame
local RECUL_P, RECUL_PITCH = V(0.1, 0.12, 0.3), 0.1 -- choc d'un coup paré
local ENTREE_GARDE, SORTIE_GARDE, DUREE_CHOC = 0.14, 0.2, 0.3
local DUREE_MAX_GARDE, RECHARGE_GARDE = 3.8, 0.45 -- serveur : 4 s et 0,3 s
local COUT_GARDE, DRAIN_GARDE, COUT_PARE = 6, 8, 10 -- stamina : lever, par seconde, par coup paré (0 si parfaite)
local RECUL_VITESSE = 14
local SON_CLANG = "rbxassetid://9116652350"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local ACTION_PARADE = "ParadeEpee"

-- Repère du torse (+X droite, +Y haut, -Z devant) ; positions relatives à l'épaule en longueurs de bras.
-- Coups 1-3, clés : départ (pose actuelle), anticipation, frappe, suivi, garde.
-- Coup 0 = dégainage : hanche gauche, sortie du fourreau, brandi, pause, garde.
local COUPS: {[number]: Coup} = {
	[0] = {
		duree = 0.85, t = {0, 0.3, 0.48, 0.62, 0.8, 1}, e = {sortie, entree, sortie, lisse, lisse},
		frappe = Vector2.new(0.32, 0.8), enchainer = 0.8, cache = 0.3, son = "SonDegainer",
		p = {Vector3.zero, V(-0.6, -0.65, -0.3), V(-0.25, 0.1, -0.75), V(-0.1, 0.85, -0.45), V(-0.1, 0.9, -0.45), GARDE_P},
		d = {Vector3.zero, V(-0.1, -0.45, 0.9), V(-0.6, 0.1, -0.8), V(0, 0.95, -0.3), V(0, 0.95, -0.3), GARDE_D},
		c = {GARDE_C, V(0.8, -0.2, 0.5), V(0.6, -0.6, 0.3), V(0.8, 0.3, 0.3), V(0.8, 0.3, 0.3), GARDE_C},
		yaw = {0, 0.35, 0.15, -0.05, -0.05, 0},
		pitch = {0, -0.1, 0, 0.08, 0.08, 0},
		n = {Vector3.zero, DROITE, DROITE, DROITE, DROITE, DROITE},
	},
	{
		duree = 0.38, t = T_COUP, e = E_COUP, frappe = F_COUP, enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(0.45, 0.05, 0.05), V(-0.25, -0.05, -0.85), V(-0.85, -0.1, -0.35), GARDE_P},
		d = {Vector3.zero, V(0.8, 0.25, 0.55), V(0.1, 0.05, -1), V(-0.9, -0.05, -0.2), GARDE_D},
		c = {GARDE_C, V(0.8, -0.3, 0.4), V(0.2, -0.9, 0.1), V(0, -0.7, 0.6), GARDE_C},
		yaw = {0, -0.45, 0.05, 0.5, 0},
		pitch = {0, 0, -0.05, -0.08, 0},
		n = {Vector3.zero, HAUT, HAUT, HAUT, DROITE},
	},
	{
		duree = 0.38, t = T_COUP, e = E_COUP, frappe = F_COUP, enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(-0.85, 0.1, -0.3), V(-0.1, -0.05, -0.85), V(0.55, -0.05, -0.15), GARDE_P},
		d = {Vector3.zero, V(-0.85, 0.3, 0.4), V(0.05, 0.05, -1), V(0.9, 0, 0.3), GARDE_D},
		c = {GARDE_C, V(0.2, -0.9, 0.3), V(0.3, -0.9, 0.2), V(0.8, -0.5, 0.2), GARDE_C},
		yaw = {0, 0.5, 0, -0.45, 0},
		pitch = {0, 0, -0.05, -0.05, 0},
		n = {Vector3.zero, HAUT, HAUT, HAUT, DROITE},
	},
	-- Coup 3 : « Fendoir à deux mains » (validé, ex-touche K de CoupsEpeeAValider), remplace l'ancien coup vertical
	{
		duree = 0.65, t = {0, 0.38, 0.55, 0.75, 1}, e = {sortie, entree, sortie, lisse},
		frappe = Vector2.new(0.38, 0.75), enchainer = 0.55, cache = 0, son = "SonCoup", deuxMains = -0.45,
		p = {Vector3.zero, V(-0.45, 0.75, -0.35), V(-0.4, -0.1, -0.85), V(-0.35, -0.6, -0.6), GARDE_P},
		d = {Vector3.zero, V(0, 0.55, 0.85), V(0, -0.25, -1), V(0, -0.85, -0.5), GARDE_D},
		c = {GARDE_C, V(0.8, 0.2, -0.2), V(0.6, -0.7, 0.1), V(0.5, -0.8, 0.3), GARDE_C},
		yaw = {0, 0.25, 0.3, 0.3, 0},
		pitch = {0, 0.2, -0.2, -0.3, 0},
		n = {Vector3.zero, DROITE, DROITE, DROITE, DROITE},
	},
	-- Coup 4 : « Coup montant » (validé, ex-touche I puis J de CoupsEpeeAValider)
	{
		duree = 0.48, t = {0, 0.3, 0.48, 0.7, 1}, e = {sortie, entree, sortie, lisse},
		frappe = Vector2.new(0.3, 0.72), enchainer = 0.55, cache = 0, son = "SonCoup",
		p = {Vector3.zero, V(0.25, -0.75, 0.2), V(-0.2, 0.1, -0.85), V(-0.15, 0.8, -0.45), GARDE_P},
		d = {Vector3.zero, V(0.15, -0.85, -0.45), V(-0.05, 0.75, -0.65), V(0, 0.95, 0.3), GARDE_D},
		c = {GARDE_C, V(0.7, -0.3, 0.5), V(0.6, -0.7, 0.2), V(0.8, 0.1, 0.3), GARDE_C},
		yaw = {0, -0.3, 0.15, 0.05, 0},
		pitch = {0, -0.12, 0, 0.15, 0},
		n = {Vector3.zero, DROITE, DROITE, DROITE, DROITE},
	},
}

-- ================= État des personnages =================

type Etat = {
	perso: Model, bras: Bras?, coup: Coup?, t: number,
	poids: number, poidsDepart: number, yaw: number, pitch: number, yaw0: number, pitch0: number,
	p0: Vector3, d0: Vector3, n0: Vector3, trail: Trail?, trailOn: boolean, grip: CFrame,
	pieces: {BasePart}, cache: boolean, son: Sound?,
	gauche: Bras?, garde: boolean, parade: boolean, tg: number, sortieG: number, choc: number,
}

local etats: {[Model]: Etat} = {}

local function etatDe(perso: Model): Etat
	local e = etats[perso]
	if not e then
		e = {
			perso = perso, bras = nil, coup = nil, t = 0, poids = 0, poidsDepart = 0,
			yaw = 0, pitch = 0, yaw0 = 0, pitch0 = 0, p0 = Vector3.zero, d0 = Vector3.zero, n0 = DROITE,
			trail = nil, trailOn = false, grip = CFrame.identity, pieces = {}, cache = false, son = nil,
			gauche = nil, garde = false, parade = false, tg = 0, sortieG = 0, choc = 0,
		}
		etats[perso] = e
		perso.Destroying:Once(function()
			etats[perso] = nil
		end)
	end
	return e :: Etat
end

local function trainee(e: Etat, on: boolean)
	if e.trailOn ~= on then
		e.trailOn = on
		local tr = e.trail
		if tr and tr.Parent then
			tr.Enabled = on
		end
	end
end

-- Épée cachée tant que la main ne l'a pas saisie au fourreau (dégainage)
local function cacher(e: Etat, on: boolean)
	if e.cache ~= on then
		e.cache = on
		local ltm = if on then 1 else 0
		for _, p in e.pieces do
			p.LocalTransparencyModifier = ltm
		end
	end
end

local function finir(e: Etat)
	trainee(e, false)
	cacher(e, false)
	if e.coup and e.coup.deuxMains then
		IK.relacherBras(e.gauche)
	end
	e.coup = nil
	e.poids, e.yaw, e.pitch = 0, 0, 0
	e.perso:SetAttribute("EpeeGeste", nil)
	IK.relacherBras(e.bras)
end

-- Pose de départ d'un geste = pose actuelle de la main (repère du torse)
local function saisir(e: Etat, outil: Tool)
	e.grip = outil.Grip.Rotation
	local b = e.bras
	if b then
		if e.poids == 0 then
			IK.relacherBras(b)
		end
		local prise = b.main.CFrame * IK.priseMain(b.main, b.att)
		e.p0 = b.torse.CFrame:PointToObjectSpace(prise.Position)
		local handle = prise * e.grip:Inverse()
		e.d0 = b.torse.CFrame:VectorToObjectSpace(handle.UpVector)
		e.n0 = b.torse.CFrame:VectorToObjectSpace(handle.ZVector)
	end
end

local function demarrerCoup(e: Etat, c: Coup?)
	if not IK.brasValide(e.bras) then
		e.bras = IK.preparerBras(e.perso, "Right")
	end
	local outil = e.perso:FindFirstChildOfClass("Tool")
	if not outil or not outil:GetAttribute("Epee") or not c then
		return
	end
	if e.coup and e.coup.deuxMains then
		IK.relacherBras(e.gauche)
	end
	if c.deuxMains and not IK.brasValide(e.gauche) then
		e.gauche = IK.preparerBras(e.perso, "Left")
	end
	if e.parade then
		e.parade, e.garde = false, false
		IK.relacherBras(e.gauche)
	end
	trainee(e, false)
	cacher(e, false)
	local tr = outil:FindFirstChild("TraineeEpee", true)
	e.trail = if tr and tr:IsA("Trail") then tr else nil
	saisir(e, outil :: Tool)
	table.clear(e.pieces)
	if c.cache > 0 then
		for _, p in outil:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(e.pieces, p)
			end
		end
		cacher(e, true)
	end
	e.coup = c
	e.t = 0
	e.poidsDepart, e.yaw0, e.pitch0 = e.poids, e.yaw, e.pitch
	e.perso:SetAttribute("EpeeGeste", true)
	local son = outil:FindFirstChild(c.son, true)
	e.son = if son and son:IsA("Sound") then son else nil
	if c.cache == 0 and e.son then
		e.son.PlaybackSpeed = 0.9 + math.random() * 0.25
		e.son:Play()
	end
end

local function demarrer(e: Etat, i: number)
	demarrerCoup(e, COUPS[i])
end

-- ================= Garde (parade) =================

local function finirGarde(e: Etat)
	e.garde, e.parade = false, false
	e.poids, e.yaw, e.pitch = 0, 0, 0
	e.perso:SetAttribute("EpeeGeste", nil)
	IK.relacherBras(e.bras)
	IK.relacherBras(e.gauche)
end

-- Lève la garde depuis la pose actuelle (interrompt proprement un coup en cours)
local function leverGarde(e: Etat)
	local outil = e.perso:FindFirstChildOfClass("Tool")
	if not outil or not outil:GetAttribute("Epee") then
		return
	end
	if not IK.brasValide(e.bras) then
		e.bras = IK.preparerBras(e.perso, "Right")
	end
	if not IK.brasValide(e.gauche) then
		e.gauche = IK.preparerBras(e.perso, "Left")
	end
	if not e.bras then
		return
	end
	if e.coup then
		trainee(e, false)
		cacher(e, false)
		e.coup = nil
	end
	saisir(e, outil :: Tool)
	e.garde, e.parade, e.tg, e.sortieG = true, true, 0, 0
	e.poidsDepart, e.yaw0, e.pitch0 = e.poids, e.yaw, e.pitch
	e.perso:SetAttribute("EpeeGeste", true)
end

local function baisserGarde(e: Etat)
	if e.garde then
		e.garde, e.sortieG = false, 0
	end
end

-- ================= Combo du joueur local =================

local combo, finPrevue, tampon = 0, -math.huge, false
local RECHARGE = 0.5 -- s minimum entre deux coups (le serveur refuse en dessous de 0.45 s)
local dernierCoup = -math.huge

local function lancerLocal(e: Etat)
	tampon = false
	local t = os.clock()
	if t - dernierCoup < RECHARGE then
		return
	end
	dernierCoup = t
	combo = if t - finPrevue > RESET then 1 else combo % #COUPS + 1
	demarrer(e, combo)
	if e.coup then
		finPrevue = t + (e.coup :: Coup).duree
		remote:FireServer(combo)
	end
end

local function degainer()
	local perso = joueur.Character
	if perso then
		local e = etatDe(perso)
		tampon = false
		finPrevue = -math.huge
		demarrer(e, 0)
		if e.coup then
			remote:FireServer(0)
		end
	end
end

-- ================= Garde du joueur local =================

local voulue, enGarde = false, false
local debutGarde, finGarde = 0, -math.huge

local function ecrireGarde(on: boolean)
	enGarde = on
	joueur:SetAttribute("EpeeGarde", on)
	remoteParade:FireServer(on)
end

local function essayerGarde()
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	local outil = perso and perso:FindFirstChildOfClass("Tool")
	if enGarde or not perso or not h or h.Health <= 0 or not outil or not outil:GetAttribute("Epee")
		or Curseur.estLibre() or os.clock() - finGarde < RECHARGE_GARDE or not Stamina.consommer(COUT_GARDE) then
		return
	end
	tampon = false
	debutGarde = os.clock()
	leverGarde(etatDe(perso))
	ecrireGarde(true)
end

local function arreterGarde()
	if enGarde then
		finGarde = os.clock()
		ecrireGarde(false)
		local perso = joueur.Character
		local e = perso and etats[perso]
		if e then
			baisserGarde(e)
		end
	end
end

local function presser(on: boolean)
	voulue = on
	if on then
		essayerGarde()
	else
		arreterGarde()
	end
end

local function majGardeLocale(dt: number)
	if not enGarde then
		if voulue then
			essayerGarde()
		end
		return
	end
	Stamina.drainer(DRAIN_GARDE * dt)
	local perso = joueur.Character
	local outil = perso and perso:FindFirstChildOfClass("Tool")
	if Stamina.estEpuise() or os.clock() - debutGarde > DUREE_MAX_GARDE or Curseur.estLibre()
		or not (outil and outil:GetAttribute("Epee")) then
		voulue = false -- relâcher puis represser pour relever la garde
		arreterGarde()
	end
end

-- Clic droit : aussi la rotation de la caméra Roblox en caméra libre → on ne bloque rien (pas de Sink)
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 and UserInputService:GetFocusedTextBox() == nil then
		presser(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		presser(false)
	end
end)

-- Manette (L2) et bouton tactile : liés seulement quand l'épée est en main
local function actionParade(_nom: string, etat: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if etat == Enum.UserInputState.Begin then
		presser(true)
	elseif etat == Enum.UserInputState.End or etat == Enum.UserInputState.Cancel then
		presser(false)
	end
	return Enum.ContextActionResult.Pass
end

-- ================= Aperçu Studio des coups à valider (CoupsEpeeAValider) =================
-- Studio seulement, épée en main : touches Y, U, J, K = coups 1-4 à valider joué en local (ni dégâts, ni serveur).
-- Action liée avec Sink (Y U J K sont libres ailleurs : le pavé 1-9 sert à la barre d'objets).
local lierApercu = function(_on: boolean) end
local module = RunService:IsStudio() and script.Parent:FindFirstChild("CoupsEpeeAValider")
if module and module:IsA("ModuleScript") then
	local liste: {Coup} = (require :: any)(module)
	local TOUCHES_APERCU = {Enum.KeyCode.Y, Enum.KeyCode.U, Enum.KeyCode.J, Enum.KeyCode.K} -- I et O = zoom de la caméra Roblox
	local TweenService = game:GetService("TweenService")
	local etiquette: TextLabel? = nil
	local numero = 0

	local function afficher(i: number, nom: string)
		local pg = joueur:FindFirstChildOfClass("PlayerGui")
		if not pg then
			return
		end
		local lbl = etiquette
		if not lbl or not lbl.Parent then
			local gui = Instance.new("ScreenGui")
			gui.Name = "ApercuCoupsEpee"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 50
			local l = Instance.new("TextLabel")
			l.AnchorPoint = Vector2.new(0.5, 0)
			l.Position = UDim2.new(0.5, 0, 0, 70)
			l.Size = UDim2.fromOffset(520, 34)
			l.BackgroundColor3 = Color3.fromRGB(24, 17, 13)
			l.BackgroundTransparency = 0.25
			l.TextColor3 = Color3.fromRGB(255, 214, 120)
			l.Font = Enum.Font.GothamBold
			l.TextSize = 20
			l.Parent = gui
			Instance.new("UICorner").Parent = l
			gui.Parent = pg
			lbl = l
			etiquette = l
		end
		local l = lbl :: TextLabel
		numero += 1
		local n = numero
		l.Text = string.format("Coup à valider n° %d : %s", i, nom)
		l.TextTransparency, l.BackgroundTransparency = 0, 0.25
		task.delay(2.5, function()
			if numero == n and l.Parent then
				TweenService:Create(l, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
			end
		end)
	end

	local function actionApercu(_nom: string, etat: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
		if etat ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		local perso = joueur.Character
		local h = perso and perso:FindFirstChildOfClass("Humanoid")
		if not perso or not h or h.Health <= 0 or enGarde then
			return Enum.ContextActionResult.Sink
		end
		for i, k in TOUCHES_APERCU do
			local c = liste[i]
			if input.KeyCode == k and c then
				demarrerCoup(etatDe(perso), c)
				afficher(i, c.nom or "?")
			end
		end
		return Enum.ContextActionResult.Sink
	end

	lierApercu = function(on: boolean)
		if on then
			ContextActionService:BindActionAtPriority("ApercuCoupsEpee", actionApercu, false,
				Enum.ContextActionPriority.High.Value, table.unpack(TOUCHES_APERCU))
		else
			ContextActionService:UnbindAction("ApercuCoupsEpee")
		end
	end
end

local function lierParade(on: boolean)
	lierApercu(on)
	if on then
		local tactile = UserInputService.TouchEnabled
		ContextActionService:BindAction(ACTION_PARADE, actionParade, tactile, Enum.KeyCode.ButtonL2)
		if tactile then
			ContextActionService:SetTitle(ACTION_PARADE, "Parade")
			ContextActionService:SetPosition(ACTION_PARADE, UDim2.new(1, -235, 1, -95))
		end
	else
		ContextActionService:UnbindAction(ACTION_PARADE)
		presser(false)
	end
end

local function cliquer()
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not h or h.Health <= 0 or enGarde then
		return
	end
	local e = etatDe(perso)
	if e.parade then
		tampon = true -- coup lancé à la fin de la sortie de garde
		return
	end
	local c = e.coup
	if c and e.t / c.duree < c.enchainer then
		tampon = true
		return
	end
	lancerLocal(e)
end

local branches: {[Tool]: boolean} = {}
local function brancher(o: Instance)
	if o:IsA("Tool") and o:GetAttribute("Epee") and not branches[o] then
		branches[o] = true
		o.Activated:Connect(cliquer)
		o.Equipped:Connect(degainer)
		o.Equipped:Connect(function()
			lierParade(true)
		end)
		o.Unequipped:Connect(function()
			lierParade(false)
		end)
		o.Destroying:Once(function()
			branches[o] = nil
		end)
		if o.Parent and o.Parent == joueur.Character then
			lierParade(true)
		end
	end
end
local function suivreConteneur(c: Instance?)
	if c then
		c.ChildAdded:Connect(brancher)
		for _, o in c:GetChildren() do
			brancher(o)
		end
	end
end
joueur.CharacterAdded:Connect(function(perso)
	tampon = false
	voulue = false
	if enGarde then
		finGarde = os.clock()
		ecrireGarde(false)
	end
	suivreConteneur(perso)
end)
joueur.ChildAdded:Connect(function(o)
	if o:IsA("Backpack") then
		suivreConteneur(o)
	end
end)
suivreConteneur(joueur.Character)
suivreConteneur(joueur:FindFirstChildOfClass("Backpack"))

remote.OnClientEvent:Connect(function(perso: any, i: any)
	if typeof(perso) == "Instance" and perso:IsA("Model") and perso ~= joueur.Character and COUPS[i] then
		demarrer(etatDe(perso), i)
	end
end)

-- Garde des autres joueurs : attribut répliqué « EpeeParade » posé par le serveur
local function suivrePerso(perso: Model)
	local function maj()
		if perso ~= joueur.Character then
			local e = etatDe(perso)
			if perso:GetAttribute("EpeeParade") then
				leverGarde(e)
			else
				baisserGarde(e)
			end
		end
	end
	perso:GetAttributeChangedSignal("EpeeParade"):Connect(maj)
	if perso:GetAttribute("EpeeParade") then
		maj()
	end
end
local function suivreJoueur(p: Player)
	if p ~= joueur then
		p.CharacterAdded:Connect(suivrePerso)
		if p.Character then
			suivrePerso(p.Character)
		end
	end
end
Players.PlayerAdded:Connect(suivreJoueur)
for _, p in Players:GetPlayers() do
	suivreJoueur(p)
end

-- Coup paré (serveur) : étincelles + clang sur la lame, choc dans la pose, recul et stamina pour soi
local function etincelles(perso: Model, parfaite: boolean)
	local outil = perso:FindFirstChildOfClass("Tool")
	local lame = outil and outil:FindFirstChild("Lame", true)
	local support = if lame and lame:IsA("BasePart") then lame else perso:FindFirstChild("HumanoidRootPart")
	if not (support and support:IsA("BasePart")) then
		return
	end
	local a = Instance.new("Attachment")
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = TEX_ETINCELLE
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 245, 205), Color3.fromRGB(255, 165, 60))
	pe.LightEmission = 1
	pe.Size = NumberSequence.new(if parfaite then 0.45 else 0.3, 0)
	pe.Lifetime = NumberRange.new(0.15, 0.35)
	pe.Speed = NumberRange.new(12, 24)
	pe.SpreadAngle = Vector2.new(80, 80)
	pe.Acceleration = V(0, -40, 0)
	pe.Drag = 3
	pe.Rate = 0
	pe.Parent = a
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 220, 150)
	l.Brightness = if parfaite then 6 else 3
	l.Range = 10
	l.Parent = a
	local s = Instance.new("Sound")
	s.SoundId = SON_CLANG
	s.Volume = if parfaite then 0.9 else 0.6
	s.PlaybackSpeed = (if parfaite then 1.25 else 1) * (0.95 + math.random() * 0.1)
	s.RollOffMaxDistance = 80
	s.Parent = a
	a.Parent = support
	pe:Emit(if parfaite then 30 else 16)
	s:Play()
	Debris:AddItem(l, 0.12)
	Debris:AddItem(a, 1.5)
end

remoteParade.OnClientEvent:Connect(function(perso: any, parfaite: any)
	if typeof(perso) ~= "Instance" or not perso:IsA("Model") then
		return
	end
	local p = parfaite == true
	local e = etats[perso]
	if e and e.parade then
		e.choc = DUREE_CHOC
	end
	etincelles(perso, p)
	if perso == joueur.Character then
		if not p then
			Stamina.drainer(COUT_PARE)
		end
		local hrp = perso:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local l = hrp.CFrame.LookVector
			hrp.AssemblyLinearVelocity -= V(l.X, 0, l.Z) * (if p then RECUL_VITESSE * 0.5 else RECUL_VITESSE)
		end
	end
end)

-- ================= Boucle =================

local function cle(liste: {Vector3}, depart: Vector3, i: number): Vector3
	return if i <= 1 then depart else liste[math.min(i, #liste)]
end

local function avancer(e: Etat, dt: number)
	local c = e.coup :: Coup
	local b = e.bras
	e.t += dt
	local u = e.t / c.duree
	if u >= 1 or not b or not IK.brasValide(b) then
		finir(e)
		return
	end
	if tampon and u >= c.enchainer and e.perso == joueur.Character then
		lancerLocal(e)
		return
	end
	if e.cache and u >= c.cache then
		cacher(e, false)
		if e.son then
			e.son:Play()
		end
	end
	trainee(e, u >= c.frappe.X and u <= c.frappe.Y)

	local T = c.t
	local n = #T - 1
	local k = n
	for s = 1, n do
		if u <= T[s + 1] then
			k = s
			break
		end
	end
	local v = c.e[k]((u - T[k]) / (T[k + 1] - T[k]))

	local w = e.poidsDepart + (1 - e.poidsDepart) * lisse(u / 0.12)
	if u > T[n] then
		w *= 1 - lisse((u - T[n]) / (1 - T[n]))
	end
	e.poids = w

	local S, L = b.epaule.c0Origine.Position, b.l1 + b.l2
	local p0 = (e.p0 - S) / L
	local q0, q1, q2, q3 = cle(c.p, p0, k - 1), cle(c.p, p0, k), cle(c.p, p0, k + 1), cle(c.p, p0, k + 2)
	local p = 0.5 * ((2 * q1) + (q2 - q0) * v + (2 * q0 - 5 * q1 + 4 * q2 - q3) * (v * v) + (3 * q1 - q0 - 3 * q2 + q3) * (v * v * v))
	q0, q1, q2, q3 = cle(c.d, e.d0, k - 1), cle(c.d, e.d0, k), cle(c.d, e.d0, k + 1), cle(c.d, e.d0, k + 2)
	local d = 0.5 * ((2 * q1) + (q2 - q0) * v + (2 * q0 - 5 * q1 + 4 * q2 - q3) * (v * v) + (3 * q1 - q0 - 3 * q2 + q3) * (v * v * v))
	if d.Magnitude < 1e-3 then
		d = q2
	end
	local pole = c.c[k]:Lerp(c.c[k + 1], v)
	local na, nb = cle(c.n, e.n0, k), c.n[k + 1]
	if na:Dot(nb) < 0 then
		na = -na
	end

	IK.poserBras(b, S + p * L, pole, d.Unit, na:Lerp(nb, v), e.grip, w)
	local dm, g = c.deuxMains, e.gauche
	if dm and g and IK.brasValide(g) then
		IK.poserBras(g, S + p * L + d.Unit * dm, GAUCHE_C, d.Unit, na:Lerp(nb, v), e.grip, w * lisse(u / 0.25))
	end

	local ya = if k == 1 then e.yaw0 else c.yaw[k]
	local pa = if k == 1 then e.pitch0 else c.pitch[k]
	e.yaw = ya + (c.yaw[k + 1] - ya) * v
	e.pitch = pa + (c.pitch[k + 1] - pa) * v
	IK.poserTaille(b, e.pitch * w, e.yaw * w)
end

local function avancerGarde(e: Etat, dt: number)
	local b = e.bras
	if not b or not IK.brasValide(b) then
		finirGarde(e)
		return
	end
	e.tg += dt
	local w = e.poidsDepart + (1 - e.poidsDepart) * lisse(e.tg / 0.08)
	if not e.garde then
		e.sortieG += dt
		local s = e.sortieG / SORTIE_GARDE
		if s >= 1 then
			finirGarde(e)
			if tampon and e.perso == joueur.Character then
				lancerLocal(e)
			end
			return
		end
		w *= 1 - lisse(s)
	end
	e.poids = w
	local u = sortie(math.min(e.tg / ENTREE_GARDE, 1))

	local a = 0
	if e.choc > 0 then
		e.choc = math.max(0, e.choc - dt)
		local v = 1 - e.choc / DUREE_CHOC
		a = if v < 0.15 then v / 0.15 else (1 - (v - 0.15) / 0.85) ^ 2
	end

	local S, L = b.epaule.c0Origine.Position, b.l1 + b.l2
	local main = S + (((e.p0 - S) / L):Lerp(PARADE_P, u) + RECUL_P * a) * L
	local d = e.d0:Lerp(PARADE_D, u)
	d = if d.Magnitude < 1e-3 then PARADE_D else d.Unit
	local n0 = if e.n0:Dot(PARADE_N) < 0 then -e.n0 else e.n0
	local n = n0:Lerp(PARADE_N, u)
	IK.poserBras(b, main, GARDE_C:Lerp(PARADE_C, u), d, n, e.grip, w)

	e.yaw = e.yaw0 + (PARADE_YAW - e.yaw0) * u
	e.pitch = e.pitch0 + (PARADE_PITCH - e.pitch0) * u + RECUL_PITCH * a
	IK.poserTaille(b, e.pitch * w, e.yaw * w)

	local g = e.gauche
	if g and IK.brasValide(g) then
		IK.poserBras(g, main + d * DEMI_LAME, GAUCHE_C, d, n, e.grip, w * u)
	end
end

local derniere = os.clock()
RunService.PreSimulation:Connect(function()
	local t = os.clock()
	local dt = math.min(t - derniere, 0.1)
	derniere = t
	majGardeLocale(dt)
	for _, e in etats do
		if e.coup then
			avancer(e, dt)
		elseif e.parade then
			avancerGarde(e, dt)
		end
	end
end)
