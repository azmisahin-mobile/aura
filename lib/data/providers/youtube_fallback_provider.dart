import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';
import '../engine/api_resolver_engine.dart';

/// Bu Provider, Piped çöktüğünde Invidious'a, Invidious çökerse başka bir node'a geçer.
class YouTubeFallbackProvider implements IAudioProvider {
  final ApiResolverEngine _resolver;
  final http.Client _client = http.Client();

  YouTubeFallbackProvider(this._resolver);

  // En stabil Piped instance'ları
  final List<String> _pipedInstances = [
    "pipedapi.adminforge.de",
    "pipedapi.syncpundit.io",
    "pipedapi.kavin.rocks",
    "pipedapi.tokhmi.xyz"
  ];

  // Alternatif Invidious instance'ları
  final List<String> _invidiousInstances = [
    "yewtu.be",
    "inv.nadeko.net",
    "invidious.nerdvpn.de"
  ];

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    // 1. Önce Piped API'yi Dene
    try {
      final bestPiped = await _resolver.getFastestInstance(
        cacheKey: 'piped_best_node',
        instances: _pipedInstances,
        healthPath: '/trending', // Piped health check
      );
      
      final streams = await _fetchFromPiped(bestPiped, tag);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [YOUTUBE] Tüm Piped instance\'ları çöktü: $e');
    }

    // 2. Piped İşe Yaramazsa Invidious API'ye Geç
    debugPrint('🛡️ [YOUTUBE] Invidious (Fallback) devrede...');
    try {
      final bestInvidious = await _resolver.getFastestInstance(
        cacheKey: 'invidious_best_node',
        instances: _invidiousInstances,
        healthPath: '/api/v1/trending', // Invidious health check
      );

      final streams = await _fetchFromInvidious(bestInvidious, tag);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [YOUTUBE] Invidious instance\'ları da çöktü: $e');
    }

    throw Exception("YouTube altyapısı (Piped & Invidious) tamamen devre dışı.");
  }

  Future<List<AudioStream>> _fetchFromPiped(String instance, String tag) async {
    final searchUri = Uri.https(instance, '/search', {'q': '$tag ambient music', 'filter': 'music_songs'});
    final searchRes = await _client.get(searchUri).timeout(const Duration(seconds: 4));
    
    if (searchRes.statusCode != 200) return [];

    final items = jsonDecode(searchRes.body)['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return [];

    List<AudioStream> streams = [];
    for (int i = 0; i < (items.length > 2 ? 2 : items.length); i++) {
      final videoId = items[i]['url'].toString().replaceAll('/watch?v=', '');
      final streamUri = Uri.https(instance, '/streams/$videoId');
      final streamRes = await _client.get(streamUri).timeout(const Duration(seconds: 4));
      
      if (streamRes.statusCode != 200) continue;
      
      final audioStreams = jsonDecode(streamRes.body)['audioStreams'] as List<dynamic>? ?? [];
      if (audioStreams.isNotEmpty) {
        audioStreams.sort((a, b) => (a['bitrate'] ?? 0).compareTo(b['bitrate'] ?? 0));
        streams.add(AudioStream(
          name: items[i]['title'] ?? 'YouTube (Piped)',
          url: audioStreams.first['url'],
          provider: 'Piped ($instance)',
        ));
      }
    }
    return streams;
  }

  Future<List<AudioStream>> _fetchFromInvidious(String instance, String tag) async {
    final searchUri = Uri.https(instance, '/api/v1/search', {'q': '$tag ambient music', 'type': 'video'});
    final searchRes = await _client.get(searchUri).timeout(const Duration(seconds: 4));
    
    if (searchRes.statusCode != 200) return [];

    final items = jsonDecode(searchRes.body) as List<dynamic>? ?? [];
    if (items.isEmpty) return [];

    List<AudioStream> streams = [];
    for (int i = 0; i < (items.length > 2 ? 2 : items.length); i++) {
      final videoId = items[i]['videoId'];
      final streamUri = Uri.https(instance, '/api/v1/videos/$videoId');
      final streamRes = await _client.get(streamUri).timeout(const Duration(seconds: 4));
      
      if (streamRes.statusCode != 200) continue;
      
      final formatStreams = jsonDecode(streamRes.body)['adaptiveFormats'] as List<dynamic>? ?? [];
      final audios = formatStreams.where((f) => f['type'].toString().contains('audio')).toList();
      
      if (audios.isNotEmpty) {
        streams.add(AudioStream(
          name: items[i]['title'] ?? 'YouTube (Invidious)',
          url: audios.first['url'],
          provider: 'Invidious ($instance)',
        ));
      }
    }
    return streams;
  }
}