import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class MasterAudioRepository {
  final IAudioProvider primaryProvider; // Radio Browser
  final IAudioProvider fallbackProvider; // Piped API
  final IAudioProvider offlineProvider; // Asset Drone

  MasterAudioRepository({
    required this.primaryProvider,
    required this.fallbackProvider,
    required this.offlineProvider,
  });

  Future<List<AudioStream>> getAudioStreams(String tag) async {
    // 1. İnternet kontrolü
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('🔌 [AURA_CHAIN] İnternet yok. Çevrimdışı mod başlatılıyor.');
      return offlineProvider.fetchStreams(tag);
    }

    // 2. Birincil Sağlayıcı (Radio Browser)
    try {
      final streams = await primaryProvider.fetchStreams(tag);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Radio Browser çöktü: $e');
    }

    // 3. İkincil Sağlayıcı (Piped API Fallback)
    try {
      debugPrint('🛡️ [AURA_CHAIN] Piped Fallback devrede.');
      final streams = await fallbackProvider.fetchStreams(tag);
      if (streams.isNotEmpty) return streams;
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Piped API de çöktü: $e');
    }

    // 4. Son Çare (Offline Ambiyans)
    debugPrint('🚨 [AURA_CHAIN] Tüm ağ kaynakları başarısız. Çevrimdışı mod.');
    return offlineProvider.fetchStreams(tag);
  }
}