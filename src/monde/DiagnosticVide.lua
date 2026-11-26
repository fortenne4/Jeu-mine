local DiagnosticVide = {}

export type Zone = {
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
	haut: number,
	bas: number,
	pas: number,
}

local function filtreSol(sols: { Instance }): RaycastParams
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = sols
	filtre.RespectCanCollide = true
	filtre.IgnoreWater = true
	return filtre
end

function DiagnosticVide.relever(zone: Zone, solsAvant: { Instance }, solsSecours: { Instance })
	local porteeX = zone.maxX - zone.minX
	local porteeZ = zone.maxZ - zone.minZ
	local hauteur = zone.haut - zone.bas
	assert(porteeX > 0 and porteeZ > 0 and hauteur > 0 and zone.pas > 0, "Bornes de la grille invalides")

	local nombreX = math.ceil(porteeX / zone.pas)
	local nombreZ = math.ceil(porteeZ / zone.pas)
	local direction = Vector3.new(0, -hauteur, 0)
	local filtreAvant = filtreSol(solsAvant)
	local filtreSecours = filtreSol(solsSecours)
	local avant: { Vector2 } = {}
	local apres: { Vector2 } = {}
	for ix = 0, nombreX do
		local x = zone.minX + porteeX * (ix / nombreX)
		for iz = 0, nombreZ do
			local z = zone.minZ + porteeZ * (iz / nombreZ)
			local origine = Vector3.new(x, zone.haut, z)
			if not workspace:Raycast(origine, direction, filtreAvant) then
				local point = Vector2.new(x, z)
				table.insert(avant, point)
				if not workspace:Raycast(origine, direction, filtreSecours) then
					table.insert(apres, point)
				end
			end
		end
	end
	return { total = (nombreX + 1) * (nombreZ + 1), avant = avant, apres = apres }
end

return DiagnosticVide
