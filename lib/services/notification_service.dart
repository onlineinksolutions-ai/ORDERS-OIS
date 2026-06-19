import 'api_service.dart';

/// Version stable sans plugins natifs.
/// Les notifications background ont ete desactivees pour eviter le crash au demarrage.
/// L'application fonctionne normalement: login, dashboard, commandes, details, WhatsApp/appel/email.
class NotificationService {
  static Future<void> init() async {}

  static Future<void> registerBackgroundPolling() async {}

  static Future<void> show(String title, String body) async {}

  static Future<int> getLastSeen() async {
    return 0;
  }

  static Future<void> setLastSeen(int id) async {}

  static Future<void> checkNow() async {
    await ApiService.load();
    if (!ApiService.isLoggedIn) return;
  }
}
