#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Subroutines/ProtectPrivateSubs.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProtectPrivateSubs;

use 5.006001;

use strict;
use warnings;

use English qw< $EVAL_ERROR -no_match_vars >;
use Readonly;

use Perl::Critic::Utils qw<
    :severities $EMPTY is_function_call is_method_call
>;
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Private subroutine/method used>;
Readonly::Scalar my $EXPL => q<Use published APIs>;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'private_name_regex',
            description     => 'Pattern that determines what a private subroutine is.',
            default_string  => '\b_\w+\b',  ## no critic (RequireInterpolationOfMetachars)
            behavior        => 'string',
            parser          => \& _parse_private_name_regex,
        },
        {
            name            => 'allow',
            description     =>
                q<Subroutines matching the private name regex to allow under this policy.>,
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => [ qw<
                POSIX::_PC_CHOWN_RESTRICTED
                POSIX::_PC_LINK_MAX
                POSIX::_PC_MAX_CANON
                POSIX::_PC_MAX_INPUT
                POSIX::_PC_NAME_MAX
                POSIX::_PC_NO_TRUNC
                POSIX::_PC_PATH_MAX
                POSIX::_PC_PIPE_BUF
                POSIX::_PC_VDISABLE
                POSIX::_POSIX_ARG_MAX
                POSIX::_POSIX_CHILD_MAX
                POSIX::_POSIX_CHOWN_RESTRICTED
                POSIX::_POSIX_JOB_CONTROL
                POSIX::_POSIX_LINK_MAX
                POSIX::_POSIX_MAX_CANON
                POSIX::_POSIX_MAX_INPUT
                POSIX::_POSIX_NAME_MAX
                POSIX::_POSIX_NGROUPS_MAX
                POSIX::_POSIX_NO_TRUNC
                POSIX::_POSIX_OPEN_MAX
                POSIX::_POSIX_PATH_MAX
                POSIX::_POSIX_PIPE_BUF
                POSIX::_POSIX_SAVED_IDS
                POSIX::_POSIX_SSIZE_MAX
                POSIX::_POSIX_STREAM_MAX
                POSIX::_POSIX_TZNAME_MAX
                POSIX::_POSIX_VDISABLE
                POSIX::_POSIX_VERSION
                POSIX::_SC_ARG_MAX
                POSIX::_SC_CHILD_MAX
                POSIX::_SC_CLK_TCK
                POSIX::_SC_JOB_CONTROL
                POSIX::_SC_NGROUPS_MAX
                POSIX::_SC_OPEN_MAX
                POSIX::_SC_PAGESIZE
                POSIX::_SC_SAVED_IDS
                POSIX::_SC_STREAM_MAX
                POSIX::_SC_TZNAME_MAX
                POSIX::_SC_VERSION
                POSIX::_exit
            > ],
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub _parse_private_name_regex {
    my ($self, $parameter, $config_string) = @_;

    defined $config_string
        or $config_string = $parameter->get_default_string();

    my $regex;
    eval { $regex = qr/$config_string/; 1 } ## no critic (RegularExpressions)
        or $self->throw_parameter_value_exception(
            'private_name_regex',
            $config_string,
            undef,
            "is not a valid regular expression: $EVAL_ERROR",
        );

    $self->__set_parameter_value($parameter, $regex);

    return;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( my $prior = $elem->sprevious_sibling() ) {
        my $prior_name = $prior->content();
        return if $prior_name eq 'package';
        return if $prior_name eq 'require';
        return if $prior_name eq 'use';
    }

    if (
            $self->_is_other_pkg_private_function($elem)
        or  $self->_is_other_pkg_private_method($elem)
    ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # ok!
}

sub _is_other_pkg_private_function {
    my ( $self, $elem ) = @_;

    return if ! is_function_call($elem) && ! is_method_call($elem);

    my $private_name_regex = $self->{_private_name_regex};
    my $content = $elem->content();
    return
            $content =~ m< \w+::$private_name_regex \z >xms
        &&  $content !~ m< \A SUPER::$private_name_regex \z >xms
        &&  ! $self->{_allow}{$content};
}

sub _is_other_pkg_private_method {
    my ( $self, $elem ) = @_;

    my $private_name_regex = $self->{_private_name_regex};
    my $content = $elem->content();

    # look for structures like "Some::Package->_foo()"
    return if $content !~ m< \A $private_name_regex \z >xms;
    my $operator = $elem->sprevious_sibling() or return;
    return if $operator->content() ne q[->];

    my $package = $operator->sprevious_sibling() or return;
    return if not $package->isa('PPI::Token::Word');

    # sometimes the previous sib is a keyword, as in:
    # shift->_private_method();  This is typically used as
    # shorthand for "my $self=shift; $self->_private_method()"
    return if $package eq 'shift' or $package eq '__PACKAGE__';

    # Maybe the user wanted to exempt this explicitly.
    return if $self->{_allow}{"${package}::$content"};

    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 266

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
