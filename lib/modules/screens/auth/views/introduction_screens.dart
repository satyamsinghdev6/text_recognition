import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:text_reconigation_project/generated/assets.dart';

class OCRIntroScreen extends StatefulWidget {
  const OCRIntroScreen({super.key});

  @override
  _OCRIntroScreenState createState() => _OCRIntroScreenState();
}

class _OCRIntroScreenState extends State<OCRIntroScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  List<Map<String, String>> introData = [
    {
      "image": Assets.imagesScreen1,
      "title": "Scan Documents Instantly",
      "description": "Use your camera to capture text from any document quickly and accurately."
    },
    {
      "image": Assets.imagesScreen1,
      "title": "Extract & Edit Text",
      "description": "Convert scanned text into editable format and make changes as needed."
    },
    {
      "image": Assets.imagesScreen1,
      "title": "Share & Save Easily",
      "description": "Export scanned text to various formats and share with anyone."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(

        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemCount: introData.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(introData[index]["image"]!, height: 300),
                  const SizedBox(height: 20),
                  Text(
                    introData[index]["title"]!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      introData[index]["description"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: introData.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.blue,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (currentIndex < introData.length - 1) {
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: Text(currentIndex == introData.length - 1 ? "Get Started" : "Next"),
            ),
          ),
        ],
      ),
    );
  }


}
