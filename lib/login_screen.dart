import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'orders_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _login() async {
    setState(() { _busy = true; _err = null; });
    try {
      final d = await Api.login(_mobile.text.trim(), _pass.text);
      if (d['error'] == false) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
      } else {
        setState(() => _err = d['message']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _err = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kNavy,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_shipping_rounded, color: kGreen, size: 64),
                const SizedBox(height: 12),
                const Text('GLC Delivery',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(children: [
                      const TabBar(tabs: [Tab(text: 'ID / Password'), Tab(text: 'OTP')]),
                      SizedBox(
                        height: 250,
                        child: TabBarView(children: [
                          Column(children: [
                            const SizedBox(height: 16),
                            TextField(
                                controller: _mobile,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 ')),
                            TextField(
                                controller: _pass,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password')),
                            if (_err != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_err!, style: const TextStyle(color: Colors.red))),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                  onPressed: _busy ? null : _login,
                                  child: _busy
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Login')),
                            ),
                          ]),
                          const Center(child: Text('OTP login jald aa raha hai')),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
