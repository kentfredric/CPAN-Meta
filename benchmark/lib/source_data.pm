use 5.006;
use strict;
use warnings;

package source_data;

# ABSTRACT: Tools for providing various source formats for testing

# AUTHORITY

use Exporter qw( import );
use Path::Tiny qw( path );

our @EXPORT_OK = qw( load_json load_vobjects );

sub load_json {
  my ($file) = @_;
  require JSON::PP;
  return JSON::PP->new->decode( path($file)->slurp_raw );
}

# Stuff in some version objects to make sure the object serializers are called
sub load_vobjects {
  my ($file)           = @_;
  my $source_structure = load_json($file);
  my $prereqs          = $source_structure->{prereqs};
  for my $phase ( keys %{$prereqs} ) {
    my $relations = $prereqs->{$phase};
    for my $relation ( keys %{$relations} ) {
      my $packages = $relations->{$relation};
      for my $package ( keys %{$packages} ) {
        $packages->{$package} = version->parse( $packages->{$package} );
      }
    }
  }
  return $source_structure;
}

1;

