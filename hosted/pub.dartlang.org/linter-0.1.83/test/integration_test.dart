// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'mocks.dart';

main() {
  defineTests();
}

defineTests() {
  group('integration', () {
    group('p2', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });
      group('config', () {
        test('excludes', () async {
          await cli
              .run(['test/_data/p2', '-c', 'test/_data/p2/lintconfig.yaml']);
          expect(
              collectingOut.trim(),
              stringContainsInOrder(
                  ['4 files analyzed, 1 issue found (2 filtered), in']));
          expect(exitCode, 1);
        });
        test('overrrides', () async {
          await cli
              .run(['test/_data/p2', '-c', 'test/_data/p2/lintconfig2.yaml']);
          expect(collectingOut.trim(),
              stringContainsInOrder(['4 files analyzed, 0 issues found, in']));
          expect(exitCode, 0);
        });
        test('default', () async {
          await cli.run(['test/_data/p2']);
          expect(collectingOut.trim(),
              stringContainsInOrder(['4 files analyzed, 3 issues found, in']));
          expect(exitCode, 1);
        });
      });
    });
    group('p3', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      test('bad pubspec', () async {
        await cli.run(['test/_data/p3', 'test/_data/p3/_pubpspec.yaml']);
        expect(collectingOut.trim(),
            startsWith('1 file analyzed, 0 issues found, in'));
      });
    });
    group('p4', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      test('no warnings due to bad canonicalization', () async {
        var packagesFilePath =
            new File('test/_data/p4/_packages').absolute.path;
        await cli.runLinter(['--packages', packagesFilePath, 'test/_data/p4'],
            new LinterOptions([]));
        expect(collectingOut.trim(),
            startsWith('3 files analyzed, 0 issues found, in'));
      });
    });

    group('p5', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });
      group('.packages', () {
        test('basic', () async {
          // Requires .packages to analyze cleanly.
          await cli
              .run(['test/_data/p5', '--packages', 'test/_data/p5/_packages']);
          // Should have 0 issues.
          expect(exitCode, 0);
        });
      });
    });

    group('overridden_fields', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      // https://github.com/dart-lang/linter/issues/246
      test('overrides across libraries', () async {
        await cli.run(
            ['test/_data/overridden_fields', '--rules', 'overridden_fields']);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['int public;', '2 files analyzed, 1 issue found, in']));
        expect(exitCode, 1);
      });
    });

    group('close_sinks', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('close sinks', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/close_sinks',
          '--rules=close_sinks'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'IOSink _sinkA; // LINT',
              'IOSink _sinkSomeFunction; // LINT',
              '1 file analyzed, 2 issues found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('cancel_subscriptions', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('cancel subscriptions', () async {
        await cli.run([
          'test/_data/cancel_subscriptions',
          '--rules=cancel_subscriptions'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'StreamSubscription _subscriptionA; // LINT',
              'StreamSubscription _subscriptionF; // LINT',
              '1 file analyzed, 3 issues found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('directives_ordering', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('dart_directives_go_first', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/dart_directives_go_first',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'dart:' imports before other imports.",
              "import 'dart:html';  // LINT",
              "Place 'dart:' imports before other imports.",
              "import 'dart:isolate';  // LINT",
              "Place 'dart:' exports before other exports.",
              "export 'dart:html';  // LINT",
              "Place 'dart:' exports before other exports.",
              "export 'dart:isolate';  // LINT",
              '2 files analyzed, 4 issues found, in'
            ]));
        expect(exitCode, 1);
      });

      test('package_directives_before_relative', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/package_directives_before_relative',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'package:' imports before relative imports.",
              "import 'package:async/src/async_cache.dart'; // LINT",
              "Place 'package:' imports before relative imports.",
              "import 'package:yaml/yaml.dart'; // LINT",
              "Place 'package:' exports before relative exports.",
              "export 'package:async/src/async_cache.dart'; // LINT",
              "Place 'package:' exports before relative exports.",
              "export 'package:yaml/yaml.dart'; // LINT",
              '3 files analyzed, 4 issues found, in'
            ]));
        expect(exitCode, 1);
      });

      test('third_party_package_directives_before_own', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/third_party_package_directives_before_own',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'third-party' 'package:' imports before other imports.",
              "import 'package:async/async.dart';  // LINT",
              "Place 'third-party' 'package:' imports before other imports.",
              "import 'package:yaml/yaml.dart';  // LINT",
              "Place 'third-party' 'package:' exports before other exports.",
              "export 'package:async/async.dart';  // LINT",
              "Place 'third-party' 'package:' exports before other exports.",
              "export 'package:yaml/yaml.dart';  // LINT",
              '1 file analyzed, 4 issues found, in'
            ]));
        expect(exitCode, 1);
      });

      test('export_directives_after_import_directives', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/export_directives_after_import_directives',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'Specify exports in a separate section after all imports.',
              "export 'dummy.dart';  // LINT",
              'Specify exports in a separate section after all imports.',
              "export 'dummy2.dart';  // LINT",
              '5 files analyzed, 2 issues found, in'
            ]));
        expect(exitCode, 1);
      });

      test('sort_directive_sections_alphabetically', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/sort_directive_sections_alphabetically',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'Sort directive sections alphabetically.',
              "import 'dart:convert'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'package:charcode/ascii.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'package:analyzer/analyzer.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'package:linter/src/formatter.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'dummy3.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'dummy2.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'dummy1.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'dart:convert'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'package:charcode/ascii.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'package:analyzer/analyzer.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'package:linter/src/formatter.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'dummy1.dart'; // LINT",
              '5 files analyzed, 12 issues found, in'
            ]));
        expect(exitCode, 1);
      });

      test('lint_one_node_no_more_than_once', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/lint_one_node_no_more_than_once',
          '--rules=directives_ordering'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'package:' imports before relative imports.",
              "import 'package:async/async.dart';  // LINT",
              '2 files analyzed, 1 issue found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('file_names', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('bad', () async {
        await cli.run(['test/_data/file_names/a-b.dart', '--rules=file_names']);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a-b.dart 1:1 [lint] Name source files using `lowercase_with_underscores`.'
            ]));
        expect(exitCode, 1);
      });

      test('ok', () async {
        await cli.run([
          'test/_data/file_names/non-strict.css.dart',
          '--rules=file_names'
        ]);
        expect(exitCode, 0);
      });
    });

    group('flutter_style_todos', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('on bad TODOs', () async {
        await cli.run(
            ['test/_data/flutter_style_todos', '--rules=flutter_style_todos']);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 8:1 [lint] Use Flutter TODO format:',
              'a.dart 9:1 [lint] Use Flutter TODO format:',
              'a.dart 10:1 [lint] Use Flutter TODO format:',
              'a.dart 11:1 [lint] Use Flutter TODO format:',
              'a.dart 12:1 [lint] Use Flutter TODO format:',
              'a.dart 13:1 [lint] Use Flutter TODO format:',
              'a.dart 14:1 [lint] Use Flutter TODO format:',
              'a.dart 15:1 [lint] Use Flutter TODO format:',
              'a.dart 16:1 [lint] Use Flutter TODO format:',
              'a.dart 17:1 [lint] Use Flutter TODO format:',
              'a.dart 18:1 [lint] Use Flutter TODO format:',
              '1 file analyzed, 11 issues found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('lines_longer_than_80_chars', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('only throw errors', () async {
        await cli.run([
          'test/_data/lines_longer_than_80_chars',
          '--rules=lines_longer_than_80_chars'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 3:1 [lint] AVOID lines longer than 80 characters',
              'a.dart 7:1 [lint] AVOID lines longer than 80 characters',
              'a.dart 16:1 [lint] AVOID lines longer than 80 characters',
              'a.dart 21:1 [lint] AVOID lines longer than 80 characters',
              '1 file analyzed, 4 issues found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('only_throw_errors', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('only throw errors', () async {
        await cli
            .run(['test/_data/only_throw_errors', '--rules=only_throw_errors']);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "throw 'hello world!'; // LINT",
              'throw null; // LINT',
              'throw 7; // LINT',
              'throw new Object(); // LINT',
              'throw returnString(); // LINT',
              '1 file analyzed, 5 issues found, in'
            ]));
        expect(exitCode, 1);
      });
    });

    group('always_require_non_null_named_parameters', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('only throw errors', () async {
        await cli.runLinter([
          'test/_data/always_require_non_null_named_parameters',
          '--rules=always_require_non_null_named_parameters'
        ], new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['b, // LINT', '1 file analyzed, 1 issue found, in']));
        expect(exitCode, 1);
      });
    });

    group('prefer_asserts_in_initializer_lists', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('only throw errors', () async {
        await cli.runLinter([
          'test/_data/prefer_asserts_in_initializer_lists',
          '--rules=prefer_asserts_in_initializer_lists'
        ], new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['lib.dart 6:5', '1 file analyzed, 1 issue found, in']));
        expect(exitCode, 1);
      });
    });

    group('prefer_const_constructors_in_immutables', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('only throw errors', () async {
        await cli.runLinter([
          'test/_data/prefer_const_constructors_in_immutables',
          '--rules=prefer_const_constructors_in_immutables'
        ], new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['D.c2(a)', '1 file analyzed, 1 issue found, in']));
        expect(exitCode, 1);
      });
    });

    group('avoid_relative_lib_imports', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('avoid relative lib imports', () async {
        await cli.runLinter([
          'test/_data/avoid_relative_lib_imports',
          '--rules=avoid_relative_lib_imports',
          '--packages',
          'test/_data/avoid_relative_lib_imports/_packages'
        ], new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['main.dart 3:8', '2 files analyzed, 1 issue found, in']));
        expect(exitCode, 1);
      });
    });

    group('public_member_api_docs', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('lint lib/ sources and non-lib/ sources', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await cli.run([
          '--packages',
          packagesFilePath,
          'test/_data/public_member_api_docs',
          '--rules=public_member_api_docs'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 7:16 [lint] Document all public members',
              'a.dart 15:11 [lint] Document all public members',
              'a.dart 19:16 [lint] Document all public members',
              'a.dart 22:3 [lint] Document all public members',
              'a.dart 23:5 [lint] Document all public members',
              'a.dart 25:7 [lint] Document all public members',
              'a.dart 27:7 [lint] Document all public members',
              'a.dart 35:3 [lint] Document all public members',
              'a.dart 37:3 [lint] Document all public members',
              'a.dart 45:9 [lint] Document all public members',
              'a.dart 53:14 [lint] Document all public members',
              'a.dart 59:6 [lint] Document all public members',
              'a.dart 61:3 [lint] Document all public members',
              'a.dart 80:1 [lint] Document all public members',
              'a.dart 85:5 [lint] Document all public members',
              'a.dart 89:5 [lint] Document all public members',
              '3 files analyzed, 16 issues found'
            ]));
        expect(exitCode, 1);
      });
    });

    group('avoid_renaming_method_parameters', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('lint lib/ sources and non-lib/ sources', () async {
        await cli.run([
          '--packages',
          'test/_data/avoid_renaming_method_parameters/_packages',
          'test/_data/avoid_renaming_method_parameters',
          '--rules=avoid_renaming_method_parameters'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 29:6 [lint] Don\'t rename parameters of overridden methods.',
              'a.dart 31:12 [lint] Don\'t rename parameters of overridden methods.',
              'a.dart 32:9 [lint] Don\'t rename parameters of overridden methods.',
              'a.dart 34:7 [lint] Don\'t rename parameters of overridden methods.',
              'a.dart 35:6 [lint] Don\'t rename parameters of overridden methods.',
              'a.dart 36:6 [lint] Don\'t rename parameters of overridden methods.',
              '3 files analyzed, 6 issues found',
            ]));
        expect(exitCode, 1);
      });
    });

    group('avoid_private_typedef_functions', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('handles parts', () async {
        await cli.run([
          'test/_data/avoid_private_typedef_functions/lib.dart',
          'test/_data/avoid_private_typedef_functions/part.dart',
          '--rules=avoid_private_typedef_functions'
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'lib.dart 9:1 [lint] Avoid private typedef functions.',
              'part.dart 9:1 [lint] Avoid private typedef functions.',
              '2 files analyzed, 2 issues found',
            ]));
        expect(exitCode, 1);
      });
    });

    // TODO(a14n) move to unit test once previewDart2 disappears
    group('unnecessary_const', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('avoid keyword to create instances', () async {
        await cli.runLinter(
            ['test/_data/unnecessary_const', '--rules=unnecessary_const'],
            new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 24:14 [lint] Avoid const keyword.',
              'a.dart 27:14 [lint] Avoid const keyword.',
              'a.dart 30:22 [lint] Avoid const keyword.',
              'a.dart 32:23 [lint] Avoid const keyword.',
              '1 file analyzed, 4 issues found',
            ]));
        expect(exitCode, 1);
      });
    });

    // TODO(a14n) move to unit test once previewDart2 disappears
    group('unnecessary_new', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('avoid keyword to create instances', () async {
        await cli.runLinter(
            ['test/_data/unnecessary_new', '--rules=unnecessary_new'],
            new LinterOptions());
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'a.dart 14:3 [lint] Unnecessary new keyword.',
              'a.dart 17:3 [lint] Unnecessary new keyword.',
              'a.dart 20:3 [lint] Unnecessary new keyword.',
              'a.dart 24:14 [lint] Unnecessary new keyword.',
              '1 file analyzed, 4 issues found',
            ]));
        expect(exitCode, 1);
      });
    });

    group('sort_pub_dependencies', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });

      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('check order', () async {
        await cli.run([
          'test/_data/sort_pub_dependencies',
          '--rules=sort_pub_dependencies',
        ]);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'pubspec.yaml 6:3 [lint] Sort pub dependencies.',
              'pubspec.yaml 10:3 [lint] Sort pub dependencies.',
              'pubspec.yaml 15:3 [lint] Sort pub dependencies.',
              '1 file analyzed, 3 issues found',
            ]));
        expect(exitCode, 1);
      });
    });

    group('examples', () {
      test('all.yaml', () {
        String src = readFile('example/all.yaml');

        Map<String, YamlNode> options = _getOptionsFromString(src);
        var configuredLints =
            ((options['linter'] as YamlMap)['rules'] as YamlList);

        // rules are sorted
        expect(
            configuredLints, orderedEquals(configuredLints.toList()..sort()));

        registerLintRules();
        expect(
            configuredLints,
            unorderedEquals(Analyzer.facade.registeredRules
                .where((r) => r.maturity != Maturity.deprecated)
                .map((r) => r.name)));
      });
    });
  });
}

/// Provide the options found in [optionsSource].
Map<String, YamlNode> _getOptionsFromString(String optionsSource) {
  Map<String, YamlNode> options = <String, YamlNode>{};
  if (optionsSource == null) {
    return options;
  }

  YamlNode doc = loadYamlNode(optionsSource);

  // Empty options.
  if (doc is YamlScalar && doc.value == null) {
    return options;
  }
  if ((doc != null) && (doc is! YamlMap)) {
    throw new Exception(
        'Bad options file format (expected map, got ${doc.runtimeType})');
  }
  if (doc is YamlMap) {
    doc.nodes.forEach((k, YamlNode v) {
      var key;
      if (k is YamlScalar) {
        key = k.value;
      }
      if (key is! String) {
        throw new Exception(
            'Bad options file format (expected String scope key, '
            'got ${k.runtimeType})');
      }
      if (v != null && v is! YamlNode) {
        throw new Exception('Bad options file format (expected Node value, '
            'got ${v.runtimeType}: `${v.toString()}`)');
      }
      options[key] = v;
    });
  }
  return options;
}
