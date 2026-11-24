// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    final movements = await Hive.openBox<dynamic>('movements_v1');
    final settings = await Hive.openBox<dynamic>('settings_v1');
    runApp(FinanceApp(store: FinanceStore(movements, settings)));
  } catch (_) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudieron abrir los datos locales. '
              'Cierra y vuelve a abrir la aplicación.',
            ),
          ),
        ),
      ),
    ));
  }
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key, required this.store});

  final FinanceStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mis finanzas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: HomePage(store: store),
      );
}