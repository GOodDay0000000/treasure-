// 기본 스모크 테스트 — 앱이 크래시 없이 빌드되는지만 확인.
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (tester) async {
    await tester.pumpWidget(const BibleApp(initialDarkMode: false));
    // 초기 프레임만 pump — 에셋 로드까지 기다리지는 않음.
  });
}
