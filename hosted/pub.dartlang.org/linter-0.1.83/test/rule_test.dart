// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart' as lint_service;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/implementation_imports.dart';
import 'package:linter/src/rules/package_prefixed_library_names.dart';
import 'package:linter/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'mock_sdk.dart';

main() {
  defineSanityTests();
  defineRuleTests();
  defineRuleUnitTests();
}

final String ruleDir = p.join('test', 'rules');
final String testConfigDir = p.join('test', 'configs');

/// Rule tests
defineRuleTests() {
  // TODO: if ruleDir cannot be found print message to set CWD to project root
  group('rule', () {
    group('dart', () {
      // Rule tests run with default analysis options.
      testRules(ruleDir, analysisOptions: null);

// todo (pq): enable when experimental feature implementations are far enough along
// see: https://github.com/dart-lang/linter/issues/1438
//      // Rule tests run against specific configurations.
//      for (var entry in new Directory(testConfigDir).listSync()) {
//        if (entry is! Directory) continue;
//        group('(config: ${p.basename(entry.path)})', () {
//          var analysisOptionsFile =
//              new File(p.join(entry.path, 'analysis_options.yaml'));
//          var analysisOptions = analysisOptionsFile.readAsStringSync();
//          testRules(ruleDir, analysisOptions: analysisOptions);
//        });
//      }
    });
    group('pub', () {
      for (var entry in new Directory(p.join(ruleDir, 'pub')).listSync()) {
        if (entry is! Directory) continue;
        Directory pubTestDir = entry;
        for (var file in pubTestDir.listSync()) {
          if (file is! File || !isPubspecFile(file)) continue;
          var ruleName = p.basename(pubTestDir.path);
          testRule(ruleName, file);
        }
      }
    });
    group('format', () {
      registerLintRules();
      for (LintRule rule in Registry.ruleRegistry.rules) {
        test('`${rule.name}` description', () {
          expect(rule.description.endsWith('.'), isTrue,
              reason:
                  "Rule description for ${rule.name} should end with a '.'");
        });
      }
    });
  });
}

defineRuleUnitTests() {
  group('uris', () {
    group('isPackage', () {
      [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ]..forEach((uri) {
          test(uri.toString(), () {
            expect(isPackage(uri), isTrue);
          });
        });
      [
        Uri.parse('foo/bar.dart'),
        Uri.parse('src/bar.dart'),
        Uri.parse('dart:async')
      ]..forEach((uri) {
          test(uri.toString(), () {
            expect(isPackage(uri), isFalse);
          });
        });
    });

    group('samePackage', () {
      test('identity', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/src/bar.dart')),
            isTrue);
      });
      test('foo/bar.dart', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/bar.dart')),
            isTrue);
      });
    });

    group('implementation', () {
      [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ]..forEach((uri) {
          test(uri.toString(), () {
            expect(isImplementation(uri), isTrue);
          });
        });
      [Uri.parse('package:foo/bar.dart'), Uri.parse('src/bar.dart')]
        ..forEach((uri) {
          test(uri.toString(), () {
            expect(isImplementation(uri), isFalse);
          });
        });
    });
  });

  group('names', () {
    group('keywords', () {
      var good = ['class', 'if', 'assert', 'catch', 'import'];
      testEach(good, isKeyWord, isTrue);
      var bad = ['_class', 'iff', 'assert_', 'Catch'];
      testEach(bad, isKeyWord, isFalse);
    });
    group('identifiers', () {
      var good = [
        'foo',
        '_if',
        '_',
        'f2',
        'fooBar',
        'foo_bar',
        '\$foo',
        'foo\$Bar',
        'foo\$'
      ];
      testEach(good, isValidDartIdentifier, isTrue);
      var bad = ['if', '42', '3', '2f'];
      testEach(bad, isValidDartIdentifier, isFalse);
    });
    group('libary_name_prefixes', () {
      testEach(
          Iterable<List<String>> values, dynamic f(List<String> s), Matcher m) {
        values.forEach((s) => test('${s[3]}', () => expect(f(s), m)));
      }

      bool isGoodPrefx(List<String> v) => matchesOrIsPrefixedBy(
          v[3],
          Analyzer.facade.createLibraryNamePrefix(
              libraryPath: v[0], projectRoot: v[1], packageName: v[2]));

      var good = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.src.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.test.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.data.a'],
        ['/u/b/c/lib/acme.dart', '/u/b/c', 'acme', 'acme']
      ];
      testEach(good, isGoodPrefx, isTrue);

      var bad = [
        ['/u/b/c/lib/src/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/lib/a.dart', '/u/b/c', 'acme', 'wrk.acme.a'],
        ['/u/b/c/test/a.dart', '/u/b/c', 'acme', 'acme.a'],
        ['/u/b/c/test/data/a.dart', '/u/b/c', 'acme', 'acme.test.a']
      ];
      testEach(bad, isGoodPrefx, isFalse);
    });
  });
}

/// Test framework sanity
defineSanityTests() {
  group('test framework', () {
    group('annotation', () {
      test('extraction', () {
        expect(extractAnnotation('int x; // LINT [1:3]'), isNotNull);
        expect(extractAnnotation('int x; //LINT'), isNotNull);
        expect(extractAnnotation('int x; // OK'), isNull);
        expect(extractAnnotation('int x;'), isNull);
        expect(extractAnnotation('dynamic x; // LINT dynamic is bad').message,
            'dynamic is bad');
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad')
                .message,
            'dynamic is bad');
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').column,
            1);
        expect(
            extractAnnotation('dynamic x; // LINT [1:3] dynamic is bad').length,
            3);
        expect(extractAnnotation('dynamic x; //LINT').message, isNull);
        expect(extractAnnotation('dynamic x; //LINT ').message, isNull);
        // Commented out lines shouldn't get linted.
        expect(extractAnnotation('// dynamic x; //LINT '), isNull);
      });
    });
    test('equality', () {
      expect(
          new Annotation('Actual message (to be ignored)', ErrorType.LINT, 1),
          matchesAnnotation(null, ErrorType.LINT, 1));
      expect(new Annotation('Message', ErrorType.LINT, 1),
          matchesAnnotation('Message', ErrorType.LINT, 1));
    });
    test('inequality', () {
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.HINT, 1)),
          throwsA(new TypeMatcher<TestFailure>()));
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message2', ErrorType.LINT, 1)),
          throwsA(new TypeMatcher<TestFailure>()));
      expect(
          () => expect(new Annotation('Message', ErrorType.LINT, 1),
              matchesAnnotation('Message', ErrorType.LINT, 2)),
          throwsA(new TypeMatcher<TestFailure>()));
    });
  });

  group('reporting', () {
    //https://github.com/dart-lang/linter/issues/193
    group('ignore synthetic nodes', () {
      String path = p.join('test', '_data', 'synthetic', 'synthetic.dart');
      File file = new File(path);
      testRule('non_constant_identifier_names', file);
    });
  });

  test('linter version caching', () {
    registerLintRules();
    expect(lint_service.linterVersion, version);
  });
}

/// Handy for debugging.
defineSoloRuleTest(String ruleToTest) {
  for (var entry in new Directory(ruleDir).listSync()) {
    if (entry is! File || !isDartFile(entry)) continue;
    var ruleName = p.basenameWithoutExtension(entry.path);
    if (ruleName == ruleToTest) {
      testRule(ruleName, entry);
    }
  }
}

Annotation extractAnnotation(String line) {
  int index = line.indexOf(new RegExp(r'(//|#)[ ]?LINT'));

  // Grab the first comment to see if there's one preceding the annotation.
  // Check for '#' first to allow for lints on dartdocs.
  int comment = line.indexOf('#');
  if (comment == -1) {
    comment = line.indexOf('//');
  }

  if (index > -1 && comment == index) {
    int column;
    int length;
    var annotation = line.substring(index);
    var leftBrace = annotation.indexOf('[');
    if (leftBrace != -1) {
      var sep = annotation.indexOf(':');
      column = int.parse(annotation.substring(leftBrace + 1, sep));
      var rightBrace = annotation.indexOf(']');
      length = int.parse(annotation.substring(sep + 1, rightBrace));
    }

    int msgIndex = annotation.indexOf(']') + 1;
    if (msgIndex < 1) {
      msgIndex = annotation.indexOf('T') + 1;
    }
    String msg;
    if (msgIndex < line.length) {
      msg = line.substring(index + msgIndex).trim();
      if (msg.isEmpty) {
        msg = null;
      }
    }
    return new Annotation.forLint(msg, column, length);
  }
  return null;
}

AnnotationMatcher matchesAnnotation(
        String message, ErrorType type, int lineNumber) =>
    new AnnotationMatcher(new Annotation(message, type, lineNumber));

testEach(Iterable<Object> values, bool f(String s), Matcher m) {
  values.forEach((s) => test('"$s"', () => expect(f(s), m)));
}

testEachInt(Iterable<Object> values, bool f(int s), Matcher m) {
  values.forEach((s) => test('"$s"', () => expect(f(s), m)));
}

testRules(String ruleDir, {String analysisOptions}) {
  for (var entry in new Directory(ruleDir).listSync()) {
    if (entry is! File || !isDartFile(entry)) continue;
    var ruleName = p.basenameWithoutExtension(entry.path);
    testRule(ruleName, entry, debug: true, analysisOptions: analysisOptions);
  }
}

testRule(String ruleName, File file,
    {bool debug = false, String analysisOptions}) {
  registerLintRules();

  test('$ruleName', () async {
    if (!file.existsSync()) {
      throw new Exception('No rule found defined at: ${file.path}');
    }

    var expected = <AnnotationMatcher>[];

    int lineNumber = 1;
    for (var line in file.readAsLinesSync()) {
      var annotation = extractAnnotation(line);
      if (annotation != null) {
        annotation.lineNumber = lineNumber;
        expected.add(new AnnotationMatcher(annotation));
      }
      ++lineNumber;
    }

    LintRule rule = Registry.ruleRegistry[ruleName];
    if (rule == null) {
      print('WARNING: Test skipped -- rule `$ruleName` is not registered.');
      return;
    }

    MemoryResourceProvider memoryResourceProvider = new MemoryResourceProvider(
        context: PhysicalResourceProvider.INSTANCE.pathContext);
    TestResourceProvider resourceProvider =
        new TestResourceProvider(memoryResourceProvider);

    p.Context pathContext = memoryResourceProvider.pathContext;
    String packageConfigPath = memoryResourceProvider.convertPath(pathContext
        .join(pathContext.dirname(file.absolute.path), '.mock_packages'));
    if (!resourceProvider.getFile(packageConfigPath).exists) {
      packageConfigPath = null;
    }

    LinterOptions options = new LinterOptions([rule], analysisOptions)
      ..mockSdk = new MockSdk(memoryResourceProvider)
      ..resourceProvider = resourceProvider
      ..packageConfigPath = packageConfigPath;

    DartLinter driver = new DartLinter(options);

    Iterable<AnalysisErrorInfo> lints = await driver.lintFiles([file]);

    List<Annotation> actual = [];
    lints.forEach((AnalysisErrorInfo info) {
      info.errors.forEach((AnalysisError error) {
        if (error.errorCode.type == ErrorType.LINT) {
          actual.add(new Annotation.forError(error, info.lineInfo));
        }
      });
    });
    actual.sort();
    try {
      expect(actual, unorderedMatches(expected));
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (debug) {
        // Dump results for debugging purposes.

        //AST.
        new Spelunker(file.absolute.path).spelunk();
        print('');
        // Lints.
        new ResultReporter(lints)..write();
      }

      // Rethrow and fail.
      rethrow;
    }
  });
}

class Annotation implements Comparable<Annotation> {
  final int column;
  final int length;
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type, this.lineNumber,
      {this.column, this.length});

  Annotation.forError(AnalysisError error, LineInfo lineInfo)
      : this(error.message, error.errorCode.type,
            lineInfo.getLocation(error.offset).lineNumber,
            column: lineInfo.getLocation(error.offset).columnNumber,
            length: error.length);

  Annotation.forLint([String message, int column, int length])
      : this(message, ErrorType.LINT, null, column: column, length: length);

  @override
  int compareTo(Annotation other) {
    if (lineNumber != other.lineNumber) {
      return lineNumber - other.lineNumber;
    } else if (column != other.column) {
      return column - other.column;
    }
    return message.compareTo(other.message);
  }

  @override
  String toString() =>
      '[$type]: "$message" (line: $lineNumber) - [$column:$length]';

  static Iterable<Annotation> fromErrors(AnalysisErrorInfo error) {
    List<Annotation> annotations = [];
    error.errors.forEach(
        (e) => annotations.add(new Annotation.forError(e, error.lineInfo)));
    return annotations;
  }
}

class AnnotationMatcher extends Matcher {
  final Annotation _expected;

  AnnotationMatcher(this._expected);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  bool matches(item, Map matchState) => item is Annotation && _matches(item);

  bool _matches(Annotation other) {
    // Only test messages if they're specified in the expectation
    if (_expected.message != null) {
      if (_expected.message != other.message) {
        return false;
      }
    }
    // Similarly for highlighting
    if (_expected.column != null) {
      if (_expected.column != other.column ||
          _expected.length != other.length) {
        return false;
      }
    }
    return _expected.type == other.type &&
        _expected.lineNumber == other.lineNumber;
  }
}

class NoFilter implements LintFilter {
  @override
  bool filter(AnalysisError lint) => false;
}

class ResultReporter extends DetailedReporter {
  ResultReporter(Iterable<AnalysisErrorInfo> errors)
      : super(errors, new NoFilter(), stdout);
}

class TestResourceProvider extends PhysicalResourceProvider {
  MemoryResourceProvider memoryResourceProvider;

  TestResourceProvider(this.memoryResourceProvider) : super(null);

  @override
  file_system.File getFile(String path) {
    file_system.File file = memoryResourceProvider.getFile(path);
    return file.exists ? file : super.getFile(path);
  }

  @override
  file_system.Folder getFolder(String path) {
    file_system.Folder folder = memoryResourceProvider.getFolder(path);
    return folder.exists ? folder : super.getFolder(path);
  }

  @override
  file_system.Resource getResource(String path) {
    file_system.Resource resource = memoryResourceProvider.getResource(path);
    return resource.exists ? resource : super.getResource(path);
  }
}
