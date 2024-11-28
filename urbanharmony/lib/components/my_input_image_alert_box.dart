import 'package:flutter/material.dart';

class MyInputImageAlertBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final void Function()? onPressed;
  final String onPressedText;
  final Widget? mywidget;
  final void Function()? onTap;
  final void Function()? onCancel;
  const MyInputImageAlertBox(
      {super.key,
      required this.textController,
      required this.hintText,
      required this.onPressed,
      required this.onPressedText,
      this.onTap,
      this.mywidget,
      this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: textController,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: hintText,
                    hintStyle:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    fillColor: Theme.of(context).colorScheme.secondary,
                    filled: true,
                    counterStyle:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                mywidget!,
                ElevatedButton(
                  onPressed: onTap!,
                  child: const Text('Choose Image'),
                )
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Clear"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onPressed!();
          },
          child: Text(onPressedText),
        ),
      ],
    );
  }
}
