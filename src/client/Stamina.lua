--!strict
-- Endurance (stamina) du joueur local · ModuleScript CLIENT (StarterPlayerScripts › Jeu › Stamina)
-- Source unique de la stamina : la course (Hud.client) la draine, les futures attaques appellent Stamina.consommer(n).
-- Recharge automatique après un court repos. À 0 → « épuisé » : plus de course ni de dépense jusqu'à SEUIL_REPRISE.
-- Publie aussi des attributs CLIENT sur le LocalPlayer (non répliqués) : Stamina, StaminaMax, StaminaEpuisee.
-- Purement visuel/local : le serveur ne s'en sert pas (à valider côté serveur si un jour la stamina conditionne des dégâts).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Stamina = {
	MAX = 100,
	DRAIN_COURSE = 12, -- par seconde de course réelle
	REGEN = 15, -- par seconde
	DELAI_REGEN = 0.8, -- secondes sans effort avant de récupérer
	SEUIL_REPRISE = 25, -- épuisé → de nouveau utilisable à partir de cette valeur
}

local joueur = Players.LocalPlayer
local valeur = Stamina.MAX
local epuise = false
local dernierEffort = -math.huge
local publiee = -1

local evEpuisement = Instance.new("BindableEvent")
-- (epuise: boolean) : déclenché quand on tombe à 0 et quand on repasse le seuil
Stamina.Epuisement = evEpuisement.Event

local function publier()
	local arrondi = math.floor(valeur + 0.5)
	if arrondi ~= publiee then
		publiee = arrondi
		joueur:SetAttribute("Stamina", arrondi)
	end
end

local function definirEpuise(e: boolean)
	if e ~= epuise then
		epuise = e
		joueur:SetAttribute("StaminaEpuisee", e)
		evEpuisement:Fire(e)
	end
end

function Stamina.get(): number
	return valeur
end

function Stamina.fraction(): number
	return valeur / Stamina.MAX
end

function Stamina.estEpuise(): boolean
	return epuise
end

function Stamina.peutCourir(): boolean
	return not epuise and valeur > 0
end

-- Dépense ponctuelle (attaque, esquive…) : tout ou rien. Renvoie false si pas assez / épuisé.
function Stamina.consommer(n: number): boolean
	if n <= 0 then
		return true
	end
	if epuise or valeur < n then
		return false
	end
	valeur -= n
	dernierEffort = os.clock()
	if valeur <= 0 then
		valeur = 0
		definirEpuise(true)
	end
	publier()
	return true
end

-- Dépense continue (course) : retire ce qu'il reste, jusqu'à 0.
function Stamina.drainer(n: number)
	if n <= 0 then
		return
	end
	valeur = math.max(0, valeur - n)
	dernierEffort = os.clock()
	if valeur <= 0 then
		definirEpuise(true)
	end
	publier()
end

function Stamina.remplir()
	valeur = Stamina.MAX
	dernierEffort = -math.huge
	definirEpuise(false)
	publier()
end

RunService.Heartbeat:Connect(function(dt)
	if valeur < Stamina.MAX and os.clock() - dernierEffort >= Stamina.DELAI_REGEN then
		valeur = math.min(Stamina.MAX, valeur + Stamina.REGEN * dt)
		if epuise and valeur >= Stamina.SEUIL_REPRISE then
			definirEpuise(false)
		end
		publier()
	end
end)

joueur:SetAttribute("StaminaMax", Stamina.MAX)
joueur:SetAttribute("StaminaEpuisee", false)
publier()

return Stamina
