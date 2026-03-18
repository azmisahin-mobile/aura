import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class RadioBrowserProvider implements IAudioProvider {
  final List<String> _nodes = [
    "https://de1.api.radio-browser.info",
    "https://nl1.api.radio-browser.info"
  ];

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    final headers = {'User-Agent': 'Aura/1.2.0'};
    
    for (String baseUrl in _nodes) {
      final uri = Uri.parse("$baseUrl/json/stations/search?tag=$tag&limit=15&hidebroken=true&order=random");
      try {
        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (data.isEmpty) continue;
          return data.map((s) => AudioStream(
            name: s['name']?.toString().trim() ?? 'Bilinmeyen Sinyal',
            url: s['url_resolved'] ?? s['url'],
            provider: 'RadioBrowser',
          )).toList();
        }
      } catch (_) {}
    }
    throw Exception("Radyo sunucuları ulaşılamaz.");
  }
}