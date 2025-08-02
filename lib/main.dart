import 'package:agora_video_call_demo/authentication/login_screen.dart';
import 'package:agora_video_call_demo/home/home_screen.dart';
import 'package:agora_video_call_demo/user_list_screen/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fcm/fcm.dart';

const String SUPABASE_URL = "https://uwbsdodldotacynpluvb.supabase.co";
const String SUPABASE_ANON_KEY =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3YnNkb2RsZG90YWN5bnBsdXZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4MjY1NDIsImV4cCI6MjA2MTQwMjU0Mn0.Mj4VU8YQgANygli74PiBCdDQRSlswtrEer0Q5EeK4gE";

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  await FCM().initFcm();
  await FCM().listenNotification();
  await FCM().getfcmToken();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agora Calling Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginScreen()
          : const UsersListScreen(),
      // home: const HomeScreen(),
    );
  }
}
