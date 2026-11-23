--[[ Habillage des grottes profondes (appelé par GrotteGenerateur à la fin de la génération).
	Purement décoratif : aucune collision, rien ne bloque le chemin départ → boss, rien dans les gisements.

	- Stalactites (avec gouttes qui tombent), stalagmites et colonnes modélisées (blender/grotte_decor.py → GrotteDecor.fbx)
	- Cristaux modélisés aux parois (sources de lumière), champignons bioluminescents
	- Galeries humides : bassins d'eau dans les salles, mousse et roche mouillée au pied des parois, racines qui pendent
	- Restes d'une ancienne mine : étais en bois, vieux rails, wagonnet renversé, caisses, pioches, lanternes
	- Balisage du chemin principal par des torches ; poussières lumineuses dans les salles
	- Salle du boss : cristal géant, pierres dressées, ossements, brume teintée, cercle de runes au sol
	Sans le modèle 3D importé, on retombe sur les anciens décors en blocs du générateur (outils.pointe / outils.cristaux). ]]
local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local B = require(script.Parent.Batiments)
local M, C = O.M, O.C

local GrotteDecor = {}
local terrain = workspace.Terrain

local TEX_GOUTTE = "rbxasset://textures/particles/sparkles_main.dds"

local function decorer(p: BasePart)
	O.decor(p)
	p.CastShadow = false
	return p
end

-- Pose une variante (motif "^Stalactite%d+$"...) : repère source = base du modèle (yBase = "bas" ou "haut")
local function poser(parent, motif, cible: CFrame, k: number, rng, couleurs, yBase)
	local vars = M3.variantes(motif)
	if #vars == 0 then
		return nil
	end
	local pieces = M3.pieces(vars[rng:NextInteger(1, #vars)]) :: {MeshPart}
	local mn, mx = M3.boite(pieces)
	local y = if yBase == "haut" then mx.Y else mn.Y
	local S = CFrame.new((mn.X + mx.X) / 2, y, (mn.Z + mx.Z) / 2)
	local m = O.modele(parent, string.match(motif, "%^(%a+)") or "Decor")
	M3.poser(pieces, S, cible, k, m, function(c, teinte)
		local t = couleurs[teinte]
		if t then
			c.Color, c.Material = t[1], t[2]
			if t[3] then
				c.Transparency = t[3]
			end
		end
		decorer(c)
	end)
	m.WorldPivot = cible
	return m, (mx.Y - mn.Y) * k
end

local function gouttes(parent, pos: Vector3, couleur: Color3, sol: number?)
	local p = O.decor(O.bloc(parent, Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos), Color3.new(), M.Lisse, "Goutteur"))
	p.Transparency = 1
	local chute = math.max(4, (pos.Y - (sol or pos.Y - 12)))
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_GOUTTE
	e.Color = ColorSequence.new(couleur:Lerp(Color3.new(1, 1, 1), 0.5))
	e.LightEmission = 0.6
	e.Size = NumberSequence.new(0.18)
	e.Squash = NumberSequence.new(-1.2)
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Speed = NumberRange.new(0)
	e.Acceleration = Vector3.new(0, -60, 0)
	e.Lifetime = NumberRange.new(math.sqrt(2 * chute / 60))
	e.Rate = 0.6
	e.Transparency = NumberSequence.new(0.1)
	e.Parent = p
end

function GrotteDecor.decorer(ctx, infos, outils, opts)
	opts = opts or {}
	local rng = ctx.rng
	local niveau = ctx.niveau
	local roche = niveau.ambiance.roche
	local lueur = niveau.ambiance.lumiere
	local decor = ctx.decor
	local lancer, paroi, solSous, plat = outils.lancer, outils.paroi, outils.solSous, outils.plat
	local depart, boss = infos.depart, infos.boss
	local chemin, salles, galeries = infos.chemin, infos.lieux, infos.galeries
	local modeles = #M3.variantes("^Stalactite%d+$") > 0

	local COULEURS = {
		Roche = {roche:Lerp(Color3.fromRGB(58, 56, 60), 0.3), ctx.matPart},
		Goutte = {lueur:Lerp(Color3.new(1, 1, 1), 0.4), M.Verre, 0.3},
		Cristal = {lueur, M.Neon},
		Socle = {roche:Lerp(Color3.new(0, 0, 0), 0.3), ctx.matPart},
		Pied = {Color3.fromRGB(214, 206, 186), M.Lisse},
		Chapeau = {roche:Lerp(lueur, 0.45), M.Lisse},
		Lueur = {lueur:Lerp(Color3.fromRGB(150, 255, 220), 0.4), M.Neon},
	}
	for k, v in opts.couleurs or {} do
		COULEURS[k] = v
	end

	local function loinDu(p: Vector3, centre: Vector3, d: number): boolean
		return (p - centre).Magnitude > d
	end
	-- on ne décore pas sur les gisements (les rochers de minerai restent bien visibles)
	local function horsGisements(p: Vector3, marge: number): boolean
		for _, g in infos.interdits or infos.gisements or {} do
			if (p - g.centre).Magnitude < (g.rayon or 6) * 0.6 + marge then
				return false
			end
		end
		return true
	end
	-- décor qui a du volume (sans collision) : jamais en plein passage, on le traverserait comme un fantôme
	local function solLibre(p: Vector3, marge: number, passage: number): boolean
		return horsGisements(p, marge) and not (infos.surChemin and infos.surChemin(p, passage))
	end

	-- ===== 1. Stalactites (avec gouttes), stalagmites =====
	for _ = 1, 55 do
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local depuis = pt.p + Vector3.new(rng:NextNumber(-pt.r, pt.r) * 0.7, 2, rng:NextNumber(-pt.r, pt.r) * 0.7)
		local hit = lancer(depuis, Vector3.new(0, 70, 0))
		if hit and hit.Normal.Y < -0.3 then
			local hauteurLibre = hit.Position.Y - pt.p.Y
			local longueur = math.min(rng:NextNumber(4, 12), hauteurLibre - 8)
			if longueur > 2.5 then
				local cf = CFrame.new(hit.Position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				local m, l = nil, nil
				if modeles then
					m, l = poser(decor, "^Stalactite%d+$", cf, longueur / 11, rng, COULEURS, "haut")
				end
				if not m then
					outils.pointe(ctx, hit.Position, -1, longueur / 8)
				elseif rng:NextNumber() < 0.35 then
					gouttes(decor, hit.Position - Vector3.new(0, (l or longueur) + 0.3, 0), lueur, pt.p.Y)
				end
			end
		end
	end
	for _ = 1, 40 do
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = solSous(pt.p + lat * pt.r * rng:NextNumber(0.6, 0.85))
		if hit and loinDu(hit.Position, depart.p, 18) and solLibre(hit.Position, 4, 4) then
			local h = rng:NextNumber(3, 9)
			local cf = CFrame.new(hit.Position - Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			if not (modeles and poser(decor, "^Stalagmite%d+$", cf, h / 8, rng, COULEURS, "bas")) then
				outils.pointe(ctx, hit.Position, 1, h / 6)
			end
		end
	end

	-- ===== 2. Colonnes (sol → plafond) contre les parois des salles =====
	if modeles then
		for _, s in salles do
			if not s.depart and not s.boss then
				for _ = 1, rng:NextInteger(1, 2) do
					local a = rng:NextNumber(0, math.pi * 2)
					local p = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * 0.72
					local sol = solSous(p)
					if sol and solLibre(sol.Position, 6, 6) then
						local plafond = lancer(sol.Position + Vector3.new(0, 1, 0), Vector3.new(0, 60, 0))
						if plafond then
							local h = plafond.Position.Y - sol.Position.Y + 1.5
							if h > 12 and h < 50 then
								local cf = CFrame.new(sol.Position - Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
								poser(decor, "^Colonne%d+$", cf, h / 20, rng, COULEURS, "bas")
							end
						end
					end
				end
			end
		end
	end

	if opts.cristaux ~= false then
	-- ===== 3. Cristaux aux parois (sources de lumière) =====
	local function cristal(hit, echelle)
		if not modeles then
			outils.cristaux(ctx, hit.Position, hit.Normal, echelle)
			return
		end
		local n = hit.Normal
		local cf = outils.axeVers(hit.Position - n * 0.6, n) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		local m = poser(decor, "^Cristal%d+$", cf, echelle * rng:NextNumber(0.8, 1.2), rng, COULEURS, "bas")
		local premier = m and m:FindFirstChildWhichIsA("BasePart")
		if premier then
			outils.lumiere(ctx, premier, lueur, 1.3, 20 * echelle)
		end
	end
	for _, s in salles do
		local a = rng:NextNumber(0, 2 * math.pi)
		local hit = paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(1, 6), s.r * 1.6)
		if hit then
			cristal(hit, if s.boss then 1.8 else 1.3)
		end
	end
	for _ = 1, 30 do
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = paroi(pt.p, lat, rng:NextNumber(0.5, 7), pt.r + 6)
		if hit and loinDu(hit.Position, depart.p, 18) then
			cristal(hit, rng:NextNumber(0.7, 1.1))
		end
	end
	end

	-- ===== 4. Galeries humides : bassins, mousse, roche mouillée =====
	local bassins = {}
	if opts.bassins ~= false then
	for _, s in salles do
		if not s.depart and not s.boss and rng:NextNumber() < 0.65 then
			local a = rng:NextNumber(0, 2 * math.pi)
			local p = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0.25, 0.5)
			local sol = solSous(p)
			if sol and horsGisements(sol.Position, 8) then
				local R = math.min(rng:NextNumber(6, 10), s.r * 0.4)
				local c = sol.Position
				terrain:FillCylinder(CFrame.new(c - Vector3.new(0, 1.1, 0)), 2.4, R, Enum.Material.Water)
				-- berge boueuse et moussue
				local region = Region3.new(c - Vector3.new(R + 4, 3, R + 4), c + Vector3.new(R + 4, 1, R + 4)):ExpandToGrid(4)
				terrain:ReplaceMaterial(region, 4, ctx.matPart, Enum.Material.Mud)
				table.insert(bassins, {c, R})
			end
		end
	end
	end
	for _ = 1, (if opts.humide == false then 0 else 50) do -- mousse et roche mouillée au pied des parois
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local bas = paroi(pt.p, lat, 1, pt.r + 8)
		if bas then
			local q = bas.Position
			local zone = Region3.new(q - Vector3.new(4, 3, 4), q + Vector3.new(4, 2, 4)):ExpandToGrid(4)
			terrain:ReplaceMaterial(zone, 4, ctx.matPart, if rng:NextNumber() < 0.6 then Enum.Material.LeafyGrass else Enum.Material.Mud)
			local haut = paroi(pt.p, lat, rng:NextNumber(4, 9), pt.r + 8)
			if haut then
				local h = haut.Position
				terrain:ReplaceMaterial(Region3.new(h - Vector3.new(3, 4, 3), h + Vector3.new(3, 4, 3)):ExpandToGrid(4), 4, ctx.matPart,
					Enum.Material.Basalt) -- coulée de roche mouillée, plus sombre
			end
		end
	end

	-- ===== 5. Champignons bioluminescents (au bord de l'eau et au pied des parois) =====
	local function champignons(p: Vector3, echelle: number, eclaire: boolean)
		if not modeles or opts.champignons == false then
			return
		end
		local cf = CFrame.new(p - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		local m = poser(decor, "^Champignon%d+$", cf, echelle, rng, COULEURS, "bas")
		if m and eclaire then
			local part = m:FindFirstChildWhichIsA("BasePart")
			if part then
				outils.lumiere(ctx, part, COULEURS.Lueur[1], 0.9, 12)
			end
		end
	end
	for _, b in bassins do
		for k = 1, rng:NextInteger(2, 4) do
			local a = rng:NextNumber(0, math.pi * 2)
			local sol = solSous(b[1] + Vector3.new(math.cos(a), 0, math.sin(a)) * (b[2] + rng:NextNumber(1, 3)))
			if sol then
				champignons(sol.Position, rng:NextNumber(0.9, 1.5), k == 1)
			end
		end
	end
	for _ = 1, 22 do
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local sol = solSous(pt.p + lat * pt.r * 0.8)
		if sol and loinDu(sol.Position, depart.p, 14) and solLibre(sol.Position, 3, 2.5) then
			champignons(sol.Position, rng:NextNumber(0.7, 1.3), rng:NextNumber() < 0.2)
		end
	end

	-- ===== 6. Racines qui pendent du plafond (bout lumineux pour certaines) =====
	for _ = 1, (if opts.racines == false then 0 else 26) do
		local pt = chemin[rng:NextInteger(1, #chemin)]
		local hit = lancer(pt.p + Vector3.new(rng:NextNumber(-4, 4), 2, rng:NextNumber(-4, 4)), Vector3.new(0, 60, 0))
		if hit and hit.Position.Y - pt.p.Y > 12 then
			local m = O.modele(decor, "Racine")
			local p = hit.Position + Vector3.new(0, 0.5, 0)
			local n = rng:NextInteger(4, 8)
			for k = 1, n do
				local l = rng:NextNumber(1.2, 2.2)
				local q = p + Vector3.new(rng:NextNumber(-0.4, 0.4), -l, rng:NextNumber(-0.4, 0.4))
				decorer(O.bloc(m, Vector3.new(0.28 - k * 0.02, l + 0.2, 0.28 - k * 0.02), CFrame.lookAt((p + q) / 2, q) * CFrame.Angles(math.pi / 2, 0, 0),
					Color3.fromRGB(78, 60, 44), M.Bois, "Racine"))
				p = q
			end
			if rng:NextNumber() < 0.4 then
				decorer(O.ellipsoide(m, Vector3.new(0.5, 0.5, 0.5), CFrame.new(p), COULEURS.Lueur[1], M.Neon, "BoutLumineux"))
			end
		end
	end

	-- ===== 7. Restes d'une ancienne mine : étais, rails, débris =====
	local principaux = {}
	for _, g in galeries do
		if g.principal then
			table.insert(principaux, g)
		end
	end
	if opts.mine == false then
		table.clear(principaux) -- thème sans restes de mine (lave, cœur maudit)
	end
	local bois = Color3.fromRGB(92, 66, 44)
	local boisSombre = Color3.fromRGB(62, 44, 30)
	local rouille = Color3.fromRGB(110, 70, 48)
	for _, g in principaux do
		for i, pt in g.pts do
			local loinDepart = loinDu(pt.p, depart.p, 22)
			local loinBoss = loinDu(pt.p, boss.p, boss.r or 20)
			-- étais : un cadre de bois tous les ~6 points, contre les parois
			if i % 5 == 2 and loinDepart and loinBoss then
				local lat = Vector3.new(-pt.t.Z, 0, pt.t.X)
				local g1, g2 = paroi(pt.p, lat, 3, pt.r + 12), paroi(pt.p, -lat, 3, pt.r + 12)
				local plafond = lancer(pt.p + Vector3.new(0, 2, 0), Vector3.new(0, 40, 0))
				if g1 and g2 and plafond then
					local h = math.min(plafond.Position.Y - pt.p.Y - 0.5, 15)
					local a, b = g1.Position + (pt.p - g1.Position).Unit * 1.2, g2.Position + (pt.p - g2.Position).Unit * 1.2
					if h > 8 and (a - b).Magnitude < 46 then
						local m = O.modele(decor, "Etai")
						for _, q in {a, b} do
							local sol = solSous(Vector3.new(q.X, pt.p.Y, q.Z))
							local y0 = if sol then sol.Position.Y else pt.p.Y
							decorer(O.bloc(m, Vector3.new(1.1, h, 1.1), CFrame.new(q.X, y0 + h / 2, q.Z) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), rng:NextNumber(-0.04, 0.04)),
								bois, M.Bois, "Poteau"))
						end
						local milieu = (a + b) / 2
						local dirP = (b - a)
						decorer(O.bloc(m, Vector3.new(1.2, 1.2, dirP.Magnitude + 1.5), CFrame.lookAt(Vector3.new(milieu.X, pt.p.Y + h, milieu.Z),
							Vector3.new(b.X, pt.p.Y + h, b.Z)), boisSombre, M.Bois, "Poutre"))
						if rng:NextNumber() < 0.5 then -- vieille lanterne éteinte accrochée à la poutre
							local haut = Vector3.new(milieu.X, pt.p.Y + h - 0.6, milieu.Z)
							decorer(O.bloc(m, Vector3.new(0.15, 1.2, 0.15), CFrame.new(haut - Vector3.new(0, 0.6, 0)), C.Fer, M.Rouille, "Chaine"))
							local cf = CFrame.new(haut - Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2))
							decorer(O.bloc(m, Vector3.new(0.9, 1.2, 0.9), cf, Color3.fromRGB(40, 36, 30), M.Verre, "LanterneEteinte")).Transparency = 0.35
							decorer(O.bloc(m, Vector3.new(1.1, 0.2, 1.1), cf * CFrame.new(0, 0.7, 0), rouille, M.Rouille, "Chapeau"))
							decorer(O.bloc(m, Vector3.new(1.1, 0.2, 1.1), cf * CFrame.new(0, -0.7, 0), rouille, M.Rouille, "Fond"))
						end
					end
				end
			end
			-- vieux rails le long de la galerie principale (quelques tronçons manquent)
			local suivant = g.pts[i + 1]
			if suivant and loinDepart and loinBoss and rng:NextNumber() > 0.15 then
				local s1, s2 = solSous(pt.p), solSous(suivant.p)
				if s1 and s2 and horsGisements(s1.Position, 4) and horsGisements(s2.Position, 4) then
					local a, b = s1.Position + Vector3.new(0, 0.15, 0), s2.Position + Vector3.new(0, 0.15, 0)
					local axe = CFrame.lookAt((a + b) / 2, b)
					local L = (b - a).Magnitude
					local m = O.modele(decor, "VieuxRails")
					for _, x in {-1.5, 1.5} do
						decorer(O.bloc(m, Vector3.new(0.3, 0.3, L + 0.2), axe * CFrame.new(x, 0.35, 0), rouille, M.Rouille, "Rail"))
					end
					for k = 0, 1 do
						decorer(O.bloc(m, Vector3.new(4.4, 0.3, 0.9), axe * CFrame.new(0, 0.05, -L / 2 + (k + 0.5) * L / 2) * CFrame.Angles(0, rng:NextNumber(-0.12, 0.12), 0),
							boisSombre, M.Planches, "Traverse"))
					end
				end
			end
		end
	end
	-- débris dans quelques salles : wagonnet renversé, caisses, tonneau, pioches abandonnées
	local nDebris = 0
	for _, s in salles do
		if nDebris >= 3 then
			break
		end
		if not s.depart and not s.boss then
			local a = rng:NextNumber(0, math.pi * 2)
			local sol = solSous(s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * 0.55)
			if sol and solLibre(sol.Position, 8, 5) then
				nDebris += 1
				local base = CFrame.new(sol.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				local wagon = B.wagonnet(decor, base * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(rng:NextInteger(70, 100))), nil, rng)
				if wagon then
					O.decorModele(wagon)
				end
				for k = 1, 3 do
					local c = B.caisse(decor, base * CFrame.new(5 + k * 2.2, 0, rng:NextNumber(-2, 2)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), 0))
					if c then
						O.decorModele(c)
					end
				end
				B.pioche(decor, base * CFrame.new(-4, 0.2, 2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), C.Fer)
				local t = B.tonneau(decor, base * CFrame.new(-6, 0, -2))
				if t then
					O.decorModele(t)
				end
			end
		end
	end

	if opts.torches ~= false then
	-- ===== 8. Balisage : torches le long du chemin principal vers le boss =====
	local derniere = depart.p
	local cote = 1
	for _, g in principaux do
		for _, pt in g.pts do
			if (pt.p - derniere).Magnitude > 38 and loinDu(pt.p, boss.p, 12) then
				local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * cote
				local hit = paroi(pt.p, lat, 6, pt.r + 8)
				if hit then
					outils.torche(ctx, hit)
					derniere = pt.p
					cote = -cote
				end
			end
		end
	end
	end

	if opts.poussieres ~= false then
	-- ===== 9. Poussières lumineuses qui flottent dans les salles =====
	for _, s in salles do
		local z = O.decor(O.bloc(decor, Vector3.new(s.r * 1.4, 12, s.r * 1.4), CFrame.new(s.p + Vector3.new(0, 7, 0)), Color3.new(), M.Lisse, "Poussieres"))
		z.Transparency = 1
		O.lucioles(z, lueur:Lerp(Color3.new(1, 1, 1), 0.5), 4)
	end
	end

	if opts.boss ~= false then
	-- ===== 10. Salle du boss : cristal géant, pierres dressées, ossements, brume, cercle de runes =====
	local centre = infos.salleBoss
	local rb = boss.r or 20
	-- mur du fond : plusieurs hauteurs / angles autour de l'axe d'arrivée, on garde le premier mur touché
	local axeBoss = (boss.p - (infos.avantBoss or depart.p)) * Vector3.new(1, 0, 1)
	axeBoss = if axeBoss.Magnitude > 1e-3 then axeBoss.Unit else Vector3.new(0, 0, -1)
	local hitFond = nil
	for _, h in {4, 8, 2, 12} do
		for _, da in {0, 0.35, -0.35, 0.7, -0.7, 1.1, -1.1} do
			hitFond = hitFond or paroi(boss.p, CFrame.Angles(0, da, 0):VectorToWorldSpace(axeBoss), h, rb * 2.2)
		end
	end
	if hitFond then
		if modeles then
			local n = hitFond.Normal
			local cf = outils.axeVers(hitFond.Position - n * 1.5 + Vector3.new(0, -1, 0), (n + Vector3.new(0, 1.2, 0)).Unit)
			local geant = table.clone(COULEURS)
			geant.Cristal = {lueur:Lerp(Color3.fromRGB(40, 60, 120), 0.45), M.Neon}
			local m = poser(decor, "^Cristal%d+$", cf, 3.4, rng, geant, "bas")
			local part = m and m:FindFirstChildWhichIsA("BasePart")
			if part then
				local l = Instance.new("PointLight")
				l.Color, l.Brightness, l.Range, l.Shadows = lueur, 1.1, 38, true
				l.Parent = part
			end
		else
			outils.cristaux(ctx, hitFond.Position, hitFond.Normal, 2.4)
		end
	end
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local sol = solSous(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * 0.82)
		if sol then
			local h = rng:NextNumber(6, 10)
			decorer(O.bloc(decor, Vector3.new(rng:NextNumber(2.2, 3.2), h, rng:NextNumber(1.6, 2.4)),
				CFrame.new(sol.Position + Vector3.new(0, h / 2 - 0.8, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), a, rng:NextNumber(-0.12, 0.12)),
				roche:Lerp(Color3.new(0, 0, 0), 0.25), ctx.matPart, "PierreDressee"))
			decorer(O.bloc(decor, Vector3.new(0.3, h * 0.5, 0.15), CFrame.new(sol.Position + Vector3.new(0, h * 0.55, 0)) * CFrame.Angles(0, a, 0)
				* CFrame.new(0, 0, -1.25), COULEURS.Lueur[1], M.Neon, "RunePierre"))
		end
	end
	for k = 1, 5 do
		local a = rng:NextNumber(0, math.pi * 2)
		local sol = solSous(centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * rng:NextNumber(0.4, 0.7))
		if sol then
			local m = O.modele(decor, "Ossements")
			local blanc = Color3.fromRGB(226, 218, 196)
			decorer(O.ellipsoide(m, Vector3.new(1, 0.9, 1.1), CFrame.new(sol.Position + Vector3.new(0, 0.4, 0)), blanc, M.Lisse, "Crane"))
			for _ = 1, 4 do
				decorer(O.bloc(m, Vector3.new(0.25, 0.25, rng:NextNumber(1.4, 2.4)), CFrame.new(sol.Position + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.15, rng:NextNumber(-1.5, 1.5)))
					* CFrame.Angles(0, rng:NextNumber(0, 3), 0), blanc, M.Lisse, "Os"))
			end
		end
	end
	local solCentre = solSous(centre)
	if solCentre then
		-- cercle de runes gravées : 24 glyphes posés chacun sur le sol (qui n'est pas plat), légèrement transparents
		for k = 0, 23 do
			local a = k / 24 * math.pi * 2
			local p = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * rb * 0.55
			local sol = solSous(p)
			if sol then
				local cf = CFrame.new(sol.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, -a, 0)
				local forme = k % 3
				for _, barre in {{0, 0, 1.6, 0}, {0.45, -0.3, 0.8, 0.6 + forme * 0.4}, {-0.45, 0.3, 0.8, -0.6 - forme * 0.3}} do
					local b = decorer(O.bloc(decor, Vector3.new(0.18, 0.05, barre[3]), cf * CFrame.new(barre[1], 0, barre[2]) * CFrame.Angles(0, barre[4], 0),
						COULEURS.Lueur[1], M.Neon, "CercleRunes"))
					b.Transparency = 0.25
				end
			end
		end
		local brume = O.decor(O.bloc(decor, Vector3.new(rb * 1.4, 3, rb * 1.4), CFrame.new(centre + Vector3.new(0, 1.5, 0)), Color3.new(), M.Lisse, "BrumeBoss"))
		brume.Transparency = 1
		O.brume(brume, lueur:Lerp(Color3.fromRGB(120, 40, 60), 0.4), 6)
	end
	end
end

GrotteDecor.poser = poser
GrotteDecor.gouttes = gouttes
GrotteDecor.decorerPart = decorer

return GrotteDecor
