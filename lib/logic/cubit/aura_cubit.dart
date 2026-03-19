import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/entities/audio_stream.dart';
import '../../data/engine/device_context_engine.dart';
import '../../data/engine/aura_memory_engine.dart';
import '../../data/providers/master_audio_repository.dart';
import 'aura_state.dart';

class AuraCubit extends Cubit<AuraUIState> {
  final AudioPlayer _player = AudioPlayer();
  final DeviceContextEngine _contextEngine;
  final AuraMemoryEngine _memoryEngine;
  final MasterAudioRepository _audioRepo;
  
  StreamSubscription? _contextSubscription;
  int _transitionId = 0;
  List<AudioStream> _currentPlaylist = [];
  int _playIndex = 0;

  AuraCubit(this._contextEngine, this._memoryEngine, this._audioRepo)
      : super(AuraUIState(
          mode: AuraState.focus,
          isPlaying: false,
          statusMessage: "Aura'yı uyandırmak için dokun",
        ));

  Future<void> initializeAndStart() async {
    if (state.isPlaying) return; 
    emit(state.copyWith(statusMessage: "Biyolojik ritim analiz ediliyor...", isPlaying: true));
    
    _contextSubscription?.cancel();
    _contextSubscription = _contextEngine.stateStream.listen((newMode) async {
      await _handleStateTransition(newMode);
    });

    await _contextEngine.initializePermissions();
  }

  Future<void> sleep() async {
    if (!state.isPlaying) return;
    debugPrint('💤 [AURA_SYSTEM] Aura derin uykuya geçiyor.');
    await _smartFadeOut();
    await _player.stop();
    _contextSubscription?.cancel();
    emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
  }

  // Swipe Right: Sadece başka bir yayına geç
  Future<void> skip() async {
    if (!state.isPlaying || _currentPlaylist.isEmpty) return;
    _playIndex = (_playIndex + 1) % _currentPlaylist.length;
    await _playStream(_currentPlaylist[_playIndex]);
  }

  // Swipe Left: Bunu sevmedim, öğren ve değiştir
  Future<void> dislikeAndLearn() async {
    if (!state.isPlaying) return;
    emit(state.copyWith(statusMessage: "Aura öğreniyor... Yeni frekans taranıyor."));
    
    TimeContext time = _contextEngine.getCurrentTimeContext();
    String currentTag = _memoryEngine.getBestTag(state.mode, time);
    
    // Hafızaya yaz
    await _memoryEngine.penalizeTag(state.mode, time, currentTag);
    
    // Yeni tag ile tekrar yükle
    await _handleStateTransition(state.mode);
  }

  Future<void> _handleStateTransition(AuraState newMode) async {
    _transitionId++;
    final currentId = _transitionId;
    TimeContext time = _contextEngine.getCurrentTimeContext();
    String tag = _memoryEngine.getBestTag(newMode, time);

    emit(state.copyWith(mode: newMode, statusMessage: "Frekans hizalanıyor..."));
    
    try {
      _currentPlaylist = await _audioRepo.getAudioStreams(tag);
      if (currentId != _transitionId) return;

      if (_currentPlaylist.isNotEmpty) {
        _playIndex = 0;
        await _playStream(_currentPlaylist.first);
      } else {
        emit(state.copyWith(statusMessage: "Sinyal boşluğu."));
      }
    } catch (e) {
      if (currentId == _transitionId) {
        emit(state.copyWith(statusMessage: "Sinyal Kaybı. Yeniden deneniyor..."));
      }
    }
  }

  Future<void> _playStream(AudioStream stream) async {
    await _smartFadeOut();
    
    try {
      // Bildirim ve Kilit Ekranı için Metadata (MediaItem) oluşturuluyor
      final mediaItem = MediaItem(
        id: stream.url,
        album: "Aura ${state.mode.name.toUpperCase()} Mode",
        title: stream.name,
        artist: stream.provider,
      );

      if (stream.url.startsWith('asset:///')) {
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(stream.url), tag: mediaItem),
        );
        await _player.setLoopMode(LoopMode.one); 
      } else {
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(stream.url), tag: mediaItem),
        );
        await _player.setLoopMode(LoopMode.off);
      }
      
      emit(state.copyWith(statusMessage: stream.name, currentStream: stream));
      await _smartFadeIn();
    } catch (e) {
      debugPrint('🚨 [AURA_PLAYER] Oynatma hatası: $e');
      skip(); // Hata varsa bir sonrakine geç
    }
  }

  Future<void> _smartFadeOut() async {
    if (!_player.playing) return;
    for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 40));
    }
    await _player.pause();
  }

  Future<void> _smartFadeIn() async {
    await _player.setVolume(0.0);
    _player.play();
    for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  @override
  Future<void> close() {
    _contextSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}