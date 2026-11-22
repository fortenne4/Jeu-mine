-- Présentation décorative des modèles d'armure déjà présents dans le jeu.
-- Les deux rangées restent indépendantes du système d'inventaire et de la forge.
local ORIGINE = Vector3.new(51, 2, -37)
local ECART_MANNEQUINS = 5.5
local ECART_RANGEES = 10
local NOMBRE_PREMIERE_RANGEE = 6
local ECHELLE_SUPPORT = 1
local AFFICHER_PLAQUES = false
local COULEUR_BOIS = Color3.fromRGB(91, 58, 35)
local COULEUR_FER = Color3.fromRGB(48, 44, 42)
local COULEUR_LUMIERE = Color3.fromRGB(255, 177, 92)
local PORTEE_LUMIERE = 22
local INTENSITE_LUMIERE = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local monde = ServerStorage:WaitForChild("Monde")
local PorteArmure = require(monde:WaitForChild("PorteArmure"))
local Forge = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Forge"))
local ArmuresExposition = require(script.Parent:WaitForChild("ArmuresExposition"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do
	task.wait(0.25)
end
if not workspace:GetAttribute("MondeConstruit") then
	warn("[ExpositionArmures] Monde non construit : exposition non créée.")
	return
end
if workspace:FindFirstChild("PorteArmures") then
	warn("[ExpositionArmures] Une exposition existe déjà : aucune copie ajoutée.")
	return
end

local dossier = Instance.new("Folder")
dossier.Name = "PorteArmures"
dossier.Parent = workspace

local function plaque(modele: Model, cf: CFrame, nom: string)
	local p = Instance.new("Part")
	p.Name = "Plaque"
	p.Size = Vector3.new(3.4, 0.65, 0.15)
	p.CFrame = cf * CFrame.new(0, 0.9, -1.45)
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.Material, p.Color = Enum.Material.WoodPlanks, COULEUR_BOIS
	p.Parent = modele
	local interface = Instance.new("SurfaceGui")
	interface.Name, interface.Face = "TexteNom", Enum.NormalId.Front
	interface.Parent = p
	local texte = Instance.new("TextLabel")
	texte.Size, texte.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	texte.Font, texte.TextScaled, texte.TextWrapped = Enum.Font.Antique, true, true
	texte.TextColor3, texte.Text = Color3.fromRGB(248, 221, 158), nom
	texte.Parent = interface
end

local modeles = {{modele = "Casque", nom = "Armure de base", rarete = "Base", couleur = Color3.fromRGB(152, 158, 170)}}
for _, palier in Forge.ECHELLES.Casque do
	local minerai = Forge.MINERAIS[palier.dominant or palier.minerais[1]]
	table.insert(modeles, {modele = palier.modele, nom = palier.nom, rarete = palier.rarete, couleur = minerai and minerai.couleur or Color3.fromRGB(152, 158, 170)})
end

for index, entree in modeles do
	local rang = math.floor((index - 1) / NOMBRE_PREMIERE_RANGEE)
	local colonne = (index - 1) % NOMBRE_PREMIERE_RANGEE
	local position = ORIGINE + Vector3.new(colonne * ECART_MANNEQUINS, 0, -rang * ECART_RANGEES)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.pi, 0) -- face vers la forge et le village (+Z)
	local mannequin = PorteArmure.creer(dossier, cf, ECHELLE_SUPPORT, {Bois = COULEUR_BOIS, Fer = COULEUR_FER})
	mannequin.Name = "PorteArmure_" .. entree.modele
	mannequin:SetAttribute("ModeleArmure", entree.modele)
	mannequin:SetAttribute("NomArmure", entree.nom)
	mannequin:SetAttribute("Rarete", entree.rarete)
	local ok, erreur = ArmuresExposition.assembler(mannequin, cf, entree.modele, entree.couleur)
	if not ok then warn("[ExpositionArmures] " .. entree.modele .. " : " .. tostring(erreur)) end
	if AFFICHER_PLAQUES then plaque(mannequin, cf, entree.nom) end
end

-- Deux sources seulement pour l'ensemble, sans retoucher à l'éclairage global.
for _, colonne in {1, 4} do
	local ancrage = Instance.new("Part")
	ancrage.Name = "EclairageExposition"
	ancrage.Size = Vector3.one * 0.1
	ancrage.CFrame = CFrame.new(ORIGINE + Vector3.new(colonne * ECART_MANNEQUINS, 8, -ECART_RANGEES / 2))
	ancrage.Transparency, ancrage.Anchored = 1, true
	ancrage.CanCollide, ancrage.CanTouch, ancrage.CanQuery = false, false, false
	ancrage.Parent = dossier
	local lumiere = Instance.new("PointLight")
	lumiere.Name, lumiere.Color = "LumiereChaude", COULEUR_LUMIERE
	lumiere.Range, lumiere.Brightness = PORTEE_LUMIERE, INTENSITE_LUMIERE
	lumiere.Shadows = false
	lumiere.Parent = ancrage
end
