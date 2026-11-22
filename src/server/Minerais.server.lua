-- Minerais · SCRIPT SERVEUR
-- Où : ServerScriptService > Script
-- 4 minerais : Charbon (Commun), Bronze (Peu commun), Fer (Rare), Gold (Légendaire).
-- Ils marchent avec les pioches (tag "Minerai") et vont dans le sac quand on les casse ;
-- on les vend ensuite à Gaspard (Marchand.server.lua) au prix de Partage › PrixMinerais.
-- Chaque minerai : grappe de rochers, amas de cristaux, veines lumineuses, cailloux au sol,
-- et des fissures qui s'allument à chaque coup.
-- Va avec le SCRIPT CLIENT des minerais (éclats en orbite, tourbillons, arcs, rayons, cercle).
--
-- Où ils apparaissent : pose des Parts avec le tag "SpawnMinerai" dans ta map.
-- Elles deviennent invisibles et un minerai pousse dessus, tiré au hasard selon sa rareté.
-- Pour forcer un type, ajoute à la Part un attribut "Type" (Charbon, Bronze, Fer ou Gold).
-- Sans point d'apparition, une rangée de démonstration des 4 minerais apparaît en (0, 0, -25).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CONFIG = {
	REAPPARITION = 20,                    -- secondes avant qu'un minerai repousse
	TAG_MINERAI = "Minerai",
	TAG_SPAWN = "SpawnMinerai",
	DEMO_POSITION = Vector3.new(0, 0, -25),
	DEMO_ECART = 9,
	MONNAIE = "Pièces",
	-- false : le minerai cassé va seulement au sac (on le vend chez Gaspard).
	-- true : ancien comportement, les Pièces tombent tout de suite en plus du minerai.
	GAIN_DIRECT = false,
}

local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"

-- Géométrie et couleurs (taille, couleur, cristaux, veines...) : Partage › MineraisModeles, partagé avec les icônes 3D du client
local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))

local PrixMinerais = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("PrixMinerais"))

-- valeur = prix de vente (source unique : Partage › PrixMinerais)
local MINERAIS = {
	Charbon = {couleurRarete = Color3.fromRGB(184, 188, 198), chance = 60, pv = 2, valeur = PrixMinerais.PRIX.Charbon, lumiere = nil},
	Bronze = {couleurRarete = Color3.fromRGB(255, 154, 60), chance = 25, pv = 3, valeur = PrixMinerais.PRIX.Bronze, lumiere = Color3.fromRGB(255, 130, 50)},
	Fer = {couleurRarete = Color3.fromRGB(79, 141, 255), chance = 12, pv = 5, valeur = PrixMinerais.PRIX.Fer, lumiere = Color3.fromRGB(140, 190, 255)},
	Gold = {couleurRarete = Color3.fromRGB(179, 92, 255), chance = 3, pv = 8, valeur = PrixMinerais.PRIX.Gold, lumiere = Color3.fromRGB(255, 200, 60)},
}
for nom, v in MineraisModeles.VISUEL do
	for cle, valeur in v do
		MINERAIS[nom][cle] = valeur
	end
end
local ORDRE = MineraisModeles.ORDRE

local dossier = Instance.new("Folder")
dossier.Name = "Minerais"
dossier.Parent = workspace

local function emetteur(parent: Instance, props: {[string]: any}): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	for cle, valeur in props do
		e[cle] = valeur
	end
	e.Parent = parent
	return e
end

local piece = MineraisModeles.piece
local construire = MineraisModeles.construire

local function effets(coeur: Part, nom: string)
	local def = MINERAIS[nom]
	local s = def.taille
	if nom == "Charbon" then
		emetteur(coeur, {
			Name = "Fumee", Texture = TEX_FUMEE, LightEmission = 0,
			Color = ColorSequence.new(Color3.fromRGB(35, 35, 40)),
			Size = NumberSequence.new(1.5 * s, 3.5 * s), Transparency = NumberSequence.new(0.65, 1),
			Lifetime = NumberRange.new(2.5, 4), Rate = 3, Speed = NumberRange.new(0.4, 0.9),
			SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 0.4, 0),
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
		})
		emetteur(coeur, {
			Name = "Poussiere", Texture = TEX_ETINCELLE, LightEmission = 0,
			Color = ColorSequence.new(Color3.fromRGB(20, 20, 24)),
			Size = NumberSequence.new(0.15, 0), Lifetime = NumberRange.new(1.5, 2.5), Rate = 6,
			Speed = NumberRange.new(0.5, 1), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.6, 0),
		})
		emetteur(coeur, {
			Name = "BraisesCouvantes", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 90, 30), Color3.fromRGB(160, 20, 5)),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0)}),
			Lifetime = NumberRange.new(0.8, 1.5), Rate = 3, Speed = NumberRange.new(0),
			Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		})
	elseif nom == "Bronze" then
		emetteur(coeur, {
			Name = "Braises", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 210, 130), Color3.fromRGB(255, 100, 30)),
			Size = NumberSequence.new(0.2, 0), Lifetime = NumberRange.new(1, 2), Rate = 12,
			Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, 2, 0),
		})
		emetteur(coeur, {
			Name = "Coulees", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 70, 15)),
			Size = NumberSequence.new(0.18, 0.08), Lifetime = NumberRange.new(0.6, 1),
			Rate = 4, Speed = NumberRange.new(0.2, 0.5), EmissionDirection = Enum.NormalId.Bottom,
			Acceleration = Vector3.new(0, -18, 0),
		})
	elseif nom == "Fer" then
		emetteur(coeur, {
			Name = "Scintillement", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(160, 205, 255)),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.5), NumberSequenceKeypoint.new(1, 0)}),
			Lifetime = NumberRange.new(0.6, 1.1), Rate = 7, Speed = NumberRange.new(0, 0.2),
			Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
		emetteur(coeur, {
			Name = "PoussiereBleue", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(190, 225, 255), Color3.fromRGB(80, 140, 255)),
			Size = NumberSequence.new(0.12, 0), Lifetime = NumberRange.new(1, 2), Rate = 5,
			Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, 0.8, 0),
		})
	elseif nom == "Gold" then
		emetteur(coeur, {
			Name = "Etoiles", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 200, 60)),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.7), NumberSequenceKeypoint.new(1, 0)}),
			Lifetime = NumberRange.new(0.6, 1.2), Rate = 14, Speed = NumberRange.new(0, 0.3),
			Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
		emetteur(coeur, {
			Name = "PoussiereOr", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 170, 30)),
			Size = NumberSequence.new(0.16, 0), Lifetime = NumberRange.new(1.2, 2.2), Rate = 16,
			Speed = NumberRange.new(0.5, 1.2), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, 1, 0),
		})
		emetteur(coeur, {
			Name = "Halo", Texture = TEX_ETINCELLE,
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 60)),
			Size = NumberSequence.new(6 * s),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 1)}),
			Lifetime = NumberRange.new(1.2), Rate = 2, Speed = NumberRange.new(0), LockedToPart = true,
		})
	end
	if def.lumiere then
		local l = Instance.new("PointLight")
		l.Color = def.lumiere
		l.Brightness = (nom == "Gold") and 3 or 1.6
		l.Range = (nom == "Gold") and 16 or 12
		l.Parent = coeur
	end
end

-- Étiquette au-dessus du minerai : nom + rareté
local function etiquette(coeur: Part, nom: string)
	local def = MINERAIS[nom]
	local b = Instance.new("BillboardGui")
	b.Name = "Etiquette"
	b.Size = UDim2.fromOffset(170, 60)
	b.StudsOffsetWorldSpace = Vector3.new(0, 2.8 * def.taille, 0)
	b.MaxDistance = 50
	b.LightInfluence = 0
	b.Parent = coeur

	local cadre = Instance.new("Frame")
	cadre.Size = UDim2.new(1, 0, 0, 34)
	cadre.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	cadre.BackgroundTransparency = 0.15
	cadre.Parent = b
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0, 10)
	coin.Parent = cadre
	local bord = Instance.new("UIStroke")
	bord.Color = def.couleurRarete
	bord.Thickness = 2.5
	bord.Parent = cadre

	local titre = Instance.new("TextLabel")
	titre.Size = UDim2.fromScale(1, 1)
	titre.BackgroundTransparency = 1
	titre.Font = Enum.Font.GothamBlack
	titre.TextSize = 22
	titre.TextColor3 = Color3.new(1, 1, 1)
	titre.Text = nom
	titre.Parent = cadre

	local rarete = Instance.new("TextLabel")
	rarete.Position = UDim2.fromOffset(0, 36)
	rarete.Size = UDim2.new(1, 0, 0, 22)
	rarete.BackgroundTransparency = 1
	rarete.Font = Enum.Font.GothamBold
	rarete.TextSize = 17
	rarete.TextColor3 = def.couleurRarete
	rarete.TextStrokeTransparency = 0.4
	rarete.Text = def.rarete
	rarete.Parent = b
end

local function tirerType(): string
	local total = 0
	for _, nom in ORDRE do
		total += MINERAIS[nom].chance
	end
	local r = math.random() * total
	for _, nom in ORDRE do
		r -= MINERAIS[nom].chance
		if r <= 0 then
			return nom
		end
	end
	return "Charbon"
end

local surCasse = {}

-- Une fissure lumineuse apparaît sur le minerai à chaque coup reçu
local function fissure(modele: Model, coeur: Part, def)
	local dir = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1).Unit
	local pos = coeur.Position + dir * coeur.Size.Y * 0.56
	local tangente = dir:Cross(Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)).Unit
	local longueur = (0.6 + math.random() * 0.8) * def.taille
	local f = piece(modele, "Fissure", Vector3.new(0.08, 0.08, longueur), CFrame.lookAt(pos, pos + tangente), def.veine, Enum.Material.Neon)
	f.CanQuery = false
	f.CanCollide = false
	f.Transparency = 1
	TweenService:Create(f, TweenInfo.new(0.15), {Transparency = 0}):Play()
end

local function apparaitre(sol: CFrame, typeFixe: string?)
	local nom = (typeFixe and MINERAIS[typeFixe]) and typeFixe or tirerType()
	local def = MINERAIS[nom]
	local modele, coeur = construire(nom, sol)
	coeur:SetAttribute("Type", nom)
	coeur:SetAttribute("Taille", def.taille)
	coeur:SetAttribute("PV", def.pv)
	coeur:SetAttribute("PVMax", def.pv)
	effets(coeur, nom)
	etiquette(coeur, nom)
	modele.Parent = dossier

	-- Le minerai pousse depuis le sol
	local echelle = Instance.new("NumberValue")
	echelle.Value = 0.2
	modele:ScaleTo(0.2)
	echelle.Changed:Connect(function(v)
		if modele.Parent then
			modele:ScaleTo(v)
		end
	end)
	TweenService:Create(echelle, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = 1}):Play()
	Debris:AddItem(echelle, 1)

	CollectionService:AddTag(coeur, CONFIG.TAG_MINERAI)

	local pvAvant = def.pv
	coeur:GetAttributeChangedSignal("PV"):Connect(function()
		local pv = coeur:GetAttribute("PV") or 0
		local perdus = math.max(0, pvAvant - pv)
		pvAvant = pv
		if pv > 0 then
			for _ = 1, perdus * 2 do
				fissure(modele, coeur, def)
			end
		end
	end)

	surCasse[coeur] = function()
		-- La pioche a cassé le cœur : le reste du rocher disparaît, puis un minerai repousse
		local b = coeur:FindFirstChild("Etiquette")
		if b then b.Enabled = false end
		for _, d in modele:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				d.Enabled = false
			elseif d:IsA("PointLight") then
				TweenService:Create(d, TweenInfo.new(0.4), {Brightness = 0}):Play()
			elseif d:IsA("BasePart") and d ~= coeur then
				d.CanCollide = false
				TweenService:Create(d, TweenInfo.new(0.35), {Transparency = 1, Size = d.Size * 0.5}):Play()
			end
		end
		Debris:AddItem(modele, 1.5)
		task.delay(CONFIG.REAPPARITION, function()
			apparaitre(sol, typeFixe)
		end)
	end
end

CollectionService:GetInstanceRemovedSignal(CONFIG.TAG_MINERAI):Connect(function(instance)
	local f = surCasse[instance]
	if f then
		surCasse[instance] = nil
		f()
	end
end)

-- ===== Récompenses =====
-- Les Pièces sont sauvegardées par le module Donnees (il remet le compteur à la valeur sauvegardée au chargement)
local Donnees = require(script.Parent:WaitForChild("Donnees"))

local function surJoueur(joueur: Player)
	local stats = joueur:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = joueur
	end
	if not stats:FindFirstChild(CONFIG.MONNAIE) then
		local v = Instance.new("IntValue")
		v.Name = CONFIG.MONNAIE
		v.Parent = stats
	end
end
Players.PlayerAdded:Connect(surJoueur)
for _, joueur in Players:GetPlayers() do
	surJoueur(joueur)
end

task.spawn(function()
	local evenement = ServerStorage:WaitForChild("MineraiCasse", 60)
	if not evenement then
		warn("Minerais : script des pioches introuvable, pas de récompense.")
		return
	end
	evenement.Event:Connect(function(joueur, bloc)
		local nom = bloc and bloc:GetAttribute("Type")
		local def = nom and MINERAIS[nom]
		if not joueur or not def then return end
		if not joueur:GetAttribute("DonneesChargees") then return end -- sinon le chargement écraserait ce gain
		if CONFIG.GAIN_DIRECT then
			local stats = joueur:FindFirstChild("leaderstats")
			local v = stats and stats:FindFirstChild(CONFIG.MONNAIE)
			if v then
				v.Value += def.valeur
			end
		end
		Donnees.ajouterMinerai(joueur, nom, 1) -- au sac : à vendre chez Gaspard ou à forger chez Brom
		Donnees.decouvrirMinerai(joueur, nom) -- 1re fois : plus de silhouette noire dans le menu des grottes
	end)
end)

-- ===== Apparition =====
-- On attend que la carte soit construite (les points "SpawnMinerai" sont dans la caverne)
local attente = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - attente < 60 do
	task.wait(0.25)
end
local points = CollectionService:GetTagged(CONFIG.TAG_SPAWN)
-- Le sol voxel de la caverne peut être plus haut que le point théorique à Y=-60.
-- Ne corrige que ses points de démonstration pour préserver les autres zones.
local function solDuPoint(point: BasePart): CFrame
	local bas = point.Position - Vector3.new(0, point.Size.Y / 2, 0)
	local carte = workspace:FindFirstChild("Carte")
	local mine = carte and carte:FindFirstChild("Mine")
	local pointsCaverne = mine and mine:FindFirstChild("PointsMinerai")
	if pointsCaverne and point:IsDescendantOf(pointsCaverne) then
		local filtre = RaycastParams.new()
		filtre.FilterType = Enum.RaycastFilterType.Include
		filtre.FilterDescendantsInstances = {workspace.Terrain}
		local resultat = workspace:Raycast(bas + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), filtre)
		if resultat and resultat.Material ~= Enum.Material.Water and resultat.Position.Y >= bas.Y then
			bas = Vector3.new(bas.X, resultat.Position.Y, bas.Z)
		end
	end
	return CFrame.new(bas)
end
if #points == 0 then
	for i, nom in ORDRE do
		local x = (i - 2.5) * CONFIG.DEMO_ECART
		apparaitre(CFrame.new(CONFIG.DEMO_POSITION + Vector3.new(x, 0, 0)), nom)
	end
else
	for _, p in points do
		if p:IsA("BasePart") then
			p.Transparency = 1
			p.CanCollide = false
			p.CanQuery = false
			apparaitre(solDuPoint(p), p:GetAttribute("Type"))
		end
	end
end
