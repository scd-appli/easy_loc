import 'package:flutter/material.dart';

class CustomDropDownMenu extends StatelessWidget {
  const CustomDropDownMenu({
    super.key,
    required this.dropdownMenuEntries,
    required this.onSelected,
    required this.initialSelection,
  });

  final List<DropdownMenuEntry> dropdownMenuEntries;
  final ValueChanged<dynamic>? onSelected;
  final dynamic initialSelection;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      dropdownMenuEntries: dropdownMenuEntries,
      onSelected: onSelected,
      initialSelection: initialSelection,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.only(top: 0.0),
        ),
      ),
    );
  }
}
