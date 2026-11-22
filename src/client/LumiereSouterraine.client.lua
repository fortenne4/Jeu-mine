-- Lumière sous terre · CLIENT : quand le joueur est sous un plafond (mine, tunnels, grottes), l'ombre ambiante
-- s'éclaircit et le bloom se calme, pour éviter le passage noir total → néon éblouissant qui fait mal aux yeux.
-- Dehors, on revient aux réglages de monde/Ambiance.lua. Effet local (chaque client), rien ne change côté serveur.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local joueur = Players.LocalPlayer
local HAUTEUR_TEST = 120 -- un plafond à moins de 120 studs au-dessus de la tête = sous terre
local PERIODE = 0.3
local TRANSITION = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Réglages sous terre : ombre lisible (on voit les parois), halos doux, contraste réduit
local SOUS_TERRE = {
	lighting = {Ambient = Color3.fromRGB(96, 90, 108), ExposureCompensation = 0.1},
	bloom = {Intensity = 0.35, Threshold = 2.2},
	correction = {Contrast = 0.02, Saturation = -0.05, Brightness = 0.03},
}

local dehors: {[string]: any}? = nil -- réglages d'origine relevés au premier passage sous terre
local sousTerre = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true

local function effet(classe: string): Instance?
	for _, e in Lighting:GetChildren() do
		if e:IsA(classe) then return e end
	end
	return nil
end

local function releverDehors()
	local bloom, cc = effet("BloomEffect"), effet("ColorCorrectionEffect")
	dehors = {
		lighting = {Ambient = Lighting.Ambient, ExposureCompensation = Lighting.ExposureCompensation},
		bloom = if bloom then {Intensity = (bloom :: any).Intensity, Threshold = (bloom :: any).Threshold} else nil,
		correction = if cc then {Contrast = (cc :: any).Contrast, Saturation = (cc :: any).Saturation, Brightness = (cc :: any).Brightness} else nil,
	}
end

local function appliquer(r)
	TweenService:Create(Lighting, TRANSITION, r.lighting):Play()
	local bloom, cc = effet("BloomEffect"), effet("ColorCorrectionEffect")
	if bloom and r.bloom then TweenService:Create(bloom, TRANSITION, r.bloom):Play() end
	if cc and r.correction then TweenService:Create(cc, TRANSITION, r.correction):Play() end
end

local function estSousTerre(): boolean
	local perso = joueur.Character
	local tete = perso and perso:FindFirstChild("Head")
	if not tete or not tete:IsA("BasePart") then return sousTerre end
	params.FilterDescendantsInstances = {perso}
	local origine = tete.Position
	-- trois rayons (vertical + deux inclinés) : il faut un vrai plafond (un arbre isolé ou un trou ne suffit pas)
	local touches = 0
	for _, d in {Vector3.new(0, 1, 0), Vector3.new(0.35, 1, 0), Vector3.new(-0.35, 1, 0.35)} do
		if workspace:Raycast(origine, d.Unit * HAUTEUR_TEST, params) then touches += 1 end
	end
	return touches >= 3
end

while true do
	local s = estSousTerre()
	if s ~= sousTerre then
		if s then
			if not dehors then releverDehors() end
			appliquer(SOUS_TERRE)
		elseif dehors then
			appliquer(dehors)
		end
		sousTerre = s
	end
	task.wait(PERIODE)
end
