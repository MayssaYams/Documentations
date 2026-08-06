# La solution Patisry — vue design (Designer)

Ce document explique **la surface visible de la plateforme** : les écrans, les parcours, le système visuel et les règles d'interaction déjà tranchées. Pour le « pourquoi » métier, voir [`po/solution.md`](../po/solution.md).

Vérifier avant de s'appuyer sur un détail (voir [`_conventions.md`](../_conventions.md)).

---

## 1. Le contexte de conception

- **Mobile-first, sans discussion pour l'instant.** L'app est une seule codebase Flutter qui sort en iOS, Android et Web — mais tout est pensé à la taille mobile. Le desktop viendra plus tard : ne pas sur-investir dans des maquettes larges sans demande explicite.
- L'app est utilisée par **deux publics dans la même interface** : le client qui achète, et le pâtissier qui vend. Un même compte peut être les deux. Un écran de commande, par exemple, a une version client et une version pâtissier.

---

## 2. Carte des écrans

**Découverte / achat (client)**
`/` accueil · `/products/:id` fiche produit · `/bakers/:id` profil pâtissier public · recherche · `/favorites` + `/favorites/group` (favoris organisés en groupes) · `/cart` panier · `/payment` puis `/payment/confirmation`

**Compte (tous)**
`/account` · `/account/profile` + `/account/profile/edit` · `/account/orders` + `/account/orders/detail` · `/account/messages` + `/account/messages/conversation` · `/notifications` · `/account/payment-methods` (+ ajout/édition carte, Google Pay, Apple Pay, PayPal)

**Espace pâtissier**
`/account/dashboard` tableau de bord · `/account/my-pastries` + `/account/my-pastries/edit` · `/account/baker/edit` profil pâtissier

**Avis**
`/reviews` liste des avis d'un produit · `/write-review`

**Admin** (back-office, esthétique secondaire)
`/admin` et ses sous-pages : analytics, users, bakers, products, categories, allergens, sizes, newsletter, audit-log, review-reports, settings, push

**Statique** : `/contact`, `/mentions-legales`, `/cgv`, `/qui-sommes-nous`

**Auth** : `/login`, `/register`, `/forgot-password`, `/email-verification`

---

## 3. Le système visuel existant

- **Thème** : `Patisry/lib/core/theme/patisry_theme.dart`
- **Couleur signature** : le rose `#E36387` — actions principales, états sélectionnés, erreurs (il sert aussi de rouge d'erreur, ce qui est une ambiguïté à garder en tête).
- **Texte principal** : brun foncé `#3E3232`. **Secondaire** : `#5F4C49`.
- **Succès** : vert `#4CAF50`. **Fond alternatif** : `#F8F5F4`.
- **Formes** : coins arrondis systématiques (12 px sur les champs et boutons, 16 px sur les cartes et modales), ombres portées très légères (noir à 4–5 % d'opacité).

### Composants déjà en place — les réutiliser avant d'en créer

`Patisry/lib/shared/widgets/` :
`back_bar` · `baker` · `buttons` · `cards` · `carousel` · `cart` · `common` · `date_picker` · `favorite_button` · `favorites` · `filter_button` · `filter_chip` · `filter_chip_list` · `filter_modal` · `footer` · `input_field` · `messages` · `navigation` · `orders` · `payment` · `rating` · `responsive_grid` · `reviews` · `search_bar` · `search_bar_with_suggestions` · `search_suggestions` · `toolbar`

---

## 4. Règles d'interaction déjà tranchées

Ces décisions viennent de bugs réels corrigés — les respecter évite de les recréer.

**Le bouton retour ne ramène pas à l'accueil.** Il revient à l'écran réellement précédent (historique navigateur sur le web). Un retour qui renvoie systématiquement à l'accueil a été explicitement rejeté : ce n'est pas ce qu'un utilisateur attend.

**Ne jamais proposer un choix qui mène à une impasse.** Cas concret : sur la fiche produit, le client choisit une date puis un horaire. Si le délai de préparation fait qu'aucun créneau n'est encore disponible ce jour-là, **la date elle-même doit être grisée** — pas seulement les horaires. Proposer une date cliquable qui n'ouvre que des créneaux grisés est un cul-de-sac. Cette règle vaut partout, pas seulement sur ce calendrier.

**Le polish est attendu par défaut, sans qu'on le demande.** Sur tout écran de liste ou de conversation : scroll automatique vers le bas, indicateurs de chargement, états vides, gestion des erreurs. Ne pas livrer une maquette qui ne traite que le cas nominal.

**Le sélecteur d'horaire s'ouvre tout seul** après le choix d'une date — enchaînement voulu, ne pas le casser.

---

## 5. Parcours clés à connaître

**Acheter** : accueil → fiche produit → choix date **et** horaire de retrait → ajout au panier → panier → paiement → confirmation.
Sur la fiche produit, le client peut laisser une **instruction spéciale** (« joyeux anniversaire Léa »). Elle a une conséquence invisible mais importante : elle **ouvre automatiquement une conversation** avec le pâtissier. La messagerie n'est donc pas un espace isolé, elle démarre depuis l'achat.

**Suivre sa commande** : le client voit l'avancement (acceptée → en préparation → prête → à récupérer), et c'est **lui** qui appuie sur « J'ai récupéré ma commande » pour clore. Ce bouton n'apparaît qu'au stade « en attente de récupération ». Le pâtissier, lui, fait avancer les étapes précédentes.

**Un panier peut contenir plusieurs pâtissiers** → il en sort **plusieurs commandes distinctes**. L'affichage doit rendre ça compréhensible sans donner l'impression d'un bug.

**Noter** : possible seulement après avoir reçu la commande, un avis par commande et par produit. Le pâtissier peut répondre publiquement sous l'avis, et un avis peut être signalé.

**Note masquée** : tant qu'un pâtissier n'a pas assez de commandes terminées, sa note n'est pas affichée. Prévoir un état visuel pour « pas encore de note » qui ne ressemble pas à « note de zéro » — actuellement des étoiles vides avec « 0.0 » s'affichent, ce qui est trompeur et mériterait d'être repensé.

---

## 6. Contraintes qui influencent le design

- Les images produits sont fournies par les pâtissiers : qualité, cadrage et ratio **très variables**. Les composants doivent rester dignes avec une photo mal cadrée ou absente.
- Le mode de paiement réellement utilisé est **« Espèces »** (paiement à la remise). Les écrans carte/Google Pay/Apple Pay/PayPal existent mais ne sont pas le chemin principal.
- La livraison n'est **pas** active : tout est en retrait boutique. Ne pas dessiner de suivi de livraison sans validation du PO.
