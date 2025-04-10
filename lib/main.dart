import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:text_reconigation_project/testing_page.dart';
import 'package:camera/camera.dart';

import 'aws_views.dart';
import 'live_detection.dart';
import 'modules/screens/auth/views/introduction_screens.dart';

late List<CameraDescription> cameras;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home:/*LiveDetection()??*/ TextRecognitionPage(),
      home:AwsViews(),
      // home:/*LiveDetection()??*/ OCRIntroScreen(),
    );
  }
}

