-- Gardien des astres (boss de la grotte −1200 m « Néant étoilé », Autel des constellations) : chevalier céleste en
-- armure bleu nuit filetée d'or, visage de néant où brillent deux yeux d'étoile, auréole d'or et étoile au front,
-- cape semée d'étoiles, constellation sur le plastron, sceptre à étoile dans la main droite, deux astres en orbite.
-- MODÈLE PROVISOIRE écrit en Luau avec MobsKit (pas d'export Blender) : le vrai modèle remplacera ce fichier.
-- Garder les noms d'os (root, hips, torso, head, halo, cape, armL/armR, legL/legR, astres) et les clips.
-- Clips : Idle, Walk, Attack, Hurt, Roar, Death + attaques spéciales « Nova » (onde stellaire) et « Invocation »
-- (pluie d'étoiles) (BossProfondeurs.lua : le clip dure le temps d'annonce de l'attaque).

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("hips", "root", V(0, 3.6, 0))
K:os("torso", "hips", V(0, 4.1, 0))
K:os("head", "torso", V(0, 6.7, 0))
K:os("halo", "head", V(0, 7.9, 0.5))
K:os("cape", "torso", V(0, 6.4, 0.9))
K:os("armL", "torso", V(-1.95, 6.3, 0))
K:os("armR", "torso", V(1.95, 6.3, 0))
K:os("legL", "root", V(-0.75, 3.6, 0))
K:os("legR", "root", V(0.75, 3.6, 0))
K:os("astres", "torso", V(0, 5.5, 0))

-- ===== jambes : grèves bleu nuit, genouillères d'or, solerets =====
K:paire("legL", "legR", "AR", V(1.05, 0.8, 1.6), V(0.75, 0.4, -0.15))
K:paire("legL", "legR", "OR", V(1.07, 0.18, 1.62), V(0.75, 0.85, -0.15))
K:paire("legL", "legR", "AB", V(0.9, 1.6, 0.9), V(0.75, 1.7, 0))
K:paire("legL", "legR", "OR", V(0.95, 0.6, 0.45), V(0.75, 2.55, -0.35))
K:paire("legL", "legR", "AR", V(1.0, 1.1, 1.0), V(0.75, 3.1, 0))

-- ===== bassin : ceinture d'or, tassettes =====
K:boite("hips", "OR", V(2.6, 0.5, 1.5), V(0, 3.65, 0))
K:boite("hips", "ET", V(0.45, 0.45, 0.12), V(0, 3.65, -0.8), A(0, 0, math.rad(45)))
K:boite("hips", "AB", V(1.1, 1.2, 0.2), V(0, 2.9, -0.75), A(0.12, 0, 0))
K:paire("hips", "hips", "AB", V(0.25, 1.3, 1.2), V(1.35, 2.95, 0), A(0, 0, -0.12))

-- ===== torse : plastron, constellation en néon, gorgerin d'or =====
K:boite("torso", "AR", V(2.9, 2.5, 1.7), V(0, 5.1, 0))
K:boite("torso", "AB", V(2.2, 1.7, 0.25), V(0, 5.25, -0.93))
for _, e in {{-0.6, 5.7}, {-0.15, 5.35}, {0.35, 5.75}, {0.6, 4.85}, {-0.4, 4.7}} do
	K:boite("torso", "ET", V(0.16, 0.16, 0.08), V(e[1], e[2], -1.08), A(0, 0, math.rad(45)))
end
K:boite("torso", "NB", V(0.9, 0.05, 0.05), V(-0.38, 5.53, -1.08), A(0, 0, -0.65))
K:boite("torso", "NB", V(0.7, 0.05, 0.05), V(0.1, 5.55, -1.08), A(0, 0, 0.7))
K:boite("torso", "NB", V(0.95, 0.05, 0.05), V(0.48, 5.3, -1.08), A(0, 0, -1.3))
K:boite("torso", "OR", V(1.9, 0.5, 1.4), V(0, 6.5, 0))

-- ===== tête : heaume, visage de néant, yeux d'étoile, étoile frontale =====
K:boite("head", "AR", V(1.45, 1.45, 1.45), V(0, 7.3, 0))
K:boite("head", "VI", V(1.0, 0.8, 0.1), V(0, 7.25, -0.73))
K:paire("head", "head", "EY", V(0.22, 0.14, 0.06), V(0.24, 7.35, -0.79))
K:boite("head", "OR", V(1.5, 0.15, 1.5), V(0, 7.95, 0))
K:boite("head", "OR", V(0.2, 0.9, 0.2), V(0, 8.4, -0.72))
K:boite("head", "ET", V(0.4, 0.4, 0.12), V(0, 8.95, -0.72), A(0, 0, math.rad(45)))
K:paire("head", "head", "OR", V(0.15, 0.6, 0.15), V(0.78, 8.1, -0.3), A(0, 0, -0.3))

-- ===== auréole d'or derrière la tête (anneau en 8 segments) =====
for i = 0, 7 do
	local a = i / 8 * TAU
	K:boite("halo", "OR", V(0.85, 0.16, 0.12), V(math.cos(a) * 1.0, 7.9 + math.sin(a) * 1.0, 0.75), A(0, 0, a + math.pi / 2))
end
K:boite("halo", "ET", V(0.22, 0.22, 0.08), V(0, 8.9, 0.75), A(0, 0, math.rad(45)))

-- ===== cape bleu profond semée d'étoiles =====
K:boite("cape", "OR", V(3.0, 0.4, 0.55), V(0, 6.45, 0.8))
K:boite("cape", "CR", V(2.8, 4.4, 0.18), V(0, 4.1, 1.05))
for _, e in {{-0.9, 5.4}, {0.4, 4.9}, {-0.3, 3.8}, {0.9, 3.2}, {-0.8, 2.5}, {0.2, 2.2}} do
	K:boite("cape", "ET", V(0.14, 0.14, 0.2), V(e[1], e[2], 1.1), A(0, 0, math.rad(45)))
end

-- ===== bras : épaulières d'or, brassards, gantelets ; sceptre à étoile (main droite) =====
K:paire("armL", "armR", "OR", V(1.4, 0.8, 1.5), V(1.95, 6.55, 0))
K:paire("armL", "armR", "AR", V(0.8, 1.3, 0.8), V(1.95, 5.35, 0))
K:paire("armL", "armR", "AB", V(0.95, 0.9, 0.95), V(1.95, 4.35, 0))
K:paire("armL", "armR", "OR", V(0.9, 0.55, 0.9), V(1.95, 3.65, 0))
K:boite("armR", "OR", V(0.25, 0.25, 6.2), V(1.95, 3.6, -0.9))
K:boite("armR", "OR", V(0.5, 0.5, 0.5), V(1.95, 3.6, -4.1))
K:boite("armR", "ET", V(0.75, 0.75, 0.2), V(1.95, 3.6, -4.55), A(0, 0, math.rad(45)))
K:boite("armR", "NB", V(0.4, 0.4, 0.3), V(1.95, 3.6, -4.55))

-- ===== astres en orbite (tournent avec l'os « astres ») =====
K:boite("astres", "NB", V(0.55, 0.55, 0.55), V(-2.9, 6.6, 1.2))
K:boite("astres", "ET", V(0.4, 0.4, 0.4), V(2.8, 7.2, 1.4))

-- ===== clips =====
K:clip("Idle", 60, function(t)
	local s = math.sin(t * TAU)
	return {
		torso = A(0.03 * s, 0, 0),
		head = A(-0.03 * s, 0.08 * math.sin(t * TAU + 1), 0),
		halo = A(0, 0, 0.1 * s),
		armL = A(0.05 * s, 0, -0.1),
		armR = A(0.12 + 0.04 * s, 0, 0.05),
		cape = A(-0.05 - 0.04 * s, 0, 0),
		astres = A(0, t * TAU, 0),
	}, V(0, 0.08 * s, 0)
end)

K:clip("Walk", 36, function(t)
	local s = math.sin(t * TAU)
	return {
		legL = A(0.5 * s, 0, 0),
		legR = A(-0.5 * s, 0, 0),
		hips = A(0, -0.06 * s, 0),
		torso = A(-0.06, 0.08 * s, 0),
		head = A(0.05, -0.04 * s, 0),
		armL = A(-0.4 * s, 0, -0.1),
		armR = A(0.15 + 0.15 * s, 0, 0.08),
		cape = A(-0.25 - 0.08 * math.abs(s), 0, 0),
		astres = A(0, t * TAU, 0),
	}, V(0, 0.1 * math.abs(math.cos(t * TAU)), 0)
end)

-- sceptre levé (0 → 0,45), abattu en se penchant (0,45 → 0,55 : impact ≈ 0,8 s), retour
K:clip("Attack", 45, function(t)
	local bras, buste
	if t < 0.45 then
		local k = rampe(t, 0, 0.45)
		bras, buste = 2.4 * k, 0.25 * k
	elseif t < 0.55 then
		local k = rampe(t, 0.45, 0.55)
		bras, buste = 2.4 - 2.2 * k, 0.25 - 0.7 * k
	else
		local k = 1 - rampe(t, 0.65, 1)
		bras, buste = 0.2 * k + 0.12 * (1 - k), -0.45 * k
	end
	local fente = cloche(t, 0.35, 0.9)
	return {
		armR = A(bras, 0, 0.12),
		armL = A(0.4 * cloche(t, 0, 0.6), 0, -0.4 * cloche(t, 0, 0.6) - 0.1),
		torso = A(buste, 0, 0),
		head = A(-buste * 0.4, 0, 0),
		legL = A(0.5 * fente, 0, 0),
		legR = A(-0.35 * fente, 0, 0),
		cape = A(-0.3 * fente, 0, 0),
		astres = A(0, t * TAU * 2, 0),
	}, V(0, -0.2 * fente, -0.5 * fente)
end)

K:clip("Hurt", 16, function(t)
	local c = cloche(t, 0, 1)
	return {
		torso = A(0.25 * c, 0, 0),
		head = A(0.2 * c, 0, 0),
		armL = A(0, 0, -0.3 * c),
		cape = A(-0.2 * c, 0, 0),
	}, V(0, 0, 0.3 * c)
end)

-- rugissement : bras écartés, tête levée vers la voûte, auréole qui vibre
K:clip("Roar", 48, function(t)
	local k = rampe(t, 0, 0.25) * (1 - rampe(t, 0.85, 1))
	local tremble = 0.05 * math.sin(t * TAU * 8) * k
	return {
		torso = A(0.3 * k, 0, 0),
		head = A(0.5 * k + tremble, tremble, 0),
		halo = A(0, 0, 0.4 * k),
		armL = A(0.3 * k, 0, -1.6 * k + tremble),
		armR = A(0.3 * k, 0, 1.4 * k - tremble),
		cape = A(-0.5 * k, 0, 0),
		legL = A(0, 0, -0.12 * k),
		legR = A(0, 0, 0.12 * k),
		astres = A(0, t * TAU * 3, 0),
	}, V(0, 0, 0.2 * k)
end)

-- « Nova » (1,2 s d'annonce) : sceptre brandi à deux mains (0 → 0,6), planté au sol à 0,7 (onde stellaire), retour
K:clip("Nova", 54, function(t)
	local leve = rampe(t, 0, 0.6)
	local abat = rampe(t, 0.6, 0.7)
	local fin = 1 - rampe(t, 0.85, 1)
	local k = if t > 0.7 then fin else 1
	local bras = (2.8 * leve - 2.6 * abat) * k
	local buste = (0.2 * leve - 0.9 * abat) * k
	local genou = abat * fin
	return {
		armR = A(bras, 0, 0.1),
		armL = A(bras * 0.9, 0, 0.35 * leve * (1 - abat)),
		torso = A(buste, 0, 0),
		head = A(-buste * 0.5, 0, 0),
		halo = A(0, 0, t * TAU),
		legL = A(0.6 * genou, 0, 0),
		legR = A(-0.7 * genou, 0, 0),
		cape = A(-0.4 * genou, 0, 0),
		astres = A(0, t * TAU * 2, 0),
	}, V(0, -0.9 * genou, -0.3 * genou)
end)

-- « Invocation » (1,6 s d'annonce) : sceptre pointé vers la voûte, bras gauche écarté, tête levée (pluie d'étoiles)
K:clip("Invocation", 60, function(t)
	local k = rampe(t, 0, 0.3) * (1 - rampe(t, 0.85, 1))
	local tremble = 0.04 * math.sin(t * TAU * 7) * k
	return {
		armR = A(2.9 * k + tremble, 0, 0.1),
		armL = A(0.2 * k, 0, -1.3 * k),
		torso = A(0.25 * k, 0, 0),
		head = A(0.5 * k, 0, 0),
		halo = A(0, 0, t * TAU * 2),
		cape = A(-0.3 * k, 0, 0),
		astres = A(0, t * TAU * 4, 0),
	}, V(0, 0.4 * k, 0)
end)

-- tombe à genoux, le sceptre s'éteint, puis s'effondre face contre terre
K:clip("Death", 60, function(t)
	local k1 = rampe(t, 0, 0.4)
	local k2 = rampe(t, 0.45, 1)
	return {
		root = A(-1.3 * k2, 0, 0),
		legL = A(-1.2 * k1, 0, 0),
		legR = A(-1.0 * k1, 0, 0),
		torso = A(-0.2 * k1, 0, 0),
		head = A(-0.3 * k1 + 0.4 * k2, 0, 0),
		armL = A(-1.0 * k2, 0, -0.6 * k2),
		armR = A(-0.3 * k1 - 0.9 * k2, 0, 0.5 * k2),
		cape = A(0.4 * k2, 0, 0),
	}, V(0, -2.1 * k1, 0)
end)

return K:donnees({
	Colors = {AR = "1c2050", AB = "2e3680", OR = "e0b450", ET = "fff2c0", NB = "a070ff", CR = "141238", VI = "05050f",
		EY = "9fe0ff"},
	Glow = {ET = true, NB = true, EY = true},
	NoStud = {ET = true, NB = true, EY = true, VI = true, OR = true, CR = true},
	Hauteur = 9,
})
