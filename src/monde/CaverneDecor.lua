-- Mise en scène de la grande caverne de cristal (décor seulement, AUCUN minerai) :
--  • deux piliers de roche naturels qui encadrent l'arrivée, reliés par un pont suspendu (plateformes, échafaudage,
--    échelle, treuil, lanternes) ;
--  • une faille dans la voûte d'où tombent des rayons de lumière et de la poussière au centre ;
--  • une frise de runes gravée au-dessus des portes des tunnels privés ;
--  • un bassin et une cascade souterraine (terrain Water) dans le lobe est ;
--  • autour du grand cristal : cercle de runes, menhirs, halo de pierres et éclats qui flottent en tournant
--    (tag « Flottant », animé côté client par Animations.client.lua) ;
--  • champignons lumineux, racines qui pendent, stalagmites, vieux rails et wagonnets renversés, torches vers les grottes.
-- Lumières douces : PointLight ≤ 1,5 et néons assombris (pas d'éblouissement en entrant sous terre).
-- Tout est dans Mine › DecorCaverne (attribut Version) : construit avec la carte, ou ajouté une seule fois à une
-- carte figée (Mine.preparerVoie). Décor sans collision, sauf les piliers, les menhirs et le parcours en hauteur :
-- échelle grimpable (TrussPart invisible) → plateforme du pilier ouest → pont suspendu → plateforme du pilier est.
local CollectionService = game:GetService("CollectionService")
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local M, C = O.M, O.C

local CaverneDecor = {}
local terrain = workspace.Terrain

local VERSION = 3 -- 2 : pont et échelle praticables, rose / poteau / torches retirés ; 3 : quai dégagé (stalagmite retirée)
local LUMIERE_MAX = 1.5

local ROCHE = Color3.fromRGB(112, 104, 98) -- teinte du matériau Rock (cf. ROCHE_PAROI de Mine.lua)
local BLEU, VIOLET = C.Cristal, C.CristalViolet
local AMBRE = Color3.fromRGB(255, 170, 90)
local TURQUOISE = Color3.fromRGB(90, 220, 200)
local PALE = Color3.fromRGB(196, 222, 240)
local CORDE = Color3.fromRGB(150, 128, 98)
local NOIR = Color3.new()

local PILIERS = {Vector3.new(-32, 0, -386), Vector3.new(32, 0, -386)}
local HAUTEUR_PONT = 28
local BASSIN = Vector3.new(62, 0, -377)
local CASCADE = Vector3.new(66, 0, -366)
local RAILS = {Vector3.new(10, 0, -374), Vector3.new(18, 0, -368), Vector3.new(28, 0, -366), Vector3.new(38, 0, -370),
	Vector3.new(45, 0, -379), Vector3.new(47, 0, -389)}
local DEMI_PLATEFORME = 7

-- ================= Outils =================

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {terrain}
params.IgnoreWater = true

local function terne(c, k) return c:Lerp(NOIR, k or 0.5) end

local function sol(x, z)
	local r = workspace:Raycast(Vector3.new(x, D.CAVERNE_SOL + 10, z), Vector3.new(0, -30, 0), params)
	return if r then r.Position.Y else D.CAVERNE_SOL
end

local function plafond(x, z, y0)
	local r = workspace:Raycast(Vector3.new(x, y0 + 4, z), Vector3.new(0, 160, 0), params)
	return r and r.Position.Y
end

local BOULES = {{D.CAVERNE_CENTRE, D.CAVERNE_RAYON}}
for _, l in D.CAVERNE_LOBES do table.insert(BOULES, l) end
local function dansCaverne(x, z, marge)
	local p = Vector3.new(x, D.CAVERNE_SOL + 2, z)
	for _, b in BOULES do
		if (p - b[1]).Magnitude < b[2] - marge then return true end
	end
	return false
end

-- Zones à garder dégagées (passages, portes, entrée des grottes, décors importants)
local LIBRES = {
	{0, -365, 18}, {0, -392, 24}, {0, -425, 16}, {28, -425, 14}, {52, -425, 20}, {0, -470, 10},
	{D.CRISTAL_CAVERNE.X, D.CRISTAL_CAVERNE.Z, 23}, {BASSIN.X, BASSIN.Z, 15}, {-44, -404, 6}, {24, -396, 6}, {16, -410, 7},
	{-32, -386, 11}, {32, -386, 11}, {-32, -378, 6}, {42, -396, 6},
	{-12, -385, 22}, {-12, -368, 12}, -- quai des profondeurs et son enseigne : aucun rocher devant
}
for _, p in RAILS do table.insert(LIBRES, {p.X, p.Z, 6}) end
for _, p in D.PORTES do
	table.insert(LIBRES, {p.X, p.Z, 14})
	local retour = CFrame.lookAt(p, Vector3.new(D.CAVERNE_CENTRE.X, p.Y, D.CAVERNE_CENTRE.Z)) * CFrame.new(0, 0, -D.RETOUR_AVANCE)
	table.insert(LIBRES, {retour.X, retour.Z, 8})
end
local function libre(x, z)
	for _, l in LIBRES do
		local dx, dz = x - l[1], z - l[2]
		if dx * dx + dz * dz < l[3] * l[3] then return false end
	end
	return true
end

local function ancre(m, cf, taille, nom)
	local p = O.decor(O.bloc(m, taille or Vector3.one, cf, NOIR, M.Lisse, nom or "Ancre"))
	p.Transparency = 1
	p.CastShadow = false
	return p
end

-- Paroi ou sol de collision invisible (pont, plateformes)
local function invisible(m, taille, cf, nom)
	local p = O.bloc(m, taille, cf, NOIR, M.Lisse, nom or "Collision")
	p.Transparency = 1
	p.CastShadow = false
	p.CanTouch = false
	return p
end

-- Barre entre deux points (cordes, chaînes, croisillons)
local function segment(m, a, b, ep, couleur, mat, nom)
	local L = (b - a).Magnitude
	local haut = if math.abs((b - a).Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return O.decor(O.bloc(m, Vector3.new(ep, ep, L), CFrame.lookAt((a + b) / 2, b, haut), couleur, mat, nom))
end

-- Lanterne de mineur (lueur ambre douce, sans le scintillement à 2,2 des lanternes du village)
local function lanterne(m, cf, portee)
	O.decor(O.bloc(m, Vector3.new(0.9, 0.2, 0.9), cf * CFrame.new(0, 0.55, 0), C.Fer, M.Metal, "Chapeau"))
	O.decor(O.bloc(m, Vector3.new(0.9, 0.15, 0.9), cf * CFrame.new(0, -0.5, 0), C.Fer, M.Metal, "Fond"))
	local flamme = O.decor(O.bloc(m, Vector3.new(0.6, 0.85, 0.6), cf, terne(AMBRE, 0.4), M.Neon, "Flamme"))
	flamme.CastShadow = false
	O.lumiere(flamme, AMBRE, 1.2, portee or 18)
	return flamme
end

local function suspendue(m, haut, longueur, portee)
	segment(m, haut, haut - Vector3.new(0, longueur, 0), 0.12, C.Fer, M.Metal, "Chaine")
	return lanterne(m, CFrame.new(haut - Vector3.new(0, longueur + 0.7, 0)), portee)
end

-- Éclat de cristal sans lumière (gaine de verre + cœur néon assombri)
local function eclat(m, cf, h, couleur)
	local r = h * 0.3
	local gaine = O.decor(O.bloc(m, Vector3.new(r, h, r), cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(45), 0), couleur, M.Verre, "Eclat"))
	gaine.Transparency = 0.35
	gaine.Reflectance = 0.2
	O.decor(O.bloc(m, Vector3.new(r * 0.45, h * 0.85, r * 0.45), gaine.CFrame, terne(couleur, 0.45), M.Neon, "CoeurEclat"))
	O.decor(O.bloc(m, Vector3.new(r * 0.7, r * 0.7, r * 0.7), cf * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), couleur, M.Verre, "PointeEclat")).Transparency = 0.3
	return gaine
end

local function emetteur(parent, props)
	local e: any = Instance.new("ParticleEmitter")
	for cle, valeur in props do e[cle] = valeur end
	e.Parent = parent
	return e
end

-- ================= Piliers et pont suspendu =================

local function pilier(m, x, z, rng)
	local y0 = sol(x, z)
	local H = ((plafond(x, z, y0) or (y0 + 60)) + 4) - y0
	local g = O.modele(m, "Pilier")
	local n = math.max(6, math.ceil(H / 7))
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local w = 6 + 7 * (2 * t - 1) ^ 2 + rng:NextNumber(-0.6, 0.6) -- sablier : évasé en bas et en haut
		local h = H / n + 1.5
		local roche = O.bloc(g, Vector3.new(w, h, w * rng:NextNumber(0.85, 1)),
			CFrame.new(x + rng:NextNumber(-0.5, 0.5), y0 + t * H, z + rng:NextNumber(-0.5, 0.5)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			ROCHE:Lerp(C.PierreFoncee, rng:NextNumber(0, 0.5)), M.Roche, "Roche")
		if math.abs(y0 + t * H - (y0 + HAUTEUR_PONT + 3)) < h / 2 + 4 then
			roche.CanCollide = false -- à hauteur de plateforme : on fait le tour du pilier sans être coincé
		end
		if rng:NextNumber() < 0.7 then
			local a = rng:NextNumber(0, math.pi * 2)
			local s = w * rng:NextNumber(0.35, 0.55)
			O.decor(O.bloc(g, Vector3.new(s, h * 0.8, s), CFrame.new(x + math.cos(a) * w * 0.45, y0 + t * H, z + math.sin(a) * w * 0.45)
				* CFrame.Angles(rng:NextNumber(-0.3, 0.3), a, rng:NextNumber(-0.3, 0.3)), ROCHE:Lerp(C.Roche, rng:NextNumber()), M.Roche, "Bosse"))
		end
	end
	-- éboulis au pied
	for _ = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local s = rng:NextNumber(1.2, 2.6)
		O.decor(O.bloc(g, Vector3.new(s, s * 0.7, s), CFrame.new(x + math.cos(a) * 7.5, y0 + s * 0.2, z + math.sin(a) * 7.5)
			* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), ROCHE:Lerp(C.PierreFoncee, rng:NextNumber()), M.Roche, "Eboulis"))
	end
	return y0
end

-- Plateforme carrée praticable autour d'un pilier à la hauteur yb ; cote = +1 si le pont part vers +X.
-- Plancher solide, murets invisibles avec une ouverture vers le pont et (ouverture = true) vers l'échelle (+Z).
local function plateforme(m, cx, cz, yb, cote, ouverture)
	local g = O.modele(m, "Plateforme")
	local P = DEMI_PLATEFORME
	for i = -3, 3 do
		O.bloc(g, Vector3.new(P * 2, 0.4, 2), CFrame.new(cx, yb - 0.2, cz + i * 2), C.Bois:Lerp(C.BoisFonce, i % 2 * 0.4), M.Planches, "Planche")
	end
	for _, s in {-1, 1} do
		O.decor(O.bloc(g, Vector3.new(P * 2 + 0.4, 0.8, 0.8), CFrame.new(cx, yb - 0.8, cz + s * (P - 0.4)), C.BoisFonce, M.Bois, "Poutre"))
		segment(g, Vector3.new(cx + s * 3, yb - 7, cz), Vector3.new(cx + s * (P - 0.4), yb - 0.8, cz), 0.6, C.BoisFonce, M.Bois, "JambeDeForce")
		segment(g, Vector3.new(cx, yb - 7, cz + s * 3), Vector3.new(cx, yb - 0.8, cz + s * (P - 0.4)), 0.6, C.BoisFonce, M.Bois, "JambeDeForce")
	end
	local coins = {}
	for _, sx in {-1, 1} do
		for _, sz in {-1, 1} do
			local p = Vector3.new(cx + sx * (P - 0.2), yb, cz + sz * (P - 0.2))
			O.decor(O.bloc(g, Vector3.new(0.5, 3.6, 0.5), CFrame.new(p + Vector3.new(0, 1.8, 0)), C.BoisFonce, M.Bois, "Poteau"))
			coins[sx .. sz] = p + Vector3.new(0, 3.2, 0)
		end
	end
	-- garde-corps de corde (décor) côté extérieur et côtés Z, lanternes aux coins extérieurs
	local e = -cote
	segment(g, coins[e .. -1], coins[e .. 1], 0.15, CORDE, M.Tissu, "GardeCorps")
	segment(g, coins["-1-1"], coins["1-1"], 0.15, CORDE, M.Tissu, "GardeCorps")
	if not ouverture then segment(g, coins["-11"], coins["11"], 0.15, CORDE, M.Tissu, "GardeCorps") end
	for _, sz in {-1, 1} do
		lanterne(g, CFrame.new(coins[e .. sz] + Vector3.new(0, 1.3, 0)), 20)
	end
	-- murets invisibles : côté extérieur et côté -Z pleins ; côté pont ouvert ; côté +Z ouvert vers l'échelle
	local HM = 4
	local function muret(x0, z0, x1, z1)
		local a, b = Vector3.new(cx + x0, yb + HM / 2, cz + z0), Vector3.new(cx + x1, yb + HM / 2, cz + z1)
		invisible(g, Vector3.new(0.6, HM, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), "GardeCorpsInvisible")
	end
	local OUV = 2.6 -- demi-largeur des ouvertures
	muret(e * P, -P, e * P, P)
	muret(cote * P, -P, cote * P, -OUV)
	muret(cote * P, OUV, cote * P, P)
	muret(-P, -P, P, -P)
	if ouverture then
		muret(-P, P, -OUV, P)
		muret(OUV, P, P, P)
	else
		muret(-P, P, P, P)
	end
	return coins
end

local function pont(m, a, b, rng)
	local g = O.modele(m, "PontSuspendu")
	local L = (b - a).Magnitude
	local axe = CFrame.lookAt(a, b)
	local FLECHE = 3.5
	local function point(s, dx, dy, fleche)
		return (axe * CFrame.new(dx, dy - (fleche or FLECHE) * 4 * s * (1 - s), -s * L)).Position
	end
	local n = math.floor(L / 1.45)
	for i = 0, n do
		local s = i / n
		if i == 0 or i == n or rng:NextNumber() > 0.07 then -- quelques planches manquantes
			local pente = math.atan(-4 * FLECHE * (1 - 2 * s) / L)
			O.bloc(g, Vector3.new(4, 0.25, 1.1), CFrame.new(point(s, 0, 0)) * axe.Rotation * CFrame.Angles(pente, 0, 0),
				C.Bois:Lerp(C.BoisFonce, rng:NextNumber(0, 0.6)), M.Planches, "Planche")
		end
	end
	-- sol continu invisible juste sous le dessus des planches (pas de chute par les planches manquantes)
	-- et parois invisibles le long des mains courantes ; tout est ancré, le pont ne bouge pas
	local nc = 24
	for i = 0, nc - 1 do
		local s0, s1 = i / nc, (i + 1) / nc
		local a0, a1 = point(s0, 0, -0.1), point(s1, 0, -0.1)
		invisible(g, Vector3.new(4.6, 0.4, (a1 - a0).Magnitude + 0.4), CFrame.lookAt((a0 + a1) / 2, a1), "SolPont")
		for _, dx in {-2.4, 2.4} do
			local b0, b1 = point(s0, dx, 2), point(s1, dx, 2)
			invisible(g, Vector3.new(0.4, 4.4, (b1 - b0).Magnitude + 0.4), CFrame.lookAt((b0 + b1) / 2, b1), "GardeCorpsInvisible")
		end
	end
	local k = 12
	for i = 0, k - 1 do
		local s0, s1 = i / k, (i + 1) / k
		for _, dx in {-2.1, 2.1} do
			segment(g, point(s0, dx, -0.25), point(s1, dx, -0.25), 0.2, CORDE, M.Tissu, "CordePorteuse")
			segment(g, point(s0, dx, 3.2, FLECHE * 0.55), point(s1, dx, 3.2, FLECHE * 0.55), 0.15, CORDE, M.Tissu, "MainCourante")
			if i > 0 then
				segment(g, point(s0, dx, -0.25), point(s0, dx, 3.2, FLECHE * 0.55), 0.08, CORDE, M.Tissu, "Suspente")
			end
		end
	end
	for _, s in {0.3, 0.7} do
		suspendue(g, point(s, 0, -0.4), 2.2, 22)
	end
end

local function echafaudage(m, x, z, y0, yb)
	local g = O.modele(m, "Echafaudage")
	local H = yb - y0
	for _, sx in {-2, 2} do
		for _, sz in {-2, 2} do
			O.decor(O.bloc(g, Vector3.new(0.7, H + 1.5, 0.7), CFrame.new(x + sx, y0 + (H + 1.5) / 2, z + sz), C.BoisFonce, M.Bois, "Poteau"))
		end
	end
	local k = 0
	for y = y0 + 7, yb, 7 do
		k += 1
		for _, s in {-2, 2} do
			O.decor(O.bloc(g, Vector3.new(4.7, 0.5, 0.5), CFrame.new(x, y, z + s), C.Bois, M.Bois, "Ceinture"))
			O.decor(O.bloc(g, Vector3.new(0.5, 0.5, 4.7), CFrame.new(x + s, y, z), C.Bois, M.Bois, "Ceinture"))
		end
		local sx = if k % 2 == 0 then -2 else 2
		segment(g, Vector3.new(x + sx, y - 7, z - 2), Vector3.new(x + sx, y, z + 2), 0.4, C.Bois, M.Bois, "Croisillon")
	end
	-- échelle sur la face extérieure et palier en haut
	for _, sx in {-0.8, 0.8} do
		O.decor(O.bloc(g, Vector3.new(0.25, H, 0.25), CFrame.new(x + sx, y0 + H / 2, z + 2.45), C.Bois, M.Bois, "Montant"))
	end
	for y = y0 + 1, yb - 0.5, 1.2 do
		O.decor(O.bloc(g, Vector3.new(1.8, 0.18, 0.18), CFrame.new(x, y, z + 2.45), C.BoisClair, M.Bois, "Barreau"))
	end
	O.bloc(g, Vector3.new(4.6, 0.4, 4.6), CFrame.new(x, yb - 0.2, z), C.Bois, M.Planches, "Palier")
	-- échelle grimpable : poutrelle invisible (escalade Roblox standard) devant les barreaux, du sol jusqu'au palier ;
	-- elle dépasse d'un stud pour basculer naturellement sur le palier
	local hauteur = 2 * math.ceil((H + 1) / 2)
	local truss = Instance.new("TrussPart")
	truss.Name = "EchelleGrimpable"
	truss.Anchored, truss.CanCollide, truss.CanTouch = true, true, false
	truss.Transparency = 1
	truss.CastShadow = false
	truss.Size = Vector3.new(2, hauteur, 2)
	truss.CFrame = CFrame.new(x, y0 + hauteur / 2, z + 3.4)
	truss.Parent = g
	lanterne(g, CFrame.new(x + 2.6, y0 + 12, z + 2.6), 16)
end

-- Treuil au bord de la plateforme est : tambour, potence, corde et seau suspendu dans le vide
local function treuil(m, cx, cz, yb)
	local g = O.modele(m, "Treuil")
	for _, dz in {2.2, 4.8} do
		O.decor(O.bloc(g, Vector3.new(0.6, 2.2, 0.6), CFrame.new(cx + 1, yb + 1.1, cz + dz), C.BoisFonce, M.Bois, "Support"))
	end
	O.decor(O.disque(g, 2.6, 1.5, CFrame.new(cx + 1, yb + 1.9, cz + 3.5) * CFrame.Angles(0, math.pi / 2, 0), C.Bois, M.Bois, "Tambour"))
	O.decor(O.bloc(g, Vector3.new(0.6, 6, 0.6), CFrame.new(cx + 5.4, yb + 3, cz + 3.5), C.BoisFonce, M.Bois, "Mat"))
	segment(g, Vector3.new(cx + 5.4, yb + 5.8, cz + 3.5), Vector3.new(cx + 10, yb + 5.8, cz + 3.5), 0.55, C.BoisFonce, M.Bois, "Potence")
	segment(g, Vector3.new(cx + 1, yb + 2.6, cz + 3.5), Vector3.new(cx + 10, yb + 5.8, cz + 3.5), 0.12, CORDE, M.Tissu, "Corde")
	segment(g, Vector3.new(cx + 10, yb + 5.8, cz + 3.5), Vector3.new(cx + 10, yb - 9, cz + 3.5), 0.12, CORDE, M.Tissu, "Corde")
	O.decor(O.cylindre(g, 1.8, 2, CFrame.new(cx + 10, yb - 9.9, cz + 3.5), C.Bois, M.Planches, "Seau"))
	O.decor(O.cylindre(g, 0.2, 2.15, CFrame.new(cx + 10, yb - 9.2, cz + 3.5), C.Fer, M.Rouille, "Cercle"))
end

local function piliersEtPont(m, rng)
	local y0s = {}
	for i, p in PILIERS do y0s[i] = pilier(m, p.X, p.Z, rng) end
	local yb = math.max(y0s[1], y0s[2]) + HAUTEUR_PONT
	local ouest, est = PILIERS[1], PILIERS[2]
	plateforme(m, ouest.X, ouest.Z, yb, 1, true)
	plateforme(m, est.X, est.Z, yb, -1, false)
	pont(m, Vector3.new(ouest.X + DEMI_PLATEFORME, yb, ouest.Z), Vector3.new(est.X - DEMI_PLATEFORME, yb, est.Z), rng)
	echafaudage(m, ouest.X, ouest.Z + DEMI_PLATEFORME + 2.3, y0s[1], yb)
	treuil(m, est.X, est.Z, yb)
end

-- ================= Faille et rayons de lumière =================

local function rayon(m, a, b, l0, l1, transparence)
	local pa = ancre(m, CFrame.new(a), nil, "RayonHaut")
	local pb = ancre(m, CFrame.new(b), nil, "RayonBas")
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = pa, pb
	local faisceau = Instance.new("Beam")
	faisceau.Name = "RayonLumiere"
	faisceau.Attachment0, faisceau.Attachment1 = a0, a1
	faisceau.Width0, faisceau.Width1 = l0, l1
	faisceau.FaceCamera = true
	faisceau.Segments = 1
	faisceau.Color = ColorSequence.new(PALE)
	faisceau.LightEmission = 0.5
	faisceau.LightInfluence = 0
	faisceau.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.97), NumberSequenceKeypoint.new(0.12, transparence),
		NumberSequenceKeypoint.new(0.85, transparence + 0.04), NumberSequenceKeypoint.new(1, 0.99),
	})
	faisceau.Parent = pa
end

-- Faille dans la voûte : rayons de lumière et poussière qui tombent au centre de la caverne
local function faille(m)
	local c = D.CAVERNE_CENTRE
	local y = sol(c.X, c.Z)
	local base = CFrame.new(c.X, y, c.Z)
	local fx, fz = c.X - 6, c.Z - 5
	local yHaut = plafond(fx, fz, y)
	if not yHaut then return end
	local haut = Vector3.new(fx, yHaut - 0.8, fz)
	local dirF = Vector3.new(1, 0, 0.45).Unit
	for k = -2, 2 do
		local p = haut + dirF * (k * 3.4) + Vector3.new(0, 0, (k % 2) * 0.8)
		local cf = CFrame.lookAt(p, p + dirF) * CFrame.Angles(0, (k % 2 - 0.5) * 0.3, 0)
		local lg = 3.8 - math.abs(k) * 0.5
		O.decor(O.bloc(m, Vector3.new(0.9 - math.abs(k) * 0.15, 0.6, lg), cf, terne(PALE, 0.25), M.Neon, "Faille")).CastShadow = false
		for _, s in {-1, 1} do
			O.decor(O.bloc(m, Vector3.new(1.6, 1.6, lg + 0.4), cf * CFrame.new(s * 1.1, -0.3, 0) * CFrame.Angles(0, 0, s * 0.4), C.PierreFoncee, M.Roche, "Levre"))
		end
	end
	for k = -1, 1 do
		rayon(m, haut + dirF * (k * 3) + Vector3.new(0, -1, 0), base.Position + Vector3.new(k * 2.5 - 1, 0.3, k * 1.2), 3 + math.abs(k), 9 - math.abs(k) * 2, 0.86 + math.abs(k) * 0.04)
	end
	local H = yHaut - y
	local volume = ancre(m, CFrame.new((haut + base.Position) / 2), Vector3.new(7, H * 0.85, 7), "Poussiere")
	local poussiere = O.lucioles(volume, PALE, 6)
	poussiere.Speed = NumberRange.new(0.1, 0.4)
	poussiere.Acceleration = Vector3.new(0, -0.25, 0)
	poussiere.Lifetime = NumberRange.new(6, 10)
	-- lumière douce qui descend de la faille
	local source = ancre(m, CFrame.lookAt(base.Position + Vector3.new(-2, math.min(45, H - 2), -2), base.Position, Vector3.xAxis), nil, "SourceFaille")
	local spot = Instance.new("SpotLight")
	spot.Color, spot.Brightness, spot.Range, spot.Angle, spot.Shadows = PALE, 1.2, 55, 40, false
	spot.Parent = source
end

-- ================= Frise de runes au-dessus des portes =================

local function frise(m)
	local c = D.CAVERNE_CENTRE
	local y = D.CAVERNE_SOL + 27
	local precedent
	for k = -3, 33 do
		local a = math.rad(-62.5 + k * 25 / 6) -- k multiple de 6 : juste au-dessus d'une porte
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local hit = workspace:Raycast(Vector3.new(c.X, y, c.Z) + dir * 50, dir * 30, params)
		if not hit then precedent = nil; continue end
		local p = hit.Position - dir * 0.3
		local cf = CFrame.lookAt(p, p - dir) -- -Z vers le centre
		local porte = k % 6 == 0
		local pierre = O.decor(O.bloc(m, if porte then Vector3.new(4.6, 4.2, 1.3) else Vector3.new(3.8, 2.6, 1),
			cf, if porte then C.PierreClaire:Lerp(C.PierreFoncee, 0.35) else Color3.fromRGB(74, 70, 76), M.Ardoise, "Frise"))
		local devant = cf * CFrame.new(0, 0, -pierre.Size.Z / 2 - 0.04)
		local rune = terne(BLEU, 0.5)
		if porte then
			O.decor(O.bloc(m, Vector3.new(1.5, 1.5, 0.3), devant * CFrame.Angles(0, 0, math.pi / 4), terne(BLEU, 0.35), M.Neon, "Oeil"))
			O.decor(O.bloc(m, Vector3.new(3.6, 0.16, 0.1), devant * CFrame.new(0, -1.6, 0), rune, M.Neon, "Rune"))
		elseif k % 3 == 0 then
			O.decor(O.bloc(m, Vector3.new(0.8, 0.8, 0.1), devant * CFrame.Angles(0, 0, math.pi / 4), rune, M.Neon, "Rune"))
		else
			O.decor(O.bloc(m, Vector3.new(2.2, 0.18, 0.1), devant, rune, M.Neon, "Rune"))
			O.decor(O.bloc(m, Vector3.new(0.18, 0.9, 0.1), devant * CFrame.new(if k % 2 == 0 then -0.6 else 0.6, 0.2, 0), rune, M.Neon, "Rune"))
		end
		local bas = (cf * CFrame.new(0, -1.6, -0.2)).Position
		if precedent then segment(m, precedent, bas, 0.14, terne(BLEU, 0.6), M.Neon, "LigneGravee") end
		precedent = bas
	end
end

-- ================= Bassin et cascade =================

local function bassin(m, rng)
	local y0 = sol(BASSIN.X, BASSIN.Z)
	local centre = Vector3.new(BASSIN.X, y0, BASSIN.Z)
	local pied = Vector3.new(CASCADE.X, y0, CASCADE.Z)
	local cfC = CFrame.lookAt(pied, centre) -- -Z vers le bassin
	local H = math.min((plafond(CASCADE.X, CASCADE.Z, y0) or (y0 + 36)) - y0, 50) + 4
	terrain:FillCylinder(CFrame.new(centre - Vector3.new(0, 4, 0)), 8, 10.5, Enum.Material.Water)
	terrain:FillBlock(cfC * CFrame.new(0, H / 2 - 6, 4.5), Vector3.new(14, H + 4, 6), Enum.Material.Rock) -- paroi derrière la chute
	terrain:FillBlock(cfC * CFrame.new(0, H / 2 - 6, 0), Vector3.new(8, H + 4, 4), Enum.Material.Water)

	local g = O.modele(m, "Cascade")
	local versCascade = (pied - centre).Unit
	for k = 0, 17 do
		local a = k * math.pi * 2 / 18
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		if d:Dot(versCascade) < 0.8 then
			local s = rng:NextNumber(1.4, 2.8)
			O.decor(O.bloc(g, Vector3.new(s * 1.3, s * 0.6, s), CFrame.new(centre + d * 11 + Vector3.new(0, s * 0.15, 0))
				* CFrame.Angles(rng:NextNumber(-0.2, 0.2), -a, rng:NextNumber(-0.2, 0.2)), ROCHE:Lerp(C.PierreFoncee, rng:NextNumber(0.2, 0.8)), M.Roche, "Margelle"))
		end
	end
	-- écume qui tombe du haut, éclaboussures et brume au pied
	local haut = ancre(g, cfC * CFrame.new(0, H - 9, -2.6), Vector3.new(6, 1, 1), "Ecume")
	emetteur(haut, {
		Name = "Chute", Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(210, 232, 236)),
		Size = NumberSequence.new(1.4, 3.2), Transparency = NumberSequence.new(0.62, 1), Lifetime = NumberRange.new(1.3, 1.7),
		Rate = 22, Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(6, 6), Acceleration = Vector3.new(0, -36, 0),
		EmissionDirection = Enum.NormalId.Bottom, Shape = Enum.ParticleEmitterShape.Box, LightInfluence = 0.6,
	})
	local bas = ancre(g, cfC * CFrame.new(0, 0.8, -3), Vector3.new(7, 1, 3), "Remous")
	O.brume(bas, Color3.fromRGB(170, 205, 210), 4)
	O.etincelles(bas, Color3.fromRGB(190, 230, 235), 10).LightEmission = 0.4
	O.lumiere(ancre(g, CFrame.new(centre + Vector3.new(0, 4, 0)), nil, "LueurBassin"), TURQUOISE, 1, 30)
end

-- ================= Champignons, racines, stalagmites =================

local function champignons(m, x, z, rng, couleur)
	local y = sol(x, z)
	local g = O.modele(m, "Champignons")
	local premier
	for k = 1, rng:NextInteger(3, 5) do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = if k == 1 then 0 else rng:NextNumber(0.9, 2.4)
		local h = if k == 1 then rng:NextNumber(2.4, 3.4) else rng:NextNumber(0.8, 2)
		local pied = CFrame.new(x + math.cos(a) * r, y, z + math.sin(a) * r) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))
		O.decor(O.cylindre(g, h, math.max(0.3, h * 0.2), pied * CFrame.new(0, h / 2, 0), Color3.fromRGB(196, 186, 170), M.Lisse, "Pied"))
		local chapeau = O.decor(O.ellipsoide(g, Vector3.new(h * 0.9, h * 0.38, h * 0.9), pied * CFrame.new(0, h, 0), terne(couleur, 0.45), M.Neon, "Chapeau"))
		chapeau.CastShadow = false
		premier = premier or chapeau
	end
	O.lumiere(premier, couleur, 0.9, 12)
end

local function racines(m, rng)
	local n = 0
	for _ = 1, 80 do
		if n >= 16 then break end
		local x, z = rng:NextNumber(-95, 95), rng:NextNumber(-475, -358)
		if dansCaverne(x, z, 6) and not dansCaverne(x, z, 22) then
			local y0 = sol(x, z)
			local yP = plafond(x, z, y0)
			if yP and yP - y0 > 24 and yP - y0 < 80 then
				n += 1
				local g = O.modele(m, "Racine")
				local p = Vector3.new(x, yP + 1, z)
				local L = rng:NextNumber(6, 15)
				for i = 1, 4 do
					local q = p + Vector3.new(rng:NextNumber(-0.8, 0.8), -L / 4, rng:NextNumber(-0.8, 0.8))
					segment(g, p, q, 0.65 - i * 0.1, C.Tronc:Lerp(C.BoisFonce, rng:NextNumber()), M.Bois, "Racine")
					p = q
				end
				if rng:NextNumber() < 0.45 then
					O.decor(O.ellipsoide(g, Vector3.new(0.6, 0.8, 0.6), CFrame.new(p), terne(TURQUOISE, 0.45), M.Neon, "Bourgeon")).CastShadow = false
				end
			end
		end
	end
end

local function stalagmites(m, rng)
	local n = 0
	for _ = 1, 160 do
		if n >= 18 then break end
		local x, z = rng:NextNumber(-100, 100), rng:NextNumber(-495, -355)
		if dansCaverne(x, z, 3) and not dansCaverne(x, z, 13) and libre(x, z) then
			local y0 = sol(x, z)
			if math.abs(y0 - D.CAVERNE_SOL) < 4 then
				n += 1
				local g = O.modele(m, "Stalagmite")
				for j = 1, rng:NextInteger(1, 2) do
					local h = rng:NextNumber(4, 12) / j
					local w = h * rng:NextNumber(0.3, 0.42)
					local bx, bz = x + (j - 1) * rng:NextNumber(-2.5, 2.5), z + (j - 1) * rng:NextNumber(-2.5, 2.5)
					local rot = CFrame.Angles(rng:NextNumber(-0.08, 0.08), rng:NextNumber(0, math.pi), rng:NextNumber(-0.08, 0.08))
					local bas = y0 - 0.5
					for k = 0, 2 do
						local l = h * (0.45 - k * 0.1)
						local e = w * (1 - k * 0.3)
						O.decor(O.bloc(g, Vector3.new(e, l, e), CFrame.new(bx, bas + l / 2, bz) * rot, ROCHE:Lerp(C.Roche, rng:NextNumber()), M.Roche, "Stalagmite"))
						bas += l - 0.3
					end
				end
			end
		end
	end
end

-- ================= Vieux rails et wagonnets =================

local function railsAbandonnes(m, rng)
	local g = O.modele(m, "RailsAbandonnes")
	local pts = {}
	for i, p in RAILS do pts[i] = Vector3.new(p.X, sol(p.X, p.Z), p.Z) end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local L = (b - a).Magnitude
		local base = CFrame.lookAt(a, b)
		for _, x in {-2.5, 2.5} do
			O.decor(O.bloc(g, Vector3.new(0.35, 0.45, L + 0.5), base * CFrame.new(x, 0.75, -L / 2), Color3.fromRGB(87, 68, 54), M.Rouille, "Rail"))
		end
		for j = 0, math.floor(L / 2.2) do
			if rng:NextNumber() > 0.15 then
				O.decor(O.bloc(g, Vector3.new(7.4, 0.5, 1.1), base * CFrame.new(0, 0.25, -j * 2.2) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0),
					C.BoisFonce:Lerp(C.Bois, rng:NextNumber()), M.Planches, "Traverse"))
			end
		end
	end
	local fin = pts[#pts]
	local dir = (fin - pts[#pts - 1]).Unit
	O.decorModele(B.butoir(g, CFrame.lookAt(fin, fin - dir)))
	-- wagonnet oublié sur la voie, chargé d'éclats de cristal
	local a, b = pts[3], pts[4]
	local wagon = O.decorModele(B.wagonnet(g, CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, 0, math.rad(4))))
	for k = 1, 4 do
		eclat(wagon, CFrame.lookAt((a + b) / 2, b) * CFrame.new(rng:NextNumber(-1.5, 1.5), 4.6, rng:NextNumber(-2, 2)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)),
			rng:NextNumber(1.4, 2.4), if k % 2 == 0 then BLEU else VIOLET)
	end
	-- wagonnet renversé au bout de la voie, éclats répandus
	local pos = Vector3.new(42, sol(42, -396), -396)
	O.decorModele(B.wagonnet(g, CFrame.new(pos + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, 0.7, math.rad(84)) * CFrame.new(0, -3.1, 0)))
	for k = 1, 5 do
		local q = pos + Vector3.new(rng:NextNumber(-5, 0), 0, rng:NextNumber(-1, 4))
		eclat(g, CFrame.new(Vector3.new(q.X, sol(q.X, q.Z) - 0.2, q.Z)) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 3), rng:NextNumber(-0.6, 0.6)),
			rng:NextNumber(1, 2.2), if k % 2 == 0 then BLEU else VIOLET)
	end
	O.lumiere(ancre(g, CFrame.new(pos + Vector3.new(-2, 1.5, 1)), nil, "LueurEclats"), BLEU, 0.8, 12)
end

-- ================= Sanctuaire du grand cristal =================

local function sanctuaire(m, rng)
	local cx, cz = D.CRISTAL_CAVERNE.X, D.CRISTAL_CAVERNE.Z
	local y = sol(cx, cz)
	local base = CFrame.new(cx, y, cz)
	local g = O.modele(m, "SanctuaireCristal")
	for k = 0, 35 do
		O.decor(O.bloc(g, Vector3.new(2.2, 0.08, 0.3), base * CFrame.Angles(0, k * math.pi / 18, 0) * CFrame.new(0, 0.2, -14), terne(VIOLET, 0.55), M.Neon, "CercleRunes"))
	end
	for k = 0, 5 do
		local a = k * math.pi / 3 + 0.3
		local px, pz = cx + math.sin(a) * 19, cz - math.cos(a) * 19
		if dansCaverne(px, pz, 4) then
			local py = sol(px, pz)
			local cf = CFrame.lookAt(Vector3.new(px, py, pz), Vector3.new(cx, py, cz)) * CFrame.Angles(rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.06, 0.06))
			local h = rng:NextNumber(6.5, 8.5)
			O.bloc(g, Vector3.new(2.6, h, 1.5), cf * CFrame.new(0, h / 2 - 0.5, 0), Color3.fromRGB(70, 66, 76):Lerp(ROCHE, rng:NextNumber(0, 0.4)), M.Ardoise, "Menhir")
			O.decor(O.bloc(g, Vector3.new(3, 0.7, 1.9), cf * CFrame.new(0, h - 0.4, 0) * CFrame.Angles(0, 0, rng:NextNumber(-0.1, 0.1)), C.PierreFoncee, M.Ardoise, "Chapeau"))
			local face = cf * CFrame.new(0, 0, -0.8)
			O.decor(O.bloc(g, Vector3.new(0.2, h * 0.45, 0.1), face * CFrame.new(0, h * 0.42, 0), terne(VIOLET, 0.5), M.Neon, "Rune"))
			O.decor(O.bloc(g, Vector3.new(0.7, 0.7, 0.1), face * CFrame.new(0, h * 0.72, 0) * CFrame.Angles(0, 0, math.pi / 4), terne(VIOLET, 0.4), M.Neon, "Rune"))
		end
	end
	-- halo de pierres runiques au-dessus de la pointe, éclats en orbite (animés côté client)
	local halo = O.modele(m, "HaloCristal")
	for k = 0, 11 do
		local cf = base * CFrame.new(0, 31, 0) * CFrame.Angles(0, k * math.pi / 6, 0) * CFrame.new(0, 0, -7.5)
		O.decor(O.bloc(halo, Vector3.new(1.6, 1, 0.8), cf, Color3.fromRGB(70, 66, 76), M.Ardoise, "PierreHalo"))
		O.decor(O.bloc(halo, Vector3.new(0.9, 0.14, 0.1), cf * CFrame.new(0, 0, -0.45), terne(VIOLET, 0.45), M.Neon, "Rune"))
	end
	halo.WorldPivot = base * CFrame.new(0, 31, 0)
	halo:SetAttribute("Amplitude", 0.5)
	O.tag(O.atomique(halo), "Flottant")
	local orbite = O.modele(m, "OrbiteCristal")
	for k = 0, 4 do
		local a = k * math.pi * 2 / 5
		eclat(orbite, base * CFrame.Angles(0, a, 0) * CFrame.new(0, rng:NextNumber(14, 22), -15) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)),
			rng:NextNumber(1.8, 3.2), if k % 2 == 0 then VIOLET else BLEU)
	end
	orbite.WorldPivot = base * CFrame.new(0, 18, 0)
	orbite:SetAttribute("Amplitude", 1.2)
	O.tag(O.atomique(orbite), "Flottant")
end

-- ================= Construction =================

-- Caverne : aucun minerai (anciens wagonnets chargés) et lumières plafonnées à LUMIERE_MAX (hors lanternes animées)
local ANCIEN_WAGON = Vector3.new(16, 0, -410) -- wagonnet posé au milieu, devant le quai (retiré)
local function adoucir(caverne)
	for _, objet in caverne:GetChildren() do
		if objet:IsA("Model") and objet.Name == "Wagonnet" and not objet:GetAttribute("WagonRetour") then
			local p = objet:GetPivot().Position
			if Vector3.new(p.X - ANCIEN_WAGON.X, 0, p.Z - ANCIEN_WAGON.Z).Magnitude < 4 then objet:Destroy() end
		end
	end
	for _, d in caverne:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Minerai" then
			d:Destroy()
		elseif d:IsA("PointLight") and d.Brightness > LUMIERE_MAX and not CollectionService:HasTag(d, "LueurLanterne") then
			d.Brightness = LUMIERE_MAX
		end
	end
end

local function construire(mine)
	local m = O.modele(mine, "DecorCaverne")
	local rng = Random.new(1717)
	piliersEtPont(m, rng)
	task.wait()
	faille(m)
	frise(m)
	task.wait()
	bassin(m, rng)
	for _, c in {
		{-40, -378, TURQUOISE}, {-23, -371, BLEU}, {19, -380, TURQUOISE}, {25, -377, VIOLET},
		{52, -369, TURQUOISE}, {73, -386, BLEU}, {56, -391, TURQUOISE}, {-88, -392, VIOLET}, {-82, -418, BLEU},
	} do
		champignons(m, c[1], c[2], rng, c[3])
	end
	for k = 0, 4 do -- entre les portes des tunnels
		local a = math.rad(-50 + k * 25)
		champignons(m, math.sin(a) * 63, D.CAVERNE_CENTRE.Z - math.cos(a) * 63, rng, if k % 2 == 0 then BLEU else TURQUOISE)
	end
	task.wait()
	racines(m, rng)
	stalagmites(m, rng)
	task.wait()
	railsAbandonnes(m, rng)
	sanctuaire(m, rng)
	-- lumières d'ambiance très douces par zone (bleu au nord, ambre à l'arrivée, turquoise à l'est, violet à l'ouest)
	for _, l in {
		{Vector3.new(0, 28, -455), BLEU, 0.6, 60}, {Vector3.new(0, 18, -392), AMBRE, 0.5, 45},
		{Vector3.new(58, 18, -390), TURQUOISE, 0.55, 45}, {Vector3.new(-62, 20, -405), VIOLET, 0.5, 45},
	} do
		O.lumiere(ancre(m, CFrame.new(l[1] + Vector3.new(0, D.CAVERNE_SOL, 0)), nil, "Ambiance"), l[2], l[3], l[4])
	end
	m:SetAttribute("Version", VERSION) -- seulement après succès
end

-- Construit le décor de la caverne (carte neuve), ou l'ajoute / le met à jour une seule fois (carte figée).
function CaverneDecor.preparer(mine)
	local caverne = mine:FindFirstChild("Caverne")
	if caverne then adoucir(caverne) end
	local existant = mine:FindFirstChild("DecorCaverne")
	if existant and existant:GetAttribute("Version") == VERSION then return end
	if existant then existant:Destroy() end
	construire(mine)
end

return CaverneDecor
