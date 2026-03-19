import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/aura_state_enum.dart';

class AuraMemoryEngine {
  final SharedPreferences _prefs;

  AuraMemoryEngine(this._prefs);

  String _getKey(AuraState state, TimeContext time, WeatherContext weather) => 
      '${state.name}_${time.name}_${weather.name}';

  // Çevresel ve biyolojik verilere göre en uygun havuzu oluşturur
  List<String> _generateSmartTags(AuraState state, TimeContext time, WeatherContext weather) {
    List<String> tags = [];

    // 1. Temel Durum Bağlamı
    if (state == AuraState.chill) tags.addAll(['lofi', 'chillout', 'acoustic', 'downtempo']);
    if (state == AuraState.energy) tags.addAll(['techno', 'house', 'upbeat', 'rock']);
    if (state == AuraState.focus) tags.addAll(['ambient', 'neoclassical', 'study', 'coding']);

    // 2. Çevresel Bağlam (Hava Durumu Bükücü)
    if (weather == WeatherContext.rain && state == AuraState.chill) {
      tags.insertAll(0, ['jazz', 'dark ambient']); // Yağmurda chill dinliyorsa başa jazz koy
    }
    if (weather == WeatherContext.snow) {
      tags.insertAll(0, ['cinematic', 'piano']); // Karda sinematik etki yarat
    }
    if (weather == WeatherContext.clear && state == AuraState.energy) {
      tags.insertAll(0, ['pop', 'synthwave']); // Güneşli havada enerjikse pop/synthwave koy
    }

    // 3. Zaman Bağlamı
    if (time == TimeContext.night && state == AuraState.chill) {
      tags.insert(0, 'sleep');
    }
    if (time == TimeContext.morning && state == AuraState.chill) {
      tags.insert(0, 'coffee');
    }

    return tags.toSet().toList(); // Çift olanları sil
  }

  // Kullanıcının seveceği tag'i bul
  String getBestTag(AuraState state, TimeContext time, WeatherContext weather) {
    String key = _getKey(state, time, weather);
    List<String> userTags = _prefs.getStringList(key) ?? _generateSmartTags(state, time, weather);
    return userTags.first;
  }

  // Sola kaydırdığında (Beğenmediğinde) bu tag'i listenin sonuna at, yeniyi öne al
  Future<void> penalizeTag(AuraState state, TimeContext time, WeatherContext weather, String dislikedTag) async {
    String key = _getKey(state, time, weather);
    List<String> tags = _prefs.getStringList(key) ?? _generateSmartTags(state, time, weather);
    
    if (tags.contains(dislikedTag)) {
      tags.remove(dislikedTag);
      tags.add(dislikedTag); // Dinlenmeyen türü ceza olarak kuyruğun sonuna it
      await _prefs.setStringList(key, tags);
    }
  }
}