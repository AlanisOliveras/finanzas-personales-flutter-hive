//lib/domain.dart
// Los importes se almacenan como centavos enteros: 12.35 -> 1235.

int? parseCents(String text) {
  final value = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final cents = int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents > 0 ? cents : null;
}

String money(int cents) {
  final absolute = cents.abs();
  return '${cents < 0 ? '-' : ''}\$${absolute ~/ 100}.'
      '${(absolute % 100).toString().padLeft(2, '0')}';
}

String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class Movement {
  const Movement({
    this.id,
    required this.type,
    required this.cents,
    required this.category,
    required this.date,
    required this.note,
  });

  final int? id;
  final String type; // ingreso o gasto
  final int cents;
  final String category;
  final DateTime date;
  final String note;

  Map<String, Object> toMap() => {
        'type': type,
        'cents': cents,
        'category': category,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'note': note,
      };

  factory Movement.fromMap(int id, Map<dynamic, dynamic> map) => Movement(
        id: id,
        type: map['type'] as String,
        cents: map['cents'] as int,
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String,
      );
}

List<Movement> inMonth(Iterable<Movement> items, DateTime month) => items
    .where((m) => m.date.year == month.year && m.date.month == month.month)
    .toList();

int total(Iterable<Movement> items, String type) =>
    items.where((m) => m.type == type).fold(0, (sum, m) => sum + m.cents);

Map<String, int> expensesByCategory(Iterable<Movement> items) {
  final result = <String, int>{};
  for (final item in items.where((m) => m.type == 'gasto')) {
    result.update(item.category, (value) => value + item.cents,
        ifAbsent: () => item.cents);
  }
  return result;
}