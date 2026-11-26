--!strict
-- Armure portée visible (ModuleScript, ServerScriptService › Jeu › EquipementVisuel)
-- Construit le modèle ArmuresVoxels de l'objet équipé et le soude au perso (Model enfant du Character → répliqué à tous).
-- Rappliqué à chaque spawn, au chargement du profil et après équiper / retirer (Sac.server).
--   EquipementVisuel.appliquer(joueur)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Donnees = require(script.Parent:WaitForChild("Donnees"))

-- emplacement → Model dans le Character + partie du corps où souder la Racine (contrat ArmuresVoxels)
-- os = partie de référence (R15) ; osR6 = équivalent R6. Jambières : chaque jambe est découpée au genou
-- (cuisse → UpperLeg, tibia → LowerLeg) pour suivre la marche.
local CIBLES: {[string]: {nom: string, os: string, osR6: string?}} = {
	Casque = {nom = "ArmureCasque", os = "Head"},
	Plastron = {nom = "ArmurePlastron", os = "UpperTorso", osR6 = "Torso"},
	Jambieres = {nom = "ArmureJambieres", os = "LeftUpperLeg", osR6 = "Left Leg"},
}
-- parties du corps dont le remplacement (apparence chargée) relance l'application
local OS_SUIVIS = {
	Head = true, UpperTorso = true, Torso = true, LeftUpperLeg = true, RightUpperLeg = true,
	LeftLowerLeg = true, RightLowerLeg = true, ["Left Leg"] = true, ["Right Leg"] = true,
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

local function construire(slot: string, o: Donnees.Objet, tailleTete: Vector3?): Model?
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

local function souder(os: BasePart, piece: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Name = "Soudure"
	w.Part0, w.Part1 = os, piece
	w.C0 = c0
	w.Parent = piece
end

-- Point d'articulation (attachement de rig R15) dans le repère de la partie, axes de la partie
local function point(partie: BasePart, nomAttache: string, repli: Vector3): CFrame
	local a = partie:FindFirstChild(nomAttache)
	return CFrame.new(if a and a:IsA("Attachment") then a.Position else repli)
end

-- Plastron : Racine = centre du torse. Dessiné pour un UpperTorso de 2 studs de large.
local function porterPlastron(perso: Model, m: Model): boolean
	local torse = perso:FindFirstChild("UpperTorso") or perso:FindFirstChild("Torso")
	local racine = m.PrimaryPart
	if not (torse and torse:IsA("BasePart") and racine) then
		return false
	end
	local f = math.clamp(torse.Size.X / 2, 0.5, 3)
	if math.abs(f - 1) > 0.02 then
		m:ScaleTo(f)
	end
	-- Chaque pièce est soudée directement au torse (Weld à décalage fixe) : les WeldConstraint vers la Racine
	-- se recalculaient mal chez les clients (pièces restées à l'endroit de construction, plastron invisible).
	local places: {[BasePart]: CFrame} = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			places[p] = p.CFrame
		end
	end
	for _, j in m:GetDescendants() do
		if j:IsA("WeldConstraint") or j:IsA("JointInstance") then
			j:Destroy()
		end
	end
	local origine = places[racine]
	for p, cf in places do
		souder(torse, p, origine:ToObjectSpace(cf))
	end
	m:PivotTo(torse.CFrame) -- déjà en place avant d'être répliqué
	return true
end

-- Jambières : Racine entre les jambes au genou (hanches y = +1, chevilles y = -1, jambe = 2 studs).
-- Chaque pièce d'une jambe est ressoudée à la cuisse (au-dessus du genou) ou au tibia (en dessous).
local function porterJambieres(perso: Model, m: Model): boolean
	local racine = m.PrimaryPart
	if not racine then
		return false
	end
	-- échelle d'après la longueur réelle hanche → cheville (R15) ou de la jambe (R6)
	local longueur = 2
	local hautG, basG = perso:FindFirstChild("LeftUpperLeg"), perso:FindFirstChild("LeftLowerLeg")
	if hautG and hautG:IsA("BasePart") and basG and basG:IsA("BasePart") then
		local hanche = point(hautG, "LeftHipRigAttachment", Vector3.new(0, hautG.Size.Y / 2, 0)).Position
		local genouH = point(hautG, "LeftKneeRigAttachment", Vector3.new(0, -hautG.Size.Y / 2, 0)).Position
		local genouB = point(basG, "LeftKneeRigAttachment", Vector3.new(0, basG.Size.Y / 2, 0)).Position
		local cheville = point(basG, "LeftAnkleRigAttachment", Vector3.new(0, -basG.Size.Y / 2, 0)).Position
		longueur = (hanche - genouH).Magnitude + (genouB - cheville).Magnitude
	else
		local r6 = perso:FindFirstChild("Left Leg")
		if r6 and r6:IsA("BasePart") then
			longueur = r6.Size.Y
		end
	end
	local f = math.clamp(longueur / 2, 0.5, 3)
	if math.abs(f - 1) > 0.02 then
		m:ScaleTo(f)
	end
	-- os de chaque jambe + position du genou dans le repère de l'os
	local function jambe(cote: string, r6Nom: string): (BasePart?, CFrame, BasePart?, CFrame)
		local haut, bas = perso:FindFirstChild(cote .. "UpperLeg"), perso:FindFirstChild(cote .. "LowerLeg")
		if haut and haut:IsA("BasePart") and bas and bas:IsA("BasePart") then
			return haut, point(haut, cote .. "KneeRigAttachment", Vector3.new(0, -haut.Size.Y / 2, 0)),
				bas, point(bas, cote .. "KneeRigAttachment", Vector3.new(0, bas.Size.Y / 2, 0))
		end
		local r6 = perso:FindFirstChild(r6Nom)
		if r6 and r6:IsA("BasePart") then
			return r6, CFrame.identity, r6, CFrame.identity -- R6 : jambe d'un bloc, genou = son centre
		end
		return nil, CFrame.identity, nil, CFrame.identity
	end
	local bassin = perso:FindFirstChild("LowerTorso") or perso:FindFirstChild("Torso")
	if not (bassin and bassin:IsA("BasePart")) then
		return false
	end
	-- repère de chaque pièce avant de défaire les soudures du modèle
	local places: {[BasePart]: CFrame} = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			places[p] = p.CFrame
		end
	end
	for _, j in m:GetDescendants() do
		if j:IsA("WeldConstraint") or j:IsA("JointInstance") then
			j:Destroy()
		end
	end
	local fait = false
	for _, c in {{"JambeG", "Left", "Left Leg"}, {"JambeD", "Right", "Right Leg"}} do
		local g = m:FindFirstChild(c[1])
		local centre = g and g:IsA("Model") and g.PrimaryPart
		local osHaut, genouHaut, osBas, genouBas = jambe(c[2], c[3])
		if not (g and centre and osHaut and osBas) then
			continue
		end
		for _, p in g:GetDescendants() do
			if p:IsA("BasePart") then
				local rel = places[centre]:ToObjectSpace(places[p])
				if p == centre or rel.Position.Y >= 0 then
					souder(osHaut, p, genouHaut * rel) -- cuisse
				else
					souder(osBas, p, genouBas * rel) -- tibia
				end
			end
		end
		fait = true
	end
	-- Racine et pièces hors des jambes (ceinture…) : bassin ; hanches = bas du bassin = y +1 (× échelle)
	local cRacine = CFrame.new(0, -bassin.Size.Y / 2 - f, 0)
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			souder(bassin, p, cRacine * places[racine]:ToObjectSpace(places[p]))
		end
	end
	return fait
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
		local partie = perso:FindFirstChild(c.os) or (c.osR6 and perso:FindFirstChild(c.osR6))
		local ancien = perso:FindFirstChild(c.nom)
		if ancien then
			-- toujours soudé à des parties actuelles du perso (pas d'apparence rechargée entre-temps) : on garde
			local soudure: any = ancien:FindFirstChild("Soudure", true)
			if cle and ancien:GetAttribute("Cle") == cle and soudure and soudure.Part0 and soudure.Part0.Parent == perso then
				continue
			end
			ancien:Destroy()
		end
		if not (o and cle and partie and partie:IsA("BasePart")) then
			continue
		end
		local m = construire(slot, o, if slot == "Casque" then tailleVisuelle(partie) else nil)
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
		local porte = true
		if slot == "Plastron" then
			porte = porterPlastron(perso, m)
		elseif slot == "Jambieres" then
			porte = porterJambieres(perso, m)
		else
			m:PivotTo(partie.CFrame)
			souder(partie, racine, CFrame.identity)
		end
		if not porte then
			m:Destroy()
			continue
		end
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
		if OS_SUIVIS[c.Name] then
			EquipementVisuel.appliquer(joueur) -- partie du corps remplacée (apparence chargée)
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
