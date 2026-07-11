#!/usr/bin/env bash
# Regenerates test/coverage_helper_test.dart. Run after adding a logic file.
# See the header of the generated file for why it exists.
set -euo pipefail
cd "$(dirname "$0")/.."
{
  sed -n '1,/^\/\/ ignore_for_file/p' test/coverage_helper_test.dart
  find lib -name "*.dart" \
    ! -name "*.g.dart" ! -name "*.gr.dart" ! -name "*.freezed.dart" \
    ! -path "*/ui/*" \
    | sed "s|^lib/|import 'package:openbaptisthymnal/|; s|\$|';|" | sort
  echo
  echo "void main() {}"
} > test/coverage_helper_test.dart.tmp
mv test/coverage_helper_test.dart.tmp test/coverage_helper_test.dart
echo "regenerated test/coverage_helper_test.dart"
