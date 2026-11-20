-- Le village du spawn : place centrale avec le cristal flottant, boutiques, forge, taverne,
-- maisons, rivière avec moulin, classements, lanternes, forêt et cristaux dans les montagnes.
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local T = require(script.Parent.Terrain)
local M, C = O.M, O.C

local Village = {}

local function sol(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- CFrame posé en pos, la façade (-Z) tournée vers la cible
local function vers(pos, cible)
	return CFrame.lookAt(pos, Vector3.new(cible.X, pos.Y, cible.Z))
end

-- Angle 0 = nord (-Z), sens horaire vu du dessus
local function polaire(a, r, y)
	return Vector3.new(math.sin(a) * r, y or 0, -math.cos(a) * r)
end

local function chemin(parent, a, b, largeur)
	a, b = sol(a), sol(b)
	local L = (b - a).Magnitude
	if L < 1 then
		return
	end
	O.bloc(parent, Vector3.new(largeur or 4.5, 0.3, L), CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, 0.15, 0), C.Terre, M.Terre, "Chemin")
end

-- ================= Place et spawn =================

local function place(v)
	local m = O.modele(v, "Place")
	O.cylindre(m, 0.4, D.PLACE_RAYON * 2, CFrame.new(0, 0.2, 0), C.Paves, M.Paves, "Dallage")
	for i = 0, 23 do
		if i ~= 0 and i ~= 1 and i ~= 23 and i ~= 12 then -- ouvertures : avenue (nord) et route (sud)
			O.bloc(m, Vector3.new(9.2, 0.7, 1.4), CFrame.Angles(0, -i * math.pi / 12, 0) * CFrame.new(0, 0.35, -D.PLACE_RAYON),
				C.PierreFoncee, M.Pierre, "Bordure")
		end
	end
	for i = 0, 19 do
		O.bloc(m, Vector3.new(7.2, 0.5, 1), CFrame.Angles(0, i * math.pi / 10, 0) * CFrame.new(0, 0.25, -22),
			C.PierreFoncee, M.Paves, "Cercle")
	end
	for _, a in {35, 145, 215, 325} do
		B.banc(m, vers(polaire(math.rad(a), 29, 0.4), Vector3.zero))
	end
end

local function monument(v, rng)
	local m = O.modele(v, "Monument")
	m:SetAttribute("VersionFontaine", 2)
	local y = 2 -- surface du terrain sur la place
	-- Fontaine circulaire : diamètre 1,5 fois supérieur à l'ancien bassin.
	local pierre = Color3.fromRGB(80, 82, 78)
	local mousse = Color3.fromRGB(64, 80, 52)
	O.cylindre(m, 0.6, 21.6, CFrame.new(0, y + 0.3, 0), pierre, M.Ardoise, "FondBassin")
	local eau = O.decor(O.cylindre(m, 0.25, 19.3, CFrame.new(0, y + 1.05, 0), C.Eau, M.Verre, "Eau"))
	eau.Transparency = 0.3
	eau.Reflectance = 0.2
	for i = 0, 31 do
		local angle = i * math.pi * 2 / 32
		local cf = CFrame.new(10.2 * math.cos(angle), y + 1.15, 10.2 * math.sin(angle)) * CFrame.Angles(0, -angle, 0)
		O.bloc(m, Vector3.new(1.2, 1.5, 2.05), cf, pierre, M.Pierre, "Margelle")
		if i % 3 == 0 then
			O.decor(O.bloc(m, Vector3.new(0.65, 0.12, 1.1), cf + Vector3.new(0, 0.8, 0), mousse, Enum.Material.LeafyGrass, "Mousse"))
		end
	end
	-- Piédestal central et deux vasques étagées en pierre sombre.
	for _, piece in {
		{1, 5.4, 1.5, "Socle"}, {0.45, 4.8, 2.2, "Socle"},
		{2.2, 2.8, 3.45, "Colonne"}, {0.45, 3.8, 4.6, "Colonne"},
		{0.5, 5.2, 4.9, "GrandeVasque"}, {0.45, 7.2, 5.25, "GrandeVasque"},
		{0.4, 9.2, 5.6, "GrandeVasque"}, {0.35, 10.2, 5.9, "GrandeVasque"},
		{0.45, 3.6, 6.4, "ColonneHaute"}, {2.2, 2.2, 7.65, "ColonneHaute"},
		{0.4, 3.2, 8.85, "ColonneHaute"}, {0.45, 4.4, 9.15, "PetiteVasque"},
		{0.4, 5.4, 9.48, "PetiteVasque"}, {0.35, 6.3, 9.78, "PetiteVasque"},
		{0.35, 1.7, 10.15, "Sommet"}, {0.45, 1.05, 10.55, "Sommet"},
	} do
		O.cylindre(m, piece[1], piece[2], CFrame.new(0, y + piece[3], 0), pierre, M.Pierre, piece[4])
	end
	local function eauDecor(taille, position, nom)
		local p = O.decor(O.bloc(m, taille, CFrame.new(position), C.Eau, M.Verre, nom))
		p.Transparency = eau.Transparency
		p.Reflectance = eau.Reflectance
	end
	for i = 0, 15 do
		local angle = i * math.pi * 2 / 16
		local x, z = math.cos(angle), math.sin(angle)
		-- Filets d'eau au bord des deux vasques, et touches de mousse espacées.
		eauDecor(Vector3.new(0.15, 3.6, 0.15), Vector3.new(x * 4.9, y + 3.85, z * 4.9), "ChuteGrandeVasque")
		if i % 2 == 0 then
			eauDecor(Vector3.new(0.12, 3.5, 0.12), Vector3.new(x * 3, y + 7.85, z * 3), "ChutePetiteVasque")
			O.decor(O.bloc(m, Vector3.new(0.55, 0.12, 0.55), CFrame.new(x * 4.7, y + 6.13, z * 4.7), mousse, Enum.Material.LeafyGrass, "MousseVasque"))
		end
	end

	-- Le cristal flottant (il monte, descend et tourne : animé par le client)
	local f = O.modele(v, "CristalFlottant")
	local _, coeur = B.cristal(f, CFrame.new(0, y + 19.2, 0), 7, C.Cristal, rng, 60)
	B.cristal(f, CFrame.new(0, y + 19.4, 0) * CFrame.Angles(math.pi, 0, 0), 3, C.Cristal, rng)
	for i = 0, 3 do
		local a = i * math.pi / 2
		B.cristal(f, CFrame.new(polaire(a, 4.5, y + 18.7)) * CFrame.Angles(0.3, -a, 0), 1.6, C.CristalViolet, rng)
	end
	O.lucioles(coeur, C.Cristal, 6)
	O.decorModele(f)
	f.PrimaryPart = coeur
	f:SetAttribute("Amplitude", 0.7)
	O.atomique(f)
	O.tag(f, "Flottant")
end

-- Met aussi à jour les places déjà figées, sans reconstruire le reste du village.
function Village.preparerFontaine(village)
	local ancienne = village:FindFirstChild("Monument")
	if not ancienne or ancienne:GetAttribute("VersionFontaine") == 2 then
		return
	end
	local ancienCristal = village:FindFirstChild("CristalFlottant")
	local temporaire = Instance.new("Folder")
	temporaire.Name = "FontaineEnConstruction"
	temporaire.Parent = village
	local ok, erreur = pcall(monument, temporaire, Random.new(1789))
	if not ok then
		temporaire:Destroy()
		warn("[Village] Impossible de préparer la fontaine : " .. tostring(erreur))
		return
	end
	local nouvelle = temporaire:FindFirstChild("Monument")
	local nouveauCristal = temporaire:FindFirstChild("CristalFlottant")
	if ancienCristal and ancienCristal:IsA("Model") and nouveauCristal then
		local collection = game:GetService("CollectionService")
		collection:RemoveTag(ancienCristal, "Flottant")
		ancienCristal:PivotTo(nouveauCristal:GetPivot())
		collection:AddTag(ancienCristal, "Flottant")
		nouveauCristal:Destroy()
	else
		nouveauCristal.Parent = village
	end
	ancienne:Destroy()
	nouvelle.Parent = village
	temporaire:Destroy()
end

-- Chemins décoratifs posés sur le terrain réel, y compris sur les cartes figées.
function Village.preparerSentiers(village)
	local anciens = village:FindFirstChild("SentiersFontaine")
	if anciens and anciens:GetAttribute("VersionSentiers") == 3 then
		return
	end
	local sentiers = O.modele(village, "SentiersEnConstruction")
	local rng = Random.new(43672)
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {workspace.Terrain}
	local terre = Color3.fromRGB(145, 112, 78)
	local pierres = {Color3.fromRGB(113, 108, 98), Color3.fromRGB(127, 119, 107), Color3.fromRGB(98, 96, 89)}
	local function hauteur(x, z)
		local resultat = workspace:Raycast(Vector3.new(x, 180, z), Vector3.new(0, -300, 0), filtre)
		if resultat and resultat.Material ~= Enum.Material.Water then
			return resultat.Position.Y
		end
		return nil
	end
	local function terreAuSol(x, z, diametre)
		local h = hauteur(x, z)
		if not h then return end
		-- Des disques superposés forment des bords arrondis et évitent les trous.
		local p = O.decor(O.cylindre(sentiers, 0.12, diametre * rng:NextNumber(0.94, 1.06), CFrame.new(x, h + 0.05 + rng:NextNumber(0, 0.004), z), terre, M.Terre, "Terre"))
		p.CastShadow = false
	end
	local function pave(x, z)
		local h = hauteur(x, z)
		if not h then return end
		local p = O.decor(O.bloc(sentiers, Vector3.new(rng:NextNumber(0.65, 1.35), 0.11, rng:NextNumber(0.65, 1.45)), CFrame.new(x, h + 0.14, z) * CFrame.Angles(0, rng:NextNumber(-0.65, 0.65), 0), pierres[rng:NextInteger(1, #pierres)], M.Paves, "Pave"))
		p.CastShadow = false
	end
	-- Anneau autour du bassin, puis deux allées : vers la gare et vers le pont.
	local rayon = 15.8
	for i = 0, 47 do
		local angle = i * 2 * math.pi / 48
		local x, z = rayon * math.cos(angle), rayon * math.sin(angle)
		terreAuSol(x, z, 7.5)
		if i % 2 == 0 then
			local r = rng:NextNumber(12.4, 19.1)
			pave(r * math.cos(angle), r * math.sin(angle))
		end
	end
	local function allee(x1, z1, x2, z2, largeur)
		local debut, fin = Vector2.new(x1, z1), Vector2.new(x2, z2)
		local direction = fin - debut
		local nombre = math.ceil(direction.Magnitude / 2.8)
		for i = 0, nombre do
			local position = debut:Lerp(fin, i / nombre)
			local normal = Vector2.new(-direction.Y, direction.X).Unit
			local decalage = rng:NextNumber(-0.65, 0.65)
			terreAuSol(position.X + normal.X * decalage, position.Y + normal.Y * decalage, largeur)
			if i % 2 == 0 then
				local lateral = rng:NextNumber(-largeur * 0.4, largeur * 0.4)
				pave(position.X + normal.X * lateral, position.Y + normal.Y * lateral)
			end
		end
	end
	allee(0, -15, 0, -96, 10)
	allee(0, -89, -14.5, -97, 8)
	allee(0, 15, 0, D.RIVIERE_Z - 16, 9)
	sentiers:SetAttribute("VersionSentiers", 3)
	if anciens then anciens:Destroy() end
	sentiers.Name = "SentiersFontaine"
end

local function apparitions(v)
	local dossier = Instance.new("Folder")
	dossier.Name = "Apparitions"
	dossier.Parent = v
	for i = 0, 7 do
		local pos = polaire(i * math.pi / 4 + math.pi / 8, 15, 0.65)
		local s = Instance.new("SpawnLocation")
		s.Name = "Apparition"
		s.Anchored = true
		s.Size = Vector3.new(5, 0.5, 5)
		s.CFrame = CFrame.new(pos) -- orientation par défaut : le joueur regarde le nord, donc la mine
		s.Material = M.Ardoise
		s.Color = C.PierreFoncee
		s.Duration = 0
		s.Neutral = true
		s.TopSurface = Enum.SurfaceType.Smooth
		s.BottomSurface = Enum.SurfaceType.Smooth
		s.Parent = dossier
		local rune = O.decor(O.bloc(dossier, Vector3.new(3, 0.1, 3), CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(45), 0),
			C.Cristal, M.Neon, "Rune"))
		rune.Transparency = 0.55
	end
end

local function routes(v)
	local m = O.modele(v, "Routes")
	local zA, zB = -D.PLACE_RAYON + 1, D.AVENUE_FIN_Z
	local L = zA - zB
	O.bloc(m, Vector3.new(14, 0.44, L), CFrame.new(0, 0.22, (zA + zB) / 2), C.Paves, M.Paves, "Avenue")
	for _, x in {-7.4, 7.4} do
		O.bloc(m, Vector3.new(0.8, 0.6, L), CFrame.new(x, 0.3, (zA + zB) / 2), C.PierreFoncee, M.Pierre, "Bordure")
	end
	chemin(m, Vector3.new(0, 0, D.PLACE_RAYON - 1), Vector3.new(0, 0, D.RIVIERE_Z - 15), 8)
	chemin(m, Vector3.new(0, 0, D.RIVIERE_Z + 15), Vector3.new(0, 0, 136), 8)
end

-- ================= Boutiques =================

local function tenue(haut, bas, extra)
	local t = {haut = haut, bas = bas}
	for k, val in extra or {} do
		t[k] = val
	end
	return t
end

local function boutiques(v, rng, obstacles)
	local m = O.modele(v, "Boutiques")
	local hauteurEnseignes = 13.45

	-- Comptoir des minerais : on y vend ce qu'on a miné
	local pos = Vector3.new(-60, 0, -14)
	table.insert(obstacles, pos)
	local cf = vers(pos, Vector3.zero)
	local maisonComptoir = B.maison(m, cf, {largeur = 20, profondeur = 16, etages = 2, mur = C.Ocre, nom = "ComptoirMinerais", rng = rng})
	B.fronton(maisonComptoir, cf * CFrame.new(0, hauteurEnseignes, -8), "COMPTOIR DES MINERAIS", 16)
	local e = cf * CFrame.new(0, 0, -14.5)
	B.echoppe(m, e, 10, Color3.fromRGB(150, 58, 46))
	local minerais = {
		{Color3.fromRGB(34, 34, 38), M.Ardoise},
		{Color3.fromRGB(184, 100, 46), M.Metal},
		{Color3.fromRGB(156, 162, 172), M.Metal},
		{Color3.fromRGB(255, 196, 48), Enum.Material.Foil},
	}
	for i, mi in minerais do
		local x = -3.6 + (i - 1) * 2.4
		O.decor(O.bloc(m, Vector3.new(1.8, 0.8, 1.6), e * CFrame.new(x, 3.95, 0), C.BoisClair, M.Planches, "Bac"))
		for k = 1, 3 do
			O.decor(O.ellipsoide(m, Vector3.new(0.8, 0.6, 0.8), e * CFrame.new(x + (k - 2) * 0.45, 4.45, (k % 2) * 0.3 - 0.15), mi[1], mi[2], "Minerai"))
		end
	end
	B.tonneau(m, e * CFrame.new(-7, 0, 1))
	B.caisse(m, e * CFrame.new(7, 0, 0.5))
	B.caisse(m, e * CFrame.new(7.3, 2.6, 0.6) * CFrame.Angles(0, 0.3, 0), 2)
	local pnj = B.pnj(m, e * CFrame.new(0, 0, 2.6), "Gaspard", "Marchand de minerais",
		tenue(Color3.fromRGB(120, 40, 36), Color3.fromRGB(60, 50, 44), {
			chapeau = Color3.fromRGB(70, 50, 36), cheveux = Color3.fromRGB(150, 146, 140), barbe = Color3.fromRGB(170, 166, 160),
			peau = Color3.fromRGB(232, 190, 160), outil = "registre",
				corps = {hauteur = 1.02, largeur = 1.05},
				-- veste de cuir, feutre en laine, barbe blanche
				accessoires = {{77359892, "Hat"}, {330294871, "Face"}, {7192547628, "Jacket"}},
		}))
	pnj:SetAttribute("Service", "Vente")

	-- Pioches & outils : améliorer son équipement
	pos = Vector3.new(-60, 0, 28)
	table.insert(obstacles, pos)
	cf = vers(pos, Vector3.zero)
	local maisonOutilleur = B.maison(m, cf, {largeur = 24, profondeur = 14, etages = 2, mur = C.Platre, toit = C.ToitRouge,
		nom = "Outilleur", lierreFacade = false, rng = rng})
	B.fronton(maisonOutilleur, cf * CFrame.new(0, hauteurEnseignes, -7), "PIOCHES & OUTILS", 16)
	e = cf * CFrame.new(0, 0, -13.5)
	B.echoppe(m, e, 10, Color3.fromRGB(52, 84, 140))
	for i, c in {Color3.fromRGB(150, 154, 162), Color3.fromRGB(184, 100, 46), Color3.fromRGB(255, 196, 48)} do
		B.pioche(m, e * CFrame.new(-3 + (i - 1) * 3, 3.55, 0) * CFrame.Angles(0, 0.25 * (i - 2), 0), c)
	end
	B.tonneau(m, e * CFrame.new(7, 0, 1))
	pnj = B.pnj(m, e * CFrame.new(0, 0, 2.6), "Liesel", "Fabricante d'outils",
		tenue(Color3.fromRGB(70, 96, 120), Color3.fromRGB(64, 56, 48), {
			tablier = Color3.fromRGB(96, 66, 44), coiffure = "chignon", cheveux = Color3.fromRGB(176, 82, 40),
			peau = Color3.fromRGB(240, 202, 176), outil = "pioche",
			corps = {hauteur = 0.95, largeur = 0.9, proportions = 0.6},
			-- tresse rousse, lunettes d'atelier, veste en jean
			accessoires = {{7193455510, "Hair"}, {2316756148, "Face"}, {8516609675, "Jacket"}},
		}))
	pnj:SetAttribute("Service", "Outils")

	-- La forge : épées et armures (casque, plastron, jambières)
	pos = Vector3.new(60, 0, -12)
	table.insert(obstacles, pos)
	cf = vers(pos, Vector3.zero)
	B.forge(m, cf)
	pnj = B.pnj(m, cf * CFrame.new(2, 1, 2.2), "Brom", "Forgeron",
		tenue(Color3.fromRGB(90, 70, 58), Color3.fromRGB(48, 42, 38),
			{peau = Color3.fromRGB(196, 150, 118), barbe = Color3.fromRGB(150, 70, 36), barbeLongue = true, coiffure = "chauve",
			cheveux = Color3.fromRGB(150, 70, 36), tablier = Color3.fromRGB(70, 46, 30), manchesCourtes = true, outil = "marteau",
				corps = {hauteur = 1.05, largeur = 1.2, silhouette = 0.6},
				-- barbe rousse tressée, lunettes de forge
				accessoires = {{461491285, "Face"}, {108828585, "Face"}}}))
	pnj:SetAttribute("Service", "Forge")
	B.tonneau(m, cf * CFrame.new(-13.5, 0, -6))
	B.caisse(m, cf * CFrame.new(13.6, 0, -4), 2.4)

	-- La taverne
	pos = Vector3.new(62, 0, 30)
	table.insert(obstacles, pos)
	cf = vers(pos, Vector3.zero)
	B.maison(m, cf, {largeur = 26, profondeur = 18, etages = 2, mur = C.Platre, toit = C.ToitRouge, nom = "Taverne",
		enseigne = "TAVERNE DU PIC DORÉ", rng = rng})
	for _, x in {-8, 0, 8} do
		B.tableTaverne(m, cf * CFrame.new(x, 0, -16))
	end
	for _, x in {-11.5, 11.5} do
		B.tonneau(m, cf * CFrame.new(x, 0, -10.5))
	end
	pnj = B.pnj(m, cf * CFrame.new(-5, 0, -11), "Margot", "Aubergiste",
		tenue(Color3.fromRGB(150, 110, 60), Color3.fromRGB(80, 50, 60), {
			tablier = Color3.fromRGB(230, 220, 200), coiffure = "long", cheveux = Color3.fromRGB(92, 56, 34),
			peau = Color3.fromRGB(222, 176, 140), outil = "chope",
				corps = {hauteur = 0.95, largeur = 0.92, proportions = 0.6},
				-- longs cheveux bruns, pull en laine, longue jupe blanche (tablier)
				accessoires = {{17877340, "Hair"}, {6984769289, "Sweater"}, {9240776381, "DressSkirt"}},
		}))
	pnj:SetAttribute("Service", "Taverne")
end

-- ================= Maisons =================

local MURS = {C.Platre, C.Ocre, C.PlatreGris, Color3.fromRGB(196, 180, 150)}
local TOITS = {C.Toit, C.ToitRouge, Color3.fromRGB(92, 74, 62)}
local VOLETS = {C.Volet, Color3.fromRGB(120, 52, 44), Color3.fromRGB(60, 70, 104)}

-- {x, z, largeur, profondeur, étages}
local MAISONS = {
	{-102, -42, 18, 15, 2}, {-108, 2, 16, 14, 1}, {-100, 46, 20, 16, 2}, {-72, 54, 16, 14, 1},
	{102, -44, 18, 16, 2}, {108, 2, 16, 14, 1}, {104, 46, 20, 15, 2}, {74, 58, 16, 14, 1},
	{-42, 122, 18, 14, 1}, {0, 144, 20, 16, 2}, {42, 122, 18, 14, 1}, {-80, 118, 16, 14, 1}, {80, 116, 16, 14, 1},
}

local function maisons(v, rng, obstacles)
	local m = O.modele(v, "Maisons")
	for i, d in MAISONS do
		local pos = Vector3.new(d[1], 0, d[2])
		table.insert(obstacles, pos)
		local cf = vers(pos, Vector3.zero)
		local _, porte = B.maison(m, cf, {
			largeur = d[3], profondeur = d[4], etages = d[5], rng = rng, nom = "Maison" .. i,
			mur = MURS[rng:NextInteger(1, #MURS)], toit = TOITS[rng:NextInteger(1, #TOITS)], volet = VOLETS[rng:NextInteger(1, #VOLETS)],
		})
		local devant = (porte * CFrame.new(0, 0, -2.2)).Position
		if pos.Z > D.RIVIERE_Z then
			chemin(m, devant, Vector3.new(0, 0, devant.Z)) -- rejoint la route du sud
		else
			chemin(m, devant, sol(devant).Unit * (D.PLACE_RAYON - 1)) -- rejoint la place
		end
		if rng:NextNumber() < 0.6 then
			B.tonneau(m, porte * CFrame.new(-3.6, -1.6, -1.6))
		end
	end

	-- Entrepôts près de la gare
	for _, x in {-62, 62} do
		local pos = Vector3.new(x, 0, -86)
		table.insert(obstacles, pos)
		local cf = vers(pos, Vector3.new(0, 0, -86))
		local _, porte = B.maison(m, cf, {largeur = 24, profondeur = 16, etages = 1, mur = C.PlatreGris, toit = C.Toit,
			nom = "Entrepot", enseigne = "ENTREPÔT", cheminee = false, rng = rng})
		chemin(m, (porte * CFrame.new(0, 0, -2.2)).Position, Vector3.new(math.sign(x) * 8, 0, -86))
		for k = 0, 2 do
			B.caisse(m, porte * CFrame.new(5 + k * 2.8, -1.6, -2.5))
		end
	end
end

-- ================= Rivière, pont et moulin =================

local function riviere(v, rng)
	local m = O.modele(v, "Riviere")
	local z = D.RIVIERE_Z
	local demi = D.RIVIERE_LARGEUR / 2

	O.bloc(m, Vector3.new(10, 1.2, 32), CFrame.new(0, 0, z), C.Pierre, M.Pierre, "Tablier")
	for _, x in {-5.5, 5.5} do
		O.bloc(m, Vector3.new(1, 2.4, 32), CFrame.new(x, 1.8, z), C.PierreClaire, M.Pierre, "Parapet")
	end
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(10, 9, 3), CFrame.new(0, -5, z + s * (demi - 1.5)), C.Pierre, M.Pierre, "Pile")
		for _, x in {-6.8, 6.8} do
			local p = Vector3.new(x, 0, z + s * 17)
			B.lanterne(m, vers(p, Vector3.new(0, 0, p.Z)), 9)
		end
	end

	-- Moulin à eau
	local cfMoulin = CFrame.lookAt(Vector3.new(-34, 0, 60), Vector3.new(-34, 0, 0))
	B.maison(m, cfMoulin, {largeur = 16, profondeur = 14, etages = 1, mur = C.Ocre, toit = C.Toit, nom = "Moulin", rng = rng})
	local axe = CFrame.new(-34, 1.5, 76) * CFrame.Angles(0, math.pi / 2, 0) -- axe X local = nord-sud
	O.disque(m, 9, 0.8, axe * CFrame.new(4.5, 0, 0), C.Fer, M.Metal, "Axe")
	O.bloc(m, Vector3.new(1.6, 9.2, 1.6), CFrame.new(-34, -3.4, 72.6), C.BoisFonce, M.Bois, "Support")

	local roue = O.modele(m, "RoueMoulin")
	local R = 7
	local moyeu = O.disque(roue, 3.4, 2.2, axe, C.BoisFonce, M.Bois, "Moyeu")
	for _, x in {-1.3, 1.3} do
		for i = 0, 15 do
			O.bloc(roue, Vector3.new(0.7, 0.7, 2 * math.pi * R / 16 + 0.3), axe * CFrame.new(x, 0, 0) * CFrame.Angles(i * math.pi / 8, 0, 0) * CFrame.new(0, R, 0),
				C.Bois, M.Bois, "Jante")
		end
		for i = 0, 7 do
			O.bloc(roue, Vector3.new(0.5, R, 0.5), axe * CFrame.new(x, 0, 0) * CFrame.Angles(i * math.pi / 4, 0, 0) * CFrame.new(0, R / 2, 0),
				C.BoisFonce, M.Bois, "Rayon")
		end
	end
	for i = 0, 11 do
		O.bloc(roue, Vector3.new(3.2, 1.8, 0.35), axe * CFrame.Angles(i * math.pi / 6, 0, 0) * CFrame.new(0, R + 0.5, 0), C.BoisClair, M.Planches, "Pale")
	end
	O.decorModele(roue)
	roue.PrimaryPart = moyeu
	roue:SetAttribute("Vitesse", 0.5)
	O.atomique(roue)
	O.tag(roue, "Rotatif")
	local remous = O.decor(O.bloc(m, Vector3.new(12, 1, 3), CFrame.new(-34, -4, 76), Color3.new(1, 1, 1), M.Lisse, "Remous"))
	remous.Transparency = 1
	O.brume(remous, Color3.fromRGB(230, 236, 240), 6)

	-- Rochers sur les berges
	for _ = 1, 16 do
		local s = if rng:NextNumber() < 0.5 then -1 else 1
		local x = rng:NextNumber(-200, 200)
		if math.abs(x) > 12 and math.abs(x + 34) > 10 then
			B.rocher(m, Vector3.new(x, -0.8, z + s * (demi + rng:NextNumber(0, 2))), rng:NextNumber(1.5, 3.5), rng)
		end
	end
end

-- ================= Éclairage, classements, décor =================

local function lanternes(v)
	local m = O.modele(v, "Eclairage")
	for z = -42, -96, -14 do
		for _, x in {-9.5, 9.5} do
			B.lanterne(m, vers(Vector3.new(x, 0, z), Vector3.new(0, 0, z)))
		end
	end
	for i = 0, 7 do
		-- Décale le lampadaire qui masque l’enseigne de Liesel depuis la place.
		local angle = 22.5 + i * 45 + (if i == 5 then 10 else 0)
		B.lanterne(m, vers(polaire(math.rad(angle), D.PLACE_RAYON + 2.5), Vector3.zero))
	end
	for _, z in {48, 114, 130} do
		B.lanterne(m, vers(Vector3.new(6, 0, z), Vector3.new(0, 0, z)), 9)
	end
end

local function classements(v)
	local m = O.modele(v, "Classements")
	B.classement(m, vers(Vector3.new(-24, 0, -44), Vector3.new(0, 0, 4)), "Meilleurs Mineurs", "Pieces")
	B.classement(m, vers(Vector3.new(24, 0, -44), Vector3.new(0, 0, 4)), "Plus Profonds", "Profondeur")
end

local function decor(v, rng, obstacles)
	local m = O.modele(v, "Decor")
	local puits = Vector3.new(-20, 0, 46)
	table.insert(obstacles, puits)
	B.puits(m, CFrame.new(puits))
	B.tonneau(m, CFrame.new(-14, 0, 50))
	B.caisse(m, CFrame.new(-26, 0, 52) * CFrame.Angles(0, 0.4, 0))

	-- Lueurs qui flottent au-dessus de la place
	local zone = O.decor(O.bloc(m, Vector3.new(90, 8, 90), CFrame.new(0, 6, 0), Color3.new(1, 1, 1), M.Lisse, "ZoneLucioles"))
	zone.Transparency = 1
	O.lucioles(zone, Color3.fromRGB(255, 210, 140), 10)

	-- Arbres d'automne dans le village
	for _, p in {{-34, -62}, {34, -62}, {-86, 24}, {86, 22}, {-22, 104}, {22, 104}, {-128, -12}, {128, -14}, {-60, 96}, {60, 96}} do
		local base = Vector3.new(p[1], -0.4, p[2])
		table.insert(obstacles, base)
		B.feuillu(m, base, rng:NextNumber(17, 24), rng)
	end
end

local function nature(v, rng, obstacles)
	local f = Instance.new("Folder")
	f.Name = "Nature"
	f.Parent = v

	local function libre(x, z, marge)
		if math.sqrt(x * x + z * z) < 132 then
			return false
		end
		if math.abs(z - D.RIVIERE_Z) < 16 then
			return false
		end
		if math.abs(x) < 50 and z < -60 then
			return false -- gare et entrée de la mine
		end
		for _, o in obstacles do
			if (Vector2.new(x - o.X, z - o.Z)).Magnitude < marge then
				return false
			end
		end
		return true
	end

	local function pente(x, z)
		return math.max(
			math.abs(T.hauteur(x + 3, z) - T.hauteur(x - 3, z)),
			math.abs(T.hauteur(x, z + 3) - T.hauteur(x, z - 3))
		) / 6
	end

	local arbres = 0
	for _ = 1, 2500 do
		if arbres >= 230 then
			break
		end
		local x, z = rng:NextNumber(-300, 300), rng:NextNumber(-250, 230)
		if libre(x, z, 16) then
			local h = T.hauteur(x, z)
			if h < 130 and pente(x, z) < 0.9 then
				local base = Vector3.new(x, h - 0.6, z)
				if h > 15 or rng:NextNumber() < 0.55 then
					B.pin(f, base, rng:NextNumber(22, 38), rng)
				else
					B.feuillu(f, base, rng:NextNumber(16, 24), rng)
				end
				arbres += 1
			end
		end
	end

	-- Rochers : petits éboulis au pied des pentes, gros blocs sur les flancs
	local rochers = 0
	for _ = 1, 2500 do
		if rochers >= 150 then
			break
		end
		local x, z = rng:NextNumber(-300, 300), rng:NextNumber(-250, 230)
		if libre(x, z, 12) then
			local h = T.hauteur(x, z)
			local p = pente(x, z)
			if h < 230 and p < 2.2 then
				local taille = if p > 1 then rng:NextNumber(5, 13) else rng:NextNumber(2.5, 8)
				B.rocher(f, Vector3.new(x, h - taille * 0.15, z), taille, rng)
				-- quelques cailloux tombés autour
				if rng:NextNumber() < 0.5 then
					for _ = 1, rng:NextInteger(2, 4) do
						local cx, cz = x + rng:NextNumber(-8, 8), z + rng:NextNumber(-8, 8)
						B.rocher(f, Vector3.new(cx, T.hauteur(cx, cz) - 0.3, cz), rng:NextNumber(1, 2.5), rng)
					end
				end
				rochers += 1
			end
		end
	end
end

--[[ Falaises et aiguilles rocheuses modélisées (Blender) plantées dans les pentes raides :
	bancs de roche stratifiés, sommets enneigés en altitude. Rien si les modèles 3D manquent. ]]
local function falaises(v, rng)
	local f = O.modele(v, "Falaises")
	local poses = {}
	local function loin(x, z, d)
		for _, p in poses do
			if (p.X - x) ^ 2 + (p.Z - z) ^ 2 < d * d then
				return false
			end
		end
		return true
	end
	local nFalaises, nAiguilles = 0, 0
	for _ = 1, 6000 do
		if nFalaises >= 70 and nAiguilles >= 18 then
			break
		end
		local x, z = rng:NextNumber(-312, 312), rng:NextNumber(-545, 232)
		-- dégager l'entrée de la mine
		if math.abs(x) < 75 and z < -110 and z > -300 then
			continue
		end
		local h = T.hauteur(x, z)
		local gx = T.hauteur(x + 4, z) - T.hauteur(x - 4, z)
		local gz = T.hauteur(x, z + 4) - T.hauteur(x, z - 4)
		local pente = math.sqrt(gx * gx + gz * gz) / 8
		if h < 35 or pente < 0.8 then
			continue
		end
		-- la largeur de la roche suit la courbe de niveau, face tournée vers la vallée
		local niveau = Vector3.new(-gz, 0, gx)
		if niveau.Magnitude < 1e-3 then
			continue
		end
		niveau = niveau.Unit
		local aiguille = nAiguilles < 18 and h > 150 and pente > 1.1 and rng:NextNumber() < 0.35
		local hauteur = if aiguille then rng:NextNumber(30, 60) else rng:NextNumber(24, 66)
		if aiguille or nFalaises < 70 then
			if loin(x, z, hauteur * 0.9) then
				local base = Vector3.new(x, h - hauteur * (if aiguille then 0.2 else 0.32), z)
				local cf = CFrame.fromMatrix(base, niveau, Vector3.yAxis)
					* CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.12, 0.12))
				if B.falaise(f, cf, hauteur, rng, aiguille) then
					table.insert(poses, base)
					if aiguille then
						nAiguilles += 1
					else
						nFalaises += 1
					end
				else
					break -- pas de modèles 3D importés
				end
			end
		end
	end
end

-- Cristaux géants qui sortent des montagnes autour de la vallée
local function cristaux(v, rng)
	local f = O.modele(v, "CristauxMontagne")
	local spots = {
		{-150, -120, 24, C.Cristal}, {165, -96, 30, C.CristalViolet}, {-182, 58, 26, C.CristalViolet},
		{186, 36, 22, C.Cristal}, {-120, 176, 28, C.Cristal}, {132, 168, 24, C.CristalViolet},
	}
	for _, s in spots do
		local h = T.hauteur(s[1], s[2])
		B.cristal(f, CFrame.new(s[1], h - 3, s[2]) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6.28), rng:NextNumber(-0.25, 0.25)),
			s[3], s[4], rng, 60)
	end
	O.decorModele(f)
end

-- Aussi appelé sur les cartes déjà figées, dont les toiles peuvent avoir été enregistrées sans collision.
function Village.preparerToits(village)
	local noms = {Auvent = true, Toit = true, Faitage = true}
	for _, piece in village:GetDescendants() do
		if piece:IsA("BasePart") and noms[piece.Name] then
			if piece.Name == "Auvent" then
				piece.CanCollide = true
				piece.CanQuery = true
			end
			if piece.CanCollide then
				piece:SetAttribute("ToitRebond", true)
			end
		end
	end
end

function Village.construire(carte)
	local rng = Random.new(1789)
	local v = Instance.new("Folder")
	v.Name = "Village"
	v.Parent = carte
	local obstacles = {}

	place(v)
	monument(v, rng)
	apparitions(v)
	routes(v)
	boutiques(v, rng, obstacles)
	maisons(v, rng, obstacles)
	riviere(v, rng)
	lanternes(v)
	classements(v)
	decor(v, rng, obstacles)
	nature(v, rng, obstacles)
	falaises(v, rng)
	cristaux(v, rng)
	Village.preparerToits(v)
	Village.preparerSentiers(v)
end

return Village
