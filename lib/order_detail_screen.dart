import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'main.dart';
import 'orders_screen.dart';
import 'util.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> o;
  const OrderDetailScreen({super.key, required this.o});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _busy = false;
  Map<String, dynamic> get o => widget.o;
  int get _pid => int.tryParse(sv(o['id'])) ?? 0;
  String get _status => sv(o['active_status']).toLowerCase();

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _open(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) _msg('Ye khul nahi paya');
    } catch (_) {
      if (mounted) _msg('Ye khul nahi paya');
    }
  }

  Future<String?> _ask(String title, String label, {bool number = false}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool> _confirm(String t) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Haan')),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() call) async {
    setState(() => _busy = true);
    try {
      final d = await call();
      if (!mounted) return;
      _msg(sv(d['message']).isEmpty ? 'Done' : sv(d['message']));
      if (d['error'] == false) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OrdersScreen()), (r) => false);
        return;
      }
    } catch (e) {
      if (mounted) _msg('Network error: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickup() async {
    if (!await _confirm('Order pickup ho gaya?')) return;
    await _run(() => Api.updateStatus(_pid, 'shipped'));
  }

  Future<void> _deliver() async {
    final otp = await _ask('Customer se OTP lo', 'Delivery OTP', number: true);
    if (otp == null || otp.isEmpty) return;
    await _run(() => Api.updateStatus(_pid, 'delivered', otp: otp));
  }

  Future<void> _fail() async {
    final r = await _ask('Delivery fail kyun hui?', 'Reason');
    if (r == null || r.isEmpty) return;
    await _run(() => Api.failed(_pid, r));
  }

  Future<void> _respond(String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await _ask('Reject ka reason', 'Reason');
      if (reason == null || reason.isEmpty) return;
    } else if (!await _confirm('Ye order accept karna hai?')) {
      return;
    }
    await _run(() => Api.respond(_pid, action, reason: reason));
  }

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

    final isCod = sv(o['payment_method']).toUpperCase() == 'COD';
    final cashPending = isCod && sv(o['is_cod_collected']) == '0';
    final items = o['items'] is List ? (o['items'] as List).length : 0;
    final done = ['delivered', 'cancelled', 'returned'].contains(_status);
    final beforePickup = ['packed', 'received', 'processed'].contains(_status);

    final safe = Map<String, dynamic>.from(o)..remove('otp');
    final pretty = const JsonEncoder.withIndent('  ').convert(safe);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        title: Text('Order #${sv(o['order_id'])}'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (cashPending)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.payments, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Customer se ${sv(o['final_total'])} cash collect karna hai',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
        _Card(children: [
          _Row(Icons.flag_outlined, 'Status', sv(o['active_status'])),
          _Row(Icons.person_outline, 'Customer', sv(o['username'])),
          _Row(Icons.phone_outlined, 'Mobile', mobile),
          _Row(Icons.location_on_outlined, 'Address', addr),
          _Row(Icons.schedule, 'Slot', '${sv(o['delivery_date'])}  ${sv(o['delivery_time'])}'),
          _Row(Icons.shopping_bag_outlined, 'Items', '$items'),
          _Row(Icons.payments_outlined, 'Payment', '${sv(o['payment_method'])}  ${sv(o['final_total'])}'),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Btn(Icons.call, 'Call', () => _open('tel:$mobile'))),
          const SizedBox(width: 10),
          Expanded(child: _Btn(Icons.chat, 'WhatsApp', () => _open('https://wa.me/$wa'))),
          const SizedBox(width: 10),
          Expanded(child: _Btn(Icons.navigation, 'Map', () => _open(mapUrl))),
        ]),
        if (!done) ...[
          const SizedBox(height: 22),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (!_busy && beforePickup) ...[
            Row(children: [
              Expanded(child: _Btn(Icons.check, 'Accept', () => _respond('accept'))),
              const SizedBox(width: 10),
              Expanded(child: _Btn(Icons.close, 'Reject', () => _respond('reject'), danger: true)),
            ]),
            const SizedBox(height: 10),
            _Btn(Icons.inventory_2, 'Pickup ho gaya', _pickup),
          ],
          if (!_busy && _status == 'shipped') _Btn(Icons.verified, 'Delivered (OTP)', _deliver),
          if (!_busy) ...[
            const SizedBox(height: 10),
            _Btn(Icons.report_problem, 'Delivery failed', _fail, danger: true),
          ],
        ],
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
  final bool danger;
  const _Btn(this.i, this.t, this.f, {this.danger = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: f,
          icon: Icon(i, size: 18),
          label: Text(t),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: danger ? Colors.red.shade600 : null,
          ),
        ),
      );
}
