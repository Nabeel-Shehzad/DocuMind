import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialise Supabase
  await Supabase.initialize(
    url: 'https://ztuznjhjxbxedkqalyyk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0dXpuamhqeGJ4ZWRrcWFseXlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MjgyMTYsImV4cCI6MjA4OTQwNDIxNn0.w7FjxHBhL8GCthUYY2EbIzNMhG5lo_dbaA2F468QwXQ',
  );

  runApp(const DocuMindApp());
}
