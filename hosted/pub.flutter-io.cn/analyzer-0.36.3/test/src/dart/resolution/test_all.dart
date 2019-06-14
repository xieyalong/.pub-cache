// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assignment_test.dart' as assignment;
import 'class_alias_test.dart' as class_alias;
import 'class_test.dart' as class_resolution;
import 'comment_test.dart' as comment;
import 'constant_test.dart' as constant;
import 'constructor_test.dart' as constructor;
import 'definite_assignment_test.dart' as definite_assignment;
import 'enum_test.dart' as enum_resolution;
import 'flow_analysis_test.dart' as flow_analysis;
import 'for_element_test.dart' as for_element;
import 'for_in_test.dart' as for_in;
import 'generic_type_alias_test.dart' as generic_type_alias;
import 'import_prefix_test.dart' as import_prefix;
import 'instance_creation_test.dart' as instance_creation;
import 'instance_member_inference_class_test.dart'
    as instance_member_inference_class;
import 'instance_member_inference_mixin_test.dart'
    as instance_member_inference_mixin;
import 'method_invocation_test.dart' as method_invocation;
import 'mixin_test.dart' as mixin_resolution;
import 'non_nullable_test.dart' as non_nullable;
import 'optional_const_test.dart' as optional_const;
import 'property_access_test.dart' as property_access;
import 'top_type_inference_test.dart' as top_type_inference;
import 'type_inference/test_all.dart' as type_inference;

main() {
  defineReflectiveSuite(() {
    assignment.main();
    class_alias.main();
    class_resolution.main();
    comment.main();
    constant.main();
    constructor.main();
    definite_assignment.main();
    enum_resolution.main();
    flow_analysis.main();
    for_element.main();
    for_in.main();
    generic_type_alias.main();
    import_prefix.main();
    instance_creation.main();
    instance_member_inference_class.main();
    instance_member_inference_mixin.main();
    method_invocation.main();
    mixin_resolution.main();
    non_nullable.main();
    optional_const.main();
    property_access.main();
    top_type_inference.main();
    type_inference.main();
  }, name: 'resolution');
}
