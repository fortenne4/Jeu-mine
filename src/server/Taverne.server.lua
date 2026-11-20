-- Actualise uniquement les tables de la taverne des cartes déjà figées.
local ServerStorage = game:GetService("ServerStorage")
local Batiments = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Batiments"))

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 60 do
	task.wait(0.25)
end

local carte = workspace:FindFirstChild("Carte")
local village = carte and carte:FindFirstChild("Village")
local boutiques = village and village:FindFirstChild("Boutiques")
local taverne = boutiques and boutiques:FindFirstChild("Taverne")
if not (boutiques and taverne and taverne:IsA("Model")) then return end

local centre = taverne:GetPivot().Position
for _, ancienne in boutiques:GetChildren() do
	if ancienne:IsA("Model") and ancienne.Name == "Table" and ancienne:GetAttribute("VersionTableTaverne") ~= 2 then
		local plateau = ancienne:FindFirstChild("Plateau")
		if plateau and plateau:IsA("BasePart") then
			local ecart = plateau.Position - centre
			if Vector2.new(ecart.X, ecart.Z).Magnitude < 38 then
				-- L'ancien plateau cylindrique est tourné de 90° autour de Z ;
				-- retrouver le repère d'origine sans déplacer les tables latéralement.
				local repere = plateau.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, -3, 0)
				local ok, resultat = pcall(Batiments.tableTaverne, boutiques, repere)
				if ok and resultat then
					ancienne:Destroy()
				else
					warn("[Taverne] Table non remplacée : " .. tostring(resultat))
				end
			end
		end
	end
end
