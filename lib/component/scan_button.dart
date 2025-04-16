import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ScanButton extends StatelessWidget {
  final VoidCallback onSend;
  final TextEditingController isbnController;

  const ScanButton({
    super.key,
    required this.onSend,
    required this.isbnController,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        scan(context, isbnController);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          Theme.of(context).primaryColor,
        ),
        iconSize: const WidgetStatePropertyAll(30),
        fixedSize: WidgetStateProperty.all(const Size(60, 60)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        ),
      ),
      child: const Icon(Icons.qr_code_scanner, color: Colors.black),
    );
  }
}

void scan(BuildContext context, TextEditingController isbnController) async {
  try {
    var result = await BarcodeScanner.scan();

    // Check if the widget is still mounted before using the context
    if (!context.mounted) return;

    // Handle the result
    switch (result.type) {
      // If Success
      case ResultType.Barcode:
        isbnController.text = result.rawContent;
        break;

      // If Cancelled
      case ResultType.Cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scanCancelledUser),
          ),
        );
        break;

      // If error
      case ResultType.Error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.scanFailed}: ${result.rawContent}',
            ),
          ),
        );
        break;
    }
  } on PlatformException catch (e) {
    if (e.code == BarcodeScanner.cameraAccessDenied) {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cameraAccessDenied),
        ),
      );
    } else {
      // Handle other potential platform exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.unknowError}: $e'),
        ),
      );
    }
  } on FormatException {
    // Handle format exceptions (e.g., user pressed back button before scanning)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.scanCancelledBeforeData),
      ),
    );
  } catch (e) {
    // Handle any other unexpected errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.unexpectedError}: $e'),
      ),
    );
  }
}
