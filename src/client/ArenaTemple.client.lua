-- Arène du temple (grotte −50 m) · SCRIPT CLIENT
-- Affiche l'arène lancée par ArenaTemple.lua (RemoteEvent « AreneTemple ») : grands titres (VAGUE 3, VICTOIRE…),
-- compteur en haut de l'écran (vague, ennemis restants : attributs « AreneVague » / « AreneRestants » de la grotte),
-- record personnel sur l'invite du gong (attribut joueur « RecordArene »).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UI = require(script.Parent:WaitForChild("InterfaceMine"))
local creer, coin, trait, texte = UI.creer, UI.coin, UI.trait, UI.texte

local joueur = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("AreneTemple") :: RemoteEvent

local VIOLET = Color3.fromRGB(190, 120, 255)
local OR = Color3.fromRGB(255, 210, 90)
local ROUGE = Color3.fromRGB(255, 100, 90)
local VERT = Color3.fromRGB(120, 235, 140)

local gui = creer("ScreenGui", {Name = "AreneTemple", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 24,
	Parent = joueur:WaitForChild("PlayerGui")})
local toast = UI.toast(gui)

-- grand titre
local titre = texte({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromScale(0.7, 0.12),
	Font = Enum.Font.GothamBlack, Visible = false, Parent = gui}, 80)
local contourTitre = creer("UIStroke", {Thickness = 3, Parent = titre})
local sousTitre = texte({AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.41), Size = UDim2.fromScale(0.6, 0.05),
	Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(235, 228, 215), Visible = false, Parent = gui}, 30)
creer("UIStroke", {Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.3, Parent = sousTitre})

local idTitre = 0
local function grandTitre(t: string, st: string, couleur: Color3, duree: number?)
	idTitre += 1
	local moi = idTitre
	titre.Text, sousTitre.Text = t, st
	titre.TextColor3 = couleur
	contourTitre.Color = couleur:Lerp(Color3.new(0, 0, 0), 0.8)
	titre.Visible, sousTitre.Visible = true, st ~= ""
	UI.pop(titre, 0.4)
	task.delay(duree or 2.6, function()
		if moi == idTitre then
			titre.Visible, sousTitre.Visible = false, false
		end
	end)
end

-- compteur
local plaque = creer("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromOffset(330, 44),
	BackgroundColor3 = Color3.fromRGB(20, 12, 30), BackgroundTransparency = 0.2, Visible = false, Parent = gui},
	{coin(0.35), trait(VIOLET, 2, 0.2)})
local ligne = texte({Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(235, 215, 255), Position = UDim2.fromScale(0.04, 0.12),
	Size = UDim2.fromScale(0.92, 0.76), Parent = plaque}, 22)

local function grotteAutour(pos: Vector3): Model?
	local g = workspace:FindFirstChild("Grottes")
	if not g then
		return nil
	end
	for _, m in g:GetChildren() do
		local c, d = m:GetAttribute("Centre"), m:GetAttribute("DemiTaille")
		if typeof(c) == "Vector3" and typeof(d) == "Vector3" then
			local r = pos - c
			if math.abs(r.X) < d.X and math.abs(r.Y) < d.Y and math.abs(r.Z) < d.Z then
				return m
			end
		end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(0.3)
		local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local g = r and grotteAutour(r.Position)
		local vague = g and g:GetAttribute("AreneVague")
		if g and type(vague) == "number" and vague > 0 then
			plaque.Visible = true
			ligne.Text = "ARÈNE · Vague " .. vague .. " / 8 · " .. tostring(g:GetAttribute("AreneRestants") or 0) .. " ennemis"
		else
			plaque.Visible = false
		end
	end
end)

-- record sur l'invite du gong (texte local)
ProximityPromptService.PromptShown:Connect(function(invite)
	if invite:GetAttribute("Arene") then
		local rec = joueur:GetAttribute("RecordArene") or 0
		invite.ObjectText = if rec > 0 then "Arène du temple · ton record : vague " .. rec else "Arène du temple · 8 vagues"
	end
end)

remote.OnClientEvent:Connect(function(genre, d)
	if type(d) ~= "table" then
		return
	end
	if genre == "Eveil" then
		toast("Le gong du temple s'est éveillé… frappe-le pour défier l'arène !", true)
	elseif genre == "Debut" then
		grandTitre("L'ARÈNE S'ÉVEILLE", "Survis à " .. tostring(d.total or 8) .. " vagues de gardiens", VIOLET, 2.8)
		UI.jouer("metal", 0.4)
	elseif genre == "Vague" then
		grandTitre("VAGUE " .. tostring(d.n), if d.n == d.total then "La dernière !" else "", if d.n == d.total then ROUGE else VIOLET)
		UI.jouer("metal", 0.6 + (d.n or 1) * 0.05)
	elseif genre == "VagueFinie" then
		toast("Vague " .. tostring(d.n) .. " vaincue" .. (if (d.pieces or 0) > 0 then " : +" .. d.pieces .. " pièces" else " (déjà payée)"), true)
		UI.jouer("succes")
	elseif genre == "Victoire" then
		grandTitre("VICTOIRE !", "Les 8 vagues sont vaincues" .. (if (d.bonus or 0) > 0 then " · +" .. d.bonus .. " pièces" else ""), OR, 4)
		UI.celebrer(gui, OR, "CHAMPION !")
	elseif genre == "Defaite" then
		grandTitre("L'ARÈNE SE TAIT", "Vagues vaincues : " .. tostring(d.vague or 0), ROUGE, 3.5)
	elseif genre == "Record" then
		task.delay(1.5, function()
			toast("Nouveau record de l'arène : vague " .. tostring(d.vague), true)
			UI.celebrer(gui, VERT, "RECORD !")
		end)
	end
end)

