import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car_model.dart';
import '../state/game_state.dart';
import '../widgets/car_silhouette.dart';
import '../widgets/glass_panel.dart';
import '../widgets/stat_bar.dart';
import 'game_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<GameState>().carIndex,
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final car = gs.selectedCar;

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
                      'GARAGE',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${gs.carIndex + 1} / ${kCars.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Color(0x88FFFFFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: kCars.length,
                          onPageChanged: gs.selectCar,
                          itemBuilder: (BuildContext context, int index) {
                            final item = kCars[index];
                            final selected = index == gs.carIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: GlassPanel(
                                tint: selected
                                    ? const Color(0x1F22D3EE)
                                    : const Color(0x12FFFFFF),
                                border: selected
                                    ? const Color(0x6622D3EE)
                                    : const Color(0x22FFFFFF),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          item.classLabel,
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 2.4,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF22D3EE)
                                                .withValues(alpha: selected ? 1 : 0.6),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (selected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 15,
                                            color: Color(0xFF22D3EE),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: CarSilhouette(
                                        car: item,
                                        paint: selected ? gs.paint : const Color(0xFF5A6270),
                                        rim: gs.rim,
                                        finish: gs.finish,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.tagline,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0x8AFFFFFF)),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 5,
                        child: GlassPanel(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'PAINT',
                                style: _labelStyle,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: kPaintPalette.map((Color c) {
                                  final selected = c.toARGB32() == gs.paint.toARGB32();
                                  return GestureDetector(
                                    onTap: () => gs.setPaint(c),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected ? Colors.white : const Color(0x33FFFFFF),
                                          width: selected ? 2.5 : 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Text('FINISH', style: _labelStyle),
                              const SizedBox(height: 8),
                              Row(
                                children: kFinishes.map((String f) {
                                  final selected = f == gs.finish;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => gs.setFinish(f),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: selected
                                              ? const Color(0x3322D3EE)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? const Color(0xFF22D3EE)
                                                : const Color(0x33FFFFFF),
                                          ),
                                        ),
                                        child: Text(
                                          f.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 1.4,
                                            fontWeight: FontWeight.w700,
                                            color: selected ? Colors.white : const Color(0x99FFFFFF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Text('RIMS', style: _labelStyle),
                              const SizedBox(height: 8),
                              Row(
                                children: List<Widget>.generate(kRimNames.length, (int i) {
                                  final selected = i == gs.rim;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => gs.setRim(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: selected
                                              ? const Color(0x3322D3EE)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? const Color(0xFF22D3EE)
                                                : const Color(0x33FFFFFF),
                                          ),
                                        ),
                                        child: Text(
                                          kRimNames[i].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 1.4,
                                            fontWeight: FontWeight.w700,
                                            color: selected ? Colors.white : const Color(0x99FFFFFF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 14),
                              const Text('PERFORMANCE', style: _labelStyle),
                              const SizedBox(height: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      StatBar(
                                        label: 'Speed',
                                        value: car.speedStat,
                                        color: const Color(0xFF22D3EE),
                                      ),
                                      StatBar(
                                        label: 'Accel',
                                        value: car.accelStat,
                                        color: const Color(0xFF39FF88),
                                      ),
                                      StatBar(
                                        label: 'Handling',
                                        value: car.handlingStat,
                                        color: const Color(0xFFF5C542),
                                      ),
                                      StatBar(
                                        label: 'Braking',
                                        value: car.brakingStat,
                                        color: const Color(0xFFFF3D68),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const GameScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFF22D3EE),
                                    ),
                                    child: const Text(
                                      'RACE THIS BUILD',
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 2.4,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF04121A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

const TextStyle _labelStyle = TextStyle(
  fontSize: 9,
  letterSpacing: 2.4,
  fontWeight: FontWeight.w700,
  color: Color(0x80FFFFFF),
);
