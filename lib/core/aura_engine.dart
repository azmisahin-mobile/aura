import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum AuraState { chill, energy, focus }

class AuraEngine {
  static Stream<AuraState> get auraStream =>
      accelerometerEvents.map((event) {
        // Vektör büyüklüğünü hesapla
        double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        
        if (magnitude > 15.0) return AuraState.energy; // Koşma/Sallama
        if (magnitude > 10.5) return AuraState.chill;  // Yürüme
        return AuraState.focus;                         // Sabit durma
      }).distinct();
}
