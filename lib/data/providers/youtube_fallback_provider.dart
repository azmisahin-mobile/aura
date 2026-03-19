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

  final List<String> _pipedInstances =["pipedapi.kavin.rocks", "pipedapi.tokhmi.xyz"];
  final List<String> _invidiousInstances = ["yewtu.be", "invidious.nerdvpn.de"];

  @override
  Future<List<AudioStream>> fetchStreams({required String tag, required String countryCode}) async {
    // YouTube için ülke kodu yerine sadece tag yeterli, çünkü tag zaten "turkce" gibi kelimeler içeriyor.
    String searchString = "$tag ambient music";

    try {
      final bestPiped = await _resolver.getFastestInstance(cacheKey: 'piped_node', instances: _pipedInstances, healthPath: '/trending');
      final streams = await _fetchFromPiped(bestPiped, searchString);
      if (streams.isNotEmpty) return streams;
    } catch (_) {}

    try {
      final bestInv = await _resolver.getFastestInstance(cacheKey: 'inv_node', instances: _invidiousInstances, healthPath: '/api/v1/trending');
      final streams = await _fetchFromInvidious(bestInv, searchString);
      if (streams.isNotEmpty) return streams;
    } catch (_) {}

    throw Exception("YouTube altyapısı devre dışı.");
  }

  Future<List<AudioStream>> _fetchFromPiped(String instance, String search) async {
    final searchUri = Uri.https(instance, '/search', {'q': search, 'filter': 'music_songs'});
    final searchRes = await _client.get(searchUri).timeout(const Duration(seconds: 4));
    if (searchRes.statusCode != 200) return [];

    final items = jsonDecode(searchRes.body)['items'] as List<dynamic>? ?? [];
    List<AudioStream> streams =[];
    for (int i = 0; i < (items.length > 2 ? 2 : items.length); i++) {
      final videoId = items[i]['url'].toString().replaceAll('/watch?v=', '');
      final streamUri = Uri.https(instance, '/streams/$videoId');
      final streamRes = await _client.get(streamUri).timeout(const Duration(seconds: 4));
      if (streamRes.statusCode != 200) continue;
      
      final audioStreams = jsonDecode(streamRes.body)['audioStreams'] as List<dynamic>? ??[];
      if (audioStreams.isNotEmpty) {
        audioStreams.sort((a, b) => (a['bitrate'] ?? 0).compareTo(b['bitrate'] ?? 0));
        streams.add(AudioStream(name: items[i]['title'], url: audioStreams.first['url'], provider: 'Piped ($instance)'));
      }
    }
    return streams;
  }

  Future<List<AudioStream>> _fetchFromInvidious(String instance, String search) async {
    final searchUri = Uri.https(instance, '/api/v1/search', {'q': search, 'type': 'video'});
    final searchRes = await _client.get(searchUri).timeout(const Duration(seconds: 4));
    if (searchRes.statusCode != 200) return[];

    final items = jsonDecode(searchRes.body) as List<dynamic>? ?? [];
    List<AudioStream> streams =[];
    for (int i = 0; i < (items.length > 2 ? 2 : items.length); i++) {
      final videoId = items[i]['videoId'];
      final streamUri = Uri.https(instance, '/api/v1/videos/$videoId');
      final streamRes = await _client.get(streamUri).timeout(const Duration(seconds: 4));
      if (streamRes.statusCode != 200) continue;
      
      final formatStreams = jsonDecode(streamRes.body)['adaptiveFormats'] as List<dynamic>? ??[];
      final audios = formatStreams.where((f) => f['type'].toString().contains('audio')).toList();
      if (audios.isNotEmpty) {
        streams.add(AudioStream(name: items[i]['title'], url: audios.first['url'], provider: 'Invidious ($instance)'));
      }
    }
    return streams;
  }
}