import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Bu motor, verilen statik API listesindeki tüm sunuculara paralel Ping (Health Check) atar.
/// İlk geçerli 200 OK dönen sunucuyu (En düşük gecikme / Fastest) seçer ve hafızaya yazar.
class ApiResolverEngine {
  final SharedPreferences _prefs;
  final http.Client _client = http.Client();

  ApiResolverEngine(this._prefs);

  Future<String> getFastestInstance({
    required String cacheKey,
    required List<String> instances,
    required String healthPath,
  }) async {
    // 1. Cache kontrolü (Eğer önceden çalışan hızlı bir sunucu varsa önce onu dene)
    final cachedInstance = _prefs.getString(cacheKey);
    if (cachedInstance != null) {
      try {
        final uri = Uri.parse("https://$cachedInstance$healthPath");
        final res = await _client.get(uri).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          debugPrint('⚡ [RESOLVER] Önbellekten çalışan sunucu bulundu: $cachedInstance');
          return cachedInstance;
        }
      } catch (_) {
        debugPrint('⚠️ [RESOLVER] Önbellekteki sunucu çökmüş, yeni arayışa geçiliyor: $cachedInstance');
      }
    }

    // 2. Cache çalışmıyorsa Paralel Yarış (Race Condition)
    debugPrint('🔍 [RESOLVER] $cacheKey için sunucular yarıştırılıyor...');
    final completer = Completer<String>();
    int errors = 0;

    for (final instance in instances) {
      _client.get(Uri.parse("https://$instance$healthPath")).timeout(const Duration(seconds: 3)).then((res) {
        if (res.statusCode == 200 && !completer.isCompleted) {
          completer.complete(instance);
        } else {
          _handleError(instances.length, ++errors, completer);
        }
      }).catchError((_) {
        _handleError(instances.length, ++errors, completer);
      });
    }

    final fastestInstance = await completer.future;
    
    // Bulunan en hızlı sunucuyu hafızaya yaz
    await _prefs.setString(cacheKey, fastestInstance);
    debugPrint('🏆 [RESOLVER] En hızlı sunucu kazandı: $fastestInstance');
    
    return fastestInstance;
  }

  void _handleError(int total, int currentErrors, Completer<String> completer) {
    if (currentErrors == total && !completer.isCompleted) {
      completer.completeError(Exception("Tüm sunucular başarısız oldu."));
    }
  }
}