-- Grottes profondes : génération d'une grotte aléatoire (Terrain) pour une expédition à 1 ou 2 joueurs.
-- Bloc de roche (matériau du palier) creusé par des galeries sinueuses : salle de départ (cercle de sortie,
-- panneau), 3 à 5 salles larges, une salle finale (boss) au bout, culs-de-sac et boucles.
-- Sol plat (galettes de roche sous chaque boule d'air), pentes ≤ ~17°, plafond ≥ 13 studs.
-- Minerais : même rocher que MinePrivee (Partage › MineraisModeles), collés aux parois / au sol.
-- Décor (cristaux néon, torches, stalactites / stalagmites) : O.decor, lumières plafonnées (MAX_LUMIERES).
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local Grottes = require(Partage:WaitForChild("Grottes"))
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local Cercle = require(script.Parent.CercleLumineux)
local M, C = O.M, O.C

local Generateur = {}

local terrain = workspace.Terrain
local AIR = Enum.Material.Air
local TAILLE_BOITE = Vector3.new(240, 80, 240) -- bloc de roche (repère : base = sol ≈ 0)
local CENTRE_BOITE = Vector3.new(0, 15, 0)     -- y de -25 à +55
local LIMITE = 98                              -- |x|, |z| max d'un point de galerie (parois ≥ 12 studs)
local Y_MIN, Y_MAX = -5, 10                    -- sols des salles
local PAS = 3.5                                -- espacement des boules d'air le long d'une galerie
local MAX_LUMIERES = 24
local MAX_MINERAIS = 70
local DISTANCE_MOBS = 45
local FLAMME = Color3.fromRGB(255, 170, 80)

local noeuds = {} -- [cœur] = modèle du rocher (toutes grottes confondues)
local dossier

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
local function lancer(origine, direction)
	return workspace:Raycast(origine, direction, params)
end

local function melanger(t, rng)
	for i = #t, 2, -1 do
		local j = rng:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

local function plat(v)
	return Vector3.new(v.X, 0, v.Z)
end

function Generateur.emplacement(index)
	local col = (index - 1) % D.GROTTES_COLONNES
	local rang = (index - 1) // D.GROTTES_COLONNES
	return D.GROTTES_ORIGINE + Vector3.new(-col * D.GROTTES_ECART, 0, rang * D.GROTTES_ECART)
end

-- ================= Plan (salles + galeries) =================

local function borne(base, p)
	local l = p - base
	return base + Vector3.new(math.clamp(l.X, -LIMITE, LIMITE), math.clamp(l.Y, Y_MIN - 1, Y_MAX + 2), math.clamp(l.Z, -LIMITE, LIMITE))
end

-- Distance horizontale du point p au segment [a, b]
local function distanceSegment(p, a, b)
	local ab, ap = plat(b - a), plat(p - a)
	local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (ap - ab * t).Magnitude
end

-- Le segment a → b ne traverse aucune autre salle (sinon sols à des hauteurs différentes qui se coupent)
local function libre(salles, a, b, sa, sb)
	for _, s in salles do
		if s ~= sa and s ~= sb and distanceSegment(s.p, a, b) < s.r + 20 then return false end
	end
	return true
end

-- Hauteur de sol d'une salle reliée à une autre : pente bornée par l'écart entre leurs bords
local function hauteurVers(base, ya, ecart, rng)
	local dy = rng:NextNumber(-1, 1) * math.min(6, 0.2 * math.max(ecart, 0))
	return math.clamp(ya + dy - base.Y, Y_MIN, Y_MAX) + base.Y
end

local function ecartEntre(a, b, ra, rb)
	return plat(b - a).Magnitude - 0.8 * (ra + rb)
end

-- Galerie sinueuse de a à b (sols) : plate dans les salles, pente douce (smoothstep) entre les deux
local function trace(base, a, b, ra, rb, r, rng)
	local L = plat(b - a).Magnitude
	if L < 2 then return nil end
	local avant = plat(b - a).Unit
	local cote = Vector3.new(-avant.Z, 0, avant.X)
	local amp = rng:NextNumber(5, 14) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local amp2 = rng:NextNumber(1, 3.5)
	local ondes = rng:NextInteger(1, 2)
	local phase = rng:NextNumber(0, math.pi)
	local debut, fin = ra * 0.8, L - rb * 0.8
	local n = math.max(2, math.ceil(L * 1.3 / PAS))
	local pts = {}
	for i = 0, n do
		local t = i / n
		local s = t * L
		local u = if fin > debut then math.clamp((s - debut) / (fin - debut), 0, 1) else t
		u = u * u * (3 - 2 * u)
		local decal = math.sin(t * math.pi) * (amp * math.sin(t * math.pi * ondes + phase) + amp2 * math.sin(t * math.pi * 5 + phase * 2))
		local p = a + avant * s + cote * decal
		table.insert(pts, {p = borne(base, Vector3.new(p.X, a.Y + (b.Y - a.Y) * u, p.Z)), r = r})
	end
	local longueur = 0
	for i, pt in pts do
		local av, ap = pts[math.max(1, i - 1)].p, pts[math.min(#pts, i + 1)].p
		local t = plat(ap - av)
		pt.t = if t.Magnitude > 1e-3 then t.Unit else avant
		if i > 1 then longueur += (pt.p - pts[i - 1].p).Magnitude end
	end
	return {pts = pts, r = r, longueur = longueur}
end

local function planifier(base, rng)
	local depart = {p = base + Vector3.new(0, 0, 80), r = 16, depart = true}
	local salles = {depart}
	local liens = {} -- {sa, sb}
	-- Chaîne principale : départ → 2-3 salles (alternées gauche / droite) → boss au fond (-Z)
	local nChaine = rng:NextInteger(2, 3)
	local prec = depart
	local signe = if rng:NextNumber() < 0.5 then -1 else 1
	for i = 1, nChaine + 1 do
		local boss = i == nChaine + 1
		local r = if boss then 20 else rng:NextNumber(14, 18)
		local x = if boss then rng:NextNumber(-40, 40) else signe * rng:NextNumber(22, LIMITE - r - 6)
		local z = if boss then -82 else 80 - 162 * i / (nChaine + 1) + rng:NextNumber(-6, 6)
		local p = base + Vector3.new(x, 0, z)
		local y = hauteurVers(base, prec.p.Y, ecartEntre(prec.p, p, prec.r, r), rng)
		local s = {p = Vector3.new(p.X, y, p.Z), r = r, boss = boss}
		table.insert(salles, s)
		table.insert(liens, {prec, s})
		prec = s
		signe = -signe
	end
	local boss = prec
	local distBoss = plat(boss.p - depart.p).Magnitude
	-- Salles annexes (3 à 5 salles larges en tout hors départ / boss), reliées à la salle la plus proche
	local nSalles = rng:NextInteger(3, 5)
	for _ = 1, 40 do
		if #salles - 2 >= nSalles then break end
		local r = rng:NextNumber(14, 20)
		local p = base + Vector3.new(rng:NextNumber(-(LIMITE - r), LIMITE - r), 0, rng:NextNumber(-70, 60))
		local ok = plat(p - depart.p).Magnitude < distBoss - 10
		local proche, dProche = nil, math.huge
		for _, s in salles do
			local d = plat(p - s.p).Magnitude
			if d < s.r + r + 18 then ok = false; break end
			if not s.depart and not s.boss and d < dProche then proche, dProche = s, d end
		end
		if ok and proche and libre(salles, proche.p, p, proche, nil) then
			local y = hauteurVers(base, proche.p.Y, ecartEntre(proche.p, p, proche.r, r), rng)
			local s = {p = Vector3.new(p.X, y, p.Z), r = r}
			table.insert(salles, s)
			table.insert(liens, {proche, s})
		end
	end
	-- Boucles et culs-de-sac jusqu'à 6-9 galeries
	local cible = rng:NextInteger(6, 9)
	local alcoves = {}
	local function relie(a, b)
		for _, l in liens do
			if (l[1] == a and l[2] == b) or (l[1] == b and l[2] == a) then return true end
		end
		return false
	end
	for _ = 1, 40 do
		if #liens >= cible then break end
		if rng:NextNumber() < 0.5 then
			local a, b = salles[rng:NextInteger(2, #salles)], salles[rng:NextInteger(2, #salles)]
			local d = plat(b.p - a.p).Magnitude
			local ecart = ecartEntre(a.p, b.p, a.r, b.r)
			if a ~= b and not relie(a, b) and d < 140 and ecart > 8 and math.abs(a.p.Y - b.p.Y) <= 0.2 * ecart
				and libre(salles, a.p, b.p, a, b) then
				table.insert(liens, {a, b})
			end
		else
			local a = salles[rng:NextInteger(2, #salles)]
			local angle = rng:NextNumber(0, 2 * math.pi)
			local longueur = rng:NextNumber(30, 55)
			local fin = borne(base, a.p + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (a.r * 0.8 + longueur))
			local ecart = ecartEntre(a.p, fin, a.r, 9)
			local ok = ecart > 15 and libre(salles, a.p, fin, a, nil)
			for _, s in salles do
				if s ~= a and plat(fin - s.p).Magnitude < s.r + 18 then ok = false end
			end
			if ok then
				local y = hauteurVers(base, a.p.Y, ecart, rng)
				local s = {p = Vector3.new(fin.X, y, fin.Z), r = 9, alcove = true}
				table.insert(alcoves, s)
				table.insert(liens, {a, s})
			end
		end
	end
	return salles, liens, alcoves, depart, boss
end

-- ================= Creusement (Terrain) =================

local function creuserSalle(s, roche, rng)
	local r = s.r
	terrain:FillBall(s.p + Vector3.new(0, r * 0.4, 0), r, AIR)
	for _ = 1, 3 do
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(0.3, 0.5) * r
		terrain:FillBall(s.p + Vector3.new(math.cos(a) * d, r * 0.45, math.sin(a) * d), r * 0.6, AIR)
	end
	local h = r * 0.6 + 2
	terrain:FillCylinder(CFrame.new(s.p - Vector3.new(0, h / 2, 0)), h, r * 1.15, roche)
end

-- Boules d'air (deux, l'une au-dessus de l'autre : plafond ≥ 13) puis galette de roche jusqu'au sol
local function creuserGalerie(g, roche)
	for _, pt in g.pts do
		local r = pt.r
		terrain:FillBall(pt.p + Vector3.new(0, r * 0.5, 0), r, AIR)
		terrain:FillBall(pt.p + Vector3.new(0, r * 0.5 + 5, 0), r * 0.9, AIR)
		local h = r * 0.5 + 1.5
		terrain:FillCylinder(CFrame.new(pt.p - Vector3.new(0, h / 2, 0)), h, r, roche)
	end
end

-- ================= Décor =================

local function lumiere(ctx, part, couleur, luminosite, portee)
	if ctx.lumieres >= MAX_LUMIERES then return end
	ctx.lumieres += 1
	O.lumiere(part, couleur, luminosite, portee)
end

-- Paroi touchée en partant de p (hauteur h) dans la direction dir (horizontale)
local function paroi(p, dir, h, portee)
	local hit = lancer(p + Vector3.new(0, h, 0), dir * portee)
	if hit and math.abs(hit.Normal.Y) < 0.7 then return hit end
	return nil
end

local function solSous(p)
	local hit = lancer(p + Vector3.new(0, 5, 0), Vector3.new(0, -14, 0))
	if hit and hit.Normal.Y > 0.82 then return hit end
	return nil
end

local function axeVers(pos, dir)
	local haut = if math.abs(dir.Y) > 0.95 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt(pos, pos + dir, haut) * CFrame.Angles(-math.pi / 2, 0, 0) -- Y = dir
end

-- Amas de cristaux lumineux (néon + verre) sortant de la paroi
local function cristaux(ctx, pos, normale, echelle)
	local rng, couleur = ctx.rng, ctx.niveau.ambiance.lumiere
	local premier
	for i = 1, rng:NextInteger(3, 5) do
		local dir = (normale + Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.3, 0.6), rng:NextNumber(-0.5, 0.5))).Unit
		local w, h = rng:NextNumber(0.5, 0.9) * echelle, rng:NextNumber(1.5, 3.8) * echelle
		local depart = pos + Vector3.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.6, 0.6)) * echelle
		local cf = axeVers(depart, dir) * CFrame.new(0, h / 2 - 0.4, 0) * CFrame.Angles(0, math.rad(45), 0)
		local p = O.decor(O.bloc(ctx.decor, Vector3.new(w, h, w), cf, couleur, if i % 2 == 0 then M.Verre else M.Neon, "Cristal"))
		if p.Material == M.Verre then p.Transparency = 0.25 end
		premier = premier or p
	end
	if premier then lumiere(ctx, premier, couleur, 1.2, 18 * echelle) end
end

-- Pointe en 3 étages (stalactite : sens = -1, stalagmite : sens = 1)
local function pointe(ctx, pos, sens, echelle)
	local rng = ctx.rng
	local couleur = ctx.niveau.ambiance.roche
	local y = -0.4 * sens
	for k, t in {{1.8, 1.6}, {1.2, 1.8}, {0.6, 2}} do
		local w, h = t[1] * echelle, t[2] * echelle
		y += sens * h / 2
		local cf = CFrame.new(pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		O.decor(O.bloc(ctx.decor, Vector3.new(w, h, w), cf, couleur:Lerp(Color3.new(), 0.1 * k), ctx.matPart, if sens < 0 then "Stalactite" else "Stalagmite"))
		y += sens * h / 2
	end
end

local function torche(ctx, hit)
	local n = plat(hit.Normal)
	if n.Magnitude < 1e-3 then return end
	n = n.Unit
	local tige = CFrame.lookAt(hit.Position + n * 0.3, hit.Position + n * 2) * CFrame.Angles(math.rad(-22), 0, 0)
	O.decor(O.bloc(ctx.decor, Vector3.new(0.35, 1.6, 0.35), tige, C.Bois, M.Bois, "Torche"))
	local flamme = O.decor(O.bloc(ctx.decor, Vector3.new(0.5, 0.5, 0.5), tige * CFrame.new(0, 0.95, 0), FLAMME, M.Neon, "Flamme"))
	lumiere(ctx, flamme, FLAMME, 1.5, 20)
	O.etincelles(flamme, FLAMME, 2)
end

local function panneau(ctx, depart)
	local hit = solSous(depart.p + Vector3.new(-8, 0, 3))
	if not hit then return end
	local pied = hit.Position
	local face = CFrame.lookAt(pied, Vector3.new(depart.p.X, pied.Y, depart.p.Z))
	O.decor(O.bloc(ctx.decor, Vector3.new(0.5, 4.6, 0.5), face * CFrame.new(0, 2.3, 0.3), C.Bois, M.Bois, "Poteau"))
	local planche = O.decor(O.bloc(ctx.decor, Vector3.new(8, 2, 0.3), face * CFrame.new(0, 4.2, 0), C.Bois, M.Planches, "Panneau"))
	O.texte(planche, Enum.NormalId.Front, "−" .. ctx.niveau.profondeur .. " m · " .. ctx.niveau.nom)
end

-- ================= Minerais =================

-- Rocher cassé par la pioche (PiocheBraise retire le tag « Minerai » à PV 0 et pose « Casse ») : il s'efface
CollectionService:GetInstanceRemovedSignal("Minerai"):Connect(function(coeur)
	local modele = noeuds[coeur]
	if not modele then return end
	noeuds[coeur] = nil
	if not modele.Parent or not coeur:GetAttribute("Casse") then return end
	for _, d in modele:GetDescendants() do
		if d:IsA("BasePart") and d ~= coeur then
			d.CanCollide = false
			TweenService:Create(d, TweenInfo.new(0.35), {Transparency = 1, Size = d.Size * 0.5}):Play()
		end
	end
	Debris:AddItem(modele, 1.2)
end)

-- Appui du rocher : sur la paroi (haut = normale) ou au sol, le long du point de galerie pt
local function appuiMinerai(rng, pt)
	local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local hit
	if rng:NextNumber() < 0.7 then
		hit = lancer(pt.p + Vector3.new(0, rng:NextNumber(1.2, 3.5), 0), lat * (pt.r + 6))
	else
		hit = lancer(pt.p + lat * (pt.r * rng:NextNumber(0.4, 0.65)) + Vector3.new(0, 5, 0), Vector3.new(0, -12, 0))
	end
	if not hit then return nil end
	local n = hit.Normal
	if n.Y > 0.7 then return CFrame.new(hit.Position - Vector3.new(0, 0.3, 0)) end
	local droite = n:Cross(Vector3.yAxis)
	if droite.Magnitude < 1e-3 or n.Y < -0.3 then return nil end
	return CFrame.fromMatrix(hit.Position - n * 0.7, droite.Unit, n)
end

local function minerais(ctx, chemin, interdits, total)
	local rng, niveau = ctx.rng, ctx.niveau
	local f = Instance.new("Folder")
	f.Name = "Minerais"
	f.Parent = ctx.modele
	local poses = {}
	local nombre = 0
	for essai = 1, total * 4 do
		if nombre >= total then break end
		local sol = appuiMinerai(rng, chemin[rng:NextInteger(1, #chemin)])
		local ok = sol ~= nil
		if sol then
			for _, q in interdits do
				if (q[1] - sol.Position).Magnitude < q[2] then ok = false; break end
			end
			if ok then
				for _, q in poses do
					if (q - sol.Position).Magnitude < 4.5 then ok = false; break end
				end
			end
		end
		if ok then
			local def = Grottes.tirer(niveau.minerais, rng)
			local visuel = MineraisModeles.VISUEL[def.id]
			if visuel then
				local modele, coeur = MineraisModeles.construire(def.id, sol, Random.new(ctx.graine + essai), true)
				for _, p in modele:GetChildren() do
					if p:IsA("BasePart") then p.CanQuery = p == coeur end -- la visée ne touche que le cœur
				end
				coeur:SetAttribute("Type", def.id)
				coeur:SetAttribute("Taille", visuel.taille)
				coeur:SetAttribute("PV", def.pv)
				coeur:SetAttribute("PVMax", def.pv)
				coeur:SetAttribute("Proprietaire", ctx.proprietaire)
				if ctx.invite then coeur:SetAttribute("Invite", ctx.invite) end
				modele.Parent = f
				CollectionService:AddTag(coeur, "Minerai")
				noeuds[coeur] = modele
				table.insert(poses, sol.Position)
				nombre += 1
			end
		end
	end
end

-- ================= Construction =================

function Generateur.construire(niveau, index, graine, proprietaire, invite)
	local rng = Random.new(graine)
	local base = Generateur.emplacement(index)
	local roche = O.materiau(niveau.ambiance.materiau, Enum.Material.Slate)
	if not dossier or not dossier.Parent then
		dossier = workspace:FindFirstChild("Grottes") or Instance.new("Folder")
		dossier.Name = "Grottes"
		dossier.Parent = workspace
	end
	local m = Instance.new("Model")
	m.Name = "Grotte_" .. tostring(proprietaire)
	m:SetAttribute("Proprietaire", proprietaire)
	if invite then m:SetAttribute("Invite", invite) end
	m:SetAttribute("Niveau", niveau.id)
	m:SetAttribute("Emplacement", index)
	O.atomique(m)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = m
	local ctx = {rng = rng, niveau = niveau, modele = m, decor = decor, lumieres = 0, graine = graine % 1e9,
		proprietaire = proprietaire, invite = invite, matPart = roche}

	-- 1. Bloc de roche puis creusement
	terrain:FillBlock(CFrame.new(base + CENTRE_BOITE), TAILLE_BOITE, roche)
	local salles, liens, alcoves, depart, boss = planifier(base, rng)
	local galeries = {}
	for _, l in liens do
		local a, b = l[1], l[2]
		local g = trace(base, a.p, b.p, a.r, b.r, rng:NextNumber(9.5, 12.5), rng) -- galeries larges (≈ 16 à 22 studs de sol)
		if g then table.insert(galeries, g) end
	end
	for _, s in salles do creuserSalle(s, roche, rng) end
	for _, s in alcoves do creuserSalle(s, roche, rng) end
	-- Rallonge de la salle de départ derrière les joueurs (place du cercle de sortie)
	creuserSalle({p = depart.p + Vector3.new(0, 0, 9), r = 11}, roche, rng)
	for _, g in galeries do creuserGalerie(g, roche) end
	-- Le terrain qui vient d'être écrit n'est touché par les raycasts qu'après un pas physique : on attend
	-- qu'il le soit (sinon panneau, torches, minerais et points des mobs ne trouvent aucun sol)
	local attente = os.clock()
	repeat task.wait() until lancer(depart.p + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0)) or os.clock() - attente > 3

	-- 2. Départ : apparitions, sortie, panneau, torches
	-- Regard vers la première salle de la chaîne (l'entrée de la première galerie), pas vers la paroi
	local versSalle = if salles[2] then plat(salles[2].p - depart.p) else Vector3.new(0, 0, -1)
	versSalle = if versSalle.Magnitude > 1e-3 then versSalle.Unit else Vector3.new(0, 0, -1)
	local apparitions = {}
	for _, dx in {-3, 3} do
		local hit = solSous(depart.p + Vector3.new(dx, 0, -1))
		local pos = if hit then hit.Position else depart.p + Vector3.new(dx, 0, -1)
		table.insert(apparitions, CFrame.lookAt(pos, pos + versSalle))
	end
	local sortie = Cercle.construire(m, CFrame.new(depart.p + Vector3.new(0, 0, 9)), "CercleSortieGrotte", {texte = "Sortie"})
	ctx.lumieres += 1 -- lampe du cercle
	panneau(ctx, depart)
	for _, dir in {Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)} do
		local hit = paroi(depart.p + Vector3.new(0, 0, 4), dir, 6, 30)
		if hit then torche(ctx, hit) end
	end
	for _, dir in {Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)} do
		local hit = paroi(boss.p, dir, 7, 40)
		if hit then torche(ctx, hit) end
	end

	-- 3. Chemin : tous les points de galerie + quelques points dans les salles
	local chemin = {}
	local longueur = 0
	for _, g in galeries do
		longueur += g.longueur
		for _, pt in g.pts do table.insert(chemin, pt) end
	end
	local lieux = table.clone(salles)
	for _, s in alcoves do table.insert(lieux, s) end

	-- 4. Points des mobs : au sol, de la place au-dessus, loin des apparitions, espacés
	local candidats = {}
	for i = 1, #chemin, 3 do table.insert(candidats, chemin[i].p) end
	for _, s in lieux do
		table.insert(candidats, s.p)
		for k = 1, 4 do
			local a = k * math.pi / 2 + rng:NextNumber(-0.4, 0.4)
			table.insert(candidats, s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * 0.5)
		end
	end
	melanger(candidats, rng)
	local sols = {}
	for _, c in candidats do
		local hit = solSous(c)
		if hit and not lancer(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 9, 0)) then
			local loin = true
			for _, a in apparitions do
				if (a.Position - hit.Position).Magnitude < DISTANCE_MOBS then loin = false end
			end
			if loin then table.insert(sols, hit.Position) end
		end
	end
	local pointsMobs = {}
	for _, espace in {14, 6} do
		for _, p in sols do
			if #pointsMobs >= 30 then break end
			local ok = true
			for _, q in pointsMobs do
				if (q - p).Magnitude < espace then ok = false; break end
			end
			if ok then table.insert(pointsMobs, p) end
		end
		if #pointsMobs >= 12 then break end
	end
	local hitBoss = solSous(boss.p)
	local salleBoss = if hitBoss then hitBoss.Position else boss.p

	-- 5. Minerais (pas devant la sortie, pas sur un point de mob)
	local interdits = {{depart.p + Vector3.new(0, 0, 4), 20}, {salleBoss, 6}}
	for _, p in pointsMobs do table.insert(interdits, {p, 3.5}) end
	local total = math.min(MAX_MINERAIS, math.floor(niveau.densiteMinerais * longueur / 10 + 0.5))
	if #chemin > 0 then minerais(ctx, chemin, interdits, total) end

	-- 6. Décor : cristaux aux parois (un amas par salle + le long des galeries), stalactites, stalagmites
	for _, s in lieux do
		local a = rng:NextNumber(0, 2 * math.pi)
		local hit = paroi(s.p, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(1, 5), s.r * 1.6)
		if hit then cristaux(ctx, hit.Position, hit.Normal, if s.boss then 1.6 else 1.2) end
	end
	if #chemin > 0 then
		for _ = 1, 30 do
			if ctx.lumieres >= MAX_LUMIERES then break end
			local pt = chemin[rng:NextInteger(1, #chemin)]
			local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
			local hit = paroi(pt.p, lat, rng:NextNumber(0.5, 6), pt.r + 6)
			if hit and (hit.Position - depart.p).Magnitude > 18 then cristaux(ctx, hit.Position, hit.Normal, 1) end
		end
		for _ = 1, 32 do
			local pt = chemin[rng:NextInteger(1, #chemin)]
			local hit = lancer(pt.p + Vector3.new(rng:NextNumber(-3, 3), 2, rng:NextNumber(-3, 3)), Vector3.new(0, 40, 0))
			if hit and hit.Normal.Y < -0.3 then pointe(ctx, hit.Position, -1, rng:NextNumber(0.7, 1.4)) end
		end
		for _ = 1, 22 do
			local pt = chemin[rng:NextInteger(1, #chemin)]
			local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
			local hit = solSous(pt.p + lat * pt.r * 0.7)
			if hit and (hit.Position - depart.p).Magnitude > 16 then pointe(ctx, hit.Position, 1, rng:NextNumber(0.6, 1.2)) end
		end
	end

	m.Parent = dossier
	return {
		modele = m,
		base = base,
		niveau = niveau,
		apparitions = apparitions,
		sortie = sortie,
		centreSortie = sortie:GetAttribute("Centre"),
		pointsMobs = pointsMobs,
		salleBoss = salleBoss,
		centre = base + CENTRE_BOITE,
		rayon = 130,
	}
end

-- Détruit le modèle et remet la zone à l'air (sans erreur si déjà détruite)
function Generateur.detruire(grotte)
	if not grotte or grotte.detruite then return end
	grotte.detruite = true
	if grotte.modele then grotte.modele:Destroy() end
	if grotte.base then
		terrain:FillBlock(CFrame.new(grotte.base + CENTRE_BOITE), TAILLE_BOITE + Vector3.new(8, 8, 8), AIR)
	end
end

return Generateur
