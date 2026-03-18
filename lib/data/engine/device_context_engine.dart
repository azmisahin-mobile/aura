import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_context_engine.dart';

class DeviceContextEngine implements IContextEngine {
  final StreamController<AuraState> _stateController = StreamController<AuraState>.broadcast();
  AuraState? _lastEmittedState;
  Timer? _debounceTimer;
  
  AuraState _accelerometerState = AuraState.focus;
  double _currentSpeedKmH = 0.0;
  bool _isAwake = false;

  @override
  Stream<AuraState> get stateStream => _stateController.stream;

  @override
  Future<void> initializePermissions() async {
    // Eğer Aura zaten uyanıksa ve bir durumu varsa, anında fırlat bekleme
    if (_isAwake) {
      if (_lastEmittedState != null) {
        _stateController.add(_lastEmittedState!);
      }
      return;
    }
    
    _isAwake = true;
    
    // Aura uyandırıldı! Şimdi sensörleri dinlemeye başla.
    _initSensors();

    // GPS İzinleri ve Dinleme
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
        ).listen((Position position) {
          _currentSpeedKmH = position.speed * 3.6;
          _evaluateContext();
        });
      }
    }
  }

  void _initSensors() {
    accelerometerEventStream().listen((event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
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
    // Kural: Hız 20'den büyükse Kesinlikle Energy, değilse ivmeölçer ne diyorsa o.
    AuraState targetState = (_currentSpeedKmH > 20.0) ? AuraState.energy : _accelerometerState;

    // Durum değişmediyse işlem yapma
    if (_lastEmittedState == targetState) {
      _debounceTimer?.cancel();
      return;
    }

    // İLK UYANIŞ: Bekleme yapmadan anında müziği başlat!
    if (_lastEmittedState == null) {
      _lastEmittedState = targetState;
      _stateController.add(targetState);
      return;
    }

    // MOD GEÇİŞİ: Yanlışlıkla sarsılmaları engellemek için 2 saniye kararlılık bekle
    if (!(_debounceTimer?.isActive ?? false)) {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _lastEmittedState = targetState;
        _stateController.add(targetState);
      });
    }
  }
}