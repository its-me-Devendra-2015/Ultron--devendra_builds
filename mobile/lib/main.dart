import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Environment can be supplied by the build/runtime in development.
  }
  runApp(const UltronMobileApp());
}

class UltronMobileApp extends StatelessWidget {
  const UltronMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ULTRON Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070506),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE51B2B),
          brightness: Brightness.dark,
          surface: const Color(0xFF12090B),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
