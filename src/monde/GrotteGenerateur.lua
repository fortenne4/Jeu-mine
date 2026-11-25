-- Grottes profondes : génération d'une grotte aléatoire (Terrain) pour une expédition à 1 ou 2 joueurs.
-- Bloc de roche (matériau du palier) creusé par des galeries sinueuses : salle de départ (cercle de sortie,
-- panneau), 3 à 5 salles larges, une salle finale (boss) au bout, culs-de-sac et boucles.
-- Relief : salles à des hauteurs très différentes (pentes ≤ ~32° ou marches de 2 studs), fosses peu profondes
-- (bords franchissables), corniches (≤ 4,5 studs, à sauter), salles hautes, passages bas (plafond ≥ 11).
-- Minerais : même rocher que MinePrivee (Partage › MineraisModeles), enfoncés dans les parois / le sol,
-- regroupés en 3-4 gisements (niveau.nombreMinerais nœuds au total, 1 nœud = 1 minerai), aucun dans la zone
-- sûre de l'arrivée (Grottes.ZONE_SURE). grotte.gisements = points de garde pour MobsGrotte.
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
local GrotteDecor = require(script.Parent.GrotteDecor)
local GrotteLueurs = require(script.Parent.GrotteLueurs) -- thème du palier 1 (−50 m)
-- thèmes des paliers profonds (GrotteTheme : outils communs) ; un palier sans thème garde GrotteDecor
local THEMES = {
	[1] = GrotteLueurs,
	[2] = require(script.Parent.GrotteMine), -- −100 m « La Mine oubliée de Brumefer »
	[3] = require(script.Parent.GrotteFonderie), -- −200 m « La Fonderie de l'Abîme »
	[4] = require(script.Parent.GrotteLave), -- −350 m « Les Rivières de lave »
	[5] = require(script.Parent.GrotteCoeur), -- −500 m « Le Cœur maudit »
	[6] = require(script.Parent.GrotteGlace), -- −700 m « Les Cavernes de glace éternelle »
	[7] = require(script.Parent.GrotteAbysses), -- −900 m « La Cité engloutie »
	[8] = require(script.Parent.GrotteAstres), -- −1200 m « L'Observatoire des astres »
}
local M, C = O.M, O.C

local Generateur = {}

local terrain = workspace.Terrain
local AIR = Enum.Material.Air
-- Grottes 1,5 × (salles, galeries, chaîne, bloc) ; hauteurs de marche / pentes / corniches inchangées
local TAILLE_BOITE = Vector3.new(360, 190, 360) -- bloc de roche (repère : base = sol ≈ 0)
local CENTRE_BOITE = Vector3.new(0, 20, 0)     -- y de -75 à +115
local LIMITE = 147                             -- |x|, |z| max d'un point de galerie (parois ≥ 18 studs)
local Y_MIN, Y_MAX = -24, 30                   -- sols des salles (départ à 0)
local PENTE = 0.42                             -- dénivelé max / longueur d'une galerie (pente moyenne ≤ ~23°)
local MARCHE = 2                               -- hauteur des marches (galeries en escalier)
local PAS = 4.5                                -- espacement des boules d'air le long d'une galerie
local MAX_LUMIERES = 48
local DISTANCE_MOBS = Grottes.ZONE_SURE
-- Gisements (« zones de chaleur ») : 3-4 grappes de 2 à 5 nœuds dans une même salle / alcôve, hors zone sûre
local GISEMENTS = {3, 4}
local NOEUDS_GISEMENT = {2, 5}
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
		if s ~= sa and s ~= sb and distanceSegment(s.p, a, b) < s.r + 30 then return false end
	end
	return true
end

-- Le segment a → b coupe (en plan) une galerie déjà posée, hors galeries partant de sa / sb (extrémité commune)
local function coupe(liens, a, b, sa, sb)
	local function o(p, q, r) return (q.X - p.X) * (r.Z - p.Z) - (q.Z - p.Z) * (r.X - p.X) end
	for _, l in liens do
		local c, d = l[1], l[2]
		if c ~= sa and c ~= sb and d ~= sa and d ~= sb then
			local cp, dp = c.p, d.p
			if o(a, b, cp) * o(a, b, dp) < 0 and o(cp, dp, a) * o(cp, dp, b) < 0 then return true end
		end
	end
	return false
end

-- Le point p est à moins de marge d'une galerie déjà posée (hors galeries partant de sauf)
local function presDeGalerie(liens, p, marge, sauf)
	for _, l in liens do
		if l[1] ~= sauf and l[2] ~= sauf and distanceSegment(p, l[1].p, l[2].p) < marge then return true end
	end
	return false
end

-- Hauteur de sol d'une salle reliée à une autre : pente bornée par l'écart entre leurs bords
local function hauteurVers(base, ya, ecart, rng)
	local dy = (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(0.3, 1) * math.min(21, PENTE * math.max(ecart, 0))
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
	local amp = rng:NextNumber(7.5, 21) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local amp2 = rng:NextNumber(1.5, 5)
	local ondes = rng:NextInteger(1, 2)
	local phase = rng:NextNumber(0, math.pi)
	local debut, fin = ra * 0.8, L - rb * 0.8
	local marches = math.abs(b.Y - a.Y) > 5 and rng:NextNumber() < 0.5
	local n = math.max(2, math.ceil(L * 1.3 / PAS))
	local pts = {}
	for i = 0, n do
		local t = i / n
		local s = t * L
		local u = if fin > debut then math.clamp((s - debut) / (fin - debut), 0, 1) else t
		u = u * u * (3 - 2 * u)
		local decal = math.sin(t * math.pi) * (amp * math.sin(t * math.pi * ondes + phase) + amp2 * math.sin(t * math.pi * 5 + phase * 2))
		local p = a + avant * s + cote * decal
		local dy = (b.Y - a.Y) * u
		if marches then dy = math.round(dy / MARCHE) * MARCHE end
		table.insert(pts, {p = borne(base, Vector3.new(p.X, a.Y + dy, p.Z)), r = r})
	end
	local longueur = 0
	for i, pt in pts do
		local av, ap = pts[math.max(1, i - 1)].p, pts[math.min(#pts, i + 1)].p
		local t = plat(ap - av)
		pt.t = if t.Magnitude > 1e-3 then t.Unit else avant
		if i > 1 then longueur += (pt.p - pts[i - 1].p).Magnitude end
	end
	local x = rng:NextNumber()
	return {pts = pts, r = r, longueur = longueur, plafond = if x < 0.25 then "bas" elseif x < 0.5 then "haut" else nil}
end

local function planifier(base, rng)
	local depart = {p = base + Vector3.new(0, 0, 120), r = 24, depart = true}
	local salles = {depart}
	local liens = {} -- {sa, sb}
	-- Chaîne principale : départ → 2-3 salles (alternées gauche / droite) → boss au fond (-Z)
	local nChaine = rng:NextInteger(2, 3)
	local prec = depart
	local signe = if rng:NextNumber() < 0.5 then -1 else 1
	for i = 1, nChaine + 1 do
		local boss = i == nChaine + 1
		local r = if boss then 30 else rng:NextNumber(21, 27)
		local x = if boss then rng:NextNumber(-60, 60) else signe * rng:NextNumber(33, LIMITE - r - 9)
		local z = if boss then -123 else 120 - 243 * i / (nChaine + 1) + rng:NextNumber(-9, 9)
		local p = base + Vector3.new(x, 0, z)
		local y = hauteurVers(base, prec.p.Y, ecartEntre(prec.p, p, prec.r, r), rng)
		local s = {p = Vector3.new(p.X, y, p.Z), r = r, boss = boss}
		table.insert(salles, s)
		table.insert(liens, {prec, s, principal = true})
		prec = s
		signe = -signe
	end
	local boss = prec
	local distBoss = plat(boss.p - depart.p).Magnitude
	-- Salles annexes (3 à 5 salles larges en tout hors départ / boss), reliées à la salle la plus proche
	local nSalles = rng:NextInteger(3, 5)
	for _ = 1, 40 do
		if #salles - 2 >= nSalles then break end
		local r = rng:NextNumber(21, 30)
		local p = base + Vector3.new(rng:NextNumber(-(LIMITE - r), LIMITE - r), 0, rng:NextNumber(-105, 90))
		local ok = plat(p - depart.p).Magnitude < distBoss - 15
		local proche, dProche = nil, math.huge
		for _, s in salles do
			local d = plat(p - s.p).Magnitude
			if d < s.r + r + 27 then ok = false; break end
			if not s.depart and not s.boss and d < dProche then proche, dProche = s, d end
		end
		if ok and proche and libre(salles, proche.p, p, proche, nil) and not presDeGalerie(liens, p, r + 30, nil)
			and not coupe(liens, proche.p, p, proche, nil) then
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
			if a ~= b and not relie(a, b) and d < 210 and ecart > 12 and math.abs(a.p.Y - b.p.Y) <= PENTE * ecart
				and libre(salles, a.p, b.p, a, b) and not coupe(liens, a.p, b.p, a, b) then
				table.insert(liens, {a, b})
			end
		else
			local a = salles[rng:NextInteger(2, #salles)]
			local angle = rng:NextNumber(0, 2 * math.pi)
			local longueur = rng:NextNumber(45, 82)
			local fin = borne(base, a.p + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (a.r * 0.8 + longueur))
			local ecart = ecartEntre(a.p, fin, a.r, 13.5)
			local ok = ecart > 22 and libre(salles, a.p, fin, a, nil) and not coupe(liens, a.p, fin, a, nil)
				and not presDeGalerie(liens, fin, 13.5 + 30, a)
			for _, s in salles do
				if s ~= a and plat(fin - s.p).Magnitude < s.r + 27 then ok = false end
			end
			for _, s in alcoves do
				if plat(fin - s.p).Magnitude < 40 then ok = false end
			end
			if ok then
				local y = hauteurVers(base, a.p.Y, ecart, rng)
				local s = {p = Vector3.new(fin.X, y, fin.Z), r = 13.5, alcove = true}
				table.insert(alcoves, s)
				table.insert(liens, {a, s})
			end
		end
	end
	return salles, liens, alcoves, depart, boss
end

-- ================= Creusement (Terrain) =================

-- Laisse respirer le serveur pendant le creusement (une pause toutes les ~25 opérations de terrain)
local operations = 0
local function respirer()
	operations += 1
	if operations % 25 == 0 then task.wait() end
end

local function creuserSalle(s, roche, rng)
	respirer()
	local r = s.r
	terrain:FillBall(s.p + Vector3.new(0, r * 0.4, 0), r, AIR)
	if s.haute then terrain:FillBall(s.p + Vector3.new(0, r * 1.25, 0), r * 0.85, AIR) end -- salle haute (≈ 2 × r)
	for _ = 1, 3 do
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(0.3, 0.5) * r
		terrain:FillBall(s.p + Vector3.new(math.cos(a) * d, r * 0.45, math.sin(a) * d), r * 0.6, AIR)
	end
	local h = r * 0.6 + 2
	terrain:FillCylinder(CFrame.new(s.p - Vector3.new(0, h / 2, 0)), h, r * 1.15, roche)
end

-- Boules d'air puis galette de roche jusqu'au sol. Plafond : normal ≥ 19, « bas » ≥ 11, « haut » ≥ 26
local function creuserGalerie(g, roche)
	for _, pt in g.pts do
		respirer()
		local r = pt.r
		if g.plafond == "bas" then
			terrain:FillBall(pt.p + Vector3.new(0, r * 0.3, 0), r * 0.9, AIR)
		else
			terrain:FillBall(pt.p + Vector3.new(0, r * 0.5, 0), r, AIR)
			terrain:FillBall(pt.p + Vector3.new(0, r * 0.5 + (if g.plafond == "haut" then 12 else 5), 0), r * 0.9, AIR)
		end
		local h = r * 0.5 + 1.5
		terrain:FillCylinder(CFrame.new(pt.p - Vector3.new(0, h / 2, 0)), h, r, roche)
	end
end

-- Relief d'une salle (hors départ / boss) : fosse (cuvette ≤ 3,5 studs, bords ≤ ~50° : on en ressort en
-- marchant, même sur le passage) et corniche contre la paroi (≤ 4,5 studs, à sauter, hors des passages).
local function relief(s, galeries, roche, rng)
	local function loinDesGaleries(c, marge)
		for _, g in galeries do
			for _, pt in g.pts do
				if plat(pt.p - c).Magnitude < marge + pt.r * 0.3 and math.abs(pt.p.Y - s.p.Y) < 8 then return false end
			end
		end
		return true
	end
	local function endroit(dist, marge)
		local a0 = rng:NextNumber(0, 2 * math.pi)
		for k = 0, 5 do
			local a = a0 + k * math.pi / 3
			local c = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * dist
			if loinDesGaleries(c, marge) then return c end
		end
		return nil
	end
	if rng:NextNumber() < 0.45 then
		local R = math.min(rng:NextNumber(13, 16), s.r * 0.6)
		local prof = rng:NextNumber(2, 3.5)
		local a = rng:NextNumber(0, 2 * math.pi)
		local c = s.p + Vector3.new(math.cos(a), 0, math.sin(a)) * s.r * rng:NextNumber(0, 0.3)
		terrain:FillBall(c + Vector3.new(0, R - prof, 0), R, AIR)
	end
	if rng:NextNumber() < 0.5 then
		local rc, h = rng:NextNumber(6, 9), rng:NextNumber(3, 4.5)
		local c = endroit(s.r * 0.72, rc + 2)
		if c then terrain:FillCylinder(CFrame.new(c + Vector3.new(0, (h - 2) / 2, 0)), h + 2, rc, roche) end
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
		local p = O.decor(O.bloc(ctx.decor, Vector3.new(w, h, w), cf, if i % 2 == 0 then couleur else couleur:Lerp(Color3.new(), 0.4), if i % 2 == 0 then M.Verre else M.Neon, "Cristal"))
		if p.Material == M.Verre then p.Transparency = 0.25 end
		premier = premier or p
	end
	if premier then lumiere(ctx, premier, couleur, 0.8, 18 * echelle) end
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
	local hit = solSous(depart.p + Vector3.new(-10, 0, 3))
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

-- Appui du rocher (haut = normale) : paroi ou sol touché par le rayon origine → direction.
-- Le centre du rocher est mis à la surface (± un peu) : il affleure au lieu de dépasser. s = taille du rocher.
-- Renvoie le CFrame à passer à MineraisModeles.construire et le point de surface.
local function appuiMinerai(rng, origine, direction, s)
	local hit = lancer(origine, direction)
	if not hit then return nil, nil end
	local n = hit.Normal
	local enfonce = rng:NextNumber(-0.5, 0.15) - 1.25 * s -- construire() monte le centre de 1,25 × s
	local penche = CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3))
	if n.Y > 0.7 then return CFrame.new(hit.Position + Vector3.new(0, enfonce + 0.2, 0)) * penche, hit.Position end
	local droite = n:Cross(Vector3.yAxis)
	if droite.Magnitude < 1e-3 or n.Y < -0.3 then return nil, nil end
	return CFrame.fromMatrix(hit.Position + n * enfonce, droite.Unit, n) * penche, hit.Position
end

local function poserMinerai(ctx, f, def, sol, echelle, graine)
	local visuel = MineraisModeles.VISUEL[def.id]
	local modele, coeur = MineraisModeles.construire(def.id, sol, Random.new(graine), true)
	if echelle ~= 1 then modele:ScaleTo(echelle) end -- autour du cœur (PrimaryPart) : reste affleurant
	for _, p in modele:GetChildren() do
		if p:IsA("BasePart") then p.CanQuery = p == coeur end -- la visée ne touche que le cœur
	end
	coeur:SetAttribute("Type", def.id)
	coeur:SetAttribute("Taille", visuel.taille * echelle)
	coeur:SetAttribute("PV", def.pv)
	coeur:SetAttribute("PVMax", def.pv)
	coeur:SetAttribute("Proprietaire", ctx.proprietaire)
	if ctx.invite then coeur:SetAttribute("Invite", ctx.invite) end
	modele.Parent = f
	CollectionService:AddTag(coeur, "Minerai")
	noeuds[coeur] = modele
end

-- Gisements (« zones de chaleur ») : `total` nœuds (1 nœud = 1 minerai) en 3-4 grappes de 2 à 5, chacune dans
-- un secteur de paroi / sol (± 35°) d'une salle ou alcôve (sites, déjà hors zone sûre). Chaque gisement a un
-- type dominant (types différents d'un gisement à l'autre : au moins 2-3 types par grotte).
-- Renvoie {{centre = sol devant le gisement (gardes), rayon}}.
local function gisements(ctx, sites, interdits, total)
	local rng, niveau = ctx.rng, ctx.niveau
	local f = Instance.new("Folder")
	f.Name = "Minerais"
	f.Parent = ctx.modele
	local mini, maxi = NOEUDS_GISEMENT[1], NOEUDS_GISEMENT[2]
	local k = math.min(#sites, math.max(rng:NextInteger(GISEMENTS[1], GISEMENTS[2]), math.ceil(total / maxi)))
	if k == 0 then return {} end
	local tailles = {}
	for i = 1, k do tailles[i] = mini end
	local reste = total - k * mini
	for _ = 1, 200 do
		if reste <= 0 then break end
		local i = rng:NextInteger(1, k)
		if tailles[i] < maxi then tailles[i] += 1; reste -= 1 end
	end
	-- types dominants : tirage pondéré sans remise, puis on reboucle (un minerai « dominant = false » ne domine jamais)
	local types, reserve = {}, Grottes.mineraisDominants(niveau)
	while #reserve > 0 do
		local d = Grottes.tirer(reserve, rng)
		table.insert(types, d)
		table.remove(reserve, table.find(reserve, d))
	end
	local liste, iSite, essai = {}, 1, 0
	for i, n in tailles do
		local dominant = types[(i - 1) % #types + 1]
		while iSite <= #sites do
			local s = sites[iSite]
			iSite += 1
			local a0 = rng:NextNumber(0, 2 * math.pi)
			local places = {}
			for _ = 1, n * 8 do
				if #places >= n then break end
				essai += 1
				local def = if rng:NextNumber() < 0.7 then dominant else Grottes.tirer(niveau.minerais, rng)
				local visuel = MineraisModeles.VISUEL[def.id]
				local a = a0 + rng:NextNumber(-0.6, 0.6)
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local sol, surface
				if visuel then
					if rng:NextNumber() < 0.75 then
						sol, surface = appuiMinerai(rng, s.p + Vector3.new(0, rng:NextNumber(0.8, 4.5), 0), dir * (s.r * 1.6), visuel.taille)
					else
						sol, surface = appuiMinerai(rng, s.p + dir * (s.r * rng:NextNumber(0.6, 0.85)) + Vector3.new(0, 5, 0), Vector3.new(0, -14, 0), visuel.taille)
					end
				end
				local ok = sol ~= nil and plat(surface - s.p).Magnitude < s.r * 1.35
				if ok then
					for _, q in interdits do
						if (q[1] - surface).Magnitude < q[2] then ok = false; break end
					end
				end
				if ok then
					for _, q in places do
						if (q - surface).Magnitude < 3.2 then ok = false; break end -- serrés mais pas imbriqués
					end
				end
				if ok then
					poserMinerai(ctx, f, def, sol, rng:NextNumber(0.8, 1), ctx.graine + essai)
					table.insert(places, surface)
				end
			end
			if #places > 0 then
				local moyenne = Vector3.zero
				for _, q in places do moyenne += q end
				moyenne /= #places
				local c = s.p + plat(moyenne - s.p) * 0.5
				local hit = solSous(Vector3.new(c.X, s.p.Y, c.Z))
				table.insert(liste, {centre = if hit then hit.Position else s.p, rayon = math.min(s.r, 18)})
				break
			end
		end
	end
	return liste
end

-- Minerai posé par un thème (ex. salle scellée de −700 m) : même rocher et mêmes attributs que les gisements.
-- Rayon origine → direction (sol ou paroi) ; valide(surface) peut refuser l'endroit. Renvoie la surface ou nil.
local function mineraiTheme(ctx, def, origine, direction, echelle, valide)
	local visuel = MineraisModeles.VISUEL[def.id]
	local sol, surface = if visuel then appuiMinerai(ctx.rng, origine, direction, visuel.taille) else nil, nil
	if not sol or (valide and not valide(surface)) then return nil end
	local f = ctx.modele:FindFirstChild("Minerais")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Minerais"
		f.Parent = ctx.modele
	end
	ctx.nTheme = (ctx.nTheme or 0) + 1
	poserMinerai(ctx, f, def, sol, echelle or 1, ctx.graine + 90000 + ctx.nTheme)
	return surface
end

-- ================= Construction =================

function Generateur.construire(niveau, index, graine, proprietaire, invite, essai)
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
		local g = trace(base, a.p, b.p, a.r, b.r, rng:NextNumber(14, 18.5), rng) -- galeries larges (≈ 24 à 33 studs de sol)
		if g then
			g.principal = l.principal
			table.insert(galeries, g)
		end
	end
	for _, s in salles do
		s.haute = not s.depart and rng:NextNumber() < 0.4
		creuserSalle(s, roche, rng)
	end
	for _, s in alcoves do creuserSalle(s, roche, rng) end
	-- Rallonge de la salle de départ derrière les joueurs (place du cercle de sortie)
	creuserSalle({p = depart.p + Vector3.new(0, 0, 12), r = 15}, roche, rng)
	-- Chaîne principale (départ → boss) creusée EN DERNIER : rien ne peut la reboucher
	for _, g in galeries do
		if not g.principal then creuserGalerie(g, roche) end
	end
	for _, g in galeries do
		if g.principal then creuserGalerie(g, roche) end
	end
	for _, s in salles do
		if not s.depart and not s.boss then relief(s, galeries, roche, rng) end
	end
	-- Le terrain qui vient d'être écrit n'est touché par les raycasts qu'après un pas physique : on attend
	-- qu'il le soit (sinon panneau, torches, minerais et points des mobs ne trouvent aucun sol)
	local attente = os.clock()
	repeat task.wait() until lancer(depart.p + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0)) or os.clock() - attente > 3

	-- Vérification départ → boss : rayons le long de la chaîne ; bouchée → nouvelle graine.
	-- Un tronçon n'est bouché que si les rayons à 3, 6 ET 9 studs du sol touchent tous la roche : les bosses du sol
	-- entre deux points (qu'on franchit en marchant) arrêtaient le seul rayon à 3 studs, et la grotte était alors
	-- générée trois fois de suite pour rien (chargement bien plus long).
	local bouchee = false
	for _, g in galeries do
		if g.principal then
			for i = 2, #g.pts do
				local ferme = true
				for _, hauteur in {3, 6, 9} do
					local a, b = g.pts[i - 1].p + Vector3.new(0, hauteur, 0), g.pts[i].p + Vector3.new(0, hauteur, 0)
					if not lancer(a, b - a) then ferme = false; break end
				end
				if ferme then bouchee = true; break end
			end
		end
		if bouchee then break end
	end
	if bouchee and (essai or 0) < 2 then
		m:Destroy()
		terrain:FillBlock(CFrame.new(base + CENTRE_BOITE), TAILLE_BOITE + Vector3.new(8, 8, 8), AIR)
		return Generateur.construire(niveau, index, graine + 7, proprietaire, invite, (essai or 0) + 1)
	elseif bouchee then
		warn("[Grottes] chemin départ → boss peut-être bouché (graine " .. tostring(graine) .. ")")
	end

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
		local hit = paroi(depart.p + Vector3.new(0, 0, 4), dir, 6, 45)
		if hit then torche(ctx, hit) end
	end
	for _, dir in {Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)} do
		local hit = paroi(boss.p, dir, 7, 60)
		if hit then torche(ctx, hit) end
	end

	-- 3. Chemin : tous les points de galerie + quelques points dans les salles
	local chemin = {}
	for _, g in galeries do
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
	local libres = {}
	for _, c in candidats do
		local hit = solSous(c)
		if hit and not lancer(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 9, 0)) then
			table.insert(libres, hit.Position)
		end
	end
	-- Hors zone sûre ; si trop peu de points (petite grotte), on se rapproche un peu (jamais sous 0,7 × la zone)
	for _, distance in {DISTANCE_MOBS, DISTANCE_MOBS * 0.7} do
		table.clear(sols)
		for _, p in libres do
			local loin = true
			for _, a in apparitions do
				if (a.Position - p).Magnitude < distance then loin = false end
			end
			if loin then table.insert(sols, p) end
		end
		if #sols >= 8 then break end
	end
	local pointsMobs = {}
	for _, espace in {20, 8} do
		for _, p in sols do
			if #pointsMobs >= 30 then break end
			local ok = true
			for _, q in pointsMobs do
				if (q - p).Magnitude < espace then ok = false; break end
			end
			if ok then table.insert(pointsMobs, p) end
		end
		if #pointsMobs >= 16 then break end
	end
	local hitBoss = solSous(boss.p)
	local salleBoss = if hitBoss then hitBoss.Position else boss.p

	-- 5. Gisements de minerais (pas dans la zone sûre, pas sur un point de mob) : salles et alcôves
	-- (ordre aléatoire, salle du boss en dernier), chacune assez loin de l'arrivée
	local interdits = {{depart.p + Vector3.new(0, 0, 4), Grottes.ZONE_SURE}, {salleBoss, 6}}
	for _, p in pointsMobs do table.insert(interdits, {p, 3.5}) end
	local sites = {}
	for _, s in lieux do
		if not s.depart and not s.boss and plat(s.p - depart.p).Magnitude > Grottes.ZONE_SURE + 5 then table.insert(sites, s) end
	end
	melanger(sites, rng)
	table.insert(sites, boss)
	local total = rng:NextInteger(niveau.nombreMinerais[1], niveau.nombreMinerais[2])
	local listeGisements = gisements(ctx, sites, interdits, total)

	-- 6. Décor (GrotteDecor.lua) : stalactites/stalagmites/colonnes/cristaux modélisés, bassins, mousse,
	-- champignons lumineux, racines, restes d'une ancienne mine, torches de balisage, salle du boss habillée
	m:SetAttribute("Centre", base + CENTRE_BOITE) -- boîte de la grotte : lue par AmbianceGrotte.client.lua
	m:SetAttribute("DemiTaille", TAILLE_BOITE / 2)
	if #chemin > 0 then
		local theme = THEMES[niveau.id] or GrotteDecor
		local ok, err = pcall(theme.decorer, ctx, {
			depart = depart, boss = boss, chemin = chemin, lieux = lieux, galeries = galeries, pointsMobs = pointsMobs,
			gisements = listeGisements, salleBoss = salleBoss, avantBoss = (function() for _, l in liens do if l.principal and l[2] == boss then return l[1].p end end return nil end)(),
		}, {
			lancer = lancer, paroi = paroi, solSous = solSous, plat = plat, axeVers = axeVers,
			lumiere = lumiere, torche = torche, pointe = pointe, cristaux = cristaux,
			minerai = function(def, o, d, e, v) return mineraiTheme(ctx, def, o, d, e, v) end,
		})
		if not ok then warn("[Grottes] décor incomplet : " .. tostring(err)) end
	end

	-- 7. Apparitions revérifiées APRÈS le décor (un thème peut creuser ou poser des choses à l'arrivée) :
	-- chaque point doit avoir un vrai sol juste dessous ; sinon on cherche du sol en anneaux autour du départ.
	local function solFiable(p: Vector3): Vector3?
		local hit = lancer(p + Vector3.new(0, 6, 0), Vector3.new(0, -16, 0))
		if hit and hit.Normal.Y > 0.7 then
			local plafond = lancer(hit.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 7, 0))
			if not plafond then return hit.Position end
		end
		return nil
	end
	for i, cf in apparitions do
		if not solFiable(cf.Position) then
			local trouve = nil
			for r = 0, 14, 2 do
				for k = 0, 11 do
					local a = k / 12 * 2 * math.pi
					local essai = solFiable(depart.p + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
					if essai then trouve = essai break end
				end
				if trouve then break end
			end
			if trouve then
				apparitions[i] = CFrame.lookAt(trouve, trouve + versSalle)
			else
				warn("[Grottes] aucune apparition sûre trouvée (graine " .. tostring(graine) .. ")")
			end
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
		gisements = listeGisements, -- {{centre, rayon}} : gardés par un groupe de mobs (MobsGrotte)
		salleBoss = salleBoss,
		centre = base + CENTRE_BOITE,
		rayon = 195,
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
