import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_personales/domain.dart';

void main() {
  test('Convierte dinero a centavos sin aritmética de punto flotante', () {
    expect(parseCents('12.35'), 1235);
    expect(parseCents('12,3'), 1230);
    expect(parseCents(' 0.01 '), 1);
    expect(parseCents('100'), 10000);
    expect(parseCents('0'), isNull);
    expect(parseCents('-5'), isNull);
    expect(parseCents('2.345'), isNull);
    expect(parseCents('1,000.00'), isNull);
    expect(parseCents('abc'), isNull);
    expect(money(-1235), '-\$12.35');
  });

  final items = [
    Movement(
        id: 0,
        type: 'ingreso',
        cents: 150000,
        category: 'Salario',
        date: DateTime(2026, 11, 1),
        note: ''),
    Movement(
        id: 1,
        type: 'gasto',
        cents: 8500,
        category: 'Alimentación',
        date: DateTime(2026, 11, 2),
        note: ''),
    Movement(
        id: 2,
        type: 'gasto',
        cents: 4000,
        category: 'Transporte',
        date: DateTime(2026, 11, 3),
        note: ''),
    Movement(
        id: 3,
        type: 'gasto',
        cents: 1000,
        category: 'Alimentación',
        date: DateTime(2025, 11, 2),
        note: ''),
    Movement(
        id: 4,
        type: 'gasto',
        cents: 3000,
        category: 'Transporte',
        date: DateTime(2026, 10, 31),
        note: ''),
  ];

  test('Filtra por año y mes, calcula balance y agrupa únicamente gastos', () {
    final month = inMonth(items, DateTime(2026, 11));
    expect(month.length, 3);
    expect(total(month, 'ingreso'), 150000);
    expect(total(month, 'gasto'), 12500);
    expect(total(month, 'ingreso') - total(month, 'gasto'), 137500);
    expect(
        expensesByCategory(month), {'Alimentación': 8500, 'Transporte': 4000});
    expect(expensesByCategory([]), isEmpty);
    expect(monthKey(DateTime(2026, 1, 1)), '2026-01');
  });

  test('El modelo conserva sus datos al convertirlo a mapa y recuperarlo', () {
    final original = items.first;
    final recovered = Movement.fromMap(0, original.toMap());
    expect(recovered.id, original.id);
    expect(recovered.toMap(), original.toMap());
  });
}