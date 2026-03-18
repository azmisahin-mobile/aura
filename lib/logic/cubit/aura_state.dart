import '../../domain/entities/aura_state_enum.dart';
import '../../domain/entities/audio_stream.dart';

class AuraUIState {
  final AuraState mode;
  final bool isPlaying;
  final String statusMessage;
  final AudioStream? currentStream;

  AuraUIState({
    required this.mode,
    required this.isPlaying,
    required this.statusMessage,
    this.currentStream,
  });

  AuraUIState copyWith({
    AuraState? mode,
    bool? isPlaying,
    String? statusMessage,
    AudioStream? currentStream,
  }) {
    return AuraUIState(
      mode: mode ?? this.mode,
      isPlaying: isPlaying ?? this.isPlaying,
      statusMessage: statusMessage ?? this.statusMessage,
      currentStream: currentStream ?? this.currentStream,
    );
  }
}