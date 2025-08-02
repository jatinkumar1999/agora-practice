import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../call_comming_screen/call_coming_screen.dart';
import '../views/call_screen.dart';
import 'outgoing_call.dart';

String currentUser = '';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final userId1 = 'user1'; // Simulate unique IDs
  final userId2 = 'user2'; // Simulate unique IDs

  @override
  void initState() {
    super.initState();
    currentUser = userId1;
    supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId1)
        .listen((data) {
          log('calls Tabke while data=>${data}');
          var call;
          try {
            call = data.firstWhere(
              (c) => c['status'] == 'ringing',
            );

            if (call['status'] == 'ringing') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    callId: call['id'],
                    channelId: call['channel_id'],
                    callerId: call['caller_id'],
                  ),
                ),
              );
            }

            log('call==>>${call}');
          } catch (err) {
            call = null;
          }
        });

  /*   FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      log('event.body=>>${event?.event}');
      log('event.body=>>${event?.body}');
      switch (event!.event) {
        case Event.actionCallAccept:
          print('Call accepted!');
          // Navigate to AgoraCallScreen or similar
          break;
        case Event.actionCallDecline:
          print('Call declined.');
          // Update Supabase / backend to mark call rejected
          break;
        case Event.actionCallEnded:
          print('Call ended.');
          break;
        default:
          break;

        // case Event.actionCallIncoming:
        //   // TODO: received an incoming call
        //   break;
        // case Event.actionCallStart:
        //   // TODO: started an outgoing call
        //   // TODO: show screen calling in Flutter
        //   break;
        // case Event.actionCallAccept:
        //   // TODO: accepted an incoming call
        //   // TODO: show screen calling in Flutter
        //   break;
        // case Event.actionCallDecline:
        //   // TODO: declined an incoming call
        //   break;
        // case Event.actionCallEnded:
        //   // TODO: ended an incoming/outgoing call
        //   break;
        // case Event.actionCallTimeout:
        //   // TODO: missed an incoming call
        //   break;
        // case Event.actionCallCallback:
        //   // TODO: only Android - click action `Call back` from missed call notification
        //   break;
        // case Event.actionCallToggleHold:
        //   // TODO: only iOS
        //   break;
        // case Event.actionCallToggleMute:
        //   // TODO: only iOS
        //   break;
        // case Event.actionCallToggleDmtf:
        //   // TODO: only iOS
        //   break;
        // case Event.actionCallToggleGroup:
        //   // TODO: only iOS
        //   break;
        // case Event.actionCallToggleAudioSession:
        //   // TODO: only iOS
        //   break;
        // case Event.actionDidUpdateDevicePushTokenVoip:
        //   // TODO: only iOS
        //   break;
        // case Event.actionCallCustom:
        //   // TODO: for custom action
        //   break;
      }
    });
   */
  }

  void _startCall() async {
    // final chan = const Uuid().v4().substring(0, 8);
    final chan = 'video_chat_123';

    await supabase.from('calls').insert({
      'caller_id': userId1,
      'receiver_id': userId2,
      'channel_id': 'video_chat_123',
      'status': 'ringing',
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => OutgoingCallingScreen(
              callId: userId1, receiverId: userId2, channelId: chan)),
    );

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => AgoraCallScreen(channelId: chan)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startCall,
          child: const Text('Start Video Calling'),
        ),
      ),
    );
  }
}
