import 'package:flutter_test/flutter_test.dart';

import 'package:bubble_study/main.dart';

void main() {
  testWidgets('shows the study bubble entry point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BubbleStudyApp());
    await tester.pump();

    expect(find.text('开始'), findsOneWidget);
    expect(find.text('轻触进入学习'), findsOneWidget);
  });
}
