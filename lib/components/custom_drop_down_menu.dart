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
    );
  }
}
