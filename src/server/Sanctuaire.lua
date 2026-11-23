-- Sanctuaire de la grotte −50 m · MODULE SERVEUR (ServerScriptService › Jeu › Sanctuaire)
-- Le palier 1 n'a pas de boss : le temple du fond est un sanctuaire. Quand un joueur de l'expédition franchit
-- l'arche runique, le sanctuaire s'éveille (attribut « SanctuaireEveil » → cinématique côté client : runes qui
-- s'allument, yeux des statues qui s'embrasent), puis une vague de gardiens (mobs du palier, plus coriaces) surgit
-- dans le temple. Quand ils sont tous vaincus, le coffre du sanctuaire s'ouvre : chaque joueur peut l'ouvrir une
-- fois (pièces, bronze et un fragment de la carte naine).
--   Sanctuaire.preparer(exp) -- appelé par Grottes.server.lua après MobsGrotte.peupler (exp = expédition)

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local MobsGrotte = require(script.Parent.MobsGrotte)
local Donnees = require(script.Parent.Donnees)
local CarteNaine = require(script.Parent.CarteNaine)

local Sanctuaire = {}

local DISTANCE_EVEIL = 22 -- studs (à plat) autour du pied de l'arche
local DUREE_CINEMATIQUE = 4.2 -- les gardiens surgissent à la fin de la cinématique
local GARDIENS = { -- mobs du palier 1, en plus coriaces (pv ×3, un peu plus grands)
	{id = "MineurZombie", poids = 3, pv = 110, degats = 10, vitesse = 9, portee = 4.8, recharge = 1.4, echelle = 1.25},
	{id = "ChauveSourisCave", poids = 1, pv = 50, degats = 6, vitesse = 14, portee = 4, recharge = 1.2, echelle = 1.2},
}
local RECOMPENSE = {pieces = 40, minerai = "Bronze", nombre = 3}

local function plat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function ouvrirCoffre(modele: Model)
	if modele:GetAttribute("CoffreOuvert") then
		return
	end
	modele:SetAttribute("CoffreOuvert", true)
	modele:SetAttribute("GardiensRestants", 0)
	local coffre = modele:FindFirstChild("CoffreSanctuaire", true)
	if not coffre then
		return
	end
	local couvercle = coffre:FindFirstChild("Couvercle") :: BasePart?
	local charniere = couvercle and couvercle:GetAttribute("Charniere")
	if couvercle and typeof(charniere) == "CFrame" then
		local fin = charniere * CFrame.Angles(math.rad(105), 0, 0) * CFrame.new(0, 0.35, -1.45)
		TweenService:Create(couvercle, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = fin}):Play()
	end
	local tresor = coffre:FindFirstChild("Tresor") :: BasePart?
	if tresor then
		TweenService:Create(tresor, TweenInfo.new(1), {Transparency = 0.15}):Play()
		local l = tresor:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = true
		end
		local e = tresor:FindFirstChildOfClass("ParticleEmitter")
		if e then
			e.Enabled = true
		end
	end
	for _, d in coffre:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d.Enabled = true
		end
	end
end

local function eveiller(exp, modele: Model)
	modele:SetAttribute("SanctuaireEveil", workspace:GetServerTimeNow())
	task.wait(DUREE_CINEMATIQUE)
	if not modele.Parent or exp.fini then
		return
	end
	local h = exp.mobs
	local temple = modele:GetAttribute("TempleSanctuaire")
	if not (h and h.actif and typeof(temple) == "Vector3") then
		ouvrirCoffre(modele)
		return
	end
	-- vague de gardiens : le tirage de MobsGrotte.groupe se fait dans h.niveau.mobs, remplacé le temps de l'appel
	local avant = #h.mobs
	local niveau = h.niveau
	h.niveau = setmetatable({mobs = GARDIENS, mobsZones = false}, {__index = niveau}) -- pas les mobs du temple
	local ok = pcall(MobsGrotte.groupe, h, temple, 3 + math.min(#exp.joueurs - 1, 2), temple)
	h.niveau = niveau
	local gardiens = {}
	for i = avant + 1, #h.mobs do
		local m = h.mobs[i]
		table.insert(gardiens, m)
		m.modele:SetAttribute("Gardien", true)
		local l = Instance.new("PointLight")
		l.Color, l.Brightness, l.Range = Color3.fromRGB(165, 90, 255), 1.2, 10
		l.Parent = m.root
	end
	if not ok or #gardiens == 0 then
		ouvrirCoffre(modele)
		return
	end
	while modele.Parent and not exp.fini do
		local restants = 0
		for _, m in gardiens do
			if not m.mort then
				restants += 1
			end
		end
		modele:SetAttribute("GardiensRestants", restants)
		if restants == 0 then
			ouvrirCoffre(modele)
			return
		end
		task.wait(0.5)
	end
end

function Sanctuaire.preparer(exp)
	local grotte = exp and exp.grotte
	local modele = grotte and grotte.modele
	if not modele or modele:GetAttribute("Niveau") ~= 1 then
		return
	end
	local arche = modele:GetAttribute("ArcheSanctuaire")
	if typeof(arche) ~= "Vector3" then
		arche = modele:GetAttribute("TempleSanctuaire") -- pas d'arche posée : le temple lui-même déclenche l'éveil
	end
	if typeof(arche) ~= "Vector3" then
		return
	end
	task.spawn(function()
		while modele.Parent and not exp.fini do
			for _, j in exp.joueurs do
				local perso = j.Character
				local r = perso and perso:FindFirstChild("HumanoidRootPart")
				if r and plat(r.Position - arche).Magnitude < DISTANCE_EVEIL and math.abs(r.Position.Y - arche.Y) < 16 then
					eveiller(exp, modele)
					return
				end
			end
			task.wait(0.3)
		end
	end)
end

-- Ouverture du coffre : une fois par joueur
ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	if not invite:GetAttribute("CoffreSanctuaire") then
		return
	end
	local caisse = invite.Parent
	local coffre = caisse and caisse.Parent
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (caisse and caisse:IsA("BasePart") and coffre and r) then
		return
	end
	if (r.Position - caisse.Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	local ouverts = coffre:GetAttribute("OuvertPar")
	ouverts = if type(ouverts) == "string" then ouverts else ","
	if ouverts:find("," .. joueur.UserId .. ",", 1, true) then
		return
	end
	coffre:SetAttribute("OuvertPar", ouverts .. joueur.UserId .. ",")
	CarteNaine.crediter(joueur, RECOMPENSE.pieces)
	Donnees.ajouterMinerai(joueur, RECOMPENSE.minerai, RECOMPENSE.nombre)
	CarteNaine.remote:FireClient(joueur, "Coffre", {pieces = RECOMPENSE.pieces, minerai = RECOMPENSE.minerai, nombre = RECOMPENSE.nombre})
	task.delay(1.2, CarteNaine.donnerFragment, joueur, "coffre")
end)

return Sanctuaire
