-- Animations du décor, calculées chez chaque joueur (fluide et sans charge réseau) :
--  • tag "Flottant" : le modèle monte, descend et tourne doucement (attribut Amplitude)
--  • tag "Rotatif"  : le modèle tourne autour de l'axe X de son pivot (attribut Vitesse, en rad/s)
--  • tag "PNJ"      : le PNJ respire et tourne la tête vers le joueur quand il s'approche
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local joueur = Players.LocalPlayer
local PNJ_DISTANCE = 28 -- studs
local PNJ_ROTATION_MAX = 1.1 -- radians (~63°)

local actifs = {}
local pnjs = {}
local lanternes = {}

local function ajouterLanterne(lumiere)
	if lumiere:IsA("PointLight") then
		lanternes[lumiere] = math.random() * 10
	end
end
CollectionService:GetInstanceAddedSignal("LueurLanterne"):Connect(ajouterLanterne)
CollectionService:GetInstanceRemovedSignal("LueurLanterne"):Connect(function(lumiere) lanternes[lumiere] = nil end)
for _, lumiere in CollectionService:GetTagged("LueurLanterne") do ajouterLanterne(lumiere) end

local function ajouter(instance)
	if instance:IsA("Model") then
		actifs[instance] = {origine = instance:GetPivot(), phase = math.random() * math.pi * 2}
	end
end

local function retirer(instance)
	actifs[instance] = nil
end

for _, tag in {"Flottant", "Rotatif"} do
	CollectionService:GetInstanceAddedSignal(tag):Connect(ajouter)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(retirer)
	for _, instance in CollectionService:GetTagged(tag) do
		ajouter(instance)
	end
end

local function ajouterPnj(modele)
	if not modele:IsA("Model") or modele:GetAttribute("Squelette") then
		return -- nains articulés : animés par AnimationsNains.client.lua
	end
	task.spawn(function()
		-- PNJ avatar (R15) : l'animation de repos gère la respiration, on tourne seulement le cou
		if modele:FindFirstChildOfClass("Humanoid") then
			local tete = modele:WaitForChild("Head", 10)
			local cou = tete and tete:WaitForChild("Neck", 10)
			local racine = modele:WaitForChild("HumanoidRootPart", 10)
			if cou and cou:IsA("Motor6D") and racine then
				pnjs[modele] = {cou = cou, c0 = cou.C0, racine = racine, rotation = 0}
			end
			return
		end
		local buste = modele:WaitForChild("Buste", 10)
		local tete = modele:WaitForChild("Tete", 10)
		if buste and tete and modele.Parent then
			pnjs[modele] = {
				buste = buste,
				tete = tete,
				origineBuste = buste:GetPivot(),
				origineTete = tete:GetPivot(),
				phase = math.random() * math.pi * 2,
				rotation = 0,
			}
		end
	end)
end

CollectionService:GetInstanceAddedSignal("PNJ"):Connect(ajouterPnj)
CollectionService:GetInstanceRemovedSignal("PNJ"):Connect(function(modele)
	pnjs[modele] = nil
end)
for _, modele in CollectionService:GetTagged("PNJ") do
	ajouterPnj(modele)
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for lumiere, phase in lanternes do
		lumiere.Brightness = 2.2 + 0.32 * math.noise((t + phase) * 1.8) + 0.12 * math.noise((t + phase) * 4)
	end

	for modele, info in actifs do
		if CollectionService:HasTag(modele, "Rotatif") then
			local vitesse = modele:GetAttribute("Vitesse") or 0.5
			modele:PivotTo(info.origine * CFrame.Angles(t * vitesse, 0, 0))
		else
			local amplitude = modele:GetAttribute("Amplitude") or 0.8
			modele:PivotTo(info.origine
				* CFrame.new(0, math.sin(t * 1.2 + info.phase) * amplitude, 0)
				* CFrame.Angles(0, t * 0.35, 0))
		end
	end

	local perso = joueur.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	for modele, p in pnjs do
		if not modele.Parent then
			pnjs[modele] = nil
			continue
		end
		if p.cou then
			local cible = 0
			if racine then
				local relatif = p.racine.CFrame:PointToObjectSpace(racine.Position)
				if relatif.Magnitude < PNJ_DISTANCE and relatif.Z < 2 then
					cible = math.clamp(math.atan2(-relatif.X, -relatif.Z), -PNJ_ROTATION_MAX, PNJ_ROTATION_MAX)
				end
			end
			p.rotation += (cible - p.rotation) * math.min(1, dt * 4)
			p.cou.C0 = p.c0 * CFrame.Angles(0, p.rotation, 0)
			continue
		end
		local souffle = math.sin(t * 1.7 + p.phase) * 0.03
		p.buste:PivotTo(p.origineBuste + Vector3.new(0, souffle, 0))

		local cible = 0
		if racine then
			local relatif = p.origineTete:PointToObjectSpace(racine.Position)
			if relatif.Magnitude < PNJ_DISTANCE and relatif.Z < 2 then
				local maxi = math.min(PNJ_ROTATION_MAX, modele:GetAttribute("RotationTeteMax") or PNJ_ROTATION_MAX)
				cible = math.clamp(math.atan2(-relatif.X, -relatif.Z), -maxi, maxi)
			end
		end
		p.rotation += (cible - p.rotation) * math.min(1, dt * 4)
		p.tete:PivotTo(p.origineTete * CFrame.new(0, souffle, 0) * CFrame.Angles(0, p.rotation, 0))
	end
end)
