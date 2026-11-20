--[[ Modèles 3D des pioches (Blender, assets/Pioches.fbx importé dans ServerStorage › Modeles3D).

	Pour chaque pioche du catalogue, les pièces « Pioche<Id>_Manche_... » et « Pioche<Id>_Tete_... »
	sont remises à l'échelle et placées dans le repère du manche de l'outil (comme les pioches en blocs) :
	  • manche le long de Y, environ 5,3 studs de haut, centré en 0 ;
	  • pic vers -Z (le côté de la tête qui dépasse le plus du manche).
	Le résultat (un Model par pioche) est rangé dans ReplicatedStorage › ModelesPioches :
	le serveur s'en sert pour l'outil en main, le client pour l'aperçu de la boutique.
	Sans import, rien n'est créé et le jeu garde les pioches en blocs. ]]
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Pioches = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Pioches"))
local Modeles3D = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Modeles3D"))
local PiochesVoxels = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("PiochesVoxels"))

local HAUTEUR = 5.3 -- même taille que la pioche en blocs (manche 4,4 + tête)

local PiochesModeles = {}

local dossier = Instance.new("Folder")
dossier.Name = "ModelesPioches"

local AXES = {Vector3.xAxis, Vector3.yAxis, Vector3.zAxis}

-- Axe du monde (±X, ±Y, ±Z) le plus long d'une boîte
local function axeLePlusLong(taille: Vector3, sauf: Vector3?): Vector3
	local meilleur, longueur = Vector3.yAxis, -1
	for _, a in AXES do
		if not (sauf and math.abs(a:Dot(sauf)) > 0.5) then
			local l = math.abs(taille:Dot(a))
			if l > longueur then
				meilleur, longueur = a, l
			end
		end
	end
	return meilleur
end

-- Les maillages importés appartiennent au compte Roblox de celui qui les a importés :
-- pour un autre compte, Roblox peut refuser de les charger (pioche invisible).
-- Dans ce cas on garde la version en blocs.
-- (PreloadAsync peut ne jamais rendre la main sur un asset refusé : on attend au plus DELAI_MAILLAGES.)
local DELAI_MAILLAGES = 4
local verdictMaillages: boolean? = nil

local function maillagesChargeables(): boolean
	if verdictMaillages ~= nil then
		return verdictMaillages
	end
	local ids, vus = {}, {}
	for _, def in Pioches.LISTE do
		for _, p in Modeles3D.pieces("Pioche" .. def.id) or {} do
			if p.MeshId ~= "" and not vus[p.MeshId] then
				vus[p.MeshId] = true
				table.insert(ids, p.MeshId)
			end
		end
	end
	local reussis, echec = 0, false
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(ids, function(_, statut)
				if statut == Enum.AssetFetchStatus.Success then
					reussis += 1
				else
					echec = true
				end
			end)
		end)
	end)
	local debut = os.clock()
	while not echec and reussis < #ids and os.clock() - debut < DELAI_MAILLAGES do
		task.wait(0.1)
	end
	verdictMaillages = not echec and reussis >= #ids
	if not verdictMaillages then
		warn(string.format("[PiochesModeles] Maillages 3D des pioches inaccessibles pour ce compte (%d/%d chargés) : pioches en blocs", reussis, #ids))
	end
	return verdictMaillages
end

local function construire(id: string): Model?
	local pieces = Modeles3D.pieces("Pioche" .. id)
	if not pieces or #pieces == 0 then
		return nil
	end
	if not maillagesChargeables() then
		return nil
	end
	local manche, tete = {}, {}
	for _, p in pieces do
		table.insert(if Modeles3D.groupe(p) == "Manche" then manche else tete, p)
	end
	if #manche == 0 or #tete == 0 then
		manche, tete = pieces, pieces
	end

	local mn, mx = Modeles3D.boite(pieces)
	local mMn, mMx = Modeles3D.boite(manche)
	local tMn, tMx = Modeles3D.boite(tete)
	local cManche, cTete = (mMn + mMx) / 2, (tMn + tMx) / 2

	-- Axe du manche, orienté vers la tête
	local haut = axeLePlusLong(mMx - mMn)
	if (cTete - cManche):Dot(haut) < 0 then
		haut = -haut
	end
	-- Axe de la tête, orienté vers le pic (le côté le plus long depuis le manche)
	local travers = axeLePlusLong(tMx - tMn, haut)
	if (tMx - cManche):Dot(travers) < (cManche - tMn):Dot(travers) then
		travers = -travers
	end

	-- Repère source : Y = haut, Z = -pic (le pic part vers -Z), origine sur l'axe du manche, à mi-hauteur
	local bas, sommet = math.min(mn:Dot(haut), mx:Dot(haut)), math.max(mn:Dot(haut), mx:Dot(haut))
	local longueur = sommet - bas
	if longueur <= 0 then
		return nil
	end
	local origine = cManche - haut * cManche:Dot(haut) + haut * (bas + sommet) / 2
	local arriere = -travers
	local S = CFrame.fromMatrix(origine, haut:Cross(arriere), haut)
	local k = HAUTEUR / longueur

	local modele = Instance.new("Model")
	modele.Name = id
	local pointe = Vector3.new(0, HAUTEUR * 0.32, -1)
	for _, p in pieces do
		local c = p:Clone()
		for _, enfant in c:GetChildren() do
			if not (enfant:IsA("SurfaceAppearance") or enfant:IsA("Decal") or enfant:IsA("Texture")) then
				enfant:Destroy()
			end
		end
		local rel = S:ToObjectSpace(p.CFrame)
		c.Size = p.Size * k
		c.CFrame = CFrame.new(rel.Position * k) * rel.Rotation
		c.Anchored = true
		c.CanCollide = false
		c.CanQuery = false
		c.CanTouch = false
		c.Massless = true
		c.Parent = modele
	end

	-- Bout du pic et centre de la tête (dans le repère du manche) pour les flammes, la traînée et la lumière
	local tMnL, tMxL = Modeles3D.boite(tete)
	local a, b = S:PointToObjectSpace(tMnL) * k, S:PointToObjectSpace(tMxL) * k
	local tmin, tmax = a:Min(b), a:Max(b)
	local centreTete = (tmin + tmax) / 2
	pointe = Vector3.new(0, centreTete.Y - (tmax.Y - tmin.Y) * 0.15, tmin.Z)
	modele.WorldPivot = CFrame.identity -- repère du manche (pas celui de la première pièce)
	modele:SetAttribute("Pointe", pointe)
	modele:SetAttribute("Centre", Vector3.new(0, centreTete.Y, 0))
	modele:SetAttribute("Talon", Vector3.new(0, tmax.Y, tmax.Z * 0.3))
	return modele
end

local gabarits: {[string]: Model} = {}

-- Modèle 3D de la pioche, dans le repère du manche : les maillages importés s'il y en a,
-- sinon la version en blocs générée depuis Blender (Partage › PiochesVoxels), sinon nil.
function PiochesModeles.gabarit(id: string): Model?
	if not gabarits[id] and PiochesVoxels.existe(id) then
		gabarits[id] = PiochesVoxels.construire(id)
	end
	return gabarits[id]
end

for _, def in Pioches.LISTE do
	local ok, res = pcall(construire, def.id)
	if ok and res then
		gabarits[def.id] = res
		res.Parent = dossier
	elseif not ok then
		warn("[PiochesModeles] " .. def.id .. " : " .. tostring(res))
	end
end
dossier.Parent = ReplicatedStorage

return PiochesModeles
