# La solution Patisry — surface de test (QA)

Ce document explique **ce qu'il y a à tester, où ça casse en vrai, et comment le vérifier**. Les commandes de base sont dans [`role.md`](role.md).

Vérifier avant de s'appuyer sur un détail (voir [`_conventions.md`](../_conventions.md)).

---

## 1. La règle de base

CLAUDE.md l'impose : **100 % des tests passent, sans jamais réduire la couverture existante**. Toute nouvelle fonctionnalité arrive avec ses tests. Si un test échoue, il faut établir s'il s'agit d'une régression ou d'un échec pré-existant — et le prouver, pas le supposer (méthode au §6).

---

## 2. Le piège numéro un : ça marche en dev, c'est cassé en staging

**Le schéma de base est appliqué à la main, environnement par environnement, sans registre.** Un code identique peut donc parfaitement fonctionner en dev et échouer totalement en staging.

Ce n'est pas hypothétique. Le 2026-07-27, le checkout en staging était cassé, et les causes se sont révélées **une par une**, chaque correctif dévoilant la suivante : colonne manquante → contrainte de statut périmée → contrainte de type de message périmée → tables et colonnes d'avis absentes.

**Conséquences directes pour la QA :**
- **Une fonctionnalité validée en dev n'est pas validée.** La recette se fait sur staging.
- Devant une erreur 500 sur staging qui n'existe pas en dev, **le premier réflexe est de comparer la structure de la table concernée entre les deux bases**, pas de chercher dans le code.
- Après toute livraison qui ajoute une colonne, une table ou une contrainte, **vérifier explicitement qu'elle existe bien en staging**.

Les erreurs Postgres remontent **jusque dans l'interface** (bandeau rouge avec le message SQL brut). C'est laid, mais très exploitable : le message nomme la table, la colonne ou la contrainte fautive.

---

## 3. Le flux critique : la commande

C'est le parcours qui rapporte de l'argent et celui qui a le plus cassé. La machine à états est doublée d'une contrainte en base — **tester les transitions interdites autant que les autorisées**.

```
pending_confirmation → in_preparation → ready → awaiting_pickup → completed
```

**Doit passer :**
- Pâtissier : `pending_confirmation` → `in_preparation` → `ready` → `awaiting_pickup`
- Client : `awaiting_pickup` → `completed`
- Annulation depuis `pending_confirmation` ou `in_preparation`, par les deux parties

**Doit être refusé :**
- Pâtissier qui pose `completed` (interdit : seul le client clôt)
- Client qui pose autre chose que `completed`
- Client qui pose `completed` depuis un statut autre que `awaiting_pickup`
- Tout saut d'étape (`pending_confirmation` → `ready`) et tout retour en arrière
- Annulation depuis `ready` ou après

### Les cas de bord qui ont réellement cassé

**Compte double rôle.** Un compte pâtissier qui commande chez un autre pâtissier doit voir la **vue client** sur cette commande — dont le bouton « J'ai récupéré ma commande ». Un bug l'avait fait disparaître parce que le code testait le type de compte global au lieu du rôle sur cette commande précise. **À retester à chaque évolution de l'écran de commande.**

**Panier multi-pâtissiers.** Un panier contenant des produits de 2 pâtissiers doit produire **2 commandes distinctes**, regroupées par un même `checkout_reference`. Tester avec 1 et avec 2+ pâtissiers.

**Instructions spéciales.** Un article avec instruction spéciale doit créer **automatiquement** une conversation client↔pâtissier contenant un message de type `order_request`. Longtemps cassé silencieusement : la contrainte en base refusait ce type de message et l'erreur était avalée sans bruit. **Vérifier que le message arrive vraiment**, pas seulement que la commande est créée.

---

## 4. Les autres zones à risque

**Avis** — un avis exige une commande réellement passée et reçue ; un seul avis par commande **et** par produit (deux commandes du même produit → deux avis possibles). Le pâtissier peut répondre. Le signalement doit remonter en modération admin.

**Note masquée** — la note d'un pâtissier reste cachée sous un seuil de commandes terminées (réglable dans l'admin, défaut 10). Tester sous et au-dessus du seuil.

**Bascule pâtissier → client** — la désactivation du compte pâtissier doit désactiver **toutes** ses pâtisseries, y compris celles dont le lien passe par `product_user` et non par `baker_id`. **Et surtout : elle ne doit toucher aucun produit d'un autre pâtissier** — un correctif trop large a réellement désactivé le produit d'un pâtissier actif. La réactivation du compte ne doit **pas** réactiver les pâtisseries (manuel, une par une).

**Produit désactivé** — ne doit plus apparaître : ni sur l'accueil, ni **dans la section favoris de l'accueil** (oubli réel), ni en recherche.

**Profil** — enregistrer avec un téléphone vide doit fonctionner (le champ part en `null`, pas en `''`). Ne doit **jamais** déconnecter l'utilisateur : un bug transformait toute erreur métier en 401 et forçait la déconnexion. Un « Session expirée » sur une action banale est le symptôme à traquer.

**Navigation web** — cliquer un produit suggéré doit changer l'URL **et** le contenu (bug déjà vu : URL modifiée, page figée). Le bouton retour revient à l'écran précédent, jamais systématiquement à l'accueil, et ne doit pas boucler entre deux écrans.

**Calendrier fiche produit** — une date dont tous les créneaux sont indisponibles doit être **grisée**, pas cliquable dans le vide.

---

## 5. Lancer les tests

**Backend** (tunnel SSH vers la base dev obligatoire) :
```bash
ssh -p 31456 -L 5433:127.0.0.1:5432 alvin@91.171.4.184 -N -f
cd Backend/<service> && source venv/bin/activate    # parfois .venv/
JWT_SECRET_KEY='<valeur dev>' DB_HOST=127.0.0.1 DB_PORT=5433 python manage.py test --keepdb
```
**Exception `user-service`** : force SQLite dès que `'test' in sys.argv`, le tunnel lui est inutile.

Certains services ont un `integration_tests.py` autonome (HTTP réel + base). Les variables attendues sont en tête de fichier ; elles pointent par défaut sur la Freebox.

**Frontend** :
```bash
cd Patisry && flutter analyze && flutter build web --no-tree-shake-icons
```
`flutter analyze` sort ~300 avertissements *info* pré-existants. Le critère est **zéro `error`** : `flutter analyze | grep -c "^   error"`.

**Après un rebuild web, forcer un rechargement dur du navigateur avant de retester.** Du JS en cache a déjà fait conclure à tort qu'un correctif ne marchait pas.

---

## 6. Distinguer une régression d'un échec pré-existant

Ne jamais deviner — le prouver :
```bash
git stash          # met de côté les modifications
<relancer le test>  # échoue-t-il déjà sans elles ?
git stash pop
```
Si le test échoue aussi **sans** les modifications, ce n'est pas une régression. Le noter dans [`state.md`](state.md) pour ne pas le rediagnostiquer à chaque campagne.

### Échecs pré-existants connus

- **display-service** : `test_authenticated_no_coords` et `test_authenticated_with_coords_returns_distance` renvoient 500 au lieu de 200. Confirmés indépendants des livraisons du 2026-07-27 (vérifié par `git stash`). Cause non investiguée.
- **admin-service / order-service** : des avertissements `[audit_log] Échec écriture audit ... violates foreign key constraint` s'affichent pendant les tests — bruit connu, la suite passe malgré tout.
- Bruit `CacheKeyWarning` sur les objets mockés : sans conséquence.

### Un test qui passe n'est pas toujours un bon test

Cas réel : un test d'« absence de modification » s'appuyait sur un `updated_at` inchangé — sauf qu'un **trigger Postgres** (`trigger_product_updated_at`) réécrit ce champ à chaque `UPDATE`. Le test ne prouvait pas ce qu'il prétendait. Se méfier des assertions indirectes quand des triggers existent en base.

---

## 7. Vérifier qu'une livraison est bien déployée

Un run CI vert prouve qu'un déploiement a eu lieu, **pas** que le bon code tourne. Contrôler dans le conteneur :
```bash
ssh -i ~/.ssh/patisry-staging-deploy deploy@51.15.236.77 \
  "docker exec patisry-<service> grep -c '<extrait du correctif>' /app/<chemin>"
```
ou par une vérification visuelle sur `stg.patisry.fr`.
