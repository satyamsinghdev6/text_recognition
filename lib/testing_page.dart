import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:text_reconigation_project/text_controller.dart';

import 'main.dart';

class TextRecognitionPage extends StatelessWidget {
  final TextRecognitionController controller = Get.put(TextRecognitionController());

  TextRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Recognition')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(255, 203, 203, 203),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Obx(() {
                    if (controller.isProcessing.value) {
                      return const CircularProgressIndicator();
                    }

                    if (controller.recognizedText.value.isEmpty) {
                      return const Text("No text recognized");
                    }

                    final jsonOutput = controller.parseInvoiceToJson(controller.recognizedText.value);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const Text(
                        //   'Recognized JSON:',
                        //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        // ),
                        const SizedBox(height: 8),

                        ...jsonOutput.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(entry.value.toString())),
                              ],
                            ),
                          );
                        }),

                        SizedBox(height: 40,),
                        Container(

                          child: Text(controller.recognizedText.value),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              controller.takePicture(ImageSource.camera);
            },
            icon: const Icon(Icons.camera, size: 35),
          ),
          const SizedBox(width: 23),
          IconButton(
            onPressed: () {
              controller.takePicture(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo, size: 35),
          ),
        ],
      ),
    );
  }
}

