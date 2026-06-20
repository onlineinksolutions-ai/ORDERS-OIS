import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../main.dart';

class OrderDetailScreen extends StatefulWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiService.orderDetail(widget.id);
      setState(() => _order = d['order'] as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Tente d'ouvrir une URI externe (tel/wa.me/mailto). Affiche un message
  /// si aucune application ne peut gerer le lien (au lieu de rien faire).
  Future<void> _launch(Uri uri, {String? failMessage}) async {
    try {
      final can = await canLaunchUrl(uri);
      if (can) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // ignore et tombe sur le message d'echec ci-dessous
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failMessage ?? 'Impossible d\'ouvrir cette action.')));
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copie')));
  }

  /// Nettoie un numero (garde chiffres et +) pour l'appel telephonique.
  String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  /// Convertit un numero marocain local (06.../07...) vers le format
  /// international +2126.../+2127... requis par wa.me. Si le numero est
  /// deja en +212 ou dans un autre format international, on le laisse tel
  /// quel (on retire juste les espaces/tirets).
  String _whatsappNumber(String phone) {
    var d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('0') && (d.length == 10) &&
        (d.startsWith('06') || d.startsWith('07'))) {
      d = '+212${d.substring(1)}';
    } else if (d.startsWith('00212')) {
      d = '+212${d.substring(5)}';
    } else if (d.startsWith('212') && !d.startsWith('+')) {
      d = '+$d';
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.id}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur : $_error'))
              : _content(),
    );
  }

  Widget _content() {
    final o = _order!;
    final cust = o['customer'] as Map<String, dynamic>;
    final addr = o['shipping_address'] as Map<String, dynamic>;
    final totals = o['totals'] as Map<String, dynamic>;
    final products = (o['products'] as List).cast<Map<String, dynamic>>();
    final history = (o['history'] as List).cast<Map<String, dynamic>>();
    final messages = (o['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final cur = o['currency'] ?? 'DH';
    final phone = cust['phone'] as String? ?? '';
    final ref = o['reference'] as String? ?? '';
    final custName = (cust['name'] ?? '').toString();
    final custEmail = (cust['email'] ?? '').toString();
    final addr1 = (addr['address1'] ?? '').toString();
    final addr2 = (addr['address2'] ?? '').toString();
    final postcode = (addr['postcode'] ?? '').toString();
    final city = (addr['city'] ?? '').toString();
    final tProducts = (totals['products'] ?? '').toString();
    final tShipping = (totals['shipping'] ?? '').toString();
    final tTotal = (totals['total'] ?? '').toString();
    final waMsg = Uri.encodeComponent(
        'Bonjour $custName, nous vous contactons concernant votre commande $ref chez Online Ink Solutions.');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tete
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(ref,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(
                        onPressed: () => _copy(ref, 'Reference'),
                        icon: const Icon(Icons.copy, size: 20)),
                  ],
                ),
                Text(o['status_name'] ?? '',
                    style: const TextStyle(
                        color: OIS.red, fontWeight: FontWeight.w600)),
                Text(o['date_add'] ?? '',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        // Actions rapides
        Row(
          children: [
            _action(
                Icons.phone,
                'Appeler',
                OIS.green,
                phone.isEmpty
                    ? null
                    : () => _launch(Uri.parse('tel:${_digits(phone)}'),
                        failMessage:
                            'Impossible de lancer l\'appel sur cet appareil.')),
            const SizedBox(width: 8),
            _action(
                Icons.chat,
                'WhatsApp',
                const Color(0xFF25D366),
                phone.isEmpty
                    ? null
                    : () => _launch(
                        Uri.parse(
                            'https://wa.me/${_whatsappNumber(phone)}?text=$waMsg'),
                        failMessage:
                            'Impossible d\'ouvrir WhatsApp pour ce numero.')),
            const SizedBox(width: 8),
            _action(
                Icons.email,
                'Email',
                OIS.black,
                custEmail.isEmpty
                    ? null
                    : () => _launch(Uri.parse('mailto:$custEmail'),
                        failMessage:
                            'Aucune application email configuree sur cet appareil.')),
          ],
        ),
        const SizedBox(height: 16),
        _section('Client', [
          _row('Nom', custName),
          _rowCopy('Telephone', phone),
          _row('Email', custEmail),
        ]),
        _section('Livraison', [
          _row('Destinataire', addr['name'] ?? ''),
          _rowCopy('Adresse', '$addr1 $addr2\n$postcode $city'),
          _row('Transporteur', o['carrier'] ?? ''),
        ]),
        _section('Produits',
            products.map((p) => _productRow(p, cur)).toList()),
        _section('Totaux', [
          _row('Produits', '$tProducts $cur'),
          _row('Livraison', '$tShipping $cur'),
          _row('Total TTC', '$tTotal $cur', bold: true),
          _row('Paiement', o['payment'] ?? ''),
        ]),
        if (history.isNotEmpty)
          _section('Historique',
              history.map((h) => _row(h['date'] ?? '', h['name'] ?? '')).toList()),
        if (messages.isNotEmpty)
          _section('Messages client',
              messages.map((m) => _row(m['date'] ?? '', m['message'] ?? '')).toList()),
      ],
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: onTap == null ? Colors.grey : color),
          onPressed: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: OIS.red)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _rowCopy(String label, String value) {
    return InkWell(
      onTap: () => _copy(value, label),
      child: Row(
        children: [
          Expanded(child: _row(label, value)),
          const Icon(Icons.copy, size: 16, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _productRow(Map<String, dynamic> p, String cur) {
  final name = (p['name'] ?? '').toString();
  final ref = (p['reference'] ?? '').toString();
  final qty = (p['quantity'] ?? '').toString();
  final total = (p['total'] ?? '').toString();
  final imageUrl = (p['image_url'] ?? '').toString();

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isEmpty
              ? Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(Icons.image_not_supported, size: 24),
                )
              : Image.network(
                  imageUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 58,
                    height: 58,
                    color: const Color(0xFFF1F1F1),
                    child: const Icon(Icons.image_not_supported, size: 24),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(
                'Ref: $ref  x$qty',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$total $cur', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
}
