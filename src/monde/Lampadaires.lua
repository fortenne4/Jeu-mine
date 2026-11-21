-- Modèles des lampadaires et lanternes, reproduits à partir de l'aperçu validé.
local CollectionService = game:GetService("CollectionService")
local Modeles = {}
local lampadaire = {
	{"BottomStoneFoot", Vector3.new(2.3412, 0.324, 2.3412), CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"CarvedBase", Vector3.new(2.0358, 1.35, 2.0358), CFrame.new(0, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.4667, 0.4353, 0.4235), Enum.Material.Slate, 0, true, false},
	{"BaseTopLip", Vector3.new(2.1987, 0.225, 2.1987), CFrame.new(0, 1.62, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"FrontCarvedPanel", Vector3.new(1.4047, 0.783, 0.0772), CFrame.new(0, 0.945, -1.0734, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"FrontInsetStone", Vector3.new(0.9833, 0.5246, 0.0365), CFrame.new(0, 0.945, -1.1302, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"BackCarvedPanel", Vector3.new(1.4047, 0.783, 0.0772), CFrame.new(0, 0.945, 1.0733, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"BackInsetStone", Vector3.new(0.9833, 0.5246, 0.0365), CFrame.new(0, 0.945, 1.1302, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"LeftCarvedPanel", Vector3.new(0.0772, 0.783, 1.4047), CFrame.new(-1.0811, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"LeftInsetStone", Vector3.new(0.0365, 0.5246, 0.9772), CFrame.new(-1.1443, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"RightCarvedPanel", Vector3.new(0.0772, 0.783, 1.4047), CFrame.new(1.0811, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"RightInsetStone", Vector3.new(0.0365, 0.5246, 0.9772), CFrame.new(1.1443, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"LowerStoneNeck", Vector3.new(0.5994, 0.636, 0.5994), CFrame.new(0, 2.0355, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.4667, 0.4353, 0.4235), Enum.Material.Slate, 0, true, false},
	{"LowerNeckCap", Vector3.new(0.7351, 0.15, 0.7351), CFrame.new(0, 2.3595, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"UpperStoneCollar", Vector3.new(0.7125, 0.69, 0.7125), CFrame.new(0, 10.2535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.4667, 0.4353, 0.4235), Enum.Material.Slate, 0, true, false},
	{"UpperCollarFrontFlute", Vector3.new(0.1357, 0.54, 0.0218), CFrame.new(0, 10.2295, -0.3687, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5922, 0.5529, 0.5216), Enum.Material.Slate, 0, true, false},
	{"UpperStoneCap", Vector3.new(0.7917, 0.15, 0.7917), CFrame.new(0, 10.6255, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.302, 0.2824, 0.2824), Enum.Material.Slate, 0, true, false},
	{"SlenderWoodenPost", Vector3.new(0.4185, 7.504, 0.4185), CFrame.new(0, 6.1595, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"PostFrontDarkGrain", Vector3.new(0.1357, 7.294, 0.0172), CFrame.new(0, 6.1475, -0.216, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"PostWoodBand1", Vector3.new(0.4863, 0.108, 0.4863), CFrame.new(0, 3.7835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"PostWoodBand2", Vector3.new(0.4863, 0.108, 0.4863), CFrame.new(0, 6.0455, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"PostWoodBand3", Vector3.new(0.4863, 0.108, 0.4863), CFrame.new(0, 8.3075, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"CentralWoodenHead", Vector3.new(1.0631, 0.72, 0.8822), CFrame.new(0, 11.0755, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"HeadTopStep", Vector3.new(1.0745, 0.312, 0.9528), CFrame.new(0.181, 11.4715, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.698, 0.4353, 0.2157), Enum.Material.Wood, 0, true, false},
	{"CantileverMainBeam", Vector3.new(4.7069, 0.45, 0.6352), CFrame.new(2.2833, 11.5015, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"CantileverUpperSlab", Vector3.new(4.8754, 0.246, 0.7675), CFrame.new(2.3956, 11.8195, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.698, 0.4353, 0.2157), Enum.Material.Wood, 0, true, false},
	-- Ferrures discrètes, sans collision, qui renforcent visuellement le bras en bois.
	{"ContreventementFer", Vector3.new(0.13, 1.65, 0.12), CFrame.new(0.76, 10.53, -0.25) * CFrame.Angles(0, 0, math.rad(-46)), Color3.fromRGB(49, 43, 42), Enum.Material.Metal, 0, false, false},
	{"ContreventementFer", Vector3.new(0.13, 1.65, 0.12), CFrame.new(0.76, 10.53, 0.25) * CFrame.Angles(0, 0, math.rad(-46)), Color3.fromRGB(49, 43, 42), Enum.Material.Metal, 0, false, false},
	{"CerclageBras", Vector3.new(0.12, 0.5, 0.68), CFrame.new(1.45, 11.5, 0), Color3.fromRGB(49, 43, 42), Enum.Material.Metal, 0, false, false},
	{"CantileverTip", Vector3.new(0.5335, 0.414, 0.7675), CFrame.new(3.8564, 11.5015, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"LeftUndersideStep", Vector3.new(0.6178, 0.348, 0.6263), CFrame.new(1.2839, 11.1355, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"LeftInnerStep", Vector3.new(0.5616, 0.384, 0.7587), CFrame.new(0.4212, 10.8835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"RightUpperStep", Vector3.new(0.622, 0.474, 0.794), CFrame.new(-0.656, 11.2675, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.5686, 0.3294, 0.1529), Enum.Material.Wood, 0, true, false},
	{"RightMiddleStep", Vector3.new(0.7125, 0.468, 0.8998), CFrame.new(-0.9727, 10.9615, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.698, 0.4353, 0.2157), Enum.Material.Wood, 0, true, false},
	{"RightOuterTip", Vector3.new(0.5542, 0.234, 0.6352), CFrame.new(-1.3798, 10.7875, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"UpperSlabJoint1", Vector3.new(0.0203, 0.054, 0.7057), CFrame.new(1.4545, 11.9515, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"UpperSlabJoint2", Vector3.new(0.0203, 0.054, 0.7057), CFrame.new(2.3417, 11.9515, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"UpperSlabJoint3", Vector3.new(0.0203, 0.054, 0.7057), CFrame.new(3.2168, 11.9515, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"UpperSlabJoint4", Vector3.new(0.0203, 0.054, 0.7057), CFrame.new(3.8227, 11.9515, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.3608, 0.2118, 0.1137), Enum.Material.Wood, 0, true, false},
	{"Socle", Vector3.new(1.02, 0.12, 1.02), CFrame.new(4.3419, 9.6835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"SocleEtage", Vector3.new(0.9, 0.13, 0.9), CFrame.new(4.3419, 9.8035, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.2706, 0.2275, 0.1882), Enum.Material.Metal, 0, false, false},
	{"Couvercle", Vector3.new(1.02, 0.12, 1.02), CFrame.new(4.3419, 10.7335, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CouvercleEtage", Vector3.new(0.78, 0.12, 0.78), CFrame.new(4.3419, 10.8435, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.2706, 0.2275, 0.1882), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(3.9419, 10.2535, -0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(3.9419, 10.2535, 0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(4.7419, 10.2535, -0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(4.7419, 10.2535, 0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(4.3419, 10.2535, -0.445, 0.7432, 0.6691, 0, -0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(4.3419, 10.2535, -0.445, 0.7432, -0.6691, 0, 0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(4.3419, 10.2535, 0.445, 0.7432, 0.6691, 0, -0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(4.3419, 10.2535, 0.445, 0.7432, -0.6691, 0, 0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(3.8969, 10.2535, 0, 1, 0, 0, 0, 0.7431, 0.6691, 0, -0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(3.8969, 10.2535, 0, 1, 0, 0, 0, 0.7431, -0.6691, 0, 0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(4.7869, 10.2535, 0, 1, 0, 0, 0, 0.7431, 0.6691, 0, -0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(4.7869, 10.2535, 0, 1, 0, 0, 0, 0.7431, -0.6691, 0, 0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"VitreAmbree", Vector3.new(0.68, 0.75, 0.025), CFrame.new(4.3419, 10.2535, -0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.68, 0.75, 0.025), CFrame.new(4.3419, 10.2535, 0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.025, 0.75, 0.68), CFrame.new(3.9369, 10.2535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.025, 0.75, 0.68), CFrame.new(4.7469, 10.2535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"Flamme", Vector3.new(0.27, 0.5, 0.27), CFrame.new(4.3419, 10.1735, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.7255, 0.2549), Enum.Material.Neon, 0, false, true},
	{"CoeurClair", Vector3.new(0.13, 0.3, 0.13), CFrame.new(4.3419, 10.1335, -0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.9412, 0.6392), Enum.Material.Neon, 0, false, false},
	{"AnseMontant", Vector3.new(0.08, 0.34, 0.08), CFrame.new(4.0319, 11.0435, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"AnseMontant", Vector3.new(0.08, 0.34, 0.08), CFrame.new(4.6519, 11.0435, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"AnseTraverse", Vector3.new(0.7, 0.08, 0.08), CFrame.new(4.3419, 11.2235, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Attache", Vector3.new(0.1, 0.22, 0.1), CFrame.new(4.3419, 11.3635, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
}
local lanterne = {
	{"Socle", Vector3.new(1.02, 0.12, 1.02), CFrame.new(0, -0.49, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"SocleEtage", Vector3.new(0.9, 0.13, 0.9), CFrame.new(0, -0.37, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.2706, 0.2275, 0.1882), Enum.Material.Metal, 0, false, false},
	{"Couvercle", Vector3.new(1.02, 0.12, 1.02), CFrame.new(0, 0.56, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CouvercleEtage", Vector3.new(0.78, 0.12, 0.78), CFrame.new(0, 0.67, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.2706, 0.2275, 0.1882), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(-0.4, 0.08, -0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(-0.4, 0.08, 0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(0.4, 0.08, -0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Montant", Vector3.new(0.11, 0.88, 0.11), CFrame.new(0.4, 0.08, 0.4, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(0, 0.08, -0.445, 0.7431, 0.6691, 0, -0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(0, 0.08, -0.445, 0.7431, -0.6691, 0, 0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(0, 0.08, 0.445, 0.7431, 0.6691, 0, -0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixFer", Vector3.new(0.075, 1.1, 0.07), CFrame.new(0, 0.08, 0.445, 0.7431, -0.6691, 0, 0.6691, 0.7431, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(-0.445, 0.08, 0, 1, 0, 0, 0, 0.7431, 0.6691, 0, -0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(-0.445, 0.08, 0, 1, 0, 0, 0, 0.7431, -0.6691, 0, 0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(0.445, 0.08, 0, 1, 0, 0, 0, 0.7431, 0.6691, 0, -0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"CroixLaterale", Vector3.new(0.07, 1.1, 0.075), CFrame.new(0.445, 0.08, 0, 1, 0, 0, 0, 0.7431, -0.6691, 0, 0.6691, 0.7431), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"VitreAmbree", Vector3.new(0.68, 0.75, 0.025), CFrame.new(0, 0.08, -0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.68, 0.75, 0.025), CFrame.new(0, 0.08, 0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.025, 0.75, 0.68), CFrame.new(-0.405, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"VitreAmbree", Vector3.new(0.025, 0.75, 0.68), CFrame.new(0.405, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.6824, 0.2549), Enum.Material.Glass, 0.38, false, false},
	{"Flamme", Vector3.new(0.27, 0.5, 0.27), CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.7255, 0.2549), Enum.Material.Neon, 0, false, true},
	{"CoeurClair", Vector3.new(0.13, 0.3, 0.13), CFrame.new(0, -0.04, -0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(1, 0.9412, 0.6392), Enum.Material.Neon, 0, false, false},
	{"AnseMontant", Vector3.new(0.08, 0.34, 0.08), CFrame.new(-0.31, 0.87, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"AnseMontant", Vector3.new(0.08, 0.34, 0.08), CFrame.new(0.31, 0.87, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"AnseTraverse", Vector3.new(0.7, 0.08, 0.08), CFrame.new(0, 1.05, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
	{"Attache", Vector3.new(0.1, 0.22, 0.1), CFrame.new(0, 1.19, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Color3.new(0.1569, 0.1412, 0.1294), Enum.Material.Metal, 0, false, false},
}
local function creer(parent, nom, cf, pieces, couleur, portee)
	local modele = Instance.new("Model")
	modele.Name = nom
	for _, d in pieces do
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = d[1], d[2], cf * d[3], d[4], d[5]
		p.Transparency, p.CanCollide, p.Anchored = d[6], d[7], true
		p.CanTouch = false
		p.CanQuery = d[7]
		p.Parent = modele
		if d[8] then
			local lumiere = Instance.new("PointLight")
			lumiere.Name = "LueurFeu"
			lumiere.Color = couleur or Color3.fromRGB(255, 171, 70)
			lumiere.Brightness = 2.2
			lumiere.Range = portee or 14
			lumiere.Shadows = true
			lumiere.Parent = p
			CollectionService:AddTag(lumiere, "LueurLanterne")
		end
	end
	modele.Parent = parent
	return modele
end
function Modeles.lampadaire(parent, cf)
	return creer(parent, "Lanterne", cf * CFrame.Angles(0, math.pi / 2, 0), lampadaire)
end
function Modeles.lanterne(parent, cf, couleur, portee)
	return creer(parent, "LanterneFlamme", cf, lanterne, couleur, portee)
end
return Modeles
