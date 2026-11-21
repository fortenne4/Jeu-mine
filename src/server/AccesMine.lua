-- Autorisations serveur : seul le trajet validé en wagon ouvre l'accès à la caverne.
-- Les mines privées sont loin de la caverne et conservent cette autorisation au retour.
local acces = {}
local autorises = {}

function acces.autoriser(joueur: Player, personnage: Model)
	autorises[joueur] = personnage
end

function acces.retirer(joueur: Player)
	autorises[joueur] = nil
end

function acces.estAutorise(joueur: Player, personnage: Model): boolean
	return autorises[joueur] == personnage
end

return acces
