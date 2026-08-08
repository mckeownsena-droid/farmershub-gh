import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'src/app_v2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAbxq0GIyW30edgLnNLiV6uXNKjSzeApJQ',
        authDomain: 'farmershub-gh-new.firebaseapp.com',
        projectId: 'farmershub-gh-new',
        storageBucket: 'farmershub-gh-new.firebasestorage.app',
        messagingSenderId: '379868120125',
        appId: '1:379868120125:android:2c6919c06deebda3be1654',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const FarmersHubApp());
}
