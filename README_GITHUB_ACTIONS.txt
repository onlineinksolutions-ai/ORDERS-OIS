================================================================
 BUILD APK VIA GITHUB ACTIONS - SANS RIEN INSTALLER
================================================================

Le workflow compile l'APK sur les serveurs GitHub (gratuit).
Vous n'installez ni Flutter ni Android Studio.

----------------------------------------------------------------
1. CREER UN DEPOT GITHUB
----------------------------------------------------------------
- Compte gratuit sur https://github.com
- Bouton "New repository"
- Nom : ois-orders-mobile  (Private recommande)
- Cocher RIEN d'autre, cliquer "Create repository"

----------------------------------------------------------------
2. UPLOADER LE CODE SOURCE
----------------------------------------------------------------
Decompressez ois_orders_mobile.zip sur votre PC.
Sur la page du depot vide, cliquez "uploading an existing file"
(lien dans la zone grise), puis glissez TOUT le CONTENU du dossier
ois_orders_mobile (pas le dossier lui-meme, son contenu) :
  - lib/
  - android/
  - assets/
  - pubspec.yaml
  - analysis_options.yaml
  - .github/   (IMPORTANT : ce dossier contient le workflow)

ATTENTION : le dossier .github commence par un point. Si le glisser-
deposer web l'ignore, voir la note en bas (methode git en ligne de
commande).

Cliquez "Commit changes".

----------------------------------------------------------------
3. LE WORKFLOW EST DEJA LA
----------------------------------------------------------------
Le fichier .github/workflows/build-apk.yml est inclus dans le ZIP.
Des qu'il est sur GitHub, l'onglet "Actions" du depot l'utilise
automatiquement. Rien a creer manuellement.

----------------------------------------------------------------
4. LANCER LE BUILD
----------------------------------------------------------------
- Onglet "Actions" du depot
- Si GitHub demande d'activer les workflows : cliquez "I understand
  my workflows, go ahead and enable them"
- A gauche, cliquez "Build APK"
- Bouton "Run workflow" (a droite) > "Run workflow"
- Le build demarre. Patientez 5-10 min (rond orange -> coche verte).

Le workflow se lance AUSSI automatiquement a chaque push sur main.

----------------------------------------------------------------
5. TELECHARGER app-release.apk
----------------------------------------------------------------
- Cliquez sur le run termine (coche verte)
- En bas, section "Artifacts"
- Cliquez "app-release-apk" -> telecharge un .zip
- Decompressez-le : il contient app-release.apk

----------------------------------------------------------------
6. INSTALLER SUR LE TELEPHONE
----------------------------------------------------------------
- Transferez app-release.apk sur le telephone
- Ouvrez-le, autorisez "Sources inconnues" pour l'app qui ouvre
  (Fichiers / Gmail / Drive), installez.
- Au 1er lancement : URL API = https://votresite.com/ois-orders-api/
  + username/password definis dans config.php de l'API.

----------------------------------------------------------------
SI LE BUILD ECHOUE (rond rouge)
----------------------------------------------------------------
- Cliquez le run rouge, ouvrez l'etape en echec, copiez le message
  d'erreur et envoyez-le moi : je corrige.
- Erreur frequente : .github non uploade -> l'onglet Actions reste
  vide. Re-verifiez que .github/workflows/build-apk.yml est bien
  present dans le depot.

----------------------------------------------------------------
NOTE : SI LE DOSSIER .github NE S'UPLOADE PAS (interface web)
----------------------------------------------------------------
Certains navigateurs ignorent les dossiers commencant par un point
en glisser-deposer. Solution : creer le fichier directement sur
GitHub.
- Sur le depot : "Add file" > "Create new file"
- Dans le champ nom, tapez exactement :
    .github/workflows/build-apk.yml
  (GitHub cree les dossiers automatiquement avec les "/")
- Collez le contenu du fichier build-apk.yml fourni
- "Commit changes"

----------------------------------------------------------------
SIGNATURE
----------------------------------------------------------------
L'APK produit est signe avec la cle debug par defaut : installable
directement (usage interne), mais pas publiable sur le Play Store.
Pour une vraie cle de signature, voir COMMANDES_BUILD_APK.txt.

Compatibilite : PrestaShop 8.1.7 / PHP 8.x / Android 10+ (minSdk 29).
