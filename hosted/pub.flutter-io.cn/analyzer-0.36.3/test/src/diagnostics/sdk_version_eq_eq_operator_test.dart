// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionEqEqOperatorTest);
  });
}

@reflectiveTest
class SdkVersionEqEqOperatorTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];

  test_left_equals() {
    verifyVersion('2.2.2', '''
class A {
  const A();
}
const A a = A();
const c = a == null;
''');
  }

  test_left_lessThan() {
    verifyVersion('2.2.0', '''
class A {
  const A();
}
const A a = A();
const c = a == null;
''', errorCodes: [HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT]);
  }

  test_right_equals() {
    verifyVersion('2.2.2', '''
class A {
  const A();
}
const A a = A();
const c = null == a;
''');
  }

  test_right_lessThan() {
    verifyVersion('2.2.0', '''
class A {
  const A();
}
const A a = A();
const c = null == a;
''', errorCodes: [HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT]);
  }
}
