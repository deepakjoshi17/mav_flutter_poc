import 'package:flutter/material.dart';
import 'package:mav_flutter/home_screen.dart';
import 'package:mav_flutter/preview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MeetingScreen(),
    );
  }
}

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MaterialButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PreviewScreen()));
          },
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.blue,
          textColor: Colors.white,
          padding: const EdgeInsets.all(16),
          elevation: 5,
          highlightElevation: 10,
          disabledElevation: 0,
          hoverElevation: 5,
          focusElevation: 5,
          minWidth: 100,
          height: 50,
          splashColor: Colors.redAccent,
          highlightColor: Colors.greenAccent,
          focusColor: Colors.yellowAccent,
          child: Text("Join meeting"),
        ),
      ),
    );
  }
}
