#!/usr/bin/env perl

# ABSTRACT: Benchmark various dclone approaches.

use strict;
use warnings;

# This file is a more advanced versionj of benchmark_dclone.pl that emits a CSV
# file of some description with the timing data for each and every run.
#
# Its not stricly necessary to use this at all, but its useful if you
# want to produce a histogram of execution times instead of a single figure aggregate
# as it shows not just average times, but best times and worst times, and the distribution
# of times.
#
# This is useful because average times in computing are not entirely useful
# as they can easily be dropped significantly by system variations, thus, a "best time"
# is an indication of what performance you'll get when the CPU is giving it its full attention
# and that specific figure is probably more informative and reliable as a measure of raw improvement,
# ( even though you can't expect to see that performance all the time )
#
# As a proof by contrast: The "worst time" is completely useless information when you consider
# the computer could conceivably enter a year long slumber before it gets back for one sample,
# and that would greatly offset the average time ;) ( Though the relevance of this of course
# is dependent on your timing measurement method, of which none are perfect )
#
# You'd think we could test it differently by benchmarking in terms of numbers of ops,
# but I've learned that sometimes more OPs can take *less* time. Superscalar--
#
# Also, if you have any other fancy statistical methods you want to apply to the data,
# like in the case of DumbBench, instead of having to write an entire new benchmarking module
# just to aggregate the raw measurements in a different way, you can simply analyse the output CSV
# without having to re-run the expensive benchmark.

use Benchmark::CSV;
use FindBin;

use lib "$FindBin::Bin/lib";
use clone_methods
  qw( dclone_json_pp dclone_json_xs dclone_pp dclone_pp_noblessed );
use source_data qw( load_vobjects );

my $source_structure = load_vobjects("$FindBin::Bin/files/bench_source.json");

my $benchmark = Benchmark::CSV->new(
  ## comment this line if you have platform issues.
  ( $^O eq 'linux' ? ( timing_method => 'hires_cputime_thread' ) : () ),
  sample_size => 1,
  output      => "$FindBin::Bin/files/benchmark_dclone.csv",
);

$benchmark->add_instance(
  json_clone_pp => sub {
    my $new = dclone_json_pp($source_structure);
    return;
  },
);
$benchmark->add_instance(
  json_clone_xs => sub {
    my $new = dclone_json_xs($source_structure);
    return;
  },
);

$benchmark->add_instance(
  pp_clone => sub {
    my $new = dclone_pp($source_structure);
    return;
  },
);

$benchmark->add_instance(
  pp_clone_noblessed => sub {
    my $new = dclone_pp_noblessed($source_structure);
    return;
  },
);

*STDOUT->autoflush(1);
my $num_steps = 20;
print "[" . ( "_" x $num_steps ) . "]\r[";
for ( 1 .. $num_steps ) {
  $benchmark->run_iterations(100);
  print "#";
}
print "]\n";
