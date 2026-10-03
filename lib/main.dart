import 'package:flutter/material.dart';
import 'api.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

const kGreen = Color(0xFF219154);
const kNavy = Color(0xFF0B1B2B);

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GLC Delivery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
          scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        ),
        home: FutureBuilder<bool>(
          future: Api.hasToken(),
          builder: (c, s) => s.connectionState != ConnectionState.done
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : (s.data == true ? const OrdersScreen() : const LoginScreen()),
        ),
      );
}
