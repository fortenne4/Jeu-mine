-- Fluidité de l'affichage · SCRIPT SERVEUR
-- Les petites pièces de décor (cailloux, clous, planchettes, gouttes, cubes des modèles voxel…) n'ont pas besoin
-- de projeter une ombre : à l'écran elle ne fait que quelques pixels, mais chaque pièce qui projette une ombre
-- alourdit le rendu de tous les joueurs. Ce script retire l'ombre portée (CastShadow) des pièces dont la plus
-- grande dimension ne dépasse pas TAILLE_MAX studs, dans :
--   * la carte (workspace.Carte), une fois construite (attribut workspace « MondeConstruit ») ;
--   * chaque grotte (workspace.Grottes) et chaque mine privée (workspace.MinesPrivees), au fur et à mesure.
-- Les bâtiments, arbres, gros rochers et les personnages gardent leurs ombres.
-- Les lanternes (tag « LueurLanterne ») n'ont plus d'ombre de lumière (voir aussi monde/Lampadaires.lua) :
-- utile pour une carte figée dans la place, construite avant ce réglage.
-- Le château fort, les sommets lointains et l'horizon de la mine restent toujours chargés (streaming).

local CollectionService = game:GetService("CollectionService")

local TAILLE_MAX = 2 -- studs

local function alleger(d: Instance)
	if d:IsA("BasePart") then
		if d.CastShadow then
			local s = d.Size
			if math.max(s.X, s.Y, s.Z) <= TAILLE_MAX then
				d.CastShadow = false
			end
		end
	elseif d:IsA("Light") and d.Shadows and CollectionService:HasTag(d, "LueurLanterne") then
		d.Shadows = false
	end
end

-- passe sur tout le contenu existant, puis sur ce qui y est ajouté ensuite (décor posé après coup)
local suivis: {[Instance]: boolean} = {}
local function suivre(racine: Instance)
	if suivis[racine] then
		return
	end
	suivis[racine] = true
	racine.DescendantAdded:Connect(function(d)
		-- différé : la taille est parfois réglée juste après le rattachement
		task.defer(alleger, d)
	end)
	local n = 0
	for _, d in racine:GetDescendants() do
		alleger(d)
		n += 1
		if n % 4000 == 0 then
			task.wait() -- ne pas figer le serveur sur une grosse carte
		end
	end
	racine.AncestryChanged:Connect(function()
		if not racine:IsDescendantOf(workspace) then
			suivis[racine] = nil
		end
	end)
end

local function suivreDossier(nom: string)
	local function brancher(dossier: Instance)
		for _, enfant in dossier:GetChildren() do
			task.spawn(suivre, enfant)
		end
		dossier.ChildAdded:Connect(function(enfant)
			task.spawn(suivre, enfant)
		end)
	end
	local dossier = workspace:FindFirstChild(nom)
	if dossier then
		brancher(dossier)
	end
	workspace.ChildAdded:Connect(function(c)
		if c.Name == nom and not suivis[c] then
			suivis[c] = true -- le dossier lui-même n'est pas allégé : ses enfants le sont un par un
			brancher(c)
		end
	end)
end

suivreDossier("Grottes")
suivreDossier("MinesPrivees")

task.spawn(function()
	local debut = os.clock()
	while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 120 do
		task.wait(0.5)
	end
	local carte = workspace:FindFirstChild("Carte")
	if carte then
		-- streaming (default.project.json : rayon 600, déchargement de ce qui est loin) : le château et les sommets
		-- lointains restent toujours chargés, sinon l'horizon de la vallée se viderait
		local bordures = carte:FindFirstChild("Bordures")
		for _, m in {bordures and bordures:FindFirstChild("ChateauFort"), bordures and bordures:FindFirstChild("SommetsLointains"),
			carte:FindFirstChild("HorizonMine")} do
			if m and m:IsA("Model") then
				m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
			end
		end
		suivre(carte)
	end
end)
