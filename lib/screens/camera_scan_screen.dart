import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../components/snack_bar.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter/services.dart';
import '../functions/utils.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.ean13, BarcodeFormat.unknown],
  );
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  bool _canProcess = true;
  Timer? _processingDelayTimer;
  bool _isCameraInitialized = false; // Track initialization state
  String? _initializationError; // Store initialization error message

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> search(RecognizedText recognizedText) async {
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String currentLineText = line.text;
        String? value;

        for (List format in acceptedSearch) {
          RegExpMatch? match = format[0].firstMatch(currentLineText);
          if (match != null) {
            String potential = match.group(0)!;
            if (format[1](potential)) {
              value = potential;
            }
          }

          if (value != null) {
            await _stopImageStream();
            if (mounted) {
              Navigator.pop(context, value);
            }
            return;
          }
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Reset error state on retry
    if (mounted) {
      setState(() {
        _initializationError = null;
        _isCameraInitialized = false;
      });
    }

    try {
      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('NoCameraAvailable', 'No cameras available.');
      }

      // Select the back camera
      CameraDescription selectedCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first, // Fallback to the first camera
      );

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        // yuv420 format which is more widely supported
        imageFormatGroup:
            defaultTargetPlatform == TargetPlatform.iOS
                ? ImageFormatGroup.bgra8888
                : ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Set auto focus mode after initialization
      await _controller!.setFocusMode(FocusMode.auto).catchError((e) {
        debugPrint("Error setting focus mode: $e");
      });

      await _controller!.startImageStream(_processCameraImage);

      // Update UI only on successful initialization
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      _handleCameraException(e);
      setState(() {
        // Store error message for UI
        _initializationError = _getCameraErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      final errorMessage = 'Failed to initialize camera: ${e.toString()}';
      _showErrorSnackBar(errorMessage);
      setState(() {
        // Store error message for UI
        _initializationError = errorMessage;
      });
    }
  }

  Future<void> _stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_canProcess || _isProcessing || !mounted || !_isCameraInitialized) {
      return;
    }

    _isProcessing = true; // Mark as processing for this entire frame attempt
    _canProcess = false; // Prevent next frame from processing immediately

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      debugPrint("_inputImageFromCameraImage returned null. Skipping frame.");
      if (mounted) {
        // Check mounted before resetting state
        _isProcessing = false;
        _resetProcessingDelay();
      }
      return;
    }

    try {
      // 1. Try Barcode Scanning
      final List<Barcode> barcodes = await _barcodeScanner.processImage(
        inputImage,
      );

      if (barcodes.isNotEmpty && mounted) {
        String? barcodeValue = barcodes.first.rawValue;
        if (barcodeValue != null) {
          await _stopImageStream();
          if (mounted) {
            Navigator.pop(context, barcodeValue);
          }
          return;
        }
      }

      // 2. If no barcode popped (or barcodeValue was null), try Text Recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      if (mounted) {
        await search(recognizedText);
      }
    } catch (e, stackTrace) {
      debugPrint('****** Error processing image with ML Kit: $e');
      debugPrint('****** Stack Trace: $stackTrace');
    } finally {
      if (mounted) {
        _isProcessing = false;
        _resetProcessingDelay();
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _cameras == null ||
        _cameras!.isEmpty) {
      debugPrint(
        "Controller or cameras not ready for image processing. Controller: ${_controller?.value.isInitialized}, Cameras: ${_cameras?.length}",
      );
      return null;
    }

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == _controller!.description.lensDirection,
      orElse: () => _cameras!.first,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) {
        debugPrint(
          "Could not get rotation compensation for device orientation.",
        );
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) {
      debugPrint("Failed to determine input image rotation.");
      return null;
    }

    // Only support NV21 on Android for ML Kit
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bytes = _yuv420ToNv21(image);
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        );
        return InputImage.fromBytes(bytes: bytes, metadata: metadata);
      } catch (e, stackTrace) {
        debugPrint("Error converting YUV420 to NV21: $e\n$stackTrace");
        return null;
      }
    }

    // iOS: use BGRA8888 if available
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        image.format.raw == 1111970369) {
      final plane = image.planes.first;
      final bytes = plane.bytes;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    debugPrint("Unsupported image format for ML Kit.");
    return null;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // Copy Y plane
    int offset = 0;
    final Plane yPlane = image.planes[0];
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        row * width,
        (row + 1) * width,
        yPlane.bytes,
        row * yPlane.bytesPerRow,
      );
    }
    offset += ySize;

    // Interleave VU for NV21
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        int uIndex = row * uvRowStride + col * uvPixelStride;
        int vIndex = row * vPlane.bytesPerRow + col * vPlane.bytesPerPixel!;
        nv21[offset++] = vPlane.bytes[vIndex];
        nv21[offset++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }

  void _resetProcessingDelay() {
    _processingDelayTimer?.cancel();
    _processingDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _canProcess = true;
      }
    });
  }

  String _getCameraErrorMessage(CameraException e) {
    // Ensure context is available before using it for l10n
    if (!mounted) return 'Camera error: ${e.description ?? e.code}';

    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return l10n.cameraAccessDenied;
      case 'CameraAccessRestricted':
        return 'Camera access is restricted.';
      case 'AudioAccessDenied':
        return 'Audio access denied.';
      case 'cameraNotFound':
      case 'NoCameraAvailable':
        return 'No suitable camera found.';
      case 'captureTimeout':
        return 'Camera capture timed out.';
      default:
        return 'Camera error: ${e.description ?? e.code}';
    }
  }

  void _handleCameraException(CameraException e) {
    if (!mounted) return;
    final message = _getCameraErrorMessage(e);
    _showErrorSnackBar(message);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      showSnackBar(
        context,
        Text(message, style: const TextStyle(color: Colors.white)),
      );
    }
  }

  @override
  void dispose() {
    _processingDelayTimer?.cancel();
    _disposeCameraResources();
    _barcodeScanner.close();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _disposeCameraResources() async {
    // Check controller before stopping stream or disposing
    final controller = _controller;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream().catchError((e) {
          debugPrint("Error stopping image stream: $e");
        });
      }
      await controller.dispose().catchError((e) {
        debugPrint("Error disposing camera controller: $e");
      });
      // Only set to null if it's the same controller we disposed
      if (_controller == controller) {
        _controller = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    final l10n = AppLocalizations.of(context)!;

    if (_initializationError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _initializationError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed:
                          () => Navigator.pop(context), // Allow user to go back
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        side: WidgetStateProperty.all<BorderSide>(
                          BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      child: Text(l10n.goBack),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _initializeCamera,
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        side: WidgetStateProperty.all<BorderSide>(
                          BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (!_isCameraInitialized || _controller == null) {
      // Show loading indicator until controller is initialized
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withAlpha((0.8 * 255).round()),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: l10n.appName),
      extendBodyBehindAppBar: true,
      body: body, // Use the determined body widget
    );
  }
}
