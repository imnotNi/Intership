import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/components/my_button.dart';
import 'package:urbanharmony/components/my_textfield.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _auth = AuthService();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Text(
                "Enter your email: ".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            MyTextField(
              hintText: "Email".tr,
              obscureText: false,
              controller: emailController,
            ),
            const SizedBox(height: 25),
            MyButton(
                onTap: () async {
                  if (!isValidEmail(emailController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Invalid email address.'.tr),
                      ),
                    );
                    return;
                  }

                  try {
                    await _auth.sendPasswordResetLink(emailController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Password reset link sent successfully.'.tr),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    // Handle errors here (e.g., show an error message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send password reset link: $e'.tr),
                      ),
                    );
                  }
                },
                text: "Reset password".tr)
          ],
        ),
      ),
    );
  }
}

bool isValidEmail(String email) {
  final emailRegExp = RegExp(
      r'^[\w-]+(\.[\w-]+)*@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.([A-Za-z]{2,})$');
  return emailRegExp.hasMatch(email);
}
