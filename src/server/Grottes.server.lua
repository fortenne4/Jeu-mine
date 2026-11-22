-- Grottes profondes · SCRIPT SERVEUR
-- Entrée dans la caverne (panneau + cercle lumineux « 0/2 », 1,25 × le cercle des tunnels privés).
-- Le premier joueur qui entre dans le cercle devient le chef : il choisit la profondeur (InterfaceGrottes.client)
-- et peut inviter un joueur (amis en premier côté client). Un 2e joueur peut aussi simplement entrer dans le cercle.
-- Au départ, une grotte aléatoire est générée (Monde › GrotteGenerateur), peuplée de mobs (MobsGrotte), et le
-- groupe y est téléporté. Le cercle « Sortie » de la grotte ramène devant l'entrée. La grotte est détruite quand
-- plus personne n'est dedans (sortie, mort, départ du jeu).
-- Serveur autoritaire : le chef seul lance ; niveaux, invitations et téléportations sont validés ici.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Partage = ReplicatedStorage:WaitForChild("Partage")
local Grottes = require(Partage:WaitForChild("Grottes"))
local Pioches = require(Partage:WaitForChild("Pioches"))
local Forge = require(Partage:WaitForChild("Forge"))
local Donnees = require(script.Parent:WaitForChild("Donnees"))
local acces = require(script.Parent:WaitForChild("AccesMine"))
local MobsGrotte = require(script.Parent:WaitForChild("MobsGrotte"))

local monde = ServerStorage:WaitForChild("Monde")
local D = require(monde:WaitForChild("Disposition"))
local O = require(monde:WaitForChild("Outils"))
local B = require(monde:WaitForChild("Batiments"))
local Cercle = require(monde:WaitForChild("CercleLumineux"))
local Generateur = require(monde:WaitForChild("GrotteGenerateur"))
local M, C = O.M, O.C

local PAS = 0.1
local RECHARGE = 3          -- délai avant de pouvoir réactiver le cercle après un voyage / une annulation
local FLUX_LIMITE = 3
local INVITATION_DUREE = 25
local RAYON = Grottes.RAYON_CERCLE
-- Entrée : lobe est de la caverne, à droite du Tunnel VI, face au centre
local ENTREE = Vector3.new(50, D.CAVERNE_SOL, -425)

-- ================= Remotes =================
local dossierRemotes = Instance.new("Folder")
dossierRemotes.Name = "Grottes"
local R = {}
for _, nom in Grottes.REMOTES do
	local e = Instance.new("RemoteEvent")
	e.Name = nom
	e.Parent = dossierRemotes
	R[nom] = e
end
dossierRemotes.Parent = ReplicatedStorage

-- ================= Stats d'équipement (barre de difficulté côté client) =================
local function statsDe(joueur: Player)
	local p = Donnees.profil(joueur)
	local pioche, epee, defense = 1, Forge.EPEE_BASE.valeur, 0
	if p then
		local def = Pioches.get(p.equipee)
		if def then pioche = def.puissance end
		local equipement = p.equipement or {}
		for _, o in p.objets or {} do
			if equipement[o.type] == o.id then
				if o.type == "Epee" then
					epee = o.valeur
				elseif o.type == "Casque" or o.type == "Plastron" or o.type == "Jambieres" then
					defense += o.valeur
				end
			end
		end
	end
	return pioche, epee, defense
end

local function majStats(joueur: Player)
	if not joueur.Parent then return end
	local pioche, epee, defense = statsDe(joueur)
	joueur:SetAttribute("StatPioche", pioche)
	joueur:SetAttribute("StatEpee", epee)
	joueur:SetAttribute("StatDefense", defense)
end

Donnees.surChangement(function(joueur) task.spawn(majStats, joueur) end)

-- ================= Entrée dans la caverne =================
-- Portail des profondeurs : arche de pierre sombre en voussoirs, vide violet où s'enfoncent les rails,
-- cristaux, braseros, lanternes suspendues, wagonnet abandonné et 5 gemmes (une par palier) sur le pilier.
local PIERRE = Color3.fromRGB(58, 53, 64)
local PIERRE_CLAIRE = Color3.fromRGB(88, 82, 96)
local VIOLET = Color3.fromRGB(186, 96, 255)
local BRAISE = Color3.fromRGB(255, 150, 70)

local entree, cercle, centreCercle
local function construireEntree()
	local f = workspace:FindFirstChild("EntreeGrottes")
	if f then f:Destroy() end
	f = O.modele(workspace, "EntreeGrottes")
	local rng = Random.new(4242)
	-- Sol réel (terrain) sous l'entrée
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	local hit = workspace:Raycast(ENTREE + Vector3.new(0, 20, 0), Vector3.new(0, -50, 0), params)
	local sol = Vector3.new(ENTREE.X, if hit then hit.Position.Y else ENTREE.Y, ENTREE.Z)
	local centre = Vector3.new(D.CAVERNE_CENTRE.X, sol.Y, D.CAVERNE_CENTRE.Z)
	local base = CFrame.lookAt(sol, centre) -- -Z vers le centre de la caverne, le portail est derrière (+Z)
	local function L(x, y, z) return base * CFrame.new(x, y, z) end
	local function pierre(k) return PIERRE:Lerp(PIERRE_CLAIRE, k) end

	-- Dalle gravée sous le cercle (le cercle se pose dessus) et marches vers le portail
	O.cylindre(f, 0.4, (RAYON + 2.4) * 2, L(0, 0.2, 0), pierre(0.15), M.Ardoise, "Dalle")
	O.decor(O.cylindre(f, 0.42, (RAYON + 2.6) * 2, L(0, 0.19, 0), pierre(0.5), M.Pierre, "BordDalle"))
	for k = 0, 11 do
		local a = k * math.pi / 6
		O.decor(O.bloc(f, Vector3.new(0.5, 0.06, 1.6), L(math.cos(a) * (RAYON + 1.5), 0.43, math.sin(a) * (RAYON + 1.5)) * CFrame.Angles(0, -a, 0),
			VIOLET, M.Neon, "RuneDalle"))
	end
	local A = RAYON + 6 -- plan de l'arche
	for k = 0, 2 do
		O.bloc(f, Vector3.new(14 - k * 0.8, 0.5 + k * 0.5, 2.2), L(0, (0.5 + k * 0.5) / 2, RAYON + 2.6 + k * 1.1), pierre(0.3 + k * 0.1), M.Ardoise, "Marche")
	end
	O.bloc(f, Vector3.new(14, 1.5, 3.4), L(0, 0.75, A), pierre(0.2), M.Ardoise, "Seuil")

	-- Piliers : blocs empilés irréguliers, fondations qui descendent dans le sol
	local R_ARC, Y_ARC = 8.5, 17
	for _, s in {-1, 1} do
		O.bloc(f, Vector3.new(5.6, 5, 5.2), L(s * R_ARC, -1.5, A), pierre(0), M.Ardoise, "Fondation")
		local y = 1
		while y < Y_ARC do
			local h = rng:NextNumber(2.6, 3.8)
			h = math.min(h, Y_ARC - y + 0.4)
			O.bloc(f, Vector3.new(rng:NextNumber(3.9, 4.5), h, rng:NextNumber(3.9, 4.4)), L(s * R_ARC + rng:NextNumber(-0.15, 0.15), y + h / 2, A),
				pierre(rng:NextNumber(0, 0.45)), if rng:NextNumber() < 0.5 then M.Ardoise else M.Granite, "Pilier")
			y += h
		end
		O.bloc(f, Vector3.new(5.4, 1.2, 5.2), L(s * R_ARC, Y_ARC, A), pierre(0.55), M.Pierre, "Chapiteau")
		-- filet de lumière violette sur l'arête intérieure
		O.decor(O.bloc(f, Vector3.new(0.25, Y_ARC - 1, 0.25), L(s * (R_ARC - 2.3), Y_ARC / 2 + 0.5, A - 2.25), VIOLET, M.Neon, "Filet"))
	end

	-- Arche en voussoirs + clé de voûte + filet lumineux intérieur
	local N = 11
	for k = 0, N - 1 do
		local a = (k + 0.5) / N * math.pi
		local p = Vector3.new(math.cos(a) * R_ARC, Y_ARC + math.sin(a) * R_ARC, A)
		local longueur = math.pi * R_ARC / N * 1.06
		if k ~= (N - 1) / 2 then
			O.bloc(f, Vector3.new(4.2, longueur, 4.2), L(p.X, p.Y, p.Z) * CFrame.Angles(0, 0, a), pierre(rng:NextNumber(0.05, 0.5)), M.Ardoise, "Voussoir")
		end
		local q = Vector3.new(math.cos(a) * (R_ARC - 2.3), Y_ARC + math.sin(a) * (R_ARC - 2.3), A - 2.25)
		O.decor(O.bloc(f, Vector3.new(0.25, math.pi * (R_ARC - 2.3) / N * 1.08, 0.25), L(q.X, q.Y, q.Z) * CFrame.Angles(0, 0, a), VIOLET, M.Neon, "Filet"))
	end
	local Y_CLE = Y_ARC + R_ARC
	O.bloc(f, Vector3.new(4, 5, 5), L(0, Y_CLE + 0.3, A), pierre(0.6), M.Pierre, "CleDeVoute")
	local gemme = O.decor(O.bloc(f, Vector3.new(1.6, 1.6, 0.6), L(0, Y_CLE + 0.3, A - 2.6) * CFrame.Angles(0, 0, math.rad(45)), VIOLET, M.Neon, "GemmeCle"))
	O.lumiere(gemme, VIOLET, 2, 22)
	-- Bandeau gravé au-dessus de la clé
	local bandeau = O.bloc(f, Vector3.new(17, 3.4, 1.2), L(0, Y_CLE + 4.4, A - 1.4), pierre(0.35), M.Ardoise, "Bandeau")
	O.texte(bandeau, Enum.NormalId.Front, "GROTTES PROFONDES", {lumiere = 0, couleur = Color3.fromRGB(255, 214, 120), ppp = 50})
	for _, s in {-1, 1} do
		O.coin(f, Vector3.new(1.2, 3.4, 2.2), L(s * 9.1, Y_CLE + 4.4, A - 1.4) * CFrame.Angles(0, s * math.pi / 2, 0), pierre(0.35), M.Ardoise, "Volute")
	end

	-- Le vide : rectangle + disque noirs, voile violet, brume et étincelles qui montent des profondeurs
	local largeur = (R_ARC - 2) * 2
	O.decor(O.bloc(f, Vector3.new(largeur, Y_ARC, 0.4), L(0, Y_ARC / 2 + 0.5, A + 1.2), Color3.fromRGB(4, 2, 8), M.Lisse, "Vide"))
	O.decor(O.disque(f, 0.4, largeur, L(0, Y_ARC, A + 1.2) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(4, 2, 8), M.Lisse, "VideHaut"))
	local voile = O.decor(O.bloc(f, Vector3.new(largeur - 0.5, Y_ARC + 4, 0.2), L(0, (Y_ARC + 4) / 2 + 0.5, A + 0.6), VIOLET, M.Neon, "Voile"))
	voile.Transparency = 0.93
	local fond = O.decor(O.bloc(f, Vector3.new(largeur - 1, 2, 2), L(0, 1.5, A), VIOLET, M.Lisse, "Profondeurs"))
	fond.Transparency = 1
	O.brume(fond, Color3.fromRGB(150, 70, 220), 5)
	O.etincelles(fond, VIOLET, 10)
	O.lucioles(fond, Color3.fromRGB(220, 170, 255), 6)
	O.lumiere(fond, VIOLET, 1.5, 22)

	-- Rails qui s'enfoncent dans le vide
	local z0, z1 = RAYON + 1, A + 1
	for _, x in {-1.6, 1.6} do
		O.decor(O.bloc(f, Vector3.new(0.25, 0.3, z1 - z0), L(x, 0.62 + 0.15, (z0 + z1) / 2), Color3.fromRGB(87, 68, 54), M.Rouille, "Rail"))
	end
	for z = z0, z1, 1.8 do
		O.decor(O.bloc(f, Vector3.new(4.2, 0.25, 0.8), L(0, 0.55, z), Color3.fromRGB(70, 47, 32), M.Planches, "Traverse"))
	end

	-- Lanternes suspendues sous l'arche et plaque « 1 à 2 mineurs » sur chaînes
	for _, x in {-4.2, 4.2} do
		B.suspension(f, L(x, Y_ARC + 5.2, A - 2.4).Position, 2.6, BRAISE, 16)
	end
	local plaque = O.decor(O.bloc(f, Vector3.new(6, 1.4, 0.25), L(0, Y_ARC + 2.2, A - 2.4), C.BoisFonce, M.Planches, "Plaque"))
	O.texte(plaque, Enum.NormalId.Front, "1 à 2 mineurs", {lumiere = 0})
	for _, x in {-2.4, 2.4} do
		O.decor(O.bloc(f, Vector3.new(0.15, Y_ARC + 6.2 - (Y_ARC + 2.9), 0.15), L(x, (Y_ARC + 6.2 + Y_ARC + 2.9) / 2, A - 2.4), C.Fer, M.Metal, "Chaine"))
	end

	-- 5 gemmes sur le pilier gauche : une par palier, du bleu (facile) au rouge (mortel)
	for i, niveau in Grottes.NIVEAUX do
		local y = 2.6 + (i - 1) * 2.7
		local socle = O.bloc(f, Vector3.new(1.6, 1.6, 0.4), L(-R_ARC, y, A - 2.3), pierre(0.7), M.Pierre, "Socle")
		local g = O.decor(O.bloc(f, Vector3.new(0.8, 0.8, 0.4), L(-R_ARC, y, A - 2.55) * CFrame.Angles(0, 0, math.rad(45)),
			Grottes.couleurDanger((i - 1) / (#Grottes.NIVEAUX - 1)), M.Neon, "GemmePalier"))
		local etiquette = O.decor(O.bloc(f, Vector3.new(2.4, 0.8, 0.1), L(-R_ARC - 2.1, y, A - 2.3), pierre(0.1), M.Ardoise, "Profondeur"))
		O.texte(etiquette, Enum.NormalId.Front, "−" .. niveau.profondeur .. " m", {lumiere = 0, couleur = g.Color})
		socle.Name = "Socle" .. i
	end
	-- Runes verticales sur le pilier droit
	for i = 0, 4 do
		O.decor(O.bloc(f, Vector3.new(0.9, 0.18, 0.1), L(R_ARC, 3 + i * 2.7, A - 2.25), VIOLET, M.Neon, "Rune"))
		O.decor(O.bloc(f, Vector3.new(0.18, 0.9, 0.1), L(R_ARC + (if i % 2 == 0 then 0.35 else -0.35), 3 + i * 2.7, A - 2.25), VIOLET, M.Neon, "Rune"))
	end

	-- Amas de cristaux autour du portail et sur l'arche
	for _, c in {{-12.5, 0, A - 1, 8, -0.25}, {12.5, 0, A - 1, 7, 0.25}, {-14.5, 0, A + 2, 4.5, -0.4}, {14, 0, A + 2.5, 5, 0.35}} do
		B.cristal(f, L(c[1], c[2], c[3]) * CFrame.Angles(0, rng:NextNumber(0, math.pi), c[5]), c[4], VIOLET, rng, 26)
	end
	for _, a in {0.22 * math.pi, 0.78 * math.pi} do
		local p = Vector3.new(math.cos(a) * (R_ARC + 2), Y_ARC + math.sin(a) * (R_ARC + 2), A)
		B.cristal(f, L(p.X, p.Y, p.Z) * CFrame.Angles(0, 0, a - math.pi / 2), 3.2, VIOLET, rng, 14)
	end

	-- Braseros de part et d'autre du cercle
	for _, s in {-1, 1} do
		local cf = L(s * (RAYON + 3.2), 0, 2)
		O.cylindre(f, 2.6, 1.5, cf * CFrame.new(0, 1.3, 0), pierre(0.3), M.Ardoise, "PiedBrasero")
		O.cylindre(f, 0.9, 2.8, cf * CFrame.new(0, 2.95, 0), C.Fer, M.Metal, "Brasero")
		local braises = O.decor(O.cylindre(f, 0.3, 2.2, cf * CFrame.new(0, 3.45, 0), BRAISE, M.Neon, "Braises"))
		O.feu(braises, 3.5)
		O.etincelles(braises, BRAISE, 5)
		O.lumiere(braises, BRAISE, 1.8, 18, true)
	end

	-- Wagonnet abandonné, renversé à moitié, et quelques pierres éboulées
	local wagon = B.wagonnet(f, L(-15, 0, -1) * CFrame.Angles(0, math.rad(70), 0) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(150, 80, 220), rng)
	wagon:ScaleTo(0.7)
	wagon:PivotTo(wagon:GetPivot() - Vector3.new(0, 3.1 * 0.3, 0))
	O.decorModele(wagon)
	for _ = 1, 9 do
		local cote = if rng:NextNumber() < 0.5 then -1 else 1
		local t = rng:NextNumber(0.8, 2)
		O.bloc(f, Vector3.new(t, t * 0.8, t), L(cote * rng:NextNumber(10, 16), t * 0.3, A + rng:NextNumber(-4, 3)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)),
			pierre(rng:NextNumber(0, 0.4)), M.Ardoise, "Eboulis")
	end

	cercle = Cercle.construire(f, base, "CercleGrotte", {rayon = RAYON, texte = "0/2"})
	centreCercle = cercle:GetAttribute("Centre")
	entree = f
end

-- Point de retour : devant le cercle, côté centre de la caverne, hors du cercle
local function arrivee(): CFrame
	local centre = Vector3.new(D.CAVERNE_CENTRE.X, centreCercle.Y, D.CAVERNE_CENTRE.Z)
	return CFrame.lookAt(centreCercle, centre) * CFrame.new(0, 0, -(RAYON + 5))
end

-- ================= Groupes (avant le départ) =================
-- groupe = {chef = Player, membres = {Player}, invites = {[userId] = expiration}, depart = bool}
local groupe = nil      -- un seul groupe au cercle à la fois (compteur 0/2)
local derniers = {}     -- [joueur] = os.clock() de la dernière activation
local expeditions = {}  -- [joueur] = expédition en cours
local occupes = {}      -- [index d'emplacement] = true

local function vivant(joueur: Player)
	local perso = joueur.Character
	local humain = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if humain and humain.Health > 0 and racine and racine:IsA("BasePart") then return perso, racine, humain end
	return nil
end

local function dedans(centre: Vector3, p: Vector3, rayon: number)
	local d = p - centre
	return d.Y > -1 and d.Y < 8 and d.X * d.X + d.Z * d.Z < rayon * rayon
end

local function compteur()
	if not cercle or not cercle.Parent then return end
	local n = if groupe then #groupe.membres else 0
	cercle:SetAttribute("Texte", n .. "/" .. Grottes.MAX_JOUEURS)
	Cercle.etat(cercle, n > 0)
end

local function etatGroupe(pour: Player)
	local membres = {}
	for _, j in groupe.membres do table.insert(membres, {userId = j.UserId, nom = j.DisplayName}) end
	local invites = {}
	for userId in groupe.invites do table.insert(invites, userId) end
	return {chef = groupe.chef.UserId, membres = membres, invites = invites, estChef = pour == groupe.chef}
end

local function diffuser()
	if not groupe then return end
	for _, j in groupe.membres do R.Ouvrir:FireClient(j, etatGroupe(j)) end
	compteur()
end

local function membre(j: Player): boolean
	return groupe ~= nil and table.find(groupe.membres, j) ~= nil
end

local function dissoudre(raison: string?)
	if not groupe then return end
	local g = groupe
	groupe = nil
	for _, j in g.membres do
		if j.Parent then
			R.Fermer:FireClient(j)
			if raison then R.Message:FireClient(j, raison) end
			derniers[j] = os.clock()
		end
	end
	compteur()
end

local function retirerDuGroupe(j: Player)
	if not groupe or groupe.depart then return end
	if j == groupe.chef then
		dissoudre(nil)
		return
	end
	local i = table.find(groupe.membres, j)
	if i then
		table.remove(groupe.membres, i)
		R.Fermer:FireClient(j)
		derniers[j] = os.clock()
		R.Message:FireClient(groupe.chef, j.DisplayName .. " a quitté le groupe")
		diffuser()
	end
end

-- ================= Expéditions =================
local function streamerPuisPoser(joueur: Player, cible: CFrame): boolean
	pcall(joueur.RequestStreamAroundAsync, joueur, cible.Position, FLUX_LIMITE)
	local perso, racine, humain = vivant(joueur)
	if not perso then return false end
	if humain.Sit then humain.Sit = false end
	local hauteur = if humain.RigType == Enum.HumanoidRigType.R6 then 3 else humain.HipHeight + racine.Size.Y / 2
	perso:PivotTo(cible + Vector3.new(0, hauteur + 0.1, 0))
	racine.AssemblyLinearVelocity = Vector3.zero
	return true
end

local function fermerExpedition(exp)
	if exp.fini then return end
	exp.fini = true
	pcall(MobsGrotte.nettoyer, exp.mobs)
	pcall(Generateur.detruire, exp.grotte)
	occupes[exp.index] = nil
end

-- Le joueur n'est plus dans la grotte (sortie, mort, départ) ; la grotte vide est détruite
local function quitterExpedition(joueur: Player)
	local exp = expeditions[joueur]
	if not exp then return end
	expeditions[joueur] = nil
	local i = table.find(exp.joueurs, joueur)
	if i then table.remove(exp.joueurs, i) end
	pcall(MobsGrotte.retirerJoueur, exp.mobs, joueur)
	if #exp.joueurs == 0 then fermerExpedition(exp) end
end

local function sortir(joueur: Player, exp)
	exp.enSortie[joueur] = true
	Cercle.activer(exp.grotte.sortie)
	task.wait(0.35)
	local perso, racine = vivant(joueur)
	if perso and dedans(exp.grotte.centreSortie, racine.Position, Cercle.RAYON) and streamerPuisPoser(joueur, arrivee()) then
		acces.autoriser(joueur, perso) -- revenu dans la caverne sans le wagon : accès conservé
		quitterExpedition(joueur)
	end
	exp.enSortie[joueur] = nil
	derniers[joueur] = os.clock()
end

local function lancer(niveau)
	local g = groupe
	if not g or g.depart then return end
	g.depart = true
	local index = 1
	while occupes[index] do index += 1 end
	occupes[index] = true
	local invite = g.membres[2]
	local ok, grotte = pcall(Generateur.construire, niveau, index, os.time() * 7919 + math.random(1, 1e6), g.chef.UserId, invite and invite.UserId)
	if not ok then
		occupes[index] = nil
		warn("[Grottes] Génération ratée : " .. tostring(grotte))
		g.depart = false
		dissoudre("La grotte s'est effondrée… réessaie !")
		return
	end
	local exp = {grotte = grotte, niveau = niveau, index = index, joueurs = {}, enSortie = {}, fini = false}
	local partants = {}
	for _, j in g.membres do
		if j.Parent and vivant(j) and not expeditions[j] then table.insert(partants, j) end
	end
	local okMobs, mobs = pcall(MobsGrotte.peupler, grotte, niveau, partants)
	if okMobs then exp.mobs = mobs else warn("[Grottes] Mobs : " .. tostring(mobs)) end
	-- Le cercle se libère tout de suite pour le groupe suivant
	groupe = nil
	compteur()
	Cercle.activer(cercle)
	for i, j in partants do
		R.Fermer:FireClient(j)
		expeditions[j] = exp
		table.insert(exp.joueurs, j)
		derniers[j] = os.clock()
		task.spawn(function()
			local cible = grotte.apparitions[i] or grotte.apparitions[1]
			if not streamerPuisPoser(j, cible) then quitterExpedition(j) end
		end)
	end
	if #exp.joueurs == 0 then fermerExpedition(exp) end
end

-- ================= Remotes : client → serveur =================
local recharges = {} -- anti-spam par joueur et par remote
local function limite(joueur: Player, nom: string, delai: number): boolean
	local cle = nom .. joueur.UserId
	local t = os.clock()
	if t - (recharges[cle] or -math.huge) < delai then return false end
	recharges[cle] = t
	return true
end

R.Choisir.OnServerEvent:Connect(function(joueur, niveauId)
	if not limite(joueur, "Choisir", 1) then return end
	if not groupe or groupe.chef ~= joueur or groupe.depart then return end
	local niveau = Grottes.niveau(niveauId)
	if not niveau then return end
	local _, racine = vivant(joueur)
	if not racine or not dedans(centreCercle, racine.Position, RAYON + 1) then return end
	lancer(niveau)
end)

R.Quitter.OnServerEvent:Connect(function(joueur)
	if membre(joueur) then retirerDuGroupe(joueur) end
end)

R.Inviter.OnServerEvent:Connect(function(joueur, userId)
	if not limite(joueur, "Inviter", 0.5) then return end
	if not groupe or groupe.chef ~= joueur or groupe.depart or type(userId) ~= "number" then return end
	if #groupe.membres >= Grottes.MAX_JOUEURS then return end
	local cible = Players:GetPlayerByUserId(userId)
	if not cible or cible == joueur or membre(cible) then return end
	if expeditions[cible] then
		R.Message:FireClient(joueur, cible.DisplayName .. " est déjà dans une grotte")
		return
	end
	groupe.invites[userId] = os.clock() + INVITATION_DUREE
	R.Invitation:FireClient(cible, joueur.UserId, joueur.DisplayName)
	diffuser()
end)

R.Repondre.OnServerEvent:Connect(function(joueur, chefId, accepte)
	if not limite(joueur, "Repondre", 0.5) then return end
	if not groupe or groupe.depart or groupe.chef.UserId ~= chefId or not groupe.invites[joueur.UserId] then
		if accepte == true then R.Message:FireClient(joueur, "L'invitation n'est plus valable") end
		return
	end
	groupe.invites[joueur.UserId] = nil
	if accepte ~= true then
		R.Message:FireClient(groupe.chef, joueur.DisplayName .. " a refusé")
		diffuser()
		return
	end
	if #groupe.membres >= Grottes.MAX_JOUEURS or expeditions[joueur] or not vivant(joueur) then
		R.Message:FireClient(joueur, "Le groupe est complet")
		diffuser()
		return
	end
	table.insert(groupe.membres, joueur)
	R.Message:FireClient(groupe.chef, joueur.DisplayName .. " rejoint l'expédition !")
	diffuser()
end)

-- ================= Joueurs =================
local function surJoueur(joueur: Player)
	task.spawn(function()
		Donnees.attendre(joueur)
		majStats(joueur)
	end)
	joueur.CharacterAdded:Connect(function()
		-- réapparition (mort) : il n'est plus dans la grotte ni dans le groupe
		quitterExpedition(joueur)
		if membre(joueur) then retirerDuGroupe(joueur) end
	end)
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do surJoueur(j) end

Players.PlayerRemoving:Connect(function(joueur)
	if membre(joueur) then
		if groupe.depart then
			table.remove(groupe.membres, table.find(groupe.membres, joueur))
		else
			retirerDuGroupe(joueur)
		end
	end
	if groupe then groupe.invites[joueur.UserId] = nil end
	quitterExpedition(joueur)
	derniers[joueur] = nil
	for cle in recharges do
		if string.find(cle, tostring(joueur.UserId) .. "$") then recharges[cle] = nil end
	end
end)

-- ================= Boucle de détection =================
local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do task.wait(0.25) end
local ok, erreur = pcall(construireEntree)
if not ok then
	warn("[Grottes] Entrée non construite : " .. tostring(erreur))
	return
end

local function examiner(joueur: Player, maintenant: number)
	local _, racine = vivant(joueur)
	if not racine then return end
	local p = racine.Position
	local exp = expeditions[joueur]
	if exp then
		local grotte = exp.grotte
		if exp.enSortie[joueur] then return end
		if grotte.sortie and grotte.sortie.Parent and dedans(grotte.centreSortie, p, Cercle.RAYON)
			and maintenant - (derniers[joueur] or -math.huge) > RECHARGE then
			task.spawn(sortir, joueur, exp)
		elseif (p - grotte.centre).Magnitude > grotte.rayon + 80 and maintenant - (derniers[joueur] or -math.huge) > 8 then
			quitterExpedition(joueur) -- téléporté ailleurs (autre système) : il a quitté la grotte
		end
		return
	end
	local dansCercle = dedans(centreCercle, p, RAYON)
	if groupe and not groupe.depart then
		if joueur == groupe.chef and not dansCercle then
			dissoudre(nil) -- le chef sort du cercle : on annule
		elseif not membre(joueur) and dansCercle and #groupe.membres < Grottes.MAX_JOUEURS
			and maintenant - (derniers[joueur] or -math.huge) > RECHARGE then
			table.insert(groupe.membres, joueur)
			groupe.invites[joueur.UserId] = nil
			diffuser()
		end
	elseif not groupe and dansCercle and maintenant - (derniers[joueur] or -math.huge) > RECHARGE then
		groupe = {chef = joueur, membres = {joueur}, invites = {}, depart = false}
		Cercle.activer(cercle)
		diffuser()
	end
end

while true do
	local maintenant = os.clock()
	if groupe and not groupe.depart then
		-- invitations expirées
		local change = false
		for userId, fin in groupe.invites do
			if maintenant > fin then groupe.invites[userId] = nil; change = true end
		end
		if change then diffuser() end
	end
	if not entree.Parent then pcall(construireEntree) end
	for _, joueur in Players:GetPlayers() do
		local okJ, err = pcall(examiner, joueur, maintenant)
		if not okJ then warn("[Grottes] Détection interrompue pour " .. joueur.Name .. " : " .. tostring(err)) end
	end
	task.wait(PAS)
end
