-- Construit la carte au lancement du serveur (sauf si elle a déjà été figée dans la place).
-- Les joueurs n'apparaissent qu'une fois la carte prête.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

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
			Village.preparerFontaine(village)
			Village.preparerToits(village)
			Village.preparerSentiers(village)
			local okAteliers, erreurAteliers = pcall(Village.preparerAteliers, village)
			if not okAteliers then warn("[Monde] Fourneau / puits / enseignes non mis à jour : " .. tostring(erreurAteliers)) end
			require(monde:WaitForChild("DecorFontaine")).preparer(village)
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
		workspace:SetAttribute("MondeConstruit", true)
		return
	end
	print("[Monde] Les modèles 3D ont changé : reconstruction de la carte")
end

Players.CharacterAutoLoads = false

local Monde = require(ServerStorage:WaitForChild("Monde"))
local ok, erreur = pcall(Monde.construire)
if not ok then
	warn("[Monde] Erreur pendant la construction : " .. tostring(erreur))
end
local carteConstruite = workspace:FindFirstChild("Carte")
if carteConstruite then
	harmoniserEnseignes(carteConstruite)
	pcall(require(ServerStorage:WaitForChild("Monde"):WaitForChild("Batiments")).degagerTonneaux, carteConstruite)
end
workspace:SetAttribute("MondeConstruit", true)

Players.CharacterAutoLoads = true
for _, joueur in Players:GetPlayers() do
	if not joueur.Character then
		task.spawn(function()
			joueur:LoadCharacter()
		end)
	end
end
