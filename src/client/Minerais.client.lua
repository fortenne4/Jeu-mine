-- Minerais · SCRIPT CLIENT
-- Où : StarterPlayer > StarterPlayerScripts > LocalScript
-- Effets fluides autour de chaque minerai : éclats en orbite, tourbillons lumineux,
-- arcs électriques (Fer), rayons divins + sceau au sol (Gold) et lumière qui respire.
-- Tout est créé uniquement sur ton écran : rien n'est envoyé au serveur.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "Minerai"
local DISTANCE_MAX = 160

local STYLE = {
	Charbon = {
		eclats = 6, couleur = Color3.fromRGB(26, 26, 30), materiau = Enum.Material.Slate, rayon = 2.2, vitesse = 0.5, tourbillons = {},
		lueur = Color3.fromRGB(255, 70, 20), lumiere = 0.6,
	},
	Bronze = {
		eclats = 6, couleur = Color3.fromRGB(255, 130, 50), materiau = Enum.Material.Neon, rayon = 2.3, vitesse = 0.9, lumiere = 1.2,
		tourbillons = {
			{couleur = Color3.fromRGB(255, 150, 60), inclinaison = CFrame.Angles(math.rad(65), 0, math.rad(20)), vitesse = 2.4, largeur = 0.22},
		},
	},
	Fer = {
		eclats = 6, couleur = Color3.fromRGB(165, 172, 186), materiau = Enum.Material.Metal, rayon = 2.4, vitesse = 1.1,
		lueur = Color3.fromRGB(150, 200, 255), lumiere = 1.4, arcs = 2,
		tourbillons = {
			{couleur = Color3.fromRGB(160, 205, 255), inclinaison = CFrame.Angles(math.rad(70), 0, math.rad(15)), vitesse = 2.6, largeur = 0.2},
			{couleur = Color3.fromRGB(220, 240, 255), inclinaison = CFrame.Angles(math.rad(110), 0, math.rad(-25)), vitesse = -2.1, largeur = 0.14},
		},
	},
	Gold = {
		eclats = 8, couleur = Color3.fromRGB(255, 205, 60), materiau = Enum.Material.Neon, rayon = 2.6, vitesse = 1.3,
		lumiere = 2, rayons = 8,
		tourbillons = {
			{couleur = Color3.fromRGB(255, 215, 90), inclinaison = CFrame.Angles(math.rad(70), 0, math.rad(20)), vitesse = 2.8, largeur = 0.3},
			{couleur = Color3.fromRGB(255, 240, 170), inclinaison = CFrame.Angles(math.rad(105), 0, math.rad(-30)), vitesse = -2.3, largeur = 0.2},
		},
	},
}

local dossier = Instance.new("Folder")
dossier.Name = "EffetsMinerais"
dossier.Parent = workspace

local actifs = {}

local function partieLocale(taille: Vector3, couleur: Color3, materiau: Enum.Material, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = taille
	p.Color = couleur
	p.Material = materiau
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = dossier
	return p
end

local function ajouter(coeur: Instance)
	if not coeur:IsA("BasePart") or actifs[coeur] then return end
	local style = STYLE[coeur:GetAttribute("Type")]
	if not style then return end
	local taille = coeur:GetAttribute("Taille") or 1

	local e = {style = style, taille = taille, eclats = {}, tourbillons = {}, phase = math.random() * 10, cache = false}
	for i = 1, style.eclats do
		local t = (0.22 + math.random() * 0.22) * taille
		local p = partieLocale(Vector3.new(t, t * 1.3, t), style.couleur, style.materiau, coeur.CFrame)
		table.insert(e.eclats, {
			partie = p,
			angle = (i / style.eclats) * math.pi * 2,
			hauteur = math.random() * 1.8 - 0.7,
			vitesse = 0.7 + math.random() * 0.6,
			spin = Vector3.new(math.random() * 4 - 2, math.random() * 4 - 2, math.random() * 4 - 2),
		})
	end
	for _, def in style.tourbillons do
		local porteur = partieLocale(Vector3.new(0.1, 0.1, 0.1), def.couleur, Enum.Material.Neon, coeur.CFrame)
		porteur.Transparency = 1
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, def.largeur / 2, 0)
		a0.Parent = porteur
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -def.largeur / 2, 0)
		a1.Parent = porteur
		local trainee = Instance.new("Trail")
		trainee.Attachment0 = a0
		trainee.Attachment1 = a1
		trainee.Lifetime = 0.8
		trainee.LightEmission = 1
		trainee.LightInfluence = 0
		trainee.Color = ColorSequence.new(def.couleur)
		trainee.Transparency = NumberSequence.new(0, 1)
		trainee.WidthScale = NumberSequence.new(1, 0.1)
		trainee.FaceCamera = true
		trainee.Parent = porteur
		table.insert(e.tourbillons, {partie = porteur, trainee = trainee, def = def})
	end

	-- Extras : arcs électriques (Fer), rayons + sceau au sol (Gold), lumière qui respire
	e.extras, e.faisceaux = {}, {}
	local support = partieLocale(Vector3.new(0.1, 0.1, 0.1), style.couleur, Enum.Material.SmoothPlastic, coeur.CFrame)
	support.Transparency = 1
	table.insert(e.extras, support)
	e.support = support

	local lumiere = Instance.new("PointLight")
	lumiere.Color = style.lueur or style.couleur
	lumiere.Range = 12 * taille
	lumiere.Brightness = 0
	lumiere.Shadows = false
	lumiere.Parent = support
	e.lumiere = lumiere

	local function faisceau(couleur: Color3, largeur0: number, largeur1: number, transparence: NumberSequence): (Beam, Attachment, Attachment)
		local a0 = Instance.new("Attachment")
		a0.Parent = support
		local a1 = Instance.new("Attachment")
		a1.Parent = support
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Color = ColorSequence.new(couleur)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Width0 = largeur0
		b.Width1 = largeur1
		b.Transparency = transparence
		b.FaceCamera = true
		b.Segments = 12
		b.Parent = support
		table.insert(e.faisceaux, b)
		return b, a0, a1
	end

	if style.arcs then
		e.arcs = {}
		for _ = 1, style.arcs do
			local b, a0, a1 = faisceau(Color3.fromRGB(190, 225, 255), 0.12, 0.04, NumberSequence.new(0))
			table.insert(e.arcs, {beam = b, a0 = a0, a1 = a1, prochain = 0})
		end
	end

	if style.rayons then
		e.rayons = {}
		local centreA = Instance.new("Attachment")
		centreA.Parent = support
		for i = 1, style.rayons do
			local b, _, a1 = faisceau(Color3.fromRGB(255, 225, 130), 0.8 * taille, 0, NumberSequence.new(0.55, 1))
			b.Attachment0 = centreA
			table.insert(e.rayons, {beam = b, bout = a1, angle = (i / style.rayons) * math.pi * 2, longueur = (2.6 + math.random() * 1.6) * taille})
		end

		-- Sceau hexagonal au sol
		local sceau = Instance.new("Model")
		sceau.Name = "Sceau"
		local disque = partieLocale(Vector3.new(0.05, 4.6 * taille, 4.6 * taille), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, coeur.CFrame)
		disque.Shape = Enum.PartType.Cylinder
		disque.Transparency = 0.82
		disque.Parent = sceau
		local barres = {}
		for i = 1, 6 do
			local b = partieLocale(Vector3.new(3.2 * taille * 0.66, 0.06, 0.08), Color3.fromRGB(255, 220, 110), Enum.Material.Neon, coeur.CFrame)
			b.Transparency = 0.35
			b.Parent = sceau
			barres[i] = b
		end
		sceau.Parent = dossier
		table.insert(e.extras, sceau)
		e.sceau = {disque = disque, barres = barres}
	end

	actifs[coeur] = e
end

local function retirer(coeur: Instance)
	local e = actifs[coeur]
	if not e then return end
	for _, f in e.eclats do f.partie:Destroy() end
	for _, w in e.tourbillons do w.partie:Destroy() end
	for _, x in e.extras do x:Destroy() end
	actifs[coeur] = nil
end

-- Point au hasard sur une coquille autour du minerai
local function surCoquille(centre: Vector3, rMin: number, rMax: number): Vector3
	local d = Vector3.new(math.random() * 2 - 1, math.random() * 1.6 - 0.5, math.random() * 2 - 1)
	if d.Magnitude < 0.01 then d = Vector3.yAxis end
	return centre + d.Unit * (rMin + math.random() * (rMax - rMin))
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(ajouter)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(retirer)
for _, coeur in CollectionService:GetTagged(TAG) do
	ajouter(coeur)
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	for coeur, e in actifs do
		if not coeur.Parent then
			retirer(coeur)
			continue
		end
		local centre = coeur.Position
		local cache = (centre - camera).Magnitude > DISTANCE_MAX or coeur.Transparency >= 1
		if cache ~= e.cache then
			e.cache = cache
			for _, f in e.eclats do f.partie.Transparency = cache and 1 or 0 end
			for _, w in e.tourbillons do w.trainee.Enabled = not cache end
			for _, b in e.faisceaux do b.Enabled = not cache end
			e.lumiere.Enabled = not cache
			if e.sceau then
				e.sceau.disque.Transparency = cache and 1 or 0.82
				for _, b in e.sceau.barres do b.Transparency = cache and 1 or 0.35 end
			end
		end
		if not cache then
			local echelle = coeur.Size.Y / 2 -- suit l'animation de pousse
			local st = e.style
			e.support.CFrame = CFrame.new(centre)
			e.lumiere.Brightness = (st.lumiere or 0) * (0.75 + 0.25 * math.sin(t * 2.2 + e.phase))

			-- Fer : arcs électriques qui sautent d'un point à l'autre
			if e.arcs then
				for _, arc in e.arcs do
					if t >= arc.prochain then
						arc.prochain = t + 0.06 + math.random() * 0.08
						arc.a0.WorldPosition = surCoquille(centre, 1.0 * echelle, 1.3 * echelle)
						arc.a1.WorldPosition = surCoquille(centre, 1.6 * echelle, 2.4 * echelle)
						arc.beam.CurveSize0 = math.random() * 4 - 2
						arc.beam.CurveSize1 = math.random() * 4 - 2
						arc.beam.Enabled = math.random() < 0.7
					end
				end
			end

			-- Gold : rayons divins face caméra + sceau qui tourne au sol
			if e.rayons then
				local cam = workspace.CurrentCamera.CFrame
				for i, r in e.rayons do
					local a = r.angle + t * 0.35
					local pulse = 0.8 + 0.2 * math.sin(t * 3 + i)
					local dir = cam.RightVector * math.cos(a) + cam.UpVector * math.sin(a)
					r.bout.WorldPosition = centre + dir * r.longueur * pulse * echelle / math.max(e.taille, 0.01)
				end
				local sol = CFrame.new(centre - Vector3.new(0, 1.25 * echelle, 0)) * CFrame.Angles(0, t * 0.6, 0)
				e.sceau.disque.CFrame = sol * CFrame.Angles(0, 0, math.pi / 2)
				local apotheme = 2.1 * echelle * 0.866
				for i, b in e.sceau.barres do
					local a = (i / 6) * math.pi * 2
					b.Size = Vector3.new(2.1 * echelle, 0.06, 0.08)
					b.CFrame = sol * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, apotheme)
				end
			end
			for _, f in e.eclats do
				local a = f.angle + t * 0.5 * st.vitesse * f.vitesse
				local r = st.rayon * echelle
				local pos = centre + Vector3.new(math.cos(a) * r, (f.hauteur + math.sin(t * 1.5 + f.angle) * 0.25) * echelle, math.sin(a) * r)
				f.partie.CFrame = CFrame.new(pos) * CFrame.Angles(t * f.spin.X, t * f.spin.Y, t * f.spin.Z)
			end
			for _, w in e.tourbillons do
				local a = t * w.def.vitesse + e.phase
				w.partie.CFrame = CFrame.new(centre) * w.def.inclinaison * CFrame.Angles(0, a, 0) * CFrame.new(st.rayon * echelle * 0.8, 0, 0)
			end
		end
	end
end)
