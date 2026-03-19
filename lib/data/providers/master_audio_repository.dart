import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // debugPrint için EKLENDİ
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class MasterAudioRepository {
  final IAudioProvider primaryProvider; // Radio Browser
  final IAudioProvider fallbackProvider; // Piped API
  final IAudioProvider offlineProvider; // Asset Drone

  // Basit bir önbellek: son başarılı stream'leri tutar
  List<AudioStream> _cache = [];
  final int _maxCacheSize = 10;

  MasterAudioRepository({
    required this.primaryProvider,
    required this.fallbackProvider,
    required this.offlineProvider,
  });

  Future<List<AudioStream>> getAudioStreams(String tag) async {
    // 1. İnternet kontrolü
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (!hasInternet) {
      debugPrint('🔌 [AURA_CHAIN] İnternet yok. Çevrimdışı mod başlatılıyor.');
      return _getOfflineStreams();
    }

    // 2. Birincil sağlayıcıyı dene
    try {
      final streams = await primaryProvider.fetchStreams(tag);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Radio Browser çöktü: $e');
    }

    // 3. İkincil sağlayıcıyı dene
    try {
      debugPrint('🛡️ [AURA_CHAIN] Piped Fallback devrede.');
      final streams = await fallbackProvider.fetchStreams(tag);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Piped API de çöktü: $e');
    }

    // 4. Önbellekte kayıt var mı?
    if (_cache.isNotEmpty) {
      debugPrint('📦 [AURA_CHAIN] Önbellekteki son stream\'ler kullanılıyor.');
      return _cache;
    }

    // 5. Son çare: offline ambiyans
    debugPrint('🚨 [AURA_CHAIN] Tüm kaynaklar başarısız. Çevrimdışı mod.');
    return _getOfflineStreams();
  }

  void _updateCache(List<AudioStream> newStreams) {
    _cache = newStreams.take(_maxCacheSize).toList();
  }

  Future<List<AudioStream>> _getOfflineStreams() async {
    // offline drone her zaman aynı, ama istersen farklı offline sesler eklenebilir
    return [
      AudioStream(
        name: "Aura Rezonansı (Çevrimdışı)",
        url: "asset:///assets/offline_drone.mp3",
        provider: 'Local',
      )
    ];
  }
}