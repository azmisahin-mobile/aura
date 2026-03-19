import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/aura_state_enum.dart';

class AuraMemoryEngine {
  final SharedPreferences _prefs;

  AuraMemoryEngine(this._prefs);

  String _getKey(AuraState state, TimeContext time, WeatherContext weather) => 
      '${state.name}_${time.name}_${weather.name}';

  List<String> _generateSmartTags(AuraState state, TimeContext time, WeatherContext weather, String country) {
    List<String> tags = [];

    // 1. Temel Durum Bağlamı
    if (state == AuraState.chill) tags.addAll(['lofi', 'chillout', 'acoustic', 'downtempo']);
    if (state == AuraState.energy) tags.addAll(['techno', 'house', 'upbeat', 'rock']);
    if (state == AuraState.focus) tags.addAll(['ambient', 'neoclassical', 'study', 'coding']);

    // 2. Faz 3: Kültürel Bükücü (Reverse Geocoding)
    // DÜZELTME: Radio-Browser ile uyumlu, veritabanında var olan gerçek etiketler.
    if (country.toLowerCase().contains("turkey") || country.toLowerCase().contains("türkiye")) {
      if (state == AuraState.chill) tags.insertAll(0, ['turkce', 'slow', 'acoustic', 'anatolian']);
      if (state == AuraState.energy) tags.insertAll(0, ['pop', 'turkish', 'rock']);
      if (state == AuraState.focus) tags.insertAll(0, ['sufi', 'ney', 'instrumental']);
    }
    if (country.toLowerCase().contains("germany")) {
      if (state == AuraState.energy) tags.insert(0, 'berlin'); // Berlin techno vs.
    }

    // 3. Çevresel Bağlam
    if (weather == WeatherContext.rain && state == AuraState.chill) {
      tags.insertAll(0, ['jazz', 'dark ambient']);
    }
    if (weather == WeatherContext.snow) {
      tags.insertAll(0, ['cinematic', 'piano']);
    }
    if (weather == WeatherContext.clear && state == AuraState.energy) {
      tags.insertAll(0, ['pop', 'synthwave']);
    }

    // 4. Zaman Bağlamı
    if (time == TimeContext.night && state == AuraState.chill) {
      tags.insert(0, 'sleep');
    }
    if (time == TimeContext.morning && state == AuraState.chill) {
      tags.insert(0, 'coffee');
    }

    return tags.toSet().toList(); // Çift kayıtları önlemek için Set kullandık
  }

  String getBestTag(AuraState state, TimeContext time, WeatherContext weather, String country) {
    String key = _getKey(state, time, weather);
    List<String> userTags = _prefs.getStringList(key) ?? _generateSmartTags(state, time, weather, country);
    return userTags.first;
  }

  Future<void> penalizeTag(AuraState state, TimeContext time, WeatherContext weather, String country, String dislikedTag) async {
    String key = _getKey(state, time, weather);
    List<String> tags = _prefs.getStringList(key) ?? _generateSmartTags(state, time, weather, country);
    
    if (tags.contains(dislikedTag)) {
      tags.remove(dislikedTag);
      tags.add(dislikedTag); // Dinlenmeyen türü ceza olarak kuyruğun sonuna it
      await _prefs.setStringList(key, tags);
    }
  }
}