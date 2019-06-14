// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show
        AstNode,
        ParenthesizedExpression,
        PrefixExpression,
        PrefixedIdentifier,
        PropertyAccess,
        SimpleIdentifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' show Element;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Use `isNotEmpty` for Iterables and Maps.';

const _details = r'''

**PREFER** `x.isNotEmpty` to `!x.isEmpty` for `Iterable` and `Map` instances.

When testing whether an iterable or map is empty, prefer `isNotEmpty` over
`!isEmpty` to improve code readability.

**GOOD:**
```
if (todo.isNotEmpty) {
  sendResults(request, todo.isEmpty);
}
```

**BAD:**
```
if (!sources.isEmpty) {
  process(sources);
}
```

''';

class PreferIsNotEmpty extends LintRule implements NodeLintRule {
  PreferIsNotEmpty()
      : super(
            name: 'prefer_is_not_empty',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    AstNode isEmptyAccess;
    SimpleIdentifier isEmptyIdentifier;

    AstNode parent = node.parent;
    if (parent is PropertyAccess) {
      isEmptyIdentifier = parent.propertyName;
      isEmptyAccess = parent;
    } else if (parent is PrefixedIdentifier) {
      isEmptyIdentifier = parent.identifier;
      isEmptyAccess = parent;
    }

    if (isEmptyIdentifier == null) {
      return;
    }

    // Should be "isEmpty".
    Element propertyElement = isEmptyIdentifier.staticElement;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      return;
    }
    // Should have "isNotEmpty".
    Element propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }

    // Walk up any parentheses above the isEmpty / isNotEmpty.
    AstNode isEmptyParent = isEmptyAccess.parent;
    while (isEmptyParent is ParenthesizedExpression) {
      isEmptyParent = isEmptyParent.parent;
    }

    // Should be in PrefixExpression.
    if (isEmptyParent is PrefixExpression) {
      // Should be !
      if (isEmptyParent.operator.type != TokenType.BANG) {
        return;
      }
      rule.reportLint(isEmptyParent);
    }
  }
}
