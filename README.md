# CraveCart

A dark, warm food delivery app built with Flutter. Browse categories, grab the
limited-time combo offer, and customise your burger (size, cheese, patty, bacon)
before adding it to the cart.

## Screens

- **Home** — greeting, search, category strip (Burger / Pizza / Chicken / Fries /
  Drink), limited-time offer card, "Popular Now" carousel, floating bottom nav.
- **Food detail** — hero shot, rating and price, description, size selector,
  three add-on toggles, quantity stepper and a live "Add to Cart" total.
- **Offers / Orders / Favorite** — empty states, ready for real data.

## Run it

```bash
flutter pub get
flutter run
```

## Build the APK

There is no Flutter SDK where this project was authored, so the APK is produced
by GitHub Actions.

- Push to `main` → the workflow builds and uploads `app-release.apk` as a
  run artifact.
- Run the workflow manually (**Actions → Build APK → Run workflow**) or push a
  `v*` tag → the APK is also attached to a GitHub Release, ready to download and
  install.

The `android/` folder is generated inside CI from a throwaway `flutter create`,
so nothing platform-specific needs to be committed. For iOS, macOS, Windows,
Linux or web, run `flutter create . --platforms=ios,macos,windows,linux` locally.

## Layout

```
lib/
  data/menu_data.dart        menu items and categories
  models/                    FoodItem, FoodCategory
  screens/                   home, detail, shell, empty tabs
  widgets/                   cards, nav bar, chips, toggles
  theme/app_theme.dart       colours and text theme
assets/
  images/                    dish photography
  fonts/                     Poppins
  icon/app_icon.png          launcher icon source
```

## Credits

Dish photography from Unsplash. Poppins by Indian Type Foundry (SIL Open Font
License).
