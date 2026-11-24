-- Viseur : petit rond avec un point blanc au centre de l'écran, affiché tout le temps (sauf mort ;
-- la cinématique du wagon masque les ScreenGui). Le ScreenGui reste activé : on ne change que le rond.
-- À chaque coup, envoie au serveur le point visé (rayon caméra → centre de l'écran) : dans sa mine privée,
-- le serveur creuse là (il valide distance et propriétaire, sinon il garde son repli devant / devant-bas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local joueur = Players.LocalPlayer
local vise = ReplicatedStorage:WaitForChild("VisePioche") :: RemoteEvent
local PORTEE = 8 -- même portée que le serveur (PiocheBraise.server, VISEE_PORTEE)

-- ===== Interface =====
local gui = Instance.new("ScreenGui")
gui.Name = "ViseurPioche"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = joueur:WaitForChild("PlayerGui")

local rond = Instance.new("Frame")
rond.AnchorPoint = Vector2.new(0.5, 0.5)
rond.Position = UDim2.fromScale(0.5, 0.5)
rond.Size = UDim2.fromOffset(20, 20)
rond.BackgroundTransparency = 1
rond.Parent = gui
Instance.new("UICorner", rond).CornerRadius = UDim.new(1, 0)
local trait = Instance.new("UIStroke")
trait.Color = Color3.new(1, 1, 1)
trait.Thickness = 1.5
trait.Transparency = 0.35
trait.Parent = rond

local point = Instance.new("Frame")
point.AnchorPoint = Vector2.new(0.5, 0.5)
point.Position = UDim2.fromScale(0.5, 0.5)
point.Size = UDim2.fromOffset(4, 4)
point.BackgroundColor3 = Color3.new(1, 1, 1)
point.BorderSizePixel = 0
point.Parent = rond
Instance.new("UICorner", point).CornerRadius = UDim.new(1, 0)

-- ===== Dureté (mine privée) : orange = très dur, rouge + cadenas = hors de portée. Le serveur décide. =====
local ORANGE, ROUGE = Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 60, 50)
local CouchesMine = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CouchesMine"))

local cadenas = Instance.new("Frame")
cadenas.AnchorPoint = Vector2.new(0.5, 0.5)
cadenas.Position = UDim2.fromScale(0.5, 0.58)
cadenas.Size = UDim2.fromOffset(10, 8)
cadenas.BackgroundColor3 = ROUGE
cadenas.BorderSizePixel = 0
cadenas.Visible = false
cadenas.Parent = rond
Instance.new("UICorner", cadenas).CornerRadius = UDim.new(0, 2)
local anse = Instance.new("Frame")
anse.AnchorPoint = Vector2.new(0.5, 1)
anse.Position = UDim2.fromScale(0.5, 0)
anse.Size = UDim2.fromOffset(6, 6)
anse.BackgroundTransparency = 1
anse.Parent = cadenas
Instance.new("UICorner", anse).CornerRadius = UDim.new(1, 0)
local anseTrait = Instance.new("UIStroke")
anseTrait.Color = ROUGE
anseTrait.Thickness = 1.5
anseTrait.Parent = anse

local etiquette = Instance.new("TextLabel")
etiquette.AnchorPoint = Vector2.new(0.5, 0)
etiquette.Position = UDim2.new(0.5, 0, 1, 6)
etiquette.Size = UDim2.fromOffset(160, 16)
etiquette.BackgroundTransparency = 1
etiquette.Font = Enum.Font.GothamBlack
etiquette.TextSize = 13
etiquette.TextStrokeTransparency = 0.3
etiquette.Visible = false
etiquette.Parent = rond

local jauge = Instance.new("Frame")
jauge.AnchorPoint = Vector2.new(0.5, 0)
jauge.Position = UDim2.new(0.5, 0, 1, 24)
jauge.Size = UDim2.fromOffset(44, 4)
jauge.BackgroundColor3 = Color3.new(0, 0, 0)
jauge.BackgroundTransparency = 0.4
jauge.BorderSizePixel = 0
jauge.Visible = false
jauge.Parent = rond
local remplissage = Instance.new("Frame")
remplissage.Size = UDim2.fromScale(0, 1)
remplissage.BackgroundColor3 = ORANGE
remplissage.BorderSizePixel = 0
remplissage.Parent = jauge

-- Progression envoyée par le serveur (roche dure : coups / COUPS_DUR ; minerai dur : usure)
local finJauge = 0
local avisMine = ReplicatedStorage:WaitForChild("AvisMine", 30) :: RemoteEvent?
if avisMine then
	avisMine.OnClientEvent:Connect(function(genre: any, valeur: any)
		if genre == "dur" and type(valeur) == "number" then
			remplissage.Size = UDim2.fromScale(math.clamp(valeur, 0, 1), 1)
			finJauge = os.clock() + 1.2
		end
	end)
end

local function palierVise(perso: Model): number?
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local taille = camera.ViewportSize
	local rayon = camera:ViewportPointToRay(taille.X / 2, taille.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {perso}
	local tete = perso:FindFirstChild("Head")
	local longueur = PORTEE + (if tete and tete:IsA("BasePart") then (tete.Position - rayon.Origin).Magnitude else 0)
	local hit = workspace:Raycast(rayon.Origin, rayon.Direction * longueur, params)
	local p = hit and hit.Instance:GetAttribute("Palier")
	return if type(p) == "number" then p else nil
end

local prochainTest = 0
game:GetService("RunService").Heartbeat:Connect(function()
	local t = os.clock()
	if t < prochainTest then return end
	prochainTest = t + 0.1
	local perso = joueur.Character
	local outil = perso and perso:FindFirstChildOfClass("Tool")
	local palier = if perso and outil and outil:GetAttribute("PiocheId") then palierVise(perso) else nil
	local ecart = if palier then CouchesMine.ecart(palier, (outil :: Tool):GetAttribute("PiocheId")) else 0
	local couleur = if ecart >= 2 then ROUGE elseif ecart == 1 then ORANGE else Color3.new(1, 1, 1)
	trait.Color = couleur
	point.BackgroundColor3 = couleur
	point.Visible = ecart < 2
	cadenas.Visible = ecart >= 2
	etiquette.Visible = ecart >= 1
	etiquette.TextColor3 = couleur
	etiquette.Text = if ecart >= 2 then "TROP DUR" else "TRÈS DUR"
	jauge.Visible = ecart == 1 or t < finJauge
end)

-- ===== Visée =====
local function pointVise(perso: Model): Vector3?
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local taille = camera.ViewportSize
	local rayon = camera:ViewportPointToRay(taille.X / 2, taille.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {perso}
	local tete = perso:FindFirstChild("Head")
	local depart = rayon.Origin
	-- Le rayon part de la caméra (derrière le joueur) : portée comptée depuis la tête
	local longueur = PORTEE + (if tete then (tete.Position - depart).Magnitude else 0)
	local hit = workspace:Raycast(depart, rayon.Direction * longueur, params)
	return hit and hit.Position or nil
end

local branches: {[Tool]: boolean} = {}
local function brancher(o: Instance)
	if not (o:IsA("Tool") and o:GetAttribute("PiocheId")) or branches[o] then return end
	branches[o] = true
	-- Clic maintenu : le serveur enchaîne les coups, on lui renvoie le point visé régulièrement
	-- (il limite lui-même la cadence des envois) pour que chaque coup suive le viseur.
	local tenu = false
	local appui = 0 -- numéro de l'appui en cours : une seule boucle d'envoi à la fois
	local function envoyer(): boolean
		local perso = joueur.Character
		if not perso or o.Parent ~= perso then return false end
		local p = pointVise(perso)
		if p then vise:FireServer(p) end
		return true
	end
	o.Activated:Connect(function()
		tenu = true
		appui += 1
		local numero = appui
		task.spawn(function()
			while tenu and appui == numero and envoyer() do
				task.wait(0.15)
			end
		end)
	end)
	o.Deactivated:Connect(function() tenu = false end)
	o.Unequipped:Connect(function() tenu = false end)
	o.Destroying:Once(function() branches[o] = nil end)
end

local function actualiser()
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	rond.Visible = humain ~= nil and humain.Health > 0
end

local function surPersonnage(perso: Model)
	perso.ChildAdded:Connect(brancher)
	local humain = perso:WaitForChild("Humanoid", 10)
	if humain and humain:IsA("Humanoid") then humain.Died:Connect(actualiser) end
	for _, o in perso:GetChildren() do brancher(o) end
	actualiser()
end

joueur.CharacterAdded:Connect(surPersonnage)
if joueur.Character then surPersonnage(joueur.Character) end
