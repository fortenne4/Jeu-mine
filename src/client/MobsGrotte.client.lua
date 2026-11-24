-- Mobs des grottes profondes · CLIENT : anime les mobs tagués « MobGrotte » (MobsVoxels.animateur selon
-- l'attribut Etat posé par MobsGrotte côté serveur), barre de vie, chiffres de dégâts et flash rouge.
-- Boss : chiffres regroupés par auteur (attribut Auteur) — les miens en blanc vif, plus gros et dorés sur les gros
-- coups ; ceux des autres plus petits et translucides — et mort au ralenti.
-- Compatible StreamingEnabled : les modèles sont atomiques, suivis à l'apparition, oubliés à la disparition.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MobsVoxels = require(Partage:WaitForChild("MobsVoxels"))

local TAG = "MobGrotte"
local DISTANCE_ANIM = 160
local NOMS = {
	MineurZombie = "Mineur zombie",
	BruteProfondeurs = "Brute des profondeurs",
	ChauveSourisCave = "Chauve-souris des caves",
	RampantGaleries = "Rampant des galeries",
	ZombieLame = "Zombie à bras-lame",
	ZombieMutant = "Zombie mutant",
	ExecuteurMaudit = "Exécuteur maudit",
	GolemChampignon = "Golem champignon",
	CrabeLueur = "Crabe des lueurs",
	SpectreNain = "Spectre nain",
	TitanCristal = "Titan de cristal",
	ReineAraignee = "Reine araignée",
	SeigneurBraise = "Seigneur de braise",
	RoiDechu = "Le Roi déchu",
}

local rng = Random.new()
local moi = Players.LocalPlayer
local REGROUPE = 0.12 -- s : les coups du même auteur sur le boss pendant ce délai font un seul chiffre
local AUTRES_MAX = 6 -- chiffres des autres joueurs affichés en même temps sur le boss
local suivis = {} -- [modele] = e

local function couleurVie(r: number): Color3
	local vert, jaune, rouge = Color3.fromRGB(110, 230, 120), Color3.fromRGB(255, 210, 70), Color3.fromRGB(240, 70, 60)
	if r > 0.5 then return jaune:Lerp(vert, (r - 0.5) / 0.5) end
	return rouge:Lerp(jaune, r / 0.5)
end

local function coin(parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = parent
end

local function creerBarre(e)
	local boss = e.boss
	local b = Instance.new("BillboardGui")
	b.Name = "BarreVie"
	b.Adornee = e.root
	b.LightInfluence = 0
	b.MaxDistance = if boss then 140 else 70
	b.StudsOffsetWorldSpace = Vector3.new(0, e.hauteur + (if boss then 2.2 else 1), 0)
	b.Size = if boss then UDim2.new(9, 60, 1.4, 14) else UDim2.new(3, 24, 0.25, 4)

	local cadre = Instance.new("Frame")
	cadre.BackgroundColor3 = Color3.fromRGB(18, 14, 16)
	cadre.BackgroundTransparency = 0.2
	cadre.BorderSizePixel = 0
	cadre.AnchorPoint = Vector2.new(0, 1)
	cadre.Position = UDim2.fromScale(0, 1)
	cadre.Size = if boss then UDim2.fromScale(1, 0.42) else UDim2.fromScale(1, 1)
	coin(cadre)
	local trait = Instance.new("UIStroke")
	trait.Color = Color3.new(0, 0, 0)
	trait.Transparency = 0.35
	trait.Thickness = if boss then 2 else 1
	trait.Parent = cadre
	cadre.Parent = b

	local trace = Instance.new("Frame") -- blanc qui rattrape la vie en retard
	trace.BackgroundColor3 = Color3.fromRGB(255, 240, 220)
	trace.BackgroundTransparency = 0.15
	trace.BorderSizePixel = 0
	trace.Size = UDim2.fromScale(1, 1)
	coin(trace)
	trace.Parent = cadre

	local rempli = Instance.new("Frame")
	rempli.BackgroundColor3 = if boss then Color3.fromRGB(220, 60, 255) else couleurVie(1)
	rempli.BorderSizePixel = 0
	rempli.Size = UDim2.fromScale(1, 1)
	coin(rempli)
	local brillance = Instance.new("UIGradient")
	brillance.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))
	brillance.Rotation = 90
	brillance.Parent = rempli
	rempli.Parent = cadre

	if boss then
		local nom = Instance.new("TextLabel")
		nom.BackgroundTransparency = 1
		nom.Size = UDim2.fromScale(1, 0.52)
		nom.Font = Enum.Font.GothamBlack
		nom.TextScaled = true
		nom.TextColor3 = Color3.fromRGB(255, 225, 235)
		nom.Text = e.modele:GetAttribute("Nom") or NOMS[e.id] or e.id -- « Nom » : boss du village (modèle de secours)
		local contour = Instance.new("UIStroke")
		contour.Thickness = 2
		contour.Color = Color3.fromRGB(40, 0, 50)
		contour.Parent = nom
		nom.Parent = b
	end
	b.Parent = e.root
	e.barre, e.rempli, e.trace = b, rempli, trace
end

local function majBarre(e, instantane: boolean?)
	local pvMax = e.modele:GetAttribute("PVMax") or 1
	local pv = e.modele:GetAttribute("PV") or pvMax
	local r = math.clamp(pv / math.max(pvMax, 1), 0, 1)
	e.barre.Enabled = e.etat ~= "Death" and (e.boss or pv < pvMax)
	if not e.boss then e.rempli.BackgroundColor3 = couleurVie(r) end
	local taille = UDim2.fromScale(r, 1)
	if instantane then
		e.rempli.Size, e.trace.Size = taille, taille
	else
		TweenService:Create(e.rempli, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = taille}):Play()
		TweenService:Create(e.trace, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.25), {Size = taille}):Play()
	end
end

local function chiffreDegats(e, montant: number, pvMax: number)
	local b = Instance.new("BillboardGui")
	b.Adornee = e.root
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.MaxDistance = 90
	b.Size = UDim2.fromOffset(56, 26)
	local depart = Vector3.new(rng:NextNumber(-1.2, 1.2), e.hauteur * 0.7 + 0.5, rng:NextNumber(-1.2, 1.2))
	b.StudsOffsetWorldSpace = depart
	local fort = montant >= pvMax * 0.15
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = tostring(math.max(1, math.floor(montant + 0.5)))
	t.TextColor3 = if fort then Color3.fromRGB(255, 190, 60) else Color3.new(1, 1, 1)
	local contour = Instance.new("UIStroke")
	contour.Thickness = 2
	contour.Color = Color3.fromRGB(30, 10, 10)
	contour.Parent = t
	t.Parent = b
	b.Parent = e.root
	local grand = if fort then UDim2.fromOffset(100, 46) else UDim2.fromOffset(80, 36)
	TweenService:Create(b, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = grand}):Play()
	TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffsetWorldSpace = depart + Vector3.new(0, 2.4, 0)}):Play()
	local fondu = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4)
	TweenService:Create(t, fondu, {TextTransparency = 1}):Play()
	TweenService:Create(contour, fondu, {Transparency = 1}):Play()
	task.delay(0.85, function() b:Destroy() end)
end

-- Boss : un chiffre stylé selon l'auteur (moi / les autres)
local function chiffreBoss(e, montant: number, pvMax: number, mien: boolean)
	local b = Instance.new("BillboardGui")
	b.Adornee = e.root
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.MaxDistance = 140
	local epee = moi:GetAttribute("StatEpee")
	local fort = if mien then (type(epee) == "number" and epee > 0 and montant >= epee * 1.35) else montant >= pvMax * 0.03
	b.Size = UDim2.fromOffset(40, 18)
	local depart = Vector3.new(rng:NextNumber(-2.5, 2.5), e.hauteur * (if mien then 0.75 else 0.6) + rng:NextNumber(0, 1.5), rng:NextNumber(-2.5, 2.5))
	b.StudsOffsetWorldSpace = depart
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = tostring(math.max(1, math.floor(montant + 0.5)))
	t.TextColor3 = if mien then (if fort then Color3.fromRGB(255, 214, 70) else Color3.new(1, 1, 1))
		else (if fort then Color3.fromRGB(240, 220, 160) else Color3.fromRGB(215, 210, 205))
	t.TextTransparency = if mien then 0 else 0.35
	local contour = Instance.new("UIStroke")
	contour.Thickness = if mien then 2.5 else 1.5
	contour.Color = if mien and fort then Color3.fromRGB(90, 30, 0) else Color3.fromRGB(30, 10, 10)
	contour.Transparency = if mien then 0 else 0.4
	contour.Parent = t
	t.Parent = b
	b.Parent = e.root
	local grand = if mien then (if fort then UDim2.fromOffset(150, 64) else UDim2.fromOffset(104, 44))
		else (if fort then UDim2.fromOffset(78, 34) else UDim2.fromOffset(60, 26))
	TweenService:Create(b, TweenInfo.new(if fort then 0.2 else 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = grand}):Play()
	TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffsetWorldSpace = depart + Vector3.new(0, if mien then 3 else 2, 0)}):Play()
	local fondu = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4)
	TweenService:Create(t, fondu, {TextTransparency = 1}):Play()
	TweenService:Create(contour, fondu, {Transparency = 1}):Play()
	if not mien then
		e.autres = (e.autres or 0) + 1
	end
	task.delay(0.85, function()
		if not mien then e.autres -= 1 end
		b:Destroy()
	end)
end

-- Regroupe les coups sur le boss (par auteur) pendant REGROUPE s : moins de chiffres, plus lisibles
local function cumulerBoss(e, montant: number, pvMax: number)
	local auteur = e.modele:GetAttribute("Auteur")
	local mien = auteur == moi.UserId
	local cle = if mien then "moi" else "autres"
	e.cumul = e.cumul or {}
	local c = e.cumul[cle]
	if c then
		c.montant += montant
		return
	end
	e.cumul[cle] = {montant = montant}
	task.delay(REGROUPE, function()
		local fin = e.cumul[cle]
		e.cumul[cle] = nil
		if not fin or suivis[e.modele] ~= e or not e.root.Parent then return end
		if not mien and (e.autres or 0) >= AUTRES_MAX then return end -- trop de chiffres des autres : on saute
		chiffreBoss(e, fin.montant, pvMax, mien)
	end)
end

local function flash(e)
	if e.flash then e.flash:Destroy() end
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 60, 50)
	hl.FillTransparency = 0.3
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = e.modele
	hl.Parent = e.modele
	e.flash = hl
	TweenService:Create(hl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FillTransparency = 1}):Play()
	task.delay(0.27, function()
		if e.flash == hl then e.flash = nil end
		hl:Destroy()
	end)
end

local function jouer(e, nom: string, boucle: boolean, fondu: number)
	if not e.anim.Clips[nom] then nom = if nom == "Run" and e.anim.Clips.Walk then "Walk" else "Idle" end -- « Run » : Roi déchu
	e.anim:Jouer(nom, boucle, fondu)
	e.unique = not boucle
	e.anim.Vitesse = if nom == "Walk" or nom == "Run" then math.clamp(e.modele:GetAttribute("Allure") or 1, 0.4, 1.2) else 1
end

local function boucleDe(etat: string?): string
	return if etat == "Walk" then "Walk" elseif etat == "Run" then "Run" else "Idle"
end

local function fondre(e)
	task.delay(if e.boss then 2.6 else 0.8, function()
		if suivis[e.modele] ~= e then return end
		local info = TweenInfo.new(if e.boss then 1.4 else 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, p in e.modele:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				TweenService:Create(p, info, {Transparency = 1}):Play()
			end
		end
	end)
end

local function surEtat(e)
	local etat = e.modele:GetAttribute("Etat") or "Idle"
	if etat == e.etat then return end
	e.etat = etat
	if etat == "Death" then
		jouer(e, "Death", false, 0.1)
		if e.boss then e.anim.Vitesse = 0.45 end -- mort du boss au ralenti
		e.barre.Enabled = false
		fondre(e)
	elseif etat == "Roar" then
		jouer(e, "Roar", false, 0.15)
	elseif etat == "Walk" or etat == "Idle" or etat == "Run" then
		-- laisse finir une attaque / blessure en cours, sinon passe à la boucle
		if not (e.unique and not e.anim:Fini()) then
			jouer(e, boucleDe(etat), true, 0.2)
		end
	elseif etat ~= "Attack" and etat ~= "Hurt" and e.anim.Clips[etat] then
		-- clip propre au mob (attaques spéciales du Roi déchu : Frappe, Elan, Charge en boucle, Incantation)
		jouer(e, etat, etat == "Charge", 0.12)
	end
	-- "Attack" : joué via l'attribut Coup ; "Hurt" : joué à la baisse de PV
end

local function suivre(modele: Instance)
	if suivis[modele] or not modele:IsA("Model") then return end
	local e = {modele = modele, connexions = {}}
	suivis[modele] = e
	task.spawn(function()
		local root = modele.PrimaryPart or modele:WaitForChild("Root", 10)
		if not root or suivis[modele] ~= e then return end
		local id = modele:GetAttribute("MobId") or modele.Name
		local ok, anim = pcall(MobsVoxels.animateur, modele, id)
		if not ok then
			warn("MobsGrotte.client : " .. tostring(anim))
			return
		end
		if suivis[modele] ~= e then return end
		e.root, e.anim, e.id = root, anim, id
		e.boss = modele:GetAttribute("Boss") == true
		e.hauteur = modele:GetAttribute("Hauteur") or modele:GetExtentsSize().Y
		e.pv = modele:GetAttribute("PV") or 0
		creerBarre(e)
		local depart = modele:GetAttribute("Etat") or "Idle"
		if depart == "Death" then
			e.etat = "Death"
			jouer(e, "Death", false, 0)
			e.barre.Enabled = false
			fondre(e)
		else
			jouer(e, boucleDe(depart), true, 0)
			e.etat = depart
		end
		majBarre(e, true)

		table.insert(e.connexions, modele:GetAttributeChangedSignal("Etat"):Connect(function()
			surEtat(e)
		end))
		table.insert(e.connexions, modele:GetAttributeChangedSignal("Coup"):Connect(function()
			if e.etat ~= "Death" then jouer(e, "Attack", false, 0.08) end
		end))
		table.insert(e.connexions, modele:GetAttributeChangedSignal("Allure"):Connect(function()
			if e.anim:EnCours() == "Walk" or e.anim:EnCours() == "Run" then
				e.anim.Vitesse = math.clamp(modele:GetAttribute("Allure") or 1, 0.4, 1.2)
			end
		end))
		table.insert(e.connexions, modele:GetAttributeChangedSignal("PV"):Connect(function()
			local pv = modele:GetAttribute("PV") or 0
			local perte = e.pv - pv
			e.pv = pv
			majBarre(e)
			if perte > 0 then
				if e.boss then
					cumulerBoss(e, perte, modele:GetAttribute("PVMax") or 1)
				else
					chiffreDegats(e, perte, modele:GetAttribute("PVMax") or 1)
				end
				if modele:GetAttribute("DernierCoup") == nil then flash(e) end
				local enAttaque = e.anim:EnCours() == "Attack" and not e.anim:Fini()
				if pv > 0 and not e.boss and not enAttaque and e.etat ~= "Death" then
					jouer(e, "Hurt", false, 0.06)
				end
			end
		end))
	end)
end

local function oublier(modele: Instance)
	local e = suivis[modele]
	if not e then return end
	suivis[modele] = nil
	for _, c in e.connexions do c:Disconnect() end
	if e.flash then e.flash:Destroy() end
	if e.barre then e.barre:Destroy() end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(suivre)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(oublier)
for _, m in CollectionService:GetTagged(TAG) do
	suivre(m)
end

RunService.Heartbeat:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local oeil = camera and camera.CFrame.Position
	for _, e in suivis do
		local a = e.anim
		if a and e.root.Parent and (not oeil or (e.root.Position - oeil).Magnitude < DISTANCE_ANIM) then
			if e.unique and e.etat ~= "Death" and a:Fini() then
				jouer(e, boucleDe(e.etat), true, 0.2)
			end
			a:Pas(dt)
		end
	end
end)
