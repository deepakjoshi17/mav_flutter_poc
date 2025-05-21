import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreviewView extends StatefulWidget {
  const PreviewView({super.key});

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  static const platform = MethodChannel('mav_flutter/preview');
  static const String viewType = 'native_preview_view';

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        creationParams: const <String, dynamic>{},
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      // For iOS, you would return a UiKitView here
      return const Center(
        child: Text('Preview not supported on this platform'),
      );
    }
  }
} 