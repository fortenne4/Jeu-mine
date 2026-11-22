-- Fragments de la carte naine · MODULE SERVEUR (ServerScriptService › Jeu › CarteNaine)
-- Les cachettes (modèles « FragmentCarte » posés par GrotteLueurs, invite « Ramasser ») donnent chacune un fragment
-- encore manquant au joueur qui les ramasse (une fois par joueur et par cachette). Le fragment est sauvegardé dans
-- son profil (Donnees.ajouterFragment) avec quelques pièces ; la carte complète rapporte un bonus.
-- Le serveur fait tout : le client ne fait qu'afficher (CarteNaine.client.lua, via le RemoteEvent « CarteNaine »).
--   CarteNaine.donnerFragment(joueur, origine) -- aussi appelé par Sanctuaire.lua (coffre du temple)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Donnees = require(script.Parent.Donnees)
local Carte = require(ReplicatedStorage:WaitForChild("Partage"):WaitForChild("CarteNaine"))

local CarteNaine = {}

local remote = ReplicatedStorage:FindFirstChild(Carte.REMOTE) :: RemoteEvent?
if not remote then
	local r = Instance.new("RemoteEvent")
	r.Name = Carte.REMOTE
	r.Parent = ReplicatedStorage
	remote = r
end
CarteNaine.remote = remote :: RemoteEvent

function CarteNaine.crediter(joueur: Player, n: number)
	local stats = joueur:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Pièces")
	if v and v:IsA("IntValue") and n > 0 then
		v.Value += math.floor(n)
	end
end

-- Donne au joueur un fragment qu'il n'a pas encore (au hasard). Renvoie l'id donné (nil si carte déjà complète).
function CarteNaine.donnerFragment(joueur: Player, origine: string): string?
	local p = Donnees.profil(joueur)
	if not p then
		return nil
	end
	local manquants = {}
	for _, f in Carte.FRAGMENTS do
		if not p.fragments[f.id] then
			table.insert(manquants, f.id)
		end
	end
	if #manquants == 0 then
		CarteNaine.crediter(joueur, Carte.PIECES_DOUBLON)
		CarteNaine.remote:FireClient(joueur, "Doublon", {pieces = Carte.PIECES_DOUBLON, origine = origine})
		return nil
	end
	local id = manquants[math.random(1, #manquants)]
	if not Donnees.ajouterFragment(joueur, id) then
		return nil
	end
	local complete = #manquants == 1
	local pieces = Carte.PIECES_FRAGMENT + (if complete then Carte.PIECES_CARTE_COMPLETE else 0)
	CarteNaine.crediter(joueur, pieces)
	CarteNaine.remote:FireClient(joueur, "Fragment", {id = id, pieces = pieces, complete = complete, origine = origine})
	return id
end

local function racine(joueur: Player): BasePart?
	local perso = joueur.Character
	local r = perso and perso:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

ProximityPromptService.PromptTriggered:Connect(function(invite: ProximityPrompt, joueur: Player)
	if not invite:GetAttribute("FragmentCarte") then
		return
	end
	local part = invite.Parent
	local cache = part and part.Parent
	local r = racine(joueur)
	if not (part and part:IsA("BasePart") and cache and cache:IsA("Model") and r) then
		return
	end
	if (r.Position - part.Position).Magnitude > invite.MaxActivationDistance + 4 then
		return
	end
	local pris = cache:GetAttribute("PrisPar")
	pris = if type(pris) == "string" then pris else ","
	local marque = "," .. joueur.UserId .. ","
	if pris:find(marque, 1, true) then
		return
	end
	cache:SetAttribute("PrisPar", pris .. joueur.UserId .. ",")
	CarteNaine.donnerFragment(joueur, "cachette")
end)

return CarteNaine
