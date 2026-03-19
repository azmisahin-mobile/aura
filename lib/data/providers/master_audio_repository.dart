import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class MasterAudioRepository {
  final IAudioProvider primaryProvider; // Radio Browser
  final IAudioProvider fallbackProvider; // YouTube (Piped + Invidious)
  final IAudioProvider offlineProvider; // Asset Drone

  List<AudioStream> _cache = [];
  final int _maxCacheSize = 10;

  MasterAudioRepository({
    required this.primaryProvider,
    required this.fallbackProvider,
    required this.offlineProvider,
  });

  Future<List<AudioStream>> getAudioStreams(String tag) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // DÜZELTİLEN SATIR BURASI:
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (!hasInternet) {
      debugPrint('🔌 [AURA_CHAIN] İnternet yok. Çevrimdışı mod başlatılıyor.');
      return _getOfflineStreams();
    }

    // 1. Birincil sağlayıcıyı dene (Radio Browser)
    try {
      final streams = await primaryProvider.fetchStreams(tag);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Radio Browser çöktü: $e');
    }

    // 2. İkincil sağlayıcıyı dene (YouTube Fallback: Piped -> Invidious)
    try {
      debugPrint('🛡️ [AURA_CHAIN] YouTube Fallback Zinciri devrede.');
      final streams = await fallbackProvider.fetchStreams(tag);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] YouTube Fallback de çöktü: $e');
    }

    // 3. Önbellek kontrolü
    if (_cache.isNotEmpty) {
      debugPrint('📦 [AURA_CHAIN] Önbellekteki son stream\'ler kullanılıyor.');
      return _cache;
    }

    // 4. Son çare: Çevrimdışı (Ölümsüzlük)
    debugPrint('🚨 [AURA_CHAIN] Tüm kaynaklar başarısız. Çevrimdışı mod.');
    return _getOfflineStreams();
  }

  void _updateCache(List<AudioStream> newStreams) {
    _cache = newStreams.take(_maxCacheSize).toList();
  }

  Future<List<AudioStream>> _getOfflineStreams() async {
    return [
      AudioStream(
        name: "Aura Rezonansı (Çevrimdışı)",
        url: "asset:///assets/offline_drone.mp3",
        provider: 'Local',
      )
    ];
  }
}