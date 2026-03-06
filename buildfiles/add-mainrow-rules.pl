#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# Usage: perl add-mainrow-rules.pl in.tex out.tex
my ($in, $out) = @ARGV;
die "Usage: $0 in.tex out.tex\n" unless defined $in && defined $out;

open(my $fh, '<:raw', $in)  or die "Cannot open $in: $!\n";
my @lines = <$fh>;
close($fh);

my $in_table = 0;
my $env = '';

my %table_env = map { $_ => 1 } qw(longtable tabular tabularx);

sub begins_env {
  my ($line) = @_;
  return $1 if $line =~ /\\begin\{([^\}]+)\}/;
  return '';
}

sub ends_env {
  my ($line) = @_;
  return $1 if $line =~ /\\end\{([^\}]+)\}/;
  return '';
}

my @out_lines;
for (my $i = 0; $i < @lines; $i++) {
  my $line = $lines[$i];

  my $beg = begins_env($line);
  if ($beg && $table_env{$beg}) {
    $in_table = 1;
    $env = $beg;
  }

  push @out_lines, $line;

  # Insert hairline after row endings inside tables
  if ($in_table && $line =~ /\\\\\s*$/) {
    # Zeile danach prüfen
    my $j = $i + 1;
    while ($j < @lines && $lines[$j] =~ /^\s*$/) { $j++; }
    my $next = ($j < @lines) ? $lines[$j] : '';
    # Nur EIN Hairline einfügen, wenn die nächste Zeile KEINE Regel ist
    next if $next =~ /\\(bottomrule|midrule|toprule|end\{longtable\}|end\{tabularx\}|end\{tabular\})/;
    push @out_lines, "\\MFourBHairline\n";
  }

  my $end = ends_env($line);
  if ($end && $table_env{$end}) {
    $in_table = 0;
    $env = '';
  }
}

open(my $oh, '>:raw', $out) or die "Cannot write $out: $!\n";
print $oh @out_lines;
close($oh);

exit 0;
