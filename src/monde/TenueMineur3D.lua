local ServerStorage = game:GetService("ServerStorage")

local TenueMineur3D = {}
local NOM_MODELE = "MineurDuPicDore3D"

-- Pivots du mannequin exporté, relatifs au centre de UpperTorso et en axes Roblox.
local pivots = {
	Head = Vector3.new(0, 1.386, 0),
	UpperTorso = Vector3.zero,
	LowerTorso = Vector3.new(0, -1, 0),
	LeftUpperArm = Vector3.new(-1.5, 0.1687, 0),
	LeftLowerArm = Vector3.new(-1.5, -0.4241, 0),
	LeftHand = Vector3.new(-1.5, -1.05, 0),
	RightUpperArm = Vector3.new(1.5, 0.1687, 0),
	RightLowerArm = Vector3.new(1.5, -0.4241, 0),
	RightHand = Vector3.new(1.5, -1.05, 0),
	LeftUpperLeg = Vector3.new(-0.5, -1.6208, 0),
	LeftLowerLeg = Vector3.new(-0.5, -2.4009, 0),
	LeftFoot = Vector3.new(-0.5, -3.05, 0),
	RightUpperLeg = Vector3.new(0.5, -1.6208, 0),
	RightLowerLeg = Vector3.new(0.5, -2.4009, 0),
	RightFoot = Vector3.new(0.5, -3.05, 0),
}

local ancrages = {
	Head = "Head",
	UpperTorso = "UpperTorso",
	LowerTorso = "LowerTorso",
	LeftUpperArm = "LeftUpperArm",
	LeftLowerArm = "LeftLowerArm",
	RightUpperArm = "RightUpperArm",
	RightLowerArm = "RightLowerArm",
	["02_Visage"] = "Head",
	["02_Casque"] = "Head",
	["03_Lampe"] = "Head",
	["04_Torse_Lin"] = "UpperTorso",
	["04_Manche_LeftUpperArm"] = "LeftUpperArm",
	["04_Manche_LeftLowerArm"] = "LeftLowerArm",
	["04_Manche_RightUpperArm"] = "RightUpperArm",
	["04_Manche_RightLowerArm"] = "RightLowerArm",
	["05_Salopette"] = "UpperTorso",
	["05_Salopette_LowerTorso"] = "LowerTorso",
	["05_Jambe_LeftUpperLeg"] = "LeftUpperLeg",
	["05_Jambe_LeftLowerLeg"] = "LeftLowerLeg",
	["05_Jambe_RightUpperLeg"] = "RightUpperLeg",
	["05_Jambe_RightLowerLeg"] = "RightLowerLeg",
	["06_Ceinture"] = "LowerTorso",
	["07_Pioche"] = "LowerTorso",
	["08_Gant_G"] = "LeftHand",
	["08_Gant_D"] = "RightHand",
	["09_Botte_G"] = "LeftFoot",
	["09_Botte_D"] = "RightFoot",
}

local sourceConnue: Model? = nil
local modeleCalibre: Model? = nil
local repereCalibre: CFrame? = nil

local function indexer(modele: Model): { [string]: MeshPart }
	local pieces: { [string]: MeshPart } = {}
	for _, objet in modele:GetDescendants() do
		if objet:IsA("MeshPart") then
			pieces[objet.Name] = objet
		end
	end
	return pieces
end

local function calibrer(source: Model): (Model?, CFrame?)
	if source == sourceConnue then
		return modeleCalibre, repereCalibre
	end

	local pieces = indexer(source)
	for nom in ancrages do
		if not pieces[nom] then
			warn("[TenueMineur3D] MeshPart introuvable :", nom)
			return nil, nil
		end
	end
	local gauche, droite = pieces.LeftUpperArm, pieces.RightUpperArm
	local ecart = (droite.Position - gauche.Position).Magnitude
	if ecart < 0.001 then
		return nil, nil
	end

	-- L'Importateur peut changer l'échelle et les axes de la scène FBX.
	local copie = source:Clone()
	copie:ScaleTo(copie:GetScale() * 3 / ecart)
	pieces = indexer(copie)
	local x = (pieces.RightUpperArm.Position - pieces.LeftUpperArm.Position).Unit
	local y = (pieces.Head.Position - pieces.UpperTorso.Position).Unit
	local z = x:Cross(y)
	if z.Magnitude < 0.99 then
		copie:Destroy()
		return nil, nil
	end
	local repere = CFrame.fromMatrix(pieces.UpperTorso.Position, x, z.Unit:Cross(x), z.Unit)
	if modeleCalibre then
		modeleCalibre:Destroy()
	end
	sourceConnue, modeleCalibre, repereCalibre = source, copie, repere
	return copie, repere
end

function TenueMineur3D.appliquer(personnage: Model, parties: { [string]: BasePart }): Model?
	local source = ServerStorage:FindFirstChild(NOM_MODELE)
	if not source or not source:IsA("Model") then
		return nil
	end
	local patron, repere = calibrer(source)
	if not patron or not repere then
		return nil
	end
	for _, ancre in ancrages do
		if not parties[ancre] then
			return nil
		end
	end

	local tenue = Instance.new("Model")
	tenue.Name = "TenueMineur3D"
	local casque = Instance.new("Model")
	casque.Name = "CasqueMineur"
	casque:SetAttribute("CasqueDeBase", true)
	casque.Parent = tenue

	local pieces = indexer(patron)
	for nom, ancre in ancrages do
		local original = pieces[nom]
		local partie = parties[ancre]
		local mesh = original:Clone()
		-- Les SurfaceAppearance restent attachées au maillage d'origine.
		mesh.Anchored = false
		mesh.CanCollide = false
		mesh.CanTouch = false
		mesh.CanQuery = false
		mesh.Massless = true
		mesh.CFrame = partie.CFrame * CFrame.new(-pivots[ancre]) * repere:ToObjectSpace(original.CFrame)
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0 = partie
		soudure.Part1 = mesh
		soudure.Parent = mesh
		mesh.Parent = if nom == "02_Casque" or nom == "03_Lampe" then casque else tenue
	end
	for nom in pivots do
		local partie = parties[nom]
		partie.Transparency = 1
		for _, couche in partie:GetChildren() do
			if couche:IsA("Decal") then
				couche.Transparency = 1
			end
		end
	end
	tenue.Parent = personnage
	return casque
end

return TenueMineur3D
