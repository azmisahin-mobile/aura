import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/engine/device_context_engine.dart';
import 'data/providers/radio_browser_provider.dart';
import 'logic/cubit/aura_cubit.dart';
import 'ui/screens/aura_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Status barı gizle (Minimalist tasarım için)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Dependency Injection (Uygulama büyüyecekse get_it kullanılabilir, şimdilik manuel)
  final contextEngine = DeviceContextEngine();
  final audioProvider = RadioBrowserProvider();

  runApp(AuraApp(
    contextEngine: contextEngine,
    audioProvider: audioProvider,
  ));
}

class AuraApp extends StatelessWidget {
  final DeviceContextEngine contextEngine;
  final RadioBrowserProvider audioProvider;

  const AuraApp({
    Key? key, 
    required this.contextEngine, 
    required this.audioProvider
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuraCubit(contextEngine, audioProvider),
      child: MaterialApp(
        title: 'AURA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Roboto', // Varsa projeye özel font eklenebilir
        ),
        home: const AuraHome(),
      ),
    );
  }
}