import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';
import '../engine/api_resolver_engine.dart';

class RadioBrowserProvider implements IAudioProvider {
  final http.Client _client = http.Client();
  final ApiResolverEngine _resolver;

  RadioBrowserProvider(this._resolver);

  // Radio Browser'ın DNS load balancer'ı. Burası aktif sunucu listesini döner.
  final String _discoveryUrl = "all.api.radio-browser.info";

  Future<List<String>> _getDynamicNodes() async {
    try {
      final res = await _client.get(Uri.https(_discoveryUrl, '/json/servers')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e['name'].toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [RADIO_BROWSER] DNS Discovery başarısız. Fallback node\'lar kullanılıyor.');
    }
    // Discovery çökerse Hardcoded Fallback
    return [
      "de1.api.radio-browser.info",
      "nl1.api.radio-browser.info",
      "at1.api.radio-browser.info",
    ];
  }

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    final nodes = await _getDynamicNodes();
    
    // Resolver ile en hızlı node'u bul (Health check için ana dizin veya stats kullanılabilir)
    final bestNode = await _resolver.getFastestInstance(
      cacheKey: 'radio_browser_best_node',
      instances: nodes,
      healthPath: '/json/stats', // Stats endpoint'i en hafif olanıdır
    );

    final uri = Uri.https(bestNode, '/json/stations/search', {
      'tag': tag,
      'limit': '15',
      'hidebroken': 'true',
      'order': 'random',
    });

    final response = await _client.get(uri, headers: {'User-Agent': 'Aura/1.3.0'}).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .where((s) {
            final urlRes = s['url_resolved']?.toString().trim() ?? '';
            final url = s['url']?.toString().trim() ?? '';
            return urlRes.isNotEmpty || url.isNotEmpty;
          })
          .map((s) => AudioStream(
                name: s['name']?.toString().trim().isNotEmpty == true 
                      ? s['name'].toString().trim() 
                      : 'Bilinmeyen Sinyal',
                url: (s['url_resolved']?.toString().trim().isNotEmpty == true)
                      ? s['url_resolved']
                      : s['url'],
                provider: 'RadioBrowser ($bestNode)',
              ))
          .toList();
    }
    
    throw Exception("Radyo yayını alınamadı.");
  }
}