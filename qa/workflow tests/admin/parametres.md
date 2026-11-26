# Paramètres plateforme

| | |
|---|---|
| **Statut** | ✅ rédigé et à jour |
| **Écrit avant le développement ?** | non — fonctionnalité déjà en production, rédigé rétroactivement le 2026-09-22 |
| **Écrans concernés** | `admin_settings_screen.dart` (`/admin/settings`) |
| **Endpoints concernés** | admin-service : `GET/PUT /api/admin/settings/min-orders-for-baker-rating/` |
| **Tickets Linear liés** | — |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Le seul réglage plateforme exposé dans le panel admin à ce jour : le seuil de commandes terminées à partir duquel la note d'un pâtissier devient visible publiquement. Cet écran ne contient **aucun autre réglage** — ne pas chercher de section supplémentaire (frais, zone de lancement, textes légaux...) qui n'existe pas dans le code.

## 2. Préconditions

- Le compte admin de test.
- Pour vérifier l'effet du seuil : un pâtissier de test avec moins de commandes terminées que la valeur courante du réglage, et si possible un second qui en dépasse (ou le même pâtissier complété entre les deux mesures) — cf. [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md) §2 et §4, qui documente le test du seuil côté client. Ne pas dupliquer ce scénario ici, seulement vérifier que **la valeur modifiée depuis cet écran est bien celle utilisée là-bas**.

## 3. Scénario nominal (happy path)

1. **Ouvrir `/admin/settings`.** `GET /settings/min-orders-for-baker-rating/` → champ pré-rempli avec la valeur courante.
2. **Valeur par défaut confirmée dans le code (pas supposée)** : si aucune ligne `platform_settings` n'existe encore pour la clé `min_orders_for_baker_rating`, le backend renvoie `'10'` par défaut (`Backend/admin-service/admin_app/views.py::setting_min_orders_for_baker_rating`) ; côté Flutter, `AdminApi.getMinOrdersForBakerRating()` retombe aussi sur `10` si la valeur reçue n'est pas parsable (`int.tryParse(...) ?? 10`) — **les deux défauts concordent à 10**, ce qui confirme la valeur mentionnée dans [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md), désormais vérifiée dans le code et pas seulement rappelée de mémoire.
3. **Modifier la valeur et enregistrer.** `PUT .../min-orders-for-baker-rating/` avec `{value: "<entier>"}` → `PlatformSetting.objects.update_or_create(pk='min_orders_for_baker_rating', ...)`, avec `updated_at`/`updated_by_id` renseignés. Confirmation « Réglage enregistré. » en snackbar.
4. **Effet immédiat.** La nouvelle valeur doit être prise en compte par review-service/baker-service dès l'enregistrement, sans redémarrage de service ni délai de cache à attendre (à vérifier explicitement — voir §4).

## 4. Cas de bord et erreurs attendues

- **Valeur non numérique ou négative.** Refusée côté client avant l'appel réseau (« Merci de saisir un entier positif. ») **et** côté serveur indépendamment (`value.isdigit()` + `int(value) < 0` → 400 « value doit être un entier positif. ») — vérifier que les deux couches rejettent bien, pas seulement celle testée en premier via l'UI (un appel direct à l'API doit aussi être bloqué).
- **Valeur à 0.** Un seuil de 0 signifierait que la note de tout pâtissier est visible dès sa première commande terminée — valeur techniquement acceptée (`>= 0`), à tester explicitement pour confirmer que ce n'est pas traité comme une valeur invalide par erreur.
- **Propagation réelle du changement.** Le réglage est lu par review-service et/ou baker-service (commentaire du code : « utilisé par review-service/baker-service ») — **vérifier concrètement, pas supposer**, qu'un changement de seuil depuis `/admin/settings` change bien l'affichage de la note masquée sur une fiche pâtissier peu après, sans qu'il faille redéployer ou vider un cache. Si un délai ou un cache existe, c'est une information à ajouter ici, pas à deviner.
- **Deux administrateurs modifient le réglage presque simultanément.** `update_or_create` sur une clé primaire textuelle ne gère aucun verrou optimiste — le dernier `PUT` gagne silencieusement, sans avertissement de conflit. Comportement à connaître plutôt qu'à corriger dans le cadre de ce fichier, mais à mentionner si un jour deux admins se marchent dessus en pratique.

## 5. Règles métier à vérifier

- Point d'entrée admin unique `IsAdminRole` → voir [`dashboard-et-analytics.md`](dashboard-et-analytics.md) §5.
- Le nom exact de la clé de configuration est **`min_orders_for_baker_rating`** (table `platform_settings`, colonne `key`) — à utiliser tel quel pour toute vérification directe en base, pas une variante approchante.
- Chaque modification est auditée (`admin.settings.updated`, avec la nouvelle valeur en métadonnée) — mêmes réserves sur la fiabilité d'écriture que documenté dans [`utilisateurs-et-audit.md`](utilisateurs-et-audit.md) §4.

## 6. Non-régressions connues

_Aucune connue à ce jour — première rédaction de cette fiche. Ajouter ici tout bug réel rencontré lors d'une future campagne._

## 7. Comment vérifier

- Backend : `admin-service` (`manage.py test`, classe `PlatformSettingsEndpointTests` — `Backend/admin-service/admin_app/tests/test_endpoints.py` — couvre déjà la valeur par défaut, la mise à jour, le rejet d'une valeur non numérique, et le rejet pour un non-admin/non-authentifié).
- Vérification directe en base : `SELECT value, updated_at, updated_by FROM platform_settings WHERE key = 'min_orders_for_baker_rating'` après modification.
- Effet croisé à vérifier manuellement : modifier le seuil puis recharger la fiche publique d'un pâtissier de test proche du seuil (→ [`../commande-et-paiement/avis.md`](../commande-et-paiement/avis.md) §4).
- Frontend : `flutter analyze` + test manuel staging avec le compte admin.

## 8. Definition of done

- [ ] Valeur par défaut à 10 confirmée quand aucune ligne n'existe en base
- [ ] Modification enregistrée, cohérente en base (`platform_settings`)
- [ ] Valeur non numérique/négative rejetée côté client et côté serveur
- [ ] Valeur à 0 acceptée et testée explicitement
- [ ] Propagation réelle du changement vérifiée sur une fiche pâtissier proche du seuil, sans redéploiement nécessaire
- [ ] Modification retrouvée dans `audit_log`
- [ ] Tests `admin-service` (`PlatformSettingsEndpointTests`) verts
- [ ] `flutter analyze` sans erreur
