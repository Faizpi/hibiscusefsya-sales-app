import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool readOnly;
  final String? Function(DateTime?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.readOnly = false,
    this.validator,
    this.firstDate,
    this.lastDate,
  });

  static final _displayFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final effectiveFirstDate = firstDate ?? DateTime(2026);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: selectedDate != null ? _displayFormat.format(selectedDate!) : '',
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: readOnly
            ? null
            : const Icon(Icons.calendar_today, size: 20),
      ),
      onTap: readOnly
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: effectiveFirstDate,
                lastDate: effectiveLastDate,
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
      validator: validator != null ? (_) => validator!(selectedDate) : null,
    );
  }
}
