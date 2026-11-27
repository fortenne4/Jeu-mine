-- Clocher du Comptoir des minerais. Le repère est au sol, façade vers -Z.
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local M, C = O.M, O.C

local Clocher = {}
local VERSION = 1
local PIERRE = Color3.fromRGB(138, 127, 110)
local TAILLE = Color3.fromRGB(172, 158, 135)
local JOINT = Color3.fromRGB(92, 86, 79)
local ARDOISE = Color3.fromRGB(64, 72, 83)
local BRONZE = Color3.fromRGB(153, 102, 51)
local PATINE = Color3.fromRGB(65, 101, 89)
local LAITON = Color3.fromRGB(216, 172, 92)

local function bloc(parent, cf, nom, taille, couleur, mat, solide)
	local p = O.bloc(parent, taille, cf, couleur, mat, nom)
	return if solide then p else O.decor(p)
end

local function barre(parent, a, b, largeur, couleur, mat, nom)
	return bloc(
		parent,
		CFrame.lookAt((a + b) / 2, b),
		nom,
		Vector3.new(largeur, largeur, (b - a).Magnitude),
		couleur,
		mat
	)
end

local function arc(parent, face, rayon, naissance, z, largeur)
	for i = 0, 10 do
		local a = i * math.pi / 10
		local cf = face * CFrame.new(rayon * math.cos(a), naissance + rayon * math.sin(a), z) * CFrame.Angles(0, 0, a)
		local cle = i == 5
		bloc(
			parent,
			cf,
			if cle then "CleDeVoute" else "Voussoir",
			Vector3.new(if cle then largeur + 0.14 else largeur, rayon * 0.30, 0.65),
			if cle then TAILLE else PIERRE:Lerp(TAILLE, 0.45 + (i % 3) * 0.14),
			M.Calcaire
		)
	end
end

local function maconnerie(parent, cf, rng)
	bloc(parent, cf * CFrame.new(0, 1.1, 0), "Socle", Vector3.new(10, 2.2, 10), JOINT, M.Pierre, true)
	bloc(parent, cf * CFrame.new(0, 2.2, 0), "Soubassement", Vector3.new(9.8, 0.52, 9.8), TAILLE, M.Calcaire, true)
	bloc(parent, cf * CFrame.new(0, 12.1, 0), "Fut", Vector3.new(8.8, 19.8, 8.8), JOINT, M.Pierre, true)
	for cote = 0, 3 do
		local face = cf * CFrame.Angles(0, cote * math.pi / 2, 0)
		for rang = 0, 12 do
			local y = 3.06 + rang * 1.48
			local x = -3.88
			while x < 3.87 do
				local w = math.min(rng:NextNumber(1.45, 2.8), 3.88 - x)
				bloc(
					parent,
					face * CFrame.new(x + w / 2, y, -4.42 - rng:NextNumber(0, 0.055)),
					"Assise",
					Vector3.new(math.max(w - 0.045, 0.045), 1.43, 0.2),
					PIERRE:Lerp(TAILLE, rng:NextNumber(0.02, 0.38)),
					M.Pierre
				)
				x += w
			end
			local largeur = if (rang + cote) % 2 == 0 then 1.12 else 0.86
			bloc(
				parent,
				face * CFrame.new(-4.47 + largeur / 2, y, -4.45),
				"ChaineDAngle",
				Vector3.new(largeur, 1.43, 0.36),
				PIERRE:Lerp(TAILLE, 0.7),
				M.Calcaire
			)
		end
	end
	for _, bande in
		{
			{ 11.4, 9.12, 0.26 },
			{ 21.25, 9.5, 0.34 },
			{ 21.62, 10.1, 0.38 },
			{ 22, 9.72, 0.4 },
			{ 29.02, 9.38, 0.48 },
			{ 29.45, 9.86, 0.38 },
			{ 29.83, 10.32, 0.40 },
			{ 30.15, 10.55, 0.24 },
		}
	do
		bloc(
			parent,
			cf * CFrame.new(0, bande[1], 0),
			"Corniche",
			Vector3.new(bande[2], bande[3], bande[2]),
			TAILLE,
			M.Calcaire,
			true
		)
	end
end

local function facade(parent, cf, couleur)
	local naissance, rayon, pied = 6.4, 1.74, 2.43
	for i = -4, 4 do
		local x = i * 0.36
		local haut = naissance + math.sqrt(rayon ^ 2 - (math.abs(x) + 0.17) ^ 2)
		bloc(
			parent,
			cf * CFrame.new(x, (haut + pied) / 2, -4.61),
			"PlanchePorte",
			Vector3.new(0.35, haut - pied, 0.19),
			C.BoisFonce:Lerp(C.Bois, 0.2 + (i % 4) * 0.16),
			M.Planches
		)
	end
	for _, x in { -1.89, 1.89 } do
		for i = 0, 3 do
			bloc(
				parent,
				cf * CFrame.new(x, 2.9 + i, -4.62),
				"Jambage",
				Vector3.new(0.53, 0.97, 0.67),
				TAILLE,
				M.Calcaire
			)
		end
	end
	arc(parent, cf, 1.89, naissance, -4.63, 0.55)
	for _, y in { 3.45, 5.85 } do
		bloc(parent, cf * CFrame.new(0, y, -4.76), "Pentures", Vector3.new(3.02, 0.21, 0.12), C.Fer, M.Metal)
		for _, x in { -1.26, -0.82, 0.82, 1.26 } do
			bloc(parent, cf * CFrame.new(x, y, -4.84), "Rivet", Vector3.new(0.13, 0.13, 0.08), BRONZE, M.Metal)
		end
	end
	bloc(parent, cf * CFrame.new(0.62, 4.87, -4.83), "Serrure", Vector3.new(0.28, 0.5, 0.13), BRONZE, M.Metal)
	bloc(parent, cf * CFrame.new(0, 2.31, -4.89), "Seuil", Vector3.new(4.4, 0.36, 1.18), TAILLE, M.Calcaire, true)
	for _, x in { -3.15, 3.15 } do
		B.applique(parent, cf * CFrame.new(x, 5.25, -4.49))
	end

	-- Bannière du comptoir sur un axe de bois et des pattes de fer.
	local drap = cf * CFrame.new(0, 14.3, -4.64)
	bloc(parent, drap * CFrame.new(0, 1.68, 0), "Tringle", Vector3.new(3.66, 0.17, 0.21), C.BoisFonce, M.Bois)
	bloc(parent, drap, "Banniere", Vector3.new(2.88, 3.3, 0.13), couleur, M.Tissu)
	for _, x in { -1.32, 1.32 } do
		bloc(parent, drap * CFrame.new(x, 0, -0.073), "Galon", Vector3.new(0.12, 3.13, 0.04), LAITON, M.Tissu)
	end
	bloc(parent, drap * CFrame.new(0, -1.5, -0.073), "Galon", Vector3.new(2.7, 0.14, 0.04), LAITON, M.Tissu)
	bloc(
		parent,
		drap * CFrame.new(0, 0.2, -0.092) * CFrame.Angles(0, 0, math.pi / 4),
		"Embleme",
		Vector3.new(0.91, 0.91, 0.07),
		LAITON,
		M.Metal
	)

	-- Oeil-de-boeuf à ferronnerie radiale, avec une lueur en retrait.
	local rosace = cf * CFrame.new(0, 18.63, -4.62)
	local function disque(epaisseur, diametre, z, teinte, mat, nom)
		return O.decor(
			O.disque(
				parent,
				epaisseur,
				diametre,
				rosace * CFrame.new(0, 0, z) * CFrame.Angles(0, math.pi / 2, 0),
				teinte,
				mat,
				nom
			)
		)
	end
	disque(0.48, 3.52, 0, TAILLE, M.Calcaire, "EncadrementRosace")
	disque(0.11, 2.78, -0.245, C.BoisFonce, M.Metal, "CadreRosace")
	disque(0.10, 2.36, -0.301, Color3.fromRGB(177, 114, 59), M.Verre, "Rosace")
	for i = 0, 7 do
		local fleuron = rosace * CFrame.Angles(0, 0, i * math.pi / 4) * CFrame.new(0, 0.68, -0.37)
		bloc(parent, fleuron, "RosaceFer", Vector3.new(0.11, 1.08, 0.09), C.Fer, M.Metal)
	end
	disque(0.14, 0.45, -0.405, LAITON, M.Metal, "CoeurRosace")
end

local function chambre(parent, cf)
	local naissance, rayon, haut = 26.03, 2.15, 28.98
	for cote = 0, 3 do
		local face = cf * CFrame.Angles(0, cote * math.pi / 2, 0)
		for _, s in { -1, 1 } do
			bloc(
				parent,
				face * CFrame.new(s * 3.4, 25.45, -4.05),
				"Pilier",
				Vector3.new(2.25, 6.9, 0.94),
				PIERRE,
				M.Pierre,
				true
			)
			for i = 0, 3 do
				bloc(
					parent,
					face * CFrame.new(s * 2.25, 22.7 + i * 0.97, -4.53),
					"Jambage",
					Vector3.new(0.52, 0.9, 0.59),
					TAILLE,
					M.Calcaire
				)
			end
		end
		local largeur = 2 * rayon / 12
		for i = 0, 11 do
			local x = (i - 5.5) * largeur
			local bord = math.abs(x) + largeur / 2
			local bas = naissance + math.sqrt(math.max(rayon ^ 2 - bord ^ 2, 0))
			bloc(
				parent,
				face * CFrame.new(x, (haut + bas) / 2, -4.05),
				"Ecoincon",
				Vector3.new(largeur + 0.025, haut - bas, 0.94),
				PIERRE,
				M.Pierre,
				true
			)
		end
		arc(parent, face, rayon + 0.09, naissance, -4.55, 0.62)
		bloc(parent, face * CFrame.new(0, 22.33, -4.24), "Appui", Vector3.new(4.77, 0.3, 1.52), TAILLE, M.Calcaire)
		for i = -3, 3 do
			bloc(
				parent,
				face * CFrame.new(i * 0.56, 22.64, -4.4),
				"Balustre",
				Vector3.new(0.12, 0.62, 0.16),
				C.Fer,
				M.Metal
			)
		end
		bloc(parent, face * CFrame.new(0, 22.96, -4.4), "MainCourante", Vector3.new(4.18, 0.10, 0.19), C.Fer, M.Metal)
	end

	local cloche = O.modele(parent, "Cloche")
	bloc(cloche, cf * CFrame.new(0, 27.52, 0), "Joug", Vector3.new(8.22, 0.72, 0.77), C.BoisFonce, M.Bois, true)
	for _, x in { -3.5, 3.5 } do
		bloc(cloche, cf * CFrame.new(x, 27.52, 0), "FerrureJoug", Vector3.new(0.27, 0.8, 0.84), C.Fer, M.Metal)
	end
	O.decor(O.cylindre(cloche, 0.72, 0.54, cf * CFrame.new(0, 27.06, 0), BRONZE, M.Metal, "CouronneCloche"))
	local profil =
		{ { 23.5, 1.68 }, { 23.73, 1.69 }, { 24.14, 1.35 }, { 25.20, 1.02 }, { 26.23, 0.78 }, { 26.74, 0.48 } }
	local facettes = 16
	for i = 1, #profil - 1 do
		local y0, r0 = table.unpack(profil[i])
		local y1, r1 = table.unpack(profil[i + 1])
		for k = 0, facettes - 1 do
			local a = k * 2 * math.pi / facettes
			local radial = Vector3.new(math.cos(a), 0, math.sin(a))
			local tangent = Vector3.yAxis:Cross(radial)
			local milieu = radial * ((r0 + r1) / 2 * math.cos(math.pi / facettes)) + Vector3.yAxis * ((y0 + y1) / 2)
			local vertical = (Vector3.yAxis * (y1 - y0) + radial * (r1 - r0) * math.cos(math.pi / facettes)).Unit
			bloc(
				cloche,
				cf * CFrame.fromMatrix(milieu, tangent, vertical),
				"BronzeCloche",
				Vector3.new(
					2 * r0 * math.sin(math.pi / facettes) + 0.017,
					Vector2.new(y1 - y0, r1 - r0).Magnitude + 0.04,
					0.13
				),
				if i == 1 then LAITON else BRONZE:Lerp(PATINE, (k % 5) * 0.06),
				M.Metal
			)
		end
	end
	O.decor(O.cylindre(cloche, 2.64, 0.14, cf * CFrame.new(0, 24.56, 0), C.Fer, M.Metal, "TigeBattant"))
	O.decor(
		O.ellipsoide(cloche, Vector3.new(0.48, 0.58, 0.48), cf * CFrame.new(0, 23.25, 0), C.Fer, M.Metal, "Battant")
	)
	local source = bloc(cloche, cf * CFrame.new(0, 26.4, -1.75), "LueurChambre", Vector3.one * 0.1, LAITON, M.Lisse)
	source.Transparency = 1
	O.lumiere(source, Color3.fromRGB(255, 191, 126), 1.6, 13, true)
end

local function toiture(parent, cf, rng)
	local demi, y, h = 5.43, 30.26, 11.4
	local longueur = Vector2.new(demi, h).Magnitude
	local montee = Vector3.new(0, h, demi).Unit
	local normale = montee:Cross(Vector3.xAxis)
	for cote = 0, 3 do
		local face = cf * CFrame.Angles(0, cote * math.pi / 2, 0)
		local egout = Vector3.new(0, y, -demi)
		for _, s in { -1, 1 } do
			local p = egout + Vector3.xAxis * (s * demi / 2) + montee * (longueur / 2)
			local pan = face * CFrame.fromMatrix(p, normale * -s, montee, Vector3.xAxis * -s)
			O.coin(parent, Vector3.new(0.38, longueur, demi), pan, ARDOISE, M.Ardoise, "Toit")
		end
		local pas = longueur / 14
		for rang = 0, 13 do
			local d = (rang + 0.48) * pas
			local demiL = demi * (1 - math.min(d + pas * 0.38, longueur) / longueur)
			local nb = math.max(1, math.ceil(2 * demiL / 1.08))
			local w = 2 * demiL / nb
			for k = 1, nb do
				local p = egout + montee * d + normale * 0.22 + Vector3.xAxis * ((k - 0.5) * w - demiL)
				bloc(
					parent,
					face * CFrame.fromMatrix(p, Vector3.xAxis, normale, montee),
					"Ardoise",
					Vector3.new(w - 0.028, 0.14, pas * 1.11),
					ARDOISE:Lerp(Color3.fromRGB(112, 124, 133), rng:NextNumber(0.03, 0.47)),
					M.Ardoise
				)
			end
		end
		barre(
			parent,
			face * Vector3.new(demi, y, -demi),
			cf * Vector3.new(0, y + h, 0),
			0.23,
			PATINE,
			M.Metal,
			"Arêtier"
		)
		local gouttiere = bloc(
			parent,
			face * CFrame.new(0, y - 0.12, -demi),
			"Larmier",
			Vector3.new(2 * demi, 0.19, 0.22),
			PATINE,
			M.Metal
		)
		gouttiere.CastShadow = false
	end
	local fleche = cf * CFrame.new(0, y + h, 0)
	O.decor(O.cylindre(parent, 2.75, 0.15, fleche * CFrame.new(0, 1.16, 0), BRONZE, M.Metal, "Fleche"))
	O.decor(O.ellipsoide(parent, Vector3.one * 0.53, fleche * CFrame.new(0, 0.53, 0), LAITON, M.Metal, "Boule"))
	bloc(parent, fleche * CFrame.new(0, 2, 0), "Girouette", Vector3.new(2.72, 0.12, 0.14), BRONZE, M.Metal)
	bloc(
		parent,
		fleche * CFrame.new(1.08, 2, 0) * CFrame.Angles(0, 0, math.pi / 4),
		"PointeGirouette",
		Vector3.new(0.51, 0.51, 0.15),
		LAITON,
		M.Metal
	)
	bloc(parent, fleche * CFrame.new(-0.94, 2.28, 0), "QueueGirouette", Vector3.new(0.65, 0.56, 0.12), PATINE, M.Metal)
end

function Clocher.construire(parent, cf, couleur)
	local t = O.modele(nil, "TourComptoir")
	t.WorldPivot = cf
	t:SetAttribute("VersionClocher", VERSION)
	local rng = Random.new(407)
	maconnerie(t, cf, rng)
	facade(t, cf, couleur)
	chambre(t, cf)
	toiture(t, cf, rng)
	t.Parent = parent
	return t
end

function Clocher.preparer(village)
	local ancien = village:FindFirstChild("TourComptoir", true)
	if not ancien or not ancien:IsA("Model") or ancien:GetAttribute("VersionClocher") == VERSION then
		return
	end
	local socle = ancien:FindFirstChild("Socle")
	if not socle or not socle:IsA("BasePart") then
		return
	end
	local banniere = ancien:FindFirstChild("Banniere")
	local couleur = if banniere and banniere:IsA("BasePart") then banniere.Color else Color3.fromRGB(150, 58, 46)
	Clocher.construire(ancien.Parent, socle.CFrame * CFrame.new(0, -socle.Size.Y / 2, 0), couleur)
	ancien:Destroy()
end

return Clocher
