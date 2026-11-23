-- Boss du village · CLIENT, fin du combat (module de BossVillage.client) :
-- « Fin »       : bannière VICTOIRE (dorée, éclat, confettis, grosse secousse) ou ÉCHEC (rouge, grondement), ~2 s.
-- « Resultats » : écran de résultats : titre, temps du combat, MVP (couronne), classement des dégâts de tous les
--                 participants (avatar, nom, dégâts, barre proportionnelle, pièces gagnées), ma ligne surlignée,
--                 bouton « Retour au village » (retour anticipé, validé par le serveur) + retour automatique.
--                 Vu depuis le village (K.O. pendant le combat) : bouton « Fermer ».
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local Outils = require(script.Parent:WaitForChild("BossOutils"))
local creer, coin, trait, texte, T = UI.creer, UI.coin, UI.trait, UI.texte, UI.T

local Resultats = {}

local ARGENT = Color3.fromRGB(205, 214, 226)
local BRONZE = Color3.fromRGB(214, 140, 84)

function Resultats.init(ctx)
	local cinema: ScreenGui = ctx.cinema
	local Config = ctx.Config
	local joueur: Player = ctx.joueur

	-- ================= Bannière de fin =================
	local scene = creer("Frame", {Name = "FinScene", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = cinema})
	local banniere = creer("CanvasGroup", {Name = "Banniere", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromScale(0.8, 0.24), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 11, Parent = cinema})
	local banniereFond = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.62),
		BackgroundColor3 = Color3.fromRGB(26, 16, 8), BorderSizePixel = 0, Parent = banniere}, {creer("UIGradient", {Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.22, 0.2), NumberSequenceKeypoint.new(0.78, 0.2), NumberSequenceKeypoint.new(1, 1)})})})
	local filets: {Frame} = {}
	for _, y in {0.19, 0.81} do
		table.insert(filets, creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, y), Size = UDim2.new(0.9, 0, 0, 2),
			BackgroundColor3 = T.Or, BorderSizePixel = 0, Parent = banniere}, {creer("UIGradient", {Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 1)})})}))
	end
	local banniereTitre = texte({Font = Enum.Font.Fantasy, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.fromScale(0.9, 0.52), Parent = banniere}, 120)
	local degradeTitre = creer("UIGradient", {Rotation = 90, Parent = banniereTitre})
	creer("UIStroke", {Thickness = 3, Color = Color3.fromRGB(30, 14, 6), Parent = banniereTitre})
	local banniereSous = texte({Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromScale(0.8, 0.14), Parent = banniere}, 30)
	creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(30, 14, 6), Parent = banniereSous})
	local numeroFin = 0

	local DORE = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 210)), ColorSequenceKeypoint.new(0.5, T.Or),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 120, 36))})
	local SANG = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 170)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 50, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 8))})

	local api = {}

	function api.fin(d)
		if type(d) ~= "table" then return end
		numeroFin += 1
		local n = numeroFin
		local victoire = d.victoire == true
		local couleur = if typeof(d.couleur) == "Color3" then d.couleur else T.Or
		banniereTitre.Text = if victoire then "VICTOIRE" else "ÉCHEC"
		degradeTitre.Color = if victoire then DORE else SANG
		banniereSous.Text = if victoire then tostring(d.nom or "Le boss") .. " est vaincu !" else tostring(d.raison or (tostring(d.nom or "Le boss") .. " l'emporte."))
		banniereFond.BackgroundColor3 = if victoire then Color3.fromRGB(30, 20, 8) else Color3.fromRGB(34, 6, 4)
		for _, f in filets do f.BackgroundColor3 = if victoire then T.Or else T.Rouge end
		banniere.Visible = true
		banniere.GroupTransparency = 0
		local e = UI.echelle(banniere)
		e.Scale = 2.2
		TweenService:Create(e, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		local dansArene = joueur:GetAttribute("DansArene") == true
		if victoire then
			UI.celebrer(scene, couleur)
			for k = 1, 3 do
				task.delay(k * 0.45, function()
					if numeroFin == n then UI.gerbe(scene, if k % 2 == 0 then T.Or else couleur, 18, Vector2.new(0.2 + math.random() * 0.6, 0.25 + math.random() * 0.3)) end
				end)
			end
			if dansArene then Outils.secouer(0.9) end
			Outils.jouer("impact", 0.45, 0.6)
			Outils.jouer("ping", 0.8, 0.6)
			task.delay(0.25, function() Outils.jouer("lame", 0.9) end)
		else
			if dansArene then Outils.secouer(0.5) end
			Outils.jouer("grondement", 0.4, 0.6)
		end
		task.delay(Config.BANNIERE_FIN - 0.3, function()
			if numeroFin ~= n then return end
			local t = TweenService:Create(banniere, TweenInfo.new(0.35), {GroupTransparency = 1})
			t.Completed:Once(function()
				if numeroFin == n then banniere.Visible = false end
			end)
			t:Play()
		end)
	end

	-- ================= Écran de résultats =================
	local ecran: Frame? = nil
	local numeroEcran = 0

	local function fermer(instantane: boolean?)
		local e = ecran
		if not e then return end
		ecran = nil
		numeroEcran += 1
		if instantane then
			e:Destroy()
			return
		end
		local racine = e:FindFirstChild("Panneau") :: Frame?
		if racine then
			TweenService:Create(UI.echelle(racine), UI.FAST, {Scale = 0.9}):Play()
			TweenService:Create(racine, UI.FAST, {Position = UDim2.fromScale(0.5, 0.56)}):Play()
		end
		TweenService:Create(e, UI.FAST, {BackgroundTransparency = 1}):Play()
		task.delay(0.17, function() e:Destroy() end)
	end
	api.fermer = fermer

	local function piece(parent: Instance, props: {[string]: any}): Frame
		props.SizeConstraint = Enum.SizeConstraint.RelativeYY
		props.BackgroundColor3 = T.Or
		props.Parent = parent
		local p = creer("Frame", props, {coin(0.5), trait(T.OrFonce, 1.5), UI.degrade(Color3.fromRGB(255, 250, 210), Color3.fromRGB(200, 130, 30), 45)})
		creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.55, 0.55), BackgroundTransparency = 1,
			ZIndex = props.ZIndex, Parent = p}, {coin(0.5), trait(T.OrFonce, 1.2, 0.3)})
		return p
	end

	function api.afficher(d)
		if type(d) ~= "table" or type(d.lignes) ~= "table" then return end
		fermer(true)
		numeroEcran += 1
		local n = numeroEcran
		local victoire = d.victoire == true
		local couleur = if typeof(d.couleur) == "Color3" then d.couleur else T.Or
		local monId = joueur.UserId
		local dansArene = joueur:GetAttribute("DansArene") == true

		local voile = creer("Frame", {Name = "Resultats", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Voile, BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 20, Parent = cinema})
		ecran = voile
		TweenService:Create(voile, UI.DOUX, {BackgroundTransparency = 0.35}):Play()

		local racine = creer("Frame", {Name = "Panneau", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.9, 0.84),
			BackgroundColor3 = Color3.fromRGB(56, 34, 21), ZIndex = 21, Parent = voile}, {coin(0.03), trait(Color3.fromRGB(18, 10, 6), 4),
			creer("UIAspectRatioConstraint", {AspectRatio = 1.3}), creer("UISizeConstraint", {MaxSize = Vector2.new(900, 692)})})
		local echelle = UI.echelle(racine)
		echelle.Scale = 0.85
		TweenService:Create(echelle, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		TweenService:Create(racine, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		Outils.jouer("souffle", 0.9)

		local interieur = creer("Frame", {Position = UDim2.fromScale(0.015, 0.02), Size = UDim2.fromScale(0.97, 0.96), BackgroundColor3 = T.Pierre,
			ClipsDescendants = true, ZIndex = 21, Parent = racine}, {coin(0.02), trait(Color3.fromRGB(20, 13, 9), 3),
			creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(176, 166, 166)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(236, 220, 206)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 196, 150))})})})
		creer("Frame", {Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = if victoire then couleur else T.Rouge, BorderSizePixel = 0, ZIndex = 22, Parent = interieur})

		-- En-tête : titre, boss, temps, nombre de mineurs
		local titre = texte({Text = if victoire then "VICTOIRE" else "ÉCHEC", Font = Enum.Font.Fantasy, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.035, 0.03), Size = UDim2.fromScale(0.5, 0.1), ZIndex = 22, Parent = interieur}, 60)
		if victoire then
			UI.dore(titre, 2.5)
		else
			creer("UIGradient", {Rotation = 90, Color = SANG, Parent = titre})
			creer("UIStroke", {Thickness = 2.5, Color = Color3.fromRGB(30, 6, 4), Parent = titre})
		end
		local sousTitre = texte({Text = tostring(d.nom or "Boss") .. " — " .. tostring(d.titre or ""), Font = Enum.Font.GothamBlack,
			TextColor3 = couleur:Lerp(Color3.new(1, 1, 1), 0.3), TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.037, 0.13), Size = UDim2.fromScale(0.55, 0.045), ZIndex = 22, Parent = interieur}, 22)
		creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(20, 10, 6), Parent = sousTitre})
		local lignes = d.lignes :: {any}
		local function stat(x: number, etiquette: string, valeur: string)
			local c = creer("Frame", {Position = UDim2.fromScale(x, 0.035), Size = UDim2.fromScale(0.16, 0.13), BackgroundColor3 = Color3.fromRGB(22, 15, 11),
				BackgroundTransparency = 0.2, ZIndex = 22, Parent = interieur}, {coin(0.15), trait(T.OrFonce, 1.5, 0.3)})
			texte({Text = etiquette, Font = Enum.Font.GothamBold, TextColor3 = T.Gris, Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.3),
				ZIndex = 23, Parent = c}, 14)
			texte({Text = valeur, Font = Enum.Font.GothamBlack, TextColor3 = T.Parchemin, Position = UDim2.fromScale(0.08, 0.42), Size = UDim2.fromScale(0.84, 0.48),
				ZIndex = 23, Parent = c}, 28)
		end
		stat(0.62, "TEMPS DU COMBAT", Config.minutes(tonumber(d.duree) or 0))
		stat(0.8, "MINEURS", tostring(#lignes))

		-- MVP
		local maxDegats = 1
		for _, l in lignes do maxDegats = math.max(maxDegats, tonumber(l.degats) or 0) end
		local mvp = nil
		for _, l in lignes do
			if l.id == d.mvp then mvp = l end
		end
		local yListe = 0.2
		if mvp then
			yListe = 0.37
			local carte = creer("Frame", {Position = UDim2.fromScale(0.035, 0.2), Size = UDim2.fromScale(0.93, 0.15), BackgroundColor3 = Color3.fromRGB(40, 28, 14),
				BackgroundTransparency = 0.1, ZIndex = 22, Parent = interieur}, {coin(0.14), trait(T.Or, 2.5),
				UI.degrade(Color3.fromRGB(255, 235, 190), Color3.fromRGB(140, 110, 80), 0)})
			local halo = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.08, 0.55), Size = UDim2.fromScale(1.15, 1.15),
				SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundColor3 = T.Or, ZIndex = 22, Parent = carte}, {coin(0.5),
				creer("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.3, 1),
					NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 0.2)})})})
			local tourne = TweenService:Create(halo, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
			tourne:Play()
			voile.Destroying:Once(function() tourne:Cancel() end)
			Outils.medaillon(carte, mvp.id, tostring(mvp.nom), T.Or, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.08, 0.55),
				Size = UDim2.fromScale(0.8, 0.8), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 23})
			Outils.couronne(carte, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.08, 0.22), Size = UDim2.fromScale(0.5, 0.42),
				SizeConstraint = Enum.SizeConstraint.RelativeYY, Rotation = -12, ZIndex = 25})
			local badge = creer("Frame", {Position = UDim2.fromScale(0.16, 0.14), Size = UDim2.fromScale(0.09, 0.32), BackgroundColor3 = T.Or, ZIndex = 23,
				Parent = carte}, {coin(0.3), trait(T.OrFonce, 1.5), UI.degrade(Color3.fromRGB(255, 245, 200), Color3.fromRGB(210, 140, 40))})
			texte({Text = "MVP", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(60, 30, 8), Position = UDim2.fromScale(0.08, 0.1),
				Size = UDim2.fromScale(0.84, 0.8), ZIndex = 24, Parent = badge}, 20)
			local nomMvp = texte({Text = tostring(mvp.nom), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = if mvp.id == monId then T.Or else T.Parchemin, Position = UDim2.fromScale(0.27, 0.1), Size = UDim2.fromScale(0.45, 0.4),
				ZIndex = 23, Parent = carte}, 30)
			creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(20, 10, 6), Parent = nomMvp})
			texte({Text = "Meilleur combattant · " .. UI.milliers(tonumber(mvp.degats) or 0) .. " dégâts", Font = Enum.Font.GothamBold, TextColor3 = T.Parchemin,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.16, 0.56), Size = UDim2.fromScale(0.6, 0.3), ZIndex = 23, Parent = carte}, 20)
			if (tonumber(mvp.pieces) or 0) > 0 then
				piece(carte, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.975, 0.5), Size = UDim2.fromScale(0.42, 0.42), ZIndex = 23})
				texte({Text = "+" .. UI.milliers(tonumber(mvp.pieces) or 0), Font = Enum.Font.GothamBlack, TextColor3 = T.Or, TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.9, 0.5), Size = UDim2.fromScale(0.18, 0.42), ZIndex = 23, Parent = carte}, 30)
			end
			task.delay(0.35, function()
				if numeroEcran == n then
					Outils.jouer("lame", 1.1)
					UI.pop(carte, 0.85)
				end
			end)
		end

		-- En-têtes de colonnes
		local colonnes = creer("Frame", {Position = UDim2.fromScale(0.035, yListe), Size = UDim2.fromScale(0.93, 0.04), BackgroundTransparency = 1, ZIndex = 22,
			Parent = interieur})
		for _, c in {{"#", 0, 0.06, Enum.TextXAlignment.Center}, {"MINEUR", 0.15, 0.3, Enum.TextXAlignment.Left},
			{"DÉGÂTS", 0.46, 0.36, Enum.TextXAlignment.Left}, {"PIÈCES", 0.84, 0.15, Enum.TextXAlignment.Right}} do
			texte({Text = c[1], Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, TextXAlignment = c[4], Position = UDim2.fromScale(c[2], 0),
				Size = UDim2.fromScale(c[3], 1), ZIndex = 22, Parent = colonnes}, 14)
		end

		-- Classement
		local hautListe = 0.86 - (yListe + 0.045)
		local liste = creer("ScrollingFrame", {Position = UDim2.fromScale(0.035, yListe + 0.045), Size = UDim2.fromScale(0.93, hautListe),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = T.OrFonce, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 22, Parent = interieur},
			{creer("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}), creer("UIPadding", {PaddingRight = UDim.new(0, 8)})})
		local hLigne = math.clamp(math.floor(math.min(cinema.AbsoluteSize.Y * 0.84, 692) * 0.065), 28, 46)

		local function ligne(l, ordre: number, delai: number)
			local moi = l.id == monId
			local rang = tonumber(l.rang) or ordre
			local f = creer("Frame", {Size = UDim2.new(1, 0, 0, hLigne), LayoutOrder = ordre, ZIndex = 22, Parent = liste,
				BackgroundColor3 = if moi then Color3.fromRGB(70, 52, 20) else Color3.fromRGB(24, 17, 13), BackgroundTransparency = if moi then 0.05 else 0.3},
				{coin(0.25), trait(if moi then T.Or else Color3.fromRGB(14, 9, 6), if moi then 2.5 else 1, if moi then 0 else 0.4)})
			local couleurRang = if rang == 1 then T.Or elseif rang == 2 then ARGENT elseif rang == 3 then BRONZE else T.Gris
			texte({Text = tostring(rang), Font = Enum.Font.GothamBlack, TextColor3 = couleurRang, Position = UDim2.fromScale(0, 0.15), Size = UDim2.fromScale(0.06, 0.7),
				ZIndex = 23, Parent = f}, 24)
			Outils.medaillon(f, tonumber(l.id) or 0, tostring(l.nom), if moi then T.Or else couleurRang, {AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.07, 0.5), Size = UDim2.fromScale(0.8, 0.8), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 23})
			local nom = texte({Text = tostring(l.nom) .. (if moi then "  (toi)" else ""), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = if moi then T.Or else T.Parchemin, Position = UDim2.fromScale(0.15, 0.2), Size = UDim2.fromScale(0.3, 0.6), ZIndex = 23, Parent = f}, 22)
			nom.TextTruncate = Enum.TextTruncate.AtEnd
			local fond = creer("Frame", {Position = UDim2.fromScale(0.46, 0.22), Size = UDim2.fromScale(0.36, 0.56), BackgroundColor3 = Color3.fromRGB(14, 10, 8),
				BorderSizePixel = 0, ZIndex = 23, Parent = f}, {coin(0.3)})
			local r = math.clamp((tonumber(l.degats) or 0) / maxDegats, 0, 1)
			local barre = creer("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = if moi then T.Or else couleur, BorderSizePixel = 0, ZIndex = 24,
				Parent = fond}, {coin(0.3), UI.degrade(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150))})
			local valeur = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.92, 0.8), ZIndex = 25, Parent = fond}, 18)
			creer("UIStroke", {Thickness = 1.5, Color = Color3.fromRGB(16, 8, 4), Parent = valeur})
			local compte = UI.compteur(valeur, function(v) return UI.milliers(v) end)
			local pieces = tonumber(l.pieces) or 0
			texte({Text = if pieces > 0 then "+" .. UI.milliers(pieces) else "—", Font = Enum.Font.GothamBlack,
				TextColor3 = if pieces > 0 then T.Or else T.Gris, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.83, 0.2),
				Size = UDim2.fromScale(0.11, 0.6), ZIndex = 23, Parent = f}, 22)
			if pieces > 0 then
				piece(f, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.995, 0.5), Size = UDim2.fromScale(0.5, 0.5), ZIndex = 23})
			end
			-- entrée en cascade : la ligne glisse, la barre pousse, le chiffre compte
			local e = UI.echelle(f)
			e.Scale = 0.9
			f.BackgroundTransparency = 1
			task.delay(delai, function()
				if numeroEcran ~= n then return end
				TweenService:Create(e, UI.BOUNCY, {Scale = 1}):Play()
				TweenService:Create(f, UI.FAST, {BackgroundTransparency = if moi then 0.05 else 0.3}):Play()
				TweenService:Create(barre, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(r, 1)}):Play()
				compte(tonumber(l.degats) or 0)
				if moi then Outils.jouer("ping", 1.1, 0.35) end
			end)
			return f
		end

		local maLigne = nil
		for i, l in lignes do
			local f = ligne(l, i, 0.5 + math.min(i, 12) * 0.06)
			if l.id == monId then maLigne = f end
		end
		if type(d.moi) == "table" then
			texte({Text = "…", Font = Enum.Font.GothamBlack, TextColor3 = T.Gris, Size = UDim2.new(1, 0, 0, math.floor(hLigne * 0.6)),
				LayoutOrder = #lignes + 1, ZIndex = 22, Parent = liste}, 20)
			maLigne = ligne(d.moi, #lignes + 2, 0.5 + 13 * 0.06)
		end
		if maLigne then -- ma ligne visible même au-delà de l'écran
			task.delay(0.6, function()
				if numeroEcran ~= n or not maLigne.Parent then return end
				local y = maLigne.AbsolutePosition.Y - liste.AbsolutePosition.Y + liste.CanvasPosition.Y
				if y + hLigne > liste.AbsoluteSize.Y then
					TweenService:Create(liste, UI.DOUX, {CanvasPosition = Vector2.new(0, y - liste.AbsoluteSize.Y * 0.5)}):Play()
				end
			end)
		end

		-- Bas : bouton + retour automatique
		local bouton = creer("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.925),
			Size = UDim2.fromScale(0.34, 0.075), BackgroundColor3 = if dansArene then T.Vert else T.Fer, ZIndex = 22, Parent = interieur},
			{coin(0.25), trait(Color3.fromRGB(24, 14, 8), 3), creer("UIGradient", {Rotation = 90, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 225, 225)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140))})})})
		local texteBouton = texte({Text = if dansArene then "Retour au village" else "Fermer", Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.06, 0.2), Size = UDim2.fromScale(0.88, 0.6), ZIndex = 23, Parent = bouton}, 26)
		creer("UIStroke", {Thickness = 2, Color = Color3.fromRGB(24, 14, 8), Parent = texteBouton})
		UI.reactif(bouton, 1.04)
		local auto = texte({Font = Enum.Font.GothamBold, TextColor3 = T.Gris, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.7, 0.9), Size = UDim2.fromScale(0.27, 0.05), ZIndex = 22, Parent = interieur}, 16)
		local demande = false
		bouton.Activated:Connect(function()
			if demande or numeroEcran ~= n then return end
			Outils.jouer("clic")
			if joueur:GetAttribute("DansArene") == true then
				demande = true
				bouton.Active = false
				texteBouton.Text = "Retour…"
				TweenService:Create(bouton, UI.FAST, {BackgroundColor3 = T.Inactif}):Play()
				ctx.action:FireServer("Retour") -- le serveur valide (combat fini, joueur dans l'arène) puis envoie « Retour »
			else
				fermer()
			end
		end)
		local finAuto = os.clock() + (tonumber(d.retour) or Config.RESULTATS)
		task.spawn(function()
			while numeroEcran == n do
				local r = math.max(0, math.ceil(finAuto - os.clock()))
				auto.Text = if joueur:GetAttribute("DansArene") == true then "Retour automatique dans " .. r .. " s" else "Fermeture dans " .. r .. " s"
				if r <= 0 then
					if joueur:GetAttribute("DansArene") ~= true then fermer() end
					break
				end
				task.wait(0.25)
			end
		end)
		if victoire then
			task.delay(0.2, function()
				if numeroEcran == n then UI.gerbe(voile, couleur, 22, Vector2.new(0.5, 0.15)) end
			end)
		end
	end

	return api
end

return Resultats
