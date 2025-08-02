import 'dart:async';
import 'dart:developer';

import 'package:agora_video_call_demo/home/notification_functions.dart';
import 'package:agora_video_call_demo/user_list_screen/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../home/home_screen.dart';

const String appId = '88ebabb4bf1e4be184fa4dcd57e7a972';

String token =
    '007eJxTYJi9f2aHKvef27vTHlmdmnAggtVNUOEp+25bdQuxNxfXde9WYLCwSE1KTEoySUozTDVJSjW0MElLNElJTjE1TzVPtDQ3UuXty2gIZGRw/ruSkZEBAkF8PoayzJTU/PjkjMSSeEMjYwYGAN4YI4I=';

class AgoraCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final String callerId;
  final String receiverId;
  const AgoraCallScreen({
    super.key,
    required this.channelId,
    required this.callId,
    required this.callerId,
    required this.receiverId,
  });

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState
    extends State<AgoraCallScreen> /* with WidgetsBindingObserver */ {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _remoteVideoMuted = false;
  bool isLoadAgora = false;
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isRemoteUserVideoEnable = true;
  int playbackVolume = 100;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    log('widget.callId=>>${widget.callId}');

    setTheSystemNavBarToWhite();
    _loadAgora(true);
    // WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await WakelockPlus.enable();

      await _startVideoCalling();
      _listenForCallResponse();
      _loadAgora(false);

      // setState(() {});
    });
  }

  void _listenForCallResponse() {
    _subscription = Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callId)
        .listen((calls) {
          if (calls.isEmpty) return;

          final call = calls.first;
          final status = call['status'];
          log('CALL SCREEN STATUS=>>$calls');

          if (status == 'accepted') {
          } else if (status == 'rejected') {
            Navigator.pop(context);
          } else if (status == 'ended') {
            Navigator.pop(context);
          }
        });
  }

  void setTheSystemNavBarToWhite() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white, // Bottom nav bar color
        systemNavigationBarIconBrightness: Brightness.dark, // Icon color
        statusBarColor:
            Colors.transparent, // Optional: make status bar transparent
        statusBarIconBrightness: Brightness.dark, // Optional: status bar icons
      ),
    );
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.detached) {
  //     cancelCallBeforeKill(); // 🛑 cancel the call on app kill or quit
  //     // WidgetsBinding.instance.removeObserver(this);

  //     _cleanupAgoraEngine();
  //   }
  // }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);

    _cleanupAgoraEngine();

    _subscription.cancel();
    super.dispose();
  }

  void _loadAgora(bool load) {
    setState(() {
      isLoadAgora = load;
    });
  }

  Future<void> cancelCallBeforeKill() async {
    // await Supabase.instance.client
    //     .from('calls')
    //     .update({'status': 'cancelled'}).eq('id', widget.callId);

    // await Supabase.instance.client
    //     .from('calls')
    //     .update({'status': 'cancelled'}).eq('id', widget.callId);

    var response = await Supabase.instance.client
        .from('calls')
        .update({'status': 'ended'})
        .eq('id', widget.callId)
        .select()
        .single();

    // var callStuff = await Supabase.instance.client
    //     .from('calls')
    //     .select()
    //     .eq('id', widget.callId)
    //     .single();

    log('responseresponseresponseresponse=>>$response');
  }

  // Initializes Agora SDK
  Future<void> _startVideoCalling() async {
    // var uid = Supabase.instance.client.auth.currentUser!.id;
    // var fetcedToken = await fetchAgoraToken(
    //   widget.channelId,
    //   uid,
    //   // widget.callerId == 'user1' ? widget.receiverId : widget.callerId,
    // );

    // log('token==>>$fetcedToken');
    // setState(() {
    //   token = fetcedToken ?? '';
    // });

    await _requestPermissions();

    await _initializeAgoraVideoSDK();
    await _setupLocalVideo();
    await _joinChannel();
    _setupEventHandlers();

    _loadAgora(false);
  }

  //1. Set up the Agora RTC engine instance
  Future<void> _initializeAgoraVideoSDK() async {
    _engine = createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    setState(() {});
  }

  //2. Join a channel
  Future<void> _joinChannel() async {
    log('token==>>$token');

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelId,
      options: const ChannelMediaOptions(
        autoSubscribeVideo:
            true, // Automatically subscribe to all video streams
        autoSubscribeAudio:
            true, // Automatically subscribe to all audio streams
        publishCameraTrack: true, // Publish camera-captured video
        publishMicrophoneTrack: true, // Publish microphone-captured audio
        // Use clientRoleBroadcaster to act as a host or clientRoleAudience for audience
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  //3. Register an event handler for Agora RTC
  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (ErrorCodeType err, String msg) {
          log('[onError] err: $err, msg: $msg');
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          log('[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        },
        onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
          log('[onUserJoined] connection: ${connection.toJson()} remoteUid: $rUid elapsed: $elapsed');

          if (_remoteUid == null) {
            setState(() {
              _remoteUid = rUid;
            });
          }
        },
        onUserMuteVideo: (RtcConnection connection, int uid, isMuted) {
          log("User $uid video muted: $isMuted");
          setState(() {
            _remoteVideoMuted = isMuted;
          });
        },
        onUserMuteAudio: (RtcConnection connection, int uid, isMuted) {
          log("User $uid Audio muted: $isMuted");
          // setState(() {
          //   _remoteVideoMuted = isMuted;
          // });
        },
        onUserOffline:
            (RtcConnection connection, int rUid, UserOfflineReasonType reason) {
          log('[onUserOffline] connection: ${connection.toJson()}  rUid: $rUid reason: $reason');
          setState(() {
            _remoteUid = null;
            Navigator.pop(context);
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          log('[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
          setState(() {
            // isJoined = false;
          });
        },
        onRemoteVideoStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed) {
          log('[onRemoteVideoStateChanged] connection: ${connection.toJson()} remoteUid: $remoteUid state: $state reason: $reason elapsed: $elapsed');
        },
      ),
    );
  }

  Future<void> _setupLocalVideo() async {
    // The video module and preview are disabled by default.
    await _engine.enableVideo();
    await _engine.startPreview();
  }

  // Displays the local user's video view using the Agora engine.
  Widget _localVideo() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine, // Uses the Agora engine instance
        useAndroidSurfaceView: true,
        useFlutterTexture: true,
        canvas: const VideoCanvas(
          uid: 0, // Specifies the local user
          renderMode:
              RenderModeType.renderModeHidden, // Sets the video rendering mode
        ),
      ),
    );
  }

  // If a remote user has joined, render their video, else display a waiting message
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine, // Uses the Agora engine instance
          useAndroidSurfaceView: true,
          useFlutterTexture: true,
          canvas: VideoCanvas(uid: _remoteUid), // Binds the remote user's video
          connection: RtcConnection(
            channelId: widget.channelId,
          ), // Specifies the channel
        ),
      );
    } else {
      return const Text(
        'Waiting for remote user to join...',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

// Leaves the channel and releases resources
  Future<void> _cleanupAgoraEngine() async {
    // await WakelockPlus.disable();
    await cancelCallBeforeKill();

    await _engine.leaveChannel();
    await _engine.release();
  }

  //Mute local  user  audio
  Future<void> _muteRemoteUser({required bool shouldMute}) async {
    setState(() {
      isMuted = !isMuted;
    });

    await _engine.muteRemoteAudioStream(mute: isMuted, uid: _remoteUid ?? 0);
  }

  Future<void> _setVolume(int volume) async {
    setState(() => playbackVolume = volume);
    await _engine.adjustRecordingSignalVolume(volume);
  }

  //Mute local  user  camera view
  Future<void> _setShowFace() async {
    setState(() => isRemoteUserVideoEnable = !isRemoteUserVideoEnable);
    await _engine.muteLocalVideoStream(!isRemoteUserVideoEnable);
  }

  // Define initial local view position
  Alignment _localViewAlignment = Alignment.topLeft;
  Widget _buildCornerTarget(Alignment alignment) {
    // For bottom corners: add 200 bottom padding using Positioned
    // if (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) {
    //   return Positioned(
    //     left: alignment == Alignment.bottomLeft ? 20 : null,
    //     right: alignment == Alignment.bottomRight ? 20 : null,
    //     bottom: 200,
    //     child: DragTarget<String>(
    //       onWillAccept: (data) => data == 'local_view',
    //       onAccept: (_) {
    //         setState(() {
    //           _localViewAlignment = alignment;
    //         });
    //       },
    //       builder: (context, candidateData, rejectedData) {
    //         return const SizedBox(
    //           width: 140,
    //           height: 180,
    //         );
    //       },
    //     ),
    //   );
    // }

    return Align(
      alignment: alignment,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (data) => data == 'local_view',
        onAcceptWithDetails: (_) {
          setState(() {
            _localViewAlignment = alignment;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return const SizedBox(
            width: 140,
            height: 180,
            // Optional: Show corner highlight during drag
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return isLoadAgora
        ? const Scaffold(backgroundColor: Colors.white)
        : Scaffold(
            appBar: AppBar(
              title: Text(currentUser.toLowerCase() ==
                      widget.callerId.toLowerCase().trim()
                  ? widget.receiverId
                  : widget.callerId),
            ),
            body: isLoadAgora
                ? const SizedBox()
                : SizedBox(
                    width: size.width,
                    child: _remoteUid == null
                        ? Stack(
                            children: [
                              _localVideo(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: size.width,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black,
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: Offset(-1, -1),
                                          )
                                        ]),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            log('kill kill kill kill kill');

                                            await _cleanupAgoraEngine();
                                            await Supabase.instance.client
                                                .from('calls')
                                                .update({
                                              'status': 'cancelled'
                                            }).eq('id', widget.callId);
                                          },
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.call_end,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Center(
                                  child: _remoteVideoMuted
                                      ? VideoMuteRemoteUserView(
                                          remoteUser:
                                              currentUser.toLowerCase() ==
                                                      widget.callerId
                                                          .toLowerCase()
                                                          .trim()
                                                  ? widget.receiverId
                                                  : widget.callerId,
                                          isVideoEnabled: _remoteVideoMuted,
                                          onTap: () async =>
                                              await _setShowFace(),
                                        )
                                      : _remoteVideo()),

                              // Drag targets
                              _buildCornerTarget(Alignment.topLeft),
                              _buildCornerTarget(Alignment.topRight),
                              _buildCornerTarget(Alignment.bottomLeft),
                              _buildCornerTarget(Alignment.bottomRight),
                              // Align(
                              //   alignment: Alignment.topLeft,
                              //   child: Padding(
                              //     padding: const EdgeInsets.only(
                              //       top: 10,
                              //       left: 10,
                              //     ),
                              //     child: Column(
                              //       children: [
                              //         ClipRRect(
                              //           borderRadius: BorderRadius.circular(10),
                              //           child: SizedBox(
                              //             width: 100,
                              //             height: 150,
                              //             child: Center(
                              //               child: _localVideo(),
                              //             ),
                              //           ),
                              //         ),
                              //         Text(
                              //           currentUser.toLowerCase() ==
                              //                   widget.callerId.toLowerCase().trim()
                              //               ? widget.callerId
                              //               : widget.receiverId,
                              //           maxLines: 1,
                              //           overflow: TextOverflow.ellipsis,
                              //           style: const TextStyle(fontSize: 12),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),

                              // Draggable local view
                              Align(
                                alignment: Alignment.topLeft,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 100,
                                    height: 150,
                                    child: Center(
                                      child: _localVideo(),
                                    ),
                                  ),
                                ),
                              ),

                              /*       Align(
                    alignment: _localViewAlignment,
                    child: Draggable<String>(
                      data: 'local_view',
                      feedback: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 100,
                            height: 150,
                            child: Center(
                              child: _localVideo(),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 100,
                            height: 150,
                            child: Center(
                              child: _localVideo(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

             */
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: size.width,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black,
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: Offset(-1, -1),
                                          )
                                        ]),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 10),
                                        // FloatingActionButton(
                                        //   elevation: 0.0,
                                        //   backgroundColor: !isMuted ? Colors.blue : null,
                                        //   onPressed: () async =>
                                        //       await _muteRemoteUser(shouldMute: true),
                                        //   child: Icon(
                                        //     isMuted ? Icons.mic_off : Icons.mic,
                                        //     color: !isMuted ? Colors.white : Colors.black,
                                        //   ),
                                        // ),
                                        GestureDetector(
                                          onTap: () async =>
                                              await _muteRemoteUser(
                                                  shouldMute: true),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: isRemoteUserVideoEnable
                                                  ? Colors.blue
                                                  : Colors.grey
                                                      .withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              isMuted
                                                  ? Icons.mic_off
                                                  : Icons.mic,
                                              color: !isMuted
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),
                                        // FloatingActionButton(
                                        //   elevation: 0.0,
                                        //   backgroundColor:
                                        //       isRemoteUserVideoEnable ? Colors.blue : null,
                                        //   onPressed: () async => await _setShowFace(),
                                        //   child: Icon(
                                        //     isRemoteUserVideoEnable
                                        //         ? Icons.videocam
                                        //         : Icons.videocam_off,
                                        //     color: isRemoteUserVideoEnable
                                        //         ? Colors.white
                                        //         : Colors.black,
                                        //   ),
                                        // ),

                                        GestureDetector(
                                          onTap: () async =>
                                              await _setShowFace(),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: isRemoteUserVideoEnable
                                                  ? Colors.blue
                                                  : Colors.grey
                                                      .withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              isRemoteUserVideoEnable
                                                  ? Icons.videocam
                                                  : Icons.videocam_off,
                                              color: isRemoteUserVideoEnable
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),
                                        // FloatingActionButton(
                                        //   elevation: 0.0,
                                        //   backgroundColor: Colors.red,
                                        //   onPressed: () => Navigator.pop(context),
                                        //   child: const Icon(
                                        //     Icons.call_end,
                                        //     color: Colors.white,
                                        //   ),
                                        // ),
                                        GestureDetector(
                                          onTap: () async {
                                            // await _cleanupAgoraEngine();
                                            await cancelCallBeforeKill();
                                          },
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.call_end,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                  ),
          );
  }
}

class VideoMuteRemoteUserView extends StatelessWidget {
  final bool isVideoEnabled;
  final VoidCallback onTap;
  final String remoteUser;
  const VideoMuteRemoteUserView({
    super.key,
    required this.isVideoEnabled,
    required this.onTap,
    required this.remoteUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 100,
            child: Icon(
              isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remoteUser,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
