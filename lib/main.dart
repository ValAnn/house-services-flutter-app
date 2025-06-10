// lib/main.dart

import 'package:flutter/material.dart';
import 'package:house_services_flutter/pages/login_page.dart';
import 'package:house_services_flutter/pages/registration_page.dart';
import 'package:house_services_flutter/pages/statistics_page.dart';
import 'package:house_services_flutter/pages/tenants_page.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'pages/home_page.dart';
import 'pages/add_request_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init(); // Инициализация сервиса API (загрузка токена)
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
            create: (_) => ApiService()), // Предоставляем экземпляр ApiService
        // Если вы хотите более сложную логику управления состоянием для пользователя,
        // можно добавить ChangeNotifierProvider для UserProvider.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Можно добавить логику для проверки токена и автоматического входа
    // if (ApiService.token != null) {
    //   // Перейти на HomePage, если токен есть
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House Services App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: ApiService.token != null
          ? '/home'
          : '/login', // Выбор начального маршрута
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/home': (context) => const HomePage(),
        '/add-request': (context) => const AddRequestPage(),
        '/statistics': (context) => const StatisticsPage(),
        '/tenants': (context) => const TenantsPage()
      },
    );
  }
}
