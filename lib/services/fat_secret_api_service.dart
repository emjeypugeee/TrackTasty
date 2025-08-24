import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FatSecretApiService extends ChangeNotifier {
  final String _consumerKey = dotenv.env['FATSECRET_API_CONSUMER_KEY']!;
  final String _consumerSecret =
      dotenv.env['FATSECRET_API_CONSUMER_KEY_SECRET']!;

  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.isEmpty) return [];

    final params = <String, String>{
      'method': 'foods.search',
      'search_expression': query,
      'format': 'json',
      'oauth_consumer_key': _consumerKey,
      'oauth_nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp':
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      'oauth_version': '1.0',
    };

    final signature = _generateOAuthSignature(
      'GET',
      'https://platform.fatsecret.com/rest/server.api',
      params,
      _consumerSecret,
    );

    params['oauth_signature'] = signature;

    final uri = Uri.https(
      'platform.fatsecret.com',
      '/rest/server.api',
      params,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final foods = data['foods']['food'] as List? ?? [];
      return foods.map((food) {
        if (food is Map<String, dynamic>) {
          return food;
        } else if (food is Map) {
          return Map<String, dynamic>.from(food);
        } else {
          return <String, dynamic>{};
        }
      }).toList();
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  String _generateOAuthSignature(
    String method,
    String url,
    Map<String, String> params,
    String consumerSecret,
  ) {
    final sortedParams = SplayTreeMap<String, String>.from(params);
    final paramString = sortedParams.keys
        .map((key) => '$key=${Uri.encodeComponent(sortedParams[key]!)}')
        .join('&');
    final baseString = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');
    final signingKey = '${Uri.encodeComponent(consumerSecret)}&';
    final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
    final signature = hmacSha1.convert(utf8.encode(baseString));
    return base64Encode(signature.bytes);
  }
}
