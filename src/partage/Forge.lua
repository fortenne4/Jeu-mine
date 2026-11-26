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
	modele: string,
	rang: number?,
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

-- Nouveaux minerais de la mine privée (Partage › MineraisPropositions) : au sac et vendables chez Gaspard ;
-- forgeable = false par défaut (refusés par Forge.calculer), levé plus bas pour ceux de FORGEABLES_PROFONDS.
-- ORDRE_SAC = tous les minerais du sac (sac, comptoir de Gaspard), du plus commun au plus rare.
Forge.ORDRE_SAC = table.clone(Forge.ORDRE_MINERAIS)
do
	local Propositions = require(script.Parent:WaitForChild("MineraisPropositions"))
	for i, id in Propositions.ORDRE do
		local v = Propositions.VISUEL[id]
		local nom = Propositions.NOMS[id] or id
		Forge.MINERAIS[id] = {id = id, rang = 4 + i, nom = nom, mat = string.lower(nom), couleur = v.cristal, force = 0, forgeable = false} :: any
		table.insert(Forge.ORDRE_SAC, id)
	end
end

-- Minerais de la mine privée devenus forgeables : force = qualité par unité (Or = 11), croissante avec le prix.
-- ORDRE_FORGE = minerais proposés dans la forge de Brom (4 de départ + ceux-ci).
-- Épée / Casque : seulement par leur échelle (2 du même minerai, ou lunarite + magmaïte) ; Plastron / Jambières : alliages libres.
Forge.FORGEABLES_PROFONDS = {
	Soufre = 2.5, Quartz = 4.5, Argent = 8, Obsidienne = 9, Givrite = 10, Emeraude = 12.5,
	Rubis = 13.5, Lunarite = 16, Magmaite = 19, Diamant = 23, Orichalque = 26, Neantite = 29,
} :: {[string]: number}
Forge.ORDRE_FORGE = table.clone(Forge.ORDRE_MINERAIS)
for _, id in Forge.ORDRE_SAC do
	local m = Forge.MINERAIS[id] :: any
	if m and Forge.FORGEABLES_PROFONDS[id] then
		m.force, m.forgeable = Forge.FORGEABLES_PROFONDS[id], nil
		table.insert(Forge.ORDRE_FORGE, id)
	end
end

Forge.ORDRE_TYPES = {"Epee", "Casque", "Plastron", "Jambieres"}
Forge.TYPES = {
	Epee = {id = "Epee", nom = "Épée", icone = "🗡️", stat = "Dégâts", mult = 2, min = 2, max = 12, frais = 20},
	Casque = {id = "Casque", nom = "Casque", icone = "⛑️", stat = "Défense", mult = 1, min = 2, max = 12, frais = 15},
	Plastron = {id = "Plastron", nom = "Plastron", icone = "🛡️", stat = "Défense", mult = 1.6, min = 4, max = 30, frais = 30},
	Jambieres = {id = "Jambieres", nom = "Jambières", icone = "👖", stat = "Défense", mult = 1.3, min = 3, max = 20, frais = 25},
} :: {[string]: TypeObjet}

-- Échelles de pièces nommées (1 ou 2 minerais, proportions libres) : remplacent les alliages pour ce type.
-- valeur = base × min(bonus quantité × bonus proportion, FACTEUR_MAX), toujours < base strictement supérieure suivante.
-- rang = position après tri par base (calculé au chargement, jamais sauvegardé : Donnees le redéduit du modèle).
export type Palier = {rang: number, minerais: {string}, dominant: string?, modele: string, nom: string, base: number, cout: number, rarete: string}
Forge.BONUS_QTE = 0.3 -- +30 % au maximum de minerais
Forge.BONUS_PROPORTION = 0.1 -- ±10 % selon la part du minerai le plus fort (duo)
Forge.FACTEUR_MAX = 1.35 -- floor(base × 1.35) < base suivante (vérifié + écrêté)
Forge.ECHELLES = {
	Casque = {
		{minerais = {"Charbon"}, modele = "CasqueCharbon", nom = "Casque de charbon", base = 8, cout = 20, rarete = "Commun"},
		{minerais = {"Bronze"}, modele = "CasqueBronze", nom = "Casque de bronze", base = 11, cout = 35, rarete = "Commun"},
		{minerais = {"Charbon", "Bronze"}, modele = "CasqueCharbonBronze", nom = "Casque de charbon et bronze", base = 15, cout = 55, rarete = "Peu commun"},
		{minerais = {"Fer"}, modele = "CasqueFer", nom = "Casque de fer", base = 21, cout = 80, rarete = "Peu commun"},
		{minerais = {"Charbon", "Fer"}, modele = "CasqueCharbonFer", nom = "Casque de charbon et fer", base = 29, cout = 110, rarete = "Rare"},
		{minerais = {"Bronze", "Fer"}, modele = "CasqueBronzeFer", nom = "Casque de bronze et fer", base = 40, cout = 150, rarete = "Rare"},
		{minerais = {"Gold"}, modele = "CasqueOr", nom = "Casque d'or", base = 55, cout = 200, rarete = "Légendaire"},
		{minerais = {"Charbon", "Gold"}, modele = "CasqueCharbonOr", nom = "Casque de charbon et or", base = 75, cout = 260, rarete = "Légendaire"},
		{minerais = {"Bronze", "Gold"}, modele = "CasqueBronzeOr", nom = "Casque de bronze et or", base = 102, cout = 330, rarete = "Mythique"},
		{minerais = {"Fer", "Gold"}, modele = "CasqueFerOr", nom = "Casque de fer et or", base = 138, cout = 420, rarete = "Divin"},
		-- butin du Léviathan des abysses (1 lunarite + 1 magmaïte = le minimum pour un casque)
		{minerais = {"Lunarite", "Magmaite"}, modele = "CasqueMarees", nom = "Heaume des marées", base = 190, cout = 520, rarete = "Divin"},
		-- 2 du même minerai de la mine privée (même base qu'un palier existant, ou au-dessus des marées)
		{minerais = {"Soufre"}, modele = "CasqueSoufre", nom = "Casque de soufre", base = 11, cout = 35, rarete = "Commun"},
		{minerais = {"Quartz"}, modele = "CasqueQuartz", nom = "Casque de quartz", base = 15, cout = 55, rarete = "Peu commun"},
		{minerais = {"Argent"}, modele = "CasqueArgent", nom = "Casque d'argent", base = 21, cout = 80, rarete = "Peu commun"},
		{minerais = {"Obsidienne"}, modele = "CasqueObsidienne", nom = "Casque d'obsidienne", base = 29, cout = 110, rarete = "Rare"},
		{minerais = {"Givrite"}, modele = "CasqueGivrite", nom = "Casque de givrite", base = 40, cout = 150, rarete = "Rare"},
		{minerais = {"Emeraude"}, modele = "CasqueEmeraude", nom = "Casque d'émeraude", base = 55, cout = 200, rarete = "Légendaire"},
		{minerais = {"Rubis"}, modele = "CasqueRubis", nom = "Casque de rubis", base = 75, cout = 260, rarete = "Légendaire"},
		{minerais = {"Lunarite"}, modele = "CasqueLunarite", nom = "Casque de lunarite", base = 102, cout = 330, rarete = "Mythique"},
		{minerais = {"Magmaite"}, modele = "CasqueMagmaite", nom = "Casque de magmaïte", base = 138, cout = 420, rarete = "Divin"},
		{minerais = {"Diamant"}, modele = "CasqueDiamant", nom = "Casque de diamant", base = 190, cout = 520, rarete = "Divin"},
		{minerais = {"Orichalque"}, modele = "CasqueOrichalque", nom = "Casque d'orichalque", base = 257, cout = 650, rarete = "Divin"},
		{minerais = {"Neantite"}, modele = "CasqueNeantite", nom = "Casque de néantite", base = 347, cout = 800, rarete = "Divin"},
	},
	-- Charbon + Bronze : deux modèles selon le minerai dominant (voir Forge.dominant)
	Epee = {
		{minerais = {"Charbon"}, modele = "EpeeCharbon", nom = "Épée de charbon", base = 10, cout = 25, rarete = "Commun"},
		{minerais = {"Bronze"}, modele = "EpeeBronze", nom = "Épée de bronze", base = 14, cout = 40, rarete = "Commun"},
		{minerais = {"Charbon", "Bronze"}, dominant = "Charbon", modele = "EpeeCharbonBronze", nom = "Épée de charbon et bronze", base = 19, cout = 55, rarete = "Peu commun"},
		{minerais = {"Charbon", "Bronze"}, dominant = "Bronze", modele = "EpeeBronzeCharbon", nom = "Épée de bronze et charbon", base = 26, cout = 70, rarete = "Peu commun"},
		{minerais = {"Fer"}, modele = "EpeeFerPur", nom = "Épée de fer pur", base = 36, cout = 95, rarete = "Peu commun"},
		{minerais = {"Charbon", "Fer"}, modele = "EpeeCharbonFer", nom = "Épée de charbon et fer", base = 49, cout = 130, rarete = "Rare"},
		{minerais = {"Bronze", "Fer"}, modele = "EpeeBronzeFer", nom = "Épée de bronze et fer", base = 67, cout = 175, rarete = "Rare"},
		{minerais = {"Gold"}, modele = "EpeeOr", nom = "Épée d'or", base = 91, cout = 230, rarete = "Légendaire"},
		{minerais = {"Charbon", "Gold"}, modele = "EpeeCharbonOr", nom = "Épée de charbon et or", base = 124, cout = 300, rarete = "Légendaire"},
		{minerais = {"Bronze", "Gold"}, modele = "EpeeBronzeOr", nom = "Épée de bronze et or", base = 169, cout = 380, rarete = "Mythique"},
		{minerais = {"Fer", "Gold"}, modele = "EpeeFerOr", nom = "Épée de fer et or", base = 230, cout = 480, rarete = "Divin"},
		-- butin du Léviathan des abysses (1 lunarite + 1 magmaïte = le minimum pour une épée)
		{minerais = {"Lunarite", "Magmaite"}, modele = "EpeeMarees", nom = "Lame des marées", base = 315, cout = 600, rarete = "Divin"},
		-- 2 du même minerai de la mine privée (même base qu'un palier existant, ou au-dessus des marées)
		{minerais = {"Soufre"}, modele = "EpeeSoufre", nom = "Épée de soufre", base = 14, cout = 40, rarete = "Commun"},
		{minerais = {"Quartz"}, modele = "EpeeQuartz", nom = "Épée de quartz", base = 19, cout = 55, rarete = "Peu commun"},
		{minerais = {"Argent"}, modele = "EpeeArgent", nom = "Épée d'argent", base = 36, cout = 95, rarete = "Peu commun"},
		{minerais = {"Obsidienne"}, modele = "EpeeObsidienne", nom = "Épée d'obsidienne", base = 49, cout = 130, rarete = "Rare"},
		{minerais = {"Givrite"}, modele = "EpeeGivrite", nom = "Épée de givrite", base = 67, cout = 175, rarete = "Rare"},
		{minerais = {"Emeraude"}, modele = "EpeeEmeraude", nom = "Épée d'émeraude", base = 91, cout = 230, rarete = "Légendaire"},
		{minerais = {"Rubis"}, modele = "EpeeRubis", nom = "Épée de rubis", base = 124, cout = 300, rarete = "Légendaire"},
		{minerais = {"Lunarite"}, modele = "EpeeLunarite", nom = "Épée de lunarite", base = 169, cout = 380, rarete = "Mythique"},
		{minerais = {"Magmaite"}, modele = "EpeeMagmaite", nom = "Épée de magmaïte", base = 230, cout = 480, rarete = "Divin"},
		{minerais = {"Diamant"}, modele = "EpeeDiamant", nom = "Épée de diamant", base = 315, cout = 600, rarete = "Divin"},
		{minerais = {"Orichalque"}, modele = "EpeeOrichalque", nom = "Épée d'orichalque", base = 426, cout = 750, rarete = "Divin"},
		{minerais = {"Neantite"}, modele = "EpeeNeantite", nom = "Épée de néantite", base = 576, cout = 900, rarete = "Divin"},
	},
} :: any -- {[string]: {Palier}} (rang ajouté ci-dessous)

-- Épée de base donnée à tout joueur sans épée forgée équipée (Epee.server.lua)
Forge.EPEE_BASE = {modele = "EpeeFer", nom = "Épée de fer", valeur = 6}

-- Minerai dominant d'une composition : la plus grande quantité ; à égalité, le minerai de plus haut rang
function Forge.dominant(composition: {{any}}): string?
	local id: string?, qMax, rMax = nil, -1, -1
	for _, e in composition do
		local m = Forge.MINERAIS[e[1]]
		local q = tonumber(e[2]) or 0
		if m and (q > qMax or (q == qMax and m.rang > rMax)) then
			id, qMax, rMax = m.id, q, m.rang
		end
	end
	return id
end

local function cleMinerais(ids: {string}, dominant: string?): string
	local t = table.clone(ids)
	table.sort(t)
	return table.concat(t, "+") .. (if dominant then ">" .. dominant else "")
end

local parCle: {[string]: {[string]: Palier}} = {}
local parModele: {[string]: Palier} = {}
local plafonds: {[Palier]: number} = {}
for typeId, echelle in Forge.ECHELLES do
	local ordre = {}
	for i, p in echelle do
		ordre[p] = i
	end
	table.sort(echelle, function(a, b)
		return if a.base ~= b.base then a.base < b.base else ordre[a] < ordre[b]
	end)
	parCle[typeId] = {}
	for i, p in echelle do
		p.rang = i
		parCle[typeId][cleMinerais(p.minerais, p.dominant)] = p
		parModele[p.modele] = p
		for j = i + 1, #echelle do
			if echelle[j].base > p.base then
				plafonds[p] = echelle[j].base - 1
				assert(math.floor(p.base * Forge.FACTEUR_MAX) <= plafonds[p], "[Forge] base trop proche : " .. p.modele)
				break
			end
		end
	end
end

-- Palier d'une pièce : par modèle, sinon par ses minerais (vieilles sauvegardes)
function Forge.palier(typeId: string, modele: string?, composition: {{any}}?): Palier?
	local p = if modele then parModele[modele] else nil
	if p and p.modele:sub(1, #typeId) == typeId then
		return p
	end
	local t = parCle[typeId]
	if not t then
		return nil
	end
	local ids = {}
	for _, e in composition or {} do
		table.insert(ids, tostring(e[1]))
	end
	local dominant = Forge.dominant(composition or {})
	return (dominant and t[cleMinerais(ids, dominant)]) or t[cleMinerais(ids)]
end

-- NomAffiche du modèle 3D (ArmesVoxels / ArmuresVoxels) s'il existe déjà, sinon le nom de la table
local modules: {[string]: any} = {}
local function nomAffiche(p: Palier): string
	local nomModule = if p.modele:sub(1, 4) == "Epee" then "ArmesVoxels" else "ArmuresVoxels"
	if modules[nomModule] == nil then
		local m = script.Parent:FindFirstChild(nomModule)
		local ok, res = pcall(require, m :: any)
		modules[nomModule] = if ok and type(res) == "table" then res else false
	end
	local armures = modules[nomModule]
	if armures and armures.existe(p.modele) then
		local ok, d = pcall(armures.donnees, p.modele)
		if ok and type(d) == "table" and type(d.Nom) == "string" and d.Nom ~= "" then
			return d.Nom
		end
	end
	return p.nom
end

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
		elseif (Forge.MINERAIS[id] :: any).forgeable == false then
			return nil, "Ce minerai ne se forge pas encore"
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
	local echelle = Forge.ECHELLES[t.id]
	if echelle then
		local p = Forge.palier(t.id, nil, liste)
		if not p then
			return nil, (if t.id == "Epee" then "Une épée" else "Un " .. string.lower(t.nom)) .. " se forge avec 1 ou 2 minerais"
		end
		local q = 1 + Forge.BONUS_QTE * (math.sqrt(total / t.min) - 1) / (math.sqrt(t.max / t.min) - 1)
		local m = 1
		if #liste == 2 then
			local a, c = liste[1], liste[2]
			local fort = if Forge.MINERAIS[a[1]].rang > Forge.MINERAIS[c[1]].rang then a else c
			m = 1 + Forge.BONUS_PROPORTION * (2 * fort[2] / total - 1)
		end
		local valeur = math.min(math.floor(p.base * math.min(q * m, Forge.FACTEUR_MAX)), plafonds[p] or math.huge)
		return {
			type = t.id,
			nom = nomAffiche(p),
			modele = p.modele,
			rang = p.rang,
			couleur = couleur,
			stat = t.stat,
			valeur = valeur,
			total = total,
			prix = p.cout + total * Forge.FRAIS_PAR_MINERAI,
			composition = liste,
		}, nil
	end
	local alliage = trouverAlliage(liste, total)
	local bonus, mat = 1, enumerer(liste)
	if alliage then
		bonus, mat = alliage.bonus, alliage.mat
		couleur = couleur:Lerp(alliage.couleur, 0.7)
	end
	return {
		type = t.id,
		nom = t.nom .. " en " .. mat,
		modele = t.id,
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
