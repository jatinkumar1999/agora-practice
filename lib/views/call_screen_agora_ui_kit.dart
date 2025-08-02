// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:flutter/material.dart';
//
// import 'call_screen.dart';
//
// class CallScreenAgoraUiKit extends StatefulWidget {
//   const CallScreenAgoraUiKit({super.key});
//
//   @override
//   State<CallScreenAgoraUiKit> createState() => _CallScreenAgoraUiKitState();
// }
//
// class _CallScreenAgoraUiKitState extends State<CallScreenAgoraUiKit> {
// // Instantiate the client
//   final AgoraClient client = AgoraClient(
//     agoraConnectionData: AgoraConnectionData(
//       appId: appId,
//       channelName: "video_chat_123",
//     ),
//   );
//   // Initialize the Agora Engine
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }
//
//   void initAgora() async {
//     await client.initialize();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             AgoraVideoViewer(client: client),
//             AgoraVideoButtons(client: client),
//           ],
//         ),
//       ),
//     );
//   }
// }
