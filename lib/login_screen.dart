import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'main.dart';
import 'orders_screen.dart';
import 'util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _err;

  Future<void> _login() async {
    final m = _mobile.text.trim();
    if (m.length != 10) {
      setState(() => _err = '10 digit ka mobile number daalo');
      return;
    }
    if (_pass.text.isEmpty) {
      setState(() => _err = 'Password daalo');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final d = await Api.login(m, _pass.text);
      if (d['error'] == false) {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
        return;
      }
      final key = sv(d['language_message_key']);
      setState(() {
        if (key == 'invalid_credentials') {
          _err = 'Mobile number ya password galat hai.\nYe app sirf admin dwara approved delivery partners ke liye hai.';
        } else {
          _err = sv(d['message']).isEmpty ? 'Login nahi ho paya' : sv(d['message']);
        }
      });
    } on DioException {
      setState(() => _err = 'Internet check karo aur dobara try karo');
    } catch (_) {
      setState(() => _err = 'Kuch galat ho gaya, dobara try karo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kNavy, Color(0xFF0F3D2E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: kGreen, size: 56),
                  ),
                  const SizedBox(height: 16),
                  const Text('GLC Delivery',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Delivery Partner App',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Mobile number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          prefixText: '+91  ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pass,
                        obscureText: _hide,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _busy ? null : _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (_err != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : _login,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Text('Account nahi hai? Admin se sampark karo.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
      );
}
