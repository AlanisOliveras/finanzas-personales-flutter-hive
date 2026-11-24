import 'package:flutter/material.dart';
import 'domain.dart';
import 'store.dart';

class MovementForm extends StatefulWidget {
  const MovementForm(
      {super.key, required this.store, this.item, required this.initialDate});

  final FinanceStore store;
  final Movement? item;
  final DateTime initialDate;

  @override
  State<MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends State<MovementForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController amount;
  late final TextEditingController note;
  late String type;
  late String category;
  late DateTime date;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    amount = TextEditingController(
        text: item == null
            ? ''
            : '${item.cents ~/ 100}.${(item.cents % 100).toString().padLeft(2, '0')}');
    note = TextEditingController(text: item?.note ?? '');
    type = item?.type ?? 'gasto';
    category = item?.category ?? widget.store.categories.first;
    date = item?.date ?? widget.initialDate;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.store.save(Movement(
        id: widget.item?.id,
        type: type,
        cents: parseCents(amount.text)!,
        category: category,
        date: date,
        note: note.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Intenta otra vez.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.item == null
              ? 'Nuevo movimiento'
              : 'Editar movimiento')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                ],
                onChanged: saving ? null : (v) => setState(() => type = v!),
              ),
              TextFormField(
                controller: amount,
                enabled: !saving,
                decoration: const InputDecoration(
                    labelText: 'Cantidad en USD',
                    helperText: 'Ejemplo: 125.50. Sin separadores de miles.'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => parseCents(v ?? '') == null
                    ? 'Escribe una cantidad positiva con hasta 2 decimales.'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: widget.store.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged:
                    saving ? null : (v) => setState(() => category = v!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(shortDate(date)),
                trailing: const Icon(Icons.calendar_month),
                onTap: saving
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (selected != null && mounted) {
                          setState(() => date = selected);
                        }
                      },
              ),
              TextFormField(
                controller: note,
                enabled: !saving,
                maxLength: 120,
                decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Guardando…' : 'Guardar')),
            ],
          )),
      );
}

