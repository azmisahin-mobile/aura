import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  
  // Çakışma önleyici kimlik
  int _transitionId = 0;

  AuraCubit(this._contextEngine, this._audioProvider)
      : super(AuraUIState(
          mode: AuraState.focus,
          isPlaying: false,
          statusMessage: "Aura'yı uyandırmak için dokun",
        )) {
    
    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      debugPrint('🚨 [AURA_PLAYER] Akış koptu veya link bozuk: $e');
    });
  }

  Future<void> initializeAndStart() async {
    if (state.isPlaying) return; 

    emit(state.copyWith(statusMessage: "Bağlam analiz ediliyor...", isPlaying: true));
    
    _contextSubscription?.cancel();
    _contextSubscription = _contextEngine.stateStream.listen((newMode) async {
      debugPrint('🧠 [AURA_ENGINE] Kesinleşmiş Bağlam: ${newMode.name.toUpperCase()}');
      await _handleStateTransition(newMode);
    });

    await _contextEngine.initializePermissions();
  }

  Future<void> togglePower() async {
    if (state.isPlaying) {
      debugPrint('💤 [AURA_SYSTEM] Aura uyku moduna alındı.');
      await _smartFadeOut();
      await _player.stop();
      _contextSubscription?.cancel();
      emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
    } else {
      await initializeAndStart();
    }
  }

  Future<void> _handleStateTransition(AuraState newMode) async {
    // Yeni bir geçiş başladı, ID'yi artır
    _transitionId++;
    final currentId = _transitionId;

    emit(state.copyWith(mode: newMode, statusMessage: "Frekans hizalanıyor..."));
    
    try {
      final streams = await _audioProvider.fetchStreams(newMode);
      
      // Eğer radyoyu ararken kullanıcı mod değiştirdiyse, bu işlemi sessizce iptal et
      if (currentId != _transitionId) {
        debugPrint('⏩ [AURA_SYSTEM] Yeni mod geldi, eski işlem iptal edildi.');
        return;
      }

      if (streams.isNotEmpty) {
        final maxIndex = min(5, streams.length);
        final selectedStream = streams[Random().nextInt(maxIndex)];
        
        debugPrint('🎵 [AURA_SYSTEM] Çalınan Frekans: ${selectedStream.name}');
        
        await _smartFadeOut();
        
        // Bu noktada hala iptal edilmedik mi kontrol et
        if (currentId != _transitionId) return;

        await _player.setUrl(selectedStream.url);
        emit(state.copyWith(statusMessage: selectedStream.name, currentStream: selectedStream));
        await _smartFadeIn();
      } else {
        emit(state.copyWith(statusMessage: "Bu mod için kaynak bulunamadı."));
      }
    } catch (e) {
      if (currentId == _transitionId) {
        debugPrint('🚨 [AURA_SYSTEM] Kritik Hata: $e');
        emit(state.copyWith(statusMessage: "Sinyal Zayıf. Yeniden deneniyor..."));
      }
    }
  }

  Future<void> _smartFadeOut() async {
    if (!_player.playing) return;
    for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await _player.pause();
  }

  Future<void> _smartFadeIn() async {
    await _player.setVolume(0.0);
    _player.play();
    for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  @override
  Future<void> close() {
    _contextSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}