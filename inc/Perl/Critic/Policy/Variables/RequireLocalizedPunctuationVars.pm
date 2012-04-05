#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/RequireLocalizedPunctuationVars.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification $EMPTY hashify};
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $PACKAGE_RX => qr/::/xms;
Readonly::Hash   my %EXCEPTIONS => hashify(qw(
    $_
    $ARG
    @_
));
Readonly::Scalar my $DESC => q{Magic variable "%s" should be assigned as "local"};
Readonly::Scalar my $EXPL => [ 81, 82 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     =>
                q<Global variables to exclude from this policy.>,
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => [ qw< $_ $ARG @_ > ],
        },
    );
}

sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw(core pbp bugs)          }
sub applies_to           { return 'PPI::Token::Operator'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne q{=};

    my $destination = $elem->sprevious_sibling;
    return if !$destination;  # huh? assignment in void context??
    while ($destination->isa('PPI::Structure::Subscript')) {
        $destination = $destination->sprevious_sibling()
            or return;
    }

    if (my $var = $self->_is_non_local_magic_dest($destination)) {
       return $self->violation( sprintf( $DESC, $var ), $EXPL, $elem );
    }
    return;  # OK
}

sub _is_non_local_magic_dest {
    my ($self, $elem) = @_;

    # Quick exit if in good form
    my $modifier = $elem->sprevious_sibling;
    return
        if
                $modifier
            &&  $modifier->isa('PPI::Token::Word')
            &&  ($modifier eq 'local' || $modifier eq 'my');

    # Implementation note: Can't rely on PPI::Token::Magic,
    # unfortunately, because we need English too

    if ($elem->isa('PPI::Token::Symbol')) {
        return $self->_is_magic_var($elem) ? $elem : undef;
    }
    elsif (
            $elem->isa('PPI::Structure::List')
        or  $elem->isa('PPI::Statement::Expression')
    ) {
        for my $child ($elem->schildren) {
            my $var = $self->_is_non_local_magic_dest($child);
            return $var if $var;
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _is_magic_var {
    my ($self, $elem) = @_;

    my $variable_name = $elem->symbol();
    return if $self->{_allow}{$variable_name};
    return 1 if $elem->isa('PPI::Token::Magic'); # optimization(?), and
                                        # helps with PPI 1.118 carat
                                        # bug. This bug is gone as of
                                        # 1.208, which is required for
                                        # P::C 1.113. RT 65514
    return if not is_perl_global( $elem );

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 201

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
