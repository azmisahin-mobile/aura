import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class PipedApiProvider implements IAudioProvider {
  // Kararlı bir açık kaynak Piped instance'ı
  final String _apiUrl = "https://pipedapi.kavin.rocks";

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    final searchUri = Uri.parse("$_apiUrl/search?q=$tag+radio+music&filter=music_songs");
    
    final response = await http.get(searchUri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) throw Exception("Piped API Yanıt Vermedi");

    final data = jsonDecode(response.body);
    final List<dynamic> items = data['items'] ?? [];
    if (items.isEmpty) throw Exception("Piped'de içerik bulunamadı");

    List<AudioStream> streams = [];
    
    // İlk 3 sonucu al (Hız için)
    for (int i = 0; i < (items.length > 3 ? 3 : items.length); i++) {
      final videoId = items[i]['url'].toString().replaceAll('/watch?v=', '');
      
      // Video detayından ses akış URL'ini çek
      final streamUri = Uri.parse("$_apiUrl/streams/$videoId");
      final streamRes = await http.get(streamUri);
      
      if (streamRes.statusCode == 200) {
        final streamData = jsonDecode(streamRes.body);
        final List audioStreams = streamData['audioStreams'] ?? [];
        if (audioStreams.isNotEmpty) {
          // En düşük boyutlu m4a/opus stream'i al (veri tasarrufu)
          final bestAudio = audioStreams.firstWhere((s) => s['mimeType'].contains('audio/mp4'), orElse: () => audioStreams.first);
          streams.add(AudioStream(
            name: streamData['title'] ?? 'YouTube Sinyali',
            url: bestAudio['url'],
            provider: 'Piped',
          ));
        }
      }
    }
    
    return streams;
  }
}