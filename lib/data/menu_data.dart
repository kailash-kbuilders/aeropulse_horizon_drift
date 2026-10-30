import 'package:flutter/material.dart';

import '../models/food_item.dart';

class MenuData {
  const MenuData._();

  static const List<FoodCategory> categories = <FoodCategory>[
    FoodCategory(label: 'Burger', icon: Icons.lunch_dining),
    FoodCategory(label: 'Pizza', icon: Icons.local_pizza),
    FoodCategory(label: 'Chicken', icon: Icons.set_meal),
    FoodCategory(label: 'Fries', icon: Icons.fastfood),
    FoodCategory(label: 'Drink', icon: Icons.local_drink),
  ];

  static const FoodItem cheeseBurger = FoodItem(
    id: 'cheese-burger',
    name: 'Cheese Burger',
    image: 'assets/images/burger_cheese.jpg',
    price: 5.49,
    rating: 4.7,
    reviews: 96,
    description:
        'Juicy grilled beef patty with melting cheddar, crisp lettuce, tomato '
        'and our signature house sauce.',
  );

  static const FoodItem spicyChickenBurger = FoodItem(
    id: 'spicy-chicken-burger',
    name: 'Spicy Chicken Burger',
    image: 'assets/images/burger_spicy.jpg',
    price: 6.49,
    rating: 4.8,
    reviews: 120,
    tag: 'Spicy',
    description:
        'Crispy spicy chicken patty with fresh lettuce, tomato, onion and our '
        'special sauce.',
  );

  static const FoodItem doubleBeefBurger = FoodItem(
    id: 'double-beef-burger',
    name: 'Double Beef Burger',
    image: 'assets/images/burger_double.jpg',
    price: 7.49,
    rating: 4.9,
    reviews: 143,
    description:
        'Two stacked beef patties, double cheese and smoky barbecue sauce in a '
        'toasted brioche bun.',
  );

  static const List<FoodItem> popular = <FoodItem>[
    cheeseBurger,
    spicyChickenBurger,
    doubleBeefBurger,
  ];

  /// The hero shot used on the detail screen.
  static const String heroImage = 'assets/images/hero_burger.jpg';

  /// The burger + fries shot used inside the offer card.
  static const String comboImage = 'assets/images/combo.jpg';
}
