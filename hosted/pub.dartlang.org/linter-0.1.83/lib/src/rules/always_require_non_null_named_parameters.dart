// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use @required.';

const _details = r'''

**DO** specify `@required` on named parameter without default value on which an
assert(param != null) is done.

**GOOD:**
```
m1({@required a}) {
  assert(a != null);
}

m2({a: 1}) {
  assert(a != null);
}
```

**BAD:**
```
m1({a}) {
  assert(a != null);
}
```

NOTE: Only asserts at the start of the bodies will be taken into account.

''';

class AlwaysRequireNonNullNamedParameters extends LintRule
    implements NodeLintRule {
  AlwaysRequireNonNullNamedParameters()
      : super(
            name: 'always_require_non_null_named_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addFormalParameterList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkLiteral(TypedLiteral literal) {
    if (literal.typeArguments == null) {
      rule.reportLintForToken(literal.beginToken);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    final params = node.parameters
        // only named parameters
        .where((p) => p.isNamed)
        .map((p) => p as DefaultFormalParameter)
        // without default value
        .where((p) => p.defaultValue == null)
        // without @required
        .where((p) => !p.declaredElement.hasRequired)
        .toList();
    final parent = node.parent;
    if (parent is FunctionExpression) {
      _checkParams(params, parent.body);
    } else if (parent is ConstructorDeclaration) {
      _checkInitializerList(params, parent.initializers);
      _checkParams(params, parent.body);
    } else if (parent is MethodDeclaration) {
      _checkParams(params, parent.body);
    }
  }

  void _checkInitializerList(List<DefaultFormalParameter> params,
      NodeList<ConstructorInitializer> initializers) {
    final asserts = initializers
        .whereType<AssertInitializer>()
        .map((e) => e.condition)
        .toList();
    for (final param in params) {
      if (asserts.any((e) => _hasAssertNotNull(e, param.identifier.name))) {
        rule.reportLintForToken(param.identifier.beginToken);
      }
    }
  }

  void _checkParams(List<DefaultFormalParameter> params, FunctionBody body) {
    if (body is BlockFunctionBody) {
      final asserts = body.block.statements
          .takeWhile((e) => e is AssertStatement)
          .map((e) => (e as AssertStatement).condition)
          .toList();
      for (final param in params) {
        if (asserts.any((e) => _hasAssertNotNull(e, param.identifier.name))) {
          rule.reportLintForToken(param.identifier.beginToken);
        }
      }
    }
  }

  bool _hasAssertNotNull(Expression node, String name) {
    bool _hasSameName(Expression rawExpression) {
      final expression = rawExpression.unParenthesized;
      return expression is SimpleIdentifier && expression.name == name;
    }

    final expression = node.unParenthesized;
    if (expression is BinaryExpression) {
      if (expression.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        return _hasAssertNotNull(expression.leftOperand, name) ||
            _hasAssertNotNull(expression.rightOperand, name);
      }
      if (expression.operator.type == TokenType.BANG_EQ) {
        final operands = [expression.leftOperand, expression.rightOperand];
        return operands.any(DartTypeUtilities.isNullLiteral) &&
            operands.any(_hasSameName);
      }
    }
    return false;
  }
}
