import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:urbanharmony/pages/gallery_page.dart';
import 'package:urbanharmony/pages/game_page.dart';

import '../models/list_products.dart';

class DesignPage extends StatefulWidget {
  const DesignPage({super.key});

  @override
  State<DesignPage> createState() => _DesignPageState();
}

class _DesignPageState extends State<DesignPage> {
  final List<Map<String, dynamic>> items = design;
  final List<String> bg = backgrounds;

  void removeItem(int index) {
    setState(() {
      design.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Products list to design',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GalleryPage(),
                ),
              );
            },
            icon: Icon(
              Icons.next_plan_rounded,
              color: Theme.of(context).colorScheme.inversePrimary,
              size: 25,
            ),
          ),
        ],
      ),
      body: Expanded(
        child: design.isEmpty
            ? Center(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text('nothing_here'.tr),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('go_add_product'.tr),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ), // Dịch thông báo không có gì ở đây
              )
            : ListView.builder(
                itemCount: items.length, // No need for null check here
                itemBuilder: (context, index) {
                  final item = items[index];
                  final sizeController = TextEditingController(text: item['size'].toString());

                  return ListTile(
                    leading: Image(
                      image: NetworkImage(item['imageUrl']),
                      width: 100,
                      height: 100,
                    ),
                    title: Row(
                      children: [
                        Text(item['name']),
                        Spacer(),
                        Expanded(
                          child: TextField(
                            controller: sizeController,
                            onChanged: (value) {
                              items[index]['size'] = int.parse(value);
                            },
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        removeItem(index);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
