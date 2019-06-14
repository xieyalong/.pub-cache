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
    defineReflectiveTests(SetElementTypeNotAssignableTest);
    defineReflectiveTests(SetElementTypeNotAssignableWithConstantTest);
  });
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends DriverResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>{if (1 < 0) a else b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>{if (1 < 0) a else b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorCodesInCode(
        '''
var v = const <int>{if (1 < 0) 'a'};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]
            : [
                StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE,
                CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT
              ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 'a';
var v = const <int>{if (1 < 0) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 0;
var v = const <int>{if (true) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorCodesInCode(
        '''
const dynamic a = 'a';
var v = const <int>{if (true) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_spread_intInt() async {
    await assertErrorCodesInCode(
        '''
var v = const <int>{...[0, 1]};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_explicitTypeArgs_const() async {
    await assertErrorCodesInCode('''
var v = const <String>{42};
''', [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_explicitTypeArgs_const_actualTypeMatch() async {
    await assertNoErrorsInCode('''
const dynamic x = null;
var v = const <String>{x};
''');
  }

  test_explicitTypeArgs_const_actualTypeMismatch() async {
    await assertErrorCodesInCode('''
const dynamic x = 42;
var v = const <String>{x};
''', [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_explicitTypeArgs_notConst() async {
    await assertErrorCodesInCode('''
var v = <String>{42};
''', [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await assertErrorCodesInCode('''
var v = <int>[if (1 < 0) 'a'];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int>{if (true) a};
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int>{if (true) a};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int>{...[0, 1]};
''');
  }
}

@reflectiveTest
class SetElementTypeNotAssignableWithConstantTest
    extends SetElementTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];
}
