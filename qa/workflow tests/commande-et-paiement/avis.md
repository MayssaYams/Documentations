# Avis produit

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `reviews_screen.dart` (`/reviews`), `write_review_screen.dart` (`/write-review`) |
| **Endpoints concernés** | review-service |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Écriture, affichage et modération d'un avis produit, et la note agrégée d'un pâtissier. Ne couvre pas l'écran admin de modération des signalements (→ [`../admin/moderation-avis.md`](../admin/moderation-avis.md)).

## 2. Préconditions

- Une commande de test **réellement passée et reçue** (`completed`) entre `client@exemple.com` et `patissier@exemple.com` (baker 5), sur un produit précis.
- Pour le seuil de note masquée : un pâtissier de test avec moins de 10 commandes terminées, et un autre (ou le même, complété) avec 10+.

## 3. Scénario nominal (happy path)

1. **Écrire un avis depuis une commande `completed`.** `push()` vers `/write-review` — retour revient au détail de commande.
2. **Soumission.** Avis créé, visible sur `/reviews` pour ce produit.
3. **Réponse du pâtissier.** Le pâtissier peut répondre à l'avis depuis son côté.
4. **Note agrégée du pâtissier.** Recalculée et affichée sur sa fiche publique (→ [`../catalogue/fiche-patissier-publique.md`](../catalogue/fiche-patissier-publique.md)).

## 4. Cas de bord et erreurs attendues

- **Avis sans commande réellement reçue.** Refusé — un avis exige une commande passée et reçue.
- **Deuxième avis sur la même commande + même produit.** Refusé — un seul avis par commande **et** par produit.
- **Deux commandes du même produit.** Doit permettre **deux** avis distincts (un par commande) — ne pas confondre avec la règle ci-dessus.
- **Note masquée sous le seuil.** La note d'un pâtissier avec moins de commandes terminées que le seuil configuré (réglable dans l'admin, défaut 10) reste **cachée** sur sa fiche publique. Tester explicitement sous **et** au-dessus du seuil — un test qui ne couvre qu'un côté ne prouve rien.
- **Signalement d'un avis.** Doit remonter dans la file de modération admin (→ [`../admin/moderation-avis.md`](../admin/moderation-avis.md)), pas seulement changer un état invisible côté client.

## 5. Règles métier à vérifier

- L'adresse exacte du pâtissier n'apparaît jamais dans un avis ou une réponse publique — seule la ville/distance est publique (règle CLAUDE.md générale, à vérifier ici aussi car un avis est un contenu utilisateur libre qui pourrait la divulguer par erreur d'affichage, pas de saisie).

## 6. Non-régressions connues

_Aucune connue à ce jour — première rédaction de cette fiche. Ajouter ici tout bug réel rencontré lors d'une future campagne._

## 7. Comment vérifier

- Backend : `review-service` (`manage.py test`).
- Vérifier le seuil de note masquée directement en base/admin (`admin_settings_screen` ou table de config) plutôt que de deviner sa valeur courante.
- Frontend : `flutter analyze` + test manuel staging avec les deux comptes de test.

## 8. Definition of done

- [ ] Avis créé uniquement depuis une commande `completed` réelle
- [ ] Un avis par commande × produit, jamais plus
- [ ] Deux commandes du même produit permettent deux avis
- [ ] Note masquée testée sous **et** au-dessus du seuil
- [ ] Réponse du pâtissier fonctionnelle
- [ ] Signalement remonte bien en modération admin
- [ ] Tests `review-service` verts
