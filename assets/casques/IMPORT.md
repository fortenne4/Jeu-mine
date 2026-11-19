# Import des casques mesh dans Roblox Studio

Fichiers : `assets/casques/<Id>.fbx` (10 casques), générés par `blender/armes/casques_fideles.py`.
Ids : CasqueCharbon, CasqueBronze, CasqueCharbonBronze, CasqueFer, CasqueCharbonFer,
CasqueBronzeFer, CasqueOr, CasqueCharbonOr, CasqueBronzeOr, CasqueFerOr.

Chaque FBX contient **un objet par matériau** (Roche, Fissures, Doublure, Bronze, BronzeClair, Fer, FerClair,
FerSombre, BronzeRouge, Or, OrClair, Gemme) + un petit cube **Racine** au centre de la tête.
Coordonnées FBX = repère Roblox : 1 unité = 1 stud, haut = +Y, devant = -Z, origine = centre de la tête R15.

## Étapes

1. Studio : onglet *Home* > *Import 3D* (ou *File > Import 3D*), choisir `<Id>.fbx`.
2. Dans la fenêtre d'import :
   - **Import as a Model** (pas « single mesh ») : un MeshPart par sous-mesh ;
   - garder les noms d'objets (Roche, Or, Racine…) ;
   - échelle : laisser l'unité proposée (le code recale de toute façon la taille avec `CasquesMeshMateriaux.Taille`) ;
   - *Anchored* indifférent (le code désancre et soude).
3. Renommer le Model importé exactement `<Id>` (ex. `CasqueFerOr`).
4. Créer un dossier **ReplicatedStorage › CasquesMesh** (Folder) et y ranger les 10 Models.
   Ils seront répliqués aux clients (icônes) et lus par le serveur (casque porté).
5. Si plusieurs fichiers : *Bulk Import* (Asset Manager > Import) puis faire glisser les Models dans `CasquesMesh`.

## Ce que fait le code (`src/partage/ArmuresVoxels/init.lua`)

`ArmuresVoxels.construire(id, teinte?, tailleTete?)` :
- si `ReplicatedStorage.CasquesMesh.<id>` existe : clone, recale l'échelle sur la hauteur attendue,
  prend la MeshPart `Racine` comme PrimaryPart (invisible, centre de la tête, devant = -Z), applique
  matériau / couleur / Neon / PointLight de `src/partage/CasquesMeshMateriaux.lua` à chaque MeshPart
  selon son nom, soude tout à Racine (WeldConstraint), puis met à l'échelle de la tête (`tailleTete`) ;
- sinon : version « Lisse » (CSG) actuelle.

## Vérifications

- Le casque doit regarder vers -Z (même sens que le personnage). S'il est retourné, ré-exporter n'est pas
  nécessaire : faire pivoter le Model de 180° autour de Y dans Studio **en gardant Racine au centre**,
  puis remettre la Racine sans rotation.
- Noms des MeshParts : si Studio ajoute un suffixe (ex. `Roche_1`), les renommer comme dans le FBX,
  sinon l'apparence par défaut de l'import est gardée.
- Ne pas renommer le sous-mesh `Doublure` en `Interieur` : `EquipementVisuel` cache les parts nommées `Interieur`.
