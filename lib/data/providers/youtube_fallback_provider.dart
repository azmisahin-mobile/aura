import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';
import '../engine/api_resolver_engine.dart';

class YouTubeFallbackProvider implements IAudioProvider {
  final ApiResolverEngine _resolver;
  final http.Client _client = http.Client();

  YouTubeFallbackProvider(this._resolver);

  final List<String> _pipedInstances = [
    "pipedapi.adminforge.de",
    "pipedapi.syncpundit.io",
    "pipedapi.kavin.rocks",
    "pipedapi.tokhmi.xyz"
  ];

  final List<String> _invidiousInstances = [
    "yewtu.be",
    "inv.nadeko.net",
    "invidious.nerdvpn.de"
  ];

  @override
  Future<List<AudioStream>> fetchStreams({required String tag, required String country}) async {
    String searchString = country != "Unknown" ? "$country $tag ambient music" : "$tag ambient music";

    try {
      final bestPiped = await _resolver.getFastestInstance(
        cacheKey: 'piped_best_node',
        instances: _pipedInstances,
        healthPath: '/trending', 
      );
      
      final streams = await _fetchFromPiped(bestPiped, searchString);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [YOUTUBE] Tüm Piped instance\'ları çöktü: $e');
    }

    debugPrint('🛡️ [YOUTUBE] Invidious (Fallback) devrede...');
    try {
      final bestInvidious = await _resolver.getFastestInstance(
        cacheKey: 'invidious_best_node',
        instances: _invidiousInstances,
        healthPath: '/api/v1/trending', 
      );

      final streams = await _fetchFromInvidious(bestInvidious, searchString);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [YOUTUBE] Invidious instance\'ları da çöktü: $e');
    }

    throw Exception("YouTube altyapısı (Piped & Invidious) tamamen devre dışı.");
  }

  Future<List<AudioStream>> _fetchFromPiped(String instance, String searchString) async {
    final searchUri = Uri.https(instance, '/search', {'q': searchString, 'filter': 'music_songs'});
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

  Future<List<AudioStream>> _fetchFromInvidious(String instance, String searchString) async {
    final searchUri = Uri.https(instance, '/api/v1/search', {'q': searchString, 'type': 'video'});
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