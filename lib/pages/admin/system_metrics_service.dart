import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/services/fat_secret_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class SystemMetricsService {
  static Future<Map<String, dynamic>> getFirebaseHealthStatus() async {
    try {
      final startTime = DateTime.now();

      // Test Auth
      final auth = FirebaseAuth.instance;
      final authUser = auth.currentUser;
      final authStatus = authUser != null ? 'Connected' : 'No active user';

      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      final testTime = DateTime.now();
      await firestore.collection('health_check').doc('test').set({
        'timestamp': testTime,
      });
      await firestore.collection('health_check').doc('test').delete();

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      // Get Firestore stats
      final usersCount = await _getCollectionCount('Users');
      final foodLogsCount = await _getCollectionCount('food_logs');

      return {
        'status': 'Healthy',
        'response_time_ms': responseTime,
        'auth_status': authStatus,
        'firestore_status': 'Connected',
        'users_count': usersCount,
        'food_logs_count': foodLogsCount,
        'last_checked': DateTime.now(),
        'error': null,
      };
    } catch (e) {
      return {
        'status': 'Unhealthy',
        'response_time_ms': null,
        'auth_status': 'Error',
        'firestore_status': 'Error',
        'users_count': 0,
        'food_logs_count': 0,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<int?> _getCollectionCount(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .count()
          .get();
      return snapshot.count;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getGeminiStatus() async {
    try {
      final startTime = DateTime.now();

      // Test Gemini API
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      final isAvailable = response.statusCode == 200;

      return {
        'status': isAvailable ? 'Connected' : 'Unavailable',
        'response_time_ms': responseTime,
        'last_checked': DateTime.now(),
        'error': !isAvailable ? 'API not responding properly' : null,
      };
    } on TimeoutException {
      return {
        'status': 'Timeout',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': 'Request timed out',
      };
    } catch (e) {
      return {
        'status': 'Unavailable',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getDeepSeekStatus() async {
    try {
      final startTime = DateTime.now();

      // Test DeepSeek API
      final response = await http.get(
        Uri.parse('https://api.deepseek.com/v1/models'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['DEEPSEEK_API_KEY']}',
        },
      );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      final isAvailable =
          response.statusCode == 200 && response.body.contains('deepseek');

      return {
        'status': isAvailable ? 'Connected' : 'Unavailable',
        'response_time_ms': responseTime,
        'last_checked': DateTime.now(),
        'error': !isAvailable ? 'API not responding properly' : null,
      };
    } catch (e) {
      return {
        'status': 'Unavailable',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getFatSecretStatus() async {
    try {
      final startTime = DateTime.now();

      // Test FatSecret API
      final service = FatSecretApiService();
      final result = await service.searchFood('apple').timeout(
            const Duration(seconds: 10),
            onTimeout: () => [],
          );

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      final isConnected = result != null;
      final status = isConnected ? 'Connected' : 'Limited';

      return {
        'status': status,
        'response_time_ms': responseTime,
        'last_checked': DateTime.now(),
        'error': !isConnected ? 'No response from API' : null,
      };
    } on TimeoutException {
      return {
        'status': 'Timeout',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': 'Request timed out',
      };
    } catch (e) {
      return {
        'status': 'Unavailable',
        'response_time_ms': null,
        'last_checked': DateTime.now(),
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getSystemMetrics() async {
    final firebaseHealth = await getFirebaseHealthStatus();
    final deepSeekStatus = await getDeepSeekStatus();
    final fatSecretStatus = await getFatSecretStatus();
    final geminiStatus = await getGeminiStatus();

    return {
      'firebase': firebaseHealth,
      'deepseek': deepSeekStatus,
      'fatsecret': fatSecretStatus,
      'gemini': geminiStatus,
      'app_version': '1.0.0',
      'timestamp': DateTime.now(),
      'device_platform': 'Flutter',
    };
  }
}
