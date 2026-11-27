-- Construit la carte au lancement du serveur (sauf si elle a déjà été figée dans la place).
-- Les joueurs n'apparaissent qu'une fois la carte prête.
local ServerStorage = game:GetService("ServerStorage")

-- Une erreur de décoration sur une carte déjà jouable ne doit pas bloquer l'apparition.
task.delay(35, function()
	if workspace:GetAttribute("ApparitionAutorisee") then return end
	local carte = workspace:FindFirstChild("Carte")
	local village = carte and carte:FindFirstChild("Village")
	if village and village:FindFirstChild("Apparitions") then
		local monde = ServerStorage:WaitForChild("Monde")
		require(monde:WaitForChild("Village")).preparerApparition(village)
		warn("[Monde] Préparation incomplète. Apparitions ouvertes sur le village disponible.")
		workspace:SetAttribute("MondeConstruit", true)
		workspace:SetAttribute("ApparitionAutorisee", true)
	end
end)

-- Les cartes figées conservent leurs anciennes enseignes : harmoniser uniquement
-- les textes de surface créés par Outils.texte, sans toucher aux interfaces.
local function harmoniserEnseignes(carte)
    for _, objet in carte:GetDescendants() do
        if objet:IsA("SurfaceGui") and (objet.Name == "TexteFront" or objet.Name == "TexteBack") then
            local etiquette = objet:FindFirstChild("Label")
            if etiquette and etiquette:IsA("TextLabel") then
                etiquette.Font = Enum.Font.Antique
            end
        end
    end
end
-- Carte figée : on la garde, sauf si les modèles 3D importés ont changé depuis
local carte = workspace:FindFirstChild("Carte")
if carte then
	local monde = ServerStorage:WaitForChild("Monde")
	local Modeles3D = require(monde:WaitForChild("Modeles3D"))
	if (carte:GetAttribute("Modeles3D") or 0) == Modeles3D.signature() then
		local village = carte:FindFirstChild("Village")
		if village then
			local Village = require(monde:WaitForChild("Village"))
			Village.retirerSauleDuPont(village)
			Village.preparerFontaine(village)
			Village.preparerApparition(village)
			Village.preparerToits(village)
			Village.preparerSentiers(village)
			local okMoulin, erreurMoulin = pcall(Village.preparerMoulin, village)
			if not okMoulin then warn("[Monde] Moulin de la rive sud non construit : " .. tostring(erreurMoulin)) end
			local okBancs, erreurBancs = pcall(Village.preparerBancs, village)
			if not okBancs then warn("[Monde] Bancs de la place non mis à jour : " .. tostring(erreurBancs)) end
			local okAteliers, erreurAteliers = pcall(Village.preparerAteliers, village)
			if not okAteliers then warn("[Monde] Fourneau / puits / enseignes non mis à jour : " .. tostring(erreurAteliers)) end
			require(monde:WaitForChild("DecorFontaine")).preparer(village)
			-- place du boss du village : retire la Maison13 figée, aplanit et pose la place
			local okBoss, erreurBoss = pcall(Village.preparerCercleBoss, village)
			if not okBoss then warn("[Monde] Place du boss non construite : " .. tostring(erreurBoss)) end
		end
		local mine = carte:FindFirstChild("Mine")
		if mine then
			local ok, erreur = pcall(require(monde:WaitForChild("Mine")).preparerVoie, mine)
			if not ok then warn("[Monde] Mise à jour de la mine interrompue : " .. tostring(erreur)) end
		end
		if not carte:FindFirstChild("HorizonMine") then require(monde:WaitForChild("HorizonMine")).construire(carte) end
		if not carte:FindFirstChild("DecorVillage") then require(monde:WaitForChild("DecorVillage")).construire(carte) end
		require(monde:WaitForChild("MineursDecor")).construire(carte)
		harmoniserEnseignes(carte)
		pcall(require(monde:WaitForChild("Batiments")).degagerTonneaux, carte)
		-- Après degagerTonneaux : le chemin du moulin pousse les tonneaux qui débordent dessus
		local villageFige = carte:FindFirstChild("Village")
		if villageFige then
			local okChemin, erreurChemin = pcall(require(monde:WaitForChild("Village")).preparerCheminMoulin, villageFige)
			if not okChemin then warn("[Monde] Chemin du moulin non tracé : " .. tostring(erreurChemin)) end
		end
		require(monde:WaitForChild("MursInvisibles")).construire(carte)
		workspace:SetAttribute("MondeConstruit", true)
		workspace:SetAttribute("ApparitionAutorisee", true)
		return
	end
	print("[Monde] Les modèles 3D ont changé : reconstruction de la carte")
end

local Monde = require(ServerStorage:WaitForChild("Monde"))
local ok, erreur = pcall(Monde.construire)
if not ok then
	warn("[Monde] Erreur pendant la construction : " .. tostring(erreur))
end
local carteConstruite = workspace:FindFirstChild("Carte")
if carteConstruite then
	harmoniserEnseignes(carteConstruite)
	pcall(require(ServerStorage:WaitForChild("Monde"):WaitForChild("Batiments")).degagerTonneaux, carteConstruite)
	local villageConstruit = carteConstruite:FindFirstChild("Village")
	if villageConstruit then
		local Village = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Village"))
		local okChemin, erreurChemin = pcall(Village.preparerCheminMoulin, villageConstruit)
		if not okChemin then warn("[Monde] Chemin du moulin non tracé : " .. tostring(erreurChemin)) end
	end
end
workspace:SetAttribute("MondeConstruit", true)
workspace:SetAttribute("ApparitionAutorisee", true)
