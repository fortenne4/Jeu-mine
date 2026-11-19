--!strict
-- Pioche dans le dos · SCRIPT SERVEUR
-- Quand le joueur ne tient pas sa pioche, elle est rangée dans son dos (manche en haut près de
-- l'épaule droite, tête en bas à gauche), comme une arme. Ce script construit ce modèle
-- (« PiocheDos ») dans le personnage, donc il est répliqué à tout le monde.
--
-- Le serveur ne cache JAMAIS le modèle : c'est chaque client (PiocheDosAnimation) qui décide,
-- pour chaque personnage, s'il montre la pioche dans le dos ou l'outil en main, au bon moment
-- du geste de dégainage. Ainsi tout le monde voit le même geste sans attendre le réseau.
--
-- Le modèle est copié à partir des pièces visibles de l'outil (BasePart enfants directs du Tool,
-- Transparency < 1) : pas d'effets (particules, lumières, traînées, aura, contour).
-- Il est reconstruit quand l'outil est remplacé (changement de pioche) ou que le torse change.

local Players = game:GetService("Players")

-- ===== Réglages de la pose dans le dos (repère du torse : +X = droite, +Y = haut, +Z = dos) =====
local INCLINAISON = math.rad(25) -- inclinaison du manche par rapport à la verticale
local DECALAGE_X = 0.05 -- studs vers la droite
local HAUTEUR = -0.05 -- fraction de la hauteur du torse (négatif = plus bas)
local ECART_DOS = 0.32 -- studs entre la surface du dos et l'axe du manche

local NOM_MODELE = "PiocheDos"
local NOM_RACINE = "RacineDos"
local NOM_SOUDURE = "SoudureDos"

type EtatJoueur = {
	connexions: {RBXScriptConnection}, -- vivent autant que le joueur
	connexionsPerso: {RBXScriptConnection}, -- vivent autant que le personnage
	connexionsSac: {RBXScriptConnection}, -- vivent autant que le Backpack actuel
	modele: Model?,
	outil: Tool?,
	torse: BasePart?,
	enAttente: boolean,
}

local etats: {[Player]: EtatJoueur} = {}

local function deconnecter(liste: {RBXScriptConnection})
	for _, c in liste do
		c:Disconnect()
	end
	table.clear(liste)
end

local function estPioche(instance: Instance): boolean
	return instance:IsA("Tool") and instance:GetAttribute("PiocheId") ~= nil
end

-- Pioche actuelle du joueur : en main d'abord, sinon dans le sac
local function piocheDans(conteneur: Instance?): Tool?
	if not conteneur then
		return nil
	end
	for _, t in conteneur:GetChildren() do
		if estPioche(t) then
			return t :: Tool
		end
	end
	return nil
end

local function piocheDe(joueur: Player): Tool?
	return piocheDans(joueur.Character) or piocheDans(joueur:FindFirstChildOfClass("Backpack"))
end

local function torseDe(perso: Model): BasePart?
	local torse = perso:FindFirstChild("UpperTorso") or perso:FindFirstChild("Torso")
	if torse and torse:IsA("BasePart") then
		return torse
	end
	return nil
end

-- Repère du Handle de la pioche une fois rangée, relatif au torse.
-- Manche (+Y du Handle) vers le bas-gauche : la tête est en bas à gauche, le bout du manche
-- dépasse au-dessus de l'épaule droite (là où la main va le chercher).
-- Pic (-Z du Handle) à plat contre le dos, vers la droite.
local function poseDos(torse: BasePart): CFrame
	local s, c = math.sin(INCLINAISON), math.cos(INCLINAISON)
	local position = Vector3.new(DECALAGE_X, HAUTEUR * torse.Size.Y, torse.Size.Z / 2 + ECART_DOS)
	local axeY = Vector3.new(-s, -c, 0) -- vers la tête de la pioche
	local axeX = Vector3.new(0, 0, -1)
	return CFrame.fromMatrix(position, axeX, axeY)
end

local function piecesVisibles(outil: Tool): {BasePart}
	local res = {}
	for _, enfant in outil:GetChildren() do
		if enfant:IsA("BasePart")
			and enfant.Transparency < 1
			and enfant.Name ~= "Aura"
			and enfant:GetAttribute("Coque") == nil
		then
			table.insert(res, enfant)
		end
	end
	return res
end

-- Copie nue d'une pièce : on ne garde que ce qui sert à l'apparence
local function copiePiece(source: BasePart): BasePart?
	local ok, copie = pcall(function()
		return source:Clone()
	end)
	if not ok or not copie then
		return nil
	end
	for _, enfant in copie:GetChildren() do
		if not (enfant:IsA("DataModelMesh") or enfant:IsA("Decal") or enfant:IsA("SurfaceAppearance")) then
			enfant:Destroy()
		end
	end
	for _, tag in copie:GetTags() do
		copie:RemoveTag(tag)
	end
	for nom in copie:GetAttributes() do
		copie:SetAttribute(nom, nil)
	end
	copie.Name = "Piece" .. source.Name
	copie.Anchored = false
	copie.CanCollide = false
	copie.CanQuery = false
	copie.CanTouch = false
	copie.Massless = true
	copie:SetAttribute("TransparenceOrigine", copie.Transparency)
	return copie
end

local function construire(outil: Tool, perso: Model, torse: BasePart): Model?
	local handle = outil:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return nil
	end

	local modele = Instance.new("Model")
	modele.Name = NOM_MODELE
	modele:SetAttribute("PiocheId", outil:GetAttribute("PiocheId"))

	-- Racine invisible = position du Handle quand la pioche est rangée
	local racine = Instance.new("Part")
	racine.Name = NOM_RACINE
	racine.Size = Vector3.new(0.2, 0.2, 0.2)
	racine.Transparency = 1
	racine.CanCollide = false
	racine.CanQuery = false
	racine.CanTouch = false
	racine.CastShadow = false
	racine.Massless = true
	racine.CFrame = torse.CFrame * poseDos(torse)
	racine.Parent = modele
	modele.PrimaryPart = racine

	for _, source in piecesVisibles(outil) do
		local copie = copiePiece(source)
		if copie then
			-- Les pièces de l'outil sont soudées entre elles : leurs positions relatives sont justes
			-- même quand l'outil est dans le Backpack.
			local relatif = handle.CFrame:ToObjectSpace(source.CFrame)
			copie.CFrame = racine.CFrame * relatif
			local soudure = Instance.new("Weld")
			soudure.Part0 = racine
			soudure.Part1 = copie
			soudure.C0 = relatif
			soudure.Parent = copie
			copie.Parent = modele
		end
	end

	-- Le client déplace cette soudure (torse ↔ main) pendant le geste de rangement
	local soudureDos = Instance.new("Weld")
	soudureDos.Name = NOM_SOUDURE
	soudureDos.Part0 = torse
	soudureDos.Part1 = racine
	soudureDos.C0 = poseDos(torse)
	soudureDos.Parent = racine

	modele.Parent = perso
	return modele
end

local function retirerModele(etat: EtatJoueur)
	if etat.modele then
		etat.modele:Destroy()
	end
	etat.modele = nil
	etat.outil = nil
	etat.torse = nil
end

local function actualiser(joueur: Player)
	local etat = etats[joueur]
	if not etat then
		return
	end
	local perso = joueur.Character
	local humanoid = perso and perso:FindFirstChildOfClass("Humanoid")
	if not perso or not perso.Parent or not humanoid then
		retirerModele(etat)
		return
	end
	local outil = piocheDe(joueur)
	local torse = torseDe(perso)
	local modele = etat.modele
	local aJour = modele ~= nil
		and modele.Parent == perso
		and etat.outil == outil
		and etat.torse == torse
	if aJour then
		return
	end
	retirerModele(etat)
	if outil and torse then
		etat.modele = construire(outil, perso, torse)
		etat.outil = outil
		etat.torse = torse
	end
end

-- Regroupe plusieurs événements de la même frame (ex. ancienne pioche détruite + nouvelle donnée)
local function planifier(joueur: Player)
	local etat = etats[joueur]
	if not etat or etat.enAttente then
		return
	end
	etat.enAttente = true
	task.defer(function()
		local e = etats[joueur]
		if e then
			e.enAttente = false
			actualiser(joueur)
		end
	end)
end

local function suivreSac(joueur: Player, sac: Instance)
	local etat = etats[joueur]
	if not etat then
		return
	end
	deconnecter(etat.connexionsSac)
	table.insert(etat.connexionsSac, sac.ChildAdded:Connect(function(enfant)
		if estPioche(enfant) then
			planifier(joueur)
		end
	end))
	table.insert(etat.connexionsSac, sac.ChildRemoved:Connect(function(enfant)
		if estPioche(enfant) then
			planifier(joueur)
		end
	end))
	planifier(joueur)
end

local function surPerso(joueur: Player, perso: Model)
	local etat = etats[joueur]
	if not etat then
		return
	end
	deconnecter(etat.connexionsPerso)
	retirerModele(etat)
	-- Tout enfant ajouté/retiré peut compter : la pioche, mais aussi le torse (avatar appliqué)
	table.insert(etat.connexionsPerso, perso.ChildAdded:Connect(function(enfant)
		if enfant.Name ~= NOM_MODELE then
			planifier(joueur)
		end
	end))
	table.insert(etat.connexionsPerso, perso.ChildRemoved:Connect(function(enfant)
		planifier(joueur)
	end))
	planifier(joueur)
end

local function surJoueur(joueur: Player)
	if etats[joueur] then
		return
	end
	local etat: EtatJoueur = {
		connexions = {},
		connexionsPerso = {},
		connexionsSac = {},
		modele = nil,
		outil = nil,
		torse = nil,
		enAttente = false,
	}
	etats[joueur] = etat

	table.insert(etat.connexions, joueur.CharacterAdded:Connect(function(perso)
		surPerso(joueur, perso)
	end))
	table.insert(etat.connexions, joueur.CharacterRemoving:Connect(function()
		deconnecter(etat.connexionsPerso)
		retirerModele(etat)
	end))
	-- Le Backpack est recréé à chaque réapparition
	table.insert(etat.connexions, joueur.ChildAdded:Connect(function(enfant)
		if enfant:IsA("Backpack") then
			suivreSac(joueur, enfant)
		end
	end))

	local sac = joueur:FindFirstChildOfClass("Backpack")
	if sac then
		suivreSac(joueur, sac)
	end
	if joueur.Character then
		surPerso(joueur, joueur.Character)
	end
end

Players.PlayerAdded:Connect(surJoueur)
Players.PlayerRemoving:Connect(function(joueur)
	local etat = etats[joueur]
	if not etat then
		return
	end
	deconnecter(etat.connexions)
	deconnecter(etat.connexionsPerso)
	deconnecter(etat.connexionsSac)
	retirerModele(etat)
	etats[joueur] = nil
end)
for _, joueur in Players:GetPlayers() do
	surJoueur(joueur)
end
