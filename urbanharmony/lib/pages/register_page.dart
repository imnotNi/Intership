
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/components/my_button.dart';
import 'package:urbanharmony/components/my_loading_circle.dart';
import 'package:urbanharmony/components/my_textfield.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_service.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _db = DatabaseService();
  //text controller
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  Future<void> register() async {
    // Validate input
    if (nameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('please_enter_name'.tr), // Dịch "Vui lòng nhập tên của bạn."
        ),
      );
      return;
    }

    if (emailController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('please_enter_email'.tr), // Dịch "Vui lòng nhập địa chỉ email của bạn."
        ),
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('please_enter_password'.tr), // Dịch "Vui lòng nhập mật khẩu của bạn."
        ),
      );
      return;
    }

    if (passwordController.text != confirmController.text) {
      showDialog(
        context: context,
        builder: (context) =>  AlertDialog(
          title: Text("passwords_do_not_match".tr), // Dịch "Mật khẩu không khớp"
        ),
      );
      return;
    }

    showLoadingCircle(context);
    try {
      await _auth.registerEmailPassword(
          emailController.text, passwordController.text);

      if (mounted) hideLoadingCircle(context);

      await _db.saveUserInfoInFirebase(
          name: nameController.text, email: emailController.text);
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
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

                const SizedBox(
                  height: 10,
                ),
                 Text(
                  "register".tr, // Dịch "Đăng ký"
                  style: TextStyle(fontSize: 20),
                ),
                //name
                const SizedBox(height: 25),
                MyTextField(
                  hintText: "name".tr, // Dịch "Tên"
                  obscureText: false,
                  controller: nameController,
                ),
                //email
                const SizedBox(height: 10),
                MyTextField(
                  hintText: "email".tr, // Dịch "Email"
                  obscureText: false,
                  controller: emailController,
                ),
                //password
                const SizedBox(height: 10),
                MyTextField(
                  hintText: "password".tr, // Dịch "Mật khẩu"
                  obscureText: true,
                  controller: passwordController,
                ),
                //confirm pw
                const SizedBox(height: 10),
                MyTextField(
                  hintText: "confirm_password".tr, // Dịch "Xác nhận mật khẩu"
                  obscureText: true,
                  controller: confirmController,
                ),
                const SizedBox(height: 25),
                //button
                MyButton(onTap: register, text: "register".tr), // Dịch "Đăng ký"

                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "have_account".tr, // Dịch "Bạn đã có tài khoản?"
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child:  Text(
                        "login_here".tr, // Dịch "Đăng nhập tại đây"
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}