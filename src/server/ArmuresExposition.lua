-- Présentation décorative des vrais modèles d'équipement de la forge.
-- Repère commun au porte-armure : origine au centre de la base, avant = -Z.
local HAUTEUR_CASQUE = 5.72
local HAUTEUR_PLASTRON = 3.8
local HAUTEUR_JAMBIERES = 1.5
local ECHELLE_ARMURE = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local ArmuresVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("ArmuresVoxels"))

local Exposition = {}
local disponibiliteMesh = {}

-- Les meshes importés par un autre compte peuvent exister dans Studio sans pouvoir
-- être affichés. Dans ce cas on réutilise le modèle lisse déjà fourni par le jeu.
local function meshIndisponible(id: string): boolean
	if disponibiliteMesh[id] ~= nil then return not disponibiliteMesh[id] end
	local dossier = ReplicatedStorage:FindFirstChild("CasquesMesh")
	local source = dossier and dossier:FindFirstChild(id)
	if not source then return false end -- le constructeur choisira son repli habituel
	local assets = {}
	for _, objet in source:GetDescendants() do
		if objet:IsA("MeshPart") and objet.Name ~= "Racine" and objet.MeshId ~= "" then
			table.insert(assets, objet)
		end
	end
	local reussi, echec, verifies = true, false, 0
	if #assets > 0 then
		reussi = pcall(function()
			ContentProvider:PreloadAsync(assets, function(_, statut)
				verifies += 1
				if statut ~= Enum.AssetFetchStatus.Success then echec = true end
			end)
		end)
	end
	local disponible = #assets > 0 and reussi and not echec and verifies > 0
	disponibiliteMesh[id] = disponible
	return not disponible
end

local function nettoyer(modele: Model)
	for _, objet in modele:GetDescendants() do
		if objet:IsA("BasePart") then
			objet.Anchored = true
			objet.CanCollide, objet.CanTouch, objet.CanQuery = false, false, false
		elseif objet:IsA("BaseScript") or objet:IsA("ModuleScript") or objet:IsA("ProximityPrompt")
			or objet:IsA("Humanoid") or objet:IsA("Tool") or objet:IsA("Light")
			or objet:IsA("ParticleEmitter") or objet:IsA("Trail") or objet:IsA("Beam")
			or objet:IsA("JointInstance") or objet:IsA("WeldConstraint") then
			objet:Destroy()
		end
	end
end

-- Un ensemble de minerai utilise au complet les mêmes modèles que l'équipement du joueur.
function Exposition.assembler(mannequin: Model, cadreBase: CFrame, id: string, couleur: Color3?, minerai: string?): (boolean, {string})
	local erreurs = {}
	local suffixe = minerai or ""
	for _, piece in {
		{id = id, hauteur = HAUTEUR_CASQUE},
		{id = "Plastron" .. suffixe, hauteur = HAUTEUR_PLASTRON},
		{id = "Jambieres" .. suffixe, hauteur = HAUTEUR_JAMBIERES},
	} do
		if not ArmuresVoxels.existe(piece.id) then
			table.insert(erreurs, "Modèle absent : " .. piece.id)
			continue
		end
		local repliLisse = piece.id == id and meshIndisponible(id)
		local ok, modele = pcall(ArmuresVoxels.construire, piece.id, couleur, nil, repliLisse)
		if not ok or not (typeof(modele) == "Instance" and modele:IsA("Model")) then
			table.insert(erreurs, "Construction impossible : " .. piece.id .. " (" .. tostring(modele) .. ")")
			continue
		end
		if ECHELLE_ARMURE ~= 1 then modele:ScaleTo(modele:GetScale() * ECHELLE_ARMURE) end
		if repliLisse then mannequin:SetAttribute("CasqueRepliLisse", true) end
		nettoyer(modele)
		modele:PivotTo(cadreBase * CFrame.new(0, piece.hauteur, 0))
		modele.Parent = mannequin
	end
	return #erreurs == 0, erreurs
end

return Exposition
