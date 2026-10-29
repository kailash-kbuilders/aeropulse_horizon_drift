import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/game_state.dart';
import '../widgets/car_silhouette.dart';
import '../widgets/glass_panel.dart';
import 'garage_screen.dart';
import 'track_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 210),
                        child: Image.asset(
                          'assets/branding/logo.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'HORIZON  DRIFT',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF22D3EE),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Real physics. Pure 3D. Built with Flutter.',
                        style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: <Widget>[
                          _ActionButton(
                            label: 'RACE',
                            filled: true,
                            icon: Icons.play_arrow_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TrackSelectScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _ActionButton(
                            label: 'GARAGE',
                            filled: false,
                            icon: Icons.tune_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GarageScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  flex: 4,
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'CURRENT BUILD',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 2.4,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: CarSilhouette(
                            car: gs.selectedCar,
                            paint: gs.paint,
                            rim: gs.rim,
                            finish: gs.finish,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gs.selectedCar.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gs.selectedCar.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0x8AFFFFFF)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Icon(gs.track.icon, size: 14, color: gs.track.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                gs.track.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: gs.track.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF22D3EE);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: filled ? accent : Colors.transparent,
          border: Border.all(color: filled ? accent : const Color(0x44FFFFFF)),
          boxShadow: filled
              ? <BoxShadow>[
                  BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: filled ? const Color(0xFF04121A) : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w800,
                color: filled ? const Color(0xFF04121A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
