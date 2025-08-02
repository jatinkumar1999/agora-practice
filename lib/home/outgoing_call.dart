import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../views/call_screen.dart';

class OutgoingCallingScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String receiverId;

  const OutgoingCallingScreen({
    super.key,
    required this.callId,
    required this.channelId,
    required this.receiverId,
  });

  @override
  State<OutgoingCallingScreen> createState() => _OutgoingCallingScreenState();
}

class _OutgoingCallingScreenState extends State<OutgoingCallingScreen> {
  late final StreamSubscription _subscription;

  String? callId;
  @override
  void initState() {
    super.initState();
    _listenForCallResponse();
  }

  void _listenForCallResponse() {
    _subscription = Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('caller_id', widget.callId)
        .order('created_at', ascending: false) // 👈 Order latest first

        .listen((calls) {
          if (calls.isEmpty) return;

          log('OutgoingCallingScreen=>>$calls');

          final call = calls.first;
          final status = call['status'];
          callId = call['id'];
          if (status == 'accepted') {
            _subscription.cancel();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AgoraCallScreen(
                  callId: callId ?? "",
                  channelId: widget.channelId,
                  callerId: call['caller_id'],
                  receiverId: call['receiver_id'],
                ),
              ),
            );
          } else if (status == 'rejected') {
            _subscription.cancel();
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Call rejected")),
            // );
            Navigator.pop(context); // Close ringing screen
          }
        });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ring_volume, size: 90, color: Colors.greenAccent),
            const SizedBox(height: 30),
            Text(
              "Calling ${widget.receiverId}...",
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_end),
              label: const Text("Cancel"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await Supabase.instance.client
                    .from('calls')
                    .update({'status': 'cancelled'}).eq('id', callId ?? "");
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}
