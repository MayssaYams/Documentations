# Conventions — organisation des postes en IA

Règles communes à tous les dossiers `Documentations/<poste>/`. Chaque fichier de poste doit s'y référer plutôt que de les réexpliquer.

## Organigramme

```
CTO (toi)
 ├── PO ──────────────── Designer
 ├── Tech Lead ───────── Full-stack
 │                ├───── DevOps
 │                └───── QA
 ├── Directeur Commercial
 └── Juriste
```

- Tu discutes directement avec **PO**, **Tech Lead**, **Directeur Commercial** et **Juriste** — quatre postes au même niveau, sans hiérarchie entre eux, chacun dans des sessions longues que tu gardes ouvertes toi-même (contexte qui s'auto-résume avec le temps, mais qui n'est jamais totalement froid).
- **PO** peut lancer un sous-agent **Designer** pour une tâche précise, attendre qu'il termine, relire son résultat, et le relancer si besoin. Pas d'échange en cours de tâche — uniquement avant (consigne) et après (revue).
- **Tech Lead** fonctionne pareil avec **Full-stack**, **DevOps** et **QA** : il découpe, lance, relit, relance si besoin, et tient à jour les fichiers de ses sous-agents s'ils ont besoin d'être corrigés.
- **Directeur Commercial** et **Juriste** n'ont pas de sous-agent dédié pour l'instant — ce sont des postes de conseil direct au CTO, tournés respectivement vers le marché/la croissance et vers le cadre légal.
- Designer, Full-stack, DevOps et QA repartent de zéro à chaque lancement — leurs fichiers de poste sont leur SEULE mémoire d'une tâche à l'autre. Rien n'est acquis qui ne soit écrit.

## Chaque poste a trois fichiers

- **`role.md`** (mémoire longue) : mission, périmètre, dépendances avec les autres postes, et une **carte** des fichiers/fonctions utiles à ce poste — pour ne pas avoir à réexplorer tout le repo à chaque tâche. Change rarement.
- **`solution.md`** (mémoire longue) : explication approfondie de la plateforme Patisry **vue sous l'angle de ce poste uniquement**. Chaque version est volontairement différente — le DevOps y trouve le détail des pipelines et de la base, le Full-stack le détail du code, le Designer les écrans et règles d'interaction, etc. Un agent qui démarre à froid lit `role.md` + `solution.md` et sait travailler. Change quand la plateforme évolue.
- **`state.md`** (mémoire courte) : ce qui est fait, ce qui reste à faire, ce qui n'a pas été possible à faire correctement, les questions ouvertes. Change à **chaque tâche**.

Ne pas recopier dans un `solution.md` ce qui appartient à un autre poste : y renvoyer par un lien.

## Règle non négociable

**Chaque poste doit mettre à jour son `state.md` en continu, pas seulement en fin de session.** Si une tâche est coupée en cours de route, `state.md` doit déjà refléter l'état réel — ne pas attendre la fin pour écrire, le prochain lancement (froid) de cet agent ne connaîtra que ce qui est écrit.

## PO ↔ Tech Lead : visibilité croisée

PO doit pouvoir lire `Documentations/tech-lead/role.md` et `state.md`, et vice versa. Chacun doit vérifier l'état de l'autre avant de décider d'une action qui le concerne (ex: Tech Lead ne découpe pas une feature sans vérifier que le PO l'a validée fonctionnellement ; PO ne promet pas une deadline sans vérifier les blocages techniques en cours côté Tech Lead).

## Vérifier avant de faire confiance

Toute carte de fichiers/fonctions dans `role.md` est une photo prise à un instant T — le code peut avoir bougé depuis. Avant d'agir sur un pointeur (pas juste avant de le citer), vérifier qu'il est toujours exact (`grep`/`Read` rapide). Un pointeur faux non vérifié peut faire perdre plus de temps qu'il n'en fait gagner.

## Documentation déjà existante à ne pas dupliquer

Le dossier `Documentations/` contient déjà une base riche, antérieure à cette organisation par poste — les fichiers de poste doivent pointer dessus plutôt que la recopier :
- `Documentations/Doc fonctionnelle/` — doc API complète par service (00 à 15), vue PO fonctionnelle (16), brief dev technique (17), parcours QA E2E (18)
- `Documentations/DATABASE_SCHEMA.md`, `API_DOCUMENTATION_COMPLETE_FREEBOX.md`, `DEPLOYMENT_FREEBOX.md`, `SSH_TUNNEL_README.md`, `Service-fonctionnel.md` (statut tests par service)
- `CLAUDE.md` à la racine du projet — vue d'ensemble archi, règles non négociables (tests, migrations DB, etc.)
