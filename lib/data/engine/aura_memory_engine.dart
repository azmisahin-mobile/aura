import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/aura_state_enum.dart';

class AuraMemoryEngine {
  final SharedPreferences _prefs;
  final Random _random = Random();
  static const String _aiWeightsKey = "aura_ai_weights";

  AuraMemoryEngine(this._prefs);

  List<String> _generateSmartTags(AuraState state, TimeContext time, WeatherContext weather, String countryCode) {
    List<String> tags =[];

    // 1. EVRENSEL TABAN (Müzik evrenseldir, sınırları kaldırıyoruz)
    if (state == AuraState.chill) tags.addAll(['lofi', 'chillout', 'acoustic', 'downtempo', 'jazz', 'ambient']);
    if (state == AuraState.energy) tags.addAll(['techno', 'house', 'upbeat', 'rock', 'synthwave', 'dance']);
    if (state == AuraState.focus) tags.addAll(['ambient', 'neoclassical', 'study', 'coding', 'instrumental', 'piano']);

    // 2. KÜLTÜREL SOS (Evrensel havuzun başına eklenir, böylece AI hepsini bilir)
    if (countryCode == "TR") {
      if (state == AuraState.chill) tags.insertAll(0, ['slow', 'turkce']);
      if (state == AuraState.energy) tags.insertAll(0, ['pop', 'hit', 'arabesk']);
      if (state == AuraState.focus) tags.insertAll(0, ['islamic', 'din', 'klasik', 'ney']);
    } else if (countryCode == "DE") {
      if (state == AuraState.energy) tags.insert(0, 'berlin'); 
    }

    // 3. ÇEVRESEL BÜKÜCÜLER
    if (weather == WeatherContext.rain && state == AuraState.chill) tags.insertAll(0, ['jazz', 'dark ambient']);
    if (weather == WeatherContext.snow) tags.insertAll(0, ['cinematic', 'piano']);
    if (weather == WeatherContext.clear && state == AuraState.energy) tags.insertAll(0, ['pop', 'synthwave']);

    if (time == TimeContext.night && state == AuraState.chill) tags.insert(0, 'sleep');
    if (time == TimeContext.morning && state == AuraState.chill) tags.insert(0, 'coffee');

    // Çiftleri temizle ve listeyi dön
    return tags.toSet().toList(); 
  }

  Map<String, int> _getWeights() {
    String? jsonStr = _prefs.getString(_aiWeightsKey);
    if (jsonStr != null) {
      return Map<String, int>.from(jsonDecode(jsonStr));
    }
    return {};
  }

  Future<void> _saveWeights(Map<String, int> weights) async {
    await _prefs.setString(_aiWeightsKey, jsonEncode(weights));
  }

  String getBestTag(AuraState state, TimeContext time, WeatherContext weather, String countryCode) {
    List<String> pool = _generateSmartTags(state, time, weather, countryCode);
    Map<String, int> weights = _getWeights();

    pool.sort((a, b) {
      int scoreA = weights[a] ?? 50;
      int scoreB = weights[b] ?? 50;
      return scoreB.compareTo(scoreA); // Puanı yüksek olan başa geçer
    });

    // %20 İhtimalle yeni bir şey keşfet, %80 ihtimalle kullanıcının en sevdiğini çal
    bool explore = _random.nextDouble() < 0.20;
    
    if (explore) {
      String randomTag = pool[_random.nextInt(pool.length)];
      debugPrint('🎲 [AI_DECISION] AURA Keşif Modunda: $randomTag denenecek.');
      return randomTag;
    } else {
      String bestTag = pool.first;
      debugPrint('🧠 [AI_DECISION] AURA Öğrenilmiş Favoriyi Seçti: $bestTag (Puan: ${weights[bestTag] ?? 50})');
      return bestTag;
    }
  }

  Future<void> updateTagScore(String tag, int delta) async {
    Map<String, int> weights = _getWeights();
    int currentScore = weights[tag] ?? 50;
    int newScore = currentScore + delta;
    
    if (newScore > 100) newScore = 100;
    if (newScore < 0) newScore = 0;
    
    weights[tag] = newScore;
    await _saveWeights(weights);

    if (delta > 0) {
      debugPrint('📈 [AI_LEARN] AURA Ödüllendirdi: $tag -> $newScore Puan');
    } else {
      debugPrint('📉 [AI_LEARN] AURA Cezalandırdı: $tag -> $newScore Puan');
    }
  }
}