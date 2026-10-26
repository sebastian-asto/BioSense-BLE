import 'package:biosense/ble/biosense_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodifica la trama BioSense v1', () {
    final packet = BiosensePacket.tryParse([
      0x42,
      0x53,
      0x01,
      0x01,
      0x00,
      0x05,
      0xb1,
      0x2a,
      0x00,
      0x3e,
      0x09,
      0xf0,
      0x1a,
      0x2d,
      0x02,
      0xbe,
      0x0a,
      0x00,
    ]);

    expect(packet, isNotNull);
    expect(packet!.deviceId, BiosensePacket.expectedDeviceId);
    expect(packet.sequence, 42);
    expect(packet.temperatureCelsius, 23.66);
    expect(packet.humidityPercent, 68.96);
    expect(packet.pressureKpa, 5.57);
    expect(packet.voltageVolts, 2.75);
    expect(packet.isBatteryLow, isFalse);
  });

  test('ignora dispositivos que no son el BioSense configurado', () {
    final packet = BiosensePacket.tryParse(List<int>.filled(18, 0));
    expect(packet, isNull);
  });
}
