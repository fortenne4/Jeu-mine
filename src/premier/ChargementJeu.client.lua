-- Écran de chargement à la connexion · LocalScript de ReplicatedFirst (lancé avant tout le reste du jeu).
-- Sa durée suit le vrai chargement du joueur : il reste affiché tant que ces 5 étapes ne sont pas finies
-- (chacune a un délai maximal pour ne jamais bloquer) :
--   1. le jeu de base est téléchargé (game.Loaded + file de ContentProvider)
--   2. la carte est construite par le serveur (attribut workspace « MondeConstruit », Monde.server.lua)
--   3. le personnage est apparu et le sol est chargé sous ses pieds (streaming)
--   4. la sauvegarde du joueur est chargée (attribut joueur « DonneesChargees », Donnees.lua)
--   5. les textures et sons en attente sont téléchargés (ContentProvider.RequestQueueSize)
-- Un joueur rapide le voit DUREE_MIN secondes, un joueur lent le voit plus longtemps (DUREE_MAX au plus).
-- Décor « la paroi » : galerie étayée (poutres, ferrures, lanternes qui se balancent et éclairent), mur de roche
-- en blocs voxel avec fissures et minerais en cristaux qui scintillent, cailloux qui tombent, braises et poussière ;
-- titre doré en relief qui tombe avec un impact ; un wagonnet (pourcentage peint sur le flanc) avance sur le rail
-- avec le chargement, crache des étincelles, puis file hors de l'écran à la fin.
-- Tout est dessiné en Frames (aucune image importée : visible par tous les collaborateurs).
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")

local TITRE = "LA GRANDE MINE" -- titre provisoire
local SOUS_TITRE = "CREUSE  ·  FORGE  ·  DESCENDS TOUJOURS PLUS PROFOND"
local DUREE_MIN, DUREE_MAX = 3, 60
local ASTUCES = {
	"Prends le wagonnet à la gare pour descendre dans la grande mine.",
	"Ta mine privée compte 8 couches : plus tu creuses, plus les minerais sont rares.",
	"Chaque couche demande une pioche plus solide : passe voir la boutique.",
	"Le forgeron transforme tes minerais en épées et en armures.",
	"Les grottes profondes se tentent seul ou à deux… si tu oses.",
	"La Guilde te confie des quêtes : rends-les pour gagner des récompenses.",
}

local joueur = Players.LocalPlayer
local NOIR, BLANC = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
local CENTRE = Vector2.new(0.5, 0.5)
local YY = Enum.SizeConstraint.RelativeYY
local rng = Random.new()

-- ================= Outils de dessin =================
local function creer(classe: string, props: {[string]: any}, enfants: {Instance}?): any
	local i: any = Instance.new(classe)
	for k, v in props do
		if k ~= "Parent" then i[k] = v end
	end
	for _, e in enfants or {} do e.Parent = i end
	if props.Parent then i.Parent = props.Parent end
	return i
end
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local function seq(t): ColorSequence
	local k = {}
	for _, p in t do table.insert(k, ColorSequenceKeypoint.new(p[1], p[2])) end
	return ColorSequence.new(k)
end
local function transp(t): NumberSequence
	local k = {}
	for _, p in t do table.insert(k, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(k)
end
local function coin(r: number?): UICorner
	return creer("UICorner", {CornerRadius = UDim.new(r or 0.5, 0)})
end
local function degrade(rotation: number, couleurs, transparences): UIGradient
	return creer("UIGradient", {Rotation = rotation, Color = seq(couleurs), Transparency = if transparences then transp(transparences) else nil})
end
local function bloc(parent: Instance, props: {[string]: any}, enfants: {Instance}?): Frame
	props.BorderSizePixel = 0
	props.Parent = parent
	return creer("Frame", props, enfants)
end
local function texte(parent: Instance, props: {[string]: any}, tailleMax: number): TextLabel
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.Parent = parent
	local l = creer("TextLabel", props)
	creer("UITextSizeConstraint", {MaxTextSize = tailleMax, MinTextSize = 8, Parent = l})
	return l
end
local function tween(o: Instance, duree: number, props, style: Enum.EasingStyle?, sens: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(duree, style or Enum.EasingStyle.Quad, sens or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
-- contour proportionnel à la taille du texte (UIStroke est en pixels)
local function contour(l: TextLabel, couleur: Color3, ratio: number): UIStroke
	local s = creer("UIStroke", {Color = couleur, LineJoinMode = Enum.LineJoinMode.Round, Parent = l})
	local function maj()
		s.Thickness = math.max(1.5, math.min(l.AbsoluteSize.Y, l.TextBounds.Y) * ratio)
	end
	l:GetPropertyChangedSignal("AbsoluteSize"):Connect(maj)
	l:GetPropertyChangedSignal("TextBounds"):Connect(maj)
	maj()
	return s
end
-- contour en dégradé (relief : arête claire en haut à gauche, sombre en bas à droite)
local function biseau(o: GuiObject, epaisseur: number, clair: Color3, sombre: Color3)
	creer("UIStroke", {Thickness = epaisseur, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = BLANC, Parent = o},
		{degrade(45, {{0, clair}, {0.5, clair:Lerp(sombre, 0.5)}, {1, sombre}})})
end
-- halo doux : cercles empilés de plus en plus grands
local function halo(parent: Instance, pos: UDim2, taille: number, couleur: Color3, alpha: number, n: number, z: number): Frame
	local h = bloc(parent, {Name = "Halo", AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z})
	for i = 1, n do
		local f = i / n
		bloc(h, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(f, f), BackgroundColor3 = couleur,
			BackgroundTransparency = 1 - alpha, ZIndex = z}, {coin()})
	end
	return h
end
-- étoile de scintillement à 4 branches (taille = côté, relatif à la hauteur du parent)
local function etoile(parent: Instance, pos: UDim2, taille: number, couleur: Color3, z: number)
	local e = bloc(parent, {Name = "Etoile", AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = z})
	for _, r in {0, 90} do
		bloc(e, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.1), Rotation = r, BackgroundColor3 = couleur, ZIndex = z},
			{coin(), creer("UIGradient", {Transparency = transp({{0, 1}, {0.5, 0}, {1, 1}})})})
	end
	for _, r in {45, 135} do
		bloc(e, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.06), Rotation = r, BackgroundColor3 = couleur, ZIndex = z},
			{coin(), creer("UIGradient", {Transparency = transp({{0, 1}, {0.5, 0.2}, {1, 1}})})})
	end
	bloc(e, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.18, 0.18), BackgroundColor3 = BLANC, ZIndex = z}, {coin()})
	local echelle = creer("UIScale", {Scale = 0, Parent = e})
	return {e = e, echelle = echelle, prochain = rng:NextNumber(0.5, 4)}
end
local function scintiller(s)
	s.e.Rotation = rng:NextNumber(-20, 20)
	tween(s.echelle, 0.18, {Scale = 1}, Enum.EasingStyle.Back).Completed:Connect(function()
		tween(s.echelle, 0.35, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end

-- ================= Écran (affiché tout de suite, avant même le chargement du jeu) =================
local gui = creer("ScreenGui", {Name = "ChargementJeu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.None})
local ecran = creer("Frame", {Name = "Ecran", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(8, 6, 5), BorderSizePixel = 0, Parent = gui})
gui.Parent = joueur:WaitForChild("PlayerGui")
pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

-- chat et liste des joueurs (dessinés par Roblox par-dessus tout) masqués pendant le chargement, puis remis
-- comme avant ; vie et sac ne sont pas touchés (Hud et Emplacements les gèrent)
local INTERFACES_MASQUEES = {Enum.CoreGuiType.Chat, Enum.CoreGuiType.PlayerList}
local interfacesAvant = {}
for i, ty in INTERFACES_MASQUEES do
	local ok, actif = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, ty)
	interfacesAvant[i] = not ok or actif
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, ty, false)
end
local function remettreInterfaces()
	for i, ty in INTERFACES_MASQUEES do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, ty, interfacesAvant[i])
	end
end

local MINERAIS = { -- couleurs des minerais (du plus commun au plus rare) : cuivre, fer, or, émeraude, rubis, saphir, améthyste, diamant
	rgb(214, 120, 64), rgb(196, 200, 212), rgb(255, 204, 72), rgb(64, 214, 120),
	rgb(236, 64, 86), rgb(70, 130, 255), rgb(176, 92, 255), rgb(140, 240, 255),
}
local BOIS, BOIS_SOMBRE = rgb(132, 84, 46), rgb(70, 42, 22)
local FER, FER_SOMBRE = rgb(92, 92, 102), rgb(30, 30, 36)

-- ================= Fond : le mur de roche =================
bloc(ecran, {Name = "Fond", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLANC, ZIndex = 1}, {degrade(90, {{0, rgb(30, 22, 18)}, {1, rgb(10, 8, 7)}})})
local mur = bloc(ecran, {Name = "Mur", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(3.6, 1.04), SizeConstraint = YY,
	BackgroundTransparency = 1, ZIndex = 2})
local LIGNES, COLONNES = 9, 32
local mineraisMur, etoilesMur = {}, {}
for l = 0, LIGNES - 1 do
	for c = 0, COLONNES - 1 do
		local v = rng:NextNumber()
		local base = rgb(40, 32, 27):Lerp(rgb(84, 68, 56), v * v)
		local loinDuCentre = math.abs(c - COLONNES / 2 + 0.5) > 7.5 or l > 5 -- pas de minerai derrière le titre
		local mi = if loinDuCentre and rng:NextNumber() < 0.11 then MINERAIS[rng:NextInteger(1, #MINERAIS)] else nil
		local saillant = not mi and rng:NextNumber() < 0.12
		local taille = if saillant then 1.02 else 0.94
		local x, y = (c + 0.5) / COLONNES + rng:NextNumber(-0.0015, 0.0015), (l + 0.5) / LIGNES
		if saillant then -- ombre portée du bloc qui dépasse
			bloc(mur, {AnchorPoint = CENTRE, Position = UDim2.fromScale(x + 0.004, y + 0.03), Size = UDim2.fromScale(taille / COLONNES, taille / LIGNES),
				BackgroundColor3 = NOIR, BackgroundTransparency = 0.45, ZIndex = 2}, {coin(0.12)})
		end
		local couleur = if mi then base:Lerp(mi, 0.12) elseif saillant then base:Lerp(BLANC, 0.06) else base
		local b = bloc(mur, {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(taille / COLONNES, taille / LIGNES),
			BackgroundColor3 = BLANC, ZIndex = 3}, {coin(0.1), degrade(70, {{0, couleur:Lerp(BLANC, 0.1)}, {1, couleur:Lerp(NOIR, 0.4)}})})
		biseau(b, if saillant then 2 else 1.5, couleur:Lerp(BLANC, 0.3), couleur:Lerp(NOIR, 0.6))
		-- fissures
		if not mi and rng:NextNumber() < 0.16 then
			local fx, fy, a = rng:NextNumber(0.25, 0.75), rng:NextNumber(0.25, 0.75), rng:NextNumber(-60, 60)
			bloc(b, {AnchorPoint = CENTRE, Position = UDim2.fromScale(fx, fy), Size = UDim2.fromScale(0.5, 0.035), Rotation = a, BackgroundColor3 = rgb(18, 13, 10), ZIndex = 4})
			bloc(b, {AnchorPoint = CENTRE, Position = UDim2.fromScale(fx + 0.15, fy + 0.12), Size = UDim2.fromScale(0.28, 0.03), Rotation = a + 50, BackgroundColor3 = rgb(18, 13, 10), ZIndex = 4})
		end
		if mi then
			-- cristaux qui sortent de la roche, lueur qui respire, étoile de scintillement
			local lueur = halo(b, UDim2.fromScale(0.5, 0.55), 1.5, mi, 0.13, 5, 3)
			local creux = bloc(b, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.7, 0.5), BackgroundColor3 = rgb(16, 12, 10), ZIndex = 4}, {coin(0.4)})
			creux.BackgroundTransparency = 0.2
			for k = 1, 4 do
				local h = rng:NextNumber(0.32, 0.55)
				local cristal = bloc(b, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.22 + (k - 1) * 0.18 + rng:NextNumber(-0.04, 0.04), 0.82),
					Size = UDim2.fromScale(0.15, h), Rotation = (k - 2.5) * 14 + rng:NextNumber(-8, 8), BackgroundColor3 = BLANC, ZIndex = 5},
					{coin(0.35), degrade(0, {{0, mi:Lerp(BLANC, 0.65)}, {0.45, mi}, {1, mi:Lerp(NOIR, 0.45)}}),
						creer("UIStroke", {Color = mi:Lerp(NOIR, 0.6), Thickness = 1})})
				bloc(cristal, {Position = UDim2.fromScale(0.2, 0.08), Size = UDim2.fromScale(0.22, 0.6), BackgroundColor3 = BLANC, BackgroundTransparency = 0.45, ZIndex = 6}, {coin()})
			end
			table.insert(mineraisMur, {lueur = lueur, phase = rng:NextNumber(0, 6.28), vitesse = rng:NextNumber(1.5, 3)})
			table.insert(etoilesMur, etoile(b, UDim2.fromScale(rng:NextNumber(0.3, 0.7), rng:NextNumber(0.25, 0.5)), 0.9, mi:Lerp(BLANC, 0.5), 7))
		end
	end
end
-- lumière chaude au centre (le titre est éclairé), vignettage
local lumiere = halo(ecran, UDim2.fromScale(0.5, 0.42), 1.6, rgb(255, 150, 60), 0.04, 15, 5)
for _, v in {{0, 0, 1, 0.38, 90, {{0, 0}, {1, 1}}}, {0, 0.5, 1, 0.5, 90, {{0, 1}, {1, 0}}}, {0, 0, 0.28, 1, 0, {{0, 0}, {1, 1}}}, {0.72, 0, 0.28, 1, 0, {{0, 1}, {1, 0}}}} do
	bloc(ecran, {Position = UDim2.fromScale(v[1], v[2]), Size = UDim2.fromScale(v[3], v[4]), BackgroundColor3 = NOIR, ZIndex = 6},
		{creer("UIGradient", {Rotation = v[5], Transparency = transp(v[6])})})
end

-- ================= Charpente de la galerie : poutres, ferrures, lanternes =================
local function grainBois(o: Frame, vertical: boolean, z: number)
	for _, p in {0.22, 0.5, 0.78} do
		local pos = p + rng:NextNumber(-0.06, 0.06)
		bloc(o, {Position = if vertical then UDim2.fromScale(pos, 0) else UDim2.fromScale(0, pos), Size = if vertical then UDim2.fromScale(0.035, 1) else UDim2.fromScale(1, 0.05),
			BackgroundColor3 = BOIS_SOMBRE, BackgroundTransparency = 0.45, ZIndex = z})
	end
	for _ = 1, 2 do -- nœuds du bois
		bloc(o, {AnchorPoint = CENTRE, Position = if vertical then UDim2.fromScale(rng:NextNumber(0.3, 0.7), rng:NextNumber(0.3, 0.9)) else UDim2.fromScale(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.3, 0.7)),
			Size = if vertical then UDim2.fromScale(0.3, 0.025) else UDim2.fromScale(0.012, 0.35), BackgroundColor3 = BOIS_SOMBRE, BackgroundTransparency = 0.2, ZIndex = z}, {coin()})
	end
end
local function boulon(parent: Instance, pos: UDim2, taille: number, z: number)
	bloc(parent, {AnchorPoint = CENTRE, Position = pos, Size = UDim2.fromScale(taille, taille), SizeConstraint = YY, BackgroundColor3 = BLANC, ZIndex = z},
		{coin(), degrade(45, {{0, rgb(210, 210, 218)}, {1, rgb(70, 70, 78)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1})})
end
local function ferrure(parent: Instance, pos: UDim2, taille: UDim2, z: number)
	local f = bloc(parent, {AnchorPoint = CENTRE, Position = pos, Size = taille, BackgroundColor3 = BLANC, ZIndex = z},
		{coin(0.12), degrade(90, {{0, rgb(120, 120, 130)}, {1, rgb(50, 50, 58)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1.5})})
	boulon(f, UDim2.fromScale(0.5, 0.25), 0.22, z + 1)
	boulon(f, UDim2.fromScale(0.5, 0.75), 0.22, z + 1)
	return f
end
local charpente = bloc(ecran, {Name = "Charpente", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10})
local function poteau(cote: number)
	local p = bloc(charpente, {Name = "Poteau", AnchorPoint = Vector2.new(cote, 0), Position = UDim2.fromScale(if cote == 0 then 0.015 else 0.985, 0.05),
		Size = UDim2.fromScale(0.085, 0.82), SizeConstraint = YY, BackgroundColor3 = BLANC, ZIndex = 11},
		{degrade(0, {{0, BOIS:Lerp(BLANC, 0.12)}, {0.6, BOIS}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 2})})
	grainBois(p, true, 12)
	ferrure(p, UDim2.fromScale(0.5, 0.1), UDim2.fromScale(1.12, 0.09), 13)
	ferrure(p, UDim2.fromScale(0.5, 0.86), UDim2.fromScale(1.12, 0.09), 13)
	-- jambe de force en diagonale vers le linteau
	local s = if cote == 0 then 1 else -1
	local jambe = bloc(p, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + s * 1.55, 0.1), Size = UDim2.fromScale(0.055, 0.25), SizeConstraint = YY, Rotation = s * 45,
		BackgroundColor3 = BLANC, ZIndex = 10}, {degrade(0, {{0, BOIS}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 2})})
	grainBois(jambe, true, 10)
	-- ombre du poteau sur la roche
	bloc(charpente, {AnchorPoint = Vector2.new(cote, 0), Position = UDim2.fromScale(if cote == 0 then 0.015 else 0.985, 0.05), Size = UDim2.fromScale(0.16, 0.82), SizeConstraint = YY,
		BackgroundColor3 = NOIR, ZIndex = 9}, {creer("UIGradient", {Rotation = if cote == 0 then 0 else 180, Transparency = transp({{0, 0.2}, {0.5, 0.45}, {1, 1}})})})
end
poteau(0)
poteau(1)
local linteau = bloc(charpente, {Name = "Linteau", Position = UDim2.fromScale(-0.01, 0.025), Size = UDim2.fromScale(1.02, 0.085), BackgroundColor3 = BLANC, ZIndex = 14},
	{degrade(90, {{0, BOIS:Lerp(BLANC, 0.15)}, {0.5, BOIS}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 2})})
grainBois(linteau, false, 15)
for _, x in {0.06, 0.3, 0.5, 0.7, 0.94} do
	ferrure(linteau, UDim2.fromScale(x, 0.5), UDim2.fromScale(0.022, 1.15), 16)
end
bloc(charpente, {Position = UDim2.fromScale(0, 0.11), Size = UDim2.fromScale(1, 0.06), BackgroundColor3 = NOIR, ZIndex = 9},
	{creer("UIGradient", {Rotation = 90, Transparency = transp({{0, 0.25}, {1, 1}})})})

-- lanternes suspendues qui se balancent, avec leur cône de lumière
local lanternes = {}
for i, x in {0.24, 0.76} do
	local pivot = bloc(charpente, {Name = "Lanterne", AnchorPoint = CENTRE, Position = UDim2.fromScale(x, 0.11), Size = UDim2.fromScale(0.13, 0.46), SizeConstraint = YY,
		BackgroundTransparency = 1, ZIndex = 17})
	for k = 1, 5 do -- cône de lumière : bandes empilées de plus en plus larges (bords doux), qui s'éteignent vers le bas
		bloc(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.5 + k * 0.5, 1.4 - k * 0.08),
			BackgroundColor3 = rgb(255, 190, 100), ZIndex = 8}, {coin(0.5), creer("UIGradient", {Rotation = 90, Transparency = transp({{0, 0.95}, {0.7, 0.98}, {1, 1}})})})
	end
	local lueur = halo(pivot, UDim2.fromScale(0.5, 0.8), 0.7, rgb(255, 180, 80), 0.07, 12, 16)
	bloc(pivot, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.04, 0.2), BackgroundColor3 = rgb(40, 40, 46), ZIndex = 17})
	bloc(pivot, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.22, 0.03), BackgroundColor3 = rgb(40, 40, 46), ZIndex = 18}, {coin()})
	bloc(pivot, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.725), Size = UDim2.fromScale(0.5, 0.04), BackgroundColor3 = BLANC, ZIndex = 19},
		{coin(0.3), degrade(90, {{0, rgb(110, 110, 120)}, {1, rgb(40, 40, 48)}})})
	local verre = bloc(pivot, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.4, 0.16), BackgroundColor3 = BLANC, ZIndex = 18},
		{coin(0.2), degrade(90, {{0, rgb(255, 246, 190)}, {0.6, rgb(255, 190, 80)}, {1, rgb(230, 120, 40)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 2})})
	bloc(verre, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(0.22, 0.4), BackgroundColor3 = rgb(255, 255, 230), ZIndex = 19}, {coin()})
	for _, bx in {0.33, 0.66} do
		bloc(verre, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(bx, 0), Size = UDim2.fromScale(0.07, 1), BackgroundColor3 = FER_SOMBRE, ZIndex = 20})
	end
	bloc(pivot, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.91), Size = UDim2.fromScale(0.48, 0.03), BackgroundColor3 = rgb(50, 50, 58), ZIndex = 19}, {coin(0.3)})
	table.insert(lanternes, {pivot = pivot, lueur = lueur, phase = i * 1.7})
end

-- ================= Sol, rail et wagonnet =================
local SOL_Y = 0.845
bloc(ecran, {Name = "Sol", Position = UDim2.fromScale(0, SOL_Y), Size = UDim2.fromScale(1, 1 - SOL_Y), BackgroundColor3 = BLANC, ZIndex = 18},
	{degrade(90, {{0, rgb(46, 36, 30)}, {0.25, rgb(26, 20, 17)}, {1, rgb(8, 6, 5)}})})
for _ = 1, 46 do -- gravats sur le bord du sol
	local d = rng:NextNumber(0.012, 0.034)
	local c = rgb(44, 35, 30):Lerp(rgb(92, 76, 62), rng:NextNumber() ^ 2)
	local g = bloc(ecran, {AnchorPoint = CENTRE, Position = UDim2.fromScale(rng:NextNumber(0, 1), SOL_Y + rng:NextNumber(-0.004, 0.012)), Size = UDim2.fromScale(d * rng:NextNumber(1, 1.6), d),
		SizeConstraint = YY, Rotation = rng:NextNumber(-30, 30), BackgroundColor3 = BLANC, ZIndex = 19}, {coin(0.25), degrade(60, {{0, c:Lerp(BLANC, 0.15)}, {1, c:Lerp(NOIR, 0.5)}})})
end
local rail = bloc(ecran, {Name = "Rail", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, SOL_Y + 0.008), Size = UDim2.fromScale(0.64, 0.012), BackgroundTransparency = 1, ZIndex = 20})
for i = 0, 32 do -- traverses
	bloc(rail, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(i / 32, 0.3), Size = UDim2.fromScale(0.011, 1.5), BackgroundColor3 = BLANC, ZIndex = 20},
		{degrade(90, {{0, BOIS}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 1})})
end
bloc(rail, {Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = BLANC, ZIndex = 21}, {degrade(90, {{0, rgb(190, 190, 200)}, {0.4, rgb(100, 100, 110)}, {1, rgb(40, 40, 46)}}),
	creer("UIStroke", {Color = rgb(16, 16, 20), Thickness = 1})})
local allume = bloc(rail, {Size = UDim2.fromScale(0, 0.5), BackgroundColor3 = BLANC, ZIndex = 22}, {degrade(0, {{0, rgb(255, 130, 30)}, {1, rgb(255, 240, 160)}})})
local lueurRail = bloc(allume, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 6), BackgroundColor3 = rgb(255, 170, 60),
	BackgroundTransparency = 0.82, ZIndex = 19}, {coin()})
for _, x in {0} do -- butoir au départ (le wagon sort par la droite)
	local butoir = bloc(rail, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromScale(1.4, 3.2), SizeConstraint = YY, BackgroundColor3 = BLANC, ZIndex = 21},
		{coin(0.15), degrade(0, {{0, BOIS}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 1.5})})
	bloc(butoir, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(1.15, 0.22), BackgroundColor3 = rgb(200, 60, 40), ZIndex = 22},
		{creer("UIStroke", {Color = rgb(40, 10, 6), Thickness = 1})})
end

local wagon = bloc(rail, {Name = "Wagon", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0, 0.05), Size = UDim2.fromScale(17, 11), SizeConstraint = YY,
	BackgroundTransparency = 1, ZIndex = 30})
-- tas de minerais (en dôme) avec reflets
local etoilesWagon = {}
for i = 1, 15 do
	local fx = (i - 0.5) / 15
	local hauteur = 1 - (fx * 2 - 1) ^ 2
	local d = rng:NextNumber(0.13, 0.2)
	local c = MINERAIS[rng:NextInteger(1, #MINERAIS)]
	local caillou = bloc(wagon, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.1 + fx * 0.8, 0.27 - hauteur * 0.17 + rng:NextNumber(-0.03, 0.03)), Size = UDim2.fromScale(d, d),
		SizeConstraint = YY, Rotation = rng:NextNumber(0, 90), BackgroundColor3 = BLANC, ZIndex = 30 + i % 3},
		{coin(0.25), degrade(45, {{0, c:Lerp(BLANC, 0.5)}, {0.5, c}, {1, c:Lerp(NOIR, 0.5)}}), creer("UIStroke", {Color = c:Lerp(NOIR, 0.7), Thickness = 1})})
	caillou.Name = "Minerai"
end
for _ = 1, 3 do
	table.insert(etoilesWagon, etoile(wagon, UDim2.fromScale(rng:NextNumber(0.25, 0.75), rng:NextNumber(0.08, 0.22)), 0.3, rgb(255, 250, 220), 36))
end
local caisse = bloc(wagon, {Name = "Caisse", Position = UDim2.fromScale(0.04, 0.25), Size = UDim2.fromScale(0.92, 0.5), BackgroundColor3 = rgb(20, 14, 10), ZIndex = 34},
	{coin(0.06), creer("UIStroke", {Color = rgb(14, 10, 8), Thickness = 2})})
for k = 0, 2 do -- planches
	local pl = bloc(caisse, {Position = UDim2.fromScale(0.01, 0.02 + k * 0.33), Size = UDim2.fromScale(0.98, 0.3), BackgroundColor3 = BLANC, ZIndex = 35},
		{coin(0.15), degrade(90, {{0, BOIS:Lerp(BLANC, 0.18)}, {1, BOIS:Lerp(NOIR, 0.25)}})})
	grainBois(pl, false, 36)
end
bloc(caisse, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromScale(1.07, 0.16), BackgroundColor3 = BLANC, ZIndex = 38},
	{coin(0.3), degrade(90, {{0, rgb(200, 200, 210)}, {1, rgb(80, 80, 90)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1.5})})
for _, bx in {0.08, 0.92} do -- bandes de fer rivetées
	local bande = bloc(caisse, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(bx, 0), Size = UDim2.fromScale(0.07, 1), BackgroundColor3 = BLANC, ZIndex = 37},
		{degrade(0, {{0, rgb(130, 130, 140)}, {1, rgb(56, 56, 64)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1})})
	for _, by in {0.2, 0.5, 0.8} do boulon(bande, UDim2.fromScale(0.5, by), 0.12, 38) end
end
-- plaque du flanc : le pourcentage peint
local plaque = bloc(caisse, {Name = "Plaque", AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.42, 0.62), BackgroundColor3 = BLANC, ZIndex = 38},
	{coin(0.2), degrade(90, {{0, rgb(70, 70, 80)}, {1, rgb(28, 28, 34)}}), creer("UIStroke", {Color = rgb(255, 196, 90), Thickness = 2})})
local pct = texte(plaque, {Name = "Pourcentage", Text = "0 %", Font = Enum.Font.LuckiestGuy, TextColor3 = BLANC, AnchorPoint = CENTRE,
	Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.9, 0.82), ZIndex = 39}, 40)
creer("UIGradient", {Rotation = 90, Color = seq({{0, rgb(255, 240, 170)}, {1, rgb(255, 170, 50)}}), Parent = pct})
contour(pct, rgb(30, 16, 6), 0.08)
bloc(wagon, {Position = UDim2.fromScale(0.1, 0.74), Size = UDim2.fromScale(0.8, 0.07), BackgroundColor3 = FER_SOMBRE, ZIndex = 33}, {coin(0.3)})
-- petite lanterne à l'avant du wagon
local lueurWagon = halo(wagon, UDim2.fromScale(0.985, 0.3), 0.55, rgb(255, 200, 100), 0.09, 8, 32)
bloc(wagon, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.985, 0.3), Size = UDim2.fromScale(0.07, 0.1), SizeConstraint = YY, BackgroundColor3 = rgb(255, 226, 140), ZIndex = 33},
	{coin(0.3), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1.5})})
local roues = {}
for _, rx in {0.25, 0.75} do
	local r = bloc(wagon, {AnchorPoint = CENTRE, Position = UDim2.fromScale(rx, 0.83), Size = UDim2.fromScale(0.3, 0.3), SizeConstraint = YY, BackgroundColor3 = rgb(36, 36, 42), ZIndex = 40},
		{coin(), creer("UIStroke", {Color = rgb(150, 150, 162), Thickness = 2.5})})
	for _, a in {0, 45, 90, 135} do
		bloc(r, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.88, 0.09), Rotation = a, BackgroundColor3 = rgb(130, 130, 142), ZIndex = 41})
	end
	bloc(r, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.34, 0.34), BackgroundColor3 = BLANC, ZIndex = 42},
		{coin(), degrade(45, {{0, rgb(220, 220, 228)}, {1, rgb(80, 80, 90)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1})})
	table.insert(roues, r)
end

-- étincelles des roues
local etincelles = {}
for _ = 1, 26 do
	local f = bloc(rail, {AnchorPoint = CENTRE, Size = UDim2.fromScale(0.5, 0.5), SizeConstraint = YY, BackgroundColor3 = rgb(255, 220, 120), ZIndex = 29, Visible = false}, {coin()})
	table.insert(etincelles, {f = f, vie = 0})
end
local prochaineEtincelle = 1
local function lancerEtincelle(x: number)
	local e = etincelles[prochaineEtincelle]
	prochaineEtincelle = prochaineEtincelle % #etincelles + 1
	e.x, e.y, e.vx, e.vy, e.vie = x, 0.1, -rng:NextNumber(0.04, 0.12), -rng:NextNumber(14, 34), rng:NextNumber(0.25, 0.5)
	e.f.Visible = true
end

-- ================= Ambiance : braises, poussière, cailloux qui tombent =================
local braises = {}
for _ = 1, 30 do
	local f = bloc(ecran, {AnchorPoint = CENTRE, Size = UDim2.fromScale(0.006, 0.006), SizeConstraint = YY, BackgroundColor3 = rgb(255, rng:NextInteger(120, 200), 50), ZIndex = 24}, {coin(0.3)})
	table.insert(braises, {f = f, x = rng:NextNumber(), y = rng:NextNumber(), v = rng:NextNumber(0.03, 0.08), phase = rng:NextNumber(0, 6.28)})
end
local poussieres = {}
for _ = 1, 26 do
	local f = bloc(ecran, {AnchorPoint = CENTRE, Size = UDim2.fromScale(0.004, 0.004), SizeConstraint = YY, BackgroundColor3 = rgb(255, 230, 190), ZIndex = 24}, {coin()})
	table.insert(poussieres, {f = f, x = rng:NextNumber(0.1, 0.9), y = rng:NextNumber(0.15, 0.8), phase = rng:NextNumber(0, 6.28), v = rng:NextNumber(0.004, 0.012)})
end
local cailloux = {}
for _ = 1, 5 do
	local d = rng:NextNumber(0.008, 0.016)
	local f = bloc(ecran, {AnchorPoint = CENTRE, Size = UDim2.fromScale(d, d), SizeConstraint = YY, BackgroundColor3 = rgb(96, 80, 66), ZIndex = 23, Visible = false},
		{coin(0.25), creer("UIStroke", {Color = rgb(30, 22, 18), Thickness = 1})})
	table.insert(cailloux, {f = f, actif = false})
end
local prochainCaillou = 1.5

-- ================= Décor en plus : stalactites, outils, caisse, tonneau, rochers au premier plan =================
for _ = 1, 16 do -- stalactites : losanges à moitié cachés derrière le linteau
	local d = rng:NextNumber(0.022, 0.05)
	local c = rgb(46, 36, 30):Lerp(rgb(84, 70, 58), rng:NextNumber())
	bloc(charpente, {AnchorPoint = CENTRE, Position = UDim2.fromScale(rng:NextNumber(0.07, 0.93), 0.108), Size = UDim2.fromScale(d * 0.75, d), SizeConstraint = YY, Rotation = 45,
		BackgroundColor3 = BLANC, ZIndex = 13}, {degrade(45, {{0, c:Lerp(BLANC, 0.15)}, {1, c:Lerp(NOIR, 0.55)}})})
end
-- repères en hauteurs d'écran, collés aux poteaux gauche et droit
local gauche = bloc(ecran, {Name = "AccessoiresGauche", Position = UDim2.fromScale(0.015, 0), Size = UDim2.fromScale(1, 1), SizeConstraint = YY, BackgroundTransparency = 1, ZIndex = 19})
local droite = bloc(ecran, {Name = "AccessoiresDroite", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.985, 0), Size = UDim2.fromScale(1, 1), SizeConstraint = YY,
	BackgroundTransparency = 1, ZIndex = 19})
-- pioche appuyée contre le poteau gauche
do
	local th = -18
	local centre = Vector2.new(0.17, SOL_Y - 0.13)
	local a = math.rad(th)
	local haut = centre + Vector2.new(0.14 * math.sin(a), -0.14 * math.cos(a))
	local dir = Vector2.new(math.cos(a), math.sin(a))
	bloc(gauche, {AnchorPoint = CENTRE, Position = UDim2.fromScale(centre.X, centre.Y), Size = UDim2.fromScale(0.019, 0.28), Rotation = th, BackgroundColor3 = BLANC, ZIndex = 19},
		{coin(0.4), degrade(0, {{0, rgb(176, 118, 66)}, {1, rgb(90, 54, 28)}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 1.5})})
	for _, s in {-1, 1} do
		local p = haut + dir * (0.036 * s)
		bloc(gauche, {AnchorPoint = CENTRE, Position = UDim2.fromScale(p.X, p.Y + 0.006), Size = UDim2.fromScale(0.08, 0.02), Rotation = th + s * 14, BackgroundColor3 = BLANC, ZIndex = 20},
			{coin(0.5), degrade(90, {{0, rgb(226, 228, 236)}, {1, rgb(96, 98, 110)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1.5})})
	end
	bloc(gauche, {AnchorPoint = CENTRE, Position = UDim2.fromScale(haut.X, haut.Y + 0.004), Size = UDim2.fromScale(0.026, 0.026), Rotation = th, BackgroundColor3 = rgb(60, 60, 68), ZIndex = 21},
		{coin(0.25), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 1})})
	for k = 1, 4 do -- quelques minerais au pied
		local c = MINERAIS[rng:NextInteger(1, #MINERAIS)]
		local d = rng:NextNumber(0.018, 0.028)
		bloc(gauche, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.22 + k * 0.026, SOL_Y + 0.006), Size = UDim2.fromScale(d, d), Rotation = rng:NextNumber(0, 90),
			BackgroundColor3 = BLANC, ZIndex = 19}, {coin(0.25), degrade(45, {{0, c:Lerp(BLANC, 0.5)}, {0.5, c}, {1, c:Lerp(NOIR, 0.5)}}), creer("UIStroke", {Color = c:Lerp(NOIR, 0.7), Thickness = 1})})
	end
end
-- caisse et tonneau contre le poteau droit
do
	local caisseD = bloc(droite, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(1 - 0.2, SOL_Y + 0.008), Size = UDim2.fromScale(0.12, 0.11), BackgroundColor3 = BLANC, ZIndex = 19},
		{coin(0.06), degrade(90, {{0, BOIS:Lerp(BLANC, 0.1)}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 2})})
	grainBois(caisseD, false, 19)
	for _, r in {41, -41} do
		bloc(caisseD, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 0.1), Rotation = r, BackgroundColor3 = BOIS_SOMBRE, ZIndex = 20},
			{creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 1})})
	end
	for _, x in {0.06, 0.94} do
		for _, y in {0.08, 0.92} do boulon(caisseD, UDim2.fromScale(x, y), 0.09, 21) end
	end
	local tonneau = bloc(droite, {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(1 - 0.33, SOL_Y + 0.008), Size = UDim2.fromScale(0.1, 0.14), BackgroundColor3 = BLANC, ZIndex = 19},
		{coin(0.3), degrade(0, {{0, BOIS_SOMBRE}, {0.35, BOIS:Lerp(BLANC, 0.15)}, {1, BOIS_SOMBRE}}), creer("UIStroke", {Color = rgb(26, 14, 6), Thickness = 2})})
	for _, y in {0.2, 0.8} do
		bloc(tonneau, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(1.04, 0.08), BackgroundColor3 = BLANC, ZIndex = 20},
			{degrade(0, {{0, rgb(50, 50, 58)}, {0.4, rgb(150, 150, 160)}, {1, rgb(50, 50, 58)}})})
	end
	-- petite lanterne posée sur la caisse
	halo(caisseD, UDim2.fromScale(0.5, -0.25), 1.1, rgb(255, 180, 80), 0.07, 8, 18)
	bloc(caisseD, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, -0.2), Size = UDim2.fromScale(0.2, 0.35), BackgroundColor3 = BLANC, ZIndex = 21},
		{coin(0.2), degrade(90, {{0, rgb(255, 246, 190)}, {1, rgb(240, 140, 40)}}), creer("UIStroke", {Color = FER_SOMBRE, Thickness = 2})})
end
-- gros rochers sombres au premier plan, dans les coins (profondeur)
for _, cote in {gauche, droite} do
	for k = 1, 3 do
		local d = rng:NextNumber(0.12, 0.2)
		local x = if cote == gauche then rng:NextNumber(-0.06, 0.06) + (k - 1) * 0.04 else 1 - rng:NextNumber(-0.06, 0.06) - (k - 1) * 0.04
		local r = bloc(cote, {AnchorPoint = CENTRE, Position = UDim2.fromScale(x, 1 - rng:NextNumber(0, 0.03)), Size = UDim2.fromScale(d * 1.3, d), Rotation = rng:NextNumber(-25, 25),
			BackgroundColor3 = BLANC, ZIndex = 27}, {coin(0.35), degrade(70, {{0, rgb(40, 32, 28)}, {0.5, rgb(18, 14, 12)}, {1, rgb(6, 5, 4)}})})
		biseau(r, 2, rgb(110, 80, 50), rgb(6, 5, 4))
	end
	cote.ZIndex = 27
end

-- ================= Veine d'or : une fissure qui s'illumine avec le chargement =================
local veine = bloc(ecran, {Name = "Veine", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7})
local NV = 26
local pointsVeine = {}
for k = 0, NV do
	pointsVeine[k] = Vector2.new(0.13 + 0.74 * k / NV, 0.655 + rng:NextNumber(-0.028, 0.028))
end
local segments = {}
local function segment(p0: Vector2, p1: Vector2, seuil: number, epaisseur: number)
	local s = {p0 = p0, p1 = p1, seuil = seuil, ep = epaisseur, allume = false}
	s.base = bloc(veine, {AnchorPoint = CENTRE, BackgroundColor3 = rgb(12, 9, 7), ZIndex = 7}, {coin()})
	s.lueur = bloc(veine, {AnchorPoint = CENTRE, BackgroundColor3 = rgb(255, 160, 40), BackgroundTransparency = 1, ZIndex = 7}, {coin()})
	s.metal = bloc(veine, {AnchorPoint = CENTRE, BackgroundColor3 = BLANC, BackgroundTransparency = 1, ZIndex = 8}, {coin(), degrade(90, {{0, rgb(255, 252, 210)}, {1, rgb(255, 170, 40)}})})
	table.insert(segments, s)
end
for k = 1, NV do
	segment(pointsVeine[k - 1], pointsVeine[k], k / NV, 1)
	if rng:NextNumber() < 0.35 then -- petite fissure secondaire
		local p = pointsVeine[k]
		segment(p, p + Vector2.new(rng:NextNumber(-0.02, 0.03), rng:NextNumber(-0.045, 0.045)), k / NV, 0.6)
	end
end
local function placerVeine()
	local a = ecran.AbsoluteSize
	local e = math.max(2, a.Y * 0.0055)
	for _, s in segments do
		local p0, p1 = s.p0 * a, s.p1 * a
		local d = p1 - p0
		local milieu = (p0 + p1) / 2
		local rot = math.deg(math.atan2(d.Y, d.X))
		for _, paire in {{s.base, 1.7}, {s.lueur, 5}, {s.metal, 0.8}} do
			paire[1].Size = UDim2.fromOffset(d.Magnitude + e * paire[2] * s.ep, e * paire[2] * s.ep)
			paire[1].Position = UDim2.fromOffset(milieu.X, milieu.Y)
			paire[1].Rotation = rot
		end
	end
end
ecran:GetPropertyChangedSignal("AbsoluteSize"):Connect(placerVeine)
placerVeine()

-- ================= Chauves-souris =================
local chauves = {}
for _ = 1, 2 do
	local c = bloc(ecran, {Name = "ChauveSouris", AnchorPoint = CENTRE, Size = UDim2.fromScale(0.07, 0.035), SizeConstraint = YY, BackgroundTransparency = 1, ZIndex = 25, Visible = false})
	local noir = rgb(16, 11, 10)
	local ailes = {}
	for _, s in {-1, 1} do
		local pivot = bloc(c, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 25})
		bloc(pivot, {AnchorPoint = Vector2.new(if s < 0 then 1 else 0, 0.5), Position = UDim2.fromScale(0.5 + s * 0.06, 0.5), Size = UDim2.fromScale(0.44, 0.55), BackgroundColor3 = noir, ZIndex = 25}, {coin(0.5)})
		bloc(pivot, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + s * 0.36, 0.72), Size = UDim2.fromScale(0.16, 0.34), Rotation = 45, BackgroundColor3 = noir, ZIndex = 25})
		table.insert(ailes, {pivot = pivot, s = s})
	end
	bloc(c, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 0.8), BackgroundColor3 = noir, ZIndex = 26}, {coin()})
	for _, s in {-1, 1} do
		bloc(c, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5 + s * 0.05, 0.12), Size = UDim2.fromScale(0.06, 0.24), Rotation = 45, BackgroundColor3 = noir, ZIndex = 26})
	end
	table.insert(chauves, {c = c, ailes = ailes, actif = false})
end
local prochaineChauve = rng:NextNumber(2, 4)

-- vacillement global de la lumière (suit les flammes) et éclair de sortie
local vacillement = bloc(ecran, {Name = "Vacillement", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOIR, BackgroundTransparency = 1, ZIndex = 28})
local eclair = bloc(ecran, {Name = "Eclair", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 236, 190), BackgroundTransparency = 1, ZIndex = 90})

-- ================= Titre doré en relief, lettre par lettre =================
local POS_TITRE = UDim2.fromScale(0.5, 0.37)
local auraTitre = halo(ecran, POS_TITRE, 1, rgb(255, 190, 90), 0.03, 12, 59)
auraTitre.SizeConstraint = Enum.SizeConstraint.RelativeXY
auraTitre.Size = UDim2.fromScale(0.62, 0.34)
local boite = bloc(ecran, {Name = "BlocTitre", AnchorPoint = CENTRE, Position = POS_TITRE, Size = UDim2.fromScale(0.72, 0.2), BackgroundTransparency = 1, ZIndex = 60},
	{creer("UIAspectRatioConstraint", {AspectRatio = 6.4})})
local echelleTitre = creer("UIScale", {Scale = 1, Parent = boite})
local rangee = bloc(boite, {Name = "Lettres", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60},
	{creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})})
local lettres = {}
local POLICE = Enum.Font.LuckiestGuy
for _, code in utf8.codes(TITRE) do
	local ch = utf8.char(code)
	local i = #lettres + 1
	-- la case a la largeur de la lettre (calculée par TextService) ; le corps porte les calques et tombe du ciel
	local case = bloc(rangee, {Name = "Lettre", LayoutOrder = i, Size = UDim2.fromScale(0, 1), BackgroundTransparency = 1, ZIndex = 60})
	local corps = bloc(case, {Name = "Corps", Position = UDim2.fromScale(0, -4), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60})
	local echelle = creer("UIScale", {Parent = corps})
	local calques, traits = {}, {}
	local function calque(nom: string, dy: number, couleur: Color3, z: number, tr: number?, trait: Color3?): TextLabel
		local l = creer("TextLabel", {Name = nom, Text = ch, Font = POLICE, TextColor3 = couleur, TextTransparency = tr or 0, BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, dy), Size = UDim2.fromScale(1, 1), ZIndex = z, Parent = corps})
		table.insert(calques, l)
		if trait then
			table.insert(traits, creer("UIStroke", {Color = trait, LineJoinMode = Enum.LineJoinMode.Round, Parent = l}))
		end
		return l
	end
	calque("Ombre", 0.14, NOIR, 60, 0.4)
	for k = 5, 1, -1 do
		calque("Relief", k * 0.018, rgb(150, 76, 24):Lerp(rgb(60, 26, 8), k / 5), 61, 0, rgb(36, 16, 4))
	end
	local metal = calque("Titre", 0, BLANC, 62, 0, rgb(46, 20, 6))
	creer("UIGradient", {Rotation = 90, Color = seq({{0, rgb(255, 250, 210)}, {0.4, rgb(255, 208, 84)}, {1, rgb(214, 116, 28)}}), Parent = metal})
	local reflet = calque("Reflet", 0, BLANC, 63)
	local degradeReflet = creer("UIGradient", {Rotation = 18, Offset = Vector2.new(-1, 0), Transparency = transp({{0, 1}, {0.4, 1}, {0.5, 0.05}, {0.6, 1}, {1, 1}}), Parent = reflet})
	table.insert(lettres, {case = case, corps = corps, echelle = echelle, calques = calques, traits = traits, reflet = degradeReflet, i = i, ch = ch, espace = ch == " ", pose = false})
end
local TextService = game:GetService("TextService")
local function tailleLettres()
	local ts = math.floor(boite.AbsoluteSize.Y * 0.92)
	for _, l in lettres do
		local ok, dim = pcall(TextService.GetTextSize, TextService, l.ch, ts, POLICE, Vector2.new(10000, 10000))
		local largeur = if l.espace then ts * 0.38 elseif ok then dim.X else ts * 0.6
		l.case.Size = UDim2.new(0, largeur, 1, 0)
		for _, c in l.calques do c.TextSize = ts end
		for _, s in l.traits do s.Thickness = math.max(1.5, ts * 0.065) end
	end
end
boite:GetPropertyChangedSignal("AbsoluteSize"):Connect(tailleLettres)
tailleLettres()
local eclats = bloc(boite, {Name = "Eclats", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 64})
local etoilesTitre = {}
for _ = 1, 5 do
	table.insert(etoilesTitre, etoile(eclats, UDim2.fromScale(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.15, 0.45)), 0.7, rgb(255, 252, 230), 64))
end
for _, s in etoilesTitre do s.prochain = 3 + rng:NextNumber(0, 3) end
-- ornement sous le titre : deux traits dorés et un diamant
local ornement = bloc(ecran, {Name = "Ornement", AnchorPoint = CENTRE, Position = POS_TITRE + UDim2.fromScale(0, 0.095), Size = UDim2.fromScale(0.4, 0.014), BackgroundTransparency = 1, ZIndex = 60})
local traitsOrnement = {}
for _, cote in {0, 1} do
	table.insert(traitsOrnement, bloc(ornement, {AnchorPoint = Vector2.new(cote, 0.5), Position = UDim2.fromScale(cote, 0.5), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = rgb(255, 204, 92), ZIndex = 60},
		{creer("UIGradient", {Rotation = if cote == 0 then 0 else 180, Transparency = transp({{0, 1}, {1, 0}})})}))
end
local diamant = bloc(ornement, {AnchorPoint = CENTRE, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 0), SizeConstraint = YY, Rotation = 45, BackgroundColor3 = BLANC, ZIndex = 61},
	{degrade(0, {{0, rgb(220, 255, 255)}, {1, rgb(60, 180, 230)}}), creer("UIStroke", {Color = rgb(255, 204, 92), Thickness = 1.5})})
local sous = texte(ecran, {Name = "SousTitre", Text = SOUS_TITRE, Font = Enum.Font.GothamBold, TextColor3 = rgb(240, 226, 200), TextTransparency = 1,
	AnchorPoint = CENTRE, Position = POS_TITRE + UDim2.fromScale(0, 0.13), Size = UDim2.fromScale(0.7, 0.03), ZIndex = 60}, 34)
local contourSous = contour(sous, rgb(20, 12, 8), 0.12)
contourSous.Transparency = 1

-- ================= Textes du bas =================
local etiquette = texte(ecran, {Name = "Etape", Text = "", Font = Enum.Font.GothamBold, TextColor3 = rgb(240, 226, 200), AnchorPoint = CENTRE,
	Position = UDim2.fromScale(0.5, 0.905), Size = UDim2.fromScale(0.6, 0.026), ZIndex = 70}, 32)
contour(etiquette, rgb(16, 10, 6), 0.12)
local astuce = texte(ecran, {Name = "Astuce", Text = "", RichText = true, Font = Enum.Font.Merriweather, TextColor3 = rgb(200, 184, 160), AnchorPoint = CENTRE,
	Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.74, 0.024), ZIndex = 70}, 26)
contour(astuce, rgb(16, 10, 6), 0.12)
local indexAstuce = rng:NextInteger(1, #ASTUCES)
local function montrerAstuce()
	astuce.Text = "<b>Astuce :</b> " .. ASTUCES[indexAstuce]
	astuce.TextTransparency = 1
	tween(astuce, 0.5, {TextTransparency = 0})
	indexAstuce = indexAstuce % #ASTUCES + 1
end
montrerAstuce()

-- ================= Entrée : les lettres tombent une à une, impact, poussière =================
local secousse = 0
local function poussiere(x: number, y: number, n: number, taille: number)
	for _ = 1, n do
		local d = rng:NextNumber(0.5, 1) * taille
		local p = bloc(ecran, {AnchorPoint = CENTRE, Position = UDim2.fromScale(x + rng:NextNumber(-0.02, 0.02), y), Size = UDim2.fromScale(d, d), SizeConstraint = YY,
			BackgroundColor3 = rgb(176, 156, 134), BackgroundTransparency = 0.5, ZIndex = 59}, {coin()})
		tween(p, rng:NextNumber(0.5, 0.9), {Position = p.Position + UDim2.fromScale(rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.05, 0)),
			Size = UDim2.fromScale(d * 2.4, d * 2.4), BackgroundTransparency = 1}).Completed:Connect(function() p:Destroy() end)
	end
end
local visibles = {}
for _, l in lettres do
	if not l.espace then table.insert(visibles, l) end
end
for n, l in visibles do
	task.delay(0.3 + (n - 1) * 0.075, function()
		tween(l.corps, 0.32, {Position = UDim2.fromScale(0, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
		l.pose = true
		l.echelle.Scale = 1.25
		tween(l.echelle, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
		local a, o = ecran.AbsoluteSize, ecran.AbsolutePosition
		local x = (l.case.AbsolutePosition.X + l.case.AbsoluteSize.X / 2 - o.X) / a.X
		local y = (l.case.AbsolutePosition.Y + l.case.AbsoluteSize.Y * 0.85 - o.Y) / a.Y
		poussiere(x, y, 3, 0.035)
		secousse = math.max(secousse, 0.1)
		if n == #visibles then -- dernière lettre : gros impact, l'ornement et le sous-titre apparaissent
			secousse = 0.32
			echelleTitre.Scale = 1.06
			tween(echelleTitre, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
			for _, tr in traitsOrnement do tween(tr, 0.6, {Size = UDim2.new(0.44, 0, 0, 2)}, Enum.EasingStyle.Quint) end
			tween(diamant, 0.5, {Size = UDim2.fromScale(1.4, 1.4)}, Enum.EasingStyle.Back)
			tween(sous, 0.8, {TextTransparency = 0})
			tween(contourSous, 0.8, {Transparency = 0})
		end
	end)
end

-- ================= Animation =================
local cibleWagon, xWagon = 0, 0
local sortie = false
local function maj(p: number)
	allume.Size = UDim2.fromScale(p, 0.5)
	if not sortie then cibleWagon = p end
	local texteP = string.format("%d%%", math.floor(p * 100 + 0.5))
	if pct.Text ~= texteP then pct.Text = texteP end
	for _, s in segments do
		if not s.allume and p >= s.seuil - 0.001 then
			s.allume = true
			tween(s.metal, 0.25, {BackgroundTransparency = 0})
			s.lueur.BackgroundTransparency = 0.25
			tween(s.lueur, 0.7, {BackgroundTransparency = 0.78})
		end
	end
end
local function animer(t: number, dt: number)
	-- secousse des impacts : on ne déplace le mur (des centaines de blocs) que pendant une secousse, pas à chaque image
	if secousse > 0 then
		secousse = math.max(0, secousse - dt)
		local sx, sy = rng:NextNumber(-1, 1) * secousse * 0.012, rng:NextNumber(-1, 1) * secousse * 0.012
		if secousse == 0 then sx, sy = 0, 0 end
		mur.Position = UDim2.fromScale(0.5 + sx, 0.5 + sy)
		charpente.Position = UDim2.fromScale(sx * 0.6, sy * 0.6)
		veine.Position = UDim2.fromScale(sx, sy)
	end
	lumiere.Size = UDim2.fromScale(1.6 + 0.04 * math.sin(t * 7.3) + 0.03 * math.sin(t * 13.1), 1.6)
	vacillement.BackgroundTransparency = math.clamp(0.93 + 0.12 * math.noise(t * 2.2, 0.37), 0.84, 1)
	auraTitre.Size = UDim2.fromScale(0.62 + 0.02 * math.sin(t * 2), 0.34)
	for _, m in mineraisMur do
		m.lueur.Size = UDim2.fromScale(1.4 + 0.25 * math.sin(t * m.vitesse + m.phase), 1.4)
	end
	for _, liste in {etoilesMur, etoilesTitre, etoilesWagon} do
		for _, s in liste do
			if t > s.prochain then
				s.prochain = t + rng:NextNumber(1.2, 4.5)
				scintiller(s)
			end
		end
	end
	for _, l in lanternes do
		l.pivot.Rotation = 5 * math.sin(t * 1.3 + l.phase)
		l.lueur.Size = UDim2.fromScale(0.7 + 0.04 * math.sin(t * 9 + l.phase) + 0.03 * math.sin(t * 17), 0.7)
	end
	-- lettres : vague douce une fois posées, reflet qui court de lettre en lettre
	for _, l in lettres do
		if l.pose then
			l.corps.Position = UDim2.fromScale(0, -0.035 * math.sin(t * 2.4 - l.i * 0.45))
		end
		l.reflet.Offset = Vector2.new(((t * 0.45 - l.i * 0.035) % 1.6) * 2 - 1.6, 0)
	end
	-- veine d'or : pulsation qui coule le long de la fissure
	for k, s in segments do
		if s.allume then
			s.lueur.BackgroundTransparency = 0.74 + 0.1 * math.sin(t * 4 - k * 0.35)
		end
	end
	lueurRail.BackgroundTransparency = 0.8 + 0.08 * math.sin(t * 5)
	lueurWagon.Size = UDim2.fromScale(0.55 + 0.05 * math.sin(t * 11), 0.55)
	-- wagon : rattrape sa cible, roues qui tournent, cahots et étincelles selon la vitesse
	local avant = xWagon
	xWagon += (cibleWagon - xWagon) * math.min(1, dt * (if sortie then 2.2 else 5))
	if sortie then cibleWagon += dt * 0.9 end
	local vitesse = (xWagon - avant) / math.max(dt, 1e-3)
	local cahot = math.min(1, math.abs(vitesse) * 6) * math.abs(math.sin(t * 22)) * 0.4
	wagon.Position = UDim2.fromScale(xWagon, 0.05 - cahot)
	for _, r in roues do r.Rotation += (xWagon - avant) * 2600 end
	if math.abs(vitesse) > 0.01 and rng:NextNumber() < math.min(0.9, math.abs(vitesse) * 8) then
		lancerEtincelle(xWagon - 0.025 + rng:NextNumber(-0.012, 0.012))
		if rng:NextNumber() < 0.5 then lancerEtincelle(xWagon + 0.025) end
	end
	for _, e in etincelles do
		if e.vie > 0 then
			e.vie -= dt
			e.vy += 110 * dt
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.f.Position = UDim2.fromScale(e.x, e.y)
			e.f.BackgroundTransparency = 1 - math.clamp(e.vie / 0.35, 0, 1)
			if e.vie <= 0 then e.f.Visible = false end
		end
	end
	-- braises, poussière dans la lumière, cailloux qui tombent du plafond
	for _, b in braises do
		b.y -= b.v * dt
		if b.y < -0.02 then b.y, b.x = 1.02, rng:NextNumber() end
		b.f.Position = UDim2.fromScale(b.x + 0.012 * math.sin(t * 1.7 + b.phase), b.y)
		b.f.BackgroundTransparency = 0.15 + 0.85 * (1 - b.y) ^ 2
	end
	for _, d in poussieres do
		d.y += d.v * dt
		if d.y > 0.82 then d.y, d.x = 0.15, rng:NextNumber(0.1, 0.9) end
		d.f.Position = UDim2.fromScale(d.x + 0.01 * math.sin(t * 0.6 + d.phase), d.y)
		d.f.BackgroundTransparency = 0.45 + 0.45 * (0.5 + 0.5 * math.sin(t * 1.8 + d.phase))
	end
	if t > prochainCaillou then
		prochainCaillou = t + rng:NextNumber(0.9, 2.4)
		for _, c in cailloux do
			if not c.actif then
				c.actif, c.x, c.y, c.vy, c.rot = true, rng:NextNumber(0.08, 0.92), 0.12, 0, rng:NextNumber(-300, 300)
				c.f.Visible, c.f.BackgroundTransparency = true, 0
				break
			end
		end
	end
	for _, c in cailloux do
		if c.actif then
			c.vy += 1.6 * dt
			c.y += c.vy * dt
			c.f.Position = UDim2.fromScale(c.x, c.y)
			c.f.Rotation += c.rot * dt
			if c.y > SOL_Y then
				c.actif, c.f.Visible = false, false
			end
		end
	end
	-- chauves-souris qui traversent la galerie
	if t > prochaineChauve then
		prochaineChauve = t + rng:NextNumber(4, 8)
		for _, b in chauves do
			if not b.actif then
				local sens = if rng:NextNumber() < 0.5 then 1 else -1
				b.actif, b.sens, b.x, b.y0, b.phase = true, sens, if sens > 0 then -0.05 else 1.05, rng:NextNumber(0.16, 0.3), rng:NextNumber(0, 6.28)
				b.vitesse = rng:NextNumber(0.22, 0.34)
				b.c.Visible = true
				break
			end
		end
	end
	for _, b in chauves do
		if b.actif then
			b.x += b.sens * b.vitesse * dt
			b.c.Position = UDim2.fromScale(b.x, b.y0 + 0.03 * math.sin(t * 3 + b.phase))
			b.c.Rotation = b.sens * 8 + 6 * math.sin(t * 6 + b.phase)
			local battement = 35 * math.sin(t * 22 + b.phase)
			for _, a in b.ailes do a.pivot.Rotation = a.s * battement end
			if b.x < -0.08 or b.x > 1.08 then b.actif, b.c.Visible = false, false end
		end
	end
end
local function sortieWagon()
	sortie = true
	cibleWagon = 1.7
end

-- ================= Progression =================
local debut = os.clock()
local etat = {debut = 0, fin = 0, frac = 0, depuis = os.clock(), affiche = 0, fini = false}
local function etape(debutP: number, finP: number, libelle: string)
	etat.debut, etat.fin, etat.frac, etat.depuis = debutP, finP, 0, os.clock()
	etiquette.Text = libelle
end
local function tard(): boolean
	return os.clock() - debut > DUREE_MAX
end

-- Temps d'animation à pas bornés : quand le jeu gèle (chargement de la carte, du personnage…), les animations
-- reprennent là où elles s'étaient arrêtées au lieu de sauter d'un coup (braises, wagon, lettres, barre).
local PAS_MAX = 1 / 30
local tAnim = 0
local connexion = RunService.RenderStepped:Connect(function(dtReel)
	local dt = math.min(dtReel, PAS_MAX)
	tAnim += dt
	-- cible = étape en cours ; si l'étape ne donne pas d'avancement précis, la barre avance doucement (jamais figée)
	local lent = 0.8 * (1 - math.exp(-(os.clock() - etat.depuis) / 4))
	local frac = math.max(etat.frac, lent)
	local cible = if etat.fini then 1 else etat.debut + (etat.fin - etat.debut) * math.clamp(frac, 0, 1)
	-- la barre glisse vers sa cible à vitesse limitée : jamais de bond, même après un gel
	local ecart = cible - etat.affiche
	local pas = math.clamp(ecart * math.min(1, dt * (if etat.fini then 6 else 3)), -dt * 0.6, dt * 0.6)
	etat.affiche += pas
	if math.abs(cible - etat.affiche) < 0.002 then etat.affiche = cible end
	maj(etat.affiche)
	animer(tAnim, dt)
end)
task.spawn(function()
	while gui.Parent do
		task.wait(5)
		if gui.Parent then montrerAstuce() end
	end
end)

-- contrôles coupés tant que l'écran est là, si le PlayerModule de Roblox est présent (sans jamais l'attendre :
-- cette place peut ne pas l'avoir, comme BossOutils.controles)
local controlesCoupes
local function couperControles(actif: boolean)
	if actif then
		if controlesCoupes then pcall(function() controlesCoupes:Enable() end) end
		controlesCoupes = nil
		return
	end
	local ok, c = pcall(function()
		local ps = joueur:FindFirstChild("PlayerScripts")
		local pm = ps and ps:FindFirstChild("PlayerModule")
		return if pm and pm:IsA("ModuleScript") then require(pm):GetControls() else nil
	end)
	if ok and c then
		c:Disable()
		controlesCoupes = c
	end
end

-- 1. le jeu de base
etape(0, 0.3, "Allumage des lanternes…")
local maxFile = 1
while not game:IsLoaded() and not tard() do
	local f = ContentProvider.RequestQueueSize
	maxFile = math.max(maxFile, f)
	etat.frac = 1 - f / maxFile
	task.wait(0.1)
end

-- 2. la carte construite par le serveur
etape(0.3, 0.45, "Creusement des galeries…")
local debutPas = os.clock()
while not workspace:GetAttribute("MondeConstruit") and not tard() and os.clock() - debutPas < 40 do
	task.wait(0.1)
end

-- 3. le personnage et le sol sous ses pieds
etape(0.45, 0.65, "Le village se réveille…")
debutPas = os.clock()
local racinePerso
while not tard() and os.clock() - debutPas < 30 do
	local perso = joueur.Character
	racinePerso = perso and perso:FindFirstChild("HumanoidRootPart")
	if racinePerso then break end
	task.wait(0.1)
end
if racinePerso then
	couperControles(false)
	etat.frac = 0.3
	local pos = racinePerso.Position
	local fluxFini = false
	task.spawn(function()
		pcall(joueur.RequestStreamAroundAsync, joueur, pos, 6)
		fluxFini = true
	end)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {joueur.Character}
	debutPas = os.clock()
	while not tard() and os.clock() - debutPas < 8 do
		local sol = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0), params)
		etat.frac = 0.3 + (if sol then 0.35 else 0) + (if fluxFini then 0.35 else 0)
		if sol and fluxFini then break end
		task.wait(0.1)
	end
end

-- 4. la sauvegarde du joueur
etape(0.65, 0.8, "Ton sac de mineur arrive…")
debutPas = os.clock()
while not joueur:GetAttribute("DonneesChargees") and not tard() and os.clock() - debutPas < 20 do
	task.wait(0.1)
end

-- 5. textures et sons en attente
etape(0.8, 1, "Polissage des minerais…")
debutPas = os.clock()
maxFile = math.max(1, ContentProvider.RequestQueueSize)
while not tard() and os.clock() - debutPas < 10 do
	local f = ContentProvider.RequestQueueSize
	maxFile = math.max(maxFile, f)
	etat.frac = 1 - f / maxFile
	if f <= 2 then break end
	task.wait(0.1)
end

-- fin : durée minimale pour voir le titre, la barre se remplit, le wagon file hors de l'écran, fondu
while os.clock() - debut < DUREE_MIN do task.wait(0.05) end
etat.fini = true
etiquette.Text = "C'est parti !"
local attente = os.clock()
while etat.affiche < 0.995 and os.clock() - attente < 1.5 do task.wait(0.05) end
task.wait(0.3)
sortieWagon()
task.wait(0.7)
couperControles(true)
remettreInterfaces()
-- éclair doré, puis le jeu apparaît
tween(eclair, 0.12, {BackgroundTransparency = 0.45}).Completed:Connect(function()
	tween(eclair, 0.6, {BackgroundTransparency = 1})
end)
tween(echelleTitre, 0.9, {Scale = 1.12}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- fondu : l'écran passe dans un CanvasGroup seulement maintenant (un CanvasGroup permanent rend l'image floue
-- et recalcule toute la scène à chaque image)
local fondu = creer("CanvasGroup", {Name = "Fondu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui})
ecran.Parent = fondu
tween(fondu, 0.9, {GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
connexion:Disconnect()
gui:Destroy()
