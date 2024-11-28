
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Thêm gói GetX
import 'package:urbanharmony/firebase_options.dart';
import 'package:urbanharmony/pages/home_page.dart';
import 'package:urbanharmony/pages/login_page.dart';
import 'package:urbanharmony/pages/notification_page.dart';
import 'package:urbanharmony/services/auth/auth_gate.dart';
import 'package:urbanharmony/services/database/database_provider.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';
import 'package:urbanharmony/theme/light_mode.dart';
import 'package:urbanharmony/theme/theme_provider.dart';
import 'package:urbanharmony/localization/LocateString.dart'; // Đường dẫn đến tệp LocaleString.dart

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => DatabaseProvider()),
        ChangeNotifierProvider(create: (context) => StorageService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: LocaleString(), // Đăng ký LocaleString
      locale: Locale('en', 'US'), // Ngôn ngữ mặc định
      title: 'Flutter Demo',
      initialRoute: '/',
      navigatorKey: navigatorKey,
      routes: {
        '/': (context) => const AuthGate(),
        'login_page': (context) => LoginPage(),
        '/notification_screen': (context) => const NotificationPage(),
        '/home_page': (context) => const HomePage(),
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}