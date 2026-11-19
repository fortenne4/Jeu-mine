# AGENTS.md — Consignes pour les agents IA (Claude Code, Codex/ChatGPT)

Projet : **jeu de mine Roblox** développé à plusieurs, chacun avec son agent IA (Claude Code ou Codex).
Dépôt : https://github.com/fortenne4/Jeu-mine (branche `main`).
Langue du projet : **français** (réponses, noms de fichiers, variables, messages de commit).

Ce fichier est la source unique de consignes. `CLAUDE.md` l'importe. Le `README.md` décrit le jeu en détail :
le lire avant de toucher à un système.

---

## 1. Commandes rapides du chat

Les collaborateurs ne connaissent pas Git. Ils tapent juste un mot dans le chat. L'agent fait tout le reste,
explique en une phrase ce qui s'est passé, et **ne perd jamais le travail de personne**.

### « pull » (ou « récupère », « mets à jour ») → récupérer la dernière version

1. `git status` : s'il y a des modifications locales non commitées, **ne rien écraser**.
   Proposer : « commit and push d'abord » ou les mettre de côté (`git stash`), puis les réappliquer après le pull.
2. `git fetch origin`, puis regarder ce qui arrive : `git log --oneline HEAD..origin/main` et
   `git diff --stat HEAD origin/main`.
3. Si le fichier place (`jeu mine .rbxl`) fait partie des changements entrants : demander au collaborateur
   de **sauvegarder puis fermer la place dans Roblox Studio** avant de continuer (sinon Studio réécrira
   l'ancienne version par-dessus). Attendre sa confirmation.
4. `git pull --rebase origin main`.
5. Résumer en français : qui a changé quoi (liste courte des commits), et ce qu'il faut faire ensuite
   (ex. « rouvre la place dans Studio », « Rojo resynchronise tout seul les scripts de `src/` »).

### « commit and push » (ou « envoie », « sauvegarde sur GitHub ») → publier son travail

1. Rappeler au collaborateur de **sauvegarder la place dans Studio (Ctrl+S)** si il l'a modifiée.
2. `git status` + `git diff --stat` : vérifier ce qui part. Ne jamais committer de secrets, de fichiers
   `*.lock`, ni ce qui est dans `.gitignore`. Signaler tout fichier > 50 Mo (GitHub refuse > 100 Mo).
3. `git add -A` puis commit avec un message **en français, clair, au présent**, qui dit ce qui a changé
   côté jeu. Format : `<zone> : <ce qui change>`. Exemples :
   - `boutique : ajoute la pioche Givre et rééquilibre les prix`
   - `mine : corrige les blocs qui flottent dans les tunnels privés`
   - `forge : nouvelle recette épée de cuivre`
4. `git pull --rebase origin main` **avant** de pousser (quelqu'un a pu pousser entre-temps).
5. `git push origin main`.
6. Confirmer : « Envoyé : <message du commit> ». Si le push échoue, expliquer pourquoi simplement.

### « statut » (ou « où on en est ») → `git status` + derniers commits, résumé en 3 lignes.

---

## 2. Règles Git (obligatoires)

- **Jamais** `git push --force`, `git reset --hard`, `git clean -fd`, `git checkout -- .` ou réécriture
  d'historique sans accord explicite du collaborateur dans le chat. Ces commandes détruisent du travail.
- Toujours `pull --rebase` avant `push`.
- **Conflit sur un fichier texte** (`.lua`, `.md`, `.py`, `.json`) : le résoudre en gardant les deux
  intentions quand c'est possible, montrer au collaborateur ce qui a été décidé, puis continuer le rebase.
  En cas de doute sur l'intention : demander.
- **Conflit sur un fichier binaire** (`.rbxl`, `.fbx`, `.blend`, `.glb`, images) : Git ne sait pas fusionner.
  **Ne jamais choisir à la place du collaborateur.** Expliquer et demander : garder la sienne
  (`git checkout --theirs`, pendant un rebase = ses changements locaux) ou celle de GitHub
  (`git checkout --ours`, pendant un rebase = version distante). Attention : pendant un rebase, ours/theirs
  sont inversés par rapport à un merge — vérifier avant d'agir.
- Petits commits fréquents > un énorme commit en fin de journée : moins de conflits.
- On travaille directement sur `main` (équipe petite). Une branche seulement si le collaborateur le demande.

### La place `jeu mine .rbxl` : un seul éditeur à la fois

C'est un fichier binaire : deux personnes qui le modifient en même temps = un des deux perd son travail.
- Le **code** vit dans `src/` (synchronisé par Rojo) : là, on peut travailler à plusieurs en même temps.
- Le **décor / modèles importés dans Studio** vivent dans le `.rbxl` : prévenir l'équipe avant de le modifier,
  faire « pull » juste avant, « commit and push » juste après.
- Préférer mettre une logique dans `src/` plutôt que dans la place, quand c'est possible.

---

## 3. Structure du projet

| Chemin | Rôle |
|---|---|
| `src/server` | ServerScriptService › Jeu (logique serveur, sauvegarde, boutique, minage) |
| `src/client` | StarterPlayerScripts › Jeu (HUD, effets, animations client) |
| `src/partage` | ReplicatedStorage › Partage (catalogues, réglages partagés client/serveur) |
| `src/monde` | ServerStorage › Monde (générateur de carte ; coordonnées dans `Disposition.lua`) |
| `default.project.json` | Mapping Rojo (ne pas changer sans raison) |
| `rokit.toml` | Version de Rojo (7.4.4) — installer avec `rokit install` |
| `jeu mine .rbxl` | La place Roblox (binaire) |
| `assets/` | FBX exportés depuis Blender + textures cuites |
| `blender/` | Scripts Python Blender (headless) + leurs sorties (`out_*`, `apercus/`) |
| `previews/` | Aperçus d'armes et de mobs |
| `atelier-bestiaire.html` | Atelier/bestiaire de travail |
| `.claude/agents/` | Sous-agents Claude spécialisés (mine, pioche, forgeron, interface, effets…) |

Workflow Studio : `rojo serve` dans ce dossier, puis Studio › Plugins › Rojo › Connect. Les scripts
de `src/` se synchronisent tout seuls ; **ne pas** éditer ces scripts dans Studio (Rojo écraserait).

---

## 4. Règles de code (Roblox / Luau)

- **Serveur autoritaire** : tout ce qui touche argent, inventaire, achats, dégâts, minage est validé côté
  serveur (distance, montant, ordre d'achat, cooldown). Ne jamais faire confiance au client.
- Sauvegarde : `src/server/Donnees.lua` (DataStore `JeuMine`, verrou de session, autosave 60 s).
  Ne pas casser le format des données sans migration. Ne pas renommer la DataStore.
- `ARGENT_TEST_STUDIO` (dans `Donnees.lua`) ne s'applique qu'en Studio : ne pas l'activer en vrai jeu.
- Équilibrage des pioches : `src/partage/Pioches.lua`. Auras : `src/partage/AurasPioches.lua`.
- **Ne pas modifier à la main** les fichiers générés : `src/partage/PiochesVoxels/` (régénérés par
  `blender/pioches/exporte_blocs.py`).
- **Ne pas renommer** les pièces des modèles 3D (`Gaspard_Tete_Peau`, `PiocheDemon_Tete_FerNoir`…) :
  le code les retrouve par leur nom.
- Les personnages utilisent **AnimationConstraint**, pas Motor6D (poser les bras via ces contraintes).
- Noms de variables, fonctions et fichiers en français, comme le code existant. Suivre le style des fichiers voisins.
- Changements chirurgicaux : ne pas reformater ni « nettoyer » du code sans rapport avec la demande
  (ça crée des conflits pour les autres).
- Pas de `_G` ; utiliser des ModuleScripts.

## 5. Blender

Blender 5.2, toujours en headless :
`"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup --python <script.py>`
Le chemin peut différer chez chaque collaborateur : le vérifier avant de lancer.
Style des modèles : voxel à studs (type LEGO), < 20 000 triangles par pièce.

## 6. Roblox Studio

- Si Studio est déjà ouvert sur la place, **ne pas le fermer ni le relancer** sans demander : tester dans
  la fenêtre ouverte.
- Après un changement, tester en Play et lire la fenêtre Output avant de dire « c'est fini ».

## 7. Comportement de l'agent

- Répondre en français, court et clair : les collaborateurs ne sont pas forcément développeurs.
- Si une demande est ambiguë ou risque de casser le travail d'un autre : demander avant d'agir.
- Mettre à jour `README.md` quand on ajoute ou change un système visible (nouvelle boutique, nouveau PNJ…).
- Ne jamais inclure d'informations personnelles (emails, mots de passe, tokens) dans le code ou les commits.
