-- Crabe des lueurs (berges des lacs de la grotte −50 m) : carapace bleu-vert tachetée de turquoise lumineux,
-- yeux jaunes sur pédoncules, grosses pinces aux pointes luisantes. Rapide, fragile ; pince des deux côtés.
-- Écrit en Luau avec MobsKit (pas d'export Blender).

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("body", "root", V(0, 1.3, 0))
K:os("clawL", "body", V(-1.3, 1.6, -0.7))
K:os("clawR", "body", V(1.3, 1.6, -0.7))
K:os("legsL", "body", V(-1.1, 1.1, 0))
K:os("legsR", "body", V(1.1, 1.1, 0))

-- carapace
K:boite("body", "BE", V(2.4, 0.35, 1.9), V(0, 0.95, 0))
K:boite("body", "SH", V(2.9, 1, 2.3), V(0, 1.55, 0))
K:boite("body", "SH2", V(2.2, 0.45, 1.7), V(0, 2.25, 0))
K:paire("body", "body", "SH2", V(0.35, 0.3, 0.35), V(1.5, 1.95, 0.6))
for _, p in {V(-0.6, 2.5, 0.4), V(0.6, 2.5, 0.35), V(0, 2.5, -0.35), V(0.15, 2.5, 0.7)} do
	K:boite("body", "GL", V(0.4, 0.12, 0.4), p)
end
K:boite("body", "MO", V(1, 0.3, 0.12), V(0, 1.3, -1.17))
-- yeux sur pédoncules
K:paire("body", "body", "ES", V(0.2, 0.75, 0.2), V(0.45, 2.35, -0.95))
K:paire("body", "body", "EY", V(0.38, 0.38, 0.38), V(0.45, 2.85, -0.95))
-- pinces
K:paire("clawL", "clawR", "CL", V(0.5, 0.5, 1.1), V(1.45, 1.6, -1.2))
K:paire("clawL", "clawR", "CP", V(1, 0.75, 1), V(1.6, 1.65, -2.1))
K:paire("clawL", "clawR", "CP", V(0.45, 0.35, 0.8), V(1.85, 1.95, -2.9))
K:paire("clawL", "clawR", "CP2", V(0.45, 0.3, 0.7), V(1.35, 1.45, -2.85))
K:paire("clawL", "clawR", "GL", V(0.3, 0.25, 0.3), V(1.85, 2, -3.35))
-- pattes (3 de chaque côté)
for _, z in {-0.6, 0, 0.6} do
	K:paire("legsL", "legsR", "LG", V(1.3, 0.28, 0.28), V(1.9, 1, z), A(0, 0, 0.55))
	K:paire("legsL", "legsR", "LG2", V(0.25, 0.9, 0.25), V(2.55, 0.45, z))
end

-- ===== clips =====
K:clip("Idle", 40, function(t)
	local s = math.sin(t * TAU)
	return {
		clawL = A(0.1 * s, 0, 0),
		clawR = A(0.1 * math.sin(t * TAU + 1.5), 0, 0),
		legsL = A(0, 0, 0.04 * s),
		legsR = A(0, 0, -0.04 * s),
	}, V(0, 0.04 * s, 0)
end)

K:clip("Walk", 16, function(t)
	local w = math.sin(t * TAU)
	return {
		legsL = A(0.15 * w, 0, 0.25 * w),
		legsR = A(-0.15 * w, 0, 0.25 * w),
		body = A(0, 0, 0.06 * w),
		clawL = A(0.15 + 0.1 * w, 0, 0),
		clawR = A(0.15 - 0.1 * w, 0, 0),
	}, V(0, 0.08 * math.abs(w), 0)
end)

-- pinces levées (0 → 10), refermées d'un coup (10 → 13 : impact), retour
K:clip("Attack", 30, function(t)
	local p, c
	if t < 0.33 then
		local k = rampe(t, 0, 0.33)
		p, c = 0.9 * k, 0.15 * k
	elseif t < 0.45 then
		local k = rampe(t, 0.33, 0.45)
		p, c = 0.9 - 1.15 * k, 0.15 - 0.35 * k
	else
		local k = 1 - rampe(t, 0.55, 1)
		p, c = -0.25 * k, -0.2 * k
	end
	local pince = 0.35 * cloche(t, 0.3, 0.5)
	return {
		clawL = A(p, pince, 0),
		clawR = A(p, -pince, 0),
		body = A(c, 0, 0),
	}, V(0, 0, 0)
end)

K:clip("Hurt", 14, function(t)
	local c = cloche(t, 0, 1)
	return {
		body = A(0.25 * c, 0, 0),
		clawL = A(0.4 * c, 0, -0.2 * c),
		clawR = A(0.4 * c, 0, 0.2 * c),
	}, V(0, 0, 0.25 * c)
end)

-- se retourne sur le dos, pattes en l'air
K:clip("Death", 36, function(t)
	local k = rampe(t, 0, 0.6)
	local frisson = math.sin(t * 40) * 0.25 * rampe(t, 0.6, 0.75) * (1 - rampe(t, 0.85, 1))
	return {
		root = A(0, 0, math.pi * k),
		legsL = A(0, 0, 0.3 + frisson),
		legsR = A(0, 0, -0.3 - frisson),
		clawL = A(-0.4 * k, 0, 0),
		clawR = A(-0.4 * k, 0, 0),
	}, V(0, 2.9 * k + 1.2 * cloche(k, 0, 1), 0)
end)

return K:donnees({
	Colors = {BE = "c9b48a", SH = "2f6f8a", SH2 = "3d8fa8", GL = "46ffd2", MO = "14232a", ES = "2a5568", EY = "fff27a",
		CL = "2a5568", CP = "3a86a0", CP2 = "2f6f8a", LG = "2a5568", LG2 = "1f4352"},
	Glow = {GL = true, EY = true},
	NoStud = {GL = true, EY = true, MO = true, ES = true},
	Hauteur = 3.2,
})
