-- Léviathan des abysses (boss de la grotte −900 m « Abysses engloutis », Sanctuaire du Léviathan) : serpent de mer
-- dressé sur ses anneaux, écailles bleu-vert, ventre pâle, nageoires sombres, crête et marques en néon cyan, perle
-- abyssale au front, gueule à crocs, bras-nageoires à griffes, deux tentacules violets dans le dos.
-- MODÈLE PROVISOIRE écrit en Luau avec MobsKit (pas d'export Blender) : le vrai modèle remplacera ce fichier.
-- Garder les noms d'os (root, anneaux, torso, head, jaw, armL/armR, tentL/tentR) et les clips (le serveur s'en sert).
-- Clips : Idle, Walk, Attack, Hurt, Roar, Death + attaques spéciales « Vague » (raz-de-marée) et « Tentacules »
-- (BossProfondeurs.lua : le clip dure le temps d'annonce de l'attaque).

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("anneaux", "root", V(0, 1, 0.5))
K:os("torso", "root", V(0, 2.6, 0))
K:os("head", "torso", V(0, 7.2, -0.6))
K:os("jaw", "head", V(0, 7.0, -1.4))
K:os("armL", "torso", V(-1.75, 6.0, -0.3))
K:os("armR", "torso", V(1.75, 6.0, -0.3))
K:os("tentL", "torso", V(-1.0, 4.6, 1.1))
K:os("tentR", "torso", V(1.0, 4.6, 1.1))

-- ===== anneaux : la queue enroulée au sol, bout de queue en nageoire =====
K:boite("anneaux", "EC", V(5.0, 1.1, 5.0), V(0, 0.55, 0.4))
K:boite("anneaux", "EB", V(4.2, 0.3, 4.2), V(0, 1.15, 0.4))
K:boite("anneaux", "EC", V(3.9, 1.0, 3.9), V(0, 1.6, 0.4), A(0, math.rad(45), 0))
K:boite("anneaux", "NE", V(0.2, 0.12, 4.4), V(-2.45, 0.85, 0.4))
K:boite("anneaux", "NE", V(0.2, 0.12, 4.4), V(2.45, 0.85, 0.4))
K:boite("anneaux", "EC", V(1.1, 0.8, 2.2), V(1.6, 0.4, 3.5), A(0, -0.5, 0))
K:boite("anneaux", "EC", V(0.8, 0.6, 1.6), V(2.5, 0.3, 4.6), A(0, -0.9, 0))
K:boite("anneaux", "EF", V(0.15, 1.4, 1.6), V(3.1, 0.8, 5.3), A(0, -0.9, 0.2))

-- ===== torse : colonne d'écailles, ventre pâle strié, nageoire dorsale =====
K:boite("torso", "EC", V(2.6, 4.2, 2.2), V(0, 4.3, 0))
K:boite("torso", "EB", V(1.8, 3.8, 0.3), V(0, 4.3, -1.15))
for i = 0, 3 do
	K:boite("torso", "EC", V(1.9, 0.12, 0.34), V(0, 2.9 + i * 0.95, -1.2))
end
K:boite("torso", "EC", V(2.3, 1.3, 2.1), V(0, 6.55, -0.2))
for i, h in {1.2, 1.5, 1.3, 1.0} do
	K:boite("torso", "EF", V(0.18, h, 0.9), V(0, 3.2 + i * 0.95, 1.35), A(-0.35, 0, 0))
end
K:paire("torso", "torso", "NE", V(0.1, 3.4, 0.12), V(1.32, 4.3, -0.6))

-- ===== tête : crâne allongé, museau, yeux et perle en néon, crête de nageoires =====
K:boite("head", "EC", V(2.1, 1.5, 2.3), V(0, 7.75, -0.9))
K:boite("head", "EC", V(1.5, 0.9, 1.6), V(0, 7.6, -2.6))
K:boite("head", "EB", V(1.3, 0.25, 1.5), V(0, 7.1, -2.5))
K:paire("head", "head", "NE", V(0.12, 0.3, 0.5), V(1.06, 7.95, -1.6))
K:paire("head", "head", "DE", V(0.12, 0.35, 0.12), V(0.55, 6.95, -3.25))
K:boite("head", "PL", V(0.45, 0.45, 0.45), V(0, 8.6, -1.5), A(0, math.rad(45), 0))
K:boite("head", "EF", V(0.18, 1.1, 1.4), V(0, 8.9, -0.6), A(-0.3, 0, 0))
K:boite("head", "EF", V(0.18, 0.8, 1.1), V(0, 8.75, 0.3), A(-0.5, 0, 0))
K:paire("head", "head", "EF", V(0.15, 1.0, 1.2), V(1.15, 8.1, -0.2), A(-0.4, 0, -0.5))

-- ===== mâchoire : gueule rouge sombre, crocs =====
K:boite("jaw", "EC", V(1.4, 0.45, 2.1), V(0, 6.8, -2.2))
K:boite("jaw", "BO", V(1.1, 0.12, 1.8), V(0, 7.05, -2.2))
K:paire("jaw", "jaw", "DE", V(0.12, 0.3, 0.12), V(0.5, 7.2, -3.0))
K:paire("jaw", "jaw", "DE", V(0.1, 0.25, 0.1), V(0.55, 7.15, -2.4))

-- ===== bras-nageoires : épaule, avant-bras, griffes, nageoire =====
K:paire("armL", "armR", "EC", V(1.1, 1.0, 1.2), V(1.85, 6.1, -0.3))
K:paire("armL", "armR", "EC", V(0.75, 2.0, 0.75), V(1.95, 4.8, -0.3))
K:paire("armL", "armR", "EB", V(0.85, 0.9, 0.85), V(1.95, 3.5, -0.35))
K:paire("armL", "armR", "DE", V(0.14, 0.6, 0.14), V(1.7, 2.8, -0.65))
K:paire("armL", "armR", "DE", V(0.14, 0.6, 0.14), V(2.2, 2.8, -0.65))
K:paire("armL", "armR", "EF", V(0.15, 2.2, 1.1), V(2.35, 4.6, 0.3))

-- ===== tentacules du dos (violets, ventouses roses) =====
for _, c in {{"tentL", -1}, {"tentR", 1}} do
	local o, s = c[1], c[2]
	K:boite(o, "TE", V(0.7, 1.6, 0.7), V(1.2 * s, 5.3, 1.5), A(-0.5, 0, 0.25 * s))
	K:boite(o, "TE", V(0.55, 1.5, 0.55), V(1.55 * s, 6.6, 2.3), A(-0.8, 0, 0.35 * s))
	K:boite(o, "TE", V(0.4, 1.3, 0.4), V(1.85 * s, 7.6, 3.3), A(-1.1, 0, 0.45 * s))
	K:boite(o, "VE", V(0.2, 0.2, 0.2), V(1.05 * s, 5.1, 1.12))
	K:boite(o, "VE", V(0.18, 0.18, 0.18), V(1.4 * s, 6.3, 1.95))
	K:boite(o, "VE", V(0.15, 0.15, 0.15), V(1.75 * s, 7.4, 2.95))
end

-- ===== clips =====
local function vague(t: number, f: number): number
	return math.sin(t * TAU * f)
end

K:clip("Idle", 60, function(t)
	local s = vague(t, 1)
	return {
		torso = A(0.04 * s, 0.05 * vague(t, 1) , 0.03 * s),
		head = A(-0.05 * s, 0.1 * math.sin(t * TAU + 1), 0),
		jaw = A(0.08 + 0.06 * math.abs(s), 0, 0),
		armL = A(0.1 * s, 0, -0.1),
		armR = A(-0.1 * s, 0, 0.1),
		tentL = A(0.2 * vague(t, 1), 0, -0.15 * vague(t, 2)),
		tentR = A(-0.2 * vague(t, 1), 0, 0.15 * vague(t, 2)),
		anneaux = A(0, 0.05 * s, 0),
	}, V(0, 0.1 * s, 0)
end)

-- glisse sur ses anneaux : ondulation du buste, tête qui garde le cap
K:clip("Walk", 36, function(t)
	local s = vague(t, 1)
	return {
		anneaux = A(0, 0.25 * s, 0),
		torso = A(-0.12, -0.18 * s, 0.1 * s),
		head = A(0.1, 0.15 * s, -0.08 * s),
		jaw = A(0.1, 0, 0),
		armL = A(-0.35 * s, 0, -0.15),
		armR = A(0.35 * s, 0, 0.15),
		tentL = A(0.35 * s, 0, -0.2),
		tentR = A(-0.35 * s, 0, 0.2),
	}, V(0.25 * s, 0.12 * math.abs(math.cos(t * TAU)), 0)
end)

-- recule le buste et ouvre la gueule (0 → 0,45), plonge en avant griffes et crocs (0,45 → 0,55 : impact ≈ 0,8 s), retour
K:clip("Attack", 45, function(t)
	local arme = rampe(t, 0, 0.45)
	local plonge = rampe(t, 0.45, 0.55)
	local retour = 1 - rampe(t, 0.65, 1)
	local k = if t < 0.55 then 1 else retour
	local buste = (0.35 * arme - 0.85 * plonge) * k
	local bras = (2.2 * arme - 1.6 * plonge) * k
	return {
		torso = A(buste, 0, 0),
		head = A(-buste * 0.4 + 0.2 * arme * (1 - plonge), 0, 0),
		jaw = A(0.6 * arme * k, 0, 0),
		armL = A(bras, 0, -0.3 * arme * k),
		armR = A(bras, 0, 0.3 * arme * k),
		tentL = A(-0.4 * arme * k, 0, -0.3 * k),
		tentR = A(-0.4 * arme * k, 0, 0.3 * k),
	}, V(0, 0, -1.2 * plonge * k)
end)

K:clip("Hurt", 16, function(t)
	local c = cloche(t, 0, 1)
	return {
		torso = A(0.3 * c, 0, 0.1 * c),
		head = A(0.35 * c, 0, 0),
		jaw = A(0.4 * c, 0, 0),
		armL = A(0, 0, -0.4 * c),
		armR = A(0, 0, 0.4 * c),
	}, V(0, 0, 0.4 * c)
end)

-- rugissement : se dresse, gueule grande ouverte, bras écartés, tentacules déployés
K:clip("Roar", 48, function(t)
	local k = rampe(t, 0, 0.25) * (1 - rampe(t, 0.85, 1))
	local tremble = 0.05 * math.sin(t * TAU * 8) * k
	return {
		torso = A(0.3 * k, 0, 0),
		head = A(0.55 * k + tremble, tremble, 0),
		jaw = A(0.9 * k, 0, 0),
		armL = A(0.4 * k, 0, -1.4 * k + tremble),
		armR = A(0.4 * k, 0, 1.4 * k - tremble),
		tentL = A(-0.6 * k, 0, -0.5 * k),
		tentR = A(-0.6 * k, 0, 0.5 * k),
	}, V(0, 0.6 * k, 0.3 * k)
end)

-- « Vague » (1,2 s d'annonce) : bras levés au-dessus de la tête (0 → 0,6), abattus au sol à 0,7 (raz-de-marée), retour
K:clip("Vague", 54, function(t)
	local leve = rampe(t, 0, 0.6)
	local abat = rampe(t, 0.6, 0.7)
	local fin = 1 - rampe(t, 0.85, 1)
	local k = if t > 0.7 then fin else 1
	local bras = (2.8 * leve - 2.9 * abat) * k
	local buste = (0.35 * leve - 1.0 * abat) * k
	return {
		armL = A(bras, 0, -0.25 * leve * k),
		armR = A(bras, 0, 0.25 * leve * k),
		torso = A(buste, 0, 0),
		head = A(0.3 * leve * k - 0.2 * abat * k, 0, 0),
		jaw = A(0.7 * leve * k, 0, 0),
		tentL = A(-0.8 * leve * k, 0, -0.4 * k),
		tentR = A(-0.8 * leve * k, 0, 0.4 * k),
	}, V(0, 0.5 * leve * k - 0.8 * abat * k, 0)
end)

-- « Tentacules » (1,4 s d'annonce) : se ramasse, griffes plantées au sol, tentacules dressés qui ondulent (ils jaillissent du sol)
K:clip("Tentacules", 54, function(t)
	local k = rampe(t, 0, 0.3) * (1 - rampe(t, 0.85, 1))
	local o = 0.25 * math.sin(t * TAU * 3) * k
	return {
		torso = A(-0.4 * k, 0, 0),
		head = A(0.2 * k, 0, 0),
		jaw = A(0.5 * k, 0, 0),
		armL = A(1.0 * k, 0, -0.3 * k),
		armR = A(1.0 * k, 0, 0.3 * k),
		tentL = A(-1.1 * k + o, 0, -0.6 * k),
		tentR = A(-1.1 * k - o, 0, 0.6 * k),
	}, V(0, -0.5 * k, 0)
end)

-- s'effondre sur ses anneaux, tête sur le côté
K:clip("Death", 60, function(t)
	local k1 = rampe(t, 0, 0.4)
	local k2 = rampe(t, 0.4, 1)
	return {
		torso = A(0.5 * k1 - 1.1 * k2, 0, 0.6 * k2),
		head = A(0.6 * k1 - 0.2 * k2, 0, 0.4 * k2),
		jaw = A(0.9 * k1 - 0.5 * k2, 0, 0),
		armL = A(-0.4 * k2, 0, -0.9 * k2),
		armR = A(0.3 * k2, 0, 0.7 * k2),
		tentL = A(0.8 * k2, 0, -0.8 * k2),
		tentR = A(0.8 * k2, 0, 0.8 * k2),
	}, V(0, -1.2 * k2, 0)
end)

return K:donnees({
	Colors = {EC = "185464", EB = "6aa8a0", EF = "0d2a3a", NE = "5affe6", DE = "e8e2c8", BO = "3a0c18", TE = "4a2a6a",
		VE = "ff7ad9", PL = "eaf8ff"},
	Glow = {NE = true, VE = true, PL = true},
	NoStud = {NE = true, VE = true, PL = true, DE = true, BO = true},
	Hauteur = 9,
})
