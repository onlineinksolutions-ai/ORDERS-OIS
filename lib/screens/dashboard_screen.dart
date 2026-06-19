import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'orders_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  String _currency = 'DH';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ApiService.stats();
      setState(() {
        _stats = d['stats'] as Map<String, dynamic>;
        _currency = (d['currency'] ?? 'DH') as String;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Erreur : $_error'))
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _stat('Commandes aujourd\'hui',
                              "${_stats!['orders_today']}", OIS.red),
                          _stat('CA aujourd\'hui',
                              "${_stats!['revenue_today']} $_currency",
                              OIS.green),
                          _stat('En attente',
                              "${_stats!['orders_pending']}", OIS.black),
                          _stat('Commandes semaine',
                              "${_stats!['orders_week']}", OIS.red),
                          _stat('CA semaine',
                              "${_stats!['revenue_week']} $_currency",
                              OIS.green),
                          _stat('Panier moyen',
                              "${_stats!['avg_cart']} $_currency", OIS.black),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const OrdersScreen())),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Voir les commandes',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
