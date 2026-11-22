--[[ Grotte −50 m « Le Lac des Lueurs » (palier 1) : habillage complet appelé par GrotteGenerateur.
	Direction artistique : Coffre Jeu mine / 01 - Game Design / Grotte 50 m - Le Lac des Lueurs.md

	Une grotte noyée et bioluminescente :
	- camp des mineurs à l'arrivée (le seul endroit chaud : tente, brasero, table et carte, caisses)
	- lacs turquoise dans des cuvettes creusées au sol (algues et tapis lumineux au fond, nénuphars, poissons,
	  brume) ; le plus grand reçoit une cascade qui tombe du plafond
	- forêt de champignons géants à lamelles lumineuses et spores qui montent
	- voûte de vers luisants (ciel étoilé sous la roche) et fils de soie perlés, rideaux de mousse
	- rais de lumière qui tombent de fissures du plafond
	- géodes cyan / améthyste, lanternes à vers luisants le long du chemin
	- ruines naines englouties : dallages, colonnes brisées, arche runique devant la salle du boss,
	  deux statues géantes de nains qui gardent l'entrée, temple du boss (géode géante, braseros, runes)
	- méduses de spores qui flottent (animées par VieGrotte.client.lua via les tags)
	- zones d'ambiance (« GrotteZone ») lues par AmbianceGrotte.client.lua
	Le reste (stalactites, colonnes, racines, restes de mine) vient de GrotteDecor avec une palette froide.
	Tout est décoratif (aucune collision) ; rien dans la zone d'arrivée, sur les gisements ni sur le chemin. ]]
local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local B = require(script.Parent.Batiments)
local GD = require(script.Parent.GrotteDecor)
local M = O.M

local GrotteLueurs = {}

local terrain = workspace.Terrain
local AIR, EAU = Enum.Material.Air, Enum.Material.Water
local MAX_LUMIERES = 48
local MAX_REMPLISSAGE = 70 -- lumières douces sans ombre (voûtes, galeries) : le gros de la lisibilité

local TEX_LUEUR = "rbxasset://textures/particles/forcefield_glow_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local SON_CASCADE = "rbxassetid://9120550180" -- rbxassetid de la boucle d'eau (vide = pas de son)

local P = {
	cyan = Color3.fromRGB(80, 230, 255),
	turquoise = Color3.fromRGB(70, 255, 210),
	violet = Color3.fromRGB(165, 90, 255),
	magenta = Color3.fromRGB(255, 95, 215),
	ambre = Color3.fromRGB(255, 168, 80),
	lune = Color3.fromRGB(195, 228, 255),
	roche = Color3.fromRGB(56, 60, 74),
	pierre = Color3.fromRGB(78, 84, 102),
	mousse = Color3.fromRGB(32, 70, 64),
}

local COUL = {
	-- GrotteLueurs.fbx
	Pied = {Color3.fromRGB(150, 140, 172), M.Lisse},
	Chapeau = {Color3.fromRGB(74, 40, 124), M.Lisse},
	Lamelles = {P.magenta, M.Neon},
	Points = {P.turquoise, M.Neon},
	Fil = {Color3.fromRGB(200, 240, 255), M.Verre, 0.55},
	Perle = {P.cyan, M.Neon},
	Mousse = {P.mousse, M.Tissu},
	Bout = {P.turquoise, M.Neon},
	Cristal = {P.cyan, M.Neon},
	Cristal2 = {P.violet, M.Neon},
	Socle = {P.roche, Enum.Material.Slate},
	Pierre = {P.pierre, Enum.Material.Slate},
	Rune = {P.cyan, M.Neon},
	Feuille = {Color3.fromRGB(26, 104, 86), M.Lisse},
	Fleur = {Color3.fromRGB(225, 160, 255), M.Neon},
	Cloche = {Color3.fromRGB(150, 225, 255), M.Verre, 0.45},
	Coeur = {P.magenta, M.Neon},
	Tentacule = {P.cyan, M.Neon, 0.3},
	Corps = {P.cyan, M.Neon},
	Nageoire = {P.violet, M.Neon},
	Tige = {Color3.fromRGB(22, 84, 72), M.Lisse},
	Lueur = {P.turquoise, M.Neon},
	Bois = {Color3.fromRGB(88, 62, 42), M.Bois},
	Fer = {Color3.fromRGB(58, 58, 66), M.Metal},
	Verre = {Color3.fromRGB(150, 255, 230), M.Neon, 0.55},
	Toile = {Color3.fromRGB(168, 144, 108), M.Tissu},
	Papier = {Color3.fromRGB(226, 206, 160), M.Lisse},
}
-- Palette appliquée au décor générique (GrotteDecor.fbx)
local COUL_GENERIQUE = {
	Roche = {Color3.fromRGB(64, 68, 84), Enum.Material.Slate},
	Goutte = {Color3.fromRGB(170, 235, 255), M.Verre, 0.3},
	Chapeau = {Color3.fromRGB(90, 52, 150), M.Lisse},
	Pied = {Color3.fromRGB(150, 140, 172), M.Lisse},
	Lueur = {P.turquoise, M.Neon},
}
local PULSE = {Lamelles = true, Points = true, Perle = true, Cristal = true, Cristal2 = true, Rune = true, Fleur = true, Lueur = true}

-- ================= Outils =================

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
params.IgnoreWater = true

local function trace(o: Vector3, d: Vector3)
	return workspace:Raycast(o, d, params)
end

local function solEn(p: Vector3, haut: number?)
	local h = haut or 6
	local hit = trace(p + Vector3.new(0, h, 0), Vector3.new(0, -(h + 18), 0))
	if hit and hit.Normal.Y > 0.55 then
		return hit
	end
	return nil
end

local function plafondEn(p: Vector3, max: number?)
	local hit = trace(p + Vector3.new(0, 1, 0), Vector3.new(0, max or 90, 0))
	if hit and hit.Normal.Y < -0.15 then
		return hit
	end
	return nil
end

local function plat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function unite(v: Vector3, defaut: Vector3): Vector3
	return if v.Magnitude > 1e-3 then v.Unit else defaut
end

local function kp(t, v, e)
	return NumberSequenceKeypoint.new(t, v, e or 0)
end

local function volume(parent, taille: Vector3, cf: CFrame, nom: string): BasePart
	local p = O.decor(O.bloc(parent, taille, cf, Color3.new(), M.Lisse, nom))
	p.Transparency = 1
	p.CastShadow = false
	return p
end

local function emetteur(parent, props)
	local e: any = Instance.new("ParticleEmitter")
	for cle, valeur in props do
		e[cle] = valeur
	end
	e.Parent = parent
	return e
end

-- Pose une variante (motif "^ChampiGeant%d+$") ; renvoie le modèle et sa hauteur
local function poser(ctx, motif, cf, k, yBase, couleurs)
	local m, h = GD.poser(ctx.decor, motif, cf, k, ctx.rng, couleurs or COUL, yBase or "bas")
	if m then
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") and PULSE[M3.teinte(p)] then
				O.tag(p, "GrottePulse")
			end
		end
	end
	return m, h
end

local function piece(m: Instance?, teinte: string): BasePart?
	if not m then
		return nil
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and M3.teinte(p) == teinte then
			return p
		end
	end
	return nil
end

-- ================= Habillage =================

function GrotteLueurs.decorer(ctx, infos, outils)
	local rng = ctx.rng
	local decor = ctx.decor
	local depart, boss = infos.depart, infos.boss
	local chemin, salles, galeries = infos.chemin, infos.lieux, infos.galeries
	local rb = boss.r or 30
	local modeles = #M3.variantes("^ChampiGeant%d+$") > 0

	local function lumiere(part: Instance, couleur: Color3, lum: number, portee: number, genre: string?): Light?
		if ctx.lumieres >= MAX_LUMIERES then
			return nil
		end
		ctx.lumieres += 1
		local l: any = Instance.new(genre or "PointLight")
		l.Color, l.Brightness, l.Range = couleur, lum, math.min(portee, 60)
		l.Parent = part
		return l
	end

	-- zones interdites au décor posé au sol : gisements (+ lacs, camp, champignons au fur et à mesure)
	local interdits = {}
	for _, g in infos.gisements or {} do
		table.insert(interdits, {centre = g.centre, rayon = (g.rayon or 8) * 0.7})
	end
	table.insert(interdits, {centre = depart.p, rayon = 20})
	local function libre(p: Vector3, marge: number): boolean
		for _, z in interdits do
			if math.abs(p.Y - z.centre.Y) < 14 and plat(p - z.centre).Magnitude < z.rayon + marge then
				return false
			end
		end
		return true
	end

	local zones = {}
	local function zone(centre: Vector3, rayon: number, teinte: Color3, nom: string)
		local z = volume(decor, Vector3.one, CFrame.new(centre), "Zone" .. nom)
		z:SetAttribute("Teinte", teinte)
		z:SetAttribute("Rayon", rayon)
		O.tag(z, "GrotteZone")
		table.insert(zones, z)
	end

	-- entrées de galerie d'une salle (pour garder les passages dégagés)
	local function entrees(s): {Vector3}
		local res = {}
		for _, pt in chemin do
			local d = plat(pt.p - s.p).Magnitude
			if d > s.r * 0.7 and d < s.r * 1.5 and math.abs(pt.p.Y - s.p.Y) < 12 then
				table.insert(res, pt.p)
			end
		end
		return res
	end
	-- point de la salle à distance d du centre, le plus loin possible des entrées
	local function coin(s, d: number): (Vector3, Vector3)
		local es = entrees(s)
		local meilleur, score, dir = s.p, -1, Vector3.new(1, 0, 0)
		local a0 = rng:NextNumber(0, math.pi * 2)
		for k = 0, 11 do
			local a = a0 + k * math.pi / 6
			local u = Vector3.new(math.cos(a), 0, math.sin(a))
			local c = s.p + u * d
			local m = math.huge
			for _, e in es do
				m = math.min(m, plat(c - e).Magnitude)
			end
			if m > score then
				meilleur, score, dir = c, m, u
			end
		end
		return meilleur, dir
	end
	local function versCentre(s, p: Vector3): Vector3
		return unite(plat(s.p - p), Vector3.new(0, 0, -1))
	end

	-- ===== Répartition des salles =====
	local candidates = {}
	for _, s in salles do
		if not s.depart and not s.boss and s.r >= 17 then
			table.insert(candidates, s)
		end
	end
	table.sort(candidates, function(a, b)
		return (if a.haute then 100 else 0) + a.r > (if b.haute then 100 else 0) + b.r
	end)
	local grandLac = candidates[1]
	local foret = candidates[2]
	local autresLacs = {candidates[3], if #candidates >= 6 then candidates[4] else nil}
	local roles = {}
	if foret then roles[foret] = "foret" end


	-- ===== 1. Camp des mineurs à l'arrivée =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		-- côté opposé au panneau d'entrée (posé en (-10, 0, 3) par le générateur)
		local cote = if (Vector3.new(-10, 0, 3)):Dot(droite) > 0 then -1 else 1
		local function place(lat: number, av: number): Vector3?
			local cible = depart.p + droite * cote * lat + avant * av
			local d = cible - depart.p
			local mur = trace(depart.p + Vector3.new(0, 3, 0), d)
			if mur and mur.Distance < d.Magnitude + 3 then
				cible = depart.p + d.Unit * math.max(0, mur.Distance - 4)
			end
			local s = solEn(cible)
			return s and s.Position
		end
		local camp = O.modele(decor, "CampMineurs")
		local pTente = place(15, -3)
		if pTente and modeles then
			poser(ctx, "^Tente$", CFrame.lookAt(pTente, pTente + plat(depart.p - pTente)), 1.25)
		end
		local pBrasero = place(9, -7)
		if pBrasero then
			local br = B.brasero(camp, CFrame.new(pBrasero - Vector3.new(0, 0.4, 0)), 0.7)
			if br then
				O.decorModele(br)
			end
		end
		local pTable = place(10, 4)
		if pTable and modeles then
			local m = poser(ctx, "^TableCarte$", CFrame.lookAt(pTable, pTable + plat(depart.p - pTable)) * CFrame.Angles(0, 0.3, 0), 1)
			local bougie = piece(m, "Papier")
			if bougie then
				local f = Instance.new("PointLight")
				f.Color, f.Brightness, f.Range = P.ambre, 0.8, 10
				f.Parent = bougie
			end
		end
		for k = 1, 4 do
			local p = place(16 + rng:NextNumber(-1, 2), 3 + k * 2.6)
			if p then
				local c = if k == 4 then B.tonneau(camp, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 3), 0))
					else B.caisse(camp, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, 3), 0))
				if c then
					O.decorModele(c)
				end
			end
		end
		local pPioche = place(13, -10)
		if pPioche then
			B.pioche(camp, CFrame.new(pPioche) * CFrame.Angles(0, rng:NextNumber(0, 3), math.rad(70)), O.C.Fer)
		end
		O.decorModele(camp)
		zone(depart.p, 34, P.ambre, "Camp")
	end

	-- ===== 2. Lacs : cuvettes creusées en gradins de cylindres (bords en pente douce) =====
	local lacs = {}
	local function chercherLac(s, f0: number)
		-- plus grand lac possible : on cherche autour de la salle le point qui laisse le plus de place
		-- entre les gisements (9 studs de marge autour de leurs rochers), l'arrivée et les parois
		local c, f = nil, 0
		local a0 = rng:NextNumber(0, math.pi * 2)
		for _, dr in {0.12, 0.3, 0.45} do
			for k = 0, 15 do
				local a = a0 + k * math.pi / 8
				local e = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * dr
				local place = math.min(f0, s.r * (1 - dr) - 2)
				for _, g in infos.gisements or {} do
					if math.abs(e.Y - g.centre.Y) < 14 then
						place = math.min(place, plat(e - g.centre).Magnitude - 7)
					end
				end
				place = math.min(place, plat(e - depart.p).Magnitude - 30)
				if place > f then
					c, f = e, place
				end
			end
		end
		if f < 7 then
			c = nil
		end
		return c, f
	end
	local function creuserLac(s, c: Vector3?, f: number, grand: boolean)
		local hitSol = c and solEn(c)
		if not hitSol then
			return
		end
		local solY = hitSol.Position.Y
		-- surface alignée sur la grille des voxels, 1,6 à 5,6 studs sous le bord. La berge est une sphère qui passe
		-- par le bord (rayon f au niveau du sol) et par la rive (rayon 0,85 f au niveau de l'eau) ; sous l'eau,
		-- un fond plat d'un voxel de profondeur
		local niveau = math.floor((solY - 1.6) / 4) * 4
		local fond = niveau - 4
		local d = solY - niveau
		local cy = (0.2775 * f * f / d + niveau + solY) / 2
		local R = math.sqrt((0.85 * f) ^ 2 + (cy - niveau) ^ 2)
		-- une seule sphère lisse ; tout ce qui est au-dessus du sol est sauvegardé puis remis à l'identique
		local y0 = math.ceil((solY + 0.5) / 4) * 4
		local garde = Region3.new(Vector3.new(c.X - R - 4, y0, c.Z - R - 4), Vector3.new(c.X + R + 4, y0 + 4 * math.ceil((2 * R + 8) / 4), c.Z + R + 4))
			:ExpandToGrid(4)
		local mats, occs = terrain:ReadVoxels(garde, 4)
		terrain:FillBall(Vector3.new(c.X, cy, c.Z), R, AIR)
		-- fond plat d'un voxel (4 studs) sur presque toute la largeur : le lac est large, pas seulement creux au centre
		terrain:FillCylinder(CFrame.new(c.X, niveau - 2, c.Z), 4, f * 0.8, AIR)
		terrain:WriteVoxels(garde, 4, mats, occs)
		local rw = 0.85 * f -- rayon de la surface
		local lac = {s = s, c = Vector3.new(c.X, niveau, c.Z), f = f, rw = rw, niveau = niveau, fond = fond, solY = solY, grand = grand, R = R, cy = cy}
		table.insert(lacs, lac)
		table.insert(interdits, {centre = Vector3.new(c.X, solY, c.Z), rayon = f + 8})
		return lac
	end
	-- on mesure la place libre dans chaque salle (hors forêt, départ, boss) ; le grand lac va là où il y en a
	-- le plus, puis 1–2 petits lacs
	local voulus = 1 + #autresLacs
	local sites = {}
	for _, s in salles do
		if not s.depart and not s.boss and s ~= foret and s.r >= 14 then
			local c, f = chercherLac(s, s.r * 0.78)
			if c then
				table.insert(sites, {s = s, c = c, f = f})
			end
		end
	end
	table.sort(sites, function(x, y)
		return x.f > y.f
	end)
	for i, site in sites do
		if i > voulus then
			break
		end
		local f = if i == 1 then site.f else math.min(site.f, site.s.r * 0.55)
		if creuserLac(site.s, site.c, f, i == 1) then
			roles[site.s] = "lac"
		end
	end

	-- ===== 3. Ruines naines : arche runique devant la salle du boss, statues gardiennes, temple =====
	local axeBoss = unite(plat(boss.p - (infos.avantBoss or depart.p)), Vector3.new(0, 0, -1))
	do
		-- galerie principale qui entre dans la salle du boss
		local meilleure, dmin = nil, math.huge
		for _, g in galeries do
			if g.principal and #g.pts > 0 then
				for _, bout in {g.pts[1], g.pts[#g.pts]} do
					local dd = plat(bout.p - boss.p).Magnitude
					if dd < dmin then
						meilleure, dmin = g, dd
					end
				end
			end
		end
		local pts = {}
		if meilleure then
			pts = table.clone(meilleure.pts)
			if plat(pts[1].p - boss.p).Magnitude < plat(pts[#pts].p - boss.p).Magnitude then
				local inv = {}
				for i = #pts, 1, -1 do
					table.insert(inv, pts[i])
				end
				pts = inv
			end
		end
		-- dernier point de galerie franchement hors de la salle du boss
		local ptArche
		for i, pt in pts do
			if plat(pt.p - boss.p).Magnitude < rb + 6 then
				ptArche = pts[math.max(1, i - 2)]
				break
			end
		end
		if ptArche and modeles then
			local sol = solEn(ptArche.p)
			if sol then
				local t = unite(plat(boss.p - ptArche.p), axeBoss)
				local k = math.clamp(0.8 * ptArche.r / 8.4, 0.75, 1.6) -- piliers à l'intérieur de la galerie
				local arche = poser(ctx, "^Arche$", CFrame.lookAt(sol.Position - Vector3.new(0, 0.6, 0), sol.Position - Vector3.new(0, 0.6, 0) + t), k)
				if arche then
					arche.Name = "ArcheRunique"
				end
				axeBoss = t
			end
		end
		-- statues : deux nains de pierre géants de part et d'autre de l'entrée, tournés vers l'arrivant
		local nain = M3.pieces("Gaspard")
		local entree = boss.p - axeBoss * rb * 0.72
		local lat = axeBoss:Cross(Vector3.yAxis).Unit
		for _, sx in {-1, 1} do
			local sol = solEn(entree + lat * sx * rb * 0.36)
			if sol then
				local pos = sol.Position
				local socle = O.decor(O.bloc(decor, Vector3.new(7, 2.4, 7), CFrame.lookAt(pos + Vector3.new(0, 0.6, 0), pos + Vector3.new(0, 0.6, 0) - axeBoss),
					P.roche, Enum.Material.Slate, "SocleStatue"))
				O.decor(O.bloc(decor, Vector3.new(7.4, 0.25, 7.4), socle.CFrame * CFrame.new(0, 1.25, 0), P.cyan, M.Neon, "LisereSocle")).Transparency = 0.4
				if nain then
					local mn, mx = M3.boite(nain)
					local S = CFrame.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
					local k = 15 / math.max(1, mx.Y - mn.Y)
					local statue = O.modele(decor, "StatueGardien")
					local cible = CFrame.lookAt(pos + Vector3.new(0, 1.8, 0), pos + Vector3.new(0, 1.8, 0) - axeBoss)
					M3.poser(nain, S, cible, k, statue, function(c, teinte)
						c.Material = Enum.Material.Slate
						if teinte == "Pivot" then
							c.Transparency = 1
						elseif teinte == "Yeux" or teinte == "Pupilles" or teinte == "Lueur" or teinte == "Peinture" then
							c.Color, c.Material = P.cyan, M.Neon
							O.tag(c, "GrottePulse")
						elseif teinte == "Barbe" or teinte == "Cheveux" or teinte == "Sourcils" then
							c.Color = P.pierre:Lerp(Color3.new(1, 1, 1), 0.12)
						elseif teinte == "Bottes" or teinte == "Semelle" or teinte == "Ceinture" then
							c.Color = P.roche
						else
							c.Color = P.pierre:Lerp(P.mousse, rng:NextNumber(0, 0.25))
						end
						GD.decorerPart(c)
					end)
					statue.WorldPivot = cible
				end
				-- éclairage par en dessous (dramatique)
				local spot = lumiere(socle, P.violet:Lerp(P.cyan, 0.3), 2.2, 28, "SpotLight")
				if spot then
					spot.Face = Enum.NormalId.Top
					spot.Angle = 50
				end
			end
		end
		-- temple du boss : géode géante au fond, colonnes brisées en cercle, braseros, ossements, runes, brume
		local fond = nil
		for _, h in {5, 9, 3, 13} do
			for _, da in {0, 0.35, -0.35, 0.7, -0.7} do
				if not fond then
					local hit = trace(boss.p + Vector3.new(0, h, 0), CFrame.Angles(0, da, 0):VectorToWorldSpace(axeBoss) * rb * 2.2)
					if hit and math.abs(hit.Normal.Y) < 0.7 then
						fond = hit
					end
				end
			end
		end
		if fond and modeles then
			local n = fond.Normal
			local m = poser(ctx, "^Geode%d+$", outils.axeVers(fond.Position - n * 2 - Vector3.new(0, 1.5, 0), (n + Vector3.new(0, 1, 0)).Unit), 3.2)
			local coeur = piece(m, "Cristal2") or piece(m, "Cristal")
			if coeur then
				local l = lumiere(coeur, P.violet, 1.6, 45)
				if l then
					(l :: any).Shadows = true
				end
			end
		end
		local centre = infos.salleBoss
		for k = 1, 6 do
			local a = k / 6 * math.pi * 2 + 0.3
			local sol = solEn(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * 0.8)
			if sol and modeles then
				poser(ctx, "^ColonneBrisee%d+$", CFrame.new(sol.Position - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(1, 1.5))
			end
		end
		for _, sx in {-1, 1} do
			local sol = solEn(boss.p + axeBoss * rb * 0.45 + lat * sx * rb * 0.5)
			if sol then
				local br = B.brasero(decor, CFrame.new(sol.Position - Vector3.new(0, 0.3, 0)), 0.9)
				if br then
					O.decorModele(br)
				end
			end
		end
		for _ = 1, 6 do
			local a = rng:NextNumber(0, math.pi * 2)
			local sol = solEn(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * rng:NextNumber(0.35, 0.7))
			if sol then
				local m = O.modele(decor, "Ossements")
				local blanc = Color3.fromRGB(214, 210, 196)
				GD.decorerPart(O.ellipsoide(m, Vector3.new(1, 0.9, 1.1), CFrame.new(sol.Position + Vector3.new(0, 0.4, 0)), blanc, M.Lisse, "Crane"))
				for _ = 1, 4 do
					GD.decorerPart(O.bloc(m, Vector3.new(0.25, 0.25, rng:NextNumber(1.4, 2.4)), CFrame.new(sol.Position + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.15,
						rng:NextNumber(-1.5, 1.5))) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), blanc, M.Lisse, "Os"))
				end
			end
		end
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			local sol = solEn(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * 0.55)
			if sol then
				local cf = CFrame.new(sol.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, -a, 0)
				local forme = k % 3
				for _, b in {{0, 0, 1.6, 0}, {0.45, -0.3, 0.8, 0.6 + forme * 0.4}, {-0.45, 0.3, 0.8, -0.6 - forme * 0.3}} do
					local r = GD.decorerPart(O.bloc(decor, Vector3.new(0.18, 0.05, b[3]), cf * CFrame.new(b[1], 0, b[2]) * CFrame.Angles(0, b[4], 0), P.cyan, M.Neon, "CercleRunes"))
					r.Transparency = 0.25
					O.tag(r, "GrottePulse")
				end
			end
		end
		local brume = volume(decor, Vector3.new(rb * 1.5, 3, rb * 1.5), CFrame.new(centre + Vector3.new(0, 1.5, 0)), "BrumeBoss")
		O.brume(brume, P.violet:Lerp(Color3.fromRGB(60, 20, 60), 0.4), 7)
		zone(centre, rb + 8, P.violet, "Temple")
	end

	-- ===== 4. Rais de lumière tombant de fissures du plafond =====
	local function rai(s)
		local p = s.p + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * s.r * 0.3
		local haut = plafondEn(p + Vector3.new(0, 2, 0))
		local bas = solEn(p)
		if not (haut and bas) or haut.Position.Y - bas.Position.Y < 18 then
			return
		end
		local h, b = haut.Position - Vector3.new(0, 0.5, 0), bas.Position
		local fissure = O.decor(O.bloc(decor, Vector3.new(0.5, 0.3, 4.5), CFrame.new(h) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), P.lune, M.Neon, "Fissure"))
		fissure.Transparency = 0.15
		local p0 = volume(decor, Vector3.new(1, 1, 1), CFrame.new(h - Vector3.new(0, 0.5, 0)), "RaiHaut")
		local p1 = volume(decor, Vector3.new(1, 1, 1), CFrame.new(b), "RaiBas")
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = p0, p1
		for k, w in {1, 0.55, 1.7} do
			local beam: any = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Width0, beam.Width1 = 2.6 * w, 9 * w
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Segments = 1
			beam.Color = ColorSequence.new(P.lune)
			beam.Transparency = NumberSequence.new({kp(0, 0.62 + k * 0.1), kp(0.7, 0.9), kp(1, 1)})
			beam.Parent = p0
		end
		local spot = lumiere(p0, P.lune, 2.4, 60, "SpotLight")
		if spot then
			spot.Face = Enum.NormalId.Bottom
			spot.Angle = 28;
			(spot :: any).Shadows = true
		end
		local poussiere = volume(decor, Vector3.new(6, h.Y - b.Y - 2, 6), CFrame.new((h + b) / 2), "PoussiereRai")
		emetteur(poussiere, {
			Name = "Poussiere", Texture = TEX_LUEUR, LightEmission = 1, Color = ColorSequence.new(P.lune),
			Size = NumberSequence.new({kp(0, 0), kp(0.3, 0.18), kp(1, 0)}), Lifetime = NumberRange.new(5, 9), Rate = 7,
			Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -0.15, 0),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, LightInfluence = 0,
		})
	end
	local nRais = 0
	for _, s in {lacs[1] and lacs[1].s, foret, candidates[3], candidates[4], candidates[5]} do
		if s and nRais < 3 then
			rai(s)
			nRais += 1
		end
	end

	-- ===== 5. Lacs : fond lumineux, algues, nénuphars, poissons, brume, berges, ruines englouties, cascade =====
	for _, lac in lacs do
		local c = lac.c
		-- tapis lumineux et algues au fond (posés avant la mise en eau)
		for _ = 1, math.floor(lac.rw * 0.8) do
			local a, r = rng:NextNumber(0, math.pi * 2), lac.rw * math.sqrt(rng:NextNumber(0, 0.85))
			local fond = solEn(Vector3.new(c.X, lac.niveau, c.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * r, 2)
			if fond then
				if rng:NextNumber() < 0.55 then
					local t = GD.decorerPart(O.ellipsoide(decor, Vector3.new(rng:NextNumber(2, 4.5), 0.25, rng:NextNumber(2, 4.5)),
						CFrame.new(fond.Position) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), if rng:NextNumber() < 0.7 then P.turquoise else P.violet, M.Neon, "TapisLumineux"))
					t.Transparency = 0.2
					O.tag(t, "GrottePulse")
				elseif modeles then
					poser(ctx, "^Algue%d+$", CFrame.new(fond.Position) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(0.8, 1.3))
				end
			end
		end
		-- liseré de galets lumineux sur la rive : le contour du lac se lit même dans le noir
		for k = 0, math.floor(lac.rw * 1.6) do
			local a = k / math.floor(lac.rw * 1.6 + 1) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			local q = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (lac.rw + rng:NextNumber(-0.3, 0.6))
			local sol = solEn(q, 2)
			if sol then
				local g = GD.decorerPart(O.ellipsoide(decor, Vector3.new(rng:NextNumber(0.5, 1.1), rng:NextNumber(0.3, 0.5), rng:NextNumber(0.5, 1.1)),
					CFrame.new(sol.Position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), if k % 4 == 0 then P.violet else P.turquoise,
					M.Neon, "GaletLumineux"))
				g.Transparency = 0.15
			end
		end
		-- fond lumineux vu à travers l'eau : c'est lui qui donne au lac sa couleur turquoise
		local nappe = GD.decorerPart(O.ellipsoide(decor, Vector3.new(lac.rw * 1.85, 0.5, lac.rw * 1.85), CFrame.new(c - Vector3.new(0, 2.3, 0)),
			Color3.fromRGB(30, 200, 215), M.Neon, "FondLumineux"))
		nappe.Transparency = 0.3
		local coeurLac = GD.decorerPart(O.ellipsoide(decor, Vector3.new(lac.rw * 0.9, 0.4, lac.rw * 0.9), CFrame.new(c - Vector3.new(0, 2.0, 0)),
			Color3.fromRGB(150, 255, 240), M.Neon, "CoeurLac"))
		coeurLac.Transparency = 0.45
		O.tag(coeurLac, "GrottePulse")
		local lueurEau = volume(decor, Vector3.new(1, 1, 1), CFrame.new(c - Vector3.new(0, 1.6, 0)), "LueurLac")
		lumiere(lueurEau, P.cyan, 1.8, lac.rw * 2.6)
		if modeles then
			for _ = 1, math.max(2, math.floor(lac.rw / 3)) do
				local a, r = rng:NextNumber(0, math.pi * 2), lac.rw * rng:NextNumber(0.2, 0.8)
				poser(ctx, "^Nenuphar%d+$", CFrame.new(c + Vector3.new(math.cos(a) * r, 0.05, math.sin(a) * r)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					rng:NextNumber(0.9, 1.5))
			end
			for i = 1, math.max(3, math.floor(lac.rw / 2.2)) do
				local m = poser(ctx, "^Poisson$", CFrame.new(c - Vector3.new(0, 1.6, 0)), rng:NextNumber(0.9, 1.6))
				if m then
					O.tag(m, "GrottePoisson")
					m:SetAttribute("Centre", c - Vector3.new(0, rng:NextNumber(1.1, 2.2), 0))
					m:SetAttribute("Rayon", lac.rw * rng:NextNumber(0.35, 0.75))
					m:SetAttribute("Vitesse", rng:NextNumber(0.25, 0.6) * (if i % 2 == 0 then -1 else 1))
					m:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
				end
			end
		end
		local brume = volume(decor, Vector3.new(lac.rw * 2, 2, lac.rw * 2), CFrame.new(c + Vector3.new(0, 1, 0)), "BrumeLac")
		O.brume(brume, Color3.fromRGB(170, 235, 255), 5)
		local lucioles = volume(decor, Vector3.new(lac.rw * 2.2, 8, lac.rw * 2.2), CFrame.new(c + Vector3.new(0, 4.5, 0)), "LuciolesLac")
		O.lucioles(lucioles, P.turquoise, 6)
		-- berges : boue puis mousse
		local f = lac.f
		terrain:ReplaceMaterial(Region3.new(Vector3.new(c.X - f - 6, lac.solY - 6, c.Z - f - 6), Vector3.new(c.X + f + 6, lac.solY + 1.5, c.Z + f + 6)):ExpandToGrid(4),
			4, ctx.matPart, Enum.Material.Mud)
		for _ = 1, 8 do
			local a = rng:NextNumber(0, math.pi * 2)
			local q = Vector3.new(c.X, lac.solY, c.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * (f + 4)
			terrain:ReplaceMaterial(Region3.new(q - Vector3.new(4, 4, 4), q + Vector3.new(4, 2, 4)):ExpandToGrid(4), 4, Enum.Material.Mud, Enum.Material.LeafyGrass)
		end
		-- champignons de berge
		for _ = 1, 3 do
			local a = rng:NextNumber(0, math.pi * 2)
			local sol = solEn(Vector3.new(c.X, lac.solY, c.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * (f + rng:NextNumber(2.5, 5)))
			if sol and modeles then
				GD.poser(decor, "^Champignon%d+$", CFrame.new(sol.Position - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					rng:NextNumber(0.9, 1.6), rng, COUL_GENERIQUE, "bas")
			end
		end
		-- ruines englouties
		if modeles then
			for k = 1, (if lac.grand then 3 else 1) do
				local a = rng:NextNumber(0, math.pi * 2)
				local r = if k == 1 then lac.rw * 0.6 else f + rng:NextNumber(0, 2)
				local sol = solEn(Vector3.new(c.X, lac.solY, c.Z) + Vector3.new(math.cos(a), 0, math.sin(a)) * r, 3)
				if sol then
					poser(ctx, if k == 3 then "^Gravats$" else "^ColonneBrisee%d+$",
						CFrame.new(sol.Position - Vector3.new(0, 0.6, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 6), rng:NextNumber(-0.12, 0.12)),
						rng:NextNumber(1, 1.4))
				end
			end
		end
		-- cascade qui tombe du plafond dans le grand lac
		if lac.grand then
			local _, dir = coin(lac.s, lac.rw * 0.55)
			local w = c + dir * lac.rw * 0.5
			local haut = plafondEn(Vector3.new(w.X, lac.solY + 2, w.Z))
			if haut and haut.Position.Y - c.Y > 14 then
				local top = Vector3.new(w.X, haut.Position.Y + 1, w.Z)
				local H = top.Y - c.Y
				local cf = CFrame.new((top + Vector3.new(w.X, c.Y, w.Z)) / 2)
				local col = O.decor(O.cylindre(decor, H, 3.4, cf, Color3.fromRGB(175, 240, 255), Enum.Material.ForceField, "Cascade"))
				col.CastShadow = false
				local coeur = O.decor(O.cylindre(decor, H, 2.2, cf, Color3.fromRGB(120, 210, 240), M.Verre, "CascadeCoeur"))
				coeur.Transparency, coeur.CastShadow = 0.55, false
				local source = volume(decor, Vector3.new(3, 0.4, 3), CFrame.new(top - Vector3.new(0, 1.2, 0)), "CascadeSource")
				emetteur(source, {
					Name = "Eau", Texture = TEX_ETINCELLE, LightEmission = 0.7, LightInfluence = 0.3,
					Color = ColorSequence.new(Color3.fromRGB(200, 245, 255)), Size = NumberSequence.new({kp(0, 0.5), kp(1, 0.9)}),
					Transparency = NumberSequence.new({kp(0, 0.2), kp(1, 0.6)}), Squash = NumberSequence.new(-1.6),
					Orientation = Enum.ParticleOrientation.VelocityParallel, EmissionDirection = Enum.NormalId.Bottom,
					Speed = NumberRange.new(30, 38), Lifetime = NumberRange.new(H / 36), Rate = 70, SpreadAngle = Vector2.new(4, 4),
					Shape = Enum.ParticleEmitterShape.Box,
				})
				local pied = volume(decor, Vector3.new(4, 0.4, 4), CFrame.new(w.X, c.Y + 0.3, w.Z), "CascadePied")
				emetteur(pied, {
					Name = "Ecume", Texture = TEX_ETINCELLE, LightEmission = 0.6, Color = ColorSequence.new(Color3.fromRGB(220, 250, 255)),
					Size = NumberSequence.new({kp(0, 0.5), kp(1, 0.1)}), Transparency = NumberSequence.new(0.25),
					EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(7, 13), SpreadAngle = Vector2.new(55, 55),
					Acceleration = Vector3.new(0, -40, 0), Lifetime = NumberRange.new(0.5, 0.9), Rate = 45,
				})
				local embrun = volume(decor, Vector3.new(10, 3, 10), CFrame.new(w.X, c.Y + 1.5, w.Z), "CascadeEmbrun")
				O.brume(embrun, Color3.fromRGB(210, 245, 255), 10)
				local anneau = O.decor(O.disque(decor, 0.15, 7, CFrame.new(w.X, c.Y + 0.08, w.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(230, 252, 255), M.Neon, "Ecume"))
				anneau.Transparency, anneau.CastShadow = 0.55, false
				O.tag(anneau, "GrottePulse")
				if SON_CASCADE ~= "" then
					local son = Instance.new("Sound")
					son.Name = "Cascade"
					son.SoundId = SON_CASCADE
					son.Looped = true
					son.Volume = 0.6
					son.RollOffMinDistance = 10
					son.RollOffMaxDistance = 90
					son.Parent = pied
					son:Play()
				end
			end
		end
		zone(c, lac.f + 16, P.cyan, "Lac")
	end

	-- ===== 6. Forêt de champignons géants =====
	if foret and modeles then
		local es = entrees(foret)
		local n = rng:NextInteger(7, 10)
		local allumes = 0
		for k = 1, n do
			local a = k / n * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
			local p = foret.p + Vector3.new(math.cos(a), 0, math.sin(a)) * foret.r * rng:NextNumber(0.42, 0.85)
			local proche = false
			for _, e in es do
				if plat(e - p).Magnitude < 8 then
					proche = true
				end
			end
			local sol = not proche and solEn(p)
			if sol and libre(sol.Position, 5) then
				local plafond = plafondEn(sol.Position + Vector3.new(0, 1, 0))
				local libreH = if plafond then plafond.Position.Y - sol.Position.Y else 40
				local k3 = math.min(rng:NextNumber(0.8, 1.45), (libreH - 3) / 14)
				if k3 > 0.45 then
					local m = poser(ctx, "^ChampiGeant%d+$", CFrame.new(sol.Position - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), k3)
					local lam = piece(m, "Lamelles")
					if lam and allumes < 4 then
						allumes += 1
						lumiere(lam, P.magenta, 0.75, 18)
					end
					table.insert(interdits, {centre = sol.Position, rayon = 3})
				end
			end
		end
		for _ = 1, 18 do
			local a = rng:NextNumber(0, math.pi * 2)
			local sol = solEn(foret.p + Vector3.new(math.cos(a), 0, math.sin(a)) * foret.r * rng:NextNumber(0.3, 0.9))
			if sol and libre(sol.Position, 2) then
				GD.poser(decor, "^Champignon%d+$", CFrame.new(sol.Position - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					rng:NextNumber(0.8, 1.6), rng, COUL_GENERIQUE, "bas")
			end
		end
		local nuage = volume(decor, Vector3.new(foret.r * 1.6, 6, foret.r * 1.6), CFrame.new(foret.p + Vector3.new(0, 3.5, 0)), "Spores")
		emetteur(nuage, {
			Name = "Spores", Texture = TEX_LUEUR, LightEmission = 1, LightInfluence = 0,
			Color = ColorSequence.new(P.magenta, Color3.fromRGB(255, 200, 240)),
			Size = NumberSequence.new({kp(0, 0), kp(0.2, 0.3, 0.1), kp(1, 0)}), Lifetime = NumberRange.new(7, 11), Rate = 14,
			Speed = NumberRange.new(0.4, 1.2), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 0.45, 0),
			Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
		terrain:ReplaceMaterial(Region3.new(foret.p - Vector3.new(foret.r, 4, foret.r), foret.p + Vector3.new(foret.r, 1.5, foret.r)):ExpandToGrid(4), 4,
			ctx.matPart, Enum.Material.Ground)
		zone(foret.p, foret.r + 10, P.magenta, "Foret")
	end

	-- ===== 7. Dallages et colonnes brisées dans les autres salles (ruines du royaume nain) =====
	for _, s in candidates do
		if not roles[s] then
			terrain:ReplaceMaterial(Region3.new(s.p - Vector3.new(s.r * 0.55, 3, s.r * 0.55), s.p + Vector3.new(s.r * 0.55, 1.5, s.r * 0.55)):ExpandToGrid(4), 4,
				ctx.matPart, Enum.Material.Cobblestone)
			if modeles then
				for _ = 1, rng:NextInteger(2, 4) do
					local p = coin(s, s.r * rng:NextNumber(0.6, 0.8))
					local sol = solEn(p)
					if sol and libre(sol.Position, 4) then
						poser(ctx, if rng:NextNumber() < 0.7 then "^ColonneBrisee%d+$" else "^Gravats$",
							CFrame.new(sol.Position - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(0.9, 1.4))
						table.insert(interdits, {centre = sol.Position, rayon = 4})
					end
				end
			end
		end
	end

	-- ===== 8. Lanternes à vers luisants le long du chemin principal =====
	if modeles then
		local derniere = depart.p
		local cote = 1
		for _, g in galeries do
			if g.principal then
				for _, pt in g.pts do
					if (pt.p - derniere).Magnitude > 26 and plat(pt.p - boss.p).Magnitude > rb + 4 and plat(pt.p - depart.p).Magnitude > 22 then
						local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * cote
						local sol = solEn(pt.p + lat * pt.r * 0.72)
						if sol then
							local vers = -lat
							local cf = CFrame.fromMatrix(sol.Position - Vector3.new(0, 0.3, 0), vers, Vector3.yAxis)
							local m = poser(ctx, "^LanterneVers$", cf, 1.45)
							local l = piece(m, "Lueur")
							if l then
								O.tag(l, "GrotteLanterne")
								lumiere(l, P.turquoise, 1.6, 24)
							end
							derniere = pt.p
							cote = -cote
						end
					end
				end
			end
		end
	end

	-- ===== 9. Décor générique (stalactites, colonnes, racines, restes de mine) en palette froide =====
	GD.decorer(ctx, {
		depart = depart, boss = boss, chemin = chemin, lieux = salles, galeries = galeries,
		gisements = infos.gisements, interdits = interdits, salleBoss = infos.salleBoss, avantBoss = infos.avantBoss,
	}, outils, {cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, couleurs = COUL_GENERIQUE})

	-- ===== 10. Géodes cyan / améthyste aux parois =====
	if modeles then
		local nLum = 0
		local function geode(hit, k)
			local n = hit.Normal
			local m = poser(ctx, "^Geode%d+$", outils.axeVers(hit.Position - n * 0.8, n) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), k)
			local c = piece(m, if nLum % 2 == 0 then "Cristal" else "Cristal2")
			if c and nLum < 8 then
				nLum += 1
				lumiere(c, if nLum % 2 == 1 then P.cyan else P.violet, 1.1, 16 * k)
			end
		end
		for _, s in salles do
			if not s.depart and not s.boss then
				local a = rng:NextNumber(0, 2 * math.pi)
				local hit = outils.paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(1, 6), s.r * 1.6)
				if hit then
					geode(hit, rng:NextNumber(0.9, 1.4))
				end
			end
		end
		for _ = 1, 16 do
			local pt = chemin[rng:NextInteger(1, #chemin)]
			local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
			local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 8), pt.r + 6)
			if hit and (hit.Position - depart.p).Magnitude > 20 then
				geode(hit, rng:NextNumber(0.5, 0.9))
			end
		end
	end

	-- ===== 11. Voûte de vers luisants (ciel étoilé sous la roche) et fils perlés =====
	local function etoiles(hit, taux: number, couleur: Color3)
		local v = volume(decor, Vector3.new(7, 0.6, 7), CFrame.new(hit.Position - Vector3.new(0, 1.4, 0)), "VersLuisants")
		emetteur(v, {
			Name = "Etoiles", Texture = TEX_LUEUR, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(couleur),
			Size = NumberSequence.new({kp(0, 0), kp(0.15, 0.22, 0.1), kp(0.85, 0.22, 0.1), kp(1, 0)}),
			Transparency = NumberSequence.new(0.05), Lifetime = NumberRange.new(7, 13), Rate = taux, Speed = NumberRange.new(0),
			LockedToPart = true, Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
	end
	for _, s in salles do
		local n = math.floor(s.r * (if s.depart then 0.4 else 0.85))
		for _ = 1, n do
			local a, r = rng:NextNumber(0, math.pi * 2), s.r * math.sqrt(rng:NextNumber(0, 0.75))
			local p = s.p + Vector3.new(math.cos(a) * r, 2, math.sin(a) * r)
			local haut = plafondEn(p)
			if haut then
				etoiles(haut, 1.3, if rng:NextNumber() < 0.8 then P.cyan else P.turquoise)
				if modeles and rng:NextNumber() < 0.3 and haut.Position.Y - s.p.Y > 18 then
					poser(ctx, "^Fils%d+$", CFrame.new(haut.Position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
						rng:NextNumber(0.8, 1.3), "haut")
				end
			end
		end
	end
	for i = 1, #chemin, 3 do
		local pt = chemin[i]
		local haut = plafondEn(pt.p + Vector3.new(0, 2, 0))
		if haut then
			etoiles(haut, 1, P.cyan)
			if modeles and rng:NextNumber() < 0.18 and haut.Position.Y - pt.p.Y > 15 then
				poser(ctx, "^Fils2$", CFrame.new(haut.Position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(0.7, 1), "haut")
			end
		end
	end

	-- ===== 12. Rideaux de mousse lumineuse dans les galeries =====
	if modeles then
		for _ = 1, 30 do
			local pt = chemin[rng:NextInteger(1, #chemin)]
			local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
			local haut = plafondEn(pt.p + lat * pt.r * 0.65 + Vector3.new(0, 2, 0))
			if haut and haut.Position.Y - pt.p.Y > 11 then
				local pos = haut.Position + Vector3.new(0, 0.6, 0)
				poser(ctx, "^Mousse%d+$", CFrame.fromMatrix(pos, unite(plat(pt.t), Vector3.xAxis), Vector3.yAxis), rng:NextNumber(0.8, 1.25), "haut")
			end
		end
	end

	-- ===== 13. Méduses de spores qui flottent dans les salles hautes =====
	if modeles then
		local n = 0
		for _, s in salles do
			if not s.depart and n < 10 then
				for _ = 1, (if s.haute then 3 else 1) do
					local p = s.p + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * s.r * 0.5
					local sol, haut = solEn(p), plafondEn(p + Vector3.new(0, 2, 0))
					if sol and haut and haut.Position.Y - sol.Position.Y > 17 then
						local y = sol.Position.Y + rng:NextNumber(8, math.min(14, haut.Position.Y - sol.Position.Y - 6))
						local m = poser(ctx, "^Meduse$", CFrame.new(p.X, y, p.Z), rng:NextNumber(0.8, 1.4))
						if m then
							O.tag(m, "GrotteMeduse")
							m:SetAttribute("Origine", Vector3.new(p.X, y, p.Z))
							m:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
							n += 1
						end
					end
				end
			end
		end
	end

	-- ===== 15. Lumière : voûtes lumineuses, veines de cristal aux parois, galets lumineux, fil du guide =====
	-- Le noir complet cassait le jeu (gisements et mobs invisibles) : chaque salle et chaque tronçon de galerie
	-- reçoit une lumière douce sans ombre, teintée par sa zone, et les parois sont parcourues de veines néon.
	local nRemplissage = 0
	local function remplir(part: Instance, couleur: Color3, lum: number, portee: number)
		if nRemplissage >= MAX_REMPLISSAGE then
			return
		end
		nRemplissage += 1
		local l = Instance.new("PointLight")
		l.Name = "Remplissage"
		l.Color, l.Brightness, l.Range, l.Shadows = couleur, lum, math.min(portee, 60), false
		l.Parent = part
	end
	local function teinteSalle(s): Color3
		if s.depart then return P.ambre:Lerp(P.lune, 0.35) end
		if s.boss then return P.violet:Lerp(P.lune, 0.25) end
		if roles[s] == "foret" then return P.magenta:Lerp(P.lune, 0.35) end
		if roles[s] == "lac" then return P.cyan:Lerp(P.lune, 0.3) end
		return P.turquoise:Lerp(P.lune, 0.45)
	end
	-- salles : un « soleil de vers luisants » sous la voûte, plus des relais aux bords des grandes salles
	for _, s in salles do
		local sol = solEn(s.p + Vector3.new(0, 4, 0), 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local haut = plafondEn(Vector3.new(s.p.X, y0 + 2, s.p.Z), 90)
		local yL = if haut then math.min(haut.Position.Y - 3, y0 + 22) else y0 + 14
		local c = teinteSalle(s)
		local coeur = volume(decor, Vector3.one, CFrame.new(s.p.X, yL, s.p.Z), "Voute")
		remplir(coeur, c, if s.boss then 0.3 elseif s.depart then 0.25 elseif roles[s] == "foret" then 0.4 else 0.58, math.min(60, s.r * 1.6 + 14))
		local relais = if s.r >= 24 then 3 elseif s.r >= 17 then 2 else 0
		local a0 = rng:NextNumber(0, math.pi * 2)
		for k = 1, relais do
			local a = a0 + k * 2 * math.pi / relais
			local p = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * 0.62
			local sp = solEn(p + Vector3.new(0, 4, 0), 10)
			if sp then
				local r = volume(decor, Vector3.one, CFrame.new(sp.Position + Vector3.new(0, 9, 0)), "VouteRelais")
				remplir(r, c, if s.boss then 0.2 else 0.38, 34)
			end
		end
	end
	-- galeries : relais tous les 22 studs (les galeries étaient les vrais trous noirs)
	for _, g in galeries do
		local dernier = nil
		for _, pt in g.pts do
			if not dernier or (pt.p - dernier).Magnitude > 22 then
				dernier = pt.p
				local haut = plafondEn(pt.p + Vector3.new(0, 2, 0), 40)
				local y = if haut then math.min(haut.Position.Y - 2.5, pt.p.Y + 9) else pt.p.Y + 8
				local r = volume(decor, Vector3.one, CFrame.new(pt.p.X, y, pt.p.Z), "GalerieLueur")
				remplir(r, P.turquoise:Lerp(P.lune, 0.62), if g.principal then 0.4 else 0.32, 32)
			end
		end
	end

	-- veines de cristal : traits néon qui serpentent sur la roche, collés à la paroi, avec des ramifications
	local COULEURS_VEINE = {P.cyan, P.turquoise, P.cyan, P.violet}
	local function veine(hit, longueur: number, couleur: Color3, epaisseur: number, profondeur: number)
		local pos, n = hit.Position, hit.Normal
		local haut = unite(Vector3.yAxis - n * n.Y, Vector3.yAxis)
		local cote = n:Cross(haut).Unit
		local dir = (haut * rng:NextNumber(0.6, 1) + cote * rng:NextNumber(-0.8, 0.8)).Unit
		local premier = nil
		for _ = 1, longueur do
			local pas = rng:NextNumber(1.6, 3)
			dir = (dir + cote * rng:NextNumber(-0.55, 0.55) + haut * 0.15).Unit
			local vise = pos + dir * pas
			-- recolle le point à la roche (la paroi n'est pas plane)
			local recolle = trace(vise + n * 2.5, -n * 5)
			if not recolle then
				break
			end
			local suivant = recolle.Position + recolle.Normal * 0.08
			local seg = suivant - pos
			if seg.Magnitude < 0.3 or math.abs(seg.Unit:Dot(recolle.Normal)) > 0.95 then
				break
			end
			local p = O.decor(O.bloc(decor, Vector3.new(epaisseur, epaisseur * 0.5, seg.Magnitude + epaisseur * 0.6),
				CFrame.lookAt(pos + seg / 2, suivant, recolle.Normal), couleur, M.Neon, "Veine"))
			p.CastShadow = false
			premier = premier or p
			if profondeur > 0 and rng:NextNumber() < 0.28 then
				veine(recolle, math.max(2, math.floor(longueur / 2)), couleur, epaisseur * 0.65, profondeur - 1)
			end
			pos, n = suivant, recolle.Normal
			haut = unite(Vector3.yAxis - n * n.Y, Vector3.yAxis)
			cote = unite(n:Cross(haut), cote)
			epaisseur = math.max(0.12, epaisseur * 0.94)
		end
		if premier and rng:NextNumber() < 0.5 then
			O.tag(premier, "GrottePulse")
		end
		return premier
	end
	local nVeines = 0
	for _, s in salles do
		local nb = if s.boss then 10 elseif s.depart then 3 else math.floor(s.r / 3.5)
		for _ = 1, nb do
			local a = rng:NextNumber(0, 2 * math.pi)
			local hit = outils.paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(0.5, 5), s.r * 1.7)
			if hit and (hit.Position - depart.p).Magnitude > 14 then
				local c = if s.boss then (if rng:NextNumber() < 0.6 then P.violet else P.cyan)
					elseif roles[s] == "foret" then (if rng:NextNumber() < 0.6 then P.magenta else P.violet)
					else COULEURS_VEINE[rng:NextInteger(1, #COULEURS_VEINE)]
				veine(hit, rng:NextInteger(6, 11), c, rng:NextNumber(0.3, 0.5), 2)
				nVeines += 1
			end
		end
	end
	for i = 1, #chemin, 4 do
		local pt = chemin[i]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.3, 4), pt.r + 8)
		if hit and (hit.Position - depart.p).Magnitude > 14 then
			veine(hit, rng:NextInteger(5, 9), COULEURS_VEINE[rng:NextInteger(1, #COULEURS_VEINE)], rng:NextNumber(0.25, 0.42), 1)
			nVeines += 1
		end
	end

	-- galets lumineux au pied des parois des galeries (on devine les bords du chemin)
	for i = 1, #chemin, 2 do
		local pt = chemin[i]
		for _, cote in {-1, 1} do
			if rng:NextNumber() < 0.55 then
				local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * cote
				local sol = solEn(pt.p + lat * pt.r * rng:NextNumber(0.78, 0.92) + pt.t * rng:NextNumber(-3, 3))
				if sol and libre(sol.Position, 1) then
					local c = if rng:NextNumber() < 0.75 then P.turquoise else P.cyan
					for _ = 1, rng:NextInteger(2, 5) do
						local d = rng:NextNumber(0.35, 0.9)
						local q = sol.Position + Vector3.new(rng:NextNumber(-1.4, 1.4), d * 0.25, rng:NextNumber(-1.4, 1.4))
						local b = O.decor(O.ellipsoide(decor, Vector3.new(d, d * 0.6, d), CFrame.new(q), c, M.Neon, "GaletLueur"))
						b.CastShadow = false
					end
				end
			end
		end
	end

	-- fil du guide : points du chemin principal, dans l'ordre départ → boss (feux follets côté client)
	local guide = Instance.new("Folder")
	guide.Name = "Guide"
	local nPts = 0
	for _, g in galeries do
		if g.principal then
			for _, pt in g.pts do
				nPts += 1
				guide:SetAttribute("P" .. nPts, pt.p)
			end
		end
	end
	guide:SetAttribute("N", nPts)
	guide:SetAttribute("Boss", boss.p)
	guide.Parent = ctx.modele
	ctx.modele:SetAttribute("Veines", nVeines)
	ctx.modele:SetAttribute("Remplissage", nRemplissage)

	-- ===== 14. Mise en eau des lacs (en dernier : les rayons du décor ignorent l'eau, ceux du générateur non) =====
	-- même sphère que la cuvette, remplie d'eau ; tout ce qui est au-dessus de la surface est remis à l'identique
	-- (les voxels du bord, en partie rocheux, deviennent aussi de l'eau : l'eau touche bien les berges)
	for _, lac in lacs do
		local c, R = lac.c, lac.R
		local garde = Region3.new(Vector3.new(c.X - R - 4, lac.niveau, c.Z - R - 4),
			Vector3.new(c.X + R + 4, lac.niveau + 4 * math.ceil((2 * R + 8) / 4), c.Z + R + 4)):ExpandToGrid(4)
		local mats, occs = terrain:ReadVoxels(garde, 4)
		terrain:FillBall(Vector3.new(c.X, lac.cy, c.Z), R - 0.3, EAU)
		terrain:FillCylinder(CFrame.new(c.X, lac.niveau - 2, c.Z), 4, lac.f * 0.8, EAU)
		terrain:WriteVoxels(garde, 4, mats, occs)
	end
end

return GrotteLueurs
