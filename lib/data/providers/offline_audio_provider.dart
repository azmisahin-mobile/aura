import '../../domain/entities/audio_stream.dart';
import '../../domain/interfaces/i_audio_provider.dart';

class OfflineAudioProvider implements IAudioProvider {
  @override
  Future<List<AudioStream>> fetchStreams({required String tag, required String countryCode}) async {
    return[
      AudioStream(
        name: "Aura Rezonansı (Çevrimdışı)",
        url: "asset:///assets/offline_drone.mp3",
        provider: 'Local',
      )
    ];
  }
}