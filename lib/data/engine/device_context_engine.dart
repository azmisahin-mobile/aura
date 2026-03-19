import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // EKLENDİ
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_context_engine.dart';

class DeviceContextEngine implements IContextEngine {
  final SharedPreferences _prefs; // HAFIZA EKLENDİ
  final StreamController<AuraState> _stateController = StreamController<AuraState>.broadcast();
  
  AuraState? _lastEmittedState;
  Timer? _debounceTimer;

  AuraState _accelerometerState = AuraState.focus;
  double _currentSpeedKmH = 0.0;
  bool _isAwake = false;
  bool _hasGpsPermission = false;

  WeatherContext _currentWeather = WeatherContext.unknown;
  DateTime? _lastWeatherFetch;

  final List<double> _magnitudes = [];
  static const int _maxSamples = 5;

  DeviceContextEngine(this._prefs) {
    // UYGULAMA AÇILIR AÇILMAZ SON HAVA DURUMUNU HAFIZADAN YÜKLE (GECİKMEYİ SIFIRLA)
    final cachedWeatherCode = _prefs.getInt('last_weather_code');
    if (cachedWeatherCode != null) {
      _currentWeather = _mapWeatherCode(cachedWeatherCode);
      debugPrint('⚡ [ENVIRONMENT] Hafızadan Hava Durumu Yüklendi: ${_currentWeather.name}');
    }
  }

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
          accuracy: LocationAccuracy.medium, 
          distanceFilter: 20, 
        ),
      ).listen((Position position) {
        _currentSpeedKmH = position.speed * 3.6;
        _updateWeatherIfNeeded(position.latitude, position.longitude);
        _evaluateContext();
      }, onError: (e) {
        debugPrint('GPS hatası: $e');
        _hasGpsPermission = false;
      });
    }
  }

  Future<void> _updateWeatherIfNeeded(double lat, double lon) async {
    final now = DateTime.now();
    if (_lastWeatherFetch != null && now.difference(_lastWeatherFetch!).inMinutes < 30) {
      return; 
    }
    _lastWeatherFetch = now;
    try {
      final uri = Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true");
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final code = data['current_weather']['weathercode'] as int;
        
        _currentWeather = _mapWeatherCode(code);
        await _prefs.setInt('last_weather_code', code); // YENİ HAVA DURUMUNU HAFIZAYA YAZ
        
        debugPrint('🌤️ [ENVIRONMENT] Çevresel Bağlam Güncellendi: ${_currentWeather.name.toUpperCase()}');
      }
    } catch (e) {
      debugPrint('⚠️ [ENVIRONMENT] Hava durumu alınamadı: $e');
    }
  }

  WeatherContext _mapWeatherCode(int code) {
    if (code == 0 || code == 1) return WeatherContext.clear;
    if (code >= 2 && code <= 48) return WeatherContext.cloudy;
    if (code >= 51 && code <= 67) return WeatherContext.rain;
    if (code >= 71 && code <= 86) return WeatherContext.snow;
    if (code >= 95) return WeatherContext.rain; 
    return WeatherContext.unknown;
  }

  void _evaluateContext() {
    AuraState targetState = (_hasGpsPermission && _currentSpeedKmH > 20.0) 
        ? AuraState.energy 
        : _accelerometerState;

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

  WeatherContext getCurrentWeatherContext() => _currentWeather;
}