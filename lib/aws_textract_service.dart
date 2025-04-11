import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'aws_views.dart';

class AwsTextractService {
  final String apiUrl =
      "https://gsmhvw0ytc.execute-api.ap-south-1.amazonaws.com/TextractOCRProxy";
  var extractedText = "".obs;
  RxBool isLoading = false.obs;
  XFile? selectedImage;

  Future<void> pickImage() async {
    selectedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      extractTextFromImage();
    } else {
      toast("No image selected");
    }
  }

  /* Future<void> extractTextFromImage() async {
    if (selectedImage == null) {
      toast("No image selected");
      return;
    }

    final Uint8List imageBytes = await selectedImage!.readAsBytes();
    final String base64Image = base64Encode(imageBytes);
    print("Base64 Image: $base64Image");

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image}),
      );

      if (response.statusCode == 200) {
        isLoading.value = false;
        final extractedData = jsonDecode(response.body);
        print("Extracted Data: $extractedData");

        if (extractedData.containsKey('extracted_data')) {
          String extractedTexts = extractedData['extracted_data'].toString();
          extractedText.value = extractedTexts;
          toast("✅ Text extracted successfully");
        } else {
          toast("⚠️ Extracted text not found");
        }
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      isLoading.value = false;
      print("❌ API Error: $e");
      toast("Something went wrong! Retrying...");

      // Automatically retry the API call without picking image again
      Future.delayed(Duration(seconds: 2), () {
        extractTextFromImage();
      });
    }
  }*/

  Future<void> extractTextFromImage() async {
    if (selectedImage == null) {
      toast("No image selected");
      return;
    }

    final Uint8List imageBytes = await selectedImage!.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image}),
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("data $responseData");

        // ✅ Expecting responseData['extracted_data'] to be a Map
        if (responseData.containsKey('extracted_data') &&
            responseData['extracted_data'] is Map) {
          final Map<String, dynamic> extractedMap =
              Map<String, dynamic>.from(responseData['extracted_data']);

          extractedText.value =
              const JsonEncoder.withIndent('  ').convert(extractedMap);

          // Optional: Navigate to display screen
          final extractedMapString =
              extractedMap.map((key, value) => MapEntry(key, value.toString()));
          Get.to(() => TextractResultView(extractedData: extractedMapString));

          print("✅ Key-value data extracted successfully");
          toast("✅ Key-value data extracted successfully");
        } else {
          print("⚠️ Invalid extracted_data format");
          toast("⚠️ Invalid extracted_data format");
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      print("❌ API Error: $e");
      toast("Something went wrong! Retrying...");
      Future.delayed(const Duration(seconds: 2), () => extractTextFromImage());
    }
  }

  Map<String, String> _extractKeyValuePairs(List blocks) {
    final Map<String, dynamic> blockMap = {};
    final Map<String, String> keyMap = {};
    final Map<String, String> valueMap = {};
    final Map<String, String> result = {};

    for (var block in blocks) {
      final id = block['Id'];
      blockMap[id] = block;

      if (block['BlockType'] == 'KEY_VALUE_SET') {
        if (block['EntityTypes']?.contains('KEY') ?? false) {
          keyMap[id] = _getText(block, blocks);
        } else {
          valueMap[id] = _getText(block, blocks);
        }
      }
    }

    keyMap.forEach((keyId, keyText) {
      final keyBlock = blockMap[keyId];
      final relationships = keyBlock['Relationships'] ?? [];

      for (var rel in relationships) {
        if (rel['Type'] == 'VALUE') {
          for (var valueId in rel['Ids']) {
            if (valueMap.containsKey(valueId)) {
              result[keyText] = valueMap[valueId]!;
            }
          }
        }
      }
    });

    return result;
  }

  String _getText(Map block, List allBlocks) {
    if (block['Relationships'] == null) return "";

    final List<String> textList = [];

    for (var rel in block['Relationships']) {
      if (rel['Type'] == 'CHILD') {
        for (var childId in rel['Ids']) {
          final childBlock = allBlocks.firstWhere((b) => b['Id'] == childId,
              orElse: () => null);
          if (childBlock != null && childBlock['BlockType'] == 'WORD') {
            textList.add(childBlock['Text']);
          }
        }
      }
    }

    return textList.join(' ');
  }
}

Map<String, dynamic> parseInvoiceToJson(String extractedText) {
  Map<String, String> data = {};

  // Improved regex to properly extract each field
  data["shipper"] = _extractValue(
      extractedText, r"Shipper:\s*(.*?)(?=\nConsignee:|\nPort of Loading:)");
  data["consignee"] = _extractValue(extractedText,
      r"Consignee:\s*(.*?)(?=\nNotify Party:|\nPort of Loading:)");
  data["notify_party"] = _extractValue(extractedText,
      r"Notify Party:\s*(.*?)(?=\nPort of Loading:|\nMarks & Nos)");

  data["port_of_loading"] =
      _extractValue(extractedText, r"Port of Loading:\s*(.*?)(?=\n)");
  data["port_of_discharge"] =
      _extractValue(extractedText, r"Port of Discharge:\s*(.*?)(?=\n)");
  data["number_of_packages"] =
      _extractValue(extractedText, r"(\d+)\s*PACKAGES");
  data["container_details"] =
      _extractValue(extractedText, r"(\d+X\d+HC\s*CONTAINER)");
  data["net_weight"] = _extractValue(extractedText,
      r"NET WEIGHT PER CNTR:\s*CNTR NO \S+\s*NET WEIGHT:\s*([\d,]+ KGS)");
  data["description_of_goods"] = _extractGoods(extractedText).join(", ");

  return data;
}

// Helper function to extract a single value using regex
String _extractValue(String text, String pattern) {
  final match =
      RegExp(pattern, caseSensitive: false, dotAll: true).firstMatch(text);
  return match != null ? match.group(1)!.replaceAll('\n', ' ').trim() : "N/A";
}

// Helper function to extract a single value using regex

// Extract multiple goods descriptions as a list
List<String> _extractGoods(String text) {
  final match =
      RegExp(r"Description of Goods:\s*([\s\S]*)", caseSensitive: false)
          .firstMatch(text);
  if (match != null) {
    return match
        .group(1)!
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return [];
}

class TextractResultView extends StatelessWidget {
  final Map<String, String> extractedData;

  const TextractResultView({super.key, required this.extractedData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted Invoice Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: extractedData.isEmpty
            ? const Center(child: Text('No data extracted'))
            : ListView.separated(
                itemCount: extractedData.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final key = extractedData.keys.elementAt(index);
                  final value = extractedData[key];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "$key:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Text(value ?? ""),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
