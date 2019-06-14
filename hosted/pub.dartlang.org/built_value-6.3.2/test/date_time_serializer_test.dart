// Copyright (c) 2017, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';

void main() {
  final serializers = new Serializers();

  group('DateTime with known specifiedType', () {
    final data = new DateTime.utc(1980, 1, 2, 3, 4, 5, 6, 7);
    final serialized = data.microsecondsSinceEpoch;
    final specifiedType = const FullType(DateTime);

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });

    test('serialize throws if not UTC', () {
      expect(() => serializers.serialize(new DateTime.now()),
          throwsA(const TypeMatcher<ArgumentError>()));
    });
  });

  group('DateTime with unknown specifiedType', () {
    final data = new DateTime.utc(1980, 1, 2, 3, 4, 5, 6, 7);
    final serialized = ['DateTime', data.microsecondsSinceEpoch];
    final specifiedType = FullType.unspecified;

    test('can be serialized', () {
      expect(serializers.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized, specifiedType: specifiedType),
          data);
    });
  });
}
