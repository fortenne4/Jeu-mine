-- Plaine des mobs : pad au village <-> grande plaine lointaine. Décompte et TP gérés par le serveur.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local O = require(ServerStorage:WaitForChild("Monde"):WaitForChild("Outils"))
local M, C = O.M, O.C

local PAD_VILLAGE = Vector3.new(27, 2, 0)
local PLAINE = Vector3.new(5000, 0, 0)
local ARRIVEE_PLAINE = CFrame.lookAt(PLAINE + Vector3.new(0, 3.5, 230), PLAINE + Vector3.new(0, 3.5, 0))
local PAD_PLAINE = PLAINE + Vector3.new(0, 0, 255)
local ARRIVEE_VILLAGE = CFrame.lookAt(Vector3.new(19, 5.5, 0), Vector3.new(40, 5.5, 0))
local RAYON, DUREE, PAS = 4, 3, 0.2

local dossier = workspace:FindFirstChild("PlaineMobs")
if dossier then
	dossier:Destroy()
end
dossier = Instance.new("Folder")
dossier.Name = "PlaineMobs"

local function pad(parent, pos, couleur, texte)
	local p = O.decor(O.cylindre(parent, 0.3, RAYON * 2, CFrame.new(pos + Vector3.new(0, 0.55, 0)), couleur, M.Neon, "Pad"))
	O.lumiere(p, couleur, 1.5, 14)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(220, 46)
	b.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
	b.MaxDistance = 150
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = couleur
	t.TextStrokeTransparency = 0.3
	t.Text = texte
	t.Parent = b
	b.Parent = p
	return p
end

local sol = O.bloc(dossier, Vector3.new(600, 4, 600), CFrame.new(PLAINE - Vector3.new(0, 2, 0)), Color3.fromRGB(86, 140, 62), M.Herbe, "Sol")
sol.Locked = true
local zone = O.decor(O.bloc(dossier, Vector3.new(300, 1, 300), CFrame.new(PLAINE + Vector3.new(0, 0.5, 0)), C.Cristal, M.Lisse, "ZoneMobs"))
zone.Transparency = 1
local arrivee = O.decor(O.bloc(dossier, Vector3.new(1, 1, 1), ARRIVEE_PLAINE, C.Cristal, M.Lisse, "Arrivee"))
arrivee.Transparency = 1

local pads = {
	{pos = PAD_VILLAGE, cible = ARRIVEE_PLAINE},
	{pos = PAD_PLAINE, cible = ARRIVEE_VILLAGE},
}
pad(dossier, PAD_VILLAGE, Color3.fromRGB(120, 255, 120), "Plaine des mobs")
pad(dossier, PAD_PLAINE, C.Cristal, "Retour au village")
dossier.Parent = workspace

local etats = {} -- [joueur] = {pad, fin}

local function surPad(racine)
	local p = racine.Position
	for _, d in pads do
		local ecart = p - d.pos
		if math.abs(ecart.Y - 3) < 5 and ecart.X * ecart.X + ecart.Z * ecart.Z < RAYON * RAYON then
			return d
		end
	end
end

Players.PlayerRemoving:Connect(function(j)
	etats[j] = nil
end)

while true do
	local t = os.clock()
	for _, j in Players:GetPlayers() do
		local perso = j.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart")
		local d = racine and surPad(racine)
		local e = etats[j]
		if not d then
			if e then
				etats[j] = nil
				j:SetAttribute("DecompteTP", nil)
			end
		elseif not e or e.pad ~= d then
			etats[j] = {pad = d, fin = t + DUREE}
			j:SetAttribute("DecompteTP", DUREE)
		else
			local reste = math.ceil(e.fin - t)
			if reste <= 0 then
				etats[j] = nil
				j:SetAttribute("DecompteTP", nil)
				task.spawn(function()
					pcall(j.RequestStreamAroundAsync, j, d.cible.Position, 2)
					if racine.Parent and j.Character == perso then
						perso:PivotTo(d.cible)
					end
				end)
			elseif reste ~= j:GetAttribute("DecompteTP") then
				j:SetAttribute("DecompteTP", reste)
			end
		end
	end
	task.wait(PAS)
end
