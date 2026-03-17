import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radio_browser_api/radio_browser_api.dart';
import '../core/aura_engine.dart';

class AuraStateModel {
  final AuraState mode;
  final bool isPlaying;
  final String stationName;

  AuraStateModel(this.mode, this.isPlaying, this.stationName);
}

class AuraBloc extends Cubit<AuraStateModel> {
  final AudioPlayer _player = AudioPlayer();
  // RadioBrowserApi versiyonuna göre constructor kontrolü
  final _api = RadioBrowserApi();

  AuraBloc() : super(AuraStateModel(AuraState.focus, false, "Aura Rezonansı Bekleniyor..."));

  void startAura() {
    AuraEngine.auraStream.listen((mode) async {
      if (mode != state.mode || !state.isPlaying) {
        await _playForMode(mode);
      }
    });
  }

  Future<void> _playForMode(AuraState mode) async {
    // Tag'leri API standartlarına göre netleştirelim
    String tag = mode == AuraState.energy ? 'techno' : (mode == AuraState.chill ? 'lofi' : 'ambient');
    
    try {
      // limit yerine 'parameters' veya direkt liste üzerinden filtreleme gerekebilir
      // En güvenli yol: Arama yap ve ilk 10'dan rastgele seç
      final stations = await _api.getStationsByTag(tag: tag);
      
      if (stations.isNotEmpty) {
        final randomIdx = Random().nextInt(min(stations.length, 10));
        final station = stations[randomIdx];
        await _player.setUrl(station.urlResolved);
        _player.play();
        emit(AuraStateModel(mode, true, station.name));
      }
    } catch (e) {
      emit(AuraStateModel(mode, false, "Bağlantı Hatası: $e"));
    }
  }
}
