# OIS Orders Mobile — App Flutter

App Android de gestion des commandes PrestaShop pour Online Ink Solutions.
Communique uniquement avec l'API PHP sécurisée (aucun secret embarqué).

## Prérequis
- Flutter SDK 3.x (`flutter --version`)
- Android Studio + SDK Android (API 29+)
- Un appareil/émulateur Android 10+

## Génération du projet natif
Ce dossier contient le code `lib/` ET le `AndroidManifest.xml` complet avec
toutes les permissions (téléphone, WhatsApp, email, notifications,
réseau). Le reste du squelette Android natif (Gradle, icônes, fichiers de
build) doit être généré par Flutter car il dépend de votre version de SDK :

```bash
# 1. Dans un dossier vide, créer le squelette natif :
flutter create --org com.onlineinksolutions --project-name ois_orders_mobile .

# 2. Remplacer par les fichiers fournis ici (ECRASER) :
#    - lib/                                          (tout le dossier)
#    - pubspec.yaml
#    - android/app/src/main/AndroidManifest.xml       (deja complet, ne pas fusionner, ECRASER)
#    - android/app/src/main/res/xml/network_security_config.xml  (nouveau fichier)
#    - android/app/src/main/res/values/styles.xml     (ECRASER)
#
#    Le AndroidManifest.xml fourni reference @drawable/launch_background
#    et @mipmap/ic_launcher : ces fichiers sont generes automatiquement
#    par `flutter create` a l'etape 1, ne les touchez pas.

# 3. Récupérer les dépendances :
flutter pub get

# 4. (Optionnel) logo : placez votre logo dans assets/logo.png
#    et affichez-le dans login_screen.dart à la place de l'icône.

# 5. minSdkVersion : ouvrez android/app/build.gradle et mettez
#    minSdkVersion 24 (minimum) ou 29 (= Android 10, recommande pour coller
#    a la demande "Compatible Android 10+").
```

## Lancer en debug
```bash
flutter run
```

## Construire l'APK
```bash
# APK debug (installable directement, non signé pour le Play Store) :
flutter build apk --debug
# -> build/app/outputs/flutter-apk/app-debug.apk

# APK release (recommandé, plus rapide). Signature debug par défaut ;
# pour une vraie clé, configurez android/key.properties :
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```
Transférez l'APK sur le téléphone et installez-le (autoriser les sources
inconnues).

## Configuration au premier lancement
- URL API : `https://monsite.com/ois-orders-api/`
- Utilisateur / mot de passe : ceux définis dans config.php de l'API.

## Notifications
- Notifications locales + polling background via WorkManager (toutes les
  15 min, minimum imposé par Android pour économiser la batterie).
- Chaque nouvelle commande n'est notifiée qu'une fois (`last_seen_order`
  stocké localement).
- Pour du temps réel, intégrez Firebase Cloud Messaging plus tard : le code
  est isolé dans `services/notification_service.dart`.

## Structure
```
lib/
  main.dart                  thème + démarrage
  services/
    api_service.dart         tous les appels réseau
    notification_service.dart notifications + polling
  screens/
    login_screen.dart
    dashboard_screen.dart
    orders_screen.dart       liste + filtres + infinite scroll
    order_detail_screen.dart détail + actions appel/WhatsApp/email
```
