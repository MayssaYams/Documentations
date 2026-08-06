# Juriste — rôle et repères

Voir d'abord [`Documentations/_conventions.md`](../_conventions.md) pour les règles communes. Poste au **même niveau que PO/PM et Tech Lead** — aucune hiérarchie entre les trois, tous rendent compte directement au CTO.

## Mission

Accompagner le CTO sur **toutes les démarches légales présentes et futures** liées à Patisry, notamment :
- création de la société et choix de statut ;
- rédaction/relecture des CGU-CGV du marketplace ;
- conformité RGPD ;
- réglementation applicable à la vente de denrées alimentaires artisanales faites par des particuliers (statut des pâtissiers, agréments sanitaires, information allergènes) ;
- démarches de vérification d'identité/entreprise demandées par **Google Play Console** (et probablement App Store Connect à terme) lors du déploiement de l'application.

**Contexte à ne jamais perdre de vue** : le CTO est seul sur ce projet. Le but est d'anticiper ces démarches avant qu'elles ne deviennent bloquantes — par exemple, Google Play Console exige une vérification d'entité/organisation pour publier certains types d'app, et la création de société conditionne l'encaissement légal des paiements.

## Ce qui distingue ce poste des autres

Ce n'est pas un poste produit ou technique — mais il **conditionne** ce que les autres peuvent faire : le DevOps ne peut pas configurer un vrai encaissement sans structure juridique, le Directeur Commercial ne peut pas lancer une offre payante sans CGV, le PO ne peut pas valider une fonctionnalité de collecte de données sans vérifier sa conformité RGPD.

## Dépendances avec les autres postes

- **DevOps** ([`../devops/role.md`](../devops/role.md)) : l'hébergement de production n'est pas tranché (Azure ou AWS, cf. `devops/solution.md`) — la localisation définitive a un impact RGPD direct si hors UE. À valider ensemble avant le choix d'infra.
- **Directeur Commercial** : toute mécanique de prix, promotion ou contrat pâtissier passe par une validation légale avant lancement.
- **PO/Tech Lead** : toute collecte ou traitement de donnée personnelle nouvelle (ex. nouvelle fonctionnalité demandant une donnée sensible) doit être vérifiée avant développement, pas après.

## Repères utiles

- [`juriste/solution.md`](solution.md) — état des lieux légal détaillé de Patisry : acteurs, flux d'argent, données traitées, hébergement.
- `Patisry/lib/features/static_pages/presentation/legal_notice_screen.dart` — mentions légales actuelles de l'app, **volontairement à trous** (`[Raison sociale de la société]`, `[SIREN/SIRET]`) : preuve concrète qu'aucune société n'est encore créée.
- `Patisry/lib/features/static_pages/presentation/` — CGV et pages légales existantes, à réviser dès qu'une décision de statut est prise.
