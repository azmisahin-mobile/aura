import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/aura_state_enum.dart';
import '../../logic/cubit/aura_cubit.dart';
import '../../logic/cubit/aura_state.dart';

class AuraHome extends StatefulWidget {
  const AuraHome({Key? key}) : super(key: key);

  @override
  State<AuraHome> createState() => _AuraHomeState();
}

class _AuraHomeState extends State<AuraHome> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    // Zero-UI felsefesi için nefes alma (pulsing) animasyonu
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Color _getBgColor(AuraState mode) {
    switch (mode) {
      case AuraState.energy:
        return Colors.deepOrange.shade900;
      case AuraState.chill:
        return Colors.indigo.shade900;
      case AuraState.focus:
        return Colors.teal.shade900;
    }
  }

  String _getModeText(AuraState mode) {
    switch (mode) {
      case AuraState.energy: return "KİNETİK";
      case AuraState.chill: return "DİNGİN";
      case AuraState.focus: return "ODAK";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuraCubit, AuraUIState>(
      builder: (context, state) {
        final bgColor = state.isPlaying ? _getBgColor(state.mode) : Colors.black87;

        return Scaffold(
          // Ekranın tamamı etkileşim alanıdır (Zero-UI)
          body: GestureDetector(
            onTap: () => context.read<AuraCubit>().togglePower(),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              color: bgColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _breathAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: state.isPlaying ? _breathAnimation.value : 1.0,
                          child: Text(
                            "AURA",
                            style: TextStyle(
                              color: Colors.white.withOpacity(state.isPlaying ? 0.9 : 0.3),
                              fontSize: 54,
                              fontWeight: FontWeight.w100,
                              letterSpacing: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    if (state.isPlaying) ...[
                      Text(
                        _getModeText(state.mode),
                        style: const TextStyle(
                          color: Colors.white54,
                          letterSpacing: 8,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        state.statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}