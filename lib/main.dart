import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart' as login;
import 'screens/sign_up_screen.dart' as signup; // এখানে underscore (_) ঠিক আছে!
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp().then((value) {
    print("Firebase Initialized");
  }).catchError((error) {
    print("Firebase Initialization Error: $error");
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hostel Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return HomeScreen(); // User is logged in
          } else {
            return login.LoginScreen(); // User is not logged in
          }
        },
      ),
      routes: {
        '/login': (context) => login.LoginScreen(),
        '/signup': (context) => signup.SignUpScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
