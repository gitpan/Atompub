#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use File::Spec ();
use String::Format qw< stringf >;

use overload ( q<""> => 'to_string', cmp => '_compare' );

use Perl::Critic::Utils qw<
    :characters
    :booleans
    :severities
    :data_conversion
    interpolate
    is_integer
    policy_long_name
    policy_short_name
    severity_to_number
>;
use Perl::Critic::Utils::DataConversion qw< dor >;
use Perl::Critic::Utils::POD qw<
    get_module_abstract_for_module
    get_raw_module_abstract_for_module
>;
use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration;
use Perl::Critic::Exception::Configuration::Option::Policy::ExtraParameter;
use Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue;
use Perl::Critic::Exception::Fatal::PolicyDefinition
    qw< throw_policy_definition >;
use Perl::Critic::PolicyConfig qw<>;
use Perl::Critic::PolicyParameter qw<>;
use Perl::Critic::Violation qw<>;

use Exception::Class;   # this must come after "use P::C::Exception::*"

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $NO_LIMIT => 'no_limit';

#-----------------------------------------------------------------------------

my $format = "%p\n"; #Default stringy format

#-----------------------------------------------------------------------------

sub new {
    my ($class, %config) = @_;

    my $self = bless {}, $class;

    my $config_object;
    if ($config{_config_object}) {
        $config_object = $config{_config_object};
    }
    else {
        $config_object =
            Perl::Critic::PolicyConfig->new(
                $self->get_short_name(),
                \%config,
            );
    }

    $self->__set_config( $config_object );

    my @parameters;
    my $parameter_metadata_available = 0;

    if ( $class->can('supported_parameters') ) {
        $parameter_metadata_available = 1;
        @parameters =
            map
                { Perl::Critic::PolicyParameter->new($_) }
                $class->supported_parameters();
    }
    $self->{_parameter_metadata_available} = $parameter_metadata_available;
    $self->{_parameters} = \@parameters;

    my $errors = Perl::Critic::Exception::AggregateConfiguration->new();
    foreach my $parameter ( @parameters ) {
        eval {
            $parameter->parse_and_validate_config_value( $self, $config_object );
        }
            or do {
                $errors->add_exception_or_rethrow($EVAL_ERROR);
            };

        $config_object->remove( $parameter->get_name() );
    }

    if ($parameter_metadata_available) {
        $config_object->handle_extra_parameters( $self, $errors );
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub is_safe {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub __get_parameter_name {
    my ( $self, $parameter ) = @_;

    return '_' . $parameter->get_name();
}

#-----------------------------------------------------------------------------

sub __set_parameter_value {
    my ( $self, $parameter, $value ) = @_;

    $self->{ $self->__get_parameter_name($parameter) } = $value;

    return;
}

#-----------------------------------------------------------------------------

sub __set_base_parameters {
    my ($self) = @_;

    my $config = $self->__get_config();
    my $errors = Perl::Critic::Exception::AggregateConfiguration->new();

    $self->_set_maximum_violations_per_document($errors);

    my $user_severity = $config->get_severity();
    if ( defined $user_severity ) {
        my $normalized_severity = severity_to_number( $user_severity );
        $self->set_severity( $normalized_severity );
    }

    my $user_set_themes = $config->get_set_themes();
    if ( defined $user_set_themes ) {
        my @set_themes = words_from_string( $user_set_themes );
        $self->set_themes( @set_themes );
    }

    my $user_add_themes = $config->get_add_themes();
    if ( defined $user_add_themes ) {
        my @add_themes = words_from_string( $user_add_themes );
        $self->add_themes( @add_themes );
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return;
}

#-----------------------------------------------------------------------------

sub _set_maximum_violations_per_document {
    my ($self, $errors) = @_;

    my $config = $self->__get_config();

    if ( $config->is_maximum_violations_per_document_unlimited() ) {
        return;
    }

    my $user_maximum_violations =
        $config->get_maximum_violations_per_document();

    if ( not is_integer($user_maximum_violations) ) {
        $errors->add_exception(
            new_parameter_value_exception(
                'maximum_violations_per_document',
                $user_maximum_violations,
                undef,
                "does not look like an integer.\n"
            )
        );

        return;
    }
    elsif ( $user_maximum_violations < 0 ) {
        $errors->add_exception(
            new_parameter_value_exception(
                'maximum_violations_per_document',
                $user_maximum_violations,
                undef,
                "is not greater than or equal to zero.\n"
            )
        );

        return;
    }

    $self->set_maximum_violations_per_document(
        $user_maximum_violations
    );

    return;
}

#-----------------------------------------------------------------------------

# Unparsed configuration, P::C::PolicyConfig.  Compare with get_parameters().
sub __get_config {
    my ($self) = @_;

    return $self->{_config};
}

sub __set_config {
    my ($self, $config) = @_;

    $self->{_config} = $config;

    return;
}

 #-----------------------------------------------------------------------------

sub get_long_name {
    my ($self) = @_;

    return policy_long_name(ref $self);
}

#-----------------------------------------------------------------------------

sub get_short_name {
    my ($self) = @_;

    return policy_short_name(ref $self);
}

#-----------------------------------------------------------------------------

sub is_enabled {
    my ($self) = @_;

    return $self->{_enabled};
}

#-----------------------------------------------------------------------------

sub __set_enabled {
    my ($self, $new_value) = @_;

    $self->{_enabled} = $new_value;

    return;
}

#-----------------------------------------------------------------------------

sub applies_to {
    return qw(PPI::Element);
}

#-----------------------------------------------------------------------------

sub set_maximum_violations_per_document {
    my ($self, $maximum_violations_per_document) = @_;

    $self->{_maximum_violations_per_document} =
        $maximum_violations_per_document;

    return $self;
}

#-----------------------------------------------------------------------------

sub get_maximum_violations_per_document {
    my ($self) = @_;

    return
        exists $self->{_maximum_violations_per_document}
            ? $self->{_maximum_violations_per_document}
            : $self->default_maximum_violations_per_document();
}

#-----------------------------------------------------------------------------

sub default_maximum_violations_per_document {
    return;
}

#-----------------------------------------------------------------------------

sub set_severity {
    my ($self, $severity) = @_;
    $self->{_severity} = $severity;
    return $self;
}

#-----------------------------------------------------------------------------

sub get_severity {
    my ($self) = @_;
    return $self->{_severity} || $self->default_severity();
}

#-----------------------------------------------------------------------------

sub default_severity {
    return $SEVERITY_LOWEST;
}

#-----------------------------------------------------------------------------

sub set_themes {
    my ($self, @themes) = @_;
    $self->{_themes} = [ sort @themes ];
    return $self;
}

#-----------------------------------------------------------------------------

sub get_themes {
    my ($self) = @_;
    my @themes = defined $self->{_themes} ? @{ $self->{_themes} } : $self->default_themes();
    my @sorted_themes = sort @themes;
    return @sorted_themes;
}

#-----------------------------------------------------------------------------

sub add_themes {
    my ($self, @additional_themes) = @_;
    #By hashifying the themes, we squish duplicates
    my %merged = hashify( $self->get_themes(), @additional_themes);
    $self->{_themes} = [ keys %merged];
    return $self;
}

#-----------------------------------------------------------------------------

sub default_themes {
    return ();
}

#-----------------------------------------------------------------------------

sub get_abstract {
    my ($self) = @_;

    return get_module_abstract_for_module( ref $self );
}

#-----------------------------------------------------------------------------

sub get_raw_abstract {
    my ($self) = @_;

    return get_raw_module_abstract_for_module( ref $self );
}

#-----------------------------------------------------------------------------

sub parameter_metadata_available {
    my ($self) = @_;

    return $self->{_parameter_metadata_available};
}

#-----------------------------------------------------------------------------

sub get_parameters {
    my ($self) = @_;

    return $self->{_parameters};
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self) = @_;

    return throw_policy_definition
        $self->get_short_name() . q/ does not implement violates()./;
}

#-----------------------------------------------------------------------------

sub violation {  ## no critic (ArgUnpacking)
    my ( $self, $desc, $expl, $elem ) = @_;
    # HACK!! Use goto instead of an explicit call because P::C::V::new() uses caller()
    my $sev = $self->get_severity();
    @_ = ('Perl::Critic::Violation', $desc, $expl, $elem, $sev );
    goto &Perl::Critic::Violation::new;
}

#-----------------------------------------------------------------------------

sub new_parameter_value_exception {
    my ( $self, $option_name, $option_value, $source, $message_suffix ) = @_;

    return Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue->new(
        policy          => $self->get_short_name(),
        option_name     => $option_name,
        option_value    => $option_value,
        source          => $source,
        message_suffix  => $message_suffix
    );
}

#-----------------------------------------------------------------------------

## no critic (Subroutines::RequireFinalReturn)
sub throw_parameter_value_exception {
    my ( $self, $option_name, $option_value, $source, $message_suffix ) = @_;

    $self->new_parameter_value_exception(
        $option_name, $option_value, $source, $message_suffix
    )
        ->throw();
}
## use critic


#-----------------------------------------------------------------------------

# Static methods.

sub set_format { return $format = $_[0] }  ## no critic(ArgUnpacking)
sub get_format { return $format         }

#-----------------------------------------------------------------------------

sub to_string {
    my ($self, @args) = @_;

    # Wrap the more expensive ones in sub{} to postpone evaluation
    my %fspec = (
         'P' => sub { $self->get_long_name() },
         'p' => sub { $self->get_short_name() },
         'a' => sub { dor($self->get_abstract(), $EMPTY) },
         'O' => sub { $self->_format_parameters(@_) },
         'U' => sub { $self->_format_lack_of_parameter_metadata(@_) },
         'S' => sub { $self->default_severity() },
         's' => sub { $self->get_severity() },
         'T' => sub { join $SPACE, $self->default_themes() },
         't' => sub { join $SPACE, $self->get_themes() },
         'V' => sub { dor( $self->default_maximum_violations_per_document(), $NO_LIMIT ) },
         'v' => sub { dor( $self->get_maximum_violations_per_document(), $NO_LIMIT ) },
    );
    return stringf(get_format(), %fspec);
}

sub _format_parameters {
    my ($self, $parameter_format) = @_;

    return $EMPTY if not $self->parameter_metadata_available();

    my $separator;
    if ($parameter_format) {
        $separator = $EMPTY;
    } else {
        $separator = $SPACE;
        $parameter_format = '%n';
    }

    return
        join
            $separator,
            map { $_->to_formatted_string($parameter_format) } @{ $self->get_parameters() };
}

sub _format_lack_of_parameter_metadata {
    my ($self, $message) = @_;

    return $EMPTY if $self->parameter_metadata_available();
    return interpolate($message) if $message;

    return
        'Cannot programmatically discover what parameters this policy takes.';
}

#-----------------------------------------------------------------------------
# Apparently, some perls do not implicitly stringify overloading
# objects before doing a comparison.  This causes a couple of our
# sorting tests to fail.  To work around this, we overload C<cmp> to
# do it explicitly.
#
# 20060503 - More information:  This problem has been traced to
# Test::Simple versions <= 0.60, not perl itself.  Upgrading to
# Test::Simple v0.62 will fix the problem.  But rather than forcing
# everyone to upgrade, I have decided to leave this workaround in
# place.

sub _compare { return "$_[0]" cmp "$_[1]" }

1;

__END__

#-----------------------------------------------------------------------------

#line 908

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
