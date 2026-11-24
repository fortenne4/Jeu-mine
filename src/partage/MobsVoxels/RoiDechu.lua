-- Roi déchu (boss du trône de magma, grotte −350 m « Les Rivières de lave ») : ancien souverain des forges,
-- consumé par la lave. Armure noire et rouge fendue de veines de lave, couronne noircie à une pointe brisée et
-- flammes aux pointes, yeux brûlants, cape en lambeaux qui se consume par le bas, épée longue à tranchant de feu.
-- Écrit en Luau avec MobsKit (pas d'export Blender). Clips : Idle, Walk, Run, Attack, Hurt, Roar, Death
-- + attaques spéciales Frappe (onde de feu), Elan / Charge (charge), Incantation (pluie de météores).
-- Aura de braises, flammes de la couronne et de l'épée : ajoutées par le serveur (TroneLave.lua).

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("hips", "root", V(0, 3.4, 0))
K:os("torso", "hips", V(0, 3.9, 0))
K:os("head", "torso", V(0, 6.4, 0))
K:os("cape", "torso", V(0, 6.1, 0.85))
K:os("armL", "torso", V(-1.85, 6.0, 0))
K:os("armR", "torso", V(1.85, 6.0, 0))
K:os("legL", "root", V(-0.7, 3.4, 0))
K:os("legR", "root", V(0.7, 3.4, 0))

-- ===== jambes : bottes, jambières, genouillères rouges, fissures de lave =====
K:paire("legL", "legR", "AN", V(1.0, 0.8, 1.5), V(0.7, 0.4, -0.15))
K:paire("legL", "legR", "AR", V(1.02, 0.35, 0.4), V(0.7, 0.55, -0.75))
K:paire("legL", "legR", "AD", V(0.85, 1.5, 0.85), V(0.7, 1.55, 0))
K:paire("legL", "legR", "AR", V(0.95, 0.55, 0.45), V(0.7, 2.35, -0.35))
K:paire("legL", "legR", "AN", V(0.95, 1.1, 0.95), V(0.7, 2.9, 0))
K:paire("legL", "legR", "LV", V(0.1, 0.9, 0.05), V(0.7, 1.5, -0.45))

-- ===== bassin : ceinture, boucle de lave, tassettes =====
K:boite("hips", "AD", V(2.5, 0.55, 1.4), V(0, 3.45, 0))
K:boite("hips", "LV", V(0.55, 0.4, 0.12), V(0, 3.45, -0.75))
K:boite("hips", "AR", V(1.0, 1.1, 0.2), V(0, 2.75, -0.72), A(0.12, 0, 0))
K:paire("hips", "hips", "AR", V(0.25, 1.2, 1.1), V(1.3, 2.8, 0), A(0, 0, -0.12))
K:boite("hips", "CB", V(1.6, 1.6, 0.15), V(0, 2.6, 0.75))

-- ===== torse : plastron noir, cuirasse rouge, veines de lave, gorgerin =====
K:boite("torso", "AN", V(2.7, 2.3, 1.6), V(0, 4.85, 0))
K:boite("torso", "AR", V(2.1, 1.5, 0.25), V(0, 5.0, -0.88))
K:boite("torso", "AD", V(1.7, 0.6, 0.2), V(0, 4.0, -0.85))
K:boite("torso", "LV", V(0.18, 1.3, 0.06), V(0, 5.05, -1.03))
K:paire("torso", "torso", "LV", V(0.12, 0.7, 0.06), V(0.42, 5.25, -1.03), A(0, 0, -0.6))
K:boite("torso", "AD", V(1.7, 0.5, 1.3), V(0, 6.15, 0))

-- ===== tête : visage calciné, heaume, yeux brûlants, couronne noircie (une pointe brisée) en flammes =====
K:boite("head", "PE", V(1.25, 1.3, 1.25), V(0, 6.95, 0))
K:boite("head", "AN", V(1.4, 1.1, 1.0), V(0, 7.05, 0.2))
K:boite("head", "AD", V(1.3, 0.35, 0.25), V(0, 6.5, -0.6))
K:paire("head", "head", "EY", V(0.36, 0.16, 0.08), V(0.3, 7.05, -0.64))
K:boite("head", "LV", V(0.5, 0.08, 0.06), V(0, 6.72, -0.64))
K:boite("head", "CR", V(1.55, 0.35, 1.55), V(0, 7.75, 0))
K:boite("head", "OR", V(1.6, 0.1, 1.6), V(0, 7.58, 0))
K:boite("head", "CR", V(0.3, 0.9, 0.3), V(0, 8.35, -0.62))
K:paire("head", "head", "CR", V(0.28, 0.7, 0.28), V(0.62, 8.25, -0.62))
K:paire("head", "head", "CR", V(0.28, 0.75, 0.28), V(0.62, 8.27, 0.62))
K:boite("head", "CR", V(0.28, 0.65, 0.28), V(-0.62, 8.22, 0), A(0, 0, 0.15))
K:boite("head", "CR", V(0.28, 0.35, 0.28), V(0.66, 8.04, 0), A(0, 0, -0.5)) -- la pointe brisée
K:boite("head", "LV", V(0.3, 0.3, 0.1), V(0, 7.75, -0.8), A(0, 0, math.rad(45)))
K:boite("head", "FL", V(0.2, 0.32, 0.2), V(0, 8.95, -0.62))
K:paire("head", "head", "FL", V(0.18, 0.28, 0.18), V(0.62, 8.75, -0.62))
K:paire("head", "head", "FL", V(0.18, 0.28, 0.18), V(0.62, 8.78, 0.62))

-- ===== cape en lambeaux qui se consume par le bas =====
K:boite("cape", "CA", V(2.9, 0.45, 0.6), V(0, 6.15, 0.75))
K:boite("cape", "CA", V(2.7, 3.3, 0.18), V(0, 4.4, 1.0))
for i, l in {{-1.1, 1.4}, {-0.5, 0.7}, {0.1, 1.2}, {0.7, 0.5}, {1.15, 1.0}} do
	local x, long = l[1], l[2]
	K:boite("cape", if i % 2 == 0 then "CB" else "CA", V(0.5, long, 0.18), V(x, 2.75 - long / 2, 1.0))
	if long >= 1 then
		K:boite("cape", "LV", V(0.3, 0.1, 0.2), V(x, 2.78 - long, 1.0))
	end
end

-- ===== bras : épaulières à pointe, brassards rouges, gantelets =====
K:paire("armL", "armR", "AR", V(1.3, 0.75, 1.4), V(1.9, 6.25, 0))
K:paire("armL", "armR", "AD", V(1.35, 0.2, 1.45), V(1.9, 5.85, 0))
K:paire("armL", "armR", "AN", V(0.3, 0.9, 0.3), V(2.2, 6.9, 0), A(0, 0, 0.4))
K:paire("armL", "armR", "AN", V(0.75, 1.3, 0.75), V(1.9, 5.1, 0))
K:paire("armL", "armR", "AR", V(0.9, 0.9, 0.9), V(1.9, 4.15, 0))
K:paire("armL", "armR", "AD", V(0.85, 0.6, 0.85), V(1.9, 3.45, 0))

-- ===== épée longue (main droite), tranchant et âme de lave =====
K:boite("armR", "AD", V(0.22, 0.22, 0.9), V(1.9, 3.35, 0.05))
K:boite("armR", "LV", V(0.32, 0.32, 0.32), V(1.9, 3.35, 0.6))
K:boite("armR", "OR", V(1.4, 0.28, 0.28), V(1.9, 3.35, -0.5))
K:boite("armR", "OR", V(0.2, 0.45, 0.2), V(1.25, 3.5, -0.5), A(0, 0, 0.5))
K:boite("armR", "OR", V(0.2, 0.45, 0.2), V(2.55, 3.5, -0.5), A(0, 0, -0.5))
K:boite("armR", "LA", V(0.18, 0.55, 4.2), V(1.9, 3.35, -2.75))
K:boite("armR", "LB", V(0.22, 0.14, 4.2), V(1.9, 3.08, -2.75))
K:boite("armR", "LB", V(0.2, 0.08, 3.6), V(1.9, 3.42, -2.6))
K:boite("armR", "LA", V(0.18, 0.35, 0.5), V(1.9, 3.3, -5.05))

-- ===== clips =====
K:clip("Idle", 60, function(t)
	local s = math.sin(t * TAU)
	return {
		torso = A(0.03 * s, 0, 0),
		head = A(-0.03 * s, 0.08 * math.sin(t * TAU + 1), 0),
		armL = A(0.05 * s, 0, -0.08),
		armR = A(0.1 + 0.04 * s, 0, 0.05),
		cape = A(-0.05 - 0.04 * s, 0, 0),
	}, V(0, 0.05 * s, 0)
end)

K:clip("Walk", 36, function(t)
	local s = math.sin(t * TAU)
	return {
		legL = A(0.55 * s, 0, 0),
		legR = A(-0.55 * s, 0, 0),
		hips = A(0, -0.06 * s, 0),
		torso = A(-0.06, 0.08 * s, 0),
		head = A(0.05, -0.04 * s, 0),
		armL = A(-0.4 * s, 0, -0.1),
		armR = A(0.15 + 0.2 * s, 0, 0.08),
		cape = A(-0.25 - 0.08 * math.abs(s), 0, 0),
	}, V(0, 0.1 * math.abs(math.cos(t * TAU)), 0)
end)

-- course : penché en avant, épée tenue devant, cape qui flotte derrière
K:clip("Run", 24, function(t)
	local s = math.sin(t * TAU)
	return {
		legL = A(0.95 * s - 0.1, 0, 0),
		legR = A(-0.95 * s - 0.1, 0, 0),
		hips = A(-0.25, -0.1 * s, 0),
		torso = A(-0.15, 0.12 * s, 0),
		head = A(0.3, 0, 0),
		armL = A(-0.8 * s, 0, -0.15),
		armR = A(0.6 + 0.25 * s, 0, 0.1),
		cape = A(-0.9 - 0.15 * math.sin(t * 2 * TAU), 0, 0),
	}, V(0, 0.25 * math.abs(math.cos(t * TAU)), 0)
end)

-- épée levée au-dessus de la tête (0 → 0,35), abattue en se penchant (0,35 → 0,47 : impact ≈ 0,57 s), retour
K:clip("Attack", 40, function(t)
	local bras, buste, tourne, gauche
	if t < 0.35 then
		local k = rampe(t, 0, 0.35)
		bras, buste, tourne, gauche = 2.6 * k, 0.25 * k, -0.3 * k, 0.6 * k
	elseif t < 0.47 then
		local k = rampe(t, 0.35, 0.47)
		bras, buste, tourne, gauche = 2.6 - 2.3 * k, 0.25 - 0.7 * k, -0.3 + 0.55 * k, 0.6 - 1.1 * k
	else
		local k = 1 - rampe(t, 0.6, 1)
		bras, buste, tourne, gauche = 0.3 * k + 0.1 * (1 - k), -0.45 * k, 0.25 * k, -0.5 * k
	end
	local fente = cloche(t, 0.3, 0.85)
	return {
		armR = A(bras, 0, 0.15),
		armL = A(gauche, 0, -0.3 * cloche(t, 0, 0.6) - 0.08),
		torso = A(buste, tourne, 0),
		head = A(-buste * 0.4, 0, 0),
		legL = A(0.5 * fente, 0, 0),
		legR = A(-0.35 * fente, 0, 0),
		cape = A(-0.3 * fente, 0, 0),
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

-- rugissement de l'intro : bras écartés, tête en arrière, tremblement
K:clip("Roar", 48, function(t)
	local k = rampe(t, 0, 0.25) * (1 - rampe(t, 0.85, 1))
	local tremble = 0.05 * math.sin(t * TAU * 8) * k
	return {
		torso = A(0.3 * k, 0, 0),
		head = A(0.5 * k + tremble, tremble, 0),
		armL = A(0.3 * k, 0, -1.6 * k + tremble),
		armR = A(0.3 * k, 0, 1.4 * k - tremble),
		cape = A(-0.5 * k, 0, 0),
		legL = A(0, 0, -0.12 * k),
		legR = A(0, 0, 0.12 * k),
	}, V(0, 0, 0.2 * k)
end)

-- ===== attaques spéciales (TroneLave) : les clips durent exactement le temps d'annonce du serveur =====
-- « Frappe » (1,6 s) : épée levée à deux mains (0 → 0,5), plantée dans le sol à 0,62 (≈ 1 s : l'onde de feu part)
K:clip("Frappe", 48, function(t)
	local leve = rampe(t, 0, 0.5)
	local abat = rampe(t, 0.5, 0.62)
	local fin = 1 - rampe(t, 0.85, 1)
	local bras = (2.8 * leve - 2.6 * abat) * (if t > 0.62 then fin else 1)
	local buste = (0.2 * leve - 0.95 * abat) * (if t > 0.62 then fin else 1)
	local genou = abat * fin
	return {
		armR = A(bras, 0, 0.1),
		armL = A(bras * 0.9, 0, 0.35 * leve * (1 - abat)),
		torso = A(buste, 0, 0),
		head = A(-buste * 0.5, 0, 0),
		legL = A(0.6 * genou, 0, 0),
		legR = A(-0.7 * genou, 0, 0),
		cape = A(-0.4 * genou, 0, 0),
	}, V(0, -0.9 * genou, -0.3 * genou)
end)

-- « Elan » (0,8 s) : accroupi, épée ramenée en arrière, prêt à charger
K:clip("Elan", 24, function(t)
	local k = rampe(t, 0, 0.5)
	local tremble = 0.03 * math.sin(t * TAU * 6) * k
	return {
		torso = A(-0.35 * k, 0.45 * k, 0),
		head = A(0.3 * k, -0.3 * k, 0),
		armR = A(-0.7 * k + tremble, 0, 0.35 * k),
		armL = A(0.5 * k, 0, -0.3 * k),
		legL = A(0.55 * k, 0, 0),
		legR = A(-0.55 * k, 0, 0),
		cape = A(-0.2 * k, 0, 0),
	}, V(0, -0.6 * k, 0.3 * k)
end)

-- « Charge » (boucle) : penché, épée tenue basse devant comme une lance, grandes foulées
K:clip("Charge", 16, function(t)
	local s = math.sin(t * TAU)
	return {
		legL = A(1.1 * s - 0.15, 0, 0),
		legR = A(-1.1 * s - 0.15, 0, 0),
		hips = A(-0.35, 0, 0),
		torso = A(-0.2, 0, 0),
		head = A(0.45, 0, 0),
		armR = A(0.55, 0, 0.05),
		armL = A(-0.9 * s, 0, -0.2),
		cape = A(-1.2 - 0.1 * math.sin(t * 2 * TAU), 0, 0),
	}, V(0, 0.2 * math.abs(math.cos(t * TAU)), 0)
end)

-- « Incantation » (1,6 s) : épée brandie vers la voûte, bras gauche écarté, tête levée (pluie de météores)
K:clip("Incantation", 48, function(t)
	local k = rampe(t, 0, 0.3) * (1 - rampe(t, 0.85, 1))
	local tremble = 0.04 * math.sin(t * TAU * 7) * k
	return {
		armR = A(1.65 * k + tremble, 0, 0.1),
		armL = A(0.2 * k, 0, -1.3 * k),
		torso = A(0.25 * k, 0, 0),
		head = A(0.5 * k, 0, 0),
		cape = A(-0.3 * k, 0, 0),
	}, V(0, 0.15 * k, 0)
end)

-- tombe à genoux, lâche son épée, puis s'effondre face contre terre
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
	Colors = {AN = "1e1a1c", AR = "6e1410", AD = "2e2829", OR = "5c4520", LV = "ff5a14", EY = "ffd23c", PE = "2a1d1a",
		CR = "17110f", FL = "ffa030", CA = "4a0e0c", CB = "2c0807", LA = "2b2428", LB = "ff7a1e"},
	Glow = {LV = true, EY = true, FL = true, LB = true},
	NoStud = {LV = true, EY = true, FL = true, LB = true, PE = true, CA = true, CB = true, LA = true, OR = true, CR = true},
	Hauteur = 8,
})
