--!strict
-- Aura des pioches (ServerScriptService › Jeu › AuraPioche), la même que dans l'Atelier 3D.
-- AuraPioche.ajouter(tool, handle, reglage) entoure la pioche d'une aura séparée de ses pièces :
-- halo, énergie, étincelles, poussière lumineuse, et selon le style fumée, neige, éclairs, volutes,
-- ailes et auréole (Divin), vortex (Ombre), cercles de runes (Arcane). Réglages : Partage › AurasPioches.

local TweenService = game:GetService("TweenService")

local TEX_FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_ETINCELLE = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FEU = "rbxasset://textures/particles/fire_main.dds"

type Style = {
	halo: number, energie: number, tailleEnergie: number, monte: number, etincelles: number,
	poussiere: number, fumee: number, neige: number, volutes: boolean, eclairs: number, rayons: boolean, leger: boolean?,
}

-- Dosage de chaque style (particules par seconde) et effets propres
local STYLES: {[string]: Style} = {
	Flammes = {halo = 6, energie = 70, tailleEnergie = 1.3, monte = 8, etincelles = 25, poussiere = 0, fumee = 6, neige = 0, volutes = false, eclairs = 0, rayons = false},
	Givre = {halo = 22, energie = 0, tailleEnergie = 0.6, monte = 1, etincelles = 8, poussiere = 10, fumee = 0, neige = 25, volutes = true, eclairs = 0, rayons = false},
	Foudre = {halo = 10, energie = 10, tailleEnergie = 0.5, monte = 3, etincelles = 45, poussiere = 0, fumee = 0, neige = 0, volutes = true, eclairs = 3, rayons = false},
	Ombre = {halo = 14, energie = 20, tailleEnergie = 0.8, monte = 2, etincelles = 6, poussiere = 16, fumee = 20, neige = 0, volutes = false, eclairs = 1, rayons = false},
	Divin = {halo = 24, energie = 20, tailleEnergie = 0.6, monte = 2, etincelles = 10, poussiere = 24, fumee = 0, neige = 0, volutes = false, eclairs = 0, rayons = true},
	Arcane = {halo = 18, energie = 40, tailleEnergie = 0.7, monte = 4, etincelles = 14, poussiere = 20, fumee = 0, neige = 0, volutes = true, eclairs = 1, rayons = false},
	Cristal = {halo = 8, energie = 6, tailleEnergie = 0.4, monte = 2, etincelles = 8, poussiere = 12, fumee = 0, neige = 0, volutes = false, eclairs = 0, rayons = false, leger = true},
	Eclat = {halo = 2, energie = 0, tailleEnergie = 0.4, monte = 1, etincelles = 4, poussiere = 3, fumee = 0, neige = 0, volutes = false, eclairs = 0, rayons = false, leger = true},
}

-- Opacité des coques de l'Atelier (liseré, halo, langues) pour chaque style
local COQUES: {[string]: {number}} = {
	Flammes = {0.45, 0.2, 1.1},
	Givre = {0.8, 0.5, 0},
	Foudre = {0.9, 0.35, 0.25},
	Ombre = {0.8, 0.3, 0.6},
	Divin = {0.6, 0.6, 0.2},
	Arcane = {0.6, 0.45, 0.5},
	Cristal = {0.45, 0.2, 0},
	Eclat = {0.22, 0.05, 0},
}

export type Reglage = {style: string, couleur: Color3, couleur2: Color3, intensite: number}

local AuraPioche = {}

local function emetteur(parent: Instance, props: {[string]: any}): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	for cle, valeur in props do
		(e :: any)[cle] = valeur
	end
	e.Parent = parent
	return e
end

-- Boîte qui englobe toutes les pièces de l'outil, dans le repère de la poignée.
-- Elle est tournée pour que la tête de la pioche soit le long de son axe X (comme dans l'Atelier).
local function boite(tool: Tool, handle: BasePart): (CFrame, Vector3)
	local mini, maxi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Aura" then
			local local_ = handle.CFrame:ToObjectSpace(p.CFrame)
			local d = p.Size / 2
			for _, c in {Vector3.new(-1, -1, -1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, -1), Vector3.new(1, 1, -1),
				Vector3.new(-1, -1, 1), Vector3.new(1, -1, 1), Vector3.new(-1, 1, 1), Vector3.new(1, 1, 1)} do
				local v = local_ * (d * c)
				mini, maxi = mini:Min(v), maxi:Max(v)
			end
		end
	end
	local taille = maxi - mini
	local cadre = handle.CFrame * CFrame.new((mini + maxi) / 2)
	if taille.Z > taille.X then
		cadre = cadre * CFrame.Angles(0, math.rad(90), 0)
		taille = Vector3.new(taille.Z, taille.Y, taille.X)
	end
	return cadre, taille
end

function AuraPioche.ajouter(tool: Tool, handle: BasePart, reglage: Reglage?)
	if not reglage or reglage.intensite <= 0 then return end
	local st = STYLES[reglage.style]
	if not st then
		warn("AuraPioche : style inconnu « " .. tostring(reglage.style) .. " »")
		return
	end
	local k = reglage.intensite
	local COULEUR, COULEUR2 = reglage.couleur, reglage.couleur2
	local cadre, taille = boite(tool, handle)
	local degrade = ColorSequence.new(COULEUR2, COULEUR)
	local BOITE, VOLUME, SURFACE = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, Enum.ParticleEmitterShapeStyle.Surface

	-- Volume invisible qui englobe la pioche : toute l'aura vit dedans
	local volume = Instance.new("Part")
	volume.Name = "Aura"
	volume.Size = taille + Vector3.new(0.6, 0.6, 0.6)
	volume.CFrame = cadre
	volume.Transparency = 1
	volume.CanCollide = false
	volume.CanQuery = false
	volume.CanTouch = false
	volume.CastShadow = false
	volume.Massless = true
	volume.Parent = tool
	local soudure = Instance.new("WeldConstraint")
	soudure.Part0 = handle
	soudure.Part1 = volume
	soudure.Parent = volume

	-- 1. Halo : grosses lueurs douces qui enveloppent l'arme
	emetteur(volume, {
		Name = "Halo", Texture = TEX_ETINCELLE, Color = degrade, Shape = BOITE, ShapeStyle = VOLUME,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1.6), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new(0.8, 1), Lifetime = NumberRange.new(0.8, 1.4),
		Rate = st.halo * k, Speed = NumberRange.new(0, 0.2), LockedToPart = true,
	})
	-- 2. Énergie qui s'échappe vers le haut (vraies flammes en style Flammes)
	emetteur(volume, {
		Name = "Energie", Texture = TEX_FEU, Color = degrade, Shape = BOITE, ShapeStyle = SURFACE,
		Size = NumberSequence.new(st.tailleEnergie, 0), Transparency = NumberSequence.new(0.3, 1),
		Lifetime = NumberRange.new(0.5, 0.9), Rate = st.energie * k, Speed = NumberRange.new(0.3, 1),
		Acceleration = Vector3.new(0, st.monte, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
	})
	-- 3. Étincelles (les braises montent en style Flammes, retombent sinon)
	emetteur(volume, {
		Name = "Etincelles", Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.new(1, 1, 1), COULEUR2),
		Shape = BOITE, ShapeStyle = SURFACE, Size = NumberSequence.new(0.18, 0),
		Lifetime = NumberRange.new(0.5, 1), Rate = st.etincelles * k, Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180), Drag = 3, Acceleration = Vector3.new(0, reglage.style == "Flammes" and 5 or -4, 0),
	})
	-- 4. Poussière lumineuse qui flotte (tombe doucement en Givre et Divin)
	emetteur(volume, {
		Name = "Poussiere", Texture = TEX_ETINCELLE, Color = degrade, Shape = BOITE, ShapeStyle = VOLUME,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0)}),
		Lifetime = NumberRange.new(1.5, 2.5), Rate = st.poussiere * k, Speed = NumberRange.new(0.2, 0.6),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, (reglage.style == "Givre" or reglage.style == "Divin") and -0.6 or 0.6, 0),
	})
	-- Fumée : cendre au-dessus des flammes, ou fumée sombre qui tourne (Ombre)
	if st.fumee > 0 then
		local ombre = reglage.style == "Ombre"
		emetteur(volume, {
			Name = "Fumee", Texture = TEX_FUMEE, LightEmission = 0, LightInfluence = 1,
			Color = ColorSequence.new(ombre and COULEUR:Lerp(Color3.new(0, 0, 0), 0.75) or Color3.fromRGB(60, 50, 45)),
			Shape = BOITE, ShapeStyle = VOLUME, Size = NumberSequence.new(1, 2.6), Transparency = NumberSequence.new(0.55, 1),
			Lifetime = NumberRange.new(1.2, 2), Rate = st.fumee * k, Speed = NumberRange.new(0.3, 1),
			Acceleration = Vector3.new(0, ombre and 0.3 or 3, 0), RotSpeed = NumberRange.new(-60, 60), Rotation = NumberRange.new(0, 360),
		})
	end
	-- Neige qui tombe autour (Givre)
	if st.neige > 0 then
		emetteur(volume, {
			Name = "Neige", Texture = TEX_ETINCELLE, Color = ColorSequence.new(COULEUR2),
			Shape = BOITE, ShapeStyle = VOLUME, Size = NumberSequence.new(0.15, 0.1),
			Lifetime = NumberRange.new(2, 3), Rate = st.neige * k, Speed = NumberRange.new(0, 0.2),
			Acceleration = Vector3.new(0, -1.5, 0), SpreadAngle = Vector2.new(180, 180),
		})
	end
	-- Rayons de lumière (Divin)
	if st.rayons then
		emetteur(volume, {
			Name = "Rayons", Texture = TEX_ETINCELLE, Color = degrade, Size = NumberSequence.new(taille.X * 1.1),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 1)}),
			Lifetime = NumberRange.new(1.6), Rate = 1.5 * k, Speed = NumberRange.new(0), LockedToPart = true,
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15),
		})
	end
	-- Éclairs : rayons qui sautent d'un point à l'autre quand l'arme est équipée
	if st.eclairs > 0 then
		local arcs = {}
		for i = 1, st.eclairs do
			local a0 = Instance.new("Attachment")
			a0.Parent = volume
			local a1 = Instance.new("Attachment")
			a1.Parent = volume
			local arc = Instance.new("Beam")
			arc.Name = "Eclair" .. i
			arc.Attachment0 = a0
			arc.Attachment1 = a1
			arc.Color = ColorSequence.new(COULEUR2)
			arc.LightEmission = 1
			arc.LightInfluence = 0
			arc.Width0 = 0.12
			arc.Width1 = 0.04
			arc.FaceCamera = true
			arc.Segments = 6
			arc.Enabled = false
			arc.Parent = volume
			table.insert(arcs, {arc = arc, a0 = a0, a1 = a1})
		end
		local function auHasard(): Vector3
			return Vector3.new((math.random() - 0.5) * taille.X, (math.random() - 0.5) * taille.Y, (math.random() - 0.5) * taille.Z)
		end
		task.defer(function() -- après que l'outil a été rangé dans le sac
			while tool.Parent do
				local equipe = (tool.Parent :: Instance):IsA("Model")
				for _, e in arcs do
					e.arc.Enabled = equipe and math.random() < 0.6
					if e.arc.Enabled then
						e.a0.Position = auHasard()
						e.a1.Position = e.a0.Position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 3
						e.arc.CurveSize0 = (math.random() - 0.5) * 3
						e.arc.CurveSize1 = (math.random() - 0.5) * 3
					end
				end
				task.wait(equipe and 0.12 or 0.5)
			end
		end)
	end
	-- 5. Volutes : trois rubans courbes qui filent du manche à la tête
	for i = 1, (st.volutes and 3 or 0) do
		local angle = (i / 3) * math.pi * 2
		local a0 = Instance.new("Attachment")
		a0.CFrame = CFrame.new(0, -taille.Y / 2, 0) * CFrame.Angles(0, angle, 0)
		a0.Parent = volume
		local a1 = Instance.new("Attachment")
		a1.CFrame = CFrame.new(0, taille.Y * 0.35, 0) * CFrame.Angles(0, angle + math.pi / 2, 0)
		a1.Parent = volume
		local ruban = Instance.new("Beam")
		ruban.Name = "Volute" .. i
		ruban.Attachment0 = a0
		ruban.Attachment1 = a1
		ruban.CurveSize0 = 2.2
		ruban.CurveSize1 = -2.2
		ruban.Texture = TEX_ETINCELLE
		ruban.TextureMode = Enum.TextureMode.Wrap
		ruban.TextureLength = 1.2
		ruban.TextureSpeed = 1 + 0.3 * i
		ruban.Color = degrade
		ruban.LightEmission = 1
		ruban.LightInfluence = 0
		ruban.Width0 = 0.3 * k
		ruban.Width1 = 0.12 * k
		ruban.FaceCamera = true
		ruban.Segments = 24
		ruban.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 1)})
		ruban.Parent = volume
	end

	-- ===== Signature du style : Divin (ailes, auréole, colonne), Ombre (vortex), Arcane (cercles de runes) =====
	-- Les pièces qui tournent sont reliées par des charnières motorisées : la physique les anime
	-- sur l'écran du joueur, sans à-coups, et elles ne pèsent presque rien.
	local yTete = taille.Y * 0.34 -- hauteur du centre de la tête de la pioche
	local function piece(nom: string, dims: Vector3, couleur: Color3, transparence: number, parent: Instance): Part
		local p = Instance.new("Part")
		p.Name = nom
		p.Size = dims
		p.Material = Enum.Material.Neon
		p.Color = couleur
		p.Transparency = transparence
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
		p.Parent = parent
		return p
	end
	local function souder(a: BasePart, b: BasePart)
		local w = Instance.new("WeldConstraint")
		w.Part0 = a
		w.Part1 = b
		w.Parent = b
	end
	-- Pivot invisible relié à l'aura par une charnière. Elle tourne autour de l'axe X de cadreLocal.
	local function pivot(nom: string, cadreLocal: CFrame): (Part, HingeConstraint)
		local c = piece(nom, Vector3.new(0.1, 0.1, 0.1), COULEUR, 1, volume)
		c.CFrame = volume.CFrame * cadreLocal
		local a0 = Instance.new("Attachment")
		a0.CFrame = cadreLocal
		a0.Parent = volume
		local a1 = Instance.new("Attachment")
		a1.Parent = c
		local h = Instance.new("HingeConstraint")
		h.Attachment0 = a0
		h.Attachment1 = a1
		h.Parent = c
		return c, h
	end
	local function moteur(h: HingeConstraint, vitesse: number)
		h.ActuatorType = Enum.ActuatorType.Motor
		h.AngularVelocity = vitesse
		h.MotorMaxTorque = 1e4
		h.MotorMaxAcceleration = 1e3
	end
	-- Anneau de n segments autour de l'axe X du pivot (glyphes = segments de tailles variées, comme des runes)
	local function anneau(centre: BasePart, rayon: number, n: number, couleur: Color3, transparence: number, glyphes: boolean)
		for i = 1, n do
			if glyphes and i % 6 == 0 then continue end -- petits vides entre les mots de runes
			local hauteur = glyphes and (i % 3 == 0 and 0.26 or (i % 2 == 0 and 0.16 or 0.1)) or 0.09
			local long = rayon * 2 * math.pi / n * (glyphes and 0.6 or 0.9)
			local p = piece("Segment", Vector3.new(0.05, hauteur, long), couleur, transparence, centre)
			p.CFrame = centre.CFrame * CFrame.Angles((i / n) * math.pi * 2, 0, 0) * CFrame.new(0, rayon, 0)
			souder(centre, p)
		end
	end
	local VERS_HAUT = CFrame.Angles(0, 0, math.rad(90)) -- axe X du pivot vers le haut
	local VERS_AVANT = CFrame.Angles(0, math.rad(-90), 0) -- axe X du pivot vers l'avant de la tête

	if reglage.style == "Divin" then
		-- Ailes : deux éventails de plumes lumineuses qui battent doucement
		local servos = {}
		for _, s in {-1, 1} do
			local epaule = Vector3.new(s * 0.25, yTete, -0.3)
			local aile, h = pivot("Aile", CFrame.new(epaule) * VERS_AVANT)
			h.ActuatorType = Enum.ActuatorType.Servo
			h.AngularSpeed = 1.6
			h.ServoMaxTorque = 1e4
			table.insert(servos, {h = h, s = s})
			for i = 1, 7 do
				local a = math.rad(-12 + i * 13)
				local d = Vector3.new(s * math.cos(a), math.sin(a), 0)
				local longueur = taille.X * (0.22 + 0.045 * i)
				local centre = epaule + d * (longueur / 2 + 0.1)
				local plume = piece("Plume", Vector3.new(longueur, 0.22, 0.04), COULEUR2:Lerp(COULEUR, i / 7), 0.25 + 0.03 * i, aile)
				plume.CFrame = volume.CFrame * CFrame.fromMatrix(centre, d, Vector3.zAxis:Cross(d))
				souder(aile, plume)
			end
		end
		task.defer(function()
			local haut = false
			while tool.Parent do
				haut = not haut
				for _, e in servos do
					e.h.TargetAngle = e.s * (haut and 18 or -10)
				end
				task.wait(0.7)
			end
		end)
		-- Auréole : double anneau doré qui tourne au-dessus de la tête
		local aureole, h = pivot("Aureole", CFrame.new(0, taille.Y / 2 + 0.5, 0) * VERS_HAUT)
		moteur(h, 1.2)
		anneau(aureole, 0.55, 24, COULEUR2, 0.1, false)
		anneau(aureole, 0.68, 28, COULEUR, 0.55, false)
		-- Colonne de lumière qui monte au-dessus de l'arme
		local bas = Instance.new("Attachment")
		bas.Position = Vector3.new(0, taille.Y / 2, 0)
		bas.Parent = volume
		local hautCol = Instance.new("Attachment")
		hautCol.Position = Vector3.new(0, taille.Y / 2 + 6, 0)
		hautCol.Parent = volume
		local colonne = Instance.new("Beam")
		colonne.Name = "Colonne"
		colonne.Attachment0 = bas
		colonne.Attachment1 = hautCol
		colonne.Color = degrade
		colonne.LightEmission = 1
		colonne.LightInfluence = 0
		colonne.Width0 = 1.4 * k
		colonne.Width1 = 0.3 * k
		colonne.FaceCamera = true
		colonne.Transparency = NumberSequence.new(0.55, 1)
		colonne.Parent = volume
	elseif reglage.style == "Ombre" then
		-- Vortex : bras en spirale qui tournent derrière la tête, avec un cœur lumineux
		local rayon = taille.X * 0.5
		local vortex, h = pivot("Vortex", CFrame.new(0, yTete, -0.4) * VERS_AVANT)
		moteur(h, -1.6)
		local coeur = piece("Coeur", Vector3.new(0.5, 0.5, 0.5), COULEUR2, 0.35, vortex)
		coeur.Shape = Enum.PartType.Ball
		coeur.CFrame = vortex.CFrame
		souder(vortex, coeur)
		for bras = 0, 4 do
			for s = 1, 9 do
				local t = s / 9
				local angle = bras * math.pi * 2 / 5 + t * 2.4
				local p = piece("Bras", Vector3.new(0.04, 0.22 * (1.3 - t), 0.4), COULEUR2:Lerp(COULEUR, t), 0.3 + 0.6 * t, vortex)
				p.CFrame = vortex.CFrame * CFrame.Angles(angle, 0, 0) * CFrame.new(0, rayon * t, 0)
				souder(vortex, p)
			end
		end
		-- Particules aspirées vers le centre du vortex
		local sphere = piece("Aspiration", Vector3.one * rayon * 2.4, COULEUR, 1, volume)
		sphere.Shape = Enum.PartType.Ball
		sphere.CFrame = volume.CFrame * CFrame.new(0, yTete, -0.4)
		souder(volume, sphere)
		emetteur(sphere, {
			Name = "Aspiration", Texture = TEX_ETINCELLE, Color = ColorSequence.new(COULEUR, COULEUR2),
			Shape = Enum.ParticleEmitterShape.Sphere, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, ShapeStyle = SURFACE,
			Size = NumberSequence.new(0.22, 0), Transparency = NumberSequence.new(0.2, 0.8),
			Lifetime = NumberRange.new(0.85), Rate = 30 * k, Speed = NumberRange.new(rayon * 1.2 / 0.9),
		})
	elseif reglage.style == "Arcane" then
		-- Trois cercles de runes inclinés qui tournent autour de la tête, chacun à sa vitesse
		local rayon = taille.X * 0.55
		local cercles = {
			{incl = CFrame.Angles(math.rad(12), 0, math.rad(8)), r = rayon, v = 0.8},
			{incl = CFrame.Angles(math.rad(80), 0, 0), r = rayon * 0.85, v = -1.1},
			{incl = CFrame.Angles(math.rad(-35), math.rad(40), 0), r = rayon * 1.15, v = 0.6},
		}
		for i, c in cercles do
			local cercle, h = pivot("Runes" .. i, CFrame.new(0, yTete, 0) * c.incl * VERS_HAUT)
			moteur(h, c.v)
			anneau(cercle, c.r, 30, COULEUR2, 0.2, true)
			anneau(cercle, c.r - 0.18, 40, COULEUR, 0.6, false)
		end
		-- Petit sceau de runes qui tourne autour du manche
		local sceau, h = pivot("SceauManche", CFrame.new(0, -taille.Y * 0.15, 0) * VERS_HAUT)
		moteur(h, 2.5)
		anneau(sceau, 0.38, 12, COULEUR2, 0.2, true)
	end

	-- Coques lumineuses (comme dans l'Atelier) : chaque pièce visible est doublée d'une enveloppe
	-- plus grosse en matériau ForceField, qui brille sur les bords (liseré, halo, langues).
	-- L'épaisseur suit un bruit 3D tiré au hasard à chaque création : l'aura gonfle par plaques,
	-- se creuse ailleurs, et les langues d'énergie ne sortent qu'à quelques endroits.
	local coque = COQUES[reglage.style] or {0.5, 0.2, 0}
	local couches = {
		-- base, ampleur du bruit, seuil (en dessous : pas de coque à cet endroit)
		{pousse = 0.035, alpha = coque[1], couleur = COULEUR2:Lerp(COULEUR, 0.35), base = 0.6, ampleur = 0.9, seuil = 0},
		{pousse = 0.17, alpha = coque[2], couleur = COULEUR, base = 0.4, ampleur = 1.1, seuil = 0.22},
		{pousse = 0.32, alpha = coque[3], couleur = COULEUR, base = 0.45, ampleur = 1.3, seuil = 0.5},
	}
	local flammes = reglage.style == "Flammes"
	local graine = Vector3.new(math.random() * 500, math.random() * 500, math.random() * 500)
	-- Bruit doux entre 0 et 1 (deux octaves) : des pièces voisines gonflent ensemble
	local function bruit(pos: Vector3, couche: number, t: number): number
		local q = pos * 0.85 + graine + Vector3.new(couche * 37, -t, t * 0.3)
		local n = math.noise(q.X, q.Y, q.Z) + 0.5 * math.noise(q.X * 2.3 + 11, q.Y * 2.3, q.Z * 2.3 - 7)
		return math.clamp(0.5 + n * 1.1, 0, 1)
	end
	-- Taille et position d'une coque pour une valeur de bruit n
	local function forme(p: BasePart, c: typeof(couches[1]), n: number, pos: Vector3): (Vector3, CFrame)
		local pousse = c.pousse * (c.base + c.ampleur * n) * (0.85 + math.random() * 0.3)
		local taille_ = p.Size + Vector3.one * (2 * pousse)
		local cadre_ = p.CFrame
		if flammes and c.seuil >= 0.5 then
			-- langues de feu : étirées vers le haut, plus ou moins selon l'endroit
			local monte = pousse * 1.4 * n
			taille_ += Vector3.new(0, monte, 0)
			cadre_ = cadre_ + Vector3.new(0, monte / 2, 0)
		end
		return taille_, cadre_
	end
	local pieces = {}
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "Aura" and not p:IsDescendantOf(volume) then
			table.insert(pieces, p)
		end
	end
	local vivantes = {} -- coques du halo et des langues, qui ondulent tant que la pioche est en main
	for ic, c in couches do
		local transparence = math.clamp(1 - c.alpha * k * 0.9, 0, 0.95)
		if c.alpha <= 0 or transparence >= 0.95 then continue end
		for _, p in pieces do
			local pos = handle.CFrame:PointToObjectSpace(p.Position)
			local n = bruit(pos, ic, 0)
			if n < c.seuil then continue end
			local enveloppe = p:Clone()
			enveloppe:ClearAllChildren()
			enveloppe.Name = "Coque"
			enveloppe.Material = Enum.Material.ForceField
			enveloppe.Color = c.couleur:Lerp(COULEUR2, (n - c.seuil) * 0.5)
			-- plus le bruit est fort, plus la coque est lumineuse ; les bords des plaques s'estompent
			local fondu = if c.seuil > 0 then math.clamp((n - c.seuil) / 0.2, 0.3, 1) else 1
			enveloppe.Transparency = 1 - (1 - transparence) * fondu
			enveloppe.Size, enveloppe.CFrame = forme(p, c, n, pos)
			enveloppe.Anchored = false
			enveloppe.CanCollide = false
			enveloppe.CanQuery = false
			enveloppe.CanTouch = false
			enveloppe.CastShadow = false
			enveloppe.Massless = true
			if enveloppe:IsA("MeshPart") then
				pcall(function()
					(enveloppe :: any).TextureID = ""
				end)
			end
			enveloppe:SetAttribute("Coque", true)
			enveloppe.Parent = volume
			souder(handle, enveloppe)
			if ic > 1 then
				table.insert(vivantes, {coque = enveloppe, piece = p, couche = c, ic = ic, pos = pos, opaque = enveloppe.Transparency})
			end
		end
	end
	-- Ondulation : quelques coques au hasard changent de forme à chaque instant (le bruit « monte » avec le temps)
	if #vivantes > 0 then
		task.defer(function()
			local t = 0
			while tool.Parent do
				local equipe = (tool.Parent :: Instance):IsA("Model")
				if equipe then
					t += 0.15 * (flammes and 2 or 1)
					for _ = 1, math.min(18, #vivantes) do
						local v = vivantes[math.random(#vivantes)]
						if not v.coque.Parent then continue end
						local n = bruit(v.pos, v.ic, t)
						local visible = n >= v.couche.seuil * 0.8
						local soudure_ = v.coque:FindFirstChildOfClass("WeldConstraint")
						if soudure_ then soudure_.Enabled = false end
						local taille_, cadre_ = forme(v.piece, v.couche, math.max(n, v.couche.seuil), v.pos)
						v.coque.Size = taille_
						v.coque.CFrame = cadre_
						if soudure_ then soudure_.Enabled = true end
						v.coque.Transparency = if visible then v.opaque else 1
					end
				end
				task.wait(equipe and 0.12 or 0.6)
			end
		end)
	end
	-- Scintillements qui montent autour de la pioche (orbe de l'Atelier)
	if st.leger then
		emetteur(volume, {
			Name = "Scintillements", Texture = TEX_ETINCELLE, Color = ColorSequence.new(Color3.new(1, 1, 1), COULEUR2),
			Shape = BOITE, ShapeStyle = VOLUME,
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.22), NumberSequenceKeypoint.new(1, 0)}),
			Lifetime = NumberRange.new(0.8, 1.6), Rate = (reglage.style == "Cristal" and 90 or 30) * k,
			Speed = NumberRange.new(0.3, 0.9), Acceleration = Vector3.new(0, 1.2, 0), SpreadAngle = Vector2.new(30, 30),
		})
	end

	-- 6. Lumière qui respire
	local lumiere = Instance.new("PointLight")
	lumiere.Color = COULEUR
	lumiere.Brightness = (st.leger and 0.4 or 1.5) * k
	lumiere.Range = st.leger and 5 or 10
	lumiere.Parent = volume
	TweenService:Create(lumiere, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Brightness = (st.leger and 0.8 or 3) * k}):Play()
	-- 7. Lueur de contour (un simple liseré pour les styles légers)
	local contour = Instance.new("Highlight")
	contour.Name = "ContourAura"
	contour.FillColor = COULEUR
	contour.FillTransparency = st.leger and 1 or math.clamp(1 - 0.12 * k, 0, 1)
	contour.OutlineColor = COULEUR2
	contour.OutlineTransparency = st.leger and math.clamp(1 - 0.6 * k, 0.4, 0.85) or math.clamp(1 - 0.6 * k, 0.4, 1)
	contour.DepthMode = Enum.HighlightDepthMode.Occluded
	contour.Parent = tool
end

return AuraPioche
