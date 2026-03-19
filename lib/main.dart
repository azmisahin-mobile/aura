import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/engine/device_context_engine.dart';
import 'data/engine/aura_memory_engine.dart';
import 'data/engine/api_resolver_engine.dart';
import 'data/providers/master_audio_repository.dart';
import 'data/providers/radio_browser_provider.dart';
import 'data/providers/youtube_fallback_provider.dart';
import 'data/providers/offline_audio_provider.dart';
import 'logic/cubit/aura_cubit.dart';
import 'ui/screens/aura_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  
  // Motorlar
  final memoryEngine = AuraMemoryEngine(prefs);
  final apiResolver = ApiResolverEngine(prefs); // Yeni Network Zekası
  final contextEngine = DeviceContextEngine();
  
  // Ölümsüzlük Zinciri (Chain of Responsibility)
  final audioRepo = MasterAudioRepository(
    primaryProvider: RadioBrowserProvider(apiResolver),
    fallbackProvider: YouTubeFallbackProvider(apiResolver), // Piped + Invidious
    offlineProvider: OfflineAudioProvider(),
  );

  runApp(AuraApp(
    contextEngine: contextEngine,
    memoryEngine: memoryEngine,
    audioRepo: audioRepo,
  ));
}

class AuraApp extends StatelessWidget {
  final DeviceContextEngine contextEngine;
  final AuraMemoryEngine memoryEngine;
  final MasterAudioRepository audioRepo;

  const AuraApp({
    Key? key, 
    required this.contextEngine, 
    required this.memoryEngine,
    required this.audioRepo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuraCubit(contextEngine, memoryEngine, audioRepo),
      child: MaterialApp(
        title: 'AURA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Roboto',
        ),
        home: const AuraHome(),
      ),
    );
  }
}