#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/NamingConventions/ProhibitAmbiguousNames.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 48 ];

Readonly::Scalar my $DEFAULT_FORBID =>
    'abstract bases close contract last left no record right second set';

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'forbid',
            description     => 'The variable names that are not to be allowed.',
            default_string  => $DEFAULT_FORBID,
            behavior        => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM         }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub
                                 PPI::Statement::Variable) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $elem->isa('PPI::Statement::Sub') ) {
        my @words = grep { $_->isa('PPI::Token::Word') } $elem->schildren();
        for my $word (@words) {

            # strip off any leading "Package::"
            my ($name) = $word =~ m/ (\w+) \z /xms;
            next if not defined $name; # should never happen, right?

            if ( exists $self->{_forbid}->{$name} ) {
                return $self->violation(
                    qq<Ambiguously named subroutine "$name">,
                    $EXPL,
                    $elem,
                );
            }
        }
        return;    # ok
    }

    # PPI::Statement::Variable

    # Accumulate them since there can be more than one violation
    # per variable statement
    my @violations;

    # TODO: false positive bug - this can erroneously catch the
    # assignment half of a variable statement

    my $symbols = $elem->find('PPI::Token::Symbol');
    if ($symbols) {   # this should always be true, right?
        for my $symbol ( @{$symbols} ) {

            # Strip off sigil and any leading "Package::"
            # Beware that punctuation vars may have no
            # alphanumeric characters.

            my ($name) = $symbol =~ m/ (\w+) \z /xms;
            next if ! defined $name;

            if ( exists $self->{_forbid}->{$name} ) {
                push
                    @violations,
                    $self->violation(
                        qq<Ambiguously named variable "$name">,
                        $EXPL,
                        $elem,
                    );
            }
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 178

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
