import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../state/game_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/hold_button.dart';
import '../widgets/speedometer.dart';

/// The race screen.
///
/// Flutter owns this whole overlay: the HUD, the controls, the pause menu and
/// the results sheet. The 3D scene and all physics live in the WebView behind
/// it, and the two talk over the `AeroPulse` JavaScript channel.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const int totalLaps = 3;

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
  String _gear = 'N';
  int _lap = 1;
  int _laps = GameScreen.totalLaps;
  int _checkpoint = 0;
  int _checkpointTotal = 3;
  double _lapTime = 0;
  double _bestLap = 0;
  bool _drifting = false;

  String? _toast;
  Timer? _toastTimer;

  bool _left = false;
  bool _right = false;
  bool _gas = false;
  bool _brake = false;
  bool _handbrake = false;

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
      if (!_paused && !_finished) {
        _setPaused(true);
      }
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
      case 'countdown':
        final int value = (data['value'] as num?)?.toInt() ?? 0;
        setState(() {
          _countdown = value;
          _countdownRunning = value > 0;
        });
        break;
      case 'hud':
        setState(() {
          _speed = (data['speed'] as num?)?.toInt() ?? 0;
          _lap = (data['lap'] as num?)?.toInt() ?? _lap;
          _laps = (data['laps'] as num?)?.toInt() ?? _laps;
          _lapTime = (data['lapTime'] as num?)?.toDouble() ?? 0;
          _bestLap = (data['bestLap'] as num?)?.toDouble() ?? 0;
          _drifting = (data['drifting'] as num?)?.toInt() == 1;
          _gear = (data['gear'] as String?) ?? 'N';
        });
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

  void _sendSetup() {
    final GameState gs = context.read<GameState>();
    final Map<String, dynamic> car = gs.selectedCar.toEngineJson(
      paint: gs.paint,
      finish: gs.finish,
      rim: gs.rim,
    );
    final String carJson = jsonEncode(car);
    final String trackJson = jsonEncode(gs.track.id);

    _controller.runJavaScript(
      'window.__AP.setLaps(${GameScreen.totalLaps});'
      'window.__AP.setup($carJson, $trackJson);',
    );
  }

  void _sendInput() {
    if (!_engineReady) return;
    final int throttle = _gas ? 1 : 0;
    final int brake = _brake ? 1 : 0;
    final int steer = (_right ? 1 : 0) - (_left ? 1 : 0);
    final int handbrake = _handbrake ? 1 : 0;

    _controller.runJavaScript(
      'window.__AP.setInput({throttle:$throttle,brake:$brake,steer:$steer,handbrake:$handbrake});',
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
      _lapTime = 0;
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
              const Text(
                'RACE COMPLETE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(height: 16),
              _ResultRow(label: 'Total time', value: _fmt(totalTime)),
              const SizedBox(height: 8),
              _ResultRow(label: 'Best lap', value: _fmt(bestLap)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _SheetButton(label: 'RESTART', filled: true, onTap: () {
                    Navigator.of(ctx).pop();
                    _restart();
                  }),
                  const SizedBox(width: 10),
                  _SheetButton(label: 'HOME', filled: false, onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
                  }),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_finished) _setPaused(true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05070D),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),

            // top-left: lap / time panel
            if (_hudVisible)
              Positioned(
                top: 12,
                left: 12,
                child: GlassPanel(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'LAP $_lap/$_laps',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'CP $_checkpoint/$_checkpointTotal',
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                              color: Color(0x88FFFFFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmt(_lapTime),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: Colors.white,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'BEST ${_fmt(_bestLap)}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.4,
                          color: Color(0x7AFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // top-right: pause + hud toggle
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: <Widget>[
                  _IconGlass(
                    icon: _hudVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    onTap: () => setState(() => _hudVisible = !_hudVisible),
                  ),
                  const SizedBox(width: 8),
                  _IconGlass(
                    icon: Icons.pause_rounded,
                    onTap: () => _setPaused(true),
                  ),
                ],
              ),
            ),

            // drifting badge
            if (_hudVisible && _drifting && !_paused)
              Positioned(
                top: 96,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x33FF9D3C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF9D3C)),
                    ),
                    child: const Text(
                      'DRIFT',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF9D3C),
                      ),
                    ),
                  ),
                ),
              ),

            // controls
            if (!_paused && !_finished && !_countdownRunning)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_hudVisible,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hudVisible ? 1 : 0,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 22,
                          bottom: 22,
                          child: Row(
                            children: <Widget>[
                              HoldButton(
                                icon: Icons.keyboard_arrow_left_rounded,
                                active: _left,
                                size: 76,
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
                              const SizedBox(width: 12),
                              HoldButton(
                                icon: Icons.keyboard_arrow_right_rounded,
                                active: _right,
                                size: 76,
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
                          right: 22,
                          bottom: 22,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              HoldButton(
                                icon: Icons.local_parking_rounded,
                                label: 'DRIFT',
                                active: _handbrake,
                                size: 62,
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
                              const SizedBox(width: 12),
                              HoldButton(
                                icon: Icons.remove_rounded,
                                label: 'BRAKE',
                                active: _brake,
                                size: 68,
                                accent: const Color(0xFFFF3D68),
                                onDown: () {
                                  _brake = true;
                                  _sendInput();
                                },
                                onUp: () {
                                  _brake = false;
                                  _sendInput();
                                },
                              ),
                              const SizedBox(width: 12),
                              HoldButton(
                                icon: Icons.add_rounded,
                                label: 'GAS',
                                active: _gas,
                                size: 84,
                                accent: const Color(0xFF39FF88),
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
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Speedometer(
                              speed: _speed,
                              gear: _gear,
                              drifting: _drifting,
                              size: 158,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // countdown
            if (_countdownRunning && !_paused)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      _countdown > 0 ? '$_countdown' : 'GO',
                      style: TextStyle(
                        fontSize: 130,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.92),
                        shadows: <Shadow>[
                          Shadow(color: accent.withValues(alpha: 0.9), blurRadius: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // toast
            if (_toast != null)
              Positioned(
                top: 74,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A1119),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _toast!,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),

            // error banner
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

            // pause menu
            if (_paused)
              Positioned.fill(
                child: Container(
                  color: const Color(0xB305070D),
                  child: Center(
                    child: GlassPanel(
                      tint: const Color(0xE60A1119),
                      padding: const EdgeInsets.all(26),
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
                          const SizedBox(height: 20),
                          _SheetButton(
                            label: 'RESUME',
                            filled: true,
                            onTap: () => _setPaused(false),
                          ),
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

class _IconGlass extends StatelessWidget {
  const _IconGlass({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x660A1119),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
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
