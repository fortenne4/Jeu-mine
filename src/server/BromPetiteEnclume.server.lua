-- Cache la petite enclume fusionnée au corps de Brom sans perdre les embouts
-- métalliques des bottes qui se trouvent dans le même maillage Blender.
-- Les pièces d'origine restent présentes pour les références et les clones.
local LARGEUR_SEMELLES_SOURCE = 2 * (0.575 + 0.51)
local ECART_PIED_SOURCE = 0.575
local Y_EMBOUT_DEPUIS_SEMELLE = 0.30 - 0.07
local Z_EMBOUT_DEPUIS_SEMELLE = -0.72 - (-0.20)
local DIAMETRES_EMBOUT_SOURCE = Vector3.new(0.72, 0.48, 0.48)

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local carte = workspace:FindFirstChild("Carte")
local village = carte and carte:FindFirstChild("Village")
local brom = village and village:FindFirstChild("Brom", true)
local corps = brom and brom:FindFirstChild("Corps")
local acier = corps and corps:FindFirstChild("Brom_Corps_Acier")
local bois = corps and corps:FindFirstChild("Brom_Corps_Bois")
local semelle = corps and corps:FindFirstChild("Brom_Corps_Semelle")
if not (acier and acier:IsA("MeshPart") and bois and bois:IsA("MeshPart") and semelle and semelle:IsA("MeshPart")) then
	warn("[BromPetiteEnclume] Maillages de Brom incomplets : décor inchangé")
	return
end
if corps:FindFirstChild("Brom_ProtegeBottes") then return end

-- Positions issues de jambes() dans blender/nains.py. Les sphères conservent
-- les proportions d'origine ; leur contour peut différer légèrement du mesh.
local echelle = semelle.Size.X / LARGEUR_SEMELLES_SOURCE
local protections = Instance.new("Model")
protections.Name = "Brom_ProtegeBottes"
for _, cote in {-1, 1} do
	local p = Instance.new("Part")
	p.Name = if cote < 0 then "EmboutGauche" else "EmboutDroit"
	p.Shape = Enum.PartType.Ball
	p.Size = DIAMETRES_EMBOUT_SOURCE * echelle
	p.CFrame = semelle.CFrame * CFrame.new(cote * ECART_PIED_SOURCE * echelle,
		Y_EMBOUT_DEPUIS_SEMELLE * echelle, Z_EMBOUT_DEPUIS_SEMELLE * echelle)
	p.Color, p.Material, p.Reflectance = acier.Color, acier.Material, acier.Reflectance
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Parent = protections
end
protections.Parent = corps
acier.Transparency = 1
bois.Transparency = 1
