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
    defineReflectiveTests(SdkVersionBoolOperatorTest);
  });
}

@reflectiveTest
class SdkVersionBoolOperatorTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];

  test_and_const_equals() {
    verifyVersion('2.2.2', '''
const c = true & false;
''');
  }

  test_and_const_lessThan() {
    verifyVersion('2.2.0', '''
const c = true & false;
''', errorCodes: [HintCode.SDK_VERSION_BOOL_OPERATOR]);
  }

  test_and_nonConst_equals() {
    verifyVersion('2.2.2', '''
var c = true & false;
''');
  }

  test_and_nonConst_lessThan() {
    verifyVersion('2.2.0', '''
var c = true & false;
''');
  }

  test_or_const_equals() {
    verifyVersion('2.2.2', '''
const c = true | false;
''');
  }

  test_or_const_lessThan() {
    verifyVersion('2.2.0', '''
const c = true | false;
''', errorCodes: [HintCode.SDK_VERSION_BOOL_OPERATOR]);
  }

  test_or_nonConst_equals() {
    verifyVersion('2.2.2', '''
var c = true | false;
''');
  }

  test_or_nonConst_lessThan() {
    verifyVersion('2.2.0', '''
var c = true | false;
''');
  }

  test_xor_const_equals() {
    verifyVersion('2.2.2', '''
const c = true ^ false;
''');
  }

  test_xor_const_lessThan() {
    verifyVersion('2.2.0', '''
const c = true ^ false;
''', errorCodes: [HintCode.SDK_VERSION_BOOL_OPERATOR]);
  }

  test_xor_nonConst_equals() {
    verifyVersion('2.2.2', '''
var c = true ^ false;
''');
  }

  test_xor_nonConst_lessThan() {
    verifyVersion('2.2.0', '''
var c = true ^ false;
''');
  }
}
