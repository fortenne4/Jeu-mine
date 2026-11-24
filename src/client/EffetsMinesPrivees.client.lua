-- Effets spéciaux des nœuds de minerai dans les mines privées · SCRIPT CLIENT.
-- Chaque minerai tagué « Minerai » dont le visuel a des « speciaux » (Émeraude, Rubis, Lunarite, Magmaïte,
-- Diamant, Orichalque, Néantite : Partage › MineraisPropositions) reçoit en local les mêmes effets que dans la
-- vitrine de la plaine (EffetsMinerais), à l'échelle du nœud (attribut « Taille »). Animés seulement près de la
-- caméra ; retirés dès que le minerai est cassé. Rien n'est répliqué : aucun effet sur le serveur.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MineraisModeles = require(game:GetService("ReplicatedStorage"):WaitForChild("Partage"):WaitForChild("MineraisModeles"))
local EffetsMinerais = require(script.Parent:WaitForChild("EffetsMinerais"))

local TAG = "Minerai"
local PORTEE = 110 -- au-delà, les animations s'arrêtent

type Actif = {animations: {(number, number) -> ()}, position: Vector3, crees: {Instance}}
local actifs: {[BasePart]: Actif} = {}

local function nettoyer(coeur: BasePart)
	local a = actifs[coeur]
	if not a then
		return
	end
	actifs[coeur] = nil
	for _, o in a.crees do
		o:Destroy()
	end
end

local function ajouter(coeur: Instance)
	if not coeur:IsA("BasePart") or actifs[coeur] or not coeur:GetAttribute("Proprietaire") then
		return
	end
	local id = coeur:GetAttribute("Type")
	local def = type(id) == "string" and MineraisModeles.VISUEL[id] or nil
	local modele = coeur.Parent
	if not def or not (def :: any).speciaux or not modele then
		return
	end
	-- les effets vont dans le modèle du nœud (les néons du rocher pulsent aussi) ; on retient ce qu'on a créé
	local avant: {[Instance]: boolean} = {}
	for _, o in modele:GetChildren() do
		avant[o] = true
	end
	for _, o in coeur:GetChildren() do
		avant[o] = true
	end
	local p = coeur.Position
	local r = Random.new(math.floor(p.X * 7 + p.Y * 13 + p.Z * 3))
	local taille = coeur:GetAttribute("Taille")
	local animations = EffetsMinerais.ajouter(def, modele, coeur, r, p, if type(taille) == "number" then taille else nil)
	local crees = {}
	for _, parent in {modele, coeur} do
		for _, o in parent:GetChildren() do
			if not avant[o] then
				table.insert(crees, o)
			end
		end
	end
	actifs[coeur] = {animations = animations, position = p, crees = crees}
	coeur.Destroying:Once(function()
		nettoyer(coeur)
	end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(coeur)
	task.defer(ajouter, coeur) -- laisse arriver les attributs et le reste du modèle
end)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(coeur)
	if coeur:IsA("BasePart") then
		nettoyer(coeur)
	end
end)
for _, coeur in CollectionService:GetTagged(TAG) do
	task.defer(ajouter, coeur)
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam or next(actifs) == nil then
		return
	end
	local oeil = cam.CFrame.Position
	local t = os.clock()
	for _, a in actifs do
		if (a.position - oeil).Magnitude <= PORTEE then
			for _, f in a.animations do
				f(t, dt)
			end
		end
	end
end)
