import 'package:flutter/material.dart';

/// Which handling family a car belongs to. Drives the silhouette drawing and
/// the garage copy — the physics numbers below are what the engine actually uses.
enum CarClass { sports, muscle, hyper, rally }

/// One car in the garage.
///
/// The numeric fields are the real engine inputs: they are serialised into JSON
/// and handed to Cannon.js, which builds the raycast vehicle from them.
class CarModel {
  const CarModel({
    required this.id,
    required this.name,
    required this.carClass,
    required this.tagline,
    required this.mass,
    required this.engineForce,
    required this.frictionSlip,
    required this.suspensionStiffness,
    required this.topSpeed,
    required this.speedStat,
    required this.accelStat,
    required this.handlingStat,
    required this.brakingStat,
  });

  final String id;
  final String name;
  final CarClass carClass;
  final String tagline;

  /// Kilograms.
  final double mass;

  /// Engine force figure from the spec sheet (the engine scales it for arcade feel).
  final double engineForce;

  /// Lateral grip of the tyres. Low value = loose rear = easy drifting.
  final double frictionSlip;

  /// Spring rate of the raycast suspension.
  final double suspensionStiffness;

  /// Soft limiter, in metres per second.
  final double topSpeed;

  /// 0..1 values used only for the garage stat bars.
  final double speedStat;
  final double accelStat;
  final double handlingStat;
  final double brakingStat;

  String get classLabel {
    switch (carClass) {
      case CarClass.sports:
        return 'SPORTS';
      case CarClass.muscle:
        return 'MUSCLE';
      case CarClass.hyper:
        return 'HYPERCAR';
      case CarClass.rally:
        return 'RALLY';
    }
  }

  /// JSON handed to the WebView engine.
  Map<String, dynamic> toEngineJson({
    required Color paint,
    required String finish,
    required int rim,
  }) {
    final hex = '#${(paint.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return <String, dynamic>{
      'id': id,
      'mass': mass,
      'engineForce': engineForce,
      'frictionSlip': frictionSlip,
      'suspensionStiffness': suspensionStiffness,
      'topSpeed': topSpeed,
      'color': hex,
      'finish': finish,
      'rim': rim,
    };
  }
}

/// The four cars in the garage, tuned per the spec sheet.
const List<CarModel> kCars = <CarModel>[
  CarModel(
    id: 'vortex_gt',
    name: 'Vortex GT',
    carClass: CarClass.sports,
    tagline: 'High top speed, balanced handling.',
    mass: 1200,
    engineForce: 2500,
    frictionSlip: 2.7,
    suspensionStiffness: 34,
    topSpeed: 52,
    speedStat: 0.78,
    accelStat: 0.72,
    handlingStat: 0.80,
    brakingStat: 0.74,
  ),
  CarModel(
    id: 'titan_x',
    name: 'Titan X',
    carClass: CarClass.muscle,
    tagline: 'Huge acceleration, loose rear grip. Born to drift.',
    mass: 1600,
    engineForce: 3200,
    frictionSlip: 1.9,
    suspensionStiffness: 30,
    topSpeed: 50,
    speedStat: 0.70,
    accelStat: 0.86,
    handlingStat: 0.55,
    brakingStat: 0.60,
  ),
  CarModel(
    id: 'apex_spider',
    name: 'Apex Spider',
    carClass: CarClass.hyper,
    tagline: 'Maximum grip, razor-sharp turn-in.',
    mass: 1000,
    engineForce: 3800,
    frictionSlip: 3.4,
    suspensionStiffness: 38,
    topSpeed: 62,
    speedStat: 0.95,
    accelStat: 0.90,
    handlingStat: 0.92,
    brakingStat: 0.88,
  ),
  CarModel(
    id: 'nomad_r1',
    name: 'Nomad R-1',
    carClass: CarClass.rally,
    tagline: 'Long suspension travel, stable over dirt.',
    mass: 1400,
    engineForce: 2400,
    frictionSlip: 2.9,
    suspensionStiffness: 46,
    topSpeed: 46,
    speedStat: 0.62,
    accelStat: 0.68,
    handlingStat: 0.70,
    brakingStat: 0.72,
  ),
];
