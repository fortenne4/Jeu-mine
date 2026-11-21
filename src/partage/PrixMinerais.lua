--!strict
-- Prix de vente des minerais chez Gaspard (ReplicatedStorage › Partage › PrixMinerais).
-- Source unique : Marchand.server.lua (fait foi), Minerais.server.lua (ancien gain direct) et l'affichage client.
-- Mêmes valeurs qu'avant (quand le minage payait tout de suite) : la progression vers les pioches
-- de Liesel reste la même, l'argent passe juste par le comptoir. Repères : ~35 charbons = Pioche de Pierre,
-- 18 ors ≈ Pioche Volcan (450).

local PrixMinerais = {}

PrixMinerais.PRIX = {
	Charbon = 1,
	Bronze = 3,
	Fer = 8,
	Gold = 25,
} :: {[string]: number}

-- Prix unitaire d'un minerai (nil si inconnu)
function PrixMinerais.get(id: any): number?
	if type(id) ~= "string" then
		return nil
	end
	return PrixMinerais.PRIX[id]
end

return PrixMinerais
