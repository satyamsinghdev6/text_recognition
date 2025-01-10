import 'dart:io';
import 'package:camera/camera.dart';
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
      appBar: AppBar(title: Text('Text Recognition')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
        width: double.infinity,
        alignment: Alignment.center,
        height: 300,
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
                  return CircularProgressIndicator();
                }
                return Text(
                  controller.recognizedText.value.isEmpty
                      ? "No text recognized"
                      : controller.recognizedText.value,
                  style: TextStyle(fontSize: 16),
                );
              }),
          
              SizedBox(height: 20),
          
              // Camera live recognition button
              ElevatedButton(
                onPressed: () async {
                  // Initialize camera and start live recognition
                  // final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    controller.startLiveTextRecognition(cameras);
                  } else {
                    Get.snackbar('Error', 'No camera found');
                  }
                },
                child: Text('Start Live Text Recognition'),
              ),
          
              SizedBox(height: 20),

            ],
          ),
        ),
        ),
      ),
      floatingActionButton:    Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: (){
            controller.takePicture(ImageSource.camera);
          }, icon: Icon(Icons.camera,size: 35,)),
          SizedBox(width: 23,),
          IconButton(onPressed: (){
            controller.takePicture(ImageSource.gallery);
          }, icon: Icon(Icons.photo,size: 35,)),
        ],
      ),
    );
  }
}
