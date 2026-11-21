-- Caméra locale partagée entre le geste du levier et la transition du wagon.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraWagon = {}
local joueur = Players.LocalPlayer
local DUREE_RECUL = 1.2
local DISTANCE_RECUL = 5
local DELAI_SECURITE = 8
local actif = nil

function CameraWagon.restaurer()
	local etat = actif
	if not etat then return end
	actif = nil
	if etat.connexion then etat.connexion:Disconnect() end
	if workspace.CurrentCamera == etat.camera and etat.camera.Parent then
		etat.camera.CameraType = etat.type
		if etat.sujet and etat.sujet.Parent then etat.camera.CameraSubject = etat.sujet end
	end
end

function CameraWagon.demarrer()
	if actif then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local etat = {camera = camera, type = camera.CameraType, sujet = camera.CameraSubject, origine = camera.CFrame, connexion = nil}
	actif = etat
	local debut = os.clock()
	camera.CameraType = Enum.CameraType.Scriptable
	etat.connexion = RunService.RenderStepped:Connect(function()
		if actif ~= etat then return end
		if workspace.CurrentCamera ~= camera or not camera.Parent then CameraWagon.restaurer(); return end
		local u = math.clamp((os.clock() - debut) / DUREE_RECUL, 0, 1)
		local ralenti = 1 - (1 - u) ^ 3 -- décélère en arrivant à la position finale
		camera.CFrame = etat.origine * CFrame.new(0, 0, DISTANCE_RECUL * ralenti)
	end)
	-- Si le lancer est annulé avant le départ, ne jamais garder une caméra figée.
	task.delay(DELAI_SECURITE, function()
		if actif == etat then CameraWagon.restaurer() end
	end)
end

joueur.CharacterRemoving:Connect(CameraWagon.restaurer)
return CameraWagon
