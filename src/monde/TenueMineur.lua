-- Tenue de départ dessinée sur le rig R15, avec casque et mini-pioche soudés.
local TenueMineur3D = require(script.Parent.TenueMineur3D)

local TenueMineur = {}

local palette = {
	Peau = Color3.fromHex("C99167"),
	Yeux = Color3.fromHex("332928"),
	Sourcils = Color3.fromHex("593C2E"),
	Bouche = Color3.fromHex("694035"),
	Joue = Color3.fromHex("9D7359"),
	Lin = Color3.fromHex("A99573"),
	Col = Color3.fromHex("C2AC87"),
	Toile = Color3.fromHex("46545B"),
	Renfort = Color3.fromHex("4E5D65"),
	Cuir = Color3.fromHex("72503B"),
	Gant = Color3.fromHex("654A37"),
	Botte = Color3.fromHex("3B3430"),
	Embout = Color3.fromHex("555B5B"),
	Poussiere = Color3.fromHex("AA8E6C"),
	Ceinture = Color3.fromHex("51372B"),
	Ardoise = Color3.fromHex("2D3336"),
	Rebord = Color3.fromHex("41494C"),
	Laiton = Color3.fromHex("BA853E"),
	Lentille = Color3.fromHex("F3D48B"),
	Bois = Color3.fromHex("835B3C"),
	Fer = Color3.fromHex("717777"),
}

local couleurs = {
	Head = palette.Peau,
	UpperTorso = palette.Lin,
	LowerTorso = palette.Toile,
	LeftUpperArm = palette.Lin,
	RightUpperArm = palette.Lin,
	LeftLowerArm = palette.Lin,
	RightLowerArm = palette.Lin,
	LeftHand = palette.Gant,
	RightHand = palette.Gant,
	LeftUpperLeg = palette.Toile,
	RightUpperLeg = palette.Toile,
	LeftLowerLeg = palette.Toile,
	RightLowerLeg = palette.Toile,
	LeftFoot = palette.Botte,
	RightFoot = palette.Botte,
}

local AVANT, ARRIERE = Enum.NormalId.Front, Enum.NormalId.Back
local MAT = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal

-- Détails de toile peints sur les faces du rig, sans changer ses volumes ni sa physique.
local function dessin(partie: BasePart, face: Enum.NormalId): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Mineur" .. face.Name
	gui.Face = face
	gui.CanvasSize = Vector2.new(160, 160)
	gui.LightInfluence = 1
	gui.MaxDistance = 120
	gui.Parent = partie
	return gui
end

local function motif(
	dessinParent: SurfaceGui,
	couleur: Color3,
	x: number,
	y: number,
	largeur: number,
	hauteur: number,
	rotation: number?,
	arrondi: number?
)
	local cadre = Instance.new("Frame")
	cadre.AnchorPoint = Vector2.new(0.5, 0.5)
	cadre.Position = UDim2.fromScale(x, y)
	cadre.Size = UDim2.fromScale(largeur, hauteur)
	cadre.BackgroundColor3 = couleur
	cadre.BorderSizePixel = 0
	cadre.Rotation = rotation or 0
	cadre.Parent = dessinParent
	if arrondi then
		local coins = Instance.new("UICorner")
		coins.CornerRadius = UDim.new(arrondi, 0)
		coins.Parent = cadre
	end
end

local function visage(tete: BasePart)
	for _, objet in tete:GetChildren() do
		if objet:IsA("Decal") and objet.Name:lower() == "face" then
			objet:Destroy()
		end
	end
	local face = dessin(tete, AVANT)
	for _, cote in { -1, 1 } do
		local x = 0.5 + cote * 0.17
		motif(face, palette.Sourcils, x, 0.37, 0.115, 0.018, cote * 8)
		motif(face, palette.Yeux, x, 0.455, 0.053, 0.12, 0, 0.5)
		motif(face, Color3.fromHex("F5DDC9"), x - 0.007, 0.43, 0.014, 0.022, 0, 0.5)
		motif(face, palette.Joue, 0.5 + cote * 0.25, 0.61, 0.079, 0.039, cote * 12, 0.18)
		motif(face, palette.Bouche, 0.5 + cote * 0.087, 0.665, 0.049, 0.016, -cote * 17)
	end
	motif(face, palette.Bouche, 0.5, 0.672, 0.139, 0.017, 0, 0.3)
	motif(face, palette.Joue, 0.494, 0.532, 0.014, 0.064, 15, 0.3)
	motif(face, palette.Joue, 0.512, 0.562, 0.049, 0.013, -6, 0.3)
end

local function salopette(torse: BasePart)
	for _, normale in { AVANT, ARRIERE } do
		local avant = normale == AVANT
		local face = dessin(torse, normale)
		motif(face, palette.Toile, 0.5, 0.688, 0.66, 0.47, 0, 0.08)
		motif(face, palette.Renfort, 0.5, 0.659, 0.34, 0.20, 0, 0.08)
		motif(face, palette.Toile, 0.5, 0.589, 0.30, 0.015)
		for _, cote in { -1, 1 } do
			local x = 0.5 + cote * 0.273
			motif(face, palette.Cuir, x, 0.255, 0.102, 0.49, if avant then 0 else -cote * 12)
			motif(face, palette.Laiton, x, 0.49, 0.037, 0.046, 0, 0.5)
			if avant then
				motif(face, palette.Col, 0.5 + cote * 0.086, 0.08, 0.15, 0.098, cote * 25)
			end
		end
		motif(face, palette.Ceinture, 0.5, 0.944, 1, 0.111)
		if avant then
			motif(face, palette.Laiton, 0.5, 0.936, 0.17, 0.09, 0, 0.1)
			motif(face, palette.Ceinture, 0.5, 0.936, 0.109, 0.058, 0, 0.12)
			motif(face, palette.Laiton, 0.525, 0.936, 0.068, 0.017)
		end
	end
	for _, normale in { Enum.NormalId.Left, Enum.NormalId.Right } do
		motif(dessin(torse, normale), palette.Ceinture, 0.5, 0.944, 1, 0.111)
	end
end

local function manchesEtJambes(parties: { [string]: BasePart })
	for _, cote in { "Left", "Right" } do
		local gauche = cote == "Left"
		local manche = dessin(parties[cote .. "LowerArm"], AVANT)
		motif(manche, palette.Col, 0.5, 0.127, 0.77, 0.032)
		motif(manche, palette.Poussiere, if gauche then 0.65 else 0.32, 0.79, 0.098, 0.028, -27, 0.3)

		local genou = dessin(parties[cote .. "UpperLeg"], AVANT)
		motif(genou, palette.Renfort, 0.5, 0.7, 0.77, 0.43, 0, 0.08)
		motif(genou, palette.Toile, 0.5, 0.525, 0.65, 0.028)
		motif(genou, palette.Poussiere, if gauche then 0.27 else 0.7, 0.817, 0.036, 0.114, -11, 0.3)

		local jambe = dessin(parties[cote .. "LowerLeg"], AVANT)
		motif(jambe, palette.Renfort, if gauche then 0.78 else 0.22, 0.5, 0.024, 0.86)
		motif(jambe, palette.Poussiere, if gauche then 0.32 else 0.69, 0.62, 0.109, 0.043, 24, 0.2)
		motif(jambe, palette.Botte, 0.5, 0.93, 1, 0.14)

		local pied = dessin(parties[cote .. "Foot"], AVANT)
		motif(pied, palette.Embout, 0.5, 0.68, 0.96, 0.41, 0, 0.10)
	end
end

local function piece(
	parent: Instance,
	ancre: BasePart,
	nom: string,
	taille: Vector3,
	offset: CFrame,
	couleur: Color3,
	materiau: Enum.Material,
	forme: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = nom
	part.Size = taille
	part.CFrame = ancre.CFrame * offset
	part.Color = couleur
	part.Material = materiau
	part.Shape = forme or Enum.PartType.Block
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false

	local soudure = Instance.new("WeldConstraint")
	soudure.Part0 = ancre
	soudure.Part1 = part
	soudure.Parent = part
	part.Parent = parent
	return part
end

local function suivreVisibiliteCasque(personnage: Model, modele: Model)
	local function actualiserCasque()
		local transparence = if personnage:FindFirstChild("ArmureCasque") then 1 else 0
		for _, element in modele:GetChildren() do
			if element:IsA("BasePart") then
				element.Transparency = transparence
			end
		end
	end
	local function armureModifiee(element: Instance)
		if element.Name == "ArmureCasque" then
			actualiserCasque()
		end
	end
	personnage.ChildAdded:Connect(armureModifiee)
	personnage.ChildRemoved:Connect(armureModifiee)
	actualiserCasque()
end

-- Tenue 3D : une armure portée remplace la partie du skin qu'elle couvre. Les pièces du skin de cette zone
-- disparaissent et les segments du rig réapparaissent dessous, aux volumes pour lesquels l'armure est dessinée.
local ARMURES = { Casque = "ArmureCasque", Plastron = "ArmurePlastron", Jambieres = "ArmureJambieres" }
local NOMS_ARMURES = { ArmureCasque = true, ArmurePlastron = true, ArmureJambieres = true }
-- Les armures des minerais ont une pièce « Dessous » qui a déjà le volume du segment : le segment reste
-- alors caché, sinon les deux surfaces se superposent et la toile du rig traverse le cuir de l'armure.
local COUVERTS_PAR_DESSOUS = {
	Plastron = { UpperTorso = true },
	Jambieres = { LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true },
}

local function suivreArmures3D(personnage: Model, tenue: Model, parties: { [string]: BasePart })
	local pieces: { [string]: { { piece: BasePart, transparence: number } } } = {}
	for _, element in tenue:GetDescendants() do
		local zone = element:GetAttribute("ZoneArmure")
		if element:IsA("BasePart") and type(zone) == "string" then
			pieces[zone] = pieces[zone] or {}
			table.insert(pieces[zone], { piece = element, transparence = element.Transparency })
		end
	end

	local function actualiser()
		for zone, nomArmure in ARMURES do
			local armure = personnage:FindFirstChild(nomArmure)
			local portee = armure ~= nil
			local dessous = armure ~= nil and armure:FindFirstChild("Dessous", true) ~= nil
			for _, entree in pieces[zone] or {} do
				entree.piece.Transparency = if portee then 1 else entree.transparence
			end
			for _, nom in TenueMineur3D.PARTIES_ZONE[zone] do
				local partie = parties[nom]
				local couverts = COUVERTS_PAR_DESSOUS[zone]
				local visible = portee and not (dessous and couverts and couverts[nom])
				partie.Transparency = if visible then 0 else 1
				if visible then
					partie.Color = couleurs[nom]
				end
				for _, couche in partie:GetChildren() do
					if couche:IsA("Decal") then
						couche.Transparency = if visible then 0 else 1
					end
				end
			end
		end
	end
	local function armureModifiee(element: Instance)
		if NOMS_ARMURES[element.Name] then
			actualiser()
		end
	end
	personnage.ChildAdded:Connect(armureModifiee)
	personnage.ChildRemoved:Connect(armureModifiee)
	actualiser()
end

local function casque(personnage: Model, tete: BasePart)
	-- Le casque a plusieurs pièces. Un modèle soudé les conserve lors du chargement du personnage.
	local modele = Instance.new("Model")
	modele.Name = "CasqueMineur"
	modele:SetAttribute("CasqueDeBase", true)
	local largeur, hauteur, profondeur = tete.Size.X, tete.Size.Y, tete.Size.Z
	piece(
		modele,
		tete,
		"Coque",
		Vector3.new(largeur * 1.14, hauteur * 0.38, profondeur * 1.14),
		CFrame.new(0, hauteur * 0.346, 0),
		palette.Ardoise,
		MAT
	)
	local h = hauteur
	piece(
		modele,
		tete,
		"Couronne",
		Vector3.new(largeur * 0.99, h * 0.12, profondeur * 0.99),
		CFrame.new(0, h * 0.55, 0),
		palette.Rebord,
		MAT
	)
	piece(
		modele,
		tete,
		"Visiere",
		Vector3.new(largeur * 1.24, h * 0.075, profondeur * 1.24),
		CFrame.new(0, h * 0.14, -profondeur * 0.056),
		palette.Rebord,
		MAT
	)
	piece(
		modele,
		tete,
		"BoitierLampe",
		Vector3.new(0.38, 0.29, 0.116),
		CFrame.new(0, h * 0.35, -profondeur * 0.604),
		palette.Laiton,
		METAL
	)
	local axe = CFrame.new(0, h * 0.35, -profondeur * 0.664) * CFrame.Angles(0, math.pi / 2, 0)
	piece(
		modele,
		tete,
		"Cerclage",
		Vector3.new(0.079, 0.274, 0.274),
		axe,
		palette.Ardoise,
		METAL,
		Enum.PartType.Cylinder
	)
	piece(
		modele,
		tete,
		"Lentille",
		Vector3.new(0.042, 0.224, 0.224),
		axe * CFrame.new(0.046, 0, 0),
		palette.Lentille,
		MAT,
		Enum.PartType.Cylinder
	)
	for _, cote in { -1, 1 } do
		piece(
			modele,
			tete,
			"Rivet",
			Vector3.new(0.052, 0.08, 0.08),
			axe * CFrame.new(-0.067, -0.137, cote * 0.42),
			palette.Embout,
			METAL,
			Enum.PartType.Cylinder
		)
	end
	suivreVisibiliteCasque(personnage, modele)
	modele.Parent = personnage
end

local function outilDeHanche(personnage: Model, torse: BasePart)
	local outil = Instance.new("Model")
	outil.Name = "PiocheDecorativeMineur"
	local ancrage = torse:FindFirstChild("WaistCenterAttachment")
	local base = if ancrage and ancrage:IsA("Attachment") then ancrage.CFrame else CFrame.new(0, -0.2, 0)
	local axe = base
		* CFrame.new(-torse.Size.X * 0.43, 0.16, torse.Size.Z * 0.57)
		* CFrame.Angles(math.rad(17), 0, math.rad(-11))
	piece(
		outil,
		torse,
		"Manche",
		Vector3.new(0.1, 0.98, 0.11),
		axe * CFrame.new(0, -0.3, 0),
		palette.Bois,
		Enum.Material.Wood
	)
	piece(outil, torse, "Fer", Vector3.new(0.56, 0.11, 0.105), axe * CFrame.new(0, 0.21, 0), palette.Fer, METAL)
	piece(
		outil,
		torse,
		"PointeGauche",
		Vector3.new(0.17, 0.062, 0.09),
		axe * CFrame.new(-0.35, 0.179, 0) * CFrame.Angles(0, 0, math.rad(24)),
		palette.Fer,
		METAL
	)
	piece(
		outil,
		torse,
		"PointeDroite",
		Vector3.new(0.15, 0.07, 0.09),
		axe * CFrame.new(0.34, 0.185, 0) * CFrame.Angles(0, 0, math.rad(-20)),
		palette.Fer,
		METAL
	)
	piece(outil, torse, "Bride", Vector3.new(0.19, 0.12, 0.17), axe * CFrame.new(0, -0.04, 0), palette.Ceinture, MAT)
	outil.Parent = personnage
end

function TenueMineur.appliquer(personnage: Model): boolean
	if personnage:GetAttribute("TenueMineur") then
		return true
	end
	local humain = personnage:FindFirstChildOfClass("Humanoid")
	if not humain or humain.RigType ~= Enum.HumanoidRigType.R15 then
		return false
	end
	local parties: { [string]: BasePart } = {}
	for nom in couleurs do
		local partie = personnage:FindFirstChild(nom)
		if not partie or not partie:IsA("BasePart") then
			return false
		end
		parties[nom] = partie
	end

	local tenue3D = TenueMineur3D.appliquer(personnage, parties)
	if tenue3D then
		suivreArmures3D(personnage, tenue3D, parties)
	else
		for nom, couleur in couleurs do
			parties[nom].Color = couleur
		end
		visage(parties.Head)
		salopette(parties.UpperTorso)
		manchesEtJambes(parties)
		casque(personnage, parties.Head)
		outilDeHanche(personnage, parties.LowerTorso)
	end
	personnage:SetAttribute("TenueMineur", true)
	return true
end

return TenueMineur
