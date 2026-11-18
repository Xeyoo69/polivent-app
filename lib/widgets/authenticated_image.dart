import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/api_service.dart';

class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorMessage = 'Gambar gagal dimuat.',
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String errorMessage;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  late Future<Uint8List> _image;

  @override
  void initState() {
    super.initState();
    _image = ApiService.instance.getBytes(widget.url);
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _image = ApiService.instance.getBytes(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.fieldFill,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.errorMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.fieldFill,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
