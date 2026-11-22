-- Personnages d'ambiance du village, séparés des PNJ de service.
local B = require(script.Parent.Batiments)
local O = require(script.Parent.Outils)

local MineursDecor = {}

-- Les deux figurants (près de la boutique de minerais et sous l'auvent est) ont été retirés :
-- ajouter une entrée ici pour en remettre un.
local EMPLACEMENTS = {}

function MineursDecor.construire(carte)
	local ancien = carte:FindFirstChild("MineursDecoratifs")
	if ancien then
		-- carte figée : on enlève aussi les figurants déjà enregistrés dans la place
		if #EMPLACEMENTS == 0 then ancien:Destroy() return nil end
		return ancien
	end
	if #EMPLACEMENTS == 0 then return nil end
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
