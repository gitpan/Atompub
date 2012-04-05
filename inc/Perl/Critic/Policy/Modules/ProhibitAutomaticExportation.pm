#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/ProhibitAutomaticExportation.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::ProhibitAutomaticExportation;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use List::MoreUtils qw(any);
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Symbols are exported by default};
Readonly::Scalar my $EXPL => q{Use '@EXPORT_OK' or '%EXPORT_TAGS' instead};  ## no critic (RequireInterpolation)

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_HIGH  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( _uses_exporter($doc) ) {
        if ( my $exp = _has_exports($doc) ) {
            return $self->violation( $DESC, $EXPL, $exp );
        }
    }
    return; #ok
}

#-----------------------------------------------------------------------------

sub _uses_exporter {
    my ($doc) = @_;

    my $includes_ref = $doc->find('PPI::Statement::Include');
    return if not $includes_ref;

    # This covers both C<use Exporter;> and C<use base 'Exporter';>
    return scalar grep { m/ \b Exporter \b/xms }  @{ $includes_ref };
}

#------------------

sub _has_exports {
    my ($doc) = @_;

    my $wanted =
        sub { _our_export(@_) or _vars_export(@_) or _package_export(@_) };

    return $doc->find_first( $wanted );
}

#------------------

sub _our_export {
    my (undef, $elem) = @_;

    $elem->isa('PPI::Statement::Variable') or return 0;
    $elem->type() eq 'our' or return 0;

    return any { $_ eq '@EXPORT' } $elem->variables(); ## no critic(RequireInterpolationOfMetachars)
}

#------------------

sub _vars_export {
    my (undef, $elem) = @_;

    $elem->isa('PPI::Statement::Include') or return 0;
    $elem->pragma() eq 'vars' or return 0;

    return $elem =~ m{ \@EXPORT \b }xms; #Crude, but usually works
}

#------------------

sub _package_export {
    my (undef, $elem) = @_;

    $elem->isa('PPI::Token::Symbol') or return 0;

    return $elem =~ m{ \A \@ \S+ ::EXPORT \z }xms;
    #TODO: ensure that it is in _this_ package!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 156

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
