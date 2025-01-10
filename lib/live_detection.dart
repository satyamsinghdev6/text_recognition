import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'main.dart';
import 'models/object_model.dart';

class LiveDetection extends StatefulWidget {
  @override
  _LiveDetectionState createState() => _LiveDetectionState();
}

class _LiveDetectionState extends State<LiveDetection> {
  late CameraController _controller;
  late ObjectDetector _detector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
    );
    await _controller.initialize();

    _controller.startImageStream((CameraImage image) {
      // Convert CameraImage to Uint8List
      Uint8List imageBytes = _convertCameraImage(image);

      // Detect objects
      var results = _detector.detectObjects(imageBytes);

      setState(() {
        // Display results (bounding boxes, labels, etc.)
      });
    });
  }

  Uint8List _convertCameraImage(CameraImage image) {
    // Perform conversion
    try {
      // Example: Assuming NV21 to RGB conversion (depends on your use case)
      Uint8List convertedImage = Uint8List.fromList(image.planes[0].bytes);
      return convertedImage;
    } catch (e) {
      throw Exception("Failed to convert CameraImage: $e");
    }
  }


  Future<void> _initializeDetector() async {
    _detector = ObjectDetector();
    await _detector.loadModel();
    print("Detector initialized successfully!");
  }

  @override
  void dispose() {
    _controller.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? CameraPreview(_controller)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
