-- Trône de magma (grotte −350 m) · SCRIPT CLIENT : cinématique du réveil du Roi déchu et messages du combat.
-- Le serveur (TroneLave.lua, RemoteEvent « TroneRoi ») envoie « Intro » aux combattants quand un joueur s'assoit :
--   0 → 2,6 s : plan par-dessus l'épaule du trône, vers le bassin ; le trône tremble, la lave bouillonne, un anneau
--               de flammes monte autour du bassin, les braseros s'emballent, la lumière rougit ;
--   2,6 → 5,6 s : plan bas entre le trône et le bassin : gerbe de feu, le roi surgit de la lave (montée serveur) ;
--   5,6 → 9 s : gros plan, il rugit (forte secousse), carte de titre « LE ROI DÉCHU » ; puis retour au jeu.
-- Tout est local (effets, tremblement du trône, caméra) et restauré à la fin. Aussi : « Eveil », « Combat »,
-- « Retour » (il replonge dans la lave), « Defaite », « Victoire » (pop-up du trésor), et les effets des attaques
-- spéciales « Onde » (anneau de feu) et « Meteores » (rochers qui tombent sur les cercles rouges posés par le serveur).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local PopupCoffre = require(script.Parent:WaitForChild("PopupCoffre"))
local creer = UI.creer

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TroneRoi") :: RemoteEvent

local LAVE = Color3.fromRGB(255, 96, 20)
local LAVE_CLAIRE = Color3.fromRGB(255, 190, 70)
local BRAISE = Color3.fromRGB(255, 70, 20)
-- Luminosité volontairement basse (retour joueur : on ne voyait plus rien) : particules peu émissives et
-- semi-transparentes, lumières faibles, aucun voile plein écran.
local LUMIERE_PARTICULES = 0.25
local TRANSPARENCE_FEU = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
local TEX_FEU = "rbxasset://textures/particles/fire_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local SONS = {
	grondement = "rbxassetid://9118598279", -- Rock Hit Dirt 14 (ralenti)
	casse = "rbxassetid://9118587698", -- Rock Breaks 3
	feu = "rbxassetid://2787093357", -- feu de camp
	cri = "rbxassetid://9114629203", -- cri du titan, grave
	eau = "rbxasset://sounds/impact_water.mp3",
}

-- ================= Interface =================
local gui = creer("ScreenGui", {Name = "TroneRoi", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 26, Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)
local bandes = {}
for i, y in {0, 1} do
	bandes[i] = creer("Frame", {AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 10, Parent = gui})
end
local carte = creer("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.8, 0.2),
	BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 11, Parent = gui})
local titre = UI.texte({Text = "LE ROI DÉCHU", Font = Enum.Font.Fantasy, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.62), ZIndex = 12, Parent = carte}, 84)
creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 170)),
	ColorSequenceKeypoint.new(0.5, LAVE), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 10))}), Parent = titre})
creer("UIStroke", {Thickness = 3, Color = Color3.fromRGB(30, 6, 4), Parent = titre})
local echelleTitre = creer("UIScale", {Scale = 1.25, Parent = titre})
for _, sx in {-1, 1} do -- filets de part et d'autre du sous-titre
	creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5 + sx * 0.33, 0.8), Size = UDim2.new(0.18, 0, 0, 2),
		BackgroundColor3 = LAVE, BorderSizePixel = 0, ZIndex = 12, Parent = carte})
end
UI.texte({Text = "Souverain des Rivières de lave", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 214, 180), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.fromScale(0.45, 0.2), ZIndex = 12, Parent = carte}, 28)

local function son(id: string, volume: number, vitesse: number?)
	local s = creer("Sound", {SoundId = id, Volume = volume, PlaybackSpeed = vitesse or 1, Parent = SoundService})
	SoundService:PlayLocalSound(s)
	Debris:AddItem(s, 8)
end

-- ================= Outils =================
local function controles(actifs: boolean)
	local scripts = joueur:FindFirstChild("PlayerScripts")
	local pm = scripts and scripts:FindFirstChild("PlayerModule")
	local ok, module = pcall(function()
		return if pm and pm:IsA("ModuleScript") then require(pm) else nil
	end)
	if ok and module and module.GetControls then
		local c = module:GetControls()
		if actifs then c:Enable() else c:Disable() end
	end
end

local function trouverRoi(pres: Vector3): Model?
	local meilleur, dMin = nil, 60
	for _, m in CollectionService:GetTagged("MobGrotte") do
		if m:IsA("Model") and m:GetAttribute("MobId") == "RoiDechu" and m.PrimaryPart then
			local d = (m.PrimaryPart.Position - pres).Magnitude
			if d < dMin then
				meilleur, dMin = m, d
			end
		end
	end
	return meilleur
end

local function troneDe(bassin: Vector3): Model?
	local dossier = workspace:FindFirstChild("Grottes")
	if not dossier then
		return nil
	end
	for _, g in dossier:GetChildren() do
		local t = g:FindFirstChild("TroneMagma", true)
		local b = t and t:GetAttribute("Bassin")
		if typeof(b) == "Vector3" and (b - bassin).Magnitude < 1 then
			return t :: Model
		end
	end
	return nil
end

local function emetteur(parent: Instance, props: {[string]: any}): ParticleEmitter
	local e: any = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	for k, v in props do
		e[k] = v
	end
	e.Parent = parent
	return e
end

local function ancre(cf: CFrame, taille: Vector3, parent: Instance): BasePart
	return creer("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = taille, CFrame = cf, Parent = parent})
end

-- gerbe de feu et éclaboussures de lave (surgissement, retour dans la lave)
local function gerbe(pos: Vector3, force: number, parent: Instance?)
	local dossier = parent or workspace
	local p = ancre(CFrame.new(pos), Vector3.new(6, 1, 6), dossier)
	local feu = emetteur(p, {Texture = TEX_FEU, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE, BRAISE), EmissionDirection = Enum.NormalId.Top,
		Transparency = TRANSPARENCE_FEU, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.3)}), Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(15, 15), Rate = 0})
	local gouttes = emetteur(p, {Texture = TEX_ETINCELLE, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE_CLAIRE, LAVE), EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}), Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(55, 55), Acceleration = Vector3.new(0, -45, 0), Rate = 0})
	local fumee = emetteur(p, {Texture = TEX_FUMEE, LightInfluence = 0.6, Color = ColorSequence.new(Color3.fromRGB(60, 40, 36)), EmissionDirection = Enum.NormalId.Top,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)}),
		Size = NumberSequence.new(4, 12), Lifetime = NumberRange.new(2, 3.5), Speed = NumberRange.new(4, 9), Rate = 0})
	feu:Emit(math.floor(22 * force))
	gouttes:Emit(math.floor(40 * force))
	fumee:Emit(math.floor(14 * force))
	local l = creer("PointLight", {Color = LAVE, Range = 24, Brightness = 1.2 * force, Shadows = false, Parent = p})
	TweenService:Create(l, TweenInfo.new(1.6, Enum.EasingStyle.Quad), {Brightness = 0}):Play()
	Debris:AddItem(p, 4)
end

-- ================= Cinématique =================
local enCinematique = false

local function intro(d)
	local cf, bassin = d.cf, d.bassin
	if enCinematique or typeof(cf) ~= "CFrame" or typeof(bassin) ~= "Vector3" then
		return
	end
	enCinematique = true
	local duree = tonumber(d.duree) or 9
	local camera = workspace.CurrentCamera
	local L, R = cf.LookVector, cf.RightVector -- L : du trône vers la salle (le bassin est devant)
	local centreB = bassin + Vector3.new(0, 0.2, 0)

	-- effets locaux
	local dossier = creer("Folder", {Name = "CinematiqueTroneRoi", Parent = workspace})
	local pBassin = ancre(CFrame.new(centreB), Vector3.new(9, 0.5, 9), dossier)
	local bouillons = emetteur(pBassin, {Texture = TEX_ETINCELLE, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE_CLAIRE, LAVE), EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 0)}),
		Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, -20, 0), Rate = 10})
	local vapeur = emetteur(pBassin, {Texture = TEX_FUMEE, LightInfluence = 0.5, Color = ColorSequence.new(Color3.fromRGB(90, 50, 40)), EmissionDirection = Enum.NormalId.Top,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)}), Size = NumberSequence.new(3, 9),
		Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(2, 5), Rate = 2})
	local lueur = creer("PointLight", {Color = BRAISE, Range = 28, Brightness = 0.4, Shadows = false, Parent = pBassin})
	local anneau = {}
	for k = 0, 7 do
		local a = k / 8 * 2 * math.pi
		local p = ancre(CFrame.new(centreB + Vector3.new(math.cos(a), 0, math.sin(a)) * 6.6), Vector3.new(1.5, 0.5, 1.5), dossier)
		table.insert(anneau, emetteur(p, {Texture = TEX_FEU, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE, BRAISE), EmissionDirection = Enum.NormalId.Top,
			Transparency = TRANSPARENCE_FEU, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.2)}), Lifetime = NumberRange.new(0.5, 1),
			Speed = NumberRange.new(4, 9), Rate = 0}))
	end
	-- braseros et colonnes du trône qui s'emballent ; trône qui tremble (pièces déplacées localement, Seat exclu)
	local trone = troneDe(bassin)
	local feux, pieces, cfs0 = {}, {}, {}
	if trone then
		for _, x in trone:GetDescendants() do
			if x:IsA("ParticleEmitter") and x.Parent and (x.Parent.Name == "FeuBrasero" or x.Parent.Name == "FeuColonne") then
				table.insert(feux, {e = x, rate = x.Rate, vitesse = x.Speed})
			elseif x:IsA("BasePart") and not x:IsA("Seat") and x.Transparency < 1 then
				local m = x:FindFirstAncestorWhichIsA("Model")
				if m == trone or (m and m.Parent == trone and m.Name ~= "ColonneTrone" and m.Name ~= "Brasero") then
					table.insert(pieces, x)
					table.insert(cfs0, x.CFrame)
				end
			end
		end
	end
	local cfsTemp = table.create(#pieces)

	-- caméra et interface
	controles(false)
	camera.CameraType = Enum.CameraType.Scriptable
	local fovAvant = camera.FieldOfView
	for _, b in bandes do
		TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0.11)}):Play()
	end
	son(SONS.grondement, 0.7, 0.45)
	son(SONS.feu, 0.5, 0.8)

	local rng = Random.new()
	local t0 = os.clock()
	local fait = {}
	local function une(cle: string, t: number, f: () -> ())
		if not fait[cle] and os.clock() - t0 >= t then
			fait[cle] = true
			f()
		end
	end
	local roi: Model? = nil
	while true do
		local t = os.clock() - t0
		if t >= duree then
			break
		end
		roi = if roi and roi.Parent then roi else trouverRoi(bassin)
		local h = if roi then (roi:GetAttribute("Hauteur") or 10) else 10
		local pRoi = if roi and roi.PrimaryPart then roi.PrimaryPart.Position else bassin
		local k = math.clamp(t / 2.6, 0, 1)

		-- lave, flammes, lumière
		bouillons.Rate = 8 + 22 * k
		vapeur.Rate = 2 + 6 * k
		lueur.Brightness = 0.4 + 0.6 * k -- reste sobre : le roi et le trône doivent rester lisibles
		for _, e in anneau do
			e.Rate = if t > 1 then 4 + 10 * math.clamp((t - 1) / 1.6, 0, 1) else 0
			e.Speed = NumberRange.new(4 + 8 * k, 9 + 12 * k)
		end
		for _, f in feux do
			f.e.Rate = f.rate * (1 + 0.6 * k)
		end
		une("gerbe", 2.8, function()
			gerbe(centreB, 0.8, dossier)
			son(SONS.eau, 0.9, 0.6)
			son(SONS.casse, 0.8, 0.7)
		end)
		une("cri", 5.6, function()
			son(SONS.cri, 0.9, 0.55)
			son(SONS.grondement, 0.8, 0.35)
			gerbe(pRoi + Vector3.new(0, 1, 0), 0.4, dossier)
		end)
		une("titre", 6, function()
			carte.Visible = true
			echelleTitre.Scale = 1.25
			TweenService:Create(carte, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {GroupTransparency = 0}):Play()
			TweenService:Create(echelleTitre, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end)
		une("finTitre", duree - 0.6, function()
			TweenService:Create(carte, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {GroupTransparency = 1}):Play()
		end)

		-- secousse
		local secousse = if t < 2.6 then 0.04 + 0.2 * k elseif t < 5.6 then 0.3 elseif t < 6.6 then 0.9 * (1 - (t - 5.6)) + 0.1 else 0.08
		-- le trône tremble jusqu'au surgissement
		if #pieces > 0 then
			local a = if t < 5.6 then 0.03 + 0.12 * k else 0
			local ofs = Vector3.new(rng:NextNumber(-a, a), rng:NextNumber(-a, a) * 0.5, rng:NextNumber(-a, a))
			for i, c in cfs0 do
				cfsTemp[i] = c + ofs
			end
			workspace:BulkMoveTo(pieces, cfsTemp, Enum.BulkMoveMode.FireCFrameChanged)
		end

		-- plans
		local oeil, vise, fov
		if t < 2.6 then
			oeil = (cf * CFrame.new(6.5, 10, 4)).Position:Lerp((cf * CFrame.new(5, 9, 2.5)).Position, k)
			vise = centreB + Vector3.new(0, 1.5, 0)
			fov = 70 - 8 * k
		elseif t < 5.6 then
			local u = math.clamp((t - 2.6) / 3, 0, 1)
			oeil = bassin - L * 7.5 + R * 3 + Vector3.new(0, 1.8, 0)
			vise = pRoi + Vector3.new(0, h * (0.35 + 0.3 * u), 0)
			fov = 66
		else
			local u = math.clamp((t - 5.6) / (duree - 5.6), 0, 1)
			oeil = bassin - L * (6 - 1.2 * u) + R * 1.4 + Vector3.new(0, h * 0.5, 0)
			vise = pRoi + Vector3.new(0, h * 0.78, 0)
			fov = 50 - 8 * u
		end
		camera.FieldOfView = fov
		camera.CFrame = CFrame.lookAt(oeil, vise) * CFrame.Angles(rng:NextNumber(-1, 1) * secousse * 0.02, rng:NextNumber(-1, 1) * secousse * 0.02, 0)
			* CFrame.new(rng:NextNumber(-1, 1) * secousse * 0.15, rng:NextNumber(-1, 1) * secousse * 0.15, 0)
		RunService.RenderStepped:Wait()
	end

	-- retour au jeu
	if #pieces > 0 then
		workspace:BulkMoveTo(pieces, cfs0, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for _, f in feux do
		if f.e.Parent then
			f.e.Rate = f.rate
		end
	end
	for _, e in anneau do
		e.Rate = 0
	end
	bouillons.Rate, vapeur.Rate = 0, 0
	TweenService:Create(lueur, TweenInfo.new(1.5), {Brightness = 0}):Play()
	Debris:AddItem(dossier, 2)
	carte.Visible = false
	for _, b in bandes do
		TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0)}):Play()
	end
	camera.FieldOfView = fovAvant
	camera.CameraType = Enum.CameraType.Custom
	local hum = joueur.Character and joueur.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		camera.CameraSubject = hum
	end
	controles(true)
	enCinematique = false
end

-- ================= Attaques spéciales (effets locaux, sobres ; dégâts et zones : TroneLave côté serveur) =================
-- Onde de feu : anneau de petites flammes qui s'élargit au ras du sol jusqu'au rayon de l'onde
local function ondeFeu(d)
	local centre, rayon, duree = d.pos, tonumber(d.rayon) or 16, tonumber(d.duree) or 0.7
	if typeof(centre) ~= "Vector3" then
		return
	end
	local dossier = creer("Folder", {Name = "OndeRoi", Parent = workspace})
	local n = 22
	for k = 0, n - 1 do
		local a = k / n * 2 * math.pi
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = ancre(CFrame.new(centre + Vector3.new(0, 0.6, 0)), Vector3.new(1.6, 0.8, 1.6), dossier)
		emetteur(p, {Texture = TEX_FEU, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE, BRAISE), EmissionDirection = Enum.NormalId.Top,
			Transparency = TRANSPARENCE_FEU, Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.2)}),
			Lifetime = NumberRange.new(0.3, 0.5), Speed = NumberRange.new(3, 6), Rate = 30})
		TweenService:Create(p, TweenInfo.new(duree, Enum.EasingStyle.Linear), {CFrame = CFrame.new(centre + dir * rayon + Vector3.new(0, 0.6, 0))}):Play()
	end
	son(SONS.casse, 0.6, 0.6)
	task.delay(duree, function()
		for _, p in dossier:GetChildren() do
			local e = p:FindFirstChildOfClass("ParticleEmitter")
			if e then
				e.Enabled = false
			end
		end
		Debris:AddItem(dossier, 0.8)
	end)
end

-- Pluie de météores : un rocher sombre à traîne de feu tombe sur chaque cercle rouge et éclate à l'impact
local CHUTE = 0.7 -- s de chute (le rocher arrive à l'heure de l'impact)
local function meteoresFeu(d)
	if type(d.impacts) ~= "table" then
		return
	end
	local rng = Random.new()
	son(SONS.grondement, 0.5, 0.5)
	for _, im in d.impacts do
		local pos, t = im.pos, tonumber(im.t) or 1
		if typeof(pos) == "Vector3" then
			task.delay(math.max(0, t - CHUTE), function()
				local haut = pos + Vector3.new(rng:NextNumber(-6, 6), 38, rng:NextNumber(-6, 6))
				local roc = creer("Part", {Name = "Meteore", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.new(2.2, 2.2, 2.2),
					Color = Color3.fromRGB(46, 30, 26), Material = Enum.Material.Basalt, CFrame = CFrame.new(haut), Parent = workspace})
				emetteur(roc, {Texture = TEX_FEU, LightEmission = LUMIERE_PARTICULES, Color = ColorSequence.new(LAVE, BRAISE), Transparency = TRANSPARENCE_FEU,
					Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0.4)}), Lifetime = NumberRange.new(0.3, 0.5),
					Speed = NumberRange.new(0.5, 1), Rate = 40})
				TweenService:Create(roc, TweenInfo.new(CHUTE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))}):Play()
				task.delay(CHUTE, function()
					roc:Destroy()
					gerbe(pos + Vector3.new(0, 0.3, 0), 0.35)
					son(SONS.casse, 0.5, 0.8 + rng:NextNumber(0, 0.3))
				end)
			end)
		end
	end
end

remote.OnClientEvent:Connect(function(genre: string, d)
	d = if type(d) == "table" then d else {}
	if genre == "Intro" then
		task.spawn(intro, d)
	elseif genre == "Eveil" then
		toast("Le Roi déchu s'est éveillé sur son trône de magma !", false)
	elseif genre == "Combat" then
		toast("Le Roi déchu ne lâche jamais sa proie… ses coups brûlent !", false)
		UI.jouer("metal", 0.6)
	elseif genre == "Onde" then
		ondeFeu(d)
	elseif genre == "Meteores" then
		meteoresFeu(d)
	elseif genre == "Retour" then
		if typeof(d.pos) == "Vector3" then
			gerbe(d.pos, 0.8)
		end
		son(SONS.eau, 0.7, 0.5)
		toast("Le Roi déchu replonge dans la lave…", false, "info")
	elseif genre == "Defaite" then
		toast("Le trône se refroidit… le roi reviendra.", false, "info")
	elseif genre == "Victoire" then
		toast("Le Roi déchu est vaincu !", true)
		task.delay(3.5, function()
			PopupCoffre.afficher({titre = "Trésor du Roi déchu", theme = "Fonderie", sousTitre = "Le Roi déchu retourne aux cendres",
				recompenses = {{genre = "pieces", n = tonumber(d.pieces) or 0}, {genre = "minerai", id = "Gold", n = tonumber(d.gold) or 0}}})
		end)
	end
end)
