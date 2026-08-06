# La solution Patisry — vue commerciale & marketing (Directeur Commercial)

Ce document explique **Patisry comme produit à vendre et à faire grandir**, pas comme code. Pour le fonctionnel détaillé, voir [`po/solution.md`](../po/solution.md) — ne pas dupliquer ici.

Vérifier avant de s'appuyer sur un détail (voir [`_conventions.md`](../_conventions.md)) — et en particulier, sur ce document plus que sur les autres : **beaucoup de points ci-dessous sont encore ouverts**, pas des faits établis. Le rôle de ce poste est justement de les faire trancher.

---

## 1. Ce qu'on vend, en une phrase

Un marketplace qui met en relation des **pâtissiers artisans** et des **clients** pour du **retrait en boutique** — pas encore de livraison active. C'est un point de positionnement important : ne pas communiquer comme un service de livraison tant que ce n'est pas vrai.

## 2. Le double funnel

Deux publics à faire venir, avec des leviers différents :

**Côté pâtissiers** (l'offre) :
- Ce qui les attire : visibilité, nouveaux clients, pas de frais d'installation d'une boutique en ligne.
- Ce qui les retient : commandes réellement converties, outils de gestion simples (tableau de bord, gestion des commandes déjà en place côté produit).
- **Sans pâtissiers actifs sur une zone, aucune campagne côté client sur cette zone n'a de sens.** Toujours vérifier la densité de l'offre avant d'investir en acquisition client localement.

**Côté clients** (la demande) :
- Ce qui les attire : découverte de pâtisseries artisanales, proximité.
- Ce qui les retient : qualité perçue (photos, avis), fiabilité (délais tenus, disponibilité réelle des créneaux).
- Le calendrier de commande grise déjà les dates sans créneau disponible plutôt que de laisser un client tomber sur une impasse — un exemple de détail produit qui a un impact direct sur la confiance et la conversion.

## 3. Les avis — un levier de confiance, pas un détail

Système déjà en place : un avis n'est possible qu'après une commande réellement reçue, le pâtissier peut y répondre publiquement. Deux points à connaître avant toute communication dessus :

- **La note d'un pâtissier reste masquée** tant qu'il n'a pas atteint un seuil de commandes terminées (réglable en admin, défaut 10). Un nouveau pâtissier n'affiche donc pas de note — à expliquer dans l'onboarding pâtissier pour ne pas donner l'impression d'un bug ou d'un défaut de crédibilité.
- Le seuil est un vrai levier produit/marketing : trop bas, une mauvaise note isolée peut tuer un nouveau pâtissier ; trop haut, aucun nouveau pâtissier n'affiche jamais de note. À discuter avec le PO si la valeur actuelle freine l'acquisition côté offre.

## 4. Ce qui N'EST PAS encore vrai — à ne jamais promettre par erreur

- **Pas de livraison.** Retrait boutique uniquement, malgré des champs déjà présents en base (rayon de livraison, frais de livraison) qui laissent penser le contraire si on regarde vite.
- **Pas de vraie production.** L'app tourne en dev et sur un environnement de test (staging). Aucune date de disponibilité publique ne doit être annoncée sans validation du Tech Lead/DevOps.
- **Pas de modèle de rémunération actif.** Le taux de commission existe en base mais n'est prélevé nulle part — voir [`role.md`](role.md).
- **Paiement en ligne partiel.** Le mode réellement fonctionnel est **« Espèces » à la remise**. L'intégration carte (Stripe) est commencée côté app mais pas finalisée bout en bout. Ne pas construire de communication autour du paiement en ligne sans vérifier son état auprès du Tech Lead au moment voulu.
- **Pas de société créée.** Les mentions légales de l'app sont encore des champs à compléter (raison sociale, SIRET). Toute démarche commerciale impliquant une facturation réelle ou un contrat dépend de [`juriste/role.md`](../juriste/role.md).

## 5. Angles de différenciation déjà présents dans le produit

- **Un marketplace, pas une simple vitrine** : commande et paiement intégrés (pas un simple annuaire renvoyant vers WhatsApp ou Instagram).
- **Panier multi-pâtissiers** : un client peut commander chez plusieurs artisans en une seule session, chacun recevant sa propre commande.
- **Personnalisation traçée** : une instruction spéciale sur une commande (« joyeux anniversaire Léa ») ouvre automatiquement une conversation avec le pâtissier — le service client/personnalisation est intégré au flux, pas un canal externe.

## 6. Zone géographique et lancement

Aucune stratégie de zone n'est encore tranchée dans ce document. Points à établir avec le CTO avant toute action :
- Zone de lancement (probablement liée à où se trouvent déjà des pâtissiers pilotes).
- Densité minimale de pâtissiers avant d'ouvrir l'acquisition client sur une zone.
- Séquencement : recruter l'offre avant la demande semble le sens logique pour un marketplace naissant, mais c'est une hypothèse à valider, pas un fait acquis.
