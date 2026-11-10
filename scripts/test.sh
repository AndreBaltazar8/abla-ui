#!/usr/bin/env bash
# abla-ui's self-checks: every tests/*_test.ab, built natively and run, and every
# tests/errors/*.ab, which must fail to build with the message its `// expect:` line names.
#   scripts/test.sh
#   ABLAC=/path/to/bin/ablac scripts/test.sh    another compiler (default: ablac on PATH)
# The tag syntax (src/dsl.ab) needs ablac 0.2.53 or newer; with an older compiler its checks
# are skipped (the rest of abla-ui builds with 0.2.48 and newer).
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ablac=${ABLAC:-$(command -v ablac || echo "$HOME/.abla/bin/ablac")}
cd "$root"
version=$("$ablac" --version | awk '{print $2}')
tags=1
if [ "$(printf '%s\n0.2.53\n' "$version" | sort -V | head -1)" != 0.2.53 ]; then
	tags=0
	echo "ablac $version: the tag syntax needs 0.2.53 or newer; its checks are skipped"
fi
mkdir -p build/checks
for check in tests/*_test.ab; do
	if [ $tags = 0 ] && grep -q 'src/dsl.ab' "$check"; then continue; fi
	name=$(basename "${check%.ab}")
	"$ablac" build "$check" -o "build/checks/$name" --fast --no-cache
	"build/checks/$name" > "build/checks/$name.log" 2>&1 || { cat "build/checks/$name.log"; exit 1; }
	tail -n 1 "build/checks/$name.log"
done
if [ $tags = 1 ]; then
	failed=0
	count=0
	for case in tests/errors/*.ab; do
		want=$(sed -n 's|^// expect: ||p' "$case" | head -1)
		name=$(basename "${case%.ab}")
		if "$ablac" build "$case" -o "build/checks/error-$name" --fast --no-cache > "build/checks/error-$name.log" 2>&1; then
			echo "FAIL $case built, but should have failed with: $want"
			failed=1
		elif ! grep -qF "$want" "build/checks/error-$name.log"; then
			echo "FAIL $case failed without: $want"
			head -5 "build/checks/error-$name.log"
			failed=1
		fi
		count=$((count + 1))
	done
	[ $failed = 0 ] || exit 1
	echo "errors: $count compile errors as expected"
fi
echo "abla-ui: all checks passed"
