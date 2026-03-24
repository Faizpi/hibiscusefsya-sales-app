import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SearchableDropdownFormField<T> extends FormField<T> {
  SearchableDropdownFormField({
    super.key,
    required List<T> items,
    required String labelText,
    String? hintText,
    T? value,
    required String Function(T item) itemAsString,
    required ValueChanged<T?> onChanged,
    super.validator,
    Widget? leadingIcon,
    bool enabled = true,
  }) : super(
          initialValue: value,
          builder: (state) {
            final entries = items
                .map(
                  (item) => DropdownMenuEntry<T>(
                    value: item,
                    label: itemAsString(item),
                  ),
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final isDark = AppTheme.isDark(context);
                    final inputBorderColor = isDark
                        ? Colors.white.withAlpha(25)
                        : const Color(0xFFC7D9FF).withAlpha(150);
                    final menuBg = isDark
                        ? const Color(0xFF1A2538).withAlpha(224)
                        : const Color(0xFFF9FBFF).withAlpha(222);

                    return DropdownMenu<T>(
                      enabled: enabled,
                      width: double.infinity,
                      menuHeight: 320,
                      enableSearch: true,
                      enableFilter: true,
                      requestFocusOnTap: true,
                      initialSelection: state.value,
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
                    );
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
