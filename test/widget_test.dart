import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finanzas_personales/main.dart';
import 'package:finanzas_personales/store.dart';

void main() {
  late Directory directory;
  late FinanceStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finanzas_ui_');
    Hive.init(directory.path);
    store = FinanceStore(
        await Hive.openBox('ui_movements'), await Hive.openBox('ui_settings'));
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('Registra un gasto y permite editarlo desde el historial',
      (tester) async {
    await tester.pumpWidget(FinanceApp(store: store));
    await tester.tap(find.byTooltip('Nuevo movimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cantidad en USD'), '85.00');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción (opcional)'), 'Compra');
    await tester.runAsync(() async {
      final changed = store.movements.watch().first;
      await tester.tap(find.text('Guardar'));
      await changed;
      await store.movements.flush();
    });
    await tester.pumpAndSettle();
    expect(store.all.single.cents, 8500);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimentación · \$85.00'));
    await tester.pumpAndSettle();
    expect(find.text('Editar movimiento'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cantidad en USD'), '90.00');
    await tester.runAsync(() async {
      final changed = store.movements.watch().first;
      await tester.tap(find.text('Guardar'));
      await changed;
      await store.movements.flush();
    });
    await tester.pumpAndSettle();
    expect(store.all.single.cents, 9000);
    expect(store.all.length, 1);
    await tester.pumpWidget(const SizedBox());
  });
}