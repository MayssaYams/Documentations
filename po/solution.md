# La solution Patisry — vue fonctionnelle (PO/PM)

Ce document explique **ce que fait la plateforme et selon quelles règles métier**. Pour l'implémentation technique, voir [`tech-lead/solution.md`](../tech-lead/solution.md) — ne pas dupliquer ici.

Vérifier avant de s'appuyer sur un détail : les règles ci-dessous sont extraites du code réel, mais le code bouge (voir [`_conventions.md`](../_conventions.md)).

---

## 1. Le produit en une phrase

Une place de marché qui met en relation des **pâtissiers artisans** et des **clients** : le client commande une pâtisserie, le pâtissier la prépare, le client vient la récupérer. Modèle type Uber, mais actuellement **en retrait boutique uniquement** — la livraison est prévue dans le code mais pas active.

---

## 2. Les trois types de comptes

Un compte = une ligne `accounts_user`, avec un `group_id` qui détermine le rôle :

| `group_id` | Rôle | Ce qu'il peut faire |
|---|---|---|
| 1 | Admin | Back-office complet (modération, réglages plateforme, analytics) |
| 2 | Client | Commander, noter, mettre en favori, discuter avec un pâtissier |
| 3 | Pâtissier | Tout ce qu'un client peut faire **+** gérer ses pâtisseries et ses commandes reçues |

**Point important pour les specs** : un pâtissier reste un client. Il peut commander chez un autre pâtissier. Toute règle formulée « le pâtissier ne voit pas X » doit préciser *sur quelle commande* — le rôle se détermine commande par commande, pas globalement. (Un bug réel est venu de là : un compte pâtissier ne voyait jamais le bouton « J'ai récupéré ma commande » sur ses propres achats.)

### Devenir pâtissier / redevenir client

- **Activation** : le compte passe `group_id = 3`, un profil `baker` est créé/réactivé. Le `baker_id` d'origine est conservé si le compte avait déjà été pâtissier.
- **Désactivation** : `group_id = 2`, et **toutes ses pâtisseries sont désactivées automatiquement**.
- **Réactivation** : les pâtisseries **ne sont PAS réactivées automatiquement**. Le pâtissier les réactive une par une depuis « Mes pâtisseries ». C'est une décision produit explicite (éviter de remettre en vente un catalogue obsolète).

---

## 3. Le cycle de vie d'une commande

C'est le cœur métier. Les statuts et qui a le droit de les changer :

```
pending_confirmation → in_preparation → ready → awaiting_pickup → completed
        (pâtissier)      (pâtissier)   (pâtissier)      (CLIENT)
```

| Statut | Sens métier | Qui le déclenche |
|---|---|---|
| `pending_confirmation` | Commande passée, le pâtissier n'a pas encore accepté | automatique au checkout |
| `in_preparation` | Le pâtissier a accepté et prépare | pâtissier |
| `ready` | La pâtisserie est prête | pâtissier |
| `awaiting_pickup` | Le pâtissier a remis la commande physiquement | pâtissier |
| `completed` | Le client confirme avoir récupéré | **client uniquement** |
| `cancelled` | Annulée | les deux, mais **seulement** depuis `pending_confirmation` ou `in_preparation` |

**Règles à connaître pour toute spec touchant les commandes :**
- Le pâtissier **ne peut pas** marquer une commande `completed`. Seul le client ferme la boucle. C'est volontaire (protection contre les faux « livré »).
- Aucun saut d'étape : on avance d'un cran à la fois, jamais en arrière.
- Une fois `ready` dépassé, **plus d'annulation possible** — la pâtisserie est faite.
- `out_for_delivery` et `delivered` existent dans le code mais sont réservés à la future livraison. Ne pas les utiliser dans une spec sans en parler au Tech Lead.

---

## 4. Le checkout, et pourquoi il est particulier

**Un panier peut contenir des produits de plusieurs pâtissiers.** Au moment de valider :

1. Le système crée **N commandes séparées, une par pâtissier** (chacun ne voit que ce qui le concerne).
2. Ces N commandes partagent un même `checkout_reference` pour rester regroupées côté client.
3. Si le client a laissé une **instruction spéciale** sur un produit (« joyeux anniversaire Léa »), une **conversation est ouverte automatiquement** entre le client et ce pâtissier, avec un message contenant la demande.

C'est une mécanique produit forte : la messagerie n'est pas un canal à part, elle démarre toute seule quand il y a un besoin de personnalisation.

---

## 5. Les avis — règles strictes

- Un client ne peut noter **que** ce qu'il a réellement commandé et reçu (l'avis est rattaché à une commande précise).
- **Un avis par commande et par produit** — commander deux fois le même gâteau permet deux avis, un seul par commande.
- Le pâtissier peut **répondre publiquement** à un avis.
- N'importe qui peut **signaler** un avis ; l'admin arbitre (rejeter le signalement ou supprimer l'avis).

### Le seuil d'affichage des notes

La note moyenne d'un pâtissier **reste masquée** tant qu'il n'a pas atteint un nombre minimum de commandes terminées. Le seuil est **réglable depuis le back-office admin** (valeur par défaut : **10**).

Raison produit : une note « 5,0 » basée sur un seul avis n'informe pas, et une mauvaise note isolée peut tuer un nouveau pâtissier. Ce réglage est un levier produit — c'est toi qui décides de sa valeur.

---

## 6. Périmètre actuel

**Actif :** inscription/connexion, catalogue et fiche produit, recherche, favoris (avec groupes), panier multi-pâtissiers, checkout, suivi de commande, messagerie client↔pâtissier, avis et réponses, notifications, espace pâtissier (catalogue + commandes + tableau de bord), back-office admin, newsletter, pages légales (CGV, mentions légales).

**Présent dans le code mais pas actif :** livraison (statuts réservés, frais et rayon de livraison déjà stockés sur le profil pâtissier), abonnements (`subscription-service` avec plans et historique de facturation).

**Modèle économique préparé mais non branché :** chaque pâtissier a un `commission_rate` (défaut **10 %**) sur son profil. La mécanique de prélèvement n'existe pas encore.

**Paiement :** le mode « Espèces » (paiement à la remise) est ce qui fonctionne. Stripe est partiellement intégré. Toute spec impliquant un paiement en ligne doit être validée techniquement avant d'être promise.

---

## 7. Ce qui contraint tes deadlines

- **Trois environnements** : dev (Freebox, maison) → staging (`stg.patisry.fr`) → production. **La production n'existe pas encore** : le domaine `patisry.fr` est un domaine parké. Aucune date de mise en ligne publique ne peut être promise tant que le Tech Lead et le DevOps n'ont pas livré cette infra.
- **Le schéma de base de données est appliqué à la main**, environnement par environnement. Conséquence concrète et déjà vécue : une fonctionnalité peut marcher parfaitement en dev et être totalement cassée en staging. **Toujours faire valider une feature sur staging avant de la considérer livrée**, jamais sur la seule démo en dev.
- Vérifier [`tech-lead/state.md`](../tech-lead/state.md) avant d'annoncer une date.
