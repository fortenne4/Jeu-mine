--[[ Modèles 3D faits dans Blender (dossier blender/, fichiers assets/*.fbx).
	Ils sont importés une fois dans Studio (Fichier > Importer 3D) puis rangés dans
	ServerStorage.Modeles3D. Chaque MeshPart s'appelle « Prefixe_..._Teinte » :
		Gaspard_Tete_Peau, Lierre2_Feuilles, Falaise1_Roche...
	Les pièces d'un même préfixe forment un modèle. Si le dossier manque, le jeu
	garde les versions construites en blocs (rien ne casse). ]]
local ServerStorage = game:GetService("ServerStorage")

local Modeles3D = {}

local index: {[string]: {MeshPart}}? = nil

local function charger(): {[string]: {MeshPart}}
	if index then
		return index
	end
	local res = {}
	-- ServerStorage.Modeles3D en priorité, sinon partout ailleurs (hors carte générée)
	local sources = {}
	local dossier = ServerStorage:FindFirstChild("Modeles3D")
	if dossier then
		-- Modeles3D, plus les modèles rangés directement dans ServerStorage (ex. ServerStorage.Nains) :
		-- sinon un dossier Modeles3D créé pour un autre import (arbres...) cacherait les nains.
		local candidats = dossier:GetChildren()
		for _, e in ServerStorage:GetChildren() do
			if e ~= dossier and e.Name ~= "Monde" then
				table.insert(candidats, e)
			end
		end
		-- les nains remplacent l'ancien import « PNJ » (mêmes noms de pièces)
		local nains = dossier:FindFirstChild("Nains", true) ~= nil or ServerStorage:FindFirstChild("Nains") ~= nil
		for _, e in candidats do
			if not (nains and e.Name == "PNJ") then
				table.insert(sources, e)
			end
		end
	else
		for _, conteneur in {ServerStorage, workspace, game:GetService("ReplicatedStorage")} do
			for _, e in conteneur:GetChildren() do
				if e.Name ~= "Carte" and e.Name ~= "Monde" and not e:IsA("Terrain") then
					table.insert(sources, e)
				end
			end
		end
	end
	for _, source in sources do
		for _, d in source:GetDescendants() do
			if d:IsA("MeshPart") and string.match(d.Name, "^%a+%d*_") then
				local prefixe = string.match(d.Name, "^([^_]+)_")
				if prefixe then
					res[prefixe] = res[prefixe] or {}
					table.insert(res[prefixe], d)
				end
			end
		end
	end
	index = res
	return res
end

-- Oublie l'index (après un nouvel import dans la même session Studio)
function Modeles3D.recharger()
	index = nil
end

function Modeles3D.pieces(prefixe: string): {MeshPart}?
	return charger()[prefixe]
end

-- Nombre total de pièces 3D : change à chaque nouvel import (sert à savoir s'il faut reconstruire)
function Modeles3D.signature(): number
	local n = 0
	for _, pieces in charger() do
		n += #pieces
	end
	return n
end

-- Préfixes disponibles qui correspondent au motif (ex. "^Rocher%d+$"), triés
function Modeles3D.variantes(motif: string): {string}
	local res = {}
	for prefixe in charger() do
		if string.match(prefixe, motif) then
			table.insert(res, prefixe)
		end
	end
	table.sort(res)
	return res
end

-- Dernier mot du nom : la teinte (Gaspard_Tete_Peau -> "Peau", Lierre1_Feuilles -> "Feuilles")
function Modeles3D.teinte(p: Instance): string
	return string.match(p.Name, "_([^_]+)$") or p.Name
end

-- Groupe du milieu pour les PNJ (Gaspard_Tete_Peau -> "Tete")
function Modeles3D.groupe(p: Instance): string?
	return string.match(p.Name, "^[^_]+_([^_]+)_")
end

-- Boîte englobante (dans le repère du monde) d'une liste de pièces
function Modeles3D.boite(pieces: {BasePart}): (Vector3, Vector3)
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = -mn
	for _, p in pieces do
		local d = p.Size / 2
		for _, sx in {-1, 1} do
			for _, sy in {-1, 1} do
				for _, sz in {-1, 1} do
					local c = p.CFrame:PointToWorldSpace(Vector3.new(d.X * sx, d.Y * sy, d.Z * sz))
					mn = mn:Min(c)
					mx = mx:Max(c)
				end
			end
		end
	end
	return mn, mx
end

-- Centre moyen des pièces dont la teinte figure dans la liste
function Modeles3D.centre(pieces: {BasePart}, teintes: {[string]: boolean}): Vector3?
	local somme, n = Vector3.zero, 0
	for _, p in pieces do
		if teintes[Modeles3D.teinte(p)] then
			somme += p.Position
			n += 1
		end
	end
	return if n > 0 then somme / n else nil
end

--[[ Copie les pièces dans parent : le repère source S (dans l'espace d'import) est amené
	sur cible, avec une mise à l'échelle k autour de l'origine de S.
	regler(clone, teinte) permet de colorer chaque pièce. ]]
function Modeles3D.poser(pieces: {MeshPart}, S: CFrame, cible: CFrame, k: number, parent: Instance,
	regler: ((MeshPart, string) -> ())?): {MeshPart}
	local clones = {}
	for _, p in pieces do
		local c = p:Clone()
		for _, enfant in c:GetChildren() do
			if enfant:IsA("SurfaceAppearance") then
				enfant:Destroy() -- la couleur vient du jeu
			end
		end
		local rel = S:ToObjectSpace(p.CFrame)
		c.Anchored = true
		c.Size = p.Size * k
		c.CFrame = cible * CFrame.new(rel.Position * k) * rel.Rotation
		pcall(function()
			c.TextureID = ""
		end)
		if regler then
			regler(c, Modeles3D.teinte(p))
		end
		c.Parent = parent
		table.insert(clones, c)
	end
	return clones
end

return Modeles3D
