import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'aws_textract_service.dart';


class AwsViews extends StatelessWidget {
  final AwsTextractService awsTextractService = AwsTextractService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: Column(


          children: [
            // if(awsTextractService.extractedText.value != "")
              Obx(()=>awsTextractService.isLoading.value?LinearProgressIndicator() : awsTextractService.extractedText.value.isNotEmpty
                  ? Expanded(child: /*buildFormatted*/Text(
                  awsTextractService.extractedText.value))
                  : Text("No data extracted yet."),),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  awsTextractService.pickImage();
                },
                child: Text('Pick & Extract Text'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildFormattedText(String extractedText) {
    String cleanedText = fixJsonFormat(extractedText); // Ensure valid JSON
    print("🔍 Cleaned JSON: $cleanedText"); // Debugging
    Map<String, dynamic> data = jsonDecode(cleanedText);;
    return ListView(
      children: data.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: "${entry.key}: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: entry.value.toString(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String fixJsonFormat(String rawText) {
    rawText = rawText.trim();

    // 🛑 Remove extra opening curly braces `{`
    if (rawText.startsWith("{{")) {
      rawText = rawText.substring(1);
    }
    if (rawText.startsWith("{\"{")) {
      rawText = rawText.replaceFirst("{\"", "\"");
    }

    // ✅ Ensure all keys are wrapped in double quotes properly
    rawText = rawText.replaceAllMapped(
        RegExp(r'(?<!")([a-zA-Z0-9_\(\)]+)(?=\s*:)', caseSensitive: false),
            (match) => '"${match.group(1)}"');

    // ✅ Remove trailing commas before closing brackets
    rawText = rawText.replaceAll(RegExp(r',\s*}'), '}');
    rawText = rawText.replaceAll(RegExp(r',\s*$'), '');

    // ✅ Ensure closing curly brace `}`
    if (!rawText.endsWith("}")) {
      rawText = "$rawText}";
    }

    return rawText;
  }


}


void toast(String message,
    {
      Color backgroundColor = Colors.redAccent,
      Color textColor = Colors.white}) {
  // doVibrate();
  Get.showSnackbar(
    GetSnackBar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor,
      boxShadows: const [
        BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1
        )
      ],
      snackPosition: SnackPosition.BOTTOM,
      isDismissible: true,
      // icon: assetImageWidget(assetUrl: onlyLogoImage),
      forwardAnimationCurve: Curves.easeIn,
      reverseAnimationCurve: Curves.easeOut,
      margin: const EdgeInsets.all(20),
      borderRadius: 10,
      snackStyle: SnackStyle.FLOATING,

      messageText: Text(
        message,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
    ),
  );
}