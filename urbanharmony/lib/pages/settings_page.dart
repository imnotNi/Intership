
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_settings_tile.dart';
import 'package:urbanharmony/helper/navigate_pages.dart';
import 'package:urbanharmony/theme/theme_provider.dart';
import 'package:get/get.dart'; // Thêm gói GetX để sử dụng cho đa ngôn ngữ

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('settings'.tr), // Dịch tiêu đề
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        children: [
          MySettingsTile(
            title: 'dark_mode'.tr, // Dịch tiêu đề chế độ tối
            action: CupertinoSwitch(
              value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              onChanged: (value) =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
            ),
          ),
          MySettingsTile(
            title: 'blocked_users'.tr, // Dịch tiêu đề người dùng bị chặn
            action: IconButton(
              onPressed: () => goBlockedUsersPage(context),
              icon: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          MySettingsTile(
            title: 'accounts_setting'.tr, // Dịch tiêu đề cài đặt tài khoản
            action: IconButton(
              onPressed: () => goAccountSettingsPage(context),
              icon: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          MySettingsTile(
            title: 'language'.tr, // Dịch tiêu đề ngôn ngữ
            action: PopupMenuButton<String>(
              icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              onSelected: (String value) {
                if (value == 'en_US') {
                  Get.updateLocale(Locale('en', 'US')); // Cập nhật ngôn ngữ sang tiếng Anh
                } else if (value == 'vi_VN') {
                  Get.updateLocale(Locale('vi', 'VN')); // Cập nhật ngôn ngữ sang tiếng Việt
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'en_US',
                    child: Text('english'.tr), // Dịch tiếng Anh
                  ),
                  PopupMenuItem<String>(
                    value: 'vi_VN',
                    child: Text('vietnamese'.tr), // Dịch tiếng Việt
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}
