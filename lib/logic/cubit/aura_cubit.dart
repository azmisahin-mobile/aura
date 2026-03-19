import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
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
  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 10),
        maxBufferDuration: Duration(seconds: 60),
        bufferForPlaybackDuration: Duration(seconds: 2),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 5),
      ),
    ),
  );
  
  final DeviceContextEngine _contextEngine;
  final AuraMemoryEngine _memoryEngine;
  final MasterAudioRepository _audioRepo;
  
  StreamSubscription? _contextSubscription;
  StreamSubscription? _playerIndexSubscription;
  int _transitionId = 0;
  List<AudioStream> _currentStreams = [];
  bool _isDisliking = false;

  AuraCubit(this._contextEngine, this._memoryEngine, this._audioRepo)
      : super(AuraUIState(
          mode: AuraState.focus,
          isPlaying: false,
          statusMessage: "Aura'yı uyandırmak için dokun",
        )) {
    _playerIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && _currentStreams.isNotEmpty && index < _currentStreams.length) {
        final stream = _currentStreams[index];
        debugPrint('🎧 [AURA_PLAYER] Şu an çalıyor: ${stream.name} (Kaynak: ${stream.provider})');
        emit(state.copyWith(statusMessage: stream.name, currentStream: stream));
      }
    });
  }

  Future<void> initializeAndStart() async {
    if (state.isPlaying) return; 
    
    HapticFeedback.vibrate(); 
    WeatherContext weather = _contextEngine.getCurrentWeatherContext();
    emit(state.copyWith(statusMessage: "Biyolojik ritim analiz ediliyor...", isPlaying: true, weather: weather));
    
    _contextSubscription?.cancel();
    _contextSubscription = _contextEngine.stateStream.listen((newMode) async {
      await _handleStateTransition(newMode);
    });

    await _contextEngine.initializePermissions();
  }

  Future<void> sleep() async {
    if (!state.isPlaying) return;
    HapticFeedback.vibrate(); 
    debugPrint('💤 [AURA_SYSTEM] Aura derin uykuya geçiyor.');
    await _smartFadeOut();
    await _player.stop();
    _contextSubscription?.cancel();
    emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
  }

  Future<void> skip() async {
    if (!state.isPlaying || _currentStreams.isEmpty) return;
    HapticFeedback.lightImpact(); 
    debugPrint('⏭️ [AURA_ACTION] Kullanıcı frekansı atladı (Skip).');
    if (_player.hasNext) {
      emit(state.copyWith(statusMessage: "Crossfade: Frekans atlanıyor..."));
      await _player.seekToNext();
    } else {
      await _handleStateTransition(state.mode);
    }
  }

  Future<void> dislikeAndLearn() async {
    if (!state.isPlaying || _isDisliking) return;
    _isDisliking = true;
    HapticFeedback.heavyImpact(); 
    debugPrint('🚫 [AURA_ACTION] Kullanıcı frekansı sevmedi (Dislike). Öğrenme algoritması tetiklendi.');
    
    emit(state.copyWith(statusMessage: "Aura öğreniyor... Yeni frekans taranıyor."));
    
    TimeContext time = _contextEngine.getCurrentTimeContext();
    WeatherContext weather = _contextEngine.getCurrentWeatherContext();
    String country = _contextEngine.getCurrentCountry();
    String currentTag = _memoryEngine.getBestTag(state.mode, time, weather, country);
    
    await _memoryEngine.penalizeTag(state.mode, time, weather, country, currentTag);
    await _handleStateTransition(state.mode);
    _isDisliking = false;
  }

  Future<void> _handleStateTransition(AuraState newMode) async {
    _transitionId++;
    final currentId = _transitionId;
    
    TimeContext time = _contextEngine.getCurrentTimeContext();
    WeatherContext weather = _contextEngine.getCurrentWeatherContext();
    String country = _contextEngine.getCurrentCountry();
    
    String tag = _memoryEngine.getBestTag(newMode, time, weather, country);
    debugPrint('\n🧠 ================= AURA BEYNİ =================');
    debugPrint('🏃 Biyolojik Mod: ${newMode.name.toUpperCase()}');
    debugPrint('🌤️ Hava Durumu: ${weather.name.toUpperCase()}');
    debugPrint('🌍 Lokasyon: $country');
    debugPrint('🎯 Seçilen Müzik Türü (Tag): $tag');
    debugPrint('================================================\n');

    if (state.mode != newMode) {
      HapticFeedback.mediumImpact();
    }

    emit(state.copyWith(mode: newMode, weather: weather, statusMessage: "Frekans hizalanıyor..."));
    
    try {
      _currentStreams = await _audioRepo.getAudioStreams(tag: tag, country: country);
      if (currentId != _transitionId) return;

      if (_currentStreams.isNotEmpty) {
        debugPrint('📻 [AURA_NETWORK] ${country} ülkesi için ${_currentStreams.length} istasyon bulundu.');
        await _loadPlaylistAndPlay(_currentStreams);
      } else {
        emit(state.copyWith(statusMessage: "Sinyal boşluğu."));
      }
    } catch (e) {
      if (currentId == _transitionId) {
        debugPrint('🚨 [AURA_NETWORK] Hata oluştu: $e');
        emit(state.copyWith(statusMessage: "Sinyal Kaybı. Yeniden deneniyor..."));
      }
    }
  }

  Future<void> _loadPlaylistAndPlay(List<AudioStream> streams) async {
    await _smartFadeOut();
    
    try {
      final audioSources = streams.map((s) {
        final mediaItem = MediaItem(
          id: s.url,
          album: "Aura ${state.mode.name.toUpperCase()} Mode",
          title: s.name,
          artist: s.provider,
        );
        return AudioSource.uri(Uri.parse(s.url), tag: mediaItem);
      }).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);
      
      await _player.setAudioSource(playlist, initialIndex: 0);
      await _smartFadeIn();
    } catch (e) {
      debugPrint('🚨 [AURA_PLAYER] Oynatma hatası: $e');
    }
  }

  Future<void> _smartFadeOut() async {
    if (!_player.playing) return;
    for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 30));
    }
    await _player.pause();
  }

  Future<void> _smartFadeIn() async {
    await _player.setVolume(0.0);
    _player.play();
    for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
      await _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> close() {
    _contextSubscription?.cancel();
    _playerIndexSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}