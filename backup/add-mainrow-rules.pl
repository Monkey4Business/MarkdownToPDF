#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# Usage: perl add-mainrow-rules.pl in.tex out.patched.tex
my ($in, $out) = @ARGV;
if (!$in || !$out) {
  die "Usage: perl add-mainrow-rules.pl in.tex out.tex\n";
}

open(my $fh,  "<:encoding(UTF-8)", $in)  or die "Cannot open $in: $!";
open(my $oh,  ">:encoding(UTF-8)", $out) or die "Cannot open $out: $!";

my $in_table = 0;
my $seen_mainrow = 0;

while (my $line = <$fh>) {

  # Enter / leave table environments (Pandoc uses longtable a lot)
  if ($line =~ /\\begin\{longtable\}/ || $line =~ /\\begin\{tabularx\}/ || $line =~ /\\begin\{tabular\}/) {
    $in_table = 1;
    $seen_mainrow = 0;
  }
  if ($line =~ /\\end\{longtable\}/ || $line =~ /\\end\{tabularx\}/ || $line =~ /\\end\{tabular\}/) {
    $in_table = 0;
    $seen_mainrow = 0;
  }

  # 1) Monkey4Business must NEVER break across lines:
  # Wrap it into \mbox{...} everywhere (but don't double-wrap).
  # Note: filenames in your project are lowercase (monkey4business_...), so no collision.
  $line =~ s/(?<!\\mbox\{)Monkey4Business/\\mbox{Monkey4Business}/g;

  # 2) Insert subtle hairline BEFORE each "main row" in your segmentation-style tables.
  # Main rows are those where the FIRST column contains content (often \textbf{...}).
  # Subsequent subrows usually start with just '& ...'
  if ($in_table) {
    if ($line =~ /^\s*\\textbf\{[^}]+\}\s*&/ || $line =~ /^\s*[A-Za-zÄÖÜäöüß].*?\s*&/) {
      if ($seen_mainrow) {
        print $oh "\\m4bhairline\n";
      }
      $seen_mainrow = 1;
    }
  }

  print $oh $line;
}

close $fh;
close $oh;