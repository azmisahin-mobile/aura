import 'dart:math' as math;
import 'dart:ui';
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

class _AuraHomeState extends State<AuraHome> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _fluidController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _fluidController.dispose();
    super.dispose();
  }

  List<Color> _getFluidColors(AuraState mode, WeatherContext weather, bool isPlaying) {
    if (!isPlaying) return [Colors.black87, Colors.black, Colors.black54];

    if (mode == AuraState.energy) {
      return weather == WeatherContext.clear 
          ? [Colors.deepOrange.shade900, Colors.red.shade800, Colors.pink.shade900]
          : [Colors.orange.shade900, Colors.red.shade900, Colors.purple.shade900];
    } else if (mode == AuraState.chill) {
      return weather == WeatherContext.rain || weather == WeatherContext.snow
          ? [Colors.deepPurple.shade900, Colors.indigo.shade900, Colors.black87]
          : [Colors.teal.shade900, Colors.blue.shade900, Colors.indigo.shade900];
    } else {
      return [Colors.blueGrey.shade900, Colors.teal.shade900, Colors.black87];
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocBuilder<AuraCubit, AuraUIState>(
      builder: (context, state) {
        final colors = _getFluidColors(state.mode, state.weather, state.isPlaying);
        
        _fluidController.duration = Duration(seconds: state.mode == AuraState.energy ? 5 : 12);
        if (!_fluidController.isAnimating) _fluidController.repeat();

        return Scaffold(
          backgroundColor: Colors.black,
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
              
              // Yanlışlıkla dokunmaları engellemek için hız (velocity) filtresi eklendi
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) { 
                // Sola hızlı kaydırma (Dislike)
                context.read<AuraCubit>().dislikeAndLearn();
              } else if (velocity > 300) {
                // Sağa hızlı kaydırma (Skip)
                context.read<AuraCubit>().skip();
              }
            },
            child: Stack(
              children: [
                if (state.isPlaying)
                  AnimatedBuilder(
                    animation: _fluidController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          _buildFluidBlob(colors[0], size, 0, 1.0),
                          _buildFluidBlob(colors[1], size, math.pi / 2, 0.8),
                          _buildFluidBlob(colors[2], size, math.pi, 1.2),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                            child: Container(color: Colors.transparent),
                          ),
                        ],
                      );
                    },
                  ),

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

                if (!state.isPlaying)
                  const Positioned(
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
        );
      },
    );
  }

  Widget _buildFluidBlob(Color color, Size size, double offset, double speedMultiplier) {
    final t = _fluidController.value * 2 * math.pi * speedMultiplier;
    final dx = math.sin(t + offset) * (size.width * 0.3);
    final dy = math.cos(t + offset) * (size.height * 0.3);

    return Positioned(
      left: (size.width / 2) - 150 + dx,
      top: (size.height / 2) - 150 + dy,
      child: AnimatedContainer(
        duration: const Duration(seconds: 2),
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.6),
        ),
      ),
    );
  }
}