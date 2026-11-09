#!/usr/bin/env bash
# abla-ui's self-checks: every tests/*_test.ab, built natively and run.
#   scripts/test.sh
#   ABLAC=/path/to/bin/ablac scripts/test.sh    another compiler (default: ablac on PATH)
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ablac=${ABLAC:-$(command -v ablac || echo "$HOME/.abla/bin/ablac")}
cd "$root"
mkdir -p build/checks
for check in tests/*_test.ab; do
	name=$(basename "${check%.ab}")
	"$ablac" build "$check" -o "build/checks/$name" --fast --no-cache
	"build/checks/$name" > "build/checks/$name.log" 2>&1 || { cat "build/checks/$name.log"; exit 1; }
	tail -n 1 "build/checks/$name.log"
done
echo "abla-ui: all checks passed"
