import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageDisplayScreen extends StatelessWidget {
  const ImageDisplayScreen({super.key, required this.imageUrl, required this.imageTag});
  final String imageUrl;
  final String imageTag;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InteractiveViewer(
        child: Center(
          child: Hero(
            tag: imageTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              // fit: BoxFit.fitWidth,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}
