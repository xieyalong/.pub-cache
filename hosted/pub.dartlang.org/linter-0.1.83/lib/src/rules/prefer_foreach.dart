// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use `forEach` to only apply a function to all the elements.';

const _details = r'''

**DO** use `forEach` if you are only going to apply a function or a method
to all the elements of an iterable.

Using `forEach` when you are only going to apply a function or method to all
elements of an iterable is a good practice because it makes your code more
terse.

**BAD:**
```
for (final key in map.keys.toList()) {
  map.remove(key);
}
```

**GOOD:**
```
map.keys.toList().forEach(map.remove);
```

**NOTE:** Replacing a for each statement with a forEach call may change the 
behavior in the case where there are side-effects on the iterable itself.
```
for (final v in myList) {
  foo().f(v); // This code invokes foo() many times.
}

myList.forEach(foo().f); // But this one invokes foo() just once.
```

''';

class PreferForeach extends LintRule implements NodeLintRule {
  PreferForeach()
      : super(
            name: 'prefer_foreach',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addForStatement2(this, visitor);
  }
}

class _PreferForEachVisitor extends SimpleAstVisitor {
  final LintRule rule;
  LocalVariableElement element;
  ForStatement2 forEachStatement;

  _PreferForEachVisitor(this.rule);

  @override
  visitBlock(Block node) {
    if (node.statements.length == 1) {
      node.statements.first.accept(this);
    }
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  visitForStatement2(ForStatement2 node) {
    final loopParts = node.forLoopParts;
    if (loopParts is ForEachPartsWithDeclaration) {
      final element = loopParts.loopVariable?.declaredElement;
      if (element != null) {
        forEachStatement = node;
        this.element = element;
        node.body.accept(this);
      }
    }
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length == 1 &&
        DartTypeUtilities.getCanonicalElementFromIdentifier(arguments.first) ==
            element) {
      rule.reportLint(forEachStatement);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.length == 1 &&
        DartTypeUtilities.getCanonicalElementFromIdentifier(arguments.first) ==
            element &&
        (node.target == null ||
            (DartTypeUtilities.getCanonicalElementFromIdentifier(node.target) !=
                    element &&
                !DartTypeUtilities.traverseNodesInDFS(node.target)
                    .map(DartTypeUtilities.getCanonicalElementFromIdentifier)
                    .contains(element)))) {
      rule.reportLint(forEachStatement);
    }
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitForStatement2(ForStatement2 node) {
    final loopParts = node.forLoopParts;
    if (loopParts is ForEachParts) {
      final visitor = new _PreferForEachVisitor(rule);
      node.accept(visitor);
    }
  }
}
