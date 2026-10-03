import 'dart:io';

import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('빼기 버튼에 스크린 리더 라벨이 있다', (tester) async {
    final handle = tester.ensureSemantics();
    var removed = -1;
    await pumpApp(
      tester,
      Scaffold(
        body: PhotoStrip(
          photoPaths: const ['a.jpg'],
          photoFile: File.new,
          maxPhotos: 10,
          onAdd: () {},
          onRemove: (index) => removed = index,
        ),
      ),
    );

    expect(find.bySemanticsLabel('사진 삭제'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walk-edit-remove-photo-0')));
    expect(removed, 0);
    handle.dispose();
  });
}
