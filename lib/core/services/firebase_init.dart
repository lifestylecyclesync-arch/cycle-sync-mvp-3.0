import 'package:firebase_core/firebase_core.dart';
import 'package:cycle_sync_mvp_2/firebase_options.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Initialize Firebase with the configuration from firebase_options.dart
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.i('✅ Firebase initialized successfully');
  } catch (e) {
    _logger.e('❌ Firebase initialization failed: $e');
    rethrow;
  }
}
