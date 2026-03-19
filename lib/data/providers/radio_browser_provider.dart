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
    return [
      "de1.api.radio-browser.info",
      "nl1.api.radio-browser.info",
      "at1.api.radio-browser.info",
    ];
  }

  @override
  Future<List<AudioStream>> fetchStreams({required String tag, required String country}) async {
    final nodes = await _getDynamicNodes();
    final bestNode = await _resolver.getFastestInstance(
      cacheKey: 'radio_browser_best_node',
      instances: nodes,
      healthPath: '/json/stats',
    );

    // 1. Önce o ülkede ara
    debugPrint('📡 [API_CALL] Lokasyon bazlı aranıyor -> Ülke: $country | Tag: $tag');
    List<AudioStream> streams = await _searchApi(bestNode, tag, country);

    // 2. Ülkede bulamazsa tüm dünyada (Global) ara
    if (streams.isEmpty) {
      debugPrint('⚠️ [API_CALL] $country sınırlarında $tag bulunamadı. Tüm dünya taranıyor...');
      streams = await _searchApi(bestNode, tag, ""); 
    }

    if (streams.isNotEmpty) {
      return streams;
    }
    
    throw Exception("Radyo yayını hiçbir yerde bulunamadı.");
  }

  Future<List<AudioStream>> _searchApi(String node, String tag, String country) async {
    final queryParams = {
      'tag': tag,
      'limit': '15',
      'hidebroken': 'true',
      'order': 'random',
    };

    if (country.isNotEmpty && country != "Unknown") {
      queryParams['country'] = country;
    }

    final uri = Uri.https(node, '/json/stations/search', queryParams);
    
    final response = await _client.get(uri, headers: {'User-Agent': 'Aura/1.7.1'}).timeout(const Duration(seconds: 5));
    
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
                provider: 'RadioBrowser ($node)',
              ))
          .toList();
    }
    return [];
  }
}