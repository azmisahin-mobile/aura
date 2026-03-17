import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/aura_bloc.dart';
import '../../core/aura_engine.dart';

class AuraHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuraBloc, AuraStateModel>(
      builder: (context, state) {
        Color bgColor = state.mode == AuraState.energy ? Colors.deepOrange : (state.mode == AuraState.chill ? Colors.indigo : Colors.black87);

        return Scaffold(
          backgroundColor: bgColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("AURA", style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w100, letterSpacing: 10)),
                SizedBox(height: 20),
                Text(state.stationName, style: TextStyle(color: Colors.white70)),
                SizedBox(height: 50),
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.blur_on : Icons.play_arrow, size: 80, color: Colors.white),
                  onPressed: () => context.read<AuraBloc>().startAura(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
