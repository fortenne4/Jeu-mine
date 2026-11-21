-- Crépuscule permanent : soleil bas et doré, brume chaude, nuages roses.
-- (Le moteur d'éclairage "Future" est réglé par Rojo dans default.project.json.)
local Lighting = game:GetService("Lighting")

local Ambiance = {}
local HEURE_CREPUSCULE = 18.15
local OMBRE_FROIDE = Color3.fromRGB(47, 40, 61)
local LUMIERE_AMBIANTE = Color3.fromRGB(105, 93, 118)
local INTENSITE_BLOOM = 0.85

local function nouveau(classe, props)
	local i: any = Instance.new(classe)
	for cle, valeur in props do
		i[cle] = valeur
	end
	i.Parent = Lighting
	return i
end

function Ambiance.appliquer()
	Lighting.ClockTime = HEURE_CREPUSCULE
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = 2.4
	Lighting.Ambient = OMBRE_FROIDE
	Lighting.OutdoorAmbient = LUMIERE_AMBIANTE
	Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 150)
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ExposureCompensation = 0.1
	Lighting.ShadowSoftness = 0.25
	Lighting.GlobalShadows = true

	for _, e in Lighting:GetChildren() do
		if e:IsA("Atmosphere") or e:IsA("PostEffect") then
			e:Destroy()
		end
	end
	nouveau("Atmosphere", {
		Name = "Crepuscule",
		Density = 0.32,
		Offset = 0.15,
		Color = Color3.fromRGB(226, 160, 128),
		Decay = Color3.fromRGB(110, 76, 104),
		Glare = 0.45,
		Haze = 2.2,
	})
	nouveau("BloomEffect", {Intensity = INTENSITE_BLOOM, Size = 28, Threshold = 1.4})
	nouveau("SunRaysEffect", {Intensity = 0.07, Spread = 0.75})
	nouveau("ColorCorrectionEffect", {
		Brightness = 0.02,
		Contrast = 0.12,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 240, 228),
	})

	-- Herbe animée du terrain : courte, sinon elle cache les PNJ et les joueurs jusqu'à la taille
	local terrain: any = workspace.Terrain
	local okLongueur = pcall(function()
		terrain.GrassLength = 0.25
	end)
	if not okLongueur then
		local okDeco = pcall(function()
			terrain.Decoration = false
		end)
		if not okDeco then
			warn("[Monde] Herbe trop haute : décoche Workspace › Terrain › Decoration dans Studio")
		end
	end

	local nuages = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	nuages.Cover = 0.55
	nuages.Density = 0.6
	nuages.Color = Color3.fromRGB(255, 214, 196)
	nuages.Parent = workspace.Terrain
end

return Ambiance
