-- Vitrine locale des minerais dans la plaine des mobs (à gauche de l'arrivée) : les 4 minerais du jeu + les 15
-- minerais en projet (MineraisPropositions), en grille de 5 colonnes, comme l'atelier previews/minerais.
-- Rien n'est minable ici : décor client uniquement. Les effets spéciaux (Épique et +) sont animés en local,
-- seulement quand le joueur est près de la vitrine.
local RunService = game:GetService("RunService")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local Propositions = require(Partage:WaitForChild("MineraisPropositions"))

local ORIGINE = Vector3.new(4925, 0, 195) -- centre de la grille, sol de la plaine à y = 0 (arrivée en 5000, z 230)
local COLONNES, ECART = 5, 8.5
local PORTEE = 170 -- au-delà, les animations s'arrêtent

workspace:WaitForChild("PlaineMobs")

local dossier = Instance.new("Folder")
dossier.Name = "VitrineMinerais"

local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass

local function piece(parent: Instance, nom: string, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material): Part
	local p = MineraisModeles.piece(parent, nom, taille, cf, couleur, mat)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if mat == GLASS then
		p.Transparency = 0.15
		p.Reflectance = 0.35
	end
	if mat == NEON or mat == GLASS then
		p.CastShadow = false
	end
	return p
end

local function etiquette(adornee: BasePart, hauteur: number, nom: string, sous: string, couleur: Color3)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(170, 44)
	b.StudsOffsetWorldSpace = Vector3.new(0, hauteur, 0)
	b.MaxDistance = 90
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 0.62)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = couleur
	t.TextStrokeTransparency = 0.3
	t.Text = nom
	t.Parent = b
	local st = Instance.new("TextLabel")
	st.Size = UDim2.fromScale(1, 0.38)
	st.Position = UDim2.fromScale(0, 0.62)
	st.BackgroundTransparency = 1
	st.Font = Enum.Font.GothamMedium
	st.TextScaled = true
	st.TextColor3 = Color3.fromRGB(235, 225, 210)
	st.TextStrokeTransparency = 0.4
	st.Text = sous
	st.Parent = b
	b.Adornee = adornee
	b.Parent = adornee
end

local function fois(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

-- Chaque fonction reçoit (t, dt) à chaque image quand le joueur est proche
local animations: {(number, number) -> ()} = {}

local function ajouterSpeciaux(def, modele: Model, coeur: BasePart, r: Random, cPos: Vector3)
	local sp = def.speciaux
	local s = def.taille
	local verre = def.cristalMat == GLASS

	-- Cristaux géants au sommet (cœur néon dans les cristaux de verre) + collerette à la base
	for i = 1, sp.geant or 0 do
		local principal = i == 1
		local dir = Vector3.new(r:NextNumber(-0.35, 0.35), 1, r:NextNumber(-0.35, 0.35)).Unit
		if not principal then
			dir = (dir + Vector3.new(r:NextNumber(-0.6, 0.6), 0, r:NextNumber(-0.6, 0.6))).Unit
		end
		local pos = cPos + Vector3.new(r:NextNumber(-0.3, 0.3) * s, 0.55 * s, r:NextNumber(-0.3, 0.3) * s)
		local h = r:NextNumber(1.9, 2.5) * s * (if principal then 1 else 0.7)
		local w = 0.62 * s * (if principal then 1 else 0.75)
		local axe = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(-math.pi / 2, 0, 0)
		piece(modele, "CristalGeant", Vector3.new(w, h, w), axe * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(45), 0), def.cristal, def.cristalMat)
		piece(modele, "Pointe", Vector3.one * w * 0.72, axe * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), def.cristal, def.cristalMat)
		if verre then
			piece(modele, "CoeurGeant", Vector3.new(w * 0.32, h * 0.8, w * 0.32), axe * CFrame.new(0, h * 0.45, 0) * CFrame.Angles(0, math.rad(45), 0), def.veine, NEON)
		end
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2 + r:NextNumber(0, 0.6)
			local d2 = Vector3.new(math.cos(a), 0.9, math.sin(a)).Unit
			local hh, ww = r:NextNumber(0.45, 0.8) * s, w * 0.38
			local ax2 = CFrame.lookAt(pos, pos + d2) * CFrame.Angles(-math.pi / 2, 0, 0)
			piece(modele, "Cristal", Vector3.new(ww, hh, ww), ax2 * CFrame.new(0, hh / 2, 0) * CFrame.Angles(0, math.rad(45), 0), def.cristal, def.cristalMat)
		end
	end

	-- Halo : PointLight couleur cristal qui respire
	if sp.lueur then
		local att = Instance.new("Attachment")
		att.Parent = coeur
		att.WorldPosition = cPos + Vector3.new(0, 1.6 * s, 0)
		local l = Instance.new("PointLight")
		l.Color = def.cristal
		l.Brightness = sp.lueur
		l.Range = 10 * s
		l.Shadows = false
		l.Parent = att
		local ph = r:NextNumber(0, 6)
		table.insert(animations, function(t)
			l.Brightness = sp.lueur * (0.75 + 0.25 * math.sin(t * 2.2 + ph))
		end)
	end

	-- Néons qui pulsent (veines, cristaux néon, cristaux géants)
	if sp.pulse then
		local neons = {}
		for _, p in modele:GetDescendants() do
			if p:IsA("BasePart") and p.Material == NEON then
				table.insert(neons, {p, p.Color})
			end
		end
		local ph = r:NextNumber(0, 6)
		table.insert(animations, function(t)
			local k = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 2.6 + ph)) ^ 2
			for _, e in neons do
				e[1].Color = fois(e[2], 0.4 + k)
			end
		end)
	end

	-- Éclats en lévitation qui tournent autour du rocher
	if sp.eclats then
		local eclats = {}
		for i = 0, sp.eclats - 1 do
			local a = i / sp.eclats * math.pi * 2
			local corps = piece(modele, "Eclat", Vector3.new(0.26, 0.62, 0.26) * s, CFrame.new(cPos), def.cristal, def.cristalMat)
			local dedans = if verre then piece(modele, "EclatCoeur", Vector3.new(0.1, 0.5, 0.1) * s, CFrame.new(cPos), def.veine, NEON) else nil
			table.insert(eclats, {corps = corps, dedans = dedans, x = math.cos(a) * 2.35 * s, z = math.sin(a) * 2.35 * s,
				y = r:NextNumber(0.3, 1.5) * s, rx = r:NextNumber(-0.5, 0.5), rz = r:NextNumber(-0.5, 0.5), ph = r:NextNumber(0, 6)})
		end
		table.insert(animations, function(t)
			local pivot = CFrame.new(cPos) * CFrame.Angles(0, t * 0.45, 0)
			for _, e in eclats do
				local cf = pivot * CFrame.new(e.x, e.y + math.sin(t * 1.6 + e.ph) * 0.18 * s, e.z) * CFrame.Angles(e.rx, t * 1.4, e.rz)
				e.corps.CFrame = cf * CFrame.Angles(0, math.rad(45), 0)
				if e.dedans then
					e.dedans.CFrame = cf
				end
			end
		end)
	end

	-- Anneau de runes incliné qui tourne en sens inverse
	if sp.anneau then
		local runes = {}
		local centreAnneau = cPos + Vector3.new(0, 0.4 * s, 0)
		for i = 0, sp.anneau - 1 do
			local a = i / sp.anneau * math.pi * 2
			local pair = i % 2 == 0
			local p = piece(modele, "Rune", Vector3.one * (if pair then 0.3 else 0.18) * s, CFrame.new(centreAnneau),
				if pair then def.veine else def.cristal, NEON)
			table.insert(runes, {p = p, a = a})
		end
		table.insert(animations, function(t)
			local base = CFrame.new(centreAnneau) * CFrame.Angles(0.28, -t * 0.7, 0.12)
			for _, e in runes do
				e.p.CFrame = base * CFrame.new(math.cos(e.a) * 2.9 * s, 0, math.sin(e.a) * 2.9 * s) * CFrame.Angles(math.pi / 4, -e.a, math.pi / 4)
			end
		end)
	end

	-- Petite lune flottante (3 blocs tournés l'un dans l'autre)
	if sp.lune then
		local blocs = {}
		for k = 0, 2 do
			local p = piece(modele, "Lune", Vector3.one * 0.85 * s, CFrame.new(cPos), def.couleur:Lerp(def.cristal, 0.5), NEON)
			table.insert(blocs, {p = p, rot = CFrame.Angles(k * 0.7, k * 0.9, k * 0.4)})
		end
		local y0 = cPos.Y + 3.1 * s
		table.insert(animations, function(t)
			local cf = CFrame.new(cPos.X, y0 + math.sin(t * 1.1) * 0.25 * s, cPos.Z) * CFrame.Angles(t * 0.2, t * 0.5, 0)
			for _, b in blocs do
				b.p.CFrame = cf * b.rot
			end
		end)
	end

	-- Étincelles : petits cubes néon animés (scintille, monte, braises, aspire)
	if sp.etincelles then
		local n, mode = sp.etincelles.n, sp.etincelles.mode
		local couleur = if mode == "braises" then Color3.fromRGB(255, 150, 40) else def.veine
		local parts = {}
		for _ = 1, n do
			local p = piece(modele, "Etincelle", Vector3.one * 0.1, CFrame.new(cPos), couleur, NEON)
			table.insert(parts, {p = p, a = r:NextNumber(0, math.pi * 2), rr = r:NextNumber(1.4, 2.8) * s,
				y = r:NextNumber(-0.6, 2.2) * s, ph = r:NextNumber(0, 1), vit = r:NextNumber(0.5, 1.2), taille = r:NextNumber(0.07, 0.14) * s})
		end
		local tourne = CFrame.Angles(math.pi / 4, 0, math.pi / 4)
		table.insert(animations, function(t)
			for _, e in parts do
				local pos, echelle
				if mode == "scintille" then
					local k = math.max(0, math.sin((t * e.vit + e.ph) * math.pi)) ^ 6
					pos = cPos + Vector3.new(math.cos(e.a) * e.rr, e.y, math.sin(e.a) * e.rr)
					echelle = e.taille * (0.2 + 2.2 * k)
				elseif mode == "aspire" then
					local f = (t * e.vit * 0.35 + e.ph) % 1
					local rad, ang = (1 - f) * 3.6 * s + 0.3 * s, e.a + f * 2.5
					pos = cPos + Vector3.new(math.cos(ang) * rad, e.y * (1 - f) * 0.7, math.sin(ang) * rad)
					echelle = e.taille * 1.3 * math.sin(f * math.pi)
				else
					local braises = mode == "braises"
					local f = (t * e.vit * (if braises then 0.45 else 0.3) + e.ph) % 1
					local ond = if braises then math.sin(t * 3 + e.a * 5) * 0.35 * s else 0
					local rad = e.rr * (if braises then 0.7 else 1)
					pos = cPos + Vector3.new(math.cos(e.a) * rad + ond, -0.6 * s + f * 4 * s, math.sin(e.a) * rad)
					echelle = e.taille * math.sin(f * math.pi) * 1.4
				end
				if echelle < 0.01 then
					e.p.Transparency = 1
				else
					e.p.Transparency = 0
					e.p.Size = Vector3.one * echelle
				end
				e.p.CFrame = CFrame.new(pos) * CFrame.Angles(0, t, 0) * tourne
			end
		end)
	end
end

-- Liste : les 4 du jeu puis les 15 propositions (même ordre que l'atelier)
local liste = {}
for _, id in MineraisModeles.ORDRE do
	table.insert(liste, {id = id, def = MineraisModeles.VISUEL[id], enJeu = true})
end
for _, id in Propositions.ORDRE do
	table.insert(liste, {id = id, def = Propositions.VISUEL[id], enJeu = false})
end

local lignes = math.ceil(#liste / COLONNES)
for i, e in liste do
	local idx = i - 1
	local x = (idx % COLONNES - (COLONNES - 1) / 2) * ECART
	local z = (math.floor(idx / COLONNES) - (lignes - 1) / 2) * ECART
	local sol = CFrame.new(ORIGINE + Vector3.new(x, 0, z))
	local r = Random.new(7 + idx * 31)
	local modele, coeur = MineraisModeles.construire(e.id, sol, r, false, e.def)
	modele.Name = "Vitrine_" .. e.id
	local def = e.def
	local cPos = sol.Position + Vector3.new(0, 1.25 * def.taille, 0)
	if def.speciaux then
		ajouterSpeciaux(def, modele, coeur, r, cPos)
	end
	local couleur = Propositions.COULEURS_RARETE[def.rarete] or Color3.new(1, 1, 1)
	etiquette(coeur, 3.4 * def.taille, Propositions.NOMS[e.id] or e.id,
		def.rarete .. (if e.enJeu then " · en jeu" else " · en projet"), couleur)
	modele.Parent = dossier
end

-- Panneau au-dessus de la grille
local panneau = Instance.new("Part")
panneau.Name = "Panneau"
panneau.Anchored, panneau.CanCollide, panneau.CanQuery, panneau.CanTouch = true, false, false, false
panneau.Transparency = 1
panneau.Size = Vector3.one
panneau.Position = ORIGINE + Vector3.new(0, 9, (lignes / 2) * ECART)
panneau.Parent = dossier
etiquette(panneau, 0, "MINERAIS", "4 en jeu · 15 en projet (pas encore minables)", Color3.fromRGB(242, 193, 78))

dossier.Parent = workspace

local camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera or camera
	if not cam or (cam.CFrame.Position - ORIGINE).Magnitude > PORTEE then
		return
	end
	local t = os.clock()
	for _, f in animations do
		f(t, dt)
	end
end)
