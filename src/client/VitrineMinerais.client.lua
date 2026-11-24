-- Vitrine locale des minerais dans la plaine des mobs (à gauche de l'arrivée) : les 4 minerais du jeu + les 12
-- nouveaux minerais de la mine privée (MineraisPropositions), en grille de 5 colonnes, comme l'atelier previews/minerais.
-- Rien n'est minable ici : décor client uniquement. Les effets spéciaux (Épique et +) sont animés en local,
-- seulement quand le joueur est près de la vitrine.
local RunService = game:GetService("RunService")
local Partage = game:GetService("ReplicatedStorage"):WaitForChild("Partage")
local MineraisModeles = require(Partage:WaitForChild("MineraisModeles"))
local Propositions = require(Partage:WaitForChild("MineraisPropositions"))

local ORIGINE = Vector3.new(4925, 0, 195) -- centre de la grille, sol de la plaine à y = 0 (arrivée en 5000, z 230)
local COLONNES, ECART = 5, 8.5
local PORTEE = 170 -- au-delà, les animations s'arrêtent

workspace:WaitForChild("PlaineMobs")

local dossier = Instance.new("Folder")
dossier.Name = "VitrineMinerais"

local EffetsMinerais = require(script.Parent:WaitForChild("EffetsMinerais")) -- effets spéciaux (Épique et +)

local function etiquette(adornee: BasePart, hauteur: number, nom: string, sous: string, couleur: Color3)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(170, 44)
	b.StudsOffsetWorldSpace = Vector3.new(0, hauteur, 0)
	b.MaxDistance = 90
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 0.62)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = couleur
	t.TextStrokeTransparency = 0.3
	t.Text = nom
	t.Parent = b
	local st = Instance.new("TextLabel")
	st.Size = UDim2.fromScale(1, 0.38)
	st.Position = UDim2.fromScale(0, 0.62)
	st.BackgroundTransparency = 1
	st.Font = Enum.Font.GothamMedium
	st.TextScaled = true
	st.TextColor3 = Color3.fromRGB(235, 225, 210)
	st.TextStrokeTransparency = 0.4
	st.Text = sous
	st.Parent = b
	b.Adornee = adornee
	b.Parent = adornee
end

-- Fonctions appelées à chaque image (t, dt) quand le joueur est proche
local animations: {(number, number) -> ()} = {}

-- Liste : les 4 du jeu puis les 12 nouveaux (même ordre que l'atelier)
local liste = {}
for _, id in MineraisModeles.ORDRE do
	table.insert(liste, {id = id, def = MineraisModeles.VISUEL[id], enJeu = true})
end
for _, id in Propositions.ORDRE do
	table.insert(liste, {id = id, def = Propositions.VISUEL[id], enJeu = false})
end

local lignes = math.ceil(#liste / COLONNES)
for i, e in liste do
	local idx = i - 1
	local x = (idx % COLONNES - (COLONNES - 1) / 2) * ECART
	local z = (math.floor(idx / COLONNES) - (lignes - 1) / 2) * ECART
	local sol = CFrame.new(ORIGINE + Vector3.new(x, 0, z))
	local r = Random.new(7 + idx * 31)
	local modele, coeur = MineraisModeles.construire(e.id, sol, r, false, e.def)
	modele.Name = "Vitrine_" .. e.id
	local def = e.def
	local cPos = sol.Position + Vector3.new(0, 1.25 * def.taille, 0)
	if def.speciaux then
		for _, a in EffetsMinerais.ajouter(def, modele, coeur, r, cPos) do
			table.insert(animations, a)
		end
	end
	local couleur = Propositions.COULEURS_RARETE[def.rarete] or Color3.new(1, 1, 1)
	etiquette(coeur, 3.4 * def.taille, Propositions.NOMS[e.id] or e.id,
		def.rarete .. (if e.enJeu then " · en jeu" else " · mine privée"), couleur)
	modele.Parent = dossier
end

-- Panneau au-dessus de la grille
local panneau = Instance.new("Part")
panneau.Name = "Panneau"
panneau.Anchored, panneau.CanCollide, panneau.CanQuery, panneau.CanTouch = true, false, false, false
panneau.Transparency = 1
panneau.Size = Vector3.one
panneau.Position = ORIGINE + Vector3.new(0, 9, (lignes / 2) * ECART)
panneau.Parent = dossier
etiquette(panneau, 0, "MINERAIS", "4 de départ · 12 de la mine privée", Color3.fromRGB(242, 193, 78))

dossier.Parent = workspace

local camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera or camera
	if not cam or (cam.CFrame.Position - ORIGINE).Magnitude > PORTEE then
		return
	end
	local t = os.clock()
	for _, f in animations do
		f(t, dt)
	end
end)
