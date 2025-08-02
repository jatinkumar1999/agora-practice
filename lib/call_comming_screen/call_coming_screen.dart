import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String callerId;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.channelId,
    required this.callerId,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _listenForCallResponse();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _listenForCallResponse() {
    _subscription = Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId)
        .order('created_at', ascending: false) // 👈 Order latest first

        .listen((calls) {
          log('Full Data==>>${calls}');
          if (calls.isEmpty) return;

          log('IncomingCallScreen=>>${calls}');

          final call = calls.first;
          final status = call['status'];

          log('status IncomingCallScreen=>>${status}');

          if (status == 'cancelled') {
            _subscription.cancel();
            Navigator.pop(context);
          }
        });
  }

  //TODO:Call Accept Reject Functions
  Future<void> _acceptCall(BuildContext context) async {
    var response = await Supabase.instance.client
        .from('calls')
        .update({'status': 'accepted'})
        .eq('id', widget.callId)
        .select()
        .single();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AgoraCallScreen(
          callId: response['id'],
          channelId: widget.channelId,
          callerId: response['caller_id'],
          receiverId: response['receiver_id'],
        ),
      ),
    );
  }

  Future<void> _rejectCall(BuildContext context) async {
    await Supabase.instance.client
        .from('calls')
        .update({'status': 'rejected'}).eq('id', widget.callId);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.call, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              Text(
                '${widget.callerId} is calling...',
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.call),
                    label: const Text("Accept"),
                    onPressed: () => _acceptCall(context),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.call_end),
                    label: const Text("Reject"),
                    onPressed: () => _rejectCall(context),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
