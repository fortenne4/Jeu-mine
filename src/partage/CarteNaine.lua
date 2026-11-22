-- Carte du royaume nain · MODULE PARTAGÉ (ReplicatedStorage › Partage › CarteNaine)
-- 8 fragments de carte cachés dans la grotte −50 m (« Le Lac des Lueurs »). Chaque fragment ramassé donne un
-- morceau de l'histoire du royaume englouti et quelques pièces ; la carte complète rapporte une grosse récompense.
-- Le serveur (CarteNaine.lua) fait foi pour les récompenses ; le client s'en sert pour l'affichage.

local CarteNaine = {}

CarteNaine.NIVEAU = 1 -- palier où les fragments sont cachés
CarteNaine.CACHES_PAR_GROTTE = 5 -- cachettes posées dans chaque grotte (chaque joueur peut les ramasser une fois)
CarteNaine.PIECES_FRAGMENT = 15 -- pièces données avec chaque nouveau fragment
CarteNaine.PIECES_DOUBLON = 8 -- cachette ramassée alors que la carte est déjà complète
CarteNaine.PIECES_CARTE_COMPLETE = 300 -- bonus quand le 8e fragment est trouvé
CarteNaine.REMOTE = "CarteNaine" -- RemoteEvent (ReplicatedStorage) : serveur → client (type, données)

CarteNaine.FRAGMENTS = {
	{id = "F1", titre = "Le peuple des lueurs",
		texte = "Avant la Grande Mine, les nains de Brumefer vivaient sous terre, au bord de lacs qui brillaient dans le noir. Ils appelaient ces lumières « les Lueurs »."},
	{id = "F2", titre = "Les lanternes vivantes",
		texte = "Les nains n'allumaient jamais de feu près des lacs. Ils enfermaient des vers luisants dans des lanternes de verre : ce sont elles qui balisent encore les galeries."},
	{id = "F3", titre = "La forêt de champignons",
		texte = "Au cœur du royaume poussait une forêt de champignons géants. Ses spores soignaient les blessures… et rendaient fous ceux qui en respiraient trop."},
	{id = "F4", titre = "Le roi Haldur",
		texte = "Le roi Haldur fit creuser un temple au fond des galeries pour y garder la plus grande géode jamais trouvée : le Cœur des Lueurs."},
	{id = "F5", titre = "Les gardiens de pierre",
		texte = "Deux statues gardent l'arche du temple. Les anciens disaient qu'une partie de l'âme des meilleurs guerriers dormait dans la pierre."},
	{id = "F6", titre = "La Grande Crue",
		texte = "Une nuit, les lacs débordèrent. L'eau noya la moitié du royaume en quelques heures. Les survivants scellèrent le temple et remontèrent vers la surface."},
	{id = "F7", titre = "Ce qu'il reste",
		texte = "On dit que les nains du village descendent de ces survivants. Gaspard, Brom et Margot se taisent quand on leur parle du temple."},
	{id = "F8", titre = "Plus bas encore",
		texte = "La dernière ligne de la carte montre un escalier qui s'enfonce sous le temple, vers des cavernes que même Haldur n'osa jamais explorer."},
}

CarteNaine.PAR_ID = {}
for i, f in CarteNaine.FRAGMENTS do
	f.numero = i
	CarteNaine.PAR_ID[f.id] = f
end

-- Ensemble des fragments trouvés à partir de l'attribut joueur « FragmentsCarte » (« F1,F3 »)
function CarteNaine.lire(attribut: any): {[string]: boolean}
	local t = {}
	if type(attribut) == "string" then
		for id in attribut:gmatch("[^,]+") do
			if CarteNaine.PAR_ID[id] then
				t[id] = true
			end
		end
	end
	return t
end

function CarteNaine.compter(trouves: {[string]: boolean}): number
	local n = 0
	for _ in trouves do
		n += 1
	end
	return n
end

return CarteNaine
