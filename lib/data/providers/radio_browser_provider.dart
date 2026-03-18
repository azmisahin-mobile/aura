import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class RadioBrowserProvider implements IAudioProvider {
  final String _baseUrl = "https://de1.api.radio-browser.info/json/stations/search";

  @override
  Future<List<AudioStream>> fetchStreams(AuraState state) async {
    String tag = _mapStateToTag(state);
    final uri = Uri.parse("$_baseUrl?tag=$tag&limit=15&hidebroken=true&order=clickcount&reverse=true");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((station) {
          return AudioStream(
            name: station['name'] ?? 'Bilinmeyen Frekans',
            url: station['url_resolved'] ?? station['url'],
            provider: 'RadioBrowser',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Radyo API Bağlantı Hatası: $e");
    }
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