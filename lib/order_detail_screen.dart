import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'util.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> o;
  const OrderDetailScreen({super.key, required this.o});

  Future<void> _open(BuildContext c, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && c.mounted) _toast(c);
    } catch (_) {
      if (c.mounted) _toast(c);
    }
  }

  void _toast(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('Ye khul nahi paya')));

  @override
  Widget build(BuildContext context) {
    final mobile = sv(o['mobile']);
    final wa = mobile.length == 10 ? '91$mobile' : mobile;
    final lat = sv(o['latitude']);
    final lng = sv(o['longitude']);
    final addr = sv(o['user_address']);
    final mapUrl = (lat.isNotEmpty && lng.isNotEmpty)
        ? 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}';

    final safe = Map<String, dynamic>.from(o)..remove('otp');
    final pretty = const JsonEncoder.withIndent('  ').convert(safe);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        title: Text('Order #${sv(o['order_id'])}'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _Card(children: [
          _Row(Icons.person_outline, 'Customer', sv(o['username'])),
          _Row(Icons.phone_outlined, 'Mobile', mobile),
          _Row(Icons.location_on_outlined, 'Address', addr),
          _Row(Icons.payments_outlined, 'Payment', sv(o['payment_method'])),
          _Row(Icons.schedule, 'Time', sv(o['created_date'])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Btn(Icons.call, 'Call', () => _open(context, 'tel:$mobile'))),
          const SizedBox(width: 10),
          Expanded(child: _Btn(Icons.chat, 'WhatsApp', () => _open(context, 'https://wa.me/$wa'))),
          const SizedBox(width: 10),
          Expanded(child: _Btn(Icons.navigation, 'Map', () => _open(context, mapUrl))),
        ]),
        const SizedBox(height: 18),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('Raw data (OTP chhupa hua)'),
            children: [SelectableText(pretty, style: const TextStyle(fontSize: 12))],
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  final IconData i;
  final String k, v;
  const _Row(this.i, this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 20, color: kGreen),
          const SizedBox(width: 10),
          SizedBox(width: 78, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class _Btn extends StatelessWidget {
  final IconData i;
  final String t;
  final VoidCallback f;
  const _Btn(this.i, this.t, this.f);
  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: f,
        icon: Icon(i, size: 18),
        label: Text(t),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      );
}
