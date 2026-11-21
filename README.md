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

À la gare, appuie sur **E** pour monter dans le wagonnet vide, puis regarde le levier sous le panneau « Départ » et appuie sur **F** pour rejoindre le quai au fond de la mine. Pour remonter, monte dans le wagon et actionne avec **F** le levier « Retour » du quai souterrain. Le début du trajet est visible à la troisième personne, suivi d'un écran de chargement apparaissant progressivement jusqu'à l'arrivée. Si tu actionnes un levier à pied, un message te demande de monter dans le wagon.

Depuis le wagon, le joueur lance une pierre à deux mains vers le levier ; le départ se déclenche à l'impact.

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

## Sauvegarde

`src/server/Donnees.lua` sauvegarde les **Pièces**, les **pioches achetées** et la **pioche équipée**
(DataStore `JeuMine`, une clé par joueur). Sauvegarde automatique toutes les 60 s, au départ du joueur
et à la fermeture du serveur. Le profil est verrouillé par le serveur qui l'utilise : impossible de
dupliquer des pièces en changeant vite de serveur. Si la sauvegarde ne se charge pas, le joueur est
renvoyé avec un message plutôt que de jouer sur un profil vide (qui écraserait le vrai).

Pour la tester dans Studio : **Fichier › Paramètres du jeu › Sécurité › Enable Studio Access to API Services**
(la place doit être publiée). Sans ça, le jeu marche mais rien n'est enregistré (avertissement dans la sortie).

## Plan de la carte

- Nord (-Z) : montagne de la mine. Les joueurs apparaissent sur la place (0, 0, 0), face à la mine.
- Place : fontaine circulaire en pierre, eau animée et bruit d'éclaboussure, cristal flottant, sentiers vers la gare et le pont, 8 points d'apparition, 2 tableaux de classement.
- Ouest : comptoir des minerais et boutique de pioches, avec leurs enseignes au-dessus des auvents. Est : forge (épées et armures) et taverne.
- Les toits du village et les auvents des échoppes sont solides et font rebondir le joueur une fois à la réception d’un saut, y compris sur les bords. Depuis le sol, sauter vers un auvent proche donne l’élan pour monter dessus.
- Avenue nord : gare des wagonnets et voie ferrée vieillie jusqu'à la caverne, avec butoirs rouges et blancs. Le joueur peut monter dans le wagonnet vide avec E et en sortir en sautant.
- Mine : tunnel étayé, descente de 60 studs, grande caverne de cristal avec les 6 portes de tunnels privés.
- Sud : rivière, pont de pierre, moulin à eau, autres maisons.

Toutes les coordonnées sont dans `src/monde/Disposition.lua`.
