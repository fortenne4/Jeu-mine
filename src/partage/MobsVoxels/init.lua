--!strict
--[[ Mobs 3D de la mine, en blocs Roblox (ReplicatedStorage › Partage › MobsVoxels).
	Les données (MineurZombie.lua, BruteProfondeurs.lua...) sont générées depuis Blender par
	blender/mobs/exporte_mobs.py (box rig du pack LihFolk) : aucun import dans Studio n'est nécessaire.

	Repère du modèle : pieds à Y = 0 (sol), devant = -Z (LookVector), unités = studs.
	Structure construite :
		Model
		├─ Root (Part invisible, ancrée, PrimaryPart) : déplacer le mob = Model:PivotTo(cf)
		├─ B_<os> (Parts invisibles, une par os) reliées par Motor6D (dossier Joints, Motor6D.Name = os)
		└─ pièces visibles (Part, une par boîte, soudées à leur os ; Neon pour les lueurs)

	Usage :
		local MobsVoxels = require(ReplicatedStorage.Partage.MobsVoxels)
		local mob = MobsVoxels.construire("MineurZombie", CFrame.new(0, 0, 0))
		mob.Parent = workspace
		local anim = MobsVoxels.animateur(mob)        -- de préférence côté client
		anim:Jouer("Walk", true)                     -- Idle / Walk / Attack / Hurt / Death (+ Roar pour la brute)
		RunService.Heartbeat:Connect(function(dt) anim:Pas(dt) end)
]]

local MobsVoxels = {}

local FACES = { "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }
local SANS_STUD = { EY = true, MO = true, TE = true } -- défaut si le module ne fournit pas NoStud

export type Animateur = {
	Jouer: (self: Animateur, nom: string, boucle: boolean?, fondu: number?) -> number,
	Pas: (self: Animateur, dt: number) -> (),
	EnCours: (self: Animateur) -> string?,
	Fini: (self: Animateur) -> boolean,
	Vitesse: number,
}

function MobsVoxels.existe(id: string): boolean
	local m = script:FindFirstChild(id)
	return m ~= nil and m:IsA("ModuleScript")
end

function MobsVoxels.liste(): { string }
	local t = {}
	for _, m in script:GetChildren() do
		if m:IsA("ModuleScript") then
			table.insert(t, m.Name)
		end
	end
	table.sort(t)
	return t
end

function MobsVoxels.donnees(id: string): any
	local module = script:FindFirstChild(id)
	assert(module and module:IsA("ModuleScript"), "MobsVoxels : mob inconnu " .. id)
	return require(module) :: any
end

-- Construit le mob (Root ancrée, pièces sans collision). studs = false -> SmoothPlastic sans picots.
function MobsVoxels.construire(id: string, place: CFrame?, studs: boolean?): Model
	local d = MobsVoxels.donnees(id)
	local cf0 = place or CFrame.identity
	local modele = Instance.new("Model")
	modele.Name = id

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.one
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide, root.CanQuery, root.CanTouch = false, false, false
	root.CFrame = cf0
	root.Parent = modele
	modele.PrimaryPart = root

	local joints = Instance.new("Folder")
	joints.Name = "Joints"
	joints.Parent = modele

	local osParts: { [string]: BasePart } = {}
	local tetes: { [string]: Vector3 } = {}
	for _, b in d.Bones do -- parents avant enfants
		local nom: string, parent: string?, pos: Vector3 = b[1], b[2], b[3]
		tetes[nom] = pos
		local p = Instance.new("Part")
		p.Name = "B_" .. nom
		p.Size = Vector3.one * 0.2
		p.Transparency = 1
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.CFrame = cf0 * CFrame.new(pos)
		p.Parent = modele
		osParts[nom] = p
		local m = Instance.new("Motor6D")
		m.Name = nom
		m.Part0 = if parent then osParts[parent] else root
		m.Part1 = p
		m.C0 = CFrame.new(pos - (if parent then tetes[parent] else Vector3.zero))
		m:SetAttribute("Parent", parent or "")
		m.Parent = joints
	end

	local lueur = d.Glow or {}
	for _, bx in d.Boxes do
		local nomOs: string, k: string, taille: Vector3, pos: Vector3 = bx[1], bx[2], bx[3], bx[4]
		local cf = CFrame.fromMatrix(pos, bx[5], bx[6], bx[7])
		local forme = bx[8]
		local p: BasePart = if forme == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
		if forme == "Cyl" then
			(p :: Part).Shape = Enum.PartType.Cylinder
		end
		p.Name = k
		p.Size = taille
		p.CFrame = cf0 * cf
		p.Color = Color3.fromHex(d.Colors[k])
		if lueur[k] then
			p.Material = Enum.Material.Neon
		elseif studs ~= false and not (d.NoStud or SANS_STUD)[k] then
			p.Material = Enum.Material.Plastic
			for _, f in FACES do
				(p :: any)[f] = Enum.SurfaceType.Studs
			end
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		local transp = d.Transparence and d.Transparence[k] -- mobs écrits avec MobsKit (spectre…)
		if transp then
			p.Transparency = transp
		end
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.CastShadow = not transp
		p.Massless = true
		local w = Instance.new("Weld")
		w.Part0 = osParts[nomOs]
		w.Part1 = p
		w.C0 = CFrame.new(tetes[nomOs]):Inverse() * cf -- les os sont alignés sur le monde au repos
		w.Parent = p
		p.Parent = modele
	end
	modele:SetAttribute("Hauteur", d.Hauteur)
	return modele
end

-- ---------- Animateur : rejoue les clips Blender (Data.Anim) via Motor6D.Transform ----------
local Anim = {}
Anim.__index = Anim

local function echantillon(cles: { any }, frame: number): (any, any, number)
	for i = 1, #cles - 1 do
		local a, b = cles[i], cles[i + 1]
		if frame <= b[1] then
			return a, b, math.clamp((frame - a[1]) / (b[1] - a[1]), 0, 1)
		end
	end
	local der = cles[#cles]
	return der, der, 0
end

function MobsVoxels.animateur(modele: Model, id: string?): Animateur
	local d = MobsVoxels.donnees(id or modele.Name)
	local self = setmetatable({}, Anim) :: any
	self.Fps = d.Fps or 30
	self.Moteurs = {}
	for _, m in (modele:WaitForChild("Joints") :: Folder):GetChildren() do
		self.Moteurs[m.Name] = m
	end
	local ordre: { string } = d.Anim.Bones
	local n = #ordre
	self.Clips = {}
	for nom, clip in d.Anim.Clips do
		local cles = {}
		for i, k in clip.Keys do
			local v, pose = k[2], {}
			for j, nomOs in ordre do
				local o = (j - 1) * 4
				pose[nomOs] = CFrame.new(0, 0, 0, v[o + 1], v[o + 2], v[o + 3], v[o + 4])
			end
			local r = n * 4
			pose[ordre[1]] = CFrame.new(v[r + 1], v[r + 2], v[r + 3]) * pose[ordre[1]] -- la racine porte la translation
			cles[i] = { k[1], pose }
		end
		self.Clips[nom] = { Longueur = clip.Length, Cles = cles }
	end
	self.Temps, self.Vitesse = 0, 1
	return self :: Animateur
end

-- Lance un clip ; renvoie sa durée en secondes.
function Anim.Jouer(self: any, nom: string, boucle: boolean?, fondu: number?): number
	local clip = self.Clips[nom]
	assert(clip, "MobsVoxels : clip inconnu " .. nom)
	local depart = {}
	for nomOs, m in self.Moteurs do
		depart[nomOs] = m.Transform
	end
	self.Depart, self.Fondu, self.FonduT = depart, fondu or 0.2, 0
	self.Nom, self.Clip, self.Boucle, self.Temps = nom, clip, boucle == true, 0
	return clip.Longueur / self.Fps
end

function Anim.EnCours(self: any): string?
	return self.Nom
end

function Anim.Fini(self: any): boolean
	return self.Clip ~= nil and not self.Boucle and self.Temps * self.Fps >= self.Clip.Longueur
end

function Anim.Pas(self: any, dt: number)
	local clip = self.Clip
	if not clip then
		return
	end
	self.Temps += dt * self.Vitesse
	local frame = self.Temps * self.Fps
	if frame >= clip.Longueur then
		if self.Boucle then
			frame %= clip.Longueur
			self.Temps = frame / self.Fps
		else
			frame = clip.Longueur
		end
	end
	local a, b, u = echantillon(clip.Cles, frame)
	self.FonduT += dt
	local f = if self.Fondu > 0 then math.min(self.FonduT / self.Fondu, 1) else 1
	for nomOs, m in self.Moteurs do
		local pa, pb = a[2][nomOs], b[2][nomOs]
		if pa then
			local cf = pa:Lerp(pb, u)
			m.Transform = if f < 1 then self.Depart[nomOs]:Lerp(cf, f) else cf
		end
	end
end

return MobsVoxels
