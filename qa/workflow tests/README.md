# Workflow tests — un but à atteindre par fonctionnalité

Ce dossier contient, **pour chaque fonctionnalité et chaque écran existant de Patisry**, un document autonome qui décrit exactement comment vérifier que ça marche : scénario nominal, cas de bord, règles métier à respecter, non-régressions connues, commandes de vérification, et une checklist finale (« definition of done »).

Un humain (Alvin ou un testeur) ou une IA QA doit pouvoir dérouler un de ces fichiers sans autre contexte que le fichier lui-même (+ [`role.md`](../role.md) pour les commandes génériques) et juger, sans deviner, si la fonctionnalité fonctionne.

## Règle : le workflow test s'écrit AVANT le développement

**Pour toute nouvelle page ou fonctionnalité, ce document se rédige en premier, avant que le code soit écrit — pas après.** Il devient l'objectif à atteindre pour dire la tâche terminée, pas un compte-rendu de ce qui a été fait.

Concrètement, dans le découpage du Tech Lead (`Documentations/tech-lead/role.md`) :

1. Le PO valide la fonctionnalité fonctionnellement.
2. **Avant** de lancer Full-stack dessus, le Tech Lead écrit (ou fait écrire par QA) le fichier `workflow tests/<domaine>/<nom>.md` correspondant, à partir du [`_template.md`](_template.md). Statut `🔲 à rédiger` → `✅ rédigé`, case « écrit avant le développement ? » = **oui**.
3. Full-stack développe en connaissant ce document — c'est la cible.
4. QA valide en déroulant exactement ce fichier, coche la section 8, met à jour le statut si le comportement réel diffère de ce qui avait été anticipé (le fichier doit refléter le comportement réel une fois la fonctionnalité livrée, pas rester un vœu pieux).

Si une fonctionnalité a dû être développée sans que ce document existe au préalable (urgence, correctif), le rédiger **immédiatement après coup**, marquer honnêtement « écrit avant le développement ? = non », et le traiter comme une dette à rattraper — ne jamais laisser un écran sans son fichier.

## Organisation

Un fichier par fonctionnalité utilisateur (pas forcément un fichier par écran Flutter : un parcours qui traverse plusieurs écrans, comme panier → paiement → confirmation, est **un seul** document), rangé par domaine :

```
workflow tests/
├── compte/                    # inscription, connexion, profil, RGPD, pages légales
├── catalogue/                 # accueil, recherche, fiche produit/pâtissier, favoris, notifications
├── commande-et-paiement/      # panier, paiement, cycle de vie commande, messages, avis
├── patissier/                 # adresse/position, bascule pâtissier ↔ client
├── transverse/                # navigation, mémorisation de la localisation — traverse tout le reste
└── admin/                     # panel admin (7 fichiers regroupant les 14 écrans admin_*)
```

Voir [`_index.md`](_index.md) pour la liste exhaustive avec statut de chacun.

## Convention de contenu

Voir [`_template.md`](_template.md) — huit sections fixes : périmètre, préconditions, scénario nominal, cas de bord, règles métier, non-régressions connues, comment vérifier, definition of done.

Points importants :
- **Comptes de test uniquement** (`patissier@exemple.com` / baker 5, `client@exemple.com`) — jamais la vraie boutique Berile (baker_id=1). Voir mémoire projet `patisry-staging-test-accounts`.
- **Staging est la cible de validation**, pas dev/Freebox (abandonnée) — CLAUDE.md, règle non négociable.
- **Ne pas dupliquer** les règles métier déjà écrites dans `CLAUDE.md` ou `Documentations/qa/solution.md` : y renvoyer par un lien, ne recopier que ce qui est strictement nécessaire à la lecture du scénario.
- **Non-régressions connues** = vrais bugs déjà rencontrés (voir `solution.md` §2-4 pour un premier stock), pas des cas hypothétiques.
- Un document qui ne correspond plus au comportement réel de l'app (écran modifié depuis) est pire qu'inutile — **statut `🔁 à revoir`** dès qu'un doute apparaît, mis à jour dans la foulée par qui le remarque, pas laissé pour plus tard.

## Ce qui existait déjà et ne doit pas être dupliqué

- [`Documentations/Doc fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md`](../../Doc%20fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md) — dix scénarios E2E du MVP initial (inscription → paiement, sans Stripe). Contenu partiellement obsolète (routes `go_router` changées depuis PAT-42) et **très en-deçà du périmètre voulu ici** (ne couvre ni l'admin, ni les commandes après paiement, ni la localisation, ni les pâtissiers). Les fichiers de ce dossier priment sur ce document dès qu'ils existent ; ce dernier reste une référence historique tant que la couverture n'est pas complète, à corriger ou retirer une fois que le couvre ici.
- [`Documentations/qa/solution.md`](../solution.md) — les zones à risque déjà identifiées (§3-4) sont le point de départ de nombreux fichiers de ce dossier ; renvoyer dessus plutôt que recopier.
