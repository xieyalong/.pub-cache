#!/bin/sh
# Regenerate the messages Dart files.
dart ../../bin/generate_from_arb.dart --generated-file-prefix=component_ \
component.dart component_translation_fr.arb
dart ../../bin/generate_from_arb.dart --generated-file-prefix=app_ \
main_app_test.dart app_translation_getfromthelocale.arb
