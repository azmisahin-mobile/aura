import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint için EKLENDİ
import 'package:http/http.dart' as http;
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class PipedApiProvider implements IAudioProvider {
  // Aktif Piped instance'ları (https://github.com/TeamPiped/Piped/wiki/Instances)
  final List<String> _instances = [
    "pipedapi.kavin.rocks",
    "pipedapi.snopyta.org",
    "pipedapi.adminforge.de",
    "pipedapi.lunar.icu",
    "pipedapi.tokhmi.xyz",
    "pipedapi.moomoo.me",
  ];

  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    const searchTimeout = Duration(seconds: 6);
    const streamTimeout = Duration(seconds: 4);

    for (String instance in _instances) {
      try {
        // 1. Arama
        final searchUri = Uri.https(instance, '/search', {
          'q': '$tag radio music',
          'filter': 'music_songs',
        });
        final searchResponse = await http.get(searchUri).timeout(searchTimeout);
        if (searchResponse.statusCode != 200) continue;

        final data = jsonDecode(searchResponse.body);
        final List<dynamic> items = data['items'] ?? [];
        if (items.isEmpty) continue;

        List<AudioStream> streams = [];

        // İlk 3 sonucu dene
        for (int i = 0; i < (items.length > 3 ? 3 : items.length); i++) {
          final videoId = items[i]['url'].toString().replaceAll('/watch?v=', '');

          // 2. Stream bilgisi
          final streamUri = Uri.https(instance, '/streams/$videoId');
          final streamRes = await http.get(streamUri).timeout(streamTimeout);
          if (streamRes.statusCode != 200) continue;

          final streamData = jsonDecode(streamRes.body);
          final List audioStreams = streamData['audioStreams'] ?? [];
          if (audioStreams.isNotEmpty) {
            // En düşük bitrate'li audio stream'i seç (veri tasarrufu)
            audioStreams.sort((a, b) => (a['bitrate'] ?? 0).compareTo(b['bitrate'] ?? 0));
            final bestAudio = audioStreams.firstWhere(
              (s) => s['mimeType'].contains('audio/mp4'),
              orElse: () => audioStreams.first,
            );
            streams.add(AudioStream(
              name: streamData['title'] ?? 'YouTube Sinyali',
              url: bestAudio['url'],
              provider: 'Piped',
            ));
          }
        }

        if (streams.isNotEmpty) return streams;
      } catch (e) {
        debugPrint('⚠️ Piped instance $instance başarısız: $e');
        // sonraki instance'a geç
      }
    }
    throw Exception("Tüm Piped instance'ları denendi, hiçbiri çalışmıyor.");
  }
}