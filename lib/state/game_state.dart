import 'package:flutter/material.dart';

import '../models/car_model.dart';
import '../models/track_model.dart';

/// Everything the player picks before a race: car, paint, finish, rims, track.
/// Kept in one ChangeNotifier so the garage, home and game screens stay in sync.
class GameState extends ChangeNotifier {
  int _carIndex = 0;
  Color _paint = kPaintPalette[0];
  String _finish = kFinishes[0];
  int _rim = 0;
  TrackModel _track = kTracks[0];
  Duration? _bestLap;

  CarModel get selectedCar => kCars[_carIndex];
  int get carIndex => _carIndex;
  Color get paint => _paint;
  String get finish => _finish;
  int get rim => _rim;
  TrackModel get track => _track;
  Duration? get bestLap => _bestLap;

  void selectCar(int index) {
    if (index < 0 || index >= kCars.length || index == _carIndex) return;
    _carIndex = index;
    notifyListeners();
  }

  void setPaint(Color color) {
    _paint = color;
    notifyListeners();
  }

  void setFinish(String finish) {
    _finish = finish;
    notifyListeners();
  }

  void setRim(int rim) {
    _rim = rim;
    notifyListeners();
  }

  void selectTrack(TrackModel track) {
    _track = track;
    notifyListeners();
  }

  void recordLap(Duration lap) {
    if (_bestLap == null || lap < _bestLap!) {
      _bestLap = lap;
      notifyListeners();
    }
  }
}

const List<Color> kPaintPalette = <Color>[
  Color(0xFF22D3EE),
  Color(0xFFFF3D68),
  Color(0xFFF5C542),
  Color(0xFF7C4DFF),
  Color(0xFF39FF88),
  Color(0xFFEDEFF5),
  Color(0xFF15181F),
];

const List<String> kFinishes = <String>['gloss', 'matte', 'metallic'];

const List<String> kRimNames = <String>['Aero', 'Gold', 'Turbine'];
