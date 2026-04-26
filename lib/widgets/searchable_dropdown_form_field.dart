import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A searchable dropdown that can be updated programmatically (e.g. via scan).
///
/// Uses a [ValueKey] based on the selected value's identity so the underlying
/// [DropdownMenu] is properly rebuilt when the external [value] changes.
class SearchableDropdownFormField<T> extends StatelessWidget {
  final List<T> items;
  final String labelText;
  final String? hintText;
  final T? value;
  final String Function(T item) itemAsString;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final Widget? leadingIcon;
  final bool enabled;

  const SearchableDropdownFormField({
    super.key,
    required this.items,
    required this.labelText,
    this.hintText,
    this.value,
    required this.itemAsString,
    required this.onChanged,
    this.validator,
    this.leadingIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use a key based on the value identity so the DropdownMenu rebuilds
    // instantly when the value is changed programmatically (e.g. via scan).
    final dropdownKey = ValueKey<int?>(value?.hashCode);

    final entries = items
        .map(
          (item) => DropdownMenuEntry<T>(
            value: item,
            label: itemAsString(item),
          ),
        )
        .toList();

    final isDark = AppTheme.isDark(context);
    final inputBorderColor = isDark
        ? Colors.white.withAlpha(25)
        : const Color(0xFFC7D9FF).withAlpha(150);
    final menuBg = isDark
        ? const Color(0xFF1A2538).withAlpha(224)
        : const Color(0xFFF9FBFF).withAlpha(222);

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        // Keep FormField state in sync with external value
        if (state.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.didChange(value);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownMenu<T>(
              key: dropdownKey,
              enabled: enabled,
              width: double.infinity,
              menuHeight: 320,
              enableSearch: true,
              enableFilter: true,
              requestFocusOnTap: true,
              initialSelection: value,
              label: Text(labelText),
              hintText: hintText,
              leadingIcon: leadingIcon,
              dropdownMenuEntries: entries,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppTheme.glassInputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(menuBg),
                side: WidgetStatePropertyAll(
                  BorderSide(color: inputBorderColor),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                elevation: const WidgetStatePropertyAll(0),
              ),
              onSelected: (selected) {
                state.didChange(selected);
                onChanged(selected);
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
