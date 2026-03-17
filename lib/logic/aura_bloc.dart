import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../core/aura_engine.dart';

class AuraStateModel {
  final AuraState mode;
  final bool isPlaying;
  final String stationName;

  AuraStateModel(this.mode, this.isPlaying, this.stationName);
}

class AuraBloc extends Cubit<AuraStateModel> {
  final AudioPlayer _player = AudioPlayer();
  // Radio Browser API'nin en stabil node'larından birini doğrudan kullanıyoruz
  final String _baseUrl = "https://de1.api.radio-browser.info/json/stations/search";

  AuraBloc() : super(AuraStateModel(AuraState.focus, false, "Aura Rezonansı Bekleniyor..."));

  void startAura() {
    AuraEngine.auraStream.listen((mode) async {
      // Sadece mod değiştiyse veya çalmıyorsa müdahale et
      if (mode != state.mode || !state.isPlaying) {
        await _playForMode(mode);
      }
    });
  }

  Future<void> _playForMode(AuraState mode) async {
    String tag = mode == AuraState.energy ? 'techno' : (mode == AuraState.chill ? 'lofi' : 'ambient');
    emit(AuraStateModel(mode, false, "$tag frekansları taranıyor..."));

    try {
      final uri = Uri.parse("$_baseUrl?tag=$tag&limit=10&hidebroken=true&order=clickcount&reverse=true");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> stations = jsonDecode(response.body);
        
        if (stations.isNotEmpty) {
          final station = stations[Random().nextInt(stations.length)];
          final streamUrl = station['url_resolved'] ?? station['url'];
          final stationName = station['name'] ?? 'Bilinmeyen Frekans';

          await _player.setUrl(streamUrl);
          _player.play();
          emit(AuraStateModel(mode, true, stationName));
        } else {
          emit(AuraStateModel(mode, false, "Uygun frekans bulunamadı."));
        }
      } else {
        emit(AuraStateModel(mode, false, "Ağ Hatası: ${response.statusCode}"));
      }
    } catch (e) {
      emit(AuraStateModel(mode, false, "Bağlantı Koptu: $e"));
    }
  }
}
