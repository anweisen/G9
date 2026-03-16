import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class FileExportService {
  static Future<void> exportJson(String fileName, String jsonString) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

    if (kIsWeb) {
      _saveForWeb(bytes, fileName);
    } else {
      await _saveForDesktop(bytes, fileName);
    }
  }

  static void _saveForWeb(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.json")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _saveForDesktop(Uint8List bytes, String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save your file',
      fileName: '$fileName.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
    }
  }
}