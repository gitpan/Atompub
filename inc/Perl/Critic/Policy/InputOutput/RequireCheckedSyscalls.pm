#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/InputOutput/RequireCheckedSyscalls.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireCheckedSyscalls;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities :classification
                            hashify is_perl_bareword };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Return value of flagged function ignored};
Readonly::Scalar my $EXPL => [208, 278];

Readonly::Array my @DEFAULT_FUNCTIONS => qw(
    open close print say
);
# I created this list by searching for "return" in perlfunc
Readonly::Array my @BUILTIN_FUNCTIONS => qw(
    accept bind binmode chdir chmod chown close closedir connect
    dbmclose dbmopen exec fcntl flock fork ioctl kill link listen
    mkdir msgctl msgget msgrcv msgsnd open opendir pipe print read
    readdir readline readlink readpipe recv rename rmdir say seek seekdir
    semctl semget semop send setpgrp setpriority setsockopt shmctl
    shmget shmread shutdown sleep socket socketpair symlink syscall
    sysopen sysread sysseek system syswrite tell telldir truncate
    umask unlink utime wait waitpid
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'functions',
            description     =>
                'The set of functions to require checking the return value of.',
            default_string  => join( $SPACE, @DEFAULT_FUNCTIONS ),
            behavior        => 'string list',
        },
        {
            name            => 'exclude_functions',
            description     =>
                'The set of functions to not require checking the return value of.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_LOWEST       }
sub default_themes       { return qw( core maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my @specified_functions = keys %{ $self->{_functions} };
    my @resulting_functions;

    foreach my $function (@specified_functions) {
        if ( $function eq ':defaults' ) {
            push @resulting_functions, @DEFAULT_FUNCTIONS;
        }
        elsif ( $function eq ':builtins' ) {
            push @resulting_functions, @BUILTIN_FUNCTIONS;
        }
        else {
            push @resulting_functions, $function;
        }
    }

    my %functions = hashify(@resulting_functions);

    foreach my $function ( keys %{ $self->{_exclude_functions} } ) {
        delete $functions{$function};
    }

    $self->{_functions} = \%functions;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->{_functions}->{':all'} ) {
        return if is_perl_bareword($elem);
        return if $self->{_exclude_functions}->{ $elem->content() };
    }
    elsif ( not $self->{_functions}->{ $elem->content() } ) {
        return;
    }

    return if not is_unchecked_call( $elem );

    return $self->violation( "$DESC - " . $elem->content(), $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

#line 221

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
