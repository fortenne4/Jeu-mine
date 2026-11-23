-- Statue du roi des mineurs : un nain en bronze couronné qui lève sa pioche dorée, sur un socle de pierre,
-- dans l'herbe à l'ouest de l'avenue de la gare (entre ses deux lampadaires). Quatre lanternes
-- sur des bornes de pierre l'éclairent la nuit (lueur + projecteur tourné vers la statue).
local POSITION = Vector3.new(-22, 0, -66)   -- x, z au sol (la hauteur est lue sur le terrain)
local REGARD = Vector3.new(0, 0, -66)       -- la statue regarde l'avenue
local COULEUR_BRONZE = Color3.fromRGB(150, 108, 62)
local COULEUR_BRONZE_FONCE = Color3.fromRGB(104, 74, 44)
local COULEUR_LUMIERE = Color3.fromRGB(255, 176, 90)
local PORTEE_LUMIERE = 16
local INTENSITE_LUMIERE = 1.4
local ECART_BORNES = 5.2 -- distance des bornes au centre du socle (coins)

local ServerStorage = game:GetService("ServerStorage")
local monde = ServerStorage:WaitForChild("Monde")
local O = require(monde:WaitForChild("Outils"))
local Lampadaires = require(monde:WaitForChild("Lampadaires"))
local M, C = O.M, O.C

local debut = os.clock()
while not workspace:GetAttribute("MondeConstruit") and os.clock() - debut < 90 do task.wait(0.25) end
local village = workspace:FindFirstChild("Carte") and workspace.Carte:FindFirstChild("Village")
if not village then warn("[StatueMineur] Village introuvable") return end
if village:FindFirstChild("StatueMineur") then return end
local statue = Instance.new("Model")
statue.Name = "StatueMineur"

local rayons = RaycastParams.new()
rayons.RespectCanCollide = true
rayons.FilterType = Enum.RaycastFilterType.Exclude
rayons.FilterDescendantsInstances = {statue}
local function hauteurSol(x, z)
	local impact = workspace:Raycast(Vector3.new(x, 12, z), Vector3.new(0, -30, 0), rayons)
	return impact and impact.Position.Y
end
local y = hauteurSol(POSITION.X, POSITION.Z)
if not y then warn("[StatueMineur] Sol introuvable") return end
-- Repère de la statue : -Z local = face avant (vers l'avenue), +X = droite de la statue
local base = CFrame.lookAt(Vector3.new(POSITION.X, y, POSITION.Z), Vector3.new(REGARD.X, y, REGARD.Z))

-- ===== Socle =====
local socle = O.modele(statue, "Socle")
O.bloc(socle, Vector3.new(8, 0.8, 8), base * CFrame.new(0, 0.2, 0), C.PierreFoncee, M.Ardoise, "Marche")
O.bloc(socle, Vector3.new(6.4, 0.5, 6.4), base * CFrame.new(0, 0.85, 0), C.Pierre, M.Ardoise, "Plinthe")
O.bloc(socle, Vector3.new(5.6, 3, 5.6), base * CFrame.new(0, 2.6, 0), C.PierreClaire, M.Calcaire, "Fut")
O.bloc(socle, Vector3.new(6.4, 0.6, 6.4), base * CFrame.new(0, 4.4, 0), C.Pierre, M.Ardoise, "Corniche")
local plaque = O.bloc(socle, Vector3.new(5, 1.5, 0.2), base * CFrame.new(0, 2.7, -2.85), COULEUR_BRONZE_FONCE, M.Metal, "Plaque")
O.texte(plaque, Enum.NormalId.Front, "AU ROI DES MINEURS")
-- petits cristaux incrustés aux coins de la corniche
for _, sx in {-1, 1} do
	for _, sz in {-1, 1} do
		local cristal = O.bloc(socle, Vector3.new(0.6, 0.9, 0.6),
			base * CFrame.new(sx * 2.9, 5.1, sz * 2.9) * CFrame.Angles(0, math.rad(45), math.rad(12 * sx)), C.Cristal, M.Neon, "Cristal")
		cristal.Transparency = 0.15
		O.decor(cristal)
	end
end

-- ===== Le roi des mineurs : un nain en bronze dans le style des PNJ nains (formes rondes),
-- debout sur la corniche (y = 4.7), la pioche dorée brandie au-dessus de la tête =====
local mineur = O.modele(statue, "RoiNain")
local pied = base * CFrame.new(0, 4.7, 0)
local function boule(taille, cf, nom, couleur, materiau)
	return O.ellipsoide(mineur, taille, pied * cf, couleur or COULEUR_BRONZE, materiau or M.Metal, nom)
end
local function cyl(hauteur, diametre, cf, nom, couleur, materiau)
	return O.cylindre(mineur, hauteur, diametre, pied * cf, couleur or COULEUR_BRONZE, materiau or M.Metal, nom)
end
local function piece(taille, cf, nom, couleur, materiau)
	return O.bloc(mineur, taille, pied * cf, couleur or COULEUR_BRONZE, materiau or M.Metal, nom)
end
local OR, FONCE = C.Or, COULEUR_BRONZE_FONCE
-- grosses bottes rondes et jambes courtes
for _, sx in {-1, 1} do
	boule(Vector3.new(1.9, 1.3, 2.4), CFrame.new(sx * 0.9, 0.6, -0.25), "Botte", FONCE)
	cyl(0.45, 1.65, CFrame.new(sx * 0.9, 1.3, 0), "ReversBotte", FONCE)
	cyl(1, 1.4, CFrame.new(sx * 0.85, 1.9, 0), "Jambe")
end
-- jupe de cuir, ventre rond, torse large, ceinture à boucle dorée et bretelles
cyl(1.3, 3.7, CFrame.new(0, 2.6, 0), "Jupe", FONCE)
boule(Vector3.new(4, 3.6, 3.4), CFrame.new(0, 4, -0.2), "Ventre")
boule(Vector3.new(4.4, 2.6, 3), CFrame.new(0, 5.3, 0), "Torse")
cyl(0.5, 3.95, CFrame.new(0, 3.1, 0), "Ceinture", FONCE)
piece(Vector3.new(0.95, 0.75, 0.25), CFrame.new(0, 3.1, -1.98), "Boucle", OR)
for _, sx in {-1, 1} do
	piece(Vector3.new(0.3, 2.4, 0.15), CFrame.new(sx * 0.85, 4.45, -1.82) * CFrame.Angles(math.rad(-12), 0, math.rad(4 * sx)), "Bretelle", FONCE)
	-- épaulières de métal, liseré et rivet dorés
	boule(Vector3.new(1.9, 1.35, 2.1), CFrame.new(sx * 2.05, 6.05, 0) * CFrame.Angles(0, 0, math.rad(-14 * sx)), "Epauliere", FONCE)
	boule(Vector3.new(2, 0.3, 2.2), CFrame.new(sx * 2.15, 5.6, 0) * CFrame.Angles(0, 0, math.rad(-14 * sx)), "LisereEpauliere", OR)
	boule(Vector3.new(0.28, 0.28, 0.28), CFrame.new(sx * 2.25, 6.55, -0.75), "Rivet", OR)
end
-- tête : gros nez, sourcils broussailleux, moustache et longue barbe
boule(Vector3.new(2, 2.1, 2), CFrame.new(0, 7.1, 0), "Tete")
boule(Vector3.new(0.6, 0.6, 0.7), CFrame.new(0, 7.05, -1.02), "Nez")
for _, sx in {-1, 1} do
	boule(Vector3.new(0.22, 0.22, 0.22), CFrame.new(sx * 0.42, 7.32, -0.92), "Oeil", C.PierreFoncee)
	boule(Vector3.new(0.75, 0.3, 0.4), CFrame.new(sx * 0.45, 7.58, -0.88) * CFrame.Angles(0, 0, math.rad(-12 * sx)), "Sourcil", FONCE)
	boule(Vector3.new(1.05, 0.42, 0.55), CFrame.new(sx * 0.45, 6.78, -1.02) * CFrame.Angles(0, 0, math.rad(18 * sx)), "Moustache", FONCE)
end
boule(Vector3.new(2.4, 2.5, 1.4), CFrame.new(0, 5.95, -1.3), "Barbe", FONCE)
boule(Vector3.new(1.5, 1.7, 1), CFrame.new(0, 4.75, -1.78), "PointeBarbe", FONCE)
piece(Vector3.new(0.5, 0.3, 0.3), CFrame.new(0, 4.35, -2.05), "AnneauBarbe", OR)
-- casque de mineur à lampe, ceint d'une couronne de roi
boule(Vector3.new(2.3, 1.5, 2.3), CFrame.new(0, 7.95, 0), "Casque", FONCE)
cyl(0.2, 2.55, CFrame.new(0, 7.75, 0), "BordCasque", FONCE)
piece(Vector3.new(0.6, 0.55, 0.3), CFrame.new(0, 8.05, -1.1), "SupportLampe", OR)
local lampe = piece(Vector3.new(0.4, 0.4, 0.15), CFrame.new(0, 8.05, -1.28), "LampeCasque", Color3.fromRGB(255, 226, 150), M.Neon)
O.decor(lampe)
cyl(0.35, 2.05, CFrame.new(0, 8.45, 0), "Couronne", OR)
for k = 0, 5 do
	local fleuron = CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 8.82, -0.98)
	piece(Vector3.new(0.34, 0.34, 0.12), fleuron * CFrame.Angles(0, 0, math.rad(45)), "Fleuron", OR)
	boule(Vector3.new(0.2, 0.2, 0.2), fleuron * CFrame.new(0, 0.3, 0), "Perle", OR)
end
-- bras gauche le long du corps, poing serré
boule(Vector3.new(1.25, 2, 1.25), CFrame.new(-2.35, 5, 0) * CFrame.Angles(0, 0, math.rad(-8)), "BrasGauche")
boule(Vector3.new(1.35, 1.8, 1.35), CFrame.new(-2.55, 3.55, -0.25), "AvantBrasGauche")
cyl(0.5, 1.5, CFrame.new(-2.55, 3.3, -0.25), "BrassardGauche", FONCE)
boule(Vector3.new(1.2, 1.15, 1.2), CFrame.new(-2.6, 2.55, -0.35), "PoingGauche")
-- bras droit levé, la pioche brandie au-dessus de la tête
local epaule = CFrame.new(2.2, 5.9, 0) * CFrame.Angles(0, 0, math.rad(-20))
boule(Vector3.new(1.25, 2, 1.25), epaule * CFrame.new(0, 0.95, 0), "BrasDroit")
boule(Vector3.new(1.35, 1.8, 1.35), epaule * CFrame.new(0, 2.6, 0), "AvantBrasDroit")
cyl(0.5, 1.5, epaule * CFrame.new(0, 2.85, 0), "BrassardDroit", FONCE)
local main = epaule * CFrame.new(0, 3.75, 0)
boule(Vector3.new(1.2, 1.15, 1.2), main, "PoingDroit")
-- pioche : manche penché au-dessus de la tête, fer doré perpendiculaire au manche
local manche = main * CFrame.Angles(0, 0, math.rad(48))
cyl(5.2, 0.4, manche * CFrame.new(0, 1.4, 0), "Manche", C.BoisFonce, M.Bois)
local fer = manche * CFrame.new(0, 3.9, 0)
piece(Vector3.new(1, 1, 0.85), fer, "FerDouille", C.Fer)
for _, sens in {-1, 1} do
	piece(Vector3.new(1.6, 0.65, 0.6), fer * CFrame.new(sens * 1.25, -0.08, 0) * CFrame.Angles(0, 0, math.rad(-10 * sens)), "FerBras", OR)
	piece(Vector3.new(1, 0.42, 0.42), fer * CFrame.new(sens * 2.4, -0.4, 0) * CFrame.Angles(0, 0, math.rad(-22 * sens)), "FerPointe", OR)
end
for _, p in mineur:GetDescendants() do
	if p:IsA("BasePart") then p.CanQuery, p.CanTouch = false, false end
end

-- ===== Bornes à lanterne aux quatre coins, projecteurs tournés vers la statue =====
local cible = (base * CFrame.new(0, 9, 0)).Position
for _, sx in {-1, 1} do
	for _, sz in {-1, 1} do
		local local_ = Vector3.new(sx * ECART_BORNES, 0, sz * ECART_BORNES)
		local monde_ = (base * CFrame.new(local_)).Position
		local h = hauteurSol(monde_.X, monde_.Z) or y
		local borne = O.modele(statue, "Borne")
		local sol = CFrame.new(monde_.X, h, monde_.Z) * base.Rotation
		O.bloc(borne, Vector3.new(1.3, 0.4, 1.3), sol * CFrame.new(0, 0.2, 0), C.PierreFoncee, M.Ardoise, "Pied")
		O.bloc(borne, Vector3.new(0.9, 2.2, 0.9), sol * CFrame.new(0, 1.5, 0), C.Pierre, M.Ardoise, "Pilier")
		O.bloc(borne, Vector3.new(1.2, 0.3, 1.2), sol * CFrame.new(0, 2.75, 0), C.PierreFoncee, M.Ardoise, "Chapeau")
		-- dessous du socle de la lanterne : -0,55 sous son origine
		local lanterne = Lampadaires.lanterne(borne, sol * CFrame.new(0, 2.9 + 0.55, 0), COULEUR_LUMIERE, PORTEE_LUMIERE)
		lanterne.Name = "Lanterne"
		for _, objet in lanterne:GetDescendants() do
			if objet:IsA("BasePart") then
				objet.Anchored, objet.CanCollide, objet.CanTouch, objet.CanQuery = true, false, false, false
			elseif objet:IsA("PointLight") then
				objet.Color, objet.Range, objet.Brightness, objet.Shadows = COULEUR_LUMIERE, PORTEE_LUMIERE, INTENSITE_LUMIERE, false
			end
		end
		-- projecteur invisible posé sur la borne, qui éclaire la statue de bas en haut
		local origine = sol.Position + Vector3.yAxis * 3.2
		local porteur = O.bloc(borne, Vector3.new(0.2, 0.2, 0.2), CFrame.lookAt(origine, cible), C.Fer, M.Lisse, "Projecteur")
		porteur.Transparency = 1
		O.decor(porteur)
		porteur.CanQuery = false
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Angle = 55
		spot.Range = 16
		spot.Brightness = 2.2
		spot.Color = COULEUR_LUMIERE
		spot.Shadows = false
		spot.Parent = porteur
	end
end

statue.Parent = village
