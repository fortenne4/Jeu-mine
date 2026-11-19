--!strict
-- Icônes 3D des objets du jeu (StarterPlayerScripts › Jeu › IconesObjets) : les VRAIS modèles
-- (minerais de la mine, pioches PiochesVoxels, épées ArmesVoxels, lingots) dans des ViewportFrames.
-- Modèles construits une seule fois (cache), puis clonés. La rotation fait tourner la caméra autour
-- de l'objet (pas de PivotTo sur des centaines de pièces) et ne tourne que si l'icône est visible.
--   local Icones = require(script.Parent:WaitForChild("IconesObjets"))
--   Icones.minerai("Fer", parent) ; Icones.pioche("Givre", parent, {silhouette = true})
--   Icones.definir(vp, "epee", "EpeeFer", {teinte = couleur}) -- change l'objet d'une icône existante
--   Icones.armure("CasqueFer", parent, teinte) -- modèle ArmuresVoxels, sinon le générique ("Casque"), sinon secours voxel
--   Icones.bourse(parent) -- bourse de mineur (bouton HUD du sac)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local PiochesVoxels = require(Partage:WaitForChild("PiochesVoxels"))
local ArmesVoxels = require(Partage:WaitForChild("ArmesVoxels"))

export type Options = {
	vitesse: number?, -- rad/s, 0 = fixe (défaut 0.6)
	marge: number?, -- recul de la caméra (défaut 0.9)
	hauteur: number?, -- angle de plongée (défaut 0.3)
	angle: number?,
	silhouette: boolean?,
	teinte: Color3?,
}
export type Vue = {vp: ViewportFrame, camera: Camera, centre: Vector3, distance: number, angle: number, hauteur: number, vitesse: number,
	genre: string?, id: string?, opts: Options?}
type Gabarit = {modele: Model, centre: Vector3, rayon: number}

local Icones = {}
local gabarits: {[string]: Gabarit} = {}
local vues: {[ViewportFrame]: Vue} = {}

-- ArmuresVoxels (Partage) : chargé à la demande, protégé ; tant qu'il manque, silhouette voxel de secours
local armuresMod: any = nil -- nil = pas encore cherché, false = absent / en erreur
local function modArmures(): any
	if armuresMod == nil then
		armuresMod = false
		local m = Partage:FindFirstChild("ArmuresVoxels")
		if m and m:IsA("ModuleScript") then
			local ok, res = pcall(require, m)
			if ok and type(res) == "table" and type(res.construire) == "function" then
				armuresMod = res
			else
				warn("[IconesObjets] ArmuresVoxels illisible, silhouette de secours :", res)
			end
		end
	end
	return armuresMod or nil
end

local NOIR = Color3.new(0, 0, 0)
local AMBIANT = Color3.fromRGB(125, 115, 108)
local LUMIERE = Color3.fromRGB(255, 238, 214)
local DIR_LUMIERE = Vector3.new(0.6, -1, -0.8).Unit -- dans le repère de la caméra : vient d'en haut à gauche
local INCLINAISON_PIOCHE = CFrame.Angles(0, 0, math.rad(-28)) * CFrame.Angles(0, math.rad(90), 0)
local INCLINAISON_EPEE = CFrame.Angles(0, 0, math.rad(-40))
local LAME = {Lame = true, Gorge = true, Tranchant = true, Pointe = true, Talon = true, Rouille = true}

local function centrer(m: Model, pose: CFrame)
	m.WorldPivot = CFrame.identity
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position)
	m:PivotTo(pose)
end

local function teinter(m: Model, teinte: Color3)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and LAME[p.Name] then
			local l = (p.Color.R + p.Color.G + p.Color.B) / 2.1
			p.Color = Color3.new(math.min(1, teinte.R * l), math.min(1, teinte.G * l), math.min(1, teinte.B * l))
		end
	end
end

local function noircir(m: Model)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color, d.Material, d.Reflectance = NOIR, Enum.Material.SmoothPlastic, 0
			if d.Transparency < 1 then -- les ancres invisibles (Racine, Centre) le restent
				d.Transparency = 0
			end
			if d:IsA("MeshPart") then
				pcall(function()
					d.TextureID = ""
				end)
			end
		elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then
			d:Destroy()
		end
	end
end

local function lingot(c: Color3): Model
	local m = Instance.new("Model")
	local function bloc(t: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Color, p.Material, p.Reflectance, p.Anchored = t, cf, couleur, mat, 0.25, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
	end
	bloc(Vector3.new(2.6, 0.55, 1.25), CFrame.new(0, 0.275, 0), c:Lerp(NOIR, 0.15), Enum.Material.Metal)
	bloc(Vector3.new(2.2, 0.35, 0.95), CFrame.new(0, 0.7, 0), c, Enum.Material.Metal)
	bloc(Vector3.new(1.9, 0.06, 0.7), CFrame.new(0, 0.9, 0), c:Lerp(Color3.new(1, 1, 1), 0.35), Enum.Material.Foil)
	for _, s in {-1, 1} do
		bloc(Vector3.new(0.2, 0.62, 1.1), CFrame.new(s * 1.2, 0.5, 0) * CFrame.Angles(0, 0, s * 0.35), c:Lerp(NOIR, 0.08), Enum.Material.Metal)
	end
	return m
end

local BLANC = Color3.new(1, 1, 1)
local function bloc(m: Model, t: Vector3, cf: CFrame, couleur: Color3, mat: Enum.Material?, reflet: number?, forme: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size, p.CFrame, p.Color, p.Anchored = t, cf, couleur, true
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Reflectance = reflet or 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if forme then
		p.Shape = forme
	end
	p.Parent = m
	return p
end

-- Pièce d'armure de secours (voxels de métal teinté), face avant vers -Z
local function armureSecours(id: string, teinte: Color3): Model
	local m = Instance.new("Model")
	local base, fonce, clair = teinte, teinte:Lerp(NOIR, 0.35), teinte:Lerp(BLANC, 0.3)
	local MET = Enum.Material.Metal
	local function b(t: Vector3, pos: Vector3, c: Color3, rot: CFrame?)
		bloc(m, t, CFrame.new(pos) * (rot or CFrame.identity), c, MET, 0.12)
	end
	if id == "Casque" then
		b(Vector3.new(2.4, 1.0, 2.6), Vector3.new(0, 0.5, 0), base)
		b(Vector3.new(2.0, 0.5, 2.2), Vector3.new(0, 1.25, 0), clair)
		b(Vector3.new(1.3, 0.3, 1.5), Vector3.new(0, 1.6, 0), clair)
		b(Vector3.new(0.3, 0.45, 2.5), Vector3.new(0, 1.55, 0), fonce) -- crête
		b(Vector3.new(1.9, 0.22, 0.1), Vector3.new(0, 0.45, -1.32), Color3.fromRGB(14, 12, 12)) -- visière
		b(Vector3.new(0.3, 0.75, 0.12), Vector3.new(0, 0.1, -1.33), fonce) -- nasal
		for _, s in {-1, 1} do
			b(Vector3.new(0.35, 0.8, 1.4), Vector3.new(s * 1.1, -0.3, -0.35), fonce) -- joues
			b(Vector3.new(0.16, 0.16, 0.16), Vector3.new(s * 0.9, 0.85, -1.32), clair) -- rivets
		end
	elseif id == "Plastron" then
		b(Vector3.new(2.6, 2.4, 1.3), Vector3.new(0, 1.2, 0), base)
		b(Vector3.new(0.35, 2.2, 0.12), Vector3.new(0, 1.25, -0.7), clair) -- arête
		b(Vector3.new(2.7, 0.35, 1.4), Vector3.new(0, 0.18, 0), fonce) -- ceinture
		b(Vector3.new(0.45, 0.3, 0.1), Vector3.new(0, 0.18, -0.72), Color3.fromRGB(255, 204, 92), Enum.Material.Metal) -- boucle
		for _, s in {-1, 1} do
			b(Vector3.new(1.0, 0.6, 1.6), Vector3.new(s * 1.45, 2.25, 0), clair, CFrame.Angles(0, 0, s * -0.25)) -- épaulières
			b(Vector3.new(0.9, 0.12, 0.12), Vector3.new(s * 0.65, 1.6, -0.68), fonce) -- lignes de poitrail
			b(Vector3.new(0.16, 0.16, 0.16), Vector3.new(s * 1.05, 2.05, -0.7), clair)
		end
	else -- Jambieres
		b(Vector3.new(2.3, 0.45, 1.25), Vector3.new(0, 2.6, 0), fonce)
		b(Vector3.new(0.4, 0.3, 0.1), Vector3.new(0, 2.6, -0.66), Color3.fromRGB(255, 204, 92))
		for _, s in {-1, 1} do
			b(Vector3.new(0.95, 2.2, 1.05), Vector3.new(s * 0.56, 1.3, 0), base)
			b(Vector3.new(0.75, 0.55, 0.12), Vector3.new(s * 0.56, 1.25, -0.56), clair) -- genouillères
			b(Vector3.new(1.05, 0.45, 1.35), Vector3.new(s * 0.56, 0.22, -0.12), fonce) -- solerets
		end
	end
	return m
end

-- Bourse de mineur en voxels : cuir dégradé, col froncé, cordon doré noué, pièces + cristal qui dépassent
local function bourse(): Model
	local m = Instance.new("Model")
	local BAS, HAUT = Color3.fromRGB(70, 38, 20), Color3.fromRGB(184, 118, 66)
	local OR, OR_F = Color3.fromRGB(255, 200, 70), Color3.fromRGB(196, 128, 30)
	local couches = {{0.2, 0.4, 1.9}, {0.65, 0.5, 2.6}, {1.15, 0.5, 2.95}, {1.65, 0.5, 3.0}, {2.15, 0.5, 2.75}, {2.6, 0.4, 2.2}}
	for i, c in couches do
		local col = BAS:Lerp(HAUT, (i - 1) / (#couches - 1))
		local y, h, w = c[1], c[2], c[3]
		bloc(m, Vector3.new(w, h, w * 0.66), CFrame.new(0, y, 0), col)
		bloc(m, Vector3.new(w * 0.66, h, w), CFrame.new(0, y, 0), col:Lerp(BAS, 0.12))
		bloc(m, Vector3.new(w * 0.86, h, w * 0.86), CFrame.new(0, y, 0), col:Lerp(HAUT, 0.06))
	end
	-- col pincé puis froncé (plis alternés)
	bloc(m, Vector3.new(1.35, 0.35, 1.35), CFrame.new(0, 2.95, 0), HAUT:Lerp(BAS, 0.25))
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local haut = if k % 2 == 0 then 0.55 else 0.4
		bloc(m, Vector3.new(0.62, haut, 0.36), CFrame.new(0, 3.3 + haut / 2 - 0.2, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 0.8) * CFrame.Angles(-0.35, 0, 0),
			HAUT:Lerp(BLANC, if k % 2 == 0 then 0.1 else 0))
	end
	-- écusson cousu devant (-Z) avec clou doré
	local zP = -1.53
	bloc(m, Vector3.new(1.3, 0.9, 0.08), CFrame.new(0, 1.45, zP), HAUT:Lerp(BLANC, 0.12))
	for i = 0, 5 do
		bloc(m, Vector3.new(0.12, 0.05, 0.04), CFrame.new(-0.5 + i * 0.2, 1.84, zP - 0.05), Color3.fromRGB(240, 214, 170))
		bloc(m, Vector3.new(0.12, 0.05, 0.04), CFrame.new(-0.5 + i * 0.2, 1.06, zP - 0.05), Color3.fromRGB(240, 214, 170))
	end
	bloc(m, Vector3.new(0.38, 0.38, 0.12), CFrame.new(0, 1.45, zP - 0.07) * CFrame.Angles(0, 0, math.rad(45)), OR, Enum.Material.Metal, 0.3)
	-- cordon doré autour du col + nœud + pans pendants avec perles
	for _, s in {-1, 1} do
		bloc(m, Vector3.new(1.6, 0.2, 0.2), CFrame.new(0, 2.98, s * 0.72), OR, Enum.Material.Metal, 0.25)
		bloc(m, Vector3.new(0.2, 0.2, 1.6), CFrame.new(s * 0.72, 2.98, 0), OR_F, Enum.Material.Metal, 0.25)
	end
	local noeud = Vector3.new(0, 2.98, -0.82)
	bloc(m, Vector3.new(0.42, 0.42, 0.42), CFrame.new(noeud) * CFrame.Angles(0, 0, math.rad(45)), OR, Enum.Material.Metal, 0.3)
	for _, s in {-1, 1} do
		local perle = Vector3.new(s * 0.32, 2.3, -1.5)
		bloc(m, Vector3.new(0.13, 0.13, (perle - noeud).Magnitude), CFrame.lookAt((noeud + perle) / 2, perle), OR_F, Enum.Material.Metal, 0.2)
		bloc(m, Vector3.new(0.26, 0.26, 0.26), CFrame.new(perle) * CFrame.Angles(0.5, 0.5, 0), OR, Enum.Material.Metal, 0.3)
	end
	-- trésor qui dépasse : pièces (cylindres), pépite, cristal
	local function piece(pos: Vector3, rx: number, rz: number)
		bloc(m, Vector3.new(0.18, 0.95, 0.95), CFrame.new(pos) * CFrame.Angles(rx, math.rad(90), rz), OR, Enum.Material.Metal, 0.35, Enum.PartType.Cylinder)
		bloc(m, Vector3.new(0.2, 0.55, 0.55), CFrame.new(pos) * CFrame.Angles(rx, math.rad(90), rz), OR_F, Enum.Material.Metal, 0.2, Enum.PartType.Cylinder)
	end
	piece(Vector3.new(-0.42, 3.7, -0.1), 0, 0.35)
	piece(Vector3.new(0.48, 3.62, 0.15), 0.2, -0.5)
	piece(Vector3.new(0.05, 3.55, -0.35), -0.6, 0.1)
	bloc(m, Vector3.new(0.45, 0.4, 0.45), CFrame.new(0.55, 3.45, -0.45) * CFrame.Angles(0.4, 0.6, 0.3), OR_F:Lerp(OR, 0.5), Enum.Material.Metal, 0.2)
	local cristal = CFrame.new(-0.05, 3.95, 0.3) * CFrame.Angles(0.15, 0.4, math.rad(-18))
	bloc(m, Vector3.new(0.48, 1.1, 0.48), cristal, Color3.fromRGB(96, 214, 255), Enum.Material.Neon)
	bloc(m, Vector3.new(0.34, 0.34, 0.34), cristal * CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(200, 246, 255), Enum.Material.Neon)
	bloc(m, Vector3.new(0.3, 0.7, 0.3), CFrame.new(0.42, 3.75, 0.45) * CFrame.Angles(0, 0.3, math.rad(25)), Color3.fromRGB(180, 120, 255), Enum.Material.Neon)
	return m
end

local function construire(genre: string, id: string, opts: Options): Model?
	local m: Model?
	if genre == "minerai" then
		if not MineraisModeles.VISUEL[id] then
			return nil
		end
		m = (MineraisModeles.construire(id, CFrame.identity, Random.new(#id * 31 + 7), true))
		if m then
			centrer(m, CFrame.Angles(0.15, 0, 0))
		end
	elseif genre == "pioche" then
		local dossier = ReplicatedStorage:FindFirstChild("ModelesPioches")
		local importe = dossier and dossier:FindFirstChild(id)
		m = if importe and importe:IsA("Model") then importe:Clone() else PiochesVoxels.construire(id)
		if m then
			centrer(m, INCLINAISON_PIOCHE)
		end
	elseif genre == "epee" then
		if not ArmesVoxels.existe(id) then
			return nil
		end
		m = ArmesVoxels.construire(id)
		if m then
			centrer(m, INCLINAISON_EPEE)
		end
	elseif genre == "lingot" then
		m = lingot(Color3.fromHex(id))
		if m then
			centrer(m, CFrame.Angles(0, 0.5, 0))
		end
	elseif genre == "armure" then
		local teinte = opts.teinte or Color3.fromRGB(152, 158, 170)
		local base = id
		for _, b in {"Casque", "Plastron", "Jambieres"} do
			if id:sub(1, #b) == b then
				base = b
			end
		end
		local mod = modArmures()
		for _, cand in {id, base} do -- modèle dédié (CasqueFer…) absent : modèle générique du type
			if not m and mod and (type(mod.existe) ~= "function" or mod.existe(cand)) then
				local ok, res = pcall(mod.construire, cand, teinte) -- teinte appliquée par ArmuresVoxels (Teinte / TeinteFacteur)
				if ok and typeof(res) == "Instance" and res:IsA("Model") then
					m = res
				end
			end
		end
		m = m or armureSecours(base, teinte)
		if m then
			centrer(m, CFrame.Angles(0, math.pi, 0)) -- face avant vers la caméra
		end
	elseif genre == "bourse" then
		m = bourse()
		centrer(m, CFrame.Angles(0, math.pi, 0))
	end
	if not m then
		return nil
	end
	for _, d in m:GetDescendants() do
		if d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("BillboardGui") or d:IsA("LuaSourceContainer") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	if opts.teinte and genre ~= "armure" then
		teinter(m, opts.teinte)
	end
	if opts.silhouette then
		noircir(m)
	end
	return m
end

local function gabarit(genre: string, id: string, opts: Options): Gabarit?
	local cle = genre .. ":" .. id .. (if opts.silhouette then ":s" else "") .. (if opts.teinte then ":" .. opts.teinte:ToHex() else "")
	local g = gabarits[cle]
	if not g then
		local m = construire(genre, id, opts)
		if not m then
			return nil
		end
		local cf, taille = m:GetBoundingBox()
		g = {modele = m, centre = cf.Position, rayon = taille.Magnitude / 2}
		gabarits[cle] = g
	end
	return g
end

local function placer(v: Vue)
	local cf = CFrame.new(v.centre) * CFrame.Angles(0, v.angle, 0) * CFrame.Angles(-v.hauteur, 0, 0) * CFrame.new(0, 0, v.distance)
	v.camera.CFrame = cf
	v.vp.LightDirection = cf:VectorToWorldSpace(DIR_LUMIERE)
end

-- ViewportFrame vide, transparent, plein cadre (à remplir avec Icones.definir)
function Icones.creer(parent: Instance?): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Icone3D"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.Ambient, vp.LightColor = AMBIANT, LUMIERE
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	vp.Destroying:Connect(function()
		vues[vp] = nil
	end)
	return vp
end

-- Met (ou remplace) l'objet affiché ; ne refait rien si c'est déjà le même
function Icones.definir(vp: ViewportFrame, genre: string, id: string, options: Options?): boolean
	local opts = options or {}
	local cle = genre .. ":" .. id .. tostring(opts.silhouette) .. (if opts.teinte then opts.teinte:ToHex() else "")
	if vp:GetAttribute("Cle") == cle then
		return true
	end
	local g = gabarit(genre, id, opts)
	local ancien = vp:FindFirstChild("Objet")
	if ancien then
		ancien:Destroy()
	end
	vp:SetAttribute("Cle", if g then cle else nil)
	if not g then
		vues[vp] = nil
		return false
	end
	local m = g.modele:Clone()
	m.Name = "Objet"
	m.Parent = vp
	vp.Ambient = if opts.silhouette then NOIR else AMBIANT
	vp.LightColor = if opts.silhouette then NOIR else LUMIERE
	local cam = vp.CurrentCamera or Instance.new("Camera", vp)
	vp.CurrentCamera = cam
	local ancienneVue = vues[vp]
	local v: Vue = {vp = vp, camera = cam, centre = g.centre,
		distance = g.rayon / math.tan(math.rad(cam.FieldOfView / 2)) * (opts.marge or 0.9),
		angle = opts.angle or (if ancienneVue then ancienneVue.angle else math.random() * 6.28),
		hauteur = opts.hauteur or 0.3, vitesse = opts.vitesse or 0.6, genre = genre, id = id, opts = opts}
	vues[vp] = v
	placer(v)
	return true
end

function Icones.vue(vp: ViewportFrame): Vue?
	return vues[vp]
end

function Icones.placer(vp: ViewportFrame)
	local v = vues[vp]
	if v then
		placer(v)
	end
end

local function nouvelle(genre: string)
	return function(id: string, parent: Instance?, opts: Options?): ViewportFrame
		local vp = Icones.creer(parent)
		Icones.definir(vp, genre, id, opts)
		return vp
	end
end
Icones.minerai = nouvelle("minerai")
Icones.pioche = nouvelle("pioche")
Icones.epee = nouvelle("epee")
function Icones.lingot(couleur: Color3, parent: Instance?, opts: Options?): ViewportFrame
	return nouvelle("lingot")(couleur:ToHex(), parent, opts)
end
-- Pièce d'armure 3D ("Casque" | "Plastron" | "Jambieres") teintée à la couleur de l'alliage
function Icones.armure(id: string, parent: Instance?, teinte: Color3?, opts: Options?): ViewportFrame
	local o: Options = table.clone(opts or {})
	o.teinte = teinte or o.teinte
	o.angle = o.angle or 0.45
	o.hauteur = o.hauteur or 0.2
	return nouvelle("armure")(id, parent, o)
end
-- Bourse de mineur (bouton du sac)
function Icones.bourse(parent: Instance?, opts: Options?): ViewportFrame
	return nouvelle("bourse")("Cuir", parent, opts)
end

-- ArmuresVoxels ou un de ses modèles arrive (Rojo / autre agent) : on jette les gabarits de secours et on redessine les armures
local function oublierArmures()
	task.wait() -- laisse Rojo finir de remplir le module
	armuresMod = nil
	for cle in gabarits do
		if cle:sub(1, 7) == "armure:" then
			gabarits[cle] = nil
		end
	end
	for vp, v in vues do
		if v.genre == "armure" and v.id then
			vp:SetAttribute("Cle", nil)
			Icones.definir(vp, "armure", v.id, v.opts)
		end
	end
end
local function suivreArmures(c: Instance)
	if c.Name == "ArmuresVoxels" then
		c.ChildAdded:Connect(oublierArmures)
	end
end
Partage.ChildAdded:Connect(function(c)
	if c.Name == "ArmuresVoxels" then
		suivreArmures(c)
		oublierArmures()
	end
end)
local dejaLa = Partage:FindFirstChild("ArmuresVoxels")
if dejaLa then
	suivreArmures(dejaLa)
end

local function visible(g: Instance): boolean
	local i: Instance? = g
	while i do
		if i:IsA("GuiObject") then
			if not i.Visible then
				return false
			end
		elseif i:IsA("LayerCollector") then
			return i.Enabled
		end
		i = i.Parent
	end
	return false
end

RunService.RenderStepped:Connect(function(dt)
	for vp, v in vues do
		if v.vitesse ~= 0 and visible(vp) then
			v.angle += dt * v.vitesse
			placer(v)
		end
	end
end)

return Icones
