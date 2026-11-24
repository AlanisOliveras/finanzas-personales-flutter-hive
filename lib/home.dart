import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'domain.dart';
import 'movement_form.dart';
import 'store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});

  final FinanceStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int tab = 0;
  String query = '';
  String type = 'todos';
  String category = 'Todas';
  FinanceStore get store => widget.store;

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        message('No se pudo completar la operación. Intenta otra vez.');
      }
    }
  }

  Future<void> edit([Movement? item]) async {
    final now = DateTime.now();
    await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => MovementForm(
              store: store,
              item: item,
              initialDate: monthKey(now) == monthKey(month) ? now : month),
        ));
  }

  Future<void> delete(Movement item) async {
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('¿Eliminar movimiento?'),
              content: Text('${item.category}: ${money(item.cents)}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar')),
              ],
            ));
    if (accepted == true) await perform(() => store.delete(item.id!));
  }

  Future<void> addCategory() async {
    final name = await showDialog<String>(
        context: context,
        builder: (context) => const _ValueDialog(
            title: 'Nueva categoría', label: 'Nombre (1–40 caracteres)'));
    if (name == null || !mounted) return;
    try {
      await store.addCategory(name);
      if (mounted) message('Categoría añadida.');
    } on ArgumentError catch (error) {
      if (mounted) message(error.message.toString());
    } catch (_) {
      if (mounted) message('No se pudo guardar la categoría.');
    }
  }

  Future<void> setBudget() async {
    final selectedMonth = month;
    final value = await showDialog<String>(
        context: context,
        builder: (context) => const _ValueDialog(
            title: 'Presupuesto mensual',
            label: 'Cantidad en USD',
            numeric: true));
    if (value == null || !mounted) return;
    final cents = parseCents(value);
    if (cents == null) {
      message('Usa una cantidad positiva con hasta 2 decimales.');
      return;
    }
    await perform(() => store.saveBudget(selectedMonth, cents));
  }

  Widget metric(String label, int cents) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Text(money(cents),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ));

  Widget movementTile(Movement m) => Card(
        child: ListTile(
          leading:
              Icon(m.type == 'ingreso' ? Icons.south_west : Icons.north_east),
          title: Text('${m.category} · ${money(m.cents)}'),
          subtitle: Text('${m.type} · ${shortDate(m.date)}'
              '${m.note.isEmpty ? '' : '\n${m.note}'}'),
          isThreeLine: m.note.isNotEmpty,
          onTap: () => edit(m),
          trailing: IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => delete(m)),
        ));

  Widget summary(List<Movement> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Totales del mes seleccionado'),
          metric('Ingresos', total(items, 'ingreso')),
          metric('Gastos', total(items, 'gasto')),
          metric('Balance del mes',
              total(items, 'ingreso') - total(items, 'gasto')),
          const Padding(
              padding: EdgeInsets.all(8), child: Text('Últimos movimientos')),
          if (items.isEmpty)
            const Text('Todavía no hay movimientos en este mes.'),
          ...items.take(5).map(movementTile),
        ],
      );

  Widget history(List<Movement> items) {
    final filtered = items
        .where((m) =>
            (type == 'todos' || m.type == type) &&
            (category == 'Todas' || m.category == category) &&
            '${m.note} ${m.category}'
                .toLowerCase()
                .contains(query.toLowerCase().trim()))
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        decoration: const InputDecoration(
            labelText: 'Buscar descripción o categoría',
            prefixIcon: Icon(Icons.search)),
        onChanged: (v) => setState(() => query = v),
      ),
      DropdownButton<String>(
        value: type,
        isExpanded: true,
        items: ['todos', 'ingreso', 'gasto']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => setState(() => type = v!),
      ),
      DropdownButton<String>(
        value: category,
        isExpanded: true,
        items: ['Todas', ...store.categories]
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => setState(() => category = v!),
      ),
      Text('${filtered.length} movimiento(s). Toca uno para editar.'),
      if (filtered.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay movimientos que coincidan con los filtros.')),
      ...filtered.map(movementTile),
    ]);
  }

  Widget budget(List<Movement> items) {
    final limit = store.budget(month);
    final spent = total(items, 'gasto');
    final remaining = limit - spent;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Presupuesto general del mes seleccionado'),
      if (limit == 0)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no has definido un presupuesto para este mes.')),
      if (limit > 0) ...[
        metric('Límite', limit),
        metric('Gastado', spent),
        metric(remaining < 0 ? 'Exceso' : 'Disponible', remaining.abs()),
        LinearProgressIndicator(value: (spent / limit).clamp(0.0, 1.0)),
        Text('Usado: ${(100 * spent / limit).toStringAsFixed(1)}%'),
        if (remaining < 0) const Text('Has superado el presupuesto.'),
      ],
      FilledButton(
          onPressed: setBudget,
          child:
              Text(limit == 0 ? 'Definir presupuesto' : 'Cambiar presupuesto')),
      if (limit > 0)
        TextButton(
          onPressed: () => perform(() => store.removeBudget(month)),
          child: const Text('Quitar presupuesto'),
        ),
    ]);
  }

  Widget reports(List<Movement> items) {
    final groups = expensesByCategory(items).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final spent = total(items, 'gasto');
    final previousMonth = DateTime(month.year, month.month - 1);
    final previousSpent = total(inMonth(store.all, previousMonth), 'gasto');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Distribución de gastos del mes'),
      if (groups.isEmpty)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Registra un gasto para ver la gráfica.')),
      ...groups.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${entry.key}: ${money(entry.value)} '
                      '(${(entry.value / spent * 100).toStringAsFixed(1)}%)'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                      value: entry.value / spent, minHeight: 14),
                ]),
          )),
      const Divider(),
      metric('Gastos ${monthKey(month)}', spent),
      metric('Gastos ${monthKey(previousMonth)}', previousSpent),
      metric('Diferencia respecto al mes anterior', spent - previousSpent),
      const Text('Una diferencia negativa indica que gastaste menos.'),
    ]);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([
          store.movements.listenable(),
          store.settings.listenable(),
        ]),
        builder: (context, _) {
          final items = inMonth(store.all, month);
          return Scaffold(
            appBar: AppBar(title: const Text('Mis finanzas'), actions: [
              IconButton(
                  onPressed: addCategory,
                  tooltip: 'Añadir categoría',
                  icon: const Icon(Icons.create_new_folder_outlined)),
            ]),
            body: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    tooltip: 'Mes anterior',
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month - 1)),
                    icon: const Icon(Icons.chevron_left)),
                Text(monthKey(month),
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    tooltip: 'Mes siguiente',
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month + 1)),
                    icon: const Icon(Icons.chevron_right)),
              ]),
              Expanded(
                  child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  switch (tab) {
                    0 => summary(items),
                    1 => history(items),
                    2 => budget(items),
                    _ => reports(items),
                  }
                ],
              )),
            ]),
            floatingActionButton: FloatingActionButton(
                tooltip: 'Nuevo movimiento',
                onPressed: edit,
                child: const Icon(Icons.add)),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (v) => setState(() => tab = v),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Inicio'),
                NavigationDestination(
                    icon: Icon(Icons.list), label: 'Historial'),
                NavigationDestination(
                    icon: Icon(Icons.savings_outlined), label: 'Presupuesto'),
                NavigationDestination(
                    icon: Icon(Icons.bar_chart), label: 'Reportes'),
              ],
            ),
          );
        },
      );
}

class _ValueDialog extends StatefulWidget {
  const _ValueDialog(
      {required this.title, required this.label, this.numeric = false});

  final String title;
  final String label;
  final bool numeric;

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          autofocus: true,
          controller: controller,
          decoration: InputDecoration(labelText: widget.label),
          keyboardType: widget.numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Aceptar')),
        ],
      );
}