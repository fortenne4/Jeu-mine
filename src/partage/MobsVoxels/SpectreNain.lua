-- Spectre nain (temple de la grotte −50 m) : fantôme translucide d'un nain de Brumefer, casque à cornes, longue
-- barbe pâle, yeux cyan, lanterne ambrée à la main. Il flotte (vol, comme la chauve-souris) et frappe de sa
-- lanterne. Écrit en Luau avec MobsKit (pas d'export Blender) ; pièces translucides (Data.Transparence).

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("body", "root", V(0, 1.5, 0))
K:os("head", "body", V(0, 4.2, 0))
K:os("armL", "body", V(-1.2, 3.8, 0))
K:os("armR", "body", V(1.2, 3.8, 0))

-- robe qui s'effile vers le bas (pas de jambes)
K:boite("body", "RB", V(0.8, 0.9, 0.8), V(0, 0.75, 0.15))
K:boite("body", "RB", V(1.5, 1.2, 1.3), V(0, 1.75, 0.05))
K:boite("body", "TO", V(2.1, 1.7, 1.6), V(0, 3.15, 0))
K:boite("body", "CE", V(2.2, 0.35, 1.7), V(0, 2.4, 0))
K:boite("body", "BO", V(0.45, 0.4, 0.15), V(0, 2.4, -0.88))
-- tête : capuche, casque à cornes, barbe, yeux
K:boite("head", "TO", V(1.5, 1.4, 1.4), V(0, 4.85, 0))
K:boite("head", "HE", V(1.75, 0.5, 1.65), V(0, 5.65, 0))
K:boite("head", "HE", V(0.9, 0.35, 0.9), V(0, 6.05, 0))
K:paire("head", "head", "CO", V(0.3, 0.8, 0.3), V(1.05, 6.05, 0), A(0, 0, -0.45))
K:boite("head", "BA", V(1.4, 1.3, 0.4), V(0, 4.1, -0.78))
K:boite("head", "BA", V(0.8, 0.8, 0.35), V(0, 3.2, -0.75))
K:paire("head", "head", "EY", V(0.36, 0.2, 0.1), V(0.35, 4.95, -0.73))
-- bras ; lanterne dans la main droite
K:paire("armL", "armR", "TO", V(0.6, 1.6, 0.6), V(1.35, 3.05, 0))
K:paire("armL", "armR", "HE", V(0.7, 0.5, 0.7), V(1.35, 2.15, 0))
K:boite("armR", "CH", V(0.12, 0.6, 0.12), V(1.35, 1.6, -0.1))
K:boite("armR", "LA", V(0.6, 0.7, 0.6), V(1.35, 1, -0.1))
K:boite("armR", "CH", V(0.75, 0.15, 0.75), V(1.35, 1.4, -0.1))
K:boite("armR", "CH", V(0.75, 0.15, 0.75), V(1.35, 0.6, -0.1))

-- ===== clips =====
K:clip("Idle", 60, function(t)
	local s = math.sin(t * TAU)
	return {
		body = A(0.04 * s, 0, 0.03 * math.cos(t * TAU)),
		head = A(-0.05 * s, 0.1 * math.sin(t * TAU + 1), 0),
		armL = A(0.1 * s, 0, -0.1),
		armR = A(0.15 - 0.1 * s, 0, 0.08),
	}, V(0, 0.25 * s, 0)
end)

K:clip("Walk", 40, function(t)
	local s = math.sin(t * TAU)
	return {
		body = A(-0.3, 0, 0.05 * s),
		head = A(0.15, 0, 0),
		armL = A(-0.5 + 0.1 * s, 0, -0.15),
		armR = A(-0.3 - 0.1 * s, 0, 0.15),
	}, V(0, 0.2 * s, 0)
end)

-- lanterne levée derrière (0 → 10), balayée vers l'avant (10 → 14 : impact), retour
K:clip("Attack", 30, function(t)
	local bras, corps
	if t < 0.33 then
		local k = rampe(t, 0, 0.33)
		bras, corps = -1.2 * k, 0.2 * k
	elseif t < 0.47 then
		local k = rampe(t, 0.33, 0.47)
		bras, corps = -1.2 + 2.9 * k, 0.2 - 0.6 * k
	else
		local k = 1 - rampe(t, 0.55, 1)
		bras, corps = 1.7 * k, -0.4 * k
	end
	return {
		armR = A(bras, 0, 0.2),
		armL = A(-0.4 * cloche(t, 0, 0.6), 0, -0.3),
		body = A(corps, 0.25 * cloche(t, 0.2, 0.7), 0),
		head = A(-corps * 0.5, 0, 0),
	}, V(0, 0, -0.4 * cloche(t, 0.3, 0.7))
end)

K:clip("Hurt", 16, function(t)
	local c = cloche(t, 0, 1)
	return {
		body = A(0.35 * c, 0, 0),
		head = A(0.25 * c, 0, 0),
		armL = A(0, 0, -0.5 * c),
		armR = A(0, 0, 0.5 * c),
	}, V(0, 0.3 * c, 0.4 * c)
end)

-- tourbillonne et s'élève en se dissipant (le client le fait fondre)
K:clip("Death", 40, function(t)
	local k = rampe(t, 0, 1)
	return {
		root = A(0, 4 * k, 0),
		body = A(0.3 * k, 0, 0),
		head = A(0.5 * k, 0, 0),
		armL = A(-1.5 * k, 0, -0.6 * k),
		armR = A(-1.5 * k, 0, 0.6 * k),
	}, V(0, 2.5 * k, 0)
end)

return K:donnees({
	Colors = {RB = "3d8aa3", TO = "4f9fba", CE = "2c6a80", BO = "9fe6ff", HE = "8fc9d9", CO = "d8f4ff", BA = "e8fbff",
		EY = "7ff6ff", CH = "6d8a94", LA = "ffcf66"},
	Glow = {RB = true, BA = true, EY = true, LA = true, BO = true},
	NoStud = {RB = true, TO = true, CE = true, BO = true, HE = true, CO = true, BA = true, EY = true, CH = true, LA = true},
	Transparence = {RB = 0.55, TO = 0.4, CE = 0.45, HE = 0.35, CO = 0.35, BA = 0.25, BO = 0.3, CH = 0.4},
	Hauteur = 6.4,
})
