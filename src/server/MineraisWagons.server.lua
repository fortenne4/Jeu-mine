-- Remplace uniquement les anciens blocs décoratifs des wagons chargés.
-- Le modèle « Minerai » reste présent pour distinguer ces wagons des wagons jouables.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Minerais = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("MineraisModeles"))
local COULEURS = {
	{nom = "Charbon", couleur = Color3.fromRGB(34, 34, 38)},
	{nom = "Bronze", couleur = Color3.fromRGB(184, 100, 46)},
	{nom = "Fer", couleur = Color3.fromRGB(156, 162, 172)},
	{nom = "Gold", couleur = Color3.fromRGB(255, 196, 48)},
}
local TOLERANCE_COULEUR = 0.08
local NOMBRE_MODELES = 3
local TAILLE_MAX = 2.25

local function typeMinerai(couleur)
	for _, entree in COULEURS do
		local c = entree.couleur
		local distance = (Vector3.new(c.R, c.G, c.B) - Vector3.new(couleur.R, couleur.G, couleur.B)).Magnitude
		if distance <= TOLERANCE_COULEUR then return entree.nom end
	end
	return nil -- une couleur inconnue n'est jamais remplacée au hasard
end

local function preparer(wagon)
	if not (wagon:IsA("Model") and wagon.Name == "Wagonnet") or wagon:GetAttribute("Minerais3D") then return end
	local anciens = {}
	for _, objet in wagon:GetChildren() do
		if objet:IsA("BasePart") and objet.Name == "Minerai" then table.insert(anciens, objet) end
	end
	if #anciens == 0 then return end
	local id = typeMinerai(anciens[1].Color)
	if not id then return end
	local fond = wagon:FindFirstChild("Fond")
	if not (fond and fond:IsA("BasePart")) then return end

	local chargement = Instance.new("Model")
	chargement.Name = "Minerai"
	chargement:SetAttribute("TypeMinerai", id)
	for i = 1, math.min(NOMBRE_MODELES, #anciens) do
		local ancien = anciens[i]
		local modele = Minerais.construire(id, CFrame.new(), Random.new(1020 + i), true)
		local etendue = modele:GetExtentsSize()
		local cible = math.min(TAILLE_MAX, math.max(ancien.Size.X, ancien.Size.Z))
		modele:ScaleTo(cible / math.max(etendue.X, etendue.Z))
		-- Orienter aussi le modèle avec le wagon, y compris sur les rails inclinés.
		local rotation = fond.CFrame.Rotation
		modele:PivotTo(CFrame.new(ancien.Position) * rotation)
		local boite = modele:GetBoundingBox()
		modele:PivotTo(modele:GetPivot() + (ancien.Position - boite.Position))
		for _, piece in modele:GetDescendants() do
			if piece:IsA("BasePart") then
				piece.Anchored, piece.CanCollide, piece.CanTouch, piece.CanQuery = true, false, false, false
			end
		end
		modele.Parent = chargement
	end
	-- Le nouveau marqueur est en place avant d'enlever les blocs d'origine.
	chargement.Parent = wagon
	for _, ancien in anciens do ancien:Destroy() end
	wagon:SetAttribute("Minerais3D", true)
end

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
for _, objet in workspace:GetDescendants() do
	if objet:IsA("Model") and objet.Name == "Wagonnet" then preparer(objet) end
end
-- Les mines privées et grottes peuvent créer des wagons après le chargement.
workspace.DescendantAdded:Connect(function(objet)
	if objet:IsA("Model") and objet.Name == "Wagonnet" then
		task.defer(preparer, objet)
	end
end)
