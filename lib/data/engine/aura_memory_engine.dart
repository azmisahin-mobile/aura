import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/aura_state_enum.dart';

class AuraMemoryEngine {
  final SharedPreferences _prefs;

  AuraMemoryEngine(this._prefs);

  // Standart felsefe eşleşmeleri
  final Map<String, List<String>> _baseTags = {
    'chill_morning': ['acoustic', 'lofi', 'jazz'],
    'chill_afternoon': ['lofi', 'chillout', 'reggae'],
    'chill_evening': ['downtempo', 'lofi', 'lounge'],
    'chill_night': ['dark ambient', 'drone', 'sleep'],
    
    'focus_morning': ['neoclassical', 'piano', 'ambient'],
    'focus_afternoon': ['study', 'ambient', 'classical'],
    'focus_evening': ['coding', 'synthwave', 'ambient'],
    'focus_night': ['space', 'deep focus', 'binaural'],

    'energy_morning': ['upbeat', 'pop', 'house'],
    'energy_afternoon': ['rock', 'techno', 'edm'],
    'energy_evening': ['techno', 'trance', 'dnb'],
    'energy_night': ['hardstyle', 'techno', 'phonk'],
  };

  String _getKey(AuraState state, TimeContext time) => '${state.name}_${time.name}';

  // Kullanıcının seveceği tag'i bul (Beğenmedikleri arkaya itilir)
  String getBestTag(AuraState state, TimeContext time) {
    String key = _getKey(state, time);
    List<String> userTags = _prefs.getStringList(key) ?? _baseTags[key]!;
    return userTags.first;
  }

  // Sola kaydırdığında (Beğenmediğinde) bu tag'i listenin sonuna at, yeniyi öne al
  Future<void> penalizeTag(AuraState state, TimeContext time, String dislikedTag) async {
    String key = _getKey(state, time);
    List<String> tags = _prefs.getStringList(key) ?? _baseTags[key]!;
    
    if (tags.contains(dislikedTag)) {
      tags.remove(dislikedTag);
      tags.add(dislikedTag); // Sona at
      await _prefs.setStringList(key, tags);
    }
  }
}