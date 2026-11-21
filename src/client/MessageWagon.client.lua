-- Retour au joueur lorsqu'il actionne le levier sans être assis dans un wagonnet.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local evenement = ReplicatedStorage:WaitForChild("InformationDepartWagon") :: RemoteEvent

evenement.OnClientEvent:Connect(function(texte: string)
	if texte ~= "Il faut être dans le wagon" then return end
	pcall(function()
		StarterGui:SetCore("SendNotification", {Title = "Gare", Text = texte, Duration = 4})
	end)
end)
