#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitPackageVars.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitPackageVars;

use 5.006001;
use strict;
use warnings;

use Readonly;
use Carp qw( carp );

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Package variable declared or used};
Readonly::Scalar my $EXPL => [ 73, 75 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'packages',
            description     => 'The base set of packages to allow variables for.',
            default_string  => 'Data::Dumper File::Find FindBin Log::Log4perl',
            behavior        => 'string list',
        },
        {
            name            => 'add_packages',
            description     => 'The set of packages to allow variables for, in addition to those given in "packages".',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM            }
sub default_themes   { return qw(core pbp maintenance)    }
sub applies_to       { return qw(PPI::Token::Symbol
                                 PPI::Statement::Variable
                                 PPI::Statement::Include) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_all_packages} = {
        hashify keys %{ $self->{_packages} }, keys %{ $self->{_add_packages} }
    };

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->_is_package_var($elem) ||
         _is_our_var($elem)            ||
         _is_vars_pragma($elem) )
       {

        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # ok
}

#-----------------------------------------------------------------------------

sub _is_package_var {
    my $self = shift;
    my $elem = shift;
    return if !$elem->isa('PPI::Token::Symbol');
    my ($package, $name) = $elem =~ m{ \A [@\$%] (.*) :: (\w+) \z }xms;
    return if not defined $package;
    return if _all_upcase( $name );
    return if $self->{_all_packages}->{$package};
    return 1;
}

#-----------------------------------------------------------------------------

sub _is_our_var {
    my $elem = shift;
    return if not $elem->isa('PPI::Statement::Variable');
    return if $elem->type() ne 'our';
    return if _all_upcase( $elem->variables() );
    return 1;
}

#-----------------------------------------------------------------------------

sub _is_vars_pragma {
    my $elem = shift;
    return if !$elem->isa('PPI::Statement::Include');
    return if $elem->pragma() ne 'vars';

    # Older Perls don't support the C<our> keyword, so we try to let
    # people use the C<vars> pragma instead, but only if all the
    # variable names are uppercase.  Since there are lots of ways to
    # pass arguments to pragmas (e.g. "$foo" or qw($foo) ) we just use
    # a regex to match things that look like variables names.

    my @varnames = $elem =~ m{ [@\$%&] (\w+) }gxms;

    return if !@varnames;   # no valid variables specified
    return if _all_upcase( @varnames );
    return 1;
}

sub _all_upcase {  ##no critic(ArgUnpacking)
    return all { $_ eq uc $_ } @_;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 222

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
