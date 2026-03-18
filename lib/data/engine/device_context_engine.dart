import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_context_engine.dart';

class DeviceContextEngine implements IContextEngine {
  final StreamController<AuraState> _stateController = StreamController<AuraState>.broadcast();
  AuraState? _currentState;
  
  AuraState _accelerometerState = AuraState.focus;
  double _currentSpeedKmH = 0.0;

  DeviceContextEngine() {
    _initSensors();
  }

  @override
  Stream<AuraState> get stateStream => _stateController.stream.distinct();

  @override
  Future<void> initializePermissions() async {
    // İlk tıklamada hemen başlangıç durumunu fırlat (Bekletmemek için)
    _evaluateContext();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // GPS Dinlemeye başla
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      _currentSpeedKmH = position.speed * 3.6;
      _evaluateContext();
    });
  }

  void _initSensors() {
    accelerometerEventStream().listen((event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Hassasiyet eşikleri düzenlendi
      if (magnitude > 15.0) {
        _accelerometerState = AuraState.energy;
      } else if (magnitude > 11.5) {
        _accelerometerState = AuraState.chill;
      } else {
        _accelerometerState = AuraState.focus;
      }
      _evaluateContext();
    });
  }

  void _evaluateContext() {
    AuraState evaluatedState;
    
    // GPS hızı 20km/h üzerindeyse kesinlikle Energy modudur.
    if (_currentSpeedKmH > 20.0) {
      evaluatedState = AuraState.energy;
    } else {
      // Değilse ivmeölçere güven
      evaluatedState = _accelerometerState;
    }

    if (_currentState != evaluatedState) {
      _currentState = evaluatedState;
      _stateController.add(_currentState!);
    }
  }
}