// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dart_hetimanet.test;

import 'package:unittest/unittest.dart';
import 'package:hetimanet/hetimanet.dart';

main() {
  group('A group of tests', () {
    setUp(() {
    });

    test('First Test', () {
      TestNet n = new TestNet();
      print("${n.hello}");
    });
  });
}
