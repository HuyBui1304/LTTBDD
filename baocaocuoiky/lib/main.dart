import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/realtime_service.dart';
import 'services/sample_data_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timeout');
      },
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - Firebase might work with retry
  }
  
  // Initialize date formatting for Vietnamese
  try {
    await initializeDateFormatting('vi_VN', null).timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Date formatting initialization error: $e');
    // Continue anyway - app can work without Vietnamese date formatting
  }
  
  // Initialize sample data (users and subjects)
  // Kiểm tra xem đã có users chưa, nếu chưa có thì mới tạo
  // Điều này tránh tạo lại nhiều lần và rate limiting
  try {
    final hasUsers = await SampleDataService.instance.checkSampleUsersExist();
    if (!hasUsers) {
      debugPrint('Chưa có users mẫu, bắt đầu tạo tất cả dữ liệu mẫu...');
      await SampleDataService.instance.initializeAllSampleData();
    } else {
      debugPrint('Đã có users mẫu, chỉ kiểm tra và tạo subjects nếu chưa có...');
      // Chỉ tạo subjects nếu chưa có
      // initializeSampleUsers sẽ tự động bỏ qua nếu users đã tồn tại
      await SampleDataService.instance.initializeAllSampleData();
    }
  } catch (e) {
    debugPrint('Error initializing sample data: $e');
    // Continue anyway - app can work without sample data
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Điểm danh QR',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // Show loading only during app initialization
                if (authProvider.isInitializing) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Navigate based on auth state
                return RealtimeNotificationListener(
                  shouldMonitor: authProvider.isAuthenticated,
                  child: authProvider.isAuthenticated
                      ? const HomeScreen()
                      : const LoginScreen(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
