-- Terrain : vallée entourée de montagnes, falaise de la mine au nord, rivière au sud,
-- puis tunnel, descente et grande caverne creusés dans la roche.
local D = require(script.Parent.Disposition)

local Terrain = {}
local terrain = workspace.Terrain

local RES = 4
local MIN_X, MAX_X = -320, 320
local MIN_Z, MAX_Z = -560, 240
local MIN_Y, MAX_Y = -140, 340
local BLOC = 160 -- taille d'un morceau écrit d'un coup (en studs)

local AIR = Enum.Material.Air
local HERBE = Enum.Material.Grass
local HERBE_HAUTE = Enum.Material.LeafyGrass
local TERRE = Enum.Material.Ground
local ROCHE = Enum.Material.Rock
local ARDOISE = Enum.Material.Slate
local BASALTE = Enum.Material.Basalt
local NEIGE = Enum.Material.Snow
local GLACIER = Enum.Material.Glacier
local CALCAIRE = Enum.Material.Limestone
local GRES = Enum.Material.Sandstone -- bancs rougeâtres dans les falaises
local BOUE = Enum.Material.Mud -- roche humide, pied des parois

local function lisse(a, b, t)
	local u = math.clamp((t - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end

local function bruit(x, z, echelle, graine)
	return math.noise(x / echelle + graine * 17.31, z / echelle - graine * 9.13, graine + 0.5)
end

-- Bruit « crêtes » sur plusieurs échelles : arêtes vives, sommets pointus, vallons entre les pics (0 à 1)
local function cretes(x, z, echelle, graine)
	local total, amplitude, frequence, somme = 0, 1, 1 / echelle, 0
	for octave = 1, 5 do
		local n = math.noise(x * frequence + graine * 13.7 + octave * 3.1, z * frequence - graine * 7.9, graine + octave * 0.37)
		local c = math.clamp(1 - math.abs(n * 2), 0, 1)
		total += c * c * amplitude
		somme += amplitude
		amplitude *= 0.5
		frequence *= 2.03
	end
	return total / somme
end

-- Couches de roche en gradins (comme des strates érodées)
local function strates(h, force)
	local t = h / 11
	local base = math.floor(t)
	local gradin = (base + lisse(0.25, 0.75, t - base)) * 11
	return h + (gradin - h) * force
end

-- Hauteur du sol en (x, z). Utilisée aussi pour poser arbres, rochers et cristaux.
function Terrain.hauteur(x, z)
	local r = math.sqrt(x * x + z * z)
	local dx = x / 230
	local dz = if z > 0 then z / 200 else 0
	local d = math.sqrt(dx * dx + dz * dz)

	-- chaînes de montagnes à l'est, à l'ouest et au sud
	local lateral = lisse(0.72, 1.15, d)
	local montagne = lateral * (95 + 190 * cretes(x, z, 210, 1.3) + 20 * bruit(x, z, 60, 2.7))

	-- la montagne de la mine, au nord, avec une falaise raide
	local nord = lisse(-166, -204, z)
	local mine = nord * (185 + 130 * cretes(x + 700, z, 190, 7.1))

	local h = math.max(montagne, mine)
	local rugueux = math.max(lateral, nord)
	-- éboulis et blocs sur les pentes
	h += math.abs(bruit(x, z, 26, 4.4)) * 14 * rugueux
	h = strates(h, 0.35 * rugueux)
	-- légères ondulations hors du village
	h += 2.5 * bruit(x, z, 45, 5.5) * lisse(165, 230, r) * (1 - nord)
	return h
end

local function materiauSurface(x, z, h, pente)
	-- sommets enneigés ; la neige ne tient pas sur les parois trop raides
	local limiteNeige = 205 + 25 * bruit(x, z, 40, 8.8)
	if h > limiteNeige then
		if pente < 0.9 then
			return if h > 275 and pente < 0.45 then GLACIER else NEIGE
		elseif pente < 1.4 and bruit(x, z, 9, 1.9) > -0.1 then
			return NEIGE
		end
		return ROCHE
	end
	-- falaises : strates géologiques ondulées (épaisseurs inégales), coulures sombres et mousse dans les fissures
	if pente > 1.05 then
		-- coulures verticales d'humidité (ne dépendent que de x, z : elles descendent toute la paroi)
		local coulure = bruit(x, z, 7, 12.4)
		if coulure > 0.42 then
			return if h < 140 and bruit(x, z, 5, 3.9) > 0.1 then HERBE_HAUTE else BASALTE
		end
		-- mousse accrochée dans les creux, plus fréquente en bas
		if h < 120 and bruit(x * 1.3, z * 1.3, 11, 2.6) > 0.48 - h / 600 then
			return HERBE_HAUTE
		end
		local niveau = h + 9 * bruit(x, z, 42, 9.9) + 4 * bruit(x, z, 13, 4.1)
		local couche = math.floor(niveau / 6.5) % 7
		if couche == 0 or couche == 4 then
			return ROCHE
		elseif couche == 1 then
			return GRES
		elseif couche == 2 then
			return CALCAIRE
		elseif couche == 3 then
			return ARDOISE
		elseif couche == 5 then
			return if bruit(x, z, 20, 7.7) > 0 then CALCAIRE else GRES
		end
		return BASALTE
	end
	-- pentes moyennes : éboulis, terre, mousse et touffes d'herbe en bas
	if pente > 0.6 then
		local n = bruit(x, z, 10, 3.3)
		if h < 110 and n > 0.22 then
			return HERBE_HAUTE
		end
		if n < -0.35 then
			return GRES
		end
		if h < 40 and bruit(x, z, 8, 5.2) > 0.3 then
			return BOUE
		end
		return if n > -0.05 then ROCHE else TERRE
	end
	-- alpages : herbe rase, terre et rochers affleurants
	if h > 130 then
		local n = bruit(x, z, 14, 6.1)
		if n > 0.25 then
			return ROCHE
		end
		return if n > -0.15 then HERBE else TERRE
	end
	if h > 30 and bruit(x, z, 15, 2.2) > 0.42 then
		return ROCHE
	end
	if bruit(x, z, 22, 6.6) > 0.18 then
		return HERBE_HAUTE
	end
	return HERBE
end

-- Veines d'ardoise et de basalte dans la roche de la mine
local function materiauProfond(x, y, z)
	local n = math.noise(x / 34 + 0.37, y / 22 + 0.11, z / 34 + 0.73)
	if n > 0.32 then
		return ARDOISE
	elseif n < -0.36 then
		return BASALTE
	end
	return ROCHE
end

local function relief()
	local NX = (MAX_X - MIN_X) / RES
	local NZ = (MAX_Z - MIN_Z) / RES
	local NY = (MAX_Y - MIN_Y) / RES

	-- hauteurs au centre de chaque colonne (avec une bordure pour calculer les pentes)
	local H = {}
	for i = 0, NX + 1 do
		local col = {}
		local x = MIN_X + (i - 0.5) * RES
		for k = 0, NZ + 1 do
			col[k] = Terrain.hauteur(x, MIN_Z + (k - 0.5) * RES)
		end
		H[i] = col
	end

	local n = BLOC / RES
	for cx = MIN_X, MAX_X - BLOC, BLOC do
		for cz = MIN_Z, MAX_Z - BLOC, BLOC do
			local mats, occs = table.create(n), table.create(n)
			for ix = 1, n do
				local gi = (cx - MIN_X) / RES + ix
				local mx, ox = table.create(NY), table.create(NY)
				for iy = 1, NY do
					mx[iy] = table.create(n)
					ox[iy] = table.create(n)
				end
				local x = cx + (ix - 0.5) * RES
				for iz = 1, n do
					local gk = (cz - MIN_Z) / RES + iz
					local h = H[gi][gk]
					local z = cz + (iz - 0.5) * RES
					local pente = math.max(
						math.abs(H[gi + 1][gk] - H[gi - 1][gk]),
						math.abs(H[gi][gk + 1] - H[gi][gk - 1])
					) / (2 * RES)
					local surface = materiauSurface(x, z, h, pente)
					local vallee = h < 6
					local zoneMine = z < -150 and math.abs(x) < 140
					for iy = 1, NY do
						local bas = MIN_Y + (iy - 1) * RES
						local occ = math.clamp((h - bas) / RES, 0, 1)
						local mat = AIR
						if occ > 0 then
							local profondeur = h - (bas + RES)
							if profondeur < 3 then
								mat = surface
							elseif vallee and profondeur < 12 then
								mat = TERRE
							elseif zoneMine then
								mat = materiauProfond(x, bas + 2, z)
							else
								mat = ROCHE
							end
						end
						mx[iy][iz] = mat
						ox[iy][iz] = occ
					end
				end
				mats[ix] = mx
				occs[ix] = ox
			end
			local region = Region3.new(Vector3.new(cx, MIN_Y, cz), Vector3.new(cx + BLOC, MAX_Y, cz + BLOC))
			terrain:WriteVoxels(region, RES, mats, occs)
			task.wait()
		end
	end
end

local function riviere()
	local z = D.RIVIERE_Z
	terrain:FillBlock(CFrame.new(0, -6, z), Vector3.new(500, 12, D.RIVIERE_LARGEUR), AIR)
	terrain:FillBlock(CFrame.new(0, -8, z), Vector3.new(500, 8, D.RIVIERE_LARGEUR), Enum.Material.Water)
end

local function mine()
	-- Tranchée + tunnel plat (sol à Y = 0)
	local zDebut = D.CREUSE_DEBUT_Z
	local zFin = D.TUNNEL_FIN.Z - 20
	local longueur = zDebut - zFin
	terrain:FillBlock(
		CFrame.new(0, D.PORTAIL_HAUTEUR / 2, (zDebut + zFin) / 2),
		Vector3.new(D.PORTAIL_LARGEUR, D.PORTAIL_HAUTEUR, longueur),
		AIR
	)

	-- Descente en pente (le sol passe exactement par TUNNEL_FIN et DESCENTE_FIN)
	local A, B = D.TUNNEL_FIN, D.DESCENTE_FIN
	local dir = (B - A).Unit
	local A2 = A - dir * 8
	local L = (B - A2).Magnitude
	terrain:FillBlock(CFrame.lookAt((A2 + B) / 2, B) * CFrame.new(0, 14, 0), Vector3.new(30, 28, L), AIR)

	-- Grande caverne
	terrain:FillBall(D.CAVERNE_CENTRE, D.CAVERNE_RAYON, AIR)
	for _, lobe in D.CAVERNE_LOBES do
		terrain:FillBall(lobe[1], lobe[2], AIR)
	end
	-- Sol plat de la caverne
	local sol = D.CAVERNE_SOL
	terrain:FillBlock(CFrame.new(D.CAVERNE_CENTRE.X, sol - 25, D.CAVERNE_CENTRE.Z), Vector3.new(200, 50, 200), ARDOISE)
	-- Passage plat entre le bas de la descente et la caverne
	terrain:FillBlock(CFrame.new(0, sol + 14, (B.Z + D.QUAI_BAS.Z) / 2 + 10), Vector3.new(30, 28, 40), AIR)
end

function Terrain.construire()
	terrain:Clear()
	terrain.WaterColor = Color3.fromRGB(44, 92, 98)
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 6
	terrain:SetMaterialColor(HERBE, Color3.fromRGB(98, 116, 56))
	terrain:SetMaterialColor(HERBE_HAUTE, Color3.fromRGB(110, 118, 58))
	terrain:SetMaterialColor(TERRE, Color3.fromRGB(104, 84, 64))
	-- palette chaude et variée (avant : gris uniforme) ; tons accordés au crépuscule de DIRECTION_ARTISTIQUE.md
	terrain:SetMaterialColor(ROCHE, Color3.fromRGB(150, 130, 114))
	terrain:SetMaterialColor(ARDOISE, Color3.fromRGB(112, 102, 122))
	terrain:SetMaterialColor(BASALTE, Color3.fromRGB(76, 68, 78))
	terrain:SetMaterialColor(CALCAIRE, Color3.fromRGB(200, 176, 138))
	terrain:SetMaterialColor(GRES, Color3.fromRGB(190, 128, 94))
	terrain:SetMaterialColor(BOUE, Color3.fromRGB(80, 66, 54))
	terrain:SetMaterialColor(NEIGE, Color3.fromRGB(238, 228, 230))
	terrain:SetMaterialColor(GLACIER, Color3.fromRGB(176, 200, 214))

	relief()
	riviere()
	mine()
end

return Terrain
