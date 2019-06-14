// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantListElementTest);
    defineReflectiveTests(NonConstantListElementWithConstantsTest);
  });
}

@reflectiveTest
class NonConstantListElementTest extends DriverResolutionTest {
  test_const_forElement() async {
    await assertErrorCodesInCode(r'''
const Set set = {};
var v = const [for(final x in set) x];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) 0 else a];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) a else 0];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) 0 else a];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) a else 0];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const [if (1 < 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) a];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const [if (1 > 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) a];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_topVar() async {
    await assertErrorCodesInCode('''
final dynamic a = 0;
var v = const [a];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_topVar_nested() async {
    await assertErrorCodesInCode(r'''
final dynamic a = 0;
var v = const [a + 1];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = [a];
''');
  }
}

@reflectiveTest
class NonConstantListElementWithConstantsTest
    extends NonConstantListElementTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];
}
