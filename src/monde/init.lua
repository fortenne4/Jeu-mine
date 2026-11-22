--[[ Monde : construit toute la carte (terrain, village, mine, ambiance).

	En jeu : le script serveur "Monde" l'appelle au lancement si la carte n'existe pas encore.

	Pour figer la carte dans ta place (et la retoucher à la main dans Studio), colle ceci
	dans la barre de commande de Studio (Affichage > Barre de commande), hors mode Play :
		require(game.ServerStorage.Monde).construire()
	puis sauvegarde la place. Le script verra le dossier "Carte" et ne reconstruira plus rien.
	Pour tout régénérer après une modification du code : supprime "Carte" et relance la commande.
]]
local Ambiance = require(script.Ambiance)
local Terrain = require(script.Terrain)
local Village = require(script.Village)
local Mine = require(script.Mine)
local Modeles3D = require(script.Modeles3D)
local HorizonMine = require(script.HorizonMine)
local DecorVillage = require(script.DecorVillage)
local DecorFontaine = require(script.DecorFontaine)
local MineursDecor = require(script.MineursDecor)
local Bordures = require(script.Bordures)

local Monde = {}

function Monde.construire()
	local debut = os.clock()
	Modeles3D.recharger()
	local nb = #Modeles3D.variantes(".")
	if nb > 0 then
		print(string.format("[Monde] %d modèles 3D trouvés dans ServerStorage.Modeles3D", nb))
		-- Diagnostic d'affichage : quelques pièces importées (maillage, taille, transparence)
		for _, nom in {"Gaspard", "Lierre1", "Falaise1", "Auberge"} do
			local pieces = Modeles3D.pieces(nom)
			if pieces then
				local p: any = pieces[1]
				local mn, mx = Modeles3D.boite(pieces)
				print(string.format("[Monde] %s : %d pièces, boîte %s, ex. %s MeshId=%s Taille=%s Transp=%.2f Classe=%s",
					nom, #pieces, tostring(mx - mn), p.Name, tostring(p.MeshId), tostring(p.Size), p.Transparency, p.ClassName))
			end
		end
	else
		-- Diagnostic : où sont passés les modèles importés ?
		local dossier = game:GetService("ServerStorage"):FindFirstChild("Modeles3D")
		if not dossier then
			local noms = {}
			for _, e in game:GetService("ServerStorage"):GetChildren() do
				table.insert(noms, e.Name .. " (" .. e.ClassName .. ")")
			end
			warn("[Monde] Pas de dossier ServerStorage.Modeles3D. Contenu de ServerStorage : " .. table.concat(noms, ", "))
		else
			local classes, exemples = {}, {}
			for _, d in dossier:GetDescendants() do
				classes[d.ClassName] = (classes[d.ClassName] or 0) + 1
				if #exemples < 8 and d:IsA("BasePart") then
					table.insert(exemples, d.Name)
				end
			end
			local resume = {}
			for c, n in classes do
				table.insert(resume, c .. "=" .. n)
			end
			warn("[Monde] Modeles3D existe mais aucun modèle reconnu. Contenu : " .. table.concat(resume, ", ")
				.. " | exemples de noms : " .. table.concat(exemples, ", "))
		end
		for _, e in workspace:GetChildren() do
			if e.Name == "PNJ" or e.Name == "Lierre" or e.Name == "Rochers" then
				warn("[Monde] « " .. e.Name .. " » est encore dans Workspace : glisse-le dans ServerStorage › Modeles3D")
			end
		end
	end

	-- La plaque et le spawn du modèle Roblox par défaut gêneraient la vallée et la mine
	for _, nom in {"Baseplate", "SpawnLocation"} do
		local v = workspace:FindFirstChild(nom)
		if v and v:IsA("BasePart") then
			v:Destroy()
		end
	end
	local ancienne = workspace:FindFirstChild("Carte")
	if ancienne then
		ancienne:Destroy()
	end

	local carte = Instance.new("Folder")
	carte.Name = "Carte"

	Ambiance.appliquer()
	Terrain.construire()
	Village.construire(carte)
	Mine.construire(carte)
	HorizonMine.construire(carte)
	DecorVillage.construire(carte)
	DecorFontaine.preparer(carte:WaitForChild("Village"))
	MineursDecor.construire(carte)
	local ok, err = pcall(Bordures.construire, carte) -- décor de bordure : ne doit jamais empêcher le jeu de démarrer
	if not ok then
		warn("[Monde] Bordures non construites : " .. tostring(err))
	end
	-- dernier passage : aucun arbre, rocher ou falaise sur une rue ou dans un bâtiment
	local okDegager, errDegager = pcall(Village.degager, carte)
	if not okDegager then
		warn("[Monde] Dégagement du village impossible : " .. tostring(errDegager))
	end
	-- tout dernier : la mine souterraine reste propre (aucun décor extérieur, matériaux d'origine)
	local okMine, errMine = pcall(Terrain.delimiterMine, carte)
	if not okMine then
		warn("[Monde] Délimitation de la mine impossible : " .. tostring(errMine))
	end

	carte:SetAttribute("Modeles3D", Modeles3D.signature())
	carte.Parent = workspace
	workspace:SetAttribute("MondeConstruit", true)
	print(string.format("[Monde] Carte construite en %.1f s", os.clock() - debut))
	return carte
end

return Monde
