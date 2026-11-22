-- Bancs de la place : la touche E assied le joueur sur la place libre du banc.
-- Le serveur vérifie la distance et que la place n'est pas déjà prise.
local ProximityPromptService = game:GetService("ProximityPromptService")

ProximityPromptService.PromptTriggered:Connect(function(invite, joueur)
	if invite.Name ~= "AsseoirBanc" then return end
	local siege = invite.Parent
	if not (siege and siege:IsA("Seat")) or siege.Occupant then return end
	local perso = joueur.Character
	local humanoide = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (humanoide and racine) or humanoide.Health <= 0 or humanoide.SeatPart then return end
	if (racine.Position - siege.Position).Magnitude > 12 then return end
	siege:Sit(humanoide)
end)
