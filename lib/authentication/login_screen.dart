import 'dart:developer';

import 'package:agora_video_call_demo/authentication/sigin_up_screen.dart';
import 'package:agora_video_call_demo/fcm/fcm.dart';
import 'package:agora_video_call_demo/user_list_screen/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agora_video_call_demo/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      if (response.session != null) {
        // Insert into "users" table
        var deviceToken = await FCM().getfcmToken();

        log('deviceToken==>>$deviceToken');

        final authId = response.session!.user.id;

// 1. Check if user exists
        final existingUser = await Supabase.instance.client
            .from('users')
            .select()
            .eq('auth_id', authId)
            .maybeSingle();

        log('existingUser==>$existingUser');

        if (existingUser != null) {
          // 2. Update if exists
          var resoord = await Supabase.instance.client
              .from('users')
              .upsert({
                'device_token': deviceToken,
              })
              .eq('auth_id', authId)
              .select()
              .single();
          log('resoord==>$resoord');
        } else {
          // 3. Insert if not exists
          await Supabase.instance.client.from('users').insert({
            'auth_id': authId,
            'email': email,
            'device_token': deviceToken,
          });
        }

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const UsersListScreen()));
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text('Don’t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
