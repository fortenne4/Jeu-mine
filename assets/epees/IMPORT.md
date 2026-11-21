# Import des épées mesh dans Roblox Studio

Fichiers : `assets/epees/<Id>.fbx` (11 épées de la forge), générés par `blender/armes/epees_fideles.py`.
Ids : EpeeCharbon, EpeeCharbonBronze, EpeeCharbonFer, EpeeCharbonOr, EpeeBronze, EpeeBronzeCharbon,
EpeeBronzeFer, EpeeBronzeOr, EpeeFerPur, EpeeFerOr, EpeeOr. (`EpeeFer` = épée de base en Parts, inchangée.)

Chaque FBX contient **un objet par rôle de matériau** (Lame, Fil, Gorge, Fissures, Cadre, Lisere, Gemme,
Garde, Bras, Embout, Bague, Manche, Tresse, Pommeau, Aura selon l'épée) + un petit cube **Poignee**
au centre de la prise en main. Coordonnées FBX = repère Roblox : 1 unité = 1 stud, lame vers +Y,
plat de la lame face à -Z, origine = centre de la prise. Longueur ≈ 4.2 studs (comme EpeeFer).

## Étapes

1. Studio : *Home* > *Import 3D*, choisir `<Id>.fbx`.
2. Dans la fenêtre d'import :
   - **Import as a Model** (pas « single mesh ») : un MeshPart par sous-mesh ;
   - garder les noms d'objets (Lame, Fil, Poignee…) ;
   - échelle : laisser l'unité proposée (le code recale la hauteur avec `EpeesMeshMateriaux.Taille`).
3. Renommer le Model importé exactement `<Id>` (ex. `EpeeFerOr`).
4. Créer un dossier **ReplicatedStorage › EpeesMesh** (Folder) et y ranger les 11 Models.

Tant qu'une épée n'est pas importée, le jeu affiche l'EpeeFer teintée à la couleur du minerai.

## Ce que fait le code (`src/partage/ArmesVoxels/init.lua`)

`ArmesVoxels.construire(id)` :
- si `ReplicatedStorage.EpeesMesh.<id>` existe : clone, recale l'échelle, prend la MeshPart `Poignee`
  comme PrimaryPart (invisible, axes alignés), applique matériau / couleur / Neon / PointLight de
  `src/partage/EpeesMeshMateriaux.lua` selon le nom de chaque MeshPart, soude tout à Poignee
  (WeldConstraint) et ajoute les Attachments `TrailA` / `TrailB` dans `Lame` ;
- sinon : EpeeFer teintée (`Teinte`). `ArmesVoxels.existe(id)` est vrai pour les 11 ids.

Contrat identique à EpeeFer : `Epee.server.lua` renomme `Poignee` en `Handle` (Tool.Grip inchangé).

## Vérifications

- Le plat de la lame doit regarder -Z et la pointe +Y. Si Studio a tourné le modèle, faire pivoter le Model
  en gardant `Poignee` au centre, puis remettre `Poignee` sans rotation.
- Si Studio ajoute un suffixe aux noms (ex. `Lame_1`), les renommer comme dans le FBX.
- `Aura` (épée d'or) : volutes Neon semi-transparentes fixes. L'équipe effets peut les animer
  (rotation lente) ou les remplacer par des Beams.
