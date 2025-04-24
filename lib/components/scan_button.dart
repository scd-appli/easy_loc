import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'snack_bar.dart';

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
  final l10n = AppLocalizations.of(context)!;

  try {
    var result = await BarcodeScanner.scan();

    // Handle the result
    switch (result.type) {
      // If Success
      case ResultType.Barcode:
        isbnController.text = result.rawContent;
        break;

      // If Cancelled
      case ResultType.Cancelled:
        showSnackBar(
          context,
          Text(
            l10n.scanCancelledUser, // Use variable
            style: TextStyle(color: Colors.black),
          ),
        );
        break;

      // If error
      case ResultType.Error:
        showSnackBar(
          context,
          Text(
            '${l10n.scanFailed}: ${result.rawContent}', // Use variable
            style: TextStyle(color: Colors.black),
          ),
        );
        break;
    }
  } on PlatformException catch (e) {
    if (e.code == BarcodeScanner.cameraAccessDenied) {
      // Handle permission denied
      showSnackBar(
        context,
        Text(
          l10n.cameraAccessDenied, // Use variable
          style: TextStyle(color: Colors.black),
        ),
      );
    } else {
      // Handle other potential platform exceptions
      showSnackBar(
        context,
        Text(
          '${l10n.unknowError}: $e', // Use variable
          style: TextStyle(color: Colors.black),
        ),
      );
    }
  } on FormatException {
    // Handle format exceptions (e.g., user pressed back button before scanning)
    showSnackBar(
      context,
      Text(
        l10n.scanCancelledBeforeData, // Use variable
        style: TextStyle(color: Colors.black),
      ),
    );
  } catch (e) {
    // Handle any other unexpected errors
    showSnackBar(
      context,
      Text(
        '${l10n.unexpectedError}: $e', // Use variable
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
