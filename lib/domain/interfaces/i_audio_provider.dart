import '../entities/audio_stream.dart';

abstract class IAudioProvider {
  // Artık sadece durum değil, öğrenilmiş spesifik "tag" (tür) aranıyor
  Future<List<AudioStream>> fetchStreams(String tag);
}