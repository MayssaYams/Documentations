# La solution Patisry — architecture (Tech Lead)

Ce document explique **comment le système est construit et pourquoi**, au niveau où l'on découpe des tâches et où l'on tranche des choix transverses. L'implémentation ligne à ligne est dans [`full-stack/solution.md`](../full-stack/solution.md), l'infra dans [`devops/solution.md`](../devops/solution.md).

Vérifier avant de s'appuyer sur un pointeur (voir [`_conventions.md`](../_conventions.md)).

---

## 1. Topologie

**Un frontend Flutter** (`Patisry/`) → **15 microservices Django REST** → **une seule base PostgreSQL partagée** (+ PostGIS).

Le point structurant, et la source de la plupart des pièges : **les services sont séparés mais la base ne l'est pas**. Il n'y a pas de base par service. Chaque service est propriétaire *par convention* de certaines tables, pas par isolation technique.

| Service | Port | Domaine fonctionnel |
|---|---|---|
| auth | 8000 | inscription, login, JWT, reset mot de passe |
| user | 8002 | profil, adresse |
| display | 8003 | agrégation lecture (accueil, fiche produit) |
| message | 8004 | conversations, messages |
| notification | 8005 | notifications, tokens d'appareil |
| product | 8006 | catalogue, images, tailles, allergènes |
| order | 8007 | panier, checkout, commandes |
| analytics | 8008 | suivi et statistiques |
| favorite | 8009 | favoris et groupes |
| baker | 8010 | profils pâtissiers |
| search | 8011 | recherche |
| payment | 8012 | paiements, promotions, webhooks |
| subscription | 8013 | abonnements, newsletter, facturation |
| admin | 8014 | back-office, modération, réglages |
| review | 8015 | avis, réponses, signalements |

---

## 2. Les décisions d'architecture à connaître avant de découper quoi que ce soit

### Aucun appel REST entre services

La communication inter-services se fait **en SQL brut sur la base partagée**, via `connection.cursor()`. Pas d'appels HTTP entre backends.

Conséquence pour le découpage : une tâche « le service A doit réagir à un événement du service B » ne se traduit pas par un endpoint, mais par une écriture directe. C'est assumé, mais ça veut dire qu'**un changement de schéma peut casser un service qui n'est pas celui qu'on modifie**. Toujours se demander qui d'autre lit ou écrit la table qu'on touche.

Exception documentée et volontaire : **order-service écrit dans les tables de message-service** au moment du checkout (création de la conversation et du message `order_request`). C'est par conception.

### `display-service` est un service de lecture, pas un CRUD

Il agrège en une requête ce que la fiche produit ou l'accueil ont besoin d'afficher (produit + pâtissier + images + catégories + avis + favoris + distance). C'est pour ça que ses requêtes SQL sont longues.

Piège structurel déjà rencontré : **une même règle métier doit être appliquée à plusieurs endroits dans ces requêtes**. Un produit désactivé était bien filtré dans la liste principale mais pas dans la section « favoris » du même payload. Quand une règle de visibilité change, chercher **toutes** ses occurrences dans `display/views.py`.

### Le schéma DB n'est jamais géré par Django

**Règle absolue, non négociable** : pas de `makemigrations`, pas de `migrate`, pas de `CREATE TABLE`/`ALTER TABLE` depuis le code applicatif. Les dossiers `migrations/` restent vides (juste `__init__.py`). Les modèles sont en `managed = False`.

Le schéma vit dans `Documentations/database/*.sql`, appliqué **à la main**.

Si une table manque, le service doit **lever une erreur claire**, jamais tenter de la créer.

**C'est le risque numéro un du projet.** Voir §5.

---

## 3. Le flux de commande

### Machine à états

Définie dans `order-service/orders/views.py` (`STATUS_CHAIN`, `BAKER_ALLOWED_TARGETS`, `CLIENT_ALLOWED_TARGETS`, `CANCELLABLE_FROM`) et **doublée par une contrainte `CHECK` en base** (`chk_order_status_valid`).

```
pending_confirmation → in_preparation → ready → awaiting_pickup → completed
```

- Le pâtissier avance jusqu'à `awaiting_pickup`, **jamais** jusqu'à `completed`.
- Seul le client pose `completed`, et seulement depuis `awaiting_pickup`.
- Aucun saut d'index, aucun retour en arrière.
- `cancelled` seulement depuis `pending_confirmation` ou `in_preparation`.
- `out_for_delivery` / `delivered` : réservés à la livraison future, inactifs.

**Attention au découpage** : cette machine existe en deux endroits (code Python + contrainte SQL). Toute évolution des statuts est une tâche **à deux volets**, sinon la contrainte rejette ce que le code autorise. C'est exactement le scénario qui a cassé le checkout en staging.

### Checkout multi-pâtissiers

Un panier → **N commandes, une par pâtissier**, regroupées par un `checkout_reference` (UUID). Si un article porte des `special_instructions`, order-service crée (ou retrouve) une conversation directe client↔pâtissier et y insère un message `order_request`.

Contraintes à respecter dans toute tâche qui touche ce flux :
- `delivery_status` doit **toujours** être présent dans un `INSERT` sur `messages`, avec `'sent'` par défaut.
- `message_type` doit faire partie des valeurs autorisées par `chk_message_type_valid` (`order_request` et `order_reply` en font partie — leur absence en staging a cassé le checkout).

---

## 4. Les pièges de modèle de données

### Double lien produit ↔ pâtissier

Un produit peut être rattaché à un pâtissier de **deux façons** :
1. `product.baker_id` — FK directe, **souvent NULL**
2. `product_user (product_id, user_id)` — la relation que product-service utilise pour lister « Mes pâtisseries »

**Règle** : `baker_id` est **toujours prioritaire** quand il est renseigné ; ne retomber sur `product_user` que si `baker_id IS NULL`. C'est la logique `COALESCE(b.id, baker_from_user.id)` de display-service.

Pourquoi c'est critique : `product_user` peut contenir des lignes **périmées**. Un correctif qui traitait les deux liens à égalité a désactivé le produit d'un pâtissier actif par erreur.

### `baker.userid` vs `baker.user_id`

Le nom de la colonne FK vers `accounts_user` **varie selon l'environnement**. Toujours passer par un helper de détection (`baker_user_fk_column()` dans order-service), jamais l'écrire en dur.

### `product.baker_id` vs `product.bakerid`

Même problème sur la table `product` (`_product_baker_column_name()` dans order-service).

Ces deux points sont le symptôme d'un schéma construit à la main sans source unique de vérité.

---

## 5. Le risque structurel : la dérive de schéma

Le schéma est appliqué manuellement, **sans aucun registre de ce qui a été joué où**. Il n'existe pas de table de migrations.

Ce n'est pas théorique. Le 2026-07-27, staging avait **plusieurs migrations de retard** et le checkout était totalement cassé. Les écarts ont été découverts **un par un, à chaque test**, chacun révélant le suivant :
1. colonne `orders.checkout_reference` absente
2. `chk_order_status_valid` périmée (refusait `pending_confirmation`)
3. `chk_message_type_valid` périmée (aurait refusé `order_request`)
4. `review_reports`, `platform_settings`, `product_reviews.baker_reply` absents — soit exactement les fonctionnalités déployées le jour même
5. `billing_history` que **aucun script ne créait** (dérive non documentée côté dev)

Détail complet dans [`devops/state.md`](../devops/state.md).

**Conséquences pour le pilotage technique :**
- « Ça marche en dev » ne prouve rien. Une feature n'est livrée que validée sur staging.
- Toute tâche impliquant une nouvelle colonne, table ou contrainte doit inclure explicitement **« appliquer le SQL sur chaque environnement »** comme sous-tâche, sinon elle sera oubliée.
- Le même scénario se reproduira **en production** si rien ne change. Un mécanisme minimal (table `schema_migrations` listant les scripts appliqués) est la contre-mesure évidente ; à arbitrer avec le CTO.

---

## 6. Frontend — ce qui a valeur d'architecture

- **State** : Provider. `AuthService` (singleton `ChangeNotifier`) porte la session et le type de compte.
- **Réseau** : Dio singleton + `AuthInterceptor` qui rafraîchit le JWT automatiquement (access 12 h / refresh 7 j).
- **Navigation** : go_router, **`context.go()` partout, jamais `context.push()`** — `push()` ne met pas à jour l'URL du navigateur sur web avec la version utilisée ici. Une route paramétrée a besoin d'un `key: ValueKey(...)` explicite dans `app.dart`, sinon go_router réutilise le même State entre deux navigations vers la même route (bug « l'URL change mais la page ne change pas »).
- **Rôle par entité, pas par compte** : un compte pâtissier reste client sur ses propres achats. Toute logique d'affichage conditionnelle doit comparer les identifiants de l'entité concernée (`detail.bakerUserId` vs utilisateur courant), pas `AuthService.userType`.

---

## 7. Environnements

| Env | Où | Déploiement |
|---|---|---|
| dev | Freebox `91.171.4.184` | manuel (`deploy_freebox.sh`) |
| staging | Scaleway `51.15.236.77` → `stg.patisry.fr` | CI au push sur `staging` |
| production | **n'existe pas** | — |

`patisry.fr` était un **domaine parké** au 2026-07-27 mais son DNS pointe désormais (constaté le 2026-08-05) vers la VM staging — voir `devops/solution.md` pour le détail et le bug CORS que ça a révélé. Toujours pas une vraie production. Chaque service backend a **son propre dépôt Git**.
