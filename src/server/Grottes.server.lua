-- Grottes profondes · SCRIPT SERVEUR
-- Deux grands cercles indépendants (un groupe de 1 à 2 joueurs chacun) devant l'entrée de la caverne.
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
local Sanctuaire = require(script.Parent:WaitForChild("Sanctuaire")) -- palier 1 : arche, gardiens, coffre (+ fragments de carte)
local EvenementsGrotte = require(script.Parent:WaitForChild("EvenementsGrotte")) -- palier 1 : événements aléatoires
local ArenaTemple = require(script.Parent:WaitForChild("ArenaTemple")) -- palier 1 : arène du temple (gong)
local TroneLave = require(script.Parent:WaitForChild("TroneLave")) -- palier 4 : trône de magma, le Roi déchu
local BossProfondeurs = require(script.Parent:WaitForChild("BossProfondeurs")) -- paliers 7 et 8 : Léviathan, Gardien des astres

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
local ANCRAGE_ARRIVEE = 1.2 -- s : joueur figé à l'arrivée dans la grotte, le temps que le sol se charge
local INVITATION_DUREE = 25
local RAYON = Grottes.RAYON_CERCLE * 1.15 -- grands cercles (halo animé : HalosGrottes.client)
-- Dans la grande salle, entre le Tunnel VI et le pilier est de la passerelle.
local ENTREE = Vector3.new(50, D.CAVERNE_SOL + 2, -416)
local ECART_CERCLES = 2 * RAYON + 3.5
local AVANCE_CERCLES_LATERAUX = 2.5

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
-- cristaux, braseros, lanternes suspendues, éboulis et une gemme par palier sur le pilier.
local PIERRE = Color3.fromRGB(58, 53, 64)
local PIERRE_CLAIRE = Color3.fromRGB(88, 82, 96)
local VIOLET = Color3.fromRGB(186, 96, 255)
local BRAISE = Color3.fromRGB(255, 150, 70)

local entree
local teleporteurs = { {}, {} }

local function construireEntree()
	local f = workspace:FindFirstChild("EntreeGrottes")
	if f then f:Destroy() end
	f = O.modele(workspace, "EntreeGrottes")
	local rng = Random.new(4242)
	local base = CFrame.lookAt(ENTREE, ENTREE - Vector3.xAxis)
	local function L(x, y, z) return base * CFrame.new(x, y, z) end
	local function pierre(k) return PIERRE:Lerp(PIERRE_CLAIRE, k) end
	local ecartLateral = math.sqrt(ECART_CERCLES ^ 2 - AVANCE_CERCLES_LATERAUX ^ 2)
	local function cadreCercle(i)
		local cote = i - (#teleporteurs + 1) / 2
		return L(cote * ecartLateral, 0, -2.5 + math.abs(cote) * AVANCE_CERCLES_LATERAUX)
	end

	-- Raccord rocheux derrière le portail, prolongé côté passerelle jusqu'à la paroi naturelle.
	local terrain = workspace.Terrain
	terrain:FillBlock(L(0, 16, 34), Vector3.new(32, 40, 32), Enum.Material.Rock)
	terrain:FillBlock(L(-16, 14, 39), Vector3.new(12, 36, 26), Enum.Material.Rock)

	-- Une seule dalle porte jusqu'au bord visible. Le dessous pénètre le terrain irrégulier.
	local A = 12.875 -- plan de l'arche, indépendant de la taille des anneaux
	local dessusDalle = 0.4
	local epaisseurDalle = 0.85
	local debutMarches = A - 4.9
	local largeurDalle = 2 * (ecartLateral * (#teleporteurs - 1) / 2 + RAYON + 1.5)
	O.bloc(f, Vector3.new(largeurDalle, epaisseurDalle, 21), L(0, dessusDalle - epaisseurDalle / 2, debutMarches - 10.5),
		pierre(0.2), M.Ardoise, "Dalle")
	for i = 1, #teleporteurs do
		local cadre = cadreCercle(i)
		for k = 0, 7 do
			local a = (k + 0.5) * math.pi / 4
			local x, z = math.cos(a) * (RAYON + 1.1), math.sin(a) * (RAYON + 1.1)
			O.decor(O.bloc(f, Vector3.new(0.5, 0.06, 1.6), cadre * CFrame.new(x, dessusDalle + 0.045, z)
				* CFrame.Angles(0, -a, 0), VIOLET, M.Neon, "RuneDalle"))
		end
	end
	local debutSeuil = A - 1.7
	local profondeurMarche = (debutSeuil - debutMarches) / 3
	local dessusSeuil = 1.5
	local dessousMarches = -0.5

	-- Les marches rejoignent la dalle sur l'axe du portail.
	local function palier(nom, debut, fin, dessus, nuance)
		local z = (debut + fin) / 2
		O.bloc(f, Vector3.new(14, dessus - dessousMarches, fin - debut), L(0, (dessus + dessousMarches) / 2, z), pierre(nuance), M.Ardoise, nom)
		-- Bois et rails décoratifs suivent la hauteur de chaque marche et du seuil.
		local finRail = math.min(fin, A + 1)
		local zRail = (debut + finRail) / 2
		O.decor(O.bloc(f, Vector3.new(4.2, 0.1, 0.65), L(0, dessus + 0.06, zRail), C.BoisFonce, M.Planches, "Traverse"))
		for _, x in {-1.6, 1.6} do
			O.decor(O.bloc(f, Vector3.new(0.25, 0.14, finRail - debut - 0.08), L(x, dessus + 0.18, zRail), Color3.fromRGB(87, 68, 54), M.Rouille, "Rail"))
		end
	end
	for k = 1, 3 do
		local debut = debutMarches + (k - 1) * profondeurMarche
		local fin = if k == 3 then debutSeuil else debut + profondeurMarche
		palier("Marche" .. k, debut, fin, dessusDalle + (dessusSeuil - dessusDalle) * k / 4, 0.2 + k * 0.1)
	end
	palier("Seuil", debutSeuil, A + 1.7, dessusSeuil, 0.2)

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

	-- Lanternes suspendues sous l'arche et plaque « 1 à 2 mineurs » sur chaînes
	for _, x in {-4.2, 4.2} do
		B.suspension(f, L(x, Y_ARC + 5.2, A - 2.4).Position, 2.6, BRAISE, 16)
	end
	local plaque = O.decor(O.bloc(f, Vector3.new(6, 1.4, 0.25), L(0, Y_ARC + 2.2, A - 2.4), C.BoisFonce, M.Planches, "Plaque"))
	O.texte(plaque, Enum.NormalId.Front, "1 à 2 mineurs", {lumiere = 0})
	for _, x in {-2.4, 2.4} do
		O.decor(O.bloc(f, Vector3.new(0.15, Y_ARC + 6.2 - (Y_ARC + 2.9), 0.15), L(x, (Y_ARC + 6.2 + Y_ARC + 2.9) / 2, A - 2.4), C.Fer, M.Metal, "Chaine"))
	end

	-- Une gemme par palier sur le pilier gauche, du bleu (facile) au rouge (mortel) ; resserrées au-delà de 5 paliers
	local pasGemmes = math.min(2.7, 10.8 / math.max(#Grottes.NIVEAUX - 1, 1))
	local tailleSocle = math.min(1.6, pasGemmes - 0.12)
	for i, niveau in Grottes.NIVEAUX do
		local y = 2.6 + (i - 1) * pasGemmes
		local socle = O.bloc(f, Vector3.new(tailleSocle, tailleSocle, 0.4), L(-R_ARC, y, A - 2.3), pierre(0.7), M.Pierre, "Socle")
		local g = O.decor(O.bloc(f, Vector3.new(tailleSocle / 2, tailleSocle / 2, 0.4), L(-R_ARC, y, A - 2.55) * CFrame.Angles(0, 0, math.rad(45)),
			Grottes.couleurDanger((i - 1) / (#Grottes.NIVEAUX - 1)), M.Neon, "GemmePalier"))
		local etiquette = O.decor(O.bloc(f, Vector3.new(2.4, math.min(0.8, pasGemmes - 0.2), 0.1), L(-R_ARC - 2.1, y, A - 2.3), pierre(0.1), M.Ardoise, "Profondeur"))
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

	-- Braseros de part et d'autre du seuil
	for _, s in {-1, 1} do
		local cf = L(s * (A - 2.8), 0, 9)
		O.cylindre(f, 2.6, 1.5, cf * CFrame.new(0, 1.3, 0), pierre(0.3), M.Ardoise, "PiedBrasero")
		O.cylindre(f, 0.9, 2.8, cf * CFrame.new(0, 2.95, 0), C.Fer, M.Metal, "Brasero")
		local braises = O.decor(O.cylindre(f, 0.3, 2.2, cf * CFrame.new(0, 3.45, 0), BRAISE, M.Neon, "Braises"))
		O.feu(braises, 3.5)
		O.etincelles(braises, BRAISE, 5)
		O.lumiere(braises, BRAISE, 1.8, 18, true)
	end

	-- Quelques pierres éboulées
	-- (le wagonnet de minerai violet, qui cachait le bassin et le coin pêche, est retiré ; même tirage pour les éboulis)
	for _ = 1, 15 do rng:NextNumber() end
	local filtreSol = RaycastParams.new()
	filtreSol.FilterType = Enum.RaycastFilterType.Include
	filtreSol.FilterDescendantsInstances = {workspace.Terrain}
	filtreSol.IgnoreWater = true
	for _ = 1, 9 do
		local cote = if rng:NextNumber() < 0.5 then -1 else 1
		local t = rng:NextNumber(0.8, 2)
		local pos = L(cote * rng:NextNumber(10, 16), 0, A + rng:NextNumber(-4, 3)).Position
		-- posé sur le sol réel (terrain), pas à une hauteur fixe
		local sol = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -16, 0), filtreSol)
		local y = if sol then sol.Position.Y else pos.Y - 2
		O.bloc(f, Vector3.new(t, t * 0.8, t), CFrame.new(pos.X, y + t * 0.3, pos.Z) * base.Rotation * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)),
			pierre(rng:NextNumber(0, 0.4)), M.Ardoise, "Eboulis")
	end

	for i, teleporteur in teleporteurs do
		local cf = cadreCercle(i)
		teleporteur.cercle = Cercle.construire(f, cf, "Teleporteur_Grottes_" .. i, {rayon = RAYON, texte = "0/2", grand = true, segments = 64})
		O.tag(teleporteur.cercle, "CercleGrotte")
		local centre = teleporteur.cercle:GetAttribute("Centre")
		teleporteur.centre = centre
		teleporteur.retour = (cf.Rotation + centre) * CFrame.new(0, 0, -(RAYON + 3))
	end
	entree = f
end

-- ================= Groupes (avant le départ) =================
local groupesJoueurs = {} -- [joueur] = téléporteur, y compris pour un membre invité hors du cercle
local derniers = {}     -- [joueur] = os.clock() de la dernière activation
local expeditions = {}  -- [joueur] = expédition en cours
local occupes = {}      -- [index d'emplacement] = true
local construction = false -- verrou : une grotte générée à la fois

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

local function compteur(teleporteur)
	local cercle, groupe = teleporteur.cercle, teleporteur.groupe
	if not cercle or not cercle.Parent then return end
	local n = if groupe then #groupe.membres else 0
	cercle:SetAttribute("Texte", n .. "/" .. Grottes.MAX_JOUEURS)
	Cercle.etat(cercle, n > 0)
end

local function etatGroupe(groupe, pour: Player)
	local membres = {}
	for _, j in groupe.membres do table.insert(membres, {userId = j.UserId, nom = j.DisplayName}) end
	local invites = {}
	for userId in groupe.invites do table.insert(invites, userId) end
	return {chef = groupe.chef.UserId, membres = membres, invites = invites, estChef = pour == groupe.chef}
end

local function diffuser(teleporteur)
	local groupe = teleporteur.groupe
	for _, j in groupe.membres do R.Ouvrir:FireClient(j, etatGroupe(groupe, j)) end
	compteur(teleporteur)
end

local function libererGroupe(teleporteur)
	local groupe = teleporteur.groupe
	teleporteur.groupe = nil
	for _, j in groupe.membres do groupesJoueurs[j] = nil end
	compteur(teleporteur)
	return groupe
end

local function dissoudre(teleporteur, raison: string?)
	local g = libererGroupe(teleporteur)
	for _, j in g.membres do
		if j.Parent then
			R.Fermer:FireClient(j)
			if raison then R.Message:FireClient(j, raison) end
			derniers[j] = os.clock()
		end
	end
end

local function retirerDuGroupe(j: Player)
	local teleporteur = groupesJoueurs[j]
	if not teleporteur then return end
	local groupe = teleporteur.groupe
	if j == groupe.chef and not groupe.depart then
		dissoudre(teleporteur, nil)
		return
	end
	groupesJoueurs[j] = nil
	table.remove(groupe.membres, table.find(groupe.membres, j))
	if j.Parent == Players then
		R.Fermer:FireClient(j)
		derniers[j] = os.clock()
	end
	if not groupe.depart and groupe.chef.Parent == Players then
		R.Message:FireClient(groupe.chef, j.DisplayName .. " a quitté le groupe")
	end
	if groupe.depart then compteur(teleporteur) else diffuser(teleporteur) end
end

local function rejoindre(teleporteur, joueur: Player)
	local groupe = teleporteur.groupe
	groupesJoueurs[joueur] = teleporteur
	table.insert(groupe.membres, joueur)
	groupe.invites[joueur.UserId] = nil
	diffuser(teleporteur)
end

-- ================= Expéditions =================
local function streamerPuisPoser(joueur: Player, cible: CFrame): boolean
	pcall(joueur.RequestStreamAroundAsync, joueur, cible.Position, FLUX_LIMITE)
	local perso, racine, humain = vivant(joueur)
	if not perso then return false end
	if humain.Sit then humain.Sit = false end
	local hauteur = if humain.RigType == Enum.HumanoidRigType.R6 then 3 else humain.HipHeight + racine.Size.Y / 2
	-- ancré le temps que le sol de la grotte arrive chez le joueur (sinon il traverse un sol pas encore chargé)
	racine.Anchored = true
	perso:PivotTo(cible + Vector3.new(0, hauteur + 0.1, 0))
	racine.AssemblyLinearVelocity = Vector3.zero
	task.delay(ANCRAGE_ARRIVEE, function()
		if racine.Parent then
			racine.Anchored = false
			racine.AssemblyLinearVelocity = Vector3.zero
		end
	end)
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
	joueur:SetAttribute("GrotteDepart", nil) -- écran de chargement (ChargementGrotte.client.lua)
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
	if perso and dedans(exp.grotte.centreSortie, racine.Position, Cercle.RAYON)
		and streamerPuisPoser(joueur, exp.teleporteur.retour) then
		acces.autoriser(joueur, perso) -- revenu dans la caverne sans le wagon : accès conservé
		local quete = ServerStorage:FindFirstChild("QueteEvenement")
		if quete and quete:IsA("BindableEvent") then
			quete:Fire("sortie", joueur, tostring(exp.niveau.profondeur))
		end
		quitterExpedition(joueur)
	end
	exp.enSortie[joueur] = nil
	derniers[joueur] = os.clock()
end

local function lancer(teleporteur, niveau)
	local g = teleporteur.groupe
	g.depart = true
	-- Une seule génération à la fois (creusement lourd, étalé sur plusieurs frames)
	while construction do task.wait(0.2) end
	if groupesJoueurs[g.chef] ~= teleporteur or not vivant(g.chef) then
		dissoudre(teleporteur, "Le chef a quitté l'expédition")
		return
	end
	construction = true
	local index = 1
	while occupes[index] do index += 1 end
	occupes[index] = true
	local invite = g.membres[2]
	local ok, grotte = pcall(Generateur.construire, niveau, index, os.time() * 7919 + math.random(1, 1e6), g.chef.UserId, invite and invite.UserId)
	construction = false
	if not ok then
		pcall(Generateur.detruire, {base = Generateur.emplacement(index)}) -- remet à l'air la roche déjà posée
		occupes[index] = nil
		warn("[Grottes] Génération ratée : " .. tostring(grotte))
		dissoudre(teleporteur, "La grotte s'est effondrée… réessaie !")
		return
	end
	local exp = {grotte = grotte, niveau = niveau, index = index, teleporteur = teleporteur, joueurs = {}, enSortie = {}, fini = false}
	if groupesJoueurs[g.chef] ~= teleporteur or not vivant(g.chef) then
		fermerExpedition(exp)
		dissoudre(teleporteur, "Le chef a quitté l'expédition")
		return
	end
	local partants = {}
	for _, j in g.membres do
		if j.Parent and vivant(j) and not expeditions[j] then table.insert(partants, j) end
	end
	local okMobs, mobs = pcall(MobsGrotte.peupler, grotte, niveau, partants)
	if okMobs then exp.mobs = mobs else warn("[Grottes] Mobs : " .. tostring(mobs)) end
	local okSanctuaire, errSanctuaire = pcall(Sanctuaire.preparer, exp)
	if not okSanctuaire then warn("[Grottes] Sanctuaire : " .. tostring(errSanctuaire)) end
	local okEvenements, errEvenements = pcall(EvenementsGrotte.lancer, exp)
	if not okEvenements then warn("[Grottes] Événements : " .. tostring(errEvenements)) end
	local okArene, errArene = pcall(ArenaTemple.preparer, exp)
	if not okArene then warn("[Grottes] Arène : " .. tostring(errArene)) end
	local okTrone, errTrone = pcall(TroneLave.preparer, exp)
	if not okTrone then warn("[Grottes] Trône : " .. tostring(errTrone)) end
	local okBoss, errBoss = pcall(BossProfondeurs.preparer, exp)
	if not okBoss then warn("[Grottes] Boss des profondeurs : " .. tostring(errBoss)) end
	-- Le cercle se libère tout de suite pour le groupe suivant
	libererGroupe(teleporteur)
	Cercle.activer(teleporteur.cercle)
	for i, j in partants do
		if not table.find(g.membres, j) or not vivant(j) or j.Parent ~= Players then continue end
		R.Fermer:FireClient(j)
		expeditions[j] = exp
		table.insert(exp.joueurs, j)
		derniers[j] = os.clock()
		j:SetAttribute("GrotteDepart", niveau.id) -- le client affiche l'écran de chargement de ce palier
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
	local teleporteur = groupesJoueurs[joueur]
	local groupe = teleporteur and teleporteur.groupe
	if not groupe or groupe.chef ~= joueur or groupe.depart then return end
	local niveau = Grottes.niveau(niveauId)
	if not niveau then return end
	local _, racine = vivant(joueur)
	if not racine or not dedans(teleporteur.centre, racine.Position, RAYON + 1) then return end
	lancer(teleporteur, niveau)
end)

R.Quitter.OnServerEvent:Connect(function(joueur)
	local teleporteur = groupesJoueurs[joueur]
	if teleporteur and not teleporteur.groupe.depart then retirerDuGroupe(joueur) end
end)

R.Inviter.OnServerEvent:Connect(function(joueur, userId)
	if not limite(joueur, "Inviter", 0.5) then return end
	local teleporteur = groupesJoueurs[joueur]
	local groupe = teleporteur and teleporteur.groupe
	if not groupe or groupe.chef ~= joueur or groupe.depart or type(userId) ~= "number" then return end
	if #groupe.membres >= Grottes.MAX_JOUEURS then return end
	local cible = Players:GetPlayerByUserId(userId)
	if not cible or cible == joueur then return end
	if groupesJoueurs[cible] then
		if groupesJoueurs[cible] ~= teleporteur then
			R.Message:FireClient(joueur, cible.DisplayName .. " a déjà une équipe")
		end
		return
	end
	if expeditions[cible] then
		R.Message:FireClient(joueur, cible.DisplayName .. " est déjà dans une grotte")
		return
	end
	groupe.invites[userId] = os.clock() + INVITATION_DUREE
	R.Invitation:FireClient(cible, joueur.UserId, joueur.DisplayName)
	diffuser(teleporteur)
end)

R.Repondre.OnServerEvent:Connect(function(joueur, chefId, accepte)
	if not limite(joueur, "Repondre", 0.5) then return end
	local chef = if type(chefId) == "number" then Players:GetPlayerByUserId(chefId) else nil
	local teleporteur = chef and groupesJoueurs[chef]
	local groupe = teleporteur and teleporteur.groupe
	local expiration = groupe and groupe.invites[joueur.UserId]
	if not groupe or groupe.depart or groupe.chef ~= chef or not expiration or expiration <= os.clock() then
		if accepte == true then R.Message:FireClient(joueur, "L'invitation n'est plus valable") end
		return
	end
	groupe.invites[joueur.UserId] = nil
	if accepte ~= true then
		R.Message:FireClient(groupe.chef, joueur.DisplayName .. " a refusé")
		diffuser(teleporteur)
		return
	end
	if #groupe.membres >= Grottes.MAX_JOUEURS or groupesJoueurs[joueur] or expeditions[joueur] or not vivant(joueur) then
		R.Message:FireClient(joueur, "Ce groupe n'est plus disponible")
		diffuser(teleporteur)
		return
	end
	rejoindre(teleporteur, joueur)
	R.Message:FireClient(groupe.chef, joueur.DisplayName .. " rejoint l'expédition !")
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
		retirerDuGroupe(joueur)
	end)
end
Players.PlayerAdded:Connect(surJoueur)
for _, j in Players:GetPlayers() do surJoueur(j) end

Players.PlayerRemoving:Connect(function(joueur)
	retirerDuGroupe(joueur)
	for _, teleporteur in teleporteurs do
		local groupe = teleporteur.groupe
		if groupe and groupe.invites[joueur.UserId] then
			groupe.invites[joueur.UserId] = nil
			if not groupe.depart then diffuser(teleporteur) end
		end
	end
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
		-- filet de sécurité : tombé sous la grotte (hors de la carte) → ramené à l'arrivée, sans dégâts
		local modele = grotte.modele
		local centre, demi = modele and modele:GetAttribute("Centre"), modele and modele:GetAttribute("DemiTaille")
		if typeof(centre) == "Vector3" and typeof(demi) == "Vector3" and p.Y < centre.Y - demi.Y - 10
			and grotte.apparitions and grotte.apparitions[1] then
			racine.AssemblyLinearVelocity = Vector3.zero
			task.spawn(streamerPuisPoser, joueur, grotte.apparitions[1])
			return
		end
		if grotte.sortie and grotte.sortie.Parent and dedans(grotte.centreSortie, p, Cercle.RAYON)
			and maintenant - (derniers[joueur] or -math.huge) > RECHARGE then
			task.spawn(sortir, joueur, exp)
		elseif (p - grotte.centre).Magnitude > grotte.rayon + 80 and maintenant - (derniers[joueur] or -math.huge) > 8 then
			quitterExpedition(joueur) -- téléporté ailleurs (autre système) : il a quitté la grotte
		end
		return
	end
	local actuel = groupesJoueurs[joueur]
	if actuel then
		local groupe = actuel.groupe
		if not groupe.depart and joueur == groupe.chef and not dedans(actuel.centre, p, RAYON) then
			dissoudre(actuel, nil)
		end
		return
	end
	if maintenant - (derniers[joueur] or -math.huge) <= RECHARGE then return end
	for _, teleporteur in teleporteurs do
		if not dedans(teleporteur.centre, p, RAYON) then continue end
		local groupe = teleporteur.groupe
		if not groupe then
			teleporteur.groupe = {chef = joueur, membres = {}, invites = {}, depart = false}
			Cercle.activer(teleporteur.cercle)
			rejoindre(teleporteur, joueur)
		elseif not groupe.depart and #groupe.membres < Grottes.MAX_JOUEURS then
			rejoindre(teleporteur, joueur)
		end
		return
	end
end

while true do
	local maintenant = os.clock()
	for _, teleporteur in teleporteurs do
		local groupe = teleporteur.groupe
		if not groupe or groupe.depart then continue end
		-- invitations expirées
		local change = false
		for userId, fin in groupe.invites do
			if maintenant > fin then groupe.invites[userId] = nil; change = true end
		end
		if change then diffuser(teleporteur) end
	end
	if not entree.Parent then
		if pcall(construireEntree) then
			for _, teleporteur in teleporteurs do compteur(teleporteur) end
		end
	end
	for _, joueur in Players:GetPlayers() do
		local okJ, err = pcall(examiner, joueur, maintenant)
		if not okJ then warn("[Grottes] Détection interrompue pour " .. joueur.Name .. " : " .. tostring(err)) end
	end
	task.wait(PAS)
end
