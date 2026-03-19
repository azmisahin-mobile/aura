import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class MasterAudioRepository {
  final IAudioProvider primaryProvider; 
  final IAudioProvider fallbackProvider; 
  final IAudioProvider offlineProvider; 

  List<AudioStream> _cache =[];
  final int _maxCacheSize = 10;

  MasterAudioRepository({
    required this.primaryProvider,
    required this.fallbackProvider,
    required this.offlineProvider,
  });

  Future<List<AudioStream>> getAudioStreams({required String tag, required String countryCode}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (!hasInternet) {
      debugPrint('🔌 [AURA_CHAIN] İnternet yok. Çevrimdışı mod başlatılıyor.');
      return _getOfflineStreams();
    }

    try {
      final streams = await primaryProvider.fetchStreams(tag: tag, countryCode: countryCode);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] Radio Browser çöktü: $e');
    }

    try {
      debugPrint('🛡️[AURA_CHAIN] YouTube Fallback Zinciri devrede.');
      final streams = await fallbackProvider.fetchStreams(tag: tag, countryCode: countryCode);
      if (streams.isNotEmpty) {
        _updateCache(streams);
        return streams;
      }
    } catch (e) {
      debugPrint('⚠️ [AURA_CHAIN] YouTube Fallback de çöktü: $e');
    }

    if (_cache.isNotEmpty) {
      debugPrint('📦 [AURA_CHAIN] Önbellekteki son stream\'ler kullanılıyor.');
      return _cache;
    }

    debugPrint('🚨[AURA_CHAIN] Tüm kaynaklar başarısız. Çevrimdışı mod.');
    return _getOfflineStreams();
  }

  void _updateCache(List<AudioStream> newStreams) {
    _cache = newStreams.take(_maxCacheSize).toList();
  }

  Future<List<AudioStream>> _getOfflineStreams() async {
    return[
      AudioStream(
        name: "Aura Rezonansı (Çevrimdışı)",
        url: "asset:///assets/offline_drone.mp3",
        provider: 'Local',
      )
    ];
  }
}