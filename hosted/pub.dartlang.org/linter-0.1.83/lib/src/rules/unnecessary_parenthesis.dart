// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Unnecessary parenthesis can be removed.';

const _details = r'''

**AVOID** using parenthesis when not needed.

**GOOD:**
```
a = b;
```

**BAD:**
```
a = (b);
```

''';

class UnnecessaryParenthesis extends LintRule implements NodeLintRule {
  UnnecessaryParenthesis()
      : super(
            name: 'unnecessary_parenthesis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addParenthesizedExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (node.expression is SimpleIdentifier) {
      rule.reportLint(node);
      return;
    }

    final parent = node.parent;

    if (parent is ParenthesizedExpression) {
      rule.reportLint(node);
      return;
    }

    // `a..b=(c..d)` is OK.
    if (node.expression is CascadeExpression ||
        node.thisOrAncestorMatching(
                (n) => n is Statement || n is CascadeExpression)
            is CascadeExpression) {
      return;
    }

    // Constructor field initializers are rather unguarded by delimiting
    // tokens, which can get confused with a function expression. See test
    // cases for issues #1395 and #1473.
    if (parent is ConstructorFieldInitializer &&
        _containsFunctionExpression(node)) {
      return;
    }

    if (parent is Expression) {
      if (parent is BinaryExpression) return;
      if (parent is ConditionalExpression) return;
      if (parent is CascadeExpression) return;
      if (parent is FunctionExpressionInvocation) return;

      // A prefix expression (! or -) can have an argument wrapped in
      // "unnecessary" parens if that argument has potentially confusing
      // whitespace after its first token.
      if (parent is PrefixExpression &&
          _expressionStartsWithWhitespace(node.expression)) return;

      // Another case of the above exception, something like
      // `!(const [7]).contains(5);`, where the _parent's_ parent is the
      // PrefixExpression.
      if (parent is MethodInvocation) {
        Expression target = parent.target;
        if (parent.parent is PrefixExpression &&
            target == node &&
            _expressionStartsWithWhitespace(node.expression)) return;
      }

      if (parent.precedence2 < node.expression.precedence2) {
        rule.reportLint(node);
        return;
      }
    } else {
      rule.reportLint(node);
      return;
    }
  }

  bool _containsFunctionExpression(ParenthesizedExpression node) {
    final containsFunctionExpressionVisitor =
        _ContainsFunctionExpressionVisitor();
    node.accept(containsFunctionExpressionVisitor);
    return containsFunctionExpressionVisitor.hasFunctionExpression;
  }

  /// Returns whether [node] "starts" with whitespace.
  ///
  /// That is, is there definitely whitespace after the first token in [node]?
  bool _expressionStartsWithWhitespace(Expression node) =>
      // As in, `!(await foo)`.
      node is AwaitExpression ||
      // As in, `!(new Foo())`.
      (node is InstanceCreationExpression && node.keyword != null) ||
      // No TypedLiteral (ListLiteral, MapLiteral, SetLiteral) accepts `-` or
      // `!` as a prefix operator, but this method can be called recursively,
      // so this catches things like `!(const [].contains(42))`.
      (node is TypedLiteral && node.constKeyword != null) ||
      // As in, `!(const List(3).contains(7))`, and chains like
      // `-(new List(3).skip(1).take(3).skip(1).length)`.
      (node is MethodInvocation &&
          _expressionStartsWithWhitespace(node.target)) ||
      // As in, `-(new List(3).length)`, and chains like
      // `-(new List(3).length.bitLength.bitLength)`.
      (node is PropertyAccess && _expressionStartsWithWhitespace(node.target));
}

class _ContainsFunctionExpressionVisitor extends UnifyingAstVisitor<void> {
  bool hasFunctionExpression = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    hasFunctionExpression = true;
  }

  @override
  void visitNode(AstNode node) {
    if (!hasFunctionExpression) {
      node.visitChildren(this);
    }
  }
}
