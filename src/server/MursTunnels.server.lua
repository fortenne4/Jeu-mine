-- Fonds en retrait derrière les six cadres générés dans la grande caverne.
local ServerStorage = game:GetService("ServerStorage")

local O = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Outils"))
local ROMAINS = { "I", "II", "III", "IV", "V", "VI" }
local JEU_CADRE = 0.02
local PROFONDEUR_COUCHE = 0.68

local function pierre(parent, cadre, nom, taille, position, gris, transparence)
	local piece =
		O.bloc(parent, taille, cadre * CFrame.new(position), Color3.fromRGB(gris, gris, gris), O.M.Ardoise, nom)
	piece.CanTouch = false
	piece.Transparency = transparence
end

local function anneau(parent, cadre, largeur, hauteur, bordX, bordY, profondeur, z, gris, transparence)
	local hauteurInterieure = hauteur - 2 * bordY
	for _, signe in { -1, 1 } do
		local bordHorizontal = if signe < 0 then "Bas" else "Haut"
		pierre(
			parent,
			cadre,
			bordHorizontal,
			Vector3.new(largeur, bordY, profondeur),
			Vector3.new(0, signe * (hauteur - bordY) / 2, z),
			gris,
			transparence
		)
		local bordVertical = if signe < 0 then "Gauche" else "Droite"
		pierre(
			parent,
			cadre,
			bordVertical,
			Vector3.new(bordX, hauteurInterieure, profondeur),
			Vector3.new(signe * (largeur - bordX) / 2, 0, z),
			gris,
			transparence
		)
	end
end

local function construire(dossier, porte, numero)
	local linteau = porte.Linteau
	local repere = linteau.CFrame
	local gauche, droite = -math.huge, math.huge
	local avant = math.huge
	for _, piece in porte:GetChildren() do
		if piece.Name == "Poteau" then
			local position = repere:PointToObjectSpace(piece.Position)
			if position.X < 0 then
				gauche = position.X + piece.Size.X / 2
			else
				droite = position.X - piece.Size.X / 2
			end
			avant = math.min(avant, position.Z - piece.Size.Z / 2)
		end
	end

	local sol = porte.SolPorte
	local bas = repere:PointToObjectSpace(sol.Position).Y + sol.Size.Y / 2
	local haut = -linteau.Size.Y / 2
	local largeur, hauteur = droite - gauche - 2 * JEU_CADRE, haut - bas - 2 * JEU_CADRE
	assert(largeur > 4 and hauteur > 5 and avant < math.huge, "Dimensions invalides pour " .. porte:GetFullName())
	local cadre = repere * CFrame.new((gauche + droite) / 2, (bas + haut) / 2, avant + 1)
	local mur = O.modele(dossier, "Mur_Tunnel_" .. numero)
	mur.WorldPivot = cadre

	local ombre = O.modele(mur, "OmbreInterieure")
	anneau(ombre, cadre, largeur, hauteur, 0.22, 0.22, 0.025, -0.025, 4, 0.45)

	-- Les couches de devant laissent voir celles du fond, même depuis le côté.
	local bordX, bordY = 0.55, 0.68
	for i, teinte in { 25, 15, 5 } do
		local couche = O.modele(mur, "Couche" .. i)
		anneau(
			couche,
			cadre,
			largeur,
			hauteur,
			bordX,
			bordY,
			PROFONDEUR_COUCHE,
			(i - 0.5) * PROFONDEUR_COUCHE,
			teinte,
			0
		)
		largeur -= 2 * bordX
		hauteur -= 2 * bordY
	end
	pierre(
		mur,
		cadre,
		"Fond",
		Vector3.new(largeur, hauteur, PROFONDEUR_COUCHE),
		Vector3.new(0, 0, 3.5 * PROFONDEUR_COUCHE),
		0,
		0
	)
end

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do
	task.wait(0.25)
end

local carte = workspace:FindFirstChild("Carte")
local mine = carte and carte:FindFirstChild("Mine")
local portes = mine and mine:FindFirstChild("PortesTunnels")
if portes and not workspace:FindFirstChild("MursTunnels") then
	local dossier = Instance.new("Folder")
	dossier.Name = "MursTunnels"
	for i, numero in ROMAINS do
		construire(dossier, portes["Porte" .. i], numero)
	end
	dossier.Parent = workspace
end
