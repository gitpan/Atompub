#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitLvalueSubstr.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr;

use 5.006001;
use strict;
use warnings;
use Readonly;
use version 0.77 ();

use Perl::Critic::Utils qw{ :severities :classification :language };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Lvalue form of "substr" used};
Readonly::Scalar my $EXPL => [ 165 ];

Readonly::Scalar my $ASSIGNMENT_PRECEDENCE => precedence_of( q{=} );
Readonly::Scalar my $MINIMUM_PERL_VERSION => version->new( 5.005 );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance pbp ) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    # perl5005delta says that is when the fourth argument to substr()
    # was introduced, so ... (RT #59112)
    my $version = $document->highest_explicit_perl_version();
    return ! $version || $version >= $MINIMUM_PERL_VERSION;
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'substr';
    return if ! is_function_call($elem);

    my $sib = $elem;
    while ($sib = $sib->snext_sibling()) {
        if ( $sib->isa( 'PPI::Token::Operator' ) ) {
            my $rslt = $ASSIGNMENT_PRECEDENCE <=> precedence_of(
                $sib->content() );
            return if $rslt < 0;
            return $self->violation( $DESC, $EXPL, $sib ) if $rslt == 0;
        }
    }
    return; #ok!
}

1;

#-----------------------------------------------------------------------------

__END__

#line 124

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
