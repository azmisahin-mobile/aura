import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class RadioBrowserProvider implements IAudioProvider {
  final http.Client _client;

  // Dependency Injection ile client alıyoruz. (Test edilebilirliği artırır)
  RadioBrowserProvider({http.Client? client}) : _client = client ?? http.Client();

  final List<String> _nodes = [
    "de1.api.radio-browser.info",
    "de2.api.radio-browser.info",
    "nl1.api.radio-browser.info",
    "fr1.api.radio-browser.info",
    "at1.api.radio-browser.info",
    "pl1.api.radio-browser.info",
    "uk1.api.radio-browser.info",
    "it1.api.radio-browser.info",
    "se1.api.radio-browser.info",
    "ch1.api.radio-browser.info",
  ];

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    final headers = {'User-Agent': 'Aura/1.2.0'};
    const timeout = Duration(seconds: 5);

    // API yük dengesini sağlamak için listeyi her istekte karıştırıyoruz
    final nodesToTry = List<String>.from(_nodes)..shuffle();

    for (String node in nodesToTry) {
      final uri = Uri.https(node, '/json/stations/search', {
        'tag': tag,
        'limit': '15',
        'hidebroken': 'true',
        'order': 'random',
      });

      try {
        final response = await _client.get(uri, headers: headers).timeout(timeout);
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          
          // Sunucu ayakta ve geçerli bir cevap verdi. 
          // Liste boş olsa bile bunu döndürüyoruz ki diğer node'ları boşuna gezmesin.
          return data
              .where((s) {
                final urlRes = s['url_resolved']?.toString().trim() ?? '';
                final url = s['url']?.toString().trim() ?? '';
                return urlRes.isNotEmpty || url.isNotEmpty; // Geçersiz URL'leri ele
              })
              .map((s) => AudioStream(
                    name: s['name']?.toString().trim().isNotEmpty == true 
                          ? s['name'].toString().trim() 
                          : 'Bilinmeyen Sinyal',
                    url: (s['url_resolved']?.toString().trim().isNotEmpty == true)
                          ? s['url_resolved']
                          : s['url'],
                    provider: 'RadioBrowser',
                  ))
              .toList();
        } else {
          debugPrint('⚠️ RadioBrowser node $node başarısız oldu: HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ RadioBrowser node $node bağlantı hatası: $e');
        // Sadece bağlantı veya timeout hatalarında bir sonraki node'a geç
      }
    }
    
    throw Exception("Tüm radyo sunucularına ulaşılamadı. Lütfen internet bağlantınızı kontrol edin.");
  }
}