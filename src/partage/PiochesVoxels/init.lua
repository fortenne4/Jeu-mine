--!strict
--[[ Pioches 3D de l'Atelier, en blocs Roblox (ReplicatedStorage › Partage › PiochesVoxels).
	Les données (Bois.lua, Demon.lua...) sont générées depuis les modèles voxel de Blender par
	blender/pioches/exporte_blocs.py : aucun import dans Studio n'est nécessaire.
	Repère du manche de l'outil : manche le long de Y (5,3 studs, centré en 0), pic vers -Z.
	Utilisé par le serveur (pioche en main) et par le client (aperçu de la boutique). ]]

local PiochesVoxels = {}

local MATERIAUX: {[string]: Enum.Material} = {
	Metal = Enum.Material.Metal,
	Fabric = Enum.Material.Fabric,
	Slate = Enum.Material.Slate,
	Glass = Enum.Material.Glass,
	Neon = Enum.Material.Neon,
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Wood = Enum.Material.Wood,
}

type Donnees = {
	pointe: Vector3,
	centre: Vector3,
	talon: Vector3,
	palette: {{any}},
	blocs: {number},
}

function PiochesVoxels.existe(id: string): boolean
	return script:FindFirstChild(id) ~= nil
end

-- Construit la pioche (pièces ancrées, sans collision) ; nil si cette pioche n'a pas de modèle
function PiochesVoxels.construire(id: string): Model?
	local module = script:FindFirstChild(id)
	if not module or not module:IsA("ModuleScript") then
		return nil
	end
	local d = require(module) :: Donnees
	local modele = Instance.new("Model")
	modele.Name = id
	local b = d.blocs
	for i = 1, #b, 7 do
		local pal = d.palette[b[i + 6]]
		local p = Instance.new("Part")
		p.Name = if pal[1] == "Neon" then "Lueur" else "Bloc"
		p.Size = Vector3.new(b[i + 3], b[i + 4], b[i + 5])
		p.CFrame = CFrame.new(b[i], b[i + 1], b[i + 2])
		p.Color = Color3.fromRGB(pal[2], pal[3], pal[4])
		p.Material = MATERIAUX[pal[1]] or Enum.Material.SmoothPlastic
		p.Reflectance = pal[5] or 0
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = modele
	end
	modele:SetAttribute("Pointe", d.pointe)
	modele:SetAttribute("Centre", d.centre)
	modele:SetAttribute("Talon", d.talon)
	return modele
end

return PiochesVoxels
