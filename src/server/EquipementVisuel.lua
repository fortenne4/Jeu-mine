--!strict
-- Armure portée visible (ModuleScript, ServerScriptService › Jeu › EquipementVisuel)
-- Construit le modèle ArmuresVoxels de l'objet équipé et le soude au perso (Model enfant du Character → répliqué à tous).
-- Rappliqué à chaque spawn, au chargement du profil et après équiper / retirer (Sac.server).
--   EquipementVisuel.appliquer(joueur)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Donnees = require(script.Parent:WaitForChild("Donnees"))

-- emplacement → Model dans le Character + partie du corps où souder la Racine (contrat ArmuresVoxels)
local CIBLES: {[string]: {nom: string, os: string}} = {
	Casque = {nom = "ArmureCasque", os = "Head"},
}
local CACHES = {Interieur = true}

local EquipementVisuel = {}

local armures: any = nil
local function modArmures(): any
	if armures == nil then
		armures = false
		local m = ReplicatedStorage:WaitForChild("Partage"):FindFirstChild("ArmuresVoxels")
		local ok, res = pcall(require, m :: any)
		if ok and type(res) == "table" then
			armures = res
			if type(res.prechauffer) == "function" then
				res.prechauffer() -- casques lisses : CSG construit une fois en fond
			end
		else
			warn("[EquipementVisuel] ArmuresVoxels illisible :", res)
		end
	end
	return armures or nil
end

local function objet(p: Donnees.Profil, id: string?): Donnees.Objet?
	for _, o in p.objets do
		if o.id == id then
			return o
		end
	end
	return nil
end

-- Casque porté : cheveux, chapeaux et accessoires soudés à la tête disparaissent (sauf ceux du visage)
local GARDES = {[Enum.AccessoryType.Face] = true, [Enum.AccessoryType.Eyebrow] = true, [Enum.AccessoryType.Eyelash] = true}
local MASQUES = {[Enum.AccessoryType.Hair] = true, [Enum.AccessoryType.Hat] = true}
local ATTR = "TransparenceAvantCasque"

local function surTete(acc: Accessory, tete: Instance?): boolean
	if MASQUES[acc.AccessoryType] then
		return true
	elseif GARDES[acc.AccessoryType] or not tete then
		return false
	end
	for _, d in acc:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			local j: any = d
			if j.Part0 == tete or j.Part1 == tete then
				return true
			end
		end
	end
	return false
end

local function masquerTete(perso: Model, masquer: boolean)
	local tete = perso:FindFirstChild("Head")
	for _, acc in perso:GetChildren() do
		if not acc:IsA("Accessory") then
			continue
		end
		local cacher = masquer and surTete(acc, tete)
		for _, p in acc:GetDescendants() do
			if not p:IsA("BasePart") then
				continue
			end
			local avant = p:GetAttribute(ATTR)
			if cacher and avant == nil then
				p:SetAttribute(ATTR, p.Transparency)
				p.Transparency = 1
			elseif not cacher and type(avant) == "number" then
				p.Transparency = avant
				p:SetAttribute(ATTR, nil)
			end
		end
	end
end

-- Taille visuelle de la tête : MeshPart R15 = Size ; tête classique (Part 2x1x1 + SpecialMesh Head) = petit côté x Scale.
local function tailleVisuelle(tete: BasePart): Vector3
	local sm = tete:FindFirstChildOfClass("SpecialMesh")
	if sm and sm.MeshType == Enum.MeshType.Head then
		local b = math.min(tete.Size.Y, tete.Size.Z)
		return Vector3.new(b * sm.Scale.X, b * sm.Scale.Y, b * sm.Scale.Z)
	end
	return tete.Size
end

local function construire(slot: string, o: Donnees.Objet, tailleTete: Vector3): Model?
	local mod = modArmures()
	if not mod then
		return nil
	end
	local modele = if o.modele:sub(1, #slot) == slot and mod.existe(o.modele) then o.modele else slot
	if not mod.existe(modele) then
		return nil
	end
	local ok, teinte = pcall(Color3.fromHex, o.couleur)
	local ok2, m = pcall(mod.construire, modele, if ok then teinte else nil, tailleTete)
	if not ok2 or typeof(m) ~= "Instance" then
		warn("[EquipementVisuel] construction ratée :", modele, m)
		return nil
	end
	for _, d in (m :: Model):GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, false, true
			if CACHES[d.Name] then
				d.Transparency = 1
			end
		end
	end
	return m :: Model
end

local tours: { [Player]: number } = {} -- construire peut céder (CSG) : seul le dernier appel l'emporte

function EquipementVisuel.appliquer(joueur: Player)
	local tour = (tours[joueur] or 0) + 1
	tours[joueur] = tour
	local p = Donnees.profil(joueur)
	local perso = joueur.Character
	if not (p and perso) then
		return
	end
	for slot, c in CIBLES do
		local o = objet(p, p.equipement[slot])
		local cle = if o then o.id .. "|" .. o.modele .. "|" .. o.couleur else nil
		local partie = perso:FindFirstChild(c.os)
		local ancien = perso:FindFirstChild(c.nom)
		if ancien then
			local soudure: any = ancien:FindFirstChild("Soudure", true)
			if cle and ancien:GetAttribute("Cle") == cle and soudure and soudure.Part0 == partie then
				continue
			end
			ancien:Destroy()
		end
		if not (o and cle and partie and partie:IsA("BasePart")) then
			continue
		end
		local m = construire(slot, o, tailleVisuelle(partie))
		local racine = m and m.PrimaryPart
		if not (m and racine) then
			continue
		end
		if tours[joueur] ~= tour or partie.Parent ~= perso or perso.Parent == nil then
			m:Destroy() -- construire a cédé (CSG) et un appel plus récent / un respawn est passé entre-temps
			continue
		end
		local doublon = perso:FindFirstChild(c.nom)
		if doublon then
			doublon:Destroy()
		end
		m.Name = c.nom
		m:SetAttribute("Cle", cle)
		m:PivotTo(partie.CFrame)
		local w = Instance.new("Weld")
		w.Name = "Soudure"
		w.Part0, w.Part1 = partie, racine
		w.Parent = racine
		m.Parent = perso
	end
	masquerTete(perso, perso:FindFirstChild(CIBLES.Casque.nom) ~= nil)
end

local function surPerso(joueur: Player, perso: Model)
	perso:WaitForChild("Humanoid", 10)
	EquipementVisuel.appliquer(joueur)
	perso.ChildAdded:Connect(function(c)
		if c:IsA("Accessory") then
			task.delay(0.1, EquipementVisuel.appliquer, joueur) -- accessoire tardif : sa soudure arrive juste après
			return
		end
		for _, cible in CIBLES do
			if c.Name == cible.os then
				EquipementVisuel.appliquer(joueur) -- partie du corps remplacée (apparence chargée)
				return
			end
		end
	end)
end

local function surJoueur(joueur: Player)
	joueur.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			tours[joueur] = nil
		end
	end)
	joueur.CharacterAdded:Connect(function(perso)
		surPerso(joueur, perso)
	end)
	if joueur.Character then
		task.spawn(surPerso, joueur, joueur.Character)
	end
	if Donnees.attendre(joueur) then
		EquipementVisuel.appliquer(joueur)
	end
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do
	task.spawn(surJoueur, j)
end

return EquipementVisuel
