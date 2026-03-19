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

    if (state == AuraState.chill) tags.addAll(['lofi', 'chillout', 'acoustic', 'downtempo', 'jazz', 'ambient']);
    if (state == AuraState.energy) tags.addAll(['techno', 'house', 'upbeat', 'rock', 'synthwave', 'dance']);
    if (state == AuraState.focus) tags.addAll(['ambient', 'neoclassical', 'study', 'coding', 'instrumental', 'piano']);

    if (countryCode == "TR") {
      if (state == AuraState.chill) tags.insertAll(0,['slow', 'turkce']);
      if (state == AuraState.energy) tags.insertAll(0,['pop', 'hit', 'arabesk']);
      if (state == AuraState.focus) tags.insertAll(0, ['islamic', 'din', 'klasik', 'ney']);
    } else if (countryCode == "DE") {
      if (state == AuraState.energy) tags.insert(0, 'berlin'); 
    }

    if (weather == WeatherContext.rain && state == AuraState.chill) tags.insertAll(0, ['jazz', 'dark ambient']);
    if (weather == WeatherContext.snow) tags.insertAll(0, ['cinematic', 'piano']);
    if (weather == WeatherContext.clear && state == AuraState.energy) tags.insertAll(0, ['pop', 'synthwave']);

    if (time == TimeContext.night && state == AuraState.chill) tags.insert(0, 'sleep');
    if (time == TimeContext.morning && state == AuraState.chill) tags.insert(0, 'coffee');

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

    // 1. KARALİSTE FİLTRESİ (Puanı 40'ın altında olan "Nefret Edilenleri" havuzdan tamamen çıkar)
    List<String> validPool = pool.where((tag) => (weights[tag] ?? 50) >= 40).toList();
    
    // Eğer kullanıcı her şeyden nefret ettiyse ve havuz boşaldıysa, sistemi sıfırla (hepsi 50 puan olsun)
    if (validPool.isEmpty) {
      debugPrint('⚠️ [AI_SYSTEM] Kullanıcı her şeyden nefret etti. Havuz sıfırlanıyor!');
      validPool = pool; 
    }

    validPool.sort((a, b) {
      int scoreA = weights[a] ?? 50;
      int scoreB = weights[b] ?? 50;
      return scoreB.compareTo(scoreA); 
    });

    // 2. KEŞİF (Sadece nefret edilmeyenler arasından rastgele seç)
    bool explore = _random.nextDouble() < 0.20;
    
    if (explore) {
      String randomTag = validPool[_random.nextInt(validPool.length)];
      debugPrint('🎲 [AI_DECISION] AURA Keşif Modunda: $randomTag denenecek.');
      return randomTag;
    } else {
      String bestTag = validPool.first;
      debugPrint('🧠 [AI_DECISION] AURA Öğrenilmiş Favoriyi Seçti: $bestTag (Puan: ${weights[bestTag] ?? 50})');
      return bestTag;
    }
  }

  Future<void> updateTagScore(String tag, int delta) async {
    Map<String, int> weights = _getWeights();
    int currentScore = weights[tag] ?? 50;
    int newScore = currentScore + delta;
    
    if (newScore > 100) newScore = 100;
    if (newScore < 0) newScore = 0; // Puan eksiye düşemez
    
    weights[tag] = newScore;
    await _saveWeights(weights);

    if (delta > 0) {
      debugPrint('📈 [AI_LEARN] AURA Ödüllendirdi: $tag -> $newScore Puan');
    } else {
      debugPrint('📉 [AI_LEARN] AURA Cezalandırdı: $tag -> $newScore Puan');
      if (newScore < 40) {
        debugPrint('🚫 [AI_BLACKLIST] "$tag" karalisteye eklendi! Artık çalınmayacak.');
      }
    }
  }
}