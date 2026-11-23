--!strict
-- Halo local des entrées des tunnels privés. Le serveur détecte toujours les joueurs via CercleTunnel.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local TAG = "CercleTunnel"
local RAYON = 5.5 -- rayon de l'anneau blanc de CercleLumineux
local POINTS = 12
local BLANC = Color3.new(1, 1, 1)
local FUMEE = "rbxasset://textures/particles/smoke_main.dds"
local POULS = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

type Effet = {support: Part, pulsation: Tween}
type Suivi = {connexion: RBXScriptConnection?, effet: Effet?}
local suivis: {[Instance]: Suivi} = {}

local function creerHalo(modele: Model, centre: Vector3): Effet
	-- Support invisible et points de brume sur le pourtour du cercle.
	local support = Instance.new("Part")
	support.Name = "AuraBlancheTunnel"
	support.Size = Vector3.new(0.2, 0.2, 0.2)
	support.Position = centre
	support.Transparency = 1
	support.Anchored = true
	support.CanCollide = false
	support.CanTouch = false
	support.CanQuery = false
	support.Massless = true
	support.CastShadow = false
	for i = 0, POINTS - 1 do
		local a = i * 2 * math.pi / POINTS
		local point = Instance.new("Attachment")
		point.Position = Vector3.new(math.cos(a) * RAYON, 0.15, math.sin(a) * RAYON)
		point.Parent = support
		local brume = Instance.new("ParticleEmitter")
		brume.Texture = FUMEE
		brume.Color = ColorSequence.new(BLANC)
		brume.LightEmission = 0.7
		brume.LightInfluence = 0
		brume.Rate = 1
		brume.Lifetime = NumberRange.new(1.3, 1.8)
		brume.Speed = NumberRange.new(0.3, 0.65)
		brume.SpreadAngle = Vector2.new(15, 15)
		brume.Size = NumberSequence.new(0.4, 1.05)
		brume.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.45), NumberSequenceKeypoint.new(1, 1)})
		brume.Parent = point
	end

	local lumiere = Instance.new("PointLight")
	lumiere.Name = "AuraTunnel"
	lumiere.Color = BLANC
	lumiere.Brightness = 0.12
	lumiere.Range = 8
	lumiere.Shadows = false
	lumiere.Parent = support
	support.Parent = modele

	local pulsation = TweenService:Create(lumiere, POULS, {Brightness = 0.3})
	pulsation:Play()
	return {support = support, pulsation = pulsation}
end

local function suivre(modele: Instance)
	if not modele:IsA("Model") or suivis[modele] then return end
	local suivi: Suivi = {}
	suivis[modele] = suivi
	local function actualiser()
		local centre = modele:GetAttribute("Centre")
		if typeof(centre) ~= "Vector3" then return end
		if suivi.effet then
			suivi.effet.support.Position = centre
		else
			suivi.effet = creerHalo(modele, centre)
		end
	end
	-- Le centre peut être reçu après le modèle lorsque le streaming est actif.
	suivi.connexion = modele:GetAttributeChangedSignal("Centre"):Connect(actualiser)
	actualiser()
end

local function retirer(modele: Instance)
	local suivi = suivis[modele]
	if not suivi then return end
	suivis[modele] = nil
	if suivi.connexion then suivi.connexion:Disconnect() end
	if suivi.effet then
		suivi.effet.pulsation:Destroy()
		suivi.effet.support:Destroy()
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(suivre)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(retirer)
for _, modele in CollectionService:GetTagged(TAG) do suivre(modele) end
