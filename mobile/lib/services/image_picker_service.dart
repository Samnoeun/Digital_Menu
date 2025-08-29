import 'dart:async'; // Add this import
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

class ImagePickerResult {
  final File? mobileFile;
  final Uint8List? webBytes;
  final String fileName;

  ImagePickerResult({
    this.mobileFile,
    this.webBytes,
    required this.fileName,
  });
}

class ImagePickerService {
  static Future<ImagePickerResult?> pickImage() async {
    if (kIsWeb) {
      return _pickImageWeb();
    } else {
      return _pickImageMobile();
    }
  }

  static Future<ImagePickerResult?> _pickImageWeb() async {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      final completer = Completer<ImagePickerResult?>();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            completer.complete(ImagePickerResult(
              webBytes: reader.result as Uint8List,
              fileName: file.name,
            ));
          });
          
          reader.readAsArrayBuffer(file);
        } else {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  static Future<ImagePickerResult?> _pickImageMobile() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return ImagePickerResult(
          mobileFile: File(pickedFile.path),
          fileName: pickedFile.name,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}