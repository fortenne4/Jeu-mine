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

## Guilde des Mineurs (quêtes de Margot)

Approche-toi de Margot (taverne) et appuie sur **E** : le tableau de la Guilde s'ouvre. Un « ! » au-dessus d'elle signale
une nouvelle quête, un « ? » une quête à rendre. Les quêtes en cours sont suivies à droite de l'écran (clic sur l'en-tête pour replier).

- **Histoire « La Veine d'Étoile »** : 16 quêtes en 4 chapitres, données par Margot, Gaspard, Liesel et Brom (miner, livrer des minerais,
  forger, acheter une pioche, prendre le wagonnet). Les minerais à livrer sont retirés du sac quand on rend la quête.
- **Contrats du jour** : 3 contrats par jour (identiques sur tous les serveurs, renouvelés à minuit UTC), plus difficiles et mieux payés
  avec le rang. Les 3 rendus le même jour ouvrent le **coffre de la Guilde** (+50 % des pièces des contrats).
- **Rangs** : la renommée gagnée monte le rang (Apprenti → Légende de la Guilde) et donne un bonus permanent de +3 % à +25 %
  sur les pièces gagnées en vendant ses minerais à Gaspard.

| Fichier | Rôle |
|---|---|
| `src/partage/Quetes.lua` | Catalogue : histoire, rangs, générateur des contrats. Modifier ici pour équilibrer (récompenses, quantités). |
| `src/server/Quetes.server.lua` | Progression, livraisons, récompenses et rangs, validés par le serveur (distance de Margot, anti-spam). |
| `src/client/Quetes.client.lua` | Tableau de la Guilde, suivi à l'écran, bannières, marqueur au-dessus de Margot. |

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
- Les toits du village et les auvents des échoppes sont solides et font rebondir le joueur une fois à la réception d’un saut, y compris sur les bords. Depuis le sol, sauter vers un auvent proche donne l’élan pour monter dessus.
- Avenue nord : gare des wagonnets et voie ferrée vieillie jusqu'à la caverne, avec butoirs rouges et blancs. Le joueur peut monter dans le wagonnet vide avec E et en sortir en sautant.
- Mine : tunnel étayé, descente de 60 studs, grande caverne de cristal (grand cristal violet dans le lobe ouest) avec les 6 portes de tunnels privés encastrées dans la paroi.
- Sud : rivière, pont de pierre, moulin à eau, autres maisons.

Toutes les coordonnées sont dans `src/monde/Disposition.lua`.
