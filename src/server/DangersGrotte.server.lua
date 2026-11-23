-- Dangers des grottes profondes · SCRIPT SERVEUR
-- Lit les repères posés par les thèmes de grottes (GrotteTheme / GrotteFonderie / GrotteLave / GrotteCoeur) :
--   * « ZoneChute » (attributs Rayon, YMin, Retour) : un joueur tombé dans un gouffre est ramené au bord
--     (Retour), avec quelques dégâts ;
--   * « Lave » (BasePart, la surface de lave) : un joueur dont les pieds touchent la lave brûle (dégâts répétés,
--     attribut joueur « Brule » pour l'effet client) ;
--   * « Geyser » (BasePart, attributs Periode, Duree, Decalage) : le serveur l'active à intervalles (attribut
--     « Actif », lu par MachinesGrotte.client.lua pour la gerbe de feu) et blesse qui se tient dessus.
-- Une seule boucle à 5 Hz pour toutes les grottes.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local DEGATS_CHUTE = 15
local DEGATS_LAVE = 10 -- toutes les 0,4 s
local DEGATS_GEYSER = 18 -- toutes les 0,4 s
local RAYON_GEYSER = 4

local function racines(): {{joueur: Player, r: BasePart, hum: Humanoid}}
	local t = {}
	for _, j in Players:GetPlayers() do
		local perso = j.Character
		local r = perso and perso:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = perso and perso:FindFirstChildOfClass("Humanoid")
		if r and hum and hum.Health > 0 then
			table.insert(t, {joueur = j, r = r, hum = hum})
		end
	end
	return t
end

-- le joueur est-il au-dessus de la part (dans son emprise horizontale) ?
local function dessus(part: BasePart, pos: Vector3, marge: number): boolean
	local l = part.CFrame:PointToObjectSpace(pos)
	local s = part.Size / 2
	return math.abs(l.X) < s.X + marge and math.abs(l.Z) < s.Z + marge
end

-- rayon vers le sol : terrain et pièces solides, sans le personnage (la lave, non solide, est traversée)
local function sansPersos(perso: Instance?): RaycastParams
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = if perso then {perso} else {}
	rp.RespectCanCollide = true
	rp.IgnoreWater = true
	return rp
end

local horloge = 0
local dernierCoup: {[Player]: number} = {}

task.spawn(function()
	while true do
		task.wait(0.2)
		horloge += 0.2
		local maintenant = os.clock()
		local joueurs = racines()
		if #joueurs == 0 then
			continue
		end
		-- chutes
		for _, z in CollectionService:GetTagged("ZoneChute") do
			if z:IsA("BasePart") then
				local rayon, yMin, retour = z:GetAttribute("Rayon"), z:GetAttribute("YMin"), z:GetAttribute("Retour")
				if type(rayon) == "number" and type(yMin) == "number" and typeof(retour) == "Vector3" then
					for _, e in joueurs do
						local p = e.r.Position
						local d = Vector3.new(p.X - z.Position.X, 0, p.Z - z.Position.Z).Magnitude
						if d < rayon and p.Y < yMin then
							e.r.AssemblyLinearVelocity = Vector3.zero
							e.joueur.Character:PivotTo(CFrame.new(retour))
							e.hum:TakeDamage(DEGATS_CHUTE)
						end
					end
				end
			end
		end
		-- geysers : activation périodique (Periode s, actif Duree s, décalé de Decalage s)
		for _, g in CollectionService:GetTagged("Geyser") do
			if g:IsA("BasePart") and g:GetAttribute("Inactif") then
				if g:GetAttribute("Actif") then
					g:SetAttribute("Actif", false)
					g:SetAttribute("Avertit", false)
				end
			elseif g:IsA("BasePart") then
				local periode = g:GetAttribute("Periode") or 7
				local duree = g:GetAttribute("Duree") or 1.6
				local phase = (horloge + (g:GetAttribute("Decalage") or 0)) % periode
				local actif = phase > periode - duree
				local avertit = not actif and phase > periode - duree - 1.2
				if g:GetAttribute("Actif") ~= actif then
					g:SetAttribute("Actif", actif)
				end
				if g:GetAttribute("Avertit") ~= avertit then
					g:SetAttribute("Avertit", avertit)
				end
				if actif then
					for _, e in joueurs do
						local p = e.r.Position
						local propulsion = g:GetAttribute("Propulsion")
						if Vector3.new(p.X - g.Position.X, 0, p.Z - g.Position.Z).Magnitude < RAYON_GEYSER and math.abs(p.Y - g.Position.Y) < 10
							and maintenant - (dernierCoup[e.joueur] or 0) > (if propulsion then 1 else 0.4) then
							dernierCoup[e.joueur] = maintenant
							if type(propulsion) == "number" then
								-- geyser propulseur : aucun dégât, il projette très haut (corniche secrète)
								e.r.AssemblyLinearVelocity = Vector3.new(e.r.AssemblyLinearVelocity.X, propulsion, e.r.AssemblyLinearVelocity.Z)
							else
								e.hum:TakeDamage(DEGATS_GEYSER)
								e.r.AssemblyLinearVelocity = Vector3.new(0, 45, 0)
							end
						end
					end
				end
			end
		end
		-- lave : on brûle si la lave recouvre ce sur quoi on marche (un pont ou un rocher au-dessus protège)
		local brulent = {}
		for _, l in CollectionService:GetTagged("Lave") do
			if l:IsA("BasePart") then
				local haut = l.Position.Y + l.Size.Y / 2
				for _, e in joueurs do
					local p = e.r.Position
					local sol = workspace:Raycast(p, Vector3.new(0, -8, 0), sansPersos(e.joueur.Character))
					local solY = if sol then sol.Position.Y else p.Y - 3
					if p.Y < haut + 3.6 and p.Y > haut - 6 and solY < haut - 0.05 and dessus(l, p, -0.3) then
						brulent[e.joueur] = true
						if maintenant - (dernierCoup[e.joueur] or 0) > 0.4 then
							dernierCoup[e.joueur] = maintenant
							e.hum:TakeDamage(DEGATS_LAVE)
						end
					end
				end
			end
		end
		for _, e in joueurs do
			local b = brulent[e.joueur] == true
			if e.joueur:GetAttribute("Brule") ~= b then
				e.joueur:SetAttribute("Brule", b)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(j)
	dernierCoup[j] = nil
end)
