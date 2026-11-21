--!strict
-- Épée · SCRIPT SERVEUR
-- Donne l'outil « Épée » et relaie les coups. Épée en main = l'épée forgée équipée (sac, slot Epee),
-- construite avec Partage.ArmesVoxels.construire(objet.modele) (EpeeFer si le modèle n'existe pas encore) ;
-- sinon l'épée de base (Forge.EPEE_BASE). Attributs de l'outil : Epee, Degats, Modele, ObjetId.
-- Les coups sont animés par chaque client (EpeeAnimation.client) : le serveur ne fait que valider la
-- cadence, prévenir les autres clients et déclencher le hook ServerStorage.CoupEpee (joueur, coup, outil).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Forge = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Forge"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local NOM_OUTIL = "Épée"
local CADENCE_MIN = 0.15
local SON_COUP = "rbxasset://sounds/swordslash.wav"
local SON_DEGAINER = "rbxasset://sounds/unsheath.wav"

local remote = Instance.new("RemoteEvent")
remote.Name = "CoupEpee"
remote.Parent = ReplicatedStorage

local hook = Instance.new("BindableEvent")
hook.Name = "CoupEpee"
hook.Parent = ServerStorage

local function piece(nom: string, taille: Vector3, y: number, couleur: Color3, matiere: Enum.Material, parent: Instance, racine: BasePart?): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.CFrame = CFrame.new(0, y, 0)
	p.Color = couleur
	p.Material = matiere
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if racine then
		local w = Instance.new("WeldConstraint")
		w.Part0 = racine
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = parent
	return p
end

local function modeleSecours(): Model
	local m = Instance.new("Model")
	local bois, fer = Color3.fromRGB(92, 60, 38), Color3.fromRGB(200, 205, 215)
	local poignee = piece("Poignee", Vector3.new(0.22, 0.9, 0.22), 0, bois, Enum.Material.Wood, m)
	piece("Pommeau", Vector3.new(0.32, 0.25, 0.32), -0.55, fer, Enum.Material.Metal, m, poignee)
	piece("Garde", Vector3.new(1.1, 0.22, 0.3), 0.55, fer, Enum.Material.Metal, m, poignee)
	piece("Lame", Vector3.new(0.42, 2.8, 0.12), 2.06, fer, Enum.Material.Metal, m, poignee)
	m.PrimaryPart = poignee
	return m
end

local function modeleEpee(id: string): Model
	local partage = ReplicatedStorage:WaitForChild("Partage")
	local dossier = partage:FindFirstChild("ArmesVoxels") or partage:WaitForChild("ArmesVoxels", 3)
	if dossier and dossier:IsA("ModuleScript") then
		local ok, m = pcall(function()
			local armes = require(dossier) :: any
			return armes.construire(if armes.existe(id) then id else Forge.EPEE_BASE.modele)
		end)
		if ok and typeof(m) == "Instance" and m:IsA("Model") and (m.PrimaryPart or m:FindFirstChild("Poignee", true)) then
			return m
		end
		warn("[Epee] ArmesVoxels.construire(\"" .. id .. "\") indisponible, lame de secours")
	end
	return modeleSecours()
end

local function attache(lame: BasePart, nom: string, y: number): Attachment
	local a = lame:FindFirstChild(nom)
	if a and a:IsA("Attachment") then
		return a
	end
	local n = Instance.new("Attachment")
	n.Name = nom
	n.Position = Vector3.new(0, y, 0)
	n.Parent = lame
	return n
end

local gabarits: {[string]: Tool} = {}

local function creerGabarit(id: string): Tool
	local m = modeleEpee(id)
	local poignee = (m.PrimaryPart or m:FindFirstChild("Poignee", true)) :: BasePart
	local tool = Instance.new("Tool")
	tool.Name = NOM_OUTIL
	tool.ToolTip = "Clic : attaquer (combo x3)"
	tool.CanBeDropped = false
	tool.Grip = CFrame.Angles(0, math.rad(90), 0)
	tool:SetAttribute("Epee", true)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	poignee.Name = "Handle"
	poignee.Parent = tool
	for _, c in m:GetChildren() do
		c.Parent = tool
	end
	m:Destroy()

	local lame = tool:FindFirstChild("Lame", true)
	if lame and lame:IsA("BasePart") then
		local trail = Instance.new("Trail")
		trail.Name = "TraineeEpee"
		trail.Attachment0 = attache(lame, "TrailA", -lame.Size.Y / 2)
		trail.Attachment1 = attache(lame, "TrailB", lame.Size.Y / 2)
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
		trail.LightEmission = 1
		trail.Brightness = 2
		trail.Lifetime = 0.15
		trail.MinLength = 0.05
		trail.Transparency = NumberSequence.new(0.15, 1)
		trail.WidthScale = NumberSequence.new(1, 0.5)
		trail.Enabled = false
		trail.Parent = lame
	end

	local son = Instance.new("Sound")
	son.Name = "SonCoup"
	son.SoundId = SON_COUP
	son.Volume = 0.45
	son.RollOffMaxDistance = 60
	son.Parent = poignee
	local degainer = son:Clone()
	degainer.Name = "SonDegainer"
	degainer.SoundId = SON_DEGAINER
	degainer.Parent = poignee
	return tool
end

-- Épée équipée dans le sac (objet forgé de type Epee), sinon l'épée de base
local function choix(joueur: Player): (string, number, string, string)
	local p = Donnees.profil(joueur)
	local id = p and p.equipement.Epee
	if p and id then
		for _, o in p.objets do
			if o.id == id and o.type == "Epee" then
				return o.modele, o.valeur, o.nom, o.id
			end
		end
	end
	local b = Forge.EPEE_BASE
	return b.modele, b.valeur, b.nom, ""
end

-- Donne l'épée voulue ; remplace l'ancienne si elle a changé (et la remet en main si elle y était)
local function donner(joueur: Player)
	local sac = joueur:WaitForChild("Backpack")
	local modele, valeur, nom, idObjet = choix(joueur)
	local gabarit = gabarits[modele] or creerGabarit(modele)
	gabarits[modele] = gabarit
	local perso = joueur.Character
	local cle = idObjet .. "|" .. modele .. "|" .. valeur
	local enMain = false
	for _, conteneur in {sac, perso} do
		for _, t in (conteneur :: Instance):GetChildren() do
			if t:IsA("Tool") and t:GetAttribute("Epee") then
				if t:GetAttribute("Cle") == cle then
					return
				end
				enMain = enMain or t.Parent == perso
				t:Destroy()
			end
		end
	end
	local outil = gabarit:Clone()
	outil.ToolTip = string.format("%s · %d dégâts · Clic : attaquer (combo x3)", nom, valeur)
	outil:SetAttribute("Cle", cle)
	outil:SetAttribute("Degats", valeur)
	outil:SetAttribute("Modele", modele)
	outil:SetAttribute("ObjetId", idObjet)
	outil.Parent = sac
	local h = enMain and perso and perso:FindFirstChildOfClass("Humanoid")
	if h then
		h:EquipTool(outil)
	end
end

local derniers: {[Player]: number} = {}

remote.OnServerEvent:Connect(function(joueur: Player, coup: any)
	if coup ~= 0 and coup ~= 1 and coup ~= 2 and coup ~= 3 then
		return
	end
	local perso = joueur.Character
	local h = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not h or h.Health <= 0 then
		return
	end
	local outil = perso:FindFirstChildOfClass("Tool")
	if not outil or not outil:GetAttribute("Epee") then
		return
	end
	local t = os.clock()
	if t - (derniers[joueur] or 0) < CADENCE_MIN then
		return
	end
	derniers[joueur] = t
	for _, p in Players:GetPlayers() do
		if p ~= joueur then
			remote:FireClient(p, perso, coup)
		end
	end
	if coup > 0 then
		hook:Fire(joueur, coup, outil)
	end
end)

local function surJoueur(joueur: Player)
	joueur.CharacterAdded:Connect(function()
		donner(joueur)
	end)
	if joueur.Character then
		task.spawn(donner, joueur)
	end
	if Donnees.attendre(joueur) and joueur.Character then
		donner(joueur)
	end
end

-- Forge, équiper / retirer (Sac.server notifie) : l'épée en main suit
Donnees.surChangement(function(joueur: Player)
	if joueur.Parent and joueur.Character then
		task.spawn(donner, joueur)
	end
end)

Players.PlayerAdded:Connect(surJoueur)
Players.PlayerRemoving:Connect(function(joueur)
	derniers[joueur] = nil
end)
for _, joueur in Players:GetPlayers() do
	task.spawn(surJoueur, joueur)
end
