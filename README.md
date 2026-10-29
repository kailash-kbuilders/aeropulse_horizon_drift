# AeroPulse: Horizon Drift

Real physics. Pure 3D. Built with Flutter.

A 3D arcade-simulation racing game. Flutter owns the shell — garage, HUD,
controls, menus — and a Three.js + Cannon.js scene runs inside a WebView,
so the car physics are a proper raycast-vehicle simulation (suspension springs,
separate longitudinal / lateral tyre friction, drift that behaves) rather than
boxes sliding on a plane.

## Architecture

```
lib/
  main.dart                  app shell, landscape lock, Provider wiring
  models/car_model.dart      the 4 cars + the physics numbers sent to the engine
  models/track_model.dart    Neon City Circuit, Canyon Dust
  state/game_state.dart      selected car / paint / finish / rims / track, best lap
  screens/
    home_screen.dart         title, current build card, RACE + GARAGE
    garage_screen.dart       carousel, paint + finish + rim pickers, stat bars
    track_select_screen.dart two environments
    game_screen.dart         WebView host + HUD overlay + controls + pause/results
  widgets/                   glass panels, stat bars, speedometer gauge, car art
assets/game/
  index.html                 WebView entry point
  three.min.js               Three.js r149 (UMD build, bundled locally)
  cannon.min.js              Cannon.js 0.6.2 (UMD build, global CANNON)
  main.js                    scene, raycast vehicle, race logic, camera
```

Flutter and the engine talk over a single JavaScript channel named `AeroPulse`:

| Direction | Payload |
|---|---|
| Flutter → JS | `window.__AP.setup(carJson, trackId)`, `setInput({throttle,brake,steer,handbrake})`, `start()`, `pause()`, `resume()`, `restart()`, `setLaps(n)` |
| JS → Flutter | `ready`, `loaded`, `countdown`, `hud` (speed, lap, lap time, best lap, gear, drifting), `checkpoint`, `lap`, `finished`, `error` |

Nothing is loaded from a CDN at runtime — all three JS files ship inside the app.

## The cars

| Car | Class | Mass | Engine force | Tyre grip | Suspension |
|---|---|---|---|---|---|
| Vortex GT | Sports | 1200 kg | 2500 | medium (2.7) | 34 |
| Titan X | Muscle | 1600 kg | 3200 | low (1.9) — drifts easily | 30 |
| Apex Spider | Hypercar | 1000 kg | 3800 | high (3.4) | 38 |
| Nomad R-1 | Rally | 1400 kg | 2400 | medium-high (2.9) | 46 |

Every model is generated from primitives at runtime (chassis block, cabin, wing,
skirt, four wheels positioned from the suspension raycasts), so there are no
heavy GLTF files to load or fail.

## Controls

Landscape only. On-screen steering left/right, gas, brake/reverse, and a
handbrake that cuts rear lateral grip for drifting. The HUD can be hidden for a
clean cinematic view.

## Branding

`branding/icon_master.png` (the car mark) and `branding/splash_master.png` (the
full lock-up) are the sources for the Android launcher icon and splash screen.
`tool/apply_branding.py` generates every mipmap density plus a centred splash
drawable — the workflow runs it right after `android/` is created, so the icon
survives every build. `assets/branding/logo.png` is the transparent version the
home screen shows.

## Build

There is no Android/iOS project checked in. The `Build APK` workflow generates
`android/` in a throwaway Flutter project and copies only that folder in, so it
can never overwrite `lib/` or `pubspec.yaml`.

Every push to `main` builds a release APK (Actions → Build APK → artifact
`release-apk`). Run the workflow manually, or push a `v*` tag, to also publish
the APK to a GitHub Release.

### iOS / local development

```bash
flutter pub get
flutter create . --platforms=ios
flutter run
```

## What is not in this build

- No AI opponents, so there is no race position tracker — progress is shown as
  checkpoints cleared per lap instead.
- Steering is on-screen buttons only; the tilt-steering option was not built.
- Canyon Dust gets its elevation from dirt mounds on the track rather than
  sculpted terrain.
- Times are not persisted between launches.
