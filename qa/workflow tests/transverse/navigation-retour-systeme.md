# Navigation et retour système

| | |
|---|---|
| **Statut** | 🔁 à revoir — PR ouverte non mergée, pas encore testée sur device réel |
| **Écrit avant le développement ?** | non — écrit pendant la revue de la PR, avant test terrain |
| **Portée** | Toute l'app — `PopScope` de `ToolbarWithDrawer`/`AdminScaffold`, tous les `context.go()`/`context.push()` |
| **Tickets Linear liés** | PAT-42 (PR [#35](https://github.com/MayssaYams/Patisry/pull/35), non mergée), PAT-25 (doublon, à fermer une fois validé) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Le comportement du bouton retour (physique Android, geste, flèche in-app) et la cohérence `go()`/`push()` sur l'ensemble du routeur `go_router` de l'app. C'est transverse : chaque autre fiche de ce dossier doit vérifier son propre écran depuis cet angle (« le retour revient bien à l'écran précédent »), mais les règles générales et la liste des écrans corrigés vivent ici pour ne pas être dupliquées partout.

## 2. Préconditions

- **Un appareil Android réel** (pas seulement le web) — c'est la seule cible qui reproduit le bug d'origine (l'app se fermait au bouton retour). Non disponible au moment de la rédaction de cette fiche.
- `client@exemple.com` et `patissier@exemple.com` (baker 5), un compte admin.

## 3. Scénario nominal (happy path)

Voir `docs/navigation.md` du dépôt Patisry (généré par PAT-42) pour le diagramme complet. Points à dérouler sur device réel :

1. **Depuis l'accueil, ouvrir une fiche produit puis appuyer sur retour.** Revient à l'accueil, ne quitte pas l'app.
2. **Depuis une fiche produit, ajouter au panier, aller au paiement, appuyer sur retour.** Revient au panier, pas à l'accueil, pas de sortie d'app.
3. **Depuis le détail d'une commande, ouvrir une conversation, appuyer sur retour.** Revient au détail de commande.
4. **Panel admin : changer de section (ex. utilisateurs → produits), appuyer sur retour.** Revient à la section précédente, pas de sortie d'app (le garde-fou s'applique aussi à `AdminScaffold`).
5. **Depuis l'accueil (racine `/`), appuyer sur retour.** Quitte l'app — c'est le **seul** endroit où c'est attendu.
6. **Tap sur une notification push (app fermée ou en arrière-plan).** Ouvre l'écran cible — **non testé du tout** par la PR, à vérifier en priorité.

## 4. Cas de bord et erreurs attendues

- **Retour depuis n'importe quel écran de la partie connectée (profil, mes pâtisseries, moyens de paiement, adresse pâtissier, pages légales du drawer) hors accueil et hors changements de section.** Ne doit **jamais** fermer l'app.
- **Drawer ouvert + retour.** Ferme le drawer, ne dépile pas l'écran en dessous.
- **Bouton « Commencer » du drawer.** Mène actuellement à `/orders`, route inexistante → « Page introuvable » (PAT-78, non corrigé, ticket séparé — ne pas re-signaler ici, juste vérifier que ça reste cohérent avec ce ticket).
- **Web : retour navigateur depuis `/payment/confirmation`.** Peut ramener à `/payment` avec un panier déjà vidé (PAT-81, non corrigé).
- **Après connexion.** Le retour ramène à l'accueil, pas à l'écran (panier/produit) qui avait déclenché la connexion (PAT-82, non corrigé, amélioration UX volontairement différée).
- **Dialogue de consentement analytics, lien politique de confidentialité.** Comportement suspect non observé (PAT-79) — à vérifier en priorité si ce dialogue est testé.

## 5. Règles métier à vérifier

Aucune règle métier produit spécifique — fiche purement technique/UX. Le seul principe à respecter : `go()` réservé aux changements de section, à l'après-authentification, aux fins de parcours et aux entrées profondes (deep link) ; `push()`/`pop()` partout où l'utilisateur s'attend à revenir en arrière.

## 6. Non-régressions connues

- **PAT-42 (2026-09-21)** : le bouton retour fermait l'app depuis la quasi-totalité des écrans (routeur plat, chaque `go()` laissait une pile d'une seule page). Corrigé par un garde-fou dans `PopScope` + audit `go`→`push` sur 31 fichiers. **Pas encore vérifié sur device réel au moment de la rédaction.**
- **PAT-25** : symptôme partiel déjà tracké (retour depuis les pages profil vers l'accueil au lieu de la page précédente) — sous-cas de PAT-42, à fermer en doublon une fois PAT-42 validé sur device.

## 7. Comment vérifier

- `flutter analyze` (0 erreur) et `flutter test` sur la branche `alvinnzembani/pat-42-navigation-flutter-incoherente-contextgo-vs-contextpush-lapp` — 182 tests passent, 4 échouent (préexistants sur `develop`, sans lien avec PAT-42).
- **Test manuel obligatoire sur appareil Android réel** avant de merger — c'est la seule vérification qui compte vraiment pour ce bug, les tests widget ne simulent le comportement du bouton retour qu'à travers un faux canal `SystemNavigator.pop`.
- `flutter build web --no-tree-shake-icons` pour le comportement web (URL, retour navigateur).

## 8. Definition of done

- [ ] Testé sur au moins un appareil Android réel, tous les points de la section 3
- [ ] Aucun écran de la partie connectée ne ferme l'app au retour, hors accueil
- [ ] Panel admin couvert par le même garde-fou
- [ ] Tap sur notification push testé
- [ ] `flutter analyze`/`flutter test`/`flutter build web` verts
- [ ] PAT-25 fermé comme doublon une fois ce document entièrement coché
