-- Retouches des arbres du village (carte figée ou reconstruite) : arbres retirés, repérés par leur type
-- et leur position au sol, et arbres ajoutés à la main.
local A_RETIRER = {
	{nom = "^Saule", x = -10, z = 55}, -- saule pleureur près du puits, gênait la vue de la rue du sud
}
local TOLERANCE = 4 -- distance au sol (studs) entre la position notée et le pied de l'arbre
-- type = "pin" ou "sapin" ; hauteur en studs (les pins des bosquets font 18 à 30)
local A_AJOUTER = {
	{type = "pin", x = -34, z = -53, hauteur = 24}, -- herbe entre le classement « Meilleurs Mineurs » et la statue du roi
	{type = "pin", x = -38, z = -58, hauteur = 27},
}

local ServerStorage = game:GetService("ServerStorage")
local Batiments = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Batiments"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local village = workspace:FindFirstChild("Carte") and workspace.Carte:FindFirstChild("Village")
if not village then warn("[ArbresVillage] Village introuvable") return end

for _, objet in village:GetDescendants() do
	if objet:IsA("Model") and objet.Parent then
		local p = objet:GetPivot().Position
		for _, a in A_RETIRER do
			if objet.Name:match(a.nom) and Vector2.new(p.X - a.x, p.Z - a.z).Magnitude < TOLERANCE then
				objet:Destroy()
				break
			end
		end
	end
end

if village:FindFirstChild("ArbresAjoutes") then return end
local groupe = Instance.new("Folder")
groupe.Name = "ArbresAjoutes"
groupe.Parent = village
local rayons = RaycastParams.new()
rayons.RespectCanCollide = true
rayons.FilterType = Enum.RaycastFilterType.Exclude
rayons.FilterDescendantsInstances = {groupe}
for index, a in A_AJOUTER do
	local impact = workspace:Raycast(Vector3.new(a.x, 40, a.z), Vector3.new(0, -80, 0), rayons)
	if not impact then warn("[ArbresVillage] Sol introuvable pour l'arbre " .. index) continue end
	local rng = Random.new(index * 7919 + a.x * 31 + a.z) -- même arbre à chaque lancement
	local base = Vector3.new(a.x, impact.Position.Y - 0.3, a.z) -- pied légèrement enfoncé dans l'herbe
	if a.type == "sapin" then Batiments.sapin(groupe, base, a.hauteur, rng) else Batiments.pin(groupe, base, a.hauteur, rng) end
end
