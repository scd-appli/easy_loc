import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../functions/utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IsbnInputForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isValid;
  final String? noDataMessage;
  final ValueChanged<String> onChanged;
  final Function({bool? fromHistory}) onSend;
  final double? padding;

  const IsbnInputForm({
    super.key,
    required this.controller,
    required this.isValid,
    this.noDataMessage,
    required this.onChanged,
    required this.onSend,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // ValueListenableBuilder to rebuild suffixIcon when controller text changes
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Padding(
          padding:
              padding != null
                  ? EdgeInsets.only(top: padding!, bottom: padding!)
                  : EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "ISBN",
                      errorText: isValid ? null : l10n.invalidInput,
                      suffixIcon:
                          value.text.isNotEmpty
                              ? IconButton(
                                onPressed: () => onSend(fromHistory: false),
                                icon: const Icon(Icons.send),
                              )
                              : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-Xx]')),
                      IsISBN(),
                    ],
                    onSubmitted: (_) => onSend(fromHistory: false),
                  ),
                  if (noDataMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        noDataMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
