--!strict
-- Réglages d'aura de chaque pioche (ReplicatedStorage › Partage › AurasPioches).
-- Ce sont ceux choisis dans l'Atelier 3D (style, couleurs, intensité) le 17/11/2026.
-- Pour en changer : modifie ici, ou refais ton réglage dans l'Atelier et demande à Claude de le reporter.
--
-- style : "Flammes", "Givre", "Foudre", "Ombre", "Divin", "Arcane", "Cristal" (léger) ou "Eclat" (très léger)
-- intensite : 0 = rien, 0.5 = discrète, 1 = normale, 2 = très forte
-- Une pioche absente de cette liste (ou avec style = nil) n'a pas d'aura ajoutée.

export type Reglage = {
	style: string,
	couleur: Color3, -- couleur principale
	couleur2: Color3, -- cœur lumineux
	intensite: number,
}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local AurasPioches: {[string]: Reglage} = {
	-- Haut de gamme
	Givre = {style = "Givre", couleur = hex("38b6ff"), couleur2 = hex("e8f9ff"), intensite = 0.6},
	Volcan = {style = "Flammes", couleur = hex("ff6a00"), couleur2 = hex("ffd36a"), intensite = 1},
	Celeste = {style = "Divin", couleur = hex("ffbf2e"), couleur2 = hex("fff6d6"), intensite = 0.35},
	Demon = {style = "Flammes", couleur = hex("ff2a1a"), couleur2 = hex("ffb070"), intensite = 0.85},
	Neant = {style = "Ombre", couleur = hex("a23bff"), couleur2 = hex("ff8af2"), intensite = 0.85},
	Legende = {style = "Arcane", couleur = hex("ffb52a"), couleur2 = hex("86ecff"), intensite = 0.7},
	-- Entrée de gamme (pas encore vendues par Liesel) : Bois et Pierre n'ont pas d'aura
	Cuivre = {style = "Eclat", couleur = hex("ff8a3a"), couleur2 = hex("ffd2a0"), intensite = 0.3},
	Fer = {style = "Eclat", couleur = hex("9fc4ff"), couleur2 = hex("ffffff"), intensite = 0.45},
	Quartz = {style = "Cristal", couleur = hex("ff5fb0"), couleur2 = hex("ffe0f0"), intensite = 1},
}

return AurasPioches
