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
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
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
      case AuraState.energy: return Colors.deepOrange.shade900;
      case AuraState.chill: return Colors.indigo.shade900;
      case AuraState.focus: return Colors.teal.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuraCubit, AuraUIState>(
      builder: (context, state) {
        final bgColor = state.isPlaying ? _getBgColor(state.mode) : Colors.black87;

        return Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!state.isPlaying) context.read<AuraCubit>().initializeAndStart();
            },
            onLongPress: () {
              if (state.isPlaying) context.read<AuraCubit>().sleep();
            },
            onHorizontalDragEnd: (details) {
              if (!state.isPlaying) return;
              
              if (details.primaryVelocity! < 0) {
                // Sola Kaydırma (Dislike & Öğren)
                context.read<AuraCubit>().dislikeAndLearn();
              } else if (details.primaryVelocity! > 0) {
                // Sağa Kaydırma (Sadece Geç)
                context.read<AuraCubit>().skip();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              color: bgColor,
              child: Stack(
                children: [
                  Center(
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
                  // Zero-UI Görünmez Rehber (Sadece uyurken görünür)
                  if (!state.isPlaying)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "Uyanmak için dokun",
                          style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 4),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}