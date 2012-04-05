#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/ProhibitBacktickOperators.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities is_in_void_context };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Use IPC::Open3 instead};
Readonly::Scalar my $DESC => q{Backtick operator used};

Readonly::Scalar my $VOID_EXPL => q{Assign result to a variable or use system() instead};
Readonly::Scalar my $VOID_DESC => q{Backtick operator used in void context};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name        => 'only_in_void_context',
            description => 'Allow backticks everywhere except in void contexts.',
            behavior    => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw(core maintenance)   }
sub applies_to       { return qw(PPI::Token::QuoteLike::Backtick
                                 PPI::Token::QuoteLike::Command ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->{_only_in_void_context} ) {
        return if not is_in_void_context( $elem );

        return $self->violation( $VOID_DESC, $VOID_EXPL, $elem );
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 144

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
