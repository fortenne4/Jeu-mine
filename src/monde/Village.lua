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
	for i, a in {35, 145, 215, 325} do
		B.bancJardinieres(m, vers(polaire(math.rad(a), 29, 2), Vector3.zero), i)
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

-- Cartes figées : remplace les anciens bancs de la place par le banc à jardinières,
-- posé sur le sol réellement visible (terrain ou dallage).
function Village.preparerBancs(village)
	local place = village:FindFirstChild("Place")
	if not place then return end
	local numero = 0
	for _, ancien in place:GetChildren() do
		if ancien:IsA("Model") and ancien.Name == "Banc" and ancien:GetAttribute("VersionBanc") ~= 2 then
			local assise = ancien:FindFirstChild("Assise")
			if assise and assise:IsA("BasePart") then
				numero += 1
				local repere = assise.CFrame * CFrame.new(0, -1.8, 0)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {ancien}
				local touche = workspace:Raycast(repere.Position + Vector3.new(0, 8, 0), Vector3.new(0, -20, 0), params)
				if touche then
					repere = repere.Rotation + Vector3.new(repere.X, touche.Position.Y, repere.Z)
				end
				ancien:Destroy()
				B.bancJardinieres(place, repere, numero)
			end
		end
	end
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
		B.preparerToitForge(forge)
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
		B.preparerAmenagementForge(forge)
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

-- Conserve le bord côté village des pièces qui dépassent sur le pont.
local function raccourcirAuPont(piece, bord, signe, demiLargeur)
	local cf, taille = piece.CFrame, piece.Size
	local demiX = (math.abs(cf.XVector.X) * taille.X + math.abs(cf.YVector.X) * taille.Y + math.abs(cf.ZVector.X) * taille.Z) / 2
	local demiZ = (math.abs(cf.XVector.Z) * taille.X + math.abs(cf.YVector.Z) * taille.Y + math.abs(cf.ZVector.Z) * taille.Z) / 2
	local distance = (piece.Position.Z - bord) * signe
	if math.abs(piece.Position.X) - demiX >= demiLargeur or distance >= demiZ + 0.019 or distance < -2 then
		return
	end

	local longueur = distance + demiZ - 0.02
	if longueur < 0.15 then
		-- Un pavé presque entièrement sur le tablier garde sa taille et recule sur la rive.
		piece.CFrame += Vector3.new(0, 0, signe * (demiZ + 0.02 - distance))
		return
	end
	if math.abs(cf.ZVector.Z) > 0.9999 then
		piece.Size = Vector3.new(taille.X, taille.Y, longueur)
	else
		-- Les pavés obliques rétrécissent dans les deux axes pour garder leur orientation.
		local facteur = longueur / (2 * demiZ)
		piece.Size = Vector3.new(taille.X * facteur, taille.Y, taille.Z * facteur)
	end
	piece.CFrame = cf + Vector3.new(0, 0, signe * (demiZ + 0.02 - distance) / 2)
end

local function preparerEscaliersPont(village, sentiers)
	local riviere = village:FindFirstChild("Riviere")
	local tablier = riviere and riviere:FindFirstChild("Tablier")
	if not tablier then return end

	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {workspace.Terrain}
	filtre.IgnoreWater = true
	local dessusPont = tablier.Position.Y + tablier.Size.Y / 2
	local profondeur = 1.8
	local longueurPalier = 4 -- recouvre la berge jusqu'à ce que le terrain passe sous les marches
	local routes = village:FindFirstChild("Routes")
	for index, nom in {"Escalier_Pont_Gauche", "Escalier_Pont_Droite"} do
		local signe = 2 * index - 3
		local bord = tablier.Position.Z + signe * tablier.Size.Z / 2
		local sol = workspace:Raycast(Vector3.new(tablier.Position.X, dessusPont + 10, bord), Vector3.new(0, -20, 0), filtre)
		if not sol then continue end
		local dessusPalier = sol.Position.Y + 0.255 -- niveau du dessus des dalles du sentier
		local hauteurMarche = (dessusPalier - dessusPont) / 3
		if hauteurMarche <= 0 then continue end

		for _, piece in sentiers:GetChildren() do
			if piece:IsA("BasePart") and (piece.Name == "Terre" or piece.Name == "DalleReguliere"
				or piece.Name == "Pave" or piece.Name == "Bordure") then
				raccourcirAuPont(piece, bord, signe, tablier.Size.X / 2)
			end
		end
		if routes then
			for _, piece in routes:GetChildren() do
				if piece:IsA("BasePart") and piece.Name == "Chemin" then
					raccourcirAuPont(piece, bord, signe, tablier.Size.X / 2)
				end
			end
		end

		if riviere:FindFirstChild(nom) then continue end
		local escalier = O.modele(riviere, nom)
		local function assise(nomAssise, recul, longueur, hauteur)
			local taille = Vector3.new(tablier.Size.X, hauteur, longueur)
			local centre = Vector3.new(tablier.Position.X, dessusPont + hauteur / 2, bord - signe * recul)
			O.bloc(escalier, taille, CFrame.new(centre), tablier.Color, tablier.Material, nomAssise)
		end
		assise("Palier", longueurPalier / 2, longueurPalier, 3 * hauteurMarche)
		assise("MarcheHaute", longueurPalier + profondeur / 2, profondeur, 2 * hauteurMarche)
		assise("MarcheBasse", longueurPalier + 1.5 * profondeur, profondeur, hauteurMarche)
	end
end

-- Chemins décoratifs posés sur le terrain réel, y compris sur les cartes figées.
function Village.preparerSentiers(village)
	local anciens = village:FindFirstChild("SentiersFontaine")
	if anciens and anciens:GetAttribute("VersionSentiers") == 15 then
		preparerEscaliersPont(village, anciens)
		return
	end
	-- rue du sud élargie : maisons écartées avant de tracer leurs allées (cartes figées)
	Village.preparerRueSud(village)
	local cheminMoulin = village:FindFirstChild("CheminMoulin")
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
					local taille = Vector2.new(largeur * 0.29, direction.Magnitude / nombre - 0.04)
					if raccordGare then
						-- Les dalles de l'avenue atteignent X = -4,45. Réduire
						-- seulement les dalles obliques qui déborderaient dessus.
						local demiLargeurX = (math.abs(math.cos(angle)) * taille.X + math.abs(math.sin(angle)) * taille.Y) / 2
						local facteur = math.clamp((-4.45 - position.X) / demiLargeurX, 0, 1)
						taille *= facteur
					end
					if taille.X > 0.1 and taille.Y > 0.1 then
						dalle(position.X, position.Y, taille, angle, "DalleReguliere", pierres[(i + j + 1) % #pierres + 1])
					end
				end
			end
			for _, signe in {-1, 1} do
				local position = centre + normal * signe * largeur * 0.49
				-- ouverture là où la rue circulaire croise l'allée (pas de bordure en travers de la rue)
				local croiseAnneau = math.abs(centre.Magnitude - Village.RUES.ANNEAU) < 3.6
				-- Garder le passage libre au raccord oblique vers le quai : les
				-- bordures de l'avenue ne doivent pas couper la seconde allée.
				local debutQuai, finQuai = Vector2.new(0, -89), Vector2.new(-14.5, -97)
				local axeQuai = finQuai - debutQuai
				local t = math.clamp((position - debutQuai):Dot(axeQuai) / axeQuai:Dot(axeQuai), 0, 1)
				local dansRaccord = x1 == 0 and z1 == -15
					and (position - (debutQuai + axeQuai * t)).Magnitude < 4.6
				if (not raccordGare or position.X < -5.2) and (raccordGare or math.abs(centre.Y) > 19.5) and not croiseAnneau and not dansRaccord then
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
	rue(Vector2.new(0, sudDebut), Vector2.new(0, RU.SUD_FIN + 2), RU.SUD_LARGEUR)

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
	local allees = {} -- allées vers les portes (seules celles des entrepôts reçoivent 2 lampadaires face à face)
	for _, d in village:GetDescendants() do
		if d:IsA("Model") then
			local accueil = d:GetAttribute("Accueil")
			if typeof(accueil) == "Vector3" and d.Name ~= "Taverne" then
				local p = Vector2.new(accueil.X, accueil.Z)
				local q, distance, axe = plusProche(p)
				-- Maison9 déplacée en face du moulin : son allée est dans CheminMoulin
				if q and distance > 2.5 and distance < 70 and not (d.Name == "Maison9" and accueil.X < -40) then
					local c = rue(q, p, math.min(5, d:GetAttribute("LargeurAllee") or 4.5))
					-- allée du moulin déjà pavée par CheminMoulin : seulement l'ouverture dans la bordure de la rue
					c.fantome = cheminMoulin ~= nil and d.Name == "MoulinSud"
					table.insert(allees, {c, axe[3], d.Name == "Entrepot"})
				end
			end
		end
	end
	for _, c in tous do
		if not c.fantome then
			relier(c)
		end
	end
	-- Lampadaires d'allée : uniquement les deux longues allées des entrepôts (les autres allées sont courtes,
	-- déjà éclairées par les lampadaires des rues : des lampadaires devant chaque porte encombraient le village)
	for _, a in allees do
		if not a[3] then
			continue
		end
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
	sentiers:SetAttribute("VersionSentiers", 15)
	if anciens then anciens:Destroy() end
	sentiers.Name = "SentiersFontaine"
	preparerEscaliersPont(village, sentiers)
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
	B.caisse(m, cf * CFrame.new(13.6, 2, -4), 2.4)

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
	SUD_FIN = 134, -- bout de la rue du sud (la dalle de l'arène commence à z = 133 ; au-delà de z = 144, le terrain monte)
	SUD_LARGEUR = 16, -- avenue pavée du pont à l'arène (bordures à x = ±7,8)
}
local R = Village.RUES
local X_LAMPE_SUD = R.SUD_LARGEUR / 2 + 1.6 -- pied des lampadaires de la rue du sud, juste hors de la bordure
local ECART_RUE_SUD = 7 -- maisons de la rue du sud écartées de 7 studs (x = ±19 → ±26) : Village.preparerRueSud

-- {x, z, largeur, profondeur, étages}
local MAISONS = {
	-- rue ouest : rangée nord (façade au sud) et rangée sud (façade au nord)
	{-102, R.OUEST_Z - 15, 18, 14, 2, Vector3.new(-102, 0, R.OUEST_Z)}, {-130, R.OUEST_Z - 15, 16, 14, 1, Vector3.new(-130, 0, R.OUEST_Z)},
	{-102, R.OUEST_Z + 15, 16, 14, 1, Vector3.new(-102, 0, R.OUEST_Z)}, {-130, R.OUEST_Z + 15, 20, 15, 2, Vector3.new(-130, 0, R.OUEST_Z)},
	-- rue est
	{102, R.EST_Z - 15, 16, 14, 1, Vector3.new(102, 0, R.EST_Z)}, {130, R.EST_Z - 15, 20, 15, 2, Vector3.new(130, 0, R.EST_Z)},
	{102, R.EST_Z + 15, 18, 14, 2, Vector3.new(102, 0, R.EST_Z)}, {130, R.EST_Z + 15, 16, 14, 1, Vector3.new(130, 0, R.EST_Z)},
	-- rue du sud, après le pont : deux maisons de chaque côté ; au bout de la rue, la place du boss du village
	-- (ancienne Maison13, retirée : Village.preparerCercleBoss)
	{-26, 108, 16, 14, 1, Vector3.new(0, 0, 108)}, {26, 108, 16, 14, 2, Vector3.new(0, 0, 108)},
	{-26, 127, 16, 14, 2, Vector3.new(0, 0, 127)}, {26, 127, 16, 14, 1, Vector3.new(0, 0, 127)},
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

-- Moulin de la rive sud (B.moulin, en blocs), dos à la rivière ; la roue tourne dans l'eau
-- et entraîne le moulin par l'arbre, le rouet et la lanterne.
local MOULIN_SUD_X, MOULIN_SUD_Z = -54, 104
local PONTON_X = 24 -- ponton de pêche, rive nord de la rivière
local ROUE_SUD_Y, ROUE_SUD_Z = 3.2, 88
local AXE_ROUE_SUD = CFrame.new(MOULIN_SUD_X, ROUE_SUD_Y, ROUE_SUD_Z) * CFrame.Angles(0, math.pi / 2, 0) -- axe X local = nord-sud
local function moulinSud(parent)
	local moulin = B.moulin(parent, CFrame.new(MOULIN_SUD_X, 2, MOULIN_SUD_Z), AXE_ROUE_SUD)
	moulin:SetAttribute("Accueil", Vector3.new(MOULIN_SUD_X, 0, MOULIN_SUD_Z + 10))
	return moulin
end

-- Cartes figées : déplace la roue (et ses remous) sur la rive sud, retire l'ancien axe et son
-- support, puis construit le moulin et son mécanisme. Une seule fois : le moulin sert de repère.
function Village.preparerMoulin(village)
	local r = village:FindFirstChild("Riviere")
	if not r or r:FindFirstChild("MoulinSud") then return end
	local roue = r:FindFirstChild("RoueMoulin")
	if not (roue and roue:IsA("Model")) then return end
	local ecart = AXE_ROUE_SUD.Position - roue:GetPivot().Position
	roue:PivotTo(roue:GetPivot() + ecart)
	for _, nom in {"Axe", "Support"} do
		local piece = r:FindFirstChild(nom)
		if piece and piece:IsA("BasePart") then piece:Destroy() end
	end
	local remous = r:FindFirstChild("Remous")
	if remous and remous:IsA("BasePart") then
		remous.CFrame = remous.CFrame.Rotation + Vector3.new(MOULIN_SUD_X, -4, ROUE_SUD_Z)
	end
	moulinSud(r)
end

-- Cartes figées : l'allée sous l'arche de la rue du sud finissait contre la porte de la Maison9.
-- On déplace cette maison en face du moulin (porte tournée vers lui), on retire les arbres
-- qui gênent, puis on pave le chemin de l'arche jusqu'au moulin et à la maison.
local MAISON_DEPLACEE = "Maison9"
local MAISON_NOUVELLE_POS = Vector3.new(MOULIN_SUD_X, 0, 134)

-- Lampadaires de la rue du sud : 2 paires au bord de l'avenue élargie (z = 110 et 126), décalées ensemble
-- (symétrie) si une allée de porte passe par là. Rend les 4 positions des pieds.
local function lampadairesRueSud(village)
	local portes = {}
	for _, d in village:GetDescendants() do
		local a = d:IsA("Model") and d.Name ~= MAISON_DEPLACEE and d:GetAttribute("Accueil")
		if typeof(a) == "Vector3" and math.abs(a.X) > 8 and math.abs(a.X) < 70 and a.Z > 96 and a.Z < 140 then
			table.insert(portes, a.Z)
		end
	end
	local pieds = {}
	for _, z in {110, 126} do
		local zl = z
		for _, dz in {0, 1.5, -1.5, 3, -3, 4.5, -4.5} do
			local libre = true
			for _, pz in portes do
				if math.abs(z + dz - pz) < 3.6 then libre = false break end -- demi-allée 2,25 + pied 1,2
			end
			if libre then zl = z + dz break end
		end
		table.insert(pieds, Vector2.new(-X_LAMPE_SUD, zl))
		table.insert(pieds, Vector2.new(X_LAMPE_SUD, zl))
	end
	return pieds
end

local function solVisible(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	local r = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
	return r and r.Position.Y or 2
end

-- Allée dans le style des sentiers du village (Village.preparerSentiers) : terre, pavés épars,
-- trois rangs de dalles régulières et bordures. Utilisée pour les raccords autour du moulin.
local SENTIER_TERRE = Color3.fromRGB(97, 91, 103)
local SENTIER_PIERRES = {Color3.fromRGB(103, 98, 112), Color3.fromRGB(117, 111, 124), Color3.fromRGB(90, 88, 102), Color3.fromRGB(108, 102, 115), Color3.fromRGB(99, 98, 109)}
local SENTIER_BORDURE = Color3.fromRGB(79, 74, 88)
local function dansReseau(q, reseau, sauf, avant)
	if not reseau then return false end
	for k, c in reseau do
		if k ~= sauf and (not avant or k < sauf) then
			local d = c.fin - c.debut
			local t = math.clamp((q - c.debut):Dot(d) / d:Dot(d), 0, 1)
			if (q - (c.debut + d * t)).Magnitude < c.demi + 0.2 then return true end
		end
	end
	return false
end

-- reseau / index (facultatifs) : tronçons d'un même chemin. Rien n'est posé deux fois sur un
-- tronçon déjà tracé, et les bordures s'arrêtent à l'entrée des autres tronçons : le chemin
-- reste d'un seul tenant, sans couches superposées.
local function alleeSentier(parent, a, b, largeur, rng, hausse, reseau, index)
	hausse = hausse or 0 -- au-dessus d'une autre allée qu'elle croise : évite le scintillement
	local debut, fin = Vector2.new(a.X, a.Z), Vector2.new(b.X, b.Z)
	local direction = fin - debut
	if direction.Magnitude < 0.5 then return end
	local normal = Vector2.new(-direction.Y, direction.X).Unit
	local function libre(q, bordure)
		return not dansReseau(q, reseau, index, not bordure)
	end
	local function terre(q)
		if not libre(q) then return end
		local p = O.decor(O.cylindre(parent, 0.12, largeur * rng:NextNumber(0.94, 1.06), CFrame.new(q.X, solVisible(q.X, q.Y) + 0.05 + hausse + rng:NextNumber(0, 0.004), q.Y), SENTIER_TERRE, M.Paves, "Terre"))
		p.CastShadow = false
	end
	local function pave(q)
		if not libre(q) then return end
		local p = O.decor(O.bloc(parent, Vector3.new(rng:NextNumber(0.6, 1.4), 0.11, rng:NextNumber(0.7, 1.55)),
			CFrame.new(q.X, solVisible(q.X, q.Y) + 0.14 + hausse, q.Y) * CFrame.Angles(0, rng:NextNumber(-0.65, 0.65), 0),
			SENTIER_PIERRES[rng:NextInteger(1, #SENTIER_PIERRES)], M.Pierre, "Pave"))
		p.CastShadow = false
	end
	local function dalle(q, taille, angle, nom, couleur)
		if not libre(q, nom == "Bordure") then return end
		local p = O.decor(O.bloc(parent, Vector3.new(taille.X, 0.1, taille.Y), CFrame.new(q.X, solVisible(q.X, q.Y) + 0.205 + hausse, q.Y) * CFrame.Angles(0, angle, 0), couleur, M.Pierre, nom))
		p.CastShadow = false
	end
	local nombre = math.ceil(direction.Magnitude / 2.8)
	for i = 0, nombre do
		local centre = debut:Lerp(fin, i / nombre)
		terre(centre + normal * rng:NextNumber(-0.65, 0.65))
		for _ = 1, 2 do
			pave(centre + normal * rng:NextNumber(-largeur * 0.38, largeur * 0.38) + direction.Unit * rng:NextNumber(-1, 1))
		end
	end
	local rangs = math.ceil(direction.Magnitude / 3)
	local angle = math.atan2(-direction.X, -direction.Y)
	for i = 0, rangs do
		local centre = debut:Lerp(fin, i / rangs)
		for j = -1, 1 do
			dalle(centre + normal * j * largeur * 0.3, Vector2.new(largeur * 0.29, direction.Magnitude / rangs - 0.04), angle,
				"DalleReguliere", SENTIER_PIERRES[(i + j + 1) % #SENTIER_PIERRES + 1])
		end
		for _, signe in {-1, 1} do
			dalle(centre + normal * signe * largeur * 0.49, Vector2.new(0.45, direction.Magnitude / rangs - 0.02), angle, "Bordure", SENTIER_BORDURE)
		end
	end
end

-- Pose un modèle à une nouvelle position (x, z) en le gardant sur le sol visible
local function deplacerAuSol(modele, x, z)
	local pivot = modele:GetPivot()
	local dy = solVisible(x, z) - solVisible(pivot.X, pivot.Z)
	modele:PivotTo(pivot.Rotation + Vector3.new(x, pivot.Y + dy, z))
end

function Village.preparerCheminMoulin(village)
	local riviereM = village:FindFirstChild("Riviere")
	local moulin = riviereM and riviereM:FindFirstChild("MoulinSud")
	if not moulin or village:FindFirstChild("CheminMoulin") then return end
	local maisons = village:FindFirstChild("Maisons")
	local maison = maisons and maisons:FindFirstChild(MAISON_DEPLACEE)
	local porteRue = maison and maison:GetAttribute("Accueil")
	if not (maison and maison:IsA("Model") and typeof(porteRue) == "Vector3") then return end

	-- Nouvelle place de la maison : face au moulin, de l'autre côté du chemin
	local ancien = maison:GetPivot()
	local yNouveau = ancien.Y + solVisible(MAISON_NOUVELLE_POS.X, MAISON_NOUVELLE_POS.Z) - solVisible(ancien.X, ancien.Z)
	local nouvelle = CFrame.lookAt(Vector3.new(MAISON_NOUVELLE_POS.X, yNouveau, MAISON_NOUVELLE_POS.Z),
		Vector3.new(MAISON_NOUVELLE_POS.X, yNouveau, 0))
	local _, taille = maison:GetBoundingBox()
	local relatif = ancien:PointToObjectSpace(porteRue)
	-- Arbres sur l'emprise de la maison et le long du chemin
	local zones = {
		{CFrame.new(MAISON_NOUVELLE_POS.X, 10, MAISON_NOUVELLE_POS.Z), Vector3.new(taille.X + 2, 20, taille.Z + 2)},
		{CFrame.new((porteRue.X + MOULIN_SUD_X) / 2, 6, porteRue.Z), Vector3.new(math.abs(porteRue.X - MOULIN_SUD_X), 10, 5)},
	}
	for _, zone in zones do
		for _, p in workspace:GetPartBoundsInBox(zone[1], zone[2]) do
			local a = p
			while a.Parent and a.Parent ~= village and a.Parent.Parent ~= village do a = a.Parent end
			local dossier = a.Parent and a.Parent.Name
			if a:IsA("Model") and a.Parent and (dossier == "Nature" or dossier == "Bosquets") then a:Destroy() end
		end
	end
	maison:PivotTo(nouvelle)
	local porteMaison = nouvelle:PointToWorldSpace(relatif)
	porteMaison = Vector3.new(porteMaison.X, 0, porteMaison.Z)
	maison:SetAttribute("Accueil", porteMaison)

	-- Petit toit en bois (auvent) de la maison voisine, collé au chemin : retiré
	local voisine = maisons:FindFirstChild("Maison11")
	if voisine then
		for _, p in voisine:GetDescendants() do
			if p:IsA("BasePart") and string.find(p.Name, "Auvent") then p:Destroy() end
		end
	end

	-- Raccords dans le style des sentiers. L'allée principale vers le moulin est normalement
	-- déjà tracée par preparerSentiers (attribut Accueil du moulin) ; sinon on la trace ici.
	local chemin = O.modele(village, "CheminMoulin")
	local zChemin = MOULIN_SUD_Z + 10
	local sentiers = village:FindFirstChild("SentiersFontaine")
	local rng = Random.new(5117)
	-- Les pierres d'allées déjà posées sur ce tracé (allée du moulin et ancienne allée de la
	-- Maison9, qui se superposaient) sont retirées, puis l'allée est tracée une seule fois :
	-- deux couches au même niveau scintillaient. Les lampadaires (modèles) sont conservés.
	if sentiers then
		for _, p in sentiers:GetChildren() do
			if p:IsA("BasePart") then
				local q = p.Position
				if q.X < -(R.SUD_LARGEUR / 2 + 0.4) and q.X > MOULIN_SUD_X - 4 and math.abs(q.Z - zChemin) < 2.9 then p:Destroy() end
			end
		end
	end
	alleeSentier(chemin, Vector3.new(-(R.SUD_LARGEUR / 2 + 1.6), 0, zChemin), Vector3.new(MOULIN_SUD_X, 0, zChemin), 4.5, rng)
	alleeSentier(chemin, Vector3.new(porteMaison.X, 0, zChemin + 2.6), porteMaison, 4.5, rng, 0.04)

	-- Les deux lampadaires de l'allée les plus proches du moulin : légèrement rapprochés de lui
	if sentiers then
		for _, l in sentiers:GetChildren() do
			local p = l:IsA("Model") and l:GetPivot().Position
			if p and math.abs(p.Z - zChemin) < 5 and p.X < -18 and p.X > MOULIN_SUD_X + 8 then
				deplacerAuSol(l, p.X - 7, p.Z)
			end
		end
	end

	-- Deux bancs le long de l'allée (côté rivière), tournés vers elle, et le tonneau entre eux
	local zBanc = zChemin - 5.7
	local xTonneau, zTonneau = -28.5, zChemin - 4.4
	for i, x in {-15.5, -36} do
		-- arbres sur l'emplacement du banc
		for _, p in workspace:GetPartBoundsInBox(CFrame.new(x, 6, zBanc), Vector3.new(10, 10, 3)) do
			local a = p
			while a.Parent and a.Parent ~= village and a.Parent.Parent ~= village do a = a.Parent end
			local dossier = a.Parent and a.Parent.Name
			if a:IsA("Model") and a.Parent and (dossier == "Nature" or dossier == "Bosquets") then a:Destroy() end
		end
		local pos = Vector3.new(x, solVisible(x, zBanc), zBanc)
		B.bancJardinieres(chemin, CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)), 4 + i)
	end
	for _, t in maisons:GetChildren() do
		local corps = t:IsA("Model") and t.Name == "Tonneau" and t:FindFirstChild("Corps")
		if corps and (Vector2.new(corps.Position.X, corps.Position.Z) - Vector2.new(-14.7 - ECART_RUE_SUD, 108.9)).Magnitude < 3 then
			local pivot = t:GetPivot()
			deplacerAuSol(t, pivot.X + (xTonneau - corps.Position.X), pivot.Z + (zTonneau - corps.Position.Z))
		end
	end

	-- Gare : le bout du chemin (demi-cercle de bordures, dalles) débordait sur la rampe et le
	-- plancher en bois du quai. Le chemin s'arrête au bord du bois.
	-- Le carrefour devant la gare (raccord de l'avenue, départ de l'allée de l'entrepôt) est
	-- entièrement retracé d'un seul tenant : avenue → carrefour → entrée du quai, et carrefour →
	-- allée de l'entrepôt. L'entrée fait toute la largeur de l'ouverture des balustrades.
	local ENTREE_GAUCHE, ENTREE_DROITE = -20.2, -11.2 -- bords de l'ouverture (Mine.lua)
	local carrefour = Vector2.new((ENTREE_GAUCHE + ENTREE_DROITE) / 2, -95)
	local raccordAvenue = Vector2.new(-5.2, -91.9)
	-- départ de l'allée de l'entrepôt : porte la plus proche dans la direction de l'ouest
	local versEntrepot = Vector2.new(-21.2, 9.1).Unit
	for _, d in village:GetDescendants() do
		local accueil = d:IsA("Model") and d:GetAttribute("Accueil")
		if typeof(accueil) == "Vector3" then
			local v = Vector2.new(accueil.X, accueil.Z) - Vector2.new(-14.5, -97)
			if v.Magnitude > 10 and v.Magnitude < 60 and v.Unit:Dot(Vector2.new(-21.2, 9.1).Unit) > 0.97 then
				versEntrepot = v.Unit
			end
		end
	end
	local departEntrepot = Vector2.new(-14.5, -97) + versEntrepot * ((-25 - -14.5) / versEntrepot.X)
	if sentiers then
		for _, p in sentiers:GetChildren() do
			if p:IsA("BasePart") then
				local q = p.Position
				if q.X > -25 and q.X < -5.1 and q.Z < -88.6 and q.Z > -146 then p:Destroy() end
			end
		end
	end
	local function v3(v) return Vector3.new(v.X, 0, v.Y) end
	local troncons = {
		{raccordAvenue, carrefour, 5},
		{carrefour, Vector2.new(carrefour.X, -100.2), ENTREE_DROITE - ENTREE_GAUCHE},
		{carrefour, departEntrepot, 4.5},
	}
	local reseau = {}
	for k, t in troncons do
		reseau[k] = {debut = t[1], fin = t[2], demi = t[3] / 2}
	end
	for k, t in troncons do
		alleeSentier(chemin, v3(t[1]), v3(t[2]), t[3], rng, 0.03, reseau, k)
	end

	-- Tonneaux retirés au bout de la rue du sud (devant la maison du fond et ses voisines)
	-- Les tonneaux « CouvreReste » cachaient un couvercle d'ancien tonneau fondu dans le maillage
	-- de la maison : un petit buisson fleuri le recouvre à la place.
	-- (positions des maisons de la rue du sud écartées de ECART_RUE_SUD : leurs tonneaux 3D ont suivi)
	local E = ECART_RUE_SUD
	local TONNEAUX_RETIRES = {Vector2.new(12.8 + E, 136.5), Vector2.new(0.86, 136.8), Vector2.new(-12.6 - E, 134.7), Vector2.new(-14.1 - E, 138.7),
		Vector2.new(14.6 + E, 107), Vector2.new(14 + E, 115.2), Vector2.new(12.4 + E, 119.4)}
	local fleurs = {Color3.fromRGB(212, 83, 126), Color3.fromRGB(239, 159, 39), Color3.fromRGB(240, 226, 190)}
	for _, d in village:GetDescendants() do
		if d:IsA("Model") and d.Name == "Tonneau" and d.Parent then
			local p = d:GetPivot().Position
			for _, cible in TONNEAUX_RETIRES do
				if (Vector2.new(p.X, p.Z) - cible).Magnitude < 1.5 then
					local couvrait = d:GetAttribute("CouvreReste")
					d:Destroy()
					if couvrait then
						local buisson = O.modele(chemin, "BuissonFleuri")
						local y = solVisible(p.X, p.Z)
						O.decor(O.bloc(buisson, Vector3.new(3, 0.9, 3), CFrame.new(p.X, y + 0.45, p.Z), Color3.fromRGB(78, 120, 42), M.Herbe, "Feuillage"))
						O.decor(O.bloc(buisson, Vector3.new(1.8, 0.7, 1.8), CFrame.new(p.X + 0.3, y + 1.1, p.Z - 0.2), Color3.fromRGB(58, 96, 34), M.Herbe, "Feuillage"))
						for k = 1, 4 do
							local a = k * math.pi / 2 + 0.4
							O.decor(O.bloc(buisson, Vector3.new(0.35, 0.35, 0.35), CFrame.new(p.X + math.cos(a) * 1.05, y + 1.05, p.Z + math.sin(a) * 1.05),
								fleurs[k % #fleurs + 1], M.Lisse, "Fleur"))
						end
					end
					break
				end
			end
		end
	end

	-- Lampadaires retirés au bout de la rue du sud (deux paires, devant la maison du fond)
	-- puis les paires (arches) à l'entrée des allées le long de la rue du sud
	local LAMPADAIRES_RETIRES = {Vector2.new(-8.6, 134.8), Vector2.new(-8.6, 131.1), Vector2.new(5.6, 133.6), Vector2.new(4.6, 137.2),
		Vector2.new(8.5, 100.1), Vector2.new(8.5, 103.8), Vector2.new(8.5, 119.1), Vector2.new(8.5, 122.8),
		Vector2.new(-8.6, 112.1), Vector2.new(-8.6, 115.8)}
	-- et le lampadaire de rue au milieu du côté est
	table.insert(LAMPADAIRES_RETIRES, Vector2.new(5.9, 117.5))
	-- et celui de l'allée du pont (cartes figées)
	table.insert(LAMPADAIRES_RETIRES, Vector2.new(4.4, 50))
	for _, nom in {"SentiersFontaine", "Eclairage"} do
		local dossier = village:FindFirstChild(nom)
		for _, l in (if dossier then dossier:GetChildren() else {}) do
			if l:IsA("Model") then
				local p = l:GetPivot().Position
				for _, cible in LAMPADAIRES_RETIRES do
					if (Vector2.new(p.X, p.Z) - cible).Magnitude < 1 then l:Destroy() break end
				end
			end
		end
	end
	-- À la place : un lampadaire simple de chaque côté de la rue du sud, à deux hauteurs
	for _, pos in lampadairesRueSud(village) do
		local y = solVisible(pos.X, pos.Y)
		B.lanterne(chemin, vers(Vector3.new(pos.X, y, pos.Y), Vector3.new(0, y, pos.Y)))
	end

	-- Tonneaux des maisons voisines qui débordent sur le chemin : poussés sur le côté
	local xMin, xMax = MOULIN_SUD_X - 6, porteRue.X + 2
	local yChemin = solVisible(porteRue.X, zChemin) + 3
	for _, p in workspace:GetPartBoundsInBox(CFrame.new((xMin + xMax) / 2, yChemin, zChemin), Vector3.new(xMax - xMin, 4, 4)) do
		local tonneau = p.Parent
		if p.Name == "Corps" and tonneau and tonneau:IsA("Model") and tonneau.Name == "Tonneau" then
			local cote = if p.Position.Z >= zChemin then 1 else -1
			local cible = zChemin + cote * (2 + p.Size.Y / 2 + 0.3)
			tonneau:PivotTo(tonneau:GetPivot() + Vector3.new(0, 0, cible - p.Position.Z))
		end
	end

	-- Coin des pêcheurs : un second pin, copie de celui qui se dresse près du puits du pont
	local bosquets = village:FindFirstChild("Bosquets")
	if bosquets and not bosquets:FindFirstChild("PinCoinPeche") then
		local modele, meilleure = nil, 4
		for _, arbre in bosquets:GetDescendants() do
			if arbre:IsA("Model") and arbre.Name == "Pin" then
				local p = arbre:GetPivot().Position
				local d = (Vector2.new(p.X, p.Z) - Vector2.new(-8.8, 51)).Magnitude
				if d < meilleure then modele, meilleure = arbre, d end
			end
		end
		if modele then
			local copie = modele:Clone()
			copie.Name = "PinCoinPeche"
			local depart = modele:GetPivot().Position
			local cible = Vector3.new(PONTON_X + 18, 0, 60)
			local dy = solVisible(cible.X, cible.Z) - solVisible(depart.X, depart.Z)
			copie:PivotTo(modele:GetPivot() + Vector3.new(cible.X - depart.X, dy, cible.Z - depart.Z))
			copie.Parent = bosquets
		end
	end
end

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
		local ecart = if s > 0 then X_LAMPE_SUD else 6.8 -- côté sud : au bord de la rue du sud élargie
		for _, x in {-ecart, ecart} do
			local p = Vector3.new(x, 0, z + s * 17)
			B.lanterne(m, vers(p, Vector3.new(0, 0, p.Z)), 9)
		end
	end

	-- Ponton de pêche sur la rive nord, devant les saules (eau à y = -4)
	local departPonton = Vector3.new(PONTON_X, 2.3, z - demi - 10)
	B.pontonPeche(m, CFrame.lookAt(departPonton, departPonton + Vector3.zAxis), 6.3, 9)
	-- coin des pêcheurs sur la berge : petit fumoir à l'est de la passerelle, un séchoir à l'ouest
	local posFumoir = Vector3.new(PONTON_X + 8, 0, z - demi - 7)
	posFumoir = Vector3.new(posFumoir.X, solVisible(posFumoir.X, posFumoir.Z), posFumoir.Z)
	B.fumoir(m, CFrame.lookAt(posFumoir, posFumoir - Vector3.xAxis))
	for i, dz in {-6.5} do
		local p = Vector3.new(PONTON_X - 8, 0, z - demi + dz)
		p = Vector3.new(p.X, solVisible(p.X, p.Z), p.Z)
		B.sechoirPoissons(m, CFrame.lookAt(p, p + Vector3.xAxis), i)
	end

	-- Moulin à eau
	local cfMoulin = CFrame.lookAt(Vector3.new(-34, 0, 60), Vector3.new(-34, 0, 0))
	local moulin, porteMoulin = B.maison(m, cfMoulin, {largeur = 16, profondeur = 14, etages = 1, mur = C.Ocre, toit = C.Toit, nom = "Moulin", rng = rng, modele = 4})
	moulin:SetAttribute("Accueil", sol((porteMoulin * CFrame.new(0, 0, -3.4)).Position))
	moulinSud(m)
	local axe = AXE_ROUE_SUD

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
	local remous = O.decor(O.bloc(m, Vector3.new(12, 1, 3), CFrame.new(MOULIN_SUD_X, -4, ROUE_SUD_Z), Color3.new(1, 1, 1), M.Lisse, "Remous"))
	remous.Transparency = 1
	O.brume(remous, Color3.fromRGB(230, 236, 240), 6)

	-- Rochers sur les berges
	for _ = 1, 16 do
		local s = if rng:NextNumber() < 0.5 then -1 else 1
		local x = rng:NextNumber(-200, 200)
		if math.abs(x) > 12 and math.abs(x + 34) > 10 and math.abs(x - MOULIN_SUD_X) > 10 and math.abs(x - PONTON_X) > 12 then
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
	-- rue du sud (le lampadaire de l'allée du pont a été retiré)
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
		{Vector2.new(0, 98), Vector2.new(0, R.SUD_FIN + 2), R.SUD_LARGEUR / 2}, -- rue du sud
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
			table.insert(liste, {cf = cf, taille = taille, accueil = d:GetAttribute("Accueil"), modele = d})
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
	il est creusé au niveau du village, avec un talus en pente douce jusqu'à 14 studs.
	seulement (facultatif) : {[modèle] = true}, bâtiments déplacés ; sous eux, un creux est aussi comblé (aucune fondation dans le vide). ]]
function Village.terrasser(v, seulement)
	local terrain = workspace.Terrain
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {terrain}
	local NIVEAU = 2
	local creuses = 0
	for _, b in batiments(v) do
		if seulement and not seulement[b.modele] then
			continue
		end
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
					elseif seulement and h and d <= 4 and h < NIVEAU - 0.8 and r.Material ~= Enum.Material.Water then
						terrain:FillBlock(CFrame.new(x, (h - 2 + NIVEAU) / 2, z), Vector3.new(4, NIVEAU - h + 2, 4), Enum.Material.Grass)
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

-- Saule de la rive nord, entre le stand de Liesel et le pont de pierre.
-- Le retirer après la plantation conserve les tirages et l'emplacement des autres arbres.
function Village.retirerSauleDuPont(village)
	local bosquets = village:FindFirstChild("Bosquets")
	if not bosquets then
		return
	end
	local cible = Vector2.new(-10, 55.45)
	local saule: Model? = nil
	for _, arbre in bosquets:GetChildren() do
		if arbre:IsA("Model") and arbre.Name == "Saule" then
			local p = arbre:GetPivot().Position
			if (Vector2.new(p.X, p.Z) - cible).Magnitude < 0.75 then
				if saule then
					return -- Carte retouchée : aucun retrait si l'emplacement est ambigu.
				end
				saule = arbre
			end
		end
	end
	if saule then
		saule:Destroy()
	end
end

--[[ Dernier passage (après les bordures) : retire tout arbre, rocher, falaise, paroi ou chèvre dont le pied
	tombe dans un bâtiment ou sur une rue. Appelé par Monde.construire.
	zone (facultatif) : function(x, z) -> booléen, limite le passage à une partie de la carte. ]]
function Village.degager(carte, zone)
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
			if zone and not zone(pied.X, pied.Z) then
				continue
			end
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

--[[ Rue du sud élargie (16 studs, du pont à l'arène) sur les cartes figées : les maisons de la rue (x = ±19)
	s'écartent de ECART_RUE_SUD (→ ±26) avec ce qui est posé devant elles (tonneaux, buissons), puis : arbres et
	rochers retirés de leur nouvelle emprise et de la rue, terrain aplani dessous ; les 4 lampadaires de la rue et
	les 2 lanternes du pont côté sud passent au bord de l'avenue ; l'amorce de CheminMoulin sur la rue est retirée.
	Appelé par preparerSentiers avant de tracer les allées (qui suivent les nouvelles portes). Une seule fois. ]]
function Village.preparerRueSud(village)
	if village:GetAttribute("VersionRueSud") == 1 then
		return
	end
	local maisonsM = village:FindFirstChild("Maisons")
	local chemin = village:FindFirstChild("CheminMoulin")
	local deplacees, seulement = {}, {}
	for _, nom in {"Maison9", "Maison10", "Maison11", "Maison12"} do
		local maison = maisonsM and maisonsM:FindFirstChild(nom)
		local accueil = maison and maison:GetAttribute("Accueil")
		if maison and maison:IsA("Model") and typeof(accueil) == "Vector3" then
			local cf, taille = maison:GetBoundingBox()
			local x = cf.Position.X
			if math.abs(x) > 10 and math.abs(x) < 22.5 and cf.Position.Z > 96 and cf.Position.Z < 140 then
				table.insert(deplacees, {maison = maison, accueil = accueil, b = {cf = cf, taille = taille}, dx = math.sign(x) * ECART_RUE_SUD})
				seulement[maison] = true
			end
		end
	end
	-- décor posé devant / contre chaque maison (≤ 3,5 studs de sa boîte) : il suit la maison
	local carte = village.Parent
	local conteneurs = {maisonsM, chemin, village:FindFirstChild("Decor"), carte and carte:FindFirstChild("DecorVillage"), carte and carte:FindFirstChild("MineursDecor")}
	for _, k in deplacees do
		local suivent = {}
		for _, dossier in conteneurs do
			for _, e in (if dossier then dossier:GetChildren() else {}) do
				-- modèles seulement (les pierres d'allée restent : les sentiers sont retracés)
				if not e:IsA("Model") or seulement[e] or e:GetAttribute("Accueil") ~= nil or e.Name == "Lanterne" or e.Name == "Banc" then
					continue
				end
				local p = e:GetPivot().Position
				if horsBoite(k.b, p.X, p.Z) < 3.5 then
					table.insert(suivent, e)
				end
			end
		end
		local decalage = Vector3.new(k.dx, 0, 0)
		k.maison:PivotTo(k.maison:GetPivot() + decalage)
		k.maison:SetAttribute("Accueil", k.accueil + decalage)
		for _, e in suivent do
			e:PivotTo(e:GetPivot() + decalage)
		end
	end
	if #deplacees > 0 then
		Village.degager(carte, function(x, z) return math.abs(x) < 48 and z > 94 and z < 150 end)
		Village.terrasser(village, seulement)
	end
	-- lampadaires : pied (BottomStoneFoot) déplacé, l'orientation (bras vers la rue) est gardée
	local function deplacerLampadaire(l, cible)
		local pied = l:FindFirstChild("BottomStoneFoot")
		if not pied then return end
		local q = pied.Position
		l:PivotTo(l:GetPivot() + Vector3.new(cible.X - q.X, solVisible(cible.X, cible.Y) - solVisible(q.X, q.Z), cible.Y - q.Z))
	end
	local function lampadaires(dossier, anciens, nouveaux)
		for _, l in (if dossier then dossier:GetChildren() else {}) do
			local pied = l:IsA("Model") and l.Name == "Lanterne" and l:FindFirstChild("BottomStoneFoot")
			if pied then
				for i, a in anciens do
					if (Vector2.new(pied.Position.X, pied.Position.Z) - a).Magnitude < 1 then
						deplacerLampadaire(l, nouveaux[i])
						break
					end
				end
			end
		end
	end
	local rz = D.RIVIERE_Z + 17
	lampadaires(village:FindFirstChild("Riviere"), {Vector2.new(-6.8, rz), Vector2.new(6.8, rz)}, {Vector2.new(-X_LAMPE_SUD, rz), Vector2.new(X_LAMPE_SUD, rz)})
	lampadaires(chemin, {Vector2.new(-5.6, 110), Vector2.new(5.6, 110), Vector2.new(-5.6, 126), Vector2.new(5.6, 126)}, lampadairesRueSud(village))
	-- amorce de l'allée du moulin (CheminMoulin) qui empiéterait sur l'avenue : retirée (la rue la recouvre)
	local zChemin = MOULIN_SUD_Z + 10
	for _, p in (if chemin then chemin:GetChildren() else {}) do
		if p:IsA("BasePart") and math.abs(p.Position.Z - zChemin) < 3 and p.Position.X < 0 and p.Position.X > -(R.SUD_LARGEUR / 2 + 0.4) then
			p:Destroy()
		end
	end
	village:SetAttribute("VersionRueSud", 1)
end

--[[ Place du boss du village : « l'Arène des boss », au bout de la rue du sud (à la place de l'ancienne Maison13).
	Esplanade pavée (dalle ronde + parvis) fermée au sud par la PORTE DES BOSS, porte naine taillée dans la montagne :
	façade en gradins (corps central ≤ 33 studs, ailes plus basses) en moellons sombres, portail à deux battants de fer
	et de bois gravés de runes, chaînes et cadenas, fronton, crâne du Seigneur de braise au-dessus, frise aux emblèmes
	des 3 boss, couronnements crénelés ; au-dessus et sur les côtés, talus de roche (terrain) semés de rochers, pins et
	buissons qui cachent la coupe. Deux nains gardiens géants (marteau, hache), bannières, braseros sur piliers à côté
	des trophées du Titan et de la Reine (hauts socles), gradins ; murs de soutènement en pierre taillée à l'est et à
	l'ouest. Côté rue : deux piliers bas à lanternes (la vue depuis le pont reste dégagée).
	Éclairage chaud et doux : 6 lumières (luminosité ≤ 1,4), néon seulement sur de petits détails assombris.
	Le cercle lumineux (rayon D.CERCLE_BOSS_RAYON) et le panneau sont posés par BossVillage.server (attribut « Centre »).
	Cartes figées ou non : le relief d'origine (Terrain.hauteur) est d'abord rétabli autour de la place (creusements
	des versions précédentes), puis seul le parvis est creusé, aligné sur les voxels de 4 studs. Retire ce qui tombe
	dans l'emprise (Maison13, pierres d'allée, arbres, rochers), jamais un bâtiment ; ne creuse jamais sous une maison.
	Reconstruite quand PLACE_BOSS_VERSION change. ]]
local PLACE_BOSS_VERSION = 7
local PLACE_BOSS_CENTRE = Vector3.new(0, 0, 151) -- = D.CERCLE_BOSS : l'esplanade reste à l'écart des Maison11/12
local PLACE_BOSS_RAYON = 18 -- dalle ; le cercle des joueurs (rayon 14) au milieu, le décor au-delà de 14,5
local PLACE_BOSS_DEMI_LARGEUR = 20 -- parvis creusé : x ∈ [-20, 20] (multiple de 4 : coupe nette des voxels)
local PLACE_BOSS_NORD = 140 -- début du parvis et des murs latéraux (≥ 5 studs des Maison11/12)
local PLACE_BOSS_FACADE_Z = 168 -- face avant de la Porte des boss (multiple de 4)
-- couleurs des 3 boss (Partage › BossVillage.BOSS) : Titan de cristal, Reine araignée, Seigneur de braise
local COULEURS_BOSS = {Color3.fromRGB(110, 205, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 50)}

function Village.preparerCercleBoss(village)
	if not village then
		return
	end
	local ancienne = village:FindFirstChild("PlaceBoss")
	if ancienne then
		if ancienne:GetAttribute("Version") == PLACE_BOSS_VERSION then
			-- Retire les inscriptions des arènes déjà figées sans reconstruire le décor.
			for _, piece in ancienne:GetChildren() do
				if piece:IsA("BasePart") and (piece.Name == "Pilier" or piece.Name == "Socle" or piece.Name == "Trophee") then
					local inscription = piece:FindFirstChild("TexteFront")
					if inscription and inscription:IsA("SurfaceGui") then inscription:Destroy() end
				end
			end
			return ancienne
		end
		ancienne:Destroy()
	end
	local c, RE = PLACE_BOSS_CENTRE, PLACE_BOSS_RAYON
	local DL, ZN, ZF = PLACE_BOSS_DEMI_LARGEUR, PLACE_BOSS_NORD, PLACE_BOSS_FACADE_Z
	local terrain = workspace.Terrain
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = {terrain}
	local function hauteur(x, z)
		local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -600, 0), filtre)
		return r and r.Position.Y
	end
	-- angle 0 = nord (vers la rue, -Z), sens horaire vu du dessus
	local function pt(a, r, y)
		return Vector3.new(c.X + math.sin(a) * r, y, c.Z - math.cos(a) * r)
	end
	local function versCentre(p) -- -Z local tourné vers le centre
		return CFrame.lookAt(p, Vector3.new(c.X, p.Y, c.Z))
	end
	local niveau = hauteur(c.X, c.Z - RE - 3) or 2 -- niveau de la rue
	local y = niveau + 0.6 -- dessus de la dalle (et sol de tout le décor)

	-- 1. Ancienne maison du bout de la rue (cartes figées) ; bâtiments à ménager
	for _, e in village:GetChildren() do
		local maison13 = e:FindFirstChild("Maison13")
		if maison13 and maison13:IsA("Model") then
			maison13:Destroy()
		end
	end
	local bats = batiments(village)
	local function presBatiment(x, z, marge)
		for _, b in bats do
			if horsBoite(b, x, z) < marge then
				return true
			end
		end
		return false
	end

	-- 2. Emprise libérée : pierres d'allée, tonneaux, arbres, rochers (marge : le feuillage déborde).
	--    Les bâtiments (attribut Accueil) ne sont jamais touchés.
	local function dansEmprise(p, marge)
		return math.abs(p.X - c.X) < DL + 4 + marge and p.Z > ZN - 4 - marge and p.Z < ZF + 10 + marge
	end
	local NATURE = {Nature = true, Bosquets = true, Falaises = true}
	local conteneurs = {}
	for _, e in village:GetChildren() do
		table.insert(conteneurs, {e, if NATURE[e.Name] then 4 else 0.5})
	end
	local carte = village.Parent
	for _, e in (if carte then carte:GetChildren() else {}) do
		if e.Name == "Bordures" then
			for _, s in e:GetChildren() do
				table.insert(conteneurs, {s, 4})
			end
		elseif e ~= village and e.Name ~= "Mine" and (e:IsA("Model") or e:IsA("Folder")) then
			table.insert(conteneurs, {e, 0.5})
		end
	end
	for _, k in conteneurs do
		for _, e in k[1]:GetChildren() do
			local p = if e:IsA("Model") then e:GetPivot().Position elseif e:IsA("BasePart") then e.Position else nil
			if p and e:GetAttribute("Accueil") == nil then
				local d = Vector2.new(p.X - c.X, p.Z - c.Z).Magnitude
				if d < RE + 1.5 + k[2] or dansEmprise(p, k[2]) then
					e:Destroy()
				end
			end
		end
	end

	-- 3. Relief d'origine rétabli autour de la place (cartes figées : anciens bols, talus et gradins creusés par
	--    les versions précédentes). Même relief que Terrain.hauteur, aplani près des maisons comme Village.terrasser.
	local function attendu(x, z)
		local h = T.hauteur(x, z)
		for _, b in bats do
			local d = horsBoite(b, x, z)
			if d < 14 then
				local cible = if d <= 4 then 2 else 2 + (d - 4) * 0.85
				if h > cible + 0.8 then
					h = cible
				end
			end
		end
		return h
	end
	local restaures = 0
	for x = -70, 70, 4 do -- centres des colonnes de voxels (4k + 2)
		for z = 134, 222, 4 do
			local px = c.X + x
			if (math.abs(x) < DL and z < ZF) or Vector2.new(x, z - c.Z).Magnitude > 76 or presBatiment(px, z, 4) then
				continue
			end
			local ha, hs = attendu(px, z), hauteur(px, z)
			if hs and hs < ha - 1.5 then
				local pente = math.max(math.abs(T.hauteur(px + 4, z) - T.hauteur(px - 4, z)), math.abs(T.hauteur(px, z + 4) - T.hauteur(px, z - 4))) / 8
				local surface = if pente > 1.05 then Enum.Material.Rock elseif pente > 0.6 then Enum.Material.Ground else Enum.Material.Grass
				local bas = hs - 4
				if ha - 3 > bas then
					terrain:FillBlock(CFrame.new(px, (bas + ha - 3) / 2, z), Vector3.new(4, ha - 3 - bas, 4), Enum.Material.Rock)
				end
				terrain:FillBlock(CFrame.new(px, ha - 1.5, z), Vector3.new(4, 3, 4), surface)
				restaures += 1
			end
		end
	end
	if restaures > 0 then
		print(string.format("[Village] place du boss : relief d'origine rétabli sur %d colonnes", restaures))
	end

	-- 4. Relevé du terrain (avant creusement) : la façade et les murs latéraux couvrent toute la coupe
	local function hautMax(points)
		local hm = -math.huge
		for _, q in points do
			local h = hauteur(q.X, q.Y)
			if h then
				hm = math.max(hm, h)
			end
		end
		return hm
	end
	local pts = {}
	for x = -DL - 2, DL + 2, 4 do
		table.insert(pts, Vector2.new(c.X + x, ZF + 0.5))
		table.insert(pts, Vector2.new(c.X + x, ZF + 2.5))
	end
	-- façade à taille humaine (≤ 33) : au-dessus, la coupe est couverte de roche (étape 5b), pas d'un mur lisse
	local hCoupe = hautMax(pts)
	local HF = math.clamp(math.ceil(hCoupe - y + 1.5), 28, 33) -- corps central de la façade
	local HA = HF - 7 -- ailes de la façade (silhouette en gradins)
	local ptsSud = {}
	for x = -DL - 8, DL + 8, 4 do
		table.insert(ptsSud, Vector2.new(c.X + x, ZF + 6))
		table.insert(ptsSud, Vector2.new(c.X + x, ZF + 10))
	end
	local hSud = math.max(hCoupe, hautMax(ptsSud)) -- crête de la colline derrière la façade
	local murs = {} -- tronçons de 4 studs le long de z, de chaque côté (le dernier, au coin de la façade, sans mur)
	for z = ZN, ZF, 4 do
		for _, s in {-1, 1} do
			local xi, xe = c.X + s * (DL + 0.5), c.X + s * (DL + 3.5)
			local h = hautMax({Vector2.new(xi, z + 0.5), Vector2.new(xi, z + 3.5), Vector2.new(xe, z + 0.5), Vector2.new(xe, z + 3.5)})
			local coin = z >= ZF
			table.insert(murs, {s = s, z = z, hT = h, coin = coin, h = if coin then HA else math.clamp(math.ceil(h - y + 1), 4, HA)})
		end
	end

	-- 5. Creusement aligné sur les voxels de 4 studs : la couche qui contient la rue est vidée (sinon l'herbe lissée
	--    dépasse la dalle) ; parvis rectangulaire jusqu'à la façade, bord nord de la dalle en cylindre bas
	local fond = math.floor(niveau / 4) * 4
	terrain:FillCylinder(CFrame.new(c.X, fond + 6, c.Z), 12, RE + 1.5, Enum.Material.Air) -- axe du cylindre = Y
	-- +4 studs derrière la façade et les murs latéraux : le terrain lissé d'une couche pleine voisine dépasse de ~2 studs
	-- et recouvrait la façade (vu en jeu). La façade et les murs cachent le vide derrière eux.
	terrain:FillBlock(CFrame.new(c.X, fond + 80, (ZN + ZF + 4) / 2), Vector3.new(2 * DL + 8, 160, ZF + 4 - ZN), Enum.Material.Air)

	-- 5b. Roche de la montagne au-dessus et autour de la façade : talus de roche (terrain) qui retombe sur la coupe,
	--     à 3 studs derrière le bord des ailes et des murs (le lissage des voxels ne recouvre pas la pierre taillée)
	local talusSud = nil
	do
		local H = hSud - (y + HA) + 4
		if H > 2 then
			local L = H / 1.8
			terrain:FillWedge(CFrame.new(c.X, y + HA + H / 2, ZF + 3 + L / 2), Vector3.new(2 * DL + 24, H, L), Enum.Material.Rock)
			talusSud = {H = H, L = L}
		end
	end
	local talusCotes = {}
	for _, w in murs do
		local H = w.hT - (y + w.h) + 3
		if H > 1.5 then
			local L = math.max(H / 1.6, 4)
			terrain:FillWedge(CFrame.new(c.X + w.s * (DL + 2 + L / 2), y + w.h + H / 2, w.z + 2) * CFrame.Angles(0, w.s * math.pi / 2, 0),
				Vector3.new(4.2, H, L), Enum.Material.Rock)
			table.insert(talusCotes, {w = w, H = H, L = L})
		end
	end

	-- palette sombre et contrastée : gris ardoise / brun, fer sombre, or
	local m = O.modele(village, "PlaceBoss")
	local rng = Random.new(1313)
	local claire, moyenne, foncee = Color3.fromRGB(118, 110, 102), Color3.fromRGB(92, 86, 82), Color3.fromRGB(52, 50, 54)
	local pierre = Color3.fromRGB(84, 80, 80)
	local pierreClaire = Color3.fromRGB(112, 104, 96)
	local pierreSombre = Color3.fromRGB(46, 44, 46)
	local pierreStatue = Color3.fromRGB(72, 68, 66)
	local orVieilli = Color3.fromRGB(184, 140, 60)
	local orTexte = Color3.fromRGB(236, 186, 90)
	local fer = Color3.fromRGB(40, 38, 42)
	local rune = Color3.fromRGB(150, 70, 28) -- néon assombri : lueur de braise discrète
	local feu = Color3.fromRGB(255, 150, 80)

	-- segment de section w entre deux points du monde
	local function segment(a, b, w, couleur, mat, nom)
		local d = b - a
		local haut = if math.abs(d.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
		return O.bloc(m, Vector3.new(w, w, d.Magnitude), CFrame.lookAt((a + b) / 2, b, haut), couleur, mat, nom)
	end
	-- chaîne pendante de a à b (maillons alternés)
	local function chaine(a, b, chute, n)
		local function p(t)
			return a:Lerp(b, t) - Vector3.new(0, 4 * chute * t * (1 - t), 0)
		end
		for i = 0, n - 1 do
			local p0, p1 = p(i / n), p((i + 1) / n)
			local cf = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, 0, if i % 2 == 0 then 0 else math.pi / 2)
			O.decor(O.bloc(m, Vector3.new(0.22, 0.55, (p1 - p0).Magnitude * 1.12), cf, fer, M.Metal, "Chaine"))
		end
	end

	-- 6. Sol : dalle ronde (rosace, anneaux de dalles), parvis rectangulaire jusqu'à la façade, marches au nord
	O.cylindre(m, 1.4, RE * 2, CFrame.new(c.X, y - 0.7, c.Z), moyenne:Lerp(claire, 0.3), M.Paves, "Dalle")
	O.bloc(m, Vector3.new(2 * DL + 0.4, 1.4, ZF - ZN + 0.6), CFrame.new(c.X, y - 0.76, (ZN + ZF) / 2), moyenne:Lerp(foncee, 0.3), M.Paves, "Parvis")
	local function anneau(r, n, largeur, couleurs, nom)
		local l = 2 * math.pi * r / n
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * 2 * math.pi
			local coul = couleurs[k % #couleurs + 1]
			O.decor(O.bloc(m, Vector3.new(l * 0.94, 0.1, largeur), versCentre(pt(a, r, y + 0.02)), coul,
				if coul == foncee then M.Ardoise else M.Ardoise, nom))
		end
	end
	anneau(16.3, 40, 3.2, {claire, moyenne}, "Dallage")
	anneau(14, 36, 1.3, {foncee}, "Liseré") -- sous l'anneau des joueurs
	anneau(7.6, 20, 1.6, {claire, moyenne}, "Rosace")
	for k = 0, 7 do -- rayons de la rosace
		local a = k * math.pi / 4
		O.decor(O.bloc(m, Vector3.new(0.3, 0.08, 9.6), versCentre(pt(a, 8.5, y + 0.01)), foncee, M.Ardoise, "Joint"))
	end
	O.decor(O.cylindre(m, 0.12, 7.2, CFrame.new(c.X, y + 0.03, c.Z), foncee, M.Ardoise, "Medaillon"))
	O.decor(O.cylindre(m, 0.14, 5, CFrame.new(c.X, y + 0.04, c.Z), moyenne, M.Ardoise, "Medaillon"))
	for k = 0, 3 do -- étoile à 8 branches en laiton
		O.decor(O.bloc(m, Vector3.new(0.5, 0.06, 4.6), CFrame.new(c.X, y + 0.12, c.Z) * CFrame.Angles(0, k * math.pi / 4, 0), orVieilli, M.Metal, "Etoile"))
	end
	local N = 40
	local Lm = 2 * math.pi * (RE + 0.6) / N * 1.04
	for k = 0, N - 1 do -- marche basse sur le bord nord de la dalle (hors du parvis)
		local p = pt((k + 0.5) * 2 * math.pi / N, RE + 0.6, niveau - 0.15)
		if p.Z < ZN - 0.4 and not presBatiment(p.X, p.Z, 0.6) then
			O.bloc(m, Vector3.new(Lm, 0.9, 1.2), versCentre(p), foncee:Lerp(moyenne, 0.4), M.Ardoise, "Marche")
		end
	end
	local xMarche = math.sqrt((RE + 0.6) ^ 2 - (c.Z - ZN) ^ 2) -- la dalle croise le bord nord du parvis
	for _, s in {-1, 1} do
		local l = DL + 0.2 - xMarche
		O.bloc(m, Vector3.new(l, 0.9, 1.2), CFrame.new(c.X + s * (xMarche + l / 2), niveau - 0.15, ZN - 0.6), foncee:Lerp(moyenne, 0.4), M.Ardoise, "Marche")
	end

	-- 7. Murs de soutènement est / ouest : pierre taillée, aussi hauts que le terrain retenu (aucune terre à nu)
	for _, w in murs do
		if w.coin then
			continue
		end
		local zc = w.z + 2
		local coul = pierre:Lerp(pierreClaire, rng:NextNumber(0, 0.25))
		O.bloc(m, Vector3.new(4, w.h + 3, 4.05), CFrame.new(c.X + w.s * (DL + 2), y - 3 + (w.h + 3) / 2, zc), coul, M.Ardoise, "Mur")
		O.bloc(m, Vector3.new(4.8, 0.7, 4.1), CFrame.new(c.X + w.s * (DL + 1.6), y + w.h + 0.35, zc), pierreClaire, M.Ardoise, "Couronnement")
		O.bloc(m, Vector3.new(0.6, 1.6, 4.05), CFrame.new(c.X + w.s * (DL - 0.3), y + 0.8, zc), pierreSombre, M.Ardoise, "Soubassement")
		if (w.z - ZN) % 8 == 4 then -- pilastre tous les 8 studs
			O.bloc(m, Vector3.new(0.8, w.h - 0.4, 1.6), CFrame.new(c.X + w.s * (DL - 0.4), y + (w.h - 0.4) / 2, zc), pierreClaire:Lerp(pierre, 0.5), M.Ardoise, "Pilastre")
		end
		for _, yy in {6.5, 13, 19.5, 26} do -- assises claires
			if yy < w.h - 1 then
				O.decor(O.bloc(m, Vector3.new(0.3, 0.45, 4.05), CFrame.new(c.X + w.s * (DL - 0.15), y + yy, zc), pierreClaire, M.Ardoise, "Assise"))
			end
		end
	end

	-- 8. La Porte des boss : porte naine taillée dans la montagne (face avant à ZF, corps de 8 studs dans la roche).
	--    Silhouette en gradins : corps central (x ±16, hauteur HF), ailes plus basses (HA) ; roche au-dessus (5b).
	local function plaque(l, h, x, yy, saillie, couleur, mat, nom) -- bloc plaqué : face avant à ZF - saillie
		return O.bloc(m, Vector3.new(l, h, saillie + 0.5), CFrame.new(c.X + x, y + yy, ZF + (0.5 - saillie) / 2), couleur, mat, nom)
	end
	O.bloc(m, Vector3.new(32, HF + 3, 8), CFrame.new(c.X, y - 3 + (HF + 3) / 2, ZF + 4), pierreSombre, M.Ardoise, "Facade")
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(8, HA + 3, 8), CFrame.new(c.X + s * 20, y - 3 + (HA + 3) / 2, ZF + 4), pierreSombre, M.Ardoise, "Facade")
	end
	plaque(2 * DL + 8, 2.2, 0, 0.1, 1, pierreSombre, M.Ardoise, "Soubassement")
	-- appareil de pierre taillée : moellons décalés d'une rangée à l'autre, teintes et saillies variées, joints sombres
	local rangee = 0
	for yy = 1.2, HF - 3.5, 3 do
		rangee += 1
		local x = -DL + (if rangee % 2 == 0 then 2.5 else 0)
		while x < DL - 0.1 do
			local fin = x + rng:NextNumber(4, 6.5)
			for _, borne in {-16, 16, DL} do -- coupe aux angles du corps central
				if x < borne - 0.01 then
					fin = math.min(fin, borne)
					break
				end
			end
			local xm = (x + fin) / 2
			local limite = if math.abs(xm) > 16 then HA else HF
			local portail = math.abs(xm) < 9 and yy < 21.6
			if fin - x > 1 and yy + 3 <= limite - 0.4 and not portail then
				local coul = pierre:Lerp(pierreSombre, rng:NextNumber(0, 0.4)):Lerp(pierreClaire, rng:NextNumber(0, 0.25))
				plaque(fin - x - 0.3, 2.7, xm, yy + 1.5, rng:NextNumber(0.12, 0.4), coul, M.Ardoise, "Moellon")
			end
			x = fin
		end
	end
	for _, d in {{-9.6, 2, HF}, {9.6, 2, HF}, {-15.6, 1.6, HF}, {15.6, 1.6, HF}} do -- pilastres
		plaque(d[2], d[3] + 1, d[1], (d[3] - 1) / 2, 1.2, pierreClaire:Lerp(pierre, 0.35), M.Ardoise, "Pilastre")
		plaque(d[2] + 0.8, 1.6, d[1], 0.8, 1.6, pierreSombre, M.Ardoise, "BasePilastre")
		plaque(d[2] + 0.8, 0.8, d[1], 21.4, 1.6, pierreClaire, M.Ardoise, "Chapiteau")
	end
	-- portail : montants, linteau gravé, fronton en pointe (style nain)
	for _, s in {-1, 1} do
		plaque(2.4, 14, s * 7.2, 8.2, 1.6, pierreClaire, M.Ardoise, "Montant")
		plaque(3, 1.2, s * 7.2, 1.8, 2, pierreSombre, M.Ardoise, "BaseMontant")
		O.coin(m, Vector3.new(1.4, 4, 8.6), CFrame.new(c.X + s * 4.3, y + 19.6, ZF - 0.5) * CFrame.Angles(0, -s * math.pi / 2, 0), pierreClaire, M.Ardoise, "Fronton")
	end
	local linteau = plaque(17.2, 2.4, 0, 16.4, 1.8, pierreClaire, M.Ardoise, "Linteau")
	O.texte(linteau, Enum.NormalId.Front, "ARÈNE DES BOSS", {couleur = orTexte, lumiere = 0.2, ppp = 30})
	plaque(12.6, 14.2, 0, 8.2, 0.2, Color3.fromRGB(20, 18, 20), M.Ardoise, "Embrasure")
	-- battants de fer sombre sur âme de bois foncé, runes, anneaux
	for _, s in {-1, 1} do
		plaque(5.9, 14, s * 3, 8.2, 0.5, Color3.fromRGB(44, 42, 46), M.Metal, "Battant")
		for _, x in {-1.5, 1.5} do -- planches de bois foncé entre les ferrures
			plaque(2.6, 13.4, s * 3 + x, 8.2, 0.6, Color3.fromRGB(46, 32, 24), M.Bois, "Planche")
		end
		for _, yy in {3.4, 8.2, 13} do
			plaque(5.7, 0.7, s * 3, yy, 0.8, fer, M.Rouille, "Ferrure")
		end
		for _, yy in {5.8, 10.6} do
			local r = O.decor(O.bloc(m, Vector3.new(0.9, 0.9, 0.3), CFrame.new(c.X + s * 3, y + yy, ZF - 0.7) * CFrame.Angles(0, 0, math.pi / 4), rune, M.Neon, "Rune"))
			r.Transparency = 0.35
			O.decor(O.bloc(m, Vector3.new(1.4, 0.16, 0.3), CFrame.new(c.X + s * 3, y + yy - 0.95, ZF - 0.7), rune:Lerp(Color3.new(), 0.3), M.Neon, "Rune")).Transparency = 0.45
		end
		local cx = c.X + s * 1.3 -- anneau de tirage
		for _, d in {{0, 0.55, 1.3, 0.25}, {0, -0.55, 1.3, 0.25}, {0.55, 0, 0.25, 1.3}, {-0.55, 0, 0.25, 1.3}} do
			O.decor(O.bloc(m, Vector3.new(d[3], d[4], 0.25), CFrame.new(cx + d[1], y + 6.4 + d[2], ZF - 1.0), orVieilli, M.Metal, "Anneau"))
		end
	end
	plaque(0.35, 14, 0, 8.2, 0.9, fer, M.Metal, "Joint")
	-- chaînes croisées et cadenas : la porte est scellée
	O.bloc(m, Vector3.new(1.8, 2, 0.8), CFrame.new(c.X, y + 8.4, ZF - 1.5), orVieilli, M.Metal, "Cadenas")
	O.decor(O.bloc(m, Vector3.new(0.3, 0.6, 0.1), CFrame.new(c.X, y + 8.2, ZF - 1.92), Color3.fromRGB(26, 22, 20), M.Metal, "Serrure"))
	for _, s in {-1, 1} do
		O.decor(O.bloc(m, Vector3.new(0.28, 1, 0.28), CFrame.new(c.X + s * 0.6, y + 9.8, ZF - 1.5), fer, M.Metal, "Anse"))
		chaine(Vector3.new(c.X + s * 7.2, y + 14.6, ZF - 1.9), Vector3.new(c.X + s * 0.6, y + 10.2, ZF - 1.6), 0.8, 9)
	end
	O.decor(O.bloc(m, Vector3.new(1.5, 0.28, 0.28), CFrame.new(c.X, y + 10.3, ZF - 1.5), fer, M.Metal, "Anse"))
	-- frise et emblèmes des 3 boss (couleurs mates), sur le corps central
	plaque(30, 5, 0, 24.5, 0.8, pierreSombre:Lerp(pierre, 0.3), M.Ardoise, "Frise")
	for _, yy in {22.1, 26.9} do
		plaque(30, 0.3, 0, yy, 0.95, orVieilli, M.Metal, "Filet")
	end
	local function medaillon(x)
		local cf = CFrame.new(c.X + x, y + 24.5, ZF)
		O.bloc(m, Vector3.new(3.3, 3.3, 1.4), cf * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, 0, math.pi / 4), orVieilli, M.Metal, "Medaillon")
		O.bloc(m, Vector3.new(2.7, 2.7, 1.4), cf * CFrame.new(0, 0, -0.7) * CFrame.Angles(0, 0, math.pi / 4), pierreSombre, M.Ardoise, "Medaillon")
		return cf * CFrame.new(0, 0, -1.5)
	end
	do -- Titan de cristal : trois prismes violets
		local cf = medaillon(-12.7)
		local violet = Color3.fromRGB(124, 88, 176)
		for _, d in {{0, 0.15, 0.8, 2, 0}, {-0.65, -0.3, 0.6, 1.3, 0.35}, {0.65, -0.3, 0.6, 1.3, -0.35}} do
			O.decor(O.bloc(m, Vector3.new(d[3], d[4], 0.4), cf * CFrame.new(d[1], d[2], 0) * CFrame.Angles(0, 0, d[5]), violet, M.Lisse, "Embleme"))
		end
	end
	do -- Seigneur de braise : flamme
		local cf = medaillon(0)
		for _, d in {{-0.35, 1.4, Color3.fromRGB(170, 70, 28)}, {0.4, 0.95, Color3.fromRGB(200, 108, 40)}, {0.95, 0.5, Color3.fromRGB(214, 156, 66)}} do
			O.decor(O.bloc(m, Vector3.new(d[2], d[2], 0.4), cf * CFrame.new(0, d[1], 0) * CFrame.Angles(0, 0, math.pi / 4), d[3], M.Lisse, "Embleme"))
		end
	end
	do -- Reine araignée : corps et huit pattes
		local cf = medaillon(12.7)
		local noir = Color3.fromRGB(52, 38, 62)
		O.decor(O.bloc(m, Vector3.new(0.9, 1.2, 0.4), cf * CFrame.new(0, -0.2, 0), noir, M.Lisse, "Embleme"))
		O.decor(O.bloc(m, Vector3.new(0.6, 0.5, 0.4), cf * CFrame.new(0, 0.6, 0), noir, M.Lisse, "Embleme"))
		O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 0.45), cf * CFrame.new(0, -0.25, 0), Color3.fromRGB(140, 56, 84), M.Lisse, "Embleme"))
		for _, s in {-1, 1} do
			for i = 0, 3 do
				local a = s * (math.rad(-35) + i * math.rad(22))
				O.decor(O.bloc(m, Vector3.new(1.2, 0.14, 0.3), cf * CFrame.new(s * 0.75, 0.5 - i * 0.35, 0) * CFrame.Angles(0, 0, a), noir, M.Lisse, "Embleme"))
			end
		end
	end
	-- corniche à denticules, couronnements crénelés (corps central et ailes), couronne centrale
	plaque(32, 1.4, 0, 28.2, 1.6, pierreClaire, M.Ardoise, "Corniche")
	for x = -15, 15, 2 do
		plaque(0.8, 0.6, x, 27.2, 1.2, pierreClaire:Lerp(pierre, 0.3), M.Ardoise, "Denticule")
	end
	O.bloc(m, Vector3.new(32.4, 0.6, 8.4), CFrame.new(c.X, y + HF + 0.3, ZF + 4), pierreClaire, M.Ardoise, "Couronnement")
	for _, x in {-14, -10, 10, 14} do
		O.bloc(m, Vector3.new(2.4, 2.2, 3), CFrame.new(c.X + x, y + HF + 1.7, ZF + 1), pierre, M.Ardoise, "Merlon")
	end
	for i, l in {16, 10, 5} do
		O.bloc(m, Vector3.new(l, 2, 4), CFrame.new(c.X, y + HF + 1.6 + (i - 1) * 2, ZF + 1.5), if i == 2 then pierreSombre else pierreClaire, M.Ardoise, "Couronne")
	end
	O.decor(O.bloc(m, Vector3.new(1.8, 1.8, 0.4), CFrame.new(c.X, y + HF + 3.6, ZF - 0.6) * CFrame.Angles(0, 0, math.pi / 4), orVieilli, M.Metal, "Couronne"))
	for _, s in {-1, 1} do
		plaque(8, 1, s * 20, HA - 0.5, 1.2, pierreClaire, M.Ardoise, "Corniche")
		O.bloc(m, Vector3.new(8.4, 0.6, 8.4), CFrame.new(c.X + s * 20, y + HA + 0.3, ZF + 4), pierreClaire, M.Ardoise, "Couronnement")
		O.bloc(m, Vector3.new(2.4, 2.2, 3), CFrame.new(c.X + s * 18.2, y + HA + 1.7, ZF + 1), pierre, M.Ardoise, "Merlon")
		-- bannière géante sur l'aile (pioches croisées, losange aux couleurs d'un boss)
		local x = c.X + s * 18
		local haut = HA - 1.6
		O.decor(O.bloc(m, Vector3.new(4.2, 0.35, 0.35), CFrame.new(x, y + haut, ZF - 1.8), orVieilli, M.Metal, "Hampe"))
		O.decor(O.bloc(m, Vector3.new(3.4, 13, 0.15), CFrame.new(x, y + haut - 6.6, ZF - 1.6), Color3.fromRGB(96, 24, 24), M.Tissu, "Banniere"))
		O.decor(O.bloc(m, Vector3.new(3.4, 0.4, 0.2), CFrame.new(x, y + haut - 13, ZF - 1.62), orVieilli, M.Tissu, "Frange"))
		for _, a in {math.pi / 4, -math.pi / 4} do
			O.decor(O.bloc(m, Vector3.new(0.35, 2.8, 0.2), CFrame.new(x, y + haut - 7, ZF - 1.72) * CFrame.Angles(0, 0, a), orVieilli, M.Tissu, "Embleme"))
		end
		local coul = if s == -1 then COULEURS_BOSS[1] else COULEURS_BOSS[2]
		O.decor(O.bloc(m, Vector3.new(1.2, 1.2, 0.2), CFrame.new(x, y + haut - 3.4, ZF - 1.72) * CFrame.Angles(0, 0, math.pi / 4), coul:Lerp(Color3.new(), 0.45), M.Tissu, "Embleme"))
	end
	-- trophée du Seigneur de braise : crâne cornu accroché au-dessus du portail, sur une console (lumière 1,0)
	do
		local cf = CFrame.new(c.X, y + 17.6, ZF - 1.8) -- -Z local = vers la place
		local console = O.bloc(m, Vector3.new(6.6, 0.9, 2.6), cf * CFrame.new(0, 0.45, 0), pierreSombre, M.Ardoise, "Console")
		O.texte(console, Enum.NormalId.Front, "SEIGNEUR DE BRAISE", {couleur = orTexte, lumiere = 0.2, ppp = 40})
		local haut = cf * CFrame.new(0, 0.9, -0.2)
		local os, corne = Color3.fromRGB(150, 138, 118), Color3.fromRGB(46, 34, 30)
		O.bloc(m, Vector3.new(3.2, 2.6, 2.6), haut * CFrame.new(0, 2.1, 0), os, M.Ardoise, "Crane")
		O.bloc(m, Vector3.new(2.6, 0.8, 2.2), haut * CFrame.new(0, 0.4, -0.1), os:Lerp(Color3.new(), 0.2), M.Ardoise, "Machoire")
		for _, s in {-1, 1} do
			O.bloc(m, Vector3.new(0.8, 0.7, 0.12), haut * CFrame.new(s * 0.7, 2.1, -1.3), Color3.fromRGB(24, 20, 18), M.Ardoise, "Orbite")
			local oeil = O.decor(O.bloc(m, Vector3.new(0.36, 0.26, 0.1), haut * CFrame.new(s * 0.7, 2.05, -1.38), Color3.fromRGB(130, 44, 14), M.Neon, "Oeil"))
			oeil.Transparency = 0.3
			local a = (haut * CFrame.new(s * 1.5, 2.9, 0)).Position
			local b2 = (haut * CFrame.new(s * 2.9, 4.1, -0.3)).Position
			segment(a, b2, 0.7, corne, M.Ardoise, "Corne")
			segment(b2, (haut * CFrame.new(s * 3.1, 5.4, 0.3)).Position, 0.45, orVieilli, M.Metal, "Corne")
			local coupelle = cf * CFrame.new(s * 2.8, 0.9, -0.2)
			O.cylindre(m, 0.4, 1.1, coupelle * CFrame.new(0, 0.2, 0), fer, M.Rouille, "Coupelle")
			local braises = O.decor(O.bloc(m, Vector3.new(0.7, 0.12, 0.7), coupelle * CFrame.new(0, 0.42, 0), Color3.fromRGB(120, 40, 12), M.Neon, "Braises"))
			O.feu(braises, 1.2)
			if s == 1 then
				O.lumiere(braises, feu, 1, 14)
			end
		end
	end

	-- 5c. Rochers sur la roche de la montagne (masses irrégulières qui cassent les talus), quelques pins et buissons
	local function roc(p, taille)
		local coul = Color3.fromRGB(64, 60, 58):Lerp(Color3.fromRGB(96, 90, 84), rng:NextNumber())
		O.bloc(m, taille, CFrame.new(p) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, math.pi), rng:NextNumber(-0.35, 0.35)), coul, M.Roche, "Roc")
	end
	local function buisson(p)
		O.decor(O.ellipsoide(m, Vector3.new(rng:NextNumber(2.5, 4), rng:NextNumber(1.6, 2.4), rng:NextNumber(2.5, 4)), CFrame.new(p),
			Color3.fromRGB(46, 66, 40):Lerp(Color3.fromRGB(66, 84, 48), rng:NextNumber()), M.Herbe, "Buisson"))
	end
	for _, s in {-1, 1} do -- rocs tombés sur les ailes de la façade
		roc(Vector3.new(c.X + s * 21.5, y + HA + 2.2, ZF + 3), Vector3.new(6, 4.5, 5))
		roc(Vector3.new(c.X + s * 17.6, y + HA + 1.6, ZF + 4.5), Vector3.new(4, 3, 4))
	end
	if talusSud then
		local H, L = talusSud.H, talusSud.L
		local tMin = (HF + 3 - HA) / H -- au-dessus du corps central
		for _ = 1, 18 do
			local x = rng:NextNumber(-DL - 8, DL + 8)
			local t = rng:NextNumber(if math.abs(x) < 17 then math.min(tMin, 0.9) else 0.05, 0.92)
			local p = Vector3.new(c.X + x, y + HA + t * H, ZF + 3 + t * L - 0.6)
			roc(p, Vector3.new(rng:NextNumber(4, 9), rng:NextNumber(3, 6), rng:NextNumber(4, 7)))
			if rng:NextNumber() < 0.35 then
				buisson(p + Vector3.new(rng:NextNumber(-3, 3), 2.2, rng:NextNumber(0, 1.5)))
			end
		end
		for _, x in {-24, -9, 13, 27} do
			B.pin(m, Vector3.new(c.X + x, y + HA + H - 1.5, ZF + 3 + L - 1), rng:NextNumber(13, 18), rng)
		end
	end
	for _, tc in talusCotes do
		if rng:NextNumber() < 0.6 then
			local t = rng:NextNumber(0.15, 0.8)
			local w = tc.w
			local p = Vector3.new(c.X + w.s * (DL + 2.5 + t * tc.L), y + w.h + t * tc.H, w.z + 2 + rng:NextNumber(-1, 1))
			roc(p, Vector3.new(rng:NextNumber(3.5, 7), rng:NextNumber(2.5, 5), rng:NextNumber(3.5, 7)))
			if rng:NextNumber() < 0.4 then
				buisson(p + Vector3.new(w.s * 1.5, 2, 0))
			end
		end
	end

	-- 9. Nains gardiens géants (≈ 23 studs avec le socle), pierre sombre et or, mains posées sur leur arme
	local function nainGardien(base, arme, k)
		local function b(sx, sy, sz, x, yy, z, coul, mat, nom)
			return O.bloc(m, Vector3.new(sx, sy, sz) * k, base * CFrame.new(x * k, yy * k, z * k), coul or pierreStatue, mat or M.Ardoise, nom)
		end
		local function p(x, yy, z)
			return (base * CFrame.new(x * k, yy * k, z * k)).Position
		end
		local sombre = pierreStatue:Lerp(Color3.new(), 0.25)
		local corneC = Color3.fromRGB(150, 138, 118)
		for _, s in {-1, 1} do
			b(2.2, 1.2, 3, s * 1.35, 0.6, -0.3, sombre, nil, "Botte")
			b(2, 2.4, 2.2, s * 1.35, 2.4, 0, nil, nil, "Jambe")
			b(2.4, 1.5, 3, s * 3.6, 9.2, 0, nil, nil, "Epaulette")
			b(2.5, 0.35, 3.1, s * 3.6, 8.5, 0, orVieilli, M.Metal, "Epaulette")
			segment(p(s * 3.4, 8.8, 0), p(s * 1.1, 6.9, -2.7), 1.6 * k, pierreStatue, M.Ardoise, "Bras")
			b(1.5, 1.5, 1.5, s * 0.95, 6.6, -3, sombre, nil, "Main")
			b(0.6, 0.35, 0.1, s * 0.7, 11.4, -1.52, Color3.fromRGB(20, 18, 18), M.Ardoise, "Oeil")
			segment(p(s * 1.6, 12.9, 0), p(s * 3.1, 14.4, -0.3), 0.8 * k, corneC, M.Ardoise, "Corne")
			segment(p(s * 3.1, 14.4, -0.3), p(s * 3.3, 15.7, 0.2), 0.5 * k, orVieilli, M.Metal, "Corne")
		end
		b(5.8, 1.8, 3.8, 0, 3.9, 0, nil, nil, "Tunique")
		b(6, 0.9, 4, 0, 5.1, 0, sombre, nil, "Ceinture")
		b(1.4, 1, 0.3, 0, 5.1, -2.05, orVieilli, M.Metal, "Boucle")
		b(5.6, 4.2, 3.6, 0, 7.6, 0, nil, nil, "Corps")
		b(3, 2.8, 3, 0, 11.1, 0, nil, nil, "Tete")
		b(0.7, 0.9, 0.6, 0, 10.9, -1.7, nil, nil, "Nez")
		b(2.6, 0.4, 0.4, 0, 11.8, -1.55, sombre, nil, "Sourcils")
		b(3.4, 3.6, 1.4, 0, 9, -1.9, sombre, nil, "Barbe")
		b(2.2, 1.4, 1.2, 0, 6.8, -2, sombre, nil, "Barbe")
		b(2.3, 0.35, 1.3, 0, 6.4, -2, orVieilli, M.Metal, "Anneau")
		b(3, 0.6, 0.5, 0, 10.3, -2.7, sombre, nil, "Moustache")
		b(3.4, 1.4, 3.4, 0, 13, 0, nil, nil, "Casque")
		b(3.5, 0.4, 3.5, 0, 12.4, 0, orVieilli, M.Metal, "Casque")
		b(0.8, 0.8, 3.6, 0, 13.9, 0, sombre, nil, "Cimier")
		b(0.6, 7.4, 0.6, 0, 4.8, -3, C.BoisFonce, M.Bois, "Manche")
		b(0.9, 0.8, 0.9, 0, 8.7, -3, orVieilli, M.Metal, "Pommeau")
		if arme == "marteau" then
			b(3.6, 2.2, 2.2, 0, 1.1, -3, fer, M.Metal, "Masse")
			for _, s in {-1, 1} do
				b(0.3, 2.3, 2.3, s * 1.2, 1.1, -3, orVieilli, M.Metal, "Cerclage")
			end
		else
			b(1.2, 1.8, 1.2, 0, 1.5, -3, fer, M.Metal, "Douille")
			for _, s in {-1, 1} do
				b(1.6, 2.8, 0.35, s * 1.3, 1.6, -3, fer, M.Metal, "Lame")
				b(0.3, 3.2, 0.4, s * 2.15, 1.6, -3, orVieilli, M.Metal, "Fil")
			end
		end
	end
	for _, d in {{-1, "marteau"}, {1, "hache"}} do
		local s = d[1]
		local cf = CFrame.new(c.X + s * 14, y, 165) -- face au nord (vers la place et la rue)
		O.bloc(m, Vector3.new(5.6, 2.2, 5.6), cf * CFrame.new(0, 1.1, 0), pierreSombre, M.Ardoise, "Socle")
		O.bloc(m, Vector3.new(6, 0.4, 6), cf * CFrame.new(0, 2.0, 0), pierreClaire, M.Ardoise, "Socle")
		nainGardien(cf * CFrame.new(0, 2.2, 0), d[2], 1.3)
	end

	-- 10. Braseros sur piliers, à côté des trophées (2 lumières douces)
	for _, s in {-1, 1} do
		local p = Vector3.new(c.X + s * 17.5, y, 158)
		O.bloc(m, Vector3.new(3, 0.8, 3), CFrame.new(p + Vector3.new(0, 0.4, 0)), pierreSombre, M.Ardoise, "Pilier")
		O.bloc(m, Vector3.new(2.4, 4.6, 2.4), CFrame.new(p + Vector3.new(0, 3.1, 0)), pierreClaire:Lerp(pierre, 0.4), M.Ardoise, "Pilier")
		O.bloc(m, Vector3.new(3, 0.5, 3), CFrame.new(p + Vector3.new(0, 5.65, 0)), pierreSombre, M.Ardoise, "Pilier")
		O.cylindre(m, 1, 3.2, CFrame.new(p + Vector3.new(0, 6.4, 0)), fer, M.Rouille, "Coupe")
		local braises = O.decor(O.bloc(m, Vector3.new(2, 0.3, 2), CFrame.new(p + Vector3.new(0, 6.85, 0)), Color3.fromRGB(130, 44, 14), M.Neon, "Braises"))
		O.feu(braises, 3)
		O.lumiere(braises, feu, 1.4, 24)
	end

	-- 11. Trophées du Titan et de la Reine sur hauts socles (le crâne du Seigneur de braise est au-dessus du portail)
	local function socleTrophee(pied)
		local cf = versCentre(pied)
		O.bloc(m, Vector3.new(4.6, 4, 4.6), cf * CFrame.new(0, 2, 0), pierreSombre, M.Ardoise, "Trophee")
		O.bloc(m, Vector3.new(5.2, 0.5, 5.2), cf * CFrame.new(0, 3.9, 0), pierreClaire, M.Ardoise, "Trophee")
		O.bloc(m, Vector3.new(5.2, 0.6, 5.2), cf * CFrame.new(0, 0.3, 0), pierreClaire:Lerp(pierreSombre, 0.5), M.Ardoise, "Trophee")
		return cf * CFrame.new(0, 4.15, 0)
	end
	do -- Titan de cristal : cristal géant (lumière 1,3)
		local haut = socleTrophee(Vector3.new(c.X - 17.6, y, 152.5))
		B.cristal(m, haut, 8, Color3.fromRGB(80, 150, 200), Random.new(71), 16)
	end
	do -- Reine araignée : sa dépouille (sans lumière)
		local haut = socleTrophee(Vector3.new(c.X + 17.6, y, 152.5))
		local k = 1.25
		local function q(x, yy, z)
			return haut * CFrame.new(x * k, yy * k, z * k)
		end
		local noir, violet = Color3.fromRGB(40, 30, 48), Color3.fromRGB(86, 50, 108)
		O.ellipsoide(m, Vector3.new(3.2, 2.6, 3.8) * k, q(0, 1.4, 0.9), noir, M.Lisse, "Abdomen")
		O.decor(O.bloc(m, Vector3.new(0.8, 0.12, 1.6) * k, q(0, 2.7, 0.9), violet, M.Lisse, "Marque"))
		O.ellipsoide(m, Vector3.new(2.2, 1.6, 2.2) * k, q(0, 1, -1.2), noir:Lerp(violet, 0.3), M.Lisse, "Tete")
		for _, e in {{-0.45, 1.45}, {0.45, 1.45}, {-0.25, 1.15}, {0.25, 1.15}} do
			O.decor(O.bloc(m, Vector3.new(0.3, 0.3, 0.15) * k, q(e[1], e[2], -2.25), Color3.fromRGB(90, 40, 110), M.Neon, "Oeil"))
		end
		for _, s in {-1, 1} do
			O.bloc(m, Vector3.new(0.3, 0.9, 0.3) * k, q(s * 0.35, 0.45, -2.2) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(150, 138, 118), M.Ardoise, "Croc")
			for i = 1, 4 do
				local base = q(s * 0.9, 1.1, -1.9 + i * 0.5).Position
				local genou = q(s * 2.5, 2.7, -2.8 + i * 1.1).Position
				local pied = q(s * 2.9, -0.6, -3.1 + i * 1.3).Position
				segment(base, genou, 0.4 * k, noir, M.Lisse, "Patte")
				segment(genou, pied, 0.3 * k, noir, M.Lisse, "Patte")
				O.decor(O.bloc(m, Vector3.new(0.5, 0.5, 0.5) * k, CFrame.new(genou), violet, M.Lisse, "Genou"))
			end
		end
	end

	-- 12. Gradins latéraux (3 rangs de pierre contre les murs, au nord des trophées)
	for _, s in {-1, 1} do
		for k = 1, 3 do
			local w = 1.3 * (4 - k)
			O.bloc(m, Vector3.new(w, 1.1 * k + 0.8, 6), CFrame.new(c.X + s * (DL - w / 2), y - 0.8 + (1.1 * k + 0.8) / 2, 144), pierre:Lerp(pierreSombre, 0.3), M.Ardoise, "Gradin")
			O.bloc(m, Vector3.new(w + 0.1, 0.25, 6.2), CFrame.new(c.X + s * (DL - w / 2), y + 1.1 * k + 0.1, 144), pierreClaire, M.Ardoise, "Gradin")
		end
	end

	-- 13. Côté rue : deux piliers bas à lanternes de part et d'autre de l'avenue (la vue depuis le pont reste dégagée)
	for _, s in {-1, 1} do
		local p = Vector3.new(c.X + s * (R.SUD_LARGEUR / 2 + 2), niveau, c.Z - RE + 1.5)
		O.bloc(m, Vector3.new(2.8, 1.2, 2.8), CFrame.new(p + Vector3.new(0, 0.3, 0)), pierreSombre, M.Ardoise, "Pilier")
		O.bloc(m, Vector3.new(2.2, 4.6, 2.2), CFrame.new(p + Vector3.new(0, 3.2, 0)), pierreClaire:Lerp(pierre, 0.4), M.Ardoise, "Pilier")
		O.bloc(m, Vector3.new(2.8, 0.6, 2.8), CFrame.new(p + Vector3.new(0, 5.8, 0)), pierreSombre, M.Ardoise, "Chapiteau")
		O.bloc(m, Vector3.new(1.4, 0.3, 1.4), CFrame.new(p + Vector3.new(0, 6.25, 0)), fer, M.Metal, "Lanterne")
		local verre = O.decor(O.bloc(m, Vector3.new(1.1, 1.3, 1.1), CFrame.new(p + Vector3.new(0, 7.05, 0)), Color3.fromRGB(120, 84, 50), M.Verre, "Lanterne"))
		verre.Transparency = 0.45
		local flamme = O.decor(O.bloc(m, Vector3.new(0.35, 0.55, 0.35), CFrame.new(p + Vector3.new(0, 6.95, 0)), Color3.fromRGB(190, 110, 46), M.Neon, "Flamme"))
		O.bloc(m, Vector3.new(1.5, 0.35, 1.5), CFrame.new(p + Vector3.new(0, 7.85, 0)), fer, M.Metal, "Lanterne")
		O.lumiere(flamme, feu, 1, 14)
	end

	m:SetAttribute("Centre", Vector3.new(c.X, y, c.Z))
	m:SetAttribute("Version", PLACE_BOSS_VERSION)
	m:SetAttribute("HauteurFacade", HF)
	return m
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
	Village.retirerSauleDuPont(v)
	falaises(v, rng)
	cristaux(v, rng)
	Village.preparerToits(v)
	Village.preparerSentiers(v)
end

return Village
