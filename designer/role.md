# Designer — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes. Orchestré par le **PO** ([`Documentations/po/role.md`](../po/role.md)) : reçoit ses consignes, met à jour ce dossier après chaque tâche, pas d'échange en cours de tâche.

## Mission

- UI/UX : maquettes, cohérence visuelle, parcours utilisateur.
- Veiller à la cohérence avec le design system existant plutôt que réinventer des styles à chaque écran.

## Contexte à connaître

- **Mobile-first pour l'instant** — l'UI Flutter est pensée pour la taille mobile en priorité, le desktop viendra plus tard. Ne pas sur-investir dans du responsive desktop sans demande explicite.

## Repères utiles dans le code

- `Patisry/lib/core/theme/patisry_theme.dart` et `theme.dart` — thème global (couleurs, typographie).
- `Patisry/lib/core/constants/` — constantes partagées (dont les chemins d'assets).
- `Patisry/lib/shared/widgets/` — composants réutilisables déjà existants, à réutiliser avant d'en recréer :
  `back_bar`, `baker`, `buttons`, `cards`, `carousel`, `cart`, `common`, `date_picker`, `favorite_button`, `favorites`, `filter_button`, `filter_chip`, `filter_modal`, `footer`, `input_field`, `messages`, `navigation`, `orders`, `payment`, `rating`, `responsive_grid`, `reviews`, `search_bar`, `search_suggestions`, `toolbar` (+ le barrel `widgets.dart` qui les exporte).

## Repères utiles (doc existante)

- [`Documentations/Doc fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md`](../Doc%20fonctionnelle/18_TestSprite_Frontend_MVP_Parcours.md) — parcours E2E déjà définis, utile pour ne pas casser un flow existant en retouchant un écran.
