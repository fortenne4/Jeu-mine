--[[ Grotte −700 m « Les Cavernes de glace éternelle » (palier 6, Glacier éternel, boss : le Titan de givre).
	Sous le Cœur maudit, la roche gèle d'un froid qui ne vient de nulle part. Une expédition naine s'y est figée.
	- Bivouac gelé à l'arrivée : tente en peaux, feu de camp (seule chaleur de la grotte), traîneau chargé, skis
	- LE LAC GELÉ : la plus grande salle a un sol de vraie glace (terrain Ice : ça glisse !), fissures bleues,
	  aiguilles de glace géantes, blocs de glace où sont pris des poissons, brume froide au ras du sol
	- AURORES : voiles de lumière verte, bleue et mauve qui ondulent sous la voûte des salles hautes
	- Galeries : stalactites de glace, grappes de cristaux de givre aux parois, congères, nains figés dans la glace
	  (pioche levée), neige qui tombe dans chaque salle
	- Salle du fond : LA CATHÉDRALE DE GIVRE — piliers de glace, lustre de cristal suspendu à la voûte, nains
	  agenouillés pris dans la glace, cercle de runes givrées ; le Titan de givre y attend
	Zones : Camp, LacGele, Aurore, Givre. Attributs du modèle : Theme = "GlaceEternelle", LacGele, ArenaGivre. ]]

local GT = require(script.Parent.GrotteTheme)
local O = require(script.Parent.Outils)

local GrotteGlace = {}

local rgb = Color3.fromRGB
local GLASS, ICE, SNOW = Enum.Material.Glass, Enum.Material.Ice, Enum.Material.Snow

local P = {
	glace = rgb(165, 220, 255),
	glaceClaire = rgb(225, 245, 255),
	glaceProfonde = rgb(70, 140, 205),
	cyan = rgb(110, 230, 255),
	neige = rgb(236, 244, 252),
	aurore1 = rgb(90, 255, 170),
	aurore2 = rgb(110, 170, 255),
	aurore3 = rgb(200, 120, 255),
	statue = rgb(120, 140, 160),
	barbe = rgb(220, 230, 238),
	metal = rgb(90, 100, 116),
	bois = rgb(92, 64, 44),
	peau = rgb(150, 116, 84),
	feu = rgb(255, 160, 70),
	poisson = rgb(255, 140, 70),
}

-- Salle scellée : minerais du trésor (tirage pondéré ; le 1er nœud est toujours Diamant, Orichalque ou Néantite)
local TRESOR = {
	{id = "Emeraude", poids = 26, pv = 140}, {id = "Lunarite", poids = 22, pv = 180}, {id = "Magmaite", poids = 18, pv = 200},
	{id = "Diamant", poids = 16, pv = 230}, {id = "Orichalque", poids = 11, pv = 250}, {id = "Neantite", poids = 7, pv = 290},
}
local GEMMES = {rgb(60, 220, 120), rgb(200, 245, 255), rgb(150, 70, 220), rgb(255, 170, 60), rgb(170, 190, 255), rgb(255, 90, 40)}
local function tirer(liste, rng)
	local total = 0
	for _, e in liste do total += e.poids end
	local x = rng:NextNumber() * total
	for _, e in liste do
		x -= e.poids
		if x <= 0 then return e end
	end
	return liste[#liste]
end

local COUL_GENERIQUE = {
	Roche = {rgb(185, 225, 250), ICE},
	Goutte = {P.glaceClaire, GLASS, 0.3},
	Lueur = {P.cyan, Enum.Material.Neon},
}

function GrotteGlace.decorer(ctx, infos, outils)
	local T = GT.nouveau(ctx, infos, outils)
	local rng, decor, M = T.rng, T.decor, T.M
	local depart, boss = T.depart, T.boss
	local salles = T.salles
	local plat, unite = T.plat, T.unite
	local terrain = workspace.Terrain

	local candidates = {}
	for _, s in salles do
		if not s.depart and not s.boss and s.r >= 15 then
			table.insert(candidates, s)
		end
	end
	table.sort(candidates, function(a, b)
		return a.r > b.r
	end)
	local roles = {}

	local function transparent(p: BasePart, t: number): BasePart
		p.Transparency, p.CastShadow = t, false
		return p
	end
	-- cristal de glace : prisme de verre, pointe à facettes, cœur bleu
	local function cristal(parent, base: CFrame, h: number, coeur: boolean?)
		local l = h * rng:NextNumber(0.22, 0.3)
		transparent(T.bloc(parent, Vector3.new(l, h * 0.8, l), base * CFrame.new(0, h * 0.4, 0) * CFrame.Angles(0, math.pi / 4, 0), P.glace, GLASS, "Glace"), 0.35)
		for k = 0, 3 do
			transparent(T.coin(parent, Vector3.new(l, h * 0.2, l * 0.5), base * CFrame.new(0, h * 0.9, 0) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 4, 0) * CFrame.new(0, 0, l * 0.25),
				P.glaceClaire, GLASS, "Pointe"), 0.35)
		end
		if coeur then
			local c = T.bloc(parent, Vector3.new(l * 0.22, h * 0.6, l * 0.22), base * CFrame.new(0, h * 0.4, 0), P.cyan, M.Neon, "Coeur")
			c.CastShadow = false
			if rng:NextNumber() < 0.5 then T.tag(c, "GrottePulse") end
		end
	end
	local function grappe(base: CFrame, taille: number)
		local m = T.modele("CristauxGivre")
		for k = 1, rng:NextInteger(3, 5) do
			cristal(m, base * CFrame.new(rng:NextNumber(-1, 1) * taille * 0.3, -0.3, rng:NextNumber(-1, 1) * taille * 0.3)
				* CFrame.Angles(rng:NextNumber(-0.45, 0.45), rng:NextNumber(0, 6), rng:NextNumber(-0.45, 0.45)), taille * rng:NextNumber(0.5, 1), k == 1)
		end
		return m
	end
	-- nain de l'expédition figé dans un bloc de glace (debout, pioche levée, ou agenouillé)
	local function nainGele(pos: Vector3, face: Vector3, s: number, agenouille: boolean?)
		local m = T.modele("NainGele")
		local cf = CFrame.lookAt(pos, pos + face)
		local dy = if agenouille then -0.9 * s else 0
		T.bloc(m, Vector3.new(1.6, if agenouille then 0.6 else 1.3, 1) * s, cf * CFrame.new(0, (if agenouille then 0.3 else 0.65) * s, 0), P.statue:Lerp(P.peau, 0.3), M.Lisse, "Jambes")
		T.bloc(m, Vector3.new(1.9, 1.6, 1.2) * s, cf * CFrame.new(0, 2.1 * s + dy, 0), P.statue, M.Lisse, "Corps")
		T.bloc(m, Vector3.new(2, 0.3, 1.3) * s, cf * CFrame.new(0, 1.6 * s + dy, 0), P.bois, M.Lisse, "Ceinture")
		T.bloc(m, Vector3.new(1.25, 1.15, 1.15) * s, cf * CFrame.new(0, 3.45 * s + dy, 0), P.peau:Lerp(P.glace, 0.4), M.Lisse, "Tete")
		T.bloc(m, Vector3.new(1.2, 1.2, 0.4) * s, cf * CFrame.new(0, 2.85 * s + dy, -0.72 * s), P.barbe, M.Lisse, "Barbe")
		T.bloc(m, Vector3.new(1.5, 0.5, 1.4) * s, cf * CFrame.new(0, 4.15 * s + dy, 0), P.metal, M.Metal, "Casque")
		for _, x in {-1, 1} do
			T.coin(m, Vector3.new(0.3, 0.8, 0.4) * s, cf * CFrame.new(x * 0.85 * s, 4.5 * s + dy, 0) * CFrame.Angles(0, 0, -x * 0.5), P.barbe, M.Lisse, "Corne")
		end
		if not agenouille then
			local bras = cf * CFrame.new(1.25 * s, 3.2 * s, -0.2 * s) * CFrame.Angles(0, 0, -0.35)
			T.bloc(m, Vector3.new(0.25, 3, 0.25) * s, bras * CFrame.new(0, 0.6 * s, 0), P.bois, M.Bois, "Manche")
			T.bloc(m, Vector3.new(2, 0.35, 0.35) * s, bras * CFrame.new(0, 2.1 * s, 0), P.metal, M.Metal, "Fer")
		end
		local h = (if agenouille then 4 else 5.4) * s
		transparent(T.bloc(m, Vector3.new(3.4 * s, h, 2.6 * s), cf * CFrame.new(0.15 * s, h / 2 - 0.2, 0) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), rng:NextNumber(-0.05, 0.05)),
			P.glace, GLASS, "Gangue"), 0.55)
		return m
	end
	-- voile d'aurore qui ondule sous la voûte (néons translucides qui pulsent)
	local function aurore(c: Vector3, rayon: number, y: number)
		local m = T.modele("Aurore")
		local a = rng:NextNumber(0, math.pi)
		local u, v = Vector3.new(math.cos(a), 0, math.sin(a)), Vector3.new(-math.sin(a), 0, math.cos(a))
		local phase = rng:NextNumber(0, 6)
		local n = 14
		local prec = nil
		for i = 0, n do
			local t = i / n
			local p = c + u * (t - 0.5) * 2 * rayon + v * math.sin(t * math.pi * 2 + phase) * rayon * 0.35
			p = Vector3.new(p.X, y + math.sin(t * math.pi * 3 + phase) * 1.2, p.Z)
			if prec then
				local seg = p - prec
				local h = 5 + 2.5 * math.sin(t * math.pi * 4 + phase)
				local couleur = if t < 0.5 then P.aurore1:Lerp(P.aurore2, t * 2) else P.aurore2:Lerp(P.aurore3, (t - 0.5) * 2)
				local milieu = (p + prec) / 2 - Vector3.new(0, h / 2, 0)
				local cf = CFrame.lookAt(milieu, milieu + seg)
				local r = transparent(T.bloc(m, Vector3.new(0.12, h, seg.Magnitude + 0.25), cf, couleur, M.Neon, "Voile"), 0.62)
				if i % 3 == 0 then T.tag(r, "GrottePulse") end
				transparent(T.bloc(m, Vector3.new(0.7, h * 1.3, seg.Magnitude + 0.3), cf * CFrame.new(0, -h * 0.15, 0), couleur, M.Neon, "Halo"), 0.9)
			end
			prec = p
		end
		local coeur = T.volume(m, Vector3.new(rayon * 2, 3, rayon), CFrame.new(c.X, y - 3, c.Z) * CFrame.Angles(0, -a, 0), "Paillettes")
		T.remplir(coeur, P.aurore1:Lerp(P.aurore2, 0.5), 0.55, 40)
		T.emetteur(coeur, {
			Name = "Paillettes", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.aurore1, P.aurore3),
			Size = NumberSequence.new({T.kp(0, 0), T.kp(0.4, 0.25), T.kp(1, 0)}), Lifetime = NumberRange.new(3, 5), Rate = 8,
			Speed = NumberRange.new(0.5, 1), Acceleration = Vector3.new(0, -0.6, 0), Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		})
	end
	local function neige(s, taux: number?)
		T.particulesSalle(s, {
			Name = "Neige", Texture = GT.TEX_LUEUR, LightEmission = 0.4, Color = ColorSequence.new(P.neige, P.glace),
			Size = NumberSequence.new({T.kp(0, 0.18), T.kp(1, 0.1)}), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.15, 0.2), T.kp(1, 1)}),
			Lifetime = NumberRange.new(6, 9), Rate = taux or 14, Speed = NumberRange.new(0.6, 1.4), SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Bottom, Acceleration = Vector3.new(0.3, -0.4, 0), RotSpeed = NumberRange.new(-40, 40),
		})
	end

	-- ===== 0. LA SALLE SCELLÉE (toujours là) : creusée AVANT le reste du décor =====
	-- Couloir creusé dans la paroi d'une salle (la plus loin du départ qui a la place, boss en dernier recours),
	-- bouché par une porte de glace (modèle « PorteGlace » : Eclat ×16, RuneGlace ×3) ; derrière, la salle au trésor.
	-- 3 leviers gelés (« LevierGlace ») dans 3 autres salles, très espacés. Serveur : MecaniquesGrotte.server.
	do
		local centreBoite = ctx.modele:GetAttribute("Centre")
		local dejaMinerais = ctx.modele:FindFirstChild("Minerais")
		-- entrée W (sol, pied de la paroi) et centre C de la salle au trésor, ou nil si ça touche autre chose
		local function place(s, u: Vector3, R: number)
			local hit = outils.paroi(s.p, u, 3, s.r * 2.2)
			if not hit or plat(hit.Normal):Dot(-u) < 0.5 then return nil end
			local sol = T.solEn(Vector3.new(hit.Position.X, s.p.Y, hit.Position.Z) - u * 4, 8)
			if not sol then return nil end
			local W = Vector3.new(hit.Position.X, sol.Position.Y, hit.Position.Z)
			local C = W + u * (8 + R * 0.8)
			for _, e in {{W + u * 3, 7}, {W + u * 7, 7}, {C, R * 1.2}} do
				local q, rad = e[1], e[2]
				if typeof(centreBoite) == "Vector3" and (math.abs(q.X - centreBoite.X) + rad > 172 or math.abs(q.Z - centreBoite.Z) + rad > 172) then return nil end
				for _, s2 in salles do
					if s2 ~= s and plat(q - s2.p).Magnitude < s2.r * 1.15 + rad + 6 then return nil end
				end
				for _, q2 in T.ptsChemin do
					if plat(q2 - s.p).Magnitude > s.r * 0.95 and plat(q - q2).Magnitude < rad + 23 then return nil end
				end
			end
			if dejaMinerais then
				for _, m in dejaMinerais:GetChildren() do
					local pp = m:IsA("Model") and m.PrimaryPart
					if pp and (pp.Position - W).Magnitude < 9 then return nil end
				end
			end
			return W, C
		end
		local hotes = {}
		for _, s in salles do
			if not s.depart and not s.boss then table.insert(hotes, s) end
		end
		table.sort(hotes, function(a, b) return plat(a.p - depart.p).Magnitude > plat(b.p - depart.p).Magnitude end)
		table.insert(hotes, boss)
		local hote, u, W, C, R
		for _, rayon in {15, 12} do
			for _, s in hotes do
				local a0 = rng:NextNumber(0, 2 * math.pi)
				for k = 0, 15 do
					local dir = Vector3.new(math.cos(a0 + k * math.pi / 8), 0, math.sin(a0 + k * math.pi / 8))
					local w, c = place(s, dir, rayon)
					if w then hote, u, W, C, R = s, dir, w, c, rayon break end
				end
				if hote then break end
			end
			if hote then break end
		end
		if not hote then
			warn("[Grottes] −700 m : pas de place pour la salle scellée")
		else
			local y0 = W.Y
			-- creusement : couloir (boîte) puis salle ronde à coupole, sols de roche comme le générateur
			local A = W - u * 3
			local axe = CFrame.lookAt((A + C) / 2, C)
			local long = (C - A).Magnitude
			terrain:FillBlock(axe * CFrame.new(0, 5, 0), Vector3.new(11, 10, long), Enum.Material.Air)
			terrain:FillBlock(axe * CFrame.new(0, -2, 0), Vector3.new(15, 4, long), ctx.matPart)
			terrain:FillBall(C + Vector3.new(0, R * 0.45, 0), R, Enum.Material.Air)
			terrain:FillBall(C + Vector3.new(0, R * 1.05, 0), R * 0.75, Enum.Material.Air)
			local h = R * 0.6 + 2
			terrain:FillCylinder(CFrame.new(C - Vector3.new(0, h / 2, 0)), h, R * 1.15, ctx.matPart)
			local function pret()
				local hit = T.trace(C + Vector3.new(0, R * 0.6, 0), Vector3.new(0, -R, 0))
				return hit ~= nil and hit.Position.Y < y0 + 2.5
			end
			local t0 = os.clock()
			repeat task.wait() until pret() or os.clock() - t0 > 3

			-- la porte de glace (face -Z tournée vers la salle hôte)
			local porte = T.modele("PorteGlace", ctx.modele)
			local cfP = CFrame.lookAt(W + u * 1.5 + Vector3.new(0, 7, 0), W + u * 1.5 + Vector3.new(0, 7, 0) - u)
			local milieu
			for cx = 0, 3 do
				for cy = 0, 3 do
					local e = O.bloc(porte, Vector3.new(4.05, 3.8, 4), cfP * CFrame.new(-6 + cx * 4, -5.625 + cy * 3.75, 0),
						P.glace:Lerp(P.glaceProfonde, rng:NextNumber(0, 0.35)), GLASS, "Eclat")
					e.Transparency, e.CastShadow = 0.3, false
					if cx == 1 and cy == 2 then milieu = e end
				end
			end
			porte.PrimaryPart = milieu
			for k = 1, 7 do
				local g = transparent(T.bloc(porte, Vector3.one * rng:NextNumber(0.8, 1.5), cfP * CFrame.new(rng:NextNumber(-6, 6), rng:NextNumber(-5, 5), rng:NextNumber(-1, 1))
					* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0), GEMMES[(k - 1) % #GEMMES + 1], M.Neon, "GemmeGelee"), 0.25)
				g.Size = Vector3.new(g.Size.X, g.Size.Y * 1.4, g.Size.Z)
			end
			for k = 1, 3 do
				local r = T.bloc(porte, Vector3.new(1.9, 1.9, 0.25), cfP * CFrame.new((k - 2) * 4.2, 4.3, -2.1) * CFrame.Angles(0, 0, math.pi / 4),
					rgb(40, 70, 110), M.Lisse, "RuneGlace")
				r:SetAttribute("Index", k)
				T.bloc(porte, Vector3.new(0.25, 1.5, 0.3), cfP * CFrame.new((k - 2) * 4.2, 4.3, -2.15) * CFrame.Angles(0, 0, (k - 2) * 0.5), P.glaceClaire, M.Lisse, "RuneTrait")
			end
			for k = 0, 15 do
				local a = k / 16 * 2 * math.pi
				transparent(T.bloc(porte, Vector3.new(0.25, 1.4, 0.2), cfP * CFrame.new(math.cos(a) * 3.6, -1.2 + math.sin(a) * 3.6, -2.1) * CFrame.Angles(0, 0, a),
					P.cyan, M.Neon, "CercleRunes"), 0.55)
			end
			-- encadrement de glace profonde, glaçons, congère
			for _, x in {-1, 1} do
				T.bloc(porte, Vector3.new(2.6, 17, 5), cfP * CFrame.new(x * 9.2, 0.6, -0.4), P.glaceProfonde, ICE, "Pilier")
			end
			T.bloc(porte, Vector3.new(21, 2.6, 5), cfP * CFrame.new(0, 8.6, -0.4), P.glaceProfonde, ICE, "Linteau")
			for k = 1, 7 do
				local L = rng:NextNumber(1.2, 3)
				transparent(T.bloc(porte, Vector3.new(0.5, L, 0.5), cfP * CFrame.new(-9 + k * 2.25, 7.3 - L / 2, -2.6) * CFrame.Angles(0, math.pi / 4, 0), P.glaceClaire, GLASS, "Glacon"), 0.2)
			end
			T.boule(porte, Vector3.new(20, 1.8, 4), cfP * CFrame.new(0, -7.2, -2.6), P.neige, SNOW, "Congere").CastShadow = false
			porte:SetAttribute("Centre", cfP.Position)
			porte:SetAttribute("Normale", -u)
			T.interdire(W - u * 4, 10)

			-- la salle au trésor : cristal géant, cercle de runes, cristaux aux parois, glaçons, lumières
			local m = T.modele("SalleScellee")
			cristal(m, CFrame.new(C - Vector3.new(0, 0.3, 0)), 11, true)
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.4
				cristal(m, CFrame.new(C + Vector3.new(math.cos(a), -0.3, math.sin(a)) * 2.6) * CFrame.Angles(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4), rng:NextNumber(4, 6), k % 2 == 0)
			end
			for k = 0, 19 do
				local a = k / 20 * 2 * math.pi
				local q = C + Vector3.new(math.cos(a), 0, math.sin(a)) * 5.5
				transparent(T.bloc(m, Vector3.new(0.3, 0.08, 1.6), CFrame.lookAt(q + Vector3.new(0, 0.1, 0), q + Vector3.new(-math.sin(a), 0.1, math.cos(a))), P.cyan, M.Neon, "CercleRunes"), 0.15)
			end
			for k = 1, 6 do
				local a = rng:NextNumber(0, 2 * math.pi)
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local hit = if dir:Dot(-u) < 0.6 then outils.paroi(C, dir, rng:NextNumber(1, 7), R * 1.8) else nil
				if hit then
					grappe(outils.axeVers(hit.Position - hit.Normal * 0.4, hit.Normal), rng:NextNumber(2, 3.4)).Parent = m
				end
				local haut = T.plafondEn(C + dir * R * rng:NextNumber(0.3, 0.7) + Vector3.new(0, 2, 0), 60)
				if haut then
					cristal(m, CFrame.new(haut.Position + Vector3.new(0, 0.4, 0)) * CFrame.Angles(math.pi, rng:NextNumber(0, 6), 0), rng:NextNumber(3, 6))
				end
			end
			local lueur = T.volume(m, Vector3.one, CFrame.new(C + Vector3.new(0, 8, 0)), "LueurTresor")
			T.lumiere(lueur, P.cyan, 2, 45)
			for k, coul in {GEMMES[1], GEMMES[3]} do
				local v = T.volume(m, Vector3.one, CFrame.new(C + Vector3.new(0, 5, 0) + Vector3.new(-u.Z, 0, u.X) * (k * 2 - 3) * R * 0.5), "LueurGemmes")
				T.remplir(v, coul, 0.8, 26)
			end
			local paillettes = T.volume(m, Vector3.new(R * 1.6, 8, R * 1.6), CFrame.new(C + Vector3.new(0, 6, 0)), "Paillettes")
			T.emetteur(paillettes, {
				Name = "Paillettes", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.glaceClaire, P.aurore3),
				Size = NumberSequence.new({T.kp(0, 0), T.kp(0.4, 0.3), T.kp(1, 0)}), Lifetime = NumberRange.new(2, 4), Rate = 10,
				Speed = NumberRange.new(0.3, 0.8), Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			-- les minerais du trésor (mêmes nœuds que les gisements : tag Minerai, PV, propriétaire)
			local places = {}
			local function valide(surface: Vector3): boolean
				if plat(surface - C).Magnitude > R * 1.3 or plat(surface - C).Magnitude < 6.5 then return false end
				for _, q in places do
					if (q - surface).Magnitude < 4.5 then return false end
				end
				return true
			end
			local nTresor = rng:NextInteger(7, 9)
			for _ = 1, nTresor * 10 do
				if #places >= nTresor then break end
				local a = rng:NextNumber(0, 2 * math.pi)
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				if dir:Dot(-u) < 0.5 then
					local def = if #places == 0 then tirer({TRESOR[4], TRESOR[5], TRESOR[6]}, rng) else tirer(TRESOR, rng)
					local surface
					if rng:NextNumber() < 0.55 then
						surface = outils.minerai(def, C + Vector3.new(0, rng:NextNumber(1, 4), 0), dir * R * 1.8, rng:NextNumber(1.1, 1.35), valide)
					else
						surface = outils.minerai(def, C + dir * R * rng:NextNumber(0.5, 0.85) + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rng:NextNumber(1.1, 1.35), valide)
					end
					if surface then table.insert(places, surface) end
				end
			end
			T.zone(C, R + 4, P.cyan:Lerp(P.aurore3, 0.35), "Tresor")
			ctx.modele:SetAttribute("SalleScellee", C)

			-- les 3 leviers gelés : salles les plus espacées (jamais le départ ni la salle hôte ; boss en dernier recours)
			local cands = {}
			for _, s in salles do
				if not s.depart and not s.boss and s ~= hote and plat(s.p - depart.p).Magnitude > 45 then table.insert(cands, s) end
			end
			if #cands < 3 and not hote.boss then table.insert(cands, hote) end
			if #cands < 3 then table.insert(cands, boss) end
			local choisies = {}
			for i = 1, 3 do
				local best, score = nil, -1
				for _, s in cands do
					local d = plat(s.p - depart.p).Magnitude * 0.5
					for _, c in choisies do d = math.min(d, plat(s.p - c.p).Magnitude) end
					if d > score then best, score = s, d end
				end
				if best then
					table.insert(choisies, best)
					table.remove(cands, table.find(cands, best))
				else
					table.insert(choisies, choisies[(i - 2) % #choisies + 1]) -- grotte minuscule : 2 leviers dans une salle
				end
			end
			for i, s in choisies do
				local sol = nil
				for _, f in {0.72, 0.55, 0.4, 0.25} do
					local q = T.coinSalle(s, s.r * f)
					local hit = T.solEn(q, 8)
					if hit and T.libre(hit.Position, 4) then sol = hit break end
				end
				sol = sol or T.solEn(s.p, 10)
				if sol then
					local pos = sol.Position
					local cf = CFrame.lookAt(pos, pos + unite(plat(s.p - pos), Vector3.zAxis))
					local lv = T.modele("LevierGlace")
					local socle = T.solide(lv, Vector3.new(3.2, 1.2, 2.4), cf * CFrame.new(0, 0.5, 0), P.statue, Enum.Material.Slate, "Socle")
					for _, x in {-1, 1} do
						T.bloc(lv, Vector3.new(0.4, 1.6, 1.4), cf * CFrame.new(x * 0.9, 1.8, 0), P.metal, M.Metal, "Joue")
					end
					T.disque(lv, 2.2, 0.5, cf * CFrame.new(0, 1.9, 0), P.metal, M.Metal, "Axe")
					local charniere = cf * CFrame.new(0, 1.9, 0)
					local manche = T.modele("Manche", lv)
					T.bloc(manche, Vector3.new(0.35, 3.2, 0.35), charniere * CFrame.new(0, 1.6, 0), P.metal, M.Metal, "Tige")
					local pommeau = T.boule(manche, Vector3.one * 0.95, charniere * CFrame.new(0, 3.3, 0), P.cyan, M.Neon, "Pommeau")
					pommeau.CastShadow = false
					manche.WorldPivot = charniere
					manche:PivotTo(charniere * CFrame.Angles(0.5, 0, 0))
					manche:SetAttribute("Charniere", charniere)
					T.bloc(lv, Vector3.new(0.9, 0.9, 0.2), cf * CFrame.new(0, 0.6, -1.25) * CFrame.Angles(0, 0, math.pi / 4), rgb(40, 70, 110), M.Lisse, "Voyant")
					-- la gangue de glace qui le retient
					local g = T.modele("GangueGlace", lv)
					local bloc = transparent(T.bloc(g, Vector3.new(3.8, 5, 3.4), cf * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.05, 0.05)),
						P.glace, GLASS, "Gangue"), 0.35)
					for k = 0, 3 do
						transparent(T.coin(g, Vector3.new(1.4, 1.6, 0.9), cf * CFrame.new(0, 5.4, 0) * CFrame.Angles(0, k * math.pi / 2 + 0.3, 0) * CFrame.new(0, 0, 0.6), P.glaceClaire, GLASS, "Pointe"), 0.3)
					end
					T.boule(g, Vector3.new(4.6, 1, 4), cf * CFrame.new(0, 0.2, 0), P.neige, SNOW, "Givre").CastShadow = false
					T.remplir(bloc, P.cyan, 0.7, 14)
					local invite = Instance.new("ProximityPrompt")
					invite.ActionText, invite.ObjectText = "Briser la glace", "Levier gelé " .. i .. " / 3"
					invite.HoldDuration, invite.MaxActivationDistance, invite.RequiresLineOfSight = 2.5, 10, false
					invite:SetAttribute("LevierGlace", "Gele")
					invite.Parent = socle
					T.interdire(pos, 5)
				end
			end
			ctx.modele:SetAttribute("LeviersGlaceTotal", 3)
		end
	end

	-- ===== 1. Bivouac gelé =====
	do
		local avant = unite(plat((salles[2] and salles[2].p or depart.p + Vector3.new(0, 0, -1)) - depart.p), Vector3.new(0, 0, -1))
		local droite = avant:Cross(Vector3.yAxis).Unit
		local m = T.modele("BivouacGele")
		-- tente en peaux
		local qT = T.solEn(depart.p - droite * 12 - avant * 1)
		if qT then
			local cf = CFrame.lookAt(qT.Position, qT.Position + droite)
			T.coin(m, Vector3.new(5, 4, 3), cf * CFrame.new(0, 2, -1.5), P.peau, Enum.Material.Fabric, "Toile")
			T.coin(m, Vector3.new(5, 4, 3), cf * CFrame.new(0, 2, 1.5) * CFrame.Angles(0, math.pi, 0), P.peau:Lerp(P.neige, 0.25), Enum.Material.Fabric, "Toile")
			T.bloc(m, Vector3.new(5.4, 0.4, 0.5), cf * CFrame.new(0, 4.05, 0), P.neige, SNOW, "NeigeToit")
		end
		-- feu de camp : pierres, bûches, flammes (la seule chaleur de la grotte)
		local qF = T.solEn(depart.p + droite * 8 + avant * 3)
		if qF then
			local c = qF.Position
			for k = 0, 7 do
				local a = k / 8 * 2 * math.pi
				T.boule(m, Vector3.new(1, 0.7, 1), CFrame.new(c + Vector3.new(math.cos(a) * 1.6, 0.25, math.sin(a) * 1.6)), P.statue, Enum.Material.Slate, "Pierre")
			end
			for k = 0, 2 do
				T.bloc(m, Vector3.new(0.5, 0.5, 2.6), CFrame.new(c + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, k * math.pi / 3, 0.15), P.bois, M.Bois, "Buche")
			end
			local braises = T.bloc(m, Vector3.new(1.4, 0.3, 1.4), CFrame.new(c + Vector3.new(0, 0.45, 0)), P.feu, M.Neon, "Braises")
			O.feu(braises, 4)
			T.lumiere(braises, P.feu, 1.6, 26)
		end
		-- traîneau chargé
		local qS = T.solEn(depart.p - droite * 10 + avant * 9)
		if qS then
			local cf = CFrame.lookAt(qS.Position, qS.Position + avant)
			for _, x in {-1, 1} do
				T.bloc(m, Vector3.new(0.25, 0.25, 5.5), cf * CFrame.new(x * 1.2, 0.15, 0), P.metal, M.Metal, "Patin")
				T.bloc(m, Vector3.new(0.25, 0.9, 0.25), cf * CFrame.new(x * 1.2, 2.6, 2.7) * CFrame.Angles(-0.5, 0, 0), P.metal, M.Metal, "Pointe")
			end
			T.bloc(m, Vector3.new(2.8, 0.3, 4.6), cf * CFrame.new(0, 0.75, 0), P.bois, M.Planches, "Plateau")
			for k = 0, 1 do
				T.bloc(m, Vector3.new(1.6, 1.3, 1.6), cf * CFrame.new(0, 1.55, -1.2 + k * 2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), P.bois:Lerp(P.neige, 0.15), M.Planches, "Caisse")
			end
		end
		-- skis plantés dans la congère
		local qK = T.solEn(depart.p + droite * 12 - avant * 2)
		if qK then
			T.boule(m, Vector3.new(5, 1.6, 4), CFrame.new(qK.Position), P.neige, SNOW, "Congere")
			for _, x in {-0.4, 0.4} do
				T.bloc(m, Vector3.new(0.15, 5, 0.4), CFrame.new(qK.Position + Vector3.new(x, 2.6, 0)) * CFrame.Angles(0.1, 0, x * 0.3), rgb(150, 40, 40), M.Lisse, "Ski")
			end
		end
		T.zone(depart.p, 34, rgb(255, 190, 130), "Camp")
	end

	-- ===== 2. LE LAC GELÉ =====
	local lac = candidates[1]
	if lac then
		local sol = T.solEn(lac.p, 10)
		if sol then
			roles[lac] = "lac"
			local y0 = sol.Position.Y
			local c = Vector3.new(lac.p.X, y0, lac.p.Z)
			local R = math.min(lac.r * 0.8, 24)
			-- le sol devient de la vraie glace (seule la couche du sol : les parois restent du glacier)
			local reg = Region3.new(Vector3.new(c.X - R, y0 - 6, c.Z - R), Vector3.new(c.X + R, y0 + 1, c.Z + R)):ExpandToGrid(4)
			terrain:ReplaceMaterial(reg, 4, ctx.matPart, ICE)
			local m = T.modele("LacGele")
			-- fissures bleues qui partent du centre
			for k = 1, 9 do
				local a = k / 9 * 2 * math.pi + rng:NextNumber(-0.2, 0.2)
				local d0, L = rng:NextNumber(1, 4), rng:NextNumber(R * 0.4, R * 0.85)
				local q = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (d0 + L / 2)
				local hit = T.solEn(q, 4)
				if hit then
					transparent(T.bloc(m, Vector3.new(0.18, 0.05, L), CFrame.lookAt(hit.Position + Vector3.new(0, 0.04, 0), hit.Position + Vector3.new(math.cos(a), 0.04, math.sin(a)))
						* CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), P.cyan, M.Neon, "Fissure"), 0.25)
				end
			end
			-- aiguilles de glace géantes (hors passage)
			local nAig = 0
			for _ = 1, 14 do
				if nAig >= 5 then break end
				local a, d = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0.35, 0.8) * R
				local hit = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * d, 6)
				if hit and T.solLibre(hit.Position, 3, 7) then
					nAig += 1
					local h = rng:NextNumber(8, 15)
					local base = CFrame.new(hit.Position - Vector3.new(0, 0.5, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 6), rng:NextNumber(-0.12, 0.12))
					local ag = T.modele("AiguilleGlace", m)
					transparent(T.bloc(ag, Vector3.new(h * 0.22, h * 0.7, h * 0.22), base * CFrame.new(0, h * 0.35, 0) * CFrame.Angles(0, math.pi / 4, 0), P.glace, ICE, "Fut"), 0.2)
					for k = 0, 3 do
						transparent(T.coin(ag, Vector3.new(h * 0.22, h * 0.3, h * 0.11), base * CFrame.new(0, h * 0.85, 0) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 4, 0) * CFrame.new(0, 0, h * 0.055),
							P.glaceClaire, ICE, "Pointe"), 0.2)
					end
					local coeur = T.bloc(ag, Vector3.new(0.3, h * 0.6, 0.3), base * CFrame.new(0, h * 0.35, 0), P.cyan, M.Neon, "Coeur")
					coeur.CastShadow = false
					T.tag(coeur, "GrottePulse")
					if nAig <= 2 then T.lumiere(coeur, P.cyan, 1.2, 26) end
					T.interdire(hit.Position, 3)
				end
			end
			-- blocs de glace où sont pris des poissons
			local nBlocs = 0
			for _ = 1, 10 do
				if nBlocs >= 3 then break end
				local a, d = rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0.4, 0.85) * R
				local hit = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * d, 6)
				if hit and T.solLibre(hit.Position, 2.5, 6) then
					nBlocs += 1
					local cf = CFrame.new(hit.Position + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), rng:NextNumber(-0.1, 0.1))
					local b = T.modele("BlocPoissons", m)
					for k = 1, rng:NextInteger(2, 3) do
						local f = cf * CFrame.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.4, 0.4)) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0)
						local col = if k == 2 then P.cyan:Lerp(P.glaceProfonde, 0.4) else P.poisson
						T.boule(b, Vector3.new(0.5, 0.6, 1.3), f, col, M.Lisse, "Poisson")
						T.coin(b, Vector3.new(0.12, 0.6, 0.5), f * CFrame.new(0, 0, 0.85), col, M.Lisse, "Queue")
					end
					transparent(T.bloc(b, Vector3.new(3.2, 2.2, 2), cf, P.glace, GLASS, "Bloc"), 0.45)
				end
			end
			-- brume froide au ras du sol
			local brume = T.volume(m, Vector3.new(R * 1.6, 2, R * 1.6), CFrame.new(c + Vector3.new(0, 1, 0)), "BrumeFroide")
			T.emetteur(brume, {
				Name = "Brume", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.glaceClaire), LightInfluence = 0.4, LightEmission = 0.1,
				Size = NumberSequence.new(5, 9), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.4, 0.82), T.kp(1, 1)}),
				Lifetime = NumberRange.new(7, 11), Speed = NumberRange.new(0.3, 0.7), Rate = 5, Shape = Enum.ParticleEmitterShape.Box,
				Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-5, 5),
			})
			local lueur = T.volume(m, Vector3.one, CFrame.new(c + Vector3.new(0, 3, 0)), "LueurLac")
			T.lumiere(lueur, P.glace, 1, 40)
			ctx.modele:SetAttribute("LacGele", c)
			T.zone(c, R + 8, P.cyan, "LacGele")
		end
	end

	-- ===== 3. AURORES sous la voûte des salles hautes (et de la plus grande salle restante) =====
	local nAurores = 0
	for i, s in candidates do
		if nAurores >= 3 then break end
		if s.haute or i == 2 then
			local sol = T.solEn(s.p, 10)
			local y0 = if sol then sol.Position.Y else s.p.Y
			local haut = T.plafondEn(Vector3.new(s.p.X, y0 + 2, s.p.Z), 90)
			if haut and haut.Position.Y - y0 > 22 then
				nAurores += 1
				roles[s] = roles[s] or "aurore"
				aurore(Vector3.new(s.p.X, 0, s.p.Z), s.r * 0.6, haut.Position.Y - 4)
				if roles[s] == "aurore" then
					T.zone(s.p, s.r + 4, P.aurore1:Lerp(P.aurore2, 0.4), "Aurore")
				end
			end
		end
	end

	-- ===== 4. Galeries et salles : cristaux de givre, congères, nains figés, neige =====
	for _ = 1, 22 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local hit = outils.paroi(pt.p, lat, rng:NextNumber(0.5, 7), pt.r + 6)
		if hit and (hit.Position - depart.p).Magnitude > 20 then
			grappe(outils.axeVers(hit.Position - hit.Normal * 0.4, hit.Normal), rng:NextNumber(1.3, 2.8))
		end
	end
	for _ = 1, 16 do
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.75, 0.95))
		if q and T.solLibre(q.Position, 1, 3) then
			T.boule(decor, Vector3.new(rng:NextNumber(3, 6), rng:NextNumber(0.8, 1.6), rng:NextNumber(2.5, 4)), CFrame.new(q.Position) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
				P.neige, SNOW, "Congere").CastShadow = false
		end
	end
	local nNains = 0
	for _ = 1, 30 do
		if nNains >= 6 then break end
		local pt = T.chemin[rng:NextInteger(1, #T.chemin)]
		local lat = Vector3.new(-pt.t.Z, 0, pt.t.X) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local q = T.solEn(pt.p + lat * pt.r * rng:NextNumber(0.7, 0.85))
		if q and (q.Position - depart.p).Magnitude > 30 and T.solLibre(q.Position, 2.5, 5) then
			nNains += 1
			nainGele(q.Position, unite(plat(pt.t * (if rng:NextNumber() < 0.5 then 1 else -1) - lat * 0.6), Vector3.zAxis), rng:NextNumber(0.9, 1.1))
			T.interdire(q.Position, 3)
		end
	end
	for _, s in salles do
		if not s.depart then
			neige(s, if s.boss then 22 else 12)
		end
	end

	-- ===== 5. LA CATHÉDRALE DE GIVRE (salle du boss) =====
	do
		local s = boss
		local sol = T.solEn(s.p, 10)
		local y0 = if sol then sol.Position.Y else s.p.Y
		local c = Vector3.new(s.p.X, y0, s.p.Z)
		local haut = T.plafondEn(c + Vector3.new(0, 2, 0), 90)
		local yH = if haut then haut.Position.Y else y0 + 40
		local m = T.modele("CathedraleGivre")
		-- piliers de glace (fût, chapiteau, anneau lumineux)
		for k = 0, 7 do
			local a = k / 8 * 2 * math.pi + math.pi / 8
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.8)
			if q and T.libre(q.Position, 1) then
				local col = T.modele("PilierGlace", m)
				local h = math.min(16, yH - q.Position.Y - 2)
				transparent(T.cylindre(col, h, 2.8, CFrame.new(q.Position + Vector3.new(0, h / 2, 0)), P.glace, ICE, "Fut"), 0.15)
				T.cylindre(col, 0.8, 4, CFrame.new(q.Position + Vector3.new(0, 0.4, 0)), P.glaceProfonde, ICE, "Base")
				T.cylindre(col, 0.8, 4, CFrame.new(q.Position + Vector3.new(0, h - 0.4, 0)), P.glaceProfonde, ICE, "Chapiteau")
				local anneau = T.cylindre(col, 0.3, 3.2, CFrame.new(q.Position + Vector3.new(0, h * 0.55, 0)), P.cyan, M.Neon, "Anneau")
				anneau.CastShadow = false
				if k % 2 == 0 then T.lumiere(anneau, P.cyan, 1, 22) end
			end
		end
		-- lustre de cristal suspendu à la voûte
		local yL = math.min(y0 + 24, yH - 7)
		local pc = Vector3.new(c.X, yL, c.Z)
		local lustre = T.modele("LustreGivre", m)
		local noyau = T.boule(lustre, Vector3.new(3, 3.6, 3), CFrame.new(pc), P.cyan, M.Neon, "Noyau")
		noyau.CastShadow = false
		T.tag(noyau, "GrottePulse")
		transparent(T.boule(lustre, Vector3.new(5, 6, 5), CFrame.new(pc), P.glace, GLASS, "Coque"), 0.5)
		transparent(T.bloc(lustre, Vector3.new(1.2, yH - yL + 2, 1.2), CFrame.new(c.X, (yH + yL) / 2 + 1, c.Z) * CFrame.Angles(0, math.pi / 4, 0), P.glace, ICE, "Tige"), 0.2)
		for k = 0, 9 do
			local a = k / 10 * 2 * math.pi
			local r = if k % 2 == 0 then 4.5 else 3
			local q = pc + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local L = if k % 2 == 0 then 5 else 3.5
			transparent(T.bloc(lustre, Vector3.new(0.7, L, 0.7), CFrame.new(q - Vector3.new(0, L / 2 - 0.5, 0)) * CFrame.Angles(0, math.pi / 4, 0), P.glaceClaire, GLASS, "Pendeloque"), 0.3)
			transparent(T.bloc(lustre, Vector3.new(0.4, r, 0.4), CFrame.lookAt(pc:Lerp(q, 0.5) + Vector3.new(0, 0.6, 0), q + Vector3.new(0, 0.6, 0)) * CFrame.Angles(math.pi / 2, 0, 0),
				P.glace, ICE, "Branche"), 0.2)
		end
		T.lumiere(noyau, P.cyan, 2.5, 60)
		T.emetteur(noyau, {
			Name = "Givre", Texture = GT.TEX_ETINCELLE, LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(P.glaceClaire, P.cyan),
			Size = NumberSequence.new({T.kp(0, 0.4), T.kp(1, 0)}), Lifetime = NumberRange.new(2, 4), Rate = 14, Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -1.5, 0),
		})
		-- nains agenouillés pris dans la glace, tournés vers le centre
		for k = 0, 3 do
			local a = k / 4 * 2 * math.pi + math.pi / 4
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.62)
			if q and T.libre(q.Position, 1) then
				nainGele(q.Position, unite(plat(c - q.Position), Vector3.zAxis), 1.15, true).Parent = m
			end
		end
		-- cercle de runes givrées
		for k = 0, 31 do
			local a = k / 32 * 2 * math.pi
			local q = T.solEn(c + Vector3.new(math.cos(a), 0, math.sin(a)) * T.rb * 0.5)
			if q then
				transparent(T.bloc(m, Vector3.new(0.25, 0.08, 2.4), CFrame.lookAt(q.Position + Vector3.new(0, 0.06, 0), q.Position + Vector3.new(0, 0.06, 0) + Vector3.new(-math.sin(a), 0, math.cos(a))),
					P.cyan, M.Neon, "CercleRunes"), 0.2)
			end
		end
		local brume = T.volume(m, Vector3.new(T.rb * 1.6, 3, T.rb * 1.6), CFrame.new(c + Vector3.new(0, 1.5, 0)), "BrumeGivre")
		T.emetteur(brume, {
			Name = "Brume", Texture = GT.TEX_FUMEE, Color = ColorSequence.new(P.glaceClaire:Lerp(P.cyan, 0.2)), LightInfluence = 0.3, LightEmission = 0.2,
			Size = NumberSequence.new(5, 10), Transparency = NumberSequence.new({T.kp(0, 1), T.kp(0.3, 0.8), T.kp(1, 1)}),
			Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.3, 0.8), Rate = 6, Shape = Enum.ParticleEmitterShape.Box,
		})
		ctx.modele:SetAttribute("ArenaGivre", c)
		T.zone(c, T.rb + 8, P.glace:Lerp(P.aurore2, 0.4), "Givre")
	end

	-- ===== 6. Décor générique (stalactites de glace), veines de givre, éclairage, guide =====
	T.decorGenerique({cristaux = false, bassins = false, torches = false, poussieres = false, boss = false, champignons = false, humide = false,
		mine = false, racines = false, couleurs = COUL_GENERIQUE})
	T.veinesEtGalets({P.cyan, P.glace, P.cyan, P.aurore2}, 4, P.glaceClaire)
	T.eclairageBase({
		teinte = function(s)
			if s.depart then return P.feu:Lerp(P.glaceClaire, 0.5) end
			if roles[s] == "lac" then return P.glace end
			if roles[s] == "aurore" then return P.aurore1:Lerp(P.glace, 0.5) end
			if s.boss then return P.cyan:Lerp(P.glaceClaire, 0.3) end
			return P.glace:Lerp(P.glaceClaire, 0.3)
		end,
		galerie = P.glace:Lerp(P.glaceClaire, 0.5),
		lum = 0.6,
	})
	T.guide()
	ctx.modele:SetAttribute("Theme", "GlaceEternelle")
end

return GrotteGlace
