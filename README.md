# Jeu de mine (Roblox)

Le code vit dans `src/` et Rojo le synchronise avec Roblox Studio.

| Dossier | Dans Studio | Contenu |
|---|---|---|
| `src/server` | ServerScriptService › Jeu | Construction du monde au lancement, pioche de braise, minerais |
| `src/client` | StarterPlayerScripts › Jeu | Effets de la pioche et des minerais, animations du décor |
| `src/monde` | ServerStorage › Monde | Générateur de carte : terrain, village, mine, ambiance |

## Installer les outils (une seule fois)

1. Installer [Rokit 1.2.0 pour Windows](https://github.com/rojo-rbx/rokit/releases/tag/v1.2.0) puis ouvrir un nouveau terminal.
2. Dans le dossier qui contient ce README, lancer `rokit install`. Les versions de Rojo, Wally, StyLua, Selene et luau-lsp sont fixées dans `rokit.toml`.
3. Installer le plugin Rojo dans Studio avec `rojo plugin install`, ou via le [Creator Store](https://create.roblox.com/store/asset/13916111004/Rojo) depuis Studio. Redémarrer Studio si le plugin n'apparaît pas.

## Travailler

1. Récupérer les dernières sources avec Git avant toute connexion à la place partagée. Dans le dossier du dépôt, lancer `rojo serve` et laisser ce terminal ouvert.
2. Ouvrir l'expérience Team Create dans Studio. Sous **Plugins › Rojo**, connecter le plugin à `localhost:34872`. Vérifier la liste des changements avant de confirmer la synchronisation.
3. Lancer **Play** pour vérifier en jeu. Les modifications dans `src/` viennent du dépôt. Le décor et les MeshParts importées restent dans la place Team Create.

Activer **Allow HTTP Requests** dans **Fichier › Paramètres de l'expérience › Sécurité** uniquement si une fonctionnalité du jeu doit appeler un service externe via `HttpService`. La connexion locale du plugin Rojo utilise son propre accès à `localhost`.

### Vérifier le code depuis le dépôt

| Besoin | Commande |
|---|---|
| Construire une place de test à partir des sources | `rojo build -o test.rbxl` |
| Vérifier le format d'un script modifié | `stylua --check chemin/du/script.lua` |
| Vérifier le code avec les API Roblox | `selene src` |
| Générer le plan des instances pour luau-lsp | `rojo sourcemap default.project.json -o sourcemap.json` |

Le build de test contient le contenu géré par Rojo. Pour vérifier les modèles importés et le décor de référence, utiliser la place Team Create. Le dépôt n'a actuellement aucun paquet Wally à installer. Lors de l'ajout de la première dépendance, déclarer le paquet dans `wally.toml`, lancer `wally install` et déclarer dans Rojo seulement les dossiers de paquets utilisés par le jeu.

Pour l'analyse Luau, l'[extension officielle de luau-lsp](https://github.com/JohnnyMorganz/luau-lsp#installation) charge les types Roblox et peut utiliser ce `sourcemap.json`. Avec le CLI, utiliser `luau-lsp analyze --platform=roblox --definitions:@roblox=.luau-lsp/globalTypes.d.luau --sourcemap=sourcemap.json src` après avoir téléchargé les [définitions Roblox de la version 1.70.1](https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau) dans `.luau-lsp/`.

### Écran de chargement à la connexion

`src/premier/ChargementJeu.client.lua` (ReplicatedFirst › ChargementJeu) s'affiche dès la connexion, avant le reste du jeu,
et remplace l'écran Roblox par défaut. Sa durée suit le vrai chargement : il reste tant que ces étapes ne sont pas finies
(chacune a un délai maximal) : jeu téléchargé (`game.Loaded`), carte construite (attribut workspace `MondeConstruit`),
personnage apparu avec le sol chargé sous ses pieds, sauvegarde chargée (attribut joueur `DonneesChargees`), puis
textures et sons en attente (`ContentProvider.RequestQueueSize`). Minimum 3 s, maximum 60 s (`DUREE_MIN`, `DUREE_MAX`).
Pendant le chargement, le chat et la liste des joueurs sont masqués et les contrôles coupés ; l'écran s'efface en fondu.

Titre provisoire « LA GRANDE MINE » (constante `TITRE`). Décor « la paroi », tout en Frames (aucune image importée) :
galerie étayée (poteaux, linteau, ferrures boulonnées, jambes de force, stalactites), deux lanternes qui se balancent
avec leur cône de lumière et un vacillement global, mur de roche en blocs voxel en relief avec fissures et minerais en
cristaux qui scintillent, pioche appuyée au poteau, caisse et tonneau, gros rochers sombres au premier plan, chauves-souris,
cailloux qui tombent, braises et poussière. Le titre doré en relief tombe lettre par lettre (poussière, secousse du mur),
puis ondule avec un reflet qui court de lettre en lettre. Deux jauges : une veine d'or qui s'illumine dans la roche, et un
wagonnet chargé de minerais, pourcentage peint sur le flanc, qui avance sur le rail (étincelles, cahots) puis file hors
de l'écran ; éclair doré et fondu à la fin.

En Studio l'écran dure ~10 s, car le serveur retente 4 fois la sauvegarde (DataStore non accessible en Studio).

### Départ du wagonnet

Le village comprend des chemins pavés, un décor fleuri autour de la fontaine et des accessoires miniers. Le style et la palette sont décrits dans `DIRECTION_ARTISTIQUE.md`.

Le quai des profondeurs comporte un banc et deux bacs décoratifs de charbon et d'or ; sa surface en bois est séparée du terrain pour éviter le scintillement.
Les wagons chargés de charbon, bronze, fer ou or exposent les mêmes modèles de minerais que la mine ; les wagons de transport restent libres.

À la gare, appuie sur **E** près du wagonnet vide : le joueur l'enjambe en saut d'obstacle (main posée sur le rebord, jambes groupées par-dessus) et s'assied. Le départ est automatique. Une cinématique en plans de film (bandes noires, interface masquée, contrôles bloqués) montre le wagon quitter la gare vers le tunnel, puis plonger dans la descente, avant un fondu au noir. Le joueur réapparaît debout sur le quai souterrain, face à la caverne. Pour remonter, monte de la même façon dans le wagon du quai souterrain : une cinématique montre la montée et l'arrivée à la gare, où le joueur réapparaît à côté du wagon. Les deux wagons restent à leur place pour les autres joueurs.

Le serveur valide le départ (joueur assis dans le wagon, délai anti-spam), attend l'accusé du client puis téléporte le joueur ; le client ne joue que la cinématique, avec des clones locaux du wagon et du passager (`src/client/CinematiqueWagon.client.lua`). Les plans sont décrits dans la table `PLANS` (sens `aller` et `retour`) : on en ajoute un en ajoutant une entrée (durée, FOV, portion de voie, caméra). Si une cinématique s'allonge, augmenter `FIN_BLOCAGE` dans `src/server/DepartWagon.server.lua`.

L'accès à la grande mine à pied est bloqué par des murs invisibles et une vérification serveur (`ProtectionMine.server.lua`). Le trajet validé en wagon autorise l'accès à la caverne, y compris après un retour des tunnels privés. Pour afficher les barrières pendant les essais, passer `DEBUG_SHOW_WALLS` à `true` en tête du script.

> Si tu avais collé à la main les scripts de la pioche et des minerais dans ServerScriptService ou
> StarterPlayerScripts, supprime ces anciennes copies. Rojo installe les siennes dans les dossiers « Jeu »
> (sinon tu aurais deux pioches et des minerais en double).

## Figer la carte pour la retoucher à la main

En mode édition (pas en Play), dans la barre de commande de Studio :

```lua
require(game.ServerStorage.Monde).construire()
```

Ensuite, sauvegarde la place. Tant que le dossier `Workspace › Carte` existe, le jeu ne reconstruit rien.
Pour régénérer la carte après une modification du code, supprime `Carte` et relance la commande.

## Modèles 3D (Blender)

Les PNJ, le lierre des maisons et les rochers/falaises des montagnes sont modélisés dans Blender
par des scripts Python (`blender/`). Ils sont exportés en FBX dans `assets/` :

| Fichier | Contenu |
|---|---|
| `assets/Nains.fbx` | Les 4 nains Gaspard, Liesel, Brom, Margot, articulés et animés (`blender/nains.py`, remplace `PNJ.fbx`) — voir « Nains du village » plus bas |
| `assets/PNJ.fbx` | Ancienne version humaine des PNJ (ignorée si `Nains` est importé) |
| `assets/Lierre.fbx` | 3 plaques de lierre grimpant + 1 retombant |
| `assets/Rochers.fbx` | 5 rochers, 3 falaises stratifiées, 1 aiguille (dessus enneigé ou moussu) |
| `assets/Arbres.fbx` | 3 pins sylvestres (`Pin1..3`) et 2 saules pleureurs (`Saule1..2`), d'après `previews/arbres/reference_*.png` (`blender/arbres.py`). Les pins remplacent les sapins en blocs de la vallée ; les saules poussent au bord de la rivière. Sans import : arbres en blocs |
| `assets/Sapins.fbx` | 3 sapins / épicéas (`Sapin1..3`, `blender/sapins.py`, mêmes outils que `arbres.py`) : uniquement branches, rameaux qui retombent en peigne et aiguilles fines en arête de poisson (aucun volume en boule), vert sombre bleuté, ~47 000 triangles. Environ un arbre sur quatre dans les forêts et les bosquets, plus nombreux en altitude. Sans import : des pins à la place |
| `assets/Inscription.fbx` | Ancienne inscription en pierre (`blender/inscription.py`), plus utilisée : l'enseigne « LA GRANDE MINE » est maintenant construite en code (voir Mine plus bas) |
| `assets/Auberge.fbx` | Auberge à colombages (`blender/auberge.py`) : **style de toutes les maisons du village** |

### Style des maisons : l'auberge

`blender/auberge.py` reproduit l'image `previews/auberge/reference.png` : rez-de-chaussée en pierre (porte en arc,
fenêtres à volets, jardinières), petit pignon à colombages à gauche, grand pignon à droite, toit central avec lucarne
et cheminée, lierre, tonneaux, auvent. Aperçus : `previews/auberge/Auberge_face|cote|dos|planche.png`, et
`Auberge_comparaison.png` (référence à gauche, planche à droite).

Une fois `Auberge.fbx` importé dans `ServerStorage › Modeles3D` (même méthode que ci-dessous), **toutes les maisons**
(`B.maison` dans `src/monde/Batiments.lua` : maisons, boutiques, taverne, entrepôts, moulin) utilisent ce modèle,
mis à l'échelle de leur largeur. Le plâtre, les tuiles et les volets gardent une nuance de la couleur de chaque maison.
Sans import, les maisons sont construites en blocs Roblox dans le même style (`maisonBlocs` dans `Batiments.lua`),
sans rien à faire dans Studio. Quatre modèles (`modele = 1..4` dans l'appel à `B.maison`) :

| Modèle | Silhouette | Utilisé pour |
|---|---|---|
| 1 | L'auberge : petit pignon à gauche, toit central avec lucarne, grand pignon en avancée à droite, auvent | Taverne, maisons |
| 2 | Grand pignon central en avancée, toits latéraux avec lucarnes, pignons d'extrémité | Comptoir des minerais, maisons |
| 3 | Étage entier à colombages en encorbellement, rangée de fenêtres, lucarnes | Pioches & outils, maisons |
| 4 | Pignon sur rue et appentis à bois | Entrepôts, moulin, maisons |

Chemins : un réseau de chemins du même style que l'anneau de la fontaine (terre, pavés, dalles, bordures) relie les
maisons entre elles, les boutiques, la forge, la taverne, les entrepôts et le moulin. Chaque bâtiment se raccorde au plus
court à un voisin ou au réseau existant (avenue, allée du pont, anneau de la fontaine), plus quelques liaisons entre voisins
proches ; aucun chemin ne traverse une maison, une échoppe, la fontaine ou la rivière. L'allée du sud continue après le pont
pour l'autre rive. Le point d'arrivée est l'attribut `Accueil` du bâtiment (posé dans `Village.lua`) ; le tracé et les
lampadaires qui bordent les chemins sont faits par `Village.preparerSentiers`.

`prestige = true` (maisons des PNJ) : porche couvert avec lanternes, bannières à la couleur de la boutique (`couleur`),
potence avec panneau, jardinières à toutes les fenêtres, rez-de-chaussée plus haut. La forge (`B.forge`) garde son atelier
ouvert mais prend le même style : pierre et colombages, toit de tuiles à deux pans, pignon de façade avec l'enseigne.

Régénérer (après avoir modifié un script) :

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python blender/pnj.py
```

(idem avec `lierre.py`, `rochers.py`, `auberge.py` et `arbres.py`). Des aperçus sont rendus dans `blender/apercus/`.

### Pioches fantasy (voxels à studs, style LihFolk)

`blender/pioches/pioches_brick.py` construit 6 pioches : Demon, Volcan, Givre, Celeste, Neant, Legende.
Chaque pioche = manche et tête séparés, une pièce par matériau (`PiocheDemon_Tete_FerNoir`, `PiocheDemon_Manche_Cuir`...),
~9 studs de haut, < 20 000 triangles par pièce. Sorties dans `blender/pioches/out_<ID>/` (`.glb`, `.fbx`, `.blend`, rendus).

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python blender/pioches/pioches_brick.py -- Demon render
py blender/pioches/presente.py
```

Planches de présentation (face, 3/4, gros plan) : `blender/apercus/pioches/`.

### Importer dans Studio (une fois, puis à chaque régénération)

1. Dans ServerStorage, créer un **Folder** nommé `Modeles3D`.
2. **Accueil › Importer 3D** (ou Fichier › Importer 3D), choisir les 3 fichiers de `assets/`.
3. Dans la fenêtre d'import : décocher **Import as single mesh** (« Importer comme maillage unique »).
   Laisser les autres réglages par défaut, puis **Importer**.
4. Glisser les 3 modèles importés (dans Workspace) **dans `ServerStorage › Modeles3D`**.
5. Supprimer `Workspace › Carte`, relancer `require(game.ServerStorage.Monde).construire()`, sauvegarder.

Sans le dossier `Modeles3D`, le jeu garde les anciennes versions en blocs : rien ne casse.
Les noms des pièces (`Gaspard_Tete_Peau`, `Lierre2_Feuilles`...) servent au jeu : ne pas les renommer.

### Nains du village (modèles et animations)

Les 4 PNJ sont inspirés d'une planche de nains ventrus : Gaspard ← Gromm (barbe grise tressée, manteau de fourrure,
hache runique), Liesel ← Brunhilde (tresses rousses, petite barbe, bandeau), Brom ← Zog (torse nu, bretelles,
casque à lampe), Margot ← Brolg (chope, casque à cornes, cape de fourrure). Ils font ~87 % de la taille d'un joueur
et sont posés sur le vrai sol (terrain, plancher) au lancement. Les pièces `…_Lueur` et `…_Lampe` sont en Neon.

Ils sont **articulés** : chaque bras est découpé en `BrasD`/`AvBrasD`/`MainD` (et `G`), plus `Buste` et `Tete`.
Les repères invisibles `Nom_Groupe_Pivot` marquent les articulations (hanches, cou, épaule, coude, poignet).
Le modèle actuel est importé dans `ServerStorage › Nains`.

| Fichier | Rôle |
|---|---|
| `blender/nains.py` | Modèles + poses clés (`POSES`). Les poses qui touchent un point précis (chope aux lèvres, livre sous les yeux, marteau sur l'épée) sont calculées en évitant que les bras traversent le corps. L'enclume de Brom est placée sous son marteau au moment de la frappe. |
| `src/partage/PosesNains.lua` | Poses exportées par `nains.py` (**généré, ne pas modifier à la main**). |
| `src/client/AnimationsNains.client.lua` | Joue les animations chez chaque joueur : respiration, regard vers le joueur proche, et l'action de chaque nain à intervalle irrégulier (Brom forge avec étincelles, Margot boit, Gaspard lit son registre, Liesel examine sa pioche). Durées et rythmes en tête du fichier. |

Brom frappe l'épée chauffée sur la grande enclume avec des coups sonores. La petite enclume, intégrée au maillage du personnage, est masquée et les protections de ses bottes sont recréées séparément.

Après une modification de `nains.py` : relancer le script (il régénère `Nains.fbx` et `PosesNains.lua`),
puis réimporter `assets/Nains.fbx` à la place de `ServerStorage › Nains`.

> Les maillages importés appartiennent au compte Roblox de celui qui les importe : pour les autres membres,
> Roblox peut refuser de les charger tant qu'ils ne sont pas partagés (groupe Roblox commun). Les pioches
> passent alors automatiquement en version blocs.

## Bâtiments des vendeurs

Les stands des PNJ sont tous à la même distance de la place, juste devant la rue circulaire. Le bâtiment de chaque vendeur
(`batimentVendeur`, `src/monde/Village.lua`) est plus grand qu'une maison et sa façade est collée derrière le stand.
L'enseigne est montée sur les poteaux du stand, au-dessus de l'auvent (`enseigneStand`) : elle ne touche aucun mur.
Chaque vendeur a son annexe : **tour de comptoir** en pierre (Gaspard), **atelier ouvert** avec meule, râtelier et grande
pioche-enseigne (Liesel), **terrasse couverte** avec guirlandes lumineuses et enseigne (Margot). La forge de Brom est inchangée.
À la taverne, les tables et les tonneaux sont installés devant la terrasse, et Margot accueille les joueurs près de l'allée. L'ensemble est en retrait de la rue circulaire ; son ancien raccord pavé est supprimé pour dégager le mobilier. Les réglages de placement et de hauteur de l'auvent sont en tête de `src/monde/Village.lua`.

## Boutique de pioches (Liesel)

Approche-toi de Liesel (« Pioches & outils », à l'ouest de la place) et appuie sur **E** : le HUD de la boutique s'ouvre.

| Fichier | Rôle |
|---|---|
| `src/partage/Pioches.lua` | Catalogue : 11 pioches (Bois offerte, Pierre, Cuivre, Fer, Quartz, Givre → Légende), prix, puissance, vitesse, couleurs. Modifier ici pour équilibrer. |
| `src/server/PiocheBraise.server.lua` | L'outil en main : modèle 3D, aura, frappe, minerais (plus de chaleur ni de Pioche de Braise). |
| `src/server/PiocheDos.server.lua` + `src/client/PiocheDosAnimation.client.lua` | Pioche rangée dans le dos (manche en haut) et geste du bras droit pour la dégainer / ranger. Réglages de pose en tête du script serveur. |
| `src/client/Emplacements.client.lua` | Barre d'objets en bois et laiton (remplace celle de Roblox) : aperçu 3D, touches 1 à 9 ou clic. |
| `src/server/PiochesModeles.lua` | Prépare les modèles 3D Blender (outil en main et aperçu de la boutique). Sans import, pioches en blocs. |

### Pioches 3D dans la boutique

Sans rien importer, les 11 pioches Blender apparaissent en jeu en blocs Roblox (aperçu de la boutique et pioche en main).
Données : `src/partage/PiochesVoxels/` (générées, ne pas modifier). Régénérer après une retouche dans `pioches_brick.py` :
`"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python blender/pioches/exporte_blocs.py`

Version identique à l'Atelier (déjà importée dans `jeu mine .rbxl`, modèle `ServerStorage › Pioches`) :
`assets/Pioches.fbx`, texturé. Chaque pioche a sa texture cuite dans `assets/textures/` (l'import Roblox ignore
les couleurs peintes, d'où la cuisson). Il remplace la version en blocs dès qu'il est présent.

Boutique : les pioches sont rangées dans l'ordre d'achat. On voit celles qu'on possède et la suivante ; les autres
apparaissent en silhouette noire « ??? » sur fond d'éclat rouge et bleu. Acheter une pioche révèle la suivante (animation).
L'aperçu se tourne à la souris et les stats sont comparées à la pioche équipée.

Ancienne note — régénérer `assets/Pioches.fbx` contient les 11 pioches Blender (75 pièces). Régénérer : 
`"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python blender/pioches/exporte_roblox.py`

1. Studio › **Importer 3D** › `assets/Pioches.fbx`, décocher **Importer comme maillage unique**, Importer.
2. Glisser le modèle importé dans `ServerStorage › Modeles3D`, sauvegarder.
3. Play : l'aperçu de la boutique et la pioche en main utilisent les modèles 3D.
| `src/server/Boutique.server.lua` | Bouton « Voir les pioches » sur Liesel, achats validés par le serveur (distance, argent, ordre). |
| `src/client/Boutique.client.lua` | Le HUD : liste, aperçu 3D qui tourne, stats, bouton Acheter / Équiper. |

### Auras des pioches

Chaque pioche reçoit l'aura réglée dans l'Atelier 3D : style, deux couleurs et intensité.

| Fichier | Rôle |
|---|---|
| `src/partage/AurasPioches.lua` | Le réglage de chaque pioche. Modifier ici pour changer une aura en jeu. |
| `src/server/AuraPioche.lua` | Fabrique l'aura : halo, particules, éclairs, volutes, ailes (Divin), vortex (Ombre), runes (Arcane). |

Les réglages faits dans l'Atelier sont enregistrés dans sa base. Pour les reporter dans le jeu, demande à Claude
de relire l'Atelier : il met à jour `AurasPioches.lua`. Comme dans l'Atelier, chaque pièce est doublée de coques lumineuses
(matériau ForceField : liseré, halo, langues). Bois et Pierre n'ont pas d'aura.

Il faut acheter les pioches dans l'ordre. La pioche achetée remplace la précédente dans le sac (stats et couleurs).
Test en Studio : chaque Play donne d'office **5 000 000 Pièces** (`ARGENT_TEST_STUDIO` dans `src/server/Donnees.lua`, 0 pour couper).
Cette partie de test n'est pas sauvegardée : ni l'argent ni les achats ne touchent à la vraie sauvegarde.
Pour en rajouter pendant le Play : `game.ServerStorage.BoutiqueAPI:Invoke("pieces", game.Players.TonNom, 5000)`.

### Minage continu et combos

- **Clic maintenu** : la pioche frappe toute seule, au rythme de la pioche, et suit le viseur. Relâcher arrête
  après le coup en cours. C'est le serveur qui enchaîne les coups (mêmes contrôles qu'un clic).
- **Accélération** : chaque coup enchaîné sans pause ajoute +3,5 % de vitesse, jusqu'à +30 %. Une pause remet à zéro.
  La cadence ne descend jamais sous 0,35 s par coup (durée du geste).
- **Éclat parfait** : un minerai cassé d'une seule série (commencée sur le minerai intact, sans viser ailleurs)
  donne **+1 minerai** dans le sac. Seulement pour les minerais qui demandent au moins 3 coups.
- Une jauge « Cadence » et la « Solidité » du minerai s'affichent au-dessus de la barre d'objets pendant la série.

Réglages dans `CONFIG` de `src/server/PiocheBraise.server.lua` (`ACCEL_PAR_COUP`, `ACCEL_MAX`, `PAUSE_SERIE`,
`BONUS_ECLAT`, `COUPS_MIN_ECLAT`). Affichage : `src/client/ComboMinage.client.lua`.

## Marchand de minerais (Gaspard) et économie

**Changement d'économie** : casser un minerai ne donne plus de Pièces tout de suite. Le minerai va dans le
**sac** ; on le **vend à Gaspard** (Comptoir des minerais, sur la place du village) pour gagner des Pièces,
puis on achète de meilleures pioches chez Liesel. On peut aussi garder ses minerais pour forger chez Brom.
Pour revenir à l'ancien système (Pièces au minage) : `CONFIG.GAIN_DIRECT = true` dans `src/server/Minerais.server.lua`.

Prix de vente (un seul endroit : `src/partage/PrixMinerais.lua`) : Charbon **1**, Bronze **3**, Fer **8**, Or **25** Pièces.
Nouveaux minerais de la mine privée : Soufre **2**, Quartz **4**, Argent **12**, Obsidienne **18**, Givrite **22**, Émeraude **40**,
Rubis **45**, Lunarite **75**, Magmaïte **90**, Diamant **150**, Orichalque **200**, Néantite **250**. Ils vont au sac et se vendent
chez Gaspard, mais **ne se forgent pas encore** (`forgeable = false` dans `Forge.MINERAIS`, hors de `Forge.ORDRE_MINERAIS`).

Le comptoir : touche **E** (manette X, mobile : toucher l'invite) près de Gaspard. À gauche, les minerais du sac
(modèle 3D, rareté, stock, prix à l'unité, valeur totale) ; à droite, le minerai choisi avec le choix de la quantité
(−/+ maintenus pour accélérer, champ à taper, raccourcis ×1, ×10, MAX), le total en direct, **Vendre** et **Tout vendre**.
Après une vente, les pièces s'envolent jusqu'à la bourse. Sac vide : « Rien à vendre, va miner ! ».
Le comptoir se ferme si on s'éloigne (bouton rouge ou touche E / X manette pour le fermer).

| Fichier | Rôle |
|---|---|
| `src/partage/PrixMinerais.lua` | Prix de vente de chaque minerai (lu par le serveur et l'interface). |
| `src/server/Marchand.server.lua` | Invite « Vendre mes minerais » sur Gaspard, ventes validées par le serveur (distance, stock, cadence), retrait du sac puis crédit des Pièces. |
| `src/client/Marchand.client.lua` | L'interface du comptoir (liste, quantité, total, animation des pièces). |

Test en Studio : la partie de test donne 50 de chaque minerai (`TEST_STUDIO` dans `Forge.server.lua`) : de quoi vendre tout de suite.

## Forge de Brom : épées et casques

Tout joueur reçoit l'**épée de base** (`EpeeFer`, 6 dégâts). Chez Brom (touche **E**), il forge de meilleures épées
avec ses minerais (1 ou 2 minerais, de 2 à 12 au total, + des Pièces). Une épée forgée **équipée dans le sac** (case Épée)
remplace l'épée de base dans la main ; on la retire → retour à l'épée de base.

Recettes d'épées (`Forge.ECHELLES.Epee` dans `src/partage/Forge.lua`) — dégâts de base, jusqu'à +35 % avec plus de minerais :

| Rang | Minerais | Modèle | Dégâts |
|---|---|---|---|
| 1 | Charbon | EpeeCharbon | 10 |
| 2 | Bronze | EpeeBronze | 14 |
| 3 | Charbon + Bronze, charbon dominant | EpeeCharbonBronze | 19 |
| 4 | Charbon + Bronze, bronze dominant | EpeeBronzeCharbon | 26 |
| 5 | Fer | EpeeFerPur | 36 |
| 6 | Charbon + Fer | EpeeCharbonFer | 49 |
| 7 | Bronze + Fer | EpeeBronzeFer | 67 |
| 8 | Or | EpeeOr | 91 |
| 9 | Charbon + Or | EpeeCharbonOr | 124 |
| 10 | Bronze + Or | EpeeBronzeOr | 169 |
| 11 | Fer + Or | EpeeFerOr | 230 |

Minerai **dominant** = celui en plus grande quantité ; à égalité, le minerai le plus rare (Bronze avant Charbon).
L'ordre des minerais ne compte pas pour les autres paires (Fer + Charbon = EpeeCharbonFer).
Les casques suivent la même logique (`Forge.ECHELLES.Casque`, 10 rangs, Défense).

Deux pioches décoratives reprennent les couleurs des épées extérieures du râtelier mural de la forge. Leur position et leur échelle sont réglables en tête de `src/server/PiochesMurales.server.lua`.
Les pioches sont fixées à l'intérieur des bords du mur. Le dallage rejoint le seuil au niveau de la rue et la toiture à deux pans ménage un passage pour la cheminée.
La rue à l'est de la forge comporte quatre tonneaux éclairés, et le baquet de trempe a été remplacé par un seau en bois avec une surface d'eau animée.

Deux supports présentent l'armure générique et le casque de bronze à la forge. Les autres porte-armures et les deux anciens modèles de la forge sont conservés en réserve derrière le portail de retour de la plaine des mobs. Les plastrons et jambières réutilisent les modèles génériques du jeu. Les réglages de placement et d'affichage sont en tête de `src/server/ExpositionArmures.server.lua`. Si les meshes importés sont inaccessibles, l'exposition utilise les casques lisses existants du projet.

Après une forge réussie, le serveur lance la **cinématique de forge** (`ForgeCinematique`, voir `src/client/ForgeCinematique.client.lua`) ;
la fenêtre de Brom se cache pendant et affiche le résultat après.

| Fichier | Rôle |
|---|---|
| `src/partage/Forge.lua` | Recettes (logique pure partagée) : échelles épée/casque, minerai dominant, dégâts/défense, prix. |
| `src/server/Forge.server.lua` | Valide la recette, débite minerais et Pièces, crée l'objet, lance la cinématique. |
| `src/server/Epee.server.lua` | Construit l'épée en main (épée forgée équipée ou épée de base), attribut `Degats` sur l'outil. |
| `src/client/Forge.client.lua` | Interface de la forge (aperçu 3D, proportions, célébration après la cinématique). |
| `src/client/ForgeCinematique.client.lua` | Cinématique locale (~5,7 s) : Brom (clone, sur une estrade) martèle 6 fois un lingot de lave sur la grosse enclume, qui s'étire vers l'épée ou le casque, refroidit et révèle l'objet. Attribut joueur `ForgeCinematique` pendant ; repli en fondu si la forge n'est pas chargée. |

## Guilde des Mineurs (quêtes de Margot)

Approche-toi de Margot (taverne) et appuie sur **E** : le tableau de la Guilde s'ouvre. Un « ! » au-dessus d'elle signale
une nouvelle quête, un « ? » une quête à rendre. Les quêtes en cours sont suivies à droite de l'écran (clic sur l'en-tête pour replier).

- **Histoire « La Veine d'Étoile »** : 16 quêtes en 4 chapitres, données par Margot, Gaspard, Liesel et Brom (miner, livrer des minerais,
  forger, acheter une pioche, prendre le wagonnet). Les minerais à livrer sont retirés du sac quand on rend la quête.
- **Contrats du jour** : 3 contrats par jour (identiques sur tous les serveurs, renouvelés à minuit UTC), plus difficiles et mieux payés
  avec le rang. Les 3 rendus le même jour ouvrent le **coffre de la Guilde** (+50 % des pièces des contrats).
- **Rangs** : la renommée gagnée monte le rang (Apprenti → Légende de la Guilde) et donne un bonus permanent de +3 % à +25 %
  sur les pièces gagnées en vendant ses minerais à Gaspard.

L'onglet **Pic Doré** du tableau de Margot propose six quêtes indépendantes de l'histoire et des contrats du jour.
La première est disponible dès la première visite. Chaque quête rendue débloque la suivante. Les pioches achetées, le
casque équipé et les prises du carnet comptent déjà. Les retours des grottes doivent avoir lieu pendant la quête active.
La progression est enregistrée dans la sauvegarde existante.

| Quête | Objectif | Récompense |
|---|---|---|
| Le foyer du Pic Doré | Livrer 8 charbons | 22 Pièces, 15 renommée |
| Un outil pour la relève | Posséder la pioche de cuivre | 32 Pièces, 20 renommée |
| Le casque du veilleur | Porter un casque du sac | 26 Pièces, 20 renommée |
| Retour des Galeries humides | Miner 4 minerais et sortir vivant de −50 m | 45 Pièces, 30 renommée |
| Les histoires du Lac des Lueurs | Avoir 3 prises au carnet de pêche | 42 Pièces, 25 renommée |
| Une ligne de plus au registre | Sortir vivant de −100 m et livrer 4 fers | 78 Pièces, 40 renommée |

| Fichier | Rôle |
|---|---|
| `src/partage/Quetes.lua` | Catalogue : histoire, rangs, générateur des contrats. Modifier ici pour équilibrer (récompenses, quantités). |
| `src/server/Quetes.server.lua` | Progression, livraisons, récompenses et rangs, validés par le serveur (distance de Margot, anti-spam). |
| `src/client/Quetes.client.lua` | Tableau de la Guilde (cartes par type de quête, parchemin, tampon d'état, sceau de cire), suivi à l'écran (progression animée), bandeaux d'annonce (nouvelle quête, objectif, quête terminée, rang), marqueur au-dessus de Margot. |
| `src/client/LogosGuilde.lua` | Logos dessinés en Frames (pioche, enclume, wagon, poisson, sceau de cire…) : aucun emoji ni glyphe spécial. |

Forge, boutique et wagonnet préviennent la Guilde par `ServerStorage.QueteEvenement` ; le minage par `MineraiCasse`.
Test en Studio (partie non sauvegardée) : `game.ServerStorage.QuetesAPI:Invoke("finir", game.Players.TonNom)`
(autres commandes : `"renommee", 500` · `"histoire", 5` · `"reset"`).

## Sauvegarde

`src/server/Donnees.lua` sauvegarde les **Pièces**, les **pioches achetées**, la **pioche équipée** et la **progression de la Guilde**
(DataStore `JeuMine`, une clé par joueur). Sauvegarde automatique toutes les 60 s, au départ du joueur
et à la fermeture du serveur. Le profil est verrouillé par le serveur qui l'utilise : impossible de
dupliquer des pièces en changeant vite de serveur. Si la sauvegarde ne se charge pas, le joueur est
renvoyé avec un message plutôt que de jouer sur un profil vide (qui écraserait le vrai).

Pour la tester dans Studio : **Fichier › Paramètres du jeu › Sécurité › Enable Studio Access to API Services**
(la place doit être publiée). Sans ça, le jeu marche mais rien n'est enregistré (avertissement dans la sortie).

## Caméra des tunnels privés

Dans les tunnels privés (mines privées), la caméra est forcée en **1re personne**. En ressortant, elle repasse en
3e personne. La mine publique et les grottes profondes gardent la caméra libre. Zone : `src/client/CameraMine.client.lua`
(mêmes coordonnées que `src/monde/Disposition.lua`, à mettre à jour ensemble).

## Tunnels privés (mines privées)

**Remonter** : dès qu'on est descendu sous le sol de la galerie dans sa mine privée, un bouton **[H] REMONTER**
apparaît à droite de l'écran avec la profondeur ; clic ou touche H = retour tout en haut de la mine (point d'apparition),
validé par le serveur (`src/server/RemonterMine.server.lua`, bouton : `src/client/RemonterMine.client.lua`).

Dans la caverne, les 6 portes (Tunnel I à VI) sont encastrées dans la paroi : cadre en bois, lanternes et fond noir,
parvis en planches. Devant chaque porte, un **cercle lumineux** au sol (anneau de lumière blanche creux de 5,5 studs
de rayon) affiche « 0/1 ». Quand un joueur entre dedans,
le cercle passe à « 1/1 », lance une gerbe d'étincelles et une colonne de lumière, puis le joueur est téléporté
en moins d'une seconde dans **sa mine privée**. Un cercle ne prend qu'un joueur à la fois.

Une brume blanche et une lumière douce sont ajoutées côté client autour de chaque entrée marquée `CercleTunnel`.
Le centre de l'anneau reste dégagé. Les planches du parvis se rejoignent au niveau du seuil.

La mine privée est construite côté serveur pour ce joueur seul (au premier passage), sur une grille d'emplacements
loin de la carte et en hauteur (`D.MINES_PRIVEES_*` dans `Disposition.lua` : x ≥ 1400, y = 700, écart 400 en X et 1000
en Z). Elle est détruite quand le joueur prend la Sortie ou quitte le jeu (moins de pièces répliquées). C'est une galerie
étayée de 28 studs en Parts (torches, rail et petit wagonnet, caisses, pioche plantée, toiles) **creusée dans** un très
grand **massif de roche** à creuser en descendant : blocs de 2 studs, 40 × 348 × 418 cases (80 de large, 696 de haut,
836 de long ; fond à 676 studs, soit **338 m**, sous la galerie : 1 bloc = 1 m). Au bout de la galerie, une descente déjà
ouverte en pente (35°, 16 studs, 24 de large). Le massif entoure la galerie et la descente : au moins 3 blocs de roche
minable sur les côtés, au-dessus et derrière la galerie (`MARGE`), dans la couleur de la couche (terre battue en haut).
Grille virtuelle côté serveur : le massif est plein par défaut, seules les cases creusées sont mémorisées, et seuls les
blocs exposés à l'air existent en Parts (tag `BlocMine`, attributs `Colonne`, `Ligne` = 1 en bas, `Couche` = 1 à l'avant,
derrière la galerie, dans `MurDeBlocs`) ; les cases de la galerie ne font pas partie du massif. Sur les 6 faces du massif,
une couche de **roche-mère inminable** de 4 studs : pavés presque noirs (`RocheMere*`, attribut `Inminable`),
reconnaissables au premier coup d'œil puisqu'aucune couche de minage n'a cet aspect ; la pioche n'y retire rien.

**Couches de minage** (`src/partage/CouchesMine.lua`, source unique) : 8 couches selon la profondeur, chacune avec sa
couleur et sa matière de roche (limites légèrement ondulées), ses minerais et son palier de pioche requis.

| # | Couche | Profondeur | Minerais (du plus fréquent au plus rare) |
|---|---|---|---|
| 1 | Terre battue | 0–40 m | Charbon, Soufre, Quartz |
| 2 | Grès | 40–85 m | Charbon, Soufre, Quartz, Argent |
| 3 | Roche grise | 85–130 m | Quartz, Argent, Obsidienne |
| 4 | Basalte | 130–170 m | Obsidienne, Givrite, Argent |
| 5 | Glacier | 170–215 m | Givrite, Émeraude, Rubis |
| 6 | Cristaux | 215–255 m | Émeraude, Rubis, Lunarite |
| 7 | Magma | 255–300 m | Magmaïte, Lunarite, Diamant |
| 8 | Néant | 300–338 m | Diamant, Orichalque, Néantite |

**Paliers de pioche (crescendo)** : chaque couche a un `palier` (1 à 8) et chaque pioche aussi
(`CouchesMine.PALIERS_PIOCHES`, réglages centralisés). Un minerai a le palier de la 1re couche où il apparaît
(`PALIERS_MINERAIS`, calculé ; minerais de la mine publique et des grottes : palier 1, donc inchangés).
Écart = palier requis − palier de la pioche, vérifié **côté serveur** (`MinePrivee.creuser` pour la roche,
`PiocheBraise` pour les nœuds via leur attribut `Palier`) :
- **≤ 0** : normal ;
- **1** : presque impossible — roche : la zone ne cède qu'au bout de `COUPS_DUR` (10) coups ; minerai : dégâts × `FACTEUR_DUR` (0,1) ;
- **≥ 2** : impossible — le coup ne fait rien (« clang » + étincelle rouge) et le joueur lit
  « Il te faut une meilleure pioche (X) pour cette couche / ce minerai » (RemoteEvent `AvisMine`, 1 avis / 1,5 s au plus).

| Pioche | Palier | Couches normales | Couche suivante (très lente) |
|---|---|---|---|
| Bûcheron (Bois, départ) | 1 | 1 Terre battue | 2 Grès |
| Silex (Pierre) | 2 | 1–2 | 3 Roche grise |
| Cuivre | 3 | 1–3 | 4 Basalte |
| Fer, Quartz | 4 | 1–4 | 5 Glacier |
| Givre | 5 | 1–5 | 6 Cristaux |
| Volcan | 6 | 1–6 | 7 Magma |
| Céleste | 7 | 1–7 | 8 Néant |
| Démon, Néant, Légende | 8 | toutes | — |

Au viseur (`ViseurPioche.client`) : rond blanc = normal, **orange « TRÈS DUR »** + jauge de progression (envoyée par
le serveur), **rouge « TROP DUR » + cadenas** = hors de portée (affichage seulement, d'après l'attribut `Palier` des blocs).

**À l'écran** (`src/client/CoucheMine.client.lua`) : dès qu'on est dans sa mine, un bandeau en haut affiche
« COUCHE 4 · BASALTE · −142 m », la barre de profondeur découpée en couches avec un repère, et les minerais de la couche
(silhouette « ? » tant qu'on n'en a jamais miné). En descendant dans une couche plus profonde : grande annonce
« Nouvelle couche ! ». Le serveur tient les attributs joueur `CoucheMine` (index) et `ProfondeurMine` (m) dans
`RemonterMine.server.lua`.

**Minerais** : la roche ne rapporte rien. Le massif est découpé en paquets de 3 × 3 × 3 cases, chacun abrite au plus un
**nœud de minerai enfoui**, tiré dans les minerais de sa couche (tirage nouveau à chaque visite : pas de farm des mêmes
nœuds ; les 12 nouveaux minerais de `Partage › MineraisPropositions` n'existent que dans la mine privée). C'est le même
rocher 3D que dans la mine publique (`Partage › MineraisModeles.construire`, réduit à 80 %), créé seulement quand une case
voisine est creusée. Les minerais Épique et plus (Émeraude, Rubis, Lunarite, Magmaïte, Diamant, Orichalque, Néantite)
ont leurs **effets spéciaux** comme dans la vitrine (cristaux géants, halo, éclats, anneau de runes, lune, étincelles),
ajoutés en local par `src/client/EffetsMinesPrivees.client.lua` (module `src/client/EffetsMinerais.lua`). On le
frappe en le visant (rayon serveur tête → point visé ; tag `Minerai`, `PV` ; seul le propriétaire de la mine peut le casser) ; cassé, il va
au sac (`MineraiCasse` → `Minerais.server` → `Donnees.ajouterMinerai`) et sa case reste creusée.

**Creuser** : un viseur (rond + point blanc) est toujours affiché au centre de l'écran
(`src/client/ViseurPioche.client.lua`). À chaque coup, le client envoie le point visé (RemoteEvent `VisePioche`) ;
le serveur le valide (≤ 8 studs de la tête, 0,35 s, rayon serveur jusqu'au premier bloc touché) et `MinePrivee.creuser` retire, dans SA mine seulement,
les blocs d'une zone de la taille du joueur (4,5 × 5,5 × 3 studs, 40 blocs max) centrée sur ce point et orientée
tête → point. Sans visée valide : zone devant, puis devant-bas (inclinée), puis sous les pieds.

Le cercle « Sortie » derrière le point d'apparition ramène le joueur devant le tunnel qu'il avait pris.

| Fichier | Rôle |
|---|---|
| `src/monde/CercleLumineux.lua` | Construit un cercle (anneaux néon, lueurs, compteur) et ses effets (`etat`, `activer`). |
| `src/monde/MinePrivee.lua` | Construit / retrouve / libère la mine privée d'un joueur (galerie + mur de blocs). |
| `src/server/CerclesTunnels.server.lua` | Détection serveur des cercles (boucle 0,1 s, morts ignorés, délai 2,5 s), streaming puis téléportation aller et retour. |
| `src/client/HalosTunnels.client.lua` | Halos des entrées détectées par le tag `CercleTunnel`. |
| `src/monde/Mine.lua` | Portes encastrées et parvis ; `preparerPortes` met à jour les cartes figées. |
| `src/monde/CaverneDecor.lua` | Mise en scène de la caverne (pont suspendu, cascade, rayons, frise, sanctuaire du cristal…), sans collision sur les passages. |

## Grottes profondes (expéditions à 1 ou 2)

Dans la grande salle de la caverne, à droite du Tunnel VI, se trouvent le panneau « Grottes profondes » et **trois cercles lumineux « 0/2 »**
disposés en arc devant l'arche, à 15 studs d'intervalle. Le premier joueur qui entre dans un cercle devient le **chef** de ce groupe :
l'interface de choix de profondeur s'ouvre. Très peu de texte : seulement les niveaux (−50 m … −500 m) et une
**barre de difficulté** calculée selon SON équipement (pioche, épée, défense casque + plastron + jambières), et à droite
les **minerais du palier** : petites pastilles 3D (les vrais modèles de minerai) qui se chevauchent, générées depuis
`Grottes.NIVEAUX`, **du plus fréquent au plus rare** (estimation `Grottes.partsMinerais`). Un minerai que le joueur n'a
**jamais miné** reste une **silhouette noire** avec un « ? » (infobulle « ??? ») ; dès qu'il en casse un (mine publique,
tunnel privé ou grotte), il apparaît en couleurs avec son nom (Charbon, Cuivre, Fer, Or) et sa fréquence. Au survol,
le niveau s'agrandit, la pile s'écarte et les rochers tournent. Le chef peut **inviter** un joueur (amis en premier dans la liste) ; un 2e joueur peut aussi
simplement entrer dans le même cercle (« 2/2 »). Un joueur peut appartenir à un seul groupe à la fois. Quand un chef choisit un niveau, le serveur génère une **grotte aléatoire** réservée à son équipe. Les trois équipes peuvent se former en parallèle et partir vers des grottes distinctes. Le cercle « Sortie » de la grotte ramène devant le cercle de départ. La grotte est détruite
quand plus personne n'est dedans (sortie, mort ou départ du jeu).

La plateforme d'entrée est générée au démarrage dans `Workspace.EntreeGrottes`. Une dalle commune porte les trois cercles et trois marches jointives mènent au seuil. Les rails, traverses et runes sont décoratifs.

5 paliers (réglages dans `src/partage/Grottes.lua`) : plus on descend, plus les minerais sont **rares et résistants**
(du charbon à −50 m jusqu'à surtout de l'or à −500 m) et plus les **mobs** sont dangereux (chauves-souris, zombies,
rampants, brutes, et l'Exécuteur maudit en boss à −500 m). Chaque palier a un équipement **conseillé** :

| Palier | Pioche (puissance) | Épée (dégâts) | Défense |
|---|---|---|---|
| −50 m Galeries humides | 1 | 6 | 0 |
| −100 m Cavernes oubliées | 1,6 | 19 | 10 |
| −200 m Abîme de fer | 2 | 49 | 25 |
| −350 m Profondeurs ardentes | 4 | 124 | 55 |
| −500 m Cœur maudit | 8 | 230 | 100 |

Combat : les mobs (sans Humanoid, déplacés par le serveur) se battent à l'épée ; la défense réduit les dégâts reçus
(`défense / (défense + 60)`). Coup reçu : le mob flashe orange et lâche quelques éclats
(`src/client/EffetCoupMob.client.lua`, déclenché par l'attribut `DernierCoup` posé par le serveur). Les nœuds de minerai se cassent à la pioche, par le chef ou son invité.

**Relief** : les salles sont à des hauteurs très différentes (jusqu'à ~36 studs d'écart), reliées par des pentes
(≤ ~32°) ou des galeries en marches de 2 studs ; certaines salles sont hautes, certains passages bas (plafond ≥ 11) ;
fosses peu profondes (≤ 4 studs, on en ressort) et corniches (≤ 4,5 studs, à sauter). Tout reste praticable à pied,
la salle du fond et le cercle de sortie sont toujours reliés.

**Zone sûre** : ni minerai ni mob ne naît dans un rayon de `Grottes.ZONE_SURE` (55 studs) autour de l'arrivée, et
les mobs n'entrent jamais dans le refuge (`Grottes.ZONE_REFUGE`, 25 studs). La chaîne départ → boss est creusée en
dernier et vérifiée (sinon la grotte est regénérée avec une autre graine).
**Taille** : bloc de roche 360 × 190 × 360 studs (1,5 × l'ancien) ; salles de 21 à 30 studs de rayon, galeries
de ~24 à 33 studs de large, chaîne départ → boss de ~240 studs ; marches, pentes et corniches gardent leurs hauteurs.
**Minerais en gisements (« zones de chaleur »)** : 1 nœud = 1 minerai ; `nombreMinerais` nœuds par grotte
(−50 m 12–14, −100 m 12–13, −200 m 11–13, −350 m 11–13, −500 m 11–13), regroupés en **3–4 gisements de 2 à 5 nœuds**
dans une même salle / alcôve (affleurant dans les murs ou le sol), jamais dans la zone sûre. Chaque gisement a un
type dominant différent (70 % des nœuds) ; les 30 % restants sont tirés au poids. Un minerai `dominant = false`
ne domine jamais un gisement : il reste rare.

| Palier | Minerais (part estimée des nœuds) |
|---|---|
| −50 m | Charbon ~91 %, Cuivre ~9 % (≈ 1 par grotte) |
| −100 m | Charbon ~35 %, Cuivre ~34 %, Fer ~31 % |
| −200 m | Fer ~37 %, Or ~34 %, Cuivre ~29 % |
| −350 m | Fer ~51 %, Or ~49 % |
| −500 m | Or ~56 %, Fer ~44 % |

**Minerais découverts** : profil `mineraisDecouverts = {[id] = true}` (`src/server/Donnees.lua`, champ ajouté sans
changer de version ; ancien profil → déduit du sac et des objets forgés). Mis à vrai par le serveur à chaque minerai
cassé (`Minerais.server.lua`, événement `MineraiCasse`), répliqué par l'attribut joueur `MineraisDecouverts`
(« Charbon,Bronze »). Le menu se met à jour en direct.
**Mobs par groupes de 2–3** : chaque gisement est **gardé** par un groupe (alerte si un joueur s'approche à 28 studs
du gisement, poursuite limitée à 40 studs, puis retour). Les autres mobs errent aussi en groupes. Coup d'épée :
le serveur pose `CoupDirection` puis `DernierCoup` sur le mob (avant `PV`) et le repousse de ~3 studs en 0,18 s
(moins pour les gros mobs, à peine pour le boss, arrêté par les murs).

**Mobs par palier** (PV joueur 150 ; dégâts avant réduction par la défense ; réglages `mobs` / `nombreMobs` dans
`src/partage/Grottes.lua`) :

| Palier | Mobs (PV / dégâts) | Nombre |
|---|---|---|
| −50 m | Zombie mineur 36 / 8, chauve-souris 18 / 5 | 9–11 |
| −100 m | Zombie mineur 90 / 14, chauve-souris 35 / 9, rampant 70 / 12 | 10–12 |
| −200 m | Zombie à lame 240 / 26, zombie mineur 180 / 22, rampant 180 / 22, chauve-souris 70 / 14 | 11–13 |
| −350 m | Zombie mutant 650 / 50, zombie à lame 520 / 44, brute 1200 / 70, chauve-souris 140 / 26 | 11–14 |
| −500 m | Zombie mutant 1400 / 80, brute 2300 / 105, zombie à lame 1100 / 72 + boss Exécuteur 9000 / 170 | 12–14 |

**Décor et ambiance** (appelé à la fin de `GrotteGenerateur.construire`, purement décoratif, jamais dans les
gisements ni à l'arrivée) :
- **Palier 1 (−50 m) « Le Lac des Lueurs »** (`src/monde/GrotteLueurs.lua`, direction artistique dans le coffre
  Obsidian : *01 - Game Design / Grotte 50 m - Le Lac des Lueurs*) : grotte noyée bioluminescente. Camp des mineurs
  à l'arrivée (tente, brasero, table et carte) ; lacs turquoise lumineux creusés dans les salles (là où les gisements
  laissent le plus de place) avec nénuphars, algues, poissons, brume et galets lumineux ; cascade qui tombe du
  plafond dans le grand lac (son « Waterfall », Pro Sound Effects) ; forêt de champignons géants à spores ; voûte de
  vers luisants et fils perlés ; rais de lumière ; géodes cyan / améthyste ; lanternes à vers luisants ; rideaux de
  mousse ; méduses de spores qui flottent ; ruines naines (dallages, colonnes brisées) ; **arche runique** devant la
  salle du boss, gardée par **deux statues géantes de nains** (modèle de Gaspard en pierre) ; temple du boss
  (géode géante, braseros, ossements, cercle de runes, brume violette). **Lisibilité** : chaque salle a une lumière de
  voûte douce teintée par sa zone (plus des relais dans les grandes salles), les galeries un relais tous les 22 studs
  (`MAX_REMPLISSAGE`), les parois sont parcourues de **veines de cristal** néon ramifiées et le pied des parois est
  semé de galets lumineux. Le dossier `Guide` du modèle garde les points du chemin principal (départ → boss) pour les
  feux follets. Modèles : `blender/grotte_lueurs.py` →
  `assets/GrotteLueurs.fbx`, à importer dans `ServerStorage.Modeles3D`.
- **Autres paliers** (`src/monde/GrotteDecor.lua`) : stalactites (gouttes), stalagmites, colonnes, cristaux,
  champignons (`blender/grotte_decor.py` → `assets/GrotteDecor.fbx`), bassins, mousse, racines, restes de mine,
  torches, salle du boss. Le palier 1 réutilise ce module (options) pour les concrétions et les restes de mine.
- Côté joueur : `src/client/AmbianceGrotte.client.lua` (éclairage souterrain en fondu, bloom, réverbération de grotte,
  lueur de lanterne autour du joueur ; au palier 1, couleurs de la roche et de l'eau changées localement et teinte
  qui suit les zones « GrotteZone » : camp ambré, lacs cyan, forêt magenta, temple violet ; tout est restauré à la
  sortie) et `src/client/VieGrotte.client.lua` (méduses, poissons, pulsation des néons, papillons de nuit autour des
  lanternes, gouttes sonores) et `src/client/FeuxFollets.client.lua` (palier 1 : trois feux follets guides qui
  flottent devant le joueur jusqu'au boss, lucioles errantes, onde lumineuse sous chaque pas, lueur des méduses).
  Dans une grotte, AmbianceGrotte pose l'attribut `GrotteActive` sur Lighting et `LumiereSouterraine` se met en
  retrait (les deux scripts ne se battent plus pour l'éclairage).

**Sanctuaire et carte naine (palier 1, qui n'a pas de boss)**
- **Sanctuaire** (`src/server/Sanctuaire.lua`, appelé par `Grottes.server.lua` après les mobs) : quand un joueur
  franchit l'arche runique (22 studs), le modèle reçoit `SanctuaireEveil` → cinématique locale de 4 s
  (`src/client/Sanctuaire.client.lua` : bandes noires, caméra vers l'arche, 11 glyphes qui s'allument un à un, yeux
  des statues qui s'embrasent, titre « Le Sanctuaire de Haldur »). Puis une vague de **gardiens** (mobs du palier,
  pv ×3, aura violette ; 3 + 1 par joueur en plus, max 5) surgit dans le temple ; compteur à l'écran
  (`GardiensRestants`). Quand ils sont vaincus, le **coffre du sanctuaire** s'ouvre (`CoffreOuvert`) : chaque joueur
  peut l'ouvrir une fois (40 pièces, 3 Bronze et un fragment de carte).
- **Carte naine** (`src/partage/CarteNaine.lua`, `src/server/CarteNaine.lua`, `src/client/CarteNaine.client.lua`) :
  8 fragments d'histoire du royaume englouti. Chaque grotte du palier 1 cache 5 rouleaux (fond du grand lac,
  derrière la géode du temple, sous un champignon géant, sous un rideau de mousse, au fond d'une alcôve) ; chaque
  joueur peut ramasser chaque rouleau une fois et reçoit un fragment qu'il n'a pas encore (+15 pièces). Carte
  complète : +300 pièces. Sauvegardé dans le profil (`fragments`, attribut joueur `FragmentsCarte`).
- **Énigme runique** (`GrotteLueurs` section 17, `src/server/SecretsGrotte.server.lua`) : une porte naine scellée,
  creusée dans la roche pleine derrière la paroi d'une salle, montre 3 runes de couleur (cyan, magenta, ambre) dans
  un ordre tiré au hasard (`OrdreRunes`, lu de gauche à droite). Il faut activer les 3 **pierres runiques** de la
  grotte dans cet ordre ; une erreur éteint tout. Réussi : la porte s'enfonce dans le sol et ouvre une **salle
  secrète** (2 Fer, 1 Or, une géode, un fragment de carte en plus des 5 cachettes).
- **Cristaux de lueur** : un amas de cristal minable au pied d'une veine par salle (8 max ; nœud « Minerai » de type
  `Lueur`, cassé par `PiocheBraise` comme les minerais de la grotte) : +4 pièces et 12 % de chance d'un fragment.
- **Musique et sons** (`src/client/SonsGrotte.client.lua`) : nappe de grotte en continu et musique en fondu selon
  la zone (galeries « Stone Cocoon », forêt « Indoor Forest », lacs « Mercury Lake », temple « Rhythm Drone »,
  camp avec feu qui crépite) ; sons de la bibliothèque audio de Studio.
- **Grotte réactive** (`src/client/GrotteReactive.client.lua`, local) : les veines de cristal et les galets
  lumineux s'illuminent quand on passe près d'eux ; les champignons lâchent une bouffée de spores quand on les
  frôle ; chaque coup de pioche envoie une onde de lumière dans les veines autour (de la plus proche à la plus
  lointaine) et fait parfois tomber de la poussière du plafond.
- **Boussole des feux follets** (`src/client/BoussoleFeux.client.lua`, touche **F**, bouton « Boussole » sur
  mobile, Y à la manette) : un feu follet doré guide vers la cachette de fragment la plus proche **à pied** que le
  joueur n'a pas encore ramassée (plus court chemin dans le réseau des galeries, attributs `R<k>_<i>` du dossier
  `Guide` ; tout droit quand la cachette est en vue). Il pulse plus vite en approchant, dure 25 s, puis 40 s de
  recharge ; une plaque en bas à gauche donne l'état. La cachette de la salle secrète ne compte qu'une fois la
  porte runique ouverte. (PathfindingService répond « NoPath » dans ces grottes, d'où le réseau des galeries.)
- **Mobs à thème** (`Grottes.lua` → `mobsZones` du palier 1) : un groupe de mobs qui apparaît dans une zone du
  décor tire ses mobs dans la liste de la zone (`MobsGrotte.groupe`, parts « GrotteZone ») ; ces zones sont servies
  en premier au peuplement. Forêt : **Golem champignon** (lent, coriace, frappe des deux poings) ; lacs : **Crabe
  des lueurs** (rapide, fragile, pinces) ; temple : **Spectre nain** (fantôme translucide qui vole et frappe de sa
  lanterne). Les gardiens du sanctuaire gardent leur propre liste. Les 3 mobs sont écrits **en Luau** avec
  `src/partage/MobsKit.lua` (os, boîtes et clips d'animation décrits par du code, même format Data que les mobs
  exportés de Blender ; `Data.Transparence` pour les pièces translucides) ; ils apparaissent aussi dans la vitrine
  des mobs de la plaine.
- **Événements aléatoires** (`src/server/EvenementsGrotte.lua` + `src/client/EvenementsGrotte.client.lua`) : pendant
  l'expédition (premier après 1 min 30 à 2 min 30, puis toutes les 2 min 30 à 4 min), près d'un joueur hors du camp
  et jamais pendant le combat du sanctuaire, avec un grand bandeau d'annonce :
  - **pluie de cristaux** : 12 éclats tombent du plafond, on les ramasse en marchant dessus (+1 pièce, 25 s) ;
  - **nuée de chauves-souris** : 3-4 chauves-souris jaillissent derrière le joueur ;
  - **éboulement** : tremblement, poussière, gravats ; une veine apparaît (2 Bronze, ou Bronze + Or 30 %) ;
  - **luciole dorée** : elle fuit (12 studs/s) ; l'attraper en 30 s rapporte 25 pièces et 25 % de chance d'un
    fragment de carte.
  Test depuis la barre de commande (serveur) : `require(game.ServerScriptService.Jeu.EvenementsGrotte).forcer(exp,
  "pluie" | "nuee" | "eboulement" | "luciole", joueur)`.
- **Grand lac à passerelles** (`GrotteLueurs.lua`, section 2) : au centre de la plus grande salle (rayon ≥ 13), un
  lac recouvre le passage ; chaque galerie qui arrive dans la salle se prolonge par une **passerelle en bois**
  (planches, longerons, poteaux, rambardes, lanternes) jusqu'à un **îlot** central (colonne de roche et herbe,
  refaite après la mise en eau). La cascade tombe près de la rive. Les petits lacs restent hors du passage.
- **Pêche** (`src/partage/Peche.lua`, `src/server/PecheGrotte.server.lua`, `src/client/PecheGrotte.client.lua`) :
  pontons de pêche (invite « Pêcher ») sur l'îlot et sur la berge des petits lacs. Le bouchon flotte, puis « ÇA
  MORD ! » : il faut ferrer (clic, Espace, A, bouton à l'écran) quand le curseur passe dans la zone verte, 2 à 5
  fois selon le poisson (2 ratés = il s'échappe). 7 poissons du Commun au Légendaire (3 à 80 pièces), bien plus
  de rares sur l'îlot ; carnet de pêche sauvegardé (profil `poissons`, attribut « CarnetPeche ») ; parfois un
  vieux coffret avec un fragment de carte. Le serveur tire le poisson et refuse une prise trop rapide.
- **Arène du temple** (`src/server/ArenaTemple.lua` + `src/client/ArenaTemple.client.lua`) : un gong (posé par
  GrotteLueurs sur le côté du temple) s'éveille quand le coffre du sanctuaire est ouvert. Le frapper lance 8
  vagues de plus en plus dures (crabes, golems, spectres, chauves-souris ; PV +14 % par vague) qui gardent le
  temple. Vague k vaincue : 10 × k pièces (une seule fois par vague et par expédition) ; les 8 vagues : +100 pièces
  et un fragment de carte. Plus de joueur vivant dans le temple pendant 4 s = fin. Record personnel sauvegardé
  (profil `arene`, attribut « RecordArene », affiché sur l'invite du gong). Gong de nouveau actif 20 s après.

### Grottes profondes : un univers par palier

`GrotteGenerateur` choisit le thème du palier dans sa table `THEMES` (palier sans thème : `GrotteDecor`). Les
thèmes 2 à 5 partagent `src/monde/GrotteTheme.lua` (sol / plafond / parois, décor hors du passage et des
gisements, budget de lumières et éclairage de lisibilité, zones « GrotteZone », veines et galets, fil du guide,
**fosse traversée de ponts** jusqu'à un pilier central dans la salle qui laisse le plus de place). Chaque thème
pose ses zones d'ambiance (musique de `SonsGrotte` par alias) et le dossier `Guide` (feux follets, boussole).

| Palier | Thème | Ce qu'on y trouve |
|---|---|---|
| −100 m | `GrotteMine.lua` « La Mine oubliée de Brumefer » | Portail du puits n°3, galeries boisées (cadres de mine, lanternes), rails et wagonnets d'améthyste, **Grand Puits** (cheminée vers le haut, cage d'ascenseur, roue qui tourne, lumière du jour), **Cathédrale d'améthyste** (cristal-roi), éboulement, échafaudages, lanternes fantômes qui flottent, **Treuil géant** (engrenages qui tournent) et filon d'améthyste |
| −200 m | `GrotteFonderie.lua` « La Fonderie de l'Abîme » | Porte de la fonderie royale, **l'Abîme** (gouffre de fer en fusion, ponts à chaînes, pilier-enclume, chaînes géantes), **la Fonderie** (creuset suspendu qui déverse sa coulée, rigoles, lingotières, haut-fourneau), **salle des Rouages** (engrenages géants qui tournent), conduites de cuivre et braseros dans les galeries, **Grande Forge des Rois** (statue du nain forgeron) |
| −350 m | `GrotteLave.lua` « Les Rivières de lave » | Avant-poste de basalte, **lac de lave** qui brûle (ponts de basalte, îlot à l'obélisque d'obsidienne), chutes de lave, **forêt de basalte** (orgues hexagonales), **geysers de feu** à intervalles, pics d'obsidienne, cendres, **Trône de magma** du **Roi déchu** (voir plus bas). Toute la roche passe en basalte sombre (la lave craquelée seulement en berges) |
| −500 m | `GrotteCoeur.lua` « Le Cœur maudit » | Dernier camp d'une expédition, **le Vide suspendu** (gouffre sans fond, dalles runiques, rochers qui flottent), failles du vide qui aspirent la lumière, cristaux corrompus, runes maudites, esprits errants, ossements, **Arène du Cœur** (cœur de cristal géant enchaîné à la voûte au-dessus du combat du boss, piliers d'obsidienne aux flammes violettes, cercle de runes) |

- **Dangers** (`src/server/DangersGrotte.server.lua`) : on tombe dans un gouffre → ramené au bord (−15 PV) ;
  la lave (tag « Lave ») brûle (−10 PV / 0,4 s) ; les geysers (tag « Geyser ») jaillissent toutes les 6 à 9 s
  (fumée d'avertissement, puis −18 PV et projection).
- **Machines** (`src/client/MachinesGrotte.client.lua`) : modèles tagués « Rouage » (attributs Vitesse, Axe)
  qui tournent ; gerbes des geysers ; braises autour du joueur qui brûle.
- La grotte réactive (veines, spores, onde des coups de pioche) et la musique par zone valent pour tous les paliers.
- **Mécaniques signature** (`src/server/MecaniquesGrotte.server.lua` + `src/client/MecaniquesGrotte.client.lua`,
  RemoteEvent « MecaniquesGrotte ») — une par palier :
  - −100 m : **course en wagonnet** (borne « Monter » à la gare : le wagonnet suit les rails, plus vite dans les
    descentes, caméra qui s'incline dans les virages) ; **ascenseur du Grand Puits** (plateforme physique, leviers
    haut/bas) jusqu'à la **Réserve du contremaître**, galerie secrète avec 3 minerais.
  - −200 m : **creuset de la Fonderie royale** (verser 3 Fer → le creuset bascule, le métal remplit les moules,
    +120 pièces, une seule fois par joueur, pour toujours) ; **3 manivelles** remettent les rouages en marche, et quand tout tourne
    le **coffre de l'Abîme** remonte du fond du gouffre (+80 pièces, +2 Or).
    **Quête du Casque du Cœur Magmatique** : 3 reliques volcaniques sont cachées sur de petits autels de basalte
    (salle de la Fonderie, salle des Rouages, salle la plus éloignée du départ). Chaque joueur les ramasse une fois
    pour toujours (sauvegardées). Sur le pilier du gouffre, l'**Enclume des Maîtres** (« Forger ») ouvre une
    interface à 3 ronds, un par relique ; avec les 3, on forge le **Casque du Cœur Magmatique**, unique (un seul par
    joueur, obtenable seulement ainsi) : Défense +15, Vie maximale +25, Résistance au feu +8 % (lave, geysers,
    Seigneur de braise), aucun bonus de vitesse. Modèle en Parts (visible par tous) + FBX/OBJ dans `assets/casques/`.
  - −350 m : **la lave monte** toutes les 2 à 3 min (alerte 6 s, crue sur les berges pendant 16 s : on se réfugie
    sur les prismes de basalte « Refuge ») ; **geyser bleu** propulseur (sans dégâts) vers la **corniche secrète** (2 Or).
    **Le trône du Roi déchu** (`GrotteLave` section 7, `src/server/TroneLave.lua`, `src/client/TroneRoi.client.lua`) :
    au fond de la salle du boss, un trône de l'enfer en blocs (estrade de basalte à marches veinées de lave, trône
    d'obsidienne, grand crâne aux cornes torsadées, cercle de runes et gemme de feu, pointes, accoudoirs à crânes,
    ailes d'obsidienne, chaînes, braseros, colonnes de feu, bassin de lave devant). On s'y assoit (Seat « SiegeRoi »
    ou invite « S'asseoir ») : **cinématique** de 9 s (le trône tremble, le bassin bouillonne, un anneau de flammes
    monte, le **Roi déchu** surgit de la lave, rugit, titre « LE ROI DÉCHU »), puis combat contre le joueur assis
    + au plus un allié présent dans la salle. Roi déchu (`src/partage/MobsVoxels/RoiDechu.lua`, écrit avec MobsKit :
    couronne noircie à pointe brisée en flammes, cape en lambeaux, armure noire et rouge, yeux brûlants, épée de feu,
    aura de braises ; clips Idle, Walk, Run, Attack, Hurt, Roar, Death) : PV 5000 seul, 8500 à deux ; coups de 60
    (avant défense, puis résistance au feu) + **brûlure** 3 s (`Brulure.lua`). Il ne lâche jamais sa cible et la
    suit à **90 % de sa vitesse** (marche 16 → 14,4 ; course 29,6 → 26,6, mesurée côté serveur) : on peut le fuir,
    jamais le semer. Victoire : 250 pièces + 3 Or par joueur (pop-up « Trésor du Roi déchu »), une fois par
    expédition. Défaite (plus personne de vivant dans la grotte, ou 20 s sans cible) : il replonge dans la lave et
    le trône se repose 45 s. Un seul combat à la fois. Réglages en tête de `TroneLave.lua`.
    **Attaques spéciales** (une toutes les 7 s, en rotation avec le coup d'épée, annoncées par une animation et une
    zone rouge au sol, validées côté serveur, brûlantes) : **onde de feu** (il plante l'épée, un anneau de feu de
    16 studs part de lui : sauter au passage ou rester hors du disque rouge, 45) ; **charge** (couloir rouge, puis il
    fonce 18 studs épée en avant, 70) ; **pluie de météores** (6 cercles rouges, dont un sous chaque combattant,
    impacts l'un après l'autre, 40). La cinématique reste sobre (lumières et flammes atténuées, aucun flash plein écran).
  - −500 m : le boss est relié au **Cœur maudit** : à 75, 50 et 25 % de ses PV une des 6 chaînes cède, et dès la
    2e phase les **runes brûlantes** de l'arène (geysers violets) s'éveillent ; à sa mort, cinématique : le Cœur
    se brise en éclats.
  - Test depuis Studio : attribut `ForcerCrue = true` sur le lac (tag « LaveMontante ») pour déclencher une crue.
- `GrotteDecor.decorer` accepte `champignons = false`, `racines = false`, `mine = false`.
- Le contrôle « chemin bouché » du générateur ne régénère plus la grotte pour une simple bosse du sol (rayons à 3,
  6 et 9 studs : bouché seulement si les trois touchent) : la grotte n'est plus générée trois fois de suite.

| Fichier | Rôle |
|---|---|
| `src/partage/Grottes.lua` | Paliers, équipement conseillé, calcul du danger, noms des RemoteEvents. |
| `src/server/Grottes.server.lua` | Entrée (panneau + cercle 0/2), groupe, invitations, lancement, sortie, nettoyage ; stats d'équipement (`StatPioche`, `StatEpee`, `StatDefense`). |
| `src/monde/GrotteGenerateur.lua` | Grotte aléatoire en terrain (galeries, salles, décor, minerais, cercle de sortie). |
| `src/monde/GrotteLueurs.lua` + `blender/grotte_lueurs.py` | Thème du palier 1 « Le Lac des Lueurs » (lacs, cascade, forêt de champignons, ruines naines, statues, temple). |
| `src/monde/GrotteDecor.lua` + `blender/grotte_decor.py` | Décor des grottes (modèles 3D, eau, mousse, restes de mine, salle du boss). |
| `src/client/VieGrotte.client.lua` | Faune et animations des grottes (méduses, poissons, néons, papillons, gouttes). |
| `src/client/AmbianceGrotte.client.lua` | Éclairage souterrain, couleurs et teintes de zone quand le joueur est dans une grotte. |
| `src/client/FeuxFollets.client.lua` | Feux follets guides, lucioles, pas lumineux et lueur des méduses (palier 1). |
| `src/server/Sanctuaire.lua` + `src/client/Sanctuaire.client.lua` | Éveil du sanctuaire (cinématique), vague de gardiens, coffre du temple (palier 1). |
| `src/partage/CarteNaine.lua` + `src/server/CarteNaine.lua` + `src/client/CarteNaine.client.lua` | Fragments de la carte naine : cachettes, récompenses, sauvegarde, parchemin. |
| `src/partage/CasqueMagma.lua` + `src/server/CasqueMagma.server.lua` + `src/client/EnclumeMagma.client.lua` + `src/client/ReliquesMagma.client.lua` | Quête du Casque du Cœur Magmatique (−200 m) : reliques, enclume, forge unique, bonus de vie et résistance au feu. |
| `src/server/SecretsGrotte.server.lua` | Énigme des pierres runiques, porte de la salle secrète, récompense des cristaux de lueur (palier 1). |
| `src/client/SonsGrotte.client.lua` | Ambiance sonore et musique par zone de la grotte −50 m. |
| `src/server/EvenementsGrotte.lua` + `src/client/EvenementsGrotte.client.lua` | Événements aléatoires du palier 1 (pluie de cristaux, nuée, éboulement, luciole dorée). |
| `src/partage/MobsKit.lua` + `src/partage/MobsVoxels/GolemChampignon.lua`, `CrabeLueur.lua`, `SpectreNain.lua` | Atelier pour écrire un mob en Luau ; les 3 mobs à thème du palier 1. |
| `src/partage/Peche.lua` + `src/server/PecheGrotte.server.lua` + `src/client/PecheGrotte.client.lua` | Pêche dans les lacs du palier 1 : poissons, mini-jeu, carnet de pêche. |
| `src/server/ArenaTemple.lua` + `src/client/ArenaTemple.client.lua` | Arène du temple (gong, 8 vagues, record). |
| `src/monde/GrotteTheme.lua` | Outils communs des thèmes de grottes (fosse à ponts, éclairage, zones, veines, guide). |
| `src/monde/GrotteMine.lua`, `GrotteFonderie.lua`, `GrotteLave.lua`, `GrotteCoeur.lua` | Thèmes des paliers −100, −200, −350 et −500 m. |
| `src/server/DangersGrotte.server.lua` + `src/client/MachinesGrotte.client.lua` | Gouffres, lave, geysers ; rouages qui tournent. |
| `src/server/MecaniquesGrotte.server.lua` + `src/client/MecaniquesGrotte.client.lua` | Mécaniques signature : wagonnet, ascenseur, creuset, rouages et coffre de l'Abîme, lave montante, phases du Cœur maudit. |
| `src/client/PopupCoffre.lua` | Pop-up d'ouverture de coffre (coffre dessiné qui tremble et s'ouvre, rayons, étincelles, récompenses en cartes avec minerais 3D) : coffres du sanctuaire et de l'Abîme, lingot royal. |
| `src/client/GrotteReactive.client.lua` | Veines qui s'allument au passage, spores des champignons, onde des coups de pioche (palier 1). |
| `src/client/BoussoleFeux.client.lua` | Boussole des feux follets (touche F) vers la cachette de fragment la plus proche (palier 1). |
| `src/server/MobsGrotte.lua` + `src/client/MobsGrotte.client.lua` | IA des mobs, coups d'épée, renforts, boss ; animations et barres de vie. |
| `src/server/TroneLave.lua` + `src/client/TroneRoi.client.lua` + `src/partage/MobsVoxels/RoiDechu.lua` | Trône de magma (−350 m) : réveil du Roi déchu, cinématique, combat, récompense. |
| `src/client/InterfaceGrottes.client.lua` | Choix de profondeur (barre, minerais du palier en silhouettes / couleurs), groupe, invitations. |

## Boss du village (événement de groupe)

Au bout de la rue du sud (après le pont), l'ancienne Maison13 a laissé la place à **l'Arène des boss** :
une esplanade en pierre taillée (dalle ronde centre (0, 151), rayon 18 : rosace, étoile de laiton, anneaux de dalles ;
parvis rectangulaire x ∈ [−20, 20], z ∈ [140, 168]) avec un **grand cercle lumineux** (rayon 14, 10 à 20 joueurs,
anneau fin et translucide) au milieu. Au sud, la **Porte des boss**, porte naine taillée dans la montagne : façade
en gradins de moellons sombres (corps central de 28 à 33 studs, ailes plus basses), portail à deux battants de fer et
de bois foncé gravés de runes, scellé par des chaînes et un cadenas, fronton en pointe, linteau gravé « ARÈNE DES
BOSS », **crâne du Seigneur de braise** accroché au-dessus du portail, frise aux emblèmes des 3 boss (cristal,
flamme, araignée), corniche à denticules, couronnements crénelés, bannières géantes sur les ailes. Au-dessus et sur
les côtés, la roche de la montagne (talus de terrain, gros rochers, pins, buissons) cache toute la coupe. Devant :
deux **nains gardiens** en pierre sombre et or (≈ 23 studs avec le socle, marteau et hache), les trophées du Titan
(cristal géant) et de la Reine araignée (sa dépouille) sur hauts socles avec un brasero à côté, gradins de pierre le
long des murs de soutènement est / ouest.
Côté rue, deux piliers bas à lanternes (« ARÈNE » / « DES BOSS », x = ±10, de part et d'autre de l'avenue) laissent la vue dégagée depuis le pont. Éclairage
chaud et doux : 6 lumières (luminosité ≤ 1,4), néon seulement sur de petits détails. Sur carte figée, le relief
d'origine est d'abord rétabli autour de la place (anciens creusements), puis seul le parvis est creusé (voxels
alignés). L'esplanade reste à l'écart des Maison11/12 (rien ne creuse sous une maison) ; `PLACE_BOSS_VERSION` dans
`Village.lua` la reconstruit. Le panneau, 26 studs au-dessus du cercle (lisible depuis le pont), affiche le prochain
boss, « Prochain boss dans 6:42 » et « 7/20 joueurs » ; pendant les 30 dernières secondes, une colonne de lumière
fine et des étincelles aux couleurs du boss s'élèvent du cercle.

- **Cycle** : toutes les 7 minutes (45 s dans Studio tant que `DEBUT_RAPIDE_STUDIO = true` ; `CYCLE` / `CYCLE_STUDIO`
  dans `src/partage/BossVillage.lua`), les joueurs vivants dans le cercle (20 max, par ordre d'arrivée) partent ensemble
  dans l'arène. Personne : le compte à rebours repart. Un seul combat à la fois (le panneau affiche « Combat en cours »).
- **Annonce (1 min avant)** : une seule **carte** (`src/client/BossAnnonce.lua`), **en haut d'écran** au village / en surface,
  **compacte sur le bord droit** dans une grotte ou une mine privée (elle bascule toute seule si on change de lieu) : emblème du boss,
  tête 3D du boss, nom doré, titre, grand compte à rebours (depuis l'heure serveur `DebutBoss`), barre de temps, braises ; rouge qui bat
  les 10 dernières secondes (sans son de décompte). Bouton **REJOINDRE LE PORTAIL** (touche R, manette croix haut) : le serveur téléporte le joueur dans le grand cercle
  (seulement depuis le village ou la mine publique, vivant, hors arène) ; **IGNORER** (touche X, croix bas) : la carte disparaît jusqu'au
  boss suivant. Dernière minute aussi : **chevrons lumineux au sol** devant le joueur, vers le cercle (en surface).
  Pendant un combat, la puce en haut d'écran dit « combat en cours · entre dans le cercle » ; après le retour,
  « Prochain boss dans 6:12 ».
- **File d'attente** : dans le cercle, panneau latéral **PRÊT AU COMBAT** (nom et rang du boss, départ, « 7/20 »,
  avatars ronds des participants, son + éclat à chaque arrivée, conseil du boss). Au-delà de 20 : « en réserve ».
- **Départ** : fondu au noir, **écran de chargement** (nom et titre du boss, anneaux de runes qui tournent, barre de
  progression, astuce au hasard), contrôles bloqués et joueurs gelés côté serveur ; téléportation 0,8 s après, puis
  **intro** quand tous sont posés : chargement de **5 s** au total (6 s max d'attente si quelqu'un traîne). Le boss
  est répliqué tout de suite chez tous (`ModelStreamingMode` Persistent) ; si son modèle manque encore, le chargement
  attend 3 s au plus (messages `[BossEntrees]` dans l'Output).
- **Intro du boss (8,6 à 8,8 s, `BossVillage.INTRO`)** : entrée en scène propre à chaque boss (`src/client/BossEntrees.lua`,
  tout en local), filmée en **plans fixes** comme une scène de film — le **Titan de cristal** est une statue de pierre
  (titan pétrifié dans une coque de roche) : gros plan sur un cristal qui tremble à son pied, puis plan large, la statue
  se fissure de veines bleues sous des secousses croissantes, éclate en débris et le titan grogne les bras levés, poings
  tremblants ; la **Reine araignée** descend du haut de l'écran au bout d'un fil en tournoyant, atterrit, se cabre et
  crache une toile qui couvre l'écran puis se dissout ; le **Seigneur de braise** allume un cercle runique, ouvre un
  portail de feu, en jaillit d'un bond vers la caméra et brûle l'herbe en atterrissant (forte secousse, marque
  calcinée). Puis plan bas fixe sur le boss qui rugit, carte de nom dorée façon Souls, retour au joueur et barre de PV.
  Boss invulnérable et immobile, joueurs gelés pendant ce temps. Bouton « Passer » (affichage local seulement).
  Pendant le combat, entrer dans le cercle fait rejoindre l'arène tout de suite, tant qu'il y a moins de 20 joueurs dedans
  (un joueur mort peut revenir ainsi).
- **Rotation** : Titan de cristal → Reine araignée → Seigneur de braise (modèles `src/partage/MobsVoxels/`,
  modèle de secours agrandi si l'un manque).
- **Une arène par boss** (centres dans `D.ARENES_BOSS` de `Disposition.lua`, tous à z = −2600 et sol à Y = 150,
  1600 studs d'écart). Même règles pour les trois : sol de combat plat et dégagé sur le rayon 70 (seule pièce
  solide), murs invisibles, décor bas sans collision dans le cercle, arrivée des joueurs à 40 studs du centre,
  pas de rouge au sol (les zones rouges des attaques restent lisibles), peu de lumières (8 à 17).
  Le boss est tiré au hasard à chaque fois (le même peut revenir). L'arène du premier boss est construite au démarrage ; celle du boss suivant pendant l'attente (fin du combat
  précédent), puis gardée. Modèles `workspace › AreneBoss_<id>` (attributs `Centre`, `Rayon`, `Arene`).
  - **Seigneur de braise → « La Fosse des Rois Nains »** (x = −2600) : volcan. Disque de dalles sombres (rosace
    dorée, cercle de runes naines qui pulsent, fissures, éclats d'obsidienne) suspendu par huit chaînes géantes
    au-dessus d'un ravin de lave (braises, fumée), au cœur d'une immense caverne volcanique (voûte, stalactites à
    gouttes de magma, colonnes, cascades et mer de lave, rocs flottants, aiguilles d'obsidienne). Autour : colisée
    nain en ruine (gradins, colonnade, quatre portes fortifiées et leurs ponts, quatre statues de rois nains,
    bannières rouges et noires qui flottent, braseros, lustre de fer). Braises qui montent, cendres qui tombent.
  - **Titan de cristal → « La Géode du Titan »** (x = −4200) : sol en tranche d'agate polie (anneaux gris-lavande,
    veines et sceau hexagonal de cristal parcourus d'une onde de lumière froide depuis le centre), posé sur un piton
    au-dessus d'une faille aux cristaux luminescents. Autour : géode géante hérissée de cristaux violets et bleus,
    colonnes de cristal du sol à la voûte, grand lustre de cristal, ruines naines englouties (colonnade, grande
    porte traversée de cristaux, tête colossale d'un roi nain à demi enfouie, marteau de guerre géant, deux
    gardiens pris dans des blocs de cristal), ponts et pylônes de cristal.
  - **Reine araignée → « Le Nid de la Reine »** (x = −5800) : vieille salle de mine envahie. Sol de terre battue
    (rails rouillés croisés sur une plaque tournante, toiles plaquées au sol, ossements et casques de mineurs,
    couvées d'œufs qui luisent), anneau d'étais de bois reliés par des toiles géantes, lanternes de mineur, quatre
    galeries (deux murées de toile, deux wagonnets pris dans les fils), prisonniers emmaillotés, voûte basse tendue
    d'une immense toile en entonnoir vers l'antre, cocons suspendus qui se balancent, sac d'œufs luminescent
    au-dessus du centre, brume verdâtre et violacée, spores.
  Dans l'arène, l'éclairage prend l'ambiance de son boss (`src/client/AmbianceArene.client.lua` : lave chaude,
  géode froide bleutée, nid verdâtre ; attribut joueur `DansArene` + index du boss en cours), restauré en sortant.
- **Boss** : IA et coups d'épée de `MobsGrotte` ; PV = Σ épée de chaque joueur (bornée 15…310) × 190 × bonus du boss
  (~3 min de combat), avec au moins 4 joueurs comptés (épée moyenne du groupe) : infaisable à 1 à 3 joueurs (`JOUEURS_MIN`). Coups au corps à corps très forts (200 à 240) et attaques de zone
  **télégraphiées** (zone rouge qui se remplit ~1 s) :
  Titan = onde de choc en anneau (sauter ou se coller à lui), frappe des poings, éclats de cristal sous les joueurs ;
  Reine = crachat de toile en cône, invocation d'araignées (6 max), bond sur un joueur ;
  Seigneur = pluie de météores, cercle de lave (brûle 4 s), souffle de feu en cône.
- **Phases** : à 66 % puis 33 % de PV, le boss s'enrage (2 s invulnérable, rugissement, onde au sol, bandeau
  « PHASE 2 — <Boss> s'enrage ! », secousse, teinte d'ambiance plus intense) ; ses attaques s'accélèrent
  (`CADENCE` : télégraphes plus courts, pauses et recharge du corps à corps réduites) et se renforcent
  (`PUISSANCE` : zones ×1,25 puis ×1,5, dégâts ×1,15 puis ×1,3 — toujours 2 coups pour un débutant) :
  Titan = 2 puis 3 anneaux d'onde, poings de cristal sur d'autres joueurs, éclats sur 6 puis 8 joueurs (2e vague en
  phase 3), **pluie de cristaux** ; Reine = 2 puis 3 crachats, 4 puis 5 araignées, 2 puis 3 bonds, **pluie d'acide**
  (flaques corrosives) ; Seigneur = 6 puis 9 météores (2e salve en phase 3), lave plus large et plus longue, souffle
  qui balaie (éventail de 3 en phase 3), **rayons de feu** en étoile.
- **Transformation à chaque phase** (`TRANSFORMATIONS` dans `src/partage/BossVillage.lua`) : le boss grandit (+15 % par phase), change de couleur en fondu et s'illumine (yeux et veines en néon, lueur autour de lui, éclat de lumière) ; phase 3 : aura de ki. Titan : cristaux violets → magenta → rouge sang ; Reine : marques rouges → vert venimeux → violet sur carapace d'ébène ; Seigneur : lave orange → jaune vif → feu infernal bleu. La hitbox suit la nouvelle taille (`MobsGrotte.grandir`).
- **Écran de chargement** (`src/client/BossChargement.lua`) : un décor par boss (géode de cristaux, nid avec toiles, yeux et araignées, lave avec braises et fissures), portrait 3D du boss en contre-jour qui rugit, nom en impact, menace, mineurs, attaques à éviter, conseil, jauge à thème et astuces qui défilent.
- **Verrouillage (focus)** (`src/client/VerrouBoss.client.lua`) : Ctrl (PC), R3 (manette) ou appui sur le logo en bas à gauche (téléphone) : la caméra suit le boss (sinon le mob le plus proche), réticule rouge « point vital » au milieu du corps (torse / nombril), le personnage lui fait face ; rappuyer libère. Saute si la cible meurt ou s'éloigne. Caméra de visée (`CameraVisee.client.lua`) : souris bloquée au viseur en 3e personne, libre dès qu'une interface ou un pop-up est ouvert (`Curseur.lua`) ou pendant les cinématiques, Alt maintenu pour la libérer ; champ de vision 90 en 1re personne.
- **Ciblage** : le boss attaque au hasard un des mineurs à moins de 24 studs de lui et change de cible toutes les
  2,5 à 4,5 s ; si sa cible s'éloigne, il passe à un mineur proche (ou au plus proche).
- **Barre de PV** : grand trait rouge centré en haut de l'écran, nom du boss en plus petit dessous (PV chiffrés, temps
  restant, traînée animée, petits crans à 66 % et 33 %), seulement dans l'arène. Dessous : « 6 mineurs debout ».
- **Ressenti** : chiffres de dégâts sur le boss (les tiens en blanc vif, dorés et gros sur les gros coups ; ceux des
  autres plus petits et translucides ; regroupés par 0,12 s), secousse si une attaque de zone tombe près de toi,
  éclat rouge sur les bords de l'écran quand tu es touché.
- **Dégâts** : chaque coup du boss (corps à corps ou zone) fait `COUP_BOSS` = 80 avant armure : un débutant (150 PV) survit au 1er coup et meurt au 2e.
- **Régénération des joueurs** (`src/server/Vie.server.lua`, remplace celle de Roblox) : 1 % des PV max/s en combat, 5 %/s après 5 s sans dégât (~20 s pour tout remonter).
- **Mort** : écran « K.O. — Retourne au cercle pour rejoindre le combat », réapparition au village ; le cercle
  renvoie dans l'arène (chargement court, sans intro) tant qu'il y a moins de 20 joueurs dedans.
- **Fin** : victoire → 150 pièces à chaque joueur qui a touché le boss + sa part d'un pot de 450 × participants
  (au prorata des dégâts) ; le boss meurt au ralenti, grosse secousse, bannière **VICTOIRE** (confettis) 2 s, puis
  **écran de résultats** 10 s : temps du combat, **MVP** (couronne), classement des dégâts de tous les participants
  (avatar, nom, barre, pièces), ta ligne surlignée, bouton « Retour au village » (retour anticipé) + retour auto.
  Tous morts ou 5 minutes écoulées → bannière **ÉCHEC**, même écran, le boss disparaît.
  Retour : fondu au noir, téléportation au village, fondu retour.
- **Musique et cris** (`src/client/MusiqueBoss.client.lua`) : une musique d'action par boss dans l'arène (Titan : « Battleground », Reine : « Impending Doom », Seigneur : « Belly Of The Beast », bibliothèque APM sous licence Roblox), plus rapide et plus forte à chaque phase ; cris de douleur propres à chaque boss quand on le frappe (grognements de géant + roche, crissements d'araignée, rugissements rauques ; Pro Sound Effects).
- **Sons de l'interface** : uniquement des sons intégrés de Roblox déjà utilisés dans le jeu (`rbxasset://sounds/…`).

| Fichier | Rôle |
|---|---|
| `src/partage/BossVillage.lua` | Réglages : cycle, boss (stats, attaques), PV, récompenses. |
| `src/server/BossVillage.server.lua` | Cercle + panneau, cycle, téléportations, attaques de zone, récompenses. |
| `src/monde/AreneBoss.lua` | Arènes : `obtenir(id)` (construit au besoin), murs invisibles ; construit la Fosse (Seigneur de braise). |
| `src/monde/AreneCristal.lua` / `src/monde/AreneNid.lua` | La Géode du Titan / le Nid de la Reine. |
| `src/monde/AreneKit.lua` | Outils communs des arènes (repères polaires, incrustations, toiles, cristaux, veines). |
| `src/client/AmbianceArene.client.lua` | Éclairage propre à chaque arène, bannières et cocons qui se balancent, runes qui pulsent, onde des cristaux. |
| `src/monde/Village.lua` (`preparerCercleBoss`) | Arène des boss du village : esplanade, Porte des boss (façade naine), gardiens, trophées, murs latéraux (aussi sur carte figée : retire la Maison13, rétablit le relief). |
| `src/client/BossVillage.client.lua` | Barre de PV du boss, annonces, aiguillage des événements vers les modules ci-dessous. |
| `src/client/BossAttente.lua` | Puce en haut d'écran, chevrons de guidage au sol, panneau « PRÊT AU COMBAT ». |
| `src/client/BossCinematique.lua` | Fondus, écran de chargement, intro du boss (caméra, carte de nom), retour au village. |
| `src/client/BossEntrees.lua` | Entrée en scène propre à chaque boss pendant l'intro (statue, descente au fil, portail de feu), en local. |
| `src/client/BossCombat.lua` | Bandeau de phase, secousses, éclat rouge (touché), « mineurs debout », écran K.O. |
| `src/client/BossResultats.lua` | Bannière VICTOIRE / ÉCHEC, écran de résultats (MVP, classement, retour). |
| `src/client/BossOutils.lua` | Sons, secousse de caméra, blocage des contrôles, avatars, icônes dessinées. |

## Bordures de la carte (château fort, sommets, cascades)

`src/monde/Bordures.lua` habille le tour de la vallée (pur décor, aucune collision) :
- **Château fort** perché sur la crête au-dessus de la mine, façade tournée vers la place : remparts crénelés, 6 tours à toits
  coniques, châtelet avec herse et pont-levis, donjon, grande salle aux vitraux, tour du mage, bannières, fenêtres allumées,
  torches et fumée de cheminée. Le site est choisi automatiquement (terrain plat en hauteur, au bord de la falaise) et aplani.
- **Sommets lointains** : 18 massifs enneigés en anneau au-delà des montagnes jouables, qui s'estompent dans la brume.
- **3 cascades** en particules (flanc du château, et deux qui alimentent la rivière à l'est et à l'ouest) : filets d'eau
  alignés sur leur chute, gouttelettes, vapeur, ruisseaux d'eau du terrain sur les pentes douces, nuage d'embruns,
  éclaboussures et bassin au pied ; la roche autour est mouillée et moussue.
- **Parois stratifiées** (48, bords biseautés, inclinées comme la pente et encastrées, jamais sur les crêtes) sur les falaises : bancs de roche ocre, rose, brun et violet, joints et failles sombres,
  corniches moussues, herbes, buissons fleuris, lierre qui pend, éboulis.
- **Terrain des falaises** : strates géologiques ondulées (roche, grès, calcaire, ardoise, basalte), coulures d'humidité et mousse.
- **Forêt d'altitude** (pins qui se raréfient en montant), **brumes**, **lucioles** (rivière et sous-bois)
  et **oiseaux** (`src/client/Oiseaux.client.lua` : volées autour du château et de la vallée, deux rapaces qui planent).
- **Faune** : troupeaux de **chèvres** sur les corniches herbeuses (`blender/chevre.py` → `assets/Chevre.fbx`), qui broutent
  et relèvent la tête ; **papillons** autour du village ; **poissons** qui sautent dans la rivière ; **feuilles et pétales**
  portés par le vent (`src/client/VieSauvage.client.lua` pour les animations, toutes locales au joueur).

| Fichier | Rôle |
|---|---|
| `blender/chateau.py` → `assets/Chateau.fbx` | Modèle du château (pièces `Chateau_<Groupe>_<Teinte>`) ; aperçus `blender/apercus/chateau_*.png` |
| `blender/cimes.py` → `assets/Cimes.fbx` | 3 massifs lointains `Cime1..3` (Roche / Neige / Ombre) ; aperçu `blender/apercus/cimes.png` |
| `blender/parois.py` → `assets/Parois.fbx` | 4 pans de falaise `Paroi1..4` (pièces par teinte de roche + mousse, lierre, fleurs) ; aperçus `blender/apercus/parois*.png` |
| `src/monde/Bordures.lua` | Placement, couleurs, cascades, parois, forêt, brumes, lucioles. Réglages dans `CONFIG` en tête de fichier. |

Les FBX (et `Rochers.fbx`, `Lierre.fbx`) sont importés dans `ServerStorage › Modeles3D` de la place.
Sans import, le petit château en blocs de `HorizonMine.lua` reste affiché : rien ne casse.

## Plan de la carte

- Nord (-Z) : montagne de la mine. Les joueurs apparaissent sur la place (0, 0, 0), face à la mine.
- Place : fontaine circulaire en pierre, eau animée et bruit d'éclaboussure, cristal flottant, sentiers vers la gare et le pont, 8 points d'apparition, 2 tableaux de classement.
- Ouest : comptoir des minerais et boutique de pioches, avec leurs enseignes au-dessus des auvents. Est : forge (épées et armures) et taverne.
- Rues (plan dans `Village.RUES`, `src/monde/Village.lua`) : une rue circulaire pavée autour de la place passe devant les quatre comptoirs ;
  les rues ouest et est partent entre les boutiques, bordées de deux rangées de maisons alignées façade sur la rue ;
  la rue du sud, après le pont, est une large avenue pavée (16 studs, `SUD_LARGEUR`, de z = 98 à 136) qui mène à
  l'Arène des boss, avec deux maisons de chaque côté écartées à x = ±26 (z = 108 et 127 ; `Village.preparerRueSud`
  les déplace sur les cartes figées) ; 4 lampadaires au bord de l'avenue (x = ±9,6, z ≈ 110 et 126) et les lanternes
  du pont côté sud à x = ±9,6. Chaque porte est reliée à sa rue par une courte allée perpendiculaire
  (`preparerSentiers`, version 15). Éclairage réduit à 16 lampadaires (place, avenue,
  entrée / milieu / bout des rues) + les lanternes du pont (`lanternes`).
- Rendu propre : `Village.terrasser` aplanit le terrain sous et autour de chaque bâtiment (talus en pente douce),
  des **bosquets** (pins, saules près de l'eau) poussent dans les espaces sans maisons, et `Village.degager`
  (appelé en fin de construction) retire tout arbre, rocher, falaise ou paroi posé sur une rue ou dans un bâtiment.
- Les toits du village et les auvents des échoppes sont solides et font rebondir le joueur une fois à la réception d’un saut, y compris sur les bords. Depuis le sol, sauter vers un auvent proche donne l’élan pour monter dessus.
- Avenue nord : gare des wagonnets et voie ferrée vieillie jusqu'à la caverne, avec butoirs rouges et blancs. Le joueur peut monter dans le wagonnet vide avec E et en sortir en sautant.
- Mine : tunnel étayé, descente de 60 studs, grande caverne de cristal (grand cristal violet dans le lobe ouest) avec les 6 portes de tunnels privés encastrées dans la paroi.
- Caverne de cristal (`src/monde/CaverneDecor.lua`, modèle `Mine › DecorCaverne`, attribut `Version`) : deux piliers de roche qui encadrent l'arrivée, reliés par un pont suspendu (plateformes, échafaudage avec échelle, treuil, lanternes) ; faille dans la voûte d'où tombent des rayons de lumière et de la poussière sur une le centre ; frise de runes au-dessus des portes des tunnels ; bassin et cascade souterraine dans le lobe est ; cercle de runes, menhirs, halo de pierres et éclats en orbite autour du grand cristal ; champignons lumineux, racines, stalagmites, vieux rails et wagonnets renversés (éclats de cristal, aucun minerai). Parcours en hauteur praticable : échelle (TrussPart invisible) contre le pilier ouest → plateforme → pont suspendu fixe (sol et garde-corps invisibles) → plateforme du pilier est. Lumières douces (PointLight ≤ 1,5, néons assombris). Sur une carte figée, le décor est ajouté par `Mine.preparerVoie` ; changer `VERSION` le reconstruit.
- Sud : rivière, pont de pierre, moulin à eau en blocs sur la rive sud (`B.moulin` : pierre, colombages, potence à sacs) relié à sa roue par un mécanisme qui tourne (arbre sur pile-palier, rouet denté dans une fosse, lanterne, arbre vertical jusqu'au coffre des meules), son puits, rue du sud et ses maisons. L'allée du moulin (style des sentiers) part de la rue du sud ; la maison qui la bouchait (Maison9) est déplacée en face du moulin, l'auvent de la Maison11 est retiré, et deux bancs à jardinières bordent l'allée côté rivière avec un tonneau entre eux (`Village.preparerCheminMoulin`).
- Rive nord, à l'est du pont : coin des pêcheurs. Ponton sur pilotis accroché à la berge avec la cabane du pêcheur (colombages, toit rouge, cheminée qui fume), filets qui sèchent, tabouret, canne et caisse de poissons (`B.pontonPeche`) ; sur la berge, un petit fumoir à poissons (`B.fumoir`) et un séchoir (`B.sechoirPoissons`). Les deux mineurs figurants (`MineursDecor`) et le lampadaire de l'allée du pont ont été retirés. Un second pin (copie de celui du puits du pont) se dresse à côté du fumoir.
- Enseigne « LA GRANDE MINE » au-dessus du portail (`preparerEnseigne`, `src/monde/Mine.lua`) : lettres en barres de cristal brut facettées, dégradé bleu → violet, légèrement enfoncées dans la roche de la montagne (basalte et grès), grappes de cristaux autour. Sur un échafaudage à droite du dernier E, un nain mineur (`B.nainPiocheur`) lève et abat sa pioche en boucle avec des étincelles (`PiocheurEnseigne.client.lua`).
- Place de la fontaine : 4 bancs en pierre à jardinières fleuries ; on s'y assied avec E (2 places par banc, `BancsAssis.server.lua`).

Toutes les coordonnées sont dans `src/monde/Disposition.lua`.
