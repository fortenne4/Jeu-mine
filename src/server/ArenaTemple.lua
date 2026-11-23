-- Arène du temple (grotte −50 m) · MODULE SERVEUR (ServerScriptService › Jeu › ArenaTemple)
-- Une fois le coffre du sanctuaire ouvert, le gong du temple (invite « Frapper le gong », posé par GrotteLueurs)
-- s'éveille. Le frapper lance l'arène : 8 vagues de plus en plus dures de mobs du palier (crabes, golems
-- champignons, spectres nains, chauves-souris), qui gardent le temple. Chaque vague vaincue rapporte des pièces
-- (une seule fois par vague et par expédition : refaire l'arène ne paie que les vagues jamais atteintes) ;
-- les 8 vagues = bonus et un fragment de la carte naine. Si plus aucun joueur vivant n'est dans le temple,
-- l'arène s'arrête. La meilleure vague atteinte est sauvegardée (Donnees.recordArene, attribut « RecordArene »).
-- Affichage : RemoteEvent « AreneTemple » (ArenaTemple.client.lua) ; attributs du modèle de la grotte
-- « AreneVague », « AreneRestants » (0 = pas d'arène en cours).
--   ArenaTemple.preparer(exp) -- appelé par Grottes.server.lua après Sanctuaire.preparer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))
local MobsGrotte = require(script.Parent.MobsGrotte)
local CarteNaine = require(script.Parent.CarteNaine)
local Donnees = require(script.Parent.Donnees)

local ArenaTemple = {}

local VAGUES = 8
local PAUSE = 6 -- s entre deux vagues
local RAYON = 50 -- un joueur à plus de ça du temple n'est plus dans l'arène
local RECHARGE = 20 -- s avant de pouvoir refrapper le gong
local PIECES_VAGUE = 10 -- × numéro de la vague
local BONUS_VICTOIRE = 100

local remote = ReplicatedStorage:FindFirstChild("AreneTemple")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AreneTemple"
	remote.Parent = ReplicatedStorage
end

local rng = Random.new()
local expeditions = {} -- [modèle de la grotte] = exp

-- composition des vagues : {id, poids} ; les statistiques viennent des mobs à thème du palier 1
local COMPOSITION = {
	{{"CrabeLueur", 3}, {"ChauveSourisCave", 1}},
	{{"CrabeLueur", 3}, {"ChauveSourisCave", 1}},
	{{"CrabeLueur", 2}, {"GolemChampignon", 1}, {"SpectreNain", 1}},
	{{"CrabeLueur", 2}, {"GolemChampignon", 1}, {"SpectreNain", 1}},
	{{"GolemChampignon", 2}, {"SpectreNain", 2}, {"CrabeLueur", 1}},
	{{"GolemChampignon", 2}, {"SpectreNain", 2}, {"CrabeLueur", 1}},
	{{"GolemChampignon", 2}, {"SpectreNain", 3}},
	{{"GolemChampignon", 2}, {"SpectreNain", 3}},
}

local function definition(id: string)
	local niveau = Grottes.niveau(1)
	for _, liste in niveau.mobsZones or {} do
		for _, d in liste do
			if d.id == id then
				return d
			end
		end
	end
	for _, d in niveau.mobs do
		if d.id == id then
			return d
		end
	end
	return nil
end

local function mobsVague(k: number)
	local liste = {}
	local echelle = 1 + 0.14 * (k - 1)
	for _, e in COMPOSITION[math.min(k, #COMPOSITION)] do
		local d = definition(e[1])
		if d then
			local c = table.clone(d)
			c.poids = e[2]
			c.pv = math.floor(d.pv * echelle)
			c.degats = math.floor(d.degats * (1 + 0.06 * (k - 1)) + 0.5)
			table.insert(liste, c)
		end
	end
	return liste
end

local function vivant(j: Player): BasePart?
	local perso = j.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return perso:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function dansArene(exp, temple: Vector3): {Player}
	local t = {}
	for _, j in exp.joueurs do
		local r = vivant(j)
		if r and (r.Position - temple).Magnitude < RAYON then
			table.insert(t, j)
		end
	end
	return t
end

local function annoncer(exp, genre: string, d: {[string]: any})
	for _, j in exp.joueurs do
		if j.Parent then
			remote:FireClient(j, genre, d)
		end
	end
end

local function invitesGong(modele: Model, actif: boolean)
	for _, d in modele:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("Arene") then
			d.Enabled = actif
		end
	end
end

local function runeGong(modele: Model, allume: boolean)
	for _, d in modele:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "RuneGong" then
			local c = d:GetAttribute("Couleur")
			d.Color = if allume and typeof(c) == "Color3" then c else Color3.fromRGB(45, 30, 60)
		end
	end
end

-- points d'apparition autour du temple (au sol, en vue du centre)
local function pointsAutour(exp, temple: Vector3, n: number): {Vector3}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	params.IgnoreWater = true
	local t = {}
	local haut = temple + Vector3.new(0, 3, 0)
	for _ = 1, 40 do
		if #t >= n then
			break
		end
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(9, 16)
		local vise = haut + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if not workspace:Raycast(haut, vise - haut, params) then
			local sol = workspace:Raycast(vise, Vector3.new(0, -12, 0), params)
			if sol then
				table.insert(t, sol.Position)
			end
		end
	end
	if #t == 0 then
		table.insert(t, temple)
	end
	return t
end

local function lancer(exp, modele: Model, temple: Vector3)
	local h = exp.mobs
	if not (h and h.actif) or modele:GetAttribute("AreneVague") then
		return
	end
	invitesGong(modele, false)
	runeGong(modele, true)
	modele:SetAttribute("AreneVague", 0)
	annoncer(exp, "Debut", {total = VAGUES})
	task.wait(3)
	local atteinte = 0
	local issue = "defaite"
	for k = 1, VAGUES do
		if exp.fini or not h.actif then
			issue = "fin"
			break
		end
		local presents = dansArene(exp, temple)
		if #presents == 0 then
			break
		end
		modele:SetAttribute("AreneVague", k)
		annoncer(exp, "Vague", {n = k, total = VAGUES})
		task.wait(1.5)
		-- apparition par petits groupes autour du temple ; les mobs gardent le temple (laisse de MobsGrotte)
		local nombre = math.min(2 + k, 8) + math.min(#presents - 1, 2)
		local avant = #h.mobs
		local niveau = h.niveau
		h.niveau = setmetatable({mobs = mobsVague(k), mobsZones = false}, {__index = niveau})
		local reste = nombre
		for _, p in pointsAutour(exp, temple, math.ceil(nombre / 2)) do
			if reste <= 0 then
				break
			end
			local n = math.min(reste, 2)
			pcall(MobsGrotte.groupe, h, p, n, temple)
			reste -= n
		end
		h.niveau = niveau
		local vague = {}
		for i = avant + 1, #h.mobs do
			local m = h.mobs[i]
			m.modele:SetAttribute("Arene", true)
			table.insert(vague, m)
		end
		-- combat
		local vide = 0
		while true do
			task.wait(0.5)
			if exp.fini or not h.actif then
				issue = "fin"
				break
			end
			local restants = 0
			for _, m in vague do
				if not m.mort and m.modele.Parent then
					restants += 1
				end
			end
			modele:SetAttribute("AreneRestants", restants)
			if restants == 0 then
				break
			end
			if #dansArene(exp, temple) == 0 then
				vide += 0.5
				if vide >= 4 then
					break
				end
			else
				vide = 0
			end
		end
		local restants = 0
		for _, m in vague do
			if not m.mort and m.modele.Parent then
				restants += 1
			end
		end
		if restants > 0 or issue == "fin" then
			-- défaite (ou fin d'expédition) : les mobs de la vague disparaissent
			for _, m in vague do
				if not m.mort and m.modele.Parent then
					m.modele:Destroy()
				end
			end
			break
		end
		atteinte = k
		-- récompense : seulement les vagues jamais payées pendant cette expédition
		local payee = (exp.arenePayee or 0) >= k
		local pieces = if payee then 0 else PIECES_VAGUE * k
		exp.arenePayee = math.max(exp.arenePayee or 0, k)
		for _, j in dansArene(exp, temple) do
			if pieces > 0 then
				CarteNaine.crediter(j, pieces)
			end
		end
		annoncer(exp, "VagueFinie", {n = k, total = VAGUES, pieces = pieces})
		if k == VAGUES then
			issue = "victoire"
			break
		end
		task.wait(PAUSE)
	end
	-- fin de l'arène
	modele:SetAttribute("AreneRestants", 0)
	modele:SetAttribute("AreneVague", nil)
	runeGong(modele, false)
	if issue ~= "fin" then
		local premiere = not exp.areneVictoire
		for _, j in exp.joueurs do
			if j.Parent then
				if Donnees.recordArene(j, atteinte) then
					remote:FireClient(j, "Record", {vague = atteinte})
				end
			end
		end
		if issue == "victoire" then
			exp.areneVictoire = true
			for _, j in dansArene(exp, temple) do
				if premiere then
					CarteNaine.crediter(j, BONUS_VICTOIRE)
					task.delay(2, CarteNaine.donnerFragment, j, "arene")
				end
			end
			annoncer(exp, "Victoire", {vague = atteinte, bonus = if premiere then BONUS_VICTOIRE else 0})
		else
			annoncer(exp, "Defaite", {vague = atteinte})
		end
	end
	task.delay(RECHARGE, function()
		if modele.Parent and not exp.fini then
			invitesGong(modele, true)
		end
	end)
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	if not invite:GetAttribute("Arene") then
		return
	end
	local dossier = workspace:FindFirstChild("Grottes")
	local modele = invite:FindFirstAncestorWhichIsA("Model")
	while modele and modele.Parent ~= dossier do
		modele = modele:FindFirstAncestorWhichIsA("Model")
	end
	local exp = modele and expeditions[modele]
	local temple = modele and modele:GetAttribute("TempleSanctuaire")
	if not (exp and typeof(temple) == "Vector3") or not table.find(exp.joueurs, joueur) then
		return
	end
	local r = vivant(joueur)
	if not r or (r.Position - invite.Parent.Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	task.spawn(lancer, exp, modele, temple)
end)

function ArenaTemple.preparer(exp)
	local modele = exp and exp.grotte and exp.grotte.modele
	if not modele or modele:GetAttribute("Niveau") ~= 1 or not modele:GetAttribute("GongArene") then
		return
	end
	expeditions[modele] = exp
	modele.AncestryChanged:Connect(function()
		if not modele.Parent then
			expeditions[modele] = nil
		end
	end)
	task.spawn(function()
		-- le gong s'éveille quand le coffre du sanctuaire est ouvert
		while modele.Parent and not exp.fini and not modele:GetAttribute("CoffreOuvert") do
			task.wait(1)
		end
		if modele.Parent and not exp.fini then
			invitesGong(modele, true)
			annoncer(exp, "Eveil", {})
		end
	end)
end

return ArenaTemple
