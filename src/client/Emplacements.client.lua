-- Emplacements · SCRIPT CLIENT (barre d'objets en bas de l'écran)
-- Où : StarterPlayer > StarterPlayerScripts > Jeu
-- Remplace la barre d'objets de Roblox par une barre en bois et laiton, aux couleurs de la boutique de Liesel :
-- aperçu 3D de chaque outil, touche (1, 2, 3...), nom, et lisere doré sur l'outil en main.
-- Touches 1 à 9 ou clic : prendre / ranger l'outil.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local joueur = Players.LocalPlayer

local T = {
	Bois = Color3.fromRGB(38, 27, 20),
	BoisClair = Color3.fromRGB(62, 44, 31),
	Laiton = Color3.fromRGB(242, 198, 96),
	LaitonFonce = Color3.fromRGB(150, 104, 44),
	Parchemin = Color3.fromRGB(236, 222, 196),
	Fond3D = Color3.fromRGB(24, 17, 13),
}
local MAX = 9
local TOUCHES = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
}

-- Cacher la barre d'objets de Roblox (réessaie tant que le CoreGui n'est pas prêt)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then break end
		task.wait(0.5)
	end
end)

local function creer(classe: string, props: {[string]: any}, enfants: {Instance}?): any
	local o = Instance.new(classe)
	for cle, valeur in props do
		if cle ~= "Parent" then
			(o :: any)[cle] = valeur
		end
	end
	for _, e in enfants or {} do
		e.Parent = o
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function coin(r: number): UICorner
	return creer("UICorner", {CornerRadius = UDim.new(r, 0)})
end
local function trait(couleur: Color3, epaisseur: number, transparence: number?): UIStroke
	return creer("UIStroke", {Color = couleur, Thickness = epaisseur, Transparency = transparence or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

local ecran = creer("ScreenGui", {Name = "Emplacements", ResetOnSpawn = false, IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 2, Parent = joueur:WaitForChild("PlayerGui")})

-- Planche de bois qui porte les emplacements
local planche = creer("Frame", {Name = "Planche", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = T.Bois,
	BackgroundTransparency = 0.12, Parent = ecran}, {
	coin(0.18), trait(T.LaitonFonce, 2.5),
	creer("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}),
	creer("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 150, 135))}),
})
local TAILLE = 74

type Slot = {cadre: TextButton, vue: ViewportFrame, nom: TextLabel, touche: TextLabel, lisere: UIStroke, outil: Tool?}
local slots: {Slot} = {}

for i = 1, MAX do
	local cadre = creer("TextButton", {Name = "Emplacement" .. i, Text = "", AutoButtonColor = false, LayoutOrder = i,
		Size = UDim2.fromOffset(TAILLE, TAILLE), BackgroundColor3 = T.BoisClair, Visible = false, Parent = planche}, {
		coin(0.16),
		creer("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 220), Color3.fromRGB(150, 130, 115))}),
	})
	local lisere = trait(T.LaitonFonce, 2)
	lisere.Parent = cadre
	local vue = creer("ViewportFrame", {Name = "Apercu", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -18),
		Position = UDim2.fromOffset(4, 2), Ambient = Color3.fromRGB(170, 160, 150), LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1), ZIndex = 2, Parent = cadre})
	local touche = creer("TextLabel", {Name = "Touche", Text = tostring(i), Font = Enum.Font.GothamBlack, TextScaled = true,
		TextColor3 = T.Bois, BackgroundColor3 = T.Laiton, Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(-5, -5),
		ZIndex = 4, Parent = cadre}, {coin(0.5), trait(T.LaitonFonce, 1.5)})
	local nom = creer("TextLabel", {Name = "Nom", Text = "", Font = Enum.Font.GothamBold, TextScaled = true,
		TextColor3 = T.Parchemin, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, -6, 0, 13), ZIndex = 3, Parent = cadre}, {
		creer("UITextSizeConstraint", {MaxTextSize = 12}),
		creer("UIStroke", {Color = T.Bois, Thickness = 1.5}),
	})
	table.insert(slots, {cadre = cadre, vue = vue, nom = nom, touche = touche, lisere = lisere, outil = nil})
end

-- Nom court affiché sous l'aperçu : toute pioche s'affiche « Pioche » (« Pioche du Bûcheron » → « Pioche »)
local function nomCourt(outil: Tool): string
	if outil.Name:sub(1, 6) == "Pioche" then
		return "Pioche"
	end
	return outil.Name
end

-- Aperçu 3D : copie des pièces visibles de l'outil (sans l'aura), cadrée de biais
local function remplirApercu(vue: ViewportFrame, outil: Tool)
	vue:ClearAllChildren()
	local modele = Instance.new("Model")
	local handle = outil:FindFirstChild("Handle") :: BasePart?
	local repere = handle and handle.CFrame or CFrame.identity
	for _, p in outil:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and not p:GetAttribute("Coque")
			and not p:FindFirstAncestor("Aura") and p.Name ~= "Aura" then
			local c = p:Clone()
			c:ClearAllChildren()
			c.Anchored = true
			c.CFrame = repere:ToObjectSpace(p.CFrame)
			c.Parent = modele
		end
	end
	if #modele:GetChildren() == 0 then
		modele:Destroy()
		local icone = creer("TextLabel", {Text = "⛏", TextScaled = true, BackgroundTransparency = 1, TextColor3 = T.Laiton,
			Size = UDim2.fromScale(1, 1), Parent = vue})
		icone.Name = "Icone"
		return
	end
	modele.WorldPivot = CFrame.identity
	modele:PivotTo(CFrame.Angles(0, 0, math.rad(-35)) * CFrame.Angles(0, math.rad(90), 0))
	local cf, taille = modele:GetBoundingBox()
	modele.Parent = vue
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local rayon = taille.Magnitude / 2
	local distance = rayon / math.tan(math.rad(camera.FieldOfView / 2)) * 1.02
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, distance), cf.Position)
	camera.Parent = vue
	vue.CurrentCamera = camera
end

local function humanoide(): Humanoid?
	local perso = joueur.Character
	return perso and perso:FindFirstChildOfClass("Humanoid")
end

local function outilEnMain(): Tool?
	local perso = joueur.Character
	return perso and perso:FindFirstChildOfClass("Tool")
end

-- Liste ordonnée des outils : on garde la place de chacun, les nouveaux vont au bout
local ordre: {Tool} = {}

local function majSlots()
	-- retirer les outils partis, ajouter les nouveaux
	local presents: {[Tool]: boolean} = {}
	local sac = joueur:FindFirstChildOfClass("Backpack")
	for _, conteneur in {sac, joueur.Character} do
		if conteneur then
			for _, o in conteneur:GetChildren() do
				if o:IsA("Tool") then
					presents[o] = true
				end
			end
		end
	end
	local nouvelOrdre = {}
	for _, o in ordre do
		if presents[o] then
			table.insert(nouvelOrdre, o)
			presents[o] = nil
		end
	end
	for o in presents do
		table.insert(nouvelOrdre, o)
	end
	ordre = nouvelOrdre

	local enMain = outilEnMain()
	for i, s in slots do
		local o = ordre[i]
		s.cadre.Visible = o ~= nil
		if o ~= s.outil then
			s.outil = o
			if o then
				s.nom.Text = nomCourt(o)
				task.defer(remplirApercu, s.vue, o) -- après que les pièces de l'outil sont arrivées
			else
				s.vue:ClearAllChildren()
			end
		end
		local actif = o ~= nil and o == enMain
		local couleur = o and o:GetAttribute("Lueur")
		TweenService:Create(s.lisere, TweenInfo.new(0.15), {
			Color = actif and (typeof(couleur) == "Color3" and couleur:Lerp(T.Laiton, 0.4) or T.Laiton) or T.LaitonFonce,
			Thickness = actif and 3.5 or 2,
		}):Play()
		TweenService:Create(s.cadre, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			Size = UDim2.fromOffset(actif and TAILLE + 8 or TAILLE, actif and TAILLE + 8 or TAILLE),
			BackgroundColor3 = actif and Color3.fromRGB(96, 68, 44) or T.BoisClair,
		}):Play()
		s.touche.BackgroundColor3 = actif and Color3.new(1, 1, 1) or T.Laiton
	end
end

local function basculer(i: number)
	local o = ordre[i]
	local h = humanoide()
	if not o or not h or h.Health <= 0 then return end
	if o.Parent == joueur.Character then
		h:UnequipTools()
	else
		h:EquipTool(o)
	end
	-- petit rebond du bouton
	local s = slots[i]
	local echelle = s.cadre:FindFirstChild("Rebond") :: UIScale?
	if not echelle then
		echelle = creer("UIScale", {Name = "Rebond", Parent = s.cadre})
	end
	(echelle :: UIScale).Scale = 0.85
	TweenService:Create(echelle :: UIScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

for i, s in slots do
	s.cadre.Activated:Connect(function()
		basculer(i)
	end)
	s.cadre.MouseEnter:Connect(function()
		if s.outil ~= outilEnMain() then
			TweenService:Create(s.lisere, TweenInfo.new(0.1), {Color = T.Laiton}):Play()
		end
	end)
	s.cadre.MouseLeave:Connect(majSlots)
end

UserInputService.InputBegan:Connect(function(input, traite)
	if traite then return end
	for i, k in TOUCHES do
		if input.KeyCode == k or input.KeyCode.Value == Enum.KeyCode.KeypadOne.Value + i - 1 then
			basculer(i)
			return
		end
	end
end)

-- Suivre le sac et le personnage
local suivis: {RBXScriptConnection} = {}
local function suivre(conteneur: Instance?)
	if not conteneur then return end
	table.insert(suivis, conteneur.ChildAdded:Connect(function(o)
		if o:IsA("Tool") then majSlots() end
	end))
	table.insert(suivis, conteneur.ChildRemoved:Connect(function(o)
		if o:IsA("Tool") then majSlots() end
	end))
end
local function surPersonnage(perso: Model)
	for _, c in suivis do
		c:Disconnect()
	end
	table.clear(suivis)
	suivre(perso)
	suivre(joueur:WaitForChild("Backpack"))
	majSlots()
end
joueur.CharacterAdded:Connect(surPersonnage)
joueur.ChildAdded:Connect(function(o) -- nouveau sac à chaque réapparition
	if o:IsA("Backpack") and joueur.Character then
		surPersonnage(joueur.Character)
	end
end)
if joueur.Character then
	surPersonnage(joueur.Character)
end

-- La barre se cache quand le personnage est mort
RunService.Heartbeat:Connect(function()
	local h = humanoide()
	planche.Visible = h ~= nil and h.Health > 0 and #ordre > 0
end)
