import 'package:flutter/material.dart';
import 'package:expense_split/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_split/pages/auth_screen.dart';
import 'package:expense_split/pages/splash_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
        title: 'Expense Split',
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadZincColorScheme.dark(),
          // Example of custom font family
          // textTheme: ShadTextTheme(family: 'UbuntuMono'),
        ),
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadZincColorScheme.light(),
          // Example of custom font family
          // textTheme: ShadTextTheme(family: 'UbuntuMono'),
        ),
        home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (ctx, userSnapShot) {
              if (userSnapShot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (userSnapShot.hasData) {
                return const MyHomePage();
              }
              return AuthScreen();
            }));
  }
}
