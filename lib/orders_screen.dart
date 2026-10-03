import 'package:flutter/material.dart';
import 'api.dart';
import 'login_screen.dart';
import 'main.dart';
import 'order_detail_screen.dart';
import 'util.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<Map<String, dynamic>> _f = Api.orders();

  Future<void> _refresh() async {
    setState(() { _f = Api.orders(); });
    await _f;
  }

  Future<void> _logout() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (c, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final d = snap.data!;
            if (d['error'] == true) {
              return Center(child: Text(sv(d['message']).isEmpty ? 'Login dobara karo' : sv(d['message'])));
            }
            final list = (d['data'] is List) ? List<Map<String, dynamic>>.from(
                (d['data'] as List).map((e) => Map<String, dynamic>.from(e))) : <Map<String, dynamic>>[];
            if (list.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Abhi koi order nahi hai')),
                ]),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: list.length,
                itemBuilder: (_, i) => _OrderCard(o: list[i]),
              ),
            );
          },
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> o;
  const _OrderCard({required this.o});

  @override
  Widget build(BuildContext context) {
    final pay = sv(o['payment_method']);
    final amount = sv(o['final_total'] ?? o['total_payable'] ?? o['total']);
    final status = sv(o['active_status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(o: o))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Order #${sv(o['order_id'])}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (pay.isNotEmpty) _Chip(pay, pay.toUpperCase() == 'COD' ? Colors.orange : kGreen),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(child: Text(sv(o['username']), style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(child: Text(sv(o['user_address']), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Text(sv(o['created_date']), style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const Spacer(),
              if (status.isNotEmpty) _Chip(status, kNavy),
              if (amount.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kGreen)),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String t;
  final Color c;
  const _Chip(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

