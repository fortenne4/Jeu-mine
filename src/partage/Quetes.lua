--!strict
-- Guilde des Mineurs (ReplicatedStorage › Partage › Quetes) : catalogue des quêtes, rangs et contrats du jour.
-- Logique pure : le serveur (Quetes.server.lua) fait foi, le client s'en sert pour l'affichage.
--
-- Types d'objectifs :
--   miner   : casser des minerais (cible = id du minerai, ou nil pour n'importe lequel)
--   livrer  : avoir N minerais dans le sac ; ils sont retirés quand on rend la quête
--   forger  : forger des objets chez Brom (cible = type d'objet, ou nil)
--   pioche  : posséder une pioche (cible = id de Pioches.lua)
--   wagon   : faire des trajets en wagonnet (aller ou retour)
--   equiper : porter un objet du type indiqué dans le sac
--   pecher  : total des prises déjà inscrites au carnet
--   sortie  : rentrer vivant par la sortie de la grotte à la profondeur indiquée
--
-- Équilibrage : un minerai rapporte en moyenne ~3 pièces (Charbon 1, Bronze 3, Fer 8, Or 25 ;
-- chances 60/25/12/3 %). Les récompenses valent environ la moitié de ce que le joueur gagne déjà
-- pendant la quête : un vrai bonus, sans rendre le minage inutile.

export type Objectif = {type: string, cible: string?, n: number}
export type Recompense = {pieces: number, renommee: number}
export type Quete = {
	id: string,
	chapitre: number,
	pnj: string, -- attribut « Service » du nain qui donne la quête (portrait)
	titre: string,
	recit: string,
	fin: string, -- réplique quand on rend la quête
	objectifs: {Objectif},
	recompense: Recompense,
}
export type Rang = {nom: string, renommee: number, bonus: number, couleur: Color3}

local Q = {}

Q.PNJ = {
	Vente = {nom = "Gaspard", role = "Marchand de minerais", couleur = Color3.fromRGB(255, 196, 48)},
	Outils = {nom = "Liesel", role = "Fabricante d'outils", couleur = Color3.fromRGB(110, 190, 255)},
	Forge = {nom = "Brom", role = "Forgeron", couleur = Color3.fromRGB(255, 120, 36)},
	Taverne = {nom = "Margot", role = "Aubergiste · Guilde", couleur = Color3.fromRGB(196, 120, 255)},
}

Q.MINERAIS = {
	Charbon = {nom = "Charbon", pluriel = "charbons", couleur = Color3.fromRGB(150, 150, 160), valeur = 1, chance = 0.60},
	Bronze = {nom = "Bronze", pluriel = "bronzes", couleur = Color3.fromRGB(230, 130, 60), valeur = 3, chance = 0.25},
	Fer = {nom = "Fer", pluriel = "fers", couleur = Color3.fromRGB(150, 185, 255), valeur = 8, chance = 0.12},
	Gold = {nom = "Or", pluriel = "ors", couleur = Color3.fromRGB(255, 200, 60), valeur = 25, chance = 0.03},
}
Q.VALEUR_MOYENNE = 3.06 -- pièces par minerai cassé, toutes raretés confondues

-- Rangs : la renommée s'obtient en rendant des quêtes. Le bonus s'ajoute aux pièces gagnées en vendant chez Gaspard.
Q.RANGS = {
	{nom = "Apprenti", renommee = 0, bonus = 0, couleur = Color3.fromRGB(184, 160, 130)},
	{nom = "Piqueur", renommee = 100, bonus = 3, couleur = Color3.fromRGB(200, 120, 70)},
	{nom = "Compagnon", renommee = 300, bonus = 6, couleur = Color3.fromRGB(170, 180, 195)},
	{nom = "Contremaître", renommee = 700, bonus = 10, couleur = Color3.fromRGB(110, 190, 255)},
	{nom = "Maître mineur", renommee = 1500, bonus = 15, couleur = Color3.fromRGB(255, 200, 60)},
	{nom = "Seigneur des Profondeurs", renommee = 3000, bonus = 20, couleur = Color3.fromRGB(196, 120, 255)},
	{nom = "Légende de la Guilde", renommee = 6000, bonus = 25, couleur = Color3.fromRGB(255, 90, 90)},
} :: {Rang}

function Q.rang(renommee: number): (number, Rang, Rang?)
	local i = 1
	for k, r in Q.RANGS do
		if renommee >= r.renommee then
			i = k
		end
	end
	return i, Q.RANGS[i], Q.RANGS[i + 1]
end

Q.CHAPITRES = {
	"Premiers coups de pioche",
	"La rumeur des profondeurs",
	"La veine d'or",
	"Le cœur de la montagne",
}

-- ===== Histoire : « La Veine d'Étoile » (dans l'ordre) =====
Q.HISTOIRE = {
	-- Chapitre 1
	{id = "h1", chapitre = 1, pnj = "Taverne", titre = "Bienvenue à la Guilde",
		recit = "Alors c'est toi, le nouveau ? Ici, on juge un mineur à ses mains, pas à sa langue. Descends à la mine et rapporte-moi la preuve que tu sais tenir une pioche.",
		fin = "Pas mal pour un débutant ! Tiens, ta première paie de la Guilde.",
		objectifs = {{type = "miner", n = 10}}, recompense = {pieces = 40, renommee = 30}},
	{id = "h2", chapitre = 1, pnj = "Vente", titre = "Le registre de Gaspard",
		recit = "Mon registre a besoin de charbon, beaucoup de charbon. Les forges du royaume ont toujours faim, et moi j'ai toujours des clients.",
		fin = "Parfait, tout est noté. Une belle ligne de plus dans mon registre !",
		objectifs = {{type = "miner", cible = "Charbon", n = 15}}, recompense = {pieces = 60, renommee = 40}},
	{id = "h3", chapitre = 1, pnj = "Outils", titre = "Un outil digne de ce nom",
		recit = "Tu creuses encore avec ce bout de bois ? Par ma barbe... Passe à ma boutique et prends une vraie pioche de silex.",
		fin = "Ah, voilà qui est mieux ! Tu sentiras la différence dès le premier coup.",
		objectifs = {{type = "pioche", cible = "Pierre", n = 1}}, recompense = {pieces = 80, renommee = 50}},
	{id = "h4", chapitre = 1, pnj = "Forge", titre = "Le feu de la forge",
		recit = "Mon foyer s'éteint, gamin. Apporte-moi du charbon pour le nourrir, puis forge quelque chose sur mon enclume. N'importe quoi, je veux te voir frapper !",
		fin = "Hah ! Tu frappes comme un nain. Enfin presque.",
		objectifs = {{type = "livrer", cible = "Charbon", n = 10}, {type = "forger", n = 1}}, recompense = {pieces = 120, renommee = 60}},
	-- Chapitre 2
	{id = "h5", chapitre = 2, pnj = "Vente", titre = "Lueurs cuivrées",
		recit = "Des mineurs racontent avoir vu des lueurs orangées plus bas dans la caverne. Du bronze, sûrement. Ramène-m'en, que je vérifie ces racontars.",
		fin = "Du beau bronze, bien veiné. Les rumeurs disaient vrai... et ce n'est que le début.",
		objectifs = {{type = "miner", cible = "Bronze", n = 12}}, recompense = {pieces = 150, renommee = 80}},
	{id = "h6", chapitre = 2, pnj = "Taverne", titre = "Le dernier wagon",
		recit = "Le vieux Hamrik a pris le wagon il y a trois jours et il n'est jamais remonté. Fais quelques trajets, creuse là-dessous et ouvre l'œil.",
		fin = "Aucune trace de Hamrik... mais tu as trouvé sa vieille lanterne. Il est allé plus profond. Bien plus profond.",
		objectifs = {{type = "wagon", n = 2}, {type = "miner", n = 25}}, recompense = {pieces = 180, renommee = 80}},
	{id = "h7", chapitre = 2, pnj = "Outils", titre = "Fer et volonté",
		recit = "Si tu veux suivre la piste de Hamrik, il te faut une pioche qui ne pliera pas. Une pioche de fer, rien de moins.",
		fin = "Elle te va bien. Prends-en soin, et elle prendra soin de toi.",
		objectifs = {{type = "pioche", cible = "Fer", n = 1}}, recompense = {pieces = 200, renommee = 100}},
	{id = "h8", chapitre = 2, pnj = "Forge", titre = "Casque de mineur",
		recit = "Là où tu vas, les plafonds s'effondrent sans prévenir. Forge-toi un casque, et ne viens pas pleurer si tu l'as fait en charbon !",
		fin = "Solide. Ta tête te remerciera.",
		objectifs = {{type = "forger", cible = "Casque", n = 1}}, recompense = {pieces = 250, renommee = 100}},
	-- Chapitre 3
	{id = "h9", chapitre = 3, pnj = "Vente", titre = "Éclats de fer",
		recit = "Dans la lanterne de Hamrik, j'ai trouvé un éclat de fer gravé d'une étoile. La Veine d'Étoile... je croyais que c'était une légende. Rapporte du fer, je dois comparer.",
		fin = "Même grain, même éclat. La Veine existe, et Hamrik l'a trouvée !",
		objectifs = {{type = "miner", cible = "Fer", n = 20}}, recompense = {pieces = 400, renommee = 150}},
	{id = "h10", chapitre = 3, pnj = "Taverne", titre = "Provisions d'expédition",
		recit = "Une expédition, ça se prépare. La Guilde réclame du bronze et du fer pour étayer les galeries. Apporte tout ça à la taverne.",
		fin = "Les étais sont prêts. Toute la Guilde parle de toi, tu sais ?",
		objectifs = {{type = "livrer", cible = "Bronze", n = 30}, {type = "livrer", cible = "Fer", n = 10}}, recompense = {pieces = 600, renommee = 180}},
	{id = "h11", chapitre = 3, pnj = "Outils", titre = "Le souffle du volcan",
		recit = "La roche autour de la Veine est brûlante, dit la légende. Seule une pioche forgée dans la lave peut l'entamer. La Pioche du Volcan.",
		fin = "Sens cette chaleur... Même la montagne va trembler devant toi.",
		objectifs = {{type = "pioche", cible = "Volcan", n = 1}}, recompense = {pieces = 500, renommee = 200}},
	{id = "h12", chapitre = 3, pnj = "Forge", titre = "L'or des anciens",
		recit = "Les anciens nains scellaient leurs portes avec de l'or pur. Trouve-en, et confie-m'en un peu : je vais te forger une clé.",
		fin = "Voilà ta clé, gravée à l'ancienne. Que les ancêtres guident ta pioche.",
		objectifs = {{type = "miner", cible = "Gold", n = 6}, {type = "livrer", cible = "Gold", n = 4}}, recompense = {pieces = 1200, renommee = 250}},
	-- Chapitre 4
	{id = "h13", chapitre = 4, pnj = "Vente", titre = "La carte effacée",
		recit = "La carte de Hamrik est à moitié effacée. Il faut sonder la roche partout, sans relâche, pour retrouver le chemin. Creuse, et creuse encore !",
		fin = "Là ! Les galeries forment une étoile. Le cœur de la montagne est juste sous nos pieds.",
		objectifs = {{type = "miner", n = 150}}, recompense = {pieces = 1500, renommee = 300}},
	{id = "h14", chapitre = 4, pnj = "Outils", titre = "La pioche des cieux",
		recit = "Le cœur de la montagne est fait d'une pierre tombée des étoiles. Une seule pioche peut la briser : la Pioche Céleste.",
		fin = "Elle chante, tu l'entends ? Elle a reconnu son étoile.",
		objectifs = {{type = "pioche", cible = "Celeste", n = 1}}, recompense = {pieces = 1500, renommee = 350}},
	{id = "h15", chapitre = 4, pnj = "Forge", titre = "Armure des profondeurs",
		recit = "Tu ne descendras pas là-dessous en chemise. Forge-toi une armure digne d'un héros, et apporte de l'or pour la renforcer.",
		fin = "Une armure de légende pour une future légende. Va, maintenant.",
		objectifs = {{type = "forger", n = 3}, {type = "livrer", cible = "Gold", n = 10}}, recompense = {pieces = 3000, renommee = 400}},
	{id = "h16", chapitre = 4, pnj = "Taverne", titre = "La Veine d'Étoile",
		recit = "C'est le moment. Descends au cœur de la montagne et rapporte l'or de la Veine d'Étoile. Toute la Guilde lève sa chope pour toi !",
		fin = "Tu l'as fait ! Hamrik est remonté grâce à toi, et ton nom sera gravé au-dessus du comptoir. À la Légende de la Guilde !",
		objectifs = {{type = "miner", cible = "Gold", n = 20}}, recompense = {pieces = 8000, renommee = 600}},
} :: {Quete}

-- Suite indépendante, accessible dès la première visite chez Margot.
Q.MARGOT = {
	{id = "pic1", chapitre = 1, pnj = "Taverne", titre = "Le foyer du Pic Doré",
		recit = "Viens te réchauffer. Le feu baisse et la salle sera pleine ce soir. Tu me rapportes de quoi rallumer le foyer ?",
		fin = "Ça crépite déjà. Merci, mon chou. Les mineurs trouveront une salle chaude en remontant.",
		objectifs = {{type = "livrer", cible = "Charbon", n = 8}}, recompense = {pieces = 22, renommee = 15}},
	{id = "pic2", chapitre = 1, pnj = "Taverne", titre = "Un outil pour la relève",
		recit = "Je tiens un registre des sorties pour les nouveaux. Si tu veux y inscrire ton nom, montre-moi une pioche de cuivre. Liesel t'en trouvera une.",
		fin = "Un bon outil et une main patiente. Te voilà sur mon registre.",
		objectifs = {{type = "pioche", cible = "Cuivre", n = 1}}, recompense = {pieces = 32, renommee = 20}},
	{id = "pic3", chapitre = 1, pnj = "Taverne", titre = "Le casque du veilleur",
		recit = "Avant de descendre, mets un casque de ton sac. Si tu n'en as pas, Brom sait en faire un avec un peu de charbon. Je préfère te revoir avec la tête entière.",
		fin = "Il te va bien. Garde-le sur la tête, même quand la galerie a l'air tranquille.",
		objectifs = {{type = "equiper", cible = "Casque", n = 1}}, recompense = {pieces = 26, renommee = 20}},
	{id = "pic4", chapitre = 1, pnj = "Taverne", titre = "Retour des Galeries humides",
		recit = "Mine quatre filons où tu veux, et reviens vivant des galeries à cinquante mètres. Si tu passes par le lac, pense à jeter une ligne. Je t'attends ici.",
		fin = "Te revoilà ! Dis-moi où la roche tient bien. Les suivants seront contents de le savoir.",
		objectifs = {{type = "miner", n = 4}, {type = "sortie", cible = "50", n = 1}}, recompense = {pieces = 45, renommee = 30}},
	{id = "pic5", chapitre = 1, pnj = "Taverne", titre = "Les histoires du Lac des Lueurs",
		recit = "On m'a dit qu'on pêchait même sous la montagne. Montre-moi trois prises dans ton carnet, même celles que tu as déjà faites. Je veux savoir ce qui mord là-dessous !",
		fin = "Trois prises sous terre ! Voilà une histoire à raconter quand on sert la soupe.",
		objectifs = {{type = "pecher", n = 3}}, recompense = {pieces = 42, renommee = 25}},
	{id = "pic6", chapitre = 1, pnj = "Taverne", titre = "Une ligne de plus au registre",
		recit = "Les Cavernes oubliées sont plus rudes. Sors-en vivant et rapporte quatre fers pour les étais. Quand tu reviendras, on notera le chemin pour les autres.",
		fin = "Quatre fers et un mineur revenu sain et sauf. Je garde la dernière ligne du registre pour ton nom.",
		objectifs = {{type = "sortie", cible = "100", n = 1}, {type = "livrer", cible = "Fer", n = 4}}, recompense = {pieces = 78, renommee = 40}},
} :: {Quete}

-- ===== Contrats du jour =====
Q.NB_CONTRATS = 3
Q.BONUS_COFFRE = 0.5 -- les 3 contrats rendus le même jour : +50 % des pièces des contrats en coffre

-- Texte d'un objectif (« Mine 15 charbons »)
function Q.texteObjectif(o: Objectif): string
	local m = o.cible and Q.MINERAIS[o.cible]
	if o.type == "miner" then
		return if m then string.format("Mine %d %s", o.n, if o.n > 1 then m.pluriel else m.nom:lower()) else string.format("Mine %d minerais", o.n)
	elseif o.type == "livrer" then
		return string.format("Livre %d %s", o.n, if m then (if o.n > 1 then m.pluriel else m.nom:lower()) else "minerais")
	elseif o.type == "forger" then
		local noms = {Epee = "épée", Casque = "casque", Plastron = "plastron", Jambieres = "jambières"}
		local nom = o.cible and noms[o.cible]
		return if nom then string.format("Forge %d %s", o.n, nom) else string.format("Forge %d objet%s", o.n, if o.n > 1 then "s" else "")
	elseif o.type == "pioche" then
		return "Obtiens la pioche « " .. tostring(o.cible) .. " »"
	elseif o.type == "wagon" then
		return string.format("Fais %d trajet%s en wagonnet", o.n, if o.n > 1 then "s" else "")
	elseif o.type == "equiper" then
		return "Équipe un casque depuis ton sac"
	elseif o.type == "pecher" then
		return string.format("Inscris %d prises au carnet de pêche", o.n)
	elseif o.type == "sortie" then
		return "Reviens vivant de la grotte à -" .. tostring(o.cible) .. " m"
	end
	return "?"
end

-- Générateur déterministe des contrats d'un joueur pour un jour donné (même résultat sur tous les serveurs)
local TITRES = {
	miner = {"Commande urgente", "Les forges ont faim", "Filon à exploiter", "Quota de la Guilde"},
	livrer = {"Livraison à la taverne", "Réserve de la Guilde", "Caisse pour le comptoir"},
	forger = {"Commande de la garde", "Équiper les recrues"},
	wagon = {"Inspection des rails", "Tournée des wagonnets"},
}
local DONNEURS = {miner = {"Vente", "Taverne"}, livrer = {"Taverne", "Vente"}, forger = {"Forge"}, wagon = {"Taverne"}}
local RECITS = {
	miner = {"Un client du comptoir a passé une grosse commande. Descends creuser, la Guilde paiera le reste.",
		"Les forges du royaume tournent à plein régime. Il leur faut du minerai, et vite !"},
	livrer = {"La réserve de la Guilde est presque vide. Apporte ce qu'il faut à la taverne, on compte sur toi.",
		"Une caravane part demain à l'aube. Remplis sa caisse avant qu'elle ne s'en aille."},
	forger = {"La garde du village manque d'équipement. Brom a besoin de bras pour frapper l'acier.",
		"Les nouvelles recrues partent en patrouille sans rien sur le dos. Forge-leur quelque chose !"},
	wagon = {"Des grincements inquiétants dans le tunnel... Fais quelques trajets pour vérifier les rails.",
		"Le wagonnet doit rouler chaque jour, sinon les roues rouillent. Va faire un tour en bas !"},
}

function Q.genererContrats(jour: number, userId: number, rang: number): {Quete}
	local rng = Random.new(jour * 7919 + (userId % 1000003) * 104729)
	local minerais = {"Charbon", "Bronze"}
	if rang >= 2 then
		table.insert(minerais, "Fer")
	end
	if rang >= 4 then
		table.insert(minerais, "Gold")
	end
	local echelle = 1 + (rang - 1) * 0.45 -- les contrats grandissent avec le rang
	local genres = {"miner", "miner", "livrer", "forger", "wagon"}
	local liste, deja = {}, {}
	local essais = 0
	while #liste < Q.NB_CONTRATS and essais < 50 do
		essais += 1
		local genre = genres[rng:NextInteger(1, #genres)]
		local cible: string? = nil
		local n, pieces = 0, 0
		if genre == "miner" then
			if rng:NextNumber() < 0.35 then
				n = math.floor((20 + rng:NextInteger(0, 10)) * echelle)
				pieces = n * Q.VALEUR_MOYENNE * 0.6
			else
				cible = minerais[rng:NextInteger(1, #minerais)]
				local m = Q.MINERAIS[cible :: string]
				n = math.max(3, math.floor((rng:NextInteger(6, 10) * echelle) * (m.chance / 0.12) ^ 0.6))
				pieces = (n / m.chance) * Q.VALEUR_MOYENNE * 0.5
			end
		elseif genre == "livrer" then
			cible = minerais[rng:NextInteger(1, #minerais)]
			local m = Q.MINERAIS[cible :: string]
			n = math.max(2, math.floor((rng:NextInteger(5, 9) * echelle) * (m.chance / 0.12) ^ 0.6))
			pieces = n * m.valeur * 2.5 + (n / m.chance) * Q.VALEUR_MOYENNE * 0.3
		elseif genre == "forger" then
			n = if rang >= 3 then 2 else 1
			pieces = 60 * n * echelle
		elseif genre == "wagon" then
			n = 2 + math.floor(rang / 3)
			pieces = 25 * n * echelle
		end
		local cle = genre .. (cible or "")
		if deja[cle] then
			continue
		end
		deja[cle] = true
		local titres = TITRES[genre]
		local donneurs = DONNEURS[genre]
		table.insert(liste, {
			id = string.format("c%d_%d", jour, #liste + 1),
			chapitre = 0,
			pnj = donneurs[rng:NextInteger(1, #donneurs)],
			titre = titres[rng:NextInteger(1, #titres)],
			recit = RECITS[genre][rng:NextInteger(1, #RECITS[genre])],
			fin = "Contrat rempli. La Guilde te remercie !",
			objectifs = {{type = genre, cible = cible, n = n}},
			recompense = {pieces = math.max(15, math.floor(pieces / 5 + 0.5) * 5), renommee = 15 + 5 * rang},
		})
	end
	return liste
end

function Q.jour(): number
	return math.floor(os.time() / 86400)
end

function Q.histoire(index: number): Quete?
	return Q.HISTOIRE[index]
end

return Q
