
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../call_comming_screen/call_coming_screen.dart';

class CallListenerWrapper extends StatefulWidget {
  final Widget child;
  final String myUserId;

  const CallListenerWrapper({
    Key? key,
    required this.child,
    required this.myUserId,
  }) : super(key: key);

  @override
  State<CallListenerWrapper> createState() => _CallListenerWrapperState();
}

class _CallListenerWrapperState extends State<CallListenerWrapper> {
  @override
  void initState() {
    super.initState();
    _listenForCalls();
  }

  void _listenForCalls() {
    Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', widget.myUserId)
        // .eq('status', 'ringing')
        .listen((calls) {
      if (calls.isNotEmpty) {
        final call = calls.first;

        // Prevent showing screen multiple times
        if (ModalRoute.of(context)?.isCurrent != true) return;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
