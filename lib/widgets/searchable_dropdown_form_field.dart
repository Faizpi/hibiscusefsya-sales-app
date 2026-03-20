import 'package:flutter/material.dart';

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
                DropdownMenu<T>(
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
