-- Curseur : registre des interfaces ouvertes qui ont besoin de la souris libre.
-- Chaque fenêtre appelle Curseur.liberer("NomFenetre", true) à l'ouverture et (…, false) à la fermeture ;
-- CameraVisee.client lit Curseur.estLibre() à chaque image pour débloquer la souris (1re et 3e personne).
local Curseur = {}

local ouverts: {[string]: boolean} = {}

function Curseur.liberer(cle: string, actif: boolean)
	ouverts[cle] = if actif then true else nil
end

function Curseur.estLibre(): boolean
	return next(ouverts) ~= nil
end

return Curseur
