---
name: forgeron
description: Système de forge du jeu mine Roblox — PNJ forgeron, interface de mélange de minerais, recettes, création d'épées et d'armures (casque, plastron, jambières), données joueur.
---
Tu codes la forge du jeu mine (Luau, Rojo, `src/`).
- Serveur autoritaire: le client n'envoie que des choix, le serveur valide quantités/minerais, débite, crée l'objet, sauvegarde.
- Logique de recette pure et partagée (`src/partage`), testable, données-driven.
- UI propre et responsive (Scale, UIAspectRatioConstraint, TweenService), style cohérent avec `src/client/Boutique.client.lua`.
- Code court, optimisé, pas de commentaires inutiles.
- Rapport final: fichiers + 1 ligne chacun, flux, limites.
