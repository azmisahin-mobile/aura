import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // debugPrint için EKLENDİ
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
  bool _hasGpsPermission = false;

  // Basit moving average için
  final List<double> _magnitudes = [];
  static const int _maxSamples = 5;

  @override
  Stream<AuraState> get stateStream => _stateController.stream;

  @override
  Future<void> initializePermissions() async {
    if (_isAwake) {
      if (_lastEmittedState != null) _stateController.add(_lastEmittedState!);
      return;
    }
    _isAwake = true;
    _initSensors();
    await _initGPS();
  }

  void _initSensors() {
    accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval).listen((event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Moving average
      _magnitudes.add(magnitude);
      if (_magnitudes.length > _maxSamples) _magnitudes.removeAt(0);
      double avgMagnitude = _magnitudes.reduce((a, b) => a + b) / _magnitudes.length;

      if (avgMagnitude > 15.0) {
        _accelerometerState = AuraState.energy;
      } else if (avgMagnitude > 11.5) {
        _accelerometerState = AuraState.chill;
      } else {
        _accelerometerState = AuraState.focus;
      }
      _evaluateContext();
    });
  }

  Future<void> _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    _hasGpsPermission = (permission == LocationPermission.whileInUse || permission == LocationPermission.always);

    if (_hasGpsPermission) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Daha az pil tüketimi
          distanceFilter: 20, // 20 metrede bir güncelle
        ),
      ).listen((Position position) {
        _currentSpeedKmH = position.speed * 3.6;
        _evaluateContext();
      }, onError: (e) {
        debugPrint('GPS hatası: $e');
        _hasGpsPermission = false;
      });
    }
  }

  void _evaluateContext() {
    AuraState targetState;
    if (_hasGpsPermission && _currentSpeedKmH > 20.0) {
      targetState = AuraState.energy;
    } else {
      targetState = _accelerometerState;
    }

    if (_lastEmittedState == targetState) {
      _debounceTimer?.cancel();
      return;
    }

    if (_lastEmittedState == null) {
      _lastEmittedState = targetState;
      _stateController.add(targetState);
      return;
    }

    if (!(_debounceTimer?.isActive ?? false)) {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _lastEmittedState = targetState;
        _stateController.add(targetState);
      });
    }
  }

  TimeContext getCurrentTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return TimeContext.morning;
    if (hour >= 12 && hour < 18) return TimeContext.afternoon;
    if (hour >= 18 && hour < 23) return TimeContext.evening;
    return TimeContext.night;
  }
}