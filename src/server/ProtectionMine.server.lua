-- Barrières physiques et contrôle serveur de l'accès à la grande mine.
local DEBUG_SHOW_WALLS = false
local PERIODE_VERIFICATION = 0.15
local MURS = {
	-- Le cadre en bois de l'entrée se trouve à Z = -175 (portail Z = -178 + 3).
	{name = "InvisibleWall_Station", position = Vector3.new(0, 25, -175), taille = Vector3.new(120, 70, 4)},
	{name = "InvisibleWall_MineEntrance", position = Vector3.new(0, 20, -180), taille = Vector3.new(100, 60, 4)},
	-- Dernier cadre en bois de la descente, juste avant le quai souterrain.
	{name = "InvisibleWall_MineBottom", position = Vector3.new(0, -45, -345.6), taille = Vector3.new(80, 50, 4)},
}
local RETOUR_GARE = Vector3.new(-9.5, 6, -128)
local RETOUR_MINE = Vector3.new(-12, -54, -388)

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local acces = require(script.Parent:WaitForChild("AccesMine"))

-- Les clones de la cinématique sont locaux et non physiques ; les vrais wagons restent immobiles.
-- Le groupe dédié couvre aussi les futurs éléments de wagon qui l'utiliseraient.
for _, nom in {"InvisibleWalls", "Wagon"} do
	if not PhysicsService:IsCollisionGroupRegistered(nom) then PhysicsService:RegisterCollisionGroup(nom) end
end
PhysicsService:CollisionGroupSetCollidable("InvisibleWalls", "Wagon", false)

local function grouperWagon(instance: Instance)
	if not instance:IsA("BasePart") then return end
	local modele = instance:FindFirstAncestor("Wagonnet")
	local mine = workspace:FindFirstChild("Carte")
	mine = mine and mine:FindFirstChild("Mine")
	if modele and mine and modele:IsDescendantOf(mine) then instance.CollisionGroup = "Wagon" end
end
workspace.DescendantAdded:Connect(function(instance) task.defer(grouperWagon, instance) end)
task.spawn(function()
	for _, instance in workspace:GetDescendants() do grouperWagon(instance) end
end)

local dossier = Instance.new("Folder")
dossier.Name = "InvisibleWalls"
dossier.Parent = workspace
for _, definition in MURS do
	local mur = Instance.new("Part")
	mur.Name = definition.name
	mur.Size = definition.taille
	mur.Position = definition.position
	mur.Anchored = true
	mur.Transparency = if DEBUG_SHOW_WALLS then 0.5 else 1
	mur.Color = Color3.fromRGB(255, 80, 30)
	mur.CanCollide = true
	mur.CanTouch = false
	mur.CanQuery = false
	mur.CollisionGroup = "InvisibleWalls"
	mur.Parent = dossier
end

local function deplacer(personnage: Model, racine: BasePart, position: Vector3)
	local humain = personnage:FindFirstChildOfClass("Humanoid")
	if humain then humain.Sit = false end
	personnage:PivotTo(CFrame.new(position))
	racine.AssemblyLinearVelocity = Vector3.zero
	racine.AssemblyAngularVelocity = Vector3.zero
end

Players.PlayerRemoving:Connect(acces.retirer)
while true do
	for _, joueur in Players:GetPlayers() do
		local personnage = joueur.Character
		local racine = personnage and personnage:FindFirstChild("HumanoidRootPart")
		local humain = personnage and personnage:FindFirstChildOfClass("Humanoid")
		if personnage and racine and racine:IsA("BasePart") and humain and humain.Health > 0 then
			local p = racine.Position
			local sousTerre = math.abs(p.X) < 180 and p.Z < -300 and p.Z > -560 and p.Y < -20
			local couloir = math.abs(p.X) < 48 and p.Z < -177 and p.Z > -345.6 and p.Y < 50
			local autourMine = sousTerre or couloir
			if autourMine and not acces.estAutorise(joueur, personnage) then
				deplacer(personnage, racine, RETOUR_GARE)
			elseif couloir and acces.estAutorise(joueur, personnage) then
				-- Une fois arrivé, on ne peut pas remonter à pied, même en contournant le mur.
				deplacer(personnage, racine, RETOUR_MINE)
			elseif p.Z > -145 and math.abs(p.X) < 180 and p.Y > -10 then
				acces.retirer(joueur)
			end
		end
	end
	task.wait(PERIODE_VERIFICATION)
end
