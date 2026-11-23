-- Tonneaux éclairés sur la rue à l'est de la forge, hors des pavés.
local ESPACEMENT = 14
local DISTANCE_AXE_CHEMIN = 6.4 -- bord du tonneau à plus de 2 studs des pavés
local NOMBRE_LANTERNES = 4
local PREMIER_X, AXE_Z = 82, 8.5
local DIAMETRE_TONNEAU = 2.4
local COULEUR_LUMIERE = Color3.fromRGB(255, 170, 70)
local PORTEE_LUMIERE = 20
local INTENSITE_LUMIERE = 1.5
local SCINTILLEMENT = false

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local monde = ServerStorage:WaitForChild("Monde")
local Batiments = require(monde:WaitForChild("Batiments"))
local Lampadaires = require(monde:WaitForChild("Lampadaires"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local village = workspace:FindFirstChild("Carte") and workspace.Carte:FindFirstChild("Village")
if not village then warn("[LanternesCheminForge] Village introuvable") return end
if village:FindFirstChild("Chemin_TonneauxLanternes") then return end
local groupe = Instance.new("Model")
groupe.Name = "Chemin_TonneauxLanternes"
groupe.Parent = village

local rayons = RaycastParams.new()
rayons.RespectCanCollide = true
rayons.FilterType = Enum.RaycastFilterType.Exclude
rayons.FilterDescendantsInstances = {groupe}
for i = 1, NOMBRE_LANTERNES do
	local x = PREMIER_X + (i - 1) * ESPACEMENT
	local z = AXE_Z + (if i % 2 == 0 then DISTANCE_AXE_CHEMIN else -DISTANCE_AXE_CHEMIN)
	local impact = workspace:Raycast(Vector3.new(x, 9, z), Vector3.new(0, -20, 0), rayons)
	if not impact then warn("[LanternesCheminForge] Sol introuvable pour la lanterne " .. i) continue end
	local sol = Vector3.new(x, impact.Position.Y, z)
	local tonneau = Batiments.tonneau(groupe, CFrame.new(sol), DIAMETRE_TONNEAU)
	tonneau.Name = "TonneauLanterne_" .. i
	for _, piece in tonneau:GetDescendants() do
		if piece:IsA("BasePart") then
			piece.Anchored, piece.CanTouch = true, false
			piece.CanCollide = piece.Name == "Corps"
			piece.CanQuery = false
		end
	end
	-- Dessus du couvercle du tonneau : 3,26 ; dessous du socle : -0,55.
	local lanterne = Lampadaires.lanterne(tonneau, CFrame.new(sol + Vector3.yAxis * 3.81), COULEUR_LUMIERE, PORTEE_LUMIERE)
	lanterne.Name = "Lanterne"
	for _, objet in lanterne:GetDescendants() do
		if objet:IsA("BasePart") then
			objet.Anchored, objet.CanCollide, objet.CanTouch, objet.CanQuery = true, false, false, false
		elseif objet:IsA("PointLight") then
			objet.Color, objet.Range, objet.Brightness, objet.Shadows = COULEUR_LUMIERE, PORTEE_LUMIERE, INTENSITE_LUMIERE, false
			if not SCINTILLEMENT then CollectionService:RemoveTag(objet, "LueurLanterne") end
		end
	end
end
