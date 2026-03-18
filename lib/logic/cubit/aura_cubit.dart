import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_audio_provider.dart';
import '../../domain/interfaces/i_context_engine.dart';
import 'aura_state.dart';

class AuraCubit extends Cubit<AuraUIState> {
  final AudioPlayer _player = AudioPlayer();
  final IContextEngine _contextEngine;
  final IAudioProvider _audioProvider;
  StreamSubscription? _contextSubscription;

  AuraCubit(this._contextEngine, this._audioProvider)
      : super(AuraUIState(
          mode: AuraState.focus,
          isPlaying: false,
          statusMessage: "Aura'yı uyandırmak için dokun",
        ));

  Future<void> initializeAndStart() async {
    if (state.isPlaying) return; // Zaten çalışıyorsa engelle

    emit(state.copyWith(statusMessage: "Bağlam analiz ediliyor...", isPlaying: true));
    
    await _contextEngine.initializePermissions();

    _contextSubscription = _contextEngine.stateStream.listen((newMode) async {
      await _handleStateTransition(newMode);
    });
  }

  Future<void> togglePower() async {
    if (state.isPlaying) {
      await _smartFadeOut();
      await _player.stop();
      _contextSubscription?.cancel();
      emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
    } else {
      await initializeAndStart();
    }
  }

  Future<void> _handleStateTransition(AuraState newMode) async {
    emit(state.copyWith(mode: newMode, statusMessage: "Frekans hizalanıyor..."));
    
    try {
      final streams = await _audioProvider.fetchStreams(newMode);
      if (streams.isNotEmpty) {
        // Rastgele bir istasyon seç
        final selectedStream = streams[Random().nextInt(streams.length)];
        
        await _smartFadeOut();
        await _player.setUrl(selectedStream.url);
        emit(state.copyWith(statusMessage: selectedStream.name, currentStream: selectedStream));
        await _smartFadeIn();
      } else {
        emit(state.copyWith(statusMessage: "Bu mod için kaynak bulunamadı."));
      }
    } catch (e) {
      emit(state.copyWith(statusMessage: "Bağlantı koptu. Yeniden deneniyor..."));
    }
  }

  // AI_HANDOVER.md Rule: Smart Fading
  Future<void> _smartFadeOut() async {
    if (!_player.playing) return;
    for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _player.pause();
  }

  Future<void> _smartFadeIn() async {
    await _player.setVolume(0.0);
    _player.play();
    for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Future<void> close() {
    _contextSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}