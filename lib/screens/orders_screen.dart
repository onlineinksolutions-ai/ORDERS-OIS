import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orders = <Map<String, dynamic>>[];
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  int _page = 1;
  int _pages = 1;
  bool _loading = false;

  Timer? _refreshTimer;
  String _lastOrderRef = '';
  bool _firstLoadDone = false;

  String _search = '';
  String? _dateFrom, _dateTo;
  bool _onlyNew = false;
  String _filterLabel = 'Tout';

  @override
  void initState() {
    super.initState();

    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 &&
          !_loading &&
          _page < _pages) {
        _page++;
        _fetch();
      }
    });

    _fetch();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetch(reset: true, silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false, bool silent = false}) async {
    if (_loading) return;

    if (reset) {
      _page = 1;
    }

    if (!silent) {
      setState(() => _loading = true);
    }

    try {
      final d = await ApiService.orders(
        page: _page,
        search: _search,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        onlyNew: _onlyNew,
      );

      final list = (d['orders'] as List).cast<Map<String, dynamic>>();
      _pages = (d['pagination']?['pages'] ?? 1) as int;

      if (reset && list.isNotEmpty) {
        final newRef = (list.first['reference'] ?? '').toString();

        if (_firstLoadDone && _lastOrderRef.isNotEmpty && newRef != _lastOrderRef) {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
          await NotificationService.show(
  '🔔 Nouvelle commande',
  '$newRef - $customer - $total $currency',
);

          if (mounted) {
            final customer = (list.first['customer'] ?? '').toString();
            final total = (list.first['total'] ?? '').toString();
            final currency = (list.first['currency'] ?? 'DH').toString();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔔 Nouvelle commande : $newRef - $customer - $total $currency'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        _lastOrderRef = newRef;
      }

      if (!_firstLoadDone && list.isNotEmpty) {
        _lastOrderRef = (list.first['reference'] ?? '').toString();
        _firstLoadDone = true;
      }

      if (!mounted) return;

      setState(() {
        if (reset) {
          _orders
            ..clear()
            ..addAll(list);
        } else {
          _orders.addAll(list);
        }
      });
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter(String label) {
    final now = DateTime.now();
    String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

    _dateFrom = null;
    _dateTo = null;
    _onlyNew = false;

    switch (label) {
      case 'Aujourd\'hui':
        _dateFrom = fmt(now);
        _dateTo = fmt(now);
        break;
      case 'Hier':
        final y = now.subtract(const Duration(days: 1));
        _dateFrom = fmt(y);
        _dateTo = fmt(y);
        break;
      case 'Cette semaine':
        _dateFrom = fmt(now.subtract(Duration(days: now.weekday - 1)));
        break;
      case 'Ce mois':
        _dateFrom = fmt(DateTime(now.year, now.month, 1));
        break;
      case 'En attente':
        _onlyNew = true;
        break;
    }

    setState(() => _filterLabel = label);
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      'Tout',
      'Aujourd\'hui',
      'Hier',
      'Cette semaine',
      'Ce mois',
      'En attente'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Reference, client, telephone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) {
                _search = v;
                _fetch(reset: true);
              },
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: filters.map((f) {
                final sel = f == _filterLabel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    selectedColor: OIS.red,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                    ),
                    onSelected: (_) => _applyFilter(f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetch(reset: true),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _orders.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= _orders.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _OrderCard(order: _orders[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  Color _color() {
    try {
      final hex = (order['status_color'] as String).replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    final total = (order['total'] ?? '').toString();
    final currency = (order['currency'] ?? '').toString();
    final city = (order['city'] ?? '').toString();
    final phone = (order['phone'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(id: order['id_order'] as int),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['reference'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '$total $currency',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: OIS.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(order['customer'] ?? '', style: const TextStyle(fontSize: 14)),
              Text(
                '$city  •  $phone',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['status_name'] ?? '',
                      style: TextStyle(
                        color: c,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      order['payment'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
