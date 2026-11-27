--!strict
-- Caméra des tunnels privés · SCRIPT CLIENT : 1re personne forcée dans sa mine privée.
--  • Dans les tunnels privés (mines privées), la caméra passe en 1re personne (impossible de dézoomer).
--    La mine publique, la caverne des portes et les grottes profondes gardent la caméra libre.
--  • En ressortant, la caméra repart en 3e personne, un peu derrière le joueur.
-- RemonterMine.server publie « CoucheMine » quand le joueur se trouve dans sa mine.

local Players = game:GetService("Players")

local joueur = Players.LocalPlayer

local RECUL_SORTIE = 12 -- studs : distance de la caméra en ressortant de la mine

local zoomMinDefaut = joueur.CameraMinZoomDistance
local enMine = false

local function appliquer(dedans: boolean)
	if dedans == enMine then
		return
	end
	enMine = dedans
	if dedans then
		zoomMinDefaut = joueur.CameraMinZoomDistance
		joueur.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		joueur.CameraMode = Enum.CameraMode.Classic
		-- la caméra resterait collée à la tête : on la repousse derrière le joueur, puis on rend le zoom libre
		joueur.CameraMinZoomDistance = RECUL_SORTIE
		task.delay(0.1, function()
			if not enMine then
				joueur.CameraMinZoomDistance = zoomMinDefaut
			end
		end)
	end
end

local function actualiser()
	appliquer(joueur:GetAttribute("CoucheMine") ~= nil)
end

joueur:GetAttributeChangedSignal("CoucheMine"):Connect(actualiser)
actualiser()
