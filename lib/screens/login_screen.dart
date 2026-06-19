import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _url = TextEditingController(
      text: ApiService.baseUrl.isEmpty ? 'https://' : ApiService.baseUrl);
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ApiService.login(_url.text, _user.text, _pass.text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        setState(() => _error = 'Identifiants ou URL incorrects.');
      }
    } catch (e) {
      setState(() => _error = 'Connexion impossible. Verifiez l\'URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OIS.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emplacement logo (assets/logo.png)
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: OIS.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.receipt_long,
                    color: OIS.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text('OIS Orders Mobile',
                  style: TextStyle(
                      color: OIS.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const Text('Online Ink Solutions',
                  style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 28),
              _field(_url, 'URL API', Icons.link),
              const SizedBox(height: 12),
              _field(_user, 'Utilisateur', Icons.person),
              const SizedBox(height: 12),
              _field(_pass, 'Mot de passe', Icons.lock, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: OIS.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Se connecter',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: OIS.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
