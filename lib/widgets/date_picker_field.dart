import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool readOnly;
  final String? Function(DateTime?)? validator;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.readOnly = false,
    this.validator,
  });

  static final _displayFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
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
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
      validator: validator != null ? (_) => validator!(selectedDate) : null,
    );
  }
}
