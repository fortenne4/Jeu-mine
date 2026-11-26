# Mineur du Pic Doré

Le fichier `Mineur_du_Pic_Dore.blend` contient le mannequin R15, les pièces
habillées, la scène d’éclairage et six caméras. Les textures sont incorporées
au fichier Blender et disponibles séparément dans `Textures/`.

Les 36 maillages exportables ont des UV sans recouvrement détecté et
des surfaces fermées. La plus grande pièce compte 2 476 triangles.
Les atlas PNG mesurent 512 × 512 ou 1 024 × 1 024.

## Import dans Roblox Studio

1. Testez dans une place de travail avec un mannequin **R15 Block Rig**.
   Ouvrez l’Importateur 3D et choisissez un FBX de `FBX/`. Dans la géométrie,
   utilisez l’unité **Stud**, un haut **Y** et un avant **Z** pour cet export
   Blender. Les cinq vues en pied utilisent le même gabarit, corps seul
   d’environ **4,00 × 5,19 × 1,20 studs**. Comparez les pièces avec votre
   mannequin avant de fixer la taille.
2. `Mineur_Complet.fbx` donne l’assemblage habillé en pose neutre.
   `Corps_R15.fbx` et `FBX/Corps/` donnent les quinze maillages de référence.
   Les FBX isolés sont centrés sur leur pivot d’attache. Pour reprendre
   l’alignement visuel exact, comparez avec le FBX complet.
3. Casque avec lampe. Importez `Casque_Ensemble.fbx` et ajustez-le sur
   `HatAttachment` avec l’outil d’ajustement d’accessoires (AFT), type **Hat**,
   ou soudez le MeshPart à `Head` pour garder l’intégration du skin actuel.
   Les FBX du casque et de la lampe sont aussi fournis séparément.
4. Ceinture et pioche décorative. Positionnez-les depuis le FBX complet,
   puis soudez-les à `LowerTorso`. La pioche se place à la hanche gauche,
   vers l’arrière. Laissez la pioche jouable gérer son propre visuel.
5. Visage, chemise, manches, salopette, jambes, gants et bottes. Importez
   les pièces comme MeshParts cosmétiques et soudez chaque région à
   son segment R15 correspondant. Masquez visuellement les segments de
   jambe, de main et de pied sous la toile, les gants et les bottes.
   Conservez la physique et les articulations du personnage standard.
6. Les FBX embarquent les textures Blender. Si Studio ne les associe pas,
   choisissez le PNG `_Albedo` portant le même nom que le MeshPart et
   assignez-le à `TextureID` ou `SurfaceAppearance.ColorMap`. Pour un
   matériau PBR, associez `_Rugosite` à `RoughnessMap` et `_Metal` à
   `MetalnessMap`. La lentille reste ambrée avec l’albédo
   seul. Le rendu Blender ajoute une légère émission.

## Application au spawn

Conservez le flux serveur actuel du skin. Après création du rig R15, clonez
les MeshParts depuis ServerStorage et soudez-les à chaque segment avec
`Massless` activé et les collisions, requêtes et événements de contact
désactivés. Le casque de mineur se masque quand `ArmureCasque` est présent
et revient quand il est retiré. Vérifiez la réapparition, la visibilité
pour un deuxième joueur, le dégagement coude/genou pendant les animations
de minage et le maintien des équipements déjà sauvegardés.

Ces FBX sont prévus pour un montage rigide en jeu. Un corps animé autonome
ou un vêtement Marketplace extensible exige un squelette pondéré et, pour
les vêtements superposés, les cages R15 correspondantes.

## Régénérer

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' -b --factory-startup --python-exit-code 1 --python .\SkinModel3D\Scripts\construire.py
```

Références Roblox · [Importateur 3D](https://create.roblox.com/docs/studio/importer) · [Échelle FBX depuis Blender](https://create.roblox.com/docs/art/blender) · [Ajustement d’accessoires](https://create.roblox.com/docs/avatar/accessory-fitting-tool)
