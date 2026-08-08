import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'src/app_v5.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;

  try {
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

      // Firestore persistence is useful for farmers working with unreliable
      // connectivity. If a device cannot apply this setting, the app should
      // still start and use Firestore normally instead of crashing at launch.
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (error, stackTrace) {
        debugPrint('Firestore offline settings could not be applied: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  } catch (error, stackTrace) {
    startupError = error;
    debugPrint('FarmersHub startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  if (startupError != null) {
    runApp(StartupFailureApp(error: startupError.toString()));
    return;
  }

  runApp(const FarmersHubAppV5());
}

class StartupFailureApp extends StatelessWidget {
  final String error;

  const StartupFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, size: 64, color: Color(0xFF2E7D32)),
                        const SizedBox(height: 16),
                        const Text(
                          'FarmersHub could not start',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Please connect to the internet once, close the app, and open it again. If this screen returns, send a screenshot to the FarmersHub beta team.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          'Startup detail: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
