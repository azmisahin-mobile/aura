import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../domain/interfaces/i_context_engine.dart';

class DeviceContextEngine implements IContextEngine {
  final SharedPreferences _prefs;
  final StreamController<AuraState> _stateController = StreamController<AuraState>.broadcast();
  
  AuraState? _lastEmittedState;
  Timer? _debounceTimer;

  AuraState _accelerometerState = AuraState.focus;
  double _currentSpeedKmH = 0.0;
  bool _isAwake = false;
  bool _hasGpsPermission = false;

  WeatherContext _currentWeather = WeatherContext.unknown;
  DateTime? _lastWeatherFetch;
  
  // Kültürel Lokasyon
  String _currentCountry = "Unknown";

  // Hysteresis (Sensör Çıldırmasını Önleme)
  final List<double> _magnitudes = [];
  static const int _maxSamples = 10; // Daha geniş örneklem
  int _consecutiveStableReads = 0;
  AuraState _potentialState = AuraState.focus;

  DeviceContextEngine(this._prefs) {
    final cachedWeatherCode = _prefs.getInt('last_weather_code');
    final cachedCountry = _prefs.getString('last_country');
    
    if (cachedWeatherCode != null) {
      _currentWeather = _mapWeatherCode(cachedWeatherCode);
    }
    if (cachedCountry != null) {
      _currentCountry = cachedCountry;
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

      AuraState newState;
      if (avgMagnitude > 16.0) {
        newState = AuraState.energy; // Eşik yükseltildi, koşu/hızlı yürüyüş
      } else if (avgMagnitude > 12.0) {
        newState = AuraState.chill; // Normal yürüyüş
      } else {
        newState = AuraState.focus; // Sabit / Masaüstü
      }

      // Hysteresis: Modun değişmesi için peş peşe 5 okumada aynı kalması lazım
      if (newState == _potentialState) {
        _consecutiveStableReads++;
        if (_consecutiveStableReads > 5) {
          if (_accelerometerState != newState) {
            _accelerometerState = newState;
            _evaluateContext();
          }
        }
      } else {
        _potentialState = newState;
        _consecutiveStableReads = 0;
      }
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
          distanceFilter: 50, // GPS Pil Optimizasyonu artırıldı
        ),
      ).listen((Position position) {
        _currentSpeedKmH = position.speed * 3.6;
        _updateWeatherAndLocationIfNeeded(position.latitude, position.longitude);
        _evaluateContext();
      }, onError: (e) {
        debugPrint('GPS hatası: $e');
        _hasGpsPermission = false;
      });
    }
  }

  Future<void> _updateWeatherAndLocationIfNeeded(double lat, double lon) async {
    final now = DateTime.now();
    if (_lastWeatherFetch != null && now.difference(_lastWeatherFetch!).inMinutes < 30) {
      return; 
    }
    _lastWeatherFetch = now;
    
    // 1. Hava Durumu
    try {
      final uri = Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true");
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final code = data['current_weather']['weathercode'] as int;
        _currentWeather = _mapWeatherCode(code);
        await _prefs.setInt('last_weather_code', code);
      }
    } catch (e) {
      debugPrint('⚠️ Hava durumu alınamadı: $e');
    }

    // 2. Kültürel Lokasyon (Reverse Geocoding)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        String country = placemarks.first.country ?? "Unknown";
        if (country != _currentCountry) {
          _currentCountry = country;
          await _prefs.setString('last_country', country);
          debugPrint('🌍 [CULTURE] Yeni Kültürel Alan Algılandı: $_currentCountry');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Lokasyon çevrilemedi: $e');
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
    AuraState targetState = (_hasGpsPermission && _currentSpeedKmH > 25.0) 
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
      _debounceTimer = Timer(const Duration(seconds: 3), () {
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
  String getCurrentCountry() => _currentCountry;
}