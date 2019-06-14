// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:markdown/markdown.dart';

import 'since.dart';

/// Generates lint rule docs for publishing to https://dart-lang.github.io/
void main([List<String> args]) async {
  var parser = new ArgParser(allowTrailingOptions: true)
    ..addOption('out', abbr: 'o', help: 'Specifies output directory.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'];
  await generateDocs(outDir);
}

const ruleFootMatter = '''
In addition, rules can be further distinguished by *maturity*.  Unqualified
rules are considered stable, while others may be marked **experimental**
to indicate that they are under review.  Lints that are marked as **deprecated**
should not be used and are subject to removal in future Linter releases.

Rules can be selectively enabled in the analyzer using
[analysis options](https://pub.dartlang.org/packages/analyzer)
or through an
[analysis options file](https://www.dartlang.org/guides/language/analysis-options#the-analysis-options-file). 

* **An auto-generated list enabling all options is provided [here](options/options.html).** 

As some lints may contradict each other, only a subset of these will be
enabled in practice, but this list should provide a
convenient jumping-off point.

These rules are under active development.  Feedback is
[welcome](https://github.com/dart-lang/linter/issues)!
''';

const ruleLeadMatter = 'Rules are organized into familiar rule groups.';

final flutterRules = <String>[];
final pedanticRules = <String>[];

/// Sorted list of contributed lint rules.
final List<LintRule> rules =
    new List<LintRule>.from(Registry.ruleRegistry, growable: false)..sort();

String get enumerateErrorRules => rules
    .where((r) => r.group == Group.errors)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

String get enumerateGroups => Group.builtin
    .map((Group g) =>
        '<li><strong>${g.name}</strong> - ${markdownToHtml(g.description)}</li>')
    .join('\n');

String get enumeratePubRules => rules
    .where((r) => r.group == Group.pub)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

String get enumerateStyleRules => rules
    .where((r) => r.group == Group.style)
    .map((r) => '${toDescription(r)}')
    .join('\n\n');

Future<void> fetchBadgeInfo() async {
  var pedantic = await fetchConfig(
      'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.yaml');
  for (var ruleConfig in pedantic.ruleConfigs) {
    pedanticRules.add(ruleConfig.name);
  }

  var flutter = await fetchConfig(
      'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/analysis_options_user.yaml');
  for (var ruleConfig in flutter.ruleConfigs) {
    flutterRules.add(ruleConfig.name);
  }
}

Future<void> fetchSinceInfo() async {
  sinceInfo = await sinceMap;
}

Future<LintConfig> fetchConfig(String url) async {
  var client = new http.Client();
  var req = await client.get(url);
  return processAnalysisOptionsFile(req.body);
}

Map<String, SinceInfo> sinceInfo;

Future<void> generateDocs(String dir) async {
  String outDir = dir;
  if (outDir != null) {
    Directory d = new Directory(outDir);
    if (!d.existsSync()) {
      print("Directory '${d.path}' does not exist");
      return;
    }
    if (!new File('$outDir/options').existsSync()) {
      Directory lintsChildDir = new Directory('$outDir/lints');
      if (lintsChildDir.existsSync()) {
        outDir = lintsChildDir.path;
      }
    }
  }

  registerLintRules();

  // Generate lint count badge.
  await new CountBadger(Registry.ruleRegistry).generate(outDir);

  // Fetch info for lint group/style badge generation.
  await fetchBadgeInfo();

  // Fetch since info.
  await fetchSinceInfo();

  // Generate index.
  new Indexer(Registry.ruleRegistry).generate(outDir);

  // Generate rule files.
  rules.forEach((l) => new Generator(l).generate(outDir));

  // Generate options samples.
  new OptionsSample(rules).generate(outDir);
}

String getBadges(String rule) {
  var sb = new StringBuffer();
  if (flutterRules.contains(rule)) {
    sb.write(
        '<a href="https://github.com/flutter/flutter/blob/master/packages/flutter/lib/analysis_options_user.yaml"><!--suppress HtmlUnknownTarget --><img alt="flutter" src="style-flutter.svg"></a> ');
  }
  if (pedanticRules.contains(rule)) {
    sb.write(
        '<a href="https://github.com/dart-lang/pedantic/#enabled-lints"><!--suppress HtmlUnknownTarget --><img alt="pedantic" src="style-pedantic.svg"></a>');
  }
  return sb.toString();
}

void printUsage(ArgParser parser, [String error]) {
  var message = 'Generates lint docs.';
  if (error != null) {
    message = error;
  }

  stdout.write('''$message
Usage: doc
${parser.usage}
''');
}

String qualify(LintRule r) => r.name.toString() + describeMaturity(r);

String describeMaturity(LintRule r) =>
    r.maturity == Maturity.stable ? '' : ' (${r.maturity.name})';

String toDescription(LintRule r) =>
    '<!--suppress HtmlUnknownTarget --><strong><a href = "${r.name}.html">${qualify(r)}</a></strong><br/> ${getBadges(r.name)} ${markdownToHtml(r.description)}';

class CountBadger {
  Iterable<LintRule> rules;
  CountBadger(this.rules);

  generate(String dirPath) async {
    var lintCount = rules.length;

    var client = new http.Client();
    var req = await client.get(
        Uri.parse('https://img.shields.io/badge/lints-$lintCount-blue.svg'));
    var bytes = req.bodyBytes;
    await new File('$dirPath/count-badge.svg').writeAsBytes(bytes);
  }
}

class Generator {
  LintRule rule;
  Generator(this.rule);

  String get details => rule.details ?? '';
  String get group => rule.group.name;
  String get humanReadableName => rule.name;
  String get maturity => rule.maturity.name;
  String get maturityString {
    switch (rule.maturity) {
      case Maturity.deprecated:
        return '<span style="color:orangered;font-weight:bold;" >$maturity</span>';
      case Maturity.experimental:
        return '<span style="color:hotpink;font-weight:bold;" >$maturity</span>';
      default:
        return maturity;
    }
  }

  String get name => rule.name;

  String get since {
    var info = sinceInfo[name];
    // todo (pq): consider a footnote explaining that since info is static and "unreleased" tags may be stale.
    return 'Dart SDK: >= ${info.sinceDartSdk ?? "<unreleased>"} • <small>(Linter v${info.sinceLinter})</small>';
  }

  generate([String filePath]) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/$name.html';
      print('Writing to $outPath');
      new File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!doctype html>
<html>
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="chrome=1">
      <title>$name</title>
      <link rel="stylesheet" href="../stylesheets/styles.css">
      <link rel="stylesheet" href="../stylesheets/pygment_trac.css">
      <script src="../javascripts/scale.fix.js"></script>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
   </head>
   <body>
      <div class="wrapper">
         <header>
            <h1>$humanReadableName</h1>
            <p>Group: $group</p>
            <p>Maturity: $maturityString</p>
            <p style="padding-bottom: 10px;">$since</p>
            ${getBadges(name)}
            <p class="view"><a href="https://github.com/dart-lang/linter">View the Project on GitHub <small>dart-lang/linter</small></a></p>
            <ul>
               <li><a href="https://www.dartlang.org/articles/style-guide/">See the <strong>Style Guide</strong></a></li>
               <li><a href="https://dart-lang.github.io/linter/lints/">List of <strong>Lint Rules</strong></a></li>
            </ul>
         </header>
         <section>

            ${markdownToHtml(details)}

         </section>
      </div>
      <footer>
         <p>Project maintained by <a href="https://github.com/dart-lang">dart-lang</a></p>
         <p>Hosted on GitHub Pages &mdash; Theme by <a href="https://github.com/orderedlist">orderedlist</a></p>
      </footer>
      <!--[if !IE]><script>fixScale(document);</script><![endif]-->
   </body>
</html>
''';
}

class Indexer {
  Iterable<LintRule> rules;
  Indexer(this.rules);

  generate(String filePath) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/index.html';
      print('Writing to $outPath');
      new File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String _generate() => '''
<!doctype html>
<html>
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="chrome=1">
      <title>Linter for Dart</title>
      <link rel="stylesheet" href="../stylesheets/styles.css">
      <link rel="stylesheet" href="../stylesheets/pygment_trac.css">
      <script src="javascripts/scale.fix.js"></script>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
   </head>
   <body>
      <div class="wrapper">
         <header>
            <a href="https://dart-lang.github.io/linter/">
               <h1>Linter for Dart</h1>
            </a>
            <p>Lint Rules</p>
            <p class="view"><a href="https://github.com/dart-lang/linter">View the Project on GitHub <small>dartlang/linter</small></a></p>
            <ul>
               <li><a href="https://github.com/dart-lang/linter">View On <strong>GitHub</strong></a></li>
            </ul>
         </header>
         <section>

            <h1 id="supported-lints">Supported Lint Rules</h1>
            <p>
               This list is auto-generated from our sources.
            </p>
            <p>
               ${markdownToHtml(ruleLeadMatter)}
            </p>
            <ul>
               <p>
                  $enumerateGroups
               </p>
            </ul>
            <p>
               ${markdownToHtml(ruleFootMatter)}
            </p>

            <h2 id="styleguide-rules">Error Rules</h2>

               $enumerateErrorRules

            <h2 id="styleguide-rules">Style Rules</h2>

               $enumerateStyleRules

            <h2 id="styleguide-rules">Pub Rules</h2>

               $enumeratePubRules

         </section>
      </div>
      <footer>
         <p>Project maintained by <a href="https://github.com/google">google</a></p>
         <p>Hosted on GitHub Pages &mdash; Theme by <a href="https://github.com/orderedlist">orderedlist</a></p>
      </footer>
      <!--[if !IE]><script>fixScale(document);</script><![endif]-->
      <script type="text/javascript">
         var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
         document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
         try {
           var pageTracker = _gat._getTracker("UA-34425814-2");
         pageTracker._trackPageview();
         } catch(err) {}
      </script>
   </body>
</html>
''';
}

class OptionsSample {
  Iterable<LintRule> rules;
  OptionsSample(this.rules);

  generate(String filePath) {
    var generated = _generate();
    if (filePath != null) {
      var outPath = '$filePath/options/options.html';
      print('Writing to $outPath');
      new File(outPath).writeAsStringSync(generated);
    } else {
      print(generated);
    }
  }

  String generateOptions() {
    StringBuffer sb = new StringBuffer('''
```
linter:
  rules:
''');

    var sortedRules = rules
        .where((r) => r.maturity != Maturity.deprecated)
        .map((r) => r.name)
        .toList()
          ..sort();
    for (String rule in sortedRules) {
      sb.write('    - $rule\n');
    }
    sb.write('```');

    return sb.toString();
  }

  String _generate() => '''
<!doctype html>
<html>
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="chrome=1">
      <title>Analysis Options</title>
      <link rel="stylesheet" href="../../stylesheets/styles.css">
      <link rel="stylesheet" href="../../stylesheets/pygment_trac.css">
      <script src="../../javascripts/scale.fix.js"></script>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
   </head>
  <body>
      <div class="wrapper">
         <header>
            <a href="https://dart-lang.github.io/linter/">
               <h1>Dart Lint</h1>
            </a>
            <p>Analysis Options</p>
            <p class="view"><a href="https://github.com/dart-lang/linter">View the Project on GitHub <small>dart-lang/linter</small></a></p>
            <ul>
              <li><a href="https://dart-lang.github.io/linter/lints/">List of <strong>Lint Rules</strong></a></li>
              <li><a href="https://github.com/dart-lang/linter">View On <strong>GitHub</strong></a></li>
            </ul>
         </header>
         <section>

            <h1 id="analysis-options">Analysis Options</h1>
            <p>
               Auto-generated options enabling all lints.
               Add these to your
               <a href="https://www.dartlang.org/guides/language/analysis-options#the-analysis-options-file">analysis_options.yaml file</a>
               and tailor to fit!
            </p>

${markdownToHtml(generateOptions())}

         </section>
      </div>
      <footer>
         <p>Project maintained by <a href="https://github.com/google">google</a></p>
         <p>Hosted on GitHub Pages &mdash; Theme by <a href="https://github.com/orderedlist">orderedlist</a></p>
      </footer>
      <!--[if !IE]><script>fixScale(document);</script><![endif]-->
      <script type="text/javascript">
         var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
         document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
         try {
           var pageTracker = _gat._getTracker("UA-34425814-2");
         pageTracker._trackPageview();
         } catch(err) {}
      </script>
   </body>
</html>
''';
}
