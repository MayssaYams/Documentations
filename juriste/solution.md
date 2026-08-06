# La solution Patisry — vue juridique (Juriste)

Ce document décrit **l'état de fait juridiquement pertinent de Patisry**, tel qu'il ressort du produit et du code — pas un avis juridique, un état des lieux à partir duquel instruire les sujets avec le CTO.

Vérifier avant de s'appuyer sur un détail (voir [`_conventions.md`](../_conventions.md)) — en particulier, ce document reflète un projet **en construction active** : beaucoup de faits ci-dessous peuvent changer vite.

---

## 1. Les trois acteurs

- **Le client** : commande et paie une pâtisserie.
- **Le pâtissier** : artisan qui vend via la plateforme. **Son statut juridique n'est pas défini** dans le produit — rien n'indique s'il s'agit d'auto-entrepreneurs, d'entreprises déjà immatriculées, ou d'un mélange. Point à instruire en premier : c'est structurant pour la réglementation applicable (vente de denrées alimentaires, agréments sanitaires) et pour la nature du contrat entre la plateforme et le pâtissier.
- **La plateforme (Patisry)** : intermédiaire technique entre les deux. **Aucune société n'est encore créée** — voir §4.

## 2. Le parcours de commande, vu sous l'angle contractuel

1. Le client compose un panier pouvant contenir des produits de **plusieurs pâtissiers**.
2. Au paiement, **N commandes séparées sont créées, une par pâtissier** — chacune est, en pratique, une transaction distincte entre le client et ce pâtissier précis, la plateforme jouant un rôle d'intermédiaire.
3. Le pâtissier fait progresser la commande (acceptée → en préparation → prête → à récupérer), et **seul le client confirme la réception finale**.
4. Retrait en boutique uniquement — pas de livraison active, ce qui simplifie (pour l'instant) les questions de responsabilité en cours de transport.

Question à instruire : la qualification exacte de la plateforme (simple intermédiaire technique / mandataire / autre) et ce qu'elle implique en termes de responsabilité si une commande se passe mal.

## 3. Le flux d'argent

- **Mode de paiement réellement fonctionnel aujourd'hui : « Espèces », payé à la remise.** Aucun flux d'argent ne transite donc par la plateforme actuellement.
- **Une intégration carte (Stripe) est en cours**, non finalisée bout en bout côté app. Tant qu'elle n'est pas active, la plateforme n'encaisse rien pour le compte des pâtissiers — ce qui limite les questions immédiates de conformité (DSP2, séquestre) mais **redevient un sujet urgent dès que ce paiement en ligne sera activé**.
- **Un taux de commission (`commission_rate`, 10 % par défaut) existe dans les données du profil pâtissier, mais n'est prélevé nulle part dans le code.** Aucun mécanisme de facturation ou de reversement n'existe. Tant que ce mécanisme n'est pas construit, il n'y a rien à qualifier juridiquement de ce côté — mais c'est un sujet à anticiper avec le Directeur Commercial avant l'implémentation, pas après.
- Un module d'abonnement (`subscription-service`, historique de facturation) existe dans le code mais n'est pas branché à un usage actif.

## 4. La société — état actuel

**Aucune société n'est créée.** Preuve la plus concrète : les mentions légales de l'app contiennent encore des champs à compléter :
> *« Patisry est édité par [Raison sociale de la société], immatriculée au RCS de [ville] sous le numéro [SIREN/SIRET]... »*

Tant que ce point n'est pas réglé :
- pas d'encaissement légal possible pour la plateforme elle-même ;
- toute démarche de vérification d'entité (Google Play Console notamment, voir §6) restera bloquée ou incomplète ;
- les CGV ne peuvent pas être finalisées (elles doivent identifier une entité juridique responsable).

## 5. Données personnelles traitées (pour le RGPD)

D'après ce que le produit collecte et manipule réellement :
- identité et contact : e-mail, nom, téléphone, adresse ;
- données de localisation (géolocalisation utilisée pour la recherche et l'affichage de distance) ;
- historique de commandes et de messages (conversations client↔pâtissier, y compris instructions spéciales pouvant contenir des informations personnelles — ex. « anniversaire de ma fille ») ;
- avis publiés (contenu potentiellement identifiant) ;
- données techniques : Firebase Analytics est intégré avec un dialogue de consentement déjà en place (`ConsentService`) ; l'identifiant publicitaire a été volontairement retiré du build Android (aucune finalité publicitaire déclarée) ;
- **suppression de compte non encore réellement implémentée** : le bouton existant dans l'app ne fait qu'une déconnexion, sans suppression ni anonymisation des données (voir ticket Linear PAT-31 côté Tech Lead — sujet à la fois technique et de conformité).

## 6. Hébergement

- **Dev** : serveur personnel du CTO (France).
- **Staging** : VM Scaleway (`51.15.236.77`), en France.
- **Production** : **pas encore déployée.** Le choix se limite pour l'instant à Azure ou AWS, **non tranché** — la localisation définitive du datacenter a un impact RGPD direct si elle sort de l'UE. À valider avec le DevOps avant que ce choix soit fait techniquement, pas après.

## 7. Vérification Google Play Console

Sujet déjà rencontré concrètement lors de la préparation du déploiement Android :
- déclaration de contenu publicitaire (« l'app contient-elle des annonces ? » → non, vérifié dans le code) ;
- déclaration de l'identifiant publicitaire (retiré du manifeste pour cohérence avec l'absence de publicité) ;
- exigence d'une **URL publique de suppression de compte** sur la fiche Play Store, avec obligation d'y détailler la procédure et la politique de conservation des données — non résolue à ce jour (voir §5).
- Selon le type de compte développeur et le volume d'installations visé, Google peut exiger une **vérification d'identité ou d'entité** (organisation) — probablement bloquée tant qu'aucune société n'existe (§4).

## 8. Points ouverts prioritaires — ne rien présumer

1. Statut juridique des pâtissiers (indépendant/auto-entrepreneur, ou autre).
2. Rôle exact et responsabilité du prestataire de paiement une fois l'intégration carte activée.
3. Localisation définitive de l'hébergement en production.
4. Statut et calendrier de création de la société.
5. Politique réelle de suppression/conservation des données, à la fois pour la conformité RGPD et pour la fiche Google Play.
