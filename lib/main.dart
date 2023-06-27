import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:janus_client/janus_client.dart';
import 'package:screen_sharing_call/widgets/JanusScreenSharing.dart';
import 'conf.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketJanusTransport? websocketTransport;
  JanusClient? client;
  JanusSession? session;
  JanusVideoRoomPlugin? videoRoomPlugin;
  int roomId = 1234;

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white10,
                  child: JanusScreenSharing(
                    isPublisher: true,
                    roomId: roomId,
                    serverUrl: servermap['janus_ws']!,
                    username: "customer",
                  )));
        },
      ),
    ));
  }
}
