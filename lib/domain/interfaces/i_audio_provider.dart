import '../entities/audio_stream.dart';
import '../entities/aura_state_enum.dart';

abstract class IAudioProvider {
  Future<List<AudioStream>> fetchStreams(AuraState state);
}