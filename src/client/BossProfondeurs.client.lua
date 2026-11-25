-- Butin des boss des grottes profondes · SCRIPT CLIENT (StarterPlayerScripts › Jeu › BossProfondeurs)
-- Affiche seulement ce que le serveur (BossProfondeurs.lua) a déjà donné : pop-up de coffre (PopupCoffre).
--   ("Butin", {boss, minerais = {{id, n}}, pieces, plein?}) : Léviathan des abysses, ou consolation du Gardien des astres
--   ("EpeeAstres", {nom, degats})                            : pop-up spécial « ÉPÉE DES ASTRES OBTENUE »
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Grottes = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("Grottes"))
local PopupCoffre = require(script.Parent:WaitForChild("PopupCoffre"))
local remote = ReplicatedStorage:WaitForChild("BossProfondeurs") :: RemoteEvent

local COSMIQUE = Color3.fromRGB(120, 170, 255)

local function cartesMinerais(d): {any}
	local cartes = {}
	for _, e in (if type(d.minerais) == "table" then d.minerais else {}) do
		local id, n = e[1], tonumber(e[2]) or 0
		if type(id) == "string" and n > 0 then
			table.insert(cartes, {genre = "minerai", id = id, n = n, nom = Grottes.NOMS_MINERAIS[id] or id})
		end
	end
	local pieces = tonumber(d.pieces) or 0
	if pieces > 0 then
		table.insert(cartes, {genre = "pieces", n = pieces})
	end
	return cartes
end

local DELAI = 2.5 -- s : laisse le boss mourir au ralenti (MobsGrotte.client) avant le pop-up

local function afficher(genre: string, d: any)
	if genre == "Butin" then
		if d.boss == "GardienAstres" then
			PopupCoffre.afficher({titre = "TRÉSOR DES ASTRES", theme = "Astres",
				sousTitre = if d.plein then "Coffre d'équipement plein : fais de la place pour l'Épée des astres"
					else "Tu possèdes déjà l'Épée des astres",
				recompenses = cartesMinerais(d)})
		else
			PopupCoffre.afficher({titre = "BUTIN DU LÉVIATHAN", theme = "Abysses",
				sousTitre = "Lunarite + magmaïte : forge la Lame ou le Heaume des marées chez Brom",
				recompenses = cartesMinerais(d)})
		end
	elseif genre == "EpeeAstres" then
		PopupCoffre.afficher({titre = "ÉPÉE DES ASTRES OBTENUE", theme = "Astres",
			sousTitre = string.format("%d dégâts · rareté Céleste · équipe-la depuis ton sac (B)", tonumber(d.degats) or 0),
			recompenses = {{genre = "epee", id = "EpeeDesAstres", n = 1, nom = if type(d.nom) == "string" then d.nom else "Épée des astres",
				rarete = "Céleste", couleur = COSMIQUE}}})
	end
end

remote.OnClientEvent:Connect(function(genre: string, d: any)
	task.delay(DELAI, afficher, genre, if type(d) == "table" then d else {})
end)
