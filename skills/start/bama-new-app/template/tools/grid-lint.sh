#!/bin/zsh
# Flags spacing numbers off the 4 pt grid in AppKit and UIKit layout code, and frames set by hand.
# Usage: tools/grid-lint.sh [folder...]   (default: the app targets, __APP_NAME__/ and __APP_NAME__iOS/)
# Allowed numbers: 0, 1, 2, and multiples of 4. Better: a token (Space.lg).
# DesignTokens.swift, where the tokens live, is skipped.
# Silence one line with a reason: // grid: ok <why>
set -euo pipefail
root=${0:A:h:h}
if (( $# )); then
  dirs=("$@")
else
  dirs=()
  for d in "$root/__APP_NAME__" "$root/__APP_NAME__iOS"; do [[ -d "$d" ]] && dirs+=("$d"); done
fi
find "${dirs[@]}" -name '*.swift' -not -name 'DesignTokens.swift' -print0 | xargs -0 perl -ne '
  BEGIN { $count = 0 }
  sub off { my $n = abs($_[0]); return !($n == 0 || $n == 1 || $n == 2 || ($n == int($n) && $n % 4 == 0)); }
  if (!/grid: ok/) {
    my @bad;
    my $line = $_;
    while ($line =~ /(?:\b(?:constant|equalToConstant|greaterThanOrEqualToConstant|lessThanOrEqualToConstant)\s*:\s*|\b(?:spacing|columnSpacing|rowSpacing|interGroupSpacing|interItemSpacing)\s*[:=]\s*|\bsetCustomSpacing\(\s*)(-?\d+(?:\.\d+)?)\b/g) {
      push @bad, $1 if off($1);
    }
    while ($line =~ /(?:NSEdgeInsets|UIEdgeInsets|NSDirectionalEdgeInsets)\(([^)]*)\)/g) {
      my $args = $1;
      while ($args =~ /:\s*(-?\d+(?:\.\d+)?)\b/g) { push @bad, $1 if off($1); }
    }
    push @bad, "frame set by hand" if $line =~ /setFrameOrigin\(|\bframe\.origin\s*=/;
    if (@bad) { $count++; my $l = $line; $l =~ s/^\s+//; print "$ARGV:$.: off grid (", join(", ", @bad), "): $l"; }
  }
  close ARGV if eof;
  END { if ($count) { print "FAIL grid-lint: $count lines off the grid\n"; exit 1 } print "PASS grid-lint\n" }'
