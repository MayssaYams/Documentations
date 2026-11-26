# Moyens de paiement enregistrés

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `payment_methods_screen.dart` (`/account/payment-methods`), `add_card_screen.dart`, `edit_card_screen.dart`, `apple_pay_screen.dart`, `google_pay_screen.dart`, `paypal_screen.dart` |
| **Endpoints concernés** | payment-service |
| **Tickets Linear liés** | PAT-55 (Stripe Connect, dépendance future) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Gestion des moyens de paiement **enregistrés** sur le compte (ajout, édition, suppression) — pas le paiement réel d'une commande, qui à date ne passe pas par ces moyens enregistrés (voir la note importante dans [`panier-et-validation-commande.md`](panier-et-validation-commande.md) §1 : le checkout appelle directement `POST /api/cart/checkout/`, sans SDK Stripe). Ce fichier couvre donc un CRUD qui, à date, **n'est pas encore branché sur le paiement réel d'une commande** — c'est un écart produit connu (cf. PAT-55, Stripe Connect toujours en Backlog), pas un bug de ce CRUD lui-même.

## 2. Préconditions

- `client@exemple.com` connecté, sans moyen de paiement enregistré au départ (pour tester l'état vide).
- **Ne jamais utiliser de vraie carte bancaire.** Utiliser exclusivement les valeurs de test Stripe documentées (cartes `4242 4242 4242 4242` etc.) si l'intégration Stripe est active sur cet écran ; sinon rester sur les champs de formulaire seuls.

## 3. Scénario nominal (happy path)

1. **Liste vide.** `payment_methods_screen` affiche un état vide clair, pas une liste cassée.
2. **Ajouter une carte.** `add_card_screen` → `push()` → retour à la liste, qui affiche la nouvelle carte.
3. **Éditer une carte existante.** `edit_card_screen` → modification reflétée dans la liste au retour.
4. **Supprimer une carte.** Disparaît de la liste, confirmation demandée avant suppression (action irréversible).
5. **Apple Pay / Google Pay / PayPal.** Les écrans de sélection s'ouvrent et se ferment proprement — **ne pas exiger d'aller jusqu'au wallet réel** (hors périmètre MVP, cf. doc `18_TestSprite_Frontend_MVP_Parcours.md` §2).

## 4. Cas de bord et erreurs attendues

- **Carte invalide (format, expirée).** Message d'erreur clair, pas de crash, pas de carte enregistrée en base.
- **Suppression du dernier moyen de paiement.** Ne doit pas bloquer l'app ni empêcher de commander (le checkout actuel ne dépend pas de cette liste, cf. §1 — vérifier que ça reste vrai).
- **Retour système depuis n'importe lequel de ces écrans.** Doit revenir à `payment_methods_screen`, pas fermer l'app (cf. [`../transverse/navigation-retour-systeme.md`](../transverse/navigation-retour-systeme.md) — ces écrans utilisaient `Navigator.pop` avant PAT-42, remplacé par `goBackOrHome`).

## 5. Règles métier à vérifier

- Aucune donnée de carte réelle ne doit transiter par les logs ou être visible dans les outils de debug — vérifier qu'aucun numéro de carte n'apparaît en clair dans `read_network_requests`/logs lors d'un ajout de carte de test.

## 6. Non-régressions connues

- **PAT-42 (2026-09-21)** : `Navigator.pop` sur `add_card_screen`/`edit_card_screen`/`apple_pay_screen`/`google_pay_screen`/`paypal_screen` a été remplacé par `goBackOrHome` (un lien direct ou un refresh web sur ces écrans ne pouvait pas dépiler correctement avant). À retester après merge.

## 7. Comment vérifier

- Backend : `payment-service` (`manage.py test`).
- Frontend : `flutter analyze` + test manuel staging, **exclusivement avec des cartes de test**.
- `read_network_requests` pour vérifier qu'aucune donnée de carte ne fuite en clair côté logs applicatifs.

## 8. Definition of done

- [ ] CRUD complet (ajout, édition, suppression) fonctionnel, état vide géré
- [ ] Carte invalide refusée proprement
- [ ] Retour système revient à la liste depuis chaque sous-écran
- [ ] Aucune donnée de carte en clair dans les logs
- [ ] Tests `payment-service` verts
