// lib/store.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'domain.dart';

class FinanceStore {
  FinanceStore(this.movements, this.settings);

  final Box<dynamic> movements;
  final Box<dynamic> settings;

  List<Movement> get all => movements.keys
      .map((key) => Movement.fromMap(key as int, movements.get(key) as Map))
      .toList()
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id!.compareTo(a.id!);
    });

  List<String> get categories => List<String>.from(settings.get('categories',
          defaultValue: <String>[
            'Alimentación',
            'Transporte',
            'Vivienda',
            'Salud',
            'Entretenimiento',
            'Salario',
            'Otros',
          ]) as List);

  Future<void> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 40) {
      throw ArgumentError('Usa entre 1 y 40 caracteres.');
    }
    final current = categories;
    if (clean.toLowerCase() == 'todas') {
      throw ArgumentError('Todas es un nombre reservado para los filtros.');
    }
    if (current.any((c) => c.toLowerCase() == clean.toLowerCase())) {
      throw ArgumentError('La categoría ya existe.');
    }
    await settings.put('categories', [...current, clean]);
  }

  Future<void> save(Movement item) async {
    if (!['ingreso', 'gasto'].contains(item.type) ||
        item.cents <= 0 ||
        !categories.contains(item.category)) {
      throw ArgumentError('Movimiento inválido.');
    }
    if (item.id == null) {
      await movements.add(item.toMap());
    } else {
      await movements.put(item.id, item.toMap());
    }
  }

  Future<void> delete(int id) => movements.delete(id);

  int budget(DateTime month) =>
      settings.get('budget:${monthKey(month)}', defaultValue: 0) as int;

  Future<void> saveBudget(DateTime month, int cents) async {
    if (cents <= 0) throw ArgumentError('El presupuesto debe ser positivo.');
    await settings.put('budget:${monthKey(month)}', cents);
  }

  Future<void> removeBudget(DateTime month) =>
      settings.delete('budget:${monthKey(month)}');
}