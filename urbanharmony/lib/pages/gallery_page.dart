import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:provider/provider.dart';

import 'package:urbanharmony/components/my_image_post.dart';
import 'package:urbanharmony/models/list_products.dart';
import 'package:urbanharmony/pages/game_page.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/firestore/firestore_background.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int selectedIndex = -1; // Initially no image is selected

  @override
  void initState() {
    super.initState();
    fetchImages();
    fetchImagesUser();
  }

  Future<void> fetchImages() async {
    await Provider.of<StorageService>(context, listen: false).fetchImages();
  }

  Future<void> fetchImagesUser() async {
    await Provider.of<StorageService>(context, listen: false).fetchImagesUser();
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
        final List<String> imageUrlsUser = storageService.imageUrlsUser;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              foregroundColor: Theme.of(context).colorScheme.secondary,
              title: Text('Choose_your_background'.tr),
              backgroundColor: Theme.of(context).colorScheme.primary,
              actions: [
                IconButton(
                  onPressed: () {
                    if (selectedIndex != -1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(
                              game: MyGame(),
                              selectedImageUrl: imageUrls[selectedIndex]),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please_select_background'.tr),
                          duration: Duration(seconds: 2),
                          showCloseIcon: true,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.next_plan_rounded,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    size: 25,
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                storageService.uploadImageUser();
              },
              child: const Icon(Icons.add_outlined),
            ),
            body: Column(
              children: [
                TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).colorScheme.inversePrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.primary,
                  indicatorColor: Theme.of(context).colorScheme.inversePrimary,
                  tabs: [
                    Tab(text: 'Our background'.tr),
                    Tab(text: 'Your background'.tr),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          final String imageUrl = imageUrls[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedIndex == index) {
                                  selectedIndex =
                                      -1; // Unselect if already selected
                                } else {
                                  selectedIndex = index;
                                }
                              });
                            },
                            child: Card(
                              elevation: selectedIndex == index ? 4 : 2,
                              child: Column(
                                children: [
                                  MyImagePost(imageUrl: imageUrl),
                                  if (selectedIndex == index)
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: CupertinoColors.activeGreen,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: imageUrlsUser.length,
                        itemBuilder: (context, index) {
                          final String imageUrl = imageUrlsUser[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedIndex == index) {
                                  selectedIndex =
                                      -1; // Unselect if already selected
                                } else {
                                  selectedIndex = index;
                                }
                              });
                            },
                            child: Card(
                              elevation: selectedIndex == index ? 4 : 2,
                              child: Column(
                                children: [
                                  IconButton(
                                      onPressed: () =>
                                          storageService.deleteImages(imageUrl),
                                      icon: const Icon(Icons.delete)),
                                  MyImagePost(imageUrl: imageUrl),
                                  if (selectedIndex == index)
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: CupertinoColors.activeGreen,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
