import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class TextRecognitionController extends GetxController {
  var recognizedText = ''.obs;
  var isProcessing = false.obs;






  CameraController? cameraController;
  late TextRecognizer textRecognizer;


  @override
  void onInit() {
    super.onInit();
    textRecognizer = TextRecognizer();
    Permission.camera.request();
  }

  @override
  void onClose() {
    textRecognizer.close();
    cameraController?.dispose();
    super.onClose();
  }


  Future<void> startLiveTextRecognition(List<CameraDescription> cameras) async {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await cameraController!.initialize();
    cameraController!.startImageStream(processCameraImage);
  }

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
  // Future<void> takePicture(ImageSource source) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     File? croppedFile = await cropImage(File(pickedFile.path));
  //     if (croppedFile != null) {
  //       await processImage(croppedFile);
  //     }
  //   }
  // }
  Future<void> takePicture(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    isProcessing.value = true;
    final File imageFile = File(pickedFile.path);

    try {
      // Extract text
      await getRecognizer(pickedFile, true);

      // Convert extracted text to JSON
      final jsonOutput = parseInvoiceToJson(recognizedText.value);

      print("Generated JSON: $jsonOutput");
      print("Extracted Text: ${recognizedText.value}");

    } catch (e) {
      print('Error recognizing text: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> getRecognizer(XFile img, bool? isList) async {
    final selectedImage = InputImage.fromFilePath(img.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    RecognizedText recognizedTexts = await textRecognizer.processImage(selectedImage);
    await textRecognizer.close();

    StringBuffer buffer = StringBuffer();
    for (TextBlock block in recognizedTexts.blocks) {
      for (TextLine line in block.lines) {
        buffer.writeln(line.text.trim());
      }
    }

    recognizedText.value = buffer.toString().trim();
    print('Extracted Text:\n${recognizedText.value}');
  }

// ✅ Updated JSON extraction function
/*  Map<String, dynamic> parseInvoiceToJson(String rawText) {
    List<String> lines = rawText.split('\n');

    String companyName = '';
    String customerId = '';
    String accessCode = '';
    String invoiceNo = '';
    String dueDate = '';
    String customerNo = '';
    List<Map<String, String>> items = [];

    bool isItemSection = false;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Extract header fields
      if (line.contains("Company Name:")) {
        companyName = extractValue(line);
      } else if (line.contains("Customer #:")) {
        customerId = extractValue(line);
      } else if (line.contains("Access Code:")) {
        accessCode = extractValue(line);
      } else if (line.contains("Invoice #:")) {
        invoiceNo = extractValue(line);
      } else if (line.contains("Due Date:")) {
        dueDate = extractValue(line);
      }

      // Start item extraction after the "Date" section header
      if (line.toLowerCase().contains("date") && !isItemSection) {
        isItemSection = true;
        continue;
      }

      // Extract item details
      if (isItemSection) {
        List<String> words = line.split(RegExp(r'\s+')); // Split by spaces
        if (words.isEmpty || words.length<4) continue;

        // Validate date format (e.g., MM/DD/YY)
        if (!RegExp(r'^\d{2}/\d{2}/\d{2}$').hasMatch(words[0])) continue;

        // Extract data
        String itemDate = words[0];
        String itemDescription = words.sublist(1, words.length - 3).join(" "); // Combine all description words
        String itemQty = words[words.length - 3];
        String itemPrice = words[words.length - 2];
        String itemTotal = words[words.length - 1];

        // Add item to list
        items.add({
          'date': itemDate,
          'description': itemDescription,
          'qty': itemQty,
          'price': itemPrice,
          'total': itemTotal,
        });

        debugPrint("Extracted Item: $itemDate | $itemDescription | $itemQty | $itemPrice | $itemTotal");
      }
    }

    return {
      "customer_id": int.tryParse(customerId) ?? 0,
      "access_code": int.tryParse(accessCode) ?? 0,
      "invoice_no": int.tryParse(invoiceNo) ?? 0,
      "due_date": dueDate,
      "customer_no": int.tryParse(customerNo) ?? 0,
      "company_name": companyName,
      "items": items,
    };
  }*/

  Map<String, dynamic> parseInvoiceToJson(String extractedText) {
    Map<String, String> data = {};

    // Improved regex to properly extract each field
    data["shipper"] = _extractValue(extractedText, r"Shipper:\s*(.*?)(?=\nConsignee:|\nPort of Loading:)");
    data["consignee"] = _extractValue(extractedText, r"Consignee:\s*(.*?)(?=\nNotify Party:|\nPort of Loading:)");
    data["notify_party"] = _extractValue(extractedText, r"Notify Party:\s*(.*?)(?=\nPort of Loading:|\nMarks & Nos)");

    data["port_of_loading"] = _extractValue(extractedText, r"Port of Loading:\s*(.*?)(?=\n)");
    data["port_of_discharge"] = _extractValue(extractedText, r"Port of Discharge:\s*(.*?)(?=\n)");
    data["number_of_packages"] = _extractValue(extractedText, r"(\d+)\s*PACKAGES");
    data["container_details"] = _extractValue(extractedText, r"(\d+X\d+HC\s*CONTAINER)");
    data["net_weight"] = _extractValue(extractedText, r"NET WEIGHT PER CNTR:\s*CNTR NO \S+\s*NET WEIGHT:\s*([\d,]+ KGS)");
    data["description_of_goods"] = _extractGoods(extractedText).join(", ");

    return data;
  }

// Helper function to extract a single value using regex
  String _extractValue(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false, dotAll: true).firstMatch(text);
    return match != null ? match.group(1)!.replaceAll('\n', ' ').trim() : "N/A";
  }



// Helper function to extract a single value using regex




  // Extract multiple goods descriptions as a list
  List<String> _extractGoods(String text) {
    final match = RegExp(r"Description of Goods:\s*([\s\S]*)", caseSensitive: false).firstMatch(text);
    if (match != null) {
      return match.group(1)!.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }





// ✅ Helper function to extract values safely
  String extractValue(String line) {
    List<String> parts = line.split(":");
    return parts.length > 1 ? parts.sublist(1).join(":").trim() : "";
  }




  /// Check if a string is a number
  bool _isNumeric(String str) {
    return double.tryParse(str) != null;
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
