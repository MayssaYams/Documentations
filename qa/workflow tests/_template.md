# {{Nom de la fonctionnalité}}

> Copier ce fichier, le renommer en `kebab-case.md` dans le bon sous-dossier, remplir chaque section, supprimer cette ligne de note. Voir [`README.md`](README.md) pour la convention complète.

| | |
|---|---|
| **Statut** | 🔲 à rédiger / 🟡 en écriture / ✅ rédigé et à jour / 🔁 à revoir (le code a bougé) |
| **Écrit avant le développement ?** | oui / non — si non, le dire franchement et le rattraper au prochain changement sur cette fonctionnalité |
| **Écrans concernés** | `chemin/vers/l_ecran.dart` (route `go_router`) |
| **Endpoints concernés** | `METHODE /api/service/chemin/` (service) |
| **Tickets Linear liés** | PAT-XX |
| **Dernière relecture** | AAAA-MM-JJ, par qui |

---

## 1. Périmètre

Ce que ce document couvre, en une ou deux phrases. Ce qu'il ne couvre **pas** explicitement (renvoyer vers l'autre fichier workflow si le cas de bord appartient à une autre fonctionnalité — ne pas dupliquer).

## 2. Préconditions

- Compte(s) de test nécessaires — utiliser les comptes standard (`patissier@exemple.com` = baker 5, `client@exemple.com`, cf. `Documentations/qa/state.md` / mémoire projet `patisry-staging-test-accounts`). **Jamais** la vraie boutique Berile (baker_id=1).
- État de données requis (ex : un produit actif, une commande dans tel statut, une adresse renseignée…).
- Environnement cible : staging (`stg.patisry.fr`) par défaut — CLAUDE.md : la Freebox est abandonnée, dev n'est pas suffisant pour valider.

## 3. Scénario nominal (happy path)

Étapes numérotées, chacune avec son résultat attendu — assez précis pour qu'un humain ou une IA QA sans autre contexte puisse dérouler et juger pass/fail sans deviner.

1. **Action.** Résultat attendu (UI + code HTTP si pertinent + effet en base si pertinent).
2. **Action.** Résultat attendu.
3. ...

## 4. Cas de bord et erreurs attendues

Chaque cas : contexte → action → résultat attendu. Se concentrer sur ce qui **doit être refusé proprement** (pas de crash, pas de 500, message clair), pas seulement ce qui doit réussir.

- **Cas.** → Résultat attendu.
- **Cas.** → Résultat attendu.

## 5. Règles métier à vérifier

Extraire uniquement les règles de `CLAUDE.md` / `Documentations/qa/solution.md` qui s'appliquent à CETTE fonctionnalité (lien plutôt que copie si la règle est longue). Exemple de forme :
- Règle : ... → comment le test le prouve.

## 6. Non-régressions connues

Bugs réels déjà rencontrés sur cette fonctionnalité (avec date/ticket si connu) — à retester explicitement à chaque évolution de l'écran ou de l'endpoint, pas seulement le happy path.

- **[date/PAT-XX]** Description du bug → ce qu'il faut revérifier précisément.

## 7. Comment vérifier

Commandes exactes (tests backend concernés avec leur label `manage.py test`, `flutter analyze`/`flutter test` si écran Flutter, vérif manuelle staging). Renvoyer vers [`role.md`](role.md) pour les commandes génériques, ne détailler ici que ce qui est spécifique à cette fonctionnalité (ex : tunnel SSH déjà couvert ailleurs, pas la peine de le répéter en entier).

## 8. Definition of done

Checklist finale — c'est le **but à atteindre** pour dire la fonctionnalité validée, cochable par un humain ou une IA QA :

- [ ] Scénario nominal passe de bout en bout sur staging
- [ ] Tous les cas de bord de la section 4 produisent le résultat attendu
- [ ] Aucune non-régression de la section 6 n'est réapparue
- [ ] Tests automatisés listés en section 7 verts (backend + `flutter analyze`/`flutter test` si frontend)
- [ ] Aucune donnée sensible exposée publiquement qui ne devrait pas l'être (adresse pâtissier, email, etc. — cf. `patisry-public-endpoints-privacy-guard`)
