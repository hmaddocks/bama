#!/bin/zsh
# Flags spacing numbers off the 4 pt grid in AppKit layout code, and frames set by hand.
# Usage: tools/grid-lint.sh [folder]      (default: the app target, __APP_NAME__/)
# Allowed numbers: 0, 1, 2, and multiples of 4. Better: a token (Space.lg).
# DesignTokens.swift, where the tokens live, is skipped.
# Silence one line with a reason: // grid: ok <why>
set -euo pipefail
dir=${1:-${0:A:h:h}/__APP_NAME__}
find "$dir" -name '*.swift' -not -name 'DesignTokens.swift' -print0 | xargs -0 perl -ne '
  BEGIN { $count = 0 }
  if (!/grid: ok/) {
    my @bad;
    my $line = $_;
    while ($line =~ /(?:\b(?:constant|equalToConstant|greaterThanOrEqualToConstant|lessThanOrEqualToConstant)\s*:\s*|\b(?:spacing|columnSpacing|rowSpacing)\s*[:=]\s*)(-?\d+(?:\.\d+)?)\b/g) {
      my $n = abs($1);
      push @bad, $1 unless $n == 0 || $n == 1 || $n == 2 || ($n == int($n) && $n % 4 == 0);
    }
    if ($line =~ /NSEdgeInsets\(([^)]*)\)/) {
      my $args = $1;
      while ($args =~ /:\s*(-?\d+(?:\.\d+)?)\b/g) {
        my $n = abs($1);
        push @bad, $1 unless $n == 0 || $n == 1 || $n == 2 || ($n == int($n) && $n % 4 == 0);
      }
    }
    push @bad, "frame set by hand" if $line =~ /setFrameOrigin\(|\bframe\.origin\s*=/;
    if (@bad) { $count++; my $l = $line; $l =~ s/^\s+//; print "$ARGV:$.: off grid (", join(", ", @bad), "): $l"; }
  }
  close ARGV if eof;
  END { if ($count) { print "FAIL grid-lint: $count lines off the grid\n"; exit 1 } print "PASS grid-lint\n" }'
