import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/janus_client.dart';
import 'ScreenSelectDialog.dart';

class JanusScreenSharing extends StatefulWidget {
  final int roomId;
  final String username;
  final String serverUrl;
  final bool isPublisher;

  const JanusScreenSharing(
      {super.key,
      required this.isPublisher,
      required this.username,
      required this.serverUrl,
      required this.roomId});

  @override
  State<JanusScreenSharing> createState() => _JanusScreenSharingState();
}

class _JanusScreenSharingState extends State<JanusScreenSharing> {
  WebSocketJanusTransport? websocketTransport;
  JanusClient? client;
  JanusSession? session;
  JanusVideoRoomPlugin? videoRoomPlugin;
  JanusVideoRoomPlugin? subscriberPlugin;
  CallKeepBaseConfig callKeepBaseConfig = CallKeepBaseConfig(
    appName: 'Screenshare',
    androidConfig: CallKeepAndroidConfig(
      logo: 'logo',
      notificationIcon: 'notification_icon',
      ringtoneFileName: 'ringtone.mp3',
      accentColor: '#34C7C2',
    ),
    iosConfig: CallKeepIosConfig(
      iconName: 'Icon',
      audioSessionMode: AvAudioSessionMode.videoChat,
      audioSessionActive: true,
      handleType: CallKitHandleType.generic,
      isVideoSupported: true,
    ),
  );
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  DesktopCapturerSource? selected_source_;
  String uuid = getUuid().v4();

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (mounted) {
      await initRenderers();
      await initializeJanus();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _stop();
    }
    _localRenderer.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
  }

  initializeJanus() async {
    websocketTransport = WebSocketJanusTransport(url: widget.serverUrl);
    client = JanusClient(transport: websocketTransport!);
    session = await client?.createSession();
  }

  handleJanusEvents() {
    videoRoomPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        print('joined user');
        (await videoRoomPlugin?.configure(
            bitrate: 3000000,
            sessionDescription: await videoRoomPlugin?.createOffer(
                audioRecv: false, videoRecv: false)));
      }
      if (data is VideoRoomLeavingEvent) {
        // unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        // unSubscribeTo(data.unpublished);
      }
      await videoRoomPlugin?.handleRemoteJsep(event.jsep);
    });
  }

  _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    // config and uuid are the only required parameters
    final config = CallKeepOutgoingConfig.fromBaseConfig(
        config: callKeepBaseConfig,
        uuid: uuid,
        handle: "screenshare",
        hasVideo: true,
        callerName: "Agent");
    await CallKeep.instance.startCall(config);
  }

  Future<void> shareScreenAndSendToJanus(BuildContext context) async {
    videoRoomPlugin = await session?.attach<JanusVideoRoomPlugin>();
    handleJanusEvents();
    await _initForegroundTask();
    if (WebRTC.platformIsDesktop) {
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (context) => ScreenSelectDialog(),
      );
      if (source != null) {
        await _shareScreenAndSendToJanus(source);
      }
    } else {
      if (WebRTC.platformIsAndroid) {
        // Android specific
        Future<void> requestBackgroundPermission([bool isRetry = false]) async {
          // Required for android screenshare.
          try {
            await FlutterForegroundTask.startService(
                notificationText: "Screensharing active",
                notificationTitle: "Screensharing");
          } catch (e) {
            if (!isRetry) {
              return await Future<void>.delayed(const Duration(seconds: 1),
                  () => requestBackgroundPermission(true));
            }
            print('could not publish video: $e');
          }
        }

        await requestBackgroundPermission();
      }
      await _shareScreenAndSendToJanus(null);
    }
  }

  Future<void> _shareScreenAndSendToJanus(DesktopCapturerSource? source) async {
    setState(() {
      selected_source_ = source;
    });
    try {
      Map<String, dynamic> mediaConstraints = {'video': true, 'audio': true};
      if (WebRTC.platformIsIOS) {
        mediaConstraints['video'] = {'deviceId': 'broadcast'};
      }
      if (WebRTC.platformIsDesktop) {
        mediaConstraints['video'] = {'deviceId': source?.id};
      }
      _localStream = await videoRoomPlugin?.initializeMediaDevices(
          mediaConstraints: mediaConstraints, useDisplayMediaDevices: true);
      _localStream?.getVideoTracks()[0].onEnded = () {
        print(
            'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
      };
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _inCalling = true;
    });
    await videoRoomPlugin?.joinPublisher(widget.roomId,
        displayName: widget.username);
  }

  Future _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
    await CallKeep.instance.endCall(uuid);
  }

  Future<void> _stop() async {
    try {
      if (kIsWeb) {
        _localStream?.getTracks().forEach((track) => track.stop());
      }
      await _localStream?.dispose();
      _localStream = null;
      _localRenderer.srcObject = null;
      await _stopForegroundTask();
      await videoRoomPlugin?.hangup();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _hangUp() async {
    await _stop();
    setState(() {
      _inCalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPublisher) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              height: 200, width: 200, child: RTCVideoView(_localRenderer)),
          IconButton(
              onPressed: () async {
                if (_inCalling) {
                  await _hangUp();
                  return;
                }
                await shareScreenAndSendToJanus(context);
              },
              icon: Icon(Icons.screen_share))
        ],
      );
    }
    return Container();
  }
}
