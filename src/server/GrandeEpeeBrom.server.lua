-- Épée chauffée décorative, posée sur la grande enclume de Brom.
local SWORD_COLOR = Color3.fromRGB(255, 40, 20)
local SWORD_SCALE = 1.0
local LUMIERE_PORTEE = 8
local LUMIERE_INTENSITE = 0.9

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local village = carte and carte:FindFirstChild("Village")
local forge = village and village:FindFirstChild("Forge", true)
local tableEnclume = forge and forge:FindFirstChild("Table")
if not (forge and tableEnclume and tableEnclume:IsA("BasePart")) then
	warn("[GrandeEpeeBrom] Grande enclume introuvable")
	return
end
-- Anciennes cartes figées : retirer uniquement le marteau décoratif posé
-- près de la grande enclume, jamais le marteau porté par Brom.
for _, nom in {"Marteau", "TeteMarteau"} do
	local objet = forge:FindFirstChild(nom)
	if objet and objet:IsA("BasePart") and (objet.Position - tableEnclume.Position).Magnitude < 3 then
		objet:Destroy()
	end
end
if forge:FindFirstChild("Forge_EpeeRouge") then return end

-- Ces deux maillages sont consacrés à l'ancienne lame et à sa garde.
-- On les masque sans les détruire : la cinématique utilise encore la position
-- de la lame comme repère. Le manche et l'enclume sont fusionnés au corps.
local brom = village:FindFirstChild("Brom", true)
local corps = brom and brom:FindFirstChild("Corps")
if corps then
	for _, nom in {"Brom_Corps_Lueur", "Brom_Corps_Or"} do
		local ancien = corps:FindFirstChild(nom)
		if ancien and ancien:IsA("BasePart") then ancien.Transparency = 1 end
	end
end

local epee = Instance.new("Model")
epee.Name = "Forge_EpeeRouge"
local base = tableEnclume.CFrame * CFrame.new(0, tableEnclume.Size.Y / 2, 0)
local function piece(nom, taille, position, couleur, materiau)
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille * SWORD_SCALE
	p.CFrame = base * CFrame.new(position * SWORD_SCALE)
	p.Color, p.Material = couleur, materiau
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = epee
	return p
end

-- Les bases des pièces sont à la hauteur de la table, sans la traverser.
local lame = piece("Lame", Vector3.new(2.3, 0.12, 0.24), Vector3.new(-0.22, 0.06, 0), SWORD_COLOR, Enum.Material.Neon)
piece("Garde", Vector3.new(0.14, 0.12, 0.62), Vector3.new(0.99, 0.06, 0), Color3.fromRGB(48, 42, 39), Enum.Material.Metal)
piece("Poignee", Vector3.new(0.56, 0.12, 0.14), Vector3.new(1.33, 0.06, 0), Color3.fromRGB(64, 36, 26), Enum.Material.Leather)
piece("Pommeau", Vector3.new(0.16, 0.14, 0.18), Vector3.new(1.68, 0.07, 0), Color3.fromRGB(48, 42, 39), Enum.Material.Metal)
local lumiere = Instance.new("PointLight")
lumiere.Name = "LueurEpee"
lumiere.Color = Color3.fromRGB(255, 95, 35)
lumiere.Brightness, lumiere.Range, lumiere.Shadows = LUMIERE_INTENSITE, LUMIERE_PORTEE, false
lumiere.Parent = lame
epee.PrimaryPart = lame
epee.Parent = forge
