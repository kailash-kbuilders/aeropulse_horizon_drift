import 'package:flutter/material.dart';

/// A single dish shown in the menu.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.description,
    this.tag,
  });

  final String id;
  final String name;
  final String image;
  final double price;
  final double rating;
  final int reviews;
  final String description;

  /// Small badge such as "Spicy". Null means no badge.
  final String? tag;
}

/// One tile in the category strip on the home screen.
class FoodCategory {
  const FoodCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
