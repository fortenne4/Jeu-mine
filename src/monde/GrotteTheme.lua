--[[ Boîte à outils commune aux thèmes de grottes (paliers 2 à 8 : GrotteMine, GrotteFonderie, GrotteLave,
	GrotteCoeur). Reprend les outils mis au point pour « Le Lac des Lueurs » (GrotteLueurs) :
	- rayons au sol / au plafond / vers les parois (terrain seul, l'eau ignorée)
	- décor tenu hors du passage (points de toutes les galeries) et hors des gisements
	- budget de lumières (ombres) et lumières de remplissage sans ombre (lisibilité : jamais de noir complet)
	- zones d'ambiance « GrotteZone » (teinte + rayon : AmbianceGrotte, SonsGrotte, mobs à thème)
	- veines néon qui serpentent sur la roche (s'illuminent au passage : GrotteReactive), galets lumineux
	- éclairage de base de toutes les salles et galeries, fil du guide (feux follets, boussole)

	local T = GrotteTheme.nouveau(ctx, infos, outils)
	T.zone(centre, rayon, teinte, "Puits") ; T.remplir(part, couleur, lum, portee) ; T.libre(p, marge) …
	T.eclairageBase({teinte = function(s) return couleur end, galerie = couleur, lum = 0.5})
	T.guide() -- dossier « Guide » (points du chemin principal + réseau des galeries) ]]

local O = require(script.Parent.Outils)
local M3 = require(script.Parent.Modeles3D)
local GD = require(script.Parent.GrotteDecor)
local M = O.M

local GrotteTheme = {}

local terrain = workspace.Terrain
GrotteTheme.TEX_LUEUR = "rbxasset://textures/particles/forcefield_glow_main.dds"
GrotteTheme.TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
GrotteTheme.TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
GrotteTheme.TEX_FEU = "rbxasset://textures/particles/fire_main.dds"

local MAX_LUMIERES = 48
local MAX_REMPLISSAGE = 70

function GrotteTheme.nouveau(ctx, infos, outils)
	local T = {}
	local rng = ctx.rng
	local decor = ctx.decor
	T.rng, T.decor, T.ctx, T.infos, T.outils = rng, decor, ctx, infos, outils
	T.depart, T.boss = infos.depart, infos.boss
	T.chemin, T.salles, T.galeries = infos.chemin, infos.lieux, infos.galeries
	T.rb = infos.boss.r or 30
	T.modeles = #M3.variantes("^Stalactite%d+$") > 0

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {terrain}
	params.IgnoreWater = true

	function T.trace(o: Vector3, d: Vector3)
		return workspace:Raycast(o, d, params)
	end
	function T.solEn(p: Vector3, haut: number?)
		local h = haut or 6
		local hit = T.trace(p + Vector3.new(0, h, 0), Vector3.new(0, -(h + 18), 0))
		if hit and hit.Normal.Y > 0.55 then
			return hit
		end
		return nil
	end
	function T.plafondEn(p: Vector3, max: number?)
		local hit = T.trace(p + Vector3.new(0, 1, 0), Vector3.new(0, max or 90, 0))
		if hit and hit.Normal.Y < -0.15 then
			return hit
		end
		return nil
	end
	function T.plat(v: Vector3): Vector3
		return Vector3.new(v.X, 0, v.Z)
	end
	function T.unite(v: Vector3, defaut: Vector3): Vector3
		return if v.Magnitude > 1e-3 then v.Unit else defaut
	end
	function T.kp(t, v, e)
		return NumberSequenceKeypoint.new(t, v, e or 0)
	end
	function T.volume(parent, taille: Vector3, cf: CFrame, nom: string): BasePart
		local p = O.decor(O.bloc(parent, taille, cf, Color3.new(), M.Lisse, nom))
		p.Transparency = 1
		p.CastShadow = false
		return p
	end
	function T.emetteur(parent, props)
		local e: any = Instance.new("ParticleEmitter")
		for cle, valeur in props do
			e[cle] = valeur
		end
		e.Parent = parent
		return e
	end
	-- pièce décorative (traversable, ignorée par la pioche)
	function T.bloc(parent, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		local p = O.decor(O.bloc(parent, taille, cf, couleur, mat, nom))
		return p
	end
	-- pièce sur laquelle on marche (ponts, plateformes) : solide, mais ignorée par la pioche
	function T.solide(parent, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		local p = O.bloc(parent, taille, cf, couleur, mat, nom)
		p.CanQuery = false
		return p
	end
	function T.cylindre(parent, hauteur: number, diametre: number, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		return O.decor(O.cylindre(parent, hauteur, diametre, cf, couleur, mat, nom))
	end
	-- disque / roue : l'axe suit l'axe X du CFrame (roue verticale si X est horizontal)
	function T.disque(parent, epaisseur: number, diametre: number, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		return O.decor(O.disque(parent, epaisseur, diametre, cf, couleur, mat, nom))
	end
	function T.boule(parent, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		return O.decor(O.ellipsoide(parent, taille, cf, couleur, mat, nom))
	end
	function T.coin(parent, taille: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material, nom: string): BasePart
		return O.decor(O.coin(parent, taille, cf, couleur, mat, nom))
	end
	function T.modele(nom: string, parent: Instance?): Model
		return O.modele(parent or decor, nom)
	end
	T.tag = O.tag
	T.M = M

	-- lumières (budget global partagé avec le générateur)
	function T.lumiere(part: Instance, couleur: Color3, lum: number, portee: number, genre: string?): Light?
		if ctx.lumieres >= MAX_LUMIERES then
			return nil
		end
		ctx.lumieres += 1
		local l: any = Instance.new(genre or "PointLight")
		l.Color, l.Brightness, l.Range = couleur, lum, math.min(portee, 60)
		l.Parent = part
		return l
	end
	local nRemplissage = 0
	function T.remplir(part: Instance, couleur: Color3, lum: number, portee: number)
		if nRemplissage >= MAX_REMPLISSAGE then
			return nil
		end
		nRemplissage += 1
		local l = Instance.new("PointLight")
		l.Name = "Remplissage"
		l.Color, l.Brightness, l.Range, l.Shadows = couleur, lum, math.min(portee, 60), false
		l.Parent = part
		return l
	end

	-- zones interdites au décor posé au sol (gisements, arrivée, puis ce que les thèmes ajoutent)
	local interdits = {}
	for _, g in infos.gisements or {} do
		table.insert(interdits, {centre = g.centre, rayon = (g.rayon or 8) * 0.7})
	end
	table.insert(interdits, {centre = T.depart.p, rayon = 20})
	T.interdits = interdits
	function T.interdire(centre: Vector3, rayon: number)
		table.insert(interdits, {centre = centre, rayon = rayon})
	end
	function T.libre(p: Vector3, marge: number): boolean
		for _, z in interdits do
			if math.abs(p.Y - z.centre.Y) < 14 and T.plat(p - z.centre).Magnitude < z.rayon + marge then
				return false
			end
		end
		return true
	end
	local ptsChemin = {}
	for _, g in T.galeries do
		for _, pt in g.pts do
			table.insert(ptsChemin, pt.p)
		end
	end
	T.ptsChemin = ptsChemin
	function T.surChemin(p: Vector3, marge: number): boolean
		for _, q in ptsChemin do
			if math.abs(p.Y - q.Y) < 12 and T.plat(p - q).Magnitude < marge then
				return true
			end
		end
		return false
	end
	-- sol libre pour un objet volumineux : hors gisements, hors passage
	function T.solLibre(p: Vector3, marge: number, passage: number): boolean
		return T.libre(p, marge) and not T.surChemin(p, passage)
	end

	function T.zone(centre: Vector3, rayon: number, teinte: Color3, nom: string)
		local z = T.volume(decor, Vector3.one, CFrame.new(centre), "Zone" .. nom)
		z:SetAttribute("Teinte", teinte)
		z:SetAttribute("Rayon", rayon)
		O.tag(z, "GrotteZone")
		return z
	end

	-- entrées de galerie d'une salle
	function T.entrees(s): {Vector3}
		local res = {}
		for _, g in T.galeries do
			for _, pt in g.pts do
				local d = T.plat(pt.p - s.p).Magnitude
				if d > s.r * 0.7 and d < s.r * 1.5 and math.abs(pt.p.Y - s.p.Y) < 12 then
					table.insert(res, pt.p)
				end
			end
		end
		return res
	end
	-- point de la salle à distance d du centre, le plus loin possible des entrées
	function T.coinSalle(s, d: number): (Vector3, Vector3)
		local es = T.entrees(s)
		local meilleur, score, dir = s.p, -1, Vector3.new(1, 0, 0)
		local a0 = rng:NextNumber(0, math.pi * 2)
		for k = 0, 11 do
			local a = a0 + k * math.pi / 6
			local u = Vector3.new(math.cos(a), 0, math.sin(a))
			local c = s.p + u * d
			local m = math.huge
			for _, e in es do
				m = math.min(m, T.plat(c - e).Magnitude)
			end
			if m > score then
				meilleur, score, dir = c, m, u
			end
		end
		return meilleur, dir
	end
	-- direction d'une galerie qui entre dans la salle s (une par galerie)
	function T.directionsGaleries(s, rayon: number): {Vector3}
		local dirs = {}
		for _, g in T.galeries do
			local pts = g.pts
			if #pts > 1 then
				local liste = nil
				if T.plat(pts[1].p - s.p).Magnitude < 4 then
					liste = pts
				elseif T.plat(pts[#pts].p - s.p).Magnitude < 4 then
					liste = {}
					for i = #pts, 1, -1 do
						table.insert(liste, pts[i])
					end
				end
				if liste then
					for _, pt in liste do
						if T.plat(pt.p - s.p).Magnitude > rayon then
							local u = T.unite(T.plat(pt.p - s.p), Vector3.xAxis)
							local doublon = false
							for _, d in dirs do
								if d:Dot(u) > 0.9 then
									doublon = true
								end
							end
							if not doublon then
								table.insert(dirs, u)
							end
							break
						end
					end
				end
			end
		end
		return dirs
	end

	-- décor générique (stalactites, colonnes, racines, restes de mine) avec la palette du thème
	function T.decorGenerique(opts)
		GD.decorer(ctx, {
			depart = T.depart, boss = T.boss, chemin = T.chemin, lieux = T.salles, galeries = T.galeries,
			gisements = infos.gisements, interdits = interdits, surChemin = T.surChemin, salleBoss = infos.salleBoss,
			avantBoss = infos.avantBoss,
		}, outils, opts)
	end
	function T.poserModele(motif: string, cf: CFrame, k: number, couleurs, yBase: string?)
		return GD.poser(decor, motif, cf, k, rng, couleurs, yBase or "bas")
	end

	-- veine néon qui serpente sur la paroi depuis hit (nom « Veine » : s'illumine au passage)
	local function veine(hit, longueur: number, couleur: Color3, epaisseur: number, profondeur: number)
		local pos, n = hit.Position, hit.Normal
		local haut = T.unite(Vector3.yAxis - n * n.Y, Vector3.yAxis)
		local cote = n:Cross(haut).Unit
		local dir = (haut * rng:NextNumber(0.6, 1) + cote * rng:NextNumber(-0.8, 0.8)).Unit
		local premier = nil
		for _ = 1, longueur do
			local pas = rng:NextNumber(1.6, 3)
			dir = (dir + cote * rng:NextNumber(-0.55, 0.55) + haut * 0.15).Unit
			local vise = pos + dir * pas
			local recolle = T.trace(vise + n * 2.5, -n * 5)
			if not recolle then
				break
			end
			local suivant = recolle.Position + recolle.Normal * 0.08
			local seg = suivant - pos
			if seg.Magnitude < 0.3 or math.abs(seg.Unit:Dot(recolle.Normal)) > 0.95 then
				break
			end
			local p = T.bloc(decor, Vector3.new(epaisseur, epaisseur * 0.5, seg.Magnitude + epaisseur * 0.6),
				CFrame.lookAt(pos + seg / 2, suivant, recolle.Normal), couleur, M.Neon, "Veine")
			p.CastShadow = false
			premier = premier or p
			if profondeur > 0 and rng:NextNumber() < 0.28 then
				veine(recolle, math.max(2, math.floor(longueur / 2)), couleur, epaisseur * 0.65, profondeur - 1)
			end
			pos, n = suivant, recolle.Normal
			haut = T.unite(Vector3.yAxis - n * n.Y, Vector3.yAxis)
			cote = T.unite(n:Cross(haut), cote)
			epaisseur = math.max(0.12, epaisseur * 0.94)
		end
		if premier and rng:NextNumber() < 0.5 then
			O.tag(premier, "GrottePulse")
		end
		return premier
	end
	T.veine = veine

	-- veines aux parois des salles et des galeries, galets lumineux au pied des parois
	function T.veinesEtGalets(couleurs: {Color3}, nSalle: number?, galets: Color3?)
		local n = 0
		for _, s in T.salles do
			if not s.depart then
				for _ = 1, nSalle or 4 do
					local a = rng:NextNumber(0, 2 * math.pi)
					local hit = outils.paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(1, 7), s.r * 1.7)
					if hit and math.abs(hit.Normal.Y) < 0.6 then
						veine(hit, rng:NextInteger(6, 12), couleurs[rng:NextInteger(1, #couleurs)], rng:NextNumber(0.3, 0.5), 2)
						n += 1
					end
				end
			end
		end
		for _, g in T.galeries do
			for i, pt in g.pts do
				if i % 4 == 0 and rng:NextNumber() < 0.6 then
					local cote = if rng:NextNumber() < 0.5 then 1 else -1
					local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * cote
					local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 6), pt.r + 8)
					if hit and (hit.Position - T.depart.p).Magnitude > 16 and math.abs(hit.Normal.Y) < 0.6 then
						veine(hit, rng:NextInteger(4, 8), couleurs[rng:NextInteger(1, #couleurs)], rng:NextNumber(0.25, 0.4), 1)
						n += 1
					end
					if galets and rng:NextNumber() < 0.5 then
						local sol = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.78, 0.92))
						if sol and T.libre(sol.Position, 1) then
							for _ = 1, rng:NextInteger(2, 4) do
								local d = rng:NextNumber(0.35, 0.8)
								local q = sol.Position + Vector3.new(rng:NextNumber(-1.2, 1.2), d * 0.25, rng:NextNumber(-1.2, 1.2))
								T.boule(decor, Vector3.new(d, d * 0.6, d), CFrame.new(q), galets, M.Neon, "GaletLueur").CastShadow = false
							end
						end
					end
				end
			end
		end
		return n
	end

	-- éclairage de base : un « soleil » doux sous la voûte de chaque salle, relais aux bords, galeries tous
	-- les 22 studs (sans ombre). opts = {teinte = fn(s) -> Color3, galerie = Color3, lum = number?}
	function T.eclairageBase(opts)
		for _, s in T.salles do
			local sol = T.solEn(s.p + Vector3.new(0, 4, 0), 10)
			local y0 = if sol then sol.Position.Y else s.p.Y
			local haut = T.plafondEn(Vector3.new(s.p.X, y0 + 2, s.p.Z), 90)
			local yL = if haut then math.min(haut.Position.Y - 3, y0 + 22) else y0 + 14
			local c = opts.teinte(s)
			local coeur = T.volume(decor, Vector3.one, CFrame.new(s.p.X, yL, s.p.Z), "Voute")
			local lum = (opts.lum or 0.55) * (if s.boss then 0.6 elseif s.depart then 0.5 else 1)
			T.remplir(coeur, c, lum, math.min(60, s.r * 1.6 + 14))
			local relais = if s.r >= 24 then 3 elseif s.r >= 17 then 2 else 0
			local a0 = rng:NextNumber(0, math.pi * 2)
			for k = 1, relais do
				local a = a0 + k * 2 * math.pi / relais
				local p = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * 0.62
				local sp = T.solEn(p + Vector3.new(0, 4, 0), 10)
				if sp then
					local r = T.volume(decor, Vector3.one, CFrame.new(sp.Position + Vector3.new(0, 9, 0)), "VouteRelais")
					T.remplir(r, c, lum * 0.65, 34)
				end
			end
		end
		for _, g in T.galeries do
			local dernier = nil
			for _, pt in g.pts do
				if not dernier or (pt.p - dernier).Magnitude > 22 then
					dernier = pt.p
					local haut = T.plafondEn(pt.p + Vector3.new(0, 2, 0), 40)
					local y = if haut then math.min(haut.Position.Y - 2.5, pt.p.Y + 9) else pt.p.Y + 8
					local r = T.volume(decor, Vector3.one, CFrame.new(pt.p.X, y, pt.p.Z), "GalerieLueur")
					T.remplir(r, opts.galerie, (opts.lum or 0.55) * (if g.principal then 0.72 else 0.58), 32)
				end
			end
		end
	end

	-- fil du guide (FeuxFollets) et réseau des galeries (BoussoleFeux)
	function T.guide()
		local guide = Instance.new("Folder")
		guide.Name = "Guide"
		local nPts = 0
		for _, g in T.galeries do
			if g.principal then
				for _, pt in g.pts do
					nPts += 1
					guide:SetAttribute("P" .. nPts, pt.p)
				end
			end
		end
		guide:SetAttribute("N", nPts)
		guide:SetAttribute("Boss", T.boss.p)
		local nR = 0
		for _, g in T.galeries do
			nR += 1
			guide:SetAttribute("R" .. nR .. "N", #g.pts)
			for i, pt in g.pts do
				guide:SetAttribute("R" .. nR .. "_" .. i, pt.p)
			end
		end
		guide:SetAttribute("R", nR)
		guide.Parent = ctx.modele
		return guide
	end

	-- Fosse circulaire au centre de la salle s (gouffre, lac de lave…), pilier central au niveau du sol, et un
	-- pont par galerie qui arrive dans la salle (opts.pont(dir, d0, d1, yPilier, yBerge) construit le pont).
	-- Sous le niveau du sol : zone « ZoneChute » (DangersGrotte.server ramène au bord ce qui tombe).
	-- opts = {profondeur, pilier, rayonMax?, pont, chute = true/false}
	-- place disponible pour une fosse au centre de la salle s (rayon), compte tenu des gisements et de l'arrivée
	function T.rayonFosse(s, rayonMax: number?): number
		local f = math.min(rayonMax or 99, s.r * 0.72)
		for _, g in infos.gisements or {} do
			if math.abs(s.p.Y - g.centre.Y) < 14 then
				f = math.min(f, T.plat(s.p - g.centre).Magnitude - 8)
			end
		end
		return math.min(f, T.plat(s.p - T.depart.p).Magnitude - 30)
	end
	-- parmi des salles, celle qui laisse la plus grande fosse (nil si aucune n'a au moins 10 studs)
	function T.salleFosse(liste, rayonMax: number?)
		local meilleure, fMax = nil, 10
		for _, s in liste do
			local f = T.rayonFosse(s, rayonMax)
			if f >= fMax then
				meilleure, fMax = s, f
			end
		end
		return meilleure
	end
	function T.fosse(s, opts)
		local f = T.rayonFosse(s, opts.rayonMax)
		if f < 10 then
			ctx.modele:SetAttribute("FosseRefusee", "place " .. math.floor(f))
			return nil
		end
		local sol = T.solEn(s.p, 10)
		if not sol then
			return nil
		end
		local y0 = sol.Position.Y
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local prof = opts.profondeur or 30
		-- jamais plus bas que le fond du bloc de roche de la grotte
		local centreBoite, demi = ctx.modele:GetAttribute("Centre"), ctx.modele:GetAttribute("DemiTaille")
		if typeof(centreBoite) == "Vector3" and typeof(demi) == "Vector3" then
			prof = math.min(prof, y0 - (centreBoite.Y - demi.Y) - 8)
		end
		if prof < 4 then
			ctx.modele:SetAttribute("FosseRefusee", "profondeur " .. math.floor(prof))
			return nil
		end
		terrain:FillCylinder(CFrame.new(c.X, y0 - prof / 2 + 0.5, c.Z), prof + 1, f, Enum.Material.Air)
		-- bords irréguliers : quelques bouchées en plus dans la paroi de la fosse
		for _ = 1, 8 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local q = c + Vector3.new(math.cos(a), 0, math.sin(a)) * f
			terrain:FillBall(q - Vector3.new(0, rng:NextNumber(3, 8), 0), rng:NextNumber(3, 5), Enum.Material.Air)
		end
		local rp = opts.pilier or 5.5
		local function pilier()
			terrain:FillCylinder(CFrame.new(c.X, y0 - prof / 2 - 1, c.Z), prof + 2, rp, ctx.matPart)
		end
		pilier()
		-- PLATEFORME au sommet du pilier : un vrai palier construit (dalle ronde, bordure, poteaux), au niveau
		-- exact des ponts. On vide la roche au-dessus pour qu'aucun bout de terrain lissé ne dépasse.
		local rPlat = rp + 2.5
		terrain:FillCylinder(CFrame.new(c.X, y0 + 6.3, c.Z), 12, rPlat + 1.5, Enum.Material.Air)
		local palier = T.modele("Plateforme")
		local dalle = O.cylindre(palier, 1.4, rPlat * 2, CFrame.new(c.X, y0 + 0.3 - 0.7, c.Z), opts.couleurDalle or Color3.fromRGB(78, 72, 70),
			opts.materiauDalle or Enum.Material.Slate, "Dalle")
		dalle.CanQuery = false
		local dirs = T.directionsGaleries(s, f + 3)
		-- bordure basse et poteaux tout autour, sauf là où arrivent les ponts
		local nBord = 16
		for k = 0, nBord - 1 do
			local a = k / nBord * 2 * math.pi
			local v = Vector3.new(math.cos(a), 0, math.sin(a))
			local libre = true
			for _, u in dirs do
				if v:Dot(u) > 0.88 then libre = false end
			end
			if libre then
				local q = c + v * (rPlat - 0.35)
				local cf = CFrame.lookAt(Vector3.new(q.X, y0 + 0.55, q.Z), Vector3.new(c.X, y0 + 0.55, c.Z))
				T.bloc(palier, Vector3.new(rPlat * 2 * math.pi / nBord + 0.1, 0.5, 0.6), cf, opts.couleurBord or Color3.fromRGB(58, 54, 54), Enum.Material.Slate, "Bordure")
				if k % 2 == 0 then
					T.bloc(palier, Vector3.new(0.5, 3, 0.5), cf * CFrame.new(0, 1.25, 0), opts.couleurPoteau or Color3.fromRGB(70, 70, 78), Enum.Material.Metal, "Poteau")
				end
			end
		end
		-- colonne visible sous la dalle (le pilier ne s'arrête plus en rocher informe)
		local col = O.cylindre(palier, 6, rp * 2 + 0.6, CFrame.new(c.X, y0 - 3.6, c.Z), opts.couleurDalle or Color3.fromRGB(78, 72, 70), Enum.Material.Slate, "Colonne")
		col.CanQuery = false
		for _, u in dirs do
			-- berge : on cherche le sol plus loin si le bord de la fosse est irrégulier, pour que le pont y repose
			local d1, yB = f + 2.5, nil
			for _, d in {f + 3.5, f + 5.5, f + 8} do
				local berge = T.solEn(c + u * d, 6)
				if berge and math.abs(berge.Position.Y - y0) < 10 then
					d1, yB = d - 1, berge.Position.Y
					break
				end
			end
			opts.pont(u, rPlat - 0.6, d1, y0, yB or y0)
			-- appuis : une poutre sous chaque extrémité du pont
			for _, e in {{rPlat - 0.6, y0}, {d1, yB or y0}} do
				local q = c + u * e[1]
				T.bloc(palier, Vector3.new(4.8, 0.6, 0.8), CFrame.lookAt(Vector3.new(q.X, e[2] - 0.25, q.Z), Vector3.new(q.X, e[2] - 0.25, q.Z) + u),
					opts.couleurPoteau or Color3.fromRGB(70, 70, 78), Enum.Material.Metal, "Appui")
			end
		end
		T.interdire(c, f + 3)
		if opts.chute ~= false and dirs[1] then
			local z = T.volume(decor, Vector3.one, CFrame.new(c), "ZoneChute")
			z:SetAttribute("Rayon", f + 1)
			z:SetAttribute("YMin", y0 - (opts.chuteProfondeur or 6))
			local retour = T.solEn(c + dirs[1] * (f + 5), 6)
			z:SetAttribute("Retour", if retour then retour.Position + Vector3.new(0, 3, 0) else c + Vector3.new(0, 4, 0))
			O.tag(z, "ZoneChute")
		end
		return {c = c, f = f, prof = prof, fond = y0 - prof, dirs = dirs, pilier = rp, refaire = pilier}
	end

	-- pont de planches entre d0 et d1 le long de u depuis le centre c (hauteurs yA → yB), garde-corps en chaîne
	function T.pontPlanches(c: Vector3, u: Vector3, d0: number, d1: number, yA: number, yB: number, couleurs)
		local cote = Vector3.new(-u.Z, 0, u.X)
		local function pos(d: number): Vector3
			local t = (d - d0) / (d1 - d0)
			local q = c + u * d
			return Vector3.new(q.X, yA + 0.15 + (yB - yA) * t, q.Z)
		end
		local pente = math.atan2(yB - yA, d1 - d0)
		local m = T.modele("Pont")
		local k, d = 0, d0
		while d <= d1 do
			k += 1
			local q = pos(d)
			T.solide(m, Vector3.new(4.4, 0.3, 0.95), CFrame.lookAt(q, q + u) * CFrame.Angles(pente, 0, rng:NextNumber(-0.03, 0.03)),
				if k % 2 == 0 then couleurs.planche else couleurs.planche2, couleurs.materiau or M.Bois, "Planche")
			d += 1.05
		end
		local a, b = pos(d0), pos(d1)
		for _, sx in {-1, 1} do
			local off = cote * 2.15 * sx
			for _, q in {a, b} do
				T.bloc(m, Vector3.new(0.5, 3.2, 0.5), CFrame.new(q + off + Vector3.new(0, 1.4, 0)), couleurs.poteau, couleurs.materiauPoteau or M.Bois, "Poteau")
			end
			-- garde-corps : deux chaînes qui pendent légèrement
			for _, h in {2.6, 1.6} do
				local milieu = (a + b) / 2 + off + Vector3.new(0, h - 0.5, 0)
				for _, extr in {a, b} do
					local p1 = extr + off + Vector3.new(0, h, 0)
					local seg = T.bloc(m, Vector3.new(0.18, 0.18, (milieu - p1).Magnitude), CFrame.lookAt((p1 + milieu) / 2, milieu), couleurs.chaine, M.Metal, "Chaine")
					seg.CastShadow = false
				end
			end
		end
		return m
	end

	-- poussières / braises / cendres qui flottent dans une salle
	function T.particulesSalle(s, props)
		local sol = T.solEn(s.p + Vector3.new(0, 4, 0), 10)
		local y = if sol then sol.Position.Y else s.p.Y
		local v = T.volume(decor, Vector3.new(s.r * 1.6, 14, s.r * 1.6), CFrame.new(s.p.X, y + 8, s.p.Z), "Particules")
		local base = {Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, LightInfluence = 0}
		for k, val in props do
			base[k] = val
		end
		return T.emetteur(v, base)
	end

	return T
end

return GrotteTheme
