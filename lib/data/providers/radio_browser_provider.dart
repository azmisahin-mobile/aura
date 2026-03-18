import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class RadioBrowserProvider implements IAudioProvider {
  final List<String> _nodes = [
    "https://de1.api.radio-browser.info",
    "https://nl1.api.radio-browser.info",
    "https://at1.api.radio-browser.info"
  ];

  @override
  Future<List<AudioStream>> fetchStreams(AuraState state) async {
    String tag = _mapStateToTag(state);
    
    // API bizi bot sanmasın diye felsefemizi User-Agent olarak gönderiyoruz
    final headers = {
      'User-Agent': 'AuraApp/1.1.0 (OpenSource/ZeroUI)',
      'Accept': 'application/json',
    };
    
    for (String baseUrl in _nodes) {
      final uri = Uri.parse("$baseUrl/json/stations/search?tag=$tag&limit=20&hidebroken=true&order=clickcount&reverse=true");
      
      try {
        debugPrint('📡 [AURA_API] Frekans aranıyor: $uri');
        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          
          if (data.isEmpty) continue;

          debugPrint('✅ [AURA_API] ${data.length} adet $tag frekansı bulundu ($baseUrl)');
          
          return data.map((station) {
            return AudioStream(
              name: station['name']?.toString().trim() ?? 'Bilinmeyen Frekans',
              url: station['url_resolved'] ?? station['url'],
              provider: 'RadioBrowser',
            );
          }).toList();
        } else {
          debugPrint('⚠️ [AURA_API] Sunucu Hata Kodu Döndü: ${response.statusCode} - $baseUrl');
        }
      } catch (e) {
        debugPrint('❌ [AURA_API] Sunucu yanıt vermedi veya zaman aşımı: $baseUrl | Hata: $e');
      }
    }

    throw Exception("Tüm açık kaynak radyo sunucuları çevrimdışı.");
  }

  String _mapStateToTag(AuraState state) {
    switch (state) {
      case AuraState.energy:
        return 'techno';
      case AuraState.chill:
        return 'lofi';
      case AuraState.focus:
        return 'ambient';
    }
  }
}