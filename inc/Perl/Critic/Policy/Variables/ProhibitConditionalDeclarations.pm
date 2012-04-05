#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitConditionalDeclarations.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Variable declared in conditional statement};
Readonly::Scalar my $EXPL => q{Declare variables outside of the condition};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->type() eq 'local';

    if ( $elem->find(\&_is_conditional) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

my @conditionals = qw( if while foreach for until unless );
my %conditionals = hashify( @conditionals );

sub _is_conditional {
    my (undef, $elem) = @_;

    return if !$conditionals{$elem};
    return if ! $elem->isa('PPI::Token::Word');
    return if is_hash_key($elem);
    return if is_method_call($elem);

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 108

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
