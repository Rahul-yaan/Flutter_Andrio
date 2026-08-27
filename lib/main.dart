import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'pages/logo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv loading error: $e");
  }
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFC0392B);

    return MaterialApp(
      title: 'StayEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
       useMaterial3: true,
       colorScheme: ColorScheme.fromSeed(
         seedColor: primaryColor,
         primary: primaryColor,
       ),
       // Centralized Poppins Typography & Font Family
       textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
       fontFamily: GoogleFonts.poppins().fontFamily,
       appBarTheme: AppBarTheme(
         backgroundColor: primaryColor,
         foregroundColor: Colors.white,
         elevation: 0,
         titleTextStyle: GoogleFonts.poppins(
           color: Colors.white,
           fontSize: 18,
           fontWeight: FontWeight.w600,
         ),
       ),
       inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: const Color(0xFFF9F9F9),
         hintStyle: GoogleFonts.poppins(
           color: const Color(0xFF888888),
           fontSize: 13,
         ),
         labelStyle: GoogleFonts.poppins(
           color: const Color(0xFF444444),
           fontSize: 13,
           fontWeight: FontWeight.w500,
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
         ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: primaryColor, width: 2),
         ),
         errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: Colors.red, width: 1),
         ),
         focusedErrorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: Colors.red, width: 2),
         ),
         contentPadding: const EdgeInsets.symmetric(
           horizontal: 16,
           vertical: 14,
         ),
       ),
      ),
      home: const LogoPage(),
    );
  }
}
