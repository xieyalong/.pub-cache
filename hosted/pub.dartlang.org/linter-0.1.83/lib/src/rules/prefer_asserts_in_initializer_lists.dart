// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer putting asserts in initializer list.';

const _details = r'''
**DO** put asserts in initializer list for constructors with only asserts in
their body.

**GOOD:**
```
class A {
  A(int a) : assert(a != null);
}
```

**BAD:**
```
class A {
  A(int a) {
    assert(a != null);
  }
}
```

''';

class PreferAssertsInInitializerLists extends LintRule implements NodeLintRule {
  PreferAssertsInInitializerLists()
      : super(
            name: 'prefer_asserts_in_initializer_lists',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _AssertVisitor extends RecursiveAstVisitor {
  final ConstructorElement constructorElement;

  bool needInstance = false;

  _AssertVisitor(this.constructorElement);

  ClassElement get classElement => constructorElement.enclosingElement;

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;

    // use method
    needInstance = needInstance ||
        element is MethodElement && !element.isStatic && _hasMethod(element);

    // use property accessor not used as field formal parameter
    needInstance = needInstance ||
        element is PropertyAccessorElement &&
            !element.isStatic &&
            _hasAccessor(element) &&
            !constructorElement.parameters
                .whereType<FieldFormalParameterElement>()
                .any((p) => p.field.getter == element);
  }

  @override
  visitThisExpression(ThisExpression node) {
    needInstance = true;
  }

  bool _hasAccessor(PropertyAccessorElement element) {
    final type = classElement.type;
    final name = element.name;
    if (element.isGetter) {
      return type.lookUpGetter(name, element.library) == element ||
          type.lookUpInheritedGetter(name) == element;
    } else {
      return type.lookUpSetter(name, element.library) == element ||
          type.lookUpInheritedSetter(name) == element;
    }
  }

  bool _hasMethod(MethodElement element) {
    final type = classElement.type;
    final name = element.name;
    return type.lookUpMethod(name, element.library) == element ||
        type.lookUpInheritedMethod(name) == element;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.declaredElement.isFactory) return;

    final body = node.body;
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! AssertStatement) break;

        final assertVisitor = new _AssertVisitor(node.declaredElement);
        statement.visitChildren(assertVisitor);
        if (!assertVisitor.needInstance) {
          rule.reportLintForToken(statement.beginToken);
        }
      }
    }
  }
}
