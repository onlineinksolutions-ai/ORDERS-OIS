OIS Orders Mobile - Version stable corrigee

Corrections faites:
- Suppression temporaire de workmanager et flutter_local_notifications pour supprimer le crash Android au demarrage.
- main.dart securise: aucun plugin natif au lancement.
- AndroidManifest.xml nettoye: aucun receiver WorkManager en conflit.
- CardThemeData corrige pour Flutter recent.
- GitHub Actions corrige: build APK + upload artifact app-release-apk.
- styles.xml simplifie pour eviter erreur launch_background.

Important:
Cette version privilegie l'ouverture de l'application, le login, dashboard, commandes, detail commande, WhatsApp/appel/email.
Les notifications background seront rajoutees apres validation que l'application ouvre correctement sur le telephone.

Etapes:
1. Supprimer tout l'ancien contenu du repo GitHub.
2. Uploader le contenu de ce ZIP.
3. Commit.
4. Actions > Build APK > Run workflow.
5. Telecharger l'artifact app-release-apk.
6. Desinstaller l'ancienne app du telephone.
7. Installer la nouvelle APK.
