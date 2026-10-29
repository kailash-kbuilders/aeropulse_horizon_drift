import 'package:flutter/material.dart';

/// A race environment. The [id] is what the WebView engine expects.
class TrackModel {
  const TrackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.accent,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final Color accent;
  final IconData icon;
}

const List<TrackModel> kTracks = <TrackModel>[
  TrackModel(
    id: 'neon_city',
    name: 'Neon City Circuit',
    description: 'Night run between glowing barriers. Fast, flowing corners.',
    accent: Color(0xFF27D9FF),
    icon: Icons.location_city,
  ),
  TrackModel(
    id: 'alpine_pass',
    name: 'Alpine Pass',
    description: 'Mountain road, tree line and guardrails. Fast sweepers, big views.',
    accent: Color(0xFF7FD4A0),
    icon: Icons.forest,
  ),
  TrackModel(
    id: 'canyon_dust',
    name: 'Canyon Dust',
    description: 'Desert loop with dirt mounds. Long slides, low grip.',
    accent: Color(0xFFFF9D3C),
    icon: Icons.landscape,
  ),
];
