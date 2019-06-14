// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc =
    r'Avoid wrapping fields in getters and setters just to be "safe".';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**AVOID** wrapping fields in getters and setters just to be "safe".

In Java and C#, it's common to hide all fields behind getters and setters (or
properties in C#), even if the implementation just forwards to the field.  That
way, if you ever need to do more work in those members, you can without needing
to touch the callsites.  This is because calling a getter method is different
than accessing a field in Java, and accessing a property isn't binary-compatible
with accessing a raw field in C#.

Dart doesn't have this limitation.  Fields and getters/setters are completely
indistinguishable.  You can expose a field in a class and later wrap it in a
getter and setter without having to touch any code that uses that field.

**GOOD:**

```
class Box {
  var contents;
}
```

**BAD:**

```
class Box {
  var _contents;
  get contents => _contents;
  set contents(value) {
    _contents = value;
  }
}
```

''';

class UnnecessaryGettersSetters extends LintRule implements NodeLintRule {
  UnnecessaryGettersSetters()
      : super(
            name: 'unnecessary_getters_setters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    Map<String, MethodDeclaration> getters = {};
    Map<String, MethodDeclaration> setters = {};

    // Build getter/setter maps
    var methods = node.members.where(isMethod);
    for (MethodDeclaration method in methods) {
      if (method.isGetter) {
        getters[method.name.toString()] = method;
      } else if (method.isSetter) {
        setters[method.name.toString()] = method;
      }
    }

    // Only select getters with setter pairs
    getters.keys.where((id) => setters.keys.contains(id))
      ..forEach((id) => _visitGetterSetter(getters[id], setters[id]));
  }

  _visitGetterSetter(MethodDeclaration getter, MethodDeclaration setter) {
    if (isSimpleSetter(setter) &&
        isSimpleGetter(getter) &&
        !isProtected(getter) &&
        !isProtected(setter)) {
      rule..reportLint(getter.name)..reportLint(setter.name);
    }
  }
}
