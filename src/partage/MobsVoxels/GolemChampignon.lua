-- Golem champignon (forêt de champignons de la grotte −50 m) : tronc de champignon trapu, gros chapeau magenta
-- tacheté de lueurs cyan, poings de pierre. Lent et coriace ; frappe des deux poings.
-- Écrit en Luau avec MobsKit (pas d'export Blender) : os, boîtes et clips décrits par du code.

local MobsKit = require(script.Parent.Parent:WaitForChild("MobsKit"))
local rampe, cloche, TAU = MobsKit.rampe, MobsKit.cloche, MobsKit.TAU
local V, A = Vector3.new, CFrame.Angles

local K = MobsKit.nouveau()
K:os("root", nil, V(0, 0, 0))
K:os("body", "root", V(0, 2.2, 0))
K:os("legL", "root", V(-0.7, 2.2, 0))
K:os("legR", "root", V(0.7, 2.2, 0))
K:os("armL", "body", V(-1.45, 4.4, 0))
K:os("armR", "body", V(1.45, 4.4, 0))
K:os("cap", "body", V(0, 5, 0))

-- jambes et pieds
K:paire("legL", "legR", "ST2", V(0.95, 2, 1.05), V(0.7, 1.2, 0))
K:paire("legL", "legR", "PI", V(1.15, 0.45, 1.35), V(0.7, 0.22, -0.1))
-- tronc
K:boite("body", "ST", V(2.3, 2.9, 1.9), V(0, 3.55, 0))
K:boite("body", "ST3", V(1.5, 1.6, 0.1), V(0, 3.3, -0.98))
K:boite("body", "MS", V(0.9, 0.5, 0.25), V(0.55, 2.6, -0.98))
K:boite("body", "MS", V(1.1, 0.6, 0.25), V(-0.6, 4.3, 0.97))
K:boite("body", "MS", V(0.25, 0.7, 0.8), V(1.17, 3, 0.3))
-- visage : yeux lumineux, sourcils froncés, bouche
K:paire("body", "body", "GL", V(0.38, 0.38, 0.12), V(0.48, 4.25, -0.99))
K:paire("body", "body", "BR", V(0.62, 0.15, 0.12), V(0.48, 4.62, -0.99), A(0, 0, -0.3))
K:boite("body", "MO", V(0.9, 0.18, 0.12), V(0, 3.75, -0.99))
-- bras et poings
K:paire("armL", "armR", "ST2", V(0.75, 1.9, 0.75), V(1.5, 3.45, 0))
K:paire("armL", "armR", "PI", V(1, 0.75, 1), V(1.5, 2.25, 0))
K:paire("armL", "armR", "SP", V(0.35, 0.35, 0.35), V(1.5, 4.45, 0.1))
-- chapeau
K:boite("cap", "GI", V(3.8, 0.3, 3.8), V(0, 5.05, 0))
K:boite("cap", "CA", V(4.6, 1.3, 4.6), V(0, 5.85, 0))
K:boite("cap", "CA2", V(3.4, 0.6, 3.4), V(0, 6.75, 0))
K:boite("cap", "CA", V(1.8, 0.35, 1.8), V(0, 7.2, 0))
for _, p in {V(1.25, 7.08, 0.9), V(-1.2, 7.08, -1), V(-1, 7.08, 1.1), V(1.1, 7.08, -1.15)} do
	K:boite("cap", "SP", V(0.55, 0.12, 0.55), p)
end
K:boite("cap", "SP", V(0.12, 0.5, 0.6), V(2.32, 5.9, 0.6))
K:boite("cap", "SP", V(0.12, 0.5, 0.6), V(-2.32, 5.8, -0.8))
K:boite("cap", "SP", V(0.6, 0.5, 0.12), V(0.9, 5.9, -2.32))
K:boite("cap", "SP", V(0.6, 0.5, 0.12), V(-1.2, 5.85, 2.32))
K:boite("cap", "SP", V(0.6, 0.5, 0.12), V(-0.9, 5.9, -2.32))

-- ===== clips =====
K:clip("Idle", 48, function(t)
	local s = math.sin(t * TAU)
	return {
		body = A(0.03 * s, 0, 0),
		cap = A(0, 0, 0.05 * math.sin(t * TAU + 1)),
		armL = A(0.08 * s, 0, -0.05),
		armR = A(-0.08 * s, 0, 0.05),
	}, V(0, 0.05 * s, 0)
end)

K:clip("Walk", 24, function(t)
	local w = math.sin(t * TAU)
	return {
		legL = A(0.55 * w, 0, 0),
		legR = A(-0.55 * w, 0, 0),
		armL = A(-0.45 * w, 0, -0.06),
		armR = A(0.45 * w, 0, 0.06),
		body = A(-0.08, 0, 0.06 * w),
		cap = A(0, 0, -0.06 * w),
	}, V(0, 0.12 * math.abs(w), 0)
end)

-- les deux poings levés (0 → 11), abattus (11 → 14 : impact), puis retour
K:clip("Attack", 30, function(t)
	local bras, corps, chapeau, y
	if t < 0.36 then
		local k = rampe(t, 0, 0.36)
		bras, corps, chapeau, y = 2.6 * k, 0.15 * k, 0.1 * k, 0
	elseif t < 0.47 then
		local k = rampe(t, 0.36, 0.47)
		bras, corps, chapeau, y = 2.6 - 1.7 * k, 0.15 - 0.55 * k, 0.1 - 0.35 * k, -0.15 * k
	else
		local k = 1 - rampe(t, 0.6, 1)
		bras, corps, chapeau, y = 0.9 * k, -0.4 * k, -0.25 * k, -0.15 * k
	end
	local serre = 0.25 * math.min(1, bras / 1.5)
	return {
		armL = A(bras, 0, serre),
		armR = A(bras, 0, -serre),
		body = A(corps, 0, 0),
		cap = A(chapeau, 0, 0),
	}, V(0, y, 0)
end)

K:clip("Hurt", 16, function(t)
	local c = cloche(t, 0, 1)
	return {
		body = A(0.3 * c, 0, 0),
		cap = A(0.2 * c, 0, 0),
		armL = A(0, 0, -0.3 * c),
		armR = A(0, 0, 0.3 * c),
	}, V(0, 0, 0.2 * c)
end)

-- tombe à la renverse, le chapeau bascule
K:clip("Death", 40, function(t)
	local k = rampe(t, 0, 0.7)
	local rebond = cloche(t, 0.7, 0.85) * 0.1
	return {
		root = A(1.45 * k - rebond, 0, 0),
		cap = A(0.6 * k, 0, 0.3 * k),
		armL = A(0, 0, -1 * k),
		armR = A(0, 0, 1 * k),
		legL = A(-0.3 * k, 0, 0),
		legR = A(-0.3 * k, 0, 0),
	}, V(0, 0, 0)
end)

return K:donnees({
	Colors = {ST = "e3d6b8", ST2 = "cbbd9c", ST3 = "efe6d0", PI = "8e7b5c", MS = "4d7a3a", GL = "8ffcff", BR = "3a2a22",
		MO = "2a1a16", GI = "f0c2dc", CA = "b2347a", CA2 = "c64a8e", SP = "7ff6ff"},
	Glow = {GL = true, SP = true},
	NoStud = {GL = true, SP = true, BR = true, MO = true, GI = true, MS = true},
	Hauteur = 7.4,
})
