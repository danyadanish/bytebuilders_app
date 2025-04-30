import 'package:flutter/material.dart';
import 'package:khaberny/messaging/messageHomepage.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData customTheme = ThemeData(
  primaryColor: Color(0xFF161B33), // Dark blue
  scaffoldBackgroundColor: Color(0xFF161B33), //Dark blue
  textTheme: TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFEFCFB), // Black
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF6C91BF), // Light Blue
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF161B33), // Dark blue
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFEFCFB), // White
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFA52422), // Red
      foregroundColor: Color(0xFFFEFCFB), // White
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: customTheme,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body:
          MessageHomepage(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
