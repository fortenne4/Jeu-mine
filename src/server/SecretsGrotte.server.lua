-- Secrets de la grotte −50 m · SCRIPT SERVEUR
-- 1. Énigme runique : 3 pierres de couleur (invite « Activer », attribut « PierreRunique ») à activer dans l'ordre
--    gravé sur la porte scellée (attribut du modèle « OrdreRunes »). Bonne pierre : elle s'allume, la rune de la
--    porte aussi. Mauvaise : tout s'éteint et on recommence. Les 3 dans l'ordre : la porte s'enfonce dans le sol
--    et la salle secrète s'ouvre (Fer, Or, fragment de carte).
-- 2. Cristaux de lueur (nœuds « Minerai » de type « Lueur » posés au pied des veines) : cassés à la pioche, ils
--    rapportent quelques pièces et parfois un fragment de la carte naine.
-- 3. Minerais de la salle secrète : le rocher s'efface quand le cœur est cassé (la récompense reste celle de
--    Minerais.server.lua).
-- Messages aux joueurs de l'expédition par le RemoteEvent « CarteNaine » (affichés par CarteNaine.client.lua).

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local CarteNaine = require(script.Parent:WaitForChild("CarteNaine"))

local PIECES_CRISTAL = 4
local CHANCE_FRAGMENT_CRISTAL = 0.12

local function grotteDe(objet: Instance): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	local m = objet
	while m and m.Parent ~= dossier do
		m = m.Parent :: Instance
	end
	return if m and m:IsA("Model") then m else nil
end

-- joueurs de l'expédition (propriétaire et invité de la grotte)
local function joueursDe(grotte: Model): {Player}
	local t = {}
	for _, j in Players:GetPlayers() do
		if j.UserId == grotte:GetAttribute("Proprietaire") or j.UserId == grotte:GetAttribute("Invite") then
			table.insert(t, j)
		end
	end
	return t
end

local function annoncer(grotte: Model, genre: string, donnees: {[string]: any})
	for _, j in joueursDe(grotte) do
		CarteNaine.remote:FireClient(j, genre, donnees)
	end
end

local function allumer(parts: {BasePart}, couleur: Color3?, allume: boolean)
	for _, p in parts do
		local c = couleur or p:GetAttribute("Couleur")
		if typeof(c) == "Color3" then
			local cible = if allume then c else c:Lerp(Color3.fromRGB(20, 22, 30), 0.82)
			TweenService:Create(p, TweenInfo.new(if allume then 0.4 else 0.8), {Color = cible}):Play()
		end
	end
end

local function morceaux(parent: Instance, nom: string): {BasePart}
	local t = {}
	for _, d in parent:GetDescendants() do
		if d:IsA("BasePart") and d.Name == nom then
			table.insert(t, d)
		end
	end
	return t
end

local function rayonPierre(pierre: Model, couleur: Color3, actif: boolean)
	local stele = pierre:FindFirstChild("Stele") :: BasePart?
	if not stele then
		return
	end
	local l = stele:FindFirstChild("LueurRune") :: PointLight?
	if actif and not l then
		local n = Instance.new("PointLight")
		n.Name = "LueurRune"
		n.Color, n.Range, n.Brightness = couleur, 14, 0
		n.Parent = stele
		TweenService:Create(n, TweenInfo.new(0.6), {Brightness = 2}):Play()
		local e = Instance.new("ParticleEmitter")
		e.Name = "ColonneRune"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(couleur)
		e.LightEmission, e.LightInfluence = 1, 0
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
		e.Lifetime = NumberRange.new(1.5, 2.5)
		e.Speed = NumberRange.new(4, 7)
		e.SpreadAngle = Vector2.new(6, 6)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = 25
		e.Parent = stele
	elseif not actif and l then
		l:Destroy()
		local e = stele:FindFirstChild("ColonneRune")
		if e then
			e:Destroy()
		end
	end
end

local function ouvrirPorte(grotte: Model)
	if grotte:GetAttribute("PorteOuverte") then
		return
	end
	grotte:SetAttribute("PorteOuverte", true)
	for _, d in grotte:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("PierreRunique") then
			d.Enabled = false
		end
	end
	local porte = grotte:FindFirstChild("PorteSecrete", true)
	local battant = porte and porte:FindFirstChild("Battant") :: BasePart?
	if battant then
		local ferme = battant:GetAttribute("Ferme")
		local cf = if typeof(ferme) == "CFrame" then ferme else battant.CFrame
		local t = TweenService:Create(battant, TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = cf * CFrame.new(0, -8.6, 0)})
		t.Completed:Once(function()
			battant.CanCollide = false
			battant.Transparency = 1
		end)
		t:Play()
	end
	annoncer(grotte, "Porte", {})
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	local idx = invite:GetAttribute("PierreRunique")
	if type(idx) ~= "number" then
		return
	end
	local stele = invite.Parent
	local pierre = stele and stele.Parent
	local grotte = pierre and grotteDe(pierre)
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (stele and stele:IsA("BasePart") and pierre and grotte and r) then
		return
	end
	if joueur.UserId ~= grotte:GetAttribute("Proprietaire") and joueur.UserId ~= grotte:GetAttribute("Invite") then
		return
	end
	if (r.Position - stele.Position).Magnitude > invite.MaxActivationDistance + 4 or grotte:GetAttribute("PorteOuverte") then
		return
	end
	if pierre:GetAttribute("Active") then
		return
	end
	local ordre = {}
	for s in tostring(grotte:GetAttribute("OrdreRunes") or ""):gmatch("%d+") do
		table.insert(ordre, tonumber(s))
	end
	local progres = grotte:GetAttribute("RunesProgres") or 0
	local porte = grotte:FindFirstChild("PorteSecrete", true)
	local couleur = pierre:GetAttribute("Couleur")
	if ordre[progres + 1] == idx then
		progres += 1
		grotte:SetAttribute("RunesProgres", progres)
		pierre:SetAttribute("Active", true)
		invite.Enabled = false
		allumer(morceaux(pierre, "Glyphe"), couleur, true)
		rayonPierre(pierre, couleur, true)
		if porte then
			for _, g in morceaux(porte, "SlotRune") do
				if g:GetAttribute("Rang") == progres then
					allumer({g}, nil, true)
				end
			end
		end
		if progres >= #ordre then
			annoncer(grotte, "Rune", {n = progres, total = #ordre, ok = true})
			task.delay(1, ouvrirPorte, grotte)
		else
			annoncer(grotte, "Rune", {n = progres, total = #ordre, ok = true})
		end
	else
		-- mauvais ordre : toutes les runes s'éteignent
		grotte:SetAttribute("RunesProgres", 0)
		for _, d in grotte:GetDescendants() do
			if d:IsA("Model") and d.Name == "PierreRunique" then
				d:SetAttribute("Active", nil)
				for _, p in d:GetDescendants() do
					if p:IsA("ProximityPrompt") then
						p.Enabled = true
					end
				end
				allumer(morceaux(d, "Glyphe"), d:GetAttribute("Couleur"), false)
				rayonPierre(d, Color3.new(), false)
			end
		end
		if porte then
			allumer(morceaux(porte, "SlotRune"), nil, false)
		end
		annoncer(grotte, "Rune", {n = 0, total = #ordre, ok = false})
	end
end)

-- Cristaux de lueur et minerais de la salle secrète
task.spawn(function()
	local casse = ServerStorage:WaitForChild("MineraiCasse", 60)
	if not (casse and casse:IsA("BindableEvent")) then
		return
	end
	casse.Event:Connect(function(joueur, bloc)
		if typeof(bloc) ~= "Instance" then
			return
		end
		local estCristal = bloc:GetAttribute("VeineLueur") == true
		if not estCristal and not bloc:GetAttribute("Secret") then
			return
		end
		-- le reste du rocher / de l'amas s'efface
		local m = bloc.Parent
		if m and m:IsA("Model") then
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d ~= bloc then
					d.CanCollide = false
					TweenService:Create(d, TweenInfo.new(0.4), {Transparency = 1, Size = d.Size * 0.5}):Play()
				elseif d:IsA("ParticleEmitter") then
					d.Enabled = false
				end
			end
			task.delay(1.2, function()
				m:Destroy()
			end)
		end
		if estCristal and typeof(joueur) == "Instance" and joueur:IsA("Player") then
			CarteNaine.crediter(joueur, PIECES_CRISTAL)
			CarteNaine.remote:FireClient(joueur, "Cristal", {pieces = PIECES_CRISTAL})
			if math.random() < CHANCE_FRAGMENT_CRISTAL then
				task.delay(0.8, CarteNaine.donnerFragment, joueur, "cristal")
			end
		end
	end)
end)
