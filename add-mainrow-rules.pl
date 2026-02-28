#!/usr/bin/perl
use strict;
use warnings;

my $in_longtable = 0;
my $after_head   = 0;
my $seen_first_main = 0;

while (my $line = <STDIN>) {

  if ($line =~ /\\begin\{longtable\}/) {
    $in_longtable = 1;
    $after_head = 0;
    $seen_first_main = 0;
  }

  if ($in_longtable && $line =~ /\\endhead/) {
    $after_head = 1;
  }

  # "Main row" heuristic for your Pandoc output:
  # - starts with \textbf{   (main label in col 1)
  # - contains an &         (real table row)
  # - continuation rows start with &
  if ($in_longtable && $after_head) {
    if ($line =~ /^\\textbf\{.*\}\s*&/ ) {
      if ($seen_first_main) {
        # thin hairline between main rows (booktabs)
        print "\\specialrule{0.3pt}{2pt}{2pt}\n";
      } else {
        $seen_first_main = 1;
      }
    }
  }

  print $line;

  if ($line =~ /\\end\{longtable\}/) {
    $in_longtable = 0;
    $after_head = 0;
    $seen_first_main = 0;
  }
}