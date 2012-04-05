#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/RequireLexicalLoopIterators.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::RequireLexicalLoopIterators;

use 5.006001;
use strict;
use warnings;
use Readonly;
use version ();

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Loop iterator is not lexical};
Readonly::Scalar my $EXPL => [ 108 ];

Readonly::Scalar my $MINIMUM_PERL_VERSION => version->new( 5.004 );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core pbp bugs)          }
sub applies_to           { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    # perl5004delta says that is when lexical iterators were introduced,
    # so ... (RT 67760)
    my $version = $document->highest_explicit_perl_version();
    return ! $version || $version >= $MINIMUM_PERL_VERSION;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # First child will be 'for' or 'foreach' keyword
    return if $elem->type() ne 'foreach';

    my $first_child = $elem->schild(0);
    return if not $first_child;
    my $start = $first_child->isa('PPI::Token::Label') ? 1 : 0;

    my $potential_scope = $elem->schild($start + 1);
    return if not $potential_scope;
    return if $potential_scope->isa('PPI::Structure::List');

    return if $potential_scope eq 'my';

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 167

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
