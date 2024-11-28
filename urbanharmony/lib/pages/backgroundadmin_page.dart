import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_image_post.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';

class BackgroundAdminPage extends StatefulWidget {
  const BackgroundAdminPage({super.key});

  @override
  State<BackgroundAdminPage> createState() => _BackgroundAdminPageState();
}

class _BackgroundAdminPageState extends State<BackgroundAdminPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    await Provider.of<StorageService>(context, listen: false).fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (
          context,
          storageService,
          child,
          ) {
        final List<String> imageUrls = storageService.imageUrls;

        return Scaffold(
          appBar: AppBar(
            title:  Text('Background'.tr),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              storageService.uploadImage();
            },
            child: const Icon(Icons.add_outlined),
          ),
          body: ListView.builder(
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final String imageUrl = imageUrls[index];
              return Column(
                children: [
                  IconButton(
                      onPressed: () => storageService.deleteImages(imageUrl),
                      icon: const Icon(Icons.delete)),
                  MyImagePost(imageUrl: imageUrl),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
