-- Boss du village · CLIENT, transitions et intro (module de BossVillage.client) :
-- « Depart »  : fondu au noir (0,6 s ; 0,35 s pour rejoindre), puis écran de chargement propre au boss (module
--               BossChargement : décor, portrait 3D, nom en impact, infos du combat, jauge, astuces), contrôles bloqués.
-- « Intro »   : la barre se remplit, bandes noires, caméra Scriptable : plan large qui tourne autour de l'arène,
--               plan bas sur le boss qui rugit (FOV 70 → 55, forte secousse), carte de nom façon Souls, puis les
--               bandes repartent et la caméra revient au joueur. Bouton « Passer » : n'abrège que l'affichage local.
-- « Arrivee » / « Annule » : fin du chargement sans intro (rejoindre en cours de combat, départ annulé).
-- « Retour »  : fondu au noir, attente de la téléportation (DansArene retiré par le serveur), fondu retour.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local Cinematique = {}

function Cinematique.init(ctx)
	local cinema: ScreenGui = ctx.cinema
	local Config = ctx.Config
	local joueur: Player = ctx.joueur

	-- ================= Voile noir =================
	local voile = creer("Frame", {Name = "Voile", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Visible = false, ZIndex = 45, Parent = cinema})
	local tweenVoile: Tween? = nil
	local function fondu(opaque: boolean, duree: number)
		if tweenVoile then tweenVoile:Cancel() end
		voile.Visible = true
		local t = TweenService:Create(voile, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundTransparency = if opaque then 0 else 1})
		tweenVoile = t
		if not opaque then
			t.Completed:Once(function(etat)
				if etat == Enum.PlaybackState.Completed then voile.Visible = false end
			end)
		end
		t:Play()
	end

	-- ================= Écran de chargement =================
	-- Visuel et animations dans BossChargement (un décor par boss, portrait 3D, jauge thématique) ; ici, seulement
	-- les mêmes points d'entrée qu'avant pour le déroulé.
	local Ecran = require(script.Parent:WaitForChild("BossChargement")).creer(cinema, Config, ctx.dossier)
	local chargement = Ecran.racine
	local etatCharge = Ecran.etat
	local progresser = Ecran.progresser

	local function montrerChargement(d)
		Ecran.montrer(d)
		progresser(0.88, if d.court then 0.8 else Config.DELAI_DEPART + 1.6)
	end

	local function cacherChargement()
		Ecran.cacher()
	end

	-- ================= Bandes cinéma, carte de nom, bouton Passer =================
	local bandes: {Frame} = {}
	for i, y in {0, 1} do
		bandes[i] = creer("Frame", {AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 40, Parent = cinema})
	end
	local function bandesCinema(entrer: boolean, duree: number)
		for _, b in bandes do
			TweenService:Create(b, TweenInfo.new(duree, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, if entrer then 0.12 else 0)}):Play()
		end
	end

	local carte = creer("CanvasGroup", {Name = "CarteNom", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.8, 0.2),
		BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 42, Parent = cinema})
	local carteNom = texte({Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.55),
		Parent = carte}, 96)
	UI.dore(carteNom, 3)
	local carteTrait = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.new(0, 0, 0, 3),
		BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = carte}, {creer("UIGradient", {Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1)})})})
	local carteTitre = texte({Font = Enum.Font.Antique, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.8, 0.26),
		Parent = carte}, 40)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(10, 5, 3), Parent = carteTitre})

	local passer = creer("TextButton", {Name = "Passer", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.97, 0, 0.94, 0),
		Size = UDim2.fromScale(0.09, 0.045), BackgroundColor3 = Color3.fromRGB(30, 22, 16), BackgroundTransparency = 0.25, Visible = false, ZIndex = 43,
		Parent = cinema}, {coin(0.3), trait(T.Gris, 1.5, 0.4), creer("UISizeConstraint", {MinSize = Vector2.new(80, 28), MaxSize = Vector2.new(130, 40)})})
	texte({Text = "Passer", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.1, 0.18), Size = UDim2.fromScale(0.8, 0.64),
		ZIndex = 44, Parent = passer}, 18)
	UI.reactif(passer, 1.06)

	-- ================= Déroulé =================
	local session = 0
	local controlesPris = false
	local enIntro = false
	local fovAvant = 70
	local camera = workspace.CurrentCamera

	local function prendre()
		if not controlesPris then
			controlesPris = true
			Outils.controles(false)
		end
	end
	local function rendre()
		if controlesPris then
			controlesPris = false
			Outils.controles(true)
		end
	end

	-- pendant le chargement et l'intro, les autres interfaces du jeu (HUD, quêtes, sac…) sont masquées : image de cinéma
	local masquees: {ScreenGui} = {}
	local function masquerAutres(masquer: boolean)
		if masquer then
			for _, g in joueur.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and g ~= cinema and g.Name ~= "BossVillage" then
					g.Enabled = false
					table.insert(masquees, g)
				end
			end
		else
			for _, g in masquees do
				if g.Parent then g.Enabled = true end
			end
			table.clear(masquees)
		end
	end

	local function debut()
		ctx.etat.cinematique = true
		ctx.majVisibilite()
		prendre()
		masquerAutres(true)
	end
	local function fin()
		ctx.etat.cinematique = false
		rendre()
		masquerAutres(false)
		ctx.majVisibilite()
	end

	-- caméra posée derrière le personnage avant de rendre la main à la caméra Roblox
	local function rendreCamera(fov: number?)
		camera = workspace.CurrentCamera
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humain = perso and perso:FindFirstChildOfClass("Humanoid")
		if racine then
			local p = racine.Position
			camera.CFrame = CFrame.lookAt(p - racine.CFrame.LookVector * 12 + Vector3.new(0, 5, 0), p + Vector3.new(0, 1.5, 0))
		end
		if humain then camera.CameraSubject = humain end
		camera.CameraType = Enum.CameraType.Custom
		if fov then camera.FieldOfView = fov end
	end

	local connexionPasser: RBXScriptConnection? = nil

	local function finirIntro()
		if not enIntro then return end
		enIntro = false
		RunService:UnbindFromRenderStep("BossIntro")
		if connexionPasser then
			connexionPasser:Disconnect()
			connexionPasser = nil
		end
		passer.Visible = false
		bandesCinema(false, 0.4)
		TweenService:Create(carte, TweenInfo.new(0.35), {GroupTransparency = 1}):Play()
		task.delay(0.4, function()
			if not enIntro then carte.Visible = false end
		end)
		rendreCamera(fovAvant)
		fin()
	end

	local api = {}

	function api.depart(d)
		session += 1
		local s = session
		if enIntro then finirIntro() end
		debut()
		local duree = if d.court then 0.35 else Config.FONDU
		fondu(true, duree)
		Outils.jouer("souffle", 0.7)
		task.delay(duree, function()
			if session == s then montrerChargement(d) end
		end)
		-- filet : jamais bloqué sur l'écran de chargement
		task.delay(12, function()
			if session == s and chargement.Visible then
				cacherChargement()
				fondu(false, 0.5)
				fin()
			end
		end)
	end

	local function terminerChargement(s: number, suite: () -> ())
		progresser(1, 0.25, Enum.EasingStyle.Linear)
		etatCharge.Text = "Arène prête !"
		Outils.jouer("ping", 1.2, 0.3)
		task.delay(0.35, function()
			if session ~= s then return end
			cacherChargement()
			etatCharge.Text = "Chargement de l'arène…"
			suite()
		end)
	end

	function api.arrivee()
		session += 1
		local s = session
		if not ctx.etat.cinematique then debut() end
		terminerChargement(s, function()
			fondu(false, 0.5)
			fin()
		end)
	end

	function api.annule()
		session += 1
		if enIntro then finirIntro() end
		cacherChargement()
		fondu(false, 0.4)
		fin()
	end

	function api.intro(d)
		if enIntro then finirIntro() end
		session += 1
		local s = session
		if not ctx.etat.cinematique then debut() end
		terminerChargement(s, function()
			camera = workspace.CurrentCamera
			local centre: Vector3 = if typeof(d.centre) == "Vector3" then d.centre else Vector3.zero
			local boss = if typeof(d.boss) == "Instance" and d.boss:IsA("Model") then d.boss else nil
			local D = tonumber(d.duree) or Config.DUREE_INTRO
			local R = tonumber(d.roar) or Config.ROAR_INTRO
			local nom = ctx.dossier:GetAttribute("Nom") or "Boss"
			local titre = ctx.dossier:GetAttribute("Titre") or ""
			local couleur = ctx.dossier:GetAttribute("Couleur") or T.Or

			-- position, hauteur et face du boss (centre de l'arène si le modèle n'est pas encore là)
			local function infosBoss(): (Vector3, number, Vector3)
				if boss and boss.Parent then
					local pivot = boss:GetPivot()
					local h = boss:GetAttribute("Hauteur") or 20
					local avant = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z)
					return pivot.Position, h, if avant.Magnitude > 0.01 then avant.Unit else Vector3.zAxis
				end
				return centre, 20, Vector3.zAxis
			end

			enIntro = true
			fovAvant = if camera.FieldOfView > 1 then camera.FieldOfView else 70
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 70
			bandesCinema(true, 0.4)
			fondu(false, 0.6)
			passer.Visible = true
			carteNom.Text = string.upper(nom)
			carteTitre.Text = titre
			carteTitre.TextColor3 = couleur:Lerp(Color3.new(1, 1, 1), 0.35)
			carte.Visible, carte.GroupTransparency = true, 1
			carteTrait.Size = UDim2.new(0, 0, 0, 3)

			local t0 = os.clock()
			local _, _, avant0 = infosBoss()
			local a0 = math.atan2(avant0.X, avant0.Z) + math.pi * 0.75 -- départ de trois quarts dos, on tourne vers sa face
			local roarFait, carteFaite, sortieFaite = false, false, false
			local FOV_BAS = 55

			RunService:BindToRenderStep("BossIntro", Enum.RenderPriority.Camera.Value + 1, function()
				local t = os.clock() - t0
				local pos, h, avant = infosBoss()
				local cf: CFrame
				if t < R then
					-- 1. plan large qui tourne autour de l'arène
					local k = t / R
					local e = k * k * (3 - 2 * k)
					local a = a0 + e * 1.5
					local rayon = 70 - 12 * e
					local oeil = centre + Vector3.new(math.sin(a) * rayon, 34 - 12 * e, math.cos(a) * rayon)
					cf = CFrame.lookAt(oeil, pos + Vector3.new(0, h * 0.45, 0))
				else
					-- 2. plan bas sur le boss qui rugit, poussée lente, puis léger contournement pendant la carte de nom
					local k = math.clamp((t - R) / (D - R), 0, 1)
					local dist = (h * 0.9 + 9) * (1.12 - 0.12 * math.min(k * 2, 1))
					local cote = avant:Cross(Vector3.yAxis)
					local dir = (avant + cote * (0.15 + 0.35 * k)).Unit
					local oeil = pos + dir * dist + Vector3.new(0, 2.2 + k * 2.5, 0)
					cf = CFrame.lookAt(oeil, pos + Vector3.new(0, h * 0.72, 0))
					if not roarFait then
						roarFait = true
						TweenService:Create(camera, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = FOV_BAS}):Play()
					end
				end
				camera.CFrame = cf
				camera.Focus = CFrame.new(pos)
				if t >= R + 0.2 and not carteFaite and t < D - 0.6 then
					-- rugissement (le serveur passe le boss en « Roar » à R) : secousse forte + grondement
					carteFaite = true
					Outils.secouer(0.85)
					Outils.jouer("grondement", 0.55, 0.6)
					Outils.jouer("impact", 0.4, 0.5)
					task.delay(1.0, function()
						if not enIntro or session ~= s then return end
						Outils.jouer("lame", 0.8)
						TweenService:Create(carte, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {GroupTransparency = 0}):Play()
						TweenService:Create(carteTrait, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0.62, 0, 0, 3)}):Play()
						UI.pop(carteNom, 1.08)
					end)
				end
				if t >= D - 0.5 and not sortieFaite then
					sortieFaite = true
					bandesCinema(false, 0.45)
					TweenService:Create(carte, TweenInfo.new(0.4), {GroupTransparency = 1}):Play()
				end
				if t >= D then finirIntro() end
			end)

			-- Passer : saute à la sortie (affichage local seulement ; le serveur garde son minutage)
			connexionPasser = passer.Activated:Connect(function()
				if connexionPasser then
					connexionPasser:Disconnect()
					connexionPasser = nil
				end
				Outils.jouer("clic")
				if enIntro and session == s then t0 = os.clock() - (D - 0.5) end
			end)
		end)
	end

	function api.retour()
		session += 1
		local s = session
		if enIntro then finirIntro() end
		debut()
		fondu(true, Config.FONDU)
		Outils.jouer("souffle", 0.8)
		task.spawn(function()
			task.wait(Config.FONDU)
			local limite = os.clock() + 2.5
			while joueur:GetAttribute("DansArene") == true and os.clock() < limite do task.wait(0.05) end
			task.wait(0.3) -- laisse la zone autour du village s'afficher
			if session ~= s then return end
			cacherChargement()
			if ctx.fermerResultats then ctx.fermerResultats() end
			rendreCamera()
			fondu(false, Config.FONDU)
			fin()
			if ctx.puceRetour then ctx.puceRetour() end
		end)
	end

	-- Mort ou réapparition en pleine transition : on rend tout
	joueur.CharacterAdded:Connect(function()
		if ctx.etat.cinematique then
			session += 1
			if enIntro then finirIntro() end
			cacherChargement()
			fondu(false, 0.4)
			fin()
		end
	end)

	return api
end

return Cinematique
