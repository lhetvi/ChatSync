import 'package:flutter/services.dart';

import 'screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

late Size mq;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enter in full screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // set fixed orientation
  // belowed used function return -> future
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((value) {
    _initializeFirebase();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
          iconTheme: IconThemeData(
            color: Colors.blue,
          ),
          titleTextStyle: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.normal,
              fontSize: 19
          ),
          backgroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(), //added const
    );
  }
}
  _initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }