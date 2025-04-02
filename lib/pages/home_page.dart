import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? imagePath;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    imagePath = image.path;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // usar 'backgroundColor' en lugar de 'primary'
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                "Cámara",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Image.file(
                  File(imagePath!),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}