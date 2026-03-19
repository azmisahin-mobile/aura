import '../entities/audio_stream.dart';

abstract class IAudioProvider {
  Future<List<AudioStream>> fetchStreams({required String tag, required String country});
}