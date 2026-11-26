# Mémorisation de la localisation (mode GPS / ville)

| | |
|---|---|
| **Statut** | 🔁 à revoir — raffinement en cours suite aux décisions CTO du 2026-09-22, pas encore mergé ni testé sur device |
| **Écrit avant le développement ?** | non — écrit pendant la revue de la PR, avant test terrain |
| **Portée** | Toute l'app — `LocationService`, `location_chip.dart`, `location_flow.dart`, `manual_location_sheet.dart`, `location_pre_prompt_dialog.dart` |
| **Tickets Linear liés** | PAT-77 (PR [#34](https://github.com/MayssaYams/Patisry/pull/34), non mergée) |
| **Dernière relecture** | 2026-09-22 |

---

## 1. Périmètre

Ce qui est mémorisé sur l'appareil entre deux lancements de l'app (mode GPS/ville/aucun, commune saisie), la relocalisation silencieuse, et l'action « Oublier ma localisation ». Ne couvre pas le géocodage BAN lui-même (→ [`../patissier/adresse-et-position.md`](../patissier/adresse-et-position.md) pour la désambiguïsation, même brique technique).

**Contrainte absolue, à vérifier en priorité sur toute évolution de cette fonctionnalité** : aucune latitude ni longitude ne doit jamais être écrite dans le stockage local, sous aucune forme. `UserLocation` ne doit jamais exposer `toJson()`/`fromJson()`.

## 2. Préconditions

- Appareil Android et iOS réels (le comportement dépend de la gestion des permissions par l'OS, non simulable en web).
- Un compte de test avec accès aux réglages système (pour révoquer la permission GPS manuellement).

## 3. Scénario nominal (happy path)

1. **Premier lancement, choix GPS.** Pre-prompt affiché → « Autoriser » → popup système → permission accordée → position acquise, distance affichée.
2. **Fermeture complète de l'app puis relance.** Mode GPS restauré **sans aucune popup** (la permission est lue en silence via `Geolocator.checkPermission()`), distance affichée directement.
3. **Choix ville saisie.** Pre-prompt → « Saisir ma ville » → commune choisie (résolue en `municipality` par la BAN) → mémorisée (libellé + **code INSEE**, jamais de coordonnées).
4. **Fermeture puis relance en mode ville.** La ville est re-résolue via son code INSEE au lancement (pas par texte libre — PAT-76 a montré que la résolution par texte est instable d'un appel à l'autre pour la BAN).
5. **Rafraîchissement automatique en session (mode GPS).** Une fois la permission accordée, la position se rafraîchit automatiquement, en silence, **toutes les 15 minutes environ**, sans jamais redemander quoi que ce soit à l'utilisateur — décision CTO du 2026-09-22, à vérifier une fois le raffinement de la PR mergé (voir §6).
6. **« Oublier ma localisation »** depuis la feuille ouverte par la puce de la home. Efface le mode ET la ville mémorisés. Confirmation affichée.

## 4. Cas de bord et erreurs attendues

- **BAN injoignable au lancement (mode ville).** La ville mémorisée reste affichée, sans tri par distance, l'app reste utilisable, le choix n'est pas perdu.
- **Permission GPS révoquée entre deux lancements, une ville est mémorisée en repli.** Bascule silencieuse sur la ville, jamais de popup.
- **Permission GPS révoquée, aucune ville de repli, refus définitif de l'OS (`deniedForever` — « Ne plus demander »).** Repli manuel proposé une seule fois, le pre-prompt ne revient plus (comportement définitif, voulu).
- **Permission GPS révoquée, aucune ville de repli, refus simple (`denied` — couvre aussi l'expiration d'un « Autoriser une fois »).** **Le pre-prompt doit réapparaître** au lancement suivant plutôt que d'être supprimé définitivement — décision CTO du 2026-09-22 : un « Autoriser une fois » signale que le choix de l'utilisateur peut changer, on ne doit pas le considérer comme un refus permanent. **À vérifier une fois le raffinement mergé** (voir §6, non encore implémenté au moment de la rédaction).
- **Mise à jour de l'app pour un utilisateur qui avait déjà accordé la permission avant PAT-77.** Aucune relocalisation automatique tant qu'il n'a pas choisi « GPS » une fois dans la feuille (aucun mode mémorisé au départ) — comportement confirmé volontaire.
- **Choisir GPS après avoir déjà saisi une ville.** La ville reste en mémoire comme repli, pas effacée — comportement confirmé volontaire.

## 5. Règles métier à vérifier

- CLAUDE.md (révisé le 2026-09-21, PAT-77) : coordonnées GPS jamais stockées ; mode et commune saisie mémorisés **sur l'appareil uniquement**, jamais en base, jamais envoyés pour stockage.
- Le rafraîchissement automatique toutes les 15 minutes (§3 point 5) ne doit produire **aucune UI** — ni popup système, ni pre-prompt, ni SnackBar visible pour l'utilisateur.

## 6. Non-régressions connues / points en cours

- **PAT-77 (2026-09-21, première version)** : mémorisation de base livrée (voir historique PR #34).
- **Raffinement demandé par le CTO le 2026-09-22, en cours d'implémentation au moment de la rédaction de cette fiche :**
  1. Le rafraîchissement automatique silencieux toutes les 15 minutes en mode GPS **n'existait pas** dans la première version (le cache mémoire expirait simplement, sans rien qui le renouvelle automatiquement) — à vérifier que ce n'est plus le cas une fois la PR mise à jour.
  2. La distinction `denied` (revient sur le pre-prompt) vs `deniedForever` (ne revient pas) dans le cas « GPS révoqué, aucune ville de repli » n'existait pas non plus — la première version traitait les deux cas comme définitifs.
  - **Ce document doit être remis à jour et son statut passé à `✅` une fois ces deux points mergés et vérifiés sur device.**

## 7. Comment vérifier

- `flutter analyze`/`flutter test` sur la branche `alvinnzembani/pat-77-localisation-retrouver-le-choix-gps-ville-saisie-apres` — 250 tests passent, 4 échouent (préexistants sur `develop`).
- **Test manuel obligatoire sur Android et iOS réels** : fermeture complète de l'app puis relance, révocation de la permission dans les réglages système, coupure réseau, attente 15+ minutes en session pour vérifier le rafraîchissement silencieux.
- Test dédié au garde-fou : vérifier qu'aucune clé de `SharedPreferences` ne contient de valeur ressemblant à une coordonnée (déjà couvert par un test automatisé dans la PR, à ne pas retirer).

## 8. Definition of done

- [ ] Mode GPS et ville restaurés sans re-saisie après fermeture complète, Android et iOS
- [ ] Rafraîchissement silencieux toutes les ~15 min en mode GPS, sans aucune UI, vérifié en session longue
- [ ] `denied` (dont « Autoriser une fois » expiré) sans ville de repli → pre-prompt réapparaît ; `deniedForever` → ne réapparaît pas
- [ ] BAN injoignable : app utilisable, choix conservé
- [ ] « Oublier ma localisation » efface tout ce qui a été mémorisé
- [ ] Aucune coordonnée GPS jamais écrite dans le stockage local (test automatisé + relecture manuelle du code)
- [ ] `flutter analyze`/`flutter test`/`flutter build web` verts
