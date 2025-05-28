import 'package:flutter/material.dart';
import '../screens/camera_scan.dart';

class ScanButton extends StatelessWidget {
  final Function({bool? fromHistory}) onSend;
  final TextEditingController isbnController;

  const ScanButton({
    super.key,
    required this.onSend,
    required this.isbnController,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final String? barcodeResult = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const CameraScan()),
        );

        if (barcodeResult != null && barcodeResult.isNotEmpty) {
          isbnController.text = barcodeResult;
          onSend(fromHistory: false);
        }
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
