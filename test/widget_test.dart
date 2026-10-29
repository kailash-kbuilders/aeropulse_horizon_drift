import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aeropulse_horizon_drift/models/car_model.dart';
import 'package:aeropulse_horizon_drift/screens/home_screen.dart';
import 'package:aeropulse_horizon_drift/state/game_state.dart';

void main() {
  testWidgets('home screen shows the title, race and garage actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>(
        create: (_) => GameState(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AEROPULSE'), findsOneWidget);
    expect(find.text('RACE'), findsOneWidget);
    expect(find.text('GARAGE'), findsOneWidget);
  });

  test('every car serialises a complete engine payload', () {
    for (final CarModel car in kCars) {
      final Map<String, dynamic> json = car.toEngineJson(
        paint: const Color(0xFF22D3EE),
        finish: 'metallic',
        rim: 2,
      );
      expect(json['id'], car.id);
      expect(json['mass'], car.mass);
      expect(json['engineForce'], car.engineForce);
      expect(json['color'], '#22d3ee');
      expect(json['finish'], 'metallic');
      expect(json['rim'], 2);
    }
  });

  test('game state tracks the selected car and track', () {
    final GameState gs = GameState();
    expect(gs.selectedCar.id, kCars.first.id);
    gs.selectCar(2);
    expect(gs.selectedCar.id, kCars[2].id);
    gs.setRim(1);
    expect(gs.rim, 1);
    expect(gs.track.id, 'neon_city');
  });
}
