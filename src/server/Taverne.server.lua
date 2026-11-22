-- Actualise uniquement les tables de la taverne des cartes déjà figées.
local ServerStorage = game:GetService("ServerStorage")
local Batiments = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Batiments"))
local Lampadaires = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Lampadaires"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do
	task.wait(0.25)
end

local carte = workspace:FindFirstChild("Carte")
local village = carte and carte:FindFirstChild("Village")
local boutiques = village and village:FindFirstChild("Boutiques")
local ensemble = boutiques and boutiques:FindFirstChild("EnsembleTaverne")
local taverne = boutiques and boutiques:FindFirstChild("Taverne", true)
if not (boutiques and taverne and taverne:IsA("Model")) then return end

-- Les deux tonneaux contre le mur peuvent provenir du modèle de maison importé ;
-- ils sont préparés et ajustés au sol lors de la construction du monde.
local margot = ensemble and ensemble:FindFirstChild("Margot")
if margot and margot:IsA("Model") then
	local tonneauProche, distance = nil, math.huge
	for _, tonneau in taverne:GetDescendants() do
		local couvercle = tonneau:IsA("Model") and tonneau.Name == "Tonneau" and tonneau:FindFirstChild("Couvercle")
		if couvercle and couvercle:IsA("BasePart") then
			local ecart = (couvercle.Position - margot:GetPivot().Position).Magnitude
			if ecart < distance then tonneauProche, distance = tonneau, ecart end
		end
	end
	if tonneauProche and distance < 16 and not tonneauProche:FindFirstChild("LanterneDerriereMargot") then
		local couvercle = tonneauProche:FindFirstChild("Couvercle")
		local haut = couvercle.Position + Vector3.new(0, couvercle.Size.X / 2 + 0.55, 0)
		local lanterne = Lampadaires.lanterne(tonneauProche, CFrame.new(haut), nil, 18)
		lanterne.Name = "LanterneDerriereMargot"
	end
end

local centre = taverne:GetPivot().Position
for _, ancienne in (ensemble or boutiques):GetChildren() do
	if ancienne:IsA("Model") and ancienne.Name == "Table" and ancienne:GetAttribute("VersionTableTaverne") ~= 2 then
		local plateau = ancienne:FindFirstChild("Plateau")
		if plateau and plateau:IsA("BasePart") then
			local ecart = plateau.Position - centre
			if Vector2.new(ecart.X, ecart.Z).Magnitude < 38 then
				-- L'ancien plateau cylindrique est tourné de 90° autour de Z ;
				-- retrouver le repère d'origine sans déplacer les tables latéralement.
				local repere = plateau.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, -3, 0)
				local ok, resultat = pcall(Batiments.tableTaverne, ensemble or boutiques, repere)
				if ok and resultat then
					ancienne:Destroy()
				else
					warn("[Taverne] Table non remplacée : " .. tostring(resultat))
				end
			end
		end
	end
end
