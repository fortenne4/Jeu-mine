-- Mine privée : une galerie par joueur, construite en Parts (pas en terrain) pour être creusée.
-- Galerie étayée (~28 studs), torches, rail, petit wagonnet, creusée DANS un très grand massif de roche en blocs
-- de 2 studs (80 de large, 836 de long, 696 de haut) ; au bout, une descente en pente (~35°) : on creuse en descendant.
-- 8 couches de minage selon la profondeur (Partage › CouchesMine) : couleur de roche, minerais, pioche requise.
-- Grille virtuelle côté serveur : le massif est plein par défaut, on ne stocke que les cases CREUSÉES ;
-- seules les cases pleines EXPOSÉES (voisines de l'air) existent en Parts (tag « BlocMine », attributs
-- Colonne / Ligne / Couche) ; creuser fait apparaître les voisines.
-- Minerais : nœuds enfouis (le même modèle que la mine publique, Partage › MineraisModeles), créés seulement
-- quand une case voisine est à l'air ; la roche ne paie rien, on casse le nœud à la pioche (tag « Minerai »).
-- Repère local : sol de la galerie à Y = 0, le joueur regarde vers -Z.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local CouchesMine = require(Partage:WaitForChild("CouchesMine"))
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local Cercle = require(script.Parent.CercleLumineux)
local M, C = O.M, O.C

local MinePrivee = {}

MinePrivee.TAILLE_BLOC = 2
MinePrivee.ZONE_COUP = Vector3.new(4.5, 5.5, 3) -- zone d'un coup : largeur × hauteur × profondeur (≈ le joueur)

local T = MinePrivee.TAILLE_BLOC
local LARGEUR = 16                        -- intérieur de la galerie (X)
local LARGEUR_MASSIF = 80                 -- intérieur du massif (X)
local HAUTEUR = 12                        -- hauteur de la galerie
local Z_ARRIERE = 8                       -- paroi derrière le point d'apparition
local Z_MUR = -20                         -- bout de la galerie : la descente commence ici
local LONGUEUR_MASSIF = 800
local Z_FOND = Z_MUR - LONGUEUR_MASSIF    -- -820, roche-mère au bout du massif
local Y_BAS = -676                        -- roche-mère au fond du massif (338 m sous la galerie)
-- Marge de roche minable entre la galerie / la descente et la roche-mère (3 blocs) : la galerie est creusée DANS
-- le massif, qui l'entoure sur les côtés, au-dessus et derrière
local MARGE = 3 * T
local Y_HAUT = HAUTEUR + 2 + MARGE        -- 20 : haut du massif (plafond de la galerie 12..14 + 3 blocs)
local Z_AVANT = Z_ARRIERE + 2 + MARGE     -- 16 : avant du massif (fond arrière de la galerie 8..10 + 3 blocs)
local PENTE = math.tan(math.rad(35))      -- pente de la face de départ
local LONGUEUR_PENTE = 16                 -- partie déjà ouverte de la descente
local LARGEUR_PENTE = LARGEUR + 8         -- 24 : largeur de la descente ouverte (la roche l'entoure)
local Z_RETOUR = 1.5                      -- cercle de sortie (anneau r 5.5)
local Z_APPARITION = -7

-- Grille : Colonne i (X, 1 = gauche vu du joueur), Ligne j (Y, 1 = bas), Couche k (profondeur, 1 = avant du massif,
-- derrière la galerie). Les cases de la galerie (intérieur, murs, sol, plafond) ne font pas partie du massif.
local NX = LARGEUR_MASSIF // T            -- 40
local NY = (Y_HAUT - Y_BAS) // T          -- 348
local NZ = (Z_AVANT - Z_FOND) // T        -- 418
MinePrivee.COLONNES, MinePrivee.LIGNES, MinePrivee.COUCHES = NX, NY, NZ

-- Repères pour les autres scripts (RemonterMine.server) : repère local de mine.base
MinePrivee.LIMITES = {demiLargeur = LARGEUR_MASSIF / 2 + 4, zMin = Z_FOND - 10, zMax = Z_AVANT + 6, yMin = Y_BAS - 15}

-- Nœuds de minerai enfouis et roche : selon la COUCHE de minage (Partage › CouchesMine, profondeur en m =
-- blocs sous le sol de la galerie). Le massif est découpé en paquets de 3 × 3 × 3 cases : chaque paquet abrite
-- au plus UN nœud, tiré dans les minerais de sa couche (tirage déterministe nouveau à chaque visite).
-- id = clé de MineraisModeles.VISUEL et de Forge.MINERAIS ; pv = CouchesMine.PV.
-- Creuser la roche d'une couche dépend du palier de la pioche (Partage › CouchesMine.PALIERS_PIOCHES).
local PAQUET = 3
local PI_, PJ_ = NX // PAQUET + 2, NY // PAQUET + 2 -- dimensions de la grille des paquets (clé unique)
local ECHELLE_NOEUD = 0.8 -- le rocher (≈ 3 studs) tient dans sa case de 2 et mord un peu dans la roche autour

local PIERRE = Color3.fromRGB(116, 113, 110)
local PAROI = Color3.fromRGB(70, 66, 64)
local FLAMME = Color3.fromRGB(255, 170, 80)

local mines = {}   -- [joueur] = {modele, apparition, centreRetour, retour}
local occupes = {} -- [index d'emplacement] = true
local visites = 0  -- mines construites sur ce serveur (mélangé à la graine des nœuds)
local dossier

local function emplacement(i)
	local col = (i - 1) % D.MINES_PRIVEES_COLONNES
	local rang = (i - 1) // D.MINES_PRIVEES_COLONNES
	return D.MINES_PRIVEES_ORIGINE + Vector3.new(col * D.MINES_PRIVEES_ECART, 0, -rang * D.MINES_PRIVEES_ECART_Z)
end

-- Roche-mère : couche INMINABLE sur les 6 faces de la zone de minage, derrière au moins 3 blocs de roche minable
-- autour de la galerie et de la descente (MARGE). Pavés presque noirs reconnaissables au premier coup d'œil
-- (aucune couche de minage n'utilise ce matériau ni cette teinte). Ces Parts sont hors de la grille : la pioche
-- n'y retire rien (MinePrivee.creuser ne touche que les cases du massif).
local ROCHE_MERE = Color3.fromRGB(30, 30, 36)
local EPAISSEUR_MERE = 4

local function rocheMere(m, taille, cf, nom)
	local p = O.bloc(m, taille, cf, ROCHE_MERE, M.Pierre, nom)
	p:SetAttribute("Inminable", true)
	return p
end

-- Coque fermée et indestructible : galerie + boîte de roche-mère autour du massif (on ne peut pas tomber dans le vide)
local function coque(m, base)
	local E = EPAISSEUR_MERE
	-- Galerie (creusée dans le massif) : plafond, murs, fond arrière et sol de 2 studs ; ces cases-là sont hors massif
	local longueurGalerie = Z_ARRIERE + 2 - Z_MUR
	local zg = Z_MUR + longueurGalerie / 2
	O.bloc(m, Vector3.new(LARGEUR + 4, 2, longueurGalerie), base * CFrame.new(0, HAUTEUR + 1, zg), PAROI, M.Roche, "Plafond")
	for _, s in {-1, 1} do
		O.bloc(m, Vector3.new(2, HAUTEUR, longueurGalerie), base * CFrame.new(s * (LARGEUR / 2 + 1), HAUTEUR / 2, zg), PAROI, M.Roche, "Mur")
	end
	O.bloc(m, Vector3.new(LARGEUR + 4, 2, longueurGalerie), base * CFrame.new(0, -1, zg), Color3.fromRGB(78, 72, 66), M.Ardoise, "Sol")
	O.bloc(m, Vector3.new(LARGEUR, HAUTEUR, 2), base * CFrame.new(0, HAUTEUR / 2, Z_ARRIERE + 1), PAROI, M.Roche, "FondArriere")
	-- Massif (de Z_AVANT à Z_FOND, de Y_BAS à Y_HAUT) : boîte de roche-mère sur les 6 faces
	local L, H = Z_AVANT - Z_FOND, Y_HAUT - Y_BAS
	local zm, yc = (Z_AVANT + Z_FOND) / 2, (Y_HAUT + Y_BAS) / 2
	for _, s in {-1, 1} do
		rocheMere(m, Vector3.new(E, H + 2 * E, L + 2 * E), base * CFrame.new(s * (LARGEUR_MASSIF / 2 + E / 2), yc, zm), "RocheMereCote")
	end
	rocheMere(m, Vector3.new(LARGEUR_MASSIF, E, L + 2 * E), base * CFrame.new(0, Y_BAS - E / 2, zm), "RocheMereFond")
	rocheMere(m, Vector3.new(LARGEUR_MASSIF, E, L + 2 * E), base * CFrame.new(0, Y_HAUT + E / 2, zm), "RocheMerePlafond")
	rocheMere(m, Vector3.new(LARGEUR_MASSIF, H, E), base * CFrame.new(0, yc, Z_FOND - E / 2), "RocheMereBout")
	rocheMere(m, Vector3.new(LARGEUR_MASSIF, H, E), base * CFrame.new(0, yc, Z_AVANT + E / 2), "RocheMereAvant")
end

-- Moellons irréguliers qui dépassent des parois de la galerie (aspect « roche taillée en blocs »)
local function moellons(m, base, rng)
	for _ = 1, 18 do
		local s = rng:NextNumber(2, 3.6)
		local z = rng:NextNumber(Z_MUR + 1, Z_ARRIERE - 1)
		local teinte = PAROI:Lerp(PIERRE, rng:NextNumber(0, 0.7))
		local cf
		if rng:NextNumber() < 0.7 then
			local cote = if rng:NextNumber() < 0.5 then -1 else 1
			cf = CFrame.new(cote * (LARGEUR / 2 + s / 2 - 0.6), rng:NextNumber(1, HAUTEUR - 1), z)
		else
			cf = CFrame.new(rng:NextNumber(-LARGEUR / 2 + 2, LARGEUR / 2 - 2), HAUTEUR + s / 2 - 0.5, z)
		end
		O.decor(O.bloc(m, Vector3.new(s, s, s), base * cf, teinte, if rng:NextNumber() < 0.5 then M.Ardoise else M.Pierre, "Moellon"))
	end
	for _ = 1, 4 do
		local w = rng:NextNumber(3, 6)
		O.decor(O.bloc(m, Vector3.new(w, 0.06, w * 0.7), base * CFrame.new(rng:NextNumber(-5, 5), 0.03, rng:NextNumber(Z_MUR + 2, Z_ARRIERE - 2))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), C.Terre:Lerp(PAROI, 0.4), M.Terre, "Terre"))
	end
end

local function torche(m, base, cote, z)
	local tige = base * CFrame.new(cote * 6.6, 7, z) * CFrame.Angles(0, 0, cote * math.rad(22))
	O.decor(O.bloc(m, Vector3.new(0.35, 1.6, 0.35), tige, C.Bois, M.Bois, "Torche"))
	local flamme = O.decor(O.bloc(m, Vector3.new(0.5, 0.5, 0.5), tige * CFrame.new(0, 0.95, 0), FLAMME, M.Neon, "Flamme"))
	O.lumiere(flamme, FLAMME, 1.5, 18)
	O.etincelles(flamme, FLAMME, 2)
end

-- Étais tous les 6 studs : deux poteaux, un chapeau et deux jambes de force
local function etais(m, base)
	local x = LARGEUR / 2 - 0.6
	local i = 0
	for z = Z_ARRIERE - 2, Z_MUR + 1, -6 do
		for _, s in {-1, 1} do
			O.bloc(m, Vector3.new(1.2, HAUTEUR, 1.2), base * CFrame.new(s * x, HAUTEUR / 2, z), C.Bois, M.Bois, "Poteau")
			O.decor(O.bloc(m, Vector3.new(0.8, 3.2, 0.8), base * CFrame.new(s * (x - 1.3), HAUTEUR - 1.9, z) * CFrame.Angles(0, 0, s * math.rad(45)),
				C.Bois, M.Bois, "JambeDeForce"))
		end
		O.bloc(m, Vector3.new(LARGEUR, 1.2, 1.4), base * CFrame.new(0, HAUTEUR - 0.6, z), C.BoisFonce, M.Bois, "Chapeau")
		i += 1
		torche(m, base, if i % 2 == 0 then 1 else -1, z)
	end
	torche(m, base, 1, Z_MUR + 2) -- dernier étai éclairé des deux côtés : le mur reste lisible
end

-- Bout de voie étroite, côté droit, avec un petit wagonnet de charbon (65 %)
local ECHELLE_WAGON = 0.65
local function rail(m, base, rng)
	local x, z0, z1 = 4.5, -5.5, Z_MUR + 0.5
	local L = z0 - z1
	for _, dx in {-1.6, 1.6} do
		O.decor(O.bloc(m, Vector3.new(0.25, 0.3, L), base * CFrame.new(x + dx, 0.48, (z0 + z1) / 2), Color3.fromRGB(87, 68, 54), M.Rouille, "Rail"))
	end
	for z = z0 - 0.6, z1 + 0.4, -1.8 do
		O.decor(O.bloc(m, Vector3.new(4.2, 0.3, 0.8), base * CFrame.new(x, 0.15, z), Color3.fromRGB(70, 47, 32), M.Planches, "Traverse"))
	end
	O.bloc(m, Vector3.new(4.2, 0.9, 0.8), base * CFrame.new(x, 0.45, z0 + 0.3), C.BoisFonce, M.Bois, "Heurtoir")
	local wagon = B.wagonnet(m, base * CFrame.new(x, 0, -13), Color3.fromRGB(34, 34, 38), rng)
	wagon:ScaleTo(ECHELLE_WAGON)
	wagon:PivotTo(wagon:GetPivot() - Vector3.new(0, 3.1 * (1 - ECHELLE_WAGON), 0)) -- roues sur les rails
end

local function details(m, base, joueur)
	B.caisse(m, base * CFrame.new(-6.1, 0, -9) * CFrame.Angles(0, 0.15, 0))
	B.caisse(m, base * CFrame.new(-6, 2.6, -8.9) * CFrame.Angles(0, -0.3, 0), 1.8)
	B.tonneau(m, base * CFrame.new(-6, 0, -14.5))
	-- Pioche plantée dans le sol, près du mur
	local p = base * CFrame.new(-4.4, 0.6, -16.5) * CFrame.Angles(0, 0.7, 0) * CFrame.Angles(math.rad(35), 0, 0)
	O.decor(O.bloc(m, Vector3.new(0.35, 0.35, 2.6), p, Color3.fromRGB(150, 154, 162), M.Metal, "TetePioche"))
	O.decor(O.bloc(m, Vector3.new(0.3, 3.6, 0.3), p * CFrame.new(0, 1.8, 0), C.Bois, M.Bois, "ManchePioche"))
	-- Toiles d'araignée dans les coins du plafond
	for _, t in {{-1, -4}, {1, 3}} do
		local centre = base * CFrame.new(t[1] * (LARGEUR / 2 - 0.05), HAUTEUR - 0.4, t[2])
		for k = 0, 3 do
			local fil = O.decor(O.bloc(m, Vector3.new(0.04, 0.04, 3.2), centre * CFrame.Angles(k * math.pi / 4, 0, 0), Color3.fromRGB(225, 225, 225), M.Tissu, "Toile"))
			fil.Transparency = 0.35
		end
	end
	-- Panneau au-dessus de la sortie
	local panneau = O.bloc(m, Vector3.new(8, 1.8, 0.3), base * CFrame.new(0, 9.2, Z_ARRIERE - 0.15), C.Bois, M.Planches, "Panneau")
	O.texte(panneau, Enum.NormalId.Front, "Mine de " .. joueur.DisplayName)
end

-- ================= Massif de blocs (grille virtuelle) =================

local function indice(i, j, k)
	return i + (j - 1) * NX + (k - 1) * NX * NY
end

local function centreCase(i, j, k)
	return Vector3.new(-LARGEUR_MASSIF / 2 + T * (i - 0.5), Y_BAS + T * (j - 0.5), Z_AVANT - T * (k - 0.5))
end

local function dansGrille(i, j, k)
	return i >= 1 and i <= NX and j >= 1 and j <= NY and k >= 1 and k <= NZ
end

-- Cases de la galerie (intérieur + murs, sol, plafond, fond arrière) : hors massif, jamais de bloc ni de creusage
local function dansGalerie(c: Vector3)
	return c.Z > Z_MUR and c.Z < Z_ARRIERE + 2 and math.abs(c.X) < LARGEUR / 2 + 2 and c.Y > -2 and c.Y < HAUTEUR + 2
end
local function interieurGalerie(c: Vector3)
	return c.Z > Z_MUR and c.Z < Z_ARRIERE and math.abs(c.X) < LARGEUR / 2 and c.Y > 0 and c.Y < HAUTEUR
end

-- Au départ : une descente ouverte (sol et plafond en pente) au bout de la galerie, à peine plus large qu'elle :
-- la roche minable l'entoure de tous côtés ; tout le reste est plein
local K_OUVERT = (Z_AVANT - Z_MUR + LONGUEUR_PENTE) // T + 1 -- dernière couche k touchée par la descente
local function ouverteAuDepart(c: Vector3)
	local d = Z_MUR - c.Z
	local s = -PENTE * d
	return d >= 0 and d <= LONGUEUR_PENTE and math.abs(c.X) < LARGEUR_PENTE / 2 and c.Y > s and c.Y < s + HAUTEUR
end

local function estPleine(mine, i, j, k)
	if mine.creuses[indice(i, j, k)] then return false end
	local c = centreCase(i, j, k)
	return not dansGalerie(c) and not ouverteAuDepart(c)
end

local VOISINS = {Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)}

-- Hors grille : roche-mère (jamais de l'air). Dans la galerie : seul son intérieur est de l'air.
local function estAir(mine, i, j, k)
	if not dansGrille(i, j, k) then return false end
	local c = centreCase(i, j, k)
	if dansGalerie(c) then return interieurGalerie(c) end
	return mine.creuses[indice(i, j, k)] == true or ouverteAuDepart(c)
end

local function expose(mine, i, j, k)
	for _, v in VOISINS do
		if estAir(mine, i + v.X, j + v.Y, k + v.Z) then return true end
	end
	return false
end

-- Nœud du paquet (I, J, K) : case et minerai tirés une fois (mémorisés) ; décalage 1 ou 2 dans le paquet,
-- donc deux nœuds ne sont jamais collés
-- Profondeur (m) d'une case, avec une petite ondulation : les limites entre couches ne sont pas des plans parfaits
local function profondeurCase(i, j, k)
	return -centreCase(i, j, k).Y / T + math.noise(i * 0.09, k * 0.09, 3.7) * 3
end
local function coucheCase(i, j, k)
	return CouchesMine.index(profondeurCase(i, j, k))
end

-- Minerais de chaque couche : {id, chance, pv}
local MINERAIS_COUCHE = {}
for c, couche in CouchesMine.LISTE do
	MINERAIS_COUCHE[c] = {}
	for _, e in couche.minerais do
		table.insert(MINERAIS_COUCHE[c], {id = e[1], chance = e[2], pv = CouchesMine.PV[e[1]] or 2})
	end
end

local function noeudDuPaquet(mine, I, J, K)
	local cle = I + J * PI_ + K * PI_ * PJ_
	local n = mine.paquets[cle]
	if n == nil then
		n = false
		local r = Random.new(mine.germe + cle)
		local i, j, k = I * PAQUET + r:NextInteger(1, 2), J * PAQUET + r:NextInteger(1, 2), K * PAQUET + r:NextInteger(1, 2)
		local tirage = r:NextNumber()
		if dansGrille(i, j, k) then
			for _, def in MINERAIS_COUCHE[coucheCase(i, j, k)] do
				if tirage < def.chance then n = {indice = indice(i, j, k), def = def}; break end
				tirage -= def.chance
			end
		end
		mine.paquets[cle] = n
	end
	return n
end

local function minerai(mine, i, j, k)
	local n = noeudDuPaquet(mine, (i - 1) // PAQUET, (j - 1) // PAQUET, (k - 1) // PAQUET)
	return if n and n.indice == indice(i, j, k) then n.def else nil
end

local noeuds = {} -- [cœur] = {mine, n, i, j, k} : nœuds visibles, toutes mines confondues

-- Nœud enfoui : le rocher de la mine publique (même construction), réduit ; PV / Type comme là-bas
local function creerNoeud(mine, n, def, cf, i, j, k)
	local visuel = MineraisModeles.VISUEL[def.id]
	local modele, coeur = MineraisModeles.construire(def.id, cf * CFrame.new(0, -1.25 * visuel.taille, 0), Random.new(mine.germe + n), true)
	modele:ScaleTo(ECHELLE_NOEUD)
	for _, p in modele:GetChildren() do
		if p:IsA("BasePart") then p.CanQuery = p == coeur end -- la visée ne touche que le cœur
	end
	coeur:SetAttribute("Type", def.id)
	coeur:SetAttribute("Taille", visuel.taille * ECHELLE_NOEUD)
	coeur:SetAttribute("PV", def.pv)
	coeur:SetAttribute("PVMax", def.pv)
	coeur:SetAttribute("Proprietaire", mine.proprietaire)
	coeur:SetAttribute("Palier", CouchesMine.palierMinerai(def.id)) -- PiocheBraise (dégâts) et ViseurPioche.client
	modele.Parent = mine.massif
	CollectionService:AddTag(coeur, "Minerai")
	noeuds[coeur] = {mine = mine, n = n, i = i, j = j, k = k}
	return modele
end

local function creerBloc(mine, i, j, k)
	local n = indice(i, j, k)
	if mine.blocs[n] then return end
	local cf = mine.base * CFrame.new(centreCase(i, j, k))
	local def = minerai(mine, i, j, k)
	if def then
		mine.blocs[n] = creerNoeud(mine, n, def, cf, i, j, k)
		return
	end
	-- Roche teintée selon la couche de minage (Partage › CouchesMine), nuancée par un bruit
	local couche = CouchesMine.LISTE[coucheCase(i, j, k)]
	local bruit = math.noise(i * 0.31, j * 0.27, k * 0.33) + 0.5
	local teinte = couche.couleur:Lerp(couche.couleur2, math.clamp(bruit, 0, 1))
	local bloc = O.bloc(mine.massif, Vector3.new(T, T, T), cf, teinte, couche.materiau, "BlocMine")
	bloc:SetAttribute("Colonne", i)
	bloc:SetAttribute("Ligne", j)
	bloc:SetAttribute("Couche", k)
	bloc:SetAttribute("Palier", couche.palier) -- ViseurPioche.client (affichage seulement)
	CollectionService:AddTag(bloc, "BlocMine")
	mine.blocs[n] = bloc
end

-- Nœud cassé par la pioche (PiocheBraise retire le tag à PV 0 ; la récompense passe par MineraiCasse) :
-- le rocher s'efface, la case devient creusée pour de bon, les voisines apparaissent
CollectionService:GetInstanceRemovedSignal("Minerai"):Connect(function(coeur)
	local info = noeuds[coeur]
	if not info then return end
	noeuds[coeur] = nil
	local mine = info.mine
	if not mine.modele.Parent or not coeur:GetAttribute("Casse") then return end
	local modele = mine.blocs[info.n]
	mine.blocs[info.n] = nil
	mine.creuses[info.n] = true
	if modele then
		for _, d in modele:GetDescendants() do
			if d:IsA("BasePart") and d ~= coeur then
				d.CanCollide = false
				TweenService:Create(d, TweenInfo.new(0.35), {Transparency = 1, Size = d.Size * 0.5}):Play()
			end
		end
		Debris:AddItem(modele, 1.2)
	end
	for _, v in VOISINS do
		local i, j, k = info.i + v.X, info.j + v.Y, info.k + v.Z
		if dansGrille(i, j, k) and estPleine(mine, i, j, k) then creerBloc(mine, i, j, k) end
	end
end)

local function massif(mine)
	local f = Instance.new("Folder")
	f.Name = "MurDeBlocs"
	f.Parent = mine.modele
	mine.massif = f
	mine.creuses, mine.blocs, mine.paquets = {}, {}, {}
	-- Seules les cases autour de la descente ouverte (au bout de la galerie) peuvent être exposées
	local J_PENTE = math.max(1, math.floor((-PENTE * LONGUEUR_PENTE - 6 - Y_BAS) / T))
	for k = 1, K_OUVERT + 1 do
		for j = J_PENTE, NY do -- en dessous de la descente ouverte, rien ne peut être exposé
			for i = 1, NX do
				if estPleine(mine, i, j, k) and expose(mine, i, j, k) then creerBloc(mine, i, j, k) end
			end
		end
	end
	-- Lueur douce au milieu de la descente (pas de torche dans la roche creusable)
	local lueur = O.decor(O.bloc(mine.modele, Vector3.new(0.2, 0.2, 0.2),
		mine.base * CFrame.new(0, -PENTE * LONGUEUR_PENTE / 2 + 6, Z_MUR - LONGUEUR_PENTE / 2), FLAMME, M.Lisse, "LueurPente"))
	lueur.Transparency = 1
	O.lumiere(lueur, FLAMME, 0.8, 22)
end

-- Retire les cases pleines dont le centre est dans la boîte orientée (repère local), s'il y a au moins
-- un bloc visible dedans ; fait apparaître les voisins devenus exposés. Au plus MAX_PAR_COUP cases.
-- Les cases de minerai restent (le nœud se casse à la pioche). Écart de palier (Partage › CouchesMine) : 1 = case
-- dure (retirée seulement si dur), ≥ 2 = case bloquée. Renvoie le premier bloc retiré ; trace reçoit
-- bloquee (couche la plus dure qui bloque), mur (bloc bloqué visible) et resiste (bloc dur visible).
local MAX_PAR_COUP = 40
local function retirer(mine, boite: CFrame, taille: Vector3, palier: number, dur: boolean, trace)
	local demi = taille / 2
	local r = demi.Magnitude
	local p = boite.Position
	local i0, i1 = math.max(1, math.ceil((p.X - r + LARGEUR_MASSIF / 2) / T + 0.5)), math.min(NX, math.floor((p.X + r + LARGEUR_MASSIF / 2) / T + 0.5))
	local j0, j1 = math.max(1, math.ceil((p.Y - r - Y_BAS) / T + 0.5)), math.min(NY, math.floor((p.Y + r - Y_BAS) / T + 0.5))
	local k0, k1 = math.max(1, math.ceil((Z_AVANT - p.Z - r) / T + 0.5)), math.min(NZ, math.floor((Z_AVANT - p.Z + r) / T + 0.5))
	local cases, visible = {}, false
	for k = k0, k1 do
		for j = j0, j1 do
			for i = i0, i1 do
				if #cases < MAX_PAR_COUP and estPleine(mine, i, j, k) then
					local q = boite:PointToObjectSpace(centreCase(i, j, k))
					local aPart = mine.blocs[indice(i, j, k)] ~= nil
					if math.abs(q.X) <= demi.X and math.abs(q.Y) <= demi.Y and math.abs(q.Z) <= demi.Z
						and not minerai(mine, i, j, k) then
						local c = coucheCase(i, j, k)
						local ecart = CouchesMine.LISTE[c].palier - palier
						local b = mine.blocs[indice(i, j, k)]
						if ecart >= 2 then
							if b then trace.bloquee, trace.mur = math.max(trace.bloquee or 0, c), trace.mur or b end
						elseif ecart == 1 and not dur then
							trace.resiste = trace.resiste or b
						else
							table.insert(cases, Vector3.new(i, j, k))
							visible = visible or aPart
						end
					end
				end
			end
		end
	end
	if not visible then return nil end
	local premier = nil
	for _, c in cases do
		local n = indice(c.X, c.Y, c.Z)
		mine.creuses[n] = true
		local bloc = mine.blocs[n]
		mine.blocs[n] = nil
		if bloc then
			if premier then bloc:Destroy() else premier = bloc; bloc.Parent = nil end
		end
	end
	for _, c in cases do
		for _, v in VOISINS do
			local i, j, k = c.X + v.X, c.Y + v.Y, c.Z + v.Z
			if dansGrille(i, j, k) and estPleine(mine, i, j, k) then creerBloc(mine, i, j, k) end
		end
	end
	return premier
end

-- « Pioche trop faible » : le client (CoucheMine.client) affiche la pioche requise pour cette couche
local avisMine = Instance.new("RemoteEvent")
avisMine.Name = "AvisMine"
avisMine.Parent = game:GetService("ReplicatedStorage")
local derniersAvis = {}
-- genre « pioche » (couche) / « minerai » (id) : un avis toutes les 1,5 s au plus ; « dur » (0..1) : à chaque coup
function MinePrivee.avertir(joueur, genre: string, valeur: any)
	if genre ~= "dur" then
		local t = os.clock()
		if t - (derniersAvis[joueur] or 0) < 1.5 then return end
		derniersAvis[joueur] = t
	end
	avisMine:FireClient(joueur, genre, valeur)
end
game:GetService("Players").PlayerRemoving:Connect(function(joueur) derniersAvis[joueur] = nil end)

-- Coup de pioche du joueur dans SA mine (serveur autoritaire). Zone ≈ taille du joueur
-- (ZONE_COUP : largeur × hauteur × profondeur), orientée selon son regard ; essaie devant,
-- puis devant-bas (boîte inclinée en descente), puis sous ses pieds.
-- Renvoie le premier bloc retiré (sorti du jeu : l'appelant le détruit après les éclats), ou nil puis le bloc qui
-- résiste et true s'il est hors de portée de la pioche (écart de palier ≥ 2). Roche dure (écart 1) : elle cède
-- au bout de CouchesMine.COUPS_DUR coups qui n'ont rien retiré d'autre.
function MinePrivee.creuser(joueur, racine: BasePart, vise: Vector3?, origine: Vector3?)
	local mine = mines[joueur]
	if not mine or not mine.modele.Parent then return nil end
	local l = mine.base:PointToObjectSpace(racine.Position)
	if math.abs(l.X) > LARGEUR_MASSIF / 2 + 4 or l.Y < Y_BAS - 6 or l.Y > Y_HAUT + 6 or l.Z > Z_AVANT + 6 or l.Z < Z_FOND - 6 then return nil end
	local regard = mine.base:VectorToObjectSpace(racine.CFrame.LookVector) * Vector3.new(1, 0, 1)
	regard = if regard.Magnitude > 1e-3 then regard.Unit else Vector3.new(0, 0, -1)
	local Z = MinePrivee.ZONE_COUP
	local palier = CouchesMine.palierPioche(joueur:GetAttribute("Pioche"))
	local boites = {}
	-- Viseur (distance déjà validée) : le serveur refait le rayon tête → point dans SA mine ; on ne garde
	-- que le premier bloc réellement touché (impossible de creuser à travers la roche)
	if vise and origine then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {mine.modele}
		local trajet = vise - origine
		local hit = if trajet.Magnitude > 0.1 then workspace:Raycast(origine, trajet.Unit * (trajet.Magnitude + 0.6), params) else nil
		local touche = hit and hit.Instance
		local dansMassif = touche and (touche.Parent == mine.massif or (touche.Parent and touche.Parent.Parent == mine.massif))
		vise = if dansMassif then hit.Position else nil
	end
	if vise and origine then
		local a, b = mine.base:PointToObjectSpace(origine), mine.base:PointToObjectSpace(vise)
		local dir = b - a
		if dir.Magnitude > 0.1 then
			dir = dir.Unit
			local haut = if math.abs(dir.Y) > 0.95 then regard else Vector3.yAxis
			local centre = b + dir * (Z.Z / 2 - 0.5) -- la zone mord dans la roche derrière le point visé
			table.insert(boites, {CFrame.lookAt(centre, centre + dir, haut), Z})
		end
	end
	local face = CFrame.lookAt(l, l + regard) -- -Z = regard, Y = haut
	table.insert(boites, {face * CFrame.new(0, -0.3, -(Z.Z / 2 + 0.6)), Z})
	table.insert(boites, {face * CFrame.new(0, -2.6, -(Z.Z / 2 + 0.4)) * CFrame.Angles(math.rad(-35), 0, 0), Z})
	table.insert(boites, {face * CFrame.new(0, -3 - Z.Z / 2, 0), Vector3.new(Z.X, Z.Z, Z.X)})
	local trace = {}
	local function passe(dur: boolean)
		for _, boite in boites do
			local bloc = retirer(mine, boite[1], boite[2], palier, dur, trace)
			if bloc then return bloc end
		end
		return nil
	end
	local bloc = passe(false)
	if not bloc and trace.resiste then
		mine.effort = (mine.effort or 0) + 1
		if mine.effort < CouchesMine.COUPS_DUR then
			MinePrivee.avertir(joueur, "dur", mine.effort / CouchesMine.COUPS_DUR)
			return nil, trace.resiste, false
		end
		bloc = passe(true)
	end
	if bloc then
		if (mine.effort or 0) > 0 then MinePrivee.avertir(joueur, "dur", 1) end
		mine.effort = 0
		return bloc
	end
	if trace.bloquee then
		MinePrivee.avertir(joueur, "pioche", trace.bloquee)
		return nil, trace.mur, true
	end
	return nil
end

local function construire(joueur, index)
	if not dossier or not dossier.Parent then
		dossier = Instance.new("Folder")
		dossier.Name = "MinesPrivees"
		dossier.Parent = workspace
	end
	local base = CFrame.new(emplacement(index))
	local rng = Random.new(joueur.UserId % 100000 + index)
	local m = Instance.new("Model")
	m.Name = "MinePrivee_" .. joueur.UserId
	m:SetAttribute("Proprietaire", joueur.UserId)
	m:SetAttribute("Emplacement", index)
	m:SetAttribute("Base", base) -- repère local (CoucheMine.client : profondeur et couche)
	O.atomique(m) -- arrive en entier chez le joueur : pas de sol manquant à l'arrivée
	coque(m, base)
	moellons(m, base, rng)
	etais(m, base)
	rail(m, base, rng)
	details(m, base, joueur)
	-- Graine des NŒUDS (la roche ne dépend pas d'elle) : change à chaque visite, sinon on refarme les mêmes nœuds
	visites += 1
	local visite = (os.time() + visites) % 1000
	local mine = {modele = m, base = base, germe = ((joueur.UserId % 1000003) + visite * 1000003) * 131072, proprietaire = joueur.UserId}
	massif(mine)
	local retour = Cercle.construire(m, base * CFrame.new(0, 0, Z_RETOUR), "CercleRetour", {texte = "Sortie"})
	m.Parent = dossier
	mine.apparition = base * CFrame.new(0, 0, Z_APPARITION) -- au sol, regard vers le massif (-Z)
	mine.retour = retour
	mine.centreRetour = retour:GetAttribute("Centre")
	return mine
end

-- Renvoie la mine du joueur (construite au premier appel, réutilisée ensuite)
function MinePrivee.obtenir(joueur)
	local mine = mines[joueur]
	if mine and mine.modele.Parent then return mine end
	if mine then occupes[mine.index] = nil end
	local index = 1
	while occupes[index] do index += 1 end
	occupes[index] = true
	local ok, resultat = pcall(construire, joueur, index)
	if not ok then
		occupes[index] = nil
		error(resultat, 0)
	end
	mine = resultat
	mine.index = index
	mines[joueur] = mine
	return mine
end

function MinePrivee.trouver(joueur)
	return mines[joueur]
end

-- Départ du joueur : la mine est détruite et l'emplacement libéré
function MinePrivee.liberer(joueur)
	derniersAvis[joueur] = nil
	local mine = mines[joueur]
	if not mine then return end
	mines[joueur] = nil
	occupes[mine.index] = nil
	mine.modele:Destroy()
end

return MinePrivee
