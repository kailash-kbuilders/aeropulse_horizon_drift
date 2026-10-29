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

## The tracks

| Track | Look | Surface |
|---|---|---|
| Neon City Circuit | night city, glowing barriers, lit windows | asphalt |
| Canyon Dust | desert, rock field, dirt mounds | sand |
| Alpine Pass | mountain road, tree line, guardrails, distant peaks | asphalt |

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

## Race

Five AI rivals follow the racing line at different speeds and lanes, so the HUD
can show a live **position** (P3/6) next to the lap counter. Progress is
measured along the track centreline, which is also what drives the minimap.

## Controls

Landscape only. A draggable steering wheel (it springs back to centre) with
left/right buttons beside it, pedal-shaped gas and brake, and a handbrake that
cuts rear lateral grip for drifting. The HUD — position, lap, lap time, best
lap, minimap, digital speed, gear and an RPM bar — can be hidden for a clean
cinematic view.

Rendering notes: a real equirectangular sky and reflection probe per track
(tone-mapped from CC0 HDRIs, embedded as data URIs so the WebView never makes an
XHR), ACES tone mapping, image-based lighting on the PBR paint, canvas-generated
asphalt / grass / sand and window textures, a car body extruded from a coupe
side profile, guardrails with posts, instanced trees and rocks, and a shadow
frustum that follows the car.

## Branding

`branding/icon_art.png` (the car, transparent), `branding/icon_master.png` and
`branding/splash_master.png` (white backgrounds) feed `tool/apply_branding.py`,
which the workflow runs right after `android/` is created:

- an **adaptive icon** (`mipmap-anydpi-v26/ic_launcher.xml` — white background
  layer plus the car as the foreground layer), so the launcher applies its usual
  rounded / circular mask instead of showing a hard square,
- a rounded legacy `ic_launcher.png` for Android 7 and older,
- a white splash screen,
- and `assets/branding/logo.png`, the rounded white tile the home screen shows.

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

- The rivals are kinematic: they follow the racing line, they do not collide
  with the player and they are not simulated with Cannon.js.
- The road is flat. Elevation is suggested with dirt mounds (Canyon) and
  hillside scenery (Alpine), not real terrain height.
- Visuals are stylised low-poly with procedural textures — not photoreal. A
  reference render with ray-traced cars and foliage needs GLTF assets and a
  real renderer, which is a different pipeline from this WebView scene.
- Tilt steering was not built.
- Times are not persisted between launches.
