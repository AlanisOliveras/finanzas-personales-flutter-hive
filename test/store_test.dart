import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finanzas_personales/domain.dart';
import 'package:finanzas_personales/store.dart';

void main() {
  late Directory directory;
  late FinanceStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finanzas_test_');
    Hive.init(directory.path);
    store = FinanceStore(
        await Hive.openBox('movements'), await Hive.openBox('settings'));
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('CRUD y persistencia después de cerrar y volver a abrir Hive', () async {
    await store.save(Movement(
        type: 'gasto',
        cents: 8500,
        category: 'Alimentación',
        date: DateTime(2026, 11, 2),
        note: 'Compra'));
    final id = store.all.single.id!;
    await store.save(Movement(
        id: id,
        type: 'gasto',
        cents: 9000,
        category: 'Alimentación',
        date: DateTime(2026, 11, 2),
        note: 'Editada'));
    await store.addCategory('Mascotas');
    await store.saveBudget(DateTime(2026, 11), 60000);
    await Hive.close();
    store = FinanceStore(
        await Hive.openBox('movements'), await Hive.openBox('settings'));
    expect(store.all.single.cents, 9000);
    expect(store.all.single.id, id);
    expect(store.categories, contains('Mascotas'));
    expect(store.budget(DateTime(2026, 11)), 60000);
    expect(store.budget(DateTime(2026, 12)), 0);
    await store.delete(id);
    await store.removeBudget(DateTime(2026, 11));
    expect(store.all, isEmpty);
    expect(store.budget(DateTime(2026, 11)), 0);
  });

  test('Rechaza categorías duplicadas y el nombre reservado', () async {
    await expectLater(store.addCategory(' alimentación '), throwsArgumentError);
    await expectLater(store.addCategory('Todas'), throwsArgumentError);
    await expectLater(store.addCategory(''), throwsArgumentError);
  });
}