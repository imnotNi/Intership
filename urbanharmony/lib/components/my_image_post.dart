import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';

class MyImagePost extends StatelessWidget {
  final String imageUrl;
  const MyImagePost({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storageService, child) => Container(
        decoration: BoxDecoration(
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.network(
                width: MediaQuery.of(context).size.width-10,
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress != null) {
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  } else {
                    return child;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
