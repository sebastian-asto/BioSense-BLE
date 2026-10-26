import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'biosense_packet.dart';

enum BiosenseScannerState {
  starting,
  bluetoothOff,
  scanning,
  unsupported,
  error,
}

class BiosenseScanUpdate {
  const BiosenseScanUpdate({
    required this.packet,
    required this.rssi,
    required this.remoteId,
    required this.receivedAt,
  });

  final BiosensePacket packet;
  final int rssi;
  final String remoteId;
  final DateTime receivedAt;
}

class BiosenseScanner {
  final _updates = StreamController<BiosenseScanUpdate>.broadcast();
  final _states = StreamController<BiosenseScannerState>.broadcast();

  Stream<BiosenseScanUpdate> get updates => _updates.stream;
  Stream<BiosenseScannerState> get states => _states.stream;

  StreamSubscription<List<ScanResult>>? _resultsSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  int? _lastSequence;
  DateTime? _lastAcceptedAt;
  bool _startingScan = false;
  bool _disposed = false;

  Future<void> start() async {
    _emitState(BiosenseScannerState.starting);

    try {
      if (!await FlutterBluePlus.isSupported) {
        _emitState(BiosenseScannerState.unsupported);
        return;
      }

      _resultsSubscription ??= FlutterBluePlus.onScanResults.listen(
        _handleResults,
        onError: (_) => _emitState(BiosenseScannerState.error),
      );
      _adapterSubscription ??= FlutterBluePlus.adapterState.listen(
        _handleAdapterState,
      );
      await _handleAdapterState(FlutterBluePlus.adapterStateNow);
    } catch (_) {
      _emitState(BiosenseScannerState.error);
    }
  }

  Future<void> ensureScanning() async {
    await _handleAdapterState(FlutterBluePlus.adapterStateNow);
  }

  Future<void> _handleAdapterState(BluetoothAdapterState state) async {
    if (_disposed) {
      return;
    }

    if (state == BluetoothAdapterState.on) {
      await _startScan();
    } else if (state == BluetoothAdapterState.off) {
      _emitState(BiosenseScannerState.bluetoothOff);
    } else {
      _emitState(BiosenseScannerState.starting);
    }
  }

  Future<void> _startScan() async {
    if (_disposed || _startingScan || FlutterBluePlus.isScanningNow) {
      if (FlutterBluePlus.isScanningNow) {
        _emitState(BiosenseScannerState.scanning);
      }
      return;
    }

    _startingScan = true;
    try {
      await FlutterBluePlus.startScan(
        continuousUpdates: true,
        oneByOne: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );
      _emitState(BiosenseScannerState.scanning);
    } catch (_) {
      _emitState(BiosenseScannerState.error);
    } finally {
      _startingScan = false;
    }
  }

  void _handleResults(List<ScanResult> results) {
    for (final result in results) {
      final bytes =
          result.advertisementData.manufacturerData[BiosensePacket.companyId];
      if (bytes == null) {
        continue;
      }

      final packet = BiosensePacket.tryParse(bytes);
      if (packet == null) {
        continue;
      }

      final now = DateTime.now();
      final isSameBurst =
          _lastSequence == packet.sequence &&
          _lastAcceptedAt != null &&
          now.difference(_lastAcceptedAt!) < const Duration(seconds: 10);
      if (isSameBurst) {
        continue;
      }

      _lastSequence = packet.sequence;
      _lastAcceptedAt = now;
      _updates.add(
        BiosenseScanUpdate(
          packet: packet,
          rssi: result.rssi,
          remoteId: result.device.remoteId.toString(),
          receivedAt: now,
        ),
      );
    }
  }

  void _emitState(BiosenseScannerState state) {
    if (!_disposed) {
      _states.add(state);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _resultsSubscription?.cancel();
    await _adapterSubscription?.cancel();
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await _updates.close();
    await _states.close();
  }
}
