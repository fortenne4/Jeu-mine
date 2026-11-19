-- La Grande Mine : gare du village, voie ferrée, portail dans la falaise, tunnel étayé,
-- descente vers la grande caverne de cristal et les portes des tunnels privés.
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
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
	O.bloc(m, Vector3.new(9, 0.2, L), base * CFrame.new(0, 0.1, -L / 2), Color3.fromRGB(88, 82, 76), M.Gravier, "Ballast")
	for _, x in {-2.5, 2.5} do
		local rail = O.decor(O.bloc(m, Vector3.new(0.35, 0.45, L), base * CFrame.new(x, 0.75, -L / 2), C.Rail, M.Metal, "Rail"))
		rail.Reflectance = 0.15
	end
	local n = math.floor(L / 3)
	for i = 0, n do
		O.decor(O.bloc(m, Vector3.new(7.4, 0.5, 1.1), base * CFrame.new(0, 0.25, -i * L / n), C.BoisFonce, M.Bois, "Traverse"))
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

	-- Guichet des départs (côté est de la voie)
	local g = vers(Vector3.new(14, 0, -114), Vector3.new(0, 0, -114))
	O.bloc(m, Vector3.new(7, 1, 6), g * CFrame.new(0, 0.5, 0), C.PierreFoncee, M.Pierre, "Socle")
	O.bloc(m, Vector3.new(6, 7, 5), g * CFrame.new(0, 4.5, 0.3), C.Bois, M.Planches, "Cabane")
	local guichet = O.bloc(m, Vector3.new(3.4, 2.2, 0.3), g * CFrame.new(0, 5, -2.25), C.Fenetre, M.Neon, "Guichet")
	guichet.Transparency = 0.3
	O.coin(m, Vector3.new(7.4, 2.4, 3.2), g * CFrame.new(0, 9.2, -1.3), C.Toit, M.Tuiles, "Toit")
	O.coin(m, Vector3.new(7.4, 2.4, 3.2), g * CFrame.new(0, 9.2, 1.9) * CFrame.Angles(0, math.pi, 0), C.Toit, M.Tuiles, "Toit")
	B.fronton(m, g * CFrame.new(0, 7.2, -2.2), "DÉPARTS", 5)

	-- Butoir et wagonnets qui attendent
	B.butoir(m, CFrame.new(0, 0, -100.5))
	B.wagonnet(m, CFrame.new(0, 0, -108), Color3.fromRGB(34, 34, 38), rng)
	B.wagonnet(m, CFrame.new(0, 0, -116.5), Color3.fromRGB(184, 100, 46), rng)
	B.wagonnet(m, CFrame.new(0, 0, -125))

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

local function voie(f)
	local m = O.modele(f, "Voie")
	troncon(m, D.RAIL_DEBUT, D.TUNNEL_FIN)
	troncon(m, D.TUNNEL_FIN, D.DESCENTE_FIN)
	troncon(m, D.DESCENTE_FIN, D.QUAI_BAS)
	local A, Bp = D.TUNNEL_FIN, D.DESCENTE_FIN
	local L = (Bp - A).Magnitude
	O.bloc(m, Vector3.new(26, 4, L), CFrame.lookAt(A, Bp) * CFrame.new(0, -2, -L / 2), C.Roche, M.Ardoise, "SolDescente")
	B.butoir(m, CFrame.new(D.QUAI_BAS + Vector3.new(0, 0, -0.5)) * CFrame.Angles(0, math.pi, 0))
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
	local enseigne = O.bloc(m, Vector3.new(30, 5, 0.6), CFrame.new(0, H + 9, z + 4.3), C.BoisFonce, M.Planches, "Enseigne")
	O.texte(enseigne, Enum.NormalId.Back, "LA GRANDE MINE", {ppp = 24})

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

local function portes(f)
	local m = O.modele(f, "PortesTunnels")
	for i, pos in D.PORTES do
		local cf = vers(pos, D.CAVERNE_CENTRE) -- -Z vers le centre ; l'alcôve est derrière (+Z)
		terrain:FillBlock(cf * CFrame.new(0, 8, 11), Vector3.new(12, 16, 22), Enum.Material.Air)
		local g = O.modele(m, "Porte" .. i)
		for _, x in {-5.6, 5.6} do
			O.bloc(g, Vector3.new(1.8, 14, 1.8), cf * CFrame.new(x, 7, 0), C.BoisFonce, M.Bois, "Poteau")
			B.applique(g, cf * CFrame.new(x, 9, -0.9))
		end
		O.bloc(g, Vector3.new(13.4, 2, 2), cf * CFrame.new(0, 15, 0), C.BoisFonce, M.Bois, "Linteau")
		O.decor(O.bloc(g, Vector3.new(9, 0.35, 0.2), cf * CFrame.new(0, 15, -1.05), C.Cristal, M.Neon, "Runes"))
		local panneau = O.bloc(g, Vector3.new(6, 2.4, 0.4), cf * CFrame.new(0, 17.6, 0), C.Bois, M.Planches, "Panneau")
		O.texte(panneau, Enum.NormalId.Front, "Tunnel " .. (ROMAINS[i] or tostring(i)))
		O.decor(O.bloc(g, Vector3.new(11, 14, 0.4), cf * CFrame.new(0, 7, 14), Color3.fromRGB(6, 6, 8), M.Lisse, "Obscurite"))
		-- Zone d'entrée : servira à envoyer le joueur dans SON tunnel privé
		local entree = O.decor(O.bloc(g, Vector3.new(10, 13, 2), cf * CFrame.new(0, 6.5, 3), Color3.new(1, 1, 1), M.Lisse, "Entree"))
		entree.Transparency = 1
		entree.CanTouch = true
		entree:SetAttribute("Numero", i)
		O.tag(entree, "PorteTunnel")
		O.brume(entree, Color3.fromRGB(120, 130, 170), 2)
	end
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

	-- Grand amas de cristaux violets
	local amas = CFrame.new(-30, y - 0.5, -445)
	B.rocher(m, Vector3.new(-30, y - 1.5, -445), 7, rng)
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
	portail(f, rng)
	soutenements(f)
	portes(f)
	caverne(f, rng)
	pointsMinerai(f)
end

return Mine
