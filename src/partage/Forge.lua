--!strict
-- Recettes de la forge de Brom (ReplicatedStorage › Partage › Forge). Logique pure, sans effet de bord :
-- le serveur s'en sert pour décider (il fait foi), le client pour l'aperçu en direct.
-- Composition : {{idMinerai, quantite}, ...} — N minerais différents (jusqu'à MAX_MINERAIS).

export type Minerai = {id: string, nom: string, mat: string, couleur: Color3, force: number, rang: number}
export type TypeObjet = {id: string, nom: string, icone: string, stat: string, mult: number, min: number, max: number, frais: number}
export type Alliage = {nom: string, mat: string, couleur: Color3, bonus: number, parts: {[string]: {number}}}
export type Resultat = {
	type: string,
	nom: string,
	couleur: Color3,
	stat: string,
	valeur: number,
	total: number,
	prix: number,
	alliage: string?,
	composition: {{any}},
}

local Forge = {}

Forge.MAX_MINERAIS = 4
Forge.QTE_MAX = 999
Forge.FRAIS_PAR_MINERAI = 5

-- Mêmes identifiants que les minerais du jeu (Minerais.server.lua) ; force = qualité par unité
Forge.ORDRE_MINERAIS = {"Charbon", "Bronze", "Fer", "Gold"}
Forge.MINERAIS = {
	Charbon = {id = "Charbon", rang = 1, nom = "Charbon", mat = "charbon", couleur = Color3.fromRGB(48, 48, 54), force = 1.5},
	Bronze = {id = "Bronze", rang = 2, nom = "Bronze", mat = "bronze", couleur = Color3.fromRGB(180, 98, 44), force = 4},
	Fer = {id = "Fer", rang = 3, nom = "Fer", mat = "fer", couleur = Color3.fromRGB(152, 158, 170), force = 7},
	Gold = {id = "Gold", rang = 4, nom = "Or", mat = "or", couleur = Color3.fromRGB(255, 196, 48), force = 11},
} :: {[string]: Minerai}

Forge.ORDRE_TYPES = {"Epee", "Casque", "Plastron", "Jambieres"}
Forge.TYPES = {
	Epee = {id = "Epee", nom = "Épée", icone = "🗡️", stat = "Dégâts", mult = 2, min = 3, max = 24, frais = 20},
	Casque = {id = "Casque", nom = "Casque", icone = "⛑️", stat = "Défense", mult = 1, min = 2, max = 12, frais = 15},
	Plastron = {id = "Plastron", nom = "Plastron", icone = "🛡️", stat = "Défense", mult = 1.6, min = 4, max = 30, frais = 30},
	Jambieres = {id = "Jambieres", nom = "Jambières", icone = "👖", stat = "Défense", mult = 1.3, min = 3, max = 20, frais = 25},
} :: {[string]: TypeObjet}

-- Alliages nommés : chaque minerai listé doit être présent dans sa fourchette de proportion [min, max],
-- et aucun autre minerai ne doit être ajouté.
Forge.ALLIAGES = {
	{nom = "Acier", mat = "acier", couleur = Color3.fromRGB(118, 134, 150), bonus = 1.4,
		parts = {Fer = {0.6, 0.95}, Charbon = {0.05, 0.4}}},
	{nom = "Bronze noir", mat = "bronze noir", couleur = Color3.fromRGB(96, 62, 40), bonus = 1.25,
		parts = {Bronze = {0.6, 0.95}, Charbon = {0.05, 0.4}}},
	{nom = "Or rose", mat = "or rose", couleur = Color3.fromRGB(236, 160, 140), bonus = 1.3,
		parts = {Gold = {0.5, 0.85}, Bronze = {0.15, 0.5}}},
	{nom = "Or blanc", mat = "or blanc", couleur = Color3.fromRGB(236, 230, 212), bonus = 1.3,
		parts = {Gold = {0.5, 0.85}, Fer = {0.15, 0.5}}},
	{nom = "Acier royal", mat = "acier royal", couleur = Color3.fromRGB(206, 182, 120), bonus = 1.6,
		parts = {Fer = {0.5, 0.8}, Charbon = {0.05, 0.25}, Gold = {0.1, 0.35}}},
} :: {Alliage}

local function trouverAlliage(liste: {{any}}, total: number): Alliage?
	for _, a in Forge.ALLIAGES do
		local nb = 0
		for _ in a.parts do
			nb += 1
		end
		if nb ~= #liste then
			continue
		end
		local ok = true
		for _, e in liste do
			local borne = a.parts[e[1]]
			local p = e[2] / total
			if not borne or p < borne[1] - 1e-9 or p > borne[2] + 1e-9 then
				ok = false
				break
			end
		end
		if ok then
			return a
		end
	end
	return nil
end

local function enumerer(liste: {{any}}): string
	local mots = {}
	for _, e in liste do
		table.insert(mots, Forge.MINERAIS[e[1]].mat)
	end
	if #mots == 1 then
		return mots[1]
	end
	local dernier = table.remove(mots) :: string
	return table.concat(mots, ", ") .. " et " .. dernier
end

-- Ne fait confiance à rien : accepte n'importe quelle entrée et renvoie (resultat, nil) ou (nil, erreur)
function Forge.calculer(typeId: any, composition: any): (Resultat?, string?)
	local t = if type(typeId) == "string" then Forge.TYPES[typeId] else nil
	if not t then
		return nil, "Type d'objet inconnu"
	end
	if type(composition) ~= "table" then
		return nil, "Composition invalide"
	end
	local n = #composition
	if n < 1 then
		return nil, "Choisis au moins un minerai"
	elseif n > Forge.MAX_MINERAIS then
		return nil, "Trop de minerais différents"
	end
	local liste, vus, total = {}, {}, 0
	for i = 1, n do
		local e = composition[i]
		if type(e) ~= "table" then
			return nil, "Composition invalide"
		end
		local id, q = e[1], e[2]
		if type(id) ~= "string" or not Forge.MINERAIS[id] then
			return nil, "Minerai inconnu"
		elseif vus[id] then
			return nil, "Même minerai deux fois"
		elseif type(q) ~= "number" or q ~= q or q < 1 or q > Forge.QTE_MAX or q % 1 ~= 0 then
			return nil, "Quantité invalide"
		end
		vus[id] = true
		total += q
		table.insert(liste, {id, q})
	end
	if total < t.min then
		return nil, string.format("Il faut au moins %d minerais", t.min)
	elseif total > t.max then
		return nil, string.format("%d minerais au maximum", t.max)
	end
	table.sort(liste, function(a, b)
		if a[2] ~= b[2] then
			return a[2] > b[2]
		end
		return Forge.MINERAIS[a[1]].rang > Forge.MINERAIS[b[1]].rang
	end)

	local force, r, g, b = 0, 0, 0, 0
	for _, e in liste do
		local m = Forge.MINERAIS[e[1]]
		local p = e[2] / total
		force += m.force * p
		r += m.couleur.R * p
		g += m.couleur.G * p
		b += m.couleur.B * p
	end
	local couleur = Color3.new(r, g, b)
	local alliage = trouverAlliage(liste, total)
	local bonus, mat = 1, enumerer(liste)
	if alliage then
		bonus, mat = alliage.bonus, alliage.mat
		couleur = couleur:Lerp(alliage.couleur, 0.7)
	end
	return {
		type = t.id,
		nom = t.nom .. " en " .. mat,
		couleur = couleur,
		stat = t.stat,
		valeur = math.max(1, math.floor(force * bonus * t.mult * math.sqrt(total / t.min) + 0.5)),
		total = total,
		prix = t.frais + total * Forge.FRAIS_PAR_MINERAI,
		alliage = alliage and alliage.nom,
		composition = liste,
	}, nil
end

return Forge
