import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class OfflineAudioProvider implements IAudioProvider {
  @override
  Future<List<AudioStream>> fetchStreams(String tag) async {
    // Uygulama içine gömülü, sonsuz döngüye uygun ambient ses (asset)
    return [
      AudioStream(
        name: "Aura Rezonansı (Çevrimdışı)",
        // 1.37 dakika < 1MB
        url: "asset:///assets/offline_drone.mp3",
        provider: 'Local',
      )
    ];
  }
}