import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:godrage/Screens/chat_page.dart';
import 'package:godrage/firebase_options.dart';
import 'package:godrage/providers/message_tab_provider.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => MessagesTabProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Godrej Hackathon',
        home: ChatPage(title: 'Godrej-Bot'),
      ),
    );
  }
}
