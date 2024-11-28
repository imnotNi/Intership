import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:urbanharmony/helper/utils.dart';
import 'package:urbanharmony/services/firestore/firestore_product.dart';
import 'package:urbanharmony/services/firestore/firestore_category.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../models/list_products.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final FirestoreService firestoreService = FirestoreService();
  final FirestoreCategoryService categoryService = FirestoreCategoryService();

  String selectedCategoryId = 'All'; // Default category ID
  @override
  void initState() {
    super.initState();
    PermissionUtil.requestAll();
  }
  _saveNetworkImage(String imageUrl) async {
    var response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes));
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: "hello");
    print(result);
    Utils.toast("Image Saved to Gallery");
  }
  Future<void> addNewCharacter(String name, String url) async {
    // Check if the item already exists
    // if (design.any(
    //     (element) => element['name'] == name && element['imageUrl'] == url)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Item_already_exists'.tr),
    //       duration: Duration(seconds: 1),
    //       showCloseIcon: true,
    //     ),
    //   );
    //   return;
    // }

    // Add the new item if it doesn't exist
    design.add({
      'id' : listId.toString(),
      'name': name,
      'imageUrl': url,
      'size' : 150,
    });
    listId++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item_added'.tr),
        duration: Duration(seconds: 1),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('An error occurred: ${snapshot.error}'.tr));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> productsList = snapshot.data!.docs;
            return Column(
              children: [
                _buildCategorySelector(),
                Expanded(child: _buildProductGrid(productsList)),
              ],
            );
          }
          return Center(child: Text('No products available.'.tr));
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: categoryService.getActiveCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading categories: ${snapshot.error}'.tr));
        }

        List<Widget> categoryChips = [
          // Add "All" category chip
          GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryId = 'All';
              });
            },
            child: Chip(
              label: Text('All'.tr),
              backgroundColor:
                  selectedCategoryId == 'All' ? Colors.teal : Colors.grey[300],
              labelStyle: TextStyle(
                color:
                    selectedCategoryId == 'All' ? Colors.white : Colors.black,
              ),
            ),
          ),
        ];

        // Add chips for each category from Firestore
        if (snapshot.hasData) {
          categoryChips.addAll(
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategoryId = doc.id;
                  });
                },
                child: Chip(
                  label: Text(data['Name'] ?? ''),
                  backgroundColor: selectedCategoryId == doc.id
                      ? Colors.teal
                      : Colors.grey[300],
                  labelStyle: TextStyle(
                    color: selectedCategoryId == doc.id
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              );
            }).toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: categoryChips.map((chip) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: chip,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(List<QueryDocumentSnapshot> productsList) {
    List<QueryDocumentSnapshot> filteredProducts =
        productsList.where((product) {
      var data = product.data() as Map<String, dynamic>;
      return selectedCategoryId == 'All' ||
          data['categoryId'] == selectedCategoryId;
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        var product = filteredProducts[index];
        Map<String, dynamic> data = product.data() as Map<String, dynamic>;
        return _buildProductCard(data, product.id);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String docID) {
    final GlobalKey _globalKeyProduct = GlobalKey();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(data, docID),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    child: RepaintBoundary(
                      key: _globalKeyProduct,
                      child: Image.network(
                        data['ImageUrl'] ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.download, color: Colors.teal),
                      onPressed: () async {
                        await _saveNetworkImage(data['ImageUrl']);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['ProductName'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FutureBuilder<String>(
                      future: firestoreService
                          .getCategoryName(data['categoryId'] ?? ''),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${data['Price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            String productLink = data['ProductLink'] ?? '';
                            if (productLink.isNotEmpty) {
                              try {
                                final Uri url = Uri.parse(productLink);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Could not launch product link'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Invalid product link: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product link not available'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: const Size(50, 24),
                          ),
                          child: const Text(
                            'GO',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(String? imageUrl) async {
    if (imageUrl == null) return;

    // Request storage permission using the permission_handler package
    final status = await Permission.storage.request();

    if (status.isPermanentlyDenied) {
      // Open app settings dialog
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Storage Permission Required'.tr),
          content: Text('Storage permission is required to download images. '
                  'Please enable it in your device settings.'
              .tr),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'.tr),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Open Settings'.tr),
              onPressed: () {
                Navigator.of(context).pop();

                openAppSettings();
              },
            ),
          ],
        ),
      );
      return;
    }

    if (status.isGranted) {
      try {
        var dio = Dio();
        var response = await dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        // Get the external storage directory
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('Could not access external storage'.tr);
        }

        // Create a file name based on the current timestamp
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory.path}/$fileName';

        // Write the file
        File file = File(filePath);
        await file.writeAsBytes(response.data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to Downloads/$fileName'.tr)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e'.tr)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required'.tr)),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> data, String docID) {
    TransformationController _transformationController = TransformationController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['ProductName'] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  maxScale: 5.0,
                  minScale: 1.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  onInteractionEnd: (details) {
                    // Đặt lại giá trị của controller khi kết thúc tương tác
                    _transformationController.value = Matrix4.identity();
                  },
                  child: Image.network(data['ImageUrl'] ?? '', fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                FutureBuilder<String>(
                  future: firestoreService
                      .getCategoryName(data['categoryId'] ?? ''),
                  builder: (context, snapshot) {
                    // return Text('Category: ${snapshot.data ?? 'Loading...'.tr}'.tr);
                    return Text(
                        '${'Category:'.tr} ${snapshot.data?.tr ?? 'Loading...'.tr}');
                  },
                ),
                // Text('Brand: ${data['Brand'] ?? ''}'),
                // Text('Price: \$${data['Price']?.toStringAsFixed(2) ?? '0.00'}'),
                // Text('Description: ${data['Description'] ?? ''}'),
                Text('${'category'.tr}${data['Category'] ?? ''}'),
                Text('${'brand'.tr}${data['Brand'] ?? ''}'),
                Text(
                    '${'price'.tr}${data['Price']?.toStringAsFixed(2) ?? '0.00'}'),
                Text('${'description'.tr}${data['Description'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    addNewCharacter(data['ProductName'], data['ImageUrl']);
                    Navigator.of(context).pop();
                  },
                  child: Text('Add to design'.tr),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'.tr),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
