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
  final RadioBrowserApi _api = RadioBrowserApi();

  AuraBloc() : super(AuraStateModel(AuraState.focus, false, "Aura Rezonansı Bekleniyor..."));

  void startAura() {
    AuraEngine.auraStream.listen((mode) async {
      if (mode != state.mode || !state.isPlaying) {
        await _playForMode(mode);
      }
    });
  }

  Future<void> _playForMode(AuraState mode) async {
    String tag = mode == AuraState.energy ? 'techno' : (mode == AuraState.chill ? 'lofi' : 'ambient');
    
    final stations = await _api.getStationsByTag(tag: tag, limit: 10);
    if (stations.isNotEmpty) {
      final station = stations[Random().nextInt(stations.length)];
      await _player.setUrl(station.urlResolved ?? station.url);
      _player.play();
      emit(AuraStateModel(mode, true, station.name));
    }
  }
}
