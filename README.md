# Jeu de mine (Roblox)

Le code vit dans `src/` et Rojo le synchronise avec Roblox Studio.

| Dossier | Dans Studio | Contenu |
|---|---|---|
| `src/server` | ServerScriptService › Jeu | Construction du monde au lancement, pioche de braise, minerais |
| `src/client` | StarterPlayerScripts › Jeu | Effets de la pioche et des minerais, animations du décor |
| `src/monde` | ServerStorage › Monde | Générateur de carte : terrain, village, mine, ambiance |

## Installer les outils (une seule fois)

1. Installer **Rokit** : https://github.com/rojo-rbx/rokit (suivre « Installation » pour Windows).
2. Dans ce dossier, lancer `rokit install`. Cela installe Rojo à la version fixée dans `rokit.toml`.
3. Installer le plugin Rojo dans Studio : `rojo plugin install`.

## Travailler

1. Dans ce dossier, lancer `rojo serve`.
2. Dans Studio, ouvrir l'onglet **Plugins** › **Rojo** › **Connect**.
3. Lancer **Play** : la carte se construit en quelques secondes, puis les joueurs apparaissent sur la place.

### Départ du wagonnet

Le village comprend des chemins pavés, un décor fleuri autour de la fontaine et des accessoires miniers. Le style et la palette sont décrits dans `DIRECTION_ARTISTIQUE.md`.

À la gare, appuie sur **E** près du wagonnet vide : le joueur l'enjambe en saut d'obstacle (main posée sur le rebord, jambes groupées par-dessus) et s'assied. Le départ est automatique. Une cinématique en plans de film (bandes noires, interface masquée, contrôles bloqués) montre le wagon quitter la gare vers le tunnel, puis plonger dans la descente, avant un fondu au noir. Le joueur réapparaît debout sur le quai souterrain, face à la caverne. Pour remonter, monte de la même façon dans le wagon du quai souterrain : une cinématique montre la montée et l'arrivée à la gare, où le joueur réapparaît à côté du wagon. Les deux wagons restent à leur place pour les autres joueurs.

Le serveur valide le départ (joueur assis dans le wagon, délai anti-spam), attend l'accusé du client puis téléporte le joueur ; le client ne joue que la cinématique, avec des clones locaux du wagon et du passager (`src/client/CinematiqueWagon.client.lua`). Les plans sont décrits dans la table `PLANS` (sens `aller` et `retour`) : on en ajoute un en ajoutant une entrée (durée, FOV, portion de voie, caméra). Si une cinématique s'allonge, augmenter `FIN_BLOCAGE` dans `src/server/DepartWagon.server.lua`.

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

Régénérer (après avoir modifié un script) :

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python blender/pnj.py
```

(idem avec `lierre.py` et `rochers.py`). Des aperçus sont rendus dans `blender/apercus/`.

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

Après une modification de `nains.py` : relancer le script (il régénère `Nains.fbx` et `PosesNains.lua`),
puis réimporter `assets/Nains.fbx` à la place de `ServerStorage › Nains`.

> Les maillages importés appartiennent au compte Roblox de celui qui les importe : pour les autres membres,
> Roblox peut refuser de les charger tant qu'ils ne sont pas partagés (groupe Roblox commun). Les pioches
> passent alors automatiquement en version blocs.

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

## Marchand de minerais (Gaspard) et économie

**Changement d'économie** : casser un minerai ne donne plus de Pièces tout de suite. Le minerai va dans le
**sac** ; on le **vend à Gaspard** (Comptoir des minerais, sur la place du village) pour gagner des Pièces,
puis on achète de meilleures pioches chez Liesel. On peut aussi garder ses minerais pour forger chez Brom.
Pour revenir à l'ancien système (Pièces au minage) : `CONFIG.GAIN_DIRECT = true` dans `src/server/Minerais.server.lua`.

Prix de vente (un seul endroit : `src/partage/PrixMinerais.lua`) : Charbon **1**, Bronze **3**, Fer **8**, Or **25** Pièces.

Le comptoir : touche **E** (manette X, mobile : toucher l'invite) près de Gaspard. À gauche, les minerais du sac
(modèle 3D, rareté, stock, prix à l'unité, valeur totale) ; à droite, le minerai choisi avec le choix de la quantité
(−/+ maintenus pour accélérer, champ à taper, raccourcis ×1, ×10, MAX), le total en direct, **Vendre** et **Tout vendre**.
Après une vente, les pièces s'envolent jusqu'à la bourse. Sac vide : « Rien à vendre, va miner ! ».
Le comptoir se ferme si on s'éloigne (Q ou ✕ pour le fermer).

| Fichier | Rôle |
|---|---|
| `src/partage/PrixMinerais.lua` | Prix de vente de chaque minerai (lu par le serveur et l'interface). |
| `src/server/Marchand.server.lua` | Invite « Vendre mes minerais » sur Gaspard, ventes validées par le serveur (distance, stock, cadence), retrait du sac puis crédit des Pièces. |
| `src/client/Marchand.client.lua` | L'interface du comptoir (liste, quantité, total, animation des pièces). |

Test en Studio : la partie de test donne 50 de chaque minerai (`TEST_STUDIO` dans `Forge.server.lua`) : de quoi vendre tout de suite.

## Sauvegarde

`src/server/Donnees.lua` sauvegarde les **Pièces**, les **pioches achetées** et la **pioche équipée**
(DataStore `JeuMine`, une clé par joueur). Sauvegarde automatique toutes les 60 s, au départ du joueur
et à la fermeture du serveur. Le profil est verrouillé par le serveur qui l'utilise : impossible de
dupliquer des pièces en changeant vite de serveur. Si la sauvegarde ne se charge pas, le joueur est
renvoyé avec un message plutôt que de jouer sur un profil vide (qui écraserait le vrai).

Pour la tester dans Studio : **Fichier › Paramètres du jeu › Sécurité › Enable Studio Access to API Services**
(la place doit être publiée). Sans ça, le jeu marche mais rien n'est enregistré (avertissement dans la sortie).

## Tunnels privés (mines privées)

Dans la caverne, les 6 portes (Tunnel I à VI) sont encastrées dans la paroi : cadre en bois, lanternes et fond noir,
parvis en planches. Devant chaque porte, un **cercle lumineux** au sol (anneau de lumière blanche creux de 5,5 studs
de rayon) affiche « 0/1 ». Quand un joueur entre dedans,
le cercle passe à « 1/1 », lance une gerbe d'étincelles et une colonne de lumière, puis le joueur est téléporté
en moins d'une seconde dans **sa mine privée**. Un cercle ne prend qu'un joueur à la fois.

La mine privée est construite côté serveur pour ce joueur seul (au premier passage), sur une grille d'emplacements
loin de la carte (`D.MINES_PRIVEES_*` dans `Disposition.lua`, x ≥ 1400, écart 400). Elle est détruite quand le joueur
prend la Sortie ou quitte le jeu (moins de pièces répliquées). C'est une galerie étayée de 28 studs en Parts (torches,
rail et petit wagonnet, caisses, pioche plantée, toiles) qui débouche sur un très grand **massif de roche** à creuser
en descendant : blocs de 2 studs, 10 × 86 × 100 cases (20 de large, 172 de haut, 200 de long ; fond à 160 studs sous
la galerie), face de départ en pente (35°, 16 premiers studs ouverts). Grille virtuelle côté serveur : le massif est
plein par défaut, seules les cases creusées sont mémorisées, et seuls les blocs exposés à l'air existent en Parts
(tag `BlocMine`, attributs `Colonne`, `Ligne` = 1 en bas, `Couche` = 1 côté galerie, dans `MurDeBlocs`). Les bords et
le fond sont indestructibles. **Minerais** : table `MinePrivee.MINERAIS` par profondeur (charbon près de la surface pour
l'instant, filons déterministes par joueur) ; bloc sombre tacheté, attribut `Minerai`. Casser un bloc de minerai
l'ajoute au sac (`Donnees.ajouterMinerai`), à vendre au marchand.

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
| `src/monde/Mine.lua` | Portes encastrées (`portes`, version 2) et grand cristal ; `preparerPortes` / `preparerCristal` mettent à jour une carte figée. |

## Plan de la carte

- Nord (-Z) : montagne de la mine. Les joueurs apparaissent sur la place (0, 0, 0), face à la mine.
- Place : fontaine circulaire en pierre, eau animée et bruit d'éclaboussure, cristal flottant, sentiers vers la gare et le pont, 8 points d'apparition, 2 tableaux de classement.
- Ouest : comptoir des minerais et boutique de pioches, avec leurs enseignes au-dessus des auvents. Est : forge (épées et armures) et taverne.
- Les toits du village et les auvents des échoppes sont solides et font rebondir le joueur une fois à la réception d’un saut, y compris sur les bords. Depuis le sol, sauter vers un auvent proche donne l’élan pour monter dessus.
- Avenue nord : gare des wagonnets et voie ferrée vieillie jusqu'à la caverne, avec butoirs rouges et blancs. Le joueur peut monter dans le wagonnet vide avec E et en sortir en sautant.
- Mine : tunnel étayé, descente de 60 studs, grande caverne de cristal (grand cristal violet dans le lobe ouest) avec les 6 portes de tunnels privés encastrées dans la paroi.
- Sud : rivière, pont de pierre, moulin à eau, autres maisons.

Toutes les coordonnées sont dans `src/monde/Disposition.lua`.
