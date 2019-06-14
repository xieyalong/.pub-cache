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
    defineReflectiveTests(NonConstantListElementFromDeferredLibraryTest);
    defineReflectiveTests(
        NonConstantListValueFromDeferredLibraryWithConstantsTest);
  });
}

@reflectiveTest
class NonConstantListElementFromDeferredLibraryTest
    extends DriverResolutionTest {
  @failingTest
  test_const_ifElement_thenTrue_deferredElse() async {
    // reports wrong error code (which is not crucial to fix)
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorCodesInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const [ if (cond) 'a' else a.c ];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY]);
  }

  test_const_ifElement_thenTrue_deferredThen() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorCodesInCode(
        r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const [ if (cond) a.c ];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                CompileTimeErrorCode
                    .NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY
              ]
            : [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
  }

  test_const_topLevel_deferred() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorCodesInCode(r'''
import 'lib1.dart' deferred as a;
var v = const [a.c];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY]);
  }

  test_const_topLevel_deferred_nested() async {
    newFile(convertPath('/test/lib/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorCodesInCode(r'''
import 'lib1.dart' deferred as a;
var v = const [a.c + 1];
''', [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY]);
  }
}

@reflectiveTest
class NonConstantListValueFromDeferredLibraryWithConstantsTest
    extends NonConstantListElementFromDeferredLibraryTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];
}
