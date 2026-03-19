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
  StreamSubscription? _playbackEventSubscription; 
  StreamSubscription? _playerStateSubscription; // ANTI-SESSİZLİK İÇİN
  
  Timer? _rewardTimer; 
  Timer? _deadAirTimer; // 8 Saniye Sessizlik Sayacı
  
  String? _currentActiveTag; 
  int _transitionId = 0;
  List<AudioStream> _currentStreams =[];
  bool _isDisliking = false;
  String? _lastPlayedUrl;

  AuraCubit(this._contextEngine, this._memoryEngine, this._audioRepo)
      : super(AuraUIState(
          mode: AuraState.focus,
          isPlaying: false,
          statusMessage: "Aura'yı uyandırmak için dokun",
        )) {
    
    _playerIndexSubscription = _player.currentIndexStream.distinct().listen((index) {
      if (index != null && _currentStreams.isNotEmpty && index < _currentStreams.length) {
        final stream = _currentStreams[index];
        if (_lastPlayedUrl != stream.url) {
          _lastPlayedUrl = stream.url;
          debugPrint('🎧 [AURA_PLAYER] Şu an çalıyor: ${stream.name} (Kaynak: ${stream.provider})');
          emit(state.copyWith(statusMessage: stream.name, currentStream: stream));
          _startRewardTimer();
        }
      }
    });

    _playbackEventSubscription = _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) async {
        debugPrint('🚨 [AURA_PLAYER] YAYIN KOPTU ($e). Oto-İyileşme -> Sıradakine atlanıyor...');
        _forceNext();
      },
    );

    // ANTI-SESSİZLİK (DEAD-AIR) MOTORU
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.loading || 
          playerState.processingState == ProcessingState.buffering) {
        
        // Eğer 8 saniye boyunca bufferda kalırsa, o radyo ölüdür (sessizdir). Hemen geç!
        if (_deadAirTimer?.isActive != true) {
          _deadAirTimer = Timer(const Duration(seconds: 8), () {
            debugPrint('⏳ [AURA_PLAYER] 8 Saniye geçti, ses gelmiyor (Dead-Air). Fişi çekiliyor...');
            _forceNext();
          });
        }
      } else if (playerState.processingState == ProcessingState.ready) {
        // Müzik çalmaya başladı, tehlike geçti.
        _deadAirTimer?.cancel();
      }
    });
  }

  void _startRewardTimer() {
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(seconds: 30), () {
      if (_currentActiveTag != null && _player.playing) {
        _memoryEngine.updateTagScore(_currentActiveTag!, 10);
      }
    });
  }

  void _cancelTimers() {
    _rewardTimer?.cancel();
    _deadAirTimer?.cancel();
  }

  Future<void> _forceNext() async {
    _cancelTimers();
    if (_player.hasNext) {
      await _player.seekToNext();
      _player.play();
    } else {
      _handleStateTransition(state.mode);
    }
  }

  Future<void> initializeAndStart() async {
    if (state.isPlaying) return; 
    HapticFeedback.vibrate(); 
    emit(state.copyWith(statusMessage: "Biyolojik ritim analiz ediliyor...", isPlaying: true));
    
    _contextSubscription?.cancel();
    _contextSubscription = _contextEngine.stateStream.listen((newMode) async {
      await _handleStateTransition(newMode);
    });
    await _contextEngine.initializePermissions();
  }

  Future<void> sleep() async {
    if (!state.isPlaying) return;
    HapticFeedback.vibrate(); 
    _cancelTimers();
    await _smartFadeOut();
    await _player.stop();
    _contextSubscription?.cancel();
    emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
  }

  Future<void> skip() async {
    if (!state.isPlaying || _currentStreams.isEmpty) return;
    HapticFeedback.lightImpact(); 
    _cancelTimers();
    
    if (_currentActiveTag != null) {
      _memoryEngine.updateTagScore(_currentActiveTag!, -5);
    }
    
    emit(state.copyWith(statusMessage: "Crossfade: Frekans atlanıyor..."));
    await _forceNext();
  }

  Future<void> dislikeAndLearn() async {
    if (!state.isPlaying || _isDisliking) return;
    _isDisliking = true;
    HapticFeedback.heavyImpact(); 
    _cancelTimers();
    
    if (_currentActiveTag != null) {
      await _memoryEngine.updateTagScore(_currentActiveTag!, -20);
    }

    emit(state.copyWith(statusMessage: "Aura öğreniyor..."));
    await _handleStateTransition(state.mode);
    _isDisliking = false;
  }

  Future<void> _handleStateTransition(AuraState newMode) async {
    _transitionId++;
    final currentId = _transitionId;
    
    TimeContext time = _contextEngine.getCurrentTimeContext();
    WeatherContext weather = _contextEngine.getCurrentWeatherContext();
    String code = _contextEngine.getCurrentCountryCode();
    
    String tag = _memoryEngine.getBestTag(newMode, time, weather, code);
    _currentActiveTag = tag; 
    
    debugPrint('\n🧠 ================= AURA BEYNİ =================');
    debugPrint('🏃 Biyolojik Mod: ${newMode.name.toUpperCase()}');
    debugPrint('🌤️ Hava Durumu: ${weather.name.toUpperCase()}');
    debugPrint('🎯 Seçilen Tür: $tag');
    debugPrint('================================================\n');

    if (state.mode != newMode) HapticFeedback.mediumImpact();
    emit(state.copyWith(mode: newMode, weather: weather, statusMessage: "Frekans hizalanıyor..."));
    
    try {
      _currentStreams = await _audioRepo.getAudioStreams(tag: tag, countryCode: code);
      if (currentId != _transitionId) return;

      if (_currentStreams.isNotEmpty) {
        await _loadPlaylistAndPlay(_currentStreams);
      } else {
        emit(state.copyWith(statusMessage: "Sinyal boşluğu."));
      }
    } catch (e) {
      if (currentId == _transitionId) {
        emit(state.copyWith(statusMessage: "Sinyal Kaybı. Yeniden deneniyor..."));
      }
    }
  }

  Future<void> _loadPlaylistAndPlay(List<AudioStream> streams) async {
    if (streams.isEmpty) return;
    
    await _smartFadeOut();
    _lastPlayedUrl = null;
    try {
      final audioSources = streams.map((s) {
        final mediaItem = MediaItem(id: s.url, album: "Aura ${state.mode.name.toUpperCase()} Mode", title: s.name, artist: s.provider);
        return AudioSource.uri(Uri.parse(s.url), tag: mediaItem);
      }).toList();
      final playlist = ConcatenatingAudioSource(children: audioSources);
      
      await _player.setAudioSource(playlist, initialIndex: 0);
      await _smartFadeIn();
    } catch (e) {
      debugPrint('🚨 [AURA_PLAYER] İlk frekans bozuk çıktı. Listedeki sıradaki frekansa atlanıyor...');
      if (streams.length > 1) {
        streams.removeAt(0);
        await _loadPlaylistAndPlay(streams);
      } else {
        _handleStateTransition(state.mode);
      }
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
    _cancelTimers();
    _contextSubscription?.cancel();
    _playerIndexSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}