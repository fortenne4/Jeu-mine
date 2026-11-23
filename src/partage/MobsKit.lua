--!strict
--[[ Petit atelier pour écrire un mob MobsVoxels directement en Luau (ReplicatedStorage › Partage › MobsKit).
	Les mobs exportés de Blender (blender/mobs) donnent des tables Data « en dur » ; ici, on décrit les os,
	les boîtes et les clips d'animation par du code, et le kit rend une table Data au même format :
		Bones = {{nom, parent, tete}}, Boxes = {{os, couleur, taille, pos, vX, vY, vZ, forme?}},
		Anim = {Bones = {ordre}, Clips = {Nom = {Length, Keys = {{frame, {qx,qy,qz,qw par os..., racine x,y,z}}}}}}

	local K = MobsKit.nouveau()
	K:os("body", "root", Vector3.new(0, 2, 0))
	K:boite("body", "PE", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), CFrame.Angles(0, 0, 0.1))
	K:clip("Walk", 24, function(t) return {body = CFrame.Angles(0.1 * math.sin(t * 2 * math.pi), 0, 0)}, Vector3.zero end)
	return K:donnees({Colors = {...}, Glow = {...}, NoStud = {...}, Hauteur = 6})

	Repère : pieds à Y = 0, devant = -Z. Rotation positive autour de X : un membre pendant part vers l'avant.
]]

local MobsKit = {}
MobsKit.__index = MobsKit

local PAS_CLE = 2 -- une clé toutes les 2 images (30 i/s)

function MobsKit.nouveau()
	local self = setmetatable({}, MobsKit)
	self.Bones = {}
	self.Boxes = {}
	self.Ordre = {}
	self.Clips = {}
	return self
end

function MobsKit.os(self: any, nom: string, parent: string?, tete: Vector3)
	table.insert(self.Bones, {nom, parent, tete})
	table.insert(self.Ordre, nom)
end

-- boîte (forme : nil, "Cyl" ou "Wedge") ; rot = orientation de la boîte autour de son centre
function MobsKit.boite(self: any, nomOs: string, couleur: string, taille: Vector3, pos: Vector3, rot: CFrame?, forme: string?)
	local r = rot or CFrame.identity
	table.insert(self.Boxes, {nomOs, couleur, taille, pos, r.RightVector, r.UpVector, -r.LookVector, forme})
end

-- la même boîte de chaque côté (x et -x), sur osG à gauche (x < 0) et osD à droite
function MobsKit.paire(self: any, osG: string, osD: string, couleur: string, taille: Vector3, pos: Vector3, rot: CFrame?, forme: string?)
	local x = math.abs(pos.X)
	local r = rot or CFrame.identity
	local rx, ry, rz = r:ToEulerAnglesXYZ()
	self:boite(osG, couleur, taille, Vector3.new(-x, pos.Y, pos.Z), r, forme)
	self:boite(osD, couleur, taille, Vector3.new(x, pos.Y, pos.Z), CFrame.fromEulerAnglesXYZ(rx, -ry, -rz), forme)
end

local function quat(cf: CFrame): (number, number, number, number)
	local axe, angle = cf:ToAxisAngle()
	if angle ~= angle or axe.Magnitude < 1e-6 then
		return 0, 0, 0, 1
	end
	local s = math.sin(angle / 2)
	return axe.X * s, axe.Y * s, axe.Z * s, math.cos(angle / 2)
end

local function arrondi(x: number): number
	return math.round(x * 1000) / 1000
end

-- pose(t) -> ({[os]: CFrame (rotation)}, décalage de la racine) ; t va de 0 à 1 sur la durée du clip
function MobsKit.clip(self: any, nom: string, longueur: number, pose: (number) -> ({[string]: CFrame}, Vector3?))
	local cles = {}
	local f = 0
	while true do
		local rots, depl = pose(f / longueur)
		local v = {}
		for _, nomOs in self.Ordre do
			local qx, qy, qz, qw = quat(rots[nomOs] or CFrame.identity)
			table.insert(v, arrondi(qx))
			table.insert(v, arrondi(qy))
			table.insert(v, arrondi(qz))
			table.insert(v, arrondi(qw))
		end
		local d = depl or Vector3.zero
		table.insert(v, arrondi(d.X))
		table.insert(v, arrondi(d.Y))
		table.insert(v, arrondi(d.Z))
		table.insert(cles, {f, v})
		if f >= longueur then
			break
		end
		f = math.min(longueur, f + PAS_CLE)
	end
	self.Clips[nom] = {Length = longueur, Keys = cles}
end

function MobsKit.donnees(self: any, infos: {[string]: any})
	local d = {
		Scale = 1,
		Colors = infos.Colors,
		Glow = infos.Glow or {},
		NoStud = infos.NoStud,
		Transparence = infos.Transparence,
		Hauteur = infos.Hauteur,
		Fps = 30,
		Bones = self.Bones,
		Boxes = self.Boxes,
		Anim = {Bones = self.Ordre, Clips = self.Clips},
	}
	return d
end

-- outils d'animation
MobsKit.TAU = 2 * math.pi
function MobsKit.cloche(t: number, a: number, b: number): number -- 0 → 1 → 0 entre a et b
	if t <= a or t >= b then
		return 0
	end
	return math.sin((t - a) / (b - a) * math.pi)
end
function MobsKit.rampe(t: number, a: number, b: number): number -- 0 avant a, 1 après b, lissé entre
	local u = math.clamp((t - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end

return MobsKit
