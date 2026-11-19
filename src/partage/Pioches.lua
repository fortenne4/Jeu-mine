--!strict
-- Catalogue des pioches vendues par Liesel (ReplicatedStorage › Partage › Pioches).
-- Le serveur s'en sert pour les prix et les stats (il fait foi) ; le client seulement pour l'affichage.
-- Les identifiants suivent les modèles voxel de blender/pioches (PiocheGivre, PiocheVolcan...).

export type Pioche = {
	id: string,
	nom: string,
	rarete: string,
	prix: number,
	puissance: number, -- PV retirés à un minerai par coup
	recharge: number, -- secondes entre deux coups
	description: string,
	lueur: Color3, -- flammes, aura, pièces néon de la pioche
	lueur2: Color3, -- couleur chaude des flammes
	metal: Color3, -- tête de la pioche (aperçu)
	manche: Color3,
}

local Pioches = {}

Pioches.RARETES = {
	Commun = Color3.fromRGB(184, 188, 198),
	["Peu commun"] = Color3.fromRGB(255, 154, 60),
	Rare = Color3.fromRGB(79, 141, 255),
	["Légendaire"] = Color3.fromRGB(179, 92, 255),
	Mythique = Color3.fromRGB(255, 72, 96),
	Divin = Color3.fromRGB(255, 206, 72),
}

-- Dans l'ordre de progression : il faut posséder la précédente pour acheter la suivante.
Pioches.LISTE = {
	{
		-- Pioche de départ, offerte (modèles 3D blender/pioches : Bois, Pierre, Cuivre, Fer, Quartz...)
		id = "Bois", nom = "Pioche du Bûcheron", rarete = "Commun", prix = 0, puissance = 1, recharge = 0.6,
		description = "Ta première pioche : une branche de chêne aux pointes durcies au feu, liée par une corde. Une pousse y a repris racine.",
		lueur = Color3.fromRGB(201, 169, 106), lueur2 = Color3.fromRGB(143, 116, 66),
		metal = Color3.fromRGB(130, 88, 47), manche = Color3.fromRGB(110, 72, 38),
	},
	{
		id = "Pierre", nom = "Pioche de Silex", rarete = "Commun", prix = 35, puissance = 1.4, recharge = 0.58,
		description = "Deux lames de silex taillé, serrées dans une mâchoire de bois par des lanières de cuir.",
		lueur = Color3.fromRGB(176, 170, 160), lueur2 = Color3.fromRGB(107, 68, 35),
		metal = Color3.fromRGB(91, 88, 86), manche = Color3.fromRGB(192, 154, 102),
	},
	{
		id = "Cuivre", nom = "Pioche de Cuivre", rarete = "Peu commun", prix = 60, puissance = 1.6, recharge = 0.57,
		description = "Coulée d'une seule pièce. Ses rivets brillent encore, le vert-de-gris gagne les creux.",
		lueur = Color3.fromRGB(255, 138, 58), lueur2 = Color3.fromRGB(75, 161, 137),
		metal = Color3.fromRGB(189, 101, 50), manche = Color3.fromRGB(173, 134, 86),
	},
	{
		id = "Fer", nom = "Pioche de Fer", rarete = "Peu commun", prix = 90, puissance = 1.8, recharge = 0.56,
		description = "Forgée au marteau : un pic, une herminette, et des tranchants d'acier trempé.",
		lueur = Color3.fromRGB(159, 196, 255), lueur2 = Color3.fromRGB(221, 227, 234),
		metal = Color3.fromRGB(50, 53, 60), manche = Color3.fromRGB(53, 36, 26),
	},
	{
		id = "Quartz", nom = "Pioche de Quartz", rarete = "Rare", prix = 120, puissance = 1.9, recharge = 0.56,
		description = "Le quartz rose d'un premier filon, serti dans l'acier. Une améthyste veille au centre.",
		lueur = Color3.fromRGB(255, 95, 176), lueur2 = Color3.fromRGB(138, 62, 224),
		metal = Color3.fromRGB(152, 162, 177), manche = Color3.fromRGB(53, 36, 26),
	},
	{
		id = "Givre", nom = "Pioche de Givre", rarete = "Peu commun", prix = 150, puissance = 2, recharge = 0.55,
		description = "Forgée dans la glace des sommets. Le minerai gèle et se fend deux fois plus vite.",
		lueur = Color3.fromRGB(140, 215, 255), lueur2 = Color3.fromRGB(60, 140, 255),
		metal = Color3.fromRGB(176, 214, 236), manche = Color3.fromRGB(70, 84, 104),
	},
	{
		id = "Volcan", nom = "Pioche du Volcan", rarete = "Rare", prix = 450, puissance = 3, recharge = 0.5,
		description = "Une tête de basalte où coule encore la lave. Rien ne lui résiste longtemps.",
		lueur = Color3.fromRGB(255, 90, 20), lueur2 = Color3.fromRGB(200, 30, 10),
		metal = Color3.fromRGB(46, 38, 36), manche = Color3.fromRGB(74, 42, 26),
	},
	{
		id = "Celeste", nom = "Pioche Céleste", rarete = "Légendaire", prix = 1200, puissance = 4, recharge = 0.45,
		description = "Tombée d'une étoile filante au-dessus de la mine. Légère comme une plume.",
		lueur = Color3.fromRGB(255, 232, 150), lueur2 = Color3.fromRGB(120, 200, 255),
		metal = Color3.fromRGB(236, 230, 214), manche = Color3.fromRGB(196, 160, 90),
	},
	{
		id = "Demon", nom = "Pioche du Démon", rarete = "Légendaire", prix = 3000, puissance = 6, recharge = 0.42,
		description = "Ses cornes murmurent la nuit. Elle a soif de cristaux.",
		lueur = Color3.fromRGB(255, 40, 60), lueur2 = Color3.fromRGB(140, 0, 20),
		metal = Color3.fromRGB(34, 26, 30), manche = Color3.fromRGB(80, 20, 24),
	},
	{
		id = "Neant", nom = "Pioche du Néant", rarete = "Mythique", prix = 7500, puissance = 8, recharge = 0.38,
		description = "Elle ne frappe pas la roche : elle l'efface.",
		lueur = Color3.fromRGB(170, 80, 255), lueur2 = Color3.fromRGB(70, 20, 160),
		metal = Color3.fromRGB(26, 20, 40), manche = Color3.fromRGB(44, 30, 64),
	},
	{
		id = "Legende", nom = "Pioche de Légende", rarete = "Divin", prix = 18000, puissance = 12, recharge = 0.32,
		description = "Le chef-d'œuvre de Liesel. On dit que la montagne s'ouvre d'elle-même devant elle.",
		lueur = Color3.fromRGB(255, 206, 72), lueur2 = Color3.fromRGB(255, 140, 20),
		metal = Color3.fromRGB(250, 214, 110), manche = Color3.fromRGB(120, 40, 36),
	},
} :: {Pioche}

Pioches.DEPART = "Bois"

local parId: {[string]: Pioche} = {}
local rang: {[string]: number} = {}
for i, p in Pioches.LISTE do
	parId[p.id] = p
	rang[p.id] = i
end

function Pioches.get(id: any): Pioche?
	if type(id) ~= "string" then
		return nil
	end
	return parId[id]
end

-- Pioche à posséder avant de pouvoir acheter celle-ci (nil pour la première)
function Pioches.precedente(id: string): Pioche?
	local r = rang[id]
	return if r and r > 1 then Pioches.LISTE[r - 1] else nil
end

return Pioches
