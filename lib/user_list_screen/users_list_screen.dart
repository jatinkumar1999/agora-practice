import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:agora_video_call_demo/authentication/login_screen.dart';
import 'package:agora_video_call_demo/home/notification_functions.dart';
import 'package:agora_video_call_demo/home/outgoing_call.dart';
import 'package:agora_video_call_demo/views/call_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  var supabase = Supabase.instance.client;
  late final StreamSubscription _subscription;
  late final StreamSubscription _subscriptionIncoming;
  String? callId;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final response = await Supabase.instance.client
        .from('users')
        .select()
        .neq('auth_id', currentUserId!)
        .order('created_at', ascending: false);

    return response;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      callHandler();
    });
  }

  Future<bool> isAndroid14Above() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // androidInfo.version.sdkInt -> Android SDK version number
      // Android 14 corresponds to API level 34
      return androidInfo.version.sdkInt > 34;
    }
    return false;
  }

  @override
  void dispose() {
    //   _subscription.cancel();

    super.dispose();
  }

  Future<void> callHandler() async {
    FlutterCallkitIncoming.requestFullIntentPermission();

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      log('FlutterCallkitIncoming.body=>>${event?.event}');
      log('FlutterCallkitIncoming.body=>>${event?.body['extra']}');
      switch (event!.event) {
        case Event.actionCallIncoming:
          final callId = event.body['extra']['callId'];
          _listenForCallComingResponse(callId);
          break;
        case Event.actionCallAccept:
          log('Call accepted!');
          _subscriptionIncoming.cancel();

          var call = await supabase
              .from('calls')
              .select()
              .eq('id', event.body['extra']['callId'])
              .single();
          callId = call['id'];

          if (call['caller_id'] != supabase.auth.currentUser!.id.toString()) {
            var response = await supabase
                .from('calls')
                .update({'status': 'accepted'})
                .eq('id', call['id'])
                .select()
                .single();

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgoraCallScreen(
                    callId: response['id'],
                    channelId: call['channel_id'],
                    callerId: response['caller_id'],
                    receiverId: response['receiver_id'],
                  ),
                ),
              );
            }
          }

          break;
        case Event.actionCallDecline:
          log('Call declined!');
          var call = await supabase
              .from('calls')
              .select()
              .eq('id', event.body['extra']['callId'])
              .single();

          log('call==>>$call');

          if (call['caller_id'] != supabase.auth.currentUser!.id.toString()) {
            await Supabase.instance.client
                .from('calls')
                .update({'status': 'rejected'}).eq('id', call['id']);
            await FlutterCallkitIncoming.endAllCalls();
            _subscriptionIncoming.cancel();
          }

          break;
        case Event.actionCallEnded:
          log('Call ended!');
          await FlutterCallkitIncoming.endAllCalls();
          _subscriptionIncoming.cancel();

          break;

        case Event.actionCallTimeout:
          log('Call Timeout!');

          log('Call declined!');
          var call = await supabase
              .from('calls')
              .select()
              .eq('id', event.body['extra']['callId'])
              .maybeSingle();

          log('call==>>$call');

          if (call?['caller_id'] != supabase.auth.currentUser!.id.toString()) {
            await Supabase.instance.client
                .from('calls')
                .update({'status': 'call-timeout'}).eq('id', call?['id']);
            await FlutterCallkitIncoming.endAllCalls();
            _subscriptionIncoming.cancel();
          }

          await FlutterCallkitIncoming.endAllCalls();
          _subscriptionIncoming.cancel();

          break;
        default:
          break;
      }
    });
  }

  void _listenForCallComingResponse(String id) {
    try {
      _subscriptionIncoming = Supabase.instance.client
          .from('calls')
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .listen((calls) async {
            if (calls.isEmpty) return;

            final call = calls.first;
            final status = call['status'];

            if (status == 'accepted') {
              await FlutterCallkitIncoming.endAllCalls();
              _subscriptionIncoming.cancel();
            } else if (status == 'rejected') {
              await FlutterCallkitIncoming.endAllCalls();
              _subscriptionIncoming.cancel();
            } else if (status == 'cancelled') {
              await FlutterCallkitIncoming.endAllCalls();
              _subscriptionIncoming.cancel();
            }
          });
    } catch (e) {
      log('specific error==>>$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          log("User popped the route with result: $result");
        } else {
          log("User tried to pop, but we blocked it.");
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("All Users"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ));
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(child: Text("No users found."));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  title: Text(user['email'] ?? 'No Email'),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () async {
                      try {
                        var channelName =
                            'channel_${DateTime.now().millisecondsSinceEpoch}';

                        var supabase = Supabase.instance.client;

                        final ongoingCall = await supabase
                            .from('calls')
                            .select()
                            .inFilter('status', ['ringing', 'accepted'])
                            .eq(
                              'receiver_id',
                              user['auth_id'],
                            )
                            .maybeSingle();

                        log('On GOIMG CALL==>>$ongoingCall');
                        if (ongoingCall != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User is busy on another call.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            return;
                          }
                        }

                        var call = await supabase
                            .from('calls')
                            .insert({
                              'caller_id':
                                  supabase.auth.currentUser!.id.toString(),
                              'receiver_id': user['auth_id'],
                              'channel_id': channelName,
                              'status': 'ringing',
                            })
                            .select()
                            .single();

                        await sendPushNotification(
                          token: user['device_token'] ?? '',
                          callId: call['id'],
                          callerId:
                              Supabase.instance.client.auth.currentUser!.id,
                        );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgoraCallScreen(
                                callId: call['id'],
                                receiverId: call['receiver_id'],
                                channelId: call['channel_id'],
                                callerId: call['caller_id'],
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        log('Error starting call: $e');
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
