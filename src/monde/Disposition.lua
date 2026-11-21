-- Plan du monde : toutes les coordonnées importantes au même endroit.
-- Nord = -Z (la montagne de la mine). Le sol de la vallée est à Y = 0.
-- Les joueurs apparaissent sur la place (0, 0, 0) et regardent vers la mine.

local D = {}

D.PLACE_RAYON = 34                          -- place centrale (spawn)
D.AVENUE_FIN_Z = -100                       -- l'avenue relie la place à la gare
D.RIVIERE_Z = 82                            -- rivière est-ouest au sud du village
D.RIVIERE_LARGEUR = 20

D.RAIL_DEBUT = Vector3.new(0, 0, -100)      -- départ des wagonnets (gare)
D.CREUSE_DEBUT_Z = -164                     -- début de la tranchée creusée dans la falaise
D.PORTAIL_Z = -178                          -- façade de pierre de la mine
D.PORTAIL_LARGEUR = 44
D.PORTAIL_HAUTEUR = 34
D.TUNNEL_FIN = Vector3.new(0, 0, -232)      -- fin du tunnel plat, début de la descente
D.DESCENTE_FIN = Vector3.new(0, -60, -352)  -- bas de la descente
D.QUAI_BAS = Vector3.new(0, -60, -400)      -- terminus souterrain

D.CAVERNE_CENTRE = Vector3.new(0, -40, -425)
D.CAVERNE_RAYON = 70
D.CAVERNE_SOL = -60
D.CAVERNE_LOBES = {
	{Vector3.new(-55, -42, -395), 42},
	{Vector3.new(55, -45, -400), 40},
}

-- Portes des tunnels privés, en arc de cercle contre la paroi nord de la caverne
D.PORTES = {}
for i = 1, 6 do
	local a = math.rad(-62.5 + (i - 1) * 25)
	D.PORTES[i] = Vector3.new(math.sin(a) * 60, D.CAVERNE_SOL, D.CAVERNE_CENTRE.Z - math.cos(a) * 60)
end
D.PORTES_ENFONCEMENT = 7   -- le cadre est encastré dans la paroi, 7 studs derrière D.PORTES (r = 67)
D.CERCLES_AVANCE = 4.5     -- cercle lumineux 4.5 studs devant D.PORTES (r = 55.5), sans toucher le parvis
D.RETOUR_AVANCE = 13       -- point de retour d'une mine privée (r = 47, hors du cercle, face au centre)

-- Grand cristal violet de la caverne (lobe ouest, à l'écart des portes et du chemin quai → portes)
D.CRISTAL_CAVERNE = Vector3.new(-68, -60, -398)

-- Mines privées : une par joueur, sur une grille loin de la carte (hors terrain, hors plaine des mobs x 4700..5300)
D.MINES_PRIVEES_ORIGINE = Vector3.new(1400, 40, -1200)
D.MINES_PRIVEES_ECART = 400
D.MINES_PRIVEES_COLONNES = 6 -- x de 1400 à 3400

-- Minerais de démonstration au sol de la caverne (en attendant les tunnels privés)
D.MINERAIS = {
	Vector3.new(18, -60, -418),
	Vector3.new(30, -60, -434),
	Vector3.new(34, -60, -452),
	Vector3.new(18, -60, -464),
	Vector3.new(0, -60, -452),
	Vector3.new(-12, -60, -468),
	Vector3.new(-46, -60, -420),
	Vector3.new(-22, -60, -414),
}

return D
