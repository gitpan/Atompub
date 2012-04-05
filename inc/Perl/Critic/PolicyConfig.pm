#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/PolicyConfig.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::PolicyConfig;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.117';

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue;
use Perl::Critic::Exception::Configuration::Option::Policy::ExtraParameter;
use Perl::Critic::Utils qw< :booleans :characters severity_to_number >;
use Perl::Critic::Utils::Constants qw< :profile_strictness >;

#-----------------------------------------------------------------------------

Readonly::Scalar my $NON_PUBLIC_DATA    => '_non_public_data';
Readonly::Scalar my $NO_LIMIT           => 'no_limit';

#-----------------------------------------------------------------------------

sub new {
    my ($class, $policy_short_name, $specification) = @_;

    my %self = $specification ? %{ $specification } : ();
    my %non_public_data;

    $non_public_data{_policy_short_name} = $policy_short_name;
    $non_public_data{_profile_strictness} =
        $self{$NON_PUBLIC_DATA}{_profile_strictness};

    foreach my $standard_parameter (
        qw< maximum_violations_per_document severity set_themes add_themes >
    ) {
        if ( exists $self{$standard_parameter} ) {
            $non_public_data{"_$standard_parameter"} =
                delete $self{$standard_parameter};
        }
    }

    $self{$NON_PUBLIC_DATA} = \%non_public_data;


    return bless \%self, $class;
}

#-----------------------------------------------------------------------------

sub _get_non_public_data {
    my $self = shift;

    return $self->{$NON_PUBLIC_DATA};
}

#-----------------------------------------------------------------------------

sub get_policy_short_name {
    my $self = shift;

    return $self->_get_non_public_data()->{_policy_short_name};
}

#-----------------------------------------------------------------------------

sub get_set_themes {
    my ($self) = @_;

    return $self->_get_non_public_data()->{_set_themes};
}

#-----------------------------------------------------------------------------

sub get_add_themes {
    my ($self) = @_;

    return $self->_get_non_public_data()->{_add_themes};
}

#-----------------------------------------------------------------------------

sub get_severity {
    my ($self) = @_;

    return $self->_get_non_public_data()->{_severity};
}

#-----------------------------------------------------------------------------

sub is_maximum_violations_per_document_unlimited {
    my ($self) = @_;

    my $maximum_violations = $self->get_maximum_violations_per_document();
    if (
            not defined $maximum_violations
        or  $maximum_violations eq $EMPTY
        or  $maximum_violations =~ m<\A $NO_LIMIT \z>xmsio
    ) {
        return $TRUE;
    }

    return $FALSE;
}

#-----------------------------------------------------------------------------

sub get_maximum_violations_per_document {
    my ($self) = @_;

    return $self->_get_non_public_data()->{_maximum_violations_per_document};
}

#-----------------------------------------------------------------------------

sub get {
    my ($self, $parameter) = @_;

    return if $parameter eq $NON_PUBLIC_DATA;

    return $self->{$parameter};
}

#-----------------------------------------------------------------------------

sub remove {
    my ($self, $parameter) = @_;

    return if $parameter eq $NON_PUBLIC_DATA;

    delete $self->{$parameter};

    return;
}

#-----------------------------------------------------------------------------

sub is_empty {
    my ($self) = @_;

    return 1 >= keys %{$self};
}

#-----------------------------------------------------------------------------

sub get_parameter_names {
    my ($self) = @_;

    return grep { $_ ne $NON_PUBLIC_DATA } keys %{$self};
}

#-----------------------------------------------------------------------------

sub handle_extra_parameters {
    my ($self, $policy, $errors) = @_;

    my $profile_strictness = $self->{$NON_PUBLIC_DATA}{_profile_strictness};
    defined $profile_strictness
        or $profile_strictness = $PROFILE_STRICTNESS_DEFAULT;

    return if $profile_strictness eq $PROFILE_STRICTNESS_QUIET;

    my $parameter_errors = $profile_strictness eq $PROFILE_STRICTNESS_WARN ?
        Perl::Critic::Exception::AggregateConfiguration->new() : $errors;

    foreach my $offered_param ( $self->get_parameter_names() ) {
        $parameter_errors->add_exception(
            Perl::Critic::Exception::Configuration::Option::Policy::ExtraParameter->new(
                policy => $policy->get_short_name(),
                option_name => $offered_param,
                source  => undef,
            )
        );
    }

    warn qq<$parameter_errors\n>
        if ($profile_strictness eq $PROFILE_STRICTNESS_WARN
            && $parameter_errors->has_exceptions());

    return;
}

#-----------------------------------------------------------------------------

sub set_profile_strictness {
    my ($self, $profile_strictness) = @_;

    $self->{$NON_PUBLIC_DATA}{_profile_strictness} = $profile_strictness;

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 333

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
