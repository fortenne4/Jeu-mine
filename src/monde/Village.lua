-- Le village du spawn : place centrale avec le cristal flottant, boutiques, forge, taverne,
-- maisons, rivière avec moulin, classements, lanternes, forêt et cristaux dans les montagnes.
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local Lampadaires = require(script.Parent.Lampadaires)
local T = require(script.Parent.Terrain)
local M, C = O.M, O.C

local Village = {}

-- Aménagement de la terrasse de la taverne (coordonnées locales de la façade).
local TERRASSE_HAUSSE_TOIT = 3.5
local TERRASSE_AVANCE_TABLES = 8.3
local TERRASSE_ESPACEMENT_TABLES = 11
local TERRASSE_POSITION_MARGOT = Vector3.new(-6, 0, -9)
local TERRASSE_ECART_TONNEAUX = 17.5
local TAVERNE_MARGE_CHEMIN = 4 -- espace d'herbe visé devant le mobilier
local TAVERNE_RECUL = 11 + TAVERNE_MARGE_CHEMIN
local TAVERNE_LANTERNE_COTE = Vector3.new(19.3, 6.6, 0)
local TAVERNE_LANTERNE_PORTEE = 22

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
	m:SetAttribute("VersionFontaine", 3)
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
		p.Color = Color3.fromRGB(124, 190, 194)
		p.Transparency = 0.84
		p.Size = Vector3.new(0.28, p.Size.Y, 0.28)
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
	local _, coeur = B.cristal(f, CFrame.new(0, y + 16.7, 0), 7, C.Cristal, rng, 60)
	B.cristal(f, CFrame.new(0, y + 16.9, 0) * CFrame.Angles(math.pi, 0, 0), 3, C.Cristal, rng)
	for i = 0, 3 do
		local a = i * math.pi / 2
		B.cristal(f, CFrame.new(polaire(a, 4.5, y + 16.2)) * CFrame.Angles(0.3, -a, 0), 1.6, C.CristalViolet, rng)
	end
	O.lucioles(coeur, C.Cristal, 6)
	O.decorModele(f)
	f.PrimaryPart = coeur
	f:SetAttribute("Amplitude", 0.7)
	O.atomique(f)
	O.tag(f, "Flottant")
	O.atomique(m)
	O.tag(m, "FontaineAnimee")
end

-- Met aussi à jour les places déjà figées, sans reconstruire le reste du village.
function Village.preparerFontaine(village)
	local ancienne = village:FindFirstChild("Monument")
	if not ancienne or ancienne:GetAttribute("VersionFontaine") == 3 then
		if ancienne then O.tag(ancienne, "FontaineAnimee") end
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

-- Pièces de « nom » dans parent dont le centre est à moins de rayon (horizontal) de p
local function piecesProches(parent, noms, p, rayon)
	local liste = {}
	for _, d in parent:GetChildren() do
		if noms[d.Name] then
			local pos = if d:IsA("BasePart") then d.Position elseif d:IsA("Model") then d:GetPivot().Position else nil
			if pos and (Vector2.new(pos.X - p.X, pos.Z - p.Z)).Magnitude < rayon then table.insert(liste, d) end
		end
	end
	return liste
end

local VERSION_ENSEIGNE = 2
local Z_ENSEIGNE, Y_ENSEIGNE = -1.55, 11.6
local enseigneStand -- défini plus bas (boutiques)

-- Cartes figées : remplace l'ancien foyer de la forge, les puits et les enseignes des deux marchands
-- par les versions actuelles (B.fourneau, B.puits, enseigneStand), une seule fois par version.
function Village.preparerAteliers(village)
	-- Fourneau du forgeron
	local forge = village:FindFirstChild("Forge", true)
	if forge and forge:IsA("Model") then
		local actuel = forge:FindFirstChild("Fourneau")
		if not (actuel and actuel:GetAttribute("VersionFourneau") == B.VERSION_FOURNEAU) then
			local base = actuel and actuel:GetAttribute("Base")
			local ancien = forge:FindFirstChild("Foyer")
			if typeof(base) ~= "CFrame" and ancien and ancien:IsA("BasePart") then
				base = ancien.CFrame * CFrame.new(0, -2, 0) -- l'ancien bloc était posé en foyer * (0, 2, 0)
			end
			if typeof(base) == "CFrame" then
				for _, d in piecesProches(forge, {Foyer = true, Braises = true, Hotte = true, Cheminee = true, Chapeau = true, Soufflet = true}, base.Position, 7) do
					d:Destroy()
				end
				if actuel then actuel:Destroy() end
				local f = B.fourneau(forge, base)
				f:SetAttribute("Base", base)
			end
		end
	end
	-- Puits
	for _, puits in village:GetDescendants() do
		if puits:IsA("Model") and puits.Name == "Puits" and puits:GetAttribute("VersionPuits") ~= B.VERSION_PUITS then
			local eau = puits:FindFirstChild("Eau")
			local base = puits:GetAttribute("Base")
			if typeof(base) ~= "CFrame" and eau and eau:IsA("BasePart") then
				base = CFrame.new(eau.Position - Vector3.new(0, 1.2, 0)) -- ancien puits : eau en cf * (0, 1.2, 0)
			end
			if typeof(base) == "CFrame" then
				local parent = puits.Parent
				puits:Destroy()
				B.puits(parent, base):SetAttribute("Base", base)
			end
		end
	end
	-- Tonneaux enfoncés dans d'autres pièces (scintillement) : celui de l'atelier de Liesel (mur, plancher,
	-- râtelier) va sur le plancher ; ceux qui mordent sur le dallage d'un puits sont repoussés à côté
	local atelier = village:FindFirstChild("AtelierOutils", true)
	local plancher = atelier and atelier:FindFirstChild("Plancher")
	local tonneauAtelier = atelier and atelier:FindFirstChild("Tonneau")
	local corpsAtelier = tonneauAtelier and tonneauAtelier:FindFirstChild("Corps")
	if plancher and plancher:IsA("BasePart") and corpsAtelier and corpsAtelier:IsA("BasePart") then
		local cible = (plancher.CFrame * CFrame.new(3.6, 0.25, 1.6)).Position -- = atelier * (3.6, 0.5, 1.6)
		tonneauAtelier:TranslateBy(cible - (corpsAtelier.Position - Vector3.new(0, 1.6, 0)))
	end
	for _, puits in village:GetDescendants() do
		local dallage = puits:IsA("Model") and puits.Name == "Puits" and puits:FindFirstChild("Dallage")
		if dallage and dallage:IsA("BasePart") then
			for _, tonneau in village:GetDescendants() do
				local corps = tonneau:IsA("Model") and tonneau.Name == "Tonneau" and tonneau:FindFirstChild("Corps")
				if corps and corps:IsA("BasePart") then
					local ecart = (corps.Position - dallage.Position) * Vector3.new(1, 0, 1)
					if ecart.Magnitude > 0.1 and ecart.Magnitude < 6.1 then
						tonneau:TranslateBy(ecart.Unit * (6.1 - ecart.Magnitude))
					end
				end
			end
		end
	end
	-- Tonneaux, seaux, baquets, chopes : cylindres en bois au lieu de « planches » (rayures sur les cylindres)
	for _, p in village:GetDescendants() do
		if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and p.Material == Enum.Material.WoodPlanks and p.Name ~= "Porte" then
			p.Material = Enum.Material.Wood
		end
	end
	-- Enseignes des marchands (Comptoir des minerais, Pioches & outils)
	local textes = {["COMPTOIR DES MINERAIS"] = true, ["PIOCHES & OUTILS"] = true}
	for _, planche in village:GetDescendants() do
		if planche:IsA("BasePart") and planche.Name == "Enseigne" and planche.Parent then
			local gui = planche:FindFirstChild("TexteFront")
			local label = gui and gui:FindFirstChild("Label")
			local texte = label and label:IsA("TextLabel") and label.Text
			local groupe = planche.Parent
			local dejaAJour = groupe.Name == "EnseigneStand" and groupe:GetAttribute("VersionEnseigne") == VERSION_ENSEIGNE
			if texte and textes[texte] and not dejaAJour then
				local e, couleur, parent
				if groupe.Name == "EnseigneStand" then
					e, couleur, parent = groupe:GetAttribute("Base"), groupe:GetAttribute("Couleur"), groupe.Parent
					groupe:Destroy()
				else
					e, parent = planche.CFrame * CFrame.new(0, -12.45, -5.05), groupe -- ancienne enseigne : e * (0, 12.45, 5.05)
					for _, d in piecesProches(groupe, {PoteauEnseigne = true, Pommeau = true, Lisere = true, Suspension = true}, e.Position, 8) do
						if d.Name == "Lisere" and d:IsA("BasePart") then couleur = d.Color end
						if d:IsA("BasePart") and d.Position.Y < e.Position.Y + 5 and d.Name ~= "PoteauEnseigne" then continue end
						d:Destroy()
					end
					planche:Destroy()
				end
				if typeof(e) == "CFrame" and parent then
					enseigneStand(parent, e, texte, 10, if typeof(couleur) == "Color3" then couleur else C.BoisFonce)
				end
			end
		end
	end
end

-- Chemins décoratifs posés sur le terrain réel, y compris sur les cartes figées.
function Village.preparerSentiers(village)
	local anciens = village:FindFirstChild("SentiersFontaine")
	if anciens and anciens:GetAttribute("VersionSentiers") == 13 then
		return
	end
	local sentiers = O.modele(village, "SentiersEnConstruction")
	local rng = Random.new(43672)
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {workspace.Terrain}
	local terre = Color3.fromRGB(97, 91, 103)
	-- Pierres usées gris-violet, avec des nuances froides proches les unes des autres.
	local pierres = {Color3.fromRGB(103, 98, 112), Color3.fromRGB(117, 111, 124), Color3.fromRGB(90, 88, 102), Color3.fromRGB(108, 102, 115), Color3.fromRGB(99, 98, 109)}
	local function hauteur(x, z)
		local resultat = workspace:Raycast(Vector3.new(x, 180, z), Vector3.new(0, -300, 0), filtre)
		if resultat and resultat.Material ~= Enum.Material.Water then
			return resultat.Position.Y
		end
		return nil
	end
	-- Pendant le tracé des nouveaux chemins : vrai si le sol est déjà pavé à cet endroit (évite deux dalles au même niveau)
	local occupe = nil
	local function terreAuSol(x, z, diametre)
		if occupe and occupe(x, z) then return end
		local h = hauteur(x, z)
		if not h then return end
		-- Des disques superposés forment des bords arrondis et évitent les trous.
		local p = O.decor(O.cylindre(sentiers, 0.12, diametre * rng:NextNumber(0.94, 1.06), CFrame.new(x, h + 0.05 + rng:NextNumber(0, 0.004), z), terre, M.Paves, "Terre"))
		p.CastShadow = false
	end
	local function pave(x, z)
		if occupe and occupe(x, z) then return end
		local h = hauteur(x, z)
		if not h then return end
		local p = O.decor(O.bloc(sentiers, Vector3.new(rng:NextNumber(0.6, 1.4), 0.11, rng:NextNumber(0.7, 1.55)), CFrame.new(x, h + 0.14, z) * CFrame.Angles(0, rng:NextNumber(-0.65, 0.65), 0), pierres[rng:NextInteger(1, #pierres)], M.Pierre, "Pave"))
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
	-- Ajout séparé pour conserver le dessin existant de la terre et des premiers pavés.
	local repartition = Random.new(73591)
	for i = 0, 107 do
		local angle = (i + repartition:NextNumber(-0.35, 0.35)) * 2 * math.pi / 108
		local r = repartition:NextNumber(12.5, 19.1)
		pave(r * math.cos(angle), r * math.sin(angle))
	end
	local function pavesAllee(x1, z1, x2, z2, largeur)
		local debut, fin = Vector2.new(x1, z1), Vector2.new(x2, z2)
		local direction = fin - debut
		local normal = Vector2.new(-direction.Y, direction.X).Unit
		local nombre = math.ceil(direction.Magnitude / 2.8)
		for i = 0, nombre do
			local position = debut:Lerp(fin, i / nombre)
			for _ = 1, 3 do
				local lateral = repartition:NextNumber(-largeur * 0.38, largeur * 0.38)
				local longitudinal = repartition:NextNumber(-1, 1)
				local cible = position + normal * lateral + direction.Unit * longitudinal
				pave(cible.X, cible.Y)
			end
		end
	end
	pavesAllee(0, -15, 0, -96, 10)
	pavesAllee(0, -89, -14.5, -97, 8)
	pavesAllee(0, 15, 0, D.RIVIERE_Z - 16, 9)
	-- Pierres supplémentaires, espacées et irrégulières, sans modifier le tracé.
	local ajouts = Random.new(29604)
	for i = 0, 47 do
		local angle = (i + ajouts:NextNumber(-0.4, 0.4)) * math.pi * 2 / 48
		local distance = ajouts:NextNumber(12.6, 18.8)
		pave(distance * math.cos(angle), distance * math.sin(angle))
	end
	local function ajouterPaves(x1, z1, x2, z2, largeur)
		local debut, fin = Vector2.new(x1, z1), Vector2.new(x2, z2)
		local direction = fin - debut
		local normal = Vector2.new(-direction.Y, direction.X).Unit
		local nombre = math.ceil(direction.Magnitude / 2)
		for i = 0, nombre do
			local centre = debut:Lerp(fin, i / nombre)
			local cible = centre + normal * ajouts:NextNumber(-largeur * 0.38, largeur * 0.38)
				+ direction.Unit * ajouts:NextNumber(-0.9, 0.9)
			pave(cible.X, cible.Y)
		end
	end
	ajouterPaves(0, -15, 0, -96, 10)
	ajouterPaves(0, -89, -14.5, -97, 8)
	ajouterPaves(0, 15, 0, D.RIVIERE_Z - 16, 9)
	-- Assises et bordures suivent la même courbe que le chemin d'origine.
	local function dalle(x, z, taille, angle, nom, couleur)
		if occupe and occupe(x, z, nom == "Bordure") then return end
		local h = hauteur(x, z)
		if not h then return end
		local p = O.decor(O.bloc(sentiers, Vector3.new(taille.X, 0.1, taille.Y), CFrame.new(x, h + 0.205, z) * CFrame.Angles(0, angle, 0), couleur, M.Pierre, nom))
		p.CastShadow = false
	end
	local bordure = Color3.fromRGB(79, 74, 88)
	for i = 0, 47 do
		local angle = i * math.pi * 2 / 48
		local ca, sa = math.cos(angle), math.sin(angle)
		-- Les allées couvrent ces secteurs : éviter deux dalles au même niveau.
		if math.abs(15.8 * ca) > 4.6 then
			dalle(15.8 * ca, 15.8 * sa, Vector2.new(5.5, 1.7), -angle, "DalleReguliere", pierres[i % #pierres + 1])
		end
		for _, rayonBord in {12.1, 19.5} do
			-- Ouvertures face aux allées, afin de ne pas barrer leur raccord.
			if math.abs(rayonBord * ca) > 5.3 then
				dalle(rayonBord * ca, rayonBord * sa, Vector2.new(0.45, rayonBord * 2 * math.sin(math.pi / 48)), -angle, "BordureCourbe", bordure)
			end
		end
		if i % 8 == 2 then
			local h = hauteur(20.1 * ca, 20.1 * sa)
			if h then
				O.decor(O.ellipsoide(sentiers, Vector3.new(1.1, 0.28, 0.8), CFrame.new(20.1 * ca, h + 0.15, 20.1 * sa), Color3.fromRGB(70, 91, 66), M.Herbe, "VerdureBordure"))
			end
		end
	end
	local function paverAllee(x1, z1, x2, z2, largeur, raccordGare)
		local debut, fin = Vector2.new(x1, z1), Vector2.new(x2, z2)
		local direction = fin - debut
		local normal = Vector2.new(-direction.Y, direction.X).Unit
		local nombre = math.ceil(direction.Magnitude / 3)
		local angle = math.atan2(-direction.X, -direction.Y)
		for i = 0, nombre do
			local centre = debut:Lerp(fin, i / nombre)
			for j = -1, 1 do
				local position = centre + normal * j * largeur * 0.3
				if not raccordGare or position.X < -5.2 then
					dalle(position.X, position.Y, Vector2.new(largeur * 0.29, direction.Magnitude / nombre - 0.04), angle, "DalleReguliere", pierres[(i + j + 1) % #pierres + 1])
				end
			end
			for _, signe in {-1, 1} do
				local position = centre + normal * signe * largeur * 0.49
				-- ouverture là où la rue circulaire croise l'allée (pas de bordure en travers de la rue)
				local croiseAnneau = math.abs(centre.Magnitude - Village.RUES.ANNEAU) < 3.6
				if (not raccordGare or position.X < -5.2) and (raccordGare or math.abs(centre.Y) > 19.5) and not croiseAnneau then
					dalle(position.X, position.Y, Vector2.new(0.45, direction.Magnitude / nombre - 0.02), angle, "Bordure", bordure)
				end
			end
		end
	end
	paverAllee(0, -15, 0, -96, 10)
	paverAllee(0, -89, -14.5, -97, 8, true)
	paverAllee(0, 15, 0, D.RIVIERE_Z - 16, 9)
	-- Extrémité en demi-cercle côté gare : elle reste décorative et hors de la voie.
	local finGare = Vector2.new(-14.5, -97)
	local axeGare = (finGare - Vector2.new(0, -89)).Unit
	local normalGare = Vector2.new(-axeGare.Y, axeGare.X)
	for i = 0, 11 do
		local theta = -math.pi / 2 + (i + 0.5) * math.pi / 12
		local direction = axeGare * math.cos(theta) + normalGare * math.sin(theta)
		local position = finGare + direction * 3.9
		dalle(position.X, position.Y, Vector2.new(0.45, 1.03), math.atan2(-direction.Y, direction.X), "BordureTerminusGare", bordure)
	end
	-- Chemins vers toutes les maisons et boutiques, dans le même style (terre, pavés, dalles, bordures).
	-- Le point d'arrivée est l'attribut « Accueil » posé par Village.construire sur chaque bâtiment.
	-- L'allée du sud est prolongée après le pont pour les maisons de l'autre rive.
	-- Couloirs déjà pavés (allées d'origine) : un nouveau chemin ne repose rien dessus.
	local couloirs = {
		{Vector2.new(0, -15), Vector2.new(0, -96), 5},
		{Vector2.new(0, -89), Vector2.new(-14.5, -97), 4},
		{Vector2.new(0, 15), Vector2.new(0, D.RIVIERE_Z - 16), 4.5},
	}
	local function dansCouloir(q, c)
		local d = c[2] - c[1]
		local t = math.clamp((q - c[1]):Dot(d) / d:Dot(d), 0, 1)
		return (q - (c[1] + d * t)).Magnitude < c[3] + 0.4
	end
	local tous = {} -- couloirs de tous les nouveaux chemins (les bordures s'arrêtent à l'entrée des autres)
	local function relier(c)
		local x1, z1, x2, z2, largeur = c[1].X, c[1].Y, c[2].X, c[2].Y, c[3] * 2
		occupe = function(x, z, bordure)
			local q = Vector2.new(x, z)
			local r = q.Magnitude
			if r > 11.6 and r < 20.2 then
				return true -- anneau de la fontaine
			end
			for _, autre in couloirs do
				-- les côtés de la rue circulaire ne coupent pas les bordures les uns des autres
				if dansCouloir(q, autre) and not (bordure and c.anneau and autre.anneau) then
					return true
				end
			end
			if bordure then
				for _, autre in tous do
					if autre ~= c and not (c.anneau and autre.anneau) and dansCouloir(q, autre) then
						return true
					end
				end
			end
			return false
		end
		allee(x1, z1, x2, z2, largeur)
		pavesAllee(x1, z1, x2, z2, largeur)
		paverAllee(x1, z1, x2, z2, largeur)
		occupe = nil
		table.insert(couloirs, c)
	end
	-- ===== Réseau de rues ordonné (version 12) =====
	-- Rue circulaire autour de la place, rues ouest et est entre les boutiques (maisons alignées de part et d'autre),
	-- rue du sud après le pont, puis une courte allée perpendiculaire de chaque rue jusqu'à chaque porte.
	-- Aucun lampadaire ici : l'éclairage est placé à la main dans lanternes() (entrées, croisements, pont).
	local RU = Village.RUES
	local sudDebut = D.RIVIERE_Z + 16
	local function rue(a, b, largeur, anneau)
		local c = {a, b, largeur / 2}
		c.anneau = anneau
		table.insert(tous, c)
		return c
	end
	-- rue circulaire : polygone de 36 côtés (les bordures des côtés voisins se raccordent sans trou)
	local COTES = 36
	for k = 0, COTES - 1 do
		local a1, a2 = k / COTES * math.pi * 2, (k + 1) / COTES * math.pi * 2
		rue(Vector2.new(math.cos(a1), math.sin(a1)) * RU.ANNEAU, Vector2.new(math.cos(a2), math.sin(a2)) * RU.ANNEAU, 6, true)
	end
	rue(Vector2.new(-RU.ANNEAU + 2, RU.OUEST_Z), Vector2.new(-RU.FIN_X, RU.OUEST_Z), 6)
	rue(Vector2.new(RU.ANNEAU - 2, RU.EST_Z), Vector2.new(RU.FIN_X, RU.EST_Z), 6)
	rue(Vector2.new(0, sudDebut), Vector2.new(0, RU.SUD_FIN + 2), 9)

	-- allées perpendiculaires vers les portes (attribut « Accueil » de chaque bâtiment)
	local axes = {}
	for _, c in couloirs do
		table.insert(axes, c)
	end
	for _, c in tous do
		table.insert(axes, c)
	end
	local function plusProche(p)
		local meilleur, distance, axe = nil, math.huge, nil
		for _, c in axes do
			local d = c[2] - c[1]
			local t = math.clamp((p - c[1]):Dot(d) / d:Dot(d), 0, 1)
			local q = c[1] + d * t
			local dist = (p - q).Magnitude
			if dist < distance then
				meilleur, distance, axe = q, dist, c
			end
		end
		return meilleur, distance, axe
	end
	local allees = {} -- allées vers les portes : 2 lampadaires face à face, de part et d'autre
	for _, d in village:GetDescendants() do
		if d:IsA("Model") then
			local accueil = d:GetAttribute("Accueil")
			if typeof(accueil) == "Vector3" and d.Name ~= "Taverne" then
				local p = Vector2.new(accueil.X, accueil.Z)
				local q, distance, axe = plusProche(p)
				if q and distance > 2.5 and distance < 70 then
					table.insert(allees, {rue(q, p, math.min(5, d:GetAttribute("LargeurAllee") or 4.5)), axe[3]})
				end
			end
		end
	end
	for _, c in tous do
		relier(c)
	end
	for _, a in allees do
		local c, demiRue = a[1], a[2]
		local direction = c[2] - c[1]
		local longueur = direction.Magnitude
		-- au milieu de la partie de l'allée hors de la rue, sans toucher la façade
		local t = math.clamp((demiRue + 1 + longueur - 1.5) / 2, math.min(demiRue + 1, longueur - 1.5), longueur - 1.5)
		local centre = c[1] + direction.Unit * t
		local normal = Vector2.new(-direction.Unit.Y, direction.Unit.X)
		for _, signe in {-1, 1} do
			local pos = centre + normal * signe * (c[3] + 1.2)
			local h = hauteur(pos.X, pos.Y)
			if h then
				B.lanterne(sentiers, vers(Vector3.new(pos.X, h, pos.Y), Vector3.new(centre.X, h, centre.Y)))
			end
		end
	end
	sentiers:SetAttribute("VersionSentiers", 13)
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

-- Bâtiment d'un vendeur : plus grand qu'une maison, façade collée juste derrière le stand.
-- direction : vers le bâtiment depuis la place ; facadeR : distance de la place à laquelle arrive la façade.
-- Renvoie le modèle, son repère (façade vers la place), sa largeur et la position locale (z) de la façade.
local function batimentVendeur(m, direction, facadeR, o)
	local u = Vector3.new(direction.X, 0, direction.Z).Unit
	local cf = vers(u * (facadeR + 14), Vector3.zero)
	local maison, porte = B.maison(m, cf, o)
	local bcf, taille = maison:GetBoundingBox()
	local avant, largeur = math.huge, 0
	local avantPorte = porte and porte.Position:Dot(u) -- le mur de façade : la porte (et pas les fleurs ou l'auvent qui dépassent)
	for _, sx in {-1, 1} do
		for _, sz in {-1, 1} do
			for _, sy in {-1, 1} do
				local coin = bcf:PointToWorldSpace(Vector3.new(sx * taille.X / 2, sy * taille.Y / 2, sz * taille.Z / 2))
				avant = math.min(avant, coin:Dot(u))
				largeur = math.max(largeur, math.abs((coin - cf.Position):Dot(cf.RightVector)) * 2)
			end
		end
	end
	avant = avantPorte or avant
	local decal = avant - facadeR -- on avance (ou recule) tout le bâtiment pour coller la façade au stand
	maison:PivotTo(maison:GetPivot() - u * decal)
	cf = cf - u * decal
	return maison, cf, largeur, -(cf.Position:Dot(u) - facadeR)
end

-- Enseigne à l'AVANT du stand, au-dessus du bord de l'auvent (avant : derrière l'auvent, cachée de près) :
-- deux poteaux montés sur les poteaux avant du comptoir, planche face à la rue, lanternes devant.
-- Modèle « EnseigneStand » (attributs Texte, VersionEnseigne) : Village.preparerAteliers le pose aussi sur les cartes figées.
function enseigneStand(m, e, texte, largeur, couleur)
	local g = O.modele(m, "EnseigneStand")
	g:SetAttribute("Texte", texte)
	g:SetAttribute("Couleur", couleur)
	g:SetAttribute("VersionEnseigne", VERSION_ENSEIGNE)
	local l = largeur
	for _, x in {-l / 2, l / 2} do
		O.bloc(g, Vector3.new(0.7, Y_ENSEIGNE + 1.9, 0.7), e * CFrame.new(x, (Y_ENSEIGNE + 1.9) / 2, -1.2), C.BoisFonce, M.Bois, "PoteauEnseigne")
		O.decor(O.bloc(g, Vector3.new(0.9, 0.9, 0.9), e * CFrame.new(x, Y_ENSEIGNE + 2.3, -1.2), C.Or, M.Metal, "Pommeau"))
	end
	local planche = O.bloc(g, Vector3.new(l + 1.6, 2.7, 0.45), e * CFrame.new(0, Y_ENSEIGNE, Z_ENSEIGNE), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(planche, Enum.NormalId.Front, texte)
	for _, y in {Y_ENSEIGNE - 1.5, Y_ENSEIGNE + 1.5} do
		O.decor(O.bloc(g, Vector3.new(l + 2, 0.32, 0.6), e * CFrame.new(0, y, Z_ENSEIGNE), couleur, M.Tissu, "Lisere"))
	end
	-- deux lanternes suspendues à des bras de fer, qui éclairent l'enseigne
	for _, s in {-1, 1} do
		O.decor(O.bloc(g, Vector3.new(1.3, 0.18, 0.18), e * CFrame.new(s * (l / 2 + 0.55), Y_ENSEIGNE - 0.35, -1.4), C.Fer, M.Metal, "Bras"))
		B.suspension(g, (e * CFrame.new(s * (l / 2 + 1.1), Y_ENSEIGNE - 0.4, -1.4)).Position, 0.8, C.Fenetre, 14)
	end
	g:SetAttribute("Base", e)
	return planche
end

-- Tour de comptoir en pierre (Gaspard) : coffre-fort et réserve de minerai
local function tourComptoir(m, cf, couleur)
	local t = O.modele(m, "TourComptoir")
	O.bloc(t, Vector3.new(10, 3, 10), cf * CFrame.new(0, 1.5, 0), C.PierreFoncee, M.Pierre, "Socle")
	O.bloc(t, Vector3.new(9, 22, 9), cf * CFrame.new(0, 13, 0), C.Pierre, M.Pierre, "Tour")
	O.bloc(t, Vector3.new(10, 1, 10), cf * CFrame.new(0, 24.5, 0), C.PierreClaire, M.Pierre, "Corniche")
	for k = 0, 3 do -- toit pyramidal d'ardoise (4 pans en coin)
		O.coin(t, Vector3.new(10.4, 8, 5.2), cf * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 29, -2.6) * CFrame.Angles(0, math.pi, 0),
			C.Toit, M.Ardoise, "Toit")
	end
	O.decor(O.bloc(t, Vector3.new(0.8, 3, 0.8), cf * CFrame.new(0, 34.4, 0), C.Or, M.Metal, "Fleche"))
	for _, y in {9, 16} do
		O.decor(O.bloc(t, Vector3.new(2, 3, 0.3), cf * CFrame.new(0, y, -4.6), C.Fenetre, M.Neon, "Fenetre"))
		O.decor(O.bloc(t, Vector3.new(2.6, 0.5, 0.6), cf * CFrame.new(0, y - 1.8, -4.7), C.PierreClaire, M.Pierre, "Appui"))
	end
	O.bloc(t, Vector3.new(4, 6.5, 0.4), cf * CFrame.new(0, 6.25, -4.6), C.Fer, M.Metal, "PorteFerree")
	O.decor(O.bloc(t, Vector3.new(3.2, 6, 0.2), cf * CFrame.new(0, 17, -4.75), couleur, M.Tissu, "Banniere"))
	O.decor(O.bloc(t, Vector3.new(1.2, 1.2, 0.25), cf * CFrame.new(0, 18, -4.9) * CFrame.Angles(0, 0, math.pi / 4), C.Or, M.Metal, "Embleme"))
	return t
end

-- Atelier de Liesel : appentis ouvert, meule, établi, râtelier d'outils et grande pioche-enseigne
local function atelierOutils(m, cf, couleur)
	local a = O.modele(m, "AtelierOutils")
	for _, x in {-5, 5} do
		for _, z in {-4, 4} do
			local h = if z > 0 then 8.5 else 7
			O.bloc(a, Vector3.new(0.7, h, 0.7), cf * CFrame.new(x, h / 2, z), C.BoisFonce, M.Bois, "Poteau")
		end
	end
	O.bloc(a, Vector3.new(11.6, 0.4, 9.6), cf * CFrame.new(0, 7.9, 0) * CFrame.Angles(math.rad(-9), 0, 0), C.ToitRouge, M.Tuiles, "Toit")
	O.bloc(a, Vector3.new(10, 0.5, 8), cf * CFrame.new(0, 0.25, 0), C.Bois, M.Planches, "Plancher")
	O.bloc(a, Vector3.new(6, 3, 2), cf * CFrame.new(-1.5, 1.5, 2.5), C.BoisClair, M.Planches, "Etabli")
	-- meule sur son bâti
	O.bloc(a, Vector3.new(0.5, 3.4, 2.4), cf * CFrame.new(3.2, 1.7, -1.6), C.BoisFonce, M.Bois, "Bati")
	O.bloc(a, Vector3.new(0.5, 3.4, 2.4), cf * CFrame.new(4.6, 1.7, -1.6), C.BoisFonce, M.Bois, "Bati")
	O.disque(a, 0.7, 3.4, cf * CFrame.new(3.9, 3.4, -1.6), C.PierreClaire, M.Granite, "Meule")
	-- râtelier d'outils au fond
	O.bloc(a, Vector3.new(9, 4, 0.4), cf * CFrame.new(0, 3.6, 3.9), C.Bois, M.Planches, "Ratelier")
	for i, c in {C.Fer, Color3.fromRGB(184, 100, 46), C.Fer, C.Or, C.Fer} do
		B.pioche(a, cf * CFrame.new(-3.6 + (i - 1) * 1.8, 3.4, 3.55) * CFrame.Angles(0, math.pi / 2, math.pi / 2), c)
	end
	-- grande pioche-enseigne sur un mât, bien visible depuis la place
	local mat = cf * CFrame.new(-5.6, 0, -5.2)
	O.bloc(a, Vector3.new(0.8, 16, 0.8), mat * CFrame.new(0, 8, 0), C.BoisFonce, M.Bois, "Mat")
	local tete = mat * CFrame.new(0, 15.5, 0) * CFrame.Angles(0, 0, math.rad(35))
	O.decor(O.bloc(a, Vector3.new(0.7, 7, 0.7), tete * CFrame.new(0, -1.5, -0.7), C.BoisClair, M.Bois, "ManchePioche"))
	O.decor(O.bloc(a, Vector3.new(6, 1, 0.9), tete * CFrame.new(0, 2, -0.7), C.Fer, M.Metal, "TetePioche"))
	O.decor(O.bloc(a, Vector3.new(2.6, 3.6, 0.2), mat * CFrame.new(1.6, 11, 0), couleur, M.Tissu, "Fanion"))
	B.tonneau(a, cf * CFrame.new(3.6, 0.5, 1.6)) -- posé sur le plancher, loin du mur, du râtelier et des poteaux
	return a
end

-- Terrasse couverte de la taverne : pergola, guirlandes lumineuses, enseigne sur la poutre de façade
local function terrasseTaverne(m, cf, profondeur, largeur, couleur)
	local t = O.modele(m, "Terrasse")
	local hx, z0, z1 = largeur / 2, -profondeur, 0
	local hausse = TERRASSE_HAUSSE_TOIT
	for _, x in {-hx, hx} do
		for _, z in {z0, z1} do
			O.bloc(t, Vector3.new(0.8, 9 + hausse, 0.8), cf * CFrame.new(x, (9 + hausse) / 2, z), C.BoisFonce, M.Bois, "Poteau")
		end
		O.bloc(t, Vector3.new(0.6, 0.7, profondeur + 1), cf * CFrame.new(x, 9 + hausse, (z0 + z1) / 2), C.Bois, M.Bois, "Poutre")
	end
	for k = 0, 5 do
		O.decor(O.bloc(t, Vector3.new(largeur + 1, 0.4, 0.4), cf * CFrame.new(0, 9.3 + hausse, z0 + k * profondeur / 5), C.Bois, M.Bois, "Chevron"))
	end
	O.bloc(t, Vector3.new(largeur + 1.2, 0.8, 0.7), cf * CFrame.new(0, 9 + hausse, z0), C.BoisFonce, M.Bois, "PoutreFacade")
	-- guirlande de petites lumières qui pend en arcs sur la façade de la terrasse
	for i = 0, 22 do
		local x = -hx + i * largeur / 22
		local creux = math.sin(((i % 11) / 11) * math.pi) * 0.9
		O.decor(O.ellipsoide(t, Vector3.new(0.45, 0.45, 0.45), cf * CFrame.new(x, 8.3 + hausse - creux, z0 - 0.1), Color3.fromRGB(255, 214, 140), M.Neon, "Ampoule"))
	end
	-- enseigne au-dessus de l'entrée de la terrasse
	local planche = O.bloc(t, Vector3.new(16, 2.8, 0.45), cf * CFrame.new(0, 11.2 + hausse, z0 - 0.1), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(planche, Enum.NormalId.Front, "TAVERNE DU PIC DORÉ")
	for _, y in {9.7, 12.7} do
		O.decor(O.bloc(t, Vector3.new(16.4, 0.32, 0.6), cf * CFrame.new(0, y + hausse, z0 - 0.1), couleur, M.Tissu, "Lisere"))
	end
	for _, x in {-8.6, 8.6} do
		O.bloc(t, Vector3.new(0.5, 2.6, 0.5), cf * CFrame.new(x, 10.6 + hausse, z0 - 0.1), C.BoisFonce, M.Bois, "Support")
	end
	return t
end

local function boutiques(v, rng, obstacles)
	local m = O.modele(v, "Boutiques")
	local STAND = 46 -- les stands sont tous à la même distance de la place (rue circulaire juste devant)

	-- ===== Comptoir des minerais (Gaspard) : bâtiment ocre + tour de pierre =====
	local rouge = Color3.fromRGB(150, 58, 46)
	local dir = Vector3.new(-58, 0, -24)
	local maisonComptoir, cf, largeur, facade = batimentVendeur(m, dir, STAND + 6.4, {largeur = 22, echelle = 0.82, mur = C.Ocre, toit = C.Toit,
		volet = Color3.fromRGB(120, 52, 44), nom = "ComptoirMinerais", rng = rng, modele = 2, prestige = true, couleur = rouge})
	table.insert(obstacles, cf.Position)
	tourComptoir(m, cf * CFrame.new(-(largeur / 2 + 5.5), 0, facade + 6), rouge)
	local e = vers(dir.Unit * STAND, Vector3.zero)
	B.echoppe(m, e, 10, rouge)
	enseigneStand(m, e, "COMPTOIR DES MINERAIS", 10, rouge)
	maisonComptoir:SetAttribute("Accueil", sol((e * CFrame.new(0, 0, -3.5)).Position))
	maisonComptoir:SetAttribute("LargeurAllee", 7)
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
		tenue(Color3.fromRGB(92, 70, 50), Color3.fromRGB(54, 46, 40), {
			chapeau = Color3.fromRGB(70, 50, 36), cheveux = Color3.fromRGB(170, 168, 162), barbe = Color3.fromRGB(188, 186, 180),
			peau = Color3.fromRGB(226, 176, 150), outil = "registre",
			fourrure = Color3.fromRGB(120, 98, 74), lueur = Color3.fromRGB(90, 180, 255), -- modèle 3D d'après Gromm
				corps = {hauteur = 1.02, largeur = 1.05},
				-- veste de cuir, feutre en laine, barbe blanche
				accessoires = {{77359892, "Hat"}, {330294871, "Face"}, {7192547628, "Jacket"}},
		}))
	pnj:SetAttribute("Service", "Vente")

	-- ===== Pioches & outils (Liesel) : maison claire à volets bleus + atelier ouvert et grande pioche =====
	local bleu = Color3.fromRGB(52, 84, 140)
	dir = Vector3.new(-53, 0, 34)
	local maisonOutilleur
	maisonOutilleur, cf, largeur, facade = batimentVendeur(m, dir, STAND + 6.4, {largeur = 24, echelle = 0.85, mur = C.Platre, toit = C.ToitRouge,
		volet = Color3.fromRGB(60, 70, 104), nom = "Outilleur", lierreFacade = false, rng = rng, modele = 3, prestige = true, couleur = bleu})
	table.insert(obstacles, cf.Position)
	atelierOutils(m, cf * CFrame.new(largeur / 2 + 6, 0, facade + 5), bleu)
	e = vers(dir.Unit * STAND, Vector3.zero)
	B.echoppe(m, e, 10, bleu)
	enseigneStand(m, e, "PIOCHES & OUTILS", 10, bleu)
	maisonOutilleur:SetAttribute("Accueil", sol((e * CFrame.new(0, 0, -3.5)).Position))
	maisonOutilleur:SetAttribute("LargeurAllee", 7)
	for i, c in {Color3.fromRGB(150, 154, 162), Color3.fromRGB(184, 100, 46), Color3.fromRGB(255, 196, 48)} do
		B.pioche(m, e * CFrame.new(-3 + (i - 1) * 3, 3.55, 0) * CFrame.Angles(0, 0.25 * (i - 2), 0), c)
	end
	B.tonneau(m, e * CFrame.new(7, 0, 1))
	pnj = B.pnj(m, e * CFrame.new(0, 0, 2.6), "Liesel", "Fabricante d'outils",
		tenue(Color3.fromRGB(58, 44, 36), Color3.fromRGB(84, 70, 54), {
			tablier = Color3.fromRGB(96, 66, 44), coiffure = "chignon", cheveux = Color3.fromRGB(178, 70, 30),
			peau = Color3.fromRGB(240, 196, 170), outil = "pioche",
			barbe = Color3.fromRGB(178, 70, 30), lueur = Color3.fromRGB(255, 140, 40), -- modèle 3D d'après Brunhilde
			corps = {hauteur = 0.95, largeur = 0.9, proportions = 0.6},
			-- tresse rousse, lunettes d'atelier, veste en jean
			accessoires = {{7193455510, "Hair"}, {2316756148, "Face"}, {8516609675, "Jacket"}},
		}))
	pnj:SetAttribute("Service", "Outils")

	-- ===== La forge (Brom) : inchangée, sa silhouette ouverte la distingue déjà =====
	local pos = Vector3.new(60, 0, -12)
	table.insert(obstacles, pos)
	cf = vers(pos, Vector3.zero)
	local forge = B.forge(m, cf)
	forge:SetAttribute("Accueil", sol((cf * CFrame.new(0, 0, -12.5)).Position))
	forge:SetAttribute("LargeurAllee", 7)
	pnj = B.pnj(m, cf * CFrame.new(2, 1, 2.2), "Brom", "Forgeron",
		tenue(Color3.fromRGB(72, 48, 32), Color3.fromRGB(74, 60, 46),
			{peau = Color3.fromRGB(214, 160, 128), barbe = Color3.fromRGB(62, 42, 30), barbeLongue = true, coiffure = "chauve",
			cheveux = Color3.fromRGB(56, 38, 28), tablier = Color3.fromRGB(70, 46, 30), manchesCourtes = true, outil = "marteau",
			lueur = Color3.fromRGB(255, 96, 20), -- modèle 3D d'après Zog
				corps = {hauteur = 1.05, largeur = 1.2, silhouette = 0.6},
				-- barbe rousse tressée, lunettes de forge
				accessoires = {{461491285, "Face"}, {108828585, "Face"}}}))
	pnj:SetAttribute("Service", "Forge")
	B.tonneau(m, cf * CFrame.new(-13.5, 0, -6))
	B.caisse(m, cf * CFrame.new(13.6, 0, -4), 2.4)

	-- ===== La taverne (Margot) : la plus grande, terrasse couverte et guirlandes =====
	local dore = Color3.fromRGB(196, 150, 44)
	dir = Vector3.new(57, 0, 36)
	local ensembleTaverne = O.modele(m, "EnsembleTaverne")
	local taverne
	taverne, cf, largeur, facade = batimentVendeur(ensembleTaverne, dir, STAND + 9 + TAVERNE_RECUL, {largeur = 26, echelle = 0.98, mur = Color3.fromRGB(238, 222, 196),
		toit = C.ToitRouge, volet = C.Volet, nom = "Taverne", rng = rng, modele = 1, prestige = true, couleur = dore})
	table.insert(obstacles, cf.Position)
	local devant = cf * CFrame.new(0, 0, facade) -- pied de la façade
	terrasseTaverne(ensembleTaverne, devant, 8.5, 22, dore)
	-- Applique sur le mur latéral, côté sombre entre la taverne et le chemin.
	local applique = O.modele(ensembleTaverne, "AppliqueCoteTaverne")
	local lanterneCote = B.applique(applique, devant * CFrame.new(TAVERNE_LANTERNE_COTE) * CFrame.Angles(0, -math.pi / 2, 0))
	local lumiereCote = lanterneCote:FindFirstChildWhichIsA("PointLight", true)
	if lumiereCote then lumiereCote.Range = TAVERNE_LANTERNE_PORTEE end
	taverne:SetAttribute("Accueil", sol((devant * CFrame.new(0, 0, -11.5)).Position))
	taverne:SetAttribute("LargeurAllee", 7)
	for _, x in {-TERRASSE_ESPACEMENT_TABLES, 0, TERRASSE_ESPACEMENT_TABLES} do
		B.tableTaverne(ensembleTaverne, devant * CFrame.new(x, 0, -5.2 - TERRASSE_AVANCE_TABLES))
	end
	for i, x in {-TERRASSE_ECART_TONNEAUX, TERRASSE_ECART_TONNEAUX} do
		B.tonneau(ensembleTaverne, devant * CFrame.new(x, 0, -1.5 - TERRASSE_AVANCE_TABLES))
		B.tonneau(ensembleTaverne, devant * CFrame.new(x, 0, -4 - TERRASSE_AVANCE_TABLES))
		local repereHaut = devant * CFrame.new(x, 3.25, -2.75 - TERRASSE_AVANCE_TABLES) * CFrame.Angles(0, i, 0)
		local tonneauHaut = B.tonneau(ensembleTaverne, repereHaut) -- posé sur les deux autres
		if i == 1 then
			-- Parentée au tonneau pour suivre ses éventuels ajustements au sol.
			local lanterne = Lampadaires.lanterne(tonneauHaut, repereHaut * CFrame.new(0, 3.81, 0), nil, 18)
			lanterne.Name = "LanterneTonneauxMargot"
		end
	end
	pnj = B.pnj(ensembleTaverne, devant * CFrame.new(TERRASSE_POSITION_MARGOT), "Margot", "Aubergiste",
		tenue(Color3.fromRGB(70, 50, 36), Color3.fromRGB(76, 58, 42), {
			tablier = Color3.fromRGB(230, 220, 200), coiffure = "long", cheveux = Color3.fromRGB(172, 72, 32),
			peau = Color3.fromRGB(232, 180, 150), outil = "chope",
			fourrure = Color3.fromRGB(112, 90, 68), lueur = Color3.fromRGB(255, 196, 70), -- modèle 3D d'après Brolg
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

-- Plan des rues du village (repris par preparerSentiers et lanternes) : rue circulaire autour de la place,
-- rues ouest et est entre les boutiques, rue du sud après le pont. Les maisons sont alignées, façade sur la rue.
Village.RUES = {
	ANNEAU = 43, -- rayon de la rue circulaire (elle passe devant les comptoirs des PNJ)
	OUEST_Z = 6, -- axe de la rue ouest (entre le comptoir et l'outilleur)
	EST_Z = 8.5, -- axe de la rue est (entre la forge et la taverne)
	FIN_X = 146, -- bout des rues ouest et est
	SUD_FIN = 132, -- bout de la rue du sud (la maison du bout est 10 plus loin ; au-delà de z = 144, le terrain monte)
}
local R = Village.RUES

-- {x, z, largeur, profondeur, étages}
local MAISONS = {
	-- rue ouest : rangée nord (façade au sud) et rangée sud (façade au nord)
	{-102, R.OUEST_Z - 15, 18, 14, 2, Vector3.new(-102, 0, R.OUEST_Z)}, {-130, R.OUEST_Z - 15, 16, 14, 1, Vector3.new(-130, 0, R.OUEST_Z)},
	{-102, R.OUEST_Z + 15, 16, 14, 1, Vector3.new(-102, 0, R.OUEST_Z)}, {-130, R.OUEST_Z + 15, 20, 15, 2, Vector3.new(-130, 0, R.OUEST_Z)},
	-- rue est
	{102, R.EST_Z - 15, 16, 14, 1, Vector3.new(102, 0, R.EST_Z)}, {130, R.EST_Z - 15, 20, 15, 2, Vector3.new(130, 0, R.EST_Z)},
	{102, R.EST_Z + 15, 18, 14, 2, Vector3.new(102, 0, R.EST_Z)}, {130, R.EST_Z + 15, 16, 14, 1, Vector3.new(130, 0, R.EST_Z)},
	-- rue du sud, après le pont : deux maisons de chaque côté et une au bout de la rue
	-- (le terrain monte au-delà de z = 144 : la maison du bout reste juste avant la pente)
	{-19, 108, 16, 14, 1, Vector3.new(0, 0, 108)}, {19, 108, 16, 14, 2, Vector3.new(0, 0, 108)},
	{-19, 127, 16, 14, 2, Vector3.new(0, 0, 127)}, {19, 127, 16, 14, 1, Vector3.new(0, 0, 127)},
	{0, R.SUD_FIN + 10, 20, 14, 2, Vector3.new(0, 0, 0)},
}

local function maisons(v, rng, obstacles)
	local m = O.modele(v, "Maisons")
	for i, d in MAISONS do
		local pos = Vector3.new(d[1], 0, d[2])
		table.insert(obstacles, pos)
		local cf = vers(pos, d[6])
		local maison, porte = B.maison(m, cf, {
			largeur = d[3], profondeur = d[4], etages = d[5], rng = rng, nom = "Maison" .. i, modele = (i - 1) % 4 + 1,
			mur = MURS[rng:NextInteger(1, #MURS)], toit = TOITS[rng:NextInteger(1, #TOITS)], volet = VOLETS[rng:NextInteger(1, #VOLETS)],
		})
		-- une courte allée pavée (preparerSentiers) relie la porte à la rue
		maison:SetAttribute("Accueil", sol((porte * CFrame.new(0, 0, -3.4)).Position))
		if rng:NextNumber() < 0.6 then
			B.tonneau(m, porte * CFrame.new(-3.6, -1.6, -1.6))
		end
	end

	-- Entrepôts près de la gare
	for _, x in {-62, 62} do
		local pos = Vector3.new(x, 0, -86)
		table.insert(obstacles, pos)
		local cf = vers(pos, Vector3.new(0, 0, -86))
		local entrepot, porte = B.maison(m, cf, {largeur = 24, profondeur = 16, etages = 1, mur = C.PlatreGris, toit = C.Toit,
			nom = "Entrepot", enseigne = "ENTREPÔT", cheminee = false, rng = rng, modele = 4})
		entrepot:SetAttribute("Accueil", sol((porte * CFrame.new(0, 0, -3.4)).Position))
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
	local moulin, porteMoulin = B.maison(m, cfMoulin, {largeur = 16, profondeur = 14, etages = 1, mur = C.Ocre, toit = C.Toit, nom = "Moulin", rng = rng, modele = 4})
	moulin:SetAttribute("Accueil", sol((porteMoulin * CFrame.new(0, 0, -3.4)).Position))
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

-- Éclairage réduit à l'essentiel (avant : un lampadaire tous les 13 studs le long de chaque chemin) :
-- 4 autour de la place, 2 paires sur l'avenue, l'entrée / le milieu / le bout des rues ouest et est,
-- 2 sur l'allée et la rue du sud (+ les 4 lanternes du pont, dans riviere).
local function lanternes(v)
	local m = O.modele(v, "Eclairage")
	-- avenue de la gare
	for _, z in {-56, -82} do
		for _, x in {-9.5, 9.5} do
			B.lanterne(m, vers(Vector3.new(x, 0, z), Vector3.new(0, 0, z)))
		end
	end
	-- place : diagonales, décalées pour ne pas masquer les enseignes de la taverne et de l'outilleur
	for _, angle in {45, 150, 210, 315} do
		B.lanterne(m, vers(polaire(math.rad(angle), D.PLACE_RAYON + 3), Vector3.zero))
	end
	-- rues ouest et est : entrée sur la rue circulaire, milieu entre les maisons, bout de la rue
	local entree = R.ANNEAU + 5
	for _, p in {
		Vector3.new(-entree, 0, R.OUEST_Z - 5), Vector3.new(-116, 0, R.OUEST_Z + 4.5), Vector3.new(-R.FIN_X + 2, 0, R.OUEST_Z - 4.5),
		Vector3.new(entree, 0, R.EST_Z + 5), Vector3.new(116, 0, R.EST_Z - 4.5), Vector3.new(R.FIN_X - 2, 0, R.EST_Z + 4.5),
	} do
		B.lanterne(m, vers(p, Vector3.new(p.X, 0, if p.X < 0 then R.OUEST_Z else R.EST_Z)))
	end
	-- allée du pont et rue du sud
	B.lanterne(m, vers(Vector3.new(6, 0, 50), Vector3.new(0, 0, 50)), 9)
	B.lanterne(m, vers(Vector3.new(7.5, 0, 117.5), Vector3.new(0, 0, 117.5)), 9)
end

local function classements(v)
	local m = O.modele(v, "Classements")
	B.classement(m, vers(Vector3.new(-24, 0, -44), Vector3.new(0, 0, 4)), "Meilleurs Mineurs", "Pieces")
	B.classement(m, vers(Vector3.new(24, 0, -44), Vector3.new(0, 0, 4)), "Plus Profonds", "Profondeur")
end

local function decor(v, rng, obstacles)
	local m = O.modele(v, "Decor")
	-- puits entre l'allée du pont et le moulin, à l'écart de l'allée du moulin
	local puits = Vector3.new(-15, 0, 64)
	table.insert(obstacles, puits)
	B.puits(m, CFrame.new(puits))
	B.tonneau(m, CFrame.new(-8.6, 0, 67.6)) -- hors du dallage du puits
	B.caisse(m, CFrame.new(-19.5, 0, 68.5) * CFrame.Angles(0, 0.4, 0))

	-- Lueurs qui flottent au-dessus de la place
	local zone = O.decor(O.bloc(m, Vector3.new(90, 8, 90), CFrame.new(0, 6, 0), Color3.new(1, 1, 1), M.Lisse, "ZoneLucioles"))
	zone.Transparency = 1
	O.lucioles(zone, Color3.fromRGB(255, 210, 140), 10)
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
					if rng:NextNumber() < 0.25 then B.sapin(f, base, rng:NextNumber(26, 40), rng) else B.pin(f, base, rng:NextNumber(22, 38), rng) end
				elseif math.abs(z - D.RIVIERE_Z) < 40 then
					B.saule(f, base, rng:NextNumber(20, 27), rng) -- saules pleureurs au bord de la rivière
				else
					if rng:NextNumber() < 0.25 then B.sapin(f, base, rng:NextNumber(26, 40), rng) else B.pin(f, base, rng:NextNumber(22, 38), rng) end
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
-- ================= Rendu propre : rues dégagées, terrain aplani, bosquets =================

-- Couloirs des rues (centre, demi-largeur) : rien ne doit y pousser ni y être posé
local function couloirsRues(): {{any}}
	local moulinPorte = Vector2.new(-34, 49.6)
	local c = {
		{Vector2.new(0, -30), Vector2.new(0, -100), 7.5}, -- avenue de la gare
		{Vector2.new(0, -89), Vector2.new(-14.5, -97), 4},
		{Vector2.new(0, 15), Vector2.new(0, 66), 4.5}, -- allée du pont
		{Vector2.new(0, 66), Vector2.new(0, 98), 6}, -- pont
		{Vector2.new(0, 98), Vector2.new(0, R.SUD_FIN + 2), 4.5}, -- rue du sud
		{Vector2.new(-R.ANNEAU + 2, R.OUEST_Z), Vector2.new(-R.FIN_X, R.OUEST_Z), 3},
		{Vector2.new(R.ANNEAU - 2, R.EST_Z), Vector2.new(R.FIN_X, R.EST_Z), 3},
		{Vector2.new(0, -86), Vector2.new(-51, -86), 2.5}, -- allées des entrepôts
		{Vector2.new(0, -86), Vector2.new(51, -86), 2.5},
		{moulinPorte.Unit * R.ANNEAU, moulinPorte, 2.5}, -- allée du moulin
	}
	return c
end

local function distanceSegment(q: Vector2, a: Vector2, b: Vector2): number
	local d = b - a
	local t = math.clamp((q - a):Dot(d) / d:Dot(d), 0, 1)
	return (q - (a + d * t)).Magnitude
end

-- Vrai si (x, z) est sur une rue, la place ou la rue circulaire (avec une marge)
local function surRue(x: number, z: number, marge: number): boolean
	local q = Vector2.new(x, z)
	local r = q.Magnitude
	if r < 40 + marge or math.abs(r - R.ANNEAU) < 3 + marge then
		return true
	end
	for _, c in couloirsRues() do
		if distanceSegment(q, c[1], c[2]) < c[3] + marge then
			return true
		end
	end
	return false
end

-- Boîtes de tous les bâtiments (maisons, boutiques, forge, taverne, moulin, entrepôts) + leur point d'accueil
local function batiments(v): {{cf: CFrame, taille: Vector3, accueil: Vector3?}}
	local liste = {}
	for _, d in v:GetDescendants() do
		if d:IsA("Model") and (typeof(d:GetAttribute("Accueil")) == "Vector3" or d.Name == "Echoppe") then
			local cf, taille = d:GetBoundingBox()
			table.insert(liste, {cf = cf, taille = taille, accueil = d:GetAttribute("Accueil")})
		end
	end
	return liste
end

-- Distance horizontale d'un point à la boîte d'un bâtiment (0 à l'intérieur)
local function horsBoite(b, x: number, z: number): number
	local l = b.cf:PointToObjectSpace(Vector3.new(x, b.cf.Position.Y, z))
	local dx = math.max(math.abs(l.X) - b.taille.X / 2, 0)
	local dz = math.max(math.abs(l.Z) - b.taille.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

--[[ Aplanit le terrain sous et autour des bâtiments : si le relief déborde dans l'emprise (pied de montagne),
	il est creusé au niveau du village, avec un talus en pente douce jusqu'à 14 studs. ]]
function Village.terrasser(v)
	local terrain = workspace.Terrain
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {terrain}
	local NIVEAU = 2
	local creuses = 0
	for _, b in batiments(v) do
		local demi = math.max(b.taille.X, b.taille.Z) / 2 + 16
		local c = b.cf.Position
		for x = c.X - demi, c.X + demi, 4 do
			for z = c.Z - demi, c.Z + demi, 4 do
				local d = horsBoite(b, x, z)
				local cible = if d <= 4 then NIVEAU else NIVEAU + (d - 4) * 0.85
				if d < 14 then
					local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), filtre)
					local h = r and r.Position.Y
					if h and h > cible + 0.8 and r.Material ~= Enum.Material.Water then
						local haut = h + 6
						terrain:FillBlock(CFrame.new(x, (cible + haut) / 2, z), Vector3.new(4, haut - cible, 4), Enum.Material.Air)
						terrain:FillBlock(CFrame.new(x, cible - 1, z), Vector3.new(4, 2, 4), Enum.Material.Grass)
						creuses += 1
					end
				end
			end
		end
	end
	if creuses > 0 then
		print(string.format("[Village] terrain aplani autour des bâtiments (%d colonnes)", creuses))
	end
end

--[[ Bosquets du village : pins (saules près de l'eau) groupés en petits bois dans les espaces sans maisons,
	jamais sur une rue, devant une porte ou contre un bâtiment. ]]
local function bosquets(v, rng)
	local f = Instance.new("Folder")
	f.Name = "Bosquets"
	f.Parent = v
	local bats = batiments(v)
	local evites = {
		{Vector2.new(-24, -44), 9}, {Vector2.new(24, -44), 9}, -- classements
		{Vector2.new(-76, -67), 6}, {Vector2.new(76, -67), 6}, {Vector2.new(-78, -82), 5}, {Vector2.new(78, -82), 5}, -- décor de la gare
		{Vector2.new(-15, 64), 7}, -- puits
	}
	local n = 0
	for gx = -155, 155, 9 do
		for gz = -112, 150, 9 do
			local x, z = gx + rng:NextNumber(-3.5, 3.5), gz + rng:NextNumber(-3.5, 3.5)
			-- petits bois : un bruit doux décide où ils poussent
			if math.noise(x / 46, z / 46, 3.3) < 0.02 then
				continue
			end
			if surRue(x, z, 5) or math.abs(z - D.RIVIERE_Z) < 16 or (math.abs(x) < 42 and z < -96) then
				continue
			end
			local libre = true
			for _, b in bats do
				if horsBoite(b, x, z) < 7 or (b.accueil and Vector2.new(x - b.accueil.X, z - b.accueil.Z).Magnitude < 10) then
					libre = false
					break
				end
			end
			for _, e in evites do
				if Vector2.new(x, z) - e[1] == Vector2.zero or (Vector2.new(x, z) - e[1]).Magnitude < e[2] then
					libre = false
				end
			end
			if not libre or T.hauteur(x, z) > 5 then
				continue
			end
			local base = Vector3.new(x, T.hauteur(x, z) + 1.4, z)
			if math.abs(z - D.RIVIERE_Z) < 28 and rng:NextNumber() < 0.3 then
				B.saule(f, base, rng:NextNumber(13, 18), rng)
			else
				if rng:NextNumber() < 0.25 then B.sapin(f, base, rng:NextNumber(22, 34), rng) else B.pin(f, base, rng:NextNumber(18, 30), rng) end
			end
			n += 1
		end
	end
	print(string.format("[Village] %d arbres plantés dans les bosquets du village", n))
end

--[[ Dernier passage (après les bordures) : retire tout arbre, rocher, falaise, paroi ou chèvre dont le pied
	tombe dans un bâtiment ou sur une rue. Appelé par Monde.construire. ]]
function Village.degager(carte)
	local v = carte:FindFirstChild("Village")
	if not v then
		return
	end
	local bats = batiments(v)
	local dossiers = {v:FindFirstChild("Nature"), v:FindFirstChild("Falaises"), v:FindFirstChild("Bosquets")}
	local bordures = carte:FindFirstChild("Bordures")
	if bordures then
		for _, nom in {"ForetAltitude", "Parois", "Chevres"} do
			table.insert(dossiers, bordures:FindFirstChild(nom))
		end
	end
	local retires = 0
	for _, dossier in dossiers do
		for _, m in (if dossier then dossier:GetChildren() else {}) do
			if not m:IsA("Model") then
				continue
			end
			local cf, taille = m:GetBoundingBox()
			local pied = cf.Position
			-- emprise au sol : les arbres comptent par leur tronc, les rochers par leur largeur
			local rayon = if m.Name == "Pin" or m.Name == "Sapin" or m.Name == "Saule" or m.Name == "Arbre" then 1.5 else math.min(taille.X, taille.Z) * 0.35
			local gene = surRue(pied.X, pied.Z, rayon)
			if not gene then
				for _, b in bats do
					if horsBoite(b, pied.X, pied.Z) < rayon + 1.5 then
						gene = true
						break
					end
				end
			end
			if gene then
				m:Destroy()
				retires += 1
			end
		end
	end
	if retires > 0 then
		print(string.format("[Village] %d éléments de décor retirés (sur une rue ou dans un bâtiment)", retires))
	end
end

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
	Village.terrasser(v) -- aucun bâtiment à moitié dans le pied d'une montagne
	nature(v, rng, obstacles)
	bosquets(v, Random.new(5150))
	falaises(v, rng)
	cristaux(v, rng)
	Village.preparerToits(v)
	Village.preparerSentiers(v)
end

return Village
