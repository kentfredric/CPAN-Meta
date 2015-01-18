#!/usr/bin/env perl

# ABSTRACT: Benchmark various dclone approaches.

use strict;
use warnings;

use Benchmark qw( :all :hireswallclock );
use FindBin;

use lib "$FindBin::Bin/lib";

use clone_methods qw(
  dclone_json_pp
  dclone_json_xs
  dclone_pp
);
use source_data qw( load_vobjects );

my $source_structure = load_vobjects("$FindBin::Bin/files/bench_source.json");

cmpthese(
  -2,
  {
    json_pp => sub {
      my $new = dclone_json_pp($source_structure);
      return;
    },
    json_xs => sub {
      my $new = dclone_json_xs($source_structure);
      return;
    },
    pp => sub {
      my $new = dclone_pp($source_structure);
      return;
    },
  },
);

