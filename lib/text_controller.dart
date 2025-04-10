import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class TextRecognitionController extends GetxController {
  var recognizedText = ''.obs;
  var isProcessing = false.obs;






  CameraController? cameraController;
  late TextRecognizer textRecognizer;


  @override
  void onInit() {
    super.onInit();
    textRecognizer = TextRecognizer();
  }

  @override
  void onClose() {
    textRecognizer.close();
    cameraController?.dispose();
    super.onClose();
  }


  // Future<void> startLiveTextRecognition(List<CameraDescription> cameras) async {
  //   cameraController = CameraController(cameras[0], ResolutionPreset.medium);
  //   await cameraController!.initialize();
  //   cameraController!.startImageStream(processCameraImage);
  // }

  void processCameraImage(CameraImage image) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      // Convert camera image to bytes and process it using ML Kit
      final bytes = _convertCameraImageToBytes(image);
      final inputImage = InputImage.fromBytes(
        bytes: Uint8List.fromList(bytes), // Convert List<int> to Uint8List
        metadata: InputImageMetadata(
          bytesPerRow: 1,
          format: InputImageFormat.nv21,
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg, // Adjust as necessary
        ),
      );

      final recognizedTextResult = await textRecognizer.processImage(inputImage);
      recognizedText.value = recognizedTextResult.text;
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  // Helper method to convert CameraImage to bytes
  List<int> _convertCameraImageToBytes(CameraImage image) {
    final plane = image.planes[0];
    return plane.bytes;
  }

  // Method to process a single image for text recognition
  Future<void> processImage(File imageFile) async {
    isProcessing.value = true;
    final inputImage = InputImage.fromFile(imageFile);
    try {
      final recognizedTextResult = await textRecognizer.processImage(inputImage);
      recognizedText.value = recognizedTextResult.text;
    } catch (e) {
      Get.snackbar('Error', 'Failed to recognize text: $e');
    } finally {
      isProcessing.value = false;
    }
  }






  final picker = ImagePicker();
  Future<void> takePicture(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      File? croppedFile = await cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        await processImage(croppedFile);
      }
    }
  }







  Future<File?> cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.deepOrange,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }



}
