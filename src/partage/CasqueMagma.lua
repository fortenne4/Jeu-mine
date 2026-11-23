-- Quête du Casque du Cœur Magmatique · MODULE PARTAGÉ (ReplicatedStorage › Partage › CasqueMagma)
-- Grotte −200 m (« La Fonderie », palier 3) : 3 reliques volcaniques cachées dans la carte. Une fois les 3 ramassées,
-- l'enclume des maîtres (sur le pilier du gouffre) forge le Casque du Cœur Magmatique, unique, obtenable seulement ainsi.
-- Sauvegarde : ids des reliques et de la forge rangés dans profil.fragments (comme la carte naine), répliqués par
-- l'attribut joueur « FragmentsCarte » (« F1,Magma1,MagmaForge »).
-- Le serveur (CasqueMagma.server.lua) fait foi ; le client (EnclumeMagma.client.lua) ne fait qu'afficher.
--
-- RemoteEvent ReplicatedStorage › CasqueMagma :
--   serveur → client : ("Relique", {id})            relique ramassée (nouvelle)
--                      ("Ouvrir", {})                le joueur a activé l'enclume : ouvrir l'interface
--                      ("Forge", {ok, message})      résultat d'une demande de forge
--   client → serveur : ("Forger")                    forger le casque (3 reliques requises, une seule fois)

local CasqueMagma = {}

CasqueMagma.NIVEAU = 3 -- palier de la Fonderie (−200 m)
CasqueMagma.REMOTE = "CasqueMagma"
CasqueMagma.MODELE = "CasqueMagma" -- module ArmuresVoxels du casque
CasqueMagma.ID_FORGE = "MagmaForge" -- marque « casque déjà forgé »

CasqueMagma.CASQUE = {
	nom = "Casque du Cœur Magmatique",
	rarete = "Unique",
	couleur = Color3.fromRGB(255, 96, 24),
	defense = 15,
	vie = 25, -- PV max en plus
	resistanceFeu = 0.08, -- dégâts de lave, braises, geysers et feu réduits de 8 %
}

-- Les 3 reliques, une par cachette (ordre = rond de l'interface, de gauche à droite)
CasqueMagma.RELIQUES = {
	{id = "Magma1", nom = "Éclat d'obsidienne", couleur = Color3.fromRGB(120, 70, 160), icone = "🪨",
		texte = "Un éclat de verre volcanique noir, encore tiède. Il servira de coque."},
	{id = "Magma2", nom = "Corne de basalte", couleur = Color3.fromRGB(150, 120, 110), icone = "🦴",
		texte = "Une corne de roche tordue par la chaleur, arrachée à une coulée figée."},
	{id = "Magma3", nom = "Cœur de magma", couleur = Color3.fromRGB(255, 110, 30), icone = "🔥",
		texte = "Un cristal qui palpite comme un cœur. La lave semble couler à l'intérieur."},
}

CasqueMagma.PAR_ID = {}
for i, r in CasqueMagma.RELIQUES do
	r.numero = i
	CasqueMagma.PAR_ID[r.id] = r
end

-- Lit l'attribut « FragmentsCarte » : reliques trouvées et casque forgé
function CasqueMagma.lire(attribut: any): ({[string]: boolean}, boolean)
	local t, forge = {}, false
	if type(attribut) == "string" then
		for id in attribut:gmatch("[^,]+") do
			if CasqueMagma.PAR_ID[id] then
				t[id] = true
			elseif id == CasqueMagma.ID_FORGE then
				forge = true
			end
		end
	end
	return t, forge
end

return CasqueMagma
