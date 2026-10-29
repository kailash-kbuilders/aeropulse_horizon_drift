import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track_model.dart';
import '../state/game_state.dart';
import '../widgets/glass_panel.dart';
import 'game_screen.dart';

class TrackSelectScreen extends StatelessWidget {
  const TrackSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF05070D), Color(0xFF0A1826), Color(0xFF05070D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'SELECT TRACK',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${gs.selectedCar.name}  •  3 LAPS',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        color: Color(0x88FFFFFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: kTracks.map((TrackModel t) {
                      final selected = t.id == gs.track.id;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: GestureDetector(
                            onTap: () => gs.selectTrack(t),
                            child: GlassPanel(
                              tint: selected
                                  ? t.accent.withValues(alpha: 0.14)
                                  : const Color(0x12FFFFFF),
                              border: selected
                                  ? t.accent.withValues(alpha: 0.6)
                                  : const Color(0x22FFFFFF),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(t.icon, size: 22, color: t.accent),
                                      const Spacer(),
                                      if (selected)
                                        Icon(Icons.check_circle_rounded, size: 16, color: t.accent),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.description,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      color: Color(0x99FFFFFF),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 3,
                                    width: 46,
                                    decoration: BoxDecoration(
                                      color: t.accent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const GameScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF22D3EE),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'START  •  ${gs.track.name.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 2.6,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF04121A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
