import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../state/game_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/hold_button.dart';
import '../widgets/minimap.dart';
import '../widgets/pedal_button.dart';
import '../widgets/speed_cluster.dart';
import '../widgets/steering_wheel.dart';

/// The race screen.
///
/// Flutter owns this whole overlay — HUD, minimap, controls, pause menu and
/// results. The 3D scene and all physics live in the WebView behind it, and the
/// two talk over the `AeroPulse` JavaScript channel.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const int totalLaps = 3;
  static const int rivals = 5;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;

  bool _engineReady = false;
  bool _countdownRunning = true;
  int _countdown = 3;

  bool _paused = false;
  bool _finished = false;
  bool _hudVisible = true;
  String? _error;

  int _speed = 0;
  int _gear = 0;
  int _rpm = 900;
  int _lap = 1;
  int _laps = GameScreen.totalLaps;
  int _position = 1;
  int _total = GameScreen.rivals + 1;
  int _checkpoint = 0;
  int _checkpointTotal = 3;
  double _lapTime = 0;
  double _bestLap = 0;
  bool _drifting = false;

  List<Offset> _trackPath = const <Offset>[];
  Offset _carPos = Offset.zero;
  Offset? _lastCarPos;
  double _heading = 0;

  String? _toast;
  Timer? _toastTimer;

  bool _left = false;
  bool _right = false;
  bool _gas = false;
  bool _brake = false;
  bool _handbrake = false;
  double _wheelSteer = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF05070D))
      ..addJavaScriptChannel('AeroPulse', onMessageReceived: _onEngineMessage)
      ..loadFlutterAsset('assets/game/index.html');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_paused && !_finished) _setPaused(true);
    }
  }

  /* ---------------------------------------------------------------- *
   * Engine bridge
   * ---------------------------------------------------------------- */
  void _onEngineMessage(JavaScriptMessage message) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (data['type']) {
      case 'ready':
        _sendSetup();
        break;
      case 'loaded':
        _engineReady = true;
        _controller.runJavaScript('window.__AP.start();');
        break;
      case 'track':
        _handleTrack(data);
        break;
      case 'countdown':
        final int value = (data['value'] as num?)?.toInt() ?? 0;
        setState(() {
          _countdown = value;
          _countdownRunning = value > 0;
        });
        break;
      case 'hud':
        _handleHud(data);
        break;
      case 'checkpoint':
        final int cp = (data['cp'] as num?)?.toInt() ?? 0;
        final int total = (data['total'] as num?)?.toInt() ?? 3;
        setState(() {
          _checkpoint = cp;
          _checkpointTotal = total;
        });
        _showToast('CHECKPOINT $cp / $total');
        break;
      case 'lap':
        final int lap = (data['lap'] as num?)?.toInt() ?? 1;
        final double lapTime = (data['lapTime'] as num?)?.toDouble() ?? 0;
        if (lapTime > 0) {
          context.read<GameState>().recordLap(
                Duration(milliseconds: (lapTime * 1000).round()),
              );
        }
        _showToast('LAP $lap');
        break;
      case 'finished':
        setState(() => _finished = true);
        _showResults(data);
        break;
      case 'error':
        setState(() => _error = data['message'] as String? ?? 'Engine error');
        break;
    }
  }

  void _handleTrack(Map<String, dynamic> data) {
    final List<dynamic> flat = (data['path'] as List<dynamic>?) ?? <dynamic>[];
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i + 1 < flat.length; i += 2) {
      pts.add(Offset(
        (flat[i] as num).toDouble(),
        (flat[i + 1] as num).toDouble(),
      ));
    }
    setState(() => _trackPath = pts);
  }

  void _handleHud(Map<String, dynamic> data) {
    final Offset next = Offset(
      (data['x'] as num?)?.toDouble() ?? _carPos.dx,
      (data['z'] as num?)?.toDouble() ?? _carPos.dy,
    );

    double heading = _heading;
    final Offset? last = _lastCarPos;
    if (last != null) {
      final Offset d = next - last;
      if (d.distance > 0.25) {
        heading = math.atan2(d.dx, -d.dy);
      }
    }

    setState(() {
      _speed = (data['speed'] as num?)?.toInt() ?? 0;
      _gear = (data['gear'] as num?)?.toInt() ?? 0;
      _rpm = (data['rpm'] as num?)?.toInt() ?? 900;
      _lap = (data['lap'] as num?)?.toInt() ?? _lap;
      _laps = (data['laps'] as num?)?.toInt() ?? _laps;
      _position = (data['pos'] as num?)?.toInt() ?? _position;
      _total = (data['total'] as num?)?.toInt() ?? _total;
      _lapTime = (data['lapTime'] as num?)?.toDouble() ?? 0;
      _bestLap = (data['bestLap'] as num?)?.toDouble() ?? 0;
      _drifting = (data['drifting'] as num?)?.toInt() == 1;
      _carPos = next;
      _lastCarPos = next;
      _heading = heading;
    });
  }

  void _sendSetup() {
    final GameState gs = context.read<GameState>();
    final String carJson = jsonEncode(gs.selectedCar.toEngineJson(
      paint: gs.paint,
      finish: gs.finish,
      rim: gs.rim,
    ));
    final String trackJson = jsonEncode(gs.track.id);

    _controller.runJavaScript(
      'window.__AP.setLaps(${GameScreen.totalLaps});'
      'window.__AP.setup($carJson, $trackJson, {opponents: ${GameScreen.rivals}});',
    );
  }

  void _sendInput() {
    if (!_engineReady) return;
    final int throttle = _gas ? 1 : 0;
    final int brake = _brake ? 1 : 0;
    final double steer = _wheelSteer != 0
        ? _wheelSteer
        : ((_right ? 1 : 0) - (_left ? 1 : 0)).toDouble();
    final int handbrake = _handbrake ? 1 : 0;

    _controller.runJavaScript(
      'window.__AP.setInput({throttle:$throttle,brake:$brake,'
      'steer:${steer.toStringAsFixed(3)},handbrake:$handbrake});',
    );
  }

  void _setPaused(bool paused) {
    setState(() {
      _paused = paused;
      _gas = false;
      _brake = false;
      _left = false;
      _right = false;
      _handbrake = false;
      _wheelSteer = 0;
    });
    _sendInput();
    _controller.runJavaScript(
      paused ? 'window.__AP.pause();' : 'window.__AP.resume();',
    );
  }

  void _restart() {
    setState(() {
      _finished = false;
      _paused = false;
      _lap = 1;
      _checkpoint = 0;
      _speed = 0;
      _rpm = 900;
      _lapTime = 0;
      _position = 1;
      _countdownRunning = true;
      _countdown = 3;
    });
    _controller.runJavaScript('window.__AP.restart();');
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _showResults(Map<String, dynamic> data) {
    final double totalTime = (data['totalTime'] as num?)?.toDouble() ?? 0;
    final double bestLap = (data['bestLap'] as num?)?.toDouble() ?? 0;
    final int pos = (data['pos'] as num?)?.toInt() ?? _position;
    final int total = (data['total'] as num?)?.toInt() ?? _total;

    if (bestLap > 0) {
      context.read<GameState>().recordLap(
            Duration(milliseconds: (bestLap * 1000).round()),
          );
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          tint: const Color(0xE60A1119),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                pos == 1 ? 'P1 — RACE WON' : 'FINISHED  P$pos / $total',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(height: 16),
              _ResultRow(label: 'Position', value: '$pos / $total'),
              const SizedBox(height: 8),
              _ResultRow(label: 'Total time', value: _fmt(totalTime)),
              const SizedBox(height: 8),
              _ResultRow(label: 'Best lap', value: _fmt(bestLap)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _SheetButton(
                    label: 'RESTART',
                    filled: true,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _restart();
                    },
                  ),
                  const SizedBox(width: 10),
                  _SheetButton(
                    label: 'HOME',
                    filled: false,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double seconds) {
    if (seconds <= 0) return '--:--.--';
    final int m = seconds ~/ 60;
    final double s = seconds - m * 60;
    return '${m.toString().padLeft(2, '0')}:${s.toStringAsFixed(2).padLeft(5, '0')}';
  }

  /* ---------------------------------------------------------------- *
   * UI
   * ---------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final GameState gs = context.watch<GameState>();
    final Color accent = gs.track.accent;
    final bool showControls = !_paused && !_finished && !_countdownRunning && _hudVisible;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_finished) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05070D),
        body: Stack(
          children: <Widget>[
            Positioned.fill(child: WebViewWidget(controller: _controller)),

            /* ---------- top left: position / lap / time ---------- */
            if (_hudVisible)
              Positioned(
                top: 10,
                left: 10,
                child: GlassPanel(
                  padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
                  radius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _HudLine(label: 'POS', value: '$_position / $_total', accent: accent),
                      _HudLine(label: 'LAP', value: '$_lap / $_laps', accent: accent),
                      _HudLine(label: 'TIME', value: _fmt(_lapTime), accent: accent),
                      _HudLine(label: 'BEST', value: _fmt(_bestLap), accent: accent),
                    ],
                  ),
                ),
              ),

            /* ---------- top centre: minimap ---------- */
            if (_hudVisible)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: GlassPanel(
                    padding: const EdgeInsets.all(6),
                    radius: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Minimap(
                          path: _trackPath,
                          car: _carPos,
                          heading: _heading,
                          accent: accent,
                          size: const Size(178, 96),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CHECKPOINT $_checkpoint / $_checkpointTotal',
                          style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            color: accent.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            /* ---------- top right: hud toggle + pause ---------- */
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: <Widget>[
                  _IconGlass(
                    icon: _hudVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    onTap: () => setState(() => _hudVisible = !_hudVisible),
                  ),
                  const SizedBox(width: 8),
                  _IconGlass(icon: Icons.pause_rounded, onTap: () => _setPaused(true)),
                ],
              ),
            ),

            /* ---------- drift badge ---------- */
            if (_hudVisible && _drifting && !_paused)
              Positioned(
                top: 122,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x33FF9D3C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF9D3C)),
                    ),
                    child: const Text(
                      'DRIFT',
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF9D3C),
                      ),
                    ),
                  ),
                ),
              ),

            /* ---------- controls ---------- */
            if (showControls)
              Positioned.fill(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          HoldButton(
                            icon: Icons.keyboard_arrow_left_rounded,
                            active: _left,
                            size: 54,
                            accent: accent,
                            onDown: () {
                              _left = true;
                              _sendInput();
                            },
                            onUp: () {
                              _left = false;
                              _sendInput();
                            },
                          ),
                          const SizedBox(width: 8),
                          SteeringWheel(
                            size: 104,
                            accent: accent,
                            onChanged: (double v) {
                              _wheelSteer = v;
                              _sendInput();
                            },
                          ),
                          const SizedBox(width: 8),
                          HoldButton(
                            icon: Icons.keyboard_arrow_right_rounded,
                            active: _right,
                            size: 54,
                            accent: accent,
                            onDown: () {
                              _right = true;
                              _sendInput();
                            },
                            onUp: () {
                              _right = false;
                              _sendInput();
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          HoldButton(
                            icon: Icons.local_parking_rounded,
                            label: 'DRIFT',
                            active: _handbrake,
                            size: 54,
                            accent: const Color(0xFFFF9D3C),
                            onDown: () {
                              _handbrake = true;
                              _sendInput();
                            },
                            onUp: () {
                              _handbrake = false;
                              _sendInput();
                            },
                          ),
                          const SizedBox(width: 10),
                          PedalButton(
                            label: 'BRAKE',
                            width: 66,
                            height: 104,
                            accent: const Color(0xFFFF3D68),
                            active: _brake,
                            onDown: () {
                              _brake = true;
                              _sendInput();
                            },
                            onUp: () {
                              _brake = false;
                              _sendInput();
                            },
                          ),
                          const SizedBox(width: 10),
                          PedalButton(
                            label: 'GAS',
                            width: 74,
                            height: 116,
                            accent: const Color(0xFF39FF88),
                            active: _gas,
                            onDown: () {
                              _gas = true;
                              _sendInput();
                            },
                            onUp: () {
                              _gas = false;
                              _sendInput();
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SpeedCluster(
                          speed: _speed,
                          gear: _gear,
                          rpm: _rpm,
                          drifting: _drifting,
                          width: 186,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /* ---------- countdown ---------- */
            if (_countdownRunning && !_paused)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      _countdown > 0 ? '$_countdown' : 'GO',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.94),
                        shadows: <Shadow>[
                          Shadow(color: accent.withValues(alpha: 0.9), blurRadius: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            /* ---------- toast ---------- */
            if (_toast != null)
              Positioned(
                top: 128,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A1119),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _toast!,
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),

            /* ---------- error ---------- */
            if (_error != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC2A0A12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF3D68)),
                  ),
                  child: Text(
                    'Engine: $_error',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),

            /* ---------- pause menu ---------- */
            if (_paused)
              Positioned.fill(
                child: Container(
                  color: const Color(0xB305070D),
                  child: Center(
                    child: GlassPanel(
                      tint: const Color(0xE60A1119),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SheetButton(label: 'RESUME', filled: true, onTap: () => _setPaused(false)),
                          const SizedBox(height: 10),
                          _SheetButton(label: 'RESTART', filled: false, onTap: _restart),
                          const SizedBox(height: 10),
                          _SheetButton(
                            label: 'QUIT',
                            filled: false,
                            onTap: () {
                              Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HudLine extends StatelessWidget {
  const _HudLine({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.9),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconGlass extends StatelessWidget {
  const _IconGlass({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x660A1119),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF22D3EE);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: filled ? accent : Colors.transparent,
          border: Border.all(color: filled ? accent : const Color(0x44FFFFFF)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w800,
            color: filled ? const Color(0xFF04121A) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: Color(0x88FFFFFF),
          ),
        ),
        const SizedBox(width: 28),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
