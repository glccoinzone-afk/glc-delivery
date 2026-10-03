import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'login_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<Map<String, dynamic>> _f = Api.orders();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Orders'), actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Api.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              })
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final pretty = const JsonEncoder.withIndent('  ').convert(s.data);
            return RefreshIndicator(
              onRefresh: () async => setState(() => _f = Api.orders()),
              child: ListView(padding: const EdgeInsets.all(12), children: [SelectableText(pretty)]),
            );
          },
        ),
      );
}
