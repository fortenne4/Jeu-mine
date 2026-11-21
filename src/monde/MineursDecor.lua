-- Personnages d'ambiance du village, séparés des PNJ de service.
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local MineursDecor = {}

local EMPLACEMENTS = {
	{position = Vector3.new(-36, 0, -28), cible = Vector3.new(-44, 0, -12),
		haut = Color3.fromRGB(96, 70, 62), bas = Color3.fromRGB(53, 47, 48), barbe = Color3.fromRGB(86, 57, 38)},
	{position = Vector3.new(34, 0, 25), cible = Vector3.new(47, 0, 22),
		haut = Color3.fromRGB(77, 77, 68), bas = Color3.fromRGB(57, 48, 44), barbe = Color3.fromRGB(66, 53, 46)},
}

function MineursDecor.construire(carte)
	local ancien = carte:FindFirstChild("MineursDecoratifs")
	if ancien then return ancien end
	local groupe = O.modele(carte, "MineursDecoratifs")
	for index, e in EMPLACEMENTS do
		local cf = CFrame.lookAt(e.position, e.cible)
		local mineur = B.pnj(groupe, cf, "MineurDecor" .. index, "Mineur", {
			avatar = false, haut = e.haut, bas = e.bas, barbe = e.barbe,
			chapeau = Color3.fromRGB(64, 48, 37), tablier = Color3.fromRGB(80, 57, 45), outil = "pioche",
		})
		-- Aucun panneau de dialogue ni volume bloquant sur ces figurants.
		for _, objet in mineur:GetDescendants() do
			if objet:IsA("BillboardGui") or objet:IsA("ProximityPrompt") then
				objet:Destroy()
			elseif objet:IsA("BasePart") then
				objet.CanCollide = false
				objet.CanTouch = false
			end
		end
	end
	return groupe
end

return MineursDecor
