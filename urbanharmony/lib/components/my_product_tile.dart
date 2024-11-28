import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyProductTile extends StatefulWidget {
  final String productName;
  final String imageProduct;
  const MyProductTile({super.key, required this.productName, required this.imageProduct});

  @override
  State<MyProductTile> createState() => _MyProductTileState();
}

class _MyProductTileState extends State<MyProductTile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Product'.tr),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.productName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              widget.imageProduct,
              width: 300,
              height: 300,
            ),
            SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('<  Quay lại', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
