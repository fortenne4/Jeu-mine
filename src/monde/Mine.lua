-- La Grande Mine : gare du village, voie ferrée, portail dans la falaise, tunnel étayé,
-- descente vers la grande caverne de cristal et les portes des tunnels privés.
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local Cercle = require(script.Parent.CercleLumineux)
local M3 = require(script.Parent.Modeles3D)
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
end

-- Wagon du retour posé au terminus, tourné vers la gare ; remplace l'ancien levier sur les cartes figées.
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
	O.bloc(m, Vector3.new(21, 0.7, 49), CFrame.new(x0, 13.95, zc), C.Toit, M.Tuiles, "Toit")
	local enseigne = O.bloc(m, Vector3.new(17, 3, 0.5), CFrame.new(x0, 15.8, -100.2), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(enseigne, Enum.NormalId.Back, "GARE DE LA GRANDE MINE")

	for _, z in {-112, -134} do
		B.banc(m, CFrame.new(-18, 2.2, z) * CFrame.Angles(0, -math.pi / 2, 0))
	end
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
	O.decor(O.cylindre(m, 1.4, 1.8, CFrame.new(30, 7.4, -143), C.Bois, M.Planches, "Seau"))

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

-- Inscription « LA GRANDE MINE » en pierres taillées lumineuses, incrustée dans la falaise au-dessus du portail
-- (remplace l'ancien grand panneau en bois). Modèle : blender/inscription.py → assets/Inscription.fbx.
-- Texte de 170 studs de large (capitales d'environ 13) : la même taille que le texte de l'ancien panneau, lisible depuis la place.
-- Sans le modèle 3D : lettres gravées en lumière dans des blocs de pierre (aucun panneau non plus).
local INSCRIPTION_BASE_Y = D.PORTAIL_HAUTEUR + 33 -- au-dessus du couronnement rocheux de la façade
local INSCRIPTION_LARGEUR = 170
local INSCRIPTION_HAUTEUR = 13
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
	if existante and existante:GetAttribute("Version") == 6 then return end
	if existante then existante:Destroy() end
	local ancienne = portail:FindFirstChild("Enseigne")
	if ancienne and ancienne:IsA("BasePart") then ancienne:Destroy() end
	local cadre = O.modele(portail, "EnseigneGrandeMine")
	cadre:SetAttribute("Version", 6)

	-- les lettres sont posées juste devant la roche la plus avancée ; derrière, une assise de roche sombre comble
	-- les creux de la paroi (incrustées, jamais en l'air), et devant, le terrain est dégagé (rien ne les recouvre)
	local z = surfaceFalaise() + 1.5
	local y = INSCRIPTION_BASE_Y
	local centreY = y + INSCRIPTION_HAUTEUR / 2
	terrain:FillBlock(CFrame.new(0, centreY, z - 8), Vector3.new(INSCRIPTION_LARGEUR + 8, INSCRIPTION_HAUTEUR + 6, 12), Enum.Material.Slate)
	terrain:FillBlock(CFrame.new(0, centreY, z + 3), Vector3.new(INSCRIPTION_LARGEUR + 8, INSCRIPTION_HAUTEUR + 4, 8), Enum.Material.Air)

	local pieces = M3.pieces("Inscription")
	if pieces then
		local mn, mx = M3.boite(pieces)
		local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
		local k = INSCRIPTION_LARGEUR / (mx.X - mn.X) -- par la largeur : le texte entier tient au-dessus du portail
		local TEINTES = {
			Pierre = {Color3.fromRGB(168, 156, 140), M.Calcaire},
			Lueur = {Color3.fromRGB(255, 190, 96), M.Neon},
			Gorge = {Color3.fromRGB(30, 24, 26), M.Ardoise},
		}
		-- la face du modèle (-Z) regarde le village (+Z du monde) : demi-tour
		M3.poser(pieces, S, CFrame.new(0, y, z) * CFrame.Angles(0, math.pi, 0), k, cadre, function(c, teinte)
			local t = TEINTES[teinte]
			if t then
				c.Color, c.Material = t[1], t[2]
			end
			O.decor(c)
			c.CastShadow = teinte ~= "Lueur"
		end)
	else
		-- secours : une pierre taillée par lettre, la lettre gravée en lumière sur sa face
		local texte = "LA GRANDE MINE"
		local n = #texte
		local pas = INSCRIPTION_LARGEUR / n
		for i = 1, n do
			local lettre = texte:sub(i, i)
			if lettre ~= " " then
				local x = -INSCRIPTION_LARGEUR / 2 + (i - 0.5) * pas
				local bloc = O.decor(O.bloc(cadre, Vector3.new(pas * 0.92, INSCRIPTION_HAUTEUR, 1.6), CFrame.new(x, y + INSCRIPTION_HAUTEUR / 2, z + 0.4),
					Color3.fromRGB(150, 140, 128), M.Calcaire, "PierreLettre"))
				local g = O.texte(bloc, Enum.NormalId.Back, lettre, {ppp = 12, police = Enum.Font.Fondamento, couleur = Color3.fromRGB(255, 196, 96), lumiere = 0})
				local label = g:FindFirstChild("Label")
				if label and label:IsA("TextLabel") then
					label.Size, label.Position = UDim2.fromScale(0.96, 0.96), UDim2.fromScale(0.02, 0.02)
				end
			end
		end
	end
	-- lueur chaude qui baigne l'inscription
	for _, x in {-50, 0, 50} do
		local p = O.decor(O.bloc(cadre, Vector3.one, CFrame.new(x, y + INSCRIPTION_HAUTEUR / 2, z + 6), Color3.new(), M.Lisse, "Halo"))
		p.Transparency = 1
		O.lumiere(p, Color3.fromRGB(255, 180, 96), 1.4, 30)
	end
end

local preparerPortes, preparerCristal -- définies avec la caverne, plus bas

-- Actualise la voie des cartes déjà enregistrées sans reconstruire la mine.
function Mine.preparerVoie(mine)
	preparerEnseigne(mine)
	local gareExistante = mine:FindFirstChild("Gare")
	if gareExistante then nettoyerGare(gareExistante) end
	local caverneExistante = mine:FindFirstChild("Caverne")
	if caverneExistante then
		preparerWagonRetour(caverneExistante)
		preparerCristal(caverneExistante)
	end
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
	for _, c in {{-48, 36, 24, C.Cristal}, {-30, 58, 20, C.CristalViolet}, {42, 30, 26, C.CristalViolet}, {26, 62, 18, C.Cristal}, {62, 18, 16, C.Cristal}} do
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
local VERSION_PORTES = 3
local ROCHE_PAROI = Color3.fromRGB(112, 104, 98) -- couleur du matériau Rock du terrain
local EMBRASURE = Color3.fromRGB(28, 25, 24)
local function portes(f)
	local m = O.modele(f, "PortesTunnels")
	for i, pos in D.PORTES do
		local base = vers(pos, D.CAVERNE_CENTRE) -- -Z vers le centre ; la paroi est derrière (+Z)
		local cf = base * CFrame.new(0, 0, D.PORTES_ENFONCEMENT) -- plan du cadre, contre la paroi
		terrain:FillBlock(cf * CFrame.new(0, 13, 10), Vector3.new(24, 34, 16), Enum.Material.Rock)
		terrain:FillBlock(cf * CFrame.new(0, 12.5, -2), Vector3.new(24, 24, 6), Enum.Material.Air)
		terrain:FillBlock(cf * CFrame.new(0, 9, 6), Vector3.new(14, 18, 10), Enum.Material.Air)
		local g = O.modele(m, "Porte" .. i)
		-- Façade de roche (Parts) autour de l'ouverture : face avant à z = +1
		for _, s in {-1, 1} do
			O.bloc(g, Vector3.new(7, 22, 2), cf * CFrame.new(s * 8.2, 11, 2), ROCHE_PAROI, M.Roche, "Facade")
		end
		O.bloc(g, Vector3.new(9.4, 8, 2), cf * CFrame.new(0, 18, 2), ROCHE_PAROI, M.Roche, "Facade")
		-- Embrasure : galerie sombre jusqu'au fond noir
		for _, s in {-1, 1} do
			O.bloc(g, Vector3.new(1, 14, 9), cf * CFrame.new(s * 5.2, 7, 5.5), EMBRASURE, M.Ardoise, "Embrasure")
		end
		O.bloc(g, Vector3.new(11.4, 1, 9), cf * CFrame.new(0, 14.5, 5.5), EMBRASURE, M.Ardoise, "Embrasure")
		O.bloc(g, Vector3.new(9.4, 0.3, 9), cf * CFrame.new(0, 0.15, 5.5), EMBRASURE, M.Ardoise, "Embrasure")
		O.decor(O.bloc(g, Vector3.new(11, 15, 0.4), cf * CFrame.new(0, 7.3, 9.8), Color3.fromRGB(6, 6, 8), M.Lisse, "Obscurite"))
		-- Cadre de bois et lanternes collés à la façade
		for _, x in {-5.6, 5.6} do
			O.bloc(g, Vector3.new(1.8, 14, 1.8), cf * CFrame.new(x, 7, 0), C.BoisFonce, M.Bois, "Poteau")
			B.applique(g, cf * CFrame.new(x * 1.4, 9, 1))
		end
		O.bloc(g, Vector3.new(13.4, 2, 2), cf * CFrame.new(0, 15, 0), C.BoisFonce, M.Bois, "Linteau")
		O.decor(O.bloc(g, Vector3.new(9, 0.35, 0.2), cf * CFrame.new(0, 15, -1.05), C.Cristal, M.Neon, "Runes"))
		local panneau = O.bloc(g, Vector3.new(8, 2.6, 0.4), cf * CFrame.new(0, 17.7, 0.6), C.BoisFonce, M.Planches, "Panneau")
		O.texte(panneau, Enum.NormalId.Front, "Tunnel " .. (ROMAINS[i] or tostring(i)), {lumiere = 0})
		-- Parvis en planches entre le cercle et le cadre
		for k = 0, 3 do
			local teinte = if k % 2 == 0 then C.Bois else C.BoisFonce:Lerp(C.Bois, 0.5)
			O.bloc(g, Vector3.new(9.4, 0.25, 1), cf * CFrame.new(0, 0.125, -1.1 - k * 1.05), teinte, M.Planches, "Planche")
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
	for _, z in {-378, -402} do
		B.lanterne(m, vers(Vector3.new(-18, y + 2, z), Vector3.new(0, y + 2, z)), 9)
	end
	for _, x in {-17, -7} do
		O.bloc(m, Vector3.new(0.8, 9, 0.8), CFrame.new(x, y + 6.5, -376.5), C.BoisFonce, M.Bois, "Poteau")
	end
	local enseigne = O.bloc(m, Vector3.new(11, 2.6, 0.4), CFrame.new(-12, y + 10, -376.5), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(enseigne, Enum.NormalId.Back, "QUAI DES PROFONDEURS")
	preparerWagonRetour(m)

	-- Grand amas de cristaux violets (lobe ouest, loin des portes)
	m:SetAttribute("VersionCristal", 2)
	local amas = CFrame.new(D.CRISTAL_CAVERNE + Vector3.new(0, -0.5, 0))
	B.rocher(m, D.CRISTAL_CAVERNE + Vector3.new(0, -1.5, 0), 7, rng)
	local _, coeur = B.cristal(m, amas, 26, C.CristalViolet, rng, 60)
	local lumiere = coeur:FindFirstChildOfClass("PointLight")
	if lumiere then
		lumiere.Shadows = true
		lumiere.Brightness = 3
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

	-- Braseros et wagonnet abandonné
	B.brasero(m, CFrame.new(24, y, -396))
	B.brasero(m, CFrame.new(-44, y, -404))
	B.wagonnet(m, CFrame.new(16, y, -410) * CFrame.Angles(0, 0.5, 0), Color3.fromRGB(255, 196, 48), rng)

	-- Panneau des tunnels privés
	local cfP = vers(Vector3.new(0, y, -470), Vector3.new(0, y, -400))
	for _, x in {-5.5, 5.5} do
		O.bloc(m, Vector3.new(0.8, 9.5, 0.8), cfP * CFrame.new(x, 4.75, 0), C.BoisFonce, M.Bois, "Poteau")
	end
	B.fronton(m, cfP * CFrame.new(0, 8, 0), "TUNNELS PRIVÉS", 12)

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
	pointsMinerai(f)
end

return Mine
