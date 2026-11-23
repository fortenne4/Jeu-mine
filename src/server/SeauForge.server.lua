-- Seau de trempe décoratif de la forge de Brom.
local HAUTEUR_SEAU = 2.0
local RAYON_BAS = 1.05
local RAYON_HAUT = 1.35
local NOMBRE_DOUELLES = 16
local COULEUR_BOIS = Color3.fromRGB(95, 55, 32)
local COULEUR_FERRURE = Color3.fromRGB(48, 44, 42)
local COULEUR_EAU = Color3.fromRGB(60, 120, 170)
local TRANSPARENCE_EAU = 0.4
local REFLECTANCE_EAU = 0.18
local AMPLITUDE_ONDULATION = 0.025
local DUREE_ONDULATION = 2.8
local BULLES_ACTIVES = false

local TweenService = game:GetService("TweenService")
local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local forge = carte and carte:FindFirstChild("Forge", true)
if not forge then warn("[SeauForge] Forge introuvable") return end
if forge:FindFirstChild("Forge_SeauEau") then return end
local ancien = forge:FindFirstChild("Baquet")
if not (ancien and ancien:IsA("BasePart")) then warn("[SeauForge] Ancien baquet introuvable") return end
local ancienneEau
for _, objet in forge:GetChildren() do
	if objet:IsA("BasePart") and objet.Name == "Eau" and (objet.Position - ancien.Position).Magnitude < 2 then
		ancienneEau = objet
		break
	end
end

-- Le fond de l'ancien baquet était enterré : conserver sa position horizontale
-- et le poser sur le terrain ou la plateforme qui le porte.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = if ancienneEau then {ancien, ancienneEau} else {ancien}
local contact = workspace:Raycast(ancien.Position + Vector3.yAxis * 6, -Vector3.yAxis * 14, params)
local solY = if contact then contact.Position.Y else ancien.Position.Y - ancien.Size.X / 2
local sol = Vector3.new(ancien.Position.X, solY, ancien.Position.Z)
local direction = ancien.CFrame.UpVector
local base = CFrame.lookAt(sol, sol + Vector3.new(direction.X, 0, direction.Z), Vector3.yAxis)
local seau = Instance.new("Model")
seau.Name = "Forge_SeauEau"

local function piece(nom, taille, cf, couleur, materiau)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = nom, taille, cf
	p.Color, p.Material = couleur, materiau
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = seau
	return p
end
local function cylindre(nom, epaisseur, diametre, hauteur, couleur, materiau)
	local p = piece(nom, Vector3.new(epaisseur, diametre, diametre), base * CFrame.new(0, hauteur, 0) * CFrame.Angles(0, 0, math.pi / 2), couleur, materiau)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Volume invisible pour conserver une collision simple sur le seau.
local collision = cylindre("VolumeSeau", HAUTEUR_SEAU, 2 * RAYON_BAS, HAUTEUR_SEAU / 2, COULEUR_BOIS, Enum.Material.Wood)
collision.Transparency, collision.CanCollide = 1, true
cylindre("Fond", 0.12, 2 * RAYON_BAS, 0.06, COULEUR_BOIS, Enum.Material.WoodPlanks)
local angle = 2 * math.pi / NOMBRE_DOUELLES
local pente = math.atan((RAYON_HAUT - RAYON_BAS) / HAUTEUR_SEAU)
for i = 0, NOMBRE_DOUELLES - 1 do
	local a = i * angle
	local orientation = base * CFrame.Angles(0, a, 0)
	local rayon = (RAYON_BAS + RAYON_HAUT) / 2
	local couleur = if i % 3 == 0 then COULEUR_BOIS:Lerp(Color3.new(0, 0, 0), 0.12) else COULEUR_BOIS
	piece("Douelle", Vector3.new(2 * RAYON_HAUT * math.tan(angle / 2) + 0.025, HAUTEUR_SEAU / math.cos(pente), 0.16),
		orientation * CFrame.new(0, HAUTEUR_SEAU / 2, rayon) * CFrame.Angles(pente, 0, 0), couleur, Enum.Material.WoodPlanks)
	for _, h in {0.35, 1.48} do
		local r = RAYON_BAS + (RAYON_HAUT - RAYON_BAS) * h / HAUTEUR_SEAU + 0.085
		piece("Cerclage", Vector3.new(2 * r * math.tan(angle / 2) + 0.025, 0.13, 0.12), orientation * CFrame.new(0, h, r), COULEUR_FERRURE, Enum.Material.Metal)
	end
	local r = RAYON_HAUT + 0.03
	piece("Bord", Vector3.new(2 * r * math.tan(angle / 2) + 0.025, 0.13, 0.2), orientation * CFrame.new(0, HAUTEUR_SEAU, r), COULEUR_BOIS:Lerp(Color3.new(0, 0, 0), 0.12), Enum.Material.WoodPlanks)
	if i % 4 == 0 then
		for _, h in {0.35, 1.48} do
			local rRivet = RAYON_BAS + (RAYON_HAUT - RAYON_BAS) * h / HAUTEUR_SEAU + 0.16
			local rivet = piece("Rivet", Vector3.one * 0.09, orientation * CFrame.new(0, h, rRivet), Color3.fromRGB(100, 96, 89), Enum.Material.Metal)
			rivet.Shape = Enum.PartType.Ball
		end
	end
end

-- Anse arquée faite de courts segments métalliques.
local function ansePoint(a)
	return Vector3.new(math.cos(a) * (RAYON_HAUT + 0.12), HAUTEUR_SEAU - 0.16 + math.sin(a) * 0.85, 0)
end
for i = 0, 11 do
	local a, b = ansePoint(math.pi * i / 12), ansePoint(math.pi * (i + 1) / 12)
	local milieu = (a + b) / 2
	piece("Anse", Vector3.new(0.09, 0.09, (b - a).Magnitude + 0.02), base * CFrame.lookAt(milieu, b), COULEUR_FERRURE, Enum.Material.Metal)
end

local niveau = HAUTEUR_SEAU - 0.25
local eau = cylindre("Eau", 0.07, 2 * (RAYON_HAUT - 0.19), niveau, COULEUR_EAU, Enum.Material.Glass)
eau.Transparency, eau.Reflectance = TRANSPARENCE_EAU, REFLECTANCE_EAU
-- Une fine surface teintée rend l'eau lisible même lorsque le verre Roblox
-- ne reflète presque que ses bords dans l'éclairage sombre de la forge.
local reflet = cylindre("RefletEau", 0.025, 2 * (RAYON_HAUT - 0.23), niveau + 0.045, Color3.fromRGB(95, 165, 200), Enum.Material.SmoothPlastic)
reflet.Transparency, reflet.Reflectance = 0.5, 0.12
for _, surface in {eau, reflet} do
	local tween = TweenService:Create(surface, TweenInfo.new(DUREE_ONDULATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{CFrame = surface.CFrame + Vector3.yAxis * AMPLITUDE_ONDULATION})
	tween:Play()
end
-- Réservé à une éventuelle version à bulles ; désactivé par défaut.
if BULLES_ACTIVES then
	local bulles = Instance.new("ParticleEmitter")
	bulles.Name, bulles.Rate, bulles.Speed = "Bulles", 1, NumberRange.new(0.15, 0.3)
	bulles.Lifetime = NumberRange.new(0.3, 0.6)
	bulles.Parent = eau
end
seau.PrimaryPart = collision
seau.Parent = forge
ancien:Destroy()
if ancienneEau then ancienneEau:Destroy() end
