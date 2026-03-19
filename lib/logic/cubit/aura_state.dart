import '../../domain/entities/aura_state_enum.dart';
import '../../domain/entities/audio_stream.dart';

class AuraUIState {
  final AuraState mode;
  final WeatherContext weather; // EKLENDİ: Renkleri havaya göre bükeceğiz
  final bool isPlaying;
  final String statusMessage;
  final AudioStream? currentStream;

  AuraUIState({
    required this.mode,
    this.weather = WeatherContext.unknown,
    required this.isPlaying,
    required this.statusMessage,
    this.currentStream,
  });

  AuraUIState copyWith({
    AuraState? mode,
    WeatherContext? weather,
    bool? isPlaying,
    String? statusMessage,
    AudioStream? currentStream,
  }) {
    return AuraUIState(
      mode: mode ?? this.mode,
      weather: weather ?? this.weather,
      isPlaying: isPlaying ?? this.isPlaying,
      statusMessage: statusMessage ?? this.statusMessage,
      currentStream: currentStream ?? this.currentStream,
    );
  }
}