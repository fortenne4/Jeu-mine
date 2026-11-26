-- Mise en scène de la grande caverne de cristal (décor seulement, AUCUN minerai) :
--  • deux piliers de roche naturels qui encadrent l'arrivée, reliés par un pont suspendu (plateformes, échafaudage,
--    échelle, treuil, lanternes) ;
--  • une faille dans la voûte d'où tombent des rayons de lumière et de la poussière au centre ;
--  • une frise de runes gravée au-dessus des portes des tunnels privés ;
--  • sous une voûte creusée dans le lobe est : un point d'eau rond en Parts (rayon 12, hauteur mesurée au raycast,
--    bord de pierres), une cascade en Parts contre la paroi (écume, brume, son) et un petit ponton de bois avec une canne
--    (1 invite « Pêcher » de PecheGrotte.server.lua, ouverte à tous, 1 pièce par prise) ; paroi sud-est reculée ;
--  • « TUNNELS PRIVÉS » en lettres flottantes (tag « TexteFlottant », animé par AmbianceCaverne.client.lua) ;
--  • autour du grand cristal : cercle de runes, menhirs, halo de pierres et éclats qui flottent en tournant
--    (tag « Flottant », animé côté client par Animations.client.lua) ;
--  • champignons lumineux, racines qui pendent, stalagmites, vieux rails et wagonnets renversés, torches vers les grottes.
-- Lumières douces : PointLight ≤ 1,5 et néons assombris (pas d'éblouissement en entrant sous terre).
-- Tout est dans Mine › DecorCaverne (attribut Version) : construit avec la carte, ou ajouté une seule fois à une
-- carte figée (Mine.preparerVoie). Décor sans collision, sauf les piliers, les menhirs, le wagonnet et le parcours en hauteur :
-- échelle grimpable (TrussPart invisible) → plateforme du pilier ouest → pont suspendu → plateforme du pilier est.
local CollectionService = game:GetService("CollectionService")
local D = require(script.Parent.Disposition)
local O = require(script.Parent.Outils)
local B = require(script.Parent.Batiments)
local M, C = O.M, O.C

local CaverneDecor = {}
local reculerParoi, texteTunnels, presDuLac -- définies plus bas
local PANNEAU_TUNNELS = Vector3.new(0, D.CAVERNE_SOL, -470) -- ancien panneau des tunnels privés (Mine.lua)
local terrain = workspace.Terrain

local VERSION = 9 -- 2 : pont et échelle praticables, rose / poteau / torches retirés ; 3 : quai dégagé (stalagmite retirée) ;
-- 4 : fontaine de cristal et coin pêche ; 5 : bassin profond sans fontaine, paroi reculée, texte flottant ;
-- 6 : grand bassin organique (rayon ~23), 3 pontons surélevés, décor posé au raycast
-- 8 : l'eau Terrain (invisible) est retirée : point d'eau et cascade en Parts, un seul petit ponton ;
-- 9 : cascade avancée dans l'eau, corniche solide, Beams qui défilent, vue dégagée depuis le ponton
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
local BASSIN = Vector3.new(70, 0, -368) -- centre du grand bassin (lobe est, élargi vers l'est)
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

local function reglerSonCascade(son: Sound)
	son.Volume = 0.25
	son.RollOffMode = Enum.RollOffMode.LinearSquare
	son.RollOffMinDistance = 12
	son.RollOffMaxDistance = 82
end

local function replacerCristalDuBassin(caverne)
	-- Amas violet presque horizontal dans la paroi, à gauche du point d'eau depuis le ponton.
	local ancien = Vector3.new(81, -55, -379)
	for _, objet in caverne:GetChildren() do
		if objet:IsA("Model") and objet.Name == "Cristal" and objet.PrimaryPart then
			local coeur = objet.PrimaryPart
			if (coeur.Position - ancien).Magnitude < 6 and math.abs(coeur.CFrame.UpVector.Y) < 0.5 then
				local x, z = 79, -384
				local pied = CFrame.new(x, sol(x, z) - 0.3, z) * CFrame.Angles(math.rad(9), math.rad(-20), math.rad(-7))
				objet:PivotTo(pied * CFrame.new(0, coeur.Size.Y / 2, 0))
				return
			end
		end
	end
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
	{D.CRISTAL_CAVERNE.X, D.CRISTAL_CAVERNE.Z, 23}, {BASSIN.X, BASSIN.Z, 31}, {-44, -404, 6}, {24, -396, 6}, {16, -410, 7},
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
			local bosse = O.bloc(g, Vector3.new(s, h * 0.8, s), CFrame.new(x + math.cos(a) * w * 0.45, y0 + t * H, z + math.sin(a) * w * 0.45)
				* CFrame.Angles(rng:NextNumber(-0.3, 0.3), a, rng:NextNumber(-0.3, 0.3)), ROCHE:Lerp(C.Roche, rng:NextNumber()), M.Roche, "Bosse")
			bosse.CanCollide = roche.CanCollide -- solide (on peut grimper), sauf à hauteur de plateforme
			bosse.CanTouch = false
		end
	end
	-- éboulis au pied
	for _ = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local s = rng:NextNumber(1.2, 2.6)
		O.decor(O.bloc(g, Vector3.new(s, s * 0.7, s), CFrame.new(x + math.cos(a) * 7.5, sol(x + math.cos(a) * 7.5, z + math.sin(a) * 7.5) + s * 0.2, z + math.sin(a) * 7.5)
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

-- ================= Voûte, point d'eau, cascade et coin pêche =================

local R_LAC = 23        -- rayon de la voûte creusée (sol de roche à plat sous la voûte)
local Y_LAC = D.CAVERNE_SOL -- sol sous la voûte
local PAS_LAC = 4       -- taille des voxels du terrain
local AVANCEES = {{0.9, 6}, {2.7, 5}, {4.5, 7}} -- avancées de roche : angle (rad), longueur (studs)
local ANCIEN_BASSIN = Vector3.new(62, 0, -377) -- petit bassin des versions 1 à 5 (rebouché)
local R_POINT = 12      -- rayon du point d'eau
local A_CASCADE = 0.15  -- direction de la cascade depuis le centre de la voûte (paroi est)
local EAU = Color3.fromRGB(70, 200, 205)
local EAU_FOND = Color3.fromRGB(12, 58, 70)
local MOUILLE = Color3.fromRGB(62, 48, 38)
local centrePoint = nil -- centre du point d'eau, une fois construit (champignons)

local function rayonLac(a)
	local r = R_LAC * (1 + 0.1 * math.sin(3 * a + 0.7) + 0.06 * math.sin(5 * a + 2.1))
	for _, av in AVANCEES do
		local d = math.abs((a - av[1] + math.pi) % (2 * math.pi) - math.pi)
		if d < 0.32 then r -= av[2] * (1 - d / 0.32) end
	end
	return r
end

-- Passages, rails, pilier, portail des grottes et ses braseros : jamais creusés
local function protege(x, z)
	if z < -392 then return true end -- dalle, cercles et braseros de l'entrée des grottes
	for _, l in LIBRES do
		if l[1] ~= BASSIN.X or l[2] ~= BASSIN.Z then
			local dx, dz = x - l[1], z - l[2]
			local r = l[3] + 3
			if dx * dx + dz * dz < r * r then return true end
		end
	end
	return false
end

local function dansLac(x, z)
	local dx, dz = x - BASSIN.X, z - BASSIN.Z
	return math.sqrt(dx * dx + dz * dz) < rayonLac(math.atan2(dz, dx)) and not protege(x, z)
end

-- Pas de champignons dans le point d'eau ni sur son bord
presDuLac = function(x, z)
	return centrePoint ~= nil and Vector2.new(x - centrePoint.X, z - centrePoint.Z).Magnitude < R_POINT + 4
end

-- Distance jusqu'où la voûte est creusée dans une direction
local function rayonBerge(a)
	local u = Vector3.new(math.cos(a), 0, math.sin(a))
	local r = 0
	while r < R_LAC * 1.3 and dansLac(BASSIN.X + u.X * (r + 1), BASSIN.Z + u.Z * (r + 1)) do r += 1 end
	return r
end

-- Voûte d'air et sol de roche à plat (colonnes de 4 studs), avancées de roche. L'eau n'est plus en terrain :
-- on retire toute l'eau Terrain des versions 6 et 7 (cachée dans la roche) et l'ancien bloc d'eau de la cascade.
local function creuserVoute()
	terrain:FillCylinder(CFrame.new(ANCIEN_BASSIN.X, Y_LAC - 11, ANCIEN_BASSIN.Z), 22, 16, Enum.Material.Rock)
	local etendue = R_LAC * 1.2 + 6
	for x = BASSIN.X - etendue, BASSIN.X + etendue, PAS_LAC do
		for z = BASSIN.Z - etendue, BASSIN.Z + etendue, PAS_LAC do
			local dx, dz = x - BASSIN.X, z - BASSIN.Z
			local d = math.sqrt(dx * dx + dz * dz)
			local r = rayonLac(math.atan2(dz, dx))
			if d < r + 6 and not protege(x, z) then
				local h = 6 + 22 * math.sqrt(math.max(0, 1 - (d / (r + 6)) ^ 2))
				terrain:FillBlock(CFrame.new(x, Y_LAC + h / 2, z), Vector3.new(PAS_LAC, h, PAS_LAC), Enum.Material.Air)
				terrain:FillCylinder(CFrame.new(x, Y_LAC - 12, z), 24, PAS_LAC * 0.73, Enum.Material.Rock)
			end
		end
		task.wait()
	end
	for _, av in AVANCEES do
		local r = rayonLac(av[1])
		local p = BASSIN + Vector3.new(math.cos(av[1]) * r, Y_LAC + 1, math.sin(av[1]) * r)
		if not protege(p.X, p.Z) then
			terrain:FillBall(p, 3.4, Enum.Material.Rock)
			terrain:FillBall(p - Vector3.new(math.cos(av[1]), 0, math.sin(av[1])) * 3, 2.4, Enum.Material.Rock)
		end
	end
	local bord = Vector3.new(etendue + 8, 0, etendue + 8)
	local zone = Region3.new(Vector3.new(BASSIN.X, Y_LAC - 40, BASSIN.Z) - bord, Vector3.new(BASSIN.X, Y_LAC + 60, BASSIN.Z) + bord)
	pcall(function() terrain:ReplaceMaterial(zone:ExpandToGrid(4), 4, Enum.Material.Water, Enum.Material.Air) end)
end

-- Hauteur du sol réel (terrain) sous un point ; nil si rien trouvé
local function solReel(x, z, depuis)
	local r = workspace:Raycast(Vector3.new(x, depuis, z), Vector3.new(0, -30, 0), params)
	return r and r.Position.Y
end

-- Point d'eau en Parts (ne dépend pas de l'eau Terrain), cuvette creusée, bord de pierres, cascade, ponton, canne
local function bassin(m, rng)
	creuserVoute()
	local u = Vector3.new(math.cos(A_CASCADE), 0, math.sin(A_CASCADE))
	local pied = BASSIN + u * (rayonBerge(A_CASCADE) + 1.5)
	pied = Vector3.new(pied.X, Y_LAC, pied.Z)
	local centre = pied - u * (R_POINT - 1) -- centre du point d'eau : la cascade tombe sur son bord
	centrePoint = centre
	-- cuvette : 4 studs au bord, 7 au centre
	terrain:FillCylinder(CFrame.new(centre.X, Y_LAC - 2, centre.Z), 4, R_POINT + 0.5, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(centre.X, Y_LAC - 5.5, centre.Z), 3, R_POINT - 4, Enum.Material.Air)

	-- hauteurs mesurées sur le terrain réel : bord (médiane autour) et fond
	local bords = {}
	for k = 0, 7 do
		local a = k * math.pi / 4
		table.insert(bords, solReel(centre.X + math.cos(a) * (R_POINT + 2.5), centre.Z + math.sin(a) * (R_POINT + 2.5), Y_LAC + 6) or Y_LAC)
	end
	table.sort(bords)
	local yBord = (bords[4] + bords[5]) / 2
	local yFond = solReel(centre.X, centre.Z, Y_LAC + 6) or (yBord - 6)
	local yEau = math.max(yFond + 1, yBord - 0.6) -- surface de l'eau

	local g = O.modele(m, "PointEau")
	local surface = O.decor(O.cylindre(g, 0.2, R_POINT * 2 + 0.6, CFrame.new(centre.X, yEau - 0.1, centre.Z), EAU, M.Verre, "Eau"))
	surface.Transparency = 0.35
	surface.Reflectance = 0.15
	surface.CastShadow = false
	local profond = O.decor(O.cylindre(g, 0.2, R_POINT * 2 - 1, CFrame.new(centre.X, math.max(yFond + 0.2, yEau - 2.2), centre.Z), EAU_FOND, M.Lisse, "EauProfonde"))
	profond.Transparency = 0.1
	profond.CastShadow = false

	-- Bord de pierres (posées sur le sol réel), ouvert devant la cascade et pour le ponton
	local versPonton = -u
	for k = 0, 23 do
		local a = k * math.pi / 12 + rng:NextNumber(-0.05, 0.05)
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local s = rng:NextNumber(1.4, 2.4)
		if d:Dot(u) < 0.85 and d:Dot(versPonton) < 0.93 then
			local p = centre + d * (R_POINT + 0.9)
			local y = solReel(p.X, p.Z, Y_LAC + 6) or yBord
			O.bloc(g, Vector3.new(s * 1.3, s * 0.65, s), CFrame.new(p.X, y + s * 0.12, p.Z) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), -a, rng:NextNumber(-0.15, 0.15)),
				ROCHE:Lerp(C.PierreFoncee, rng:NextNumber(0.2, 0.7)), M.Roche, "PierreBord").CanTouch = false
		end
	end

	O.lumiere(ancre(g, CFrame.new(centre.X, yEau + 5, centre.Z), nil, "LueurPoint"), TURQUOISE, 1, 26)

	-- Petit ponton en bois face à la cascade : plancher 1,5 stud au-dessus de l'eau, pilotis jusqu'au fond, une canne
	local origine = centre - u * R_POINT -- bord de l'eau côté caverne
	local P = CFrame.lookAt(Vector3.new(origine.X, yEau, origine.Z), Vector3.new(centre.X, yEau, centre.Z)) -- -Z au-dessus de l'eau
	local function a(x, y, z) return P * CFrame.new(x, y, z) end
	local pont = O.modele(g, "PontonPeche")
	local HAUT = 1.5
	local debut = a(0, 0, 3.2).Position
	local ySol = solReel(debut.X, debut.Z, Y_LAC + 6) or yBord
	local montee = math.max(0.3, yEau + HAUT - ySol)
	local rampe = O.coin(pont, Vector3.new(3.4, montee, 2.4), a(0, ySol - yEau + montee / 2, 2.4) * CFrame.Angles(0, math.pi, 0), C.BoisClair, M.Planches, "Rampe")
	rampe.CanQuery, rampe.CanTouch = false, false
	local planches = {Color3.fromRGB(134, 98, 64), Color3.fromRGB(118, 86, 56), Color3.fromRGB(146, 108, 72)}
	local bout = 1.2
	for i = 0, 7 do
		bout = 1.2 - i * 0.93
		local p = O.bloc(pont, Vector3.new(3.4 + rng:NextNumber(-0.08, 0.08), 0.3, 0.9), a(0, HAUT - 0.15, bout) * CFrame.Angles(0, math.rad(rng:NextNumber(-1.5, 1.5)), 0),
			planches[i % 3 + 1], M.Planches, "Planche")
		p.CanQuery, p.CanTouch = false, false
	end
	for _, x in {-1.3, 1.3} do
		O.decor(O.bloc(pont, Vector3.new(0.4, 0.4, 1.2 - bout + 0.9), a(x, HAUT - 0.5, (1.2 + bout) / 2), MOUILLE, M.Bois, "Longeron"))
		for _, z in {-1, bout + 0.3} do
			local h = a(x, HAUT - 0.3, z).Position
			local b = (solReel(h.X, h.Z, yEau - 0.3) or yFond) - 0.5
			O.decor(O.cylindre(pont, h.Y - b, 0.5, CFrame.new(h.X, (h.Y + b) / 2, h.Z), MOUILLE, M.Bois, "Pieu"))
		end
		O.decor(O.bloc(pont, Vector3.new(0.25, 1.3, 0.25), a(x * 1.25, HAUT + 0.65, bout + 0.3), MOUILLE, M.Bois, "Poteau"))
	end
	-- canne posée dans son support, ligne et bouchon sur l'eau
	local talon = a(1.1, HAUT + 0.35, bout + 1.4).Position
	local scion = a(2.6, HAUT + 3, bout - 2.2).Position
	O.decor(O.bloc(pont, Vector3.new(0.3, 0.7, 0.3), CFrame.new(talon - Vector3.new(0, 0.1, 0)), C.Fer, M.Metal, "Support"))
	segment(pont, talon, scion, 0.12, Color3.fromRGB(92, 64, 40), M.Bois, "Canne")
	O.decor(O.cylindre(pont, 0.25, 0.4, CFrame.lookAt(talon:Lerp(scion, 0.15), scion) * CFrame.Angles(math.pi / 2, 0, 0), C.Fer, M.Metal, "Moulinet"))
	local flotte = Vector3.new(scion.X, yEau + 0.08, scion.Z)
	segment(pont, scion, flotte, 0.03, Color3.fromRGB(235, 235, 235), M.Lisse, "Ligne")
	O.decor(O.ellipsoide(pont, Vector3.new(0.3, 0.22, 0.3), CFrame.new(flotte + Vector3.new(0, 0.05, 0)), Color3.fromRGB(220, 50, 40), M.Lisse, "Bouchon"))
	O.decor(O.ellipsoide(pont, Vector3.new(0.22, 0.16, 0.22), CFrame.new(flotte + Vector3.new(0, 0.2, 0)), Color3.new(1, 1, 1), M.Lisse, "Bouchon"))

	-- Une seule invite « Pêcher » (attributs de PecheGrotte : Peche, Eau ; PecheLibre = ouverte à tous, 1 pièce)
	local place = ancre(pont, a(0, HAUT + 1.5, bout + 0.6), Vector3.new(1, 1, 1), "BoutPonton")
	local eau = a(-0.8, 0, bout - 4.5).Position
	place:SetAttribute("Peche", "caverne")
	place:SetAttribute("PecheLibre", true)
	place:SetAttribute("Eau", Vector3.new(eau.X, yEau, eau.Z))
	local invite = Instance.new("ProximityPrompt")
	invite.ActionText = "Pêcher"
	invite.ObjectText = "Coin pêche de la caverne"
	invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 0, 7, false
	invite:SetAttribute("Peche", "caverne")
	invite.Parent = place
	-- Cascade bien visible : en avant de la paroi, 2 studs à l'intérieur de l'eau côté est, qui tombe d'une corniche de
	-- roche solide (Parts). Hauteur 18 studs, plafonnée par un raycast vers le haut (jamais dans la voûte).
	local base = centre + u * (R_POINT - 2)
	local cfK = CFrame.lookAt(Vector3.new(base.X, yEau, base.Z), Vector3.new(base.X - u.X, yEau, base.Z - u.Z)) -- -Z vers le ponton, y = 0 à la surface
	local toit = workspace:Raycast(Vector3.new(base.X, yEau + 1, base.Z), Vector3.new(0, 40, 0), params)
	local haut = math.max(8, math.min(18, if toit then toit.Position.Y - yEau - 3 else 18))
	terrain:FillBlock(cfK * CFrame.new(0, haut / 2, 6.5), Vector3.new(14, haut + 6, 5), Enum.Material.Rock) -- paroi loin derrière
	local cascade = O.modele(g, "Cascade")
	local fonce = ROCHE:Lerp(C.PierreFoncee, 0.5)
	O.bloc(cascade, Vector3.new(8, haut + 1.5, 2.5), cfK * CFrame.new(0, (haut + 1.5) / 2 - 1, 2.6), fonce, M.Roche, "RocheArriere").CanTouch = false
	O.bloc(cascade, Vector3.new(8.5, 1.6, 4.6), cfK * CFrame.new(0, haut + 0.8, 0.6), ROCHE, M.Roche, "Corniche").CanTouch = false
	O.bloc(cascade, Vector3.new(6, 1, 3), cfK * CFrame.new(0.4, haut + 2, 1.4) * CFrame.Angles(0, 0.2, 0.06), fonce, M.Roche, "Corniche").CanTouch = false
	O.decor(O.ellipsoide(cascade, Vector3.new(9.5, 1.3, 2), cfK * CFrame.new(0, haut + 0.1, -1.3), MOUILLE, M.Roche, "Levre"))
	-- nappes de largeurs différentes (verre turquoise clair + filet néon léger au centre)
	for _, v in {{0, 4.6, 0.22, -0.3, M.Verre, Color3.fromRGB(125, 225, 230)}, {-2.6, 1.3, 0.3, -0.15, M.Lisse, Color3.fromRGB(150, 232, 235)},
		{2.5, 1.1, 0.3, -0.15, M.Lisse, Color3.fromRGB(150, 232, 235)}, {0.3, 1.6, 0.55, -0.5, M.Neon, Color3.fromRGB(170, 245, 245)}} do
		local nappe = O.decor(O.bloc(cascade, Vector3.new(v[2], haut + 0.2, 0.25), cfK * CFrame.new(v[1], haut / 2 - 0.1, v[4]), v[6], v[5], "Nappe"))
		nappe.Transparency = v[3]
		nappe.CastShadow = false
	end
	-- eau qui défile : Beams texturés face caméra
	local hautK = ancre(cascade, cfK * CFrame.new(0, haut - 0.2, -0.8), Vector3.new(4.5, 1, 0.6), "Ecume")
	local basK = ancre(cascade, cfK * CFrame.new(0, 0.2, -0.8), Vector3.new(6, 1, 2.5), "Remous")
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = hautK, basK
	for _, v in {{4.6, 5.4, 1.6, 0.15}, {2.2, 2.8, 2.6, 0.3}} do
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Width0, beam.Width1 = v[1], v[2]
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 3
		beam.TextureSpeed = v[3]
		beam.Color = ColorSequence.new(Color3.fromRGB(205, 248, 250), Color3.fromRGB(140, 230, 235))
		beam.Transparency = NumberSequence.new(v[4], v[4] + 0.3)
		beam.LightEmission = 0.35
		beam.LightInfluence = 0.5
		beam.Parent = hautK
	end
	emetteur(hautK, {
		Name = "Chute", Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(215, 240, 242)),
		Size = NumberSequence.new(1, 2.6), Transparency = NumberSequence.new(0.5, 1), Lifetime = NumberRange.new(0.9, 1.2),
		Rate = 22, Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(5, 5), Acceleration = Vector3.new(0, -36, 0),
		EmissionDirection = Enum.NormalId.Bottom, Shape = Enum.ParticleEmitterShape.Box, LightInfluence = 0.6,
	})
	-- pied : écume, éclaboussures, brume, son
	local ecume = O.decor(O.ellipsoide(cascade, Vector3.new(7.5, 0.3, 4.5), cfK * CFrame.new(0, 0.05, -1.4), Color3.fromRGB(228, 246, 246), M.Lisse, "EcumePied"))
	ecume.Transparency = 0.3
	ecume.CastShadow = false
	emetteur(basK, {
		Name = "Eclaboussures", Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(220, 248, 250)),
		Size = NumberSequence.new(0.45, 0.1), Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.5, 0.9),
		Rate = 40, Speed = NumberRange.new(5, 9), SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, -30, 0),
		EmissionDirection = Enum.NormalId.Top, LightEmission = 0.3,
	})
	O.brume(basK, Color3.fromRGB(175, 215, 220), 5)
	O.etincelles(basK, Color3.fromRGB(190, 230, 235), 12).LightEmission = 0.4
	local son = Instance.new("Sound")
	son.Name = "Cascade"
	son.SoundId = "rbxassetid://9120550180" -- boucle d'eau (déjà utilisée par la cascade du Lac des Lueurs)
	son.Looped = true
	reglerSonCascade(son)
	son.Parent = basK
	son:Play()
	O.lumiere(ancre(cascade, cfK * CFrame.new(0, haut / 2, -3), nil, "LueurCascade"), TURQUOISE, 1.2, 24)
	-- rien de solide entre le ponton et la cascade : raycasts horizontaux, la roche qui masque est creusée
	local vue = RaycastParams.new()
	vue.FilterType = Enum.RaycastFilterType.Exclude
	vue.FilterDescendantsInstances = {cascade, pont}
	vue.IgnoreWater = true
	local oeil = a(0, HAUT + 3, bout + 0.6).Position
	for _, y in {haut * 0.4, haut * 0.75} do
		local cible = (cfK * CFrame.new(0, y, -0.6)).Position
		for _ = 1, 4 do
			local r = workspace:Raycast(oeil, (cible - oeil) * 0.97, vue)
			if not r then break end
			if r.Instance == terrain and r.Position.Y > yEau + 1 then
				terrain:FillBall(r.Position, 3.5, Enum.Material.Air)
			else
				warn("[CaverneDecor] cascade masquée par", r.Instance:GetFullName())
				break
			end
		end
	end
	O.tag(pont, "PontonPeche")
end

-- ================= Champignons, racines, stalagmites =================

local function champignons(m, x, z, rng, couleur)
	if presDuLac(x, z) then return end -- le point d'eau a pris sa place
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
	local wagon = B.wagonnet(g, CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, 0, math.rad(4))) -- solide : on peut sauter dessus
	for k = 1, 4 do
		eclat(wagon, CFrame.lookAt((a + b) / 2, b) * CFrame.new(rng:NextNumber(-1.5, 1.5), 4.6, rng:NextNumber(-2, 2)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)),
			rng:NextNumber(1.4, 2.4), if k % 2 == 0 then BLEU else VIOLET)
	end
	-- éclats répandus au bout de la voie (le wagonnet renversé, qui cachait le bassin, est retiré)
	local pos = Vector3.new(42, sol(42, -396), -396)
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

-- ================= Paroi sud-est reculée =================

-- Élargit la salle derrière le pilier est (rails abandonnés, wagonnet qui était dans le mur) : roche creusée en
-- boules d'air, sol refait à plat au niveau de la caverne. Avant le bassin, qui reprend sa berge ensuite.
local CREUSES = {{Vector3.new(30, D.CAVERNE_SOL + 13, -358), 17}, {Vector3.new(45, D.CAVERNE_SOL + 13, -358), 15}}
reculerParoi = function()
	for _, c in CREUSES do
		terrain:FillBall(c[1], c[2], Enum.Material.Air)
	end
	terrain:FillBlock(CFrame.new(36, D.CAVERNE_SOL - 4, -358), Vector3.new(52, 8, 38), Enum.Material.Rock)
end

-- ================= Texte flottant « TUNNELS PRIVÉS » =================

-- Remplace l'ancien panneau sur poteaux (Mine.lua) : lettres dorées sur une part invisible, lueur ambre,
-- flottement animé côté client (tag « TexteFlottant »).
texteTunnels = function(m)
	local cf = CFrame.lookAt(PANNEAU_TUNNELS + Vector3.new(0, 8.5, 0), Vector3.new(0, PANNEAU_TUNNELS.Y + 8.5, -400))
	local p = ancre(m, cf, Vector3.new(14, 3, 0.2), "TexteTunnels")
	local g = Instance.new("SurfaceGui")
	g.Name = "Texte"
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Brightness = 1.6
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.Antique -- même police que « Tunnel VI » (O.texte)
	t.Text = "TUNNELS PRIVÉS"
	t.TextScaled = true
	t.TextColor3 = C.Or
	t.TextStrokeColor3 = Color3.fromRGB(24, 14, 8)
	t.TextStrokeTransparency = 0.3
	t.Parent = g
	local halo = Instance.new("UIStroke")
	halo.Color = AMBRE
	halo.Thickness = 3
	halo.Transparency = 0.55
	halo.Parent = t
	O.lumiere(p, AMBRE, 1, 16)
	O.etincelles(p, Color3.fromRGB(255, 214, 140), 3).LightEmission = 0.6
	O.tag(p, "TexteFlottant")
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
	for _, d in caverne:GetChildren() do -- ancien panneau « TUNNELS PRIVÉS » (remplacé par le texte flottant)
		if d:IsA("BasePart") and (d.Name == "Fronton" or d.Name == "Poteau") then
			local ecart = d.Position - PANNEAU_TUNNELS
			if math.abs(ecart.X) < 7 and math.abs(ecart.Z) < 2 and ecart.Y > -1 and ecart.Y < 12 then d:Destroy() end
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
	reculerParoi()
	piliersEtPont(m, rng)
	texteTunnels(m)
	task.wait()
	faille(m)
	frise(m)
	task.wait()
	bassin(m, rng)
	for _, c in {
		{-40, -378, TURQUOISE}, {-23, -371, BLEU}, {19, -380, TURQUOISE}, {25, -377, VIOLET},
		{48, -365, TURQUOISE}, {73, -386, BLEU}, {56, -391, TURQUOISE}, {-88, -392, VIOLET}, {-82, -418, BLEU},
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
	if existant and existant:GetAttribute("Version") == VERSION then
		local pointEau = existant:FindFirstChild("PointEau")
		local cascade = pointEau and pointEau:FindFirstChild("Cascade")
		local remous = cascade and cascade:FindFirstChild("Remous")
		local son = remous and remous:FindFirstChild("Cascade")
		if son and son:IsA("Sound") then
			reglerSonCascade(son)
		end
	else
		if existant then existant:Destroy() end
		construire(mine)
	end
	if caverne then replacerCristalDuBassin(caverne) end
end

return CaverneDecor
