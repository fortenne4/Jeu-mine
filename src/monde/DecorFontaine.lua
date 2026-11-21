-- Décoration indépendante de la fontaine : ne modifie ni son eau ni ses minerais.
local O = require(script.Parent.Outils)
local M = O.M

local DecorFontaine = {}

function DecorFontaine.preparer(village)
	if village:FindFirstChild("DecorFontainePlace") then
		return
	end
	local monument = village:FindFirstChild("Monument")
	local fond = monument and monument:FindFirstChild("FondBassin")
	if not fond or not fond:IsA("BasePart") then
		return
	end

	local centre = fond.Position
	local hauteurSecours = centre.Y - fond.Size.X / 2
	local filtre = RaycastParams.new()
	filtre.FilterType = Enum.RaycastFilterType.Include
	filtre.FilterDescendantsInstances = { workspace.Terrain }
	filtre.IgnoreWater = true
	local function sol(x, z)
		local resultat = workspace:Raycast(Vector3.new(x, centre.Y + 20, z), Vector3.new(0, -50, 0), filtre)
		return resultat and resultat.Position.Y or hauteurSecours
	end
	local decor = Instance.new("Model")
	decor.Name = "DecorFontainePlace"
	local function bloc(parent, taille, position, couleur, materiau, nom)
		return O.decor(O.bloc(parent, taille, CFrame.new(position), couleur, materiau, nom))
	end
	local pierre = Color3.fromRGB(91, 85, 101)
	local fer = Color3.fromRGB(45, 40, 45)
	local ambre = Color3.fromRGB(255, 175, 75)
	-- Quatre bornes éclairent le pourtour sans bloquer les déplacements.
	for i = 0, 3 do
		local angle = math.pi / 4 + i * math.pi / 2
		local x, z = centre.X + 11.55 * math.cos(angle), centre.Z + 11.55 * math.sin(angle)
		local y = sol(x, z)
		local borne = O.modele(decor, "BorneLanterne")
		bloc(borne, Vector3.new(1.3, 0.35, 1.3), Vector3.new(x, y + 0.175, z), pierre, M.Pierre, "Socle")
		bloc(borne, Vector3.new(0.75, 1.65, 0.75), Vector3.new(x, y + 1.175, z), pierre, M.Ardoise, "Pilier")
		bloc(borne, Vector3.new(1.1, 0.25, 1.1), Vector3.new(x, y + 2.125, z), pierre, M.Pierre, "Chapiteau")
		bloc(borne, Vector3.new(0.75, 0.15, 0.75), Vector3.new(x, y + 2.325, z), fer, M.Metal, "PiedLanterne")
		local flamme = bloc(borne, Vector3.new(0.49, 0.75, 0.49), Vector3.new(x, y + 2.775, z), ambre, M.Neon, "Lumiere")
		O.lumiere(flamme, ambre, 1, 10, false)
		bloc(borne, Vector3.new(0.78, 0.15, 0.78), Vector3.new(x, y + 3.225, z), fer, M.Metal, "ToitLanterne")
		for _, dx in { -0.29, 0.29 } do
			for _, dz in { -0.29, 0.29 } do
				bloc(borne, Vector3.new(0.1, 0.8, 0.1), Vector3.new(x + dx, y + 2.775, z + dz), fer, M.Metal, "Montant")
			end
		end
	end
	-- Petites touffes fleuries entre les bornes ; aucun élément ne fait collision.
	for i = 0, 15 do
		if i % 4 ~= 2 then
			local angle = i * math.pi / 8
			local x, z = centre.X + 11.5 * math.cos(angle), centre.Z + 11.5 * math.sin(angle)
			local y = sol(x, z)
			local touffe = O.modele(decor, "FleursViolettes")
			O.decor(O.ellipsoide(touffe, Vector3.new(0.9, 0.38, 0.7), CFrame.new(x, y + 0.19, z), Color3.fromRGB(54, 76, 48), M.Herbe, "Buisson"))
			for j = -1, 1, 2 do
				bloc(touffe, Vector3.new(0.08, 0.38, 0.08), Vector3.new(x + j * 0.2, y + 0.39, z), Color3.fromRGB(65, 92, 52), M.Herbe, "Tige")
				bloc(touffe, Vector3.new(0.27, 0.16, 0.27), Vector3.new(x + j * 0.2, y + 0.62, z), Color3.fromRGB(137 + j * 8, 89, 167), M.Herbe, "Fleur")
			end
		end
	end
	-- Publier en une fois rend les appels successifs sans effet supplémentaire.
	decor.Parent = village
end

return DecorFontaine
