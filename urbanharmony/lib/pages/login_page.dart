
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/components/my_button.dart';
import 'package:urbanharmony/components/my_loading_circle.dart';
import 'package:urbanharmony/components/my_textfield.dart';
import 'package:urbanharmony/pages/forgot_password_page.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_service.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _db = DatabaseService();

  //text controller
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //login method
  Future<void> login() async {
    showLoadingCircle(context);

    // Validate input
    if (emailController.text.isEmpty) {
      hideLoadingCircle(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('enter_email'.tr), // Sử dụng khóa dịch
        ),
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      hideLoadingCircle(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('enter_password'.tr), // Sử dụng khóa dịch
        ),
      );
      return;
    }

    try {
      await _auth.loginEmailPassword(emailController.text, passwordController.text);
      if (mounted) hideLoadingCircle(context);
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('email_password_error'.tr), // Sử dụng khóa dịch
          ),
        );
      }
    }
  }

  Future<void> loginGG() async {
    showLoadingCircle(context);
    try {
      await _auth.signInWithGoogle();
      if (mounted) hideLoadingCircle(context);
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('google_signin_error'.tr), // Sử dụng khóa dịch
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'login'.tr, // Sử dụng khóa dịch
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  hintText: 'email'.tr, // Sử dụng khóa dịch
                  obscureText: false,
                  controller: emailController,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  hintText: 'password'.tr, // Sử dụng khóa dịch
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const ForgotPasswordPage();
                            },
                          ),
                        );
                      },
                      child: Text(
                        'forgot_password'.tr, // Sử dụng khóa dịch
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                MyButton(onTap: login, text: 'login'.tr), // Sử dụng khóa dịch
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "dont_have_account".tr, // Sử dụng khóa dịch
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'register_here'.tr, // Sử dụng khóa dịch
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SignInButton(
                  Buttons.Google,
                  onPressed: () => AuthService().signInWithGoogle(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
