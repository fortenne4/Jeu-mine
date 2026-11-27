-- La Grande Mine : gare du village, voie ferrée, portail dans la falaise, tunnel étayé,
-- descente vers la grande caverne de cristal et les portes des tunnels privés.
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local Cercle = require(script.Parent.CercleLumineux)
local M3 = require(script.Parent.Modeles3D)
local CaverneDecor = require(script.Parent.CaverneDecor)
local M, C = O.M, O.C

local Mine = {}
local terrain = workspace.Terrain

local ROMAINS = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII"}

local function vers(pos, cible)
	return CFrame.lookAt(pos, Vector3.new(cible.X, pos.Y, cible.Z))
end

-- Un tronçon de voie droit entre deux points du sol (fonctionne aussi en pente)
local function troncon(parent, a, b)
	local L = (b - a).Magnitude
	local base = CFrame.lookAt(a, b)
	local m = O.modele(parent, "Troncon")
	O.bloc(m, Vector3.new(9, 0.2, L), base * CFrame.new(0, 0.1, -L / 2), Color3.fromRGB(117, 91, 64), M.Terre, "Ballast")
	for _, x in {-2.5, 2.5} do
		O.decor(O.bloc(m, Vector3.new(0.35, 0.45, L), base * CFrame.new(x, 0.75, -L / 2), Color3.fromRGB(87, 68, 54), M.Rouille, "Rail"))
		O.decor(O.bloc(m, Vector3.new(0.12, 0.04, L), base * CFrame.new(x, 0.995, -L / 2), Color3.fromRGB(119, 112, 100), M.Metal, "RefletRail"))
	end
	local n = math.floor(L / 3)
	for i = 0, n do
		local couleur = if i % 3 == 0 then Color3.fromRGB(78, 50, 33) else Color3.fromRGB(68, 45, 31)
		O.decor(O.bloc(m, Vector3.new(7.4, 0.5, 1.1), base * CFrame.new(0, 0.25, -i * L / n), couleur, M.Planches, "Traverse"))
		for _, x in {-2.5, 2.5} do
			O.decor(O.bloc(m, Vector3.new(0.7, 0.12, 0.65), base * CFrame.new(x, 0.56, -i * L / n), Color3.fromRGB(86, 65, 49), M.Rouille, "Fixation"))
		end
	end
	return m
end

-- Cadre de soutènement en bois (base au sol, au centre du tunnel)
local function cadre(parent, base, largeur, hauteur, e)
	for _, s in {-1, 1} do
		O.bloc(parent, Vector3.new(e, hauteur, e), base * CFrame.new(s * largeur / 2, hauteur / 2, 0), C.Bois, M.Bois, "Poteau")
		O.decor(O.bloc(parent, Vector3.new(e * 0.7, 5, e * 0.7), base * CFrame.new(s * (largeur / 2 - 2), hauteur - 1.8, 0) * CFrame.Angles(0, 0, s * math.rad(45)),
			C.Bois, M.Bois, "JambeDeForce"))
	end
	O.bloc(parent, Vector3.new(largeur + e, e * 1.2, e * 1.2), base * CFrame.new(0, hauteur + e * 0.6, 0), C.BoisFonce, M.Bois, "Chapeau")
end

-- ================= Gare du village =================

local function poserToitGare(gare, repere, taille)
	local toiture = O.modele(nil, "ToitureGare")
	local demiLargeur, demiLongueur = taille.X / 2, taille.Z / 2
	local hauteur = 6.4
	local pente = math.atan(hauteur / demiLargeur)
	local rampant = Vector2.new(demiLargeur, hauteur).Magnitude
	for _, cote in {-1, 1} do
		local pan = O.bloc(toiture, Vector3.new(rampant + 0.035, 0.65, taille.Z),
			repere * CFrame.new(cote * demiLargeur / 2, hauteur / 2, 0) * CFrame.Angles(0, 0, -cote * pente),
			C.Toit, M.Tuiles, "Pan")
		pan:SetAttribute("ToitRebond", true)
		O.decor(O.bloc(toiture, Vector3.new(0.29, 0.55, taille.Z),
			repere * CFrame.new(cote * demiLargeur, -0.18, 0), C.BoisFonce, M.Bois, "Bandeau"))
		-- La sablière prolonge la poutre existante jusqu'au dessous du pan.
		O.decor(O.bloc(toiture, Vector3.new(1.2, 1.66, taille.Z - 3),
			repere * CFrame.new(cote * 8, 0.45, 0), C.BoisFonce, M.Bois, "Sabliere"))
	end
	O.decor(O.bloc(toiture, Vector3.new(0.78, 0.38, taille.Z + 0.18), repere * CFrame.new(0, hauteur + 0.32, 0),
		C.Toit:Lerp(C.PierreFoncee, 0.38), M.Tuiles, "Faitage"))

	local zPignon = demiLongueur - 1.65
	for _, bout in {-1, 1} do
		for _, cote in {-1, 1} do
			local base = CFrame.fromMatrix(Vector3.new(cote * demiLargeur / 2, hauteur / 2 - 0.31, bout * zPignon),
				Vector3.zAxis * cote, Vector3.yAxis, -Vector3.xAxis * cote)
			O.decor(O.coin(toiture, Vector3.new(0.42, hauteur, demiLargeur), repere * base,
				C.Bois, M.Planches, "Pignon"))
			local rive = repere * CFrame.new(cote * demiLargeur / 2, hauteur / 2 - 0.1, bout * demiLongueur)
				* CFrame.Angles(0, 0, -cote * pente)
			O.decor(O.bloc(toiture, Vector3.new(rampant, 0.48, 0.25), rive, C.BoisFonce, M.Bois, "Rive"))
		end
		O.decor(O.bloc(toiture, Vector3.new(0.4, hauteur, 0.18),
			repere * CFrame.new(0, hauteur / 2 - 0.32, bout * (zPignon + 0.245)),
			C.BoisFonce, M.Bois, "PoinconPignon"))
	end
	for _, z in {-19, 0, 19} do
		O.decor(O.bloc(toiture, Vector3.new(17.2, 0.72, 0.84),
			repere * CFrame.new(0, 0.04, z), C.BoisFonce, M.Bois, "Entrait"))
		O.decor(O.bloc(toiture, Vector3.new(0.52, hauteur - 0.72, 0.59),
			repere * CFrame.new(0, hauteur / 2 - 0.02, z), C.Bois, M.Bois, "Poincon"))
	end

	local enseigne = gare:FindFirstChild("Enseigne")
	if enseigne and enseigne:IsA("BasePart") then
		-- La même enseigne est suspendue sous le pignon, à hauteur lisible depuis l'avenue.
		enseigne.CFrame = repere * CFrame.new(0, -0.72, zPignon + 0.62)
		for _, x in {-5.85, 5.85} do
			O.decor(O.bloc(toiture, Vector3.new(0.22, 1.14, 0.8),
				repere * CFrame.new(x, 0.42, zPignon + 0.28), C.Fer, M.Metal, "SuspenteEnseigne"))
		end
	end
	toiture.Parent = gare
end

-- Cartes figées : retire l'ancien guichet et l'ancien levier de départ (le départ est automatique).
local function nettoyerGare(m)
	local g = vers(Vector3.new(14, 0, -114), Vector3.new(0, 0, -114))
	local anciennesPieces = {
		Socle = g * CFrame.new(0, 0.5, 0),
		Cabane = g * CFrame.new(0, 4.5, 0.3),
		Guichet = g * CFrame.new(0, 5, -2.25),
		Fronton = g * CFrame.new(0, 7.2, -2.55),
	}
	for _, piece in m:GetChildren() do
		if piece:IsA("BasePart") then
			local ancien = anciennesPieces[piece.Name]
			local toitGuichet = piece.Name == "Toit" and (piece.Position - Vector3.new(14, 9.2, -114)).Magnitude < 5
			if (ancien and (piece.Position - ancien.Position).Magnitude < 0.2) or toitGuichet then piece:Destroy() end
		end
	end
	local levier = m:FindFirstChild("LevierDepart")
	if levier then levier:Destroy() end
	local ancienToit = m:FindFirstChild("Toit")
	if not m:FindFirstChild("ToitureGare") and ancienToit and ancienToit:IsA("BasePart") then
		poserToitGare(m, ancienToit.CFrame, ancienToit.Size)
		ancienToit:Destroy()
	end
end

-- Wagon du retour posé au terminus, tourné vers la gare ; remplace l'ancien levier sur les cartes figées.
-- Quai souterrain : le sol de roche de la caverne arrive à la hauteur des planches et les traverse en
-- scintillant. On surélève le quai et sa rampe de 0.3 et on creuse la roche à l'intérieur de leur volume.
-- Positions absolues : sans effet si on le refait.
local QUAI_SOUTERRAIN = {
	Quai = CFrame.new(-12.2, D.CAVERNE_SOL + 1.3, -390),
	Rampe = CFrame.new(-12.2, D.CAVERNE_SOL + 1.3, -408),
}
local function degagerQuai(caverne)
	for nom, cf in QUAI_SOUTERRAIN do
		local piece = caverne:FindFirstChild(nom)
		if piece and piece:IsA("BasePart") then
			piece.CFrame = cf * piece.CFrame.Rotation
			if piece:IsA("WedgePart") then
				terrain:FillWedge(piece.CFrame, piece.Size, Enum.Material.Air)
			else
				terrain:FillBlock(piece.CFrame, piece.Size, Enum.Material.Air)
			end
		end
	end
end

local function preparerWagonRetour(caverne)
	local levier = caverne:FindFirstChild("LevierRetour")
	if levier then levier:Destroy() end
	for _, objet in caverne:GetChildren() do
		if objet:GetAttribute("WagonRetour") then return end
	end
	local wagon = B.wagonnet(caverne, CFrame.new(D.QUAI_BAS + Vector3.new(0, 2, 4)) * CFrame.Angles(0, math.pi, 0))
	wagon:SetAttribute("WagonRetour", true)
end

local function gare(f, rng)
	local m = O.modele(f, "Gare")
	local zc, x0 = -123, -14.5

	O.bloc(m, Vector3.new(19, 2.2, 46), CFrame.new(x0, 1.1, zc), C.Bois, M.Planches, "Quai")
	O.bloc(m, Vector3.new(0.8, 2.3, 46), CFrame.new(-5.2, 1.15, zc), C.PierreFoncee, M.Pierre, "Bordure")
	O.coin(m, Vector3.new(19, 2.2, 6), CFrame.new(x0, 1.1, -97) * CFrame.Angles(0, math.pi, 0), C.Bois, M.Planches, "Rampe")
	for _, x in {-6.5, -22.5} do
		for _, z in {-104, -123, -142} do
			O.bloc(m, Vector3.new(1, 10.8, 1), CFrame.new(x, 7.6, z), C.BoisFonce, M.Bois, "Poteau")
		end
		O.bloc(m, Vector3.new(1.2, 1.2, 46), CFrame.new(x, 13, zc), C.BoisFonce, M.Bois, "Poutre")
	end
	local enseigne = O.bloc(m, Vector3.new(17, 3, 0.5), CFrame.new(x0, 15.8, -100.2), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(enseigne, Enum.NormalId.Back, "GARE DE LA GRANDE MINE")
	poserToitGare(m, CFrame.new(x0, 13.95, zc), Vector3.new(21, 0.7, 49))

	for i, z in {-112, -134} do
		B.bancJardinieres(m, CFrame.new(-18, 2.2, z) * CFrame.Angles(0, -math.pi / 2, 0), 10 + i)
	end
	-- Balustrades en bois : bord arrière du quai (côté forêt) et bord avant, de part et
	-- d'autre de l'arrivée du chemin (ouverture de x = -20,2 à -11,2, alignée sur le chemin : Village.preparerCheminMoulin)
	local yQuai = 2.2
	local function balustrade(a, b)
		local longueur = (b - a).Magnitude
		local repere = CFrame.lookAt(a, b) -- axe -Z local le long de la balustrade
		local poteaux = math.max(1, math.ceil(longueur / 3.4))
		for i = 0, poteaux do
			local d = longueur * i / poteaux
			O.bloc(m, Vector3.new(0.5, 3.1, 0.5), repere * CFrame.new(0, 1.55, -d), C.BoisFonce, M.Bois, "PoteauBalustrade")
			O.decor(O.bloc(m, Vector3.new(0.65, 0.25, 0.65), repere * CFrame.new(0, 3.2, -d), C.BoisFonce, M.Bois, "ChapeauBalustrade"))
			if i < poteaux then
				for k = 1, 3 do
					O.decor(O.bloc(m, Vector3.new(0.22, 2.3, 0.22), repere * CFrame.new(0, 1.35, -(d + longueur / poteaux * k / 4)), C.Bois, M.Bois, "Barreau"))
				end
			end
		end
		O.bloc(m, Vector3.new(0.45, 0.35, longueur + 0.5), repere * CFrame.new(0, 2.9, -longueur / 2), C.Bois, M.Planches, "MainCourante")
		O.decor(O.bloc(m, Vector3.new(0.3, 0.25, longueur), repere * CFrame.new(0, 0.35, -longueur / 2), C.Bois, M.Bois, "Lisse"))
	end
	balustrade(Vector3.new(-23.55, yQuai, -145.6), Vector3.new(-23.55, yQuai, -100.4))
	balustrade(Vector3.new(-23.55, yQuai, -100.35), Vector3.new(-20.2, yQuai, -100.35))
	balustrade(Vector3.new(-11.2, yQuai, -100.35), Vector3.new(-6.1, yQuai, -100.35))

	-- Jardinières du quai : un wagonnet fleuri à chaque bout, une caisse à lanterne entre les bancs
	B.wagonnetFleuri(m, CFrame.new(-18, 2.2, -105.4), 21)
	B.caisseLanterne(m, CFrame.new(-18, 2.2, -123), 22)
	B.wagonnetFleuri(m, CFrame.new(-18, 2.2, -140.8), 23)
	for _, z in {-108, -123, -138} do
		B.suspension(m, Vector3.new(x0, 13.6, z), 2.5)
	end
	B.caisse(m, CFrame.new(-21.5, 2.2, -144))
	B.caisse(m, CFrame.new(-21.3, 4.8, -144) * CFrame.Angles(0, 0.4, 0), 2)
	B.tonneau(m, CFrame.new(-21.8, 2.2, -104))

	-- Butoir et wagonnets qui attendent
	B.butoir(m, CFrame.new(0, 2, -100.5))
	B.wagonnet(m, CFrame.new(0, 2, -108), Color3.fromRGB(34, 34, 38), rng)
	B.wagonnet(m, CFrame.new(0, 2, -116.5), Color3.fromRGB(184, 100, 46), rng)
	B.wagonnet(m, CFrame.new(0, 2, -125))

	-- Tas de minerai et grue côté est
	B.tas(m, CFrame.new(22, 0, -132), Color3.fromRGB(34, 34, 38), 8, rng)
	B.tas(m, CFrame.new(28, 0, -144), Color3.fromRGB(150, 154, 160), 6, rng)
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(1, 16, 1), CFrame.new(30 + s * 2, 7.8, -154) * CFrame.Angles(0, 0, s * math.rad(8)), C.BoisFonce, M.Bois, "Pied")
	end
	O.bloc(m, Vector3.new(1, 1, 14), CFrame.new(30, 15.6, -149), C.Bois, M.Bois, "Fleche")
	O.decor(O.bloc(m, Vector3.new(0.15, 7, 0.15), CFrame.new(30, 11.6, -143), Color3.fromRGB(150, 130, 100), M.Tissu, "Corde"))
	O.decor(O.cylindre(m, 1.4, 1.8, CFrame.new(30, 7.4, -143), C.Bois, M.Bois, "Seau"))

	for _, z in {-150, -164} do
		for _, x in {-8, 8} do
			B.lanterne(m, vers(Vector3.new(x, 0, z), Vector3.new(0, 0, z)))
		end
	end
end

-- ================= Voie ferrée =================

-- Enlève uniquement le terrain qui traverse la voie en pente ; le sol construit
-- sous les rails reste en place pour porter les joueurs et les wagonnets.
local function degagerDescente(mine)
	if mine:GetAttribute("DescenteDegagee") == 1 then return end
	local a, b = D.TUNNEL_FIN, D.DESCENTE_FIN
	local longueur = (b - a).Magnitude
	local axe = CFrame.lookAt(a, b)
	terrain:FillBlock(axe * CFrame.new(0, 2, -longueur / 2), Vector3.new(10, 10, longueur), Enum.Material.Air)
	mine:SetAttribute("DescenteDegagee", 1)
end

local function voie(f)
	local m = O.modele(f, "Voie")
	m:SetAttribute("VersionVoie", 1)
	local hauteurSol = Vector3.new(0, 2, 0) -- surface réelle du terrain voxélisé
	troncon(m, D.RAIL_DEBUT + hauteurSol, D.TUNNEL_FIN + hauteurSol)
	troncon(m, D.TUNNEL_FIN + hauteurSol, D.DESCENTE_FIN + hauteurSol)
	troncon(m, D.DESCENTE_FIN + hauteurSol, D.QUAI_BAS + hauteurSol)
	local A, Bp = D.TUNNEL_FIN, D.DESCENTE_FIN
	local L = (Bp - A).Magnitude
	O.bloc(m, Vector3.new(26, 4, L), CFrame.lookAt(A, Bp) * CFrame.new(0, -2, -L / 2), C.Roche, M.Ardoise, "SolDescente")
	B.butoir(m, CFrame.new(D.QUAI_BAS + hauteurSol + Vector3.new(0, 0, -0.5)) * CFrame.Angles(0, math.pi, 0))
end

-- Inscription « LA GRANDE MINE » en éclats de cristaux bleus et roses jaillissant de la falaise au-dessus du portail,
-- avec un nain mineur sur son échafaudage qui pioche le dernier E. Texte de 170 studs de large (capitales de 13),
-- lisible depuis la place.
local INSCRIPTION_BASE_Y = D.PORTAIL_HAUTEUR + 33 -- au-dessus du couronnement rocheux de la façade
local INSCRIPTION_LARGEUR = 170
local INSCRIPTION_HAUTEUR = 13
local INSCRIPTION_TEXTE = "LA GRANDE MINE"
-- Traits des lettres en cristal, sur une grille de 4 × 6 (x vers la droite, y vers le haut)
local POLICE_CRISTAL = {
	L = {{{0, 0}, {0, 6}}, {{0, 0}, {3.6, 0}}},
	A = {{{0, 0}, {2, 6}}, {{2, 6}, {4, 0}}, {{0.9, 2.4}, {3.1, 2.4}}},
	G = {{{4, 5}, {3, 6}}, {{3, 6}, {1, 6}}, {{1, 6}, {0, 5}}, {{0, 5}, {0, 1}}, {{0, 1}, {1, 0}}, {{1, 0}, {3, 0}},
		{{3, 0}, {4, 1}}, {{4, 1}, {4, 2.8}}, {{4, 2.8}, {2.2, 2.8}}},
	R = {{{0, 0}, {0, 6}}, {{0, 6}, {3, 6}}, {{3, 6}, {4, 5}}, {{4, 5}, {4, 4}}, {{4, 4}, {3, 3}}, {{3, 3}, {0, 3}}, {{2, 3}, {4, 0}}},
	N = {{{0, 0}, {0, 6}}, {{0, 6}, {4, 0}}, {{4, 0}, {4, 6}}},
	D = {{{0, 0}, {0, 6}}, {{0, 6}, {2.4, 6}}, {{2.4, 6}, {4, 4.4}}, {{4, 4.4}, {4, 1.6}}, {{4, 1.6}, {2.4, 0}}, {{2.4, 0}, {0, 0}}},
	E = {{{0, 0}, {0, 6}}, {{0, 6}, {3.8, 6}}, {{0, 3}, {3, 3}}, {{0, 0}, {3.8, 0}}},
	M = {{{0, 0}, {0, 6}}, {{0, 6}, {2, 2.6}}, {{2, 2.6}, {4, 6}}, {{4, 6}, {4, 0}}},
	I = {{{2, 0}, {2, 6}}},
}
local function surfaceFalaise(): number
	-- point le plus avancé de la paroi sur toute la largeur du texte (seulement le terrain)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	p.FilterDescendantsInstances = {terrain}
	local avant = -math.huge
	for x = -INSCRIPTION_LARGEUR / 2, INSCRIPTION_LARGEUR / 2, 10 do
		for _, y in {INSCRIPTION_BASE_Y + 2, INSCRIPTION_BASE_Y + INSCRIPTION_HAUTEUR / 2, INSCRIPTION_BASE_Y + INSCRIPTION_HAUTEUR - 2} do
			local r = workspace:Raycast(Vector3.new(x, y, D.PORTAIL_Z + 60), Vector3.new(0, 0, -120), p)
			if r then
				avant = math.max(avant, r.Position.Z)
			end
		end
	end
	return if avant > -math.huge then avant else D.PORTAIL_Z - 2
end

local function preparerEnseigne(mine)
	local portail = mine:FindFirstChild("Portail")
	if not portail then return end
	local existante = portail:FindFirstChild("EnseigneGrandeMine")
	if existante and existante:GetAttribute("Version") == 13 then return end
	if existante then existante:Destroy() end
	local ancienne = portail:FindFirstChild("Enseigne")
	if ancienne and ancienne:IsA("BasePart") then ancienne:Destroy() end
	local cadre = O.modele(portail, "EnseigneGrandeMine")
	cadre:SetAttribute("Version", 13)

	-- les lettres sont posées juste devant la roche la plus avancée ; derrière, une assise de roche sombre comble
	-- les creux de la paroi (incrustées, jamais en l'air), et devant, le terrain est dégagé (rien ne les recouvre)
	local z = surfaceFalaise() + 1.5
	local y = INSCRIPTION_BASE_Y
	local centreY = y + INSCRIPTION_HAUTEUR / 2
	-- la bande derrière le texte prend la roche de la montagne (basalte sombre veiné de grès) et des bosses
	-- irrégulières, toutes en retrait du plan des lettres (qui semblent légèrement enfoncées dans la roche)
	local rngRoche = Random.new(77)
	terrain:FillBlock(CFrame.new(0, centreY, z - 8), Vector3.new(INSCRIPTION_LARGEUR + 8, INSCRIPTION_HAUTEUR + 6, 12), Enum.Material.Basalt)
	for _ = 1, 40 do
		local p = Vector3.new(rngRoche:NextNumber(-INSCRIPTION_LARGEUR / 2, INSCRIPTION_LARGEUR / 2), centreY + rngRoche:NextNumber(-10, 10), z - 4.5)
		terrain:FillBall(p, rngRoche:NextNumber(2.5, 4), if rngRoche:NextNumber() < 0.3 then Enum.Material.Sandstone else Enum.Material.Basalt)
	end
	terrain:FillBlock(CFrame.new(0, centreY, z + 3), Vector3.new(INSCRIPTION_LARGEUR + 8, INSCRIPTION_HAUTEUR + 4, 8), Enum.Material.Air)

	-- Lettres en cristal facetté bleu-violet : chaque trait est une barre de cristal (section en losange, gaine de
	-- verre + cœur néon), les jointures sont couvertes par de petites pointes ; dégradé bleu → violet le long du texte.
	local rng = Random.new(2024)
	local BLEU, ROSE = Color3.fromRGB(70, 150, 255), Color3.fromRGB(176, 96, 255)
	local uy = INSCRIPTION_HAUTEUR / 6
	local ux = 2.05
	local pas = INSCRIPTION_LARGEUR / #INSCRIPTION_TEXTE
	local EPAISSEUR = 1.9
	local function barre(parent, a, b, couleur)
		local dir, longueur = (b - a).Unit, (b - a).Magnitude
		-- cristal brut : le trait est fait de 2 ou 3 blocs irréguliers (épaisseur, rotation et léger décalage variables)
		local n = if longueur > 9 then 3 elseif longueur > 4 then 2 else 1
		for k = 1, n do
			local t0, t1 = (k - 1) / n, k / n
			local milieu = a + dir * (longueur * (t0 + t1) / 2) + Vector3.new(rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.1, 0.25))
			local e = EPAISSEUR * rng:NextNumber(0.88, 1.12)
			local cf = CFrame.lookAt(milieu, milieu + dir, Vector3.zAxis) * CFrame.Angles(math.rad(rng:NextNumber(-3, 3)), math.rad(rng:NextNumber(-3, 3)), math.rad(45 + rng:NextNumber(-14, 14)))
			local seg = longueur / n + EPAISSEUR * (if k == 1 or k == n then 0.25 else 0.4)
			local gaine = O.decor(O.bloc(parent, Vector3.new(e, e * rng:NextNumber(0.85, 1.05), seg), cf, couleur, M.Verre, "Cristal"))
			gaine.Transparency = 0.15
			gaine.Reflectance = 0.35
			gaine.CastShadow = false
			local reflet = O.decor(O.bloc(parent, Vector3.new(e * 0.55, e * 1.06, seg * 0.92), cf * CFrame.Angles(0, 0, math.rad(45)),
				couleur:Lerp(Color3.new(1, 1, 1), 0.28), M.Verre, "Facette"))
			reflet.Transparency = 0.4
			reflet.CastShadow = false
			O.decor(O.bloc(parent, Vector3.new(e * 0.55, e * 0.55, seg * 0.95), cf, couleur:Lerp(Color3.new(1, 1, 1), 0.12), M.Neon, "Coeur")).CastShadow = false
		end
		-- petites pointes qui dépassent du trait
		for _ = 1, rng:NextInteger(0, if longueur > 6 then 2 else 1) do
			local p = a + dir * longueur * rng:NextNumber(0.15, 0.85)
			local h = rng:NextNumber(0.9, 1.6)
			local cf = CFrame.new(p) * CFrame.Angles(math.rad(rng:NextNumber(20, 70)), 0, math.rad(rng:NextNumber(-60, 60)))
			local pointe = O.decor(O.bloc(parent, Vector3.new(0.55, h, 0.55), cf * CFrame.new(0, h / 2 + 0.4, 0) * CFrame.Angles(0, math.rad(45), 0), couleur, M.Verre, "Pointe"))
			pointe.Transparency = 0.15
			pointe.CastShadow = false
			O.decor(O.bloc(parent, Vector3.new(0.4, 0.4, 0.4), cf * CFrame.new(0, h + 0.4, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), couleur:Lerp(Color3.new(1, 1, 1), 0.3), M.Neon, "Bout")).CastShadow = false
		end
	end
	local function noeud(parent, p, couleur)
		local d = O.decor(O.bloc(parent, Vector3.one * EPAISSEUR * rng:NextNumber(1.05, 1.3), CFrame.new(p) * CFrame.Angles(math.rad(45 + rng:NextNumber(-15, 15)), math.rad(45 + rng:NextNumber(-15, 15)), 0), couleur, M.Verre, "Noeud"))
		d.Transparency = 0.2
		d.Reflectance = 0.3
		d.CastShadow = false
	end
	for i = 1, #INSCRIPTION_TEXTE do
		local traits = POLICE_CRISTAL[INSCRIPTION_TEXTE:sub(i, i)]
		if traits then
			local groupe = O.modele(cadre, "Lettre" .. i)
			local x0 = -INSCRIPTION_LARGEUR / 2 + (i - 0.5) * pas - 2 * ux
			local function point(q) return Vector3.new(x0 + q[1] * ux, y + q[2] * uy + EPAISSEUR / 2, z - 0.3) end
			for _, t in traits do
				local couleur = BLEU:Lerp(ROSE, math.clamp((i - 1) / (#INSCRIPTION_TEXTE - 1) * 0.7 + rng:NextNumber(0, 0.3), 0, 1))
				local a, b = point(t[1]), point(t[2])
				barre(groupe, a, b, couleur)
				noeud(groupe, a, couleur)
				noeud(groupe, b, couleur)
			end
		end
	end
	-- grappes de cristaux sur la roche autour du texte (avec leur lumière)
	for _, g in {{-93, -1, 0}, {-88, 2, 1}, {-60, 17, 1}, {-14, 16, 0}, {30, 17, 1}, {66, 16, 0}, {-36, -2, 1}, {10, -2, 0}, {48, -2, 1}, {-80, 15, 0}} do
		local p = Vector3.new(g[1], y + g[2], z - 1)
		B.cristal(cadre, CFrame.new(p) * CFrame.Angles(math.rad(12), 0, math.rad(rng:NextNumber(-20, 20))), rng:NextNumber(3.5, 5.5),
			if g[3] == 0 then BLEU else ROSE, rng, 22)
	end
	-- lueurs bleues et roses qui baignent l'inscription
	for k, x in {-60, 0, 60} do
		local p = O.decor(O.bloc(cadre, Vector3.one, CFrame.new(x, y + INSCRIPTION_HAUTEUR / 2, z + 8), Color3.new(), M.Lisse, "Halo"))
		p.Transparency = 1
		O.lumiere(p, if k == 2 then ROSE else BLEU, 0.55, 22)
	end

	-- Nain mineur sur son échafaudage, qui pioche le dernier E (animé par PiocheurEnseigne.client)
	local xE = -INSCRIPTION_LARGEUR / 2 + (#INSCRIPTION_TEXTE - 0.5) * pas + 1.8 * ux + EPAISSEUR
	local plancher = CFrame.new(xE + 7.6, y - 0.4, z + 2)
	local echafaudage = O.modele(cadre, "Echafaudage")
	O.decor(O.bloc(echafaudage, Vector3.new(9.5, 0.6, 6), plancher, C.Bois, M.Planches, "Plancher"))
	for _, dx in {-4.5, 4.5} do
		for _, dz in {-2.7, 2.7} do
			O.decor(O.bloc(echafaudage, Vector3.new(0.6, 14, 0.6), plancher * CFrame.new(dx, -7.2, dz), C.BoisFonce, M.Bois, "Montant"))
		end
		O.decor(O.bloc(echafaudage, Vector3.new(0.35, 0.35, 7.8), plancher * CFrame.new(dx, -6, 0) * CFrame.Angles(math.rad(40), 0, 0), C.BoisFonce, M.Bois, "Croix"))
		O.decor(O.bloc(echafaudage, Vector3.new(0.35, 2, 0.35), plancher * CFrame.new(dx, 1.2, 2.7), C.BoisFonce, M.Bois, "GardeCorps"))
	end
	O.decor(O.bloc(echafaudage, Vector3.new(9.5, 0.3, 0.3), plancher * CFrame.new(0, 2.1, 2.7), C.BoisFonce, M.Bois, "Lisse"))
	local lampe = O.decor(O.bloc(echafaudage, Vector3.new(0.3, 3, 0.3), plancher * CFrame.new(4.5, 1.8, -2.7), C.Fer, M.Metal, "PoteauLampe"))
	B.suspension(echafaudage, lampe.Position + Vector3.new(0, 1.1, 0), 0.4, C.Lumiere, 18)
	B.caisse(echafaudage, plancher * CFrame.new(3, 0.3, 1.2), 2)
	B.nainPiocheur(cadre, plancher * CFrame.new(-0.6, 0.3, -0.9) * CFrame.Angles(0, math.rad(90), 0), 2.6)
end

local preparerPortes, preparerCristal -- définies avec la caverne, plus bas

-- Ajuster le texte indépendamment du dégagement du quai et de sa rampe.
local LARGEUR_TEXTE_QUAI = 0.78
local function preparerQuai(caverne)
	local enseigne = caverne:FindFirstChild("Enseigne")
	local gui = enseigne and enseigne:FindFirstChild("TexteBack")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Size = UDim2.fromScale(LARGEUR_TEXTE_QUAI, 0.8)
		label.Position = UDim2.fromScale((1 - LARGEUR_TEXTE_QUAI) / 2, 0.1)
		label.TextScaled = true
	end
end

-- Actualise la voie des cartes déjà enregistrées sans reconstruire la mine.
function Mine.preparerVoie(mine)
	preparerEnseigne(mine)
	local gareExistante = mine:FindFirstChild("Gare")
	if gareExistante then nettoyerGare(gareExistante) end
	local caverneExistante = mine:FindFirstChild("Caverne")
	if caverneExistante then
		preparerWagonRetour(caverneExistante)
		preparerCristal(caverneExistante)
		degagerQuai(caverneExistante)
		preparerQuai(caverneExistante)
	end
	local okDecor, erreurDecor = pcall(CaverneDecor.preparer, mine)
	if not okDecor then warn("[Mine] Décor de la caverne non mis à jour : " .. tostring(erreurDecor)) end
	local ok, erreur = pcall(preparerPortes, mine)
	if not ok then warn("[Mine] Portes non mises à jour : " .. tostring(erreur)) end
	degagerDescente(mine)
	local ancienne = mine:FindFirstChild("Voie")
	if not ancienne or ancienne:GetAttribute("VersionVoie") == 1 then return end
	local temporaire = Instance.new("Folder")
	temporaire.Parent = mine
	local ok, erreur = pcall(voie, temporaire)
	if not ok then temporaire:Destroy(); warn("[Mine] Voie non mise à jour : " .. tostring(erreur)); return end
	local nouvelle = temporaire:FindFirstChild("Voie")
	ancienne:Destroy()
	nouvelle.Parent = mine
	temporaire:Destroy()
	local ancienButoir = gareExistante and gareExistante:FindFirstChild("Butoir")
	if ancienButoir then
		B.butoir(gareExistante, CFrame.new(0, 2, -100.5))
		ancienButoir:Destroy()
		for _, objet in gareExistante:GetChildren() do
			if objet.Name == "Wagonnet" and objet:IsA("Model") then objet:PivotTo(objet:GetPivot() + Vector3.new(0, 2, 0)) end
		end
	end
end

-- ================= Portail dans la falaise =================

local function portail(f, rng)
	local m = O.modele(f, "Portail")
	local z = D.PORTAIL_Z
	local W, H = D.PORTAIL_LARGEUR, D.PORTAIL_HAUTEUR
	local pierre = Color3.fromRGB(108, 100, 94)

	for _, s in {-1, 1} do
		local x = s * (W / 2 + 7)
		O.bloc(m, Vector3.new(14, 48, 8), CFrame.new(x, 24, z), pierre, M.Granite, "Pilier")
		O.bloc(m, Vector3.new(16, 3, 10), CFrame.new(x, 1.5, z + 1), C.PierreFoncee, M.Pierre, "Base")
		O.bloc(m, Vector3.new(15, 2.4, 9), CFrame.new(x, 46.8, z), C.PierreClaire, M.Pierre, "Corniche")
		-- cadre de bois dans l'ouverture
		O.bloc(m, Vector3.new(3, H, 3), CFrame.new(s * (W / 2 - 1.5), H / 2, z + 3), C.BoisFonce, M.Bois, "Poteau")
		O.bloc(m, Vector3.new(1.8, 9, 1.8), CFrame.new(s * (W / 2 - 6.5), H - 7, z + 3) * CFrame.Angles(0, 0, s * math.rad(45)),
			C.Bois, M.Bois, "JambeDeForce")
		B.brasero(m, CFrame.new(s * (W / 2 + 6), 0, z + 10), 1.2)
	end
	O.bloc(m, Vector3.new(W + 0.2, 12, 8), CFrame.new(0, H + 6, z), pierre, M.Granite, "Linteau")
	O.bloc(m, Vector3.new(W, 3.5, 3.5), CFrame.new(0, H - 1.75, z + 3), C.BoisFonce, M.Bois, "Poutre")
	O.bloc(m, Vector3.new(6, 6, 9), CFrame.new(0, H + 3.5, z), C.PierreClaire, M.Pierre, "CleDeVoute")
	preparerEnseigne(f)

	-- Cristaux géants qui sortent de la falaise
	for _, c in {{-48, 36, 24, C.Cristal}, {-30, 50, 20, C.CristalViolet}, {42, 30, 26, C.CristalViolet}, {26, 62, 18, C.Cristal}, {62, 18, 16, C.Cristal}} do
		local s = if c[1] < 0 then -1 else 1
		B.cristal(m, CFrame.new(c[1], c[2], -188) * CFrame.Angles(math.rad(50), 0, math.rad(-s * 15)), c[3], c[4], rng, 50)
	end
	B.cristal(m, CFrame.new(-40, -1, -168) * CFrame.Angles(0.2, 0.5, -0.2), 9, C.Cristal, rng)
	B.cristal(m, CFrame.new(41, -1, -166) * CFrame.Angles(0.15, -0.4, 0.2), 7, C.CristalViolet, rng)

	-- Matériel de mineur devant l'entrée
	B.caisse(m, CFrame.new(-30, 0, -157))
	B.caisse(m, CFrame.new(-27.2, 0, -157.5) * CFrame.Angles(0, 0.3, 0))
	B.caisse(m, CFrame.new(-28.6, 2.6, -157.2) * CFrame.Angles(0, -0.2, 0), 2.2)
	B.tonneau(m, CFrame.new(-25, 0, -152))
	B.pioche(m, CFrame.new(-30, 2.6, -157) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(150, 154, 162))
	B.wagonnet(m, CFrame.new(32, 0, -156) * CFrame.Angles(0, 0.6, 0), Color3.fromRGB(156, 162, 172), rng)
	B.tonneau(m, CFrame.new(26, 0, -150))
end

-- ================= Tunnel et descente =================

local function soutenements(f)
	local m = O.modele(f, "Soutenements")
	for z = -188, D.TUNNEL_FIN.Z, -11 do
		cadre(m, CFrame.new(0, 0, z), 40, 28, 2.2)
		B.suspension(m, Vector3.new(0, 28, z), 3, nil, 34)
	end
	local A, Bp = D.TUNNEL_FIN, D.DESCENTE_FIN
	local dir = (Bp - A).Unit
	local L = (Bp - A).Magnitude
	for s = 10, L - 6, 13 do
		local p = A + dir * s
		cadre(m, CFrame.new(p), 22, 20, 1.8)
		B.suspension(m, p + Vector3.new(0, 20, 0), 2.5, nil, 28)
	end
end

-- ================= Grande caverne =================

-- Portes encastrées dans la paroi. Le terrain (voxels de 4 studs) est trop grossier pour une ouverture
-- nette : on dégage l'air devant, on rebouche derrière, puis une façade de roche en Parts et une
-- embrasure sombre (murs, plafond, fond noir) donnent une ouverture propre. Devant : parvis et cercle.
local VERSION_PORTES = 5
local ROCHE_PAROI = Color3.fromRGB(112, 104, 98) -- couleur du matériau Rock du terrain
local EMBRASURE = Color3.fromRGB(28, 25, 24)
local function portes(f)
	local m = O.modele(f, "PortesTunnels")
	for i, pos in D.PORTES do
		local base = vers(pos, D.CAVERNE_CENTRE) -- -Z vers le centre ; la paroi est derrière (+Z)
		local paroi = base * CFrame.new(0, 0, D.PORTES_ENFONCEMENT)
		terrain:FillBlock(paroi * CFrame.new(0, 13, 10), Vector3.new(24, 34, 16), Enum.Material.Rock)
		-- Déborder derrière la face en pierre : les voxels arrondis ne doivent pas reparaître devant.
		terrain:FillBlock(paroi * CFrame.new(0, 14.5, -0.125), Vector3.new(28, 28, 9.75), Enum.Material.Air)
		-- Le dégagement mord sur celui de la façade pour effacer le bourrelet de voxels au seuil.
		terrain:FillBlock(paroi * CFrame.new(0, 9, 5), Vector3.new(18, 18, 12), Enum.Material.Air)
		-- Le sol visible de la caverne est 2 studs au-dessus du repère de creusement.
		-- On relève le cadre et le plancher, sans déplacer le cercle devant la porte.
		local cf = paroi * CFrame.new(0, 2, 0)
		local g = O.modele(m, "Porte" .. i)
		-- Façade autour de l'ouverture : bord intérieur à x = ±4,7 et face avant à z = +1.
		for _, s in {-1, 1} do
			O.bloc(g, Vector3.new(6, 22, 2), cf * CFrame.new(s * 7.7, 11, 2), ROCHE_PAROI, M.Roche, "Facade")
		end
		O.bloc(g, Vector3.new(9.4, 8, 2), cf * CFrame.new(0, 18, 2), ROCHE_PAROI, M.Roche, "Facade")
		-- Embrasure : galerie sombre jusqu'au fond noir
		for _, s in {-1, 1} do
			O.bloc(g, Vector3.new(1, 14, 9), cf * CFrame.new(s * 5.2, 7, 5.5), EMBRASURE, M.Ardoise, "Embrasure")
		end
		O.bloc(g, Vector3.new(11.4, 1, 9), cf * CFrame.new(0, 14.5, 5.5), EMBRASURE, M.Ardoise, "Embrasure")
		local epaisseurSol = 0.55
		local hauteurSol = 0.25 - epaisseurSol / 2
		O.decor(O.bloc(g, Vector3.new(9.4, epaisseurSol, 9), cf * CFrame.new(0, hauteurSol, 5.5), EMBRASURE, M.Ardoise, "Embrasure"))
		O.decor(O.bloc(g, Vector3.new(11, 15, 0.4), cf * CFrame.new(0, 7.3, 9.8), Color3.fromRGB(6, 6, 8), M.Lisse, "Obscurite"))
		-- Cadre de bois et lanternes collés à la façade
		for _, x in {-5.6, 5.6} do
			O.bloc(g, Vector3.new(1.8, 14, 1.8), cf * CFrame.new(x, 7, 0), C.BoisFonce, M.Bois, "Poteau")
			B.applique(g, cf * CFrame.new(x * 1.4, 9, 1))
		end
		O.bloc(g, Vector3.new(13.4, 2, 2), cf * CFrame.new(0, 15, 0), C.BoisFonce, M.Bois, "Linteau")
		O.decor(O.bloc(g, Vector3.new(9, 0.35, 0.2), cf * CFrame.new(0, 15, -1.05), C.Cristal, M.Neon, "Runes"))
		local panneau = O.decor(O.bloc(g, Vector3.new(8, 2.6, 0.4), cf * CFrame.new(0, 17.7, -0.85), C.BoisFonce, M.Planches, "Panneau"))
		O.texte(panneau, Enum.NormalId.Front, "Tunnel " .. (ROMAINS[i] or tostring(i)), {lumiere = 0})
		-- Une seule pièce porteuse sous le parvis et l'embrasure ; les joints du bois restent visuels.
		local profondeurPlanche = 1.65
		local debutParvis = 1 - 4 * profondeurPlanche
		local support = O.bloc(g, Vector3.new(9.4, epaisseurSol, 10 - debutParvis), cf * CFrame.new(0, hauteurSol, (10 + debutParvis) / 2),
			EMBRASURE, M.Ardoise, "SolPorte")
		support.Transparency = 1
		support.CastShadow = false
		for k = 0, 3 do
			local teinte = if k % 2 == 0 then C.Bois else C.BoisFonce:Lerp(C.Bois, 0.5)
			O.decor(O.bloc(g, Vector3.new(9.4, epaisseurSol, profondeurPlanche), cf * CFrame.new(0, hauteurSol, 1 - (k + 0.5) * profondeurPlanche),
				teinte, M.Planches, "Planche"))
		end
		local cercle = Cercle.construire(g, base * CFrame.new(0, 0, -D.CERCLES_AVANCE), "CercleTunnel")
		cercle:SetAttribute("Numero", i)
		O.tag(cercle, "CercleTunnel")
	end
	m:SetAttribute("VersionPortes", VERSION_PORTES) -- seulement après succès
end

-- Cartes figées : remplace les anciennes portes (cadre en avant de la paroi) par les portes encastrées.
function preparerPortes(mine)
	local existantes = mine:FindFirstChild("PortesTunnels")
	if existantes and existantes:GetAttribute("VersionPortes") == VERSION_PORTES then return end
	if existantes then existantes:Destroy() end
	portes(mine)
end

-- Cartes figées : déplace le grand cristal (rocher, cristal, satellites) vers D.CRISTAL_CAVERNE.
local ANCIEN_CRISTAL = Vector3.new(-30, D.CAVERNE_SOL, -445)
function preparerCristal(caverne)
	if caverne:GetAttribute("VersionCristal") == 2 then return end
	local decalage = D.CRISTAL_CAVERNE - ANCIEN_CRISTAL
	for _, objet in caverne:GetChildren() do
		if objet:IsA("Model") and (objet.Name == "Cristal" or objet.Name:match("^Rocher")) then
			local p = objet:GetPivot().Position
			local ecart = Vector3.new(p.X - ANCIEN_CRISTAL.X, 0, p.Z - ANCIEN_CRISTAL.Z).Magnitude
			if ecart < 16 and p.Y < D.CAVERNE_SOL + 25 then objet:PivotTo(objet:GetPivot() + decalage) end
		end
	end
	caverne:SetAttribute("VersionCristal", 2) -- seulement après succès
end

local function caverne(f, rng)
	local m = O.modele(f, "Caverne")
	local y = D.CAVERNE_SOL
	local centre = D.CAVERNE_CENTRE

	-- Quai souterrain
	O.bloc(m, Vector3.new(14, 2, 30), CFrame.new(-12.2, y + 1, -390), C.Bois, M.Planches, "Quai")
	O.coin(m, Vector3.new(14, 2, 6), CFrame.new(-12.2, y + 1, -408), C.Bois, M.Planches, "Rampe")
	degagerQuai(m)
	for _, z in {-378, -402} do
		B.lanterne(m, vers(Vector3.new(-18, y + 2, z), Vector3.new(0, y + 2, z)), 9)
	end
	for _, x in {-17, -7} do
		O.bloc(m, Vector3.new(0.8, 9, 0.8), CFrame.new(x, y + 6.5, -376.5), C.BoisFonce, M.Bois, "Poteau")
	end
	local enseigne = O.bloc(m, Vector3.new(11, 2.6, 0.4), CFrame.new(-12, y + 10, -376.5), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(enseigne, Enum.NormalId.Back, "QUAI DES PROFONDEURS")
	preparerQuai(m)
	preparerWagonRetour(m)

	-- Grand amas de cristaux violets (lobe ouest, loin des portes)
	m:SetAttribute("VersionCristal", 2)
	local amas = CFrame.new(D.CRISTAL_CAVERNE + Vector3.new(0, -0.5, 0))
	B.rocher(m, D.CRISTAL_CAVERNE + Vector3.new(0, -1.5, 0), 7, rng)
	local _, coeur = B.cristal(m, amas, 26, C.CristalViolet, rng, 60)
	local lumiere = coeur:FindFirstChildOfClass("PointLight")
	if lumiere then
		lumiere.Shadows = true
		lumiere.Brightness = 1.5 -- lueur douce (plus d'éblouissement en entrant)
	end
	O.lucioles(coeur, C.CristalViolet, 8)
	for i = 1, 6 do
		local a = i * math.pi / 3 + rng:NextNumber(-0.3, 0.3)
		local p = amas * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -rng:NextNumber(6, 10)) * CFrame.Angles(-rng:NextNumber(0.2, 0.5), 0, 0)
		B.cristal(m, p, rng:NextNumber(7, 15), if i % 2 == 0 then C.Cristal else C.CristalViolet, rng, 30)
	end

	-- Brume au sol
	local zone = O.decor(O.bloc(m, Vector3.new(120, 2, 120), CFrame.new(centre.X, y + 1.5, centre.Z), Color3.new(1, 1, 1), M.Lisse, "ZoneBrume"))
	zone.Transparency = 1
	O.brume(zone, Color3.fromRGB(150, 160, 200), 5)

	-- Braseros (le wagonnet du centre a été retiré : centre dégagé)
	B.brasero(m, CFrame.new(24, y, -396))
	B.brasero(m, CFrame.new(-44, y, -404))

	-- « TUNNELS PRIVÉS » : texte flottant posé par CaverneDecor (l'ancien panneau sur poteaux est retiré)

	-- Stalactites et cristaux dans les parois (on vise la roche avec des rayons)
	task.wait()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {terrain}

	for _ = 1, 45 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(5, 62)
		local depart = Vector3.new(centre.X + math.sin(a) * r, y + 8, centre.Z - math.cos(a) * r)
		local hit = workspace:Raycast(depart, Vector3.new(0, 140, 0), params)
		if hit then
			local longueur = rng:NextNumber(5, 15)
			local rot = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
			local haut = hit.Position.Y + 1
			for k = 0, 2 do
				local l = longueur * (0.45 - k * 0.1)
				local w = longueur * (0.28 - k * 0.08)
				O.decor(O.bloc(m, Vector3.new(w, l, w), CFrame.new(hit.Position.X, haut - l / 2, hit.Position.Z) * rot, C.Roche, M.Roche, "Stalactite"))
				haut = haut - l + 0.3
			end
		end
	end

	for _ = 1, 22 do
		local a = rng:NextNumber(0, math.pi * 2)
		local dir = Vector3.new(math.sin(a), rng:NextNumber(-0.15, 0.6), -math.cos(a)).Unit
		local zonePortes = math.cos(a) > 0.35 and dir.Y < 0.25
		local zoneVoie = math.cos(a) < -0.8
		if not zonePortes and not zoneVoie then
			local hit = workspace:Raycast(centre + Vector3.new(0, -8, 0), dir * 140, params)
			if hit and math.abs(hit.Normal.Y) < 0.9 then
				local cf = CFrame.lookAt(hit.Position, hit.Position + hit.Normal) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, -1.5, 0)
				B.cristal(m, cf, rng:NextNumber(5, 12), if rng:NextNumber() < 0.5 then C.Cristal else C.CristalViolet, rng, 30)
			end
		end
	end
end

-- Points d'apparition pour le script des minerais (tag "SpawnMinerai")
local function pointsMinerai(f)
	local d = Instance.new("Folder")
	d.Name = "PointsMinerai"
	d.Parent = f
	for _, p in D.MINERAIS do
		local s = O.decor(O.bloc(d, Vector3.new(4, 1, 4), CFrame.new(p + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1), M.Lisse, "SpawnMinerai"))
		s.Transparency = 1
		O.tag(s, "SpawnMinerai")
	end
end

function Mine.construire(carte)
	local rng = Random.new(4242)
	local f = Instance.new("Folder")
	f.Name = "Mine"
	f.Parent = carte

	gare(f, rng)
	voie(f)
	degagerDescente(f)
	portail(f, rng)
	soutenements(f)
	portes(f)
	caverne(f, rng)
	local okDecor, erreurDecor = pcall(CaverneDecor.preparer, f) -- piliers, pont, cascade, rayons, frise, sanctuaire…
	if not okDecor then warn("[Mine] Décor de la caverne non construit : " .. tostring(erreurDecor)) end
	-- pointsMinerai(f) : plus aucun minerai dans la mine (seulement des cristaux) ; les minerais sont dans les grottes
end

return Mine
