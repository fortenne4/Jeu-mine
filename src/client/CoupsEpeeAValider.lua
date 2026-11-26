--!strict
-- Coups d'épée À VALIDER · ModuleScript CLIENT (StarterPlayerScripts › Jeu › CoupsEpeeAValider)
-- Hors combo, jamais jouables en vrai jeu : EpeeAnimation.client ne charge ce module qu'en Studio
-- (aperçu local, touches Y U J K, épée en main ; ni dégâts ni envoi au serveur).
-- Même format que COUPS d'EpeeAnimation (repère du torse : +X droite, +Y haut, -Z devant ; p relatif à l'épaule
-- droite en longueurs de bras ; d = lame, c = coude, n = normale du plat ; yaw + = épaule droite en avant,
-- pitch + = cambré). Clé 1 = pose actuelle, dernière clé = garde. deuxMains = main gauche sur la poignée
-- (décalage le long de la lame, négatif = vers le pommeau). Une fois validé, un coup passe dans COUPS.

local IK = require(script.Parent:WaitForChild("RigIK"))
local lisse, sortie, entree = IK.lisse, IK.sortie, IK.entree
local function lineaire(u: number): number
	return u
end

local V = Vector3.new
local Z = Vector3.zero
local GARDE_P, GARDE_D, GARDE_C = V(-0.1, -0.45, -0.6), V(-0.1, 0.55, -0.85), V(0.3, -0.6, 0.6)
local HAUT, DROITE = V(0, 1, 0), V(1, 0, 0)

return {
	{
		nom = "Estoc fendu", -- recul de l'épaule, puis coup droit bras tendu, buste penché en avant
		duree = 0.5, t = {0, 0.32, 0.48, 0.7, 1}, e = {sortie, entree, sortie, lisse},
		frappe = Vector2.new(0.32, 0.7), enchainer = 1, cache = 0, son = "SonCoup",
		p = {Z, V(0.15, -0.3, 0.25), V(-0.3, 0.05, -0.95), V(-0.28, 0.02, -0.9), GARDE_P},
		d = {Z, V(0, 0.05, -1), V(0, -0.05, -1), V(0, -0.03, -1), GARDE_D},
		c = {GARDE_C, V(0.6, -0.5, 0.6), V(0.5, -0.8, 0.2), V(0.5, -0.8, 0.25), GARDE_C},
		yaw = {0, -0.35, 0.45, 0.4, 0},
		pitch = {0, 0.05, -0.15, -0.12, 0},
		n = {Z, HAUT, HAUT, HAUT, DROITE},
	},
	{
		nom = "Moulinet tournoyant", -- buste vrillé loin derrière, grand arc à hauteur de taille, lame qui finit derrière l'épaule gauche
		duree = 0.7, t = {0, 0.25, 0.42, 0.55, 0.72, 1}, e = {sortie, entree, lineaire, sortie, lisse},
		frappe = Vector2.new(0.3, 0.68), enchainer = 1, cache = 0, son = "SonCoup",
		p = {Z, V(0.6, -0.1, 0.55), V(0.45, -0.15, -0.6), V(-0.25, -0.15, -0.9), V(-0.9, 0.05, -0.3), GARDE_P},
		d = {Z, V(0.3, 0.1, 0.95), V(0.55, 0, -0.85), V(-0.45, -0.05, -0.9), V(-0.85, 0.15, 0.5), GARDE_D},
		c = {GARDE_C, V(0.6, -0.6, 0.5), V(0.8, -0.5, 0), V(0.3, -0.9, 0.1), V(0.1, -0.8, -0.2), GARDE_C},
		yaw = {0, -0.75, -0.3, 0.3, 0.75, 0},
		pitch = {0, 0, -0.05, -0.05, 0, 0},
		n = {Z, HAUT, HAUT, HAUT, HAUT, DROITE},
	},
	{
		nom = "Coup montant", -- lame basse à droite, buste ramassé, remontée en uppercut jusqu'au-dessus de la tête
		duree = 0.48, t = {0, 0.3, 0.48, 0.7, 1}, e = {sortie, entree, sortie, lisse},
		frappe = Vector2.new(0.3, 0.72), enchainer = 1, cache = 0, son = "SonCoup",
		p = {Z, V(0.25, -0.75, 0.2), V(-0.2, 0.1, -0.85), V(-0.15, 0.8, -0.45), GARDE_P},
		d = {Z, V(0.15, -0.85, -0.45), V(-0.05, 0.75, -0.65), V(0, 0.95, 0.3), GARDE_D},
		c = {GARDE_C, V(0.7, -0.3, 0.5), V(0.6, -0.7, 0.2), V(0.8, 0.1, 0.3), GARDE_C},
		yaw = {0, -0.3, 0.15, 0.05, 0},
		pitch = {0, -0.12, 0, 0.15, 0},
		n = {Z, DROITE, DROITE, DROITE, DROITE},
	},
	{
		nom = "Fendoir à deux mains", -- épée levée au-dessus de la tête à deux mains (lame vers l'arrière), chute plongeante, buste penché
		duree = 0.65, t = {0, 0.38, 0.55, 0.75, 1}, e = {sortie, entree, sortie, lisse},
		frappe = Vector2.new(0.38, 0.75), enchainer = 1, cache = 0, son = "SonCoup", deuxMains = -0.45,
		p = {Z, V(-0.45, 0.75, -0.35), V(-0.4, -0.1, -0.85), V(-0.35, -0.6, -0.6), GARDE_P},
		d = {Z, V(0, 0.55, 0.85), V(0, -0.25, -1), V(0, -0.85, -0.5), GARDE_D},
		c = {GARDE_C, V(0.8, 0.2, -0.2), V(0.6, -0.7, 0.1), V(0.5, -0.8, 0.3), GARDE_C},
		yaw = {0, 0.25, 0.3, 0.3, 0},
		pitch = {0, 0.2, -0.2, -0.3, 0},
		n = {Z, DROITE, DROITE, DROITE, DROITE},
	},
}
