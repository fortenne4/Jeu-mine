-- Boussole des feux follets (grotte −50 m) · SCRIPT CLIENT
-- Touche F (bouton « Boussole » sur mobile, Y à la manette) dans une grotte du palier 1 : un feu follet doré
-- sort du joueur et le guide, par le réseau des galeries (dossier « Guide », plus court chemin), vers la cachette la plus
-- proche (fragment de carte) qu'il n'a pas encore ramassée. Plus on approche, plus il pulse vite ; arrivé, il tourne au-dessus de la
-- cachette. Il dure 25 s, puis la boussole se recharge 40 s. Une petite plaque en bas indique l'état.
-- Tout est local ; la cachette reste ramassée par l'invite « Ramasser » (CarteNaine.lua côté serveur).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait, texte = UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local terrain = workspace.Terrain

local ACTION = "BoussoleFeux"
local DUREE, RECHARGE = 25, 40
local DORE = Color3.fromRGB(255, 214, 110)
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
params.IgnoreWater = true

local grotte: Model? = nil
local actif = false -- feu follet sorti
local finActif, finRecharge = 0, 0
local feu: BasePart? = nil
local cible: Model? = nil
local chemin: {Vector3} = {}
local posFeu = Vector3.zero
local reseau: {pts: {Vector3}, voisins: {{number}}}? = nil

-- ================= Plaque d'état =================
local gui = creer("ScreenGui", {Name = "BoussoleFeux", ResetOnSpawn = false, DisplayOrder = 5, Enabled = false,
	Parent = joueur:WaitForChild("PlayerGui")})
local plaque = creer("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -14), Size = UDim2.fromOffset(300, 34),
	BackgroundColor3 = Color3.fromRGB(20, 16, 30), BackgroundTransparency = 0.25, Parent = gui},
	{coin(0.4), trait(DORE, 1.5, 0.35)})
local icone = creer("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = DORE, Parent = plaque}, {coin(1)})
local etiquette = texte({Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 236, 190), TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.new(0, 32, 0.18, 0), Size = UDim2.new(1, -40, 0.64, 0), Parent = plaque}, 16)

-- ================= Outils =================
local function grotteAutour(pos: Vector3): Model?
	local g = workspace:FindFirstChild("Grottes")
	if not g then
		return nil
	end
	for _, m in g:GetChildren() do
		local c, d = m:GetAttribute("Centre"), m:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return m
			end
		end
	end
	return nil
end

local function prise(m: Instance): boolean
	local p = m:GetAttribute("PrisPar")
	return type(p) == "string" and p:find("," .. joueur.UserId .. ",", 1, true) ~= nil
end

local function cachettes(): {Model}
	local t = {}
	if grotte then
		for _, m in CollectionService:GetTagged("FragmentCarte") do
			-- la cachette de la salle secrète ne compte qu'une fois la porte runique ouverte
			local secrete = m:GetAttribute("Cachette") == "secret" and not grotte:GetAttribute("PorteOuverte")
			if m:IsA("Model") and m:IsDescendantOf(grotte) and not prise(m) and not secrete then
				table.insert(t, m)
			end
		end
	end
	return t
end

local function racine(): BasePart?
	return joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function libre(depuis: Vector3, vers: Vector3): Vector3
	local d = vers - depuis
	if d.Magnitude < 0.01 then
		return vers
	end
	local hit = workspace:Raycast(depuis, d, params)
	return if hit then hit.Position - d.Unit * 1.5 else vers
end

-- ================= Feu follet =================
local function creerFeu(depart: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "FeuBoussole"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * 1.1
	p.Material = Enum.Material.Neon
	p.Color = DORE
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Position = depart
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = DORE, 1.2, 20, false
	l.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Color = ColorSequence.new(Color3.fromRGB(255, 245, 210), DORE)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.8, 1.5)
	e.Rate = 18
	e.Speed = NumberRange.new(0.2, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = p
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0.4, 0), Vector3.new(0, -0.4, 0)
	a0.Parent, a1.Parent = p, p
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(DORE)
	t.LightEmission, t.LightInfluence = 1, 0
	t.Transparency = NumberSequence.new(0.2, 1)
	t.Lifetime = 1.1
	t.FaceCamera = true
	t.WidthScale = NumberSequence.new(1, 0)
	t.Parent = p
	p.Parent = workspace
	return p
end

local function eclat(pos: Vector3, n: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_ETINCELLE
	e.Color = ColorSequence.new(DORE)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 3
	e.Rate = 0
	e.Parent = a
	e:Emit(n)
	Debris:AddItem(a, 2)
end

local function eteindre(rechargement: boolean)
	if feu then
		eclat(feu.Position, 30)
		feu:Destroy()
		feu = nil
	end
	actif, cible = false, nil
	table.clear(chemin)
	if rechargement then
		finRecharge = os.clock() + RECHARGE
	end
end

-- réseau des galeries : chaque galerie va d'un centre de salle à un autre ; les points à moins de 3 studs
-- sont fusionnés, ce qui relie les galeries entre elles aux salles
local function construireReseau(g: Model)
	local guide = g:FindFirstChild("Guide")
	local nR = guide and guide:GetAttribute("R")
	if not guide or type(nR) ~= "number" then
		return nil
	end
	local pts, voisins = {}, {}
	local function noeud(p: Vector3): number
		for i, q in pts do
			if (q - p).Magnitude < 3 then
				return i
			end
		end
		table.insert(pts, p)
		voisins[#pts] = {}
		return #pts
	end
	for k = 1, nR do
		local prec = nil
		for i = 1, guide:GetAttribute("R" .. k .. "N") or 0 do
			local p = guide:GetAttribute("R" .. k .. "_" .. i)
			if typeof(p) == "Vector3" then
				local id = noeud(p)
				if prec and prec ~= id then
					table.insert(voisins[prec], id)
					table.insert(voisins[id], prec)
				end
				prec = id
			end
		end
	end
	return {pts = pts, voisins = voisins}
end

local HAUT = Vector3.new(0, 2.5, 0)
local function voit(a: Vector3, b: Vector3): boolean
	return workspace:Raycast(a + HAUT, b - a, params) == nil
end

-- point du réseau le plus proche qu'on voit depuis pos (pas un point de la galerie voisine, derrière la roche)
local function noeudProche(pos: Vector3): number?
	if not reseau then
		return nil
	end
	local tries = {}
	for i, p in reseau.pts do
		table.insert(tries, {i = i, d = (p - pos).Magnitude})
	end
	table.sort(tries, function(a, b)
		return a.d < b.d
	end)
	for k = 1, math.min(10, #tries) do
		if voit(pos, reseau.pts[tries[k].i]) then
			return tries[k].i
		end
	end
	return if tries[1] then tries[1].i else nil
end

-- plus court chemin (Dijkstra : quelques centaines de points)
local function plusCourt(a: number, b: number): {Vector3}
	local r = reseau :: any
	local dist, prec, fait = {[a] = 0}, {}, {}
	while true do
		local u, du = nil, math.huge
		for i, d in dist do
			if not fait[i] and d < du then
				u, du = i, d
			end
		end
		if not u or u == b then
			break
		end
		fait[u] = true
		for _, v in r.voisins[u] do
			local nd = du + (r.pts[u] - r.pts[v]).Magnitude
			if nd < (dist[v] or math.huge) then
				dist[v], prec[v] = nd, u
			end
		end
	end
	if not dist[b] then
		return {}
	end
	local liste, i = {}, b
	while i do
		table.insert(liste, 1, r.pts[i])
		i = prec[i]
	end
	return liste
end

-- trajet de pos à but : tout droit si la cachette est en vue, sinon par le réseau des galeries
local function trajet(pos: Vector3, but: Vector3): {Vector3}
	if (but - pos).Magnitude < 60 and voit(pos, but) then
		return {pos, but}
	end
	local pts = {pos}
	local a, b = noeudProche(pos), noeudProche(but)
	if a and b then
		for _, p in plusCourt(a, b) do
			table.insert(pts, p)
		end
	end
	table.insert(pts, but) -- sans réseau : tout droit
	return pts
end

local function longueur(pts: {Vector3}): number
	local l = 0
	for i = 2, #pts do
		l += (pts[i] - pts[i - 1]).Magnitude
	end
	return l
end

-- chemin vers la cachette (recalculé toutes les 2,5 s pendant que le feu est sorti)
local function calculer()
	local r = racine()
	if r and cible and cible.Parent then
		chemin = trajet(r.Position, cible:GetPivot().Position)
	end
end

local function lancer()
	local r = racine()
	if actif or not grotte or not r or os.clock() < finRecharge then
		return
	end
	local liste = cachettes()
	if #liste == 0 then
		return
	end
	-- la plus proche à pied (par les galeries), pas à vol d'oiseau
	local meilleure, lmin = liste[1], math.huge
	for _, m in liste do
		local l = longueur(trajet(r.Position, m:GetPivot().Position))
		if l < lmin then
			meilleure, lmin = m, l
		end
	end
	cible = meilleure
	actif = true
	finActif = os.clock() + DUREE
	posFeu = r.Position + Vector3.new(0, 2.5, 0)
	feu = creerFeu(posFeu)	eclat(posFeu, 24)
	UI.jouer("ouvrir", 1.3)
	task.spawn(function()
		while actif and cible do
			calculer()
			task.wait(2.5)
		end
	end)
end

ContextActionService:BindAction(ACTION, function(_, etat)
	if etat == Enum.UserInputState.Begin then
		lancer()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY)

local boutonTactile = false
local function boutonMobile(montrer: boolean)
	if montrer == boutonTactile then
		return
	end
	boutonTactile = montrer
	ContextActionService:UnbindAction(ACTION)
	ContextActionService:BindAction(ACTION, function(_, etat)
		if etat == Enum.UserInputState.Begin then
			lancer()
		end
		return Enum.ContextActionResult.Pass
	end, montrer, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
	if montrer then
		ContextActionService:SetTitle(ACTION, "Boussole")
		ContextActionService:SetPosition(ACTION, UDim2.new(1, -170, 1, -150))
	end
end

-- point du chemin à suivre : le premier à plus de 9 studs du joueur, au-delà du point le plus proche
local function pointSuivant(pos: Vector3): Vector3?
	if #chemin == 0 then
		return nil
	end
	local i0, dmin = 1, math.huge
	for i, p in chemin do
		local d = (p - pos).Magnitude
		if d < dmin then
			i0, dmin = i, d
		end
	end
	for i = i0, #chemin do
		if (chemin[i] - pos).Magnitude > 9 then
			return chemin[i]
		end
	end
	return chemin[#chemin]
end

local verif = math.huge
RunService.RenderStepped:Connect(function(dt)
	local r = racine()
	verif += dt
	if verif > 0.5 then
		verif = 0
		local g = r and grotteAutour(r.Position)
		if g and g:GetAttribute("Niveau") ~= 1 then
			g = nil
		end
		if g ~= grotte then
			eteindre(false)
			grotte = g
			reseau = if g then construireReseau(g) else nil
			gui.Enabled = g ~= nil
			boutonMobile(g ~= nil and game:GetService("UserInputService").TouchEnabled)
		end
		-- plaque d'état
		if grotte then
			local n = #cachettes()
			local maintenant = os.clock()
			if n == 0 then
				etiquette.Text = "Boussole : toutes les cachettes sont trouvées"
				icone.BackgroundTransparency = 0.7
			elseif actif then
				etiquette.Text = "Suis le feu follet doré… (" .. math.ceil(finActif - maintenant) .. " s)"
				icone.BackgroundTransparency = 0
			elseif maintenant < finRecharge then
				etiquette.Text = "Boussole en recharge : " .. math.ceil(finRecharge - maintenant) .. " s"
				icone.BackgroundTransparency = 0.7
			else
				etiquette.Text = "[F] Boussole des feux follets · " .. n .. (if n > 1 then " cachettes" else " cachette")
				icone.BackgroundTransparency = 0
			end
		end
	end
	if not actif or not feu or not r then
		return
	end
	local t = os.clock()
	if t > finActif or not cible or not cible.Parent or prise(cible) then
		if cible and prise(cible) then
			UI.jouer("succes")
		end
		eteindre(true)
		return
	end
	local but = cible:GetPivot().Position
	local tete = r.Position + Vector3.new(0, 2, 0)
	local dBut = (but - r.Position).Magnitude
	local vise
	if dBut < 14 then
		-- arrivé : il tourne au-dessus de la cachette
		local a = t * 2.2
		vise = but + Vector3.new(math.cos(a) * 2.2, 2.6 + math.sin(t * 3) * 0.4, math.sin(a) * 2.2)
	else
		local p = pointSuivant(r.Position) or but
		vise = libre(tete, p + Vector3.new(0, 3, 0))
		-- il attend le joueur : jamais plus de 16 studs devant
		local d = vise - tete
		if d.Magnitude > 16 then
			vise = tete + d.Unit * 16
		end
	end
	posFeu = posFeu:Lerp(vise, math.min(1, dt * 2.4))
	feu.Position = posFeu + Vector3.new(math.sin(t * 2.7), math.sin(t * 3.3) * 0.5, math.cos(t * 2.1)) * 0.45
	-- pulsation : plus rapide quand on approche
	local chaleur = math.clamp(1 - dBut / 120, 0, 1)
	local freq = 2 + chaleur * 10
	local battement = math.sin(t * freq) * 0.5 + 0.5
	feu.Size = Vector3.one * (1 + battement * (0.2 + chaleur * 0.35))
	local l = feu:FindFirstChildOfClass("PointLight")
	if l then
		l.Brightness = 0.9 + battement * (0.4 + chaleur * 1.4)
	end
end)
