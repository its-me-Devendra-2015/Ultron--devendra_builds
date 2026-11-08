import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UltronSession {
  const UltronSession({
    required this.serverUrl,
    required this.roomName,
    required this.participantToken,
    required this.expiresAt,
  });

  final String serverUrl;
  final String roomName;
  final String participantToken;
  final DateTime expiresAt;

  factory UltronSession.fromJson(Map<String, dynamic> json) {
    return UltronSession(
      serverUrl: json['server_url'] as String,
      roomName: json['room_name'] as String,
      participantToken: json['participant_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class UltronApi {
  UltronApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final base = dotenv.env['ULTRON_API_BASE_URL']?.trim();
    if (base == null || base.isEmpty || base.contains('your-ultron-api')) {
      throw const FormatException(
        'Set ULTRON_API_BASE_URL in mobile/.env before connecting.',
      );
    }
    return Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}$path');
  }

  Future<UltronSession> createSession(String mode) async {
    if (mode != 'companion' && mode != 'independent') {
      throw ArgumentError.value(mode, 'mode');
    }
    final response = await _client
        .post(
          _uri('/api/mobile/session'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'mode': mode}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('ULTRON backend error (${response.statusCode}): ${response.body}');
    }
    return UltronSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() => _client.close();
}
