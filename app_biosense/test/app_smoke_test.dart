import 'package:biosense/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el panel principal BioSense', (tester) async {
    await tester.pumpWidget(const BioSenseApp());
    await tester.pump();

    expect(find.text('BIOSENSE'), findsOneWidget);
    expect(find.text('TMP / 01'), findsOneWidget);
    expect(find.text('RH / 02'), findsOneWidget);
    expect(find.text('PRES / 03'), findsOneWidget);
    expect(find.text('PWR / 04'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
