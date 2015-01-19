use 5.006;
use strict;
use warnings;

package clone_methods;

# ABSTRACT: A collection of cloning methods for benchmarks

use Exporter 'import';

our @EXPORT_OK = qw(
  dclone_json_pp
  dclone_json_xs
  dclone_cpanel_json_xs
  dclone_pp
  dclone_pp_noblessed
);

## Original Implementation in CPAN::Meta::Converter
sub dclone_json_pp {
  my $ref = shift;
  no warnings 'once';
  no warnings 'redefine';
  require JSON::PP;
  local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
  my $json = JSON::PP->new->utf8->allow_blessed->convert_blessed;
  $json->decode( $json->encode($ref) );
}

sub dclone_json_xs {
  my $ref = shift;
  no warnings 'once';
  no warnings 'redefine';
  require JSON::XS;
  local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
  my $json = JSON::XS->new->utf8->allow_blessed->convert_blessed;
  $json->decode( $json->encode($ref) );
}

sub dclone_cpanel_json_xs {
  my $ref = shift;
  no warnings 'once';
  no warnings 'redefine';
  require Cpanel::JSON::XS;
  local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
  my $json = Cpanel::JSON::XS->new->utf8->allow_blessed->convert_blessed;
  $json->decode( $json->encode($ref) );
}

use Scalar::Util qw( blessed );

our $DCLONE_MAXDEPTH = 1024;
our $_CLONE_DEPTH;

sub dclone_pp {
  my ($ref) = @_;
  return $ref unless my $reftype = ref $ref;

  local $_CLONE_DEPTH =
    defined $_CLONE_DEPTH ? $_CLONE_DEPTH - 1 : $DCLONE_MAXDEPTH;
  die "Depth Limit $DCLONE_MAXDEPTH Exceeded" if $_CLONE_DEPTH == 0;

  return [ map { dclone_pp($_) } @{$ref} ] if 'ARRAY' eq $reftype;
  return { map { $_ => dclone_pp( $ref->{$_} ) } keys %{$ref} }
    if 'HASH' eq $reftype;

  if ( 'SCALAR' eq $reftype ) {
    my $new = dclone_pp( ${$ref} );
    return \$new;
  }
  if ( blessed $ref ) {
    no warnings 'once';
    no warnings 'redefine';
    local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
    return $ref->TO_JSON;
  }
  die "Don't understand how to clone $ref/$reftype";
}

sub dclone_pp_noblessed {
  my ($ref) = @_;
  return $ref unless my $reftype = ref $ref;

  local $_CLONE_DEPTH =
    defined $_CLONE_DEPTH ? $_CLONE_DEPTH - 1 : $DCLONE_MAXDEPTH;
  die "Depth Limit $DCLONE_MAXDEPTH Exceeded" if $_CLONE_DEPTH == 0;

  return [ map { dclone_pp($_) } @{$ref} ] if 'ARRAY' eq $reftype;
  return { map { $_ => dclone_pp( $ref->{$_} ) } keys %{$ref} }
    if 'HASH' eq $reftype;

  if ( 'SCALAR' eq $reftype ) {
    my $new = dclone_pp( ${$ref} );
    return \$new;
  }
  # Just stringify everything else
  return "$ref";
}


1;

=head1 Attempted Tech And why it doesn't work

=head2 Storable

=over 4

=item * Freeze must have either thaw or attach with it

=item * Thaw creates objects for you ( no execeptions )

=item * Attach demands you return objects ( no exceptions )

=item * But we need objects (ALL of them) to be coerced into simple data structures

=item * So we need version objects to be coerced to strings ....

=back
