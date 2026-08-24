import 'dart:typed_data';

class BiosensePacket {
  const BiosensePacket({
    required this.deviceId,
    required this.sequence,
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.pressureKpa,
    required this.voltageVolts,
    required this.flags,
  });

  static const int companyId = 0xffff;
  static const int expectedDeviceId = 0xb1050001;
  static const int frameVersion = 1;
  static const int payloadLength = 18;

  final int deviceId;
  final int sequence;
  final double temperatureCelsius;
  final double humidityPercent;
  final double pressureKpa;
  final double voltageVolts;
  final int flags;

  bool get isBatteryLow => (flags & 0x01) != 0;

  String get deviceLabel =>
      'BS-${(deviceId & 0xffff).toRadixString(16).padLeft(4, '0').toUpperCase()}';

  static BiosensePacket? tryParse(List<int> bytes) {
    if (bytes.length < payloadLength ||
        bytes[0] != 0x42 ||
        bytes[1] != 0x53 ||
        bytes[2] != frameVersion) {
      return null;
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final deviceId = data.getUint32(3, Endian.little);
    if (deviceId != expectedDeviceId) {
      return null;
    }

    return BiosensePacket(
      deviceId: deviceId,
      sequence: data.getUint16(7, Endian.little),
      temperatureCelsius: data.getInt16(9, Endian.little) / 100.0,
      humidityPercent: data.getUint16(11, Endian.little) / 100.0,
      pressureKpa: data.getInt16(13, Endian.little) / 100.0,
      voltageVolts: data.getUint16(15, Endian.little) / 1000.0,
      flags: data.getUint8(17),
    );
  }
}
