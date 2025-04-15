import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart' show PlatformException;

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

    // Check if the user cancelled the scan
    if (result.type == ResultType.Barcode) {
      isbnController.text = result.rawContent;
    } else if (result.type == ResultType.Cancelled) {
      // Handle cancellation, e.g., show a message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan cancelled by user.')));
    } else if (result.type == ResultType.Error) {
      // Handle other errors reported by the scanner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: ${result.rawContent}')),
      );
    }
  } on PlatformException catch (e) {
    if (e.code == BarcodeScanner.cameraAccessDenied) {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera permission was denied. Please grant permission in app settings.',
          ),
        ),
      );
    } else {
      // Handle other potential platform exceptions
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An unknown error occurred: $e')));
    }
  } on FormatException {
    // Handle format exceptions (e.g., user pressed back button before scanning)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan cancelled before capturing data.')),
    );
  } catch (e) {
    // Handle any other unexpected errors
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
  }
}
