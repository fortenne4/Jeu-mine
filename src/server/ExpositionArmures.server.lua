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
local RESERVE_ORIGINE = Vector3.new(4985, 0, 270)
local RESERVE_COLONNES = 6
local RESERVE_ECART = 6
local RESERVE_ECART_RANGEES = 11
local ENSEMBLES_FORGE = {
	CasqueDiamant = {rang = 1, minerai = "Diamant", precedent = "PorteArmure_Casque"},
	CasqueMagmaite = {rang = 2, minerai = "Magmaite", precedent = "PorteArmure_CasqueBronze"},
}

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
local dossier = workspace:FindFirstChild("PorteArmures")
local expositionExistante = dossier ~= nil
if not dossier then
	dossier = Instance.new("Folder")
	dossier.Name = "PorteArmures"
	dossier.Parent = workspace
end
local reserve = dossier:FindFirstChild("ReservePlaine")
if not reserve then
	reserve = Instance.new("Folder")
	reserve.Name = "ReservePlaine"
	reserve.Parent = dossier
end
local forge = workspace:FindFirstChild("Forge", true)
local anciens = {}
if forge and not expositionExistante then
	for _, objet in forge:GetChildren() do
		if objet:IsA("Model") and objet.Name == "Armure" and objet:FindFirstChild("Socle") then table.insert(anciens, objet) end
	end
end
table.sort(anciens, function(a, b) return a.Socle.Position.Z > b.Socle.Position.Z end)
local emplacements = {}
if #anciens == 2 then
	local sol = forge:FindFirstChild("Sol")
	for i, ancien in anciens do
		local socle = ancien.Socle
		local hauteur = if sol and sol:IsA("BasePart") then sol.Position.Y + sol.Size.Y / 2 else socle.Position.Y - socle.Size.Y / 2
		emplacements[i] = CFrame.new(socle.Position.X, hauteur, socle.Position.Z) * socle.CFrame.Rotation
	end
elseif not expositionExistante then
	warn("[ExpositionArmures] Nombre d'emplacements de forge inattendu : " .. #anciens)
end
local indexReserve = #reserve:GetChildren()
local function positionReserve()
	local colonne = indexReserve % RESERVE_COLONNES
	local rang = math.floor(indexReserve / RESERVE_COLONNES)
	indexReserve += 1
	return RESERVE_ORIGINE + Vector3.new(colonne * RESERVE_ECART, 0, rang * RESERVE_ECART_RANGEES)
end

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
local ArmuresVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("ArmuresVoxels"))
for _, palier in Forge.ECHELLES.Casque do
	if not ArmuresVoxels.existe(palier.modele) then continue end -- casque sans modèle 3D (ex. Heaume des marées) : pas exposé
	local minerai = Forge.MINERAIS[palier.dominant or palier.minerais[1]]
	table.insert(modeles, {modele = palier.modele, nom = palier.nom, rarete = palier.rarete, couleur = minerai and minerai.couleur or Color3.fromRGB(152, 158, 170)})
end

local function construireMannequin(cf, entree, minerai)
	local mannequin = PorteArmure.creer(nil, cf, ECHELLE_SUPPORT, {Bois = COULEUR_BOIS, Fer = COULEUR_FER})
	mannequin.Name = "PorteArmure_" .. entree.modele
	mannequin:SetAttribute("ModeleArmure", entree.modele)
	mannequin:SetAttribute("NomArmure", entree.nom)
	mannequin:SetAttribute("Rarete", entree.rarete)
	mannequin:SetAttribute("MineraiEnsemble", minerai)
	local ok, erreur = ArmuresExposition.assembler(mannequin, cf, entree.modele, entree.couleur, minerai)
	if not ok then warn("[ExpositionArmures] " .. entree.modele .. " : " .. tostring(erreur)) end
	if AFFICHER_PLAQUES then plaque(mannequin, cf, entree.nom) end
	return mannequin, ok
end

for _, entree in modeles do
	local ensemble = ENSEMBLES_FORGE[entree.modele]
	if expositionExistante then
		if not ensemble or dossier:FindFirstChild("PorteArmure_" .. entree.modele) then continue end
		local precedent = dossier:FindFirstChild(ensemble.precedent)
		if not precedent or not precedent:IsA("Model") then continue end
		local mannequin, ok = construireMannequin(precedent:GetPivot(), entree, ensemble.minerai)
		if not ok then
			mannequin:Destroy()
			continue
		end
		local enReserve = reserve:FindFirstChild(mannequin.Name)
		local pivot = if enReserve and enReserve:IsA("Model") then enReserve:GetPivot()
			else CFrame.new(positionReserve()) * CFrame.Angles(0, math.pi, 0)
		precedent:PivotTo(pivot)
		precedent.Parent = reserve
		if enReserve then enReserve:Destroy() end
		mannequin.Parent = dossier
	else
		local cf = ensemble and emplacements[ensemble.rang]
		if cf then
			local mannequin, ok = construireMannequin(cf, entree, ensemble.minerai)
			if ok then
				local ancien = anciens[ensemble.rang]
				local socle = ancien.Socle
				local base = socle.Position - Vector3.new(0, socle.Size.Y / 2, 0)
				ancien:PivotTo(ancien:GetPivot() + (positionReserve() - base))
				ancien.Name = "AncienneArmureForge_" .. ensemble.rang
				ancien.Parent = reserve
				mannequin.Parent = dossier
			else
				mannequin:Destroy()
			end
		else
			local mannequin = construireMannequin(CFrame.new(positionReserve()) * CFrame.Angles(0, math.pi, 0), entree)
			mannequin.Parent = reserve
		end
	end
end

if expositionExistante then return end -- conserve les éclairages existants

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
