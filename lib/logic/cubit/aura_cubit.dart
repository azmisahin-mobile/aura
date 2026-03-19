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
  
  Timer? _rewardTimer; 
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
        debugPrint('🚨[AURA_PLAYER] YAYIN KOPTU ($e). Oto-İyileşme -> Sıradakine atlanıyor...');
        if (_player.hasNext) {
          await _player.seekToNext();
          _player.play(); // Oynatmayı yeniden tetikle
        } else {
          _handleStateTransition(state.mode);
        }
      },
    );
  }

  void _startRewardTimer() {
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(seconds: 30), () {
      if (_currentActiveTag != null && _player.playing) {
        _memoryEngine.updateTagScore(_currentActiveTag!, 10);
      }
    });
  }

  void _cancelRewardTimer() {
    _rewardTimer?.cancel();
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
    _cancelRewardTimer();
    await _smartFadeOut();
    await _player.stop();
    _contextSubscription?.cancel();
    emit(state.copyWith(isPlaying: false, statusMessage: "Aura Uykuya Geçti"));
  }

  Future<void> skip() async {
    if (!state.isPlaying || _currentStreams.isEmpty) return;
    HapticFeedback.lightImpact(); 
    _cancelRewardTimer();
    
    if (_currentActiveTag != null) {
      _memoryEngine.updateTagScore(_currentActiveTag!, -5);
    }

    if (_player.hasNext) {
      emit(state.copyWith(statusMessage: "Crossfade: Frekans atlanıyor..."));
      await _player.seekToNext();
      _player.play(); // Garantile
    } else {
      await _handleStateTransition(state.mode);
    }
  }

  Future<void> dislikeAndLearn() async {
    if (!state.isPlaying || _isDisliking) return;
    _isDisliking = true;
    HapticFeedback.heavyImpact(); 
    _cancelRewardTimer();
    
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
      debugPrint('🚨 [AURA_PLAYER] İlk frekans bozuk çıktı ($e). Listedeki sıradaki frekansa atlanıyor...');
      // OTO-İYİLEŞME V2: Eğer ilk şarkı yüklenemezse (setAudioSource patlarsa), 
      // bozuk olanı listeden at ve kalanıyla tekrar dene!
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
    _cancelRewardTimer();
    _contextSubscription?.cancel();
    _playerIndexSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _player.dispose();
    return super.close();
  }
}