--!strict
-- Caméra des tunnels privés · SCRIPT CLIENT : 1re personne forcée dans sa mine privée.
--  • Dans les tunnels privés (mines privées), la caméra passe en 1re personne (impossible de dézoomer).
--    La mine publique, la caverne des portes et les grottes profondes gardent la caméra libre.
--  • En ressortant, la caméra repart en 3e personne, un peu derrière le joueur.
-- La zone reprend les coordonnées de ServerStorage › Monde › Disposition (non lisible côté client) :
-- les mettre à jour ensemble si la carte change.

local Players = game:GetService("Players")

local joueur = Players.LocalPlayer

type Boite = {min: Vector3, max: Vector3}
local ZONES_MINE: {Boite} = {
	-- tunnels privés (mines privées) : D.MINES_PRIVEES_ORIGINE (1400, 700, -1200), écart 400 en X (6 colonnes, x de 1400
	-- à 3400) et 1000 en Z ; massif de 690 studs de haut (fond vers y = 20) et 800 de long
	{min = Vector3.new(1150, -100, -8000), max = Vector3.new(3650, 900, -950)},
}
local RECUL_SORTIE = 12 -- studs : distance de la caméra en ressortant de la mine
local INTERVALLE = 0.2 -- secondes entre deux vérifications de la position

local function dansBoite(p: Vector3, b: Boite): boolean
	return p.X >= b.min.X and p.X <= b.max.X and p.Y >= b.min.Y and p.Y <= b.max.Y
		and p.Z >= b.min.Z and p.Z <= b.max.Z
end

local function dansUneMine(p: Vector3): boolean
	for _, b in ZONES_MINE do
		if dansBoite(p, b) then
			return true
		end
	end
	return false
end

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

task.spawn(function()
	while true do
		local perso = joueur.Character
		local racine = perso and perso:FindFirstChild("HumanoidRootPart")
		if racine and racine:IsA("BasePart") then
			appliquer(dansUneMine(racine.Position))
		end
		task.wait(INTERVALLE)
	end
end)
