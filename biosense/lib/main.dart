import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ble/biosense_packet.dart';
import 'ble/biosense_scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BioSenseApp());
}

class BioSenseApp extends StatelessWidget {
  const BioSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff20b486);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BioSense',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff071612),
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
    if (!mounted) {
      return;
    }

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 32 : 18,
                vertical: 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(packet),
                      const SizedBox(height: 20),
                      _buildMetrics(packet, wide),
                      const SizedBox(height: 18),
                      _buildDeviceDetails(packet),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(BiosensePacket? packet) {
    final status = _statusText(packet != null);
    final statusColor = _statusColor(packet != null);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xff123c31), Color(0xff0b2922)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xff286854)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4420b486),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xff20b486),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.eco_rounded, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BioSense',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 13.5),
                ),
              ],
            ),
          ),
          _ArrivalPulse(
            animation: _arrivalAnimation,
            active: packet != null,
            color: statusColor,
          ),
          IconButton(
            tooltip: 'Reanudar búsqueda',
            onPressed: () => unawaited(_scanner.ensureScanning()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BiosensePacket? packet, bool wide) {
    final cards = [
      _MetricCard(
        title: 'Temperatura',
        value: packet == null
            ? '--'
            : '${packet.temperatureCelsius.toStringAsFixed(2)} °C',
        caption: 'Ambiente',
        icon: Icons.thermostat_rounded,
        color: const Color(0xffff8d68),
        animationKey: _updateCount,
      ),
      _MetricCard(
        title: 'Humedad',
        value: packet == null
            ? '--'
            : '${packet.humidityPercent.toStringAsFixed(2)} %',
        caption: 'Humedad relativa',
        icon: Icons.water_drop_rounded,
        color: const Color(0xff55b8ff),
        animationKey: _updateCount,
      ),
      _MetricCard(
        title: 'Presión',
        value: packet == null
            ? '--'
            : '${packet.pressureKpa.toStringAsFixed(2)} kPa',
        caption: 'Presión relativa',
        icon: Icons.speed_rounded,
        color: const Color(0xffc89cff),
        animationKey: _updateCount,
      ),
      _MetricCard(
        title: 'Batería',
        value: packet == null
            ? '--'
            : '${packet.voltageVolts.toStringAsFixed(3)} V',
        caption: packet?.isBatteryLow == true ? 'Batería baja' : 'Voltaje VDD',
        icon: packet?.isBatteryLow == true
            ? Icons.battery_alert_rounded
            : Icons.battery_5_bar_rounded,
        color: packet?.isBatteryLow == true
            ? const Color(0xffff647c)
            : const Color(0xff60d394),
        animationKey: _updateCount,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: wide ? 0.95 : 0.88,
      children: cards,
    );
  }

  Widget _buildDeviceDetails(BiosensePacket? packet) {
    final update = _latest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xff0d221c),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff1d4237)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _Detail(
            icon: Icons.sensors_rounded,
            label: 'Sensor',
            value: packet?.deviceLabel ?? 'BS-0001',
          ),
          _Detail(
            icon: Icons.wifi_rounded,
            label: 'Señal',
            value: update == null ? '-- dBm' : '${update.rssi} dBm',
          ),
          _Detail(
            icon: Icons.bluetooth_rounded,
            label: 'Dirección BLE',
            value: update?.remoteId ?? '--',
          ),
          _Detail(
            icon: Icons.tag_rounded,
            label: 'Muestra',
            value: packet == null ? '--' : '#${packet.sequence}',
          ),
          _Detail(
            icon: Icons.schedule_rounded,
            label: 'Último dato',
            value: update == null
                ? 'Esperando…'
                : _formatTime(update.receivedAt),
          ),
        ],
      ),
    );
  }

  String _statusText(bool hasPacket) {
    switch (_scannerState) {
      case BiosenseScannerState.starting:
        return 'Preparando Bluetooth…';
      case BiosenseScannerState.bluetoothOff:
        return 'Activa Bluetooth para recibir datos';
      case BiosenseScannerState.scanning:
        return hasPacket
            ? 'Escuchando la próxima muestra de 1 minuto'
            : 'Buscando exclusivamente el sensor BS-0001…';
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
      return const Color(0xffffb45e);
    }
    return hasPacket ? const Color(0xff68e0ad) : const Color(0xff9bbcaf);
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
          width: 13 + pulse * 10,
          height: 13 + pulse * 10,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : const Color(0xff567269),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15 + pulse * 0.55),
                blurRadius: 8 + pulse * 18,
                spreadRadius: pulse * 5,
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
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.animationKey,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final int animationKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xff102820),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey('$title-$animationKey'),
            tween: Tween(begin: 0.76, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 27),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Color(0xff9db9af), fontSize: 13),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 11,
            ),
          ),
        ],
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
        Icon(icon, size: 19, color: const Color(0xff68e0ad)),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xff7f9e93), fontSize: 10),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
