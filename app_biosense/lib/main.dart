import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ble/biosense_packet.dart';
import 'ble/biosense_scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _Palette.background,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _Palette.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BioSenseApp());
}

abstract final class _Palette {
  static const background = Color(0xff080906);
  static const ink = Color(0xff11120f);
  static const cream = Color(0xfffff3dc);
  static const sand = Color(0xffe4a45f);
  static const brick = Color(0xffb75a4f);
  static const green = Color(0xff789572);
  static const gray = Color(0xffaaa9a5);
  static const yellow = Color(0xffffd338);
}

class BioSenseApp extends StatelessWidget {
  const BioSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BioSense',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _Palette.background,
        colorScheme: const ColorScheme.dark(
          primary: _Palette.sand,
          secondary: _Palette.green,
          surface: _Palette.ink,
          error: _Palette.brick,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: _Palette.cream,
          displayColor: _Palette.cream,
        ),
      ),
      home: const BioSenseDashboard(),
    );
  }
}

class BioSenseDashboard extends StatefulWidget {
  const BioSenseDashboard({super.key});

  @override
  State<BioSenseDashboard> createState() => _BioSenseDashboardState();
}

class _BioSenseDashboardState extends State<BioSenseDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BiosenseScanner _scanner;
  late final AnimationController _arrivalAnimation;
  StreamSubscription<BiosenseScanUpdate>? _updatesSubscription;
  StreamSubscription<BiosenseScannerState>? _statesSubscription;

  BiosenseScannerState _scannerState = BiosenseScannerState.starting;
  BiosenseScanUpdate? _latest;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arrivalAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _scanner = BiosenseScanner();
    _updatesSubscription = _scanner.updates.listen(_handleUpdate);
    _statesSubscription = _scanner.states.listen((state) {
      if (mounted) {
        setState(() => _scannerState = state);
      }
    });
    unawaited(_scanner.start());
  }

  void _handleUpdate(BiosenseScanUpdate update) {
    if (!mounted) return;

    setState(() {
      _latest = update;
      _updateCount++;
    });
    _arrivalAnimation.forward(from: 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_scanner.ensureScanning());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_updatesSubscription?.cancel());
    unawaited(_statesSubscription?.cancel());
    unawaited(_scanner.dispose());
    _arrivalAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packet = _latest?.packet;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 16,
                    18,
                    wide ? 32 : 16,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(packet, wide),
                          const SizedBox(height: 14),
                          _buildMetrics(packet, wide),
                          const SizedBox(height: 14),
                          _buildDeviceDetails(packet),
                          const SizedBox(height: 14),
                          const Text(
                            'BIOSENSE // BLE ENVIRONMENTAL TELEMETRY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff76766f),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BiosensePacket? packet, bool wide) {
    final hasPacket = packet != null;
    final status = _statusText(hasPacket);
    final statusColor = _statusColor(hasPacket);

    return Container(
      padding: EdgeInsets.all(wide ? 22 : 16),
      decoration: BoxDecoration(
        color: _Palette.sand,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _Palette.ink, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 0,
            offset: Offset(5, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: wide ? 76 : 62,
            height: wide ? 76 : 62,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _Palette.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/branding/biosense_icon.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          SizedBox(width: wide ? 18 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIOSENSE',
                  maxLines: 1,
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: wide ? 31 : 24,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _ArrivalPulse(
                      animation: _arrivalAnimation,
                      active: hasPacket,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 10.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _Palette.ink,
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              tooltip: 'Reanudar búsqueda',
              onPressed: () => unawaited(_scanner.ensureScanning()),
              color: _Palette.cream,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BiosensePacket? packet, bool wide) {
    final cards = [
      _MetricCard(
        code: 'TMP / 01',
        title: 'Temperatura',
        value: packet == null
            ? '--'
            : '${packet.temperatureCelsius.toStringAsFixed(2)} °C',
        caption: 'AMBIENTE',
        icon: Icons.thermostat_rounded,
        panelColor: _Palette.brick,
        animationKey: _updateCount,
      ),
      _MetricCard(
        code: 'RH / 02',
        title: 'Humedad',
        value: packet == null
            ? '--'
            : '${packet.humidityPercent.toStringAsFixed(2)} %',
        caption: 'HUMEDAD RELATIVA',
        icon: Icons.water_drop_rounded,
        panelColor: _Palette.sand,
        animationKey: _updateCount,
      ),
      _MetricCard(
        code: 'PRES / 03',
        title: 'Presión',
        value: packet == null
            ? '--'
            : '${packet.pressureKpa.toStringAsFixed(2)} kPa',
        caption: 'PRESIÓN RELATIVA',
        icon: Icons.speed_rounded,
        panelColor: _Palette.green,
        animationKey: _updateCount,
      ),
      _MetricCard(
        code: 'PWR / 04',
        title: 'Batería',
        value: packet == null
            ? '--'
            : '${packet.voltageVolts.toStringAsFixed(3)} V',
        caption: packet?.isBatteryLow == true ? 'BATERÍA BAJA' : 'VOLTAJE VDD',
        icon: packet?.isBatteryLow == true
            ? Icons.battery_alert_rounded
            : Icons.battery_5_bar_rounded,
        panelColor: packet?.isBatteryLow == true
            ? const Color(0xffd74e45)
            : _Palette.gray,
        animationKey: _updateCount,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: wide ? 0.96 : 0.83,
      children: cards,
    );
  }

  Widget _buildDeviceDetails(BiosensePacket? packet) {
    final update = _latest;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: _Palette.ink,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.sand, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'DEVICE LINK',
                  style: TextStyle(
                    color: _Palette.sand,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Icon(Icons.north_east_rounded, color: _Palette.sand, size: 24),
            ],
          ),
          const SizedBox(height: 5),
          const Divider(color: Color(0xff4b402f), height: 13),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _Detail(
                icon: Icons.sensors_rounded,
                label: 'SENSOR',
                value: packet?.deviceLabel ?? 'BS-0001',
              ),
              _Detail(
                icon: Icons.wifi_rounded,
                label: 'SEÑAL',
                value: update == null ? '-- dBm' : '${update.rssi} dBm',
              ),
              _Detail(
                icon: Icons.bluetooth_rounded,
                label: 'DIRECCIÓN BLE',
                value: update?.remoteId ?? '--',
              ),
              _Detail(
                icon: Icons.tag_rounded,
                label: 'MUESTRA',
                value: packet == null ? '--' : '#${packet.sequence}',
              ),
              _Detail(
                icon: Icons.schedule_rounded,
                label: 'ÚLTIMO DATO',
                value: update == null
                    ? 'Esperando…'
                    : _formatTime(update.receivedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(bool hasPacket) {
    switch (_scannerState) {
      case BiosenseScannerState.starting:
        return 'Preparando Bluetooth';
      case BiosenseScannerState.bluetoothOff:
        return 'Activa Bluetooth para recibir datos';
      case BiosenseScannerState.scanning:
        return hasPacket
            ? 'Enlace activo · próxima muestra en 1 minuto'
            : 'Buscando exclusivamente el sensor BS-0001';
      case BiosenseScannerState.unsupported:
        return 'Este dispositivo no admite Bluetooth LE';
      case BiosenseScannerState.error:
        return 'No se pudo iniciar el escaneo BLE';
    }
  }

  Color _statusColor(bool hasPacket) {
    if (_scannerState == BiosenseScannerState.error ||
        _scannerState == BiosenseScannerState.bluetoothOff ||
        _scannerState == BiosenseScannerState.unsupported) {
      return _Palette.brick;
    }
    return hasPacket ? _Palette.green : _Palette.yellow;
  }

  static String _formatTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

class _ArrivalPulse extends StatelessWidget {
  const _ArrivalPulse({
    required this.animation,
    required this.active,
    required this.color,
  });

  final Animation<double> animation;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = math.sin(animation.value * math.pi).clamp(0.0, 1.0);
        return Container(
          width: 11 + pulse * 7,
          height: 11 + pulse * 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : const Color(0xff76766f),
            border: Border.all(color: _Palette.ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18 + pulse * 0.55),
                blurRadius: 5 + pulse * 12,
                spreadRadius: pulse * 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.code,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.panelColor,
    required this.animationKey,
  });

  final String code;
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color panelColor;
  final int animationKey;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$code-$animationKey'),
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _Palette.ink, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Icon(icon, color: _Palette.ink, size: 27),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 2, color: _Palette.ink),
            const SizedBox(height: 10),
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Palette.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: _Palette.ink,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.55,
                    ),
                  ),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  color: _Palette.ink,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xff26261f),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _Palette.sand),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff85847d),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.75,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: _Palette.cream,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xff1c1d18)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = const Color(0xff282921)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    for (double x = 0; x <= size.width; x += spacing * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
    }
    for (double y = 0; y <= size.height; y += spacing * 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
